local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
---@class XUiGridDlcRelinkEquipPresets : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkPopupEquipPresets
local XUiGridDlcRelinkEquipPresets = XClass(XUiNode, "XUiGridDlcRelinkEquipPresets")

function XUiGridDlcRelinkEquipPresets:OnStart()
    self.GridEquipment.gameObject:SetActiveEx(false)
    self.BtnTop:AddEventListener(handler(self, self.OnBtnTopClick))
    self.BtnCover:AddEventListener(handler(self, self.OnBtnCoverClick))
    self.BtnUse:AddEventListener(handler(self, self.OnBtnUseClick))
    self.BtnRename:AddEventListener(handler(self, self.OnBtnRenameClick))

    ---@type XUiGridDlcRelinkEquipment[]
    self.EquipmentGridList = {}
    self.CurSelectGrid = nil
    self.CurSelectEquipUid = 0
    -- 预设起始Id
    self.PresetBeginId = self._Control:GetEquipPresetBeginId()
end

function XUiGridDlcRelinkEquipPresets:Refresh(index)
    self.Index = index + self.PresetBeginId - 1
    self:RefreshInfo()
    self:RefreshEquipment()
    self:RefreshBtn()
end

function XUiGridDlcRelinkEquipPresets:RefreshInfo()
    -- 预设名称
    self.TxtPresets.text = self._Control:GetEquipPresetSetNameByIndex(self.Index, true)
    -- 预设总战力
    self.TxtLv.text = self._Control:GetEquipPresetSetAbilityByIndex(self.Index)
end

function XUiGridDlcRelinkEquipPresets:RefreshEquipment()
    -- 装备槽位
    local equipSlotIndexMap = self._Control:GetEquipSlotIndexMap()
    for index, slotIndex in ipairs(equipSlotIndexMap) do
        local grid = self.EquipmentGridList[index]
        if not grid then
            local parent = self[string.format("GridEquipment0%d", index)]
            if not parent then
                XLog.Error("XUiGridDlcRelinkEquipPresets:RefreshEquipment parent is nil, index: " .. index)
                return
            end
            local go = XUiHelper.Instantiate(self.GridEquipment, parent)
            grid = XUiGridDlcRelinkEquipment.New(go, self, handler(self, self.OnEquipSlotCallBack))
            self.EquipmentGridList[index] = grid
        end
        grid:Open()
        local equipUid = self._Control:GetEquipPresetSetEquipUidByIndexAndSlot(self.Index, slotIndex)
        grid:Refresh(equipUid, slotIndex)
        grid:SetAdd(not XTool.IsNumberValid(equipUid))
        grid:SetHead(self._Control:GetEquipWearCharacterId(equipUid))
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiGridDlcRelinkEquipPresets:OnEquipSlotCallBack(grid)
    local equipUid = grid:GetEquipUid()
    if not XTool.IsNumberValid(equipUid) then
        return
    end
    if equipUid == self.CurSelectEquipUid then
        return
    end
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    grid:SetSelect(true)
    self.CurSelectEquipUid = equipUid
    self.CurSelectGrid = grid
    XLuaUiManager.Open("UiDlcRelinkBubbleEquipDetail", equipUid, self.Parent.PanelPresetsGroup.transform, handler(self, self.OnBubbleEquipDetailClose))
end

function XUiGridDlcRelinkEquipPresets:OnBubbleEquipDetailClose()
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    self.CurSelectEquipUid = 0
    self.CurSelectGrid = nil
end

function XUiGridDlcRelinkEquipPresets:RefreshBtn()
    self.BtnTop:SetDisable(self.Index == self.PresetBeginId)
    self.BtnUse:SetDisable(self._Control:CheckEquipPresetSetIsEmpty(self.Index))
end

-- 置顶
function XUiGridDlcRelinkEquipPresets:OnBtnTopClick()
    if self.Index <= self.PresetBeginId then
        return
    end
    local isEmpty = self._Control:CheckEquipPresetSetIsEmpty(self.Index)
    if isEmpty then
        self._Control:OpenCommonTipText("EquipPresetSetUseEmpty")
        return
    end
    self._Control:RequestPinEquipPreset(self.Index)
end

-- 覆盖
function XUiGridDlcRelinkEquipPresets:OnBtnCoverClick()
    -- 检查当前角色装备是否与预设相同
    if self:CheckCurrentCharacterEquipIsSameAsPreset() then
        return
    end
    -- 检查预设是否为空
    local isEmpty = self._Control:CheckEquipPresetSetIsEmpty(self.Index)
    if not isEmpty then
        local title = self._Control:GetClientConfig("TipTitle")
        local data = self._Control:GetClientConfigParams("EquipPresetSetCoverTipContent")
        local content = data[1] or ""
        local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "EquipPresetSetCoverTip", }
        self._Control:OpenCommonTipDialog(title, content, nil, handler(self, self.OnBtnCoverConfirm), extraData)
        return
    end
    self:OnBtnCoverConfirm()
end

-- 覆盖确认
function XUiGridDlcRelinkEquipPresets:OnBtnCoverConfirm()
    local equipDict = self._Control:GetWearEquipUidsByCharacterId(self.Parent.CharacterId)
    local name = self._Control:GetEquipPresetSetNameByIndex(self.Index)
    self._Control:RequestRecordEquipPreset(XTool.CloneEx(equipDict), self.Index, name, function()
        self:RefreshInfo()
        self:RefreshEquipment()
        self:RefreshBtn()
        self.Parent:RefreshPresetCount()
    end)
end

-- 使用
function XUiGridDlcRelinkEquipPresets:OnBtnUseClick()
    -- 检查预设是否为空
    local isEmpty = self._Control:CheckEquipPresetSetIsEmpty(self.Index)
    if isEmpty then
        self._Control:OpenCommonTipText("EquipPresetSetUseEmpty")
        return
    end
    -- 检查当前角色装备是否与预设相同
    if self:CheckCurrentCharacterEquipIsSameAsPreset() then
        return
    end
    -- 检查预设是否被其他角色穿戴
    local isWorn = self._Control:CheckEquipPresetSetIsWornByOtherCharacter(self.Index, self.Parent.CharacterId)
    if isWorn then
        local title = self._Control:GetClientConfig("TipTitle")
        local data = self._Control:GetClientConfigParams("EquipPresetSetUseTipContent")
        local content = data[1] or ""
        local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "EquipPresetSetUse", }
        self._Control:OpenCommonTipDialog(title, content, nil, handler(self, self.OnBtnUseConfirm), extraData)
        return
    end
    self:OnBtnUseConfirm()
end

-- 使用确认
function XUiGridDlcRelinkEquipPresets:OnBtnUseConfirm()
    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end
    self._Control:RequestUseEquipPreset(self.Index, self.Parent.CharacterId, function()
        self.Parent.DynamicTable:ReloadDataSync()
        self._Control:OpenCommonLeftTipDialog(self._Control:GetClientConfig("EquipPresetSetUseSuccess"))
    end)
end

--- 检查当前角色装备是否与预设相同
---@return boolean 是否相同
function XUiGridDlcRelinkEquipPresets:CheckCurrentCharacterEquipIsSameAsPreset()
    local currentEquipUids = self._Control:GetWearEquipUidsByCharacterId(self.Parent.CharacterId)
    local presetEquipUids = self._Control:GetEquipPresetSetEquipUidsByIndex(self.Index)

    local equipSlotIndexMap = self._Control:GetEquipSlotIndexMap()
    for _, slotIndex in ipairs(equipSlotIndexMap) do
        local currentUid = currentEquipUids[slotIndex] or 0
        local presetUid = presetEquipUids[slotIndex] or 0
        if currentUid ~= presetUid then
            return false
        end
    end

    self._Control:OpenCommonTipText("EquipPresetSetUseSameEquip")
    return true
end

-- 重命名
function XUiGridDlcRelinkEquipPresets:OnBtnRenameClick()
    XLuaUiManager.Open("UiDlcRelinkPopupRename", handler(self, self.OnConfirmRename))
end

-- 更新预设名称
---@param newName string 新名称
---@param callBack function 重命名成功回调
function XUiGridDlcRelinkEquipPresets:OnConfirmRename(newName, callBack)
    local equipUids = self._Control:GetEquipPresetSetEquipUidsByIndex(self.Index)
    self._Control:RequestRecordEquipPreset(equipUids, self.Index, newName, function()
        self:RefreshInfo()
        if callBack then
            callBack()
        end
    end)
end

return XUiGridDlcRelinkEquipPresets
