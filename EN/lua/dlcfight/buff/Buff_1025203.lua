local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025203 : XTheatre6BuffBase
local XBuffScript1025203 = XDlcScriptManager.RegBuffScript(1025203, "XBuffScript1025203", XTheatre6BuffBase)

--效果说明：自身每次触发【反制技能】时，受到伤害降低5%，至多3层。

function XBuffScript1025203:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self.BuffId = 1025204 --受到伤害降低5%BuffId
end

function XBuffScript1025203:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillType ~= ETheatre6SkillType.Dodge then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1,0,1)
end

return XBuffScript1025203
