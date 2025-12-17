---@class XUiTheatre5PopupNewSeason : XLuaUi
---@field _Control XTheatre5Control
local XUiTheatre5PopupNewSeason = XLuaUiManager.Register(XLuaUi, "UiTheatre5PopupNewSeason")

function XUiTheatre5PopupNewSeason:OnAwake()
    self:BindExitBtns(self.BtnBack)
end

function XUiTheatre5PopupNewSeason:OnEnable()
    self:Update()
end

function XUiTheatre5PopupNewSeason:Update()
    self.TxtSeasonTime.text = self._Control:GetActivityTime()
    self.TxtName.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpTitle", 1)
    self.TxtSeasonNum.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpTitle", 2)
    self.TxtName1.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent1", 1)
    self.TxtTips1.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent1", 2)
    self.TxtName2.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent2", 1)
    self.TxtTips2.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent2", 2)
    self.TxtName3.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent3", 1)
    self.TxtTips3.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent3", 2)
    self.ImgNameplate:SetSprite(XMVCA.XTheatre5:GetClientConfig("PvpPopUpImgNameplate", 1))
    self.RImgRune:SetRawImage(XMVCA.XTheatre5:GetClientConfig("PvpPopUpImgRune", 1))
end

return XUiTheatre5PopupNewSeason