local base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")

---自走棋自动战斗角色脚本
---@class XAFKCharBase : XFightBase
local XAFKCharBase = XClass(base, "XAFKCharBase")

XAFKCharBase.FireActionType = {  --定义当前筛选的释放类型
    None = 0,
    First = 1,
    Tail = 2,
    Normal = 3,
    Combo = 4,
}

function XAFKCharBase:Init() --初始化
    base.Init(self)

    ---------自走棋普攻处理---------
    self.normalAttackList={} --新建普攻列表
    self.afkCharConfig = self._proxy:GetAutoChessCharacterConfig(self._proxy:GetAutoChessCharacterId(self._uuid)) --获取AFK角色配置
    self.nextNormalAttackIndex = 1   --当前准备要释放的普攻击编号
    
    --移动配置--------------------------------------------------------------------------
    self.followTargetMinDis = 1
    self.followTargetMaxDis = 3
    self.followTargetHeartBeat = 1
    self.moveSkillId = nil  ------如果有配置这个技能ID的话移动方式会使用moveSkillId

    --AI核心--------------------------------------------------------------------------
    self.isFightAiOpen = false  --是否开启AI，这里指的是玩家完全没有控制的AI，比如怪物或队友（

    --状态管理--------------------------------------------------------------------------
    self.isAutoCastSkill = false  --Relink要用的辣:自动释放技能模式
    self.isAutoMove = false     --Relink可能要用的辣：自动移动模式
    self.lastFireActionType = XAFKCharBase.FireActionType.None  --上一个释放成功的FireAction

    --战斗信息--------------------------------------------------------------------------------------------------------------
    self.fightTime = 0

    self.isFightingState = false         --是否处于战斗状态
    self.selfHpPercent = 0              --自己血量百分比
    self.selfPos = { x = 0, y = 0, z = 0 }        --自己位置
    self.selfFacing = { x = 0, y = 0, z = 0 }    --自己朝向

    self.targetUUID = nil                --当前目标UUID
    self.targetHpPercent = 0            --目标血量百分比
    self.targetDistance = 0               --和目标距离
    self.targetPos = { x = 0, y = 0, z = 0 }     --目标位置
    self.targetFacing = { x = 0, y = 0, z = 0 }  --目标朝向

    self._playerNpcUUID = nil

    self.playerDistance = 0             --和玩家距离
    self.playerPos = { x = 0, y = 0, z = 0 }        --玩家位置
    self.PlayerFacing = { x = 0, y = 0, z = 0 }  --玩家朝向
    self.playerFightState = 0           --玩家的战斗状态

    --战场配置--------------------------------------------------------------------------
    self.EnterBattleDistance = 15  --初次入战距离

    --技能释放模块
    self.GoToFightDistance = 5  --回到战场距离
    
    --技能距离要求配置--------------------------------------------------------------------------------------------------
    self.skillCastDistanceDic = {  --配置技能的释放距离
    }
    self:AddItemSkill(self.afkCharConfig.NormalAttack) --给自己添加普攻技能
    --Como执行-----------------------------------------------------------------------------------------------------
    self.ItemSkillComboDic = {  --根据ItemSkillID保存ComboList的字典，用来读取

    }
    
    self.comboList = {} --ComboList存储剩余要释放的Combo，PS：系统技能ID释放两个以上才会保存在这个列表

    self.currentItemSkillId = nil --当前ItemSkill的Id，如果是Nil说明为空
    self.currentComboLastSkillId = nil   --当前combo的最后一个技能ID

    --队列AI存储-------------------------------------------------------------------------------------------------------
    self.firstList = { --根据队列类型-队列Action往队首插
    }

    self.tailList = {  --根据队列类型-队列Action往队尾插
    }

    --------------------------------------------------------------------------------------------------

    ------设置一下默认的玩家控制的ID--------------------------------------------------------------------------
    self._playerNpcUUID = self._proxy:GetLocalPlayerNpcId() --玩家ID


    --启用标哥打的跟随补丁。
    ---@type XNpcFollowController
    self._followController = XNpcFollowController.New(self._proxy, self._uuid, true) --New跟随组件
    
    self.skillAfterDelayMaxTime = 0.23 --Delay时间最长是多少,单位是秒，配0.2秒就是技能释放会Delay0-0.2秒最多小数点后两位数。（配置小数点后超过两位数会失效）
    self.skillDelayTime = 0 --初始化默认值，这个值在每次释放技能成功后都会重新设置一遍。
    self.skillDelayTimer = nil
end

---@param dt number @ delta time 
function XAFKCharBase:Update(dt)

    if not self.isFightingState then--检查入战
        self:UnBattleModule(dt)
    end
    
    if not self.isFightAiOpen then  --关闭了AI则不会走下面逻辑
        return
    end
    
    if self.isFightingState then --运行战斗模块
        self:BattleModule(dt) --运行战斗模块
    end
    
end

---@param eventType number
---@param eventArgs userdata
function XAFKCharBase:HandleEvent(eventType, eventArgs)
    base.HandleEvent(self, eventType, eventArgs)
end

---@param eventType number 来自EFightLuaEvent
---@param eventArgs table
function XAFKCharBase:HandleLuaEvent(eventType, eventArgs)
    
    if eventType == EFightLuaEvent.AutoChessSetAIEnable then --设置AI开关
        self:OnLuaSetAiEnableEvent(eventArgs.Enable)
    end

    if eventType == EFightLuaEvent.AutoChessTriggerItemSkill then --触发ItemSkill
        self:OnLuaAutoChessTriggerItemSkill(eventArgs.NpcUUid,eventArgs.ItemSkillId)
    end
end
function XAFKCharBase:Terminate()
    self._followController:Terminate()
end

--region EventCallBack
function XAFKCharBase:InitEventCallBackRegister()
    ------全局事件-----------------------------------
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore)         -- OnNpcCastActionBeforeEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
    
    ------自定义Lua事件-----------------------------------
    self:RegisterLuaEvent(EFightLuaEvent.AutoChessSetAIEnable)       --注册AI设置事件
    self:RegisterLuaEvent(EFightLuaEvent.AutoChessTriggerItemSkill)       -- 注册触发itemSkill事件
end

function XAFKCharBase:OnLuaSetAiEnableEvent(isAiOpen)  --设置AI开关
    
    self:FightAiSwitch(isAiOpen)  --设置AI开关
end

function XAFKCharBase:OnLuaAutoChessTriggerItemSkill(triggerNpc,itemSkillId)  --触发ItemSkillID
    if not (triggerNpc == self._uuid) then  --只接收自己触发的
        return
    end
    
    self:AddItemSkill(itemSkillId) --调用触发技能事件
end

function XAFKCharBase:OnNpcCastActionBeforeEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then --不是自己放的技能不用管
        return
    end

    self._proxy:SetNpcFaceToPosition(self._uuid, self._proxy:GetNpcPosition(self.targetUUID)) --如果是自己释放的就设置自己看向目标
end

function XAFKCharBase:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~=self._uuid then
        return
    end
    
    if buffId == 1010027 then  --AI开启
        self:FightAiSwitch(true)
    end

    if buffId == 1010028 then  --AI关闭
        self:FightAiSwitch(false)
    end
    
end

function XAFKCharBase:GetAfkTarget() --获得自走棋敌人
    local playerUUID = self._proxy:GetAutoChessNpc(true)
    local enemyUUID = self._proxy:GetAutoChessNpc(false)

    if playerUUID == self._uuid then --自己是玩家的话
        return enemyUUID
    else
        return playerUUID
    end
end


--region BattleModule
function XAFKCharBase:BattleModule(dt) --战斗模块
    if self:OutBattleCheck() then --退出战斗检测，死亡或濒死等
        self.targetUUID = nil --战斗结束，清空战斗目标
        self._proxy:RemoveFightTarget(self._uuid) --清除战斗目标
        self:OnOutBattle()         --退出战斗要执行的内容
        return --退出战斗
    end
    self:ComboEndCheck() --检查Combo断连
    
    if not self:IsValidSkillDelayTimer() then --判断技能延迟执行有效性 TODO:未来如果要做打断的话需要做打断相关的保底
        return
    end
    
    local fireSuccess, actionType = self:TryFire()
    if  fireSuccess then  --释放技能成功
        if (actionType == XAFKCharBase.FireActionType.First) or (actionType == XAFKCharBase.FireActionType.Tail) then  --首尾队列释放成功
            --留空，不敢改，改了怕出bug
        end
    else                  --释放技能失败
        if actionType ~= XAFKCharBase.FireActionType.None then
            self:AfkAiMove(dt)
        end
    end
end

function XAFKCharBase:UnBattleModule(dt) --非战斗模块
    if self:EnterBattleCheck() then  --入战检测
        self:OnEnterBattle()  --入战要处理的内容
        return
    end

    -- self._followController:Update(dt)  --没有入战时不跟随
end

function XAFKCharBase:EnterBattleCheck()  --进入战斗检测
    local isEnterBattle = false
    local enemyUUID = self:GetAfkTarget()--找到Afk里的敌人
    
    if (enemyUUID) and (enemyUUID~=0) then                    --找到了敌人
        self.targetUUID = enemyUUID   --把当前目标设置成找到的敌人
        self._proxy:SetFightTarget(self._uuid, enemyUUID)
        isEnterBattle = true
    end

    return isEnterBattle
end

function XAFKCharBase:OnEnterBattle() --进入战斗时执行的逻辑
    local followTargetMinDis = self.followTargetMinDis
    local followTargetMMaxDis = self.followTargetMaxDis
    local followTargetHeartBeat = self.followTargetHeartBeat

    self.isFightingState = true
    self._followController:SetFollowTargetNpcNoNavMesh(self.targetUUID, followTargetMinDis, followTargetMMaxDis, followTargetHeartBeat)  --跟随目标设置成当前目标
    self._proxy:SetNpcFocusTarget(self._uuid,self.targetUUID)
end

function XAFKCharBase:OutBattleCheck()  --退出战斗检测
    local target = self.targetUUID
    local isOutBattle = false

    if (target == 0) or (not target) then
        return true
    end

    if not self._proxy:CheckNpc(target) then
        return true
    end
    
    if self._proxy:CheckNpcFullActionState(target, ENpcAction.Dying, -1) or self._proxy:CheckNpcFullActionState(target, ENpcAction.Death, -1) then
        return true
    end

    return isOutBattle
    
end

function XAFKCharBase:UpdateFightInfo()  --更新战斗信息
    --敌我Player血量刷新
end

function XAFKCharBase:OnOutBattle()
    --退出战斗时
    self.isFightingState = false
    self._followController:CancelFollow() --根据组件清空
    self.nextNormalAttackIndex = 1 --重置普攻
    self:ComboEnd()
end
--endregion

--region Victory
function XAFKCharBase:OnVictory()--胜利时
end
--endregion

--region Action模块
function XAFKCharBase:IsValidSkillDelayTimer()--判断延迟释放技能有效性
    
    if not self._proxy:CheckNpcFullActionState(self._uuid,ENpcAction.Skill)then --不在技能，清空Timer
        self.skillDelayTimer = nil --清空技能DelayTimer
        return true
    end

    if not (self._proxy:CheckCanCastSkill(self._uuid) and self._proxy:CheckNpcCurActionIsDone(self._uuid)) then --判断是否在技能后摇
        self.skillDelayTimer = nil --不在后摇，清空Timer
        return false
    end
    if not self.skillDelayTimer then --进入后摇设置Timer。
        self:SetSkillDelayTime() --随机一个DelayTime
        self.skillDelayTimer = self._proxy:GetFightTime() + self.skillDelayTime --设置技能DelayTimer时间
    end

    if self._proxy:GetFightTime() > self.skillDelayTimer then --过了delayTimer
        return true
    end
    
    
    return false
end

function XAFKCharBase:TryFire()--尝试攻击
    local nextSkillID = 0   --下一个要放的技能是0,重新通过筛选获得。
    local actionType = XAFKCharBase.FireActionType.None  --当前的释放模式
    local isHaveCombo = #self.comboList > 0  --是否有Combo待执行列表
    local listItemId = 0
    
    ------SkillIdSelect-------------技能ID筛选-------------------------------------------------------------------

    if isHaveCombo then
        nextSkillID = self.comboList[1] --释放列表里的第一个
        actionType = XAFKCharBase.FireActionType.Combo
    elseif #self.firstList > 0 then
        listItemId = self.firstList[1]
        nextSkillID = self.ItemSkillComboDic[listItemId] [1]  --首列第一个ItemSkillId的第一个技能ID
        actionType = XAFKCharBase.FireActionType.First
        --self.nextNormalAttackIndex = 1-- 重置普攻为1
    elseif #self.tailList > 0 then
        listItemId = self.tailList[1]
        nextSkillID = self.ItemSkillComboDic[listItemId] [1]  --首列第一个ItemSkillId的第一个技能ID
        actionType = XAFKCharBase.FireActionType.Tail
        --self.nextNormalAttackIndex = 1 --重置普攻为1
    elseif #self.normalAttackList > 0 then --需要普攻列表不为空
        if self.lastFireActionType ~= XAFKCharBase.FireActionType.Normal then --上一个不是普攻的话要重置普攻
            self.nextNormalAttackIndex = 1
        end
        actionType = XAFKCharBase.FireActionType.Normal
        nextSkillID = self.normalAttackList[self.nextNormalAttackIndex]   --要放的普攻技能Id
    end

    if nextSkillID == nil or nextSkillID == 0 then
        return false, actionType   --执行失败和筛选到的行为类型
    end

    self.lastFireActionType = actionType  --保存上一次筛选的类型
    return self:DoAction(actionType, nextSkillID,listItemId), actionType--返回是否执行成功和筛选到的行为类型
end

function XAFKCharBase:IsInSkillReleaseRange(casterUUID,targetUUID,skillID,actiontype)--是否在技能释放范围内
    local skillCastDistanceNeed = nil   --是否需要距离要求，需要的话会赋值具体的值。

    skillCastDistanceNeed = self.skillCastDistanceDic[skillID] --检查有没有配置距离要求。

    if not skillCastDistanceNeed then   --技能释放没有距离要求
        return true
    end

    if self._proxy:CheckNpcDistance(casterUUID, targetUUID, skillCastDistanceNeed) then --有距离要求时会赋值对应的距离，检查是否在释放距离内。
        return true
    end
    
    return false
end

function XAFKCharBase:DoAction(ACTION_Type, Skill_ID, ItemSkillId) --执行Action
    local selfUUID = self._uuid           --自己的UUID
    local targetUUID = self.targetUUID   --目标的UUID
    local isActionSuccess  --Action是否成功

    if self:IsInSkillReleaseRange(selfUUID, targetUUID, Skill_ID, ACTION_Type) then --技能释放距离检查,没有在列表里的说明没有要求，无距离要求释放
        isActionSuccess = self._proxy:CastActionToTarget(self._uuid, Skill_ID, targetUUID) --释放技能是否成功
    else
        if ACTION_Type == XAFKCharBase.FireActionType.Combo then
            self.comboList = {} --combo只有一次失败的机会，不满足需要的释放距离就清空了。
        end
    end

    if isActionSuccess then --如果技能释放成功
        ---------------------------------------------技能释放成功后基础执行逻辑---------------------------------------------
        if ACTION_Type == XAFKCharBase.FireActionType.Combo then                   ------Combo
            table.remove(self.comboList, 1)
        elseif ACTION_Type == XAFKCharBase.FireActionType.First then               ------首列表
            table.remove(self.firstList, 1)
        elseif ACTION_Type == XAFKCharBase.FireActionType.Tail then                 ------尾列表
            table.remove(self.tailList, 1)
        elseif ACTION_Type == XAFKCharBase.FireActionType.Normal then               ------普攻
            if self.nextNormalAttackIndex == #self.normalAttackList then
                self.nextNormalAttackIndex = 1 --重置普攻
            else
                self.nextNormalAttackIndex = self.nextNormalAttackIndex + 1--普攻Index+1
            end
        end
        ---------------------------------------------技能释放成功后补充Combo相关逻辑处理---------------------------------------------
        if (ACTION_Type == XAFKCharBase.FireActionType.First) or (ACTION_Type == XAFKCharBase.FireActionType.Tail) then
            self.currentItemSkillId = ItemSkillId --设置当前的ItemSkillId
            self:ComboStart()--释放combo要做的事情
        end
    end
    return isActionSuccess
end

function XAFKCharBase:ComboStart() --Combo开始，发送事件
    ----------------------------Combo开始处理 ----------------------------
    local tempComboList = {}
    for i = 1, #self.ItemSkillComboDic[self.currentItemSkillId] do
        table.insert(tempComboList,self.ItemSkillComboDic[self.currentItemSkillId][i])

        if i == #self.ItemSkillComboDic[self.currentItemSkillId] then  --保存最后一个技能ID
            self.currentComboLastSkillId = self.ItemSkillComboDic[self.currentItemSkillId][i]
        end
    end
    table.remove(tempComboList, 1) --列表里删除第一个
    if #tempComboList > 0 then
        self.comboList = tempComboList --剩余没放完的技能扔进ComboList里继续发光发热
    end

    ----------------------------发送事件通知别人Combo第一个技能释放完毕 ----------------------------
    ---@type XLuaEventArgsAutoChessItemSkillComboEnd
    local eventArgs = {
        NpcUUid = self._uuid,
        ItemSkillId = self.currentItemSkillId
    }
    self:DispatchLuaEvent(ELuaEventTarget.Npc+ELuaEventTarget.Buff, EFightLuaEvent.AutoChessItemSkillComboStart, eventArgs)
end

function XAFKCharBase:ComboEndCheck() --检查Combo是否结束
    
    if not self.currentItemSkillId then
        return
    end

    if #self.comboList >0 then
        return
    end
    
    if self._proxy:CheckNpcCurrentAction(self._uuid,self.currentComboLastSkillId) then --如果正在最后一个技能过程中
        if self._proxy:CheckNpcCurActionIsDone(self._uuid) then  --技能过程中后摇属于End
            self:ComboEnd()
        end
    else
        self:ComboEnd()
    end
end

function XAFKCharBase:ComboEnd() --Combo结束，发送事件
    ----------------------------发送事件通知别人Combo已经结束 ----------------------------
    ---@type XLuaEventArgsAutoChessItemSkillComboEnd
    local eventArgs = {
        NpcUUid = self._uuid,
        ItemSkillId = self.currentItemSkillId
    }
    self:DispatchLuaEvent(ELuaEventTarget.Npc+ELuaEventTarget.Buff, EFightLuaEvent.AutoChessItemSkillComboEnd, eventArgs)
    
    self.comboList={}
    self.currentItemSkillId=nil
    self.currentComboLastSkillId=nil
end

function XAFKCharBase:AddItemSkill(ItemSkillId)--触发了ItemSkill
    
    if (not ItemSkillId) or (ItemSkillId == 0 ) then
        XLog.Warning("添加ItemSkill"..ItemSkillId.."失败")
        return
    end
    
    local config = self._proxy:GetAutoChessSkillConfig(ItemSkillId) --通过ID获取技能配置
    local type = config.Type  --队列类型
    --local range =config.range --释放距离
    local comboList = {}  --处理ComboList
    
    if type == 4 then --如果添加的技能类型是普攻就会替换当前的普攻
        self.normalAttackList={}--清空普攻队列
        for i = 0 ,config.ComboList.Count -1 do --遍历获得普攻列表
            local skillId = config.ComboList[i]
            table.insert(self.normalAttackList,skillId)
            if i == 0 then
                self.skillCastDistanceDic[skillId] = config.Range --把ComboList第一个技能添加进释放距离要求
            end
        end
        return
    end

    --如果没有在字典里的就处理成ComboList保存下来，以便之后直接调用使用。
    if not self.ItemSkillComboDic[ItemSkillId] then --
        for i = 0, config.ComboList.Count - 1 do
            local skillId = config.ComboList[i]
            table.insert(comboList,skillId)
            if i == 0 then
                self.skillCastDistanceDic[skillId] = config.Range --把ComboList第一个技能添加进释放距离要求
            end
        end
        self.ItemSkillComboDic[ItemSkillId] = comboList
    end
    
    if type == 1 then      --队尾
        table.insert(self.tailList, #self.tailList + 1, ItemSkillId) --在队尾列表往后插入ActionID
    elseif type == 2 then  --队首
        table.insert(self.firstList, 1, ItemSkillId) --在队首列表往前插入ActionID
    end
end

function XAFKCharBase:SetSkillDelayTime() --获取随机的Delay时间
    --假设DelayMaxTime是0.53，就是随机0到53的值，假设随机到50/100 = delay0.5秒，
    local maxValue = self.skillAfterDelayMaxTime * 100 --这个值最多小数点后两位，单位是秒
    self.skillDelayTime = self._proxy:Random(0,maxValue) / 100
end
--endregion

--region AI
function XAFKCharBase:AfkAiMove(dt)
    if not self._proxy:CheckCanCastSkill(self._uuid) then --不可以放技能的状态不调用移动模块
        return
    end
    if self.moveSkillId then  --配置了移动技能向目标释放移动技能
        self._proxy:CastActionToTarget(self._uuid,self.moveSkillId,self.targetUUID)
    else--没有配置移动技能的时候
        --调用跟随组件
        self._followController:SetFollowTargetNpcNoNavMesh(self.targetUUID, self.followTargetMinDis, self.followTargetMaxDis, self.followTargetHeartBeat)
        self._followController:Update(dt)  --调用跟随组件走向目标
    end
end

function XAFKCharBase:FightAiSwitch(isOpenFightAi) --设置AI开关
    self.isFightAiOpen = isOpenFightAi   --是否关闭AI
    if not self.isFightAiOpen then
        self:OnOutBattle()
    end
end
--endregion

return XAFKCharBase
