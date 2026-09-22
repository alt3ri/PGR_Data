local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281070 : XTheatre6SkillBase
local XBuffScript10281070 = XDlcScriptManager.RegBuffScript(10281070, "XBuffScript10281070", XTheatre6SkillBase)

--效果说明：· 对手每有4层【剧毒】，获得1点【魅惑】，至多获得2/3/4点。

function XBuffScript10281070:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self._StackBuffPoisoned = 1028103
    self._stackCount = 0
    self._StackBuffHypno = 1028101
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    self._stackCountMax = {
        --不同等级的默认剧毒层数
        [1] = 2,
        [2] = 3,
        [3] = 4
    }
end

function XBuffScript10281070:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end

--self:LogError(".....初始化完成")

function XBuffScript10281070:OnLuaSkillStart(eventArgs)
------------执行------------
if eventArgs._skillId ~= self._skillId then return end
if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.ChanceCheck = 1
    self._stackCount = self._proxy:GetBuffStacks(self._enemyUUID,self._StackBuffPoisoned) // 4
    if self._stackCount >= 1 then
        if self._stackCount >= self._stackCountMax[self._lv] then self._stackCount = self._stackCountMax[self._lv] end
        self._hypnoController:CastStackBuff(self._stackCount,self._npcUUID)
    end
end

--function XBuffScript10281070:OnLuaSkillEnd(eventArgs)
------------执行------------
--if eventArgs._skillId ~= self._skillId then return end
--if eventArgs._launcherUUID ~= self._npcUUID then return end
--if self.ChanceCheck == 1 then
--self._proxy:RemoveBuffByKindAndCount(self._npcUUID,1025194, 1)
--self.ChanceCheck = 2
--end
--end


return XBuffScript10281070