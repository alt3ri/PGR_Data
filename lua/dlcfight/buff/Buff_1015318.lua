local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1015318 : XBuffBase
local XBuffScript1015318 = XDlcScriptManager.RegBuffScript(1015318, "XBuffScript1015318", Base)

--效果说明：当生命值百分比低于对方时，自身【回复效率】额外增加50点

------------配置------------
local ConfigMagicIdDict = {
    [1015318] = 1015319,
    [1015359] = 1015360,
    [1015361] = 1015362,
    [1015363] = 1015364,
    [1016130] = 1016131
}
local ConfigRuneIdDict = {
    [1015318] = 20318,
    [1015359] = 20359,
    [1015361] = 20361,
    [1015363] = 20363,
    [1016130] = 20363
}

function XBuffScript1015318:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicIdDict[self._buffId]  --增伤Magic
    self.magicLevel = 1
    self.runeId = ConfigRuneIdDict[self._buffId] --宝珠id，用于ui和记录次数
    self.isBuffActive = false
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015318:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    -- 获取我方/敌方的当前属性
    self.enemyId = self._proxy:GetFightTargetId(self._uuid)

    if self.enemyId == 0 then
        --没有目标的时候下面不执行
        return
    end

    -- 计算百分比
    self.percentSelf = self._proxy:GetNpcAttribRate(self._uuid,ENpcAttrib.Life)
    self.percentEnemy = self._proxy:GetNpcAttribRate(self.enemyId,ENpcAttrib.Life)
    -- 加buff
    if self.percentSelf < self.percentEnemy and (not self.isBuffActive) then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
        self.isBuffActive = true
    elseif self.percentSelf >= self.percentEnemy and self.isBuffActive then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
        self.isBuffActive = false
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015318:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015318:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015318

    