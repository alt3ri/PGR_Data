local Base = require("Buff/BuffBase/XBuffBase")

---@class XBuffScript1016226 : XBuffBase
local XBuffScript1016226 = XDlcScriptManager.RegBuffScript(1016226, "XBuffScript1016226", Base)

--效果说明：每获得1.25%额外【护盾强度/回复效率】，提升1%火/雷/冰伤，至多提升z%火/雷/冰伤
local ConfigMagicDict = {
    [1016226] = 1015227,
    [1016228] = 1015229,
    [1016230] = 1015231,
    [1016232] = 1015335,
    [1016234] = 1015337,
    [1016236] = 1015339,
}
local ConfigRuneDict = {
    [1016226] = 20226,
    [1016228] = 20228,
    [1016230] = 20230,
    [1016232] = 20335,
    [1016234] = 20337,
    [1016236] = 20339,
}
local ConfigAttribDict = {
    [1016226] = ENpcAttrib.ShieldAmpP,
    [1016228] = ENpcAttrib.ShieldAmpP,
    [1016230] = ENpcAttrib.ShieldAmpP,
    [1016232] = ENpcAttrib.HealAmpP,
    [1016234] = ENpcAttrib.HealAmpP,
    [1016236] = ENpcAttrib.HealAmpP,
}
local ConfigFireId = {
    [1016226] = 1015029,
    [1016228] = 1015029,
    [1016230] = 1015029,
    [1016232] = 1015031,
    [1016234] = 1015031,
    [1016236] = 1015031,
}
local ConfigThunderId = {
    [1016226] = 1015131,
    [1016228] = 1015131,
    [1016230] = 1015131,
    [1016232] = 1015133,
    [1016234] = 1015133,
    [1016236] = 1015133,
}
local ConfigIceId = {
    [1016226] = 1015433,
    [1016228] = 1015433,
    [1016230] = 1015433,
    [1016232] = 1015435,
    [1016234] = 1015435,
    [1016236] = 1015435,
}
function XBuffScript1016226:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = ConfigMagicDict[self._buffId]
    self.countAttrib = 125    -- 每获得x点额外属性
    self.magicEffect = 100    -- 其他属性转为本属性时的转换比
    self.attrib = ConfigAttribDict[self._buffId]
    self.addTimes = 240

    self.magicIdFire = ConfigFireId[self._buffId]
    self.magicIdThunder = ConfigThunderId[self._buffId]
    self.magicIdIce = ConfigIceId[self._buffId]
    self.magicLevel = 1
    ------------执行------------
    self.runeId = ConfigRuneDict[self._buffId]
    self.magicIdA = self.magicIdFire
    self.magicIdB = self.magicIdThunder
    self.magicIdC = self.magicIdIce
    self.originAttrib = self._proxy:GetNpcAttribValue(self._uuid, self.attrib)
end

---@param dt number @ delta time
function XBuffScript1016226:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    -- 获取我方的当前属性
    self.currentAttrib = self._proxy:GetNpcAttribValue(self._uuid, self.attrib)
    -- 获取火转护盾的buff层数
    self.buffStacksA = self._proxy:GetBuffStacks(self._uuid, self.magicIdA)
    -- 获取雷转护盾的buff层数
    self.buffStacksB = self._proxy:GetBuffStacks(self._uuid, self.magicIdB)
    -- 获取冰转护盾的buff层数
    self.buffStacksC = self._proxy:GetBuffStacks(self._uuid, self.magicIdC)
    -- 计算差值
    self.attribChanged = self.currentAttrib - self.originAttrib - (self.buffStacksA + self.buffStacksB + self.buffStacksC) * self.magicEffect
    -- 加buff
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
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel, 0, math.min(self.loopTimes, self.addTimes))
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
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel, 0, self.loopTimes)
                self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
            end
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1016226:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1016226:Terminate()
    Base.Terminate(self)
end

return XBuffScript1016226

