local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---首席指挥官角色脚本
---@class XChar8071 : XFightBase
local XChar8071 = XDlcScriptManager.RegCharScript(8071, "XChar8071", Base)
--region 函数: 脚本生命周期

function XChar8071:Init()
    Base.Init(self)
    self.Move = true
    self.Attack = true
    self.Attack2 = true
    self.Attack3 = true
    self.PlayUUID =  self._proxy:GetPlayerNpcList()
    self.Target = self.PlayUUID[1] --self.Cuuid
    self.targetPos = self._proxy:GetNpcPosition(self._uuid)
    self.Npcuuid = self._proxy:GetNpcList()
    for xIndex = 1, #self.Npcuuid, 1 do
        if self._proxy:CheckBuffByKind(self.Npcuuid[xIndex], 80560011) then
            self.QianZiUUID = self.Npcuuid[xIndex]
        end
    end
 --[[   self._proxy:LaunchMissile(self.QianZiUUID, self._uuid, 80710001, 80710001,1)
    self._proxy:AddTimerTask(2, function()--延迟5秒后，释放影牌技能
        if not self._proxy:CheckBuffByKind(self.QianZiUUID, 80560018) then
            local chushouzidan, var1 =  self._proxy:LaunchMissile(self.QianZiUUID, self._uuid, 80710001, 80710002,1)
            self.chushouzidan1 = var1
        end
    end)
    self._proxy:AddTimerTask(8, function()--延迟5秒后，释放影牌技能
        if not self._proxy:CheckBuffByKind(self.QianZiUUID, 80560018) then
            self._proxy:DestroyMissileByUUID(self.chushouzidan1)
            local chushouzidan2 =  self._proxy:LaunchMissile(self.QianZiUUID, self._uuid, 80710001, 80710006,1)
            self._proxy:AddTimerTask(30, function()--延迟5秒后，释放影牌技能
                self._proxy:NpcDie(self._uuid)
            end)
        end
    end)]]

    self._proxy:AddTimerTask(42, function()
        self._proxy:DestroyNpc(self._uuid)
    end)

end

function XChar8071:InitEventCallBackRegister()
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

function XChar8071:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8071:Update(dt)
    Base.Update(self, dt)

    if not self.Move == true then
        return
    end

    if  self.Attack == true and self._proxy:CheckBuffByKind(self._uuid, 8071004) then-- 出生
        self.Attack = false
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionToTarget(self._uuid,805413,self.Target)
        self._proxy:AddTimerTask(9.7, function()
            self._proxy:NpcDie(self._uuid)
        end)
    end

   --[[ if  self.Attack2 == true and self._proxy:CheckBuffByKind(self._uuid, 8071005)then -- 攻击
        self.Attack2 = false
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionToTarget(self._uuid,805401,self.Target)
        self._proxy:AddTimerTask(4, function()--延迟5秒后，释放影牌技能
            self.Attack2 = true
        end)
    end

    if  self.Attack3 == true and self._proxy:CheckBuffByKind(self.QianZiUUID, 80560018) then -- 攻击
        self.Attack3 = false
        self._proxy:DestroyMissileByUUID(self.chushouzidan1)
        local chushouzidan3 =  self._proxy:LaunchMissile(self.QianZiUUID, self._uuid, 80710001, 80710003,1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 8071009, 1)
        self._proxy:AddTimerTask(30, function()--延迟5秒后，释放影牌技能
            self._proxy:NpcDie(self._uuid)
        end)
    end]]

--[[    if self.Attack2 == true then
        self.Attack2 = false
        self:NormalSkill1()
    end]]


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

--[[
function XChar8071:NormalSkill1() --常规技能组1
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

]]


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

function XChar8071:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end

    if buffId == 80710005 then
        self.Attack = true
    end
end


return XChar8071