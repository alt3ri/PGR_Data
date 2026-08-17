local XUiEnvelopeGuessingCollectionCharacterCard = require("XUi/XUiEnvelopeGuessing/XUiEnvelopeGuessingCollectionCharacterCard")
---@class XUiEnvelopeGuessingDetail : XLuaUi
---@field private _Control XEnvelopeGuessingControl
---@field private _Card XUiEnvelopeGuessingCollectionCharacterCard
local XUiEnvelopeGuessingDetail = XLuaUiManager.Register(XLuaUi, "UiEnvelopeGuessingDetail")

function XUiEnvelopeGuessingDetail:OnStart(characterConfig)
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self.BtnDisplayUI:AddEventListener(handler(self, self._ShowHideUi))
    self.BtnInvitation:AddEventListener(handler(self, self._OnBtnInvitationClicked))
    self.TxtName.text = characterConfig.CharacterName
    self._UiDisplaying = true

    self._Card = XUiEnvelopeGuessingCollectionCharacterCard.New(self.UiEnvelopeGuessingClueCard, self)

    self._CharacterConfig = characterConfig
    -- 设置自动关闭
    self:SetAutoCloseInfo(XMVCA.XEnvelopeGuessing:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
end

function XUiEnvelopeGuessingDetail:OnEnable()
    self._Card:SetData(self._CharacterConfig)
    self.PanelBubbleDetail.gameObject:SetActiveEx(self._UiDisplaying and not self._Control:IsCharacterStoryWatched(self._CharacterConfig.Id))
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

    self.PanelBubbleDetail.gameObject:SetActiveEx(self._UiDisplaying and not self._Control:IsCharacterStoryWatched(self._CharacterConfig.Id))
end

function XUiEnvelopeGuessingDetail:_OnBtnInvitationClicked()
    self.PanelBubbleDetail.gameObject:SetActiveEx(false)
    XMVCA.XEnvelopeGuessing:EnvelopeRecordAvgRequest(self._CharacterConfig.Id, function()
        XDataCenter.MovieManager.PlayMovie(self._CharacterConfig.StoryId)
    end)
end

return XUiEnvelopeGuessingDetail
