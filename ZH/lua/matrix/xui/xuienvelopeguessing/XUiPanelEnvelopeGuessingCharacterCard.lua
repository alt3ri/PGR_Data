---@class XUiPanelEnvelopeGuessingCharacterCard : XUiNode
---@field private _Control XEnvelopeGuessingControl
local XUiPanelEnvelopeGuessingCharacterCard = XClass(XUiNode, "XUiPanelEnvelopeGuessingCharacterCard")

function XUiPanelEnvelopeGuessingCharacterCard:OnStart(charConf, onOpenCardCallback)
    self._CharConf = charConf
    self._OnOpenCard = onOpenCardCallback
    self.RlmgCardRole:SetRawImage(charConf.CgAssetPathLocked)
    self.RImgCardBg:SetRawImage(charConf.CgAssetPathUnlocked)
    self.TxtCardTip.text = string.gsub(charConf.Desc, "\\n", "\n")

    self._MaxSlideProgress = CS.XGame.ClientConfig:GetFloat("EnvelopeGuessingEnvelopeCardSlideProgressAuto")
    self._MinSlideProgress = CS.XGame.ClientConfig:GetFloat("EnvelopeGuessingEnvelopeCardSlideProgressMin")

    self:_InitSlider()
end

function XUiPanelEnvelopeGuessingCharacterCard:OnDisable()
    self:_KillReverseOpenPackageAnimation()
end

function XUiPanelEnvelopeGuessingCharacterCard:SetAsOpenedAndPlayUnlockAnimation(isPlay)
    self.RImgCardPackage.gameObject:SetActiveEx(false)
    self.Slider.gameObject:SetActiveEx(false)
    self.TxtCardTip.gameObject:SetActiveEx(false)
    if isPlay then
        self:PlayAnimationWithMask("StoryReadFinished")
    else
        self:ForceSkipToEndAnimation("StoryReadFinished")
    end
end

function XUiPanelEnvelopeGuessingCharacterCard:_InitSlider()
    local sliderRt = self.Slider.transform
    local widget = self.SliderUiWidget

    widget:AddPointerDownListener(function(eventData)
        local ok, localPt = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(sliderRt, eventData.position, CS.XUiManager.Instance.UiCamera)
        if ok then
            self._SliderPressLocalX = localPt.x
        end
    end)

    widget:AddDragListener(function(eventData)
        local ok, localPt = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(sliderRt, eventData.position, CS.XUiManager.Instance.UiCamera)
        if not ok or not self._SliderPressLocalX then return end
        local r = sliderRt.rect
        local v = (localPt.x - self._SliderPressLocalX) / (r.xMax - r.xMin)
        self:_OnSlide(math.max(0, math.min(1, v)))
    end)

    widget:AddPointerUpListener(function(eventData)
        self:_OnRelease()
    end)
end

function XUiPanelEnvelopeGuessingCharacterCard:_KillReverseOpenPackageAnimation()
    if self._ReverseOpenPackageSchedule then
        XScheduleManager.UnSchedule(self._ReverseOpenPackageSchedule)
        self._ReverseOpenPackageSchedule = nil
    end
end

function XUiPanelEnvelopeGuessingCharacterCard:_OnRelease()
    if self._ForceOpened then return end
    self:_KillReverseOpenPackageAnimation()
    self._ReverseOpenPackageSchedule = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.OpenPackage) then
            self:_KillReverseOpenPackageAnimation()
            return
        end
        self.OpenPackage.time = self.OpenPackage.time - CS.UnityEngine.Time.deltaTime

        if self.OpenPackage.time <= 0 then
            self.OpenPackage.time = 0
            self:_KillReverseOpenPackageAnimation()
        end

        self.OpenPackage:Evaluate()
    end, 0, 0)
end

function XUiPanelEnvelopeGuessingCharacterCard:_OnSlide(v)
    self:_KillReverseOpenPackageAnimation()

    if self._ForceOpened then return end
    if v >= self._MaxSlideProgress then
        self:ForceOpen()
    else
        self.OpenPackage.time = self.OpenPackage.duration * math.max(v, self._MinSlideProgress)
        self.OpenPackage:Evaluate()
    end
end

function XUiPanelEnvelopeGuessingCharacterCard:ForceOpen(isForceOpen)
    self:_KillReverseOpenPackageAnimation()

    self._ForceOpened = true

    if isForceOpen then
        self.OpenPackage:Play()
    else
        self.OpenPackage:Evaluate()
        self.OpenPackage:Resume()
    end

    self._OnOpenCard()
end

return XUiPanelEnvelopeGuessingCharacterCard
