local XTheatre6CharBase = require("Gameplay/Theatre6/XTheatre6CharBase")

---肉鸽6维罗妮卡脚本
---@class XChar1025:XTheatre6CharBase
local XChar1025 = XDlcScriptManager.RegCharScript(1025, "XChar1025", XTheatre6CharBase)

---@class XChar1025.State:XTheatre6State
---@field _owner XChar1025
---@field _stateMachine XChar1025.StateMachine

---@class XChar1025.StateMachine:XTheatre6StateMachine

local StateMachine, States = XTheatre6CharBase:CreateClasses("XChar1025")

XChar1025.StateMachine = StateMachine --[[@as XChar1025.StateMachine]]
XChar1025.States = States --[[@as table<string|integer, XChar1025.State>]]

States.Wrestle.WrestleSkillIdLeft = 1025001 -- 拼刀start动作 左 (fighter1
States.Wrestle.WrestleSkillIdRight = 1025005 -- 拼刀start动作 右 (fighter2
States.Wrestle.WrestleSkillIdLeftCountinue = 1025006 -- 拼刀僵持动作 左 (fighter1
States.Wrestle.WrestleSkillIdRightCountinue = 1025007 -- 拼刀僵持动作 右 (fighter2
States.Wrestle.PindaoStart2LCamera = 10250102 -- 拼刀start冲刺特写镜头动画buff 左(fighter1
States.Wrestle.PindaoStart2RCamera = 10250103 -- 拼刀start冲刺特写镜头动画buff 右(fighter2
States.Wrestle.SucceedActionId = 1025002 -- 拼刀成功动作
States.Wrestle.SecondWrestleReset = 1025010 -- 二次拼刀位置重置动作
States.Dodge.DodgeSkillId = 1025003  -- 超算受身动作
States.Dodge.SucceedActionId = 1025004 --超算受身成功反击
States.Block.ActionId = 1025009 -- 格挡动作

function XChar1025:_BaseInit()
    XTheatre6CharBase._BaseInit(self)
    -- self._proxy:ApplyMagic(self._uuid, self._uuid, 1025003)
    -- self._proxy:ApplyMagic(self._uuid, self._uuid, 1025004)
    XLog.Warning("维罗妮卡初始化完成")
end

function XChar1025:InitEventCallBackRegister()
    --维罗妮卡独特注册脚本
    XTheatre6CharBase.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
end

---@param eventType number
---@param eventArgs userdata
function XChar1025:HandleEvent(eventType, eventArgs)
    XTheatre6CharBase.HandleEvent(self, eventType, eventArgs)
end

function XChar1025:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    XTheatre6CharBase.OnNpcAddBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果不是自身加buff返回
    if npcUUID ~= self._uuid then
        return
    end
    --动作属于BaseLayer
    if buffId == 1025001 then
        XLog.Warning("切换状态机为0")
        self._proxy:SetNpcAnimationLayer(self._uuid, 0)
        self._proxy:AddTimerTask(0.5, function()
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1025003)
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1025004)
        end)
    end
    --动作属于Layer1
    if buffId == 1025002 then
        XLog.Warning("切换状态机为1")
        self._proxy:SetNpcAnimationLayer(self._uuid, 1)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1025007)
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1025008)
    end
end

-- function XChar1025:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
--     XTheatre6CharBase.OnNpcSkillActionKeyframeSendEvent(self, launcher, eventName, skillActionId, keyFrameId, skillId)
--     if eventName == "Wrestle" then
--         self._proxy:ApplyMagic(self._uuid, self._uuid, 1025003)--添加去时缓buff
--         self._proxy:AbortAction(self._uuid, true)
--         self._proxy:CastActionToTarget(self._uuid, 1025002, self._enemyUUID)
--     end
-- end

return XChar1025