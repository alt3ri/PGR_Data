
---@class XUiSkyGardenDormCodex : XBigWorldUi
---@field _Control XSkyGardenDormControl
---@field PanelTabBtnGroup XUiButtonGroup
local XUiSkyGardenDormCodex = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenDormCodex")

function XUiSkyGardenDormCodex:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenDormCodex:OnStart(defaultTypeId)
    self._DefaultIndex = self:GetTabIndexByType(defaultTypeId)
    self:InitView()
end

function XUiSkyGardenDormCodex:OnDestroy()
    self._Control:SaveHandBookMark()
end

function XUiSkyGardenDormCodex:InitUi()
    local typeList = self._Control:GetHandBookTypeList()
    self._TypeList = typeList
    local tab = {}
    for i, type in pairs(typeList) do
        local btn = i == 1 and self.BtnTab or XUiHelper.Instantiate(self.BtnTab, self.PanelTabBtnGroup.transform)
        btn:SetNameByGroup(0, self._Control:GetHandBookTypeName(type))
        btn:ShowReddot(self:CheckNewMark(type))
        btn:SetSprite(self._Control:GetFurnitureTypeIcon(type))
        tab[#tab + 1] = btn
    end
    self.TabList = tab
    self.TxtDesc.text = ""
    self._Cur = 0
    self._Total =0
    self.PanelTabBtnGroup:Init(tab, function(tabIndex) self:OnSelectTab(tabIndex) end)
    self.CodexItem.gameObject:SetActiveEx(false)
    self._DynamicTable = XUiHelper.DynamicTableNormal(self, self.CoatingList, require("XUi/XUiSkyGarden/XDorm/Grid/XUiGridSGFurnitureHandBook"))
end

function XUiSkyGardenDormCodex:InitCb()
    self.BtnTanchuangClose:AddEventListener(handler(self, self.Close))
    self.BtnView:AddEventListener(handler(self, self.OnBtnViewClick))
end

function XUiSkyGardenDormCodex:InitView()
    self.PanelTabBtnGroup:SelectIndex(self._DefaultIndex)
end

function XUiSkyGardenDormCodex:OnSelectTab(tabIndex)
    if self._TabIndex == tabIndex then
        return
    end
    self:PlayAnimation("QieHuan1")
    self._TabIndex = tabIndex
    self:RefreshRight()
end

function XUiSkyGardenDormCodex:RefreshRight()
    self:SetupDynamicTable()
    self.TxtNumber.text = string.format("%s/%s", self._Cur, self._Total)
end

function XUiSkyGardenDormCodex:SetupDynamicTable()
    local type = self._TypeList[self._TabIndex]
    self._DataList = self._Control:GetHandBookFurnitureListByType(type)
    local cur = 0
    for _, furnitureId in pairs(self._DataList) do
        if self._Control:CheckFurnitureUnlockByConfigId(furnitureId) then
            cur = cur + 1
        end
    end
    self._Cur = cur
    self._Total = #self._DataList
    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync()
end

function XUiSkyGardenDormCodex:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self._DataList[index], self._SelectFurnitureId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local t = self._DynamicTable:GetGridByIndex(1)
        self:OnClickGrid(t)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickGrid(grid)
    end
end

---@param grid XUiGridSGFurnitureHandBook
function XUiSkyGardenDormCodex:OnClickGrid(grid)
    if not grid or grid:IsSelect() then
        return
    end
    self:PlayAnimation("QieHuan2")
    if self._LastGrid then
        self._LastGrid:SetSelect(false)
    end
    local furnitureId = grid:GetId()
    self.ItemIcon:SetRawImage(self._Control:GetFurnitureIcon(furnitureId))
    self.TxtDesc.text = self._Control:GetFurnitureWorldDesc(furnitureId)
    self.TxtLockDesc.text = self._Control:GetFurnitureLockDesc(furnitureId)
    self.ItemIconTitle.text = self._Control:GetFurnitureName(furnitureId)
    self._SelectFurnitureId = furnitureId
    self.BtnView.gameObject:SetActiveEx(self._Control:CheckFurnitureUnlockByConfigId(furnitureId))
    self._LastGrid = grid
    grid:OnClick()
end

function XUiSkyGardenDormCodex:GetTabIndexByType(type)
    if not type then
        return 1
    end
    for index, t in pairs(self._TypeList) do
        if t == type then
            return index
        end
    end
    return 1
end

function XUiSkyGardenDormCodex:CheckNewMark(type)
    return self._Control:CheckHandBookNewMark(type)
end

function XUiSkyGardenDormCodex:RefreshRed()
    local type = self._TypeList[self._TabIndex]
    local value = self:CheckNewMark(type)
    local tab = self.TabList[self._TabIndex]
    tab:ShowReddot(value)
    self._Control:Notify(XMVCA.XSkyGardenDorm.XEventId.REFRESH_HANDBOOK_NEW_MARK)
end

function XUiSkyGardenDormCodex:OnBtnViewClick()
    XMVCA.XBigWorldUI:Open("UiSkyGardenDormItemDetail3D", self._SelectFurnitureId)
end