local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
local XUiPanelDlcRelinkEquipDetail = require("XUi/XUiDlcRelink/Equip/Panel/XUiPanelDlcRelinkEquipDetail")
local XUiGridDlcRelinkEquipAttribute = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipAttribute")
---@class XUiDlcRelinkEquipReform : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelTab XUiButtonGroup
---@field BtnFilter XUiComponent.XUiButton
local XUiDlcRelinkEquipReform = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkEquipReform")

local EquipSlotType = {
    Reform = 1, -- 改造槽位
    Absorb = 2, -- 吸收槽位
}

function XUiDlcRelinkEquipReform:OnAwake()
    self.GridEquipment.gameObject:SetActiveEx(false)
    self.GridAttribute.gameObject:SetActiveEx(false)
    self.GridAttributeGroup.gameObject:SetActiveEx(false)
    self.GridNone.gameObject:SetActiveEx(false)
    self.Spacing.gameObject:SetActiveEx(false)
    self.BtnTab.gameObject:SetActiveEx(false)
    self.MaskDelete.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()

    ---@type XUiComponent.XUiButton[]
    self.EquipBtnTabList = {}
    ---@type XUiGridDlcRelinkEquipAttribute
    self.MainAttribute = nil
    ---@type table<number, UiObject>
    self.DeputyAttributeGroup = {}
    ---@type table<number, table<number, XUiGridDlcRelinkEquipAttribute>>
    self.DeputyAttributeNodes = {}

    --- 装备筛选数据缓存
    ---@type XDlcRelinkEquipFilterCache
    self.EquipFilterCache = {}
end

function XUiDlcRelinkEquipReform:OnStart(equipUid)
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self.CurSelectSlotIndex = EquipSlotType.Absorb
    self.CurReformSlotEquipUid = equipUid
    self.CurAbsorbSlotEquipUid = 0

    self.EquipOccupationDefaultIndex = 1 -- 进入时默认选择的职业Tab
    self.CurSelectEquipOccupationIndex = 0

    self.CurSelectGrid = nil
    self.CurSelectEquipUid = 0

    self:InitPanelTab()
    self:InitDynamicTable()
end

function XUiDlcRelinkEquipReform:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshEquipReform()
    self:RefreshEquipAbsorb()
    self:RefreshEquipSlotSelect()
    self:RefreshEquipDetail()
    self.PanelTab:SelectIndex(self.EquipOccupationDefaultIndex)
    self.BtnFilter:SetSpriteVisible(false)
end

function XUiDlcRelinkEquipReform:OnDisable()
    self.Super.OnDisable(self)
    self.EquipFilterCache = {}
end

--region 装备背包

function XUiDlcRelinkEquipReform:InitPanelTab()
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

function XUiDlcRelinkEquipReform:OnEquipBtnTabClick(index)
    if self.CurSelectEquipOccupationIndex == index then
        return
    end
    self.CurSelectEquipOccupationIndex = index
    -- 重置装备筛选缓存
    self.EquipFilterCache = {}
    self:SetupDynamicTable()
    self:RefreshFilterBtn()
end

function XUiDlcRelinkEquipReform:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkEquipment, self, handler(self, self.OnEquipItemCallBack))
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkEquipReform:SetupDynamicTable()
    local opts = { Context = "Reform", Filter = self.EquipFilterCache }
    if self.CurSelectSlotIndex == EquipSlotType.Reform then
        opts.SelectedEquipUid = self.CurAbsorbSlotEquipUid
    elseif self.CurSelectSlotIndex == EquipSlotType.Absorb then
        opts.SelectedEquipUid = self.CurReformSlotEquipUid
    end

    self.EquipUidList = self._Control:GetEquipUidListByOccupationType(self.CurSelectEquipOccupationIndex, opts)
    local isEmpty = XTool.IsTableEmpty(self.EquipUidList)
    self.None.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        self.DynamicTable:Clear()
        self.CurSelectEquipUid = 0
        self.CurSelectGrid = nil
        self:RefreshPanelReform()
        return
    end

    local index = self:GetDefaultSelectEquipUidIndex()
    self.DynamicTable:SetDataSource(self.EquipUidList)
    self.DynamicTable:ReloadDataSync(index)
end

function XUiDlcRelinkEquipReform:GetDefaultSelectEquipUidIndex()
    local equipUid
    if self.CurSelectSlotIndex == EquipSlotType.Reform then
        equipUid = self.CurReformSlotEquipUid
    elseif self.CurSelectSlotIndex == EquipSlotType.Absorb then
        equipUid = self.CurAbsorbSlotEquipUid
    end

    self.CurSelectEquipUid = equipUid
    self.CurSelectGrid = nil
    if XTool.IsNumberValid(equipUid) then
        for index, uid in pairs(self.EquipUidList) do
            if uid == equipUid then
                return index
            end
        end
    end
    return 1
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipReform:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local equipUid = self.EquipUidList[index]
        grid:Refresh(equipUid)
        grid:SetHead(self._Control:GetEquipWearCharacterId(equipUid))
        local isSelected = XTool.IsNumberValid(self.CurSelectEquipUid) and equipUid == self.CurSelectEquipUid
        grid:SetSelect(isSelected)
        if isSelected and not self.CurSelectGrid then
            self.CurSelectGrid = grid
            self:RefreshPanelReform()
        end
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipReform:OnEquipItemCallBack(grid)
    local equipUid = grid:GetEquipUid()
    if equipUid == self.CurSelectEquipUid then
        return
    end

    self:CheckSelectEquipCondition(equipUid, function()
        if self.CurSelectGrid then
            self.CurSelectGrid:SetSelect(false)
        end
        grid:SetSelect(true)
        self.CurSelectEquipUid = equipUid
        self.CurSelectGrid = grid

        if self.CurSelectSlotIndex == EquipSlotType.Reform then
            self.CurReformSlotEquipUid = equipUid
        elseif self.CurSelectSlotIndex == EquipSlotType.Absorb then
            self.CurAbsorbSlotEquipUid = equipUid
        end

        self:RefreshPanelReform()
    end)
end

-- 检查选择装备条件
function XUiDlcRelinkEquipReform:CheckSelectEquipCondition(equipUid, callback)
    if not XTool.IsNumberValid(equipUid) then
        return
    end

    -- 改造槽位选择装备没有条件
    if self.CurSelectSlotIndex == EquipSlotType.Reform then
        if callback then
            callback()
        end
        return
    end

    -- 吸收槽位选择装备为佩戴中或预设中的装备，需弹二次确认弹框
    local wearCharacterId = self._Control:GetEquipWearCharacterId(equipUid)
    local isPreset = self._Control:CheckEquipIsPresetByEquipUid(equipUid)
    local hasWearer = XTool.IsNumberValid(wearCharacterId)

    -- 有佩戴者时处理（同时在预设中或仅佩戴中）
    if hasWearer then
        if isPreset then
            self:OpenWearTipDialog(wearCharacterId, function()
                self:OpenPresetTipDialog(callback)
            end)
        else
            self:OpenWearTipDialog(wearCharacterId, callback)
        end
        return
    end

    -- 仅预设中
    if isPreset then
        self:OpenPresetTipDialog(callback)
        return
    end

    if callback then
        callback()
    end
end

-- 打开佩戴中提示弹窗
---@param wearCharacterId number 佩戴角色Id
---@param callback function 确认后的回调
function XUiDlcRelinkEquipReform:OpenWearTipDialog(wearCharacterId, callback)
    local characterName = XMVCA.XCharacter:GetCharacterName(wearCharacterId)
    local title = self._Control:GetClientConfig("TipTitle")
    local data = self._Control:GetClientConfigParams("EquipReformAbsorbWearTipContent")
    local content = string.format(data[1] or "", characterName)
    local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "EquipReformAbsorbWearTip" }
    self._Control:OpenCommonTipDialog(title, content, nil, callback, extraData)
end

-- 打开预设中提示弹窗
---@param callback function 确认后的回调
function XUiDlcRelinkEquipReform:OpenPresetTipDialog(callback)
    local title = self._Control:GetClientConfig("TipTitle")
    local data = self._Control:GetClientConfigParams("EquipReformAbsorbPresetTipContent")
    local content = data[1] or ""
    local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "EquipReformAbsorbPresetTip" }
    self._Control:OpenCommonTipDialog(title, content, nil, callback, extraData)
end

--endregion

--region 装备改造

function XUiDlcRelinkEquipReform:RefreshPanelReform()
    if self.CurSelectSlotIndex == EquipSlotType.Reform then
        self:RefreshEquipReform()
    elseif self.CurSelectSlotIndex == EquipSlotType.Absorb then
        self:RefreshEquipAbsorb()
    end
end

function XUiDlcRelinkEquipReform:RefreshEquipReform()
    if not self.EquipReformNode then
        ---@type XUiGridDlcRelinkEquipment
        self.EquipReformNode = XUiGridDlcRelinkEquipment.New(self.GridReformEquipment, self, handler(self, self.OnEquipSlotCallBack))
        self.EquipReformNode:Open()
    end
    self.EquipReformNode:Refresh(self.CurReformSlotEquipUid, EquipSlotType.Reform)
    self.EquipReformNode:SetHead(self._Control:GetEquipWearCharacterId(self.CurReformSlotEquipUid))

    self:RefreshEquipDetail()
end

function XUiDlcRelinkEquipReform:RefreshEquipAbsorb()
    if not self.EquipAbsorbNode then
        ---@type XUiGridDlcRelinkEquipment
        self.EquipAbsorbNode = XUiGridDlcRelinkEquipment.New(self.GridAbsorbEquipment, self, handler(self, self.OnEquipSlotCallBack))
        self.EquipAbsorbNode:Open()
    end
    self.EquipAbsorbNode:Refresh(self.CurAbsorbSlotEquipUid, EquipSlotType.Absorb)
    self.EquipAbsorbNode:SetHead(self._Control:GetEquipWearCharacterId(self.CurAbsorbSlotEquipUid))
    self.EquipAbsorbNode:SetAdd(not XTool.IsNumberValid(self.CurAbsorbSlotEquipUid))

    self:RefreshIsLocked()
    self:RefreshAttributes()
    self:RefreshAbsorbBtn()
end

function XUiDlcRelinkEquipReform:RefreshIsLocked()
    local isValid = XTool.IsNumberValid(self.CurAbsorbSlotEquipUid)
    self.BtnLock.gameObject:SetActiveEx(isValid)
    if not isValid then
        return
    end

    local isLocked = self._Control:GetEquipIsLockedByEquipUid(self.CurAbsorbSlotEquipUid)
    self.BtnLock:SetButtonState(isLocked and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

-- 刷新属性
function XUiDlcRelinkEquipReform:RefreshAttributes()
    local isValid = XTool.IsNumberValid(self.CurAbsorbSlotEquipUid)
    self.PanelGroup.gameObject:SetActiveEx(isValid)
    if not isValid then
        return
    end

    self:HideEquipAttributes()

    -- 主属性
    local mainAttr = self._Control:GetEquipMainFactorByUid(self.CurAbsorbSlotEquipUid, false)
    if mainAttr then
        if not self.MainAttribute then
            local grid = XUiHelper.Instantiate(self.GridAttribute, self.PanelGroup)
            self.MainAttribute = XUiGridDlcRelinkEquipAttribute.New(grid, self)
        end
        self.MainAttribute:Open()
        self.MainAttribute:Refresh(mainAttr)
        self.MainAttribute.Transform:SetAsLastSibling()

        self.Spacing.gameObject:SetActiveEx(true)
        self.Spacing.transform:SetAsLastSibling()
    end

    -- 副属性
    local allSlots = self._Control:GetEquipAllDeputyFactorByUid(self.CurAbsorbSlotEquipUid)
    for index, slot in pairs(allSlots) do
        if slot.Attributes and not XTool.IsTableEmpty(slot.Attributes) then
            local grid = self:EnsureDeputyGroup(index)
            local attrCount = #slot.Attributes

            grid:GetObject("GridAttribute1").gameObject:SetActiveEx(attrCount >= 1)
            local hasSecond = attrCount >= 2
            grid:GetObject("Line").gameObject:SetActiveEx(hasSecond)
            grid:GetObject("GridAttribute2").gameObject:SetActiveEx(hasSecond)

            self.DeputyAttributeNodes[index] = self.DeputyAttributeNodes[index] or {}
            for i = 1, math.min(attrCount, 2) do
                if not self.DeputyAttributeNodes[index][i] then
                    self.DeputyAttributeNodes[index][i] = XUiGridDlcRelinkEquipAttribute.New(grid:GetObject("GridAttribute" .. i), self)
                end
                local node = self.DeputyAttributeNodes[index][i]
                node:Open()
                node:Refresh(slot.Attributes[i])
            end
        end
    end
end

function XUiDlcRelinkEquipReform:HideEquipAttributes()
    if self.MainAttribute then
        self.MainAttribute:Close()
    end
    for _, nodes in pairs(self.DeputyAttributeNodes) do
        for _, node in pairs(nodes or {}) do
            node:Close()
        end
    end
    for _, group in pairs(self.DeputyAttributeGroup) do
        group.gameObject:SetActiveEx(false)
    end
end

function XUiDlcRelinkEquipReform:EnsureDeputyGroup(index)
    local grid = self.DeputyAttributeGroup[index]
    if not grid then
        grid = XUiHelper.Instantiate(self.GridAttributeGroup, self.PanelGroup)
        self.DeputyAttributeGroup[index] = grid
    end
    grid.gameObject:SetActiveEx(true)
    grid.transform:SetAsLastSibling()
    return grid
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipReform:OnEquipSlotCallBack(grid)
    local slotIndex = grid:GetSlotIndex()
    if self.CurSelectSlotIndex == slotIndex then
        if slotIndex == EquipSlotType.Absorb then
            self:UnloadAbsorbSlot()
        end
        return
    end

    self.CurSelectSlotIndex = slotIndex
    self:RefreshEquipSlotSelect()

    -- 重置职业选择并刷新列表
    self.CurSelectEquipOccupationIndex = 0
    self.CurSelectEquipUid = 0
    self.CurSelectGrid = nil
    self.EquipFilterCache = {}

    local defaultIndex = self:GetDefaultSelectEquipOccupationIndex()
    self.PanelTab:SelectIndex(defaultIndex)
end

-- 刷新装备槽位选择状态
function XUiDlcRelinkEquipReform:RefreshEquipSlotSelect()
    if self.EquipReformNode then
        self.EquipReformNode:SetSelect(self.CurSelectSlotIndex == EquipSlotType.Reform)
    end
    if self.EquipAbsorbNode then
        self.EquipAbsorbNode:SetSelect(self.CurSelectSlotIndex == EquipSlotType.Absorb)
    end
end

-- 卸下吸收槽位的装备
function XUiDlcRelinkEquipReform:UnloadAbsorbSlot()
    -- 吸收槽位无装备
    if not XTool.IsNumberValid(self.CurAbsorbSlotEquipUid) then
        return
    end

    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelect(false)
    end
    self.CurSelectEquipUid = 0
    self.CurSelectGrid = nil
    self.CurAbsorbSlotEquipUid = 0
    self:RefreshEquipAbsorb()
end

function XUiDlcRelinkEquipReform:GetDefaultSelectEquipOccupationIndex()
    local equipUid
    if self.CurSelectSlotIndex == EquipSlotType.Reform then
        equipUid = self.CurReformSlotEquipUid
    elseif self.CurSelectSlotIndex == EquipSlotType.Absorb then
        equipUid = self.CurAbsorbSlotEquipUid
    end

    if XTool.IsNumberValid(equipUid) then
        local occupationType = self:GetEquipOccupationTypeByUid(equipUid)
        if XTool.IsNumberValid(occupationType) then
            return occupationType
        end
    end
    return 1
end

function XUiDlcRelinkEquipReform:GetEquipOccupationTypeByUid(equipUid)
    local templateId = self._Control:GetEquipTemplateIdByEquipUid(equipUid)
    if not XTool.IsNumberValid(templateId) then
        return 0
    end
    return self._Control:GetEquipOccupationType(templateId)
end

--endregion

--region 右侧装备详情

function XUiDlcRelinkEquipReform:RefreshEquipDetail()
    if not self.EquipDetailNode then
        ---@type XUiPanelDlcRelinkEquipDetail
        self.EquipDetailNode = XUiPanelDlcRelinkEquipDetail.New(self.PanelDetail, self)
    end
    local isValid = XTool.IsNumberValid(self.CurReformSlotEquipUid)
    if isValid then
        self.EquipDetailNode:Open()
        self.EquipDetailNode:Refresh(self.CurReformSlotEquipUid)
    else
        self.EquipDetailNode:Close()
    end

    self.BtnDelete.gameObject:SetActiveEx(isValid)
    self.TxtTips.gameObject:SetActiveEx(isValid)
    if isValid then
        self:RefreshDeleteBtn()
    end
end

function XUiDlcRelinkEquipReform:RefreshDeleteBtn()
    local remainFactorRemoveNum = self:GetRemainFactorRemoveNum()
    self.TxtTips.text = string.format(self._Control:GetClientConfig("EquipReformDeleteTips"), remainFactorRemoveNum)
    self.BtnDelete:SetDisable(remainFactorRemoveNum <= 0)
end

-- 获取当前改造槽位装备剩余可移除次数
function XUiDlcRelinkEquipReform:GetRemainFactorRemoveNum()
    if not XTool.IsNumberValid(self.CurReformSlotEquipUid) then
        return 0
    end

    local templateId = self._Control:GetEquipTemplateIdByEquipUid(self.CurReformSlotEquipUid)
    local quality = self._Control:GetEquipQuality(templateId)

    local maxFactorRemoveNum = self._Control:GetEquipQualityFactorRemoveNum(quality)
    local factorRemoveNum = self._Control:GetEquipFactorRemoveNumByEquipUid(self.CurReformSlotEquipUid)

    return math.max(0, maxFactorRemoveNum - factorRemoveNum)
end

--endregion

--region 刷新按钮

function XUiDlcRelinkEquipReform:RefreshFilterBtn()
    local isFilter = self:CheckFilterCache()
    self.BtnFilter:SetNameByGroup(0, self._Control:GetClientConfig("EquipFilterBtnDesc", isFilter and 2 or 1))
end

-- 检查当前筛选条件是否有生效
function XUiDlcRelinkEquipReform:CheckFilterCache()
    if XTool.IsTableEmpty(self.EquipFilterCache) then
        return false
    end

    if XTool.IsNumberValid(self.EquipFilterCache.ReformedType)
        or XTool.IsNumberValid(self.EquipFilterCache.FactorRemovedType)
        or XTool.IsNumberValid(self.EquipFilterCache.EquipType)
        or not XTool.IsTableEmpty(self.EquipFilterCache.FactorIds) then
        return true
    end

    return false
end

function XUiDlcRelinkEquipReform:RefreshAbsorbBtn()
    local isValid = XTool.IsNumberValid(self.CurAbsorbSlotEquipUid)
    local isLocked = isValid and self._Control:GetEquipIsLockedByEquipUid(self.CurAbsorbSlotEquipUid) or false
    local isSlotFull = isValid and self._Control:CheckEquipDeputyFactorSlotsIsFull(self.CurAbsorbSlotEquipUid) or false
    self.BtnAbsorb:SetDisable(not isValid or isLocked or isSlotFull)
end

--endregion

function XUiDlcRelinkEquipReform:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnFilter, self.OnBtnFilterClick)
    self:RegisterClickEvent(self.BtnDelete, self.OnBtnDeleteClick)
    self:RegisterClickEvent(self.BtnLock, self.OnBtnLockClick)
    self:RegisterClickEvent(self.BtnAbsorb, self.OnBtnAbsorbClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiDlcRelinkEquipReform:OnBtnBackClick()
    self:Close()
end

-- 打开筛选弹窗
function XUiDlcRelinkEquipReform:OnBtnFilterClick()
    self.BtnFilter:SetSpriteVisible(true)
    local equipUidList = self._Control:GetEquipUidListByOccupationType(self.CurSelectEquipOccupationIndex)
    local equipMainFactorIds = self._Control:GetEquipMainFactorIds(equipUidList)
    XLuaUiManager.Open("UiDlcRelinkPopupFilter", equipMainFactorIds, self.EquipFilterCache, false, function()
        self:SetupDynamicTable()
        self:RefreshFilterBtn()
    end, function()
        self.BtnFilter:SetSpriteVisible(false)
    end)
end

-- 删除属性
function XUiDlcRelinkEquipReform:OnBtnDeleteClick()
    if not XTool.IsNumberValid(self.CurReformSlotEquipUid) then
        return
    end

    local remainFactorRemoveNum = self:GetRemainFactorRemoveNum()
    if remainFactorRemoveNum <= 0 then
        self._Control:OpenCommonTipText("EquipReformDeleteNoTimesTips")
        return
    end

    self.MaskDelete.gameObject:SetActiveEx(true)
    local orderInLayer = self.MaskCanvas.sortingOrder + 1
    self.EquipDetailNode:OpenDeleteFactorPanel(orderInLayer, function()
        self:RefreshEquipReform()
    end)
end

-- 锁定/解锁装备
function XUiDlcRelinkEquipReform:OnBtnLockClick()
    if not XTool.IsNumberValid(self.CurAbsorbSlotEquipUid) then
        return
    end

    local isLocked = self._Control:GetEquipIsLockedByEquipUid(self.CurAbsorbSlotEquipUid)
    local callback = function()
        self:RefreshIsLocked()
    end

    if isLocked then
        self._Control:RequestUnlockEquip(self.CurAbsorbSlotEquipUid, callback)
    else
        self._Control:RequestLockEquip(self.CurAbsorbSlotEquipUid, callback)
    end
end

-- 吸收装备
function XUiDlcRelinkEquipReform:OnBtnAbsorbClick()
    if not XTool.IsNumberValid(self.CurAbsorbSlotEquipUid) then
        self._Control:OpenCommonTipText("EquipReformAbsorbNoEquipTips")
        return
    end

    local isLocked = self._Control:GetEquipIsLockedByEquipUid(self.CurAbsorbSlotEquipUid)
    if isLocked then
        self._Control:OpenCommonTipText("EquipReformAbsorbLockTips")
        return
    end

    local isSlotFull = self._Control:CheckEquipDeputyFactorSlotsIsFull(self.CurAbsorbSlotEquipUid)
    if isSlotFull then
        self._Control:OpenCommonTipText("EquipReformAbsorbFullTips")
        return
    end

    if self.CurReformSlotEquipUid == self.CurAbsorbSlotEquipUid then
        XLog.Error("XUiDlcRelinkEquipReform:OnBtnAbsorbClick -> 吸收槽位装备不能与改造槽位装备相同")
        return
    end

    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end

    self._Control:RequestEquipAbsorb(self.CurReformSlotEquipUid, self.CurAbsorbSlotEquipUid, function()
        self:UnloadAbsorbSlot()
        self:RefreshEquipReform()
        self:RefreshEquipDetail()
        self:SetupDynamicTable()
    end)
end

function XUiDlcRelinkEquipReform:OnBtnCloseClick()
    self.EquipDetailNode:CloseDeleteFactorPanel()
    self.MaskDelete.gameObject:SetActiveEx(false)
end

return XUiDlcRelinkEquipReform
