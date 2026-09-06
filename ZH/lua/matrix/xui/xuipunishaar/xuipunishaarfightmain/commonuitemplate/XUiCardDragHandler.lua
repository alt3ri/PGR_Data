--- 卡牌假拖拽处理器（Theatre5 范式）：XGoInputHandler 三阶段 + 阈值区分 click/drag + 跟手 +
--- reparent 到 DragRoot（经 RequestCustody 事件）+ blocksRaycasts 放行 + 保底定时器。
--- 组合到 grid（grid 持 self._DragHandler = XUiCardDragHandler.New(self)）。
--- grid 拥有 _DragCardData/_DragArea/_DragSourcePos/_Control/Transform/GameObject，handler 读这些；
--- 拖拽机制状态（_DragInputCom/_DragCanvasGroup/归位快照/保底定时器）由 handler 自管。
--- C 级塌缩：XUiGridShopCard 与 XUiComShopSubCardItem 拖拽模式字节同构（~130 行 × 2），hoist 至此。
---@class XUiCardDragHandler
local XUiCardDragHandler = XClass(nil, "XUiCardDragHandler")

local UNITY = CS.UnityEngine
local Vector2 = UNITY.Vector2
local DRAG_MOVE_LIMIT = 20
local Vector3Cache = UNITY.Vector3.zero

---@param host XUiGridShopCard|XUiComShopSubCardItem 持有者
function XUiCardDragHandler:Ctor(host)
    self._Host = host
end

--- 开启拖拽能力（幂等：init 一次）。dragArea 由 host 自管（host._DragArea，drop zone 亦读），handler 不存。
function XUiCardDragHandler:Enable()
    if self._DragInited then
        return
    end
    self._DragInited = true

    local host = self._Host
    self._DragContainerTrans = host.Transform.parent
    self._DragDefaultLocalPos = host.Transform.localPosition
    self._DragDefaultSibling = host.Transform:GetSiblingIndex()

    self._DragInputCom = host.GameObject:GetComponent(typeof(CS.XGoInputHandler))
    if XTool.UObjIsNil(self._DragInputCom) then
        self._DragInputCom = host.GameObject:AddComponent(typeof(CS.XGoInputHandler))
    end
    self._DragInputCom:AddBeginDragListener(handler(self, self.OnBeginDrag))
    self._DragInputCom:AddDragListener(handler(self, self.OnDragging))
    self._DragInputCom:AddEndDragListener(handler(self, self.OnEndDrag))

    self._DragCanvasGroup = host.GameObject:GetComponent(typeof(UNITY.CanvasGroup))
    if XTool.UObjIsNil(self._DragCanvasGroup) then
        self._DragCanvasGroup = host.GameObject:AddComponent(typeof(UNITY.CanvasGroup))
    end
end

--- toggle XGoInputHandler.enabled（副卡商品禁用 grid 拖拽用）。
---@param value boolean
function XUiCardDragHandler:SetEnabled(value)
    if self._DragInputCom then
        self._DragInputCom.enabled = value
    end
end

--- 重置归位快照（host RefreshPosition 调，SetPosition 改 localPosition 后同步，防拖拽后归错位）。
function XUiCardDragHandler:UpdateSnapshot()
    local host = self._Host
    self._DragContainerTrans = host.Transform.parent
    self._DragDefaultLocalPos = host.Transform.localPosition
    self._DragDefaultSibling = host.Transform:GetSiblingIndex()
end

---@param value boolean
function XUiCardDragHandler:SetBlocksRaycasts(value)
    if self._DragCanvasGroup then
        self._DragCanvasGroup.blocksRaycasts = value
    end
end

function XUiCardDragHandler:OnBeginDrag(eventData)
    self._DragBeginScreenPos = eventData.position
    self._IsDragging = false
    -- 按住点跟手 offset：光标本地 - 卡牌本地（原 parent 空间；reparent 后通用因相对偏移与 parent 原点无关、同 canvas 同尺度）#跟手
    local parent = self._Host.Transform.parent
    local ok, point = UNITY.RectTransformUtility.ScreenPointToLocalPointInRectangle(parent, eventData.position, CS.XUiManager.Instance.UiCamera)
    if ok then
        local cardLocal = self._Host.Transform.localPosition
        self._DragOffsetX = point.x - cardLocal.x
        self._DragOffsetY = point.y - cardLocal.y
    else
        self._DragOffsetX = 0
        self._DragOffsetY = 0
    end
    -- 缓存拖拽基准偏移 K #落点重构：源栏 slot sizeDelta.x 作格周期，K=floor(_DragOffsetX/周期)。
    -- OnBeginDrag 即真拖拽起点（Unity 阈值后触发），卡牌尚在原位、指针在源栏内。
    self:_CacheDragBaseline(eventData)
end

function XUiCardDragHandler:OnDragging(eventData)
    if not self:_CheckCanDrag(eventData) then
        return
    end
    self:_ScreenToLocal(eventData)  -- 填 Vector3Cache（光标在当前 parent 本地）
    Vector3Cache.x = Vector3Cache.x - (self._DragOffsetX or 0)  -- 按住点跟手：光标钉按下时相对卡牌的位置 #跟手
    Vector3Cache.y = Vector3Cache.y - (self._DragOffsetY or 0)
    self._Host.Transform.localPosition = Vector3Cache
    -- 栏级落点反算 + 防抖 + 转发栏容器
    self:_RecomputeFocus(eventData)
end

function XUiCardDragHandler:OnEndDrag(eventData)
    self:_StopDragErrorTimer()
    -- 清拖拽基准字段 #落点重构（无论是否真拖拽均清，防 OnBeginDrag 缓存残留）
    self:_ClearDragBaseline()
    if self._DragCanvasGroup then
        self._DragCanvasGroup.blocksRaycasts = true
    end
    if not self._IsDragging then
        return
    end
    self._IsDragging = false
    self:_RemoveAppPauseListener()

    local host = self._Host
    local handled = host._Control.GameControl:EndDragCard(handler(self, self._OnDragEndCallback))
    if not handled then
        self:_OnDragEndCallback(false)
    end
end

function XUiCardDragHandler:_OnDragEndCallback(success)
    self:_RestorePosition()
end

--region 落点反算（slot 射线 + G 基准左对齐 #落点重构） -------------------

--- 缓存拖拽基准偏移 K（OnBeginDrag 调）。K = floor(光标相对卡牌左缘位移 / slotWidth)，
--- 即按下时光标位于卡牌左缘右数第几格。OnDragging 中 focusSlot = S - K（S=光标命中 slot），
--- 实现多格卡左对齐（卡牌左缘落 focusSlot）；单格卡 K=0 → focusSlot=S。
--- slotWidth 取源栏 slot sizeDelta.x（slot RT 覆盖完整落点格子、无间隙 → sizeDelta.x=格周期）。
--- pivot.x=0：_DragOffsetX 即「光标 - 卡牌左缘」在源栏 parent 空间位移（卡牌/槽位 parent 坐标对齐，复用跟手 offset）。
--- Shop 无源栏（不在商店栏算 K）→ K=0，落点取命中 slot 直读。
---@param eventData table
function XUiCardDragHandler:_CacheDragBaseline(eventData)
    self._DragBaselineK = 0
    self._LastFocusPos = nil
    local gc = self._Host._Control.GameControl
    if not gc or not gc.GetDragFocusBars then
        return
    end
    local bars = gc:GetDragFocusBars()
    if not bars then
        return
    end
    -- 源栏 = 注册栏中 DragArea==host._DragArea 者；取其 slot 格周期
    local srcArea = self._Host._DragArea
    local slotWidth
    for i = 1, #bars do
        local bar = bars[i]
        if bar:GetDragArea() == srcArea then
            slotWidth = bar.GetDragSlotWidth and bar:GetDragSlotWidth()
            break
        end
    end
    if slotWidth and slotWidth > 0 and self._DragOffsetX then
        self._DragBaselineK = math.floor(self._DragOffsetX / slotWidth)
    end
end

--- 清空拖拽基准字段（OnEndDrag/CancelDrag 调，防会话残留；OnBeginDrag 会被 _CacheDragBaseline 重置）。
function XUiCardDragHandler:_ClearDragBaseline()
    self._DragBaselineK = nil
    self._LastFocusPos = nil
    self._DragOffsetX = nil  -- 按住点跟手 offset 清理（防下次拖拽残留）#跟手
    self._DragOffsetY = nil
end

--- 落点反算：遍历注册栏，每栏逐 slot RectTransformUtility.RectangleContainsScreenPoint 几何命中，
--- 命中 slot S → focusSlot = S - K（K=OnBeginDrag 缓存基准偏移，多格卡左对齐）。
--- 间隙不命中 → 无栏命中 → 仅清栏区域焦点（不清卖出区 SellZone，其 OnExit 自管 #批次2）。
--- 注入式：handler 经 gc:GetDragFocusBars() 取栏遍历 slot，不直读 host.Parent（向上铁律）。
---@param eventData table
function XUiCardDragHandler:_RecomputeFocus(eventData)
    local gc = self._Host._Control.GameControl
    local bars = gc and gc.GetDragFocusBars and gc:GetDragFocusBars() or nil
    if not bars then
        return
    end
    local uiCamera = CS.XUiManager.Instance.UiCamera
    -- 逐 slot 几何命中：找光标所在 slot（S=1-based 格号）+ 栏归属
    local hitBar, hitSlot
    for i = 1, #bars do
        local bar = bars[i]
        local count = bar.GetSlotListCount and bar:GetSlotListCount() or 0
        for j = 1, count do
            local slot = bar.GetSlotByIndex and bar:GetSlotByIndex(j)
            if slot and not XTool.UObjIsNil(slot.Transform)
                and UNITY.RectTransformUtility.RectangleContainsScreenPoint(
                        slot.Transform, eventData.position, uiCamera) then
                hitBar, hitSlot = bar, j
                break
            end
        end
        if hitBar then
            break
        end
    end
    if not hitBar then
        -- 无栏命中：仅清栏区域焦点，不清 SellZone 焦点（卖出区未接入栏反算，其 OnExit 自管）
        local curArea = gc:GetDragFocusArea()
        if curArea == gc.DragArea.FightArea or curArea == gc.DragArea.Bag then
            gc:ClearDragFocusTarget()
        end
        self._LastFocusPos = nil
        return
    end
    -- G 基准左对齐：focusSlot = S - K（K=按下时光标距卡牌左缘的格数；单格 K=0 → focusSlot=S）
    local focusSlot = hitSlot - (self._DragBaselineK or 0)
    -- clamp gridLimit（unlockLimit 解锁上限，防 focusSlot 越界；maxCount 含锁定格不拦 #跨栏 off-by-one）
    local barArea = hitBar:GetDragArea()
    local cardArea = (barArea == gc.DragArea.FightArea)
        and XMVCA.XPunishaar.EnumConst.CardAreaType.FightArea
        or XMVCA.XPunishaar.EnumConst.CardAreaType.Bag
    local gridLimit = gc:_GetAreaGridLimit(cardArea) or 0
    if gridLimit > 0 then
        if focusSlot < 1 then
            focusSlot = 1
        elseif focusSlot > gridLimit then
            focusSlot = gridLimit
        end
    end
    -- 防抖：槽位/区域不变且焦点未被外部清空才跳过（防卖出区 OnExit 清空后误判不重设）
    if focusSlot == self._LastFocusPos and barArea == gc:GetDragFocusArea()
        and gc:GetDragFocusArea() ~= nil then
        return
    end
    self._LastFocusPos = focusSlot
    -- 临时日志：聚焦槽位 + 偏左/右（测后移除 #调试；cardArea 复用 clamp 段转换）
    local B = gc.GetMasterCardByAreaPos and gc:GetMasterCardByAreaPos(cardArea, focusSlot)
    if B then
        local bCfg = gc.GetTablePunishaarCard and gc:GetTablePunishaarCard(B.TemplateId, true)
        local bSize = (bCfg and bCfg.Size) or 1
        local side = (focusSlot * 2 > B.StartPos * 2 + bSize - 1) and "偏右后插" or "偏左前插"
        XLog.Debug("[DragTrace] focus=" .. focusSlot .. " B@" .. B.StartPos .. "+size" .. bSize .. " " .. side)
    else
        XLog.Debug("[DragTrace] focus=" .. focusSlot .. " 空格无B")
    end
    gc:SetDragFocusTarget(barArea, focusSlot)
end

--endregion

function XUiCardDragHandler:_CheckCanDrag(eventData)
    if self._IsDragging then
        return true
    end
    local host = self._Host
    if not host._DragArea then
        return false
    end
    -- 已购商品拒拖拽：点击侧 BtnClick 已按 goods.IsBought 置灰（XUiGridShopCard:216），
    -- 拖拽侧对称补拦截，避免“点击拦、拖拽放”的不对称。非商品卡 IsBought=nil 不触发。#R7
    if host._DragCardData and host._DragCardData.IsBought then
        return false
    end
    if host._Control.GameControl:GetIsDraggingCard() then
        return false
    end
    if Vector2.Distance(self._DragBeginScreenPos, eventData.position) <= DRAG_MOVE_LIMIT then
        return false
    end

    self._IsDragging = true
    if self._DragCanvasGroup then
        self._DragCanvasGroup.blocksRaycasts = false
    end
    -- 兜底先就位再移走节点：reparent/BeginDragCard 之后若抛错，已注册的定时器与 PAUSE 监听仍能把节点归位；
    -- 反序（先移走再注册）时一旦中间抛错，节点已在 DragRoot 却无任何兜底守着，将永久滞留。
    self:_StartDragErrorTimer()
    -- app 切后台监听（仅活跃拖拽期间，结束/销毁即注销，对齐 Theatre5 :208）
    XEventManager.AddEventListener(XEventId.EVENT_APPLICATION_PAUSE, self.OnApplicationPause, self)
    self:_ReparentToDragRoot()
    host._Control.GameControl:BeginDragCard(host._DragCardData, host._DragArea, host._DragSourcePos)
    return true
end

function XUiCardDragHandler:_ScreenToLocal(eventData)
    local parent = self._Host.Transform.parent
    local ok, point = UNITY.RectTransformUtility.ScreenPointToLocalPointInRectangle(
            parent, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not ok then
        Vector3Cache.x, Vector3Cache.y, Vector3Cache.z = -99999, -99999, 0
        return Vector3Cache
    end
    Vector3Cache.x, Vector3Cache.y, Vector3Cache.z = point.x, point.y, 0
    return Vector3Cache
end

--- 请求把自己托管到高层拖拽层（依赖倒置：grid 不知顶层结构，只派发请求）。
function XUiCardDragHandler:_ReparentToDragRoot()
    local host = self._Host
    host._Control.GameControl:DispatchEvent(host._Control.GameControl.DragEventId.RequestCustody, host)
end

function XUiCardDragHandler:_RestorePosition()
    local host = self._Host
    if self._DragContainerTrans then
        host.Transform:SetParent(self._DragContainerTrans, false)
    end
    if self._DragDefaultLocalPos then
        host.Transform.localPosition = self._DragDefaultLocalPos
    end
    if self._DragDefaultSibling then
        host.Transform:SetSiblingIndex(self._DragDefaultSibling)
    end
end

function XUiCardDragHandler:_StartDragErrorTimer()
    self:_StopDragErrorTimer()
    -- 秒级保底（对齐 Theatre5 BattleShop:78）：异常路径事件丢失兜底归位，非每帧热路径；
    -- 拖拽期间每秒检测一次抬手，mouseup 后最多 1s 归位（正常 OnEndDrag 即时归位不受影响）。#R9
    self._DragErrorTimerId = XScheduleManager.ScheduleForever(handler(self, self._OnDragErrorCheck), XScheduleManager.SECOND)
end

function XUiCardDragHandler:_StopDragErrorTimer()
    if self._DragErrorTimerId then
        XScheduleManager.UnSchedule(self._DragErrorTimerId)
        self._DragErrorTimerId = nil
    end
end

function XUiCardDragHandler:_OnDragErrorCheck()
    if not self._IsDragging then
        self:_StopDragErrorTimer()
        return
    end
    local up = UNITY.Input.GetMouseButtonUp(0)
            or (UNITY.Input.touchCount > 0 and UNITY.Input.GetTouch(0).phase == UNITY.TouchPhase.Ended)
    if up then
        self:OnEndDrag(nil)
    end
end

--- app 切后台：拖拽输入事件丢失，强制结束（归位+清会话，绕过操作路由，对齐 Theatre5 OnApplicationPauseEvent :248）。
--- Layer 1 保底定时器不覆盖此场景（后台无输入 → GetMouseButtonUp 返回 false → 检查空转、拖拽卡死）。
---@param isPause boolean
function XUiCardDragHandler:OnApplicationPause(isPause)
    self:CancelDragIfDragging()
end

--- 强制中断拖拽并归位（幂等：未在拖拽时 no-op）。
--- 三处共用：app 切后台 / host 节点被隐藏（OnDisable）/ host 销毁（OnDestroy）。
--- 归位 + 停定时器 + 恢复射线 + 清逻辑层会话（派发 DRAG_END 让各面板恢复 blocksRaycasts 与副卡置灰）。
function XUiCardDragHandler:CancelDragIfDragging()
    if not self._IsDragging then
        return
    end
    self._IsDragging = false
    self:_StopDragErrorTimer()
    self:SetBlocksRaycasts(true)
    self:_RestorePosition()
    -- 清拖拽基准字段 #落点重构
    self:_ClearDragBaseline()
    -- 清逻辑层拖拽会话 + 派发 DRAG_END（让 PanelBagLayoutBase._OnDragEnd 恢复 bag grids blocksRaycasts + 副卡置灰恢复）
    self._Host._Control.GameControl:CancelDrag()
    self:_RemoveAppPauseListener()
end

function XUiCardDragHandler:_RemoveAppPauseListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_APPLICATION_PAUSE, self.OnApplicationPause, self)
end

function XUiCardDragHandler:OnDestroy()
    -- 销毁时若仍在拖拽：先归位并清逻辑层会话，防节点滞留 DragRoot + 会话残留致后续拖拽被 GetIsDraggingCard 拒
    self:CancelDragIfDragging()
    self:_StopDragErrorTimer()
    self:_RemoveAppPauseListener()
end

return XUiCardDragHandler
