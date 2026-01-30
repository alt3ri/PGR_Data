local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015128 : XBuffBase
local XBuffScript1015128 = XDlcScriptManager.RegBuffScript(1015128, "XBuffScript1015128", Base)

--效果说明：每次普攻命中敌人时，提升X%【雷属性伤害提升】，上限4X%

------------配置------------
local ConfigMagicIdDict = {
    [1015128] = 1015129,
    [1015154] = 1015155,
    [1015156] = 1015157,
    [1015158] = 1015159,
    [1016112] = 1016113
}
local ConfigRuneIdDict = {
    [1015128] = 20128,
    [1015154] = 20154,
    [1015156] = 20156,
    [1015158] = 20158,
    [1016112] = 20158
}

function XBuffScript1015128:Init() --初始化
    Base.Init(self)
    ------------配置------------
    self.initialBuffLevel = 1  -- 初始buff等级
    self.BuffId = ConfigMagicIdDict[self._buffId]     -- 雷伤BUFF
    self.buffCount = 0         -- buff叠加计数器
    self.maxCount = 30  --最大叠加次数
    self.skillKind = 1
    self.runeId = ConfigRuneIdDict[self._buffId]
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015128:Update(dt) --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015128:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)         -- OnNpcCastSkillEvent

end

function XBuffScript1015128:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    if self.buffCount >= self.maxCount then return end
    if launcherId ~= self._uuid then return end
    if self._proxy:CheckNpcCurrentAction(self._uuid,self.skillKind) then return end
    self._proxy:ApplyMagic(self._uuid,self._uuid,self.BuffId,self.initialBuffLevel)
    self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
    self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    self.buffCount = self.buffCount + 1
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015128:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015128:Terminate()
    Base.Terminate(self)
end


return XBuffScript1015128
