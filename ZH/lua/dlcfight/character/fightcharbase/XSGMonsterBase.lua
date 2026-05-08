local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
---空花的怪物基类
---@class XSGMonsterBase : XFightBase
local XSGMonsterBase = XClass(Base, "XSGMonsterBase")
local SkillConfigs = require("TempSkillConfigs/SkillConfig_8052")--小辉辉临时的技能配置
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")

--region 脚本枚举
---战斗状态管理
XSGMonsterBase.FightMode = { --无、非战斗、战斗、目标丢失
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
XSGMonsterBase.OverDriveState = {
    --- 无激活OD状态
    None = 0,
    --- 普通
    Normal = 1,
    --- 狂暴
    ODState = 2,
    --- 虚弱开始
    BreakStart = 3,
    --- 虚弱循环
    BreakLoop = 4,
}
---行为筛选和执行时的类型
XSGMonsterBase.ActionType = {--待机、追逐移动、攻击、游荡、巡逻、连招
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
XSGMonsterBase.SwitchPhaseType = { --不切阶段、Hp、时间轴
    ---没有切换阶段
    None = 0,
    ---进入OD时切阶段
    EnterOverDrive = 1,
    ---退出Break时切阶段
    ExitBreak = 2,
    ---添加BUFF时(TODO:暂不支持，占位)
    AddBuff = 3,
    ---移除Buff时(TODO:暂无支持，占位)
    RemoveBuff = 4,
    ---自定义条件
    CustomCondition = 5,
}
---距离类型
XSGMonsterBase.DistanceType = { --近、中、远、超远
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
XSGMonsterBase.DirectionType = { --前、后、左、右（暂时只需要四方向）
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
XSGMonsterBase.AttackFixType = {
    ---转向
    Turn = 1,
    ---距离
    Distance = 2,
}
---战斗逻辑情况下按照什么类型选择技能
XSGMonsterBase.SelectSkillType = {--根据什么规则去释放技能。
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
XSGMonsterBase.TurnType = { --根据转向类型决定调用哪个转向技能
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
XSGMonsterBase.SkillLayer = { --技能释放层，用来表示用哪个技能组
    None = 0,
    Normal = 1,
    ODState = 2,
}
XSGMonsterBase.SkillGroup = { --技能组结构
    GroupId = 0, --组ID，不用管
    GroupConditionType = 1, --组判断类型，乱选还是顺序选
    SkillList = 2, --组对应的技能列表。
}
---OD后特殊技能释放模式
XSGMonsterBase.OverDriveSpecialSkillCastMode = {
    None = 0,--没有OD特殊技能
    Config = 1, --配置的OD特殊技能（暂不支持）
    Custom =2,--自定义
}
---处理自定义事件类型
XSGMonsterBase.HandleCustomEventType = {
    None = 0,--无
    Latest = 1, --检查是否等于最新的，执行后删除所有
    All =2,--检查所有，执行后删除所有
}
---技能测试类型
XSGMonsterBase.SkillTestType = {
    None = 0,--无
    ToTarget = 1, --对目标
    CustomFuc =2,--自定义函数
}
--endregion

--region 同步和换端管理

--StringKey、Id、值类型、值
local RelinkMonsterBaseSyncKeyFirstTwoNumMeaningDic = { --怪物同步黑板Key前两个数字代表的含义和拼起来的意思
    10,--RelinkMonsterBase里自带脚本运行时同步的变量+(变量Key)：值可能是Int、Boll、Float
    11,--技能CD+（技能ID）：值永远是浮点值:01（初始CD），02（CD），03（Time）
    12,--NpcTimer+（TimerId）：值永远是浮点值: （）,跟技能Cd一样的结构。
    13,--继承RelinkMonsterBase以外需要同步的黑板变量
}

XSGMonsterBase.SyncValueType = { --同步值类型
    bool = 1 ,--默认F
    int = 2 ,--默认0
    float = 3 ,--默认0
}

--变量字典，这里面的变量会在初始化的时候注册和填入黑板（无赋值）
XSGMonsterBase.RelinkMonsterBaseVarSyncValueDic = { --怪物变量需要同步字典 String变量名=黑板Key+值类
    isAiOpen = {XSGMonsterBase.SyncValueType.bool},
    curODState = {XSGMonsterBase.SyncValueType.int},
    curFightMode = {XSGMonsterBase.SyncValueType.int},
    curPhase = {XSGMonsterBase.SyncValueType.int},
    isOnSoftFury = {XSGMonsterBase.SyncValueType.bool},
    curSkillTarget = {XSGMonsterBase.SyncValueType.int}
}

--怪物变量初始变量
XSGMonsterBase.RelinkMonsterBaseVarSyncKeyDicInitial = { --变量名对应的黑板Key
    isAiOpen = 1, --AI是否开启
    curODState = 2, --当前的OD状态
    curFightMode = 3, --当前的战斗状态
    curPhase = 4, --当前阶段
    isOnSoftFury = 5, --是否在软狂暴
    curSkillTarget = 6, --当前的技能目标
}

---脚本初始化时处理同步变量
function XSGMonsterBase:MonsterHandleScriptInitSyncValue(isGainControl)
    --怪物基类黑板处理
    for valueName,v in pairs(XSGMonsterBase.RelinkMonsterBaseVarSyncKeyDicInitial) do 
        self:RelinkMonsterBaseRegisterVarSync(valueName) --怪物基类注册黑板里的值
        self:RelinkMonsterBaseTrySyncBBValueToLocal(valueName) --怪物基类尝试将Base里的黑板值同步到本地
    end
    
    self:HandleSkillCdSync(isGainControl) --处理技能Cd同步到本地
    self:HandleNpcTimerSync(isGainControl) --处理NpcTimer到本地
    --怪物子类黑板处理
    if self.monsterSubVarSyncKeyDicInitial then
        local tableCount = 0
        for valueName, v in pairs(self.monsterSubVarSyncKeyDicInitial)do
            tableCount = tableCount + 1
            self:MonsterSubRegisterVarSync(valueName) --怪物子类注册黑板里的值
            self:MonsterSubTrySyncBBValueToLocal(valueName) --怪物子类尝试将Base里的黑板值同步到本地
        end
        if tableCount >0 then
            self:MonsterSubTrySyncBBValueToLocalAfter() --怪物子类尝试将Base里的黑板值同步到本地后
        end
    end
    
    --怪物处理脚本初始化值
    self:MonsterHandleScriptInitSyncVarAfter(isGainControl)
    
end

---脚本处理初始化同步变量后
function XSGMonsterBase:MonsterHandleScriptInitSyncVarAfter(isGainControl)
    
end

---处理技能Cd同步到本地
function XSGMonsterBase:HandleSkillCdSync(isGainControl)
    if not self.monsterScriptInitSyncRegisterSkillCdList then --没有要处理的列表就直接返回
        return
    end
    
    if not isGainControl then --服务器里注册技能CD同步
        self:MonsterRegisterSkillCdSync() --怪物注册技能CD同步
    end
    
    local fightTime = self._proxy:GetFightTime() --获取战斗时间
    for skillId,Value in pairs(self.monsterScriptInitSyncRegisterSkillCdList) do --遍历数组
        local hasKey1,initCd = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid,self:ConcatNumbers(1101,skillId))
        local hasKey2,cd = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid,self:ConcatNumbers(1102,skillId))
        local hasKey3,time = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid,self:ConcatNumbers(1103,skillId))
        self.SkillCds[skillId] = {} --对应技能创空数组

        if hasKey1 then --有注册同步的情况下直接赋值同步的值
            self.SkillCds[skillId].initCd = initCd
            self.SkillCds[skillId].cd = cd
            self.SkillCds[skillId].time = time
        else --没注册过就初始化一下
            self:InitSkillCd(skillId,Value[1],Value[2])
        end
    end
end

---怪物注册技能CD同步
function XSGMonsterBase:MonsterRegisterSkillCdSync()

    local fightTime = self._proxy:GetFightTime() --获取战斗时间

    for skillId , value in pairs(self.monsterScriptInitSyncRegisterSkillCdList)do --遍历要同步的列表
        local initBBCdKey = self:ConcatNumbers(1101,skillId)
        local initCdBBValue = value[1]
        local cdBBKey = self:ConcatNumbers(1102,skillId)
        local cdBBValue = value[2]
        local timeBBKey = self:ConcatNumbers(1103,skillId)
        local timeBBValue = fightTime + initCdBBValue --初始CD
        self._proxy:RegisterBBSync(XVarDomain.Npc,self._uuid,initBBCdKey)
        self._proxy:RegisterBBSync(XVarDomain.Npc,self._uuid,cdBBKey)
        self._proxy:RegisterBBSync(XVarDomain.Npc,self._uuid,timeBBKey)
        self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,initBBCdKey,initCdBBValue)
        self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,cdBBKey,cdBBValue)
        self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,timeBBKey,timeBBValue)
    end

end

---处理NpcTimer到本地
function XSGMonsterBase:HandleNpcTimerSync(isGainControl)
    
    if not self.monsterScriptInitSyncRegisterNpcTimerList then --没有要处理的列表就直接返回
        return
    end
    
    self:MonsterRegisterNpcTimerSync() --怪物注册NpcTimer同步
    
    if not isGainControl then --服务器里注册NpcTimer同步
        self:MonsterRegisterNpcTimerSync() --怪物注册NpcTimer同步
    end
    local fightTime = self._proxy:GetNpcTime(self._uuid) --获取战斗时间
    for npcTimerId,Value in pairs(self.monsterScriptInitSyncRegisterNpcTimerList) do --遍历需要同步的Npc数组
        local hasKey1,initCd = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid,self:ConcatNumbers(1201,npcTimerId))
        local hasKey2,cd = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid,self:ConcatNumbers(1202,npcTimerId))
        local hasKey3,time = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid,self:ConcatNumbers(1203,npcTimerId))
        self.timerList[npcTimerId] = {} --对应NpcTimer清空

        if hasKey1 then --有注册同步的情况下直接赋值同步的值
            self.timerList[npcTimerId].initCd = initCd
            self.timerList[npcTimerId].cd = cd
            self.timerList[npcTimerId].time = time
        else --没注册过就初始化一下
            self:InitNpcTimer(npcTimerId,Value[1],Value[2])
        end
    end
end

---怪物注册NpcTimer同步
function XSGMonsterBase:MonsterRegisterNpcTimerSync()
    local fightTime = self._proxy:GetFightTime() --获取战斗时间
    for timerId , value in pairs(self.monsterScriptInitSyncRegisterNpcTimerList) do
        local initBBCdKey = self:ConcatNumbers(1201,timerId)
        local initCdBBValue = value[1]
        local cdBBKey = self:ConcatNumbers(1202,timerId)
        local cdBBValue = value[2]
        local timeBBKey = self:ConcatNumbers(1203,timerId)
        local timeBBValue = fightTime + initCdBBValue --初始CD
        self._proxy:RegisterBBSync(XVarDomain.Npc,self._uuid,initBBCdKey)
        self._proxy:RegisterBBSync(XVarDomain.Npc,self._uuid,cdBBKey)
        self._proxy:RegisterBBSync(XVarDomain.Npc,self._uuid,timeBBKey)
        self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,initBBCdKey,initCdBBValue)
        self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,cdBBKey,cdBBValue)
        self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,timeBBKey,timeBBValue)
    end
end

---Relink怪物基类设置变量同步值
function XSGMonsterBase:RelinkMonsterBaseSetVarSyncValue(VarName,Value)
    local bbType = XSGMonsterBase.RelinkMonsterBaseVarSyncValueDic[VarName][1] --变量类型
    local key = self:ConcatNumbers(10,XSGMonsterBase.RelinkMonsterBaseVarSyncKeyDicInitial[VarName])

    if bbType == XSGMonsterBase.SyncValueType.float then
        self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,key,Value)
    elseif bbType == XSGMonsterBase.SyncValueType.int then
        self._proxy:SetBBInt(XVarDomain.Npc,self._uuid,key,Value)
    elseif bbType == XSGMonsterBase.SyncValueType.bool then
        self._proxy:SetBBBoolean(XVarDomain.Npc,self._uuid,key,Value)
    end
end

---Relink怪物基类获取同步值(变量名)
function XSGMonsterBase:RelinkMonsterBaseGetVarSyncValue(VarName)
    local bbType = XSGMonsterBase.RelinkMonsterBaseVarSyncValueDic[VarName][1] --变量类型
    local key = self:ConcatNumbers(10,XSGMonsterBase.RelinkMonsterBaseVarSyncKeyDicInitial[VarName])
    local isHaveKey = nil
    local value = nil

    if bbType == XSGMonsterBase.SyncValueType.float then
        isHaveKey,value = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid,key)
    elseif bbType == XSGMonsterBase.SyncValueType.int then
        isHaveKey,value = self._proxy:TryGetBBInt(XVarDomain.Npc,self._uuid,key)
    elseif bbType == XSGMonsterBase.SyncValueType.bool then
        isHaveKey,value = self._proxy:TryGetBBBoolean(XVarDomain.Npc,self._uuid,key)
    end

    if isHaveKey then --如果成功获得则返回值
        return value
    end
end

---Relink怪物基类尝试将黑板的值同步到本地，如果黑板有值就同步到本地
function XSGMonsterBase:RelinkMonsterBaseTrySyncBBValueToLocal(VarName)
    local haveKey,value = self:RelinkMonsterBaseTryGetVarSyncValue(VarName)
    if haveKey then --如果黑板有值就直接赋值
        self[VarName] =value
    end
end

---Relink怪物基类尝试获取同步值，返回是否获取和值
function XSGMonsterBase:RelinkMonsterBaseTryGetVarSyncValue(VarName)
    local bbType = XSGMonsterBase.RelinkMonsterBaseVarSyncValueDic[VarName][1] --变量类型
    local key = self:ConcatNumbers(10,XSGMonsterBase.RelinkMonsterBaseVarSyncKeyDicInitial[VarName])
    local isHaveKey = nil
    local value = nil

    if bbType == XSGMonsterBase.SyncValueType.float then
        isHaveKey,value = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid,key)
    elseif bbType == XSGMonsterBase.SyncValueType.int then
        isHaveKey,value = self._proxy:TryGetBBInt(XVarDomain.Npc,self._uuid,key)
    elseif bbType == XSGMonsterBase.SyncValueType.bool then
        isHaveKey,value = self._proxy:TryGetBBBoolean(XVarDomain.Npc,self._uuid,key)
    end
    return isHaveKey,value
end

---Relink怪物基类注册同步变量
function XSGMonsterBase:RelinkMonsterBaseRegisterVarSync(VarName)
    local bbType = XSGMonsterBase.RelinkMonsterBaseVarSyncValueDic[VarName][1] --变量类型
    local value = XSGMonsterBase.RelinkMonsterBaseVarSyncValueDic[VarName][2] --默认值
    local key = self:ConcatNumbers(10,XSGMonsterBase.RelinkMonsterBaseVarSyncKeyDicInitial[VarName])
    self._proxy:RegisterBBSync(XVarDomain.Npc,self._uuid,key)
    if bbType == XSGMonsterBase.SyncValueType.float then
        if value then
            self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,key,value)
        end
    elseif bbType == XSGMonsterBase.SyncValueType.int then
        if value then
            self._proxy:SetBBInt(XVarDomain.Npc,self._uuid,key,value)
        end
    elseif bbType == XSGMonsterBase.SyncValueType.bool then
        if value then
            self._proxy:SetBBBoolean(XVarDomain.Npc,self._uuid,key,value)
        end
    end
end

---Relink怪物子类设置变量同步值
function XSGMonsterBase:MonsterSubSetVarSyncValue(VarName,Value)
    local bbType = self.monsterSubSyncValueDic[VarName][1] --变量类型
    local key = self:ConcatNumbers(13,self.monsterSubVarSyncKeyDicInitial[VarName])

    if bbType == XSGMonsterBase.SyncValueType.float then
        self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,key,Value)
    elseif bbType == XSGMonsterBase.SyncValueType.int then
        self._proxy:SetBBInt(XVarDomain.Npc,self._uuid,key,Value)
    elseif bbType == XSGMonsterBase.SyncValueType.bool then
        self._proxy:SetBBBoolean(XVarDomain.Npc,self._uuid,key,Value)
    end
end

---Relink怪物子类注册同步变量
function XSGMonsterBase:MonsterSubRegisterVarSync(VarName)
    local bbType = self.monsterSubSyncValueDic[VarName][1] --变量类型
    local value = self.monsterSubSyncValueDic[VarName][2] --默认值
    local key = self:ConcatNumbers(13,self.monsterSubVarSyncKeyDicInitial[VarName])
    local isHaveKey = false


    if bbType == XSGMonsterBase.SyncValueType.float then
        isHaveKey,value = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid,key)
    elseif bbType == XSGMonsterBase.SyncValueType.int then
        isHaveKey,value = self._proxy:TryGetBBInt(XVarDomain.Npc,self._uuid,key)
    elseif bbType == XSGMonsterBase.SyncValueType.bool then
        isHaveKey,value = self._proxy:TryGetBBBoolean(XVarDomain.Npc,self._uuid,key)
    end

    if isHaveKey then --如果注册过就不注册了
        return
    end

    self._proxy:RegisterBBSync(XVarDomain.Npc,self._uuid,key)
    
    if bbType == XSGMonsterBase.SyncValueType.float then
        if value then
            self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,key,value)
        end
    elseif bbType == XSGMonsterBase.SyncValueType.int then
        if value then
            self._proxy:SetBBInt(XVarDomain.Npc,self._uuid,key,value)
        end
    elseif bbType == XSGMonsterBase.SyncValueType.bool then
        if value then
            self._proxy:SetBBBoolean(XVarDomain.Npc,self._uuid,key,value)
        end
    end
end

---Relink怪物子类尝试将黑板的值同步到本地，如果黑板有值就同步到本地
function XSGMonsterBase:MonsterSubTrySyncBBValueToLocal(VarName)
    local haveKey,value = self:MonsterSubTryGetVarSyncValue(VarName)
    
    if haveKey then --如果黑板有值就直接赋值
        self[VarName] =value
    end
end

---Relink怪物子类尝试将黑板的值同步到本地后
function XSGMonsterBase:MonsterSubTrySyncBBValueToLocalAfter()
    
end

---Relink怪物子类尝试获取同步值，返回是否获取和值
function XSGMonsterBase:MonsterSubTryGetVarSyncValue(VarName)
    local bbType = self.monsterSubSyncValueDic[VarName][1] --变量类型
    local key = self:ConcatNumbers(13,self.monsterSubVarSyncKeyDicInitial[VarName])
    local isHaveKey = nil
    local value = nil

    if bbType == XSGMonsterBase.SyncValueType.float then
        isHaveKey,value = self._proxy:TryGetBBFloat(XVarDomain.Npc,self._uuid,key)
    elseif bbType == XSGMonsterBase.SyncValueType.int then
        isHaveKey,value = self._proxy:TryGetBBInt(XVarDomain.Npc,self._uuid,key)
    elseif bbType == XSGMonsterBase.SyncValueType.bool then
        isHaveKey,value = self._proxy:TryGetBBBoolean(XVarDomain.Npc,self._uuid,key)
    end

    return isHaveKey,value
end

--endregion

--region 函数: 脚本生命周期

---脚本创建 或 换端时执行
function XSGMonsterBase:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    self:MonsterRunVarAwake() --怪物运行逻辑初始化构造
    self:MonsterConfigMain(isGainControl) --怪物配置，用来覆盖初始化好的变量
    self:MonsterRunInit(isGainControl) --怪物初始化，根据配置会有调整
    self:MonsterHandleScriptInitSyncValue(isGainControl) --处理黑板同步和赋值
end

---帧更新
---@param dt number @ delta time 
function XSGMonsterBase:Update(dt)
    Base.Update(self, dt)
    if dt == 0 then
        return
    end --暂停的时候AI不跑
    self:UpdateSelfBaseInfo(dt) --更新怪物自己的基础信息
    self:UpdateFightModeBefore()--战斗模式逻辑前
    if self.isSkillTestOpen then
        self:UpdateSkillTest(dt) --技能测试逻辑
        return
    end
    if not self.isAiOpen then--AI是否关闭
        --AI总开关
        return
    end
    self:UpdateFightMode(dt) --战斗模式逻辑
end

---怪物配置主入口，除了Main其他配置都是空，用于MonsterBase自带的各种功能组件配置，类似读表。
function XSGMonsterBase:MonsterConfigMain()
    self:SkillConfig() --技能配置
    self:PhaseConfig()     --阶段配置
    self:OverDriveConfig()  --OD系统配置
    self:BreakGaugeConfig()   --韧性系统配置
    self:SkillCastConfig()  --技能释放配置
    self:SkillTestConfig()  --技能测试配置
    self:SoftFuryConfig() --软狂暴配置
end

---软狂暴配置
function XSGMonsterBase:SoftFuryConfig()
end

---技能配置
function XSGMonsterBase:SkillConfig()
end

---阶段配置
function XSGMonsterBase:PhaseConfig()
end

---OverDrive配置
function XSGMonsterBase:OverDriveConfig()
end

---韧性系统配置
function XSGMonsterBase:BreakGaugeConfig()
end

---技能释放配置
function XSGMonsterBase:SkillCastConfig()
end

---技能测试配置
function XSGMonsterBase:SkillTestConfig()
end

--endregion

--region 怪物：怪物生命周期
--当怪物AI自己被创建的时候
function XSGMonsterBase:OnMonsterSelfAIBorn()
    if self.bornSkill then --有配置出生动画的话
        self:ForceSkill(self.bornSkill)
    end
end

--endregion

--region 怪物流程-Awake

---创建怪物运行要用的变量
function XSGMonsterBase:MonsterRunVarAwake()
    self.skillConfigs = SkillConfigs
    self:SelfInfoAwake() --自己信息初始化变量
    self:AiControlAwake() --Ai控制初始变量设置
    self:SkillCdAwake() --技能CD初始变量设置
    self:OverDriveAwake() --OD初始变量设置
    self:BreakGaugeAwake() --韧性初始变量设置
    self:FightModeAwake() --战斗模式初始变量设置
    self:PhaseAwake() --阶段控制初始化变量
    self:TargetAwake() --目标相关初始化变量
    self:FollowComponentAwake() --跟随组件初始化变量
    self:SkillTestAwake() --技能测试变量初始化
    self:SoftFuryAwake() --软狂暴变量初始化
    self:BBSyncAwake()  --黑板同步变量初始化
end

---黑板变量初始化，这里其实是给子类要同步变量用的。
function XSGMonsterBase:BBSyncAwake()
    self.monsterScriptInitSyncRegisterSkillCdList=nil --需要同步的技能Cd列表
    self.monsterScriptInitSyncRegisterNpcTimerList= nil --需要同步的NpcTimerCd列表
    self.monsterSubVarSyncKeyDicInitial=nil --变量名对应的黑板Key,这里的Key开头会变成13
    self.monsterSubSyncValueDic =nil --怪物变量需要同步字典,这里的Key开头会变成13
end

---软狂暴运行初始化
function XSGMonsterBase:SoftFuryAwake()
    self.isHaveSoftFury = false --是否有软狂暴
    self.enterSoftFuryFightTime = 600 --战斗时间超过多少秒后进入软狂暴
    self.isOnSoftFury = false --当前是否在软狂暴状态
    self.enterSoftFurySkill = nil --进入软狂暴时会执行的技能
    self.enterSoftFuryMagicList = nil --进入软狂暴的时候会给自己添加的Magic列表
end

---自己信息相关变量激活
function XSGMonsterBase:SelfInfoAwake()
    self.hpRate = 1           --自己生命百分比
    self.Pos = nil       --自己的位置
    self.fightTime = self._proxy:GetFightTime() --当前战斗时间
    self.npcTime = self._proxy:GetNpcTime(self._uuid) --当前Npc时间
    self.customEventList={}--保存获得帧事件的列表
    self.levelCenterPoint = self._proxy:GetSpot(2) --获取场景中心点
    self.timerList={}
    self.curSkillTarget = nil --技能释放目标
    self.lastTarget = nil --上一个目标
    self.bornSkill = nil -- 出生技能
end

---OverDrive变量激活
function XSGMonsterBase:OverDriveAwake()
    self.isOverDriveActive = false --是否开启Od系统，空花默认关闭。
    self.isODValueFull = false --OD值是否满
    self.enterOverDriveMagics={8052034}--进入OD时要Magic的列表
    self.exitOverDriveMagics={8052035}--退出OD时要Magic的列表
    -------OD系统:OD-----------------------------------------
    self.curODState = XSGMonsterBase.OverDriveState.None
    self.enterOverDriveSkill = nil --配置：进入OD的技能
    self.spSkill = nil --配置：Sp技能，进入OD后优先释放的。
    --OD系统:Breaking状态-----------------------------------------
    self.breakStartSkill = nil --配置：进入虚弱技能
    self.breakLoopSkill = nil --配置：虚弱循环技能
    self.breakEndSkill = nil --配置：退出虚弱时技能
    self.breakStartEnterLoopDelayTime = 0 --BreakStart多久后切到BreakLoop
    self.overDriveSpecialSkillSwitch = false --OD后要释放特殊技能的开关
    self.overDriveSpecialSkillCastMode = XSGMonsterBase.OverDriveSpecialSkillCastMode.None --默认OD后没有要特殊释放的技能
end

---设置OverDrive开启状态（目前只能在配置里调用生效）
function XSGMonsterBase:SetOverDriveActive(isActive)
    self.isOverDriveActive = isActive
end

---韧性变量激活
function XSGMonsterBase:BreakGaugeAwake()
    self.isBreakGaugeActive = false --是否开启破韧系统，空花默认关闭
    self.brokenSkillDefault = nil --被破韧时默认释放的技能,现在没有用 TODO:之后用来设置默认的破韧技能，简单破韧技能。
    self.brokenSkillFront = nil --被前面破韧时技能
    self.brokenSkillBack = nil --被破韧时释放的技能
    self.brokenSkillLeft = nil --被破韧时释放的技能
    self.brokenSkillRight = nil --被破韧时释放的技能
    self.brokenRange = 40 --被破韧时多少米范围内的玩家可以使用破韧技能
end

---设置破韧系统是否开启
function XSGMonsterBase:SetBreakGaugeActive(isBreakGaugeActive)
    self.isBreakGaugeActive=(isBreakGaugeActive)
end

---战斗模式变量激活
function XSGMonsterBase:FightModeAwake()
    self.curFightMode = XSGMonsterBase.FightMode.NonCombat --默认没有在战斗
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
    self.currentActionType = XSGMonsterBase.ActionType.None
    self.lastActionType = XSGMonsterBase.ActionType.None
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
    self.haveWander = false --是否开启游荡
    self.distanceReference = { --近中远距离参考
        near = 997,
        mid = 998,
        far = 999
    }
    self.wanderSkills = { --前后左右的游荡技能
        front = nil,
        back = nil,
        left = nil,
        right = nil,
    }
    self.wanderWeights = { --游荡判断权重
        near = { --近距离游荡行为判断权重
            attack = 0,
            front = 0,
            back = 0,
            left = 0,
            right = 0,
            daze =0,
        },
        mid = {--中距离游荡行为判断权重
            attack = 0,
            front = 0,
            back = 0,
            left = 0,
            right = 0,
            daze =0,
        },
        far = {--远距离游荡行为判断权重
            attack = 0,
            front = 0,
            back = 0,
            left = 0,
            right = 0,
            daze =0,
        }
    }
    self.dazeTimes ={1,2} --发呆时间区间，最小最大的秒
    self.wanderTimer = 0 --游荡相关计时器
    self.skillInfoConfigList = {}
    self.selectSkillType = XSGMonsterBase.SelectSkillType.None --默认不放技能
    self.skillLayer = XSGMonsterBase.SkillLayer.Normal --普通层技能释放
    self.skillLockedList = {} --锁定技能列表，被锁定的技能无法释放

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
    
    ------追逐配置-------------
    self.isOpenChase = true --开启追逐
end

---目标变量激活
function XSGMonsterBase:TargetAwake()
    self.target = nil               --战斗目标，会在战斗模式下更新
    self.targetHpPercent = 0            --目标血量百分比
    self.targetPos = nil     --目标当前坐标位置
    self.targetDistance = 0               --和目标距离
    self.targetDistanceType = XSGMonsterBase.DistanceType.None --和目标的距离类型
    self.targetSpaceType = nil --目标在自己当前哪个方位

    ------- 周围敌人列表相关 --------------------------------
    self.vigilantRange = 50 --警戒范围。
    self.vigilantRangePlayerList = {} --警戒范围内的敌人列表
    self.vigilantRangePlayerListUpdateTimeOnCombatMode = 10 --战斗模式下更新敌人列表频率
    self.vigilantRangePlayerListUpdateTimer = self.fightTime --更新敌人列表的计时器
end

---阶段管理变量激活
function XSGMonsterBase:PhaseAwake()
    self.curPhase = 1 --当前阶段
    self.maxPhase = 3 --阶段上限
    self.switchPhaseType = XSGMonsterBase.SwitchPhaseType.None --切阶段类型，None就是没有切阶段，所以会一直停留在一阶段。
end

---整个AI控制变量激活
function XSGMonsterBase:AiControlAwake()
    self.isAiOpen = nil --bool总AI开关
    self.isCombatModeAiOpen = true  --是否调用战斗模式逻辑
    self.isCombatLogicAiOpen = true --是否调用战斗逻辑
    self.isCombatLogicMainOpen = true --Main逻辑是否跑
end

---根据技能配置初始化技能Cd
function XSGMonsterBase:SkillCdAwake()
    self.SkillCds = {} --保存技能CD
    --local fightTime = self._proxy:GetFightTime() --获取战斗时间
    --for skill, config in pairs(SkillConfigs) do
    --    --如果有配置初始化Cd的就设置cd
    --    local cd = config.InitCd
    --    if cd then
    --        self.SkillCds[skill] = fightTime + cd
    --    end
    --end
end

---跟随组件变量激活
function XSGMonsterBase:FollowComponentAwake()
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
function XSGMonsterBase:MonsterRunInit()
    self:OverDriveInit() --OD初始化
    self:BreakGaugeInit() --韧性初始化
    self:SkillTestInit()--技能测试初始化
end

---OD系统初始化
function XSGMonsterBase:OverDriveInit()
    
    if not self.isOverDriveActive then
        return
    end
    
    --TODO可能存在怪物不需要OD功能的情况，当前默认开启
    self._proxy:SetNpcOverDriveActive(self._uuid,true)--激活OD功能
    --监听事件
    self._proxy:RegisterEvent(EWorldEvent.NpcEnterOverDrive)       --Npc进入OD
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)       --Npc死亡
    self._proxy:RegisterEvent(EWorldEvent.NpcOverDriveFull)       --当NpcOD满了
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakBefore)   --NpcODBreak前
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakAfter)   --NpcODBreak后
    self._proxy:RegisterEvent(EWorldEvent.NpcODExitBreakAfter)-- NpcOD退出Break
end

---阶段初始化
function XSGMonsterBase:PhaseInit()
end

---韧性系统初始化
function XSGMonsterBase:BreakGaugeInit()

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
function XSGMonsterBase:UpdateCombatMode(dt)
    --战斗模块
    if not self.isCombatModeAiOpen then
        return
    end
    
    --1：战斗逻辑启用前。
    self:CombatLogicBefore(dt)
    if not self.isCombatLogicAiOpen then --未开启战斗逻辑，以下内容不执行
        return
    end
    
    self:CombatLogicSelectTarget(dt) --战斗逻辑选择目标，默认选择一仇

    if not self:CheckTargetValid() then--检查有没有目标
        return
    end

    self:UpdateTargetInfo()  --更新目标相关信息
    --2：战斗前置逻辑，当前已有目标，但行为是不确定的
    self:CombatLogicTargetLocked(dt)
    
    if not self:CheckSelfActionValid() then
        --行为有效性检查
        return
    end--行动有效性判断
    --3：优先战斗逻辑
    self:CombatLogicPriority(dt)
    if not self:CheckSelfActionValid() then
        --行为有效性检查
        return
    end--行动有效性判断
    --4：自定义战斗逻辑
    self:CombatLogicCustom(dt)
    if not self.isCombatLogicMainOpen then
        return
    end
    if not self:CheckSelfActionValid() then
        --行为有效性检查
        return
    end--行动有效性判断
    --5:核心底层运行的核心战斗逻辑
    self:CombatLogicMain(dt) --核心战斗逻辑

end

---1：战斗逻辑执行前，不包括任何状态或条件检测，默认空逻辑
function XSGMonsterBase:CombatLogicBefore(dt)
end

---2：战斗流程：前置战斗逻辑（已有目标）
function XSGMonsterBase:CombatLogicTargetLocked(dt)

end

---3：战斗流程：优先战斗逻辑
function XSGMonsterBase:CombatLogicPriority(dt)
    self:CombatModeTryCastOverDriveSpecialSkill()--尝试释放OD机制技能
    self:CombatModeTryEnterSoftFury() --尝试进入软狂暴
    self:CombatModeTryEnterOverDrive()--尝试进入OD
end

---4：战斗流程：自定义战斗逻辑
function XSGMonsterBase:CombatLogicCustom(dt)
end

---5：战斗流程：核心底层运行的核心战斗逻辑
function XSGMonsterBase:CombatLogicMain(dt)
    self:SelectAction() --行为筛选，筛选出要做的事
    self:DoAction(dt) --行为执行，根据行为筛选出来的事情去执行，用来处理执行前和执行后的逻辑。
end
--endregion

--region 战斗模式

---检查自己是不是通常意义上的可行动
function XSGMonsterBase:CheckSelfActionValid()
    
    if self._proxy:CheckNpcAction(self._uuid, ENpcAction.Skill) then--正在释放技能
        if not self._proxy:CheckNpcCurActionIsDone(self._uuid)then--自己技能没有完成时，无效。
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

---尝试改变目标
function XSGMonsterBase:TryChangeTarget()
    local isSuccess = true --是否改变目标成功
    
    if self._proxy:CheckThreatList(self._uuid) then --如果仇恨列表为空
        return false
    end
    
    self:SetTarget(self._proxy:GetMaxThreatNpc(self._uuid)) --设置一仇为目标
    
    return isSuccess
end

---检查Npc成为目标的合法性
function XSGMonsterBase:CheckTargetValidByNpc(npc)

    if not self._proxy:CheckNpc(npc) then --是否存在
        return
    end
    
    if self._proxy:CheckNpcFullActionState(npc,ENpcAction.Dying,-1) then --死亡中
        return false
    end

    if self._proxy:CheckNpcFullActionState(npc,ENpcAction.Death,-1) then --死亡
        return false
    end

    if self._proxy:CheckNpcFullActionState(npc,ENpcAction.Reboot,-1) then --复活中
        return false
    end

    return true--以上无效判断都不通过时，
end

---非战斗模式逻辑
function XSGMonsterBase:UpdateNonCombatMode(dt)
    --非战斗模块
    return --非战斗下现在啥也不干
end

---GamePlay逻辑
function XSGMonsterBase:UpdateGamePlayLogic(dt)
    self:UpdatePhaseSystem(dt) --阶段管理系统，Update检测自己是否要转阶段了
end

---更新自己相关的基础信息
function XSGMonsterBase:UpdateSelfBaseInfo()
    ---生命百分比
    local maxHp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    local curHp = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    self.hpRate = curHp / maxHp--生命百分比
    --BK值暂时没有
    self.fightTime = self._proxy:GetFightTime() --更新战斗时间
    self.npcTime = self._proxy:GetNpcTime(self._uuid) --更新Npc时间
    self.Pos = self._proxy:GetNpcPosition(self._uuid) --更新位置
    self:UpdateVigilantRangePlayerList() --更新警戒范围内敌人列表
    self.curAction =nil --当前释放中的Action
    
    if self.curSkillTarget then --有当前技能释放目标时检查退出技能要把技能目标干掉
        if not self._proxy:CheckNpcFullActionState(self._uuid,ENpcAction.Skill) then
            self.curSkillTarget = nil
        end
    end
    
end

---更新警戒范围内敌人列表
function XSGMonsterBase:UpdateVigilantRangePlayerList()
    if self.fightTime < self.vigilantRangePlayerListUpdateTimer then
        --CD控制器
        return
    end
    --搜索周围敌人列表
    self.vigilantRangePlayerList = {}--清空周围敌人列表
    self.vigilantRangePlayerList = self:GetPlayerListInRange(self.vigilantRange,true)--设置为警戒范围内的活人
    if self.curFightMode == XSGMonsterBase.FightMode.Combat then
        --设置刷新警戒范围内敌人列表的时间，战斗模式下的CD
        self.vigilantRangePlayerListUpdateTimer = self.fightTime + self.vigilantRangePlayerListUpdateTimeOnCombatMode --战斗时更新警戒范围敌人列表的CD
    end
end

---在范围内获取随机的敌人
function XSGMonsterBase:GetRandomPlayerInRange(near,far)
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
function XSGMonsterBase:GetPlayerListInRange(range,needAlive)
    local npcList = self._proxy:GetPlayerNpcList()
    local tempNpcList = {}
    for i, npc in pairs(npcList) do
        local distance = self._proxy:CalcNpcDistance(self._uuid, npc) --计算和目标的距离
        if distance < range then --在范围内
            if needAlive then --是否需要检查存活
                if self:CheckTargetValidByNpc(npc) then --需要存活并确实存活就插入
                    table.insert(tempNpcList, npc)
                end
            else--不需要就直接插入
                table.insert(tempNpcList, npc) --插入Npc
            end
        end
    end
    return tempNpcList
end

---战斗逻辑选择目标。根据仇恨选择目标（包括强仇和仇恨值）
function XSGMonsterBase:CombatLogicSelectTarget(dt)
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
function XSGMonsterBase:CombatLogicCustomSelectTarget()
    return nil
end

---清除目标信息
function XSGMonsterBase:ClearTarget()
    self.target = nil
    self.lastTarget =nil
    self._proxy:RemoveFightTarget(self._uuid)
end

---更新战斗模式的战斗信息
function XSGMonsterBase:UpdateFightInfo()
    --更新战斗信息

end

---检查目标有效性
function XSGMonsterBase:CheckTargetValid()

    if (self.target == 0) or (not self.target) then
        return false
    end

    if not self._proxy:CheckNpc(self.target) then
        return false
    end

    return true
end

---更新和战斗目标相关信息
function XSGMonsterBase:UpdateTargetInfo()
    if not self.target then
        return
    end
    self.targetHpPercent = self._proxy:GetNpcAttribRate(self.target, ENpcAttrib.Life)
    self.targetPos = self._proxy:GetNpcPosition(self.target)
    self.targetDistance = self._proxy:CalcNpcDistance(self._uuid, self.target) --获取距离

    --更细和目标的距离类型
    if self.targetDistance <= self.basicDistanceReference[1] then
        --近距离
        self.targetDistanceType = XSGMonsterBase.DistanceType.Near
    elseif self.targetDistance <= self.basicDistanceReference[2] then
        --中距离
        self.targetDistanceType = XSGMonsterBase.DistanceType.Mid
    elseif self.targetDistance <= self.basicDistanceReference[3] then
        --远距离
        self.targetDistanceType = XSGMonsterBase.DistanceType.Far
    else
        self.targetDistanceType = XSGMonsterBase.DistanceType.SoFar  --超远距离
    end
end

--检查和更新战斗模式
function XSGMonsterBase:UpdateFightMode(dt)
    if self.curFightMode == XSGMonsterBase.FightMode.Combat then
        if self:OutCombatCheck(dt) then --更新战斗模块逻辑前脱战逻辑
            --检查退出战斗成功
            return
        end
        self:UpdateCombatMode(dt)
    elseif (self.curFightMode == XSGMonsterBase.FightMode.NonCombat) then
        --非战斗模块
        if self:EnterCombatCheck(dt) then
            --检查进入战斗
            return
        end
        self:UpdateNonCombatMode(dt) --运行非战斗模块逻辑
    end
end

---Update战斗模式前
function XSGMonsterBase:UpdateFightModeBefore(dt)
    self:FightModeTryEnterODBreakLoop()--尝试进入ODBreakLoop
end

---找到最近的敌人触发战斗
function XSGMonsterBase:EnterCombatCheck()
    --进入战斗检测
    if not self:CheckSelfActionValid() then --当前行为不合法
        return false
    end
    -----------------仇恨列表触发战斗------------------------------------
    if self._proxy:CheckThreatList(self._uuid) then
        --仇恨列表不为空
        self:EnterCombatByNpc(self._proxy:GetMaxThreatNpc(self._uuid)) --被一仇触发战斗
        return true
    end

    -------------------靠近触发战斗-----------------------------------
    if #self.vigilantRangePlayerList < 1 then
        --周围没有敌人时进入战斗失败
        return false
    end
    local nearestPlayer = self:GetNearestValidTarget()--玩家列表里找一个存活的玩家
    if nearestPlayer then --如果找到了最近的玩家就被Npc触发。
        self:EnterCombatByNpc(nearestPlayer) 
    end
    return true
end

---没有一点点防备,也没有一丝顾虑，私自入战
function XSGMonsterBase:EnterCombat()
    self.curFightMode = XSGMonsterBase.FightMode.Combat --战斗模式设置为入战
    self:RelinkMonsterBaseSetVarSyncValue("curFightMode",self.curFightMode)--同步当前战斗模式
    if self.enterCombatSkill then
        --有入战技能的时候使用入战斗技能：吼叫
        self._proxy:CastAction(self._uuid, self.enterCombatSkill)
    end
end

--被Npc触发战斗了，需要做点什么
function XSGMonsterBase:EnterCombatByNpc(triggerNpc)
    self.curFightMode = XSGMonsterBase.FightMode.Combat  --进入战斗模式
    self:RelinkMonsterBaseSetVarSyncValue("curFightMode",self.curFightMode)--同步当前战斗模式
    if self.enterCombatSkill and self._proxy:CheckCanCastSkill(self._uuid) then
        --有配置技能且可释放技能的情况下，释放入战技能。
        self._proxy:CastActionToTarget(self._uuid, self.enterCombatSkill, triggerNpc)
    end
    if not self._proxy:CheckNpcInThreatList(self._uuid, triggerNpc) then
        self:AddNpcToThreatValueList(triggerNpc)--把触发的Npc添加进仇恨列表
    end
    -----进入战斗时把其他玩家一起拉进战斗---------------------------------------
    local npcList = self._proxy:GetPlayerNpcList()
    for i, npcUUID in pairs(npcList) do
        --把没有在仇恨列表的合法玩家拉进仇恨列表
        if not self._proxy:CheckNpcInThreatList(self._uuid, npcUUID) and self:CheckTargetValidByNpc(npcUUID)then
            self:AddNpcToThreatValueList(npcUUID)--添加进仇恨列表
        end
    end
    self:SetTarget(triggerNpc) --将目标设置为触发战斗的Npc
end

---寻找最近目标
function XSGMonsterBase:GetNearestValidTarget(range)
    local target = nil
    local lastDistance = 0
    local isInRange = false
    local isValidTarget = false
    local distance = nil
    
    if #self.vigilantRangePlayerList < 1 then
        --没有Npc了
        return nil
    end
    for i, npc in pairs(self.vigilantRangePlayerList) do
        --遍历警戒范围内的敌人，找到最近的
        distance = self._proxy:CalcNpcDistance(self._uuid, npc) --计算和目标的距离
        if range then --范围要求
            isInRange = distance < range
        else
            isInRange = true
        end
        isValidTarget = self:CheckTargetValidByNpc(npc)
        if isInRange and isValidTarget then
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
    end
    return target
end

---根据位置寻找最近的敌人
function XSGMonsterBase:GetNearestPlayerByPos(pos)
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
function XSGMonsterBase:SetTarget(npc)
    if (not npc) or (npc == 0)then
        XLog.Warning("设置目标非法")
        return
    end
    if not self.lastTarget or npc~=self.lastTarget then --没有上一个目标且当前目标和之前目标不一样的时候
        --XLog.Warning("设置目标？")
        self.target = npc --当前目标设置为这个
        self._proxy:SetFightTarget(self._uuid, npc)
        self.lastTarget = self.target
        --self:RemoveBuffAllPlayer(8052119)
        --self._proxy:ApplyMagic(self._uuid,npc,8052119) --给目标上仇恨线
        --设置该目标为移动目标
        local followTargetMinDis = self.followTargetMinDis
        local followTargetMMaxDis = self.followTargetMaxDis
        local followTargetHeartBeat = self.followTargetHeartBeat
        self._followController:SetFollowTargetNpcNoNavMesh(self.target, followTargetMinDis, followTargetMMaxDis, followTargetHeartBeat)  --跟随目标设置成当前目标
    end
    
   
end

--获取怪物目标
function XSGMonsterBase:GetTarget()
   return self.target 
end
--移除怪物目标
function XSGMonsterBase:RemoveMonsterTarget()
    self.target = nil
    self._proxy:RemoveMonsterTarget(self._uuid)
    --取消移动组件
    self._followController:CancelFollow() --清空移动组件
end
--检查退出战斗
function XSGMonsterBase:OutCombatCheck()
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

    if (not self:CheckTargetValidByNpc(target) and (not self:TryChangeTarget())) then --当前目标不合法且尝试改变目标失败
        self:OutCombat() --退出战斗
        return true
    end
   
    return isOutBattle
end

--退出战斗时
function XSGMonsterBase:OutCombat()
    --搜索周围敌人列表
    self.vigilantRangePlayerList = {}--清空周围敌人列表
    self.vigilantRangePlayerList = self:GetPlayerListInRange(self.vigilantRange,true)--更新警戒范围内玩家
    self.curFightMode = XSGMonsterBase.FightMode.NonCombat
    self:RelinkMonsterBaseSetVarSyncValue("curFightMode",self.curFightMode)--同步当前战斗模式
    self:ClearTarget() --清除目标相关东西
end
--endregion

--region 行为：基础
--行为筛选
function XSGMonsterBase:SelectAction()
    if not self:CheckNeedSelectAction() then --检查是否有必要再筛选一次
        return
    end
    
    local skill = nil
    local wander = nil
    --连招筛选
    skill = self:SelectCombo()--连招选择
    if skill then
        self.SelectActionInfo.CurActionType = XSGMonsterBase.ActionType.Attack
        self.SelectActionInfo.SkillId = skill
        return
    end

    --超远距离
    if self.targetDistanceType == XSGMonsterBase.DistanceType.SoFar then
        self.SelectActionInfo.CurActionType = XSGMonsterBase.ActionType.Chase
        return
    end

    --技能筛选--
    skill = self:SelectSkill()
    if skill then
        --筛选出可以释放的技能
        wander = self:SelectSkillPreWander()--技能释放前根据攻击欲望选择游荡
        if wander then
            self.SelectActionInfo.CurActionType = XSGMonsterBase.ActionType.Wander
            self.SelectActionInfo.Wander = wander
        else
            self.SelectActionInfo.CurActionType = XSGMonsterBase.ActionType.Attack
            self.SelectActionInfo.SkillId = skill
        end
        --筛选技能成功
        return
    end
    
    wander = self:SelectCommonWander()
    --通用游荡
    if wander then
        self.SelectActionInfo.CurActionType = XSGMonsterBase.ActionType.Wander
        self.SelectActionInfo.Wander = wander
        return
    end

    --没有任何想做的，就追逐目标。
    if self.isOpenChase then
        self.SelectActionInfo.CurActionType = XSGMonsterBase.ActionType.Chase
        return
    end

    self.SelectActionInfo.CurActionType = XSGMonsterBase.ActionType.None--啥也不干
    return
end

--检查是否需要选择Action
function XSGMonsterBase:CheckNeedSelectAction()

    if self.SelectActionInfo.CurActionType == XSGMonsterBase.ActionType.None or not self.SelectActionInfo.CurActionType then --没有行为时就需要判断
        return true
    end

    if self.SelectActionInfo.CurActionType == XSGMonsterBase.ActionType.Wander then --游荡逻辑的话就没必要
        return false
    end
    return true
end
--执行行为
function XSGMonsterBase:DoAction(dt)
    local actionType = self.SelectActionInfo.CurActionType
    if actionType == XSGMonsterBase.ActionType.Chase then
        --追逐
        self:Chasing(dt)
    elseif actionType == XSGMonsterBase.ActionType.Attack then
        --攻击
            self:Attack()
    elseif actionType == XSGMonsterBase.ActionType.Wander then
        self:Wander(dt)
    end
end
--DoAction过程中发生意外了，需要重新选择行为。
function XSGMonsterBase:ReSelectAction()

end
--检查目标是否在角度范围内
function XSGMonsterBase:IsTargetInMyAngle(angle)
    return self._proxy:CheckNpcInAngle(self._uuid, self.target, angle)
end
--游荡
function XSGMonsterBase:Wander()
    local wander = self.SelectActionInfo.Wander
    if self.SelectActionInfo.Wander == "daze" then --如果是发呆
        if self.wanderTimer == 0 then
            local minTime =  self.dazeTimes[1]
            local maxTime =  self.dazeTimes[2]
            local cdTime = self._proxy:Random(minTime*100,maxTime*100)/100
            self.wanderTimer = self.fightTime + cdTime
        else
            if self.fightTime > self.wanderTimer then
                self:OnActionDone(XSGMonsterBase.ActionType.Wander)
            end
        end 
    end
    --if self:ForceSkillToTarget(self.wanderSkills[wander]) then
    --    self:OnActionDone(XSGMonsterBase.ActionType.Wander)
    --end
end
--技能释放过程中的转身调整
function XSGMonsterBase:TurnAround()

end
--攻击行为
function XSGMonsterBase:Attack()
    if self:ForceSkillToNpc(self.SelectActionInfo.SkillId, self.target) then
        --强制释放这个技能
        self:OnActionDone(XSGMonsterBase.ActionType.Attack)
    end
    --if self._proxy:CastActionToTarget(self._uuid,self.SelectActionInfo.SkillId,self.target) then
    --    
    --end
end
--当Action结束
function XSGMonsterBase:OnActionDone(action)
    self.SelectActionInfo.SkillId = nil
    self.SelectActionInfo.Wander = nil
    self.wanderTimer = 0
    self.SelectActionInfo.CurActionType = nil
    self.SelectActionInfo.LastActionType = action

end
--endregion

--region 行为：追逐
--追逐目标
function XSGMonsterBase:Chasing(dt)
    --XLog.Warning("向Npc移动")
    --调用跟随组件，需要补充其他追逐逻辑，比如是否优先使用追逐技能。
    self._followController:SetFollowTargetNpcNoNavMesh(self.target, self.followTargetMinDis, self.followTargetMaxDis, self.followTargetHeartBeat)
    self._followController:Update(dt)  --调用跟随组件走向目标
end

--追逐测试
function XSGMonsterBase:ChasingTest()
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
function XSGMonsterBase:TurnTest()
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
function XSGMonsterBase:SelectCombo()

end
--选择技能前置游荡
function XSGMonsterBase:SelectSkillPreWander()
    if not self.haveWander then --没有游荡
        return false
    end
    local weights = nil --根据位置距离类型决定的权重组，
    local tempWeights = {} --筛选用的权重组
    local totalWanderWeight = 0 --游荡总权重
    if self.targetDistanceType == XSGMonsterBase.DistanceType.Near then --筛选距离组
        weights = self.wanderWeights.near
    elseif self.targetDistanceType == XSGMonsterBase.DistanceType.Mid then
        weights = self.wanderWeights.mid
    elseif self.targetDistanceType == XSGMonsterBase.DistanceType.Far then
        weights = self.wanderWeights.far
    end

    for key,weight in pairs(weights)do --保证只收集配了值的，没配值的默认不想要
        if weight > 0 then
            tempWeights[key] = weight
            totalWanderWeight = totalWanderWeight + weight --收集总权重
        end
    end
    
    if totalWanderWeight == 0 then--没有任何配置的直接游荡失败
        return false
    end
    
    local randomValue = self._proxy:Random(0,totalWanderWeight)
    local cumulativeWeight = 0
    for key,weight in pairs(tempWeights)do
        cumulativeWeight= cumulativeWeight +weight
        if randomValue <= cumulativeWeight then--遍历的时候被选中了
            if key == "attack" then --被选中的如果是攻击
                return false
            else --其他的游荡选项就直接返回Key
                return key
            end
        end
    end
    
    return false --默认游荡失败
end
--后置游荡，技能释放结束后游荡
function XSGMonsterBase:SelectCommonWander()
    if not self.haveWander then --没有游荡
        return false
    end
    local weights = nil --根据位置距离类型决定的权重组，
    if self.targetDistanceType == XSGMonsterBase.DistanceType.Near then
        weights = self.wanderWeights.near
    elseif self.targetDistanceType == XSGMonsterBase.DistanceType.Mid then
        weights = self.wanderWeights.mid
    elseif self.targetDistanceType == XSGMonsterBase.DistanceType.Far then
        weights = self.wanderWeights.far
    end
end
--筛选技能
function XSGMonsterBase:SelectSkill()
    if self.selectSkillType == XSGMonsterBase.SelectSkillType.NormalSequence then
        --普通技能筛选，按照技能列表从左到右判断是否满足释放条件
        return self:NormalSequenceSelectSkill() --按从左到右顺序筛选技能
    end
    if self.selectSkillType == XSGMonsterBase.SelectSkillType.RandomSequence then
        --普通技能筛选，按照技能列表从左到右判断是否满足释放条件
        return self:RandomSequenceSelectSkill() --普通列表随机筛选技能
    end
    if self.selectSkillType == XSGMonsterBase.SelectSkillType.CastGroup then
        --普通技能筛选，按照技能列表从左到右判断是否满足释放条件
        return self:CastGroupSelectSkill() --按照技能释放组里的权重筛选出一个可以释放的技能
    end
    return nil
end
--普通顺序筛选技能
function XSGMonsterBase:NormalSequenceSelectSkill()
    if #self.sequenceSkillList < 1 then
        --技能列表为空
        return nil
    end
    for index, skill in pairs(self.sequenceSkillList) do
        if self:CheckSkillCondition(skill) then--是否能释放该技能
            return skill
        end
    end
end
--普通随机筛选
function XSGMonsterBase:RandomSequenceSelectSkill()
    if #self.sequenceSkillList < 1 then
        --技能列表为空
        return nil
    end

    local skillIndex = self._proxy:Random(1, #self.sequenceSkillList)
    local skillId = self.sequenceSkillList[skillIndex]

    return skillId
end
--技能释放组
function XSGMonsterBase:CastGroupSelectSkill()
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

---尝试提升当前阶段
function XSGMonsterBase:TryRiseCurPhase()
    if self:CheckRiseCurPhaseCondition() then---判断提升当前阶段的条件
        return self:RiseCurPhase()
    end
end

---尝试在进入OD时提升阶段
function XSGMonsterBase:TryRiseCurPhaseOnEnterOverDrive()
    if self:GetSwitchPhaseType() == XSGMonsterBase.SwitchPhaseType.EnterOverDrive then---判断切换阶段的条件是否是进入OverDrive时
        self:RiseCurPhase()
    end
end

---尝试在退出BK时提升阶段
function XSGMonsterBase:TryRiseCurPhaseOnExitODBreak()
    if self:GetSwitchPhaseType() == XSGMonsterBase.switchPhaseType.ExitODBreak then---判断条件是否是进入OD
    self:RiseCurPhase()
    end
end

--判断提升当前阶段的条件
function XSGMonsterBase:CheckRiseCurPhaseCondition()
    ---如果是不切换阶段的话切换阶段失败
    if (self.switchPhaseType == XSGMonsterBase.SwitchPhaseType.None)  then
        --不切换阶段
        return false
    end
    --
    --if (self.switchPhaseType == XSGMonsterBase.SwitchPhaseType.EnterOverDrive)  then
    --    --进入OD时切阶段
    --    return true
    --end
    --
    --if (self.switchPhaseType == XSGMonsterBase.SwitchPhaseType.ExitBreak)  then
    --    --退出Break时切阶段
    --    return true
    --end
    return true
end

---提升当前阶段，返回是否提升成功
function XSGMonsterBase:RiseCurPhase()
    if self:TrySetCurPhase(self:GetCurPhase()+1) then --当前阶段+1
        self:RiseCurPhaseAfter()
        return true
    end
    return false
end

---提升当前阶段后
function XSGMonsterBase:RiseCurPhaseAfter()
end

---获取切换阶段的类型
function XSGMonsterBase:GetSwitchPhaseType()
    return self.switchPhaseType
end

---设置切换阶段的类型
function XSGMonsterBase:SetSwitchPhaseType(type)
    self.switchPhaseType = type
end

---尝试设置当前阶段，不允许超过阶段上限
function XSGMonsterBase:TrySetCurPhase(phase)
    if phase > self:GetMaxPhase() then--要设置的值超过上限，设置失败。
        return false
    end
    self.curPhase = phase
    self:RelinkMonsterBaseSetVarSyncValue("curPhase",self.curPhase) --同步当前阶段
    return true
    
end

---获取当前阶段
function XSGMonsterBase:GetCurPhase()
    return self.curPhase
end

---设置上限阶段
function XSGMonsterBase:SetMaxPhase(num)
    self.maxPhase = num
end

---获取上限阶段
function XSGMonsterBase:GetMaxPhase()
    return self.maxPhase
end

--endregion

--region 韧性系统

---清空韧性值
function XSGMonsterBase:SetBreakGaugeClear()
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000476,1)--清空OD值
end

---当自己受伤时处理韧性系统
function XSGMonsterBase:HandleMonsterBrokenGaugeOnGetDamage(triggerNpc,magicTags)
    if self._proxy:CheckBuffByKind(self._uuid,8052135) then --有屏蔽逻辑时直接跳过
        return
    end
    if GameplayTag.CSMatchNoTag(magicTags,{EGameplayTag.Magic_RelinkDamage_HitType_Break}) then --非QTE就Return
        return
    end
    if not self._proxy:CheckBuffByKind(self._uuid,1000494) then--判断自己是否不存在破韧可QTE的标记
        return
    end
    self:MonsterOnBeHitBroken(triggerNpc) --被触发破韧受击
end

---被破韧后
function XSGMonsterBase:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId)
    if targetUUID ~=self._uuid then
        return
    end
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000494,1) --给自己加一个破韧状态标记
    self._proxy:ApplyMagic(self._uuid,self._uuid,8005566,1) --给自己上破韧畏缩状态，Relink数值要的一个易伤
    self:MonsterOnBeHitBroken(launcherUUID) --破韧受击
end

---被破韧受击了，向被破韧时的Npc位置释放技能
function XSGMonsterBase:MonsterOnBeHitBroken(triggerNpc)
    local triggerNpcAngle = self:GetNpcTargetAngle(self._uuid,triggerNpc)--角度判断
    local triggerDirection = self:GetNpcTargetDirection(self._uuid,triggerNpc) --左右方位判断
    local triggerPos = self._proxy:GetNpcPosition(triggerNpc)
    if triggerNpcAngle < 45 and self.brokenSkillFront then --正面破韧
        self:ForceSkillToPosition(self.brokenSkillFront,triggerPos)
    elseif triggerNpcAngle > 135 and self.brokenSkillBack then--背面受击
        self:ForceSkillToPosition(self.brokenSkillBack,triggerPos)
    elseif triggerDirection =="right"  and self.brokenSkillLeft then --右面受击
        self:ForceSkillToPosition(self.brokenSkillLeft,triggerPos)
    elseif self.brokenSkillRight then--左面受击
        self:ForceSkillToPosition(self.brokenSkillRight,triggerPos)
    end
end

---锁定削韧
function XSGMonsterBase:LockBroken()
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000469,1)
end

---解除锁定削韧
function XSGMonsterBase:UnLockBroken()
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000470,1)
end

--endregion

--region OverDrive系统

---设置OverDrive值直接变满
function XSGMonsterBase:SetOverDriveValueFull()
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000473,1)--满上OD值
    self.isODValueFull =true
end

---设置OverDrive值直接99%
function XSGMonsterBase:SetOverDriveValueAlmostFull()
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000481,1)--满上OD值
end

---清空OverDrive值
function XSGMonsterBase:SetOverDriveValueClear()
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000474,1)--清空OD值
end

---锁定OD值
function XSGMonsterBase:LockOverDriveValue()
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000465,1)
end

---解除锁定OD值
function XSGMonsterBase:UnLockOverDriveValue()
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000466,1)
end

---尝试释放OD机制技能
function XSGMonsterBase:CombatModeTryCastOverDriveSpecialSkill()
    if not self:CheckOverDriveSpecialSkillSwitch() then --判断释放机会
        return
    end
    local mode = self:GetOverDriveSpecialSkillMode()
    if mode == XSGMonsterBase.OverDriveSpecialSkillCastMode.None then--无特殊释放模式，直接消耗掉释放的机会。
        self:SetOverDriveSpecialSkillSwitch(false)
    end

    if mode == XSGMonsterBase.OverDriveSpecialSkillCastMode.Custom then--特殊机制技能要自己写，返回False表示等一等，不然直接就消耗掉了
        local isSuccess = self:OnCustomCastOverDriveSpecialSkill()
        if isSuccess or (isSuccess == nil) then--没有返回值或True那么表示成功，消耗掉。
            self:SetOverDriveSpecialSkillSwitch(false)
        end
    end
    
end

---自定义释放OD机制技能
function XSGMonsterBase:OnCustomCastOverDriveSpecialSkill()
    --XLog.Warning("OD机制要放一个试试")
end

---战斗模式里尝试进入Overdrive
function XSGMonsterBase:CombatModeTryEnterOverDrive()
    if not self.enterOverDriveSkill then --没配OD技能不进OD
        return false
    end
    self.isODValueFull = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.OverDrive) >= self._proxy:GetNpcAttribMaxValue(self._uuid,ENpcAttrib.OverDrive)
    
    if not self.isODValueFull then--OD值没有满不进OD
        return false
    end
    self:ForceSkill(self.enterOverDriveSkill)--强制释放OD技能,注意这里还不是真正的进OD
end

---退出ODBreak后
function XSGMonsterBase:OnMonsterExitBreakAfter()
end

---战斗模式里尝试进入Break循环技能
function XSGMonsterBase:FightModeTryEnterODBreakLoop()
    if not self:CheckCurOverDriveState(XSGMonsterBase.OverDriveState.BreakStart) then --检查是否在BreakStart
        return false
    end
    if not self.breakLoopSkill then --没有配置这个技能就不生效
        return false
    end
    local isSuccess , skillTime = self._proxy:TryGetNpcCurrentActionElapsedTime(self._uuid)
    if isSuccess then
        if skillTime<= self.breakStartEnterLoopDelayTime then--没到时间
            return
        end
    end
    self:MonsterEnterBreakLoop()
end
   
---检查自己当前是否可以进入OD    
function XSGMonsterBase:CheckCanOverDrive()
    if not self:CheckSelfActionValid() then --检查行动有效性
        return false
    end
    return true
end

---检查OD特殊技能开关
function XSGMonsterBase:CheckOverDriveSpecialSkillSwitch()
    return self.overDriveSpecialSkillSwitch
end

---设置OD后特殊技能开关
function XSGMonsterBase:SetOverDriveSpecialSkillSwitch(isOpen)
    self.overDriveSpecialSkillSwitch = isOpen
end

---设置OD后特殊技能的释放模式
function XSGMonsterBase:SetOverDriveSpecialSkillMode(mode)
    self.overDriveSpecialSkillCastMode = mode
end

---获取OverDrive特殊机制释放模式
function XSGMonsterBase:GetOverDriveSpecialSkillMode()
    return self.overDriveSpecialSkillCastMode
end

---当虚弱时
function XSGMonsterBase:OnBreak()

end

---当OD值满时    
function XSGMonsterBase:OnNpcOverDriveFull(targetUUID)
    if targetUUID ~= self._uuid then--非自己OD满直接返回
        return
    end
    self.isODValueFull = true --设置自己OD值是满的。
end

---进入Break。
function XSGMonsterBase:OnNpcODBreakAfter(targetUUID)
    if targetUUID ~=self._uuid then
        return
    end
    self:OnMonsterExitOverDrive()--怪物先退出Overdrive
    self:MonsterEnterBreak(targetUUID) --进入Break
end

---当退出Break后
function XSGMonsterBase:OnNpcODExitBreakAfter(targetUUID)
    self:OnMonsterExitBreak()--退出Break
end

---获取当前的ODState
function XSGMonsterBase:GetCurOverDriveState()
    return self.curODState
end

---检查当前的OverDriveState是否等于传进来的状态
function XSGMonsterBase:CheckCurOverDriveState(state)
    return self.curODState == state
end

---获取当前的ODState
function XSGMonsterBase:SetCurOverDriveState(state)
    self.curODState = state
    self:RelinkMonsterBaseSetVarSyncValue("curODState",self.curODState)
end

--检查是否要进入OD吧
function XSGMonsterBase:UpdateODNormalState(dt)
    --NormalUpdate

end

---更新ODState
function XSGMonsterBase:UpdateODODState(dt)
    --ODUpate

end

---更新Break状态
function XSGMonsterBase:UpdateODBreakingState(dt)
    --BreakingUpdate
end

---FightBase的事件，NpcEnterOverDrive
function XSGMonsterBase:OnNpcEnterOverDrive(targetUUID)
    if targetUUID ~= self._uuid then
        return
    end
    self:OnMonsterEnterOverDrive()
end

---进入OverDrive时
function XSGMonsterBase:OnMonsterEnterOverDrive()
    self.isODValueFull = false
    self:SetOverDriveSpecialSkillSwitch(true)--将OD特殊技能开启。
    self:TryRiseCurPhaseOnEnterOverDrive()--尝试进OD时提升阶段
    self:SetCurOverDriveState(XSGMonsterBase.OverDriveState.ODState)--进入OD
    self:ApplyMagicsToSelf(self.enterOverDriveMagics)--给自己挂上进入时的Magic列表
    self:LockBroken() --锁定削韧
    self:MonsterEnterOverDriveAfter()--自定义编辑的地方
end

---怪物进入OD后，自定义要做的东西
function XSGMonsterBase:MonsterEnterOverDriveAfter()
end

---进入OverDrive时
function XSGMonsterBase:OnMonsterExitOverDrive()
    self:ApplyMagicsToSelf(self.exitOverDriveMagics)--给自己退出时的Magic列表
end

---怪物进入Break状态
function XSGMonsterBase:MonsterEnterBreak(targetUUID)
    if not self:ForceSkillToNpc(self.breakStartSkill,targetUUID) then --优先对触发的目标释放该技能
        self:ForceSkill(self.breakStartSkill) --强制释放BreakStart技能
    end
    self:SetCurOverDriveState(XSGMonsterBase.OverDriveState.BreakStart) --OD状态切换到BreakStart
    --XLog.Warning("释放BreakStart，进入BKS阶段")
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052035,1) --去掉OD的通用特效
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000469,1) --锁定削韧
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052135,1) --免疫伤害受击
    self:ApplyMagicToPlayerInRange(8005201,1,999) ---给敌人上特效
    self:ApplyMagicToPlayerInRange(8052070,1,999) ---999范围内的敌人上卡肉
end

---怪物进入Break循环
function XSGMonsterBase:MonsterEnterBreakLoop()
    self:ForceSkill(self.breakLoopSkill) --强制放BreakLoop技能
    self:SetCurOverDriveState(XSGMonsterBase.OverDriveState.BreakLoop)--切换状态到循环
end

---退出虚弱状态
function XSGMonsterBase:OnMonsterExitBreak()
    --XLog.Warning("退出Break")
    self:ForceSkill(self.breakEndSkill)
    self:SetCurOverDriveState(XSGMonsterBase.OverDriveState.None)--切换到没有任何OD的状态
    self._proxy:RemoveBuff(self._uuid,8052136) --移除免疫伤害受击
    self:UnLockBroken()--解除削韧
    self:OnMonsterExitBreakAfter()
    --退出虚弱
end

---检查当前是否处于OverDrive
function XSGMonsterBase:CheckCurIsOverDrive()
    return self.curODState == XSGMonsterBase.OverDriveState.ODState
end

--endregion

--region AI控制

---设置是否开启技能测试
function XSGMonsterBase:SetSkillTestActive(isActive)
    self.isSkillTestOpen = isActive
end

---是否关闭Ai总开关，不包括测试技能AI
function XSGMonsterBase:SetAiActive(isActive)
    self.isAiOpen = isActive   --是否关闭战斗Ai：指会对玩家造成威胁的Ai
    self:RelinkMonsterBaseSetVarSyncValue("isAiOpen",self.isAiOpen) --设置AI时同步黑板
end

---设置战斗逻辑Main是否跑
function XSGMonsterBase:SetCombatLogicMainActive(isActive)
    self.isCombatLogicMainOpen = isActive
end

---设置战斗模式下的战斗逻辑AI是否开启
function XSGMonsterBase:SetCombatLogicAiActive(isActive)
    self.isCombatLogicAiOpen = isActive
end

---设置战斗模式AI
function XSGMonsterBase:SetCombatModeAiActive(isActive)
    --Ai战斗模式开关，入战和退出都不会走
    self.isCombatModeAiOpen = isActive
end

--endregion

--region 事件监听处理
function XSGMonsterBase:InitEventCallBackRegister()
    ------全局事件-----------------------------------
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- 添加buff时
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- Npc受伤伤害时
    --self._proxy:RegisterEvent(EWorldEvent.NpcExitAction)            -- 退出Action时
    self._proxy:RegisterEvent(EWorldEvent.NpcDie)            -- Npc死亡时
    self._proxy:RegisterEvent(EWorldEvent.NpcRevive)            -- Npc复活时

    -----Lua相关的事件-----------------------------------
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkAIBorn) --RelinkAI出生的时候
    --self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkSetAIActivate) --RelinkSetAIActivate
   
end
--endregion

--region 事件执行处理

function XSGMonsterBase:HandleLuaEvent(eventType, eventArgs)
    if eventType == EFightLuaEvent.RelinkAIBorn then
        if eventArgs.NpcUUid == self._uuid then --自己出生了
            self:OnMonsterSelfAIBorn()
        end
    end

    if eventType == EFightLuaEvent.RelinkSetAIActivate then
        if eventArgs.NpcUUid == self._uuid then 
            self:SetAiActive(eventArgs.IsActivated)
            if eventArgs.IsActivated then
            end
        end
    end
    
end

---Npc复活时
function XSGMonsterBase:OnNpcReviveEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
    self:TryAddNpcToThreatValueList(npcUUID)
end

---NpcDie
function XSGMonsterBase:OnNpcDieEvent(npcUUID, npcPlaceId, npcKind, isPlayer, killerUUID, magicId, deathType, deathId, rebootType, rebootId)
    if not npcUUID ==self._uuid then
        return
    end
    self:OnMonsterSelfDie()
end

---怪物自己死亡
function XSGMonsterBase:OnMonsterSelfDie()
    
end

---尝试执行事件，默认执行了一次就清空事件列表
function XSGMonsterBase:HandleCustomEvent(eventName,type)
    if #self.customEventList == 0 then
        return false
    end

    for i,event in pairs(self.customEventList) do
        if event == eventName then
            self:TryRunFunctionByString(eventName)
            self:CustomEventListClear()--清空事件列表
            return true
        end
    end
        
end

---处理动作帧事件最新事件，尝试执行事件列表最新的事件。
function XSGMonsterBase:HandleActionKeyFrameEventLatest()
    if #self.customEventList == 0 then
        return false
    end
    for i,eventName in pairs(self.customEventList) do --遍历事件列表尝试执行函数，不管成功与否
        self:TryRunFunctionByString(eventName)
    end
    self:ActionKeyFrameEventListClear()--尝试执行完毕后清空列表
end

---尝试执行对应事件名字的函数
function XSGMonsterBase:HandleActionKeyFrameEventName(eventName)
    if #self.customEventList == 0 then
        return false
    end
    if self:TryRunFunctionByString(eventName) then
        self:ActionKeyFrameEventListClear()
        return true
    end
    return false
end

---尝试执行最新的事件
function XSGMonsterBase:CheckCustomEventInList(eventName)

end

---客户端事件列表添加
function XSGMonsterBase:ActionKeyFrameEventListAdd(eventName)
    table.insert(self.customEventList,eventName)
end

---客户端事件列表移除
function XSGMonsterBase:ActionKeyFrameEventListRemove(eventName)
end

---客户端事件列表清空
function XSGMonsterBase:ActionKeyFrameEventListClear()
    self.customEventList = {}--清空自定义事件列表
end

---添加buff时事件
function XSGMonsterBase:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
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
function XSGMonsterBase:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    Base.OnNpcDamageEvent(self,launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    if targetId ~= self._uuid then --只监听自己受到的伤害
        return
    end
    self:HandleMonsterSelfOnGetDamage(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags) --怪物自己受伤的时候会调用
end

---怪物自己受伤事件
function XSGMonsterBase:HandleMonsterSelfOnGetDamage(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    self:HandleMonsterBrokenGaugeOnGetDamage(launcherId,magicTags) --受伤时处理破韧系统
    self:HandleMonsterBeHitOnGetDamage(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags) --受伤时处理受击（不包括破韧）
end

---处理怪物受到伤害时的受击
function XSGMonsterBase:HandleMonsterBeHitOnGetDamage(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    if self._proxy:CheckBuffByKind(self._uuid,8052135) then --有屏蔽逻辑时直接跳过
        return
    end
    if GameplayTag.CSMatchNoTag(magicTags,{EGameplayTag.Magic_RelinkDamage_HitType_Ultra}) then --现在只有大招类型的可以触发
        return
    end
    self:OnMonsterGetDamageBeHit(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags) --怪物受伤受击
end

---怪物受到受击伤害时
function XSGMonsterBase:OnMonsterGetDamageBeHit(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags) --怪物受伤受击
    
end

--endregion

--region 怪物本身脚本的工具函数

---关闭AI后多久开启AI
function XSGMonsterBase:SetSelfAiDelayOpen(delayTime)
    self.isAiOpen = false
    self._proxy:AddTimerTask(delayTime, function()
        self.isAiOpen = true
    end)
end


---获取数字里的前几个数字
function XSGMonsterBase:GetFirstDigits(num,n)
    -- 将数字转换为字符串
    local str = tostring(num)
    -- 截取前n个字符
    local firstPart = string.sub(str, 1, n)
    -- 转换回数字
    return tonumber(firstPart)
end

--连接两串数字
function XSGMonsterBase:ConcatNumbers(num1,num2)
    -- 将两个数字转换为字符串，然后拼接
    local result = tostring(num1) .. tostring(num2)
    -- 转换为数字返回
    return tonumber(result)
end

---获取关卡场景中心点
function XSGMonsterBase:GetLevelCenterPoint()
    return self.levelCenterPoint
end

---概率成功，输入概率，返回是否成功
function XSGMonsterBase:GetRandomSuccess(maybe)
    local isSuccess = false
    if self._proxy:Random(0, 100) < maybe then
        isSuccess = true
    end
    return isSuccess
end

---Magic给范围内的敌人
function XSGMonsterBase:ApplyMagicToPlayerInRange(magicId,level,range)
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
function XSGMonsterBase:ApplyMagicAllPlayer(magicId,level)
    local tempLevel = 1
    local npcList = self:GetPlayerListInRange(99999)
    if level then
        tempLevel = level
    end
    for i, npc in pairs(npcList) do
        self._proxy:ApplyMagic(self._uuid,npc,magicId,tempLevel)
    end
end


---打断所有玩家Action
function XSGMonsterBase:AbortActionAllPlayer()
    local tempLevel = 1
    local npcList = self:GetPlayerListInRange(99999)
    for i, npc in pairs(npcList) do
        self._proxy:AbortAction(npc,true)
    end
end

---RemoveBuff给所有玩家
function XSGMonsterBase:RemoveBuffAllPlayer(buffId,num)
    local count = 1 
    local npcList = self:GetPlayerListInRange(99999)
    if num then
        count = num
    end
    for i, npc in pairs(npcList) do
        self._proxy:RemoveBuff(npc,buffId)
    end
    
end


---ApplyMagic给所有玩家
function XSGMonsterBase:ApplyMagicOtherAllNpc(magicId,level)
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
function XSGMonsterBase:ApplyMagicsToSelf(magics)
    for i,magicId in pairs(magics)do
        self._proxy:ApplyMagic(self._uuid,self._uuid,magicId,1)
    end
end

---判断值是否在table中
function XSGMonsterBase:ValueIsInTable(value,table)
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
function XSGMonsterBase:CheckSkillLockedValid(skill)
    if self.skillLockedList[skill] then
        return false
    else
        return true
    end
end

---设置技能锁定，不能释放
function XSGMonsterBase:SetSkillLocked(skill)
    self.skillLockedList[skill] = true
end

---设置技能解锁，允许释放。
function XSGMonsterBase:SetSkillUnLocked(skill)
    self.skillLockedList[skill] = false
end

---把技能添加进锁定列表
function XSGMonsterBase:AddSkillLocked(skill)
    table.insert(self.skillLockedList,skill)
end

---通常的检查技能条件,目标是按照Ai的战斗目标去判断
function XSGMonsterBase:CheckSkillCondition(skill,target)
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
function XSGMonsterBase:CheckSkillConditionByNpc(skill,npc)
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
function XSGMonsterBase:IsSkillODStateValid(skill)
    local config = self.skillConfigs[skill]
    if not config then--没有配置条件直接返回True
        return true
    end
    if config.IsLockInODState and self:CheckCurIsOverDrive() then --OD锁定且在OD,返回F
        --XLog.Warning("技能"..skill.."释放失败，因为OD锁定且当前在OD")
        return false
    end
    if config.IsNeedODState and (not self:CheckCurIsOverDrive())then --需要OD且不在OD,返回F
        return false
    end
    return true
end

---对自己阶段有效性判断
function XSGMonsterBase:IsSkillPhaseValid(skill)
    local config = self.skillConfigs[skill]
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
function XSGMonsterBase:IsSkillHpValid(skill)
    local config = self.skillConfigs[skill]
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
function XSGMonsterBase:IsSkillDistanceValid(skill,target)
    if not target then
        return true
    end

    if not target.x then --不是位置，那就是Npc
        return self:CheckSkillDistance(skill, self._proxy:GetNpcDistance(self._uuid,target,true)) --传入目标距离去检查
    end
    
    return self:CheckSkillDistance(skill, self._proxy:GetNpcToPositionDistance(self._uuid,target,true)) --传入目标距离去检查
end

--传入技能和距离检查距离是否满足技能配置的释放条件
function XSGMonsterBase:CheckSkillDistance(skill, distances)
    
    local config = self.skillConfigs[skill]
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

--返回与目标距离是否在范围内
function XSGMonsterBase:CheckTargetDistance(distance)
    return self.targetDistance <= distance
end

---检查Npc的距离
function XSGMonsterBase:CheckSkillDisByNpc(skill, npc)
    if not self._proxy:CheckNpc(npc) then
        XLog.Warning("NPC非法,CheckSkillDisByNpc不通过" .. npc)
        return false
    end
    local dis = self._proxy:CalcNpcDistance(self._uuid, npc)
    return self:CheckSkillDistance(skill,dis)
end

---检查和目标距离是否在范围内
function XSGMonsterBase:CheckDisByTarget(distances)
    return distances <= self.targetDistance
end

--释放角度有效性判断
function XSGMonsterBase:IsSkillAngleValid(skill)
    local config = self.skillConfigs[skill]
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
function XSGMonsterBase:IsSkillTurnFixValid(skill)
    if not self.haveSkillTurnFix then
        --AI关闭了转向就不转了
        return false
    end

    local config = self.skillConfigs[skill]
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
function XSGMonsterBase:CheckHaveFunctionByString(funcName)
    if not self[funcName] then
        return false
    end
    if type(self[funcName]) ~= "function" then
        return false
    end
    return true
end

---尝试通过字符串执行函数，仅适用于不传参+不回参需求的函数。
function XSGMonsterBase:TryRunFunctionByString(funcName)
    if self:CheckHaveFunctionByString(funcName) then
        self[funcName](self)--存在这个名字的函数，直接运行函数
        return true
    else
        return false
    end
end

---尝试把Npc送进仇恨值列表
function XSGMonsterBase:TryAddNpcToThreatValueList(npc)
    if self:CheckNpcIsPlayer(npc) then
        self:AddNpcToThreatValueList(npc)
    end
end

---Npc添加进仇恨列表
function XSGMonsterBase:AddNpcToThreatValueList(npc)
    --XLog.Warning("将"..npc.."添加进仇恨列表")
    self._proxy:ApplyMagic(self._uuid, npc, 8052000, 1) --触发的Npc给自己添加1仇恨，用来添加进仇恨列表
end

---检查Npc是不是玩家
function XSGMonsterBase:CheckNpcIsPlayer(npc)
    local playerList = self._proxy:GetPlayerNpcList()
    return self:ValueIsInTable(npc,playerList)--返回是否在玩家列表
end

---获取场景中心点
function XSGMonsterBase:GetCenterPoint()
    return self._proxy
end

---获取NpcA向前朝向和NpcB的夹角
function XSGMonsterBase:GetNpcTargetAngle(npc,target)
    local npcAPos = self._proxy:GetNpcPosition(npc)
    --XLog.Warning("获取目标的朝向2")
    --XLog.Warning("npc1是："..npc)
    --XLog.Warning("目标是："..target)
    --XLog.Warning(npcAFace)
    --XLog.Warning("获取完毕")
    local npcAFace = self._proxy:GetNpcOffsetPositionByFacing(npc,{x=0,y=0,z=0},1) - npcAPos --NpcA的朝向
    local npcBPos =self._proxy:GetNpcPosition(target)
    return self:GetAngleByPosFace(npcAPos,npcAFace,npcBPos)
end

---获取目标方位根据Npc的朝向
function XSGMonsterBase:GetNpcTargetDirection(npc,target)
    local npcAPos = self._proxy:GetNpcPosition(npc)
    
    local npcAFace = self._proxy:GetNpcOffsetPositionByFacing(self._uuid, { x=0,y=0,z=0 },1) - npcAPos --NpcA的朝向
    local npcBPos =self._proxy:GetNpcPosition(target)
    return self:GetDirectionRelativePosFace(npcAPos,npcAFace,npcBPos)
end

---根据A点的朝向
function XSGMonsterBase:GetAngleByPosFace(pointA, orientationA, pointB)
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
function XSGMonsterBase:GetDirectionRelativePosFace(pointA, orientationA, pointB)
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
function XSGMonsterBase:SetPlayerHardLockSelf()
    for i , playerUUID in pairs(self._proxy:GetPlayerNpcList()) do
        self._proxy:SetHardLock(playerUUID,self._uuid)
    end
end

---检查位置到位置的距离忽略Y轴是否在范围内
function XSGMonsterBase:CheckNpcToPosDistanceIgnoreY(npcUUID,pos,dis)
    return self:GetNpcToPosDistanceIgnoreY(npcUUID,pos)<= dis
end

---检查位置到位置的距离忽略Y轴是否在范围内
function XSGMonsterBase:GetNpcToPosDistanceIgnoreY(npcUUID,pos2)
    local pos1= self._proxy:GetNpcPosition(npcUUID)
    local dx = pos2.x-pos1.x
    local dz = pos2.z-pos1.z
    return math.sqrt(dx*dx + dz *dz)
end

---检查位置到位置的距离忽略Y轴是否在范围内
function XSGMonsterBase:CheckPosToPosDistanceIgnoreY(pos1,pos2,dis)
    return self:GetPosToPosDistanceIgnore(pos1,pos2)<= dis
end

---获取位置1到位置2的忽略Y轴距离
function XSGMonsterBase:GetPosToPosDistanceIgnoreY(pos1,pos2)
    local dx = pos2.x-pos1.x
    local dz = pos2.z-pos1.z
    return math.sqrt(dx*dx + dz *dz)
end

---检查Npc是否为当前技能目标
function XSGMonsterBase:CheckNpcIsCurSkillTarget(npc)
    if not npc then
        return false
    end
    if not self.curSkillTarget then
        return false
    end
    return npc == self.curSkillTarget
end

---检查Npc是否为当前技能目标
function XSGMonsterBase:GetPositionByPosToPosOffset(pos1,pos2,offset)
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
function XSGMonsterBase:GetPlayerCountByPosRadiusIgnoreY(pos,radius)
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
function XSGMonsterBase:GetParryType(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
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
function XSGMonsterBase:CheckParryMultipleByCounter(Npc)
    
end

--endregion

--region 技能测试

---技能测试变量激活
function XSGMonsterBase:SkillTestAwake()
    self.isSkillTestOpen = false --技能测试开关，开了后会运行调试模式
    self.skillTestId = nil --测试的技能ID
    self.skillTestCd = 5 --测试技能CD，CD进入方式都是从上一个技能释放成功开始
    self.skillTestInitialCd = 2 --测试技能初始CD
    self.skillTestType = self.SkillTestType.ToTarget
end

---技能测试初始化
function XSGMonsterBase:SkillTestInit()
    if not self.isSkillTestOpen then
        return
    end
    self.skillTestTimer = self._proxy:GetFightTime() + self.skillTestInitialCd --设置初始CD
    self:UpdateVigilantRangePlayerList()--更新警戒范围敌人列表
    self:SetTarget(self:GetNearestValidTarget()) --找到最近的敌人作为战斗目标
end

---技能配置测试模块
function XSGMonsterBase:UpdateSkillTest()
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
        self:ForceSkillToTarget(self.skillTestId)
    end
    self.skillTestTimer = self._proxy:GetFightTime() + self.skillTestCd --释放成功，设置测试CD
end

---当技能测试触发自定义函数，只有自定义函数时会触发
function XSGMonsterBase:OnSkillTestTriggerCustomFuc()
    
end
--endregion

--region NpcTimer

--初始化NpcTimer
function XSGMonsterBase:InitNpcTimer(index,initCd,cd)
    if not self.timerList[index] then
        self.timerList[index]={
        }
    end
    self.timerList[index].initCd = initCd
    self:SetNpcTimerCd(index,cd)
    self:SetNpcTimerTime(index,initCd)
    self:MonsterSyncLocalNpcTimerInfo(index) --同步NpcTimer到黑板
end

---怪物同步本地NpcTimer信息
function XSGMonsterBase:MonsterSyncLocalNpcTimerInfo(index)
    self:MonsterSyncLocalNpcTimerInfoInitCd(index) --同步本地NpcTimer信息初始Cd
    self:MonsterSyncLocalNpcTimerInfoCd(index) --同步本地NpcTimer信息Cd
    self:MonsterSyncLocalNpcTimerInfoTime(index)--同步本地NpcTimer信息Time
end

---同步本地NpcTimer信息初始Cd
function XSGMonsterBase:MonsterSyncLocalNpcTimerInfoInitCd(index)
    local initBBCdKey = self:ConcatNumbers(1201,index)
    local initCdBBValue = self.timerList[index].initCd
    self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,initBBCdKey,initCdBBValue)
end

---同步本地NpcTimer信息Cd
function XSGMonsterBase:MonsterSyncLocalNpcTimerInfoCd(index)
    local cdBBKey = self:ConcatNumbers(1202,index)
    local cdBBValue = self.timerList[index].cd
    self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,cdBBKey,cdBBValue)
end

---同步本地NpcTimer信息Time
function XSGMonsterBase:MonsterSyncLocalNpcTimerInfoTime(index)
    local timeBBKey = self:ConcatNumbers(1203,index)
    local timeBBValue = self.timerList[index].time
    self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,timeBBKey,timeBBValue)
end

--设置NpcTimer的Cd
function XSGMonsterBase:SetNpcTimerCd(index,cd)
    self.timerList[index].cd = cd
end

--设置Timer时间
function XSGMonsterBase:SetNpcTimerTime(index,time)
    if time then
        self.timerList[index].time = self.npcTime + time
    end
    self:MonsterSyncLocalNpcTimerInfo(index)
end

--NpcTimer进入CD(带同步)
function XSGMonsterBase:NpcTimerEnterCd(index)
    local cd = self.timerList[index].cd
    if not cd then
        self.timerList[index].cd = 0
    end
    self.timerList[index].time = self.npcTime + self.timerList[index].cd
    self:MonsterSyncLocalNpcTimerInfoTime(index)
end

--NpcTimer进入CD(带同步)
function XSGMonsterBase:NpcTimerEnterGiveCd(index,giveCd)
    if not self.timerList[index] then
        self.timerList[index] = { }
    end
    self.timerList[index].time = self.npcTime + giveCd
    self:MonsterSyncLocalNpcTimerInfoTime(index)
end

--获取TimerCd
function XSGMonsterBase:GetNpcTimerRemainTime(index)
    local time =  self.npcTime-self.timerList[index].time
    if time <0 then
        return 0
    end
    return time
end
    
--检查Timer好了没有
function XSGMonsterBase:CheckNpcTimer(index)
    if not self.timerList[index] then
        return true
    end
    return self.npcTime >= self.timerList[index].time
end

--设置对应Index的Timer清空时间
function XSGMonsterBase:ClearNpcTimer(index)
    self.timerList[index].time = self.npcTime
end

--endregion

--region 软狂暴系统

---尝试进入软狂暴
function XSGMonsterBase:CombatModeTryEnterSoftFury()
    if not self.isHaveSoftFury then --没有软狂暴这里的逻辑就不用看
        return false
    end

    if self.isOnSoftFury then --在软狂暴就不用管了
        return
    end
    local canEnterSoftFury = self.fightTime >= self.enterSoftFuryFightTime
    if not canEnterSoftFury then
        return false
    end
    
    if self.enterSoftFurySkill then --有软狂暴技能的话要等放技能出来才算进入
        local isSuccess =self:ForceSkill(805280)
        if isSuccess then
            self:EnterSoftFury() --进入软狂暴
        end
        return
    end
    
    --没有配置技能的话就直接进入吧
    self:EnterSoftFury() --直接进入
    
end

--进入软狂暴
function XSGMonsterBase:EnterSoftFury()

    if self.enterSoftFuryMagicList then --给自己Magic一个列表
        for i,magicId in pairs(self.enterSoftFuryMagicList) do
            self._proxy:ApplyMagic(self._uuid,self._uuid,magicId)
        end
    end
    self.isOnSoftFury = true
    self:RelinkMonsterBaseSetVarSyncValue("isOnSoftFury",self.isOnSoftFury) --同步是否软狂暴
    self:OnEnterSoftFuryAfter() --进入软狂暴后要执行的东西
end

--退出软狂暴
function XSGMonsterBase:ExitSoftFury()
    
end

--进入软狂暴后
function XSGMonsterBase:OnEnterSoftFuryAfter()

end

--检查是否在软狂暴种
function XSGMonsterBase:CheckIsOnSoftFury()
    return self.isOnSoftFury
end

--endregion

--region 技能释放处理工具
--对战斗目标释放技能
---怪物对npc释放技能,会进行一系列怪物侧配置的条件判断
function XSGMonsterBase:CastSkillToNpc(skill, npc)
    if not self._proxy:CheckNpc(npc) then
        XLog.Warning("释放技能" .. skill .. "失败,Npc非法")
        return false
    end
    local isSuccess = false
    self:CheckSkillCondition(skill)
    if self:CheckSkillConditionByNpc(skill, npc) then
        isSuccess = self._proxy:CastActionToTarget(self._uuid, skill, target)
    end
    self:HandleAfterCastSkill(skill,isSuccess,npc)--处理释放技能之后
    return isSuccess
end

---无目标强制释放技能
function XSGMonsterBase:ForceSkill(skill)
    self._proxy:AbortAction(self._uuid, true) --强制打断当前技能
    local isSuccess = self._proxy:CastAction(self._uuid,skill)--强制释放这个技能
    return isSuccess
end

---强制对战斗目标释放技能（行为脚本不判断除了战斗目标合法性以外的条件）
function XSGMonsterBase:ForceSkillToTarget(skill)
    local target = self._proxy:GetFightTargetId(self._uuid)
    local isSuccess = false
    if not self._proxy:CheckNpc(target) then
        --目标不合法
        XLog.Warning("强制释放技能目标非法"..target)
        return false
    end
    self._proxy:AbortAction(self._uuid, true) --强制打断当前技能
    isSuccess = self._proxy:CastActionToTarget(self._uuid, skill, target)--对目标放技能
    self:HandleAfterCastSkill(skill,isSuccess,target)--处理释放技能之后
    return isSuccess
end

---对战斗目标释放技能（会判断配置的技能条件）
function XSGMonsterBase:CastSkillToTarget(skill)
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
    self:HandleAfterCastSkill(skill, isSuccess,target)--处理释放技能之后
    return isSuccess
end

---强制对Npc释放技能（行为脚本不判断除了Npc合法性以外的条件）
function XSGMonsterBase:ForceSkillToNpc(skill, npc)
    local isSuccess = false
    if not self._proxy:CheckNpc(npc) then
        --目标不合法
        return false
    end
    if not skill or skill == 0 then
        XLog.Warning("ForceSkillToNpc的技能非法")
    end
    self._proxy:AbortAction(self._uuid, true)--打断Npc
    isSuccess = self._proxy:CastActionToTarget(self._uuid, skill, npc)--放技能
    self:HandleAfterCastSkill(skill, isSuccess,npc)--放完技能后处理CD
    return isSuccess
end

---获得权重组里对Npc可以放的技能
function XSGMonsterBase:GetAbleSkillByWeightsToNpc(skills,npc)
    local newGroup = {}
    local totalW = 0 --总权重
    for skill, w in pairs(skills) do
        --筛选出满足条件的权重组
        if self:CheckSkillConditionByNpc(skill, npc) then
            --判断对这个Npc放技能是否满足条件
            newGroup[skill] = w
            if w then --判断w的合法性
                totalW = totalW + w --总权重
            end
        end
    end
    return self:GetWeightsKeyByTotalWeight(newGroup, totalW)
end

---从权重组里直接拿出Key(目前用于技能权重组里获取技能)
function XSGMonsterBase:GetKeyByWeights(skills)
    local totalW = 0 --总权重
    --计算总权重
    for skill, w in pairs(skills) do
        totalW = totalW + w
    end
    return self:GetWeightsKeyByTotalWeight(skills, totalW)--直接从技能组里随机一个出去
end

---对战斗目标根据权重组放技能（技能组，是否忽略技能完成）
function XSGMonsterBase:TryCastSkillToTargetByWeights(skills)
    XLog.Warning(skills)
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
function XSGMonsterBase:ForceCastSkillToTargetByWeights(skills)
    local skill = self:GetKeyByWeights(skills) --从权重组里筛出一个技能,不包括条件判断
    local isSuccess = false
    if not skill then
        return false
    end
    isSuccess = self:ForceSkillToTarget(skill)  --强制释放拿出来的技能给战斗目标
    return isSuccess
end

---强制对位置释放技能（不走怪物脚本的判断条件）
function XSGMonsterBase:ForceSkillToPosition(skill, pos)
    self._proxy:AbortAction(self._uuid, true)--打断当前技能
    local isSuccess = self._proxy:CastActionToPosition(self._uuid, skill, pos)--对位置释放技能
    self:HandleAfterCastSkill(skill, isSuccess,nil)--处理释放技能之后
end

---尝试对位置释放技能
function XSGMonsterBase:CastSkillToPosition(skill, pos)
    if not self:CheckSkillCondition(skill,pos) then --TODO:不是只有对目标，位置或Npc一样需要。
        return
    end
    self._proxy:AbortAction(self._uuid, true)--打断当前技能
    local isSuccess = self._proxy:CastActionToPosition(self._uuid, skill, pos)--对位置释放技能
    self:HandleAfterCastSkill(skill, isSuccess,nil)--处理释放技能之后
end


---输入权重组和总权重获得Key
function XSGMonsterBase:GetWeightsKeyByTotalWeight(weights, total)
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
function XSGMonsterBase:HandleAfterCastSkill(skill, isSuccess,target)
    if not isSuccess then
        --技能没有成功就不管了
        return
    end
    self.curSkillTarget = target --设置当前技能目标
    self:RelinkMonsterBaseSetVarSyncValue("curSkillTarget",self.curSkillTarget)
    self:EnterSkillCd(skill) --技能进入CD
    self:HandleCastCdLinkSkills(skill) --查看是否要把别的技能一起进入Cd
    self:OnMonsterCastSkillSuccessAfter(skill)
end

---处理技能释放成功进入Cd后是否把列表里的技能也进入Cd
function XSGMonsterBase:HandleCastCdLinkSkills(skill)
    local config = self.skillConfigs[skill]
    if not config then
        return
    end
    local skills = config.CastCdLinkSkills
    if not skills then
        return
    end
    for index,enterCdSkill in pairs(skills)do
        --XLog.Warning("释放"..skill.."时将技能"..enterCdSkill.."一起进入Cd")
        self:EnterSkillCd(enterCdSkill)
    end
end

---释放技能成功后
function XSGMonsterBase:OnMonsterCastSkillSuccessAfter(skill)
end

---设置技能CD直接完成
function XSGMonsterBase:SetSkillCdDone(skill)
    local cd = self.skillConfigs[skill].Cd
    if not cd then
        return
    end
    self.SkillCds[skill].time = self.fightTime
end

---技能进入给定的CD，不会影响原本的CD配置
function XSGMonsterBase:EnterSkillGiveCd(skill,cd)
    if not self.SkillCds[skill] then--
        self.SkillCds[skill] = {}
    end
    self.SkillCds[skill].time = self.fightTime + cd
    self:MonsterSyncLocalSKillCdInfoTime(skill)--同步本地技能Cd
end

---初始化技能cd。(带同步)
function XSGMonsterBase:InitSkillCd(skill,initCd,cd)
    self.SkillCds[skill] = {}
    self.SkillCds[skill].initCd = initCd
    self.SkillCds[skill].cd = cd
    self.SkillCds[skill].time = self.fightTime + initCd
    self:MonsterSyncLocalSKillCdInfo(skill)--初始化技能Cd需要同步黑板
end

---怪物同步本地技能信息
function XSGMonsterBase:MonsterSyncLocalSKillCdInfo(skill)
    self:MonsterSyncLocalSKillCdInfoInitCd(skill) --同步本地技能Cd信息初始Cd
    self:MonsterSyncLocalSKillCdInfoCd(skill) --同步本地技能Cd信息Cd
    self:MonsterSyncLocalSKillCdInfoTime(skill)--同步本地技能Cd信息Time
end

---同步本地技能Cd信息初始Cd
function XSGMonsterBase:MonsterSyncLocalSKillCdInfoInitCd(skill)
    local initBBCdKey = self:ConcatNumbers(1101,skill)
    local initCdBBValue = self.SkillCds[skill].initCd
    self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,initBBCdKey,initCdBBValue)
end

---同步本地技能Cd信息Cd
function XSGMonsterBase:MonsterSyncLocalSKillCdInfoCd(skill)
    local cdBBKey = self:ConcatNumbers(1102,skill)
    local cdBBValue = self.SkillCds[skill].cd
    self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,cdBBKey,cdBBValue)
end

---同步本地技能Cd信息Time
function XSGMonsterBase:MonsterSyncLocalSKillCdInfoTime(skill)
    local timeBBKey = self:ConcatNumbers(1103,skill)
    local timeBBValue = self.SkillCds[skill].time
    self._proxy:SetBBFloat(XVarDomain.Npc,self._uuid,timeBBKey,timeBBValue)
end

---重置技能CD（带同步）
function XSGMonsterBase:EnterSkillCd(skill)
    if not self.SkillCds[skill] then
        self:InitSkillCd(skill,0,0)
        return
    end
    self.SkillCds[skill].time = self.fightTime + self.SkillCds[skill].cd
    self:MonsterSyncLocalSKillCdInfoTime(skill)--同步技能CdTime
end

---检查技能Cd好了没有
function XSGMonsterBase:CheckSkillCdDone(skill)
    local info = self.SkillCds[skill]
    if not info then
        return true
    end
    return self.fightTime >= info.time--当前战斗时间是否大于配置的cd时间
end

---获取技能CD剩余时间
function XSGMonsterBase:GetSkillCdRemainTime(skill)
    local info = self.SkillCds[skill]
    local remain =  info.time - self.fightTime
    if remain <= 0 then
        return 0
    else 
        return remain
    end
end

--endregion

--region 怪物技能释放组
---清除释放组
function XSGMonsterBase:ClearCastGroup()
    self.castGroup = {}
end

---设置释放组
function XSGMonsterBase:SetCastGroup(castList)
    self.castGroup = castList
end

---获取释放组
function XSGMonsterBase:GetCastGroup()
    return self.castGroup
end

---添加技能组进释放组
function XSGMonsterBase:AddSkillsToCastGroup(group)
    table.insert(self.castGroup, group)
end

---设置技能组Cd
function XSGMonsterBase:SetSkillsCd(skillsId)
    --table.insert(self.castGroup,skillsId)
end

---从Npc自定义变量的释放组里获得一个可以对当前战斗目标可以放的技能
function XSGMonsterBase:GetAbleSkillToTargetByNpcCastGroup()
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
function XSGMonsterBase:GetAbleSkillToNpcByNpcCastGroup(npc)
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
function XSGMonsterBase:CastSkillToNpcByCastGroup(group,npc)
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
function XSGMonsterBase:GetAbleSkillToNpcByCastGroup(group,npc)
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
function XSGMonsterBase:CastSkillToTargetIgnoreSkillDoneByCastSkillGroup()
    for skillsId, skills in pairs(self.castGroup) do
        --遍历释放组去获得技能权重组
        local skill = self:GetAbleSkillByWeightsToNpc(skills, self.target) --从当前技能组里获得可以对当前目标放的技能
        if skill then
            self:ForceSkillToTarget(skill)
        end
    end
    return --如果没有技能就不放技能了。
end

--endregion

--region 怪物Ai工具类

--endregion

return XSGMonsterBase