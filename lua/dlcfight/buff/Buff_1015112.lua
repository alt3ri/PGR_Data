local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015112 : XBuffBase
local XBuffScript1015112 = XDlcScriptManager.RegBuffScript(1015112, "XBuffScript1015112", Base)

--效果说明：出生时所在位置生成一个半径3m的雷圈，角色处于雷圈内时获得【雷属性伤害提升】X%（仅对自身生效）

------------配置------------
local ConfigMagicIdDict = {
    [1015112] = 1015113,
    [1015148] = 1015149,
    [1015150] = 1015151,
    [1015152] = 1015153
}
local ConfigRuneIdDict = {
    [1015112] = 20112,
    [1015148] = 20148,
    [1015150] = 20150,
    [1015152] = 20152
}

function XBuffScript1015112:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.range = 3          --半径
    self.triggerCD = 0.2    --检查位置的CD，表里Buff生效时间填的0.2，可覆盖自己
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 1     --magic等级
    self.magicPos = self._proxy:GetNpcPosition(self._uuid)  --雷圈生成位置
    self.isMagicApply = false
    self.runeId = ConfigRuneIdDict[self._buffId]

    ------------执行------------

    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --计算宝珠CD的Timer
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --给目标添加特定类型的效果
end

---@param dt number @ delta time 
function XBuffScript1015112:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    --仅开局1次，生成雷圈位置
    if not self.isMagicApply then
        self.magicPos = self._proxy:GetNpcPosition(self._uuid)  --雷圈生成位置
        self._proxy:SetAutoChessGemActiveState(self._uuid,self.runeId)
        self.isMagicApply = true
    end
    --如果CD没好就返回
    if self._proxy:GetNpcTime(self._uuid) < self.cdTimer then
        return
    end
    --检查自己与出生点的距离是否满足半径需求，满足则更新buff
    if self._proxy:CheckNpcPositionDistance(self._uuid, self.magicPos, self.range, true) then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel) --更新Buff
    end
    self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD  --更新宝珠CD的Timer
end

--region EventCallBack
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015112:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015112:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015112
