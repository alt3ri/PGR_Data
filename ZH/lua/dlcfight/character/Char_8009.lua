local Base = require("Character/Char_8005")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---白龙（难度3）
---@class XChar8009 : XFightBase
local XChar8009 = XDlcScriptManager.RegCharScript(8009, "XChar8009", Base)

--region 函数: 脚本生命周期
function XChar8009:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    -- 启用白龙软狂暴机制
    self._enableSoftFury = true
    self._softFuryTime = 330

    --- DPS检测护盾值magic
    self._ultraDpsCheckProtectorMagic = 8005569
end

---@param dt number @ delta time
function XChar8009:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar8009:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8009:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
end

function XChar8009:Terminate()
    Base.Terminate(self)
end
--endregion

return XChar8009