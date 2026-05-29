local XFunctionTime = require("XEntity/XFunctional/XFunctionTime")
local tableInsert = table.insert

local ShieldFuncDic = {}    -- 功能过滤
local ShieldUiNameDic = {}    -- 功能对应的界面过滤
local FunctionTimeData = {} --功能开启时间
local FunctionOpenTimeDict = nil --带有TimeId的Function

local ResultIdPool = 1 -- 跳转结果的等待Id
local ResultWaitingDict = {} -- 等待异步跳转结果的缓存字典
---@type XPool
local AsyncSkipDataPool = XPool.New(function()  -- 异步跳转信息对象池
    return {}
end, function(data)
    data.SkipId = nil
    data.FromMsg = nil
end)

XFunctionManager = XFunctionManager or {}

XFunctionManager.SkipOrigin = {
    System = 1, -- 系统来源
    SonSystem = 2, -- 子系统来源
    Section = 3, -- 副本来源
    Main = 4, -- 主界面
    Webpage = 5, -- 网页
    SystemWithArgs = 6, -- 跳转特定标签页的系统
    Custom = 7, -- 跳转自定义系统（大部分副本）
    Dormitory = 8, -- 跳转宿舍
    ActivityUrl = 9, --活动链接
    MVCAModule = 10, -- 跳转模块为MVCA
}

--这个枚举由服务端制定
XFunctionManager.FunctionName = {
    Target = 1, --目标
    SkipObligate = 2, --预留
    Deposit = 3, --充值
    Setting = 4, --设置
    SignIn = 5, --签到
    Feedback = 6, --反馈
    Welfare = 7, --福利
    ExchangeCode = 8, --兑换码
    ICPFiling = 9, --备案号
    MainRightTopActivity = 10, --主界面右侧活动按钮
    MainLeftTopActivity = 11, --主界面左侧活动按钮
    AutoWindow = 12, --打脸图
    CharacterVoice = 13, --CV入口检测参数
    UiMainMusicAlbum = 14, --主界面CD机

    Character = 101, --构造体
    CharacterGrade = 102, --构造体晋升
    CharacterQuality = 103, --构造体进化
    CharacterSkill = 104, --构造体技能
    CharacterEnhanceSkill = 107, --构造体补强技能
    SpCharacterEnhanceSkill = 108, --SP角色补强技能
    CharacterExhibition = 105, --构造体展示厅
    Isomer = 106, --感染体

    Equip = 201, --装备
    EquipStrengthen = 202, --装备强化
    EquipResonance = 203, --装备共鸣
    EquipStrengthenAutoSelect = 204, --装备一键强化
    EquipAwake = 205, --装备觉醒
    EquipQuick = 206, --一键培养
    EquipGuideRecommend = 207, --装备目标-推荐
    EquipGuideSetTarget = 208, --装备目标-设定
    EquipOverrun = 209, --装备超限

    Bag = 301, --背包
    DrawCard = 401, --研发
    DrawCardEquip = 402, --研发装备
    ActivityDrawCard = 403, --活动研发
    Lotto = 10432,--皮肤抽卡

    Task = 501, --任务
    TaskDay = 503, --任务每日
    TaskActivity = 504, --任务活动
    TaskWeekly = 505, --任务每周
    Player = 601, --战队
    PlayerBrand = 602, --战队烙印
    PlayerAchievement = 603, --战斗成就
    ReviewActivity = 604,
    Mail = 701, --邮件
    SocialFriend = 801, --好友
    SocialChat = 802, --聊天
    SocialChatWorld = 803, --聊天 - 世界
    Domitory = 901, --基建（弃用）
    Dorm = 902, --宿舍
    DormQuest = 903, -- 宿舍委托
    ShopCommon = 1001, --普通商店
    ShopActive = 1002, --活动商店
    ShopPoints = 1003, --积分商店
    ShopRecharge = 1004, --累充商店
    Dispatch = 1201, --派遣
    BountyTask = 1301, --赏金
    MaintainerAction = 1302, --维持者行动（大富翁）
    MentorSystem = 1303, --师徒系统
    MainLineTRPG = 1304, --主线跑团玩法（终焉福音）
    NieR = 1305, --尼尔玩法
    Pokemon = 1306, --口袋战双
    ChessPursuitMain = 1307, -- 追击玩法
    SpringFestivalActivity = 1308, --春节集字活动
    WhiteValentineDay = 1309, -- 白色情人节约会活动
    MoeWar = 1310, -- 萌战
    FavorabilityMain = 1400, --好感度
    FavorabilityFile = 1401, --好感度-档案
    FavorabilityStory = 1402, --好感度-剧情
    FavorabilityGift = 1403, --好感度-礼物
    FavorabilityComeAcross = 1404, --好感度-偶遇

    CustomUi = 1501, --自定义控件

    FubenChallengeTrial = 1601, --试炼玩法
    Prequel = 1701, --间章
    Practice = 1800, --教学
    PartnerTeaching = 1801, -- 宠物教学(适配拟合)
    Course = 1802,  --考级系统
    PracticeDataExercise = 1803,  --赛利卡补习班数据演习

    Guild = 1901, --公会
    GuildBoss = 1904, --公会boss
    GuildBgm = 1905, --公会CD机
    OtherHelp = 2001, --助战
    Collection = 2100, --收藏品
    Medal = 2101, --勋章
    Nameplate = 2102, --铭牌
    Archive = 2200, --图鉴系统
    SubMenu = 2300, -- 主界面二级菜单
    Photograph = 2400, -- 拍照模式
    PurchaseAdd = 3000, --累计充值

    Partner = 5001, --伙伴系统

    ActivityCalendar = 6000, --活动日历

    InvitationCodeShare = 8001, -- 邀请码分享

    FubenDifficulty = 10102, --副本困难
    Bfrt = 10103, --据点战
    MainLine = 10104, --主线副本
    FubenChallenge = 10201, --挑战副本
    FubenChallengeTower = 10202, --挑战爬塔
    FubenChallengeBossSingle = 10203, --幻痛囚笼
    FubenArena = 10204, -- 竞技
    Stronghold = 10205, -- 矿区

    ActivityBrief = 10300, --活动简介
    FubenActivity = 10301, --活动副本
    FubenActivityOnlineBoss = 10302, --活动联机boss
    FubenActivityBranch = 10303, --活动支线
    FubenActivitySingleBoss = 10304, --活动单挑boss
    Experiment = 10305, --试玩区
    FestivalActivity = 10306, --节日活动(活动记录)
    BabelTower = 10307, --巴别塔计划
    FubenActivityMainLine = 10308, --活动主线
    RepeatChallenge = 10309, --复刷本
    RogueLike = 10310, --爬塔
    FubenAssign = 10311, --边界公约
    ArenaOnline = 10312, --区域联机玩法
    FubenUnionKill = 10313, --狙击战
    ExtralChapter = 10314, -- 外篇旧闻
    ShortStory = 10352, --浮点纪实
    FubenInfesotorExplore = 10315, --感染体玩法
    SpecialTrain = 10316, -- 特训关
    EliminateGame = 10317, -- 特训关小游戏
    Expedition = 10318, -- 虚像地平线
    ClickClearGame = 10319, -- 中元节点消小游戏
    WorldBoss = 10320, -- 世界boss
    RpgTower = 10321, -- 兵法蓝图
    HonorLevel = 10322, -- 荣耀勋阶
    FubenZhongYuanFestival = 10323, -- 中元节副本
    DragPuzzleGame = 10324, -- 拼图小游戏
    NewCharAct = 10325, -- 新角色教学
    ChristmasTreeGame = 10326, -- 圣诞树装扮小游戏
    CoupletGame = 10328, -- 对联小游戏
    FingerGuessing = 10329, --猜拳小游戏
    FubenSimulatedCombat = 10330, -- 模拟作战
    InvertCardGame = 10331, -- 翻牌小游戏
    PokerGuessing = 10333, --翻牌猜大小
    MovieAssemble = 10334, -- 剧情合集
    MineSweeping = 10335, -- 扫雷
    FubenHack = 10336, -- 骇入玩法
    Reform = 10337, -- 改造玩法
    ScratchTicket = 10338, -- 刮刮卡
    KillZone = 10339, --杀戮空间
    SuperTower = 10340, -- 超级爬塔
    FashionStory = 10341, -- 涂装剧情活动
    Passport = 10342,   --战斗通行证
    FubenCoupleCombat = 10343, -- 双人下场玩法
    RpgMakerActivity = 10345,   --21年端午活动
    LivWarmActivity = 10347,    --超丽芙预热活动
    LivWarmSoundActivity = 10348,    --超丽芙预热音频活动
    SoloReform = 10353, --mini改造
    AreaWar = 10349, --全服决战
    SuperSmashBros = 10350, --超限乱斗
    MemorySave = 10351, -- 周年意识营救
    FubenDaily = 10401, --日常副本
    FubenDailyYSHTX = 10402, --日常意识海特训
    FubenDailyEMEX = 10403, --日常EMEX行动
    FubenDailyResource = 10404, --日常资源副本
    FubenExplore = 10405, --黄金之涡
    FubenDailyGZTX = 10406, --日常構造體特訓
    FubenDailyXYZB = 10407, --日常稀有裝備
    FubenDailyTPCL = 10408, --日常突破材料
    FubenDailyZBJY = 10409, --日常裝備經驗
    FubenDailyLMDZ = 10410, --日常螺母大戰
    FubenDailyJNQH = 10411, --日常技能强化
    FubenDailyFZJQH = 10412, --日常辅助机强化
    FubenDailyShop = 10450, --日常补给商店
    SameColor = 10413,  -- 三消游戏
    RunGame = 10414,    --二周年预热-赛跑小游戏
    DiceGame = 10415, --元旦预热-投骰子小游戏
    Maverick = 10416, -- 射击玩法
    NewYearLuck = 10417, --元旦奖券小游戏
    HitMouse = 10418, --打地鼠小游戏
    BodyCombineGame = 10419, --哈卡玛小游戏
    Theatre = 10420,    --肉鸽1期
    Doomsday = 10421, --末日生存（模拟经营）
    PivotCombat = 10422, --SP枢纽作战
    Escape = 10423, --大逃杀活动
    DoubleTowers = 10424, --动作塔防
    GoldenMiner = 10426, --黄金矿工活动
    WeekChallenge = 10428, --周挑战
    MultiDim = 10427, -- 多维挑战
    TaikoMaster = 10430, --舞乐晨星
    TwoSideTower = 10431, --正逆塔
    BiancaTheatre = 10433,  --肉鸽2期
    SummerSignIn = 10434, --夏日签到
    NewbieTask = 10435, -- 新手任务二期
    CharacterTower = 10436, --本我回廊（角色塔）
    Rift = 10437, -- 大秘境
    ColorTable = 10438, -- 调色板战争
    FubenBrilliantWalk = 10439, -- 光辉同行
    FubenAwareness = 10440, -- 意识公约副本
    SkinVote = 10442, -- 皮肤投票
    Restaurant = 10443, -- 餐厅玩法
    Maverick2 = 10444, -- 异构阵线2.0
    MonsterCombat = 10447, -- 战双BVB
    CerberusGame = 10448, -- 三头犬小队
    SlotMachines = 10449, -- 老虎机
    Transfinite = 10451, -- 历战映射
    NewActivityCalendar = 10452, -- 新活动周历
    Theatre3 = 10453, -- 肉鸽3.0
    Turntable = 10454, -- 夏日幸运星
    BlackRockChess = 10455, -- 国际战棋
    ConnetingLine = 10456, -- 连线游戏
    RogueSim = 10457, -- 肉鸽模拟经营
    Kotodama = 10459, -- 言灵
    FangKuai = 10461, -- 大方块
    Temple = 10463, -- 庙会
    LinkCraftActivity = 10465, -- 战双工艺
    BossInshot = 10467, -- Boss跃升
    LineArithmetic = 10468, -- 大连线
    MechanismActivity = 10469, -- 机制玩法
    Theatre4 = 10470, -- 肉鸽4.0
    SimulateTrain = 10474, -- 数据演习
    BagOrganizeActivity = 10473, -- 背包整理玩法
    Temple2 = 10472, -- 庙会2
    Game2048 = 10475, -- 2048玩法
    FpsGame = 10477, -- 首席打枪
    WheelchairManual = 10478, --轮椅手册
    ReCallActivity = 10479, -- 拉人回流
    StageMemory = 10480, -- 周年精选关
    Maverick3 = 10482, -- 孤胆枪手
    GachaCanLiver = 10484, --3.1可肝卡池（常驻+限时组合）
    LuckyTenant = 10481, -- 幸运租客
    Pcg = 10485, -- 打牌
    PokerGuessing2 = 10486,
    VersionGift = 10487, -- 合版本活动
    ScoreTower = 10488, -- 新矿区
    Theatre5 = 10491, -- 肉鸽5.0
    BountyChallenge = 10492, -- 悬赏挑战
    DlcRelink = 10493, -- 联机共斗
    PlotExhibition = 10494, -- 军团（剧情）
    SpeedrunStage = 10495, -- 速通模式
    
    SkyGarden = 20000, --空中花园
    Race = 10354, --赛马
    FashionSuit = 10496, --涂装套装
    AprilFoolsDayClearOut = 10499, -- 愚人节假界面小活动
    PBRGame = 10500, -- 战双兄弟
    Theatre6 = 10501, -- 肉鸽6.0
    LifeTree = 10502, -- 生命树图鉴
    GameCollection = 10503, -- 小游戏合集
}   

XFunctionManager.FunctionType = {
    System = 1,
    Stage = 2,
}

XFunctionManager.TimeState = {
    Start = 1,
    End = 2,
}

--- 对于埋点记录，跳转类型
XFunctionManager.SkipTypeForRecord = {
    CommonSkip = 1, -- 通用跳转，id指向SkipFunctional.tab
    FubenActivitySkip = 2, -- 战斗面板跳转, id指向FubenActivity.tab
}

XFunctionManager.__RecordTestEnable = false -- 是否开启埋点输出测试

function XFunctionManager.FilterUi(evt, args, ...)
    local uiName = args[0].UiData.UiName
    if ShieldUiNameDic[uiName] then
        XUiManager.TipText("ShieldFunctionTip", nil, true)
        XLuaUiManager.RunMain()
    end
end

function XFunctionManager.FilterUiFinish()
    ShieldUiNameDic = {}
    CsXGameEventManager.Instance:RemoveEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE, XFunctionManager.FilterUi)
    XEventManager.RemoveEventListener(XEventId.EVENT_MAINUI_ENABLE, XFunctionManager.FilterUiFinish)
end

function XFunctionManager.InitShieldFuncData(shieldFuncList, inGameUpdate)
    ShieldFuncDic = {}
    ShieldUiNameDic = {}
    local EnableFilterUi = true
    for _, v in ipairs(shieldFuncList) do
        ShieldFuncDic[v] = true
        if inGameUpdate then
            for _, uiName in ipairs(XFunctionConfig.GetShieldFuncUiName(v)) do
                if CS.XFight.Instance and XLuaUiManager.IsUiShow(uiName) then
                    EnableFilterUi = false
                    XUiManager.TipText("ShieldFunctionTip", nil, true)
                    XLuaUiManager.RunMain()
                    ShieldUiNameDic = {}
                end
                ShieldUiNameDic[uiName] = true
            end
        end
    end

    if inGameUpdate and EnableFilterUi then
        CsXGameEventManager.Instance:RegisterEvent(CS.XEventId.EVENT_UI_ALLOWOPERATE, XFunctionManager.FilterUi)
        XEventManager.AddEventListener(XEventId.EVENT_MAINUI_ENABLE, XFunctionManager.FilterUiFinish)
    end
end

function XFunctionManager.InitFunctionOpenTimeData(functionOpenTimeList)
    FunctionOpenTimeDict = {}
    if not XTool.IsTableEmpty(functionOpenTimeList) then
        for _, data in pairs(functionOpenTimeList) do
            FunctionOpenTimeDict[data.FunctionId] = data.TimeId
        end
    end
    XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_OPEN_TIME_CHANGED)
end

function XFunctionManager.InitFuncOpenList()
    XFunctionConfig.InitFuncOpenList()
end

--检测是否可以过滤该功能
function XFunctionManager.CheckFunctionFitter(id)
    return ShieldFuncDic[id]
end

function XFunctionManager.CheckFunctionInTime(functionId)
    if XTool.IsTableEmpty(FunctionOpenTimeDict) then
        return true
    end
    local timeId = FunctionOpenTimeDict[functionId]
    if not timeId or timeId <= 0 then
        return true
    end
    return XFunctionManager.CheckInTimeByTimeId(timeId)
end

function XFunctionManager.GetFunctionTimeId(functionId)
    if XTool.IsTableEmpty(FunctionOpenTimeDict) then
        return 0
    end
    local timeId = FunctionOpenTimeDict[functionId]
    return timeId and timeId or 0
end

--界面跳转
---@param id @SkipFunctional.tab 的 SkipId
---@param fromMsg @来源描述（界面/系统)，用于埋点，可选参数
function XFunctionManager.SkipInterface(id, fromMsg, ...)
    if id == 0 then
        return false
    end

    local list = XFunctionConfig.GetSkipFuncCfg(id)
    if list == nil then
        XLog.Error("XFunctionManager.SkipInterface error: can not found list, id = " .. tostring(id))
        return false
    end

    if list.FunctionalId ~= nil and list.FunctionalId ~= 0 then
        -- 屏蔽功能
        if XFunctionManager.CheckFunctionFitter(list.FunctionalId) then
            XUiManager.TipMsg(CS.XTextManager.GetText("FunctionalMaintain"))
            return false
        end

        if not XFunctionManager.DetectionFunction(list.FunctionalId) then
            return false
        end

    end


    if XTool.IsNumberValid(list.ConditionId) then
        if not XConditionManager.CheckCondition(list.ConditionId, list) then
            return false
        end
    end
    local isOpen = XFunctionManager.CheckInTimeByTimeId(list.TimeId,true)
    if not isOpen then
        XUiManager.TipText("ActivityBaseTaskSkipNotInDuring")
        return
    end
    -- 提审包屏蔽，跳转到主线页面
    if XUiManager.IsHideFunc and list.IsHideFunc then
        -- XLuaUiManager.Open("UiFuben", XDataCenter.FubenManager.StageType.Mainline, nil, 1)
        XLuaUiManager.Open("UiNewFuben", XEnumConst.FuBen.ChapterType.MainLine)
        return false
    end

    
    -- 直接指定界面跳转
    if list.Origin == XFunctionManager.SkipOrigin.System then
        if XLuaUiManager.IsUiShow(list.UiName) then
            return false
        end
        XLuaUiManager.Open(list.UiName)
        XFunctionManager.RecordSkip(id, nil, fromMsg)
        return true
    elseif list.Origin == XFunctionManager.SkipOrigin.SonSystem then
        if XLuaUiManager.IsUiShow(list.UiName) then
            return false
        end

        if list.UiName == "UiCharacter" then
            XLuaUiManager.Open(list.UiName, list.ParamId, nil, nil, nil, true)
        elseif list.UiName == "UiActivityBase" then
            XLuaUiManager.Open(list.UiName, list.ParamId, list.CustomParams[1], list.CustomParams[2])
        else
            XLuaUiManager.Open(list.UiName, list.ParamId)
        end

        XFunctionManager.RecordSkip(id, nil, fromMsg)
        return true
    elseif list.Origin == XFunctionManager.SkipOrigin.Main then
        if XLuaUiManager.IsUiShow("UiMain") then
            return false
        end

        XLuaUiManager.RunMain()
        XFunctionManager.RecordSkip(id, nil, fromMsg)
        return true
    end

    -- 其他模块接口调用
    local result = nil
    
    if list.Origin == XFunctionManager.SkipOrigin.Section then
        result = XDataCenter.FubenManager.GoToFuben(list.ParamId)
    elseif list.Origin == XFunctionManager.SkipOrigin.SystemWithArgs then
        result = XDataCenter.FunctionalSkipManager.SkipSystemWidthArgs(list)
    elseif list.Origin == XFunctionManager.SkipOrigin.Custom then
        result = XDataCenter.FunctionalSkipManager.SkipCustom(list, ...)
    elseif list.Origin == XFunctionManager.SkipOrigin.Dormitory then
        result = XDataCenter.FunctionalSkipManager.SkipDormitory(list)
    elseif list.Origin == XFunctionManager.SkipOrigin.ActivityUrl then --活动跳转链接
        result = XMVCA.XUrl:SkipByUrlId(list.ParamId)
    elseif list.Origin == XFunctionManager.SkipOrigin.MVCAModule then
        result = XDataCenter.FunctionalSkipManager.SkipMVCAModule(list, ...)
    end

    if list.IsRecord then
        XFunctionManager._DealWithSkipResult(result, list.SkipId, fromMsg)
    end
    
    return result
end

function XFunctionManager.CheckSkipInDuration(id, defaultClose)
    local cfg = XFunctionConfig.GetSkipFuncCfg(id)
    if not cfg then
        return false
    end

    local timeId = cfg.TimeId
    local startTimeStr = cfg.StartTime
    local closeTimeStr = cfg.CloseTime
    if timeId and timeId ~= 0 then
        return XFunctionManager.CheckInTimeByTimeId(timeId)
    else
        local nowTimeStamp = XTime.GetServerNowTimestamp()
        if startTimeStr and startTimeStr ~= "" and closeTimeStr and closeTimeStr ~= "" then
            local startTime = XTime.ParseToTimestamp(startTimeStr)
            local closeTime = XTime.ParseToTimestamp(closeTimeStr)
            return (nowTimeStamp >= startTime and nowTimeStamp <= closeTime)
        elseif startTimeStr and startTimeStr ~= "" then
            local startTime = XTime.ParseToTimestamp(startTimeStr)
            return nowTimeStamp >= startTime
        elseif closeTimeStr and closeTimeStr ~= "" then
            local closeTime = XTime.ParseToTimestamp(closeTimeStr)
            return nowTimeStamp < closeTime
        end
    end

    if defaultClose then
        return false
    end
    
    return true
end

function XFunctionManager.IsCanSkip(skipId)
    local list = XFunctionConfig.GetSkipList(skipId)
    if not list then return false end
    return XFunctionManager.JudgeCanOpen(list.FunctionalId)
end

function XFunctionManager.IsCanSkipCheckTime(skipId)
    ---@type XTableSkipFunctional
    local config = XFunctionConfig.GetSkipList(skipId)
    if not config then
        return false
    end
    if config.TimeId > 0 then
        if not XFunctionManager.CheckInTimeByTimeId(config.TimeId) then
            return false
        end
    end
    if not XFunctionManager.IsCanSkip(skipId) then
        return false
    end
    return true
end

function XFunctionManager.IsPlayerMark(id)
    return XPlayer.IsMark(id)
end

function XFunctionManager.JudgeOpen(id)
    if not XFunctionManager.CheckFunctionInTime(id) then
        return false
    end
    --判断是否开启功能
    if not XFunctionConfig.GetFuncOpenCfg(id) then
        return true
    end

    return XFunctionManager.IsPlayerMark(id)
end

function XFunctionManager.GetFunctionOpenCondition(id)
    --获取开启条件说明
    local isOpen
    local decs = ""

    if not XFunctionConfig.GetFuncOpenCfg(id) then
        return decs
    end

     if not XFunctionManager.CheckFunctionInTime(id) then
         return CS.XTextManager.GetText("FunctionNotDuringOpening")
     end

    for _, v in pairs(XFunctionConfig.GetFuncOpenCfg(id).Condition) do
        if v and v ~= 0 then
            isOpen, decs = XConditionManager.CheckCondition(v)
            if not isOpen then
                break
            end
        end
    end

    return decs
end

function XFunctionManager.JudgeCanOpen(id, ignoreTime)
    if not ignoreTime then
        if not XFunctionManager.CheckFunctionInTime(id) then
            return false
        end
    end

    -- 判断是否能开启
    local isOpen = true

    -- 如果没有配置应该返回true
    if not XFunctionConfig.GetFuncOpenCfg(id) then
        return true
    end

    for _, v in pairs(XFunctionConfig.GetFuncOpenCfg(id).Condition) do
        if v and v ~= 0 then
            isOpen = XConditionManager.CheckCondition(v)
            if not isOpen then
                break
            end
        end
    end

    return isOpen
end
--================
--检测功能是否开放
--@param functionNameId:FunctionManager.FunctionName 功能枚举ID
--@param needMark:是否需要通知后端标记功能开放
--@param noTips:是否要弹出错误提示
--================
function XFunctionManager.DetectionFunction(functionNameId, needMark, noTips)
    if not XFunctionManager.CheckFunctionInTime(functionNameId) then
        if not noTips then
            XUiManager.TipMsg(CS.XTextManager.GetText("FunctionNotDuringOpening"))
        end
        return false
    end
    --判断能否进入功能按钮
    if not XFunctionManager.JudgeCanOpen(functionNameId) then
        if not noTips then
            XUiManager.TipError(XFunctionManager.GetFunctionOpenCondition(functionNameId))
        end
        return false
    end
    --后端需要使用功能开放标记时另外特殊判断并添加标记
    if needMark then
        --功能开启不用处理时间，时间仅仅用于拦截入口
        if not XFunctionManager.IsPlayerMark(functionNameId) then
            XPlayer.ChangeMarks(functionNameId)
        end
    end
    return true
end

local CanOpenId = {}

function XFunctionManager.CheckOpen()
    --开启功能
    for _, id in ipairs(XFunctionConfig.GetOpenList(XFunctionConfig.FunctionType.Basic)) do
        --功能未被标记
        if not XFunctionManager.IsPlayerMark(id) then
            --功能开启不用处理时间，时间仅仅用于拦截入口
            if XFunctionManager.JudgeCanOpen(id, true) then
                XPlayer.ChangeMarks(id)
                if XFunctionConfig.GetOpenHint(id) == 1 then
                    tableInsert(CanOpenId, id)
                end
            end
        end
    end
end


--获取功能开启提醒方式
function XFunctionManager.ShowOpenHint()
    if not CanOpenId or #CanOpenId <= 0 then
        return false
    end

    for i = 1, #CanOpenId do
        if XFunctionConfig.GetOpenHint(CanOpenId[i]) == 1 then
            XLuaUiManager.Open("UiHintFunctional", CanOpenId)
            CanOpenId = {}
            return true
        end
    end

    return false
end

--活动跳转相关 begin
function XFunctionManager.CheckSkipActivityOpen()
    local template = XFunctionConfig.GetMainActSkipCfg(1)
    local stageType = template.StageType
    local stageTypes = XDataCenter.FubenManager.StageType

    if stageType == stageTypes.Mainline then
        return XDataCenter.FubenMainLineManager.IsMainLineActivityOpen()
    --elseif stageType == stageTypes.ActivtityBranch then
    --    return XDataCenter.FubenActivityBranchManager.IsOpen()
    elseif stageType == stageTypes.ActivityBossSingle then
        return XDataCenter.FubenActivityBossSingleManager.IsOpen()
    end

    return false
end

function XFunctionManager.SkipToActivity()
    if not XFunctionManager.CheckSkipActivityOpen() then
        return
    end

    local skipId = XFunctionConfig.GetMainActSkipCfg(1).SkipId
    if not skipId then
        return
    end

    XFunctionManager.SkipInterface(skipId)
end

--活动跳转相关 end
--功能时间相关 begin
local function GetTimeData(timeId)
    return FunctionTimeData[timeId]
end

function XFunctionManager.IsEffectiveTimeId(timeId)
    if not timeId then
        return false
    end
    if FunctionTimeData[timeId] then
        return true
    else
        return false
    end
end

function XFunctionManager.CheckInTimeByTimeId(timeId, defaultOpen)
    --未配置timeId默认未开启
    if not XTool.IsNumberValid(timeId) then
        return defaultOpen and true or false
    end

    --timeId配置错误默认未开启
    local timeData = GetTimeData(timeId)
    if not timeData then
        return defaultOpen and true or false
    end

    --startTime未配置默认无开启时间限制
    --endTime未配置默认无结束时间限制
    return timeData:IsInTime()
end

function XFunctionManager.GetStartTimeByTimeId(timeId)
    if not timeId then return end
    local timeData = GetTimeData(timeId)
    return timeData and timeData:GetStartTime() or 0
end

function XFunctionManager.GetEndTimeByTimeId(timeId)
    if not timeId then return 0 end
    local timeData = GetTimeData(timeId)
    return timeData and timeData:GetEndTime() or 0
end

function XFunctionManager.GetTimeByTimeId(timeId)
    return XFunctionManager.GetStartTimeByTimeId(timeId), XFunctionManager.GetEndTimeByTimeId(timeId)
end

-- 已废弃
-- function XFunctionManager.IsDuringTime(functionId)
--     local timeId = XFunctionConfig.GetFuncOpenCfg(functionId) and XFunctionConfig.GetFuncOpenCfg(functionId).TimeId
--     --未配置timeId默认开启(功能开启特殊处理)
--     if not timeId or timeId == 0 then return true end
--     return XFunctionManager.CheckInTimeByTimeId(timeId)
-- end

function XFunctionManager.BindTimeId(timeId)
    if not timeId then return end
    local timeData = GetTimeData(timeId)
    if timeData then
        timeData:CreateTimer()
    end
end

local function UpdateFunctionTimeData(dataList)
    if not dataList then return end
    for _, data in pairs(dataList) do
        local timeId = data.Id

        local timeData = FunctionTimeData[timeId]
        if not timeData then
            timeData = XFunctionTime.New(timeId)
            FunctionTimeData[timeId] = timeData
        end

        timeData:UpdateData(data)
    end
end

function XFunctionManager.InitFuncOpenTime(data)
    UpdateFunctionTimeData(data)
end

--2.8
function XFunctionManager.CheckSkipPanelIsLoad(skipId)
    local list = XFunctionConfig.GetSkipList(skipId)
    if list.NotShowUI then
        for i, v in pairs(list.NotShowUI) do
            if XLuaUiManager.IsUiLoad(v) then
                return true
            end
        end
    end
    return false
end

--region 通用埋点相关接口

--- 记录成功跳转的埋点信息
function XFunctionManager.RecordSkip(skipId, skipType, fromMsg)
    skipType = skipType or XFunctionManager.SkipTypeForRecord.CommonSkip

    if skipType == XFunctionManager.SkipTypeForRecord.CommonSkip then
        ---@type XTableSkipFunctional
        local skipCfg = XFunctionConfig.GetSkipFuncCfg(skipId)

        if not skipCfg or not skipCfg.IsRecord then
            return
        end
    end


    local dict = {}
    dict["skip_id"] = skipId
    dict["role_level"] = XPlayer.GetLevel()
    dict["skip_type"] = skipType
    dict["from_msg"] = fromMsg

    if XMain.IsEditorDebug then
        if XFunctionManager.__RecordTestEnable then
            CS.XRecord.RecordTest(dict, "200019", "SkipFunc")
        else
            CS.XRecord.Record(dict, "200019", "SkipFunc")
        end
    else
        CS.XRecord.Record(dict, "200019", "SkipFunc")
    end
    
end

--- 从池子中获取结果Id
function XFunctionManager.GetNewResultId()
    local resultId = ResultIdPool
    ResultIdPool = ResultIdPool + 1
    
    -- 溢出处理，Id不包括负数范围
    if ResultIdPool <= 0 then
        ResultIdPool = 1
    end
    
    -- 标记该Id被使用
    if ResultWaitingDict[resultId] then
        XLog.Error('异步跳转, 获取新Id时，等待结果字典中已存在缓存滞留，数据为：', ResultWaitingDict[resultId])

        -- 回收滞留对象
        local timeOutData = ResultWaitingDict[resultId]
        ResultWaitingDict[resultId] = nil

        if type(timeOutData) == 'table' then
            AsyncSkipDataPool:ReturnItemToPool(timeOutData)
        end
    end

    ResultWaitingDict[resultId] = true
    
    return resultId
end

--- 接收跳转结果
function XFunctionManager.AcceptResult(resultId, isSuccess)
    if not XTool.IsNumberValid(resultId) then
        XLog.Error('无效的结果Id: '..tostring(resultId))
        return
    end
    
    if ResultWaitingDict[resultId] then
        if ResultWaitingDict[resultId] == true then
            -- 埋点Id请求了，但因为没有开启埋点或非通过SkipInterface，并没有执行完整，这边默认丢弃此次埋点处理
            ResultWaitingDict[resultId] = nil
            return
        end
        
        
        if isSuccess then
            local data = ResultWaitingDict[resultId]
            XFunctionManager.RecordSkip(data.SkipId, nil, data.FromMsg)
        end
        
        -- 回收对象
        AsyncSkipDataPool:ReturnItemToPool(ResultWaitingDict[resultId])
        ResultWaitingDict[resultId] = nil
    else
        XLog.Error('接收的结果等待Id在缓存中不存在:'..tostring(resultId))
    end
end

--- 处理跳转结果，这里主要是针对内部执行返回值情况的处理，只用于内部
function XFunctionManager._DealWithSkipResult(result, skipId, fromMsg)
    if result == true then
        XFunctionManager.RecordSkip(skipId, nil, fromMsg)
    elseif result == false then
        return
    elseif XTool.IsNumberValid(result) then
        if ResultWaitingDict[result] == nil then
            XLog.Error('异步跳转，返回的等待Id与请求的Id不一致')
            return
        end
        
        if ResultWaitingDict[result] ~= true then
            XLog.Error('异步跳转等待结果字典中已存在缓存滞留，数据为：', ResultWaitingDict[result])
            
            -- 回收滞留对象
            local timeOutData = ResultWaitingDict[result]
            ResultWaitingDict[result] = nil
            
            AsyncSkipDataPool:ReturnItemToPool(timeOutData)
        end
        
        local data = AsyncSkipDataPool:GetItemFromPool()
        data.SkipId = skipId
        data.FromMsg = fromMsg
        
        ResultWaitingDict[result] = data
    else
        ---@type XTableSkipFunctional
        local skipCfg = XFunctionConfig.GetSkipFuncCfg(skipId)

        if skipCfg then
            XLog.Error('跳转开启了埋点功能，但对应跳转接口返回值不正确，SkipId:'..tostring(skipId)..' Origin: '..tostring(skipCfg.Origin)..' UiName: '..tostring(skipCfg.UiName))
        else
            XLog.Error('跳转开启了埋点功能，但对应跳转接口返回值不正确，SkipId:'..tostring(skipId))
        end
    end
end

--endregion

--region 通用模块显隐控制

---@type table<number, XUiComponent.XFunctionShowGroup>
local FunctionShowGroupMap = nil
local FunctionShowEventMap = nil
local FunctionShowReddotMap = nil

--- C#组件XFunctionShowGroup初始化时注册到Lua中，处理事件监听、红点检测等逻辑
---@param functionShowGroup XUiComponent.XFunctionShowGroup
function XFunctionManager.RegisterFunctionShowGroup(functionShowGroup, instanceId2functionShowId)
    if not instanceId2functionShowId then
        return
    end

    if FunctionShowGroupMap == nil then
        FunctionShowGroupMap = {}
    end
    
    if FunctionShowEventMap == nil then
        FunctionShowEventMap = {}
    end

    if FunctionShowReddotMap == nil then
        FunctionShowReddotMap = {}
    end

    -- 获取组件的instanceId，构建instanceId-组件实例的映射
    local groupInstanceId = functionShowGroup:GetInstanceID()
    
    FunctionShowGroupMap[groupInstanceId] = functionShowGroup

    
    -- 注册刷新事件监听
    local group = FunctionShowEventMap[groupInstanceId] or {}

    for instanceId, id in pairs(instanceId2functionShowId) do
        if XTool.IsNumberValidEx(id) then
            XFunctionManager._AddFunctionShowEventListener(instanceId, id, group, groupInstanceId)
        end
    end

    FunctionShowEventMap[groupInstanceId] = group
    
    -- 注册红点事件

    for instanceId, id in pairs(instanceId2functionShowId) do
        if XTool.IsNumberValidEx(id) then
            XFunctionManager._AddFunctionShowReddotEvent(instanceId, id, groupInstanceId)
        end
    end
end

function XFunctionManager._AddFunctionShowEventListener(instanceId, id, functionShowEventGroup, groupInstanceId)
    -- 根据Id获取配置中的eventId列表
    local eventIds = nil
    
    local cfg = XFunctionConfig.GetFunctionalShowCfg(id)

    if cfg then
        eventIds = cfg.EventIds
    end

    if not XTool.IsTableEmpty(eventIds) then
        -- 每个eventId对应一组实例
        for i, eventId in pairs(eventIds) do
            local eventData = functionShowEventGroup[eventId] or {}

            eventData.InstanceList = eventData.InstanceList or {}
            eventData.InstanceList[instanceId] = true

            functionShowEventGroup[eventId] = eventData

            local eventFunc = function()
                XFunctionManager._AcceptFunctionShowEvent(groupInstanceId, eventData.InstanceList)
            end

            eventData.EventFuncList = eventData.EventFuncList or {}

            table.insert(eventData.EventFuncList, eventFunc)

            -- 注册事件监听
            XEventManager.AddEventListener(eventId, eventFunc)
        end
    end
end

function XFunctionManager._AddFunctionShowReddotEvent(instanceId, id, groupInstanceId)
    -- 根据Id获取配置中的eventId列表
    local reddotConditions = nil

    local cfg = XFunctionConfig.GetFunctionalShowCfg(id)

    if cfg then
        reddotConditions = cfg.RedPointConditions
    end

    if not XTool.IsTableEmpty(reddotConditions) then
        local group = FunctionShowReddotMap[groupInstanceId] or {}
        
        local redEventId = XRedPointManager.AddRedPointEvent(FunctionShowGroupMap[groupInstanceId], function(count)
            local isShow = count >= 0
            XFunctionManager._AcceptFunctionShowReddotEvent(groupInstanceId, instanceId, isShow)
        end, nil, reddotConditions, cfg.RedPointArgs, true)

        table.insert(group, redEventId)

        FunctionShowReddotMap[groupInstanceId] = group
    end
end

function XFunctionManager._AcceptFunctionShowEvent(groupInstanceId, instanceList)
    local functionShowGroup = FunctionShowGroupMap[groupInstanceId]
    
    if not functionShowGroup or not functionShowGroup:Exist() then
        return
    end
    
    if not XTool.IsTableEmpty(instanceList) then
        for instanceId, v in pairs(instanceList) do
            functionShowGroup:RefreshControlByInstanceId(instanceId)        
        end
    end
end

function XFunctionManager._AcceptFunctionShowReddotEvent(groupInstanceId, instanceId, isShow)
    local functionShowGroup = FunctionShowGroupMap[groupInstanceId]

    if not functionShowGroup or not functionShowGroup:Exist() then
        return
    end

    functionShowGroup:RefreshControlReddotShowByInstanceId(instanceId, isShow)
end


---@param functionShowGroup XUiComponent.XFunctionShowGroup
function XFunctionManager.RemoveFunctionShowGroup(functionShowGroup)
    if FunctionShowGroupMap == nil then
        return
    end
    
    local instanceId = functionShowGroup:GetInstanceID()
    -- 清除映射中的引用
    FunctionShowGroupMap[instanceId] = nil

    -- 移除所有事件
    if FunctionShowEventMap[instanceId] then
        local group = FunctionShowEventMap[instanceId]

        for eventId, eventData in pairs(group) do
            if not XTool.IsTableEmpty(eventData.EventFuncList) then
                for i, func in ipairs(eventData.EventFuncList) do
                    XEventManager.RemoveEventListener(eventId, func)
                end
            end
        end
        
        FunctionShowEventMap[instanceId] = nil
    end
    
    -- 移除所有红点
    if FunctionShowReddotMap[instanceId] then
        local group = FunctionShowReddotMap[instanceId]

        for i, redEventId in pairs(group) do
            XRedPointManager.RemoveRedPointEvent(redEventId)            
        end

        FunctionShowReddotMap[instanceId] = nil
    end
end

function XFunctionManager.CheckUiNodeIsShowByFunctionShowId(id)
    if not XTool.IsNumberValidEx(id) then
        -- 没有条件默认显示
        return true
    end
    
    -- 读表判断condition
    local cfg = XFunctionConfig.GetFunctionalShowCfg(id)

    if not cfg then
        return true
    end
    
    -- 判断是否提审屏蔽
    if cfg.IsCheckHideFunc and XUiManager.IsHideFunc then
        return false
    end
    
    -- 判断是否功能过滤
    if XTool.IsNumberValidEx(cfg.FunctionId) and XFunctionManager.CheckFunctionFitter(cfg.FunctionId) then
        return false
    end

    if not XTool.IsNumberValidEx(cfg.ShowCondition) then
        return true
    end
    
   
    return XConditionManager.CheckCondition(cfg.ShowCondition)
end

function XFunctionManager.CheckUiNodeIsUnlockByFunctionShowId(id)
    if not XTool.IsNumberValidEx(id) then
        -- 没有条件默认解锁
        return true
    end

    -- 读表判断condition
    local cfg = XFunctionConfig.GetFunctionalShowCfg(id)

    if not cfg then
        return true
    end

    -- 判断是否提审屏蔽
    if cfg.IsCheckHideFunc and XUiManager.IsHideFunc then
        return false
    end

    -- 判断是否功能过滤
    if XTool.IsNumberValidEx(cfg.FunctionId) and XFunctionManager.CheckFunctionFitter(cfg.FunctionId) then
        return false
    end

    if not XTool.IsNumberValidEx(cfg.UnlockCondition) then
        return true
    end


    return XConditionManager.CheckCondition(cfg.UnlockCondition)
end

function XFunctionManager.CheckRedNodeIsCanShowByFunctionShowId(id)
    if not XTool.IsNumberValidEx(id) then
        -- 没有条件默认显示
        return true
    end

    -- 读表判断condition
    local cfg = XFunctionConfig.GetFunctionalShowCfg(id)

    if not cfg then
        return true
    end

    -- 没有先决条件也允许显示
    if XTool.IsTableEmpty(cfg.RedPointShowPreCondition) then
        return true
    end

    for i, v in pairs(cfg.RedPointShowPreCondition) do
        if XTool.IsNumberValidEx(v) and not XConditionManager.CheckCondition(v) then
            return false
        end
    end
    
    return true
end

---刷新组内所有的红点，一般用于界面Enable时全量刷新
function XFunctionManager.UpdateFunctionShowGroupAllReddot(groupInstanceId)
    local group = FunctionShowReddotMap[groupInstanceId]

    if not XTool.IsTableEmpty(group) then
        for i, redEventId in pairs(group) do
            XRedPointManager.Check(redEventId)
        end
    end
end
--endregion

--AFDeepLink特定需求
function XFunctionManager.IsAFDeepLinkCanSkipByShowTips(skipId)
    if not XOverseaManager.IsOverSeaRegion() then
        return false
    end
    local list = XFunctionConfig.GetSkipList(skipId)
    if not list then return false end
    local isCanSkip = XFunctionManager.DetectionFunction(list.FunctionalId)
    if isCanSkip and not XFunctionManager.CheckSkipInDuration(skipId) then
        XUiManager.TipError(CS.XTextManager.GetText("AFDeepLinkNotTime"))
        return false
    end
    return isCanSkip
end


XRpc.NotifyTimeLimitCtrlConfigList = function(data)
    UpdateFunctionTimeData(data.TimeLimitCtrlConfigList)
    XEventManager.DispatchEvent(XEventId.EVENT_ETCD_TIME_CHANGE)
end

--功能时间相关 end
XRpc.NotifyClientShieldFunction = function(data)
    XFunctionManager.InitShieldFuncData(data.ShieldFunctionIds, true)
end

XRpc.NotifyClientFunctionOpenConfig = function(data) 
    XFunctionManager.InitFunctionOpenTimeData(data.FunctionOpenTimeConfigs)
end