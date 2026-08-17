---@class XUiGridTheatre6PvpArchive : XUiNode
---@field _Control XTheatre6Control
---@field Parent XUiPanelTheatre6PvpArchive
local XUiGridTheatre6PvpArchive = XClass(XUiNode, "XUiGridTheatre6PvpArchive")

local XUiCommonDraggable = require("XUi/XUiCommon/XCommonDrag/XUiCommonDraggable")

function XUiGridTheatre6PvpArchive:OnStart()
    self.BtnArchive:AddEventListener(handler(self, self.OnBtnArchiveClick))
    self.Select.gameObject:SetActiveEx(false)
    self.ImgRoleMask.gameObject:SetActiveEx(false)
    self:_InitDraggable()
end

---@param fileData Theatre6FileData 存档数据
function XUiGridTheatre6PvpArchive:Update(fileData, index)
    self.FileData = fileData
    self.Index = index
    self:RefreshContent()
end

function XUiGridTheatre6PvpArchive:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE,
    }
end

function XUiGridTheatre6PvpArchive:OnNotify(evt, ...)
    if evt == XEventId.EVENT_THEATRE6_PVP_LINEUP_CHANGE then
        self:RefreshLineupIndexes()
    end
end

function XUiGridTheatre6PvpArchive:OnDisable()
    if self._Draggable then
        self._Draggable:Reset()
    end
end

function XUiGridTheatre6PvpArchive:OnDestroy()
    if self._Draggable then
        self._Draggable:Destroy()
        self._Draggable = nil
    end
end

function XUiGridTheatre6PvpArchive:RefreshContent()
    -- 角色头像
    local characterConfig = self._Control:GetCharacterConfig(self.FileData.CharacterId)
    local fashionConfig = self._Control:GetFashionConfig(characterConfig.FashionIds[1])
    self.RImgRole:SetRawImageEx(fashionConfig.Portrait)
    -- 分数
    self.UiTxtScore.text = self.FileData.Score
    -- 标签
    local showTags = self._Control:GetSortFileDataBuildTags(self.FileData)
    XUiHelper.RefreshCustomizedList(self.PanelTag, self.GridTag, #showTags, function(i, go)
        local grid = {}
        local cfg = self._Control:GetBuildTagConfig(showTags[i])
        XUiHelper.InitUiClass(grid, go)
        grid.UiTxtName.text = cfg.Name
        grid.UiImgIcon:SetRawImageEx(cfg.Icon)
    end)
    self:RefreshLineupIndexes()
end

-- 上阵序号灯 未上阵无；已上阵1个亮一个灰一个；已上阵2个全亮
function XUiGridTheatre6PvpArchive:RefreshLineupIndexes()
    if not self.FileData then
        return
    end
    local lineupMode = self.Parent.Parent:GetLineupMode()
    local indexes = self._Control:GetPvpCurrentLineupInfoIndexes(lineupMode, self.FileData.CharacterId, self.FileData.SlotId)
    if XTool.IsTableEmpty(indexes) then
        self.ListTag.gameObject:SetActiveEx(false)
        return
    end
    self.ListTag.gameObject:SetActiveEx(true)
    local tagCount = 2 -- 上阵序号灯数量固定为2
    -- 全亮时按灯位顺序显示；仅上阵 1 个时灰灯在左、亮灯在右
    local isFullLineup = #indexes == tagCount
    XUiHelper.RefreshCustomizedList(self.ListTag, self.TagNum, tagCount, function(i, go)
        local grid = {}
        XUiHelper.InitUiClass(grid, go)
        local index = isFullLineup and indexes[i] or (indexes[tagCount - i + 1] or 0)
        local isLit = index > 0
        grid.ImgBgGrey.gameObject:SetActiveEx(not isLit)
        grid.ImgBg.gameObject:SetActiveEx(isLit)
        if isLit then
            grid.TxtNum.text = index
        end
    end)
end

function XUiGridTheatre6PvpArchive:SetSelect(isSelected)
    self.Select.gameObject:SetActiveEx(isSelected)
end

function XUiGridTheatre6PvpArchive:SetRoleMask(isMask)
    self.ImgRoleMask.gameObject:SetActiveEx(isMask)
end

function XUiGridTheatre6PvpArchive:OnBtnArchiveClick()
    if self.Parent then
        self.Parent:OnSelectArchive(self)
    end
end

--region 拖拽相关
-- 声明为拖拽源（长按 + 进度条，拖到右侧上阵槽位）
function XUiGridTheatre6PvpArchive:_InitDraggable()
    -- XUiTheatre6PVPAttackDefend
    local rootUi = self.Parent.Parent
    if not rootUi then
        return
    end

    -- 禁用按钮，点击改由拖拽源的 OnClick 派发，避免与长按冲突
    self.BtnArchive.enabled = false

    ---@type XUiCommonDraggable
    self._Draggable = XUiCommonDraggable.New(self.Transform,
        {
            Context = rootUi:GetDragContext(),
            Mode = XEnumConst.CommonDrag.TriggerMode.Press, -- 在滚动列表里：长按+进度条触发，区分滑列表
            MoveTolerance = self._Control:GetIntPvpClientConfigValue("DragMoveTolerance"),
            CanDrag = function() return self.FileData ~= nil end,
            GetPayload = function() return self.FileData end,
            CloneFactory = function(fileData) return rootUi:NewArchiveDragClone(fileData) end,
            CloneRecycle = function(clone) if clone then clone:Close() end end,
            OnClick = function() self:OnBtnArchiveClick() end,
            ProgressTarget = self.Select.transform, -- 进度条目标
        })

    -- 拖拽开始时选中当前存档
    self._Draggable:SetOnDragBegin(function() self:OnBtnArchiveClick() end)
end
--endregion

return XUiGridTheatre6PvpArchive
