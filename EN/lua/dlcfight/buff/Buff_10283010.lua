local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10283010 : XTheatre6SkillBase
local XBuffScript10283010 = XDlcScriptManager.RegBuffScript(10283010, "XBuffScript10283010", XTheatre6SkillBase)

--效果说明：· 获得6点【魅惑】。
--· {被动}每有200点【先机】属性，造成【失心】所需的【魅惑】降低1点，至多降低4点。这一块写在控制器里了。
--· 造成【击飞】。

function XBuffScript10283010:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self._stackbuff = 1028101
    self._stackCount = 6
    self._stackCountHitFly = 1
    self._HitFlyController = self:GetNpc():GetHitFlyController()
end


--self:LogError(".....初始化完成")

function XBuffScript10283010:OnLuaSkillStart(eventArgs)
------------执行------------
if eventArgs._skillId ~= self._skillId then return end
if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._HitFlyController:AddSkillCount(self._stackCountHitFly)
    self._hypnoController:CastStackBuff(self._stackCount,self._npcUUID)
    self._proxy:Theatre6AddNpcStun(self._enemyUUID, 5)
end


--function XBuffScript10283010:OnLuaSkillEnd(eventArgs)
------------执行------------
--if eventArgs._skillId ~= self._skillId then return end
--if eventArgs._launcherUUID ~= self._npcUUID then return end
--if self.ChanceCheck == 1 then
--self._proxy:RemoveBuffByKindAndCount(self._npcUUID,1025194, 1)
--self.ChanceCheck = 2
--end
--end


return XBuffScript10283010