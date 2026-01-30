local Base = require("Character/Char_8005")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local RelinkStateMachine = require("Tools/StateMachine/RelinkStateMachine")

---白龙（难度5）
---@class XChar8012 : XFightBase
local XChar8012 = XDlcScriptManager.RegCharScript(8012, "XChar8012", Base)

--region 函数: 脚本生命周期
function XChar8012:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)

    -- 启用白龙软狂暴机制
    self._enableSoftFury = false
    self._softFuryTime = 480

    --- DPS检测护盾值magic
    self._ultraDpsCheckProtectorMagic = 8005571
end

---@param dt number @ delta time
function XChar8012:Update(dt)
    Base.Update(self, dt)
end

---@param eventType number
---@param eventArgs userdata
function XChar8012:HandleEvent(eventType, eventArgs)
    Base.HandleEvent(self, eventType, eventArgs)
end

function XChar8012:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
end

function XChar8012:Terminate()
    Base.Terminate(self)
end
--endregion

function XChar8012:InitCoreCombatSkillCastSystem()
    Base.InitCoreCombatSkillCastSystem(self)

    -- 不给放技能
    self._intendSkillSeqs = {
        [1] = {
            [1] = {
            },
            [2] = {
                {1, 0},     -- OD吼
                {27, 0}
            }
        },
        [2] = {
            [1] = {
            },
            [2] = {
                { 1, 0 }, -- OD吼
            }
        },
        [3] = {
            [1] = {
                { 22, 0 },
            },
            [2] = {
                { 1, 0 },
                { 22, 0 },
            }
        }
    }
end

return XChar8012