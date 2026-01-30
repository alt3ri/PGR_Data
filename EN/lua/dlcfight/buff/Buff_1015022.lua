local Base = require("Common/XFightBase")

---@class XBuffScript1015022 : XFightBase
local XBuffScript1015022 = XDlcScriptManager.RegBuffScript(1015022, "XBuffScript1015022", Base)

--效果说明：每次造成火伤，提升自身10火伤，上限100，判断cd为1s
function XBuffScript1015022:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015023
    self.magicKind = 1015023
    self.magicLevel = 1
    self.magicCd = 0
    self.skillCd = 1
    self.count = 1
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015022:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015022:InitEventCallBackRegister()
    --按需求解除注释进行注册
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage)            -- OnNpcDamageEvent
end

function XBuffScript1015022:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical)
    -- 对方受击
    if targetId ~= self._uuid then
        self.currentTime = self._proxy:GetNpcTime(self._uuid) - self.magicCd

        if elementType == 1 and self.currentTime >= 0 and self.count <= 10 then
            self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            self.magicCd = self._proxy:GetNpcTime(self._uuid) + self.skillCd
            self.count = self.count + 1
        end
    end
end
--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015022:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015022:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015022

    