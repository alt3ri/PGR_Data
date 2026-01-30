local Base = require("Common/XFightBase")

---@class XBuffScript1015008 : XFightBase
local XBuffScript1015008 = XDlcScriptManager.RegBuffScript(1015008, "XBuffScript1015008", Base)

--效果说明：造成火属性伤害时，概率获得3层标记（每层获取概率为50%），下一次释放火属性技能时，每层标记提供10%【火属性伤害提升】
function XBuffScript1015008:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015009          --增伤MagicId
    self.magicLevel = 1             --Magic等级
    self.prob = 50                  --百分比，触发Buff的概率
    self.magicMaxCnt = 3            --最大触发次数
    self.magicCnt = 0               --标记层数
    self.targetElementType = 1      --火属性伤害类型
    self.skillStartType = 2         --起手技能类型
    self.trigger = 1                --流程管理，1为标记阶段，2为检测技能阶段，3为判断技能伤害属性阶段&加Buff阶段，4为删除Buff阶段
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015008:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015008:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)    -- OnNpcCastSkillEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcCalcDamageBefore)  -- BeforeDamageCalc
end

function XBuffScript1015008:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    --当有对敌人造成伤害时，记录标记，下一次使用技能时将标记层数转化为火属性增伤
    --只有标记阶段走这个流程
    if self.trigger ~= 1 then
        return
    end
    --自己不是释放者时返回
    if launcherId ~= self._uuid then
        return
    end
    --不是火属性伤害时返回
    if elementType ~= self.targetElementType then
        return
    end
    --3次随机，小于Prob则计数+1
    for _ = 1, self.magicMaxCnt do
        local num = self._proxy:Random(1, 100)
        if num < self.prob then
            self.magicCnt = self.magicCnt + 1
        end
    end
    --完成标记，进入阶段2
    self.trigger = 2
end

function XBuffScript1015008:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    --释放技能时，首先根据标记数量判断增加还是删除Buff，然后打开开关走伤害事件走标记逻辑
    --不是自己释放时返回
    if launcherId ~= self._uuid then
        return
    end
    --不是起手技能时返回
    if self._proxy:GetActionType(skillId) ~= self.skillStartType then
        return
    end
    --检测技能阶段逻辑
    if self.trigger == 2 then
        self.trigger = 3        --去检测一下伤害属性
    end
    --删除Buff阶段逻辑
    if self.trigger == 4 then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self.trigger = 1        --完成整个流程，重置
    end
end

function XBuffScript1015008:BeforeDamageCalc(eventArgs)
    --如果不是判断技能属性的阶段，就返回
    if self.trigger ~= 3 then
        return
    end
    --如果不是自己的技能，就返回
    if eventArgs.Launcher ~= self._uuid then
        return
    end
    --如果技能不是火属性，则回到步骤2
    if eventArgs.elementType == self.targetElementType then
        self.trigger = 2
        return
    end
    --施加Buff，进入阶段4
    self.magicLevel = self.magicCnt
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
    self.trigger = 4
    self.magicCnt = 0 --重置标记数量
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015008:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015008:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015008
