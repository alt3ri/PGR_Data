---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋-巴拉德
---@class XCharTes8204 : XAFKCharBase
local XCharTes8204 = XDlcScriptManager.RegCharScript(8204, "XCharTes8204", Base)

function XCharTes8204:Init()
    --初始化
    Base.Init(self)

    self.moveSkillId = 8204005    --使用技能位移，使用这行代码并配置id就会自动执行用该技能替代run来移动

end

return XCharTes8204
