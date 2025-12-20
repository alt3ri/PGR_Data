local Base = require("Character/FightCharBase/XRelinkMonsterBase")
local SkillConfig = require("TempSkillConfigs/SkillConfig_8052")
local EGameplayTag = require("Enum/XGameplayTag")
local GameplayTag = require("Tools/GameplayTag/GameplayTag")

---小辉辉BOSS脚本
---@class XChar8052 : XRelinkMonsterBase
local XChar8052 = XDlcScriptManager.RegCharScript(8052, "XChar8052", Base)
--region 枚举
XChar8052.DashMode = { --冲刺技能的流程
    None = 0,
    Start =1,--开始阶段，进行蓄力
    Loop = 2,--冲刺阶段
    End = 3,--结束，释放收招技能。
}

XChar8052.DashType = { --冲刺类型
    None =0, --不选择冲刺
    Mid = 1 , --在中心
    Side = 2 , --在边缘
    Player =3,--向玩家冲刺
    Random =4,--随机选点
}

--endregion

--region 怪物配置

---配置主入口
function XChar8052:MonsterConfigMain() --怪物配置用
    Base.MonsterConfigMain(self)
    --self._proxy:ApplyMagic(self._uuid,self._uuid,1010007)
    ------怪物自己机制的初始化------
    self:DashInit() --连续冲刺机制技能初始化
    self:AirFireInit() --激光攻击技能初始化
    self:SkillConnectInit() --自己的技能衔接初始化
    
    self:InitNpcTimer(1,25,15) --闪避CD
    self:InitNpcTimer(2,45,45) --连续闪避CD（闪避时连续闪避
    self:InitNpcTimer(4,20,20) --回中CD（多久尝试回一次中）
    
    --self:SetCombatModeAiActive(false) --关闭主AI
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
        {--OD机制启动技能最优先判断
            --[805257] = 10,  --浮空机制启动
            [805258] = 10,  --Dash机制启动
        },
        {--二阶段：优先判断技能（升空），升空应该要有一样的CD
            [805223] = 10,  --光刃上天
            [805226] = 10,  --激光起跳版
        },
        {--二阶段：普通技能（光刃和火力攻击）
            [805216] = 10,  --地面蓄力炮（10）
            [805229] = 10,  --重火锤
            [805227] = 10,  --升龙腿（30）
            [805230] = 10,  --后退斩
            [805207] = 10,  --交叉射击：近距离后退拉开距离（）
            [805230] = 10 , --后退斩
            [805224] = 10 , --光刃二连
        },
        {--一阶段OD机制技能
            [805248] = 10,  --OD连续冲拳
            [805249] = 10,  --瑟提锤
        },
        {--一阶段：优先
            [805208] = 10,  --中远距离：推进拳（15）
            [805204]=  10,  --欧拉拳（35）
        },
        { --1阶段：中距离释放
            [805232] = 10,  --瑟提锤
            [805208] = 10,  --推进拳15s
        },
        { --1阶段：超远距离
            [805221] = 10,  --超远距离：移动射击（0）远程
        },
        {--近战保底，全部没有CD
            [805203]=10,   --上勾拳（0）
            [805234]=10,   --二连拳（0）
            [805202]=10,   --反身拳（0）
        },
    }
end

---技能测试配置
function XChar8052:SkillTestConfig()
    --self:SetSkillTestActive(true) --技能测试开关
    self.skillTestId = 805267
    self.skillTestInitialCd = 8--测试初始CD
    self.skillTestCd = 20
end

---技能测试配置
function XChar8052:SkillConfig()
    self:InitSkillCd(805201,35,35) --格挡
    self:InitSkillCd(805202,0,0) --反身拳
    self:InitSkillCd(805203,0,6) --上勾拳
    self:InitSkillCd(805204,45,35) --欧拉拳
    self:InitSkillCd(805205,0,0) --格挡反击
    self:InitSkillCd(805206,0,0) --流星冲锋坠
    self:InitSkillCd(805207,20,10) --交叉射击
    self:InitSkillCd(805208,8,15) --推进拳
    self:InitSkillCd(805209,0,5) --下段斩
    self:InitSkillCd(805216,0,10)--地面蓄力炮
    self:InitSkillCd(805221,6,0) --移动射击向前
    self:InitSkillCd(805222,0,15) --光刃三连
    self:InitSkillCd(805223,0,35) --光刃上天
    self:InitSkillCd(805224,0,30) --光刃二连
    self:InitSkillCd(805225,0,0) --胸炮浮空版
    self:InitSkillCd(805226,0,35) --胸炮地面起跳版
    self:InitSkillCd(805227,45,35) --升龙腿
    self:InitSkillCd(805228,0,10) --空落锤
    self:InitSkillCd(805229,0,10) --重火锤
    self:InitSkillCd(805230,0,5) --后退斩
    self:InitSkillCd(805231,0,0) --响指波
    self:InitSkillCd(805232,10,15) --瑟提锤
    self:InitSkillCd(805234,0,6) --二连拳
    self:InitSkillCd(805248,0,45) --OD推进拳连续
    self:InitSkillCd(805249,0,40) --OD瑟提锤
    self:InitSkillCd(805249,0,40) --OD角力启动
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
end

---阶段配置
function XChar8052:PhaseConfig()
    self:SetSwitchPhaseType(Base.SwitchPhaseType.ExitBreak)--退出Break的时候切阶段
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
    self:HandleActionKeyFrameEventLatest()
    self:AirFirePlayerShieldTickCheck() --浮空机制玩家护盾检查
    self:DashTickCheck()--Dash机制Tick检查
    self:MoveFireTickCheck() --移动射击检查
    self:GoCenterCheck() --回中检查
    --XLog.Warning("和目标的距离："..self.targetDistance)
end

---怪物进入OD后要做的事情
function XChar8052:MonsterEnterOverDriveAfter()
    self:InitSkillCd(805258,15,50) --初始化设置冲刺机制启动技能
end

--endregion

--region Dash机制技能

---小辉辉冲刺技能初始化
function XChar8052:DashInit()

    -----Dash机制默认关闭碰撞-----
    self._proxy:SetObstacleActive(10,false) --设置Dash障碍默认关闭
    self._proxy:SetObstacleActive(11,false)
    self._proxy:SetObstacleActive(12,false)
    self._proxy:SetObstacleActive(13,false)

    -----Dash机制的几个点位保存-----
    self.dashPlayerPointList ={}
    self.dashMonsterPoint = self._proxy:GetSpot(6) --Dash机制BOSS位置
    table.insert(self.dashPlayerPointList,self._proxy:GetSpot(7))--Dash机制玩家1位置
    table.insert(self.dashPlayerPointList,self._proxy:GetSpot(8))--Dash机制玩家2位置
    table.insert(self.dashPlayerPointList,self._proxy:GetSpot(9))--Dash机制玩家3位置
    self.dashArriveCheckRange = 0
    self.curDashRound = 0 --当前冲刺轮次
    self.dashMode = XChar8052.DashMode.None --默认冲刺没有东西
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
    self.dashOrthoCenterVerticalPointOffset =20
    self.dashOrthoCenterHorizontalPointOffset=20
    self.dashVerticalOffset =20
    self.dashHorizontalOffset = 20
    self:RefreshDashMapPointList() --根据配置的范围刷新冲刺列表
    ----冲刺范围配置----
    
    self.dashRound1TypeMap = { --第一轮冲刺类型
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
        [11] = XChar8052.DashType.Side,
    }

    self.dashRound2TypeMap = { --第二轮冲刺类型
        [1] = XChar8052.DashType.Random,
        [2] = XChar8052.DashType.Side,
        [3] = XChar8052.DashType.Player,
        [4] = XChar8052.DashType.Side,
        [5] = XChar8052.DashType.Mid,
        [6] = XChar8052.DashType.Player,
        [7] = XChar8052.DashType.Side,
        [8] = XChar8052.DashType.Mid,
        [9] = XChar8052.DashType.Player,
        [10] = XChar8052.DashType.Player,
        [11] = XChar8052.DashType.Player,
    }

    self.dashShunPointList = { --标记起点和终点
        
    }
    
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
    --创建屏障子弹
    self:ClearDashTips() --先清空
    if self.curDashRound == 2 then  --第二轮创建边长40的
        self.dashPingZhangBulletUUID = self._proxy:LaunchMissileFromPosToPos(self._uuid,80520170,80525002,self.dashCenter,self.dashCenter)
    else --第一轮创建边长30的
        self.dashPingZhangBulletUUID = self._proxy:LaunchMissileFromPosToPos(self._uuid,80520170,80525001,self.dashCenter,self.dashCenter)
    end
    
    local LeftUp = self.dashMapPointList.uL
    local LeftDown = self.dashMapPointList.dL
    local RightDown = self.dashMapPointList.dR
    local RightUp = self.dashMapPointList.uR

    local line1 =self._proxy:AddPosLink(LeftUp,LeftDown,self.dashLinkEffect,self._uuid,true)--创建连线)
    local line2 =self._proxy:AddPosLink(LeftDown,RightDown,self.dashLinkEffect,self._uuid,true) --创建连线)
    local line3 self._proxy:AddPosLink(RightDown,RightUp,self.dashLinkEffect,self._uuid,true)--创建连线)
    local line4 self._proxy:AddPosLink(RightUp,LeftUp,self.dashLinkEffect,self._uuid,true) --创建连线)

    table.insert(self.dashTipsList,line1)
    table.insert(self.dashTipsList,line2)
    table.insert(self.dashTipsList,line3)
    table.insert(self.dashTipsList,line4)
    
end

---ClearDashTips
function XChar8052:ClearDashTips()
    if #self.dashTipsList == 0 then --没有东西就不管了
        return
    end
    for i, linkUUID in pairs(self.dashTipsList) do
        self._proxy:RemoveLink(self._uuid,linkUUID)
    end
    self._proxy:DestroyAllMissileDependOnLauncher(self._uuid)
    self.dashTipsList={}
end

---小辉辉Dash机制开始布置场地
function XChar8052:DashStartSetLevel()
    
    
    for i,playerUUID in pairs(self._proxy:GetPlayerNpcList()) do --获取和设置玩家位置
        self._proxy:SetNpcPosition(playerUUID,self.dashPlayerPointList[i])
        self._proxy:SetNpcRotation(playerUUID,{x=0,y=0,z=0})
        self._proxy:ResetCamera(0,0,true)
        self._proxy:ApplyMagic(self._uuid,playerUUID,8052097) --设置冲刺机制相机偏移
    end

    self.curDashRound = 1 --要从第一轮开始
    
    ----Dash初次冲刺范围----
    self.dashOrthoCenterVerticalPointOffset = 14
    self.dashOrthoCenterHorizontalPointOffset= 14
    self.dashVerticalOffset = 14
    self.dashHorizontalOffset = 14
    self:RefreshDashMapPointList() --根据配置的范围刷新冲刺列表
    self.dashArriveCheckRange = 3 --首次冲刺的判断范围
    -------创建场景屏障特效
    self:CreatDashTips()
    
end

---小辉辉Dash机制开始Go了
function XChar8052:DashStartGo()
    self:ForceSkillToNpc(805239,self:GetRandomPlayerInRange(0,999))
    self:ApplyMagicOtherAllNpc(8052086) --取消禁止控制相机
    --随机释放冲刺的爆炸技能
end

---小辉辉Dash机制ReadyToStart
function XChar8052:DashReadyStart()
    self._proxy:SetNpcPosition(self._uuid,self.dashMonsterPoint) --传送怪物位置
    self._proxy:SetNpcRotation(self._uuid,{x=0,y=180,z=0})
    self:ApplyMagicOtherAllNpc(8052085) --禁止控制相机
    self:ForceSkill(805250) --强制释放这个技能
    --随机释放冲刺的爆炸技能
end

---小辉辉处理边界
function XChar8052:DashHandleBoundary()
    if self.curDashRound == 2 then
        ----第二次范围边长40----
        self.dashOrthoCenterVerticalPointOffset = 20
        self.dashOrthoCenterHorizontalPointOffset= 20
        self.dashVerticalOffset = 20
        self.dashHorizontalOffset = 20
        self.dashArriveCheckRange = 5 --第二次速度比较快，到达的范围检测更大
        self:RefreshDashMapPointList() --根据配置的范围刷新冲刺列表
        -------创建场景屏障特效
        self:CreatDashTips()
    end
    if self.curDashRound >= 3 then
        self:ClearDashTips() --清除冲刺提示
        for i,playerUUID in pairs(self._proxy:GetPlayerNpcList()) do --获取和设置玩家位置
            self._proxy:ApplyMagic(self._uuid,playerUUID,8052098) --移除设置相机偏移
        end
    end
    
end

---刷新清空冲刺数据
function XChar8052:DashRefresh()
    self.dashList = {} --清空冲刺列表
    self.dashTestNpcList = {}--清空测试Npc列表
    self.dashLinkIdList={} --清空LinkID列表
end

---冲刺技能Update
function XChar8052:DashTickCheck()
    if self.dashMode == XChar8052.DashMode.Loop then
        self:OnDashLoop()--循环的时候判断到点或结束
    end
    
end

---进入DashStart
function XChar8052:EnterDashStart()
    if self.curDashRound >=3 then --限制冲刺次数
        return
    end
    self:DashRefresh() --清空上一轮保存的点
    self.nextDashIndex = 1 --要冲向的点Index是1
    local startPos = nil --冲刺的开始点
    if self.curDashRound ==1 then
        XLog.Warning("第一次冲刺")
        startPos =self:TryGetDashStartPoint()--获得开始的第一个点
    elseif self.curDashRound ==2 then
        XLog.Warning("第二次冲刺")
        startPos = self:TryGetDashStartPoint()--获得开始的第一个点
    elseif self.curDashRound ==3 then
        startPos = self.dashMonsterPoint --朝着出生点
        XLog.Warning("第三次冲刺")
    end
    table.insert(self.dashList,startPos)--插入开始的第一个点。
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052089) --不能被索敌
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052075) --不能被碰撞
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052091) --无敌
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052093) --无视场景障碍
    self:ForceSkillToPosition(805240,startPos)--向开始的点释放Start技能
    self._proxy:LookAtPositionImmediately(self._uuid,self.dashList[self.nextDashIndex])--看向要冲刺的第一个点
    self.dashSelectCount =2 --冲刺选点之后要选第二个点了
    self:CreatStartDashPosLink() --创建开始时的冲刺线
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
    if self.curDashRound == 3 then --一瞬千击
        --XLog.Warning("第三轮冲刺")
        dashSkill = 805243
    end
    
    local targetPoint = self.dashList[self.nextDashIndex]
    self:ForceSkillToPosition(dashSkill,targetPoint)--向目标点放冲刺技能
    self._proxy:LookAtPositionImmediately(self._uuid,targetPoint)--看向目标点
    self.dashMode= XChar8052.DashMode.Loop --进入Loop判断
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
    --XLog.Warning("创建链接成功:"..linkID)
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
end

---移除冲刺时的线
function XChar8052:RemoveDashPosLink()
    self._proxy:RemoveLink(self._uuid,self.dashLinkIdList[self.nextDashIndex])--到达第几个点就删除几个点
end

---当DashLoop的时候
function XChar8052:OnDashLoop()
    local nextPointDistance = self._proxy:GetNpcToPositionDistance(self._uuid,self.dashList[self.nextDashIndex])--获取和下一个点的距离
    --XLog.Warning(nextPointDistance)--和下一个点的距离
    --判断到达目标点的条件
    if nextPointDistance <= self.dashArriveCheckRange then --小于这个距离就等于到达了目的地
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
    self:RemoveDashPosLink() --删除冲刺连接线
    
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
    
    if self.nextDashIndex==#self.dashList then --没有可冲的点，当前要结束了。
        self:OnCurDashRoundEnd()
        return
    end
    
    self.nextDashIndex = self.nextDashIndex+1 --自增1
    --如果还有冲刺的点就看向下一个点继续冲刺。
    local nextPos = self.dashList[self.nextDashIndex]
    
    self:ForceSkillToPosition(805251,nextPos)--转向下一个点
    --self._proxy:LookAtPositionImmediately(self._uuid,nextPos)--看向下一个点
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
    self:GetDashPoint(1)
end

---获取多少次选点
function XChar8052:GetDashPoint(count)
    for i =1,count do --额外选择次数
        local type =self.dashRound1TypeMap[self.dashSelectCount] --默认走第一轮的冲刺方式
        if self.curDashRound == 2 then --如果是第二轮就按照第二轮的冲刺方式
            type =self.dashRound2TypeMap[self.dashSelectCount]
        end
        local lastPos = self.dashList[#self.dashList] --最后位置的点
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
    self.curDashRound = self.curDashRound + 1 --回合数+1
    self:CleanDashLink() --保底清除所有冲刺线
    self.dashMode=XChar8052.DashMode.None --状态设置成无,结束冲刺.
    self.dashSelectCount = 2 --重置一下Count
    --self._proxy:DestroyAllMissileDependOnLauncher(self._uuid)--移除自己生成的所有子弹,主要是子弹缺了随Action结束移除的功能 TODO:子弹需要新增一个随Action打断移除(任何情况打断都应该移除)
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052090) --移除不能被索敌
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052076) --移除不能被碰撞
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052092) --移除无敌
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052094) --移除无视场景障碍
    self:SetPlayerHardLockSelf() --设置玩家强锁自己    
    self:ForceSkillToPosition(805239,self.dashCenter) --向Dash的中心点放瑟提锤用来结束流程。
    --self:ForceSkillToPosition(805259,self.dashCenter) --原地结束停下来
    --if not  then
    --    self:ForceSkillToPosition(805239,self.dashCenter) --原地结束停下来
    --end
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
end

---受到伤害后事件
function XChar8052:OnNpcDamageEvent(launcherId, targetId, magicId, kind, physicalDamage, elementDamage, elementType, realDamage, isCritical, skillId, magicTags)
    if targetId ~= self._uuid then
        return
    end
    --自己受到伤害时
    if self:CheckParryNpc(launcherId) then
        self:ParryToNpc(launcherId)
    end
end
---拼刀触发前
function XChar8052:OnNpcBeforeTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag, triggerMissileTemplateId, triggerMissileUUID, contextId)
    if triggerNpcUUID ~= self._uuid then
        return
    end
    
    --是否多人拼刀，自己是多人弹刀盒，对方是重
    local isMulti = GameplayTag.CSMatchAnyTag(triggerTag,{EGameplayTag.Missile_Parry_Trigger_MultiInteract}) and GameplayTag.CSMatchAnyTag(counterTag,{EGameplayTag.Missile_Parry_Counter_Heavy})
    
    --self._proxy:CastMultiParry(self._uuid,counterNpcUUID,805201) --开启多人弹刀
    self._proxy:CastWrestle(self._uuid,counterNpcUUID,805201) --进入角力
    
    --self._proxy:CheckBuffByKind(counterNpcUUID,1000487)--是否坦克
    --self._proxy:CheckBuffByKind(counterNpcUUID,1000486)--是否输出
    --self._proxy:CheckBuffByKind(counterNpcUUID,1000488)--是否奶
    --self:BeParryByNpc(counterNpcUUID)
end

---拼刀触发后
function XChar8052:OnNpcAfterTriggerCounter(triggerNpcUUID, counterNpcUUID, triggerTag, counterTag)
    if triggerNpcUUID ~= self._uuid then
        return
    end

end
--endregion

--region OD机制

---OD后优先尝试放一次特殊机制，自定义的特殊机制位置。
function XChar8052:OnCustomCastOverDriveSpecialSkill()
    local curPhase = self:GetCurPhase() --获取当前阶段
    if curPhase == 3 then 
        XLog.Warning("切到阶段3时有特殊的特殊技能，暂时留空")
        return
    end
    self:ForceSkillToPosition(805239,self.dashCenter)--其他阶段默认都向场景中心点释放进入冲刺技能流程的技能。
end

--endregion

--region 小辉辉战斗逻辑

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
        self:EnterNpcTimer(2)
    end
end

---移动射击时每帧检测
function XChar8052:MoveFireTickCheck()
    if not self._proxy:CheckNpcCurrentAction(self._uuid,805221)then --是否在移动射击
        return
    end
    
    local success , time =self._proxy:TryGetNpcCurrentActionElapsedTime(self._uuid)
    
    if not success then
        return
    end

    if not  (time >= 1.4 and time <=2.6) then
        return
    end
    
    ---移动射击且可以衔接的时候
    if self:CheckTargetDistance(8) then --8m以内有威胁，停止
        self._proxy:AbortAction(self._uuid,true) --打断当前技能
        self:TryCastSkillToTargetByWeights(self:GetCastGroup())
    end
end

--endregion

--region 武器控制
--endregion

--region 闪避
---闪避
function XChar8052:DoDodge()
    self:ForceSkillToTarget(805211)--后推
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
    
    if not self:CheckSkillCdDone(805201) then --检查格挡技能CD
        return false
    end
    if not self._proxy:CheckNpcInAngle(self._uuid,npc,angle) then--在自己角度范围内
        return false
    end
    if not  self._proxy:CheckBuffByKind(self._uuid,buffKind) then--身上没有可以格挡的标记
        return false
    end
    return true
end

---被Npc触发格挡（npc）
function XChar8052:ParryToNpc(triggerNpc)
    self._proxy:SetNpcFaceToPosition(self._uuid, self._proxy:GetNpcPosition(triggerNpc))--看向触发格挡的Npc
    self:SetTarget(triggerNpc)--设置为战斗目标
    self._proxy:SetNpcFaceToPosition(self._uuid, self._proxy:GetNpcPosition(triggerNpc))--看向触发弹刀的Npc
    self:ForceSkillToNpc(805201,triggerNpc)--对触发弹反的Npc释放拼刀技能
    ---表现调整后面补
    self._proxy:LaunchMissile(triggerNpc,self._uuid,80520521,1)--目标对自己发特效
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052029,1)--对辉辉顿帧
    self._proxy:ApplyMagic(self._uuid,triggerNpc,8052030,1)--对目标顿帧
    self._proxy:ApplyMagic(triggerNpc,triggerNpc,8052031,1)--调整镜头广角
    XLog.Warning("向")
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
    local buffId = 8052033 --检查的BuffID
    local maxCount = 2 --拼刀最大次数
    local buffCount = 0 --当前拼刀次数
    local phase1Skill = 805233 --小击飞
    local phase2Skill = 805214 --再来一次
    local phase3Skill = 805233 --大击飞
    self:SetTarget(triggerNpc)--设置为战斗目标
    
    if self:GetCurPhase()<=1 then --一阶段被防御直接小击飞
        self:HandleBeParry(phase1Skill,triggerNpc)--一阶段小击飞
        return
    end
    ----二阶段及以上
    self._proxy:ApplyMagic(self._uuid,self._uuid,buffId,1)--拼刀层数增加一层
    buffCount = self._proxy:GetBuffStacks(self._uuid,buffId) --获取当前拼刀次数

    if buffCount > maxCount then
        self:HandleBeParry(phase3Skill,triggerNpc)--二阶段大击飞结束
        return
    end

    self:HandleBeParry(phase2Skill,triggerNpc)--再来一次
    
end

---处理被拼刀（skill,npc）
function XChar8052:HandleBeParry(skill,npc)
    self._proxy:SetNpcFaceToPosition(self._uuid, self._proxy:GetNpcPosition(npc))--看向触发弹刀的Npc
    --self._proxy:LaunchMissile(npc,self._uuid,80520521,1)--目标对自己发特效
    self:ForceSkillToNpc(skill,npc)--对触发弹反的Npc释放拼刀技能
    self._proxy:ApplyMagic(self._uuid,self._uuid,8052029,1)--对自己顿帧
    --self._proxy:ApplyMagic(self._uuid,npc,8052030,1)--对目标顿帧
    self._proxy:ApplyMagic(npc,npc,8052031,1)--调整镜头广角
end

--endregion

--region 连招控制

---OD连续推进拳
function XChar8052:ODPushFistConnect()
    local count = self._proxy:GetBuffStacks(self._uuid,8052083)
    if count >=3 then--已经冲了三次
        self:ForceSkillToPosition(805232,self.levelCenterPoint) --中心点放瑟提锤
        self:SetSkillCdDone(805208) --推进拳
        return
    end
    self:ForceSkillToTarget(805248,self:GetRandomPlayerInRange(0,999))--随机选择一个玩家冲刺
end

---衔接初始化
function XChar8052:SkillConnectInit() --技能衔接初始化
    self.isSkillConnectLocked = true --设置小辉辉的连招锁
    self.maxConnectCount = 2-- 连招上限
    self.curConnectCount = 1 --当前连招段数
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

end
---光刃上天衔接
function XChar8052:SwordGoAirConnect()
    
end
--光刃二连衔接
function XChar8052:SwordHit2Connect()

end

---上勾拳衔接
function XChar8052:ShangGouQuanConnect() --上勾拳衔接
    
end

---交叉射击衔接
function XChar8052:CrossFireConnect() --交叉射击衔接

end

---后退斩衔接
function XChar8052:BackChopConnect()--后退斩衔接
    
end

---空落锤衔接
function XChar8052:AirHitLandConnect()
    local castGroup ={
        [805209] =10, --下段斩
    }
end

---瑟提锤衔接
function XChar8052:HitLandConnect()

end

---反身拳衔接
function XChar8052:FanShenQuanConnect()
    if self:CheckNpcTimer(2) then --可以闪避
        self:DoDodge()--闪避
        self:EnterNpcTimer(2) --闪避进入CD
    end
end

---二连拳衔接衔接
function XChar8052:DoubleFistConnect() 
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
    
end

---空中激光衔接
function XChar8052:AirLaserConnect()
    
end

---空中衔接
function XChar8052:AirPushConnect()--空中喷气衔接
    local skillId1 = 805217 --左推轻
    local skillId2 = 805218 --右推轻
    if self._proxy:Random(0,100) >=50 then --50概率放左推
        self:ForceSkillToTarget(skillId1)
        return
    end
    self:ForceSkillToTarget(skillId2)
end

---空中喷气衔接落地
function XChar8052:AirPushConnectDown()--空中喷气衔接流星坠
    local skillId = 805206
    self:ForceSkillToTarget(skillId)
end

---跳跃激光衔接/胸炮地面版衔接
function XChar8052:JumpLaserConnect()
    local skills = {--要判断的技能释放列表
        [805228]=1,
    }
    --如果有CD或不满足条件的技能就没办法放，会在满足释放条件的技能里选择。
    --self:ForceCastSkillToTargetByWeights(skills) --根据权重组释放技能
    self:ForceSkillToTarget(805219) 
    XLog.Warning("What")
    return
    --self:TryCastSkillToTargetByWeights(skills) --根据权重组判断条件地去筛技能
    --self:ForceSkillToTarget(805228) --强制释放空落锤
end

---移动射击后衔接
function XChar8052:AfterMoveFireConnect()
    
    --if self._proxy:GetBuffStacks(self._uuid,8052080)<2 then
    --    return
    --end
    --
    --local SkillGroup={}
    ----八方向障碍检查
    --if self:CheckDisByTarget(5) then--近距离
    --    if self.curPhase == 1 then--近距离一阶段
    --        SkillGroup = {
    --            [805207] = 10,--交叉射击,用来后退
    --            [805203] = 10,--上勾拳
    --            [805234] = 10,--二连拳
    --        }
    --    end
    --    if self.curPhase == 2 then--近距离二阶段
    --        SkillGroup = {
    --            [805230] = 10,--后退斩,用来后退
    --            [805216] = 10,--地面蓄力炮
    --        }
    --    end
    --    return self:TryCastSkillToTargetByWeights(SkillGroup)
    --end
    --
    --if self:CheckDisByTarget(10) then--中距离
    --    if self.curPhase == 1 then--中距离一阶段
    --        SkillGroup = {
    --            [805208] = 10,--推进拳
    --        }
    --    end
    --    if self.curPhase == 2 then--中距离二阶段
    --        SkillGroup = {
    --            [805227] = 10,--升龙腿
    --            [805224] = 10,--光刃二连
    --            [805209] = 10,--下段斩
    --        }
    --    end
    --    return self:TryCastSkillToTargetByWeights(SkillGroup)
    --end
    --self:ForceSkillToTarget(805221)--远距离继续放移动射击
end

---推进拳衔接
function XChar8052:PushFistConnect()
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

--endregion

return XChar8052