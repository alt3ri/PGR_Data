local Base = require("Common/XFightBase")

---@class XBuffScript1015210 : XFightBase
local XBuffScript1015210 = XDlcScriptManager.RegBuffScript(1015210, "XBuffScript1015210", Base)


--效果说明：每获得3次护盾，可以使下一个护盾获得200点临时护盾强度。

function XBuffScript1015210:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015211
    self.buffKind = 1015211
    self.magicLevel = 1
    self.count = 0
    self.isAdd = false
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015210:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015210:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddProtector)           -- OnNpcAddBuffEvent
end

function XBuffScript1015210:XNpcAddProtectorArgs(LauncherId, TargetId, Value, TotalValue, MagicId)
    if TargetId == self._uuid then
        -- 统计护盾加的次数
        self.count = self.count + 1
        -- 前2次技能不加
        if self.count <= 2 then
            return
        else
            -- 第3次加护盾，生效buff
            if self.count == 3 then
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
                self.isAdd = true
            end
        end
        -- 第4次加护盾之后，移除buff
        if self.isAdd and self.count == 4 then
            self._proxy:RemoveBuff(self._uuid, self.buffKind)
            self.isAdd = false
            self.count = 0
        end
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015210:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015210:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015210

    