--- 商店拖拽购买提示组件（独立 XUiNode）。
--- 拖拽商店商品时由 ComBottomBag:_OnDragBegin 调 Show 显：
---   中性态（购买区前）显 ImgNormal + TxtDragBuyTips；
---   进购买区（战斗区/暂存区）显 ImgNormal + TxtDragBuyPriceTips（替代 TxtDragBuyTips）。
--- 3 态切换逻辑封装本类（RefreshState）；当前骨架接 Show/Hide，RefreshState 触发留后续扩展。#PanelDragBuyTips
local XUiPanelPunishaarDragBuyTips = XClass(XUiNode, "XUiPanelPunishaarDragBuyTips")

---@field protected _Control XPunishaarControl
---@field Parent
---@field ImgNormal UnityEngine.UI.Image 中性基础图（拖拽期间恒显）
---@field TxtDragBuyTips UnityEngine.UI.Text 购买区前提示文本（中性态显）
---@field TxtDragBuyPriceTips UnityEngine.UI.Text 购买区内提示文本（进购买区显）

function XUiPanelPunishaarDragBuyTips:OnStart()
    -- 初始隐购买区文本（中性态为默认；Show 时再 _ApplyNeutral 统一设）
    if self.TxtDragBuyPriceTips then
        self.TxtDragBuyPriceTips.gameObject:SetActiveEx(false)
    end
end

--- 显示购买提示（拖拽商店商品时由 ComBottomBag:_OnDragBegin 调）。
--- Open 后默认中性态（ImgNormal + TxtDragBuyTips 显，TxtDragBuyPriceTips 隐）。
function XUiPanelPunishaarDragBuyTips:Show()
    self:Open()
    self:_ApplyNeutral()
end

--- 隐藏（拖拽结束由 ComBottomBag:_OnDragEnd 调；幂等）。
function XUiPanelPunishaarDragBuyTips:Hide()
    self:Close()
end

--- 按当前落点区切换中性/购买区态。
--- 骨架就绪，触发留后续扩展（每帧轮询 GetDragFocusArea 或 handler 回调调本方法）。
---@param focusArea number|nil DragArea（FightArea/Bag=购买区，其余/nil=中性）
function XUiPanelPunishaarDragBuyTips:RefreshState(focusArea)
    local DragArea = self._Control.GameControl.DragArea
    if focusArea == DragArea.FightArea or focusArea == DragArea.Bag then
        self:_ApplyBuyZone()
    else
        self:_ApplyNeutral()
    end
end

--- 中性态：ImgNormal + TxtDragBuyTips 显，TxtDragBuyPriceTips 隐
function XUiPanelPunishaarDragBuyTips:_ApplyNeutral()
    if self.ImgNormal then
        self.ImgNormal.gameObject:SetActiveEx(true)
    end
    if self.TxtDragBuyTips then
        self.TxtDragBuyTips.gameObject:SetActiveEx(true)
    end
    if self.TxtDragBuyPriceTips then
        self.TxtDragBuyPriceTips.gameObject:SetActiveEx(false)
    end
end

--- 购买区态：ImgNormal + TxtDragBuyPriceTips 显，TxtDragBuyTips 隐
function XUiPanelPunishaarDragBuyTips:_ApplyBuyZone()
    if self.ImgNormal then
        self.ImgNormal.gameObject:SetActiveEx(true)
    end
    if self.TxtDragBuyTips then
        self.TxtDragBuyTips.gameObject:SetActiveEx(false)
    end
    if self.TxtDragBuyPriceTips then
        self.TxtDragBuyPriceTips.gameObject:SetActiveEx(true)
    end
end

return XUiPanelPunishaarDragBuyTips
