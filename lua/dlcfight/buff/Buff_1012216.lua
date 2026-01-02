local Base = require("Common/XFightBase")
---@class XBuffScript1012216 : XFightBase
local XBuffScript1012216 = XDlcScriptManager.RegBuffScript(1012216, "XBuffScript1012216", Base)

function XBuffScript1012216:Init() --初始化
    Base.Init(self)
    self.kaiguan1 = true
    self.kaiguan2 = true
end

---@param dt number @ delta time
function XBuffScript1012216:Update(dt)
    Base.Update(self, dt)

    if self.kaiguan1 == true then
        local biaoji1 =  self._proxy:CheckBuffByKind(self._uuid, 1016411)
        local biaoji2 =  self._proxy:CheckBuffByKind(self._uuid, 1016412)
        local biaoji3 =  self._proxy:CheckBuffByKind(self._uuid, 1016413)
        local biaoji4 =  self._proxy:CheckBuffByKind(self._uuid, 1016414)
        local biaoji5 =  self._proxy:CheckBuffByKind(self._uuid, 1016415)
        if biaoji1 == true  or biaoji2 == true or biaoji3 == true or biaoji4 == true or biaoji5 == true  then  -- 拥有任意标记buff时
            self.kaiguan1 = false
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1012319, 1) --旧buff删除
        end
    end


    if self._proxy:CheckBuffByKind(self._uuid, 1010029) and  self.kaiguan2 == true then --进入疲劳状态后
        self.kaiguan2 = false
        local biaoji1 =  self._proxy:CheckBuffByKind(self._uuid, 1016411)
        local biaoji2 =  self._proxy:CheckBuffByKind(self._uuid, 1016412)
        local biaoji3 =  self._proxy:CheckBuffByKind(self._uuid, 1016413)
        local biaoji4 =  self._proxy:CheckBuffByKind(self._uuid, 1016414)
        local biaoji5 =  self._proxy:CheckBuffByKind(self._uuid, 1016415)
        if biaoji1 == true then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1012220, 1) --旧buff删除，替换新强化buff
        elseif biaoji2 == true then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1012221, 1) --旧buff删除，替换新强化buff
        elseif biaoji3 == true then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1012222, 1) --旧buff删除，替换新强化buff
        elseif biaoji4 == true then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1012223, 1) --旧buff删除，替换新强化buff
        elseif biaoji5 == true then
            self._proxy:ApplyMagic(self._uuid, self._uuid, 1012224, 1) --旧buff删除，替换新强化buff
        end
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
