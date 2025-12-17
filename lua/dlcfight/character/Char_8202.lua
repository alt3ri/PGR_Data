---@type XAFKCharBase
local Base = require("Character/FightCharBase/XAFKCharBase")

---自走棋-意识聚合宿体
---@class XCharTes8202 : XAFKCharBase
local XCharTes8202 = XDlcScriptManager.RegCharScript(8202, "XCharTes8202", Base)

function XCharTes8202:Init()
    --初始化
    Base.Init(self)

    --距离要求，没有在列表内说明没有距离要求，在筛选到技能释放时
    self.skillCastDistanceDic = {  --配置技能的释放距离，没有在字典内配置距离的技能表示没有释放距离
        [8202001] = 2,
        [8202002] = 2,
    }

    --默认普攻技能释放列表，这个基类里找
    self.normalAttackList = {
        8202001,
        8202002,
    }
end

return XCharTes8202
