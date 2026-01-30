local Base = require("Common/XFightBase")

---@class XBuffScript1015208 : XFightBase
local XBuffScript1015208 = XDlcScriptManager.RegBuffScript(1015208, "XBuffScript1015208", Base)

--效果说明：提高30点【护盾强度】，根据敌人减益数量，额外提【护盾强度】（上限100点）
function XBuffScript1015208:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.buffKind = 200
    self.magicId = 1015209
    self.magicKind = 1015209
    self.magicLevel = 1
    self.magicLevelTable = { 1, 2, 3, 4, 5, 6, 7, 8 }
    self.buffNumTable = { 0, 1, 2, 3, 4, 5, 6, 7 }
    self.isAddTable = { false, false, false, false, false, false, false, false }

    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015208:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    local enemyId = self._proxy:GetFightTargetId(self._uuid)

    if enemyId == 0 then
        --没有目标的时候下面不执行
        return
    end

    self.buffNum = self._proxy:GetBuffCountByKind(enemyId, self.buffKind)
    for i in ipairs(self.magicLevelTable) do
        if self.buffNum >= self.buffNumTable[i] and self.buffNum < self.buffNumTable[i + 1] and not self.isAddTable[i] then
            self.magicLevel = self.magicLevelTable[i]
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self.isAddTable[i] = true
        end
    end

    -- 已经加过buff之后如果增益减少了，扣buff
    for i = #self.magicLevelTable, 1, -1 do
        if self.isAddTable[i] and self.buffNum < self.buffNumTable[i] then
            if i == 1 then
                self._proxy:RemoveBuff(self._uuid, self.magicKind)
                self.isAddTable[i] = false
                return
            else
                self._proxy:RemoveBuff(self._uuid, self.magicKind)
                self.magicLevel = self.magicLevelTable[i - 1]
                self.isAddTable[i] = false
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            end
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015208:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015208:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015208

    