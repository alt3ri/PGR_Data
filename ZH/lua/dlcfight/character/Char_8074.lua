---@type XRelinkCharBase
local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")
local XFastBlackboard = require("Tools/Blackboard/XFastBlackboard")

---首席指挥官角色脚本
---@class XChar8074 : XRelinkCharBase
local XChar8074 = XDlcScriptManager.RegCharScript(8074, "XChar8074", Base)

--[[function XChar8074:Init() -- 初始化
    Base.Init(self)
    self.Move = true
    self.Guangjian = true
    self.AISwitch = true -- AI总开关
    self.SkillSwitch = true  -- 技能释放开关
    self.SkillSwitch2 = true  -- 技能保底释放开关
    self.JiGuangSwitch = true  -- 激光技能释放开关
    self.ZhaoHuanChuShou1 = 0
    self.ZhaoHuanChuShou2 = 0
    self.ZhaoHuanChuShou3 = 0
    self.ZhaoHuanChuShouindex = 0
    self.ZhaoHuanChuShouSwitch = true
    self.ODindex = 0
    self._proxy:SetNpcIgnoreObstacle(self._uuid, 11 , true)

    self._JiGuangSkill1 = {
        [1] = 805308,
        [2] = 805309,
        [3] = 805310,
    }

    self._HeiQiuSkill1 = {
        [1] = 805311,
        [2] = 805312,
        [3] = 805313,
    }

    self._JiGuangSkill2 = {
        [1] = 805318,
        [2] = 805319,
        [3] = 805318,
        [4] = 805319,
    }

    self._JiGuangSkill3 = {
        [1] = 805325,
        [2] = 805326,
        [3] = 805327,
    }

    self._NormalSkill1 = {
        [1] = 805302,
        [2] = 805303,
        [3] = nil,
        [4] = nil,
        [5] = 805305,
        [6] = 805320,
        [7] = 805314,
        [8] = 805305,
        [9] = nil,
        [10] = 805307,
    }

    self._ODSkill1 = {
        [1] = 805315,
        [2] = 805316,
        [3] = 805317,
        [4] = 805303,
        [5] = nil,
        [6] = 805305,
        [7] = 805307,
        [8] = nil,
    }


    self.Skill1index = 1
    self.JiGangSkill1index1 = 1
    self.JiGangSkill1index2 = 1
    self.JiGangSkill1index3 = 1
    self.Skill1index1 = 0
    self.ODSkill1index1 = 0
    self.PlayUUID = nil
    self.GuangJian_UUID = 0
    self.Target = 0
]]--[[    self._proxy:ApplyMagic(self._uuid, self.PlayUUID[1], 8071010, 1)
    self._proxy:ApplyMagic(self._uuid, self.PlayUUID[1], 8071012, 1)
    self._proxy:ApplyMagic(self._uuid, self.PlayUUID[1], 8071013, 1)]]--[[
  ]]--[[  self._proxy:AddTimerTask(20, function()--延迟20秒后，开始召唤触手
        XLog.Warning("召唤触手")
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053021, 1)
    end)]]--[[

    self:ChouShouCheck()

end]]

function XChar8074:ScriptInit(isGainControl)
    self.Move = true
    self.Guangjian = true
    self.AISwitch = false -- AI总开关
--[[    self._proxy:AddTimerTask(2, function()--延迟5秒后，释放影牌技能
        self._proxy:CastAction(self._uuid,805333)
    end)]]
    self._proxy:AddTimerTask(12, function()--延迟5秒后，释放影牌技能
        self.AISwitch = true
    end)
    self.SkillSwitch = true  -- 技能释放开关
    self.SkillSwitch2 = true  -- 技能保底释放开关
    self.JiGuangSwitch = true  -- 激光技能释放开关
    self.HPCheck = true  -- 血量检测开关
    self.ZhaoHuanChuShou1 = 0
    self.ZhaoHuanChuShou2 = 0
    self.ZhaoHuanChuShou3 = 0
    self.ZhaoHuanChuShouindex = 0
    self.ZhaoHuanChuShouSwitch = true
    self.ODindex = 0
    self._proxy:SetNpcIgnoreObstacle(self._uuid, 11 , true)
    self.RenXing = 8077
    self.ChuShouuuid = 8078

--[[    local T = {
        {value = 5 , id = 323},
        {value = 1 , id = 33},
        {value = 7 , id = 872}
    }


    table.sort(T,function(X,Y)
        return X.value <  Y.value
    end)]]

   --[[ for i,v in ipairs(T) do
        XLog.Warning(v.id)
    end]]


    self._JiGuangSkill1 = {
        [1] = 805308,
        [2] = 805309,
        [3] = 805310,
    }

    self._HeiQiuSkill1 = {
        [1] = 805311,
        [2] = 805312,
        [3] = 805313,
    }

    self._JiGuangSkill2 = {
        [1] = 805319,
        [2] = 805318,
    }

    self._JiGuangSkill3 = {
        [1] = 805337,
        [2] = 805338,
    }

    self._NormalSkill1 = {
        [1] = 805302,
        [2] = 805303,
        [3] = 805339,
        [4] = nil,
        [5] = 805307,
        [6] = 805303,
        [7] = 805339,
        [8] = nil,
        [9] = 805307,
    }

    self._ODSkill1 = {
        [1] = 805315,
        [2] = 805316,
        [3] = 805317,
        [4] = 805303,
        [5] = nil,
        [6] = 805307,
        [7] = nil,
        [8] = 805339,
        [9] = 805303,
        [10] = 805307,
        [11] = nil,
        [12] = 805339,
        [13] = 805303,
        [14] = 805315,
        [15] = 805316,
        [16] = 805317,
    }
    self.Skill1index = 1
    self.JiGangSkill1index1 = 1
    self.JiGangSkill1index2 = 1
    self.JiGangSkill1index3 = 1
    self.Skill1index1 = 0
    self.ODSkill1index1 = 0
    self.PlayUUID = nil
    self.GuangJian_UUID = 0
    self.Target = 0
    self.LuoJianKaiGuan = true

end

function XChar8074:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- 添加buff
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore) --注册技能释放前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter) --注册技能释放后前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction) -- 技能释放完成事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcDamageAfter) -- 计算伤害后
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid) --注册技能事件
    -- 初始化韧性OD系统
    self._proxy:SetNpcBreakGaugeActive(self._uuid, true)
    self._proxy:SetNpcOverDriveActive(self._uuid, true)
    --破韧、OD与Break事件
    self._proxy:RegisterEvent(EWorldEvent.NpcOverDriveFull) -- OD已满事件
    self._proxy:RegisterEvent(EWorldEvent.NpcODBreakBefore) --Break事件
    self._proxy:RegisterEvent(EWorldEvent.NpcODExitBreakAfter) --退出Break事件
    self._proxy:RegisterEvent(EWorldEvent.NpcBrokenAfter) -- 破韧前事件

    -- 注册自定义lua事件
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkSetAIActivate)
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkAIBorn)

end


function XChar8074:Update(dt)
    Base.Update(self, dt)

    if self.HPCheck == true then
        local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
        local SelfHpMax = self._proxy:GetNpcAttribMaxValue(self._uuid,0) --检测当前自身最大血量
        local SelfHpPercent = SelfHp / SelfHpMax -- 获取自身血量百分比
        if SelfHpPercent <= 0.4 then
            self.HPCheck = false
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053045, 1)
        end
    end


    if self.PlayUUID == nil  then
        XLog.Warning("检测目标")
        XLog.Warning(self.SkillSwitch)
        self.PlayUUID = self._proxy:GetPlayerNpcList()
        XLog.Warning(self.PlayUUID)
        self:ChouShouCheck()
        for i = 1,#self.PlayUUID, 1 do
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071010, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071012, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071013, 1)
        end

    end

    if not self.AISwitch == true then -- AI总开关未开启则返回
        return
    end

    if self._proxy:CheckActorExist(self.ZhaoHuanChuShou1) == false or self._proxy:CheckActorExist(self.ZhaoHuanChuShou2) == false or self._proxy:CheckActorExist(self.ZhaoHuanChuShou3) == false  then
        self.ZhaoHuanChuShouSwitch = true
    else
        self.ZhaoHuanChuShouSwitch = false
    end


    if self.SkillSwitch == true  and self._proxy:CheckBuffByKind(self._uuid, 8053046) and not self._proxy:CheckBuffByKind(self._uuid, 8053045)then -- 技能开关开启后执行以下
        self.SkillSwitch = false
        self.SkillSwitch2 = false
        self:XiShou()
    end

    if self.SkillSwitch == true and self._proxy:CheckBuffByKind(self._uuid, 8053045)  and not self._proxy:CheckBuffByKind(self._uuid, 8053036) then -- 技能开关开启后执行以下
        self.SkillSwitch = false
        self.SkillSwitch2 = false
        self:JiGuangSkill3()
    end


    if self.SkillSwitch == true and  self._proxy:CheckBuffByKind(self._uuid, 8053044) and self.SkillSwitch2 == true then -- 技能开关开启后执行以下
        self.AISwitch = false
        self.SkillSwitch = false
        self.SkillSwitch2 = false
        self:FuHua()
    end

    if self.SkillSwitch == true and  self._proxy:CheckBuffByKind(self._uuid, 8053035) then -- OD激活
        self.SkillSwitch = false
        self.SkillSwitch2 = false
        self:ODJiHuo()
    end


--[[    if self.SkillSwitch == true and self._proxy:CheckBuffByKind(self._uuid, 8053021) then -- 技能开关开启后执行以下
        self.SkillSwitch = false
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053022, 1)
        self:ChuShouZhaoHuan()
    end]]

    if self.SkillSwitch == true and self._proxy:CheckBuffByKind(self._uuid, 8053013) then -- 技能开关开启后执行以下
        self.SkillSwitch = false
        self.SkillSwitch2 = false
        self:HeiQiuSkill1()
    end

    if self.SkillSwitch == true and not self._proxy:CheckBuffByKind(self._uuid, 8053013) and self._proxy:CheckBuffByKind(self._uuid, 8053040) then -- 技能开关开启后执行以下
        self.SkillSwitch = false
        self.SkillSwitch2 = false
        self:JiGuangSkill2()
    end


    if self.SkillSwitch == true and not self._proxy:CheckBuffByKind(self._uuid, 8053013) and self._proxy:CheckBuffByKind(self._uuid, 8053039) then -- 技能开关开启后执行以下
        self.SkillSwitch = false
        self.SkillSwitch2 = false
        self:JiGuangSkill1()
    end


    if self.SkillSwitch == true and self._proxy:CheckBuffByKind(self._uuid, 8053036) then -- 技能开关开启后执行以下
        self.SkillSwitch = false
        self.SkillSwitch2 = false
        self:ODSkill1()
    end


    if self.SkillSwitch == true  and not self._proxy:CheckBuffByKind(self._uuid, 8053036) then -- 技能开关开启后执行以下
        XLog.Warning("开始攻击")
        self.SkillSwitch = false
        self.SkillSwitch2 = false
        self:NormalSkill1()
    end
end

--[[function XChar8074:AfterDamageCalc(eventArgs)   -- 计算伤害后
    if eventArgs.Target ~= self._uuid then
        return
    end

    if eventArgs.Id ~= 80540110 then
        eventArgs.PhysicalDamage = 0
        XLog.Warning("物理伤害为0")
    end

    ]]--[[if  self._proxy:CheckBuffByKind(self._uuid, 8053064) then
        if eventArgs.Id ~= 80540110 then
            eventArgs.PhysicalPermyriad = 0
        end
    end]]--[[
end]]

function XChar8074:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)


end

function XChar8074:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)

    if launcherId == self.ChuShouLuuid and skillId == 805409 then
        XLog.Warning("触手倒地")
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8054001, 1)
    end

    if launcherId ~= self._uuid then
        return
    end


    if skillId == 805308 then
        if self.Guangjian == true then
            self.Guangjian = false
            self._proxy:AddTimerTask(4, function()--延迟5秒后，释放影牌技能
                local Target = self.PlayUUID[1]
                local GuangJianCamp= ENpcCampType.Camp1
                local GuangJianBornPos = {x = 32.22, y = 9.78, z = 42.9}
                local GuangJianBornRota = {x = 0, y = 90, z = 0}
                self.GuangJian_UUID = self._proxy:GenerateNpc(8058, GuangJianCamp, GuangJianBornPos, GuangJianBornRota)
                --[[self._proxy:AddLink(self._uuid, Target, self.GuangJian_UUID,"HitCase","HitCase", "FxJianTouLianXian01")]]
            end)

        end

        if self._proxy:CheckActorExist(self.GuangJian_UUID) then --检测光剑是否存活
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053017, 1)
        else
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053018, 1)
        end

    end

    if skillId == 805318 then

        if self._proxy:CheckActorExist(self.GuangJian_UUID) then --检测光剑是否存活
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053017, 1)
        else
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053018, 1)
        end

    end


--[[    if skillId == 805303 then
        self._proxy:AddTimerTask(0.95, function()--延迟5秒后，释放影牌技能
            self._proxy:LaunchMissile(self._uuid, 433, 80530114, 80530312,1)
        end)
        self._proxy:AddTimerTask(2.3, function()--延迟5秒后，释放影牌技能
            self._proxy:LaunchMissile(self._uuid, 433, 80530114, 80530312,1)
        end)
    end]]

    if skillId == 805313 then
        self._proxy:AddTimerTask(1, function()--延迟5秒后，释放影牌技能
            self._proxy:LaunchMissile(self._uuid, self.GuangJian_UUID, 80531205, 80531204,1)
        end)
        self._proxy:AddTimerTask(2.3, function()--延迟5秒后，释放影牌技能
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053015, 1)
            if not self._proxy:CheckBuffByKind(self.GuangJian_UUID, 8053010) then
                self._proxy:LaunchMissile(self._uuid, self.GuangJian_UUID, 80531204, 80530512,1)
            end
        end)
        self._proxy:AddTimerTask(4, function()--延迟5秒后，释放影牌技能
            self._proxy:LaunchMissile(self._uuid, self.GuangJian_UUID, 80531206, 80531204,1)
        end)

        self._proxy:AddTimerTask(5.3, function()--延迟5秒后，释放影牌技能
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053015, 1)
            if not self._proxy:CheckBuffByKind(self.GuangJian_UUID, 8053010) then
                self._proxy:LaunchMissile(self._uuid, self.GuangJian_UUID, 80531204, 80530512,1)
            end
        end)

        self._proxy:AddTimerTask(7, function()--延迟5秒后，释放影牌技能
            self._proxy:LaunchMissile(self._uuid, self.GuangJian_UUID, 80531207, 80531204,1)
        end)
        self._proxy:AddTimerTask(8.3, function()--延迟5秒后，释放影牌技能
            if not self._proxy:CheckBuffByKind(self.GuangJian_UUID, 8053010) then
                self._proxy:LaunchMissile(self._uuid, self.GuangJian_UUID, 80531204, 80530512,1)
            end
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053015, 1)
            self._proxy:ApplyMagic(self._uuid, self.GuangJian_UUID, 8053020, 1)
        end)
    end

    if skillId == 805317 then
        self._proxy:AddTimerTask(1.3, function()--延迟5秒后，释放影牌技能
            self._proxy:PoissonDiscPoints(50, 50,5)
        end)
    end

    if skillId == 805321 then
       --[[ self._proxy:AddTimerTask(0.6, function()--延迟5秒后，释放影牌技能
            local Points = {x =41.53, y = 9.86, z = 42.92}
            self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80532101,Points, Points,1)
        end)]]
    end

end

function XChar8074:ChouShouCheck() --获取左右触手uuid
    self._proxy:AddTimerTask(2, function()
        self.Npcuuid = self._proxy:GetNpcList()
        for xIndex = 1, #self.Npcuuid, 1 do
            if self._proxy:CheckBuffByKind(self.Npcuuid[xIndex], 8054000) then
                self.ChuShouLuuid = self.Npcuuid[xIndex]
                XLog.Warning("左触手"..self.ChuShouLuuid)
            elseif self._proxy:CheckBuffByKind(self.Npcuuid[xIndex], 8055000) then
                self.ChuShouRuuid = self.Npcuuid[xIndex]
                XLog.Warning("右触手"..self.ChuShouRuuid)
            end
        end
    end)
end

function XChar8074:ClassCheck() --按职业区分目标
    XLog.Warning("开始职业检测")
    self.Tuuid = nil
    self.Cuuid = nil
    self.Huuid = nil
    if self._proxy:CheckBuffByKind(self.PlayUUID[1], 1000487) then -- 检查1号玩家是否为T
        self.Tuuid = self.PlayUUID[1]
    end
    XLog.Warning("T职业为"..self.Tuuid)
    if self._proxy:CheckBuffByKind(self.PlayUUID[2], 1000487) and self.Tuuid ~= self.PlayUUID[1] then -- 检查2号玩家是否为T
        self.Tuuid = self.PlayUUID[2]
    end

    if self._proxy:CheckBuffByKind(self.PlayUUID[3], 1000487) and self.Tuuid ~= self.PlayUUID[1] and self.Tuuid ~= self.PlayUUID[2]  then -- 检查3号玩家是否为T
        self.Tuuid = self.PlayUUID[3]
    end

    if self.Tuuid == nil then  -- 若T为空，则选择其他职业承担T的位置
        if self._proxy:CheckBuffByKind(self.PlayUUID[1], 1000486) then -- 1号位为C时，优先承担T位
            self.Tuuid = self.PlayUUID[1]
        else
            if self._proxy:CheckBuffByKind(self.PlayUUID[2], 1000486) then  -- 1号位不为C，2号位若为C则优先承担T位
                self.Tuuid = self.PlayUUID[2]
            else
                if self._proxy:CheckBuffByKind(self.PlayUUID[3], 1000486) then -- 1和2都不为C，3号位若为C则承担T位
                    self.Tuuid = self.PlayUUID[3]
                else
                    self.Tuuid = self.PlayUUID[1]   -- 全奶队伍，默认1号位承担T位
                end
            end
        end
    end

    if self.Tuuid == self.PlayUUID[1] then -- 若1号位为T，则开始分发C和奶位
        if self._proxy:CheckBuffByKind(self.PlayUUID[2], 1000486) then -- 检查2号玩家是否为C，若是则承担C位，3号承担奶位
            self.Cuuid = self.PlayUUID[2]
            self.Huuid = self.PlayUUID[3]
        else  -- 若不是则承担奶位，3号承担C位。
            self.Cuuid = self.PlayUUID[3]
            self.Huuid = self.PlayUUID[2]
        end
    end

    if self.Tuuid == self.PlayUUID[2] then -- 若2号位为T，则开始分发C和奶位
        if self._proxy:CheckBuffByKind(self.PlayUUID[1], 1000486) then -- 检查1号玩家是否为C，若是则承担C位，3号承担奶位
            self.Cuuid = self.PlayUUID[1]
            self.Huuid = self.PlayUUID[3]
        else  -- 若不是则承担奶位，3号承担C位。
            self.Cuuid = self.PlayUUID[3]
            self.Huuid = self.PlayUUID[1]
        end
    end

    if self.Tuuid == self.PlayUUID[3] then -- 若3号位为T，则开始分发C和奶位
        if self._proxy:CheckBuffByKind(self.PlayUUID[1], 1000486) then -- 检查1号玩家是否为C，若是则承担C位，2号承担奶位
            self.Cuuid = self.PlayUUID[1]
            self.Huuid = self.PlayUUID[2]
        else  -- 若不是则承担奶位，2号承担C位。
            self.Cuuid = self.PlayUUID[2]
            self.Huuid = self.PlayUUID[1]
        end
    end
end


--------------------------------技能组逻辑---------------------------------------------
function XChar8074:JiGuangSkill3() --触手炼狱启动
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    local JiGuangSkill3key = self._JiGuangSkill3[self.JiGangSkill1index3] -- 获取当前技能释放序列
    local Target = self.PlayUUID[1]
    self._proxy:CastActionToTarget(self._uuid,JiGuangSkill3key,Target) -- 向最大仇恨目标按顺序释放常规技能组1
    self.JiGangSkill1index3 = self.JiGangSkill1index3 + 1

--[[    self._proxy:AddTimerTask(2, function()--延迟4秒后
        self._proxy:CastActionToTarget(self.QianZi_UUID,805630,Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end)]]

   --[[ if self.JiGangSkill1index3 == 2 then --序号大于2则返回0
        self._proxy:AddTimerTask(3, function()--延迟4秒后
            local QianZiPos = {x =24.46, y = 9.77, z = 43}
            self._proxy:SetNpcPosition(self.QianZi_UUID,QianZiPos,true) -- 向最大仇恨目标按顺序释放常规技能组1
            self._proxy:AddTimerTask(0.5, function()--延迟4秒后
                self._proxy:CastActionToTarget(self.QianZi_UUID,805631,Target) -- 向最大仇恨目标按顺序释放常规技能组1
                self._proxy:AddTimerTask(0.5, function()--延迟4秒后
                    self._proxy:CastActionToTarget(self.QianZi_UUID,805632,Target) -- 向最大仇恨目标按顺序释放常规技能组1
                    self._proxy:AddTimerTask(2.2, function()--延迟4秒后
                        self._proxy:CastActionToTarget(self.QianZi_UUID,805633,Target) -- 向最大仇恨目标按顺序释放常规技能组1
                        self._proxy:AddTimerTask(6, function()--延迟4秒后
                            self._proxy:CastActionToTarget(self.QianZi_UUID,805634,Target) -- 向最大仇恨目标按顺序释放常规技能组1
                        end)
                    end)
                end)
            end)
        end)
    end]]

    if self.JiGangSkill1index3 >= 4 then --序号大于3则返回1
     --[[   self._proxy:ApplyMagic(self._uuid, self._uuid, 8053046, 1)
        self.AISwitch = false
        self._proxy:AddTimerTask(3, function()
            self.AISwitch = true
        end)]]
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053055, 1)
        self._proxy:AddTimerTask(6, function()
            for i = 1,#self.PlayUUID, 1 do
                self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8053054, 1)
            end
        end)
    end
end


function XChar8074:JiGuangSkill1() --激光技能组1
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    local JiGuangSkill1key = self._JiGuangSkill1[self.JiGangSkill1index1] -- 获取当前技能释放序列
    local Target = self.PlayUUID[1]
    self._proxy:CastActionToTarget(self._uuid,JiGuangSkill1key,Target) -- 向最大仇恨目标按顺序释放常规技能组1
    self.JiGangSkill1index1 = self.JiGangSkill1index1 + 1 -- 每次释放技能加一次序号
    if self.JiGangSkill1index1 > 3 then --序号大于3则返回1
        if self._proxy:CheckBuffByKind(self._uuid, 8053042)  then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053040, 1)
        end
    end

    if self.JiGangSkill1index1 == 2 then
        for i = 1,#self.PlayUUID, 1 do
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071010, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071012, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071013, 1)
        end
    end

end


function XChar8074:JiGuangSkill2() --激光技能组2
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    local JiGuangSkill2key = self._JiGuangSkill2[self.JiGangSkill1index2] -- 获取当前技能释放序列
    local Target = self.PlayUUID[1]
    self._proxy:CastActionToTarget(self._uuid,JiGuangSkill2key,Target) -- 向最大仇恨目标按顺序释放常规技能组1
    self.JiGangSkill1index2 = self.JiGangSkill1index2 + 1 -- 每次释放技能加一次序号
    if self.JiGangSkill1index2 > 2 then --序号大于2则返回1
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053041, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053043, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000466, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1000468, 1)
    end
    if self.JiGangSkill1index2 == 2 then --序号大于3则返回1
        for i = 1,#self.PlayUUID, 1 do
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071010, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071012, 1)
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8071013, 1)
        end
    end

end

function XChar8074:NormalSkill1() --常规技能组1
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    if MaxThreatTarget ~= 0 then
        self.Target = MaxThreatTarget
    else
        self.Target = self.PlayUUID[1] --self.Cuuid
    end
    XLog.Warning("寻找仇恨目标")
    self.Skill1index1 = self.Skill1index1 + 1
--[[    if self.Skill1index1 == 7 and self.ZhaoHuanChuShouSwitch == true then
        self:ChuShouZhaoHuan()
    elseif self.Skill1index1 == 7 and self.ZhaoHuanChuShouSwitch == false then
        self.Skill1index1 = self.Skill1index1 + 1
    end]]
    local NormalSkill1key = self._NormalSkill1[self.Skill1index1] -- 获取当前技能释放序列
    if NormalSkill1key ~= nil then
        self._proxy:CastActionToTarget(self._uuid,NormalSkill1key,self.Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end

    if self.Skill1index1 >= 10 then --序号大于3则返回0
        self.Skill1index1 = 1
        local juli = self._proxy:CheckNpcDistance(self.ChuShouLuuid,self.Target,15)
        if juli == true then
            self:ChuShouSkill1()
        else
            self:ChuShouSkill4()
        end
    end

    if self.Skill1index1 == 4  then
        --[[local juli = self._proxy:CheckNpcDistance(self.ChuShouLuuid,self.Target,15)]]
        self:ChuShouSkill1()
      --[[  if juli == true then
            self:ChuShouSkill1()
        else
            self:ChuShouSkill4()
        end]]
    elseif self.Skill1index1 == 8 then
        --[[local juli = self._proxy:CheckNpcDistance(self.ChuShouLuuid,self.Target,15)]]
        self:ChuShouSkill2()
       --[[ if juli == true then
            self:ChuShouSkill2()
        else
            self:ChuShouSkill4()
        end]]
    end
    --[[   elseif self.Skill1index1 == 9 then
           local juli = self._proxy:CheckNpcDistance(self.ChuShouLuuid,self.Target,15)
           if juli == true then
               self:ChuShouSkill3()
           else
               self:ChuShouSkill4()
           end]]
end

function XChar8074:ODSkill1() --OD技能组
    self.ODSkill1index1 = self.ODSkill1index1 + 1 -- 每次释放技能加一次序号
    local ODSkill1key = self._ODSkill1[self.ODSkill1index1] -- 获取当前技能释放序列
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    if MaxThreatTarget ~= 0 then
        self.Target = MaxThreatTarget
    else
        self.Target = self.PlayUUID[1] --self.Cuuid
    end

    if ODSkill1key ~= nil then
        self._proxy:CastActionToTarget(self._uuid,ODSkill1key,self.Target) -- 向最大仇恨目标按顺序释放常规技能组1
    end

    if self.ODSkill1index1 == 5 then --序号大于3则返回1
        if self.LuoJianKaiGuan == true then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053039, 1)
            self.SkillSwitch = true
        else
            self.ODSkill1index1= self.ODSkill1index1 + 1
        end
    end

    if self.ODSkill1index1 == 7 then
        self:ChuShouSkill1()
    end

    if self.ODSkill1index1 == 11 then
        self:ChuShouSkill1()
    end
    if self.ODSkill1index1 >= 16 then
        self.ODSkill1index1 = 6
    end
end


function XChar8074:ODJiHuo() --OD激活
    local Target = self.PlayUUID[1]
    self._proxy:CastActionToTarget(self._uuid,805323,Target) -- OD激活技能
end


function XChar8074:HeiQiuSkill1() --黑球技能组
    if not self._proxy:CheckActorExist(self.GuangJian_UUID)  then
        return
    end

    local Target = self.PlayUUID[1]
    local HeiQiuSkill1key = self._HeiQiuSkill1[self.Skill1index] -- 获取当前技能释放序列
    self._proxy:CastActionToTarget(self._uuid,HeiQiuSkill1key,self.GuangJian_UUID) -- 向最大仇恨目标按顺序释放常规技能组1
    self.Skill1index = self.Skill1index + 1 -- 每次释放技能加一次序号
    if self.Skill1index > 3 then --序号大于3则返回4
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053014, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053042, 1)
        self.Skill1index = 4
        self.AISwitch = false
        self._proxy:AddTimerTask(12, function()--延迟5秒后，释放影牌技能
            self.JiGangSkill1index1 = 1
            self.AISwitch = true
        end)
    end
end

function XChar8074:FuHua() --千子孵化
    local Target = self.PlayUUID[1]
    local QianZiPos = {x =41.53, y = 9.86, z = 42.92}
    self._proxy:SetNpcFaceToPosition(Target,QianZiPos)
    self._proxy:CastActionToTarget(self._uuid,805321,Target) -- 向最大仇恨目标按顺序释放
    self._proxy:AddTimerTask(1.5, function()--延迟4秒后
        local QianZiCamp= ENpcCampType.Camp2
        local QianZiRota = {x = 0, y = 90, z = 0}
        self.QianZi_UUID = self._proxy:GenerateNpc(self.RenXing, QianZiCamp, QianZiPos, QianZiRota)
    end)
    self.AISwitch = false
    self._proxy:AddTimerTask(12, function()
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053046, 1)
        self.AISwitch = true
    end)
end

function XChar8074:XiShou() --千子吸收
    local GuangJianBornPos = {x =41.53, y = 9.86, z = 42.92}
    local GuangJianBornRota = {x = 0, y = 90, z = 0}
    local Target = self.PlayUUID[1]
--[[    self._proxy:CastActionToTarget(self.QianZi_UUID,805630,Target)
    self._proxy:AddTimerTask(0.5, function()--延迟4秒后
        local QianZiPos = {x =41.53, y = 9.86, z = 42.92}
        local QianZiRota = {x = 0, y = 90, z = 0}
        self._proxy:CastActionToTarget(self.QianZi_UUID,805631,Target) -- 向最大仇恨目标按顺序释放常规技能组1
        self._proxy:AddTimerTask(0.5, function()--延迟4秒后
            self._proxy:SetNpcPosition(self.QianZi_UUID,QianZiPos,true)
        end)
    end)]]
    self._proxy:AddTimerTask(2, function()--延迟4秒后
        self._proxy:CastActionToTarget(self._uuid,805322,Target) -- 向最大仇恨目标按顺序释放
        self._proxy:CastActionToTarget(self.QianZi_UUID,805628,Target) -- 向最大仇恨目标按顺序释放
        if self._proxy:CheckNpc(self.ChuShouLuuid) then
            if not self._proxy:IsNpcDead(self.ChuShouLuuid)then
                self._proxy:ApplyMagic(self._uuid, self.ChuShouLuuid, 8053066, 1)
                self._proxy:ApplyMagic(self._uuid, self.ChuShouLuuid, 80540111, 1)
            end
        end
        if self._proxy:CheckNpc(self.ChuShouRuuid) then
            if not self._proxy:IsNpcDead(self.ChuShouRuuid)then
                self._proxy:ApplyMagic(self._uuid, self.ChuShouRuuid, 8053066, 1)
                self._proxy:ApplyMagic(self._uuid, self.ChuShouRuuid, 80540111, 1)
            end
        end
    end)

    self._proxy:AddTimerTask(7, function()--延迟4秒后
        self._proxy:AbortAction(self.QianZi_UUID, true)
        self._proxy:CastActionToTarget(self.QianZi_UUID,805629,Target) -- 向最大仇恨目标按顺序释放
        self._proxy:ApplyMagic(self._uuid, self.Target, 80560006, 1)
    end)
end

function XChar8074:ChuShouSkill1() --左触手拍打
    self._proxy:CastActionToTarget(self.ChuShouLuuid,805401,self.Target) -- 向最大仇恨目标按顺序释放
    self._proxy:AddTimerTask(7, function()--延迟4秒后，开启技能开关
        self.SkillSwitch2 = true
        self.SkillSwitch = true
    end)
end

function XChar8074:ChuShouSkill2() --左触手横扫
    self._proxy:CastActionToTarget(self.ChuShouLuuid,805402,self.Target) -- 向最大仇恨目标按顺序释放
    self._proxy:AddTimerTask(4, function()--延迟4秒后进行倒地判断
        if self._proxy:CheckBuffByKind(self._uuid, 8054001) then
            self._proxy:AddTimerTask(4, function()--延迟4秒后，开启技能开关
                self.SkillSwitch2 = true
                self.SkillSwitch = true
            end)
        else
            self.SkillSwitch2 = true
            self.SkillSwitch = true
        end
    end)
end

function XChar8074:ChuShouSkill3() --左触手突刺
    self._proxy:CastActionToTarget(self.ChuShouLuuid,805412,self.Target) -- 向最大仇恨目标按顺序释放
    self._proxy:AddTimerTask(5, function()--延迟5秒后进行倒地判断
        if self._proxy:CheckBuffByKind(self._uuid, 8054001) then
            self._proxy:AddTimerTask(4, function()--延迟4秒后，开启技能开关
                self.SkillSwitch2 = true
                self.SkillSwitch = true
            end)
        else
            self.SkillSwitch2 = true
            self.SkillSwitch = true
        end
    end)
end

function XChar8074:ChuShouSkill4() --触手投掷
    self.ChouHenLianXian =  self._proxy:AddLink(self.ChuShouLuuid, self.Target, self.ChuShouLuuid,"HitCase","HitCase", "FxRelinkLianxian")
    self._proxy:ApplyMagic(self.ChuShouLuuid, self.Target, 8057001, 1)
    self._proxy:AddTimerTask(4, function()--延迟4秒后，删除连线特效
        self._proxy:RemoveLink(self.ChuShouLuuid,self.ChouHenLianXian)
    end)
    self._proxy:AbortAction(self.ChuShouLuuid, true)
    self._proxy:CastActionToTarget(self.ChuShouLuuid,805405,self.Target) -- 向最大仇恨目标按顺序释放常规技能组1
    self._proxy:AddTimerTask(6, function()--延迟5秒后，释放影牌技能
        self.SkillSwitch = true
    end)
end

--[[function XChar8074:ChuShouZhaoHuan() --召唤触手1
    local Target = self.PlayUUID[1]
    local monsterCamp= ENpcCampType.Camp2
    local ChuShouBornPos = {x = 36.27, y = 8.749, z = 23}
    local ChuShouBornPos2 = {x = 38.36, y = 8.749, z = 63}
    local ChuShouBornPos3 = {x = 45, y = 8.749, z = 23}
    local monsterBornRota = {x = 0, y = 180, z = 0}
    self.ZhaoHuanChuShouindex = self.ZhaoHuanChuShouindex + 1
    if self.ZhaoHuanChuShouindex == 1 then
        self.ZhaoHuanChuShou1 = self._proxy:GenerateNpc(8057, monsterCamp, ChuShouBornPos, monsterBornRota)
        self._proxy:AddTimerTask(3, function()--延迟4秒后
            self._proxy:LaunchMissile(self._uuid, self.ZhaoHuanChuShou1, 80530215, 80531401,1)
        end)
    elseif self.ZhaoHuanChuShouindex == 2 then
        self.ZhaoHuanChuShou2 = self._proxy:GenerateNpc(8057, monsterCamp, ChuShouBornPos2, monsterBornRota)
        self._proxy:AddTimerTask(3, function()--延迟4秒后
            self._proxy:LaunchMissile(self._uuid, self.ZhaoHuanChuShou2, 80530215, 80531401,1)
        end)
    elseif self.ZhaoHuanChuShouindex > 2  then
        if not self._proxy:CheckActorExist(self.ZhaoHuanChuShou1) == true then
            self.ZhaoHuanChuShou1 = self._proxy:GenerateNpc(8057, monsterCamp, ChuShouBornPos, monsterBornRota)
            self._proxy:AddTimerTask(3, function()--延迟4秒后
                self._proxy:LaunchMissile(self._uuid, self.ZhaoHuanChuShou1, 80530215, 80531401,1)
            end)
        else
            if not self._proxy:CheckActorExist(self.ZhaoHuanChuShou2) == true then
                self.ZhaoHuanChuShou2 = self._proxy:GenerateNpc(8057, monsterCamp, ChuShouBornPos2, monsterBornRota)
                self._proxy:AddTimerTask(3, function()--延迟4秒后
                    self._proxy:LaunchMissile(self._uuid, self.ZhaoHuanChuShou2, 80530215, 80531401,1)
                end)
            else
                if not self._proxy:CheckActorExist(self.ZhaoHuanChuShou3) == true then
                    self.ZhaoHuanChuShou3 = self._proxy:GenerateNpc(8057, monsterCamp, ChuShouBornPos3, monsterBornRota)
                    self._proxy:AddTimerTask(3, function()--延迟4秒后
                        self._proxy:LaunchMissile(self._uuid, self.ZhaoHuanChuShou3, 80530215, 80531401,1)
                    end)
                end
            end
        end
    end
end]]

function XChar8074:ChuShouLianYu() --触手炼狱
    local Target = self.PlayUUID[1]
    for i = 1,#self.PlayUUID, 1 do
        self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8053061, 1)
        self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8053062, 1)
        self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8053063, 1)
    end
    local monsterCamp= ENpcCampType.Camp2
    local ChuShouBornPos1 = {x = 29.48, y = 8.749, z = 25.73}
    local ChuShouBornPos2 = {x = 40.6, y = 8.749, z = 21.46}
    local ChuShouBornPos3 = {x = 55.3, y = 8.749, z = 25.89}
    local ChuShouBornPos4 = {x = 28.45, y = 8.749, z = 61.48}
    local ChuShouBornPos5 = {x = 40.26, y = 8.749, z = 64.96}
    local ChuShouBornPos6 = {x = 55.43, y = 8.749, z = 60.58}
    local monsterBornRota = {x = 0, y = 180, z = 0}
    self.ZhaoHuanChuShou1 = self._proxy:GenerateNpc(self.ChuShouuuid, monsterCamp, ChuShouBornPos1, monsterBornRota)
    self.ZhaoHuanChuShou2 = self._proxy:GenerateNpc(self.ChuShouuuid, monsterCamp, ChuShouBornPos2, monsterBornRota)
    self.ZhaoHuanChuShou3 = self._proxy:GenerateNpc(self.ChuShouuuid, monsterCamp, ChuShouBornPos3, monsterBornRota)
    self.ZhaoHuanChuShou4 = self._proxy:GenerateNpc(self.ChuShouuuid, monsterCamp, ChuShouBornPos4, monsterBornRota)
    self.ZhaoHuanChuShou5 = self._proxy:GenerateNpc(self.ChuShouuuid, monsterCamp, ChuShouBornPos5, monsterBornRota)
    self.ZhaoHuanChuShou6 = self._proxy:GenerateNpc(self.ChuShouuuid, monsterCamp, ChuShouBornPos6, monsterBornRota)
end

function XChar8074:HandleLuaEvent(eventType, eventArgs)
    -- 响应AI开启和停止
    if eventType == EFightLuaEvent.RelinkSetAIActivate then
        if eventArgs.NpcUUid == self._uuid then
            self.AISwitch = eventArgs.IsActivated
        end
    end

    -- 相应AI出生
    if eventType == EFightLuaEvent.RelinkAIBorn then
        if eventArgs.NpcUUid ~= self._uuid then
            return
        end

        -- 播放入场动作
        self._proxy:CastAction(self._uuid, 805333)
    end
end
-----------------------------------------------------------------------------

function XChar8074:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort) -- 技能释放完成时
    if launcherId ~= self._uuid then
        return
    end

    if skillId == 805314 then
        self._proxy:AddTimerTask(4, function()--延迟4秒后
            self.SkillSwitch = true
        end)
    elseif skillId ~= 805322 then
        self.SkillSwitch = true
    elseif skillId == 805322 then
        self.SkillSwitch = false
        self.AISwitch = false -- AI总开关
        self._proxy:AddTimerTask(2, function()--延迟4秒后
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053067, 1)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 80540111, 1)
        end)
    end

    if (skillId == 805301) or (skillId == 805302) or (skillId == 805303) or (skillId == 805304) or (skillId == 805305) or (skillId == 805307) or (skillId == 805314) or (skillId == 805320) or (skillId == 805324)  then
        self.SkillSwitch2 = true
    end

end

---@param dt number @ delta time

---@param eventType number
---@param eventArgs userdata

function XChar8074:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    if buffId == 8053012 then
        local Target = self.PlayUUID[1]
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionToTarget(self._uuid,805306,Target)
    end

    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 8053015 then
        self._proxy:ApplyMagic(self._uuid, self.GuangJian_UUID, 8053015, 1)
    end

    if buffId == 8053028 then
        self._proxy:ApplyMagic(self._uuid, self.GuangJian_UUID, 8053028, 1)
    end

    if buffId == 8053026 then
        self._proxy:ApplyMagic(self._uuid, self.ChuShouLuuid, 8053026, 1)
        self._proxy:ApplyMagic(self._uuid, self.ChuShouLuuid, 8053027, 1)
        self._proxy:ApplyMagic(self._uuid, self.ChuShouRuuid, 8053026, 1)
        self._proxy:ApplyMagic(self._uuid, self.ChuShouRuuid, 8053027, 1)
    end

    if buffId == 8053037 then
        self._proxy:ApplyMagic(self._uuid, self.ChuShouLuuid, 8053037, 1)
        self._proxy:ApplyMagic(self._uuid, self.ChuShouRuuid, 8053037, 1)
    end

    if buffId == 8053064 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053050, 1)
        self._proxy:AddTimerTask(0.1, function()--延迟4秒后
            self._proxy:ApplyMagic(self._uuid, self._uuid, 80540110, 1)
        end)
        self._proxy:AddTimerTask(0.2, function()--延迟4秒后
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8053049, 1)
        end)
    end

end

function XChar8074:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    Base.OnNpcSkillActionKeyframeSendEvent(self, launcher, eventName, skillActionId, keyFrameId, skillId)

    if launcher ~= self._uuid then
        return
    end

    if (eventName == "HeBao") then
        local poissonDiskPoints = self._proxy:PoissonDiscPoints(38,45,15)
        for xIndex = 1, #poissonDiskPoints, 2 do
            local yIndex = xIndex + 1
            local Points = {x = poissonDiskPoints[xIndex]+26.32, y = 9.8, z = poissonDiskPoints[yIndex]+19}
            local ZiDanIndex = (math.random(5))
            if ZiDanIndex == 1 then
                self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80531501,Points, Points,1)
                XLog.Warning(string.format("采样坐标:{%f, %f}",
                        poissonDiskPoints[xIndex],
                        poissonDiskPoints[yIndex]))
            elseif ZiDanIndex == 2 then
                self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80531509,Points, Points,1)
            elseif ZiDanIndex == 3 then
                self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80531510,Points, Points,1)
            elseif ZiDanIndex == 4 then
                self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80531511,Points, Points,1)
            elseif ZiDanIndex == 5 then
                self._proxy:LaunchMissileFromPosToPos(self._uuid, 80530115, 80531512,Points, Points,1)
            end
        end
    end

    if (eventName == "TouHuan2") then
        self.PlayUUID =  self._proxy:GetPlayerNpcList()
        if #self.PlayUUID == 2  then
            local target = self._proxy:GetMinThreatNpc(self._uuid)
            self._proxy:LaunchMissile(self._uuid,target, 80530114, 80530312,1)
        end
    end

    if (eventName == "TouHuan2") then
        self.PlayUUID =  self._proxy:GetPlayerNpcList()
        if #self.PlayUUID == 2  then
            local target = self._proxy:GetMinThreatNpc(self._uuid)
            self._proxy:LaunchMissile(self._uuid,target, 80530114, 80530312,1)
        end
    end

    if (eventName == "TouHuan3") then
        self.PlayUUID =  self._proxy:GetPlayerNpcList()
        if #self.PlayUUID == 1  then
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80530114, 80530312,1)
        end

        if #self.PlayUUID == 2  then
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80530114, 80530312,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[2], 80530114, 80530312,1)
        end

        if #self.PlayUUID == 3  then
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80530114, 80530312,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[2], 80530114, 80530312,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[3], 80530114, 80530312,1)
        end


    end

    if (eventName == "DiCi2") then
        self.PlayUUID =  self._proxy:GetPlayerNpcList()
        if #self.PlayUUID == 2  then
            local target = self._proxy:GetMinThreatNpc(self._uuid)
            self._proxy:LaunchMissile(self._uuid,target, 80530114, 80530509,1)
            self._proxy:LaunchMissile(self._uuid,target, 80530114, 80530510,1)
        end
    end

    if (eventName == "DiCi3") then
        self.PlayUUID =  self._proxy:GetPlayerNpcList()
        if #self.PlayUUID == 1  then
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80530114, 80530509,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80530114, 80530510,1)
        end

        if #self.PlayUUID == 2  then
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80530114, 80530509,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80530114, 80530510,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[2], 80530114, 80530509,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[2], 80530114, 80530510,1)
        end

        if #self.PlayUUID == 3  then
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80530114, 80530509,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80530114, 80530510,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[2], 80530114, 80530509,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[2], 80530114, 80530510,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[3], 80530114, 80530509,1)
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[3], 80530114, 80530510,1)
        end
    end


    if (eventName == "Pingmu") then
        self.PlayUUID = self._proxy:GetPlayerNpcList()
        for i = 1,#self.PlayUUID, 1 do
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8053057, 1)
        end
    end

    if (eventName == "PingmuShanBai") then
        self.PlayUUID = self._proxy:GetPlayerNpcList()
        for i = 1,#self.PlayUUID, 1 do
            self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8053058, 1)
        end
    end

    if (eventName == "ChuShouZhaoHuan") then
        self:ChuShouLianYu()
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053023, 1)
        self._proxy:ApplyMagic(self._uuid, self.ChuShouLuuid, 8053023, 1)
        self._proxy:ApplyMagic(self._uuid, self.ChuShouRuuid, 8053023, 1)
    end


    if (eventName == "ChuShouBiaoJi") then
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou1) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou1, 8054004, 1)
        end
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou2) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou2,8054004,1)
        end
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou3) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou3, 8054004, 1)
        end
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou4) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou4, 8054004, 1)
        end
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou5) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou5, 8054004, 1)
        end
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou6) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou6, 8054004, 1)
        end
    end


    if (eventName == "ChuShouSiWang") then
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou1) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou1, 80540111, 1)
        end
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou2) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou2, 80540111, 1)
        end
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou3) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou3, 80540111, 1)
        end
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou4) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou4, 80540111, 1)
        end
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou5) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou5, 80540111, 1)
        end
        if self._proxy:IsNpcDead(self.ZhaoHuanChuShou6) == false then
            self._proxy:ApplyMagic(self._uuid, self.ZhaoHuanChuShou6, 80540111, 1)
        end
        XLog.Warning("本体现身")
        self._proxy:CastActionToTarget(self.ChuShouLuuid,805415,self._uuid)
        self._proxy:CastActionToTarget(self.ChuShouRuuid,805503,self._uuid)
    end

    if (eventName == "ChuShouYinCang") then
        self._proxy:CastAction(self.ChuShouLuuid,805414)
        self._proxy:CastAction(self.ChuShouRuuid,805502)
    end


    if (eventName == "XiaZa") then
        for i = 1,#self.PlayUUID, 1 do
            self._proxy:LaunchMissile(self._uuid,self.PlayUUID[i], 80531204, 80530312,1)
        end
    end

end

function XChar8074:OnNpcOverDriveFull(targetUUID) -- OD已满事件
    if targetUUID ~= self._uuid then
        return
    end

    if self.ODindex < 1 then
        self.ODindex = self.ODindex + 1
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053035, 1)
    end

end

function XChar8074:OnNpcODBreakBefore(targetUUID)  -- Break前事件
    if targetUUID ~= self._uuid then
        return
    end
    local Target = self.PlayUUID[1]
    self._proxy:ApplyMagic(self._uuid, self._uuid, 8053037, 1)
    self._proxy:ApplyMagic(self._uuid, self._uuid, 8053051, 1)
    self.AISwitch = false
    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastActionToTarget(self._uuid,805334,Target)
    self._proxy:AddTimerTask(2.1, function()--延迟4秒后
        self._proxy:CastActionToTarget(self._uuid,805335,Target)
    end)
    --时停,碎屏特效,镜头拉近
    for i = 1,#self.PlayUUID, 1 do
        self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8005302, 1)
        self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8005201, 1)
        self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8005401, 1)
        self._proxy:ApplyMagic(self._uuid, self.PlayUUID[i], 8005401, 1)
    end

end


function XChar8074:OnNpcODExitBreakAfter(targetUUID) -- 退出Break后
    if targetUUID ~= self._uuid then
        return
    end
    local Target = self.PlayUUID[1]
    self.AISwitch = true
    self._proxy:ApplyMagic(self._uuid, Target, 8053038, 1)
    self._proxy:CastActionToTarget(self._uuid,805336,Target)
end

function XChar8074:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillActionId, magicTags)
    if targetId ~= self._uuid then
        return
    end

    local SelfHp = self._proxy:GetNpcAttribValue(self._uuid,0) -- 检测当前自身血量
    if SelfHp == 1 then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053044, 1)
    end

    if magicId == 10519201 and self._proxy:CheckBuffByKind(self._uuid, 8005901) then
        local Target = self.PlayUUID[1]
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionToTarget(self._uuid,805330,Target)
    end

end

function XChar8074:OnNpcBrokenAfter(launcherUUID, targetUUID, magicId)  --破韧
    local Target = self.PlayUUID[1]
    XLog.Warning("破韧成功")
    self._proxy:ApplyMagic(self._uuid, self._uuid, 1000494, 1)
    self.AISwitch = false
    self._proxy:AbortAction(self._uuid, true)
    self._proxy:CastActionToTarget(self._uuid,805331,Target)
    --[[self._proxy:LaunchMissile(self._uuid,self.PlayUUID[1], 80530115, 80530601,1)]]
    self._proxy:AddTimerTask(3, function()
        XLog.Warning("破韧后恢复")
        self.AISwitch = true
        self.SkillSwitch = true
    end)
    self._proxy:AddTimerTask(5, function()--延迟4秒后
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8053068, 1)
    end)
end

return XChar8074