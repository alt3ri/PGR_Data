local Base = require("Buff/Buff_1015700")
---@class XBuffScript1015730 : XBuffScript1015700
local XBuffScript1015730 = XDlcScriptManager.RegBuffScript(1015730, "XBuffScript1015730", Base)


--效果说明：进入战斗时30%的概率触发：本局战斗火伤增加30%

function XBuffScript1015730:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015731
    self.magicKind = 1015731
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015730

    