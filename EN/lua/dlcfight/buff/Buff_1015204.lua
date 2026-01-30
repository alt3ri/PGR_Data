local Base = require("Common/XFightBase")

---@class XBuffScript1015204 : XFightBase
local XBuffScript1015204 = XDlcScriptManager.RegBuffScript(1015204, "XBuffScript1015204", Base)

--效果说明：疲劳阶段，【护盾强度】增加50点
function XBuffScript1015204:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015205
    self.magicLevel = 1
    self.tiredBuff = 1010029
    self.isAdd = false
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015204:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015204:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
end

function XBuffScript1015204:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
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
function XBuffScript1015204:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015204:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015204

    