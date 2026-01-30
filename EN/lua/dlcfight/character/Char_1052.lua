---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")

---@field _proxy XDlcCSharpFuncs

---首席指挥官角色脚本
---@class XChar1052 : XRelinkCharBase
local XChar1052 = XDlcScriptManager.RegCharScript(1052, "XChar1052", Base)

function XChar1052:Init()
    Base.Init(self)
    ---- 技能计时器
    self._skillTimer = 0
    ---- 角力象限镜头用
    self._WristleCameraAngle = 0
    ---- 极限技使用限制
    self._LimitSkillHasRelease = 0
    ---- 斧角力流程输入监听开关
    self.AxeWrestleInput = false
    ---- 角力用白龙锁定部位id
    self.LockPartForWrestle = 8001006
    ----角力期间部位锁定记录id（占位用，无实际对应id）
    self.LockTargetKeeper = 8001001
    ----斧角力期间计时
    self._WrestleTimer = 0
    ----斧角力期间输入计数
    self._WrestleInputCount = 0
    ----剑解气势系数
    self.BladeReleaseCoe = 0.0015
    ----超解气势系数
    self.OverReleaseCoe = 0.0015
    ----超解气势系数增长系数
    self.OverReleaseCoeAdd = 0.5
end

function XChar1052:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleStart) --注册角力开始事件
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestlePursuit) --注册角力失败事件
    self._proxy:RegisterEvent(EWorldEvent.NpcWrestleReversal) --注册角力弹开事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter) --注册技能释放后事件
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction) --注册退出技能事件
    self.CustomPower1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1) --初始声明自定义能量属性
end

---@param dt number @ delta time
function XChar1052:Update(dt)
    Base.Update(self, dt)
    self:TestInputLogic()
    self:CheckInputDuringAxeWrestle()
    self:CheckLimitEnergyAddBuff()
    if self._proxy:CheckNpcCurrentAction(self._uuid,105259) then
        --更新角力时间
        self._WrestleTimer = self._WrestleTimer + dt
    end
    if self._proxy:CheckNpcFullActionState(self._uuid, 3, -1) then
        -- 更新技能时间
        self._skillTimer = self._skillTimer + dt
        self:SkillAtuoCombo()
        return
    end
end

---@param eventType number
---@param eventArgs userdata
function XChar1052:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar1052:Terminate()
    Base.Terminate(self)
end

function XChar1052:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    if launcherId ~= targetId and targetId == self._uuid then
        if self._proxy:CheckBuffByKind(self._uuid, 105233) and self._proxy:CheckBuffByKind(self._uuid, 8005501) then
            self._proxy:AbortAction(self._uuid, true)
            --旧弹刀逻辑，通过buff确认区分，目前已不通过
            XLog.Warning("完美弹刀格挡")
            self._proxy:CastActionEx(self._uuid,105240,0.26,3.83) --剑盾受击触发弹刀释放精确格挡
            if self._proxy:CheckBuffByKind(self._uuid, 105218) then
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionEx(self._uuid,105243,0,2) --斧受击触发弹刀释放精确格挡
            end
            --
        elseif self._proxy:CheckBuffByKind(self._uuid, 105233) then
            self._proxy:AbortAction(self._uuid, true)
            --XLog.Warning("精确格挡受击")
            self._proxy:CastActionEx(self._uuid,105220,0.26,3.83) --剑盾受击释放精确格挡
            if self._proxy:CheckBuffByKind(self._uuid, 105218) then
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionEx(self._uuid,105238,0,2) --斧受击释放精确格挡
            end
        elseif self._proxy:CheckBuffByKind(self._uuid, 105234) then
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionEx(self._uuid,105234,0.26,3.83) --剑盾受击释放普通格挡
            if self._proxy:CheckBuffByKind(self._uuid, 105218) then
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionEx(self._uuid,105239,0,2) --斧受击释放普通格挡
            end
        end

    end
end

---计算伤害前
---@param eventArgs BeforeDamageCalcEventArgs
function XChar1052:BeforeDamageCalc(eventArgs)
    if eventArgs.Id == 1052001 then
        self.CustomPower1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1) -- 确认消耗后的能量状况
        if self._proxy:CheckBuffByKind(self._uuid,1052383) then
            --XLog.Warning("强化修正前伤害倍率："..eventArgs.ElementPermyraid)
            local FinalDMGRate = eventArgs.ElementPermyraid * (1 +(self.CurCustomPower1-self.CustomPower1)* self.OverReleaseCoe*(1+self.OverReleaseCoeAdd))
            --XLog.Warning("强化修正后伤害倍率："..FinalDMGRate)
            self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, eventArgs.PhysicalPermyraid, FinalDMGRate, eventArgs.HackDamage, eventArgs.HackPermyraid, eventArgs.isCrit)
        else
            --XLog.Warning("修正前伤害倍率："..eventArgs.ElementPermyraid)
            local FinalDMGRate = eventArgs.ElementPermyraid * (1 +(self.CurCustomPower1-self.CustomPower1)* self.OverReleaseCoe)
            --XLog.Warning("修正后伤害倍率："..FinalDMGRate)
            self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, eventArgs.PhysicalPermyraid, FinalDMGRate, eventArgs.HackDamage, eventArgs.HackPermyraid, eventArgs.isCrit)
        end
    end

    if eventArgs.Id == 1052017 then
        --XLog.Warning("修正前伤害倍率："..eventArgs.ElementPermyraid)
        local FinalDMGRate = eventArgs.ElementPermyraid * (1 + (100 * self.BladeReleaseCoe))
        --XLog.Warning("修正后伤害倍率："..FinalDMGRate)
        self._proxy:SetBeforeDamageMagicContext(eventArgs.ContextId, eventArgs.PhysicalPermyraid, FinalDMGRate, eventArgs.HackDamage, eventArgs.HackPermyraid, eventArgs.isCrit)
    end

    if eventArgs.Launcher ~= eventArgs.Target and eventArgs.Target == self._uuid then --受击流程，伤害来源不是自己
        if (self._proxy:CheckNpcCurrentAction(self._uuid,105206) or self._proxy:CheckNpcCurrentAction(self._uuid,105224)
                or self._proxy:CheckNpcCurrentAction(self._uuid,105225) )  --处于防御技能类中
                and not (self._proxy:CheckBuffByKind(self._uuid,105233) or self._proxy:CheckBuffByKind(self._uuid,105234)) then --非格挡情况下
            self:CheckDefendResources() --检测防御受击相关时当前闪避资源
            self._proxy:ApplyMagic(self._uuid,self._uuid,105259,1)  --防御减伤
        elseif self._proxy:CheckBuffByKind(self._uuid,105234) then
            self:CheckDefendResources() --检测防御受击相关时当前闪避资源
            self._proxy:ApplyMagic(self._uuid,self._uuid,105260,1)  --触发格挡减伤
        elseif self._proxy:CheckBuffByKind(self._uuid,105233) then
            self:CheckDefendResources() --检测防御受击相关时当前闪避资源
            self._proxy:ApplyMagic(self._uuid,self._uuid,105261,1)  --触发完美格挡减伤
        end

    end
end

function XChar1052:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    Base.OnNpcAddBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    if npcUUID ~= self._uuid then
        return
    end

    --切换剑盾与斧相关动画状态与技能ui显示
    if buffId == 105217 then
        self._proxy:SetNpcAnimationLayer(self._uuid,0)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105205) --切换技能组3
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105203) --还原技能组1
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105204) --还原技能组2
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052360,1) --移除常驻fov增加
    elseif buffId == 105218 then
        self._proxy:SetNpcAnimationLayer(self._uuid,1)
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105210) --切换技能组3
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105211) --空置技能组1
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball2,105211) --空置技能组2
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052359,1) --常驻fov增加
    end

    if buffId == 105219 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105209)
    end
    if buffId == 1000450 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,105276,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105289,1) --关闭碰撞
        --XLog.Warning("多人联弹触发")
    end
    if buffId == 1000462 then
        self._proxy:AbortAction(self._uuid,true)
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105245,0,5)
            --XLog.Warning("多人联弹进入僵持循环,剑盾")
        elseif self._proxy:CheckBuffByKind(self._uuid,105218) then
            self._proxy:CastActionEx(self._uuid,105259,0,5)
            --XLog.Warning("多人联弹进入僵持循环,斧")
        end
    end
    if buffId == 1000455 then
        self._proxy:AbortAction(self._uuid,true)
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105246,0,5)
            --XLog.Warning("多人联弹僵持失败，剑盾")
        elseif self._proxy:CheckBuffByKind(self._uuid,105218) then
            self._proxy:CastActionEx(self._uuid,105260,0,5)
            --XLog.Warning("多人联弹僵持失败，斧")
            self._proxy:ApplyMagic(self._uuid,self._uuid,105286,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,105287,1)
        end
    end
    if buffId == 1000454 then
        self._proxy:AbortAction(self._uuid,true)
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105247,0,5)
            self._proxy:ApplyMagic(self._uuid,self._uuid,1000460,1)
            --XLog.Warning("多人联弹僵持成功，剑盾")
        elseif self._proxy:CheckBuffByKind(self._uuid,105218) then
            self._proxy:CastActionEx(self._uuid,105261,0,5)
            self._proxy:ApplyMagic(self._uuid,self._uuid,1000460,1)
            --XLog.Warning("多人联弹僵持成功，斧")
        end
        self._proxy:ApplyMagic(self._uuid,self._uuid,105286,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105287,1)
    end
    if buffId == 105255 then
        --XLog.Warning("防御维持标记添加")
    end
end

function XChar1052:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    Base.OnNpcRemoveBuffEvent(self,casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId == 105255 then
        --XLog.Warning("防御标记delay移除：")
        if self._proxy:CheckNpcCurrentAction(self._uuid,105224) and self._proxy:IsKeyHold(2,0.2) then
            self:DefendSkillLoop()
        elseif self._proxy:CheckNpcCurrentAction(self._uuid,105236) and self._proxy:IsKeyHold(2,0.2)  then
            self:DefendSkillLoop()
        elseif (self._proxy:CheckNpcCurrentAction(self._uuid,105238)and self._proxy:IsKeyHold(2,0.2)) or
                (self._proxy:CheckNpcCurrentAction(self._uuid,105239)and self._proxy:IsKeyHold(2,0.2)) then
            --XLog.Warning("斧受击防御恢复")
            self:BehitSkillRecoverInDefend()
        end
    end
    if buffId == 105219 then
        self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105203)
    end
    if buffId == 105276 then
        --XLog.Warning("角力buff前置")
        self._proxy:AbortAction(self._uuid,true)
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            --XLog.Warning("检测剑盾")
            self._proxy:CastActionEx(self._uuid,105244,0,5)
            --XLog.Warning("多人联弹进入,剑盾角力")
        elseif self._proxy:CheckBuffByKind(self._uuid,105218) then
            self._proxy:CastActionEx(self._uuid,105258,0,5)
            --XLog.Warning("多人联弹进入,斧角力")
        end
    end
end

function XChar1052:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    Base.OnNpcCastActionAfterEvent(self,skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end

    --XLog.Warning("技能释放事件确认:"..skillId)
    if skillId == 105206 then
        XLog.Warning("释放短按防御")
    elseif skillId == 105224 then
        --XLog.Warning("释放长按防御")
    elseif skillId == 105226 then
        --XLog.Warning("释放格挡普攻派生成功")
    elseif skillId == 105227 then
        --XLog.Warning("释放格挡长按派生成功")
    end
    if skillId == 105205 then
        --XLog.Warning("释放前闪避锁定目标")
        --self._proxy:SetHardLockToPart(self._uuid,273,8001001)
    end

    --核心技能能量值消耗
    if skillId == 105219 then
        self.CustomPower1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1) --消耗前更新一次当前能量
        self.CurCustomPower1 = self.CustomPower1
        --XLog.Warning("记录当前能量值："..self.CurCustomPower1)
    end
    if skillId == 105235 or skillId == 105236 or skillId == 105237 or skillId == 105265 then
        --XLog.Warning("记录连段")
        if self._proxy:CheckBuffByKind(self._uuid,1052367) then
            --XLog.Warning("记录连段3中")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052370,1)
        elseif self._proxy:CheckBuffByKind(self._uuid,1052366) then
            --XLog.Warning("记录连段2中")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052369,1)
        elseif self._proxy:CheckBuffByKind(self._uuid,1052365) then
            --XLog.Warning("记录连段1中")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052368,1)
        end
    end

    --角力相关技能进入
    if skillId == 105244 then
        XLog.Warning("角力僵持发生")
        --self:WrestleEnterCamera()--角力发生镜头
        self:WrestleEnterCameraNew()--角力发生新镜头
    end
    if skillId == 105256 then
        --XLog.Warning("角力弹开后派生")
    end
    if skillId == 105245 then
        --XLog.Warning("角力僵持持续")
        --self:WrestleLoopingCamera()--角力维持镜头
        --self._proxy:ApplyMagic(self._uuid,self._uuid,1052136,1) --模拟扰动震屏
    end
    if skillId == 105246 then
        --XLog.Warning("角力僵持失败")
        self:WrestleFailCameraNew()
    end
    if skillId == 105247 then
        --XLog.Warning("角力僵持成功")
        --self:WrestleEndCamera()--角力退出镜头
        self:WrestleSuccessCameraNew()
    end
    if skillId == 105248 then
        local RandomInt = self._proxy:Random(1,3)
        if RandomInt == 1 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052216,1)--加速1.2
        elseif RandomInt == 2 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052217,1)--加速1.3
        else
            XLog.Warning("原速")
        end
    end
    if skillId == 105269 then
        local RandomInt = self._proxy:Random(1,4)
        if RandomInt == 1 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052218,1)--减速0.8
        elseif RandomInt == 2 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052219,1)--减速0.85
        elseif RandomInt == 3 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052220,1)--减速0.7
        else
            XLog.Warning("原速2")
        end
    end
    if skillId == 105249 then
        --XLog.Warning("支援角色响应")
        --self:SupportBlinkCamera()
    end
    if skillId == 105252 then
        --XLog.Warning("终结角色响应")
        --self:SupportBlinkCamera()
    end
    if skillId == 105256 then
        --XLog.Warning("角力成功派生1")
    end
    if skillId == 105257 then
        --XLog.Warning("角力成功派生2")
    end
    if skillId == 105250 then
        --XLog.Warning("移动后地面回击1")
    end
    if skillId == 105251 then
        --XLog.Warning("移动后地面回击2")
    end
    if skillId == 105253 then
        --XLog.Warning("移动后空中回击1")
    end
    if skillId == 105254 then
        --XLog.Warning("移动后空中回击2")
    end
    if skillId == 105258 then
        self:WrestleEnterCameraNew()
        --XLog.Warning("角力僵持发生，斧")
    end
    if skillId == 105259 then
        --XLog.Warning("角力僵持持续，斧")
        --self._proxy:ApplyMagic(self._uuid,self._uuid,1052136,1) --模拟扰动震屏
    end
    if skillId == 105260 then
        --XLog.Warning("角力僵持失败，斧")
        self:WrestleFailCameraNew()
    end
    if skillId == 105261 then
        --XLog.Warning("角力僵持成功，斧")
        self:WrestleSuccessCameraNew()
    end
    if skillId == 105271 then
        XLog.Warning("测试瞬移流程镜头")
        self:SupportBlinkCamera()
    end

    --弹刀派生相关进入
    if skillId == 105241 or skillId == 105226 then
        XLog.Warning("弹刀派生镜头问题")
        local _,Angle  = self._proxy:GetCameraPosInfo(self._uuid,0,0)
        XLog.Warning("镜头朝向与控制器朝向角度"..Angle)
        if Angle < 70 or Angle > 220 then
            return
        else
            self:CounterAttackCamera()
        end
    end
    self._skillTimer = 0
end

function XChar1052:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId ~= self._uuid then
        return
    end

    if skillId == 105226 or skillId == 105227 or skillId == 105241 or skillId == 105242 then
        --XLog.Warning("确认退出格挡派生事件")
            self._proxy:ApplyMagic(self._uuid,self._uuid,105203,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,105204,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,105202,1)
    end
    if skillId == 105213 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,105200,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105201,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105205,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052185,1)
    end
    if skillId == 105214 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,105203,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105204,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,105202,1)
    end
    if skillId == 105246 or skillId == 105247 or skillId == 105260 or skillId == 105261 then
        --self._proxy:ApplyMagic(self._uuid,self._uuid,105290,1)  --开启碰撞
    end
    if skillId == 105215 then
        --XLog.Warning("斧普攻1退出")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052365,1)
    elseif skillId == 105216 then
        --XLog.Warning("斧普攻2退出")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052366,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052371,1)
    elseif skillId == 105217 then
        --XLog.Warning("斧普攻3退出")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052367,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052372,1)
    elseif skillId == 105218 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052373,1)
    end
    if skillId == 105261 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052171,1)
    end
    self._skillTimer = 0
    self._WrestleInputCount = 0
end

function XChar1052:DefendSkillLoop()
    --XLog.Warning("确认防御的循环维持")
    self._proxy:AbortAction(self._uuid, true)
    if self._proxy:CheckBuffByKind(self._uuid,105217) then
        --XLog.Warning("持续防御")
        self._proxy:CastActionEx(self._uuid,105224,0,3)
    elseif self._proxy:CheckBuffByKind(self._uuid,105218) then
        self._proxy:CastActionEx(self._uuid,105236,0,3)
    end

end

function XChar1052:BehitSkillRecoverInDefend()
    --XLog.Warning("执行斧防御的受击恢复逻辑")
    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastActionEx(self._uuid,105236,0,3)
end

--region 按键测试逻辑
function XChar1052:TestInputLogic()
    if self._proxy:IsKeyDown(ENpcOperationKey.Ball4) then
        --XLog.Warning("测试按键触发逻辑，test用")
        --测试buff效果添加
        --self._proxy:ApplyMagic(self._uuid,self._uuid,105293,1)
        --self._proxy:ApplyMagic(self._uuid,self._uuid,105294,1)
        --self._proxy:ApplyMagic(self._uuid,self._uuid,1052164,1)
        --XLog.Warning("角力进入镜头变化")
        --测试buff效果添加
        --测试技能释放
        local testskill = 105252
        --XLog.Warning("放技能看效果:"..testskill)
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastAction(self._uuid,testskill)
        --self._proxy:CastActionEx(self._uuid,testskill,0,5)
        --测试技能释放
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball5) then
        self._proxy:SetPlayerButtonOpEnabled(ENpcOperationKey.RelinkBreakQte,self._uuid,false)
        --self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball1,105211)
        XLog.Warning("测试qte按钮关")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball6) then
        self._proxy:SetPlayerButtonOpEnabled(ENpcOperationKey.RelinkBreakQte,self._uuid,true)
        --self._proxy:SetSkillGroup(self._uuid,ENpcOperationKey.Ball3,105210)
        XLog.Warning("测试qte按钮开")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball7) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052348,1)
        XLog.Warning("禁止自然恢复")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball8) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052386,1)
        XLog.Warning("增加闪避能量")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball9) then
        if self._proxy:CheckNpcCurrentAction(self._uuid,105245) then
            self._proxy:CastAction(self._uuid,105248)
            XLog.Warning("单独测试角色输入流程")
        end
    end
end
--endregion

--region 自动连招内容
function XChar1052:SkillAtuoCombo()
    --XLog.Warning("计算"..self._skillTimer)
    --[[
    if self._proxy:CheckNpcCurrentAction(self._uuid,105245) and self._skillTimer >= 1 then
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105245,0,5)
        --XLog.Warning("僵持循环中")
        local npclist = self._proxy:GetNpcList()
        for _, npcuuid in pairs(npclist) do
            if npcuuid == 0  then
                return
            end
            if self._proxy:CheckBuffByKind(npcuuid,1000451) then
                self._proxy:SetFightTarget(self._uuid,npcuuid)
                --XLog.Warning("僵持循环中维持战斗状态稳定")
            end
        end
    end
--]]
    --[[
    if self._proxy:CheckNpcCurrentAction(self._uuid,105259) and self._skillTimer >= 1 then
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105259,0,5)
        --XLog.Warning("斧僵持循环中")
    end
--]]
    if self._proxy:CheckNpcCurrentAction(self._uuid,105248) and self._skillTimer >= 0.8 then --剑盾角力攻击1完成时回到僵持循环的内容
        --XLog.Debug(self._skillTimer)
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105245,0,5)
        --XLog.Warning("完成攻击动作后回到僵持循环")
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105269) and self._skillTimer >= 0.6 then --剑盾角力攻击2完成时回到僵持循环的内容
        --XLog.Debug(self._skillTimer)
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105245,0,5)
        --XLog.Warning("完成攻击动作后回到僵持循环")
    end
----[[
    if self._proxy:CheckNpcCurrentAction(self._uuid,105262) and self._skillTimer >= 0.8 then --斧角力攻击动作完成时回到僵持循环的内容
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105259,0,5)
        --XLog.Warning("斧完成攻击动作后回到僵持循环")
    end
----]]
    if self._proxy:CheckNpcCurrentAction(self._uuid,105249) and self._skillTimer >= 0.95 then
        self._proxy:AbortAction(self._uuid,true)
        --XLog.Warning("支援移动后进入回击流程")
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105250,0,5)
        else
            self._proxy:CastActionEx(self._uuid,105251,0,5)
        end
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105252) and self._skillTimer >= 1 then
        self._proxy:AbortAction(self._uuid,true)
        --XLog.Warning("终结移动后攻击流程")
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105253,0,5)
        else
            self._proxy:CastActionEx(self._uuid,105254,0,5)
        end
    end
--[[
    if self._proxy:CheckNpcCurrentAction(self._uuid,105271) and self._skillTimer >= 0.9 then
        self._proxy:AbortAction(self._uuid,true)
        XLog.Warning("弹刀移动后走攻击弹开动作，测试表现效果")
        self._proxy:CastActionEx(self._uuid,105255,0,5)
    end
--]]
    if self._proxy:CheckNpcCurrentAction(self._uuid,105247) and self._skillTimer >= 1.05 then
        --XLog.Warning("角力成功清除镜头")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052171,1)
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105246) and self._skillTimer >= 0.7 then
        --XLog.Warning("角力失败清除镜头")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052171,1)
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105260) and self._skillTimer >= 0.7 then
        --XLog.Warning("角力失败清除镜头")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052171,1)
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105261) and self._skillTimer >= 0.95 then
        --XLog.Warning("角力失败清除镜头")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052171,1)
    end
end


--endregion

--region 角力相关表现镜头
function XChar1052:WrestleEnterCamera() --剑盾角力进入
    local _,npc = self._proxy:GetLockTarget()
    local _,angle = self._proxy:GetCameraPosInfo(self._uuid,npc)
    if angle >= 180 then
        self._WristleCameraAngle = 0
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052162,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052163,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052164,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052189,1)
    else
        self._WristleCameraAngle = 1
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052162,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052163,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052164,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052189,1)
    end
end

function XChar1052:WrestleLoopingCamera() --剑盾角力持续中
    if not self._proxy:CheckBuffByKind(self._uuid,1052165) then --排除重复进入导致的镜头效果问题
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052165,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052166,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052167,1)
        --self._proxy:ApplyMagic(self._uuid,self._uuid,1052136,1) --模拟扰动震屏

    end
end

function XChar1052:WrestleEndCamera() --剑盾角力成功
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052168,1)
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052169,1)
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052170,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052172,1)
end

function XChar1052:WrestleEnterCameraNew() --角力进入新
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052313,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052314,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052315,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052316,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052317,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052318,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052319,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052320,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052321,1)

end

function XChar1052:WrestleFailCameraNew() --角力失败退出新
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052325,1)
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052326,1)
end

function XChar1052:WrestleSuccessCameraNew() --角力成功退出新
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1052338,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052168,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052169,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052170,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052172,1)

end

--endregion

--region 镜头处理相关
function XChar1052:CounterAttackCamera() --格挡反击镜头
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052173,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052174,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052175,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052176,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052177,1)
end

function XChar1052:SupportBlinkCamera() --支援位移镜头
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052341,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052342,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052343,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052344,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052345,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052346,1)
end

--endregion

--region Update执行相关函数
function XChar1052:CheckLimitEnergyAddBuff()
    --local LimitSkillEnergy = self._proxy:GetTeamWorkMaxEnergy()
    --local LimitSkillEnergy1 = self._proxy:GetTeamWorkEnergy(self._uuid)
    --XLog.Warning("极限值能量"..LimitSkillEnergy)
    --XLog.Warning("极限值能量"..LimitSkillEnergy1)
    if not self._proxy:CheckBuffByKind(self._uuid,1052301) then
        local LimitSkillEnergy = self._proxy:GetTeamWorkEnergy(self._uuid)
        if LimitSkillEnergy >= 100 then
            --XLog.Warning("加极限技能buff效果")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052300,1)
        end
    end
end

function XChar1052:CheckInputDuringAxeWrestle()
    if  self.AxeWrestleInput == true and self._proxy:IsKeyDown(ENpcOperationKey.RelinkQte) then
        if self._WrestleTimer >= 0.4 then
            XLog.Warning("斧前顶镜头震动")
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052129,1)
            self._WrestleInputCount = self._WrestleInputCount +1
            self._WrestleTimer = 0
        end
        if self._WrestleInputCount < 3 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052361,1) --火花
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052374,1) --材质
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052378,1) --爆发
            elseif self._WrestleInputCount < 6 then
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052362,1) --火花
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052375,1) --材质
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052378,1) --爆发
            else
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052363,1) --火花
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052376,1) --材质
            self._proxy:ApplyMagic(self._uuid,self._uuid,1052379,1) --爆发
        end
    end
end
--endregion

--region 防御弹刀相关逻辑
function XChar1052:OnNpcCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    Base.OnNpcCounterSuccess(self,triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    if self._proxy:CheckNpcCurrentAction(self._uuid, 105206) or self._proxy:CheckNpcCurrentAction(self._uuid, 105224)
            or self._proxy:CheckNpcCurrentAction(self._uuid,105235) or self._proxy:CheckNpcCurrentAction(self._uuid,105236)then
        self._proxy:AbortAction(self._uuid, true)
        if self._proxy:CheckBuffByKind(self._uuid, 105217) then
            self._proxy:CastActionEx(self._uuid,105240,0.26,3.83) --剑盾受击触发弹刀释放精确格挡
        elseif self._proxy:CheckBuffByKind(self._uuid, 105218) then
            self._proxy:CastActionEx(self._uuid,105243,0,2) --斧受击触发弹刀释放精确格挡

        end
    end
end

function XChar1052:CheckDefendResources() --防御资源不足时移除霸体效果
    local CurDodageRes = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.DodgeEnergy)
    XLog.Warning("要被干碎了"..CurDodageRes)
    if CurDodageRes <= 0 then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052387,1)

    end
end
--endregion

--region 角力监听节点(处理部分角力相关的保底内容)
function XChar1052:OnNpcWrestleStart(launcherNpcUUID, targetNpcUUID, succeed)
    Base.OnNpcWrestleStart(self,launcherNpcUUID, targetNpcUUID, succeed)
    --角力进入强制设置锁定目标
    self.LockTargetKeeper = self._proxy:GetLockTarget()
    XLog.Warning("程序角力进入 "..self.LockTargetKeeper .. " launcherUUID" .. launcherNpcUUID .. " targetNpcUUID" .. targetNpcUUID)
    self._proxy:SetHardLockToPart(targetNpcUUID,launcherNpcUUID,self.LockPartForWrestle)
    --角力进入设置碰撞关闭
    self._proxy:ApplyMagic(self._uuid,self._uuid,105289,1) --关闭碰撞
    --设置白龙不被裁切
    self._proxy:SetNpcDither(launcherNpcUUID,true)
    --移除斧形态offset内容
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052371,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052372,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052373,1)
    --角力进入隐藏小飞机
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052380,1)
    --斧角力进入开启角力输入监听
    if self._proxy:CheckBuffByKind(self._uuid,105218) then
        self.AxeWrestleInput = true
    end
end

function XChar1052:OnNpcWrestlePursuit(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestlePursuit(self,launcherNpcUUID, targetNpcUUID)
    XLog.Warning("角力失败")
    self.AxeWrestleInput = false
    --角力退出还原锁定配置
    self._proxy:SetHardLock(targetNpcUUID,self.LockTargetKeeper)
    --设置白龙不被裁切
    self._proxy:SetNpcDither(launcherNpcUUID,false)
    --角力退出开启碰撞
    self._proxy:ApplyMagic(self._uuid,self._uuid,105290,1) --开启碰撞
    --角力退出显示小飞机
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052381,1)
    --角力失败隐藏材质效果
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052377,1) --角力失败移除斧材质
    self.LockTargetKeeper = 8001001
end

function XChar1052:OnNpcWrestleReversal(launcherNpcUUID, targetNpcUUID)
    Base.OnNpcWrestleReversal(self,launcherNpcUUID, targetNpcUUID)
    XLog.Warning("角力成功")
    self.AxeWrestleInput = false
    --角力退出还原锁定配置
    self._proxy:SetHardLock(targetNpcUUID,self.LockTargetKeeper)
    --设置白龙不被裁切
    self._proxy:SetNpcDither(launcherNpcUUID,false)
    --角力退出开启碰撞
    self._proxy:ApplyMagic(self._uuid,self._uuid,105290,1) --开启碰撞
    --角力退出显示小飞机
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052381,1)
    self.LockTargetKeeper = 8001001
end
--endregion

--region 角力逻辑相关

--endregion
return XChar1052