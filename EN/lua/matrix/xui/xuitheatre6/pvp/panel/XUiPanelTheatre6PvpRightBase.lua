---@class XUiPanelTheatre6PvpRightBase : XUiNode
---@field private _Control XTheatre6Control
---@field Parent XUiTheatre6PVPAttackDefend
local XUiPanelTheatre6PvpRightBase = XClass(XUiNode, "XUiPanelTheatre6PvpRightBase")

local XUiGridTheatre6PvpRole = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRole")
local XUiCommonDragContext = require("XUi/XUiCommon/XCommonDrag/XUiCommonDragContext")

local MAX_SLOT = 3
local REMOVE_FROM_INDEX = 100

function XUiPanelTheatre6PvpRightBase:OnStart()
    self.GridPVPRoleMe.gameObject:SetActiveEx(false)
    ---@type table<number, XUiGridTheatre6PvpRole>
    self._MyRoleGrids = {}
    self._MyFileDataList = {}
    self._CurSelectedIndex = -1

    ---@type XUiGridTheatre6PvpRole
    self._DragCloneGrid = nil           -- 拖拽克隆格子
    self:_InitDragContext()
end

-- 初始化互换拖拽上下文
function XUiPanelTheatre6PvpRightBase:_InitDragContext()
    ---@type XUiCommonDragContext
    self._DragContext = XUiCommonDragContext.New(self, self.Transform,
        {
            HitTest = XEnumConst.CommonDrag.HitTest.Rect,
        })

    self._DragContext:SetOnHoverChange(function(fromIndex, toIndex) self:_UpdateHoverState(fromIndex, toIndex) end)
    self._DragContext:SetOnDrop(function(fromIndex, toIndex) self:_OnInnerDrop(fromIndex, toIndex) end)

    -- 下阵区域
    if self.PanelCancel then
        self._DragContext:AddDropZone(self.PanelCancel.transform, REMOVE_FROM_INDEX)
    end
end

function XUiPanelTheatre6PvpRightBase:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE,
    }
end

function XUiPanelTheatre6PvpRightBase:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE then
        if args[1] == self:GetLineupMode() then
            self:RefreshRoleMe()
            if args[2] then
                self:OnSlotFilled()
            end
        end
    end
end

function XUiPanelTheatre6PvpRightBase:OnDestroy()
    if self._DragContext then
        self._DragContext:Destroy()
        self._DragContext = nil
    end
end

---子类必须重写：返回 LineupMode（Attack / Defend）
---@return number
function XUiPanelTheatre6PvpRightBase:GetLineupMode()
    return XEnumConst.Theatre6.Pvp.LineupMode.Attack
end

function XUiPanelTheatre6PvpRightBase:GetCurSelectedIndex()
    return self._CurSelectedIndex
end

--region 我方槽位刷新 / 选中
function XUiPanelTheatre6PvpRightBase:RefreshRoleMe()
    self._MyFileDataList = self._Control:GetPvpCurrentLineupFileDataList(self:GetLineupMode())
    for index = 1, MAX_SLOT do
        local grid = self._MyRoleGrids[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridPVPRoleMe, self.ListRoleMe)
            grid = XUiGridTheatre6PvpRole.New(go, self, handler(self, self.OnMyRoleGridClick))
            self._MyRoleGrids[index] = grid
            grid:InitGridDraggable()
            self._DragContext:AddDropZone(grid.Transform, index)
        end
        grid:Open()
        grid:Refresh(self._MyFileDataList[index], false, index)
        grid:SetSelect(self._CurSelectedIndex == index)
        grid:SetHighLight(false)
        grid:SetPanelDisabled(false)
    end
end

---@param grid XUiGridTheatre6PvpRole
function XUiPanelTheatre6PvpRightBase:OnMyRoleGridClick(grid)
    self:SelectSlot(grid.Index)
end

-- 默认选中第一个空槽位，如果没有空槽位则选中第一个槽位
function XUiPanelTheatre6PvpRightBase:SelectDefaultSlot()
    if self._CurSelectedIndex > 0 then
        return
    end
    local targetIndex = 1
    for index = 1, MAX_SLOT do
        if not self._MyFileDataList[index] then
            targetIndex = index
            break
        end
    end
    self:SelectSlot(targetIndex)
end

-- 当空槽位被填充之后，自动切换至下一个空槽位。若所有槽位已填满，则不自动切换
function XUiPanelTheatre6PvpRightBase:OnSlotFilled()
    if self._CurSelectedIndex <= 0 then
        return
    end

    for index = self._CurSelectedIndex + 1, MAX_SLOT do
        if not self._MyFileDataList[index] then
            self:SelectSlot(index)
            return
        end
    end
    -- 若后方没有空槽位，再从头查找空槽位
    for index = 1, MAX_SLOT do
        if not self._MyFileDataList[index] then
            self:SelectSlot(index)
            return
        end
    end
end

---选中指定槽位
---@param index number
function XUiPanelTheatre6PvpRightBase:SelectSlot(index)
    if not XTool.IsNumberValid(index) or self._CurSelectedIndex == index then
        return
    end

    self._CurSelectedIndex = index
    for i, grid in pairs(self._MyRoleGrids) do
        if grid then
            local isSelected = i == index
            grid:SetSelect(isSelected)
            if isSelected then
                if grid.FileData then
                    self.Parent:SelectArchive(grid.FileData.CharacterId, grid.FileData.SlotId)
                else
                    self.Parent:RefreshArchiveOther()
                end
            end
        end
    end
end
--endregion

--region 互换拖拽
-- 拖拽放下（fromIndex 为 payload，toIndex 为命中槽位）
function XUiPanelTheatre6PvpRightBase:_OnInnerDrop(fromIndex, toIndex)
    -- 源槽位无效则无需处理
    if not XTool.IsNumberValid(fromIndex) then
        self:_UpdateHoverState()
        return
    end

    local lineupMode = self:GetLineupMode()
    if toIndex == REMOVE_FROM_INDEX then
        -- 拖到下阵区域：移除源槽位，并选中该空出的槽位
        self._Control:RemovePvpCurrentLineupInfo(lineupMode, fromIndex)
        self:_ReselectSlot(fromIndex)
    elseif XTool.IsNumberValid(toIndex) and toIndex ~= fromIndex then
        -- 拖到有效且不同的槽位：交换两槽位（目标为空即为移动，非空则互换），并选中新槽位
        self._Control:SwapPvpCurrentLineupSlots(lineupMode, fromIndex, toIndex)
        self:_ReselectSlot(toIndex)
    end
    self:_UpdateHoverState()
end

-- 强制重新选中指定槽位（先清空当前选中以绕过同值短路）
---@param index number
function XUiPanelTheatre6PvpRightBase:_ReselectSlot(index)
    self._CurSelectedIndex = -1
    self:SelectSlot(index)
end

-- 刷新槽位高亮（fromIndex 为 payload，toIndex 为当前悬停槽位）
function XUiPanelTheatre6PvpRightBase:_UpdateHoverState(fromIndex, toIndex)
    local hoverIndex = toIndex or 0
    local fromSlot = fromIndex or 0
    for index, grid in pairs(self._MyRoleGrids) do
        if grid then
            grid:SetHighLight(index == hoverIndex and index ~= fromSlot)
            grid:SetPanelDisabled(false)
        end
    end
    if self.PanelCancel then
        self.PanelCancel.gameObject:SetActiveEx(hoverIndex == REMOVE_FROM_INDEX)
    end
end

---@param fileData Theatre6FileData|nil PVP存档数据
---@return UnityEngine.RectTransform, XUiGridTheatre6PvpRole 拖拽克隆体
function XUiPanelTheatre6PvpRightBase:CreateDragClone(fileData)
    if not self._DragCloneGrid then
        local cloneGo = XUiHelper.Instantiate(self.GridPVPRoleMe, self.Transform)
        self._DragCloneGrid = XUiGridTheatre6PvpRole.New(cloneGo, self)
    end
    self._DragCloneGrid:Open()
    self._DragCloneGrid:Refresh(fileData)
    self._DragCloneGrid:SetSelect(true)
    self._DragCloneGrid:SetHighLight(false)
    self._DragCloneGrid:SetPanelDisabled(false)
    self._DragCloneGrid:SetupAsDragClone()
    return self._DragCloneGrid.Transform, self._DragCloneGrid
end
--endregion

--region 跨面板拖拽
-- 计算存档 fileData 拖到 toIndex 槽位时需替换的槽位
-- 进攻：替换目标存档整组（份数受上阵上限约束）；防守：只换命中单槽
---@param fileData Theatre6FileData 拖入的存档
---@param toIndex number 命中的槽位索引
---@return boolean isDisabled 是否禁止放入（显示禁用图标）
---@return number[] replaceIndexes 需替换的槽位索引（已排序）
function XUiPanelTheatre6PvpRightBase:_CalcReplaceSlotIndexes(fileData, toIndex)
    if not fileData or not XTool.IsNumberValid(toIndex) then
        return false, {}
    end
    local lineupMode = self:GetLineupMode()
    local targetData = self._MyFileDataList[toIndex]
    -- 目标空槽：直接放入
    if not targetData then
        return false, { toIndex }
    end
    -- 拖回同一存档：空操作
    if targetData.CharacterId == fileData.CharacterId and targetData.SlotId == fileData.SlotId then
        return false, {}
    end

    -- 拖入存档剩余可上阵份数，<=0 则禁止放入
    local repeatLimit = self._Control:GetPvpLineupSlotRepeatLimit()
    local curCount = self._Control:GetPvpCurrentLineupInfoCount(lineupMode, fileData.CharacterId, fileData.SlotId)
    local remain = repeatLimit - curCount
    if remain <= 0 then
        return true, {}
    end

    -- 防守：只换命中单槽
    if lineupMode == XEnumConst.Theatre6.Pvp.LineupMode.Defend then
        return false, { toIndex }
    end

    -- 进攻：替换目标整组，份数不超过 remain
    local targetSlots = self._Control:GetPvpCurrentLineupInfoIndexes(lineupMode, targetData.CharacterId, targetData.SlotId)
    local replaceCount = math.min(#targetSlots, remain)
    if replaceCount >= #targetSlots then
        return false, targetSlots
    end
    -- 份数受限：取部分槽位，确保含命中槽
    local result = { toIndex }
    for _, slotIndex in ipairs(targetSlots) do
        if #result >= replaceCount then
            break
        end
        if slotIndex ~= toIndex then
            table.insert(result, slotIndex)
        end
    end
    table.sort(result)
    return false, result
end

-- 跨面板拖拽悬停：点亮待替换槽位，或在目标槽位显示禁用图标
---@param fileData Theatre6FileData|nil PVP存档数据
---@param toIndex number|nil 命中的槽位索引
function XUiPanelTheatre6PvpRightBase:UpdateArchiveHoverState(fileData, toIndex)
    local isDisabled, replaceIndexes = self:_CalcReplaceSlotIndexes(fileData, toIndex)
    for index, grid in pairs(self._MyRoleGrids) do
        if grid then
            grid:SetHighLight(not isDisabled and table.contains(replaceIndexes, index))
            grid:SetPanelDisabled(isDisabled and index == toIndex)
        end
    end
end

-- 跨面板拖拽放下：替换槽位（多槽需二次确认）
---@param fileData Theatre6FileData|nil PVP存档数据
---@param toIndex number|nil 命中的槽位索引
function XUiPanelTheatre6PvpRightBase:OnArchiveDrop(fileData, toIndex)
    local isDisabled, replaceIndexes = self:_CalcReplaceSlotIndexes(fileData, toIndex)
    if isDisabled or XTool.IsTableEmpty(replaceIndexes) then
        return
    end
    if #replaceIndexes > 1 then
        local content = self._Control:GetPvpClientConfigValue("ArchiveReplaceConfirm")
        self._Control:ShowPopup(content, function()
            self:_DoArchiveReplace(fileData, replaceIndexes)
        end)
    else
        self:_DoArchiveReplace(fileData, replaceIndexes)
    end
end

-- 执行替换并选中命中的槽位
---@param fileData Theatre6FileData
---@param replaceIndexes number[]
function XUiPanelTheatre6PvpRightBase:_DoArchiveReplace(fileData, replaceIndexes)
    if not fileData or XTool.IsTableEmpty(replaceIndexes) then
        return
    end
    local isSuccess = self._Control:ReplacePvpCurrentLineupSlots(self:GetLineupMode(), fileData, replaceIndexes)
    if isSuccess then
        self.Parent:RefreshPanelArchive()
        self:_ReselectSlot(replaceIndexes[1])
    end
end

-- 获取槽位 RectTransform 以供外部（跨面板）拖拽时悬停对齐
function XUiPanelTheatre6PvpRightBase:GetSlotRectTransform(index)
    local grid = self._MyRoleGrids[index]
    return grid and grid.Transform or nil
end

-- 获取最大槽位数以供外部（跨面板）拖拽时索引边界检查
function XUiPanelTheatre6PvpRightBase:GetMaxSlot()
    return MAX_SLOT
end
--endregion

return XUiPanelTheatre6PvpRightBase
