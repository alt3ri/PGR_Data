local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015902 : XBuffBase
local XBuffScript1015902 = XDlcScriptManager.RegBuffScript(1015902, "XBuffScript1015902", Base)
--效果说明：生命值大于等于80%时，进入【浑身】状态

function XBuffScript1015902:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.signalId = 1015903      --浑身标记Buff
    self.signalLevel = 1
    self.effectHpRate = 0.8     --触发浑身效果的Hp比例，高于此条件即可触发
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    --增强Buff列表，enh = enhance
    self.enhBuffIdDict = {
        [1] = 1015648           --增强Buff[1]：触发浑身状态所需的生命值条件降低x
    }
    self.enhRuneIdDict = {
        [1] = 20648             --增强Buff[1]对应的符纹Id
    }
    --增强Buff[1]配置
    self.enhEffectHpRate = 0.4          --降低后的浑身状态触发条件，高于此条件即可触发
    ------------执行------------


end

---@param dt number @ delta time
function XBuffScript1015902:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --开局Buff不存在时，不运行后续逻辑
    if not self._proxy:CheckBuffByKind(self._uuid,self.battleStartBuffId) then
        return
    end

    local percentHp = self._proxy:GetNpcAttribRate(self._uuid, ENpcAttrib.Life)
    local isBuffActive = self._proxy:CheckBuffByKind(self._uuid, self.signalId)
    --身上有标记buff，且低于触发要求的hp时，移除标记buff
    if percentHp < self.effectHpRate and isBuffActive then
        self._proxy:RemoveBuff(self._uuid, self.signalId)
    end
    --生命值满足触发要求时，获得标记
    if percentHp >= self.effectHpRate and (not isBuffActive) then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalId, self.signalLevel)
    end
end


--region EventCallBack
function XBuffScript1015902:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1015902:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        --如果有增强Buff[1]，需要替换【浑身】的触发条件
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1]) then
            self.effectHpRate = self.enhEffectHpRate
            --激活增强Buff[1]符纹特效
            self._proxy:SetAutoChessGemTriggerState(self.enhBuffIdDict[1], self.enhRuneIdDict[1])
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015902:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015902:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015902
