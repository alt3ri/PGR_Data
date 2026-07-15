local XTheatre6CharBase = require("Gameplay/Theatre6/XTheatre6CharBase")

---肉鸽6鬼白毛脚本
---@class XChar1026:XTheatre6CharBase
local XChar1026 = XDlcScriptManager.RegCharScript(1026, "XChar1026", XTheatre6CharBase)

---@class XChar1026.State:XTheatre6State
---@field _owner XChar1026
---@field _stateMachine XChar1026.StateMachine

---@class XChar1026.StateMachine:XTheatre6StateMachine

local StateMachine, States = XTheatre6CharBase:CreateClasses("XChar1026")

XChar1026.StateMachine = StateMachine --[[@as XChar1026.StateMachine]]
XChar1026.States = States --[[@as table<string|integer, XChar1026.State>]]

States.Wrestle.WrestleSkillIdLeft = 1026001 -- 拼刀start动作 左 (fighter1
States.Wrestle.WrestleSkillIdRight = 1026005 -- 拼刀start动作 右 (fighter2
States.Wrestle.WrestleSkillIdLeftCountinue = 1026006 -- 拼刀僵持动作 左 (fighter1
States.Wrestle.WrestleSkillIdRightCountinue = 1026007 -- 拼刀僵持动作 右 (fighter2
States.Wrestle.PindaoStart2LCamera = 10260102 -- 拼刀start冲刺特写镜头动画buff 左(fighter1
States.Wrestle.PindaoStart2RCamera = 10260103 -- 拼刀start冲刺特写镜头动画buff 右(fighter2
States.Wrestle.SucceedActionId = 1026002 -- 拼刀成功动作
States.Wrestle.SecondWrestleReset = 1026010 -- 二次拼刀位置重置动作
States.Dodge.DodgeSkillId = 1026003  -- 超算受身动作
States.Dodge.SucceedActionId = 1026004 --超算受身成功反击
States.Block.Actions = {1026008, 1026009} -- 格挡动作

function XChar1026:_BaseInit()
    XTheatre6CharBase._BaseInit(self)
    self._skillTimer = 0
    self._insertSkillTriggerTimer = 6 + math.random(10)

end

function XChar1026:InitEventCallBackRegister()
    --维罗妮卡独特注册脚本
    XTheatre6CharBase.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
end

---@param eventType number
---@param eventArgs userdata
function XChar1026:HandleEvent(eventType, eventArgs)
    XTheatre6CharBase.HandleEvent(self, eventType, eventArgs)
end

function XChar1026:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    XTheatre6CharBase.OnNpcAddBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果不是自身加buff返回
    if npcUUID ~= self._uuid then
        return
    end
    --动作属于BaseLayer
    if buffId == 1026001 then
        -- XLog.Warning("切换状态机为0")
        self._proxy:SetNpcAnimationLayer(self._uuid, 0)
    end
    --动作属于Layer1
    if buffId == 1026002 then
        -- XLog.Warning("切换状态机为1")
        self._proxy:SetNpcAnimationLayer(self._uuid, 1)
    end

    if buffId == 1026003 then
        -- XLog.Warning("切换状态机为2")
        self._proxy:SetNpcAnimationLayer(self._uuid, 2)
    end
end

function XChar1026:OnNpcCastActionAfterEvent(skillActionId, launcherId, targetId, targetSceneObjId, isAbort)
    if launcherId ~= self._uuid then return end
    if skillActionId == 1026205 then
        self._proxy:SetNpcGravity(self._uuid, 0, 0)
    else
        self._proxy:SetNpcGravity(self._uuid, -50, -15)
    end
end


return XChar1026