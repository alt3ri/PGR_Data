local Base = require("Character/Char_8005")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---白龙（难度2）
---@class XChar8008 : XFightBase
local XChar8008 = XDlcScriptManager.RegCharScript(8008, "XChar8008", Base)

--region 函数: 脚本生命周期
function XChar8008:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    -- 禁止白龙软狂暴机制
    self._enableSoftFury = false

    --- DPS检测护盾值magic
    self._ultraDpsCheckProtectorMagic = 8005568
end

---@param dt number @ delta time
function XChar8008:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar8008:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8008:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
end

function XChar8008:Terminate()
    Base.Terminate(self)
end
--endregion

return XChar8008