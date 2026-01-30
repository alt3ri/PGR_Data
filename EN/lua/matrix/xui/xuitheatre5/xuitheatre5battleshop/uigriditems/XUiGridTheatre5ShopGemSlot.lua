local XUiGridTheatre5ShopContainer = require('XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5ShopContainer')

--- 商店容器派生 - 宝珠槽位
---@class XUiGridTheatre5ShopGemSlot: XUiGridTheatre5ShopContainer
local XUiGridTheatre5ShopGemSlot = XClass(XUiGridTheatre5ShopContainer, 'XUiGridTheatre5ShopGemSlot')

function XUiGridTheatre5ShopGemSlot:OnStart()
    XUiGridTheatre5ShopContainer.OnStart(self)

    self.BtnLock:AddEventListener(handler(self, self.OnBtnLockClickEvent))
    self.Noneffective = self.Noneffective or XUiHelper.TryGetComponent(self.Transform, "Noneffective", "RectTransform")
end

function XUiGridTheatre5ShopGemSlot:SetLockShow(isLock, isUnlockNext)
    self.IsLock = isLock
    self.IsUnlockNext = isUnlockNext

    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(isLock)
    end

    -- 是否是下一个解锁的格子，是则显示价格
    self.PanelUnlockPrice.gameObject:SetActiveEx(isUnlockNext)

    if isUnlockNext then
        ---@type XTableTheatre5GridUnlockCost
        local cost = self._Control.ShopControl:GetCurTurnsGemSlotUnlockCost()

        self.TxtNum.text = cost
    end
end

---@overload
---@param eventData UnityEngine.EventSystems.PointerEventData
function XUiGridTheatre5ShopGemSlot:OnPointerEnter(eventData)
    -- 锁定的宝珠槽，拖拽上去不显示聚焦图片
    if self.IsLock then
        return
    end

    XUiGridTheatre5ShopContainer.OnPointerEnter(self, eventData)
end

function XUiGridTheatre5ShopGemSlot:OnBtnLockClickEvent()
    if not self.IsLock and self.IsUnlockNext then
        return
    end

    ---@type XTableTheatre5GridUnlockCost
    local cost = self._Control.ShopControl:GetCurTurnsGemSlotUnlockCost()
    local goldNum = self._Control:GetGoldNum()

    local content = XUiHelper.FormatText(self._Control.ShopControl:GetTheatre5NewGemSlotUnlockTipsFromClientConfig(), cost)

    -- 判断金币是否足够
    if cost <= goldNum then
        -- 在手机上可以同时点击两个不同位置的槽位，导致重复弹出
        if XLuaUiManager.IsStackUiOpen("UiTheatre5PopupCommon") then
            return
        end
        XMVCA.XTheatre5:TryPopupDialog(XUiHelper.GetText("TipTitle"), content, nil, function()
            XMVCA.XTheatre5:RequestTheatre5ShopUnlockGridRequest(XMVCA.XTheatre5.EnumConst.ItemType.Equip)
        end, nil, nil, nil, nil, nil, true)
    else
        XUiManager.TipMsg(self._Control.ShopControl:GetTheatre5GemSlotUnlockLackGoldErrorFromClientConfig())
    end
end

return XUiGridTheatre5ShopGemSlot