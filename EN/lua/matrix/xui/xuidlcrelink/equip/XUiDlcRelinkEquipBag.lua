local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
local XUiPanelDlcRelinkEquipDetail = require("XUi/XUiDlcRelink/Equip/Panel/XUiPanelDlcRelinkEquipDetail")
local XUiGridDlcRelinkEquipAttribute = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipAttribute")
local XUiPanelLongPressProgress = require("XUi/XUiDlcRelink/Common/XUiPanelLongPressProgress")
---@class XUiDlcRelinkEquipBag : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelTab XUiButtonGroup
---@field BtnFilter XUiComponent.XUiButton
local XUiDlcRelinkEquipBag = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkEquipBag")

local EquipSlotIndex = XEnumConst.DlcRelink.EquipSlotIndex
local BtnOperateType = {
    Replace = 1, -- 替换（同角色不同槽位，交换）
    Wear = 2, -- 穿戴（当前槽为空）
    Change = 3, -- 更换（当前槽有装备，用背包选中装备覆盖）
}
local DraggingFromType = {
    EquipSlot = 1, -- 从装备槽位拖出
    BagEquip = 2, -- 从背包装备拖出
}
local DragAction = {
    Cancel = 0, -- 取消/无效操作
    Equip = 1, -- 背包装备穿戴到槽位
    Swap = 2, -- 槽位间交换
    Unequip = 3, -- 从槽位卸下到背包
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
    ---@type UiObject[]
    self.PanelGlowList = {}

    --- 装备筛选数据缓存
    ---@type XDlcRelinkEquipFilterCache
    self.EquipFilterCache = {}

    -- 拖拽状态变量
    self.Dragging = false               -- 是否正在拖拽
    self.DraggingEquipUid = nil         -- 正在拖拽的装备Uid
    self.DraggingFrom = nil             -- 拖拽来源（装备槽位或背包装备）
    self.DraggingFromIndex = nil        -- 拖拽来源的索引（槽位索引）
    ---@type XUiGridDlcRelinkEquipment
    self.DragCloneGrid = nil            -- 拖拽中的克隆格子
    self.HoverSlotIndex = nil           -- 当前悬停的槽位索引
    self.HoverInList = false            -- 当前是否悬停在背包列表区域
    -- 长按状态变量
    ---@type XUiGridDlcRelinkEquipment
    self.PressingGrid = nil             -- 当前正在长按交互的Grid引用
    self.IsPressing = false             -- 是否正在长按加载进度
    self.DragTriggered = false          -- 是否已触发拖拽
    self.PressCancelled = false         -- 本次按压是否已取消长按

    self._screenVec2 = CS.UnityEngine.Vector2(0, 0)
    self._dragVec2 = CS.UnityEngine.Vector2(0, 0)
    self._hideVec2 = CS.UnityEngine.Vector2(-99999, -99999)

    if self.PanelEquipScroll then
        -- 列表区域hover监听，用于判断拖拽释放位置
        self:AddPointerEnterExitListener(self.PanelEquipScroll.gameObject, handler(self, self.OnPointerEnterBgList), handler(self, self.OnPointerExitBgList))
        ---@type UnityEngine.UI.ScrollRect
        self.EquipScrollRect = self.PanelEquipScroll.transform:GetComponent(typeof(CS.UnityEngine.UI.ScrollRect))
    end
end

function XUiDlcRelinkEquipBag:OnStart(characterId, slotIndex)
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self.CharacterId = characterId
    self.CurSelectSlotIndex = XTool.IsNumberValid(slotIndex) and slotIndex or EquipSlotIndex.MainSlot
    self.CurSelectSlotEquipUid = self._Control:GetEquipUidByCharacterId(self.CharacterId, self.CurSelectSlotIndex)

    self.DefaultSelectTabIndex = 0 -- 进入时默认选择的Tab下标
    self.CurSelectTabIndex = -1 -- 当前选择的Tab下标

    self.CurSelectGrid = nil
    self.CurSelectEquipUid = 0

    self:InitPanelTab()
    self:InitDynamicTable()

    -- 先确定进入时的默认槽位与装备选择
    self:EnsureInitialSelection()
end

function XUiDlcRelinkEquipBag:OnEnable()
    self.Super.OnEnable(self)
    self:ValidateEquipSlotData()
    self:RefreshPanelEquipment()
    self.PanelTab:SelectIndex(self.DefaultSelectTabIndex)
end

function XUiDlcRelinkEquipBag:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_RELINK_EQUIP_COMPOSE_SUCCESS,
    }
end

function XUiDlcRelinkEquipBag:OnNotify(event, ...)
    if event == XEventId.EVENT_DLC_RELINK_EQUIP_COMPOSE_SUCCESS then
        self:SetupDynamicTable()
    end
end

function XUiDlcRelinkEquipBag:OnDisable()
    self.Super.OnDisable(self)
    self.EquipFilterCache = {}
    -- 记录当前职业Tab为下次默认选择
    if self.CurSelectTabIndex >= 0 then
        self.DefaultSelectTabIndex = self.CurSelectTabIndex
    end
    self.CurSelectTabIndex = -1
    -- 记录所有装备已查看状态
    self._Control:RecordAllEquipViewed()
    -- 是否进行槽位数据验证
    self.IsNeedValidateEquipSlotData = true
    -- 清理待选装备状态
    self._PendingSelectEquipUid = nil
    -- 清理拖拽状态
    self:ClearDragState()
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
            self.DefaultSelectTabIndex = occupationType
        end
        return
    end

    -- 无槽位参数
    local unWeareEquipUids = self._Control:GetUnWearEquipUidListBySlot(self.CurSelectSlotIndex)
    local hasAnyEquip = not XTool.IsTableEmpty(unWeareEquipUids)

    if hasAnyEquip then
        -- 情况2：背包有装备，选中全部页签
        self.DefaultSelectTabIndex = 0
    else
        -- 情况3：背包无装备，按优先级找已穿戴
        local slot, uid = self:FindFirstWornEquipByPriority()
        if XTool.IsNumberValid(uid) then
            self.CurSelectSlotIndex = slot
            self.CurSelectSlotEquipUid = uid
            local occupationType = self:GetEquipOccupationTypeByUid(uid)
            if XTool.IsNumberValid(occupationType) then
                self.DefaultSelectTabIndex = occupationType
            end
        else
            -- 默认到主槽 + 全部
            self.CurSelectSlotIndex = EquipSlotIndex.MainSlot
            self.CurSelectSlotEquipUid = 0
            self.DefaultSelectTabIndex = 0
        end
    end
end

--endregion

--region 左侧装备槽位

-- 验证槽位数据
function XUiDlcRelinkEquipBag:ValidateEquipSlotData()
    if not self.IsNeedValidateEquipSlotData then
        return
    end
    self.IsNeedValidateEquipSlotData = false

    local isUnLock = self._Control:CheckEquipSlotIsUnlocked(self.CharacterId, self.CurSelectSlotIndex)
    if not isUnLock then
        -- 当前槽位已锁定，切回主槽
        self.CurSelectSlotIndex = EquipSlotIndex.MainSlot
    end

    local equipUid = self._Control:GetEquipUidByCharacterId(self.CharacterId, self.CurSelectSlotIndex)
    if equipUid ~= self.CurSelectSlotEquipUid then
        -- 当前槽位装备已变化，更新记录
        self.CurSelectSlotEquipUid = equipUid
    end
end

function XUiDlcRelinkEquipBag:RefreshPanelEquipment()
    -- 装备总战力
    self.TxtLv.text = self._Control:GetEquipTotalAbilityByCharacterId(self.CharacterId)
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
            -- 缓存 PanelGlow 引用
            self.PanelGlowList[index] = self[string.format("PanelGlow0%s", index)]
            -- 槽位hover监听（用于拖拽悬停检测）
            self:AddPointerEnterExitListener(parent.gameObject, function() self:OnPointerEnterSlot(slotIndex) end, function() self:OnPointerExitSlot(slotIndex) end)
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
        grid:SetIsEquipSlot(true)
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:OnEquipSlotCallBack(grid)
    if self.Dragging then
        return
    end

    local slotIndex = grid:GetSlotIndex()
    local isUnLock, unlockDesc = self._Control:CheckEquipSlotIsUnlocked(self.CharacterId, slotIndex)
    if not isUnLock then
        self._Control:OpenCommonTipMsg(unlockDesc)
        return
    end

    if self.CurSelectSlotIndex == slotIndex and self.CurSelectSlotEquipUid == self.CurSelectEquipUid then
        return
    end
    self:SetCurrentSlot(slotIndex)
    local defaultIndex = self.CurSelectTabIndex
    if defaultIndex < 0 then
        defaultIndex = self:GetDefaultSelectEquipOccupationIndex()
    end
    self.CurSelectTabIndex = -1
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
    return 0
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
    local totalAttributes = self._Control:GetEquipTotalAttributeList(self.CharacterId, equipUids)
    for index, attribute in ipairs(totalAttributes) do
        local grid = self.EquipTotalAttributeGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridAttribute, self.PaneAttribute)
            grid = XUiGridDlcRelinkEquipAttribute.New(go, self)
            self.EquipTotalAttributeGridList[index] = grid
        end
        grid:Open()
        grid:CustomRefresh(attribute)
        grid:SetBg(index % 2 ~= 0)
    end

    for i = #totalAttributes + 1, #self.EquipTotalAttributeGridList do
        local grid = self.EquipTotalAttributeGridList[i]
        if grid then
            grid:Close()
        end
    end
end

function XUiDlcRelinkEquipBag:CheckExtendSlotAndMainSlotWearEquip()
    return self.CurSelectSlotIndex >= EquipSlotIndex.NormalExpandBegin and self.CurSelectSlotIndex < EquipSlotIndex.NormalSlotBegin
end

--endregion

--region 装备背包

function XUiDlcRelinkEquipBag:InitPanelTab()
    self.EquipBtnTabList = {}
    -- 收集并排序
    local sortedTagTypes = {}
    for key, value in pairs(self._Control.EquipTagType) do
        table.insert(sortedTagTypes, { Key = key, Value = value })
    end
    table.sort(sortedTagTypes, function(a, b)
        return a.Value < b.Value
    end)
    -- 创建Tab按钮
    for _, tagTypeInfo in ipairs(sortedTagTypes) do
        local index = tagTypeInfo.Value
        ---@type XUiComponent.XUiButton
        local btnTab = XUiHelper.Instantiate(self.BtnTab, self.PanelTab.transform)
        btnTab.gameObject:SetActiveEx(true)

        local tabDesc = self._Control:GetClientConfig("EquipTabsDesc", index + 1)
        btnTab:SetNameByGroup(0, tabDesc)

        local tabIcon = self._Control:GetClientConfig("EquipTabsIcon", index + 1)
        btnTab:SetSprite(tabIcon)

        self.EquipBtnTabList[index] = btnTab
    end
    self.PanelTab:Init(self.EquipBtnTabList, handler(self, self.OnEquipBtnTabClick))
end

function XUiDlcRelinkEquipBag:OnEquipBtnTabClick(index)
    if self.CurSelectTabIndex == index then
        return
    end
    self.CurSelectTabIndex = index
    -- 重置装备筛选缓存
    self.EquipFilterCache = {}
    self:SetupDynamicTable()
    self:RefreshEquipFilter()
    self:RefreshEquipTabRedPoint()
end

function XUiDlcRelinkEquipBag:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkEquipment, self, handler(self, self.OnEquipItemCallBack))
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkEquipBag:SetupDynamicTable()
    -- 装备类型(默认筛选条件)
    self.EquipFilterCache.EquipType = self.CurSelectSlotIndex == EquipSlotIndex.MainSlot and XEnumConst.DlcRelink.EquipType.Main or XEnumConst.DlcRelink.EquipType.Normal
    self.EquipUidList = self._Control:GetEquipUidListByTagType(self.CurSelectTabIndex, self._Control.EquipUiType.Bg, self.EquipFilterCache, self.CharacterId)
    local isEmpty = XTool.IsTableEmpty(self.EquipUidList)
    self.None.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        self.DynamicTable:Clear()
        self.CurSelectEquipUid = self.CurSelectSlotEquipUid
        self.CurSelectGrid = nil
        self:RefreshEquipDetail()
        return
    end

    self:SortNewEquipFirst(self.EquipUidList)

    self.CurSelectEquipUid = self.CurSelectSlotEquipUid
    self.CurSelectGrid = nil
    local index = self:GetDefaultSelectEquipUidIndex()

    -- 若有待选装备（如卸下后自动选中），优先使用
    if XTool.IsNumberValid(self._PendingSelectEquipUid) then
        for i, uid in ipairs(self.EquipUidList) do
            if uid == self._PendingSelectEquipUid then
                self.CurSelectEquipUid = self._PendingSelectEquipUid
                index = i
                break
            end
        end
        self._PendingSelectEquipUid = nil
    end

    self.DynamicTable:SetDataSource(self.EquipUidList)
    self.DynamicTable:ReloadDataSync(index)
end

--- 将新获得（未查看）的装备按原来的顺序排在列表最前面
---@param equipUidList number[]
function XUiDlcRelinkEquipBag:SortNewEquipFirst(equipUidList)
    local n = #equipUidList
    if n <= 1 then
        return
    end
    local newList = {}
    local newCount = 0
    local oldList = {}
    local oldCount = 0
    for i = 1, n do
        local uid = equipUidList[i]
        if not self._Control:CheckEquipViewed(uid) then
            newCount = newCount + 1
            newList[newCount] = uid
        else
            oldCount = oldCount + 1
            oldList[oldCount] = uid
        end
    end
    -- 全部同类型（全新或全旧）无需重排
    if newCount == 0 or oldCount == 0 then
        return
    end
    -- 回写：新装备在前，旧装备在后
    for i = 1, newCount do
        equipUidList[i] = newList[i]
    end
    for i = 1, oldCount do
        equipUidList[newCount + i] = oldList[i]
    end
end

function XUiDlcRelinkEquipBag:GetDefaultSelectEquipUidIndex()
    if XTool.IsNumberValid(self.CurSelectSlotEquipUid) then
        for i, uid in ipairs(self.EquipUidList) do
            if uid == self.CurSelectSlotEquipUid then
                return i
            end
        end
    else
        for i, uid in ipairs(self.EquipUidList) do
            local wearCharacterId = self._Control:GetEquipWearCharacterId(uid)
            if not XTool.IsNumberValid(wearCharacterId) then
                self.CurSelectEquipUid = uid
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
        grid:SetPreset(self._Control:CheckEquipIsPresetByEquipUid(equipUid))
        local isSelected = equipUid == self.CurSelectEquipUid
        grid:SetSelect(isSelected)
        if isSelected and not self.CurSelectGrid then
            self.CurSelectGrid = grid
            self:RecordEquipViewed()
        end
        grid:SetRedDot(not self._Control:CheckEquipViewed(equipUid))
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:RefreshEquipDetail()
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:OnEquipItemCallBack(grid)
    if self.Dragging then
        return
    end

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
    self:RefreshEquipTabRedPoint()
end

function XUiDlcRelinkEquipBag:RefreshEquipTabRedPoint()
    local equipDataList = self._Control:GetEquipsDataList()
    local equipType = self.EquipFilterCache.EquipType
    local tabRedDict = {}

    if not XTool.IsTableEmpty(equipDataList) then
        for _, equipData in pairs(equipDataList) do
            local templateId = equipData:GetTemplateId()
            if equipType == self._Control:GetEquipType(templateId) then
                local occupationType = self._Control:GetEquipOccupationType(templateId)
                if not tabRedDict[occupationType] then
                    local equipUid = equipData:GetUid()
                    if not self._Control:CheckEquipViewed(equipUid) then
                        tabRedDict[occupationType] = true
                        -- 全部Tab红点
                        tabRedDict[self._Control.EquipTagType.All] = true
                    end
                end
            end
        end
    end

    for i = 0, #self.EquipBtnTabList do
        local isRed = tabRedDict[i] or false
        self.EquipBtnTabList[i]:ShowReddot(isRed)
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

--region 词条等级溢出检查

--- 构建穿戴指定装备到指定槽位后的装备快照
---@param targetSlotIndex number 目标槽位
---@param equipUid number 要穿戴的装备Uid
---@return table<number, number> 穿戴后的装备Uid映射 key: 槽位索引, value: 装备Uid
function XUiDlcRelinkEquipBag:BuildWearEquipSnapshot(targetSlotIndex, equipUid)
    local equipDict = self._Control:GetWearEquipUidsByCharacterId(self.CharacterId)
    local equipUids = {}
    local fromSlot = 0

    -- 先拷贝现有穿戴并定位被选装备所在槽位
    local equipSlotIndexMap = self._Control:GetEquipSlotIndexMap()
    for _, slotIndex in ipairs(equipSlotIndexMap) do
        local uid = equipDict[slotIndex]
        if XTool.IsNumberValid(uid) then
            equipUids[slotIndex] = uid
            if uid == equipUid then
                fromSlot = slotIndex
            end
        end
    end

    -- 将装备放入目标槽位
    equipUids[targetSlotIndex] = equipUid

    -- 如果装备原本穿戴在其他槽位，需要处理原槽位
    if fromSlot > 0 and fromSlot ~= targetSlotIndex then
        -- 清除来源槽位
        equipUids[fromSlot] = nil
    end

    return equipUids
end

--- 检查穿戴装备后词条等级是否溢出，如溢出则弹二次确认
---@param targetSlotIndex number 目标槽位
---@param equipUid number 要穿戴的装备Uid
---@param callback function 确认或无溢出时的回调
function XUiDlcRelinkEquipBag:CheckAndConfirmFactorOverflow(targetSlotIndex, equipUid, callback)
    local equipUids = self:BuildWearEquipSnapshot(targetSlotIndex, equipUid)
    local overflowList = self._Control:CheckEquipFactorLevelOverflow(self.CharacterId, equipUids, equipUid)
    if not XTool.IsTableEmpty(overflowList) then
        local title = self._Control:GetClientConfig("TipTitle")
        local data = self._Control:GetClientConfigParams("EquipFactorOverflowWearTipContent")
        local content = data[1] or ""
        local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "EquipFactorOverflowWearTip" }

        local descriptions = {}
        local factorOverflowDesc = self._Control:GetClientConfig("EquipFactorOverflowDesc")
        for _, info in ipairs(overflowList) do
            table.insert(descriptions, string.format(factorOverflowDesc, info.Name, info.CurLevel, info.MaxLevel))
        end

        local factorStr = table.concat(descriptions, "\n")
        content = XUiHelper.ConvertLineBreakSymbol(content)
        content = XUiHelper.FormatText(content, factorStr)
        self._Control:OpenCommonTipDialog(title, content, nil, callback, extraData)
        return
    end
    if callback then
        callback()
    end
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
    self:RefreshOneClickEquipBtn()
end

---@param attribute XDlcRelinkEquipAttribute
function XUiDlcRelinkEquipBag:CheckEquipFactorIsUnlock(attribute)
    if not XTool.IsNumberValid(self.CurSelectEquipUid) then
        return true, ""
    end
    if not self._Control:CheckFactorIsConditionalFactor(attribute.FactorId) then
        return true, ""
    end
    local equipUids = self:BuildWearEquipSnapshot(self.CurSelectSlotIndex, self.CurSelectEquipUid)
    return self._Control:CheckEquipFactorIsUnlock(attribute.FactorId, self.CharacterId, equipUids)
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

    local isHasSlot = self._Control:CheckEquipHasDeputyFactorSlot(self.CurSelectEquipUid)
    self.BtnReform:SetDisable(not isHasSlot)

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
    local color = self._Control:GetClientConfig("EquipFilterBtnColor", isFilter and 2 or 1)
    self.BtnFilter:SetImgRGB(XUiHelper.Hexcolor2Color(color))
end

-- 检查当前筛选条件是否有生效
function XUiDlcRelinkEquipBag:CheckFilterCache()
    if XTool.IsTableEmpty(self.EquipFilterCache) then
        return false
    end

    if XTool.IsNumberValid(self.EquipFilterCache.ReformedType)
        or XTool.IsNumberValid(self.EquipFilterCache.EquipQuality)
        or XTool.IsNumberValid(self.EquipFilterCache.EquipDiscard)
        or not XTool.IsTableEmpty(self.EquipFilterCache.FactorIds) then
        return true
    end

    return false
end

function XUiDlcRelinkEquipBag:RefreshOneClickEquipBtn()
    local equipInfoList = self._Control:CalcOneKeyEquipPlan(self.CharacterId)
    local _, hasAnyChange = self:CheckOneKeyEquipPlanChanged(equipInfoList)
    self.BtnOneClickEquip:ShowReddot(hasAnyChange)
end

--endregion

--region 筛选相关

function XUiDlcRelinkEquipBag:RefreshEquipFilter()
    ---@type XUiDlcRelinkPopupFilter
    local luaUi = XLuaUiManager.GetTopLuaUi("UiDlcRelinkPopupFilter")
    if luaUi then
        local equipMainFactorIds = self._Control:GetEquipMainFactorIds(self.EquipUidList)
        luaUi:RefreshFilter(equipMainFactorIds, self.EquipFilterCache)
    end
end

--endregion

--region 拖拽逻辑

-- 进入/离开监听绑定（用于拖拽悬停检测）
function XUiDlcRelinkEquipBag:AddPointerEnterExitListener(go, onEnter, onExit)
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
    return listener
end

--region 拖拽 hover 监听

function XUiDlcRelinkEquipBag:OnPointerEnterBgList()
    if not self.Dragging then
        return
    end
    self.HoverInList = true
end

function XUiDlcRelinkEquipBag:OnPointerExitBgList()
    if not self.Dragging then
        return
    end
    self.HoverInList = false
end

function XUiDlcRelinkEquipBag:OnPointerEnterSlot(slotIndex)
    if not self.Dragging then
        return
    end
    self.HoverSlotIndex = slotIndex
    self:UpdateSlotHoverState()
end

function XUiDlcRelinkEquipBag:OnPointerExitSlot(slotIndex)
    if not self.Dragging then
        return
    end
    if self.HoverSlotIndex == slotIndex then
        self.HoverSlotIndex = nil
        self:UpdateSlotHoverState()
    end
end

--endregion

--region 拖拽辅助方法

-- 判断拖拽来源是否为装备槽位
function XUiDlcRelinkEquipBag:IsDragFromSlot()
    return self.DraggingFrom == DraggingFromType.EquipSlot
end

--- 根据当前拖拽状态和悬停位置，解析应执行的拖拽操作
---@return number action DragAction 枚举值
---@return number|nil targetIndex 目标槽位索引（Equip/Swap）或来源槽位索引（Unequip）
function XUiDlcRelinkEquipBag:ResolveDragAction()
    local toSlot = self.HoverSlotIndex and self.HoverSlotIndex > 0
    if toSlot then
        if self:IsDragFromSlot() and self.DraggingFromIndex then
            -- 槽位 → 槽位：交换
            return DragAction.Swap, self.HoverSlotIndex
        else
            -- 背包 → 槽位：穿戴/更换
            return DragAction.Equip, self.HoverSlotIndex
        end
    elseif self:IsDragFromSlot() and self.DraggingFromIndex and self.HoverInList then
        -- 槽位 → 背包列表：卸下
        return DragAction.Unequip, self.DraggingFromIndex
    end
    return DragAction.Cancel, nil
end

--endregion

--region 拖拽生命周期

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:StartDrag(grid)
    if self.Dragging then
        return
    end
    local equipUid = grid and grid:GetEquipUid() or 0
    if not XTool.IsNumberValid(equipUid) then
        return
    end

    self.Dragging = true
    self.DraggingEquipUid = equipUid
    local isEquipSlot = grid:GetIsEquipSlot()
    self.DraggingFrom = isEquipSlot and DraggingFromType.EquipSlot or DraggingFromType.BagEquip
    self.DraggingFromIndex = isEquipSlot and grid:GetSlotIndex() or nil

    -- 创建拖拽克隆
    ---@type XUiGridDlcRelinkEquipment
    local dragGrid = self.DragCloneGrid
    if not dragGrid then
        local go = XUiHelper.Instantiate(self.GridEquipment, self.PanelDrag.transform)
        dragGrid = XUiGridDlcRelinkEquipment.New(go, self)
        self.DragCloneGrid = dragGrid

        -- 提升层级
        local order = self.PanelDrag.sortingOrder + 5
        dragGrid:SetOverrideSorting(true, order)
        -- 禁用射线检测
        ---@type UnityEngine.CanvasGroup
        local canvasGroup = dragGrid.GameObject:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
        if XTool.UObjIsNil(canvasGroup) then
            canvasGroup = dragGrid.GameObject:AddComponent(typeof(CS.UnityEngine.CanvasGroup))
        end
        canvasGroup.blocksRaycasts = false
    end
    dragGrid:Open()
    dragGrid:SetIsDragClone(true)
    dragGrid:SetOnDrag(true)
    dragGrid:Refresh(equipUid)

    -- 禁用列表滑动，显示槽位可放入状态，开始追踪
    self:SetScrollEnabled(false)
    self:UpdateSlotCanDropState()
    self:StartDragTracking()
end

function XUiDlcRelinkEquipBag:EndDrag()
    if not self.Dragging then
        return
    end

    local action, targetIndex = self:ResolveDragAction()
    if action == DragAction.Equip then
        self:HandleDragEquip(targetIndex, self.DraggingEquipUid)
    elseif action == DragAction.Swap then
        self:HandleDragSwap(self.DraggingFromIndex, targetIndex, self.DraggingEquipUid)
    elseif action == DragAction.Unequip then
        self:HandleDragUnequip(targetIndex)
    end

    self:ClearDragState()
end

function XUiDlcRelinkEquipBag:ClearDragState()
    self:StopDragTracking()
    self:SetScrollEnabled(true)
    -- 重置长按状态
    self:ClearPressState()
    self.Dragging = false
    self.DraggingEquipUid = nil
    self.DraggingFrom = nil
    self.DraggingFromIndex = nil
    self.HoverSlotIndex = nil
    self.HoverInList = false
    if self.DragCloneGrid then
        self.DragCloneGrid:Close()
    end
    self:ClearSlotDragStates()
end

--endregion

--region 拖拽追踪

-- 获取当前手指/鼠标屏幕坐标
function XUiDlcRelinkEquipBag:GetScreenPoint()
    if CS.UnityEngine.Input.touchCount > 0 then
        return CS.UnityEngine.Input.GetTouch(0).position
    elseif CS.UnityEngine.Input.GetMouseButton(0) then
        return CS.UnityEngine.Input.mousePosition
    end
    return nil
end

-- 获取当前手指/鼠标在UI根节点下的本地坐标
function XUiDlcRelinkEquipBag:GetScreenLocalPos(screenPos)
    screenPos = screenPos or self:GetScreenPoint()
    if not screenPos then
        return nil
    end
    self._screenVec2.x = screenPos.x
    self._screenVec2.y = screenPos.y
    local ok, point = CS.UnityEngine.RectTransformUtility.ScreenPointToLocalPointInRectangle(self.PanelDrag.transform, self._screenVec2, CS.XUiManager.Instance.UiCamera)
    if not ok then
        return nil
    end
    return point
end

-- 开始拖拽追踪（用定时器读取屏幕坐标，代替Drag事件，避免拦截ScrollRect）
-- 定时器同时负责：1)位置追踪 2)手指抬起检测
function XUiDlcRelinkEquipBag:StartDragTracking()
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
            -- 手指真正抬起
            self:EndDrag()
            return
        end
        self:RefreshDragClonePos(screenPos)
    end, 0)
end

function XUiDlcRelinkEquipBag:RefreshDragClonePos(screenPos)
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

function XUiDlcRelinkEquipBag:StopDragTracking()
    if self.DragTrackingTimer then
        XScheduleManager.UnSchedule(self.DragTrackingTimer)
        self.DragTrackingTimer = nil
    end
end

--endregion

--region 槽位拖拽视觉状态

-- 更新所有槽位的「可放入」状态
function XUiDlcRelinkEquipBag:UpdateSlotCanDropState()
    if not self.Dragging then
        return
    end
    for index, grid in ipairs(self.EquipmentGridList) do
        if grid then
            local canDrop = self:CheckEquipCanDropToSlot(self.DraggingEquipUid, grid:GetSlotIndex(), grid:GetEquipUid())
            local panelGlow = self.PanelGlowList[index]
            if panelGlow then
                panelGlow.gameObject:SetActiveEx(true)
                panelGlow:GetObject("ImgAvailableGlow").gameObject:SetActiveEx(canDrop)
                panelGlow:GetObject("ImgConfirmGlow").gameObject:SetActiveEx(false)
            end
        end
    end
end

-- 更新槽位的「将放入」悬停状态
function XUiDlcRelinkEquipBag:UpdateSlotHoverState()
    local hoverSlotIndex = self.Dragging and self.HoverSlotIndex or 0
    for index, grid in ipairs(self.EquipmentGridList) do
        if grid then
            local slotIndex = grid:GetSlotIndex()
            local isHover = hoverSlotIndex == slotIndex
            if isHover then
                isHover = self:CheckEquipCanDropToSlot(self.DraggingEquipUid, slotIndex, grid:GetEquipUid())
            end
            local panelGlow = self.PanelGlowList[index]
            if panelGlow then
                panelGlow:GetObject("ImgConfirmGlow").gameObject:SetActiveEx(isHover)
            end
        end
    end
end

-- 清除所有槽位的拖拽视觉状态
function XUiDlcRelinkEquipBag:ClearSlotDragStates()
    for index, _ in ipairs(self.EquipmentGridList) do
        local panelGlow = self.PanelGlowList[index]
        if panelGlow then
            panelGlow.gameObject:SetActiveEx(false)
        end
    end
end

-- 检查装备是否可以放入指定槽位
function XUiDlcRelinkEquipBag:CheckEquipCanDropToSlot(equipUid, slotIndex, curSlotEquipUid)
    if not XTool.IsNumberValid(equipUid) or not XTool.IsNumberValid(slotIndex) then
        return false
    end
    -- 当前槽位已穿戴该装备
    if XTool.IsNumberValid(curSlotEquipUid) and curSlotEquipUid == equipUid then
        return false
    end
    -- 槽位未解锁
    local isUnLock = self._Control:CheckEquipSlotIsUnlocked(self.CharacterId, slotIndex)
    if not isUnLock then
        return false
    end
    -- 装备类型匹配
    local templateId = self._Control:GetEquipTemplateIdByEquipUid(equipUid)
    if not XTool.IsNumberValid(templateId) then
        return false
    end
    local equipType = self._Control:GetEquipType(templateId)
    local isMainSlot = slotIndex == EquipSlotIndex.MainSlot
    if isMainSlot then
        return equipType == XEnumConst.DlcRelink.EquipType.Main
    else
        return equipType == XEnumConst.DlcRelink.EquipType.Normal
    end
end

--endregion

--region 拖拽结果处理

--- 装备变更后统一刷新界面
function XUiDlcRelinkEquipBag:RefreshAfterEquipChange()
    -- 强制验证槽位数据一致性
    self.IsNeedValidateEquipSlotData = true
    self:ValidateEquipSlotData()
    self:RefreshPanelEquipment()
    self:SetupDynamicTable()
    XDataCenter.GuideManager.CheckGuideOpen()
end

--- 执行穿戴请求，若装备被其他角色穿戴则弹确认框
---@param targetSlotIndex number 目标槽位
---@param equipUid number 装备Uid
---@param onComplete function 穿戴成功回调
function XUiDlcRelinkEquipBag:RequestWearEquipWithConfirm(targetSlotIndex, equipUid, onComplete)
    local wearCharacterId = self._Control:GetEquipWearCharacterId(equipUid)
    if XTool.IsNumberValid(wearCharacterId) and wearCharacterId ~= self.CharacterId then
        local characterName = XMVCA.XCharacter:GetCharacterName(wearCharacterId)
        local title = self._Control:GetClientConfig("TipTitle")
        local data = self._Control:GetClientConfigParams("EquipReplaceWearTipContent")
        local content = string.format(data[1] or "", characterName)
        local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "EquipReplaceWearTip" }
        self._Control:OpenCommonTipDialog(title, content, nil, function()
            self._Control:RequestWearEquip(self.CharacterId, targetSlotIndex, equipUid, onComplete)
        end, extraData)
        return
    end
    self._Control:RequestWearEquip(self.CharacterId, targetSlotIndex, equipUid, onComplete)
end

--- 处理穿戴前的二次确认弹框，按顺序执行：
--- 1. 词条等级溢出检查
--- 2. 装备被其他角色穿戴检查
--- 全部通过后执行穿戴请求
---@param targetSlotIndex number 目标槽位
---@param equipUid number 装备Uid
---@param onComplete function 穿戴成功回调
function XUiDlcRelinkEquipBag:WearEquipWithAllConfirms(targetSlotIndex, equipUid, onComplete)
    self:CheckAndConfirmFactorOverflow(targetSlotIndex, equipUid, function()
        self:RequestWearEquipWithConfirm(targetSlotIndex, equipUid, onComplete)
    end)
end

-- 背包装备拖拽到槽位 → 穿戴/更换
function XUiDlcRelinkEquipBag:HandleDragEquip(targetSlotIndex, equipUid)
    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end
    -- 验证可放入目标槽位
    local curSlotEquipUid = self._Control:GetEquipUidByCharacterId(self.CharacterId, targetSlotIndex)
    if not self:CheckEquipCanDropToSlot(equipUid, targetSlotIndex, curSlotEquipUid) then
        return
    end
    self:WearEquipWithAllConfirms(targetSlotIndex, equipUid, handler(self, self.RefreshAfterEquipChange))
end

-- 槽位间拖拽 → 交换装备
function XUiDlcRelinkEquipBag:HandleDragSwap(fromSlotIndex, toSlotIndex, equipUid)
    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end
    -- 验证来源槽位仍持有该装备
    local fromEquipUid = self._Control:GetEquipUidByCharacterId(self.CharacterId, fromSlotIndex)
    if fromEquipUid ~= equipUid then
        return
    end
    -- 验证可放入目标槽位
    local toSlotEquipUid = self._Control:GetEquipUidByCharacterId(self.CharacterId, toSlotIndex)
    if not self:CheckEquipCanDropToSlot(equipUid, toSlotIndex, toSlotEquipUid) then
        return
    end
    self:WearEquipWithAllConfirms(toSlotIndex, equipUid, handler(self, self.RefreshAfterEquipChange))
end

-- 从槽位拖到背包列表区域 → 卸下装备
function XUiDlcRelinkEquipBag:HandleDragUnequip(fromSlotIndex)
    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end
    -- 验证该槽位确实穿戴了装备
    local equipUid = self._Control:GetEquipUidByCharacterId(self.CharacterId, fromSlotIndex)
    if not XTool.IsNumberValid(equipUid) then
        return
    end

    self._Control:RequestUnWearEquip(self.CharacterId, fromSlotIndex, function()
        -- 强制验证槽位数据一致性
        self.IsNeedValidateEquipSlotData = true
        self:ValidateEquipSlotData()
        -- 卸下后在背包列表中自动选中该装备
        self._PendingSelectEquipUid = equipUid
        self:RefreshPanelEquipment()
        self:SetupDynamicTable()
    end)
end

--endregion

--region 长按进度条

-- 装备格子按下
---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:OnGridPointerDown(grid)
    if self.PressingGrid and self.PressingGrid ~= grid then
        return
    end
    -- 正在拖拽不响应
    if self.Dragging then
        return
    end
    -- 注册为当前长按交互Grid，重置状态标记
    self.PressingGrid = grid
    self.PressCancelled = false
    self.DragTriggered = false
end

-- 装备格子长按触发（持续按压达到长按时间后调用）
---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:OnGridPress(grid)
    if self.DragTriggered then
        return
    end
    if self.PressingGrid ~= grid then
        return
    end
    if self.PressCancelled then
        return
    end
    -- 开始长按，显示进度条
    if not self.IsPressing then
        self.IsPressing = true
        self:ShowPressProgress(grid.PressProgressTarget, function()
            self.IsPressing = false
            self.DragTriggered = true
            self:StartDrag(grid)
            self:HidePressProgress()
        end)
    end
end

-- 装备格子取消长按（如拖出范围）或抬起
---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:OnGridPointerUp(grid)
    if self.PressingGrid ~= grid then
        return
    end
    self:CancelPress()
    self.PressingGrid = nil
end

-- 装备格子取消（如拖出范围）
---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:OnGridPointerExit(grid)
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
function XUiDlcRelinkEquipBag:ShowPressProgress(targetTransform, onComplete)
    if not self.PressProgress then
        local path = self._Control:GetClientConfig("LongPressProgressBarPath")
        local panelTimerGo = self.PanelDrag.transform:LoadPrefabEx(path)
        local order = self.PanelDrag.sortingOrder + 3
        ---@type XUiPanelLongPressProgress
        self.PressProgress = XUiPanelLongPressProgress.New(panelTimerGo, self, order)
    end
    self.PressProgress:Open()
    self.PressProgress:Refresh(targetTransform, onComplete)
end

-- 隐藏长按进度条
function XUiDlcRelinkEquipBag:HidePressProgress()
    if self.PressProgress then
        self.PressProgress:Close()
    end
end

-- 取消长按
function XUiDlcRelinkEquipBag:CancelPress()
    if self.IsPressing then
        self.IsPressing = false
        self.PressCancelled = true
        self:HidePressProgress()
    end
end

-- 重置所有长按状态变量
function XUiDlcRelinkEquipBag:ClearPressState()
    if self.IsPressing then
        self:HidePressProgress()
    end
    self.PressingGrid = nil
    self.IsPressing = false
    self.DragTriggered = false
    self.PressCancelled = false
end

--endregion

--region 列表滚动控制

-- 启用/禁用列表滚动（拖拽时需禁用，避免列表跟着滚动）
function XUiDlcRelinkEquipBag:SetScrollEnabled(enabled)
    if self.EquipScrollRect then
        self.EquipScrollRect.enabled = enabled
    end
end

--endregion

--endregion

function XUiDlcRelinkEquipBag:RegisterUiEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnAttribute:AddEventListener(handler(self, self.OnBtnAttributeClick))
    self.BtnReform:AddEventListener(handler(self, self.OnBtnReformClick))
    self.BtnReplace:AddEventListener(handler(self, self.OnBtnReplaceClick))
    self.BtnRemove:AddEventListener(handler(self, self.OnBtnRemoveClick))
    self.BtnFilter:AddEventListener(handler(self, self.OnBtnFilterClick))
    self.BtnBreakdown:AddEventListener(handler(self, self.OnBtnBreakdownClick))
    self.BtnSynthesis:AddEventListener(handler(self, self.OnBtnSynthesisClick))
    self.BtnOneClickEquip:AddEventListener(handler(self, self.OnBtnOneClickEquipClick))
end

function XUiDlcRelinkEquipBag:OnBtnBackClick()
    XLuaUiManager.SafeClose("UiDlcRelinkPopupFilter")
    self:Close()
end

-- 打开属性详情弹窗
function XUiDlcRelinkEquipBag:OnBtnAttributeClick()
    local equipUids = self:BuildEquipUidsSnapshot()
    if XTool.IsTableEmpty(equipUids) then
        return
    end
    local totalAttributes = self._Control:GetEquipTotalAttributeList(self.CharacterId, equipUids)
    if XTool.IsTableEmpty(totalAttributes) then
        return
    end
    XLuaUiManager.Open("UiDlcRelinkPopupEquipAttributeDetail", self.CharacterId, totalAttributes)
end

-- 改造装备
function XUiDlcRelinkEquipBag:OnBtnReformClick()
    if not XTool.IsNumberValid(self.CurSelectEquipUid) then
        return
    end
    local isHasSlot = self._Control:CheckEquipHasDeputyFactorSlot(self.CurSelectEquipUid)
    if not isHasSlot then
        self._Control:OpenCommonTipText("EquipReformAbsorbFullTips")
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

    self:WearEquipWithAllConfirms(self.CurSelectSlotIndex, self.CurSelectEquipUid, function()
        self.CurSelectSlotEquipUid = self.CurSelectEquipUid
        self:RefreshPanelEquipment()
        self:SetupDynamicTable()
        -- 检查引导
        XDataCenter.GuideManager.CheckGuideOpen()
    end)
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
        self:SetupDynamicTable()
    end)
end

-- 打开筛选弹窗
function XUiDlcRelinkEquipBag:OnBtnFilterClick()
    if XLuaUiManager.IsUiShow("UiDlcRelinkPopupFilter") then
        XLuaUiManager.Close("UiDlcRelinkPopupFilter")
        return
    end

    local filterCache = {}
    filterCache.EquipType = self.CurSelectSlotIndex == EquipSlotIndex.MainSlot and XEnumConst.DlcRelink.EquipType.Main or XEnumConst.DlcRelink.EquipType.Normal
    local equipUidList = self._Control:GetEquipUidListByTagType(self.CurSelectTabIndex, self._Control.EquipUiType.Bg, filterCache)
    local equipMainFactorIds = self._Control:GetEquipMainFactorIds(equipUidList)
    XLuaUiManager.Open("UiDlcRelinkPopupFilter", equipMainFactorIds, self.EquipFilterCache, true, function()
        self:SetupDynamicTable()
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

--region 一键穿戴

--- 检查一键装备计划是否有实际变化
---@param equipInfoList table[] 装备计划列表
---@return boolean, boolean hasReplace, hasAnyChange
function XUiDlcRelinkEquipBag:CheckOneKeyEquipPlanChanged(equipInfoList)
    local hasReplace = false
    local hasAnyChange = false
    for _, info in pairs(equipInfoList) do
        local newValid = XTool.IsNumberValid(info.NewEquipUid)
        local curValid = XTool.IsNumberValid(info.CurrentEquipUid)
        if newValid and curValid and info.NewEquipUid ~= info.CurrentEquipUid then
            hasReplace = true
            hasAnyChange = true
            break
        elseif newValid and not curValid then
            -- 空槽位填充新装备
            hasAnyChange = true
        end
    end

    return hasReplace, hasAnyChange
end

--- 根据一键装备计划构建槽位->装备Uid的映射
---@param equipInfoList table[] 装备计划列表
---@param isReplace boolean 是否替换已有装备
---@return table<number, number> slotIndex -> equipUid
function XUiDlcRelinkEquipBag:BuildOneKeyEquipMap(equipInfoList, isReplace)
    local slotId2EquipUid = {}
    -- 已分配的装备Uid集合
    local usedEquipUids = {}
    for _, info in ipairs(equipInfoList) do
        local equipUid
        if not XTool.IsNumberValid(info.NewEquipUid) then
            -- 无新装备可分配，保留当前装备
            equipUid = info.CurrentEquipUid
        elseif not XTool.IsNumberValid(info.CurrentEquipUid) then
            -- 槽位无当前装备，直接穿戴新装备
            equipUid = info.NewEquipUid
        elseif info.NewEquipUid ~= info.CurrentEquipUid then
            -- 新旧装备不同，根据isReplace决定是否替换
            equipUid = isReplace and info.NewEquipUid or info.CurrentEquipUid
        else
            -- 新旧装备相同，保持不变
            equipUid = info.NewEquipUid
        end
        -- 同一装备只能分配给一个槽位，如果已被分配则该槽位不穿戴任何装备
        if XTool.IsNumberValid(equipUid) and usedEquipUids[equipUid] then
            equipUid = 0
        end
        if XTool.IsNumberValid(equipUid) then
            usedEquipUids[equipUid] = true
            slotId2EquipUid[info.SlotIndex] = equipUid
        end
    end
    return slotId2EquipUid
end

--- 执行一键穿戴请求
---@param equipInfoList table[] 装备计划列表
---@param isReplace boolean 是否替换已有装备
function XUiDlcRelinkEquipBag:DoOneClickEquip(equipInfoList, isReplace)
    local slotId2EquipUid = self:BuildOneKeyEquipMap(equipInfoList, isReplace)
    self._Control:RequestWearMultiEquip(self.CharacterId, slotId2EquipUid, handler(self, self.RefreshAfterEquipChange))
end

--- 一键穿戴入口
function XUiDlcRelinkEquipBag:OnBtnOneClickEquipClick()
    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end

    local equipInfoList = self._Control:CalcOneKeyEquipPlan(self.CharacterId)
    local hasReplace, hasAnyChange = self:CheckOneKeyEquipPlanChanged(equipInfoList)

    -- 没有任何变化时提示并返回
    if not hasAnyChange then
        self._Control:OpenCommonLeftTipDialog(self._Control:GetClientConfig("EquipOneClickWearNoChangeTip"))
        return
    end

    if hasReplace then
        local title = self._Control:GetClientConfig("TipTitle")
        local data = self._Control:GetClientConfigParams("EquipOneClickWearTipContent")
        local content = data[1] or ""
        local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "EquipOneClickWearTip" }
        self._Control:OpenCommonTipDialog(title, content, function()
            self:DoOneClickEquip(equipInfoList, false)
        end, function()
            self:DoOneClickEquip(equipInfoList, true)
        end, extraData)
        return
    end

    self:DoOneClickEquip(equipInfoList, true)
end

--endregion

return XUiDlcRelinkEquipBag
