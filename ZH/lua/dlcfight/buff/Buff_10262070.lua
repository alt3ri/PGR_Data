local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262070 : XTheatre6SkillBase
local XBuffScript10262070 = XDlcScriptManager.RegBuffScript(10262070, "XBuffScript10262070", XTheatre6SkillBase)

--效果说明：本场战斗中首次累计获得8层<坚毅>后触发：
--· 造成400%攻击伤害；
--· 自身每次使用任意技能，均将使自身【攻击】属性提升15/20/25点。

function XBuffScript10262070:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.targetCount = 8
    self._blockController = self:GetNpc():GetBlockController()
    self.ChanceCheck = 0
    self.dictAddAtk = {
        [1] = 15,
        [2] = 20,
        [3] = 25
    }
    self.blockBuff = 1025105
    self.blockCountSave = 0
    self.blockCountNow = 0
    self.blockCountTotal = 0
    self.usedCheck = 0
    self.StackBuffBlock = 1025105 --格挡层数buff
end

--region EventCallBack
function XBuffScript10262070:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)    -- OnNpcAddBuffEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff) -- OnNpcRemoveBuffEvent
end

function XBuffScript10262070:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    if buffId == self.blockBuff then
        self.blockCountNow = self._proxy:GetBuffStacks(self._npcUUID, self.blockBuff) -- 检查获得格挡层数后
        --检查格挡层数是否有变化
        local deltaCount = self.blockCountNow - self.blockCountSave
        if deltaCount >= 0 then                         --如果格挡层数是上升的，计算与上次储存层数的差值
            self.blockCountTotal = self.blockCountTotal + deltaCount
            self.blockCountSave = self.blockCountNow
        end
    end
    if self.blockCountTotal >= self.targetCount and self.ChanceCheck == 0 then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId) --调用技能
        self.ChanceCheck = 1
    end
end

function XBuffScript10262070:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId ~= self.blockBuff then return end
    --更新存储的格挡层数
    self.blockCountSave = self._proxy:GetBuffStacks(self._npcUUID, self.StackBuffBlock)
end

--endregion

function XBuffScript10262070:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    if eventArgs._skillId ~= self._skillId then return end
    self.usedCheck = 1
end

function XBuffScript10262070:OnLuaSkillEnd(eventArgs)
    ------------执行------------
    if self.usedCheck == 0 then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self:AddAttrib(ENpcAttrib.Attack, self.dictAddAtk[self._lv], self._npcUUID, self._npcUUID)
end

return XBuffScript10262070

--无法获取到击飞事件
