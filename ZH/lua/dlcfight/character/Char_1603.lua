local Base = require("Character/FightCharBase/XDlcPartnerBase")
local SkillConfig = require("TempSkillConfigs/SkillConfig_8052")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")

---丽芙教学关AI
---@class XChar1603 : XDlcPartnerBase
local XChar1603 = XDlcScriptManager.RegCharScript(1603, "XChar1603", Base)

---在读配置前的脚本配置
function XChar1603:PartnerScriptConfigBeforeReadConfig()
    self.partnerId = 1603 --设置
end

return XChar1603