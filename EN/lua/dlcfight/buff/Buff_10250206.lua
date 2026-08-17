local XTheatre6BuffBase = require("Gameplay/Theatre6/XTheatre6BuffBase")
---@class XBuffScript10250206 : XTheatre6BuffBase
local XBuffScript10250206 = XDlcScriptManager.RegBuffScript(10250206, "XBuffScript10250206", XTheatre6BuffBase)

--效果说明：用于添加伤害上限加成buff

function XBuffScript10250206:Init()
    --初始化
    XTheatre6BuffBase.Init(self)
    ------------配置------------
    local npc01id = self._proxy:Theatre6GetNpc(true)
    local npc02id = self._proxy:Theatre6GetNpc(false)
    if self._uuid == npc01id then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10250207)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10250208)
    elseif self._uuid == npc02id then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10250209)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 10250210)
    end
end

return XBuffScript10250206
