local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10263020 : XTheatre6SkillBase
local XBuffScript10263020 = XDlcScriptManager.RegBuffScript(10263020, "XBuffScript10263020", XTheatre6SkillBase)

--效果说明：
--拼刀成功后触发：
--· 首次出手期间，每次【击倒】对手均将恢复自身10点【体力值】；
--· 造成5秒【晕眩】与【击倒】。

function XBuffScript10263020:ScriptInit(isGainControl) --初始化
    --self.TargetSkill = self._skillId
    self.TLRecover = 10
    self._stackCount = 1
    --self:LogError(".....初始化完成")
    self._HitDownController = self:GetNpc():GetHitDownController()
    self.ChanceCheck = 0
    self.isSkillJustStart = 0
    self.isSelfStart = 0  --本技能释放成功
    self.delayTime = 0.1 --出手权判定延迟
    self.timer = 0       --出手权判定计时
end

function XBuffScript10263020:OnLuaSkillStart(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.isSkillJustStart = 1 --击倒效果可受理开关
    --如果是本技能，额外触发击倒和晕眩
    if eventArgs._skillId ~= self._skillId then return end
    self._HitDownController:AddSkillCount(self._stackCount)
    self._proxy:Theatre6AddNpcStun(self._enemyUUID, 5)
    self.isSelfStart = 1
end

function XBuffScript10263020:OnLuaSkillEnd(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.isSkillJustStart = 0
end

function XBuffScript10263020:OnLuaAffixHitDown(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.isSelfStart == 0 then return end
    if self.ChanceCheck <= 1 and self.isSkillJustStart ~= 0 then
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复10体力
        self.isSkillJustStart = 0 -- 一次技能造成多次击倒，只会触发1次恢复效果
    end
end

function XBuffScript10263020:OnLuaAttackerChange(eventArgs)
    ------------执行------------
    if self.ChanceCheck >= 2 then return end
    if self.timer > self._proxy:GetNpcTime(self._npcUUID) then return end
    if eventArgs._newAttackerUUID ~= self._npcUUID then return end
    self.ChanceCheck = self.ChanceCheck + 1
    self.timer = self._proxy:GetNpcTime(self._npcUUID) + self.delayTime
end

return XBuffScript10263020
