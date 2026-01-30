local Base = require("Buff/Buff_1015700")
---@class XBuffScript1015706 : XBuffScript1015700
local XBuffScript1015706 = XDlcScriptManager.RegBuffScript(1015706, "XBuffScript1015706", Base)


--效果说明：进入战斗时30%的概率触发：本局战斗火伤增加30%

function XBuffScript1015706:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015707
    self.magicKind = 1015707
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015706

    