---@class XUiGridLuosaitaBlock : XUiNode
---@field Parent XUiPanelLuosaitaSection
---@field _Control XMainLineLuosaitaControl
local XUiGridLuosaitaBlock = XClass(nil, "XUiGridLuosaitaBlock")

function XUiGridLuosaitaBlock:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    self.RImgRed = self.Transform:Find("RImgRed"):GetComponent("RawImage")
    self.RImgGreen = self.Transform:Find("RImgGreen"):GetComponent("RawImage")
end

function XUiGridLuosaitaBlock:Refresh(blockData)
    if not blockData then
        self.GameObject:SetActiveEx(false)
        return
    end
    self.GameObject:SetActiveEx(blockData)
    self.RImgRed.gameObject:SetActiveEx(not blockData:IsOccupied())
    self.RImgGreen.gameObject:SetActiveEx(blockData:IsOccupied())
end

return XUiGridLuosaitaBlock
