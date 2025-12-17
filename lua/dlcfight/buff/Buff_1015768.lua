local Base = require("Buff/Buff_1015766")

---@class XBuffScript1015768 : XBuffScript1015766
local XBuffScript1015768 = XDlcScriptManager.RegBuffScript(1015768, "XBuffScript1015768", Base)
--效果说明：开局前10秒冰伤提升30%
--1015790,开局效果提升+20%
--1015792,开局效果持续时间+5s
--1015794,持有开局效果时，每命中5次，开局类型的宝珠生效事件+1s
function XBuffScript1015768:Init() --初始化
    Base.Init(self)
    ------------配置------------
    self.BuffTimer =  0 --初始计时器
    self.PhaseTimer = 0 --开局阶段计时器
    self.BuffId = 1015769   --冰伤+30%的buffid

end

return XBuffScript1015768
