local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281040 : XTheatre6SkillBase
local XBuffScript10281040 = XDlcScriptManager.RegBuffScript(10281040, "XBuffScript10281040", XTheatre6SkillBase)

--效果说明：· 每有4点【魅惑】，获得1点【魅惑】。
--· 造成【击飞】。

function XBuffScript10281040:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self._stackbuff = 1028101
    self._stackCount = 0
    self._stackCountHitFly = 1
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self.ChanceCheck = 0
    self.hypnoPerHypno = 4
end


--self:LogError(".....初始化完成")

function XBuffScript10281040:OnLuaSkillStart(eventArgs)
------------执行------------
if eventArgs._skillId ~= self._skillId then return end
if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._HitFlyController:AddSkillCount(self._stackCountHitFly)
    --self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,1025194) -- 击飞标记，不太确定现在还要不要加，先注释掉
    self.ChanceCheck = 1
    self._stackCount = self._proxy:GetBuffStacks(self._npcUUID,self._stackbuff) // self.hypnoPerHypno
    if self._stackCount >= 1 then
        self._hypnoController:CastStackBuff(self._stackCount,self._npcUUID)
    end
end

--function XBuffScript10281040:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    --if eventArgs._skillId ~= self._skillId then return end
    --if eventArgs._launcherUUID ~= self._npcUUID then return end
    --if self.ChanceCheck == 1 then
        --self._proxy:RemoveBuffByKindAndCount(self._npcUUID,1025194, 1)
        --self.ChanceCheck = 2
    --end
--end

--function XBuffScript10281040:OnLuaSkillEnd(eventArgs)
------------执行------------
--if eventArgs._skillId ~= self._skillId then return end
--if eventArgs._launcherUUID ~= self._npcUUID then return end
--if self.ChanceCheck == 1 then
--self._proxy:RemoveBuffByKindAndCount(self._npcUUID,1025194, 1)
--self.ChanceCheck = 2
--end
--end


return XBuffScript10281040