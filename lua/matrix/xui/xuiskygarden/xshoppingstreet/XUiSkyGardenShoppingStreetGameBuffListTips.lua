---@class XUiSkyGardenShoppingStreetGameBuffListTips : XLuaUi
local XUiSkyGardenShoppingStreetGameBuffListTips = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenShoppingStreetGameBuffListTips")
local XUiSkyGardenShoppingStreetBuffDetailGrid = require("XUi/XUiSkyGarden/XShoppingStreet/Grid/XUiSkyGardenShoppingStreetBuffDetailGrid")

function XUiSkyGardenShoppingStreetGameBuffListTips:OnStart(...)
    self:_RegisterButtonClicks()

    if self.ScrollView then
        self.DetailRt = self.ScrollView.gameObject:GetComponent(typeof(CS.UnityEngine.RectTransform))
        self.DefaultRtSizeY = self.DetailRt.sizeDelta.y
    end
    
    if not self._BuffDetailsList then self._BuffDetailsList = {} end
    local buffs = self._Control:GetStageGameBuffs()
    XTool.UpdateDynamicItem(self._BuffDetailsList, buffs, self.GridBuffDetail, XUiSkyGardenShoppingStreetBuffDetailGrid, self)
    if self.ScrollView then
        local size = self.DetailRt.sizeDelta
        size.y = math.min(self.DefaultRtSizeY, #buffs * 160)
        self.DetailRt.sizeDelta = size
    end
end

function XUiSkyGardenShoppingStreetGameBuffListTips:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnClose:AddEventListener(handler(self, self.Close))
end

return XUiSkyGardenShoppingStreetGameBuffListTips

