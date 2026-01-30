local Base = require("Common/XFightBase")

---@class XBuffScript1015428 : XFightBase
local XBuffScript1015428 = XDlcScriptManager.RegBuffScript(1015428, "XBuffScript1015428", Base)

--效果说明：使用技能造成冰伤时，角色可获得【寒霜】Buff，内置CD1秒（【寒霜】：重复获得时可刷新冷却时间并提升Buff等级，持续2秒，最高5级，1/2/3/4/5级可提升冰伤10/20/40/80/160点）
function XBuffScript1015428:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.triggerCD = 1      --宝珠生效CD
    self.magicId = 1015429  --魔法id
    self.magicLevel = 1     --初始魔法等级
    self.magicMaxLevel = 5  --最大等级
    ------------执行------------
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
end

---@param dt number @ delta time 
function XBuffScript1015428:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015428:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015428:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    --当有Npc受到伤害时

    --不是自己释放的就返回
    if not (launcherId == self._uuid) then
        return
    end

    --不是冰属性就返回，0物理、1火/2雷/3暗/4冰
    if elementType ~= 4 then
        return
    end

    --CD没好就返回
    if self._proxy:GetNpcTime(self._uuid) < self.cdTimer then
        return
    end

    --如果身上有Buff，则更新为更高一级的buff，如果身上没有Buff，则重置等级，挂上1级Buff
    if self._proxy:CheckBuffByKind(self._uuid, self.magicId) then
        --如果Buff等级超过上限了，就直接返回
        if self.magicLevel > self.magicMaxLevel then
            return
        end
        --没超过上限再继续执行更新buff操作
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.magicLevel = self.magicLevel + 1   --等级加1
    else
        self.magicLevel = 1     --重置等级
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015428:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015428:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015428
