local Base = require("Common/XBigWorldCharBase")

---空花拍照任务屏蔽碰撞脚本
---@class XNPC_PhotoWalkNPC : XBigWorldCharBase
local XNPC_PhotoWalkNPC = XDlcScriptManager.RegCharScript(6086, "XNPC_PhotoWalkNPC", Base)

function XNPC_PhotoWalkNPC:CommonInit()
    Base.CommonInit(self)
    self._proxy:SetNpcIgnoreOtherNpcAllCollisions(self._uuid, true)
    self._Target1={x=590.967, y=194.068, z=1025.55}
    self._Target2={x=590.538, y=194.078, z=1015.738}
    self._proxy:NpcNavigateTo(self._uuid,self._Target1,ENpcMoveType.Walk)
    self:FindWaypoint()
end

function XNPC_PhotoWalkNPC:Update(dt)
    self:FindWaypoint()
end

function XNPC_PhotoWalkNPC:FindWaypoint()
    if self._proxy:CheckNpcDistanceWithPos(self._uuid,self._Target1.x,self._Target1.y,self._Target1.z,0.2) then
        self._proxy:NpcNavigateTo(self._uuid,self._Target2,ENpcMoveType.Walk)
    end

    if self._proxy:CheckNpcDistanceWithPos(self._uuid,self._Target2.x,self._Target2.y,self._Target2.z,0.2) then
        self._proxy:NpcNavigateTo(self._uuid,self._Target1,ENpcMoveType.Walk)
    end
end
return XNPC_PhotoWalkNPC
