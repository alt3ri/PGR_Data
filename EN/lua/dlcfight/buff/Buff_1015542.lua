local Base = require("Common/XFightBase")

---@class XBuffScript1015542 : XFightBase
local XBuffScript1015542 = XDlcScriptManager.RegBuffScript(1015542, "XBuffScript1015542", Base)


--效果说明：自身血量低于30/20/10%时，受到伤害降低10/20/30%

function XBuffScript1015542:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015543
    self.magicKind = 1015543
    self.magicLevel = 1
    self.hpTable = { 0.2, 0 }
    self.magicLevelTable = { 1 }
    self.isAddTable = { false }
    ------------执行------------
    self.runeId = self.magicId - 1015000 + 20000 - 1

end

---@param dt number @ delta time
function XBuffScript1015542:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    self.percentHp = self._proxy:GetNpcAttribRate(self._uuid, ENpcAttrib.Life)
    -- 不到生命百分比就移除buff
    if self.percentHp > self.hpTable[1] and self._proxy:CheckBuffByKind(self._uuid, self.magicKind) then
        self._proxy:RemoveBuff(self._uuid, self.magicKind)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
        return
    end
    -- 生命够百分比，开始遍历
    for i in ipairs(self.magicLevelTable) do
        -- 移除标记
        if self.percentHp > self.hpTable[i] or self.percentHp <= self.hpTable[i + 1] and self.isAddTable[i] then
            self.isAddTable[i] = false
        end

        -- 加buff
        if self.percentHp <= self.hpTable[i] and self.percentHp > self.hpTable[i + 1] and not self.isAddTable[i] then
            self.magicLevel = self.magicLevelTable[i]
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
            self._proxy:AddAutoChessGemTriggerRecord(self._uuid, self.runeId, 1)  --记录一次触发
            self.isAddTable[i] = true
        end
    end
end

--region EventCallBack
function XBuffScript1015542:InitEventCallBackRegister()

end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015542:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015542:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015542

    