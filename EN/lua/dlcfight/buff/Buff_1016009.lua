local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016009 : XBuffBase
local XBuffScript1016009 = XDlcScriptManager.RegBuffScript(1016009, "XBuffScript1016009", Base)
--效果说明：对生命值最大值大于自身的敌人，造成伤害提升

function XBuffScript1016009:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicIds = { 1016010, 1016011, 1016012, 1016013 }      --全属性增伤效果
    self.magicLevel = 1
    self.battleStartBuffId = 1015992    --战斗开始标记buff
    self.targetId = 0
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript1016009:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --开局Buff不存在时，不运行后续逻辑
    if not self._proxy:CheckBuffByKind(self._uuid, self.battleStartBuffId) then
        return
    end
    if not self._proxy:CheckNpc(self.targetId) then
        return
    end
    local hpMaxSelf = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    local hpMaxTarget = self._proxy:GetNpcAttribMaxValue(self.targetId, ENpcAttrib.Life)
    if hpMaxTarget > hpMaxSelf and not self._proxy:CheckBuffByKind(self._uuid, self.magicIds[1]) then
        for _, magicId in ipairs(self.magicIds) do
            self._proxy:ApplyMagic(self._uuid, self._uuid, magicId, self.magicLevel)
        end
    elseif hpMaxSelf >= hpMaxTarget and self._proxy:CheckBuffByKind(self._uuid, self.magicIds[1]) then
        for _, magicId in ipairs(self.magicIds) do
            self._proxy:RemoveBuff(self._uuid, magicId)
        end
    end
end

--region EventCallBack
function XBuffScript1016009:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
end

function XBuffScript1016009:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --开局时，获得目标
    if npcUUID == self._uuid and buffId == self.battleStartBuffId then
        self.targetId = self._proxy:GetFightTargetId(self._uuid)
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016009:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016009:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016009
