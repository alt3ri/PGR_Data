local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---首席指挥官角色脚本
---@class XChar8057 : XFightBase
local XChar8057 = XDlcScriptManager.RegCharScript(8057, "XChar8057", Base)
--region 函数: 脚本生命周期

function XChar8057:Init()
    Base.Init(self)
    self.Move = true
    self.Attack = true
    self.Attack2 = false
    self.YuJing = true
    self.YuJingCiShu = 0
    self.TanDaoCiShu = 0
    self.Skill1index1 = 0
    self.PlayUUID =  self._proxy:GetPlayerNpcList()
    self.Target = nil
    self._proxy:SetNpcIgnoreObstacle(self._uuid, 13 , true)
    self._proxy:LaunchMissile(self._uuid, self._uuid, 80530115, 80530511,1)
     -- self:ClassCheck()
    self._NormalSkill1 = {
        [1] = 805402,
        [2] = 805412,
        [3] = 805402,
        [4] = nil,
    }

end

function XChar8057:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- 添加buff
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore) --注册技能释放前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter) --注册技能释放后前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcExitAction) -- 技能释放完成事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionKeyframeSendEvent, self._uuid) --注册技能事件

    -- 指定目标事件绑定
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore, self._uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcBeforeTriggerCounter, self._uuid)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcAfterTriggerCounter, self._uuid)

    -- 注册自定义lua事件
    self._proxy:RegisterLuaEvent(EFightLuaEvent.RelinkSetAIActivate)

end

function XChar8057:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8057:Update(dt)
    Base.Update(self, dt)

    if not self.Move == true then
        return
    end

    if  self.Attack == true and self._proxy:CheckBuffByKind(self._uuid, 8053025)then
        self.Attack = false
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionToTarget(self._uuid,805411,self.PlayUUID[1])
        self._proxy:AddTimerTask(6, function()--延迟5秒后，释放影牌技能
            self.Attack2 = true
        end)
    end

    if self.YuJing == true and self.YuJingCiShu < 4 then
        self.YuJing = false
        self._proxy:AddTimerTask(1, function()--延迟1秒后
            self._proxy:LaunchMissile(self._uuid, self._uuid, 80530115, 80530511,1)
            self.YuJing = true
            self.YuJingCiShu = self.YuJingCiShu + 1
        end)
    end


    if self.Attack2 == true then
        self.Attack2 = false
        self:NormalSkill1()
    end


   --[[ if  self.Attack == true then
        self.Attack = false
        self._proxy:AddTimerTask(6, function()--延迟0.6秒后，释放影牌技能
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,805410,33)
        end)
        self._proxy:AddTimerTask(12, function()--延迟0.6秒后，释放影牌技能
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,805410,33)
        end)
        self._proxy:AddTimerTask(18, function()--延迟0.6秒后，释放影牌技能
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,805403,33)
            self.Attack2 = true
        end)
    end

    if  self.Attack2 == true then
        self.Attack2 = false
        self._proxy:AddTimerTask(6, function()--延迟0.6秒后，释放影牌技能
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,805403,33)
            self.Attack2 = true
        end)
    end]]
end

function XChar8057:NormalSkill1() --常规技能组1
    local MaxThreatTarget = self._proxy:GetMaxThreatNpc(self._uuid)  -- 获取最大仇恨目标
    self.Skill1index1 = self.Skill1index1 + 1 -- 每次释放技能加一次序号
    XLog.Warning("触手技能编号"..self.Skill1index1)
    local NormalSkill1key = self._NormalSkill1[self.Skill1index1] -- 获取当前技能释放序列
    if MaxThreatTarget ~= 0 then
        self.Target = MaxThreatTarget
    else
        self.Target = self.PlayUUID[1] --self.Cuuid
    end

    if NormalSkill1key ~= nil then
        local juli = self._proxy:CheckNpcDistance(self._uuid,self.Target,15)
        XLog.Warning(juli)
        if juli == true then
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,NormalSkill1key,self.Target) -- 向最大仇恨目标按顺序释放常规技能组1
            self._proxy:AddTimerTask(8, function()--延迟5秒后，释放影牌技能
                self.Attack2 = true
            end)
        else
            self.ChouHenLianXian =  self._proxy:AddLink(self._uuid, self.Target, self._uuid,"HitCase","HitCase", "FxRelinkLianxian")
            self._proxy:ApplyMagic(self._uuid, self.Target, 8057001, 1)
            self._proxy:AddTimerTask(4, function()--延迟4秒后，删除连线特效
                self._proxy:RemoveLink(self._uuid,self.ChouHenLianXian)
            end)
            self._proxy:AbortAction(self._uuid, true)
            self._proxy:CastActionToTarget(self._uuid,805405,self.Target) -- 向最大仇恨目标按顺序释放常规技能组1
            self._proxy:AddTimerTask(8, function()--延迟5秒后，释放影牌技能
                self.Attack2 = true
            end)
        end
    end

    if self.Skill1index1 >= 4 then --序号大于4则返回0
        if self.TanDaoCiShu < 1  then
            self._proxy:CastActionToTarget(self._uuid,805403,self.Target)
            self.TanDaoCiShu = 0
            self._proxy:AddTimerTask(7, function()--延迟5秒后，释放影牌技能
                self.Attack2 = true
                self.Skill1index1 = 0
            end)
        else
            self.Attack2 = true
            self.Skill1index1 = 0
            self.TanDaoCiShu = 0
        end
    end
end

function XChar8057:ClassCheck() --按职业区分目标
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

end


function XChar8057:OnNpcCastActionBeforeEvent(SkillId, LauncherId, TargetId, TargetSceneObjId, IsAbort)

end

function XChar8057:OnNpcBeforeTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    Base.OnNpcBeforeTriggerCounter(self, triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    -- 非技能目标不能弹刀
    XLog.Warning("打印")
    self._proxy:AbortAction(self._uuid, true)
    self.TanDaoCiShu = self.TanDaoCiShu+1
    self._proxy:CastActionToTarget(self._uuid,805409,self.Target)
end

--[[
function XChar8057:OnNpcExitActionEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort) -- 技能释放完成时
    if launcherId ~= self._uuid then
        return
    end

    self.Attack2 = true
end]]

---@param dt number @ delta time

---@param eventType number
---@param eventArgs userdata

function XChar8057:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)

    if buffId == 8053033 then
        self._proxy:NpcDie(self._uuid)
    end
end






return XChar8057