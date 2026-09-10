local XUiGridShopCard = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopCard")
local XUiGridShopCardSlot = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopCardSlot")
local XUiNodeList = require("XUi/XUiCommon/XUiNodeList")
local XUiPanelPunishaarDragBuyTips = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/Panel/XUiPanelPunishaarDragBuyTips")

-- PanelDragBuyTips cardType/state 值（对齐 XUiPanelPunishaarDragBuyTips 内部 file-local 枚举；
-- 项目禁类静态字段直接访问 ClassName.Field，容器本地镜像约定值，Tips 枚举值变更须两边同步）
local DragBuyCardType = { MainCard = 1, SubCard = 2 }
local DragBuyState = { Invalid = 1, Neutral = 2, BuyZone = 3 }

--- 背包暂存区卡牌-slot 容器基类：显示 Bag 区域卡牌，由父容器 BtnBag 控制显隐。
--- 商店态/战前态共用；当前两子类零差异，派生点(_Get* 系列)预留供将来分离时重写。
---@class XUiPunishaarPanelBagLayoutBase : XUiNode
---@field protected _Control XPunishaarControl
---@field PanelExpandBagList UnityEngine.RectTransform 背包卡牌父节点
---@field GridCard UnityEngine.RectTransform 背包卡牌模板
---@field PanelBagSlotList UnityEngine.RectTransform 背包格子父节点
---@field GridSlot UnityEngine.RectTransform 背包格子模板
---@field PanelDragBuyTips UnityEngine.RectTransform 拖拽购买提示根节点（仅商店态实例化 XUiNode，其他态直接隐 GO）#PanelDragBuyTips
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

--- 拖拽购买提示 XUiNode 类（默认 nil=不实例化；商店态子类覆写返回 XUiPanelPunishaarDragBuyTips）。
--- 非商店态 nil 时若 prefab 有 PanelDragBuyTips 引用则直接隐 GO 不实例化 #PanelDragBuyTips
function XUiPunishaarPanelBagLayoutBase:_GetDragBuyTipsClass()
    return nil
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

    -- 拖拽购买提示（PanelDragBuyTips）：仅商店态实例化 XUiNode（_GetDragBuyTipsClass 派生点），
    -- 非商店态若 prefab 有引用则直接隐 GO 不实例化。先 SetActiveEx(false) 防 New 时 activeSelf=true 自动 Open #PanelDragBuyTips
    if self.PanelDragBuyTips then
        self.PanelDragBuyTips.gameObject:SetActiveEx(false)
        local tipsCls = self:_GetDragBuyTipsClass()
        if tipsCls then
            ---@type XUiPanelPunishaarDragBuyTips
            self._DragBuyTips = tipsCls.New(self.PanelDragBuyTips, self)
        end
    end
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
    -- 拖拽焦点变化→刷购买提示态（Neutral/BuyZone）#PanelDragBuyTips
    self._Control.GameControl:AddEventListener(self._Control.GameControl.DragEventId.FocusChange, self._OnDragFocusChange, self)
    -- 栏级落点反算注册：handler OnDragging 遍历注册栏做落点反算 #批次2
    self._Control.GameControl:RegisterDragFocusBar(self)
end

function XUiPunishaarPanelBagLayoutBase:OnDisable()
    -- 兜底隐购买提示：若拖拽进行中切态（DRAG_END 订阅随本 OnDisable 注销，tips 收不到 Hide），
    -- 防 _DragBuyTips 残留 Open 态挂 inactive 祖先下违 active-ancestor 不变量 + 重显时 stale 闪 #PanelDragBuyTips
    if self._DragBuyTips then
        self._DragBuyTips:Close()
    end
    self._IsSubCardInvalid = nil  -- 清副卡 Invalid 标记（防切态残留）#M1
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_BAG_GRID_UNLOCK, self._RefreshSlots, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_DRAG_BEGIN, self._OnDragBegin, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_DRAG_END, self._OnDragEnd, self)
    self._Control.GameControl:RemoveEventListener(self._Control.GameControl.DragEventId.FocusChange, self._OnDragFocusChange, self)
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
--- 商店副卡商品拖拽显副卡态购买提示；主卡商品拖拽不显（由 ComBottomBag 显主卡态）#PanelDragBuyTips
function XUiPunishaarPanelBagLayoutBase:_OnDragBegin()
    local gc = self._Control.GameControl
    local srcArea = gc:GetDraggingSourceArea()
    if srcArea == gc.DragArea.Shop then
        -- 仅副卡商品拖拽显副卡态提示；主卡商品拖拽跳过（ComBottomBag 的 _DragBuyTips 显主卡态）。
        -- 主卡/副卡判定复刻 BeginDragCard（gc._IsDraggingSubCard 无公开 getter，UI 层不跨入逻辑层读私有字段）#PanelDragBuyTips
        if self._DragBuyTips then
            local cardData = gc:GetDraggingCardData()
            local isSubCard = cardData and cardData.CardId and self._Control:IsSubCard(cardData.CardId) or false
            if isSubCard then
                self._DragBuyTips:Show(DragBuyCardType.SubCard)
                -- Invalid 判定（拖起时算一次，全程恒显）：全场无可装配宿主 → Invalid（TxtSubCardNoneSlot）#M1
                -- 金币不足不在此判（与主卡同，到达可买入位 BuyZone 才显 canComplete=false）
                self._IsSubCardInvalid = not gc:HasMountableMasterForSubCard(cardData.CardId)
                if self._IsSubCardInvalid then
                    self._DragBuyTips:RefreshState(DragBuyState.Invalid, true)
                end
            end
        end
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
    -- 隐购买提示（幂等，nil 跳过；置 _CardList 守卫前防 Shop 源结束漏隐）#PanelDragBuyTips
    if self._DragBuyTips then
        self._DragBuyTips:Hide()
    end
    self._IsSubCardInvalid = nil  -- 清副卡 Invalid 标记 #M1
    if not self._CardList then
        return
    end
    self._CardList:ForEachActive(function(_, grid)
        grid:SetBlocksRaycasts(true)
    end)
end

--- 拖拽焦点变化→刷副卡态购买提示（Neutral/BuyZone）#PanelDragBuyTips
--- 仅副卡商品拖拽处理；主卡拖拽由 ComBottomBag 显主卡态。
--- Invalid 态（全场无可装配宿主）拖起时算恒显，此方法内 _IsSubCardInvalid 守卫 return 不切 #M1
--- 焦点在 Bag/Fight 空槽位（无主卡）保持上一态不切；焦点在主卡格→BuyZone(canMount AND 金币够)；焦点离开 Bag/Fight→Neutral
---@param payload table|nil {Area,Pos} 或 nil（焦点清空）
function XUiPunishaarPanelBagLayoutBase:_OnDragFocusChange(payload)
    if not self._DragBuyTips then
        return
    end
    local gc = self._Control.GameControl
    if gc:GetDraggingSourceArea() ~= gc.DragArea.Shop then
        return
    end
    local cardData = gc:GetDraggingCardData()
    local isSubCard = cardData and cardData.CardId and self._Control:IsSubCard(cardData.CardId) or false
    if not isSubCard then
        return
    end
    -- Invalid 恒显（全场无可装配宿主），不切 BuyZone/Neutral #M1
    if self._IsSubCardInvalid then
        return
    end
    local area = payload and payload.Area
    local pos = payload and payload.Pos
    if area == gc.DragArea.FightArea or area == gc.DragArea.Bag then
        if pos and gc:CheckDragDropValid() then
            local CardAreaType = XMVCA.XPunishaar.EnumConst.CardAreaType
            local cardArea = area == gc.DragArea.FightArea and CardAreaType.FightArea or CardAreaType.Bag
            local hostCard = gc:GetMasterCardByAreaPos(cardArea, pos)
            if hostCard then
                local canMount = gc:CanMountSubCardOnMaster(cardData.CardId, hostCard)
                if canMount then
                    -- 可装配主卡 → BuyZone 显价格+金币差异化（_RefreshBuyPrice 内部算金币切背景+BuyTips 1/2，canComplete 参数不用）
                    self._DragBuyTips:RefreshState(DragBuyState.BuyZone, true)
                end
                -- canMount false（不可装配该宿主，置灰格）→ 保持上一态，不 RefreshState
            end
            -- hostCard nil（空槽位）→ 保持上一态，不 RefreshState（"拖到背包栏不在卡牌上显示之前 BuyTips"）#M1
        end
        -- 无 pos（区域粒度）→ 保持上一态
    else
        -- 焦点离开 Bag/Fight（Shop/SellZone/nil 清空）→ Neutral
        self._DragBuyTips:RefreshState(DragBuyState.Neutral, true)
    end
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
