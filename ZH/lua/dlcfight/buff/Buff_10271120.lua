local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10271120 : XTheatre6SkillBase
local XBuffScript10271120 = XDlcScriptManager.RegBuffScript(10271120, "XBuffScript10271120", XTheatre6SkillBase)

--效果说明：
--· 消耗【体力值】的40%，每消耗1点，额外获得1点【耀斑值】；
--· 每次释放关联技能时，根据本场战斗自身每获得过10点【耀斑值】，自身【体力】属性提升1点。

function XBuffScript10271120:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    self.FlarePerStamina = 1 --额外获得3点
    --self.MaxFlare = 60 --最多获得耀斑，已废弃
    self.StaminaPerFlare = 10 --计算每次获得过10点
    self._totalFlareGained = 0 --总共
    self._lastFlareStacks = 0 --上次
    self._sunBuffId = 1027101 --耀斑值BUFF
    self._sunController = nil --耀斑值控制器
    self._pendingSelfSkillFlare = 0 --当前技能获得的耀斑值
end

function XBuffScript10271120:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)

    self._sunController = self:GetNpc():GetSunController()
    self._lastFlareStacks = self:GetCurrentFlareStacks()
end

function XBuffScript10271120:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScript10271120:GetCurrentFlareStacks()
    return self._proxy:GetBuffStacks(self._npcUUID, self._sunBuffId) or 0
end

function XBuffScript10271120:ApplyStaminaBonusByTotalFlare()
    local staminaBonus = math.floor(self._totalFlareGained / self.StaminaPerFlare)
    if staminaBonus <= 0 then
        return
    end

    self:AddTheatre6Attrib(ETheatre6AttribType.Stamina, staminaBonus, self._npcUUID, self._npcUUID)
end

function XBuffScript10271120:SyncExternalFlareGained()
    local currentFlare = self:GetCurrentFlareStacks()
    local addedFlare = currentFlare - self._lastFlareStacks
    if addedFlare < 0 then
        addedFlare = currentFlare
    end

    if addedFlare > 0 then
        self._totalFlareGained = self._totalFlareGained + addedFlare
    end

    self._lastFlareStacks = currentFlare
end

function XBuffScript10271120:SyncSelfSkillFlareEvent()
    local currentFlare = self:GetCurrentFlareStacks()
    local addedFlare = currentFlare - self._lastFlareStacks
    if addedFlare < 0 then
        addedFlare = currentFlare
    end

    if addedFlare > 0 then
        self._pendingSelfSkillFlare = self._pendingSelfSkillFlare - addedFlare
        if self._pendingSelfSkillFlare < 0 then
            self._pendingSelfSkillFlare = 0
        end
    end

    self._lastFlareStacks = currentFlare

    if self._pendingSelfSkillFlare <= 0 then
        self._pendingSelfSkillFlare = 0
    end
end

function XBuffScript10271120:OnLuaSkillStart(eventArgs)
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end

    -- 当前技能自产耀斑不参与本次结算，只从下次释放开始生效。
    self:ApplyStaminaBonusByTotalFlare()

    local stamina = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.Stamina)
    local staminaCost = math.floor(stamina * 0.4)
    --local currentStamina = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.Stamina)
    --local actualStaminaCost = math.min(staminaCost, math.max(0, currentStamina))
    if staminaCost > 0 then
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -staminaCost, 0)
    end

    local actualGain = staminaCost * self.FlarePerStamina
    --local actualGain = math.min(flareGain, self.MaxFlare)

    if actualGain > 0 then
        self._sunController = self._sunController or self:GetNpc():GetSunController()
        if self._sunController then
            --self._totalFlareGained = self._totalFlareGained + actualGain
            self._pendingSelfSkillFlare = self._pendingSelfSkillFlare + actualGain
            self._sunController:CastStackBuff(actualGain, self._npcUUID)
        end
    end
end

function XBuffScript10271120:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if self._npcUUID ~= npcUUID then return end
    if buffId ~= self._sunBuffId then return end

    if self._pendingSelfSkillFlare > 0 then
        self:SyncSelfSkillFlareEvent()
        return
    end

    self:SyncExternalFlareGained()
end

function XBuffScript10271120:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if self._npcUUID ~= npcUUID then return end
    if buffId ~= self._sunBuffId then return end

    self._lastFlareStacks = self:GetCurrentFlareStacks()
end

function XBuffScript10271120:Terminate()
    self._proxy:UnregisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:UnregisterEvent(EWorldEvent.NpcRemoveBuff)

    XTheatre6SkillBase.Terminate(self)
end

return XBuffScript10271120
