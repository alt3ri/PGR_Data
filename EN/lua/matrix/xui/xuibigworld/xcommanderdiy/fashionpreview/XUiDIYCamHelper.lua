---@class XUiDIYCamHelper
---@field _Control XBigWorldCommanderDIYControl
---@field _ModelHelper XUiBigWorldDIYModelHelper
local XUiDIYCamHelper = XClass(nil, "XUiDIYCamHelper")

function XUiDIYCamHelper:Ctor(control, modelHelper, modelGameObject)
    self._Control = control
    self._CameraMoveRange = control:GetCameraMoveRange()
    -- 目前这里 self._CameraControl 和 self._ModelHelper 混用，后面看看有没有机会把Camera相关的都抽到这边来
    self._CameraControl = modelGameObject:GetComponent(typeof(CS.XUiComponent.XUiStateControl))
    self._ModelHelper = modelHelper
    self._CameraKeys = {
        Body = {
            [XEnumConst.PlayerFashion.Gender.Male] = "ManBody",
            [XEnumConst.PlayerFashion.Gender.Female] = "WomanBody"
        },
        NearBody = {
            [XEnumConst.PlayerFashion.Gender.Male] = "ManNearBody",
            [XEnumConst.PlayerFashion.Gender.Female] = "WomanNearBody"
        }
    }
    self._NearMaleCamera = modelGameObject.transform:FindTransform("VCameraManNear")
    self._NearFemaleCamera = modelGameObject.transform:FindTransform("VCameraWomanNear")
    self._OriginalMaleCameraPosY = self._NearMaleCamera.transform.localPosition.y
    self._OriginalFemaleCameraPosY = self._NearFemaleCamera.transform.localPosition.y
    
    self.gender = self._Control:GetCurrentGender()
end

function XUiDIYCamHelper:InitUI(sliderCharacter, btnLensIn, btnLensOut, gender)
    self._SliderCharacter = sliderCharacter
    self._BtnLensIn = btnLensIn
    self._BtnLensOut = btnLensOut
    self.gender = gender
    self:ChangeBodyCamera(false)
end

function XUiDIYCamHelper:SetGender(gender)
    self.gender = gender
    return self
end

function XUiDIYCamHelper:Focus(key)
    local cameraKey = self._CameraKeys[key][self.gender]
    self._CameraControl:ChangeState(cameraKey)
end

function XUiDIYCamHelper:ChangeBodyCamera(isIn)
    if isIn then
        self:Focus("NearBody")
        self:_ChangeCameraLens(true)
    else
        self:Focus("Body")
        self:_ChangeCameraLens(false)
    end
    self._SliderCharacter.gameObject:SetActiveEx(isIn)
end

function XUiDIYCamHelper:MoveNearCamera(offset)
    self._ModelHelper:MoveNearCamera(self.gender, offset)
end

function XUiDIYCamHelper:GetCameraMoveRange()
    return self._CameraMoveRange
end

-- 私有方法

function XUiDIYCamHelper:ChangeCamera(key)
    self._ModelHelper:ChangeCamera(key)
end

function XUiDIYCamHelper:_ChangeCameraLens(isIn)
    self._BtnLensOut.gameObject:SetActiveEx(not isIn)
    self._BtnLensIn.gameObject:SetActiveEx(isIn)
    if isIn then
        self._SliderCharacter.value = 0
    end
end

function XUiDIYCamHelper:_GetCurrentBodyCameraKey()
    return self._CameraKeys.Body[self.gender]
end

function XUiDIYCamHelper:_GetCurrentNearBodyCameraKey()
    return self._CameraKeys.NearBody[self.gender]
end

return XUiDIYCamHelper
