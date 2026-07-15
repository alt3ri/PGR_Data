---@class XDyeMergeAnimationControl : XControl
---@field _MainControl XDyeMergeGamingControl
---@field private _Model XDyeMergeGameModel
local XDyeMergeAnimationControl = XClass(XControl, "XDyeMergeAnimationControl")

function XDyeMergeAnimationControl:OnInit()
    ---@type XGameAnimationControl
    self.AnimationCtrl = require("XModule/XDyeMergeGame/AnimationSystem/XGameAnimationControl").New()
    
    self.AnimationCtrl:Init(nil, nil, XMVCA.XDyeMergeGame.EnumConst.AnimationType, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority)
    self.AnimationCtrl:InitAnimationCallbacks(handler(self ,self.OnAnimationStart))
end

function XDyeMergeAnimationControl:AddAgencyEvent()

end

function XDyeMergeAnimationControl:RemoveAgencyEvent()

end

function XDyeMergeAnimationControl:OnRelease()

end

function XDyeMergeAnimationControl:ResetData()
    self.AnimationCtrl:Reset()
end

function XDyeMergeAnimationControl:StartAnimations(cb)
    self.AnimationCtrl:StartAnimationList(cb)
end

---@param params XGameAnimationParams
function XDyeMergeAnimationControl:OnAnimationStart(actionType, params)
    -- XLog.Debug("[DyeMerge][AnimationControl] 动画开始广播 actionType=" .. tostring(actionType) .. " blockUid=" .. tostring(params.BlockUid))
    self._MainControl:DispatchEvent(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_ANIMATION_RUN, actionType, params)
end

function XDyeMergeAnimationControl:OnEndAnimation(params, isBreak)
    self.AnimationCtrl:EndAnimation(params, isBreak)
end

--region 具体的动画入队封装接口

--- 入队"选中方块"动画（SelectGrid）
---@param uid number 被选中的方块 uid
function XDyeMergeAnimationControl:EnqueueSelectGridAnimation(uid)
    -- XLog.Debug("[DyeMerge][AnimationControl] 入队 SelectGrid uid=" .. tostring(uid))
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.SelectGrid)
    anim:SetParam("BlockUid", uid)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.SelectGrid)
end

--- 入队"放置方块"动画（PlacedGird）
---@param uid number 被放置的方块 uid
function XDyeMergeAnimationControl:EnqueuePlacedGridAnimation(uid)
    -- XLog.Debug("[DyeMerge][AnimationControl] 入队 PlacedGird uid=" .. tostring(uid))
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.PlacedGird)
    anim:SetParam("BlockUid", uid)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.PlacedGird)
end

--- 入队"更新所有方块状态"动画（UpdateAllState）
function XDyeMergeAnimationControl:EnqueueUpdateAllStateAnimation()
    -- XLog.Debug("[DyeMerge][AnimationControl] 入队 UpdateAllState")
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.UpdateAllState)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.UpdateAllState)
end

--- 入队"通关后刷新表现"动画（StagePassed）
function XDyeMergeAnimationControl:EnqueueStagePassedAnimation()
    -- XLog.Debug("[DyeMerge][AnimationControl] 入队 StagePassed")
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.StagePassed)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.StagePassed)
end

--- 入队"旋转方块线条缩回"动画（TurnableRetractLines）
---@param uid number 旋转方块 uid
function XDyeMergeAnimationControl:EnqueueRetractLinesAnimation(uid)
    -- XLog.Debug("[DyeMerge][AnimationControl] 入队 TurnableRetractLines uid=" .. tostring(uid))
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.TurnableRetractLines)
    anim:SetParam("BlockUid", uid)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.TurnableRetractLines)
end

--- 入队"旋转方块线条延伸"动画（TurnableExtendLines）
---@param uid number 旋转方块 uid
function XDyeMergeAnimationControl:EnqueueExtendLinesAnimation(uid)
    -- XLog.Debug("[DyeMerge][AnimationControl] 入队 TurnableExtendLines uid=" .. tostring(uid))
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.TurnableExtendLines)
    anim:SetParam("BlockUid", uid)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.TurnableExtendLines)
end

--- 入队"延伸块切片缩回 Disable"动画
---@param uid number 延伸块 uid
---@param oldLen number 变化前的长度
function XDyeMergeAnimationControl:EnqueueExtendBlockDisableAnimation(uid, oldLen)
    -- XLog.Debug("[DyeMerge][AnimationControl] 入队 ExtendBlockDisable uid=" .. tostring(uid))
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.ExtendBlockDisable)
    anim:SetParam("BlockUid", uid)
    anim:SetParam("OldLen", oldLen)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.ExtendBlockDisable)
end

--- 入队"延伸块切片延伸 Enable"动画
---@param uid number 延伸块 uid
---@param oldLen number 变化前的长度
function XDyeMergeAnimationControl:EnqueueExtendBlockEnableAnimation(uid, oldLen)
    -- XLog.Debug("[DyeMerge][AnimationControl] 入队 ExtendBlockEnable uid=" .. tostring(uid))
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.ExtendBlockEnable)
    anim:SetParam("BlockUid", uid)
    anim:SetParam("OldLen", oldLen)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.ExtendBlockEnable)
end

--endregion

return XDyeMergeAnimationControl