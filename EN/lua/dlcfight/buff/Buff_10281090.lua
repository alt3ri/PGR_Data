local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281090 : XTheatre6SkillBase
local XBuffScript10281090 = XDlcScriptManager.RegBuffScript(10281090, "XBuffScript10281090", XTheatre6SkillBase)

--效果说明：· 扣除双方30点【体力值】，如果此技能是因【失心】触发的，不扣除自身【战意值】；
--· 获得2层<暴击>。

function XBuffScript10281090:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self.StackBuff = 1025105 --格挡buffid
    self.TLCost = 30
    self._critController = self:GetNpc():GetCritController()
    self._StackBuffLostHeart = 1028102
    self._stackCount = 0
    self._critCount = 2
end

function XBuffScript10281090:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._stackCount = self._proxy:GetBuffCountByKind(self._npcUUID,self._StackBuffLostHeart)
    if self._stackCount == 0 then -- 检测是不是失心触发的，不是就继续往下走扣自己体力
        self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
        if self.originAttrib1 > 0 then
            self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -self.TLCost, 0) --扣除自己30体力
        end
    end
    self.originAttrib2 = self._proxy:GetNpcGameplayAttribValue(self._enemyUUID,ETheatre6AttribType.Stamina)
    if self.originAttrib2 > 0 then
        self._proxy:Theatre6ChangeStaminaValue(self._enemyUUID, -self.TLCost, 0) --扣除对面30体力
    end
end

function XBuffScript10281090:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._critController:AddSkillCount(self._critCount)
end


return XBuffScript10281090