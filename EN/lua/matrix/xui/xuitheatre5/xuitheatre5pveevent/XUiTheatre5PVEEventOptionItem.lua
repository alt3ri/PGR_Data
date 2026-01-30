--- 章节主界面事件节点item
---@class XUiTheatre5PVEEventOptionItem: XUiNode
---@field protected _Control XTheatre5Control
local XUiTheatre5PVEEventOptionItem = XClass(XUiNode, 'XUiTheatre5PVEEventOptionItem')

function XUiTheatre5PVEEventOptionItem:OnStart()
    self._OptionData = nil
    self._IsSelect = false
    self._Unlock = nil
    self._LockDesc = nil
    XUiHelper.RegisterClickEvent(self, self.BtnOption, self.OnClickOption, true, true)
end

-- optionData = {EventId = number,EventOptionId = number}
function XUiTheatre5PVEEventOptionItem:Update(optionData, index)
    self._OptionData = optionData
    local optionCfg = self._Control.PVEControl:GetPveEventOptionCfg(optionData.EventOptionId)
    self._Unlock,self._LockDesc = XConditionManager.CheckConditionAndDefaultPass(optionCfg.OptionCondition)
    self.BtnOption:SetName(optionCfg.OptionDesc)  
    self.PanelItem.gameObject:SetActiveEx(optionCfg.OptionType ~= XMVCA.XTheatre5.EnumConst.PVEOptionType.NormalChat)
    if optionCfg.OptionType ~= XMVCA.XTheatre5.EnumConst.PVEOptionType.NormalChat then
      self:UpdateItem(optionCfg)
    end
    self.BtnOption:SetDisable(not self._Unlock)
    self._IsSelect = false
     self.BtnOption.enabled = true    
end

function XUiTheatre5PVEEventOptionItem:UpdateItem(optionCfg)
    local eventOptionIncomplete = self._Control.PVEControl:GetEventOptionIncomplete()
    if optionCfg.OptionType == XMVCA.XTheatre5.EnumConst.PVEOptionType.CostItem then
        if optionCfg.OptionCostType == XMVCA.XTheatre5.EnumConst.ItemType.Gold then  --花费的只能配金币
            local currencyCfg = self._Control:GetRouge5CurrencyCfg(optionCfg.OptionCostId)
            self.IconItem:SetRawImage(currencyCfg.IconRes)
            self.TextItemCount.text = optionCfg.OptionCostCount 
            local ownGoldCount = self._Control:GetGoldNum()
            if self._Unlock then
                self._Unlock = ownGoldCount >= optionCfg.OptionCostCount
                if not self._Unlock then
                    self._LockDesc = XUiHelper.FormatText(eventOptionIncomplete, currencyCfg.Name)
                end    
            end    
        end    
    elseif optionCfg.OptionType == XMVCA.XTheatre5.EnumConst.PVEOptionType.HasItem then
        if optionCfg.OptionCostType == XMVCA.XTheatre5.EnumConst.ItemType.Skill or
            optionCfg.OptionCostType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
            local itemCfg = self._Control:GetTheatre5ItemCfgById(optionCfg.OptionCostId)
            self.IconItem:SetRawImage(itemCfg.IconRes)
            self.TextItemCount.gameObject:SetActiveEx(false)
            if self._Unlock then
                self._Unlock = self._Control:CheckHasEquipOrSkill(optionCfg.OptionType, optionCfg.OptionCostId)
                if not self._Unlock then
                    self._LockDesc = XUiHelper.FormatText(eventOptionIncomplete, itemCfg.Name)
                end    
            end    
        elseif optionCfg.OptionCostType == XMVCA.XTheatre5.EnumConst.ItemType.Clue then
             local clueCfg = self._Control.PVEControl:GetDeduceClueCfg(optionCfg.OptionCostId)
             self.IconItem:SetRawImage(clueCfg.Img)
             self.TextItemCount.gameObject:SetActiveEx(false)
             if self._Unlock then
                self._Unlock = self._Control.PVEControl:CheckHasClue(optionCfg.OptionCostId)
                if not self._Unlock then
                    self._LockDesc = XUiHelper.FormatText(eventOptionIncomplete, clueCfg.Title)
                end    
             end   
        end
    end                 
end

function XUiTheatre5PVEEventOptionItem:SetSelect(eventOptionId)
    if not self._Unlock then
        return
    end
    self._IsSelect = self._OptionData.EventOptionId == eventOptionId 
    self.BtnOption.enabled = not self._IsSelect  
    self.BtnOption:SetButtonState(self._IsSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiTheatre5PVEEventOptionItem:OnClickOption()
    if not self._Unlock then
        XUiManager.TipMsg(self._LockDesc) 
        return
    end
    if self._IsSelect then
        return
    end        
    if self.Parent then
        self.Parent:UpdateSelectOption(self._OptionData.EventOptionId)
    end            
end

function XUiTheatre5PVEEventOptionItem:OnDestroy()
    self._OptionData = nil
    self._IsSelect = nil
    self._Unlock = nil
    self._LockDesc = nil
end

return XUiTheatre5PVEEventOptionItem