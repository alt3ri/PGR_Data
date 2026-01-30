local Base = require("Common/XFightBase")

---@class XBuffScript1015038 : XFightBase
local XBuffScript1015038 = XDlcScriptManager.RegBuffScript(1015038, "XBuffScript1015038", Base)


--效果说明：敌方生命值低于50%时，提升自身【火属性伤害提升】10点，每低10%，再提升自身【火属性伤害提升】10点

function XBuffScript1015038:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015039
    self.buffKind = 1015039
    self.magicLevel = 1
    self.hpTable = { 0.5, 0.4, 0.3, 0.2, 0.1, 0 }
    self.magicLevelTable = { 1, 2, 3, 4, 5 }
    self.isAddTable = { false, false, false, false, false }
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015038:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    self.targetId = self._proxy:GetFightTargetId(self._uuid)
    if self.targetId == 0 then
        return
    end

    self.percentHp = self._proxy:GetNpcAttribRate(self.targetId, ENpcAttrib.Life)
    if self.percentHp <= 0.5 and self.percentHp > 0 then
        -- 加buff
        for i in ipairs(self.hpTable) do
            if self.percentHp <= self.hpTable[i] and self.percentHp > self.hpTable[i + 1] and not self.isAddTable[i] then
                self.magicLevel = self.magicLevelTable[i]
                self.isAddTable[i] = true
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            end
        end
    end

    -- 已经加过buff之后如果回血了，扣buff
    for i = #self.magicLevelTable, 1, -1 do
        if self.isAddTable[i] and self.percentHp > self.hpTable[i] then
            if i == 1 then
                self._proxy:RemoveBuff(self._uuid, self.buffKind)
                self.isAddTable[i] = false
                return
            else
                self._proxy:RemoveBuff(self._uuid, self.buffKind)
                self.magicLevel = self.magicLevelTable[i - 1]
                self.isAddTable[i] = false
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            end
        end
    end
end

--region EventCallBack
function XBuffScript1015038:InitEventCallBackRegister()

end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015038:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015038:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015038

    