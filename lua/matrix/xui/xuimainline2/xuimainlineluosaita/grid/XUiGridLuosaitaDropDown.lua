---@class XUiGridLuosaitaDropDown : XUiNode
---@field Parent XUiMainLineLuosaitaMain
---@field _Control XMainLineLuosaitaControl
local XUiGridLuosaitaDropDown = XClass(XUiNode, "XUiGridLuosaitaDropDown")

function XUiGridLuosaitaDropDown:OnStart()

end

---@param data XTableMainLineLuosaitaSection
function XUiGridLuosaitaDropDown:Refresh(data)
    self.TxtName.text = data.Name
    local unLock = self.Parent._Control:IsSectionUnlock(data.Id)
    self.UiButton:SetDisable(not unLock)
end

return XUiGridLuosaitaDropDown
