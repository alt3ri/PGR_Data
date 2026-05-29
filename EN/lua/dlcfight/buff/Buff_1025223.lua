local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025223 : XTheatre6BuffBase
local XBuffScript1025223 = XDlcScriptManager.RegBuffScript(1025223, "XBuffScript1025223", XTheatre6BuffBase)

--效果说明：自身【常规技能】造成的伤害提升5%，受到对手【常规技能】伤害降低5%。

function XBuffScript1025223:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    ------------执行------------
    --self._proxy:ApplyMagic(self._uuid, self._uuid, 1025105,1,0, 3)
    self.AddDamage = 5
    self.SubtractDamage = 5
    self.AddDamageBuffId = 1025906
    self.SubtractDamageBuffId = 1025909
end

function XBuffScript1025223:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= Main then return end
    if eventArgs._launcherUUID ~= self._npcUUID then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.AddDamageBuffId, 1,1,self.AddDamage)
    else
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.SubtractDamageBuffId, 1,1,self.SubtractDamage)
    end
end

function XBuffScript1025223:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= Main then return end

    if eventArgs._launcherUUID ~= self._npcUUID then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.AddDamageBuffId, 1,1,self.AddDamage)
    else
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.SubtractDamageBuffId, 1,1,self.SubtractDamage)
    end
end

return XBuffScript1025223