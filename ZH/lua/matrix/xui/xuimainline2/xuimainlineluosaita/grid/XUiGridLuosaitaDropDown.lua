local CSNormal = CS.UiButtonState.Normal
local CSSelect = CS.UiButtonState.Select
local CSDisable = CS.UiButtonState.Disable

---@class XUiGridLuosaitaDropDown : XUiNode
---@field Parent XUiMainLineLuosaitaMain
---@field _Control XMainLineLuosaitaControl
local XUiGridLuosaitaDropDown = XClass(XUiNode, "XUiGridLuosaitaDropDown")

function XUiGridLuosaitaDropDown:OnStart()

end

---@param data XTableMainLineLuosaitaSection
function XUiGridLuosaitaDropDown:Refresh(data)
    self.TxtName.text = data.Name
    local isSelect = self.Parent:GetCurSectionId() == data.Id
    local state = isSelect and CSSelect or CSNormal
    local unLock = self.Parent._Control:IsSectionUnlock(data.Id)
    if not unLock then
        state = CSDisable
    end
    self.UiButton:SetButtonState(state)
end

return XUiGridLuosaitaDropDown
