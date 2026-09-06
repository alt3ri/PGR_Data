local XUiGridShopCard = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopCard")
local XUiGridShopCardSlot = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopCardSlot")
local XUiNodeList = require("XUi/XUiCommon/XUiNodeList")

--- 背包暂存区卡牌-slot 容器基类：显示 Bag 区域卡牌，由父容器 BtnBag 控制显隐。
--- 商店态/战前态共用；当前两子类零差异，派生点(_Get* 系列)预留供将来分离时重写。
---@class XUiPunishaarPanelBagLayoutBase : XUiNode
---@field protected _Control XPunishaarControl
---@field PanelExpandBagList UnityEngine.RectTransform 背包卡牌父节点
---@field GridCard UnityEngine.RectTransform 背包卡牌模板
---@field PanelBagSlotList UnityEngine.RectTransform 背包格子父节点
---@field GridSlot UnityEngine.RectTransform 背包格子模板
local XUiPunishaarPanelBagLayoutBase = XClass(XUiNode, "XUiPunishaarPanelBagLayoutBase")

--region 派生点（hook，子类按需覆写；当前两子类用默认实现）

--- 本容器显示的卡牌区域（默认背包暂存区 Bag；预留分离）
function XUiPunishaarPanelBagLayoutBase:_GetAreaType()
    return XMVCA.XPunishaar.EnumConst.CardAreaType.Bag
end

--- 本容器对应的拖拽区域（DragArea，栏级反算 handler 匹配源栏/设落点区域用 #批次2）
function XUiPunishaarPanelBagLayoutBase:_GetDragArea()
    return self._Control.GameControl.DragArea.Bag
end

--- 背包卡 grid 类（默认 XUiGridShopCard）
function XUiPunishaarPanelBagLayoutBase:_GetGridClass()
    return XUiGridShopCard
end

--- 背包 slot grid 类（默认 XUiGridShopCardSlot）
function XUiPunishaarPanelBagLayoutBase:_GetSlotGridClass()
    return XUiGridShopCardSlot
end

--- 背包 slot 解锁上限来源（默认 GetBagGridLimit）
function XUiPunishaarPanelBagLayoutBase:_GetGridLimit()
    return self._Control:GetBagGridLimit()
end

--endregion

function XUiPunishaarPanelBagLayoutBase:OnStart()
    -- 卡牌/槽位列表容器：模板恒 inactive 仅作克隆源（根治 XUiEffectLayer 特效层级二次叠层），
    -- 内部持 XUiNode 实例替代原 _CardGridDict/_SlotGridDict + _SlotList 手工缓存。
    -- _GetGridClass/_GetSlotGridClass 为派生点，此处经 self 调保证多态。
    ---@type XUiNodeList
    self._CardList = XUiNodeList.New(self.GridCard, self.PanelExpandBagList.transform, self:_GetGridClass(), self)
    ---@type XUiNodeList
    self._SlotList = XUiNodeList.New(self.GridSlot, self.PanelBagSlotList.transform, self:_GetSlotGridClass(), self)
    self:_RefreshSlots()
end

function XUiPunishaarPanelBagLayoutBase:OnEnable()
    -- Enable 时刷新 slot 解锁态（重读 _GetGridLimit，子界面切换/重新进入均刷）
    self:_RefreshSlots()
    -- 副卡宿主选择态：拖起副卡时给"不可作宿主的背包主卡格"置灰，松手时恢复（OnEnable 订阅 / OnDisable 注销）
    self._Control.GameControl:AddEventListener(self._Control.GameControl.DragEventId.SubCardHostHintBegin, self.OnSubCardHostHintBegin, self)
    self._Control.GameControl:AddEventListener(self._Control.GameControl.DragEventId.SubCardHostHintEnd, self.OnSubCardHostHintEnd, self)
    -- 激活态槽位解锁刷新：服务端经 NotifyPunishaarRewardResult 推 BagGridLimit 奖励时实时刷 slot
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_BAG_GRID_UNLOCK, self._RefreshSlots, self)
    -- 主卡拖拽编排时关 blocksRaycasts 让 Slot 射线穿透报精确格位 #52
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_DRAG_BEGIN, self._OnDragBegin, self)
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_DRAG_END, self._OnDragEnd, self)
    -- 栏级落点反算注册：handler OnDragging 遍历注册栏做落点反算 #批次2
    self._Control.GameControl:RegisterDragFocusBar(self)
end

function XUiPunishaarPanelBagLayoutBase:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_BAG_GRID_UNLOCK, self._RefreshSlots, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_DRAG_BEGIN, self._OnDragBegin, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_DRAG_END, self._OnDragEnd, self)
    self._Control.GameControl:RemoveEventListener(self._Control.GameControl.DragEventId.SubCardHostHintBegin, self.OnSubCardHostHintBegin, self)
    self._Control.GameControl:RemoveEventListener(self._Control.GameControl.DragEventId.SubCardHostHintEnd, self.OnSubCardHostHintEnd, self)
    self._Control.GameControl:UnregisterDragFocusBar(self)
end

--- 拖起副卡：遍历背包主卡格，不可作宿主的置灰，可作宿主的保持常态。
---@param subCardId number 正在拖拽的副卡模板 Id
function XUiPunishaarPanelBagLayoutBase:OnSubCardHostHintBegin(subCardId)
    if not self._CardList then
        return
    end
    self._CardList:ForEachActive(function(_, grid)
        local card = grid:GetEquippedCard()
        grid:SetDisable(not self._Control.GameControl:CanMountSubCardOnMaster(subCardId, card))
    end)
end

--- 松手：恢复全部背包主卡格为常态。
function XUiPunishaarPanelBagLayoutBase:OnSubCardHostHintEnd()
    if not self._CardList then
        return
    end
    self._CardList:ForEachActive(function(_, grid)
        grid:SetDisable(false)
    end)
end

--- 主卡拖拽开始：关 blocksRaycasts 让 Slot 射线穿透报精确格位 #52
--- 副卡拖拽（Shop 来源）不关——Card.OnEnter 需收射线作 #36 落点
function XUiPunishaarPanelBagLayoutBase:_OnDragBegin()
    local srcArea = self._Control.GameControl:GetDraggingSourceArea()
    if srcArea == self._Control.GameControl.DragArea.Shop then
        return
    end
    if not self._CardList then
        return
    end
    self._CardList:ForEachActive(function(_, grid)
        grid:SetBlocksRaycasts(false)
    end)
end

--- 拖拽结束：恢复 blocksRaycasts #52
function XUiPunishaarPanelBagLayoutBase:_OnDragEnd()
    if not self._CardList then
        return
    end
    self._CardList:ForEachActive(function(_, grid)
        grid:SetBlocksRaycasts(true)
    end)
end

--- 核心骨架：刷背包卡牌列表（复用 XList 容器，零 per-call GC；FillAreaCardsSorted 内部已按 StartPos 排序）
function XUiPunishaarPanelBagLayoutBase:Refresh()
    if not self._BagAreaCardsList then
        self._BagAreaCardsList = XTool.XListNew()
    end
    local count = self._Control:FillAreaCardsSorted(self:_GetAreaType(), self._BagAreaCardsList)

    self._CardList:Refresh(count, function(index, grid)
        local card = self._BagAreaCardsList:GetValueByIndex(index)
        local cfg = self._Control:GetTablePunishaarCard(card.TemplateId, true)
        local sz = cfg and cfg.Size or 1
        grid:RefreshAsEquipped(card, sz, self.GridSlot)
        grid:EnableDrag(self._Control.GameControl.DragArea.Bag)
        -- 主卡 grid 自身作落点（副卡拖拽释放于此→装配，解决主卡 Image 拦截 slot listener #36）
        -- 栏级反算接管落点，旧单格 PointEnter 暂注释 #批次2
        -- grid:EnableAsDropZone()
        local slot = self:GetSlotByIndex(card.StartPos)
        if slot then
            grid:RefreshPosition(slot)
        end
    end)
end

--- 核心骨架：建背包 slot 列表，构造位置索引供卡牌坐标重合。
function XUiPunishaarPanelBagLayoutBase:_RefreshSlots()
    local maxCount = XMVCA.XPunishaar:GetClientNumberByKey("EquipCardMaxSlotCount")
    local unlockLimit = self:_GetGridLimit() or maxCount

    self._SlotList:Refresh(maxCount, function(index, grid)
        grid:RefreshUnlockState(index <= unlockLimit, false)
        -- 栏级反算接管落点，旧单格 PointEnter 暂注释 #批次2
        -- grid:EnableAsDropZone(self._Control.GameControl.DragArea.Bag, index)
    end)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelBagSlotList.transform)
end

function XUiPunishaarPanelBagLayoutBase:GetSlotByIndex(index)
    return self._SlotList and self._SlotList:GetActive(index)
end

--region 落点反算 slot 射线提供方（handler 逐 slot 几何命中 #落点重构） --------

function XUiPunishaarPanelBagLayoutBase:GetDragArea()
    return self:_GetDragArea()
end

--- 当前显示中的 slot 数量（handler 遍历逐 slot 射线用）。
---@return number
function XUiPunishaarPanelBagLayoutBase:GetSlotListCount()
    if not self._SlotList then
        return 0
    end
    return self._SlotList:GetActiveCount() or 0
end

--- slot 格周期（slot sizeDelta.x）。slot RT 覆盖完整落点格子（无间隙 → sizeDelta.x=格周期），
--- handler OnBeginDrag 算基准偏移 K=floor(_DragOffsetX/格周期) 用。
---@return number|nil
function XUiPunishaarPanelBagLayoutBase:GetDragSlotWidth()
    local slot1 = self._SlotList and self._SlotList:GetActive(1)
    if not slot1 or XTool.UObjIsNil(slot1.Transform) then
        return nil
    end
    return slot1.Transform.sizeDelta.x
end

--endregion

return XUiPunishaarPanelBagLayoutBase
