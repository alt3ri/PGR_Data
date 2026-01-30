local Base = require("Common/XFightBase")
local XCharDummy4002 = XDlcScriptManager.RegCharScript(4002, "XCharDummy4002", Base) --躲猫猫木偶人

function XCharDummy4002:Init()
    Base.Init(self)

    self._fxMouseWhiskers = 200032                                         --鼠胡须特效
    self._fxMouseHat = 200034                                              --鼠阵营头套特效

    self._npc = self._proxy:GetSelfNpcId() ---@type number
    self._isPlayerNpc = self._proxy:IsPlayerNpc(self._npc)
    self._lastPos = self._proxy:GetNpcPosition(self._npc)
    self._nextFrameDestroy = false
    self._cameraDir = self._proxy:GetCameraForwardDir()
    self._timer = 0
    self._npcCheckMissileUUID = 0
    if not self._isPlayerNpc then
        self._proxy:ApplyMagic(self._npc, self._npc, 1900031, 1)
        local launchSuccess, missileUUID = self._proxy:LaunchMissile(self._npc, self._npc, 50430132, 50430132, 1)
        self._npcCheckMissileUUID = missileUUID

        self._proxy:ApplyMagic(self._npc, self._npc, self._fxMouseWhiskers, 1) --鼠胡须特效
        self._proxy:ApplyMagic(self._npc, self._npc, self._fxMouseHat, 1)      --鼠阵营头套特效

        local equipUUID = self._proxy:GetNpcEquipUUID(self._npc, 1, 1)
        self._proxy:SetNpcEquipHide(self._npc, equipUUID, true)
    end
end

---@param dt number @ delta time
function XCharDummy4002:Update(dt)
    Base.Update(self, dt)

    if self._isPlayerNpc == nil or self._isPlayerNpc then
        return
    end

    local cameraDir = { x = self._cameraDir.x, y = 0, z = self._cameraDir.z}
    local curPos = self._proxy:GetNpcPosition(self._npc)
    local targetPos = curPos + cameraDir
    self._proxy:NpcMoveTo(self._npc, targetPos, ENpcMoveType.Run)

    self._timer = self._timer + dt
    if self._timer < 1 then
        return
    end

    if self._nextFrameDestroy then
        self._proxy:DestroyNpcDelay(self._npc)
        self._nextFrameDestroy = false
    end

    -- 移动距离判断
    local actualOffset = XScriptTool.Distance(self._lastPos, curPos)
    if actualOffset < 0.01 then
        self._nextFrameDestroy = true
    end

    -- 移动方向夹角判断
    local checkPos = curPos + (curPos - self._lastPos)
    checkPos.y = curPos.y
    if self._proxy:CheckNpcToPosInAngle(self._npc, checkPos, 5) then
        self._nextFrameDestroy = true
    end

    self._lastPos = curPos
end

---@param eventType number
---@param eventArgs userdata

function XCharDummy4002:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.MissileHit)
end

function XCharDummy4002:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.MissileHit then
        if eventArgs.TargetUUID == self._npc and eventArgs.MissileUUID == self._npcCheckMissileUUID then
            self._nextFrameDestroy = true
        end
    end
end

function XCharDummy4002:Terminate()
    self._proxy:UnregisterEvent(EWorldEvent.MissileHit)

    Base.Terminate(self)
end

function XCharDummy4002:DotProduct(fstVec, sndVec)
    return fstVec[1] * sndVec[1] + fstVec[2] * sndVec[2] + fstVec[3] * sndVec[3]
end

return XCharDummy4002