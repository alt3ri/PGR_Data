local SceneIds = require("XModule/XScene/XScene/XLuaSceneDefine").SceneIds

--- 肉鸽6存档预览界面
---@class XUiTheatre6Archive : XLuaUi
---@field private _Control XTheatre6Control
local XUiTheatre6Archive = XLuaUiManager.Register(XLuaUi, "UiTheatre6Archive")

local XUiGridTheatre6SettlementArchive = require("XUi/XUiTheatre6/Settlement/Grid/XUiGridTheatre6SettlementArchive")

function XUiTheatre6Archive:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    ---@type XUiGridTheatre6SettlementArchive[]
    self._ArchiveGrids = {}
    self._SelectedSlotIndex = nil
    self.GridArchive.gameObject:SetActiveEx(false)
    self:Init3DPanel()
end

function XUiTheatre6Archive:Init3DPanel()
    ---@type XTheatre6Scene
    self._Scene = XMVCA.XScene:GetScene(SceneIds.XTheatre6Scene)
end

function XUiTheatre6Archive:OnStart(roleId)
    self._RoleId = roleId
    self:Refresh()
end

function XUiTheatre6Archive:OnEnable()
    local timerId = XScheduleManager.ScheduleNextFrame(function()
        self:PlayArchiveCamAnim()
    end)
    self:_AddTimerId(timerId)
end

function XUiTheatre6Archive:OnDestroy()
    local index = self:_GetRoleIndex()
    if index then
        -- 不调用 BackToMain，避免重置 CurSelectIndex 与重播 ChooseAnim
        self._Scene:SetAllModelCamFalse()
        self._Scene:SetModelSelect(index)
    else
        self._Scene:BackToMain()
    end
end

function XUiTheatre6Archive:Refresh()
    self:RefreshRoleName()
    self:RefreshArchiveList()
    self:RefreshTips()
    self:SelectDefaultArchive()
end

function XUiTheatre6Archive:RefreshRoleName()
    if not self._RoleId then
        self.UiTxtRoleName.text = ""
        return
    end
    local characterConfig = self._Control:GetCharacterConfig(self._RoleId)
    self.UiTxtRoleName.text = characterConfig and characterConfig.Name or ""
end

function XUiTheatre6Archive:RefreshArchiveList()
    local allArchiveList = self._Control:GetSettlementArchiveList(self._RoleId)
    self._ArchiveDataList = {}
    if XTool.IsTableEmpty(allArchiveList) then
        return
    end

    for _, data in ipairs(allArchiveList) do
        if data.isEmpty then
            table.insert(self._ArchiveDataList, { isEmpty = true, slotIndex = data.slotIndex })
        else
            table.insert(self._ArchiveDataList, data)
        end
    end
    table.sort(self._ArchiveDataList, function(a, b) return a.slotIndex < b.slotIndex end)

    local defendSlotIndex = {}
    local myFileDataList = self._Control:GetPvpCurrentLineupFileDataList(XEnumConst.Theatre6.Pvp.LineupMode.Defend)
    for _, fileData in pairs(myFileDataList) do
        if fileData.CharacterId == self._RoleId then
            defendSlotIndex[fileData.SlotId] = true
        end
    end

    for i = 1, #self._ArchiveDataList do
        local data = self._ArchiveDataList[i]
        local grid = self._ArchiveGrids[i]
        if not grid then
            local ui = XUiHelper.Instantiate(self.GridArchive, self.GridArchive.transform.parent)
            grid = XUiGridTheatre6SettlementArchive.New(ui, self)
            self._ArchiveGrids[i] = grid
        end
        grid:Open()
        grid:Update(data, i)
        grid:ShowTagDefend(defendSlotIndex[data.slotIndex])
    end

    for i = #self._ArchiveDataList + 1, #self._ArchiveGrids do
        self._ArchiveGrids[i]:Close()
    end
end

function XUiTheatre6Archive:RefreshTips()
    if self.TxtTips then
        self.TxtTips.text = CS.XTextManager.GetText("Theatre6ArchiveTips")
    end
end

---默认选中第一个有数据的存档（不弹窗）
function XUiTheatre6Archive:SelectDefaultArchive()
    if XTool.IsTableEmpty(self._ArchiveDataList) then
        return
    end

    for _, data in ipairs(self._ArchiveDataList) do
        if not data.isEmpty then
            self._SelectedSlotIndex = data.slotIndex
            for _, grid in ipairs(self._ArchiveGrids) do
                grid:Update(grid.Data, grid.Index)
            end
            return
        end
    end
end

---用户点击存档槽位时调用，更新选中状态并弹出详情
---@param slotIndex number
function XUiTheatre6Archive:SelectSlot(slotIndex, target)
    self._SelectedSlotIndex = slotIndex

    for _, grid in ipairs(self._ArchiveGrids) do
        grid:Update(grid.Data, grid.Index)
    end

    for _, data in ipairs(self._ArchiveDataList) do
        if data.slotIndex == slotIndex and not data.isEmpty then
            local fileData = self._Control:GetFileDataBySlot(self._RoleId, slotIndex)
            if fileData then
                XLuaUiManager.Open("UiTheatre6PopupRoleDetail", target, fileData)
            end
            break
        end
    end
end

function XUiTheatre6Archive:PlayArchiveCamAnim()
    local index = self:_GetRoleIndex()
    if index then
        self._Scene:SetChangeArchiveByRoleBtn(index)
    end
end

function XUiTheatre6Archive:_GetRoleIndex()
    if not self._RoleId then
        return nil
    end

    -- 获取角色配置列表并排序
    local roleConfigs = {}
    for _, v in pairs(self._Control:GetCharacterConfigs()) do
        if XTool.IsNumberValid(v.Priority) then
            table.insert(roleConfigs, v)
        end
    end
    table.sort(roleConfigs, function(a, b)
        return a.Priority > b.Priority
    end)

    -- 找到角色对应的索引
    for index, config in ipairs(roleConfigs) do
        if config.Id == self._RoleId then
            return index
        end
    end
    return nil
end

return XUiTheatre6Archive