local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

-- 本场战斗中我方首次使用任意技能后触发：
--  · 造成50%攻击伤害；
--  · 自身每有20/10/5点【体力】属性，使自身【超算】属性或【拼刀】属性中较高的一项在本场战斗中增加1点。
---@class XBuffScript.10262130 : XTheatre6SkillBase
local XBuff10262130 = XDlcScriptManager.RegBuffScript(10262130, "XBuffScript10262130", XTheatre6SkillBase)

function XBuff10262130:ScriptInit(isGainControl) --初始化
    self.addAttr = 1                             --增加属性值
    self.trigger = true                          --是否可触发
    self.dictStaminaTarget = {
        --坚毅层数
        [1] = 20,
        [2] = 10,
        [3] = 5
    }
end

function XBuff10262130:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --如果是【拼刀成功技】，则触发本技能
    self._level:RequestInsertSkill(self._npcUUID, self._skillId)
    self.trigger = false
end

function XBuff10262130:OnLuaSkillStart(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.trigger == false then return end
    --增加属性值
    local stamina = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
    local addAttrValue = math.floor(stamina / self.dictStaminaTarget[self._level]) * self.addAttr
     --增加哪一个属性
    local overClock = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.OverClock)
    local wrestlePoint = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint)
    if overClock >= wrestlePoint then
        self:AddTheatre6Attrib(ETheatre6AttribType.OverClock, addAttrValue, self._npcUUID, self._npcUUID)
    else
        self:AddTheatre6Attrib(ETheatre6AttribType.WrestlePoint, addAttrValue, self._npcUUID, self._npcUUID)
    end
end

return XBuff10262130
