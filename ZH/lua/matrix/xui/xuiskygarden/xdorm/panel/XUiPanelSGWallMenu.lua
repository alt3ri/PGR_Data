local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiPanelSGWallMenu : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiPanelSGWall
local XUiPanelSGWallMenu = XClass(XUiNode, "XUiPanelSGWallMenu")

local GridType = {
    Furniture = 1,
    AlbumPhoto = 2,
}

function XUiPanelSGWallMenu:OnStart(areaType)
    self._AreaType = areaType
    self._DisplaySortTypeIdDict = {
        [self._Control:GetAlbumPhotoTypeId()] = true
    }
    self._IsPositiveSequence = self._Control:IsPositiveSequence(areaType)
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGWallMenu:OnDisable()
    self:RefreshSort(self._TypeId)
end

function XUiPanelSGWallMenu:Refresh()
end

function XUiPanelSGWallMenu:InitUi()
    self.BtnSkipClick.gameObject:SetActiveEx(false)
    self.GridItem.gameObject:SetActiveEx(false)
    self._DynamicTable = XDynamicTableNormal.New(self.List)
    self._DynamicTable:SetDelegate(self)
    self._DynamicTable:SetProxy(require("XUi/XUiSkyGarden/XDorm/Grid/XUiGridSGFurniture"), self, self._AreaType)
    self._TypeId2List = {}
end

function XUiPanelSGWallMenu:InitCb()
    self.BtnOrder:AddEventListener(handler(self, self.OnBtnOrderClick))
    self.BtnReverse:AddEventListener(handler(self, self.OnBtnReverseClick))
    self._Control:Subscribe(XMVCA.XSkyGardenDorm.XEventId.EVENT_DORM_FURNITURE_REFRESH, self.ClearListCache, self)
end

function XUiPanelSGWallMenu:OnDestroy()
    self._Control:Unsubscribe(XMVCA.XSkyGardenDorm.XEventId.EVENT_DORM_FURNITURE_REFRESH, self.ClearListCache, self)
end

function XUiPanelSGWallMenu:OnTypeIdChanged(typeId, selectId)
    self._LastTypeId = self._TypeId
    self._TypeId = typeId
    self._IsPlayEnable = self._TypeId ~= self._LastTypeId
    if not XTool.IsTableEmpty(self._TypeId2List[typeId]) then
        self:SetupDynamicTable(self._TypeId2List[typeId], selectId, GridType.Furniture)
        return 
    end
    local list
    local gridType
    if typeId == self._Control:GetAlbumPhotoTypeId() then
        list = self:SortAlbumPhotoDataList(self._Control:GetAlbumPhotoList())
        gridType = GridType.AlbumPhoto
    else
        list = self._Control:GetFurnitureListByTypeId(typeId)
        if not XTool.IsTableEmpty(list) then
            local tempList = {}
            --需求：未解锁 && 未配置解锁文案
            for i, configId in pairs(list) do
                if not (not self._Control:CheckFurnitureUnlockByConfigId(configId)
                        and string.IsNilOrEmpty(self._Control:GetFurnitureLockDesc(configId))) then
                    tempList[#tempList + 1] = configId
                end
            end
            

            self._TypeId2List[typeId] = tempList
            
            list = self:SortFurnitureDataList(tempList)
        end
        gridType = GridType.Furniture
    end
    self:SetupDynamicTable(list, nil, gridType)
end

function XUiPanelSGWallMenu:RefreshSort(typeId)
    local display = self._DisplaySortTypeIdDict[typeId] and not XTool.IsTableEmpty(self._DataList) and self:IsNodeShow()
    self.BtnReverse.gameObject:SetActiveEx(display)
    self.BtnOrder.gameObject:SetActiveEx(display)
    if not display then
        return
    end
    self.BtnReverse.gameObject:SetActiveEx(not self._IsPositiveSequence)
    self.BtnOrder.gameObject:SetActiveEx(self._IsPositiveSequence)
end

function XUiPanelSGWallMenu:ClearListCache()
    self._TypeId2List = {}
end

function XUiPanelSGWallMenu:SetupDynamicTable(list, selectId, gridType)
    if self._LastGrid then
        self._LastGrid:SetSelect(false)
    end
    self._LastGrid = nil
    --self._SelectCfgId = nil
    
    local isEmpty = XTool.IsTableEmpty(list)
    self.PanelEmpty.gameObject:SetActiveEx(isEmpty)
    self._DataList = list
    self._SelectCfgId = selectId
    self:RefreshSort(self._TypeId)
    local startIndex
    if selectId then
        for i, cfgId in pairs(self._DataList) do
            if cfgId == selectId then
                startIndex = i
                break
            end
        end
    end
    self._GridType = gridType
    self._DynamicTable:SetDataSource(self._DataList)
    self._DynamicTable:ReloadDataSync(startIndex)
end

function XUiPanelSGWallMenu:RefreshDynamicTable(selectId)
    if XTool.IsTableEmpty(self._DataList) then
        return
    end
    self:SetupDynamicTable(self._DataList, selectId, self._GridType)
end

function XUiPanelSGWallMenu:PlayEnableAnimation()
    local allUseGird = self._DynamicTable:GetGrids()
    for index, grid in pairs(allUseGird) do
        grid:PlayEnableAnimation(index)
    end
    self._IsPlayEnable = false
end

---@param grid XUiGridSGFurniture
function XUiPanelSGWallMenu:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DataList[index]
        grid:Refresh(data, self._SelectCfgId, self._GridType)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        grid:OnClick()
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        if self._SelectCfgId then
            local grids = self._DynamicTable:GetGrids()
            ---@type XUiGridSGFurniture
            local temp
            for _, g in pairs(grids) do
                if g:GetConfigId() == self._SelectCfgId then
                    temp = g
                    break
                end
            end
            if temp then
                temp:SetSelect(true)
            end
            --self._SelectCfgId = nil
        end
        if self._IsPlayEnable then
            self:PlayEnableAnimation()
        end
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:OnRecycle()
    end
end

function XUiPanelSGWallMenu:SortFurnitureDataList(list)
    if XTool.IsTableEmpty(list) then
        return {}
    end
   
    local control = self._Control
    table.sort(list, function(a, b) 
        local unlockA = control:CheckFurnitureUnlockByConfigId(a)
        local unlockB = control:CheckFurnitureUnlockByConfigId(b)
        if unlockA ~= unlockB then
            return unlockA
        end
        local pA = control:GetFurniturePriority(a)
        local pB = control:GetFurniturePriority(b)
        if pA ~= pB then
            return pA > pB
        end
        return a < b
    end)
    
    return list
end

function XUiPanelSGWallMenu:SortAlbumPhotoDataList(list)
    if XTool.IsTableEmpty(list) then
        return {}
    end

    if self._IsPositiveSequence then
        table.sort(list, function(a, b)
            local cTimeA = a.CreateTime
            local cTimeB = b.CreateTime
            if cTimeA ~= cTimeB then
                return cTimeA > cTimeB
            end
            return a.Id > b.Id
        end)
    else
        table.sort(list, function(a, b)
            local cTimeA = a.CreateTime
            local cTimeB = b.CreateTime
            if cTimeA ~= cTimeB then
                return cTimeA < cTimeB
            end
            return a.Id < b.Id
        end)
    end
    return list
end

---@param grid XUiGridSGFurniture
function XUiPanelSGWallMenu:OnSelectFurniture(id, cfgId, grid, isCreate)
    self._SelectCfgId = cfgId
    if self._LastGrid then
        self._LastGrid:SetSelect(false)
    end
    
    self._LastGrid = grid
    
    self.Parent:OnSelectFurniture(id, cfgId, isCreate, grid:IsAlbumPhoto())
end

function XUiPanelSGWallMenu:OnBtnOrderClick()
    if not self._DisplaySortTypeIdDict[self._TypeId] then
        self.BtnReverse.gameObject:SetActiveEx(false)
        self.BtnOrder.gameObject:SetActiveEx(false)
        return
    end
    self._IsPositiveSequence = false
    self:OnTypeIdChanged(self._TypeId, self._SelectCfgId)
    self._Control:SetPositiveSequence(self._AreaType, false)
end

function XUiPanelSGWallMenu:OnBtnReverseClick()
    if not self._DisplaySortTypeIdDict[self._TypeId] then
        self.BtnReverse.gameObject:SetActiveEx(false)
        self.BtnOrder.gameObject:SetActiveEx(false)
        return
    end
    self._IsPositiveSequence = true
    self:OnTypeIdChanged(self._TypeId, self._SelectCfgId)
    self._Control:SetPositiveSequence(self._AreaType, true)
end

return XUiPanelSGWallMenu