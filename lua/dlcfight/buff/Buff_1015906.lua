local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015906 : XBuffBase
local XBuffScript1015906 = XDlcScriptManager.RegBuffScript(1015906, "XBuffScript1015906", Base)
--效果说明：战斗开始进入【开局】状态，持续一段时间

function XBuffScript1015906:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.signalId = 1015907         --开局标记Buff
    self.signalLevel = 1
    self.effectTimeInit = 12        --开局效果初始时间/秒
    self.effectTime = self.effectTimeInit          --实际生效的开局效果时长
    self.effectTimer = 0            --开局效果计时器
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    --增强Buff列表，enh = enhance
    self.enhBuffIdDict = {
        [1] = 1015790, --增强Buff[1]：开局效果提升（2级效果）
        [2] = 1015792, --增强Buff[2]：开局效果增加一定时间
        [3] = 1015920  --增强Buff[3]：生命值高于80%时，每造成1000点伤害，可延长0.5秒开局类属性提升效果的持续时间
    }
    self.enhRuneIdDict = {
        [1] = 20790,
        [2] = 20792,
        [3] = 20920
    }
    --增强Buff[2]配置
    self.enhDurTime = 4                 --延长时间
    --增强Buff[3]配置
    self.enhBuff3SignalId = 1015921              --标记buffID
    self.enhBuff3AddTime = 0.5                 --触发后增加的时长/秒
    ------------执行------------

end

---@param dt number @ delta time
function XBuffScript1015906:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --开局Buff不存在时，不运行后续逻辑
    if not self._proxy:CheckBuffByKind(self._uuid, self.battleStartBuffId) then
        return
    end

    --开局后打标记+设置计时器
    if self.effectTimer == 0 then
        self.effectTimer = self._proxy:GetNpcTime(self._uuid) + self.effectTime
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalId, self.signalLevel)
    end

    --超出计时器时间后，删除标记
    if self._proxy:GetNpcTime(self._uuid) > self.effectTimer then
        self._proxy:RemoveBuff(self._uuid, self.signalId)
        --删除Buff[1][2]的特效
        self._proxy:SetAutoChessGemData(self._uuid, self.enhRuneIdDict[1], 0, 0)
        self._proxy:SetAutoChessGemData(self._uuid, self.enhRuneIdDict[2], 0, 0)
    end

end

--region EventCallBack
function XBuffScript1015906:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1015906:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --正式开始战斗后的处理
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        --如果有增强Buff[1]，则激活icon特效
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1]) then
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.enhRuneIdDict[1])
        end
        --如果有增强Buff[2]，则开局效果时间延长，并激活icon特效
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2]) then
            self.effectTime = self.effectTimeInit + self.enhDurTime
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.enhRuneIdDict[2])
        end
    end
    --Buff[3]消耗标记增加时长
    if npcUUID == self._uuid and buffId == self.enhBuff3SignalId then
        local buffStacks = self._proxy:GetBuffStacks(self._uuid, self.enhBuff3SignalId)
        self.effectTimer = self.effectTimer + self.enhBuff3AddTime * buffStacks
        self._proxy:RemoveBuff(self._uuid, self.enhBuff3SignalId)
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015906:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015906:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015906
