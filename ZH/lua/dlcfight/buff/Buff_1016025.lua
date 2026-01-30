local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016025 : XBuffBase
local XBuffScript1016025 = XDlcScriptManager.RegBuffScript(1016025, "XBuffScript1016025", Base)
--效果说明：【疲劳】状态下每秒召唤一只镜魔对敌人造成一次70%攻击

function XBuffScript1016025:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1020001
    self.dmgMagicId = 1020101
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.signalId = 1015909 --【疲劳】标记
    self.cd = 5
    self.timer = 0
    self.enhBuffId = 1016242    --【疲劳】通用强化buff标记
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016025:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --Buff不存在时，不运行后续逻辑
    if not self._proxy:CheckBuffByKind(self._uuid, self.signalId) then
        return
    end

    local targetId = self._proxy:GetFightTargetId(self._uuid)

    if not self._proxy:CheckNpc(targetId) then
        return
    end

    if self._proxy:GetNpcTime(self._uuid) >= self.timer then
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel)
        self.timer = self._proxy:GetNpcTime(self._uuid) + self.cd
    end
end

--region EventCallBack
function XBuffScript1016025:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1016025:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        self.timer = self.cd + self._proxy:GetNpcTime(self._uuid)
        --更新magic等级
        self.magicLevel = self._proxy:GetBuffStacks(self._uuid, self.enhBuffId)
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016025:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016025:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016025
