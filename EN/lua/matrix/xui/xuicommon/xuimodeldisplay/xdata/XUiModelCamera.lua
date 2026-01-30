local XUiModelDataBase = require("XUi/XUiCommon/XUiModelDisplay/XData/XUiModelDataBase")

---@class XUiModelCamera : XUiModelDataBase
local XUiModelCamera = XClass(XUiModelDataBase, "XUiModelCamera")

function XUiModelCamera:Ctor()
    self.Camera = false
end

function XUiModelCamera:IsEmpty()
    return not self.Camera or XTool.UObjIsNil(self.Camera)
end

---@param helper XUiModelDisplayHelper
function XUiModelCamera:IsCompatibility(componentType, helper)
    return helper.CheckComponentDerived(XEnumConst.UiModel.ComponentType.Camera, componentType)
end

function XUiModelCamera:Clear()
    self.Camera = false
end

function XUiModelCamera:InjectComponent(component)
    if not component or self:IsEmpty() then
        return
    end

    component:SetCamera(self.Camera)
end

function XUiModelCamera:SetCamera(camera)
    self.Camera = camera or false
end

return XUiModelCamera
