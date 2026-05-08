local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript1025211 : XTheatre6SkillBase
local XBuffScript1025211 = XDlcScriptManager.RegBuffScript(1025211, "XBuffScript1025211", XTheatre6SkillBase)


--效果说明：进入战斗时，获得3层<坚毅>，在下次受到技能伤害时消耗1层<坚毅>，并触发【格挡】。

function XBuffScript1025211:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    --self.magicId = 1015335
    --self.magicKind = 1015335
    --self.attrib = ENpcAttrib.HealAmpP
    self._stackCount = 3
    self._blockController = self:GetNpc():GetBlockController()
    ------------执行------------
    --self._proxy:ApplyMagic(self._uuid, self._uuid, 1025105,1,0, 3)
    self._blockController:AddSkillCount(self._stackCount)
end

return XBuffScript1025211

    