local XUiModelInfoBase = require("XUi/XUiCommon/XUiModelDisplay/XInfo/XUiModelInfoBase")

---@class XUiModelAnimationIKInfo : XUiModelInfoBase
local XUiModelAnimationIKInfo = XClass(XUiModelInfoBase, "XUiModelAnimationIKInfo")

function XUiModelAnimationIKInfo:Ctor()
    self.Target = nil
    self.Weight = 0
end

function XUiModelAnimationIKInfo:IsEmpty()
    return XTool.UObjIsNil(self.Target)
end

---@param controller XUiModelDisplayController
---@param modelInfo XUiModelDisplayInfo
function XUiModelAnimationIKInfo:InitModelController(controller, modelInfo)
    if not controller then
        return
    end

    controller.Controller:SetAnimationIKTarget(modelInfo.Key, modelInfo.ComponentId, self.Target)
    controller.Controller:SetAnimationIKWeight(modelInfo.Key, modelInfo.ComponentId, self.Weight)
end

function XUiModelAnimationIKInfo:GetInfoType()
    return XMVCA.XBigWorldCommon.ModelInfoType.AnimationIK
end

return XUiModelAnimationIKInfo