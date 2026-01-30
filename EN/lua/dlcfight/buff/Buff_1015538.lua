local Base = require("Buff/Buff_1015500")
---@class XBuffScript1015538 : XBuffScript1015000
local XBuffScript1015538 = XDlcScriptManager.RegBuffScript(1015538, "XBuffScript1015538", Base)


--效果说明：自身血量低于x时，增加回复y点

function XBuffScript1015538:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015539
    self.magicKind = 1015539
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015538

    