local XFubenActivityAgency = require('XModule/XBase/XFubenActivityAgency')

---@class XPunishaarAgency : XAgency
---@field private _Model XPunishaarModel
---@field NetworkAgency XPunishaarNetworkAgency
local XPunishaarAgency = XClass(XFubenActivityAgency, "XPunishaarAgency", true)
--部分类require
XClassPartialRequire("XModule/XPunishaar/XPunishaarConfigAgency", "XPunishaarAgency")

function XPunishaarAgency:OnInit()
    self:RegisterActivityAgency()

    --初始化一些变量
    self:InitConfig()

    ---@type XPunishaarEnum
    self.EnumConst = require("XModule/XPunishaar/XPunishaarEnum")

    ---@type XPunishaarNetworkAgency
    self.NetworkAgency = self:AddSubAgency(require("XModule/XPunishaar/SubModules/Network/XPunishaarNetworkAgency"))
end

function XPunishaarAgency:InitRpc()
    -- NotifyPunishaarLoginData 已移入 NetworkAgency:InitRpc
end

function XPunishaarAgency:InitEvent()

end

--- 活动入口跳转钩子（被 ExOpenMainUi / SkipId 机制回调）
function XPunishaarAgency:ExOnSkip()
    if self:GetIsActivityOpen(true) then
        XLuaUiManager.Open("UiPunishaarMain")
        return true
    end
    return false
end

--- 活动是否当前可进入（功能开关 + 时间 + 服务端数据三合一）
---@param needTips boolean 不满足时是否弹提示
---@return boolean
function XPunishaarAgency:GetIsActivityOpen(needTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Punishaar, true, needTips) then 
        return false
    end

    if not self:ExCheckInTime() then
        if needTips then
            XUiManager.TipText("CommonActivityNotInTime")
        end
        return false
    end

    if not self._Model:CheckHasValidActivityId() then
        if needTips then
            XUiManager.TipText("CommonActivityNotInTime")
        end
        return false
    end

    return true
end

--region ----------public start----------

--- 【调试/测试】开始编辑一份开战契约：清空 Model 上的可复用契约对象并返回，供外部（C# 编辑器 / GM）逐项 set。
--- C# 经 XMVCA 拿本 Agency 调用；set 完调 CommitBattleTest 开战。
--- 注意：本入口面向策划/QA 战斗效果调试，只填契约数据，不触碰配置表。
---@return XPunishaarBattleInitData 已 Reset 的契约对象
function XPunishaarAgency:BeginBattleTest()
    return self._Model:ResetBattleInitData()
end

--- 【调试/测试】提交已 set 好的契约并打开战斗界面。
--- 数据流向：Agency 存 Model → 界面驱动 Control → Control 初始化时从 Model 取契约 StartBattle。
--- 约束：仅限 Editor 环境（XMain.IsWindowsEditor），真机禁止走测试路径（防误触/外放泄露调试入口）
---@return boolean 校验通过并已打开界面
function XPunishaarAgency:CommitBattleTest()
    if not XMain.IsWindowsEditor then
        XLog.Error("[Punishaar] CommitBattleTest 测试入口仅限 Editor 环境，真机禁止调用")
        return false
    end
    local data = self._Model:PeekBattleInitData()
    if not data or not data:Validate() then
        XLog.Error("[Punishaar] 开战契约未就绪或非法，CommitBattleTest 中止")
        return false
    end

    -- set 阶段末排序：_Cards(pairs 序)→_SortedCards(posIndex 序)，镜像正式路径 _PrepareBattleData 末尾产出。
    -- 测试路径不经 _PrepareBattleData，须在此补排，否则 SetupBattle 读 GetSortedCard 拿 nil 致 index nil 崩（#82 派生字段）。
    data:BuildSortedCards()

    if XLuaUiManager.IsUiLoad("UiPunishaarFightMain") then
        XLog.Error("[Punishaar] 当前已加载大巴扎战斗界面，请退出所有大巴扎战斗界面后，再通过调试入口进入战斗")
        return
    end

    -- 打开战斗界面（Fighting 态=3）；界面 OnEnable 检测无 GameControl 时走测试工具路径：
    -- 就地 InitGameControl + 设 FightState=Fighting + 标记 _IsTestMode，再 SwitchToState(Fighting)
    -- → FightingPanel.OnEnable 调 Control:EnterFight 从 Model 取调试契约 StartBattle。
    XLuaUiManager.Open("UiPunishaarFightMain", 3)
    return true
end

--- 【调试/测试】提取局内对战区卡组（含装备副卡），供战斗测试窗口复用开测试局。
--- 仅 FightArea 卡；局外/无 stage 返空表；副卡 SubCardId≠0 含；subLevel 不返（C# 默认1）。
--- 守卫：必须进入关卡界面（FightMain 已加载）才提取——防 stage 缓存致局外误提；未进返 nil（C# 区分提示"需进入关卡界面"）。
---@return table|nil 卡列表（1-based 数组）；nil=未进关卡界面，空表=已进但无对战区卡
function XPunishaarAgency:GetInGameCardLineup()
    if not XLuaUiManager.IsUiLoad("UiPunishaarFightMain") then
        return nil
    end
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.TotalMasterCards then
        return {}
    end
    local list = {}
    local FightArea = XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea
    for _, card in pairs(stage.TotalMasterCards) do
        if card.AreaType == FightArea then
            list[#list + 1] = {
                cardId = card.TemplateId,
                level = card.Level,
                posIndex = card.StartPos,
                subCardId = card.SubCardId or 0,
            }
        end
    end
    return list
end

--- 判断关卡是否已通关
---@param stageId number
---@return boolean
function XPunishaarAgency:CheckStageIsPassById(stageId)
    return self._Model:GetOutSideModel():IsPassStage(stageId)
end

--- 判断关卡是否已解锁（可进入）
--- 解锁条件：TimeId 时间段内；前置关卡已通关。前置关卡由配置 PreStageId 显式指定（0/nil 表示无前置，默认解锁）。
---@param stageId number
---@return boolean
function XPunishaarAgency:IsStageUnlocked(stageId)
    local stageCfg = self:GetTablePunishaarStageGroupById(stageId)
    if not stageCfg then return false end

    if not XFunctionManager.CheckInTimeByTimeId(stageCfg.TimeId, true) then
        return false
    end

    -- 前置关卡：读配置 PreStageId 字段（0/nil 表示无前置，默认解锁）
    local preStageId = stageCfg.PreStageId
    
    if not XTool.IsNumberValidEx(preStageId) then
        return true
    end

    return self:CheckStageIsPassById(preStageId)
end

--- 获取关卡当前状态
---@param stageId number
---@return number self.EnumConst.StageStatus
function XPunishaarAgency:GetStageStatus(stageId)
    local outsideModel = self._Model:GetOutSideModel()
    if outsideModel:IsHasSaveStage(stageId) then
        return self.EnumConst.StageStatus.HasSave
    end
    if outsideModel:IsPassStage(stageId) then
        return self.EnumConst.StageStatus.Passed
    end
    if self:IsStageUnlocked(stageId) then
        return self.EnumConst.StageStatus.Opened
    end
    return self.EnumConst.StageStatus.NotOpen
end

--- 检查当前活动是否存在可领取奖励的任务
--- 指定taskGroupIndex时仅检查对应任务组，否则检查全部任务组
---@param taskGroupIndex number|nil PunishaarActivity.TaskGroupIds的下标
---@return boolean 是否显示任务红点
function XPunishaarAgency:CheckTaskRedPoint(taskGroupIndex)
    local activityId = self._Model:GetActivityId()
    local activityCfg = activityId and self:GetTablePunishaarActivityById(activityId, true)

    if not activityCfg or XTool.IsTableEmpty(activityCfg.TaskGroupIds) then
        return false
    end

    if taskGroupIndex then
        local groupId = activityCfg.TaskGroupIds[taskGroupIndex]
        return XTool.IsNumberValid(groupId) and XDataCenter.TaskManager.IsAnyTaskCanReceiveByTaskGroupId(groupId)
    end

    for _, groupId in ipairs(activityCfg.TaskGroupIds) do
        if XTool.IsNumberValid(groupId) and XDataCenter.TaskManager.IsAnyTaskCanReceiveByTaskGroupId(groupId) then 
            return true
        end
    end

    return false
end

--- 获取指定关卡的局外存档进度
--- cur 表示当前所在节点序号，按“已经过节点数+1”计算；total 表示该关卡配置节点总数
--- 无尽关的 HistoryNodeList 每轮通关后会清空，因此这里返回的是当前轮内进度
---@param stageId number 关卡Id
---@return number cur 当前节点序号，无存档时为 0
---@return number total 节点总数
function XPunishaarAgency:GetStageProgress(stageId)
    local total = self:GetStageContentCount(stageId)
    if total <= 0 then
        return 0, 0
    end

    local stage = self._Model:GetOutSideModel():GetSaveStage(stageId)
    if not stage then
        return 0, total
    end

    local historyCount = stage.HistoryNodeList and #stage.HistoryNodeList or 0
    local cur = historyCount + 1

    if cur > total then
        cur = total
    end

    return cur, total
end

--- 检查关卡是否应该显示红点，未通关且已解锁且从未点过的关卡才会显示红点
---@param stageId number
---@return boolean
function XPunishaarAgency:CheckStageShowRedPoint(stageId)
    if self:GetStageStatus(stageId) ~= self.EnumConst.StageStatus.Opened then
        return false
    end

    return not self._Model:GetIsStageRead(stageId)
end

---@return boolean
function XPunishaarAgency:CheckAnyStageShowRedPoint()
    local groupId = self:GetCurrentStageGroupId()
    if not groupId then
        return false
    end

    for index = 1, 9 do
        local stageId = self:GetStageIdByGroupAndIndex(groupId, index)
        local stageCfg = self:GetTablePunishaarStageGroupById(stageId, true)

        if stageCfg and self:CheckStageShowRedPoint(stageId) then
            return true
        end
    end

    return false
end

function XPunishaarAgency:IsCollectionCardVisible(cardId)
    local cfg = self:GetTablePunishaarCard(cardId, true)
    return cfg and cfg.IsShow or false
end

--- 判断当前局内持有金币数量与右值的关系（对齐 Control:GetCurrentGold stage.Gold）。
---@param rightVal number 右值
---@param opEnum number 逻辑运算枚举：1=大于, 2=小于等于
---@return boolean 是否满足（活动未开/非局内返 false）
function XPunishaarAgency:CheckGoldRelation(rightVal, opEnum)
    if not self:GetIsActivityOpen(false) then
        return false
    end
    local stage = self._Model:GetCurrentStage()
    if not stage then
        return false
    end
    local gold = stage.Gold or 0
    if opEnum == 1 then
        return gold > rightVal
    elseif opEnum == 2 then
        return gold <= rightVal
    end
    return false  -- 未知 opEnum
end

--- 判断当前局内节点是否在指定闭区间 [leftBound, rightBound]（对齐 Control:GetCurrentNodeIndex #HistoryNodeList+1）。
---@param leftBound number 左闭区间
---@param rightBound number 右闭区间
---@param stageId number|nil 指定关卡Id；不传则不校验关卡
---@return boolean 是否在区间内（活动未开/非局内返 false）
function XPunishaarAgency:CheckNodeInterval(leftBound, rightBound, stageId, status)
    if not self:GetIsActivityOpen(false) then
        return false
    end

    ---@type XPunishaarStageProtocol
    local stage = self._Model:GetCurrentStage()

    if not stage then
        return false
    end

    if XTool.IsNumberValid(stageId) and stage.StageId ~= stageId then
        return false
    end

    if XTool.IsNumberValidEx(status) and stage.CurrentNode and stage.CurrentNode.Status ~= status then
        return false
    end
    
    local nodeIndex = XTool.GetTableCount(stage.HistoryNodeList) + 1
    return nodeIndex >= leftBound and nodeIndex <= rightBound
end

function XPunishaarAgency:CheckCollectionCardRedPoint(catalogType, cardId)
    if not self:IsCollectionCardVisible(cardId) then
        return false
    end

    local outsideModel = self._Model:GetOutSideModel()

    if not outsideModel:IsCollectionUnlocked(catalogType, cardId) then
        return false
    end

    return not self._Model:IsCollectionCardRead(catalogType, cardId)
end

function XPunishaarAgency:CheckCollectionRedPoint(catalogType)
    return self._Model:GetOutSideModel():LoopCollectionIds(catalogType,
        function(cardId)
            return self:CheckCollectionCardRedPoint(catalogType, cardId)
        end
    )
end

function XPunishaarAgency:MarkCollectionRead(catalogType)
    local readDict = self._Model:GetCollectionReadDict(catalogType)

    local changed = false

    self._Model:GetOutSideModel():LoopCollectionIds(catalogType,
        function(cardId)
            if self:IsCollectionCardVisible(cardId) and not readDict[cardId] then
                readDict[cardId] = true
                changed = true
            end
        end
    )

    if not changed then
        return
    end

    self._Model:SaveCollectionReadDict(catalogType, readDict)

    XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_COLLECTION_RED_POINT_CHANGE)
end
--endregion ----------public end----------

--region ----------private start----------

--endregion ----------private end----------

return XPunishaarAgency
