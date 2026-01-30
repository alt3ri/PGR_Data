local Base = require("Common/XFightBase")

---@class XBuffScript1015345 : XFightBase
local XBuffScript1015345 = XDlcScriptManager.RegBuffScript(1015345, "XBuffScript1015345", Base)

--效果说明：受到5次治疗后，可召唤一个持续5秒的医疗助手无人机，医疗助手无人机可提升角色100点【回复效率】，并减少90%玩家受到的最终伤害。
function XBuffScript1015345:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicLevel = 1
    self.magicId = 1015346      --buff id，所谓的无人机 1010023
    self.healCnt = 0            --治疗计数
    self.healCntTarget = 5      --目标治疗次数
    self.dmgAbsorbP = 90        --减伤，百分比
    ------------执行------------
end

---@param dt number @ delta time
function XBuffScript1015345:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015345:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcCalcDamageAfter,self._uuid)
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcCureAfter)
end

function XBuffScript1015345:AfterDamageCalc(eventArgs)
    --Buff存在时，受伤时可减少伤害
    --Buff不存在时返回
    if not self._proxy:CheckBuffByKind(self._uuid, self.magicId) then
        return
    end
    --不是自己受伤时返回
    if eventArgs.Target ~= self._uuid then
        return
    end
    --减伤，元素和物理
    XLog.Warning("1015345:触发减伤逻辑")
    local physicalDmg = eventArgs.PhysicalDamage
    XLog.Warning("1015345:本次伤害值为" .. physicalDmg)
    physicalDmg = math.floor(0.5 + physicalDmg *(100 - self.dmgAbsorbP) / 100)
    XLog.Warning("1015345:本次伤害减免后值为" .. physicalDmg)
    self._proxy:SetAfterDamageMagicContext(eventArgs.ContextId, physicalDmg, eventArgs.ElementDamage, eventArgs.FinalHackDamage)
end

function XBuffScript1015345:AfterCureCalc(eventArgs)
    --治疗后，添加一个无人机Buff
    --Buff存在时返回
    if self._proxy:CheckBuffByKind(self._uuid, self.magicId) then
        return
    end
    --目标不是自己时返回，是自己则进行计数
    if eventArgs.Target ~= self._uuid then
        return
    end
    self.healCnt = self.healCnt + 1
    XLog.Warning("1015345:进行了一次治疗，计数为" .. self.healCnt)
    --若计数次数满足要求则添加Buff
    if self.healCnt >= self.healCntTarget then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        XLog.Warning("1015345:召唤无人机！")
        self.healCnt = 0
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015345:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015345:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015345
