local Base = require("Buff/Buff_1015758")

---@class XBuffScript1015762 : XBuffScript1015758
local XBuffScript1015762 = XDlcScriptManager.RegBuffScript(1015762, "XBuffScript1015762", Base)
--效果说明：开局前10秒雷伤提升30%
--1015790,开局效果提升+20%
--1015792,开局效果持续时间+5s
--1015794,持有开局效果时，每命中5次，开局类型的宝珠生效事件+1s
function XBuffScript1015762:Init() --初始化
    Base.Init(self)
    ------------配置------------
    self.BuffTimer =  0 --初始计时器
    self.PhaseTimer = 0 --开局阶段计时器
    self.BuffId = 1015763   --雷伤+30%的buffid

end

return XBuffScript1015762
