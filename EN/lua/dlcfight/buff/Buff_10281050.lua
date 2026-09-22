local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281050 : XTheatre6SkillBase
local XBuffScript10281050 = XDlcScriptManager.RegBuffScript(10281050, "XBuffScript10281050", XTheatre6SkillBase)

--效果说明：· 获得1点【魅惑】；
--· 【攻击】属性提升20点。

function XBuffScript10281050:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self._stackbuff = 1028101
    self._stackCount = {
        --不同等级的默认剧毒层数
        [1] = 1,
        [2] = 1,
        [3] = 2
    }
    self._HitFlyController = self:GetNpc():GetHitFlyController()
    self.ChanceCheck = 0
    self._stackCountAtk = 20
end


--self:LogError(".....初始化完成")

function XBuffScript10281050:OnLuaSkillStart(eventArgs)
------------执行------------
if eventArgs._skillId ~= self._skillId then return end
if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._hypnoController:CastStackBuff(self._stackCount[self._lv],self._npcUUID)
    self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,1025904,1,1,self._stackCountAtk)
end


return XBuffScript10281050