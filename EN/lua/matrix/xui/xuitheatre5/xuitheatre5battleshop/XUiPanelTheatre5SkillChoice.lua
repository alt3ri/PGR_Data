--- 技能三选一界面
---@class XUiPanelTheatre5SkillChoice: XUiNode
---@field private _Control XTheatre5Control
---@field Parent XUiTheatre5BattleShop
local XUiPanelTheatre5SkillChoice = XClass(XUiNode, 'XUiPanelTheatre5SkillChoice')
local XUiGridTheatre5ShopSkillSlot = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5ShopSkillSlot')

function XUiPanelTheatre5SkillChoice:OnStart()
    self.BtnShopMaskDetailShow:AddEventListener(handler(self, self.OnBtnMaskDetailShowClickEvent))

    self:InitStoreContainers()
    self:RefreshSkillChoiceShow()
    self:InitFullShopArea()
end

function XUiPanelTheatre5SkillChoice:OnEnable()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_STORE_SHOW, self.RefreshSkillChoiceShow, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FULLSHOPAREA_SHOW_STATE, self.SetFullAreaState, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SKILL_CHOICE_END, self.RefreshSkillSlotAfterSelect, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CANCEL_CONTAINERS_FOCUS, self.OnApplicationPauseEvent, self)
end

function XUiPanelTheatre5SkillChoice:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_STORE_SHOW, self.RefreshSkillChoiceShow, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FULLSHOPAREA_SHOW_STATE, self.SetFullAreaState, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_SKILL_CHOICE_END, self.RefreshSkillSlotAfterSelect, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CANCEL_CONTAINERS_FOCUS, self.OnApplicationPauseEvent, self)
end

function XUiPanelTheatre5SkillChoice:InitStoreContainers()
    ---@type XUiGridTheatre5ShopSkillSlot[]
    self.GridContainers = {}

    local shopGridTotalCount = self._Control.ShopControl:GetSkillChoiceListCount()

    XUiHelper.RefreshCustomizedList(self.ListSkill.transform, self.GridSkill, shopGridTotalCount, function(index, go)
        ---@type XUiGridTheatre5ShopSkillSlot
        local grid = XUiGridTheatre5ShopSkillSlot.New(go, self)
        grid:Open()
        grid:SetContainerType(XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillSelection)
        grid:SetContainerIndex(index)

        self.GridContainers[index] = grid
    end)
end

function XUiPanelTheatre5SkillChoice:RefreshSkillChoiceShow()
    local dataList = self._Control.ShopControl:GetSkillChoiceList()
    
    if not XTool.IsTableEmpty(dataList) and not XTool.IsTableEmpty(self.GridContainers) then
        for i, v in ipairs(self.GridContainers) do
            v:SetItemData(dataList[i])
        end
    end
end

function XUiPanelTheatre5SkillChoice:RefreshSkillSlotAfterSelect()
    if not XTool.IsTableEmpty(self.GridContainers) then
        for i, v in pairs(self.GridContainers) do
            v:RefreshShow()
        end
    end
end

function XUiPanelTheatre5SkillChoice:OnBtnMaskDetailShowClickEvent()
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
end

--region 卖出相关

function XUiPanelTheatre5SkillChoice:InitFullShopArea()
    ---@type XUguiEventListener
    self.UiFullShopAreaEventCom = self.FullShopAreaForSell.gameObject:AddComponent(typeof(CS.XUguiEventListener))
    self.UiFullShopAreaEventCom.OnEnter = handler(self, self.OnShopAreaPointerEnter)
    self.UiFullShopAreaEventCom.OnExit = handler(self, self.OnShopAreaPointerExit)
    self.UiFullShopAreaEventCom.OnDown = handler(self, self.OnShopAreaPointerDown)

    self.FullShopAreaForSell.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre5SkillChoice:OnShopAreaPointerEnter(eventData)
    if self._Control.ShopControl:GetIsDraggingItem() then
        self._Control.ShopControl:SetFocusContainer(XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillSelection, 0)
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ENTER_FULLSHOPAREA)

        local isFromShop = self._Control.ShopControl:GetDraggingItemOwnerContainerType() == XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillSelection
        if not isFromShop and self.RawImgLight then
            self.RawImgLight.gameObject:SetActiveEx(true)
        end
    end
end

function XUiPanelTheatre5SkillChoice:OnShopAreaPointerExit(eventData)
    self:_DoShopAreaExit()
end

function XUiPanelTheatre5SkillChoice:_DoShopAreaExit()
    self._Control.ShopControl:SetFocusContainer(nil, nil)
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_EXIT_FULLSHOPAREA)
    if self.RawImgLight then
        self.RawImgLight.gameObject:SetActiveEx(false)
    end
end

function XUiPanelTheatre5SkillChoice:OnApplicationPauseEvent()
    if self._Control.ShopControl:CheckIsSameContainer(XMVCA.XTheatre5.EnumConst.ItemContainerType.SkillSelection, 0) then
        self:_DoShopAreaExit()
    end
end

function XUiPanelTheatre5SkillChoice:OnShopAreaPointerDown(eventData)
    -- 保底逻辑，防止遮罩因为某些原因没有正常关闭而导致无法操作商店商品
    self.FullShopAreaForSell.gameObject:SetActiveEx(false)
    if self.RawImgLight then
        self.RawImgLight.gameObject:SetActiveEx(false)
    end
end


function XUiPanelTheatre5SkillChoice:SetFullAreaState(isShow)
    self.FullShopAreaForSell.gameObject:SetActiveEx(isShow)

    if not isShow then
        if self.RawImgLight then
            self.RawImgLight.gameObject:SetActiveEx(false)
        end
    end
end
--endregion



return XUiPanelTheatre5SkillChoice