---@class XUiPBRCommonDropdownItem: XUiNode
---@field protected _Control
---@field Parent
local XUiPBRCommonDropdownItem = XClass(XUiNode, "XUiPBRCommonDropdownItem")


function XUiPBRCommonDropdownItem:OnStart(callback)
    self.CallBack = callback
    self.Button.CallBack = function() self:OnClickBtnItem() end
end

function XUiPBRCommonDropdownItem:RefreshShow(index, desc, isSelected)
    self.Index= index
    self.TxtName.text = desc
    self.Select.gameObject:SetActiveEx(isSelected)
end

function XUiPBRCommonDropdownItem:OnClickBtnItem()
    if XTool.IsNumberValidEx(self.Index) then
        self.CallBack(self.Index)
    end
end

return XUiPBRCommonDropdownItem