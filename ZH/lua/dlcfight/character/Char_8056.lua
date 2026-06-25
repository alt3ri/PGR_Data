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
    self.HPCheck = true
    self.Bianka = 0
    self.PlayUUID =  self._proxy:GetPlayerNpcList()
    self.DanShengindex = 1
    self.NPC = 0
    self.ODindex = 0
    self.JiGuangindex = 0
    self.TanDaoCiShu = 0
    self._proxy:AddTimerTask(1, function()--延迟4秒后
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053023, 1)
    end)
    self._proxy:AddTimerTask(4.5, function()--延迟4秒后
        self._proxy:ApplyMagic(self._uuid, self._uuid, 80560025, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 80560028, 1)
    end)
    self._DanSheng= {
        [1] = 805608,
        [2] = 805609,
        [3] = 805610,
    }
    self.KuangBao1index = 0
    self.ODSkill1index3 = 1
    self.ODSkill1index2 = 1
    self.ODSkill1index1 = 1
    self._JiGuangSkillindex1 = 1
    self._JiGuangSkillindexEX = 1
    self.Skill1index = 1
    self.SiDouindex = 1
    self._NormalSkill1= {
        [1] = 805612,
        [2] = 805613,
        [3] = 805649,
        [4] = 805616,
        [5] = 805617,
        [6] = 805644,
        [7] = 805614,
        [8] = 805649,
        [9] = 805615,
    }

    self._ODSkill3 = {
        [1] = 805640,
        [2] = 805622,
        [3] = 805623,
        [4] = 805624,
        [5] = 805640,
        [6] = 805644,
        [7] = 805613,
        [8] = 805616,
        [9] = 805617,
        [10] = 805640,
        [11] = 805614,
        [12] = 805612,
        [13] = 805607,
        [14] = 805615,
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
    }

    self._ODSkill1 = {
        [1] = 805640,
        [2] = 805613,
        [3] = 805607,
        [4] = nil,
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

    if not self.AISwitch == true or self._proxy:CheckBuffByKind(self._uuid, 80560037) then
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
    if self.HPCheck == true then
        local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
        local SelfHpMax = self._proxy:GetNpcAttribMaxValue(self._uuid,0) --检测当前自身最大血量
        local SelfHpPercent = SelfHp / SelfHpMax -- 获取自身血量百分比
        if SelfHpPercent <= 0.1 then
            self.HPCheck = false
            self._proxy:ApplyMagic(self._uuid, self._uuid, 80560035, 1)
        end
    end

    if self.SiDouSwitch == true and self._proxy:CheckBuffByKind(self._uuid, 80560016) then -- 死斗启动后逻辑
        self.PlayUUID =  self._proxy:GetPlayerNpcList()
        if #self.PlayUUID == 1 then
            self.juli1 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[1],5)
        end

        if #self.PlayUUID == 2 then
            self.juli1 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[1],5)
            self.juli2 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[2],5)
        end

        if #self.PlayUUID == 3 then
            self.juli1 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[1],5)
            self.juli2 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[2],5)
            self.juli3 = self._proxy:CheckNpcDistance(self.NPC, self.PlayUUID[3],5)
        end

        if self.juli1 == true or self.juli2 == true or self.juli3 == true  then

            if #self.PlayUUID == 1 and self._proxy:CheckBuffByKind(self._uuid, 80560029) then
                XLog.Warning("激活死斗")
                self._proxy:AddTimerTask(15, function()--延迟4秒后
                    self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)
                    self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1)
                end)
                self.SiDouSwitch = false
                self.Move = true
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToTarget(self._uuid,805639,self.PlayUUID[1])
                self._proxy:ApplyMagic(self._uuid, self.PlayUUID[1], 8072003, 1)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 80560018, 1)
                self._proxy:ApplyMagic(self._uuid, self.NPC, 8072004, 1)
                self._proxy:ApplyMagic(self._uuid,self._uuid, 80560012, 1)
                local  ShuiQiang, id  = self._proxy:LaunchMissile(self._uuid, self.NPC, 80531204, 80720001,1) --水墙特效
                self.ShuiQiangid = id
                self:SiDouChuShou()
                self._proxy:AddTimerTask(2, function()--延迟4秒后
                    self._proxy:ApplyMagic(self._uuid,self._uuid, 80560012, 1)
                    self._proxy:DestroyNpc(self.NPC)
                end)
                self._proxy:AddTimerTask(18, function()--延迟4秒后
                    self._proxy:ApplyMagic(self._uuid,self._uuid, 80560013, 1)
                    --[[self._proxy:DestroyMissileByUUID(self.ShuiQiangid)]]
                end)
            end

            if #self.PlayUUID == 2 and self._proxy:CheckBuffByKind(self._uuid, 80560029) then
                self._proxy:AddTimerTask(15, function()--延迟4秒后
                    self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)
                    self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1)
                end)
                local Juli1 =self._proxy:GetNpcDistance(self.NPC,self.PlayUUID[1],false)
                local Juli2 =self._proxy:GetNpcDistance(self.NPC,self.PlayUUID[2],false)
                local Juliindex = {
                    {value = Juli1 , id = self.PlayUUID[1]},
                    {value = Juli2 , id = self.PlayUUID[2]},
                }

                table.sort(Juliindex,function(X,Y)
                    return X.value <  Y.value
                end)

                self.SiDouSwitch = false
                self.Move = true
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToTarget(self._uuid,805639,Juliindex[1].id)
                self._proxy:ApplyMagic(self._uuid, Juliindex[1].id, 8072003, 1)
                self._proxy:ApplyMagic(self._uuid, Juliindex[2].id, 8071007, 1)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 80560018, 1)
                self._proxy:ApplyMagic(self._uuid, self.NPC, 8072004, 1)
                local  ShuiQiang, id  = self._proxy:LaunchMissile(self._uuid, self.NPC, 80531204, 80720001,1) --水墙特效
                self.ShuiQiangid = id
                self:SiDouChuShou()
                self._proxy:AddTimerTask(2, function()--延迟4秒后
                    self._proxy:ApplyMagic(self._uuid,self._uuid, 80560012, 1)
                    self._proxy:DestroyNpc(self.NPC)
                end)
                self._proxy:AddTimerTask(18, function()--延迟4秒后
                    self._proxy:ApplyMagic(self._uuid,self._uuid, 80560013, 1)
                    --[[self._proxy:DestroyMissileByUUID(self.ShuiQiangid)]]
                end)
            end

            if #self.PlayUUID == 3 and self._proxy:CheckBuffByKind(self._uuid, 80560029) then
                self._proxy:AddTimerTask(15, function()--延迟4秒后
                    self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)
                    self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1)
                end)
                local Juli1 =self._proxy:GetNpcDistance(self.NPC,self.PlayUUID[1],false)
                local Juli2 =self._proxy:GetNpcDistance(self.NPC,self.PlayUUID[2],false)
                local Juli3 =self._proxy:GetNpcDistance(self.NPC,self.PlayUUID[3],false)
                local Juliindex = {
                    {value = Juli1 , id = self.PlayUUID[1]},
                    {value = Juli2 , id = self.PlayUUID[2]},
                    {value = Juli3 , id = self.PlayUUID[3]}
                }

                table.sort(Juliindex,function(X,Y)
                    return X.value <  Y.value
                end)

                self.SiDouSwitch = false
                self.Move = true
                self._proxy:AbortAction(self._uuid, true)
                self._proxy:CastActionToTarget(self._uuid,805639,Juliindex[1].id)
                self._proxy:ApplyMagic(self._uuid, Juliindex[1].id, 8072003, 1)
                self._proxy:ApplyMagic(self._uuid, Juliindex[2].id, 8071007, 1)
                self._proxy:ApplyMagic(self._uuid, Juliindex[3].id, 8071007, 1)
                self._proxy:ApplyMagic(self._uuid, self._uuid, 80560018, 1)
                self._proxy:ApplyMagic(self._uuid, self.NPC, 8072004, 1)
                local  ShuiQiang, id  = self._proxy:LaunchMissile(self._uuid, self.NPC, 80531204, 80720001,1) --水墙特效
                self.ShuiQiangid = id
                self:SiDouChuShou()
                self._proxy:AddTimerTask(2, function()--延迟4秒后
                    self._proxy:ApplyMagic(self._uuid,self._uuid, 80560012, 1)
                    self._proxy:DestroyNpc(self.NPC)
                end)
                self._proxy:AddTimerTask(18, function()--延迟4秒后
                    self._proxy:ApplyMagic(self._uuid,self._uuid, 80560013, 1)
                    --[[self._proxy:DestroyMissileByUUID(self.ShuiQiangid)]]
                end)
            end
        end

       --[[ if self.juli3 == true then
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
            self:SiDouChuShou()
           ]]--[[ self._proxy:LaunchMissile(self._uuid, self.NPC, 80563801, 80563805,1)]]--[[

            self._proxy:AddTimerTask(2, function()--延迟4秒后
                self._proxy:LaunchMissile(self._uuid, self.NPC, 80531204, 80720001,1)
                self._proxy:ApplyMagic(self._uuid,self._uuid, 80560012, 1)
                self._proxy:DestroyNpc(self.NPC)
            end)
            local ZhaDanWeiZhi,P1 = self._proxy:TryGetMissilePositionByUUID(self.ShuiQiu1)
            local ZhaDanWeiZhi2 = self._proxy:GetNpcPosition(self.NPC)
            self._proxy:LaunchMissileFromPosToPos(self._uuid,80563803,80563805,P1,ZhaDanWeiZhi2,1)
            self._proxy:DestroyMissileByUUID(self.ShuiQiu1)
        end]]

    end --死斗启动后逻辑

    if self.Move == true and  self._proxy:CheckBuffByKind(self._uuid, 80560036) then -- 狂暴-超级激光释放
        self.Move = false
        self:JiGangSkillEX()
    end


    if self.Move == true and  self._proxy:CheckBuffByKind(self._uuid, 80560035) then -- 狂暴-超级激光释放
        self.Move = false
        self:KuangBao1()
    end


    if self.Move == true and  self._proxy:CheckBuffByKind(self._uuid, 80560023) then -- 狂暴-超级激光释放
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

    if self.Move == true and  self._proxy:CheckBuffByKind(self._uuid, 80560021) then -- 死斗失败惩罚-超级激光释放
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

    if buffId == 8072004 then
        self.Move = true
        self.AISwitch = true
    end

    if buffId == 80590002 then
        self._proxy:ApplyMagic(self._uuid,self.LanQianZi,8053006, 1)
        self._proxy:AbortAction(self._uuid, true)
        self.AISwitch = false
        self._proxy:ApplyMagic(self._uuid,self._uuid,8053005, 1)
        self._proxy:CastActionToTarget(self.LanQianZi,807001,self.Target)
    end

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

function XChar8056:KuangBao1() --彩蛋机制路线-点名水囚
    self.PlayUUID = self._proxy:GetPlayerNpcList()
    self.KuangBao1index = self.KuangBao1index + 1
    local Target = self.PlayUUID[self.KuangBao1index]
    self._proxy:CastActionToTarget(self._uuid,805651,Target)
    self._proxy:AddTimerTask(1.85, function()
        local cishu = self.KuangBao1index - 1
        self._proxy:ApplyMagic(self._uuid,self.PlayUUID[cishu],8072009, 1)
    end)
    if self.KuangBao1index == #self.PlayUUID then
        self._proxy:ApplyMagic(self._uuid,self._uuid,80560036, 1)
        local ChuShouCamp1= ENpcCampType.Camp1
        local ShuiQiuPos = {x = 40.87, y = 9.86, z = 43.03}
        local ChuShouRota1 = {x = 0, y = -90, z = 0}
        self.Bianka = self._proxy:GenerateNpc(8059, ChuShouCamp1, ShuiQiuPos, ChuShouRota1)
    end

end


function XChar8056:JiGangSkillEX() --最终激光技能组 - 打断
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    if MaxThreatTarget ~= 0 then
        self.Target = MaxThreatTarget
    else
        self.Target = self.PlayUUID[1] --self.Cuuid
    end
    local JiGuangSkill1key = self._JiGuangSkill1[self._JiGuangSkillindexEX] -- 获取当前技能释放序列
    if JiGuangSkill1key ~= nil then --序号大于3则返回1
        self._proxy:CastActionToTarget(self._uuid,JiGuangSkill1key,self.Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end
    self._JiGuangSkillindexEX = self._JiGuangSkillindexEX + 1 -- 每次释放技能加一次序号
    if self._JiGuangSkillindexEX == 2 then
        local ChuShouCamp1= ENpcCampType.Camp1
        local ChuShouCamp2= ENpcCampType.Camp2
        local QianZiPos = {x =24.46, y = 9.77, z = 43}
        local QianZiPos2 = {x =16.9, y = 9.72, z = 43}
        local QianZiRota = {x = 0, y = 90, z = 0}
        self.LanQianZi = self._proxy:GenerateNpc(8070, ChuShouCamp1, QianZiPos, QianZiRota)
        self.DaQianZi = self._proxy:GenerateNpc(8110, ChuShouCamp2, QianZiPos2, QianZiRota)
        self._proxy:AddTimerTask(1, function()
            self._proxy:SetNpcPosition(self._uuid,QianZiPos,true)
            self._proxy:SetNpcRotation(self._uuid,QianZiRota)
        end)
    end
    if self._JiGuangSkillindexEX == 4 then --序号大于3则返回1
        for i = 1,#self.PlayUUID, 1 do
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071010, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071012, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071013, 1)
        end

        self._proxy:AddTimerTask(3, function()
            self._proxy:ApplyMagic(self._uuid,self.Bianka,80590001, 1)
            self._proxy:ApplyMagic(self._uuid,self.LanQianZi,8053006, 1)
            self._proxy:AbortAction(self._uuid, true)
            self.AISwitch = false
            self._proxy:ApplyMagic(self._uuid,self._uuid,8053005, 1)
            self._proxy:CastActionToTarget(self.LanQianZi,807001,self.Target)
        end)
    end
end


function XChar8056:ODSkill() --OD技能组1
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    if MaxThreatTarget ~= 0 then
        self.Target = MaxThreatTarget
    else
        self.Target = self.PlayUUID[1] --self.Cuuid
    end
    local ODSkill1key = self._ODSkill1[self.ODSkill1index1] -- 获取当前技能释放序列
    if ODSkill1key ~= nil then
        self._proxy:CastActionToTarget(self._uuid,ODSkill1key,self.Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end
    self.ODSkill1index1 = self.ODSkill1index1 + 1 -- 每次释放技能加一次序号
    if self.ODSkill1index1 == 5 then
        XLog.Debug("死斗开启")
        self._proxy:ApplyMagic(self._uuid,self._uuid,80560019, 1)
        self._proxy:AddTimerTask(1.5, function()
            self.Move = true
        end)
    end
end

function XChar8056:ODSkill3() --OD技能组3,软狂暴
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    if MaxThreatTarget ~= 0 then
        self.Target = MaxThreatTarget
    else
        self.Target = self.PlayUUID[1] --self.Cuuid
    end
    local ODSkill1key = self._ODSkill3[self.ODSkill1index3] -- 获取当前技能释放序列
    local Target = self.PlayUUID[1]
    if ODSkill1key ~= nil then --序号大于3则返回1
        self._proxy:CastActionToTarget(self._uuid,ODSkill1key,self.Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end
    self.ODSkill1index3 = self.ODSkill1index3 + 1 -- 每次释放技能加一次序号
    if self.ODSkill1index3 == 15 then
        self.ODSkill1index3 = 1
    end
end


function XChar8056:ODSkill2() --OD技能组2
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    if MaxThreatTarget ~= 0 then
        self.Target = MaxThreatTarget
    else
        self.Target = self.PlayUUID[1] --self.Cuuid
    end
    local ODSkill1key = self._ODSkill2[self.ODSkill1index2] -- 获取当前技能释放序列
    if ODSkill1key ~= nil then --序号大于3则返回1
        self._proxy:CastActionToTarget(self._uuid,ODSkill1key,self.Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end
    self.ODSkill1index2 = self.ODSkill1index2 + 1 -- 每次释放技能加一次序号
    if self.ODSkill1index2 == 13 then
        self.ODSkill1index2 = 1
    end
end

function XChar8056:JiGangSkill1() --超强激光技能组
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    if MaxThreatTarget ~= 0 then
        self.Target = MaxThreatTarget
    else
        self.Target = self.PlayUUID[1] --self.Cuuid
    end
    local JiGuangSkill1key = self._JiGuangSkill1[self._JiGuangSkillindex1] -- 获取当前技能释放序列
    if JiGuangSkill1key ~= nil then --序号大于3则返回1
        self._proxy:CastActionToTarget(self._uuid,JiGuangSkill1key,self.Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end
    self._JiGuangSkillindex1 = self._JiGuangSkillindex1 + 1 -- 每次释放技能加一次序号
    if self._JiGuangSkillindex1 == 2 then
        local QianZiPos = {x =24.46, y = 9.77, z = 43}
        local QianZiRota = {x = 0, y = 90, z = 0}
        self._proxy:AddTimerTask(1, function()
            self._proxy:SetNpcPosition(self._uuid,QianZiPos,true)
            self._proxy:SetNpcRotation(self._uuid,QianZiRota)
        end)
        if self._JiGuangSkillindex1 == 4 then --序号大于3则返回1
            for i = 1,#self.PlayUUID, 1 do
                self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071010, 1)
                self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071012, 1)
                self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071013, 1)
            end
        end
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
    if MaxThreatTarget ~= 0 then
        self.Target = MaxThreatTarget
    else
        self.Target = self.PlayUUID[1] --self.Cuuid
    end
    local NormalSkill1key = self._NormalSkill1[self.Skill1index] -- 获取当前技能释放序列
    self._proxy:CastActionToTarget(self._uuid,NormalSkill1key,self.Target) -- 向最大仇恨目标按顺序释放常规技能组1
    self.Skill1index = self.Skill1index + 1 -- 每次释放技能加一次序号
    if self.Skill1index >= 10 then --序号大于3则返回1
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
            self._proxy:ApplyMagic(self._uuid,self._uuid, 80560016, 1)
        end)
    elseif self.SiDouindex == 5  then
        self._proxy:ApplyMagic(self._uuid,self.NPC, 80560030, 1)
        self._proxy:ApplyMagic(self._uuid,self.NPC, 80560031, 1)
        for i = 1,#self.PlayUUID, 1 do
            self._proxy:SetNpcFaceToSearchTarget(self.PlayUUID[i], self._uuid)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 80560033, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 80560034, 1)
        end
        self._proxy:AddTimerTask(2, function()--延迟4秒后
            self._proxy:ApplyMagic(self._uuid,self.NPC, 8072001, 1)
        end)
        self._proxy:AddTimerTask(6, function()--延迟4秒后
            self._proxy:ApplyMagic(self._uuid,self.NPC, 80560032, 1)
            self._proxy:ApplyMagic(self._uuid,self._uuid, 80560029, 1)
        end)
    elseif self.SiDouindex == 6  then
        self.SiDouSwitch = false
        self._proxy:AddTimerTask(15, function()
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1)
        end)
        self._proxy:AddTimerTask(1, function()
            if self._proxy:CheckBuffByKind(self._uuid, 80560018) then
                self._proxy:ApplyMagic(self._uuid,self._uuid, 80560020, 1)
            else
                self._proxy:ApplyMagic(self._uuid,self.NPC, 8072004, 1)
                self._proxy:ApplyMagic(self._uuid,self._uuid, 80560021, 1)
                self._proxy:AddTimerTask(4, function()--延迟4秒后
                    self._proxy:DestroyNpc(self.NPC)
                end)
            end
        end)
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


function XChar8056:SiDouChuShou() -- 死斗场外触手
    self.PlayUUID =  self._proxy:GetPlayerNpcList()
    if #self.PlayUUID == 2 then
        local ChuShouCamp2= ENpcCampType.Camp2
        local ShuiQiuPos1 = {x = 41.41, y = 8, z = 22}
        local ChuShouRota1 = {x = 0, y = 180, z = 0}
        self.SiDouChuShou1 = self._proxy:GenerateNpc(8057, ChuShouCamp2, ShuiQiuPos1, ChuShouRota1)
        self._proxy:ApplyMagic(self._uuid,self.SiDouChuShou1, 8057002, 1)
        self._proxy:AddTimerTask(2, function()--延迟4秒后
            self._proxy:ApplyMagic(self._uuid,self.SiDouChuShou1, 8053025, 1)
            self._proxy:ApplyMagic(self._uuid,self.SiDouChuShou1, 8053006, 1)
        end)
    end

    if #self.PlayUUID == 3 then
        local ChuShouCamp2= ENpcCampType.Camp2
        local ShuiQiuPos1 = {x = 41.41, y = 8, z = 22}
        local ShuiQiuPos2 = {x = 41.52, y = 8, z = 65}
        local ChuShouRota1 = {x = 0, y = 180, z = 0}
        self.SiDouChuShou1 = self._proxy:GenerateNpc(8057, ChuShouCamp2, ShuiQiuPos1, ChuShouRota1)
        self.SiDouChuShou2   = self._proxy:GenerateNpc(8057, ChuShouCamp2, ShuiQiuPos2, ChuShouRota1)
        self._proxy:ApplyMagic(self._uuid,self.SiDouChuShou1, 8057002, 1)
        self._proxy:ApplyMagic(self._uuid,self.SiDouChuShou2, 8057002, 1)
        self._proxy:AddTimerTask(2, function()--延迟4秒后
            self._proxy:ApplyMagic(self._uuid,self.SiDouChuShou1, 8053025, 1)
            self._proxy:ApplyMagic(self._uuid,self.SiDouChuShou2, 8053025, 1)
            self._proxy:ApplyMagic(self._uuid,self.SiDouChuShou1, 8053006, 1)
            self._proxy:ApplyMagic(self._uuid,self.SiDouChuShou2, 8053006, 1)
        end)
    end
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
            self._proxy:AddTimerTask(1, function()--延迟4秒后
                local poissonDiskPoints = self._proxy:PoissonDiscPoints(38,45,20)
                for xIndex = 1, #poissonDiskPoints, 2 do
                    local yIndex = xIndex + 1
                    local Points = {x = poissonDiskPoints[xIndex]+26.32, y = 9.8, z = poissonDiskPoints[yIndex]+19}
                    self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80564012,Points, Points,1)
                    for i = 1,#self.PlayUUID, 1 do
                        self._proxy:LaunchMissile(self._uuid,self.PlayUUID[i], 80531204, 80564012,1)
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
                        self._proxy:LaunchMissile(self._uuid,self.PlayUUID[i], 80531204, 80564012,1)
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
                        self._proxy:LaunchMissile(self._uuid,self.PlayUUID[i], 80531204, 80564012,1)
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
                        self._proxy:LaunchMissile(self._uuid,self.PlayUUID[i], 80531204, 80564012,1)
                    end
                end
            end)
    end

    if (eventName == "ShanXian") then
        local QianZiPos = {x =36, y = 9.86, z = 43}
        self._proxy:SetNpcPosition(self._uuid,QianZiPos,false)
    end

    if (eventName == "TanHuan1") then
        self._proxy:CastAction(self._uuid,805656)
    end

    if (eventName == "TanHuan2") then
        self._proxy:CastAction(self._uuid,805657)
    end
end



function XChar8056:OnNpcBeforeTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    Base.OnNpcBeforeTriggerCounter(self, triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    -- 非技能目标不能弹刀
    XLog.Warning("打印")
    if self.TanDaoCiShu >= 3 then
        self.TanDaoCiShu = 0
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid,805655)
    else
        self.TanDaoCiShu = self.TanDaoCiShu + 1
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastAction(self._uuid,805620)
    end

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
    self._proxy:CastActionToTarget(self._uuid,805652,MaxThreatTarget)
    self._proxy:AddTimerTask(1.83, function()--延迟4秒后
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionToTarget(self._uuid,805653,MaxThreatTarget)
    end)

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
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    self.AISwitch = true
    self._proxy:ApplyMagic(self._uuid, self._uuid, 80560010, 1)
    self._proxy:CastActionToTarget(self._uuid,805654,MaxThreatTarget)
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
    self._proxy:AddTimerTask(5, function()--延迟4秒后
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053068, 1)
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