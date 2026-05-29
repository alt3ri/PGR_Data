---@class XUiGridPhotographSceneTabTag
---@field Parent
local XUiGridPhotographSceneTabTag = XClass(nil, "XUiGridPhotographSceneTabTag")

function XUiGridPhotographSceneTabTag:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
end


function XUiGridPhotographSceneTabTag:RefreshText(tab)
    if self.TxtTag then
        self.TxtTag.text = tab
    end
end

return XUiGridPhotographSceneTabTag