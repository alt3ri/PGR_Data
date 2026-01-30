local Base = require("Common/XFightBase")

---@class XBuffScript1015406 : XFightBase
local XBuffScript1015406 = XDlcScriptManager.RegBuffScript(1015406, "XBuffScript1015406", Base)

--效果说明：造成冰属性伤害时，将标记目标，目标未移动时，自己造成的冰伤提升10/s，上限50
function XBuffScript1015406:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.triggerCD = 1     --宝珠生效CD
    self.magicId = 1015407 --魔法id
    self.magicLevel = 1 --魔法等级
    self.magicCount = 1   --buff层数计数
    self.magicMaxCount = 5 --最大层数
    self.enemyId = 0    --敌人id
    self.trigger = false    --记录开关
    ------------执行------------
    XLog.Warning("初始化完成")
end

---@param dt number @ delta time
function XBuffScript1015406:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --开关没打开时不用考虑添加buff
    if not self.trigger then
        return
    end

    --如果敌人坐标变化了，则删除增伤buff、重置Cd、层数、敌人坐标
    local isStay = XScriptTool.EqualVector3(self._proxy:GetNpcPosition(self.enemyId), self.npcPosition) 
    if not isStay then
        XLog.Warning("敌人坐标变化了")
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
        self.magicCount = 0
        self.trigger = false
        return
    end

    local isCdOk = self._proxy:GetNpcTime(self._uuid) >= self.cdTimer   --CD好了没
    local isCountOk = self.magicCount <= self.magicMaxCount             --层数满了没
    if isCdOk and isCountOk then
        XLog.Warning("Buff加上了")
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --给自己添加增伤Buff
        self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
        self.magicCount = self.magicCount + 1   --层数计数+1
    end
end

--region EventCallBack
function XBuffScript1015406:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015406:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    --当有Npc受到伤害时

    --开关打开时不用再走这个逻辑
    if self.trigger then
        return
    end

    --如果不是自己放的技能，则返回
    if not (launcherId == self._uuid) then
        return
    end

    --是否冰属性 0物理、1火/2雷/3暗/4冰 !!!临时改成物理攻击测试
    if not (elementType == 0) then
        return
    end
    self.enemyId = targetId   --记录敌人id
    self.npcPosition = self._proxy:GetNpcPosition(self.enemyId) --记录初始坐标
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
    self.trigger = true
    XLog.Warning("标记完成")
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015406:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015406:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015406
