local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")

---@class XBuffScript10274020 : XTheatre6SkillBase
local XBuffScript10274020 = XDlcScriptManager.RegBuffScript(10274020, "XBuffScript10274020", XTheatre6SkillBase)

-- 技能效果：
--· 获得120点【耀斑值】；
--· 每次使用技能时，自身每有1点【超算】属性，获得1点【耀斑值】；
--· 扣除对手40点【体力值】并造成【击飞】。
-- 数值修改：
-- · {被动}每次使用技能时，自身每有180点【超算】属性，获得1点【耀斑值】；
-- · 扣除对手30点【体力值】并造成【击飞】。

function XBuffScript10274020:ScriptInit(isGainControl)
    XTheatre6SkillBase.ScriptInit(self, isGainControl)

    self._sunController = nil
    self._hitFlyController = nil
    self.OverClockPerFlare = 180
    self.LinkedSkillFlareGain = 120
    self.StaminaDrainValue = 30
end

---@param levelId number
function XBuffScript10274020:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)

    self._sunController = self:GetNpc():GetSunController()
    self._hitFlyController = self:GetNpc():GetHitFlyController()
end

function XBuffScript10274020:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then
        return
    end
    self:TriggerPassiveEffect()
    if eventArgs._skillId == self._skillId then
        self:TriggerLinkedSkillEffect()
    end
end

function XBuffScript10274020:TriggerLinkedSkillEffect()
    if self._sunController then
        self._sunController:CastStackBuff(self.LinkedSkillFlareGain, self._npcUUID)
        if self._enemyUUID then
            self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.StaminaDrainValue, 0)
        end
    end
    if self._hitFlyController then
        self._hitFlyController:AddSkillCount(1)
    end
end

function XBuffScript10274020:TriggerPassiveEffect()
    local currentOverClock = self._proxy:GetNpcGameplayAttribValue(self._npcUUID, ETheatre6AttribType.OverClock)
    local flareGain = math.floor(currentOverClock / self.OverClockPerFlare)
    if self._sunController and flareGain > 0 then
        self._sunController:CastStackBuff(flareGain, self._npcUUID)
        --self:LogError(".....看一下耀斑值"..flareGain)
    end

end

return XBuffScript10274020
