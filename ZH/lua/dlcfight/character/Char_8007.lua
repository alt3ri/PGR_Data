local Base = require("Character/Char_8005")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---白龙（难度1）
---@class XChar8007 : XFightBase
local XChar8007 = XDlcScriptManager.RegCharScript(8007, "XChar8007", Base)

--region 函数: 脚本生命周期
function XChar8007:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    -- 禁止白龙软狂暴机制
    self._enableSoftFury = false
end

---@param dt number @ delta time
function XChar8007:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar8007:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8007:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
end

function XChar8007:Terminate()
    Base.Terminate(self)
end
--endregion

return XChar8007