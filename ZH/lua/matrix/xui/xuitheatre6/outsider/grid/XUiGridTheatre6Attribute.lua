---@class XUiGridTheatre6Attribute : XUiNode 左侧属性条目Grid
---@field _Control XTheatre6Control
local XUiGridTheatre6Attribute = XClass(XUiNode, "XUiGridTheatre6Attribute")

function XUiGridTheatre6Attribute:OnStart()
end

---@param attrId number 属性Id（Theatre6Attr表Id）
---@param totalValue number 该属性的总加成值
function XUiGridTheatre6Attribute:Update(attrId, totalValue)
    local attrCfg = self._Control:GetAttrConfig(attrId)
    self.UiTxtName.text = attrCfg.Name
    self.UiTxtNum.text = tostring(totalValue)
end

return XUiGridTheatre6Attribute
