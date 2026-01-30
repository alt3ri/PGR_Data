local Base = require("Common/XFightBase")
---@class XBuffScript1012216 : XFightBase
local XBuffScript1012216 = XDlcScriptManager.RegBuffScript(1012216, "XBuffScript1012216", Base)

function XBuffScript1012216:Init() --初始化
    Base.Init(self)
    self.kaiguan = true
    self._proxy:AddTimerTask(10, function()--延迟5秒后，开始以下逻辑
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012219, 1) --强化1级
    end)
    self._proxy:AddTimerTask(15, function()--延迟15秒后，开始以下逻辑
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012220, 1) --强化2级
    end)
    self._proxy:AddTimerTask(20, function()--延迟20秒后，开始以下逻辑
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012221, 1) --强化3级
    end)
    self._proxy:AddTimerTask(25, function()--延迟25秒后，开始以下逻辑
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012222, 1) --强化4级
    end)
    self._proxy:AddTimerTask(30, function()--延迟30秒后，开始以下逻辑
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012223, 1) --强化5级
    end)
    self._proxy:AddTimerTask(35, function()--延迟35秒后，开始以下逻辑
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012224, 1) --强化6级
    end)
end

---@param dt number @ delta time
function XBuffScript1012216:Update(dt)
    Base.Update(self, dt)
    if self._proxy:CheckBuffByKind(self._uuid, 1010029) and  self.kaiguan == true then
        self.kaiguan = false
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012315, 1) --旧buff删除
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012316, 1) --旧buff删除
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012317, 1) --旧buff删除
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012318, 1) --旧buff删除
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012319, 1) --旧buff删除
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012320, 1) --旧buff删除
        self._proxy:ApplyMagic(self._uuid, self._uuid, 1012225, 1) --疲劳强化
    end
end

---@param eventType number
---@param eventArgs userdata
function XBuffScript1012216:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1012216:Terminate()
    Base.Terminate(self)
end

return XBuffScript1012216
