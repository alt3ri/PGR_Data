local Base = require("Character/Char_8005")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---白龙（难度5）
---@class XChar8011 : XFightBase
local XChar8011 = XDlcScriptManager.RegCharScript(8011, "XChar8011", Base)

--region 函数: 脚本生命周期
function XChar8011:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    -- 启用白龙软狂暴机制
    self._enableSoftFury = true
    self._softFuryTime = 480

    --- DPS检测护盾值magic
    self._ultraDpsCheckProtectorMagic = 8005571
end

---@param dt number @ delta time
function XChar8011:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar8011:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8011:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
end

function XChar8011:Terminate()
    Base.Terminate(self)
end
--endregion

return XChar8011