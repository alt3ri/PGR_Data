local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")

---@class XTheatre6SkillBase:XTheatre6BuffBase
local XTheatre6SkillBase = XClass(XTheatre6BuffBase, "XTheatre6SkillBase")

function XTheatre6SkillBase:_BaseInit()
    XTheatre6BuffBase._BaseInit(self)
    self._lv = self._proxy:GetBuffLevel()
    self._skillId = self._proxy:Theatre6GetSkillIdByMagicId(self._buffId, self._lv)
end


return XTheatre6SkillBase