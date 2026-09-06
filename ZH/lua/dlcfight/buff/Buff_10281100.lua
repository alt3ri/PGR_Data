local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10281100 : XTheatre6SkillBase
local XBuffScript10281100 = XDlcScriptManager.RegBuffScript(10281100, "XBuffScript10281100", XTheatre6SkillBase)

--效果说明：· 获得1层<格挡>；
--· 恢复5点【战意值】。

function XBuffScript10281100:ScriptInit(isGainControl) --初始化
    self.TLRecover = 5
    self._blockController = self:GetNpc():GetBlockController()
    self._stackCount = 1
end

function XBuffScript10281100:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --扣除自己30体力
    self._blockController:AddSkillCount(self._stackCount)

end


return XBuffScript10281100