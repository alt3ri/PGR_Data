local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025213 : XTheatre6BuffBase
local XBuffScript1025213 = XDlcScriptManager.RegBuffScript(1025213, "XBuffScript1025213", XTheatre6BuffBase)


--效果说明：使用【拼刀技能】或【超算技能】后，3秒内造成伤害提升15%。

function XBuffScript1025213:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    ------------执行------------
    --self._proxy:ApplyMagic(self._uuid, self._uuid, 1025105,1,0, 3)
    self.BuffId = 1025214 --增伤15%，持续3秒
end

function XBuffScript1025213:OnLuaSkillEnd(eventArgs) --这里逻辑有点问题，实际逻辑是触发拼刀/超算技能时给加伤
    ------------执行------------
    if eventArgs._skillType == ETheatre6SkillType.Wrestle or eventArgs._skillType == ETheatre6SkillType.Dodge then
        if eventArgs._launcherUUID ~= self._npcUUID then return end
        self._proxy:ApplyMagic(self._npcUUID, self._npcUUID, self.BuffId, 1)
    end
end

return XBuffScript1025213