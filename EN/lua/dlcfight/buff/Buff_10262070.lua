local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262070 : XTheatre6SkillBase
local XBuffScript10262070 = XDlcScriptManager.RegBuffScript(10262070, "XBuffScript10262070", XTheatre6SkillBase)

--效果说明：本场战斗中首次累计获得10层<坚毅>后触发：
--· 造成400%攻击伤害；
--· 自身每次使用任意技能，均将使自身【攻击】属性提升25点。

function XBuffScript10262070:ScriptInit(isGainControl) --初始化
    self.TargetSkill = self._skillId
    self.targetCount = 10
    self._blockController = self:GetNpc():GetBlockController()
    self.ChanceCheck = 0
    self._addAttack = 25
    self.blockBuff = 1025105
    self.blockCountSave = 0
    self.blockCountNow = 0
    self.blockCountTotal = 0
    self.usedCheck = 0
end

--region EventCallBack
function XBuffScript10262070:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
end

function XBuffScript10262070:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffTableId, buffKinds)
    if buffId == self.blockBuff then
        self.blockCountNow = self._proxy:GetBuffStacks( self._npcUUID,self.StackBuffAngry) -- 检查获得格挡层数后
        if self.blockCountNow - self.blockCountSave >= 0 then --如果格挡层数是上升的，计算与上次储存层数的差值
            self.blockCountTotal = self.blockCountTotal + self.blockCountNow - self.blockCountSave
        end
    end
    if self.blockCountTotal >= self.targetCount then
        self._level:RequestInsertSkill(self._npcUUID, self._skillId) --调用技能
    end
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
    self:AddAttrib(ENpcAttrib.Attack, self._addAttack, self._npcUUID, self._npcUUID)
end

function XBuffScript10262070:OnLuaAttackerChange(eventArgs)
    ------------执行------------
    self.blockCountSave = self._proxy:GetBuffStacks( self._npcUUID,self.StackBuffAngry) -- 出手权发生交换时，刷新一次格挡层数记录，避免受击掉的格挡层数污染记录
end


return XBuffScript10262070

--无法获取到击飞事件