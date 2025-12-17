---@class XFightBase
---@field _uuid number 当前脚本挂载的NpcId
---@field _proxy XDlcCSharpFuncs
local XFightBase = XClass(nil, "FightBase")

---@param proxy XDlcCSharpFuncs
function XFightBase:Ctor(proxy)
    self._proxy = proxy
end

function XFightBase:Init()
    self._uuid = self._proxy:GetSelfNpcId()
    self:InitLuaEvent()
    self:InitEventCallBackRegister()
end

---@param dt number @ delta time
function XFightBase:Update(dt)

end

---@param eventType number
---@param eventArgs userdata
function XFightBase:HandleEvent(eventType, eventArgs)
    if eventType == EWorldEvent.NpcDamage then
        self:OnNpcDamageEvent(eventArgs.LauncherId, eventArgs.TargetId, eventArgs.MagicId, eventArgs.Kind,
                eventArgs.PhysicalDamage, eventArgs.ElementDamage, eventArgs.ElementType, eventArgs.RealDamage, eventArgs.IsCritical)
    end
    if eventType == EWorldEvent.NpcCastActionBefore then
        self:OnNpcCastActionBeforeEvent(eventArgs.SkillId, eventArgs.LauncherId, eventArgs.TargetId, eventArgs.TargetSceneObjId, eventArgs.IsAbort)
    end
    if eventType == EWorldEvent.NpcCastActionAfter then
        self:OnNpcCastActionAfterEvent(eventArgs.SkillId, eventArgs.LauncherId, eventArgs.TargetId, eventArgs.TargetSceneObjId, eventArgs.IsAbort)
    end
    if eventType == EWorldEvent.NpcExitAction then
        self:OnNpcExitActionEvent(eventArgs.SkillId, eventArgs.LauncherId, eventArgs.TargetId, eventArgs.TargetSceneObjId, eventArgs.IsAbort)
    end
    if eventType == EWorldEvent.NpcDie then
        self:OnNpcDieEvent(eventArgs.NpcId, eventArgs.NpcPlaceId, eventArgs.NpcKind, eventArgs.IsPlayer)
    end
    if eventType == EWorldEvent.NpcRevive then
        self:OnNpcReviveEvent(eventArgs.NpcId, eventArgs.NpcPlaceId, eventArgs.NpcKind, eventArgs.IsPlayer)
    end
    if eventType == EWorldEvent.NpcLoadComplete then
        self:OnNpcLoadCompleteEvent(eventArgs.NpcId, eventArgs.NpcPlaceId, eventArgs.NpcKind, eventArgs.IsPlayer)
    end
    if eventType == EWorldEvent.Behavior2ScriptMsg then
        self:OnBehavior2ScriptMsgEvent(eventArgs.NpcUUID, eventArgs.MsgType, eventArgs.IntList, eventArgs.FloatList)
    end
    if eventType == EWorldEvent.NpcAddBuff then
        self:OnNpcAddBuffEvent(eventArgs.CasterUUID, eventArgs.NpcUUID, eventArgs.BuffTableId, eventArgs.BuffKinds, eventArgs.BuffId)
    end
    if eventType == EWorldEvent.NpcRemoveBuff then
        self:OnNpcRemoveBuffEvent(eventArgs.CasterUUID, eventArgs.NpcUUID, eventArgs.BuffTableId, eventArgs.BuffKinds, eventArgs.BuffId)
    end
    if eventType == EWorldEvent.MissileHit then
        self:OnMissileHitEvent(eventArgs.MissileUUID, eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.MissileDead then
        self:OnMissileDeadEvent(eventArgs.MissileUUID)
    end
    if eventType == EWorldEvent.MissileCreate then
        self:OnMissileCreateEvent(eventArgs.MissileUUID)
    end
    if eventType == EWorldEvent.NpcCalcDamageBefore then
        self:BeforeDamageCalc(eventArgs)
    end
    if eventType == EWorldEvent.NpcCalcDamageAfter then
        self:AfterDamageCalc(eventArgs)
    end
    if eventType == EWorldEvent.NpcCalcCureBefore then
        self:BeforeCureCalc(eventArgs)
    end
    if eventType == EWorldEvent.NpcCalcCureAfter then
        self:AfterCureCalc(eventArgs)
    end
    if eventType == EWorldEvent.NpcAddProtector then
        self:XNpcAddProtectorArgs(eventArgs.LauncherId, eventArgs.TargetId, eventArgs.Value, eventArgs.TotalValue, eventArgs.MagicId)
    end
    if eventType == EWorldEvent.NpcChangeProtector then
        self:XNpcChangeProtectorArgs(eventArgs.LauncherId, eventArgs.TargetId, eventArgs.Value, eventArgs.TotalValue)
    end
    if eventType == EWorldEvent.NpcDodge then
        self:OnNpcDodge(eventArgs.AttackerUUID, eventArgs.Type)
    end
    if eventType == EWorldEvent.NpcBrokenBefore then
        self:OnNpcBrokenBefore(eventArgs.LauncherUUID, eventArgs.TargetUUID, eventArgs.MagicId)
    end
    if eventType == EWorldEvent.NpcBrokenAfter then
        self:OnNpcBrokenAfter(eventArgs.LauncherUUID, eventArgs.TargetUUID, eventArgs.MagicId)
    end
    if eventType == EWorldEvent.NpcRecoverBrokenBefore then
        self:OnNpcRecoverBrokenBefore(eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcRecoverBrokenAfter then
        self:OnNpcRecoverBrokenAfter(eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcOverDriveFull then
        self:OnNpcOverDriveFull(eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcEnterOverDrive then
        self:OnNpcEnterOverDrive(eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcODBreakBefore then
        self:OnNpcODBreakBefore(eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcODBreakAfter then
        self:OnNpcODBreakAfter(eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcODExitBreakAfter then
        self:OnNpcODExitBreakAfter(eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcSkillActionEnd then
        self:OnNpcSkillActionEnd(eventArgs.SourceUUID, eventArgs.SkillId, eventArgs.SkillActionId, eventArgs.IsAbort)
    end
    if eventType == EWorldEvent.NpcTeamWorkSkillCast then
        self:OnNpcTeamWorkSkillCast(eventArgs.SourceUUID, eventArgs.Camp, eventArgs.SkillId, eventArgs.ChainCount)
    end
    if eventType == EWorldEvent.NpcTeamWorkSkillChainCountChange then
         self:OnNpcTeamWorkSkillChainCountChange(eventArgs.SourceUUID, eventArgs.Camp, eventArgs.ChainCount)
    end
    if eventType == EWorldEvent.NpcCounterSuccess then
        self:OnNpcCounterSuccess(eventArgs.TriggerNpcUUID, eventArgs.CounterNpcUUID, eventArgs.TriggerTag, eventArgs.CounterTag)
    end
    if eventType == EWorldEvent.NpcAfterSyncCounterSuccess then
        self:OnNpcAfterSyncCounterSuccess(eventArgs.TriggerNpcUUID, eventArgs.CounterNpcUUID, eventArgs.TriggerTag, eventArgs.CounterTag)
    end
    if eventType == EWorldEvent.NpcBeforeTriggerCounter then
        self:OnNpcBeforeTriggerCounter(eventArgs.TriggerNpcUUID, eventArgs.CounterNpcUUID, eventArgs.TriggerTag, eventArgs.CounterTag, eventArgs.TriggerMissileTemplateId, eventArgs.TriggerMissileUUID, eventArgs.ContextId)
    end
    if eventType == EWorldEvent.NpcAfterTriggerCounter then
        self:OnNpcAfterTriggerCounter(eventArgs.TriggerNpcUUID, eventArgs.CounterNpcUUID, eventArgs.TriggerTag, eventArgs.CounterTag)
    end
    if eventType == EWorldEvent.NpcWrestleStart then
        self:OnNpcWrestleStart(eventArgs.LauncherUUID, eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcWrestleLocked then
        self:OnNpcWrestleLocked(eventArgs.LauncherUUID, eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcWrestleReversal then
        self:OnNpcWrestleReversal(eventArgs.LauncherUUID, eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcWrestlePursuit then
        self:OnNpcWrestlePursuit(eventArgs.LauncherUUID, eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcMultiParryStart then
        self:OnNpcMultiParryStart(eventArgs.LauncherUUID, eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcMultiParrySucceed then
        self:OnNpcMultiParrySucceed(eventArgs.LauncherUUID, eventArgs.TargetUUID)
    end
    if eventType == EWorldEvent.NpcMultiParryFail then
        self:OnNpcMultiParryFail(eventArgs.LauncherUUID, eventArgs.TargetUUID)
    end
end

---@param eventType number 来自EFightLuaEvent
---@param eventArgs table
function XFightBase:HandleLuaEvent(eventType, eventArgs)
end

---@desc 生命周期里CleanUp的上一步，可以理解为脚本专用的CleanUp
---@desc 回收前调用
function XFightBase:Terminate()
    self:ClearLuaEvent()
end

--region EventCallBack
---事件注册, Buff脚本需按需求在改方法注册事件响应
function XFightBase:InitEventCallBackRegister()
end

---Npc受到伤害
---@param launcherId number 伤害发起者的UUID
---@param targetId number 伤害目标的UUID
---@param magicId number 伤害Magic的配表Id
---@param kind number 策划定义的伤害类型
---@param physicalDamage number 物理伤害
---@param elementDamage number 元素伤害
---@param elementType number 元素伤害类型
---@param realDamage number 真实伤害
---@param isCritical boolean 是否暴击
function XFightBase:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
end

---Npc释放技能前
---@param skillId number 技能ID
---@param launcherId number 发动者UUID
---@param targetId number 目标UUID
---@param targetSceneObjId number 目标场景物件PlaceId
---@param isAbort number 目标场景物件PlaceId，仅在技能退出事件中有效？
function XFightBase:OnNpcCastActionBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
end

---Npc释放技能后
---@param skillId number 技能ID
---@param launcherId number 发动者UUID
---@param targetId number 目标UUID
---@param targetSceneObjId number 目标场景物件PlaceId
---@param isAbort number 目标场景物件PlaceId，仅在技能退出事件中有效？
function XFightBase:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
end

---Npc退出技能
---@param skillId number 技能ID
---@param launcherId number 发动者UUID
---@param targetId number 目标UUID
---@param targetSceneObjId number 目标场景物件PlaceId
---@param isAbort number 目标场景物件PlaceId，仅在技能退出事件中有效？
function XFightBase:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
end

---Npc死亡
---@param npcUUID number
---@param npcPlaceId number
---@param npcKind number
---@param isPlayer boolean
function XFightBase:OnNpcDieEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
end

---Npc复活
---@param npcUUID number
---@param npcPlaceId number
---@param npcKind number
---@param isPlayer boolean
function XFightBase:OnNpcReviveEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
end

---Npc加载资源完成
---@param npcUUID number
---@param npcPlaceId number
---@param npcKind number
---@param isPlayer boolean
function XFightBase:OnNpcLoadCompleteEvent(npcUUID, npcPlaceId, npcKind, isPlayer)
end

---Npc行为树消息
---@param npcUUID number 消息源Npc的UUID
---@param msgType number 消息类型
---@param intList number int参数列表
---@param floatList number float参数列表
function XFightBase:OnBehavior2ScriptMsgEvent(npcUUID, msgType, intList, floatList)
end

---Npc添加Buff
---@param casterNpcUUID number
---@param npcUUID number
---@param buffId number
---@param buffKinds table
---@param buffUUId number
function XFightBase:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
end

---Npc移除Buff
---@param casterNpcUUID number
---@param npcUUID number
---@param buffId number
---@param buffKinds table
---@param buffUUId number
function XFightBase:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
end

---Npc移除Buff
---@param missileUUID number
---@param targetNpcUUID number 子弹目标NpcUUID
function XFightBase:OnMissileHitEvent(missileUUID, targetNpcUUID)
end

---Npc移除Buff
---@param missileUUID number
function XFightBase:OnMissileDeadEvent(missileUUID)
end

---Npc移除Buff
---@param missileUUID number
function XFightBase:OnMissileCreateEvent(missileUUID)
end

---计算伤害前
---@class BeforeDamageCalcEventArgs
---@field Launcher number 发起者NpcId
---@field Target number 目标NpcId
---@field Part number 部位ID
---@field Id number MagicId
---@field Kind number 伤害类型
---@field PhysicalPermyraid number 物理伤害倍率 
---@field ElementPermyraid number 元素伤害倍率
---@field HackDamage number 击破伤害基础值
---@field HackPermyraid number 击破倍率
---@field IsCrit bool 是否暴击
---@field ElementType number 元素类型
---@field Additive table 附加值数组 （可更改）
---@param eventArgs BeforeDamageCalcEventArgs
function XFightBase:BeforeDamageCalc(eventArgs)
end

---计算伤害后
---@class AfterDamageCalcEventArgs
---@field Launcher number 发起者NpcId
---@field Target number 目标NpcId
---@field Part number 部位ID
---@field Id number MagicId
---@field Kind number 伤害类型
---@field PhysicalDamage number 物理伤害（可更改）
---@field ElementDamage number 元素伤害（可更改）
---@field PhysicalPermyraid number 物理伤害倍率 
---@field ElementPermyraid number 元素伤害倍率 
---@field HackDamage number 击破伤害基础值
---@field HackPermyraid number 击破倍率
---@field FinalHackDamage number 最终破击伤害（可更改）
---@field RealDamage number 真实伤害 （Relink暂时无用）
---@field ElementType number 元素类型
---@field IsCrit bool 是否暴击
---@param eventArgs AfterDamageCalcEventArgs
function XFightBase:AfterDamageCalc(eventArgs)
end

---@class BeforeCureCalcEventArgs
---@field Launcher number 发起者NpcId
---@field Target number 目标NpcId
---@field Id number MagicId
---@field AttribType number 参照属性类型
---@field Type number 计算类型
---@field Value number 基础值（可更改）
---@field Permyriad number 倍率（可更改）
---@field Additive table 附加值数组 （可更改）
---计算治疗前
---@param eventArgs AfterDamageCalcEventArgs
function XFightBase:BeforeCureCalc(eventArgs)

end

---@class AfterCureEventArgs
---@field Launcher number 发起者NpcId
---@field Target number 目标NpcId
---@field Id number MagicId
---@field AttribType number 参照属性类型
---@field Type number 计算类型
---@field Value number 基础值
---@field Permyriad number 倍率
---@field FinalValue number FinalValue：计算最终值
---计算治疗后
---@param eventArgs AfterCureEventArgs
function XFightBase:AfterCureCalc(eventArgs)

end

---@param LauncherId number 发起者NpcId
---@param TargetId number 目标NpcId
---@param Value number 获得的护盾值
---@param TotalValue number 当前总护盾值
---@param MagicId number magicId
function XFightBase:XNpcAddProtectorArgs(LauncherId, TargetId, Value, TotalValue, MagicId)

end

---@param LauncherId number 发起者NpcId
---@param TargetId number 目标NpcId
---@param Value number 获得的护盾值
---@param TotalValue number 当前总护盾值
function XFightBase:XNpcChangeProtectorArgs(LauncherId, TargetId, Value, TotalValue)

end

---@class XNpcDodgeEventArgs
---@field AttackerUUID number 被闪避目标
---@field Type number 闪避窗口类型
---触发闪避成功
---@param eventArgs XNpcDodgeEventArgs
function XFightBase:OnNpcDodge(AttackerUUID, Type)

end

--region 韧性事件

---Npc破韧前
---@param launcherUUID number 发起者的UUID
---@param targetUUID number 目标的UUID
---@param magicId number Magic的配表Id
function XFightBase:OnNpcBrokenBefore(launcherUUID, targetUUID, magicId)
end

---Npc破韧后
---@param launcherUUID number 发起者的UUID
---@param targetUUID number 目标的UUID
---@param magicId number Magic的配表Id
function XFightBase:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId)
end

---Npc恢复破韧前
---@param targetUUID number 目标的UUID
function XFightBase:OnNpcRecoverBrokenBefore(targetUUID)
end

---Npc恢复破韧后
---@param targetUUID number 目标的UUID
function XFightBase:OnNpcRecoverBrokenAfter(targetUUID)
end

---Npc OD满
---@param targetUUID number 目标的UUID
function XFightBase:OnNpcOverDriveFull(targetUUID)
end

---Npc 进入OD
---@param targetUUID number 目标的UUID
function XFightBase:OnNpcEnterOverDrive(targetUUID)
end

---Npc OD Break前
---@param targetUUID number 目标的UUID
function XFightBase:OnNpcODBreakBefore(targetUUID)
end

---Npc OD Break后
---@param targetUUID number 目标的UUID
function XFightBase:OnNpcODBreakAfter(targetUUID)
end

---Npc OD 退出Break后
---@param targetUUID number 目标的UUID
function XFightBase:OnNpcODExitBreakAfter(targetUUID)
end

--endregion

---Npc一个SkillAction完成
---@param sourceUUID number 来源UUID
---@param skillId number 技能ID
---@param skillActionId number ActionID
---@param isAbort number 是否打断
function XFightBase:OnNpcSkillActionEnd(sourceUUID, skillId, skillActionId, isAbort)
end

---Npc团队极限技释放成功
---@param sourceUUID number 来源UUID
---@param camp number 阵营
---@param skillId number 技能ID
---@param chainCount number 当前连锁数
function XFightBase:OnNpcTeamWorkSkillCast(sourceUUID, camp, skillId, chainCount)
end

---Npc团队极限技连锁
---@param sourceUUID number 来源UUID
---@param camp number 阵营
---@param chainCount number 当前连锁数
function XFightBase:OnNpcTeamWorkSkillChainCountChange(sourceUUID, camp, chainCount)
end

--region 弹刀

---Npc本端弹刀反制成功后
---@param triggerNpcUUID number 被弹刀NpcUUID
---@param counterNpcUUID number 弹刀NpcUUID
---@param triggerTag table 被弹刀子弹Tag intList
---@param triggerTag table 弹刀子弹Tag intList
function XFightBase:OnNpcCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
end

---Npc经对手校验后弹刀反制成功后
---@param triggerNpcUUID number 被弹刀NpcUUID
---@param counterNpcUUID number 弹刀NpcUUID
---@param triggerTag table 被弹刀子弹Tag intList
---@param triggerTag table 弹刀子弹Tag intList
function XFightBase:OnNpcAfterSyncCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
end

---Npc被弹刀反制前
---@param triggerNpcUUID number 被弹刀NpcUUID
---@param counterNpcUUID number 弹刀NpcUUID
---@param triggerTag table 被弹刀子弹Tag intList
---@param triggerTag table 弹刀子弹Tag intList
---@param triggerMissileTemplateId number 弹刀触发盒子弹配置Id (被弹刀的子弹)
---@param triggerMissileUUID number 弹刀触发盒子弹UUID (被弹刀的子弹)
---@param contextId number 上下文ID
function XFightBase:OnNpcBeforeTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
end

---Npc被弹刀反制后
---@param triggerNpcUUID number 被弹刀NpcUUID
---@param counterNpcUUID number 弹刀NpcUUID
---@param triggerTag table 被弹刀子弹Tag intList
---@param triggerTag table 弹刀子弹Tag intList
function XFightBase:OnNpcAfterTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
end

--endregion

--region 角力事件

---Npc角力开始
---@param launcherNpcUUID number 被弹刀NpcUUID
---@param targetNpcUUID number 弹刀NpcUUID
function XFightBase:OnNpcWrestleStart(launcherNpcUUID, targetNpcUUID)
end

---Npc角力僵持
---@param launcherNpcUUID number 被弹刀NpcUUID
---@param targetNpcUUID number 弹刀NpcUUID
function XFightBase:OnNpcWrestleLocked(launcherNpcUUID, targetNpcUUID)
end

---Npc角力顶开
---@param launcherNpcUUID number 被弹刀NpcUUID
---@param targetNpcUUID number 弹刀NpcUUID
function XFightBase:OnNpcWrestleReversal(launcherNpcUUID, targetNpcUUID)
end

---Npc角力追击
---@param launcherNpcUUID number 被弹刀NpcUUID
---@param targetNpcUUID number 弹刀NpcUUID
function XFightBase:OnNpcWrestlePursuit(launcherNpcUUID, targetNpcUUID)
end

--region 多人弹刀

---Npc多人弹刀开始
---@param launcherNpcUUID number 被弹刀NpcUUID
---@param targetNpcUUID number 弹刀NpcUUID
function XFightBase:OnNpcMultiParryStart(launcherNpcUUID, targetNpcUUID)
end

---Npc多人弹刀成功
---@param launcherNpcUUID number 被弹刀NpcUUID
---@param targetNpcUUID number 弹刀NpcUUID
function XFightBase:OnNpcMultiParrySucceed(launcherNpcUUID, targetNpcUUID)
end

---Npc多人弹刀失败
---@param launcherNpcUUID number 被弹刀NpcUUID
---@param targetNpcUUID number 弹刀NpcUUID
function XFightBase:OnNpcMultiParryFail(launcherNpcUUID, targetNpcUUID)
end

--endregion

--endregion

--region LuaEvent
---初始化Lua事件列表
---@private
function XFightBase:InitLuaEvent()
    self._luaEventDict = {}
end

---注册Lua事件
---@param eventType number 来自EFightLuaEvent
function XFightBase:RegisterLuaEvent(eventType)
    if self._luaEventDict[eventType] then
        return
    end
    self._luaEventDict[eventType] = true
    self._proxy:RegisterLuaEvent(eventType)
end

---注销Lua事件
---@param eventType number 来自EFightLuaEvent
function XFightBase:UnRegisterLuaEvent(eventType)
    if not self._luaEventDict[eventType] then
        return
    end
    self._luaEventDict[eventType] = false
    self._proxy:UnregisterLuaEvent(eventType)
end

---派发Lua事件
---@param targetType number 来自ELuaEventTarget
---@param eventType number 来自EFightLuaEvent
---@param eventArgs table
function XFightBase:DispatchLuaEvent(targetType, eventType, eventArgs)
    self._proxy:DispatchLuaEvent(targetType, eventType, eventArgs)
end

---@private
function XFightBase:ClearLuaEvent()
    for eventType, _ in pairs(self._luaEventDict) do
        self:UnRegisterLuaEvent(eventType)
    end
end
--endregion

--region Random
---在一个选项List里随机选择一个选项
---@param list table
function XFightBase:GetValueByListRandom(list)
    if not list then
        return nil
    end
    local listCount = #list
    local listIndex = 1
    if listCount == 1 then
        listIndex = 1
    else
        listIndex = self._proxy:Random(1, #list)
    end
    return list[listIndex]
end

---在一个选项全是function的List里随机选择一个function并执行
---@param list table<number, function>
function XFightBase:DoFuncByListRandom(list)
    local func = self:GetValueByListRandom(list)
    if func and type(func) == "function" then
        func()
    else
        XLog.Error("[XFightBase] DoFuncByListRandom func is fail, please check the param!")
    end
end

---在一个key为选项 value为选项权值的Dict根据权值随机发里随机选择一个选项
---@param weightDict table key为选项 value为选项权值
function XFightBase:GetValueByWeightRandom(weightDict)
    if not weightDict then
        return nil
    end
    -- 第一步：计算总权值
    local totalWeight = 0
    for _, weight in pairs(weightDict) do
        totalWeight = totalWeight + weight
    end

    -- 第二步：生成随机数（注意：Lua的math.random()需要先调用math.randomseed(os.time())初始化）
    local randomPoint = self._proxy:Random(1, totalWeight)

    -- 第三步：遍历查找对应的选项
    local accumulated = 0
    for option, weight in pairs(weightDict) do
        accumulated = accumulated + weight
        if accumulated >= randomPoint then
            return option
        end
    end
end

---在一个key为function类型的选项 value为选项权值的Dict根据权值随机发里随机选择一个选项
---@param dict table<function, number> key为选项 value为选项权值
function XFightBase:DoFuncByWeightRandom(dict)
    local func = self:GetValueByWeightRandom(dict)
    if func and type(func) == "function" then
        func()
    else
        XLog.Error("[XFightBase] DoFuncByWeightRandom func is fail, please check the param!")
    end
end
--endregion

--region GameplayTags
--- 检测一个tags列表内是否含有目标tag
--- @param tags @ tags列表(C# List)
--- @param EGameplayTag @ 需要检测存在的目标tag
--- @return bool @ 是否包含
function XFightBase:ContainsGameplayTag(tags, targetTag)
    for i = 0, tags.Count - 1, 1 do
        if tags[i] == targetTag then
            return true
        end
    end
    return false
end
--endregion

return XFightBase
