local XUiGridLuosaitaMember = require("XUi/XUiMainLine2/XUiMainLineLuosaita/Grid/XUiGridLuosaitaMember")

---@class XUiGridLuosaitaMemberCharacter : XUiNode
---@field Parent XUiPanelLuosaitaSection
---@field _Control XMainLineLuosaitaControl
---@field MemberData XMainLineLuosaitaPositionInfo
local XUiGridLuosaitaMemberCharacter = XClass(XUiGridLuosaitaMember, "XUiGridLuosaitaMemberCharacter")

function XUiGridLuosaitaMemberCharacter:OnStart(prefabName)
    self:RegisterUiEvents()
end

function XUiGridLuosaitaMemberCharacter:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnBtnClick)
end

function XUiGridLuosaitaMemberCharacter:OnBtnClick()
    if self.Parent:IsDragOperation() then
        return
    end

    self:OpenMemberDetail()
end

---@param memberData XMainLineLuosaitaPositionInfo
function XUiGridLuosaitaMemberCharacter:Refresh(memberData)
    self.MemberData = memberData

    local characterId = memberData:GetCharacterId()
    local head = self._Control:GetConfig():GetCharacterHead(characterId)
    self.RImgHead:SetRawImage(head)
end

function XUiGridLuosaitaMemberCharacter:OnDestory()
    
end

return XUiGridLuosaitaMemberCharacter
