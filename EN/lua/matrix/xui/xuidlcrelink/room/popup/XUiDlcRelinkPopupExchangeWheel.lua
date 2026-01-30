local XUiGridDlcRelinkExchangeWheelEmoji = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkExchangeWheelEmoji")
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

    -- 列表区域hover监听，用于判断拖拽释放位置
    if self.PanelEmojiList then
        self:AddPointerEnterExit(self.PanelEmojiList.gameObject, function() self.HoverInList = true end, function() self.HoverInList = false end)
    end
end

function XUiDlcRelinkPopupExchangeWheel:OnStart()
    self:InitBtnTab()
    self:InitDynamicTable()
    self.CurSelectIndex = 2
    ---@type XUiGridDlcRelinkExchangeWheelEmoji[]
    self.EmojiGridList = {}

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

-- 进入/离开监听绑定
function XUiDlcRelinkPopupExchangeWheel:AddPointerEnterExit(go, onEnter, onExit)
    if not go then
        return
    end
    ---@type XGoInputHandler
    local handler = go:GetComponent(typeof(CS.XGoInputHandler))
    if not handler then
        handler = go:AddComponent(typeof(CS.XGoInputHandler))
    end
    if onEnter then
        handler:AddPointerEnterListener(onEnter)
    end
    if onExit then
        handler:AddPointerExitListener(onExit)
    end
    return handler
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
        -- 左侧选中高亮
        local isSelect = self.ClickSelectFrom == DraggingFromType.List and self.ClickSelectEmojiId == emojiId
        grid:SetSelect(isSelect)
        -- 左侧点击选择时提升层级
        if isSelect then
            local order = self:GetExchangeBaseOrder() + 1
            grid:SetLayerOrder(order)
        else
            grid:RestoreLayerOrder()
        end
    end
end

function XUiDlcRelinkPopupExchangeWheel:IsUsed(emojiId)
    for _, id in ipairs(self.TempEmojiWheelIds) do
        if XTool.IsNumberValid(emojiId) and id == emojiId then
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
            self:AddPointerEnterExit(parent.gameObject, function(e) self:OnPointerEnterEmoji(e, i) end, function(e) self:OnPointerExitEmoji(e, i) end)
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
    self:UpdateWheelHoverState()
    -- 根据当前选择状态调整层级
    self:UpdateSelectionLayers()
end

--region 悬停监听

function XUiDlcRelinkPopupExchangeWheel:OnPointerEnterEmoji(_, index)
    self.HoverWheelIndex = index
    self:UpdateWheelHoverState()
end

function XUiDlcRelinkPopupExchangeWheel:OnPointerExitEmoji(_, index)
    if self.HoverWheelIndex == index then
        self.HoverWheelIndex = nil
        self:UpdateWheelHoverState()
    end
end

function XUiDlcRelinkPopupExchangeWheel:UpdateWheelHoverState()
    for i, grid in ipairs(self.EmojiGridList) do
        if grid then
            local isDragHover = self.Dragging and self.HoverWheelIndex == i
            local isClickSelected = self.ClickSelectFrom == DraggingFromType.Wheel and self.ClickSelectWheelIndex == i
            grid:SetSelect(isDragHover or isClickSelected)
        end
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
        local go = XUiHelper.Instantiate(self.GridEmoji2, self.PanelInfo)
        dragGrid = XUiGridDlcRelinkExchangeWheelEmoji.New(go, self)
        self.DragCloneGrid = dragGrid

        local order = self:GetExchangeBaseOrder() + 2
        dragGrid:SetLayerOrder(order)
        ---@type UnityEngine.CanvasGroup
        local canvasGroup = dragGrid.GameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
        canvasGroup.blocksRaycasts = false
    end
    dragGrid:Open()
    dragGrid:SetIsDragClone(true)
    dragGrid:Refresh(emojiId)
end

function XUiDlcRelinkPopupExchangeWheel:GetPosByEventData(eventData)
    local transform = self.PanelInfo.transform
    local ok, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(transform, eventData.position, CS.XUiManager.Instance.UiCamera)
    if not ok then
        return -99999, -99999
    end
    return point.x, point.y
end

function XUiDlcRelinkPopupExchangeWheel:OnDragMove(eventData)
    if not self.Dragging or not self.DragCloneGrid then
        return
    end
    local x, y = self:GetPosByEventData(eventData)
    self.DragCloneGrid.Transform.anchoredPosition = CS.UnityEngine.Vector2(x, y)
end

function XUiDlcRelinkPopupExchangeWheel:EndDrag(eventData)
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
        -- 列表拖入：若其它槽已有则清空旧槽
        if existedIndex and existedIndex ~= targetIndex then
            self.TempEmojiWheelIds[existedIndex] = 0
        end
        self.TempEmojiWheelIds[targetIndex] = emojiId
    end
    self:RefreshPanelWheel()
end

--endregion

--region 点击操作

function XUiDlcRelinkPopupExchangeWheel:ClearClickSelectState()
    self.ClickSelectFrom = nil
    self.ClickSelectEmojiId = nil
    self.ClickSelectWheelIndex = nil
end

---@param grid XUiGridDlcRelinkExchangeWheelEmoji
function XUiDlcRelinkPopupExchangeWheel:OnClickListEmoji(grid)
    local emojiId = grid and grid:GetEmojiId() or 0
    if not XTool.IsNumberValid(emojiId) then
        return
    end
    local enteringSelect = false
    -- 切换到“从列表选择”模式（再次点击同一项则取消选择）
    if self.ClickSelectFrom == DraggingFromType.List and self.ClickSelectEmojiId == emojiId then
        self:ClearClickSelectState()
    else
        self.ClickSelectFrom = DraggingFromType.List
        self.ClickSelectEmojiId = emojiId
        self.ClickSelectWheelIndex = nil
        enteringSelect = true
    end
    -- 更新左侧“使用中”与高亮
    self.DynamicTable:ReloadDataSync()
    self:UpdateWheelHoverState()
    -- 根据当前选择状态调整层级
    self:UpdateSelectionLayers()
    if enteringSelect then
        self:OpenExchangePanel()
    else
        self:CloseExchangePanel()
    end
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

    -- 没有任何选择时，点击有内容的槽位则开始“从轮盘选择”
    if XTool.IsNumberValid(curWheelEmojiId) then
        self.ClickSelectFrom = DraggingFromType.Wheel
        self.ClickSelectEmojiId = curWheelEmojiId
        self.ClickSelectWheelIndex = targetIndex
        self:UpdateWheelHoverState()
        -- 进入轮盘选择时仅提升轮盘层级
        self:UpdateSelectionLayers()
        self:OpenExchangePanel()
    end
end

-- 退出选择模式 & 刷新相关显示
function XUiDlcRelinkPopupExchangeWheel:ExitSelectionMode()
    self:ClearClickSelectState()
    -- 更新左侧“使用中”与高亮
    if self.DynamicTable then
        self.DynamicTable:ReloadDataSync()
    end
    self:UpdateWheelHoverState()
    -- 根据当前选择状态调整层级
    self:UpdateSelectionLayers()
    self:CloseExchangePanel()
end

--endregion

--region 层级调整

-- 获取遮罩的基础order
function XUiDlcRelinkPopupExchangeWheel:GetExchangeBaseOrder()
    return self.ExchangeCanvas and self.ExchangeCanvas.sortingOrder or 0
end

-- 将轮盘里的所有格子层级设置为指定 order
function XUiDlcRelinkPopupExchangeWheel:SetWheelGridsLayer(order)
    for _, grid in ipairs(self.EmojiGridList) do
        if grid then
            grid:SetLayerOrder(order)
        end
    end
end

-- 还原轮盘里所有格子的层级
function XUiDlcRelinkPopupExchangeWheel:RestoreWheelGridsLayer()
    for _, grid in ipairs(self.EmojiGridList) do
        if grid then
            grid:RestoreLayerOrder()
        end
    end
end

-- 根据当前选择状态应用层级调整
function XUiDlcRelinkPopupExchangeWheel:UpdateSelectionLayers()
    local baseOrder = self:GetExchangeBaseOrder()
    local raised = baseOrder + 1
    if self.ClickSelectFrom == DraggingFromType.List and XTool.IsNumberValid(self.ClickSelectEmojiId) then
        -- 列表选择：轮盘全部+1，左侧被选中项单独由列表格子处理
        self:SetWheelGridsLayer(raised)
    elseif self.ClickSelectFrom == DraggingFromType.Wheel and self.ClickSelectWheelIndex then
        -- 轮盘选择：仅轮盘全部+1
        self:SetWheelGridsLayer(raised)
    else
        -- 无选择：全部还原
        self:RestoreWheelGridsLayer()
    end
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

function XUiDlcRelinkPopupExchangeWheel:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSave, self.OnBtnSaveClick)
    self:RegisterClickEvent(self.BtnClose2, self.OnBtnClose2Click)
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
