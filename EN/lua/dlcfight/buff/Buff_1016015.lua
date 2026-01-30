local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016015 : XBuffBase
local XBuffScript1016015 = XDlcScriptManager.RegBuffScript(1016015, "XBuffScript1016015", Base)
--效果说明：敌人每回复5000点生命，则偷取其2000点生命

function XBuffScript1016015:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1016016
    self.cureId = 1016017
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    self.damageUpRate = 2
    self.cureSum = 0
    self.cureTarget = 5000
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016015:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --开局Buff不存在时，不运行后续逻辑
    if not self._proxy:CheckBuffByKind(self._uuid, self.battleStartBuffId) then
        return
    end
    if not self._proxy:CheckNpc(self.targetId) then
        return
    end

end

--region EventCallBack
function XBuffScript1016015:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcCureAfter)
end

function XBuffScript1016015:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
    end
end

function XBuffScript1016015:AfterCureCalc(eventArgs)
    if eventArgs.Target == self.targetId then
        self.cureSum = eventArgs.FinalValue + self.cureSum
        local magicTimes = math.floor(self.cureSum / self.cureTarget)
        for _ = 1, magicTimes do
            self._proxy:ApplyMagic(self._uuid, self.targetId, self.magicId, self.magicLevel)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.cureId, self.magicLevel)
        end
        self.cureSum = self.cureSum % self.cureTarget
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016015:HandleEvent(eventType, eventArgs)
Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016015:Terminate()
Base.Terminate(self)
end

return XBuffScript1016015
