local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10252150 : XTheatre6SkillBase
local XBuffScript10252150 = XDlcScriptManager.RegBuffScript(10252150, "XBuffScript10252150", XTheatre6SkillBase)

--效果说明：累计造成3次【暴击】技能时触发：
--· 造成【击飞】。

function XBuffScript10252150:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._stackCountCrit = 3
    self._stackCount = 1
    self.Count = 0
    --self._proxy:ApplyMagic(self._uuid, self._uuid, 1025105,1,0, 3)
    self._critController = self:GetNpc():GetCritController()
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self.CSCost = 10
    self.SkillChanceCheck = 0
end


function XBuffScript10252150:OnLuaAffixCritDamage(eventArgs)
    --self:LogError(".....抓到暴击")
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.SkillChanceCheck == 0 then
        self.Count = self.Count + 1
        -- self:LogError(".....抓到我方暴击，暴击方为"..self._npcUUID)
        self.SkillChanceCheck = 1
        --我槽这通知居然是一段伤害通知一次，这么变态
        --加个检测限制下每次技能跟至多触发一次暴击通知
    end
    if self.Count == self._stackCountCrit then
        self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
        --self:LogError(".....暴击插入技已塞入队列"..self._npcUUID)
        self.Count = 0
    end
end

function XBuffScript10252150:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.SkillChanceCheck = 0
    if eventArgs._skillId ~= self.TargetSkill then return end
    --这个地方是根据技能的magicid抓技能id，多个同magicid技能会读串
    self._HitFlyController:AddSkillCount(self._stackCount)
    self.TargetCS = self._proxy:Theatre6GetNpcRuntimeOverClock(self._enemyUUID)
    if self.TargetCS <= self.CSCost then self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID,self.TargetCS)
    else self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID,self.CSCost)
    end
    --技能开始时给技能塞一个击飞计数器，可以在关键帧触发击飞
end

return XBuffScript10252150
