local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016026 : XBuffBase
local XBuffScript1016026 = XDlcScriptManager.RegBuffScript(1016026, "XBuffScript1016026", Base)
--效果说明：【概率】类符纹触发x次后，会召唤一只镜魔对敌人进行攻击

function XBuffScript1016026:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1021001
    self.dmgMagicId = 1021101
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.signalId = 1015743 --【概率】成功标记
    self.cnt = 0
    self.cntTarget = 3
    self.enhBuffId = 1016243    --【概率】通用强化buff标记
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016026:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --Buff不存在时，不运行后续逻辑
end

--region EventCallBack
function XBuffScript1016026:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1016026:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        --更新magic等级
        self.magicLevel = self._proxy:GetBuffStacks(self._uuid,self.enhBuffId)
    end
    if npcUUID == self._uuid and buffId == self.signalId then
        self.cnt = self.cnt + 1
        if self.cnt >= self.cntTarget then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self.cnt = 0
        end

    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016026:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016026:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016026
