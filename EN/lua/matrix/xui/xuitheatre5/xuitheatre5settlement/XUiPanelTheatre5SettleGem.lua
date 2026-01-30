--- 结算展示宝珠列表
---@class XUiPanelTheatre5SettleGem: XUiNode
---@field protected _Control XTheatre5Control
local XUiPanelTheatre5SettleGem = XClass(XUiNode, 'XUiPanelTheatre5SettleGem')
local XUiGridTheatre5Container = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Container')
local XUiGridTheatre5SettleGem = require('XUi/XUiTheatre5/XUiTheatre5RoundSettlement/XUiGridTheatre5SettleGem')

function XUiPanelTheatre5SettleGem:OnStart(customContainerCls)
    self:InitGemContainers(customContainerCls)
    self._StartRun = true
end

function XUiPanelTheatre5SettleGem:OnEnable()
    if self._StartRun then
        self._StartRun = false
        return
    end
    
    self:RefreshShow()
end

function XUiPanelTheatre5SettleGem:InitGemContainers(customContainerCls)
    ---@type XUiGridTheatre5ShopGemSlot[]
    self.GridContainers = {}

    local gemList = self._Control:GetCurSelfGemIdList(true)
    self.UiTheatre5GridGem.gameObject:SetActiveEx(false)
    
    for i = 1, #gemList do
        local go = CS.UnityEngine.GameObject.Instantiate(self.UiTheatre5GridGem, self.UiTheatre5GridGem.transform.parent)
        
        ---@type XUiGridTheatre5ShopGemSlot
        local grid = customContainerCls and customContainerCls.New(go, self) or XUiGridTheatre5Container.New(go, self)
        grid:Open()
        grid:SetContainerType(XMVCA.XTheatre5.EnumConst.ItemContainerType.EquipBlock)
        grid:SetContainerIndex(i)

        if not grid:GetIsInitBindItems() then
            grid:InitBindItem(XUiGridTheatre5SettleGem)
        end
        
        --grid:SetItemShowById(gemIdList[i])
        grid:SetItemData(gemList[i])
        
        self.GridContainers[i] = grid
    end
end

function XUiPanelTheatre5SettleGem:RefreshShow()
    local gemList = self._Control:GetCurSelfGemIdList(true)

    for i = 1, #gemList do
        local grid = self.GridContainers[i]

        if grid then
            --grid:SetItemShowById(gemIdList[i])
            grid:SetItemData(gemList[i])
        end
    end
end

return XUiPanelTheatre5SettleGem