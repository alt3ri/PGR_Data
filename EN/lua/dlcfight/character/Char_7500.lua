local Base = require("Character/FightCharBase/XSGMonsterBase")
local SkillConfig = require("TempSkillConfigs/SkillConfig_8052")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
--local SkillForMonster = require("TempSkillConfigs/SkillConfigsForMonster")
---2.0骨王
---@class XChar7500 : XRelinkMonsterBase
local XChar7500 = XDlcScriptManager.RegCharScript(7500, "XChar7500", Base)

--region 怪物配置
---配置主入口


--function XChar7500:Update(dt)
--    self._proxy:SetNpcMoveDirection(self._uuid,ENpcMoveDirection.Backward)
--    self._proxy:SetNpcMoveType(self._uuid,ENpcMoveType.Walk)
--    local pos = self._proxy:GetNpcPosition(33)
--    self._proxy:MoveToPosition(self._uuid,pos)
--end

----更新战斗模式时
--function XChar7500:UpdateCombatMode(dt)
--    XLog.Warning("战斗模式已启动")
--end

---技能测试配置
function XChar7500:SkillTestConfig()
    self:SetSkillTestActive(true)
    --self.skillTestType = Base.SkillTestType.CustomFuc --开启了就会只执行这个函数里面的内容
    --self:InitSkillCd(805201,0,0) --格挡
    
    self.skillTestId = 7500001
    self.skillTestInitialCd = 0--测试初始CD
    --self.skillTestInitialCd = 1.5--测试初始CD
    self.skillTestCd = 5
    --self:SetOverDriveValueFull()--满OD
end



return XChar7500