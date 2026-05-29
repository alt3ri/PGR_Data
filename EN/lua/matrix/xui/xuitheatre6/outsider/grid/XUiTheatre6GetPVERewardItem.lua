--- 获得奖励界面rouge6物品的item
---@class XUiTheatre6GetPVERewardItem: XUiNode
---@field protected _Control XTheatre6Control
local XUiTheatre6GetPVERewardItem = XClass(XUiNode, 'XUiTheatre6GetPVERewardItem')

function XUiTheatre6GetPVERewardItem:OnStart()
    self._ItemData = nil
    ---@type XTheatre6Item
    self._Theatre6Item = nil --组拼的结构，给技能、宝珠详情显示的
    self.BtnGridTheatre6Item:AddEventListener(handler(self, self.OnClickItem))
end

---@param itemData { Id:number, Type:number, Count:number, IsFirst:bool }
function XUiTheatre6GetPVERewardItem:Update(itemData, index)
    self._ItemData = itemData
    self._Theatre6Item = {ItemId = itemData.Id, ItemType = itemData.Type}
    self.UiTheatre6GridGem.gameObject:SetActiveEx(itemData.Type == XMVCA.XTheatre6.EnumConst.ItemType.Equip)
    self.UiTheatre6GridSkill.gameObject:SetActiveEx(itemData.Type == XMVCA.XTheatre6.EnumConst.ItemType.Skill)
    self.GridGold.gameObject:SetActiveEx(itemData.Type == XMVCA.XTheatre6.EnumConst.ItemType.Gold)
    self.GridBox.gameObject:SetActiveEx(itemData.Type == XMVCA.XTheatre6.EnumConst.ItemType.ItemBox)
    if itemData.Type == XMVCA.XTheatre6.EnumConst.ItemType.Equip then --宝珠
        self:UpdateGem(itemData)
    elseif itemData.Type == XMVCA.XTheatre6.EnumConst.ItemType.Skill then
        self:UpdateSkill(itemData)
    elseif itemData.Type == XMVCA.XTheatre6.EnumConst.ItemType.Gold then
        self:UpdateGold(itemData)
    elseif itemData.Type == XMVCA.XTheatre6.EnumConst.ItemType.ItemBox then
        self:UpdateItemBox(itemData)
    end 
    --todo 设置IsFirst是否是首通标签
                
end

function XUiTheatre6GetPVERewardItem:UpdateGem(itemData)
    local GemIconPanel = XTool.InitUiObjectByUi({}, self.UiTheatre6GridGem)
    local itemCfg = self._Control:GetTheatre6ItemCfgById(itemData.Id)
    GemIconPanel.RImgIcon:SetRawImage(itemCfg.IconRes)
    local color = self._Control:GetClientConfigGemQualityColor(itemCfg.Quality)
    if color then
        GemIconPanel.RawImgBgQuality.color = color
    end
end

function XUiTheatre6GetPVERewardItem:UpdateSkill(itemData)
    local itemCfg = self._Control:GetTheatre6ItemCfgById(itemData.Id)
    self.RImgIconSkill:SetRawImage(itemCfg.IconRes)
end

function XUiTheatre6GetPVERewardItem:UpdateGold(itemData)
    local currencyCfg = self._Control:GetRouge6CurrencyCfg(itemData.Id)
    self.ImgGoldBg:SetImage(currencyCfg.IconRes)
    --self.TxtNameGold.text = currencyCfg.Name
    self.TxtGoldCount.text = itemData.Count
end

function XUiTheatre6GetPVERewardItem:UpdateItemBox(itemData)
    local itemCfg = self._Control:GetTheatre6ItemCfgById(itemData.Id)
    self.RawImgBoxBg:SetImage(itemCfg.IconRes)
    --self.TxtBoxName.text = itemCfg.Name
    self.TxtBoxCount.text = string.format("x%s", itemData.Count)
    --self.TxtBoxCount.gameObject:SetActiveEx(false)
end

function XUiTheatre6GetPVERewardItem:OnClickItem()
    if self._Theatre6Item.ItemType == XMVCA.XTheatre6.EnumConst.ItemType.Equip 
        or self._Theatre6Item.ItemType == XMVCA.XTheatre6.EnumConst.ItemType.Skill then
        XLuaUiManager.Open('UiTheatre6BubbleItemDetail', self._Theatre6Item, XMVCA.XTheatre6.EnumConst.ItemContainerType.NormalDetails, self.Transform)
    else
        XLuaUiManager.Open("UiTheatre6PopupRewardDetail",self._Theatre6Item.ItemId,self._Theatre6Item.ItemType)
    end                 
end

function XUiTheatre6GetPVERewardItem:OnDestroy()
    self._ItemData = nil
    self._Theatre6Item = nil
end

return XUiTheatre6GetPVERewardItem