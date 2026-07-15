local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript1025194 : XTheatre6BuffBase
local XBuffScript1025194 = XDlcScriptManager.RegBuffScript(1025194, "XBuffScript1025194", XTheatre6BuffBase)

--效果说明：技能结束后，清除此buff。会导致报错，已废弃。

function XBuffScript1025194:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    self.magicId = 1025194
end

--function XBuffScript1025194:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    --self._proxy:RemoveBuffByKindAndCount(self._npcUUID, self.magicId, 1)
--end

return XBuffScript1025194
