local Base = require("Common/XBigWorldCharBase")

---重炮射击敌人脚本
---@class XCharHeavyArtillery7005 : XBigWorldCharBase
---@field _uuid number 当前脚本挂载的NpcId
---@field _proxy XDlcCSharpFuncs
local XCharHeavyArtillery7005 = XDlcScriptManager.RegCharScript(7005, "XCharHeavyArtillery7005", Base)

function XCharHeavyArtillery7005:CommonInit()
    Base.CommonInit(self)
    -- 自定义参数
    self._attackRange = 10 -- 进入攻击状态的范围
    self._attackSkillActionId = 700501 -- 攻击技能 id
    self._attackInterval = self._proxy:Random(1,4) -- 攻击间隔时间

    -- 内部变量
    self._disCheckInterval = 0.1
    self._curDisCheckCdTime = self._disCheckInterval
    self._curAttackCdTime = self._attackInterval
    self._canAttack = false
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)
end

---@param dt number @ delta time 
function XCharHeavyArtillery7005:Update(dt)
    self:UpdateTime(dt)
    self:UpdateAttackState(dt)
    self:TryAttackPlayer(dt)
end

function XCharHeavyArtillery7005:UpdateTime(dt)
    self._curAttackCdTime = self._curAttackCdTime - dt
    self._curDisCheckCdTime = self._curDisCheckCdTime - dt
end

function XCharHeavyArtillery7005:UpdateAttackState(dt)
    if self._curAttackCdTime < 0 and self._curDisCheckCdTime < 0 then
        local selfUUID = self._proxy:GetSelfNpcId()
        local selfPos = self._proxy:GetNpcPosition(selfUUID)
        local localPlayerUUID = self._proxy:GetLocalPlayerNpcId()
        local targetPos = self._proxy:GetNpcPosition(localPlayerUUID)
        local isTargetNpcInRange = XScriptTool.Distance(selfPos, targetPos) < self._attackRange
        self._canAttack = isTargetNpcInRange

        self._curDisCheckCdTime = self._disCheckInterval
    end
end

function XCharHeavyArtillery7005:TryAttackPlayer(dt)
    if not self._canAttack then
        return
    end

    self._proxy:CastActionToTarget(self._uuid, self._attackSkillActionId, self._proxy:GetLocalPlayerNpcId())
    self._curAttackCdTime = self._attackInterval
    self._canAttack = false
end

---@param eventType number
---@param eventArgs userdata
function XCharHeavyArtillery7005:HandleEvent(eventType, eventArgs)
    if   eventType == EWorldEvent.NpcDie then
        if eventArgs.NpcId == self._uuid then
            self._proxy:LaunchMissile(self._proxy:GetNpcUUID(2),self._uuid,7005103,7005103,4033)
        end
    end
end

function XCharHeavyArtillery7005:Terminate()
end

return XCharHeavyArtillery7005
