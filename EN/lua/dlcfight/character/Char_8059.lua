local Base = require("Common/XFightBase")
local XNpcFollowController = require("Character/Common/XNpcFollowController")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---首席指挥官角色脚本
---@class XChar8059 : XFightBase
local XChar8059 = XDlcScriptManager.RegCharScript(8059, "XChar8059", Base)
--region 函数: 脚本生命周期

function XChar8059:Init() --初始化
    Base.Init(self)
    self.PlayUUID =  self._proxy:GetPlayerNpcList()
    self.QiDong = false
    self._proxy:AddTimerTask(2, function()
        self._proxy:AbortAction(self._uuid, true)
        self.QiDong = true
    end)

    self._proxy:AddTimerTask(5, function()
        if self._proxy:IsNpcDead(self._uuid) == true then
            return
        end
        self._proxy:LaunchMissile(self._uuid, self._uuid, 80531204, 80590001,1)
        self._proxy:NpcStopMove(self._uuid)
        self._proxy:AddTimerTask(2, function()
            self.QiDong = true
        end)
    end)

    self._proxy:AddTimerTask(12, function()
        if self._proxy:IsNpcDead(self._uuid) == true then
            return
        end
        self._proxy:LaunchMissile(self._uuid, self._uuid, 80531204, 80590001,1)
        self._proxy:NpcStopMove(self._uuid)
        self._proxy:AddTimerTask(2, function()
            self.QiDong = true
            self._proxy:ApplyMagic(self._uuid, self._uuid, 8071002, 1)
        end)
    end)

    self._proxy:AddTimerTask(19, function()
        if self._proxy:IsNpcDead(self._uuid) == true then
            return
        end
        self._proxy:LaunchMissile(self._uuid,  self._uuid, 80531204, 80590004,1)
        self._proxy:NpcStopMove(self._uuid)
        self._proxy:AddTimerTask(1.6, function()
            self._proxy:NpcDie(self._uuid)
        end)
    end)
end


function XChar8059:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- 添加buff
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCounterSuccess,self._uuid) --注册反击
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageBefore,self._uuid) --注册伤害前事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --注册伤害事件
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionBefore) --注册技能释放事件
end

function XChar8059:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8059:Update(dt)
    Base.Update(self, dt)
    if self.QiDong == true then
        self.QiDong = false
        XLog.Warning("移动")
        local Playeruuid1 = self.PlayUUID[1]
        local ShuiQiuPos = {x = 40.87, y = 9.86, z = 43.03}
        self._proxy:NpcMoveTo(self._uuid,ShuiQiuPos,ENpcMoveType.Walk)
    end
end

function XChar8059:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillActionId, magicTags)
    if targetId ~= self._uuid then
        return
    end

    self._proxy:ApplyMagic(self._uuid, self._uuid, 8059003, 1)

end

    ---@param dt number @ delta time

    ---@param eventType number
    ---@param eventArgs userdata

return XChar8059