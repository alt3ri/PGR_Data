--- 卡牌/敌人详情通用 Tips 根面板（气泡壳，继承 XUiCommonBubblePanel）。
--- 挂在 FightMain 的 CardTipsPanelRoot 节点下（全屏 shell，承载 BtnClose 穿透关闭 + 越界修正）。
--- 按展示对象 LoadPrefab 加载对应内容子面板（MainCardTips/SubCard/Enemy，普通 XUiNode，不继承 bubble），
--- 由本壳统一兜：定位（SetPosition 定位加载进来的内容 RectTransform）+ 越界修正 + BtnClose。
--- 同一时刻只显一个内容；切对象先 Close 旧、再 Open 新。壳常驻 Open（空容器无 Graphic 不拦截射线），
--- BtnClose 随内容显隐。
--- TODO: UiPunishaarSubCardTips 与 UiPunishaarEnemyTips 子面板骨架尚未创建。
local XUiCommonBubblePanel = require("XUi/XUiCommon/XUiCommonBubblePanel")

-- 越界修正复用向量（避免高频路径 GC，对齐基类 Vector3ForCal 风格）
local Vector3ForCal = Vector3.zero

--- 内容子面板模块路径（require 用）。Enemy 骨架未建，路径留 nil + TODO。
local TipsModulePath = {
    [1] = "XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/UiPunishaarMainCardTips/XUiPunishaarMainCardTips",
    [2] = "XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/UiPunishaarSubCardTips/XUiPunishaarSubCardTips",
    [3] = "XUi/XUiPunishaar/XUiPunishaarCommonCardDetail/UiPunishaarEnemyTips/XUiPunishaarEnemyTips",
}

--- 主卡详情统一数据契约（ShowMainCard 归一后传给 MainCardTips.Refresh）。
---@class PunishaarMainCardTipsData
---@field cardId number 主卡模板 Id
---@field level number 等级
---@field source number 1=Goods（商品）2=Equipped（装备态主卡）
---@field goodsIndex number|nil 商品槽位 index（source=1）
---@field isBought boolean|nil 已购（source=1）
---@field frozen boolean|nil 冻结（source=1）
---@field masterCard table|nil 装备态主卡原始对象（source=2，含 Id 供 SellCard/DiscardCard）

---@class XUiPanelPunishaarTipsRoot: XUiCommonBubblePanel
---@field protected _Control XPunishaarControl
---@field Parent
---@field BtnClose XUiComponent.XUiButton 全屏穿透关闭按钮（随内容显隐；射线穿透特性由 prefab 配置）
local XUiPanelPunishaarTipsRoot = XClass(XUiCommonBubblePanel, "XUiPanelPunishaarTipsRoot")

function XUiPanelPunishaarTipsRoot:OnStart()
    self._TipsInst = {}
    self._AnchorRoot = {}
    self._CurType = nil
    self._CurData = nil
    self._SubInst = nil   -- 子气泡（副卡详情，主卡内展开 #39）；nil 表示无 sub
    self._SubData = nil
    -- BtnClose 判空：prefab 可能尚未提供。初始隐藏，仅 Show 内容时激活。
    -- 点空白直接 Hide 全关（main+sub 同关，4.8 不分两段式）。
    if self.BtnClose then
        self.BtnClose.gameObject:SetActiveEx(false)
        self.BtnClose:AddEventListener(handler(self, self._OnBtnClose))
    end
end

--- 展示指定类型的内容子面板。幂等短路（同 type 同 data 不重复切换）。
---@param tipsType number XPunishaarEnum.TipsType
---@param data table 内容子面板所需数据
---@param posUi UnityEngine.RectTransform|nil 触发元素（卡牌 grid）的 RectTransform，供气泡定位
function XUiPanelPunishaarTipsRoot:Show(tipsType, data, posUi)
    -- 短路：同卡已开，不重刷 main（sub 不先关避免闪烁；_AutoExpandSub 内 sub 已展则保留/已关则重开）
    if self._CurType == tipsType and self:_IsDetailEqual(self._CurData, data) then
        self:_AutoExpandSub(data)
        return
    end
    -- 切对象：先关 sub（主卡切走/换卡时 sub 不保留 #39）
    if self._SubInst then
        self._SubInst:Close()
        self._SubInst = nil
        self._SubData = nil
    end

    -- 先 Close 旧内容子面板（Close 幂等，nil 安全）
    if self._CurType and self._TipsInst[self._CurType] then
        self._TipsInst[self._CurType]:Close()
    end

    -- 懒加载目标内容（已缓存则复用）
    local inst = self:_LoadTips(tipsType)
    if not inst then
        return
    end

    -- 先 Open 后 Refresh：首次 Open 才触发内容子面板的 OnStart（建 MainCardPanel 等子节点），
    -- 故 Refresh 必须在 Open 之后；复用场景 Open 为 no-op，Refresh 照常刷新。
    inst:Open()
    if inst.Refresh then
        inst:Refresh(data)
    end

    -- 强制内容子面板布局落定：Refresh 内切 PanelBuy/Sell/Discard SetActiveEx + SubCardSlot Open/Close 会 dirty 布局，
    -- Unity 帧末才重建；若不强制，首次打开 SetPosition→PositionBoundsFix 的 GetUIRectWidthHeight 会读到 stale 尺寸致越界修正算错。
    -- 第二次起因实例已缓存、上一帧已布局过而正常，故表现为"首次定位错"。
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(inst.Transform)

    -- 气泡定位：以内容子面板 RectTransform 为定位对象，悬浮于触发卡牌旁 + 越界修正
    self:SetPopupPanelRectTrans(inst.Transform)
    self:_InitViewArea()
    if posUi then
        self:SetPosition(posUi.position, posUi.pivot)
    end

    -- BtnClose 随内容显示激活（点空白即关 + 射线穿透由 prefab 配置）
    if self.BtnClose then
        self.BtnClose.gameObject:SetActiveEx(true)
    end

    self._CurType = tipsType
    self._CurData = data
    -- 4.8：打开主卡 tips 同时展开副卡子气泡（装备态主卡有副卡时；详见 _AutoExpandSub）
    self:_AutoExpandSub(data)
end

--- 展示主卡详情。data 形态二选一：
---   Server.XPunishaarGoods（含 CardId/Level/GoodsIndex/IsBought/Frozen）→ source=1
---   Server.XPunishaarMasterCard（含 TemplateId/Level/Id/StartPos）       → source=2
---@param data table
---@param posUi UnityEngine.RectTransform|nil 触发元素（卡牌 grid）的 RectTransform
function XUiPanelPunishaarTipsRoot:ShowMainCard(data, posUi, readOnly)
    if not data then
        return
    end
    local TipsType = XMVCA.XPunishaar.EnumConst.TipsType
    local detail
    if data.CardId ~= nil then
        detail = {
            cardId = data.CardId,
            level = data.Level,
            source = 1,
            goodsIndex = data.GoodsIndex,
            isBought = data.IsBought,
            frozen = data.Frozen,
            readOnly = readOnly,
        }
    elseif data.TemplateId ~= nil then
        detail = {
            cardId = data.TemplateId,
            level = data.Level,
            source = 2,
            masterCard = data,
            readOnly = readOnly,
        }
    else
        XLog.Warning("[TipsRoot] ShowMainCard: 无法识别的 data 形态，需为 Goods 或 MasterCard")
        return
    end
    self:Show(TipsType.MainCard, detail, posUi)
end

--- 展示副卡详情（主入口，互斥：关旧内容开副卡 #39）。data 形态二选一：
---   Server.XPunishaarGoods（含 CardId/Level/GoodsIndex/IsBought/Frozen）→ source=1（商品态副卡）
---   { subCardId=, level?=, masterCard?= }（经主卡副卡槽点击进入）             → source=2（装备态副卡）
---@param data table
---@param posUi UnityEngine.RectTransform|nil 触发元素（卡牌 grid）的 RectTransform
function XUiPanelPunishaarTipsRoot:ShowSubCard(data, posUi)
    local detail = self:_NormalizeSubCardData(data)
    if not detail then
        return
    end
    self:Show(XMVCA.XPunishaar.EnumConst.TipsType.SubCard, detail, posUi)
end

--- 展示副卡详情（子气泡，不关主卡 #39）：主卡详情内 SubCardSlot 点击展开入口用。
--- 主卡气泡保留，副卡气泡叠加在 posUi（SubCardSlot）旁。BtnClose 点空白直接 Hide 全关（4.8）。
---@param data table 同 ShowSubCard
---@param posUi UnityEngine.RectTransform|nil SubCardSlot 的 RectTransform（副卡气泡定位基准）
function XUiPanelPunishaarTipsRoot:ShowSubCardNested(data, posUi)
    local detail = self:_NormalizeSubCardData(data)
    if not detail then
        return
    end
    -- toggle：同 data sub 已显 → 关闭（点展开入口 toggle off）
    -- 用 _IsDetailEqual 比业务键，勿用 == （detail 每次新建引用不等，详见 _IsDetailEqual 注释）
    if self._SubInst and self:_IsDetailEqual(self._SubData, detail) then
        self:_CloseSub()
        return
    end
    -- 关旧 sub（若不同 data）
    if self._SubInst then
        self._SubInst:Close()
    end
    local inst = self:_LoadTips(XMVCA.XPunishaar.EnumConst.TipsType.SubCard)
    if not inst then
        return
    end
    inst:Open()
    if inst.Refresh then
        inst:Refresh(detail)
    end
    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(inst.Transform)
    self:SetPopupPanelRectTrans(inst.Transform)
    self:_InitViewArea()

    -- 副卡气泡定位到主卡气泡侧（左/右，根据超框决定，默认右 #42）：
    -- 取 main inst（_TipsInst[MainCard]）的 DetailRootLeft/Right，x-flip 选一侧作 posUi。
    -- 复用 #33 模式：main center x vs shell center x，halfMainW band，default right。
    local mainInst = self._CurType and self._TipsInst[self._CurType]
    local subPosUi = self:_PickSubSidePosUi(mainInst, inst, posUi)
    if subPosUi then
        self:SetPosition(subPosUi.position, subPosUi.pivot)
    end

    self._SubInst = inst
    self._SubData = detail
end

--- 自动展开副卡子气泡（4.8：打开主卡 tips 同时展开主卡+副卡）。
--- 仅装备态主卡（detail.source==2）且 masterCard.SubCardId≠0 时展开；副卡已展开且同 data 时保持不动（同卡再点不 toggle-off）。
--- 只读场景（detail.readOnly）压副卡 operationMode=None（不显操作按钮，对齐主卡 readOnly；SubCardTips 经 detail.operationMode 显式覆盖返 None）。
--- SellCardTip 子类（#69 PickingHost）覆写为 no-op——其副卡=待购入 picking sub，由显式 ShowSubCardNested 展开，不走主卡已装备 sub。
---@param data table 主卡 detail 契约（Show 传入）
function XUiPanelPunishaarTipsRoot:_AutoExpandSub(data)
    -- 仅主卡详情触发；副卡/敌人详情无副卡可展
    if self._CurType ~= XMVCA.XPunishaar.EnumConst.TipsType.MainCard then
        return
    end
    if not data or data.source ~= 2 then
        return
    end
    local masterCard = data.masterCard
    if not masterCard or not masterCard.SubCardId or masterCard.SubCardId == 0 then
        return
    end
    local subData = {
        subCardId = masterCard.SubCardId,
        masterCard = masterCard,
    }
    -- 只读场景压副卡 operationMode=None（SubCardTips.OperationMode.None=0），不显 Discard 等操作按钮，对齐主卡 readOnly
    if data.readOnly then
        subData.operationMode = 0
    end
    -- 副卡已展开且同 data：保持不动（同卡再点不 toggle-off）；subData 须归一后比，_SubData 经 _NormalizeSubCardData 存（cardId 键）
    local normSub = self:_NormalizeSubCardData(subData)
    if normSub and self._SubInst and self:_IsDetailEqual(self._SubData, normSub) then
        return
    end
    -- posUi 传 nil：副卡气泡定位靠主卡 DetailRootLeft/Right（_PickSubSidePosUi 内部取，无则回退 nil 不定位）
    self:ShowSubCardNested(subData, nil)
end

--- 选副卡气泡定位锚点（主卡详情的 DetailRootLeft/Right，x-flip，默认右 #42）。
--- 本地坐标系判定（shell 本地中心=0，全像素单位一致）：
---   副卡贴主卡左/右边沿展开后是否超 shell 视区——右展右边沿=mainRightEdge+subW、左展左边沿=mainLeftEdge-subW；
---   右侧放得下→默认右；右侧放不下且左侧放得下→左；两边都放不下→右让 clamp 兜底。
--- #复盘根因：旧版用世界 position.x（mainInst.Transform.position.x / self.Transform.position.x）与本地 sizeDelta 半宽混比，
---   Canvas Scaler 缩放世界坐标（主卡世界 2.6 ↔ 本地 481，比例≈185）致 diff 恒小→永远落默认右→副卡右展超屏 clamp 推回压主卡重叠。
---   前两轮改判定逻辑（band/边沿 fit）仍用世界 position.x，单位都错故无效。改全本地坐标后单位一致。#副卡左右判定
--- 无 main DetailRoots 时回退 posUi（SubCardSlot 坐标）。
---@param mainInst table|nil 主卡详情 inst（_TipsInst[MainCard]）
---@param subInst table|nil 副卡详情 inst（供读副卡宽判侧空间；ShowSubCardNested 传 inst）
---@param fallbackPosUi UnityEngine.RectTransform|nil 回退锚点
---@return UnityEngine.RectTransform|nil
function XUiPanelPunishaarTipsRoot:_PickSubSidePosUi(mainInst, subInst, fallbackPosUi)
    if not mainInst then
        return fallbackPosUi
    end
    local rootLeft = mainInst.DetailRootLeft
    local rootRight = mainInst.DetailRootRight
    if not rootLeft or not rootRight then
        return fallbackPosUi
    end
    -- 全本地坐标系（mainTrans.localPosition 相对 anchor=shell 子 localPos 0 → 相对 shell 本地中心 0）
    local mainTrans = mainInst.Transform
    local mainLocalX = mainTrans.localPosition.x
    local mainPivotX = mainTrans:GetPivot()
    local mainW = mainTrans:GetUIRectWidthHeight()        -- 渲染宽（含 CSF 重建+scale，对齐 clamp panelWidth；避免 sizeDelta stale/CSF-on-root 读 0 致判定退化）#副卡左右判定
    local mainLeftEdge = mainLocalX - mainPivotX * mainW           -- 主卡左边沿本地
    local mainRightEdge = mainLocalX + (1 - mainPivotX) * mainW     -- 主卡右边沿本地
    local halfViewW = (self._ViewWidth or 0) * 0.5
    local shellLeftEdge = -halfViewW
    local shellRightEdge = halfViewW
    local subW = 0
    local subTrans = subInst and subInst.Transform
    if subTrans then
        subW = subTrans:GetUIRectWidthHeight()   -- 同 mainW，渲染宽（避免 sizeDelta CSF stale 读 0 致 rightFit/leftFit 恒 true 退默认右复现旧重叠）
    end
    if mainW <= 0 or subW <= 0 then
        XLog.Warning(string.format("[Punishaar] 副卡左右判定尺寸异常 mainW=%.1f subW=%.1f，判定可能退化（退默认右→clamp 推回压主卡重叠）", mainW, subW))
    end
    -- 右展贴 rootRight（pivot.x=0 从左展向右）：右展后右边沿 = mainRightEdge + subW
    -- 左展贴 rootLeft （pivot.x=1 从右展向左）：左展后左边沿 = mainLeftEdge  - subW
    local rightFit = mainRightEdge + subW <= shellRightEdge
    local leftFit = mainLeftEdge - subW >= shellLeftEdge
    if rightFit then
        return rootRight   -- 右侧放得下：默认右
    elseif leftFit then
        return rootLeft    -- 右侧放不下、左侧放得下：左展
    end
    return rootRight       -- 两边都放不下：右展让 clamp 兜底
end

--- 归一副卡详情数据为 detail 契约。
---@param data table|nil
---@return table|nil
function XUiPanelPunishaarTipsRoot:_NormalizeSubCardData(data)
    if not data then
        return nil
    end
    if data.CardId ~= nil then
        -- 商品态副卡（副卡无 level #43）
        return {
            cardId = data.CardId,
            source = 1,
            goodsIndex = data.GoodsIndex,
            isBought = data.IsBought,
            frozen = data.Frozen,
            operationMode = data.operationMode, -- 透传显式覆盖（#69 坑1：原丢弃致 _ResolveOperationMode 退回 source 兜底）
            masterCard = data.masterCard, -- PickingHost B2 需宿主上下文（BuyPlace/BuyReplace 取 detail.masterCard.Id）#69
        }
    elseif data.subCardId ~= nil then
        -- 装备态副卡（经主卡副卡槽点击，副卡无 level #43）
        -- masterCard 经 SubCardSlot:127 传入（主卡详情内副卡槽点击，宿主主卡上下文）；Place/Replace 需宿主，丢弃需副卡实例 Id
        return {
            cardId = data.subCardId,
            source = 2,
            masterCard = data.masterCard,
            operationMode = data.operationMode, -- 透传显式覆盖（#69 坑1）
        }
    end
    XLog.Warning("[TipsRoot] _NormalizeSubCardData: 无法识别的 data 形态，需为 Goods 或 {subCardId=...}")
    return nil
end

--- 判断两个 detail 契约是否为同一逻辑对象（幂等/toggle 判据）。
--- 不能用 table 引用相等：detail 由 _NormalizeSubCardData 每次新建，引用恒不等 → == 永远 false，
--- 会导致 Show 幂等短路与 ShowSubCardNested toggle-off 分支永不触发（关了重开而非短路/切换）。
--- 比业务键：cardId + source + level +（商品态 goodsIndex / 装备态 masterCard.Id）。
---@param a table|nil
---@param b table|nil
---@return boolean
function XUiPanelPunishaarTipsRoot:_IsDetailEqual(a, b)
    if not a or not b then
        return false
    end
    if a == b then
        return true
    end  -- 同引用/同 number 短路
    -- number 类型（Enemy data=fightId）：不同则不短路（让 Show 刷新）#70
    if type(a) == "number" or type(b) == "number" then
        return false
    end
    if a.cardId ~= b.cardId then
        return false
    end
    -- fightId 比较（Enemy 详情 data 用 fightId；SubCard 无 fightId → 0==0 不影响）#69
    if (a.fightId or 0) ~= (b.fightId or 0) then
        return false
    end
    if a.source ~= b.source then
        return false
    end
    if (a.level or 0) ~= (b.level or 0) then
        return false
    end
    -- operationMode 必入比较键（#69 坑2）：B1(None)⇄B2(BuyPlace/BuyReplace) 同 cardId/source/goodsIndex 仅 mode 不同，
    -- 不比 mode 则 ShowSubCardNested toggle 分支误判"相同"关 sub 而非切换按钮态
    if (a.operationMode or 0) ~= (b.operationMode or 0) then
        return false
    end
    if a.source == 1 then
        -- 商品态：goodsIndex 定位槽位
        if (a.goodsIndex or 0) ~= (b.goodsIndex or 0) then
            return false
        end
    elseif a.source == 2 then
        -- 装备态：masterCard.Id 定位具体主卡实例
        local am = a.masterCard and a.masterCard.Id
        local bm = b.masterCard and b.masterCard.Id
        if am ~= bm then
            return false
        end
    end
    return true
end

--- 展示敌人详情：经 Show 加载 EnemyTips + Refresh(fightId) #69
--- 禁止传临时 ViewModel table，直接传 fightId number #70
---@param fightId number
---@param posUi UnityEngine.RectTransform|nil
function XUiPanelPunishaarTipsRoot:ShowEnemy(fightId, posUi)
    self:Show(XMVCA.XPunishaar.EnumConst.TipsType.Enemy, fightId, posUi)
end

--- 关闭 sub（副卡详情子气泡），main 保留。供 ShowSubCardNested toggle / Hide 共用。
function XUiPanelPunishaarTipsRoot:_CloseSub()
    if self._SubInst then
        self._SubInst:Close()
        self._SubInst = nil
        self._SubData = nil
    end
end

--- 隐藏全部内容子面板（main + sub，不 Destroy 缓存实例，便于下次复用）。
function XUiPanelPunishaarTipsRoot:Hide()
    self:_CloseSub()
    if self._CurType and self._TipsInst[self._CurType] then
        self._TipsInst[self._CurType]:Close()
    end
    self._CurType = nil
    self._CurData = nil
    -- BtnClose 随内容隐藏，避免常驻拦截下层点击
    if self.BtnClose then
        self.BtnClose.gameObject:SetActiveEx(false)
    end
    -- 通知各 grid 隐外发光选中态（Tips 关闭 = 取消选中）
    self._Control:DispatchEvent(self._Control.EventId.CardOutlineDeselect)
end

--- 点空白/BtnClose：直接 Hide 关闭全部（main+sub 同关，4.8 策划定：同时显主+副时点空白一次全关，不分两段式）。
function XUiPanelPunishaarTipsRoot:_OnBtnClose()
    self:Hide()
end

--- 懒初始化越界修正视区。视区 = 壳（CardTipsPanelRoot，全屏=屏幕）尺寸，作浮窗越界修正的边界；
--- 非 内容子面板尺寸（否则 panel==view → clamp 恒居中、修正失效）。壳尺寸恒定，懒测一次。
function XUiPanelPunishaarTipsRoot:_InitViewArea()
    if self._IsInitViewArea then
        return
    end
    self._IsInitViewArea = true
    local width, height = self.Transform:GetUIRectWidthHeight()
    self:SetViewArea(width or 0, height or 0)
end

--- 越界修正（覆写基类 XUiCommonBubblePanel.PositionBoundsFix）。
--- 基类算法用 stale diff（CORRECTION 2 用修正前 leftDownDiff），面板≥视区（两边同轴越界）时两修正抵消、最终仍越界。
--- 改为按轴独立直接 clamp：W≤V 时 clamp 到有效区间 [−halfV+p·W, halfV−(1−p)·W]（一次满足两边，无 stale）；
--- W>V 时无法两边都进 → 居中兜底（(p−0.5)·W，两侧对称溢出最小）。
--- 仅 Punishaar 覆写，待验证后考虑移植基类（基类另有 chat 使用方，本期不动）。
function XUiPanelPunishaarTipsRoot:PositionBoundsFix()
    local pivotX, pivotY = self._PanelRectTrans:GetPivot()
    local panelWidth, panelHeight = self._PanelRectTrans:GetUIRectWidthHeight()
    local panelLocPos = self._PanelRectTrans.localPosition

    local halfViewW = self._ViewWidth * 0.5
    local halfViewH = self._ViewHeight * 0.5

    local newLocX = self:_ClampAxisBound(panelLocPos.x, panelWidth, pivotX, halfViewW, "X")
    local newLocY = self:_ClampAxisBound(panelLocPos.y, panelHeight, pivotY, halfViewH, "Y")

    if newLocX ~= panelLocPos.x or newLocY ~= panelLocPos.y then
        Vector3ForCal.x = newLocX
        Vector3ForCal.y = newLocY
        Vector3ForCal.z = panelLocPos.z
        self._PanelRectTrans.localPosition = Vector3ForCal
    end
end

--- 沿单一轴做越界修正，返回修正后的轴坐标。
---@param loc number 修正前该轴 localPosition 分量
---@param panelSize number 面板沿该轴尺寸
---@param pivot number 该轴 pivot（0~1）
---@param halfView number 视区沿该轴半边长
---@param axisName string "X"/"Y"（warning 用）
---@return number
function XUiPanelPunishaarTipsRoot:_ClampAxisBound(loc, panelSize, pivot, halfView, axisName)
    if panelSize <= halfView * 2 then
        -- 面板 ≤ 视区：有效区间保证左/下沿 ≥ -halfView 且右/上沿 ≤ halfView
        local minLoc = -halfView + pivot * panelSize
        local maxLoc = halfView - (1 - pivot) * panelSize
        local newLoc = math.max(minLoc, math.min(maxLoc, loc))
        if XMain.IsEditorDebug and newLoc ~= loc then
            XLog.Warning(self.__cname .. " 浮窗触发" .. axisName .. "轴越界修正")
        end
        return newLoc
    else
        -- 面板 > 视区：两沿不可能同时满足，居中兜底使两侧溢出对称最小
        -- 面板中心 = loc + (0.5 - pivot)*panelSize，令中心 = 0 → loc = (pivot - 0.5)*panelSize
        local centerLoc = (pivot - 0.5) * panelSize
        if XMain.IsEditorDebug then
            XLog.Warning(self.__cname .. " 浮窗" .. axisName .. "轴面板超过视区，居中兜底")
        end
        return centerLoc
    end
end

--- 懒加载指定类型的内容子面板实例（缓存复用）。失败返回 nil。
---@param tipsType number XPunishaarEnum.TipsType
---@return XUiNode|nil
function XUiPanelPunishaarTipsRoot:_LoadTips(tipsType)
    local inst = self._TipsInst[tipsType]
    if inst then
        return inst
    end

    local path
    local TipsType = XMVCA.XPunishaar.EnumConst.TipsType
    if tipsType == TipsType.MainCard then
        path = self._Control:GetTipsMainCardPrefabPath()
    elseif tipsType == TipsType.SubCard then
        path = self._Control:GetTipsSubCardPrefabPath()
    elseif tipsType == TipsType.Enemy then
        path = self._Control:GetTipsEnemyPrefabPath()
    end
    if string.IsNilOrEmpty(path) then
        XLog.Error("[TipsRoot] _LoadTips: prefab 路径为空 tipsType=" .. tostring(tipsType))
        return nil
    end

    local modulePath = TipsModulePath[tipsType]
    if not modulePath then
        -- SubCard/Enemy 骨架未建时前置拦截（ShowSubCard/ShowEnemy 已 Warning，此处兜底）
        XLog.Error("[TipsRoot] _LoadTips: modulePath 未配置 tipsType=" .. tostring(tipsType))
        return nil
    end

    local anchorGoName = "TipsAnchor_" .. tostring(tipsType)
    local anchorGo = self[anchorGoName]

    if not anchorGo then
        -- per-type anchor GO：每类型 prefab 挂各自 anchor（shell 下子节点），避免同壳 LoadPrefab 不同 url
        -- 销毁旧类型实例（缓存失效 + SubCardSlot 在 MainCardTips 内发起 ShowSubCard 时中途被销毁→MissingReference #38）
        anchorGo = CS.UnityEngine.GameObject('', typeof(CS.UnityEngine.RectTransform))
        anchorGo.transform:SetParent(self.Transform, false)
        anchorGo.transform.localPosition = CS.UnityEngine.Vector3.zero
        anchorGo.transform.localScale = CS.UnityEngine.Vector3.one
        anchorGo.name = anchorGoName
        anchorGo.layer = self.GameObject.layer
    end

    local ui = anchorGo:LoadPrefab(path, false, true)
    XUiHelper.SetCanvasesSortingOrder(anchorGo.transform)

    inst = require(modulePath).New(ui, self)
    self._TipsInst[tipsType] = inst
    self._AnchorRoot[tipsType] = anchorGo
    return inst
end

function XUiPanelPunishaarTipsRoot:OnDisable()
    -- 框架禁用本壳时（FightMain 压栈等）清内容+隐 BtnClose，防 EnableChildNodes 重激活旧内容。
    -- 不调 self:Close（框架已在禁用本壳，且避免递归）；壳本身由框架按 _IsNodeShow 复活（空壳无 Graphic 无害）。
    self:Hide()
end

function XUiPanelPunishaarTipsRoot:OnDestroy()
    self:Hide()
    self._TipsInst = nil
    self._AnchorRoot = nil
end

return XUiPanelPunishaarTipsRoot
