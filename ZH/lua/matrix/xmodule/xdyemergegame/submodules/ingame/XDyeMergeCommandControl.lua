--- 负责局内命令系统的调度
---@class XDyeMergeCommandControl : XControl
---@field private _Model XDyeMergeGameModel
---@field _MainControl XDyeMergeGamingControl
local XDyeMergeCommandControl = XClass(XControl, "XDyeMergeCommandControl")

function XDyeMergeCommandControl:OnInit()
    self:_InitCommandSystem()
end

function XDyeMergeCommandControl:AddAgencyEvent()

end

function XDyeMergeCommandControl:RemoveAgencyEvent()

end

function XDyeMergeCommandControl:OnRelease()

end

function XDyeMergeCommandControl:_InitCommandSystem()
    ---@type XGameCommandControl 通用命令系统驱动器
    self.CommandSystem = require("XModule/XDyeMergeGame/CommandSystem/XGameCommandControl").New(nil, nil, 0)

    self.CommandSystem:Init()
    self.CommandSystem:RegisterExecutor(XMVCA.XDyeMergeGame.EnumConst.CommandType.RemoveBlockInfluence, self:_WrapExecutor(self._RemoveBlockInfluence))
    self.CommandSystem:RegisterExecutor(XMVCA.XDyeMergeGame.EnumConst.CommandType.AddBlockInfluence, self:_WrapExecutor(self._AddBlockInfluence))
    self.CommandSystem:RegisterExecutor(XMVCA.XDyeMergeGame.EnumConst.CommandType.SetBlockPlacedState, self:_WrapExecutor(self._SetBlockPlacedState))
    self.CommandSystem:RegisterExecutor(XMVCA.XDyeMergeGame.EnumConst.CommandType.UpdateBlocksState, self:_WrapExecutor(self._UpdateBlocksState))
    self.CommandSystem:RegisterExecutor(XMVCA.XDyeMergeGame.EnumConst.CommandType.ChangeBlockColor, self:_WrapExecutor(self._ChangeBlockColor))
    self.CommandSystem:RegisterExecutor(XMVCA.XDyeMergeGame.EnumConst.CommandType.RotateBlock, self:_WrapExecutor(self._RotateBlock))
    self.CommandSystem:RegisterExecutor(XMVCA.XDyeMergeGame.EnumConst.CommandType.ChangeBlockLength, self:_WrapExecutor(self._ChangeBlockLength))
    self.CommandSystem:RegisterExecutor(XMVCA.XDyeMergeGame.EnumConst.CommandType.DetachBlock, self:_WrapExecutor(self._DetachBlock))
    self.CommandSystem:RegisterExecutor(XMVCA.XDyeMergeGame.EnumConst.CommandType.AttachBlock, self:_WrapExecutor(self._AttachBlock))
end

--- 将成员方法包装为 CommandSystem 期望的 executor 对象（含 OnExecuteCommand 字段）
function XDyeMergeCommandControl:_WrapExecutor(method)
    local ctrl = self
    return {
        OnExecuteCommand = function(_, params, finishHandle)
            method(ctrl, params, finishHandle)
        end
    }
end

--region 命令入队接口
--- 以下方法仅负责将命令压入队列，不触发执行。
--- 调用方在所有 Enqueue 完毕后统一调用 Execute() 驱动队列。

function XDyeMergeCommandControl:EnqueueRemoveBlockInfluence(uid)
    local cmd = self.CommandSystem:GetCommandFromPool(XMVCA.XDyeMergeGame.EnumConst.CommandType.RemoveBlockInfluence)
    cmd:SetParam("BlockUid", uid)
    self.CommandSystem:AddCommand(cmd)
end

function XDyeMergeCommandControl:EnqueueAddBlockInfluence(uid)
    local cmd = self.CommandSystem:GetCommandFromPool(XMVCA.XDyeMergeGame.EnumConst.CommandType.AddBlockInfluence)
    cmd:SetParam("BlockUid", uid)
    self.CommandSystem:AddCommand(cmd)
end

---@param isPlaced boolean
function XDyeMergeCommandControl:EnqueueSetBlockPlacedState(uid, isPlaced, withSelectAnim)
    local cmd = self.CommandSystem:GetCommandFromPool(XMVCA.XDyeMergeGame.EnumConst.CommandType.SetBlockPlacedState)
    cmd:SetParam("BlockUid", uid)
    cmd:SetParam("IsPlaced", isPlaced)
    cmd:SetParam("WithSelectAnim", withSelectAnim)
    self.CommandSystem:AddCommand(cmd)
end

function XDyeMergeCommandControl:EnqueueUpdateBlocksState()
    local cmd = self.CommandSystem:GetCommandFromPool(XMVCA.XDyeMergeGame.EnumConst.CommandType.UpdateBlocksState)
    self.CommandSystem:AddCommand(cmd)
end

function XDyeMergeCommandControl:EnqueueRotateBlock(uid)
    local cmd = self.CommandSystem:GetCommandFromPool(XMVCA.XDyeMergeGame.EnumConst.CommandType.RotateBlock)
    cmd:SetParam("BlockUid", uid)
    self.CommandSystem:AddCommand(cmd)
end

---@param blockId number 配置表 Id，供执行者做越界修正
function XDyeMergeCommandControl:EnqueueChangeBlockLength(uid, blockId)
    local cmd = self.CommandSystem:GetCommandFromPool(XMVCA.XDyeMergeGame.EnumConst.CommandType.ChangeBlockLength)
    cmd:SetParam("BlockUid", uid)
    cmd:SetParam("BlockId", blockId)
    self.CommandSystem:AddCommand(cmd)
end

---@param newColorIndex number
function XDyeMergeCommandControl:EnqueueChangeBlockColor(uid, newColorIndex)
    local cmd = self.CommandSystem:GetCommandFromPool(XMVCA.XDyeMergeGame.EnumConst.CommandType.ChangeBlockColor)
    cmd:SetParam("BlockUid", uid)
    cmd:SetParam("NewColorIndex", newColorIndex)
    self.CommandSystem:AddCommand(cmd)
end

function XDyeMergeCommandControl:EnqueueDetachBlock(uid)
    local cmd = self.CommandSystem:GetCommandFromPool(XMVCA.XDyeMergeGame.EnumConst.CommandType.DetachBlock)
    cmd:SetParam("BlockUid", uid)
    self.CommandSystem:AddCommand(cmd)
end

function XDyeMergeCommandControl:EnqueueAttachBlock(uid, x, y)
    local cmd = self.CommandSystem:GetCommandFromPool(XMVCA.XDyeMergeGame.EnumConst.CommandType.AttachBlock)
    cmd:SetParam("BlockUid", uid)
    cmd:SetParam("NewPosX", x)
    cmd:SetParam("NewPosY", y)
    self.CommandSystem:AddCommand(cmd)
end

--- 驱动命令队列开始执行，全部完成后启动动画列表播放
function XDyeMergeCommandControl:Execute()
    XLog.Debug("[DyeMerge][CommandControl] 命令队列开始执行")
    self._MainControl.AnimationControl:ResetData()
    self.CommandSystem:TryDoNextCommand(function()
        XLog.Debug("[DyeMerge][CommandControl] 命令队列全部完成，启动动画列表")
        self._MainControl.AnimationControl:StartAnimations(function()
            self._MainControl:CheckAndTryPassStage()
        end)
    end)
end

--endregion

--region 命令执行者

---@param params XDyeMergeCommandParams
function XDyeMergeCommandControl:_RemoveBlockInfluence(params, finishCb)
    self._MainControl.MapControl:RemoveBlockInfluences(params.BlockUid)

    if finishCb then
        finishCb()
    end
end

---@param params XDyeMergeCommandParams
function XDyeMergeCommandControl:_AddBlockInfluence(params, finishCb)
    local uid = params.BlockUid
    local mapList = self._MainControl.MapControl:GetMapList()

    local in_list, in_dirList, in_colorList = self._MainControl.BlocksControl:GetBlockInfluenceCells(uid, mapList)

    if not XTool.IsTableEmpty(in_list) then
        for i, posIndex in pairs(in_list) do
            self._MainControl.MapControl:AddBlockInfluence(uid, posIndex, in_dirList[i], in_colorList[i])
        end
    end

    if finishCb then
        finishCb()
    end
end

---@param params XDyeMerge.SetBlockPlacedStateParams
function XDyeMergeCommandControl:_SetBlockPlacedState(params, finishCb)
    local block = self._MainControl.BlocksControl:GetBlockByUid(params.BlockUid)

    if block then
        block:SetPlacedState(params.IsPlaced)
    end

    -- 标记状态
    self._MainControl:SetCurrentState(not params.IsPlaced)

    if params.IsPlaced then
        self._MainControl.AnimationControl:EnqueuePlacedGridAnimation(params.BlockUid)
    elseif params.WithSelectAnim then
        self._MainControl.AnimationControl:EnqueueSelectGridAnimation(params.BlockUid)
    end

    if finishCb then
        finishCb()
    end
end

---@param params XDyeMergeCommandParams
function XDyeMergeCommandControl:_UpdateBlocksState(params, finishCb)
    local mapList = self._MainControl.MapControl:GetMapList()
    self._MainControl.BlocksControl:RefreshTurnableRayInfluences(mapList)
    self._MainControl.BlocksControl:UpdateTargetReceivedColors(mapList)

    self._MainControl.AnimationControl:EnqueueUpdateAllStateAnimation()

    if finishCb then
        finishCb()
    end
end

---@param params XDyeMerge.ChangeBlockColorParams
function XDyeMergeCommandControl:_ChangeBlockColor(params, finishCb)
    -- 将可变色方块的颜色索引切换为指定的新颜色索引
    local block = self._MainControl.BlocksControl:GetBlockByUid(params.BlockUid)

    if block then
        block:SetChangeableColorIndex(params.NewColorIndex)
    end

    if finishCb then
        finishCb()
    end
end

---@param params XDyeMergeCommandParams
function XDyeMergeCommandControl:_RotateBlock(params, finishCb)
    -- 默认按顺时针执行旋转，一个指令旋转一个离散值
    local block = self._MainControl.BlocksControl:GetBlockByUid(params.BlockUid)

    if block then
        local oldIndex = block:GetRotateIndex()
        local newIndex = math.fmod((oldIndex + 1), 4)

        block:SetRotateIndex(newIndex)
    end

    if finishCb then
        finishCb()
    end
end

---@param params XDyeMergeCommandParams
function XDyeMergeCommandControl:_ChangeBlockLength(params, finishCb)
    local block = self._MainControl.BlocksControl:GetBlockByUid(params.BlockUid)
    local cfg = self._MainControl:GetTableDyeMergeBlockById(params.BlockId)

    XLog.Debug("[DyeMerge][ChangeBlockLength] uid=" .. tostring(params.BlockUid) .. " blockId=" .. tostring(params.BlockId) .. " hasBlock=" .. tostring(block ~= nil) .. " hasCfg=" .. tostring(cfg ~= nil))

    if block and cfg then
        local oldLen = block:GetVariableLength()
        local expand = block:GetVariableIsExpand()

        local newLen = expand and oldLen + 2 or oldLen - 2

        local minLen = cfg.Params[XMVCA.XDyeMergeGame.EnumConst.BlockCfgParams.VariableLength.MinLen]
        local maxLen = cfg.Params[XMVCA.XDyeMergeGame.EnumConst.BlockCfgParams.VariableLength.MaxLen]

        XLog.Debug("[DyeMerge][ChangeBlockLength] oldLen=" .. tostring(oldLen) .. " expand=" .. tostring(expand) .. " newLen(raw)=" .. tostring(newLen) .. " minLen=" .. tostring(minLen) .. " maxLen=" .. tostring(maxLen))

        -- 越界修正
        newLen = XMath.Clamp(newLen, minLen, maxLen)
        -- 根据最新的长度，调整下次的延伸方向
        if newLen == maxLen then
            expand = false
        elseif newLen == minLen then
            expand = true
        end
        
        block:SetVariableLength(newLen, expand)
        self._MainControl:DispatchEvent(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_BLOCK_DEPTH_DIRTY, params.BlockUid)
    end

    if finishCb then
        finishCb()
    end
end

--- 将方块从位置注册表中注销，保留方块自身坐标不变
--- 执行后目标格在 Pos2BlockMap 中清空，可供其他方块 Attach
---@param params XDyeMergeCommandParams
function XDyeMergeCommandControl:_DetachBlock(params, finishCb)
    self._MainControl.BlocksControl:DetachBlockFromPos(params.BlockUid)

    if finishCb then
        finishCb()
    end
end

--- 将方块绑定到新坐标并写入位置注册表
--- 执行前必须确保目标格已通过 DetachBlock 腾空
---@param params XDyeMerge.AttachBlockParams
function XDyeMergeCommandControl:_AttachBlock(params, finishCb)
    self._MainControl.BlocksControl:AttachBlockToPos(params.BlockUid, params.NewPosX, params.NewPosY)
    self._MainControl:DispatchEvent(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_BLOCK_DEPTH_DIRTY, params.BlockUid)

    if finishCb then
        finishCb()
    end
end

--endregion

return XDyeMergeCommandControl


--region 命令参数定义

---@class XDyeMergeCommandParams: XGameCommandParams
---@field BlockUid number
---@field BlockId number

---@class XDyeMerge.SetBlockPlacedStateParams: XDyeMergeCommandParams
---@field IsPlaced boolean
---@field WithSelectAnim boolean

--- DetachBlock 直接复用基础参数，仅需 BlockUid，无额外字段

---@class XDyeMerge.AttachBlockParams: XDyeMergeCommandParams
---@field NewPosX number 目标格 X 坐标
---@field NewPosY number 目标格 Y 坐标

---@class XDyeMerge.ChangeBlockColorParams: XDyeMergeCommandParams
---@field OldColorIndex number
---@field NewColorIndex number

--endregion