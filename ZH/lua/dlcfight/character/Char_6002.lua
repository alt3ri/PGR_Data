local Base = require("Common/XBigWorldCharBase")

---空花拍照任务屏蔽碰撞脚本
---@class XNPC_PhotoRunNPC : XBigWorldCharBase
local XNPC_PhotoRunNPC = XDlcScriptManager.RegCharScript(6002, "XNPC_PhotoRunNPC", Base)

function XNPC_PhotoRunNPC:CommonInit()
    Base.CommonInit(self)
    self._proxy:SetNpcIgnoreOtherNpcAllCollisions(self._uuid, true)
    self._Target1={x=571.587402, y=194.561005, z=981.9245}
    self._Target2={x=573.18396, y=194.561005, z=967.689148}
    self._proxy:NpcNavigateTo(self._uuid,self._Target1,ENpcMoveType.Run)
    self:FindWaypoint()
end

function XNPC_PhotoRunNPC:Update(dt)
    self:FindWaypoint()
end

function XNPC_PhotoRunNPC:FindWaypoint()
    if self._proxy:CheckNpcDistanceWithPos(self._uuid,self._Target1.x,self._Target1.y,self._Target1.z,0.2) then
        self._proxy:NpcNavigateTo(self._uuid,self._Target2,ENpcMoveType.Run)
    end

    if self._proxy:CheckNpcDistanceWithPos(self._uuid,self._Target2.x,self._Target2.y,self._Target2.z,0.2) then
        self._proxy:NpcNavigateTo(self._uuid,self._Target1,ENpcMoveType.Run)
    end
end
return XNPC_PhotoRunNPC
