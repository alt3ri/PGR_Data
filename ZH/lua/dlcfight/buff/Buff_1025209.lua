local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript1025209 : XTheatre6SkillBase
local XBuffScript1025209 = XDlcScriptManager.RegBuffScript(1025209, "XBuffScript1025209", XTheatre6SkillBase)


--效果说明：进入战斗时，获得1层<心眼>，在下次使用主动技能时消耗1层<心眼>，并触发【暴击】。

function XBuffScript1025209:Init()
    --初始化
    XTheatre6SkillBase.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self._stackCount = 1
    self._critController = self:GetNpc():GetCritController()
    ------------执行------------
    --self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025104,1,0, 1)
    self._critController:AddSkillCount(self._stackCount)
end

return XBuffScript1025209

--这里没办法保证下一个一定是主动技能    ：能放出来的一定是主动技能吧，还有不是的道理
--继承自肉鸽6技能基类, self._uuid 应该替换为self._npcId     ：已改
--18行是冗余的    ：已改
