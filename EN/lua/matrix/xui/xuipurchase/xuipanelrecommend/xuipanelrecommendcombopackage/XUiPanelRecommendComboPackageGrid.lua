---@class XUiPanelRecommendComboPackageGrid
local XUiPanelRecommendComboPackageGrid = XClass(nil, "XUiPanelRecommendComboPackageGrid")

function XUiPanelRecommendComboPackageGrid:Ctor(ui, rootUi, buyFinished, notEnoughCb)
    XUiHelper.InitUiClass(self, ui)
    
    self.Btn = ui
    self.Btn:AddEventListener(handler(self, self.OnOpenBuyTips))

    self.BuyFinished = buyFinished
    self.NotEnoughCb = notEnoughCb
end

---@param data XPurchaseComboData
function XUiPanelRecommendComboPackageGrid:Update(data)
    -- 当前价格
    self.Btn:SetNameByGroup(0, data.Price)
    
    if data.Discount and data.Discount > 0 then
        for i = 1, 10 do
            local ui = self['PanelDiscount' .. i]

            if ui then
                ui.gameObject:SetActiveEx(true)
            else
                break
            end
        end

        self.Btn:SetNameByGroup(1, data.OriginalPrice)
        self.Btn:SetNameByGroup(2, XUiHelper.GetDiscountTextV2(data.Discount))
    else
        for i = 1, 10 do
            local ui = self['PanelDiscount' .. i]

            if ui then
                ui.gameObject:SetActiveEx(false)
            else
                break
            end
        end
    end

    -- 商品图片
    local iconPath = XPurchaseConfigs.GetIconPathByIconName(data.Icon)
    if iconPath and iconPath.AssetPath then
        self.Btn:SetRawImageWithNative(iconPath.AssetPath)
    end
    
    -- 货币图标
    local path = XDataCenter.ItemManager.GetItemIcon(data.ConsumeId)
    if path then
        for i = 1, 10 do
            local ui = self['RImgIcon' .. i]

            if ui then
                ui:SetRawImage(path)
            else
                break
            end
        end
    end

    if self.Btn then
        self.Btn:SetButtonState(data.IsSoldOut and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    end
    
    self._Data = data
end

--todo
function XUiPanelRecommendComboPackageGrid:OnOpenBuyTips()
    -- 特殊处理，通过checkFunc字段传递进去
    if not XTool.IsTableEmpty(self._Data.SubDatas) then
        XLuaUiManager.Open("UiPurchaseBuyTips", self._Data, self.NotEnoughCb, self.BuyFinished)
    else
        XLuaUiManager.Open("UiPurchaseBuyTips", self._Data, self.NotEnoughCb, self.BuyFinished)
    end
end

return XUiPanelRecommendComboPackageGrid