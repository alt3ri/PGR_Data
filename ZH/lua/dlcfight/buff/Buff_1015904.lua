local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015904 : XBuffBase
local XBuffScript1015904 = XDlcScriptManager.RegBuffScript(1015904, "XBuffScript1015904", Base)
--效果说明：敌人生命值小于等于40%时，进入【斩杀】状态

function XBuffScript1015904:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.signalId = 1015905      --斩杀标记Buff
    self.signalLevel = 1
    self.effectHpRateInit = 0.4     --触发斩杀效果的初始Hp比例，敌人生命小于等于此条件即可触发
    self.effectHpRate = 0           --实际生效的Hp比例
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    --增强Buff列表，enh = enhance
    self.enhBuffIdDict = {
        [1] = 1015840, --增强Buff[1]：斩杀线提高
        [2] = 1015841, --增强Buff[2]：即便失去斩杀状态，斩杀相关的Buff也将持续5秒
        [3] = 1015842, --增强Buff[3]：斩杀标签的宝珠效果提升
        [4] = 1015914, --增强Buff[4]，【浑身】状态下承受伤害，可使斩杀类符纹的生效条件提高（具体提高数量与传递的Buff层数有关）
        [5] = 1015928, --增强Buff[5]，触发【背水】效果时，也可触发斩杀的属性提升效果
        [6] = 1015973, --自身生命百分比高于对方时，自身攻击力提升x%，并视为满足【敌人血量低于X%】的条件，触发相关效果。
    }
    self.enhRuneIdDict = {
        [1] = 20840,
        [2] = 20841,
        [3] = 20842,
        [4] = 20914,
        [5] = 20928,
        [6] = 20973, --自身生命百分比高于对方时，自身攻击力提升x%，并视为满足【敌人血量低于X%】的条件，触发相关效果。

    }
    --增强Buff[1]配置
    self.enhBuff1HpRate = 0.8          --斩杀线提高后的值
    --增强Buff[2]配置
    self.enhDurTime = 5                 --延迟失效时间
    self.enhDurTimer = 0                --延迟失效计时器
    --增强Buff[4]配置
    self.enhBuff4SignalId = 1015915     --Buff[4]效果的标记层数
    self.enhBuff4HpRateUp = 0.05        --Buff[4]效果单层可提升的斩杀线数值
    --增强Buff[5]配置
    self.enhBuff5signalId = 1015901      --【背水】标记Id
    ------------执行------------

end

---@param dt number @ delta time
function XBuffScript1015904:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --没有目标时，不用运行后边的
    local targetId = self._proxy:GetFightTargetId(self._uuid)
    if targetId == 0 then
        return
    end

    --开局Buff不存在时，不运行后续逻辑
    if not self._proxy:CheckBuffByKind(self._uuid, self.battleStartBuffId) then
        return
    end

    --记录增强Buff是否存在
    local isEnhBuff1Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1])
    local isEnhBuff2Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2])
    local isEnhBuff3Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[3])
    local isEnhBuff4Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[4])
    local isEnhBuff5Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[5])
    local isEnhBuff6Active = self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[6])

    --重置斩杀线
    self.effectHpRate = self.effectHpRateInit

    --如果有增强Buff[1]，需要替换【斩杀】的触发条件
    if isEnhBuff1Active then
        self.effectHpRate = self.enhBuff1HpRate
    end

    --如果有增强Buff[4]存在，需要根据标记层数来判断斩杀线提高多少
    if isEnhBuff4Active then
        --获取Buff[4]标记层数，调整斩杀线
        local enhBuff4Stacks = self._proxy:GetBuffStacks(self._uuid, self.enhBuff4SignalId)
        self.effectHpRate = self.effectHpRate + enhBuff4Stacks * self.enhBuff4HpRateUp
    end

    --计算敌人的生命比例
    local enemyPercentHp = self._proxy:GetNpcAttribRate(targetId, ENpcAttrib.Life)
    local isBuffActive = self._proxy:CheckBuffByKind(self._uuid, self.signalId)
    --计算我方生命值比例是否高于敌方
    local selfPercentHp = self._proxy:GetNpcAttribRate(self._uuid, ENpcAttrib.Life)
    local isSelfHpPercentHigher = selfPercentHp > enemyPercentHp

    --身上有标记buff，且高于触发要求的hp时，移除标记buff
    if enemyPercentHp > self.effectHpRate and isBuffActive then
        --如果有Buff[5]存在，则检查是否有【背水】状态，如果有则无需删除
        if isEnhBuff5Active and self._proxy:CheckBuffByKind(self._uuid, self.enhBuff5signalId) then
            return
        end
        --如果有Buff[6]存在，且我方生命值高于敌方则无需删除
        if isEnhBuff6Active and isSelfHpPercentHigher then
            return
        end
        --如果有增强Buff[2]存在，且计时器为0时，需先开启计时器并开启icon特效，当计时器满足条件后再删除
        if isEnhBuff2Active and self.enhDurTimer == 0 then
            self.enhDurTimer = self._proxy:GetNpcTime(self._uuid) + self.enhDurTime
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.enhRuneIdDict[2])
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.enhRuneIdDict[2], 1)  --记录一次触发

        end
        if self._proxy:GetNpcTime(self._uuid) > self.enhDurTimer then
            self._proxy:RemoveBuff(self._uuid, self.signalId)
            --重置计时器
            self.enhDurTimer = 0
            --如果有Buff[2]存在，则关闭icon特效
            if isEnhBuff2Active then
                self._proxy:SetAutoChessGemData(self._uuid, self.enhRuneIdDict[2], 0, 0)
            end
            --如果有Buff[3]存在，则关闭icon特效
            if isEnhBuff3Active then
                self._proxy:SetAutoChessGemData(self._uuid, self.enhRuneIdDict[3], 0, 0)
            end
        end
    end

    --三种标记获得条件，1:敌人生命值满足触发要求时，获得标记；2:如果有Buff[5]存在，且有【背水】效果时；3:Buff[6]存在且我方生命值比例高于敌方
    local isEnemyHpOk = enemyPercentHp <= self.effectHpRate and (not isBuffActive)
    local isEnhBuff5Ok = isEnhBuff5Active and self._proxy:CheckBuffByKind(self._uuid, self.enhBuff5signalId)
    local isEnhBuff6Ok = isEnhBuff6Active and isSelfHpPercentHigher
    --任意条件满足要求即可，获得标记
    if isEnemyHpOk or isEnhBuff5Ok or isEnhBuff6Ok then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalId, self.signalLevel)
        --如果有Buff[3]存在，则开启特效
        if isEnhBuff3Active then
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.enhRuneIdDict[3])
        end
    end
end

--region EventCallBack
function XBuffScript1015904:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1015904:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --正式开始战斗的处理
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        --增强Buff[1]特效
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[1]) then
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.enhRuneIdDict[1])
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.enhRuneIdDict[1], 1)  --记录一次触发
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015904:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015904:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015904
