---@class XUiModelDataBase
local XUiModelDataBase = XClass(nil, "XUiModelDataBase")

function XUiModelDataBase:IsEmpty()
    return false
end

---@param helper XUiModelDisplayHelper
function XUiModelDataBase:IsCompatibility(componentType, helper)
    return not self:IsEmpty()
end

function XUiModelDataBase:Clear()
end

function XUiModelDataBase:InjectComponent(component)
end

return XUiModelDataBase
