local Base = require("Common/XFightBase")
---@class XBuffScript1018001 : XFightBase
local XBuffScript1018001 = XDlcScriptManager.RegBuffScript(1018001, "XBuffScript1018001", Base)

function XBuffScript1018001:Init() --初始化
    Base.Init(self)
    -----------------------------Partner配置------------------------
    self.shashen = nil
    self.kaiguan = true
    local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标
    local camp = self._proxy:GetNpcCamp(self._uuid)
    local targetRota2 = {x = 0, y = 180, z =0}
    local targetBehindPos = self._proxy:GetNpcOffsetPositionByFacing(target, targetRota2, 1)
    self.shashen = self._proxy:GenerateNpc(1018, camp, targetBehindPos, targetRota2)--生成杀神
    self._proxy:CastActionToTarget(self.shashen,101801,target)
    self._proxy:AddTimerTask(1, function()--延迟3秒后，释放技能
        if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
            return
        end
        local Position = self._proxy:GetNpcPosition(target)--获取目标位置
        self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
        if self._proxy:GetBuffStacks(self._uuid, 1016238) == 2 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
        elseif self._proxy:GetBuffStacks(self._uuid, 1016238) == 3 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
        elseif self._proxy:GetBuffStacks(self._uuid, 1016238) == 4 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
        elseif self._proxy:GetBuffStacks(self._uuid, 1016238) == 5 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
        elseif self._proxy:GetBuffStacks(self._uuid, 1016238) == 6 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
        elseif self._proxy:GetBuffStacks(self._uuid, 1016238) == 7 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10180105,10180105,Position,Position,1)--伤害子弹
        end
    end)
    self._proxy:AddTimerTask(3.5, function()--延迟3.5秒后，释放技能
        if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
            return
        end
        self._proxy:CastActionToTarget(self.shashen,101802,target)
        self._proxy:ApplyMagic(self._uuid, self._uuid,  1018201, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid,  1018202, 1)
        self.kaiguan = true
    end)
    self._proxy:AddTimerTask(5.2, function()--延迟3.5秒后，释放技能
        if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
            return
        end
        self._proxy:AbortAction(self.shashen, true)
        self._proxy:CastActionToTarget(self.shashen,101803,target)
    end)
    self._proxy:AddTimerTask(7.2, function()--延迟3.5秒后，释放技能
        if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
            return
        end
        self._proxy:AbortAction(self.shashen, true)
        self._proxy:CastActionToTarget(self.shashen,101803,target)
    end)
    self._proxy:AddTimerTask(9.2, function()--延迟3.5秒后，释放技能
        if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
            return
        end
        self._proxy:AbortAction(self.shashen, true)
        self._proxy:CastActionToTarget(self.shashen,101803,target)
    end)
end

---@param dt number @ delta time 
function XBuffScript1018001:Update(dt)
    Base.Update(self, dt)
    if not self._proxy:CheckBuffByKind(self._uuid, 1015907) and self.kaiguan == true then
        self.kaiguan = false
        self._proxy:ApplyMagic(self._uuid, self._uuid,  1018203, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid,  1018204, 1)
        self._proxy:AddTimerTask(1, function()--延迟1秒后，死亡
            self._proxy:DestroyNpc(self.shashen)--移除NPC
            self._proxy:ApplyMagic(self._uuid, self._uuid,  1018205, 1)
        end)
    end
end

return XBuffScript1018001
