local Base = require("Character/FightCharBase/XRelinkMonsterBase")
local SkillConfig = require("TempSkillConfigs/SkillConfig_8052")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")
local ParryType ={
    None = 0,--什么都没有
    Break = 1 ,--打断
    UnBreak = 2 , --不打断
    Offset = 3 , --角力
}

---小辉辉BOSS脚本
---@class XChar8052 : XRelinkMonsterBase
local XChar8052 = XDlcScriptManager.RegCharScript(8052, "XChar8052", Base)
--region 枚举
XChar8052.DashMode = { --冲刺技能的流程
    None = 0,
    Start =1,--开始阶段，进行蓄力
    Turn = 2,--转身阶段
    Loop = 3,--冲刺阶段
    End = 4,-- 结束，释放收招技能阶段
    ReadyStart=5,--启动时已经做了很多处理，但还没开屏障
    AlreadySetLevel = 6, --已经设置好关卡了
}

XChar8052.DashType = { --冲刺类型
    None =0, --不选择冲刺
    Mid = 1 , --在中心
    Side = 2 , --在边缘
    Player =3,--向玩家冲刺
    Random =4,--随机选点
}

XChar8052.DashBoundaryState ={
    None = 0, --无
    SmallAwake = 1, --初始时候的那一次
    Small = 2,--小内圈
    Big = 3, --大外圈
}

--endregion

--region 同步换端处理部分

--怪物在处理完脚本同步变量后
function XChar8052:MonsterHandleScriptInitSyncVarAfter()

    local curODState = self:GetCurOverDriveState() --当前OD状态
    
    --if self.dashMode ~= XChar8052.DashMode.None then --当前模式不等于0的时候需要重启流程
    --    --self:DashReStart() --Dash流程重新启动！
    --end
    
    if self:CheckIsOnSoftFury() then --软狂暴的时候设置软狂暴技能组
        local castGroup={
            --{--OD：Dash机制
            --    [805258] = 10,  --Dash机制启动
            --},
            {--OD:强力技能
                [805204]=  50,  --欧拉拳（35）
                [805277] = 30, --OD光刃二连
                [805278] = 30, --OD光刃三连
                [805248] = 10,  --OD连续推进拳
                [805249] = 50,  --OD瑟提锤
                [805223] = 10,  --光刃上天
            },
        }
        self:SetCastGroup(castGroup) --设置成新的技能组
    end
    
    ---Break过程中换端直接接上BreakLoop
    if curODState == Base.OverDriveState.BreakStart or curODState == Base.OverDriveState.BreakLoop then
        self:ForceSkill(self.breakLoopSkill)
    end

end

--endregion

--region 怪物配置
---配置主入口
function XChar8052:MonsterConfigMain() --怪物配置用
    Base.MonsterConfigMain(self)
    self.airAttackRemainCount = 0 --上天攻击剩余次数，没有次数时就要落地了，落地时要清空
    self.airAttack = 3 --上天攻击上限
    self.dodgeRemainCount =  0 --剩余攻击次数，没有次数时要取消闪避。
    self.dodgeMax = 3 --连续闪避次数上限
    self.pushFistODCount = 1 --连续推进拳计数
    self.isAirHaveDodge = false --空中有没有闪避过
    self._proxy:AddTimerTask(0.8, function() --0.8秒后开启怪物Ai
        self:SetAiActive(true)
    end)
    ------怪物自己机制的初始化------
    --需要同步的变量Key字典
    self.monsterSubVarSyncKeyDicInitial ={
        dashMode = 1, --冲刺模式(ok
        curDashRound=2,--冲刺轮次
        dashPingZhangBulletUUID =3,--冲刺过程中的屏障子弹UUID
        dashBoundaryState = 4, --屏障的状态
    }
    self.monsterSubSyncValueDic ={
        dashMode = {Base.SyncValueType.int},
        curDashRound = {Base.SyncValueType.int},
        dashPingZhangBulletUUID = {Base.SyncValueType.int},
        dashBoundaryState = {Base.SyncValueType.int},
    }
    self.monsterScriptInitSyncRegisterSkillCdList = { --需要同步的技能CD
        [805201] = {25,25},--格挡
        [805202] = {0,5},--反身拳
        [805203] = {0,5},--上勾拳
        [805204] = {45,35},--欧拉拳
        [805205] = {0,0},--格挡反击
        [805206] = {0,0},--流星冲锋坠
        [805207] = {20,10},--交叉射击
        [805208] = {8,15},--推进拳
        [805209] = {0,30},--下段斩
        [805216]={0,15},--地面蓄力炮
        [805221]={6,0}, --移动射击向前
        [805222]={0,40}, --光刃三连
        [805223]={40,40}, --光刃上天
        [805224]={0,30}, --光刃二连
        [805225]={0,0}, --胸炮浮空版
        [805226]={30,35}, --胸炮地面起跳版
        [805227]={45,35}, --升龙腿
        [805228]={0,10}, --空落锤
        [805229]={0,35}, --重火锤
        [805230]={0,15}, --后退斩
        [805231]={0,0}, --响指波
        [805232]={10,15}, --瑟提锤
        [805234]={0,5}, --二连拳
        [805258]={35,120}, --冲刺机制：启动
        [805248]={0,60}, --OD：连续Plus推进拳
        [805249]={0,40}, --OD：瑟提锤
        [805273]={0,0}, --OD：胸炮浮空版
        [805274]={30,35}, --OD：胸炮地面起跳版
        [805275]={0,0}, --OD：蓄力不死斩启动技能
        [805277]={0,30}, --OD：光刃二连
        [805278]={0,40}, --OD：光刃三连
        [805279]={0,40}, --OD：流星冲锋坠
    }
    self.monsterScriptInitSyncRegisterNpcTimerList = { --需要同步的NpcTimer
        [1] = {15,10},--闪避CD
        [2] = {30,20}, --连续闪避Cd
        [3] = {0,60}, --回中用来释放大不死斩的Timer
    }

    -----没有用到的东西------------
    self.isSkillConnectLocked = true --设置小辉辉的连招锁
    self.maxConnectCount = 2-- 连招上限
    self.curConnectCount = 1 --当前连招段数
    -----------------------------
    self.bornSkill = 805282 --出生动画
    self:DashInit() --连续冲刺机制技能初始化
end

--软狂暴配置
function XChar8052:SoftFuryConfig()
    self.enterSoftFurySkill = 805280 --进入软狂暴的爆气技能
    self.enterSoftFuryMagicList = { --进入软狂暴时会给自己添加的Magic列表
        8052130,--软狂暴特效
        1000512,--软狂暴标记
    }
end

--技能释放配置
function XChar8052:SkillCastConfig()
    self.selectSkillType = Base.SelectSkillType.CastGroup --按照技能释放组去放技能
    --爆气优先技能列表
    --转阶段优先技能列表。
    --self:TrySetCurPhase(2)
    self.castGroup= {
        --距离参考{
        --远距离：15
        --中距离：8
        --近距离：5
        --}
        {--OD：机制启动技能
            --[805252] = 10,  --浮空机制启动技能
            [805258] = 10,  --Dash机制启动技能
        },
        {--OD:二阶段不死斩系列
            [805277] = 10, --OD光刃二连
            [805278] = 10, --OD光刃三连
        },
        {--OD：通用的强力技能
            [805248] = 10,  --OD连续推进拳
            [805249] = 10,  --OD瑟提锤
        },
        {--二阶段：上天技能，有公共CD
            [805223] = 10,  --光刃上天
            [805274] = 10,  --OD胸炮起跳版，一阶段就会有。
            [805227] = 10, --升龙腿
        },
        {--二阶段，强力攻击
            [805224] = 10,  --光刃二连
            [805229] = 10,  --重火锤
        },
        {--二阶段：优先
            [805216] = 10,  --地面蓄力炮（10）
            [805229] = 10,  --重火锤
            [805230] = 10,  --后退斩
            [805209] = 10 , --下段斩
        },
        {--普通阶段：优先
            [805232] = 10,  --瑟提锤
            [805208] = 10,  --中远距离：推进拳（15）
            [805204]=  10,  --欧拉拳（35）
            [805207] = 10,  --交叉射击：近距离后退拉开距离（）
        },
        { --普通阶段：超远距离
            [805221] = 10,  --超远距离：移动射击（0）远程
        },
        {--普通阶段，全部的CD都很短
            [805203]=10,   --上勾拳（0）
            [805234]=10,   --二连拳（0）
            [805202]=10,   --反身拳（0）
        },
    }
end

---技能测试配置
function XChar8052:SkillTestConfig()
    --self:SetSkillTestActive(true)
    --self.skillTestType = Base.SkillTestType.CustomFuc --开启了就会只执行这个函数里面的内容
    --self:InitSkillCd(805201,0,0) --格挡
    
    self.skillTestId = 805277
    self.skillTestInitialCd = 10--测试初始CD
    --self.skillTestInitialCd = 1.5--测试初始CD
    self.skillTestCd = 10
    --self:SetOverDriveValueFull()--满OD
end

function XChar8052:OnSkillTestTriggerCustomFuc()
    self:ForceSkill(805258)
    self:ApplyMagicAllPlayer(8052134) --隐藏全场玩家UI
end

-----技能配置
function XChar8052:SkillConfig()
--    self:InitSkillCd(805201,25,25) --格挡
--    self:InitSkillCd(805202,0,0) --反身拳
--    self:InitSkillCd(805203,0,5) --上勾拳
--    self:InitSkillCd(805204,45,35) --欧拉拳
--    self:InitSkillCd(805205,0,0) --格挡反击
--    self:InitSkillCd(805206,0,0) --流星冲锋坠
--    self:InitSkillCd(805207,20,10) --交叉射击
--    self:InitSkillCd(805208,8,15) --推进拳
--    self:InitSkillCd(805209,0,30) --下段斩
--    self:InitSkillCd(805216,0,15)--地面蓄力炮
--    self:InitSkillCd(805221,6,0) --移动射击向前
--    self:InitSkillCd(805222,0,40) --光刃三连
--    self:InitSkillCd(805223,40,40) --光刃上天
--    self:InitSkillCd(805224,0,30) --光刃二连
--    self:InitSkillCd(805225,0,0) --胸炮浮空版
--    self:InitSkillCd(805226,30,35) --胸炮地面起跳版
--    self:InitSkillCd(805227,45,35) --升龙腿
--    self:InitSkillCd(805228,0,10) --空落锤
--    self:InitSkillCd(805229,0,35) --重火锤
--    self:InitSkillCd(805230,0,15) --后退斩
--    self:InitSkillCd(805231,0,0) --响指波
--    self:InitSkillCd(805232,10,15) --瑟提锤
--    self:InitSkillCd(805234,0,5) --二连拳
--    self:InitSkillCd(805258,35,120) --冲刺机制：启动
--    self:InitSkillCd(805248,0,60) --OD：连续Plus推进拳
--    self:InitSkillCd(805249,0,40) --OD：瑟提锤
--    self:InitSkillCd(805273,0,0) --OD：胸炮浮空版
--    self:InitSkillCd(805274,30,35) --OD：胸炮地面起跳版
--    self:InitSkillCd(805275,0,60) --OD：蓄力不死斩启动技能
--    self:InitSkillCd(805277,0,30) --OD：光刃二连
--    self:InitSkillCd(805278,0,40) --OD：光刃三连
--    self:InitSkillCd(805279,0,40) --OD：流星冲锋坠
end

---韧性系统配置
function XChar8052:BreakGaugeConfig()
    --self:SetBreakGaugeActive(false)--关闭韧性系统
    self.brokenSkill = 805236 --被破韧技能
    self.brokenRange = 40 --多少米内的玩家可以受到破韧信号
    self.brokenSkillFront = 805245 --被前面破韧时技能
    self.brokenSkillBack = 805244 --被破韧时释放的技能
    self.brokenSkillLeft = 805247 --被破韧时释放的技能
    
    self.brokenSkillRight = 805246 --被破韧时释放的技能
end

---OverDrive配置
function XChar8052:OverDriveConfig()
    --self:SetOverDriveActive(false)--关闭OD系统
    self.enterOverDriveSkill = 805235 --OD技能
    self.breakStartSkill = 805236 --配置：进入虚弱技能
    self.breakLoopSkill = 805237 --配置：虚弱循环技能
    self.breakEndSkill = 805238 --配置：退出虚弱时技能
    self.breakStartEnterLoopDelayTime = 0.9 --0.9秒后切到BreakLoop
    --self:SetOverDriveValueFull()--设置OverDrive满
end

---阶段配置
function XChar8052:PhaseConfig()
    self:SetSwitchPhaseType(Base.SwitchPhaseType.ExitBreak)--退出Break的时候切阶段
    self:SetMaxPhase(2) --阶段上限2
end

---OverDrive配置用
function XChar8052:OverDriveTest()
    self._proxy:AddTimerTask(4,function()
        self:SetOverDriveValueFull()--把OD值加满
    end )
end

--endregion

--region 脚本生命周期

function XChar8052:InitEventCallBackRegister()
    Base.InitEventCallBackRegister(self)
    self._proxy:RegisterEvent(EWorldEvent.NpcAddBuff)           -- 添加buff
    self._proxy:RegisterEvent(EWorldEvent.NpcSkillActionKeyframeSendEvent) --监听帧事件发送事件
    self._proxy:RegisterEvent(EWorldEvent.NpcDamage) --监听帧事件发送事件
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcBeforeTriggerCounter,self._uuid) --触发前
    self._proxy:RegisterEventByTarget(EWorldEvent.NpcAfterTriggerCounter,self._uuid) --触发后
end

--endregion

--region 战斗流程
---塔塔开的前置逻辑
function XChar8052:UpdateFightModeBefore()
    Base.UpdateFightModeBefore(self)
    self:HandleActionKeyFrameEventLatest() --尝试在事件列表里执行相应的函数
    self:DashTickCheck() --Dash机制Tick检查
    self:MortalBladeTickCheck() --不死斩机制释放检查
    self:OdDashTickCheck() --OD机制技能每帧检测
    --self:AirFirePlayerShieldTickCheck() --浮空机制玩家护盾检查
    self:MoveFireTickCheck() --移动射击检查
    --self:GoCenterCheck() --回中检查
end

--endregion

--region 不死斩
---不死斩每帧更新
function XChar8052:MortalBladeTickCheck()
    
    --不在软狂暴和OD直接返回
    if not self:CheckIsOnSoftFury() and not self:CheckCurIsOverDrive() then
        return
    end
    
    --检查不死斩TimerCD情况
    if not self:CheckNpcTimer(3) then
        return
    end

    if not self:CheckSelfActionValid() then --行为不合法的时候返回
        return
    end

    ----距离场地中心10m范围内的时候
    if self:CheckNpcToPosDistanceIgnoreY(self._uuid, self:GetLevelCenterPoint(), 10) then
        self:MortalBladeStart()
    else
        self:CastSkillToPosition(805275,self.levelCenterPoint) --尝试向场地中间放蓄力不死斩启动技能
    end
    self:NpcTimerEnterCd(3) --启动后进入Cd
end

--endregion

--region Dash机制技能

---小辉辉冲刺技能初始化
function XChar8052:DashInit()
    --默认关闭内外圈
    -----Dash机制的几个点位保存-----
    self.dashPlayerPointList ={}
    self.dashMonsterPoint = self._proxy:GetSpot(6) --Dash机制BOSS位置
    table.insert(self.dashPlayerPointList,self._proxy:GetSpot(7))--Dash机制玩家1位置
    table.insert(self.dashPlayerPointList,self._proxy:GetSpot(8))--Dash机制玩家2位置
    table.insert(self.dashPlayerPointList,self._proxy:GetSpot(9))--Dash机制玩家3位置
    -----机制关键要同步的东西--------
    self.curDashRound = 0 --当前冲刺轮次
    self.dashArriveCheckRange = 0
    self.dashMode = (XChar8052.DashMode.None)--默认冲刺没有东西
    self.dashCenter = self:GetLevelCenterPoint() --场地中心点作为冲刺的中心点
    self.dashLinkEffect = "FxMb1StarknightLine01" --连线特效名
    self.dashSelectCount = 2 --选点的时候选择到了第几个点
    self.nextDashIndex = 1 --冲刺的时候是在朝着第几个点前进
    self.dashTestNpcList = { } --临时列表，保存要表示连线的NpcUUID
    self.dashLinkIdList = { } --临时保存LinkID的列表
    self.dashMapPointIndexList ={}--保存index的列表，方便序号随机
    self.dashList = {} --冲刺列表，按照顺序冲刺，数据结构={Vector3位置，和上一个点}
    self.dashTipsList = {} --冲刺范围的Line列表
    self.dashPingZhangBulletUUID = nil --冲刺机制屏障子弹的UUID
    ----冲刺范围默认参数----
    self.dashOrthoCenterVerticalPointOffset =14
    self.dashOrthoCenterHorizontalPointOffset=14
    self.dashVerticalOffset =14
    self.dashHorizontalOffset = 14
    self:RefreshDashMapPointList() --根据配置的范围刷新冲刺列表
    ----冲刺范围配置----
    
    self.dashRound1TypeMap = { --第一轮冲刺类型，会限制最终的选点数量
        [1] = XChar8052.DashType.Random,
        [2] = XChar8052.DashType.Side,
        [3] = XChar8052.DashType.Mid,
        [4] = XChar8052.DashType.Player,
        [5] = XChar8052.DashType.Side,
        [6] = XChar8052.DashType.Mid,
        [7] = XChar8052.DashType.Player,
        [8] = XChar8052.DashType.Side,
        [9] = XChar8052.DashType.Mid,
        [10] = XChar8052.DashType.Player,
        [11] = XChar8052.DashType.Mid,
    }

    self.dashRound2TypeMap = { --第二轮冲刺类型，会限制最终的选点数量
        [1] = XChar8052.DashType.Random,
        [2] = XChar8052.DashType.Side,
        [3] = XChar8052.DashType.Player,
        [4] = XChar8052.DashType.Side,
        [5] = XChar8052.DashType.Side,
        [6] = XChar8052.DashType.Mid,
        [7] = XChar8052.DashType.Side,
        [8] = XChar8052.DashType.Mid,
        [9] = XChar8052.DashType.Player,
        [10] = XChar8052.DashType.Side,
        [11] = XChar8052.DashType.Player,
    }

    self.dashRound3TypeMap = { --第三轮冲刺类型，会限制最终的选点数量
        [1] = XChar8052.DashType.Random,
        [2] = XChar8052.DashType.Side,
        [3] = XChar8052.DashType.Side,
        [4] = XChar8052.DashType.Player,
        [5] = XChar8052.DashType.Side,
        [6] = XChar8052.DashType.Side,
        [7] = XChar8052.DashType.Side,
        [8] = XChar8052.DashType.Side,
        [9] = XChar8052.DashType.Player,
        [10] = XChar8052.DashType.Side,
        [11] = XChar8052.DashType.Side,
    }

    --self.dashRound3TypeMap = { --第三轮冲刺类型，会限制最终的选点数量
    --    [1] = XChar8052.DashType.Random,
    --    [2] = XChar8052.DashType.Side,
    --    [3] = XChar8052.DashType.Player,
    --    [4] = XChar8052.DashType.Side,
    --    [5] = XChar8052.DashType.Side,
    --    [6] = XChar8052.DashType.Mid,
    --    [7] = XChar8052.DashType.Side,
    --    [8] = XChar8052.DashType.Side,
    --    [9] = XChar8052.DashType.Player,
    --    [10] = XChar8052.DashType.Side,
    --    [11] = XChar8052.DashType.Mid,
    --}

    self.dashShunPointList = { --标记起点和终点
    }
    
    self.dashAboutSkill = { --Dash相关的技能，用来判断是否不在流程中
        805240,--DashStart开始的技能
        805241,--DashLoop1
        805242,--DashLoop2
        805243,--DashLoop3
        805251,--转身
        805239,--Dash的瑟提锤
        805258,--启动1
        805250,--启动2
    }
    self:DashSetDashBoundaryState(XChar8052.DashBoundaryState.None)
end

--OD机制技能每帧检测
function XChar8052:OdDashTickCheck()
    
    if not self:CheckSkillCdDone(805258) then --检查启动技能的CD
        return
    end

    if self:CheckAnyPlayerInUltra() then
        return
    end

    if not self:CheckSelfActionValid() then
        return
    end

    if self:CastSkillToTarget(805258) then --释放成功
        self:ApplyMagicAllPlayer(8052134) --隐藏全场玩家UI
    end
    
end

---冲刺机制回区域检查
function XChar8052:DashBackAreaCheck()
    local isOutArea = false --是否在区域外
    if self.curDashRound == 0 or self.curDashRound == 1 then --最开始的时候
        if not self._proxy:CheckNpcPositionDistance(self._uuid,self.dashCenter,21,false) then
            isOutArea = true
        end
    elseif not self._proxy:CheckNpcPositionDistance(self._uuid,self.dashCenter,30,false) then--其他情况
            isOutArea = true
    end
    
    if isOutArea == false then --没有出区域
        return
    end

    ----在区域外要做的处理
    if self.dashMode == XChar8052.DashMode.Loop then --如果是在Loop中的话马上看向下一个点
        if self.nextDashIndex == 1 then
            self._proxy:SetNpcPosition(self._uuid,self.dashCenter,false) --传到场地中心
            self._proxy:SetNpcPosition(self._uuid,self.dashList[self.nextDashIndex],false) --看向第一个点
            return
        end
        if self.nextDashIndex <= #self.dashList then
            self._proxy:SetNpcPosition(self._uuid,self.dashList[self.nextDashIndex-1],false) --传到起点
            self._proxy:LookAtPositionImmediately(self._uuid,self.dashList[self.nextDashIndex]) --看向下一个点
            return
        else
            self._proxy:SetNpcPosition(self._uuid,self.dashList[#self.dashList],false) --传送到最后一个点结束
            self:OnCurDashRoundEnd()
        end
        
    end
    self._proxy:SetNpcPosition(self._uuid,self.dashCenter,false) --出了场地传回场地中心
end

--检查是否有玩家在必杀
function XChar8052:CheckAnyPlayerInUltra()
    local playerList = self._proxy:GetPlayerNpcList()
    for i ,player in pairs(playerList)do
        local suc,actionId,actionType = self._proxy:TryGetCurrentAction(player)
        if suc and actionType == 2  then--如果有奥义
            return true
        end
    end
    return false --没有人在奥义
end

---刷新冲刺Map点
function XChar8052:RefreshDashMapPointList()
    local centerPoint = {x=self.dashCenter.x,y=self.dashCenter.y,z=self.dashCenter.z }
    local orthoCenterVerticalPointOffset = self.dashOrthoCenterVerticalPointOffset --和中心点正交的垂直偏移
    local orthoCenterHorizontalPointOffset =self.dashOrthoCenterHorizontalPointOffset --和中心点正交的横向偏移
    local verticalOffset = self.dashVerticalOffset
    local horizontalOffset = self.dashHorizontalOffset
    self.dashMapPointList = { --冲刺的场景固定点位置
        u = { --中心正交上
            x = centerPoint.x ,
            y = centerPoint.y ,
            z = centerPoint.z + orthoCenterHorizontalPointOffset
        },
        d = { --中心正交下
            x = centerPoint.x ,
            y = centerPoint.y ,
            z = centerPoint.z -orthoCenterHorizontalPointOffset
        },
        l = { --中心正交左
            x = centerPoint.x-orthoCenterVerticalPointOffset,
            y = centerPoint.y,
            z = centerPoint.z
        },
        r = { --中心正交右
            x = centerPoint.x +orthoCenterVerticalPointOffset,
            y = centerPoint.y,
            z = centerPoint.z
        },
        uL = { --中心正交上左
            x = centerPoint.x -verticalOffset,
            y = centerPoint.y,
            z = centerPoint.z +orthoCenterHorizontalPointOffset
        },
        uR = { --中心正交上右
            x = centerPoint.x +verticalOffset,
            y = centerPoint.y,
            z = centerPoint.z +orthoCenterHorizontalPointOffset
        },
        dL = { --中心正交下左
            x = centerPoint.x-verticalOffset,
            y = centerPoint.y,
            z = centerPoint.z -orthoCenterHorizontalPointOffset
        },
        dR= { --中心正交下右
            x = centerPoint.x+verticalOffset,
            y = centerPoint.y,
            z = centerPoint.z -orthoCenterHorizontalPointOffset
        },
        lU = { --中心正交左上
            x = centerPoint.x -orthoCenterVerticalPointOffset,
            y = centerPoint.y,
            z = centerPoint.z +horizontalOffset
        },
        lD = { --中心正交左下
            x = centerPoint.x -orthoCenterVerticalPointOffset,
            y = centerPoint.y,
            z = centerPoint.z -horizontalOffset
        },
        rU = { --中心正交右上
            x = centerPoint.x +orthoCenterVerticalPointOffset,
            y = centerPoint.y,
            z = centerPoint.z +horizontalOffset
        },
        rD = { --中心正交右下
            x = centerPoint.x +orthoCenterVerticalPointOffset,
            y = centerPoint.y,
            z = centerPoint.z -horizontalOffset
        },
    }
    self.dashMapPointIndexList ={}--保存index的列表，方便序号随机
    for pointName,pos in pairs(self.dashMapPointList) do--按序号排序，方便随机。
        table.insert(self.dashMapPointIndexList,pos)
    end
end

---CreatDashTips
function XChar8052:CreatDashTips()
    local _
    --创建屏障子弹
    self:ClearDashTips() --先清空
    ---30内圈
    if self.dashBoundaryState == XChar8052.DashBoundaryState.SmallAwake or self.dashBoundaryState == XChar8052.DashBoundaryState.None then
        _,self.dashPingZhangBulletUUID = self._proxy:LaunchMissileFromPosToPos(self._uuid,80520170,80525001,self.dashCenter,self.dashCenter)
        self:DashSetObstacleActive(true,true)--开启内圈
        self:DashSetObstacleActive(false,false)--关闭外圈
    else -- 40外圈
        _,self.dashPingZhangBulletUUID = self._proxy:LaunchMissileFromPosToPos(self._uuid,80520170,80525002,self.dashCenter,self.dashCenter)
        self:DashSetObstacleActive(true,false)--关闭内圈
        self:DashSetObstacleActive(false,true)--开启外圈
    end
end

---重新启动时
function XChar8052:ReStartCreatDashTips()
    local _
    --创建屏障子弹
    self:ClearDashTips() --先清空
    ---内圈
    if self.curDashRound == 1 then
        _,self.dashPingZhangBulletUUID = self._proxy:LaunchMissileFromPosToPos(self._uuid,80520170,80525001,self.dashCenter,self.dashCenter)
        self:DashSetObstacleActive(true,true)--开启内圈
        self:DashSetObstacleActive(false,false)--关闭外圈
    else
        --外圈
        _,self.dashPingZhangBulletUUID = self._proxy:LaunchMissileFromPosToPos(self._uuid,80520170,80525002,self.dashCenter,self.dashCenter)
        self:DashSetObstacleActive(true,false)--关闭内圈
        self:DashSetObstacleActive(false,true)--开启外圈
    end
    
end

---ClearDashTips，清除提示障碍边缘的特效子弹
function XChar8052:ClearDashTips()
    self._proxy:RemoveCurrentNpcMissileByTemplateId(80525001)--内外圈都删除
    self._proxy:RemoveCurrentNpcMissileByTemplateId(80525002)--内外圈都删除
    --if self.dashPingZhangBulletUUID then
    --    XLog.Warning("删除子弹UUID"..self.dashPingZhangBulletUUID)
    --    self._proxy:DestroyMissileByUUID(self.dashPingZhangBulletUUID)
    --end
    self.dashPingZhangBulletUUID = nil
end

---小辉辉Dash机制开始布置场地
function XChar8052:DashStartSetLevel()
    
    for i,playerUUID in pairs(self._proxy:GetPlayerNpcList()) do --获取和设置玩家位置(对每个玩家进行处理)
        self._proxy:SetNpcPosition(playerUUID,self.dashPlayerPointList[i])
        self._proxy:SetNpcRotation(playerUUID,{x=0,y=0,z=0})
        self._proxy:ResetCamera(0,0,true) --这个好像只会设置自己的
    end
    
    ----Dash初次冲刺范围----
    self.dashOrthoCenterVerticalPointOffset = 14
    self.dashOrthoCenterHorizontalPointOffset= 14
    self.dashVerticalOffset = 14
    self.dashHorizontalOffset = 14
    self:RefreshDashMapPointList() --根据配置的范围刷新冲刺列表
    self.dashArriveCheckRange = 3 --首次冲刺的判断范围
    self:DashSetDashBoundaryState(XChar8052.DashBoundaryState.SmallAwake) --初始的那一次
    -------创建场景屏障特效
    self:CreatDashTips()
    self:DashSetDashMode(XChar8052.DashMode.AlreadySetLevel)--设置好关卡了
end

---小辉辉Dash设置冲刺模式
function XChar8052:DashSetDashMode(mode)
    self.dashMode = mode
    self:MonsterSubSetVarSyncValue("dashMode",mode)
    if self.dashMode == XChar8052.DashMode.None then
        --XLog.Warning("小辉辉的冲刺流程结束")
    end
end

---小辉辉Dash机制开始Go了
function XChar8052:DashStartGo()
    self:ForceSkillToNpc(805239,self:GetRandomPlayerInRange(0,999)) --随机向一个玩家释放冲刺机制瑟提锤
end

---小辉辉Dash机制ReadyToStart
function XChar8052:DashReadyStart()
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052089) --不能被玩家索敌/锁定
    self._proxy:SetNpcPosition(self._uuid,self.dashMonsterPoint)   --设置冲刺时怪物位置
    self._proxy:SetNpcRotation(self._uuid,{x=0,y=180,z=0}) --设置冲刺时怪物朝向
    
    ------
    self:AbortActionAllPlayer() --打断所有玩家的当前Action
    self:ApplyMagicAllPlayer(8052324) --所有玩家设置相机位置偏移
    self:ApplyMagicAllPlayer(8052325) --所有玩家设置相机旋转偏移
    self:ApplyMagicAllPlayer(8052134) --屏蔽所有玩家的UI
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052135) --免疫Relink特殊伤害受击
    self:DashSetDashMode(XChar8052.DashMode.ReadyStart)--状态变成了准备开始
    self:DashSetCurRound(1)
    self:ForceSkill(805250) --强制释放启动2
end

---小辉辉Dash技能重新开始
function XChar8052:DashScriptInitReStart()
    --XLog.Warning("崔俊豪重启冲刺技能")
    self:CleanDashLink() --清空连线
    if self.curDashRound == 1 then
        --XLog.Warning("冲啊")
        self.dashOrthoCenterVerticalPointOffset = 14
        self.dashOrthoCenterHorizontalPointOffset= 14
        self.dashVerticalOffset = 14
        self.dashHorizontalOffset = 14
        self.dashArriveCheckRange = 3 --首次冲刺的判断范围
        self:RefreshDashMapPointList() --根据配置的范围刷新冲刺列表
        self:ForceSkillToNpc(805239,self:GetRandomPlayerInRange(0,999)) --随机向一个玩家释放冲刺机制瑟提锤，开始流程
    end

    if self.curDashRound == 2 then
        self:ForceSkillToNpc(805239,self:GetRandomPlayerInRange(0,999)) --随机向一个玩家释放冲刺机制瑟提锤，开始流程
    end
end

---小辉辉处理边界
function XChar8052:DashHandleBoundary()
    --根据护盾的状态来决定

    if self.dashBoundaryState == XChar8052.DashBoundaryState.SmallAwake then
        self:DashSetDashBoundaryState(XChar8052.DashBoundaryState.Small)

    elseif self.dashBoundaryState == XChar8052.DashBoundaryState.Small then

        ----第二次范围边长40----
        self.dashOrthoCenterVerticalPointOffset = 20
        self.dashOrthoCenterHorizontalPointOffset= 20
        self.dashVerticalOffset = 20
        self.dashHorizontalOffset = 20
        self.dashArriveCheckRange = 5 --第二次速度比较快，到达的范围检测更大
        self:RefreshDashMapPointList() --根据配置的范围刷新冲刺列表
        -------创建场景屏障特效
        self:CreatDashTips()
        self:DashProcessBulletControl()
        self._proxy:RemoveBuff(self._uuid,8052076) --移除不能被碰撞
        self._proxy:RemoveBuff(self._uuid,8052093) --移除无视场景障碍
        self:DashSetCurRound(2) --当前冲刺该是第二轮了
        self:DashSetDashBoundaryState(XChar8052.DashBoundaryState.Big)
    elseif self.dashBoundaryState == XChar8052.DashBoundaryState.Big then

        self:ClearDashTips() --清除冲刺提示
        self:DashSetObstacleActive(true,false)--关闭内圈障碍
        self:DashSetObstacleActive(false,false)--关闭外圈障碍
        self:RemoveBuffAllPlayer(8052301)--相机坐标偏移
        self:RemoveBuffAllPlayer(8052302)--相机旋转偏移
        self._proxy:RemoveBuff(self._uuid,8052089)
        self:RemoveBuffAllPlayer(8052134) --移除隐藏UI的Buff
        self:RemoveBuffAllPlayer(8052324) --移除位置偏移
        self:RemoveBuffAllPlayer(8052325)--移除旋转偏移
        self._proxy:RemoveBuff(self._uuid,8052135) --移除免疫特殊伤害受击
        self._proxy:RemoveBuff(self._uuid,1000465) --移除锁定Od
        self._proxy:RemoveBuff(self._uuid,1000469) --取消锁韧
        self._proxy:RemoveBuff(self._uuid,8052076) --移除不能被碰撞
        self._proxy:RemoveBuff(self._uuid,8052093) --移除无视场景障碍
        self:DashSetCurRound(0)
        self:DashSetDashBoundaryState(XChar8052.DashBoundaryState.None) --结束
        self:DashSetDashMode(XChar8052.DashMode.None) --结束流程
    end
    
end

---刷新清空冲刺数据
function XChar8052:DashRefresh()
    self.dashList = {} --清空冲刺列表
    self.dashTestNpcList = {}--清空测试Npc列表
    self:CleanDashLink()
end

---冲刺技能Update
function XChar8052:DashTickCheck()
    if self.dashMode == XChar8052.DashMode.None then --没有进流程就返回
        return
    end
    --------在冲刺机制流程里面--------
    self:DashBackAreaCheck() --回区域检查
    self:DashLoopTickCheck() --Dash循环检查
    self:DashReStartCheck() --Dash过程中重启检查
    
end

---进入DashStart
function XChar8052:EnterDashStart()
    if self.curDashRound ==0 then --无法无缘无辜就启动
        return
    end
    
    self:DashRefresh() --清空上一轮保存的点
    self.nextDashIndex = 1 --要冲向的点Index是1
    local startPos = nil --冲刺的开始点
    if self.curDashRound ==1 then
        --XLog.Warning("第一次冲刺")
        startPos =self:TryGetDashStartPoint()--获得开始的第一个点
    elseif self.curDashRound ==2 then
        --XLog.Warning("第二次冲刺")
        startPos = self:TryGetDashStartPoint()--获得开始的第一个点
    elseif self.curDashRound ==3 then
        startPos = self:TryGetDashStartPoint()--获得开始的第一个点
        --XLog.Warning("第三次冲刺")
    end
    table.insert(self.dashList,startPos)--插入开始的第一个点。
    
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052075) --不能被碰撞
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052091) --无敌
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052093) --无视场景障碍
    self:ForceSkillToPosition(805240,startPos)--向开始的点释放Start技能
    self._proxy:LookAtPositionImmediately(self._uuid,self.dashList[self.nextDashIndex])--看向要冲刺的第一个点
    self.dashSelectCount =2 --冲刺选点之后要选第二个点了
    self:CreatStartDashPosLink() --创建开始时的冲刺线
end

---DashReStart，重启重启流程
function XChar8052:DashReStart()
    local startPos = nil --冲刺的开始点
    
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052075) --不能被碰撞
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052091) --无敌
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052093) --无视场景障碍
    
    if #self.dashList == 0 then --冲刺列表为空就重新选一下点
        if self.curDashRound == 1 or self.curDashRound == 0 then
            ----Dash初次冲刺范围----
            self.dashOrthoCenterVerticalPointOffset = 14
            self.dashOrthoCenterHorizontalPointOffset= 14
            self.dashVerticalOffset = 14
            self.dashHorizontalOffset = 14
            self.dashArriveCheckRange = 3 --首次冲刺的判断范围
            self:DashSetCurRound(1)
            self:DashSetDashBoundaryState(XChar8052.DashBoundaryState.Small)
        end

        if self.curDashRound == 2 then
            self.dashOrthoCenterVerticalPointOffset = 20
            self.dashOrthoCenterHorizontalPointOffset= 20
            self.dashVerticalOffset = 20
            self.dashHorizontalOffset = 20
            self:DashSetCurRound(2)
            self.dashArriveCheckRange = 5 --第二次速度比较快，到达的范围检测更大
            self:DashSetDashBoundaryState(XChar8052.DashBoundaryState.Big)
        end

        self:RefreshDashMapPointList() --根据配置的范围刷新冲刺列表
        self:ReStartCreatDashTips() ---重新创建屏障

        startPos =self:TryGetDashStartPoint()--获得开始的第一个点
        table.insert(self.dashList,startPos)--插入开始的第一个点。
        self:CreatStartDashPosLink() --创建开始时的冲刺线
        self.nextDashIndex = 1 --重新选点重置下一个点
        self:ForceSkillToPosition(805240,startPos)--向开始的点释放Start技能
        self._proxy:LookAtPositionImmediately(self._uuid,self.dashList[self.nextDashIndex])--看向要冲刺的第一个点
        self.dashSelectCount = 2 --冲刺选点之后要选第二个点了
        return
    end
    if #self.dashList > 0 then
        --本端打断吧
        self:EnterDashLoop()
    end
end

---进入DashLoop时
function XChar8052:EnterDashLoop()
    local dashSkill = 805241 --冲刺技能默认是慢速的
    if self.curDashRound == 1 then--第二回合快速
        --XLog.Warning("第一轮冲刺")
        dashSkill = 805241
    end
    if self.curDashRound == 2 then--第二回合快速
        --XLog.Warning("第二轮冲刺")
        dashSkill = 805242
    end
    if self.curDashRound == 3 then --顺一闪
        dashSkill = 805243
    end
    
    local targetPoint = self.dashList[self.nextDashIndex]
    self:ForceSkillToPosition(dashSkill,targetPoint)--向目标点放冲刺技能
    self._proxy:LookAtPositionImmediately(self._uuid,targetPoint)--看向目标点
    self:DashSetDashMode(XChar8052.DashMode.Loop)--进入Loop判断
end

---选点完成后创建连线
function XChar8052:CreatDashPosLink()
    local startPos = {x=0,y=self.dashCenter.y+1,z=0} 
    local endPos = self.dashList[#self.dashList] --最后一个点的位置
    endPos.y = startPos.y --连线高度保持一致

    if #self.dashList == 1 then--如果是第一次选点，那么这里结束了
        local selfPos = self._proxy:GetNpcPosition(self._uuid) --自己的位置
        startPos.x = selfPos.x
        startPos.z = selfPos.z
    else
        local lastSecondPos= self.dashList[#self.dashList-1]
        startPos.x = lastSecondPos.x
        startPos.z = lastSecondPos.z
    end
    local linkID = self._proxy:AddPosLink(startPos,endPos,self.dashLinkEffect,self._uuid,true) --创建连线
    table.insert(self.dashLinkIdList,linkID)
end

---创建冲刺的第一个连线
function XChar8052:CreatStartDashPosLink()
    self:CleanDashLink() --清除以前的
    local selfPos = self._proxy:GetNpcPosition(self._uuid)
    local startPos={x=selfPos.x,y=self.dashCenter.y+1,z=selfPos.z}
    local endPos = self.dashList[#self.dashList] --最后一个点的位置
    endPos.y = startPos.y --连线高度保持一致
    
    local linkID = self._proxy:AddPosLink(startPos,endPos,self.dashLinkEffect,self._uuid,true) --创建连线
    --XLog.Warning("创建链接成功:"..linkID)
    table.insert(self.dashLinkIdList,linkID)
end

function XChar8052:CleanDashLink()
    for i,link in pairs(self.dashLinkIdList) do
        self._proxy:RemoveLink(self._uuid,self.dashLinkIdList[self.nextDashIndex])--到达第几个点就删除几个点
    end
    self.dashLinkIdList={}--清空冲刺线
    self._proxy:RemoveAllNpcPosLink(self._uuid)
end

---移除冲刺时的线
function XChar8052:RemoveDashPosLink()
    self._proxy:RemoveLink(self._uuid,self.dashLinkIdList[self.nextDashIndex])--到达第几个点就删除几个点
end

---冲刺过程中重启检查
function XChar8052:DashReStartCheck()
    if not self._proxy:CheckNpcFullActionState(self._uuid, ENpcAction.Idle, -1) then --不在Idle
        return
    end
    if not self:CheckSelfActionValid() then --不懂不合法
        return
    end
    local suc , actionId,actionType = self._proxy:TryGetCurrentAction(self._uuid)
    if suc then
        for i, skillId in pairs(self.dashAboutSkill) do --检查是不是在放相关技能
            if actionId == skillId then
                return
            end
        end
    end
    
    self:DashReStart() --重启重启！
    
end

---DashLoop检查
function XChar8052:DashLoopTickCheck()
    if not self.dashMode == XChar8052.DashMode.Loop then --不在循环中跳过
        return
    end
    
    local nextPointDistance = self._proxy:GetNpcToPositionDistance(self._uuid,self.dashList[self.nextDashIndex])--获取和下一个点的距离
    --判断到达目标点的条件
    if nextPointDistance <= self.dashArriveCheckRange  then --小于这个距离就等于到达了目的地
        self:OnArrivedDashPoint()
    end
end

---获取方向和坐标的余弦值
function XChar8052:CalculateCosine(direction, p1, ignoreY)
    -- 计算指向点p1的向量
    local vecToP1 = {
        x = p1.x,
        y = p1.y,
        z = p1.z
    }

    -- 如果忽略Y轴，则将Y分量设为0
    if ignoreY then
        direction = {x = direction.x, y = 0, z = direction.z}
        vecToP1 = {x = vecToP1.x, y = 0, z = vecToP1.z}
    end

    -- 计算点积
    local dotProduct = direction.x * vecToP1.x + direction.y * vecToP1.y + direction.z * vecToP1.z

    -- 计算模长
    local magnitudeDir = math.sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
    local magnitudeP1 = math.sqrt(vecToP1.x * vecToP1.x + vecToP1.y * vecToP1.y + vecToP1.z * vecToP1.z)

    -- 避免除以零
    if magnitudeDir == 0 or magnitudeP1 == 0 then
        return 0
    end

    -- 返回余弦值
    return dotProduct / (magnitudeDir * magnitudeP1)
end

---检查是否到正在冲刺的Dash点
function XChar8052:CheckArriveDashPoint()
    local pointPos = self.dashList[self.nextDashIndex] --当前冲刺的技能
    local distance = self._proxy:GetNpcToPositionDistance(self._uuid,pointPos,true) --获得这个点的距离
    if distance <=0.5 then --和坐标位置小于这个值时表示到达点
        self:OnArrivedDashPoint()  --到达点时
    end
end

---到达Dash目标点时
function XChar8052:OnArrivedDashPoint()
    
    ---到点第一时间要做的事情---
    self:RemoveDashPosLink() --删除上一个冲刺连接线
    if self.curDashRound == 1 then
        --根据到达点要做的事情
        if self.nextDashIndex == 2 then
        self:GetDashPoint(2)--新增获取两次点
        end
        if self.nextDashIndex == 3 then
        end
        if self.nextDashIndex == 4 then
        self:GetDashPoint(2)--新增获取两次点
        end
        if self.nextDashIndex == 5 then
        end
        if self.nextDashIndex == 6 then
        self:GetDashPoint(2)--新增获取两次点
        end
        if self.nextDashIndex == 7 then
        end
        if self.nextDashIndex == 8 then
        end
        if self.nextDashIndex == 9 then
        end
        if self.nextDashIndex == 10 then
        end
    end

    if self.curDashRound == 2 then --第二轮
        --根据到达点要做的事情
        if self.nextDashIndex == 2 then
            self:GetDashPoint(2)--新增获取两次点
        end
        if self.nextDashIndex == 3 then
        end
        if self.nextDashIndex == 4 then
            self:GetDashPoint(2)--新增获取两次点
        end
        if self.nextDashIndex == 5 then
        end
        if self.nextDashIndex == 6 then
            self:GetDashPoint(2)--新增获取两次点
        end
        if self.nextDashIndex == 7 then
        end
        if self.nextDashIndex == 8 then
        end
        if self.nextDashIndex == 9 then
        end
        if self.nextDashIndex == 10 then
        end
    end

    --if self.curDashRound == 3 then --第三轮
    --    --根据到达点要做的事情
    --    if self.nextDashIndex == 2 then
    --        self:GetDashPoint(2)--新增获取两次点
    --    end
    --    if self.nextDashIndex == 3 then
    --        self:GetDashPoint(2)--新增获取两次点
    --    end
    --    if self.nextDashIndex == 4 then
    --    end
    --    if self.nextDashIndex == 5 then
    --    end
    --    if self.nextDashIndex == 6 then
    --    end
    --    if self.nextDashIndex == 7 then
    --    end
    --    if self.nextDashIndex == 8 then
    --    end
    --    if self.nextDashIndex == 9 then
    --    end
    --    if self.nextDashIndex == 10 then
    --    end
    --end

    ---结束判断，如果结束就结束了---
    if self.nextDashIndex==#self.dashList then --没有可冲的点，当前要结束了。
        self:OnCurDashRoundEnd()
    return
    end

    ---还没结束要做的事情---
    self.nextDashIndex = self.nextDashIndex+1 --自增1
    --如果还有冲刺的点就看向下一个点继续冲刺。
    local nextPos = self.dashList[self.nextDashIndex]
    self:ForceSkillToPosition(805251,nextPos)--转向下一个点
    self:DashSetDashMode(XChar8052.DashMode.Turn) --设置为转身
end

---Dash结束
function XChar8052:OnDashLoopStop()
    local stopSkill = 805232
    self:ForceSkillToPosition(stopSkill,self.CenterPoint) --向中心点释放瑟提锤
end

---获取下一个DashPoint(起始点)
function XChar8052:GetNextDashPos(startPoint)
    local tempPoint = {}
    local point = nil

    if #self.dashList>3 then--冲刺列表中大于3
        
    end
    
    point = self:GetPriorityMapPoint(startPoint) --优先规则里选点
    if point then
        return
    end
    
    --随机一个点
    return point
end

---返回两个位置点的冲刺类型
function XChar8052:GetDashPointType(p2, p3)
    if self:CheckLineOnDashEdge(p2,p3) then
        --XLog.Warning("为空")
        return XChar8052.DashType.None
    end
    if self:CheckLineCircleIntersectionIgnoreY(self.dashCenter,8,p2,p3) then --连线是否靠近终点一段距离
        --XLog.Warning("中间")
        return XChar8052.DashType.Mid
    end
    --XLog.Warning("边边")
    return XChar8052.DashType.Side
end

---获取Dash冲刺的第一个点
function XChar8052:TryGetDashStartPoint()
    local randomIndex = self._proxy:Random(1,#self.dashMapPointIndexList)
    return self.dashMapPointIndexList[randomIndex]--随机一个固定的点作为初始点
end

---尝试获得该点穿过中间的点
function XChar8052:TryGetDashMidPoint(start)
    local midPosMap ={} --保存符合中间的点
    for k ,v in pairs(self.dashMapPointList) do
        if self:GetDashPointType(start,v) == XChar8052.DashType.Mid then
            table.insert(midPosMap,v)
        end
    end
    return midPosMap[self._proxy:Random(1,#midPosMap)] --随机返回一个靠近中间的位置
end

---尝试获得该点侧面的点
function XChar8052:TryGetDashSidePoint(start)
    local sidePosMap ={} --保存符合中间的点
    for k ,v in pairs(self.dashMapPointList) do
        if self:GetDashPointType(start,v) == XChar8052.DashType.Side then
            table.insert(sidePosMap,v)
        end
    end
    return sidePosMap[self._proxy:Random(1,#sidePosMap)] --随机返回一个边缘的位置
end

---尝试获得穿过Npc的点
function XChar8052:TryGetDashPlayerPoint(start)
    local playerList = self:GetPlayerListInRange(9999)--获取9999范围内的敌人列表。
    
    if #playerList == 0 then --
        if self._proxy:Random(1,2) == 1 then
            return self:TryGetDashSidePoint(start)
        else
            return self:TryGetDashMidPoint(start)
        end
    end
    
    local npcUUID = playerList[self._proxy:Random(1,#playerList)]--随机选择一个玩家
    local tempPlayerPos = self._proxy:GetNpcPosition(npcUUID)
    local playerPos ={x=tempPlayerPos.x,y=tempPlayerPos.y,z=tempPlayerPos.z}
    local offSetP =self:GetPosByPosToPosOffsetDistanceIgnoreY(start,playerPos,0.5) --起点向终点偏移0.5，避免交叉到自己点的位置了
    local endPos = self:GetIntersectionDashPoints(offSetP,playerPos) --从偏移后的点向玩家方向打一个射线
    return endPos --A到玩家连线延长到Dash的矩形上
end

---获取A到B连线做Dash边缘的点
function XChar8052:GetIntersectionDashPoints(p1, p2)
    local left = self.dashCenter.x - self.dashOrthoCenterVerticalPointOffset
    local right = self.dashCenter.x + self.dashOrthoCenterVerticalPointOffset
    local bottom = self.dashCenter.z - self.dashOrthoCenterHorizontalPointOffset
    local top = self.dashCenter.z + self.dashOrthoCenterHorizontalPointOffset

    local dx = p2.x - p1.x
    local dz = p2.z - p1.z

    -- 如果 p1 和 p2 重合，检查 p1 是否在矩形边界上
    if dx == 0 and dz == 0 then
        if p1.x == left or p1.x == right or p1.z == bottom or p1.z == top then
            return p1
        else
            return nil
        end
    end

    local t_values = {} -- 存储 {t, point}

    -- 检查左右边界（当 dx != 0 时）
    if dx ~= 0 then
        -- 左边界
        local t_left = (left - p1.x) / dx
        if t_left >= 0 then
            local z = p1.z + t_left * dz
            if z >= bottom and z <= top then
                table.insert(t_values, {t = t_left, point = {x = left, y = p1.y, z = z}})
            end
        end

        -- 右边界
        local t_right = (right - p1.x) / dx
        if t_right >= 0 then
            local z = p1.z + t_right * dz
            if z >= bottom and z <= top then
                table.insert(t_values, {t = t_right, point = {x = right, y = p1.y, z = z}})
            end
        end
    end

    -- 检查上下边界（当 dz != 0 时）
    if dz ~= 0 then
        -- 下边界
        local t_bottom = (bottom - p1.z) / dz
        if t_bottom >= 0 then
            local x = p1.x + t_bottom * dx
            if x >= left and x <= right then
                table.insert(t_values, {t = t_bottom, point = {x = x, y = p1.y, z = bottom}})
            end
        end

        -- 上边界
        local t_top = (top - p1.z) / dz
        if t_top >= 0 then
            local x = p1.x + t_top * dx
            if x >= left and x <= right then
                table.insert(t_values, {t = t_top, point = {x = x, y = p1.y, z = top}})
            end
        end
    end

    -- 如果没有交点，返回 nil
    if #t_values == 0 then
        return nil
    end

    -- 找到最小的 t 值对应的交点
    local min_t = math.huge
    local intersection_point = nil
    for _, data in ipairs(t_values) do
        if data.t < min_t then
            min_t = data.t
            intersection_point = data.point
        end
    end

    return intersection_point
end

---从A点到B点偏移忽略Y轴的位置
function XChar8052:GetPosByPosToPosOffsetDistanceIgnoreY(p1,p2,offsetDistance)
    -- 计算方向向量
    local dx = p2.x - p1.x
    local dz = p2.z - p1.z

    -- 计算向量长度
    local length = math.sqrt(dx * dx + dz * dz)

    -- 如果向量长度为0（两点重合），则无法确定方向，直接返回p1
    if length == 0 then
        return {x = p1.x, y = p1.y, z = p1.z}
    end

    -- 归一化方向向量
    local normalizedDx = dx / length
    local normalizedDz = dz / length

    -- 计算偏移后的点
    local offsetX = p1.x + normalizedDx * offsetDistance
    local offsetZ = p1.z + normalizedDz * offsetDistance

    return {x = offsetX, y = p1.y, z = offsetZ}
end

---检查点3和点4连线能不能穿过点1画的半径的圆。
function XChar8052:CheckLineCircleIntersectionIgnoreY(p1, radius, p2, p3)
    -- 将点视为二维向量（忽略Y轴），计算向量差
    local function vec2Sub(a, b)
        return {x = a.x - b.x, z = a.z - b.z}
    end

    local function vec2Dot(a, b)
        return a.x * b.x + a.z * b.z
    end

    local function vec2LengthSq(a)
        return a.x * a.x + a.z * a.z
    end

    -- 将点投影到XZ平面
    local center = {x = p1.x, z = p1.z}
    local a = {x = p2.x, z = p2.z}
    local b = {x = p3.x, z = p3.z}

    -- 计算线段向量和圆心到线段起点的向量
    local lineVec = vec2Sub(b, a)
    local centerToA = vec2Sub(center, a)

    -- 计算线段长度的平方
    local lineLengthSq = vec2LengthSq(lineVec)

    -- 如果线段长度为0，则检查点是否在圆内
    if lineLengthSq == 0 then
        return vec2LengthSq(centerToA) <= radius * radius
    end

    -- 计算投影比例t
    local t = vec2Dot(centerToA, lineVec) / lineLengthSq

    -- 限制t在线段范围内
    t = math.max(0, math.min(1, t))

    -- 计算圆心上在线段上的最近点
    local projection = {
        x = a.x + t * lineVec.x,
        z = a.z + t * lineVec.z
    }

    -- 计算最近点到圆心的距离平方
    local distVec = vec2Sub(center, projection)
    local distSq = vec2LengthSq(distVec)

    -- 判断距离是否小于等于半径
    return distSq <= radius * radius
end

---检查两个点的连线是否在四个坐标点的边上。
function XChar8052:CheckLineOnDashEdge(p1,p2)
    local tolerance = 0.2
    local x_left = self.dashMapPointList.l.x
    local x_right = self.dashMapPointList.r.x
    local z_bottom = self.dashMapPointList.d.z
    local z_top = self.dashMapPointList.u.z

    -- Check top edge
    if math.abs(p1.z - z_top) < tolerance and math.abs(p2.z - z_top) < tolerance and
            p1.x >= x_left and p1.x <= x_right and p2.x >= x_left and p2.x <= x_right then
        return true
    end

    -- Check bottom edge
    if math.abs(p1.z - z_bottom) < tolerance and math.abs(p2.z - z_bottom) < tolerance and
            p1.x >= x_left and p1.x <= x_right and p2.x >= x_left and p2.x <= x_right then
        return true
    end

    -- Check left edge
    if math.abs(p1.x - x_left) < tolerance and math.abs(p2.x - x_left) < tolerance and
            p1.z >= z_bottom and p1.z <= z_top and p2.z >= z_bottom and p2.z <= z_top then
        return true
    end

    -- Check right edge
    if math.abs(p1.x - x_right) < tolerance and math.abs(p2.x - x_right) < tolerance and
            p1.z >= z_bottom and p1.z <= z_top and p2.z >= z_bottom and p2.z <= z_top then
        return true
    end

    return false
    
end

---返回点1-2-3连成一条线后形成的夹角角度线忽略Y轴的角度
function XChar8052:CalculatePositionLinkIgnoreYAngle(p1, p2, p3)
        -- 忽略y坐标，只取x和z（二维平面）
        local v1 = {x = p1.x - p2.x, z = p1.z - p2.z}  -- 向量 p2->p1
        local v2 = {x = p3.x - p2.x, z = p3.z - p2.z}  -- 向量 p2->p3

        -- 计算点积 (v1 · v2)
        local dotProduct = v1.x * v2.x + v1.z * v2.z

        -- 计算向量模长
        local v1Magnitude = math.sqrt(v1.x * v1.x + v1.z * v1.z)
        local v2Magnitude = math.sqrt(v2.x * v2.x + v2.z * v2.z)

        -- 避免除零错误（若点重合则返回nil）
        if v1Magnitude == 0 or v2Magnitude == 0 then
            return nil
        end

        -- 计算夹角的余弦值
        local cosTheta = dotProduct / (v1Magnitude * v2Magnitude)

        -- 处理浮点精度可能导致的超出[-1,1]范围的问题
        cosTheta = math.max(-1.0, math.min(1.0, cosTheta))

        -- 计算弧度角并转换为角度
        local angleRad = math.acos(cosTheta)
        local angleDeg = math.deg(angleRad)

        return angleDeg
end

---获取点一定距离外的列表
function XChar8052:GetPointMapBeyondMapPoint(point,distance)
    local tempMap = {}
    for i = 1 ,#self.dashMapPointList do
        if self:GetPositionToPositionDistance(point,self.dashMapPointList[i],true) >= distance then --点的距离大于的话
            table.insert(tempMap,self.dashMapPointList[i]) --添加进列表
        end 
    end

    if #tempMap>0 then--有东西就返回tempMap
        return tempMap
    else
        return nil--没有东西就返回Nil
    end
    
end

--进入循环1
function XChar8052:DashShunEnterLoop1()
    self:ForceSkill(805261)
end

--进入循环2
function XChar8052:DashShunEnterLoop2()
    self:ForceSkill(805262)
end

--进入循环1
function XChar8052:DashShunEnterAttack()
    self:ForceSkill(805263)
end

---Action帧事件获点
function XChar8052:ActionKeyFrameGetDashPoint()
    local isFirst = #self.dashList == 0 --是否之前没有选过点
    if self.curDashRound == 1 then --第一回
        if isFirst then
            self:GetDashPoint(1)
        else
            self:GetDashPoint(1)
        end
        return
    end

    if self.curDashRound == 2 then --第二回
        if isFirst then
            self:GetDashPoint(1)
        else
            self:GetDashPoint(2)
        end
        return
    end

    if self.curDashRound == 3 then --第三回
        if isFirst then
            self:GetDashPoint(3)
        else
            self:GetDashPoint(4)
        end
    end
end

---获取多少次选点
function XChar8052:GetDashPoint(count)
    for i = 1,count do --额外选择次数
        local typeMap = self.dashRound1TypeMap
        if self.curDashRound == 2 then --如果是第二轮就按照第二轮的冲刺方式
            typeMap =self.dashRound2TypeMap
        elseif self.curDashRound == 3 then
            typeMap =self.dashRound3TypeMap
        end
        if self.dashSelectCount>#typeMap then --没有可选次数了
            XLog.Warning("当前回合"..self.curDashRound..",没有剩余选点次数，溢出的选点次数为："..count - i)
            return
        end
        local type =typeMap[self.dashSelectCount] --根据typeMap当前Count来选点
        
        local lastPos = self.dashList[#self.dashList] --最后位置的点作为起点
        if type == XChar8052.DashType.Side then
            --XLog.Warning("选边")
            table.insert(self.dashList,self:TryGetDashSidePoint(lastPos))
        end
        if type == XChar8052.DashType.Mid then
            --XLog.Warning("选中间")
            table.insert(self.dashList,self:TryGetDashMidPoint(lastPos))
        end
        if type == XChar8052.DashType.Player then
            --XLog.Warning("冲玩家")
            table.insert(self.dashList,self:TryGetDashPlayerPoint(lastPos))
        end
        self.dashSelectCount = self.dashSelectCount + 1
        self:CreatDashPosLink() --创建可视化的线
    end
end

---当前冲刺轮结束
function XChar8052:OnCurDashRoundEnd()
    self.nextDashIndex = self.nextDashIndex+1 --自增1
    self:RemoveDashPosLink()
    self:CleanDashLink() --保底清除所有冲刺线
    self:DashSetDashMode(XChar8052.DashMode.End)--状态设置为中场可能会结束流程
    
    self.dashSelectCount = 2 --重置一下Count
    self._proxy:RemoveBuff(self._uuid,8052091) --移除无敌
    
    self:SetPlayerHardLockSelf() --设置玩家强锁自己    
    self:ForceSkillToPosition(805239,self.dashCenter) --向Dash的中心点放瑟提锤用来结束流程。

    --if self.curDashRound > 3 then --结束
    --    self:RemoveBuffAllPlayer(8052301)
    --    self:RemoveBuffAllPlayer(8052302)
    --end
    ----RemoveBuffAllPlayer
end

---冲刺设置当前冲刺回合（带同步）
function XChar8052:DashSetCurRound(round)
    self.curDashRound = round
    self:MonsterSubSetVarSyncValue("curDashRound",self.curDashRound)
end

---冲刺设置当前屏障模式(带同步)
function XChar8052:DashSetDashBoundaryState(state)
    self.dashBoundaryState = state
    self:MonsterSubSetVarSyncValue("dashBoundaryState",self.dashBoundaryState)
end

---设置障碍激活情况
function XChar8052:DashSetObstacleActive(isInside,active)
    if isInside then --是否内圈
        self._proxy:SetObstacleActive(14,active)
        self._proxy:SetObstacleActive(15,active)
        self._proxy:SetObstacleActive(16,active)
        self._proxy:SetObstacleActive(17,active)
    else
        self._proxy:SetObstacleActive(10,active)
        self._proxy:SetObstacleActive(11,active)
        self._proxy:SetObstacleActive(12,active)
        self._proxy:SetObstacleActive(13,active)
    end
end

---移除所有玩家的ui隐藏
function XChar8052:DashRemoveAllPlayerUIHide()
    self:RemoveBuffAllPlayer(8052134)
end

---处理Dash技能开始时的子弹控制
function XChar8052:DashStartBulletControl()
    local npcList = self._proxy:GetPlayerNpcList()
    for i , npc in pairs(npcList)do--遍历玩家列表
        self:DashLoopDelayFireBullet(15,0.5,true,npc)
    end
end

---冲刺的时候隔一段事件发射一次子弹(次数，间隔，是否开始触发。)延迟子弹
function XChar8052:DashLoopDelayFireBullet(num,interval,isStartTrigger,npc)
    local time = 0
    if isStartTrigger then
        self:DashFireBulletToNpc(npc)
        num = num - 1 --消耗了一次
    end
    for i =1  , num + 1 do
        time = time + interval
        self._proxy:AddTimerTask(time + interval , function()
            self:DashFireBulletToNpc(npc)
        end)
    end
end

---处理Dash技能过程
function XChar8052:DashProcessBulletControl()
    local npcList = self._proxy:GetPlayerNpcList()
    for i , npc in pairs(npcList)do--遍历玩家列表
        self:DashLoopDelayFireBullet(10,0.5,true,npc)
    end
end

---向Npc发射Dash的导弹
function XChar8052:DashFireBulletToNpc(npc)
    self._proxy:LaunchMissile(self._uuid,npc,80525806,80525013,1)
end

--endregion

--region AirFire机制技能

---攻击激光初始化
function XChar8052:AirFireInit()
    -----------怪物位置-----------
    self.airFireMonsterPoint = self._proxy:GetSpot(10) --浮空机制怪物位置
    self.airFirePlayerPointList ={
        [1] = {x= 108,y=self.levelCenterPoint.y,z =122},
        [2] = {x= 108,y=self.levelCenterPoint.y,z =112},
        [3] = {x= 108,y=self.levelCenterPoint.y,z =132},
    } --三个玩家的位置     中左右
    self.airFirePlayerShieldPointList ={
        [1] = {x= 125,y=self.levelCenterPoint.y,z =122},
        [2] = {x= 125,y=self.levelCenterPoint.y,z =112},
        [3] = {x= 125,y=self.levelCenterPoint.y,z =132},
    } --三个护盾的位置 中左右
    
    -----------怪物屏障-----------
    self.airFireMonsterShieldUUID = nil --保存怪物屏障子弹的UUID
    self.airFireMonsterShieldTableId = 80525203 --怪物屏障子弹

    -----------玩家屏障-----------
    self.airFirePlayerShieldSucTableId = 80525205 --玩家屏障成功
    self.airFirePlayerShieldTableId = 80525204 --玩家屏障默认
    self.airFirePlayerShieldUUIDList ={} --保存玩家屏障子弹的UUID列表
    self.airFirePlayerShieldCheckRadius = 5--浮空机制玩家护盾的半径，用来检查周围是否有玩家。
    self.airFirePlayerShieldReferee = { --保存三个护盾的完成情况
        [1] = false,
        [2] = false,
        [3] = false,
    }
    self.airFirePlayerShieldCheckStarted = false --是否开启玩家护盾情况检查。
end

---浮空攻击启动
function XChar8052:AirFireStart()
    self._proxy:SetNpcPosition(self._uuid,self.airFireMonsterPoint) --怪物传送位置
    self._proxy:LookAtPositionImmediately(self._uuid,self.levelCenterPoint)--看向场地中心
    self:SetPlayerHardLockSelf() --设置玩家强锁自己  
end

---浮空攻击创造护盾
function XChar8052:AirFireCreatShield()
    --怪物身上的护盾
    ---创建怪物身上的护盾
    local isSuc
    isSuc,self.airFireMonsterShieldUUID = self._proxy:LaunchMissile(self._uuid,self._uuid,80525203,80525203)
     self._proxy:LaunchMissile(self._uuid,self._uuid,80525203,80525209)
    self:AirFireCreatPlayerShield() --创建玩家护盾
    for i,playerUUID in pairs(self._proxy:GetPlayerNpcList()) do --获取和设置玩家位置
        self._proxy:ApplyMagic(self._uuid,playerUUID,8052101) --设置浮空机制相机偏移
    end
end

---浮空攻击清理所有护盾
function XChar8052:AirFireCleanShield()
    if self.airFireMonsterShieldUUID then
        self._proxy:DestroyMissileByUUID(self.airFireMonsterShieldUUID)
        self.airFireMonsterShieldUUID = nil
    end
    self:AirFireCleanPlayerShield() --清理玩家的护盾
    for i,playerUUID in pairs(self._proxy:GetPlayerNpcList()) do --获取和设置玩家位置
        self._proxy:ApplyMagic(self._uuid,playerUUID,8052102) --移除浮空机制相机偏移
    end
end

---攻击激光初始化
function XChar8052:AirFireEnterLoop()
    self:ForceSkill(805253) --切换到循环
end

---浮空攻击创造玩家护盾
function XChar8052:AirFireCreatPlayerShield()
    self:AirFireCleanPlayerShield() --尝试清理一下玩家护盾
    self.airFirePlayerShieldCheckStarted = true --开启要检查护盾情况
    local suc = nil
    local id = nil
    for i , pos in pairs(self.airFirePlayerShieldPointList) do
        suc,id = self._proxy:LaunchMissileFromPosToPos(self._uuid,80525806,80525204,pos,pos) --目标点出现子弹
        self.airFirePlayerShieldUUIDList[i] =id--保存到子弹列表
    end
end

---浮空攻击玩家应对成功
function XChar8052:AirFireChallengeSuccess()
    self:ForceSkill(805255)
end

---浮空攻击玩家应对失败
function XChar8052:AirFireChallengeFail()
    self:ForceSkillToPosition(805254,self.levelCenterPoint) --向场地中心释放惩罚技能
end

---浮空攻击清空玩家护盾
function XChar8052:AirFireCleanPlayerShield()
    if #self.airFirePlayerShieldUUIDList == 0 then
        return
    end
    for i , id in pairs(self.airFirePlayerShieldUUIDList) do
        self._proxy:DestroyMissileByUUID(id)
    end
    self.airFirePlayerShieldUUIDList={}
    self.airFirePlayerShieldReferee = { --三个玩家护盾的完成情况全部设置为F
        [1] = false,
        [2] = false,
        [3] = false,
    }
    self.airFirePlayerShieldCheckStarted = false --清理的时候关闭一下Tick
end

---玩家护盾切换状态
function XChar8052:AirFirePlayerShieldSwitch(index,switch)
    self._proxy:DestroyMissileByUUID(self.airFirePlayerShieldUUIDList[index])--先清除当前子弹
    local suc,id,pos
    pos = self.airFirePlayerShieldPointList[index]
    if switch then --机制成功的子弹
        suc,id = self._proxy:LaunchMissileFromPosToPos(self._uuid,80525806,80525205,pos,pos) --目标点出现子弹
    else--机制失败的默认子弹
        suc,id = self._proxy:LaunchMissileFromPosToPos(self._uuid,80525806,80525204,pos,pos) --目标点出现子弹
    end
    self.airFirePlayerShieldReferee[index] = switch
    self.airFirePlayerShieldUUIDList[index] =id--保存到子弹列表
end

---玩家护盾每帧检测满足情况
function XChar8052:AirFirePlayerShieldTickCheck()
    if self.airFirePlayerShieldCheckStarted == false then
        return
    end
    for i ,npc in pairs(self.airFirePlayerShieldUUIDList) do
        local count = self:GetPlayerCountByPosRadiusIgnoreY(self.airFirePlayerShieldPointList[i],2.5)
        if self.airFirePlayerShieldReferee[i] then
            if count <=0 then
                self:AirFirePlayerShieldSwitch(i,false)
            end
        else
            if count >0 then
                self:AirFirePlayerShieldSwitch(i,true)
            end
        end
    end
end

--endregion

--region 事件系统执行

---监听事件，目前仅监听自己发出来的
function XChar8052:OnNpcSkillActionKeyframeSendEvent(launcher,eventName,skillActionId,keyFrameId,skillId)
    if launcher ~= self._uuid then
        return
    end
    self:ActionKeyFrameEventListAdd(eventName)--添加进事件列表
end

---添加buff事件
function XChar8052:OnNpcAddBuffEvent(casterNpcUUID, npcUUID, buffId, buffKinds, buffUUId)
    if casterNpcUUID~=self._uuid then --下面只检查自己添加出去的buff
        return
    end
    self:ParryMainLogic(npcUUID,buffId)--拼刀主检测
    self:SoftFuryHitDamageHitCheck(npcUUID,buffId)
end

---受到伤害后事件
function XChar8052:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    Base.OnNpcDamageEvent(self,launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    if targetId ~= self._uuid then
        return
    end
    --自己受到伤害时检查跟Npc的拼刀
    if self:CheckParryNpc(launcherId) then
        self:ParryToNpc(launcherId)
    end
end

---拼刀触发前
function XChar8052:OnNpcBeforeTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    --不是自己或不是技能目标触发的不管
    if triggerNpcUUID ~= self._uuid or (not self:CheckNpcIsCurSkillTarget(counterNpcUUID))  then
        return
    end
    
    local parryType = self:GetParryType(triggerNpcUUID,counterNpcUUID,triggerTag,counterTag)
    
    --self._proxy:CastWrestle(self._uuid,counterNpcUUID,805201) --进入角力
    --if triggerNpcUUID then
    --    return
    --end
    
    if parryType == 1 or parryType == 3 then --打断拼刀
        self:BeParryByNpc(counterNpcUUID)--被普通拼刀
    end

    if parryType == 2 then --不打断拼刀
        --self:FreezeFrameLightToNpc(self._uuid)--顿帧
        --self:FreezeFrameLightToNpc(counterNpcUUID)--顿帧
        --XLog.Warning("不打断拼刀")
        self._proxy:LaunchMissile(self._uuid,triggerNpcUUID,80520150,80520521)--拼刀特效
    end

    --if parryType == 3 then --角力
    --    if not self:CheckCurIsOverDrive() then --不是OD时正常被拼
    --        self:BeParryByNpc(counterNpcUUID)--被普通拼刀
    --    else--OD时被拼刀进入角力
    --        if self._proxy:CheckBuffByKind(counterNpcUUID, 1000487) then
    --            self._proxy:CastWrestle(self._uuid,counterNpcUUID,805201) --进入角力
    --        else
    --            self._proxy:CastMultiParry(self._uuid, counterNpcUUID, 805201) --多人角力
    --        end
    --        
    --    end
    --end
end

---拼刀触发后
function XChar8052:OnNpcAfterTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    if triggerNpcUUID ~= self._uuid then
        return
    end

end

---怪物技能释放成功后
function XChar8052:OnMonsterCastSkillSuccessAfter(skill)
    --有的技能需要
end

---怪物自己死亡时
function XChar8052:OnMonsterSelfDie()
    self._proxy:ApplyMagic(self._uuid,self._uuid,1000513) --移除这个Buff
end

---处理怪物受到伤害时的受击
function XChar8052:OnMonsterGetDamageBeHit(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    XLog.Warning("受击")
    if self:CheckNpcIsPlayer(launcherId) then
        self._proxy:LookAtPositionImmediately(self._uuid,self._proxy:GetNpcPosition(launcherId)) --看向目标所在位置
        self:ForceSkillToNpc(805245,launcherId)
    else
        self:ForceSkill(805245)
    end
end
--endregion

--region 角力

--进入循环1
function XChar8052:OffsetEnterLoop1()
    self:ForceSkillToTarget(805265)
end

--进入循环2
function XChar8052:OffsetEnterLoop2()
    self:ForceSkillToTarget(805266)
end

--攻击
function XChar8052:OffsetEnterGo()
    self:ForceSkillToTarget(805267)
end

--endregion

--region OD机制

---怪物进入OD后
function XChar8052:MonsterEnterOverDriveAfter()
    if self:CheckIsOnSoftFury() then --狂暴的时候就不处理了
        return
    end
    if self:GetCurPhase() == 1 then --1阶段OD
        self:EnterSkillGiveCd(805201,10) --10秒后格挡
        self:EnterSkillGiveCd(805248,5) --5秒后OD推进拳
        self:EnterSkillGiveCd(805249,10) --10秒后OD瑟提锤
        self:EnterSkillGiveCd(805258,15) --15秒后Dash启动
        self:EnterSkillGiveCd(805252,15) --15秒后浮空机制启动
        return
    end
    --2阶段及以上：主要是不死斩，然后才是OD的其他技能
    self:EnterSkillGiveCd(805201,10) --10秒后格挡
    self:EnterSkillGiveCd(805248,5) --5秒后OD推进拳
    self:EnterSkillGiveCd(805249,25) --10秒后OD瑟提锤
    self:EnterSkillGiveCd(805258,25) --15秒后Dash启动
    self:EnterSkillGiveCd(805252,20) --15秒后浮空机制启动
    self:EnterSkillGiveCd(805277,5) --5秒后可以放光刃二连
    self:EnterSkillGiveCd(805278,15) --5秒后可以放光刃二连
    
    self:NpcTimerEnterGiveCd(3,20) --15秒后可以释放蓄力不死斩
end

---怪物退出OD后
function XChar8052:OnMonsterExitBreakAfter()
    self:TryRiseCurPhase() --退出Break时提升阶段
    self:EnterSkillGiveCd(805201,15) --格挡
    --退出OD后
    self:InitSkillCd(805201,25,25) --格挡
end

--endregion

--region 阶段

--阶段配置

--endregion

--region 小辉辉战斗专属逻辑不包括机制

---回中检查，检查是否要回中
function XChar8052:GoCenterCheck()
    local dis = self._proxy:GetNpcToPositionDistance(self._uuid,self.levelCenterPoint,true) --获取与中心点的距离
    --XLog.Warning(dis)
    if dis <=26 then --超过中心太远距离了
        return
    end
    if not self:CheckNpcTimer(2) then -- 检查回中CD
        return
    end
    if self:CastSkillToPosition(805232,self.levelCenterPoint) then
        self:NpcTimerEnterCd(2)
    end
end

---移动射击时每帧检测
function XChar8052:MoveFireTickCheck()
    if not self._proxy:CheckNpcCurrentAction(self._uuid, 805221) then --在移动射击的过程中
        return
    end
    
    local success , time =self._proxy:TryGetNpcCurrentActionElapsedTime(self._uuid)
    
    if not success then
        return
    end

    if not  (time >= 1.4 and time <=2.6) then --移动射击的后摇
        return
    end
    local skillList ={
        [805277] = 10, --OD光刃二连
        [805278] = 10, --OD光刃三连
        [805248] = 10,  --OD连续推进拳
        [805249] = 10,  --OD瑟提锤
        [805227] = 10, --升龙腿
        [805224] = 10,  --光刃二连
        [805216] = 10,  --地面蓄力炮（10）
        [805229] = 10,  --重火锤
        [805230] = 10,  --后退斩
        [805209] = 10 , --下段斩
        [805232] = 10,  --瑟提锤
        [805208] = 10,  --中远距离：推进拳（15）
        [805204]=  10,  --欧拉拳（35）
        [805207] = 10,  --交叉射击：近距离后退拉开距离（）
        [805221] = 10,  --超远距离：移动射击（0）远程
        [805203]=  10,   --上勾拳（0）
        [805234]=  10,   --二连拳（0）
        [805202]=  10,   --反身拳（0）
    }
    local skill
    ---移动射击且可以衔接的时候
    if self:CheckTargetDistance(8) then --优先攻击当前目标，如果当前目标在
        skill = self:GetAbleSkillByWeightsToNpc(skillList,self:GetTarget())
        if skill then
            if self:ForceSkillToTarget(skill) then --如果对目标释放技能成功就直接返回
                return
            end 
        end
    end
    
    --目标太远的时候随机找附近的玩家攻击。
    for i, npc in pairs(self._proxy:GetPlayerNpcList())do 
        if self:CheckTargetValidByNpc(npc) and self._proxy:CheckNpcDistance(self._uuid,npc,6) then --活着的6m范围内的玩家
            skill = self:GetAbleSkillByWeightsToNpc(skillList,npc)
            if skill then
                if self:ForceSkillToNpc(skill,npc) then --如果对目标释放技能成功就直接返回
                    return
                end
            end
        end
    end
end

--轻冻结帧对Npc
function XChar8052:FreezeFrameLightToNpc(target)
    self._proxy:ApplyMagic(self._uuid, target, 8052029, 1)
end

--轻冻结帧对Npc
function XChar8052:FreezeFrameMidToNpc(target)
    self._proxy:ApplyMagic(self._uuid, target, 8052030, 1)
end

--endregion

--region 软狂暴专区

--进入软狂暴后
function XChar8052:OnEnterSoftFuryAfter()
    local castGroup={
        {--OD：Dash机制
            [805258] = 10,  --Dash机制启动
        },
        {--OD:强力技能
            [805204]=  50,  --欧拉拳（35）
            [805277] = 30, --OD光刃二连
            [805278] = 30, --OD光刃三连
            [805248] = 10,  --OD连续推进拳
            [805249] = 50,  --OD瑟提锤
            [805223] = 10,  --光刃上天
        },
    }
    
    ----格挡解放---
    self:InitSkillCd(805201,0,15) --格挡
    -------------
    
    ----闪避解放（但是好像并没有闪避的技能）----
    self:InitNpcTimer(1,2,8) --闪避CD
    self:InitNpcTimer(2,15,15) --连续闪避CD，闪避时触发。
    ----闪避解放----
    
    ------OD技能处理一下配置-------------------------------
    self:InitSkillCd(805204,0,0) --OD：欧拉拳
    self:InitSkillCd(805249,0,0) --OD：瑟提锤
    self:InitSkillCd(805248,0,15) --OD：连续Plus推进拳
    self:InitSkillCd(805277,0,10) --OD：光刃二连
    self:InitSkillCd(805278,0,10) --OD：光刃三连
    self:InitSkillCd(805223,15,40) --光刃上天
    
    self:InitNpcTimer(3,10,15)--OD：蓄力不死斩启动技能
    
    self.skillConfigs[805248].IsNeedODState = false
    self.skillConfigs[805277].IsNeedODState = false
    self.skillConfigs[805278].IsNeedODState = false
    self.skillConfigs[805275].IsNeedODState = false
    self.skillConfigs[805249].IsNeedODState = false
    self.skillConfigs[805223].IsNeedODState = false--光刃上天
    self.skillConfigs[805248].PhaseNeed = {  }--OD：连续Plus推进拳
    self.skillConfigs[805277].PhaseNeed = {  }--OD：光刃二连
    self.skillConfigs[805278].PhaseNeed = {  }--OD：光刃三连
    self.skillConfigs[805275].PhaseNeed = {  }--OD：蓄力不死斩启动技能
    self.skillConfigs[805249].PhaseNeed = {  }--OD：瑟提锤
    self.skillConfigs[805223].PhaseNeed = {  }--光刃上天
    ------OD技能处理一下变成新的-------------------------------
    
    self:SetCastGroup(castGroup) --设置成新的技能组
end

--软狂暴伤害命中标记
function XChar8052:SoftFuryHitDamageHitCheck(npcUUID,buffId)
    if buffId ~= 8052132 then
        return
    end
    local buffCount = self._proxy:GetBuffStacks(npcUUID,8052132)
    local damageMagic = 8052461 --默认8000
    if buffCount == 2 then --第二次一万
        damageMagic = 8052462
    elseif buffCount >= 3 then --三次以上斩杀
        damageMagic = 8052464
    elseif buffCount == 4 then
        damageMagic = 8052463
    elseif buffCount >= 5 then
        damageMagic = 8052464
    end
    --XLog.Warning("造成了伤害:"..damageMagic)
    self._proxy:ApplyMagic(self._uuid,npcUUID,damageMagic) --造成伤害
end

--endregion

--region 闪避

---闪避
function XChar8052:DoDodge()
    
end

---前闪
function XChar8052:FrontDodge()
    local skill = 805210
    self:ForceSkillToTarget(skill)
end

---后闪
function XChar8052:BackDodge()
    local skill = 805211
    self:ForceSkillToTarget(skill)
end

---左闪
function XChar8052:LeftDodge()
    local skill = 805212
    self:ForceSkillToTarget(skill)
end

---右闪
function XChar8052:RightDodge()
    local skill = 805213
    self:ForceSkillToTarget(skill)
end
--endregion

--region 拼刀控制

---检查是否要对Npc使用格挡(npc)
function XChar8052:CheckParryNpc(npc)
    local angle = 135
    local buffKind = 8052001
    if npc ~= self:GetTarget() then --目标检查
        return false
    end
    if not self._proxy:CheckNpc(npc) then--不存在放过
        return
    end
    if not self:CheckTargetValidByNpc(npc) then --放过死人
        return
    end
    if not self:CheckTargetDistance(npc,3.5) then --目标需要在3.5米内
        return false
    end
    if not self:CheckSkillCdDone(805201) then --检查格挡技能CD
        return false
    end
    if not self._proxy:CheckNpcInAngle(self._uuid,npc,angle) then--角度范围检查
        return false
    end
    if not  self._proxy:CheckBuffByKind(self._uuid,buffKind) then--可格挡标记检查
        return false
    end
    return true
end

---被Npc触发格挡（npc）
function XChar8052:ParryToNpc(triggerNpc)
    --self:SetTarget(triggerNpc)--设置为战斗目标
    self._proxy:SetNpcFaceToPosition(self._uuid, self._proxy:GetNpcPosition(triggerNpc))--看向触发格挡的Npc
    self:ForceSkillToNpc(805201,triggerNpc)--对触发弹反的Npc释放拼刀技能
    self._proxy:RemoveBuff(self._uuid,8052001) --删除格挡标记
end

---拼刀主逻辑(npcuuid，buffuuid）
function XChar8052:ParryMainLogic(npcUUID,buffId)
    if (buffId == 8052026) and self:CheckBeParryByNpc(npcUUID) then--拼刀检查
        self:BeParryByNpc(npcUUID)--检查通过，被Npc触发弹反
    end
end

---对Npc检查拼刀条件(npc)
function XChar8052:CheckBeParryByNpc(npc)
    return self._proxy:CheckBuffByKind(npc,105234) or self._proxy:CheckBuffByKind(npc,105233)--检查Npc身上是否有这几个标记
end

---被Npc触发弹刀(npc)
function XChar8052:BeParryByNpc(triggerNpc)
    --local isOnLand = self._proxy:CheckBuffByKind(self._uuid,8052105)
    --if isOnLand then --地面只有一种攻击
    --    self:HandleBeParry(805245,triggerNpc)
    --    return
    --end
    local buffId = 8052033 --检查的BuffID
    local maxCount = 2 --拼刀最大次数
    local phase1Skill = 805233 --小击飞
    local phase2Skill = 805214 --再来一次
    local phase3Skill = 805233 --大击飞
    self:SetTarget(triggerNpc)--设置为战斗目标
    
    --一阶段、不在软狂暴、不在OD时直接击飞结束
    if self:GetCurPhase()<=1 and (not self:CheckIsOnSoftFury()) and (not self:CheckCurIsOverDrive()) then 
        self:HandleBeParry(phase1Skill,triggerNpc)--一阶段小击飞
        return
    end
    
    --当前拼刀层数+1
    self._proxy:ApplyMagic(self._uuid,self._uuid,buffId,1)--拼刀层数增加一层
    local buffCount = self._proxy:GetBuffStacks(self._uuid,buffId) --获取当前拼刀次数
    
    ---二阶段、软狂暴或OD时看拼刀是否到达次数限制，到达时直接结束。
    if buffCount >= maxCount then --
        self:HandleBeParry(phase3Skill,triggerNpc)--二阶段击飞结束
        return
    end
    
   
    
    self:HandleBeParry(phase2Skill,triggerNpc)--再拼一次
    
end

---处理被拼刀（skill,npc）
function XChar8052:HandleBeParry(skill,npc)
    self._proxy:SetNpcFaceToPosition(self._uuid, self._proxy:GetNpcPosition(npc))--看向触发拼刀的Npc
    self:ForceSkillToNpc(skill,npc)--对触发弹反的Npc释放拼刀技能
end

--endregion

--region Action帧事件执行
---创建OD的场地不死斩
function XChar8052:CreatSceneMortalBlade()

    local num = self._proxy:Random(1,4)--四种方位随机出现一种
    local selfPos = self._proxy:GetNpcPosition(self._uuid) --获取自己的位置
    local offsetDistance = 21 --圆圈偏移多少
    local rotaOffset = {
        [1] = {x=0,y=0,z=0},
        [2] = {x=0,y=135,z=0},
        [3] = {x=0,y=225,z=0}
    }
    --local offsetList ={
    --    [1] ={
    --        [1] = {x=0,y=0,z=25},
    --        [2] = {x=-15,y=0,z=-20},
    --        [3] = {x=15,y=0,z=-20}
    --    },
    --    [2] ={
    --        [1] = {x=0,y=0,z=25},
    --        [2] = {x=-15,y=0,z=-20},
    --        [3] = {x=15,y=0,z=-20}
    --    },
    --    [3] ={
    --        [1] = {x=0,y=0,z=25},
    --        [2] = {x=-15,y=0,z=-20},
    --        [3] = {x=15,y=0,z=-20}
    --    },
    --    [4] ={
    --        [1] = {x=0,y=0,z=25},
    --        [2] = {x=-15,y=0,z=-20},
    --        [3] = {x=15,y=0,z=-20}
    --    }
    --}
    local posList={} --确认用来创建三个子弹位置的
    --posList[1] ={x=selfPos.x+offsetList[1][1].x,y=selfPos.y+offsetList[1][1].y,z=selfPos.z+offsetList[1][1].z} --第一个子弹位置
    --posList[2] ={x=selfPos.x+offsetList[1][2].x,y=selfPos.y+offsetList[1][2].y,z=selfPos.z+offsetList[1][2].z} --第二个子弹位置
    --posList[3] ={x=selfPos.x+offsetList[1][3].x,y=selfPos.y+offsetList[1][3].y,z=selfPos.z+offsetList[1][3].z} --第三个子弹位置

    --
    posList[1]= self._proxy:GetNpcOffsetPositionByFacing(self._uuid,rotaOffset[1],offsetDistance)
    posList[2]= self._proxy:GetNpcOffsetPositionByFacing(self._uuid,rotaOffset[2],offsetDistance)
    posList[3]= self._proxy:GetNpcOffsetPositionByFacing(self._uuid,rotaOffset[3],offsetDistance)
    
    --local posList = {} --
    --if num == 1 then
    --    posList[1] = {x=self.levelCenterPoint.x,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z+25}
    --    posList[2] = {x=self.levelCenterPoint.x-15,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z-20}
    --    posList[3] = {x=self.levelCenterPoint.x+15,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z-20}
    --elseif num == 2 then
    --    posList[1] = {x=self.levelCenterPoint.x,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z-25}
    --    posList[2] = {x=self.levelCenterPoint.x-15,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z+20}
    --    posList[3] = {x=self.levelCenterPoint.x+15,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z+20}
    --elseif num == 3 then
    --    posList[1] = {x=self.levelCenterPoint.x+25,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z}
    --    posList[2] = {x=self.levelCenterPoint.x-20,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z-15}
    --    posList[3] = {x=self.levelCenterPoint.x-20,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z+25}
    --else
    --    posList[1] = {x=self.levelCenterPoint.x-25,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z}
    --    posList[2] = {x=self.levelCenterPoint.x+20,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z-15}
    --    posList[3] = {x=self.levelCenterPoint.x+20,y=self.levelCenterPoint.y,z=self.levelCenterPoint.z+15}
    --end
    
    
    -----在上面位置位置上创建这几个子弹
    self._proxy:LaunchMissileFromPosToPos(self._uuid,80520170,80527614,posList[1],posList[1])
    self._proxy:LaunchMissileFromPosToPos(self._uuid,80520170,80527614,posList[2],posList[2])
    self._proxy:LaunchMissileFromPosToPos(self._uuid,80520170,80527614,posList[3],posList[3])

end

--endregion

--region 连招控制

--尝试执行闪避

--尝试软狂暴时闪避，给强力技能用
function XChar8052:TrySoftFuryDodge()
    if not self:CheckIsOnSoftFury() then--非软狂暴时候直接返回
        return
    end
    self:TryDoDodge()
end

--尝试执行闪避
function XChar8052:TryDoDodge()
    local posOffset = {x=0,y=0,z=0} --位置偏转
    local rotaOffset = {x=0,y=-180,z=0} --旋转偏转
    local dodgeGroup = {  } --闪避的列表
    if self:CheckNpcTimer(1) then--闪避CD
        self.dodgeRemainCount = 1 --可以闪避一次 
        self:NpcTimerEnterCd(1)
    end
    if self.dodgeRemainCount<= 0 then --没有次数，释放失败。
        return false
    end
    
    if self:CheckNpcTimer(2) then --连续闪避CD检查
        self.dodgeRemainCount = self._proxy:Random(2,3) --连续闪避2-3次
        self:NpcTimerEnterCd(2) 
    end
    
    local canDodgeList ={ --不同方向是否可以冲刺
        front = false,
        back = false,
        left = false,
        right = false,
    }
    
    --有障碍的地方就是False
    canDodgeList.front =  not self._proxy:CheckNpcRayCastObstacle(self._uuid,posOffset,  {x=0,y=0,z=0} ,3) --前
    canDodgeList.back =  not self._proxy:CheckNpcRayCastObstacle(self._uuid,posOffset, { x=0,y=180,z=0 },3) --
    canDodgeList.left =  not self._proxy:CheckNpcRayCastObstacle(self._uuid,posOffset, { x=0,y=270,z=0 },3) --左
    canDodgeList.right =  not self._proxy:CheckNpcRayCastObstacle(self._uuid,posOffset, { x=0,y=90,z=0 },3) --右
    
    if canDodgeList.front and not self:CheckTargetDistance(4) then --需要3m外才会有往前的
        dodgeGroup[805210] = 20
        if not self:CheckTargetDistance(10) then --10m外
            dodgeGroup[805210] = 100
        elseif not self:CheckTargetDistance(8) then--8-10
            dodgeGroup[805210] = 40
        elseif not self:CheckTargetDistance(6) then --6-8
            dodgeGroup[805210] = 30
        end
        if self:CheckTargetDistance(4) then --4m内就别推了哥
            dodgeGroup[805210] = 0
        end
    end
    if canDodgeList.back then --可以向后
        dodgeGroup[805211] = 10
        if self:CheckTargetDistance(2.5) then --靠太近就不往前了
            dodgeGroup[805211] = 30
        end
    end
    if canDodgeList.left then
        dodgeGroup[805212] = 10
        if self.dodgeRemainCount > 1 then --优先左右晃
            dodgeGroup[805212] = 30
        end
    end
    if canDodgeList.right then
        dodgeGroup[805213] = 10
        if self.dodgeRemainCount > 1 then --优先左右晃
            dodgeGroup[805212] = 30
        end
    end

    if (not canDodgeList.front) and (not canDodgeList.back) and  (not canDodgeList.left) and (not canDodgeList.right) then
        dodgeGroup = nil
    end
    if not dodgeGroup  then --没有可以冲刺的就直接返回别冲刺了
        return false
    end

    self:ForceCastSkillToTargetByWeights(dodgeGroup)
    self.dodgeRemainCount = self.dodgeRemainCount - 1 
    return true --释放成功
end

--闪避后衔接
function XChar8052:DodgeConnect()
    local posOffset = {x=0,y=0,z=0} --位置偏转
    local rotaOffset = {x=0,y=-180,z=0} --旋转偏转
    local dodgeGroup = {  } --闪避的列表
    if self:CheckNpcTimer(1) then--闪避CD
        self.dodgeRemainCount = 1 --可以闪避一次 
        self:NpcTimerEnterCd(1)
    end
    if self.dodgeRemainCount<= 0 then --没有次数，释放失败。
        return false
    end

    if self:CheckNpcTimer(2) then --连续闪避CD检查
        self.dodgeRemainCount = self._proxy:Random(2,3) --连续闪避2-3次
        self:NpcTimerEnterCd(2)
    end

    local canDodgeList ={ --不同方向是否可以冲刺
        front = false,
        back = false,
        left = false,
        right = false,
    }

    --有障碍的地方就是False
    canDodgeList.front =  not self._proxy:CheckNpcRayCastObstacle(self._uuid,posOffset,  {x=0,y=0,z=0} ,3) --前
    canDodgeList.back =  not self._proxy:CheckNpcRayCastObstacle(self._uuid,posOffset, { x=0,y=180,z=0 },3) --
    canDodgeList.left =  not self._proxy:CheckNpcRayCastObstacle(self._uuid,posOffset, { x=0,y=270,z=0 },3) --左
    canDodgeList.right =  not self._proxy:CheckNpcRayCastObstacle(self._uuid,posOffset, { x=0,y=90,z=0 },3) --右

    if canDodgeList.front and not self:CheckTargetDistance(10) then --10米外可能向前
        dodgeGroup[805210] = 5
    end
    if canDodgeList.back then --可以向后
        dodgeGroup[805211] = 10
        if self:CheckTargetDistance(5) then --5m范围内更高概率向后
            dodgeGroup[805211] = 30
        end
    end
    if canDodgeList.left then
        dodgeGroup[805212] = 10
    end
    if canDodgeList.right then
        dodgeGroup[805213] = 10
    end

    if (not canDodgeList.front) and (not canDodgeList.back) and  (not canDodgeList.left) and (not canDodgeList.right) then
        dodgeGroup = nil
    end
    XLog.Warning(dodgeGroup)
    if not dodgeGroup  then --没有可以冲刺的就直接返回别冲刺了
        return false
    end

    self:ForceCastSkillToTargetByWeights(dodgeGroup)
    self.dodgeRemainCount = self.dodgeRemainCount - 1
    return true --释放成功
end


--上天：光刃上天衔接
function XChar8052:AirGoUpConnect()
    --XLog.Warning("光刃上天衔接")
    self.airAttackRemainCount = 3 --光刃上天
    local skillGroup = { --空中攻击起手
        [805217] = 10,--左推1
        [805218] = 10,--右推1
    }
    ---上天三技能进入CD---
    self:EnterSkillCd(805223)--光刃上天
    self:EnterSkillCd(805274)--OD胸炮起跳
    self:EnterSkillCd(805227)--升龙腿
    self:ForceCastSkillToTargetByWeights(skillGroup)
end

---上天：胸炮起跳版衔接
function XChar8052:JumpLaserConnect()
    XLog.Warning("胸炮起跳版")
    --if self:GetCurPhase() < 2 then --一阶段空中不攻击
    --    return
    --end
    
    ---上天组合攻击进CD---
    self:EnterSkillCd(805223)--光刃上天
    self:EnterSkillCd(805274)--胸炮起跳
    self:EnterSkillCd(805227)--升龙腿
    
    if not self:CheckCurIsOverDrive() then--OD状态下可能会释放下面的攻击技能
        return
    end
    
    local skills = {--要判断的技能释放列表
       [805217] = 10,--左推
       [805218] = 10,--右推
       [805228] = 10,--空落锤
    }
    self:ForceCastSkillToTargetByWeights(skills)
    
    
end
---上天：升龙腿衔接
function XChar8052:UpDragonLegConnect()
    --XLog.Warning("升龙腿衔接")
    --self.airAttackRemainCount = 3 --光刃上天
    --local skillGroup = { --空中攻击起手
    --    --[805217] = 10,--左推
    --    --[805218] = 10,--右推
    --    --[805225] = 10,--OD:胸炮浮空版（未有）
    --    --[805225] = 10,--胸炮浮空版
    --}
    -----上天三技能进入CD---
    --self:EnterSkillCd(805223)--光刃上天
    --self:EnterSkillCd(805226)--胸炮起跳
    --self:EnterSkillCd(805227)--升龙腿
    ----self:ForceCastSkillToTargetByWeights()
    ----self:ForceCastSkillToTargetByWeights(skillGroup)
    ----
end

--空中：攻击衔接
function XChar8052:AirAttackConnect()
    if self.airAttackRemainCount <= 0 then
        XLog.Warning("没有攻击次数了要落地了")
    else
        XLog.Warning("还有攻击次数，继续攻击")
    end
end

---OD连续推进拳
function XChar8052:ODPushFistConnect()
    if self.pushFistODCount >= 3 then --次数限制
        self:ForceSkillToPosition(805232,self.levelCenterPoint) --中心点放瑟提锤
        self:SetSkillCdDone(805208) --推进拳
        self.pushFistODCount = 1
        return
    end
    self:ForceSkillToTarget(805248,self:GetRandomPlayerInRange(0,999))--随机选择一个玩家冲刺
    self.pushFistODCount = self.pushFistODCount+1
end

---检查和处理是否能衔接技能
function XChar8052:HandleConnectCount()
    if not self.isSkillConnectLocked then
        return false
    end
    
    if self.curConnectCount<self.maxConnectCount then--小于最大值
        self.curConnectCount = self.curConnectCount + 1
        return true
    end

    self.curConnectCount = 1 --不足以衔接，重置成1
    return false
    
end

---下段斩衔接
function XChar8052:DownChopConnect() --下段斩衔接
    if self:TryDoDodge() then
        return
    end
end

--光刃二连衔接
function XChar8052:SwordHit2Connect()
    self:EnterSkillCd(805224)--二连进入CD
    self:EnterSkillCd(805222)--三连也进入CD
    if self:TryDoDodge() then
        return
    end
end

---上勾拳衔接
function XChar8052:ShangGouQuanConnect() --上勾拳衔接
    if self:TryDoDodge() then
        return
    end
end

---交叉射击衔接
function XChar8052:CrossFireConnect() --交叉射击衔接
    if self:TryDoDodge() then
        return
    end
end

---后退斩衔接
function XChar8052:BackChopConnect()--后退斩衔接
    if self:TryDoDodge() then
        return
    end
end

---空落锤衔接
function XChar8052:AirHitLandConnect()
    if self:TryDoDodge() then
        return
    end
    local castGroup ={
        [805209] =10, --下段斩
    }
end

---瑟提锤衔接
function XChar8052:HitLandConnect()
    if self:TryDoDodge() then
        return
    end
end

---反身拳衔接
function XChar8052:FanShenQuanConnect()
    if self:TryDoDodge() then
        return
    end
end

---二连拳衔接衔接
function XChar8052:DoubleFistConnect()
    if self:TryDoDodge() then
        return
    end
    local target = self._proxy:GetFightTargetId(self._uuid)
    local SkillGroup={
        [805203]=10,--上勾拳
        [805207]=10,--交叉射击
        --缺一个连续推进
    }
    --if self:TryCastSkillToTargetByWeights(SkillGroup) then
    --    XLog.Warning("二连拳技能衔接成功")
    --end
end

---地面激光衔接
function XChar8052:GroundLaserConnect()
    if self:TryDoDodge() then
        return
    end
end

---空中：胸炮起跳衔接
function XChar8052:AirLaserConnect()
    local skills ={
        [805228] = 10,--空落锤
    }
    self:ForceCastSkillToTargetByWeights(skills)
end

---空中：闪避1衔接
function XChar8052:AirDodge1Connect()--空中闪避1衔接
    local skills={}
    if self.isAirHaveDodge then--空中如果已经闪避过了
        skills ={
            [805219] = 20,--空中左推2
            [805220] = 20,--空中右推2
            [805206] = 10,--流星冲锋坠，直接下去
            [805279] = 10,--OD流星冲锋坠
        }
        self.isAirHaveDodge = false
    else--没闪避就闪一次
        skills ={
            [805217] = 10,--空中左推1
            [805218] = 10,--空中右推1
        }
        self.isAirHaveDodge = true
    end
    self:ForceCastSkillToTargetByWeights(skills)
end

---空中：闪避2衔接
function XChar8052:AirDodge2Connect()--空中闪避2衔接
    local skills ={
        [805206] = 10,--流星冲锋坠
        [805279] = 10,--OD流星冲锋坠
        [805228] = 10,--空落锤
    }
    self:ForceCastSkillToTargetByWeights(skills)
end

---空中喷气衔接落地
function XChar8052:AirPushConnectDown()--空中喷气衔接流星坠
    local skillId = 805206
    if self:CheckCurIsOverDrive() then
        skillId = 805279 --OD版流星冲锋坠
    end
    
    self:ForceSkillToTarget(skillId)
end

---移动射击后衔接
function XChar8052:AfterMoveFireConnect()
    if self:TryDoDodge() then
        return
    end
end

---推进拳衔接
function XChar8052:PushFistConnect()
    --if self:TryDoDodge() then
    --    return
    --end

    local skillList ={
        [805277] = 10, --OD光刃二连
        [805278] = 10, --OD光刃三连
        [805248] = 10,  --OD连续推进拳
        [805249] = 10,  --OD瑟提锤
        [805227] = 10, --升龙腿
        [805224] = 10,  --光刃二连
        [805216] = 10,  --地面蓄力炮（10）
        [805229] = 10,  --重火锤
        [805230] = 10,  --后退斩
        [805209] = 10 , --下段斩
        [805232] = 50,  --瑟提锤
        [805208] = 10,  --中远距离：推进拳（15）
        [805204]=  10,  --欧拉拳（35）
        [805207] = 10,  --交叉射击：近距离后退拉开距离（）
        --[805221] = 10,  --超远距离：移动射击（0）远程
        [805203]=  10,   --上勾拳（0）
        [805234]=  10,   --二连拳（0）
        [805202]=  10,   --反身拳（0）
    }
    local skill
    skill = self:GetAbleSkillByWeightsToNpc(skillList,self:GetTarget())
    if skill then
        if self:ForceSkillToNpc(skill,self:GetTarget()) then --如果对目标释放技能成功就直接返回
            return
        end
    else
        local dis = self._proxy:GetNpcDistance(self._uuid,self:GetTarget(),true)
        if dis >12 then
            self:ForceSkillToNpc(805232,self:GetTarget())
            --XLog.Warning("太远了")
        elseif dis > 5 then
            self:ForceSkillToNpc(805210,self:GetTarget())
            --XLog.Warning("推一下")
        elseif dis < 2.5 then
            self:ForceSkillToNpc(805211,self:GetTarget()) --2m内往后推
        end
    end
    
end

---欧拉拳衔接
function XChar8052:OuLaConnect()
    if self:TryDoDodge() then
        return
    end
    --XLog.Warning("推进拳衔接")
    --local skills={
    --    
    --}
    --self:TryCastSkillToTargetByWeights(skills)
end

---Parry格挡衔接
function XChar8052:ParryConnect()
    self:ForceSkillToTarget(805205)--释放格挡反击
end

---强制喷气调整位置
function XChar8052:ForceFixPosition()
    
end

--不死斩启动
function XChar8052:MortalBladeStart()
    if self.isOnSoftFury then--根据是否软狂暴释放不同的不死斩
        self:ForceSkill(805281) --软狂暴不死斩
    else
        self:ForceSkill(805276) --原版不死斩
    end
end

--不死斩1衔接
function XChar8052:MortalBladeConnect()
    self:ForceSkillToTarget(805277)
end

--endregion

return XChar8052