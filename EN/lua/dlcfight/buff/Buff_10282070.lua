local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10282070 : XTheatre6SkillBase
local XBuffScript10282070 = XDlcScriptManager.RegBuffScript(10282070, "XBuffScript10282070", XTheatre6SkillBase)

--效果说明：每累计造成3次【失心】时触发：
--· 【攻击】属性提升30/60/100点；
--· 恢复25点【战意值】。

function XBuffScript10282070:ScriptInit(isGainControl) --初始化
    self._hypnoController = self:GetNpc():GetHypnoController()
    self.LostHeartTriggerBuff = self:GetNpc():GetHypnoController().LostHeartTriggerBuff
    self.LostHeartTimeCount = 0
    self.LostHeartTimeCountTimeTarget = 3
    --self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
    --self._StackBuffATK = 50
    self._StackBuffATK = {
        --不同等级的默认魅惑层数
        [1] = 30,
        [2] = 60,
        [3] = 100
    }

    self._TLRecover = 25
end

function XBuffScript10282070:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff) --注册添加buff事件
end


function XBuffScript10282070:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._poisonedController = self:GetEnemyNpc():GetPoisonedController()
end

function XBuffScript10282070:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._launcherUUID == self._npcUUID then
        if eventArgs._skillId ~= self._skillId then return end
       self._proxy:ApplyMagic(self._npcUUID,self._npcUUID,1025904,1,1,self._StackBuffATK[self._lv])
        self._proxy:Theatre6ChangeStaminaValue(self._npcUUID,self._TLRecover)
    end
end

function XBuffScript10282070:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if npcUUID ~= self._npcUUID then return end
    if buffId ~= self.LostHeartTriggerBuff then return end --失心
    self.LostHeartTimeCount = self.LostHeartTimeCount + 1
    if self.LostHeartTimeCount == self.LostHeartTimeCountTimeTarget then
        self._level:RequestInsertSkill(self._npcUUID,self._skillId)
        self.LostHeartTimeCount = 0
    end
end

return XBuffScript10282070