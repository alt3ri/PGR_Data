--- 临时背包
---@class XUiPanelTheatre5TempBag: XUiNode
---@field private _Control XTheatre5Control
---@field Parent XUiTheatre5BattleShop
local XUiPanelTheatre5TempBag = XClass(XUiNode, 'XUiPanelTheatre5TempBag')
local XUiGridTheatre5ShopContainer = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5ShopContainer')

local TempBagLimit
function XUiPanelTheatre5TempBag:OnStart()
    if TempBagLimit == nil or XMain.IsEditorDebug then
        TempBagLimit = self._Control.ShopControl:GetTempBagSizeLimit()
    end
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_BAG_SHOW, self.RefreshBagShow, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE5_UPDATE_BAG, self.RefreshBagShow, self)
    self:UpdateTempBagContainers()

end

function XUiPanelTheatre5TempBag:OnEnable()
    self:RefreshBagShow()
end

function XUiPanelTheatre5TempBag:UpdateTempBagContainers()  
    self.GridContainers = {}
    if self.GridItem then
        XUiHelper.RefreshCustomizedList(self.Transform, self.GridItem, TempBagLimit, function(index, go)
            ---@type XUiGridTheatre5ShopContainer
            local grid = XUiGridTheatre5ShopContainer.New(go, self)
            grid:Open()
            grid:SetContainerType(XMVCA.XTheatre5.EnumConst.ItemContainerType.TempBagBlock)
            grid:SetContainerIndex(index)
            self.GridContainers[index] = grid
        end)
    end    
end

function XUiPanelTheatre5TempBag:RefreshBagShow()
      --临时背包自动去占位置
    local tempBagItemDic = self._Control.ShopControl:GetTempBagGrids()
    if XTool.IsTableEmpty(tempBagItemDic) then
        self:Close()
        return
    end
    self:Open()
    for i, v in ipairs(self.GridContainers) do
        v:SetItemData(self._Control.ShopControl:GetItemInTempBagByIndex(i))
    end
  
    for i = 1, TempBagLimit do
        local itemData = tempBagItemDic[i]
        local targetEquipped,targetIndex = self:GetSwitchSuccessInfo(itemData)
        if XTool.IsNumberValid(targetIndex) then
            self:SendAutoSwitch(itemData, i, targetEquipped, targetIndex)
            return
        end    
    end
end

---@return targetEquipped,targetIndex
function XUiPanelTheatre5TempBag:GetSwitchSuccessInfo(itemData)
    if not itemData then
        return
    end
    if itemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        local skillIndex = self._Control.ShopControl:GetEmptyBagSkillIndex()
        if XTool.IsNumberValid(skillIndex) then
            return true, skillIndex
        end
    elseif itemData.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip then
        local runeIndex = self._Control.ShopControl:GetEmptyBagRuneIndex()
        if XTool.IsNumberValid(runeIndex) then
            return true, runeIndex
        end
    end 
    local bagIndex = self._Control.ShopControl:GetEmptyBagIndex()
    if XTool.IsNumberValid(bagIndex) then
        return false, bagIndex
    end               
end

--临时物品自动换上
function XUiPanelTheatre5TempBag:SendAutoSwitch(itemData, srcIndex, targetEquipped, targetIndex)
    -- 重复自动装备，会带来报错
    if self._IsLockRequest then
        return
    end
    self._IsLockRequest = true
    self._Control.ShopControl:SendItemSwitch(itemData.InstanceId, itemData.ItemType, false, srcIndex, true, targetEquipped, targetIndex,  function()
        self._IsLockRequest = false
    end)
end

function XUiPanelTheatre5TempBag:OnDestroy()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_BAG_SHOW, self.RefreshBagShow, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE5_UPDATE_BAG, self.RefreshBagShow, self)
end

return XUiPanelTheatre5TempBag