local XUiPunishaarFightMainPanelStateBase = require("XUi/XUiPunishaar/XUiPunishaarFightMain/CommonUiTemplate/XUiPunishaarFightMainPanelStateBase")
local XUiPunishaarFightMainPanelTopShop = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiPunishaarFightMainPanelTopShop")
local XUiPunishaarFightMainComBottomBag = require("XUi/XUiPunishaar/XUiPunishaarFightMain/UiShop/XUiPunishaarFightMainComBottomBag")

--- 商店状态根节点：持有商品面板(TopShop)和对战区装备面板(BottomBag)，
--- 继承 PanelStateBase（DragRoot 拖拽托管 + BuySuccess 刷新订阅），覆写 _OnBuySuccess=RefreshAll；
--- 展开/折叠（BtnExpand/PanelRopeExpand）为本态专有，自理。
---@class XUiPunishaarFightMainPanelShop : XUiPunishaarFightMainPanelStateBase
---@field PanelTopShop UnityEngine.RectTransform 商品面板挂载根节点
---@field ComBottomBag UnityEngine.RectTransform 对战区装备面板挂载根节点
---@field BtnExpand XUiComponent.XUiButton 展开商店面板（显示 PanelTopShop + 隐藏 PanelRopeExpand）
---@field PanelRopeExpand UnityEngine.GameObject 折叠态绳索节点（TopShop 展开时隐藏，折叠时显示）
local XUiPunishaarFightMainPanelShop = XClass(XUiPunishaarFightMainPanelStateBase, "XUiPunishaarFightMainPanelShop")

function XUiPunishaarFightMainPanelShop:OnStart()
    if self.BtnFight then
        self.BtnFight.gameObject:SetActiveEx(false)
    end

    ---@type XUiPunishaarFightMainPanelTopShop
    self.TopShop  = XUiPunishaarFightMainPanelTopShop.New(self.PanelTopShop, self)
    ---@type XUiPunishaarFightMainComBottomBag
    self.BottomBag = XUiPunishaarFightMainComBottomBag.New(self.ComBottomBag, self)

    self.TopShop:Open()
    self.BottomBag:Open()
    -- 商店栏初始展开态由 TopShop._IsFolded=false 自持（TopShop:OnStart 设）；始终 Open 不 Close，展开/收回靠动画 #商店栏动效
    self._FoldedBySubCardDrag = false  -- 副卡拖拽折叠标志显式初始化（OnEnable 兜底/归位清，靠 nil falsy 亦可，显式更清晰）#副卡拖拽收起展开

    -- 两栏互斥由本父对象统一管理 #70：向下注入回调（子容器只回调通知，不反向访问父方法）
    self.BottomBag:SetBagExclusiveHandler(
        handler(self, self.FoldTopShop),      -- 背包展开前 → 收商店栏
        handler(self, self.ExpandTopShop)     -- 玩家主动收背包后 → 展商店栏
    )
    -- 商店栏折叠键（TopShop 内）同样经注入回调上报，父统一处理
    self.TopShop:SetFoldHandler(handler(self, self.FoldTopShop))

    -- 展开/折叠：初始展开态（TopShop 已 Open），PanelRopeExpand 隐藏
    if self.BtnExpand then
        self.BtnExpand:AddEventListener(handler(self, self._OnBtnExpandClick))
    end
    if self.PanelRopeExpand then
        self.PanelRopeExpand.gameObject:SetActiveEx(false)
    end
end

function XUiPunishaarFightMainPanelShop:OnEnable()
    XUiPunishaarFightMainPanelStateBase.OnEnable(self)  -- BuySuccess/RequestCustody 订阅
    local gc = self._Control.GameControl
    gc:AddEventListener(gc.ShopEventId.PickHostChange, self._OnPickHostChange, self)
    -- 副卡拖拽收起商店栏+展开背包（互斥对称）：拖起副卡 _OnSubCardDragBegin（OpenBag 触发互斥收商店栏），
    -- 归位 DragSettled→CloseBag（互斥展商店栏）；购买走异步 cb=等 cb 展开，取消/无效走同步=松手即展开 #副卡拖拽收起展开
    gc:AddEventListener(gc.DragEventId.SubCardHostHintBegin, self._OnSubCardDragBegin, self)
    gc:AddEventListener(gc.DragEventId.DragSettled, self._OnDragSettled, self)
    -- 进态刷背包红点（商店商品就绪后判背包暂存区可升级卡）#背包红点
    if self.BottomBag then
        self.BottomBag:RefreshBagReddot()
    end
    -- 进入商店+展开态：播展开动效（切态/外部进入都要播一次；TopShop._IsFolded=false 即展开态）#商店栏动效
    if self.TopShop and not self.TopShop:IsFolded() then
        self:_PlayShopAnimEnable()
    end
    -- 兜底恢复：副卡拖拽收起态残留（PanelShop 在异步购买 cb 等待期被切走，cb→DragSettled 收不到致 _FoldedBySubCardDrag 残留），
    -- 重入商店态强制还原（收背包+展商店栏）；正常进入 _FoldedBySubCardDrag=nil 跳过 #副卡拖拽收起展开
    if self._FoldedBySubCardDrag then
        self._FoldedBySubCardDrag = false
        if self.BottomBag then
            self.BottomBag:CloseBag()  -- 互斥展商店栏（幂等，bag 已收也无害）
        end
        if self.TopShop and self.TopShop:IsFolded() then
            self:ExpandTopShop()  -- 兜底展（防 CloseBag 幂等未触 afterCloseCb）
        end
    end
end

function XUiPunishaarFightMainPanelShop:OnDisable()
    XUiPunishaarFightMainPanelStateBase.OnDisable(self)
    local gc = self._Control.GameControl
    gc:RemoveEventListener(gc.ShopEventId.PickHostChange, self._OnPickHostChange, self)
    gc:RemoveEventListener(gc.DragEventId.SubCardHostHintBegin, self._OnSubCardDragBegin, self)
    gc:RemoveEventListener(gc.DragEventId.DragSettled, self._OnDragSettled, self)
end

--- 展开商店栏（TopShop 已始终 Open，只 Refresh + 隐折叠绳索 + 播展开动效）。每次展开都播（含切换/外部进入）。
--- **纯展开语义，不反向收背包**——作为回调注入给 BottomBag（收背包后调），亦供 PickingHost 还原(#69) 复用。
--- 玩家点绳索展开走 _OnBtnExpandClick（那里会先收背包）；两者分开是为语义清晰，
--- 避免同次操作绕一圈重复收展（XUiNode 有 _IsNodeShow 幂等守卫，混用不会失控但难读）。
function XUiPunishaarFightMainPanelShop:ExpandTopShop()
    self:_PlayShopAnimEnable()

    -- 先置展开态再 Refresh（Refresh 收起态早返，须 false 才跑）#副卡拖拽收起展开
    if self.TopShop then
        self.TopShop:SetFolded(false)
        self.TopShop:Refresh()
    end
    if self.PanelRopeExpand then
        self.PanelRopeExpand.gameObject:SetActiveEx(false)
    end
end

--- 收起商店栏（始终 Open 不 Close，靠动画收起 + 显折叠绳索）。幂等：已折叠则只保证绳索显示。
--- 本父对象统一持有折叠态，四方共用：TopShop.BtnFoldUp 上报 / 背包展开前回调(#70) /
---   PickingHost 进入(#69) / 副卡拖拽(SubCardHostHintBegin)。子面板均只上报意图，不自行 Close、不访问父节点。
--- 注：不在此处理 BtnExpand 禁用——常态互斥收起后必须允许再展开，
---   仅 PickingHost 需锁死展开键，故锁键留在 _OnPickHostChange 分支。
function XUiPunishaarFightMainPanelShop:FoldTopShop()
    if self.TopShop and self.TopShop:IsFolded() then
        return
    end
    if self.TopShop then
        self.TopShop:SetFolded(true)
    end
    -- 商店栏始终 Open（不 Close），收回靠动画；CloseAllGrids/Close 注释（#73 根因=TopShop Close 致 grid 挂 inactive 父，现不 Close 根因消失）#商店栏动效
    -- self.TopShop:CloseAllGrids()
    -- self.TopShop:Close()
    if self.PanelRopeExpand then
        self.PanelRopeExpand.gameObject:SetActiveEx(true)
    end
    self:_PlayShopAnimDisable()
end

--- 副卡拖拽开始：收起商店栏 + 展开背包暂存区（经 OpenBag 触发互斥，beforeOpenCb=FoldTopShop 自动收商店栏）。
--- 标 _FoldedBySubCardDrag 供归位时识别仅回滚本路径折叠（不误展玩家互斥/PickHost/BtnFoldUp 折叠 #R3）。#副卡拖拽收起展开
function XUiPunishaarFightMainPanelShop:_OnSubCardDragBegin()
    self._FoldedBySubCardDrag = true
    if self.BottomBag then
        self.BottomBag:OpenBag()  -- 互斥：beforeOpenCb 收商店栏 + 展背包 + 隐 HUD
    end
end

--- 拖拽归位完成（DragSettled）：副卡拖拽收起态下收背包 + 展商店栏（经 CloseBag 触发互斥，afterCloseCb=ExpandTopShop 自动展商店栏）。
--- 购买走异步 cb→归位（等 cb 展开）；取消/无效走同步归位（松手即展开）。仅回滚 _FoldedBySubCardDrag 标记的副卡拖拽折叠，
--- 非副卡拖拽折叠（玩家互斥/PickHost/BtnFoldUp）不回滚避免误展破坏互斥 #R3。#副卡拖拽收起展开
function XUiPunishaarFightMainPanelShop:_OnDragSettled()
    if not self._FoldedBySubCardDrag then
        return
    end
    self._FoldedBySubCardDrag = false
    if self.BottomBag then
        self.BottomBag:CloseBag()  -- 互斥：afterCloseCb 展商店栏 + 收背包 + 恢复 HUD
    end
    if self.TopShop and self.TopShop:IsFolded() then
        self:ExpandTopShop()  -- 兜底展（防 CloseBag 幂等未触 afterCloseCb；IsFolded 守卫防双重 Expand）
    end
end

--- 播商店栏展开动效（FightMain 根 PanelShopAnimEnable，经 gc 事件派发 FightMain 订阅播）#商店栏动效
function XUiPunishaarFightMainPanelShop:_PlayShopAnimEnable()
    local gc = self._Control and self._Control.GameControl
    if gc then
        gc:DispatchEvent(gc.ShopEventId.ShopPanelAnimEnable)
    end
end

--- 播商店栏收起动效（FightMain 根 PanelShopDisable）#商店栏动效
function XUiPunishaarFightMainPanelShop:_PlayShopAnimDisable()
    local gc = self._Control and self._Control.GameControl
    if gc then
        gc:DispatchEvent(gc.ShopEventId.ShopPanelAnimDisable)
    end
end

--- PickHostChange：PickingHost 进入=FightMain 收商店栏（选宿主在弹窗内独立 ComBottomBag，不锁背包/不刷主卡 Disable）；退出=还原 #69
--- 进入时收起动画 cb（FightMain _OnShopPanelAnimDisableDone）→gc:FlushPendingPickHostTip 开弹窗（用户要求动画回调后再开）；
---   已收起态（玩家先开背包互斥折叠后点副卡购买）FoldTopShop 幂等不播动画，直接 flush 兜底防卡不开。#副卡购买收起后开弹窗
function XUiPunishaarFightMainPanelShop:_OnPickHostChange(isPicking)
    if isPicking then
        -- 收商店栏（走公共方法 #70）+ 锁 BtnExpand 防手动展开
        local wasFolded = self.TopShop and self.TopShop:IsFolded()
        self:FoldTopShop()
        if wasFolded then
            -- 已收起态：FoldTopShop 幂等 no-op 不播动画，无 cb 可待，直接 flush 开弹窗
            local gc = self._Control and self._Control.GameControl
            if gc and gc.FlushPendingPickHostTip then
                gc:FlushPendingPickHostTip()
            end
        end
        -- else 未收起：FoldTopShop 播 PanelShopAnimDisable → FightMain 动画 cb → gc:FlushPendingPickHostTip
        if self.BtnExpand then self.BtnExpand:SetDisable(true) end
    else
        -- 还原：展 TopShop（走公共方法 #70）+ 解锁 BtnExpand + 刷新 BottomBag（购买后卡牌变化）#69
        self:ExpandTopShop()
        if self.BottomBag then self.BottomBag:Refresh() end
        if self.BtnExpand then self.BtnExpand:SetDisable(false) end
    end
end

--- BuySuccess 刷新 = 全量刷新（TopShop + BottomBag）。
--- PickingHost 期间 TopShop Close（inactive），不 RefreshAll（避免 inactive 父下子节点 SetActiveEx 报错 #69 / xuinode-active-ancestor-invariant）；
--- ExitPickHost 还原时 _OnPickHostChange(false) 补刷 BottomBag。
function XUiPunishaarFightMainPanelShop:_OnBuySuccess(isFromMasterCardChange)
    local gc = self._Control.GameControl
    if gc and gc:IsPickingHost() then
        return
    end
    self:RefreshAll(isFromMasterCardChange)
end

--- 玩家点绳索展开商店栏：先收背包暂存区（两栏互斥 #70），再展开。
function XUiPunishaarFightMainPanelShop:_OnBtnExpandClick()
    -- 互斥：展商店栏前先收背包（CloseBagIfShow 不回调 AfterBagClose，语义单向）
    if self.BottomBag then
        self.BottomBag:CloseBagIfShow()
    end
    self:ExpandTopShop()
end

--- 全量刷新：商品列表 + 对战区装备列表。
--- 购买/拖拽/卖出操作后由各格子通过 self.Parent.Parent:RefreshAll() 调用至此。
--- TopShop Fold（互斥收起/暂存区展开/PickingHost）时跳过其下 grid 刷新——TopShop:Refresh 内
---   RefreshCustomizedList+grid:Open() 触达 inactive 父下子节点致 activeInHierarchy=false 报错
---  （xuinode-active-ancestor-invariant）。还原时 ExpandTopShop 已含 Refresh 补刷，数据不丢。
function XUiPunishaarFightMainPanelShop:RefreshAll(isFromMasterCardChange)
    -- MASTER_CARD_CHANGE 时跳过商品栏 Refresh（Goods IsBought 可能旧 SetCurrentNode 未调，CanGoodsUpgradeOwnedCard 误判可升级）#升级动画
    if not isFromMasterCardChange and self.TopShop and self.TopShop:IsNodeShow() then
        self.TopShop:Refresh()
    end
    self.BottomBag:Refresh()
    self.BottomBag:RefreshBagLayoutIfShow()
    self.BottomBag:RefreshBagReddot()  -- BuySuccess 后背包卡变更，重判可升级红点 #背包红点
end

return XUiPunishaarFightMainPanelShop
