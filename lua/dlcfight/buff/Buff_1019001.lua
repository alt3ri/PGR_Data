local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1019001 : XBuffBase
local XBuffScript1019001 = XDlcScriptManager.RegBuffScript(1019001, "XBuffScript1019001", Base)

function XBuffScript1019001:Init() --初始化
    Base.Init(self)
    -----------------------------Partner配置------------------------
    self.Aibi = nil
    local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标
    local camp = self._proxy:GetNpcCamp(self._uuid)
    local targetRota2 = {x = 0, y = 180, z =0}
    local targetBehindPos = self._proxy:GetNpcOffsetPositionByFacing(target, targetRota2, 1)
    self.Aibi = self._proxy:GenerateNpc(1019, camp, targetBehindPos, targetRota2)--生成埃比
    self._proxy:CastActionToTarget(self.Aibi,101901,target)
    self._proxy:AddTimerTask(2.25, function()--延迟2.25秒后，释放子弹
        if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
            return
        end
        local Position = self._proxy:GetNpcPosition(target)--获取目标位置
        self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
        if self._proxy:GetBuffStacks(self._uuid, 1016241) == 2 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
        elseif self._proxy:GetBuffStacks(self._uuid, 1016241) == 3 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
        elseif self._proxy:GetBuffStacks(self._uuid, 1016241) == 4 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
        elseif self._proxy:GetBuffStacks(self._uuid, 1016241) == 5 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
        elseif self._proxy:GetBuffStacks(self._uuid, 1016241) == 6 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
        elseif self._proxy:GetBuffStacks(self._uuid, 1016241) == 7 then
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
            self._proxy:LaunchMissileFromPosToPos(self._uuid,10190116,10190116,Position,Position,1)--伤害子弹
        end
    end)
    self._proxy:AddTimerTask(5, function()--延迟5秒后，死亡
        self._proxy:DestroyNpc(self.Aibi)--移除NPC
    end)
end
---@param dt number @ delta time


return XBuffScript1019001
