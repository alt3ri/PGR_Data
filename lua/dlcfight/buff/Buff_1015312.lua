local Base = require("Common/XFightBase")

---@class XBuffScript1015312 : XFightBase
local XBuffScript1015312 = XDlcScriptManager.RegBuffScript(1015312, "XBuffScript1015312", Base)


--效果说明：疲劳阶段，【回复效率】增加100点

function XBuffScript1015312:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015313
    self.magicLevel = 1
    self.tiredBuff = 1010029
    self.isAdd = false
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015312:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015312:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
end

function XBuffScript1015312:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if buffId ~= self.tiredBuff then
        return
    end

    if not self.isAdd then
        self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
        self.isAdd = true
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015312:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015312:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015312

    