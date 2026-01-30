local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
local XUiPanelDlcRelinkEquipDetail = require("XUi/XUiDlcRelink/Equip/Panel/XUiPanelDlcRelinkEquipDetail")
local XUiGridDlcRelinkEquipAttribute = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipAttribute")
---@class XUiDlcRelinkEquipBag : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelTab XUiButtonGroup
---@field BtnFilter XUiComponent.XUiButton
local XUiDlcRelinkEquipBag = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkEquipBag")

local BtnOperateType = {
    Replace = 1, -- 替换（同角色不同槽位，交换）
    Wear = 2, -- 穿戴（当前槽为空）
    Change = 3, -- 更换（当前槽有装备，用背包选中装备覆盖）
}

function XUiDlcRelinkEquipBag:OnAwake()
    self.GridEquipment.gameObject:SetActiveEx(false)
    self.GridAttribute.gameObject:SetActiveEx(false)
    self.GridEquipItem.gameObject:SetActiveEx(false)
    self.BtnTab.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()

    ---@type XUiGridDlcRelinkEquipment[]
    self.EquipmentGridList = {}
    ---@type XUiComponent.XUiButton[]
    self.EquipBtnTabList = {}
    ---@type XUiGridDlcRelinkEquipAttribute[]
    self.EquipTotalAttributeGridList = {}

    --- 装备筛选数据缓存
    ---@type XDlcRelinkEquipFilterCache
    self.EquipFilterCache = {}
end

function XUiDlcRelinkEquipBag:OnStart(characterId, slotIndex)
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self.CharacterId = characterId
    self.CurSelectSlotIndex = XTool.IsNumberValid(slotIndex) and slotIndex or XEnumConst.DlcRelink.EquipSlotIndex.MainSlot
    self.CurSelectSlotEquipUid = self._Control:GetEquipUidByCharacterId(self.CharacterId, self.CurSelectSlotIndex)

    self.EquipOccupationDefaultIndex = 1 -- 进入时默认选择的职业Tab
    self.CurSelectEquipOccupationIndex = 0

    self.CurSelectGrid = nil
    self.CurSelectEquipUid = 0

    self:InitPanelTab()
    self:InitDynamicTable()

    -- 先确定进入时的默认槽位与装备选择
    self:EnsureInitialSelection()
end

function XUiDlcRelinkEquipBag:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshPanelEquipment()
    self.PanelTab:SelectIndex(self.EquipOccupationDefaultIndex)
    self.BtnFilter:SetSpriteVisible(false)
end

function XUiDlcRelinkEquipBag:OnDisable()
    self.Super.OnDisable(self)
    self.EquipFilterCache = {}
    -- 记录当前职业Tab为下次默认选择
    if self.CurSelectEquipOccupationIndex > 0 then
        self.EquipOccupationDefaultIndex = self.CurSelectEquipOccupationIndex
    end
    self.CurSelectEquipOccupationIndex = 0
    -- 记录所有装备已查看状态
    self._Control:RecordAllEquipViewed()
end

--region 进入默认选择逻辑

function XUiDlcRelinkEquipBag:GetEquipOccupationTypeByUid(equipUid)
    local templateId = self._Control:GetEquipTemplateIdByEquipUid(equipUid)
    if not XTool.IsNumberValid(templateId) then
        return 0
    end
    return self._Control:GetEquipOccupationType(templateId)
end

-- 从背包中按职业(1-3)扫描，返回第一件可选装备的Uid
---@param unWeareEquipUids number[] 未穿戴装备Uid列表
---@return number, number 装备Uid，装备职业
function XUiDlcRelinkEquipBag:FindFirstAvailableBagEquip(unWeareEquipUids)
    for occ = 1, 3 do
        for _, uid in ipairs(unWeareEquipUids) do
            local equipOcc = self:GetEquipOccupationTypeByUid(uid)
            if equipOcc == occ then
                return uid, equipOcc
            end
        end
    end
    return 0, 0
end

-- 在无背包可选时，按槽位优先级找到已穿戴的装备
---@return number, number 装备槽位，装备Uid
function XUiDlcRelinkEquipBag:FindFirstWornEquipByPriority()
    local equipSlotIndexMap = self._Control:GetEquipSlotIndexMap()
    for _, slotIndex in ipairs(equipSlotIndexMap) do
        if slotIndex ~= self.CurSelectSlotIndex then
            local uid = self._Control:GetEquipUidByCharacterId(self.CharacterId, slotIndex)
            if XTool.IsNumberValid(uid) then
                return slotIndex, uid
            end
        end
    end
    return 0, 0
end

-- 入口默认选择：
-- 1) 有槽位参数：若该槽位已穿戴，则展示该装备并切到对应职业Tab
-- 2) 无槽位参数且背包有装备：选中背包第一件装备，展示该装备详情
-- 3) 无背包可选：按优先级找已穿戴装备，展示该装备详情
function XUiDlcRelinkEquipBag:EnsureInitialSelection()
    -- 情况1：外部点击有装备槽位进入
    if XTool.IsNumberValid(self.CurSelectSlotEquipUid) then
        local occupationType = self:GetEquipOccupationTypeByUid(self.CurSelectSlotEquipUid)
        if XTool.IsNumberValid(occupationType) then
            self.EquipOccupationDefaultIndex = occupationType
        end
        return
    end

    -- 无槽位参数
    local unWeareEquipUids = self._Control:GetUnWearEquipUidListBySlot(self.CurSelectSlotIndex)
    local hasAnyEquip = not XTool.IsTableEmpty(unWeareEquipUids)

    if hasAnyEquip then
        -- 情况2：背包有装备，选中背包第一件
        local _, occupationType = self:FindFirstAvailableBagEquip(unWeareEquipUids)
        if XTool.IsNumberValid(occupationType) then
            self.EquipOccupationDefaultIndex = occupationType
        end
    else
        -- 情况3：背包无装备，按优先级找已穿戴
        local slot, uid = self:FindFirstWornEquipByPriority()
        if XTool.IsNumberValid(uid) then
            self.CurSelectSlotIndex = slot
            self.CurSelectSlotEquipUid = uid
            local occupationType = self:GetEquipOccupationTypeByUid(uid)
            if XTool.IsNumberValid(occupationType) then
                self.EquipOccupationDefaultIndex = occupationType
            end
        else
            -- 默认到主槽 + 职业1
            self.CurSelectSlotIndex = XEnumConst.DlcRelink.EquipSlotIndex.MainSlot
            self.CurSelectSlotEquipUid = 0
            self.EquipOccupationDefaultIndex = 1
        end
    end
end

--endregion

--region 左侧装备槽位

function XUiDlcRelinkEquipBag:RefreshPanelEquipment()
    -- 装备总战力
    local totalAbility = self._Control:GetEquipTotalAbilityByCharacterId(self.CharacterId)
    self.TxtLv.text = string.format(self._Control:GetClientConfig("EquipLevelDesc"), totalAbility)
    -- 装备槽位
    local equipSlotIndexMap = self._Control:GetEquipSlotIndexMap()
    for index, slotIndex in ipairs(equipSlotIndexMap) do
        local grid = self.EquipmentGridList[index]
        if not grid then
            local parent = self[string.format("GridEquipment0%d", index)]
            if not parent then
                XLog.Error("XUiDlcRelinkEquipBag:RefreshPanelEquipment - GridEquipment0" .. index .. " not found")
                return
            end
            local go = XUiHelper.Instantiate(self.GridEquipment, parent)
            grid = XUiGridDlcRelinkEquipment.New(go, self, handler(self, self.OnEquipSlotCallBack))
            self.EquipmentGridList[index] = grid
        end
        grid:Open()
        local equipUid = self._Control:GetEquipUidByCharacterId(self.CharacterId, slotIndex)
        local isUnLock = self._Control:CheckEquipSlotIsUnlocked(self.CharacterId, slotIndex)
        grid:Refresh(equipUid, slotIndex)
        grid:SetLock(not isUnLock)
        grid:SetAdd(isUnLock and not XTool.IsNumberValid(equipUid))
        grid:SetSelect(self.CurSelectSlotIndex == slotIndex)
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:OnEquipSlotCallBack(grid)
    local slotIndex = grid:GetSlotIndex()
    local isUnLock, unlockDesc = self._Control:CheckEquipSlotIsUnlocked(self.CharacterId, slotIndex)
    if not isUnLock then
        self._Control:OpenCommonTipMsg(unlockDesc)
        return
    end

    if self.CurSelectSlotIndex == slotIndex then
        return
    end
    self:SetCurrentSlot(slotIndex)
    -- 重置职业选择并刷新列表
    self.CurSelectEquipOccupationIndex = 0
    self.CurSelectEquipUid = 0
    self.CurSelectGrid = nil
    self.EquipFilterCache = {}

    local defaultIndex = self:GetDefaultSelectEquipOccupationIndex()
    self.PanelTab:SelectIndex(defaultIndex)
end

function XUiDlcRelinkEquipBag:SetCurrentSlot(slotIndex)
    self.CurSelectSlotIndex = slotIndex
    self.CurSelectSlotEquipUid = self._Control:GetEquipUidByCharacterId(self.CharacterId, slotIndex)
    -- 刷新槽位选中状态
    for _, grid in ipairs(self.EquipmentGridList) do
        grid:SetSelect(grid:GetSlotIndex() == slotIndex)
    end
end

function XUiDlcRelinkEquipBag:GetDefaultSelectEquipOccupationIndex()
    if XTool.IsNumberValid(self.CurSelectSlotEquipUid) then
        local occupationType = self:GetEquipOccupationTypeByUid(self.CurSelectSlotEquipUid)
        if XTool.IsNumberValid(occupationType) then
            return occupationType
        end
    else
        local unWeareEquipUids = self._Control:GetUnWearEquipUidListBySlot(self.CurSelectSlotIndex)
        if not XTool.IsTableEmpty(unWeareEquipUids) then
            local _, occupationType = self:FindFirstAvailableBagEquip(unWeareEquipUids)
            if XTool.IsNumberValid(occupationType) then
                return occupationType
            end
        end
    end
    return 1
end

-- 构建当前装备穿戴快照
function XUiDlcRelinkEquipBag:BuildEquipUidsSnapshot()
    local equipDict = self._Control:GetWearEquipUidsByCharacterId(self.CharacterId)
    local isCanWear = self:CheckCurrentEquipCanWear()

    local equipUids = {}
    local fromSlot = 0

    -- 先拷贝现有穿戴并定位被选装备所在槽位
    local equipSlotIndexMap = self._Control:GetEquipSlotIndexMap()
    for _, slotIndex in ipairs(equipSlotIndexMap) do
        local uid = equipDict[slotIndex]
        if XTool.IsNumberValid(uid) then
            equipUids[slotIndex] = uid
            if uid == self.CurSelectEquipUid then
                fromSlot = slotIndex
            end
        end
    end

    -- 无法穿戴则保持原样
    if not isCanWear then
        return equipUids
    end

    local operateType = self:GetOperateType()
    if operateType == BtnOperateType.Replace then
        -- 交换：当前槽位 <- 被选装备；被选装备原槽位 <- 当前槽原装备
        equipUids[self.CurSelectSlotIndex] = self.CurSelectEquipUid
        if fromSlot > 0 then
            if XTool.IsNumberValid(self.CurSelectSlotEquipUid) then
                equipUids[fromSlot] = self.CurSelectSlotEquipUid
            else
                equipUids[fromSlot] = nil
            end
        end
        return equipUids
    end

    -- 穿戴/更换：当前槽位覆盖为被选装备
    equipUids[self.CurSelectSlotIndex] = self.CurSelectEquipUid
    return equipUids
end

function XUiDlcRelinkEquipBag:RefreshEquipTotalAttribute()
    local equipUids = self:BuildEquipUidsSnapshot()
    local totalAttributes = self._Control:GetEquipTotalAttributeList(equipUids)
    for index, attribute in ipairs(totalAttributes) do
        local grid = self.EquipTotalAttributeGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridAttribute, self.PaneAttribute)
            grid = XUiGridDlcRelinkEquipAttribute.New(go, self)
            self.EquipTotalAttributeGridList[index] = grid
        end
        grid:Open()
        grid:CustomRefresh(attribute)
    end

    for i = #totalAttributes + 1, #self.EquipTotalAttributeGridList do
        local grid = self.EquipTotalAttributeGridList[i]
        if grid then
            grid:Close()
        end
    end
end

-- 检查当前选中的槽位是否为扩展槽位且主槽位已穿戴装备
function XUiDlcRelinkEquipBag:CheckExtendSlotAndMainSlotWearEquip()
    local isExtendSlot = self._Control:CheckIsExpandSlotIndex(self.CurSelectSlotIndex)
    local mainEquipUid = self._Control:GetEquipUidByCharacterId(self.CharacterId, XEnumConst.DlcRelink.EquipSlotIndex.MainSlot)
    local isMainSlotWearEquip = XTool.IsNumberValid(mainEquipUid)
    return isExtendSlot and isMainSlotWearEquip
end

--endregion

--region 装备背包

function XUiDlcRelinkEquipBag:InitPanelTab()
    self.EquipBtnTabList = {}
    local tabDescList = self._Control:GetClientConfigParams("EquipTabsDesc")
    for _, tabDesc in ipairs(tabDescList) do
        ---@type XUiComponent.XUiButton
        local btnTab = XUiHelper.Instantiate(self.BtnTab, self.PanelTab.transform)
        btnTab.gameObject:SetActiveEx(true)
        btnTab:SetNameByGroup(0, tabDesc)
        table.insert(self.EquipBtnTabList, btnTab)
    end
    self.PanelTab:Init(self.EquipBtnTabList, handler(self, self.OnEquipBtnTabClick))
end

function XUiDlcRelinkEquipBag:OnEquipBtnTabClick(index)
    if self.CurSelectEquipOccupationIndex == index then
        return
    end
    self.CurSelectEquipOccupationIndex = index
    -- 重置装备筛选缓存
    self.EquipFilterCache = {}
    self:SetupDynamicTable()
end

function XUiDlcRelinkEquipBag:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkEquipment, self, handler(self, self.OnEquipItemCallBack))
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkEquipBag:SetupDynamicTable()
    -- 装备类型(默认筛选条件)
    self.EquipFilterCache.EquipType = self.CurSelectSlotIndex == XEnumConst.DlcRelink.EquipSlotIndex.MainSlot and XEnumConst.DlcRelink.EquipType.Main or XEnumConst.DlcRelink.EquipType.Normal
    self.EquipUidList = self._Control:GetEquipUidListByOccupationType(self.CurSelectEquipOccupationIndex, { Context = "Equip", CharacterId = self.CharacterId, Filter = self.EquipFilterCache })
    local isEmpty = XTool.IsTableEmpty(self.EquipUidList)
    self.None.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        self.DynamicTable:Clear()
        self.CurSelectEquipUid = 0
        self.CurSelectGrid = nil
        self:RefreshEquipDetail()
        return
    end

    local index = self:GetDefaultSelectEquipUidIndex()
    self.CurSelectEquipUid = self.EquipUidList[index]
    self.CurSelectGrid = nil

    self.DynamicTable:SetDataSource(self.EquipUidList)
    self.DynamicTable:ReloadDataSync(index)
end

function XUiDlcRelinkEquipBag:GetDefaultSelectEquipUidIndex()
    if XTool.IsNumberValid(self.CurSelectSlotEquipUid) then
        for i, uid in ipairs(self.EquipUidList) do
            if uid == self.CurSelectSlotEquipUid then
                return i
            end
        end
    end
    return 1
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local equipUid = self.EquipUidList[index]
        grid:Refresh(equipUid)
        grid:SetHead(self._Control:GetEquipWearCharacterId(equipUid))
        local isSelected = equipUid == self.CurSelectEquipUid
        grid:SetSelect(isSelected)
        if isSelected and not self.CurSelectGrid then
            self.CurSelectGrid = grid
            self:RefreshEquipDetail()
            self:RecordEquipViewed()
        end
        grid:SetRedDot(not self._Control:CheckEquipViewed(equipUid))
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:OnEquipItemCallBack(grid)
    local equipUid = grid:GetEquipUid()
    if equipUid == self.CurSelectEquipUid then
        return
    end
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    grid:SetSelect(true)
    self.CurSelectEquipUid = equipUid
    self.CurSelectGrid = grid
    self:RefreshEquipDetail()
    self:RecordEquipViewed()
end

-- 记录装备已查看状态
function XUiDlcRelinkEquipBag:RecordEquipViewed()
    if not XTool.IsNumberValid(self.CurSelectEquipUid) then
        return
    end
    self._Control:RecordEquipViewed(self.CurSelectEquipUid)
    if self.CurSelectGrid then
        self.CurSelectGrid:SetRedDot(false)
    end
end

-- 检查当前选中的装备是否可穿戴
function XUiDlcRelinkEquipBag:CheckCurrentEquipCanWear()
    if not XTool.IsNumberValid(self.CurSelectEquipUid) then
        return false
    end

    -- 不可穿戴条件：当前槽位已穿戴该装备
    return self.CurSelectSlotEquipUid ~= self.CurSelectEquipUid
end

-- 获取【替换/穿戴/更换】按钮状态
---@return number, number BtnOperateType替换=1,穿戴=2,更换=3, 穿戴的角色Id 
function XUiDlcRelinkEquipBag:GetOperateType()
    if not XTool.IsNumberValid(self.CurSelectEquipUid) then
        return nil, 0
    end

    local wearCharacterId = self._Control:GetEquipWearCharacterId(self.CurSelectEquipUid)
    if XTool.IsNumberValid(wearCharacterId) and wearCharacterId == self.CharacterId then
        return BtnOperateType.Replace, wearCharacterId
    end

    if not XTool.IsNumberValid(self.CurSelectSlotEquipUid) then
        return BtnOperateType.Wear, wearCharacterId
    end

    return BtnOperateType.Change, wearCharacterId
end

--endregion

--region 右侧装备详情

function XUiDlcRelinkEquipBag:RefreshEquipDetail()
    if not self.EquipDetailNode then
        ---@type XUiPanelDlcRelinkEquipDetail
        self.EquipDetailNode = XUiPanelDlcRelinkEquipDetail.New(self.PanelDetail, self)
    end
    if XTool.IsNumberValid(self.CurSelectEquipUid) then
        self.EquipDetailNode:Open()
        self.EquipDetailNode:Refresh(self.CurSelectEquipUid)
    else
        self.EquipDetailNode:Close()
    end

    self:RefreshEquipTotalAttribute()
    self:RefreshBtn()
    self:RefreshFilterBtn()
end

--endregion

--region 刷新按钮

function XUiDlcRelinkEquipBag:RefreshBtn()
    local isValidEquip = XTool.IsNumberValid(self.CurSelectEquipUid)
    self.BtnReform.gameObject:SetActiveEx(isValidEquip)
    self.RightBg.gameObject:SetActiveEx(isValidEquip)

    if not isValidEquip then
        self.BtnReplace.gameObject:SetActiveEx(false)
        self.BtnRemove.gameObject:SetActiveEx(false)
        return
    end

    local isCanWear = self:CheckCurrentEquipCanWear()
    self.BtnReplace.gameObject:SetActiveEx(isCanWear)
    self.BtnRemove.gameObject:SetActiveEx(not isCanWear)

    if isCanWear then
        local operateType = self:GetOperateType()
        self.BtnReplace:SetNameByGroup(0, self._Control:GetClientConfig("EquipBagBtnReplaceDesc", operateType))
    end
end

function XUiDlcRelinkEquipBag:RefreshFilterBtn()
    local isFilter = self:CheckFilterCache()
    self.BtnFilter:SetNameByGroup(0, self._Control:GetClientConfig("EquipFilterBtnDesc", isFilter and 2 or 1))
end

-- 检查当前筛选条件是否有生效
function XUiDlcRelinkEquipBag:CheckFilterCache()
    if XTool.IsTableEmpty(self.EquipFilterCache) then
        return false
    end

    if XTool.IsNumberValid(self.EquipFilterCache.ReformedType)
        or XTool.IsNumberValid(self.EquipFilterCache.FactorRemovedType)
        or not XTool.IsTableEmpty(self.EquipFilterCache.FactorIds) then
        return true
    end

    return false
end

--endregion

function XUiDlcRelinkEquipBag:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnAttribute, self.OnBtnAttributeClick)
    self:RegisterClickEvent(self.BtnReform, self.OnBtnReformClick)
    self:RegisterClickEvent(self.BtnReplace, self.OnBtnReplaceClick)
    self:RegisterClickEvent(self.BtnRemove, self.OnBtnRemoveClick)
    self:RegisterClickEvent(self.BtnFilter, self.OnBtnFilterClick)
    self:RegisterClickEvent(self.BtnBreakdown, self.OnBtnBreakdownClick)
    self:RegisterClickEvent(self.BtnSynthesis, self.OnBtnSynthesisClick)
end

function XUiDlcRelinkEquipBag:OnBtnBackClick()
    self:Close()
end

-- 打开属性详情弹窗
function XUiDlcRelinkEquipBag:OnBtnAttributeClick()
    local equipUids = self:BuildEquipUidsSnapshot()
    if XTool.IsTableEmpty(equipUids) then
        return
    end
    XLuaUiManager.Open("UiDlcRelinkPopupEquipAttributeDetail", equipUids, self.CharacterId)
end

-- 改造装备
function XUiDlcRelinkEquipBag:OnBtnReformClick()
    if not XTool.IsNumberValid(self.CurSelectEquipUid) then
        return
    end
    XLuaUiManager.Open("UiDlcRelinkEquipReform", self.CurSelectEquipUid)
end

-- 穿戴/更换/替换
function XUiDlcRelinkEquipBag:OnBtnReplaceClick()
    if not XTool.IsNumberValid(self.CurSelectEquipUid) then
        return
    end

    if not self:CheckCurrentEquipCanWear() then
        XLog.Error("XUiDlcRelinkEquipBag:OnBtnReplaceClick -> 当前槽位已穿戴该装备，无法穿戴")
        return
    end

    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end

    local onWearEquip = function()
        self.CurSelectSlotEquipUid = self.CurSelectEquipUid
        self:RefreshPanelEquipment()
        self:RefreshEquipTotalAttribute()
        if self.CurSelectGrid then
            self.CurSelectGrid:SetHead(self.CharacterId)
        end
        self:RefreshBtn()
    end

    local operateType, wearCharacterId = self:GetOperateType()
    if (operateType == BtnOperateType.Wear or operateType == BtnOperateType.Change) and XTool.IsNumberValid(wearCharacterId) then
        local characterName = XMVCA.XCharacter:GetCharacterName(wearCharacterId)
        local title = self._Control:GetClientConfig("TipTitle")
        local data = self._Control:GetClientConfigParams("EquipReplaceWearTipContent")
        local content = string.format(data[1] or "", characterName)
        local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "EquipReplaceWearTip" }
        self._Control:OpenCommonTipDialog(title, content, nil, function()
            self._Control:RequestWearEquip(self.CharacterId, self.CurSelectSlotIndex, self.CurSelectEquipUid, onWearEquip)
        end, extraData)
        return
    end

    self._Control:RequestWearEquip(self.CharacterId, self.CurSelectSlotIndex, self.CurSelectEquipUid, onWearEquip)
end

-- 卸下装备
function XUiDlcRelinkEquipBag:OnBtnRemoveClick()
    if not XTool.IsNumberValid(self.CurSelectEquipUid) then
        return
    end

    if self:CheckCurrentEquipCanWear() then
        XLog.Error("XUiDlcRelinkEquipBag:OnBtnRemoveClick -> 当前槽位并未穿戴该装备，无法卸下")
        return
    end

    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end

    self._Control:RequestUnWearEquip(self.CharacterId, self.CurSelectSlotIndex, function()
        self.CurSelectSlotEquipUid = 0
        self:RefreshPanelEquipment()
        self:RefreshEquipTotalAttribute()
        if self.CurSelectGrid then
            self.CurSelectGrid:SetHead(0)
        end
        self:RefreshBtn()
    end)
end

-- 打开筛选弹窗
function XUiDlcRelinkEquipBag:OnBtnFilterClick()
    self.BtnFilter:SetSpriteVisible(true)
    local equipUidList = self._Control:GetEquipUidListByOccupationType(self.CurSelectEquipOccupationIndex)
    local equipMainFactorIds = self._Control:GetEquipMainFactorIds(equipUidList)
    XLuaUiManager.Open("UiDlcRelinkPopupFilter", equipMainFactorIds, self.EquipFilterCache, true, function()
        self:SetupDynamicTable()
    end, function()
        self.BtnFilter:SetSpriteVisible(false)
    end)
end

-- 打开分解界面
function XUiDlcRelinkEquipBag:OnBtnBreakdownClick()
    XLuaUiManager.Open("UiDlcRelinkEquipDecompose")
end

-- 打开合成界面
function XUiDlcRelinkEquipBag:OnBtnSynthesisClick()
    local curLevel = self._Control:GetCurrentPlayerLevel()
    local composeId = self._Control:GetPlayerLevelComposeId(curLevel)
    if not XTool.IsNumberValid(composeId) then
        return
    end
    XLuaUiManager.Open("UiDlcRelinkPopupEquipCompose", composeId)
end

return XUiDlcRelinkEquipBag
