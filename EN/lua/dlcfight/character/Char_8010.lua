local Base = require("Character/Char_8005")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---白龙（难度4）
---@class XChar8010 : XFightBase
local XChar8010 = XDlcScriptManager.RegCharScript(8010, "XChar8010", Base)

--region 函数: 脚本生命周期
function XChar8010:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    -- 启用白龙软狂暴机制
    self._enableSoftFury = true
    self._softFuryTime = 360

    --- DPS检测护盾值magic
    self._ultraDpsCheckProtectorMagic = 8005570
end

---@param dt number @ delta time
function XChar8010:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar8010:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8010:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
end

function XChar8010:Terminate()
    Base.Terminate(self)
end
--endregion

return XChar8010