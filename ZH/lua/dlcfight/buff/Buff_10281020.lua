local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281020 : XTheatre6SkillBase
local XBuffScript10281020 = XDlcScriptManager.RegBuffScript(10281020, "XBuffScript10281020", XTheatre6SkillBase)

--效果说明：· 消耗10点【战意值】，获得1层<暴击>。

function XBuffScript10281020:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self.StackBuff = 1025105 --格挡buffid
    self.TLCost = 10
    self._critController = self:GetNpc():GetCritController()
    self._stackCount = 1
end


function XBuffScript10281020:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
    if self.originAttrib1 > 0 then
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID,-self.TLCost,0)
        self._critController:AddSkillCount(self._stackCount)
    end
end


return XBuffScript10281020