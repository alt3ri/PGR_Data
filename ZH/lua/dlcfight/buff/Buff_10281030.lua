local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281030 : XTheatre6SkillBase
local XBuffScript10281030 = XDlcScriptManager.RegBuffScript(10281030, "XBuffScript10281030", XTheatre6SkillBase)

--效果说明：· 获得1点【魅惑】。
--· 此次技能若是【暴击】，获得1点【魅惑】。

function XBuffScript10281030:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self._stackbuff = 1025104
    self._critController = self:GetNpc():GetCritController()
    self._stackCountExtra = 1
    self._stackCount = {
        --不同等级的默认剧毒层数
        [1] = 1,
        [2] = 1,
        [3] = 2
    }
end

--self:LogError(".....初始化完成")

function XBuffScript10281030:OnLuaSkillStart(eventArgs)
------------执行------------
if eventArgs._skillId ~= self._skillId then return end
if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._hypnoController:CastStackBuff(self._stackCount[self._lv],self._npcUUID)
    if self._proxy:CheckBuffByKind(self._npcUUID,self._stackbuff) then --检测身上是否有暴击buff，有则视为此技能触发了暴击。
        self._hypnoController:CastStackBuff(self._stackCountExtra,self._npcUUID)
    end
end

--function XBuffScript10281030:OnLuaSkillEnd(eventArgs)
------------执行------------
--if eventArgs._skillId ~= self._skillId then return end
--if eventArgs._launcherUUID ~= self._npcUUID then return end
--if self.ChanceCheck == 1 then
--self._proxy:RemoveBuffByKindAndCount(self._npcUUID,1025194, 1)
--self.ChanceCheck = 2
--end
--end


return XBuffScript10281030