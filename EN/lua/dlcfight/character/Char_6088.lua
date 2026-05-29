local Base = require("Common/XBigWorldCharBase")

---空花拍照任务屏蔽碰撞脚本
---@class XNPC_KuroroWalkNPC : XBigWorldCharBase
local XNPC_KuroroWalkNPC = XDlcScriptManager.RegCharScript(6088, "XNPC_KuroroWalkNPC", Base)

function XNPC_KuroroWalkNPC:CommonInit()
    Base.CommonInit(self)
    self._proxy:SetNpcIgnoreOtherNpcAllCollisions(self._uuid, true)
    self._Target1={x=346.52, y=211.4832, z=173.78}
    self._Target2={x=345.18, y=211.4832, z=178.05}
    self._proxy:NpcNavigateTo(self._uuid,self._Target1,ENpcMoveType.Walk)
    self:FindWaypoint()
end

function XNPC_KuroroWalkNPC:Update(dt)
    self:FindWaypoint()
end

function XNPC_KuroroWalkNPC:FindWaypoint()
    if self._proxy:CheckNpcDistanceWithPos(self._uuid,self._Target1.x,self._Target1.y,self._Target1.z,0.2) then
        self._proxy:NpcNavigateTo(self._uuid,self._Target2,ENpcMoveType.Walk)
    elseif self._proxy:CheckNpcDistanceWithPos(self._uuid,self._Target2.x,self._Target2.y,self._Target2.z,0.2) then
        self._proxy:NpcNavigateTo(self._uuid,self._Target1,ENpcMoveType.Walk)
    end
end

return XNPC_KuroroWalkNPC
