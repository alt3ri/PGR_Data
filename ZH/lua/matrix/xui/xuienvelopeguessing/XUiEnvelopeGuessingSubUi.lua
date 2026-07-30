local XUiEnvelopeGuessingSubUi = XClass(XLuaUi, "XUiEnvelopeGuessingSubUi")

function XUiEnvelopeGuessingSubUi:OnEnable()
    if self.__ActivityId
    and self.__ActivityId ~= XMVCA.XEnvelopeGuessing:GetCurrentActivity().Id then
        self:Close()
        return
    end

    XMVCA.XEnvelopeGuessing:AddEventListener(
        XMVCA.XEnvelopeGuessing.EventIds.EVENT_ON_NOTIFY_ENVELOPE,
        self.Close,
        self)
end

function XUiEnvelopeGuessingSubUi:OnDisable()
    XMVCA.XEnvelopeGuessing:RemoveEventListener(
        XMVCA.XEnvelopeGuessing.EventIds.EVENT_ON_NOTIFY_ENVELOPE,
        self.Close,
        self)

    self.__ActivityId = XMVCA.XEnvelopeGuessing:GetCurrentActivity().Id
end

return XUiEnvelopeGuessingSubUi
