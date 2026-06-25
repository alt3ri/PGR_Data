---@class XUiConcertPreHeatingPanelSpine : XUiNode
local XUiConcertPreHeatingPanelSpine = XLuaUiManager.Register(XUiNode, "XUiConcertPreHeatingPanelSpine")

function XUiConcertPreHeatingPanelSpine:OnStart(closeCb)
    self._CloseCb = closeCb
    self:InitButton()
    self:HideAllControl()
end

function XUiConcertPreHeatingPanelSpine:OnDestroy()
    self:RemoveSpineComplete()
end

function XUiConcertPreHeatingPanelSpine:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnReplay, self.OnBtnReplayClick)
    XUiHelper.RegisterClickEvent(self, self.BtnCompleted, self.OnBtnCompletedClick)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangCloseBig, self.OnBtnCompletedClick)
    XUiHelper.RegisterClickEvent(self, self.BtnSoundSet, self.OnBtnSoundSetClick)
    XUiHelper.RegisterClickEvent(self, self.BtnHide, self.OnBtnHideClick)
    XUiHelper.RegisterClickEvent(self, self.BtnShow, self.OnBtnShowClick)
end

function XUiConcertPreHeatingPanelSpine:LoadSpinePrefab(spinePrefabUrl)
    self:RemoveSpineComplete()
    local spineGo = self.SpinePrefabRoot:LoadPrefab(spinePrefabUrl)
    self._SkeletonAnimation = spineGo.transform:Find("Root/Role"):GetComponent(typeof(CS.Spine.Unity.SkeletonAnimation))
end

function XUiConcertPreHeatingPanelSpine:PlaySpinePerformance(isFirstPlay, enableCompleteCb)
    self:RemoveSpineComplete()
    if isFirstPlay then
        self:HideAllControl()
    end

    local completeCb
    completeCb = function(track)
        if track.Animation.Name ~= "Enable" then
            return
        end

        self._SkeletonAnimation.AnimationState:SetAnimation(0, "Loop", true)
        self._SkeletonAnimation.AnimationState:Complete("-", completeCb)
        self._SpineCompleteCb = nil
        if enableCompleteCb then
            enableCompleteCb()
        end
        if isFirstPlay then
            self:ShowControl()
        end
    end
    self._SpineCompleteCb = completeCb
    self._SkeletonAnimation.AnimationState:Complete("+", completeCb)
    self._SkeletonAnimation.AnimationState:SetAnimation(0, "Enable", false)
end

function XUiConcertPreHeatingPanelSpine:ShowControl()
    self.PanelHideControlGroup.gameObject:SetActiveEx(true)
    self.BtnShow.gameObject:SetActiveEx(false)
end

function XUiConcertPreHeatingPanelSpine:HideControl()
    self.PanelHideControlGroup.gameObject:SetActiveEx(false)
    self.BtnShow.gameObject:SetActiveEx(true)
end

function XUiConcertPreHeatingPanelSpine:HideAllControl()
    self.PanelHideControlGroup.gameObject:SetActiveEx(false)
    self.BtnShow.gameObject:SetActiveEx(false)
end

function XUiConcertPreHeatingPanelSpine:RemoveSpineComplete()
    if not self._SpineCompleteCb or XTool.UObjIsNil(self._SkeletonAnimation) then
        return
    end

    self._SkeletonAnimation.AnimationState:Complete("-", self._SpineCompleteCb)
    self._SpineCompleteCb = nil
end

function XUiConcertPreHeatingPanelSpine:OnBtnReplayClick()
    self:PlaySpinePerformance()
end

function XUiConcertPreHeatingPanelSpine:OnBtnCompletedClick()
    if self._CloseCb then
        self._CloseCb()
    end
end

function XUiConcertPreHeatingPanelSpine:OnBtnSoundSetClick()
    XLuaUiManager.Open("UiSet")
end

function XUiConcertPreHeatingPanelSpine:OnBtnHideClick()
    self:HideControl()
end

function XUiConcertPreHeatingPanelSpine:OnBtnShowClick()
    self:ShowControl()
end

return XUiConcertPreHeatingPanelSpine
