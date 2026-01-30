---@class XUiPlotExhibitionDetailCharacterGrid : XUiNode
---@field _Control XPlotExhibitionControl
local XUiPlotExhibitionDetailCharacterGrid = XClass(XUiNode, "XUiPlotExhibitionDetailCharacterGrid")

function XUiPlotExhibitionDetailCharacterGrid:OnStart()
end

---@param data XPlotExhibitionControlCharacter
function XUiPlotExhibitionDetailCharacterGrid:Update(data)
    --self.GridMember
    self.RImgHead:SetRawImage(data.Icon)
    self.TxtName.text = data.Name
    self.TxtNum.text = data.Progress .. "%"
    self.TagNew.gameObject:SetActiveEx(data.IsNew)
end

function XUiPlotExhibitionDetailCharacterGrid:Deselected()
    self.GridMember:SetButtonState(CS.UiButtonState.Normal)
end

function XUiPlotExhibitionDetailCharacterGrid:Select()
    self.GridMember:SetButtonState(CS.UiButtonState.Select)
end

return XUiPlotExhibitionDetailCharacterGrid