local Base = require("Common/XFightBase")

---@class XBuffScript1015302 : XFightBase
local XBuffScript1015302 = XDlcScriptManager.RegBuffScript(1015302, "XBuffScript1015302", Base)

--效果说明：每次为自身添加增益，可获得10点【回复效率】（上限100点）
function XBuffScript1015302:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.triggerCD = 3
    self.activeBuff = { 100 }
    self.magicId = 1015303
    self.buffId = 1015302
    self.magicLevel = 1
    self.count = 1
    ------------执行------------
    self.cdTimer = 0
end

---@param dt number @ delta time 
function XBuffScript1015302:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015302:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- OnNpcAddBuffEvent
end

function XBuffScript1015302:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUID)
    if self._proxy:GetNpcTime(self._uuid) - self.cdTimer >= 0 then
        if npcUUID == self._uuid and self.count <= 10 then
            -- 只有技能buff才会触发
            if self._proxy:CheckBuffKinds(buffId, self.activeBuff) then
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
                self.cdTimer = self._proxy:GetNpcTime(self._uuid) + self.triggerCD
                self.count = self.count + 1
            end
        end
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015302:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015302:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015302

    