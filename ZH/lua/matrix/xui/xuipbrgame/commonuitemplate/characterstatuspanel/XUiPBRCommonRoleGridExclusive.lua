--- 通用的角色特质描述格子
---@class XUiPBRCommonRoleGridExclusive : XUiNode
local XUiPBRCommonRoleGridExclusive = XClass(XUiNode, "XUiPBRCommonRoleGridExclusive")

function XUiPBRCommonRoleGridExclusive:OnStart(...)
    self:InitComponents()
end

function XUiPBRCommonRoleGridExclusive:OnEnable()
end

function XUiPBRCommonRoleGridExclusive:OnDisable()
end

function XUiPBRCommonRoleGridExclusive:OnDestroy()
end

function XUiPBRCommonRoleGridExclusive:InitComponents()
end

---@param info XPBRCharacterExclusiveDescParams
function XUiPBRCommonRoleGridExclusive:Refresh(info)
    self.TxtDesc.text = info.Desc
end
return XUiPBRCommonRoleGridExclusive
