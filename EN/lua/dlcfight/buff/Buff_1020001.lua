local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1020001 : XBuffBase
local XBuffScript1020001 = XDlcScriptManager.RegBuffScript(1020001, "XBuffScript1020001", Base)

function XBuffScript1020001:Init() --初始化
    Base.Init(self)
    -----------------------------Partner配置------------------------
    self.Jingmo = nil
    local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标
        local camp = self._proxy:GetNpcCamp(self._uuid)
        local targetRota2 = {x = 0, y = 180, z =0}
        local targetBehindPos = self._proxy:GetNpcOffsetPositionByFacing(target, targetRota2, 1)
        self.Jingmo = self._proxy:GenerateNpc(1020, camp, targetBehindPos, targetRota2)--生成镜魔
        self._proxy:CastActionToTarget(self.Jingmo,102001,target)
        self._proxy:AddTimerTask(1.75, function()--延迟1.75秒后，释放子弹
            if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
                return
            end
            local Position = self._proxy:GetNpcPosition(target)--获取目标位置
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
            if self._proxy:GetBuffStacks(self._uuid, 1016242) == 2 then
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
            elseif self._proxy:GetBuffStacks(self._uuid, 1016242) == 3 then
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
            elseif self._proxy:GetBuffStacks(self._uuid, 1016242) == 4 then
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
            elseif self._proxy:GetBuffStacks(self._uuid, 1016242) == 5 then
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
            elseif self._proxy:GetBuffStacks(self._uuid, 1016242) == 6 then
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
            elseif self._proxy:GetBuffStacks(self._uuid, 1016242) == 7 then
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10200108,10200108,Position,Position,1)--伤害子弹
            end
        end)
        self._proxy:AddTimerTask(5, function()--延迟5秒后，死亡
            self._proxy:DestroyNpc(self.Jingmo)--移除NPC
        end)
    end

---@param dt number @ delta time
function XBuffScript1020001:Update(dt)
    Base.Update(self, dt)
end

return XBuffScript1020001
