

---@class XUiGridSGFurnitureHandBook : XUiNode
---@field _Control XSkyGardenDormControl
---@field Parent XUiSkyGardenDormCodex
local XUiGridSGFurnitureHandBook = XClass(XUiNode, "XUiGridSGFurnitureHandBook")

function XUiGridSGFurnitureHandBook:OnStart()
    self:InitUi()
    self:InitCb()
end

function XUiGridSGFurnitureHandBook:Refresh(furnitureId, selectId)
    self._FurnitureId = furnitureId
    self.RImgIcon:SetRawImage(self._Control:GetFurnitureIcon(furnitureId))
    self.PanelLock.gameObject:SetActiveEx(not self._Control:CheckFurnitureUnlockByConfigId(furnitureId))
    self.UiBigWorldRed.gameObject:SetActiveEx(self:CheckNewMark(furnitureId))
    self:SetSelect(furnitureId == selectId)
end

function XUiGridSGFurnitureHandBook:InitUi()
    self.BtnClick.gameObject:SetActiveEx(false)
    self.PanelEmpty.gameObject:SetActiveEx(false)
end

function XUiGridSGFurnitureHandBook:InitCb()
end

function XUiGridSGFurnitureHandBook:GetId()
    return self._FurnitureId
end

function XUiGridSGFurnitureHandBook:IsSelect()
    return self._IsSelect
end

function XUiGridSGFurnitureHandBook:SetSelect(value)
    self._IsSelect = value
    self.PanelSelect.gameObject:SetActiveEx(value)
end

function XUiGridSGFurnitureHandBook:OnClick()
    self:SetSelect(true)
    self:MarkHandBookNewMark()
end

function XUiGridSGFurnitureHandBook:CheckNewMark(furnitureId)
    local type = self._Control:GetHandBookFurnitureType(furnitureId)
    return self._Control:CheckHandBookNewMark(type, furnitureId)
end

function XUiGridSGFurnitureHandBook:MarkHandBookNewMark()
    if not self._Control:CheckFurnitureUnlockByConfigId(self._FurnitureId) then
        return
    end
    local type = self._Control:GetHandBookFurnitureType(self._FurnitureId)
    self._Control:MarkHandBookNewMark(type, self._FurnitureId)
    self.UiBigWorldRed.gameObject:SetActiveEx(false)
    self.Parent:RefreshRed()
end

return XUiGridSGFurnitureHandBook