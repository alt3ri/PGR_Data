local XTheatre6SkillBase = require("Gameplay/Theatre6/XTheatre6SkillBase")
---@class XBuffScript10262040 : XTheatre6SkillBase
local XBuffScript10262040 = XDlcScriptManager.RegBuffScript(10262040, "XBuffScript10262040", XTheatre6SkillBase)

--效果说明：每次【狂暴】结束时触发：
--· 造成80%攻击伤害；
--· 获得15/30/45点【怒火】；
--· 恢复自身20点【体力值】；

function XBuffScript10262040:ScriptInit(isGainControl) --初始化
    self._damageMagicId = 1026601                     --注册超算成功技1伤害id，目前是临时的 5.20已替换
    self.angryBuffId = 1025108
    self.dictAngerRecover = {
        [1] = 15,
        [2] = 30,
        [3] = 45,
    }
    self.TLRecover = 20
end

function XBuffScript10262040:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScript10262040:OnEnterLevel(levelId)
    XTheatre6SkillBase.OnEnterLevel(self, levelId)
    self._AngerController = self:GetNpc():GetAngerController()
end

function XBuffScript10262040:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId ~= self.angryBuffId then return end
    self._level:RequestInsertSkill(self._npcUUID, self._skillId)
end

function XBuffScript10262040:OnLuaSkillStart(eventArgs)
    ------------执行------------
    if eventArgs._skillId ~= self._skillId then return end
    if eventArgs._launcherUUID ~= self._npcUUID then return end
    self._AngerController:CastStackBuff(self.dictAngerRecover[self._lv], self._npcUUID)
    self._proxy:Theatre6ChangeStaminaValue(self._npcUUID, self.TLRecover, 0) --恢复20体力
end

return XBuffScript10262040

--无法获取到击飞事件
