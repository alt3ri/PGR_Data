local Base = require("Common/XFightBase")

---@class XBuffScript1015124 : XFightBase
local XBuffScript1015124 = XDlcScriptManager.RegBuffScript(1015124, "XBuffScript1015124", Base)

--效果说明：每次对敌人造成雷属性伤害时，有10%概率使接下来三次普攻附加雷属性攻击，效果不可叠加
function XBuffScript1015124:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015125
    self.magicLevel = 1
    self.magicProb = 10         --触发概率，百分比
    self.atkCount = 0           --普攻计数器
    self.atkTargetCount = 3     --生效的普攻次数
    self.trigger = false        --普攻召唤雷电判定
    self.normalAtkType = 1      --普攻Type类型
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015124:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015124:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)    -- OnNpcCastSkillEvent
end

function XBuffScript1015124:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    --造成雷伤时，进行一次随机判定，是否施加附加伤害
    --当附加伤害开关打开时，无需走下列逻辑
    if self.trigger then
        return
    end

    --不是自己释放的就返回
    if launcherId ~= self._uuid then
        return
    end

    --不是雷伤就返回，0物理、1火/2雷/3暗/4冰
    if elementType ~= 2 then
        return
    end

    --进行一次随机判定
    local num = self._proxy:Random(1, 100)
    if num <= self.magicProb then
        self.trigger = true     --打开普攻附加开关
    end
end

function XBuffScript1015124:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    --当附加伤害开启时，技能为普攻，则施加一次雷伤，计数3次后关闭

    --当附加伤害开关关闭时，无需走下列逻辑
    if not self.trigger then
        return
    end

    --判定自己释放技能
    if launcherId ~= self._uuid then
        return
    end

    --如果是普攻，就附加伤害
    if self._proxy:GetActionType(skillId) == self.normalAtkType then
        self._proxy:ApplyMagic(self._uuid, targetId, self.magicId, self.magicLevel)
        self.atkCount = self.atkCount + 1
    end

    --如果已经打了目标次数，重置次数计数，并关闭开关
    if self.atkCount >= self.atkTargetCount then
        self.trigger = false
        self.atkCount = 0
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015124:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015124:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015124
