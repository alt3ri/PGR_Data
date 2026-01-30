local Base = require("Common/XBigWorldCharBase")

---空花拍照任务屏蔽碰撞脚本
---@class XNPC_PhotoNPC : XBigWorldCharBase
local XNPC_PhotoNPC = XDlcScriptManager.RegCharScript(6047, "XNPC_PhotoNPC", Base)

function XNPC_PhotoNPC:CommonInit()
    Base.CommonInit(self)
    self._proxy:SetNpcIgnoreOtherNpcAllCollisions(self._uuid, true)
end

return XNPC_PhotoNPC
