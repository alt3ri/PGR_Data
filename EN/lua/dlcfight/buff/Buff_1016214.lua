local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016214 : XFightBase
local XBuffScript1016214 = XDlcScriptManager.RegBuffScript(1016214, "XBuffScript1016214", Base)

--效果说明：每1%【火伤】可提升自身1%【护盾强度】（此效果提升的上限为240%）
local ConfigMagicDict = {
    [1016214] = 1015029,
    [1016216] = 1015031,
    [1016218] = 1015131,
    [1016220] = 1015133,
    [1016222] = 1015433,
    [1016224] = 1015435,
}
local ConfigRuneDict = {
    [1016214] = 20028,
    [1016216] = 20030,
    [1016218] = 20130,
    [1016220] = 20132,
    [1016222] = 20432,
    [1016224] = 20434,
}
local ConfigAttribDict = {
    [1016214] = ENpcAttrib.Element1AmpP,
    [1016216] = ENpcAttrib.Element1AmpP,
    [1016218] = ENpcAttrib.Element2AmpP,
    [1016220] = ENpcAttrib.Element2AmpP,
    [1016222] = ENpcAttrib.Element3AmpP,
    [1016224] = ENpcAttrib.Element3AmpP,
}
local ConfigShieldId = {
    [1016214] = 1015227,
    [1016216] = 1015227,
    [1016218] = 1015229,
    [1016220] = 1015229,
    [1016222] = 1015231,
    [1016224] = 1015231,
}
local ConfigHealId = {
    [1016226] = 1015335,
    [1016228] = 1015335,
    [1016230] = 1015337,
    [1016232] = 1015337,
    [1016234] = 1015339,
    [1016236] = 1015339,
}

function XBuffScript1016214:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicDict[self._buffId]
    self.countAttrib = 100    -- 每获得x点额外属性
    self.magicEffect = 100      -- 其他属性转为本属性时的转换比
    self.attrib = ConfigAttribDict[self._buffId]
    self.addTimes = 240

    self.magicIdShield = ConfigShieldId[self._buffId]
    self.magicIdHeal = ConfigHealId[self._buffId]
    self.magicLevel = 1
    ------------执行------------
    self.runeId = ConfigRuneDict[self._buffId]
    self.magicIdA = self.magicIdShield
    self.magicIdB = self.magicIdHeal
    self.originAttrib = self._proxy:GetNpcAttribValue(self._uuid, self.attrib)
end

---@param dt number @ delta time
function XBuffScript1016214:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    -- 获取我方的当前属性
    self.currentAttrib = self._proxy:GetNpcAttribValue(self._uuid, self.attrib)
    -- 获取护盾转的buff层数
    self.buffStacksA = self._proxy:GetBuffStacks(self._uuid, self.magicIdA)
    -- 获取回复转的buff层数
    self.buffStacksB = self._proxy:GetBuffStacks(self._uuid, self.magicIdB)
    -- 计算差值
    self.attribChanged = self.currentAttrib - self.originAttrib - (self.buffStacksA + self.buffStacksB) * self.magicEffect
    -- 存一下当前值
    if self.currentAttrib == self.historyAttrib then
        return
    end
    self.historyAttrib = self.currentAttrib
    -- 加buff
    if self.attribChanged == 0 then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
    end

    if self.attribChanged > 0 then
        -- 获取本体buff层数
        self.newTimes = math.floor(self.attribChanged / self.countAttrib)
        -- 计算循环次数
        self.loopTimes = self.newTimes
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel,0,math.min(self.loopTimes,self.addTimes))
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
    else
        if self.attribChanged < 0 then
            -- 获取本体buff层数
            self.selfBuffStacks = self._proxy:GetBuffStacks(self._uuid, self.magicId)
            self.newTimes = math.floor(self.attribChanged / self.countAttrib)
            -- 扣buff
            if math.abs(self.newTimes) >= self.selfBuffStacks then
                self._proxy:RemoveBuff(self._uuid, self.magicId)
                self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
            else
                self._proxy:RemoveBuff(self._uuid, self.magicId)
                self.loopTimes = self.selfBuffStacks - math.abs(self.newTimes)
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel,0,self.loopTimes)
                self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
            end
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016214:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016214:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016214
