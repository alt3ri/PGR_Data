local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")

---白龙
---@class XRelinkBossBase : XFightBase
local XRelinkBossBase = XClass(Base, "XRelinkBossBase")

XRelinkBossBase.EBattleState =
{
    Inactive = 0,           -- 未激活
    NormalState = 1,        -- 普通状态
    ODState = 2,            -- OD状态
}

--region 函数: 脚本生命周期
function XRelinkBossBase:Init()
    Base.Init(self)

    -- AI总控
    self._isAiActivated = false

    -- 临时仇恨系统
    --- 当前仇恨目标UUID
    self._curAggroTarUUID = nil
    --- 仇恨目标更新频率
    self._aggroUpdateInterval = 0.25
    --- 仇恨目标更新计时器
    self._aggroUpdateTimer = 0
    --- 当前到仇恨目标的距离
    self._curDisToAggroTar = 0

    -- 临时追逐系统
    --- 最短的追逐停止距离
    self._minChaseStopDis = 8
    --- 当前追逐停止距离
    self._curChaseStopDis = 10
    --- 当前追逐目标UUID
    self._curChasingTarUUID = nil
    --- 是否正在追逐
    self._isChasing = false

    -- 战斗
    --- 当前战斗状态
    self._curBattleState = XRelinkBossBase.EBattleState.Inactive

    -- 战斗: 角度和距离修正
    -- TODO: 8001写了个针对不同距离下不同转向条件的系统，后续可以考虑实现那种
    --- 正在修正朝向和距离
    self._isRectifying = false
    --- 修正角度的技能ID
    self._angleRectifySkills = {

    }
    --- 角度修正的区间（180度转特殊处理）
    self._angleRectifyConds ={

    }
    --- 修正距离的技能
    self._disRectifySkills = {

    }
    --- 距离修正技能的修正距离（负数代表向前修正拉近距离，正数代表向后修正拉远距离）
    self._disRectifyConds = {

    }

    --- 最大烦躁值
    self._maxRectifyIrritation = 10
    --- 当前耐心值
    self._curRectifyIrritation = 0
    --- 角度修正的烦躁增长值表
    self._angleRectifyCostTable = {

    }
    --- 距离修正的烦躁增长值表
    self._disRectifyCostTable = {

    }
    --- 烦躁后的技能ID表
    -- 无视除了CD以外的所有技能条件强制释放一个，如果全在CD就随机选一个放
    -- 里面基本放的都是全方位可用的技能，并且强力技能居多
    -- 如果玩家拉修正太多，就会触发这些技能，因为这些技能本来就在轴里，所以会导致一些乱轴（惩罚机制）
    self._irritationSkills = {

    }

    -- 战斗: 普通状态
    --- 存储技能信息，其中 [技能序号] = {CD, 转阶段是否重置CD, 是否允许修正, 距离条件, 角度条件}
    -- 关于修正：因为目前修正只考虑正向释放的攻击性技能，像例如吼叫或者背后攻击，是不会专门修正的
    -- 关于距离条件：格式为 { 最小距离，最大距离 }
    self._skillInfos = {

    }
    --- 技能冷却时间计时器
    self._skillCdTimers = {

    }
    --- 技能并行群组
    -- 每个技能组里存储多个技能，每个里面包含{技能索引, 释放权重}
    -- 【释放权重】 在有多个技能可以释放时，权重决定选择哪个的概率高一些
    self._skillGroup = {

    }
    -- 每个战斗循环里面细分为普通状态技能轴和OD状态技能轴，每个里面存储了技能组释放序列
    --- 期望技能轴，按照顺序执行循环
    self._intendSkillSeqs = {

    }
    --- 战斗循环索引
    self._battleLoopIdx = 1
    --- 当前技能轴
    self._curSkillSeq = nil
    --- 期望技能轴索引
    self._curSeqIdx = 0

    -- 连招系统
    -- 每个对应的【技能Id】会配备一个【连招信息表】，表内每一个元素存储的内容为：
    --            [连招序号] = {前连招序号，连招技能Id，连接时间区间，开始时间，结束时间，连招触发概率(0-1浮点)，连招距离要求，连招角度要求}
    --                      如果前招式序号为0，则表示前招式为起手招
    --- 连招配置表
    self._comboTable = {

    }
    --- 当前技能索引（这个技能索引只有正常放技能会更新，连招不会更新）
    self._curSkillId = 0
    --- 当前连招序号
    self._curComboId = 0
    --self._isUseSkill = false
    --- 技能计时器
    self._skillTimer = 0

    -- 战斗：Break技
    --- 是否在OD Break状态
    self._isODBreak = false
    --- ODBreak技能组（ODBreak基本由3个动作组成，开始，循环，和结束）
    self._odBreakSkillSeq = {

    }
    self._odBreakSkillIdx = 0

    -- 战斗：破韧技能(由于破韧技能一般是小受击，所以这里就假定只有一个动作了)
    --- 破韧技能表（适配多方位破韧受击）
    self._tenacityBreakSkillSeq = {

    }
    -- TODO：这里临时只能取到仇恨目标，所以就用仇恨目标位置当源头来算了，后面再修改）
    --- 破韧不同角度受击动作的触发角度条件
    self._tenacityBreakAngleConds = {

    }

    -- 临时Stats
    --- 上一次血量阈值
    self._prevHpRatio = 1
    --- 当前OD值
    self._curODValue = 0
    --- 最大OD值
    self._maxODValue = 100
    --- OD状态下，OD值自动衰减速度（单位：value/s）
    self._odAutoDropSpeed = 0.74
    --- 是否锁OD条(后续这个用buff搞)
    self._isODLocked = false
    --- 血量伤害半分比 -> OD值增长的转换率
    self._hpPctToODIncreRatio = 5
    --- 血量伤害百分比 -> OD值削减的转换率
    self._hpPctToODDecreRatio = 3
    --- 当前韧性值
    self._curTenacity = 0
    --- 最大韧性值
    self._maxTenacity = 100
    --- 血量伤害半分比 -> 韧性增长的转换率
    self._hpPctToTenaIncreRatio = 18
    --- 韧性自动衰减速度（单位：value/s）
    self._tenaAutoDropSpeed = 5
    --- 是否锁韧性（禁止破韧）
    self._isTenaLocked = false
    --- 是否处于破韧冷却
    self._isTenaBreakCooling = false

    -- 测试用tick（开始运行后，以固定频率调用的测试函数）
    --- 测试用tick更新频率
    self._testTickInterval = 1
    --- 测试用tick计时器
    self._testTickTimer = 0
    -- 测试用delay（开始运行后，固定延迟一定时间后执行一次的函数）
    --- 测试用delay延迟时间
    self._testDelayTime = 5
    --- 测试用delay计时器
    self._testDelayTimer = 0
    --- 测试用delay是否已经触发
    self._hasTestDelayTriggered = false

    -- 调试参, true为开启
    --- 是否调试核心战斗逻辑
    self._isDebugBattleLogic = false
    --- 是否调试修正逻辑
    self._isDebugRectifyLogic = false
    --- 是否调试追逐逻辑
    self._isDebugChasingLogic = false
    --- 是否调试OD值
    self._isDebugODValue = false
    --- 是否调试韧性值
    self._isDebugTenacity = false

    --- 初始化跟随组件
    ---@type XNpcFollowController
    self._followController = XNpcFollowController.New(self._proxy, self._uuid)

    --- 事件绑定
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction)
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
end

---@param dt number @ delta time
function XRelinkBossBase:Update(dt)
    Base.Update(self, dt)
    -- 测试用tick
    self:TestUpdateLogic(dt)

    -- 是否启动AI？
    if not self._isAiActivated then
        return
    end

    -- 固定频率更新仇恨目标
    if self._aggroUpdateTimer >= self._aggroUpdateInterval then
        self:AggroTarUpdateLogic()
        self._aggroUpdateTimer = 0
    end
    self._aggroUpdateTimer = self._aggroUpdateTimer + dt

    -- 是否有目标存在？
    if self._curAggroTarUUID == nil then
        return
    end

    -- 跟随控制器update
    self._followController:Update(dt)

    -- 追逐逻辑
    self:ChasingUpdateLogic()

    -- 战斗核心逻辑
    self:BattleUpdateLogic(dt)
end

---@param eventType number
---@param eventArgs userdata
function XRelinkBossBase:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XRelinkBossBase:Terminate()
    -- 追逐系统注销
    self._followController:Terminate()
    self._followController = nil

    -- 事件解绑
    self._proxy:UnregisterEvent(EWorldEvent.NpcCastActionBefore)
    self._proxy:UnregisterEvent(EWorldEvent.NpcExitAction)
    self._proxy:UnregisterEvent(EWorldEvent.NpcDamage)

    Base.Terminate(self)
end
--endregion

--region 临时仇恨系统逻辑
--- 临时的更新仇恨目标函数，永远以最近的目标为仇恨目标
function XRelinkBossBase:AggroTarUpdateLogic()
    --TODO: 考虑Npc死亡后，仇恨目标不会立即更新的问题，可以用事件绑定的方法来处理
    local targetNpc = self._proxy:GetMaxThreatNpc(self._uuid)
    --设置为仇恨目标
    if self._proxy:CheckNpc(targetNpc) then
        self._curAggroTarUUID = targetNpc
        -- 如果不为空，就更新为fight target
        if self._curAggroTarUUID ~= nil then
            self._curDisToAggroTar = self._proxy:CalcNpcDistance(self._uuid, self._curAggroTarUUID)
            self._proxy:SetFightTarget(self._uuid, self._curAggroTarUUID)
        end
    end
end
--endregion

--region 追逐系统逻辑
function XRelinkBossBase:ChasingUpdateLogic()
    -- 追逐未开始，不执行后续逻辑
    if not self._isChasing then
        return
    end

    -- 追逐停止的条件检测，为了方便debug停止原因，这里分开单独判断
    local isAggroTargetNull = self._curAggroTarUUID == nil
    local isAggroTargetChange = self._curAggroTarUUID ~= self._curChasingTarUUID
    local isInStopDis = self._curDisToAggroTar <= self._curChaseStopDis

    -- 追逐流程停止
    if isAggroTargetNull or isAggroTargetChange or isInStopDis then
        self._followController:CancelFollow()
        self._isChasing = false

        -- 输出log
        if self._isDebugChasingLogic then
            local logInfo = "白龙追逐系统: 追逐停止！停止原因为"
            if isAggroTargetNull then
                logInfo = logInfo .. "[仇恨目标为空]"
            end
            if isAggroTargetChange then
                logInfo = logInfo .. "[仇恨目标变更]"
            end
            if isInStopDis then
                logInfo = logInfo .. "[到达停止距离]"
            end
            XLog.Debug(logInfo)
        end
        return
    end
end

--- 追逐仇恨目标
---@param stopDis number @ 停止追逐距离
function XRelinkBossBase:ChasingAggroTarget(stopDis)
    -- 仇恨目标是否为空
    if self._curAggroTarUUID == nil then
        return
    end

    -- 参数类型和是否为空的验证
    if stopDis == nil or type(stopDis) ~= "number" then
        return
    end

    -- 参数合法性验证以及修正
    if stopDis < self._minChaseStopDis then
        stopDis = self._minChaseStopDis
    end

    -- 如果还在追逐流程，则先停止追逐
    if self._isChasing then
        self._followController:CancelFollow()
        XLog.Debug("白龙追逐系统: 上一个追逐流程未结束，强制停止！")
    end

    -- 开始追击
    self._curChaseStopDis = stopDis;
    self._curChasingTarUUID = self._curAggroTarUUID
    self._isChasing = true;
    self._followController:SetFollowTargetNpcNoNavMesh(self._curChasingTarUUID,  0, self._curChaseStopDis, 0.2)

    if self._isDebugChasingLogic then
        XLog.Debug(string.format("白龙追逐系统: 开始追逐目标，目标UUID[%d]", self._curChasingTarUUID))
    end
end
--endregion

--region 核心战斗逻辑
--- @param dt number @ delta time
function XRelinkBossBase:BattleUpdateLogic(dt)
    -- Inactive状态
    if self._curBattleState == XRelinkBossBase.EBattleState.Inactive then
        return
    end

    -- 循环轴为nil或长度为0则不执行后续逻辑
    if self._intendSkillSeqs == nil or #self._intendSkillSeqs <= 0 then
        return
    end

    -- OD状态下OD值的自然削减
    if self._curBattleState == XRelinkBossBase.EBattleState.ODState then
        self:ModifyODValue(-self._odAutoDropSpeed * dt, false)
    end

    -- 技能CD更新
    --TODO: 加接口
    for id, t in pairs(self._skillCdTimers) do
        self._skillCdTimers[id] = self._skillCdTimers[id] - dt
        --XLog.Debug(string.format("技能[%d]冷却[%f]", id, self._skillCdTimers[id]))
    end

    -- 韧性冷却
    if self._isTenaBreakCooling then
        self:ModifyTenaValue(-self._tenaAutoDropSpeed * dt)
    end

    -- OD Break情况下，播独特的技能序列
    if self._isODBreak then
        if not self._proxy:CheckNpcFullActionState(self._uuid, 3, -1) then
            if self._odBreakSkillIdx > #self._odBreakSkillSeq then
                -- 如果没在放技能，且索引超标，停止Break状态
                self._isODBreak = false
            else
                -- 否则，释放下一技能，更新索引
                self._proxy:CastAction(self._uuid, self._odBreakSkillSeq[self._odBreakSkillIdx])
                self._odBreakSkillIdx = self._odBreakSkillIdx + 1
            end
        end
        return
    end

    -- 技能中的话，阻断后续逻辑，并进行连招检定
    if self._proxy:CheckNpcFullActionState(self._uuid, 3, -1) then
        -- 更新技能时间
        self._skillTimer = self._skillTimer + dt
        self:SelectAndApplyCombo()
        self:CustomInSkillLogic()
        --XLog.Debug("技能中")
        return
    end
    --XLog.Debug("可以放技能")
    -- 转入OD阶段检测（进OD要等正在释放的动作结束才行）
    if self._curBattleState == XRelinkBossBase.EBattleState.NormalState and self._curODValue >= self._maxODValue then
        self:ChangeState(XRelinkBossBase.EBattleState.ODState)
        return
    end

    -- 如果正在追逐，则不执行技能判断
    if self._isChasing then
        return
    end

    -- 如果技能轴为空，则不执行技能判断
    local skillSeqLength = #self._curSkillSeq
    if skillSeqLength <= 0 then
        return
    end

    -- 如果技能轴索引>=长度，则从头开始
    if self._curSeqIdx >= skillSeqLength then
        self._curSeqIdx = 0
    end

    -- 烦躁技能
    if #self._irritationSkills >= 0 and self._curRectifyIrritation >= self._maxRectifyIrritation then
        local validIrritationSkills = {}
        local idx = 1
        for k, skillId in ipairs(self._irritationSkills) do
            local curCdTimer = self._skillCdTimers[skillId]
            if curCdTimer <= 0 then
                validIrritationSkills[idx] = skillId
                idx = idx + 1
            end
        end

        if #validIrritationSkills == 0 then
            validIrritationSkills = self._irritationSkills
        end

        local randomSkillId = self:GetValueByListRandom(validIrritationSkills)

        -- 释放烦躁技能，重置烦躁值
        self:CastRegularSkill(randomSkillId)
        self._curRectifyIrritation = 0

        if self._isDebugRectifyLogic then
            XLog.Debug(string.format("白龙修正逻辑：烦躁值过高，释放烦躁技能[%d]", randomSkillId))
        end
        return
    end



    -- 顺轴选择技能组(索引计算用Clamp保险，防止OutOfIndex)
    local nextSeqIdx = self:Clamp(self._curSeqIdx + 1, 1, skillSeqLength)
    local skillGroupIdx = self._curSkillSeq[nextSeqIdx]

    local validSkillEleKeys, validSkillEleIdx = {}, 1
    local rotRecEleTotalWeight, rotRecEleKeys, rotRecEleIdx = 0, {}, 1
    local posRecEleTotalWeight, posRecEleKeys, posRecEleIdx = 0, {}, 1
    for key, skillGroupEle in ipairs(self._skillGroup[skillGroupIdx]) do
        --XLog.Debug("检测技能组")
        local skillId, skillWeight = skillGroupEle[1], skillGroupEle[2]
        -- CD检测，如果还在冷却就不管了，冷却是硬伤，不能修正
        if self._skillCdTimers[skillId] <= 0 then
            local intendSkillInfo = self._skillInfos[skillId]
            local allowRectify = intendSkillInfo[3]
            local disCond = intendSkillInfo[4]
            local angleCond = intendSkillInfo[5]

            -- 角度检测，是否能释放当前技能(如果长度为0，则说明无视角度条件)
            local isSatisfyAngle = true
            if #angleCond ~= 0 then
                isSatisfyAngle = self:IsTarSatisfyAngleCond(self._curAggroTarUUID, angleCond)
                --XLog.Debug("满足角度条件:" .. tostring(isSatisfyAngle))
            end

            -- 距离检测，是否能释放当前技能(如果长度为0，则说明无视距离条件)
            local isSatisfyDis = true
            if #disCond ~= 0 then
                local curDisToTar = self._proxy:CalcNpcDistance(self._uuid, self._curAggroTarUUID)
                isSatisfyDis = curDisToTar >= disCond[1] and curDisToTar <= disCond[2]
                --XLog.Debug("满足距离条件:" .. tostring(isSatisfyDis))
            end

            if isSatisfyAngle then
                if isSatisfyDis then
                    validSkillEleKeys[validSkillEleIdx] = key
                    validSkillEleIdx = validSkillEleIdx + 1
                else
                    if allowRectify then
                        posRecEleKeys[posRecEleIdx] = key
                        posRecEleIdx = posRecEleIdx + 1
                        posRecEleTotalWeight = posRecEleTotalWeight + skillWeight
                    end
                end
            else
                if allowRectify then
                    rotRecEleKeys[rotRecEleIdx] = key
                    rotRecEleIdx = rotRecEleIdx + 1
                    rotRecEleTotalWeight = rotRecEleTotalWeight + skillWeight
                end
            end
        else
            --XLog.Debug(self._skillCdTimers[skillId])
        end
    end

    -- 获取0-1的随机数，设立公用的权重计数器，权重锚点
    local randomFloat = self._proxy:Random(1, 100) / 100
    local weightSum = 0
    local weightAnchor = 0

    -- 有可以释放的技能
    if #validSkillEleKeys > 0 then
        -- 提取其中优先级最高的列表
        local highPrioritySkillEleKeys = {}
        local curHighestPriority = -99999
        local curHighPrioritySkillEleKeyIdx = 1
        local highPriorityTotalWeight = 0
        for idx, key in ipairs(validSkillEleKeys) do
            local skillGroupEle = self._skillGroup[skillGroupIdx][key]
            if skillGroupEle[3] >= curHighestPriority then
                if skillGroupEle[3] > curHighestPriority then
                    highPrioritySkillEleKeys = {}
                    curHighestPriority = skillGroupEle[3]
                end
                highPrioritySkillEleKeys[curHighPrioritySkillEleKeyIdx] = key
                curHighPrioritySkillEleKeyIdx = curHighPrioritySkillEleKeyIdx + 1
                highPriorityTotalWeight = highPriorityTotalWeight + skillGroupEle[2]
            end
        end

        weightAnchor = randomFloat * highPriorityTotalWeight
        -- 遍历所有可释放技能
        for idx, key in ipairs(highPrioritySkillEleKeys) do
            local skillGroupEle = self._skillGroup[skillGroupIdx][key]
            -- 每次遍历更新权重计数器
            weightSum = weightSum + skillGroupEle[2]
            -- 当权重计数器超过锚点时，说明是目标技能，开始释放
            if weightSum >= weightAnchor then
                local skillId = skillGroupEle[1]

                -- 更新索引，释放技能，更新冷却
                self._curSeqIdx = nextSeqIdx
                --XLog.Debug("更新索引")
                self:CastRegularSkill(skillId)

                if self._isDebugBattleLogic then
                    XLog.Debug(string.format("白龙核心战斗：[普通形态]顺轴释放技能[%d]", skillId))
                end
                -- 跳出循环
                break
            end
        end
        -- 返回，流程结束
        return
    end

    -- 有可以修正角度的技能
    if #rotRecEleKeys > 0 then
        XLog.Debug("可以修正角度")
        -- TODO: 目前由于修正逻辑只针对正向修正，不会根据技能参数而改变修正逻辑，所以这里其实没必要记录哪些技能要修正
        -- TODO: 但如果后面有空做的话就做（比如，向背后甩尾，就会故意调整成背朝玩家），这里先留一个口子出来
        self:TryRectifyRot()
        return
    end
    if #posRecEleKeys > 0 then
        XLog.Debug("可以修正距离")
        -- 类似上面按照权重选技能，这里用权重选一个技能来修正距离
        -- TODO: 后面有空考虑加一个修正优先级的系统，优先挑选一个最容易修正的技能
        weightAnchor = randomFloat * posRecEleTotalWeight
        -- 遍历所有可释放技能
        for i = 1, #posRecEleKeys do
            local skillGroupEle = self._skillGroup[skillGroupIdx][i]
            -- 每次遍历更新权重计数器
            weightSum = weightSum + skillGroupEle[2]

            -- 当权重计数器超过锚点时，说明是目标技能，选择它的参数进行修正
            if weightSum >= weightAnchor then
                local intendSkillInfo = self._skillInfos[skillGroupEle[1]]
                local disCond = intendSkillInfo[4]

                -- 看看是不是距离过近，传参修正
                local curDisToTar = self._proxy:CalcNpcDistance(self._uuid, self._curAggroTarUUID)
                local isTooClose = curDisToTar <= disCond[1]
                self:TryRectifyPos(isTooClose, curDisToTar, disCond[1], disCond[2])
            end
        end
        return
    end

    -- 剩下来的说明在CD里，没救了，啥都不放直接跳过这个技能
    --XLog.Debug(string.format("当前索引[%d], 下一索引[%d], 可放技能[%d], 可修正角度[%d], 可修正距离[%d]", self._curSeqIdx, nextSeqIdx,
    --        #validSkillEleKeys, #rotRecEleKeys, #posRecEleKeys))
    self._curSeqIdx = nextSeqIdx
end

--- 释放常规技能（常规流程释放的技能，破防，破OD，修正，连招等等均不算常规技能）
function XRelinkBossBase:CastRegularSkill(skillId)
    self._proxy:CastActionToTarget(self._uuid, skillId, self._curAggroTarUUID)
    --XLog.Debug("放个技能")
    self._skillCdTimers[skillId] = self._skillInfos[skillId][1]
    -- 刷新连招序号和当前释放的技能索引
    self._curComboId = 0
    self._curSkillId = skillId
end

function XRelinkBossBase:ChangeState(nextState)
    -- 自身状态濒死或死亡，则返回
    if self._proxy:CheckNpcFullActionState(self._uuid, ENpcAction.Dying, -1) and self._proxy:CheckNpcFullActionState(self._uuid, ENpcAction.Death, -1) then
        if self._isDebugBattleLogic then
            XLog.Debug("白龙核心战斗：已处于濒死或死亡状态，无法进入普通状态")
        end
        return
    end

    -- 从OD变回普通时，设立战斗循环索引(如果循环轴为空，则设为0)
    if self._curBattleState == XRelinkBossBase.EBattleState.ODState and nextState == XRelinkBossBase.EBattleState.NormalState then
        local newBattleLoopIdx = self._battleLoopIdx + 1
        if #self._intendSkillSeqs > 0 then
            if newBattleLoopIdx > #self._intendSkillSeqs then
                newBattleLoopIdx = 1
            end
        else
            newBattleLoopIdx = 0
        end
        self._battleLoopIdx = newBattleLoopIdx
    end

    -- 设立状态
    local previousState = self._curBattleState
    self._curBattleState = nextState
    self._curSeqIdx = 0

    -- 设立技能轴
    if self._battleLoopIdx > 0 then
        self._curSkillSeq = self._intendSkillSeqs[self._battleLoopIdx][self._curBattleState]
    end

    -- 如果转到Inactive则强制刷新所有CD，否则正常刷新
    self:RefreshSkillCD(nextState == XRelinkBossBase.EBattleState.Inactive)

    -- 可重写回调
    self:OnStateChanged(previousState, nextState)
end

--- 检测，选择，并释放连招
function XRelinkBossBase:SelectAndApplyCombo()
    -- 检测当前技能是否有连招
    local hasCombo = rawget(self._comboTable, self._curSkillId) ~= nil

    -- 寻找合适的连招
    if hasCombo then
        local comboInfos = self._comboTable[self._curSkillId]
        for i = 1, #comboInfos do
            local info = comboInfos[i]
            local foreComboId = info[1]
            local comboSkillId = info[2]
            local comboInterval = info[3]
            local comboBeginTime = info[4]
            local comboEndTime = info[5]
            local comboPossibility = info[6]
            local comboDisCond = info[7]
            local comboAngleCond = info[8]

            if self._curComboId == foreComboId                  -- 连招序号检定
                    and self._skillTimer >= comboInterval[1]    -- 时间区间检定
                    and self._skillTimer <= comboInterval[2]
            then
                -- 角度检定
                local isAngleSatisfy = true
                if #comboAngleCond ~= 0 then
                    isAngleSatisfy = self:IsTarSatisfyAngleCond(self._curAggroTarUUID, comboAngleCond)
                end

                -- 距离检定
                local isDisSatisfy = true
                if #comboDisCond ~= 0 then
                    local curDisToTar = self._proxy:CalcNpcDistance(self._uuid, self._curAggroTarUUID)
                    isDisSatisfy = curDisToTar >= comboDisCond[1] and curDisToTar <= comboDisCond[2]
                end

                -- 随机数选取
                local randomFloat = self._proxy:Random(1, 100) / 100
                -- XLog.Debug(string.format("随机数检定 - 随机值[%f]，概率[%f]", randomFloat, comboPossibility))

                -- 同时满足，释放连招
                if isAngleSatisfy and isDisSatisfy and randomFloat <= comboPossibility then
                    self._proxy:AbortAction(self._uuid, true)
                    self._proxy:CastActionToTargetEx(self._uuid, comboSkillId, self._curAggroTarUUID, comboBeginTime, comboEndTime)
                    self._curComboId = i
                    break
                end
            end
        end
    end
end

function XRelinkBossBase:CustomInSkillLogic()

end

--- @param forceRefresh @ 无视重置规则，强制重置所有CD
function XRelinkBossBase:RefreshSkillCD(forceRefresh)
    for skillId, info in pairs(self._skillInfos) do
        if forceRefresh or info[2] then
            self._skillCdTimers[skillId] = 0
        end
    end
end

--- 尝试修正角度
function XRelinkBossBase:TryRectifyRot()
    if self._isDebugRectifyLogic then
        XLog.Debug("白龙修正逻辑：开始修正角度！")
    end
    local arSkills = self._angleRectifySkills
    local arRanges = self._angleRectifyConds

    -- 修正技能或者修正范围为空，不允许修正
    if arSkills == nil or arRanges == nil then
        if self._isDebugRectifyLogic then
            XLog.Warning("白龙修正逻辑：角度修正参数有nil存在，修正中止！")
        end
        return
    end

    -- 修正技能或者修正范围任意长度为0，或者两者长度不相等，则不允许修正
    if #arSkills == 0 or #arRanges == 0 or #arSkills ~= #arRanges then
        if self._isDebugRectifyLogic then
            XLog.Warning("白龙修正逻辑：角度修正参数有不合法内容存在，修正中止！")
        end
        return
    end

    -- 遍历所有修正技能，查找一个符合条件的，随后释放
    for i = 1, #self._angleRectifySkills do
        local isSatisfy = self:IsTarSatisfyAngleCond(self._curAggroTarUUID, arRanges[i], false)
        if isSatisfy then
            self._proxy:CastActionToTarget(self._uuid, arSkills[i], self._curAggroTarUUID)

            -- 烦躁值增长
            local cost = self._angleRectifyCostTable[i]
            if cost == nil then cost = 0 end
            self._curRectifyIrritation = self._curRectifyIrritation + cost

            if self._isDebugRectifyLogic then
                XLog.Debug(string.format("白龙修正逻辑：找到合适的修正技能[%q]，烦躁值[%f / %f]",
                        arSkills[i], self._curRectifyIrritation, self._maxRectifyIrritation))
            end
            break
        end
    end
end

--- 尝试修正距离
--- @param isTooClose @ 是否距离过近，false则代表距离过远（调用这个函数，默认有距离问题）
--- @param disMin @ 最小距离
--- @param disMax @ 最大距离
function XRelinkBossBase:TryRectifyPos(isTooClose, curDis, disMin, disMax)
    if self._isDebugRectifyLogic then
        XLog.Debug("白龙修正逻辑：开始修正距离！")
    end

    local drSkills = self._disRectifySkills
    local drLengths = self._disRectifyConds

    --TODO: 距离修正技能
    -- 修正技能或者修正范围为空，不允许修正
    if drSkills == nil or drLengths == nil then
        if self._isDebugRectifyLogic then
            XLog.Warning("白龙修正逻辑：距离修正参数有nil存在，修正中止！")
        end
        return
    end

    -- 修正技能或者修正范围任意长度为0，或者两者长度不相等，则不允许修正
    if #drSkills == 0 or #drLengths == 0 or #drSkills ~= #drLengths then
        if self._isDebugRectifyLogic then
            XLog.Warning("白龙修正逻辑：距离修正参数有不合法内容存在，修正中止！")
        end
        return
    end

    -- 寻找修正长度绝对值最小的修正技能
    local drSkillIdx = -1
    local curMinAbsLength = math.huge
    for i = 1, #drSkills do
        local rectifyPredictDis = curDis + drLengths[i]
        local isPredictDisInRange = rectifyPredictDis >= disMin and rectifyPredictDis <= disMax
        local curAbsLength = math.abs(drLengths[i])
        if isPredictDisInRange and curAbsLength < curMinAbsLength then
            drSkillIdx = i
            curMinAbsLength = curAbsLength
        end
    end

    -- 如果有合适的直接释放
    if drSkillIdx > 0 then
        self._proxy:CastActionToTarget(self._uuid, drSkills[drSkillIdx], self._curAggroTarUUID)

        -- 烦躁值增长
        local cost = self._disRectifyCostTable[drSkillIdx]
        if cost == nil then cost = 0 end
        self._curRectifyIrritation = self._curRectifyIrritation + cost

        if self._isDebugRectifyLogic then
            XLog.Debug(string.format(
                    "白龙修正逻辑: 选择技能[%d]进行修正，修正前距离[%f]，修正长度[%f]，修正后预测距离[%f]，烦躁值[%f / %f]",
                    drSkills[drSkillIdx], curDis, drLengths[drSkillIdx], curDis + drLengths[drSkillIdx],
                    self._curRectifyIrritation, self._maxRectifyIrritation))
        end
        return
    end

    -- 如果没有合适的修正技能，直接走过去，目前只能前走
    if isTooClose then
        -- 距离过近，触发向后走？
    else
        -- 距离过远，走过去！
        -- 追逐停止距离 = 最小距离 +（最大距离 - 最小距离）/ 1.3
        local stopDis = disMin + (disMax - disMin) / 1.3
        -- 开始追逐，停止追逐距离会被自动修正确保距离合法
        self:ChasingAggroTarget(stopDis)
    end
end

--- 尝试破韧（防止一些特殊情况）
function XRelinkBossBase:TryTenaBreak()
    -- 目前如果韧性条，OD条锁住，或者Break状态下，都是不能破韧的
    -- TODO: Break下如果破韧会导致Break动作被吞，如果刻意不吞的话也行，但那样就没有破韧表现，后续再优化
    if self._isTenaLocked or self._isODLocked or self._isODBreak then
        return
    end

    self:PlayTenaBreakSkillBySrcPos(self._curAggroTarUUID)
    self._isTenaBreakCooling = true
    -- 破韧持续时间，临时用buff做
    self._proxy:ApplyMagic(self._uuid, self._uuid, 8005901, 1)
    -- 传递可放破韧技的通知(暂时给所有人上)
    local players = self._proxy:GetPlayerNpcList()
    for k, playerID in ipairs(players) do
        self._proxy:ApplyMagic(self._uuid, playerID, 8005902, 1)
    end
    if self._isDebugBattleLogic then
        XLog.Debug("白龙核心战斗：触发破韧技！")
    end
end

--- 根据伤害来源角色位置，播放对应的破韧动作
function XRelinkBossBase:PlayTenaBreakSkillBySrcPos(srcId)
    -- 异常情况排除，nil和空table的情况
    if self._tenacityBreakSkillSeq == nil or
            #self._tenacityBreakSkillSeq <= 0 or
            self._tenacityBreakAngleConds == nil or
            #self._tenacityBreakAngleConds <= 0 then
        return
    end

    -- 来源不存在
    if not self._proxy:CheckNpc(srcId) then return end

    -- 默认用第一个
    local resultSkillIdx = self._tenacityBreakSkillSeq[1]

    -- 根据角度细化选择破韧技，选不到就用默认的
    if #self._tenacityBreakSkillSeq == #self._tenacityBreakAngleConds then
        for i = 1, #self._tenacityBreakSkillSeq do
            if self:IsTarSatisfyAngleCond(srcId, self._tenacityBreakAngleConds[i]) then
                resultSkillIdx = self._tenacityBreakSkillSeq[i]
            end
        end
    end

    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastAction(self._uuid, resultSkillIdx)
end
--endregion

--region 临时Stats系统的一些函数
--- 将伤害百分比转化为OD值增长或者削减
function XRelinkBossBase:TransHPDmgToODDmg(hpDmgPct)
    -- 如果在常规状态，则攻击增长OD值
    local odValChange = 0
    if self._curBattleState == XRelinkBossBase.EBattleState.NormalState then
        odValChange = hpDmgPct * self._hpPctToODIncreRatio * self._maxODValue
    elseif self._curBattleState == XRelinkBossBase.EBattleState.ODState then
        odValChange = hpDmgPct * self._hpPctToODDecreRatio * -self._maxODValue
    end

    if odValChange ~= 0 then
        self:ModifyODValue(odValChange, true)
    end
end

--- 修改OD值
--- @param amount number @ 需要改动的量，正负皆可
--- @param isModifiedByDmg boolean @ 是否为伤害修改（例如，OD值自然削减是不会触发Break的）
function XRelinkBossBase:ModifyODValue(amount, isModifiedByDmg)
    local oldValue = self._curODValue
    self._curODValue = self:Clamp(self._curODValue + amount, 0, self._maxODValue)

    if self._isDebugODValue then
        XLog.Debug(string.format("白龙数值：OD值变动，原本值[%f]，变动值[%f]，最终值[%f]", oldValue, amount, self._curODValue))
    end

    -- Break触发（只有来自于伤害的变动才可以触发，自然削减不算）
    if isModifiedByDmg then
        if self._curBattleState == XRelinkBossBase.EBattleState.ODState and (not self._isODLocked) and self._curODValue <= 0 then
            self._proxy:AbortAction(self._uuid, true)

            self._isODBreak = true
            self._odBreakSkillIdx = 1
            if self._isDebugBattleLogic then
                XLog.Debug("白龙核心战斗：OD Break！")
            end
            self:ChangeState(XRelinkBossBase.EBattleState.NormalState)

            -- 回调
            self:OnODBreak()
        end
    end
end

--- 将伤害百分比转化为韧性削减
function XRelinkBossBase:TransHPDmgToTenaDmg(hpDmgPct)
    -- 如果在破韧冷却，则不允许造成韧性伤害
    if self._isTenaBreakCooling then
        return
    end

    local tenaValChange = hpDmgPct * self._hpPctToTenaIncreRatio * self._maxTenacity
    if tenaValChange ~= 0 then
        self:ModifyTenaValue(tenaValChange)
    end
end

--- 修改韧性值
function XRelinkBossBase:ModifyTenaValue(amount)
    local oldValue = self._curTenacity
    self._curTenacity = self:Clamp(self._curTenacity + amount, 0, self._maxTenacity)

    if self._isDebugTenacity then
        XLog.Debug(string.format("白龙数值：韧性变动，原本值[%f]，变动值[%f]，最终值[%f]", oldValue, amount, self._curTenacity))
    end

    --- 区分是否在冷却
    if self._isTenaBreakCooling then
        if self._curTenacity <= 0 then
            self._isTenaBreakCooling = false
        end
    else
        if self._curTenacity >= self._maxTenacity then
            self:TryTenaBreak()
        end
    end
end
--endregion

--region protected可重写函数
--- OD条Break回调
function XRelinkBossBase:OnODBreak()

end

function XRelinkBossBase:OnStateChanged(previousState, newState)

end
--endregion

--region 事件回调
function XRelinkBossBase:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastActionAfterEvent(self, skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then return end

    self._skillTimer = 0
end

function XRelinkBossBase:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcExitActionEvent(self, skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then return end

    self._skillTimer = 0
end

function XRelinkBossBase:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    Base.OnNpcDamageEvent(self, launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if targetId ~= self._uuid then return end

    local curHealth = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    local maxHealth = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    local hpRatio = curHealth / maxHealth
    local damageRatio = self._prevHpRatio - hpRatio
    self._prevHpRatio = hpRatio
    --XLog.Debug(string.format("当前生命百分比[%f]", hpRatio))

    self:TransHPDmgToTenaDmg(damageRatio)
    self:TransHPDmgToODDmg(damageRatio)
end
--endregion

--region 测试逻辑
--- 测试逻辑的更新函数
--- @param dt number @ delta time
function XRelinkBossBase:TestUpdateLogic(dt)
    if self._testTickTimer >= self._testTickInterval then
        -- 具体测试逻辑
        self:TestTickLogic()
        self._testTickTimer = 0
    end
    self._testTickTimer = self._testTickTimer + dt

    -- 测试用delay
    if not self._hasTestDelayTriggered then
        if self._testDelayTimer >= self._testDelayTime then
            self:TestDelayLogic()
            self._hasTestDelayTriggered = true
        end
        self._testDelayTimer = self._testDelayTimer + dt
    end

end

---开始运行后，以固定频率调用的测试函数
function XRelinkBossBase:TestTickLogic()
    -- 模拟扣血，扣OD值，扣韧性值

    -- 假设dps为0.000555%血量每秒
    --local hpDmgPct = self._proxy:Random(50, 60) * 0.0001
    --self:TransHPDmgToTenaDmg(hpDmgPct)
    --self:TransHPDmgToODDmg(hpDmgPct)
end

---开始运行后，固定延迟一定时间后执行一次的函数
function XRelinkBossBase:TestDelayLogic()
    -- 延迟几秒后开始战斗
    self:ChangeState(XRelinkBossBase.EBattleState.NormalState)
end
--endregion

--region 工具函数
--- 目标与自身夹角是否满足角度条件table（[角度条件table]为一个数组，其中每一个[角度条件]的结构为{[起始角度from]，[到达角度to]}的区间）
--- @param targetUUID number @目标UUID
--- @param angleCond @角度条件table
--- @return boolean @是否满足角度条件
function XRelinkBossBase:IsTarSatisfyAngleCond(targetUUID, angleCond)
    -- 如果条件为空则直接满足
    if #angleCond == 0 then
        return true
    end

    local isSatisfy = false
    -- 便利所有条件，只要满足任意一个角度条件就算成功
    for k, angleSet in ipairs(angleCond) do
        if #angleSet >= 2 then
            local from = angleSet[1]
            local to = angleSet[2]
            isSatisfy = isSatisfy or self:CheckTargetInAngle(targetUUID, from, to)
        end

        -- 满足条件直接跳出
        if isSatisfy then
            break
        end
    end

    return isSatisfy
end
--endregion

--region 数学
--- 将val的值限制在min和max之间，随后返回
--- @param val number @ 需要限制的值
--- @param min number @ 区间最小值
--- @param max number @ 区间最大值
--- @return number @ 限制后的值
function XRelinkBossBase:Clamp(val, min, max)
    -- 任意参数不为数字类型，则直接返回原值
    if type(val) ~= "number" or type(min) ~= "number" or type(max) ~= "number" then
        return val
    end

    -- min 如果大于 max，则直接返回原值
    if min > max then
        return val
    end

    -- 限制值后返回
    if val < min then
        return min
    elseif val > max then
        return max
    else
        return val
    end
end

--- 计算目标是否在角度区间内（判断背后扇形时拆开判断，例如背后60度夹角，则调用两次，第一次-180 -150, 第二次150 180）
--- @param targetUUID @ 目标UUID
--- @param from number @ 最小值，合法参数区间[-180, 180]
--- @param to number @ 最大值，合法参数区间[-180, 180]
function XRelinkBossBase:CheckTargetInAngle(targetUUID, from, to)
    -- 角度参数合法性检测
    if from > to then
        return false
    end
    if math.abs(from) > 180 or math.abs(to) > 180 then
        return false
    end

    -- 如果差大于360度，则直接返回true
    if (to - from) >= 360 then
        return true
    end

    -- 对于from小于0，to大于0的进行区间拆分
    local angleList
    if from < 0 and to > 0 then
        angleList = {{from, 0}, {0, to}}
    else
        angleList = {{from, to}}
    end

    -- 获取自身位置和目标位置
    local targetPosVec3 = self._proxy:GetNpcPosition(targetUUID)
    local sourcePosVec3 = self._proxy:GetNpcPosition(self._uuid)
    local targetPos = { targetPosVec3.x, targetPosVec3.z }
    local sourcePos = { sourcePosVec3.x, sourcePosVec3.z }

    -- 计算前方和右方的方向向量，以及指向目标的方向向量
    local forwardDir = self:NormVec2(self:RotateVector2({0, 1}, self._proxy:GetNpcRotation(self._uuid).y))
    local rightDir = self:NormVec2(self:RotateVector2(forwardDir, 90))
    local targetDir = self:NormVec2(self:Vec2Minus(targetPos, sourcePos))

    -- 检测左右
    local isIn = false
    for k, v in ipairs(angleList) do
        -- 点乘
        local forwardDot = self:Vec2Dot(forwardDir, targetDir)
        local rightDot = self:Vec2Dot(rightDir, targetDir)
        --XLog.Debug(string.format("是否在右侧: [%q]", rightDot > 0))

        -- 检测是否满足左右条件
        if (v[2] <= 0 and rightDot <= 0) or (v[1] >= 0 and rightDot >= 0) then
            local absAngleMin = math.abs(v[1])
            local absAngleMax = math.abs(v[2])

            -- 如果为左侧的话，负数绝对值对调
            if v[2] <= 0 then
                absAngleMin, absAngleMax = absAngleMax, absAngleMin
            end

            -- 判断夹角是否在区间内
            local angleBtw = math.deg(math.acos(forwardDot))
            if angleBtw >= absAngleMin and angleBtw <= absAngleMax then
                isIn = true
                break
            end
        end
    end

    return isIn
end

--- 旋转一个二维向量（这里用于计算XZ平面的旋转，即Y轴旋转）
--- @param vec2 @ 二维向量table
--- @param deg @ 旋转角度
--- @return @ 旋转后的向量
function XRelinkBossBase:RotateVector2(vec2, deg)
    -- 构建旋转矩阵
    -- unity为顺时针旋转，这里角度取反
    local radian = math.rad(-deg)
    local cos = math.cos(radian)
    local sin = math.sin(radian)

    -- z = forward backward纵轴，x = left right横轴
    local x = vec2[1]
    local z = vec2[2]

    -- 应用旋转矩阵
    local rotatedX = x * cos - z * sin
    local rotatedZ = x * sin + z * cos

    return {rotatedX, rotatedZ}
end

--- 二维向量取模（长度）
function XRelinkBossBase:Vec2Magnitude(vec2)
    return math.sqrt(vec2[1]^2 + vec2[2]^2)
end

--- 二维向量归一化
function XRelinkBossBase:NormVec2(vec2)
    local mag = self:Vec2Magnitude(vec2)
    return { vec2[1] / mag, vec2[2] / mag }
end

--- 二维向量点乘
function XRelinkBossBase:Vec2Dot(vec2a, vec2b)
    return vec2a[1] * vec2b[1] + vec2a[2] * vec2b[2]
end

--- 二维向量减法（算朝向向量用）
function XRelinkBossBase:Vec2Minus(vec2a, vec2b)
    return { vec2a[1] - vec2b[1], vec2a[2] - vec2b[2] }
end
--endregion

return XRelinkBossBase