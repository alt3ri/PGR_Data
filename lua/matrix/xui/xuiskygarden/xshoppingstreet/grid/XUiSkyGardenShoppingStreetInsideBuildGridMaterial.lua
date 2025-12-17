---@class XUiSkyGardenShoppingStreetInsideBuildGridMaterial : XUiNode
---@field RImgMaterial UnityEngine.UI.RawImage
---@field ImgIcon UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetInsideBuildGridMaterial = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildGridMaterial")

function XUiSkyGardenShoppingStreetInsideBuildGridMaterial:OnStart()
    self.BtnUp:AddEventListener(handler(self, self.OnBtnUpClick))
    self.BtnDown:AddEventListener(handler(self, self.OnBtnDownClick))
end

function XUiSkyGardenShoppingStreetInsideBuildGridMaterial:OnBtnUpClick()
    self.Parent:MoveOffset(self._Index, 1)
end

function XUiSkyGardenShoppingStreetInsideBuildGridMaterial:OnBtnDownClick()
    self.Parent:MoveOffset(self._Index, -1)
end

function XUiSkyGardenShoppingStreetInsideBuildGridMaterial:Update(dessertId, i, maxCount)
    self._Index = i
    local dessertCfg = self._Control:GetShopDessertGoodsConfigsByGoodId(dessertId)
    self.TxtTitle.text = dessertCfg.GoodsName
    self.RImgMaterial:SetRawImage(dessertCfg.GoodsIcon)
    self.BtnUp.gameObject:SetActiveEx(i ~= 4)
    self.BtnDown.gameObject:SetActiveEx(i ~= 1)
end

return XUiSkyGardenShoppingStreetInsideBuildGridMaterial
