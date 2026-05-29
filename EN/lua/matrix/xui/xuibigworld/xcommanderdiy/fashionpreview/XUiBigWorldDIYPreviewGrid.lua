local XUIDIYGridBase = require("XUi/XUiBigWorld/XCommanderDIY/FashionPreview/XUIDIYGridBase")
---@class XUiBigWorldDIYPreviewGrid : XUiNode
local XUiBigWorldDIYPreviewGrid = XClass(XUIDIYGridBase, "XUiBigWorldDIYPreviewGrid")

function XUiBigWorldDIYPreviewGrid:OnClickGrid(eventData, data)
    self:SetSelect(true)
end

function XUiBigWorldDIYPreviewGrid:OnSetData(data)
    self.ImgColour:SetSprite(data.Icon)
    self.PanelNow.gameObject:SetActiveEx(false)
end

function XUiBigWorldDIYPreviewGrid:OnSelectChangde(isSelect)
    self.ImgSelect.gameObject:SetActiveEx(isSelect)
end

return XUiBigWorldDIYPreviewGrid
