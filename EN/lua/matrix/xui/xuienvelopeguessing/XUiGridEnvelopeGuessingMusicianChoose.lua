---@class XUiGridEnvelopeGuessingMusicianChoose : XUiNode
---@field private _Control XEnvelopeGuessingControl
local XUiGridEnvelopeGuessingMusicianChoose = XClass(XUiNode, "XUiGridEnvelopeGuessingMusicianChoose")

function XUiGridEnvelopeGuessingMusicianChoose:OnStart()
    self.BtnSelf:AddEventListener(handler(self, self._OnClick))
end

function XUiGridEnvelopeGuessingMusicianChoose:SetData(characterId, instrument, onClick)
    self._InstrumentConfig = instrument
    self._CharacterId = characterId
    self._OnClickCallback = onClick

    local characterConf = self._Control:GetCharacterConfig(characterId)
    self.BtnSelf:SetRawImage(characterConf.HeadIcon)

    if self._Control:GetInstrumentBinding(instrument.Id) == characterId then
        self.BtnSelf:SetButtonState(CS.UiButtonState.Select)
    else
        self.BtnSelf:SetButtonState(CS.UiButtonState.Normal)
    end

    self.ImgTag.gameObject:SetActiveEx(not not self._Control:GetInstrumentByBoundCharacterId(self._CharacterId))
end

function XUiGridEnvelopeGuessingMusicianChoose:_OnClick()
    self._OnClickCallback(self._InstrumentConfig, self._CharacterId)
end

return XUiGridEnvelopeGuessingMusicianChoose
