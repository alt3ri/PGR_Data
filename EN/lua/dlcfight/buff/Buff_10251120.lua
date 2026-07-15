local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251120 : XTheatre6SkillBase
local XBuffScript10251120 = XDlcScriptManager.RegBuffScript(10251120, "XBuffScript10251120", XTheatre6SkillBase)

--效果说明：
--· 恢复自身10点【体力值】。
--· 此次技能若是【暴击】，额外造成【击飞】。

function XBuffScript10251120:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.TLRecover = 10
    --self:LogError(".....初始化完成")
    self._stackbuff = 1025104
    self._critController = self:GetNpc():GetCritController()
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    --self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -30, 0)
    self._stackCount = 1
    self.ChanceCheck = 0
end

function XBuffScript10251120:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复10体力
    --self:LogError(".....技能specialhit？")
    if self._proxy:CheckBuffByKind(self._npcUUID,self._stackbuff) then
        self._HitFlyController:AddSkillCount(self._stackCount)
        --self:LogError("1120触发了击飞附魔")
        self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,1025194)
        self.ChanceCheck = 1
    end
end

function XBuffScript10251120:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck == 1 then
        self._proxy:RemoveBuffByKindAndCount(self._npcUUID,1025194, 1)
        self.ChanceCheck = 2
    end
end

return XBuffScript10251120

--没有对释放的技能进行过滤. 所有技能都会触发此词条    已修，技能重做了