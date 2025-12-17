---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")

---首席指挥官角色脚本
---@class XChar1052 : XRelinkCharBase
local XChar1052 = XDlcScriptManager.RegCharScript(1052, "XChar1052", Base)

function XChar1052:Init()
    Base.Init(self)
    ----- 测试用tick更新频率
    --self._testTickInterval = 1
    ----- 测试用tick计时器
    --self._testTickTimer = 0
    --- 测试用delay（开始运行后，固定延迟一定时间后执行一次的函数）
    --- 测试用delay延迟时间
    --self._testDelayTime = 1
    ----- 测试用delay计时器
    --self._testDelayTimer = 0
    ----- 测试用delay是否已经触发
    --self._hasTestDelayTriggered = false
    ---- 调试参, true为开启
    ---- 防御维持开关，true为开启
    --self._defendstate = false
    ---- 技能计时器
    self._skillTimer = 0
    ---- 角力象限镜头用
    self._WristleCameraAngle = 0
    ---- 极限技使用限制
    self._LimitSkillHasRelease = 0
end

function XChar1052:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter) --注册技能释放后事件
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction) --注册退出技能事件
    self.CustomPower1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1) --初始声明自定义能量属性
end

---@param dt number @ delta time
function XChar1052:Update(dt)
    Base.Update(self, dt)
    --self:TestUpdateLogic(dt)
    --self:TestLogic()
    self:TestInputLogic()
    self:CheckLimitEnergyAddBuff()
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
                self._proxy:CastActionEx(self._uuid,105238,0,2) --斧受击释放普通格挡
            end
        end

    end
end

---计算伤害前
---@param eventArgs BeforeDamageCalcEventArgs
function XChar1052:BeforeDamageCalc(eventArgs)
    if eventArgs.Id == 1052001 then
        self.CustomPower1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1) -- 确认消耗后的能量状况
        eventArgs.ElementPermyraid = eventArgs.ElementPermyraid * (1 +(self.CurCustomPower1-self.CustomPower1)* 0.0015)
        --XLog.Warning("修正后伤害倍率："..eventArgs.ElementPermyraid)
    end
    if eventArgs.Id == 1052025 then
        --XLog.Warning("多人联弹空中回击")
    end
    if eventArgs.Launcher ~= eventArgs.Target and eventArgs.Target == self._uuid then --受击流程，伤害来源不是自己
        if (self._proxy:CheckNpcCurrentAction(self._uuid,105206) or self._proxy:CheckNpcCurrentAction(self._uuid,105224)
                or self._proxy:CheckNpcCurrentAction(self._uuid,105225) )  --处于防御技能类中
                and not (self._proxy:CheckBuffByKind(self._uuid,105233) or self._proxy:CheckBuffByKind(self._uuid,105234)) then --非格挡情况下
            self._proxy:ApplyMagic(self._uuid,self._uuid,105259,1)  --防御减伤
        elseif self._proxy:CheckBuffByKind(self._uuid,105234) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,105260,1)  --触发格挡减伤
        elseif self._proxy:CheckBuffByKind(self._uuid,105233) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,105261,1)  --触发完美格挡减伤
        end

    end
end



function XChar1052:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    if buffId == 105217 then
        self._proxy:SetNpcAnimationLayer(self._uuid,0)
    elseif buffId == 105218 then
        self._proxy:SetNpcAnimationLayer(self._uuid,1)
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
end

function XChar1052:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
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
    --XLog.Warning("技能释放事件确认:"..skillId)
    if skillId == 105206 then
        --XLog.Warning("释放短按防御")
    elseif skillId == 105224 then
        --XLog.Warning("释放长按防御")
        --self._defendstate = true --长按防御状态维持阶段
        --self._testDelayTimer =0
        --self._hasTestDelayTriggered = false
        --elseif skillId == 105220 then
        --XLog.Warning("释放格挡成功")
    elseif skillId == 105226 then
        --XLog.Warning("释放格挡普攻派生成功")
    elseif skillId == 105227 then
        --XLog.Warning("释放格挡长按派生成功")
    end
    --核心技能能量值消耗
    if skillId == 105219 then
        self.CustomPower1 = self._proxy:GetNpcAttribValue(self._uuid,ENpcAttrib.CustomEnergyGroup1) --消耗前更新一次当前能量
        self.CurCustomPower1 = self.CustomPower1
        --XLog.Warning("记录当前能量值："..self.CurCustomPower1)
    end
    if skillId == 105244 then
        XLog.Warning("角力僵持发生")
        self:WrestleEnterCamera()--角力发生镜头
        local npclist = self._proxy:GetNpcList()
        for _, npcuuid in pairs(npclist) do
            XLog.Warning("设置")
            if npcuuid == 0  then
                return
            end
            if self._proxy:CheckBuffByKind(npcuuid,1000451) then
                self._proxy:SetNpcDither(npcuuid,true)
                XLog.Warning("设置目标不被透明")
            end
        end
        --角力发生时设置角色到目标位置
        --local npclist = self._proxy:GetNpcList()
        --self.deflectMonster = 0
        --for _, npcuuid in pairs(npclist) do
        --    if npcuuid == 0  then
        --        return
        --    end
        --    if self._proxy:CheckBuffByKind(npcuuid,1000451) then --确定角力中的怪物目标
        --        self.deflectMonster = npcuuid
        --    end
        --end
        --local isSuccess, outPos = self._proxy:TryGetBBVector3(1, self.deflectMonster, 800501) --从白龙身上获取一个计算位置
        --self._proxy:SetNpcPosition(self._uuid, outPos)
        --
    end
    if skillId == 105256 then
        --XLog.Warning("角力弹开后派生")
        self._proxy:ApplyMagic(self._uuid, self._uuid,1000453) --施加终结标记，单人测试用
    end
    if skillId == 105245 then
        --XLog.Warning("角力僵持持续")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1000463,1)
        self:WrestleLoopingCamera()--角力维持镜头
    end
    if skillId == 105246 then
        --XLog.Warning("角力僵持失败")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1000461,1)
    end
    if skillId == 105247 then
        --XLog.Warning("角力僵持成功")
        self:WrestleEndCamera()--角力退出镜头
    end
    if skillId == 105248 then
        --XLog.Warning("角力僵持输入")
    end
    if skillId == 105249 then
        --XLog.Warning("支援角色响应")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1000458)  --移除自身支援标记
        local npclist = self._proxy:GetNpcList()
        for _, npcuuid in pairs(npclist) do
            if npcuuid == 0  then
                return
            end
            if self._proxy:CheckBuffByKind(npcuuid,1000450) then --向角力中的角色发送角力成功标记
                self._proxy:ApplyMagic(self._uuid, npcuuid,1000454) --角力成功标记
            end
            if self._proxy:CheckBuffByKind(npcuuid,1000452) and npcuuid ~= self._uuid then --向后续响应的角色发送终结标记
                self._proxy:ApplyMagic(self._uuid, npcuuid,1000458) --移除支援标记
                self._proxy:ApplyMagic(self._uuid, npcuuid,1000453) --施加终结标记
            end
            if self._proxy:CheckBuffByKind(npcuuid,1000451) then --向角力中的怪物发送角力成功标记
                self._proxy:ApplyMagic(self._uuid, npcuuid,1000454) --角力成功标记
            end
        end
    end
    if skillId == 105252 then
        --XLog.Warning("终结角色响应")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1000459)  --移除自身终结标记
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
        --XLog.Warning("角力僵持发生，斧")
    end
    if skillId == 105259 then
        --XLog.Warning("角力僵持持续，斧")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1000463,1)
    end
    if skillId == 105246 then
        --XLog.Warning("角力僵持失败，斧")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1000461,1)
    end
    self._skillTimer = 0
end

function XChar1052:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if skillId == 105226 or skillId == 105227 or skillId == 105241 or skillId == 105242 then
        --XLog.Warning("确认退出格挡派生事件")
            self._proxy:ApplyMagic(self._uuid,self._uuid,105203,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,105204,1)
            self._proxy:ApplyMagic(self._uuid,self._uuid,105202,1)
        --elseif skillId == 105224 then
        --self._defendstate = false
        --self._hasTestDelayTriggered = false
        --XLog.Warning("防御状态确认："..tostring(self._defendstate))
        --XLog.Warning("延迟时间确认："..self._testDelayTimer)
        --XLog.Warning("延迟逻辑是否可以使用："..tostring(self._hasTestDelayTriggered))
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
        self._proxy:ApplyMagic(self._uuid,self._uuid,105290,1)  --开启碰撞
    end
    self._skillTimer = 0
end

--function XChar1052:TestUpdateLogic(dt)
--    if self._defendstate == true then
--        --测试用tick
--        --if self._testTickTimer >= self._testTickInterval then
--        --    -- 具体测试逻辑
--        --    self:TestTickLogic()
--        --    self._testTickTimer = 0
--        --end
--        --self._testTickTimer = self._testTickTimer + dt
--        --
--        -- 测试用delay
--        if not self._hasTestDelayTriggered then
--            if self._testDelayTimer >= self._testDelayTime then
--                self:TestDelayLogic()
--                self._hasTestDelayTriggered = true
--            end
--            self._testDelayTimer = self._testDelayTimer + dt
--            XLog.Warning("确认防御的循环维持"..self._testDelayTimer)
--        end
--    end
--end

function XChar1052:DefendSkillLoop()
    XLog.Warning("确认防御的循环维持")
    self._proxy:AbortAction(self._uuid, true)
    if self._proxy:CheckBuffByKind(self._uuid,105217) then
        XLog.Warning("持续防御")
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
        local testskill = 105268
        --XLog.Warning("放技能看效果:"..testskill)
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastAction(self._uuid,testskill)
        --self._proxy:CastActionEx(self._uuid,testskill,0,5)
        --测试技能释放
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball5) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052173,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052174,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052175,1)
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052176,1)
        --XLog.Warning("格挡派生镜头变化")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball6) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052310,1)
        XLog.Warning("加极限技能量")
    end

    if self._proxy:IsKeyDown(ENpcOperationKey.Ball7) then
        self._proxy:ApplyMagic(self._uuid,self._uuid,105290,1)
        --XLog.Warning("开碰撞")
    end
end
--endregion

--region 自动连招内容
function XChar1052:SkillAtuoCombo()
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

    if self._proxy:CheckNpcCurrentAction(self._uuid,105259) and self._skillTimer >= 1 then
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105259,0,5)
        --XLog.Warning("斧僵持循环中")
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

    if self._proxy:CheckNpcCurrentAction(self._uuid,105248) and self._skillTimer >= 0.35 then
        --XLog.Debug(self._skillTimer)
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105245,0,5)
        --XLog.Warning("完成攻击动作后回到僵持循环")
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

    if self._proxy:CheckNpcCurrentAction(self._uuid,105262) and self._skillTimer >= 0.35 then
        self._proxy:AbortAction(self._uuid,true)
        self._proxy:CastActionEx(self._uuid,105259,0,5)
        --XLog.Warning("斧完成攻击动作后回到僵持循环")
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

    if self._proxy:CheckNpcCurrentAction(self._uuid,105249) and self._skillTimer >= 0.4 then
        self._proxy:AbortAction(self._uuid,true)
        --XLog.Warning("支援移动后进入回击流程")
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105250,0,5)
        else
            self._proxy:CastActionEx(self._uuid,105251,0,5)
        end
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105252) and self._skillTimer >= 0.4 then
        self._proxy:AbortAction(self._uuid,true)
        --XLog.Warning("终结移动后攻击流程")
        if self._proxy:CheckBuffByKind(self._uuid,105217) then
            self._proxy:CastActionEx(self._uuid,105253,0,5)
        else
            self._proxy:CastActionEx(self._uuid,105254,0,5)
        end
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105247) and self._skillTimer >= 1 then
        --XLog.Warning("角力成功清除镜头")
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052171,1)
    end

    if self._proxy:CheckNpcCurrentAction(self._uuid,105246) and self._skillTimer >= 1 then
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
        self._proxy:ApplyMagic(self._uuid,self._uuid,1052136,1) --模拟扰动震屏

    end
end

function XChar1052:WrestleEndCamera() --剑盾角力成功
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052168,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052169,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052170,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,1052172,1)
end


--endregion

--region Update执行相关函数
function XChar1052:CheckLimitEnergyAddBuff()
    local LimitSkillEnergy = self._proxy:GetTeamWorkMaxEnergy()
    local LimitSkillEnergy1 = self._proxy:GetTeamWorkEnergy(self._uuid)
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
--endregion

--region 防御弹刀相关逻辑
function XChar1052:OnNpcCounterSuccess(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    if self._proxy:CheckNpcCurrentAction(self._uuid, 105206) or self._proxy:CheckNpcCurrentAction(self._uuid, 105224)
            or self._proxy:CheckNpcCurrentAction(self._uuid,105235) or self._proxy:CheckNpcCurrentAction(self._uuid,105236)then
        XLog.Warning("防御弹刀")
        self._proxy:AbortAction(self._uuid, true)
        if self._proxy:CheckBuffByKind(self._uuid, 105217) then
            self._proxy:CastActionEx(self._uuid,105240,0.26,3.83) --剑盾受击触发弹刀释放精确格挡
        elseif self._proxy:CheckBuffByKind(self._uuid, 105218) then
            self._proxy:CastActionEx(self._uuid,105243,0,2) --斧受击触发弹刀释放精确格挡

        end
    end

end
--endregion

return XChar1052