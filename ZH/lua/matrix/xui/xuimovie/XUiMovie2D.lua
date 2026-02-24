local XUiMovie = require("XUi/XUiMovie/XUiMovie")

---@class XUiMovie2D : XUiMovie 和UiMove功能一样，只是UI配置无SceneUrl和ModelUrl，UI3D场景会影响战斗场景的信息
local XUiMovie2D = XLuaUiManager.Register(XUiMovie, "UiMovie2D")

function XUiMovie2D:OnInitScene()
    
end

return XUiMovie2D