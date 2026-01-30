local XUiGridTheatre5Container = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Container')
--- 商店界面的物品容器，包含支持拖拽的相关逻辑
---@class XUiGridTheatre5ShopContainer: XUiGridTheatre5Container
---@field protected _Control XTheatre5Control
local XUiGridTheatre5ShopContainer = XClass(XUiGridTheatre5Container, 'XUiGridTheatre5ShopContainer')
local XUiGridTheatre5ShopItem = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5ShopItem')

function XUiGridTheatre5ShopContainer:OnStart()
    self:InitBindItem()
    self._Control:AddEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CANCEL_CONTAINERS_FOCUS, self.OnApplicationPauseEvent, self)
end

function XUiGridTheatre5Container:OnDestroy()
    self._Control:RemoveEventListener(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_CANCEL_CONTAINERS_FOCUS, self.OnApplicationPauseEvent, self)
end

function XUiGridTheatre5ShopContainer:InitBindItem()
    XUiGridTheatre5Container.InitBindItem(self, XUiGridTheatre5ShopItem)
    -- 容器需要增加组件监听Enter和Exit方法，以支持拖拽相关
    ---@type XUguiEventListener
    self.UiEventCom = self.GameObject:GetComponent(typeof(CS.XUguiEventListener))

    if not self.UiEventCom then
        self.UiEventCom = self.GameObject:AddComponent(typeof(CS.XUguiEventListener))
    end
    
    self.UiEventCom.OnEnter = handler(self, self.OnPointerEnter)
    self.UiEventCom.OnExit = handler(self, self.OnPointerExit)

    if self.UiGridGem then
        self.UiGridGem:InitDrag()
    end

    if self.UiGridSkill then
        self.UiGridSkill:InitDrag()
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridTheatre5ShopContainer:OnPointerEnter(eventData)
    -- 如果正在拖拽道具
    if self._Control.ShopControl:GetIsDraggingItem() then
        self._Control.ShopControl:SetFocusContainer(self.ContainerType, self.ContainerIndex)

        if self._Control.ShopControl:CheckDraggingItemIsFitInContainer() then
            if self.ImgSelect then
                self.ImgSelect.gameObject:SetActiveEx(true)
            end
        else
            if self.RawImgSelectNo then
                self.RawImgSelectNo.gameObject:SetActiveEx(true)
            end
        end
    end
end

---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridTheatre5ShopContainer:OnPointerExit(eventData)
    self:CancelFocus()
end

function XUiGridTheatre5ShopContainer:CancelFocus()
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end

    if self.RawImgSelectNo then
        self.RawImgSelectNo.gameObject:SetActiveEx(false)
    end

    self._Control.ShopControl:SetFocusContainer(nil, nil)
end

function XUiGridTheatre5ShopContainer:OnApplicationPauseEvent(isPause)
    if self._Control.ShopControl:CheckIsSameContainer(self.ContainerType, self.ContainerIndex) then
        self:CancelFocus()
    end
end

return XUiGridTheatre5ShopContainer