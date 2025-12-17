local Base = require("Buff/Buff_1015782")

---@class XBuffScript1015784 : XBuffScript1015782
local XBuffScript1015784 = XDlcScriptManager.RegBuffScript(1015784, "XBuffScript1015784", Base)
--效果说明：开局前10秒回复提升30%
--1015790,开局效果提升+20%
--1015792,开局效果持续时间+5s
--1015794,持有开局效果时，每命中5次，开局类型的宝珠生效事件+1s
function XBuffScript1015784:Init() --初始化
    Base.Init(self)
    ------------配置------------
    self.BuffTimer =  0 --初始计时器
    self.PhaseTimer = 0 --开局阶段计时器
    self.BuffId = 1015785   --回复+30%的buffid

end

return XBuffScript1015784
