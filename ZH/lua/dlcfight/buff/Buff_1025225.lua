local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript1025225 : XTheatre6SkillBase
local XBuffScript1025225 = XDlcScriptManager.RegBuffScript(1025225, "XBuffScript1025225", XTheatre6SkillBase)


--效果说明：每次释放【主动技能】时，使自身【体力】属性在本场战斗中提升2点。

function XBuffScript1025225:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    ------------执行------------
    --self._proxy:ApplyMagic(self._uuid, self._uuid, 1025105,1,0, 3)
    self.BuffNum = 2
    self.BuffId = 1025903
end

function XBuffScript1025225:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1,1,self.BuffNum)
end

return XBuffScript1025225