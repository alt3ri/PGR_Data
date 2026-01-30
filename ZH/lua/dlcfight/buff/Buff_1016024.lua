local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016024 : XBuffBase
local XBuffScript1016024 = XDlcScriptManager.RegBuffScript(1016024, "XBuffScript1016024", Base)
--效果说明：【斩杀】效果首次触发时，召唤恶魔对敌人进行一次高额伤害，随后每3次释放技能额外召唤一次

function XBuffScript1016024:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1019001
    self.dmgMagicId = 1019101
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.signalId = 1015905 --【斩杀】标记
    self.targetId = 0
    self.targetCnt = 3
    self.cnt = 0
    self.enhBuffId = 1016241    --【斩杀】通用强化buff标记
    ------------执行------------
    self:RegisterLuaEvent(EFightLuaEvent.AutoChessItemSkillComboStart)
end
---@param dt number @ delta time
function XBuffScript1016024:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --Buff不存在时，不运行后续逻辑
end

--region EventCallBack
function XBuffScript1016024:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1016024:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        --更新magic等级
        self.magicLevel = self._proxy:GetBuffStacks(self._uuid,self.enhBuffId)
    end
    if npcUUID == self._uuid and buffId == self.signalId then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
    end
end
function XBuffScript1016024:HandleLuaEvent(eventType, eventArgs)
    --自定义事件
    Base.HandleLuaEvent(self, eventType, eventArgs)
    if not self._proxy:CheckBuffByKind(self._uuid,self.signalId) then
        return
    end
    -- 技能combo开始时
    if eventType == EFightLuaEvent.AutoChessItemSkillComboStart then
        self.cnt = self.cnt + 1
    end
    if self.cnt >= self.targetCnt then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.cnt = 0
    end

end

--endregion

---@param eventType number
---@param eventArgs userdata

return XBuffScript1016024
