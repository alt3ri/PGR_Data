local XUiEnvelopeGuessingSubUi =
    require("XUi/XUiEnvelopeGuessing/XUiEnvelopeGuessingSubUi")

local XUiEnvelopeGuessingCollectionCharacterCard =
    require("XUi/XUiEnvelopeGuessing/XUiEnvelopeGuessingCollectionCharacterCard")

local XUiEnvelopeGuessingDetail =
    XLuaUiManager.Register(XUiEnvelopeGuessingSubUi, "UiEnvelopeGuessingDetail")

function XUiEnvelopeGuessingDetail:OnStart(characterConfig)
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self.BtnDisplayUI.CallBack = handler(self, self._ShowHideUi)
    self.BtnInvitation.CallBack = handler(self, self._OnBtnInvitationClicked)
    self.TxtName.text = characterConfig.CharacterName
    self._UiDisplaying = true

    self._Card = XUiEnvelopeGuessingCollectionCharacterCard.New(
        self.UiEnvelopeGuessingClueCard, self)

    self._CharacterConfig = characterConfig
end

function XUiEnvelopeGuessingDetail:OnEnable()
    self.Super.OnEnable(self)
    self._Card:SetData(self._CharacterConfig)

    self.PanelBubbleDetail.gameObject:SetActiveEx(
        self._UiDisplaying
        and not self._Control:IsCharacterStoryWatched(self._CharacterConfig.Id))
end

function XUiEnvelopeGuessingDetail:_ShowHideUi()
    self._UiDisplaying = not self._UiDisplaying

    if not self._ClickToHideThese then
        self._ClickToHideThese = {}
        XTool.InitUiObjectByInstance(self.ClickToHide, self._ClickToHideThese)
    end

    for _, ui in pairs(self._ClickToHideThese) do
        ui.gameObject:SetActiveEx(self._UiDisplaying)
    end

    self.PanelBubbleDetail.gameObject:SetActiveEx(
        self._UiDisplaying
        and not self._Control:IsCharacterStoryWatched(self._CharacterConfig.Id))
end

function XUiEnvelopeGuessingDetail:_OnBtnInvitationClicked()
    self.PanelBubbleDetail.gameObject:SetActiveEx(false)
    XMVCA.XEnvelopeGuessing:MarkCharacterStoryHasWatched(self._CharacterConfig.Id, function()
        XDataCenter.MovieManager.PlayMovie(self._CharacterConfig.StoryId)
    end)
end

return XUiEnvelopeGuessingDetail
