---@class XUiLineArithmetic2GameEventGrid : XUiNode
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2GameEventGrid = XClass(XUiNode, "XUiLineArithmetic2GameEventGrid")

---@param data XLineArithmetic2ControlDataGridDesc
function XUiLineArithmetic2GameEventGrid:Update(data)
    --self.ImgBg
    --self.TxtNum.gameObject:SetActiveEx(false)
    self.RImgType:SetRawImage(data.Icon)
    --self.TxtName.text = data.Name
    self.TxtDetail.text = data.Desc
end

return XUiLineArithmetic2GameEventGrid