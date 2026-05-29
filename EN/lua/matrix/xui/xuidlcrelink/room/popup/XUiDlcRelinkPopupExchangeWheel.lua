local XUiGridDlcRelinkExchangeWheelEmoji = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkExchangeWheelEmoji")
local XUiPanelLongPressProgress = require("XUi/XUiDlcRelink/Common/XUiPanelLongPressProgress")
---@class XUiDlcRelinkPopupExchangeWheel : XLuaUi
---@field private _Control XDlcRelinkControl
---@field BtnTab XUiButtonGroup
local XUiDlcRelinkPopupExchangeWheel = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupExchangeWheel")

local DraggingFromType = {
    List = 1, -- 从列表拖出
    Wheel = 2, -- 从轮盘拖出
}

function XUiDlcRelinkPopupExchangeWheel:OnAwake()
    self.GridEmoji.gameObject:SetActiveEx(false)
    self.GridEmoji2.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()

    -- 拖拽状态变量
    self.Dragging = false               -- 是否正在拖拽
    self.DraggingEmojiId = nil          -- 正在拖拽的表情ID
    self.DraggingFrom = nil             -- DraggingFromType.List | DraggingFromType.Wheel
    self.DraggingFromIndex = nil        -- 若来自轮盘记录槽位
    ---@type XUiGridDlcRelinkExchangeWheelEmoji
    self.DragCloneGrid = nil            -- 拖拽中的克隆格子
    self.HoverWheelIndex = nil          -- 当前悬停的轮盘槽位
    self.HoverInList = false            -- 是否悬停在左侧列表区域

    -- 点击选择状态变量
    self.ClickSelectFrom = nil          -- DraggingFromType.List | DraggingFromType.Wheel
    self.ClickSelectEmojiId = nil       -- 当前点击选择的表情ID
    self.ClickSelectWheelIndex = nil    -- 若来自轮盘则记录槽位

    -- 交换面板打开时禁止拖拽
    self.DragLocked = false

    -- 长按状态变量
    ---@type XUiGridDlcRelinkExchangeWheelEmoji
    self.PressingGrid = nil             -- 当前正在长按交互的Grid引用
    self.IsPressing = false             -- 是否正在长按加载进度
    self.DragTriggered = false          -- 是否已触发拖拽
    self.PressCancelled = false         -- 本次按压是否已取消长按

    self._screenVec2 = CS.UnityEngine.Vector2(0, 0)
    self._dragVec2 = CS.UnityEngine.Vector2(0, 0)
    self._hideVec2 = CS.UnityEngine.Vector2(-99999, -99999)

    if self.PanelEmojiList then
        -- 列表区域hover监听，用于判断拖拽释放位置
        self:AddPointerEnterExitClick(self.PanelEmojiList.gameObject, handler(self, self.OnPointerEnterList), handler(self, self.OnPointerExitList), handler(self, self.OnPointerClickList))
        ---@type UnityEngine.UI.ScrollRect
        self.EmojiListScrollRect = self.PanelEmojiList.transform:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
    end
end

function XUiDlcRelinkPopupExchangeWheel:OnStart()
    self:InitBtnTab()
    self:InitDynamicTable()
    self.CurSelectIndex = 2
    ---@type XUiGridDlcRelinkExchangeWheelEmoji[]
    self.EmojiGridList = {}
    -- 缓存ImgSelect引用，避免频繁调用Find
    self.ImgSelectList = {}

    -- 轮盘最大槽位数
    self.MaxEmojiWheelCount = self._Control:GetActivityEmojiWheelMaxCount()
    -- 读取初始轮盘数据到临时编辑副本
    self.TempEmojiWheelIds = {}
    local origin = self._Control:GetEmojiWheelIds()
    for i = 1, self.MaxEmojiWheelCount do
        self.TempEmojiWheelIds[i] = origin[i] or 0
    end
end

function XUiDlcRelinkPopupExchangeWheel:OnEnable()
    self.BtnTab:SelectIndex(self.CurSelectIndex)
    self:RefreshPanelWheel()
end

function XUiDlcRelinkPopupExchangeWheel:OnDestroy()
    self:StopDragTracking()
    self:ClearPressState()
end

-- 进入/离开/点击监听绑定
function XUiDlcRelinkPopupExchangeWheel:AddPointerEnterExitClick(go, onEnter, onExit, onClick)
    if not go then
        return
    end
    ---@type XUguiPointerEventListener
    local listener = go:GetComponent(typeof(CS.XUguiPointerEventListener))
    if XTool.UObjIsNil(listener) then
        listener = go:AddComponent(typeof(CS.XUguiPointerEventListener))
    end
    if onEnter then
        listener.OnEnter = onEnter
    end
    if onExit then
        listener.OnExit = onExit
    end
    if onClick then
        listener.OnClick = onClick
    end
    return listener
end

function XUiDlcRelinkPopupExchangeWheel:InitBtnTab()
    local btnTabList = { self.Tab1, self.Tab2 }
    self.BtnTab:Init(btnTabList, handler(self, self.OnBtnTabClick))
end

function XUiDlcRelinkPopupExchangeWheel:OnBtnTabClick(index)
    self.CurSelectIndex = index
    self:SetupDynamicTable()
end

function XUiDlcRelinkPopupExchangeWheel:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEmojiList)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkExchangeWheelEmoji, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkPopupExchangeWheel:SetupDynamicTable()
    self.TextEmojiIdList = self._Control:GetEmojiWheelIdsByType(self.CurSelectIndex)
    local isEmpty = XTool.IsTableEmpty(self.TextEmojiIdList)
    self.None.gameObject:SetActiveEx(isEmpty)
    self.PanelDelete.gameObject:SetActiveEx(false)
    if isEmpty then
        self.DynamicTable:Clear()
        return
    end

    self.DynamicTable:SetDataSource(self.TextEmojiIdList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridDlcRelinkExchangeWheelEmoji
function XUiDlcRelinkPopupExchangeWheel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local emojiId = self.TextEmojiIdList[index]
        grid:Refresh(emojiId)
        -- 标记是否使用中（在轮盘上）
        local used = self:IsUsed(emojiId)
        grid:SetTag(used)
        -- 左侧选中
        local isSelect = self.ClickSelectFrom == DraggingFromType.List and self.ClickSelectEmojiId == emojiId
        grid:SetSelect(isSelect)
    end
end

function XUiDlcRelinkPopupExchangeWheel:IsUsed(emojiId)
    if not XTool.IsNumberValid(emojiId) then
        return false
    end
    for _, id in ipairs(self.TempEmojiWheelIds) do
        if id == emojiId then
            return true
        end
    end
    return false
end

function XUiDlcRelinkPopupExchangeWheel:RefreshPanelWheel()
    for i = 1, self.MaxEmojiWheelCount do
        local grid = self.EmojiGridList[i]
        if not grid then
            local parent = self[string.format("GridEmoji0%s", i)]
            if not parent then
                XLog.Error("XUiDlcRelinkPopupExchangeWheel:RefreshPanelWheel error: not find parent for emoji grid, index:" .. i)
                return
            end
            -- 槽位hover监听
            self:AddPointerEnterExitClick(parent.gameObject, function() self:OnPointerEnterWheel(i) end, function() self:OnPointerExitWheel(i) end)
            self.ImgSelectList[i] = self[string.format("ImgSelect0%s", i)]
            -- 实例化格子
            local go = XUiHelper.Instantiate(self.GridEmoji2, parent)
            grid = XUiGridDlcRelinkExchangeWheelEmoji.New(go, self)
            self.EmojiGridList[i] = grid
        end
        grid:Open()
        local emojiId = self.TempEmojiWheelIds[i] or 0
        grid:Refresh(emojiId)
        grid:SetIsWheelSlot(true)
        grid:SetWheelIndex(i)
    end
    self:UpdateWheelSelectState()
end

--region 轮盘状态刷新

-- 刷新轮盘选中状态
function XUiDlcRelinkPopupExchangeWheel:UpdateWheelSelectState()
    for i, grid in ipairs(self.EmojiGridList) do
        if grid then
            local isClickSelected = self.ClickSelectFrom == DraggingFromType.Wheel and self.ClickSelectWheelIndex == i
            grid:SetSelect(isClickSelected)
        end
    end
end

-- 刷新轮盘选择状态
function XUiDlcRelinkPopupExchangeWheel:UpdateWheelSelectableState(emojiId)
    local isValid = XTool.IsNumberValid(emojiId)
    for i, grid in ipairs(self.EmojiGridList) do
        if grid then
            local isCanSelect = isValid and grid:GetEmojiId() == emojiId
            local imgSelect = self.ImgSelectList[i]
            if imgSelect then
                imgSelect.gameObject:SetActiveEx(isCanSelect)
            end
        end
    end
end

-- 刷新轮盘悬停状态
function XUiDlcRelinkPopupExchangeWheel:UpdateWheelHoverState()
    local hoverIndex = self.Dragging and self.HoverWheelIndex or 0
    for i, grid in ipairs(self.EmojiGridList) do
        if grid then
            local imgSelect = self.ImgSelectList[i]
            if imgSelect then
                imgSelect.gameObject:SetActiveEx(hoverIndex == i)
            end
        end
    end
end

--endregion

--region 监听

function XUiDlcRelinkPopupExchangeWheel:OnPointerEnterList()
    if not self.Dragging then
        return
    end
    self.HoverInList = true
    if self.DraggingFrom == DraggingFromType.List then
        return
    end
    self.PanelDelete.gameObject:SetActiveEx(true)
end

function XUiDlcRelinkPopupExchangeWheel:OnPointerExitList()
    if not self.Dragging then
        return
    end
    self.HoverInList = false
    if self.DraggingFrom == DraggingFromType.List then
        return
    end
    self.PanelDelete.gameObject:SetActiveEx(false)
end

function XUiDlcRelinkPopupExchangeWheel:OnPointerClickList()
    if self.Dragging then
        return
    end
    if XTool.IsNumberValid(self.ClickSelectEmojiId) then
        self:ExitSelectionMode()
    end
end

function XUiDlcRelinkPopupExchangeWheel:OnPointerEnterWheel(index)
    if not self.Dragging then
        return
    end
    self.HoverWheelIndex = index
    self:UpdateWheelHoverState()
end

function XUiDlcRelinkPopupExchangeWheel:OnPointerExitWheel(index)
    if not self.Dragging then
        return
    end
    if self.HoverWheelIndex == index then
        self.HoverWheelIndex = nil
        self:UpdateWheelHoverState()
    end
end

--endregion

--region 拖拽逻辑
---@param grid XUiGridDlcRelinkExchangeWheelEmoji
function XUiDlcRelinkPopupExchangeWheel:StartDrag(grid)
    if self.Dragging or self.DragLocked then
        return
    end
    local emojiId = grid and grid:GetEmojiId() or 0
    if not XTool.IsNumberValid(emojiId) then
        return
    end

    self.Dragging = true
    self.DraggingEmojiId = emojiId
    local isWheelSlot = grid:GetIsWheelSlot()
    self.DraggingFrom = isWheelSlot and DraggingFromType.Wheel or DraggingFromType.List
    self.DraggingFromIndex = isWheelSlot and grid:GetWheelIndex() or nil

    ---@type XUiGridDlcRelinkExchangeWheelEmoji
    local dragGrid = self.DragCloneGrid
    if not dragGrid then
        local go = XUiHelper.Instantiate(self.GridEmoji, self.PanelInfo)
        dragGrid = XUiGridDlcRelinkExchangeWheelEmoji.New(go, self)
        self.DragCloneGrid = dragGrid
    end
    dragGrid:Open()
    dragGrid:SetIsDragClone(true)
    dragGrid:SetOnDrag(true)
    dragGrid:Refresh(emojiId)
    -- 提升拖拽格子层级
    local order = self:GetExchangeBaseOrder() + 5
    dragGrid:SetOverrideSorting(true)
    dragGrid:SetLayerOrder(order)
    -- 禁用拖拽格子射线检测
    ---@type UnityEngine.CanvasGroup
    local canvasGroup = dragGrid.GameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    if XTool.UObjIsNil(canvasGroup) then
        canvasGroup = dragGrid.GameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
    end
    canvasGroup.blocksRaycasts = false

    -- 禁用列表滑动，开始拖拽追踪
    self:SetScrollEnabled(false)
    self:StartDragTracking()
end

-- 获取当前手指/鼠标屏幕坐标
function XUiDlcRelinkPopupExchangeWheel:GetScreenPoint()
    if CS.UnityEngine.Input.touchCount > 0 then
        return CS.UnityEngine.Input.GetTouch(0).position
    elseif CS.UnityEngine.Input.GetMouseButton(0) then
        return CS.UnityEngine.Input.mousePosition
    end
    return nil
end

-- 获取当前手指/鼠标在PanelInfo下的本地坐标
function XUiDlcRelinkPopupExchangeWheel:GetScreenLocalPos(screenPos)
    screenPos = screenPos or self:GetScreenPoint()
    if not screenPos then
        return nil
    end
    self._screenVec2.x = screenPos.x
    self._screenVec2.y = screenPos.y
    local ok, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.PanelInfo.transform, self._screenVec2, CS.XUiManager.Instance.UiCamera)
    if not ok then
        return nil
    end
    return point
end

-- 开始拖拽追踪（用定时器读取屏幕坐标，代替Drag事件，避免拦截ScrollRect）
-- 定时器同时负责：1)位置追踪 2)手指抬起检测
function XUiDlcRelinkPopupExchangeWheel:StartDragTracking()
    self:StopDragTracking()
    self:RefreshDragClonePos()
    self.DragTrackingTimer = XScheduleManager.ScheduleForeverEx(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:StopDragTracking()
            return
        end
        -- 获取屏幕坐标
        local screenPos = self:GetScreenPoint()
        if not screenPos then
            -- 手指真正抬起（Input.touchCount=0 且鼠标未按下）
            self:EndDrag()
            return
        end
        self:RefreshDragClonePos(screenPos)
    end, 0)
end

function XUiDlcRelinkPopupExchangeWheel:RefreshDragClonePos(screenPos)
    if not self.Dragging or not self.DragCloneGrid then
        return
    end
    local localPos = self:GetScreenLocalPos(screenPos)
    if localPos then
        self._dragVec2.x = localPos.x
        self._dragVec2.y = localPos.y
        self.DragCloneGrid.Transform.anchoredPosition = self._dragVec2
    else
        self.DragCloneGrid.Transform.anchoredPosition = self._hideVec2
    end
end

-- 停止拖拽追踪
function XUiDlcRelinkPopupExchangeWheel:StopDragTracking()
    if self.DragTrackingTimer then
        XScheduleManager.UnSchedule(self.DragTrackingTimer)
        self.DragTrackingTimer = nil
    end
end

function XUiDlcRelinkPopupExchangeWheel:EndDrag()
    if not self.Dragging then
        return
    end

    local targetIndex = self.HoverWheelIndex
    local fromWheel = self.DraggingFrom == DraggingFromType.Wheel
    if targetIndex and targetIndex > 0 then
        self:ApplyEmojiToWheel(targetIndex, self.DraggingEmojiId, fromWheel and self.DraggingFromIndex or nil)
        self.DynamicTable:ReloadDataSync()
    else
        -- 拖出轮盘区域：若拖到左侧列表则卸下，否则放弃本次操作
        if fromWheel and self.DraggingFromIndex and self.HoverInList then
            self.TempEmojiWheelIds[self.DraggingFromIndex] = 0
            self:RefreshPanelWheel()
            self.DynamicTable:ReloadDataSync()
        end
    end
    self:ClearDragState()
end

function XUiDlcRelinkPopupExchangeWheel:ClearDragState()
    self:StopDragTracking()
    self:SetScrollEnabled(true)
    -- 重置长按状态
    self:ClearPressState()
    self.Dragging = false
    self.DraggingEmojiId = nil
    self.DraggingFrom = nil
    self.DraggingFromIndex = nil
    self.HoverWheelIndex = nil
    self.HoverInList = false
    if self.DragCloneGrid then
        self.DragCloneGrid:Close()
    end
    self:UpdateWheelHoverState()
    self.PanelDelete.gameObject:SetActiveEx(false)
end

--endregion

--region 轮盘数据应用

function XUiDlcRelinkPopupExchangeWheel:ApplyEmojiToWheel(targetIndex, emojiId, originIndex)
    if not XTool.IsNumberValid(emojiId) then
        return
    end
    if originIndex == targetIndex then
        return
    end
    -- 已存在该emoji则记录
    local existedIndex
    for i, id in ipairs(self.TempEmojiWheelIds) do
        if id == emojiId then
            existedIndex = i
            break
        end
    end
    if originIndex then
        -- 轮盘内部拖拽：交换或移动
        local prev = self.TempEmojiWheelIds[targetIndex]
        self.TempEmojiWheelIds[targetIndex] = emojiId
        self.TempEmojiWheelIds[originIndex] = prev or 0
    else
        -- 列表拖入：交换或移动
        if existedIndex and existedIndex ~= targetIndex then
            local prev = self.TempEmojiWheelIds[targetIndex]
            self.TempEmojiWheelIds[targetIndex] = emojiId
            self.TempEmojiWheelIds[existedIndex] = prev or 0
        else
            self.TempEmojiWheelIds[targetIndex] = emojiId
        end
    end
    self:RefreshPanelWheel()
end

--endregion

--region 点击操作

---@param grid XUiGridDlcRelinkExchangeWheelEmoji
function XUiDlcRelinkPopupExchangeWheel:OnClickListEmoji(grid)
    local emojiId = grid and grid:GetEmojiId() or 0
    if not XTool.IsNumberValid(emojiId) then
        return
    end

    -- 情况1：右侧槽位已有选择，点击列表项则替换并退出状态
    if self.ClickSelectFrom == DraggingFromType.Wheel and self.ClickSelectWheelIndex then
        self:ApplyEmojiToWheel(self.ClickSelectWheelIndex, emojiId, nil)
        self:ExitSelectionMode()
        return
    end

    -- 情况2/3：右侧槽位无选择。点击列表项, 则进入“从列表选择”模式；
    -- 若已经在列表选择模式, 再次点击同一项则取消选择
    if self.ClickSelectFrom == DraggingFromType.List and self.ClickSelectEmojiId == emojiId then
        self:ExitSelectionMode()
        return
    end

    -- 进入从列表选择模式
    self.ClickSelectFrom = DraggingFromType.List
    self.ClickSelectEmojiId = emojiId
    self.ClickSelectWheelIndex = nil

    self.DynamicTable:ReloadDataSync()
    self:UpdateWheelSelectableState(emojiId)
    self:OpenExchangePanel()
end

---@param grid XUiGridDlcRelinkExchangeWheelEmoji
function XUiDlcRelinkPopupExchangeWheel:OnClickWheelEmoji(grid)
    local targetIndex = grid and grid:GetWheelIndex() or nil
    if not targetIndex then
        return
    end

    local curWheelEmojiId = grid and grid:GetEmojiId() or 0

    -- 情况1：左侧已有选择，点击槽位则装载并退出状态
    if self.ClickSelectFrom == DraggingFromType.List and XTool.IsNumberValid(self.ClickSelectEmojiId) then
        self:ApplyEmojiToWheel(targetIndex, self.ClickSelectEmojiId, nil)
        self:ExitSelectionMode()
        return
    end

    -- 情况2/3：左侧无选择。若点击的是有内容的槽位，则进入“从轮盘选择”模式；
    -- 若已经在从轮盘选择模式，则点击任意其他槽位进行换位/装载，同一槽位则取消。
    if self.ClickSelectFrom == DraggingFromType.Wheel and self.ClickSelectWheelIndex then
        local originIndex = self.ClickSelectWheelIndex
        if originIndex == targetIndex then
            -- 再次点击同一槽位，取消选择
            self:ExitSelectionMode()
            return
        end
        local pickedEmojiId = self.TempEmojiWheelIds[originIndex] or 0
        if XTool.IsNumberValid(pickedEmojiId) then
            self:ApplyEmojiToWheel(targetIndex, pickedEmojiId, originIndex)
        end
        self:ExitSelectionMode()
        return
    end

    -- 情况4：左侧无选择，当前槽位无内容，点击无效
    if not XTool.IsNumberValid(curWheelEmojiId) then
        return
    end

    -- 进入从轮盘选择模式
    self.ClickSelectFrom = DraggingFromType.Wheel
    self.ClickSelectEmojiId = curWheelEmojiId
    self.ClickSelectWheelIndex = targetIndex

    self:UpdateWheelSelectState()
    self:UpdateWheelSelectableState(curWheelEmojiId)
    self:OpenExchangePanel()
end

---@param grid XUiGridDlcRelinkExchangeWheelEmoji
function XUiDlcRelinkPopupExchangeWheel:OnClickDeleteWheelEmoji(grid)
    local targetIndex = grid and grid:GetWheelIndex() or nil
    if not targetIndex then
        return
    end

    self.TempEmojiWheelIds[targetIndex] = 0
    self:RefreshPanelWheel()
    self:ExitSelectionMode()
end

-- 退出选择模式 & 刷新相关显示
function XUiDlcRelinkPopupExchangeWheel:ExitSelectionMode()
    self:ClearClickSelectState()
    if self.DynamicTable then
        self.DynamicTable:ReloadDataSync()
    end
    self:UpdateWheelSelectState()
    self:UpdateWheelSelectableState(nil)
    self:CloseExchangePanel()
end

function XUiDlcRelinkPopupExchangeWheel:ClearClickSelectState()
    self.ClickSelectFrom = nil
    self.ClickSelectEmojiId = nil
    self.ClickSelectWheelIndex = nil
end

--endregion

--region 层级调整

-- 获取遮罩的基础order
function XUiDlcRelinkPopupExchangeWheel:GetExchangeBaseOrder()
    return self.ExchangeCanvas and self.ExchangeCanvas.sortingOrder or 0
end

-- 打开交换面板并锁定拖拽
function XUiDlcRelinkPopupExchangeWheel:OpenExchangePanel()
    self.PanelExchange.gameObject:SetActiveEx(true)
    if self.Dragging then
        self:ClearDragState()
    end
    self.DragLocked = true
end

-- 关闭交换面板并解锁拖拽
function XUiDlcRelinkPopupExchangeWheel:CloseExchangePanel()
    self.PanelExchange.gameObject:SetActiveEx(false)
    self.DragLocked = false
end

--endregion

--region 列表滚动控制

-- 启用/禁用列表滚动（拖拽emoji时需禁用，避免列表跟着滚动）
function XUiDlcRelinkPopupExchangeWheel:SetScrollEnabled(enabled)
    if self.EmojiListScrollRect then
        self.EmojiListScrollRect.enabled = enabled
    end
end

--endregion

--region 长按进度条

-- Grid刷新前：若正在长按该Grid，则取消长按状态，避免刷新重置时长按残留
---@param grid XUiGridDlcRelinkExchangeWheelEmoji
function XUiDlcRelinkPopupExchangeWheel:OnGridBeforeRefresh(grid)
    if self.PressingGrid == grid then
        self:CancelPress()
        self.PressingGrid = nil
    end
end

-- Grid手指按下，开始长按流程
---@param grid XUiGridDlcRelinkExchangeWheelEmoji
function XUiDlcRelinkPopupExchangeWheel:OnGridPointerDown(grid)
    if self.PressingGrid and self.PressingGrid ~= grid then
        return
    end
    -- 正在拖拽或拖拽被锁定时不响应
    if self.Dragging or self.DragLocked then
        return
    end
    -- 注册为当前长按交互Grid，重置状态标记
    self.PressingGrid = grid
    self.PressCancelled = false
    self.DragTriggered = false
end

-- Grid长按持续回调：触发拖拽进度条
---@param grid XUiGridDlcRelinkExchangeWheelEmoji
function XUiDlcRelinkPopupExchangeWheel:OnGridPress(grid)
    if self.DragTriggered then
        return
    end
    if self.PressingGrid ~= grid then
        return
    end
    if self.PressCancelled then
        return
    end
    -- 拖拽被锁定时（交换面板打开），不响应长按
    if self.DragLocked then
        return
    end
    -- 开始长按，显示进度条
    if not self.IsPressing then
        self.IsPressing = true
        self:ShowPressProgress(grid.PressProgressTarget, function()
            self.IsPressing = false
            if not self.DragLocked then
                self.DragTriggered = true
                self:StartDrag(grid)
            else
                self.DragTriggered = false
            end
            self:HidePressProgress()
        end)
    end
end

-- Grid手指抬起
---@param grid XUiGridDlcRelinkExchangeWheelEmoji
function XUiDlcRelinkPopupExchangeWheel:OnGridPointerUp(grid)
    if self.PressingGrid ~= grid then
        return
    end
    self:CancelPress()
    self.PressingGrid = nil
end

-- Grid移出范围取消长按和进度条
---@param grid XUiGridDlcRelinkExchangeWheelEmoji
function XUiDlcRelinkPopupExchangeWheel:OnGridPointerExit(grid)
    if self.PressingGrid ~= grid then
        return
    end
    -- 仅在长按阶段（未触发拖拽）时取消
    if self.IsPressing and not self.DragTriggered then
        self:CancelPress()
    end
end

-- 显示长按进度条并开始加载
---@param targetTransform UnityEngine.RectTransform 目标格子的RectTransform
---@param onComplete function 进度完成回调
function XUiDlcRelinkPopupExchangeWheel:ShowPressProgress(targetTransform, onComplete)
    if not self.PressProgress then
        local path = self._Control:GetClientConfig("LongPressProgressBarPath")
        local panelTimerGo = self.PanelInfo.transform:LoadPrefabEx(path)
        local order = self:GetExchangeBaseOrder() + 3
        ---@type XUiPanelLongPressProgress
        self.PressProgress = XUiPanelLongPressProgress.New(panelTimerGo, self, order)
    end
    self.PressProgress:Open()
    self.PressProgress:Refresh(targetTransform, onComplete)
end

-- 隐藏长按进度条
function XUiDlcRelinkPopupExchangeWheel:HidePressProgress()
    if self.PressProgress then
        self.PressProgress:Close()
    end
end

-- 取消长按
function XUiDlcRelinkPopupExchangeWheel:CancelPress()
    if self.IsPressing then
        self.IsPressing = false
        self.PressCancelled = true
        self:HidePressProgress()
    end
end

-- 重置所有长按状态变量
function XUiDlcRelinkPopupExchangeWheel:ClearPressState()
    if self.IsPressing then
        self:HidePressProgress()
    end
    self.PressingGrid = nil
    self.IsPressing = false
    self.DragTriggered = false
    self.PressCancelled = false
end

--endregion

function XUiDlcRelinkPopupExchangeWheel:RegisterUiEvents()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnSave:AddEventListener(handler(self, self.OnBtnSaveClick))
    self.BtnClose2:AddEventListener(handler(self, self.OnBtnClose2Click))
end

function XUiDlcRelinkPopupExchangeWheel:OnBtnCloseClick()
    self:Close()
end

function XUiDlcRelinkPopupExchangeWheel:OnBtnSaveClick()
    self._Control:RequestSetEmojiWheel(self.TempEmojiWheelIds, function()
        self:Close()
    end)
end

function XUiDlcRelinkPopupExchangeWheel:OnBtnClose2Click()
    self:ExitSelectionMode()
end

return XUiDlcRelinkPopupExchangeWheel
