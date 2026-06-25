local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025501 : XTheatre6BuffBase
local XBuffScript1025501 = XDlcScriptManager.RegBuffScript(1025501, "XBuffScript1025501", XTheatre6BuffBase)

--效果说明：自身每次【体力值】归零时，获得1层<坚毅>。一场战斗至多触发3次。

function XBuffScript1025501:Init()
    --初始化
    ------------配置------------
    XTheatre6BuffBase.Init(self)
    self.ChanceCheck = 0
    self._stackCount = 1
    self.MaxChanceCheck = 3
    ------------执行------------
end

function XBuffScript1025501:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
    if self.originAttrib1 <= 0 then
        if self.ChanceCheck < self.MaxChanceCheck then
            self._blockController = self:GetNpc():GetBlockController()
            self._blockController:AddSkillCount(self._stackCount)
            self.ChanceCheck = self.ChanceCheck + 1
        end
    end
end

return XBuffScript1025501
