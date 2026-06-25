local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10272070 : XTheatre6SkillBase
local XBuffScript10272070 = XDlcScriptManager.RegBuffScript(10272070, "XBuffScript10272070", XTheatre6SkillBase)

function XBuffScript10272070:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    self._shieldBuffIds = {
        [1027107] = true,
        [1027109] = true,
    }
    self._shieldBuffGainCount = 0
    self._triggerShieldBuffGainCount = 8
    self._isTriggered = false
    self.skillCount = 0
end

function XBuffScript10272070:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddProtector)
end

---@param levelId number
function XBuffScript10272070:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
end

function XBuffScript10272070:XNpcAddProtectorArgs(LauncherId, TargetId, Value, TotalValue, MagicId)
    if self._isTriggered then return end
    if self._npcUUID ~= self._npcUUID then return end
    if self.skillCount == 0 then --加一个每个技能仅计数一次的判定，不然可能一个技能加了过多的层数直接触发了
        self._shieldBuffGainCount = self._shieldBuffGainCount + 1
        self:CheckTriggerCondition()
        self.skillCount = 1
    end

end


function XBuffScript10272070:CheckTriggerCondition()
    if self._isTriggered then
        return
    end

    if self._shieldBuffGainCount < self._triggerShieldBuffGainCount then
        return
    end

    self._isTriggered = true
    if self._level then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId)
    end
end

---@param eventArgs table
function XBuffScript10272070:OnLuaSkillStart(eventArgs)
    self.skillCount = 0
    if eventArgs._launcherUUID ~= self._npcUUID then
        return
    end

    if eventArgs._skillId ~= self._skillId then
        return
    end

    self:TriggerEffect()
end

function XBuffScript10272070:TriggerEffect()
    self:AddAttrib(ENpcAttrib.Attack, 10, self._npcUUID, self._npcUUID)
    self:AddTheatre6Attrib(ETheatre6AttribType.OverClock, 3, self._npcUUID, self._npcUUID)
end

function XBuffScript10272070:HandleEvent(eventType, eventArgs)
    XTheatre6SkillBase.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript10272070:Terminate()
    self._proxy:UnregisterEvent(EWorldEvent.NpcAddBuff)
    XTheatre6SkillBase.Terminate(self)
end

return XBuffScript10272070
