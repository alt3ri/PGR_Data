---@class XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods : XUiNode
---@field ImgAttribute UnityEngine.UI.Image
---@field TxtDetailNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods = XClass(XUiNode, "XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods")

function XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods:OnStart()
    self.GridSmallGoods:AddEventListener(function () self:OnGridSmallGoodsClick() end)
    self.BtnAdd:AddEventListener(function () self:OnBtnAddClick() end)
    self.BtnMinus:AddEventListener(function () self:OnBtnMinusClick() end)
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods:Update(goodId, index)
    self._GoodId = goodId or self._GoodId
    self._Index = index or self._Index
    
    local goodCfg = self._Control:GetShopGroceryGoodsConfigsByGoodId(self._GoodId)
    self.GridSmallGoods:SetName(goodCfg.GoodsName)
    -- self.TxtName.text = goodCfg.GoodsName
    -- self.RImgGoods:SetRawImage(goodCfg.GoodsIcon)
    self.GridSmallGoods:SetRawImage(goodCfg.GoodsIcon)

    local isSelect = self.Parent:IsSelectGoodId(self._GoodId)
    self:SetSelect(isSelect)

    self._Data = self.Parent:GetTempData(self._GoodId)

    if self._Data then
        -- self.TxtName.text = goodCfg.GoodsName
        self._MinNum = goodCfg.GoldMin
        self._MaxNum = goodCfg.GoldMax
        self._Data.num = XMath.Clamp(self._Data.num, self._MinNum, self._MaxNum)
        self.TxtNum.text = self._Data.num
    end
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods:SetSelect(isSelect)
    -- self.Select.gameObject:SetActive(isSelect)
    self.PanelPrice.gameObject:SetActive(isSelect)
    self.GridSmallGoods:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods:OnGridSmallGoodsClick()
    self.Parent:OnGridSmallGoodsClick(self._Index, self._GoodId)
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods:OnBtnAddClick()
    self._Data.num = XMath.Clamp(self._Data.num + 1, self._MinNum, self._MaxNum)
    self.TxtNum.text = self._Data.num
    if self.BtnAddEnable then
        self.BtnAddEnable:PlayTimelineAnimation()
    end
end

function XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods:OnBtnMinusClick()
    self._Data.num = XMath.Clamp(self._Data.num - 1, self._MinNum, self._MaxNum)
    self.TxtNum.text = self._Data.num
    if self.BtnMinusPressEnable then
        self.BtnMinusPressEnable:PlayTimelineAnimation()
    end
end

return XUiSkyGardenShoppingStreetInsideBuildGoodsGridSmallGoods
