local Base = require("Common/XBigWorldCharBase")

---阿尔法邀约教官巡逻脚本本
---@class XNPC_PatrollerNPC : XBigWorldCharBase
local XNPC_PatrollerNPC = XDlcScriptManager.RegCharScript(6089, "XNPC_PatrollerNPC", Base)

function XNPC_PatrollerNPC:CommonInit()
    Base.CommonInit(self)
    self._proxy:RegisterEvent(EWorldEvent.ActorTrigger)
    self._proxy:SetNpcIgnoreOtherNpcAllCollisions(self._uuid, true)
    self._Start={x=326.3, y=289.2, z=263.3}---------------------------教官出发的位置326.3,289.2,263.3
    self._Target={x=325.9, y=289.2, z=254.0}--------------------------教官巡查的第一个目标点325.9,289.2,254.0
    self._Target2={x=340.3, y=291.4, z=253.8}--------------------------教官巡查的第二个目标点340.3,291.4,253.8
    self._PlayerPos={x=326.20, y=287.30, z=233.90}-----------------------玩家触发Trigger后被传送回的位置326.20,287.30,233.90
    self._proxy:NpcNavigateTo(self._uuid,self._Target,ENpcMoveType.Walk)------------教官出发
    self:FindWaypoint()-----------------------------持续执行巡逻逻辑

end

function XNPC_PatrollerNPC:Update(dt)
    self:FindWaypoint()-----------------------------持续执行巡逻逻辑

end

function XNPC_PatrollerNPC:FindWaypoint()
    if self._proxy:CheckNpcDistanceWithPos(self._uuid,self._Target.x,self._Target.y,self._Target.z,0.2) then----------------抵达Target之后转身向新目标点走去
        self._proxy:NpcNavigateTo(self._uuid,self._Target2,ENpcMoveType.Walk)
    elseif self._proxy:CheckNpcDistanceWithPos(self._uuid,self._Target2.x,self._Target2.y,self._Target2.z,0.2) then
        self._proxy:SetNpcFade(self._uuid,false,3)---------------------到目的地把自己渐隐了
    end
end

function XNPC_PatrollerNPC:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.ActorTrigger and eventArgs.TriggerState == ETriggerState.Enter and eventArgs.TriggerHolderUUID == self._uuid  then
        self._proxy:PlayBlackScreenEffect()--------------播放黑屏
        self._proxy:SetNpcPosition(self._uuid,self._Start)-----------------------将NPC传回起点
        self._proxy:SetNpcPosition(self._proxy:GetLocalPlayerNpcId(),self._PlayerPos)-----------------------将玩家传回起点
    end
end


return XNPC_PatrollerNPC
