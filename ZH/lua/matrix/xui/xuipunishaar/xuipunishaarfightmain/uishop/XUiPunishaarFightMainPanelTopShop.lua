local XUiGridShopCard          = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopCard")
local XUiGridShopCardSlot      = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopCardSlot")
local XUiPanelPunishaarSellEffect = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/Panel/XUiPanelPunishaarSellEffect")
local XUiNodeList = require("XUi/XUiCommon/XUiNodeList")

--- 商店商品展示面板：显示当前节点所有商品槽位，提供购买/刷新/离开操作。
--- 拖拽拥有的卡牌时委托 XUiPanelPunishaarSellEffect 显示卖出区 + 卖出价 #50。
---@class XUiPunishaarPanelTopShop : XUiNode
---@field _Control XPunishaarControl
---@field BtnExitShop XUiComponent.XUiButton 结束商店节点
---@field BtnRefresh XUiComponent.XUiButton 刷新商店商品
---@field PanelBagSlotList UnityEngine.RectTransform 商品槽位格子父节点
---@field GridSlot UnityEngine.RectTransform 商品槽位格子模板
---@field PanelShopList UnityEngine.RectTransform 商品卡牌父节点
---@field GridCard UnityEngine.RectTransform 商品卡牌模板
---@field BtnFoldUp XUiComponent.XUiButton 控制商店界面展开/收回
---@field PanelSellEffect UnityEngine.RectTransform 拖拽卖出区根节点（挂 XUiPanelPunishaarSellEffect #50）
local XUiPunishaarFightMainPanelTopShop = XClass(XUiNode, "XUiPunishaarFightMainPanelTopShop")

function XUiPunishaarFightMainPanelTopShop:InitComponents()
    local exitHandler = handler(self, self.OnBtnExitShopClick)
    self.BtnExitShop:AddEventListener(exitHandler)
    self.BtnRefresh:AddEventListener(handler(self, self.OnBtnRefreshClick))
    self.BtnFoldUp:AddEventListener(handler(self, self.OnBtnFoldUpClick))

    if self.ExpandBtnExitShop then
        self.ExpandBtnExitShop:AddEventListener(exitHandler)
    end
    
    -- 商品卡/槽位列表容器：模板恒 inactive 仅作克隆源（根治 XUiEffectLayer 特效层级二次叠层），
    -- 内部持 XUiNode 实例替代原 _CardGridDict/_SlotGridDict + _SlotList 手工缓存。
    ---@type XUiNodeList
    self._CardList = XUiNodeList.New(self.GridCard, self.PanelShopList.transform, XUiGridShopCard, self)
    ---@type XUiNodeList
    self._SlotList = XUiNodeList.New(self.GridSlot, self.PanelBagSlotList.transform, XUiGridShopCardSlot, self)

    -- 卖出区组件（独立 XUiNode，自管 DropZone + 卖出价显示 #50）
    if self.PanelSellEffect then
        ---@type XUiPanelPunishaarSellEffect
        self.SellEffect = XUiPanelPunishaarSellEffect.New(self.PanelSellEffect, self)
        self.SellEffect:Close()  -- 初始隐藏
    end
end

function XUiPunishaarFightMainPanelTopShop:OnStart(...)
    self:InitComponents()
end

function XUiPunishaarFightMainPanelTopShop:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_GOLD_CHANGE, self._OnGoldChange, self)
    -- 拖拽开始/结束：显隐卖出区组件 #50
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_DRAG_BEGIN, self._OnDragBegin, self)
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_DRAG_END, self._OnDragEnd, self)
end

function XUiPunishaarFightMainPanelTopShop:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_GOLD_CHANGE, self._OnGoldChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_DRAG_BEGIN, self._OnDragBegin, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_DRAG_END, self._OnDragEnd, self)
end

function XUiPunishaarFightMainPanelTopShop:OnDestroy()
    self._FoldHandler = nil
end

--- 设置"折叠"上报回调（自上而下注入，由父 PanelShop 统一管理折叠态与互斥 #70）。
--- 本面板只上报意图，不自行 Close、不访问父节点。
---@param cb function
function XUiPunishaarFightMainPanelTopShop:SetFoldHandler(cb)
    self._FoldHandler = cb
end

--- 折叠商店面板：上报父对象（父负责 Close 本面板 + 显折叠态绳索）。
function XUiPunishaarFightMainPanelTopShop:OnBtnFoldUpClick()
    if self._FoldHandler then
        self._FoldHandler()
    end
end

--- 拖拽开始：拥有卡牌（对战区/背包）时显卖出区组件 + 显示卖出价 #50
function XUiPunishaarFightMainPanelTopShop:_OnDragBegin()
    -- 商店收起态（PanelTopShop inactive，动画驱动）时 TopShop XUiNode 订阅可能残留仍收 DRAG_BEGIN，
    -- 但父 inactive 下 SellEffect:Open 无效（activeInHierarchy=false，违活跃祖先不变式）——收起态直接跳过 #SellEffect商店态
    if not self.GameObject.activeInHierarchy then
        return
    end
    local dragData = self._Control.GameControl:GetDraggingCardData()
    local srcArea = self._Control.GameControl:GetDraggingSourceArea()
    local DragArea = self._Control.GameControl.DragArea
    -- 仅拥有卡牌（对战区/背包）拖拽时显示卖出区；商品栏拖拽不显（商品不能卖）
    if dragData and (srcArea == DragArea.FightArea or srcArea == DragArea.Bag) then
        if self.SellEffect then
            self.SellEffect:Open()
            self.SellEffect:Refresh(dragData)
        end
    end
end

--- 拖拽结束：隐卖出区组件 #50
function XUiPunishaarFightMainPanelTopShop:_OnDragEnd()
    if self.SellEffect then
        self.SellEffect:Close()
    end
end

--- 金币变动：刷刷新按钮 + 局部刷商品卡价格颜色（不重建列表，只刷价格域；grid 未开/无 _Goods 时 RefreshPrice 自行 no-op）。#商品价格颜色
function XUiPunishaarFightMainPanelTopShop:_OnGoldChange()
    self:_RefreshRefreshBtn()
    if self._CardList then
        -- ForEachActive 只遍历在用项（已 Close 的不在其中），无需再判 IsNodeShow
        self._CardList:ForEachActive(function(_, grid)
            grid:RefreshPrice()
        end)
    end
end

--- 刷新刷新按钮显示：费用文本 + 金币不足时禁用按钮（灰显作不足信号，不依赖 richText）。
--- 费用 = 基础 + 增量 × 已刷新次数（见 Control:GetShopRefreshCost）。
function XUiPunishaarFightMainPanelTopShop:_RefreshRefreshBtn()
    if not self.BtnRefresh then return end
    local cost = self._Control:GetShopRefreshCost() or 0
    local gold = self._Control:GetCurrentGold() or 0
    local canAfford = gold >= cost
    self.BtnRefresh:SetNameByGroup(1, tostring(cost))
    self.BtnRefresh:SetDisable(not canAfford)
end

function XUiPunishaarFightMainPanelTopShop:Refresh()
    local goods = self._Control:GetCurrentShopGoods()
    if not goods then return end

    -- 复用成员表 + 内层条目表（每次 Refresh 重填，避免 per-call 新建 table 抖 GC）
    if self._DisplayList == nil then
        self._DisplayList = {}
    end
    local displayList = self._DisplayList
    local count = 0
    local totalSlots = 0
    for i, g in ipairs(goods) do
        if not g.IsBought then
            local cardCfg = self._Control:GetTablePunishaarCard(g.CardId, true)
            local sz = cardCfg and cardCfg.Size or 1
            count = count + 1
            local item = displayList[count]
            if item == nil then
                item = {}
                displayList[count] = item
            end
            item.goods = g
            item.index = i
            item.size = sz
            totalSlots = totalSlots + sz
        end
    end
    -- 截断尾部残留（复用表长于本次数量时，防后续误读旧条目）
    for i = #displayList, count + 1, -1 do
        displayList[i] = nil
    end

    self._SlotList:Refresh(totalSlots, function(_, grid)
        grid:RefreshUnlockState(true, true)
    end)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelBagSlotList.transform)

    local slotPos = 1
    self._CardList:Refresh(count, function(index, grid)
        local item = displayList[index]
        grid:Refresh(item.goods, item.index, self.GridSlot)
        grid:EnableDrag(self._Control.GameControl.DragArea.Shop)
        local slot = self._SlotList:GetActive(slotPos)
        if slot then
            grid:RefreshPosition(slot)
        end
        slotPos = slotPos + item.size
    end)

    self:_RefreshRefreshBtn()
end

--- Close 所有子 grid（商品卡 grid + slot grid）——FoldTopShop 收起前调，
--- 避免 Open 态 grid 挂 inactive 父违反 xuinode-active-ancestor-invariant（延迟暴露型）。
--- ExpandTopShop:Refresh 重建时复用同一批 XUiNode 实例（已 Close 的经 Refresh 重新 Open）。
function XUiPunishaarFightMainPanelTopShop:CloseAllGrids()
    if self._SlotList then
        self._SlotList:CloseAll()
    end
    if self._CardList then
        self._CardList:CloseAll()
    end
end

function XUiPunishaarFightMainPanelTopShop:OnBtnExitShopClick()
    if self._Control:IsInRemedyShop() then
        self._Control.GameControl:LeaveRemedyShop()
    else
        self._Control.GameControl:ExitNode()
    end
end

function XUiPunishaarFightMainPanelTopShop:OnBtnRefreshClick()
    -- 金币不足校验移至 Control:RefreshShop 收口（不足派发 RefreshShopFail 供 FightMain 播 ReShowFail）#商店刷新动效
    -- RefreshShop 成功后派发 BuySuccess→RefreshAll 统一刷（含本 TopShop:Refresh 商品卡升级标记 +
    -- 战斗区卡装备态升级标记 _RefreshEquippedTags + 背包入口红点），无需回调自刷 #74
    self._Control.GameControl:RefreshShop()
end

function XUiPunishaarFightMainPanelTopShop:OnBtnExpandClick()
    -- TODO: 控制商店界面展开/收回
end

return XUiPunishaarFightMainPanelTopShop
