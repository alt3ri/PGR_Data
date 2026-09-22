--- 商店/装备栏槽位占位 grid（提供位置锚点，显示锁定状态）
---@class XUiGridShopCardSlot: XUiNode
---@field protected _Control XPunishaarControl
---@field Parent
---@field PanelNone UnityEngine.GameObject 空槽默认外观（装备栏 + 锁定状态底图）
---@field PanelShopNone UnityEngine.GameObject 商店空槽外观（仅商店已解锁槽位使用）
---@field PanelLock UnityEngine.GameObject 锁定遮罩
local XUiGridShopCardSlot = XClass(XUiNode, "XUiGridShopCardSlot")

---@param isUnlock boolean 是否已解锁
---@param isShopMode boolean 商店商品槽模式（true）；装备栏模式（false）
function XUiGridShopCardSlot:RefreshUnlockState(isUnlock, isShopMode)
    if self.PanelLock then
        self.PanelLock.gameObject:SetActiveEx(not isUnlock)
    end
    local showShopNone = isUnlock and isShopMode
    if self.PanelNone then
        self.PanelNone.gameObject:SetActiveEx(not showShopNone)
    end
    if self.PanelShopNone then
        self.PanelShopNone.gameObject:SetActiveEx(showShopNone)
    end
end

--- 作为拖拽落点：挂 XUguiEventListener，拖拽会话中指针进出联动 Control 拖拽中枢。幂等。
---@param area number Control.DragArea：本槽位所属落点区域（FightArea）
---@param posIndex number 槽位位置索引（1-based，对应卡的 StartPos）
function XUiGridShopCardSlot:EnableAsDropZone(area, posIndex)
    -- 栏级反算接管落点，旧单格 PointEnter 暂注释 #批次2（保留以备回退）
    --[[
    self._DropArea = area
    self._DropPosIndex = posIndex
    if self._DropInited then return end
    self._DropInited = true

    local com = self.GameObject:GetComponent(typeof(CS.XUguiEventListener))
    if XTool.UObjIsNil(com) then
        com = self.GameObject:AddComponent(typeof(CS.XUguiEventListener))
    end
    com.OnEnter = handler(self, self._OnDropPointerEnter)
    com.OnExit  = handler(self, self._OnDropPointerExit)
    --]]
end

function XUiGridShopCardSlot:_OnDropPointerEnter()
    if self._Control.GameControl:GetIsDraggingCard() then
        self._Control.GameControl:SetDragFocusTarget(self._DropArea, self._DropPosIndex)
    end
end

function XUiGridShopCardSlot:_OnDropPointerExit()
    if self._Control.GameControl:GetIsDraggingCard() then
        self._Control.GameControl:ClearDragFocusTarget()
    end
end

return XUiGridShopCardSlot
