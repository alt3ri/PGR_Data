---@class XUiPBRCommonItemDetailTag : XUiNode
local XUiPBRCommonItemDetailTag = XClass(XUiNode, "XUiPBRCommonItemDetailTag")

function XUiPBRCommonItemDetailTag:InitComponents()
end

function XUiPBRCommonItemDetailTag:OnStart(...)
    self:InitComponents()
end

function XUiPBRCommonItemDetailTag:OnEnable()
end

function XUiPBRCommonItemDetailTag:OnDisable()
end

function XUiPBRCommonItemDetailTag:OnDestroy()
end

function XUiPBRCommonItemDetailTag:SetTagShow(tagStr)
    self.TxtTitle.text = tagStr
end

return XUiPBRCommonItemDetailTag
