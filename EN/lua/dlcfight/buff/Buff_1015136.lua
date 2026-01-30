local Base = require("Common/XFightBase")

---@class XBuffScript1015136 : XFightBase
local XBuffScript1015136 = XDlcScriptManager.RegBuffScript(1015136, "XBuffScript1015136", Base)

--效果说明：每使用3次技能，下一次释放雷属性技能时【雷属性伤害】提升50点，并且该次技能可造成1次电磁爆炸，将敌人击退5m
function XBuffScript1015136:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.missileId = 10100106      --击退子弹ID
    self.missileLevel = 1
    self.magicId = 1015137      --增伤BuffId
    self.magicLevel = 1
    self.skillCnt = 0           --技能计数
    self.skillTargetCnt = 3     --目标技能释放数
    self.startSkillType = 2     --起手技能Type
    self.normalAtkType = 1      --普攻技能Type
    self.trigger = false        --击退开关，如果触发效果则打开
    self.skillGroup = { 101011, 101013, 101014 }    --万事雷属性起手技能
    XLog.Warning("1015136：初始化")
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015136:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015136:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)    -- OnNpcCastSkillEvent
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015136:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    --技能释放时进行计数，当满足计数时，判断释放的技能是否为射击技能，是则触发效果，不是则返回
    --判断是否是自己放技能
    if launcherId ~= self._uuid then
        return
    end

    --判断技能类型
    local isStartSkill = self._proxy:GetActionType(skillId) == self.startSkillType
    local isNormalAtk = self._proxy:GetActionType(skillId) == self.normalAtkType
    --如果是普攻、起手技能，且身上已有Buff了，说明前一个技能已经吃到加成收益了，删除Buff
    if (isStartSkill or isNormalAtk) and self._proxy:CheckBuffByKind(self._uuid, self.magicId) then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
    end
    --如果不是起手技能，就不用继续后续计数逻辑了
    if not isStartSkill then
        return
    end
    --判断技能计数是否达到触发值，没达到则+1后返回，达到了需要走触发逻辑
    if self.skillCnt < self.skillTargetCnt then
        self.skillCnt = self.skillCnt + 1
        return
    end
    --触发逻辑：判断是否是skillGroup中的技能，是的话获取增伤Buff，不是则跳过
    if self:ContainsValue(self.skillGroup, skillId) then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.trigger = true
        self.skillCnt = 0   --计数重置
    end
end

function XBuffScript1015136:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    --判断击退开关是否打开，没打开直接返回，打开了则发射子弹
    if not self.trigger then
        return
    end
    --判断是否是自己造成伤害
    if launcherId ~= self._uuid then
        return
    end
    --发射击退子弹
    self._proxy:LaunchMissile(launcherId, targetId, self.missileId, self.missileId,self.missileLevel)
    XLog.Warning("1015136：发射子弹")
    self.trigger = false
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015136:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015136:Terminate()
    Base.Terminate(self)
end

--查询技能是否在SkillGroup中
function XBuffScript1015136:ContainsValue(array, target)
    for _, v in ipairs(array) do
        if v == target then
            XLog.Warning("1015136：是组里的技能")
            return true
        end
    end
    return false
end

return XBuffScript1015136
