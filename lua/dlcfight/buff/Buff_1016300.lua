local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016300 : XBuffBase
local XBuffScript1016300 = XDlcScriptManager.RegBuffScript(1016300, "XBuffScript1016300", Base)
--效果说明：敌人生命最大值高于自身最大值healthPercent倍时，造成伤害提升

function XBuffScript1016300:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.buffLevelGroupId= {1016300, 1016301, 1016302, 1016303, 1016304}  --5个等级
    self.healthPercent={1, 1, 1, 1, 1}  --生命值倍率
    self.magicIds={1016305,1016306,1016307,1016308}   --全属性增伤效果

    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript1016300:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --Buff不存在时，不运行后续逻辑
end
--region EventCallBack

function XBuffScript1016300:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1016300:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        local hpMaxSelf = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
        local hpMaxTarget = self._proxy:GetNpcAttribMaxValue(self.targetId, ENpcAttrib.Life)

        for thisLevel, buffGroupThisLevel in ipairs(self.buffGroupId) do
            if self._proxy:CheckBuffByKind(self._uuid, buffGroupThisLevel) then
                --双方生命值判定
                local isHealthOk = hpMaxSelf*self.healthPercent[thisLevel] < hpMaxTarget
                --如果自身生命最大值的{0}%<敌人生命最大值，执行
                if isHealthOk then
                    for _, magicId in ipairs(self.magicIds) do
                        self._proxy:ApplyMagic(self._uuid,self._uuid,magicId, thisLevel)
                    end
                end
            end
        end
    end

end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016300:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016300:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016300
