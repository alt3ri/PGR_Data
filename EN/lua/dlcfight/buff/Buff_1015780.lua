local Base = require("Buff/Buff_1015774")

---@class XBuffScript1015780 : XBuffScript1015774
local XBuffScript1015780 = XDlcScriptManager.RegBuffScript(1015780, "XBuffScript1015780", Base)
--效果说明：开局前10秒护盾提升30%
--1015790,开局效果提升+20%
--1015792,开局效果持续时间+5s
--1015794,持有开局效果时，每命中5次，开局类型的宝珠生效事件+1s
function XBuffScript1015780:Init() --初始化
    Base.Init(self)
    ------------配置------------
    self.BuffTimer =  0 --初始计时器
    self.PhaseTimer = 0 --开局阶段计时器
    self.BuffId = 1015781   --护盾+30%的buffid

end

return XBuffScript1015780
