local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262010 : XTheatre6SkillBase
local XBuffScript10262010 = XDlcScriptManager.RegBuffScript(10262010, "XBuffScript10262010", XTheatre6SkillBase)

--效果说明：每累计造成2次【击倒】后触发：
--· 造成50%攻击伤害；
--· 若对手在本场战斗中没有出手过，造成【击倒】；
--· 自身每有1点【拼刀】属性，降低对手1点【超算值】。

function XBuffScript10262010:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self._Count = 0
    self.ChanceCheck = 0
    self._stackCountHitDown = 0
end

function XBuffScript10262010:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._HitDownController = self:GetEnemyNpc():GetHitDownController()
end


function XBuffScript10262010:OnLuaAffixHitDown(eventArgs )
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._Count = self._Count + 1
    if self._Count == 2 then
    self._level:RequestInsertSkill(self._uuid,self.TargetSkill)
    self._Count = 0
    --self:LogError("目标插入式技能1注册完成")
    end
end

function XBuffScript10262010:OnLuaAttackerChange(eventArgs)
    ---出手权交换时重置计数
    if eventArgs._newAttackerUUID == self._npcUUID then
    self.ChanceCheck = 1
    end
end

function XBuffScript10262010:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.ChanceCheck == 0 then --如果本次技能结束时击飞标记为开
        self._HitDownController:AddSkillCount(self._stackCountHitDown)
        return
    end
    self.CSCost = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint)
    self.TargetCS = self._proxy:Theatre6GetNpcRuntimeOverClock(self._enemyUUID)
    self._HitDownController:AddSkillCount(self._stackCountHitDown)
    if self.TargetCS <= self.CSCost then self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID,self.TargetCS)
    else self._proxy:Theatre6CastNpcRuntimeOverClock(self._enemyUUID,self.CSCost)
        self._blockController:AddSkillCount(self._stackCount)
    end
end

return XBuffScript10262010

--无法获取到击飞事件