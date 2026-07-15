local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10271020 : XTheatre6SkillBase
local XBuffScript10271020 = XDlcScriptManager.RegBuffScript(10271020, "XBuffScript10271020", XTheatre6SkillBase)

-- Effect:
-- 本场战斗中，每次释放技能时检测，本场战斗每获得过30点【耀斑值】，此技能伤害倍率提升7.5%，至多提升150%。
function XBuffScript10271020:ScriptInit(isGainControl)
    self.FlarePerOverClock = 30
    self.MaxOverClockRecover = 20
    self._totalFlareGained = 0
    self._lastFlareStacks = 0
    self._sunBuffId = 1027101
    self.isDmgChanged = false
    self._damageMagicId = 10270001
    self.extraPermyriadPerSun = 750
    self.extraPermyriadMax = 15000
    isGainControl = isGainControl or false
end

function XBuffScript10271020:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._lastFlareStacks = self:GetCurrentFlareStacks()
    self._sunController = self:GetNpc():GetSunController()
end

function XBuffScript10271020:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._npcUUID)
end

function XBuffScript10271020:GetCurrentFlareStacks()
    return self._proxy:GetBuffStacks(self._npcUUID, self._sunBuffId) or 0
end

function XBuffScript10271020:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if self._npcUUID ~= npcUUID then return end
    if buffId ~= self._sunBuffId then return end

    local currentFlareStacks = self:GetCurrentFlareStacks()
    local addedFlare = currentFlareStacks - self._lastFlareStacks

    if addedFlare < 0 then
        -- 耀斑爆发会清空层数，但本场战斗的耀斑总获取量应保持累积。
        addedFlare = currentFlareStacks
    end

    if addedFlare <= 0 then
        self._lastFlareStacks = currentFlareStacks
        return
    end

    self._totalFlareGained = self._totalFlareGained + addedFlare
    self:LogError("[Buff_10271020] 耀斑变化 当前:" .. currentFlareStacks
            .. " 新增:" .. addedFlare
            .. " 总获取:" .. self._totalFlareGained)

    self._lastFlareStacks = currentFlareStacks
end


function XBuffScript10271020:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self.isDmgChanged = false
end

function XBuffScript10271020:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if self._npcUUID ~= npcUUID then return end
    if buffId ~= self._sunBuffId then return end
    -- 仅同步当前层数用于下次增量计算。不要重置本场战斗的耀斑总获取量。
    self._lastFlareStacks = self:GetCurrentFlareStacks()
end


function XBuffScript10271020:BeforeDamageCalc(eventArgs)
    if eventArgs.Launcher ~= self._npcUUID then return end
    if eventArgs.Id ~= self._damageMagicId then return end
    if self.isDmgChanged then return end
    if self._totalFlareGained > 0 then
        self.extraPermyriad = math.min( (self._totalFlareGained // self.FlarePerOverClock ) * self.extraPermyriadPerSun,self.extraPermyriadMax)
        local finalPermyriad = self.extraPermyriad + eventArgs.PhysicalPermyriad
        self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, finalPermyriad, eventArgs.ElementPermyriad, eventArgs.HackDamage,eventArgs.HackPermyriad,eventArgs.IsCrit)
        self.isDmgChanged = true
    end
end

function XBuffScript10271020:Terminate()
    self._proxy:UnregisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:UnregisterEvent(EWorldEvent.NpcRemoveBuff)

    XTheatre6SkillBase.Terminate(self)
end

return XBuffScript10271020
