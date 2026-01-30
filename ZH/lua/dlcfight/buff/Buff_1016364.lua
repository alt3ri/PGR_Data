local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016364 : XBuffBase
local XBuffScript1016364 = XDlcScriptManager.RegBuffScript(1016364, "XBuffScript1016364", Base)
--效果说明：加生命最大值，敌我角色不同时加更多生命最大值

function XBuffScript1016364:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.buffLevelGroupId= {1016364, 1016365, 1016366, 1016367, 1016368}  --5个等级
    self.lifeBuffGroupId={1016369, 1016370, 1016371, 1016372, 1016373}  --生命值Buff
    self.currentLifeToUp = 0

    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    self.lifeAddBuff = 1016417
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript1016364:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --Buff不存在时，不运行后续逻辑
end
--region EventCallBack

function XBuffScript1016364:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcCureAfter)

end

function XBuffScript1016364:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)

        local meNpcId = self._proxy:GetNpcTemplate(self._uuid)
        local enemyNpcId = self._proxy:GetNpcTemplate(self.targetId)
        for thisLevel, buffGroupThisLevel in ipairs(self.buffLevelGroupId) do
            if self._proxy:CheckBuffByKind(self._uuid, buffGroupThisLevel) then
                local currentLife = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
                if meNpcId.Id == enemyNpcId.Id then
                    --同角色，开lv1的加成
                    self._proxy:ApplyMagic(self._uuid,self._uuid,self.lifeBuffGroupId[thisLevel], 1)
                    self.currentLifeToUp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life) - currentLife
                    self._proxy:ApplyMagic(self._uuid,self._uuid,self.lifeAddBuff, 1)

                else
                    --非同角色，开lv2的加成
                    self._proxy:ApplyMagic(self._uuid,self._uuid,self.lifeBuffGroupId[thisLevel], 2)
                    self.currentLifeToUp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life) - currentLife
                    self._proxy:ApplyMagic(self._uuid,self._uuid,self.lifeAddBuff, 1)
                end
            end
        end
    end
end

function XBuffScript1016364:AfterCureCalc(eventArgs)
    local isPlayer = eventArgs.Launcher == self._uuid and eventArgs.Target == self._uuid --奶自己
    local isThisCure = eventArgs.Id == self.lifeAddBuff --奶来自该buff
    if isPlayer and isThisCure then
        self._proxy:SetAfterCureMagicContext(eventArgs.ContextId,self.currentLifeToUp)
    end

end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016364:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016364:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016364
