---@class XUiPanelSGWall : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiSkyGardenDormPhotoWall
---@field _PanelMenu XUiPanelSGWallMenu
---@field _PanelTab XUiPanelSGWallTab
---@field _PanelOp XUiPanelSGWallOp
local XUiPanelSGWall = XClass(XUiNode, "XUiPanelSGWall")

function XUiPanelSGWall:InitUi()
    local areaType = self._AreaType
    self._PanelMenu = require("XUi/XUiSkyGarden/XDorm/Panel/XUiPanelSGWallMenu").New(self.PanelMenu, self, areaType)
    self.CanvasGroupList = self.Transform:GetComponentsInChildren(typeof(CS.UnityEngine.CanvasGroup))
end

function XUiPanelSGWall:InitCb()
end

function XUiPanelSGWall:Refresh()
    self._PanelMenu:RefreshDynamicTable()
end

function XUiPanelSGWall:OnSelectTab(typeId, furnitureId)
    self._PanelMenu:OnTypeIdChanged(typeId, furnitureId)
end

function XUiPanelSGWall:OnSelectFurniture(id, cfgId, isCreate, isAlbumPhoto)
end

--- 选中操作框的家具
---@param id number
function XUiPanelSGWall:OnSelectFurnitureGridOp(id, tabIndex)
    if not id or id <= 0 then
        return self._PanelTab:SelectIndex(tabIndex)
    end
    local cfgId = self._Control:GetFurnitureConfigIdById(id)
    local typeId = self._Control:GetFurnitureTypeId(cfgId)
    self._PanelTab:OnSelectByTypeId(typeId, cfgId)
end

function XUiPanelSGWall:InitFurniture()
end

function XUiPanelSGWall:EnterEditMode()
    self._PanelMenu:Close()
    self._PanelTab:Close()
    self.Parent:EnterEditMode(false)
end

function XUiPanelSGWall:ExitEditMode()
    self.Parent:ExitEditMode(true)
    self._PanelMenu:Open()
    self._PanelTab:Open()
end

function XUiPanelSGWall:ClearDecoration()
    self._PanelOp:ClearDecoration()
end

function XUiPanelSGWall:TryCheckOpIsSafe(tips)
    return self._PanelOp:TryCheckOpIsSafe(tips)
end

function XUiPanelSGWall:RevertDecoration()
    self._PanelOp:RevertDecoration()
end

function XUiPanelSGWall:ApplyNewLayout()
    self._PanelOp:ApplyNewLayout()
end

function XUiPanelSGWall:OnDestroy()
end

function XUiPanelSGWall:SetVisible(value)
    self:SetBlocksRaycasts(value)
    if value then
        self._PanelMenu:Open()
        self._PanelTab:Open()
    else
        self._PanelMenu:Close()
        self._PanelTab:Close()
    end
end

function XUiPanelSGWall:SetBlocksRaycasts(value)
    for i = 0, self.CanvasGroupList.Length - 1 do
        self.CanvasGroupList[i].blocksRaycasts = value
    end
end

function XUiPanelSGWall:GetTypeId()
    return self._PanelTab:GetTypeId()
end

function XUiPanelSGWall:RotateByHandle(z)
    self._PanelOp:RotateByHandle(z)
end

return XUiPanelSGWall