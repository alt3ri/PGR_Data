local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10261100 : XTheatre6SkillBase
local XBuffScript10261100 = XDlcScriptManager.RegBuffScript(10261100, "XBuffScript10261100", XTheatre6SkillBase)

--效果说明：
--自身的【体力】属性>150点时，额外消耗20点【体力值】，并获得2层<坚毅> 。

function XBuffScript10261100:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --目标体力值
    self.TargetTL = 150
    --坚毅层数
    self._stackCount = 2
    --额外扣除体力值
    self.TLCost = 20
    --获取坚毅控制器
    self._blockController = self:GetNpc():GetBlockController()
    
    ------------执行------------
end

function XBuffScript10261100:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    -- 抓到体力属性
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._uuid,ETheatre6AttribType.Stamina)
    --如果体力属性要求达到了
    if self.originAttrib1 > self.TargetTL then
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, -self.TLCost, 0)
        self._blockController:AddSkillCount(self._stackCount)
    end
end

return XBuffScript10261100
