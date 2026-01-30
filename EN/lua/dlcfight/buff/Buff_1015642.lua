local Base = require("Common/XFightBase")

---@class XBuffScript1015642 : XFightBase
local XBuffScript1015642 = XDlcScriptManager.RegBuffScript(1015642, "XBuffScript1015642", Base)


--效果说明：自身血量高于70%/80%/90%时，造成伤害提升40/50/60%

function XBuffScript1015642:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId1 = 1015643
    self.magicKind = 1015642
    self.magicKind1 = 1015643
    self.magicId2 = 1015644
    self.magicKind2 = 1015644
    self.magicId3 = 1015645
    self.magicKind3 = 1015645
    self.magicId4 = 1015646
    self.magicKind4 = 1015646
    self.magicLevel = 1
    self.hpTable = { 0.8, 1 }
    self.hpTableSp = { 0.4, 1 }
    self.magicKindSp = 1015648
    self.magicLevelTable = { 1 }
    self.isAddTable = { false }
    ------------执行------------
    self.runeId = self.magicId1 - 1015000 + 20000 - 1

end

---@param dt number @ delta time 
function XBuffScript1015642:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    if self._proxy:CheckBuffByKind(self._uuid, self.magicKindSp) then
        self.hpTable = self.hpTableSp
    end

    self.percentHp = self._proxy:GetNpcAttribRate(self._uuid, ENpcAttrib.Life)
    -- 不到生命百分比就移除buff
    if self.percentHp < self.hpTable[1] and self._proxy:CheckBuffByKind(self._uuid, self.magicKind) then
        self._proxy:RemoveBuff(self._uuid, self.magicKind1)
        self._proxy:RemoveBuff(self._uuid, self.magicKind2)
        self._proxy:RemoveBuff(self._uuid, self.magicKind3)
        self._proxy:RemoveBuff(self._uuid, self.magicKind4)
        self._proxy:SetAutoChessGemData(self._uuid, self.runeId, 0, 0)
        -- 移除时重置状态
        for i in ipairs(self.magicLevelTable) do
            self.isAddTable[i] = false
        end
        -- 不满足条件省略下方逻辑
        return
    end
    -- 生命够百分比，开始遍历
    for i in ipairs(self.magicLevelTable) do
        -- 移除标记
        if self.percentHp < self.hpTable[i] or self.percentHp >= self.hpTable[i + 1] and self.isAddTable[i] then
            self.isAddTable[i] = false
        end

        -- 加buff
        if self.percentHp >= self.hpTable[i] and self.percentHp < self.hpTable[i + 1] and not self.isAddTable[i] then
            self.magicLevel = self.magicLevelTable[i]
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId1, self.magicLevel)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId2, self.magicLevel)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId3, self.magicLevel)
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId4, self.magicLevel)
            self._proxy:SetAutoChessGemActiveState(self._uuid, self.runeId)
            self.isAddTable[i] = true
        end
    end
end

--region EventCallBack
function XBuffScript1015642:InitEventCallBackRegister()

end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015642:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015642:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015642

    