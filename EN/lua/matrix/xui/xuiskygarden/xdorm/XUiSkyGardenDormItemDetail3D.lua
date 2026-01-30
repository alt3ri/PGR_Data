
---@class XUiSkyGardenDormItemDetail3D : XBigWorldUi
---@field _Control XSkyGardenDormControl
---@field _DragComponent XDormitory.XFurnitureRotate
---@field Camera3D UnityEngine.Camera
local XUiSkyGardenDormItemDetail3D = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenDormItemDetail3D")

function XUiSkyGardenDormItemDetail3D:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenDormItemDetail3D:OnStart(furnitureId)
    self._FurnitureId = furnitureId
    self:InitView()
end

function XUiSkyGardenDormItemDetail3D:OnDestroy()
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DORMITORY_DESTROY_PREVIEW_GOOD)
    self._SceneObj = nil
end

function XUiSkyGardenDormItemDetail3D:InitUi()
    self._DragComponent = self.DragArea.gameObject:AddComponent(typeof(CS.XDormitory.XFurnitureRotate))
    self._DragComponent:ChangeSpeed(self._Control:GetDragSpeed())
end

function XUiSkyGardenDormItemDetail3D:InitCb()
    self.BtnBack:AddEventListener(handler(self, self.Close))
end

function XUiSkyGardenDormItemDetail3D:InitView()
    local id = self._FurnitureId

    local defaultFov = self._Control:GetDefaultCameraFOV()
    local k = -defaultFov / 2
    local b = defaultFov - k
    local fov = k * self._Control:GetHandBookFurnitureScale(id) + b
    fov = math.max(0.1, fov)
    self.Camera3D.fieldOfView = fov
    
    --region 正式代码
    
    local data = XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_DORMITORY_CREATE_PREVIEW_GOOD, {
        SoId = self._Control:GetFurnitureSceneObjId(id),
        GoodsType = self._Control:GetFurnitureTypeId(id),
        Root = self.Panel
    })
    self.TxtItem.text = self._Control:GetFurnitureName(id)
    self._SceneObj = data.ActorRef
    if data and data.ActorRef then
        local rotateX, rotateY = self._Control:GetHandBookFurnitureRotationX(id), self._Control:GetHandBookFurnitureRotationY(id)
        if rotateX ~= 0 or rotateY ~= 0 then
            data.ActorRef:SetRotation(CS.UnityEngine.Quaternion.Euler(rotateX, rotateY, 0))
        end
        local positionY = self._Control:GetHandBookFurniturePositionY(id)
        if positionY ~= 0 then
            local p = data.ActorRef:GetPosition()
            data.ActorRef:SetPosition(Vector3(p.x, p.y + positionY, p.z))
        end
        self._DragComponent:SetComponent(data.ActorRef)
        self.Camera3D.transform.position = CS.StatusSyncFight.XFightClient.FightInstance.RLManager:GetRenderPos(self.Camera3D.transform.position)
    end

    

    --endregion


    --测试代码
    --local obj = CS.UnityEngine.GameObject("TestCube")
    --obj.transform:SetParent(self.Panel)
    --obj.transform.localPosition = Vector3.zero
    --obj.transform.localScale = Vector3.one
    --self._DragComponent:SetComponent(obj.transform)
end