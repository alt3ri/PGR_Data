local Base = require("Common/XFightBase")

---@class XBuffScript1015028 : XFightBase
local XBuffScript1015028 = XDlcScriptManager.RegBuffScript(1015028, "XBuffScript1015028", Base)

--效果说明：每2%【火伤】可提升自身1%【护盾强度】（此效果提升的上限为200%）
function XBuffScript1015028:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015029
    self.magicKind = 1015029
    self.countAttrib = 200    -- 每获得x点额外属性
    self.magicEffect = 100      -- 其他属性转为本属性时的转换比
    self.attrib = ENpcAttrib.Element1AmpP
    self.addTimes = 120

    self.magicIdShield = 1015227
    self.magicIdHeal = 1015335
    self.magicLevel = 1
    ------------执行------------
    self.runeId = self.magicId - 1015000 + 20000 - 1
    self.magicIdA = self.magicIdShield
    self.magicIdB = self.magicIdHeal
    self.originAttrib = self._proxy:GetNpcAttribValue(self._uuid, self.attrib)
end

---@param dt number @ delta time
function XBuffScript1015028:Update(dt)
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
        self._proxy:RemoveBuff(self._uuid, self.magicKind)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
    end

    if self.attribChanged > 0 then
        -- 获取本体buff层数
        self.newTimes = math.floor(self.attribChanged / self.countAttrib)
        -- 计算循环次数
        self.loopTimes = self.newTimes
        self._proxy:RemoveBuff(self._uuid, self.magicKind)
        self._proxy:ApplyMagic(self._uuid,self._uuid,self.magicId,self.magicLevel,0,math.min(self.loopTimes,self.addTimes))
        self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
    else
        if self.attribChanged < 0 then
            -- 获取本体buff层数
            self.selfBuffStacks = self._proxy:GetBuffStacks(self._uuid, self.magicId)
            self.newTimes = math.floor(self.attribChanged / self.countAttrib)
            -- 扣buff
            if math.abs(self.newTimes) >= self.selfBuffStacks then
                self._proxy:RemoveBuff(self._uuid, self.magicKind)
                self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
            else
                self._proxy:RemoveBuff(self._uuid, self.magicKind)
                self.loopTimes = self.selfBuffStacks - math.abs(self.newTimes)
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel,0,self.loopTimes)
                self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
            end
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015028:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015028:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015028
