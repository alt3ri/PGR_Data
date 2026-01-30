local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015016 : XBuffBase
local XBuffScript1015016 = XDlcScriptManager.RegBuffScript(1015016, "XBuffScript1015016", Base)

--效果说明：越靠近目标，火伤越高。距离1m火伤加成100，10m火伤加成10，每秒判断1次，每1m变动10，最大10X，最小X

------------配置------------
local ConfigMagicIdDict = {
    [1015016] = 1015017,
    [1015052] = 1015053,
    [1015054] = 1015055,
    [1015056] = 1015057,
    [1016104] = 1016105
}
local ConfigRuneIdDict = {
    [1015016] = 20016,
    [1015052] = 20052,
    [1015054] = 20054,
    [1015056] = 20056,
    [1016104] = 20056
}

function XBuffScript1015016:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.deltaRange = 1     --每1m为标准修改Buff等级
    self.triggerCD = 1      --检查位置的CD，Buff持续时间为1s
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 1     --magic等级
    self.magicMaxLevel = 10 --magic最大等级
    self.runeId = ConfigRuneIdDict[self._buffId]    --宝珠id，用于ui和记录次数
    ------------执行------------
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
end

---@param dt number @ delta time 
function XBuffScript1015016:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --每秒判断1次距离，根据距离计算Buff等级
    --CD没有冷却好时，返回
    if self._proxy:GetNpcTime(self._uuid) < self.cdTimer then
        return
    end
    --获取距离
    local enemyId = self._proxy:GetFightTargetId(self._uuid)
    if enemyId == 0 then
        return
    end

    local range = self._proxy:GetNpcDistance(self._uuid, enemyId)
    self.magicLevel = self.magicMaxLevel + 1 - math.ceil(range / self.deltaRange)  --向上取整作为等级
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, math.min(self.magicLevel, self.magicMaxLevel))
    self._proxy:SetAutoChessGemTriggerState(self._uuid, self.runeId)       --触发一次宝珠ui
    self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015016:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015016:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015016
