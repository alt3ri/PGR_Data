local XTheatre6CharBase = require("Gameplay/Theatre6/XTheatre6CharBase")

---肉鸽6神威脚本
---@class XChar1027:XTheatre6CharBase
local XChar1027 = XDlcScriptManager.RegCharScript(1027, "XChar1027", XTheatre6CharBase)

---@class XChar1027.State:XTheatre6State
---@field _owner XChar1027
---@field _stateMachine XChar1027.StateMachine

---@class XChar1027.State.Wrestle:XTheatre6CharBase.State.Wrestle
---@field WrestleSkillIdLeft integer 拼刀start动作 左
---@field WrestleSkillIdRight integer 拼刀start动作 右
---@field WrestleSkillIdLeftCountinue integer 拼刀僵持动作 左
---@field WrestleSkillIdRightCountinue integer 拼刀僵持动作 右
---@field PindaoStart2LCamera integer 拼刀start冲刺特写镜头动画buff 左
---@field PindaoStart2RCamera integer 拼刀start冲刺特写镜头动画buff 右
---@field SecondWrestleReset integer 二次拼刀位置重置动作

---@class XChar1027.State.Dodge:XTheatre6CharBase.State.Dodge
---@field DodgeSkillId integer 超算受身动作
---@field SucceedActionId integer 超算受身成功反击

---@class XChar1027.State.Block:XTheatre6CharBase.State.Block
---@field Actions integer[] 格挡动作列表

---@class XChar1027.StateMachine:XTheatre6StateMachine

local StateMachine, States = XTheatre6CharBase:CreateClasses("XChar1027")

XChar1027.StateMachine = StateMachine --[[@as XChar1027.StateMachine]]
XChar1027.States = States --[[@as table<string|integer, XChar1027.State>]]

local wrestleState = States.Wrestle --[[@as XChar1027.State.Wrestle]]
wrestleState.WrestleSkillIdLeft = 1027001 -- 拼刀start动作 左 (fighter1
wrestleState.WrestleSkillIdRight = 1027005 -- 拼刀start动作 右 (fighter2
wrestleState.WrestleSkillIdLeftCountinue = 1027006 -- 拼刀僵持动作 左 (fighter1
wrestleState.WrestleSkillIdRightCountinue = 1027007 -- 拼刀僵持动作 右 (fighter2
wrestleState.PindaoStart2LCamera = 10275134 -- 拼刀start冲刺特写镜头动画buff 左(fighter1
wrestleState.PindaoStart2RCamera = 10275135 -- 拼刀start冲刺特写镜头动画buff 右(fighter2
wrestleState.SucceedActionId = 1027002 -- 拼刀成功动作
wrestleState.SecondWrestleReset = 1027010 -- 二次拼刀位置重置动作

local dodgeState = States.Dodge --[[@as XChar1027.State.Dodge]]
dodgeState.DodgeSkillId = 1027003  -- 超算受身动作
dodgeState.SucceedActionId = 1027004 --超算受身成功反击

local blockState = States.Block --[[@as XChar1027.State.Block]]
blockState.Actions = {1027009} -- 格挡动作   

function XChar1027:_BaseInit()
    XTheatre6CharBase._BaseInit(self)
    self._skill1027301MissileUUIDs = {}
    self._isTrackingSkill1027301Missile = false
    self._needRemoveSkill1027301Missile = false
end

function XChar1027:InitEventCallBackRegister()
    --神威独特注册脚本
    XTheatre6CharBase.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcSkillActionEnd, self._uuid)
    self._proxy:RegisterEvent(EWorldEvent.MissileCreate)
    self._proxy:RegisterEvent(EWorldEvent.MissileDead)
end

---@param eventType number
---@param eventArgs userdata
function XChar1027:HandleEvent(eventType, eventArgs)
    XTheatre6CharBase.HandleEvent(self, eventType, eventArgs)
end

function XChar1027:IsSelfSkill1027301(skillId, uuid)
    return uuid == self._uuid and skillId == 1027301
end

-- 技能1027301结束时，移除无敌类Buff 10275124。
function XChar1027:RemoveEndBuff(skillId, uuid)
    if not self:IsSelfSkill1027301(skillId, uuid) then
        return
    end

    self._proxy:RemoveBuff(self._uuid, 10275124)
end

-- 技能1027301开始后，记录子弹模板102710505生成的实例UUID。
-- 子弹配置ID不是实例UUID，清理时优先使用MissileCreate记录到的UUID。
function XChar1027:StartMissileTrack(skillId, uuid)
    if not self:IsSelfSkill1027301(skillId, uuid) then
        return
    end

    self._skill1027301MissileUUIDs = {}
    self._isTrackingSkill1027301Missile = true
    self._needRemoveSkill1027301Missile = false
    XLog.Warning("神威 技能1027301开始，记录子弹模板102710505实例")
end

-- 技能1027301结束后标记清理；真正删除等动作完成。
function XChar1027:EndMissileTrack(skillId, uuid)
    if not self:IsSelfSkill1027301(skillId, uuid) then
        return
    end

    self._isTrackingSkill1027301Missile = false
    self._needRemoveSkill1027301Missile = true
    self:TryClearMissile()
end

-- 等CheckNpcCurActionIsDone确认动作真正结束后，再清理102710505子弹。
function XChar1027:TryClearMissile()
    if not self._needRemoveSkill1027301Missile then
        return
    end
    if not self._proxy:CheckNpcCurActionIsDone(self._uuid) then
        return
    end

    for missileUUID, _ in pairs(self._skill1027301MissileUUIDs) do
        self._proxy:DestroyMissileByUUID(missileUUID)
    end
    self._skill1027301MissileUUIDs = {}
    self._needRemoveSkill1027301Missile = false
    self._proxy:RemoveCurrentNpcMissileByTemplateId(102710505)
    XLog.Warning("神威 技能1027301动作完成，清理子弹模板102710505")
end

-- 技能1027301释放时，先移除二阶段常驻特效10277108，避免表现残留。
function XChar1027:RemovePhase2FxOnCast(skillId, uuid)
    if not self:IsSelfSkill1027301(skillId, uuid) then
        return false
    end

    self._proxy:RemoveBuff(self._uuid, 10277108)
    XLog.Warning("神威 释放技能1027301，移除二阶段常驻特效Buff 10277108")
    return true
end

-- 1027001是二阶段，1027002是一阶段，10277108是二阶段常驻特效。
function XChar1027:RefreshPhaseFx(reason)
    local stateBuff = self._pendingPhaseBuff
    if not stateBuff then
        if self._proxy:CheckBuffByKind(self._uuid, 1027002) then
            stateBuff = 1027002
        elseif self._proxy:CheckBuffByKind(self._uuid, 1027001) then
            stateBuff = 1027001
        end
    end

    if stateBuff == 1027002 then
        XLog.Warning("神威 二阶段常驻特效刷新: " .. tostring(reason) .. " 检测到一阶段Buff 1027002，移除二阶段常驻特效Buff 10277108")
        self._proxy:RemoveBuff(self._uuid, 10277108)
        self._pendingPhaseBuff = nil
        self._needRefreshSecondPhaseLoopEffect = false
        return
    end

    if stateBuff == 1027001 then
        XLog.Warning("神威 二阶段常驻特效刷新: " .. tostring(reason) .. " 检测到二阶段Buff 1027001")
        if not self._proxy:CheckBuffByKind(self._uuid, 10277108) then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 10277108, 1)
            XLog.Warning("神威 二阶段常驻特效刷新: " .. tostring(reason) .. " 已添加二阶段常驻特效Buff 10277108")
        end
    end

    self._pendingPhaseBuff = nil
    self._needRefreshSecondPhaseLoopEffect = false
end

function XChar1027:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    XTheatre6CharBase.OnNpcAddBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._uuid then
        return
    end
    if buffId == 1027001 then
        XLog.Warning("神威 添加Buff事件: 检测到二阶段Buff 1027001")
        self._pendingPhaseBuff = 1027001
        self._needRefreshSecondPhaseLoopEffect = true
    end
    if buffId == 1027002 then
        XLog.Warning("神威 添加Buff事件: 检测到一阶段Buff 1027002")
        self._pendingPhaseBuff = 1027002
        self._needRefreshSecondPhaseLoopEffect = true
    end
end

function XChar1027:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    XTheatre6CharBase.OnNpcCastActionAfterEvent(self, skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then
        return
    end

    XLog.Warning("神威 技能释放检测: skillId=" .. tostring(skillId))
    self:StartMissileTrack(skillId, launcherId)
    if self:RemovePhase2FxOnCast(skillId, launcherId) then
        return
    end
    self:RefreshPhaseFx("SkillStart")
end

function XChar1027:OnLuaSkillStart(eventArgs)
    XTheatre6CharBase.OnLuaSkillStart(self, eventArgs)
    self:RemovePhase2FxOnCast(eventArgs._skillId, eventArgs._launcherUUID)
end

function XChar1027:OnMissileCreateEvent(missileUUID)
    XTheatre6CharBase.OnMissileCreateEvent(self, missileUUID)
    if not self._isTrackingSkill1027301Missile then
        return
    end

    local success, templateId = self._proxy:MissileUUIDToTemplateId(missileUUID)
    if not success then
        return
    end
    if templateId ~= 102710505 then
        return
    end

    self._skill1027301MissileUUIDs[missileUUID] = true
    XLog.Warning("神威 技能1027301记录子弹实例: " .. tostring(missileUUID))
end

function XChar1027:OnMissileDeadEvent(missileUUID)
    XTheatre6CharBase.OnMissileDeadEvent(self, missileUUID)
    if self._skill1027301MissileUUIDs then
        self._skill1027301MissileUUIDs[missileUUID] = nil
    end
end

function XChar1027:OnLuaSkillEnd(eventArgs)
    XTheatre6CharBase.OnLuaSkillEnd(self, eventArgs)
    self:RemoveEndBuff(eventArgs._skillId, eventArgs._launcherUUID)
    self:EndMissileTrack(eventArgs._skillId, eventArgs._launcherUUID)
end

function XChar1027:OnNpcSkillActionEnd(sourceUUID, skillId, skillActionId, isAbort)
    XTheatre6CharBase.OnNpcSkillActionEnd(self, sourceUUID, skillId, skillActionId, isAbort)
    self:RemoveEndBuff(skillId, sourceUUID)
    self:EndMissileTrack(skillId, sourceUUID)
    if sourceUUID ~= self._uuid then
        return
    end

    self:RefreshPhaseFx("SkillEnd")
end

function XChar1027:Update(dt)
    XTheatre6CharBase.Update(self, dt)
    self:TryClearMissile()
end

function XChar1027:Terminate()
    self._proxy:UnregisterEventByTarget(EWorldEvent.NpcSkillActionEnd, self._uuid)
    self._proxy:UnregisterEvent(EWorldEvent.MissileCreate)
    self._proxy:UnregisterEvent(EWorldEvent.MissileDead)
    XTheatre6CharBase.Terminate(self)
end


---关键帧事件：切换空中状态、添加镜头Magic。
---相关技能：1027201、1027506。
function XChar1027:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    XTheatre6CharBase.OnNpcSkillActionKeyframeSendEvent(self, launcher, eventName, skillActionId, keyFrameId, skillId)
    if eventName == "ChangeAirStatus" then
        self._proxy:SetNpcGravity(self._uuid, 0, 0)
        return
    end

    if eventName == "EndAirStatus" then
        self._proxy:SetNpcGravity(self._uuid, -50, -15)
        return
    end

    local magicMap = {
        CameraChangeOne = { 10275119, 10275120 },
        CameraChangeTwo = { 10275121, 10275122 },
        SkillCameraOne = { 10275130, 10275131 },
        SkillCameraTwo = { 10275128, 10275129 },
    }

    local magicIds = magicMap[eventName]
    if not magicIds then
        return
    end

    for _, magicId in ipairs(magicIds) do
        self._proxy:ApplyMagic(self._uuid, self._uuid, magicId, 0)
    end
end

return XChar1027
