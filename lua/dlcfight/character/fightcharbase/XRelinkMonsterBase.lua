local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
---Relink的怪物基类
---@class XRelinkMonsterBase : XFightBase
local XRelinkMonsterBase = XClass(Base, "XRelinkMonsterBase")
local SkillConfigs = require("TempSkillConfigs/SkillConfig_8052")--小辉辉临时的技能配置

--region 脚本枚举
---战斗状态管理
XRelinkMonsterBase.FightMode = { --无、非战斗、战斗、目标丢失
    ---无
    None = 0,
    ---非战斗
    NonCombat = 1,
    ---战斗
    Combat = 2,
    ---战斗逻辑时目标丢失（死亡、隐身等）
    CombatTargetLosing = 3
}
---OD状态管理
XRelinkMonsterBase.ODState = {
    --- 无激活OD状态
    None = 0,
    --- 普通
    Normal = 1,
    --- 狂暴
    ODState = 2,
    --- 虚弱
    Breaking = 3,
}
---行为筛选和执行时的类型
XRelinkMonsterBase.ActionType = {--待机、追逐移动、攻击、游荡、巡逻、连招
    ---无行为类型
    None = 0,
    ---
    Chase = 1,
    ---攻击，使用技能
    Attack = 2,
    ---游荡
    Wander = 3,
    ---巡逻
    Patrol = 4,
    ---连招
    Combo = 5,
}
---切换阶段条件
XRelinkMonsterBase.PhaseSwitchType = { --不切阶段、Hp、时间轴
    ---没有切换阶段
    None = 0,
    ---按照血量切换阶段
    Hp = 1,
    ---根据时间切换阶段
    TimeLine = 2,
}
---距离类型
XRelinkMonsterBase.DistanceType = { --近、中、远、超远
    ---无
    None = 0,
    ---近
    Near = 1,
    ---中
    Mid = 2,
    ---远
    Far = 3,
    ---超远
    SoFar = 4
}
---方位类型
XRelinkMonsterBase.DirectionType = { --前、后、左、右（暂时只需要四方向）
    ---前
    Front = 1,
    ---后
    Back = 2,
    ---左
    Left = 3,
    ---右
    Right = 4,
}
---技能修正类型
XRelinkMonsterBase.AttackFixType = {
    ---转向
    Turn = 1,
    ---距离
    Distance = 2,
}
---战斗逻辑情况下按照什么类型选择技能
XRelinkMonsterBase.SelectSkillType = {--根据什么规则去释放技能。
    ---不释放技能
    None = 0,
    ---从技能释放组里按顺序判断可放技能{id1,id2,id3}
    NormalSequence = 1, --NormalList里按从前到后筛选一个可释放技能。(未实现)
    ---从技能释放组里随机放可放技能{id1,id2,id3}
    RandomSequence = 2, --NormalList里按照权重随机一个技能。（已支持）
    ---技能释放组
    CastGroup = 3, 
}
---返回的转向类型
XRelinkMonsterBase.TurnType = { --根据转向类型决定调用哪个转向技能
    None = 0, --无转向
    Left45 = 1,
    Right45 = 2,
    Left90 = 3,
    Right90 = 4,
    Left135 = 5,
    Right135 = 6,
    Left180 = 7,
    Right180 = 8
}
XRelinkMonsterBase.SkillLayer = { --技能释放层，用来表示用哪个技能组
    None = 0,
    Normal = 1,
    ODState = 2,
}
XRelinkMonsterBase.SkillGroup = { --技能组结构
    GroupId = 0, --组ID，不用管
    GroupConditionType = 1, --组判断类型，乱选还是顺序选
    SkillList = 2, --组对应的技能列表。
}
--endregion

--region 函数: 脚本生命周期

---初始化
function XRelinkMonsterBase:Init()
    Base.Init(self)
    self:MonsterRunVarAwake() --怪物运行逻辑初始化构造
    self:MonsterConfigMain() --怪物配置，用来覆盖初始化好的变量
    self:MonsterRunInit() --怪物初始化，根据配置会有调整
end

---帧更新
---@param dt number @ delta time 
function XRelinkMonsterBase:Update(dt)
    Base.Update(self, dt)
    if self.isSkillTestOpen then
        self:UpdateSkillTest(dt) --技能测试逻辑
        return
    end
    if not self.isAiOpen then--AI是否关闭
        --AI总开关
        return
    end

    self:UpdateSelfBaseInfo(dt) --更新怪物自己的基础信息

    --self:UpdateGamePlayLogic(dt)--AiGamePlay相关的逻辑，现在暂时不需要

    self:UpdateFightMode(dt) --战斗模式逻辑
end

---怪物配置主入口，除了Main其他配置都是空，用于MonsterBase自带的各种功能组件配置，类似读表。
function XRelinkMonsterBase:MonsterConfigMain()
    
    self:OverDriveConfig()  --OD系统配置
    self:BreakGaugeConfig()   --韧性系统配置
    self:SkillCastConfig()  --技能释放配置
    self:SkillTestConfig()  --技能测试配置
    
end

---OverDrive配置
function XRelinkMonsterBase:OverDriveConfig()
end

---韧性系统配置
function XRelinkMonsterBase:BreakGaugeConfig()
end

---技能释放配置
function XRelinkMonsterBase:SkillCastConfig()
end

---技能测试配置
function XRelinkMonsterBase:SkillTestConfig()
end

--endregion

--region 怪物流程-Awake

---创建怪物运行要用的变量
function XRelinkMonsterBase:MonsterRunVarAwake()
    self.skillConfigs = SkillConfigs
    self:SelfInfoAwake() --自己信息初始化变量
    self:AiControlAwake() --Ai控制初始变量设置
    self:SkillCdAwake() --技能CD初始变量设置
    self:OverDriveAwake() --OD初始变量设置
    self:BreakGaugeAwake() --韧性初始变量设置
    self:FightModeAwake() --战斗模式初始变量设置
    self:PhaseControlAwake() --阶段管理初始化变量
    self:TargetAwake() --目标相关初始化变量
    self:FollowComponentAwake() --跟随组件初始化变量
    self:SkillTestAwake() --技能测试变量初始化
end

---自己信息相关变量激活
function XRelinkMonsterBase:SelfInfoAwake()
    self.hpRate = 1           --自己生命百分比
    self.Pos = nil       --自己的位置
    self.fightTime = self._proxy:GetFightTime() --当前战斗时间
    self.npcTime = self._proxy:GetNpcTime(self._uuid) --当前Npc时间
end

---OverDrive变量激活
function XRelinkMonsterBase:OverDriveAwake()
    self.isOverDriveActive = true --是否开启Od系统，默认开启。
    self.isODValueFull = false --OD值是否满
    -------OD系统:OD-----------------------------------------
    self.curODState = XRelinkMonsterBase.ODState.None
    self.enterOverDriveSkill = nil --配置：进入OD的技能
    self.spSkill = nil --配置：Sp技能，进入OD后优先释放的。
    --OD系统:Breaking状态-----------------------------------------
    self.breakStartSkill = nil --配置：进入虚弱技能
    self.breakLoopSkill = nil --配置：虚弱循环技能
    self.breakEndSkill = nil --配置：退出虚弱时技能
end

---设置OverDrive开启状态（目前只能在配置里调用生效）
function XRelinkMonsterBase:SetOverDriveActive(isActive)
    self.isOverDriveActive = isActive
end

---韧性变量激活
function XRelinkMonsterBase:BreakGaugeAwake()
    self.isBreakGaugeActive = true --是否开启破韧系统，默认开启
    self.brokenSkill = nil --被破韧时释放的技能
    self.brokenRange = 40 --被破韧时多少米范围内的玩家可以使用破韧技能
end

---设置破韧系统是否开启
function XRelinkMonsterBase:SetBreakGaugeActive(isBreakGaugeActive)
    self.isBreakGaugeActive=(isBreakGaugeActive)
end

---战斗模式变量激活
function XRelinkMonsterBase:FightModeAwake()
    self.curFightMode = XRelinkMonsterBase.FightMode.NonCombat --默认没有在战斗
    self.enterCombatSkill = nil --这里可以配置吼叫技能作为入战技能
    self.outCombatTime = 15 --丢失目标多久后退出战斗

    self.haveODState = false --是否有OD那套逻辑
    self.havePreWander = false --是否调用前置游荡逻辑，技能判断前进行游荡判断。
    self.havePreTurn = false --是否有前置转身逻辑，技能判断前。
    self.haveSkillTurnFix = false --是否有技能转向修正
    self.haveCombo = false --是否有连招逻辑

    self.haveWander = false --是否开启游荡
    self.haveTurn90 = false --是否开启90度转身
    self.haveTurn180 = false --是否开启180度转身调整
    self.haveIrritation = false --是否开启烦躁技能
    ------------------下面的之后有可能会被干掉------------------------------------------
    ----行为类型-------------------
    self.currentActionType = XRelinkMonsterBase.ActionType.None
    self.lastActionType = XRelinkMonsterBase.ActionType.None
    self.lastAttackSkill = nil --上一次筛选攻击行为时筛选出来的技能，只有上一次ActionType是攻击时才保存

    ---追逐耐心--------------------------------------------开始追逐多少秒后失去耐心，尝试重新寻找目标。
    self.maxChasingPatience = 10 --追逐耐心时间，追逐持续时间不能超过这个时间，超过这个时间就会更换目标。
    self.currentChasingPatience = self.maxChasingPatience --当前追逐耐心时间。
    self.chasingMinStopDis = 8 --追逐最小停止距离
    self.chasingCurrentStopDis = self.chasingMinStopDis --当前追逐停止距离，经过计算得出来的。
    self.defaultChaseSkill = nil --默认追逐技能（
    self.nearChaseSkill = 0 --近距离使用的追逐技能（0表示用默认追逐技能，nil表示该距离下不使用追逐技能）
    self.midChaseSkill = 0 --中距离使用的追逐技能（0表示用默认追逐技能，nil表示该距离下不使用追逐技能）
    self.farChaseSkill = 0 --远距离使用的追逐技能（0表示用默认追逐技能，nil表示该距离下不使用追逐技能）
    self.soFarChaseSkill = 0 --超远距离使用的追逐技能（0表示用默认追逐技能，nil表示该距离下不使用追逐技能）
    -----基础配置-----------------------------------------
    self.basicDistanceReference = { 997, 998, 999 } --近中远距离配置，超过远距离则是超远，超远会直接开始追逐，没追逐逻辑就要发呆了。
    self.sight = 40 --度数，前后左右40度属于正/后，其他是侧面。

    self.publicAttackDesire = 10 --公共攻击欲望
    self.nearAttackDesire = 10 --近距离攻击欲望。
    self.midAttackDesire = 10 --中距离攻击欲望
    self.farAttackDesire = 10 --远距离攻击欲望
    self.attackDesire = 0 --攻击欲望，用来判断是否使用技能攻击的依据，公共攻击欲望+距离攻击欲望修正，作为行为判定里攻击的权重。

    ----攻击空间修正-----------------------------------------
    self.maxFixValue = 100 --每次攻击空间修正
    self.currentFixValue = self.maxFixValue --空间修正默认值

    ----技能空间修正：角度-----------------------------------------
    self.publicTurnDesire = 10--想要释放技能时角度修正欲望
    self.nearTurnDesire = 0
    self.midTurnDesire = 0
    self.farTurnDesire = 0
    self.TurnDesire = 0 --转身权重=距离权重+转身公共权重。

    self.turnFixConsume = 50 --每次转身消耗，不够消耗的时候修正失败
    self.turn90Skills = { --左/右转90度技能ID
    }
    self.turn180Skills = { --左/右转180度技能ID。
    }
    -----转身测试-----------------------------------------
    self._farDistTurnStopAngle = 67.5
    self._midDistTurnStopAngle = 42.5
    self._nearDistTurnStopAngle = 27.5

    self._turnSkillList = {
        [3] = 8001003, --右45
        [4] = 8001004, --左45
        [5] = 8001005, --右90
        [6] = 8001006, --左90
        [7] = 8001007, --右135
        [8] = 8001008, --左135
        [9] = 8001009, --后转
    }

    ----技能空间修正：距离-----------------------------------------
    self.publicDistanceFixDesire = 10--想要释放技能时距离修正欲望
    self.nearDistanceFixDesire = 0
    self.midDistanceFixDesire = 0
    self.farDistanceFixDesire = 0
    self.DistanceFixDesire = 0 --距离修正权重=公共距离修正+根据距离类型权重。

    self.maxTurnValue = 100 --转身值
    self.currentTurnValue = self.maxTurnValue --当前转身值
    self.turnConsume = 50 --每次转身消耗，不够消耗的时候转身将会失败。
    self.turn90Skills = { --左/右转90度技能ID
    }
    self.turn180Skills = { --左/右转180度技能ID。
    }
    self.forwardSkillList = {  } --向前调整位置技能，距离从近到远排序，优先使用近的。
    self.backSkill = nil --向后调整位置技能

    ----游荡技能-----------------------------------------
    self.nearWanderDesire = 0
    self.midWanderDesire = 0
    self.farWanderDesire = 0
    self.wanderDesire = 0 --游荡权重=距离权重，用来筛选游荡行为的。

    self.wanderSkill = {} --左右游荡技能ID。
    self.wanderWeight = {} --左右游荡权重。
    self.maxWanderDesire = 100 --游荡值
    self.wanderConsume = 50 --每次游荡消耗的值，不够游荡时判定失败。

    self.skillInfoConfigList = {}
    self.selectSkillType = XRelinkMonsterBase.SelectSkillType.None --默认不放技能
    self.skillLayer = XRelinkMonsterBase.SkillLayer.Normal --普通层技能释放
    self.lockedSkillList = {} --锁定技能列表，被锁定的技能无法释放

    self.AllSkillList = {} --自己的所有技能列表，到时候遍历赋值。
    --normal技能释放列表
    self.normalSkillList = {} --普通技能筛选列表。
    self.sequenceSkillList = {} --顺序技能列表
    --角度释放列表--
    self.frontSkillList = {}    --前
    self.backSkillList = {}     --后
    self.leftSkillList = {}     --左
    self.rightSkillList = {}    --右

    --距离释放技能列表--
    self.nearSkillList = {}      --近距离技能列表
    self.midSkillList = {}     --中距离技能列表
    self.farSkillList = {}     --远距离技能列表

    --距离释放技能列表--
    self.nearSkillList = {}      --近距离技能列表
    self.midSkillList = {}     --中距离技能列表
    self.farSkillList = {}     --远距离技能列表


    self.castGroup = {} --初始化技能释放组
    self.SkillsCds = {} --保存技能组Id+Cd的表

    --筛选信息
    self.SelectActionInfo = { --筛选信息
        CurActionType = nil,
        SkillId = nil,
        Wander = nil,
        Turn = nil,
        LastActionType = nil,
    }
    -------Order释放模式----------------------------
    self.orderSkillList = {} --按序号放技能的列表
    self.nextSkillOrder = 1 --下一个攻击的序号
end

---目标变量激活
function XRelinkMonsterBase:TargetAwake()
    self.target = nil               --战斗目标，会在战斗模式下更新
    self.targetHpPercent = 0            --目标血量百分比
    self.targetPos = nil     --目标当前坐标位置
    self.targetDistance = 0               --和目标距离
    self.targetDistanceType = XRelinkMonsterBase.DistanceType.None --和目标的距离类型
    self.targetSpaceType = nil --目标在自己当前哪个方位

    ------- 周围敌人列表相关 --------------------------------
    self.vigilantRange = 20 --索敌用的范围。
    self.vigilantRangeEnemyList = {} --警戒范围内的敌人列表
    self.vigilantRangeEnemyListUpdateTimeOnCombatMode = 10 --战斗模式下更新敌人列表频率
    self.vigilantRangeEnemyListUpdateTimer = self.fightTime --更新敌人列表的计时器
end

---阶段管理变量激活
function XRelinkMonsterBase:PhaseControlAwake()
    self.curPhase = 1 --当前阶段
    self.phaseSwitchType = XRelinkMonsterBase.PhaseSwitchType.None --切阶段类型，Nonc就是不切阶段。
    self.PhaseHpConditon = { --血量切阶段配置，少于等于这个比例时切换阶段
        [1] = 70,
        [2] = 50,
        [3] = 30,
    }
    self.PhaseHpConditon = { --血量切阶段配置，少于等于这个比例时切换阶段
        [1] = 70,
        [2] = 50,
        [3] = 30,
    }
    self.PhaseTimeLineConditon = { --根据TimeLine切阶段，按照FightTime来切阶段。
        [1] = 999,
        [2] = 9999,
        [3] = 30,
    }
    self.phaseSwitchSkillList = { --根据不同阶段使用切阶段技能，有切阶段技能的需要等切阶段的技能释放后才算切阶段成功。
    }
end

---整个AI控制变量激活
function XRelinkMonsterBase:AiControlAwake()
    self.isAiOpen = true --总AI开关
    self.isCombatModeAiOpen = true  --是否调用战斗模式逻辑
    self.isCombatLogicAiOpen = true --是否调用战斗逻辑
end

---根据技能配置初始化技能Cd
function XRelinkMonsterBase:SkillCdAwake()
    self.SkillCds = {} --初始化技能CD保存用
    local fightTime = self._proxy:GetFightTime() --获取战斗时间
    for skill, config in pairs(SkillConfigs) do
        --如果有配置初始化Cd的就设置cd
        local cd = config.InitCd
        if cd then
            self.SkillCds[skill] = fightTime + cd
        end
    end
end

---跟随组件变量激活
function XRelinkMonsterBase:FollowComponentAwake()
    -----移动组件--------------------------
    ---@type XNpcFollowController
    self.followTargetMinDis = 1
    self.followTargetMaxDis = 3
    self.followTargetHeartBeat = 1
    self._followController = XNpcFollowController.New(self._proxy, self._uuid) --New跟随组件
end

--endregion

--region 怪物流程-Init

---怪物运行前初始化，根据构造变量和配置进行初始化
function XRelinkMonsterBase:MonsterRunInit()
    self:OverDriveInit() --OD初始化
    self:BreakGaugeInit() --韧性初始化
    self:SkillTestInit()--技能测试初始化
end

---OD系统初始化
function XRelinkMonsterBase:OverDriveInit()
    
    if not self.isOverDriveActive then
        return
    end
    
    --TODO可能存在怪物不需要OD功能的情况，当前默认开启
    self._proxy:SetNpcOverDriveActive(self._uuid,true)--激活OD功能
    --监听事件
    self._proxy:RegisterEvent(EWorldEvent.NpcEnterOverDrive)       --Npc进入OD
    self._proxy:RegisterEvent(EWorldEvent.NpcOverDriveFull)       --当NpcOD满了
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakBefore)   --NpcODBreak前
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakAfter)   --NpcODBreak后
    self._proxy:RegisterEvent(EWorldEvent.NpcODExitBreakAfter)-- NpcOD退出Break
end

---韧性系统初始化
function XRelinkMonsterBase:BreakGaugeInit()

    if not self.isBreakGaugeActive then--是否开启破韧系统
        return
    end
    
    --TODO可能存在怪物不需要韧性的情况，当前默认开启
    self._proxy:SetNpcBreakGaugeActive(self._uuid,true)--激活韧性条功能
    
    --监听事件
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenBefore)       --监听Npc破韧前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter)       --监听Npc破韧后事件
end

--endregion

--region 战斗流程

---战斗模块主流程,负责分发所有战斗流程.
function XRelinkMonsterBase:UpdateCombatMode(dt)

    --TODO 受击也会执行
    --1：战斗逻辑开始前，不包括目标选择，状态检查也没有,一般就不要在这里写逻辑了。
    self:BeforeCombatLogic(dt)
    
    --战斗模块
    if not self.isCombatModeAiOpen then
        --战斗逻辑总开关
        --XLog.Warning("1")
        return
    end
    
    self:SelectTargetByThreat(dt) --根据仇恨选择目标

    if not self:CheckTargetValid() then
        --目标有效性检查，无效则不执行后续逻辑
        --XLog.Warning("2")
        return
    end

    self:UpdateTargetInfo()  --更新目标相关信息

    --2：战斗前置逻辑，当前已有目标，但行为是不确定的
    self:PreCombatLogic(dt)

    if not self:CheckSelfActionValid() then
        --行为有效性检查
        return
    end

    --3：确保了目标、行为都是有效的，正式进入战斗逻辑流程
    self:MainCombatLogic(dt) --核心战斗逻辑

end

---战斗逻辑执行前，不包括任何状态或条件检测，默认空逻辑
function XRelinkMonsterBase:BeforeCombatLogic(dt)
    
end

---战斗前置逻辑，通常为空，自定义编辑的地方。
function XRelinkMonsterBase:PreCombatLogic(dt)

end

---核心战斗逻辑，里面的逻辑都跟配置绑定。
function XRelinkMonsterBase:MainCombatLogic(dt)
    self:SelectAction() --行为筛选，处理好要做的事情。
    self:DoAction(dt) --行为执行，根据行为筛选出来的事情去执行，用来处理执行前和执行后的逻辑。
end
--endregion

--region 战斗模式


---检查自己是不是通常意义上的可行动
function XRelinkMonsterBase:CheckSelfActionValid()
    if self._proxy:CheckNpcAction(self._uuid, ENpcAction.Skill) then--正在释放技能
        if not self._proxy:CheckNpcCurSkillIsDone(self._uuid)then--自己技能没有完成时，无效。
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

    return true--以上无效判断都不通过时，
end
--非战斗模式逻辑
function XRelinkMonsterBase:UpdateNonCombatMode(dt)
    --非战斗模块
    return --非战斗下现在啥也不干
end
--GamePlay逻辑
function XRelinkMonsterBase:UpdateGamePlayLogic(dt)
    self:UpdatePhaseSystem(dt) --阶段管理系统，Update检测自己是否要转阶段了
end
--更新自己相关的基础信息
function XRelinkMonsterBase:UpdateSelfBaseInfo()
    ---生命百分比
    local maxHp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    local curHp = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    self.hpRate = curHp / maxHp--生命百分比
    --BK值暂时没有
    self.fightTime = self._proxy:GetFightTime() --更新战斗时间
    self.npcTime = self._proxy:GetNpcTime(self._uuid) --更新Npc时间
    self.Pos = self._proxy:GetNpcPosition(self._uuid) --更新位置
    self:UpdateVigilantRangeEnemyList() --更新警戒范围内敌人列表
end

---更新警戒范围内敌人列表
function XRelinkMonsterBase:UpdateVigilantRangeEnemyList()
    if self.fightTime < self.vigilantRangeEnemyListUpdateTimer then
        --CD控制器
        return
    end
    --搜索周围敌人列表
    self.vigilantRangeEnemyList = {}--清空周围敌人列表
    self.vigilantRangeEnemyList = self:GetEnemyListInRange(self.vigilantRange)--设置为警戒范围内的敌人
    if self.curFightMode == XRelinkMonsterBase.FightMode.Combat then
        --设置刷新警戒范围内敌人列表的时间，战斗模式下的CD
        self.vigilantRangeEnemyListUpdateTimer = self.fightTime + self.vigilantRangeEnemyListUpdateTimeOnCombatMode --战斗时更新警戒范围敌人列表的CD
    end
end

---获取范围内的敌人列表
function XRelinkMonsterBase:GetEnemyListInRange(range)
    local npcList = self._proxy:GetNpcList()
    local tempNpcList = {}

    for i, npc in pairs(npcList) do
        local distance = self._proxy:CalcNpcDistance(self._uuid, npc) --计算和目标的距离
        if distance < range and self:IsEnemy(npc) then --在范围内的敌人
            table.insert(tempNpcList, npc) --插入Npc
        end
    end
    --XLog.Warning(tempNpcList)
    return tempNpcList
end

--判断Npc是否是敌人
function XRelinkMonsterBase:IsEnemy(npc)
    if npc == self._uuid then
        --自己就跳过
        return false
    end
    if self._proxy:CompareNpcCamp(self._uuid, npc) then
        --同阵营也跳过
        return false
    end
    return true
end

--根据仇恨选择目标
function XRelinkMonsterBase:SelectTargetByThreat(dt)
    --根据仇恨选择目标

    if not self._proxy:CheckThreatList(self._uuid) then
        --仇恨列表为空时，清空目标。
        self:ClearTarget() --清空目标
        return
    end

    --仇恨列表有Npc的时候就选择最大仇恨值的目标为战斗目标。
    self.target = self._proxy:GetMaxThreatNpc(self._uuid) --默认选择最大仇恨值目标作为目标
    self._proxy:SetFightTarget(self._uuid, self.target)
end

--清除目标信息
function XRelinkMonsterBase:ClearTarget()
    self.target = nil
    self._proxy:RemoveFightTarget(self._uuid)
end

--更新战斗模式的战斗信息
function XRelinkMonsterBase:UpdateFightInfo()
    --更新战斗信息

end
--检查目标有效性
function XRelinkMonsterBase:CheckTargetValid()

    if (self.target == 0) or (not self.target) then
        return false
    end

    if not self._proxy:CheckNpc(self.target) then
        return false
    end

    return true
end
---更新和战斗目标相关信息
function XRelinkMonsterBase:UpdateTargetInfo()
    self.targetHpPercent = self._proxy:GetNpcAttribRate(self.target, ENpcAttrib.Life)
    self.targetPos = self._proxy:GetNpcPosition(self.target)
    self.targetDistance = self._proxy:CalcNpcDistance(self._uuid, self.target) --获取距离

    --更细和目标的距离类型
    if self.targetDistance <= self.basicDistanceReference[1] then
        --近距离
        self.targetDistanceType = XRelinkMonsterBase.DistanceType.Near
    elseif self.targetDistance <= self.basicDistanceReference[2] then
        --中距离
        self.targetDistanceType = XRelinkMonsterBase.DistanceType.Mid
    elseif self.targetDistance <= self.basicDistanceReference[3] then
        --远距离
        self.targetDistanceType = XRelinkMonsterBase.DistanceType.Far
    else
        self.targetDistanceType = XRelinkMonsterBase.DistanceType.SoFar  --超远距离
    end
end
--检查和更新战斗模式
function XRelinkMonsterBase:UpdateFightMode(dt)
    if self.curFightMode == XRelinkMonsterBase.FightMode.Combat then
        --战斗模块
        if self:OutCombatCheck() then
            --检查退出战斗成功
            return
        end
        self:UpdateCombatMode(dt) --战斗模块逻辑
    elseif (self.curFightMode == XRelinkMonsterBase.FightMode.NonCombat) then
        --非战斗模块
        if self:EnterCombatCheck() then
            --检查进入战斗
            return
        end
        self:UpdateNonCombatMode(dt) --运行非战斗模块逻辑
    end
end
---找到最近的敌人触发战斗
function XRelinkMonsterBase:EnterCombatCheck()
    --进入战斗检测
    -----------------仇恨列表触发战斗------------------------------------
    if self._proxy:CheckThreatList(self._uuid) then
        --仇恨列表不为空
        self:EnterCombatByNpc(self._proxy:GetMaxThreatNpc(self._uuid)) --被一仇触发战斗
        return true
    end

    -------------------靠近触发战斗-----------------------------------
    if #self.vigilantRangeEnemyList < 1 then
        --周围没有敌人时进入战斗失败
        return false
    end
    local nearestEnemy = self:FindNearestEnemy()--从警戒列表里找到最近的目标
    self:EnterCombatByNpc(nearestEnemy) --触发战斗方式为被Npc触发了
    return true
end

---没有一点点防备,也没有一丝顾虑，私自入战
function XRelinkMonsterBase:EnterCombat()
    self.curFightMode = XRelinkMonsterBase.FightMode.Combat --战斗模式设置为入战
    if self.enterCombatSkill then
        --有入战技能的时候使用入战斗技能：吼叫
        self._proxy:CastAction(self._uuid, self.enterCombatSkill)
    end
end

--被Npc触发战斗了，需要做点什么
function XRelinkMonsterBase:EnterCombatByNpc(triggerNpc)
    self.curFightMode = XRelinkMonsterBase.FightMode.Combat  --进入战斗模式

    if self.enterCombatSkill and self._proxy:CheckCanCastSkill(self._uuid) then
        --有配置技能且可释放技能的情况下，释放入战技能。
        self._proxy:CastActionToTarget(self._uuid, self.enterCombatSkill, triggerNpc)
    end
    if not self._proxy:CheckNpcInThreatList(self._uuid, triggerNpc) then
        self._proxy:ApplyMagic(self._uuid, triggerNpc, 8052000, 1) --触发的Npc给自己添加1仇恨，用来添加进仇恨列表
    end
    -----进入战斗时把其他玩家一起拉进战斗---------------------------------------
    local npcList = self._proxy:GetNpcList()
    for i, npcUUID in pairs(npcList) do
        --把所有敌人拉进仇恨列表
        if self:IsEnemy(npcUUID) and (not self._proxy:CheckNpcInThreatList(self._uuid, npcUUID)) then
            --所有不在仇恨列表的敌人都存进仇恨列表
            self._proxy:ApplyMagic(self._uuid, npcUUID, 8052000, 1)
        end
    end
    self:SetTarget(triggerNpc) --将目标设置为触发战斗的Npc
end

---寻找最近目标
function XRelinkMonsterBase:FindNearestEnemy()
    local target = nil
    local lastDistance = 0

    if #self.vigilantRangeEnemyList < 1 then
        --没有Npc了
        return nil
    end
    for i, npc in pairs(self.vigilantRangeEnemyList) do
        --遍历警戒范围内的敌人，找到最近的

        local distance = self._proxy:CalcNpcDistance(self._uuid, npc) --计算和目标的距离

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
function XRelinkMonsterBase:FindNearestEnemyByPos(pos)
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

--设置怪物目标
function XRelinkMonsterBase:SetTarget(npc)
    self.target = npc
    self._proxy:SetFightTarget(self._uuid, npc)

    --设置该目标为移动目标
    local followTargetMinDis = self.followTargetMinDis
    local followTargetMMaxDis = self.followTargetMaxDis
    local followTargetHeartBeat = self.followTargetHeartBeat
    self._followController:SetFollowTargetNpcNoNavMesh(self.target, followTargetMinDis, followTargetMMaxDis, followTargetHeartBeat)  --跟随目标设置成当前目标
end
--移除怪物目标
function XRelinkMonsterBase:RemoveMonsterTarget()
    self.target = nil
    self._proxy:RemoveMonsterTarget(self._uuid)
    --取消移动组件
    self._followController:CancelFollow() --清空移动组件
end
--检查退出战斗
function XRelinkMonsterBase:OutCombatCheck()
    local target = self.target
    local isOutBattle = false
    if (target == 0) or (not target) then
        self:OutCombat() --退出战斗
        return true
    end

    if not self._proxy:CheckNpc(target) then
        self:OutCombat() --退出战斗
        return true
    end

    if self._proxy:CheckNpcFullActionState(target, ENpcAction.Dying, -1) or self._proxy:CheckNpcFullActionState(target, ENpcAction.Death, -1) then
        self:OutCombat() --退出战斗
        return true
    end

    return isOutBattle
end
--退出战斗时
function XRelinkMonsterBase:OutCombat()
    self.curFightMode = XRelinkMonsterBase.FightMode.NonCombat
    self:ClearTarget() --清除目标相关东西
end
--endregion

--region 行为：基础
--行为筛选
function XRelinkMonsterBase:SelectAction()
    local skill = nil
    local wander = nil
    --连招筛选
    skill = self:SelectCombo()--连招选择
    if skill then
        self.SelectActionInfo.CurActionType = XRelinkMonsterBase.ActionType.Attack
        self.SelectActionInfo.SkillId = skill
        return
    end

    --超远距离
    if self.targetDistanceType == XRelinkMonsterBase.DistanceType.SoFar then
        self.SelectActionInfo.CurActionType = XRelinkMonsterBase.ActionType.Chase
        return
    end

    --游荡：前置游荡判断
    wander = self:PreWander()
    if wander then
        self.SelectActionInfo.CurActionType = XRelinkMonsterBase.ActionType.Wander
        self.SelectActionInfo.Wander = wander
        return
    end

    --转身：前置转身

    --技能筛选--
    skill = self:SelectSkill()
    if skill then
        self.SelectActionInfo.CurActionType = XRelinkMonsterBase.ActionType.Attack
        self.SelectActionInfo.SkillId = skill
        --筛选技能成功
        return
    end

    --通用游荡
    if self:CommonWander() then
        self.SelectActionInfo.CurActionType = XRelinkMonsterBase.ActionType.Wander
        self.SelectActionInfo.Wander = wander
        return
    end

    --没有任何想做的，就追逐目标。
    self.SelectActionInfo.CurActionType = XRelinkMonsterBase.ActionType.Chase
    return

end
--执行行为
function XRelinkMonsterBase:DoAction(dt)
    local actionType = self.SelectActionInfo.CurActionType
    if actionType == XRelinkMonsterBase.ActionType.Chase then
        --追逐
        self:Chasing()
    elseif actionType == XRelinkMonsterBase.ActionType.Attack then
        --攻击
        self:Attack()
    end
end
--DoAction过程中发生意外了，需要重新选择行为。
function XRelinkMonsterBase:ReSelectAction()

end
--检查目标是否在角度范围内
function XRelinkMonsterBase:IsTargetInMyAngle(angle)
    return self._proxy:CheckNpcInAngle(self._uuid, self.target, angle)
end
--游荡
function XRelinkMonsterBase:Wander()

end
--技能释放过程中的转身调整
function XRelinkMonsterBase:TurnAround()

end
--攻击行为
function XRelinkMonsterBase:Attack()
    if self:ForceSkillToNpc(self.SelectActionInfo.SkillId, self.target) then
        --强制释放这个技能
        self:OnActionDone(XRelinkMonsterBase.ActionType.Attack)
    end
    --if self._proxy:CastActionToTarget(self._uuid,self.SelectActionInfo.SkillId,self.target) then
    --    
    --end
end
--当Action结束
function XRelinkMonsterBase:OnActionDone(action)
    if action == XRelinkMonsterBase.ActionType.Attack then
        self.SelectActionInfo.SkillId = nil
    end

    self.SelectActionInfo.CurActionType = nil
    self.SelectActionInfo.LastActionType = action

end
--endregion

--region 行为：追逐
--追逐目标
function XRelinkMonsterBase:Chasing(dt)
    --XLog.Warning("向Npc移动")
    --调用跟随组件，需要补充其他追逐逻辑，比如是否优先使用追逐技能。
    --self._followController:SetFollowTargetNpcNoNavMesh(self.target, self.followTargetMinDis, self.followTargetMaxDis, self.followTargetHeartBeat)
    --self._followController:Update(dt)  --调用跟随组件走向目标
end

--追逐测试
function XRelinkMonsterBase:ChasingTest()
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
function XRelinkMonsterBase:TurnTest()
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
function XRelinkMonsterBase:SelectCombo()

end
--前置游荡
function XRelinkMonsterBase:PreWander()

end
--后置游荡，技能释放结束后游荡
function XRelinkMonsterBase:CommonWander()

end
--筛选技能
function XRelinkMonsterBase:SelectSkill()
    if self.selectSkillType == XRelinkMonsterBase.SelectSkillType.NormalSequence then
        --普通技能筛选，按照技能列表从左到右判断是否满足释放条件
        return self:NormalSequenceSelectSkill() --按从左到右顺序筛选技能
    end
    if self.selectSkillType == XRelinkMonsterBase.SelectSkillType.RandomSequence then
        --普通技能筛选，按照技能列表从左到右判断是否满足释放条件
        return self:RandomSequenceSelectSkill() --普通列表随机筛选技能
    end
    if self.selectSkillType == XRelinkMonsterBase.SelectSkillType.CastGroup then
        --普通技能筛选，按照技能列表从左到右判断是否满足释放条件
        return self:CastGroupSelectSkill() --按照技能释放组里的权重筛选出一个可以释放的技能
    end
    return nil
end
--普通顺序筛选技能
function XRelinkMonsterBase:NormalSequenceSelectSkill()
    if #self.sequenceSkillList < 1 then
        --技能列表为空
        return nil
    end
    for index, skill in pairs(self.sequenceSkillList) do
        if self:CheckSkillCondition(skill) then
            --检查技能条件
            return skill
        end
    end
end
--普通随机筛选
function XRelinkMonsterBase:RandomSequenceSelectSkill()
    if #self.sequenceSkillList < 1 then
        --技能列表为空
        return nil
    end

    local skillIndex = self._proxy:Random(1, #self.sequenceSkillList)
    local skillId = self.sequenceSkillList[skillIndex]

    return skillId
end
--技能释放组
function XRelinkMonsterBase:CastGroupSelectSkill()
    if #self.castGroup < 1 then
        --没有配置技能直接返回
        return
    end
    return self:GetAbleSkillToTargetByNpcCastGroup()
end
--endregion

--region 行为：游荡

--endregion

--region 阶段管理

---更新阶段管理系统
function XRelinkMonsterBase:UpdatePhaseSystem(dt)

    if self.phaseSwitchType == XRelinkMonsterBase.PhaseSwitchType.None then
        --没有切阶段逻辑
        return
    end

    if self:SwitchPhaseCondition() then
        --满足切阶段条件时
        self:TrySwitchPhase() --尝试切换阶段
    end
end

--判断阶段切换条件
function XRelinkMonsterBase:SwitchPhaseCondition()
    local hpCondition = self.PhaseHpConditons[self.curPhase]
    local fightTime = self.fightTime
    local timeLineCondition = self.PhaseTimeLineConditons[self.curPhase]

    if (self.phaseSwitchType == XRelinkMonsterBase.PhaseSwitchType.Hp) and (hpCondition) and (self.hpRate <= hpCondition) then
        --根据血量切换阶段
        return true
    end

    if (self.phaseSwitchType == XRelinkMonsterBase.PhaseSwitchType.TimeLine) and (timeLineCondition) and (self.fightTime >= fightTime) then
        --根据关卡时间切换阶段
        return true
    end

    return false
end

--尝试切换阶段
function XRelinkMonsterBase:TrySwitchPhase()

    if self.phaseSwitchSkillList[self.curPhase] then
        --有切换阶段技能。
        if self._proxy:CastAction(self._uuid, self.phaseSwitchSkillList[self.curPhase]) then
            self.curPhase = self.curPhase + 1 --阶段+1
        end
    else
        self.curPhase = self.curPhase + 1 --没有技能，直接切换阶段
    end

end
--endregion

--region 韧性系统

---当自己受伤时处理韧性系统
function XRelinkMonsterBase:HandleBrokenGaugeOnGetDamage(magicId)
    if magicId ~= 10519201 then --QTE伤害Magic
        return
    end
    if not self._proxy:CheckBuffByKind(self._uuid,8005901) then--判断自己是否不存在破韧可QTE的标记
        return
    end
    self:BeBrokenHit() --破韧受击
end

---被破韧后
function XRelinkMonsterBase:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId)
    self:BeBrokenHit() --破韧受击
    self._proxy:ApplyMagic(self._uuid,self._uuid,8005901,1) --给自己上破韧畏缩状态
    self:ApplyMagicToEnemyInRange(8005902,1,self.brokenRange)--给周围玩家上可释放QTEMagic
end

---破韧受击
function XRelinkMonsterBase:BeBrokenHit()
    self:ForceSkill(self.brokenSkill) --释放破韧技能
end


--endregion

--region OverDrive系统

---设置OverDrive值直接变满
function XRelinkMonsterBase:SetOverDriveValueFull()
    local maxValue = self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.OverDrive)
end

---清空OverDrive值
function XRelinkMonsterBase:ClearOverDriveValue()

end

---当自己受伤时处理OD系统
function XRelinkMonsterBase:HandleOverDriveOnGetDamage()
    --XLog.Warning("受伤检查OD系统")
    if not self:CheckCanOverDrive() then--检查是否满足进入OD条件
        return false
    end
    self:EnterOverDriveState()--进入OD
end
   
---检查自己当前是否可以进入OD    
function XRelinkMonsterBase:CheckCanOverDrive()
    
    if not self.isODValueFull then--OD值没满不可以进入OD
        return false
    end

    if not self:CheckSelfActionValid() then --检查行动有效性
        return false
    end
    
    return true
end

---当进入OD时
function XRelinkMonsterBase:OnOverDrive()
    
end

---当虚弱时
function XRelinkMonsterBase:OnBreak()

end

---当OD值满时    
function XRelinkMonsterBase:OnNpcOverDriveFull(targetUUID)
    if targetUUID ~= self._uuid then--非自己OD满直接返回
        return
    end
    self.isODValueFull = true --设置自己OD值是满的。
end

---当进入Break后
function XRelinkMonsterBase:OnNpcODBreakAfter(targetUUID)
    self:ForceSkill(self.breakStartSkill) --强制释放BreakStart技能
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052040,1) --去掉OD的通用特效
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000469,1) --锁定削韧
end

---当退出Break后
function XRelinkMonsterBase:OnNpcODExitBreakAfter(targetUUID)
    self:OnExitBreak()--退出Break
end

--检查是否要进入OD吧
function XRelinkMonsterBase:UpdateODNormalState(dt)
    --NormalUpdate

end

---更新ODState
function XRelinkMonsterBase:UpdateODODState(dt)
    --ODUpate

end

---更新Break状态
function XRelinkMonsterBase:UpdateODBreakingState(dt)
    --BreakingUpdate
end

---进入OD状态
function XRelinkMonsterBase:EnterOverDriveState()
    if not self.enterOverDriveSkill then --没有配置OD技能
        XLog.Warning("未配置进入OD技能，目前暂不支持无OD技能进入OD。")
        return false
    end
    
    if self:ForceSkillToTarget(self.enterOverDriveSkill) then--对战斗目标强制释放OD技能
        self.isODValueFull = false
        return true
    end
    
    if self:ForceSkill(self.enterOverDriveSkill) then--无战斗目标强制释放
        self.isODValueFull = false
        return true
    end
    self:OnEnterOverDrive() --进入OverDrive
end

---进入OD状态
function XRelinkMonsterBase:OnEnterOverDrive()
    --正常退出OD
    self.curPhase = self.curPhase + 1
    --怪物阶段+1
end

---进入虚弱状态
function XRelinkMonsterBase:OnEnterBreak()
    self:ForceSkill(self.breakEndSkill)  --释放退出Break技能
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000470,1) --移除锁定削韧
    --进入进入虚弱
end

---退出虚弱状态
function XRelinkMonsterBase:OnExitBreak()
    --退出虚弱
end

--endregion

--region AI控制

---是否关闭Ai总开关，不包括测试技能AI
function XRelinkMonsterBase:SetAiActive(isActive)
    self.isAiOpen = isActive   --是否关闭战斗Ai：指会对玩家造成威胁的Ai
end

---设置战斗模式AI
function XRelinkMonsterBase:CombatModeAiSwitch(isActive)
    --Ai战斗模式开关，入战和退出都不会走
    self.isCombatModeAiOpen = isActive
end

--endregion

--region 事件监听处理
function XRelinkMonsterBase:InitEventCallBackRegister()
    ------全局事件-----------------------------------
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- 添加buff时
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- Npc受伤伤害时
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction)            -- 退出Action时
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)            -- Npc死亡时
    self._proxy:RegisterEvent(EWorldEvent.NpcRevive)            -- Npc复活时
end
--endregion

--region 事件执行处理

function XRelinkMonsterBase:OnNpcDieEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
    XLog.Warning(npcUUID.."死亡了")
    
end

function XRelinkMonsterBase:OnNpcReviveEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
    XLog.Warning(npcUUID.."复活了")
end

---添加buff时事件
function XRelinkMonsterBase:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 1010027 then
        --AI战斗逻辑开启
        self:SetCombatAiActive(true)
    end

    if buffId == 1010028 then
        --AI战斗逻辑开启
        self:SetCombatAiActive(false)
    end
end

---受伤时事件
function XRelinkMonsterBase:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    Base.OnNpcDamageEvent(self,launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if targetId ~= self._uuid then --只监听自己受到的伤害
        return
    end
    self:HandleOverDriveOnGetDamage() --受伤时处理OD系统
    self:HandleBrokenGaugeOnGetDamage(magicId) --受伤时处理破韧系统
end

---退出Action时事件
function XRelinkMonsterBase:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end
    
    if skillId == self.breakStartSkill then --结束的是不是虚弱开始技能
        self:ForceSkill(self.breakLoopSkill) --释放虚弱循环技能
    end
end

--endregion

--region 怪物本身脚本的工具函数
---概率成功，输入概率，返回是否成功
function XRelinkMonsterBase:GetRandomSuccess(maybe)
    local isSuccess = false
    if self._proxy:Random(0, 100) < maybe then
        isSuccess = true
    end
    return isSuccess
end

---Magic给范围内的敌人
function XRelinkMonsterBase:ApplyMagicToEnemyInRange(magicId,level,range)
    local npcList = self:GetEnemyListInRange(range)
    XLog.Warning(npcList)
    for i, npc in pairs(npcList) do
        XLog.Warning("周围敌人"..npc)
        self._proxy:ApplyMagic(self._uuid,npc,magicId,level)
    end
end

---判断值是否在table中
function XRelinkMonsterBase:IsInTable(table, value)
    if #table < 0 then
        return false
    end

    for i = 1, #table do
        --在表格内
        if table[i] == value then
            return true
        end
    end

    return false
end

---技能锁定有效性判断
function XRelinkMonsterBase:IsSkillLockedValid(skill)
    if not self:IsInTable(self.lockedSkillList, skill) then
        --是否在锁定列表里
        return true
    end
    return false --在列表返回False
end

---通常的检查技能条件,目标是按照Ai的战斗目标去判断
function XRelinkMonsterBase:CheckSkillCondition(skill)
    --技能锁定有效性判断
    if not self:IsSkillLockedValid(skill) then
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
    if not self:IsSkillDistanceValid(skill) then
        return false
    end
    --释放角度有效性判断
    if not self:IsSkillAngleValid(skill) then
        --只是不满足角度的话，还有一丝丝希望
        return false
    end
    return true
end

---检查怪物配置的技能条件,目标是判断传入的目标
function XRelinkMonsterBase:CheckSkillConditionByNpc(skill, npc)
    --技能锁定有效性判断
    if not self:IsSkillLockedValid(skill) then
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
function XRelinkMonsterBase:IsSkillODStateValid(skill)
    local config = SkillConfigs[skill]
    if not config then
        return true
    end
    local need = config.ODStateNeed
    if not need then
        return true
    end
    if #need < 1 then
        return true
    end
    for i, state in pairs(need) do
        --当前状态在里面
        if state == self.curODState then
            return true
        end
    end

    return false
end

---对自己阶段有效性判断
function XRelinkMonsterBase:IsSkillPhaseValid(skill)
    local config = SkillConfigs[skill]
    if not config then
        return true
    end
    local needs = config.PhaseNeed
    if not needs then
        return true
    end
    if #config[PhaseNeed] < 1 then
        return true
    end

    for i, phase in pairs(needs) do
        --里面有状态和自己状态是一样的
        if phase == self.curPhase then
            return true
        end
    end

    return false
end

---自己血量有效性判断
function XRelinkMonsterBase:IsSkillHpValid(skill)
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
function XRelinkMonsterBase:IsSkillDistanceValid(skill)
    XLog.Warning("技能距离")
    XLog.Warning(self.targetDistance)
    return self:CheckSkillDistance(skill, self.targetDistance) --传入目标距离去检查
end

--传入技能和距离检查距离是否满足技能配置的释放条件
function XRelinkMonsterBase:CheckSkillDistance(skill, distances)
    --if skill == 805221 then
    --    XLog.Warning(skill)
    --end
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
    if #needs == 1 then
        return distances <= needs[1]--是否小于等于距离要求
    end
    --是否大于等于最小And小于等于最大
    return (distances >= needs[1]) and (distances <= needs[2])
end

---检查Npc的距离
function XRelinkMonsterBase:CheckSkillDisByNpc(skill, npc)
    if not self._proxy:CheckNpc(npc) then
        XLog.Warning("NPC非法,CheckSkillDisByNpc不通过" .. npc)
        return false
    end
    local dis = self._proxy:CalcNpcDistance(self._uuid, npc)
    return self:CheckSkillDistance(skill, dis)
end

---检查和目标距离是否在范围内
function XRelinkMonsterBase:CheckDisByTarget(distances)
    return distances <= self.targetDistance
end

--释放角度有效性判断
function XRelinkMonsterBase:IsSkillAngleValid(skill)
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
function XRelinkMonsterBase:IsSkillTurnFixValid(skill)
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
--endregion

--region 技能测试

---技能测试变量激活
function XRelinkMonsterBase:SkillTestAwake()
    self.isSkillTestOpen = false --技能测试开关，开了后会运行调试模式
    self.skillTestId = nil --测试的技能ID
    self.skillTestCd = 5 --测试技能CD，CD进入方式都是从上一个技能释放成功开始
    self.skillTestInitialCd = 2 --测试技能初始CD
end

---技能测试初始化
function XRelinkMonsterBase:SkillTestInit()
    self.skillTestTimer = self._proxy:GetFightTime() + self.skillTestInitialCd --设置初始CD
    self:UpdateVigilantRangeEnemyList()--更新警戒范围敌人列表
    self:SetTarget(self:FindNearestEnemy()) --找到最近的敌人作为战斗目标
end

---技能配置测试模块
function XRelinkMonsterBase:UpdateSkillTest()
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
    self:ForceSkillToTarget(self.skillTestId) --对战斗目标强制释放技能
    local pos  ={x=83,y= 1.87,z= 54.44}
    self.skillTestTimer = self._proxy:GetFightTime() + self.skillTestCd --释放成功，设置测试CD
end
--endregion

--region 技能释放处理工具
--对战斗目标释放技能
---怪物对npc释放技能,会进行一系列怪物侧配置的条件判断
function XRelinkMonsterBase:CastSkillToNpc(skill, npc)
    if not self._proxy:CheckNpc(npc) then
        XLog.Warning("释放技能" .. skill .. "失败,Npc非法")
        return false
    end
    local isSuccess = false
    self:CheckSkillCondition(skill)
    if self:CheckSkillConditionByNpc(skill, npc) then
        isSuccess = self._proxy:CastActionToTarget(self._uuid, skill, target)
    end
    self:HandleAfterCastSkill(skill, isSuccess)--处理释放技能之后
    return isSuccess
end

---无目标强制释放技能
function XRelinkMonsterBase:ForceSkill(skill)
    XLog.Warning("强制释放技能:"..skill)
    self._proxy:AbortAction(self._uuid, true) --强制打断当前技能
    local isSuccess = self._proxy:CastAction(self._uuid,skill)--强制释放这个技能
    return isSuccess
end

---强制对战斗目标释放技能（行为脚本不判断除了战斗目标合法性以外的条件）
function XRelinkMonsterBase:ForceSkillToTarget(skill)
    local target = self._proxy:GetFightTargetId(self._uuid)
    local isSuccess = false
    if not self._proxy:CheckNpc(target) then
        --目标不合法
        XLog.Warning("强制释放技能目标非法"..target)
        return false
    end
    self._proxy:AbortAction(self._uuid, true) --强制打断当前技能
    isSuccess = self._proxy:CastActionToTarget(self._uuid, skill, target)--对目标放技能
    self:HandleAfterCastSkill(skill, isSuccess)--处理释放技能之后
    return isSuccess
end

---对战斗目标释放技能（会判断配置的技能条件）
function XRelinkMonsterBase:CastSkillToTarget(skill)
    local target = self._proxy:GetFightTargetId(self._uuid)
    local isSuccess = false
    if self._proxy:CheckNpc(target) then
        --目标不合法
        return false
    end
    if not self:CheckSkillConditionByNpc(skill, target) then
        --技能条件不通过
        return false
    end
    isSuccess = self._proxy:CastActionToTarget(self._uuid, skill, target)--对目标放技能
    self:HandleAfterCastSkill(skill, isSuccess)--处理释放技能之后
    return isSuccess
end

---强制对Npc释放技能（行为脚本不判断除了Npc合法性以外的条件）
function XRelinkMonsterBase:ForceSkillToNpc(skill, npc)
    local isSuccess = false
    if not self._proxy:CheckNpc(npc) then
        --目标不合法
        return false
    end
    self._proxy:AbortAction(self._uuid, true)--打断Npc
    isSuccess = self._proxy:CastActionToTarget(self._uuid, skill, npc)--放技能
    self:HandleAfterCastSkill(skill, isSuccess)--放完技能后处理CD
    return isSuccess
end

---获得权重组里对Npc可以放的技能
function XRelinkMonsterBase:GetAbleSkillByWeightsToNpc(skills, npc)
    local newGroup = {}
    local totalW = 0 --总权重
    for skill, w in pairs(skills) do
        --筛选出满足条件的权重组
        if self:CheckSkillConditionByNpc(skill, npc) then
            --判断对这个Npc放技能是否满足条件
            newGroup[skill] = w
            totalW = totalW + w --总权重
        end
    end
    return self:GetWeightsKeyByTotalWeight(newGroup, totalW)
end

---从权重组里直接拿出Key(目前用于技能权重组里获取技能)
function XRelinkMonsterBase:GetKeyByWeights(skills)
    local totalW = 0 --总权重
    --计算总权重
    for skill, w in pairs(skills) do
        totalW = totalW + w
    end
    return self:GetWeightsKeyByTotalWeight(skills, totalW)--直接从技能组里随机一个出去
end

---对战斗目标根据权重组放技能（会判断怪物技能配置的释放条件）
function XRelinkMonsterBase:CastSkillToTargetByWeights(skills)
    local target = self.target
    local skill = self:GetAbleSkillByWeightsToNpc(skills, target) --从权重组里找到适合可以放的技能
    XLog.Warning(skill)
    if not skill then
        return false
    end
    isSuccess = self:ForceSkillToNpc(skill, target)  --对战斗目标强制放这个连招技能
    self:HandleAfterCastSkill(skill, isSuccess)--释放技能后要处理技能进入CD
    return isSuccess
end

---对战斗目标根据权重组强制放技能
function XRelinkMonsterBase:ForceCastSkillToTargetByWeights(skills)
    local skill = self:GetKeyByWeights(skills) --从权重组里筛出一个技能,不包括条件判断
    local isSuccess = false
    if not skill then
        return false
    end
    isSuccess = self:ForceSkillToTarget(skill)  --强制释放拿出来的技能给战斗目标
    return isSuccess
end

---强制对位置释放技能（不走怪物脚本的判断条件）
function XRelinkMonsterBase:ForceSkillToPosition(skill, pos)
    self._proxy:AbortAction(self._uuid, true)--打断当前技能
    local isSuccess = self._proxy:CastActionToPosition(self._uuid, skill, pos)--对位置释放技能
    self:HandleAfterCastSkill(skill, isSuccess)--处理释放技能之后
end

---输入权重组和总权重获得Key
function XRelinkMonsterBase:GetWeightsKeyByTotalWeight(weights, total)
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
function XRelinkMonsterBase:HandleAfterCastSkill(skill, isSuccess)
    if not isSuccess then
        --技能没有成功就不管了
        return
    end
    self:SkillEnterConfigCd(skill) --技能尝试进入配置Cd
    --释放成功时间处理
end

---技能进入配置Cd的接口
function XRelinkMonsterBase:SkillEnterConfigCd(skill)
    local cd = SkillConfigs[skill].Cd
    if not cd then
        return
    end
    self:SetSkillCd(skill, cd)--设置技能Cd
end
---设置技能CD直接完成
function XRelinkMonsterBase:SetSkillCdDone(skill)
    local cd = SkillConfigs[skill].Cd
    if not cd then
        return
    end
    self.SkillCds[skill] = self.fightTime
end

---设置技能CD(当前战斗时间+额外时间)
function XRelinkMonsterBase:SetSkillCd(skill, time)
    self.SkillCds[skill] = self.fightTime + time
end

---检查技能Cd好了没有
function XRelinkMonsterBase:CheckSkillCdDone(skill)
    local cd = self.SkillCds[skill]
    if cd then
        return self.fightTime >= cd
    end
    return true--表里没有记录Cd的说明没有Cd
end

--endregion

--region 怪物技能释放组
---清除释放组
function XRelinkMonsterBase:ClearCastGroup()
    self.castGroup = {}
end

---设置释放组
function XRelinkMonsterBase:SetCastGroup(castList)
    self.castGroup = castList
end

---添加技能组进释放组
function XRelinkMonsterBase:AddSkillsToCastGroup(group)
    table.insert(self.castGroup, group)
end

---设置技能组Cd
function XRelinkMonsterBase:SetSkillsCd(skillsId)
    --table.insert(self.castGroup,skillsId)
end

---从Npc自定义变量的释放组里获得一个可以对当前战斗目标可以放的技能
function XRelinkMonsterBase:GetAbleSkillToTargetByNpcCastGroup()
    for skillsId, skills in pairs(self.castGroup) do
        --遍历释放组去获得技能权重组
        local skill = self:GetAbleSkillByWeightsToNpc(skills, self.target) --从当前技能组里获得可以对当前目标放的技能
        if skill then
            --如果获得了技能就返回这个技能
            return skill
        end
    end
    return --如果没有技能就不放技能了。
end

---从脚本变量释放组里对Npc获得可以释放的技能(npc)
function XRelinkMonsterBase:GetAbleSkillToNpcByNpcCastGroup(npc)
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
function XRelinkMonsterBase:CastSkillToNpcByCastGroup(group,npc)
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
function XRelinkMonsterBase:GetAbleSkillToNpcByCastGroup(group,npc)
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
function XRelinkMonsterBase:CastSkillToTargetByCastSkillGroup()
    for skillsId, skills in pairs(self.castGroup) do
        --遍历释放组去获得技能权重组
        local skill = self:GetAbleSkillByWeightsToNpc(skills, self.target) --从当前技能组里获得可以对当前目标放的技能
        if skill then
            --如果获得了技能就返回这个技能
            return skill
        end
    end
    return --如果没有技能就不放技能了。
end


--endregion

--region 怪物Ai工具类

--endregion

return XRelinkMonsterBase