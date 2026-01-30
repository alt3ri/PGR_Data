local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015924 : XBuffBase
local XBuffScript1015924 = XDlcScriptManager.RegBuffScript(1015924, "XBuffScript1015924", Base)

--效果说明：开局前10秒每造成1000点伤害，敌人生命低于20%时可提升自身10%全属性伤害（最大50%）

function XBuffScript1015924:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicIds = { 1015925, 1015964, 1015965, 1015966, }          --属性提升Buff
    self.runeId = 20920            --符纹ID赋值
    self.magicLevel = 1             --初始等级
    self.maxLevel = 5               --最大等级
    self.signal1Id = 1015907     --【开局】状态标记，标记管理脚本见1015906
    self.signal1CtrlId = 1015906 --【开局】状态管理Buff
    self.signal2Id = 1015905     --【斩杀】状态标记，标记管理脚本见1015904
    self.signal2CtrlId = 1015904 --【斩杀】状态管理Buff
    self.calDmg = 0             --伤害统计
    self.targetDmg = 1000       --每x点伤害触发一次标记

    ------------执行------------
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signal1CtrlId, 1)   --为自己添加【浑身】管理Buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.signal2CtrlId, 1)   --为自己添加【斩杀】管理Buff
end

---@param dt number @ delta time 
function XBuffScript1015924:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015924:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)
    self._proxy:RegisterEvent(EWorldEvent.NpcRemoveBuff)
end

function XBuffScript1015924:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    --计算最终的Buff层数
    local isSignal1Active = self._proxy:CheckBuffByKind(self._uuid, self.signal1Id)
    if self._uuid == launcherId and self._uuid ~= targetId and isSignal1Active then
        self.calDmg = self.calDmg + physicalDamage + elementDamage + realDamage
        local addLevel = math.floor(self.calDmg, self.targetDmg)
        self.calDmg = self.calDmg % self.targetDmg
        self.magicLevel = self.magicLevel + addLevel
    end
end

function XBuffScript1015924:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --进入斩杀状态后施加buff
    if self._uuid == npcUUID and self.signal2Id == buffId then
        self.magicLevel = math.min(self.maxLevel, self.magicLevel)
        for _, magicId in ipairs(self.magicIds) do
            self._proxy:ApplyMagic(self._uuid, self._uuid, magicId, self.magicLevel)
        end
    end
end
function XBuffScript1015924:OnNpcRemoveBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --退出斩杀状态时删除Buff
    if self._uuid == npcUUID and self.signal2Id == buffId then
        for _, magicId in ipairs(self.magicIds) do
            self._proxy:RemoveBuff(self._uuid, magicId)
        end
    end
end


--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015924:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015924:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015924

    