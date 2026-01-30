---@class XUiGridLuosaitaMember
---@field Parent XUiPanelLuosaitaSection
---@field UiMain XUiMainLineLuosaitaMain
---@field _Control XMainLineLuosaitaControl
---@field MemberData XMainLineLuosaitaPositionInfo
local XUiGridLuosaitaMember = XClass(XUiNode, "XUiGridLuosaitaMember")

function XUiGridLuosaitaMember:Init(linkGo)
    self.LinkGameObject = linkGo
    self.UiMain = self.Parent.Parent
    self.V2 = Vector2(0, 0)
    self.Camera = CS.XUiManager.Instance.UiCamera
end

---@param memberData XMainLineLuosaitaPositionInfo
function XUiGridLuosaitaMember:Refresh(memberData)
    self.MemberData = memberData
end

function XUiGridLuosaitaMember:OpenMemberDetail()
    local posId = self.MemberData:GetPosId()
    self.UiMain:OpenPanelPositionDetail(posId)
end

-- 获取类型
function XUiGridLuosaitaMember:GetType()
    return self.MemberData:GetType()
end

-- 获取友军id
function XUiGridLuosaitaMember:GetArmyId()
    return self.MemberData:GetArmyId()
end

function XUiGridLuosaitaMember:IsInScreenSize()
    local screenPos = self.Camera:WorldToScreenPoint(self.Transform.position)
    return screenPos.x >= 0 and screenPos.x <= CS.UnityEngine.Screen.width and screenPos.y >= 0 and screenPos.y <= CS.UnityEngine.Screen.height
end

function XUiGridLuosaitaMember:Hide()
    self:Close()
end

return XUiGridLuosaitaMember
