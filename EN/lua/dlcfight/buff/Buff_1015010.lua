local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015010 : XBuffBase
local XBuffScript1015010 = XDlcScriptManager.RegBuffScript(1015010, "XBuffScript1015010", Base)

--效果说明：火属性攻击命中敌人后（给个内置cd），在敌人脚下生成一个区域，持续5秒，自身在区域内可提升X%【火属性伤害提升】

------------配置------------
local ConfigMagicIdDict = {
    [1015010] = 1015011,
    [1015040] = 1015041,
    [1015042] = 1015043,
    [1015044] = 1015045
}
local ConfigRuneIdDict = {
    [1015010] = 20010,
    [1015040] = 20040,
    [1015042] = 20042,
    [1015044] = 20044
}

function XBuffScript1015010:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.range = 3          --半径
    self.refreshCd = 5      --火圈重新生成的CD
    self.duration = 5        --火圈持续时间
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 1     --magic等级
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    ------------执行------------
    self.magicPos = self._proxy:GetNpcPosition(self._uuid)  --火圈生成位置初始化
    self.refreshTimer = self._proxy:GetNpcTime(self._uuid)  --计算火圈重新生成的计时器
    self.durTimer = 0      --计算火圈生效的计时器
end

---@param dt number @ delta time 
function XBuffScript1015010:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --若处于火圈生效期间，则根据距离和身上是否有Buff决定添加还是删除火圈Buff
    --不在火圈生效期间直接返回
    if self._proxy:GetNpcTime(self._uuid) > self.durTimer then
        return
    end
    --记录身上是否有Buff，以及是否处于火圈内
    local isBuffActive = self._proxy:CheckBuffByKind(self._uuid, self.magicId)
    local isInArea = self._proxy:CheckNpcPositionDistance(self._uuid, self.magicPos, self.range, true)
    --如果身上有Buff，且处于火圈外，那需要删除Buff
    if isBuffActive and not isInArea then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
    end
    --如果身上没有Buff，且处于火圈内，则需要添加Buff
    if not isBuffActive and isInArea then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
    end
end

--region EventCallBack
function XBuffScript1015010:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015010:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    --满足刷新条件，且自身释放火属性攻击时，刷新火圈位置，并刷新火圈生效和刷新的计时器
    --不满足刷新火圈CD时直接返回
    if self._proxy:GetNpcTime(self._uuid) < self.refreshTimer then
        return
    end
    --如果是自身释放，且属性为火时，则更新火圈位置，更新两个计时器
    if launcherId == self._uuid and elementType == 1 then
        self.magicPos = self._proxy:GetNpcPosition(self._proxy:GetFightTargetId(self._uuid))
        self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
        self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
        self.refreshTimer = self._proxy:GetNpcTime(self._uuid) + self.refreshCd  --计算火圈重新生成的计时器
        self.durTimer = self._proxy:GetNpcTime(self._uuid) + self.duration      --计算火圈生效的计时器
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015010:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015010:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015010
