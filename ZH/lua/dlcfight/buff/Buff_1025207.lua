local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript1025207 : XTheatre6SkillBase
local XBuffScript1025207 = XDlcScriptManager.RegBuffScript(1025207, "XBuffScript1025207", XTheatre6SkillBase)

--效果说明：自身首次出手前，受到的攻击伤害降低20%，自身首次获得出手权期间，造成的攻击伤害提升20%。

function XBuffScript1025207:Init()
    --初始化
    XTheatre6SkillBase.Init(self)
    ------------配置------------
    --self._blockController = self:GetNpc():GetBlockController()
    ------------执行------------
    self.originAttrib1 = 0
    self.originAttrib2 = 0
    self.Count = 0
    self.AddDamage = 20
    self.SubtractDamage = 20
    self.Chance = 0
    self.AddDamageBuffId = 1025906
    self.SubtractDamageBuffId = 1025909
end

function XBuffScript1025207:OnLuaAttackerChange(eventArgs)
    ------------执行------------
    self.Count = self.Count + 1
    if self.Chance == 0 then
        if self.Count <= 2 then
            self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.AddDamageBuffId, 1,1,self.AddDamage)
            self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.SubtractDamageBuffId, 1,1,self.SubtractDamage)
            self.Chance = 1
        end
    end
    if self.Chance == 1 then
        if self.Count > 2 then
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.AddDamageBuffId, self.AddDamage)
            self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.SubtractDamageBuffId, self.SubtractDamage)
            self.Chance = 2
        end
    end
end

return XBuffScript1025207