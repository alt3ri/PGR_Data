---@class UiTheatre5PopupRewardDetail : XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5PopupRewardDetail = XLuaUiManager.Register(XLuaUi, "UiTheatre5PopupRewardDetail")

function XUiTheatre5PopupRewardDetail:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.Close, true)
    self:RegisterClickEvent(self.BtnTanchuangClose, self.Close, true)
    self:RegisterClickEvent(self.BtnOk, self.Close, true)
end
function XUiTheatre5PopupRewardDetail:OnStart(itemId, itemType)
    if itemType == XMVCA.XTheatre5.EnumConst.ItemType.ItemBox then
        self:RefreshItemBox(itemId)
    elseif itemType == XMVCA.XTheatre5.EnumConst.ItemType.Gold then
        self:RefreshGold(itemId)
    elseif itemType == XMVCA.XTheatre5.EnumConst.ItemType.Common then
        self:RefreshCommonItem(itemId)
    end    
end

function XUiTheatre5PopupRewardDetail:RefreshItemBox(itemId)
    local itemCfg = self._Control:GetTheatre5ItemCfgById(itemId)
    if not itemCfg then
        return
    end
    self:SetIcon(itemCfg.IconRes)
    self.TxtName.text = itemCfg.Name
    self.TxtDescription.text = self._Control:GetItemDesc(itemCfg)
    self.TxtWorldDesc.text = itemCfg.Info
    self.TxtCount.text = 0
end

function XUiTheatre5PopupRewardDetail:RefreshGold(itemId)
    local currencyCfg = self._Control:GetRouge5CurrencyCfg(itemId)
    if not currencyCfg then
        return
    end
    self:SetIcon(currencyCfg.IconRes)
    self.TxtName.text = currencyCfg.Name
    self.TxtDescription.text = currencyCfg.Desc
    self.TxtWorldDesc.text = currencyCfg.Info
    self.TxtCount.text = self._Control:GetGoldNum()
end

function XUiTheatre5PopupRewardDetail:RefreshCommonItem(templateId)
    local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)
    self:SetIcon(goodsShowParams.Icon)
    local desc = XGoodsCommonManager.GetGoodsDescription(templateId)
    self.TxtDescription.text = desc
    local worldDesc = XGoodsCommonManager.GetGoodsWorldDesc(templateId)
    self.TxtWorldDesc.text = worldDesc
    self.TxtName.text = goodsShowParams.Name
    self.TxtCount.text = XGoodsCommonManager.GetGoodsCurrentCount(templateId)


    -- local itemData = XDataCenter.ItemManager.GetItem(itemId)
    -- if not itemData then
    --     return
    -- end    
    -- local icon = XDataCenter.ItemManager.GetItemIcon(itemId)
    -- self.RImgIcon:SetRawImage(icon)
    -- self.TxtDescription.text = XDataCenter.ItemManager.GetItemDescription(itemId)
    -- self.TxtWorldDesc.text = XDataCenter.ItemManager.GetItemWorldDesc(itemId)
    -- self.TxtName.text = XDataCenter.ItemManager.GetItemName(itemId)
    -- self.TxtCount.text = itemData.Count
end

function XUiTheatre5PopupRewardDetail:SetIcon(iconRes)
    -- 因为有部份资源, 是和铭牌系统共用的, 但是那边是使用图集的, 所以只能肉鸽这边支持两种图片的配置了
    if string.find(iconRes, "Atlas") then
        self.ImgIcon.gameObject:SetActiveEx(true)
        self.RImgIcon.gameObject:SetActiveEx(false)
        self.ImgIcon:SetSprite(iconRes)
    else
        self.ImgIcon.gameObject:SetActiveEx(false)
        self.RImgIcon.gameObject:SetActiveEx(true)
        self.RImgIcon:SetRawImage(iconRes)
    end
end

return XUiTheatre5PopupRewardDetail
