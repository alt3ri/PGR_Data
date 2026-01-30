--- 背包列表
---@class XUiPanelTheatre5Bag: XUiNode
---@field private _Control XTheatre5Control
---@field Parent XUiTheatre5BattleShop
local XUiPanelTheatre5Bag = XClass(XUiNode, 'XUiPanelTheatre5Bag')
local XUiGridTheatre5ShopContainer = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5ShopContainer')

local BagLimit = nil

function XUiPanelTheatre5Bag:OnStart(containerType)
    if BagLimit == nil or XMain.IsEditorDebug then
        BagLimit = self._Control.ShopControl:GetBagSizeLimit()
    end
    
    self._ContainerType = containerType
    self:InitBagContainers()
    self:RefreshBagShow()
end

function XUiPanelTheatre5Bag:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_BAG_SHOW, self.RefreshBagShow, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE5_UPDATE_BAG, self.RefreshBagShow, self)
end

function XUiPanelTheatre5Bag:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_BAG_SHOW, self.RefreshBagShow, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE5_UPDATE_BAG, self.RefreshBagShow, self)
end

function XUiPanelTheatre5Bag:InitBagContainers()
    ---@type XUiGridTheatre5ShopContainer[]
    self.GridContainers = {}
    
    XUiHelper.RefreshCustomizedList(self.Transform, self.GridItem, BagLimit, function(index, go)
        ---@type XUiGridTheatre5ShopContainer
        local grid = XUiGridTheatre5ShopContainer.New(go, self)
        grid:Open()
        grid:SetContainerType(XMVCA.XTheatre5.EnumConst.ItemContainerType.BagBlock)
        grid:SetContainerIndex(index)
        
        self.GridContainers[index] = grid
    end)
end

function XUiPanelTheatre5Bag:NotAllowDrag()
    for i, gridContainer in ipairs(self.GridContainers) do
       if gridContainer.CurUiGrid and gridContainer.CurUiGrid.UiDragCom then
            gridContainer.CurUiGrid.UiDragCom.enabled = false
       end 
    end
end

function XUiPanelTheatre5Bag:RefreshBagShow()
    for i, v in ipairs(self.GridContainers) do
        v:SetItemData(self._Control.ShopControl:GetItemInBagByIndex(i))
        if self._ContainerType then
            v:SetContainerType(self._ContainerType)
        end
    end
end

return XUiPanelTheatre5Bag