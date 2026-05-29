local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025215 : XTheatre6BuffBase
local XBuffScript1025215 = XDlcScriptManager.RegBuffScript(1025215, "XBuffScript1025215", XTheatre6BuffBase)


--效果说明：使用【插入式技能】后，返还8点【体力值】。

function XBuffScript1025215:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    ------------执行------------
    --self._proxy:ApplyMagic(self._uuid, self._uuid, 1025105,1,0, 3)
    self.TLRecover = 8
end

function XBuffScript1025215:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= Insert then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复8点体力
end

return XBuffScript1025215