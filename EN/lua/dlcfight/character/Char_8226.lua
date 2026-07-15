local XTheatre6CharBase = require("Gameplay/Theatre6/XTheatre6CharBase")

---肉鸽6囚徒脚本
---@class XChar8226:XTheatre6CharBase
local XChar8226 = XDlcScriptManager.RegCharScript(8226, "XChar8226", XTheatre6CharBase)

---@class XChar8226.State:XTheatre6State
---@field _owner XChar8226
---@field _stateMachine XChar8226.StateMachine

---@class XChar8226.StateMachine:XTheatre6StateMachine

--注册状态机
local StateMachine, States = XTheatre6CharBase:CreateClasses("XChar8226")

XChar8226.StateMachine = StateMachine --[[@as XChar8226.StateMachine]]
XChar8226.States = States --[[@as table<string|integer, XChar8226.State>]]

--注册拼刀、超算技能
-- States.Wrestle.WrestleSkillIdLeft = 1025001 -- 拼刀start动作 左 (fighter1 怪物不需要
States.Wrestle.WrestleSkillIdRight = 8226012 -- 拼刀start动作 右 (fighter2
-- States.Wrestle.WrestleSkillIdLeftCountinue = 1025006 -- 拼刀僵持动作 左 (fighter1 怪物不需要
States.Wrestle.WrestleSkillIdRightCountinue = 8226013 -- 拼刀僵持动作 右 (fighter2
-- States.Wrestle.PindaoStart2LCamera = 10250102 -- 拼刀start冲刺特写镜头动画buff 左(fighter1 怪物不需要
States.Wrestle.PindaoStart2RCamera = 8226015 -- 拼刀start冲刺特写镜头动画buff 右(fighter2
States.Wrestle.SucceedActionId = 8226014 -- 拼刀成功动作
States.Wrestle.SecondWrestleReset = 8226019 -- 二次拼刀位置重置动作
States.Dodge.DodgeSkillId = 8226015  -- 超算受身动作
States.Dodge.SucceedActionId = 8226016 --超算受身成功反击
-- States.Block.ActionId = 1025009 -- 格挡动作 (怪物不需要

function XChar8226:_BaseInit()
    XTheatre6CharBase._BaseInit(self)
    self._skillTimer = 0 
    self._insertSkillTriggerTimer = 6 + math.random(10)
end
--注册脚本事件
function XChar8226:InitEventCallBackRegister()
    --囚徒独特注册脚本
    XTheatre6CharBase.InitEventCallBackRegister(self)
    -- self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
end
--中转脚本事件
---@param eventType number
---@param eventArgs userdata
function XChar8226:HandleEvent(eventType, eventArgs)
    XTheatre6CharBase.HandleEvent(self, eventType, eventArgs)
end

-- function XChar8226:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
--     XTheatre6CharBase.OnNpcAddBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
--     --如果不是自身加buff返回
--     if npcUUID ~= self._uuid then
--         return
--     end
--     --动作属于BaseLayer
--     if buffId == 1025001 then
--         XLog.Warning("切换状态机为0")
--         self._proxy:SetNpcAnimationLayer(self._uuid, 0)
--     end
--     --动作属于Layer1
--     if buffId == 1025002 then
--         XLog.Warning("切换状态机为1")
--         self._proxy:SetNpcAnimationLayer(self._uuid, 1)
--     end
-- end

function XChar8226:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    XTheatre6CharBase.OnNpcSkillActionKeyframeSendEvent(self, launcher, eventName, skillActionId, keyFrameId, skillId)
    if eventName == "Wrestle" then
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1025003)--添加去时缓buff
        self._proxy:AbortAction(self._uuid, true)
        self._proxy:CastActionToTarget(self._uuid, 1025002, self._enemyUUID)
    end
end

-- function XChar8226:OnNpcCastActionAfterEvent(skillActionId, launcherId, targetId, targetSceneObjId, isAbort)
--     if launcherId ~= self._uuid then 
--         return
--     end
--     XLog.Warning("释放技能" ..self._skillTimer)
--     self._skillTimer = self._skillTimer + 1
--     if self._skillTimer > self._insertSkillTriggerTimer then
--         -- self._proxy:AbortAction(self._uuid, true)
--         self._level:RequestInsertSkill(self._uuid,46)
--         self._skillTimer = 0
--         self._insertSkillTriggerTimer = 6 + math.random(10)
--     end
-- end

return XChar8226