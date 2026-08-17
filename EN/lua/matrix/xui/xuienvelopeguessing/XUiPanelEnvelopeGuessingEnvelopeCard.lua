---@class XUiPanelEnvelopeGuessingEnvelopeCard : XUiNode
---@field private _Control XEnvelopeGuessingControl
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
    if not envelope then
        return
    end
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

-- 陀螺仪历史最大倾斜角度（度）
function XUiPanelEnvelopeGuessingEnvelopeCard:GetMaxTiltAngle()
    if XTool.UObjIsNil(self.ParallaxController) then
        return 0
    end
    return self.ParallaxController.MaxTiltAngle or 0
end

return XUiPanelEnvelopeGuessingEnvelopeCard
