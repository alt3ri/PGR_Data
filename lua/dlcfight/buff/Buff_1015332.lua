local Base = require("Common/XFightBase")

---@class XBuffScript1015332 : XFightBase
local XBuffScript1015332 = XDlcScriptManager.RegBuffScript(1015332, "XBuffScript1015332", Base)

--效果说明：自身周围2m内存在敌人时，获得回复效率20/s，上限100点，不存在时清空
function XBuffScript1015332:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015333
    self.magicLevel = 1
    self.addRound = 2
    self.isAdd = false
    ------------执行------------

end

---@param dt number @ delta time
function XBuffScript1015332:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------

    self.enemyId = self._proxy:GetFightTargetId(self._uuid)

    if self.enemyId == 0 then
        --没有目标的时候下面不执行
        return
    end

    -- 判断是否在2m内
    self.isAround = self._proxy:CheckNpcDistance(self._uuid, self.enemyId, self.addRound)

    -- 0到1加buff
    if self.isAround and not self.isAdd then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.addTime = self._proxy:GetNpcTime(self._uuid)
        self.isAdd = true
        self.count = 1
    end

    -- 周围没人清buff
    if not self.isAround and self.isAdd then
        self._proxy:RemoveBuff(self._uuid, self.magicId)
        self.isAdd = false
    end

    -- 叠层
    if self.isAround and self.isAdd and self.count <= 5 then
        local currentTime = self._proxy:GetNpcTime(self._uuid)
        if currentTime - self.addTime >= 0.5 then
            -- 叠层
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self.count = self.count + 1
            self.addTime = currentTime
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015332:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015332:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015332