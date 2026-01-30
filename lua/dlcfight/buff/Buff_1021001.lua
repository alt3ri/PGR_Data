local Base = require("Buff/BuffBase/XBuffBase")
---@class XBuffScript1021001 : XBuffBase
local XBuffScript1021001 = XDlcScriptManager.RegBuffScript(1021001, "XBuffScript1021001", Base)

function XBuffScript1021001:Init() --初始化
    Base.Init(self)
    -----------------------------Partner配置------------------------
    self.Jingmo = nil
    self.kaiguan = true
    local target = self._proxy:GetFightTargetId(self._uuid) --获取战斗目标

    local camp = self._proxy:GetNpcCamp(self._uuid)
    local targetRota2 = {x = 0, y = 180, z =0}
    local targetBehindPos = self._proxy:GetNpcOffsetPositionByFacing(target, targetRota2, 1)
    self.Jingmo = self._proxy:GenerateNpc(1021, camp, targetBehindPos, targetRota2)--生成镜魔
    self._proxy:CastActionToTarget(self.Jingmo,102101,target)
    self._proxy:AddTimerTask(1.75, function()--延迟1.75秒后，释放子弹
        if not self._proxy:CheckActorExist(target) then  --检测目标是否存活
            return
        end
        local Position = self._proxy:GetNpcPosition(target)--获取目标位置
        self.BuffStacks = self._proxy:GetBuffStacks(self._uuid, 1016243)
        if self._proxy:CheckBuffByKind(self._uuid, 1016374) then
            for i = 1, self.BuffStacks do
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10210103,10210132,Position,Position,1)--强化伤害子弹
            end
        else
            for i = 1, self.BuffStacks do
                self._proxy:LaunchMissileFromPosToPos(self._uuid,10210103,10210103,Position,Position,1)--伤害子弹
            end
        end
    end)
    self._proxy:AddTimerTask(5, function()--延迟5秒后，死亡
        self._proxy:DestroyNpc(self.Jingmo)--移除NPC
    end)
end

function XBuffScript1021001:Update(dt)
    Base.Update(self, dt)
end

return XBuffScript1021001
