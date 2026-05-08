local SceneIds = require("XModule/XScene/XScene/XLuaSceneDefine").SceneIds

--- 肉鸽6存档预览界面
---@class XUiTheatre6Archive : XLuaUi
---@field private _Control XTheatre6Control
local XUiTheatre6Archive = XLuaUiManager.Register(XLuaUi, "UiTheatre6Archive")

local XUiGridTheatre6SettlementArchive = require("XUi/XUiTheatre6/Settlement/Grid/XUiGridTheatre6SettlementArchive")

function XUiTheatre6Archive:OnAwake()
    self:RegisterClickEvent(self.BtnBack, self.Close)
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
    self._Scene:BackToMain()
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

    XTool.UpdateDynamicItem(self._ArchiveGrids, self._ArchiveDataList, self.GridArchive, XUiGridTheatre6SettlementArchive, self)
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
    if not self._RoleId then
        return
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
            self._Scene:SetChangeArchiveByRoleBtn(index)
            return
        end
    end
end

return XUiTheatre6Archive