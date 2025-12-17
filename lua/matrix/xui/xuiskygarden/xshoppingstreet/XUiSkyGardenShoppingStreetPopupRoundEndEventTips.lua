---@class XUiSkyGardenShoppingStreetPopupRoundEndEventTips : XLuaUi
local XUiSkyGardenShoppingStreetPopupRoundEndEventTips = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetPopupRoundEndEventTips")

--region 生命周期
function XUiSkyGardenShoppingStreetPopupRoundEndEventTips:OnStart(text, pos)
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.TxtDetail.text = text
    self.Pointer.transform.position = pos
end
--endregion

return XUiSkyGardenShoppingStreetPopupRoundEndEventTips
