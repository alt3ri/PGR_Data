---@class XUiPanelEnvelopeGuessingEnvelopeCard : XUiNode
---@field ParallaxController XUiParallaxController
local XUiPanelEnvelopeGuessingEnvelopeCard = XClass(XUiNode, "XUiPanelEnvelopeGuessingEnvelopeCard")

function XUiPanelEnvelopeGuessingEnvelopeCard:OnStart()
    local card = {}
    XTool.InitUiObjectByInstance(self.UiEnvelopeGuessingClueCard, card)
    self.RImgCardBg = card.RImgCardBg
    self.RImgCardBg.gameObject:SetActiveEx(true)
    self.RImgCardPackage = card.RImgCardPackage
    self.TxtCardTip = card.TxtCardTip
end

function XUiPanelEnvelopeGuessingEnvelopeCard:SetData(envelope)
    assert(envelope)
    self._EnvelopeConf = envelope
    self._CharacterConf = self._Control:GetCharacterConfig(envelope.CharacterId)
    self.RImgCardBg:SetRawImage(self._CharacterConf.CgAssetPathLocked)
    self.TxtCardTip.text = string.gsub(self._CharacterConf.Desc, "\\n", "\n")
end

function XUiPanelEnvelopeGuessingEnvelopeCard:GetData()
    return self._EnvelopeConf, self._CharacterConf
end

-- 开启/关闭该卡片的视差(陀螺仪)效果
function XUiPanelEnvelopeGuessingEnvelopeCard:SetParallaxEnabled(enable)
    if self.ParallaxController then
        self.ParallaxController:SetParallaxEnabled(enable)
    end
end

return XUiPanelEnvelopeGuessingEnvelopeCard
