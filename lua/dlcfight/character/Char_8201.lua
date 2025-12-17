---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋-感染构造体
---@class XCharTes8201 : XAFKCharBase
local XCharTes8201 = XDlcScriptManager.RegCharScript(8201, "XCharTes8201", Base)

function XCharTes8201:Init()
    --初始化
    Base.Init(self)

    --距离要求，没有在列表内说明没有距离要求，在筛选到技能释放时
    self.skillCastDistanceDic = {  --配置技能的释放距离，没有在字典内配置距离的技能表示没有释放距离
        [8201001] = 1,
        [8201003] = 2,
    }

    --默认普攻技能释放列表，这个基类里找
    self.normalAttackList = {
        8201001,
        8201003,
    }
end

return XCharTes8201
