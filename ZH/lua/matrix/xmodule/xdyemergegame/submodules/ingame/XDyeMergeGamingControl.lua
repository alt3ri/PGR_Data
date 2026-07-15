local FLOOR_DISPLAY_ONLY = -1

--- 局内控制器
---@class XDyeMergeGamingControl : XControl
---@field _MainControl XDyeMergeGameControl
---@field private _Model XDyeMergeGameModel
local XDyeMergeGamingControl = XClass(XControl, "XDyeMergeGamingControl", true)

--部分类require
XClassPartialRequire("XModule/XDyeMergeGame/SubModules/InGame/XDyeMergeGamingConfigControl", "XDyeMergeGamingControl")

function XDyeMergeGamingControl:OnInit()
    self:InitConfig()
    
    ---@type XDyeMergeBlocksControl
    self.BlocksControl = self:AddSubControl(require("XModule/XDyeMergeGame/SubModules/InGame/XDyeMergeBlocksControl"))
    ---@type XDyeMergeMapControl
    self.MapControl = self:AddSubControl(require("XModule/XDyeMergeGame/SubModules/InGame/XDyeMergeMapControl"))
    ---@type XDyeMergeCommandControl
    self.CommandControl = self:AddSubControl(require("XModule/XDyeMergeGame/SubModules/InGame/XDyeMergeCommandControl"))
    ---@type XDyeMergeAnimationControl
    self.AnimationControl = self:AddSubControl(require("XModule/XDyeMergeGame/SubModules/InGame/XDyeMergeAnimationControl"))
end

function XDyeMergeGamingControl:AddAgencyEvent()

end

function XDyeMergeGamingControl:RemoveAgencyEvent()

end

function XDyeMergeGamingControl:OnRelease()

end

--region 通用工具方法

function XDyeMergeGamingControl:Vec2ToIndex(x, y)
    return x * 100 + y
end

function XDyeMergeGamingControl:IndexToVec2(index)
    local y = math.floor(math.fmod(index, 100))
    local x = math.floor((index - y) / 100)
    
    return x, y
end

local radian45 = math.rad(45)   -- 45度角转弧度
local cos45 = math.cos(radian45)
local sin45 = math.sin(radian45)

function XDyeMergeGamingControl:Vec2Rotate45(x, y)
    local newX = x * cos45 - y * sin45
    local newY = x * sin45 + y * cos45

    return newX, newY
end

--- 网格坐标 → 等距屏幕坐标（以棋盘中心为原点，UGUI Y 轴向上）
--- 适用于菱形格布局；tileHalfW / tileHalfH 由 UI 层传入（图片半宽/半高）
--- 等效于将"X 向左、Y 向上"的网格坐标系 CCW 旋转 45° 后投影到屏幕：
---   +gridX 移动一格 → 屏幕右上 (+tileHalfW, +tileHalfH)
---   +gridY 移动一格 → 屏幕左上 (-tileHalfW, +tileHalfH)
---   x+y 越大 → 越靠屏幕上方（越远离观察者）→ SiblingIndex 越低（先渲染，显示在后）
--- 注意：逻辑层方向（DirDelta）与等距屏幕方向的映射（Y 轴相反）：
---   逻辑1="上"(dy=-1) → gridY减 → screen右下
---   逻辑2="右"(dx=+1) → gridX增 → screen右上
---   逻辑3="下"(dy=+1) → gridY增 → screen左上
---   逻辑4="左"(dx=-1) → gridX减 → screen左下
---@param gridX number
---@param gridY number
---@param tileHalfW number 菱形格图片宽度的一半
---@param tileHalfH number 菱形格图片高度的一半
---@return number screenX, number screenY
function XDyeMergeGamingControl:Vec2ToIsoPos(gridX, gridY, tileHalfW, tileHalfH)
    local mapSizeX = self.MapControl:GetMapSizeX()
    local mapSizeY = self.MapControl:GetMapSizeY()
    local screenX = (gridX - gridY) * tileHalfW - (mapSizeX - mapSizeY) * tileHalfW / 2
    local screenY = (gridX + gridY) * tileHalfH - (mapSizeX + mapSizeY + 2) * tileHalfH / 2
    return screenX, screenY
end

--endregion

function XDyeMergeGamingControl:GetCurStageId()
    return self._CurStageId
end

--- 检查当前是否允许玩家交互操作
--- 集中管理所有锁定条件，OnUiGridClick / OnUiFloorClick 统一调用
---@return boolean isLocked true = 不可交互
function XDyeMergeGamingControl:CheckIsInteractionLocked()
    if self._IsStagePassed then return true end
    if self:CheckIsAnimationLocked() then return true end
    return false
end

--- 检查动画是否正在播放（表现层锁定）
---@return boolean isLocked true = 动画播放中
function XDyeMergeGamingControl:CheckIsAnimationLocked()
    return self.AnimationControl.AnimationCtrl:GetIsAnimationPlaying()
end

--- 检查是否所有 Target 已满足，通关时触发 OnStagePassed
function XDyeMergeGamingControl:CheckAndTryPassStage()
    if self.BlocksControl:CheckIsAllTargetSatisfied() then
        self:OnStagePassed()
    end
end

--- 通关处理：播放通关动画后发送完关请求
function XDyeMergeGamingControl:OnStagePassed()
    if self._IsStagePassed then return end
    self._IsStagePassed = true
    self:_RecordStageResult(true)
    local passedStageId = self._CurStageId

    self.AnimationControl:EnqueueStagePassedAnimation()
    self.AnimationControl:StartAnimations(function()
        XMVCA.XDyeMergeGame.Network:DoDyeMergeTryCompleteStageRequest(passedStageId, function(success)
            if success then
                local nextStageId = XMVCA.XDyeMergeGame:GetNextStageIdInChapter(passedStageId)
                self:DispatchEvent(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_STAGE_PASSED, nextStageId)
            end
        end)
    end)
end

function XDyeMergeGamingControl:InitGame(stageId)
    self._IsInitPhase = true
    self:_ResetRecordData(stageId)
    self._IsStagePassed = false
    self._PendingExtendAnim = nil
    self._ExtendEnablePendingUid = nil
    self.AnimationControl:ResetData()
    self.BlocksControl:ResetData()
    self.MapControl:ResetData()

    self._CurStageId = stageId

    if not XTool.IsNumberValidEx(stageId) then
        XLog.Error("[DyeMerge]进入了无效的关卡，stageId: " .. tostring(stageId))
        return
    end
    
    local stageCfg = self:GetTableDyeMergeMapById(stageId)
    
    local rowCount = XTool.GetTableCount(stageCfg)
    --- 约定配置地图时必须全部有值，因此只需要读第一行的列数即可
    local columnCount = not XTool.IsTableEmpty(stageCfg) and XTool.GetTableCount(stageCfg[1].Columns) or 0

    if columnCount == 0 then
        XLog.Error("[DyeMerge]地图列数异常，请检查对应关卡的地图配置, stageId: " .. tostring(stageId))
        return
    end

    self.MapControl:Init(columnCount, rowCount)
    
    local mapList = self.MapControl:GetMapList()
    local influencesList = {}
    local influencesDirList = {}
    local influencesColorList = {}

    for y, row in pairs(stageCfg) do
        for x, id in pairs(row.Columns) do
            if self:IsValidBlockId(id) then
                local addSuccess, uid = self.BlocksControl:AddNewBlock(id, x, y)

                if addSuccess then
                    -- 复用列表清除缓存
                    for i = #influencesList, 1, -1 do
                        influencesList[i] = nil
                        influencesDirList[i] = nil
                        influencesColorList[i] = nil
                    end

                    influencesList, influencesDirList, influencesColorList = self.BlocksControl:GetBlockInfluenceCells(uid, mapList, influencesList, influencesDirList, influencesColorList)

                    -- 将该方块的影响范围记录到地图中
                    if not XTool.IsTableEmpty(influencesList) then
                        for i, v in pairs(influencesList) do
                            self.MapControl:AddBlockInfluence(uid, v, influencesDirList[i], influencesColorList[i])
                        end
                    end
                end
            end
        end
    end

    -- 初始化射线和 Target 受色状态（此时 UI 层尚未创建，不走命令/动画系统）
    self.BlocksControl:RefreshTurnableRayInfluences(mapList)
    self.BlocksControl:UpdateTargetReceivedColors(mapList)

    -- [Test] 保存初始化完成时的逻辑层快照，供重置比对使用
    self._TestInitSnapshot = self:TestTakeLogicSnapshot()
    self._IsDirty = false
    
    -- 提示窗小窗模式
    self._IsTipsSmallWindowOpen = nil
end

function XDyeMergeGamingControl:IsInitPhase()
    return self._IsInitPhase == true
end

function XDyeMergeGamingControl:SetInitPhaseState(isInit)
    self._IsInitPhase = isInit
end

function XDyeMergeGamingControl:SetCurrentState(isSelect)
    self._IsSelect = isSelect
end

--- E: 已选中 → 点击空地格 → 将选中块移动到该格并放置
---@param selectUid number 已选中方块的 uid
---@param targetX number  目标格 X
---@param targetY number  目标格 Y
function XDyeMergeGamingControl:_ExecutePlaceBlock(selectUid, targetX, targetY)
    self.CommandControl:EnqueueRemoveBlockInfluence(selectUid)
    self.CommandControl:EnqueueDetachBlock(selectUid)
    self.CommandControl:EnqueueAttachBlock(selectUid, targetX, targetY)
    self.CommandControl:EnqueueAddBlockInfluence(selectUid)
    self.CommandControl:EnqueueSetBlockPlacedState(selectUid, true)
    self.CommandControl:EnqueueUpdateBlocksState()
    self.CommandControl:Execute()
    self._IsSelect = false
    self._SelectUid = nil
    self._IsDirty = true
end

--- F: 已选中 → 点击另一个可移动方块 → 交换两块位置
---@param selectUid  number 已选中方块的 uid
---@param clickedUid number 被点击方块的 uid
function XDyeMergeGamingControl:_ExecuteSwapBlocks(selectUid, clickedUid)
    local selectBlock  = self.BlocksControl:GetBlockByUid(selectUid)
    local clickedBlock = self.BlocksControl:GetBlockByUid(clickedUid)
    local x1, y1 = selectBlock:GetX(),  selectBlock:GetY()
    local x2, y2 = clickedBlock:GetX(), clickedBlock:GetY()

    self.CommandControl:EnqueueRemoveBlockInfluence(selectUid)
    self.CommandControl:EnqueueRemoveBlockInfluence(clickedUid)
    self.CommandControl:EnqueueSetBlockPlacedState(clickedUid, false)
    self.CommandControl:EnqueueDetachBlock(selectUid)
    self.CommandControl:EnqueueDetachBlock(clickedUid)
    self.CommandControl:EnqueueAttachBlock(selectUid,  x2, y2)
    self.CommandControl:EnqueueAttachBlock(clickedUid, x1, y1)
    self.CommandControl:EnqueueSetBlockPlacedState(selectUid,  true)
    self.CommandControl:EnqueueSetBlockPlacedState(clickedUid, true)
    self.CommandControl:EnqueueAddBlockInfluence(selectUid)
    self.CommandControl:EnqueueAddBlockInfluence(clickedUid)
    self.CommandControl:EnqueueUpdateBlocksState()
    self.CommandControl:Execute()
    self._IsSelect = false
    self._SelectUid = nil
    self._IsDirty = true
end

--- G-cancel: 已选中 → 再次点击同一方块 → 取消选中（恢复放置状态）
---@param uid number
function XDyeMergeGamingControl:_ExecuteCancelSelect(uid)
    self.CommandControl:EnqueueSetBlockPlacedState(uid, true)
    self.CommandControl:Execute()
    self._IsSelect = false
    self._SelectUid = nil
end

--- G: 未选中 → 点击可移动方块 → 选中（标记悬空）
---@param uid number
function XDyeMergeGamingControl:_ExecuteSelectBlock(uid)
    self.CommandControl:EnqueueSetBlockPlacedState(uid, false, true)
    self.CommandControl:Execute()
    self._IsSelect = true
    self._SelectUid = uid
end

--- H: 未选中 → 点击不可移动方块 → 按 blockType 切换状态
---@param uid number
---@param blockType number
function XDyeMergeGamingControl:_ExecuteToggleBlockState(uid, blockType)
    local block = self.BlocksControl:GetBlockByUid(uid)
    local BT = XMVCA.XDyeMergeGame.EnumConst.BlockType

    self.CommandControl:EnqueueRemoveBlockInfluence(uid)

    if blockType == BT.TurnableMultyColor then
        self._PendingLineAnimUid = uid
        self.CommandControl:EnqueueRotateBlock(uid)
    elseif blockType == BT.VariableLength then
        self.CommandControl:EnqueueChangeBlockLength(uid, block:GetId())
    elseif blockType == BT.ColorChangeable then
        -- 从配置 Params 列表中循环取下一个颜色索引
        local cfg = self:GetTableDyeMergeBlockById(block:GetId())
        local colorList = cfg and cfg.Params
        local curColor = block:GetChangeableColorIndex()
        local nextColor = curColor
        if colorList and #colorList > 0 then
            local curPos = 1
            for i, v in ipairs(colorList) do
                if v == curColor then
                    curPos = i
                    break
                end
            end
            nextColor = colorList[curPos % #colorList + 1]
        end
        self.CommandControl:EnqueueChangeBlockColor(uid, nextColor)
    elseif blockType == BT.Mirror then
        self.CommandControl:EnqueueRotateBlock(uid)
    end

    self.CommandControl:EnqueueAddBlockInfluence(uid)
    self.CommandControl:EnqueueUpdateBlocksState()
    self.CommandControl:Execute()
    self._IsDirty = true
end

function XDyeMergeGamingControl:ConsumePendingLineAnimUid()
    local uid = self._PendingLineAnimUid
    self._PendingLineAnimUid = nil
    return uid
end

function XDyeMergeGamingControl:SetPendingExtendAnim(uid, oldLen, newLen)
    self._PendingExtendAnim = { Uid = uid, OldLen = oldLen, NewLen = newLen }
end

function XDyeMergeGamingControl:ConsumePendingExtendAnim()
    local data = self._PendingExtendAnim
    self._PendingExtendAnim = nil
    return data
end

function XDyeMergeGamingControl:HasPendingShrinkAnim(uid)
    local d = self._PendingExtendAnim
    return d ~= nil and d.Uid == uid and d.NewLen < d.OldLen
end

function XDyeMergeGamingControl:SetExtendEnablePendingUid(uid)
    self._ExtendEnablePendingUid = uid
end

function XDyeMergeGamingControl:ConsumeExtendEnablePendingUid()
    local uid = self._ExtendEnablePendingUid
    self._ExtendEnablePendingUid = nil
    return uid
end

--- 根据外部的交互沟通逻辑层
function XDyeMergeGamingControl:OnUiGridClick(uid)
    if self:CheckIsInteractionLocked() then return end
    local block = self.BlocksControl:GetBlockByUid(uid)
    local blockType = block:GetType()

    -- XLog.Debug("[DyeMerge][OnUiGridClick] uid=" .. tostring(uid) .. " blockType=" .. tostring(blockType) .. " canMove=" .. tostring(block:GetCanMove()) .. " isSelect=" .. tostring(self._IsSelect))

    if self._IsSelect then
        if uid == self._SelectUid then
            self:_ExecuteCancelSelect(uid)
        elseif block:GetCanMove() then
            self:_ExecuteSwapBlocks(self._SelectUid, uid)
        end
    else
        if block:GetCanMove() then
            self:_ExecuteSelectBlock(uid)
        else
            self:_ExecuteToggleBlockState(uid, blockType)
        end
    end
end

function XDyeMergeGamingControl:OnUiFloorClick(x, y)
    if self:CheckIsInteractionLocked() then return end
    local _, id = self:IsGridValid(x, y)
    if id == FLOOR_DISPLAY_ONLY then return end
    if self._IsSelect then
        self:_ExecutePlaceBlock(self._SelectUid, x, y)
    end
end

--region 重置关卡

--- 重置关卡到初始状态（不销毁/重建 Control 对象）
--- 传入 newStageId 可切换到新关卡，不传则重置当前关
function XDyeMergeGamingControl:ResetGame(newStageId)
    local stageId = newStageId or self._CurStageId

    if not XTool.IsNumberValidEx(stageId) then
        XLog.Error("[DyeMerge]ResetGame: 当前无有效关卡")
        return
    end

    -- 中断命令队列（回收所有命令 + Generation 递增使旧异步回调失效）
    self.CommandControl.CommandSystem:Reset()

    -- 清除选中状态
    self._IsSelect = false
    self._SelectUid = nil

    -- 重新初始化（内部已包含三个子 Control 的 ResetData + 地图构建 + 射线刷新 + Target 受色）
    self:InitGame(stageId)
end

--endregion

function XDyeMergeGamingControl:SetIsTipsSmallWindowOpen(isOpen)
    self._IsTipsSmallWindowOpen = isOpen
end

function XDyeMergeGamingControl:GetIsTipsSmallWindowOpen()
    return self._IsTipsSmallWindowOpen
end

--region [Test] 逻辑层快照

--- [Test] 拍摄逻辑层数据快照，用于重置前后比对
---@return table
function XDyeMergeGamingControl:TestTakeLogicSnapshot()
    local snapshot = {}
    snapshot.StageId = self._CurStageId

    -- 方块快照
    snapshot.Blocks = {}
    local blocks = self.BlocksControl:GetUsingBlockList()
    for _, block in pairs(blocks) do
        table.insert(snapshot.Blocks, {
            Id = block:GetId(),
            Uid = block:GetUid(),
            Type = block:GetType(),
            X = block:GetX(),
            Y = block:GetY(),
            RotateIndex = block:GetRotateIndex(),
            ColorIndex = block:GetChangeableColorIndex(),
            Length = block:GetVariableLength(),
            IsExpand = block:GetVariableIsExpand(),
            ReceivedColor = block:GetReceivedColor(),
        })
    end

    -- 地图快照
    snapshot.MapList = {}
    local mapList = self.MapControl:GetMapList()
    for k, v in pairs(mapList) do
        snapshot.MapList[k] = v
    end

    return snapshot
end

--- [Test] 将当前逻辑层数据与先前拍摄的快照进行比对，差异以 XLog.Warning 输出
---@param snapshot table TestTakeLogicSnapshot 的返回值
function XDyeMergeGamingControl:TestCompareLogicSnapshot(snapshot)
    if not snapshot then return end

    local prefix = "[DyeMerge][TestReset] "

    if self._CurStageId ~= snapshot.StageId then
        XLog.Warning(prefix .. "StageId 不一致: 期望=" .. tostring(snapshot.StageId) .. " 实际=" .. tostring(self._CurStageId))
    end

    local curBlocks = self.BlocksControl:GetUsingBlockList()
    local curCount = XTool.GetTableCount(curBlocks)
    local snapCount = #snapshot.Blocks

    if curCount ~= snapCount then
        XLog.Warning(prefix .. "方块数量不一致: 期望=" .. tostring(snapCount) .. " 实际=" .. tostring(curCount))
    end

    for _, snapBlock in ipairs(snapshot.Blocks) do
        local curBlock = self.BlocksControl:GetBlockByUid(snapBlock.Uid)
        if not curBlock then
            XLog.Warning(prefix .. "方块 Uid=" .. tostring(snapBlock.Uid) .. " 重置后不存在")
        else
            local checks = {
                { "Id", curBlock:GetId() },
                { "Type", curBlock:GetType() },
                { "X", curBlock:GetX() },
                { "Y", curBlock:GetY() },
                { "RotateIndex", curBlock:GetRotateIndex() },
            }
            for _, check in ipairs(checks) do
                if snapBlock[check[1]] ~= check[2] then
                    XLog.Warning(prefix .. "方块 Uid=" .. tostring(snapBlock.Uid) .. " " .. check[1] .. " 不一致: 期望=" .. tostring(snapBlock[check[1]]) .. " 实际=" .. tostring(check[2]))
                end
            end
        end
    end

    -- 比较地图占位
    local curMapList = self.MapControl:GetMapList()
    for k, v in pairs(snapshot.MapList) do
        if curMapList[k] ~= v then
            XLog.Warning(prefix .. "MapList[" .. tostring(k) .. "] 不一致: 期望=" .. tostring(v) .. " 实际=" .. tostring(curMapList[k]))
        end
    end
    for k, v in pairs(curMapList) do
        if snapshot.MapList[k] == nil then
            XLog.Warning(prefix .. "MapList[" .. tostring(k) .. "] 重置后多出: " .. tostring(v))
        end
    end

    XLog.Debug(prefix .. "逻辑层快照比对完成")
end

--endregion

--region 埋点上报

--- 重置埋点数据：新关卡全量初始化，重置当前关仅递增重置次数
function XDyeMergeGamingControl:_ResetRecordData(stageId)
    if stageId ~= self._CurStageId then
        self._RecordStartTime = XTime.GetServerNowTimestamp()
        self._RecordResetCount = 0
        self._RecordHasViewedTips = false
    else
        self._RecordResetCount = (self._RecordResetCount or 0) + 1
    end
end

--- 统一上报关卡结果，上报后置 _RecordStartTime = nil 防止重复上报
function XDyeMergeGamingControl:_RecordStageResult(isWin)
    if not XTool.IsNumberValidEx(self._CurStageId) then return end
    if not XTool.IsNumberValidEx(self._RecordStartTime) then return end

    local duration = XTime.GetServerNowTimestamp() - self._RecordStartTime
    local dict = {}
    dict["stage_id"] = self._CurStageId
    dict["play_duration"] = duration
    dict["reset_count"] = self._RecordResetCount or 0
    dict["has_viewed_tips"] = self._RecordHasViewedTips and 1 or 0
    dict["is_win"] = isWin and 1 or 0

    if XMain.IsWindowsEditor then
        CS.XRecord.RecordTest(dict, "1000046", "DyeMergeStageResult")
    else
        CS.XRecord.Record(dict, "1000046", "DyeMergeStageResult")
    end

    self._RecordStartTime = nil
end

--- 标记玩家已查看过提示
function XDyeMergeGamingControl:MarkTipsViewed()
    self._RecordHasViewedTips = true
end

--- 退出时上报关卡结果（供外部 Control 调用）
function XDyeMergeGamingControl:RecordExitResult()
    self:_RecordStageResult(false)
end

--endregion

return XDyeMergeGamingControl