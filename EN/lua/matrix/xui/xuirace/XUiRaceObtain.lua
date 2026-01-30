---@class XUiRaceObtain : XLuaUi 获取道具
---@field _Control XRaceControl
local XUiObtain = require("XUi/XUiObtain/XUiObtain")
local XUiRaceObtain = XLuaUiManager.Register(XUiObtain, "UiRaceObtain")

function XUiRaceObtain:AutoInitUi()
end

function XUiRaceObtain:PlayAnimationAniObtain()
end

return XUiRaceObtain