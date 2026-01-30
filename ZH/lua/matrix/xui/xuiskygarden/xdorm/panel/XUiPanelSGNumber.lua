---@class XUiGridSGNumber : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiPanelSGNumber
local XUiGridSGNumber = XClass(XUiNode, "XUiGridSGNumber")

function XUiGridSGNumber:Refresh(icon, cur, max, name)
    if not string.IsNilOrEmpty(icon) then
        self.ImgIcon:SetSprite(icon)
    end
    
    if not string.IsNilOrEmpty(name) then
        self.Txt.text = name
    end
    self.TxtNumber.text = string.format("%s/%s", cur, max)
    self:Open()
end


---@class XUiPanelSGNumber : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiSkyGardenDormPhotoWall
---@field _GridNum1 XUiGridSGNumber
---@field _GridNum2 XUiGridSGNumber
local XUiPanelSGNumber = XClass(XUiNode, "XUiPanelSGNumber")

function XUiPanelSGNumber:OnStart(areaType)
    self._AreaType = areaType
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGNumber:InitUi()
    self.GridNumber1.gameObject:SetActiveEx(false)
    self.GridNumber2.gameObject:SetActiveEx(false)
    self._GridNums = {}
end

function XUiPanelSGNumber:InitCb()
end

function XUiPanelSGNumber:Refresh()
    local control = self._Control
    local typeList, capacityList = control:GetContainerCapacity(self._AreaType)
    if XTool.IsTableEmpty(typeList) or XTool.IsTableEmpty(capacityList) then
        return
    end
    local dict = control:GetPutCountDictByMajorType(typeList, self.Parent:GetContainerData())
    for i, majorType in pairs(typeList) do
        local grid = self._GridNums[i]
        if not grid then
            local ui = self["GridNumber" .. i] or XUiHelper.Instantiate(self.GridNumber1, self.GridNumber1.transform.parent)
            grid = XUiGridSGNumber.New(ui, self)
            self._GridNums[i] = grid
        end
        local capacity = capacityList[i]
        local typeId = control:GetTypeIdByMajorType(majorType)
        local name = control:GetFurnitureMajorName(typeId)
        grid:Refresh(control:GetFurnitureTypeIcon(typeId), dict[majorType], capacity, name)
    end

    for i = #typeList + 1, #self._GridNums do
        local grid = self._GridNums[i]
        grid:Close()
    end
end

function XUiPanelSGNumber:IsFull(majorType)
    local control = self._Control
    local typeList, capacityList = control:GetContainerCapacity(self._AreaType)
    if XTool.IsTableEmpty(typeList) or XTool.IsTableEmpty(capacityList) then
        return true
    end
    local dict = control:GetPutCountDictByMajorType(typeList, self.Parent:GetContainerData())
    for i, mType in pairs(typeList) do
        if mType == majorType then
            local capacity = capacityList[i]
            return dict[mType] >= capacity
        end
    end
    return true
end

return XUiPanelSGNumber