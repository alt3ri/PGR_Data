--- 商店面板
---@class XUiPanelTheatre5Store: XUiNode
---@field private _Control XTheatre5Control
---@field Parent XUiTheatre5BattleShop
---@field BtnFreezeAllStateCtrl XUiComponent.XUiStateControl
local XUiPanelTheatre5Store = XClass(XUiNode, 'XUiPanelTheatre5Store')
local XUiGridTheatre5ShopGoods = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5ShopGoods')

local FreezeTargetAll = -1

function XUiPanelTheatre5Store:OnStart()
    self.BtnTitle:AddEventListener(handler(self, self.OnBtnTitleClickEvent))
    self.BtnFreezeAll:AddEventListener(handler(self, self.OnBtnFreezeAllClickEvent))
    self.BtnRefresh:AddEventListener(handler(self, self.OnBtnRefreshClickEvent))
    self:InitStoreContainers()
    self:RefreshStoreShow()
    self:InitFullShopArea()
end

function XUiPanelTheatre5Store:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE5_REFRESH_STORE_SHOW, self.RefreshStoreShow, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_STORE_SHOW, self.RefreshStoreShow, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FULLSHOPAREA_SHOW_STATE, self.SetFullAreaState, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CANCEL_CONTAINERS_FOCUS, self.OnApplicationPauseEvent, self)
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_PLAY_GOODS_FREEZE_SFX, self.PlayFreezeSFX, self)
end

function XUiPanelTheatre5Store:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE5_REFRESH_STORE_SHOW, self.RefreshStoreShow, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_REFRESH_STORE_SHOW, self.RefreshStoreShow, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_FULLSHOPAREA_SHOW_STATE, self.SetFullAreaState, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CANCEL_CONTAINERS_FOCUS, self.OnApplicationPauseEvent, self)
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_PLAY_GOODS_FREEZE_SFX, self.PlayFreezeSFX, self)
end

function XUiPanelTheatre5Store:InitStoreContainers()
    ---@type XUiGridTheatre5ShopGoods[]
    self.GridContainers = {}
    
    local shopGridTotalCount = self._Control.PVPControl:GetShopGridsTotalCount()
    
    XUiHelper.RefreshCustomizedList(self.ListItem.transform, self.GridItem, shopGridTotalCount, function(index, go)
        ---@type XUiGridTheatre5ShopGoods
        local grid = XUiGridTheatre5ShopGoods.New(go, self)
        grid:Open()
        grid:SetContainerType(XMVCA.XTheatre5.EnumConst.ItemContainerType.Goods)
        grid:SetContainerIndex(index)
        
        self.GridContainers[index] = grid
    end)
end

---@param isRefreshNew @是否刷新商店商品
function XUiPanelTheatre5Store:RefreshStoreShow(isRefreshNew)
    -- 标题
    ---@type XTableTheatre5Shop
    local shopCfg = self._Control.ShopControl:GetCurShopCfg()

    if shopCfg then
        self.BtnTitle:SetNameByGroup(0, shopCfg.Name)
    end
    
    -- 刷新格子解锁状态
    local unlockCount = self._Control.ShopControl:GetShopUnlockGridsCount()
    
    for i, v in ipairs(self.GridContainers) do
        local isLock = i > unlockCount
        v:SetLockState(isLock)

        if not isLock then
            v:SetItemData(self._Control.ShopControl:GetShopGoodsByIndex(i), isRefreshNew)
        end
    end
    
    -- 刷新冻结按钮显示
    self.IsFreezeAll = self._Control.ShopControl:CheckAllGoodsIsFreeze()
    self.BtnFreezeAll:SetNameByGroup(0, self._Control.ShopControl:GetShopFreezeStateLabel(self.IsFreezeAll))
    self.BtnFreezeAllStateCtrl:ChangeState(self.IsFreezeAll and 'ShowUnFreeze' or 'ShowFreeze')
    -- 刷新刷新按钮显示
    self.CurRefreshCfg = self._Control.ShopControl:GetCurShopRefreshCntCostCfg()

    if self.CurRefreshCfg then
        local refreshCost = self._Control.ShopControl:GetShopRefreshCost()
        self.BtnRefresh:SetNameByGroup(1, refreshCost)
        
        local isGoldEnough = self._Control.ShopControl:GetGoldNum() >= refreshCost
        
        self.BtnRefresh:SetButtonState(isGoldEnough and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    end
end

--region 卖出相关

function XUiPanelTheatre5Store:InitFullShopArea()
    ---@type XUguiEventListener
    self.UiFullShopAreaEventCom = self.FullShopAreaForSell.gameObject:GetComponent(typeof(CS.XUguiEventListener))

    if not self.UiFullShopAreaEventCom then
        self.UiFullShopAreaEventCom = self.FullShopAreaForSell.gameObject:AddComponent(typeof(CS.XUguiEventListener))
    end
    
    self.UiFullShopAreaEventCom.OnEnter = handler(self, self.OnShopAreaPointerEnter)
    self.UiFullShopAreaEventCom.OnExit = handler(self, self.OnShopAreaPointerExit)
    self.UiFullShopAreaEventCom.OnDown = handler(self, self.OnShopAreaPointerDown)

    self.FullShopAreaForSell.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre5Store:OnShopAreaPointerEnter(eventData)
    if self._Control.ShopControl:GetIsDraggingItem() then
        self._Control.ShopControl:SetFocusContainer(XMVCA.XTheatre5.EnumConst.ItemContainerType.Goods, 0)
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_ENTER_FULLSHOPAREA)

        local isFromShop = self._Control.ShopControl:GetDraggingItemOwnerContainerType() == XMVCA.XTheatre5.EnumConst.ItemContainerType.Goods
        
        if not isFromShop and self.RawImgLight then
            self.RawImgLight.gameObject:SetActiveEx(true)
        end
    end
end

function XUiPanelTheatre5Store:OnShopAreaPointerExit(eventData)
    self:_DoShopAreaExit()
end

function XUiPanelTheatre5Store:_DoShopAreaExit()
    self._Control.ShopControl:SetFocusContainer(nil, nil)
    self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_EXIT_FULLSHOPAREA)
    if self.RawImgLight then
        self.RawImgLight.gameObject:SetActiveEx(false)
    end
end

function XUiPanelTheatre5Store:OnApplicationPauseEvent(isPause)
    if self._Control.ShopControl:CheckIsSameContainer(XMVCA.XTheatre5.EnumConst.ItemContainerType.Goods, 0) then
        self:_DoShopAreaExit()
    end
end

function XUiPanelTheatre5Store:OnShopAreaPointerDown(eventData)
    -- 保底逻辑，防止遮罩因为某些原因没有正常关闭而导致无法操作商店商品
    self.FullShopAreaForSell.gameObject:SetActiveEx(false)
    if self.RawImgLight then
        self.RawImgLight.gameObject:SetActiveEx(false)
    end
end


function XUiPanelTheatre5Store:SetFullAreaState(isShow)
    self.FullShopAreaForSell.gameObject:SetActiveEx(isShow)

    if not isShow then
        if self.RawImgLight then
            self.RawImgLight.gameObject:SetActiveEx(false)
        end
    end
end
--endregion

function XUiPanelTheatre5Store:OnBtnTitleClickEvent()
    self.Parent:OpenShopDetailPanel()
end

function XUiPanelTheatre5Store:OnBtnFreezeAllClickEvent()
    -- 判断是否有商品
    if not self._Control.ShopControl:CheckAllGoodsAreSellOut() then
        local isFreezeAll = self.IsFreezeAll
        
        XMVCA.XTheatre5:RequestTheatre5ShopFreeze(FreezeTargetAll, not self.IsFreezeAll, function(success)
            if success then
                self._Control.ShopControl:RefreshAfterFreezeRequest()
                
                self:PlayFreezeSFX(not isFreezeAll)
            end
        end)
    else
        XUiManager.TipMsg(self._Control.ShopControl:GetClientConfigFreezeAllSellOutGoodsTips())
    end
end

function XUiPanelTheatre5Store:OnBtnRefreshClickEvent()
    if self.CurRefreshCfg then
        -- 判断是否全冻结
        if self._Control.ShopControl:CheckAllGoodsIsFreeze() and not self._Control.ShopControl:CheckHasAnyGoodsIsSellOut() then
            XUiManager.TipMsg(self._Control.ShopControl:GetClientConfigAllFreezeShopRefreshTips())
            return
        end
        
        local goldCost = self._Control.ShopControl:GetShopRefreshCost()
        if self._Control.ShopControl:GetGoldNum() >= goldCost then
            XMVCA.XTheatre5:RequestTheatre5ShopRefresh(function(success)
                if success then
                    self._Control.ShopControl:RefreshAfterRefreshRequest()
                end
            end)
        else
            XUiManager.TipMsg(self._Control.ShopControl:GetShopRefreshErrorTips())
        end
    end
end

--- 播放解冻音效
function XUiPanelTheatre5Store:PlayFreezeSFX(isFreeze)
    if isFreeze then
        if self.SFX_Freeze then
            self.SFX_Freeze.gameObject:SetActiveEx(false)
            self.SFX_Freeze.gameObject:SetActiveEx(true)
        end
    else
        if self.SFX_UnFreeze then
            self.SFX_UnFreeze.gameObject:SetActiveEx(false)
            self.SFX_UnFreeze.gameObject:SetActiveEx(true)
        end
    end

end

return XUiPanelTheatre5Store