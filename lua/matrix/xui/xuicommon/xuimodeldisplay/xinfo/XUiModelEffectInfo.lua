local XUiModelInfoBase = require("XUi/XUiCommon/XUiModelDisplay/XInfo/XUiModelInfoBase")

---@class XUiModelEffectInfo : XUiModelInfoBase
local XUiModelEffectInfo = XClass(XUiModelInfoBase, "XUiModelEffectInfo")

function XUiModelEffectInfo:Ctor()
    self.EffectId = 0
    self.EffectUrl = ""
    self.TargetAnimation = ""
    self.TargetRootName = ""
    self.DelayFrame = 0
    self.IsIgnoreRotate = true
end

---@param controller XUiModelDisplayController
---@param modelInfo XUiModelDisplayInfo
function XUiModelEffectInfo:InitModelController(controller, modelInfo)
    if not controller then
        return
    end

    local effectInfo = self:ToClass()
    local componentId = modelInfo.ComponentId

    controller.Controller:AddModelEffect(modelInfo.Key, componentId, self.EffectId, self.EffectUrl, effectInfo)
end

function XUiModelEffectInfo:IsEmpty()
    return not XTool.IsNumberValid(self.EffectId) or string.IsNilOrEmpty(self.EffectUrl)
end

function XUiModelEffectInfo:GetInfoType()
    return XMVCA.XBigWorldCommon.ModelInfoType.Effect
end

function XUiModelEffectInfo:ToClass()
    local info = CS.XUiComponent.XModelDisplay.XCommon.XUiModelEffectInfo()

    info.TargetAnimation = self.TargetAnimation
    info.TargetRootName = self.TargetRootName
    info.DelayFrame = self.DelayFrame
    info.IsIgnoreRotate = self.IsIgnoreRotate

    return info
end

return XUiModelEffectInfo