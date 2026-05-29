local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025305 : XTheatre6BuffBase
local XBuffScript1025305 = XDlcScriptManager.RegBuffScript(1025305, "XBuffScript1025305", XTheatre6BuffBase)

--效果说明：每释放3次未【暴击】的技能，获得1层<心眼>。

function XBuffScript1025305:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self.CritNum = 0
    self.UseNum = 0
    self._critController = self:GetNpc():GetCritController()
    self.SkillCount = 0
    self._stackCount = 1
    self.SkillChanceCheck = 0
end

function XBuffScript1025305:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    self.SkillChanceCheck = 0
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.UseNum = self.UseNum + 1 --计算使用技能次数
    self.SkillCount = self.UseNum - self.CritNum --计算使用技能但没暴击的次数
    if self.SkillCount >= 3 then
        self._critController:AddSkillCount(self._stackCount)
        self.CritNum = 0
        self.UseNum = 0
    end
end

function XBuffScript1025305:OnLuaAffixCritDamage(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.SkillChanceCheck == 0 then
        self.CritNum = self.CritNum + 1 --计算暴击次数
        self.SkillChanceCheck = 1       --一个技能仅生效一次
    end
end

return XBuffScript1025305
