local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPanelEnvelopeGuessingInstrument = require("XUi/XUiEnvelopeGuessing/XUiPanelEnvelopeGuessingInstrument")
---@class XUiPanelEnvelopeGuessingMusicianChoose : XUiNode
---@field private _Control XEnvelopeGuessingControl
local XUiPanelEnvelopeGuessingMusicianChoose = XClass(XUiNode, "XUiPanelEnvelopeGuessingMusicianChoose")

function XUiPanelEnvelopeGuessingMusicianChoose:OnStart(refreshInstrument, closeChoosePanel)
    XTool.InitUiObjectByInstance(self.PanelDetail, self)
    self._RefreshInstrument = refreshInstrument
    self._CloseChoosePanel = closeChoosePanel
    self._DynTable = XDynamicTableNormal.New(self.ScrollView)
    self._DynTable:SetProxy(require("XUi/XUiEnvelopeGuessing/XUiGridEnvelopeGuessingMusicianChoose"), self)
    self._DynTable:SetDelegate(self)
end

function XUiPanelEnvelopeGuessingMusicianChoose:Reset(instrument)
    self._Instrument = instrument

    if self._OnSessionEndCallback then
        self._OnSessionEndCallback(true)
    end

    self._AllOpenedCharacterIds = XTool.Clone(self._Control:GetAllOpenedCharacters())

    table.sort(self._AllOpenedCharacterIds, function(a, b)
        local aPlaying = self._Control:GetInstrumentByBoundCharacterId(a)
        local bPlaying = self._Control:GetInstrumentByBoundCharacterId(b)

        if aPlaying and bPlaying then
            return a < b
        elseif aPlaying then
            return true
        elseif bPlaying then
            return false
        else
            return a < b
        end
    end)

    self._OnCharacterClickedHandler = handler(self, self._OnCharacterClicked)

    self._DynTable:Clear()
    self._DynTable:SetDataSource(self._AllOpenedCharacterIds)
    self._DynTable:ReloadDataASync()
end

---@param grid XUiGridEnvelopeGuessingMusicianChoose
function XUiPanelEnvelopeGuessingMusicianChoose:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(self._AllOpenedCharacterIds[index], self._Instrument, self._OnCharacterClickedHandler)
    end
end

function XUiPanelEnvelopeGuessingMusicianChoose:_OnCharacterClicked(instConfig, charId)
    self._CloseChoosePanel()
    if charId and self._Control:GetInstrumentBinding(self._Instrument.Id) == charId then
        self._Control:SetInstrumentBinding(instConfig.Id, nil, function()
            self:_OnInstrumentBindingFinished(instConfig, nil, nil, nil, charId)
        end)
    else
        self._Control:SetInstrumentBinding(instConfig.Id, charId, function(anotherInst, anotherChar)
            self:_OnInstrumentBindingFinished(instConfig, anotherInst, anotherChar, charId, nil)
        end)
    end
end

function XUiPanelEnvelopeGuessingMusicianChoose:_OnInstrumentBindingFinished(instConfig, anotherInstId, anotherCharId, charId, prevCharId)
    local msg
    local refreshType = XUiPanelEnvelopeGuessingInstrument.RefreshType.Normal

    if not charId then
        refreshType = XUiPanelEnvelopeGuessingInstrument.RefreshType.Exit
        msg = CS.XTextManager.GetText("EnvelopeGuessingChoosePanelUnbindingSuccess", self._Control:GetCharacterName(prevCharId))
    elseif anotherInstId and anotherCharId then
        msg = CS.XTextManager.GetText("EnvelopeGuessingChoosePanelSwapSuccess", self._Control:GetCharacterName(charId), self._Control:GetCharacterName(anotherCharId))
    elseif anotherInstId and not anotherCharId then
        msg = CS.XTextManager.GetText("EnvelopeGuessingChoosePanelMoveSuccess", self._Control:GetCharacterName(charId))
    else
        refreshType = XUiPanelEnvelopeGuessingInstrument.RefreshType.Enter
        msg = CS.XTextManager.GetText("EnvelopeGuessingChoosePanelBindingSuccess", self._Control:GetCharacterName(charId))
    end

    if anotherInstId then
        self._RefreshInstrument(anotherInstId)
    end
    self._RefreshInstrument(instConfig.Id, refreshType)
    XUiManager.TipMsg(msg)
end

return XUiPanelEnvelopeGuessingMusicianChoose
