local XUiGridShopCardSlot = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopCardSlot")
local XUiGridShopCard = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiGridShopCard")
local XUiPunishaarPanelBagLayoutBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarPanelBagLayoutBase")
local XUiNodeList = require("XUi/XUiCommon/XUiNodeList")

--- 对战区卡牌-slot 容器基类：持有对战区卡牌列表 + 槽位列表 + 背包暂存区(BagLayout)。
--- 商店态/战前态共用；当前两子类零差异，派生点(_Get* 系列)预留供将来分离时重写。
---@class XUiPunishaarComBottomBagBase : XUiNode
---@field protected _Control XPunishaarControl
---@field BtnBag XUiComponent.XUiButton 展开/收起背包暂存区
---@field PanelBagLayout UnityEngine.RectTransform 背包暂存区根节点（默认隐藏）
---@field PanelBagList UnityEngine.RectTransform 对战区卡牌父节点
---@field GridCard UnityEngine.RectTransform 对战区卡牌模板
---@field PanelBagSlotList UnityEngine.RectTransform 对战区格子父节点
---@field GridSlot UnityEngine.RectTransform 对战区格子模板
local XUiPunishaarComBottomBagBase = XClass(XUiNode, "XUiPunishaarComBottomBagBase")

--region 派生点（hook，子类按需覆写；当前两子类用默认实现）

--- 本容器持有的 BagLayout 类（默认基类；子类分离时覆写指向各自派生类）
function XUiPunishaarComBottomBagBase:_GetBagLayoutClass()
    return XUiPunishaarPanelBagLayoutBase
end

--- 本容器显示的卡牌区域（默认对战区 FightArea；预留分离）
function XUiPunishaarComBottomBagBase:_GetAreaType()
    return XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea
end

--- 本容器对应的拖拽区域（DragArea，栏级反算 handler 匹配源栏/设落点区域用 #批次2）
function XUiPunishaarComBottomBagBase:_GetDragArea()
    return self._Control.GameControl.DragArea.FightArea
end

--- 对战区卡 grid 类（默认 XUiGridShopCard）
function XUiPunishaarComBottomBagBase:_GetGridClass()
    return XUiGridShopCard
end

--- 对战区 slot grid 类（默认 XUiGridShopCardSlot）
function XUiPunishaarComBottomBagBase:_GetSlotGridClass()
    return XUiGridShopCardSlot
end

--- 对战区 slot 解锁上限来源（默认 GetFightAreaGridLimit）
function XUiPunishaarComBottomBagBase:_GetGridLimit()
    return self._Control:GetFightAreaGridLimit()
end

--- 背包暂存区开合的互斥回调（自上而下注入，由父对象统一管理互斥）。
--- 父对象（如商店态 PanelShop）注入后，本容器在开合时机回调通知，自身不知也不碰父对象。
--- 不注入时为 nil，开合行为不变（战前态/基底态无互斥需求，不注入）。
---@param beforeOpenCb function|nil 背包展开前调用（商店态：收商店栏）
---@param afterCloseCb function|nil 玩家主动收起背包后调用（商店态：展商店栏）
function XUiPunishaarComBottomBagBase:SetBagExclusiveHandler(beforeOpenCb, afterCloseCb)
    self._BeforeBagOpenCb = beforeOpenCb
    self._AfterBagCloseCb = afterCloseCb
end

--endregion

function XUiPunishaarComBottomBagBase:OnStart()
    if self.BtnBag then
        self.BtnBag:AddEventListener(handler(self, self._OnBtnBag))
    end
    -- 对战区卡牌/槽位列表容器：模板恒 inactive 仅作克隆源（根治 XUiEffectLayer 特效层级二次叠层），
    -- 内部持 XUiNode 实例替代原 _CardGridDict/_SlotGridDict + _SlotList 手工缓存。
    -- _GetGridClass/_GetSlotGridClass 为派生点，此处经 self 调保证多态。
    ---@type XUiNodeList
    self._CardList = XUiNodeList.New(self.GridCard, self.PanelBagList.transform, self:_GetGridClass(), self)
    ---@type XUiNodeList
    self._SlotList = XUiNodeList.New(self.GridSlot, self.PanelBagSlotList.transform, self:_GetSlotGridClass(), self)
    -- 暂存区默认隐藏：先关 gameObject，避免 New 时因 activeSelf=true 自动 Open 触发刷新
    self.PanelBagLayout.gameObject:SetActiveEx(false)
    self._BagLayout = self:_GetBagLayoutClass().New(self.PanelBagLayout, self)
    self:_RefreshSlots()
    self:_RefreshBtnBagState()
end

--- 刷新 BtnBag 按钮态 + 容量文本：背包展开→Select，收起→Normal；Disable（_BagLocked）优先不覆盖。
--- 容量文本（group 1，格式 占用/总容量 如 1/2）总显（含锁定态）；手动开/关/互斥关/解锁/初始化/卡变更(Refresh)时调。
function XUiPunishaarComBottomBagBase:_RefreshBtnBagState()
    if not self.BtnBag then
        return
    end
    -- 容量文本：走 ClientConfig（BagCapacityText，{0}=占用 {1}=总容量）；配置缺失兜底拼接 used/total #背包容量显示
    local total = self._Control:GetBagGridLimit() or 0
    if not self._BagCapacityList then
        self._BagCapacityList = XTool.XListNew()
    end
    local used = self._Control:FillBagAreaCards(self._BagCapacityList)
    local fmt = self._Control:GetBagCapacityText()
    local capacityText
    if not string.IsNilOrEmpty(fmt) then
        capacityText = XUiHelper.FormatTextEx(fmt, tostring(used), tostring(total))
    else
        capacityText = tostring(used) .. "/" .. tostring(total)
    end
    self.BtnBag:SetNameByGroup(1, capacityText)
    if self._BagLocked then
        return  -- Disable 优先（OpenBagWithLock 管），不切 Select/Normal（容量文本仍显）
    end
    local isShow = self._BagLayout and self._BagLayout:IsNodeShow()
    self.BtnBag:SetButtonState(isShow and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiPunishaarComBottomBagBase:_OnBtnBag()
    -- 锁定态（OpenBagWithLock）：禁手动开关，点击无反应（虽 BtnBag:SetDisable(true) 但点击事件仍触发，须此守卫）#bug4
    if self._BagLocked then
        return
    end
    if self._BagLayout:IsNodeShow() then
        self._BagLayout:Close()
        -- 互斥：背包收起，通知 FightMain 恢复 HUD 显隐（读 GetDisplayHud，未手动关才显）#背包HUD互斥
        local gc = self._Control and self._Control.GameControl
        if gc then gc:DispatchEvent(gc.BagEventId.Close) end
        -- 玩家主动收起后回调父对象（商店态：展开商店栏 #70）
        if self._AfterBagCloseCb then
            self._AfterBagCloseCb()
        end
    else
        -- 展开前回调父对象（商店态：先收商店栏 #70）
        if self._BeforeBagOpenCb then
            self._BeforeBagOpenCb()
        end
        self._BagLayout:Open()
        self._BagLayout:Refresh()
        -- 互斥：背包展开，通知 FightMain 纯遮蔽隐 HUD（不标 DismissHud，收起后可恢复）#背包HUD互斥
        local gc = self._Control and self._Control.GameControl
        if gc then gc:DispatchEvent(gc.BagEventId.Open) end
    end
    self:_RefreshBtnBagState()
end

--- 收起背包暂存区（已收则 no-op）。供父对象在展开商店栏时反向互斥调用 #70
--- 不触发 _AfterBagCloseCb——此路径由父对象主动发起，父自身即将展商店栏，
--- 回调等于同次操作重复展开（XUiNode 有 _IsNodeShow 幂等守卫，不会失控，但语义混乱）。
function XUiPunishaarComBottomBagBase:CloseBagIfShow()
    if self._BagLayout and self._BagLayout:IsNodeShow() then
        self._BagLayout:Close()
        -- 互斥：父对象主动收也恢复 HUD（一致性；切态末 _RefreshGuideTips 兜底防与商店栏冲突）#背包HUD互斥
        local gc = self._Control and self._Control.GameControl
        if gc then gc:DispatchEvent(gc.BagEventId.Close) end
    end
    self:_RefreshBtnBagState()
end

--- 强制显示背包暂存区并禁用收起按钮（奖励放置等需玩家专注背包的场景调用）。
--- 幂等：已锁时不重复操作。配套 UnlockBag 恢复手动开关。#66
function XUiPunishaarComBottomBagBase:OpenBagWithLock()
    if self._BagLayout then
        -- 与手动展开一致回调父对象（商店态收商店栏），避免调用方漏收 #70
        if self._BeforeBagOpenCb then
            self._BeforeBagOpenCb()
        end
        self._BagLayout:Open()
        self._BagLayout:Refresh()
        -- 互斥：强制展开也隐 HUD（与手动展开一致）#背包HUD互斥
        local gc = self._Control and self._Control.GameControl
        if gc then gc:DispatchEvent(gc.BagEventId.Open) end
    end
    if self._BagLocked then
        return
    end
    self._BagLocked = true
    if self.BtnBag then
        self.BtnBag:SetDisable(true)
    end
end

--- 恢复背包收起按钮的手动开关（OpenBagWithLock 的对称解锁）。#66
function XUiPunishaarComBottomBagBase:UnlockBag()
    if not self._BagLocked then
        return
    end
    self._BagLocked = nil
    if self.BtnBag then
        self.BtnBag:SetDisable(false)
    end
    self:_RefreshBtnBagState()
end

--- 防御式刷新暂存区：仅当暂存区处于显示态时才刷新，隐藏时跳过。
function XUiPunishaarComBottomBagBase:RefreshBagLayoutIfShow()
    if self._BagLayout and self._BagLayout:IsNodeShow() then
        self._BagLayout:Refresh()
    end
end

--- 刷新 BtnBag 红点：背包暂存区有卡能被商店商品升级→显红点（提示玩家展开背包查看可升级卡）。
--- 仅商店态由 PanelShop 调用（CanOwnedCardUpgradeByShop 依赖商店商品；非商店态不调）。#背包红点
function XUiPunishaarComBottomBagBase:RefreshBagReddot()
    if not self.BtnBag then
        return
    end
    local gc = self._Control and self._Control.GameControl
    if not gc or not gc.CanOwnedCardUpgradeByShop then
        self.BtnBag:ShowReddot(false)
        return
    end
    if not self._BagReddotList then
        self._BagReddotList = XTool.XListNew()
    end
    local list = self._BagReddotList
    list:Clear()
    local count = self._Control:FillBagAreaCards(list)
    local hasUpgrade = false
    for i = 1, count do
        local card = list:GetValueByIndex(i)
        if card and gc:CanOwnedCardUpgradeByShop(card) then
            hasUpgrade = true
            break
        end
    end
    self.BtnBag:ShowReddot(hasUpgrade)
end

function XUiPunishaarComBottomBagBase:OnEnable()
    -- Enable 时刷新 slot 解锁态（重读 _GetGridLimit，子界面切换/重新进入均刷）
    self:_RefreshSlots()
    -- 副卡宿主选择态：拖起副卡时给"不可作宿主的对战区主卡格"置灰，松手时恢复（OnEnable 订阅 / OnDisable 注销）
    self._Control.GameControl:AddEventListener(self._Control.GameControl.DragEventId.SubCardHostHintBegin, self.OnSubCardHostHintBegin, self)
    self._Control.GameControl:AddEventListener(self._Control.GameControl.DragEventId.SubCardHostHintEnd, self.OnSubCardHostHintEnd, self)
    -- 激活态槽位解锁刷新：服务端经 NotifyPunishaarRewardResult 推 FightAreaGridLimit 奖励时实时刷 slot
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_FIGHT_AREA_GRID_UNLOCK, self._RefreshSlots, self)
    -- 主卡拖拽编排时关 blocksRaycasts 让 Slot 射线穿透报精确格位 #52
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_DRAG_BEGIN, self._OnDragBegin, self)
    XEventManager.AddEventListener(XEventId.EVENT_PUNISHAAR_DRAG_END, self._OnDragEnd, self)
    -- 栏级落点反算注册：handler OnDragging 遍历注册栏做落点反算 #批次2
    self._Control.GameControl:RegisterDragFocusBar(self)
end

function XUiPunishaarComBottomBagBase:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_FIGHT_AREA_GRID_UNLOCK, self._RefreshSlots, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_DRAG_BEGIN, self._OnDragBegin, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PUNISHAAR_DRAG_END, self._OnDragEnd, self)
    self._Control.GameControl:RemoveEventListener(self._Control.GameControl.DragEventId.SubCardHostHintBegin, self.OnSubCardHostHintBegin, self)
    self._Control.GameControl:RemoveEventListener(self._Control.GameControl.DragEventId.SubCardHostHintEnd, self.OnSubCardHostHintEnd, self)
    self._Control.GameControl:UnregisterDragFocusBar(self)
end

--- 拖起副卡：遍历对战区主卡格，不可作宿主的置灰，可作宿主的保持常态。
---@param subCardId number 正在拖拽的副卡模板 Id
function XUiPunishaarComBottomBagBase:OnSubCardHostHintBegin(subCardId)
    if not self._CardList then
        return
    end
    self._CardList:ForEachActive(function(_, grid)
        local card = grid:GetEquippedCard()
        grid:SetDisable(not self._Control.GameControl:CanMountSubCardOnMaster(subCardId, card))
    end)
end

--- 松手：恢复全部对战区主卡格为常态。
function XUiPunishaarComBottomBagBase:OnSubCardHostHintEnd()
    if not self._CardList then
        return
    end
    self._CardList:ForEachActive(function(_, grid)
        grid:SetDisable(false)
    end)
end

--- 主卡拖拽开始：关 blocksRaycasts 让 Slot 射线穿透报精确格位 #52
--- 副卡拖拽（Shop 来源）不关——Card.OnEnter 需收射线作 #36 落点
function XUiPunishaarComBottomBagBase:_OnDragBegin()
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
function XUiPunishaarComBottomBagBase:_OnDragEnd()
    if not self._CardList then
        return
    end
    self._CardList:ForEachActive(function(_, grid)
        grid:SetBlocksRaycasts(true)
    end)
end

function XUiPunishaarComBottomBagBase:OnDestroy()
    self._BeforeBagOpenCb = nil
    self._AfterBagCloseCb = nil
end

--- 核心骨架：刷对战区卡牌列表（按 StartPos 找对应槽位坐标重合；复用 XList 容器，零 per-call GC）。
function XUiPunishaarComBottomBagBase:Refresh()
    if not self._FightAreaCardsList then
        self._FightAreaCardsList = XTool.XListNew()
    end
    local count = self._Control:FillAreaCardsSorted(self:_GetAreaType(), self._FightAreaCardsList)

    self._CardList:Refresh(count, function(index, grid)
        local card = self._FightAreaCardsList:GetValueByIndex(index)
        local cfg = self._Control:GetTablePunishaarCard(card.TemplateId, true)
        local sz = cfg and cfg.Size or 1
        grid:RefreshAsEquipped(card, sz, self.GridSlot)
        grid:EnableDrag(self._Control.GameControl.DragArea.FightArea)
        -- 主卡 grid 自身作落点（副卡拖拽释放于此→装配，解决主卡 Image 拦截 slot listener #36）
        -- 栏级反算接管落点，旧单格 PointEnter 暂注释 #批次2
        -- grid:EnableAsDropZone()
        local slot = self:GetSlotByIndex(card.StartPos)
        if slot then
            grid:RefreshPosition(slot)
        end
    end)
    -- 卡牌变更（买/卖/移动入背包）经 RefreshAll 调本 Refresh，同步刷 BtnBag 容量文本 #背包容量显示
    self:_RefreshBtnBagState()
end

--- 核心骨架：初始化对战区格子，构造位置索引供卡牌坐标重合。
function XUiPunishaarComBottomBagBase:_RefreshSlots()
    local maxCount = XMVCA.XPunishaar:GetClientNumberByKey("EquipCardMaxSlotCount")
    local unlockLimit = self:_GetGridLimit() or maxCount

    self._SlotList:Refresh(maxCount, function(index, grid)
        grid:RefreshUnlockState(index <= unlockLimit, false)
        -- 栏级反算接管落点，旧单格 PointEnter 暂注释 #批次2
        -- grid:EnableAsDropZone(self._Control.GameControl.DragArea.FightArea, index)
    end)
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.PanelBagSlotList.transform)
end

function XUiPunishaarComBottomBagBase:GetSlotByIndex(index)
    return self._SlotList and self._SlotList:GetActive(index)
end

--region 落点反算 slot 射线提供方（handler 逐 slot 几何命中 #落点重构） --------

--- 本容器对应的拖拽区域（DragArea）。
---@return number
function XUiPunishaarComBottomBagBase:GetDragArea()
    return self:_GetDragArea()
end

--- 当前显示中的 slot 数量（handler 遍历逐 slot 射线用）。
---@return number
function XUiPunishaarComBottomBagBase:GetSlotListCount()
    if not self._SlotList then
        return 0
    end
    return self._SlotList:GetActiveCount() or 0
end

--- slot 格周期（slot sizeDelta.x）。slot RT 覆盖完整落点格子（无间隙 → sizeDelta.x=格周期），
--- handler OnBeginDrag 算基准偏移 K=floor(_DragOffsetX/格周期) 用。
---@return number|nil
function XUiPunishaarComBottomBagBase:GetDragSlotWidth()
    local slot1 = self._SlotList and self._SlotList:GetActive(1)
    if not slot1 or XTool.UObjIsNil(slot1.Transform) then
        return nil
    end
    return slot1.Transform.sizeDelta.x
end

--endregion

return XUiPunishaarComBottomBagBase
