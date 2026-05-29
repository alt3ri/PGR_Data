local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10252050 : XTheatre6SkillBase
local XBuffScript10252050 = XDlcScriptManager.RegBuffScript(10252050, "XBuffScript10252050", XTheatre6SkillBase)

--效果说明：释放【超算成功技能】后触发：
--· 获得1/2/3层<心眼>。

function XBuffScript10252050:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.ChanceCheck = 0
    if self._skillId == 10252051 then self._stackCountCrit = 1
    else if self._skillId == 10252052 then self._stackCountCrit = 2
    else self._stackCountCrit = 3
    end
    end
    self._critController = self:GetNpc():GetCritController()
end

function XBuffScript10252050:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId == self._skillId and eventArgs._launcherUUID == self._npcUUID then --如果是玩家方的当前技能则接下来获得暴击次数，放在skillstart会导致这一次直接暴击
        self._critController:AddSkillCount(self._stackCountCrit)
    end
    if eventArgs._skillType ~= ETheatre6SkillType.Dodge then return end
    self._level:RequestInsertSkill(self._npcUUID,self.TargetSkill)
    --self:LogError(".....超算技能释放完毕"..self._skillId)
end

return XBuffScript10252050

--19行的3最好写成ETheatre6SkillType.Dodge,已改
--19行skillType应该为_skillType, 已改. 需要检查一下为啥会出现这种错误
--27行的_critController没有初始化