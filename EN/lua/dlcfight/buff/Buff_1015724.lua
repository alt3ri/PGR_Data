local Base = require("Buff/Buff_1015700")
---@class XBuffScript1015724 : XBuffScript1015700
local XBuffScript1015724 = XDlcScriptManager.RegBuffScript(1015724, "XBuffScript1015724", Base)


--效果说明：进入战斗时30%的概率触发：本局战斗火伤增加30%

function XBuffScript1015724:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015725
    self.magicKind = 1015725
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015724

    