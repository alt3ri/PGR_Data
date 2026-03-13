local Base = require("Common/XBigWorldCharBase")

---重炮射击辅助机脚本
---@class XCharHeavyArtillery7002 : XBigWorldCharBase
---@field _uuid number 当前脚本挂载的NpcId
---@field _proxy XDlcCSharpFuncs
local XCharHeavyArtillery7002 = XDlcScriptManager.RegCharScript(7002, "XCharHeavyArtillery7002", Base)

---@param proxy XDlcCSharpFuncs
function XCharHeavyArtillery7002:Ctor(proxy)
    self._proxy = proxy
end

function XCharHeavyArtillery7002:CommonInit()
    Base.CommonInit(self)
    -- 自定义参数
    self._attackSkillActionId = 700201 -- 攻击技能 id

    -- 内部变量
    self._proxy:SetNpcCamp(self._uuid, ENpcCampType.Camp1)
    self._maxRaycastLength = 500
    self._placeId = self._proxy:GetNpcPlaceId()
    self._proxy:SetNpcNodeLockFollow(self._placeId, "Bip001Neck", { x = -1, y = 0.5, z = 0 }, true)
    self._proxy:RegisterEvent(EWorldEvent.GameplayHeavyArtilleryFireTriggerFire)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.MissileCreate)

    XLog.Debug("注册成功")
end

---@param dt number @ delta time
function XCharHeavyArtillery7002:Update(dt)
end

function XCharHeavyArtillery7002:Attack()

    self._Playeruuid = self._proxy:GetLocalPlayerNpcId()
    local hitObstacle, hitPos = self._proxy:CheckCameraRayCastCollider(self._maxRaycastLength)
    self._proxy:CastActionToPosition(self._uuid, self._attackSkillActionId, hitPos)
end

---@param eventType number
---@param eventArgs userdata
function XCharHeavyArtillery7002:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.MissileCreate then
        local checkSuccess, templateId = self._proxy:MissileUUIDToTemplateId(eventArgs.MissileUUID)
        if templateId == 7002102 then
            XLog.Debug("检测到子弹爆炸")
            self._proxy:ApplyMagic(self._uuid,self._Playeruuid,7002113,1)
            XLog.Debug("重炮射击辅助机命中向后震屏")
            self._proxy:ApplyMagic(self._uuid,self._Playeruuid,7002114,1)
            XLog.Debug("重炮射击辅助机命中向上震屏")
            self._proxy:ApplyMagic(self._uuid,self._Playeruuid,7002115,1)
            XLog.Debug("重炮射击辅助机命中左右震屏")
            self._proxy:ApplyMagic(self._uuid,self._Playeruuid,7002112,1)
            XLog.Debug("重炮射击辅助机命中顿帧")

        end

    end


    if eventType == EWorldEvent.GameplayHeavyArtilleryFireTriggerFire then
        self._proxy:SetNpcStopFollow(self._uuid)
        self:Attack()
    end

    if eventType == EWorldEvent.NpcAddBuff and eventArgs.BuffTableId == 7002108 then
        XLog.Debug("7002108：检测到buff被添加")

        self._proxy:ApplyMagic(self._uuid,self._Playeruuid,7002119,1)
        XLog.Debug("禁止相机输入")
        self._proxy:ApplyMagic(self._uuid,self._Playeruuid,7002116,1)
        XLog.Debug("相机后退")
        self._proxy:ApplyMagic(self._uuid,self._Playeruuid,7002117,1)
        XLog.Debug("瞄准相机FOV增大")
        self._proxy:ApplyMagic(self._uuid,self._Playeruuid,7002109,1)
        XLog.Debug("顿帧")
        self._proxy:ApplyMagic(self._uuid,self._Playeruuid,7002110,1)
        XLog.Debug("重炮射击辅助机发射向上震屏")
        self._proxy:ApplyMagic(self._uuid,self._Playeruuid,7002111,1)
        XLog.Debug("重炮射击辅助机发射向后震屏")

    end


    if eventType == EWorldEvent.NpcAddBuff and eventArgs.BuffTableId == 7002107 then
        XLog.Debug("7002107：检测到buff被添加")
        self._proxy:SetNpcNodeLockFollow(self._placeId, "Bip001Neck", { x = -1, y = 0.5, z = 0 }, true)
    end
end


function XCharHeavyArtillery7002:Terminate()
    if self._Playeruuid ~= nil and self._proxy:CheckNpc(self._Playeruuid) then
        self._proxy:RemoveBuff(self._Playeruuid, 7002119)
    end
    self._proxy:UnregisterEvent(EWorldEvent.GameplayHeavyArtilleryFireTriggerFire)
end

return XCharHeavyArtillery7002
