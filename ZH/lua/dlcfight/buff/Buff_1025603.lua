local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025603 : XTheatre6BuffBase
local XBuffScript1025603 = XDlcScriptManager.RegBuffScript(1025603, "XBuffScript1025603", XTheatre6BuffBase)

--效果说明：每释放4次【暴击】的技能，获得1层<暴击>。

function XBuffScript1025603:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self.CritNum = 0
    self._critController = self:GetNpc():GetCritController()
    self._stackCount = 1
    self.SkillChanceCheck = 0
end

function XBuffScript1025603:OnLuaSkillStart(eventArgs)
    ------------执行------------
    self.SkillChanceCheck = 0
end

function XBuffScript1025603:OnLuaAffixCritDamage(eventArgs)
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self.SkillChanceCheck == 0 then
        self.CritNum = self.CritNum + 1 --计算暴击次数
        self.SkillChanceCheck = 1       --一个技能仅生效一次
    end
    if self.CritNum >= 4 then
        self._critController:AddSkillCount(self._stackCount)
        self.CritNum = 0
    end
end

return XBuffScript1025603
