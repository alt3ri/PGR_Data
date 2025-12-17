local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015224 : XBuffBase
local XBuffScript1015224 = XDlcScriptManager.RegBuffScript(1015224, "XBuffScript1015224", Base)

--效果说明：普攻命中敌人时，提升自身5点【护盾强度】，上限100点

------------配置------------
local ConfigMagicIdDict = {
    [1015224] = 1015225,
    [1015243] = 1015244,
    [1015245] = 1015246,
    [1015247] = 1015248,
    [1016116] = 1016117
}
local ConfigRuneIdDict = {
    [1015224] = 20224,
    [1015243] = 20243,
    [1015245] = 20245,
    [1015247] = 20247,
    [1016116] = 20247
}

function XBuffScript1015224:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 1
    self.count = 0
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
end

---@param dt number @ delta time 
function XBuffScript1015224:Update(dt)
    --每帧执行
    Base.Update(self, dt)
end

--region EventCallBack
function XBuffScript1015224:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)
end

function XBuffScript1015224:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    local kind = self._proxy:GetActionType(skillId)
    if launcherId == self._uuid and kind == 1 and self.count <= 20 then
        self.count = self.count + 1
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015224:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015224:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015224

    