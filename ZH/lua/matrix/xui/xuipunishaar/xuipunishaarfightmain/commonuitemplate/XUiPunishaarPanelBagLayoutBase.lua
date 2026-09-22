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
---@field GridHighLight UnityEngine.RectTransform 主卡拖拽落点高亮（尺寸=卡覆盖的已解锁格部分，裁剪到 gridLimit；prefab 须绑本栏 slot 容器 PanelBagSlotList 下、与 slot 同 parent）#GridHighLight
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
    -- 落点高亮：强制 pivot.x=0 左对齐（多格卡左缘对齐 slot[pos]），y 保持 prefab；初始隐 #GridHighLight
    if self.GridHighLight then
        self.GridHighLight.pivot = CS.UnityEngine.Vector2(0, self.GridHighLight.pivot.y)
        self.GridHighLight.gameObject:SetActiveEx(false)
    end
end

function XUiPunishaarPanelBagLayoutBase:OnEnable()
    local gameControl = self._Control.GameControl  -- #事件统合 补 local（DRAG 订阅经 gameControl:）
    -- Enable 时刷新 slot 解锁态（重读 _GetGridLimit，子界面切换/重新进入均刷）
    self:_RefreshSlots()
    -- 副卡宿主选择态：拖起副卡时给"不可作宿主的背包主卡格"置灰，松手时恢复（OnEnable 订阅 / OnDisable 注销）
    self._Control.GameControl:AddEventListener(self._Control.GameControl.EventId.Drag.SubCardHostHintBegin, self.OnSubCardHostHintBegin, self)
    self._Control.GameControl:AddEventListener(self._Control.GameControl.EventId.Drag.SubCardHostHintEnd, self.OnSubCardHostHintEnd, self)
    -- 激活态槽位解锁刷新：服务端经 NotifyPunishaarRewardResult 推 BagGridLimit 奖励时实时刷 slot
    XMVCA.XPunishaar:AddEventListener(XMVCA.XPunishaar.EventIds.EVENT_PUNISHAAR_INNER_BAG_GRID_UNLOCK, self._RefreshSlots, self)
    -- 主卡拖拽编排时关 blocksRaycasts 让 Slot 射线穿透报精确格位 #52
    gameControl:AddEventListener(gameControl.EventId.Drag.DragBegin, self._OnDragBegin, self)
    gameControl:AddEventListener(gameControl.EventId.Drag.DragEnd, self._OnDragEnd, self)
    -- 拖拽焦点变化→刷购买提示态（Neutral/BuyZone）#PanelDragBuyTips
    self._Control.GameControl:AddEventListener(self._Control.GameControl.EventId.Drag.FocusChange, self._OnDragFocusChange, self)
    -- 栏级落点反算注册：handler OnDragging 遍历注册栏做落点反算 #批次2
    self._Control.GameControl:RegisterDragFocusBar(self)
end

function XUiPunishaarPanelBagLayoutBase:OnDisable()
    local gameControl = self._Control.GameControl  -- #事件统合 补 local（DRAG 注销经 gameControl:）
    -- 兜底隐购买提示：若拖拽进行中切态（DRAG_END 订阅随本 OnDisable 注销，tips 收不到 Hide），
    -- 防 _DragBuyTips 残留 Open 态挂 inactive 祖先下违 active-ancestor 不变量 + 重显时 stale 闪 #PanelDragBuyTips
    if self._DragBuyTips then
        self._DragBuyTips:Close()
    end
    -- 兜底隐落点高亮（防拖拽中切态残留 stale 闪，与 _DragBuyTips:Close 对称）#GridHighLight
    if self.GridHighLight then
        self.GridHighLight.gameObject:SetActiveEx(false)
    end
    self._IsSubCardInvalid = nil  -- 清副卡 Invalid 标记（防切态残留）#M1
    XMVCA.XPunishaar:RemoveEventListener(XMVCA.XPunishaar.EventIds.EVENT_PUNISHAAR_INNER_BAG_GRID_UNLOCK, self._RefreshSlots, self)
    gameControl:RemoveEventListener(gameControl.EventId.Drag.DragBegin, self._OnDragBegin, self)
    gameControl:RemoveEventListener(gameControl.EventId.Drag.DragEnd, self._OnDragEnd, self)
    self._Control.GameControl:RemoveEventListener(self._Control.GameControl.EventId.Drag.FocusChange, self._OnDragFocusChange, self)
    self._Control.GameControl:RemoveEventListener(self._Control.GameControl.EventId.Drag.SubCardHostHintBegin, self.OnSubCardHostHintBegin, self)
    self._Control.GameControl:RemoveEventListener(self._Control.GameControl.EventId.Drag.SubCardHostHintEnd, self.OnSubCardHostHintEnd, self)
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
    local gameControl = self._Control.GameControl
    local srcArea = gameControl:GetDraggingSourceArea()
    if srcArea == gameControl.DragArea.Shop then
        -- 仅副卡商品拖拽显副卡态提示；主卡商品拖拽跳过（ComBottomBag 的 _DragBuyTips 显主卡态）。
        -- 主卡/副卡判定复刻 BeginDragCard（gameControl._IsDraggingSubCard 无公开 getter，UI 层不跨入逻辑层读私有字段）#PanelDragBuyTips
        if self._DragBuyTips then
            local cardData = gameControl:GetDraggingCardData()
            local isSubCard = cardData and cardData.CardId and self._Control:IsSubCard(cardData.CardId) or false
            if isSubCard then
                self._DragBuyTips:Show(DragBuyCardType.SubCard)
                -- Invalid 判定（拖起时算一次，全程恒显）：全场无可装配宿主 → Invalid（TxtSubCardNoneSlot）#M1
                -- 金币不足不在此判（与主卡同，到达可买入位 BuyZone 才显 canComplete=false）
                self._IsSubCardInvalid = not gameControl:HasMountableMasterForSubCard(cardData.CardId)
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
    -- 隐落点高亮（DragEnd 兜底：_ClearDragSession 清 _FocusArea 不派发 FocusChange，FocusChange nil 收不住高亮）#GridHighLight
    if self.GridHighLight then
        self.GridHighLight.gameObject:SetActiveEx(false)
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
    -- 落点高亮（主卡拖拽显、副卡/无效隐；_RefreshDragHighLight 内部全 gating，放最前不受下方 tips 早返影响）#GridHighLight
    self:_RefreshDragHighLight(payload)
    if not self._DragBuyTips then
        return
    end
    local gameControl = self._Control.GameControl
    if gameControl:GetDraggingSourceArea() ~= gameControl.DragArea.Shop then
        return
    end
    local cardData = gameControl:GetDraggingCardData()
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
    if area == gameControl.DragArea.FightArea or area == gameControl.DragArea.Bag then
        if pos and gameControl:CheckDragDropValid() then
            local CardAreaType = XMVCA.XPunishaar.EnumConst.CardAreaType
            local cardArea = area == gameControl.DragArea.FightArea and CardAreaType.FightArea or CardAreaType.Bag
            local hostCard = gameControl:GetMasterCardByAreaPos(cardArea, pos)
            if hostCard then
                local canMount = gameControl:CanMountSubCardOnMaster(cardData.CardId, hostCard)
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

--- 拖拽落点高亮：主卡拖拽时在预测落点格显 GridHighLight，尺寸=卡覆盖的已解锁格部分（裁剪到 gridLimit）。
--- 副卡不显（落宿主不落格）；focus 离开本栏/清空/无效 → 隐。不查占位（位置示意非可放性判定）。#GridHighLight
---@param payload table|nil {Area,Pos} 或 nil（焦点清空）
function XUiPunishaarPanelBagLayoutBase:_RefreshDragHighLight(payload)
    if not self.GridHighLight then
        return
    end
    local gameControl = self._Control.GameControl
    -- 副卡拖拽不显（落宿主主卡、不落格）
    if gameControl:GetIsDraggingSubCard() then
        self.GridHighLight.gameObject:SetActiveEx(false)
        return
    end
    local area = payload and payload.Area
    local pos = payload and payload.Pos
    -- 仅本栏区域 + 有 pos 才显（含原位：拖回原位也显高亮，与其他位置表现一致；
    -- 不用 CheckDragDropValid——它对原位返 false 会致原位不显高亮、表现不一致）#GridHighLight 原位一致
    if area ~= self:_GetDragArea() or not pos then
        self.GridHighLight.gameObject:SetActiveEx(false)
        return
    end
    -- 拖拽卡尺寸（cardId 解析对齐 _OnDragBegin：商品走 CardId、已装备卡走 TemplateId）
    local data = gameControl:GetDraggingCardData()
    local cardId = data and (data.CardId or data.TemplateId) or nil
    local cfg = cardId and self._Control:GetTablePunishaarCard(cardId, true) or nil
    local cardSize = (cfg and cfg.Size) or 1
    local gridLimit = self:_GetGridLimit() or 0
    -- 裁剪到已解锁区 [1, gridLimit]：卡覆盖 [pos, pos+cardSize-1] 与之交集格数（不查占位）
    local validCount = 0
    if pos <= gridLimit then
        validCount = math.min(cardSize, gridLimit - pos + 1)
    end
    if validCount <= 0 then
        -- 整卡落在锁定区（pos > gridLimit）→ 不显
        self.GridHighLight.gameObject:SetActiveEx(false)
        return
    end
    local slot = self:GetSlotByIndex(pos)
    if not slot or XTool.UObjIsNil(slot.Transform) then
        self.GridHighLight.gameObject:SetActiveEx(false)
        return
    end
    local slotTransform = slot.Transform
    local slotSize = slotTransform.sizeDelta
    -- GridHighLight 与 slot 不同 parent（gh 在 PnlHighLightList、slot 在 PanelBagSlotList），local 空间 origin 不一致致 localPosition 偏移；
    -- 改用 world position 对齐（免疫 parent local 空间差异）。两者 pivot 均 (0,0.5) 左中 → slot.position 即左缘+垂直中心，
    -- gh 同 pivot 落此点即重合；多格向右延伸 validCount 格（sizeDelta.x = 格周期×validCount）#GridHighLight world定位
    self.GridHighLight.position = slotTransform.position
    self.GridHighLight.sizeDelta = CS.UnityEngine.Vector2(slotSize.x * validCount, slotSize.y)
    self.GridHighLight.gameObject:SetActiveEx(true)
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
