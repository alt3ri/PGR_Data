local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
---@class XUiDlcRelinkEquipBag : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PaneTab XUiButtonGroup
local XUiDlcRelinkEquipBag = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkEquipBag")

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
end

function XUiDlcRelinkEquipBag:OnStart(characterId, index)
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self.CharacterId = characterId
    self.CurSlotIndex = index or 1

    self.CurEquipOccupationIndex = 0

    self.CurSelectGrid = nil
    self.CurSelectEquipUId = 0

    self:InitPanelTab()
    self:InitDynamicTable()
end

function XUiDlcRelinkEquipBag:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshPanelEquipment()
    self.PaneTab:SelectIndex(self.CurEquipOccupationIndex > 0 and self.CurEquipOccupationIndex or 1)
end

function XUiDlcRelinkEquipBag:OnGetEvents()

end

function XUiDlcRelinkEquipBag:OnGetLuaEvents()

end

function XUiDlcRelinkEquipBag:OnNotify(event, ...)

end

function XUiDlcRelinkEquipBag:OnDisable()
    self.Super.OnDisable(self)
end

function XUiDlcRelinkEquipBag:OnDestroy()

end

--region 左侧装备槽位

function XUiDlcRelinkEquipBag:RefreshPanelEquipment()
    -- 装备总等级
    local totalLv = self._Control:GetEquipTotalAbilityByCharacterId(self.CharacterId)
    self.TxtLv.text = string.format(self._Control:GetClientConfig("EquipLevelDesc"), totalLv)
    -- 装备槽位
    for index = 1, XEnumConst.DlcRelink.EquipSlotCount do
        local grid = self.EquipmentGridList[index]
        if not grid then
            local parent = self[string.format("GridEquipment0%d", index)]
            if not parent then
                XLog.Error("XUiPanelDlcRelinkCharacterRight:RefreshPanelEquipment - GridEquipment0" .. index .. " not found")
                return
            end
            local go = XUiHelper.Instantiate(self.GridEquipment, parent)
            grid = XUiGridDlcRelinkEquipment.New(go, self, handler(self, self.OnEquipSlotCallBack))
            self.EquipmentGridList[index] = grid
        end
        grid:Open()
        local equipUId = self._Control:GetEquipUIdByCharacterId(self.CharacterId, index)
        local isUnLock = true -- TODO 装备槽位是否解锁
        grid:Refresh(equipUId, index)
        grid:SetLock(not isUnLock)
        grid:SetAdd(isUnLock and not XTool.IsNumberValid(equipUId))
        grid:SetSelect(self.CurSlotIndex == index)
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:OnEquipSlotCallBack(grid)
    local index = grid:GetIndex()
    if self.CurSlotIndex == index then
        return
    end

    self.CurSlotIndex = index
    for i, g in ipairs(self.EquipmentGridList) do
        g:SetSelect(i == index)
    end

    self.CurEquipOccupationIndex = 0
    self.PaneTab:SelectIndex(1)
end

--endregion

--region 装备背包

function XUiDlcRelinkEquipBag:InitPanelTab()
    self.EquipBtnTabList = {}
    local tabDescList = self._Control:GetClientConfigParams("EquipTabsDesc")
    for _, tabDesc in ipairs(tabDescList) do
        ---@type XUiComponent.XUiButton
        local btnTab = XUiHelper.Instantiate(self.BtnTab, self.PaneTab.transform)
        btnTab.gameObject:SetActiveEx(true)
        btnTab:SetNameByGroup(0, tabDesc)
        table.insert(self.EquipBtnTabList, btnTab)
    end
    self.PaneTab:Init(self.EquipBtnTabList, handler(self, self.OnEquipBtnTabClick))
end

function XUiDlcRelinkEquipBag:OnEquipBtnTabClick(index)
    if self.CurEquipOccupationIndex == index then
        return
    end
    self.CurEquipOccupationIndex = index
    self:SetupDynamicTable()
end

function XUiDlcRelinkEquipBag:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkEquipment, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkEquipBag:SetupDynamicTable()
    self.EquipUidList = self._Control:GetEquipUidListBySlotAndOccType(self.CharacterId, self.CurSlotIndex, self.CurEquipOccupationIndex)
    local isEmpty = XTool.IsTableEmpty(self.EquipUidList)
    self.None.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        self.DynamicTable:Clear()
        return
    end

    local index = self:GetDefaultSelectEquipUId()
    self.CurSelectEquipUId = self.EquipUidList[index]
    self.CurSelectGrid = nil

    self.DynamicTable:SetDataSource(self.EquipUidList)
    self.DynamicTable:ReloadDataSync(index)
end

function XUiDlcRelinkEquipBag:GetDefaultSelectEquipUId()
    return 1 -- TODO 默认选中装备
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipBag:OnDynamicTableEvent(event, index, grid)
    local equipUId = self.EquipUidList[index]
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(equipUId)
        grid:SetHead(self._Control:GetEquipWearCharacterId(equipUId))
        local isSelected = equipUId == self.CurSelectEquipUId
        grid:SetSelect(isSelected)
        if isSelected and not self.CurSelectGrid then
            self.CurSelectGrid = grid
            self:RefreshEquipDetail()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        if equipUId == self.CurSelectEquipUId then
            return
        end
        if self.CurSelectGrid then
            self.CurSelectGrid:SetSelect(false)
        end
        grid:SetSelect(true)
        self.CurSelectEquipUId = equipUId
        self.CurSelectGrid = grid
        self:RefreshEquipDetail()
    end
end

--endregion

--region 右侧装备详情

function XUiDlcRelinkEquipBag:RefreshEquipDetail()
    if not self.EquipDetailNode then

    end
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

function XUiDlcRelinkEquipBag:OnBtnAttributeClick()
    -- TODO 打开12弹窗-装备属性等级预览
end

function XUiDlcRelinkEquipBag:OnBtnReformClick()
    -- 改造装备
end

function XUiDlcRelinkEquipBag:OnBtnReplaceClick()
    -- 替换装备
end

function XUiDlcRelinkEquipBag:OnBtnRemoveClick()
    -- 卸下装备
end

function XUiDlcRelinkEquipBag:OnBtnFilterClick()
    -- TODO 打开16弹窗-装备筛选
end

function XUiDlcRelinkEquipBag:OnBtnBreakdownClick()
    -- TODO 打开20界面-分解装备
end

function XUiDlcRelinkEquipBag:OnBtnSynthesisClick()
    -- TODO 打开22弹窗·合成装备
end

return XUiDlcRelinkEquipBag
