local XQuestBaseAction = require("XUi/XUiBigWorld/XHud/Action/XQuestBaseAction")

---@class XQuestPlayAnimationAction : XQuestBaseAction
---@field _Transform UnityEngine.Transform
local XQuestPlayAnimationAction = XClass(XQuestBaseAction, "XQuestPlayAnimationAction")

local WrapHold = CS.UnityEngine.Playables.DirectorWrapMode.Hold

function XQuestPlayAnimationAction:OnInit(transform, ...)
    self._Transform = transform
    self._IsPlaying = false
end

function XQuestPlayAnimationAction:Execute()
    if XTool.UObjIsNil(self._Transform) then
        return self:Finish()
    end

    if not self._Transform.gameObject.activeInHierarchy then
        return self._Container:Pause()
    end

    self._IsPlaying = true
    self._Transform:PlayTimelineAnimation(function(isFinish)
        if isFinish then
            self:Finish()
        end
    end, nil, WrapHold, true)
end

function XQuestPlayAnimationAction:OnFinish()
    self._Transform = nil
    self._IsPlaying = false
end

function XQuestPlayAnimationAction:OnPause()
    if self._IsPlaying then
        return
    end
    self._Container:InsertFirst(self)
end

function XQuestPlayAnimationAction:OnResume()
    --已经播放了，等待播放完成回调往后执行
    if self._IsPlaying then
        return
    end
    XQuestBaseAction.OnResume(self)
end

function XQuestPlayAnimationAction:GetActionType()
    return XMVCA.XBigWorldQuest.ActionType.PlayAnimation
end

return XQuestPlayAnimationAction