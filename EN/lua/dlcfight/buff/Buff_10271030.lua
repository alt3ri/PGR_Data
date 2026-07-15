local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10271030 : XTheatre6SkillBase
local XBuffScript10271030 = XDlcScriptManager.RegBuffScript(10271030, "XBuffScript10271030", XTheatre6SkillBase)

--效果说明：· 未持有<坚毅>时，获得1层<坚毅>，否则恢复10点【体力值】。

function XBuffScript10271030:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    --self.StackBuff = 1025105 --格挡buffid
    self.stackTL = 10 --恢复的体力值
    self._blockController = self:GetNpc():GetBlockController()
end

function XBuffScript10271030:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if self._proxy:GetBuffStacks(self._npcUUID, self.StackBuff) < 1 then
        --self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,self.StackBuff,1,1,3)
        self._blockController:AddSkillCount(1,self._npcUUID)
    else
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.stackTL, 0) --恢复自己体力
    end
end

return XBuffScript10271030