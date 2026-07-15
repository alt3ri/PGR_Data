local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262030 : XTheatre6SkillBase
local XBuffScript10262030 = XDlcScriptManager.RegBuffScript(10262030, "XBuffScript10262030", XTheatre6SkillBase)

--效果说明：
--狂暴期间，每次怒火=50点时触发：
--恢复50点怒火。每次使用此技能，本场战斗中此技能的怒火恢复减少30/20/15点

function XBuffScript10262030:ScriptInit(isGainControl)
    self.count = 0            --触发计数
    self.angerCheck = 50      --怒火值检查点
    self.angerRecover = 50    --恢复基础值
    self.checkTrigger = false --检查重复触发开关，高于50时打开，低于50时关闭
    self.isAdded = false      --重复触发统计
    self.selfTrigger = true  --是否允许自己触发自己
    --每次使用技能后，减少的值
    self.dictAngerRecoverReduce = {
        [1] = 30,
        [2] = 20,
        [3] = 15,
    }
    --注册怒火控制器
    self.angerController = self:GetNpc():GetAngerController()
    self.ChanceCheck = 0
end

function XBuffScript10262030:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self.isAdded = false
    --如果是自己释放的技能，进行怒火恢复逻辑
    if eventArgs._skillId ~= self._skillId then self.ChanceCheck = 0 return end
    local calAngerRecover = math.max(0, self.angerRecover - self.dictAngerRecoverReduce[self._lv] * self.count)
    self.angerController:CastStackBuff(calAngerRecover, self._npcUUID)
    self.count = self.count + 1
    --如果不允许触发自己，则释放本技能时，不判断触发技能
    if not self.selfTrigger then self.isAdded = true end
end

function XBuffScript10262030:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScript10262030:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId ~= self.angerController.StackBuffAnger then return end
    if npcUUID ~= self._npcUUID then return end
    --如果开关已经打开，直接返回
    if self.checkTrigger then return end
    --判断怒火值是否达到目标值以上，以上则开启
    local angerStacks = self._proxy:GetBuffStacks(self._npcUUID, self.angerController.StackBuffAnger)
    if angerStacks > self.angerCheck then
        self.checkTrigger = true
    end
end

function XBuffScript10262030:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId ~= self.angerController.StackBuffAnger then return end
    if npcUUID ~= self._npcUUID then return end
    --每当怒火从检查点以上，降低至检查点以下时，触发一次技能
    local angerStacks = self._proxy:GetBuffStacks(self._npcUUID, self.angerController.StackBuffAnger)
    --当触发开关打开，且当前值小于检查值时，进行一次触发
    local isAngry = self._proxy:GetBuffStacks(self._npcUUID, self.angerController.StackBuffAngry) >= 1
    local isRequest = (angerStacks <= self.angerCheck) and self.checkTrigger and isAngry and not self.isAdded
    if isRequest then
        if self.ChanceCheck == 0 then
            self._level:RequestInsertSkill(self._npcUUID, self._skillId)
            self.isAdded = true
            self.checkTrigger = false
            self.ChanceCheck = 1
        end
    end
end

return XBuffScript10262030
