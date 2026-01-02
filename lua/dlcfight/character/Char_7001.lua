local Base = require("Common/XBigWorldCharBase")

---重炮射击敌人脚本
---@class XCharHeavyArtillery7001 : XBigWorldCharBase
---@field _uuid number 当前脚本挂载的NpcId
---@field _proxy XDlcCSharpFuncs
local XCharHeavyArtillery7001 = XDlcScriptManager.RegCharScript(7001, "XCharHeavyArtillery7001", Base)

function XCharHeavyArtillery7001:Init()
    Base.CommonInit(self)
    -- 自定义参数
    self._attackRange = 10 -- 进入攻击状态的范围
    self._attackSkillActionId = 700101 -- 攻击技能 id
    self._attackInterval = 1 -- 攻击间隔时间

    -- 内部变量
    self._disCheckInterval = 0.1
    self._curDisCheckCdTime = self._disCheckInterval
    self._curAttackCdTime = self._attackInterval
    self._canAttack = false
end

---@param dt number @ delta time 
function XCharHeavyArtillery7001:Update(dt)
    self:UpdateTime(dt)
    self:UpdateAttackState(dt)
    self:TryAttackPlayer(dt)
end

function XCharHeavyArtillery7001:UpdateTime(dt)
    self._curAttackCdTime = self._curAttackCdTime - dt
    self._curDisCheckCdTime = self._curDisCheckCdTime - dt
end

function XCharHeavyArtillery7001:UpdateAttackState(dt)
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

function XCharHeavyArtillery7001:TryAttackPlayer(dt)
    if not self._canAttack then
        return
    end

    self._proxy:CastActionToTarget(self._uuid, self._attackSkillActionId, self._proxy:GetLocalPlayerNpcId())
    self._curAttackCdTime = self._attackInterval
    self._canAttack = false
end

---@param eventType number
---@param eventArgs userdata
function XCharHeavyArtillery7001:HandleEvent(eventType, eventArgs)
end

function XCharHeavyArtillery7001:Terminate()
end

return XCharHeavyArtillery7001
