local Base = require("Common/XFightBase")

---@class XBuffScript1015343 : XFightBase
local XBuffScript1015343 = XDlcScriptManager.RegBuffScript(1015343, "XBuffScript1015343", Base)

--效果说明：每次恢复生命值时，有10%概率在自己脚下召唤一个区域，角色处在区域内时，提升100点【回复效率】，区域存在5s，该效果冷却时间为8s
function XBuffScript1015343:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015344
    self.magicLevel = 1
    self.assistTime = 5
    self.cd = 0
    self.cdTime = 8
    self.isAdd = false
    self.isPassed = false
    self.record = false
    ------------执行------------
    self.maxHp = self._proxy:GetNpcAttribMaxValue(self._uuid, ENpcAttrib.Life)
    self.historyHp = self.maxHp
end

---@param dt number @ delta time 
function XBuffScript1015343:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
    self.currentHp = self._proxy:GetNpcAttribValue(self._uuid, ENpcAttrib.Life)
    self.changeHp = self.currentHp - self.historyHp
    self.historyHp = self.currentHp

    local cdIsOk = self._proxy:GetNpcTime(self._uuid) >= self.cd

    if self.changeHp > 0 and cdIsOk then
        math.randomseed(os.time())
        local seed = math.random()
        if seed <= 0.1 then
            self.isPassed = true
        end
    else
        return
    end

    -- 触发了
    if self.isPassed and not self.record then
        -- 生成区域的位置
        self.addPos = self._proxy:GetNpcPosition(self._uuid)
        -- 记录添加时间
        self.addTime = self._proxy:GetNpcTime(self._uuid)
        -- cd更新
        self.cd = self.cdTime + self.addTime
        self.record = true
    end

    -- 当前有区域
    if self.record then
        -- 判断角色是否在区域内
        self.inArea = self._proxy:CheckNpcPositionDistance(self._uuid, self.addPos, 1, true)
        -- 获取当前时间
        self.currentTime = self._proxy:GetNpcTime(self._uuid)
        -- 已经添加buff在身上，就判断是否移除:出区域或超时移除
        if self.isAdd and not self.inArea or self.currentTime - self.addTime >= 5 then
            self._proxy:RemoveBuff(self._uuid, self.magicId)
            self.isAdd = false
            self.isPassed = false
            self.record = false
        end
        -- 如果身上没buff、在区域内、区域有时间，加buff
        if not self.isAdd and self.inArea and self.currentTime - self.addTime < 5 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self.isAdd = true
        end
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015343:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015343:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015343

    