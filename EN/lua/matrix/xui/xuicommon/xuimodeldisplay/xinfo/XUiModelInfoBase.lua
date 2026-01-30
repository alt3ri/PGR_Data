---@class XUiModelInfoBase
local XUiModelInfoBase = XClass(nil, "XUiModelInfoBase")

---@param controller XUiModelDisplayController
---@param modelInfo XUiModelDisplayInfo
function XUiModelInfoBase:InitModelController(controller, modelInfo)
end

function XUiModelInfoBase:IsEmpty()
    return true
end

function XUiModelInfoBase:GetInfoType()
    XLog.Error("No NotImplementedException")
end

return XUiModelInfoBase