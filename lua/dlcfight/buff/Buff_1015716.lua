local Base = require("Buff/Buff_1015700")
---@class XBuffScript1015716 : XBuffScript1015700
local XBuffScript1015716 = XDlcScriptManager.RegBuffScript(1015716, "XBuffScript1015716", Base)


--效果说明：进入战斗时30%的概率触发：本局战斗火伤增加30%

function XBuffScript1015716:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015717
    self.magicKind = 1015717
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015716

    