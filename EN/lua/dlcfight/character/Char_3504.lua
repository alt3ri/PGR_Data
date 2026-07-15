local Base = require("Character/FightCharBase/XSGMonsterBase")
local SkillConfig = require("TempSkillConfigs/SkillConfig_8052")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
--local SkillForMonster = require("TempSkillConfigs/SkillConfigsForMonster")
---空花无人机
---@class XChar3504 : XSGMonsterBase
local XChar3504 = XDlcScriptManager.RegCharScript(3504, "XChar3504", Base)

--region 怪物配置
---配置主入口

--技能释放配置
function XChar3504:SkillCastConfig()
    self.isOverDriveActive = false --关闭OD
    self.isBreakGaugeActive = false --关闭韧性
    self.basicDistanceReference = {5,15,40}
    --self.isOpenChase = true --开启跟随功能
    ---------游荡配置---------
    --self.haveWander = true --开启游荡逻辑
    self.wanderSkills = { --前后左右的游荡技能
        front = 350390,
        back = 350391,
        left = 350392,
        right = 350393,
    }
    self.wanderWeights = { --游荡判断权重
        near = { --近距离攻击或游荡
            attack = 10,
            front = 0,
            back = 10,
            left = 0,
            right = 0,
        },
        mid = {--中距离后退或左右游荡
            attack = 50,
            front = 0,
            back = 10,
            left = 30,
            right = 30,
        },
        far = {--远距离攻击或向前游荡
            attack = 10,
            front = 40,
            back = 0,
            left = 0,
            right = 0,
        }
    }
    
    self.selectSkillType = Base.SelectSkillType.CastGroup --按照技能释放组去放技能
    self.monsterScriptInitSyncRegisterSkillCdList = { --需要同步的技能CD初始化
        [350411] = {5,65},--A21-强力攻击-前冲【通用	
        --[350416] = { 8,0 } , --A06-可爱吸气【一阶】	
        [350417] = { 10,20 } , --A10-嘲讽【一阶】
        [350430] = { 10,65 } , --A03-左右跳后攻击【通用】		
        [350432] = { 10,35 } , --A25-强力攻击-跳劈【通用】		
        [350429] = { 10,15 }, --A02-眼睛激光后跳劈【通用】
        [350444] = { 8,15 }, --A94-横向走路-向自左【通用】
        [350445] = { 8,15 }, --A94-横向走路-向自右【通用】
        --[350409] = { 10,35 }, --A04-二连下砸【通用】		
        [350406] = { 10,35 }, --A61-投技-原地电磁爆炸【通用】		
        [350401] = { 0,8 }, --A01-近战三连【通用】		
        [350410] = { 5,0 }, --A05-扫尾后跳【通用】
    }


    self.castGroup= {
        --距离参考{
        --远距离：15
        --中距离：8
        --近距离：5
        {--印象点技能
            [350411] = 10 , --A21-强力攻击-前冲【通用	中|20	
        },
        { --标志性
            [350430] = 40 , --A03-左右跳后攻击【通用】	  近|15
        },
        { --中距离的时候可以表演一下
            [350417] = 10 , --A10-嘲讽【一阶】          中远|25
            [350444] = 10 , --A94-横向走路-向自左【通用】 中|20
            [350445] = 10 , --A95-横向走路-向自右【通用】 中|20
        },
        { --核心技能
            [350432] = 10 , --A25-强力攻击-跳劈【通用】	   中|8
            --[350409] = 10, --A04-二连下砸【通用】        近中|10
            --[350429] = 10, --A02-眼睛激光后跳劈【通用】		中远|15
        },
        {--填充技能
            [350406] = 10, --A61-投技-原地电磁爆炸【通用】 近|8
            [350401] = 20, --A01-近战三连【通用】	近|8	
            [350410] = 10, --A05-扫尾后跳【通用】	近保底|
        },
        {--保底超远
            [350409] = 10, --A04-二连下砸【通用】        
        },
    }
    self.isOpenChase = false
    self:SetSelfAiDelayOpen(0.3)
end

-----技能测试配置
--function XChar3504:SkillTestConfig()
--    self.isSkillTestOpen = false
----    --self.skillTestType = Base.SkillTestType.CustomFuc --开启了就会只执行这个函数里面的内容
----    --self:InitSkillCd(805201,0,0) --格挡
----
--    self.skillTestId = 350430
--    --self.skillTestInitialCd = 10--测试初始CD
--    self.skillTestInitialCd = 1.5--测试初始CD
--    self.skillTestCd = 10
----    --self:SetOverDriveValueFull()--满OD
--end

--function XChar3504:Update(dt)
--    Base.Update(self,dt)
--end

-----临时写一个统计技能的
--function XChar3504:OnMonsterCastSkillSuccessAfter(skill)
--    if not self.SkillCastCounts then
--        self.SkillCastCounts = {}
--    end
--    if not self.SkillCastCounts[skill] then
--        self.SkillCastCounts[skill] = 1
--    else
--        self.SkillCastCounts[skill] = self.SkillCastCounts[skill] + 1
--    end
--end
--
---临时写一个销毁技能的
function XChar3504:Terminate()
    Base.Terminate(self)
    local efPos = self._proxy:GetNpcPosition(self._uuid)
    local efRot = self._proxy:GetNpcRotation(self._uuid)
    self._proxy:CreateCommonEffect("FxHeiBangDeath",efPos,efRot) --创建尸体销毁特效
end


return XChar3504