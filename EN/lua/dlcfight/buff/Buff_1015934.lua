local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015934 : XBuffBase
local XBuffScript1015934 = XDlcScriptManager.RegBuffScript(1015934, "XBuffScript1015934", Base)

--效果说明：每间隔5秒，有40%概率将5%当前生命值转化为等量生命最大值

function XBuffScript1015934:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015935          --属性提升Buff
    self.runeId = 20934            --符纹ID赋值
    self.attackId = 1015999         --通用1点伤害
    self.attackRate = 0.05          --造成伤害比例5%当前生命值
    self.magicLevel = 1 --初始buff等级1级
    self.signalId = 1015913         --【概率】状态标记，标记管理脚本见1015910
    self.signalCtrlId = 1015912     --【概率】状态管理Buff
    self.magicStacks = 1            --【概率】触发时，添加的Buff层数
    self.magicProb = 40             --【概率】符纹触发概率
    --增强Buff列表，enh = enhance
    self.enhBuffIdDict = {
        [1] = 1015740, --带有【概率触发】条件的效果触发时，自身额外获得X%的伤害提升（注意，不吃定时的效果翻倍，因为这个效果不带有【每隔X秒】条件）
        [2] = 1015741, --概率类符纹触发时，可以额外触发一次
        [3] = 1015742, --概率类触发概率+10%
        [5] = 1015940, --获得标记时，定时符纹的间隔有20%概率缩短0.5秒（最短缩短至2秒）
        [6] = 1015936, --自身生命值低于20%时，概率类符纹可额外触发一次，效果叠加
        [7] = 1015938, --每间隔5秒，永久提升概率类符纹的触发概率5%（最大20%）
        [8] = 1015948, --每间隔5秒，疲劳阶段的时间有20%概率提前2秒
    }
    self.enhRuneIdDict = {
        [1] = 20740,
        [2] = 20741,
        [3] = 20742,
        [5] = 20940,
        [6] = 20936,
        [7] = 20938,
        [8] = 20948,
    }
    --增强Buff[1]配置
    self.enhBuffSuccessSignal = 1015743  --若【概率】符纹触发，则通过此标记告知Buff[1]

    --增强Buff[2]配置
    self.enhBuff2Stacks = 1         --有Buff[2]时，成功触发时，额外获得一层效果

    --增强Buff[3]配置
    self.enhBuff3MagicProbRate = 2     --有Buff[3]时，触发概率提升倍率

    --增强Buff[5]配置
    self.enhBuff5Prob = 20          --若Buff[5]运行时，概率需替换为20%

    --增强Buff[6]配置
    self.enhBuff6Stacks = 1         --有Buff[6]时，且处于【背水】状态时，成功触发时，额外获得一层效果
    self.enhBuff6SignalId = 1015901 --【背水】标记ID
    self.enhBuff6signalCtrlId = 1015900 --【背水】管理Buff

    --增强Buff[7]配置
    self.enhBuff7SignalId = 1015939 --标记ID
    self.enhBuff7Prob = 8           --每层提升的概率

    --增强Buff[8]配置
    self.enhBuff8SignalId = 1015949 --标记ID
    self.enhBuff8Prob = 20          --若Buff[8]运行时，概率需替换为20%
    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加管理Buff

end

---@param dt number @ delta time
function XBuffScript1015934:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1015934:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)
end

function XBuffScript1015934:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局处理
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        if self._proxy:CheckBuffByKind(self._uuid,self.enhBuffIdDict[6]) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.enhBuff6signalCtrlId, 1)   --为自己添加【背水】管理Buff
        end
    end

    --获得【概率】标记时，进行此逻辑
    if npcUUID == self._uuid and buffId == self.signalId then
        --如果有Buff[2]，则添加层数+1
        local magicStacks = self.magicStacks
        local magicProb = self.magicProb
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2]) then
            magicStacks = magicStacks + self.enhBuff2Stacks
        end
        --如果有Buff[6]，且处于【背水】状态，则添加层数+1
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuff6SignalId) and self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[6]) then
            magicStacks = magicStacks + self.enhBuff6Stacks
        end
        --如果有Buff[5]，则基础概率调整为
        if self._buffId == self.enhBuffIdDict[5] then
            magicProb = self.enhBuff5Prob
        end
        --如果有Buff[8]，则基础概率调整为
        if self._buffId == self.enhBuffIdDict[5] then
            magicProb = self.enhBuff8Prob
        end
        --如果有Buff[3]，则概率调整为
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[3]) then
            magicProb = self.enhBuff3MagicProb + magicProb
        end
        --如果有Buff[7]，则概率调整为
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[7]) then
            local stacks = self._proxy:GetBuffStacks(self._uuid, self.enhBuff7SignalId)
            magicProb = self.enhBuff7Prob * stacks + magicProb
        end
        --进行一次Roll，满足概率条件即可获得Buff
        local seed = self._proxy:Random(1, 100)
        --随机数<=预期概率时，触发效果
        if seed <= magicProb then
            for _ = 1, self.magicStacks do
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.attackId, self.magicLevel)
                self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
            end
            self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)
            --进行一次成功触发标记，触发Buff[1]、Buff[4]效果
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.enhBuffSuccessSignal, self.magicLevel, 0, self.magicStacks)
        end
    end
end

function XBuffScript1015934:AfterDamageCalc(eventArgs)
    --将伤害值调整为当前生命值*目标比例
    if eventArgs.Id == self.attackId and eventArgs.Target == self._uuid then
        local attHp = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.Life)
        self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, attHp, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
    end
end

---endregion


function XBuffScript1015934:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015934

