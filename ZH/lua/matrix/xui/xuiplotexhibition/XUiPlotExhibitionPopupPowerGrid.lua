---@class XUiPlotExhibitionPopupPowerGrid : XUiNode
---@field _Control XPlotExhibitionControl
local XUiPlotExhibitionPopupPowerGrid = XClass(XUiNode, "XUiPlotExhibitionPopupPowerGrid")

function XUiPlotExhibitionPopupPowerGrid:OnStart()
end

---@param data XTablePlotExhibitionForceCharacter
function XUiPlotExhibitionPopupPowerGrid:Update(data)
    self.TxtName.text = data.Name
    self.TxtNum.text = data.Progress .. "%"
    self.TagNew.gameObject:SetActiveEx(data.IsNew)
    self.RImgHead:SetRawImage(data.Icon)
end

return XUiPlotExhibitionPopupPowerGrid