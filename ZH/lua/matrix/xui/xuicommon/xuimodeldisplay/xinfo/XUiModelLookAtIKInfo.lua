local XUiModelInfoBase = require("XUi/XUiCommon/XUiModelDisplay/XInfo/XUiModelInfoBase")

---@class XUiModelLookAtIKInfo : XUiModelInfoBase
local XUiModelLookAtIKInfo = XClass(XUiModelInfoBase, "XUiModelLookAtIKInfo")

function XUiModelLookAtIKInfo:Ctor()
    self.Target = nil
    self.Weight = 1
    self.BodyWeight = 0.2
    self.HeadWeight = 1
    self.EyesWeight = 0.5
    self.ClampWeight = 0.5
    self.ClampWeightHead = 0.8
    self.ClampWeightEyes = 0.95
    self.LerpTime = 0
end

function XUiModelLookAtIKInfo:IsEmpty()
    return XTool.UObjIsNil(self.Target)
end

function XUiModelLookAtIKInfo:SetWeight(weight)
    self.Weight = weight or 1
end

function XUiModelLookAtIKInfo:SetBodyWeight(weight)
    self.BodyWeight = weight or 0.2
end

function XUiModelLookAtIKInfo:SetHeadWeight(weight)
    self.HeadWeight = weight or 1
end

function XUiModelLookAtIKInfo:SetEyesWeight(weight)
    self.EyesWeight = weight or 0.5
end

function XUiModelLookAtIKInfo:SetClampWeight(weight)
    self.ClampWeight = weight or 0.5
end

function XUiModelLookAtIKInfo:SetClampWeightHead(weight)
    self.ClampWeightHead = weight or 0.8
end

function XUiModelLookAtIKInfo:SetClampWeightEyes(weight)
    self.ClampWeightEyes = weight or 0.95
end

function XUiModelLookAtIKInfo:SetLerpTime(lerpTime)
    self.LerpTime = lerpTime
end

---@param controller XUiModelDisplayController
---@param modelInfo XUiModelDisplayInfo
function XUiModelLookAtIKInfo:InitModelController(controller, modelInfo)
    if not controller then
        return
    end

    controller.Controller:SetLookAtIKTarget(modelInfo.Key, modelInfo.ComponentId, self.Target, self.LerpTime)
    controller.Controller:SetLookAtIKWeight(modelInfo.Key, modelInfo.ComponentId, self.Weight, self.BodyWeight, self.HeadWeight, self.EyesWeight, self.ClampWeight, self.ClampWeightHead, self.ClampWeightEyes)
end

function XUiModelLookAtIKInfo:GetInfoType()
    return XMVCA.XBigWorldCommon.ModelInfoType.LookAtIK
end

return XUiModelLookAtIKInfo