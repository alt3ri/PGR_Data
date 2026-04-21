--- 格子基类
--- 暂不继承XUiNode的原因：该系统已趋近完善，很多逻辑都是直接面向GameObject，先减少对已有逻辑的影响
---@class XUiLineArithmetic3GridItem
local XUiLineArithmetic3GridItem = XClass(nil, 'XUiLineArithmetic3GridItem')

function XUiLineArithmetic3GridItem:Ctor(ui, parent)
    self.Parent = parent
    
    XTool.InitUiObjectByUi(self, ui)
end

return XUiLineArithmetic3GridItem