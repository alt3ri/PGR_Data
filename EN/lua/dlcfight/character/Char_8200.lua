---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋-类人、意识聚合宿体、仿生斗牛、机械异种、圣堂守卫 通用脚本
---@class XCharTes8200 : XAFKCharBase
local XCharTes8200 = XDlcScriptManager.RegCharScript(8200, "XCharTes8200", Base)


function XCharTes8200:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    --按需求解除注释进行注册
end


return XCharTes8200