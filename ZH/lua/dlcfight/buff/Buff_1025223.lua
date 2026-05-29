local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025223 : XTheatre6BuffBase
local XBuffScript1025223 = XDlcScriptManager.RegBuffScript(1025223, "XBuffScript1025223", XTheatre6BuffBase)

--效果说明：自身【常规技能】造成的伤害提升5%，受到对手【常规技能】伤害降低5%。

function XBuffScript1025223:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self.AddDamage = 5                       --增加的增伤buff层数
    self.SubtractDamage = 5                  --增加的减伤buff层数
    self.AddDamageBuffId = 1025906           --增伤buff的id
    self.SubtractDamageBuffId = 1025909      --减伤buff的id
    self.checkType = ETheatre6SkillType.Main --主动/常规技能类型
end

function XBuffScript1025223:OnLuaSkillStart(eventArgs)
    --如果技能不是常规技能，停止
    if eventArgs._skillType ~= self.checkType then return end
    --如果是自己释放，获得增伤Buff，如果是敌人，获得减伤buff
    if eventArgs._launcherUUID == self._npcUUID then
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.AddDamageBuffId, 1, 1, self.AddDamage)
    else
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.SubtractDamageBuffId, 1, 1, self.SubtractDamage)
    end
end

function XBuffScript1025223:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    --如果技能不是常规技能，停止
    if eventArgs._skillType ~= self.checkType then return end
    --如果是自己释放，删除增伤Buff，如果是敌人，删除减伤buff
    if eventArgs._launcherUUID == self._npcUUID then
        self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.AddDamageBuffId, self.AddDamage)
    else
        self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.SubtractDamageBuffId, self.AddDamage)
    end
end

return XBuffScript1025223
