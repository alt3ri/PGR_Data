local Base = require("Character/FightCharBase/XDlcPartnerBase")
local SkillConfig = require("TempSkillConfigs/SkillConfig_8052")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")

---70教学关AI
---@class XChar1602 : XDlcPartnerBase
local XChar1602 = XDlcScriptManager.RegCharScript(1602, "XChar1602", Base)

---伙伴初始化
function XChar1602:PartnerInit()
    --初始设置自己变成斧形态
    self._proxy:SetNpcAnimationLayer(self._uuid,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,105200,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,105201,1)
    self._proxy:ApplyMagic(self._uuid,self._uuid,105205,1)
    
end

---在读配置前的脚本配置
function XChar1602:PartnerScriptConfigBeforeReadConfig()
    self.partnerId = 1602 --设置
end

return XChar1602