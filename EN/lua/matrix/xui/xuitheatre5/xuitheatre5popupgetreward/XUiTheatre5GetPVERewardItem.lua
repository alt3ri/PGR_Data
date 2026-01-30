--- 获得奖励界面rouge5物品的item
---@class XUiTheatre5GetPVERewardItem: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5GetPVERewardItem = XClass(XUiNode, 'XUiTheatre5GetPVERewardItem')

function XUiTheatre5GetPVERewardItem:OnStart()
    self._ItemData = nil
    ---@type XTheatre5Item
    self._Theatre5Item = nil --组拼的结构，给技能、宝珠详情显示的
    XUiHelper.RegisterClickEvent(self, self.BtnGridTheatre5Item, self.OnClickItem,true)
end

---@param itemData { Id:number, Type:number, Count:number, IsFirst:bool }
function XUiTheatre5GetPVERewardItem:Update(itemData, index)
    self._ItemData = itemData
    self._Theatre5Item = {ItemId = itemData.Id, ItemType = itemData.Type}
    self.UiTheatre5GridGem.gameObject:SetActiveEx(itemData.Type == XMVCA.XTheatre5.EnumConst.ItemType.Equip)
    self.UiTheatre5GridSkill.gameObject:SetActiveEx(itemData.Type == XMVCA.XTheatre5.EnumConst.ItemType.Skill)
    self.GridGold.gameObject:SetActiveEx(itemData.Type == XMVCA.XTheatre5.EnumConst.ItemType.Gold)
    self.GridBox.gameObject:SetActiveEx(itemData.Type == XMVCA.XTheatre5.EnumConst.ItemType.ItemBox)
    if itemData.Type == XMVCA.XTheatre5.EnumConst.ItemType.Equip then --宝珠
        self:UpdateGem(itemData)
    elseif itemData.Type == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        self:UpdateSkill(itemData)
    elseif itemData.Type == XMVCA.XTheatre5.EnumConst.ItemType.Gold then
        self:UpdateGold(itemData)
    elseif itemData.Type == XMVCA.XTheatre5.EnumConst.ItemType.ItemBox then
        self:UpdateItemBox(itemData)
    end 
    --todo 设置IsFirst是否是首通标签
                
end

function XUiTheatre5GetPVERewardItem:UpdateGem(itemData)
    local GemIconPanel = XTool.InitUiObjectByUi({}, self.UiTheatre5GridGem)
    local itemCfg = self._Control:GetTheatre5ItemCfgById(itemData.Id)
    GemIconPanel.RImgIcon:SetRawImage(itemCfg.IconRes)
    local color = self._Control:GetClientConfigGemQualityColor(itemCfg.Quality)
    if color then
        GemIconPanel.RawImgBgQuality.color = color
    end
end

function XUiTheatre5GetPVERewardItem:UpdateSkill(itemData)
    local itemCfg = self._Control:GetTheatre5ItemCfgById(itemData.Id)
    self.RImgIconSkill:SetRawImage(itemCfg.IconRes)
end

function XUiTheatre5GetPVERewardItem:UpdateGold(itemData)
    local currencyCfg = self._Control:GetRouge5CurrencyCfg(itemData.Id)
    self.ImgGoldBg:SetImage(currencyCfg.IconRes)
    --self.TxtNameGold.text = currencyCfg.Name
    self.TxtGoldCount.text = itemData.Count
end

function XUiTheatre5GetPVERewardItem:UpdateItemBox(itemData)
    local itemCfg = self._Control:GetTheatre5ItemCfgById(itemData.Id)
    self.RawImgBoxBg:SetImage(itemCfg.IconRes)
    --self.TxtBoxName.text = itemCfg.Name
    self.TxtBoxCount.text = string.format("x%s", itemData.Count)
    --self.TxtBoxCount.gameObject:SetActiveEx(false)
end

function XUiTheatre5GetPVERewardItem:OnClickItem()
    if self._Theatre5Item.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip 
        or self._Theatre5Item.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        XLuaUiManager.Open('UiTheatre5BubbleItemDetail', self._Theatre5Item, XMVCA.XTheatre5.EnumConst.ItemContainerType.NormalDetails, self.Transform)
    else
        XLuaUiManager.Open("UiTheatre5PopupRewardDetail",self._Theatre5Item.ItemId,self._Theatre5Item.ItemType)
    end                 
end

function XUiTheatre5GetPVERewardItem:OnDestroy()
    self._ItemData = nil
    self._Theatre5Item = nil
end

return XUiTheatre5GetPVERewardItem