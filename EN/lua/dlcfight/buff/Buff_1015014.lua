local Base = require("Common/XFightBase")

---@class XBuffScript1015014 : XFightBase
local XBuffScript1015014 = XDlcScriptManager.RegBuffScript(1015014, "XBuffScript1015014", Base)

--效果说明：疲劳阶段，【回复效率】增加100点
function XBuffScript1015014:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015015
    self.magicLevel = 1
    self.tiredBuff = 1010029
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015014:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015014:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
end

function XBuffScript1015014:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    --不是疲劳标记就返回
    if buffId ~= self.tiredBuff then
        return
    end
    --添加一次buff
    self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015014:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015014:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015014

    