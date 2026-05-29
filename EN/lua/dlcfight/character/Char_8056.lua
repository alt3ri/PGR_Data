---@type XRelinkCharBase
local Base = require("Character/FightCharBase/XRelinkCharBase")

---首席指挥官角色脚本
---@class XChar8056 : XRelinkCharBase
local XChar8056 = XDlcScriptManager.RegCharScript(8056, "XChar8056", Base)

function XChar8056:Init()
    Base.Init(self)
    self.Move = true
    self.AISwitch = true
    self.SiDouSwitch = true
    self.juli1 = false
    self.juli2 = false
    self.juli3 = false
    self.PlayUUID =  self._proxy:GetPlayerNpcList()
    XLog.Warning(self.PlayUUID)
    self.DanShengindex = 1
    self.NPC = 0
    self.ODindex = 0
    self.JiGuangindex = 0
    self._proxy:AddTimerTask(4.5, function()--延迟4秒后
        self._proxy:ApplyMagic(self._uuid, self._uuid, 80560025, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 80560028, 1)
    end)
    self._DanSheng= {
        [1] = 805608,
        [2] = 805609,
        [3] = 805610,
    }
    self.ODSkill1index3 = 1
    self.ODSkill1index2 = 1
    self.ODSkill1index1 = 1
    self._JiGuangSkillindex1 = 1
    self.Skill1index = 1
    self.SiDouindex = 1
    self._NormalSkill1= {
        [1] = 805614, -- 805612
        [2] = 805612, --805614
        [3] = 805644, -- 805613
        [4] = 805613, -- 805613
        [5] = 805615,  --805615
        [6] = 805616, --16
        [7] = 805617,
        [8] = 805607,
    }

    self._ODSkill3 = {
        [1] = 805640,
        [2] = 805622,
        [3] = 805623,
        [4] = 805624,
        [5] = 805625,
        [6] = 805626,
        [7] = 805627,
        [8] = 805640,
        [9] = 805644,
        [10] = 805613,
        [11] = 805616,
        [12] = 805617,
        [13] = 805640,
        [14] = 805614,
        [15] = 805612,
        [16] = 805607,
        [17] = 805615,
    }


    self._ODSkill2 = {
        [1] = 805616,
        [2] = 805617,
        [3] = 805644,
        [4] = 805613,
        [5] = 805614,
        [6] = 805615,
        [7] = 805640,
        [8] = 805612,
        [9] = 805607,
        [10] = 805622,
        [11] = 805623,
        [12] = 805624,
        [13] = 805625,
        [14] = 805626,
        [15] = 805627,
    }

    self._ODSkill1 = {
        [1] = 805640,
        [2] = 805613,
        [3] = 805607,
        [4] = 805615,
        [5] = 805612,
        [6] = 805613,
        [7] = nil,
    }

    self._JiGuangSkill1= {
        [1] = 805630,
        [2] = 805631,
        [3] = 805641,
        [4] = 805642,
        [5] = 805643,
    }

    self._SiDouSkill1= {
        [1] = 805630,
        [2] = 805631,
        [3] = 805637,
        [4] = 805638,
        [5] = 805639,
    }

end

function XChar8056:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- 添加buff
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore) --注册技能释放前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter) --注册技能释放后前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction) -- 技能释放完成事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid) --注册技能事件
    -- 初始化韧性OD系统
    self._proxy:SetNpcBreakGaugeActive(self._uuid, true)
    self._proxy:SetNpcOverDriveActive(self._uuid, true)
    --OD与Break事件
    self._proxy:RegisterEvent(EWorldEvent.NpcOverDriveFull) -- OD已满事件
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakBefore) --Break事件
    self._proxy:RegisterEvent(EWorldEvent.NpcODExitBreakAfter) --退出Break事件
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter) -- 破韧前事件

    -- 指定目标事件绑定
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcBeforeTriggerCounter, self._uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcAfterTriggerCounter, self._uuid)

    -- 注册自定义lua事件
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkSetAIActivate)

end

function XChar8056:Update(dt)
    Base.Update(self, dt)

    if not self.AISwitch == true then
        return
    end
    --更新角力时间
   --[[ if  self.AISwitch == true then
        self.Attack = false
        self._proxy:AddTimerTask(9, function()--延迟0.6秒后，释放影牌技能
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,805608,33)
            self.Attack = true
        end)
    end]]

    if self.SiDouSwitch == true and self._proxy:CheckBuffByKind(self._uuid, 80560016) then -- 死斗启动后逻辑
        self.PlayUUID =  self._proxy:GetPlayerNpcList()
        if #self.PlayUUID == 1 then
            self.juli1 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[1],4)
        end

        if #self.PlayUUID == 2 then
            self.juli1 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[1],4)
            self.juli2 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[2],4)
        end

        if #self.PlayUUID == 3 then
            self.juli1 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[1],4)
            self.juli2 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[2],4)
            self.juli3 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[3],4)
        end

        if self.juli1 == true then
            self._proxy:AddTimerTask(15, function()--延迟4秒后
                self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1)
            end)
            self.juli2 = false
            self.juli3 = false
            self.SiDouSwitch = false
            self.Move = true
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,805639,self.PlayUUID[1])
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[1], 8072003, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[2], 8071007, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[3], 8071007, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 80560018, 1)
            self._proxy:ApplyMagic(self._uuid, self.NPC, 8072004, 1)
            self._proxy:ApplyMagic(self._uuid, self.NPC, 8057001, 1)
            self:ShuiQiu()
            --[[self._proxy:LaunchMissile(self._uuid, self.NPC, 80563801, 80563805,1)]]
            self._proxy:AddTimerTask(0.5, function()
            end)

            self._proxy:AddTimerTask(2, function()--延迟4秒后
                self._proxy:LaunchMissile(self._uuid, self.NPC, 80531204, 80720001,1)
                self._proxy:ApplyMagic(self._uuid,self._uuid, 80560012, 1)
                self._proxy:DestroyNpc(self.NPC)
            end)
           local ZhaDanWeiZhi,P1 = self._proxy:TryGetMissilePositionByUUID(self.ShuiQiu1)
            local ZhaDanWeiZhi2 = self._proxy:GetNpcPosition(self.NPC)
            self._proxy:LaunchMissileFromPosToPos(self._uuid,80563803,80563805,P1,ZhaDanWeiZhi2,1)
            self._proxy:DestroyMissileByUUID(self.ShuiQiu1)
        end

        if self.juli2 == true then
            self._proxy:AddTimerTask(15, function()--延迟4秒后
                self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1)
            end)
            self.juli1 = false
            self.juli3 = false
            self.SiDouSwitch = false
            self.Move = true
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,805639,self.PlayUUID[2])
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[2], 8072003, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[1], 8071007, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[3], 8071007, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 80560018, 1)
            self._proxy:ApplyMagic(self._uuid, self.NPC, 8072004, 1)
            self._proxy:ApplyMagic(self._uuid, self.NPC, 8057001, 1)
            self:ShuiQiu()
            --[[self._proxy:LaunchMissile(self._uuid, self.NPC, 80563801, 80563805,1)]]
            self._proxy:AddTimerTask(0.5, function()
            end)

            self._proxy:AddTimerTask(2, function()--延迟4秒后
                self._proxy:LaunchMissile(self._uuid, self.NPC, 80531204, 80720001,1)
                self._proxy:ApplyMagic(self._uuid,self._uuid, 80560012, 1)
                self._proxy:DestroyNpc(self.NPC)
            end)
            local ZhaDanWeiZhi,P1 = self._proxy:TryGetMissilePositionByUUID(self.ShuiQiu1)
            local ZhaDanWeiZhi2 = self._proxy:GetNpcPosition(self.NPC)
            self._proxy:LaunchMissileFromPosToPos(self._uuid,80563803,80563805,P1,ZhaDanWeiZhi2,1)
            self._proxy:DestroyMissileByUUID(self.ShuiQiu1)
        end

        if self.juli3 == true then
            self._proxy:AddTimerTask(15, function()--延迟4秒后
                self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1)
            end)
            self.juli1 = false
            self.juli2 = false
            self.SiDouSwitch = false
            self.Move = true
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,805639,self.PlayUUID[3])
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[3], 8072003, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[1], 8071007, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[2], 8071007, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 80560018, 1)
            self._proxy:ApplyMagic(self._uuid, self.NPC, 8072004, 1)
            self._proxy:ApplyMagic(self._uuid, self.NPC, 8057001, 1)
            self:ShuiQiu()
           --[[ self._proxy:LaunchMissile(self._uuid, self.NPC, 80563801, 80563805,1)]]
            self._proxy:AddTimerTask(0.5, function()
            end)

            self._proxy:AddTimerTask(2, function()--延迟4秒后
                self._proxy:LaunchMissile(self._uuid, self.NPC, 80531204, 80720001,1)
                self._proxy:ApplyMagic(self._uuid,self._uuid, 80560012, 1)
                self._proxy:DestroyNpc(self.NPC)
            end)
            local ZhaDanWeiZhi,P1 = self._proxy:TryGetMissilePositionByUUID(self.ShuiQiu1)
            local ZhaDanWeiZhi2 = self._proxy:GetNpcPosition(self.NPC)
            self._proxy:LaunchMissileFromPosToPos(self._uuid,80563803,80563805,P1,ZhaDanWeiZhi2,1)
            self._proxy:DestroyMissileByUUID(self.ShuiQiu1)
        end

    end --死斗启动后逻辑

    if self.Move == true and  self._proxy:CheckBuffByKind(self._uuid, 80560023) then -- 超级激光释放
        self.Move = false
        self:JiGangSkill1()
    end

    if self.Move == true and  self._proxy:CheckBuffByKind(self._uuid, 80560007) then -- OD激活
        self.Move = false
        self:ODJiHuo()
    end

    if self.Move == true and not self._proxy:CheckBuffByKind(self._uuid, 80560005) and  self._proxy:CheckBuffByKind(self._uuid, 80560025)  then
        self.Move = false
        self:DanSheng()
    end

    if self.Move == true and  self._proxy:CheckBuffByKind(self._uuid, 80560021) then -- 超级激光释放
        self.Move = false
        self:JiGangSkill1()
    end

    if self.Move == true and self._proxy:CheckBuffByKind(self._uuid, 80560027)  then -- 技能开关开启后执行以下
        self.Move = false
        self:ODSkill3()
    end

    if self.Move == true and self._proxy:CheckBuffByKind(self._uuid, 80560008) and  self._proxy:CheckBuffByKind(self._uuid, 80560020) then -- 技能开关开启后执行以下
        self.Move = false
        self:ODSkill2()
    end


    if self.Move == true and self._proxy:CheckBuffByKind(self._uuid, 80560019) then
        self.Move = false
        self:SiDouSkill()
    end

    if self.Move == true and self._proxy:CheckBuffByKind(self._uuid, 80560008) and not self._proxy:CheckBuffByKind(self._uuid, 80560019) then -- 技能开关开启后执行以下
        self.Move = false
        self:ODSkill()
    end

    if self.Move == true and self._proxy:CheckBuffByKind(self._uuid, 80560005) then -- 技能开关开启后执行以下
        self.Move = false
        self:NormalSkill()
    end

end


function XChar8056:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)

    if LauncherId ~= self._uuid then
        return
    end

 --[[   if SkillId == 805637 then
        self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80563801, 80563801,1)
        self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80563802, 80563801,1)
        self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80563803, 80563801,1)
        self._proxy:AddTimerTask(2, function()
            local ShuiQiu1,v1 =  self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80563801, 80563802,1)
            local ShuiQiu2,v2 =  self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80563801, 80563802,1)
            local ShuiQiu3,v3 =  self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80563801, 80563802,1)
            self.ShuiQiu1 = v1
            self.ShuiQiu2 = v2
            self.ShuiQiu3 = v3
        end)
    end]]

end


function XChar8056:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 80560005 then
        self.Move = true
        self.AISwitch = true
    end


end


function XChar8056:DanSheng() --千子诞生
    XLog.Warning("千子诞生")
    local Target = self.PlayUUID[1]
    local DanShengSkill1key = self._DanSheng[self.DanShengindex] -- 获取当前技能释放序列
    self._proxy:CastActionToTarget(self._uuid,DanShengSkill1key,Target) -- 向最大仇恨目标按顺序释放常规技能组1
    self.DanShengindex = self.DanShengindex + 1 -- 每次释放技能加一次序号
    if self.DanShengindex > 6 then --序号大于3则返回1
        self.DanShengindex = 1
        self.AISwitch = false
    end
end

function XChar8056:ODSkill() --OD技能组1
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    local ODSkill1key = self._ODSkill1[self.ODSkill1index1] -- 获取当前技能释放序列
    local Target = self.PlayUUID[1]
    if ODSkill1key ~= nil then
        self._proxy:CastActionToTarget(self._uuid,ODSkill1key,Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end
    self.ODSkill1index1 = self.ODSkill1index1 + 1 -- 每次释放技能加一次序号
    if self.ODSkill1index1 == 8 then
        XLog.Debug("死斗开启")
        self._proxy:ApplyMagic(self._uuid,self._uuid,80560019, 1)
        self._proxy:AddTimerTask(1.5, function()
            self.Move = true
        end)
    end
end

function XChar8056:ODSkill3() --OD技能组3,软狂暴
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    local ODSkill1key = self._ODSkill3[self.ODSkill1index3] -- 获取当前技能释放序列
    local Target = self.PlayUUID[1]
    if ODSkill1key ~= nil then --序号大于3则返回1
        self._proxy:CastActionToTarget(self._uuid,ODSkill1key,Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end
    self.ODSkill1index3 = self.ODSkill1index3 + 1 -- 每次释放技能加一次序号
    if self.ODSkill1index3 == 18 then
        self.ODSkill1index3 = 1
    end
end


function XChar8056:ODSkill2() --OD技能组2
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    local ODSkill1key = self._ODSkill2[self.ODSkill1index2] -- 获取当前技能释放序列
    local Target = self.PlayUUID[1]
    if ODSkill1key ~= nil then --序号大于3则返回1
        self._proxy:CastActionToTarget(self._uuid,ODSkill1key,Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end
    self.ODSkill1index2 = self.ODSkill1index2 + 1 -- 每次释放技能加一次序号
    if self.ODSkill1index2 == 16 then
        self.ODSkill1index2 = 1
    end
end

function XChar8056:JiGangSkill1() --超强激光技能组
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    local JiGuangSkill1key = self._JiGuangSkill1[self._JiGuangSkillindex1] -- 获取当前技能释放序列
    local Target = self.PlayUUID[1]
    if JiGuangSkill1key ~= nil then --序号大于3则返回1
        self._proxy:CastActionToTarget(self._uuid,JiGuangSkill1key,Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end
    self._JiGuangSkillindex1 = self._JiGuangSkillindex1 + 1 -- 每次释放技能加一次序号
    if self._JiGuangSkillindex1 == 2 then
        local QianZiPos = {x =24.46, y = 9.77, z = 43}
        local QianZiRota = {x = 0, y = 90, z = 0}
        self._proxy:AddTimerTask(1, function()
            self._proxy:SetNpcPosition(self._uuid,QianZiPos,true)
            self._proxy:SetNpcRotation(self._uuid,QianZiRota)
        end)
    end
    if self._JiGuangSkillindex1 == 6 then
        if self._proxy:CheckBuffByKind(self._uuid, 80560021) then
            self._proxy:ApplyMagic(self._uuid,self._uuid,80560020, 1)
            self._JiGuangSkillindex1 = 1
        end

        if self._proxy:CheckBuffByKind(self._uuid, 80560023) then
            self._JiGuangSkillindex1 = 3
        end
    end
end


function XChar8056:NormalSkill() --常规技能组1
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    local NormalSkill1key = self._NormalSkill1[self.Skill1index] -- 获取当前技能释放序列
    local Target = self.PlayUUID[1]
    self._proxy:CastActionToTarget(self._uuid,NormalSkill1key,Target) -- 向最大仇恨目标按顺序释放常规技能组1
    self.Skill1index = self.Skill1index + 1 -- 每次释放技能加一次序号
    if self.Skill1index >= 9 then --序号大于3则返回1
        self.Skill1index = 1
    end
end

function XChar8056:SiDouSkill() --死斗技能
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    local SiDouSkill1key = self._SiDouSkill1[self.SiDouindex] -- 获取当前技能释放序列
    local Target = self.PlayUUID[1]
    self._proxy:CastActionToTarget(self._uuid,SiDouSkill1key,Target) -- 向最大仇恨目标按顺序释放常规技能组1
    self.SiDouindex = self.SiDouindex + 1 -- 每次释放技能加一次序号
    if self.SiDouindex == 2 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000465, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000467, 1)
        local QianZiPos = {x = 38.27, y = 9.86, z = 42.97}
        local QianZiRota = {x = 0, y = 90, z = 0}
        self._proxy:AddTimerTask(1, function()--延迟4秒后
            self._proxy:SetNpcPosition(self._uuid,QianZiPos,true)
            self._proxy:SetNpcRotation(self._uuid,QianZiRota)
        end)
    elseif self.SiDouindex == 4  then
        local ChuShouCamp1= ENpcCampType.Camp1
        local ShuiQiuPos = {x = 40.87, y = 9.86, z = 43.03}
        local ChuShouRota1 = {x = 0, y = 180, z = 0}
        self.NPC = self._proxy:GenerateNpc(8072, ChuShouCamp1, ShuiQiuPos, ChuShouRota1)
        self._proxy:AddTimerTask(1, function()--延迟4秒后
            self:SiDou()
        end)
    elseif self.SiDouindex == 5  then
        self._proxy:AddTimerTask(2, function()--延迟4秒后
            self._proxy:ApplyMagic(self._uuid,self.NPC, 8072001, 1)
        end)
    elseif self.SiDouindex == 6  then
        self.SiDouSwitch = false
        self._proxy:AddTimerTask(15, function()--延迟4秒后
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1)
        end)
        if self._proxy:CheckBuffByKind(self._uuid, 80560018) then
            self._proxy:ApplyMagic(self._uuid,self._uuid, 80560020, 1)
        else
            self._proxy:ApplyMagic(self._uuid,self.NPC, 8072004, 1)
            self._proxy:ApplyMagic(self._uuid,self._uuid, 80560021, 1)
            --[[self._proxy:LaunchMissile(self._uuid, self.NPC, 80563801, 80563807,1)]]
         --[[   self._proxy:LaunchMissile(self._uuid, self.PlayUUID[1], 80563802, 80563803,1)
            self._proxy:LaunchMissile(self._uuid, self.PlayUUID[1], 80563803, 80563803,1)]]
            self._proxy:DestroyMissileByUUID(self.ShuiQiu1)
       --[[     self._proxy:DestroyMissileByUUID(self.ShuiQiu2)
            self._proxy:DestroyMissileByUUID(self.ShuiQiu3)]]
            self._proxy:AddTimerTask(2, function()--延迟4秒后
                self._proxy:DestroyNpc(self.NPC)
            end)
        end
    end

end

function XChar8056:ODJiHuo() --OD激活
    local Target = self.PlayUUID[1]
    self._proxy:CastActionToTarget(self._uuid,805635,Target) -- OD激活技能
end


function XChar8056:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort) -- 技能释放完成时
    if launcherId ~= self._uuid then
        return
    end
    self.Move = true -- 开启技能开关
 --[[   if skillId ~= 805644 then
        self.Move = true -- 开启技能开关
    end]]


end

function XChar8056:SiDou() -- 死斗开始
    XLog.Warning("死斗开始")
    local Target = self.PlayUUID[1]
    local ChuShouCamp= ENpcCampType.Camp2
    local ChuShouPos1 = {x = 41.08, y = 9.78, z = 27.35}
    local ChuShouPos3 = {x = 41.14, y = 9.78, z = 57.1}
    local ChuShouRota1 = {x = 0, y = 180, z = 0}
    self._proxy:LaunchMissile(self._uuid,self.NPC, 80563801, 80563801,1)
    self._proxy:AddTimerTask(2, function()
        local ShuiQiu1,v1 =  self._proxy:LaunchMissile(self._uuid,self.NPC, 80563801, 80563807,1)
        self.ShuiQiu1 = v1
    end)

    self._proxy:AddTimerTask(0.1, function()--延迟4秒后
        self.ChuShou1 = self._proxy:GenerateNpc(8071, ChuShouCamp, ChuShouPos1, ChuShouRota1)
    end)
    self._proxy:AddTimerTask(0.3, function()--延迟4秒后
        self.ChuShou1 = self._proxy:GenerateNpc(8071, ChuShouCamp, ChuShouPos3, ChuShouRota1)
    end)

    self._proxy:ApplyMagic(self._uuid,self._uuid, 80560016, 1)
end

function XChar8056:ShuiQiu() -- 场外水球
    local Target = self.PlayUUID[1]
    local ChuShouCamp2= ENpcCampType.Camp2
    local ShuiQiuPos1 = {x = 41.41, y = 9.78, z = 65.62}
    local ShuiQiuPos2 = {x = 41.52, y = 9.77, z = 20.50}
    local ShuiQiuPos3 = {x = 25.05, y = 9.77, z = 26.24}
    local ShuiQiuPos4 = {x = 57.47, y = 9.78, z = 26.02}

    local QianZiPos = {x = 38.27, y = 9.86, z = 42.97}
    local ShuiQiuPos = {x = 40.87, y = 9.86, z = 43.03}
    local ChuShouRota1 = {x = 0, y = 180, z = 0}

    self._proxy:AddTimerTask(0.1, function()--延迟4秒后
        self.ChuShou1 = self._proxy:GenerateNpc(8059, ChuShouCamp2, ShuiQiuPos1, ChuShouRota1)
    end)
    self._proxy:AddTimerTask(0.3, function()--延迟4秒后
        self.ChuShou1 = self._proxy:GenerateNpc(8059, ChuShouCamp2, ShuiQiuPos2, ChuShouRota1)
    end)

end


function XChar8056:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

--[[    if skillId == 805644 then
        self._proxy:AddTimerTask(1.2, function()--延迟4秒后
            self.Move = true -- 开启技能开关
        end)
    end]]

end


function XChar8056:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    Base.OnNpcSkillActionKeyframeSendEvent(self, launcher, eventName, skillActionId, keyFrameId, skillId)

    if launcher ~= self._uuid then
        return
    end

    if (eventName == "LuoYu") then -- 落雨
        local poissonDiskPoints = self._proxy:PoissonDiscPoints(38,45,20)
        for xIndex = 1, #poissonDiskPoints, 2 do
            local yIndex = xIndex + 1
            local Points = {x = poissonDiskPoints[xIndex]+26.32, y = 9.8, z = poissonDiskPoints[yIndex]+19}
            self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80564012,Points, Points,1)
            self._proxy:AddTimerTask(1, function()--延迟4秒后
                local poissonDiskPoints = self._proxy:PoissonDiscPoints(38,45,20)
                for xIndex = 1, #poissonDiskPoints, 2 do
                    local yIndex = xIndex + 1
                    local Points = {x = poissonDiskPoints[xIndex]+26.32, y = 9.8, z = poissonDiskPoints[yIndex]+19}
                    self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80564012,Points, Points,1)
                    for i = 1,#self.PlayUUID, 1 do
                        self._proxy:LaunchMissile(self._uuid,self.PlayUUID[i], 80530115, 80564012,1)
                    end
                end
            end)
            self._proxy:AddTimerTask(3, function()--延迟4秒后
                local poissonDiskPoints = self._proxy:PoissonDiscPoints(38,45,20)
                for xIndex = 1, #poissonDiskPoints, 2 do
                    local yIndex = xIndex + 1
                    local Points = {x = poissonDiskPoints[xIndex]+26.32, y = 9.8, z = poissonDiskPoints[yIndex]+19}
                    self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80564012,Points, Points,1)
                    for i = 1,#self.PlayUUID, 1 do
                        self._proxy:LaunchMissile(self._uuid,self.PlayUUID[i], 80530115, 80564012,1)
                    end
                end
            end)
            self._proxy:AddTimerTask(5, function()--延迟4秒后
                local poissonDiskPoints = self._proxy:PoissonDiscPoints(38,45,18)
                for xIndex = 1, #poissonDiskPoints, 2 do
                    local yIndex = xIndex + 1
                    local Points = {x = poissonDiskPoints[xIndex]+26.32, y = 9.8, z = poissonDiskPoints[yIndex]+19}
                    self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80564012,Points, Points,1)
                    for i = 1,#self.PlayUUID, 1 do
                        self._proxy:LaunchMissile(self._uuid,self.PlayUUID[i], 80530115, 80564012,1)
                    end
                end
            end)
            self._proxy:AddTimerTask(7, function()--延迟4秒后
                local poissonDiskPoints = self._proxy:PoissonDiscPoints(38,45,18)
                for xIndex = 1, #poissonDiskPoints, 2 do
                    local yIndex = xIndex + 1
                    local Points = {x = poissonDiskPoints[xIndex]+26.32, y = 9.8, z = poissonDiskPoints[yIndex]+19}
                    self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80564012,Points, Points,1)
                    for i = 1,#self.PlayUUID, 1 do
                        self._proxy:LaunchMissile(self._uuid,self.PlayUUID[i], 80530115, 80564012,1)
                    end
                end
            end)
        end
    end

    if (eventName == "ShanXian") then
        local QianZiPos = {x =41.53, y = 9.86, z = 42.92}
        self._proxy:SetNpcPosition(self._uuid,QianZiPos,false)
    end

end





function XChar8056:OnNpcBeforeTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    Base.OnNpcBeforeTriggerCounter(self, triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    -- 非技能目标不能弹刀
    XLog.Warning("打印")
    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastActionToTarget(self._uuid,805620,33)
end

function XChar8056:OnNpcOverDriveFull(targetUUID) -- OD已满事件
    if targetUUID ~= self._uuid then
        return
    end

    self._proxy:ApplyMagic(self._uuid, self._uuid, 80560007, 1)
    XLog.Warning("OD条已满")
    if self.ODindex < 1 then
        self.ODindex = self.ODindex + 1
    else
        self._proxy:ApplyMagic(self._uuid, self._uuid, 80560026, 1)
    end

end

function XChar8056:OnNpcODBreakBefore(targetUUID)  -- Break前事件
    if targetUUID ~= self._uuid then
        return
    end
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    self._proxy:ApplyMagic(self._uuid, self._uuid, 80560009, 1)
    self.AISwitch = false
    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastActionToTarget(self._uuid,805636,MaxThreatTarget)

    --时停,碎屏特效,镜头拉近

    for i = 1,#self.PlayUUID, 1 do
        self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8005302, 1)
        self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8005201, 1)
        self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8005401, 1)
        self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8005401, 1)
    end

end


function XChar8056:OnNpcODExitBreakAfter(targetUUID) -- 退出Break后
    if targetUUID ~= self._uuid then
        return
    end
    self.AISwitch = true
    self._proxy:ApplyMagic(self._uuid, self._uuid, 80560010, 1)
end


function XChar8056:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId)
    if targetUUID ~= self._uuid then
        return
    end

    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1000494, 1)
    self.AISwitch = false
    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastActionToTarget(self._uuid,805645,MaxThreatTarget)
    self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80530115, 80530601,1)
    self._proxy:AddTimerTask(3, function()--延迟4秒后
        self.AISwitch = true
    end)
end

function XChar8056:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillActionId, magicTags, customValue)

    if targetId ~= self._uuid then
        return
    end

    if magicId == 10519201 and self._proxy:CheckBuffByKind(self._uuid, 8005901) then
        local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionToTarget(self._uuid,805620,MaxThreatTarget)
    end

end




---@param dt number @ delta time

---@param eventType number
---@param eventArgs userdata
---
---
return XChar8056