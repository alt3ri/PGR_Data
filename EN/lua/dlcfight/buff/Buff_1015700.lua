local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015700 : XBuffBase
local XBuffScript1015700 = XDlcScriptManager.RegBuffScript(1015700, "XBuffScript1015700", Base)

--效果说明：每次获得【概率】标记时，有概率触发符纹效果
local ConfigMagicIdDict = {
    [1015700] = 1015701,
    [1015702] = 1015703,
    [1015704] = 1015705,
    [1015706] = 1015707,
    [1015708] = 1015709,
    [1015710] = 1015711,
    [1015712] = 1015713,
    [1015714] = 1015715,
    [1015716] = 1015717,
    [1015718] = 1015719,
    [1015720] = 1015721,
    [1015722] = 1015723,
    [1015724] = 1015725,
    [1015726] = 1015727,
    [1015728] = 1015729,
    [1015730] = 1015731,
    [1015732] = 1015733,
    [1015734] = 1015735,
    [1015736] = 1015737,
    [1015738] = 1015739,
    [1015940] = 1015941, --每间隔5秒，定时符纹的间隔有20%概率缩短0.5秒（最短缩短至2秒）
    [1015948] = 1015949, --每间隔5秒，疲劳阶段的时间有20%概率提前2秒
    --强化效果部分
    [1016184] = 1016185,
    [1016186] = 1016187,
    [1016188] = 1016189,
    [1016190] = 1016191,
    [1016192] = 1016193,

}
local ConfigRuneIdDict = {
    [1015700] = 20700,
    [1015702] = 20702,
    [1015704] = 20704,
    [1015706] = 20706,
    [1015708] = 20708,
    [1015710] = 20710,
    [1015712] = 20712,
    [1015714] = 20714,
    [1015716] = 20716,
    [1015718] = 20718,
    [1015720] = 20720,
    [1015722] = 20722,
    [1015724] = 20724,
    [1015726] = 20726,
    [1015728] = 20728,
    [1015730] = 20730,
    [1015732] = 20732,
    [1015734] = 20734,
    [1015736] = 20736,
    [1015738] = 20738,
    [1015940] = 20940,
    [1015948] = 20948,
    --强化效果部分
    [1016184] = 20706,
    [1016186] = 20714,
    [1016188] = 20722,
    [1016190] = 20730,
    [1016192] = 20738,
}

function XBuffScript1015700:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]          --属性提升Buff
    self.runeId = ConfigRuneIdDict[self._buffId]            --符纹ID赋值
    self.magicLevel = 1 --初始buff等级1级
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.signalId = 1015913         --【概率】状态标记，标记管理脚本见1015910
    self.signalCtrlId = 1015912     --【概率】状态管理Buff
    self.magicStacks = 1            --【概率】触发时，添加的Buff层数
    self.magicProb = 40             --【概率】符纹触发概率
    self.maxStacks = 4
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
    self.enhBuff2maxStacks = 8      --最大层数翻倍

    --增强Buff[3]配置
    self.enhBuff3MagicProb = 10     --有Buff[3]时，触发概率提升10%

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

    --1016355 - 饰品61161~61165 - 触发次数统计相关
    self.buffLevelGroupId= {1016355, 1016356, 1016357, 1016358, 1016359}  --5个等级
    self.currentBuffLevelGroupId = 0
    self.signalAwakeForMission = 1016416 -- 定时、概率触发传递标记buff

    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalCtrlId, 1)   --为自己添加【定时】管理Buff

end

---@param dt number @ delta time
function XBuffScript1015700:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

end

--region EventCallBack
function XBuffScript1015700:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)         -- OnNpcCastSkillEvent
end

function XBuffScript1015700:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局处理
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        if self._proxy:CheckBuffByKind(self._uuid,self.enhBuffIdDict[6]) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.enhBuff6signalCtrlId, 1)   --为自己添加【背水】管理Buff
        end
        if self._proxy:CheckBuffByKind(self._uuid, self.enhBuffIdDict[2]) then
            self.maxStacks = self.enhBuff2maxStacks
        end

        --记录是否挂任务奖励buff
        for _, buffGroupThisLevel in ipairs(self.buffLevelGroupId) do
            if self._proxy:CheckBuffByKind(self._uuid, buffGroupThisLevel) then
                self.currentBuffLevelGroupId = buffGroupThisLevel
            end
        end

    end

    --达到层数上限时，不进行后续逻辑
    if self._proxy:GetBuffStacks(self._uuid,self.magicId) >= self.maxStacks then
        return
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
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel, 0, magicStacks)
            self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
            --进行一次成功触发标记，触发Buff[1]效果
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.enhBuffSuccessSignal, self.magicLevel, 0, magicStacks)

            --有挂任务奖励buff，则传递1次触发标记buff
            if self.currentBuffLevelGroupId ~= 0 then
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.signalAwakeForMission, 1)
            end

        end
    end
end

---endregion


function XBuffScript1015700:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015700

