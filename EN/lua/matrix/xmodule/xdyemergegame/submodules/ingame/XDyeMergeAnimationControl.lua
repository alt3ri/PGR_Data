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
    XLog.Debug("[DyeMerge][AnimationControl] 动画开始广播 actionType=" .. tostring(actionType) .. " blockUid=" .. tostring(params.BlockUid))
    self._MainControl:DispatchEvent(XMVCA.XDyeMergeGame.EventIds.EVENT_DYEMERGE_INNER_ANIMATION_RUN, actionType, params)
end

function XDyeMergeAnimationControl:OnEndAnimation(params, isBreak)
    self.AnimationCtrl:EndAnimation(params, isBreak)
end

--region 具体的动画入队封装接口

--- 入队"选中方块"动画（SelectGrid）
---@param uid number 被选中的方块 uid
function XDyeMergeAnimationControl:EnqueueSelectGridAnimation(uid)
    XLog.Debug("[DyeMerge][AnimationControl] 入队 SelectGrid uid=" .. tostring(uid))
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.SelectGrid)
    anim:SetParam("BlockUid", uid)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.SelectGrid)
end

--- 入队"放置方块"动画（PlacedGird）
---@param uid number 被放置的方块 uid
function XDyeMergeAnimationControl:EnqueuePlacedGridAnimation(uid)
    XLog.Debug("[DyeMerge][AnimationControl] 入队 PlacedGird uid=" .. tostring(uid))
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.PlacedGird)
    anim:SetParam("BlockUid", uid)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.PlacedGird)
end

--- 入队"更新所有方块状态"动画（UpdateAllState）
function XDyeMergeAnimationControl:EnqueueUpdateAllStateAnimation()
    XLog.Debug("[DyeMerge][AnimationControl] 入队 UpdateAllState")
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.UpdateAllState)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.UpdateAllState)
end

--- 入队"通关后刷新表现"动画（StagePassed）
function XDyeMergeAnimationControl:EnqueueStagePassedAnimation()
    XLog.Debug("[DyeMerge][AnimationControl] 入队 StagePassed")
    local AT = XMVCA.XDyeMergeGame.EnumConst.AnimationType
    local anim = self.AnimationCtrl:GetAnimationFromPool()
    anim:SetParam("ActionType", AT.StagePassed)
    self.AnimationCtrl:InsertActionToList(anim, XMVCA.XDyeMergeGame.EnumConst.AnimationPriority.StagePassed)
end

--endregion

return XDyeMergeAnimationControl