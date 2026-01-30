local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
---Dlc的伙伴基类
---@class XDlcPartnerBase : XFightBase
local XDlcPartnerBase = XClass(Base, "XDlcPartnerBase")
local SkillConfigs = require("TempSkillConfigs/SkillConfig_8052")--配置：临时技能
local PartnerConfigs = require("PartnerConfigs/PartnerConfigs")--配置：伙伴
local EGameplayTag = require("Enum/XGameplayTag") --Tag系统
local GameplayTag = require("Tools/GameplayTag/GameplayTag")--Tag系统

--region 脚本枚举
---战斗状态
XDlcPartnerBase.CombatState = { 
    None = 0,---啥也不干
}
---和平状态
XDlcPartnerBase.PeaceState = { --无、非战斗、战斗、目标丢失
    None = 0,---啥也不干
}
---行为筛选和执行时的类型
XDlcPartnerBase.ActionType = {--待机、追逐移动、攻击、游荡、巡逻、连招
    ---无行为类型
    None = 0, --什么都不干
    NormalAttack = 1,--对目标：普攻
    Chase = 2,  --对目标：追击
    SkillAction = 3, --对目标：技能攻击
    Follow = 4, --对Master：跟随
}
---行为筛选和执行时的类型
XDlcPartnerBase.FollowStateType = {--跟随Master的状态
    None = 0, --什么都不干
    Wait = 1 , --原地等待
    Moving = 2 , --移动跟随中
}
---战斗逻辑情况下按照什么类型选择技能
XDlcPartnerBase.SelectSkillType = {--根据什么规则去释放技能。
    ---不释放技能
    None = 0,
    ---从技能释放组里按顺序判断可放技能{id1,id2,id3}
    NormalSequence = 1, --NormalList里按从前到后筛选一个可释放技能。(未实现)
    ---从技能释放组里随机放可放技能{id1,id2,id3}
    RandomSequence = 2, --NormalList里按照权重随机一个技能。（已支持）
    ---技能释放组
    CastGroup = 3, 
}
---技能测试类型
XDlcPartnerBase.SkillTestType = {
    None = 0,--无
    ToTarget = 1, --对目标
    CustomFuc =2,--自定义函数
}
--endregion

--region 函数: 脚本生命周期

---初始化
function XDlcPartnerBase:Init()
    Base.Init(self)
    self:PartnerRunVarAwake() --伙伴运行变量初始创建
    self:PartnerScriptConfigBeforeReadConfig()--伙伴在读配置表前配置（空）
    self:PartnerReadConfig() --伙伴读配置表赋值
    self:PartnerInit()--伙伴的初始化
    self:PartnerRunInit() --伙伴运行初始化（空）根据配置有特殊调整逻辑时启用。
end

---帧更新
---@param dt number @ delta time 
function XDlcPartnerBase:Update(dt)
    Base.Update(self, dt)
    if dt == 0 then
        return
    end --暂停的时候AI不跑
    self:UpdateAIBefore(dt)--AI执行前,与决策无关的
    if not self.isAiOpen then--AI是否关闭
        --AI总开关
        return
    end
    self:UpdatePartnerAi(dt) --Tick执行伙伴AI，与决策有关的
end

---伙伴在读配置表前配置
function XDlcPartnerBase:PartnerScriptConfigBeforeReadConfig()
end

---脚本配置入口
function XDlcPartnerBase:PartnerInit()
end

--endregion

--region 伙伴流程-Awake

---伙伴运行变量初始创建
function XDlcPartnerBase:PartnerRunVarAwake()
    self.skillConfigs = SkillConfigs --获取技能配置
    self.partnerConfigs = PartnerConfigs --获取伙伴配置
    self:PartnerAiControlAwake() --AI控制
    self:PartnerInfoAwake() --伙伴信息
    --self:PartnerMasterAwake() --主人初始化:教学暂时不用
    self:PartnerTargetAwake() --目标
    self:PartnerFollowComponentAwake() --跟随组件初始化变量
    self:PartnerSkillTestAwake() --技能测试变量初始化
end

---自己信息相关变量激活
function XDlcPartnerBase:PartnerInfoAwake()
    self.partnerId = nil --伙伴Id，用来读配置表的
    self.normalAttackList = {} --普攻列表
    
    self.partnerConfig = nil
    self.normalAttackIndex = 1 --普攻序号
    self.hpRate = 1           --自己生命百分比
    self.Pos = nil       --自己的位置
    self.fightTime = self._proxy:GetFightTime() --当前战斗时间
    self.npcTime = self._proxy:GetNpcTime(self._uuid) --当前Npc时间
    self.levelCenterPoint = self._proxy:GetSpot(2) --获取场景中心点
    self.npcTimerList={}
    self.isCombatState = false --是否战斗状态
    self.lastActionType = XDlcPartnerBase.ActionType.None --上次执行的Action类型
    self.partnerSelectActionType = XDlcPartnerBase.ActionType.None --筛选的类型
    self:ClearPartnerSelectActionData()
    self.SkillCds = {}
    self.skillLockedList={}
    ------- 警戒范围和敌人相关 --------------------------------
    self.vigilantRange = 0 --警戒范围。
    self.vigilantRangeEnemyList = {} --警戒范围内的敌人列表
    self.vigilantRangeEnemyListUpdateTimeOnCombatState = 5 --战斗模式下更新敌人列表频率
    self.vigilantRangeEnemyListUpdateTimer = self.fightTime --更新敌人列表的计时器
end

---Master变量激活
function XDlcPartnerBase:PartnerMasterAwake()
    local PlayerList = self._proxy:GetPlayerNpcList()
    self.master = nil --主人UUID
    if #PlayerList>0 then
        self.master = PlayerList[1]
    end
    ----基础的跟随配置捏-----
    self.followState = XDlcPartnerBase.FollowStateType.Wait
    self.StartFollowDistance = 5 --开始跟随距离
    self.StopFollowDistance = 3 --停止跟随距离
    
    self.masterPos = nil   --主人当前位置
    self.masterDistance =0 --与主人距离

    self.followPos = nil --跟随的位置
end

---目标变量激活
function XDlcPartnerBase:PartnerTargetAwake()
    self.target = nil               --战斗目标，会在战斗模式下更新
    self.targetHpPercent = 0            --目标血量百分比
    self.targetPos = nil     --目标当前坐标位置
    self.targetDistance = 0               --和目标距离
end

---整个AI控制变量激活
function XDlcPartnerBase:PartnerAiControlAwake()
    self.isAiOpen = true --总AI开关
    self.isCombatStateAiOpen = true  --是否调用战斗State逻辑
    self.isCombatLogicAiOpen = true --是否调用战斗逻辑
    self.isCombatLogicMainOpen = true --Main逻辑是否跑
end

---跟随组件变量激活
function XDlcPartnerBase:PartnerFollowComponentAwake()
    -----移动组件--------------------------
    ---@type XNpcFollowController
    self.followTargetMinDis = 3
    self.followTargetMaxDis = 5
    self.followTargetHeartBeat = 1
    self._followController = XNpcFollowController.New(self._proxy, self._uuid) --New跟随组件
end

---技能测试变量激活
function XDlcPartnerBase:PartnerSkillTestAwake()
    self.isSkillTestOpen = false --技能测试开关，开了后会运行调试模式
    self.skillTestId = nil --测试的技能ID
    self.skillTestCd = 5 --测试技能CD，CD进入方式都是从上一个技能释放成功开始
    self.skillTestInitialCd = 2 --测试技能初始CD
    self.skillTestType = self.SkillTestType.ToTarget
end

--endregion

--region 伙伴流程-Init

---伙伴初始化流程
function XDlcPartnerBase:PartnerRunInit()
end

---伙伴读配置
function XDlcPartnerBase:PartnerReadConfig()
    if not self.partnerId then
        --XLog.Warning("伙伴初始化失败，请给一个ID")
        return
    end
    self.partnerConfig = PartnerConfigs[self.partnerId]
    local config = self.partnerConfig
    if not self.partnerId then
        --XLog.Warning("没有读到对应的伙伴配置ID，伙伴配置ID是:")
        --XLog.Warning(self.partnerId)
        return
    end
    
    self.normalAttackList = config.NormalAttackList --普攻列表
    self.vigilantRange = config.VigilantRange --警戒范围
    self:SetAiActive(not config.IsAiDefaultUnEnabled) --是否默认关闭AI，如果需要的话开启后自动关闭AI
    
end

---伙伴初始化
function XDlcPartnerBase:PartnerAiReadConfig()
    if not self.partnerConfig then
        return
    end
    if self.partnerConfig.IsAiDefaultUnEnabled then --如果要默认要关闭AI
        self:SetAiActive(false) --那就关闭AI
    end
end


--endregion

--region 战斗流程

---战斗模块主流程,负责分发所有战斗流程.
function XDlcPartnerBase:UpdateCombatLogic(dt)
    if not self.isCombatStateAiOpen then --战斗模块
        return
    end

    --1：战斗前置逻辑，当前已有目标，但行为是不确定的
    self:CombatLogicTargetLocked(dt)

    
    if not self:CheckSelfActionValid() then --行动合法性
        --行为有效性检查
        return
    end--行动有效性判断
    
    --2:应对怪物机制
    self:HandleMonsterGamePlay() --应对怪物玩法

    if not self:CheckSelfActionValid() then --行动合法性
        --行为有效性检查
        return
    end--行动有效性判断

    --3：自定义战斗逻辑
    self:PartnerCombatLogicCustom(dt)
    if not self.isCombatLogicMainOpen then
        return
    end

    if not self:CheckSelfActionValid() then --行动合法性
        --行为有效性检查
        return
    end--行动有效性判断
    
    --4:伙伴底层运行逻辑.
    self:PartnerCombatLogicMain(dt) --伙伴核心逻辑

end

---1：战斗逻辑执行前，不包括任何状态或条件检测，默认空逻辑
function XDlcPartnerBase:CombatLogicBefore(dt)
end

---2：战斗流程：前置战斗逻辑（已有目标）
function XDlcPartnerBase:CombatLogicTargetLocked(dt)

end

---3：战斗流程：优先战斗逻辑
function XDlcPartnerBase:CombatLogicPriority(dt)
    self:CombatModeTryCastOverDriveSpecialSkill()--尝试释放OD机制技能
    self:CombatModeTryEnterOverDrive()--尝试进入OD
end

---4：战斗流程：自定义战斗逻辑
function XDlcPartnerBase:PartnerCombatLogicCustom(dt)
end

---5：战斗流程：核心底层运行的核心战斗逻辑
function XDlcPartnerBase:PartnerCombatLogicMain(dt)
    self:PartnerSelectAction() --伙伴行为筛选，处理好要做的事情。
    self:PartnerDoAction(dt) --伙伴行为执行，根据行为筛选出来的事情去执行，用来处理执行前和执行后的逻辑。
end

---处理机制部分
function XDlcPartnerBase:HandleMonsterGamePlay()
    
end
--endregion

--region 战斗模式

---检查自己是不是通常意义上的可行动
function XDlcPartnerBase:CheckSelfActionValid()
    
    if self._proxy:CheckNpcAction(self._uuid, ENpcAction.Skill) then--正在释放技能
        if not self._proxy:CheckNpcCurActionIsDone(self._uuid) then  --自己技能没有完成时，无效。
            return false
        end
    end

    if self._proxy:CheckNpcAction(self._uuid, ENpcAction.BeHit) then--受击中无效
        return false
    end

    if self._proxy:CheckNpcAction(self._uuid, ENpcAction.Death) or self._proxy:CheckNpcAction(self._uuid, ENpcAction.Dying) then---濒死或死亡：无效
        return false
    end

    if not self._proxy:CheckCanCastSkill(self._uuid) then--当前不可释放技能，无效
        return false
    end

    if not self._proxy:CheckCanCastSkill(self._uuid) then--当前不可释放技能，无效
        return false
    end

    if self._proxy:CheckNpcFullActionState(self._uuid,ENpcAction.Born) then --出生时也不算
        return false
    end
    
    return true--以上无效判断都不通过时，
end

---TickPeaceStateLogic
function XDlcPartnerBase:UpdatePeaceStateLogic(dt)
    --self:FollowMaster(dt) --跟随主人，暂时不用
    return --非战斗下现在啥也不干
end

---永远跟随主人
function XDlcPartnerBase:FollowMaster(dt)
    if self.followState == XDlcPartnerBase.FollowStateType.Wait then --等待的时候
        if self.masterDistance >= self.StartFollowDistance then
            self._followController:SetFollowTargetNpcNoNavMesh(self.master, self.followTargetMinDis, self.followTargetMaxDis, self.followTargetHeartBeat)
            self.followState = XDlcPartnerBase.FollowStateType.Moving
        end
    elseif self.followState == XDlcPartnerBase.FollowStateType.Moving then
        if self.masterDistance <= self.StopFollowDistance then
            self.followState = XDlcPartnerBase.FollowStateType.Wait
        end
        self._followController:Update(dt)  --调用跟随组件走向目标
    end
    return --非战斗下现在啥也不干
end

---GamePlay逻辑
function XDlcPartnerBase:UpdateGamePlayLogic(dt)
    self:UpdatePhaseSystem(dt) --阶段管理系统，Update检测自己是否要转阶段了
end

---更新自己相关的基础信息
function XDlcPartnerBase:UpdateSelfBaseInfo()
    ---生命百分比
    local maxHp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    local curHp = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    self.hpRate = curHp / maxHp--生命百分比

    self.fightTime = self._proxy:GetFightTime() --更新战斗时间
    self.npcTime = self._proxy:GetNpcTime(self._uuid) --更新Npc时间
    self.Pos = self._proxy:GetNpcPosition(self._uuid) --更新自己位置
    self:UpdateVigilantRangeEnemyList() --更新警戒范围内敌人列表
end

---更新Master信息
function XDlcPartnerBase:UpdateMasterInfo()
    if not self.master then
        return
    end

    self.targetHpPercent = self._proxy:GetNpcAttribRate(self.master, ENpcAttrib.Life)
    self.masterPos = self._proxy:GetNpcPosition(self.master) --Master位置
    self.masterDistance = self._proxy:CalcNpcDistance(self._uuid, self.master) ----Master距离
    
end

---更新警戒范围内敌人列表
function XDlcPartnerBase:UpdateVigilantRangeEnemyList()
    if not self.isCombatState then --非战斗状态下Tick更新范围内的敌人
        self.vigilantRangeEnemyList = {}--清空周围敌人列表
        self.vigilantRangeEnemyList = self:GetEnemyListInRange(self.vigilantRange)--寻找警戒范围内的敌人
        return
    end
    if self.fightTime < self.vigilantRangeEnemyListUpdateTimer then --战斗状态下按照CD更新范围内敌人
        self.vigilantRangeEnemyList = {}--清空周围敌人列表
        self.vigilantRangeEnemyList = self:GetEnemyListInRange(self.vigilantRange)--寻找警戒范围内的敌人
        self.vigilantRangeEnemyListUpdateTimer = self.fightTime + self.vigilantRangeEnemyListUpdateTimeOnCombatState --战斗时更新警戒范围敌人列表的CD
    end
    --搜索周围敌人列表
end

---在范围内获取随机的敌人
function XDlcPartnerBase:GetRandomPlayerInRange(near,far)
    local npcList = self._proxy:GetPlayerNpcList()
    local tempNpcList = {}
    local player = nil
    for i, npc in pairs(npcList) do
        local distance = self._proxy:CalcNpcDistance(self._uuid, npc) --计算和目标的距离
        if distance>=near and distance<=far then --在范围内的敌人
            table.insert(tempNpcList, npc) --插入Npc
        end
    end
    if #tempNpcList>0 then --随机返回一个
        player = tempNpcList[self._proxy:Random(1,#tempNpcList)]
    end
    return player
end

---获取范围内的玩家列表
function XDlcPartnerBase:GetEnemyListInRange(range)
    local npcList = self._proxy:GetNpcList()
    local tempNpcList = {}
    for i, npc in pairs(npcList) do
        local distance = self._proxy:CalcNpcDistance(self._uuid, npc) --计算和目标的距离
        if (distance < range) and (self:CheckNpcIsEnemy(npc)) and self:CheckNpcValid(npc) then --在范围内并且是敌人
            table.insert(tempNpcList, npc) --插入Npc
        end
    end
    return tempNpcList
end

function XDlcPartnerBase:CheckNpcIsEnemy(npc) 
    return not self._proxy:CompareNpcCamp(self._uuid,npc) --不同阵营表示
end


---战斗逻辑选择目标。根据仇恨选择目标（包括强仇和仇恨值）
function XDlcPartnerBase:CombatLogicSelectTarget(dt)
    local target = self:CombatLogicCustomSelectTarget()--自定义返回目标
    if target then --有自定义的目标优先用自定义的目标
        self:SetTarget(target)
        return
    end
    if not self._proxy:CheckThreatList(self._uuid) then--仇恨列表为空，清空目标
        self:ClearTarget() --清空目标
        return
    end
    target = self._proxy:GetMaxThreatNpc(self._uuid) --从仇恨列表里找到一仇作为目标
    self:SetTarget(target)
end

---自定义返回目标
function XDlcPartnerBase:CombatLogicCustomSelectTarget()
    return nil
end

---清除目标信息
function XDlcPartnerBase:ClearTarget()
    self.target = nil
    self._proxy:RemoveFightTarget(self._uuid)
end

---更新战斗模式的战斗信息
function XDlcPartnerBase:UpdateFightInfo()
    --更新战斗信息

end

---检查目标有效性
function XDlcPartnerBase:CheckTargetValid()
    return self:CheckNpcValid(self.target)
end

---检查Npc的有效性
function XDlcPartnerBase:CheckNpcValid(npc)

    if (npc == 0) or (not npc) then
        return false
    end

    if not self._proxy:CheckNpc(npc) then
        return false
    end

    if self._proxy:CheckNpcAction(npc,ENpcAction.Dying) or self._proxy:CheckNpcAction(npc,ENpcAction.Death) or self._proxy:CheckNpcAction(npc,ENpcAction.Reboot) then
        return false
    end

    return true
end

---更新和战斗目标相关信息
function XDlcPartnerBase:UpdateTargetInfo()
    if not self.target then
        return
    end
    self.targetHpPercent = self._proxy:GetNpcAttribRate(self.target, ENpcAttrib.Life)
    self.targetPos = self._proxy:GetNpcPosition(self.target)
    self.targetDistance = self._proxy:CalcNpcDistance(self._uuid, self.target) --获取距离
end

---Tick执行伙伴AI
function XDlcPartnerBase:UpdatePartnerAi(dt)
    if not self.isCombatState then --PeaceState
        if self:EnterCombatCheck(dt) then--入战检查
            return
        end
        self:UpdatePeaceStateLogic(dt)
    end
    
    if self.isCombatState then --战斗状态
        self:UpdateTargetInfo()  --更新目标相关信息
        if self:OutCombatStateCheck(dt) then --脱战判断处理
            --检查退出战斗成功
            return
        end
        self:UpdateCombatLogic(dt)
    end
end

---Update战斗模式前
function XDlcPartnerBase:UpdateAIBefore(dt)
    self:UpdateSelfBaseInfo(dt) --更新伙伴自己的基础信息
    self:UpdateMasterInfo(dt) --更新Master的信息
end

---找到最近的敌人触发战斗
function XDlcPartnerBase:EnterCombatCheck()
    -------------------周围有敌人触发战斗-----------------------------------
    if #self.vigilantRangeEnemyList < 1 then--周围没有敌人的时候无法触发战斗
        --周围没有敌人时进入战斗失败
        return false
    end
    local nearestEnemy = self:GetNearestEnemy()--从周围的敌人里面找到最近的
    if not nearestEnemy then --没有最近的敌人
        return false
    end
    self:EnterCombatByNpc(nearestEnemy) --触发战斗方式为被Npc触发了
    return true
end

---没有一点点防备,也没有一丝顾虑，私自入战
function XDlcPartnerBase:EnterCombat()
    self.curFightMode = XDlcPartnerBase.FightMode.Combat --战斗模式设置为入战
    if self.enterCombatSkill then
        --有入战技能的时候使用入战斗技能：吼叫
        self._proxy:CastAction(self._uuid, self.enterCombatSkill)
    end
end

--被Npc触发战斗了，需要做点什么
function XDlcPartnerBase:EnterCombatByNpc(triggerNpc)
    self.isCombatState = true --进入战斗状态
    self:SetTarget(triggerNpc) --将目标设置为触发战斗的Npc
    --XLog.Warning(self._uuid.."进入战斗")
end

---寻找最低的敌人
function XDlcPartnerBase:GetNearestEnemy(range)
    local target = nil
    local lastDistance = 0
    
    if #self.vigilantRangeEnemyList < 1 then
        --没有Npc了
        return nil
    end
    for i, npc in pairs(self.vigilantRangeEnemyList) do--遍历警戒范围内的敌人，找到最近的
        local distance = self._proxy:CalcNpcDistance(self._uuid, npc) --计算和目标的距离
        if not self:CheckNpcValid(npc) then
            break
        end
        if range then --如果有范围需求，检查是否在范围内
            if distance > range then
                break
            end
        end
        if lastDistance == 0 then
            --初始第一个
            lastDistance = distance
            target = npc
            break
        end
        if distance < lastDistance then
            --如果比上一个更近，就更新距离和Npc
            lastDistance = distance
            target = npc
        end
    end
    return target
end

---根据位置寻找最近的敌人
function XDlcPartnerBase:GetNearestEnemyByPos(pos)
    local target = nil
    local lastDistance = 0
    local playerList = self._proxy:GetPlayerNpcList() --获取玩家列表
    
    
    for i, npc in pairs(playerList) do
        --遍历警戒范围内的敌人，找到最近的
        local distance = self._proxy:GetNpcToPositionDistance(npc,pos,true) --计算和位置的距离

        if lastDistance == 0 then
            --初始第一个
            lastDistance = distance
            target = npc
            break
        end
        if distance < lastDistance then
            --如果比上一个更近，就更新距离和Npc
            lastDistance = distance
            target = npc
        end
    end
    return target
end

--设置伙伴目标
function XDlcPartnerBase:SetTarget(npc)
    if (not npc) or (npc == 0) then
        --XLog.Warning("设置目标非法")
        return
    end
    self.target = npc
    self._proxy:SetFightTarget(self._uuid, npc)

    --设置该目标为移动目标
    local followTargetMinDis = self.followTargetMinDis
    local followTargetMMaxDis = self.followTargetMaxDis
    local followTargetHeartBeat = self.followTargetHeartBeat
    self._followController:SetFollowTargetNpcNoNavMesh(self.target, followTargetMinDis, followTargetMMaxDis, followTargetHeartBeat)  --跟随目标设置成当前目标
end

--获取伙伴目标
function XDlcPartnerBase:GetTarget()
   return self.target 
end
--移除伙伴目标
function XDlcPartnerBase:RemovePartnerTarget()
    self.target = nil
    self._proxy:RemovePartnerTarget(self._uuid)
    --取消移动组件
    self._followController:CancelFollow() --清空移动组件
end
--检查退出战斗
function XDlcPartnerBase:OutCombatStateCheck()
    local target = self.target
    local isOutBattle = false
    if (target == 0) or (not target) then
        self:OutCombatState() --退出战斗
        return true
    end

    if not self._proxy:CheckNpc(target) then
        self:OutCombatState() --退出战斗
        return true
    end

    if self._proxy:CheckNpcFullActionState(target, ENpcAction.Dying, -1) or self._proxy:CheckNpcFullActionState(target, ENpcAction.Death, -1) then
        self:OutCombatState() --退出战斗
        return true
    end

    return isOutBattle
end
--退出战斗时
function XDlcPartnerBase:OutCombatState()
    self.isCombatState = false
    self:ClearTarget() --清除目标相关东西
    --XLog.Warning(self._uuid.."退出战斗")
end
--endregion

--region 行为：基础
--行为筛选
function XDlcPartnerBase:PartnerSelectAction()
    local skill = nil --筛选技能的时候要用的
    self:ClearPartnerSelectActionData()--清空筛选数据
    skill = self:PartnerSelectNormalAttack() --普攻筛选
    if skill then
        self.SelectActionInfo.CurActionType = XDlcPartnerBase.ActionType.NormalAttack
        self.SelectActionInfo.SkillId = skill
        return
    end
    --没有任何能做的事情，追逐目标
    self.SelectActionInfo.CurActionType = XDlcPartnerBase.ActionType.Chase
    return
end
--执行行为
function XDlcPartnerBase:PartnerDoAction(dt)
    
    local actionType = self.SelectActionInfo.CurActionType
    if actionType == XDlcPartnerBase.ActionType.NormalAttack then --向目标普攻
        self:PartnerDoNormalAttack(dt)
    elseif actionType == XDlcPartnerBase.ActionType.Chase then--向目标移动
        self:PartnerDoChasing(dt)
    end
end

---清空筛选数据
function XDlcPartnerBase:ClearPartnerSelectActionData()
    self.SelectActionInfo = { --筛选信息
        CurActionType = XDlcPartnerBase.ActionType.None,
        SkillId = nil, --筛选类型要释放的技能假如有
    }
end

--伙伴进行普攻筛选
function XDlcPartnerBase:PartnerSelectNormalAttack()
    if #self.normalAttackList < 1 then 
        return nil
    end
    local skill = self.normalAttackList[self.normalAttackIndex]
    if self:PartnerCheckSkillConditionByNpc(skill,self.target) then
        return skill
    end   
    
    return nil
end

--伙伴进行普攻执行
function XDlcPartnerBase:PartnerDoNormalAttack()
    if not (self.lastActionType ==XDlcPartnerBase.ActionType.NormalAttack) then --上次类型不是普攻时重置普攻
        self.normalAttackIndex = 1
    end
    local su = self:PartnerForceSkillToTarget(self.normalAttackList[self.normalAttackIndex])
    if su then --释放成功
        if self.normalAttackIndex + 1 > #self.normalAttackList then --下段普攻超过范围的话就重置Index
            self.normalAttackIndex = 1
        else
            self.normalAttackIndex = self.normalAttackIndex + 1
        end
        self.lastActionType = XDlcPartnerBase.ActionType.NormalAttack
    end
end

--PartnerDoAction过程中发生意外了，需要重新选择行为。
function XDlcPartnerBase:ReSelectAction()

end
--检查目标是否在角度范围内
function XDlcPartnerBase:IsTargetInMyAngle(angle)
    return self._proxy:CheckNpcInAngle(self._uuid, self.target, angle)
end
--游荡
function XDlcPartnerBase:Wander()

end
--技能释放过程中的转身调整
function XDlcPartnerBase:TurnAround()

end
--攻击行为
function XDlcPartnerBase:Attack()
    if self:ForceSkillToNpc(self.SelectActionInfo.SkillId, self.target) then
        --强制释放这个技能
        self:OnActionDone(XDlcPartnerBase.ActionType.Attack)
    end
    --if self._proxy:CastActionToTarget(self._uuid,self.SelectActionInfo.SkillId,self.target) then
    --    
    --end
end
--当Action结束
function XDlcPartnerBase:OnActionDone(action)
    if action == XDlcPartnerBase.ActionType.Attack then
        self.SelectActionInfo.SkillId = nil
    end

    self.SelectActionInfo.CurActionType = nil
    self.SelectActionInfo.LastActionType = action

end
--endregion

--region 行为：追逐
--追逐目标
function XDlcPartnerBase:PartnerDoChasing(dt)
    if self.lastActionType ~= XDlcPartnerBase.ActionType.Chase then
        self._followController:SetFollowTargetNpcNoNavMesh(self.target, self.followTargetMinDis, self.followTargetMaxDis, self.followTargetHeartBeat)
    end
    self._followController:Update(dt)  --调用跟随组件走向目标
    self.lastActionType = XDlcPartnerBase.ActionType.Chase
end

--追逐测试
function XDlcPartnerBase:ChasingTest()
    local movePlan = 0
    local targetDist = self._proxy:CalcNpcDistance(self._npcId, self._targetId)--目标距离
    if movePlan < 2 and targetDist >= self._farDistance and self:IsTargetInMyAngle(self._farDistTurnStopAngle) then
        --远距离
        movePlan = 2
    elseif movePlan < 1 and targetDist >= self._midDistance and targetDist < self._farDistance --中距离
            and self:IsTargetInMyAngle(self._farDistTurnStopAngle)
    then
        movePlan = 1
    elseif movePlan < 1 and targetDist >= self._midDistance and targetDist < self._midDistance then
        --近距离停止移动
        movePlan = 0
    end

    if movePlan == 2 then
        --向目标位置快速移动
        self._proxy:NpcStartMove(self._npcId, self._targetPosition)
        self._proxy:SetNpcMoveDirection(self._npcId, 0)
        self._proxy:SetNpcMoveType(self._npcId, 1)
    elseif movePlan == 1 then
        --向目标位置普通移动
        self._proxy:NpcStartMove(self._npcId, self._targetPosition)
        self._proxy:SetNpcMoveDirection(self._npcId, 0)
        self._proxy:SetNpcMoveType(self._npcId, 0)
    elseif movePlan == 0 then
        --停止移动
        self._proxy:NpcStopMove(self._npcId)
    end
end
--endregion

--region 行为：转向
--转向算法测试
function XDlcPartnerBase:TurnTest()
    if not self._isWaiting and not self._proxy:CheckNpcAction(self._npcId, ENpcAction.Skill) then
        --没有放技能且等待
        local turnPlan = -1 --设置默认转向值
        local targetDist = self._proxy:CalcNpcDistance(self._npcId, self._targetId) --获取目标距离
        if self._turnActionId < 3 and targetDist >= self._midDistance and targetDist < self._farDistance --远距离转向
                and not self:IsTargetInMyAngle(self._farDistTurnStopAngle)
        then
            turnPlan = 3
        elseif self._turnActionId < 2 and targetDist >= self._nearDistance and targetDist < self._midDistance --中距离转向
                and not self:IsTargetInMyAngle(self._midDistTurnStopAngle)
        then
            turnPlan = 2
        elseif self._turnActionId < 1 and targetDist < self._nearDistance --近距离转向计划
                and not self:IsTargetInMyAngle(self._nearDistTurnStopAngle)
        then
            turnPlan = 1
        elseif self._turnActionId > 0 and self:IsTargetInMyAngle(self._nearDistTurnStopAngle) then
            --近距离转向计划
            turnPlan = 0
        end
    end
    --print("Turn plan: " .. tostring(turnPlan))

    for planId, data in pairs(self._turnPlanDataTable) do
        --在转向表里筛选转向
        --print("Check Turn plan: " .. tostring(planId))
        if turnPlan == planId then
            for j = 1, #data do
                local pair = data[j]
                if self._proxy:CheckNpcInAngleRangeHorizontal(self._npcId, self._targetId, pair[1], pair[2]) then
                    self._turnActionId = pair[3]
                    --print("Turn action: " .. tostring(self._turnActionId))
                    break
                end
            end
            break
        end
    end
    for actionId, skillId in pairs(self._turnActionMap) do
        if self._turnActionId == actionId then
            self._proxy:CastAction(self._npcId, skillId)
            break
        end
    end

    self._turnActionId = 0
end
--endregion

--region 行为：技能
--连招选择
function XDlcPartnerBase:SelectCombo()

end
--前置游荡
function XDlcPartnerBase:PreWander()

end
--后置游荡，技能释放结束后游荡
function XDlcPartnerBase:CommonWander()

end
--筛选技能
function XDlcPartnerBase:SelectSkill()
    if self.selectSkillType == XDlcPartnerBase.SelectSkillType.NormalSequence then
        --普通技能筛选，按照技能列表从左到右判断是否满足释放条件
        return self:NormalSequenceSelectSkill() --按从左到右顺序筛选技能
    end
    if self.selectSkillType == XDlcPartnerBase.SelectSkillType.RandomSequence then
        --普通技能筛选，按照技能列表从左到右判断是否满足释放条件
        return self:RandomSequenceSelectSkill() --普通列表随机筛选技能
    end
    if self.selectSkillType == XDlcPartnerBase.SelectSkillType.CastGroup then
        --普通技能筛选，按照技能列表从左到右判断是否满足释放条件
        return self:CastGroupSelectSkill() --按照技能释放组里的权重筛选出一个可以释放的技能
    end
    return nil
end
--普通顺序筛选技能
function XDlcPartnerBase:NormalSequenceSelectSkill()
    if #self.sequenceSkillList < 1 then
        --技能列表为空
        return nil
    end
    for index, skill in pairs(self.sequenceSkillList) do
        if self:PartnerCheckSkillCondition(skill) then--是否能释放该技能
            return skill
        end
    end
end

---检查技能条件是否满足/没有目标捏
function XDlcPartnerBase:PartnerCheckSkillCondition(skill)
    if not self._proxy:CheckNpcCurActionIsDone(self._uuid) then --需要等上一个技能放完
        return false
    end
    --技能锁定有效性判断
    if not self:CheckSkillLockedValid(skill) then
        --是否在锁定列表里
        return false
    end
    --技能CD有效性判断
    if not self:CheckSkillCdDone(skill) then
        return false
    end
    --血量有效性判断
    if not self:IsSkillHpValid(skill) then
        return false
    end
    return true
end

---检查技能条件是否满足/没有目标捏
function XDlcPartnerBase:PartnerCheckSkillConditionByNpc(skill,target)
    if not self._proxy:CheckNpcCurActionIsDone(self._uuid) then --需要等上一个技能放完
        return false
    end
    --技能锁定有效性判断
    if not self:CheckSkillLockedValid(skill) then
        --是否在锁定列表里
        return false
    end
    --技能CD有效性判断
    if not self:CheckSkillCdDone(skill) then
        return false
    end
    --血量有效性判断
    if not self:IsSkillHpValid(skill) then
        return false
    end
    --释放距离有效性判断
    if not self:IsSkillDistanceValid(skill,target) then
        return false
    end
    --释放角度有效性判断
    if not self:IsSkillAngleValid(skill) then
        --只是不满足角度的话，还有一丝丝希望
        return false
    end
    return true
end

--普通随机筛选
function XDlcPartnerBase:RandomSequenceSelectSkill()
    if #self.sequenceSkillList < 1 then
        --技能列表为空
        return nil
    end

    local skillIndex = self._proxy:Random(1, #self.sequenceSkillList)
    local skillId = self.sequenceSkillList[skillIndex]

    return skillId
end
--技能释放组
function XDlcPartnerBase:CastGroupSelectSkill()
    if #self.castGroup < 1 then
        --没有配置技能直接返回
        return
    end
    return self:GetAbleSkillToTargetByNpcCastGroup()
end
--endregion

--region 行为：游荡

--endregion

--region AI控制

---设置是否开启技能测试
function XDlcPartnerBase:SetSkillTestActive(isActive)
    self.isSkillTestOpen = isActive
end

---是否关闭Ai总开关，不包括测试技能AI
function XDlcPartnerBase:SetAiActive(isActive)
    self.isAiOpen = isActive   --是否关闭战斗Ai：指会对玩家造成威胁的Ai
end

---设置战斗逻辑Main是否跑
function XDlcPartnerBase:SetCombatLogicMainActive(isActive)
    self.isCombatLogicMainOpen = isActive
end

---设置战斗模式下的战斗逻辑AI是否开启
function XDlcPartnerBase:SetCombatLogicAiActive(isActive)
    self.isCombatLogicAiOpen = isActive
end

---设置战斗模式AI
function XDlcPartnerBase:SetCombatModeAiActive(isActive)
    --Ai战斗模式开关，入战和退出都不会走
    self.isCombatStateAiOpen = isActive
end

--endregion

--region 事件监听处理
function XDlcPartnerBase:InitEventCallBackRegister()
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkSetAIActivate)
end
--endregion

--region 事件执行处理

--处理Lua自定义事件
function XDlcPartnerBase:HandleLuaEvent(eventType, eventArgs)
    -- 响应AI开启和停止
    if eventType == EFightLuaEvent.RelinkSetAIActivate then --只处理传给自己的
        --XLog.Warning("eventArgs")
        --XLog.Warning(eventArgs)
        --XLog.Warning(self._uuid)
        if eventArgs.NpcUUid == self._uuid then
            --XLog.Warning(self._uuid.."收到了设置AI的事件")
            self:SetAiActive(eventArgs.IsActivated)
        end
    end
end

--endregion

--region 技能测试

---技能测试初始化
function XDlcPartnerBase:SkillTestInit()
    self.skillTestTimer = self._proxy:GetFightTime() + self.skillTestInitialCd --设置初始CD
    self:UpdateVigilantRangeEnemyList()--更新警戒范围敌人列表
    self:SetTarget(self:GetNearestEnemy()) --找到最近的敌人作为战斗目标
end

---技能配置测试模块
function XDlcPartnerBase:UpdateSkillTest()
    if not self.skillTestId then
        --没有配置测试ID
        return
    end
    if self.skillTestTimer > self._proxy:GetFightTime() then
        --测试CD用的
        return
    end
    if not self:CheckSelfActionValid() then
        return
    end
    self:UpdateTargetInfo()--更新目标相关信息
    if self.skillTestType == self.SkillTestType.CustomFuc then
        self:OnSkillTestTriggerCustomFuc()
    else
        self:PartnerForceSkillToTarget(self.skillTestId)
    end
    self.skillTestTimer = self._proxy:GetFightTime() + self.skillTestCd --释放成功，设置测试CD
end

---当技能测试触发自定义函数，只有自定义函数时会触发
function XDlcPartnerBase:OnSkillTestTriggerCustomFuc()
    
end
--endregion

--region NpcTimer

--初始化NpcTimer
function XDlcPartnerBase:InitNpcTimer(index,initCd,cd)
    if not self.npcTimerList[index] then
        self.npcTimerList[index]={
        }
    end
    self.npcTimerList[index].initCd = initCd
    self:SetNpcTimerCd(index,cd)
    self:SetNpcTimerTime(index,initCd)
end

--设置NpcTimer的Cd
function XDlcPartnerBase:SetNpcTimerCd(index,cd)
    self.npcTimerList[index].cd = cd
end

--设置Timer时间
function XDlcPartnerBase:SetNpcTimerTime(index,time)
    if time then
        self.npcTimerList[index].time = self.npcTime + time
    end
end

--NpcTimer进入CD
function XDlcPartnerBase:NpcTimerEnterCd(index)
    local cd = self.npcTimerList[index].cd
    if not cd then
        self.npcTimerList[index].cd = 0
    end
    self.npcTimerList[index].time = self.npcTime + self.npcTimerList[index].cd
end

--获取TimerCd
function XDlcPartnerBase:GetNpcTimerRemainTime(index)
    local time =  self.npcTime-self.npcTimerList[index].time
    if time <0 then
        return 0
    end
    return time
end
    
--检查Timer好了没有
function XDlcPartnerBase:CheckNpcTimer(index)
    if not self.npcTimerList[index] then
        return true
    end
    return self.npcTime >= self.npcTimerList[index].time
end

--设置对应Index的Timer清空时间
function XDlcPartnerBase:ClearNpcTimer(index)
    self.npcTimerList[index].time = self.npcTime
end

--endregion

--region 伙伴脚本的工具函数
---获取关卡场景中心点
function XDlcPartnerBase:GetLevelCenterPoint()
    return self.levelCenterPoint
end

---概率成功，输入概率，返回是否成功
function XDlcPartnerBase:GetRandomSuccess(maybe)
    local isSuccess = false
    if self._proxy:Random(0, 100) < maybe then
        isSuccess = true
    end
    return isSuccess
end

---Magic给范围内的敌人
function XDlcPartnerBase:ApplyMagicToPlayerInRange(magicId,level,range)
    local tempLevel = 1
    if level then
        tempLevel = level
    end
    local npcList = self:GetPlayerListInRange(range)
    for i, npc in pairs(npcList) do
        self._proxy:ApplyMagic(self._uuid,npc,magicId,tempLevel)
    end
end

---ApplyMagic给所有玩家
function XDlcPartnerBase:ApplyMagicAllPlayer(magicId,level)
    local tempLevel = 1
    local npcList = self:GetPlayerListInRange(99999)
    if level then
        tempLevel = level
    end
    for i, npc in pairs(npcList) do
        self._proxy:ApplyMagic(self._uuid,npc,magicId,tempLevel)
    end
end

---ApplyMagic给所有玩家
function XDlcPartnerBase:ApplyMagicOtherAllNpc(magicId,level)
    local tempLevel = 1
    local npcList = self._proxy:GetNpcList()
    if level then
        tempLevel = level
    end
    for i, npc in pairs(npcList) do
        if not npc ~= self._uuid then
            self._proxy:ApplyMagic(self._uuid,npc,magicId,tempLevel)
        end
    end
end

---给自己Magic一个列表
function XDlcPartnerBase:ApplyMagicsToSelf(magics)
    for i,magicId in pairs(magics)do
        self._proxy:ApplyMagic(self._uuid,self._uuid,magicId,1)
    end
end

---判断值是否在table中
function XDlcPartnerBase:ValueIsInTable(value,table)
    if #table < 0 then
        return false
    end
    for i,v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

---检查是否锁定技能
function XDlcPartnerBase:CheckSkillLockedValid(skill)
    if self.skillLockedList[skill] then
        return false
    else
        return true
    end
end

---设置技能锁定，不能释放
function XDlcPartnerBase:SetSkillLocked(skill)
    self.skillLockedList[skill] = true
end

---设置技能解锁，允许释放。
function XDlcPartnerBase:SetSkillUnLocked(skill)
    self.skillLockedList[skill] = false
end

---把技能添加进锁定列表
function XDlcPartnerBase:AddSkillLocked(skill)
    table.insert(self.skillLockedList,skill)
end

---通常的检查技能条件,目标是按照Ai的战斗目标去判断
function XDlcPartnerBase:CheckSkillCondition(skill,target)
    if not self._proxy:CheckNpcCurActionIsDone(self._uuid) then --需要等上一个技能放完
        return false
    end
    --技能锁定有效性判断
    if not self:CheckSkillLockedValid(skill) then
        --是否在锁定列表里
        return false
    end
    --技能CD有效性判断
    if not self:CheckSkillCdDone(skill) then
        return false
    end
    --OD状态有效性判断
    if not self:IsSkillODStateValid(skill) then
        return false
    end
    --阶段有效性判断
    if not self:IsSkillPhaseValid(skill) then
        return false
    end
    --血量有效性判断
    if not self:IsSkillHpValid(skill) then
        return false
    end
    --释放距离有效性判断
    if not self:IsSkillDistanceValid(skill,target) then
        return false
    end
    --释放角度有效性判断
    if not self:IsSkillAngleValid(skill) then
        --只是不满足角度的话，还有一丝丝希望
        return false
    end
    return true
end

---检查怪物配置的技能条件,目标是判断传入的目标，不检查当前动作
function XDlcPartnerBase:CheckSkillConditionByNpc(skill,npc)
    --技能锁定有效性判断
    if not self:CheckSkillLockedValid(skill) then
        return false
    end

    --检查技能CD好了没有
    if not self:CheckSkillCdDone(skill) then
        return false
    end
    --OD状态有效性判断
    if not self:IsSkillODStateValid(skill) then
        return false
    end
    --阶段有效性判断
    if not self:IsSkillPhaseValid(skill) then
        return false
    end
    --血量有效性判断
    if not self:IsSkillHpValid(skill) then
        return false
    end
    --对传入的Npc进行距离判断
    if not self:CheckSkillDisByNpc(skill, npc) then
        return false
    end
    --释放角度有效性判断
    if not self:IsSkillAngleValid(skill) then
        --只是不满足角度的话，还有一丝丝希望
        return false
    end
    return true
end

---对自己OD状态有效性判断
function XDlcPartnerBase:IsSkillODStateValid(skill)
    local config = SkillConfigs[skill]
    if not config then--没有配置条件直接返回True
        return true
    end
    if config.IsLockInODState and self:CheckCurIsOverDrive() then --OD锁定且在OD,返回F
        --XLog.Warning("技能"..skill.."释放失败，因为OD锁定且当前在OD")
        return false
    end
    if config.IsNeedODState and (not self:CheckCurIsOverDrive()) then --需要OD且不在OD,返回F
        return false
    end
    return true
end

---对自己阶段有效性判断
function XDlcPartnerBase:IsSkillPhaseValid(skill)
    local config = SkillConfigs[skill]
    if not config then
        return true
    end
    local needs = config.PhaseNeed
    if not needs then
        return true
    end

    if #needs < 1 then
        return true
    end

    for i, phase in pairs(needs) do--里面有和自己当前阶段状态一样的
        if phase == self.curPhase then
            return true
        end
    end

    return false
end

---自己血量有效性判断  
function XDlcPartnerBase:IsSkillHpValid(skill)
    local config = SkillConfigs[skill]
    if not config then
        return true
    end
    local needs = config.HpNeed
    if not needs then
        return true
    end
    if #needs < 1 then
        return true
    end

    if self.hpRate <= needs[2] and self.hpRate >= needs[2] then
        --在最小值和最大值区间
        return true
    end

    return false
end

---对当前已筛选到的目标释放距离有效性判断
function XDlcPartnerBase:IsSkillDistanceValid(skill,target)
    if not target then
        return true
    end

    return self:CheckSkillDistance(skill, self._proxy:GetNpcDistance(self._uuid,target,true)) --传入目标距离去检查
end

--传入技能和距离检查距离是否满足技能配置的释放条件
function XDlcPartnerBase:CheckSkillDistance(skill, distance)
    local config = SkillConfigs[skill]
    if not config then
        --没有这个技能配置
        return true
    end
    local needs = config.DistanceNeed
    if not needs then
        --没有配置距离要求
        return true
    end
    if #needs < 0 then
        --距离要求为空
        return true
    end
    local su = false
    if #needs == 1 then--只有一个要求，是范围内
        return distance <= needs[1]--是否小于等于距离要求
    end
    --是否大于等于最小And小于等于最大
    return (distance >= needs[1]) and (distance <= needs[2])
end

--返回与目标距离是否在范围内
function XDlcPartnerBase:CheckTargetDistance(distance)
    return self.targetDistance <= distance
end

---检查Npc的距离
function XDlcPartnerBase:CheckSkillDisByNpc(skill, npc)
    if not self._proxy:CheckNpc(npc) then
        --XLog.Warning("NPC非法,CheckSkillDisByNpc不通过" .. npc)
        return false
    end
    local dis = self._proxy:CalcNpcDistance(self._uuid, npc)
    return self:CheckSkillDistance(skill,dis)
end

---检查和目标距离是否在范围内
function XDlcPartnerBase:CheckDisByTarget(distances)
    return distances <= self.targetDistance
end

--释放角度有效性判断
function XDlcPartnerBase:IsSkillAngleValid(skill)
    local config = SkillConfigs[skill]
    if not config then
        return true
    end
    local needs = config.SpaceNeed
    if not needs then
        return true
    end
    if #needs < 1 then
        return true
    end
    local angle = needs[1]
    local offset = needs[2]
    local rotaY = needs[3]
    --中间角度判断的逻辑就不懂了，摇程序
    return true
end

--技能转向有效性判断
function XDlcPartnerBase:IsSkillTurnFixValid(skill)
    if not self.haveSkillTurnFix then
        --AI关闭了转向就不转了
        return false
    end

    local config = SkillConfigs[skill]
    if not config then
        --没有配置转向也不转
        return false
    end

    if not config.HaveTurnFix then
        --技能没有转向也不转
        return false
    end

    if self.currentTurnValue <= self.turnFixConsume then
        --没有可以转向的帕瓦了
        return false
    end
    return false
end

---通过字符串检查是否存在某个函数
function XDlcPartnerBase:CheckHaveFunctionByString(funcName)
    if not self[funcName] then
        return false
    end
    if type(self[funcName]) ~= "function" then
        return false
    end
    return true
end

---尝试通过字符串执行函数，仅适用于不传参+不回参需求的函数。
function XDlcPartnerBase:TryRunFunctionByString(funcName)
    if self:CheckHaveFunctionByString(funcName) then
        self[funcName](self)--存在这个名字的函数，直接运行函数
        return true
    else
        return false
    end
end

---尝试把Npc送进仇恨值列表
function XDlcPartnerBase:TryAddNpcToThreatValueList(npc)
    if self:CheckNpcIsPlayer(npc) and (not self._proxy:CheckNpcInThreatList(self._uuid,npc)) then
        self:AddNpcToThreatValueList(npc)
    end
end

---Npc添加进仇恨列表
function XDlcPartnerBase:AddNpcToThreatValueList(npc)
    self._proxy:ApplyMagic(self._uuid, npc, 8052000, 1) --触发的Npc给自己添加1仇恨，用来添加进仇恨列表
end

---检查Npc是不是玩家
function XDlcPartnerBase:CheckNpcIsPlayer(npc)
    local playerList = self._proxy:GetPlayerNpcList()
    return self:ValueIsInTable(npc,playerList)--返回是否在玩家列表
end

---获取场景中心点
function XDlcPartnerBase:GetCenterPoint()
    return self._proxy
end

---获取NpcA向前朝向和NpcB的夹角
function XDlcPartnerBase:GetNpcTargetAngle(npc,target)
    local npcAPos = self._proxy:GetNpcPosition(npc)
    --XLog.Warning("获取目标的朝向2")
    --XLog.Warning("npc1是："..npc)
    --XLog.Warning("目标是："..target)
    local npcAFace = self._proxy:GetNpcOffsetPositionByFacing(npc,{x=0,y=0,z=0},1) - npcAPos --NpcA的朝向
    --XLog.Warning(npcAFace)
    --XLog.Warning("获取完毕")
    local npcBPos =self._proxy:GetNpcPosition(target)
    return self:GetAngleByPosFace(npcAPos,npcAFace,npcBPos)
end

---获取目标方位根据Npc的朝向
function XDlcPartnerBase:GetNpcTargetDirection(npc,target)
    local npcAPos = self._proxy:GetNpcPosition(npc)

    local npcAFace = self._proxy:GetNpcOffsetPositionByFacing(self._uuid, { x=0,y=0,z=0 },1) - npcAPos --NpcA的朝向
    local npcBPos =self._proxy:GetNpcPosition(target)
    return self:GetDirectionRelativePosFace(npcAPos,npcAFace,npcBPos)
end

---根据A点的朝向
function XDlcPartnerBase:GetAngleByPosFace(pointA, orientationA, pointB)
    -- 将点A的朝向向量投影到XZ平面（忽略Y轴）
    local dirVectorX = orientationA.x
    local dirVectorZ = orientationA.z

    -- 计算从点A到点B的向量，并投影到XZ平面
    local toBVectorX = pointB.x - pointA.x
    local toBVectorZ = pointB.z - pointA.z

    -- 计算两个向量的模长
    local dirMagnitude = math.sqrt(dirVectorX * dirVectorX + dirVectorZ * dirVectorZ)
    local toBMagnitude = math.sqrt(toBVectorX * toBVectorX + toBVectorZ * toBVectorZ)

    -- 如果任一向量长度为0，则无法计算夹角
    if dirMagnitude == 0 or toBMagnitude == 0 then
        return 0
    end

    -- 计算两个向量的点积
    local dotProduct = dirVectorX * toBVectorX + dirVectorZ * toBVectorZ

    -- 计算夹角的余弦值
    local cosAngle = dotProduct / (dirMagnitude * toBMagnitude)

    -- 处理浮点数精度问题，确保cosAngle在[-1, 1]范围内
    cosAngle = math.max(-1, math.min(1, cosAngle))

    -- 计算夹角（弧度）并转换为角度
    local angleRad = math.acos(cosAngle)
    local angleDeg = math.deg(angleRad)

    -- 返回0到180度之间的角度
    return angleDeg
end

--获取坐标B相对于坐标A和坐标A朝向的方位（left、right、front）
function XDlcPartnerBase:GetDirectionRelativePosFace(pointA, orientationA, pointB)
    -- 将点A的朝向向量投影到XZ平面（忽略Y轴）
    local forwardX = orientationA.x
    local forwardZ = orientationA.z

    -- 计算从点A到点B的向量，并投影到XZ平面
    local toB_X = pointB.x - pointA.x
    local toB_Z = pointB.z - pointA.z

    -- 计算两个向量的叉积（只取Y分量）
    local crossProduct = forwardX * toB_Z - forwardZ * toB_X

    -- 根据叉积的正负判断左右
    if crossProduct > 0 then
        return "left"  -- B在A的左侧
    elseif crossProduct < 0 then
        return "right" -- B在A的右侧
    else
        return "front" -- B在A的正前方或正后方
    end
end

---设置玩家强锁自己
function XDlcPartnerBase:SetPlayerHardLockSelf()
    for i , playerUUID in pairs(self._proxy:GetPlayerNpcList()) do
        self._proxy:SetHardLock(playerUUID,self._uuid)
    end
end

---检查位置到位置的距离忽略Y轴是否在范围内
function XDlcPartnerBase:CheckNpcToPosDistanceIgnoreY(npcUUID,pos,dis)
    return self:GetNpcToPosDistanceIgnoreY(npcUUID,pos)<= dis
end

---检查位置到位置的距离忽略Y轴是否在范围内
function XDlcPartnerBase:GetNpcToPosDistanceIgnoreY(npcUUID,pos2)
    local pos1= self._proxy:GetNpcPosition(npcUUID)
    local dx = pos2.x-pos1.x
    local dz = pos2.z-pos1.z
    return math.sqrt(dx*dx + dz *dz)
end

---检查位置到位置的距离忽略Y轴是否在范围内
function XDlcPartnerBase:CheckPosToPosDistanceIgnoreY(pos1,pos2,dis)
    return self:GetPosToPosDistanceIgnore(pos1,pos2)<= dis
end

---获取位置1到位置2的忽略Y轴距离
function XDlcPartnerBase:GetPosToPosDistanceIgnoreY(pos1,pos2)
    local dx = pos2.x-pos1.x
    local dz = pos2.z-pos1.z
    return math.sqrt(dx*dx + dz *dz)
end

---检查Npc是否为当前技能目标
function XDlcPartnerBase:CheckNpcIsCurSkillTarget(npc)
    if not npc then
        return false
    end
    if not self.curSkillTarget then
        return false
    end
    return npc == self.curSkillTarget
end

---检查Npc是否为当前技能目标
function XDlcPartnerBase:GetPositionByPosToPosOffset(pos1,pos2,offset)
    if not npc then
        return false
    end
    if not self.curSkillTarget then
        return false
    end
    return npc == self.curSkillTarget
end



--TODO:可能要判断是否死亡，现在没有包括死亡判断
---获取位置半径范围内玩家数量（）
function XDlcPartnerBase:GetPlayerCountByPosRadiusIgnoreY(pos,radius)
    local playerList = self._proxy:GetPlayerNpcList()
    local count = 0
    for i,player in pairs(playerList) do
        if self:CheckNpcToPosDistanceIgnoreY(player,pos,radius) then
            count = count + 1
        end
    end
    return count
end

---根据标签或角色类型决定拼刀类型
function XDlcPartnerBase:GetParryType(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    --触发子弹Tag是打断式时
    if GameplayTag.CSMatchAnyTag(triggerTag,{EGameplayTag.Missile_Parry_Trigger_Interrupt}) then
        if GameplayTag.CSMatchAnyTag(counterTag, {EGameplayTag.Missile_Parry_Counter_Heavy}) then
            return 1 --强Counter打断
        end
        if GameplayTag.CSMatchAnyTag(counterTag, {EGameplayTag.Missile_Parry_Counter_Medium}) then
            return 1 --中Counter打断
        end
        return 2 --弱Counter不打断
    end
    --触发子弹Tag是不打断式时
    if GameplayTag.CSMatchAnyTag(triggerTag, {EGameplayTag.Missile_Parry_Trigger_Sustain}) then
        return 2 -- 不打断
    end
    --多人弹刀/角力类型
    if GameplayTag.CSMatchAnyTag(triggerTag,{EGameplayTag.Missile_Parry_Trigger_MultiInteract}) then
        if GameplayTag.CSMatchAnyTag(counterTag, {EGameplayTag.Missile_Parry_Counter_Heavy}) then
            return 3 --强Counter进多人
        end
    end
    return 0
end

---根据Counter的角色判断是否多人
function XDlcPartnerBase:CheckParryMultipleByCounter(Npc)

end

--endregion

--region 技能释放处理工具
--对战斗目标释放技能
---伙伴对npc释放技能,会进行一系列伙伴侧配置的条件判断
function XDlcPartnerBase:CastSkillToNpc(skill, npc)
    if not self._proxy:CheckNpc(npc) then
        --XLog.Warning("释放技能" .. skill .. "失败,Npc非法")
        return false
    end
    local isSuccess = false
    self:PartnerCheckSkillCondition(skill)
    if self:PartnerCheckSkillConditionByNpc(skill, npc) then
        isSuccess = self._proxy:CastActionToTarget(self._uuid, skill, target)
    end
    self:HandleAfterCastSkill(skill,isSuccess,npc)--处理释放技能之后
    return isSuccess
end

---无目标强制释放技能
function XDlcPartnerBase:ForceSkill(skill)
    self._proxy:AbortAction(self._uuid, true) --强制打断当前技能
    local isSuccess = self._proxy:CastAction(self._uuid,skill)--强制释放这个技能
    return isSuccess
end

---强制对战斗目标释放技能（行为脚本不判断除了战斗目标合法性以外的条件）
function XDlcPartnerBase:PartnerForceSkillToTarget(skill)
    local target = self._proxy:GetFightTargetId(self._uuid)
    local isSuccess = false
    if not self._proxy:CheckNpc(target) then
        --目标不合法
        --XLog.Warning("强制释放技能目标非法"..target)
        return false
    end
    
    self._proxy:AbortAction(self._uuid, true) --强制打断当前技能
    isSuccess = self._proxy:CastSkillActionToNpcNotCheck(self._uuid, skill, target)--对目标放技能
    self:HandleAfterCastSkill(skill,isSuccess,target)--处理释放技能之后
    return isSuccess
end

---对战斗目标释放技能（会判断配置的技能条件）
function XDlcPartnerBase:CastSkillToTarget(skill)
    local target = self._proxy:GetFightTargetId(self._uuid)
    local isSuccess = false
    if self._proxy:CheckNpc(target) then
        --目标不合法
        return false
    end
    if not self:PartnerCheckSkillConditionByNpc(skill, target) then
        --技能条件不通过
        return false
    end
    isSuccess = self._proxy:CastActionToTarget(self._uuid, skill, target)--对目标放技能
    self:HandleAfterCastSkill(skill, isSuccess,target)--处理释放技能之后
    return isSuccess
end

---强制对Npc释放技能（行为脚本不判断除了Npc合法性以外的条件）
function XDlcPartnerBase:ForceSkillToNpc(skill, npc)
    local isSuccess = false
    if not self._proxy:CheckNpc(npc) then
        --目标不合法
        return false
    end
    self._proxy:AbortAction(self._uuid, true)--打断Npc
    isSuccess = self._proxy:CastActionToTarget(self._uuid, skill, npc)--放技能
    self:HandleAfterCastSkill(skill, isSuccess,npc)--放完技能后处理CD
    return isSuccess
end

---获得权重组里对Npc可以放的技能
function XDlcPartnerBase:GetAbleSkillByWeightsToNpc(skills,npc)
    local newGroup = {}
    local totalW = 0 --总权重
    for skill, w in pairs(skills) do
        --筛选出满足条件的权重组
        if self:PartnerCheckSkillConditionByNpc(skill, npc) then
            --判断对这个Npc放技能是否满足条件
            newGroup[skill] = w
            totalW = totalW + w --总权重
        end
    end
    return self:GetWeightsKeyByTotalWeight(newGroup, totalW)
end

---从权重组里直接拿出Key(目前用于技能权重组里获取技能)
function XDlcPartnerBase:GetKeyByWeights(skills)
    local totalW = 0 --总权重
    --计算总权重
    for skill, w in pairs(skills) do
        totalW = totalW + w
    end
    return self:GetWeightsKeyByTotalWeight(skills, totalW)--直接从技能组里随机一个出去
end

---对战斗目标根据权重组放技能（技能组，是否忽略技能完成）
function XDlcPartnerBase:TryCastSkillToTargetByWeights(skills)
    local target = self.target
    local isSuccess = false
    local skill = self:GetAbleSkillByWeightsToNpc(skills,target) --从权重组里找到适合可以放的技能
    if not skill then
        return false
    end
    isSuccess = self:ForceSkillToNpc(skill, target)  --对战斗目标强制放这个连招技能
    self:HandleAfterCastSkill(skill, isSuccess,target)--释放技能后要处理技能进入CD
    return isSuccess
end

---对战斗目标根据权重组强制放技能
function XDlcPartnerBase:ForceCastSkillToTargetByWeights(skills)
    local skill = self:GetKeyByWeights(skills) --从权重组里筛出一个技能,不包括条件判断
    local isSuccess = false
    if not skill then
        return false
    end
    isSuccess = self:PartnerForceSkillToTarget(skill)  --强制释放拿出来的技能给战斗目标
    return isSuccess
end

---强制对位置释放技能（不走伙伴脚本的判断条件）
function XDlcPartnerBase:ForceSkillToPosition(skill, pos)
    self._proxy:AbortAction(self._uuid, true)--打断当前技能
    local isSuccess = self._proxy:CastActionToPosition(self._uuid, skill, pos)--对位置释放技能
    self:HandleAfterCastSkill(skill, isSuccess,nil)--处理释放技能之后
end

---尝试对位置释放技能
function XDlcPartnerBase:CastSkillToPosition(skill, pos)
    if not self:PartnerCheckSkillCondition(skill,pos) then --TODO:不是只有对目标，位置或Npc一样需要。
        return
    end
    self._proxy:AbortAction(self._uuid, true)--打断当前技能
    local isSuccess = self._proxy:CastActionToPosition(self._uuid, skill, pos)--对位置释放技能
    self:HandleAfterCastSkill(skill, isSuccess,nil)--处理释放技能之后
end


---输入权重组和总权重获得Key
function XDlcPartnerBase:GetWeightsKeyByTotalWeight(weights, total)
    --传入权重Table，和总权重，返回Key
    local rand = self._proxy:Random(0, total) --从总权重里随机一个值
    local accumulated = 0 --用来计算权重用的
    for skillID, weight in pairs(weights) do
        accumulated = accumulated + weight
        if accumulated >= rand then
            return skillID
        end
    end
end

---处理释放技能之后,目前只有技能进入配置CD的处理
function XDlcPartnerBase:HandleAfterCastSkill(skill, isSuccess,target)
    if not isSuccess then
        --技能没有成功就不管了
        return
    end
    self.curSkillTarget = target --设置当前技能目标
    self:EnterSkillCd(skill) --技能进入CD
    self:OnPartnerCastSkillSuccessAfter(skill)
end

---释放技能成功后
function XDlcPartnerBase:OnPartnerCastSkillSuccessAfter(skill)
end

---设置技能CD直接完成
function XDlcPartnerBase:SetSkillCdDone(skill)
    local cd = SkillConfigs[skill].Cd
    if not cd then
        return
    end
    self.SkillCds[skill].time = self.fightTime
end

---技能进入给定的CD，不会影响原本的CD配置
function XDlcPartnerBase:EnterSkillGiveCd(skill,cd)
    if not self.SkillCds[skill] then--
        self.SkillCds[skill] = {}
    end
    self.SkillCds[skill].time = self.fightTime + cd
end

---初始化技能cd。
function XDlcPartnerBase:InitSkillCd(skill,initCd,cd)
    self.SkillCds[skill] = {}
    self.SkillCds[skill].initCd = initCd
    self.SkillCds[skill].cd = cd
    self.SkillCds[skill].time = self.fightTime + initCd 
end

---重置技能CD
function XDlcPartnerBase:EnterSkillCd(skill)
    if not self.SkillCds[skill] then
        self:InitSkillCd(skill,0,0)
        return
    end
    self.SkillCds[skill].time = self.fightTime + self.SkillCds[skill].cd
end

---检查技能Cd好了没有
function XDlcPartnerBase:CheckSkillCdDone(skill)
    local info = self.SkillCds[skill]
    if not info then
        return true
    end
    return self.fightTime >= info.time--当前战斗时间是否大于配置的cd时间
end

---获取技能CD剩余时间
function XDlcPartnerBase:GetSkillCdRemainTime(skill)
    local info = self.SkillCds[skill]
    local remain =  info.time - self.fightTime
    if remain <= 0 then
        return 0
    else 
        return remain
    end
end

--endregion

--region 伙伴技能释放组
---清除释放组
function XDlcPartnerBase:ClearCastGroup()
    self.castGroup = {}
end

---设置释放组
function XDlcPartnerBase:SetCastGroup(castList)
    self.castGroup = castList
end

---获取释放组
function XDlcPartnerBase:GetCastGroup()
    return self.castGroup
end

---添加技能组进释放组
function XDlcPartnerBase:AddSkillsToCastGroup(group)
    table.insert(self.castGroup, group)
end

---设置技能组Cd
function XDlcPartnerBase:SetSkillsCd(skillsId)
    --table.insert(self.castGroup,skillsId)
end

---从Npc自定义变量的释放组里获得一个可以对当前战斗目标可以放的技能
function XDlcPartnerBase:GetAbleSkillToTargetByNpcCastGroup()
    for skillsId, skills in pairs(self.castGroup) do
        --遍历释放组去获得技能权重组
        local skill = self:GetAbleSkillByWeightsToNpc(skills,self.target) --从当前技能组里获得可以对当前目标放的技能
        if skill then
            --如果获得了技能就返回这个技能
            return skill
        end
    end
    return nil --如果没有技能就不放技能了。
end

---从脚本变量释放组里对Npc获得可以释放的技能(npc)
function XDlcPartnerBase:GetAbleSkillToNpcByNpcCastGroup(npc)
    for skillsId, skills in pairs(self.castGroup) do
        --遍历释放组去获得技能权重组
        local skill = self:GetAbleSkillByWeightsToNpc(skills, npc) --从当前技能组里获得可以对当前目标放的技能
        if skill then
            --如果获得了技能就返回这个技能
            return skill
        end
    end
    return --如果没有技能就不放技能了。
end

---传入组和Npc，尝试释放可以放的技能。(group,npc)
function XDlcPartnerBase:CastSkillToNpcByCastGroup(group,npc)
    for skillsId, skills in pairs(group) do
        --遍历释放组去获得技能权重组
        local skill = self:GetAbleSkillByWeightsToNpc(skills, npc) --从当前技能组里获得可以对当前目标放的技能
        if skill then --有筛选到技能
            return self:ForceSkillToNpc(skill,npc)--强制释放并返回结果
        end
    end
    return --如果没有技能就不放技能了。
end

---传入释放组和Npc返回可以放的技能(group,npc)
function XDlcPartnerBase:GetAbleSkillToNpcByCastGroup(group,npc)
    for skillsId, skills in pairs(group) do
        --遍历释放组去获得技能权重组
        local skill = self:GetAbleSkillByWeightsToNpc(skills, npc) --从当前技能组里获得可以对当前目标放的技能
        if skill then
            --如果获得了技能就返回这个技能
            return skill
        end
    end
    return --如果没有技能就不放技能了。
end

---对战斗目标尝试从CastGroup里释放一个满足条件的技能
function XDlcPartnerBase:CastSkillToTargetIgnoreSkillDoneByCastSkillGroup()
    for skillsId, skills in pairs(self.castGroup) do
        --遍历释放组去获得技能权重组
        local skill = self:GetAbleSkillByWeightsToNpc(skills, self.target) --从当前技能组里获得可以对当前目标放的技能
        if skill then
            self:PartnerForceSkillToTarget(skill)
        end
    end
    return --如果没有技能就不放技能了。
end

--endregion

--endregion

return XDlcPartnerBase