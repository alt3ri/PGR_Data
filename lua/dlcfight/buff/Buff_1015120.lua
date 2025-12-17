local Base = require("Common/XFightBase")

---@class XBuffScript1015120 : XFightBase
local XBuffScript1015120 = XDlcScriptManager.RegBuffScript(1015120, "XBuffScript1015120", Base)

--效果说明：当敌人距离自身5m内，每次使用普攻或技能可获得【静电】标记（最高10层）。当敌人距离自身5m外时，使用技能消耗全部【静电】标记，使本次技能期间【雷属性伤害】提升10*层数
function XBuffScript1015120:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.labelId = 1015121      --【静电】BuffId
    self.magicId = 1015140      --提升属性Buff
    self.magicLevel = 1         --Buff等级
    self.magicRange = 5         --距离
    self.magicMaxLevel = 10     --最大数量
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015120:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015120:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcCastActionAfter)    -- OnNpcCastSkillEvent
end

function XBuffScript1015120:OnNpcCastActionAfterEvent(skillId, launcherId, targetId, targetSceneObjId, isAbort)
    --释放技能时，判断距离，如果距离内就加buff，距离外就消耗buff提升属性，再放技能时删除提升属性
    --不是自己释放的就返回
    if launcherId ~= self._uuid then
        return
    end
    --判断是否已经有增伤Buff在身上了，如果有则删除，没有则继续
    if self._proxy:CheckBuffByKind(self._uuid, self.magicId) then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        XLog.Warning("1015120: 删除了增伤Buff")
    end

    --判断距离，如果在距离内则增加静电层数，如果距离外则消耗静电获得增益
    local isInMagicRange = self._proxy:CheckNpcPositionDistance(self._uuid, self._proxy:GetNpcPosition(targetId), self.magicRange, true)
    local stacks = self._proxy:GetBuffStacks(self._uuid, self.labelId)
    local isStacksOk = stacks < self.magicMaxLevel
    if isInMagicRange then
        --层数没到最大就添加
        if isStacksOk then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.labelId, self.magicLevel)
            XLog.Warning("1015120: 添加了1层静电")
        end
    else
        self._proxy:RemoveBuff(self._uuid, self.labelId)
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, stacks)
        XLog.Warning("1015120: 删除静电，添加增伤Buff，等级为" .. stacks)
    end

end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015120:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015120:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015120
