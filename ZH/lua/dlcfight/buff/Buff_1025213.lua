local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript1025213 : XTheatre6SkillBase
local XBuffScript1025213 = XDlcScriptManager.RegBuffScript(1025213, "XBuffScript1025213", XTheatre6SkillBase)


--效果说明：拼点成功后，3秒内造成伤害提升15%。

function XBuffScript1025213:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    ------------执行------------
    --self._proxy:ApplyMagic(self._uuid, self._uuid, 1025105,1,0, 3)
    self.BuffId = 1025214 --增伤15%，持续3秒
end

function XBuffScript1025213:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if eventArgs._skillType == Wrestle or eventArgs._skillType == Dodge then
        if eventArgs._launcherUUID ~= self._npcUUID then return end
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1)
    end
end

return XBuffScript1025213