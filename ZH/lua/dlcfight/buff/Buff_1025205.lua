local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript1025205 : XTheatre6SkillBase
local XBuffScript1025205 = XDlcScriptManager.RegBuffScript(1025205, "XBuffScript1025205", XTheatre6SkillBase)

--效果说明：自身每拥有40点【体力】属性，使用所有技能后返还1点【体力值】，至多5点。

function XBuffScript1025205:Init()
    --初始化
    XTheatre6SkillBase.Init(self)
    ------------配置------------
    --self._blockController = self:GetNpc():GetBlockController()
    ------------执行------------
    self.originAttrib1 = 0
    self.originAttrib2 = 0
end

function XBuffScript1025205:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.originAttrib1 = self._proxy:GetNpcGameplayAttribValue(self._npcUUID,ETheatre6AttribType.Stamina)
    self.originAttrib2 = self.originAttrib1 // 40
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.originAttrib2, 0) --恢复X点体力
end

return XBuffScript1025205