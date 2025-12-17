
local XUiPanelSGWall = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGWall")

---@class XUiPanelSGPhotoWall : XUiPanelSGWall
---@field _Control XSkyGardenDormControl
---@field Parent XUiSkyGardenDormPhotoWall
---@field _PanelOp XUiPanelSGPhotoWallOp
local XUiPanelSGPhotoWall = XClass(XUiPanelSGWall, "XUiPanelSGPhotoWall")

local SgFurnitureType = XMVCA.XSkyGardenDorm.XSgFurnitureType
---@type X3CCommand
local X3C_CMD = CS.X3CCommand

function XUiPanelSGPhotoWall:OnStart(areaType)
    self._AreaType = areaType
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGPhotoWall:Refresh()
    XUiPanelSGWall.Refresh(self)
end

function XUiPanelSGPhotoWall:InitUi()
    XUiPanelSGWall.InitUi(self)
    self._PanelTab = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGWallTab").New(self.ScrollTitleTab, self, self._AreaType, 1)
    self._PanelOp = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGPhotoWallOp").New(self.PanelWall, self, self._AreaType)
end

function XUiPanelSGPhotoWall:InitCb()
    self._CreateFunc = {
        [SgFurnitureType.SystemPhoto] = function(id, cfgId) self:OnCreateSystemPhoto(id, cfgId) end,
        [SgFurnitureType.AlbumPhoto] = function(id, cfgId) self:OnCreateAlbumPhoto(id, cfgId) end,
        [SgFurnitureType.Decoration] = function(id, cfgId) self:OnCreateDecoration(id, cfgId) end,
        [SgFurnitureType.DecorationBoard] = function(id, cfgId) self:OnCreateDecorationBoard(id, cfgId) end,
    }
end

function XUiPanelSGPhotoWall:OnSelectFurniture(id, cfgId, isCreate, isAlbumPhoto)
    if not self._PanelOp:TryCheckOpIsSafe(true) then
        return
    end
    if isCreate then
        local majorType
        if isAlbumPhoto then
            local typeId = self._Control:GetAlbumPhotoTypeId()
            majorType = self._Control:GetMajorType(typeId)
            if self.Parent:CheckIsFull(majorType) then
                XUiManager.TipMsg(self._Control:GetSameTypeFullCountText())
                return
            end
        else
            majorType = self._Control:GetFurnitureMajorType(cfgId)
            if not self._Control:IsContainerFurniture(cfgId) then
                if self.Parent:CheckIsFull(majorType) then
                    XUiManager.TipMsg(self._Control:GetSameTypeFullCountText())
                    return
                end
            end
        end
        
        local func = self._CreateFunc[majorType]

        if func then
            func(id, cfgId)
        end
    else
        self._PanelOp:TryClickSlot(id)
    end
end

function XUiPanelSGPhotoWall:InitFurniture()
    local data = self.Parent:GetContainerData()
    local dict = data:GetFurnitureDict(false)
    ---@type XSgFurnitureData[]
    local list = {}
    local maxLayer = 0
    for _, f in pairs(dict) do
        list[#list + 1] = f
        maxLayer = math.max(maxLayer, f:GetLayer())
    end
    dict = data:GetFurnitureDict(true)
    for _, f in pairs(dict) do
        list[#list + 1] = f
        maxLayer = math.max(maxLayer, f:GetLayer())
    end
    self._Control:SetMaxLayer(maxLayer)
    
    table.sort(list, function(a, b)
        local layerA = a:GetLayer()
        local layerB = b:GetLayer()
        if layerA ~= layerB then
            return layerA > layerB
        end
        return a:GetId() < a:GetId()
    end)
    
    for i, f in pairs(list) do
        self._PanelOp:CreateFurniture(i, f:GetId(), false, false, f:IsAlbumPhoto())
    end
end

function XUiPanelSGPhotoWall:OnCreateSystemPhoto(id, cfgId)
    local data =  XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_CREATE_PHOTO, {
        Id = id,
        SoId = self._Control:GetFurnitureSceneObjId(cfgId),
        PhotoId = 0,
        SaltId = 0,
    })
    self._Control:AddFightFurnitureData(id, data, nil, false)
    self._PanelOp:CreateFurniture(0, id, true, false, false)
end

function XUiPanelSGPhotoWall:OnCreateAlbumPhoto(id, cfgId)
    local data = XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_CREATE_PHOTO, {
        Id = 0,
        SoId = 0,
        PhotoId = id,
        SaltId = cfgId
    })
    self._Control:AddFightFurnitureData(id, data, nil, true)
    self._PanelOp:CreateFurniture(0, id, true, false, true)
end

function XUiPanelSGPhotoWall:OnCreateDecoration(id, cfgId)
    local data =  XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_CREATE_PHOTO_ADORN, {
        Id = id,
        SoId = self._Control:GetFurnitureSceneObjId(cfgId),
    })
    self._Control:AddFightFurnitureData(id, data, nil, false)
    self._PanelOp:CreateFurniture(0, id, true, false, false)
end

function XUiPanelSGPhotoWall:OnCreateDecorationBoard(id, cfgId)
    local data =  XMVCA.X3CProxy:Send(X3C_CMD.CMD_DORMITORY_CHANGE_OR_CREATE_PHOTO_WALL, {
        Id = self._Control:GetFurnitureSceneObjId(cfgId),
    })
    self._Control:UpdateWallFightData(data)
    --更换容器
    self._Control:CloneContainerFurnitureData(self._AreaType):ChangeContainer(id, cfgId)
    --通知战斗更换
    self._PanelOp:SwitchContainer()
    self.Parent:UpdateView()
end

return XUiPanelSGPhotoWall