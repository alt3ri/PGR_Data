local Base = require("Character/FightCharBase/XSGMonsterBase")
local SkillConfig = require("TempSkillConfigs/SkillConfig_8052")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
--local SkillForMonster = require("TempSkillConfigs/SkillConfigsForMonster")
---空花无人机
---@class XChar3503 : XRelinkMonsterBase
local XChar3503 = XDlcScriptManager.RegCharScript(3503, "XChar3503", Base)

--region 怪物配置
---配置主入口

--技能释放配置
function XChar3503:SkillCastConfig()
    self.isOverDriveActive = false --关闭OD
    self.isBreakGaugeActive = false --关闭韧性
    self.basicDistanceReference = {5,15,20}
    self.isOpenChase = true --开启追随
    ---------游荡配置---------
    self.haveWander = true --开启游荡逻辑(包括发呆)
    self.wanderSkills = { --前后左右的游荡技能
        front = 350390,
        back = 350391,
        left = 350392,
        right = 350393,
    }
    self.wanderWeights = { --游荡判断权重
        near = { --近距离攻击或游荡
            attack = 50,
            front = 0,
            back = 80,
            left = 30,
            right = 30,
            daze = 20,
        },
        mid = {--中距离后退或左右游荡
            attack = 50,
            front = 0,
            back = 0,
            left = 60,
            right = 60,
            daze = 0,
        },
        far = {--远距离攻击或向前游荡
            attack = 50,
            front = 0,
            back = 0,
            left = 80,
            right = 80,
            daze = 0,
        }
    }
    self.dazeTimes = {1.5,2}
    self.wanderTimes = {1.6,2}
    self.selectSkillType = Base.SelectSkillType.CastGroup --按照技能释放组去放技能
    self.castGroup= {
        --距离参考{
        --远距离：15
        --中距离：8
        --近距离：5
        {--普通释放组
            [350301]=10, --狙击射击
            [350302]=10, --后跳下落
            [350303]=10, --闪避反击（左滚）
            [350304]=10, --闪避反击（右滚）
        },
    }
    self.isOpenChase = true
    self:SetSelfAiDelayOpen(0.3)
end

--function XChar3503:Update(dt)
--    self._proxy:SetNpcMoveDirection(self._uuid,ENpcMoveDirection.Backward)
--    self._proxy:SetNpcMoveType(self._uuid,ENpcMoveType.Walk)
--    local pos = self._proxy:GetNpcPosition(33)
--    self._proxy:MoveToPosition(self._uuid,pos)
--end

----更新战斗模式时
--function XChar3503:UpdateCombatMode(dt)
--    XLog.Warning("战斗模式已启动")
--end

---技能测试配置
--function XChar3503:SkillTestConfig()
--    --self:SetSkillTestActive(true)
--    --self.skillTestType = Base.SkillTestType.CustomFuc --开启了就会只执行这个函数里面的内容
--    --self:InitSkillCd(805201,0,0) --格挡
--    
--    self.skillTestId = 350303
--    self.skillTestInitialCd = 10--测试初始CD
--    --self.skillTestInitialCd = 1.5--测试初始CD
--    self.skillTestCd = 5
--    --self:SetOverDriveValueFull()--满OD
--end
--
function XChar3503:Terminate()
    Base.Terminate(self)
    local efPos = self._proxy:GetNpcPosition(self._uuid)
    local efRot = self._proxy:GetNpcRotation(self._uuid)
    self._proxy:CreateCommonEffect("FxHeiBangDeath",efPos,efRot) --创建尸体销毁特效
end

return XChar3503