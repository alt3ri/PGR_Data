local XUiModelDataBase = require("XUi/XUiCommon/XUiModelDisplay/XData/XUiModelDataBase")

---@class XUiModelBone : XUiModelDataBase
local XUiModelBone = XClass(XUiModelDataBase, "XUiModelBone")

function XUiModelBone:Ctor()
    self.Target = false
end

function XUiModelBone:IsEmpty()
    return not self.Target or XTool.UObjIsNil(self.Target)
end

---@param helper XUiModelDisplayHelper
function XUiModelBone:IsCompatibility(componentType, helper)
    return helper.CheckComponentDerived(XEnumConst.UiModel.ComponentType.Bone, componentType)
end

function XUiModelBone:Clear()
    self.Target = false
end

function XUiModelBone:InjectComponent(component)
    if not component or self:IsEmpty() then
        return
    end

    component:SetTarget(self.Target)
end

function XUiModelBone:SetTarget(target)
    self.Target = target or false
end

return XUiModelBone
