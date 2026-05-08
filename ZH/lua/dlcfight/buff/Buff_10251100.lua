local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10251100 : XTheatre6SkillBase
local XBuffScript10251100 = XDlcScriptManager.RegBuffScript(10251100, "XBuffScript10251100", XTheatre6SkillBase)

--效果说明：
--· 获得10点【超算值】；
--· 【攻击】属性在本场战斗中提升15、25、35点。

function XBuffScript10251100:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.CSRecover = 10
    --self:LogError(".....初始化完成")
    self._stackCount = 1
    --self._critController = self:GetNpc():GetCritController()
    --self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -30, 0)
    if self._skillId == 10251101 then self._stackCountAtk = 15
    else if self._skillId == 10251102 then self._stackCountAtk = 25
    else self._stackCountAtk = 35
    end
    end
end

function XBuffScript10251100:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --self.TargetCS = self._proxy:Theatre6GetNpcRuntimeOverClock(self._enemyUUID)
    --self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025904,1,0,2)
        --self:LogError(".....扣了敌人超算？"..self._enemyUUID)
    self._proxy:Theatre6AddNpcRuntimeOverClock(self._npcUUID,self.CSRecover)
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, 1025904,1,0,self._stackCountAtk)
end

return XBuffScript10251100
