--- 商店拖拽卖出区组件（独立 XUiNode）。
--- 外部（PanelTopShop）拖拽拥有卡牌时 Open 本组件 + Refresh(cardData) 显示卖出价；
--- 本节点同时作 DropZone（XUguiEventListener OnEnter→SetDragFocusTarget(SellZone)），
--- 拖到本区域松手即触发卖出（EndDragCard→_DropAction_Sell）#50。
local XUiPanelPunishaarSellEffect = XClass(XUiNode, "XUiPanelPunishaarSellEffect")

---@field protected _Control XPunishaarControl
---@field Parent
---@field TxtPrice UnityEngine.UI.Text 卖出价值文本（主卡 Sell + 副卡 Sell 合计）

function XUiPanelPunishaarSellEffect:OnStart()
    -- 作 DropZone：XUguiEventListener OnEnter/Exit 联动 DragControl 焦点 #50
    local com = self.GameObject:GetComponent(typeof(CS.XUguiEventListener))
    if XTool.UObjIsNil(com) then
        com = self.GameObject:AddComponent(typeof(CS.XUguiEventListener))
    end
    com.OnEnter = handler(self, self._OnDropZoneEnter)
    com.OnExit  = handler(self, self._OnDropZoneExit)
end

--- 刷新卖出价显示。
---@param cardData table|nil Server.XPunishaarMasterCard（拖拽中的拥有卡牌；nil→清空）
function XUiPanelPunishaarSellEffect:Refresh(cardData)
    if self.TxtGetPrice then
        if cardData then
            self.TxtGetPrice.text = tostring(self._Control.GameControl:GetCardSellPrice(cardData))
        else
            self.TxtGetPrice.text = ""
        end
    end
end

--- DropZone OnEnter：设 DragFocusTarget=SellZone，EndDragCard 据此路由到 _DropAction_Sell #50
function XUiPanelPunishaarSellEffect:_OnDropZoneEnter()
    if self._Control.GameControl:GetIsDraggingCard() then
        self._Control.GameControl:SetDragFocusTarget(self._Control.GameControl.DragArea.SellZone, nil)
    end
end

function XUiPanelPunishaarSellEffect:_OnDropZoneExit()
    if self._Control.GameControl:GetIsDraggingCard() then
        self._Control.GameControl:ClearDragFocusTarget()
    end
end

return XUiPanelPunishaarSellEffect
