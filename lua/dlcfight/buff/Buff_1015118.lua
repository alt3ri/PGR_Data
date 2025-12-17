local Base = require("Common/XFightBase")

---@class XBuffScript1015118 : XFightBase
local XBuffScript1015118 = XDlcScriptManager.RegBuffScript(1015118, "XBuffScript1015118", Base)


--效果说明：每隔8s，在我方脚底召唤一个存在5s雷圈，我方角色处在区域内释放技能时，雷伤+50

function XBuffScript1015118:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.range = 3          --半径
    self.refreshCd = 8        --雷圈重新生成的CD
    self.duration = 5        --雷圈的持续时间
    self.magicId = 1015119  --增伤Magic
    self.magicLevel = 1     --magic等级
    self.skillStartType = 2 --起手技能类型
    self.normalAtkType = 1  --普攻技能类型
    self.magicPos = self._proxy:GetNpcPosition(self._uuid)  --雷圈生成位置

    ------------执行------------
    self.refreshTimer = self._proxy:GetNpcTime(self._uuid) + self.refreshCd  --计算雷圈重新生成的计时器
    self.durTimer = self._proxy:GetNpcTime(self._uuid) + self.duration      --计算雷圈生效的计时器
end

---@param dt number @ delta time 
function XBuffScript1015118:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --判断雷圈是否需要重新生成
    if self._proxy:GetNpcTime(self._uuid) >= self.refreshTimer then
        self.magicPos = self._proxy:GetNpcPosition(self._uuid)  --更新雷圈位置
        self.refreshTimer = self._proxy:GetNpcTime(self._uuid) + self.refreshCd  --更新雷圈刷新计时器
        self.durTimer = self._proxy:GetNpcTime(self._uuid) + self.duration      --计算雷圈生效的计时器
    end
end

--region EventCallBack
function XBuffScript1015118:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)    -- OnNpcCastActionEvent
end

function XBuffScript1015118:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    --检查是否在持续时间内，不在时间内就返回
    if self._proxy:GetNpcTime(self._uuid) > self.durTimer then
        return
    end
    --检查自己与雷圈中心点的距离是否满足半径需求，满足则更新buff
    if self._proxy:CheckNpcPositionDistance(self._uuid, self.magicPos, self.range, true) then
        --判断技能类型，是技能起手，就加上增伤，是普攻，就删除增伤
        local skillType =self._proxy:GetActionType(skillId)
        if skillType == self.skillStartType then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --更新Buff
        elseif skillType == self.normalAtkType then
            self._proxy:RemoveBuff(self._uuid,self.magicId)
        end
    else
        --不在圈内的话，就删除技能
        self._proxy:RemoveBuff(self._uuid,self.magicId)
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015118:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015118:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015118
