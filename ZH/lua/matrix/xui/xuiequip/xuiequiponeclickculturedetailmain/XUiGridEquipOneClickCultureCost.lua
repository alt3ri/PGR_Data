local COLOR_HEX = {
    Black = "000000",
    Red = "FF0000",
}
local TEXT_COLOR = {
    Black = XUiHelper.Hexcolor2Color(COLOR_HEX.Black),
    Red = XUiHelper.Hexcolor2Color(COLOR_HEX.Red),
}

---@class XUiGridEquipOneClickCultureCost:XUiNode
---@field Parent XUiPanelEquipOneClickCultureModule
local XUiGridEquipOneClickCultureCost = XClass(XUiNode, "XUiGridEquipOneClickCultureCost")

function XUiGridEquipOneClickCultureCost:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnBtnClick)
end

function XUiGridEquipOneClickCultureCost:Update(data)
    self.Data = data
    self.ItemId = data.ItemId

    local icon, quality = data.Icon, data.Quality
    -- 无自定义图标且带 ItemId 时，按道具配置取图标/品质（突破材料等标准道具）
    if not icon and not data.IsExp and XTool.IsNumberValid(data.ItemId) then
        local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(data.ItemId)
        icon = goodsShowParams and goodsShowParams.Icon
        quality = goodsShowParams and goodsShowParams.Quality or quality
    end
    -- 主界面显示"持有(含兑换补足)/需求"：升级项 HaveCount 为真实持有 + ExchangeCount 兑换补足；
    -- 共鸣/谐振项 HaveCount 已含兑换、无 ExchangeCount，+0 结果一致
    local haveCount = (data.HaveCount or 0) + (data.ExchangeCount or 0)
    self:RefreshCustom(icon, quality, data.NeedCount, haveCount, data.HaveText, data.NeedText)
end

function XUiGridEquipOneClickCultureCost:RefreshCustom(icon, quality, needCount, haveCount, haveText, needText)
    if icon then
        self.RImgIcon:SetRawImage(icon)
    end
    if not XTool.IsNumberValid(quality) then
        self.ImgQuality.gameObject:SetActiveEx(false)
    else
        self.ImgQuality.gameObject:SetActiveEx(true)
        XUiHelper.SetQualityIcon(self.Parent.Parent, self.ImgQuality, quality or 0)
    end
    self.TxtHaveCount.text = haveText or tostring(haveCount or 0)
    self.TxtNeedCount.text = needText or "/" .. tostring(needCount or 0)
    if self.Data and self.Data.IsExp then
        self.TxtHaveCount.color = TEXT_COLOR.Black
        return
    end
    local isEnough = (haveCount or 0) >= (needCount or 0)
    self.TxtHaveCount.color = isEnough and TEXT_COLOR.Black or TEXT_COLOR.Red
end

function XUiGridEquipOneClickCultureCost:OnBtnClick()
    local data = self.Data
    if data and data.OnClick then
        data.OnClick(data)
        return
    end
    -- 武器材料点击跳转强化跳过界面（武器获取途径）
    if data and data.IsWeaponMaterial then
        XLuaUiManager.Open("UiEquipStrengthenSkip", XMVCA.XEquip:GenerateEquipSkipData(self.ItemId))
        return
    end
    if self.ItemId then
        XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(self.ItemId))
    elseif data and data.ItemId then
        XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(data.ItemId))
    end
end

return XUiGridEquipOneClickCultureCost
