local XTheatre6CharBase = require("Gameplay/Theatre6/XTheatre6CharBase")

---肉鸽6涅媞娅脚本
---@class XChar1028:XTheatre6CharBase
local XChar1028 = XDlcScriptManager.RegCharScript(1028, "XChar1028", XTheatre6CharBase)

---@class XChar1028.StateMachine:XTheatre6StateMachine

local StateMachine, States = XTheatre6CharBase:CreateClasses("XChar1028")

XChar1028.StateMachine = StateMachine --[[@as XChar1028.StateMachine]]
XChar1028.States = States --[[@as table<string|integer, XChar1028.State>]]

States.Wrestle.WrestleSkillIdLeft = 1028001 -- 拼刀start动作 左 (fighter1
States.Wrestle.WrestleSkillIdRight = 1028005 -- 拼刀start动作 右 (fighter2
States.Wrestle.WrestleSkillIdLeftCountinue = 1028006 -- 拼刀僵持动作 左 (fighter1
States.Wrestle.WrestleSkillIdRightCountinue = 1028007 -- 拼刀僵持动作 右 (fighter2
States.Wrestle.PindaoStart2LCamera = 10280102 -- 拼刀start冲刺特写镜头动画buff 左(fighter1
States.Wrestle.PindaoStart2RCamera = 10280103 -- 拼刀start冲刺特写镜头动画buff 右(fighter2
States.Wrestle.SucceedActionId = 1028002 -- 拼刀成功动作
States.Wrestle.SecondWrestleReset = 1028010 -- 二次拼刀位置重置动作
States.Dodge.DodgeSkillId = 1028003  -- 超算受身动作
States.Dodge.SucceedActionId = 1028004 --超算受身成功反击
States.Block.Actions = {1028009} -- 格挡动作

-- local NetiaGatherSelfPos = { x = 51, y = 11.52, z = 58.5 } --涅媞娅大招固定点位for自己
-- local NetiaGatherSelfPos_look = { x = 52, y = 11.52, z = 58.5 } --涅媞娅大招固定点位for自己_看向的方向
-- local NetiaGatherEnemyPos = { x = 60, y = 11.52, z = 55.6 } --涅媞娅大招固定点位for敌人
--local NetiaGatherEnemyPos_look = { x = 58.7, y = 11.52, z = 54 } --涅媞娅大招固定点位for敌人_看向的方向

function XChar1028:_BaseInit()
    XTheatre6CharBase._BaseInit(self)
    -- self._proxy:ApplyMagic(self._uuid, self._uuid, 1028003)
    -- self._proxy:ApplyMagic(self._uuid, self._uuid, 1028004)
    -- XLog.Warning("涅媞娅初始化完成")
end

function XChar1028:InitEventCallBackRegister()
    --涅媞娅独特注册脚本
    XTheatre6CharBase.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
end

---@param eventType number
---@param eventArgs userdata
function XChar1028:HandleEvent(eventType, eventArgs)
    XTheatre6CharBase.HandleEvent(self, eventType, eventArgs)
end

function XChar1028:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    XTheatre6CharBase.OnNpcAddBuffEvent(self, casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --如果不是自身加buff返回
    if npcUUID ~= self._uuid then
        return
    end
    --动作属于BaseLayer
    if buffId == 1028001 then
        -- XLog.Warning("切换状态机为0")
        self._proxy:SetNpcAnimationLayer(self._uuid, 0)
        self._proxy:AddTimerTask(0.5, function()
            ---self._proxy:ApplyMagic(self._uuid, self._uuid, 1028003)
            ---self._proxy:ApplyMagic(self._uuid, self._uuid, 1028004)
        end)
    end
    --动作属于Layer1
    if buffId == 1028002 then
        -- XLog.Warning("切换状态机为1")
        self._proxy:SetNpcAnimationLayer(self._uuid, 1)
        ---self._proxy:ApplyMagic(self._uuid, self._uuid, 1028007)
        ---self._proxy:ApplyMagic(self._uuid, self._uuid, 1028008)
    end
end

function XChar1028:OnNpcSkillActionKeyframeSendEvent(launcher, eventName, skillActionId, keyFrameId, skillId)
    XTheatre6CharBase.OnNpcSkillActionKeyframeSendEvent(self, launcher, eventName, skillActionId, keyFrameId, skillId)

    if launcher ~= self._uuid then
        return
    end

    if eventName == "ResetGatherPosition" then
        local enemy = self._enemyUUID or self._proxy:GetFightTargetId(self._uuid)
        if not enemy or not self._proxy:CheckActorExist(enemy) then
            return
        end
        local centerPos = self._proxy:GetSpot(1)
        local NetiaGatherSelfPos = {
         x = centerPos.x - 6,
         y = centerPos.y,
         z = centerPos.z - 2.9,
        }
        local NetiaGatherSelfPos_look = {
         x = centerPos.x -5,
         y = centerPos.y,
         z = centerPos.z - 2.9,
        }
        local NetiaGatherEnemyPos = {
         x = centerPos.x + 11,
         y = centerPos.y,
         z = centerPos.z -7,
        }

        self._proxy:SetNpcPosition(self._uuid, NetiaGatherSelfPos, false)
        self._proxy:SetNpcPosition(enemy, NetiaGatherEnemyPos, false)
        self._proxy:SetNpcFaceToPosition(self._uuid, NetiaGatherSelfPos_look)
        self._proxy:SetNpcFaceToPosition(enemy, NetiaGatherSelfPos)
        return
    end

end

return XChar1028