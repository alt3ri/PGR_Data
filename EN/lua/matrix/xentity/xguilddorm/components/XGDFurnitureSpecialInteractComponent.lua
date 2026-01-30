local Quaternion = CS.UnityEngine.Quaternion
local XGDComponet = require("XEntity/XGuildDorm/Components/XGDComponet")
local XGuildDormHelper = CS.XGuildDormHelper
---@class XGDFurnitureSpecialInteractComponent : XGDComponet
local XGDFurnitureSpecialInteractComponent = XClass(XGDComponet, "XGDFurnitureSpecialInteractComponent")

---@param role XGuildDormRole
---@param room XGuildDormRoom
function XGDFurnitureSpecialInteractComponent:Ctor(role, room)
    self.Role = role
    self.Room = room
    self.MoveAgent = nil
    self.Transform = nil
    self.AngleSpeed = XGuildDormConfig.GetRoleInteracAngleSpeed()
    self.IsDirectInteract = false
    self.InteractStatus = XGuildDormConfig.InteractStatus.End
    self.InteractInfo = nil

    self.SignalData = XSignalData.New()
end

function XGDFurnitureSpecialInteractComponent:GetSignalData()
    return self.SignalData
end

function XGDFurnitureSpecialInteractComponent:Init()
    XGDFurnitureSpecialInteractComponent.Super.Init(self)
    self:UpdateRoleDependence()
end

function XGDFurnitureSpecialInteractComponent:UpdateRoleDependence()
    self.MoveAgent = self.Role:GetMoveAgent()
    self.Transform = self.Role:GetRLRole():GetTransform()
end

function XGDFurnitureSpecialInteractComponent:BeginInteract(currentInteractInfo, isDirectInteract)
    self.InteractInfo = currentInteractInfo
    if isDirectInteract == nil then isDirectInteract = false end
    self.IsDirectInteract = isDirectInteract

    self._IsOpen = false
    -- 改变状态
    self.Role:EnableCharacterController(false)
    self.InteractStatus = XGuildDormConfig.InteractStatus.Begin
end

function XGDFurnitureSpecialInteractComponent:Update(dt)
    if self.InteractStatus == XGuildDormConfig.InteractStatus.Begin then
        self.Role:ChangeStateMachine(XGuildDormConfig.RoleFSMType.IDLE)
        self.InteractStatus = XGuildDormConfig.InteractStatus.Playing
    elseif self.InteractStatus == XGuildDormConfig.InteractStatus.Playing then
        if not self._IsOpen then
            self._IsOpen = true
            self:OpenMovie()
        end
    end
end

function XGDFurnitureSpecialInteractComponent:OpenMovie()
    XDataCenter.GuildDormManager.SetFurnitureSpeicalInteractGameStatus(self.InteractInfo.Id)
    -- 控制镜头
    ---@type XGuildDormRoom
    local room = XDataCenter.GuildDormManager.GetCurrentRoom()
    local furniture = room:GetFurnitureById(self.InteractInfo.Id)
    local focusPoint = furniture.FurnitureModel.Transform

    focusPoint = self:GetFocusPoint(furniture) or furniture.FurnitureModel.Transform
    
    local cameraController = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCameraController()
    
    self._CameraTargetXCache = cameraController.TargetAngleX
    self._CameraTargetYCache = cameraController.TargetAngleY
    
    self:SetCameraFocus(cameraController, focusPoint)
    
    self._CameraAllowXAxisCache = cameraController.AllowXAxis
    self._CameraAllowYAxisCache = cameraController.AllowYAxis
    cameraController.AllowXAxis = false
    cameraController.AllowYAxis = false
    -- 隐藏所有玩家模型
    local roles = self.Room:GetRoles()
    for i, v in pairs(roles) do
        local rlRole = v:GetRLRole()
        if rlRole then
            rlRole:SetTransparent(0)
        end
    end
    
    self:OpenMovieUI()
end

function XGDFurnitureSpecialInteractComponent:OnInteractEnd()
    self.InteractStatus = XGuildDormConfig.InteractStatus.End
    self.Role:EnableCharacterController(true)
    -- 显示所有玩家模型
    local roles = self.Room:GetRoles()
    for i, v in pairs(roles) do
        local rlRole = v:GetRLRole()
        if rlRole then
            rlRole:SetTransparent(1)
        end
    end
    XDataCenter.GuildDormManager.ResetFurnitureSpeicalInteractGameStatus(self.InteractInfo.Id)
    local cameraController = XDataCenter.GuildDormManager.SceneManager.GetCurrentScene():GetCameraController()
    cameraController:SetNpcInteract(false)
    cameraController:SetFollowObj(self.Role:GetRLRole():GetTransform(), 0, false)
    cameraController.AllowXAxis = self._CameraAllowXAxisCache
    cameraController.AllowYAxis = self._CameraAllowYAxisCache
    cameraController.TargetAngleX = self._CameraTargetXCache
    cameraController.TargetAngleY = self._CameraTargetYCache
end

--region 逻辑拆分和封装，以支持子类重写

function XGDFurnitureSpecialInteractComponent:GetFocusPoint(furniture)
    local furnitureInteractionCfg = XGuildDormConfig.GetFurnitureInteraction(self.InteractInfo.Id)

    if not string.IsNilOrEmpty(furnitureInteractionCfg.FocusGameObjectPath) then
        return furniture.FurnitureModel.Transform:Find(furnitureInteractionCfg.FocusGameObjectPath)
    end
end

function XGDFurnitureSpecialInteractComponent:SetCameraFocus(cameraController, focusPoint)
    local furnitureInteractionCfg = XGuildDormConfig.GetFurnitureInteraction(self.InteractInfo.Id)

    cameraController:SetNpcInteract(true, furnitureInteractionCfg.CameraDistance)
    cameraController:SetFollowObj(focusPoint)
    cameraController:SetTartAngle(Vector2(focusPoint.eulerAngles.y + 180 + furnitureInteractionCfg.CameraAngleYOffset, furnitureInteractionCfg.CameraAngleXOffset))
end

function XGDFurnitureSpecialInteractComponent:OpenMovieUI()
    XLuaUiManager.OpenWithCloseCallback('UiGuildDormFurnitureMovieCommon', handler(self, self.OnInteractEnd), self.InteractInfo.Id, function()
        self.SignalData:EmitSignal("UpdateBtnInteractName")
    end)
end

--endregion

return XGDFurnitureSpecialInteractComponent