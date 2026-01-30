local XGDFurnitureSpecialInteractComponent = require("XEntity/XGuildDorm/Components/XGDFurnitureSpecialInteractComponent")
---@class XGDFurnitureRandomBoxInteractComponent : XGDFurnitureSpecialInteractComponent
local XGDFurnitureRandomBoxInteractComponent = XClass(XGDFurnitureSpecialInteractComponent, "XGDFurnitureRandomBoxInteractComponent")

---@overload
function XGDFurnitureRandomBoxInteractComponent:BeginInteract(currentInteractInfo, isDirectInteract, randomBoxData)
    self._RandomBoxData = randomBoxData
    self.Super.BeginInteract(self, currentInteractInfo, isDirectInteract)
end

---@overload
function XGDFurnitureRandomBoxInteractComponent:GetFocusPoint(furniture)
    local furnitureRandomBoxCfg = XGuildDormConfig.GetFurnitureRandomBox(self.InteractInfo.Id)

    if not string.IsNilOrEmpty(furnitureRandomBoxCfg.FocusPointPath) then
        return furniture.FurnitureModel.Transform:Find(furnitureRandomBoxCfg.FocusPointPath)
    end
end

---@overload
function XGDFurnitureRandomBoxInteractComponent:SetCameraFocus(cameraController, focusPoint)
    local furnitureRandomBoxCfg = XGuildDormConfig.GetFurnitureRandomBox(self.InteractInfo.Id)

    cameraController:SetNpcInteract(true, furnitureRandomBoxCfg.CameraDistance)
    cameraController:SetFollowObj(focusPoint)
    cameraController:SetTartAngle(Vector2(focusPoint.eulerAngles.y + 180, 0))
end

---@overload
function XGDFurnitureRandomBoxInteractComponent:OpenMovieUI()
    XLuaUiManager.OpenWithCloseCallback('UiGuildDormFurnitureMovieRandomBox', handler(self, self.OnInteractEnd), self.InteractInfo.Id, self._RandomBoxData)
end

return XGDFurnitureRandomBoxInteractComponent