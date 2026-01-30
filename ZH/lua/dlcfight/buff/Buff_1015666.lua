local Base = require("Buff/Buff_1015650")
---@class XBuffScript1015666 : XBuffScript1015650
local XBuffScript1015666 = XDlcScriptManager.RegBuffScript(1015666, "XBuffScript1015666", Base)


--效果说明：疲劳阶段，冰伤增加10%

function XBuffScript1015666:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015667
    self.magicKind = 1015667
    self.magicLevel = 1
    ------------执行------------
end

return XBuffScript1015666

    