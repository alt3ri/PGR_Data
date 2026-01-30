local Base = require("Common/XFightBase")

---@class XBuffScript1015216 : XFightBase
local XBuffScript1015216 = XDlcScriptManager.RegBuffScript(1015216, "XBuffScript1015216", Base)

--效果说明：持有护盾时，护盾每减少100点，提升自身5点【护盾强度】，上限50点，护盾消失后加成消失
function XBuffScript1015216:Init()
    --初始化
    Base.Init(self)
    ------------配置------------
    self.magicId = 1015217
    self.buffKind = 1015217
    self.magicLevel = 1
    self.count = 1
    self.shieldAcc = 0
    self.numChange = 100
    ------------执行------------
end

---@param dt number @ delta time 
function XBuffScript1015216:Update(dt)
    --每帧执行
    Base.Update(self, dt)
    ------------执行------------
end

--region EventCallBack
function XBuffScript1015216:InitEventCallBackRegister()
    self._proxy:RegisterEvent(EWorldEvent.NpcChangeProtector)
end

function XBuffScript1015216:XNpcChangeProtectorArgs(LauncherId, TargetId, Value, TotalValue)
    -- 己方的护盾减少
    if TargetId == self._uuid and Value < 0 then
        -- 护盾还在时
        if TotalValue > 0 then
            self.shieldAcc = self.shieldAcc + math.abs(Value)
            -- 计算损失了多少个100
            self.magicLevel = math.floor(self.shieldAcc / self.numChange)
            if self.magicLevel >= 1 then
                self._proxy:ApplyMagic(self._uuid, self._uuid, self.magicId, self.magicLevel)
            end
        else
            -- 护盾没了重置
            self.RemoveBuff(self._uuid, self.buffKind)
            self.shieldAcc = 0
        end
    end
end

--endregion

---@param eventType number
---@param eventArgs userdata
function XBuffScript1015216:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XBuffScript1015216:Terminate()
    Base.Terminate(self)
end

return XBuffScript1015216

    