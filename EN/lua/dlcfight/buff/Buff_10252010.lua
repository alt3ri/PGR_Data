local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10252010 : XTheatre6SkillBase
local XBuffScript10252010 = XDlcScriptManager.RegBuffScript(10252010, "XBuffScript10252010", XTheatre6SkillBase)

--效果说明：触发击飞时，请求释放插入技

function XBuffScript10252010:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.ChanceCheck = 0
    self._stackCountBurn = 1
end

function XBuffScript10252010:OnLuaAffixHitFly(eventArgs )
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck == 1 then
        self._level:RequestInsertSkill(self._uuid,self.TargetSkill)
        self:LogError("2010抓到了击飞效果"..eventArgs._skillId)
        self.ChanceCheck = 0
    end
end

function XBuffScript10252010:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.ChanceCheck = 1
    if eventArgs._skillId ~= self._skillId then return end
    self:GetEnemyNpc():GetBurnController():CastStackBuff(self._stackCountBurn, self._enemyUUID)
end

return XBuffScript10252010

--无法获取到击飞事件