local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10271070 : XTheatre6SkillBase
local XBuffScript10271070 = XDlcScriptManager.RegBuffScript(10271070, "XBuffScript10271070", XTheatre6SkillBase)

--效果说明：自身每有1点【攻击】属性，获得2点【护盾】。
--目前仅支持使用能量类属性获得护盾，因此改为如下的处理：先抓取玩家的攻击属性，赋值给自定义能量组1，然后基于自定义能量组1获得护盾。

function XBuffScript10271070:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self.TargetWrestle = 300
    self.StackBuff = 1027107 --给护盾Buff
    self.Protector = self:GetNpc():GetProtectorController()
end

function XBuffScript10271070:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    --if self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.WrestlePoint) > self.TargetWrestle then
    local attack = self._proxy:GetNpcAttribValue(self._npcUUID,ENpcAttrib.Attack)
    local Energy1 = self._proxy:GetNpcAttribMaxValue(self._npcUUID,ENpcAttrib.CustomEnergyGroup1) --刷新一下缓存
    self._proxy:AddNpcAttribAdditive(self._npcUUID, ENpcAttrib.CustomEnergyGroup1, -Energy1, 0) -- 把之前的缓存清空
    self._proxy:AddNpcAttribAdditive(self._npcUUID, ENpcAttrib.CustomEnergyGroup1, attack, 0) -- 令自定义能量1的上限等值于玩家攻击
    self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self.StackBuff)
    --end
end

return XBuffScript10271070