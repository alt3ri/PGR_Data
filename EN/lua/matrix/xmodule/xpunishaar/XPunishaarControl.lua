---@class XPunishaarControl : XControl
---@field private _Model XPunishaarModel
---@field GameControl XPunishaarGameControl  -- 关卡级壳（lazy 于 EnterRun，退出结算界面销毁）
local XPunishaarControl = XClass(XControl, "XPunishaarControl", true)
--部分类require（玩法级 partial：配置 + 外部界面数据/流程入口；关卡级 flow partial 已移至 GameControl）
XClassPartialRequire("XModule/XPunishaar/XPunishaarConfigControl", "XPunishaarControl")
XClassPartialRequire("XModule/XPunishaar/SubModules/OutSide/XPunishaarControlOutside", "XPunishaarControl")
-- Shop/NodeFlow/Drag/Projection flow partial 已降级到 GameControl（关卡级，外部界面不可直调，见 GameControl.lua）

XPunishaarControl.EventId = {
    ActivityTimerUpdate = "PunishaarActivityTimerUpdate",
    CardOutlineSelect = "PunishaarCardOutlineSelect",
    CardOutlineDeselect = "PunishaarCardOutlineDeselect",
}

function XPunishaarControl:OnInit()
    --初始化内部变量
    self:InitConfig()
    self:StartActivityTimer()
end

function XPunishaarControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XPunishaarControl:RemoveAgencyEvent()

end

function XPunishaarControl:OnRelease()
    self:StopActivityTimer()
    -- GameControl 由框架 Release 级联释放（XControl:Release L227-229 遍历 _SubControls 释放子控），
    -- 此处不手动 RemoveSubControl（OnRelease 调用时 _SubControls 已被置 nil，会 index nil）
end


--region ----------public start----------

function XPunishaarControl:GetActivityCfg()
    local activityId = self._Model:GetActivityId()
    return XMVCA.XPunishaar:GetTablePunishaarActivityById(activityId)
end

--- 进入一局（服务端路径：ExploreDetail 收到 StartStage 回调后调用；结算续关 _OnBtnRestart 亦走此）。
--- lazy 建 GameControl（关卡级壳）→ EnterRun 委派 RunControl:EnterRun。
--- 续关时先 release 旧 GameControl 再建新的（EnterGame 即关卡的真正切换点）。
---@param gameData table 服务端下发的局数据
function XPunishaarControl:EnterGame(gameData)
    self:ReleaseGameControl()
    self:InitGameControl()
    self.GameControl:EnterRun(gameData)
end

--- 进入战斗（Fighting UI OnStart 调；从 Model 取契约后转 GameControl:EnterFight lazy 建 FightControl 开局）。
function XPunishaarControl:EnterFight()
    self:InitGameControl()
    -- 数据来源：Control 初始化期间自己从 Model 取契约对象（Agency 已在开界面前 set 好）。
    -- 无契约则报错（正式流程必经 Agency:BeginBattleTest→set→CommitBattleTest 备好契约）。
    local data = self._Model:PeekBattleInitData()
    if data then
        self.GameControl:EnterFight(data)
        XLog.Debug("进入战斗")
    else
        XLog.Error("大巴扎战斗数据不存在")
    end

end

function XPunishaarControl:ExitFight()
    if self.GameControl then
        self.GameControl:ReleaseFightControl()
    end
    XLog.Debug("退出战斗")
end

---@param stageId number
---@param callback function|nil
function XPunishaarControl:EnterStory(stageId, callback)
    local storyId = XMVCA.XPunishaar:GetExploreDetailStoryId(stageId)

    -- 没配置开场剧情时，直接继续进入关卡
    if string.IsNilOrEmpty(storyId) then
        if callback then
            callback()
        end
        return
    end

    -- 剧情在关卡内：释放战斗引擎，GameControl 仍存活
    if self.GameControl then
        self.GameControl:ReleaseFightControl()
    end
    XDataCenter.MovieManager.PlayMovie(storyId, callback)
end

--endregion ----------public end----------

--region ----------当前局服务端数据读取----------
-- 以下接口读取 Model 中的 CurrentStage，局内外均可调用。
-- 生命周期：OutSideModel.ClearPrivate 调用后数据清空，局外调用返回 nil。

---@return number|nil 当前关卡 ID
function XPunishaarControl:GetCurrentStageId()
    local stage = self._Model:GetCurrentStage()
    return stage and stage.StageId
end

---@return number|nil 当前回合/进度
function XPunishaarControl:GetCurrentRound()
    local stage = self._Model:GetCurrentStage()
    return stage and stage.CurrentRound
end

--- 无尽关历史最佳轮次（破纪录比对基准）。
--- TODO: 数据源未定——客户端 DataDb 持久化 best round per 无尽关，或服务端字段下发；
--- 确定后在此实现，暂返回 0（IsNewRecord 据 best>0 守护，未实现前不会误报破纪录）。
---@param stageId number
---@return number
function XPunishaarControl:GetBestRound(stageId)
    -- TODO: 待数据源定（客户端缓存 / 服务端下发）
    return 0
end

--- 当前轮次是否破纪录（仅无尽关有意义，调用方应先判 IsEndlessStage）。
---@param stageId number
---@param currentRound number
---@return boolean
function XPunishaarControl:IsNewRecord(stageId, currentRound)
    local best = self:GetBestRound(stageId)
    return best > 0 and (currentRound or 0) > best
end

--- 玩家当前血量（Durability 即关卡耐久度/玩家 HP）
---@return number|nil
function XPunishaarControl:GetCurrentDurability()
    local stage = self._Model:GetCurrentStage()
    return stage and stage.Durability
end

---@return number|nil 玩家当前货币量
function XPunishaarControl:GetCurrentGold()
    local stage = self._Model:GetCurrentStage()
    return stage and stage.Gold
end

--- 当前战斗节点的 FightId（非战斗节点返回 nil）
--- 优先取 SelectedFightId，其次取 RandomFightIds[1]
---@return number|nil
function XPunishaarControl:GetCurrentFightId()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.CurrentNode then return nil end
    local fightInfo = stage.CurrentNode.FightInfo
    if not fightInfo then return nil end
    local fightId = fightInfo.SelectedFightId
    if fightId and fightId ~= 0 then return fightId end
    return fightInfo.RandomFightIds and fightInfo.RandomFightIds[1]
end

--- 当前节点是否已完成战斗选定、可以点击"开始战斗"。
--- 普通战斗节点（FightNode）进入即可；选择战斗节点（SelectFightNode）需玩家先调 SelectFight。
---@return boolean
function XPunishaarControl:CanStartFight()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.CurrentNode then return false end
    local node = stage.CurrentNode
    if node.Type == XMVCA.XPunishaar.EnumConst.NodeType.Fight then
        return true
    end
    if node.Type == XMVCA.XPunishaar.EnumConst.NodeType.ChoiceFight then
        local fightInfo = node.FightInfo
        return fightInfo ~= nil and fightInfo.SelectedFightId ~= nil and fightInfo.SelectedFightId ~= 0
    end
    return false
end

--- 当前节点状态（对应服务端 XPunishaarNodeStatus）
---@return number|nil
function XPunishaarControl:GetCurrentNodeStatus()
    local stage = self._Model:GetCurrentStage()
    return stage and stage.CurrentNode and stage.CurrentNode.Status
end

--- 当前是否处于补强商店：补强商店复用商店 UI，但节点本质是战斗节点(Fight/ChoiceFight)的补强(Remedy)状态。
--- 需 Type==Fight/ChoiceFight 且 Status==Remedy 两者同时满足，与普通商店节点(Type==Shop, Status==Processing)区分。
--- ChoiceFight 对齐 Fight（#81）：选择战斗节点补强同判，原仅判 Fight 致 ChoiceFight+Remedy 离开按钮误走 ExitNode。
---@return boolean
function XPunishaarControl:IsInRemedyShop()
    local stage = self._Model:GetCurrentStage()
    local node = stage and stage.CurrentNode
    if not node then return false end
    local NodeType = XMVCA.XPunishaar.EnumConst.NodeType
    return (node.Type == NodeType.Fight or node.Type == NodeType.ChoiceFight)
        and node.Status == XMVCA.XPunishaar.EnumConst.NodeStatus.Remedy
end

--- 当前商店节点的候选商店 Id 列表（WaitSelectShop 状态时使用）
---@return number[]|nil
function XPunishaarControl:GetCurrentShopCandidateIds()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.CurrentNode then return nil end
    local shopInfo = stage.CurrentNode.ShopInfo
    return shopInfo and shopInfo.CandidateShopIds
end

--- 当前选定的商店 Id（玩家二选一/补强商店选定后由服务端下发，非商店节点返回 0）
---@return number
function XPunishaarControl:GetCurrentShopId()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.CurrentNode then return 0 end
    local shopInfo = stage.CurrentNode.ShopInfo
    return (shopInfo and shopInfo.SelectedShopId) or 0
end

--- 当前商店节点的商品列表（非商店节点返回 nil）
---@return table[]|nil Server.XPunishaarGoods[]
function XPunishaarControl:GetCurrentShopGoods()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.CurrentNode then return nil end
    local shopInfo = stage.CurrentNode.ShopInfo
    return shopInfo and shopInfo.Goods
end

--- 当前商店已刷新次数（用于刷新费用计算：基础 + 增量 × 次数）。非商店节点返回 0。
---@return number
function XPunishaarControl:GetCurrentShopRefreshTimes()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.CurrentNode then return 0 end
    local shopInfo = stage.CurrentNode.ShopInfo
    return (shopInfo and shopInfo.RefreshTimes) or 0
end

--- 填充对战区卡牌到 out（XList 复用，零 per-call GC）
---@param out XList 调用方持有并复用的 XList
---@return number 卡牌数
function XPunishaarControl:FillFightAreaCards(out)
    out:Clear()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.TotalMasterCards then return 0 end
    for _, card in pairs(stage.TotalMasterCards) do
        if card.AreaType == XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea then
            out:Append(card)
        end
    end
    return out:GetCount()
end

--- 填充背包卡牌到 out（XList 复用）
---@param out XList
---@return number
function XPunishaarControl:FillBagAreaCards(out)
    out:Clear()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.TotalMasterCards then return 0 end
    for _, card in pairs(stage.TotalMasterCards) do
        if card.AreaType == XMVCA.XPunishaar.EnumConst.CardAreaType.Bag then
            out:Append(card)
        end
    end
    return out:GetCount()
end

--- 填充指定区域的卡牌到 out 并按 StartPos 升序排序（XList 复用）
---@param areaType number CardAreaType
---@param out XList
---@return number
function XPunishaarControl:FillAreaCardsSorted(areaType, out)
    out:Clear()
    local stage = self._Model:GetCurrentStage()
    if not stage or not stage.TotalMasterCards then return 0 end
    for _, card in pairs(stage.TotalMasterCards) do
        if card.AreaType == areaType then
            out:Append(card)
        end
    end
    out:Sort(function(a, b) return a.StartPos < b.StartPos end)
    return out:GetCount()
end

--- Stage 未就位时返回 nil，调用方应以 `or maxCount` 兜底（全部解锁），避免槽全部显示为锁定。
function XPunishaarControl:GetFightAreaGridLimit()
    local stage = self._Model:GetCurrentStage()
    if not stage then return nil end
    return stage.FightAreaGridLimit
end

function XPunishaarControl:GetBagGridLimit()
    local stage = self._Model:GetCurrentStage()
    if not stage then return nil end
    return stage.BagGridLimit
end

--endregion ----------当前局服务端数据读取----------

--region 活动时间定时器

function XPunishaarControl:StartActivityTimer()
    self:StopActivityTimer()
    self._ActivityTimerId = XScheduleManager.ScheduleForever(
        handler(self, self.UpdateActivityTimer),
        XScheduleManager.SECOND
    )
    self:UpdateActivityTimer()
end

function XPunishaarControl:StopActivityTimer()
    if self._ActivityTimerId then
        XScheduleManager.UnSchedule(self._ActivityTimerId)
        self._ActivityTimerId = nil
    end

    self._TimeTickOutCallBack = nil
end

function XPunishaarControl:GetIsActivityTimerStart()
    return XTool.IsNumberValidEx(self._ActivityTimerId)
end

function XPunishaarControl:UpdateActivityTimer()
    local activityCfg = self:GetActivityCfg()

    if activityCfg and XTool.IsNumberValidEx(activityCfg.TimeId) then
        self:DispatchEvent(self.EventId.ActivityTimerUpdate, activityCfg.TimeId)
        if XFunctionManager.CheckInTimeByTimeId(activityCfg.TimeId) then
            return
        end
    end

    if self:TryDoTimeTickOut() then
        self:StopActivityTimer()
    end
end

function XPunishaarControl:TryDoTimeTickOut()
    if self._IsLockTimeTickOut then
        return false
    end

    if self._TimeTickOutCallBack then
        self._TimeTickOutCallBack()
    else
        -- 局内状态由 Control 统一清理：关 FightMain 面板 + 释放关卡级 GameControl（级联 Run/Fight）
        if self.GameControl then
            self.GameControl:ExitRun()
        end
        self:ReleaseGameControl()

        XLuaUiManager.RunMain()
        XUiManager.TipText("CommonActivityEnd")
    end

    return true
end

function XPunishaarControl:SetTimeTickOutCallBack(callback)
    self._TimeTickOutCallBack = callback
end

function XPunishaarControl:LockActivityTimerTickOut()
    self._IsLockTimeTickOut = true
end

function XPunishaarControl:UnLockActivityTimerTickOut()
    self._IsLockTimeTickOut = false
end

function XPunishaarControl:AddTimeEventListener(func, obj)
    self:AddEventListener(self.EventId.ActivityTimerUpdate, func, obj)

    -- 注册后立刻刷新一次，避免等下一秒
    if self:GetIsActivityTimerStart() then
        self:UpdateActivityTimer()
    end
end

function XPunishaarControl:RemoveTimeEventListener(func, obj)
    self:RemoveEventListener(self.EventId.ActivityTimerUpdate, func, obj)
end

--endregion

function XPunishaarControl:InitGameControl()
    if not self.GameControl then
        ---@type XPunishaarGameControl
        self.GameControl = self:AddSubControl(require("XModule/XPunishaar/SubModules/InGame/XPunishaarGameControl"))
    end
end

function XPunishaarControl:ReleaseGameControl()
    if self.GameControl then
        self:RemoveSubControl(self.GameControl)
        self.GameControl = nil
    end
end

return XPunishaarControl
