local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10271050 : XTheatre6SkillBase
local XBuffScript10271050 = XDlcScriptManager.RegBuffScript(10271050, "XBuffScript10271050", XTheatre6SkillBase)

--效果说明：· 拥有【护盾】时，获得1层<坚毅>。
--· 获得10点【耀斑值】。

function XBuffScript10271050:ScriptInit(isGainControl) --初始化
    self.StackBuff = 1025106 --格挡buffid
    self.ChanceCheck = 0
    self.StackBuffCountNormal = 1
    self.SunRecover = 10 --耀斑值恢复量
    self._sunController = self:GetNpc():GetSunController()
    self._blockController = self:GetNpc():GetBlockController()
end

function XBuffScript10271050:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._proxy:GetNpcProtector(self._npcUUID) > 1 then
        self._blockController:AddSkillCount(self.StackBuffCountNormal,self._npcUUID)
    end
    self._sunController:CastStackBuff(self.SunRecover, self._npcUUID)
end

return XBuffScript10271050