local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016021 : XBuffBase
local XBuffScript1016021 = XDlcScriptManager.RegBuffScript(1016021, "XBuffScript1016021", Base)
--效果说明：开始战斗时召唤恶魔进行一次强力攻击，随后提升角色攻击力和减伤，持续至【开局】效果结束

function XBuffScript1016021:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1018001
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.signalId = 1015907 --【开局】标记
    self.targetId = 0
    self.enhBuffId = 1016238    --【开局】通用强化buff标记
    ------------执行------------
end
---@param dt number @ delta time
function XBuffScript1016021:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --开局Buff不存在时，不运行后续逻辑

end

--region EventCallBack
function XBuffScript1016021:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScript1016021:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局执行操作
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        --获得目标
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
        --更新magic等级
        self.magicLevel = self._proxy:GetBuffStacks(self._uuid,self.enhBuffId)
    end
    if npcUUID == self._uuid and buffId == self.signalId then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
    end


end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016021:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016021:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016021
