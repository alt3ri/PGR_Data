---@class XUiGridGoldenMinerHex: XUiNode
---@field StateCtrl XUiComponent.XUiStateControl
---@field _Control XGoldenMinerControl
---@field Parent XUiGoldenMinerHexSelect
local XUiGridGoldenMinerHex = XClass(XUiNode, 'XUiGridGoldenMinerHex')

local StateEnum = {
    [1] = 'Hex',
    [2] = 'Update',
    [3] = 'Common',
}

function XUiGridGoldenMinerHex:OnStart()
    -- 额外的点击事件用于处理XUiButton禁用后的弹窗提示
    self.Parent:RegisterClickEvent(self.GridBtn, function()
        if self.IsHave then
            XUiManager.TipMsg(self._Control:GetClientHexSelectAgainTips(self.ItemType))
        end
    end)
end

function XUiGridGoldenMinerHex:GetButton()
    return self.GridBtn
end

function XUiGridGoldenMinerHex:RefreshShow(showType, itemType, id)
    self.StateCtrl:ChangeState(StateEnum[showType])

    self.TxtName.text = self._Control:GetClientHexSelectItemShowName(showType)
    self.ItemType = itemType
    
    if itemType == XMVCA.XGoldenMiner.EnumConst.ItemTypeInShop.Hex then
        self:RefreshHexShow(id)
    elseif itemType == XMVCA.XGoldenMiner.EnumConst.ItemTypeInShop.Update then
        self:RefreshUpgradeShow(id)
    end
    
end

function XUiGridGoldenMinerHex:RefreshHexShow(hexId)
    self.GridBtn:SetNameByGroup(0, self._Control:GetCfgHexName(hexId))
    self.GridBtn:SetNameByGroup(1, XUiHelper.ConvertLineBreakSymbol(self._Control:GetCfgHexDesc(hexId)))
    self.GridBtn:SetRawImage(self._Control:GetCfgHexIcon(hexId))
    
    -- 判断是否拥有该海克斯
    self.IsHave = self._Control:GetMainDb():CheckHaveHex(hexId)
    
    self.GridBtn:SetButtonState(self.IsHave and CS.UiButtonState.Disable or CS.UiButtonState.Normal)

    if self.IsHave then
        self.TxtName.text = self._Control:GetClientHexSelectedTips(XMVCA.XGoldenMiner.EnumConst.ItemTypeInShop.Hex)
    end
end

function XUiGridGoldenMinerHex:RefreshUpgradeShow(upgradeId)
    self.GridBtn:SetNameByGroup(0, self._Control:GetCfgHexUpgradeName(upgradeId))
    self.GridBtn:SetNameByGroup(1, XUiHelper.ConvertLineBreakSymbol(self._Control:GetCfgHexUpgradeDesc(upgradeId)))
    self.GridBtn:SetRawImage(self._Control:GetCfgHexUpgradeIcon(upgradeId))

    -- 判断是否拥有该升级方案
    self.IsHave = self._Control:GetMainDb():CheckHasUpgrade(upgradeId)

    self.GridBtn:SetButtonState(self.IsHave and CS.UiButtonState.Disable or CS.UiButtonState.Normal)

    if self.IsHave then
        self.TxtName.text = self._Control:GetClientHexSelectedTips(XMVCA.XGoldenMiner.EnumConst.ItemTypeInShop.Update)
    end
end

function XUiGridGoldenMinerHex:GetIsHave()
    return self.IsHave or false
end

return XUiGridGoldenMinerHex