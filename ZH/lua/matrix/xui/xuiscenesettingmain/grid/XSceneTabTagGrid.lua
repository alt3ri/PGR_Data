---@class XSceneTabTagGrid: XUiNode
---@field Parent
local XSceneTabTagGrid = XClass(XUiNode, "XSceneTabTagGrid")

function XSceneTabTagGrid:RefreshText(tab)
    if self.TxtTag then
        self.TxtTag.text = tab
    end
end

return XSceneTabTagGrid