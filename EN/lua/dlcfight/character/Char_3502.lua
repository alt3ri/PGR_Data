local Base = require("Character/FightCharBase/XSGMonsterBase")
local SkillConfig = require("TempSkillConfigs/SkillConfig_8052")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
--local SkillForMonster = require("TempSkillConfigs/SkillConfigsForMonster")
---空花无人机
---@class XChar3502 : XRelinkMonsterBase
local XChar3502 = XDlcScriptManager.RegCharScript(3502, "XChar3502", Base)

--region 怪物配置
---配置主入口

--技能释放配置
function XChar3502:SkillCastConfig()
    self.selectSkillType = Base.SelectSkillType.CastGroup --按照技能释放组去放技能
    self.isOverDriveActive = false --关闭OD
    self.isBreakGaugeActive = false --关闭韧性
    self.basicDistanceReference = {5,15,20}
    ---------游荡配置---------
    self.haveWander = true --开启游荡逻辑
    self.wanderSkills = { --前后左右的游荡技能
        front = 350290,
        back = 350291,
        left = 350292,
        right = 350293,
    }
    self.wanderWeights = { --游荡判断权重
        near = { --近距离攻击或游荡
            attack = 50,
            front = 0,
            back = 0,
            left = 0,
            right = 0,
            daze = 50,
        },
        mid = {--中距离后退或左右游荡
            attack = 50,
            front = 0,
            back = 0,
            left = 0,
            right = 0,
            daze = 50,
        },
        far = {--远距离攻击或向前游荡
            attack = 50,
            front = 0,
            back = 0,
            left = 0,
            right = 0,
            daze = 50,
        }
    }

    self:SetSelfAiDelayOpen(4)

    self.castGroup= {
        --距离参考{
        --远距离：15
        --中距离：8
        --近距离：5
        --}
        {--普通释放组
            [350201]=10, --回旋后摆
            [350204]=10, --冲撞
        }
    }
    self.isOpenChase = true
end

--
--function XChar3502:Update(dt)
--    Base.Update(self,dt)
--    self.skillTestId = 350204
--end
--
-----技能测试配置
--function XChar3502:SkillTestConfig()
--    self:SetSkillTestActive(true)
--    --self.skillTestType = Base.SkillTestType.CustomFuc --开启了就会只执行这个函数里面的内容
--    --self:InitSkillCd(805201,0,0) --格挡
--
--    self.skillTestId = 350204
--    self.skillTestInitialCd = 10--测试初始CD
--    --self.skillTestInitialCd = 1.5--测试初始CD
--    self.skillTestCd = 5
--    --self:SetOverDriveValueFull()--满OD
--end
--
function XChar3502:Terminate()
    Base.Terminate(self)
    local efPos = self._proxy:GetNpcPosition(self._uuid)
    local efRot = self._proxy:GetNpcRotation(self._uuid)
    self._proxy:CreateCommonEffect("FxHeiBangDeath",efPos,efRot) --创建尸体销毁特效
end

return XChar3502