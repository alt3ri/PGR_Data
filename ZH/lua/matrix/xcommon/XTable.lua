local ValueTypestringPrimaryKey = {ValueType = "string",PrimaryKey=true}
local ValueTypestring = {ValueType = "string"}
local ValueTypeintPrimaryKey = {ValueType = "int",PrimaryKey=true}
local ValueTypeint = {ValueType = "int"}
local ValueTypefloat = {ValueType = "float"}
local ValueTypefix = {ValueType = "fix"}
local ValueTypebool = {ValueType = "bool"}
local Type2KeyTypestringValueTypestring = {Type = 2, KeyType = "string", ValueType = "string"}
local Type2KeyTypeintValueTypestring = {Type = 2, KeyType = "int", ValueType = "string"}
local Type2KeyTypeintValueTypeint = {Type = 2, KeyType = "int", ValueType = "int"}
local Type2KeyTypeintValueTypefloat = {Type = 2, KeyType = "int", ValueType = "float"}
local Type1ValueTypestring = {Type = 1, ValueType = "string"}
local Type1ValueTypeint = {Type = 1, ValueType = "int"}
local Type1ValueTypefloat = {Type = 1, ValueType = "float"}
local Type1ValueTypefix = {Type = 1, ValueType = "fix"}
local Type1ValueTypebool = {Type = 1, ValueType = "bool"}
XTable = {
    BindLauncherNpc = {
        BindBone = ValueTypestring,
        BindFrame = ValueTypefix,
    },
    BindStartHeight = {
        BindFrame = ValueTypefix,
    },
    BindTargetHeight = {
        BindFrame = ValueTypefix,
    },
    BindTargetNpc = {
        BindBone = ValueTypestring,
        BindFrame = ValueTypefix,
    },
    BornPositionData = {
    },
    ExtraEffectData = {
        EffectName = ValueTypestring,
    },
    ExtraEffectDistanceData = {
        Distance = ValueTypefix,
        EffectName = ValueTypestring,
    },
    GlobalTimeScaleConfig = {
        TargetScale = ValueTypefix,
        DurationFrame = ValueTypeint,
        EaseInFrame = ValueTypeint,
        EaseOutFrame = ValueTypeint,
        EaseInCurveId = ValueTypeint,
        EaseOutCurveId = ValueTypeint,
    },
    IXTableCharacterSkillUpgradeBase = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Level = ValueTypeint,
        ConditionId = Type1ValueTypeint,
    },
    LauncherGround = {
        OffsetHeight = ValueTypefix,
        Frame = ValueTypefix,
    },
    LauncherGroundWhenBorn = {
        OffsetHeight = ValueTypefix,
        Frame = ValueTypefix,
    },
    LivWarmSoundsActivitySoundLocal = {
        SoundId = ValueTypeintPrimaryKey,
        RankNumber = ValueTypestring,
        CueId = ValueTypeint,
        AttachedImgUrl = ValueTypestring,
        ReflectedImgUrl = ValueTypestring,
    },
    LivWarmSoundsActivityStageLocal = {
        Id = ValueTypeintPrimaryKey,
        PreStageId = ValueTypeint,
        ActivityId = ValueTypeint,
        BroadTestTime = ValueTypeint,
        StageName = ValueTypestring,
        FinishImg = ValueTypestring,
        FinishText = ValueTypestring,
        FinishUrl = ValueTypestring,
        InitialSoundId = Type1ValueTypeint,
        Hint = Type1ValueTypestring,
    },
    Luancher = {
        ReferenceBone = ValueTypestring,
        OffsetHeight = ValueTypefix,
        Frame = ValueTypefix,
    },
    MissileBindHeightParam = {
        BindFrame = ValueTypefix,
    },
    MissileHeightLimitationParam = {
        Frame = ValueTypefix,
    },
    TrackConfig = {
        TrackRes = ValueTypestring,
        Duration = ValueTypefloat,
        BlendIn = ValueTypefloat,
        BlendOut = ValueTypefloat,
        PrefabXZ = ValueTypeint,
        PrefabY = ValueTypeint,
        PrefabRot = ValueTypeint,
    },
    XSubPackConfig = {
        Id = ValueTypeintPrimaryKey,
        ResourcePath = ValueTypestring,
    },
    XTabelCoupletWord = {
        Id = ValueTypeintPrimaryKey,
        WordImageUrl = ValueTypestring,
    },
    XTableAccumulatedConsumeDrawActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        CoinItemId = ValueTypeint,
        CoinCost = ValueTypeint,
        SingleMaxDraw = ValueTypeint,
        DropId = ValueTypeint,
        AssetItemId = ValueTypeint,
    },
    XTableAccumulatedConsumeDrawActivityDetail = {
        Id = ValueTypeintPrimaryKey,
        ActivityTimeId = ValueTypeint,
        ShopId = ValueTypeint,
        ShopCoinId = ValueTypeint,
        CoatTaskId = ValueTypeint,
        TaskGroupId = Type1ValueTypeint,
        TaskGroupName = Type1ValueTypestring,
        DrawId = ValueTypeint,
        ModelId = ValueTypestring,
        CoatBg = ValueTypestring,
        CoatName = ValueTypestring,
        RewardDescription = ValueTypestring,
    },
    XTableAccumulatedConsumeDrawExchangeIcon = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableAccumulatedConsumeDrawProbShow = {
        Id = ValueTypeintPrimaryKey,
        DrawId = ValueTypeint,
        RewardType = ValueTypeint,
        RewardId = ValueTypeint,
        Name = ValueTypestring,
        ProbShow = ValueTypestring,
    },
    XTableAccumulatedConsumeDrawReward = {
        ActId = ValueTypeintPrimaryKey,
        ProgressId = Type1ValueTypeint,
        ProgressRequired = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
    },
    XTableAccumulatedConsumeDrawRewardType = {
        RewardType = ValueTypeintPrimaryKey,
        RewardName = ValueTypestring,
        PrefabName = ValueTypestring,
    },
    XTableAccumulatedConsumeDrawRule = {
        DrawId = ValueTypeintPrimaryKey,
        BaseRuleTitles = Type1ValueTypestring,
        BaseRules = Type1ValueTypestring,
    },
    XTableAccumulatedExtraPayReward = {
        Id = ValueTypeintPrimaryKey,
        ExtraBigRewardId = ValueTypeint,
        ExtraSmallRewardId = ValueTypeint,
    },
    XTableAccumulatedPay = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        TimeId = ValueTypeint,
        PayRewardId = Type1ValueTypeint,
    },
    XTableAccumulatedPayReward = {
        Id = ValueTypeintPrimaryKey,
        Money = ValueTypeint,
        BigRewardId = ValueTypeint,
        SmallRewardId = ValueTypeint,
        ExtraPayRewardId = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableAccumulateExpendActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MailId = ValueTypeint,
        ItemId = ValueTypeint,
        ItemIcon = ValueTypestring,
        ConditionIds = Type1ValueTypeint,
        BaseRuleTitles = Type1ValueTypestring,
        BaseRules = Type1ValueTypestring,
    },
    XTableAccumulateExpendReward = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        TaskId = ValueTypeint,
        IsSpecialShow = ValueTypebool,
        IsMainReward = ValueTypebool,
    },
    XTableAccumulateExpendShopActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ItemId = ValueTypeint,
        ShopId = ValueTypeint,
        ShopItemId = ValueTypeint,
        ItemExchangeRate = ValueTypeint,
        SignRewardId = ValueTypeint,
        EndTipsTimeId = ValueTypeint,
        EndTipsMailId = ValueTypeint,
        PromptLeftTime = ValueTypeint,
        ShopItemMaxCount = ValueTypeint,
        OpenConditionIds = Type1ValueTypeint,
        BaseRuleTitles = Type1ValueTypestring,
        BaseRules = Type1ValueTypestring,
    },
    XTableAccumulateExpendShopSignReward = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        RewardIds = Type1ValueTypeint,
    },
    XTableAchievement = {
        Id = ValueTypeintPrimaryKey,
        AchievementTypeId = ValueTypeint,
        TaskId = ValueTypeint,
        Quality = ValueTypeint,
        IsHiddenMode = ValueTypeint,
        ShowTips = ValueTypeint,
    },
    XTableAchievementBaseTypeInfo = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SubName = ValueTypestring,
        EntryImage = ValueTypestring,
    },
    XTableAchievementTypeInfo = {
        Id = ValueTypeintPrimaryKey,
        BaseTypeId = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        GroupId = ValueTypeint,
        SortId = ValueTypeint,
        TimeId = ValueTypeint,
        ActivityType = ValueTypeint,
        ActivityBgType = ValueTypeint,
        ActivityBg = ValueTypestring,
        ActivityTitle = ValueTypestring,
        ActivityDes = ValueTypestring,
        ActivityPrefabPath = ValueTypestring,
        Params = Type1ValueTypeint,
        ConditionId = ValueTypeint,
        ShowBeginTime = ValueTypestring,
        ShowEndTime = ValueTypestring,
        ShowAllTime = ValueTypestring,
    },
    XTableActivityBriefGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SkipId = ValueTypeint,
        TimeId = ValueTypeint,
        BtnInitMethodName = ValueTypestring,
        IsRemindWhenOpen = ValueTypeint,
        RemindPriority = ValueTypeint,
        RedConditions = Type1ValueTypestring,
        RedParam = ValueTypeint,
        TagCondition = ValueTypestring,
        TagOffset = ValueTypefloat,
        TagParam = ValueTypestring,
        ActivityRewardIds = Type1ValueTypeint,
        RewardShowTimeIds = Type1ValueTypeint,
        ConstShowRewardId = ValueTypeint,
        ConstShowRewardClaimCondition = ValueTypeint,
    },
    XTableActivityBriefShop = {
        Id = ValueTypeintPrimaryKey,
        ShopId = ValueTypeint,
        TimeId = ValueTypeint,
        GoodsSortIds = Type1ValueTypeint,
        ShopBg = ValueTypestring,
        ShopSortGroupBg = ValueTypestring,
        ShopItemBg = ValueTypestring,
        ShopIcon = ValueTypestring,
    },
    XTableActivityBriefShopGoodsSort = {
        Id = ValueTypeintPrimaryKey,
        ShopId = ValueTypeint,
        BgImg = ValueTypestring,
        TargetIds = Type1ValueTypeint,
    },
    XTableActivityBriefStory = {
        Id = ValueTypeintPrimaryKey,
        BgImage = ValueTypestring,
        StoryId = ValueTypestring,
        UnlockBgImage = ValueTypestring,
        ConditionId = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableActivityBriefTask = {
        Id = ValueTypeintPrimaryKey,
        TaskGroupId = ValueTypeint,
        TaskBg = ValueTypestring,
        TaskVipBg = ValueTypestring,
        TaskGotBg = ValueTypestring,
        TaskVipGotBg = ValueTypestring,
        ActivityPointId = ValueTypeint,
        MarkTaskId = Type1ValueTypeint,
    },
    XTableActivityBtn = {
        Id = ValueTypeintPrimaryKey,
        Priority = ValueTypeint,
        Name = ValueTypestring,
        NameEN = ValueTypestring,
        ManagerName = ValueTypestring,
        IsAgency = ValueTypebool,
        SkipId = ValueTypeint,
        TimeId = ValueTypeint,
        IsOrConditions = ValueTypebool,
        Conditions = Type1ValueTypeint,
        BtnIcon = ValueTypestring,
        LeftTimeFun = ValueTypestring,
        Effect1 = ValueTypestring,
        Effect2 = ValueTypestring,
        EventId = ValueTypestring,
        RedPointRefreshEventId = ValueTypestring,
        RedPointConditions = Type1ValueTypestring,
    },
    XTableActivityCalendar = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SortId = ValueTypeint,
        TimeId = ValueTypeint,
        ActivityIcon = ValueTypestring,
        ActivityBanner = ValueTypestring,
        ActivityDesc = ValueTypestring,
        FunctionId = ValueTypeint,
        IsInCalendar = ValueTypeint,
        ShowItem = Type1ValueTypeint,
        SkipId = ValueTypeint,
        ExchangeTimeId = ValueTypeint,
        TaskTimeId = ValueTypeint,
        FightTimeId = ValueTypeint,
    },
    XTableActivityGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SortId = ValueTypeint,
        Bg = ValueTypestring,
        IsOnlyGroup = ValueTypeint,
    },
    XTableActivityLink = {
        Id = ValueTypeintPrimaryKey,
        LinkUrlId = ValueTypeint,
        RedPointType = ValueTypeint,
        LinkName = ValueTypestring,
        LinkUrl = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableActivitySortRule = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        ActivityId = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableActivityToastHall = {
        Id = ValueTypeintPrimaryKey,
        Priority = ValueTypeint,
        Name = ValueTypestring,
        Content = ValueTypestring,
        ConditionId = ValueTypeint,
        TimeId = ValueTypeint,
        IntervalTime = ValueTypeint,
        SceneKey = ValueTypestring,
        SkinId = ValueTypeint,
        MoveType = ValueTypeint,
        TipMoveTime = ValueTypeint,
        TipStayTime = ValueTypeint,
    },
    XTableActivityToastHallSceneRule = {
        SceneKey = ValueTypestringPrimaryKey,
        AllowTopUiNames = Type1ValueTypestring,
        BlockUiNames = Type1ValueTypestring,
    },
    XTableActivityToastHallSkin = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SkinPrefabUiPath = ValueTypestring,
    },
    XTableAlarmClock = {
        ClockId = ValueTypeintPrimaryKey,
        EpochTime = ValueTypeint,
        AlarmCycle = ValueTypeint,
        DayOfWeek = ValueTypestring,
        DayOfMonth = ValueTypestring,
    },
    XTableAnniversary = {
        Id = ValueTypestring,
        PlayerType = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableAnniversaryActivity = {
        ID = ValueTypeintPrimaryKey,
        Activityname = ValueTypestring,
        SkipID = ValueTypeint,
    },
    XTableAnniversaryReivewSharePlatforms = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableAnniversaryReviewDataUI = {
        Id = ValueTypestringPrimaryKey,
        UiName = ValueTypestring,
        DataType = ValueTypeint,
    },
    XTableAnniversaryReviewPictures = {
        Id = ValueTypeintPrimaryKey,
        Address = ValueTypestring,
        FocusPointUi = ValueTypestring,
        DisplayShowUI = Type1ValueTypestring,
        ScreenShotShowUI = Type1ValueTypestring,
    },
    XTableAnniversaryReviewTopics = {
        Id = ValueTypestringPrimaryKey,
        Name = ValueTypestring,
    },
    XTableAnnouncement = {
        Id = ValueTypeint,
        Des = ValueTypestring,
        Param = Type1ValueTypestring,
    },
    XTableArchive = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        Name = ValueTypestring,
        UnLockBg = ValueTypestring,
        LockBg = ValueTypestring,
        SkipId = ValueTypeint,
        TagText = ValueTypestring,
        ShowTag = ValueTypeint,
    },
    XTableArchiveAwarenessGroup = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Add = ValueTypestring,
        IconPath = ValueTypestring,
        ShowTimeStr = ValueTypestring,
    },
    XTableArchiveAwarenessGroupType = {
        GroupId = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        GroupName = ValueTypestring,
    },
    XTableArchiveCGDetail = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Order = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Author = ValueTypestring,
        Bg = ValueTypestring,
        SpineBg = ValueTypestring,
        LockBg = ValueTypestring,
        Condition = ValueTypeint,
        IsShowRedPoint = ValueTypeint,
        UnLockTime = ValueTypestring,
        BgWidth = ValueTypeint,
        BgHigh = ValueTypeint,
        BgOffSetX = ValueTypeint,
        BgOffSetY = ValueTypeint,
        ShowTimeStr = ValueTypestring,
    },
    XTableArchiveCGGroup = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableArchiveComicChapter = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Order = ValueTypeint,
        Name = ValueTypestring,
        Bg = ValueTypestring,
        LockBg = ValueTypestring,
        UnLockTime = ValueTypestring,
        Condition = ValueTypeint,
        IsShowRedPoint = ValueTypebool,
        ShowTimeStr = ValueTypestring,
        DetailCount = ValueTypeint,
    },
    XTableArchiveComicDetail = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        Bg = ValueTypestring,
        BgWidth = ValueTypefloat,
        BgHigh = ValueTypefloat,
    },
    XTableArchiveComicGroup = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        Name = ValueTypestring,
        ShowTimeStr = ValueTypestring,
    },
    XTableArchiveCommunication = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        CommunicationId = ValueTypeint,
        CommunicationType = ValueTypeint,
        CommunicationIcon = ValueTypestring,
        Name = ValueTypestring,
        Condition = ValueTypeint,
        Order = ValueTypeint,
        BtnContent = ValueTypestring,
        UnLockTime = ValueTypestring,
        NpcName = ValueTypestring,
        NpcHandIcon = ValueTypestring,
        UiType = ValueTypeint,
        ContentsGroupId = ValueTypeint,
    },
    XTableArchiveEventDateGroup = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        Name = ValueTypestring,
        GroupType = ValueTypeint,
        ShowTime = ValueTypestring,
    },
    XTableArchiveMail = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Condition = ValueTypeint,
        UnLockTime = ValueTypestring,
        Order = ValueTypeint,
        Title = ValueTypestring,
        SendName = ValueTypestring,
        Content = ValueTypestring,
        NpcHandIcon = ValueTypestring,
    },
    XTableArchiveMonster = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        Type = ValueTypeint,
        UnlockType = ValueTypeint,
        NpcId = Type1ValueTypeint,
        StageIds = Type1ValueTypeint,
    },
    XTableArchiveMonsterInfo = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        GroupId = ValueTypeint,
        Type = ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableArchiveMonsterInner = {
        Id = ValueTypeintPrimaryKey,
        Author = ValueTypestring,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Pic = ValueTypestring,
        LockPic = ValueTypestring,
        TagGroupId = ValueTypeint,
        TagIds = Type1ValueTypeint,
        StandbyAction = ValueTypestring,
        Actions = Type1ValueTypestring,
    },
    XTableArchiveMonsterSkill = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Order = ValueTypeint,
        Title = ValueTypestring,
        Text = ValueTypestring,
        Condition = ValueTypeint,
    },
    XTableArchivePartner = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Order = ValueTypeint,
        LockIconPath = ValueTypestring,
        IconPath = ValueTypestring,
        StoryChapterId = ValueTypeint,
    },
    XTableArchivePartnerGroup = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        GroupName = ValueTypestring,
    },
    XTableArchivePVDetail = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        GroupId = ValueTypeint,
        Order = ValueTypeint,
        Name = ValueTypestring,
        Bg = ValueTypestring,
        LockBg = ValueTypestring,
        Pv = ValueTypeint,
        UnLockTime = ValueTypestring,
        Condition = ValueTypeint,
        BgWidth = ValueTypeint,
        BgHigh = ValueTypeint,
        BgOffSetX = ValueTypeint,
        BgOffSetY = ValueTypeint,
    },
    XTableArchivePVGroup = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableArchiveStoryChapter = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Order = ValueTypeint,
        Name = ValueTypestring,
        Bg = ValueTypestring,
        LockBg = ValueTypestring,
        BgWidth = ValueTypeint,
        BgHigh = ValueTypeint,
        BgOffSetX = ValueTypeint,
        BgOffSetY = ValueTypeint,
    },
    XTableArchiveStoryDetail = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        Order = ValueTypeint,
        Name = ValueTypestring,
        SubName = ValueTypestring,
        Icon = ValueTypestring,
        DescTitle = ValueTypestring,
        Desc = ValueTypestring,
        Condition = ValueTypeint,
        UnLockTime = ValueTypestring,
        StoryId = Type1ValueTypestring,
    },
    XTableArchiveStoryGroup = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableArchiveStoryNpc = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        Name = ValueTypestring,
        PicSmall = ValueTypestring,
        PicBig = ValueTypestring,
        UnLockTime = ValueTypestring,
        Condition = ValueTypeint,
    },
    XTableArchiveStoryNpcSetting = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Order = ValueTypeint,
        Type = ValueTypeint,
        Title = ValueTypestring,
        Text = ValueTypestring,
        Condition = ValueTypeint,
        UnLockTime = ValueTypestring,
    },
    XTableArchiveTag = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        Color = ValueTypestring,
        Bg = ValueTypestring,
        Name = ValueTypestring,
        IsNotShow = ValueTypeint,
        TagGroupId = Type1ValueTypeint,
    },
    XTableArchiveWeaponGroup = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        GroupName = ValueTypestring,
        CollectionTitle = Type1ValueTypestring,
        CollectionContent = Type1ValueTypestring,
        CollectNum = Type1ValueTypeint,
        IconPath = Type1ValueTypestring,
        CgId = Type1ValueTypeint,
    },
    XTableAreaDistribute = {
        Id = ValueTypeint,
        AreaGroupId = Type1ValueTypeint,
    },
    XTableAreaDistributeType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableAreaGroup = {
        Id = ValueTypeint,
        AreaId = Type1ValueTypeint,
        GroupFightEvents = Type1ValueTypeint,
    },
    XTableAreaStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BuffName = Type1ValueTypestring,
        DistributeTypes = Type1ValueTypeint,
        Desc = ValueTypestring,
        Region = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        BuffDesc = Type1ValueTypestring,
        StageId = Type1ValueTypeint,
        MarkId = ValueTypeint,
        IsAbandoned = ValueTypebool,
    },
    XTableAreaWarActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        TimeLimitTaskId = Type1ValueTypeint,
        ShopId = Type1ValueTypeint,
        Name = ValueTypestring,
        ActivityBanner = ValueTypestring,
    },
    XTableAreaWarArticle = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Priority = ValueTypeint,
        UnlockBlockId = ValueTypeint,
        UnlockBlockProgress = ValueTypeint,
        Author = ValueTypestring,
        Title = ValueTypestring,
        Content = ValueTypestring,
        StoryId = ValueTypestring,
        Background = ValueTypestring,
    },
    XTableAreaWarArticleGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        UnlockChapterId = ValueTypeint,
    },
    XTableAreaWarArticleLikeFactor = {
        Id = ValueTypeintPrimaryKey,
        LikeCount = ValueTypeint,
        RandMin = ValueTypeint,
        RandMax = ValueTypeint,
    },
    XTableAreaWarAuction = {
        ItemId = ValueTypeintPrimaryKey,
        BasePrice = ValueTypeint,
    },
    XTableAreaWarAuctionSell = {
        ItemId = ValueTypeintPrimaryKey,
        PriceIntervalMins = Type1ValueTypeint,
        PriceIntervalMaxs = Type1ValueTypeint,
        PriceDefault = ValueTypeint,
        PriceInterval = ValueTypeint,
    },
    XTableAreaWarBlock = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        NameEn = ValueTypestring,
        ChapterId = ValueTypeint,
        Type = ValueTypeint,
        ShowType = ValueTypeint,
        MovieId = ValueTypestring,
        OpenHour = ValueTypeint,
        PreBlockId = Type1ValueTypestring,
        FightBasicPurification = ValueTypeint,
        FightFactor = ValueTypeint,
        CleanNeed = ValueTypeint,
        AutoGrow = ValueTypeint,
        StageId = ValueTypeint,
        PurificationExp = ValueTypeint,
        MailId = ValueTypeint,
        ShowRewardId = ValueTypeint,
        RewardId = ValueTypeint,
        ActionPoint = ValueTypeint,
        DetachActionPoint = ValueTypeint,
        DetachBasicPurification = ValueTypeint,
        DetachExtraPurification = Type1ValueTypeint,
        DetachBasicRewardId = ValueTypeint,
        DetachExtraRewardId = Type1ValueTypeint,
        WorldBossStartHour = ValueTypeint,
        WorldBossEndHour = ValueTypeint,
        RepeatChallengeActionPoint = ValueTypeint,
        DetachRepeatChallengeActionPoint = ValueTypeint,
        RepeatChallengeRewardId = ValueTypeint,
        DetachRepeatChallengeRewardId = ValueTypeint,
        LevelType = ValueTypeint,
        LevelDesc = ValueTypestring,
        SideBlockId = Type1ValueTypeint,
        AuctionCionReward = ValueTypeint,
        DetachAuctionCionReward = ValueTypeint,
    },
    XTableAreaWarBlockAutoGrow = {
        Id = ValueTypeintPrimaryKey,
        BlockId = ValueTypeint,
        TargetPurification = ValueTypeint,
        TimeStr = ValueTypestring,
    },
    XTableAreaWarBlockDrop = {
        BlockId = ValueTypeintPrimaryKey,
    },
    XTableAreaWarBlockShowType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Prefab = ValueTypestring,
        StageDetailBg = ValueTypestring,
    },
    XTableAreaWarBossMail = {
        Id = ValueTypeintPrimaryKey,
        BlockId = ValueTypeint,
        Type = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableAreaWarBuff = {
        Id = ValueTypeintPrimaryKey,
        FightEventId = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        Bg = ValueTypestring,
    },
    XTableAreaWarChapter = {
        Id = ValueTypeintPrimaryKey,
        ChapterName = ValueTypestring,
        TimeId = ValueTypeint,
        WorldBossUiType = ValueTypeint,
        DailyBattleRewardId = ValueTypeint,
        DailyHelpRewardId = ValueTypeint,
        StageId = Type1ValueTypeint,
    },
    XTableAreaWarClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableAreaWarConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableAreaWarDetachCondition = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
    },
    XTableAreaWarDetachRole = {
        Id = ValueTypeintPrimaryKey,
        DetachCondition = Type1ValueTypeint,
    },
    XTableAreaWarDropGroup = {
        Id = ValueTypeintPrimaryKey,
    },
    XTableAreaWarDropQuality = {
        DropGroupId = ValueTypeintPrimaryKey,
    },
    XTableAreaWarEtcdConfig = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypestring,
    },
    XTableAreaWarGrow = {
        Level = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Buff = ValueTypeint,
        Exp = ValueTypeint,
        Icon = ValueTypestring,
        SkipNum = ValueTypeint,
    },
    XTableAreaWarHangUpReward = {
        Id = ValueTypeintPrimaryKey,
        UnlockBlockId = ValueTypeint,
        ProductionAmount = ValueTypeint,
    },
    XTableAreaWarItem = {
        ItemId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Quality = ValueTypeint,
        UnlockLv = ValueTypeint,
        IsRare = ValueTypebool,
        EffectType = ValueTypeint,
        EffectProbability = ValueTypeint,
        RareRewardId = ValueTypeint,
        GridMaxCount = ValueTypeint,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        ModelId = ValueTypeint,
    },
    XTableAreaWarItemQuality = {
        Quality = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        SellTipsType = ValueTypeint,
        SellTips = ValueTypestring,
        Effect = ValueTypestring,
    },
    XTableAreaWarItemRoomLevel = {
        Lv = ValueTypeintPrimaryKey,
        AddRareItemRate = ValueTypeint,
        LvUpItems = Type1ValueTypeint,
        LvUpItemCounts = Type1ValueTypeint,
        RewardId = ValueTypeint,
        ShowAttrs = Type1ValueTypeint,
        SkipNum = ValueTypeint,
        NeedCleanBlock = ValueTypeint,
    },
    XTableAreaWarLevelAutoGrow = {
        Id = ValueTypeintPrimaryKey,
        TimeStr = ValueTypestring,
        PurificationExp = ValueTypeint,
    },
    XTableAreaWarModel = {
        Id = ValueTypeintPrimaryKey,
        ModelUrl = ValueTypestring,
        PositionX = ValueTypefloat,
        PositionY = ValueTypefloat,
        PositionZ = ValueTypefloat,
        RotationX = ValueTypefloat,
        RotationY = ValueTypefloat,
        RotationZ = ValueTypefloat,
        ScaleX = ValueTypefloat,
        ScaleY = ValueTypefloat,
        ScaleZ = ValueTypefloat,
    },
    XTableAreaWarPlate = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BlockId = Type1ValueTypeint,
        UnlockBlockId = Type1ValueTypeint,
    },
    XTableAreaWarPurificationLevel = {
        Id = ValueTypeintPrimaryKey,
        Exp = ValueTypeint,
        TeamFightEventId = ValueTypeint,
        FightEventLevel = ValueTypeint,
        BuffId = ValueTypeint,
        AddAttr = Type1ValueTypeint,
        HoleCount = ValueTypeint,
    },
    XTableAreaWarSpecialRole = {
        Id = ValueTypeintPrimaryKey,
        OrderId = ValueTypeint,
        RobotId = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        HeadIcon = ValueTypestring,
        Lihui = ValueTypestring,
        UnlockBlockId = ValueTypeint,
        BuffId = ValueTypeint,
    },
    XTableAreaWarSpecialRoleReward = {
        Id = ValueTypeintPrimaryKey,
        UnlockCount = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableAreaWarWorldBossUi = {
        Id = ValueTypeintPrimaryKey,
        UiName = ValueTypestring,
        TitleIcon = ValueTypestring,
        RankTitle = ValueTypestring,
        ModelId = Type1ValueTypestring,
        HeadName = Type1ValueTypestring,
        HeadIcon = Type1ValueTypestring,
    },
    XTableArenaActivityControl = {
        Id = ValueTypeint,
        BeginTime = ValueTypeint,
        EndTime = ValueTypeint,
        RestTime = ValueTypeint,
        FightTime = ValueTypeint,
        ResetWaveRateTimeId = ValueTypeint,
        Desc = ValueTypestring,
        AutoJointTime = ValueTypeint,
        AutoJointPercent = ValueTypeint,
    },
    XTableArenaAreaBuffDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BuffBg = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableArenaGroupFightEvent = {
        Id = ValueTypeintPrimaryKey,
        FightEvents = Type1ValueTypeint,
    },
    XTableArenaLevel = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        WordIcon = ValueTypestring,
    },
    XTableArenaLevelChallenge = {
        Id = ValueTypeintPrimaryKey,
        BeforeChallengeId = Type1ValueTypeint,
        AfterLevelId = ValueTypeint,
    },
    XTableArenaOnlineActiveBuff = {
        Id = ValueTypeintPrimaryKey,
        Quality = ValueTypeint,
        QualityCount = ValueTypeint,
        AffectQuality = ValueTypeint,
        FightEffectId = ValueTypeint,
        OnIcon = ValueTypestring,
        OffIcon = ValueTypestring,
        ActiveTip = ValueTypestring,
        Title = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableArenaOnlineChapter = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        MaxLevel = ValueTypeint,
        MinLevel = ValueTypeint,
        Name = ValueTypestring,
        Title = ValueTypestring,
        Icon = ValueTypestring,
        PrefabPath = ValueTypestring,
        StoryId = ValueTypestring,
        SectionId = Type1ValueTypeint,
    },
    XTableArenaOnlineSection = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        LeftTimeDesc = ValueTypestring,
        PrefabPath = ValueTypestring,
        OpenDays = Type1ValueTypeint,
        StageGroupId = Type1ValueTypeint,
    },
    XTableArenaOnlineStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Sort = ValueTypeint,
        BgIcon = ValueTypestring,
        NameIcon = ValueTypestring,
        StageId = ValueTypestring,
        EnduranceCost = ValueTypeint,
        SingleSwitch = ValueTypebool,
        ConditionDesc = ValueTypestring,
        ActiveBuffId = ValueTypeint,
        BottomCount = ValueTypeint,
        ShowDropId = ValueTypeint,
        ShowBottomId = ValueTypeint,
        Difficulty = Type1ValueTypeint,
        SingleDiff = Type1ValueTypeint,
        SkillTitle = Type1ValueTypestring,
        SkillDesc = Type1ValueTypestring,
        EventId = Type1ValueTypeint,
    },
    XTableArenaOnlineStageGroup = {
        Id = ValueTypeintPrimaryKey,
        RequireStar = ValueTypeint,
        StageIds = Type1ValueTypeint,
        PrefabPath = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableArenaStage = {
        StageId = ValueTypeintPrimaryKey,
        DifficuIocn = ValueTypestring,
        Name = ValueTypestring,
        BgIconSmall = ValueTypestring,
        BgIconBig = ValueTypestring,
        MarkId = ValueTypeint,
    },
    XTableArrangementGameControl = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        Condition = ValueTypeint,
        MusicIds = Type1ValueTypeint,
        HelpId = ValueTypeint,
    },
    XTableArrangementGameMusic = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        NameSp = ValueTypestring,
        Selections = Type1ValueTypeint,
        MusicTexts = Type1ValueTypestring,
        ResCueId = ValueTypeint,
        ResText = ValueTypestring,
        ResTextSp = ValueTypestring,
        ResBg = ValueTypestring,
        ResBgSp = ValueTypestring,
        IconCd = ValueTypestring,
        IconCdSp = ValueTypestring,
    },
    XTableArrangementGameSelection = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TryCueId = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableAssignChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        ChapterName = ValueTypestring,
        ChapterEn = ValueTypestring,
        OrderId = ValueTypeint,
        Cover = ValueTypestring,
        SkillPlusId = ValueTypeint,
        AssignCondition = Type1ValueTypeint,
        SelectCharCondition = Type1ValueTypeint,
        SelectCharSkipId = Type1ValueTypeint,
        GroupId = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
        SkillIcon = ValueTypestring,
    },
    XTableAssignGroup = {
        GroupId = ValueTypeintPrimaryKey,
        PreGroupId = ValueTypeint,
        ChallengeNum = ValueTypeint,
        BaseStage = ValueTypeint,
        StageId = Type1ValueTypeint,
        TeamInfoId = Type1ValueTypeint,
        GroupOrderId = ValueTypestring,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableAssignTeamInfo = {
        Id = ValueTypeintPrimaryKey,
        RequireAbility = ValueTypeint,
        NeedCharacter = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableAssist = {
        AssistType = ValueTypeint,
        LevelKey = ValueTypeint,
        RoleMinLevel = ValueTypeint,
        RoleMaxLevel = ValueTypeint,
        TargetMinLevel = ValueTypeint,
        TargetMaxLevel = ValueTypeint,
    },
    XTableAssistCommon = {
        AssistType = ValueTypeint,
        ShowNm = ValueTypeint,
        RoleRewardId = ValueTypeint,
        TargetRewardId = ValueTypeint,
        RoleRewardMaxNum = ValueTypeint,
    },
    XTableAssistRevise = {
        Id = ValueTypeint,
        MaxValue = ValueTypeint,
        MinValue = ValueTypeint,
        AttribReviseId = ValueTypeint,
    },
    XTableAssistRule = {
        Id = ValueTypeintPrimaryKey,
        DisplayRange = Type1ValueTypeint,
        Weight = ValueTypeint,
        SuccessRate = ValueTypeint,
        Title = ValueTypestring,
    },
    XTableAssistType = {
        Type = ValueTypeint,
        Name = ValueTypestring,
        Weight = ValueTypeint,
    },
    XTableAttribAbility = {
        Key = ValueTypestringPrimaryKey,
        Ability = ValueTypefix,
        PartnerAbility = ValueTypefix,
    },
    XTableAttribBase = {
        Id = ValueTypeintPrimaryKey,
        Comment = ValueTypestring,
        Life = ValueTypeint,
        Attack = ValueTypeint,
        AttackIntensity = ValueTypeint,
        Defense = ValueTypeint,
        DefensePierceP = ValueTypeint,
        CritP = ValueTypeint,
        CritResistanceP = ValueTypeint,
        CritDmgRateP = ValueTypeint,
        CritDmgRateReductionP = ValueTypeint,
        ShieldEfficiencyP = ValueTypeint,
        ShieldAmpP = ValueTypeint,
        ShieldReductionP = ValueTypeint,
        ShieldGainBonusP = ValueTypeint,
        ShieldGainReductionP = ValueTypeint,
        PhysicalAmpP = ValueTypeint,
        Element1AmpP = ValueTypeint,
        Element2AmpP = ValueTypeint,
        Element3AmpP = ValueTypeint,
        Element4AmpP = ValueTypeint,
        PhysicalReductionP = ValueTypeint,
        Element1ReductionP = ValueTypeint,
        Element2ReductionP = ValueTypeint,
        Element3ReductionP = ValueTypeint,
        Element4ReductionP = ValueTypeint,
        PhysicalPierceP = ValueTypeint,
        Element1PierceP = ValueTypeint,
        Element2PierceP = ValueTypeint,
        Element3PierceP = ValueTypeint,
        Element4PierceP = ValueTypeint,
        SignalSkillDmgAmpP = ValueTypeint,
        CoreSkillDmgAmpP = ValueTypeint,
        NormalAtkDmgAmpP = ValueTypeint,
        ExSkillDmgAmpP = ValueTypeint,
        HuntSkillDmgAmpP = ValueTypeint,
        SignalSkillDmgReductionP = ValueTypeint,
        SpecialSkillDmgReductionP = ValueTypeint,
        NormalAtkDmgReductionP = ValueTypeint,
        ExSkillDmgReductionP = ValueTypeint,
        HuntSkillDmgReductionP = ValueTypeint,
        ThreatRate = ValueTypeint,
        CharacterValue = ValueTypeint,
        ExSkillPoint = ValueTypeint,
        IdleSpinningSpeed = ValueTypefloat,
        RunSpinningSpeed = ValueTypefloat,
        DodgeEnergy = ValueTypeint,
        JumpEnergy = ValueTypeint,
        DodgeEnergyRegen = ValueTypeint,
        JumpEnergyRegen = ValueTypeint,
        CustomEnergyGroup1 = ValueTypeint,
        CustomEnergyGroup2 = ValueTypeint,
        CustomEnergyGroup3 = ValueTypeint,
        CustomEnergyGroup4 = ValueTypeint,
        Speed = ValueTypefloat,
        RunSpeed = ValueTypefloat,
        JumpSpeed = ValueTypefloat,
        RunSpeedCOE = ValueTypefloat,
        JumpSpeedCOE = ValueTypefloat,
        IdleJumpSpeedCOE = ValueTypefloat,
        WalkJumpSpeedCOE = ValueTypefloat,
        SprintJumpSpeedCOE = ValueTypefloat,
        RunStartJumpSpeedCOE = ValueTypefloat,
        SprintStartJumpSpeedCOE = ValueTypefloat,
        RotationSpeed = ValueTypefloat,
        WalkSpeed = ValueTypefloat,
        WalkSpeedCOE = ValueTypefloat,
        SprintSpeed = ValueTypefloat,
        SprintSpeedCOE = ValueTypefloat,
        DmgReduction = ValueTypeint,
        BlockRate = ValueTypeint,
        BlockReduction = ValueTypeint,
        Attack1AmpP = ValueTypeint,
        Attack2AmpP = ValueTypeint,
        Attack3AmpP = ValueTypeint,
        Attack4AmpP = ValueTypeint,
        Attack5AmpP = ValueTypeint,
        Attack6AmpP = ValueTypeint,
        Attack7AmpP = ValueTypeint,
        DmgLimitP = ValueTypeint,
        Bonus1RateP = ValueTypeint,
        Bonus2RateP = ValueTypeint,
        Bonus3RateP = ValueTypeint,
        BonusDmgP = ValueTypeint,
        WeakAmpP = ValueTypeint,
        HealAmpP = ValueTypeint,
        BreakDmg = ValueTypeint,
        BreakDmgP = ValueTypeint,
        BreakGauge = ValueTypeint,
        BreakGaugeRecoveryRateP = ValueTypeint,
        BreakGaugeReductionCOE = ValueTypeint,
        OverDrive = ValueTypeint,
        OverDriveBreakTime = ValueTypeint,
        OverDriveStackP = ValueTypeint,
        OverDriveDecreaseP = ValueTypeint,
        OverDriveDecreaseSpeed = ValueTypeint,
        OverDriveRaiseLimit = ValueTypeint,
        OverDriveDecreaseLimit = ValueTypeint,
        CauseDamageThreatCoe = ValueTypeint,
        RebootValue = ValueTypeint,
        DmgAmplification = ValueTypeint,
        CooldownReduction = ValueTypeint,
        DodgeIncreaseP = ValueTypeint,
        BlockIncreaseP = ValueTypeint,
        RelinkChainSkillAmpP = ValueTypeint,
        BonusDmgP2 = ValueTypeint,
        BonusDmgP3 = ValueTypeint,
        DefenseReductionP = ValueTypeint,
        Element5AmpP = ValueTypeint,
        Element5ReductionP = ValueTypeint,
        Element5PierceP = ValueTypeint,
        AnyDmgAmpP = ValueTypeint,
        PhysicalAmpP2 = ValueTypeint,
        Element1AmpP2 = ValueTypeint,
        Element2AmpP2 = ValueTypeint,
        Element3AmpP2 = ValueTypeint,
        Element4AmpP2 = ValueTypeint,
        Element5AmpP2 = ValueTypeint,
        AnyDmgAmpP2 = ValueTypeint,
        SignalSkillDmgAmpP2 = ValueTypeint,
        NormalAtkDmgAmpP2 = ValueTypeint,
        ExSkillDmgAmpP2 = ValueTypeint,
        CoreSkillDmgAmpP2 = ValueTypeint,
        PhysicalWeaknessP = ValueTypeint,
        Element1WeaknessP = ValueTypeint,
        Element2WeaknessP = ValueTypeint,
        Element3WeaknessP = ValueTypeint,
        Element4WeaknessP = ValueTypeint,
        Element5WeaknessP = ValueTypeint,
        SignalSkillWeaknessP = ValueTypeint,
        NormalAtkWeaknessP = ValueTypeint,
        ExSkillDmgWeaknessP = ValueTypeint,
        CoreSkillWeaknessP = ValueTypeint,
        PhysicalResistanceReductionP = ValueTypeint,
        Element1ResistanceReductionP = ValueTypeint,
        Element2ResistanceReductionP = ValueTypeint,
        Element3ResistanceReductionP = ValueTypeint,
        Element4ResistanceReductionP = ValueTypeint,
        Element5ResistanceReductionP = ValueTypeint,
        HeavyEnergy = ValueTypeint,
        DamageTypeHeavyDmgAmpP = ValueTypeint,
        DamageTypeQteDmgAmpP = ValueTypeint,
        DamageTypeEntryDmgAmpP = ValueTypeint,
        DamageTypeHeavyDmgAmpP2 = ValueTypeint,
        DamageTypeQteDmgAmpP2 = ValueTypeint,
        DamageTypeEntryDmgAmpP2 = ValueTypeint,
        DamageTypeHeavyWeaknessP = ValueTypeint,
        DamageTypeQteWeaknessP = ValueTypeint,
        DamageTypeEntryWeaknessP = ValueTypeint,
        BreakResistP = ValueTypeint,
    },
    XTableAttribDesc = {
        Index = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Attrib = ValueTypestring,
    },
    XTableAttribGroup = {
        Id = ValueTypeintPrimaryKey,
        PoolId = ValueTypeint,
        Weight = ValueTypeint,
        AttribId = ValueTypeint,
        AttribGrowRateId = ValueTypeint,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        MaxAttribDesc = ValueTypestring,
    },
    XTableAttribPoolTmp = {
        Id = ValueTypeint,
        PoolId = ValueTypeint,
        Weight = ValueTypeint,
        AttribId = ValueTypeint,
        AttribGrowRateId = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Description = ValueTypestring,
        MaxAttribDesc = ValueTypestring,
    },
    XTableAttribRevise = {
        Id = ValueTypeintPrimaryKey,
        AttribTypes = Type1ValueTypeint,
        Values = Type1ValueTypefix,
    },
    XTableAudioClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypestring,
        Type = ValueTypeint,
    },
    XTableAutoFight = {
        Id = ValueTypeintPrimaryKey,
        Limit = ValueTypeint,
    },
    XTableAutoWindowController = {
        Id = ValueTypeintPrimaryKey,
        FunctionType = ValueTypeint,
        SkipId = ValueTypeint,
        Pre = ValueTypeint,
        TimeId = ValueTypeint,
        AutoType = ValueTypeint,
        AutoCount = ValueTypeint,
        ConditionIds = Type1ValueTypeint,
        ContinueOpen = ValueTypebool,
    },
    XTableAutoWindowView = {
        Id = ValueTypeintPrimaryKey,
        BgIcon = ValueTypestring,
        SpineBg = ValueTypestring,
        SkipId = ValueTypeint,
        SkipURL = ValueTypestring,
        Type = ValueTypeint,
    },
    XTableAwarenessChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Cover = ValueTypestring,
        Site = ValueTypeint,
        FightEventId = ValueTypeint,
        OpenCondition = Type1ValueTypeint,
        SelectCharCondition = Type1ValueTypeint,
        SelectCharSkipId = Type1ValueTypeint,
        BaseStage = ValueTypeint,
        StageId = Type1ValueTypeint,
        TeamInfoId = Type1ValueTypeint,
        ChapterNo = ValueTypestring,
    },
    XTableAwarenessSetting = {
        Id = ValueTypeintPrimaryKey,
        SuitId = ValueTypeint,
        Order = ValueTypeint,
        Type = ValueTypeint,
        Title = ValueTypestring,
        Text = ValueTypestring,
        Condition = ValueTypeint,
    },
    XTableAwarenessTeamInfo = {
        Id = ValueTypeintPrimaryKey,
        RequireAbility = ValueTypeint,
        NeedCharacter = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableBabelTowerActivity = {
        Id = ValueTypeintPrimaryKey,
        ActivityType = ValueTypeint,
        ExtraActivityId = ValueTypeint,
        ActivityTimeId = ValueTypeint,
        FightTimeId = ValueTypeint,
        ShowTimeId = ValueTypeint,
        RankType = ValueTypeint,
        BaseRankNum = ValueTypeint,
        StageId = Type1ValueTypeint,
        TimeoutScoreRatio = ValueTypeint,
        RebootSubScore = Type1ValueTypeint,
    },
    XTableBabelTowerActivityDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BeginStoryId = ValueTypestring,
        RankTitle = ValueTypestring,
        RewardId = ValueTypeint,
    },
    XTableBabelTowerBuff = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        FightEventId = ValueTypeint,
        UnlockLevel = ValueTypeint,
        ScoreAdd = ValueTypeint,
        PointSub = ValueTypeint,
        UnlockDesc = ValueTypestring,
        TeamLimitCount = ValueTypeint,
        BanCharacterId = Type1ValueTypeint,
        UnlockScore = Type2KeyTypeintValueTypeint,
    },
    XTableBabelTowerBuffDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BuffBg = ValueTypestring,
        BuffTriangleBg = ValueTypestring,
        Desc = ValueTypestring,
        TeachingContents = Type1ValueTypestring,
        BuffSuggestAbility = ValueTypeint,
    },
    XTableBabelTowerBuffGroup = {
        Id = ValueTypeintPrimaryKey,
        BuffId = Type1ValueTypeint,
    },
    XTableBabelTowerBuffGroupDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        BuffLv = Type1ValueTypeint,
        IsStress = ValueTypeint,
    },
    XTableBabelTowerClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableBabelTowerConditionDetails = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
    },
    XTableBabelTowerRankLevel = {
        Id = ValueTypeintPrimaryKey,
        MinLevel = ValueTypeint,
        MaxLevel = ValueTypeint,
    },
    XTableBabelTowerRankReward = {
        Id = ValueTypeintPrimaryKey,
        LevelId = ValueTypeint,
        MinRank = ValueTypefloat,
        MaxRank = ValueTypefloat,
        MailId = ValueTypeint,
        RankIcon = ValueTypestring,
    },
    XTableBabelTowerStage = {
        Id = ValueTypeintPrimaryKey,
        BaseScore = ValueTypeint,
        BaseSupportPoint = ValueTypeint,
        PreStageScore = ValueTypeint,
        TimeId = ValueTypeint,
        StageGuideId = Type1ValueTypeint,
        SupportConditionId = Type1ValueTypeint,
        BaseBuffId = Type1ValueTypeint,
        ChallengeBuffGroup = Type1ValueTypeint,
        SupportBuffGroup = Type1ValueTypeint,
        TeamCount = ValueTypeint,
        RobotIds = Type1ValueTypeint,
        ProtectRobotCount = ValueTypeint,
        ProtectChallengeBuffGroup = Type1ValueTypeint,
    },
    XTableBabelTowerStageDetails = {
        Id = ValueTypeintPrimaryKey,
        MainUiBg = ValueTypestring,
        StagePrefab = ValueTypestring,
        StageGuidePrefab = ValueTypestring,
        Name = ValueTypestring,
        Title = ValueTypestring,
        Number = ValueTypeint,
        ChallengeUiBg = ValueTypestring,
        SupportUiBg = ValueTypestring,
        ProtectTipText = ValueTypestring,
    },
    XTableBabelTowerStageGuide = {
        Id = ValueTypeintPrimaryKey,
        BuffGroup = Type1ValueTypeint,
        BuffId = Type1ValueTypeint,
    },
    XTableBabelTowerStageGuideDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        GuideBg = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableBabelTowerStageLevel = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        BuffId = ValueTypeint,
        Level = ValueTypeint,
        RecommendAblity = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        ScoreRatio = ValueTypefloat,
        FightEventId = Type1ValueTypeint,
        LockBuffId = Type1ValueTypeint,
        UnlockCondLevel = ValueTypeint,
        ScoreTitleUnlockDesc = ValueTypestring,
    },
    XTableBabelTowerStageLevelGlobalUnlock = {
        Id = ValueTypeintPrimaryKey,
        BuffIdList = Type1ValueTypeint,
        Level = ValueTypeint,
        MaxTeamId = ValueTypeint,
        ScoreTitleType = ValueTypeint,
        ScoreTitleQuality = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableBabelTowerSupportCondition = {
        Id = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
        PointAdd = ValueTypeint,
    },
    XTableBackFlow = {
        Id = ValueTypeintPrimaryKey,
        OpenCondition = ValueTypeint,
        NeedOffLineTime = ValueTypeint,
        Duration = ValueTypeint,
    },
    XTableBackground = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Quality = ValueTypeint,
        Description = ValueTypestring,
        WorldDescription = ValueTypestring,
        Icon = ValueTypestring,
        BigIcon = ValueTypestring,
        IconPath = ValueTypestring,
        SceneModelId = ValueTypeint,
        LockDec = ValueTypestring,
        ShowStr = ValueTypestring,
        Priority = ValueTypeint,
        IsFree = ValueTypeint,
        IsMainScene = ValueTypeint,
        ParticleGroupName = ValueTypestring,
        Tag = Type1ValueTypestring,
        SwitchDesc = Type1ValueTypestring,
        SceneRotation = ValueTypeint,
        ItemKey = ValueTypeint,
        ItemCount = ValueTypeint,
        SkipId = ValueTypeint,
        IsEnvMusic = ValueTypebool,
        TabTag = ValueTypestring,
    },
    XTableBagOrganizeActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        TaskTimelimitId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        EnableRankStageId = ValueTypeint,
    },
    XTableBagOrganizeBags = {
        Id = ValueTypeintPrimaryKey,
        Cost = ValueTypeint,
        MaxWidth = ValueTypeint,
        MaxHeight = ValueTypeint,
        IconAddress = ValueTypestring,
    },
    XTableBagOrganizeChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        StageIds = Type1ValueTypeint,
        TitleBg = ValueTypestring,
    },
    XTableBagOrganizeClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableBagOrganizeEvent = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        OptionTexts = Type1ValueTypestring,
        OptionResultIds = Type1ValueTypeint,
        EntranceIcon = ValueTypestring,
        EventImg = ValueTypestring,
        EventRoleName = ValueTypestring,
    },
    XTableBagOrganizeEventResult = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Desc = ValueTypestring,
        EffectDesc = ValueTypestring,
        Params = Type1ValueTypestring,
    },
    XTableBagOrganizeEventRule = {
        Id = ValueTypeintPrimaryKey,
        EventIds = Type1ValueTypeint,
        EventWeights = Type1ValueTypefloat,
    },
    XTableBagOrganizeGoods = {
        Id = ValueTypeintPrimaryKey,
        Value = ValueTypeint,
        IconAddress = ValueTypestring,
        BlockColor = ValueTypestring,
        SelectedColor = ValueTypestring,
        Blocks = Type1ValueTypeint,
    },
    XTableBagOrganizeGoodsGroup = {
        Id = ValueTypeintPrimaryKey,
        LifeTimeSeconds = ValueTypeint,
        GoodsList = Type1ValueTypeint,
    },
    XTableBagOrganizeGoodsRule = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        ConstantGroupId = ValueTypeint,
        TimeIndex = ValueTypeint,
        RandInterval = ValueTypefloat,
        RandGroupIds = Type1ValueTypeint,
        Duration = ValueTypefloat,
        PeriodTitle = ValueTypestring,
        PeriodDesc = ValueTypestring,
        ScoreRateAdds = ValueTypefloat,
        GoodsDefaultLifeTime = ValueTypefloat,
    },
    XTableBagOrganizeMap = {
        Id = ValueTypeintPrimaryKey,
        Blocks = Type1ValueTypeint,
    },
    XTableBagOrganizeScoreGrade = {
        StageId = ValueTypeintPrimaryKey,
        Score = Type1ValueTypeint,
        MaxScoreLimit = ValueTypeint,
    },
    XTableBagOrganizeStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        PreStageId = ValueTypeint,
        MapIds = Type1ValueTypeint,
        GoodsRuleIds = Type1ValueTypeint,
        EntranceRoleIcon = ValueTypestring,
        GuideImages = Type1ValueTypestring,
    },
    XTableBagOrganizeStageBaseRuleSet = {
        Id = ValueTypeintPrimaryKey,
        IsSameColroComboEnabled = ValueTypebool,
        IsMultyBagEnabled = ValueTypebool,
        IsTimelimitEnabled = ValueTypebool,
    },
    XTableBaseEquip = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Part = ValueTypeint,
        Star = ValueTypeint,
        Level = ValueTypeint,
        Quality = ValueTypeint,
        Priority = ValueTypeint,
        BigSuccessProbability = ValueTypeint,
        BigSuccessBottomId = ValueTypeint,
        PoolId = Type1ValueTypeint,
        BigSuccessPoolId = Type1ValueTypeint,
        RecoveryRewardId = ValueTypeint,
        NotEvaluatedDesc = Type1ValueTypestring,
        Icon = ValueTypestring,
        BigIcon = ValueTypestring,
        Obtain = ValueTypeint,
    },
    XTableBaseEquipBottomPool = {
        Id = ValueTypeint,
        Min = ValueTypeint,
        Max = ValueTypeint,
    },
    XTableBaseEquipScore = {
        Key = ValueTypestringPrimaryKey,
        Numerical = ValueTypeint,
        GrowRate = ValueTypeint,
    },
    XTableBattleExperiment = {
        Id = ValueTypeintPrimaryKey,
        CharacterID = ValueTypeint,
        Pic = ValueTypestring,
        Title = ValueTypestring,
        Description = ValueTypestring,
        NextTrialID = ValueTypeint,
    },
    XTableBattleShowSkillKeyframe = {
        Id = ValueTypeintPrimaryKey,
        Key = Type1ValueTypestring,
    },
    XTableBfrtChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        ChapterName = ValueTypestring,
        ChapterEn = ValueTypestring,
        OpenTimeStr = ValueTypestring,
        Bg = ValueTypestring,
        Icon = ValueTypestring,
        OrderId = ValueTypeint,
        GroupId = Type1ValueTypeint,
        TaskId = Type1ValueTypeint,
        PrefabName = ValueTypestring,
        ActivityCondition = ValueTypeint,
        Cover = ValueTypestring,
        RewardIds = Type1ValueTypeint,
        RewardTitleList = Type1ValueTypestring,
        RewardDescList = Type1ValueTypestring,
        BfrtRewardId = ValueTypeint,
    },
    XTableBfrtCourseReward = {
        Id = ValueTypeintPrimaryKey,
        CourseStars = Type1ValueTypeint,
        RewardIds = Type1ValueTypeint,
        ShowItems = Type1ValueTypestring,
        IsImportantItem = ValueTypeint,
    },
    XTableBfrtGroup = {
        GroupId = ValueTypeintPrimaryKey,
        GroupName = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        PreGroupId = ValueTypeint,
        ChallengeNum = ValueTypeint,
        BaseStage = ValueTypeint,
        StageId = Type1ValueTypeint,
        FightInfoId = Type1ValueTypeint,
        TeamFightSeq = ValueTypestring,
        LogisticsInfoId = Type1ValueTypeint,
        GroupOrderId = ValueTypeint,
        NeedPoint = ValueTypeint,
        ClearOpen = ValueTypeint,
    },
    XTableBiancaTheatreAchievement = {
        Id = ValueTypeintPrimaryKey,
        TagName = ValueTypestring,
        TaskIds = Type1ValueTypeint,
    },
    XTableBiancaTheatreActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        NeedCounts = Type2KeyTypeintValueTypeint,
        RewardIds = Type2KeyTypeintValueTypeint,
    },
    XTableBiancaTheatreBaseCharacter = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Career = ValueTypeint,
        ReferenceComboId = Type1ValueTypeint,
        Name = ValueTypestring,
    },
    XTableBiancaTheatreBaseGroup = {
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
    },
    XTableBiancaTheatreChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        GroupId = ValueTypeint,
        NextChapterIds = Type1ValueTypeint,
        ConditionId = ValueTypeint,
        ExtraRewardConditionId = ValueTypeint,
        ExtraRewardItemBoxId = ValueTypeint,
        ExtraRewardDesc = ValueTypestring,
        DefaultRecruitTicketId = ValueTypeint,
        FloorFightGroupId = ValueTypeint,
        FloorEventGroupId = ValueTypeint,
        FloorShopGroupId = ValueTypeint,
        OpenIndexIcon = ValueTypestring,
        OpenTitleIcon = ValueTypestring,
        SceneUrl = ValueTypestring,
        BgA = ValueTypestring,
        BgB = ValueTypestring,
        ModelUrl = ValueTypestring,
        OtherBg = ValueTypestring,
        BgmCueId = ValueTypeint,
        OpenBg = ValueTypestring,
    },
    XTableBiancaTheatreChapterGroup = {
        Id = ValueTypeintPrimaryKey,
        ChapterStartId = ValueTypeint,
        ConditionId = ValueTypeint,
    },
    XTableBiancaTheatreCharacterElements = {
        Id = ValueTypeintPrimaryKey,
        ElementName = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableBiancaTheatreCharacterLevel = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Level = ValueTypeint,
        Type = ValueTypeint,
        RobotId = ValueTypeint,
        FightAbility = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
    },
    XTableBiancaTheatreChildCombo = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ComboTypeId = ValueTypeint,
        IconPath = ValueTypestring,
        ConditionDescription = ValueTypestring,
        ActivationType = ValueTypeint,
    },
    XTableBiancaTheatreClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableBiancaTheatreCombo = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ChildComboId = ValueTypeint,
        EffectDescription = ValueTypestring,
        ConditionDesc = ValueTypestring,
        ConditionLevel = ValueTypeint,
        ConditionNum = ValueTypeint,
        IsDecay = ValueTypeint,
        EffectId = Type1ValueTypeint,
        EffectValid = Type1ValueTypeint,
        EffectTarget = Type1ValueTypeint,
        Quality = ValueTypeint,
    },
    XTableBiancaTheatreComboTypeName = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        OrderId = ValueTypeint,
    },
    XTableBiancaTheatreComboValid = {
        Id = ValueTypeintPrimaryKey,
        TriggerType = ValueTypeint,
        ComboType = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableBiancaTheatreConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Value = ValueTypestring,
    },
    XTableBiancaTheatreDecayRecruitTicket = {
        Id = ValueTypeintPrimaryKey,
        RefreshCount = ValueTypeint,
        RecruitCount = ValueTypeint,
        LeastRecruitCount = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        Quality = ValueTypeint,
        InnerItemId = ValueTypeint,
        VisionId = ValueTypeint,
    },
    XTableBiancaTheatreDefaultRecruitTicket = {
        Id = ValueTypeintPrimaryKey,
        NormalId = Type1ValueTypeint,
        SpecialId = Type1ValueTypeint,
    },
    XTableBiancaTheatreDifficulty = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ConditionId = ValueTypeint,
        ExpFactor = ValueTypefloat,
        OutItemFactor = ValueTypefloat,
        EffectGroupId = ValueTypeint,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        ShowItemIds = Type1ValueTypeint,
    },
    XTableBiancaTheatreEffectGroup = {
        Id = ValueTypeintPrimaryKey,
        FightEvents = Type1ValueTypeint,
        SystemEvents = Type1ValueTypeint,
    },
    XTableBiancaTheatreEnding = {
        Id = ValueTypeintPrimaryKey,
        PassType = ValueTypeint,
        Priority = ValueTypeint,
        Factor = ValueTypefloat,
        Type = Type1ValueTypeint,
        Param = Type1ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        StoryId = ValueTypestring,
        RImgDesc = ValueTypestring,
        Bg = ValueTypestring,
        SpineBg = ValueTypestring,
        RImgTitle = ValueTypestring,
        Icon = ValueTypestring,
        IconBg = ValueTypestring,
        RecordIndex = ValueTypeint,
        BgmCueId = ValueTypeint,
    },
    XTableBiancaTheatreEvent = {
        Id = ValueTypeintPrimaryKey,
        EventId = ValueTypeint,
        StepId = ValueTypeint,
        NextStepId = ValueTypeint,
        Type = ValueTypeint,
        FightNodeId = ValueTypeint,
        EffectGroupId = ValueTypeint,
        StepRewardItemType = ValueTypeint,
        StoryId = ValueTypestring,
        StepRewardItemId = Type2KeyTypeintValueTypeint,
        StepRewardItemCount = Type2KeyTypeintValueTypeint,
        OptionDesc = Type2KeyTypeintValueTypestring,
        OptionDownDesc = Type2KeyTypeintValueTypestring,
        OptionIcon = Type2KeyTypeintValueTypestring,
        OptionType = Type2KeyTypeintValueTypeint,
        OptionItemType = Type2KeyTypeintValueTypeint,
        OptionItemId = Type2KeyTypeintValueTypeint,
        OptionItemCount = Type2KeyTypeintValueTypeint,
        OptionNextStepGroupId = Type2KeyTypeintValueTypeint,
        OptionCondition = Type2KeyTypeintValueTypeint,
        Title = ValueTypestring,
        TitleContent = ValueTypestring,
        RoleIcon = ValueTypestring,
        RoleName = ValueTypestring,
        RoleContent = ValueTypestring,
        EventDesc = ValueTypestring,
        ConfirmContent = ValueTypestring,
        BgAsset = ValueTypestring,
    },
    XTableBiancaTheatreEventClientConfig = {
        Id = ValueTypeintPrimaryKey,
        NodeTypeName = ValueTypestring,
        NodeTypeIcon = ValueTypestring,
        NodeTypeDesc = ValueTypestring,
        SmallIcon = ValueTypestring,
        NodeTypeEffectUrl = ValueTypestring,
    },
    XTableBiancaTheatreEventGroup = {
        Id = ValueTypeintPrimaryKey,
        EventId = ValueTypeint,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
    },
    XTableBiancaTheatreEventStepGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        StepId = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableBiancaTheatreFieldGuide = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Order = ValueTypeint,
    },
    XTableBiancaTheatreFightLib = {
        Id = ValueTypeintPrimaryKey,
        FightId = ValueTypeint,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
    },
    XTableBiancaTheatreFightNode = {
        Id = ValueTypeintPrimaryKey,
        TemplateId = ValueTypeint,
        Note = ValueTypestring,
        Difficulty = ValueTypeint,
        GoldId = ValueTypeint,
        ItemBoxId = ValueTypeint,
        RecruitTicketId = ValueTypeint,
    },
    XTableBiancaTheatreFightNodeClient = {
        Id = ValueTypeintPrimaryKey,
        NodeTypeName = ValueTypestring,
        NodeTypeIcon = ValueTypestring,
        NodeTypeDesc = ValueTypestring,
        SmallIcon = ValueTypestring,
        NodeTypeEffectUrl = ValueTypestring,
    },
    XTableBiancaTheatreFightStageTemplate = {
        Id = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        TemplateId = ValueTypeint,
        StageId = ValueTypeint,
        Weight = ValueTypeint,
        Mode = ValueTypeint,
        ModeParams = Type1ValueTypeint,
        TimeLimit = ValueTypeint,
        MonsterGroupId = Type1ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        SuggestAbility = ValueTypeint,
    },
    XTableBiancaTheatreGold = {
        Id = ValueTypeintPrimaryKey,
        Count = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableBiancaTheatreGoldGroup = {
        Id = ValueTypeintPrimaryKey,
        GoldId = ValueTypeint,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
    },
    XTableBiancaTheatreItem = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Repeatable = ValueTypeint,
        Type = ValueTypeint,
        Quality = ValueTypeint,
        UnlockConditionId = ValueTypeint,
        EffectGroupId = ValueTypeint,
        Description = ValueTypestring,
        WorldDesc = ValueTypestring,
        Icon = ValueTypestring,
        VisionId = ValueTypeint,
    },
    XTableBiancaTheatreItemBox = {
        Id = ValueTypeintPrimaryKey,
        GroupId = Type1ValueTypeint,
        SafeGroupId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableBiancaTheatreItemBoxGroup = {
        Id = ValueTypeintPrimaryKey,
        ItemBoxId = ValueTypeint,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
    },
    XTableBiancaTheatreItemGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        ItemId = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableBiancaTheatreItemType = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableBiancaTheatreLevelReward = {
        Id = ValueTypeintPrimaryKey,
        UnlockScore = ValueTypeint,
        RewardId = ValueTypeint,
        Desc = ValueTypestring,
        DisplayType = ValueTypeint,
    },
    XTableBiancaTheatreMonster = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Level = ValueTypeint,
        BuffLevel = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
        Note = ValueTypestring,
    },
    XTableBiancaTheatreMonsterGroup = {
        Id = ValueTypeintPrimaryKey,
        MonsterIds = Type1ValueTypeint,
        Note = ValueTypestring,
    },
    XTableBiancaTheatreNode = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        CountWeight = Type1ValueTypeint,
        FightWeight = ValueTypeint,
        FightFactor = Type2KeyTypeintValueTypeint,
        FightWeightFactor = ValueTypefloat,
        EventWeight = ValueTypeint,
        ShopWeight = ValueTypeint,
        FightFloor = ValueTypeint,
        FightTop = ValueTypeint,
        EventFloor = ValueTypeint,
        EventTop = ValueTypeint,
        ShopFloor = ValueTypeint,
        ShopTop = ValueTypeint,
        FightLibId = ValueTypeint,
        EventLibId = ValueTypeint,
        ShopLibId = ValueTypeint,
        RewardProbability = Type1ValueTypeint,
        ItemBoxWeight = Type1ValueTypeint,
        RecruitTicketWeight = Type1ValueTypeint,
        GoldWeight = Type1ValueTypeint,
        ItemBoxGroupId = Type1ValueTypeint,
        RecruitTicketGroupId = Type1ValueTypeint,
        GoldGroupId = Type1ValueTypeint,
    },
    XTableBiancaTheatreNodeShop = {
        Id = ValueTypeintPrimaryKey,
        DiscountNum = ValueTypeint,
        DiscountRate = ValueTypeint,
        GroupId = Type1ValueTypeint,
        ConditionId = Type1ValueTypeint,
        TitleContent = ValueTypestring,
        RoleIcon = ValueTypestring,
        RoleName = ValueTypestring,
        RoleContent = ValueTypestring,
        Desc = ValueTypestring,
        EndDesc = ValueTypestring,
        EndComfirmText = ValueTypestring,
        BgAsset = ValueTypestring,
    },
    XTableBiancaTheatreNodeShopGroup = {
        Id = ValueTypeintPrimaryKey,
        ShopId = ValueTypeint,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
    },
    XTableBiancaTheatreNodeShopItem = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        ItemType = ValueTypeint,
        ItemId = ValueTypeint,
        TicketId = ValueTypeint,
        Weight = ValueTypeint,
        Price = ValueTypeint,
    },
    XTableBiancaTheatreRecruitCharacterGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        CharacterId = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableBiancaTheatreRecruitTicket = {
        Id = ValueTypeintPrimaryKey,
        Quality = ValueTypeint,
        RefreshCount = ValueTypeint,
        RecruitCount = ValueTypeint,
        LeastRecruitCount = ValueTypeint,
        GroupId = Type1ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        IsSpecial = ValueTypeint,
    },
    XTableBiancaTheatreRecruitTicketGroup = {
        Id = ValueTypeintPrimaryKey,
        TicketId = ValueTypeint,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
    },
    XTableBiancaTheatreSettleChapterFactor = {
        Id = ValueTypeintPrimaryKey,
        Count = ValueTypeint,
        Score = ValueTypeint,
    },
    XTableBiancaTheatreSettleFactor = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Factor = ValueTypefloat,
    },
    XTableBiancaTheatreShopNodeClient = {
        Id = ValueTypeintPrimaryKey,
        NodeTypeName = ValueTypestring,
        NodeTypeIcon = ValueTypestring,
        NodeTypeDesc = ValueTypestring,
        SmallIcon = ValueTypestring,
        NodeTypeEffectUrl = ValueTypestring,
    },
    XTableBiancaTheatreStrengthen = {
        Id = ValueTypeintPrimaryKey,
        UnlockPrice = ValueTypeint,
        EffectGroupId = ValueTypeint,
        PreStrengthenIds = Type1ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        GroupId = ValueTypeint,
        ActiveLinesIndex = Type1ValueTypeint,
    },
    XTableBiancaTheatreStrengthenGroup = {
        Id = ValueTypeintPrimaryKey,
        TitleAsset = ValueTypestring,
        LevelAsset = ValueTypestring,
        Name = ValueTypestring,
        PreStrengthenGroupId = ValueTypeint,
    },
    XTableBiancaTheatreSystemEffect = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        ResetType = ValueTypeint,
        Type = ValueTypeint,
        Params = Type1ValueTypefloat,
    },
    XTableBiancaTheatreTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        MainShowOrder = ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTableBiancaTheatreTeam = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        TimeId = ValueTypeint,
        ConditionId = ValueTypeint,
        EffectGroupId = ValueTypeint,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableBiancaTheatreTeamType = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Color = ValueTypestring,
    },
    XTableBiancaTheatreVision = {
        Id = ValueTypeintPrimaryKey,
        Min = ValueTypeint,
        Max = ValueTypeint,
        Name = ValueTypestring,
        EffectGroupId = ValueTypeint,
        Icon = ValueTypestring,
        SoundFilterOpenCueId = ValueTypeint,
        SoundFilterCloseCueId = ValueTypeint,
        DescShakeGroupId = ValueTypeint,
        RecordDescShakeGroupId = ValueTypeint,
    },
    XTableBiancaTheatreVisionChange = {
        Id = ValueTypeintPrimaryKey,
        Change = ValueTypeint,
        GetSoundCueId = ValueTypeint,
        ShowDesc = ValueTypestring,
    },
    XTableBiancaTheatreVisionFactorLevel = {
        Id = ValueTypeintPrimaryKey,
        Min = ValueTypeint,
        Max = ValueTypeint,
    },
    XTableBiancaTheatreVisionTxtShake = {
        Id = ValueTypeintPrimaryKey,
        TxtGroup = ValueTypeint,
        ChapterId = ValueTypeint,
        Txt = ValueTypestring,
        StartIndex = ValueTypeint,
        EndIndex = ValueTypeint,
        HShakeType = ValueTypeint,
        HStrength = ValueTypefloat,
        HSpeed = ValueTypefloat,
        HoriDensity = ValueTypefloat,
        VShakeType = ValueTypeint,
        VStrength = ValueTypefloat,
        VSpeed = ValueTypefloat,
        VDensity = ValueTypefloat,
    },
    XTableBigWorldActivity = {
        Id = ValueTypeintPrimaryKey,
        LevelId = ValueTypeint,
        ModuleId = ValueTypestring,
        Name = ValueTypestring,
        VirtureCamera = ValueTypestring,
        CameraDuration = ValueTypefloat,
        CamDepthOfFieldId = ValueTypeint,
        GoodsGroupId = ValueTypeint,
    },
    XTableBigworldAIMemory = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Index = ValueTypeint,
        Condition = ValueTypeint,
        LockedTitle = ValueTypestring,
        LockedDesc = ValueTypestring,
        UnlockedTitle = ValueTypestring,
        UnlockedDesc = ValueTypestring,
    },
    XTableBigWorldAssetUrl = {
        Name = ValueTypestringPrimaryKey,
        Url = ValueTypestring,
    },
    XTableBigWorldBackpackType = {
        Type = ValueTypeintPrimaryKey,
        Description = ValueTypestring,
        IconUrl = ValueTypestring,
        TagType = ValueTypeint,
        Priority = ValueTypeint,
        IsTabHide = ValueTypebool,
        ItemTypes = Type1ValueTypeint,
    },
    XTableBigWorldCellData = {
        Id = ValueTypestringPrimaryKey,
        Name = ValueTypestring,
        Path = ValueTypestring,
    },
    XTableBigWorldCharacter = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        AttribId = ValueTypeint,
        Condition = ValueTypeint,
        Priority = ValueTypeint,
        IsCommandant = ValueTypebool,
        DefaultFashionId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableBigWorldCharacterUiEffect = {
        Id = ValueTypeintPrimaryKey,
        FashionId = ValueTypeint,
        ActionId = ValueTypestring,
        EffectRootName = ValueTypestring,
        IsIgnoreRotate = ValueTypebool,
        EffectIds = Type1ValueTypestring,
    },
    XTableBigWorldCommonValues = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableBigWorldConfig = {
        Key = ValueTypestringPrimaryKey,
        Type = ValueTypestring,
        Value = ValueTypestring,
    },
    XTableBigWorldCourseContent = {
        ContentId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ContentType = ValueTypeint,
        TaskProgressItemId = ValueTypeint,
        BannerBg = ValueTypestring,
        TaskProgressItemIcon = ValueTypestring,
        ExploreRewardId = ValueTypeint,
        ExploreTitle = ValueTypestring,
        Priority = ValueTypeint,
        ContentTip = ValueTypestring,
        ConditionIds = Type1ValueTypeint,
    },
    XTableBigWorldCourseCore = {
        CoreId = ValueTypeintPrimaryKey,
        ContentId = ValueTypeint,
        GroupId = ValueTypeint,
        Priority = ValueTypeint,
        Name = ValueTypestring,
        LabelImage = ValueTypestring,
        Banner = ValueTypestring,
        SpineBanner = ValueTypestring,
        ConditionId = ValueTypeint,
        ElementIds = Type1ValueTypeint,
    },
    XTableBigWorldCourseCoreElement = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ProgressTitle = ValueTypestring,
        SortIndex = ValueTypeint,
        Background = ValueTypestring,
        TeachId = ValueTypeint,
        DisplayRewardId = ValueTypeint,
        EntryType = ValueTypeint,
        EntryIds = Type1ValueTypeint,
        SkipId = ValueTypeint,
        CustomParamId = ValueTypeint,
        LockSkipIds = Type1ValueTypeint,
        LockSkipConditionIds = Type1ValueTypeint,
        EarlyAccessSkipIds = Type1ValueTypeint,
    },
    XTableBigWorldCourseCoreGroup = {
        GroupId = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Priority = ValueTypeint,
        Name = ValueTypestring,
        LabelImage = ValueTypestring,
    },
    XTableBigWorldCourseExplore = {
        ExploreId = ValueTypeintPrimaryKey,
        ContentId = ValueTypeint,
        Type = ValueTypeint,
        Title = ValueTypestring,
        TeachId = ValueTypeint,
        Banner = ValueTypestring,
        Icon = ValueTypestring,
        Priority = ValueTypeint,
        GuideId = ValueTypeint,
        RewardId = ValueTypeint,
        TimeId = ValueTypeint,
        PoiIds = Type1ValueTypeint,
    },
    XTableBigWorldCourseExplorePoi = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        TotalProgress = ValueTypeint,
        Priority = ValueTypeint,
        SkipId = ValueTypeint,
        CollectionLevelId = ValueTypeint,
        ComputeParams = Type1ValueTypeint,
        ConditionIds = Type1ValueTypeint,
    },
    XTableBigWorldCourseTask = {
        TaskId = ValueTypeintPrimaryKey,
        ContentId = ValueTypeint,
        UnlockType = ValueTypeint,
        UnlockParams = Type1ValueTypeint,
        ConditionId = ValueTypeint,
        UnlockTagConditionId = ValueTypeint,
        Title = ValueTypestring,
        UnlockText = ValueTypestring,
        SkipId = ValueTypeint,
        TimeId = ValueTypeint,
    },
    XTableBigWorldCourseTaskProgressReward = {
        Id = ValueTypeintPrimaryKey,
        ContentId = ValueTypeint,
        Progress = ValueTypeint,
        IsSpecial = ValueTypebool,
        RewardId = ValueTypeint,
    },
    XTableBigWorldCourseVersion = {
        VersionId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ContentIds = Type1ValueTypeint,
        TimeId = ValueTypeint,
        ConditionId = ValueTypeint,
        Priority = ValueTypeint,
        SwitchIcon = ValueTypestring,
    },
    XTableBigWorldCustomParam = {
        Param = ValueTypeintPrimaryKey,
    },
    XTableBigWorldDIYColor = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Priority = ValueTypeint,
        Icon = ValueTypestring,
        MaterialName = ValueTypestring,
    },
    XTableBigWorldDIYColorGroup = {
        GroupId = ValueTypeintPrimaryKey,
        ColorId = Type1ValueTypeint,
    },
    XTableBigWorldDIYOutfit = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        AllowFashionIds = Type1ValueTypeint,
        DefaultPartIds = Type1ValueTypeint,
    },
    XTableBigWorldDIYPart = {
        Id = ValueTypeintPrimaryKey,
        IsSuitPart = ValueTypebool,
        IsPreview = ValueTypebool,
        Name = ValueTypestring,
        Description = ValueTypestring,
        WorldDescription = ValueTypestring,
        ItemIcon = ValueTypestring,
        GoodsIcon = ValueTypestring,
        GoodsName = ValueTypestring,
        ObtainDesc = ValueTypestring,
        Quality = ValueTypeint,
        Priority = ValueTypeint,
        TypeId = ValueTypeint,
        ResId = Type1ValueTypeint,
        ConvertItemId = Type1ValueTypeint,
        ConvertItemCount = Type1ValueTypeint,
        IncompatibleType = Type1ValueTypeint,
        Parts = Type1ValueTypeint,
        IncompatiblePartIds = Type1ValueTypeint,
        SkipID = Type1ValueTypeint,
    },
    XTableBigWorldDIYPartGroup = {
        TypeId = ValueTypeintPrimaryKey,
        PartId = Type1ValueTypeint,
    },
    XTableBigWorldDIYPreview = {
        Id = ValueTypeintPrimaryKey,
        OutfitType = ValueTypeint,
        PreviewParts = Type1ValueTypeint,
        PreviewPartsMaleColor = Type1ValueTypeint,
        PreviewPartsFemaleColor = Type1ValueTypeint,
    },
    XTableBigWorldDIYRes = {
        Id = ValueTypeintPrimaryKey,
        BigIcon = ValueTypestring,
        Icon = ValueTypestring,
        PartModelId = ValueTypestring,
        FashionId = ValueTypeint,
        ColorGroupId = ValueTypeint,
        DefaultColorId = ValueTypeint,
    },
    XTableBigWorldDIYType = {
        TypeId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        IsRequired = ValueTypebool,
        IsFashion = ValueTypebool,
        IsSuit = ValueTypebool,
        DefaultAnimationParam = ValueTypeint,
        EntryAnimationName = ValueTypestring,
    },
    XTableBigWorldFashion = {
        Id = ValueTypeintPrimaryKey,
        UiModelId = ValueTypestring,
        SquareHeadImage = ValueTypestring,
        RoundHeadImage = ValueTypestring,
        AnimExpressionSOGroupId = ValueTypeint,
        UIModelAnimExpressionSOGroupId = ValueTypeint,
        DefaultColor = ValueTypestring,
        FashionColorIds = Type1ValueTypeint,
    },
    XTableBigWorldFashionColor = {
        Id = ValueTypeintPrimaryKey,
        UiModelId = ValueTypestring,
        Priority = ValueTypeint,
        Color = ValueTypestring,
    },
    XTableBigWorldFashionSO = {
        Id = ValueTypeintPrimaryKey,
        AnimateState = ValueTypestring,
        Url = ValueTypestring,
    },
    XTableBigWorldFashionSOGroup = {
        Id = ValueTypeintPrimaryKey,
        BigWorldAnimationExpressionSOIdList = Type1ValueTypeint,
    },
    XTableBigWorldGoods = {
        Id = ValueTypeintPrimaryKey,
        TemplateId = ValueTypeint,
        Count = ValueTypeint,
    },
    XTableBigWorldGoodsGroup = {
        Id = ValueTypeintPrimaryKey,
        IsIgnoreCount = ValueTypebool,
        GoodIds = Type1ValueTypeint,
    },
    XTableBigworldGuideGroup = {
        Id = ValueTypeintPrimaryKey,
        Priority = ValueTypeint,
        SequentialId = ValueTypeint,
        Ignore = ValueTypeint,
        Desc = ValueTypestring,
        GuideType = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        CompleteId = ValueTypeint,
        ActiveUi = ValueTypestring,
        CheckNodeActive = ValueTypestring,
        RewardId = ValueTypeint,
        GroupId = ValueTypeint,
    },
    XTableBigWorldHelpCourse = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Priority = ValueTypeint,
        Name = ValueTypestring,
        IsPause = ValueTypebool,
        IsForce = ValueTypebool,
        IsHide = ValueTypebool,
    },
    XTableBigWorldHelpCourseDetail = {
        Id = ValueTypeintPrimaryKey,
        HelpCourseId = ValueTypeint,
        Index = ValueTypeint,
        Name = ValueTypestring,
        Image = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableBigWorldHelpCourseGroup = {
        Id = ValueTypeintPrimaryKey,
        Priority = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableBigWorldHelpCourseUnlockTrigger = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        HelpCourseId = ValueTypeint,
        TargetId = ValueTypeint,
    },
    XTableBigWorldLevelFovSave = {
        Id = ValueTypeintPrimaryKey,
        FovGroupId = ValueTypeint,
    },
    XTableBigWorldLoading = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        ImageUrl = ValueTypestring,
        Weight = ValueTypeint,
        ConditionIds = Type1ValueTypeint,
    },
    XTableBigWorldLoadingGroup = {
        GroupId = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        LoadingIds = Type1ValueTypeint,
    },
    XTableBigWorldMap = {
        LevelId = ValueTypeintPrimaryKey,
        ConditionId = ValueTypeint,
        SortIndex = ValueTypeint,
        PosX = ValueTypefloat,
        PosZ = ValueTypefloat,
        PixelRatio = ValueTypeint,
        Width = ValueTypeint,
        Height = ValueTypeint,
        AreaGroupType = ValueTypeint,
        MapName = ValueTypestring,
        BaseImage = ValueTypestring,
        LittleMapScale = ValueTypefloat,
        MaxScale = ValueTypefloat,
        MinScale = ValueTypefloat,
        DefaultScale = ValueTypefloat,
        OverviewId = ValueTypeint,
        AreaGroupIds = Type1ValueTypeint,
    },
    XTableBigWorldMapArea = {
        AreaId = ValueTypeintPrimaryKey,
        PosX = ValueTypefloat,
        PosZ = ValueTypefloat,
        PixelRatio = ValueTypeint,
        AreaName = ValueTypestring,
        AreaImage = ValueTypestring,
        GroupId = ValueTypeint,
    },
    XTableBigWorldMapAreaGroup = {
        GroupId = ValueTypeintPrimaryKey,
        FloorIndex = ValueTypeint,
        GroupName = ValueTypestring,
        Icon = ValueTypestring,
        AreaIds = Type1ValueTypeint,
    },
    XTableBigWorldMapLink = {
        LevelId = ValueTypeintPrimaryKey,
        LinkWorldId = ValueTypeint,
        LinkLevelId = ValueTypeint,
        BindPinId = ValueTypeint,
    },
    XTableBigWorldMapOverview = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        PosX = ValueTypeint,
        PosY = ValueTypeint,
        Prefab = ValueTypestring,
        Background = ValueTypestring,
    },
    XTableBigWorldMapPinStyle = {
        StyleId = ValueTypeintPrimaryKey,
        ActiveIcon = ValueTypestring,
        UnActiveIcon = ValueTypestring,
        BriefIcon = ValueTypestring,
        AreaColor = ValueTypestring,
        SecondIcon = ValueTypestring,
    },
    XTableBigWorldMapQuestPin = {
        QuestType = ValueTypeintPrimaryKey,
        StyleId = ValueTypeint,
        SecondStyleId = ValueTypeint,
        ReadyStyleId = ValueTypeint,
    },
    XTableBigWorldMessage = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        OpenType = ValueTypeint,
        ContactsId = ValueTypeint,
        IsMultiple = ValueTypebool,
        Priority = ValueTypeint,
        RewardId = ValueTypeint,
        AwardId = ValueTypeint,
        FirstStepId = ValueTypeint,
        QuestId = ValueTypeint,
        ConditionIds = Type1ValueTypeint,
    },
    XTableBigWorldMessageContacts = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Text = ValueTypestring,
        ConditionIds = Type1ValueTypeint,
        Names = Type1ValueTypestring,
        Icons = Type1ValueTypestring,
        Texts = Type1ValueTypestring,
    },
    XTableBigWorldMessageIcon = {
        Key = ValueTypestringPrimaryKey,
        Icon = ValueTypestring,
    },
    XTableBigWorldMessageStep = {
        Id = ValueTypeintPrimaryKey,
        MessageId = ValueTypeint,
        StepId = ValueTypeint,
        Duration = ValueTypefloat,
        IsCanSkip = ValueTypebool,
        IsEndStep = ValueTypebool,
        Type = ValueTypeint,
        SpeakerId = ValueTypeint,
        Emoji = ValueTypestring,
        VideoImage = ValueTypestring,
        VideoId = ValueTypeint,
        PhotoRefId = ValueTypeint,
        Image = ValueTypestring,
        Text = Type1ValueTypestring,
        NextStep = Type1ValueTypeint,
    },
    XTableBigWorldNarrativeText = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Title = ValueTypestring,
        Content = ValueTypestring,
        AssetUrl = ValueTypestring,
        Alignment = ValueTypeint,
        Signature = ValueTypestring,
    },
    XTableBigWorldNews = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Title = ValueTypestring,
        Content = ValueTypestring,
        Priority = ValueTypeint,
        ShowReward = ValueTypeint,
        ShowTimeId = ValueTypeint,
        ShowCountDown = ValueTypeint,
        ShowTimeRewardTitle = ValueTypestring,
        ShowTimeRewardContent = ValueTypestring,
        ShowTimeRewardTip = ValueTypestring,
        TagHideCondition = ValueTypeint,
        UnlockCondition = ValueTypeint,
        PopupCondition = ValueTypeint,
        EarlyAccessCondition = ValueTypeint,
        SpineBanner = ValueTypestring,
        BgPic = ValueTypestring,
        SkipId = ValueTypeint,
        RewardShowSkipId = ValueTypeint,
        TaskGroupId = ValueTypeint,
        TextDialogId = ValueTypeint,
        IsSpecial = ValueTypebool,
        CustomParamId = ValueTypeint,
        EarlyAccessTextDialogId = ValueTypeint,
        EarlyAccessSkipIds = Type1ValueTypeint,
        Params = Type1ValueTypeint,
        PreConditions = Type1ValueTypeint,
        PreSkipIds = Type1ValueTypeint,
    },
    XTableBigWorldOpenFunctionMain = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        UiName = ValueTypestring,
        World = ValueTypeint,
        Level = ValueTypeint,
        Pin = ValueTypeint,
        OpenFuncControl = ValueTypeint,
    },
    XTableBigWorldOpenGuide = {
        Id = ValueTypeintPrimaryKey,
        SysModuleId = ValueTypeint,
        StepIndex = ValueTypeint,
        ActionType = ValueTypeint,
        VideoConfigId = ValueTypeint,
        ActionParams = Type1ValueTypeint,
    },
    XTableBigWorldPhotographActions = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        AnimationName = ValueTypestring,
        Name = ValueTypestring,
        ObtainType = ValueTypeint,
        ConditionIds = Type1ValueTypeint,
        IsPreview = ValueTypebool,
        ConvertItemId = Type1ValueTypeint,
        ConvertItemCount = Type1ValueTypeint,
        Icon = ValueTypestring,
        SmallIcon = ValueTypestring,
        Desc = ValueTypestring,
        WorldDesc = ValueTypestring,
        Priority = ValueTypeint,
        LockDesc = ValueTypestring,
    },
    XTableBigWorldPhotographCharacterActions = {
        Id = ValueTypeintPrimaryKey,
        ActionId = Type1ValueTypeint,
    },
    XTableBigWorldPhotographFilters = {
        Id = ValueTypeintPrimaryKey,
        FilterId = ValueTypeint,
        Name = ValueTypestring,
        ObtainType = ValueTypeint,
        ConditionIds = Type1ValueTypeint,
        Image = ValueTypestring,
        IsPreview = ValueTypebool,
        ConvertItemId = Type1ValueTypeint,
        ConvertItemCount = Type1ValueTypeint,
        Icon = ValueTypestring,
        SmallIcon = ValueTypestring,
        Desc = ValueTypestring,
        WorldDesc = ValueTypestring,
        Priority = ValueTypeint,
        LockDesc = ValueTypestring,
    },
    XTableBigWorldPhotographFunctionalUnlock = {
        Id = ValueTypeintPrimaryKey,
        ConditionId = ValueTypeint,
    },
    XTableBigWorldPhotographNpcDetectBone = {
        Id = ValueTypeintPrimaryKey,
        BodyShape = ValueTypeint,
        Animation = ValueTypestring,
        Bone = ValueTypestring,
    },
    XTableBigWorldPhotographParams = {
        Id = ValueTypeintPrimaryKey,
        HideClose = ValueTypebool,
        HideMenu = ValueTypebool,
        HideNpc = ValueTypebool,
        HideChar = ValueTypebool,
        HideAlbum = ValueTypebool,
        HideCharRotate = ValueTypebool,
        HideReset = ValueTypebool,
        HidePersonSwitch = ValueTypebool,
        InitCharRotate = ValueTypefloat,
        DisableCameraOperation = ValueTypebool,
        UseInitCameraZoom = ValueTypebool,
        InitCameraZoom = ValueTypefloat,
        HideCameraMove = ValueTypebool,
        UseInitCameraMove = ValueTypebool,
        InitCameraMoveX = ValueTypefloat,
        InitCameraMoveY = ValueTypefloat,
        InitLookAtCamera = ValueTypebool,
        ResetCameraHeight = ValueTypebool,
        UseInitCameraY = ValueTypebool,
        InitCameraY = ValueTypefloat,
        MinDistance = ValueTypefloat,
        MaxDistance = ValueTypefloat,
        WidthDetectionRatio = ValueTypefloat,
        HeightDetectionRatio = ValueTypefloat,
        FailTimes = ValueTypeint,
        MinFov = ValueTypefloat,
        MaxFov = ValueTypefloat,
        ThirdPersonMode = ValueTypeint,
        MoveSpeed = ValueTypefloat,
        DofId = ValueTypeint,
        MinBlurSize = ValueTypefloat,
        MaxBlurSize = ValueTypefloat,
    },
    XTableBigWorldPopupUi = {
        UiName = ValueTypestringPrimaryKey,
        IsModality = ValueTypebool,
        Priority = ValueTypeint,
        CustomModalityParams = Type1ValueTypestring,
        SpecificModalityUi = Type1ValueTypestring,
    },
    XTableBigWorldRewardGoodDetails = {
        Id = ValueTypeintPrimaryKey,
        DisplayType = ValueTypeint,
        DataType = ValueTypeint,
    },
    XTableBigWorldSettle = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Theme = ValueTypeint,
        UiName = ValueTypestring,
    },
    XTableBigWorldSetType = {
        Type = ValueTypeintPrimaryKey,
        TypeName = ValueTypestring,
        Priority = ValueTypeint,
        Icon = ValueTypestring,
        UiName = ValueTypestring,
        PcUiName = ValueTypestring,
    },
    XTableBigWorldShowInputMap = {
        Id = ValueTypeintPrimaryKey,
        InputMapId = Type1ValueTypeint,
    },
    XTableBigWorldSkipFunction = {
        Id = ValueTypeintPrimaryKey,
        SkipName = ValueTypestring,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        ConditionId = ValueTypeint,
        FinishConditionId = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableBigWorldSysModule = {
        WorldId = ValueTypeintPrimaryKey,
        SysModuleId = ValueTypeint,
    },
    XTableBigWorldText = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypestring,
    },
    XTableBigWorldTextDialog = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Content = ValueTypestring,
    },
    XTableBigWorldUi = {
        UiName = ValueTypestringPrimaryKey,
        IsPauseFight = ValueTypebool,
        IsChangeInput = ValueTypebool,
        IsQueue = ValueTypebool,
        IsHideFightUi = ValueTypebool,
        IsCloseCameraControl = ValueTypebool,
        IsVirtual = ValueTypebool,
        ImpactIds = Type1ValueTypeint,
    },
    XTableBigWorldUiEffect = {
        Id = ValueTypeintPrimaryKey,
        EffectUrl = ValueTypestring,
        DelayTime = ValueTypeint,
    },
    XTableBigWorldUiImpact = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypestring,
    },
    XTableBigWorldUiModel = {
        Id = ValueTypestringPrimaryKey,
        ModelId = ValueTypestring,
        DefaultAnimationName = ValueTypestring,
        DisplayControllerPath = ValueTypestring,
    },
    XTableBigWorldUiModelNodeControl = {
        Id = ValueTypeintPrimaryKey,
        AnimationName = ValueTypestring,
        ModelId = ValueTypestring,
        HideNodes = Type1ValueTypestring,
        ShowNodes = Type1ValueTypestring,
    },
    XTableBigWorldUiTheme = {
        Id = ValueTypeintPrimaryKey,
        Color = Type1ValueTypestring,
        FxColor = Type1ValueTypestring,
        ImageUrl = Type1ValueTypestring,
        RawImageUrl = Type1ValueTypestring,
        EffectUrl = Type1ValueTypestring,
    },
    XTableBirthdayPeriod = {
        Id = ValueTypeint,
        StoryChapterId = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MailId = ValueTypeint,
        IsSingleStory = ValueTypeint,
    },
    XTableBirthdayPlot = {
        StoryChapterId = ValueTypeintPrimaryKey,
        MailId = ValueTypeint,
        TimeId = ValueTypeint,
    },
    XTableBirthdayPlotCovert = {
        Id = ValueTypeintPrimaryKey,
        BeginTime = ValueTypestring,
        EndTime = ValueTypestring,
        CovertToMonth = ValueTypeint,
        CovertToDay = ValueTypeint,
    },
    XTableBlackRockChessActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ShopReminderTimeId = ValueTypeint,
        Name = ValueTypestring,
        Chapters = Type1ValueTypeint,
        MaxEnergy = ValueTypeint,
        RoundEnergyAdd = ValueTypeint,
        KillEnergyAdd = ValueTypeint,
        MaxPartnerCount = ValueTypeint,
        ShopIds = Type1ValueTypeint,
        CurrencyIds = Type1ValueTypeint,
    },
    XTableBlackRockChessArchive = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        ArchiveType = ValueTypeint,
        StoryId = ValueTypestring,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Condition = ValueTypeint,
        UnlockTip = ValueTypestring,
        ArchiveTitle = ValueTypestring,
        ArchiveDesc = ValueTypestring,
    },
    XTableBlackRockChessArchiveType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableBlackRockChessBuff = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        TargetType = Type1ValueTypeint,
        Params = Type1ValueTypeint,
        RoundDuration = ValueTypeint,
        NodeDuration = ValueTypeint,
        MaxOverlays = ValueTypeint,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Condition = ValueTypeint,
        EffectId = ValueTypeint,
    },
    XTableBlackRockChessChapter = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        Type = ValueTypeint,
        StageIds = Type1ValueTypeint,
        Condition = ValueTypeint,
        IsRank = ValueTypebool,
    },
    XTableBlackRockChessCharacter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        MoveType = ValueTypeint,
        Type = ValueTypeint,
        WeaponIds = Type1ValueTypeint,
        WeaponConditions = Type1ValueTypeint,
        SkillIds = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
        DefaultWeapon = ValueTypeint,
        MaxLife = ValueTypeint,
        ModelUrl = ValueTypestring,
        ControllerUrl = ValueTypestring,
        CircleIcon = ValueTypestring,
        RectIcon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableBlackRockChessCharacterSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        RoundDuration = ValueTypeint,
        Icon = ValueTypestring,
        Params = Type1ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableBlackRockChessCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Desc = ValueTypestring,
        Params = Type1ValueTypeint,
    },
    XTableBlackRockChessConfig = {
        Key = ValueTypestringPrimaryKey,
        Note = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableBlackRockChessEffect = {
        Id = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        EffectPrefab = ValueTypestring,
        Offset = ValueTypestring,
        Rotate = ValueTypestring,
        Scale = ValueTypestring,
        IsDirection = ValueTypeint,
        InitAngle = ValueTypefloat,
    },
    XTableBlackRockChessFightNode = {
        Id = ValueTypeintPrimaryKey,
        LayoutId = ValueTypeint,
        ChessBoardType = ValueTypeint,
        ReinforceIds = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
        DisplayBuffIds = Type1ValueTypeint,
        ShopId = ValueTypeint,
        TargetCondition = ValueTypeint,
        UnlockSkillIds = Type1ValueTypeint,
        NodeScore = ValueTypeint,
        Coin = ValueTypeint,
        PartnerPieceLimit = ValueTypeint,
        PartnerAddEnergy = ValueTypeint,
        Name = ValueTypestring,
        NodeType = ValueTypeint,
        Icon = Type1ValueTypestring,
        Desc = ValueTypestring,
        ScenePrefab = ValueTypestring,
    },
    XTableBlackRockChessHandbook = {
        Id = ValueTypeintPrimaryKey,
        HandbookType = ValueTypeint,
        Param = ValueTypeint,
        HeadIcon = ValueTypestring,
        Hp = ValueTypeint,
        Interval = ValueTypeint,
        Desc = ValueTypestring,
        MoveMapIcon = ValueTypestring,
        Condition = ValueTypeint,
        UnlockDesc = ValueTypestring,
        Name = ValueTypestring,
    },
    XTableBlackRockChessLayout = {
        Id = ValueTypeintPrimaryKey,
        LayoutId = ValueTypeint,
        Member = ValueTypeint,
        Type = ValueTypeint,
        X = ValueTypeint,
        Y = ValueTypeint,
    },
    XTableBlackRockChessNodeGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        NodeId = ValueTypeint,
    },
    XTableBlackRockChessPartnerPiece = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Level = ValueTypeint,
        MaxLife = ValueTypeint,
        InitMoveCd = ValueTypeint,
        MoveCd = ValueTypeint,
        BornCd = ValueTypeint,
        PromotionPieces = Type1ValueTypeint,
        OriginalPiece = ValueTypeint,
        AtkLife = ValueTypeint,
        RecyclePrice = ValueTypeint,
        CharacterBuffIds = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
        AvoidBuffIds = Type1ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Note = ValueTypestring,
        Prefab = ValueTypestring,
        HeadIcon = ValueTypestring,
        EffectIcon = ValueTypestring,
        EffectDesc = ValueTypestring,
    },
    XTableBlackRockChessPiece = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        MaxLife = ValueTypeint,
        InitMoveCd = ValueTypeint,
        MoveCd = ValueTypeint,
        PromotionPiece = ValueTypeint,
        TransPartnerPiece = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        AtkLife = ValueTypeint,
        Desc = ValueTypestring,
        Note = ValueTypestring,
        Prefab = ValueTypestring,
        HeadIcon = ValueTypestring,
    },
    XTableBlackRockChessReinforce = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Condition = ValueTypeint,
        TriggerCd = ValueTypeint,
        PreviewCd = ValueTypeint,
        SummonCount = ValueTypeint,
        Range = ValueTypeint,
        Locations = Type1ValueTypestring,
        PieceIds = Type1ValueTypeint,
    },
    XTableBlackRockChessReviveBuff = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        ReviveCount = ValueTypeint,
        BuffIds = Type1ValueTypeint,
    },
    XTableBlackRockChessShop = {
        Id = ValueTypeintPrimaryKey,
        GoodsGroupId = Type1ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        RefreshLimit = ValueTypeint,
        RefreshCost = ValueTypeint,
    },
    XTableBlackRockChessShopGoods = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        GoodsType = ValueTypeint,
        GoodsId = ValueTypeint,
        GoodsNum = ValueTypeint,
        Price = ValueTypeint,
        Weight = ValueTypeint,
        GoodsLimit = ValueTypeint,
    },
    XTableBlackRockChessStage = {
        Id = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
        NodeGroups = Type1ValueTypeint,
        DisplayBuffIds = Type1ValueTypeint,
        InitEnergy = ValueTypeint,
        ReviveCount = ValueTypeint,
        MinGuaranteeReviveCount = ValueTypeint,
        ReviveBuffGroupId = ValueTypeint,
        FirstPassRewardId = ValueTypeint,
        FirstPassWeaponId = ValueTypeint,
        FirstPassSkillId = ValueTypeint,
        FirstPassBuffIds = Type1ValueTypeint,
        StarRewardTemplateId = ValueTypeint,
        RetractTimes = ValueTypeint,
        SettleItemFactor = ValueTypeint,
        MaxSettleItem = ValueTypeint,
        RoundScore = ValueTypeint,
        ReviveScore = ValueTypeint,
        KillScore = ValueTypeint,
        Version = ValueTypeint,
        StageIcon = ValueTypestring,
        Name = ValueTypestring,
        TargetDesc = Type1ValueTypestring,
        HelpKey = ValueTypestring,
        EnterStoryId = ValueTypestring,
        ExitStoryId = ValueTypestring,
        EnterCommunicationId = ValueTypeint,
        ExitCommunicationId = ValueTypeint,
        ShowIcon = ValueTypestring,
        ShowBossId = Type1ValueTypeint,
        ShowBossIcon = Type1ValueTypestring,
    },
    XTableBlackRockChessStarReward = {
        Id = ValueTypeintPrimaryKey,
        TemplateId = ValueTypeint,
        Conditions = Type1ValueTypeint,
        Star = ValueTypeint,
        RewardId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableBlackRockChessWeapon = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Step = ValueTypeint,
        IsPenetrate = ValueTypebool,
        SkillIds = Type1ValueTypeint,
        Icon = ValueTypestring,
        CircleIcon = ValueTypestring,
        ModelUrl = ValueTypestring,
        ControllerUrl = ValueTypestring,
        Desc = ValueTypestring,
        Desc2 = ValueTypestring,
        MapIcon = ValueTypestring,
        MapIcon2 = ValueTypestring,
        UnlockDesc = ValueTypestring,
    },
    XTableBlackRockChessWeaponSkill = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Cost = ValueTypeint,
        Range = ValueTypeint,
        IsDefault = ValueTypebool,
        IsPassive = ValueTypebool,
        IsDizzy = ValueTypebool,
        IsPenetrate = ValueTypebool,
        DelayRound = ValueTypeint,
        Params = Type1ValueTypeint,
        Desc = ValueTypestring,
        Desc2 = ValueTypestring,
        Name = ValueTypestring,
        Name2 = ValueTypestring,
        Icon = ValueTypestring,
        CircleIcon = ValueTypestring,
        MapIcon = ValueTypestring,
        MapIcon2 = ValueTypestring,
        UnlockDesc = ValueTypestring,
        HitEffectId = Type1ValueTypeint,
        AssistHitEffectId = Type1ValueTypeint,
        IconBg = ValueTypestring,
    },
    XTableBlackRockChessWeaponSkillCd = {
        Id = ValueTypeintPrimaryKey,
        InitCd = ValueTypeint,
        Cd = ValueTypeint,
        SkillIds = Type1ValueTypeint,
    },
    XTableBoardEffectActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        TriggerProbability = ValueTypeint,
        TriggerCd = ValueTypeint,
        EffectRootNames = Type2KeyTypeintValueTypestring,
        EffectPaths = Type1ValueTypestring,
        EffectTimes = Type1ValueTypeint,
    },
    XTableBodyCombineGameActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MatchColCount = ValueTypeint,
        ActivityTitle = ValueTypestring,
        FinishBanner = ValueTypestring,
    },
    XTableBodyCombineGameSmallIcon = {
        Id = ValueTypeintPrimaryKey,
        Path = ValueTypestring,
        BodyType = ValueTypeint,
    },
    XTableBodyCombineGameStage = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        StageId = ValueTypeint,
        PreStage = ValueTypeint,
        CostCount = ValueTypeint,
        ColPictures = Type1ValueTypeint,
        ScrollPictures = Type1ValueTypeint,
        Desc = ValueTypestring,
        QuestionDescs = Type1ValueTypestring,
        SuspectIcon = ValueTypestring,
        PassDesc = ValueTypestring,
        OpenBanner = ValueTypestring,
        FinishBanner = ValueTypestring,
        WinnerQIcon = ValueTypestring,
    },
    XTableBoneOffset = {
        Role = ValueTypestring,
        Animation = ValueTypestring,
        Bone = ValueTypestring,
        Layer = ValueTypeint,
        OffsetX = Type1ValueTypefix,
        OffsetY = Type1ValueTypefix,
        OffsetZ = Type1ValueTypefix,
        Cos = Type1ValueTypefix,
        Sin = Type1ValueTypefix,
    },
    XTableBossActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ActivityTimeId = ValueTypeint,
        FightTimeId = ValueTypeint,
        PrefabAddress = ValueTypestring,
        CustomUiScripts = ValueTypestring,
        DifficultyScaleStages = Type1ValueTypeint,
    },
    XTableBossActivityStory = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        PreStageId = ValueTypeint,
        Name = ValueTypestring,
        MovieId = ValueTypestring,
        Bg = ValueTypestring,
    },
    XTableBossChallenge = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        StageDetailTitle = ValueTypestring,
        StageAttention = Type1ValueTypestring,
        StageAttentionTitle = Type1ValueTypestring,
        EffectPath = ValueTypestring,
        CharacterCount = ValueTypeint,
    },
    XTableBossChallengeRes = {
        Id = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        BgPath = ValueTypestring,
        EffectPath = ValueTypestring,
    },
    XTableBossInshotActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        BossIds = Type1ValueTypeint,
        CharacterIds = Type1ValueTypeint,
        TeachStageId = ValueTypeint,
        TaskGroupIds = Type1ValueTypeint,
        PreviewTaskRewardId = ValueTypeint,
        PositionNum = ValueTypeint,
        IsRank = ValueTypebool,
        IsTowerRank = ValueTypebool,
        TowerMaxScoreLimit = ValueTypeint,
        TowerBossIds = Type1ValueTypeint,
        TowerConditions = Type1ValueTypeint,
    },
    XTableBossInshotBoss = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ModelId = ValueTypestring,
        HeadIcon = ValueTypestring,
        SkillIds = Type1ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        OpenTimeId = ValueTypeint,
    },
    XTableBossInshotCharacter = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        RobotId = ValueTypeint,
        MarkEffectName = ValueTypestring,
        FightEventIds = Type1ValueTypeint,
    },
    XTableBossInshotScore = {
        Id = ValueTypeintPrimaryKey,
        Score = ValueTypeint,
        Type = ValueTypeint,
        Desc = ValueTypestring,
        Order = ValueTypeint,
        TipsDesc = ValueTypestring,
        TipsScore = ValueTypestring,
    },
    XTableBossInshotScoreLevel = {
        Id = ValueTypeintPrimaryKey,
        MinScores = Type1ValueTypeint,
        MaxScores = Type1ValueTypeint,
        TowerMinScore = Type1ValueTypeint,
        TowerMaxScore = Type1ValueTypeint,
        LevelName = ValueTypestring,
        LevelIcon = ValueTypestring,
        BalanceIcon = ValueTypestring,
        EffectName = ValueTypestring,
    },
    XTableBossInshotSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Tips = ValueTypestring,
        Desc = ValueTypestring,
        VideoUrl = ValueTypestring,
        PracticeStageId = ValueTypeint,
        FightEventId = ValueTypeint,
    },
    XTableBossInshotStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Difficulty = ValueTypeint,
        IsPractice = ValueTypeint,
        UnlockConditionId = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        StageId = ValueTypeint,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        BossId = ValueTypeint,
    },
    XTableBossInshotTalent = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        TalentType = ValueTypeint,
        UnlockConditionId = ValueTypeint,
        FightEventId = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableBossInshotTower = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        PassScore = ValueTypeint,
        Stages = Type1ValueTypeint,
        Weight = Type1ValueTypeint,
        RepeatWeight = Type1ValueTypeint,
        SelectNum = ValueTypeint,
        FailReBackToId = ValueTypeint,
        Type = ValueTypeint,
        ProtectCount = ValueTypeint,
    },
    XTableBossInshotTowerStage = {
        StageId = ValueTypeintPrimaryKey,
        BossId = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
    },
    XTableBossOnlineActivity = {
        Id = ValueTypeint,
        BeginTimeStr = Type1ValueTypestring,
        EndTimeStr = Type1ValueTypestring,
    },
    XTableBossOnlineChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableBossOnlineInvite = {
        Id = ValueTypeintPrimaryKey,
        UiName = ValueTypestring,
    },
    XTableBossOnlineOpenTime = {
        Id = ValueTypeintPrimaryKey,
        BeginTime = ValueTypestring,
        EndTime = ValueTypestring,
    },
    XTableBossOnlineRisk = {
        Id = ValueTypeintPrimaryKey,
        MinCount = ValueTypeint,
        MaxCount = ValueTypeint,
        Name = ValueTypestring,
        Color = ValueTypestring,
    },
    XTableBossOnlineSection = {
        Id = ValueTypeintPrimaryKey,
        LastSectionId = ValueTypeint,
        Activity = ValueTypeint,
        Weight = ValueTypeint,
        DifficultType = ValueTypeint,
        ModelId = ValueTypestring,
        StageId = ValueTypeint,
        Animation = ValueTypestring,
        Scene = ValueTypestring,
        NpcPic = ValueTypestring,
        CameraSetting = Type1ValueTypestring,
        Description = Type1ValueTypestring,
        SkillName = Type1ValueTypestring,
        SkillDes = Type1ValueTypestring,
    },
    XTableBossRobotGroup = {
        Id = ValueTypeintPrimaryKey,
        RobotId = Type1ValueTypeint,
    },
    XTableBossScoreLevel = {
        Id = ValueTypeintPrimaryKey,
        Des = ValueTypestring,
        MinScore = ValueTypeint,
        MaxScore = ValueTypeint,
        ScoreRatio = ValueTypeint,
    },
    XTableBossScoreTime = {
        Id = ValueTypeintPrimaryKey,
        MinTimeCost = ValueTypeint,
        MaxTimeCost = ValueTypeint,
        ScoreRatio = ValueTypeint,
    },
    XTableBossSection = {
        Id = ValueTypeintPrimaryKey,
        OrderId = ValueTypestring,
        Name = ValueTypestring,
        ChapterName = ValueTypestring,
        Description = ValueTypestring,
        Cover = ValueTypestring,
        Icon = ValueTypestring,
        Prefab = ValueTypestring,
        MinLevel = ValueTypeint,
        MaxLevel = ValueTypeint,
        ShowRewardId = ValueTypeint,
        SkipId = ValueTypeint,
        ChallengeId = Type1ValueTypeint,
        StarRewardId = Type1ValueTypeint,
        StoryId = Type1ValueTypeint,
        ActivityId = ValueTypeint,
        UiName = ValueTypestring,
    },
    XTableBossSingleChallengeBuffGroup = {
        Id = ValueTypeintPrimaryKey,
        BuffGroupId = ValueTypeint,
        Index = ValueTypeint,
        Buff = Type1ValueTypeint,
        IndexName = ValueTypestring,
    },
    XTableBossSingleChallengeBuffGroupIndex = {
        BuffGroupId = ValueTypeintPrimaryKey,
        Index = Type1ValueTypeint,
    },
    XTableBossSingleChallengeDistribute = {
        Id = ValueTypeintPrimaryKey,
        GroupDistributeId = Type1ValueTypeint,
    },
    XTableBossSingleChallengeFeature = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        TriangleBg = ValueTypestring,
        Desc = ValueTypestring,
        FightEventIds = Type1ValueTypeint,
        ShowRecommendIds = Type1ValueTypeint,
        Type = ValueTypeint,
        ScoreRate = ValueTypeint,
    },
    XTableBossSingleChallengeFeatureGroup = {
        Id = ValueTypeintPrimaryKey,
        FeatureIds = Type1ValueTypeint,
        BuffGroupIds = Type1ValueTypeint,
    },
    XTableBossSingleChallengeGrade = {
        LevelType = ValueTypeintPrimaryKey,
        GradeType = ValueTypeint,
        NeedGradeType = ValueTypeint,
        NeedScore = ValueTypeint,
        LevelName = ValueTypestring,
        LevelIcon = ValueTypestring,
        BaseRankNum = ValueTypeint,
        DistributeId = ValueTypeint,
        RankTimeId = ValueTypeint,
        BossGroupId = ValueTypeint,
        RewardGroupId = ValueTypeint,
        RankStageNum = ValueTypeint,
    },
    XTableBossSingleChallengeGroupDistribute = {
        Id = ValueTypeintPrimaryKey,
        SectionUniqueId = ValueTypeint,
        FeatureGroupId = ValueTypeint,
    },
    XTableBossSingleDistribute = {
        Id = ValueTypeintPrimaryKey,
        GroupDistributeId = Type1ValueTypeint,
    },
    XTableBossSingleEtcdConfig = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypeint,
    },
    XTableBossSingleGrade = {
        LevelType = ValueTypeintPrimaryKey,
        GradeType = ValueTypeint,
        Offline = ValueTypeint,
        MinPlayerLevel = ValueTypeint,
        MaxPlayerLevel = ValueTypeint,
        PreGradeType = ValueTypeint,
        NeedScore = ValueTypeint,
        Icon = ValueTypestring,
        LevelName = ValueTypestring,
        HideBossOpen = ValueTypebool,
        ChallengeCount = ValueTypeint,
        WeekChallengeCount = ValueTypeint,
        StaminaCount = ValueTypeint,
        BaseRankNum = ValueTypeint,
        DistributeId = ValueTypeint,
        GroupId = Type1ValueTypeint,
        RankTimeId = ValueTypeint,
        RewardGroupId = ValueTypeint,
        AfreshId = ValueTypeint,
        IsBossGalleryEnabled = ValueTypebool,
        InheritLevelType = ValueTypeint,
    },
    XTableBossSingleGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupIcon = ValueTypestring,
        GroupName = ValueTypestring,
        SectionId = Type1ValueTypeint,
    },
    XTableBossSingleGroupDistribute = {
        Id = ValueTypeintPrimaryKey,
        SectionId = Type1ValueTypeint,
    },
    XTableBossSingleRankReward = {
        Id = ValueTypeintPrimaryKey,
        LevelType = ValueTypeint,
        MinRank = ValueTypefloat,
        MaxRank = ValueTypefloat,
        MailID = ValueTypeint,
        RankIcon = ValueTypestring,
        RewardGroupId = ValueTypeint,
    },
    XTableBossSingleReplay = {
        Key = ValueTypestringPrimaryKey,
        Ids = Type1ValueTypeint,
    },
    XTableBossSingleScoreReward = {
        Id = ValueTypeintPrimaryKey,
        LevelType = ValueTypeint,
        Score = ValueTypeint,
        RewardId = ValueTypeint,
        RankIcon = ValueTypestring,
        RewardGroupId = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableBossSingleScoreRule = {
        Id = ValueTypeintPrimaryKey,
        BaseScore = ValueTypeint,
        BossLoseHp = Type1ValueTypefloat,
        BossLoseHpScore = Type1ValueTypeint,
        BossTotalHp = Type1ValueTypeint,
        LeftTime = Type1ValueTypeint,
        LeftTimeScore = Type1ValueTypefloat,
        CharLeftHp = Type1ValueTypefloat,
        CharLeftHpSocre = Type1ValueTypefloat,
    },
    XTableBossSingleSection = {
        Id = ValueTypeintPrimaryKey,
        SectionId = ValueTypeint,
        Desc = ValueTypestring,
        BossHeadIcon = ValueTypestring,
        BossRankIcon = ValueTypestring,
        UnlockChallengeBannerImage = ValueTypestring,
        Priority = ValueTypeint,
        StageId = Type1ValueTypeint,
        ActivityTag = Type1ValueTypestring,
        TeamBuffId = ValueTypeint,
        ActivityTimeId = Type1ValueTypeint,
        SwitchTimeId = ValueTypeint,
        AfreshId = ValueTypeint,
        AchievementTasks = Type1ValueTypeint,
    },
    XTableBossSingleStage = {
        StageId = ValueTypeintPrimaryKey,
        ModelId = ValueTypestring,
        BossName = ValueTypestring,
        Score = ValueTypeint,
        BossLoseHpScore = ValueTypeint,
        LeftTimeScore = ValueTypeint,
        LeftHpScore = ValueTypeint,
        DifficultyType = ValueTypeint,
        DifficultyDesc = ValueTypestring,
        DifficultyDescEn = ValueTypestring,
        AutoFight = ValueTypebool,
        FightCharCount = ValueTypeint,
        PreFullScore = Type1ValueTypeint,
        OpenCondition = Type1ValueTypeint,
        BuffDetailsId = Type1ValueTypeint,
        FeaturesId = Type1ValueTypeint,
        ProposedLevel = Type1ValueTypeint,
        SkillTitle = Type1ValueTypestring,
        SkillDesc = Type1ValueTypestring,
        AttackName = Type1ValueTypestring,
    },
    XTableBossSingleTrialGrade = {
        LevelType = ValueTypeintPrimaryKey,
        LevelName = ValueTypestring,
        IsBestiaryCfg = ValueTypebool,
        SectionId = Type1ValueTypeint,
        Order = Type1ValueTypeint,
    },
    XTableBossStarReward = {
        Id = ValueTypeintPrimaryKey,
        RequireStar = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableBountyChallengeActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        ShownRewardId = ValueTypeint,
        MonsterIdList = Type1ValueTypeint,
    },
    XTableBountyChallengeCharacterGroup = {
        Id = ValueTypeintPrimaryKey,
        CharacterIdList = Type1ValueTypeint,
        RobotIds = Type1ValueTypeint,
    },
    XTableBountyChallengeConstVar = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableBountyChallengeDifficultyGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        DifficultyGroupId = ValueTypeint,
        Difficulty = ValueTypeint,
        NPCId = ValueTypeint,
        MonsterAtk = ValueTypeint,
        MonsterHp = ValueTypeint,
        MonsterEndure = ValueTypeint,
        SelectableCharacterGroupId = ValueTypeint,
        TaskGroupId = ValueTypeint,
        TrialCharacterGroupId = ValueTypeint,
        CharacterMaximumNum = ValueTypeint,
        FightEventIdList = Type1ValueTypeint,
        StageDescId = ValueTypeint,
        IsCloseGeneral = ValueTypebool,
    },
    XTableBountyChallengeMonster = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        DifficultyGroupId = ValueTypeint,
        StageId = ValueTypeint,
        Icon1 = ValueTypestring,
        Icon2 = ValueTypestring,
    },
    XTableBountyChallengeStage = {
        Id = ValueTypeintPrimaryKey,
        StageDescriptions = Type1ValueTypestring,
        GameplayDescription = Type1ValueTypestring,
        VideoConfigId = Type1ValueTypeint,
    },
    XTableBountyChallengeTask = {
        Id = ValueTypeintPrimaryKey,
        TaskGroupId = ValueTypeint,
        TaskId = ValueTypeint,
        Priority = ValueTypeint,
        StageDescId = ValueTypeint,
        StageDescIndex = ValueTypeint,
        Difficulty = ValueTypeint,
    },
    XTableBountyChallengeTrialCharacterGroup = {
        Id = ValueTypeintPrimaryKey,
        RobotIdList = Type1ValueTypeint,
    },
    XTableBountyTask = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        StageIcon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        RoleIcon = ValueTypestring,
        SmallRoleIcon = ValueTypestring,
        EnterAnimation = Type1ValueTypestring,
        DifficultLevel = ValueTypeint,
        TextColor = ValueTypestring,
        DifficultLevelIcon = ValueTypestring,
        DifficultLevelIconX = ValueTypestring,
        TaskExp = ValueTypeint,
        RewardId = ValueTypeint,
        RandomWeightList = Type1ValueTypeint,
    },
    XTableBountyTaskDifficultStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        RandomWeight = ValueTypeint,
        SkipId = ValueTypeint,
    },
    XTableBountyTaskRandomEvent = {
        EventId = ValueTypeintPrimaryKey,
        EventName = ValueTypestring,
        RandomWeight = ValueTypeint,
    },
    XTableBountyTaskRank = {
        RankLevel = ValueTypeintPrimaryKey,
        RankName = ValueTypestring,
        RankIcon = ValueTypestring,
        RewardId = ValueTypeint,
        LevelUpExp = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableBriefActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        TaskInfoId = ValueTypeint,
        AnimConditionId = ValueTypeint,
        BgType = ValueTypeint,
        EnterAniCheckType = ValueTypeint,
        Main3DBg = ValueTypestring,
        Main3DBgModel = ValueTypestring,
        SpecialEnterAnimName = ValueTypestring,
        EnterAnimName = ValueTypestring,
        LoopAnimName = ValueTypestring,
        VideoEnterSoundCueId = ValueTypeint,
        VideoLoopSoundCueId = ValueTypeint,
        IsAfterFirstAnimSetSkip = ValueTypeint,
        ShopInfoId = Type1ValueTypeint,
        UIModelId = Type1ValueTypestring,
        SpinePath = Type1ValueTypestring,
        GroupIdList = Type1ValueTypeint,
    },
    XTableBrilliantWalkActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        RobotId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        TimeLimitTaskId = ValueTypeint,
        InitPlugin = Type1ValueTypeint,
        TaskReward = Type1ValueTypeint,
        StoryId = ValueTypestring,
    },
    XTableBrilliantWalkAdditionalBuff = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableBrilliantWalkAttention = {
        Id = ValueTypeintPrimaryKey,
        Title = Type1ValueTypestring,
        Content = Type1ValueTypestring,
    },
    XTableBrilliantWalkBuildPlugin = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        TrenchType = ValueTypeint,
        Type = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        NeedEnergy = ValueTypeint,
        PrePluginId = ValueTypeint,
        ItemId = ValueTypeint,
    },
    XTableBrilliantWalkChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Type = ValueTypeint,
        Name = ValueTypestring,
        PrefabName = ValueTypestring,
        MainStageIds = Type1ValueTypeint,
        SideStageIds = Type1ValueTypeint,
    },
    XTableBrilliantWalkStage = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        PerfabType = ValueTypestring,
        RecommendBuild = Type1ValueTypeint,
        UnlockPlugin = Type1ValueTypeint,
        AddEnergy = ValueTypeint,
        TimeScoreLimit = ValueTypeint,
        TimeScoreParam = Type1ValueTypefloat,
        HpScoreLimit = ValueTypeint,
        HpScoreParam = Type1ValueTypefloat,
        ComboScoreLimit = ValueTypeint,
        ComboScoreParam = Type1ValueTypefloat,
        PerfectParam = ValueTypefloat,
    },
    XTableBrilliantWalkStageClient = {
        Id = ValueTypeintPrimaryKey,
        ScoreRank = Type1ValueTypeint,
    },
    XTableBrilliantWalkTask = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTableBrilliantWalkTrench = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TrenchType = ValueTypeint,
        NeedUnlockPlugin = Type1ValueTypeint,
        NeedBuildPlugin = Type1ValueTypeint,
    },
    XTableBuffTips = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableBuyAsset = {
        Id = ValueTypeintPrimaryKey,
        DailyLimit = ValueTypeint,
        TotalLimit = ValueTypeint,
        BuyLimit = ValueTypeint,
        TimeId = ValueTypeint,
        Config = Type1ValueTypeint,
        ExchangeType = ValueTypeint,
        CanMutiply = ValueTypeint,
        AutoClose = ValueTypeint,
        IsRestrictFreeBuy = ValueTypeint,
    },
    XTableBuyAssetConfig = {
        Id = ValueTypeintPrimaryKey,
        Times = ValueTypeint,
        GainCount = ValueTypeint,
        ConsumeId = Type1ValueTypeint,
        ConsumeCount = Type1ValueTypeint,
        DiscountShows = Type1ValueTypefloat,
    },
    XTableCameraParam = {
        Id = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        IsDragOrRotate = ValueTypeint,
        IsTweenCamera = ValueTypeint,
        AllowZoom = ValueTypeint,
        Distance = ValueTypefloat,
        MinDistance = ValueTypefloat,
        MaxDistance = ValueTypefloat,
        ZoomSpeed = ValueTypefloat,
        AllowXAxis = ValueTypeint,
        TargetAngleX = ValueTypefloat,
        MinAngleX = ValueTypefloat,
        MaxAngleX = ValueTypefloat,
        XAxisSpeed = ValueTypefloat,
        AllowYAxis = ValueTypeint,
        TargetAngleY = ValueTypefloat,
        MinAngleY = ValueTypefloat,
        MaxAngleY = ValueTypefloat,
        YAxisSpeed = ValueTypefloat,
        AllowDrag = ValueTypeint,
        DragSpeed = ValueTypefloat,
        OffsetViewportX = ValueTypefloat,
        OffsetViewportY = ValueTypefloat,
        IsLockOnViewportOffset = ValueTypeint,
        ViewportPointX = ValueTypefloat,
        ViewportPointY = ValueTypefloat,
        BoundsCenterX = ValueTypefloat,
        BoundsCenterY = ValueTypefloat,
        BoundsCenterZ = ValueTypefloat,
        BoundsSizeX = ValueTypefloat,
        BoundsSizeY = ValueTypefloat,
        BoundsSizeZ = ValueTypefloat,
    },
    XTableCampTicketCorrection = {
        Id = ValueTypeint,
        MinValue = ValueTypeint,
        MaxValue = ValueTypeint,
    },
    XTableCanNotGiveWafer = {
        WaferId = ValueTypeintPrimaryKey,
    },
    XTableCaptureV217Camera = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type2KeyTypeintValueTypestring,
    },
    XTableCaptureV217NpcAction = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        ActionName = ValueTypestring,
        PlayType = ValueTypeint,
        UnlockDesc = ValueTypestring,
        PlayParams = Type1ValueTypestring,
    },
    XTableCaptureV217ScreenEffect = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Path = ValueTypestring,
    },
    XTableCaptureV217Sticker = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        SmallIconPath = ValueTypestring,
        IconPath = ValueTypestring,
        UnlockDesc = ValueTypestring,
        Width = ValueTypeint,
        Height = ValueTypeint,
        DefaultScale = ValueTypefloat,
        MaxScale = ValueTypefloat,
        MinScale = ValueTypefloat,
    },
    XTableCerberusGameActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        ShopId = Type1ValueTypeint,
        ChapterIds = Type1ValueTypeint,
    },
    XTableCerberusGameBoss = {
        Id = ValueTypeintPrimaryKey,
        BossName = ValueTypestring,
        BossDesc = ValueTypestring,
        BossImg = ValueTypestring,
        StageId = Type1ValueTypeint,
    },
    XTableCerberusGameChallenge = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        PreStageId = ValueTypeint,
        CharacterIds = Type1ValueTypeint,
        RobotIds = Type1ValueTypeint,
        BuffIcon = Type1ValueTypestring,
        BuffTitle = Type1ValueTypestring,
        BuffDescs = Type1ValueTypestring,
    },
    XTableCerberusGameChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        OpenCondition = ValueTypeint,
        IsClearData = ValueTypeint,
        DefaultTeam = Type1ValueTypestring,
    },
    XTableCerberusGameCharacterInfo = {
        Id = ValueTypeintPrimaryKey,
        TeamTitle = ValueTypestring,
        TeamInfo = ValueTypestring,
        CharacterInfo = ValueTypestring,
        Desc = ValueTypestring,
        SkillIcon = Type1ValueTypestring,
        SkillTitle = Type1ValueTypestring,
        SkillDesc = Type1ValueTypestring,
    },
    XTableCerberusGameClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypestring,
    },
    XTableCerberusGameCommunication = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BtnContent = ValueTypestring,
        NpcName = ValueTypestring,
        NpcHandIcon = ValueTypestring,
        ContentsGroupId = ValueTypeint,
        Type = ValueTypeint,
        UiType = ValueTypeint,
    },
    XTableCerberusGameRole = {
        Id = ValueTypeintPrimaryKey,
        Chapter = ValueTypeint,
        Difficulty = ValueTypeint,
        RoleId = ValueTypeint,
    },
    XTableCerberusGameStoryLine = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        OpenCondition = ValueTypeint,
        RobotIds = Type1ValueTypeint,
        StoryPointIds = Type1ValueTypeint,
        Name = ValueTypestring,
        Bg = ValueTypestring,
        EffectUrl = ValueTypestring,
        FubenPrefab = ValueTypestring,
        GirdStageFight = ValueTypestring,
        GirdStageFightSpecial = ValueTypestring,
        GridBossPrefab = ValueTypestring,
        GridStory1 = ValueTypestring,
        GridStory2 = ValueTypestring,
        Difficulty = ValueTypeint,
    },
    XTableCerberusGameStoryPoint = {
        Id = ValueTypeintPrimaryKey,
        StoryPointType = ValueTypeint,
        PrePointIds = Type1ValueTypeint,
        StoryPointTypeParams = Type1ValueTypestring,
        OpenCondition = ValueTypeint,
        Title = ValueTypestring,
        Name = ValueTypestring,
        GridShowType = ValueTypeint,
        BuffIcon = Type1ValueTypestring,
        BuffTitle = Type1ValueTypestring,
        BuffDescs = Type1ValueTypestring,
        ExtraRobotId = ValueTypeint,
    },
    XTableChallengeArea = {
        ChallengeId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ArenaLv = ValueTypeint,
        MinLv = ValueTypeint,
        MaxLv = ValueTypeint,
        DistributeId = ValueTypeint,
        JoinNum = ValueTypeint,
        DanUpRank = ValueTypeint,
        DanKeepRank = ValueTypeint,
        DanUpRankCostContributeScore = ValueTypeint,
        DanDownRank = ValueTypeint,
        UpRewardId = ValueTypeint,
        KeepRewardId = ValueTypeint,
        DownRewardId = ValueTypeint,
        DayUnlockNum = ValueTypeint,
        WeekEndUnlockNum = ValueTypeint,
        AreaId = Type1ValueTypeint,
        AreaIdGroup = Type1ValueTypestring,
        BaseTeamRank = ValueTypeint,
        DifShowRate = ValueTypeint,
        AvgScore = ValueTypeint,
        MinScore = ValueTypeint,
        ContributeScore = Type1ValueTypeint,
        TaskId = Type1ValueTypeint,
        ProtectScore = ValueTypeint,
        MinWaveRate = ValueTypeint,
        MaxWaveRate = ValueTypeint,
        Ignore = ValueTypeint,
    },
    XTableChallengeAreaFixReward = {
        Id = ValueTypeintPrimaryKey,
        ActivityIdRange = ValueTypeint,
        UpRewardId = ValueTypeint,
        KeepRewardId = ValueTypeint,
        DownRewardId = ValueTypeint,
        DanUpRank = ValueTypeint,
        DanKeepRank = ValueTypeint,
        DanUpRankCostContributeScore = ValueTypeint,
        DanDownRank = ValueTypeint,
    },
    XTableChallengeDayReward = {
        DayOfWeek = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableChallengeExtraTime = {
        Id = ValueTypeintPrimaryKey,
        DamageType = ValueTypeint,
        MaxDamage = ValueTypeint,
        Ruling = ValueTypeint,
        AbbrState = ValueTypeint,
        DamageIntervals = Type1ValueTypeint,
        TimeIntervals = Type1ValueTypeint,
    },
    XTableChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        OrderId = ValueTypeint,
        Difficult = ValueTypeint,
        ChapterEn = ValueTypestring,
        PrefabName = ValueTypestring,
        ExStageId = ValueTypeint,
        TaskGroupId = ValueTypeint,
        StageId = Type1ValueTypeint,
        TreasureId = Type1ValueTypeint,
        ChapterName = ValueTypestring,
        Bg = ValueTypestring,
        Icon = ValueTypestring,
        ActivityCondition = ValueTypeint,
        ExploreGroupId = ValueTypeint,
        OpenCondition = ValueTypeint,
        ParallelAnimeGroupId = Type1ValueTypeint,
        MoveStageIndex = Type1ValueTypeint,
        DatumLinePrecent = ValueTypefloat,
        ChapterTextColor = Type1ValueTypestring,
        LeftTimeTextColor = Type1ValueTypestring,
        StarProgressTextColor = Type1ValueTypestring,
        IsBtnMissionWhite = ValueTypeint,
        SkipId = Type1ValueTypeint,
        SkipCondition = Type1ValueTypeint,
        SkipIcon = Type1ValueTypestring,
    },
    XTableChapterExtra = {
        Id = ValueTypeintPrimaryKey,
        ChapterName = ValueTypestring,
        ChapterEn = ValueTypestring,
        Icon = ValueTypestring,
        OrderId = ValueTypeint,
        ChapterId = Type1ValueTypeint,
        ZhouMuId = ValueTypeint,
    },
    XTableChapterExtraActivity = {
        Id = ValueTypeint,
        ChapterId = Type1ValueTypeint,
        ChapterTimeId = ValueTypeint,
        HideChapterTimeId = ValueTypeint,
    },
    XTableChapterExtraDetails = {
        ChapterId = ValueTypeintPrimaryKey,
        OrderId = ValueTypeint,
        Difficult = ValueTypeint,
        ChapterEn = ValueTypestring,
        PrefabName = ValueTypestring,
        StageId = Type1ValueTypeint,
        TreasureId = Type1ValueTypeint,
        ChapterName = ValueTypestring,
        MoveStageIndex = Type1ValueTypeint,
        DatumLinePrecent = ValueTypefloat,
        Icon = ValueTypestring,
        ActivityCondition = ValueTypeint,
        ExploreGroupId = ValueTypeint,
        StageTitle = ValueTypestring,
        OpenCondition = ValueTypeint,
        IsBtnMissionWhite = ValueTypeint,
    },
    XTableChapterExtraStarTreasure = {
        TreasureId = ValueTypeintPrimaryKey,
        RequireStar = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableChapterFashionRelative = {
        ChapterId = ValueTypeintPrimaryKey,
        FashionIds = Type1ValueTypeint,
        IsWeakInterput = ValueTypebool,
    },
    XTableChapterMain = {
        Id = ValueTypeintPrimaryKey,
        ChapterName = ValueTypestring,
        ChapterEn = ValueTypestring,
        Icon = ValueTypestring,
        OrderId = ValueTypeint,
        Difficult = ValueTypeint,
        BfrtId = ValueTypeint,
        ChapterId = Type1ValueTypeint,
        ZhouMuId = ValueTypeint,
        SubChapter = Type1ValueTypeint,
        GroupId = ValueTypeint,
        ShowCondition = ValueTypeint,
    },
    XTableChapterMainGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Bg = ValueTypestring,
        BgmCueId = ValueTypeint,
        ShowCondition = ValueTypeint,
    },
    XTableCharacter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TradeName = ValueTypestring,
        LogName = ValueTypestring,
        EnName = ValueTypestring,
        Type = ValueTypeint,
        Sex = ValueTypeint,
        StoryChapterId = ValueTypeint,
        Intro = ValueTypestring,
        ItemId = ValueTypeint,
        LevelUpTemplateId = ValueTypeint,
        Priority = ValueTypeint,
        EquipType = ValueTypeint,
        EquipId = ValueTypeint,
        ExclusiveEquipId = ValueTypeint,
        EmotionIcon = ValueTypestring,
        Foreshow = ValueTypeint,
        DefaultNpcFashtionId = ValueTypeint,
        CaptainSkillId = ValueTypeint,
        MissionInfo = ValueTypestring,
        NeedFirstShow = ValueTypeint,
        Code = ValueTypestring,
        Element = ValueTypeint,
        ShowTimeId = ValueTypeint,
        LinkageType = ValueTypeint,
        GeneralSkillIds = Type1ValueTypeint,
        IsAddGeneral = Type1ValueTypebool,
        GeneralElement = Type1ValueTypeint,
        Career = ValueTypeint,
    },
    XTableCharacterAction = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Name = ValueTypestring,
        SignBoardActionId = ValueTypeint,
        UnlockLv = ValueTypeint,
        UnlockCondition = Type1ValueTypeint,
        ConditionDescript = ValueTypestring,
    },
    XTableCharacterActionRange = {
        Id = ValueTypeintPrimaryKey,
        BeginIndex = ValueTypeint,
        EndIndex = ValueTypeint,
    },
    XTableCharacterActionSignBoard = {
        Id = ValueTypeintPrimaryKey,
        CharacterActionId = ValueTypeint,
    },
    XTableCharacterAnimaSyncCallBack = {
        ModelName = ValueTypestringPrimaryKey,
        IsAllAnimaSync = ValueTypebool,
        AnimaNames = Type1ValueTypestring,
        WeaponLoadDefaultShow = Type1ValueTypestring,
        WeaponLoadDefaultHide = Type1ValueTypestring,
    },
    XTableCharacterBaseData = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeintPrimaryKey,
        ShapId = ValueTypeint,
        BaseDataTitle = Type1ValueTypestring,
        BaseData = Type1ValueTypestring,
        Cast = Type1ValueTypestring,
        TeamIcon = ValueTypestring,
    },
    XTableCharacterCareer = {
        Type = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        IconTranspose = ValueTypestring,
        IconObs = ValueTypestring,
        Des = ValueTypestring,
        Name = ValueTypestring,
        SortId = ValueTypeint,
        ShowId = ValueTypeint,
    },
    XTableCharacterClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Params = Type1ValueTypestring,
    },
    XTableCharacterCollaboration = {
        CharacterId = ValueTypeintPrimaryKey,
        languageSet = ValueTypestring,
        Text = ValueTypestring,
        IconPath = ValueTypestring,
        IconX = ValueTypefloat,
        IconY = ValueTypefloat,
        IconScale = ValueTypefloat,
        IsNewCharacter = ValueTypebool,
    },
    XTableCharacterCute = {
        CharacterId = ValueTypeintPrimaryKey,
        ModelName = ValueTypestring,
        Name = ValueTypestring,
        SmallHeadIcon = ValueTypestring,
        HalfBodyImage = ValueTypestring,
        RoundnessHeadIcon = ValueTypestring,
    },
    XTableCharacterCuteUiEffect = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        ActionId = ValueTypestring,
        EffectRootName = ValueTypestring,
        EffectPath = Type1ValueTypestring,
    },
    XTableCharacterElement = {
        Id = ValueTypeintPrimaryKey,
        ElementName = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        Icon2 = ValueTypestring,
        Icon3 = ValueTypestring,
    },
    XTableCharacterEquipTypeToIdAuto = {
        EquipType = ValueTypeintPrimaryKey,
        CharacterId = Type1ValueTypeint,
    },
    XTableCharacterExhibition = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        GroupName = ValueTypestring,
        GroupNameEn = ValueTypestring,
        GroupLogo = ValueTypestring,
        GroupDescription = ValueTypestring,
        CharacterId = ValueTypeint,
        HeadPortrait = ValueTypestring,
        GraduationPortrait = ValueTypestring,
        Port = ValueTypeint,
        Type = ValueTypeint,
        InVisible = ValueTypeint,
        CanClickGroup = ValueTypeint,
    },
    XTableCharacterFavorAttr = {
        CharacterId = ValueTypeint,
        AttrType = ValueTypeint,
    },
    XTableCharacterFilter = {
        Id = ValueTypeintPrimaryKey,
        TagGroups = Type1ValueTypeint,
    },
    XTableCharacterFilterCommonGroup = {
        Id = ValueTypeintPrimaryKey,
        Tags = Type1ValueTypeint,
    },
    XTableCharacterFilterController = {
        UiName = ValueTypestringPrimaryKey,
        CharacterListPrefabPath = ValueTypestring,
        EnableFolder = ValueTypebool,
        DisableAutoSeleGrid = ValueTypebool,
        EnableShowFragment = ValueTypebool,
        DiableEmptyStatus = ValueTypebool,
        ForceEnableUniframe = ValueTypebool,
        EnableRedDotTag = ValueTypebool,
        EnableSupportTag = ValueTypebool,
        BanElementTags = Type1ValueTypeint,
        DiyTagNames = Type1ValueTypestring,
        BtnGeneralSkillType = ValueTypeint,
        SortTagList = Type1ValueTypeint,
    },
    XTableCharacterFilterTag = {
        Id = ValueTypeintPrimaryKey,
        TagName = ValueTypestring,
        CharacterType = ValueTypeint,
        Value = ValueTypeint,
        SelectedIcon = ValueTypestring,
        UnSelectedIcon = ValueTypestring,
    },
    XTableCharacterFilterTagGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupName = ValueTypestring,
        Tags = Type1ValueTypeint,
        Order = ValueTypeint,
    },
    XTableCharacterGeneralSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        IconTranspose = ValueTypestring,
        IconBlue = ValueTypestring,
        FightEventId = ValueTypeint,
        IsSkipSkillCheck = ValueTypebool,
        SkillId = Type1ValueTypeint,
        SkillLevel = Type1ValueTypeint,
        EnhanceSkillId = Type1ValueTypeint,
        EnhanceSkillLevel = Type1ValueTypeint,
    },
    XTableCharacterGrade = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Grade = ValueTypeint,
        UseItemKey = ValueTypeint,
        UseItemCount = ValueTypeint,
        AttrId = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        GradeBigIcon = ValueTypestring,
        GradeIcon = ValueTypestring,
        Star = ValueTypestring,
        NoStar = ValueTypestring,
        GradeName = ValueTypestring,
    },
    XTableCharacterInformation = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        UnlockLv = ValueTypeint,
        Title = ValueTypestring,
        Content = ValueTypestring,
        ConditionDescript = ValueTypestring,
    },
    XTableCharacterLiberation = {
        CharacterGrowUpLevelId = ValueTypeintPrimaryKey,
        ModelId = ValueTypestring,
        EffectRootName = ValueTypestring,
        EffectPath = ValueTypestring,
        Title = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableCharacterLiberationIcon = {
        LiberationLv = ValueTypeintPrimaryKey,
        ArticleIcon = ValueTypestring,
        Color = ValueTypestring,
    },
    XTableCharacterModelNodeEffectMapping = {
        PId = ValueTypestringPrimaryKey,
        PrefabRootName = ValueTypestring,
        PrefabName = Type1ValueTypestring,
        AnimController = Type1ValueTypestring,
        IsDontRotate = ValueTypebool,
    },
    XTableCharacterObsTriggerMagic = {
        SkillId = ValueTypeintPrimaryKey,
        Des = Type1ValueTypestring,
        ObservationCareer = Type1ValueTypeint,
        ObservationElement = Type1ValueTypeint,
        Level = Type1ValueTypeint,
        MagicList = Type2KeyTypeintValueTypestring,
    },
    XTableCharacterPopupGetCharacterController = {
        CharacterId = ValueTypeintPrimaryKey,
        TxtTypeColor = ValueTypestring,
        ShowImgUrl = ValueTypestring,
    },
    XTableCharacterPos = {
        CharacterId = ValueTypeintPrimaryKey,
        MainSkillIcon = Type1ValueTypestring,
        MainSkillName = Type1ValueTypestring,
        MainSkillType = Type1ValueTypestring,
    },
    XTableCharacterPower = {
        Id = ValueTypeintPrimaryKey,
        PowerName = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        IconSmall = ValueTypestring,
        IconSkill = ValueTypestring,
        IconSkill2 = ValueTypestring,
        IconSkillUnder = ValueTypestring,
        IconEvolve = ValueTypestring,
        IconDetail = ValueTypestring,
    },
    XTableCharacterQuality = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Quality = ValueTypeint,
        NpcId = ValueTypeint,
        AttrId = Type1ValueTypeint,
    },
    XTableCharacterQualityFragment = {
        Id = ValueTypeintPrimaryKey,
        Quality = ValueTypeint,
        Type = ValueTypeint,
        DecomposeCount = ValueTypeint,
        ComposeCount = ValueTypeint,
        StarUseCount = Type1ValueTypeint,
        PromoteItemId = ValueTypeint,
        PromoteUseCoin = ValueTypeint,
    },
    XTableCharacterQualityIcon = {
        Quality = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        IconCharacter = ValueTypestring,
        IconCharacterInit = ValueTypestring,
        IconGoods = ValueTypestring,
        InitColor = ValueTypestring,
        Desc = ValueTypestring,
        Icon2 = ValueTypestring,
        IconCharacter2 = ValueTypestring,
        IconCharacterInit2 = ValueTypestring,
        IconGoods2 = ValueTypestring,
        InitColor2 = ValueTypestring,
        Desc2 = ValueTypestring,
        IconDraw = ValueTypestring,
        IconDraw2 = ValueTypestring,
        IconEffect = ValueTypestring,
        IconEffect2 = ValueTypestring,
    },
    XTableCharacterRecommend = {
        Id = ValueTypeintPrimaryKey,
        CharacterRecomend = Type1ValueTypeint,
    },
    XTableCharacterRes = {
        Id = ValueTypeint,
    },
    XTableCharacterReward = {
        Id = ValueTypeint,
        CharacterId = ValueTypeint,
        UnlockType = ValueTypeint,
        UnlockPara = ValueTypeint,
        ItemId = ValueTypeint,
        ItemCount = ValueTypeint,
        ConditionDescript = ValueTypestring,
    },
    XTableCharacterShowScore = {
        CharacterId = ValueTypeintPrimaryKey,
        Quality = Type1ValueTypeint,
    },
    XTableCharacterSkill = {
        CharacterId = ValueTypeintPrimaryKey,
        SkillGroupId = Type1ValueTypeint,
        Pos = Type1ValueTypeint,
    },
    XTableCharacterSkillEntry = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableCharacterSkillExchangeDes = {
        SkillLevelId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Title = Type2KeyTypeintValueTypestring,
        SpecificDesLite = Type2KeyTypeintValueTypestring,
        UiType = ValueTypeint,
    },
    XTableCharacterSkillGate = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        EnName = ValueTypestring,
    },
    XTableCharacterSkillGroup = {
        Id = ValueTypeintPrimaryKey,
        SkillId = Type1ValueTypeint,
    },
    XTableCharacterSkillLevelEffect = {
        SkillLevelId = ValueTypeintPrimaryKey,
        BornMagic = Type1ValueTypeint,
        SubSkillId = Type1ValueTypeint,
        SubMagicId = Type1ValueTypeint,
        Ability = ValueTypeint,
        ResonanceAbility = ValueTypeint,
        PlusAbility = ValueTypeint,
    },
    XTableCharacterSkillLevelEffectMinMaxLevel = {
        SkillId = ValueTypeintPrimaryKey,
        Min = ValueTypeint,
        Max = ValueTypeint,
    },
    XTableCharacterSkillPool = {
        Id = ValueTypeintPrimaryKey,
        PoolId = ValueTypeint,
        Weight = ValueTypeint,
        SkillId = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableCharacterSkillQualityApart = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Quality = ValueTypeint,
        Phase = ValueTypeint,
        Name = ValueTypestring,
        Level = ValueTypeint,
        Intro = ValueTypestring,
        SkillId = ValueTypeint,
    },
    XTableCharacterSkillQualityApartByCharacterId = {
        CharacterId = ValueTypeintPrimaryKey,
        CharacterQualityIds = Type1ValueTypeint,
    },
    XTableCharacterSkillQualityApartByCharacterQualityId = {
        CharacterQualityId = ValueTypeintPrimaryKey,
        CharacterQualityPhaseIds = Type1ValueTypeint,
    },
    XTableCharacterSkillQualityApartByCharacterQualityPhaseId = {
        CharacterQualityPhaseId = ValueTypeintPrimaryKey,
        Id = Type1ValueTypeint,
    },
    XTableCharacterSkillQualityBigEffectBall = {
        Quality = ValueTypeintPrimaryKey,
        PerformDisable = Type1ValueTypebool,
        PerformArea = Type1ValueTypestring,
        CueIds = Type1ValueTypeint,
    },
    XTableCharacterSkillTeach = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Title = ValueTypestring,
        WebUrl = ValueTypestring,
        Icon = ValueTypestring,
        TeachIcon = ValueTypestring,
        HeadLine = Type2KeyTypeintValueTypestring,
        Description = Type2KeyTypeintValueTypestring,
    },
    XTableCharacterSkillType = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
    },
    XTableCharacterSkillTypeInfo = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableCharacterSkillTypePlus = {
        Id = ValueTypeintPrimaryKey,
        CharacterType = Type1ValueTypeint,
        SkillType = Type1ValueTypeint,
    },
    XTableCharacterSkillUpgrade = {
        Name = ValueTypestring,
        Intro = ValueTypestring,
        Icon = ValueTypestring,
        UseSkillPoint = ValueTypeint,
        UseCoin = ValueTypeint,
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Level = ValueTypeint,
        ConditionId = Type1ValueTypeint,
    },
    XTableCharacterSkillUpgradeDes = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Level = ValueTypeint,
        Name = ValueTypestring,
        RefId = ValueTypeint,
        SpecificDesNum = Type2KeyTypeintValueTypestring,
    },
    XTableCharacterSkillUpgradeDetail = {
        RefId = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        WeaponSkillDes = ValueTypestring,
        EntryId = Type1ValueTypeint,
        TypeDes = ValueTypestring,
        Tag = Type1ValueTypestring,
        Title = Type2KeyTypeintValueTypestring,
        BriefDes = Type2KeyTypeintValueTypestring,
        SpecificDes = Type2KeyTypeintValueTypestring,
    },
    XTableCharacterSkillUpgradeIdOptimize = {
        SkillLevelId = ValueTypeintPrimaryKey,
        ConditionId = Type1ValueTypeint,
        UseSkillPoint = ValueTypeint,
        UseCoin = ValueTypeint,
    },
    XTableCharacterSkillUpgradeMinMaxLevel = {
        SkillId = ValueTypeintPrimaryKey,
        Min = ValueTypeint,
        Max = ValueTypeint,
    },
    XTableCharacterSort = {
        Id = ValueTypeintPrimaryKey,
        Tags = Type1ValueTypeint,
    },
    XTableCharacterSortTag = {
        Id = ValueTypeintPrimaryKey,
        TagName = ValueTypestring,
        CharacterType = ValueTypeint,
    },
    XTableCharacterStory = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        StoryId = ValueTypestring,
        StageId = ValueTypeint,
        UnlockLv = ValueTypeint,
        ConditionDescript = ValueTypestring,
        SectionNumber = ValueTypeint,
        TaskId = ValueTypeint,
        ExtraDescript = ValueTypestring,
        Tips = Type1ValueTypeint,
        StageDetailType = ValueTypeint,
        StageDetailParams = Type1ValueTypestring,
    },
    XTableCharacterStoryActivity = {
        CharacterId = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        TaskTimeLimitId = ValueTypeint,
        RewardId = ValueTypeint,
        TimeId = ValueTypeint,
    },
    XTableCharacterStoryChaper = {
        Id = ValueTypeint,
        Name = ValueTypestring,
        ConditionId = ValueTypeint,
        TaskId = ValueTypeint,
        StoryStageId = Type1ValueTypeint,
    },
    XTableCharacterStoryStage = {
        Id = ValueTypeint,
        OpenConditionId = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        StageId = ValueTypeint,
        StoryId = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Picture = ValueTypestring,
        TaskId = ValueTypeint,
    },
    XTableCharacterStoryStageDetailType = {
        Type = ValueTypeintPrimaryKey,
        PrefabAddress = ValueTypestring,
        CommonParams = Type1ValueTypestring,
    },
    XTableCharacterStrangeNews = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Type = ValueTypeint,
        UnlockType = ValueTypeint,
        UnlockPara = ValueTypeint,
        Title = ValueTypestring,
        Content = ValueTypestring,
        Picture = ValueTypestring,
        ConditionDescript = ValueTypestring,
        PreviewPicture = ValueTypestring,
    },
    XTableCharacterSuitPriority = {
        CharacterId = ValueTypeintPrimaryKey,
        ExclusiveSuitId = ValueTypeint,
        PriorityType = Type1ValueTypeint,
    },
    XTableCharacterTabByRecommendTypeTab = {
        CharacterRecommendTypeTabId = ValueTypeintPrimaryKey,
        TabName = ValueTypestring,
        GroupId = ValueTypeint,
    },
    XTableCharacterTabId = {
        CharacterRecommendTypeId = ValueTypeintPrimaryKey,
        CharacterRecommendTypeTabIds = Type1ValueTypeint,
    },
    XTableCharacterTips = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BgColor = ValueTypestring,
        TxtColor = ValueTypestring,
    },
    XTableCharacterTower = {
        Id = ValueTypeintPrimaryKey,
        CharacterName = ValueTypestring,
        Img = ValueTypestring,
        Priority = ValueTypeint,
        OpenTimeId = ValueTypeint,
        ConditionId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
    },
    XTableCharacterTowerActionDisplay = {
        Id = ValueTypeintPrimaryKey,
        SignBoardActionId = ValueTypeint,
    },
    XTableCharacterTowerChapter = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        TimeId = ValueTypeint,
        CharacterId = ValueTypeint,
        OpenCondition = Type1ValueTypeint,
        ActivityCondition = Type1ValueTypeint,
        Img = ValueTypestring,
        Title = ValueTypestring,
        Prefab = ValueTypestring,
        ChapterRewardId = ValueTypeint,
        RelationGroupId = ValueTypeint,
        StageIds = Type1ValueTypeint,
        TreasureId = Type1ValueTypeint,
    },
    XTableCharacterTowerChapterDetail = {
        Id = ValueTypeintPrimaryKey,
        RelatedChapterId = ValueTypeint,
        ChapterName = ValueTypestring,
        PreviewRewardId = ValueTypeint,
        ShowRewardId = ValueTypeint,
        StoryPassedBg = ValueTypestring,
        StoryUnPassedBg = ValueTypestring,
        StorySpineBg = ValueTypestring,
        ChapterRewardIcon = ValueTypestring,
        TaskSceneUrl = ValueTypestring,
        TaskModelUrl = ValueTypestring,
        BattleBg = ValueTypestring,
    },
    XTableCharacterTowerConfig = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypestring,
    },
    XTableCharacterTowerDisplayController = {
        CharacterId = ValueTypeintPrimaryKey,
        DisabledActionId = Type1ValueTypeint,
    },
    XTableCharacterTowerRelation = {
        Id = ValueTypeintPrimaryKey,
        Conditions = Type1ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        FinishNums = Type1ValueTypeint,
        StoryIds = Type1ValueTypestring,
    },
    XTableCharacterTowerRelationDetail = {
        Id = ValueTypeintPrimaryKey,
        FettersPrefab = ValueTypestring,
        FettersTitles = Type1ValueTypestring,
        FettersDescribes = Type1ValueTypestring,
        ConditionTitles = Type1ValueTypestring,
        ConditionSkipId = Type1ValueTypeint,
    },
    XTableCharacterTowerTreasure = {
        TreasureId = ValueTypeintPrimaryKey,
        RequireStar = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableCharacterTrustExp = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        TrustLv = ValueTypeint,
        Exp = ValueTypeint,
        Name = ValueTypestring,
        PlayId = ValueTypeint,
    },
    XTableCharacterTrustItem = {
        Id = ValueTypeintPrimaryKey,
        Exp = ValueTypeint,
        FavorCharacterId = Type1ValueTypeint,
        FavorExp = ValueTypeint,
        TrustItemType = ValueTypeint,
        LimitLinkageType = Type1ValueTypeint,
    },
    XTableCharacterUiEffect = {
        Id = ValueTypeintPrimaryKey,
        FashionId = ValueTypeint,
        ActionId = ValueTypestring,
        EffectRootName = ValueTypestring,
        EquipModelId = Type1ValueTypeint,
        EffectPath = Type1ValueTypestring,
        DisplayDelayTime = Type1ValueTypeint,
        IsDontRotate = ValueTypeint,
    },
    XTableCharacterUiEquipEffect = {
        Id = ValueTypeintPrimaryKey,
        FashionId = ValueTypeint,
        ActionId = ValueTypestring,
        EffectRootName = ValueTypestring,
        EquipModelId = ValueTypeint,
        EffectPath = Type1ValueTypestring,
    },
    XTableCharacterVoice = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Name = ValueTypeint,
        CvId = ValueTypeint,
        UnlockLv = ValueTypeint,
        UnlockCondition = ValueTypeint,
        ConditionDescript = ValueTypeint,
        SoundType = ValueTypeint,
        IsShow = ValueTypeint,
        TurnOffBgm = ValueTypebool,
    },
    XTableCharacterVoiceContentMap = {
        Id = ValueTypeintPrimaryKey,
        Text = ValueTypestring,
    },
    XTableCharacterVoiceRange = {
        Id = ValueTypeintPrimaryKey,
        BeginIndex = ValueTypeint,
        EndIndex = ValueTypeint,
    },
    XTableCharActiveMsg = {
        Id = ValueTypeintPrimaryKey,
        ActId = ValueTypeint,
        Order = ValueTypeint,
        Title = ValueTypestring,
        Content = ValueTypestring,
        IsLock = ValueTypebool,
        ConditionId = ValueTypeint,
        BtnBg = ValueTypestring,
    },
    XTableCharDetail = {
        Id = ValueTypeintPrimaryKey,
        BigImgPath = ValueTypestring,
        ObtainElementList = Type1ValueTypeint,
        ObtainElementValueList = Type1ValueTypeint,
        ObtainSpeicalTitle = Type1ValueTypestring,
        ObtainSpeicalDes = Type1ValueTypestring,
        AttribGraphDes = Type1ValueTypestring,
        AttribGraphNum = Type1ValueTypeint,
        DetailDes = ValueTypestring,
        CareerIcon = ValueTypestring,
        FullBodyImg = ValueTypestring,
        LiberationShowType = ValueTypebool,
        CharacterPowerId = ValueTypeint,
        PowerSkillIds = ValueTypestring,
        PowerEnhanceSkillIds = ValueTypestring,
        EnableCheckAmplifierAndSameElement = ValueTypebool,
    },
    XTableChatBoard = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        WorldDesc = ValueTypestring,
        GetDesc = ValueTypestring,
        AvailableTimeStr = ValueTypestring,
        ChatBoardRes = ValueTypestring,
        LogoRes = ValueTypestring,
        Icon = ValueTypestring,
        EffectRes = ValueTypestring,
        ChatBoardImageRes = ValueTypestring,
        ConvertItemId = ValueTypeint,
        ConvertItemCount = ValueTypeint,
        IsInit = ValueTypebool,
        IsDefault = ValueTypebool,
        ExpireTimeStr = ValueTypestring,
        Duration = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableChatChannelTimeLimit = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
    },
    XTableChatEffect = {
        Id = ValueTypeintPrimaryKey,
        BeginTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
        Keyword = Type1ValueTypestring,
        Path = Type1ValueTypestring,
        Weight = Type1ValueTypeint,
        CoolTime = ValueTypestring,
        TriggerType = ValueTypeint,
        Channel = Type1ValueTypeint,
    },
    XTableCheatResonance = {
        CharacterId = ValueTypeint,
        WeaponId = ValueTypeint,
        WaferId = Type1ValueTypeint,
        WeaponResonance = ValueTypestring,
        WeaponResonanceType = ValueTypestring,
        WaferResonance = Type2KeyTypeintValueTypestring,
        WaferResonanceType = Type2KeyTypeintValueTypestring,
        WaferAwakeCount = Type1ValueTypeint,
        OverrunSuitId = Type1ValueTypeint,
    },
    XTableChessCommunication = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BtnContent = ValueTypestring,
        NpcName = ValueTypestring,
        NpcHandIcon = ValueTypestring,
        ContentsGroupId = ValueTypeint,
        Type = ValueTypeint,
        UiType = ValueTypeint,
    },
    XTableChessGrowls = {
        Id = ValueTypeintPrimaryKey,
        Belong = ValueTypeint,
        Duration = ValueTypeint,
        BelongArgs = Type1ValueTypeint,
        TriggerType = ValueTypeint,
        TriggerArgs = Type1ValueTypeint,
        CvIds = Type1ValueTypeint,
        Text = Type1ValueTypestring,
    },
    XTableChessPursuitBoss = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Perfab = ValueTypestring,
        StageId = ValueTypeint,
        BossBg = ValueTypestring,
        HeadIcon = ValueTypestring,
    },
    XTableChessPursuitCard = {
        Id = ValueTypeintPrimaryKey,
        TargetType = ValueTypeint,
        EffectId = ValueTypeint,
        SubCoin = ValueTypeint,
        Describe = ValueTypestring,
        Quality = ValueTypeint,
        Icon = ValueTypestring,
        QualityIcon = ValueTypestring,
        HeadIcon = ValueTypestring,
        Name = ValueTypestring,
        QualityIconSmall = ValueTypestring,
        Effect = ValueTypestring,
        ShopBgQualityIcon = ValueTypestring,
        TipsQualityIconBg = ValueTypestring,
        QualityIconTips = ValueTypestring,
    },
    XTableChessPursuitCardEffect = {
        Id = ValueTypeintPrimaryKey,
        EffctTrigger = ValueTypeint,
        EffectType = ValueTypeint,
        Param = Type1ValueTypeint,
        KeepType = ValueTypeint,
        KeepCount = ValueTypeint,
        KeepTypeDesc = ValueTypestring,
    },
    XTableChessPursuitMap = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        CoinId = ValueTypeint,
        OpenCondition = Type1ValueTypeint,
        InitCoin = ValueTypeint,
        InitFunc = Type1ValueTypeint,
        BossId = ValueTypeint,
        GridCount = ValueTypeint,
        CardMaxCount = ValueTypeint,
        AddCoin = ValueTypeint,
        ShopCardId = ValueTypeint,
        TestRoleGroup = Type1ValueTypeint,
        TeamGrid = Type1ValueTypeint,
        TaskId = ValueTypeint,
        RewardId = ValueTypeint,
        Perfab = ValueTypestring,
        Stage = ValueTypeint,
        RewardShow = ValueTypeint,
        StageName = ValueTypestring,
        FinishAddCoin = ValueTypeint,
        IsCanAutoClear = ValueTypeint,
    },
    XTableChessPursuitMapCardShop = {
        Id = ValueTypeintPrimaryKey,
        CardId = Type1ValueTypeint,
    },
    XTableChessPursuitMapGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Rank = ValueTypeint,
        TimeId = ValueTypeint,
        ActivityName = ValueTypestring,
        EntryTexture = ValueTypestring,
    },
    XTableChessPursuitMapGroupReward = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        StartRange = ValueTypeint,
        EndRange = ValueTypeint,
        RewardShowId = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableChessPursuitMapInitFunc = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Param = Type1ValueTypeint,
    },
    XTableChessPursuitStep = {
        Id = ValueTypeintPrimaryKey,
        Step = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableChessPursuitTestRole = {
        Id = ValueTypeintPrimaryKey,
        RoleId = Type1ValueTypeint,
    },
    XTableChessSkillKeyframe = {
        Id = ValueTypeintPrimaryKey,
        Key = Type1ValueTypestring,
    },
    XTableChristmasTreeActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        TaskId = Type1ValueTypeint,
        AttrName = Type1ValueTypestring,
        OverallPrefab = ValueTypestring,
        PartPrefab = Type1ValueTypestring,
        MaxDistance = ValueTypefloat,
        LongClickOffset = ValueTypeint,
        StoryId = Type1ValueTypestring,
        Time = Type1ValueTypestring,
    },
    XTableChristmasTreeActivityOrnament = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        PartId = Type1ValueTypeint,
        Attr = Type1ValueTypeint,
        SubItemId = ValueTypeint,
        ItemId = ValueTypeint,
        SubItemCount = ValueTypeint,
        IsClearItem = ValueTypebool,
        PosType = Type1ValueTypeint,
        ResPath = ValueTypestring,
        Width = ValueTypeint,
        Height = ValueTypeint,
        PlaceScale = ValueTypefloat,
    },
    XTableChristmasTreeActivityPart = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        SubId = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableClickClearGame = {
        Id = ValueTypeintPrimaryKey,
        StartTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
        HelpId = ValueTypeint,
    },
    XTableClickClearGameStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        NameEn = ValueTypestring,
        UnlockCondition = ValueTypeint,
        TimeLimit = ValueTypeint,
        HeadNormalType = ValueTypeint,
        HeadNormalCount = ValueTypeint,
        NormalTypeDesc = ValueTypestring,
        HeadSpecialType = ValueTypeint,
        HeadSpecialCount = ValueTypeint,
        SpecialTypeDesc = ValueTypestring,
        HeadWrongType = ValueTypeint,
        WrongCostTime = ValueTypeint,
        RewardId = ValueTypeint,
        RewardConditionDesc = ValueTypestring,
        PageList = Type1ValueTypestring,
    },
    XTableClickClearHead = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Url = ValueTypestring,
    },
    XTableClickClearPage = {
        Id = ValueTypeintPrimaryKey,
        RowNumber = Type1ValueTypestring,
    },
    XTableClickClearRow = {
        Id = ValueTypeintPrimaryKey,
        HeadId = Type1ValueTypeint,
    },
    XTableCloudGameConfig = {
        Id = ValueTypestringPrimaryKey,
        ParamsString = ValueTypestring,
        ParamsInt = Type1ValueTypeint,
    },
    XTableCodeText = {
        Id = ValueTypeintPrimaryKey,
        Key = ValueTypestring,
        Text = ValueTypestring,
    },
    XTableCollectionLevel = {
        Id = ValueTypeintPrimaryKey,
        CurLevel = ValueTypeint,
        MaxLevel = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableCollectionSize = {
        Id = ValueTypeintPrimaryKey,
        Size = ValueTypeint,
        GridNum = ValueTypeint,
        Scale = ValueTypefloat,
    },
    XTableCollectionWall = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Rank = ValueTypeint,
        Condition = ValueTypeint,
        InitBackgroundId = ValueTypeint,
        InitPedestalId = ValueTypeint,
    },
    XTableCollectionWallDecoration = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Rank = ValueTypeint,
        UnlockType = ValueTypeint,
        Condition = ValueTypeint,
        Path = ValueTypestring,
        Icon = ValueTypestring,
        LockDesc = ValueTypestring,
    },
    XTableCollectWords = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        CanGiven = ValueTypebool,
        Type = ValueTypeint,
    },
    XTableCollectWordsActivity = {
        Id = ValueTypeint,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        Background = ValueTypestring,
    },
    XTableCollectWordsFullReward = {
        Id = ValueTypeint,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Weight = ValueTypeint,
        RewardCount = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableCollectWordsJackpotRewardRate = {
        Id = ValueTypeint,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Rate = ValueTypeint,
    },
    XTableCollectWordsReward = {
        Id = ValueTypeintPrimaryKey,
        MagnaItem = ValueTypeint,
        ActivityId = ValueTypeint,
        Name = ValueTypestring,
        CostItem = Type1ValueTypeint,
        CostCount = Type1ValueTypeint,
        Reward = Type1ValueTypeint,
    },
    XTableColorTableActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        TaskGroupId = Type1ValueTypeint,
        MovieId = ValueTypestring,
    },
    XTableColorTableBuffDetail = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BuffBg = ValueTypestring,
        BuffTriangleBg = ValueTypestring,
        Desc = ValueTypestring,
        TeachingContents = Type1ValueTypestring,
        BuffSuggestAbility = ValueTypeint,
    },
    XTableColorTableBuffGroup = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        BuffIds = Type1ValueTypeint,
    },
    XTableColorTableCaptain = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        SettleIcon = ValueTypestring,
        SkillIcon = ValueTypestring,
        SkillName = ValueTypestring,
        SkillDesc = ValueTypestring,
        FaceIcon = ValueTypestring,
        CanChoose = ValueTypeint,
        EffectId = ValueTypeint,
        CharacterIds = Type1ValueTypeint,
        CharacterDesc = ValueTypestring,
        FightEventId = ValueTypeint,
        FightEventDesc = ValueTypestring,
    },
    XTableColorTableChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ConditionId = ValueTypeint,
        TimeId = ValueTypeint,
        ShowRewardId = ValueTypeint,
    },
    XTableColorTableConfig = {
        Key = ValueTypestringPrimaryKey,
        Params = Type1ValueTypestring,
    },
    XTableColorTableDifficultyReward = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        DifficultyId = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableColorTableDrama = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Type = ValueTypeint,
        Repeatable = ValueTypeint,
        StoryId = ValueTypestring,
        ConditionType = ValueTypeint,
        Params = Type1ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableColorTableEffect = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        LifeType = ValueTypeint,
        ShowType = ValueTypeint,
        ShowDesc = ValueTypestring,
        ShowOnPointTypes = Type1ValueTypeint,
        ShowOnColors = Type1ValueTypeint,
        Params = Type1ValueTypeint,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableColorTableEvent = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        TimelineIds = Type1ValueTypeint,
        MaxTriggerCount = ValueTypeint,
        InitWeight = ValueTypeint,
        ConditionWeights = Type2KeyTypeintValueTypeint,
        ConditionIds = Type2KeyTypeintValueTypestring,
        EffectIds = Type1ValueTypeint,
        ShowType = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        SmallIcon = ValueTypestring,
    },
    XTableColorTableEventCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypefloat,
        Desc = ValueTypestring,
    },
    XTableColorTableHandbook = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        SubType = ValueTypeint,
        EventId = ValueTypeint,
        DramaId = ValueTypeint,
        SubTypeName = ValueTypestring,
        UnlockTips = ValueTypestring,
    },
    XTableColorTableMap = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        MapType = ValueTypeint,
        Clearable = ValueTypeint,
        Rebootable = ValueTypeint,
        BossExplodeLevel = ValueTypeint,
        StudyLevelLimit = ValueTypeint,
        StudyDataLimit = ValueTypeint,
        BossLevels = Type1ValueTypeint,
        StudyDatas = Type1ValueTypeint,
        StudyLevels = Type1ValueTypeint,
        BornPosition = ValueTypeint,
        InitActionPoint = ValueTypeint,
        MaxActionPoint = ValueTypeint,
        InitTimeBlock = ValueTypeint,
        EventGroupId = ValueTypeint,
        DramaGroupId = ValueTypeint,
        PointGroupId = ValueTypeint,
        BossRebootLevel = ValueTypeint,
    },
    XTableColorTablePoint = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        PositionId = ValueTypeint,
        Color = ValueTypeint,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Icon = ValueTypestring,
        TipIcon = ValueTypestring,
        PointDesc = ValueTypestring,
        EffectDesc = ValueTypestring,
        Params = Type1ValueTypeint,
    },
    XTableColorTablePointLink = {
        Id = ValueTypeintPrimaryKey,
        MapType = ValueTypeint,
        Position = ValueTypeint,
        LinkPositions = Type1ValueTypeint,
    },
    XTableColorTablePointLinkWeight = {
        Id = ValueTypeintPrimaryKey,
        MapType = ValueTypeint,
        S = ValueTypeint,
        T = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableColorTableShop = {
        Id = ValueTypeintPrimaryKey,
        ShopId = ValueTypeint,
        UnlockTips = ValueTypestring,
    },
    XTableColorTableSpecialRole = {
        Id = ValueTypeintPrimaryKey,
        FightEventId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableColorTableStage = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        Order = ValueTypeint,
        DifficultyId = ValueTypeint,
        Name = ValueTypestring,
        StageType = ValueTypeint,
        PreStageId = ValueTypeint,
        TimeId = ValueTypeint,
        CaptainId = ValueTypeint,
        MapId = ValueTypeint,
        NormalWinConditionId = ValueTypeint,
        SpecialWinConditionId = ValueTypeint,
        NormalStageId = ValueTypeint,
        SpecialStageId = ValueTypeint,
        BossFightEventIds = Type1ValueTypeint,
        NormalStageAbility = ValueTypeint,
        SpecialStageAbility = ValueTypeint,
        StageEffectId = ValueTypeint,
        RobotGroupId = ValueTypeint,
        FirstRewardId = ValueTypeint,
        PassRewardId = ValueTypeint,
        RebootPassRewardId = ValueTypeint,
        ClearNodeCount = Type2KeyTypeintValueTypeint,
        ClearNodeRewardId = Type2KeyTypeintValueTypeint,
        Icon = ValueTypestring,
        MovieId = ValueTypestring,
        BreakTitle = ValueTypestring,
        BreakDesc = ValueTypestring,
        NormalWinTitle = ValueTypestring,
        NormalWinDesc = ValueTypestring,
        SpecialWinTitle = ValueTypestring,
        SpecialWinDesc = ValueTypestring,
    },
    XTableColorTableStageEffect = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        EffectIds = Type1ValueTypeint,
    },
    XTableColorTableStageEndStory = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        StageId = ValueTypeint,
        HandBookSubType = ValueTypeint,
        HandBookSubTypeName = ValueTypestring,
        StoryType = ValueTypeint,
        StoryId = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        UnlockTips = ValueTypestring,
    },
    XTableColorTableStageRobot = {
        Id = ValueTypeintPrimaryKey,
        RobotIds = Type1ValueTypeint,
    },
    XTableColorTableTimeline = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        IsEdge = ValueTypeint,
    },
    XTableColorTableWinCondition = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Type = ValueTypeint,
        StudyLevel = ValueTypeint,
        Colors = Type1ValueTypeint,
        TriggerCount = ValueTypeint,
        KillBossCount = ValueTypeint,
    },
    XTableCombAccumulateExpendActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MailId = ValueTypeint,
        ItemId = ValueTypeint,
        ItemIcon = ValueTypestring,
        ConditionIds = Type1ValueTypeint,
        BaseRuleTitles = Type1ValueTypestring,
        BaseRules = Type1ValueTypestring,
    },
    XTableCombAccumulateExpendReward = {
        Id = ValueTypeintPrimaryKey,
        TaskId = ValueTypeint,
        IsSpecialShow = ValueTypebool,
        IsMainReward = ValueTypebool,
    },
    XTableCommonBall = {
        Id = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        ReleaseEffect = ValueTypestring,
        ExEffect = ValueTypestring,
        LinkEffect = ValueTypestring,
        ClickEffect = ValueTypestring,
        FillBarEffect = ValueTypestring,
    },
    XTableCommunityDisplayChannel = {
        Id = ValueTypeintPrimaryKey,
        ChannelId = ValueTypeint,
    },
    XTableComposeClientConfig = {
        Id = ValueTypeintPrimaryKey,
        ActId = ValueTypeint,
        ItemDefaultWorldDesc = ValueTypestring,
        ItemDefaultDescription = ValueTypestring,
        DebugMode = ValueTypeint,
        UseDebugTime = ValueTypeint,
        DebugStartTime = ValueTypestring,
        DebugEndTime = ValueTypestring,
        BeginStoryId = ValueTypestring,
    },
    XTableComposeGame = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        CoinId = ValueTypeint,
        RefreshCountLimit = ValueTypeint,
        RefreshTimeSec = ValueTypeint,
        MaxSchedule = ValueTypeint,
        ShopRandCount = ValueTypeint,
        Schedule = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
    },
    XTableComposeGoods = {
        Id = ValueTypeintPrimaryKey,
        ActId = ValueTypeint,
        OrderId = ValueTypeint,
        Name = ValueTypestring,
        BigIcon = ValueTypestring,
        SmallIcon = ValueTypestring,
        Star = ValueTypeint,
        Quality = ValueTypeint,
        ComposeId = ValueTypeint,
        ComposeNeedNum = ValueTypeint,
        CostCoinNum = ValueTypeint,
        GainSchedule = ValueTypeint,
        FinalSchedule = ValueTypeint,
    },
    XTableComposeShop = {
        Id = ValueTypeint,
        ActId = ValueTypeint,
        Schedule = Type1ValueTypeint,
        Goods = Type1ValueTypeint,
        Weight = Type1ValueTypeint,
    },
    XTableConcertClientConfig = {
        Id = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableConcertPreHeatingActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        StageIds = Type1ValueTypeint,
        TaskGroupId = ValueTypeint,
    },
    XTableConcertPreHeatingControlParam = {
        Id = ValueTypeintPrimaryKey,
        ParamName = ValueTypestring,
        MinParam = ValueTypeint,
        MaxParam = ValueTypeint,
        Target = ValueTypeint,
        AisacControlName = ValueTypestring,
        AisacTargetValue = ValueTypefloat,
        SandControlType = ValueTypeint,
        CueControlType = ValueTypeint,
    },
    XTableConcertPreHeatingStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        CueId = ValueTypeint,
        ControlIds = Type1ValueTypeint,
        StageEntranceImg = ValueTypestring,
        StageMainUiDisplayImg = ValueTypestring,
        StageMainUiSilhouetteImg = ValueTypestring,
        StageGamePlaySilhouetteImg = ValueTypestring,
        TargetCompeleteSpinePrefab = ValueTypestring,
        IsMainPerformance = ValueTypebool,
    },
    XTableConcertVideoConfig = {
        Id = ValueTypeintPrimaryKey,
        LiveUrl = ValueTypestring,
        LiveTimeId = ValueTypeint,
        RecordUrl = ValueTypestring,
        RecordTimeId = ValueTypeint,
    },
    XTableCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        Formula = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableConnectingLineActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        CoinItemId = ValueTypeint,
        NpcName = ValueTypestring,
        NpcPic = ValueTypestring,
        HairPic = ValueTypestring,
        StageNum = ValueTypeint,
    },
    XTableConnectingLineBubble = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Type = ValueTypeint,
        Text = Type1ValueTypestring,
        Face = ValueTypestring,
        Duration = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableConnectingLineChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ActivityId = ValueTypeint,
        PassCG = ValueTypestring,
        TimeId = ValueTypeint,
    },
    XTableConnectingLineClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableConnectingLineGrid = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Row = ValueTypeint,
        Column = Type1ValueTypeint,
    },
    XTableConnectingLineHead = {
        Id = ValueTypeintPrimaryKey,
        HeadPic = ValueTypestring,
        GridHeadBg = ValueTypestring,
        GridBg = ValueTypestring,
        Color = ValueTypestring,
        LineColor = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableConnectingLineStage = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        CostItemNum = ValueTypeint,
        ConnectingNum = ValueTypeint,
        LightingNum = ValueTypeint,
        RewardId = ValueTypeint,
        ChapterId = ValueTypeint,
        LockPic = ValueTypestring,
        UnlockPic = ValueTypestring,
        Name = ValueTypestring,
        RewardText = Type1ValueTypestring,
    },
    XTableControllerMap = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Title = ValueTypestring,
        InputMapId = ValueTypeint,
        DefaultKeyMapIds = Type1ValueTypeint,
        KeySetTypes = Type1ValueTypeint,
        IsMutexIgnoreInputMapSectionId = ValueTypebool,
    },
    XTableCostHint = {
        Id = ValueTypeintPrimaryKey,
        CostItemIds = Type1ValueTypeint,
        CostItemNum = ValueTypeint,
    },
    XTableCoupleCombatActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        FightEventId = ValueTypeint,
        Name = ValueTypestring,
        BannerBg = ValueTypestring,
        GridPrefab = ValueTypestring,
    },
    XTableCoupleCombatChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        NameIcon = ValueTypestring,
        Icon = ValueTypestring,
        TimeId = ValueTypeint,
        UnlockChapterId = ValueTypeint,
        UnlockOccupyStageCount = ValueTypeint,
        StageIds = Type1ValueTypeint,
        RobotIds = Type1ValueTypeint,
        ShowFightEventIds = Type1ValueTypeint,
        PrefabName = ValueTypestring,
        ChapterType = ValueTypeint,
    },
    XTableCoupleCombatCharacter = {
        CharacterId = ValueTypeintPrimaryKey,
        Feature = Type1ValueTypeint,
        Name = Type1ValueTypestring,
        Icon = Type1ValueTypestring,
        Description = Type1ValueTypestring,
    },
    XTableCoupleCombatCharacterCareerSkill = {
        Id = ValueTypeintPrimaryKey,
        Type = Type1ValueTypeint,
        Name = ValueTypestring,
        EnName = ValueTypestring,
        Icon = ValueTypestring,
        Description = ValueTypestring,
        FightEventId = ValueTypeint,
        Condition = ValueTypeint,
        IconLv = ValueTypestring,
    },
    XTableCoupleCombatCharacterCareerSkillGroup = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        EnName = ValueTypestring,
        Icon = ValueTypestring,
        Description = ValueTypestring,
        BelongCareers = Type1ValueTypestring,
    },
    XTableCoupleCombatFeature = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableCoupleCombatStage = {
        Id = ValueTypeintPrimaryKey,
        OpenDay = ValueTypeint,
        Intro = Type1ValueTypestring,
        Feature = Type1ValueTypeint,
        ShowFightEventIds = Type1ValueTypeint,
        GridBg = ValueTypestring,
        IndexText = ValueTypestring,
        IsLastOne = ValueTypeint,
    },
    XTableCouplet = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        ItemConsumeCount = ValueTypeint,
        TitleName = ValueTypestring,
        StoryStr = ValueTypestring,
        BatchUrl = ValueTypestring,
        DefaultBatchUrl = ValueTypestring,
        UpImgUrl = ValueTypestring,
        DownImgUrl = ValueTypestring,
        UpWordId = Type1ValueTypeint,
        DownWordId = Type1ValueTypestring,
        DownIdPool = Type1ValueTypestring,
    },
    XTableCoupletActivityBase = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ConsumeItemId = ValueTypeint,
        HelpId = ValueTypeint,
        Title = ValueTypestring,
        TitleEn = ValueTypestring,
        EffectDelay = ValueTypestring,
        StoryId = ValueTypestring,
    },
    XTableCourse = {
        StageId = ValueTypeintPrimaryKey,
        RewardId = ValueTypeint,
        ShowId = ValueTypeint,
        Tip = ValueTypestring,
        TipEn = ValueTypestring,
    },
    XTableCourseActivity = {
        StageType = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        GroupIds = Type1ValueTypeint,
    },
    XTableCourseChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        StageType = ValueTypeint,
        ClearPoint = ValueTypeint,
        UnlockLessonPoint = ValueTypeint,
        UnlockLv = ValueTypeint,
        PrevChapterIds = Type1ValueTypeint,
        StageIds = Type1ValueTypeint,
        Order = ValueTypeint,
        Name = ValueTypestring,
        LockDesc = ValueTypestring,
    },
    XTableCourseChapterDetail = {
        ChapterId = ValueTypeintPrimaryKey,
        DescTitle = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableCourseChapterGroup = {
        GroupId = ValueTypeintPrimaryKey,
        UnlockLv = ValueTypeint,
        PrevChapterIds = Type1ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        LockDesc = ValueTypestring,
        Bg = ValueTypestring,
    },
    XTableCourseClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableCourseExamChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        GridNormalBg = ValueTypestring,
        GridDisableBg = ValueTypestring,
        ShowReward = ValueTypeint,
        RewardIcon = ValueTypestring,
    },
    XTableCourseLessonChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        GridNormalBg = ValueTypestring,
        ImgNum = ValueTypestring,
        SortBg = ValueTypestring,
        ShowReward = ValueTypeint,
    },
    XTableCourseReward = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        Point = ValueTypeint,
        RewardId = ValueTypeint,
        ClearTipsTitle = ValueTypestring,
        Name = ValueTypestring,
    },
    XTableCourseStage = {
        StageId = ValueTypeintPrimaryKey,
        PrevStageId = Type1ValueTypeint,
        LessonStageId = ValueTypeint,
        StarPoint = Type1ValueTypeint,
        StageShowType = ValueTypeint,
    },
    XTableCourseStageShowType = {
        StageShowType = ValueTypeintPrimaryKey,
        TypeName = ValueTypestring,
        TxtRewardTitle = ValueTypestring,
        TxtDescTitle = ValueTypestring,
        IconPath = ValueTypestring,
        PrefabPath = ValueTypestring,
    },
    XTableCue = {
        Id = ValueTypeintPrimaryKey,
        CueSheetId = ValueTypeint,
        CueName = ValueTypestring,
        PlayType = ValueTypeint,
        Duration = ValueTypeint,
    },
    XTableCueSheet = {
        Id = ValueTypeintPrimaryKey,
        CueSheetName = ValueTypestring,
        CueAwb = ValueTypestring,
        HasAwb = ValueTypebool,
    },
    XTableCustomLoading = {
        Id = ValueTypeintPrimaryKey,
        Rate = ValueTypeint,
        AllowType = Type1ValueTypestring,
        BlockGroup = Type1ValueTypeint,
        UseSpine = ValueTypebool,
    },
    XTableCv = {
        Id = ValueTypeintPrimaryKey,
        Cvs = Type1ValueTypeint,
        CvContent = Type1ValueTypestring,
    },
    XTableCvSplit = {
        Id = ValueTypeintPrimaryKey,
        CvId = ValueTypeint,
        Cvs = ValueTypeint,
        Timing = ValueTypeint,
        Text = ValueTypestring,
    },
    XTableCvSplitRange = {
        Id = ValueTypeintPrimaryKey,
        Count = ValueTypeint,
    },
    XTableDailyDropGroup = {
        Id = ValueTypeintPrimaryKey,
        DungeonId = ValueTypeint,
        OpenDayOfWeek = ValueTypeint,
        Remark = ValueTypestring,
        RandomRewardId = ValueTypeint,
        FixedRewardId = ValueTypeint,
    },
    XTableDailyDungeonData = {
        Id = ValueTypeintPrimaryKey,
        Code = ValueTypestring,
        Name = ValueTypestring,
        Description = ValueTypestring,
        BgImg = ValueTypestring,
        Difficult = ValueTypeint,
        StageId = Type1ValueTypeint,
        ConditionId = Type1ValueTypeint,
        ShopId = ValueTypeint,
        SkipId = ValueTypeint,
        TagName = ValueTypestring,
        RedPointConditions = ValueTypestring,
    },
    XTableDailyDungeonRules = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Title = ValueTypestring,
        Describe = ValueTypestring,
        Remark = ValueTypestring,
        SpecialConditionId = Type1ValueTypeint,
        Priority = ValueTypeint,
        Icon = ValueTypestring,
        Bg = ValueTypestring,
        OpenDayOfWeek = Type1ValueTypeint,
        DungeonOfWeek = Type1ValueTypeint,
    },
    XTableDailyLottery = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        PrefabPath = ValueTypestring,
        RoundDays = Type1ValueTypeint,
        RoundIds = Type1ValueTypeint,
        OpenLevel = ValueTypeint,
        OpenStage = ValueTypeint,
        StartTimeStr = ValueTypestring,
        CloseTimeStr = ValueTypestring,
        MaxRecordCount = ValueTypeint,
        RuleTitle = Type1ValueTypestring,
        RuleContent = Type1ValueTypestring,
    },
    XTableDailyLotteryReward = {
        Id = ValueTypeintPrimaryKey,
        RoundId = ValueTypeint,
        RewardId = ValueTypeint,
        Weight = ValueTypeint,
        RewardText = ValueTypestring,
        RewardSignPath = ValueTypestring,
        RewardSignDesc = ValueTypestring,
    },
    XTableDailySpecialCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        IntParam = Type1ValueTypeint,
        StringParam = Type1ValueTypestring,
        Text = ValueTypestring,
    },
    XTableDamageTypeTip = {
        Id = ValueTypeintPrimaryKey,
        DamageTypeTip = ValueTypestring,
        IconPath = ValueTypestring,
    },
    XTableDEConfig = {
        Id = ValueTypeint,
        UiName = ValueTypestring,
        Type = ValueTypeint,
        Path = ValueTypestring,
    },
    XTableDevilMayCryActivity = {
        DrawId = ValueTypeintPrimaryKey,
        TaskGroupId = ValueTypeint,
    },
    XTableDiceAnimation = {
        Id = ValueTypeintPrimaryKey,
        TailFrames = Type1ValueTypestring,
    },
    XTableDiceGameActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        CoinItemId = ValueTypeint,
        CoinCost = ValueTypeint,
        HelpId = ValueTypeint,
        DiceCount = ValueTypeint,
    },
    XTableDiceGameEasterEgg = {
        Id = ValueTypeintPrimaryKey,
        ScoreRequired = ValueTypeint,
        PointRequired = Type1ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Text = ValueTypestring,
    },
    XTableDiceGameOperation = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Type = ValueTypeint,
        DescText = ValueTypestring,
        ResultText = ValueTypestring,
        CountText = ValueTypestring,
        FormulaText = ValueTypestring,
        ScoreRate = ValueTypeint,
        SelectionRate = ValueTypeint,
        FlagObtain = ValueTypeint,
        FlagRequired = ValueTypeint,
        FlagToScore = ValueTypeint,
    },
    XTableDiceGamePoint = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Weight = ValueTypeint,
        ImgPath = ValueTypestring,
    },
    XTableDiceGameReward = {
        Id = ValueTypeintPrimaryKey,
        ProgressRequired = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableDisplay = {
        Id = ValueTypeintPrimaryKey,
        Model = ValueTypestring,
        Action = ValueTypestring,
        ContentId = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableDisplayContent = {
        Id = ValueTypeintPrimaryKey,
        Sound = ValueTypeint,
        Text = ValueTypestring,
        Duration = ValueTypeint,
    },
    XTableDlcCasualActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Type = ValueTypeint,
        TutorialWorldId = ValueTypeint,
        TutorialLevelId = ValueTypeint,
        HelpId = ValueTypeint,
        CharacterPoolId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        TaskGroupIds = Type1ValueTypeint,
    },
    XTableDlcCasualChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        WorldIds = Type1ValueTypeint,
        LevelIds = Type1ValueTypeint,
        WorldDesc = Type1ValueTypestring,
    },
    XTableDlcCasualCharacterPool = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = Type1ValueTypeint,
    },
    XTableDlcCasualConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableDlcCasualScore = {
        WorldId = ValueTypeintPrimaryKey,
        JudgeScore = Type1ValueTypeint,
        JudgeName = Type1ValueTypestring,
        CubeRankMaxTeamScore = ValueTypeint,
    },
    XTableDlcCharacterCute = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        AttribId = ValueTypeint,
        Name = ValueTypestring,
        TradeName = ValueTypestring,
        HeadIcon = ValueTypestring,
        RoundHeadImage = ValueTypestring,
        MVPAction = ValueTypestring,
        VictoryAction = ValueTypestring,
        FailAction = ValueTypestring,
    },
    XTableDlcCheatDetection = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        DetectType = ValueTypeint,
        DetectMethod = ValueTypeint,
        IntParams = Type1ValueTypeint,
        FloatParams = Type1ValueTypefloat,
    },
    XTableDlcEnvironmentQuest = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        GroupId = ValueTypeint,
        Priority = ValueTypeint,
        RoleIcon = ValueTypestring,
        ShowReward = ValueTypeint,
        SkipId = ValueTypeint,
        PlaceId = ValueTypeint,
        ObjectiveIds = Type1ValueTypestring,
    },
    XTableDlcEnvironmentQuestGroup = {
        Id = ValueTypeintPrimaryKey,
        LevelId = ValueTypeint,
        Name = ValueTypestring,
        IsDefaultGroup = ValueTypebool,
    },
    XTableDlcEnvironmentQuestLevel = {
        LevelId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        ConditionId = ValueTypeint,
        GroupIds = Type1ValueTypeint,
    },
    XTableDlcHuntActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        BaseRankNum = ValueTypeint,
    },
    XTableDlcHuntAttribDesc = {
        Name = ValueTypestringPrimaryKey,
        Id = ValueTypeint,
        Type = ValueTypeint,
        Des = ValueTypestring,
        Power = ValueTypefloat,
        IsPercent = ValueTypebool,
        DescEn = ValueTypestring,
    },
    XTableDlcHuntAttrType = {
        AttrType = ValueTypeintPrimaryKey,
        Des = ValueTypestring,
    },
    XTableDlcHuntBadge = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Level = ValueTypeint,
        Name = ValueTypestring,
        Des = ValueTypestring,
        Icon = ValueTypestring,
        Condition = ValueTypeint,
    },
    XTableDlcHuntBossChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        NameEn = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        PreWorldId = ValueTypeint,
        WorldIds = Type1ValueTypeint,
        Index = ValueTypeint,
        ModelId = ValueTypestring,
        ModelId2 = ValueTypestring,
    },
    XTableDlcHuntBossDetail = {
        Id = ValueTypeintPrimaryKey,
        TipName = Type1ValueTypestring,
        TipDes = Type1ValueTypestring,
        TipAsset = Type1ValueTypestring,
    },
    XTableDlcHuntCharacter = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Name = ValueTypestring,
        TradeName = ValueTypestring,
        LogName = ValueTypestring,
        EnName = ValueTypestring,
        Icon = ValueTypestring,
        HalfBodyImage = ValueTypestring,
        Sex = ValueTypeint,
        Priority = ValueTypeint,
        EquipId = ValueTypeint,
        DefaultNpcFashionId = ValueTypeint,
        Code = ValueTypestring,
        Class = ValueTypeint,
        AttribId = ValueTypeint,
        Element = Type1ValueTypeint,
    },
    XTableDlcHuntCharacterDetail = {
        Id = ValueTypeintPrimaryKey,
        ElementName = ValueTypestring,
        ElementPath = ValueTypestring,
        WeaponName = ValueTypestring,
        WeaponPath = ValueTypestring,
    },
    XTableDlcHuntCharacterSkill = {
        CharacterId = ValueTypeintPrimaryKey,
        SkillIds = Type1ValueTypeint,
        Pos = Type1ValueTypeint,
    },
    XTableDlcHuntCharacterSkillLevelEffect = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Level = ValueTypeint,
        BornMagic = Type1ValueTypeint,
        SubSkillId = Type1ValueTypeint,
        SubMagicId = Type1ValueTypeint,
        Ability = ValueTypeint,
        ResonanceAbility = ValueTypeint,
        PlusAbility = ValueTypeint,
    },
    XTableDlcHuntCharacterSkillType = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
    },
    XTableDlcHuntChip = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Quality = ValueTypeint,
    },
    XTableDlcHuntChipAssist = {
        Id = ValueTypeintPrimaryKey,
        ChipId = ValueTypeint,
        Level = ValueTypeint,
        BreakTimes = ValueTypeint,
    },
    XTableDlcHuntChipBreakThrough = {
        Id = ValueTypeintPrimaryKey,
        ChipId = ValueTypeint,
        BreakTimes = ValueTypeint,
        LevelLimit = ValueTypeint,
        AttribId = ValueTypeint,
        AttribPromotedId = ValueTypeint,
        MagicEventIds = Type1ValueTypeint,
        MagicLevel = Type1ValueTypeint,
        LevelUpTemplateId = ValueTypeint,
        CostType = ValueTypeint,
        CostChipBreakTime = ValueTypeint,
        CostChipQuality = ValueTypeint,
        CostCount = ValueTypeint,
        OfferExp = ValueTypeint,
        ResolveItem = ValueTypeint,
        ResolveItemCount = ValueTypeint,
        ConsumeDes = ValueTypestring,
    },
    XTableDlcHuntChipClient = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IconPath = ValueTypestring,
        Priority = ValueTypeint,
        Model = ValueTypestring,
    },
    XTableDlcHuntChipLevelUpTemplate = {
        Id = ValueTypeintPrimaryKey,
        TemplateId = ValueTypeint,
        Level = ValueTypeint,
        Exp = ValueTypeint,
        AllExp = ValueTypeint,
    },
    XTableDlcHuntChipMagic = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Params = Type1ValueTypeint,
    },
    XTableDlcHuntDifficulty = {
        Id = ValueTypeintPrimaryKey,
        Des = Type1ValueTypestring,
        Bg = ValueTypestring,
        DifficultyLevel = ValueTypeint,
        DifficultyName = ValueTypestring,
        BossDetailId = ValueTypeint,
        BossDetailOnPause = ValueTypeint,
        RecommendAbility = ValueTypeint,
        EnName = ValueTypestring,
    },
    XTableDlcHuntElement = {
        Id = ValueTypeintPrimaryKey,
        ElementName = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        Icon2 = ValueTypestring,
    },
    XTableDlcHuntNetworkState = {
        Id = ValueTypeintPrimaryKey,
        DelayUpLimit = ValueTypeint,
    },
    XTableDlcHuntShareCfg = {
        Key = ValueTypestringPrimaryKey,
        IntValues = Type1ValueTypeint,
        FloatValues = Type1ValueTypefloat,
        StringValues = Type1ValueTypestring,
        Comment = ValueTypestring,
    },
    XTableDlcHuntSkillGate = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableDlcHuntSkillTeach = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        TeachIcon = ValueTypestring,
        HeadLine = Type2KeyTypeintValueTypestring,
        Description = Type2KeyTypeintValueTypestring,
    },
    XTableDlcHuntSkillTypeInfo = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableDlcHuntSkillUpgradeDes = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Level = ValueTypeint,
        Name = ValueTypestring,
        Intro = ValueTypestring,
        Icon = ValueTypestring,
        EntryId = Type1ValueTypeint,
        TypeDes = ValueTypestring,
        Tag = Type1ValueTypestring,
        Title = Type2KeyTypeintValueTypestring,
        BriefDes = Type2KeyTypeintValueTypestring,
        SpecificDes = Type2KeyTypeintValueTypestring,
    },
    XTableDlcHuntWorld = {
        WorldId = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        PreWorldId = ValueTypeint,
        Name = ValueTypestring,
        BgmId = ValueTypeint,
        EventId = ValueTypeint,
        LoadingType = ValueTypeint,
        FinishRewardShow = ValueTypeint,
        FinishDropId = ValueTypeint,
        FirstRewardId = ValueTypeint,
        OnlinePlayerLeast = ValueTypeint,
        OnlinePlayerLimit = ValueTypeint,
        SettleLoseTipId = ValueTypeint,
        Difficulty = ValueTypeint,
        IsRank = ValueTypeint,
        MatchPlayerCountThreshold = ValueTypeint,
        NeedFightPower = ValueTypeint,
        DifficultyId = ValueTypeint,
        RebootId = ValueTypeint,
        TeachingCharacterId = ValueTypeint,
        WorldType = ValueTypeint,
        MatchTimeoutSec = ValueTypeint,
    },
    XTableDlcInviteQuest = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        Condition = ValueTypeint,
        ModelId = ValueTypestring,
        RolePath = ValueTypestring,
        RoleIcon = ValueTypestring,
        AcceptMessageId = ValueTypeint,
        Type = ValueTypeint,
        ResultIds = Type1ValueTypeint,
        TotalRewardId = ValueTypeint,
        TipText = ValueTypestring,
        PopTipText = ValueTypestring,
    },
    XTableDlcInviteQuestResult = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Banner = ValueTypestring,
        CGAsset = ValueTypestring,
        RewardId = ValueTypeint,
    },
    XTableDlcList = {
        Id = ValueTypeintPrimaryKey,
        RootId = ValueTypeint,
        PatchConfigIds = Type1ValueTypeint,
        EntryType = ValueTypeint,
        EntryParam = ValueTypeint,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        ImgBanner = ValueTypestring,
    },
    XTableDlcMultiplayerActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        Type = ValueTypeint,
        ChapterGroupId = ValueTypeint,
        CharacterPoolId = ValueTypeint,
        TitleGroupId = ValueTypeint,
        HelpId = ValueTypeint,
        ShopIdList = Type1ValueTypeint,
        CatSkillGroup = ValueTypeint,
        MouseSkillGroup = ValueTypeint,
        BpGroupId = ValueTypeint,
        BpExpItem = ValueTypeint,
        BpDailyTask = Type1ValueTypeint,
        BpForeverTask = Type1ValueTypeint,
        DiscussionWinExp = ValueTypeint,
        DiscussionFailExp = ValueTypeint,
    },
    XTableDlcMultiplayerBp = {
        Lv = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        Exp = ValueTypeint,
        RewardId = ValueTypeint,
        MainReward = ValueTypeint,
    },
    XTableDlcMultiplayerChapter = {
        Id = ValueTypeintPrimaryKey,
        WorldIds = Type1ValueTypeint,
        LevelIds = Type1ValueTypeint,
    },
    XTableDlcMultiplayerChapterGroup = {
        Id = ValueTypeintPrimaryKey,
        ChapterIds = Type1ValueTypeint,
        RefreshHour = Type1ValueTypeint,
    },
    XTableDlcMultiPlayerCharacter = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        AttribId = ValueTypeint,
        ModelId = ValueTypestring,
        Name = ValueTypestring,
        TradeName = ValueTypestring,
        SquareHeadImage = ValueTypestring,
        RoundHeadImage = ValueTypestring,
        MvpAction = ValueTypestring,
        VictoryAction = ValueTypestring,
        FailAction = ValueTypestring,
    },
    XTableDlcMultiplayerCharacterPool = {
        Id = ValueTypeintPrimaryKey,
        CharacterIds = Type1ValueTypeint,
    },
    XTableDlcMultiplayerClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableDlcMultiplayerCondition = {
        Id = ValueTypeintPrimaryKey,
        Params = Type1ValueTypeint,
    },
    XTableDlcMultiplayerConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Param = Type1ValueTypestring,
    },
    XTableDlcMultiplayerDiscussion = {
        Id = ValueTypeintPrimaryKey,
        Discussion = ValueTypestring,
        DiscussionStartTime = ValueTypestring,
        DiscussionEndTime = ValueTypestring,
        VoteEndTime = ValueTypestring,
        DanmuCapacity = ValueTypeint,
        Camp1 = ValueTypestring,
        Camp2 = ValueTypestring,
        Camp1Des = ValueTypestring,
        Camp2Des = ValueTypestring,
        Camp1Icon = ValueTypestring,
        Camp2Icon = ValueTypestring,
        Camp1Ratio = Type1ValueTypeint,
        ShowRatioTime = Type1ValueTypestring,
    },
    XTableDlcMultiplayerReward = {
        Id = ValueTypeintPrimaryKey,
        Camp = ValueTypeint,
        Record = ValueTypeint,
        Currency = ValueTypeint,
    },
    XTableDlcMultiplayerSkill = {
        Id = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
        InitMagicId = ValueTypeint,
        MagicId = ValueTypeint,
        Icon = ValueTypestring,
        SkillCnt = ValueTypeint,
        SkillCd = ValueTypeint,
        Name = ValueTypestring,
        Des = ValueTypestring,
    },
    XTableDlcMultiplayerSkillGroup = {
        Id = ValueTypeintPrimaryKey,
        SkillIdList = Type1ValueTypeint,
    },
    XTableDlcMultiplayerTeam = {
        Id = ValueTypeintPrimaryKey,
        CatNum = Type2KeyTypeintValueTypeint,
    },
    XTableDlcMultiplayerTitle = {
        Id = ValueTypeintPrimaryKey,
        TitleContent = ValueTypestring,
        Background = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        IsProgress = ValueTypebool,
        EventType = ValueTypeint,
        Target = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableDlcMultiplayerTitleGroup = {
        Id = ValueTypeintPrimaryKey,
        TitleIds = Type1ValueTypeint,
    },
    XTableDlcMultiplayerWorld = {
        Id = ValueTypestringPrimaryKey,
        Icon = ValueTypestring,
        SceneUrl = ValueTypestring,
        SceneModelUrl = ValueTypestring,
        LoadingBackground = ValueTypestring,
        ArtName = ValueTypestring,
        MaskLoadingType = ValueTypestring,
        SettlementUiName = ValueTypestring,
    },
    XTableDlcQuestArchive = {
        Id = ValueTypeintPrimaryKey,
        QuestId = ValueTypeint,
        PreQuestId = ValueTypeint,
        Icon = ValueTypestring,
        CompleteText = ValueTypestring,
    },
    XTableDlcQuestChapter = {
        Id = ValueTypeintPrimaryKey,
        MapName = ValueTypestring,
        ChapterName = ValueTypestring,
        FullBg = ValueTypestring,
        ChapterUrl = ValueTypestring,
        ArchiveIds = Type1ValueTypeint,
    },
    XTableDlcQuestGroup = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        IncompleteText = ValueTypestring,
        Icon = ValueTypestring,
        Quest = Type1ValueTypeint,
    },
    XTableDlcQuestItem = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        WorldDescription = ValueTypestring,
        Icon = ValueTypestring,
        Quality = ValueTypeint,
        Priority = ValueTypeint,
        MaxCount = ValueTypeint,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableDlcQuestType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        BriefIcon = ValueTypestring,
        BigIcon = ValueTypestring,
        Priority = ValueTypeint,
        Color = ValueTypestring,
        MessageColor = ValueTypestring,
        PopType = ValueTypeint,
        PopTheme = ValueTypeint,
    },
    XTableDlcRelinkActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        WorldId = ValueTypeint,
        EmojiWheelMaxCount = ValueTypeint,
        DefaultSignId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        VideoConfigId = ValueTypeint,
        Tips = Type1ValueTypestring,
        TipIcons = Type1ValueTypestring,
        BattleCharacterIds = Type1ValueTypeint,
        NamePlateGroupId = ValueTypeint,
    },
    XTableDlcRelinkBossSkillDesc = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        VideoConfigId = ValueTypeint,
        Desc = ValueTypestring,
        Tags = Type1ValueTypestring,
    },
    XTableDlcRelinkBreak = {
        BreakEquipId = ValueTypeintPrimaryKey,
        FixOutputId = Type1ValueTypeint,
        FixOutputCount = Type1ValueTypeint,
        FactorOutputCount = Type1ValueTypeint,
    },
    XTableDlcRelinkChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Condition = Type1ValueTypeint,
        LevelIds = Type1ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        RoomIcon = ValueTypestring,
        Skills = Type1ValueTypeint,
        OdSkills = Type1ValueTypeint,
        TrueOccupations = Type1ValueTypeint,
        IsTutorial = ValueTypebool,
    },
    XTableDlcRelinkCharacter = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        StyleType = ValueTypeint,
        StyleName = ValueTypestring,
        StyleIcon = ValueTypestring,
        StyleDesc = ValueTypestring,
        OccupationType = ValueTypeint,
        IsDefaultTag = ValueTypebool,
        NpcId = ValueTypeint,
        Condition = Type1ValueTypeint,
        SkillIds = Type1ValueTypeint,
        JumpWikiId = ValueTypeint,
    },
    XTableDlcRelinkCharacterAttrib = {
        Key = ValueTypestringPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        IsPercent = ValueTypeint,
        Order = ValueTypeint,
    },
    XTableDlcRelinkClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Params = Type1ValueTypestring,
    },
    XTableDlcRelinkCompose = {
        Id = ValueTypeintPrimaryKey,
        EquipPoolIds = Type1ValueTypeint,
        PoolWeights = Type1ValueTypeint,
        PaceMaxs = Type1ValueTypeint,
        ConsumeIds = Type1ValueTypeint,
        ConsumeCounts = Type1ValueTypeint,
    },
    XTableDlcRelinkComposePool = {
        Id = ValueTypeintPrimaryKey,
        Quality = ValueTypeint,
        EquipIds = Type1ValueTypeint,
    },
    XTableDlcRelinkConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Param = Type1ValueTypestring,
    },
    XTableDlcRelinkDropGroup = {
        Id = ValueTypeintPrimaryKey,
        DropGroupId = ValueTypeint,
        RewardGroupId = ValueTypeint,
        ExtractNum = ValueTypeint,
        BaseWeight = ValueTypeint,
        AddWeight = Type1ValueTypeint,
        AddWeightPartIds = Type1ValueTypeint,
    },
    XTableDlcRelinkEquip = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Type = ValueTypeint,
        CharacterUid = ValueTypeint,
        EquipOccupationType = ValueTypeint,
        Quality = ValueTypeint,
        MainSkillFactorId = ValueTypeint,
        AddSlotNum = ValueTypeint,
        AddFactorLevel = ValueTypeint,
        MainFactorId = ValueTypeint,
        MainFactorLevel = Type1ValueTypeint,
        LevelWeights = Type1ValueTypeint,
        FactorAbility = Type1ValueTypeint,
        LevelTypes = Type1ValueTypeint,
        Ability = ValueTypeint,
    },
    XTableDlcRelinkEquipQuality = {
        Quality = ValueTypeintPrimaryKey,
        QualityAssets = ValueTypestring,
        QualityName = ValueTypestring,
        DeputyFactorNum = ValueTypeint,
        FactorRemoveNum = ValueTypeint,
        AbsorbFactorWeight = ValueTypeint,
        AbsorbFactorPaceMax = ValueTypeint,
    },
    XTableDlcRelinkEquipSkillFactor = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableDlcRelinkFactor = {
        Id = ValueTypeintPrimaryKey,
        FactorId = ValueTypeint,
        Type = ValueTypeint,
        Level = ValueTypeint,
        Params = Type1ValueTypeint,
        Desc = ValueTypestring,
        SkillDesc = ValueTypestring,
        AffectedSkillIds = Type1ValueTypeint,
        NewSkillIds = Type1ValueTypeint,
        SecondFactors = Type1ValueTypeint,
    },
    XTableDlcRelinkFactorDesc = {
        Id = ValueTypeintPrimaryKey,
        AttributeName = ValueTypestring,
        AttributeType = ValueTypeint,
        LevelOverlyingType = ValueTypeint,
        DetailShowType = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        IsPercent = ValueTypeint,
        MaxLevel = ValueTypeint,
        Order = ValueTypeint,
        Condition = Type1ValueTypeint,
        CharacterIcon = ValueTypestring,
    },
    XTableDlcRelinkLevel = {
        LevelId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        PreLevelId = ValueTypeint,
        ChapterId = ValueTypeint,
        Difficulty = ValueTypeint,
        TimeId = ValueTypeint,
        Condition = Type1ValueTypeint,
        IsRank = ValueTypebool,
        FirstDropIds = Type1ValueTypeint,
        DropIds = Type1ValueTypeint,
        FirstExp = ValueTypeint,
        Exp = ValueTypeint,
        FirstCoin = ValueTypeint,
        Coin = ValueTypeint,
        FirstGold = ValueTypeint,
        Gold = ValueTypeint,
        AbilityLimit = ValueTypeint,
        AttributeNames = Type1ValueTypestring,
        AttributeValues = Type1ValueTypeint,
        LoadingTips = Type1ValueTypestring,
        FirstShowGroupId = ValueTypeint,
        ShowGroupId = ValueTypeint,
        LockCharacterId = ValueTypeint,
    },
    XTableDlcRelinkMechanismTeach = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        MechanismId = ValueTypeint,
        LevelId = Type1ValueTypeint,
    },
    XTableDlcRelinkMedalTag = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Priority = ValueTypeint,
        CoverIds = Type1ValueTypeint,
        CompareKeys = Type1ValueTypeint,
        CompareValues = Type1ValueTypeint,
        CompareTypes = Type1ValueTypeint,
    },
    XTableDlcRelinkPlayerLevel = {
        Level = ValueTypeintPrimaryKey,
        Exp = ValueTypeint,
        CoinExpTransfer = ValueTypeint,
        NormalSlot = ValueTypeint,
        ExtraSlotLimit = ValueTypeint,
        ConditionId = ValueTypeint,
        AttributeNames = Type1ValueTypestring,
        AttributeValues = Type1ValueTypeint,
        FinishOneOfLevelIds = Type1ValueTypeint,
        ComposeId = ValueTypeint,
        IsMax = ValueTypeint,
    },
    XTableDlcRelinkRewardGroup = {
        Id = ValueTypeintPrimaryKey,
        RewardGroupId = ValueTypeint,
        RewardType = ValueTypeint,
        RewardId = ValueTypeint,
        RewardNum = ValueTypeint,
        LimitNum = ValueTypeint,
        BaseWeight = ValueTypeint,
        AddWeight = Type1ValueTypeint,
        AddWeightCondition = Type1ValueTypeint,
        CharacterUIdWeight = Type1ValueTypeint,
        CharacterUId = Type1ValueTypeint,
    },
    XTableDlcRelinkShopTask = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        ParamId = Type1ValueTypeint,
    },
    XTableDlcRelinkShowLevelDrop = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Quality = ValueTypeint,
    },
    XTableDlcRelinkSign = {
        Id = ValueTypeintPrimaryKey,
        MaxGainLimitCount = ValueTypeint,
        RewardIds = Type1ValueTypeint,
        RewardGroupId = ValueTypeint,
        ExtractNum = ValueTypeint,
        Condition = Type1ValueTypeint,
    },
    XTableDlcRelinkSkillDesc = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Subtitle = ValueTypestring,
        Desc = ValueTypestring,
        DescNum = ValueTypestring,
        SimpleDesc = ValueTypestring,
        SimpleDescNum = ValueTypestring,
        TypeDesc = ValueTypestring,
        Icon = ValueTypestring,
        Cd = ValueTypeint,
        BaseDamageLimit = ValueTypeint,
        Rate = ValueTypeint,
        AttribType = ValueTypeint,
        Tags = Type1ValueTypestring,
        EntryName = Type1ValueTypestring,
        EntryDesc = Type1ValueTypestring,
        VideoConfigId = ValueTypeint,
        SecondSkill = Type1ValueTypeint,
    },
    XTableDlcRelinkSummaryFactor = {
        Id = ValueTypeintPrimaryKey,
        Factor = ValueTypefloat,
    },
    XTableDlcRelinkTextEmoji = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Text = ValueTypestring,
        EmojiId = ValueTypeint,
        DefaultCanUse = ValueTypebool,
    },
    XTableDlcRelinkWiki = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        ConditionId = ValueTypeint,
        VideoConfigIds = Type2KeyTypeintValueTypestring,
        ImageUrl = Type2KeyTypeintValueTypestring,
        Desc = Type2KeyTypeintValueTypestring,
    },
    XTableDlcServerStageThreadMaxLoad = {
        StageNo = ValueTypeintPrimaryKey,
        MaxLoad = ValueTypeint,
    },
    XTableDlcWorld = {
        WorldId = ValueTypeintPrimaryKey,
        WorldType = ValueTypeint,
        ChapterId = ValueTypeint,
        PreWorldId = ValueTypeint,
        Name = ValueTypestring,
        BgmId = ValueTypeint,
        EventId = ValueTypeint,
        LoadingType = ValueTypeint,
        FinishRewardShow = ValueTypeint,
        FinishDropId = ValueTypeint,
        FirstRewardId = ValueTypeint,
        TeamPlayerLeast = ValueTypeint,
        TeamPlayerLimit = ValueTypeint,
        OnlinePlayerLeast = ValueTypeint,
        OnlinePlayerLimit = ValueTypeint,
        SettleLoseTipId = ValueTypeint,
        IsRank = ValueTypeint,
        MatchPlayerCountThreshold = ValueTypeint,
        NeedFightPower = ValueTypeint,
        DifficultyId = ValueTypeint,
        SettingDetailId = ValueTypeint,
        RebootId = ValueTypeint,
        TeachingCharacterId = ValueTypeint,
        MatchTimeoutSec = ValueTypeint,
        MatchStrategy = ValueTypeint,
        CheatDetectionGroupId = ValueTypeint,
        MinFightPlayerCount = ValueTypeint,
    },
    XTableDlcWorldSettingDetail = {
        Id = ValueTypeintPrimaryKey,
        TipName = Type1ValueTypestring,
        TipDes = Type1ValueTypestring,
        TipAsset = Type1ValueTypestring,
    },
    XTableDoomsdayActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BannerBg = ValueTypestring,
        OpenTimeId = ValueTypeint,
        StageId = Type1ValueTypeint,
        TaskGroupId = ValueTypeint,
        DiaryTaskGroupId = ValueTypeint,
    },
    XTableDoomsdayAttribute = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Threshold = ValueTypeint,
        ResourceId = ValueTypeint,
        DailyRequireResourceCount = ValueTypeint,
        DailyChangeValue = ValueTypeint,
        DailyChangeValueWhenNoHome = ValueTypeint,
        DailyChangeValueWhenHungery = ValueTypeint,
        DailyChangeValueWhenSick = ValueTypeint,
        DailyRecoveryRatio = ValueTypeint,
    },
    XTableDoomsdayAttributeType = {
        Id = ValueTypeintPrimaryKey,
        MaxValue = ValueTypeint,
        Name = ValueTypestring,
        BadName = ValueTypestring,
        BadIcon = ValueTypestring,
    },
    XTableDoomsdayBroadcast = {
        Type = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        Duration = ValueTypeint,
    },
    XTableDoomsdayBuilding = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        MaxNum = ValueTypeint,
        FinishDayCount = ValueTypeint,
        WorkDayCount = ValueTypeint,
        SpendResourceType = Type1ValueTypeint,
        SpendResourceCount = Type1ValueTypeint,
        WorkingDailyConsumeResourceId = Type1ValueTypeint,
        WorkingDailyConsumeResourceCount = Type1ValueTypeint,
        WorkingDailyGainResourceId = Type1ValueTypeint,
        WorkingDailyGainResourceCount = Type1ValueTypeint,
        LockPeopleOnBuilding = ValueTypeint,
        LockPeopleOnWorking = ValueTypeint,
        ExtendPeopleNumber = ValueTypeint,
        WorkingEffectId = Type1ValueTypeint,
        CanManualRemove = ValueTypebool,
        UnlockCondition = ValueTypeint,
    },
    XTableDoomsdayCfg = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypeint,
        Comment = ValueTypestring,
    },
    XTableDoomsdayCondition = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        Args = Type1ValueTypeint,
    },
    XTableDoomsdayCreateTeam = {
        Id = ValueTypeintPrimaryKey,
        CostInhabitantCount = ValueTypeint,
        SpendResourceType = Type1ValueTypeint,
        SpendResourceCount = Type1ValueTypeint,
    },
    XTableDoomsdayEffect = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Trigger = ValueTypeint,
        EffectType = ValueTypeint,
        Args = Type1ValueTypeint,
        SourceType = Type1ValueTypeint,
        SourceCount = Type1ValueTypeint,
        TargetType = Type1ValueTypeint,
        TargetCount = Type1ValueTypeint,
    },
    XTableDoomsdayEvent = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Title = ValueTypestring,
        EventType = ValueTypeint,
        ActiveConditionId = Type1ValueTypeint,
        Mutex = ValueTypebool,
        EffectId = Type1ValueTypeint,
        SubEventId = Type1ValueTypeint,
        SubConditionId = Type1ValueTypeint,
        AutoPopup = ValueTypebool,
        ForceFinish = ValueTypebool,
    },
    XTableDoomsdayReportText = {
        Id = ValueTypeintPrimaryKey,
        Desc = Type1ValueTypestring,
    },
    XTableDoomsdayResource = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        MaxCount = ValueTypestring,
        CanAllot = ValueTypebool,
    },
    XTableDoomsdayResourceAllot = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Tips = ValueTypestring,
    },
    XTableDoomsdayStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Order = ValueTypestring,
        Desc = ValueTypestring,
        PreStage = ValueTypeint,
        OpenTime = ValueTypeint,
        PrefabPath = ValueTypestring,
        FirstPlace = ValueTypeint,
        PlaceId = Type1ValueTypeint,
        DayCount = ValueTypeint,
        MaxBuildingCount = ValueTypeint,
        Effect = Type1ValueTypeint,
        PlaceIReadOnlyList = Type1ValueTypeint,
        TaskPool = Type1ValueTypeint,
        MainTaskId = ValueTypeint,
        SubTaskId = Type1ValueTypeint,
        EffectIds = Type1ValueTypeint,
        BuildingIds = Type1ValueTypeint,
        EndingId = Type1ValueTypeint,
        WeatherModeId = Type1ValueTypeint,
        WeatherModeWeight = Type1ValueTypeint,
        PossibleWeather = Type1ValueTypeint,
    },
    XTableDoomsdayStageDay = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Day = ValueTypeint,
        BasicEvent = Type1ValueTypeint,
        RandomEventCount = ValueTypeint,
        RandomEvent = Type1ValueTypeint,
        RandomEventWeight = Type1ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTableDoomsdayStageEnding = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        EventId = ValueTypeint,
        IsSuccess = ValueTypebool,
        ConditionId = ValueTypeint,
    },
    XTableDoomsdayStagePlace = {
        Id = ValueTypeintPrimaryKey,
        Pos = ValueTypeint,
        PrePlaceId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        CanGetPeople = ValueTypebool,
        ResourceId = Type1ValueTypeint,
        UnlockCondition = Type1ValueTypeint,
        EventId = Type1ValueTypeint,
        StageId = ValueTypeint,
    },
    XTableDoomsdayStructure = {
        Id = ValueTypeintPrimaryKey,
        EffectId = Type1ValueTypeint,
    },
    XTableDoomsdayTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Tips = Type1ValueTypestring,
        Round = ValueTypeint,
        ActivityConditionId = ValueTypeint,
        FinishCondition = ValueTypeint,
        FinishEffect = Type1ValueTypeint,
        FailedEffect = Type1ValueTypeint,
    },
    XTableDoomsdayTaskCondition = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        Trigger = ValueTypeint,
        Args = Type1ValueTypeint,
        MaxValue = ValueTypeint,
    },
    XTableDoomsdayWeather = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Temperature = ValueTypestring,
        Icon = ValueTypestring,
        BigIcon = ValueTypestring,
        EffectPath = ValueTypestring,
        AttributeId = Type1ValueTypeint,
        EventId = Type1ValueTypeint,
        NoRepeat = Type1ValueTypebool,
        EventWeight = Type1ValueTypeint,
    },
    XTableDoomsdayWeatherMode = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        DayCount = ValueTypeint,
        WeatherId = Type1ValueTypeint,
    },
    XTableDormActorDialog = {
        Id = ValueTypeintPrimaryKey,
        ActorId = ValueTypeint,
        MoodMinValue = ValueTypeint,
        MoodMaxValue = ValueTypeint,
        State = ValueTypestring,
        Content = Type1ValueTypestring,
        Time = Type1ValueTypeint,
    },
    XTableDormActorStateToDialog = {
        StateId = ValueTypeintPrimaryKey,
        DialogId = Type1ValueTypeint,
    },
    XTableDormActorToState = {
        ActorId = ValueTypeintPrimaryKey,
        StateName = Type1ValueTypestring,
        StateId = Type1ValueTypeint,
    },
    XTableDormBgm = {
        Id = ValueTypeintPrimaryKey,
        BgmId = ValueTypeint,
        SuitNum = ValueTypeint,
        SuitId = ValueTypeint,
        Name = ValueTypestring,
        Order = ValueTypeint,
    },
    XTableDormCharacterAction = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        State = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableDormCharacterBehavior = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        State = ValueTypestring,
        BehaviorId = ValueTypestring,
        CanClick = ValueTypeint,
        StateMachine = ValueTypestring,
    },
    XTableDormCharacterEffect = {
        Id = ValueTypeintPrimaryKey,
        Path = ValueTypestring,
        Hight = ValueTypefloat,
        Bind = ValueTypeint,
    },
    XTableDormCharacterEvent = {
        EventId = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Type = ValueTypeint,
        Weight = ValueTypeint,
        BehaviorId = ValueTypestring,
        HappenReward = ValueTypeint,
        FinishReward = ValueTypeint,
        ConditionList = Type1ValueTypeint,
        CompletedType = Type1ValueTypeint,
    },
    XTableDormCharacterEventReward = {
        Id = ValueTypeint,
        BuffId = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableDormCharacterEventType = {
        Id = ValueTypeint,
        CompareOrder = ValueTypeint,
        EventType = ValueTypeint,
        EventNum = ValueTypeint,
        Condition = Type1ValueTypeint,
        CharacterNum = ValueTypeint,
        CharacterCondition = Type1ValueTypeint,
    },
    XTableDormCharacterFondle = {
        CharacterId = ValueTypeintPrimaryKey,
        MaxCount = ValueTypeint,
        RecoveryTime = ValueTypeint,
        Lower = Type1ValueTypeint,
        Upper = Type1ValueTypeint,
    },
    XTableDormCharacterMood = {
        Id = ValueTypeintPrimaryKey,
        MoodMinValue = ValueTypeint,
        MoodMaxValue = ValueTypeint,
        Describe = ValueTypestring,
        Color = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableDormCharacterMoodBuff = {
        Id = ValueTypeint,
        Type = ValueTypeint,
        Interval = ValueTypeint,
        MaxCount = ValueTypeint,
        Speed = ValueTypeint,
    },
    XTableDormCharacterRecovery = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        VitalityRecoveryType = ValueTypeint,
        VitalityRecovery = ValueTypeint,
        MoodRecoveryType = ValueTypeint,
        MoodRecovery = ValueTypeint,
        Pre = ValueTypeint,
        CompareType = ValueTypeint,
        AttrTotal = ValueTypeint,
        AttrCondition = Type2KeyTypeintValueTypeint,
        Description = ValueTypestring,
    },
    XTableDormCharacterReward = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Name = ValueTypestring,
        Quality = ValueTypeint,
        ConvertItemId = ValueTypeint,
        ConvertItemCount = ValueTypeint,
        Icon = ValueTypestring,
        SmallIcon = ValueTypestring,
        Description = ValueTypestring,
        WorldDescription = ValueTypestring,
    },
    XTableDormCharacterState = {
        StateName = ValueTypestringPrimaryKey,
        StateId = ValueTypeint,
    },
    XTableDormCharacterStyle = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Model = ValueTypestring,
        Name = ValueTypestring,
        NameFrist = ValueTypestring,
        NameLast = ValueTypestring,
        HeadIcon = ValueTypestring,
        HeadRoundIcon = ValueTypestring,
        ExpFondleWidgetHeight = ValueTypefloat,
        ExpDetailWidgetHeight = ValueTypefloat,
        PutOnWidgetHight = ValueTypefloat,
        DailogWidgetHight = ValueTypefloat,
        DailogTouchHight = ValueTypefloat,
        EffectWidgetHight = ValueTypefloat,
        TouchWidgetHight = ValueTypefloat,
        LoveType = ValueTypeint,
        LikeType = ValueTypeint,
        LikeCharIds = Type1ValueTypeint,
        HateCharIds = Type1ValueTypeint,
        LikePetIds = Type1ValueTypeint,
        QuestAttrib = Type1ValueTypeint,
    },
    XTableDormCharacterWithState = {
        Id = ValueTypeintPrimaryKey,
        BehaviorId = ValueTypeint,
    },
    XTableDormCharacterWork = {
        DormitoryNum = ValueTypeintPrimaryKey,
        ItemId = ValueTypeint,
        Vitality = ValueTypeint,
        Time = ValueTypeint,
        Seat = ValueTypeint,
        Mood = ValueTypeint,
        ExtraReward = ValueTypeint,
    },
    XTableDormClientConfig = {
        Id = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableDormEventCondition = {
        Id = ValueTypeint,
        Type = ValueTypeint,
        Param = Type1ValueTypeint,
    },
    XTableDormExceptionItem = {
        Id = ValueTypeintPrimaryKey,
        ConvertId = ValueTypeint,
        ConvertCount = ValueTypeint,
    },
    XTableDormF2CBehaviorRelation = {
        Id = ValueTypeintPrimaryKey,
        FurnitureId = ValueTypeint,
        CharacterId = ValueTypeint,
        PositionId = ValueTypeint,
        Behavior = Type1ValueTypestring,
        BehaviorWeight = Type1ValueTypeint,
        AttractBehavior = Type1ValueTypestring,
        AttractBehaviorWeight = Type1ValueTypeint,
    },
    XTableDormFunitureAnimation = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = Type1ValueTypeint,
        CharacterAnimationName = Type1ValueTypestring,
        ClickType = ValueTypeint,
        OnceAnimationName = ValueTypestring,
        RepaatAnimationName = Type1ValueTypestring,
    },
    XTableDormFurnitureRimMat = {
        Key = ValueTypestringPrimaryKey,
        HighlightColor = ValueTypestring,
        MinHighLightLevel = ValueTypefloat,
        MaxHighLightLevel = ValueTypefloat,
        HighlightSpeed = ValueTypefloat,
        ColorIntensity = ValueTypefloat,
        Alpha = ValueTypefloat,
    },
    XTableDormFurnitureTagType = {
        Id = ValueTypeintPrimaryKey,
        TagName = ValueTypestring,
        AttrIndex = ValueTypeint,
    },
    XTableDormFurnitureType = {
        Id = ValueTypeintPrimaryKey,
        TypeName = ValueTypestring,
        TypeIcon = ValueTypestring,
        Color = ValueTypestring,
    },
    XTableDormGuideTask = {
        Id = ValueTypeintPrimaryKey,
        TaskId = ValueTypeint,
    },
    XTableDormInteractiveEvent = {
        Id = ValueTypeintPrimaryKey,
        Weight = ValueTypeint,
        MinDis = ValueTypeint,
        MaxDis = ValueTypeint,
        CharacterIds = Type1ValueTypeint,
        State = Type1ValueTypestring,
    },
    XTableDormInteractiveRelation = {
        ActiveRoleId = ValueTypeintPrimaryKey,
        PassiveRoleId = Type1ValueTypeint,
        InteractiveId = Type1ValueTypeint,
    },
    XTableDormitory = {
        Id = ValueTypeintPrimaryKey,
        IsFree = ValueTypeint,
        SceneId = ValueTypeint,
        Width = ValueTypeint,
        Height = ValueTypeint,
        CharCapacity = ValueTypeint,
        BigFurnitureCapacity = ValueTypeint,
        SmallFurnitureCapacity = ValueTypeint,
        DecorateCapacity = ValueTypeint,
        PetCapacity = ValueTypeint,
        ShieldCapacity = ValueTypeint,
        ConsumeItemId = ValueTypeint,
        ConsumeItemCount = ValueTypeint,
        InitNumber = ValueTypeint,
        InitName = ValueTypestring,
        InitFurniture = Type1ValueTypeint,
        InitFurniturePos = Type1ValueTypestring,
    },
    XTableDormPet = {
        Id = ValueTypeintPrimaryKey,
        TypeId = ValueTypeint,
        Model = ValueTypestring,
        Name = ValueTypestring,
        HeadRoundIcon = ValueTypestring,
        HeadIcon = ValueTypestring,
        CommingDormCueId = ValueTypeint,
        InteractPos = ValueTypeint,
        DialogWidgetHeight = ValueTypefloat,
        DialogTouchHeight = ValueTypefloat,
        EffectWidgetHeight = ValueTypefloat,
        BehaviorType = Type1ValueTypestring,
        AttractBehaviorType = Type1ValueTypestring,
    },
    XTableDormPetBehaviour = {
        Id = ValueTypeintPrimaryKey,
        PetId = ValueTypeint,
        State = ValueTypestring,
        BehaviorId = ValueTypestring,
        CanClick = ValueTypeint,
        StateMachine = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableDormRecommendLevel = {
        LevelId = ValueTypeint,
        LowerLimit = ValueTypeint,
        UpperLimit = ValueTypeint,
    },
    XTableDormRecommendSearch = {
        Level = ValueTypeint,
        RecommendList = Type1ValueTypeint,
    },
    XTableDormSecondMenu = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        FunctionName = ValueTypestring,
        IconPath = ValueTypestring,
        Order = ValueTypeint,
        Ignore = ValueTypeint,
    },
    XTableDormShowEvent = {
        Id = ValueTypeintPrimaryKey,
        ShowType = ValueTypeint,
        Description = Type1ValueTypestring,
        State = ValueTypestring,
    },
    XTableDormTemplate = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Order = ValueTypeint,
        IsShow = ValueTypebool,
        ShowTimeStr = ValueTypestring,
        PicturePath = ValueTypestring,
        FurnitureId = Type1ValueTypeint,
        FurniturePos = Type1ValueTypestring,
    },
    XTableDormTemplateCollect = {
        Id = ValueTypeintPrimaryKey,
        DefaultName = ValueTypestring,
        DefaultIcon = ValueTypestring,
        SkipTemplateId = ValueTypeint,
        CaptureCameraId = ValueTypeint,
        Order = ValueTypeint,
    },
    XTableDormTemplateGroup = {
        Id = ValueTypeintPrimaryKey,
        SecondIndex = ValueTypeint,
        Name = ValueTypestring,
        HasScond = ValueTypebool,
        SecondTagType = ValueTypeint,
        DormType = ValueTypeint,
        BtnIcon = ValueTypestring,
        DormId = Type1ValueTypeint,
    },
    XTableDoubleTowerActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BannerBg = ValueTypestring,
        OpenTimeId = ValueTypeint,
        RewardInitNum = ValueTypeint,
        RewardTimer = ValueTypeint,
        RewardItemId = ValueTypeint,
        RewardItemCount = ValueTypeint,
        RewardMaxCount = ValueTypeint,
        RolePluginMaxCount = ValueTypeint,
        GuardPluginMaxCount = ValueTypeint,
        HelpKey = ValueTypestring,
    },
    XTableDoubleTowerGuard = {
        Id = ValueTypeintPrimaryKey,
        PluginLevelId = Type1ValueTypeint,
        SlotPluginType = ValueTypeint,
        PreStageId = Type1ValueTypeint,
        SlotPreStageId = Type1ValueTypeint,
        NPCId = Type1ValueTypeint,
        Icon = Type1ValueTypestring,
        SmallIcon = Type1ValueTypestring,
    },
    XTableDoubleTowerInformation = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        BossImage = ValueTypestring,
        TypeDesc = ValueTypestring,
        RoundDesc = ValueTypestring,
    },
    XTableDoubleTowerPlugin = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Type = ValueTypeint,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableDoubleTowerPluginLevel = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        PluginId = ValueTypeint,
        Level = ValueTypeint,
        UpgradeSpend = ValueTypeint,
        FightEventId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableDoubleTowerRole = {
        Id = ValueTypeintPrimaryKey,
        SlotPluginType = ValueTypeint,
        PluginLevelId = Type1ValueTypeint,
        PreStage = Type1ValueTypeint,
        SlotPreStageId = Type1ValueTypeint,
        Icon = Type1ValueTypestring,
        DefaultPlugin = ValueTypeint,
    },
    XTableDoubleTowerStage = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        PreStageId = ValueTypeint,
        FightEventId = ValueTypeint,
        Name = ValueTypestring,
        BuffDesc = ValueTypestring,
    },
    XTableDoubleTowerStageGroup = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        OpenTimeId = ValueTypeint,
        IsSpecial = ValueTypebool,
        PreStageId = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableDragPuzzleActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        HelpId = ValueTypeint,
        ItemId = ValueTypeint,
    },
    XTableDragPuzzleActivityPassword = {
        Id = ValueTypeintPrimaryKey,
        PuzzleId = ValueTypeint,
        Password = Type1ValueTypeint,
        PasswordHint = ValueTypestring,
        HintMessage = Type1ValueTypestring,
        DecryptionImgUrl = ValueTypestring,
    },
    XTableDragPuzzleActivityPiece = {
        Id = ValueTypeintPrimaryKey,
        PuzzleId = ValueTypeint,
        CorrectIdx = ValueTypeint,
        FragmentUrl = ValueTypestring,
    },
    XTableDragPuzzleActivityPuzzle = {
        Id = ValueTypeintPrimaryKey,
        ActId = ValueTypeint,
        Name = ValueTypestring,
        SubName = ValueTypestring,
        RowSize = ValueTypeint,
        ColSize = ValueTypeint,
        PieceItemCount = ValueTypeint,
        BgUrl = ValueTypestring,
        CompleteStoryId = ValueTypestring,
        CompleteRewardId = ValueTypeint,
        CompleteHintText = ValueTypestring,
        RewardPiecesStr = Type1ValueTypestring,
        RewardId = Type1ValueTypeint,
        CompleteImageUrl = ValueTypestring,
        PuzzleType = ValueTypeint,
    },
    XTableDrawActivityTargetRoleBg = {
        Quality = ValueTypeintPrimaryKey,
        BgUrl = ValueTypestring,
        ProbabilityBgUrl = ValueTypestring,
    },
    XTableDrawActivityTargetShow = {
        Id = ValueTypeintPrimaryKey,
        TabDesc = ValueTypestring,
        Title = Type1ValueTypestring,
        Desc = Type1ValueTypestring,
        BannerPrefab = ValueTypestring,
        ActiveTipTxt = ValueTypestring,
        RuleTipTxt = ValueTypestring,
    },
    XTableDrawAdjustActivity = {
        Id = ValueTypeintPrimaryKey,
        StartTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
        AdjustTimes = ValueTypeint,
        DrawGroupId = ValueTypeint,
        SourceTemplateIds = Type1ValueTypeint,
        TargetTemplateIds = Type1ValueTypeint,
    },
    XTableDrawAimProbability = {
        Id = ValueTypeintPrimaryKey,
        Priority = ValueTypeint,
        UpProbability = ValueTypestring,
        UpProbabilityDesc = ValueTypestring,
        UpProbabilityPercent = ValueTypestring,
        Bg = ValueTypestring,
        ProbabilityBg = ValueTypestring,
        IsChangePos = ValueTypeint,
        IconPosX = ValueTypefloat,
        IconPosY = ValueTypefloat,
        IsChangeSize = ValueTypeint,
        IconWidth = ValueTypefloat,
        IconHeight = ValueTypefloat,
        IsChangeRot = ValueTypeint,
        RotZ = ValueTypefloat,
        NewTimeId = ValueTypeint,
    },
    XTableDrawCamera = {
        Id = ValueTypeintPrimaryKey,
        AllowHDR = ValueTypebool,
        Intensity = ValueTypefloat,
        Threshold = ValueTypefloat,
        Saturation = ValueTypefloat,
        SoftKnee = ValueTypefloat,
        Radius = ValueTypefloat,
        Iterations = ValueTypeint,
    },
    XTableDrawCanLiverActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        DrawIds = Type1ValueTypeint,
        RewardMailId = ValueTypeint,
        Schedules = Type1ValueTypeint,
        RewardIds = Type1ValueTypeint,
    },
    XTableDrawCharacterImage = {
        Id = ValueTypeintPrimaryKey,
        DrawShowRImg = ValueTypestring,
    },
    XTableDrawClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        ValueList = Type1ValueTypestring,
    },
    XTableDrawCombinations = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        GoodsId = Type1ValueTypeint,
    },
    XTableDrawExtraTagGroup = {
        Id = ValueTypeintPrimaryKey,
        Tag = ValueTypeint,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableDrawGoodsLimit = {
        Id = ValueTypeint,
        MinTimes = ValueTypeint,
        MaxTimes = ValueTypeint,
        LimitCount = ValueTypeint,
        UsePoolId = ValueTypeint,
    },
    XTableDrawGoodsLimitPool = {
        Id = ValueTypeint,
        PoolId = ValueTypeint,
        GoodsId = ValueTypeint,
    },
    XTableDrawGroupLogName = {
        Id = ValueTypeint,
        LogName = ValueTypestring,
    },
    XTableDrawGroupRelation = {
        NormalGroupId = ValueTypeintPrimaryKey,
        DestinyGroupId = ValueTypeint,
    },
    XTableDrawGroupRule = {
        Id = ValueTypeintPrimaryKey,
        TitleCN = ValueTypestring,
        TitleEN = ValueTypestring,
        RareRank = ValueTypeint,
        GroupBtnBg = ValueTypestring,
        MainRules = Type1ValueTypestring,
        BaseRuleTitles = Type1ValueTypestring,
        BaseRules = Type1ValueTypestring,
        EventRuleTitles = Type1ValueTypestring,
        EventRules = Type1ValueTypestring,
        UpType = ValueTypestring,
        UpQuality = ValueTypestring,
        UpProbability = ValueTypestring,
        BottomText = ValueTypestring,
        NewHandBottomCount = ValueTypeint,
        SpecialBottomMin = ValueTypeint,
        SpecialBottomMax = ValueTypeint,
        DrawBottomHint = ValueTypestring,
        IsNotSelectDefault = ValueTypebool,
        IsShowFilter = ValueTypeint,
        CharFilterElementList = Type1ValueTypeint,
        DrawRules = Type1ValueTypestring,
        IsCharacterImage = ValueTypeint,
        DrawName = ValueTypestring,
        DrawGroupName = ValueTypestring,
    },
    XTableDrawNewPlayerAssignTag = {
        CharacterId = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        TagText = ValueTypestring,
        IsRecommend = ValueTypebool,
    },
    XTableDrawPower = {
        DrawId = ValueTypeintPrimaryKey,
        Params = ValueTypeint,
    },
    XTableDrawPredict = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ShowUpTime = ValueTypestring,
        CharacterId = Type1ValueTypeint,
    },
    XTableDrawPredictPos = {
        CharacterId = ValueTypeintPrimaryKey,
        PosX = ValueTypefloat,
        PosY = ValueTypefloat,
        Width = ValueTypefloat,
        Height = ValueTypefloat,
    },
    XTableDrawPreview = {
        Id = ValueTypeintPrimaryKey,
        UpGoodsId = Type1ValueTypeint,
        GoodsId = Type1ValueTypeint,
    },
    XTableDrawProbShow = {
        DrawId = ValueTypeintPrimaryKey,
        IsUp = Type1ValueTypebool,
        Name = Type1ValueTypestring,
        Type = Type1ValueTypestring,
        ProbShow = Type1ValueTypestring,
        Sort = Type1ValueTypeint,
    },
    XTableDrawRolePerformance = {
        Id = ValueTypeintPrimaryKey,
        VoiceId = ValueTypeint,
        TimelinePath = ValueTypestring,
        CharacterPrefabPath = ValueTypestring,
        WeaponPrefabPaths = Type2KeyTypeintValueTypestring,
        WeaponMountBoneNames = Type2KeyTypeintValueTypestring,
        CameraPrefabPath = ValueTypestring,
        MainCameraPrefabPath = ValueTypestring,
        UiShowTime = ValueTypefloat,
        EffectPrefabPaths = Type2KeyTypeintValueTypestring,
        EffectBoneNames = Type2KeyTypeintValueTypestring,
    },
    XTableDrawScene = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        ModelId = ValueTypestring,
        ScenePath = ValueTypestring,
        UiModelPath = ValueTypestring,
        ModelPosition = ValueTypestring,
        ModelRotation = ValueTypestring,
        ModelScale = ValueTypestring,
        IsHideWeapon = ValueTypeint,
        DrawTreePv = ValueTypeint,
    },
    XTableDrawShow = {
        Type = ValueTypeintPrimaryKey,
        TypeText = ValueTypestring,
        QualityText = Type1ValueTypestring,
        UiAnim = ValueTypestring,
        UiResultAnim = ValueTypestring,
        DrawEffectGroupId = Type1ValueTypeint,
        GachaEffectGroupId = Type1ValueTypeint,
        DrawPictureGroupId = Type1ValueTypeint,
    },
    XTableDrawShowCharacter = {
        Id = ValueTypeintPrimaryKey,
        AnimeID = ValueTypestring,
        VoiceId = ValueTypeint,
    },
    XTableDrawShowEffect = {
        EffectGroupId = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        PanelOpenUp = ValueTypestring,
        PanelOpenDown = ValueTypestring,
        PanelCardShowOff = ValueTypestring,
        EffectOpenBox = ValueTypestring,
        SkipEffect = ValueTypestring,
        CarriageEffect = ValueTypestring,
        FloorEffect = ValueTypestring,
        CardEffectStart = ValueTypestring,
        CardEffect = ValueTypestring,
        ApertureEffect = ValueTypestring,
        CardEffectSound = ValueTypeint,
    },
    XTableDrawShowPicture = {
        GroupId = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        Bg = ValueTypestring,
        HalfBg = ValueTypestring,
        NameBg = ValueTypestring,
    },
    XTableDrawSkip = {
        DrawId = ValueTypeintPrimaryKey,
        SkipId = ValueTypeint,
    },
    XTableDrawTabs = {
        Id = ValueTypeintPrimaryKey,
        TxtName1 = ValueTypestring,
        TxtName2 = ValueTypestring,
        TxtName3 = ValueTypestring,
        TxtTagName = ValueTypestring,
        TabBg = ValueTypestring,
        Priority = ValueTypeint,
        ParentName = ValueTypestring,
        Condition = Type1ValueTypeint,
        IsLifeTreePower = ValueTypeint,
    },
    XTableDrawTicket = {
        Id = ValueTypeintPrimaryKey,
        EffectType = ValueTypeint,
        EffectParamStr = ValueTypestring,
        DrawGroupIds = Type1ValueTypeint,
        FreeNum = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        WorldDescription = ValueTypestring,
        Icon = ValueTypestring,
        BigIcon = ValueTypestring,
        Quality = ValueTypeint,
    },
    XTableDrawTypeChange = {
        MainGroupId = ValueTypeintPrimaryKey,
        MainTypeName = ValueTypestring,
        SubGroupId = Type1ValueTypeint,
        SubTypeName = Type1ValueTypestring,
    },
    XTableDrawWaferShow = {
        Id = ValueTypeintPrimaryKey,
        PositionX = ValueTypefloat,
        PositionY = ValueTypefloat,
        PositionZ = ValueTypefloat,
        RotationX = ValueTypefloat,
        RotationY = ValueTypefloat,
        RotationZ = ValueTypefloat,
        ScaleX = ValueTypefloat,
        ScaleY = ValueTypefloat,
        ScaleZ = ValueTypefloat,
    },
    XTableDrop = {
        Id = ValueTypeint,
        TargetIds = Type1ValueTypeint,
        Layers = Type1ValueTypeint,
        Probability = Type1ValueTypeint,
        BottomIds = Type1ValueTypeint,
    },
    XTableDropBottom = {
        Id = ValueTypeint,
        BottomDropType = ValueTypeint,
        BottomDropId = ValueTypeint,
        MeasureSetIds = ValueTypestring,
        MeasureGroupIds = ValueTypestring,
        MeasureDropIds = ValueTypestring,
        Min = ValueTypeint,
        Max = ValueTypeint,
        Priority = ValueTypeint,
        IsClose = ValueTypeint,
        UsableCount = ValueTypeint,
        CycleNeedCount = ValueTypeint,
    },
    XTableDropBottomLimit = {
        Id = ValueTypeint,
        StartTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
    },
    XTableDropGoods = {
        Id = ValueTypeint,
        TemplateId = ValueTypeint,
        MinCount = ValueTypeint,
        MaxCount = ValueTypeint,
        Span = ValueTypeint,
    },
    XTableDropGroup = {
        Id = ValueTypeint,
        DropIds = Type1ValueTypestring,
        Weights = Type1ValueTypeint,
    },
    XTableDropSet = {
        Id = ValueTypeint,
        GroupIds = Type1ValueTypeint,
        Weights = Type1ValueTypeint,
    },
    XTableDyeMergeActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        HelpKey = ValueTypestring,
        TaskTimeLimitId = ValueTypeint,
        RewardId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
    },
    XTableDyeMergeBlocks = {
        Id = ValueTypeintPrimaryKey,
        UiGridName = ValueTypestring,
        Type = ValueTypeint,
        Color = ValueTypeint,
        CanMove = ValueTypebool,
        InitRotateIndex = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableDyeMergeBlocksConfig = {
        Id = ValueTypeintPrimaryKey,
        IconSupprtTop = ValueTypestring,
        IconTop = ValueTypestring,
        IconNormal = ValueTypestring,
        IconNormalBig = ValueTypestring,
        IconTarget = ValueTypestring,
        IconActive = ValueTypestring,
        IconCircle = ValueTypestring,
        IconSector = ValueTypestring,
        IconSectorWall = ValueTypestring,
        ExtendIcons = Type1ValueTypestring,
        LineColor = ValueTypestring,
        ToggleColor = ValueTypestring,
    },
    XTableDyeMergeChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        Condition = ValueTypeint,
        NotPassedDesc = ValueTypestring,
        PassedDesc = ValueTypestring,
        PassedBg = ValueTypefloat,
        ChapterIcon = ValueTypestring,
        StageIds = Type1ValueTypeint,
    },
    XTableDyeMergeClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableDyeMergeColorMapper = {
        Color = ValueTypeintPrimaryKey,
        FromColors = Type1ValueTypeint,
        Icons = Type1ValueTypestring,
    },
    XTableDyeMergeColorMix = {
        Id = ValueTypeintPrimaryKey,
        IconMix = ValueTypestring,
        IconMixFiled = ValueTypestring,
    },
    XTableDyeMergeMap = {
        Row = ValueTypeintPrimaryKey,
        Columns = Type1ValueTypeint,
    },
    XTableDyeMergeStage = {
        Id = ValueTypeintPrimaryKey,
        PreStage = ValueTypeint,
        Name = ValueTypestring,
        TipsImg = ValueTypestring,
        BoardOffsetX = ValueTypefloat,
        BoardOffsetY = ValueTypefloat,
        BoardScale = ValueTypefloat,
        RuleTipsMapperIds = Type1ValueTypeint,
        StartFocusPosIndexs = Type1ValueTypeint,
    },
    XTableEatEquipCost = {
        Id = ValueTypeintPrimaryKey,
        Key = ValueTypestringPrimaryKey,
        Site = ValueTypeint,
        Star = ValueTypeint,
        UseMoney = ValueTypeint,
    },
    XTableEchelonInfo = {
        Id = ValueTypeintPrimaryKey,
        BuffId = ValueTypeint,
        NeedCharacter = ValueTypeint,
        RequireAbility = ValueTypeint,
        Condition = ValueTypeint,
        ShowFightEventIds = Type1ValueTypeint,
        IsShowEventTips = ValueTypebool,
    },
    XTableEliminateGame = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        LineCount = ValueTypeint,
        HelpId = ValueTypeint,
        FlipItemId = ValueTypeint,
        FlipItemCount = ValueTypeint,
        MoveItemId = ValueTypeint,
        MoveItemCount = ValueTypeint,
        EliminateCount = ValueTypeint,
        Grids = Type1ValueTypeint,
    },
    XTableEliminateGrid = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        DefaultState = ValueTypeint,
    },
    XTableEliminateGridType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        TypePic = ValueTypestring,
    },
    XTableEliminateReward = {
        Id = ValueTypeintPrimaryKey,
        GameId = ValueTypeint,
        GridType = ValueTypeint,
        GridCount = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableEmoji = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Order = ValueTypeint,
        Name = ValueTypestring,
        BigIcon = ValueTypestring,
        Path = ValueTypestring,
        GIFAsset = ValueTypestring,
        Description = ValueTypestring,
        WorldDesc = ValueTypestring,
        IsFree = ValueTypeint,
        ConvertItemId = ValueTypeint,
        ConvertItemCount = ValueTypeint,
        TimeLimitType = ValueTypeint,
        ExpireTimeStr = ValueTypestring,
        Duration = ValueTypeint,
        PackageId = ValueTypeint,
        ConnotationDesc = ValueTypestring,
    },
    XTableEmojiPack = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        Note = ValueTypestring,
    },
    XTableEmojiUnicodeConfig = {
        Id = ValueTypeintPrimaryKey,
        StartUnicode = ValueTypeint,
        EndUnicode = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableEnhanceSkillLevelEffect = {
        SkillLevelId = ValueTypeintPrimaryKey,
        BornMagic = Type1ValueTypeint,
        SubSkillId = Type1ValueTypeint,
        SubMagicId = Type1ValueTypeint,
        Ability = ValueTypeint,
        ResonanceAbility = ValueTypeint,
        PlusAbility = ValueTypeint,
    },
    XTableEnhanceSkillUpgrade = {
        CostItem = Type1ValueTypeint,
        CostItemCount = Type1ValueTypeint,
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Level = ValueTypeint,
        ConditionId = Type1ValueTypeint,
    },
    XTableEnhanceSkillUpgradeDes = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Level = ValueTypeint,
        Name = ValueTypestring,
        WeaponSkillDes = ValueTypestring,
        Intro = ValueTypestring,
        Icon = ValueTypestring,
        EntryId = Type1ValueTypeint,
        TypeDes = ValueTypestring,
        Tag = Type1ValueTypestring,
        Title = Type2KeyTypeintValueTypestring,
        BriefDes = Type2KeyTypeintValueTypestring,
        SpecificDes = Type2KeyTypeintValueTypestring,
    },
    XTableEnvelopeActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        TaskGroup = ValueTypeint,
        TaskDailyGroup = ValueTypeint,
        FirstDayRewardId = ValueTypeint,
        DailyTicketRewardId = ValueTypeint,
        FastOpenTarget = ValueTypeint,
        TicketItemId = ValueTypeint,
        SelectChoiceItemId = ValueTypeint,
        BGMCueId = ValueTypeint,
        ShowRewardId = ValueTypeint,
    },
    XTableEnvelopeCharacter = {
        Id = ValueTypeintPrimaryKey,
        CharacterName = ValueTypestring,
        Desc = ValueTypestring,
        HeadIcon = ValueTypestring,
        CgAssetPathLocked = ValueTypestring,
        CgAssetPathUnlocked = ValueTypestring,
        OpenEffectAssetPath = ValueTypestring,
        StoryId = ValueTypestring,
        ModelId = ValueTypestring,
        IsFemale = ValueTypebool,
    },
    XTableEnvelopeInstrument = {
        Id = ValueTypeintPrimaryKey,
        OpenTarget = ValueTypeint,
        ModelId = ValueTypestring,
        ModelPlayingId = ValueTypestring,
        CharacterAnimationId = ValueTypestring,
        BGMTrackControlName = ValueTypestring,
    },
    XTableEnvelopeList = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
    },
    XTableEquip = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Site = ValueTypeint,
        Quality = ValueTypeint,
        Star = ValueTypeint,
        WeaponSkillId = ValueTypeint,
        Priority = ValueTypeint,
        DefaultLock = ValueTypebool,
        CharacterId = ValueTypeint,
        SuitId = ValueTypeint,
        CharacterType = ValueTypeint,
        Name = ValueTypestring,
        LogName = ValueTypestring,
        Description = ValueTypestring,
        NeedFirstShow = ValueTypeint,
        RecommendCharacterId = ValueTypeint,
        OverrunNoShow = ValueTypeint,
    },
    XTableEquipAnim = {
        ModelId = ValueTypestringPrimaryKey,
        Params = ValueTypeint,
    },
    XTableEquipAnimReset = {
        Id = ValueTypeintPrimaryKey,
        CharacterModel = ValueTypestring,
        IsImmediateTransition = ValueTypeint,
    },
    XTableEquipAwake = {
        Id = ValueTypeintPrimaryKey,
        AttribId = Type2KeyTypeintValueTypeint,
        AttribDes1 = Type1ValueTypestring,
        AttribDes2 = Type1ValueTypestring,
        ItemId = Type1ValueTypeint,
        ItemCount = Type1ValueTypeint,
        ItemCrystalId = Type1ValueTypeint,
        ItemCrystalCount = Type1ValueTypeint,
        AwarenessAttrDesc = ValueTypestring,
        AwarenessAttrValue = ValueTypeint,
    },
    XTableEquipBreakthrough = {
        Id = ValueTypeintPrimaryKey,
        EquipId = ValueTypeint,
        Times = ValueTypeint,
        LevelLimit = ValueTypeint,
        UseItemId = ValueTypeint,
        UseMoney = ValueTypeint,
        AttribId = ValueTypeint,
        AttribPromotedId = ValueTypeint,
        Exp = ValueTypeint,
        LevelUpTemplateId = ValueTypeint,
        ConditionId = ValueTypeint,
        ResId = ValueTypeint,
        ItemId = Type1ValueTypeint,
        ItemCount = Type1ValueTypeint,
    },
    XTableEquipConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypeint,
    },
    XTableEquipDecompose = {
        Id = ValueTypeintPrimaryKey,
        Key = ValueTypestringPrimaryKey,
        Site = ValueTypeint,
        Star = ValueTypeint,
        Breakthrough = ValueTypeint,
        ExpToOneCoin = ValueTypefloat,
        ExpToItemId = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableEquipInit = {
        Id = ValueTypeint,
        Count = ValueTypeint,
    },
    XTableEquipJudge = {
        Id = ValueTypeintPrimaryKey,
        GrossScore = ValueTypeint,
        WeaponBreakThroughScore = ValueTypeint,
        WeaponUpLevelScore = ValueTypeint,
        WeaponPutOnScore = ValueTypeint,
        ChipBreakThroughScore = ValueTypeint,
        ChipUpLevelScore = ValueTypeint,
        ChipPutOnScore = ValueTypeint,
    },
    XTableEquipLevelUp = {
        Level = ValueTypeintPrimaryKey,
        Exp = ValueTypeint,
        AllExp = ValueTypeint,
    },
    XTableEquipModel = {
        Id = ValueTypeintPrimaryKey,
        ModelName = Type2KeyTypeintValueTypestring,
        LowModelName = Type2KeyTypeintValueTypestring,
        AnimController = Type2KeyTypeintValueTypestring,
        UiAnimStateName = Type2KeyTypeintValueTypestring,
        UiAnimCueId = Type2KeyTypeintValueTypeint,
        UiAnimDelay = Type2KeyTypeintValueTypeint,
        UiAutoRotateDelay = Type2KeyTypeintValueTypeint,
        WeaponModelHash = ValueTypestring,
    },
    XTableEquipModelShow = {
        Id = ValueTypeintPrimaryKey,
        ModelId = ValueTypeint,
        UiName = ValueTypestring,
        HideNodeName = Type1ValueTypestring,
    },
    XTableEquipModelTransform = {
        Id = ValueTypeintPrimaryKey,
        IndexId = ValueTypeint,
        UiName = ValueTypestring,
        PositionX = ValueTypefloat,
        PositionY = ValueTypefloat,
        PositionZ = ValueTypefloat,
        RotationX = ValueTypefloat,
        RotationY = ValueTypefloat,
        RotationZ = ValueTypefloat,
        ScaleX = ValueTypefloat,
        ScaleY = ValueTypefloat,
        ScaleZ = ValueTypefloat,
    },
    XTableEquipRecommend = {
        Id = ValueTypeintPrimaryKey,
        EquipRecomend = ValueTypeint,
        ChipRecomend = Type1ValueTypeint,
        SuitId = Type1ValueTypeint,
        Number = Type1ValueTypeint,
    },
    XTableEquipRes = {
        Id = ValueTypeintPrimaryKey,
        BigIconPath = ValueTypestring,
        IconPath = ValueTypestring,
        ModelTransId = Type1ValueTypeint,
        ResonanceModelTransId1 = Type1ValueTypeint,
        ResonanceModelTransId2 = Type1ValueTypeint,
        ResonanceModelTransId3 = Type1ValueTypeint,
        LiHuiPath = ValueTypestring,
        PainterName = ValueTypestring,
    },
    XTableEquipResByFool = {
        Id = ValueTypeintPrimaryKey,
        ModelTransId = Type1ValueTypeint,
        ResonanceModelTransId1 = Type1ValueTypeint,
        ResonanceModelTransId2 = Type1ValueTypeint,
        ResonanceModelTransId3 = Type1ValueTypeint,
    },
    XTableEquipResonance = {
        Id = ValueTypeintPrimaryKey,
        AttribPoolId = Type2KeyTypeintValueTypeint,
        AttribPoolWeight = Type2KeyTypeintValueTypeint,
        CharacterSkillPoolId = Type2KeyTypeintValueTypeint,
        CharacterSkillPoolWeight = Type2KeyTypeintValueTypeint,
        WeaponSkillPoolId = Type2KeyTypeintValueTypeint,
        WeaponSkillPoolWeight = Type2KeyTypeintValueTypeint,
    },
    XTableEquipResonanceEffect = {
        Id = ValueTypeintPrimaryKey,
        ModelId = ValueTypeint,
        DisplayRootName = Type2KeyTypeintValueTypestring,
        DisplayEffectPath = Type2KeyTypeintValueTypestring,
        DisplayDelayTime = Type2KeyTypeintValueTypeint,
    },
    XTableEquipResonanceUseItem = {
        Id = ValueTypeintPrimaryKey,
        ItemId = Type1ValueTypeint,
        ItemCount = Type1ValueTypeint,
        SelectSkillItemId = Type1ValueTypeint,
        SelectSkillItemCount = Type1ValueTypeint,
    },
    XTableEquipSignboard = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        ChaIsAllActive = ValueTypeint,
        FashionId = ValueTypeint,
        FashIsAllActive = ValueTypeint,
        ActionId = ValueTypestring,
        EquipModelIndex = ValueTypeint,
    },
    XTableEquipSkipId = {
        Id = ValueTypeintPrimaryKey,
        EatType = ValueTypeint,
        EquipType = ValueTypeint,
        Site = ValueTypeint,
        SkipIdParams = Type1ValueTypeint,
    },
    XTableEquipSuit = {
        Id = ValueTypeintPrimaryKey,
        IconPath = ValueTypestring,
        ClearIconPath = ValueTypestring,
        WaferBagPath = ValueTypestring,
        Name = ValueTypestring,
        Description = ValueTypestring,
        SkillEffect = Type2KeyTypeintValueTypeint,
        SkillDescription = Type2KeyTypeintValueTypestring,
        SuitType = ValueTypeint,
        EquipIds = Type2KeyTypeintValueTypeint,
        EquipType = ValueTypestring,
        RecommendCharacterId = ValueTypestring,
    },
    XTableEquipSuitEffect = {
        Id = ValueTypeintPrimaryKey,
        BornMagic = Type1ValueTypeint,
        SkillId = Type1ValueTypeint,
        Ability = ValueTypeint,
    },
    XTableEquipTarget = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        EquipRecommendId = ValueTypeint,
        Description = ValueTypestring,
        Hidden = ValueTypeint,
    },
    XTableEscapeActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        Background = ValueTypestring,
    },
    XTableEscapeChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        OpenCondition = ValueTypeint,
        GroupId = ValueTypeint,
        Difficulty = ValueTypeint,
        InitialTime = ValueTypeint,
        MaxTime = ValueTypeint,
        LayerIds = Type1ValueTypeint,
        ScoreRatio = ValueTypeint,
        Name = ValueTypestring,
        EnName = ValueTypestring,
        EnvironmentDesc = Type1ValueTypestring,
        BuffDesc = ValueTypestring,
        ShowFightEventIds = Type1ValueTypeint,
    },
    XTableEscapeClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableEscapeLayer = {
        Id = ValueTypeintPrimaryKey,
        ClearStageCount = ValueTypeint,
        StageIds = Type1ValueTypeint,
        TacticsNodeIds = Type1ValueTypeint,
    },
    XTableEscapeStage = {
        StageId = ValueTypeintPrimaryKey,
        AwardTime = ValueTypeint,
        Color = ValueTypeint,
        GridDesc = ValueTypestring,
        ScoreRatio = ValueTypeint,
    },
    XTableEscapeStageColorPrefab = {
        Id = ValueTypeintPrimaryKey,
        Prefab = ValueTypestring,
    },
    XTableEscapeTactics = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Quality = ValueTypeint,
        UnlockConditionId = ValueTypeint,
        EffectGroupId = ValueTypeint,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableEscapeTacticsEffect = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Desc = ValueTypestring,
        Params = Type1ValueTypeint,
    },
    XTableEscapeTacticsEffectGroup = {
        Id = ValueTypeintPrimaryKey,
        FightEventIds = Type1ValueTypeint,
        TacticsEffectIds = Type1ValueTypeint,
    },
    XTableEscapeTacticsNode = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BrifeDesc = ValueTypestring,
        Desc = ValueTypestring,
        ShowIcon = ValueTypestring,
        RandomGroupIds = Type1ValueTypeint,
    },
    XTableEscapeTacticsRandomGroup = {
        Id = ValueTypeintPrimaryKey,
        RandomGroupId = ValueTypeint,
        TacticsId = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableEscapeTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TaskId = Type1ValueTypeint,
    },
    XTableExecuteRankUpMission = {
        Id = ValueTypeintPrimaryKey,
        Stageids = ValueTypeint,
        CastOnTime = Type1ValueTypeint,
        CastOnMission = Type1ValueTypeint,
        CastOffFightevent = Type1ValueTypeint,
        CastFail = Type1ValueTypeint,
        CastOnMissionFightTips = Type1ValueTypeint,
        CastOffFighteventTips = Type1ValueTypeint,
    },
    XTableExhibitionCharacterMap = {
        CharacterId = ValueTypeintPrimaryKey,
        ExhibitionId = ValueTypeint,
    },
    XTableExhibitionLevel = {
        LevelId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        IconFrame = ValueTypestring,
        LevelLogo = ValueTypestring,
        LevelFrame = ValueTypestring,
        LevelIcon = ValueTypestring,
    },
    XTableExhibitionLimit = {
        CharacterId = ValueTypeintPrimaryKey,
        SetAureoleId = ValueTypeint,
        SetBallColor = ValueTypeint,
        AureoleIds = Type1ValueTypeint,
    },
    XTableExhibitionReward = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        LevelId = ValueTypeint,
        RewardId = ValueTypeint,
        HeadPortrait = ValueTypeint,
        ConditionIds = Type1ValueTypeint,
        SkillGroupId = ValueTypeint,
    },
    XTableExhibitionTypeMap = {
        Type = ValueTypeintPrimaryKey,
        ExhibitionIds = Type1ValueTypeint,
    },
    XTableExpeditionAssist = {
        EffectId = ValueTypeint,
        AssistType = ValueTypeint,
    },
    XTableExpeditionBaseCharacter = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Type = Type1ValueTypeint,
        LockSkill = Type1ValueTypeint,
        SkillLevel = Type1ValueTypeint,
        LockLevel = Type1ValueTypeint,
        Elements = Type1ValueTypeint,
        ReferenceComboId = Type1ValueTypeint,
    },
    XTableExpeditionChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        RewardId = Type1ValueTypeint,
        PrefabPath = Type1ValueTypestring,
        CodeName = ValueTypestring,
        StageBgPath = Type1ValueTypestring,
        BgFx = Type1ValueTypestring,
        RewardIcon = Type1ValueTypestring,
        DefaultTeamIds = Type1ValueTypeint,
        ComboIds = Type1ValueTypeint,
    },
    XTableExpeditionCharacter = {
        Id = ValueTypeintPrimaryKey,
        BaseId = ValueTypeint,
        Rank = ValueTypeint,
        RobotId = ValueTypeint,
    },
    XTableExpeditionCharacterElements = {
        Id = ValueTypeintPrimaryKey,
        ElementName = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableExpeditionCharacterType = {
        Id = ValueTypestringPrimaryKey,
        TypeName = ValueTypestring,
    },
    XTableExpeditionCharacterWeight = {
        Id = ValueTypeint,
        BaseId = ValueTypeint,
        Weight = ValueTypeint,
        ExtraWeight = ValueTypeint,
        MustAppearCount = ValueTypeint,
    },
    XTableExpeditionChildCombo = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ComboTypeId = ValueTypeint,
        IconPath = ValueTypestring,
        ConditionDescription = ValueTypestring,
        Condition = ValueTypeint,
        DefaultTeamId = ValueTypeint,
    },
    XTableExpeditionCombo = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        EffectDescription = ValueTypestring,
        EffectId = Type1ValueTypeint,
        EffectValid = Type1ValueTypestring,
        EffectTarget = Type1ValueTypestring,
        ChildComboId = ValueTypeint,
        ConditionDesc = ValueTypestring,
        ConditionLevel = ValueTypeint,
        ConditionNum = ValueTypeint,
    },
    XTableExpeditionComboTypeName = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        OrderId = ValueTypeint,
    },
    XTableExpeditionConfig = {
        Id = ValueTypeintPrimaryKey,
        ActivityType = ValueTypeint,
        Name = ValueTypestring,
        RecruitRobotMaxNum = ValueTypeint,
        RecruitInitNum = ValueTypeint,
        RecruitMaxNum = ValueTypeint,
        RecruitRecoverTime = ValueTypeint,
        RecruitDrawNum = ValueTypeint,
        RecruitPickNum = ValueTypeint,
        TimeId = ValueTypeint,
        TaskGroupId = ValueTypeint,
        Cycle = ValueTypeint,
        ResetStageConsumeId = ValueTypeint,
        ResetStageConsumeCount = ValueTypeint,
        ResetChapterConsumeId = ValueTypeint,
        ResetChapterConsumeCount = ValueTypeint,
        CommentMaxNum = ValueTypeint,
        DailyLikeMaxNum = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        BannerTexturePath = ValueTypestring,
        RankIcon = Type1ValueTypestring,
        ChapterPrefab = ValueTypestring,
    },
    XTableExpeditionDefaultTeam = {
        TeamId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TeamDes = ValueTypestring,
        PreStageType = ValueTypeint,
        PreStageIds = Type1ValueTypeint,
        ECharacterIds = Type1ValueTypeint,
    },
    XTableExpeditionDrawConsume = {
        Id = ValueTypeintPrimaryKey,
        ConsumeId = ValueTypeint,
        ConsumeCount = ValueTypeint,
    },
    XTableExpeditionDrawPR = {
        Level = ValueTypeintPrimaryKey,
        NeedRefreshTime = ValueTypeint,
        RankPR = Type1ValueTypeint,
    },
    XTableExpeditionDrawRank = {
        Id = ValueTypeintPrimaryKey,
        Rank = ValueTypeint,
    },
    XTableExpeditionGlobalCombo = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        EffectId = Type1ValueTypeint,
        EffectValid = Type1ValueTypestring,
        EffectTarget = Type1ValueTypestring,
        IsVisible = ValueTypeint,
        EffectDescription = ValueTypestring,
        IconPath = ValueTypestring,
    },
    XTableExpeditionRankUp = {
        Id = ValueTypeint,
        Level1 = ValueTypeint,
        Level2 = ValueTypeint,
        Level3 = ValueTypeint,
        Level4 = ValueTypeint,
    },
    XTableExpeditionStage = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        StageId = ValueTypeint,
        StageDes = ValueTypestring,
        PreStageType = ValueTypeint,
        PreStageIds = Type1ValueTypeint,
        OrderId = ValueTypeint,
        TierId = ValueTypeint,
        StageType = ValueTypeint,
        Difficulty = ValueTypeint,
        PassDrawTimesReward = ValueTypeint,
        DrawTimesReward = ValueTypeint,
        BossStageCover = ValueTypestring,
        RecommentStar = ValueTypeint,
        WarningStarCap = ValueTypeint,
        DangerStarCap = ValueTypeint,
        StageWords = Type1ValueTypeint,
        StagePrefab = ValueTypestring,
    },
    XTableExpeditionStageTier = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ChapterId = ValueTypeint,
        OrderId = ValueTypeint,
        Difficulty = ValueTypeint,
        TierType = ValueTypeint,
        CoverPath = ValueTypestring,
    },
    XTableExpeditionTeamPos = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        ConditionDes = ValueTypestring,
        ConditionId = ValueTypeint,
    },
    XTableExpensiveiItem = {
        ItemId = ValueTypeintPrimaryKey,
        LeftTime = ValueTypeint,
        SkipId = ValueTypeint,
    },
    XTableExperimentGroup = {
        Id = ValueTypeintPrimaryKey,
        SubIndex = ValueTypeint,
        Name = ValueTypestring,
        Order = ValueTypeint,
        Description = ValueTypestring,
        TimeId = ValueTypeint,
        ModeExplainText = ValueTypestring,
    },
    XTableExperimentLevel = {
        Id = ValueTypeintPrimaryKey,
        GroupID = ValueTypeint,
        Name = ValueTypestring,
        RecommendLevel = ValueTypeint,
        Order = ValueTypeint,
        Type = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        ShowPass = ValueTypeint,
        IsShow = ValueTypeint,
        Ico = ValueTypestring,
        TrialID = ValueTypeint,
        TrialStatus = ValueTypeint,
        SingStageId = ValueTypeint,
        MultStageId = ValueTypeint,
        SingleDescription = ValueTypestring,
        MultDescription = ValueTypestring,
        DetailBackGroundIco = ValueTypestring,
        TimeId = ValueTypeint,
        HeadIcon = ValueTypestring,
        ChapterIcon = ValueTypestring,
        HelpCourseId = ValueTypeint,
        SkillExplainId = ValueTypeint,
        StarDesc = Type1ValueTypestring,
        StarReward = ValueTypeint,
        SpinePath = ValueTypestring,
        FashionId = ValueTypeint,
    },
    XTableExperimentReward = {
        Id = ValueTypeintPrimaryKey,
        StarNum = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
    },
    XTableExperimentSceneShow = {
        Id = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
        TimeId = ValueTypeint,
        SpecialUiName = ValueTypestring,
        BackgroundId = ValueTypeint,
        WeaponFashionId = ValueTypeint,
        StandbyAnimName = ValueTypestring,
        SkipUiType = ValueTypeint,
        SkipFunctionals = Type2KeyTypeintValueTypeint,
    },
    XTableExperimentSkillExplainId = {
        Id = ValueTypeintPrimaryKey,
        SkillTitle = Type1ValueTypestring,
        SkillDesc = Type1ValueTypestring,
    },
    XTableExploreBuffItem = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        UnlockEvent = Type1ValueTypeint,
        GainDesc = Type1ValueTypestring,
        Icon = ValueTypestring,
        BuffName = ValueTypestring,
        Explain = ValueTypestring,
        EventId = ValueTypeint,
    },
    XTableExploreChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BgPic = ValueTypestring,
        Icon = ValueTypestring,
        RewardId = ValueTypeint,
        RewardIcon = ValueTypestring,
        PreId = ValueTypeint,
        Endurance = ValueTypeint,
        StoryId = ValueTypestring,
        ChapterPrefab = ValueTypestring,
    },
    XTableExploreNode = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        Name = ValueTypestring,
        Title = ValueTypestring,
        Explain = ValueTypestring,
        EnterIco = ValueTypestring,
        IsBossNode = ValueTypebool,
        IsKeyNode = ValueTypebool,
        Type = ValueTypeint,
        TypeValue = ValueTypestring,
        Icon = ValueTypestring,
        PreShowId = Type1ValueTypeint,
        PreOpenId = Type1ValueTypeint,
        CostEndurance = ValueTypeint,
        RewardId = ValueTypeint,
        RewardIcon = ValueTypestring,
        CharacterIcon = ValueTypestring,
        TimeDesc = ValueTypestring,
        Posision = Type1ValueTypeint,
    },
    XTableExploreStoryText = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        Title = ValueTypestring,
        Text = ValueTypestring,
        UnlockNodeId = ValueTypeint,
    },
    XTableExpUpGame = {
        Id = ValueTypeintPrimaryKey,
        Hp = ValueTypeint,
        Attack = ValueTypeint,
        LevelCost = ValueTypeint,
        BuffCost = ValueTypeint,
        BuffTemplateID = Type1ValueTypeint,
    },
    XTableExternalActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        IsStatLogin = ValueTypebool,
        Desc = ValueTypestring,
    },
    XTableExternalReward = {
        RewardKey = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        MailId = ValueTypeint,
        LimitCount = ValueTypeint,
    },
    XTableExtraChapterActivity = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = Type1ValueTypeint,
        ChapterTimeId = ValueTypeint,
        HideChapterTimeId = ValueTypeint,
    },
    XTableExtraExploreGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        StageIndex = ValueTypeint,
        PreShowIndex = Type1ValueTypeint,
    },
    XTableExtraExploreItem = {
        Id = ValueTypeintPrimaryKey,
        MainChapterId = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Hint = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableExtraNextChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        SkipCondition = ValueTypeint,
        StoryImgs = Type1ValueTypestring,
        StorySkipId = Type1ValueTypeint,
        StorySkipName = Type1ValueTypestring,
        StoryChpterType = Type1ValueTypeint,
        StoryChapterId = Type1ValueTypeint,
        StoryChapterName = Type1ValueTypestring,
    },
    XTableFangKuaiActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        TaskTimeLimitIds = Type1ValueTypeint,
        TaskTabNames = Type1ValueTypestring,
        HelpId = ValueTypestring,
        MaxItemCount = ValueTypeint,
        MinOnGroundLineCount = ValueTypeint,
        FevItemGain = ValueTypeint,
        MaxFevLevel = ValueTypeint,
        FevScoreGainCoefficient = ValueTypeint,
        FevScoreGainCoefficientRate = ValueTypeint,
        MaxEnhanceTimes = ValueTypeint,
        MaxLevelScore = ValueTypeint,
        RewardId = ValueTypeint,
        ScoreTitle = ValueTypeint,
    },
    XTableFangKuaiArchieve = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableFangKuaiBlock = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Type = ValueTypeint,
        Length = ValueTypeint,
        Direction = ValueTypeint,
        Colors = Type1ValueTypeint,
        MaxHitTimes = ValueTypeint,
        UnBuild = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableFangKuaiBlockPoint = {
        Id = ValueTypeintPrimaryKey,
        BlockType = ValueTypeint,
        BlockLength = ValueTypeint,
        Point = ValueTypeint,
    },
    XTableFangKuaiBlockTexture = {
        Id = ValueTypeintPrimaryKey,
        HeadImage = ValueTypestring,
        BodyImage = ValueTypestring,
        TailImage = ValueTypestring,
        StandaloneImage = ValueTypestring,
        Standby = Type1ValueTypestring,
        BossStandby = Type1ValueTypestring,
    },
    XTableFangKuaiBrickFace = {
        Id = ValueTypeintPrimaryKey,
        FacePic = Type1ValueTypestring,
    },
    XTableFangKuaiChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        StageGroupIds = Type1ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableFangKuaiCharacter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TradeName = ValueTypestring,
        HeadIcon = ValueTypestring,
        CharacterId = Type1ValueTypeint,
    },
    XTableFangKuaiClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableFangKuaiCombo = {
        Id = ValueTypeintPrimaryKey,
        Radio = ValueTypeint,
        FevComboGain = ValueTypeint,
    },
    XTableFangKuaiDropBlock = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        ActionRange = Type1ValueTypeint,
        BlockLength = Type1ValueTypeint,
        BlockType = Type1ValueTypeint,
        Weight = Type1ValueTypeint,
        ActionCd = ValueTypeint,
    },
    XTableFangKuaiItem = {
        Id = ValueTypeintPrimaryKey,
        Kind = ValueTypeint,
        NextItemId = ValueTypeint,
        BackItemId = ValueTypeint,
        Params = Type1ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        ItemType = ValueTypeint,
        BlockTypes = Type1ValueTypeint,
    },
    XTableFangKuaiNpcAction = {
        Id = ValueTypeintPrimaryKey,
        Model = ValueTypestring,
        Kind = ValueTypeint,
        StandbyAnim = Type1ValueTypestring,
        AttackAnim = Type1ValueTypestring,
        JoyfulAnim = Type1ValueTypestring,
        BossStandbyAnim = Type1ValueTypestring,
        BossAttackAnim = Type1ValueTypestring,
        MoveFangKuaiAnim = Type1ValueTypestring,
    },
    XTableFangKuaiScoreRate = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Score = ValueTypeint,
        Grade = ValueTypeint,
    },
    XTableFangKuaiStage = {
        Id = ValueTypeintPrimaryKey,
        PreStageId = ValueTypeint,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        BossName = ValueTypestring,
        BuffTitle = Type1ValueTypestring,
        BuffDesc = Type1ValueTypestring,
        HeadIcon = ValueTypestring,
        Icon = ValueTypestring,
        NpcId = ValueTypeint,
        SizeX = ValueTypeint,
        SizeY = ValueTypeint,
        MaxBlockLength = ValueTypeint,
        InitLineCount = ValueTypeint,
        MaxRound = ValueTypeint,
        EnvironmentId = ValueTypeint,
        ShowItem = Type1ValueTypeint,
        MaxUseCount = ValueTypeint,
        SettleDesc = ValueTypestring,
        FevExctiedValue = ValueTypeint,
        FevStageMulti = ValueTypeint,
        InitialItemIds = Type1ValueTypeint,
        InitialFev = ValueTypeint,
    },
    XTableFangKuaiStageBlockRule = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        MinLine = ValueTypeint,
        MaxLine = ValueTypeint,
        Type = ValueTypeint,
        IsLoop = ValueTypebool,
        FixBlockXs = Type1ValueTypeint,
        FixBlockLengths = Type1ValueTypeint,
        FixBlockType = Type1ValueTypeint,
        MaxBlockLengths = Type1ValueTypeint,
        MaxBlockLengthWeights = Type1ValueTypeint,
        FillBlockCounts = Type1ValueTypeint,
        FillBlockCountWeights = Type1ValueTypeint,
        SpaceCounts = Type1ValueTypeint,
        SpaceCountWeights = Type1ValueTypeint,
    },
    XTableFangKuaiStageEnvironment = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableFangKuaiStageGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        SimpleStageId = ValueTypeint,
        DiffcultStageId = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableFangKuaiStageItemRule = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        MinLine = ValueTypeint,
        MaxLine = ValueTypeint,
        ItemIds = Type1ValueTypeint,
        ItemIdWeights = Type1ValueTypeint,
        MinRefreshInterval = ValueTypeint,
        MaxRefreshInterval = ValueTypeint,
    },
    XTableFashion = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        ResourcesId = ValueTypeint,
        Name = ValueTypestring,
        Quality = ValueTypeint,
        Series = ValueTypeint,
        Description = ValueTypestring,
        WorldDescription = ValueTypestring,
        FashionSuitRare = ValueTypeint,
        FashionSuitVideo = ValueTypeint,
        FashionSuitResourcePicPath = ValueTypestring,
        FashionSuitResourceSpinePath = ValueTypestring,
        FashionSuitPic = ValueTypestring,
        Icon = ValueTypestring,
        BigIcon = ValueTypestring,
        SkipIdParams = Type1ValueTypeint,
        Priority = ValueTypeint,
        ItemKey = ValueTypeint,
        ItemCount = ValueTypeint,
        SmallHeadIcon = ValueTypestring,
        SmallHeadIconLiberation = ValueTypestring,
        SmallHeadIconFashion = ValueTypestring,
        BigHeadIcon = ValueTypestring,
        BigHeadIconFashion = ValueTypestring,
        RoundnessNotItemHeadIcon = ValueTypestring,
        RoundnessNotItemHeadIconLiberation = ValueTypestring,
        RoundnessHeadIcon = ValueTypestring,
        BigRoundnessHeadIcon = ValueTypestring,
        HalfBodyImage = ValueTypestring,
        RoleCharacterBigImage = ValueTypestring,
        BigHeadIconLiberation = ValueTypestring,
        CharacterIcon = ValueTypestring,
        GachaIcon = ValueTypestring,
        ShowTimeStr = ValueTypestring,
        SceneModelId = ValueTypeint,
        EffectRootName = ValueTypestring,
        EffectPath = ValueTypestring,
        AureoleId = ValueTypeint,
        SubItem = Type1ValueTypeint,
        GiftId = ValueTypeint,
        FashionColorIds = Type1ValueTypeint,
        FashionColorHex = ValueTypestring,
        DefaultHide = ValueTypebool,
    },
    XTableFashionAureole = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        EffectPath = ValueTypestring,
        Icon = ValueTypestring,
        Condition = Type1ValueTypeint,
    },
    XTableFashionColor = {
        Id = ValueTypeintPrimaryKey,
        ConvertItemId = ValueTypeint,
        ConvertItemCount = ValueTypeint,
        ResourcesId = ValueTypeint,
        ColorHex = ValueTypestring,
        SkipIdParams = Type1ValueTypeint,
        FashionIcon = ValueTypestring,
        FashionName = ValueTypestring,
        FashionNameVertical = ValueTypestring,
        OriginalFashionId = ValueTypeint,
        TargetFashionId = ValueTypeint,
        PreviewAnimation = ValueTypestring,
        Quality = ValueTypeint,
        Description = ValueTypestring,
        WorldDescription = ValueTypestring,
    },
    XTableFashionDownloadConfig = {
        FashionId = ValueTypeintPrimaryKey,
        ResId = ValueTypeint,
        AutoDownload = ValueTypebool,
        NotShow = ValueTypebool,
    },
    XTableFashionGroup = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Name = ValueTypestring,
        FashionId = ValueTypeint,
        WeaponFashionId = ValueTypeint,
        GainType = ValueTypeint,
        FashionGainParams = Type1ValueTypeint,
        WeaponFashionGainParams = Type1ValueTypeint,
    },
    XTableFashionGroupAuto = {
        FashionId = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
    },
    XTableFashionQuality = {
        Id = ValueTypeint,
        IconDesc = ValueTypestring,
    },
    XTableFashionSeries = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableFashionStory = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        PrefabType = ValueTypeint,
        SingleLines = Type1ValueTypeint,
        TrialStages = Type1ValueTypeint,
        TrialBg = ValueTypestring,
        SkipId = Type1ValueTypeint,
        TaskLimitId = ValueTypeint,
        RewardActivityTimeId = ValueTypeint,
        RewardTaskId = ValueTypeint,
        RewardSkipId = ValueTypeint,
    },
    XTableFashionStorySingleLine = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ChapterPrefab = ValueTypestring,
        ActivityBannerIcon = ValueTypestring,
        ChapterBg = ValueTypestring,
        TrialBg = ValueTypestring,
        FightStagePrefab = ValueTypestring,
        StoryStagePrefab = ValueTypestring,
        ChapterStages = Type1ValueTypeint,
        StoryTimeId = ValueTypeint,
        StoryEntranceBg = ValueTypestring,
        StoryFinishTag = ValueTypestring,
        AsGroupStoryIcon = ValueTypestring,
        SummerFashionTitleImg = ValueTypestring,
        StoryDecorateIcon = ValueTypestring,
    },
    XTableFashionStoryStage = {
        StageId = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        PreStageId = ValueTypeint,
        StoryStageDetailBg = ValueTypestring,
        StoryStageDetailIcon = ValueTypestring,
        TrialDetailBg = ValueTypestring,
        TrialDetailSpine = ValueTypestring,
        TrialDetailHeadIcon = ValueTypestring,
        TrialDetailRecommendLevel = ValueTypeint,
        TrialDetailDesc = ValueTypestring,
        FinishTag = ValueTypestring,
        StoryStageFace = ValueTypestring,
        TrialFace = ValueTypestring,
        TrialLockIcon = ValueTypestring,
        TrialImgName = ValueTypestring,
    },
    XTableFashionStoryTrialEntry = {
        StageId = ValueTypeintPrimaryKey,
        TrialFace = ValueTypestring,
        FinishTag = ValueTypestring,
        TrialLockIcon = ValueTypestring,
        TrialImgName = ValueTypestring,
    },
    XTableFashionSuit = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        RewardId = ValueTypeint,
        IsComplete = ValueTypebool,
        FashionIds = Type1ValueTypeint,
        Sort = ValueTypeint,
        Type = ValueTypeint,
        SuitDescription = ValueTypestring,
        SuitTabText = ValueTypestring,
        SubTabTimeId = ValueTypeint,
    },
    XTableFashionSuitClientConfig = {
        Id = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableFashionSuitNotice = {
        Id = ValueTypeintPrimaryKey,
        FashionIds = Type1ValueTypeint,
        TimeId = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableFashionSuitUiConfig = {
        Id = ValueTypeintPrimaryKey,
        SuitLogo = ValueTypestring,
        SuitBanner = ValueTypestring,
        SuitBackground = ValueTypestring,
        PrefabPath = ValueTypestring,
        ScenePrefabPath = ValueTypestring,
        WeaponPosX = ValueTypefloat,
        WeaponPosY = ValueTypefloat,
        WeaponPosZ = ValueTypefloat,
        FirstBg = ValueTypestring,
        PanelFashionDetailPrefabPath = ValueTypestring,
        CameraPrefabPath = ValueTypestring,
        SliderMax = ValueTypefloat,
        EnableAnimDelay = ValueTypeint
    },
    XTableFashionVoice = {
        Id = ValueTypeint,
        FashionId = ValueTypeintPrimaryKey,
        CueId = ValueTypeint,
    },
    XTableFavorabilityLevelConfig = {
        Id = ValueTypeintPrimaryKey,
        WordColor = ValueTypestring,
        LevelIcon = ValueTypestring,
    },
    XTableFavorLevelIcon = {
        Level = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
    },
    XTableFestival = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        SendMailType = ValueTypeint,
        MailId = ValueTypeint,
        Note = ValueTypestring,
    },
    XTableFestivalActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ActivityTimeId = ValueTypeint,
        UiType = ValueTypeint,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        FubenActivityOrder = ValueTypeint,
        SkipId = Type1ValueTypeint,
        FunctionOpenId = ValueTypeint,
        StagePrefix = ValueTypestring,
        BannerBg = ValueTypestring,
        MainBackgound = ValueTypestring,
        EffectUrl = ValueTypestring,
        FubenPrefab = ValueTypestring,
        GridFubenPrefab = ValueTypestring,
        GridStoryPrefab = ValueTypestring,
        TitleIcon = ValueTypestring,
        TitleBg = ValueTypestring,
        ChapterType = ValueTypeint,
        ChapterBgm = ValueTypeint,
        StageId = Type1ValueTypeint,
        StageName = Type2KeyTypeintValueTypestring,
        StageStyle = Type2KeyTypeintValueTypestring,
        IsRetainData = ValueTypebool,
    },
    XTableFestivalCharacterGroup = {
        CharacterId = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        MailId = ValueTypeint,
        ArchiveMailId = ValueTypeint,
        CommunicationId = ValueTypeint,
    },
    XTableFestivalMail = {
        Id = ValueTypeint,
        FestivalId = ValueTypeint,
        CharacterId = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableFestivalStage = {
        StageId = ValueTypeintPrimaryKey,
        StageName = ValueTypestring,
        StageStyle = ValueTypestring,
        OpenConditionId = Type1ValueTypeint,
        UnlockType = ValueTypeint,
    },
    XTableFetter = {
        Level = ValueTypeintPrimaryKey,
        Exp = ValueTypeint,
        Add = ValueTypeint,
    },
    XTableFetterType = {
        Id = ValueTypeint,
        Type = ValueTypeint,
        Min = ValueTypeint,
        Max = ValueTypeint,
        Count = ValueTypeint,
    },
    XTableFightBrilliantwalk = {
        Id = ValueTypeintPrimaryKey,
        EffectName = ValueTypestring,
        TypeToPrefabPaths = Type1ValueTypestring,
    },
    XTableFightEvent = {
        Id = ValueTypeintPrimaryKey,
        ConditionId = Type1ValueTypeint,
        BornMagic = Type1ValueTypeint,
        EnemyBornMagic = Type1ValueTypeint,
        PartnerBornMagic = Type1ValueTypeint,
        Description = ValueTypestring,
    },
    XTableFightMapData = {
        Id = ValueTypeintPrimaryKey,
        MiddlePointX = ValueTypefloat,
        MiddlePointY = ValueTypefloat,
        WorldSize = ValueTypefloat,
        PixelRatio = ValueTypefloat,
        PixelSize = ValueTypefloat,
        CameraHigh = ValueTypefloat,
        ResUrl = ValueTypestring,
    },
    XTableFightMapDataLut = {
        MapId = ValueTypeintPrimaryKey,
        HasStaticMapPin = ValueTypebool,
        HasStaticMapPinFunc = ValueTypebool,
    },
    XTableFightMapPinFunc = {
        Id = ValueTypeintPrimaryKey,
        FuncName = ValueTypestring,
        FuncParam = Type1ValueTypestring,
    },
    XTableFightMapPinTemplate = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        TemplateDesc = ValueTypestring,
        IntParams = Type1ValueTypeint,
        FloatParams = Type1ValueTypefloat,
        StrParams = Type1ValueTypestring,
        CBText = Type1ValueTypestring,
        CBFunc = Type1ValueTypestring,
    },
    XTableFightPasswordGame = {
        Id = ValueTypeintPrimaryKey,
        MinPasswordMapId = ValueTypeint,
        MaxPasswordMapId = ValueTypeint,
        CorrectPasswords = Type1ValueTypeint,
    },
    XTableFightStaticMapPin = {
        Id = ValueTypeintPrimaryKey,
        MapPinGroup = ValueTypeint,
        MapPinId = ValueTypeint,
        MapPinTemplateId = ValueTypeint,
        PinName = ValueTypestring,
        PinDesc = ValueTypestring,
        PosX = ValueTypefix,
        PosY = ValueTypefix,
        UniqueClickCB = ValueTypebool,
        CBText = Type1ValueTypestring,
        CBFunc = Type1ValueTypestring,
    },
    XTableFightWords = {
        Group = ValueTypeint,
        Text = ValueTypestring,
        Duration = Type1ValueTypefloat,
        CvId = ValueTypeint,
        WordsIndex = ValueTypeint,
    },
    XTableFingerGuessingActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        CoinItemId = ValueTypeint,
        DefaultCoinNum = ValueTypeint,
        HeroName = ValueTypestring,
        HeroImage = ValueTypestring,
        PlayerPortraits = ValueTypestring,
        StartMovieId = ValueTypestring,
    },
    XTableFingerGuessingConfig = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypestring,
    },
    XTableFingerGuessingFinger = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableFingerGuessingStage = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        StageName = ValueTypestring,
        LockStageName = ValueTypestring,
        Description = ValueTypestring,
        OpenEyeTipsTitle = ValueTypestring,
        OpenEyeTipsContent = ValueTypestring,
        WinTalk = ValueTypestring,
        LoseTalk = ValueTypestring,
        RobotImage = ValueTypestring,
        RobotPortraits = ValueTypestring,
        StageLockRobotPortraits = ValueTypestring,
        CostItemCount = ValueTypeint,
        CheatCount = ValueTypeint,
        PreStageId = ValueTypeint,
        WinScore = ValueTypeint,
        StartMovieId = ValueTypestring,
        EndMovieId = ValueTypestring,
    },
    XTableFingerGuessingStageRound = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Round = ValueTypeint,
        Tricks = Type1ValueTypebool,
    },
    XTableFirstPayReward = {
        Id = ValueTypeintPrimaryKey,
        NeedPayMoney = ValueTypefloat,
        BigRewardId = ValueTypeint,
        SmallRewardId = ValueTypeint,
    },
    XTableFlopReward = {
        Id = ValueTypeintPrimaryKey,
        ConsumeItemId = ValueTypeint,
        ConsumeItemCount = ValueTypeint,
        ExtraActionPoint = ValueTypeint,
        ShowRewardId = ValueTypeint,
        DropId = ValueTypeint,
        ShowDropId = ValueTypeint,
    },
    XTableFoolsDayActivityBroadcast = {
        Id = ValueTypeintPrimaryKey,
        Content = ValueTypestring,
        Condition = ValueTypeint,
        TimeId = ValueTypeint,
        IntervalTime = ValueTypeint,
        UiStyle = ValueTypeint,
        TipMoveDuration = ValueTypeint,
        TipStayTime = ValueTypeint,
    },
    XTableFoolsDayClearOut = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        NeedAtkTimes = ValueTypeint,
    },
    XTableFoolsDayClearOutConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Param = Type1ValueTypestring,
    },
    XTableFoolsDayMainInterface = {
        Id = ValueTypeintPrimaryKey,
        RoleId = ValueTypeint,
        SceneId = ValueTypeint,
        ClearOutActionIds = Type1ValueTypestring,
        ClearOutContents = Type1ValueTypestring,
        ContentShowTimeList = Type1ValueTypefloat,
    },
    XTableFpsGameActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
    },
    XTableFpsGameChapter = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        OpenTimeId = ValueTypeint,
        StarRewardGroupId = ValueTypeint,
        Condition = ValueTypeint,
        PlayerRobotId = ValueTypeint,
        Robot = Type1ValueTypeint,
    },
    XTableFpsGameClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableFpsGameScore = {
        Id = ValueTypeintPrimaryKey,
        Score = ValueTypeint,
        Type = ValueTypeint,
        Divisor = ValueTypeint,
        Desc = ValueTypestring,
        Order = ValueTypeint,
        TipsDesc = ValueTypestring,
        TipsScore = ValueTypestring,
    },
    XTableFpsGameScoreLevel = {
        Id = ValueTypeintPrimaryKey,
        MinScore = ValueTypeint,
        MaxScore = ValueTypeint,
        LevelName = ValueTypestring,
        LevelIcon = ValueTypestring,
    },
    XTableFpsGameStage = {
        StageId = ValueTypeintPrimaryKey,
        PreStageId = ValueTypeint,
        ChapterId = ValueTypeint,
        MapPoint = ValueTypeint,
        StarCount = ValueTypeint,
        Name = ValueTypestring,
        NodeType = ValueTypeint,
        NodeParam = Type1ValueTypeint,
        StarDesc = Type1ValueTypestring,
        UnlockWeapon = ValueTypeint,
        BuffIcon = Type1ValueTypestring,
        BuffTitle = Type1ValueTypestring,
        BuffDesc = Type1ValueTypestring,
        SelectWeapons = Type1ValueTypeint,
        OnlyUseRobotId = ValueTypeint,
        ExtraRobotID = ValueTypeint,
        CallId = ValueTypeint,
    },
    XTableFpsGameStarReward = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Star = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableFpsGameWeapon = {
        Id = ValueTypeintPrimaryKey,
        TemplateId = ValueTypeint,
        Name = ValueTypestring,
        UnlockCondition = ValueTypeint,
        Icon = ValueTypestring,
        Title = ValueTypestring,
        SkillIcon = Type1ValueTypestring,
        SkillName = Type1ValueTypestring,
        SkillDesc = Type1ValueTypestring,
        SkillVideoUrl = Type1ValueTypestring,
        Fightevent = Type1ValueTypeint,
    },
    XTableFragment = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        RoleName = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        StageId = ValueTypeint,
        CoverId = ValueTypeint,
    },
    XTableFubenActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ManagerName = ValueTypestring,
        Icon = ValueTypestring,
        TimeId = ValueTypeint,
        ShowConditionId = ValueTypeint,
        FunctionNameId = ValueTypeint,
        SkipId = ValueTypeint,
        Order = ValueTypeint,
        RedPointConditions = Type1ValueTypestring,
        RedParam = ValueTypeint,
        Note = ValueTypestring,
        IsAgency = ValueTypeint,
        IsRecord = ValueTypebool,
    },
    XTableFubenActivityTimeTips = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableFubenBranchActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ActivityTimeId = ValueTypeint,
        FightTimeId = ValueTypeint,
        ChallengeTimeId = ValueTypeint,
    },
    XTableFubenBranchChallenge = {
        Id = ValueTypeintPrimaryKey,
        OrderId = ValueTypestring,
        Name = ValueTypestring,
        OpenCondition = ValueTypeint,
        Description = ValueTypestring,
        Prefab = ValueTypestring,
        Cover = ValueTypestring,
        Bg1 = ValueTypestring,
        Bg2 = ValueTypestring,
        MoveStageIndex = Type1ValueTypeint,
        DatumLinePrecent = ValueTypefloat,
        StageId = Type1ValueTypeint,
    },
    XTableFubenBranchSection = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        MinLevel = ValueTypeint,
        MaxLevel = ValueTypeint,
        ShowRewardId = ValueTypeint,
        NormalId = ValueTypeint,
        DifficultyId = ValueTypeint,
        SkipId = ValueTypeint,
    },
    XTableFubenChallengeBanner = {
        Id = ValueTypeint,
        Type = ValueTypeintPrimaryKey,
        NameEn = ValueTypestring,
        SimpleDesc = ValueTypestring,
        Icon = ValueTypestring,
        IconMain = ValueTypestring,
        IsClose = ValueTypebool,
        ResetType = ValueTypeint,
        ResetTime = ValueTypestring,
        ResetInterval = ValueTypeint,
        ShopId = ValueTypeint,
        IsOpen = ValueTypeint,
        Priority = ValueTypeint,
        ShowNewStartTime = ValueTypestring,
        ShowNewEndTime = ValueTypestring,
        FunctionId = ValueTypeint,
        SkipId = ValueTypeint,
        RewardId = ValueTypeint,
        RedPointConditions = Type1ValueTypestring,
    },
    XTableFubenClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableFubenCollegeBanner = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        NameEn = ValueTypestring,
        SimpleDesc = ValueTypestring,
        Icon = ValueTypestring,
        Priority = ValueTypeint,
        FunctionId = ValueTypeint,
        SkipId = ValueTypeint,
        RedPointConditions = Type1ValueTypestring,
    },
    XTableFubenFeatures = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        TriangleBg = ValueTypestring,
    },
    XTableFubenSecondTag = {
        Id = ValueTypeintPrimaryKey,
        FirstTagId = ValueTypeint,
        Order = ValueTypeint,
        TagName = ValueTypestring,
        ChapterType = Type1ValueTypeint,
        ChapterTypeShowCondition = Type1ValueTypeint,
        Bg = ValueTypestring,
        CustomParams = Type1ValueTypestring,
        ShowCondition = ValueTypeint,
    },
    XTableFubenStageCharacterLimit = {
        Id = ValueTypeintPrimaryKey,
        BuffId = Type1ValueTypeint,
    },
    XTableFubenStoryLine = {
        Id = ValueTypeintPrimaryKey,
        ChapterType = ValueTypeint,
        ChapterId = ValueTypeint,
        Condition = ValueTypeint,
        SkipCondition = ValueTypeint,
    },
    XTableFubenTabConfig = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        AssetPath = ValueTypestring,
        IconPath = ValueTypestring,
        ProxyPath = ValueTypestring,
        UiParentName = ValueTypestring,
        ConditionDesc = ValueTypestring,
        UnlockCondition = ValueTypeint,
        Params = Type1ValueTypestring,
    },
    XTableFunctionalCommunication = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ConditionIds = Type1ValueTypeint,
        Priority = ValueTypeint,
        SkipId = ValueTypeint,
        BtnContent = ValueTypestring,
        NpcName = ValueTypestring,
        NpcHandIcon = ValueTypestring,
        Type = ValueTypeint,
        UiType = ValueTypeint,
        ContentsGroupId = ValueTypeint,
    },
    XTableFunctionalContents = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Type = ValueTypeint,
        NpcName = ValueTypestring,
        NpcHalfIconPath = ValueTypestring,
        Contents = ValueTypestring,
        CueId = ValueTypeint,
        ContentsSkip = ValueTypeint,
        OptionTitle = Type1ValueTypestring,
        Optionskip = Type1ValueTypeint,
    },
    XTableFunctionalContentsGroupFirstMap = {
        Id = ValueTypeintPrimaryKey,
        FirstContentId = ValueTypeint,
    },
    XTableFunctionalEntranceConfig = {
        FunctionId = ValueTypeintPrimaryKey,
        Label = Type1ValueTypestring,
        Icon = Type1ValueTypestring,
        TaskId = Type1ValueTypeint,
        LabelTimeId = ValueTypeint,
        RedPointNum = ValueTypeint,
    },
    XTableFunctionalFestivalCommunication = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ConditionIds = Type1ValueTypeint,
        Priority = ValueTypeint,
        SkipId = ValueTypeint,
        BtnContent = ValueTypestring,
        NpcName = ValueTypestring,
        NpcHandIcon = ValueTypestring,
        Type = ValueTypeint,
        UiType = ValueTypeint,
        StartTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
        ContentsGroupId = ValueTypeint,
    },
    XTableFunctionalOpen = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        Hint = ValueTypeint,
        Condition = Type1ValueTypeint,
        Type = ValueTypeint,
        FunctionType = ValueTypeint,
    },
    XTableFunctionalShow = {
        Id = ValueTypeintPrimaryKey,
        ShowCondition = ValueTypeint,
        UnlockCondition = ValueTypeint,
        IsCheckHideFunc = ValueTypebool,
        FunctionId = ValueTypeint,
        RedPointShowPreCondition = Type1ValueTypeint,
        RedPointConditions = Type1ValueTypestring,
        RedPointArgs = Type1ValueTypeint,
        RedPointTypes = Type1ValueTypeint,
        EventIds = Type1ValueTypestring,
    },
    XTableFunctionDevice = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Des = ValueTypestring,
        BelongType = ValueTypeint,
        Type = ValueTypeint,
        Level = ValueTypeint,
        ConditionId = ValueTypeint,
        CostId = ValueTypeint,
        CostCount = ValueTypeint,
        CostTime = ValueTypeint,
        FunctionParam = Type1ValueTypeint,
    },
    XTableFunctionIdFashionRelative = {
        FunctionId = ValueTypeintPrimaryKey,
        FashionIds = Type1ValueTypeint,
        IsWeakInterput = ValueTypebool,
    },
    XTableFurniture = {
        Id = ValueTypeintPrimaryKey,
        MaxCount = ValueTypeint,
        Width = ValueTypeint,
        Height = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        SmallIcon = ValueTypestring,
        Quality = ValueTypeint,
        Model = ValueTypestring,
        Desc = ValueTypestring,
        TypeId = ValueTypeint,
        LocateType = ValueTypeint,
        IsObstacle = ValueTypeint,
        SuitId = ValueTypeint,
        GainType = ValueTypeint,
        InitAttr = ValueTypeint,
        CreateTime = ValueTypeint,
        RandomGroupId = ValueTypeint,
        InteractRange = ValueTypeint,
        InteractWeight = ValueTypeint,
        InteractPos = ValueTypeint,
        InteractName = ValueTypestring,
        ReturnId = ValueTypeint,
        PicId = ValueTypeint,
        PicNum = ValueTypeint,
        MoneyNum = ValueTypeint,
        IlluminationSO = ValueTypestring,
        PointLight = ValueTypestring,
        BehaviorType = Type1ValueTypestring,
        AttractBehaviorType = Type1ValueTypestring,
        AnimationId = ValueTypeint,
        AttrTagY = ValueTypefloat,
        FunitureBehaviorType = ValueTypestring,
        PutOnWidgetHight = ValueTypefloat,
        HasBehavior = ValueTypebool,
        PosChangeType = ValueTypeint,
        PutNumType = ValueTypeint,
        IsDefaultLocked = ValueTypebool,
        PetId = ValueTypeint,
        ShowTimeStr = ValueTypestring,
    },
    XTableFurnitureAdditionalAttr = {
        AttributeId = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        AddType = ValueTypeint,
        AddValue = Type1ValueTypeint,
        AddScore = ValueTypeint,
        RestrictedRole = Type1ValueTypeint,
        Introduce = ValueTypestring,
        QualityType = ValueTypeint,
    },
    XTableFurnitureAdditionalAttrRandom = {
        Id = ValueTypeint,
        GroupId = ValueTypeint,
        AttrId = ValueTypeint,
        Weight = ValueTypeint,
        Introduce = ValueTypestring,
    },
    XTableFurnitureAttr = {
        Id = ValueTypeint,
        Type = ValueTypeint,
        Value = ValueTypeint,
    },
    XTableFurnitureAttrType = {
        Id = ValueTypeint,
        AttrName = ValueTypestring,
        AttrIcon = ValueTypestring,
    },
    XTableFurnitureBaseAttr = {
        Id = ValueTypeintPrimaryKey,
        Value = ValueTypeint,
    },
    XTableFurnitureBehavior = {
        Id = ValueTypeintPrimaryKey,
        FurnitureId = ValueTypeint,
        State = ValueTypestring,
        BehaviorId = ValueTypestring,
    },
    XTableFurnitureCreateAttr = {
        Id = ValueTypeintPrimaryKey,
        FurnitureType = ValueTypeint,
        MinConsume = ValueTypeint,
        AttrTotal = Type1ValueTypeint,
        AttrWeight = Type1ValueTypeint,
        ExtraAttrTotal = Type1ValueTypeint,
        ExtraAttrWeight = Type1ValueTypeint,
    },
    XTableFurnitureExtraAttr = {
        Id = ValueTypeintPrimaryKey,
        BaseAttrId = ValueTypeint,
        RemakeExtraAttrId = ValueTypeint,
        AttrIds = Type1ValueTypeint,
    },
    XTableFurnitureLevel = {
        Id = ValueTypeintPrimaryKey,
        FurnitureType = ValueTypeint,
        AttrScore = Type1ValueTypeint,
        MinScore = ValueTypeint,
        MaxScore = ValueTypeint,
        ReturnId = ValueTypeint,
        Quality = ValueTypeint,
    },
    XTableFurniturePutNum = {
        PutId = ValueTypeintPrimaryKey,
        PutCount = ValueTypeint,
    },
    XTableFurnitureReward = {
        Id = ValueTypeintPrimaryKey,
        FurnitureId = ValueTypeint,
        ExtraAttrId = ValueTypeint,
        AdditionId = ValueTypeint,
        Quality = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableFurnitureSingleAttrLevel = {
        Id = ValueTypeintPrimaryKey,
        FurnitureType = ValueTypeint,
        AttrMinScore = Type1ValueTypeint,
        AttrMaxScore = Type1ValueTypeint,
        Quality = ValueTypeint,
    },
    XTableFurnitureSuit = {
        Id = ValueTypeintPrimaryKey,
        SuitName = ValueTypestring,
        IsIgnoreWhenCreate = ValueTypeint,
        IsIgnoreWhenRemodule = ValueTypebool,
        IgnoreRecovery = ValueTypebool,
        SuitIcon = ValueTypestring,
        SuitBigIcon = ValueTypestring,
        ShowTimeStr = ValueTypestring,
    },
    XTableFurnitureType = {
        Id = ValueTypeintPrimaryKey,
        Priority = ValueTypeint,
        MajorType = ValueTypeint,
        MajorName = ValueTypestring,
        MinorType = ValueTypeint,
        MinorName = ValueTypestring,
        Category = ValueTypeint,
        CategoryName = ValueTypestring,
        TypeIcon = ValueTypestring,
        BtnIcon = ValueTypestring,
    },
    XTableFurnitureViewAngle = {
        MinorType = ValueTypeintPrimaryKey,
        MinorName = ValueTypestring,
        TargetAngleY = ValueTypeint,
        AllowYAxis = ValueTypeint,
        GroupId = ValueTypeint,
    },
    XTableFurntiureColour = {
        Id = ValueTypeintPrimaryKey,
        AttrIds = Type1ValueTypeint,
        FurnitureMaterials = Type1ValueTypestring,
        DefaultMaterial = ValueTypestring,
        FurnitureFx = Type1ValueTypestring,
        DefaultFurnitureFx = ValueTypestring,
        FurnitureIcons = Type1ValueTypestring,
        DefaultFurnitureIcon = ValueTypestring,
    },
    XTableGacha = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ConsumeId = ValueTypeint,
        ConsumeCount = ValueTypeint,
        BtnGachaCount = Type1ValueTypeint,
        OrganizeId = ValueTypeint,
        PreGachaId = ValueTypeint,
        OrganizeSort = ValueTypeint,
        PropStartTimes = ValueTypeint,
        PropAdd = ValueTypeint,
        PropAddGroupId = ValueTypeint,
        GroupId = Type1ValueTypeint,
        Weight = Type1ValueTypeint,
        GachaIcon = ValueTypestring,
        ExchangeId = ValueTypeint,
        CourseRewardId = ValueTypeint,
        FestivalActivityId = ValueTypeint,
        TargetTemplateId = ValueTypeint,
        GachaShowGroupId = ValueTypeint,
        EnterVideoId = ValueTypeint,
    },
    XTableGachaCanLiver = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        FreeItemId = ValueTypeint,
        FreeItemGainUpLimit = ValueTypeint,
        FreeItemRecycleRewardId = ValueTypeint,
        CoinItemId = ValueTypeint,
        ResidentShopId = ValueTypeint,
        TimelimitShopId = ValueTypeint,
        RecycleRewardId = ValueTypeint,
        TaskGroupId = ValueTypeint,
        TaskIds = Type1ValueTypeint,
        TaskTimeLimitGroupIds = Type1ValueTypeint,
        ResidentGachaId = ValueTypeint,
        IsDefault = ValueTypebool,
        TimeLimitGachaIds = Type1ValueTypeint,
        TimeLimitGachaConditionIds = Type1ValueTypeint,
    },
    XTableGachaCanLiverShop = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ConditionIds = Type1ValueTypeint,
    },
    XTableGachaCanLiverShow = {
        Id = ValueTypeintPrimaryKey,
        ShopShowRewardId = ValueTypeint,
        CharacterId = ValueTypeint,
        SpecialRewardLimitCount = ValueTypeint,
        PanelAssetItemIds = Type1ValueTypeint,
        MainPrefabAddress = ValueTypestring,
    },
    XTableGachaClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Value = Type1ValueTypestring,
    },
    XTableGachaCourseReward = {
        Id = ValueTypeintPrimaryKey,
        LimitDrawTimes = Type1ValueTypeint,
        RewardIds = Type1ValueTypeint,
        RewardNames = Type1ValueTypestring,
    },
    XTableGachaFashionSelfChoiceActivity = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        TimeId = ValueTypeint,
        GachaGroupIds = Type1ValueTypeint,
    },
    XTableGachaFashionSelfChoiceGroup = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        TimeId = ValueTypeint,
        GachaIds = Type1ValueTypeint,
        RuleTitle = Type1ValueTypestring,
        RuleText = Type1ValueTypestring,
    },
    XTableGachaFashionSelfChoiceResources = {
        GachaId = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        SkipId = ValueTypeint,
        EntranceIcon = ValueTypestring,
        VideoConfigId = ValueTypeint,
        SpecialRewardTemplateIds = Type1ValueTypeint,
    },
    XTableGachaItemExchange = {
        Id = ValueTypeintPrimaryKey,
        BuyCountMax = ValueTypeint,
        UseItemIds = Type1ValueTypeint,
        UseItemCounts = Type1ValueTypeint,
        Sales = Type2KeyTypeintValueTypestring,
        UseItemImgs = Type1ValueTypestring,
        TargetItemImg = ValueTypestring,
        TotalBuyCountMax = ValueTypeint,
    },
    XTableGachaProbShow = {
        GachaId = ValueTypeintPrimaryKey,
        IsRare = Type1ValueTypebool,
        TemplateId = Type1ValueTypeint,
        Name = Type1ValueTypestring,
        Type = Type1ValueTypeint,
        ProbShowList = Type1ValueTypestring,
    },
    XTableGachaReward = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        UsableTimes = ValueTypeint,
        TemplateId = ValueTypeint,
        Count = ValueTypeint,
        Params = Type1ValueTypeint,
        Weight = ValueTypeint,
        Rare = ValueTypebool,
        Priority = ValueTypeint,
        RewardType = ValueTypeint,
        Note = ValueTypestring,
        Rarelevel = ValueTypeint,
    },
    XTableGachaRule = {
        Id = ValueTypeintPrimaryKey,
        GachaName = ValueTypestring,
        GachaName2 = ValueTypestring,
        UiType = ValueTypeint,
        UiName = ValueTypestring,
        StageLineUiName = ValueTypestring,
        SceneModelId = ValueTypeint,
        RuleHint = ValueTypestring,
        PreviewShowCount = ValueTypeint,
        ItemNotEnoughSkipId = ValueTypeint,
        BaseRuleTitles = Type1ValueTypestring,
        BaseRules = Type1ValueTypestring,
    },
    XTableGachaSceneInteract = {
        Id = ValueTypeintPrimaryKey,
        SceneId = ValueTypeint,
        TipsPanelContent = ValueTypestring,
    },
    XTableGachaShow = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        GroupId = ValueTypeint,
        TypeText = ValueTypestring,
        QualityText = Type1ValueTypestring,
        UiAnim = ValueTypestring,
        UiResultAnim = ValueTypestring,
        DrawEffectGroupId = Type1ValueTypeint,
        GachaEffectGroupId = Type1ValueTypeint,
        DrawPictureGroupId = Type1ValueTypeint,
    },
    XTableGachaShowRewardConfig = {
        Id = ValueTypeintPrimaryKey,
        EffectQualityType = ValueTypeint,
    },
    XTableGame2048Activity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        ShopId = ValueTypeint,
    },
    XTableGame2048Block = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Level = ValueTypeint,
        ShowLevel = ValueTypestring,
        LevelUpId = ValueTypeint,
        AddScore = ValueTypeint,
        GenPriority = ValueTypeint,
        HitTimes = ValueTypeint,
        DoublingLevelUpId = ValueTypeint,
        AdjustLevelUpId = ValueTypeint,
        IconRes = ValueTypestring,
        BgRes = ValueTypestring,
        EffectRes = ValueTypestring,
        LastLevelId = ValueTypeint,
    },
    XTableGame2048BlockType = {
        Type = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        CanDispel = ValueTypebool,
        CanMerge = ValueTypebool,
        CanMove = ValueTypebool,
        MergeResults = Type2KeyTypeintValueTypeint,
    },
    XTableGame2048Board = {
        Id = ValueTypeintPrimaryKey,
        BoardId = ValueTypeint,
        BoardLv = ValueTypeint,
        FeverState = ValueTypeint,
        TargetBlockId = ValueTypeint,
        GeneratedGroupId = ValueTypeint,
        FeverTimePlus = ValueTypeint,
        BoardScore = ValueTypeint,
        TransBlockId = ValueTypeint,
        Tips = ValueTypestring,
    },
    XTableGame2048BoardShow = {
        Id = ValueTypeintPrimaryKey,
        ShowConditionId = ValueTypeint,
        ShowAct = ValueTypestring,
        ShowTalk = ValueTypestring,
        UiVfx = ValueTypestring,
    },
    XTableGame2048BoardShowGroup = {
        Id = ValueTypeintPrimaryKey,
        Stand = ValueTypestring,
        BoardShowIds = Type1ValueTypeint,
    },
    XTableGame2048Buff = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        IconRes = ValueTypestring,
        TriggerCD = ValueTypeint,
        TriggerBlockId = ValueTypeint,
        TriggerReplaceType = ValueTypeint,
        ReplaceValueFormBlockTypes = Type1ValueTypeint,
        TriggerFeverLv = ValueTypeint,
        TriggerCountLimit = ValueTypeint,
        TriggerRate = ValueTypeint,
    },
    XTableGame2048Chapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        Condition = ValueTypeint,
        StageIds = Type1ValueTypeint,
        TitleIcon = ValueTypestring,
        FullBg = ValueTypestring,
    },
    XTableGame2048ChapterShow = {
        ChapterId = ValueTypeintPrimaryKey,
        StageEntranceIcon = ValueTypestring,
        StageEntranceSelectedIcon = ValueTypestring,
        GameBoardBg = ValueTypestring,
        GameBoardBgMask = ValueTypestring,
        ScoreNumberColor = ValueTypestring,
        ScoreLabelColor = ValueTypestring,
        GameBoardBlocksBg = ValueTypestring,
        GameBoardGridBg = Type1ValueTypestring,
        StepColor = ValueTypestring,
        BuffCdBgColor = ValueTypestring,
        BuffCdNumColor = ValueTypestring,
    },
    XTableGame2048ClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableGame2048GeneratedGroup = {
        Id = ValueTypeintPrimaryKey,
        BlockIds = Type1ValueTypeint,
        Num = Type1ValueTypeint,
    },
    XTableGame2048Initialize = {
        Id = ValueTypeintPrimaryKey,
        InitializeId = ValueTypeint,
        BlockPosX = ValueTypeint,
        BlockPosY = ValueTypeint,
        BlockId = ValueTypeint,
    },
    XTableGame2048Item = {
        Id = ValueTypeintPrimaryKey,
        ChargeSteps = ValueTypeint,
        MaxCount = ValueTypeint,
        BuffId = ValueTypeint,
        IconRes = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableGame2048ShowCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableGame2048Stage = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        PreStageId = ValueTypeint,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        ShowCharacterId = ValueTypeint,
        DispelRule = ValueTypeint,
        BoardShowGroupId = ValueTypeint,
        InitializeId = ValueTypeint,
        BoardId = ValueTypeint,
        Steps = ValueTypeint,
        EntranceEmojiIcon = ValueTypestring,
        BuffIds = Type1ValueTypeint,
        Scores = Type1ValueTypeint,
        RewardIds = Type1ValueTypeint,
        StarDescs = Type1ValueTypestring,
        InitBuffCharge = Type1ValueTypeint,
    },
    XTableGameCollection = {
        GameType = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        StageId = ValueTypeint,
        TimeId = ValueTypeint,
        Image = ValueTypestring,
    },
    XTableGameCollectionActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        TaskTimeLimitIds = Type1ValueTypeint,
        ShopId = ValueTypeint,
    },
    XTableGameCollectionConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableGoldenMinerActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MaxItemColumnCount = ValueTypeint,
        BaseRankNum = ValueTypeint,
        RandMinValue = ValueTypeint,
        RandMaxValue = ValueTypeint,
        TotalHideStageCount = ValueTypeint,
        Name = ValueTypestring,
        BannerBg = ValueTypestring,
        HexSelectStages = Type1ValueTypeint,
        HexMapStages = Type1ValueTypeint,
    },
    XTableGoldenMinerBuff = {
        BuffId = ValueTypeintPrimaryKey,
        BuffEffect = ValueTypestring,
        BuffType = ValueTypeint,
        DisplayType = ValueTypeint,
        DisplayPriority = ValueTypeint,
        Params = Type1ValueTypeint,
        BuffInit = Type1ValueTypeint,
        BuffCover = Type1ValueTypeint,
        TimeType = ValueTypeint,
        TimeTypeParam = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableGoldenMinerCharacter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Condition = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        ModelId = ValueTypestring,
        Info = ValueTypestring,
        HeadPath = ValueTypestring,
        SkillName = ValueTypestring,
        SkillDesc = ValueTypestring,
        EnName = ValueTypestring,
        DefaultFace = ValueTypestring,
    },
    XTableGoldenMinerClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Common = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableGoldenMinerFace = {
        Id = ValueTypeintPrimaryKey,
        FaceImage = ValueTypestring,
        FaceGroup = ValueTypeint,
        Weight = ValueTypeint,
        Score = ValueTypeint,
    },
    XTableGoldenMinerFalculaType = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ColliderName = ValueTypestring,
        OffsetXPercent = ValueTypeint,
        OffsetYPercent = ValueTypeint,
        RadiusPercent = ValueTypeint,
        SizeXPercent = ValueTypeint,
        SizeYPercent = ValueTypeint,
        ShipTip = ValueTypestring,
        ButtonTip = ValueTypestring,
        IgnoreStoneTypeList = Type1ValueTypeint,
    },
    XTableGoldenMinerHex = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        HexType = ValueTypeint,
        DropMapGroupId = ValueTypeint,
        HexUpgradeId = ValueTypeint,
        Anti = Type1ValueTypeint,
    },
    XTableGoldenMinerHexUpgrade = {
        Id = ValueTypeintPrimaryKey,
        HexId = ValueTypeint,
        UpgradeInit = Type1ValueTypeint,
        BuffList = Type1ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableGoldenMinerHideTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        TaskType = ValueTypeint,
        FinishProgress = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableGoldenMinerHideTaskMapDrawGroup = {
        Id = ValueTypeintPrimaryKey,
        MapId = ValueTypeint,
        StoneIdIndex = ValueTypeint,
        IsStay = ValueTypeint,
    },
    XTableGoldenMinerItem = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Describe = ValueTypestring,
        ItemType = ValueTypeint,
        BuyCost = ValueTypeint,
        BuffId = ValueTypeint,
        RemainingTimes = ValueTypeint,
        Icon = ValueTypestring,
        UseSoundId = ValueTypeint,
        SellPrice = ValueTypeint,
        UseFaceId = ValueTypeint,
        TipsType = ValueTypeint,
        TipsTxt = ValueTypestring,
    },
    XTableGoldenMinerMap = {
        MapId = ValueTypeintPrimaryKey,
        MaxScores = ValueTypeint,
        Time = ValueTypeint,
        MapType = ValueTypeint,
        IsOpenSlotsScore = ValueTypebool,
        SunMoonInitialType = ValueTypeint,
        PreviewPic = ValueTypestring,
        StoneId = Type1ValueTypeint,
        XPosPercent = Type1ValueTypeint,
        YPosPercent = Type1ValueTypeint,
        Scale = Type1ValueTypeint,
        RotationZ = Type1ValueTypeint,
        HideTask = Type1ValueTypeint,
    },
    XTableGoldenMinerMapDrop = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        MapId = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableGoldenMinerPartner = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Prefab = ValueTypestring,
        TriggerEffect = ValueTypestring,
        TriggerSoundId = ValueTypeint,
        MoveSpeed = ValueTypeint,
        RangeXMin = ValueTypeint,
        RangeXMax = ValueTypeint,
        RangeYMin = ValueTypeint,
        RangeYMax = ValueTypeint,
        IgnoreStoneConfigKey = ValueTypestring,
        IntParam = Type1ValueTypeint,
        FloatParam = Type1ValueTypefloat,
        StringParam = Type1ValueTypestring,
    },
    XTableGoldenMinerQTELevelGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Type = ValueTypeint,
        ClickCount = ValueTypeint,
        DownTime = ValueTypefloat,
        SpeedRate = ValueTypefloat,
        Icon = ValueTypestring,
        Params = Type1ValueTypeint,
    },
    XTableGoldenMinerRandom = {
        Id = ValueTypeintPrimaryKey,
        Index = ValueTypeint,
        Num = ValueTypeint,
        IsHex = ValueTypeint,
        HexIndex = ValueTypeint,
    },
    XTableGoldenMinerRedEnvelopeRandPool = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        Heft = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableGoldenMinerScore = {
        Id = ValueTypeintPrimaryKey,
        LastTimeMax = ValueTypeint,
        Point = ValueTypeint,
    },
    XTableGoldenMinerShipShell = {
        Id = ValueTypeintPrimaryKey,
        ShellRawImage = ValueTypestring,
    },
    XTableGoldenMinerShopDrop = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        DropType = ValueTypeint,
        RefreshType = ValueTypeint,
        ItemId = ValueTypeint,
        SingleFieldCount = ValueTypeint,
        AllFieldCount = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableGoldenMinerStage = {
        StageId = ValueTypeintPrimaryKey,
        TeachMap = ValueTypeint,
        MoveHexMap = ValueTypeint,
        TargetScore = ValueTypeint,
        FixTargetScore = ValueTypeint,
        PreStage = ValueTypeint,
        NextStage = ValueTypeint,
        CommonHexSelect = ValueTypeint,
        CommonRefreshCount = ValueTypeint,
        DropShopGroupId = ValueTypeint,
        DropMapGroupId = ValueTypeint,
        HideMapGroupId = ValueTypeint,
        HideTaskFinishCount = ValueTypeint,
        ShopGridCount = ValueTypeint,
        ActivityId = ValueTypeint,
        GridUseDrops = Type1ValueTypeint,
    },
    XTableGoldenMinerStone = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        LevelUpId = ValueTypeint,
        Type = ValueTypeint,
        Prefab = ValueTypestring,
        Score = ValueTypeint,
        MoveType = ValueTypeint,
        StartMoveDirection = ValueTypeint,
        MoveRange = ValueTypeint,
        MoveSpeed = ValueTypeint,
        Weight = ValueTypeint,
        BornDelay = ValueTypefloat,
        DestoryTime = ValueTypefloat,
        CarryStoneId = ValueTypeint,
        CatchEffect = ValueTypestring,
        IsBoomDestroy = ValueTypeint,
        InitialType = ValueTypeint,
        IntParams = Type1ValueTypeint,
        FloatParams = Type1ValueTypefloat,
    },
    XTableGoldenMinerStoneType = {
        Type = ValueTypeintPrimaryKey,
        GrabFaceId = ValueTypeint,
        Icon = ValueTypestring,
        IsSlotAnyType = ValueTypebool,
    },
    XTableGoldenMinerTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TaskId = Type1ValueTypeint,
    },
    XTableGoldenMinerUpgrade = {
        Id = ValueTypeintPrimaryKey,
        UpgradeCosts = Type1ValueTypeint,
        UpgradeBuffs = Type1ValueTypeint,
        Conditions = Type1ValueTypeint,
        Type = ValueTypeint,
        LocalIds = Type1ValueTypeint,
        LvMaxShipKey = ValueTypestring,
        IsOpen = ValueTypeint,
    },
    XTableGoldenMinerUpgradeLocal = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Describe = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableGoods = {
        Id = ValueTypeint,
        Priority = ValueTypeint,
        ObtainId = ValueTypeint,
        ObtainCount = ValueTypeint,
        ObtainParamStr = ValueTypestring,
        ConsumeId = Type1ValueTypeint,
        ConsumeCount = Type1ValueTypeint,
        IsShowWhenSaleTimeLimit = ValueTypebool,
        StartTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
        BuyTimesLimit = ValueTypeint,
        OnSaleStr = ValueTypestring,
        AutoResetClockId = ValueTypeint,
        Weight = ValueTypeint,
        Tags = ValueTypeint,
        IsResetWhenShopReset = ValueTypebool,
        ConditionId = Type1ValueTypeint,
        IsUnShelve = ValueTypebool,
        IsHideWhenConditionLimit = ValueTypebool,
        GiftRewardId = ValueTypeint,
        ShowBuyResult = ValueTypeint,
        BuyPriority = ValueTypeint,
        ActivityId = ValueTypeint,
        ActivityConsumeCount = ValueTypeint,
        ActivityDiscount = ValueTypeint,
    },
    XTableGoodsBuyPriorityDesc = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
    },
    XTableGoodsGroup = {
        Id = ValueTypeint,
        ChancePercent = ValueTypeint,
        GoodsCount = ValueTypeint,
        GoodsIds = Type1ValueTypeint,
    },
    XTableGooglePlayPoints = {
        Id = ValueTypeintPrimaryKey,
        PayKey = ValueTypestring,
        GoogleProductId = ValueTypestring,
        MailId = ValueTypeint,
    },
    XTableGraph = {
        Id = ValueTypeintPrimaryKey,
        GraphName = ValueTypestring,
    },
    XTableGraphicSetting = {
        Name = ValueTypestring,
        DisplayName = ValueTypestring,
        Consumption = ValueTypeint,
    },
    XTableGuardCamp = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        RewardId = ValueTypeint,
    },
    XTableGuardCampActivity = {
        Id = ValueTypeintPrimaryKey,
        OpenTimeId = ValueTypeint,
        SupportTimeId = ValueTypeint,
        SupportItemId = ValueTypeint,
        RewardPondItemId = ValueTypeint,
        SelectCampNeedCount = ValueTypeint,
        PerSupportNum = ValueTypeint,
        TotalSupportCount = ValueTypeint,
        WinPersonalRate = ValueTypefloat,
        WinPontRate = ValueTypefloat,
        LosePersonalRate = ValueTypefloat,
        LosePontRate = ValueTypefloat,
        ResultMailId = ValueTypeint,
        CampId = Type1ValueTypeint,
        JoinNum = Type1ValueTypeint,
        PondAdd = Type1ValueTypeint,
        DrawLotteryTime = ValueTypestring,
        ShowDrawLotteryTime = ValueTypestring,
        JoinCampPurchasePackageUiType = ValueTypeint,
        JoinCampPurchasePackageId = ValueTypeint,
        SupportCampPurchasePackageUiType = ValueTypeint,
        SupportCampPurchasePackageId = ValueTypeint,
    },
    XTableGuideComplete = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Param = Type1ValueTypeint,
    },
    XTableGuideFight = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        NpcId = Type1ValueTypeint,
        Weapon = Type1ValueTypeint,
        DefaultRecordTime = ValueTypeint,
    },
    XTableGuideGroup = {
        Id = ValueTypeintPrimaryKey,
        Priority = ValueTypeint,
        Ignore = ValueTypeint,
        Desc = ValueTypestring,
        GuideType = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        CompleteId = ValueTypeint,
        ActiveUi = ValueTypestring,
        CheckNodeActive = ValueTypestring,
        RewardId = ValueTypeint,
        GroupId = ValueTypeint,
    },
    XTableGuideIcon = {
        Id = ValueTypeintPrimaryKey,
        Image = ValueTypestring,
    },
    XTableGuideStep = {
        Id = ValueTypeintPrimaryKey,
        NextStep = ValueTypeint,
        Mask = ValueTypeint,
        ConditionType = ValueTypeint,
        ConditionParam = ValueTypestring,
        CompleteType = ValueTypeint,
        CompleteParam = ValueTypestring,
        Effect = ValueTypestring,
        Arrow = ValueTypeint,
        UiName = ValueTypestring,
        IsFlow = Type1ValueTypeint,
        FlowParam = Type1ValueTypestring,
        ListIndex = Type1ValueTypeint,
        Target = Type1ValueTypestring,
        Record = ValueTypeint,
        RewardId = ValueTypeint,
        IconPos = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Text = ValueTypestring,
    },
    XTableGuideText = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Content = ValueTypestring,
    },
    XTableGuildBossBuff = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Dis = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableGuildBossData = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        StageType = ValueTypeint,
        StageId = Type1ValueTypestring,
        Robot = Type1ValueTypeint,
        StageEffect = Type1ValueTypeint,
        EffectCount = Type1ValueTypeint,
        RobotCount = ValueTypeint,
        StageCount = ValueTypeint,
        FixedRobot = Type1ValueTypeint,
    },
    XTableGuildBossFightStyle = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        MaxCount = ValueTypeint,
        Bg = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableGuildBossFightStyleSkill = {
        Id = ValueTypeintPrimaryKey,
        Style = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        UnlockLv = ValueTypeint,
        FightEventId = Type1ValueTypeint,
        Icon = ValueTypestring,
        IsCore = ValueTypeint,
        IsPermanent = ValueTypeint,
    },
    XTableGuildBossHpReward = {
        Id = ValueTypeintPrimaryKey,
        HpPercent = ValueTypeint,
        RewardId = ValueTypeint,
        NewRewardId = ValueTypeint,
        TimeId = ValueTypeint,
    },
    XTableGuildBossLevel = {
        Level = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BossHp = ValueTypeint,
        UnlockScore = ValueTypeint,
        AdditionPercent = ValueTypeint,
    },
    XTableGuildBossRankReward = {
        Id = ValueTypeintPrimaryKey,
        Percent = ValueTypeint,
        RewardId = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableGuildBossScoreReward = {
        Id = ValueTypeintPrimaryKey,
        Score = ValueTypeint,
        RewardId = ValueTypeint,
        NewRewardId = ValueTypeint,
        TimeId = ValueTypeint,
    },
    XTableGuildBossScoreRule = {
        Id = ValueTypeintPrimaryKey,
        BaseScore = ValueTypeint,
        DamageScore = ValueTypeint,
        HpMaxScore = ValueTypeint,
        CharLeftHp = ValueTypefloat,
        CharLeftHpScore = ValueTypeint,
    },
    XTableGuildBossStageEffect = {
        StageId = ValueTypeintPrimaryKey,
        EffectId = ValueTypeint,
    },
    XTableGuildBossStageInfo = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Code = ValueTypestring,
        BackGround = ValueTypestring,
        Icon = ValueTypestring,
        DetailIcon = ValueTypestring,
        BuffId = ValueTypeint,
        Limit = ValueTypestring,
        BossHead = ValueTypestring,
        Desc = Type1ValueTypestring,
        SubLevelBg = ValueTypestring,
    },
    XTableGuildBossStageRobot = {
        Id = ValueTypeintPrimaryKey,
        RobotId = Type1ValueTypeint,
        TimeId = ValueTypeint,
    },
    XTableGuildChallengeDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SkipId = ValueTypeint,
        ChallengeBg = ValueTypestring,
        ChallengeType = ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableGuildCreate = {
        Id = ValueTypeintPrimaryKey,
        DailyLimit = ValueTypeint,
        ItemId = Type1ValueTypeint,
        ItemNum = Type1ValueTypeint,
        ConditionIds = Type1ValueTypeint,
    },
    XTableGuildCustomName = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        RankLevel = ValueTypeint,
        Enable = ValueTypebool,
    },
    XTableGuildDormBgm = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        CueId = ValueTypeint,
        Image = ValueTypestring,
        Duration = ValueTypeint,
        NeedBuy = ValueTypeint,
        ExperienceTimeId = ValueTypeint,
        BgImage = ValueTypestring,
    },
    XTableGuildDormBgmList = {
        Id = ValueTypeintPrimaryKey,
        BgmIds = Type1ValueTypeint,
    },
    XTableGuildDormClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableGuildDormConfig = {
        Id = ValueTypeintPrimaryKey,
        InteractIntervalTime = ValueTypeint,
        MaxInteractIntervalTime = ValueTypeint,
        HeartbeatTimeout = ValueTypeint,
        HeartbeatInterval = ValueTypeint,
        MaxDisconnectTime = ValueTypeint,
        ReconnectInterval = ValueTypeint,
        DefaultEnterCharacterId = ValueTypeint,
        DailyInteractRewardId = ValueTypeint,
        DailyInteractRewardTimesMin = ValueTypeint,
        DailyInteractRewardTimesMax = ValueTypeint,
        SetRoomThemeCd = ValueTypeint,
        CommonDefaultBgmListId = ValueTypeint,
    },
    XTableGuildDormDefaultFurniture = {
        Id = ValueTypeintPrimaryKey,
        ThemeId = ValueTypeint,
        FurnitureId = ValueTypeint,
    },
    XTableGuildDormDialog = {
        Id = ValueTypeintPrimaryKey,
        Content = Type1ValueTypestring,
        Time = Type1ValueTypeint,
    },
    XTableGuildDormEffect = {
        Id = ValueTypeintPrimaryKey,
        Path = ValueTypestring,
    },
    XTableGuildDormFurniture = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Width = ValueTypeint,
        Height = ValueTypeint,
        Name = ValueTypestring,
        IsShowName = ValueTypebool,
        NameHeightOffset = ValueTypefloat,
        IsGetReward = ValueTypebool,
        RewardHeightOffset = ValueTypefloat,
        IsNeedLoad = ValueTypeint,
        FurnitureType = ValueTypeint,
        PrefabName = ValueTypestring,
        DontAutoCreateCollider = ValueTypeint,
        Model = ValueTypestring,
        InteractPos = ValueTypeint,
        AnimationType = ValueTypeint,
        AnimationArg = ValueTypestring,
        AnimationName = Type1ValueTypestring,
        SpecialUiNames = Type1ValueTypestring,
        UiNameProxyPaths = Type1ValueTypestring,
        SpecialUiNameHeightOffset = Type1ValueTypefloat,
        UiShowDistance = ValueTypefloat,
        EnvironmentSound = ValueTypeint,
        RedPointCondition = ValueTypestring,
        ShowButtonGroupId = ValueTypeint,
        EffectGroupId = ValueTypeint,
    },
    XTableGuildDormFurnitureEffect = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Note = ValueTypestring,
        ConditionType = ValueTypeint,
        ConditionArg = ValueTypestring,
        ConditionState = ValueTypeint,
        IsSpecialPos = ValueTypeint,
        SpecialPosName = ValueTypestring,
        EffectId = ValueTypeint,
        EffectX = ValueTypefloat,
        EffectY = ValueTypefloat,
        EffectZ = ValueTypefloat,
    },
    XTableGuildDormFurnitureInteractBtn = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Note = ValueTypestring,
        ConditionType = ValueTypeint,
        ConditionArg = ValueTypestring,
        ConditionState = ValueTypeint,
        ShowButtonName = ValueTypestring,
        ButtonType = ValueTypeint,
        ButtonArg = ValueTypestring,
        InteractPoint = ValueTypeint,
        BehaviorType = ValueTypestring,
    },
    XTableGuildDormFurnitureInteraction = {
        Id = ValueTypeintPrimaryKey,
        NeedMark = ValueTypebool,
        ShowButtonNames = Type1ValueTypestring,
        InteractionText = ValueTypestring,
        ReplyTexts = Type1ValueTypestring,
        ReplyRewardIds = Type1ValueTypeint,
        CameraDistance = ValueTypefloat,
        CameraAngleYOffset = ValueTypefloat,
        CameraAngleXOffset = ValueTypefloat,
        FocusGameObjectPath = ValueTypestring,
    },
    XTableGuildDormFurnitureRandomBox = {
        Id = ValueTypeintPrimaryKey,
        RandomTimes = ValueTypeint,
        FocusPointPath = ValueTypestring,
        CameraDistance = ValueTypefloat,
        AgreeReply = ValueTypestring,
        RefreshReply = ValueTypestring,
        StopRefreshReply = ValueTypestring,
        CloseReply = ValueTypestring,
        StopRefreshText = ValueTypestring,
        InteractionTexts = Type1ValueTypestring,
    },
    XTableGuildDormFurnitureRandomBoxItem = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        FurnitureId = ValueTypeint,
    },
    XTableGuildDormInstrumentVolumeControl = {
        GuildDormRoomId = ValueTypeintPrimaryKey,
        FirstMuteBgm = ValueTypeint,
        FirstMuteInstrument = ValueTypeint,
    },
    XTableGuildDormNpc = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableGuildDormNpcActionGroup = {
        Id = ValueTypeintPrimaryKey,
        ActionTypes = Type1ValueTypeint,
        ActionIds = Type1ValueTypeint,
    },
    XTableGuildDormNpcActionIdle = {
        Id = ValueTypeintPrimaryKey,
        Duration = ValueTypeint,
        IdleAnimId = ValueTypestring,
    },
    XTableGuildDormNpcActionMove = {
        Id = ValueTypeintPrimaryKey,
        LerpSpace = ValueTypefloat,
        PositionStrs = Type1ValueTypestring,
    },
    XTableGuildDormNpcRefresh = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        ThemeId = ValueTypeint,
        InitPos = ValueTypestring,
        RefreshTimeId = ValueTypeint,
        ActionGroupId = ValueTypeint,
        InteractName = ValueTypestring,
        IdleBehaviorId = ValueTypestring,
        TalkBehaviorId = ValueTypestring,
        PatrolBehaviorId = ValueTypestring,
        AnimControllerPath = ValueTypestring,
        ColliderRadius = ValueTypefloat,
        InteractCdTime = ValueTypeint,
        InteractMaxTime = ValueTypeint,
    },
    XTableGuildDormNpcRefreshControl = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        TimeId = ValueTypeint,
        Priority = ValueTypeint,
        RefreshType = ValueTypeint,
        RefreshInterval = ValueTypeint,
        NpcGroupIds = Type1ValueTypeint,
        NpcGroupWeights = Type1ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableGuildDormNpcRefreshGroup = {
        Id = ValueTypeintPrimaryKey,
        NpcRefreshIds = Type1ValueTypeint,
    },
    XTableGuildDormNpcTalk = {
        Id = ValueTypeintPrimaryKey,
        Content = ValueTypestring,
        BehaviorId = ValueTypestring,
        OptionShowTime = ValueTypeint,
        EmptySkipId = ValueTypeint,
        RepeatId = ValueTypeint,
        Options = Type1ValueTypestring,
        SkipIds = Type1ValueTypeint,
    },
    XTableGuildDormPaint = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        DefaultPaints = Type1ValueTypestring,
        SpeicalPaints = Type1ValueTypestring,
    },
    XTableGuildDormPlayAction = {
        Id = ValueTypeintPrimaryKey,
        ActionName = ValueTypestring,
        ActionUiName = ValueTypestring,
        Duration = ValueTypefloat,
        CoolDown = ValueTypefloat,
        Icon = ValueTypestring,
        CrossDuration = ValueTypefloat,
        IsFollowCamera = ValueTypebool,
    },
    XTableGuildDormRole = {
        Id = ValueTypeintPrimaryKey,
        CCHeight = ValueTypefloat,
        CCRadius = ValueTypefloat,
        CCCenterX = ValueTypefloat,
        CCCenterY = ValueTypefloat,
        CCCenterZ = ValueTypefloat,
        SkinWidth = ValueTypefloat,
        NameHeightOffset = ValueTypefloat,
        TalkHeightOffset = ValueTypefloat,
        IdleAnim = ValueTypestring,
        WalkAnim = ValueTypestring,
    },
    XTableGuildDormRoleBehavior = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        State = ValueTypestring,
        BehaviorId = ValueTypestring,
    },
    XTableGuildDormRoom = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        EntryX = ValueTypefloat,
        EntryY = ValueTypefloat,
        EntryAngle = ValueTypefloat,
        PrefabName = ValueTypestring,
        SceneName = ValueTypestring,
        Index = ValueTypeint,
        ChannelCount = ValueTypeint,
        ChannelMemberCount = ValueTypeint,
    },
    XTableGuildDormRoomTheme = {
        Id = ValueTypeintPrimaryKey,
        RoomId = ValueTypeint,
        Name = ValueTypestring,
        EntryX = ValueTypefloat,
        EntryZ = ValueTypefloat,
        EntryY = ValueTypefloat,
        EntryAngle = ValueTypefloat,
        PrefabName = ValueTypestring,
        SceneName = ValueTypestring,
        ScenePath = ValueTypestring,
        Index = ValueTypeint,
        TimeId = ValueTypeint,
        NpcRefreshControlGroupId = ValueTypeint,
        BgmListId = ValueTypeint,
        StepCueId = ValueTypeint,
        NeedBuy = ValueTypeint,
        Image = ValueTypestring,
        BigImage = ValueTypestring,
        ShopSkipId = ValueTypeint,
        UiName = ValueTypestring,
        Labels = Type1ValueTypestring,
        PreviewImageList = Type1ValueTypestring,
    },
    XTableGuildDormRoomThemeLabel = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Content = ValueTypestring,
        BgColor = ValueTypestring,
    },
    XTableGuildGift = {
        Id = ValueTypeintPrimaryKey,
        GuildLevel = ValueTypeint,
        GiftLevel = ValueTypeint,
        GiftReward = ValueTypeint,
        NewGiftReward = ValueTypeint,
        TimeId = ValueTypeint,
        GiftIcon = ValueTypestring,
        GiftContribute = ValueTypeint,
    },
    XTableGuildGoods = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        TargetId = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableGuildHeadPortrait = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Describe = ValueTypestring,
        Icon = ValueTypestring,
        ConditionId = ValueTypeint,
        Cost = ValueTypeint,
        IsSpecial = ValueTypebool,
        SearchGuildBgIcon = ValueTypestring,
        GuildMessageBgIcon = ValueTypestring,
        GuildRankBgIcon = ValueTypestring,
        NewGuildRoomBg = ValueTypestring,
        OldGuildRoomBg = ValueTypestring,
        GuildHeadPortraitBg = ValueTypestring,
        CreateGuildBg = ValueTypestring,
    },
    XTableGuildLevel = {
        Level = ValueTypeintPrimaryKey,
        Capacity = ValueTypeint,
        PositionNum = Type1ValueTypeint,
        Build = ValueTypeint,
        Contribution = ValueTypeint,
        EmergencyMaintenance = ValueTypeint,
        EmergencyDay = ValueTypeint,
        WishMaxCount = ValueTypeint,
        WishItemCount = ValueTypeint,
        WishContributeMaxCount = ValueTypeint,
        TalentPoint = ValueTypeint,
    },
    XTableGuildNews = {
        Id = ValueTypeintPrimaryKey,
        Content = ValueTypestring,
        ShowChat = ValueTypeint,
        Group = ValueTypeint,
    },
    XTableGuildPosition = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        Authority = Type1ValueTypeint,
    },
    XTableGuildPresent = {
        Id = ValueTypeintPrimaryKey,
        PresentId = ValueTypeint,
        Popularity = ValueTypeint,
        GuildCoin = ValueTypeint,
    },
    XTableGuildSign = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Weight = ValueTypeint,
        SignType = Type1ValueTypeint,
        SignNum = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
        RewardWeight = Type1ValueTypeint,
        ImageMap = Type2KeyTypestringValueTypestring,
    },
    XTableGuildSignEvent = {
        Id = ValueTypeintPrimaryKey,
        SignType = ValueTypeint,
        Pos = ValueTypeint,
        SignContent = ValueTypestring,
    },
    XTableGuildSignSpecialDateSign = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Date = ValueTypestring,
        SignId = ValueTypeint,
    },
    XTableGuildTalent = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        GuildLevel = ValueTypeint,
        CostPoint = Type1ValueTypeint,
        Parent = Type1ValueTypeint,
        BuffId = ValueTypeint,
    },
    XTableGuildTalentDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IndexInMap = ValueTypeint,
        TalentIcon = ValueTypestring,
        PrefabPath = ValueTypestring,
        Descriptions = Type1ValueTypestring,
    },
    XTableGuildTaskGroup = {
        GroupId = ValueTypeintPrimaryKey,
        TaskType = ValueTypeint,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        TaskDataKey = ValueTypestring,
        SkipId = ValueTypeint,
    },
    XTableGuildWarActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        CurrencyId = ValueTypeint,
        FightNodeType = ValueTypeint,
    },
    XTableGuildWarBossReward = {
        Id = ValueTypeintPrimaryKey,
        Difficulty = ValueTypeint,
        RewardId = ValueTypeint,
        LimitLevel = ValueTypeint,
    },
    XTableGuildWarBuff = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        HpPercent = ValueTypeint,
        KillMonsterCount = ValueTypeint,
        DelayMonsterBornInterval = ValueTypeint,
        FightEventId = ValueTypeint,
    },
    XTableGuildWarClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableGuildWarConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Value = ValueTypestring,
    },
    XTableGuildWarDifficulty = {
        Id = ValueTypeintPrimaryKey,
        PreId = ValueTypeint,
        Name = ValueTypestring,
        RecommendActive = ValueTypeint,
        BgPath = ValueTypestring,
        MapPath = ValueTypestring,
        LockText = ValueTypestring,
        FightEventIds = Type1ValueTypeint,
        PassRewardId = ValueTypeint,
        UnPassRewardId = ValueTypeint,
        SweepHpFactor = ValueTypefloat,
        SweepPointFactor = ValueTypefloat,
        BossSweepHpFactor = ValueTypefloat,
        BossSweepPointFactor = ValueTypefloat,
        RobotId = Type1ValueTypeint,
    },
    XTableGuildWarDragonRage = {
        Id = ValueTypeintPrimaryKey,
        PlayThrough = ValueTypeint,
        DifficultyId = ValueTypeint,
        UpLimit = ValueTypeint,
        PassAdd = ValueTypeint,
        ReduceIntervalMinute = ValueTypeint,
        IntervalReduce = ValueTypeint,
        PassReduce = ValueTypeint,
    },
    XTableGuildWarDragonRageNodeChange = {
        Id = ValueTypeintPrimaryKey,
        PlayThrough = ValueTypeint,
        DifficultyId = ValueTypeint,
        ChangeNodeIds = Type1ValueTypeint,
    },
    XTableGuildWarEliteMonster = {
        Id = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        GuildWarStageId = ValueTypeint,
        PatrolId = ValueTypeint,
        HpMax = ValueTypeint,
        DamagePercent = ValueTypeint,
        BaseSubHp = ValueTypeint,
        MaxSubHp = ValueTypeint,
        MaxPoint = ValueTypeint,
        MinSubDamage = ValueTypeint,
        FactorA = ValueTypefloat,
        FactorB = ValueTypefloat,
        FactorC = ValueTypefloat,
        FactorD = ValueTypefloat,
        FightCostEnergy = ValueTypeint,
        SweepCostEnergy = ValueTypeint,
    },
    XTableGuildWarMonsterPatrol = {
        Id = ValueTypeintPrimaryKey,
        Routes = Type1ValueTypeint,
        Notifys = Type1ValueTypeint,
    },
    XTableGuildWarNode = {
        Id = ValueTypeintPrimaryKey,
        GroupIndex = ValueTypeint,
        StageIndex = ValueTypeint,
        DifficultyId = ValueTypeint,
        Name = ValueTypestring,
        NameEn = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        BgIcon = ValueTypestring,
        ShowMonsterIcon = ValueTypestring,
        ShowMonsterName = ValueTypestring,
        ShowFightEventId = Type1ValueTypeint,
        FightEventId = Type1ValueTypeint,
        Type = ValueTypeint,
        RootId = ValueTypeint,
        RootGuardId = ValueTypeint,
        SubMonsterBornCd = ValueTypeint,
        TreatMstInterval = ValueTypeint,
        TreatMstPercent = ValueTypeint,
        WeaknessFightEventId = ValueTypeint,
        AttackBaseDamage = ValueTypeint,
        AttackBaseInterval = ValueTypeint,
        LinkIds = Type1ValueTypeint,
        HpMax = ValueTypeint,
        RewardId = ValueTypeint,
        GuildWarStageId = ValueTypeint,
        EliteMonsterId = ValueTypeint,
        EliteMonsterBornInterval = ValueTypeint,
        BuffGroupId = ValueTypeint,
        RebuildTime = ValueTypeint,
        RebuildTimeFactor = ValueTypeint,
        RebuildMaxTime = ValueTypeint,
        RebuildGuildWarStageId = ValueTypeint,
        ResidueStageId = ValueTypeint,
        BaseSubHp = ValueTypeint,
        MaxSubHp = ValueTypeint,
        MaxPoint = ValueTypeint,
        BasePoint = ValueTypeint,
        MinSubDamage = ValueTypeint,
        FactorA = ValueTypefloat,
        FactorB = ValueTypefloat,
        FactorC = ValueTypefloat,
        FactorD = ValueTypefloat,
        FightCostEnergy = ValueTypeint,
        SweepCostEnergy = ValueTypeint,
        HelpTitle = ValueTypestring,
        HelpDetail = ValueTypestring,
        DescWeakness = ValueTypestring,
        ModelId = ValueTypestring,
        DeployCharacterMax = ValueTypeint,
        DeployCharacterNum = Type1ValueTypeint,
        DeployBuff = Type1ValueTypeint,
    },
    XTableGuildWarPlayThrough = {
        Id = ValueTypeintPrimaryKey,
        PlayThrough = ValueTypeint,
        DifficultyId = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        AddNodeHpPercent = ValueTypeint,
        AddPointPercent = ValueTypeint,
        ShowBuffId = ValueTypeint,
        ShowBuffDescFormat = ValueTypestring,
        ChangeNodeIds = Type1ValueTypeint,
    },
    XTableGuildWarRankingType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TabType = ValueTypestring,
        FatherTab = ValueTypeint,
        RankingTarget = ValueTypeint,
        Params = Type1ValueTypeint,
        RoundId = ValueTypeint,
    },
    XTableGuildWarReinforcements = {
        Id = ValueTypeintPrimaryKey,
        DifficultyId = ValueTypeint,
        Name = ValueTypestring,
        HpMax = ValueTypeint,
        AttackIntervalSecond = ValueTypeint,
        SupportCost = ValueTypeint,
        BornNodeId = ValueTypeint,
        MoveNextNodeIds = Type1ValueTypeint,
        ShowFightEventIds = Type1ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableGuildWarRound = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        TimeId = ValueTypeint,
    },
    XTableGuildWarSpecialRole = {
        Id = ValueTypeintPrimaryKey,
        CenterCharacter = ValueTypeint,
        FightEventId = ValueTypeint,
    },
    XTableGuildWarSpecialRoleTeam = {
        Id = ValueTypeintPrimaryKey,
        CharacterIds = Type1ValueTypeint,
        FightEventId = Type1ValueTypeint,
        EnableNum = Type1ValueTypeint,
        BuffName = ValueTypestring,
        BuffSimpleDesc = ValueTypestring,
        BuffDesc = ValueTypestring,
        BuffIcon = ValueTypestring,
    },
    XTableGuildWarStage = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        MonsterLibraryId = ValueTypeint,
        Ability = ValueTypeint,
    },
    XTableGuildWarStageMonster = {
        Id = ValueTypeintPrimaryKey,
        MonsterId = ValueTypeint,
        Num = ValueTypeint,
        Level = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableGuildWarStageMonsterLibrary = {
        Id = ValueTypeintPrimaryKey,
        LibraryId = ValueTypeint,
        MonsterIds = Type1ValueTypeint,
    },
    XTableGuildWarTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        SubType = ValueTypeint,
        RoundId = ValueTypeint,
        Icon = ValueTypestring,
        DifficultyId = ValueTypeint,
        Desc = ValueTypestring,
        TaskId = ValueTypeint,
        Percent = ValueTypeint,
        RewardId = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableGuildWarTaskType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableGuildWelcome = {
        Id = ValueTypeintPrimaryKey,
        WelcomeWord = ValueTypestring,
        Select = ValueTypebool,
    },
    XTableGuildWelfare = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SkipId = ValueTypeint,
        WelfareBg = ValueTypestring,
        Condition = ValueTypeint,
    },
    XTableHackActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        TicketId = ValueTypeint,
        ExpId = ValueTypeint,
        TicketDays = ValueTypeint,
        DailyTicketCount = ValueTypeint,
        ChapterId = Type1ValueTypeint,
        Name = ValueTypestring,
        BannerBg = ValueTypestring,
        GridPrefab = Type1ValueTypestring,
    },
    XTableHackBuff = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        FightEvent = ValueTypeint,
        Icon = ValueTypestring,
        Description = ValueTypestring,
        AbilityBonus = ValueTypeint,
    },
    XTableHackChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        SelectBuffCount = ValueTypeint,
        UnGetRewardMailId = ValueTypeint,
        StageId = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
        RobotId = Type1ValueTypeint,
    },
    XTableHackCharacterEffect = {
        Id = ValueTypeintPrimaryKey,
        BuffId = ValueTypeint,
    },
    XTableHackExpLevel = {
        Id = ValueTypeintPrimaryKey,
        Level = ValueTypeint,
        ChapterId = ValueTypeint,
        UpExp = ValueTypeint,
        BuffId = ValueTypeint,
        UnlockBuffPos = ValueTypeint,
    },
    XTableHackReward = {
        Id = ValueTypeintPrimaryKey,
        NeedStars = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableHackStage = {
        Id = ValueTypeintPrimaryKey,
        ConsumeTicket = ValueTypeint,
        GridName = ValueTypestring,
        ConditionDesc = ValueTypestring,
        FeatureTitle = Type1ValueTypestring,
        FeatureDesc = Type1ValueTypestring,
    },
    XTableHeadPortrait = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        IsInit = ValueTypeint,
        Name = ValueTypestring,
        ImgSrc = ValueTypestring,
        LockDesc = ValueTypestring,
        ConvertItemId = ValueTypeint,
        ConvertItemCount = ValueTypeint,
        Description = ValueTypestring,
        WorldDesc = ValueTypestring,
        Effect = ValueTypestring,
        Priority = ValueTypeint,
        LimitType = ValueTypeint,
        TimeId = ValueTypeint,
        ShowTimeStr = ValueTypestring,
        Duration = ValueTypeint,
        IsRepetition = ValueTypeint,
        GroupId = ValueTypeint,
        Quality = ValueTypeint,
        Expire = ValueTypebool,
    },
    XTableHeadPortraitHide = {
        Id = ValueTypeint,
        BeginTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
    },
    XTableHelpCourse = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Function = ValueTypestring,
        Describe = ValueTypestring,
        IsShowCourse = ValueTypeint,
        ImageAsset = Type1ValueTypestring,
        TextGroupIds = Type1ValueTypeint,
        SubIds = Type1ValueTypeint,
    },
    XTableHelpCourseFunctionMap = {
        Function = ValueTypestringPrimaryKey,
        Id = ValueTypeint,
    },
    XTableHelpCourseTextGroup = {
        Id = ValueTypeintPrimaryKey,
        Texts = Type1ValueTypestring,
    },
    XTableHHMapConfigInfo = {
        Id = ValueTypeintPrimaryKey,
        Index = ValueTypeint,
        WorldRectX = ValueTypefloat,
        WorldRectY = ValueTypefloat,
        WorldRectWidth = ValueTypefloat,
        WorldRectHeight = ValueTypefloat,
        CenterX = ValueTypefloat,
        CenterZ = ValueTypefloat,
        CellSize = ValueTypeint,
        ShowRange = ValueTypefloat,
        ShowAndHideRange = ValueTypefloat,
        HideRange = ValueTypefloat,
        LoadRange = ValueTypefloat,
        LoadAndUnloadRange = ValueTypefloat,
    },
    XTableHierarchicalHashCellInfo = {
        Id = ValueTypestringPrimaryKey,
        Name = ValueTypestring,
        Path = ValueTypestring,
        EntityId = ValueTypeint,
    },
    XTableHierarchicalHashMapInfo = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        CellSize = ValueTypeint,
        CenterX = ValueTypefloat,
        CenterY = ValueTypefloat,
        WorldBoxMinX = ValueTypefloat,
        WorldBoxMinY = ValueTypefloat,
        WorldBoxMaxX = ValueTypefloat,
        WorldBoxMaxY = ValueTypefloat,
        ShowRange = ValueTypefloat,
        ShowOrHideRange = ValueTypefloat,
        HideRange = ValueTypefloat,
        LoadRange = ValueTypefloat,
        LoadOrUnloadRange = ValueTypefloat,
    },
    XTableHitMouseActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        UseItem = ValueTypeint,
        RewardScores = Type1ValueTypeint,
        RewardIds = Type1ValueTypeint,
    },
    XTableHitMouseGame = {
        Id = ValueTypeintPrimaryKey,
        MoleNum = ValueTypeint,
        ComboTextNum = Type1ValueTypeint,
        ComboTextSize = Type1ValueTypeint,
        RuleTitle = ValueTypestring,
        RuleText = ValueTypestring,
        StartFx = ValueTypestring,
    },
    XTableHitMouseMole = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Name = ValueTypestring,
        Type = ValueTypeint,
        CanBeHit = ValueTypeint,
        ScoreAffix = ValueTypefloat,
        ShowTimeAffix = ValueTypefloat,
        ReduceTime = ValueTypefloat,
        Prefab = ValueTypestring,
        Effect = ValueTypestring,
    },
    XTableHitMouseRefresh = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        HitCount = ValueTypeint,
        MaxShowTime = ValueTypefloat,
        RestTime = ValueTypefloat,
        Type1NumberMin = ValueTypeint,
        Type1NumberMax = ValueTypeint,
        Type2NumberMin = ValueTypeint,
        Type2NumberMax = ValueTypeint,
        HitScoreRate = ValueTypefloat,
    },
    XTableHitMouseStage = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        BgImgUrl = ValueTypestring,
        PreStageId = ValueTypeint,
        UnlockItemCount = ValueTypeint,
        StageName = ValueTypestring,
        Time = ValueTypeint,
        BreakTime = ValueTypefloat,
        TurnTime = ValueTypefloat,
        HaveFever = ValueTypeint,
        FeverRefresh = ValueTypeint,
        FeverTime = ValueTypefloat,
        MouseRefresh = ValueTypestring,
        MouseWeights = Type1ValueTypeint,
        RefreshMaxIntervals = Type1ValueTypeint,
    },
    XTableHoldRegressionActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ContinueDays = ValueTypeint,
        NeedLevel = ValueTypeint,
        MaxInviteNum = ValueTypeint,
        InviteTimeId = ValueTypeint,
        BgIcon = ValueTypestring,
        Text = Type1ValueTypestring,
        RegressionRewardId = ValueTypeint,
        InviteRewardId = ValueTypeint,
        OpenChatChannel = ValueTypebool,
        ChatChannelId = ValueTypeint,
        TaskGroupId = ValueTypeint,
        MultiRewardCount = ValueTypeint,
    },
    XTableHoldRegressionClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableHoldRegressionCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableHoldRegressionInvite = {
        Id = ValueTypeintPrimaryKey,
        Slogan = ValueTypestring,
        InvitationCode = ValueTypebool,
        InvitationQRCode = ValueTypebool,
        QRCodeIcon = ValueTypestring,
        InvitationBg = Type1ValueTypestring,
    },
    XTableHoldRegressionShareConfig = {
        Key = ValueTypestringPrimaryKey,
        PlatformName = ValueTypestring,
        IconPath = ValueTypestring,
        Text = ValueTypestring,
    },
    XTableHoldRegressionTask = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        TimeId = ValueTypeint,
        Type = ValueTypeint,
        ConditionId = ValueTypeint,
        RewardId = ValueTypeint,
        NeedSchedule = ValueTypeint,
        TaskTimesLimit = ValueTypeint,
        Priority = ValueTypeint,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableHonorLevel = {
        HonorLevel = ValueTypeintPrimaryKey,
        MaxExp = ValueTypeint,
        MaxActionPoint = ValueTypeint,
        RewardId = ValueTypeint,
        MaxFriendCount = ValueTypeint,
    },
    XTableHookRope = {
        Id = ValueTypeintPrimaryKey,
        AreaType = ValueTypeint,
        Radius = ValueTypefix,
        Length = ValueTypefix,
        Width = ValueTypefix,
        PosX = ValueTypefix,
        PosY = ValueTypefix,
        PosZ = ValueTypefix,
        face = ValueTypefix,
        TargetIds = Type1ValueTypeint,
    },
    XTableHostelDelegate = {
        Id = ValueTypeint,
        SlotType = ValueTypeint,
        DelegateType = ValueTypeint,
        DelegateName = ValueTypestring,
        DelegateDes = ValueTypestring,
        ReportDes = ValueTypestring,
        PublishAwardPercent = ValueTypeint,
        AssistAwardPercent = ValueTypeint,
        HuixinAward = ValueTypeint,
        SHuixinAward = ValueTypeint,
        DelegateCount = ValueTypeint,
        NormalReport = ValueTypestring,
        HuixinReport = ValueTypestring,
        SHuixinReport = ValueTypestring,
    },
    XTableHostelDeviceNode = {
        Id = ValueTypeintPrimaryKey,
        RoomType = ValueTypeint,
        Scene = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Path = ValueTypestring,
        OpenUI = ValueTypestring,
    },
    XTableHostelHud = {
        Id = ValueTypeintPrimaryKey,
        HudType = ValueTypeint,
        DeviceType = ValueTypeint,
        HudX = ValueTypefloat,
        HudY = ValueTypefloat,
        HudHeight = ValueTypefloat,
        HudWidth = ValueTypefloat,
        HudScale = ValueTypefloat,
    },
    XTableHostelRest = {
        Floor = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        AreaName = ValueTypestring,
        Comfortable = ValueTypeint,
        RestCD = ValueTypeint,
        RecoveryValue = ValueTypeint,
        RestCharCount = ValueTypeint,
    },
    XTableHostelRoom = {
        Id = ValueTypeintPrimaryKey,
        Floor = ValueTypeint,
        Name = ValueTypestring,
        CostId = ValueTypeint,
        CostCount = ValueTypeint,
        ConditionId = Type1ValueTypeint,
    },
    XTableHostelRoomNode = {
        Id = ValueTypeintPrimaryKey,
        Scene = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Path = ValueTypestring,
    },
    XTableHXResReplace = {
        Res = ValueTypestringPrimaryKey,
        ResHX = ValueTypestring,
    },
    XTableInfestorActivity = {
        Id = ValueTypeintPrimaryKey,
        ExploreChapterId = Type1ValueTypeint,
        BossStageId = Type1ValueTypeint,
    },
    XTableInfestorBossScoreRule = {
        StageId = ValueTypeintPrimaryKey,
        TotalMaxScore = ValueTypeint,
        DamageFactor = ValueTypefloat,
        DamageMaxScore = ValueTypeint,
        HpFactor = ValueTypefloat,
        HpMaxScore = ValueTypeint,
        UseTimeFactor = ValueTypefloat,
        UseTimeMaxScore = ValueTypeint,
    },
    XTableInfestorBuffsRes = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableInfestorEventGoods = {
        EventId = ValueTypeintPrimaryKey,
        Cost = ValueTypeint,
    },
    XTableInfestorEventPoolRes = {
        PoolId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        BtnName = ValueTypestring,
        EventId1 = Type1ValueTypeint,
        EventId2 = Type1ValueTypeint,
        EventId3 = Type1ValueTypeint,
    },
    XTableInfestorEventType = {
        Type = ValueTypeintPrimaryKey,
        Description = ValueTypestring,
        DescriptionRevert = ValueTypestring,
        DescriptionEmpty = ValueTypestring,
    },
    XTableInfestorExploreBuff = {
        Id = ValueTypeint,
        PoolId = ValueTypeint,
        Weight = ValueTypeint,
        BuffId = ValueTypeint,
    },
    XTableInfestorExploreChapter = {
        Id = ValueTypeintPrimaryKey,
        PreChapterId = ValueTypeint,
        MapId = ValueTypeint,
        ShopId = ValueTypeint,
        TeamType = ValueTypeint,
        CharacterLimitType = ValueTypeint,
        LimitBuffId = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Bg = ValueTypestring,
        Icon = ValueTypestring,
        Prefab = ValueTypestring,
    },
    XTableInfestorExploreCore = {
        Id = ValueTypeintPrimaryKey,
        Quality = ValueTypeint,
        MaxLevel = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableInfestorExploreCoreLevelEffect = {
        Id = ValueTypeintPrimaryKey,
        CoreId = ValueTypeint,
        CoreLevel = ValueTypeint,
        DecomposeMoney = ValueTypeint,
        Description = ValueTypestring,
        BuffId = Type1ValueTypeint,
    },
    XTableInfestorExploreDiff = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Diff = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        JoinNum = ValueTypeint,
        UpNum = ValueTypeint,
        DownNum = ValueTypeint,
        UpMailId = ValueTypeint,
        KeepMailId = ValueTypeint,
        DownMailId = ValueTypeint,
        ShowScoreGap = ValueTypeint,
        ShowScoreLimit = ValueTypeint,
    },
    XTableInfestorExploreEvent = {
        Id = ValueTypeintPrimaryKey,
        PoolId = ValueTypeint,
        Weight = ValueTypeint,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        Description = ValueTypestring,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableInfestorExploreFog = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Depth = ValueTypeint,
    },
    XTableInfestorExploreGrid = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        FrontId = Type1ValueTypeint,
    },
    XTableInfestorExploreLevelGroup = {
        Id = ValueTypeint,
        MinLevel = ValueTypeint,
        MaxLevel = ValueTypeint,
    },
    XTableInfestorExploreNode = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        Type = ValueTypeint,
        ResType = ValueTypeint,
        RecHpPer = ValueTypeint,
        FightStageId = ValueTypeint,
        ShowRewardId = ValueTypeint,
        RewardPoolId = ValueTypeint,
        RewardCount = ValueTypeint,
        EventPoolId = ValueTypeint,
        SubHpProbability = ValueTypeint,
        SubHpMinPer = ValueTypeint,
        SubHpMaxPer = ValueTypeint,
        RewardMoneyCount = ValueTypeint,
        UseActionPoint = ValueTypeint,
    },
    XTableInfestorExploreReward = {
        Id = ValueTypeintPrimaryKey,
        PoolId = ValueTypeint,
        CoreId = ValueTypeint,
        CoreLevel = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableInfestorExploreSection = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableInfestorExploreShop = {
        Id = ValueTypeintPrimaryKey,
        GoodsCount = ValueTypeint,
        RefreshCost = ValueTypeint,
    },
    XTableInfestorExploreShopGoods = {
        Id = ValueTypeintPrimaryKey,
        ShopId = ValueTypeint,
        Weight = ValueTypeint,
        CoreId = ValueTypeint,
        CoreLevel = ValueTypeint,
        Cost = ValueTypeint,
        LimitCount = ValueTypeint,
    },
    XTableInfestorFightEvent = {
        Id = ValueTypeintPrimaryKey,
        ExploreFightEventId = Type1ValueTypeint,
        BossFightEventId = Type1ValueTypeint,
    },
    XTableInfestorFightRewardCost = {
        Times = ValueTypeintPrimaryKey,
        Cost = ValueTypeint,
    },
    XTableInfestorGroup = {
        Id = ValueTypeintPrimaryKey,
        MinLevel = ValueTypeint,
        MaxLevel = ValueTypeint,
    },
    XTableInfestorNodeType = {
        Type = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        StageBg = ValueTypestring,
    },
    XTableInfestorOutPostDes = {
        Id = ValueTypeintPrimaryKey,
        Key = ValueTypestring,
        PoolId = Type1ValueTypeint,
    },
    XTableInfestorOutPostDesPool = {
        Id = ValueTypeintPrimaryKey,
        PoolId = ValueTypeint,
        Description = ValueTypestring,
    },
    XTableInfestorStageDiffControl = {
        Id = ValueTypeint,
        StageId = ValueTypeint,
        GroupId = ValueTypeint,
        Diff = ValueTypeint,
        MonsterLevel = Type1ValueTypeint,
    },
    XTableInfestorStatus = {
        Day = Type1ValueTypeint,
    },
    XTableInfestorSupplyRewardRes = {
        Id = ValueTypeintPrimaryKey,
        Description = ValueTypestring,
    },
    XTableInputMap = {
        InputMapId = ValueTypeintPrimaryKey,
        Str = ValueTypestring,
        TimeId = ValueTypeint,
        Version = ValueTypeint,
        StageType = Type1ValueTypeint,
    },
    XTableInstrumentKeyMap = {
        FId = ValueTypeintPrimaryKey,
        KeyCode = ValueTypeint,
        CueId = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableInvertCard = {
        Id = ValueTypeintPrimaryKey,
        BaseIcon = ValueTypestring,
    },
    XTableInvertCardGame = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ItemId = ValueTypeint,
        HelpId = ValueTypeint,
        StorySkipId = ValueTypeint,
        ActivityStageIds = Type1ValueTypeint,
    },
    XTableInvertCardStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        RowCount = ValueTypeint,
        ColumnCount = ValueTypeint,
        ContainCards = Type1ValueTypeint,
        CostCoinNum = ValueTypeint,
        MaxCostNum = ValueTypeint,
        TargetNum = ValueTypeint,
        FinishGroups = Type1ValueTypestring,
        FinishProgress = Type1ValueTypeint,
        Rewards = Type1ValueTypeint,
        MaxOnCardsNum = ValueTypeint,
        FailedPunishNum = ValueTypeint,
        ClearConditionDesc = ValueTypestring,
    },
    XTableIosHardware = {
        PhoneName = ValueTypestringPrimaryKey,
        Quality = ValueTypeint,
    },
    XTableItem = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        WorldDesc = ValueTypestring,
        BigIcon = ValueTypestring,
        Icon = ValueTypestring,
        ItemType = ValueTypeint,
        Quality = ValueTypeint,
        Priority = ValueTypeint,
        MaxCount = ValueTypeint,
        GridCount = ValueTypeint,
        TimelinessType = ValueTypeint,
        StartTime = ValueTypestring,
        Duration = ValueTypeint,
        RecycleRewardId = ValueTypeint,
        RecycleByMail = ValueTypebool,
        SellForId = ValueTypeint,
        SellForCount = ValueTypeint,
        RecType = ValueTypeint,
        RecTime = ValueTypestring,
        RecCount = ValueTypeint,
        SuitId = ValueTypeint,
        FastTrading = ValueTypeint,
        SkipIdParams = Type1ValueTypeint,
        SubTypeParams = Type1ValueTypeint,
    },
    XTableItemCollection = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        WorldDesc = ValueTypestring,
        BigIcon = ValueTypestring,
        Icon = ValueTypestring,
        Quality = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableItemExchange = {
        Id = ValueTypeintPrimaryKey,
        ItemId = ValueTypeint,
        MinCount = ValueTypeint,
        UseItemId = ValueTypeint,
        UseItemCount = ValueTypeint,
    },
    XTableItemInitData = {
        Id = ValueTypeint,
        Count = ValueTypeint,
    },
    XTableItemUsePackage = {
        Id = ValueTypeintPrimaryKey,
        PackageIds = Type1ValueTypeint,
        SubItems = Type1ValueTypeint,
    },
    XTableKillZoneActivity = {
        Id = ValueTypeintPrimaryKey,
        OpenTimeId = ValueTypeint,
        ActivityBg = ValueTypestring,
        Name = ValueTypestring,
        ResetPluginSpend = ValueTypeint,
        TakeFarmRewardMaxCount = ValueTypeint,
        ChapterId = Type1ValueTypeint,
    },
    XTableKillZoneBuff = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableKillZoneChapter = {
        Id = ValueTypeintPrimaryKey,
        Diff = ValueTypeint,
        PreStageId = ValueTypeint,
        Name = ValueTypestring,
        OpenTimeId = ValueTypeint,
        Bg = ValueTypestring,
        StageId = Type1ValueTypeint,
        DailyStageId = ValueTypeint,
    },
    XTableKillZoneDailyStarReward = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Star = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableKillZoneMonster = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Level = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        BuffLevels = Type1ValueTypeint,
        MaxLife = ValueTypeint,
        Note = ValueTypestring,
    },
    XTableKillZoneMonsterGroup = {
        Id = ValueTypeintPrimaryKey,
        MonsterIds = Type1ValueTypeint,
    },
    XTableKillZonePlugin = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        LevelId = Type1ValueTypeint,
        UnlockSpend = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableKillZonePluginGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableKillZonePluginLevel = {
        Id = ValueTypeintPrimaryKey,
        FightEventId = ValueTypeint,
        UnlockSpend = ValueTypeint,
        SkillDesc = ValueTypestring,
    },
    XTableKillZonePluginSlot = {
        Id = ValueTypeintPrimaryKey,
        UnlockCondition = ValueTypeint,
    },
    XTableKillZoneStage = {
        Id = ValueTypeintPrimaryKey,
        PreStageId = ValueTypeint,
        Name = ValueTypestring,
        Order = ValueTypestring,
        Bg = ValueTypestring,
        WinCondition = Type1ValueTypeint,
        StarCondition = Type1ValueTypeint,
        TestRobot = Type1ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        StarDesc = Type1ValueTypestring,
        FarmReward = ValueTypeint,
        MaxStar = ValueTypeint,
        RandomFightEventIds = Type1ValueTypeint,
        MonsterGroups = Type1ValueTypeint,
    },
    XTableKillZoneStarReward = {
        Id = ValueTypeintPrimaryKey,
        Diff = ValueTypeint,
        Star = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableKizunaConfig = {
        Id = ValueTypeint,
        Count = ValueTypeint,
    },
    XTableKotodamaActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        TaskGroupId = ValueTypeint,
        ShowItem = Type1ValueTypeint,
        PrologueId = ValueTypestring,
        EpilogueId = ValueTypestring,
    },
    XTableKotodamaArtifact = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableKotodamaArtifactAffix = {
        Id = ValueTypeintPrimaryKey,
        Content = ValueTypestring,
        FightEventId = ValueTypeint,
    },
    XTableKotodamaArtifactCompose = {
        Id = ValueTypeintPrimaryKey,
        ArtifactId = ValueTypeint,
        Quality = ValueTypeint,
        ArtifactAffixIds = Type1ValueTypeint,
    },
    XTableKotodamaCharacterGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        CharacterId = ValueTypeint,
        RobotId = ValueTypeint,
    },
    XTableKotodamaClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Value = Type1ValueTypestring,
    },
    XTableKotodamaSentence = {
        Id = ValueTypeintPrimaryKey,
        PatternId = ValueTypeint,
        Words = Type1ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        Title = ValueTypestring,
        TitleFormat = ValueTypestring,
        ExtraContent = ValueTypestring,
        EndContent = ValueTypestring,
        IsCollect = ValueTypeint,
        IsVisible = ValueTypeint,
        IsEnableBan = ValueTypebool,
        BanFightEventIds = Type1ValueTypeint,
    },
    XTableKotodamaSentencePattern = {
        Id = ValueTypeintPrimaryKey,
        Content = ValueTypestring,
        PhraseId = ValueTypeint,
        DefaultWords = Type1ValueTypeint,
        Target = ValueTypeint,
        BlockNum = ValueTypeint,
    },
    XTableKotodamaStage = {
        Id = ValueTypeintPrimaryKey,
        OpenTime = ValueTypeint,
        SentencePatterns = Type1ValueTypeint,
        CharacterGroup = ValueTypeint,
        StageTitle = ValueTypestring,
        StageTitleEx = ValueTypestring,
        StageContent = ValueTypestring,
        SentenceIds = Type1ValueTypeint,
        Order = ValueTypeint,
        ShowMonsterName = Type1ValueTypestring,
        ShowMonsterIcon = Type1ValueTypestring,
        StageIcon = ValueTypestring,
        IsBranch = ValueTypeint,
        BranchPreStageId = ValueTypeint,
        BranchUnLockSentenceIds = Type1ValueTypeint,
        UnLockArtifactComposeId = ValueTypeint,
        EnableArtifactIds = Type1ValueTypeint,
    },
    XTableKotodamaWord = {
        Id = ValueTypeintPrimaryKey,
        PhraseId = ValueTypeint,
        Content = ValueTypestring,
        IsNeedUnLock = ValueTypebool,
        UnLockSentenceId = ValueTypeint,
    },
    XTableKotodamaWordBlock = {
        Id = ValueTypeintPrimaryKey,
        AnchoredX = ValueTypefloat,
        AnchoredY = ValueTypefloat,
        BlockWidth = ValueTypeint,
        UIWidth = ValueTypefloat,
    },
    XTableLevelMusicMap = {
        Id = ValueTypeintPrimaryKey,
        TutorialId = ValueTypeint,
        AreaMoveTypeList = Type1ValueTypeint,
        AreaInitPosList = Type1ValueTypeint,
        AreaInitMoveSpeedList = Type1ValueTypeint,
        FaultTolerance = ValueTypeint,
        LimitTime = ValueTypefloat,
        TrackList = Type1ValueTypeint,
    },
    XTableLevelMusicNote = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Length = ValueTypeint,
    },
    XTableLevelMusicTrack = {
        Id = ValueTypeintPrimaryKey,
        Length = ValueTypeint,
        NoteList = Type1ValueTypeint,
    },
    XTableLifeTreeChapter = {
        Id = ValueTypeintPrimaryKey,
        CharacterCatalogId = ValueTypeint,
        ConditionId = ValueTypeint,
        Icon = ValueTypestring,
        UnlockTips = ValueTypestring,
    },
    XTableLifeTreeCharacter = {
        Id = ValueTypeintPrimaryKey,
        ConditionIds = Type1ValueTypeint,
        UnlockTitles = Type1ValueTypestring,
        UiLifeTreeCardUnlockAnims = Type2KeyTypeintValueTypestring,
        GridDivineCardUnlockAnims = Type2KeyTypeintValueTypestring,
    },
    XTableLifeTreeCharacterCatalog = {
        Id = ValueTypeintPrimaryKey,
        ConstellationId = ValueTypeint,
        CharacterId = ValueTypeint,
        CardType = ValueTypeint,
        DivineUnlockProcessType = ValueTypeint,
        SceneFollowPoint = ValueTypestring,
        UiLifeTreeCardLink = ValueTypestring,
        LinkPos = ValueTypestring,
        LinkScaleWan = ValueTypeint,
        LinkIsShowLine = ValueTypebool,
        CardIcons = Type1ValueTypestring,
        Name = ValueTypestring,
        Descs = Type1ValueTypestring,
        SkipIds1 = Type1ValueTypeint,
        SkipDescs1 = Type1ValueTypestring,
        SkipIcons1 = Type1ValueTypestring,
        SkipIds2 = Type1ValueTypeint,
        SkipDescs2 = Type1ValueTypestring,
        SkipIcons2 = Type1ValueTypestring,
        UnlockSkipIds = Type1ValueTypeint,
        UnlockSkipDescs = Type1ValueTypestring,
        UnlockSkipIcons = Type1ValueTypestring,
    },
    XTableLifeTreeClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableLifeTreeConstellation = {
        Id = ValueTypeintPrimaryKey,
        Names = Type1ValueTypestring,
        Descs = Type1ValueTypestring,
        Icons = Type1ValueTypestring,
        CharacterCatalogIds = Type1ValueTypeint,
        TaskIds = Type1ValueTypeint,
        PreviewRewardId = ValueTypeint,
        AsideTips = ValueTypestring,
    },
    XTableLimitedLoginConst = {
        Id = ValueTypeint,
        QuizCount = ValueTypeint,
    },
    XTableLimitedLoginQuiz = {
        Id = ValueTypeint,
        Title = ValueTypestring,
        Answers = Type1ValueTypestring,
        CorrectAnsIdxs = Type1ValueTypeint,
        ImagePath = ValueTypestring,
    },
    XTableLineArithmetic2Help = {
        Id = ValueTypeintPrimaryKey,
        Round = ValueTypeint,
        X = ValueTypeint,
        Y = ValueTypeint,
    },
    XTableLineArithmetic3Help = {
        Id = ValueTypeintPrimaryKey,
        MapId = ValueTypeint,
        X = ValueTypeint,
        Y = ValueTypeint,
    },
    XTableLineArithmeticActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        RewardId = ValueTypeint,
        Name = ValueTypestring,
        Help = ValueTypeint,
        TaskIds = Type1ValueTypeint,
    },
    XTableLineArithmeticCar = {
        Id = ValueTypeintPrimaryKey,
        Carriages = Type1ValueTypeint,
        RoleImgs = Type1ValueTypestring,
    },
    XTableLineArithmeticCell = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Color = ValueTypeint,
        BulletNum = ValueTypeint,
        GridName = ValueTypestring,
        CharacterId = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableLineArithmeticChapter = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        TitleImg = ValueTypestring,
        BgChapter = ValueTypestring,
    },
    XTableLineArithmeticClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableLineArithmeticHelp = {
        Id = ValueTypeintPrimaryKey,
        Round = ValueTypeint,
        X = ValueTypeint,
        Y = ValueTypeint,
    },
    XTableLineArithmeticMap = {
        Id = ValueTypeintPrimaryKey,
        MapId = ValueTypeint,
        Row = ValueTypeint,
        Column = Type1ValueTypeint,
    },
    XTableLineArithmeticStage = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        PreStageId = ValueTypeint,
        MapId = ValueTypeint,
        StarCondition = Type1ValueTypeint,
        StarDesc = Type1ValueTypestring,
        CellId = Type1ValueTypeint,
        Name = ValueTypestring,
        MeshIcon = Type1ValueTypestring,
        MeshDesc = Type1ValueTypestring,
        SettleDesc = Type1ValueTypestring,
        SettleRoleIcon = ValueTypestring,
        ChapterRoleIcon = ValueTypestring,
    },
    XTableLinkCraftActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        Chapters = Type1ValueTypeint,
        Robots = Type1ValueTypeint,
        Skills = Type1ValueTypeint,
        DefaultSkill = Type1ValueTypeint,
        ShopId = ValueTypeint,
    },
    XTableLinkCraftChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        Condition = ValueTypeint,
        LinkId = ValueTypeint,
        Stages = Type1ValueTypeint,
    },
    XTableLinkCraftClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Value = Type1ValueTypestring,
    },
    XTableLinkCraftConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Value = ValueTypestring,
    },
    XTableLinkCraftLink = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Skills = Type1ValueTypeint,
    },
    XTableLinkCraftSkill = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        UnlockTips = ValueTypestring,
    },
    XTableLinkCraftStage = {
        Id = ValueTypeintPrimaryKey,
        Difficulty = ValueTypeint,
        ChapterId = ValueTypeint,
        StageId = ValueTypeint,
        StarsCnt = ValueTypeint,
        LinkId = ValueTypeint,
        LinkSkill = ValueTypeint,
        AffixIcon = Type1ValueTypestring,
        AffixDesc = Type1ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableLivWarmActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ItemId = ValueTypeint,
        UseItemCount = ValueTypeint,
        MaxWidth = ValueTypeint,
        MaxHeight = ValueTypeint,
    },
    XTableLivWarmActivityHead = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        ColumnIndexes = Type1ValueTypeint,
    },
    XTableLivWarmActivityLocal = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        HelpId = ValueTypeint,
        SkipId = ValueTypeint,
    },
    XTableLivWarmActivityStage = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        MaxItemCount = ValueTypeint,
        RewardProgress = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
        DismisMaxCount = ValueTypeint,
        RequireStageId = ValueTypeint,
    },
    XTableLivWarmActivityStageLocal = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        StageName = ValueTypestring,
        RoleHead = Type1ValueTypestring,
        StageEnName = ValueTypestring,
        CgPic = ValueTypestring,
        CgText = ValueTypestring,
    },
    XTableLivWarmExtActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
    },
    XTableLivWarmExtImg = {
        Id = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
        TimeId = ValueTypeint,
        ImgUrl = ValueTypestring,
    },
    XTableLivWarmExtTimeline = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        LockedIcon = ValueTypestring,
        UnlockIcon = ValueTypestring,
        Name = ValueTypestring,
        Url = ValueTypestring,
    },
    XTableLivWarmSoundsActivityCfg = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
    },
    XTableLivWarmSoundsActivityLocal = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        HelpId = ValueTypeint,
        ClearBgImg = ValueTypestring,
    },
    XTableLivWarmSoundsActivityStage = {
        Id = ValueTypeintPrimaryKey,
        FinishSoundId = Type1ValueTypeint,
        ActivityId = ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableLoading = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypestring,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        ImageUrl = ValueTypestring,
        Weight = ValueTypeint,
        ShowCondition = Type1ValueTypeint,
    },
    XTableLoadingTypeMap = {
        Type = ValueTypestringPrimaryKey,
        LoadingIds = Type1ValueTypeint,
    },
    XTableLoginCode = {
        ErrCode = ValueTypeintPrimaryKey,
        Msg = ValueTypestring,
    },
    XTableLoginPromoFeature = {
        Id = ValueTypeintPrimaryKey,
        ConditionId = ValueTypeint,
        EnterTimeId = ValueTypeint,
        EnterSkipId = ValueTypeint,
        GotoSkipId = ValueTypeint,
        VideoConfigId = Type1ValueTypeint,
        ShowTimeId = ValueTypeint,
    },
    XTableLoginProtect = {
        Id = ValueTypeintPrimaryKey,
        LoginTime = ValueTypeint,
        Interval = ValueTypeint,
        Hint = ValueTypestring,
    },
    XTableLotto = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        LottoGroupId = ValueTypeint,
        LottoStageActivity = ValueTypeint,
        Priority = ValueTypeint,
        OpenUiName = ValueTypestring,
        Banner = ValueTypestring,
        ReachRewardTimes = ValueTypeint,
        ExtraRewardId = ValueTypeint,
        ConsumeId = ValueTypeint,
        BuyTicketRuleIdList = Type1ValueTypeint,
        ConsumeCountList = Type1ValueTypeint,
        StoryStageMode = ValueTypeint,
    },
    XTableLottoBuyTicketRule = {
        Id = ValueTypeintPrimaryKey,
        UseItemId = Type2KeyTypeintValueTypeint,
        Sale = Type2KeyTypeintValueTypestring,
        UseItemCount = Type2KeyTypeintValueTypeint,
        UseItemImg = Type2KeyTypeintValueTypestring,
        TargetItemCount = ValueTypeint,
        TargetItemImg = ValueTypestring,
    },
    XTableLottoClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Value = Type1ValueTypestring,
    },
    XTableLottoFashionSelfChoiceResources = {
        LottoId = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        SkipId = ValueTypeint,
        EntranceIcon = ValueTypestring,
        VideoConfigId = ValueTypeint,
        SpecialRewardTemplateIds = Type1ValueTypeint,
    },
    XTableLottoGroupRule = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Tag = ValueTypeint,
        Priority = ValueTypeint,
        UiType = ValueTypeint,
        GroupBtnBg = ValueTypestring,
        UiPrefab = ValueTypestring,
        Banner = ValueTypestring,
        UiBackGround = ValueTypestring,
        RuleHint = ValueTypestring,
        BaseRuleTitles = Type1ValueTypestring,
        BaseRules = Type1ValueTypestring,
    },
    XTableLottoPrimary = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Desc = ValueTypestring,
        LottoIdList = Type1ValueTypeint,
        RuleTitleList = Type1ValueTypestring,
        RuleTextList = Type1ValueTypestring,
        MaxSelectCount = ValueTypeint,
    },
    XTableLottoProbShow = {
        Id = ValueTypeintPrimaryKey,
        LottoId = ValueTypeint,
        RareLevel = ValueTypeint,
        Priority = ValueTypeint,
        ProbShow = Type1ValueTypestring,
    },
    XTableLottoReward = {
        Id = ValueTypeintPrimaryKey,
        LottoId = ValueTypeint,
        TemplateId = ValueTypeint,
        Count = ValueTypeint,
        Params = Type1ValueTypeint,
        Weights = Type1ValueTypeint,
        ShowTimelineName = ValueTypestring,
        ShowEffectId = ValueTypeint,
    },
    XTableLottoSceneVideo = {
        LottoId = ValueTypeintPrimaryKey,
        VideoConfigId = ValueTypeint,
    },
    XTableLottoShowRewardConfig = {
        Id = ValueTypeintPrimaryKey,
        DrawEffectPath = ValueTypestring,
        EffectPosition = ValueTypestring,
        EffectRotation = ValueTypestring,
        EffectScale = ValueTypestring,
        AnimationName = ValueTypestring,
    },
    XTableLuaFunctionParams = {
        Id = ValueTypeintPrimaryKey,
        FunctionName = ValueTypestring,
        Params = Type1ValueTypestring,
    },
    XTableLuckyTenant2Activity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        HelpId = ValueTypestring,
        TaskGroup = Type1ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableLuckyTenant2Bond = {
        Id = ValueTypeintPrimaryKey,
        BondId = ValueTypeint,
        BondName = ValueTypestring,
        Icon = ValueTypestring,
        RelatedChess = ValueTypestring,
        RelatedChessForScore = ValueTypestring,
        UpgradeRequire = ValueTypeint,
        UpgradeRequireDesc = ValueTypestring,
    },
    XTableLuckyTenant2BondQuality = {
        Id = ValueTypeintPrimaryKey,
        Quality = ValueTypeint,
        BgPath = ValueTypestring,
    },
    XTableLuckyTenant2BondSkill = {
        Id = ValueTypeintPrimaryKey,
        BondId = ValueTypeint,
        Level = ValueTypeint,
        SkillRequire = ValueTypeint,
        SkillId = ValueTypeint,
        SkillQualityId = ValueTypeint,
        IsPassive = ValueTypebool,
        SkillMode = ValueTypeint,
        EffectiveLevelEnd = ValueTypeint,
    },
    XTableLuckyTenant2Chapter = {
        Id = ValueTypeintPrimaryKey,
        StageId = Type1ValueTypeint,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
    },
    XTableLuckyTenant2Chess = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Quality = ValueTypeint,
        Name = ValueTypestring,
        Desc = Type1ValueTypestring,
        Value = ValueTypeint,
        Icon = ValueTypestring,
        CanDelete = ValueTypeint,
        CanDie = ValueTypeint,
        Priority = ValueTypeint,
        SkillId = Type1ValueTypeint,
        Tag = Type1ValueTypestring,
        ValueUponDeletion = ValueTypeint,
        BondId = ValueTypestring,
        CanUseForBond = ValueTypeint,
        DefaultLevel = ValueTypeint,
        CanUpgrade = ValueTypeint,
        CanBeEliminated = ValueTypeint,
        StateSkillId = Type1ValueTypeint,
    },
    XTableLuckyTenant2ChessCondition = {
        Id = ValueTypeintPrimaryKey,
        ConditionDesc = ValueTypestring,
        Param = Type1ValueTypeint,
    },
    XTableLuckyTenant2ChessRandomGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        PieceId = ValueTypeint,
        PieceWeight = ValueTypeint,
        Condition = Type1ValueTypeint,
        IncreaseWeight = Type1ValueTypeint,
    },
    XTableLuckyTenant2ChessRound = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        StartRound = ValueTypeint,
        Group = Type1ValueTypeint,
        FirstUseInRound = Type1ValueTypeint,
        FirstUseInStage = Type1ValueTypeint,
    },
    XTableLuckyTenant2ChessSkill = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Params = Type1ValueTypeint,
        Score = ValueTypeint,
        Priority = ValueTypeint,
        IsPassive = ValueTypeint,
        IsEffectUponJoining = ValueTypeint,
        EffectJustOnFirstRound = ValueTypeint,
        Condition = ValueTypestring,
    },
    XTableLuckyTenant2ChessType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableLuckyTenant2Quality = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IconQuad = ValueTypestring,
        IconCircle = ValueTypestring,
        BgChessDetail = ValueTypestring,
    },
    XTableLuckyTenant2Stage = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        PreStage = ValueTypeint,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        BagCapacity = ValueTypeint,
        FirstSupplyCnt = ValueTypeint,
        InitialPiece = Type1ValueTypeint,
        InitialPieceNum = Type1ValueTypeint,
        Row = ValueTypeint,
        Column = ValueTypeint,
        Desc = ValueTypestring,
        PerfectDesc = ValueTypestring,
        ShowDeleteOption = ValueTypebool,
        InitialPieceGroup = ValueTypeint,
        InitialPieceGroupAmount = ValueTypeint,
        IsChallenge = ValueTypeint,
        CoverImage = ValueTypestring,
        ShowBondId = ValueTypestring,
        TutorialPage = ValueTypeint,
    },
    XTableLuckyTenant2StageTask = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Round = ValueTypeint,
        Score = ValueTypeint,
        RewardPieces = Type1ValueTypeint,
        RewardPiecesAmount = Type1ValueTypeint,
        NormalClear = ValueTypebool,
        PerfectClear = ValueTypebool,
        Condition = ValueTypestring,
    },
    XTableLuckyTenant2TestCase = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Desc = ValueTypestring,
        Pos = Type1ValueTypeint,
    },
    XTableLuckyTenantActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        HelpId = ValueTypestring,
        ShowReward = Type1ValueTypeint,
        TaskGroup = Type1ValueTypeint,
    },
    XTableLuckyTenantChess = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Quality = ValueTypeint,
        Name = ValueTypestring,
        Desc = Type1ValueTypestring,
        Value = ValueTypeint,
        Icon = ValueTypestring,
        CanDelete = ValueTypeint,
        CanDie = ValueTypeint,
        Priority = ValueTypeint,
        SkillId = Type1ValueTypeint,
        Tag = Type1ValueTypestring,
        ValueUponDeletion = ValueTypeint,
    },
    XTableLuckyTenantChessCondition = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Params = Type1ValueTypestring,
    },
    XTableLuckyTenantChessRandomGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        PieceId = ValueTypeint,
        PieceWeight = ValueTypeint,
        Condition = Type1ValueTypeint,
        IncreaseWeight = Type1ValueTypeint,
    },
    XTableLuckyTenantChessRound = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        StartRound = ValueTypeint,
        Group = Type1ValueTypeint,
        FirstUseInRound = Type1ValueTypeint,
        FirstUseInStage = Type1ValueTypeint,
    },
    XTableLuckyTenantChessSkill = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Params = Type1ValueTypeint,
        Score = ValueTypeint,
        Priority = ValueTypeint,
        IsPassive = ValueTypebool,
        IsEffectUponJoining = ValueTypebool,
        EffectJustOnFirstRound = ValueTypebool,
    },
    XTableLuckyTenantChessType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableLuckyTenantQuality = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IconQuad = ValueTypestring,
        IconCircle = ValueTypestring,
    },
    XTableLuckyTenantStage = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        TimeId = ValueTypeint,
        PreStage = ValueTypeint,
        FirstSupplyCnt = ValueTypeint,
        BagCapacity = ValueTypeint,
        Name = ValueTypestring,
        InitialPiece = Type1ValueTypeint,
        InitialPieceNum = Type1ValueTypeint,
        SpecialPieceType = Type1ValueTypeint,
        SpecialScore = Type1ValueTypeint,
        Row = ValueTypeint,
        Column = ValueTypeint,
        Desc = ValueTypestring,
        ShowDeleteOption = ValueTypebool,
        InitialPieceGroup = ValueTypeint,
        InitialPieceGroupAmount = ValueTypeint,
        IsChallenge = ValueTypebool,
        CoverImage = ValueTypestring,
    },
    XTableLuckyTenantStageTask = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Round = ValueTypeint,
        Score = ValueTypeint,
        RewardPieces = Type1ValueTypeint,
        RewardPiecesAmount = Type1ValueTypeint,
        NormalClear = ValueTypebool,
        PerfectClear = ValueTypebool,
    },
    XTableLuckyTenantTag = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableLuckyTenantTestCase = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Desc = ValueTypestring,
        Pos = Type1ValueTypeint,
    },
    XTableMail = {
        Id = ValueTypeintPrimaryKey,
        RewardIds = Type1ValueTypeint,
    },
    XTableMailCollectionBoxActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        FavoriteMailIds = Type1ValueTypeint,
    },
    XTableMailCollectionBoxFavoriteMail = {
        Id = ValueTypeintPrimaryKey,
        TagId = ValueTypeint,
        ShowTime = ValueTypestring,
        MailIcon = ValueTypestring,
        Desc = ValueTypestring,
        Title = ValueTypestring,
        SendName = ValueTypestring,
        Content = ValueTypestring,
        RewardIds = Type1ValueTypeint,
    },
    XTableMailCollectionBoxFavoriteMailTag = {
        Id = ValueTypeintPrimaryKey,
        TagName = ValueTypestring,
        Desc = ValueTypestring,
        EnName = ValueTypestring,
        TagImage = ValueTypestring,
        TagBg = ValueTypestring,
    },
    XTableMailInitData = {
        Id = ValueTypeintPrimaryKey,
        Ids = Type1ValueTypeint,
    },
    XTableMainActivitySkip = {
        Id = ValueTypeintPrimaryKey,
        SkipId = ValueTypeint,
        StageType = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableMainAd = {
        Id = ValueTypeint,
        Priority = ValueTypeint,
        PicType = ValueTypeint,
        PicAddr = ValueTypestring,
        JumpType = ValueTypeint,
        JumpAddr = ValueTypestring,
        ChannelId = ValueTypeint,
    },
    XTableMainLine2Achievement = {
        Id = ValueTypeintPrimaryKey,
        Count = ValueTypeint,
        ClearRewardId = ValueTypeint,
        Icon = ValueTypestring,
        IconLock = ValueTypestring,
        ChapterIcon = ValueTypestring,
        ChapterIconLock = ValueTypestring,
        ChapterEffect = ValueTypestring,
    },
    XTableMainLine2Chapter = {
        ChapterId = ValueTypeintPrimaryKey,
        Difficult = ValueTypeint,
        DifficultName = ValueTypestring,
        DifficultEnName = ValueTypestring,
        DifficultColor = ValueTypestring,
        Desc = ValueTypestring,
        ActivityTimeId = ValueTypeint,
        ActivityCondition = ValueTypeint,
        OpenCondition = ValueTypeint,
        StageGroupIds = Type1ValueTypeint,
        PrefabName = ValueTypestring,
        BgStageIndexs = Type1ValueTypeint,
        TitleTextColors = Type1ValueTypestring,
        LeftTimeTextColors = Type1ValueTypestring,
        ProgressTextColors = Type1ValueTypestring,
        TreasureId = ValueTypeint,
        AchievementId = ValueTypeint,
        SkipIds = Type1ValueTypeint,
        SkipConditions = Type1ValueTypeint,
        SkipIcons = Type1ValueTypestring,
        SkipNames = Type1ValueTypestring,
        SkipChapterNames = Type1ValueTypestring,
        EggIds = Type1ValueTypeint,
        SpineStageIndexs = Type1ValueTypeint,
        SpineProgressWans = Type1ValueTypeint,
        BgSpineStageIndexs = Type1ValueTypeint,
        BgSpineProgressWans = Type1ValueTypeint,
        EnterSpineStageIndex = Type1ValueTypeint,
        EnterSpineName = Type1ValueTypestring,
        SwitchSpineStageIndex = Type1ValueTypeint,
        SwitchAheadSpineName = Type1ValueTypestring,
        SwitchBackwardSpineName = Type1ValueTypestring,
        IdleSpineStageIndexs = Type1ValueTypeint,
        IdleSpineName = Type1ValueTypestring,
    },
    XTableMainLine2ClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Note = ValueTypestring,
        Params = Type1ValueTypestring,
    },
    XTableMainLine2EggsTreasure = {
        Id = ValueTypeintPrimaryKey,
        ConditionId = ValueTypeint,
        TipsText = ValueTypestring,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        RewardId = ValueTypeint,
    },
    XTableMainLine2ExhibitionChapter = {
        Id = ValueTypeintPrimaryKey,
        TitleName = ValueTypestring,
        SubTitleName = ValueTypestring,
        UiName = ValueTypestring,
        ExhibitionFubenType = ValueTypeint,
        ExhibitionFubenConfigId = ValueTypeint,
        PreIds = Type1ValueTypeint,
        ShowConditionId = ValueTypeint,
        BgPath = ValueTypestring,
        BgPosX = ValueTypeint,
        BgPosY = ValueTypeint,
    },
    XTableMainLine2ExhibitionModule = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        BgImage = ValueTypestring,
        BgmCueId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        Condition = Type1ValueTypeint,
        SpineCondition = Type1ValueTypestring,
        BgCondition = Type1ValueTypestring,
    },
    XTableMainLine2Main = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Name = ValueTypestring,
        NameFontSize = ValueTypeint,
        Icon = ValueTypestring,
        StoryType = ValueTypeint,
        GroupId = ValueTypeint,
        OrderId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        AchievementId = ValueTypeint,
        RedTimeId = ValueTypeint,
        SpecialCondition = ValueTypeint,
        SpecialTagName = ValueTypestring,
        SpecailEffect = ValueTypestring,
        HideChapterOption = ValueTypeint,
        TreasureId = ValueTypeint,
        SettlementBg = ValueTypestring,
        ShowCondition = ValueTypeint,
        TaskGroupId = ValueTypeint,
    },
    XTableMainLine2MessageContents = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        NextMessageIds = Type1ValueTypeint,
        Name = ValueTypestring,
        CueId = ValueTypeint,
        RoleIcon = ValueTypestring,
        Desc = ValueTypestring,
        ShowIcon = ValueTypestring,
        ConfirmContent = Type1ValueTypestring,
    },
    XTableMainLine2MessageGroups = {
        Id = ValueTypeintPrimaryKey,
        MessageIds = Type1ValueTypeint,
    },
    XTableMainLine2MessagePosition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        BeginContentId = ValueTypeint,
        UiPosIndex = ValueTypeint,
        Conditions = Type1ValueTypeint,
    },
    XTableMainLine2Stage = {
        Id = ValueTypeintPrimaryKey,
        StageDetailType = ValueTypeint,
        TransformCondition = ValueTypeint,
        TransformStageId = ValueTypeint,
        Ignore = ValueTypebool,
        UnlockCondition = ValueTypeint,
        ProgressConditions = Type1ValueTypeint,
        ProgressGreyBg = ValueTypestring,
        ProgressBg = ValueTypestring,
        AchievementTpyes = Type1ValueTypeint,
        AchievementNames = Type2KeyTypeintValueTypestring,
        AchievementDescs = Type2KeyTypeintValueTypestring,
        AchievementBriefDescs = Type2KeyTypeintValueTypestring,
        AchievementUndoneDescs = Type2KeyTypeintValueTypestring,
        VideoIds = Type1ValueTypeint,
        VideoConditions = Type2KeyTypeintValueTypeint,
        Specialorder = ValueTypestring,
        MonsterHeads = Type1ValueTypestring,
        MonsterReplaceOrders = Type1ValueTypeint,
        EffectPath = ValueTypestring,
    },
    XTableMainLine2StageArea = {
        Id = ValueTypeintPrimaryKey,
        AreaStageIds = Type1ValueTypeint,
        AreaMessageIds = Type1ValueTypeint,
        CenterNodeId = ValueTypeint,
        CenterNodeType = ValueTypeint,
        AreaIndex = ValueTypeint,
        TimelineProgress = ValueTypefloat,
        TimelineOffset = ValueTypeint,
    },
    XTableMainLine2StageAreaGroup = {
        Id = ValueTypeintPrimaryKey,
        AreaIds = Type1ValueTypeint,
    },
    XTableMainLine2StageGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupType = ValueTypeint,
        GroupName = ValueTypestring,
        AchievementIsCombine = ValueTypeint,
        StageIds = Type1ValueTypeint,
    },
    XTableMainLine2Treasure = {
        Id = ValueTypeintPrimaryKey,
        StageCounts = Type1ValueTypeint,
        RewardIds = Type1ValueTypeint,
        HighlightRewardIds = Type1ValueTypeint,
    },
    XTableMainLineActivity = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = Type1ValueTypeint,
        BfrtChapter = ValueTypeint,
        ChapterTimeId = ValueTypeint,
        HideChapterTimeId = ValueTypeint,
        VariationsChapterTimeId = ValueTypeint,
    },
    XTableMainLineExploreGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        StageIndex = ValueTypeint,
        PreShowIndex = Type1ValueTypeint,
    },
    XTableMainLineExploreItem = {
        Id = ValueTypeintPrimaryKey,
        MainChapterId = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Hint = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableMainlineIgnoreStageList = {
        StageId = ValueTypeintPrimaryKey,
        Id = ValueTypeint,
        Note = ValueTypestring,
    },
    XTableMainLineLuosaitaArmy = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ConditionId = ValueTypeint,
        Attack = ValueTypeint,
        Hp = ValueTypeint,
        Desc = ValueTypestring,
        Head = ValueTypestring,
        AnimConditionId = ValueTypeint,
        AnimName = ValueTypestring,
    },
    XTableMainLineLuosaitaBlock = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SectionId = ValueTypeint,
        EdgeBlocks = Type1ValueTypeint,
        UiNodeName = ValueTypestring,
    },
    XTableMainLineLuosaitaCharacter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ConditionId = ValueTypeint,
        DisappearConditionId = ValueTypeint,
        Desc = ValueTypestring,
        Head = ValueTypestring,
        HeadCircle = ValueTypestring,
        AnimConditionId = ValueTypeint,
        AnimName = ValueTypestring,
    },
    XTableMainLineLuosaitaCharacterMove = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        ConditionId = ValueTypeint,
        PosId = ValueTypeint,
        Millisecond = ValueTypeint,
    },
    XTableMainLineLuosaitaConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableMainLineLuosaitaDocument = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        PopUpTitle = ValueTypestring,
        PopUpName = ValueTypestring,
        PopUpDesc = ValueTypestring,
    },
    XTableMainLineLuosaitaEnemy = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Attack = ValueTypeint,
        Hp = ValueTypeint,
        AttackChange = ValueTypeint,
        HpChange = ValueTypeint,
        ConditionId = ValueTypeint,
        DisappearConditionId = ValueTypeint,
        ShowConditionId = ValueTypeint,
        ChallengeArmyId = ValueTypeint,
        ChallengeArmyTips = ValueTypestring,
        DocIds = Type1ValueTypeint,
        Desc = ValueTypestring,
        Head = ValueTypestring,
        MessageId = ValueTypeint,
    },
    XTableMainLineLuosaitaMessage = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        Text = ValueTypestring,
    },
    XTableMainLineLuosaitaPosition = {
        Id = ValueTypeintPrimaryKey,
        BlockId = ValueTypeint,
        Type = ValueTypeint,
        MemberId = ValueTypeint,
        UiNodeName = ValueTypestring,
    },
    XTableMainLineLuosaitaSection = {
        Id = ValueTypeintPrimaryKey,
        MessageGroups = Type1ValueTypeint,
        MapPrefabPath = ValueTypestring,
        Name = ValueTypestring,
        ConditionIds = Type2KeyTypeintValueTypeint,
        FocusPosUiNodeNames = Type1ValueTypestring,
        EnableAnims = Type2KeyTypeintValueTypestring,
        LoopAnims = Type2KeyTypeintValueTypestring,
    },
    XTableMainLineLuosaitaStage = {
        Id = ValueTypeintPrimaryKey,
        ConditionId = ValueTypeint,
        DocIds = Type1ValueTypeint,
        MessageId = ValueTypeint,
    },
    XTableMainLineNextChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        SkipCondition = ValueTypeint,
        TRPGChapterId = ValueTypeint,
        StoryImgs = Type1ValueTypestring,
        StorySkipId = Type1ValueTypeint,
        StorySkipName = Type1ValueTypestring,
        StoryChpterType = Type1ValueTypeint,
        StoryChapterId = Type1ValueTypeint,
        StoryChapterName = Type1ValueTypestring,
    },
    XTableMainLineStageClearContr = {
        StageId = ValueTypeintPrimaryKey,
        ProgressBgIcon = ValueTypestring,
        ProgressBarIcon = ValueTypestring,
    },
    XTableMainLineStageEx = {
        Id = ValueTypeintPrimaryKey,
        EventEffect = ValueTypestring,
        EventIcon = ValueTypestring,
        EventParams = Type1ValueTypestring,
    },
    XTableMainLineStageTransform = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        BeforeStageId = ValueTypeint,
        AfterStageId = ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableMainLineTeleport = {
        StageId = ValueTypeintPrimaryKey,
        SkipStageId = Type1ValueTypeint,
        SkipLoadingType = Type1ValueTypestring,
        KeepPlayingStory = ValueTypeint,
    },
    XTableMainLineTip = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Desc = ValueTypestring,
        Condition = ValueTypeint,
        SkipFunction = ValueTypeint,
    },
    XTableMaintainerActionConfig = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        StoryId = ValueTypestring,
        MaxDailyActionCount = ValueTypeint,
        MaxFightWinCount = ValueTypeint,
        MaxBoxCount = ValueTypeint,
        MaxWarehouseFinishCount = ValueTypeint,
        NodeCount = ValueTypeint,
        MaxCardNumber = ValueTypeint,
        MaxHandCardCount = ValueTypeint,
        NodePoolId = ValueTypeint,
        TeacherMailId = ValueTypeint,
        StudentMailId = ValueTypeint,
    },
    XTableMaintainerActionEvent = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IsRecord = ValueTypeint,
        RecordText = ValueTypestring,
        HintText = ValueTypestring,
        DescText = ValueTypestring,
        EventIcon = ValueTypestring,
    },
    XTableMaintainerActionEventNode = {
        Id = ValueTypeint,
        PoolId = ValueTypeint,
        NodeInfoId = ValueTypeint,
        MinCount = ValueTypeint,
        MaxCount = ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableMaintainerActionFightNode = {
        Id = ValueTypeint,
        Nodes = Type1ValueTypeint,
    },
    XTableMaintainerActionLevel = {
        Level = ValueTypeintPrimaryKey,
        StageIds = Type1ValueTypeint,
        BoxRewardIds = Type1ValueTypeint,
    },
    XTableMaintainerActionNodeInfo = {
        Id = ValueTypeint,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Seen = ValueTypebool,
        Params = Type1ValueTypeint,
        EventIds = Type1ValueTypeint,
    },
    XTableMainTaskTabControl = {
        Id = ValueTypeintPrimaryKey,
        TagName = ValueTypestring,
        TagType = ValueTypeint,
        ShowCondition = ValueTypeint,
        UnlockCondition = ValueTypeint,
        FunctionId = ValueTypeint,
        ShowTypeInHideFunc = ValueTypeint,
        RedPointConditions = Type1ValueTypestring,
        RedPointArgs = Type1ValueTypeint,
    },
    XTableMapPinLut = {
        Id = ValueTypeintPrimaryKey,
        PerfabUrl = ValueTypestring,
    },
    XTableMapResLut = {
        Id = ValueTypeintPrimaryKey,
        MiniMapUrl = ValueTypestring,
        DetailMapUrl = ValueTypestring,
    },
    XTableMark = {
        MarkId = ValueTypeintPrimaryKey,
        MinPoint = ValueTypeint,
        MaxPoint = ValueTypeint,
        EnemyHpPoint = ValueTypestring,
        MyHpPoint = ValueTypestring,
        TimePoint = ValueTypestring,
        MaxEnemyHpPoint = ValueTypeint,
        MaxMyHpPoint = ValueTypeint,
        MaxTimePoint = ValueTypeint,
        NpcGroupPoint = ValueTypestring,
        MaxNpcGroupPoint = ValueTypeint,
    },
    XTableMasterStageReward = {
        Count = ValueTypeintPrimaryKey,
        RewardId = ValueTypeint,
    },
    XTableMasterWeeklyTaskReward = {
        TaskId = ValueTypeintPrimaryKey,
        RewardId = ValueTypeint,
    },
    XTableMaverick2Activity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
    },
    XTableMaverick2Attribute = {
        Id = ValueTypeintPrimaryKey,
        ShowType = ValueTypeint,
        Name = ValueTypestring,
        Order = ValueTypeint,
        Icon = ValueTypestring,
        EnglishName = ValueTypestring,
    },
    XTableMaverick2Chapter = {
        ChapterId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ActivityId = ValueTypeint,
        OpenTime = ValueTypeint,
        PreStageId = ValueTypeint,
        DailyStageCount = ValueTypeint,
        Background = ValueTypestring,
        BackgroundEffect = ValueTypestring,
        Bgm = ValueTypestring,
        IfFlag = ValueTypeint,
        Map = ValueTypeint,
        MapBg = ValueTypestring,
        MapEffect = ValueTypestring,
        ShopBg = ValueTypestring,
    },
    XTableMaverick2Config = {
        Key = ValueTypestringPrimaryKey,
        Params = Type1ValueTypestring,
    },
    XTableMaverick2Mental = {
        Level = ValueTypeintPrimaryKey,
        NeedUnit = ValueTypeint,
        FightEventId = ValueTypeint,
        FightEventLevel = ValueTypeint,
        AttrId = Type1ValueTypeint,
        AttrValue = Type1ValueTypeint,
    },
    XTableMaverick2Movie = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        OpenMovieId = ValueTypestring,
        CloseStageIds = Type1ValueTypeint,
        CloseMovieIds = Type1ValueTypestring,
    },
    XTableMaverick2Robot = {
        RobotId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        UnLockDesc = ValueTypestring,
        Desc = ValueTypestring,
        Condition = ValueTypeint,
        FightEventId = ValueTypeint,
        FightEventLevel = ValueTypeint,
        AttrId = Type1ValueTypeint,
        AttrValue = Type1ValueTypeint,
        SkillIds = Type1ValueTypeint,
    },
    XTableMaverick2SkillDesc = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Intro = ValueTypestring,
    },
    XTableMaverick2Stage = {
        StageId = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        StageType = ValueTypeint,
        PreStageId = ValueTypeint,
        FirstRewardId = ValueTypeint,
        RewardUnit = ValueTypeint,
        FightEventId = Type1ValueTypeint,
        FightEventLevel = Type1ValueTypeint,
        RecommendMentalLv = ValueTypeint,
        MainlineTips = ValueTypestring,
        IconPos = ValueTypeint,
        RewardParam = Type1ValueTypestring,
        ForbidRobot = Type1ValueTypeint,
    },
    XTableMaverick2StageType = {
        TypeId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        DetailBg = ValueTypestring,
        NameBgColor = ValueTypestring,
    },
    XTableMaverick2Talent = {
        Id = ValueTypeintPrimaryKey,
        TalentId = ValueTypeint,
        NeedUnit = ValueTypeint,
        Condition = ValueTypeint,
        FightEventId = ValueTypeint,
        FightEventLevel = ValueTypeint,
        Desc = ValueTypestring,
        UnlockTips = ValueTypestring,
        UnlockName = ValueTypestring,
        UnlockDesc = ValueTypestring,
        Icon = ValueTypestring,
        AttrId = ValueTypeint,
        AttrValue = ValueTypeint,
    },
    XTableMaverick2TalentGroup = {
        Id = ValueTypeintPrimaryKey,
        TalentGroupId = ValueTypeint,
        Name = ValueTypestring,
        TalentId = ValueTypeint,
        AssistFlag = ValueTypeint,
        SummaryTab = ValueTypeint,
    },
    XTableMaverick2TalentTree = {
        Id = ValueTypeintPrimaryKey,
        RobotId = ValueTypeint,
        Order = ValueTypeint,
        TalentGroupId = ValueTypeint,
        NeedMentalLv = ValueTypeint,
        NeedUnit = ValueTypeint,
        UseUiPos1 = ValueTypeint,
        UseUiPos2 = ValueTypeint,
        UseUiPos3 = ValueTypeint,
    },
    XTableMaverick3Activity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        DailyTaskGroup = ValueTypeint,
        ShopId = ValueTypeint,
        DamageRate = ValueTypefloat,
        KillRate = ValueTypefloat,
    },
    XTableMaverick3Chapter = {
        ChapterId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        OpenTimeId = ValueTypeint,
        Type = ValueTypeint,
        Difficult = ValueTypeint,
        Bg = ValueTypestring,
    },
    XTableMaverick3ClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableMaverick3Robot = {
        Id = ValueTypeintPrimaryKey,
        RobotId = ValueTypeint,
        Condition = ValueTypeint,
        AttrId = Type1ValueTypeint,
        AttrValue = Type1ValueTypeint,
        SkillIds = Type1ValueTypeint,
        Talentds = Type1ValueTypeint,
        FashionId = ValueTypeint,
    },
    XTableMaverick3Skill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        Video = ValueTypestring,
    },
    XTableMaverick3Stage = {
        StageId = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        StageType = ValueTypeint,
        PreStageId = ValueTypeint,
        FirstRewardId = ValueTypeint,
        FinishRewardId = ValueTypeint,
        FirstShowRewardId = ValueTypeint,
        StoryId = ValueTypeint,
        OpenTimeId = ValueTypeint,
        StarConditions = Type1ValueTypeint,
        StarDesc = Type1ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableMaverick3Story = {
        Id = ValueTypeintPrimaryKey,
        Chapter = ValueTypeint,
        Condition = ValueTypeint,
        Name = ValueTypestring,
        AvgId = ValueTypestring,
        Bg = ValueTypestring,
        Words = ValueTypestring,
        IsEnd = ValueTypeint,
    },
    XTableMaverick3Talent = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Fightevents = Type1ValueTypeint,
        NeedItemCount = ValueTypeint,
        Condition = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableMaverickActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        EntryTexture = ValueTypestring,
        RankStageId = ValueTypeint,
        PatternIds = Type1ValueTypeint,
    },
    XTableMaverickDisplayAttrib = {
        Id = ValueTypeintPrimaryKey,
        Life = ValueTypeint,
        Attack = ValueTypeint,
        Defense = ValueTypeint,
        Crit = ValueTypeint,
    },
    XTableMaverickLevelUp = {
        Id = ValueTypeintPrimaryKey,
        MemberId = ValueTypeint,
        Level = ValueTypeint,
        RobotId = ValueTypeint,
        ConsumeItemCount = ValueTypeint,
        CombatScore = ValueTypeint,
        DisplayAttribId = ValueTypeint,
    },
    XTableMaverickMember = {
        Id = ValueTypeintPrimaryKey,
        UnlockStageId = ValueTypeint,
        TalentIds = Type1ValueTypeint,
        FightEventId = ValueTypeint,
        Attributes = Type1ValueTypestring,
        SkillIds = Type1ValueTypeint,
    },
    XTableMaverickNumIcon = {
        Num = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
    },
    XTableMaverickPattern = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        PatternName = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableMaverickSkillDesc = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Intro = ValueTypestring,
    },
    XTableMaverickStage = {
        StageId = ValueTypeintPrimaryKey,
        PatternId = ValueTypeint,
        StageType = ValueTypeint,
        GridIndex = ValueTypeint,
        GridName = ValueTypestring,
        Danger = ValueTypeint,
        Tips = Type1ValueTypestring,
        AffixIds = Type1ValueTypeint,
        MonsterIds = Type1ValueTypeint,
    },
    XTableMaverickTalent = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        PreTalentId = ValueTypeint,
        UnlockLevel = ValueTypeint,
        FightEventId = ValueTypeint,
        Intro = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableMazeActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        TicketItemId = ValueTypeint,
        TicketCount = ValueTypeint,
        ExtraTicketDay = ValueTypeint,
        ExtraTicketCount = ValueTypeint,
        FastPassParam = ValueTypeint,
        FastPassFightEvent = ValueTypeint,
        PassFightEvent = ValueTypeint,
        TimeLimitTaskId = ValueTypeint,
        StoryId = ValueTypestring,
        StoryIcon = ValueTypestring,
        PlayerModel = ValueTypestring,
    },
    XTableMazeGrade = {
        Id = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        Score = ValueTypeint,
    },
    XTableMazeRandomAction = {
        Id = ValueTypeintPrimaryKey,
        ModelName = ValueTypestring,
        Timeline = ValueTypestring,
    },
    XTableMazeStage = {
        StageId = ValueTypeintPrimaryKey,
        RobotId = ValueTypeint,
        FightEventId = ValueTypeint,
        Priority = ValueTypeint,
        SettleBg = ValueTypestring,
    },
    XTableMechanismActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        ShopId = ValueTypeint,
        CoinItem = ValueTypeint,
        ShowRewardId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
    },
    XTableMechanismChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        TeamName = ValueTypestring,
        Icon = ValueTypestring,
        BigBg = ValueTypestring,
        StageIds = Type1ValueTypeint,
        LimitCharacterIds = Type1ValueTypeint,
    },
    XTableMechanismCharacter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        CharacterId = ValueTypeint,
        RobotId = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        BuffConditions = Type1ValueTypeint,
        CharacterTitles = Type1ValueTypestring,
        CharacterDesc = Type1ValueTypestring,
        BuffIcons = Type1ValueTypestring,
        BuffNames = Type1ValueTypestring,
        BuffDesc = Type1ValueTypestring,
    },
    XTableMechanismClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Value = Type1ValueTypestring,
    },
    XTableMechanismStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        AffixIcons = Type1ValueTypestring,
        AffixDesc = Type1ValueTypestring,
        StarRewards = Type1ValueTypeint,
        StarDesc = Type1ValueTypestring,
    },
    XTableMedal = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        UnlockType = ValueTypeint,
        UnlockPara = Type1ValueTypeint,
        UnlockDesc = ValueTypestring,
        SkillId = Type1ValueTypeint,
        Priority = ValueTypeint,
        Medal3D = ValueTypestring,
        MedalImg = ValueTypestring,
        MedalIcon = ValueTypestring,
        MedalEffect = ValueTypestring,
        MedalHeadframe = ValueTypestring,
        KeepTime = ValueTypeint,
    },
    XTableMemorySaveActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ActivityName = ValueTypestring,
        ActivityBanner = ValueTypestring,
        ChapterIds = Type1ValueTypeint,
    },
    XTableMemorySaveChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ChapterName = ValueTypestring,
        ChapterBtnName = ValueTypestring,
        ChapterBg = ValueTypestring,
        BtnChapterBg = ValueTypestring,
        BtnChapterIcon = ValueTypestring,
        StageShortName = ValueTypestring,
        StageLinePrefab = ValueTypestring,
        StageBg = ValueTypestring,
        RewardIds = Type1ValueTypeint,
        RequirePass = Type1ValueTypeint,
        StageIds = Type1ValueTypeint,
    },
    XTableMemorySaveTreasure = {
        TreasureId = ValueTypeintPrimaryKey,
        RequirePass = ValueTypeint,
    },
    XTableMentorConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Value = ValueTypeint,
    },
    XTableMentorSystemTask = {
        Id = ValueTypeint,
        TaskId = ValueTypeint,
        Weight = ValueTypeint,
        Lv = ValueTypeint,
    },
    XTableMentorTag = {
        Id = ValueTypeintPrimaryKey,
        Tab = ValueTypestring,
        Order = ValueTypeint,
        Bg = ValueTypestring,
    },
    XTableMineSweepingActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        CoinItemId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
    },
    XTableMineSweepingChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        NameEn = ValueTypestring,
        ActivityStageIds = Type1ValueTypeint,
        ShowActivityStageIds = Type1ValueTypeint,
        CompleteStoryId = ValueTypestring,
        CompletePicture = ValueTypestring,
        AllMinePicture = ValueTypestring,
        MineEffect = ValueTypestring,
        WinGridEffect = ValueTypestring,
        MineIcon = ValueTypestring,
    },
    XTableMineSweepingMine = {
        Id = ValueTypeint,
        ActivityStageId = ValueTypeint,
        ColumnIndexes = Type1ValueTypeint,
    },
    XTableMineSweepingStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        WinEffect = ValueTypestring,
        CostCoinNum = ValueTypeint,
        RowCount = ValueTypeint,
        ColumnCount = ValueTypeint,
        RewardId = ValueTypeint,
        CanFailedCounts = Type1ValueTypeint,
    },
    XTableModel = {
        Id = ValueTypestringPrimaryKey,
        ModelPath = ValueTypestring,
        LowModelPath = ValueTypestring,
        HXModelPath = ValueTypestring,
        LowHXModelPath = ValueTypestring,
        ControllerPath = ValueTypestring,
        DisplayControllerPath = ValueTypestring,
        UiDefaultAnimationPath = ValueTypestring,
        LevelControllerPath = Type1ValueTypestring,
    },
    XTableMoeRankGroup = {
        RankType = ValueTypeintPrimaryKey,
        TagName = ValueTypestring,
        HasSub = ValueTypebool,
        IsSub = ValueTypebool,
        Title = ValueTypestring,
        ResetTip = ValueTypestring,
    },
    XTableMoeWarActivity = {
        Id = ValueTypeintPrimaryKey,
        ActivityTimeId = ValueTypeint,
        GroupName = Type1ValueTypestring,
        CurrencyId = Type1ValueTypeint,
        GroupSecondName = Type1ValueTypestring,
        Name = ValueTypestring,
        Background = ValueTypestring,
        ShopIds = Type1ValueTypeint,
    },
    XTableMoeWarActivityConfig = {
        Id = ValueTypeintPrimaryKey,
        GachaSkipId = ValueTypeint,
        ShowItem = Type1ValueTypeint,
        RewardSkipId = ValueTypeint,
        WebUrl = ValueTypestring,
        BeginStoryId = ValueTypestring,
        MainHelpId = ValueTypeint,
        VoteHelpId = ValueTypeint,
    },
    XTableMoeWarAnimation = {
        Id = ValueTypeintPrimaryKey,
        ModelName = ValueTypestring,
        Speed = ValueTypefloat,
        Distance = ValueTypefloat,
        AnimName = ValueTypestring,
        RoleEffect = ValueTypestring,
        RoleEffectRoot = ValueTypestring,
        SceneEffect = ValueTypestring,
        SceneEffectRoot = ValueTypestring,
    },
    XTableMoeWarAnimationGroup = {
        Id = ValueTypeintPrimaryKey,
        InitModelName = ValueTypestring,
        InitAnim = ValueTypestring,
        AnimationId = Type1ValueTypeint,
    },
    XTableMoeWarCharacterMood = {
        Id = ValueTypeintPrimaryKey,
        MoodMinValue = ValueTypeint,
        Color = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableMoeWarIconConfig = {
        Id = ValueTypeintPrimaryKey,
        IconList = Type1ValueTypestring,
    },
    XTableMoeWarInitPair = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        RankMatch = Type1ValueTypeint,
        WarSituationType = ValueTypeint,
    },
    XTableMoeWarMail = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        MailId = ValueTypeint,
        MatchId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableMoeWarMatch = {
        Id = ValueTypeintPrimaryKey,
        MatchName = ValueTypestring,
        MatchSubName = ValueTypestring,
        SessionId = ValueTypeint,
        Type = ValueTypeint,
        TypeName = ValueTypestring,
        TimeId = ValueTypeint,
        RefreshVoteHour = Type1ValueTypeint,
        CoverImg = ValueTypestring,
        Des = Type1ValueTypestring,
        DailyLimitCount = ValueTypeint,
        FinalImg = ValueTypestring,
    },
    XTableMoeWarMoeWarNameplateConfig = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        NameplateId = Type1ValueTypeint,
    },
    XTableMoeWarNameplateStore = {
        NameplateId = ValueTypeintPrimaryKey,
        PreNameplateId = ValueTypeint,
        CostItemId = ValueTypeint,
        CostItemCount = ValueTypeint,
        ItemName = ValueTypestring,
    },
    XTableMoeWarParkourActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        RewardId = ValueTypeint,
        DailyMaxReward = ValueTypeint,
        TeachStageId = ValueTypeint,
        StageId = Type1ValueTypeint,
    },
    XTableMoeWarParkourStage = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ItemDistanceParam = ValueTypeint,
        ItemScoreParam = ValueTypeint,
        MoodDistanceParam = ValueTypeint,
        MaxItemCount = ValueTypeint,
        MaxMoodCount = ValueTypeint,
    },
    XTableMoeWarPlayer = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
    },
    XTableMoeWarPlayerLocal = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ModelName = ValueTypestring,
        CareerName = ValueTypestring,
        CareerIcon = ValueTypestring,
        CampName = ValueTypestring,
        Description = ValueTypestring,
        IntroAnim = Type1ValueTypestring,
        IntroCv = ValueTypeint,
        IntroLength = Type1ValueTypefloat,
        ThankAnim = Type1ValueTypestring,
        ThankCv = ValueTypeint,
        ThankLength = Type1ValueTypefloat,
        SquareHead = ValueTypestring,
        CircleHead = ValueTypestring,
        ActionBg = ValueTypestring,
        BigCharacterImage = ValueTypestring,
        ShareImg = ValueTypestring,
        WinAnimGroupId = Type1ValueTypeint,
        LoseAnimGroupId = Type1ValueTypeint,
    },
    XTableMoeWarPreparationActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MatchIds = Type1ValueTypeint,
        InitStageCount = ValueTypeint,
        MaxStageCount = ValueTypeint,
        StageRecoveryTime = ValueTypeint,
        CommunicateItemId = ValueTypeint,
        PreparationGears = Type1ValueTypeint,
        Name = ValueTypestring,
        RedminNum = ValueTypeint,
        GiftAmount = ValueTypeint,
    },
    XTableMoeWarPreparationAssistance = {
        EffectId = ValueTypeintPrimaryKey,
        VoteItemId = ValueTypeint,
        VoteItemCount = ValueTypeint,
        Level = ValueTypeint,
        Order = ValueTypeint,
        EffectType = ValueTypeint,
        Param = ValueTypeint,
        IsShowInList = ValueTypeint,
        Desc = ValueTypestring,
        Title = ValueTypestring,
    },
    XTableMoeWarPreparationGear = {
        Id = ValueTypeintPrimaryKey,
        NeedCount = ValueTypeint,
        RewardId = ValueTypeint,
        ShowRewardId = ValueTypeint,
    },
    XTableMoeWarPreparationHelper = {
        Id = ValueTypeintPrimaryKey,
        RobotId = ValueTypeint,
        Order = ValueTypeint,
        LabelIds = Type1ValueTypeint,
        QuestionBankIds = Type1ValueTypeint,
        QuestionCounts = Type1ValueTypeint,
        CommunicateItemId = ValueTypeint,
        CommunicateConsumeCount = ValueTypeint,
        CirleIcon = ValueTypestring,
        DefaultLock = ValueTypeint,
        MoodUpLimit = ValueTypeint,
        GiftRecoveryMood = ValueTypeint,
        ThankId = ValueTypeint,
    },
    XTableMoeWarPreparationMatch = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        HelperIds = Type1ValueTypeint,
        StageIds = Type1ValueTypeint,
        NumText = ValueTypestring,
    },
    XTableMoeWarPreparationQuestion = {
        Id = ValueTypeintPrimaryKey,
        BankId = ValueTypeint,
        HelperId = ValueTypeint,
        Type = ValueTypeint,
        Chat = ValueTypestring,
        ChatReply = ValueTypestring,
        PreChatId = ValueTypeint,
        Weight = ValueTypeint,
        Question = ValueTypestring,
        RightAnswer = ValueTypeint,
        Answers = Type2KeyTypeintValueTypestring,
        RightReply = ValueTypestring,
        WrongReply = ValueTypestring,
        HelperIcon = ValueTypestring,
        HelperName = ValueTypestring,
    },
    XTableMoeWarPreparationStage = {
        StageId = ValueTypeintPrimaryKey,
        NormalWeight = ValueTypeint,
        Weights = Type1ValueTypeint,
        LabelIds = Type1ValueTypeint,
        BestHelperFightEventId = ValueTypeint,
        BaseRewardId = ValueTypeint,
        ShowBaseRewardId = ValueTypeint,
        ExtraRewardIds = Type1ValueTypeint,
        ShowExtraRewardIds = Type1ValueTypeint,
        ShowSpecialRewardId = ValueTypeint,
        ShowAllRewardId = ValueTypeint,
        BaseCostMoodNum = ValueTypeint,
        LabelCostMoodNums = Type1ValueTypeint,
    },
    XTableMoeWarPreparationStageEvaluationLabel = {
        ReachNum = ValueTypeintPrimaryKey,
        EvaluatioLabel = ValueTypestring,
    },
    XTableMoeWarPreparationStageTagLabel = {
        Id = ValueTypeintPrimaryKey,
        TagLabel = ValueTypestring,
    },
    XTableMoeWarScheduleTabGroup = {
        Id = ValueTypeintPrimaryKey,
        BtnType = ValueTypeint,
        Name = ValueTypestring,
        SecondName = ValueTypestring,
        SessionId = ValueTypeint,
        ParentIndex = ValueTypeint,
        IsShowGroupTab = ValueTypeint,
        IsShowModel = ValueTypeint,
    },
    XTableMoeWarTaskGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Group = ValueTypeint,
    },
    XTableMoeWarThank = {
        Id = ValueTypeintPrimaryKey,
        Text = ValueTypestring,
    },
    XTableMoeWarVoteItem = {
        ItemId = ValueTypeint,
        Multiple = ValueTypeint,
        VoteFactor = ValueTypefloat,
        CoinFactor = ValueTypefloat,
        CoinItemId = ValueTypeint,
        IsLimit = ValueTypeint,
        MatchId = Type1ValueTypeint,
        DailyLimitCount = Type1ValueTypeint,
        FailGroupDailyLimitCount = Type1ValueTypeint,
        No = ValueTypeintPrimaryKey,
        GainItemId = ValueTypeint,
        GainItemCount = ValueTypeint,
    },
    XTableMoive = {
        Id = ValueTypestringPrimaryKey,
        Name = ValueTypestring,
        AssetUrl = ValueTypestring,
    },
    XTableMonsterCombatActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        ChapterIds = Type1ValueTypeint,
        TimeLimitTaskId = ValueTypeint,
        MonsterCostLimit = ValueTypeint,
        MonsterCountLimit = ValueTypeint,
        HelpId = ValueTypeint,
    },
    XTableMonsterCombatBuff = {
        MonsterId = ValueTypeintPrimaryKey,
        CharacterIds = Type1ValueTypeint,
        FightEventId = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableMonsterCombatChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        Type = ValueTypeint,
        PreChapterId = ValueTypeint,
        UnlockMonsterIds = Type1ValueTypeint,
        StageIds = Type1ValueTypeint,
        LimitMonsters = Type1ValueTypeint,
        LimitRobotIds = Type1ValueTypeint,
    },
    XTableMonsterCombatChapterDetail = {
        Id = ValueTypeintPrimaryKey,
        Description = ValueTypestring,
        PrefabName = ValueTypestring,
        BgIcon = ValueTypestring,
    },
    XTableMonsterCombatConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableMonsterCombatMonster = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Cost = ValueTypeint,
        FightEventId = ValueTypeint,
        FightEventLevel = ValueTypeint,
        Order = ValueTypeint,
    },
    XTableMonsterCombatMonsterDetail = {
        Id = ValueTypeintPrimaryKey,
        FightTime = ValueTypeint,
        Description = ValueTypestring,
        UiModelId = ValueTypestring,
        Icon = ValueTypestring,
        AchieveIcon = ValueTypestring,
        ActiveSkillName = ValueTypestring,
        ActiveSkillDesc = ValueTypestring,
        ActiveSkillCooling = ValueTypeint,
        PassiveSkillName = ValueTypestring,
        PassiveSkillDesc = ValueTypestring,
        UnlockConditionDesc = ValueTypestring,
    },
    XTableMonsterCombatStage = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        UnlockMonsterIds = Type1ValueTypeint,
        ScoreParams = Type1ValueTypeint,
        ScoreLimit = ValueTypeint,
        RecommendMonsters = Type1ValueTypeint,
    },
    XTableMonsterCombatStageDetail = {
        Id = ValueTypeintPrimaryKey,
        Description = Type1ValueTypestring,
    },
    XTableMonsterEffect = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        NpcState = ValueTypeint,
        EffectNodeName = ValueTypestring,
        EffectPath = ValueTypestring,
    },
    XTableMonsterInfoInner = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Text = ValueTypestring,
    },
    XTableMonsterNpcData = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ModelId = Type1ValueTypestring,
    },
    XTableMonsterSetting = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Order = ValueTypeint,
        Type = ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableMonsterSettingInner = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Text = ValueTypestring,
    },
    XTableMouthData = {
        Id = ValueTypeintPrimaryKey,
        CvId = ValueTypeint,
        Msec = ValueTypeint,
        A = ValueTypefloat,
        I = ValueTypefloat,
        U = ValueTypefloat,
        E = ValueTypefloat,
        O = ValueTypefloat,
    },
    XTableMovementSound = {
        Id = ValueTypeint,
        CharacterId = ValueTypestring,
        Motion = ValueTypestring,
        SoundId = ValueTypeint,
    },
    XTableMovieActor = {
        RoleId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        RoleIcon = ValueTypestring,
        Race = ValueTypestring,
        Age = ValueTypeint,
        Height = ValueTypeint,
        Weight = ValueTypeint,
        Wepon = ValueTypestring,
        Team = ValueTypestring,
        FacePosX = ValueTypefloat,
        FacePosY = ValueTypefloat,
        AvatarPosX = ValueTypefloat,
        AvatarPosY = ValueTypefloat,
        AvatarPosZ = ValueTypefloat,
        AvatarScale = ValueTypefloat,
    },
    XTableMovieAssemble = {
        Id = ValueTypeintPrimaryKey,
        BgImgUrl = ValueTypestring,
        UiPrefab = ValueTypestring,
        MovieTmpPrefab = ValueTypestring,
        MovieTmpIds = Type1ValueTypeint,
    },
    XTableMovieAssembleTemplate = {
        Id = ValueTypeintPrimaryKey,
        MovieId = ValueTypestring,
        ConditionId = ValueTypeint,
        LockedBgUrl = ValueTypestring,
        UnlockBgUrl = ValueTypestring,
    },
    XTableMovieAudioLip = {
        CueId = ValueTypeintPrimaryKey,
        Times = Type1ValueTypefloat,
        Lips = Type1ValueTypestring,
    },
    XTableMovieClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Note = ValueTypestring,
        Params = Type1ValueTypestring,
    },
    XTableMovieKeyword = {
        Id = ValueTypeintPrimaryKey,
        KuroTerm = ValueTypestring,
        MovieId = ValueTypestring,
        Interpretation = ValueTypestring,
    },
    XTableMovieNew = {
        Id = ValueTypeintPrimaryKey,
        ActionId = ValueTypeint,
        NextActionId = ValueTypeint,
        Type = ValueTypeint,
        IsBlock = ValueTypeint,
        IsEnd = ValueTypeint,
        BeginAnim = ValueTypestring,
        EndAnim = ValueTypestring,
        BeginDelay = ValueTypefloat,
        EndDelay = ValueTypefloat,
        Params = Type2KeyTypeintValueTypestring,
    },
    XTableMovieRecordOptions = {
        Id = ValueTypestringPrimaryKey,
        IsDrop = ValueTypeint,
        Options = Type1ValueTypeint,
    },
    XTableMovieRoleFace = {
        RoleId = ValueTypeintPrimaryKey,
        FaceLook = Type1ValueTypestring,
    },
    XTableMovieSkip = {
        Id = ValueTypestring,
        SkipDesc = ValueTypestring,
    },
    XTableMovieSkipSummary = {
        StoryId = ValueTypestringPrimaryKey,
        Title = ValueTypestring,
        SummaryContent = ValueTypestring,
    },
    XTableMovieSpeed = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Speed = ValueTypeint,
    },
    XTableMovieSpineActor = {
        RoleId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SpinePath = ValueTypestring,
        RoleAnims = Type1ValueTypestring,
        RoleAnims2 = Type2KeyTypeintValueTypestring,
        KouIdleAnims = Type1ValueTypestring,
        KouTalkAnims = Type1ValueTypestring,
        TransitionAnims = Type2KeyTypeintValueTypestring,
    },
    XTableMovieSpineActorV2 = {
        RoleId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableMovieStaff = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableMultiChallengeStage = {
        Id = ValueTypeintPrimaryKey,
        ConsumeId = Type1ValueTypeint,
        ConsumeNum = Type1ValueTypeint,
        MultiChallengeMin = ValueTypeint,
        MultiChallengeMax = ValueTypeint,
    },
    XTableMultiDimActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableMultiDimActivityDetail = {
        Id = ValueTypeintPrimaryKey,
        TaskGroupId = Type1ValueTypeint,
        ItemId = ValueTypeint,
        BannerBg = ValueTypestring,
        TaskGroupName = Type1ValueTypestring,
    },
    XTableMultiDimBuffDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BuffBg = ValueTypestring,
        BuffTriangleBg = ValueTypestring,
        Desc = ValueTypestring,
        TeachingContents = Type1ValueTypestring,
        BuffSuggestAbility = ValueTypeint,
    },
    XTableMultiDimCareer = {
        Career = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        IconTranspose = ValueTypestring,
        Des = ValueTypestring,
        Name = ValueTypestring,
        SortId = ValueTypeint,
        FilterCareer = Type1ValueTypeint,
    },
    XTableMultiDimCharacterCareer = {
        Id = ValueTypeintPrimaryKey,
        Career = ValueTypeint,
    },
    XTableMultiDimConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Value = ValueTypestring,
    },
    XTableMultiDimDifficulty = {
        Id = ValueTypeintPrimaryKey,
        ThemeId = ValueTypeint,
        DifficultyId = ValueTypeint,
        StageId = ValueTypeint,
        ExtraStageIds = Type1ValueTypeint,
        FightAbility = ValueTypeint,
        DifficultyFirstPassReward = ValueTypeint,
        DifficultyFactor = ValueTypefloat,
        RateFactor = ValueTypefloat,
        ThemeFactor = ValueTypefloat,
        DamageRankPoints = Type1ValueTypefloat,
        IsOnRank = ValueTypeint,
        RecommendClass = Type1ValueTypeint,
        FightEventId = Type1ValueTypeint,
        BaseBuffId = Type1ValueTypeint,
    },
    XTableMultiDimDifficultyDetail = {
        Id = ValueTypeintPrimaryKey,
        ThemeId = ValueTypeint,
        DifficultyId = ValueTypeint,
        Name = ValueTypestring,
        Color = ValueTypestring,
        Description = ValueTypestring,
        IsLimitShow = ValueTypeint,
    },
    XTableMultiDimRankReward = {
        Id = ValueTypeintPrimaryKey,
        ThemeId = ValueTypeint,
        Percent = ValueTypeint,
        RewardId = ValueTypeint,
        MailId = ValueTypeint,
        MinRank = ValueTypeint,
        MaxRank = ValueTypeint,
    },
    XTableMultiDimSingleFuben = {
        Id = ValueTypeintPrimaryKey,
        ThemeId = ValueTypeint,
        StageId = ValueTypeint,
        OpenTimeId = ValueTypeint,
        RewardId = Type1ValueTypeint,
        RewardDes = ValueTypestring,
        BaseBuffId = Type1ValueTypeint,
    },
    XTableMultiDimTalent = {
        Id = ValueTypeintPrimaryKey,
        ClassId = ValueTypeint,
        TalentType = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Level = ValueTypeint,
        UseOwn = ValueTypeint,
        CostItemId = ValueTypeint,
        CostItemCount = ValueTypeint,
        FightEventId = Type1ValueTypeint,
    },
    XTableMultiDimTalentDetail = {
        Id = ValueTypeintPrimaryKey,
        ClassId = ValueTypeint,
        TalentType = ValueTypeint,
        Level = ValueTypeint,
        NextLevel = ValueTypeint,
        IsHighLevel = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableMultiDimTheme = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        ThemeFirstPassTimeId = ValueTypeint,
        ThemeDailyFirstPassRewardId = ValueTypeint,
        MatchConditionId = ValueTypeint,
    },
    XTableMultiDimThemeDetail = {
        Id = ValueTypeintPrimaryKey,
        ModelId = ValueTypestring,
        StagePrefix = ValueTypestring,
        FubenSingleMainBg = ValueTypestring,
        FubenSingleEffectUrl = ValueTypestring,
        FubenSinglePrefab = ValueTypestring,
        GridFubenSinglePrefab = ValueTypestring,
        ModelScale = ValueTypefloat,
    },
    XTableMultiplayerCurrencyConfig = {
        Day = ValueTypeintPrimaryKey,
        MaxLimit = ValueTypeint,
    },
    XTableMuralShareActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        RewardId = ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTableMuralSharePainting = {
        Id = ValueTypeintPrimaryKey,
        Price = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Width = ValueTypeint,
        Height = ValueTypeint,
        DefaultScale = ValueTypefloat,
    },
    XTableMuralShareReward = {
        Id = ValueTypeintPrimaryKey,
        PaintingNum = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableMusicGameActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        ArrangementUseItemCount = ValueTypeint,
        RhythmGameControlId = ValueTypeint,
        ArrangementGameControlId = ValueTypeint,
        TaskGroupIds = Type1ValueTypeint,
    },
    XTableMusicPlayerAlbum = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Composer = ValueTypestring,
        Cover = ValueTypestring,
        Bg = ValueTypestring,
        CueId = ValueTypeint,
        Priority = ValueTypeint,
        ConditionId = ValueTypeint,
        ExperienceTimeId = ValueTypeint,
        IsDisable = ValueTypebool,
        ComposeBrief = ValueTypestring,
        SkipId = ValueTypeint,
        EggText = ValueTypestring,
    },
    XTableMusicPlayerColorStyleRes = {
        ColorType = ValueTypestringPrimaryKey,
        BgmListBtnSprite = ValueTypestring,
        PlayMusicBtnSprite = ValueTypestring,
        StopMusicBtnSprite = ValueTypestring,
        ListCellSelectedBgSprite = ValueTypestring,
        MusicCurve = ValueTypestring,
        MusicCurve2 = ValueTypestring,
        MusicCurve4 = ValueTypestring,
        MusicHuan = ValueTypestring,
        MusicHuan02 = ValueTypestring,
        MusicHuan04 = ValueTypestring,
        MusicGongxing = ValueTypestring,
        Sanjiao2 = ValueTypestring,
    },
    XTableMusicScene = {
        Id = ValueTypeintPrimaryKey,
        MusicId = ValueTypeint,
        LoopCueId = ValueTypeint,
        ToNormalAnim = ValueTypestring,
        NormalAnim = ValueTypestring,
        ToMusicAnim = ValueTypestring,
        MusicAnim = ValueTypestring,
        ClickPrefab = ValueTypestring,
        AnimSwitchTime = ValueTypeint,
    },
    XTableMusicSceneClientConfig = {
        Id = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableNameplate = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypeint,
        Title = ValueTypeint,
        NameplateQuality = ValueTypeint,
        Group = ValueTypeint,
        Description = ValueTypeint,
        Hint = Type1ValueTypeint,
        NameplateGetWay = ValueTypeint,
        NameplateUpgradeType = ValueTypeint,
        Params = Type1ValueTypeint,
        DecomposeExp = ValueTypeint,
        UpgradeExp = ValueTypeint,
        ConvertItemId = ValueTypeint,
        ConvertItemCount = ValueTypeint,
        ExpireTimeStr = ValueTypestring,
        Duration = ValueTypeint,
        PlusTime = ValueTypeint,
        IconType = ValueTypeint,
        Icon = ValueTypestring,
        BackBoard = ValueTypestring,
        OutLineColor = ValueTypestring,
        QualityIcon = ValueTypestring,
        EffectRes = ValueTypestring,
        IsNewTextureIcon = ValueTypeint,
    },
    XTableNameplateContentMap = {
        Id = ValueTypeintPrimaryKey,
        Text = ValueTypestring,
    },
    XTableNetworkState = {
        Id = ValueTypeintPrimaryKey,
        DelayUpLimit = ValueTypeint,
    },
    XTableNewActivityCalendarActivity = {
        ActivityId = ValueTypeintPrimaryKey,
        MainTimeId = ValueTypeint,
        MainTemplateId = Type1ValueTypeint,
        MainTemplateCount = Type1ValueTypeint,
        TaskSourceGroupId = ValueTypeint,
        ShopId = Type1ValueTypeint,
        EventCause = Type1ValueTypeint,
        ExtraItem = Type1ValueTypeint,
        PeriodId = Type1ValueTypeint,
        Name = ValueTypestring,
        Kind = Type1ValueTypeint,
        IsMajorActivity = ValueTypeint,
        SkipId = ValueTypeint,
        ActivityIcon = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableNewActivityCalendarClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableNewActivityCalendarKind = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BgColor = ValueTypestring,
    },
    XTableNewActivityCalendarPeriod = {
        PeriodId = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MainTemplateId = Type1ValueTypeint,
        MainTemplateCount = Type1ValueTypeint,
    },
    XTableNewActivityCalendarWeekActivity = {
        MainId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Kind = Type1ValueTypeint,
        IsMajorActivity = ValueTypeint,
        SkipId = ValueTypeint,
        ActivityIcon = ValueTypestring,
        Description = ValueTypestring,
        SortId = ValueTypeint,
        RefreshTime = ValueTypestring,
    },
    XTableNewActivityCalendarWeekReward = {
        Id = ValueTypeintPrimaryKey,
        MainId = ValueTypeint,
        SubId = ValueTypeint,
        MainTemplateId = Type1ValueTypeint,
        MainTemplateCount = Type1ValueTypeint,
        TaskSourceGroupId = ValueTypeint,
        ShopId = Type1ValueTypeint,
        EventCause = Type1ValueTypeint,
        ExtraItem = Type1ValueTypeint,
    },
    XTableNewbieTaskGroup = {
        Id = ValueTypeintPrimaryKey,
        RegisterDay = ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTableNewPlayerTaskGroup = {
        Id = ValueTypeintPrimaryKey,
        OpenDay = ValueTypeint,
        FirstTalk = ValueTypestring,
        TaskId = Type1ValueTypeint,
    },
    XTableNewPlayerTaskTalk = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        StoryId = ValueTypestring,
        SpellName = ValueTypestring,
        RoleHalfIcon = ValueTypestring,
        ShowCharId = ValueTypeint,
        GetCount = Type1ValueTypeint,
        TalkContent = Type1ValueTypestring,
    },
    XTableNewYearLuckActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        OpenPrizeTimeId = ValueTypeint,
        BannerBg = ValueTypestring,
        Name = ValueTypestring,
        NameEn = ValueTypestring,
        UseItem = ValueTypeint,
        MailId = ValueTypeint,
        ConvertCoinRewardId = ValueTypeint,
        CoinMailId = ValueTypeint,
        NormalUnlockMax = ValueTypeint,
        SpecialUnlockMax = ValueTypeint,
        NormalTicketPrices = Type1ValueTypeint,
        SpecialTicketPrices = Type1ValueTypeint,
    },
    XTableNewYearLuckLevel = {
        Id = ValueTypeintPrimaryKey,
        RewardLevel = ValueTypestring,
        ActivityId = ValueTypeint,
        GroupType = ValueTypeint,
        RewardId = ValueTypeint,
        ProbabilityOfWinning = ValueTypestring,
        AnnounceTitle = ValueTypestring,
        LuckNums = Type1ValueTypeint,
    },
    XTableNieRAbilityGroup = {
        Id = ValueTypeintPrimaryKey,
        AbilityGroupId = ValueTypeint,
        Condition = ValueTypeint,
        SkillId = ValueTypeint,
        SkillLevel = ValueTypeint,
        FashionId = ValueTypeint,
        WeaponId = ValueTypeint,
        WeaponAweken = ValueTypeint,
        WeaponBreakThrough = ValueTypeint,
        WaferId = Type1ValueTypeint,
        WaferAweken = Type1ValueTypeint,
        WaferBreakThrough = Type1ValueTypeint,
        Priority = ValueTypeint,
        TitleStr = ValueTypestring,
    },
    XTableNieRActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        SupportId = ValueTypeint,
        RepeatableConsumeId = ValueTypeint,
        RepeatableConsumeInitCount = ValueTypeint,
        RepeatableConsumeDailyAdd = ValueTypeint,
        RepeatableConsumeMaxCount = ValueTypeint,
        BannerBg = ValueTypestring,
        ChapterIds = Type1ValueTypeint,
        RepeatableStageIds = Type1ValueTypeint,
        DevelopCharacterIds = Type1ValueTypeint,
        ShopIds = Type1ValueTypeint,
        TaskGroupIds = Type1ValueTypeint,
        EasterEggStageId = ValueTypeint,
        EasterEggRewardId = ValueTypeint,
        EasterEggMinAge = ValueTypeint,
        EasterEggMaxAge = ValueTypeint,
        MaxEasterEggMessageCount = ValueTypeint,
    },
    XTableNieRBossScoreRule = {
        Id = ValueTypeint,
        BaseScore = ValueTypeint,
        DamageScore = ValueTypefloat,
        CharacterLeftHpScore = ValueTypefloat,
        MaxCharacterLeftHpScore = ValueTypeint,
        ScoreHpRatio = ValueTypefloat,
    },
    XTableNieRChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Condition = ValueTypeint,
        BossStageId = ValueTypeint,
        BossHp = ValueTypeint,
        BossScoreRuleId = ValueTypeint,
        TaskSkipId = ValueTypeint,
        RepeatPoStagePos = ValueTypeint,
        RobotIds = Type1ValueTypeint,
        StageIds = Type1ValueTypeint,
        Icon = ValueTypestring,
        Title = ValueTypestring,
        RepeatPoStageLabel = ValueTypestring,
    },
    XTableNieRCharacter = {
        Id = ValueTypeint,
        CharacterId = ValueTypeintPrimaryKey,
        InitLevel = ValueTypeint,
        Condition = ValueTypeint,
        AbilityGroupId = ValueTypeint,
        EasterEggFightTag = ValueTypeint,
        TeachingStageIds = Type1ValueTypeint,
    },
    XTableNieRCharacterClient = {
        CharacterId = ValueTypeintPrimaryKey,
        UpLevelItem = ValueTypeint,
        Pos = ValueTypeint,
        SkipId = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableNieRCharacterInformation = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        UnlockCondition = ValueTypeint,
        Priority = ValueTypeint,
        Title = ValueTypestring,
        Content = ValueTypestring,
        DescEx = ValueTypestring,
    },
    XTableNieRCharacterLevel = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Level = ValueTypeint,
        RobotId = ValueTypeint,
        MaxExp = ValueTypeint,
        WeaponLevel = ValueTypeint,
        WaferLevel = ValueTypeint,
    },
    XTableNieREasterEggClient = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Type = ValueTypeint,
        ShowBullet = ValueTypeint,
        Desc = ValueTypestring,
        BtnExStr = ValueTypestring,
        BtnStr = Type1ValueTypestring,
        BtnTag = Type1ValueTypeint,
    },
    XTableNieREasterEggInitMessage = {
        Id = ValueTypeintPrimaryKey,
        PlayerName = ValueTypestring,
        MessageId = ValueTypeint,
        Age = ValueTypeint,
        LabelId = ValueTypeint,
    },
    XTableNieREasterEggLabel = {
        Id = ValueTypeintPrimaryKey,
        Label = ValueTypestring,
    },
    XTableNieREasterEggMessage = {
        Id = ValueTypeintPrimaryKey,
        Message = ValueTypestring,
    },
    XTableNieRRepeatableStage = {
        RepeatableStageId = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
        ConsumeCount = ValueTypeint,
        NormalReward = ValueTypeint,
        TaskSkipId = ValueTypeint,
        StarRewards = Type1ValueTypeint,
        ExStageIds = Type1ValueTypeint,
        ExStageConditions = Type1ValueTypeint,
        ExConsumeIds = Type1ValueTypeint,
        ExConsumeCounts = Type1ValueTypeint,
        RobotIds = Type1ValueTypeint,
    },
    XTableNieRRepeatableStageClient = {
        StageId = ValueTypeintPrimaryKey,
        RewardIcon = ValueTypestring,
        RewardTitle = ValueTypestring,
        RewardQuality = ValueTypeint,
    },
    XTableNieRShopClient = {
        ShopId = ValueTypeintPrimaryKey,
        BtnName = ValueTypestring,
        ShopBg = ValueTypestring,
        ShopItemBg = ValueTypestring,
        ShopIcon = ValueTypestring,
    },
    XTableNieRSupport = {
        SupportId = ValueTypeintPrimaryKey,
        SkillIds = Type1ValueTypeint,
        SkillPassiveFlags = Type1ValueTypeint,
        SkillConditions = Type1ValueTypeint,
    },
    XTableNieRSupportClient = {
        SupportId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        UpLevelItem = ValueTypeint,
        UpSkillLevelItem = ValueTypeint,
    },
    XTableNieRSupportLevel = {
        Id = ValueTypeintPrimaryKey,
        SupportId = ValueTypeint,
        Level = ValueTypeint,
        MaxExp = ValueTypeint,
        Icon = ValueTypestring,
        HeadIcon = ValueTypestring,
        HeadBigIcon = ValueTypestring,
        Model = ValueTypestring,
    },
    XTableNieRSupportSkillClient = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Level = ValueTypeint,
        Desc = ValueTypestring,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableNieRSupportSkillLevel = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Level = ValueTypeint,
        FightEventId = ValueTypeint,
        UpgradeCondition = ValueTypeint,
        UpgradeConsumeId = ValueTypeint,
        UpgradeConsumeCount = ValueTypeint,
    },
    XTableNieRTask = {
        TaskGroupId = ValueTypeintPrimaryKey,
        TitleStr = ValueTypestring,
        Priority = ValueTypeint,
        EasterEggTask = ValueTypeint,
    },
    XTableNonogramActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
    },
    XTableNonogramChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        StageGroupIds = Type1ValueTypeint,
        PreChapterId = ValueTypeint,
        UnlockItemNum = ValueTypeint,
        UnlockCgItemId = ValueTypeint,
        UnlockCgItemNum = ValueTypeint,
        CgRewardId = ValueTypeint,
        TimeLimit = ValueTypeint,
        DeductTime = ValueTypeint,
        IsRebrush = ValueTypebool,
    },
    XTableNonogramChapterClient = {
        Id = ValueTypeintPrimaryKey,
        BtnChapterImagePath = ValueTypestring,
        CGTexturePath = ValueTypestring,
        CGDetail = ValueTypestring,
        PlayTips = ValueTypestring,
        ShowTipCD = ValueTypeint,
        ShowTipErrorHitTimes = ValueTypeint,
    },
    XTableNonogramGrid = {
        Id = ValueTypeintPrimaryKey,
        TemplateId = ValueTypeint,
        LineIndex = ValueTypeint,
        Values = Type1ValueTypeint,
    },
    XTableNonogramStage = {
        Id = ValueTypeintPrimaryKey,
        RewardId = ValueTypeint,
        GridTemplateId = ValueTypeint,
        FirstTipIndexStr = ValueTypestring,
    },
    XTableNonogramStageGroup = {
        Id = ValueTypeintPrimaryKey,
        StageIds = Type1ValueTypeint,
    },
    XTableNpc = {
        Id = ValueTypeintPrimaryKey,
        UiResId = ValueTypeint,
        Type = ValueTypeint,
        Kind = ValueTypeint,
        Name = ValueTypestring,
        Note = ValueTypestring,
        UseShadowMesh = ValueTypebool,
        ShadowQuadScale = ValueTypefloat,
        ModelId = ValueTypestring,
        ColliderType = ValueTypeint,
        PolygonId = ValueTypeint,
        BodyRadius = ValueTypefix,
        HitRadius = ValueTypefix,
        BaseHeight = ValueTypefloat,
        CameraCollideRadius = ValueTypefloat,
        MoveUseFaceDir = ValueTypebool,
        AttribId = ValueTypeint,
        AttribType = ValueTypeint,
        PromotedId = ValueTypeint,
        AttackSkillId = ValueTypeint,
        DodgeSkillId = ValueTypeint,
        ModelScale = ValueTypefloat,
        EffectScale = ValueTypefloat,
        MissileScale = ValueTypefix,
        OffsetScale = ValueTypefix,
        CatchType = ValueTypeint,
        BossHp = ValueTypebool,
        HpWdigetCount = ValueTypeint,
        HpWidgetHeight = ValueTypefloat,
        HpWidgetType = ValueTypeint,
        RollCharHeight = ValueTypefloat,
        HasRunTilt = ValueTypebool,
        HasSprintTilt = ValueTypebool,
        HasRunToStand = ValueTypebool,
        HasSprintToStand = ValueTypebool,
        HasRunStart = ValueTypebool,
        HasStandTransition = ValueTypebool,
        HasSquatState = ValueTypebool,
        HasSprintState = ValueTypebool,
        HasNeoWalk = ValueTypebool,
        HasSimpleJump = ValueTypebool,
        WalkMotionOffset = ValueTypebool,
        RunMotionOffset = ValueTypebool,
        SquatMotionOffset = ValueTypebool,
        SprintMotionOffset = ValueTypebool,
        BeHitInterval = ValueTypefix,
        LieOnFloorTime = ValueTypefix,
        StandUpImmuneHitTime = ValueTypefix,
        StandUpTailTime = ValueTypefix,
        IdleJumpToStand = ValueTypefix,
        RunJumpToStandTime = ValueTypefix,
        MaxHitValue = ValueTypeint,
        DeathTime = ValueTypefix,
        NoThreat = ValueTypebool,
        NotToThreatTarget = ValueTypebool,
        CollisionPriority = ValueTypeint,
        IgnoreCollisionToNpc = ValueTypebool,
        IgnoreCollisionFromNpc = ValueTypebool,
        ForceSqueezeOut = ValueTypebool,
        SqueezeSpeed = ValueTypefix,
        RobotBornMagic = Type1ValueTypeint,
        BornMagic = Type1ValueTypeint,
        DeathMagic = Type1ValueTypeint,
        SkillId = Type1ValueTypeint,
        Ball = ValueTypestring,
        RandomBall = ValueTypestring,
        ImmuneHitLevel = ValueTypeint,
        DisableMotionRotation = ValueTypebool,
        HitCaseHeight = ValueTypefix,
        NpcHeight = ValueTypefix,
        BeHitType = ValueTypeint,
        JumpHasAirDodge = ValueTypebool,
    },
    XTableNpcAttrib = {
        Id = ValueTypeintPrimaryKey,
        Life = ValueTypefix,
        Energy = ValueTypefix,
        RunSpeed = ValueTypefix,
        SprintSpeed = ValueTypefix,
        WalkSpeed = ValueTypefix,
        TurnRoundSpeed = ValueTypefix,
        BallInterval = ValueTypefix,
        DamageNormalImmunity = ValueTypefix,
        DamageMagicImmunity = ValueTypefix,
        AntiDamageNormalImmunity = ValueTypefix,
        AntiDamageMagicImmunity = ValueTypefix,
        AttackNormal = ValueTypefix,
        AttackMagic1 = ValueTypefix,
        AttackMagic2 = ValueTypefix,
        AttackMagic3 = ValueTypefix,
        AttackMagic4 = ValueTypefix,
        AttackMagic5 = ValueTypefix,
        AntiAttackNormal = ValueTypefix,
        AntiAttackMagic1 = ValueTypefix,
        AntiAttackMagic2 = ValueTypefix,
        AntiAttackMagic3 = ValueTypefix,
        AntiAttackMagic4 = ValueTypefix,
        AntiAttackMagic5 = ValueTypefix,
        DefenseNormal = ValueTypefix,
        AntiDefenseNormal = ValueTypefix,
        DamageChangeP = ValueTypefix,
        DamageNormalChangeP = ValueTypefix,
        DamageMagic1ChangeP = ValueTypefix,
        DamageMagic2ChangeP = ValueTypefix,
        DamageMagic3ChangeP = ValueTypefix,
        DamageMagic4ChangeP = ValueTypefix,
        DamageMagic5ChangeP = ValueTypefix,
        AntiDamageChangeP = ValueTypefix,
        AntiDamageNormalChangeP = ValueTypefix,
        AntiDamageMagic1ChangeP = ValueTypefix,
        AntiDamageMagic2ChangeP = ValueTypefix,
        AntiDamageMagic3ChangeP = ValueTypefix,
        AntiDamageMagic4ChangeP = ValueTypefix,
        AntiDamageMagic5ChangeP = ValueTypefix,
        DamagePBegin = ValueTypefix,
        Damage1P = ValueTypefix,
        Damage2P = ValueTypefix,
        Damage3P = ValueTypefix,
        DamagePEnd = ValueTypefix,
        Crit = ValueTypefix,
        CritP = ValueTypefix,
        CritDamageP = ValueTypefix,
        AntiCritP = ValueTypefix,
        AntiCritDamageP = ValueTypefix,
        Lifesteal = ValueTypefix,
        LifestealP = ValueTypefix,
        CureChangeP = ValueTypefix,
        AntiCureChangeP = ValueTypefix,
        Endure = ValueTypefix,
        ThreatRateP = ValueTypefix,
        DodgeEnergy = ValueTypefix,
        DodgeEnergyAutoRecovery = ValueTypefix,
        CustomEnergy = ValueTypefix,
        AccuResistance1 = ValueTypefix,
        AccuResistance2 = ValueTypefix,
        AccuResistance3 = ValueTypefix,
        AccuResistance4 = ValueTypefix,
        AccuResistance5 = ValueTypefix,
        AccuResistance6 = ValueTypefix,
        AccuResistance7 = ValueTypefix,
        AccuResistance8 = ValueTypefix,
        AccuResistance9 = ValueTypefix,
        AccuResistance10 = ValueTypefix,
        SquatSpeed = ValueTypefix,
        NormalWeaknessP = ValueTypefix,
        Magic1WeaknessP = ValueTypefix,
        Magic2WeaknessP = ValueTypefix,
        Magic3WeaknessP = ValueTypefix,
        Magic4WeaknessP = ValueTypefix,
        Magic5WeaknessP = ValueTypefix,
        CustomEnergyGroup1 = ValueTypefix,
        CustomEnergyGroup2 = ValueTypefix,
        CustomEnergyGroup3 = ValueTypefix,
        CustomEnergyGroup4 = ValueTypefix,
        Hack = ValueTypefix,
        HackChangeP = ValueTypefix,
        AntiHackChangeP = ValueTypefix,
        HackExecuteSkillTriggerP = ValueTypefix,
        SkillDamageChangeP = ValueTypefix,
        ReduceHackDynamicScoringCoe = ValueTypefix,
        BeExecutedDynamicScoringCoe = ValueTypefix,
        DynamicScoringScoreChangeP = ValueTypefix,
        DynamicScoringScoreChangeV = ValueTypefix,
        ReduceDynamicScoringScorePerSecondChangeP = ValueTypefix,
        ReduceDynamicScoringScorePerSecondChangeV = ValueTypefix,
        ReduceDynamicScoringScoreWhenBeDamagedChangeP = ValueTypefix,
        ReduceDynamicScoringScoreWhenBeDamagedChangeV = ValueTypefix,
        DamageAmplificationFactorP = ValueTypefix,
        BrokenProtectorHp = ValueTypefix,
        BrokenProtectorHpChangeP = ValueTypefix,
        AntiBrokenProtectorHpChangeP = ValueTypefix,
        AllMagicDamageChangeP = ValueTypefix,
        AllMagicAntiChangeP = ValueTypefix,
        ProtectorHp = ValueTypefix,
        BurnDamageExtraP = ValueTypefix,
        AntiBurnDamageP = ValueTypefix,
        SwordPowerDamageP = ValueTypefix,
        SwordPowerDamageExtraP = ValueTypefix,
        AntiSwordPowerP = ValueTypefix,
        SwordPowerWeaknessP = ValueTypefix,
        SkillAccumulatorP = ValueTypefix,
        BurnAccumulatorP = ValueTypefix,
        BurnAntiAccumulatorP = ValueTypefix,
        SwordPowerAccumulatorP = ValueTypefix,
        SwordPowerAntiAccumulatorP = ValueTypefix,
        BurnDamageWeaknessP = ValueTypefix,
        ThunderShieldAccumulatorP = ValueTypefix,
        ThunderShieldAntiAccumulatorP = ValueTypefix,
        ThunderShieldDamageExtraP = ValueTypefix,
        AntiThunderShieldP = ValueTypefix,
        ThunderShieldWeaknessP = ValueTypefix,
        FreezeAccumulatorP = ValueTypefix,
        FreezeAntiAccumulatorP = ValueTypefix,
        FreezeDamageExtraP = ValueTypefix,
        AntiFreezeP = ValueTypefix,
        FreezeWeaknessP = ValueTypefix,
        IdleJumpSpeed = ValueTypefix,
        RunJumpSpeed = ValueTypefix,
        JumpTurnRoundSpeed = ValueTypefix,
        LandingFreeze = ValueTypefix,
        LockedLife = ValueTypefix,
        FalloutDamageExtraP = ValueTypefix,
        FalloutAntiDamageP = ValueTypefix,
        FalloutWeaknessP = ValueTypefix,
        FalloutAccumulatorP = ValueTypefix,
        FalloutAntiAccumulatorP = ValueTypefix,
        JumpAcceleration = ValueTypefix,
        BloodBorne = ValueTypefix,
        BloodBorneAttenuationTime = ValueTypefix,
        BloodBorneDeductSpeed = ValueTypefix,
        BloodBorneResetCD = ValueTypefix,
        BloodBorneChangeRateP = ValueTypefix,
        LightNoiseAccumulatorP = ValueTypefix,
        LightNoiseAntiAccumulatorP = ValueTypefix,
        LightNoiseDamageExtraP = ValueTypefix,
        AntiLightNoiseP = ValueTypefix,
        LightNoiseWeaknessP = ValueTypefix,
        DamageChangePEx = ValueTypefix,
        LifeEnergy1 = ValueTypefix,
        LifeEnergy2 = ValueTypefix,
        LifeEnergy3 = ValueTypefix,
        LifeEnergy4 = ValueTypefix,
        LifeEnergy5 = ValueTypefix,
        LifeEnergy6 = ValueTypefix,
        LifeEnergy7 = ValueTypefix,
        LifeEnergy8 = ValueTypefix,
        LifeEnergy9 = ValueTypefix,
        LifeEnergy10 = ValueTypefix,
        CustomEnergyGroup5 = ValueTypefix,
        CustomEnergyGroup6 = ValueTypefix,
        CustomEnergyGroup7 = ValueTypefix,
        CustomEnergyGroup8 = ValueTypefix,
        CustomEnergyGroup9 = ValueTypefix,
        CustomEnergyGroup10 = ValueTypefix,
        FireBoomDamageExtraP = ValueTypefix,
        FireBoomAntiDamageP = ValueTypefix,
        FireBoomWeaknessP = ValueTypefix,
        FireBoomAccumulatorP = ValueTypefix,
        FireBoomAntiAccumulatorP = ValueTypefix,
    },
    XTableNpcType = {
        Id = ValueTypeint,
        Name = ValueTypestring,
        NpcId = Type1ValueTypeint,
        Weight = Type1ValueTypeint,
    },
    XTableNpcTypeIcon = {
        Type = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        IconTranspose = ValueTypestring,
        Des = ValueTypestring,
        Name = ValueTypestring,
        SortId = ValueTypeint,
        ShowId = ValueTypeint,
    },
    XTableOrderActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        RestaurantActivityId = ValueTypeint,
    },
    XTablePacMan2Activity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        GroupId = ValueTypeint,
    },
    XTablePacMan2Entity = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Speed = ValueTypeint,
        TurningDuration = ValueTypeint,
        AlertX = ValueTypeint,
        AlertY = ValueTypeint,
        AlertVisibility = ValueTypebool,
        Params = Type1ValueTypeint,
        Score = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTablePacMan2GameConfig = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypeint,
        ValueArray = Type1ValueTypeint,
    },
    XTablePacMan2Stage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        PreStageId = ValueTypeint,
        GroupId = ValueTypeint,
        GroupOrder = ValueTypeint,
        RedOrb = ValueTypeint,
        Prefab = ValueTypestring,
        InitialHp = ValueTypeint,
        OrbsAttackThreshold = ValueTypeint,
        KeyReward = ValueTypeint,
        Star = Type1ValueTypeint,
        StarReward = Type1ValueTypeint,
        ShowProp = Type1ValueTypeint,
        ShowGhost = Type1ValueTypeint,
        ReviveProtectionTime = ValueTypeint,
    },
    XTablePacMan2StageTips = {
        Id = ValueTypeintPrimaryKey,
        TipsContent = ValueTypestring,
        TriggerType = ValueTypeint,
        TriggerPram = Type1ValueTypeint,
    },
    XTablePacManStage = {
        Id = ValueTypeintPrimaryKey,
        Time = ValueTypeint,
        PelletAmount = ValueTypeint,
        Prefab = ValueTypestring,
    },
    XTablePacManStory = {
        Id = ValueTypeintPrimaryKey,
        StoryId = ValueTypeint,
        TxtTalkName = ValueTypestring,
        TxtTalk = ValueTypestring,
        Image = ValueTypestring,
        TxtAnswer = Type1ValueTypestring,
    },
    XTableParallelAnimeGroup = {
        Id = ValueTypeintPrimaryKey,
        StageIndex = Type1ValueTypeint,
    },
    XTablePartner = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        RecommendElement = Type1ValueTypeint,
        Icon = ValueTypestring,
        LiHuiPath = ValueTypestring,
        Priority = ValueTypeint,
        InitQuality = ValueTypeint,
        CarryCharacterType = ValueTypeint,
        ChipItemId = ValueTypeint,
        ChipNeedCount = ValueTypeint,
        DefaultLock = ValueTypebool,
        GoodsDesc = ValueTypestring,
        GoodsWorldDesc = ValueTypestring,
        DecomposeItemId = Type1ValueTypeint,
        DecomposeItemCount = Type1ValueTypeint,
        RecommendCharacterId = ValueTypeint,
        NoCameraSwitchDuringTransformation = ValueTypebool,
        PartnerType = ValueTypeint,
        AvaliableTimeId = ValueTypeint,
    },
    XTablePartnerBreakThrough = {
        Id = ValueTypeintPrimaryKey,
        PartnerId = ValueTypeint,
        BreakTimes = ValueTypeint,
        LevelLimit = ValueTypeint,
        AttribId = ValueTypeint,
        AttribPromotedId = ValueTypeint,
        LevelUpTemplateId = ValueTypeint,
        CostItemId = Type1ValueTypeint,
        CostItemCount = Type1ValueTypeint,
    },
    XTablePartnerItemSkipId = {
        PartnerId = ValueTypeintPrimaryKey,
        LevelUpSkipIdParams = Type1ValueTypeint,
        ClipSkipIdParams = Type1ValueTypeint,
        StageSkipIdParam = ValueTypeint,
    },
    XTablePartnerLevelUp = {
        Level = ValueTypeintPrimaryKey,
        Exp = ValueTypeint,
        AllExp = ValueTypeint,
    },
    XTablePartnerMainSkillGroup = {
        Id = ValueTypeintPrimaryKey,
        ConditionId = ValueTypeint,
        SkillId = Type2KeyTypeintValueTypeint,
        Element = Type2KeyTypeintValueTypeint,
    },
    XTablePartnerModel = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        StandbyModel = ValueTypestring,
        CombatModel = ValueTypestring,
        SToCAnime = ValueTypestring,
        StandbyBornAnime = ValueTypestring,
        CToSAnime = ValueTypestring,
        CombatBornAnime = ValueTypestring,
        SToCVoice = ValueTypeint,
        CToSVoice = ValueTypeint,
    },
    XTablePartnerModelControl = {
        Id = ValueTypeintPrimaryKey,
        Model = ValueTypestring,
        NodeName = ValueTypestring,
        IsHide = ValueTypeint,
        Effect = ValueTypestring,
    },
    XTablePartnerPassiveSkillGroup = {
        Id = ValueTypeintPrimaryKey,
        SkillId = Type1ValueTypeint,
    },
    XTablePartnerQuality = {
        Id = ValueTypeintPrimaryKey,
        PartnerId = ValueTypeint,
        Quality = ValueTypeint,
        SkillColumnCount = ValueTypeint,
        EvolutionAttrId = ValueTypeint,
        EvolutionCostItemId = Type1ValueTypeint,
        EvolutionCostItemCount = Type1ValueTypeint,
        StarCostChipCount = Type1ValueTypeint,
        AttrId = Type1ValueTypeint,
    },
    XTablePartnerSetting = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Order = ValueTypeint,
        Type = ValueTypeint,
        Title = ValueTypestring,
        Text = ValueTypestring,
        Condition = ValueTypeint,
    },
    XTablePartnerSkill = {
        PartnerId = ValueTypeintPrimaryKey,
        UpgradeCostItemId = Type1ValueTypeint,
        UpgradeCostItemCount = Type1ValueTypeint,
        DefaultMainSkillGroupId = ValueTypeint,
        MainSkillGroupId = Type1ValueTypeint,
        PassiveSkillGroupId = Type1ValueTypeint,
    },
    XTablePartnerSkillEffect = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Level = ValueTypeint,
        Ability = ValueTypeint,
        BornMagic = Type1ValueTypeint,
        SubSkillId = Type1ValueTypeint,
        SubMagicId = Type1ValueTypeint,
    },
    XTablePartnerSkillInfo = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        Level = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTablePartnerSkillWeight = {
        Level = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTablePartnerStory = {
        PartnerId = ValueTypeint,
        StoryId = Type2KeyTypeintValueTypeint,
        ConditionId = Type2KeyTypeintValueTypeint,
    },
    XTablePartnerStoryDetail = {
        Id = ValueTypeint,
        Title = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTablePartnerTeachingChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ActivityTimeId = ValueTypeint,
        ActivityCondition = Type1ValueTypeint,
        StagePrefix = ValueTypestring,
        OpenCondition = Type1ValueTypeint,
        BannerIcon = ValueTypestring,
        Background = ValueTypestring,
        ChapterIcon = ValueTypestring,
        FubenPrefab = ValueTypestring,
        FightStagePrefab = ValueTypestring,
        StoryStagePrefab = ValueTypestring,
        StoryStageDetailBg = ValueTypestring,
        StoryStageDetailIcon = ValueTypestring,
        StageIds = Type1ValueTypeint,
        Order = ValueTypeint,
        NewTag = ValueTypestring,
        PartnerId = ValueTypeint,
    },
    XTablePartnerUiEffect = {
        Id = ValueTypeintPrimaryKey,
        PartnerId = ValueTypeint,
        ModelType = ValueTypestring,
        EffectType = ValueTypestring,
        EffectRootName = ValueTypestring,
        EffectPath = Type1ValueTypestring,
    },
    XTablePassportActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        DailyTaskGroup = ValueTypeint,
        WeekTaskGroup = ValueTypeint,
        BuyPassPortEarlyEndTime = ValueTypeint,
        ComingToEndMailTime = ValueTypeint,
        ComingToEndMailId = ValueTypeint,
        SupplyReward = ValueTypeint,
        BPTask = Type1ValueTypeint,
        NewbieTasks = Type1ValueTypeint,
        RegressionTasks = Type1ValueTypeint,
    },
    XTablePassportBuyFashionShow = {
        PassportId = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        FashionId = ValueTypeint,
        FashionType = ValueTypeint,
    },
    XTablePassportBuyRewardShow = {
        Id = ValueTypeintPrimaryKey,
        PassportId = ValueTypeint,
        Level = ValueTypeint,
        RewardId = ValueTypeint,
        ShowCount = ValueTypeint,
    },
    XTablePassportLevel = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Level = ValueTypeint,
        TotalExp = ValueTypeint,
        CostItemId = ValueTypeint,
        CostItemCount = ValueTypeint,
        IsTargetLevel = ValueTypeint,
    },
    XTablePassportPayTimeCard = {
        Id = ValueTypeint,
        Days = ValueTypeint,
        PassportTypeId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTablePassportReward = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        PassportId = ValueTypeint,
        Level = ValueTypeint,
        RewardId = ValueTypeint,
        IsPrimeReward = ValueTypebool,
    },
    XTablePassportTaskGroup = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        TimeId = ValueTypeint,
        Group = ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTablePassportTimeLimitTaskReward = {
        TaskId = ValueTypeintPrimaryKey,
        ExTimeId = ValueTypeint,
        ExRewardId = ValueTypeint,
    },
    XTablePassportTypeInfo = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Name = ValueTypestring,
        CostItemId = ValueTypeint,
        CostItemCount = ValueTypeint,
        IsFree = ValueTypebool,
        RewardId = ValueTypeint,
        Icon = ValueTypestring,
        BuyDesc = ValueTypestring,
        BuyDescCloudGame = ValueTypestring,
    },
    XTablePatchConfig = {
        Id = ValueTypeintPrimaryKey,
        ResourceType = Type1ValueTypestring,
        ResourceParam = Type1ValueTypestring,
    },
    XTablePay = {
        Key = ValueTypestringPrimaryKey,
        Platform = ValueTypeint,
        GoodsId = ValueTypestring,
        Amount = ValueTypefloat,
        Currency = ValueTypestring,
        ShowAmount = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        MoneyCard = ValueTypeint,
        Icon = ValueTypestring,
        PayId = ValueTypeint,
        ShowUIType = ValueTypeint,
    },
    XTablePBRActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        StageIds = Type1ValueTypeint,
        TaskGroupIds = Type1ValueTypeint,
    },
    XTablePBRArchiveMonster = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Type = ValueTypeint,
        BaseDesc = ValueTypestring,
        UpgradeDesc = ValueTypestring,
        StatusDict = Type2KeyTypeintValueTypeint,
    },
    XTablePBRBgmList = {
        Id = ValueTypeintPrimaryKey,
        CueId = ValueTypeint,
        Name = ValueTypestring,
        Duration = ValueTypeint,
        BeatsPerLoop = ValueTypeint,
        AccentBeatIndex = ValueTypeint,
        BeatsPerMinute = ValueTypefloat,
        Offset = ValueTypeint,
        HitWindowFrames = ValueTypeint,
        CoverImg = ValueTypestring,
    },
    XTablePBRCharacter = {
        CharacterId = ValueTypeintPrimaryKey,
        CharacterName = ValueTypestring,
        CharacterIcon = ValueTypestring,
        ShowPriority = ValueTypeint,
        IsHide = ValueTypebool,
        CharacterType = ValueTypeint,
        BasicAttackDesc = ValueTypestring,
        CorePassiveDesc = ValueTypestring,
        ComboBoostDesc = ValueTypestring,
        CharacterUnlockStage = ValueTypeint,
        CuteModelName = ValueTypestring,
        RecommendStatus = Type1ValueTypeint,
        IdleAction = ValueTypestring,
        WinAction = ValueTypestring,
        FailAction = ValueTypestring,
    },
    XTablePBRCharacterLevel = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Level = ValueTypeint,
        NeedExp = ValueTypeint,
    },
    XTablePBRCharacterStats = {
        CharacterId = ValueTypeintPrimaryKey,
        Status = Type2KeyTypeintValueTypeint,
    },
    XTablePBRClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTablePBRConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypeint,
    },
    XTablePBRDrop = {
        DropType = ValueTypeintPrimaryKey,
        MagicId = ValueTypeint,
        Radius = ValueTypefix,
        Effect = ValueTypestring,
        BeHitEffect = ValueTypestring,
    },
    XTablePBRItem = {
        ItemId = ValueTypeintPrimaryKey,
        ItemType = ValueTypeint,
        OrbColor = ValueTypeint,
        OrbGroup = ValueTypeint,
        ItemTier = ValueTypeint,
        ItemName = ValueTypestring,
        ItemDesc = ValueTypestring,
        UnlockProgressionNodeId = ValueTypeint,
        Icon = ValueTypestring,
        SkillId = ValueTypeint,
        SaveSkillNote = ValueTypeint,
        ItemMagic = ValueTypeint,
        Tags = Type1ValueTypestring,
    },
    XTablePBRItemGroup = {
        OrbGroup = ValueTypeintPrimaryKey,
        ItemIds = Type1ValueTypeint,
    },
    XTablePBRMetaProgression = {
        NodeId = ValueTypeintPrimaryKey,
        PreNode = ValueTypeint,
        NodeName = ValueTypestring,
        NodeType = ValueTypeint,
        NodeGroup = ValueTypeint,
        NodeCost = ValueTypeint,
        NodeCondition = ValueTypeint,
        TextUnlock = ValueTypestring,
        TextLocked = ValueTypestring,
        NodeIcon = ValueTypestring,
        NodeStats = Type1ValueTypeint,
        NodeStatsNum = Type1ValueTypeint,
        ShopFreshCount = ValueTypeint,
        RewardItemIds = Type1ValueTypeint,
    },
    XTablePBRMetaProgressionNodeGroup = {
        NodeGroup = ValueTypeintPrimaryKey,
        NodeIds = Type1ValueTypeint,
    },
    XTablePBRMonsterWave = {
        WaveId = ValueTypeintPrimaryKey,
        WaveType = ValueTypeint,
        WaveReward = ValueTypeint,
        WaveFinishCondition = ValueTypestring,
        MaxMonsterCount = ValueTypeint,
        IconType = ValueTypeint,
        IconAssets = ValueTypestring,
        SpawnGroup = Type1ValueTypeint,
        SpawnTime = Type1ValueTypefix,
    },
    XTablePBRRichTextIconConfig = {
        Key = ValueTypestringPrimaryKey,
        IconRes = ValueTypestring,
    },
    XTablePBRShopRefresh = {
        WaveId = ValueTypeintPrimaryKey,
    },
    XTablePBRSkillGroupDesc = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BaseDesc = ValueTypestring,
        Icon = ValueTypestring,
        LevelDescList = Type1ValueTypestring,
    },
    XTablePBRStage = {
        StageId = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        PreStageId = ValueTypeint,
        StageName = ValueTypestring,
        GridStyle = ValueTypeint,
        StageType = ValueTypeint,
        FinishWaves = ValueTypeint,
        FinishRewards = ValueTypeint,
        RecommendChar = ValueTypeint,
        MonsterWaves = Type1ValueTypeint,
        MaxWaves = ValueTypeint,
        BgmIds = Type1ValueTypeint,
    },
    XTablePBRStatsDesc = {
        StatsId = ValueTypeintPrimaryKey,
        StatsName = ValueTypestring,
        StatsDesc = ValueTypestring,
        ValueBase = ValueTypeint,
        ShowPriority = ValueTypeint,
        IsHide = ValueTypebool,
        MaxValue = ValueTypeint,
        FightValueSrc = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTablePBRTaskGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        GroupType = ValueTypeint,
        TaskIds = Type1ValueTypeint,
    },
    XTablePcgActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        RewardId = ValueTypeint,
        HelpId = ValueTypeint,
        TaskGroupIds = Type1ValueTypeint,
        TaskGroupNames = Type1ValueTypestring,
    },
    XTablePcgCards = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Color = ValueTypeint,
        Suit = ValueTypeint,
        Point = ValueTypeint,
        Name = ValueTypestring,
        KeyWords = ValueTypeint,
        Desc = ValueTypestring,
        CardIcon = ValueTypestring,
        Effects = Type1ValueTypeint,
        TokenIds = Type1ValueTypeint,
    },
    XTablePcgChapter = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        Title = ValueTypestring,
        LockTips = ValueTypestring,
        Type = ValueTypeint,
        ChallengeStageId = ValueTypeint,
        StageIds = Type1ValueTypeint,
        CharacterUnlockIds = Type1ValueTypeint,
        BgIcon = ValueTypestring,
    },
    XTablePcgCharacter = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        ColorType = ValueTypeint,
        Name = ValueTypestring,
        SignatureCardId = ValueTypeint,
        CorePassiveEffects = Type1ValueTypeint,
        RedPingEffects = Type1ValueTypeint,
        YellowPingEffects = Type1ValueTypeint,
        BluePingEffects = Type1ValueTypeint,
        HeadIcon = ValueTypestring,
        HeadIconCircle = ValueTypestring,
        HalfIcon = ValueTypestring,
        Desc = ValueTypestring,
        QteDesc = ValueTypestring,
        RedBallDesc = ValueTypestring,
        BlueBallDesc = ValueTypestring,
        YellowBallDesc = ValueTypestring,
        TagIds = Type1ValueTypeint,
        FinishCv = ValueTypeint,
        QteCv = ValueTypeint,
    },
    XTablePcgCharacterTag = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTablePcgCharacterType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Effects = Type1ValueTypeint,
        ColorTagIcons = Type1ValueTypestring,
    },
    XTablePcgClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Note = ValueTypestring,
        Params = Type1ValueTypestring,
    },
    XTablePcgDrawRules = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        MinTurns = ValueTypeint,
        MaxTurns = ValueTypeint,
        DetailsGroup = Type1ValueTypeint,
        Weights = Type1ValueTypeint,
    },
    XTablePcgDrawRulesDetails = {
        Id = ValueTypeintPrimaryKey,
        DetailsGroup = ValueTypeint,
        PositionType = ValueTypeint,
        Position = ValueTypeint,
        Color = ValueTypeint,
        CardId = ValueTypeint,
        PositionRange = ValueTypeint,
        RedPings = ValueTypeint,
        YellowPings = ValueTypeint,
        BluePings = ValueTypeint,
        RandCards = Type1ValueTypeint,
    },
    XTablePcgEffects = {
        Id = ValueTypeintPrimaryKey,
        Trigger = ValueTypeint,
        TriggerParams = Type1ValueTypeint,
        Type = ValueTypeint,
        TypeParams = Type1ValueTypeint,
        PerformanceOrder = ValueTypeint,
        Desc = ValueTypestring,
        ShowDesc = ValueTypestring,
        Cv = ValueTypeint,
    },
    XTablePcgEffectsTriggerParams = {
        Id = ValueTypeintPrimaryKey,
        ParamCount = ValueTypeint,
    },
    XTablePcgEffectsTypeParams = {
        Id = ValueTypeintPrimaryKey,
        ParamCount = ValueTypeint,
    },
    XTablePcgIllustrate = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Order = ValueTypeint,
        UnlockChapter = ValueTypeint,
        Tag = Type1ValueTypeint,
    },
    XTablePcgMonster = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Group = ValueTypeint,
        Name = ValueTypestring,
        InitialArmor = ValueTypeint,
        InitialHp = ValueTypeint,
        MaxHp = ValueTypeint,
        BehaviorGroup = ValueTypeint,
        Waves = ValueTypeint,
        WavesIsLoop = ValueTypeint,
        WavesToken = ValueTypeint,
        WavesScore = ValueTypeint,
        InitialTokens = Type1ValueTypeint,
        InitialTokensLayer = Type1ValueTypeint,
        HeadIcon = ValueTypestring,
        HalfBodyIcon = ValueTypestring,
    },
    XTablePcgMonsterBehavior = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        OrderType = ValueTypeint,
        Order = ValueTypeint,
        Weights = ValueTypeint,
        Effects = Type1ValueTypeint,
        IconId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTablePcgStage = {
        Id = ValueTypeintPrimaryKey,
        PreStage = ValueTypeint,
        Type = ValueTypeint,
        Name = ValueTypestring,
        FinishCondition = ValueTypeint,
        FinishDesc = ValueTypestring,
        DrawRulesGroup = ValueTypeint,
        HandNum = ValueTypeint,
        FirstDrawNum = ValueTypeint,
        DrawNum = ValueTypeint,
        NeedCharNum = ValueTypeint,
        MonsterGroup = ValueTypeint,
        EnableReboot = ValueTypeint,
        InitActionPoint = ValueTypeint,
        InitialHp = ValueTypeint,
        MaxHp = ValueTypeint,
        MaxEnergy = ValueTypeint,
        EnablePlayerSkill = ValueTypeint,
        StageTokenIcons = Type1ValueTypestring,
        StageTokenNames = Type1ValueTypestring,
        StageTokenDescs = Type1ValueTypestring,
        StarConditions = Type1ValueTypeint,
        StarDesc = Type1ValueTypestring,
        RecommendChar = Type1ValueTypeint,
        PlayerSkillsEffect = Type1ValueTypeint,
        PlayerSkillsEnergy = Type1ValueTypeint,
        CommanderPassiveEffects = Type1ValueTypeint,
        Icon = ValueTypestring,
    },
    XTablePcgTeam = {
        Id = ValueTypestringPrimaryKey,
        Name = ValueTypestring,
        CharacterIdColor1 = ValueTypeint,
        CharacterIdColor2 = ValueTypeint,
        CharacterIdColor3 = ValueTypeint,
    },
    XTablePcgToken = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        RoundClear = ValueTypeint,
        MaxLayer = ValueTypeint,
        RoundClearLayer = ValueTypeint,
        Effects = Type1ValueTypeint,
        IsShow = ValueTypeint,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        EffectType = ValueTypeint,
    },
    XTablePhotoModeShareInfo = {
        Id = ValueTypestringPrimaryKey,
        Name = ValueTypestring,
        IconPath = ValueTypestring,
        Text = ValueTypestring,
        Param = Type1ValueTypestring,
    },
    XTablePhotoModeSharePlatformConfig = {
        Id = ValueTypeint,
        SdkId = Type1ValueTypeint,
    },
    XTablePickFlipActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        Bg = ValueTypestring,
        ShopId = ValueTypeint,
        AssetItemIds = Type1ValueTypeint,
    },
    XTablePickFlipClienConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTablePickFlipItemTypeConfig = {
        ItemType = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IsSpecial = ValueTypebool,
    },
    XTablePickFlipReward = {
        Id = ValueTypeintPrimaryKey,
        RewardGroupId = ValueTypeint,
        Type = ValueTypeint,
        Weight = ValueTypeint,
        TemplateId = ValueTypeint,
        Count = ValueTypeint,
        ItemType = ValueTypeint,
        Param = Type1ValueTypeint,
    },
    XTablePickFlipRewardGroup = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Order = ValueTypeint,
        ConsumeItemId = ValueTypeint,
        ConsumeItemCount = ValueTypeint,
        SelectRewardCount = ValueTypeint,
        RandomRewardCount = ValueTypeint,
        RandomRewardType = ValueTypeint,
        FinishRewardId = ValueTypeint,
    },
    XTablePickFlipTextRule = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Title = ValueTypestring,
        RuleTitles = Type1ValueTypestring,
        RuleDescs = Type1ValueTypestring,
    },
    XTablePivotCombatActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        ActivityBanner = ValueTypestring,
        CoinId = ValueTypeint,
        ShopType = ValueTypeint,
    },
    XTablePivotCombatDifficult = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Background = ValueTypestring,
    },
    XTablePivotCombatEffectLib = {
        Id = ValueTypeintPrimaryKey,
        EffectLibId = ValueTypeint,
        SupplyEnergyLevel = ValueTypeint,
        ScoreAddition = ValueTypeint,
        FightEventId = ValueTypeint,
        BuffDesc = ValueTypestring,
    },
    XTablePivotCombatRankIcon = {
        Ranking = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
    },
    XTablePivotCombatRegion = {
        Id = ValueTypeintPrimaryKey,
        RegionId = ValueTypeint,
        ActivityId = ValueTypeint,
        OpenTime = ValueTypeint,
        Difficulty = ValueTypeint,
        StageLibId = ValueTypeint,
        TotalSupplyEnergyLevelLimit = ValueTypeint,
        EffectLibId = ValueTypeint,
        RegionName = ValueTypestring,
        SmallIcon = ValueTypestring,
        SecondaryRegionBackground = ValueTypestring,
        SecondaryRegionIndex = ValueTypeint,
        TaskGroupId = ValueTypeint,
    },
    XTablePivotCombatRobot = {
        Id = ValueTypeintPrimaryKey,
        RobotId = ValueTypeint,
    },
    XTablePivotCombatSettleDesc = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
    },
    XTablePivotCombatSkillCheck = {
        CharacterId = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
    },
    XTablePivotCombatStageLib = {
        Id = ValueTypeintPrimaryKey,
        StageLibId = ValueTypeint,
        StageId = ValueTypeint,
        GridIndex = ValueTypeint,
        GridName = ValueTypestring,
        GridIcon = ValueTypestring,
        SupplyEnergyLevelReward = ValueTypeint,
        IsScoreStage = ValueTypebool,
        IsLockCharacterStage = ValueTypebool,
        MutexLockCharacter = ValueTypebool,
        AffixIds = Type1ValueTypeint,
        Tips = Type1ValueTypestring,
        Efficiency = Type1ValueTypestring,
    },
    XTablePlanetRunningActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        TalentPlanetId = ValueTypeint,
        TimeLimitTaskId = ValueTypeint,
        ShopIdList = Type1ValueTypeint,
    },
    XTablePlanetRunningAttr = {
        Id = ValueTypeintPrimaryKey,
        Key = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTablePlanetRunningAttribute = {
        Id = ValueTypeintPrimaryKey,
        Life = ValueTypeint,
        Attack = ValueTypeint,
        Defense = ValueTypeint,
        CriticalChance = ValueTypeint,
        CriticalDamage = ValueTypeint,
        AttackSpeed = ValueTypeint,
        LifeGrowUp = ValueTypefloat,
        AttackGrowUp = ValueTypefloat,
        DefenseGrowUp = ValueTypefloat,
        CriticalChanceGrowUp = ValueTypefloat,
        CriticalDamageGrowUp = ValueTypefloat,
        AttackSpeedGrowUp = ValueTypefloat,
        FightCriticalChanceGrowUp = ValueTypefloat,
        Desc = ValueTypestring,
    },
    XTablePlanetRunningBossGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        BossId = ValueTypeint,
        SummonValue = ValueTypeint,
        BossFightValue = ValueTypeint,
        CommendFightValue = ValueTypeint,
        BottomEventId = ValueTypeint,
    },
    XTablePlanetRunningBubbleController = {
        Id = ValueTypeintPrimaryKey,
        IntervalTime = ValueTypeint,
        TriggerLimitCount = ValueTypeint,
        Duration = ValueTypeint,
        BubbleResId = ValueTypeint,
    },
    XTablePlanetRunningBubbleResource = {
        Id = ValueTypeintPrimaryKey,
        IconEmoji = ValueTypestring,
        IconSymbol = ValueTypestring,
        SoundId = ValueTypeint,
    },
    XTablePlanetRunningBuilding = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BgDesc = ValueTypestring,
        IconUrl = ValueTypestring,
        UnlockStageId = ValueTypeint,
        BuildType = ValueTypeint,
        GridOccupyType = ValueTypeint,
        RangeType = ValueTypeint,
        BuildingCount = ValueTypeint,
        Cast = ValueTypeint,
        Recovery = ValueTypefloat,
        CanRecovery = ValueTypebool,
        CanSelect = ValueTypebool,
        CycleLevelUp = ValueTypeint,
        BatchBuild = ValueTypeint,
        Events = Type1ValueTypeint,
        FloorId = ValueTypeint,
        FloorHeight = ValueTypefloat,
        ModelKey = ValueTypestring,
        IsShowBuildingCount = ValueTypebool,
        LimitNumStageIds = Type1ValueTypeint,
        LimitNums = Type1ValueTypeint,
        Icon = ValueTypestring,
        RelyOnBuilding = ValueTypeint,
        ComboEvent = ValueTypeint,
        UnlockTimeId = ValueTypeint,
    },
    XTablePlanetRunningBuildingRecommend = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Building = ValueTypeint,
        IsRecommend = ValueTypebool,
    },
    XTablePlanetRunningChapter = {
        Id = ValueTypeintPrimaryKey,
        ChapterName = ValueTypestring,
        OpenTimeId = ValueTypeint,
        PreStageId = ValueTypeint,
        BaseTileFloorId = ValueTypeint,
        BaseRoadFloorId = ValueTypeint,
        TitleIconUrl = ValueTypestring,
        StageSceneUrl = ValueTypestring,
        PlanetPrefabUrl = ValueTypestring,
    },
    XTablePlanetRunningCharacter = {
        Id = ValueTypeintPrimaryKey,
        Sorting = ValueTypeint,
        UnlockStageId = ValueTypeint,
        NpcAttributeId = ValueTypeint,
        AttributeIds = Type1ValueTypeint,
        AttributeValues = Type1ValueTypeint,
        Name = ValueTypestring,
        Model = ValueTypestring,
        Events = Type1ValueTypeint,
        DefaultUnlock = ValueTypebool,
        Story = ValueTypestring,
        From = ValueTypestring,
        Icon = ValueTypestring,
        LockDesc = ValueTypestring,
    },
    XTablePlanetRunningClientCfg = {
        Key = ValueTypestringPrimaryKey,
        IntValues = Type1ValueTypeint,
        FloatValues = Type1ValueTypefloat,
        StringValues = Type1ValueTypestring,
    },
    XTablePlanetRunningCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Desc = ValueTypestring,
        Params = Type1ValueTypeint,
    },
    XTablePlanetRunningEffect = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Overlying = ValueTypebool,
        TriggerCountLimit = ValueTypeint,
        Desc = ValueTypestring,
        Params = Type1ValueTypeint,
        BubbleControllerId = ValueTypeint,
        PlayEffect = ValueTypestring,
    },
    XTablePlanetRunningEvent = {
        Id = ValueTypeintPrimaryKey,
        ActivateCount = ValueTypeint,
        TriggerType = ValueTypeint,
        IsDirectTrigger = ValueTypebool,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        UseDesc = ValueTypestring,
        Show = ValueTypeint,
        Icon = ValueTypestring,
        IsIncrease = ValueTypeint,
        Effects = Type1ValueTypeint,
        Conditions = Type1ValueTypeint,
    },
    XTablePlanetRunningFightingGrowUp = {
        Name = ValueTypestringPrimaryKey,
        Id = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTablePlanetRunningFightingPower = {
        StageId = ValueTypeintPrimaryKey,
        MaxLife = ValueTypefloat,
        Attack = ValueTypefloat,
        Defense = ValueTypefloat,
        CriticalChance = ValueTypefloat,
        CriticalDamage = ValueTypefloat,
        AttackSpeed = ValueTypefloat,
    },
    XTablePlanetRunningGrid = {
        Id = ValueTypeintPrimaryKey,
        AdjacentGrid = Type1ValueTypeint,
        GridType = ValueTypeint,
        StageId = ValueTypeint,
        DefaultBuilding = ValueTypeint,
        BuildingCenter = ValueTypeint,
        BuildingDirection = ValueTypeint,
        DefaultFloorId = ValueTypeint,
        FloorHeight = ValueTypefloat,
    },
    XTablePlanetRunningItem = {
        Id = ValueTypeintPrimaryKey,
        TargetType = ValueTypeint,
        TargetTypeParam = ValueTypeint,
        Range = ValueTypeint,
        TargetCount = ValueTypeint,
        Name = ValueTypestring,
        OverflowReturnCoin = ValueTypeint,
        Events = Type1ValueTypeint,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTablePlanetRunningItemGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        ItemId = ValueTypeint,
        Weight = ValueTypeint,
        DrawCount = ValueTypeint,
    },
    XTablePlanetRunningLevelAttribute = {
        Id = ValueTypeintPrimaryKey,
        AttributeId = ValueTypeint,
        StageId = ValueTypeint,
        Level = ValueTypeint,
        Life = ValueTypeint,
        Attack = ValueTypeint,
        Defense = ValueTypeint,
        CriticalChance = ValueTypeint,
        CriticalDamage = ValueTypeint,
        AttackSpeed = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTablePlanetRunningMaterial = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        UnlockStageId = ValueTypeint,
        MaterialIcon = ValueTypestring,
        MaterialUrl = ValueTypestring,
        IsRoad = ValueTypeint,
        TalentFloorHeight = ValueTypefloat,
    },
    XTablePlanetRunningModelCfg = {
        Key = ValueTypestringPrimaryKey,
        ResUrl = ValueTypestring,
        Scale = Type1ValueTypefloat,
    },
    XTablePlanetRunningMonster = {
        Id = ValueTypeintPrimaryKey,
        NpcAttributeId = ValueTypeint,
        MonsterType = ValueTypeint,
        UnlockCharacterId = ValueTypeint,
        CoinFactor = ValueTypefloat,
        CoinSeckillFactor = ValueTypefloat,
        BaseCoin = ValueTypefloat,
        CoinLimit = ValueTypeint,
        Events = Type1ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Model = ValueTypestring,
    },
    XTablePlanetRunningMovieContent = {
        Id = ValueTypeintPrimaryKey,
        MovieId = ValueTypeint,
        Name = ValueTypestring,
        TalkText = ValueTypestring,
        Action = ValueTypestring,
        BubbleControllerId = ValueTypeint,
        PlanetCharacterId = ValueTypeint,
    },
    XTablePlanetRunningMovieController = {
        Id = ValueTypeintPrimaryKey,
        MovieId = ValueTypeint,
        Condition = ValueTypeint,
        StageId = ValueTypeint,
        BossId = ValueTypeint,
    },
    XTablePlanetRunningRoad = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        StartTileId = ValueTypeint,
        EndTileId = ValueTypeint,
        IsRoadStart = ValueTypeint,
    },
    XTablePlanetRunningSceneCamera = {
        Id = ValueTypeintPrimaryKey,
        Fov = ValueTypefloat,
        Position = Type1ValueTypefloat,
        Rotation = Type1ValueTypefloat,
    },
    XTablePlanetRunningStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ChapterId = ValueTypeint,
        Order = ValueTypeint,
        PreStageId = ValueTypeint,
        PlanetId = ValueTypeint,
        WeatherGroupId = ValueTypeint,
        BossGroupId = ValueTypeint,
        ItemGroupId = ValueTypeint,
        InitCoin = ValueTypeint,
        CarryItemCount = ValueTypeint,
        CarryBuildingCount = ValueTypeint,
        LevelUpProgress = ValueTypeint,
        RewardId = ValueTypeint,
        EnvironmentEvents = Type1ValueTypeint,
        CompelUsedBuilding = Type1ValueTypeint,
        DefaultBuilding = Type1ValueTypeint,
        DisableBuilding = Type1ValueTypeint,
        BuildingRecommend = ValueTypeint,
        FightLoseCoinProportion = ValueTypefloat,
        Icon = ValueTypestring,
        TargetGroupId = ValueTypeint,
    },
    XTablePlanetRunningTalentBuilding = {
        Id = ValueTypeintPrimaryKey,
        Sorting = ValueTypeint,
        UnlockStageId = ValueTypeint,
        BuyPrices = ValueTypeint,
        HoldingCount = ValueTypeint,
        Events = Type1ValueTypeint,
        UnlockCountStageIds = Type1ValueTypeint,
        UnlockCounts = Type1ValueTypeint,
        CanUseFloorId = Type1ValueTypeint,
        IsCard = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTablePlanetRunningTarget = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTablePlanetRunningVersion = {
        StageId = ValueTypeintPrimaryKey,
        Version = ValueTypeint,
    },
    XTablePlanetRunningWeather = {
        Id = ValueTypeintPrimaryKey,
        Order = ValueTypeint,
        UnlockStageId = ValueTypeint,
        Events = Type1ValueTypeint,
        IsTalentShow = ValueTypeint,
        Name = ValueTypestring,
        EffectUrl = ValueTypestring,
        IconUrl = ValueTypestring,
        BgUrl = ValueTypestring,
    },
    XTablePlanetRunningWeatherGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        WeatherId = ValueTypeint,
        Order = ValueTypeint,
        Duration = ValueTypeint,
    },
    XTablePlatformShare = {
        Id = ValueTypeintPrimaryKey,
        ShareType = ValueTypeint,
        ShareParam = Type1ValueTypestring,
        PlatformType = Type1ValueTypeint,
        PlatformIcon = Type1ValueTypestring,
        PlatformShowedText = Type1ValueTypestring,
    },
    XTablePlatformShareOpen = {
        Id = ValueTypestringPrimaryKey,
        IsOpen = ValueTypebool,
    },
    XTablePlayer = {
        Level = ValueTypeintPrimaryKey,
        MaxExp = ValueTypeint,
        MaxActionPoint = ValueTypeint,
        FreeActionPoint = ValueTypeint,
        MaxFriendCount = ValueTypeint,
    },
    XTablePlayerGender = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        EnDesc = ValueTypestring,
        IconAddress = ValueTypestring,
    },
    XTablePlotExhibitionCharacter = {
        Id = ValueTypeintPrimaryKey,
        NewTime = ValueTypeint,
        Force = Type1ValueTypeint,
        CharacterCg = ValueTypestring,
    },
    XTablePlotExhibitionForce = {
        Id = ValueTypeintPrimaryKey,
        ForceName = ValueTypestring,
        ForceLogo = ValueTypestring,
        ForceDes = ValueTypestring,
    },
    XTablePlotExhibitionRoleGroup = {
        Id = ValueTypeintPrimaryKey,
        RoleName = ValueTypestring,
        CharacterId = Type1ValueTypeint,
        Priority = ValueTypeint,
    },
    XTablePlotExhibitionStoryLine = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        StoryType = ValueTypeint,
        StoryName = ValueTypestring,
        StoryChapter = ValueTypeint,
        StoryBg = ValueTypestring,
        Priority = ValueTypeint,
        NewTime = ValueTypeint,
    },
    XTablePokemonActivity = {
        Id = ValueTypeintPrimaryKey,
        ActivityTimeId = ValueTypeint,
        Bg = ValueTypestring,
        Name = ValueTypestring,
        TaskTimeLimitId = ValueTypeint,
    },
    XTablePokemonChapter = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        ChapterType = ValueTypeint,
        TimeId = ValueTypeint,
        OpenCondition = ValueTypeint,
    },
    XTablePokemonChapterLocalConfig = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Background = ValueTypestring,
        Desc = ValueTypestring,
        ChapterTitleImage = ValueTypestring,
        ChapterScrollBg = ValueTypestring,
        PerPageStageCount = ValueTypeint,
    },
    XTablePokemonInit = {
        Id = ValueTypeintPrimaryKey,
        DefaultEnergy = ValueTypeint,
        DefaultUnlockPositions = Type1ValueTypeint,
        FirstMonsterIds = Type1ValueTypeint,
        DefaultStageTimes = ValueTypeint,
        StageTimesMax = ValueTypeint,
        StageTimesRecoverInterval = ValueTypeint,
        DefaultTimeSupplyAccuTimes = ValueTypeint,
        TimeSupplyAccuInterval = ValueTypeint,
        TimeSupplyMaxCount = ValueTypeint,
        TimeSupplyRewardId = ValueTypeint,
        DramaId = ValueTypestring,
        HelpId = ValueTypeint,
        StageSkipTimesMax = ValueTypeint,
        SkipItemId = ValueTypeint,
    },
    XTablePokemonMonster = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Career = ValueTypeint,
        NpcId = ValueTypeint,
        ModelId = ValueTypestring,
        EnergyCost = ValueTypeint,
        LevelTemplateId = ValueTypeint,
        StarTemplateId = ValueTypeint,
        AbilityRateMonster = ValueTypefloat,
        AbilityRateHp = ValueTypefloat,
        AbilityRateAttack = ValueTypefloat,
        Name = ValueTypestring,
        Description = ValueTypestring,
        HeadIcon = ValueTypestring,
        SkillIds = Type1ValueTypeint,
        RatingIcon = ValueTypestring,
    },
    XTablePokemonMonsterCareer = {
        Career = ValueTypeintPrimaryKey,
        RestraintCareer = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTablePokemonMonsterLevel = {
        Level = ValueTypeintPrimaryKey,
        CostItemId = ValueTypeint,
        CostItemCount = ValueTypeint,
    },
    XTablePokemonMonsterSkill = {
        Id = ValueTypeintPrimaryKey,
        Position = ValueTypeint,
        FightSkillId = ValueTypeint,
        UnlockStar = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTablePokemonMonsterStar = {
        Star = ValueTypeintPrimaryKey,
        MaxLevel = ValueTypeint,
        CostItemId = ValueTypeint,
        CostItemCount = ValueTypeint,
    },
    XTablePokemonStage = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        StageType = ValueTypeint,
        UnlockPosition = ValueTypeint,
        UnlockMaxEnergy = ValueTypeint,
        UnlockDesc = ValueTypestring,
        StageBg = ValueTypestring,
        BossHeadIcon = ValueTypestring,
        IsBossStage = ValueTypeint,
        ActivityId = ValueTypeint,
        ChapterId = ValueTypeint,
        StageMonsterId = Type2KeyTypeintValueTypeint,
        ShowAbility = Type2KeyTypeintValueTypeint,
    },
    XTablePokemonStageMonster = {
        Id = ValueTypeintPrimaryKey,
        Career = ValueTypeint,
        Level = ValueTypeint,
        Ability = ValueTypeint,
        HeadIcon = ValueTypestring,
    },
    XTablePokemonStageTemplate = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        Index = ValueTypeint,
        Type = ValueTypeint,
        PosX = ValueTypefloat,
        PosY = ValueTypefloat,
        PosZ = ValueTypefloat,
        ScaleX = ValueTypefloat,
        ScaleY = ValueTypefloat,
        ScaleZ = ValueTypefloat,
    },
    XTablePokerButtonGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTablePokerGroup = {
        Id = ValueTypeintPrimaryKey,
        PokerGroup = ValueTypeint,
        PokerNum = ValueTypeint,
        PokerSuitType = ValueTypeint,
        PokerSuitName = ValueTypestring,
        FrontAssetPath = ValueTypestring,
    },
    XTablePokerGuessing2Activity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MaxTipsCount = ValueTypeint,
        MaxChangePlayerCardCount = ValueTypeint,
        MaxChangeRobotCardCount = ValueTypeint,
        BackAssetPath = ValueTypestring,
        ShopSkipId = ValueTypeint,
        StoryId = ValueTypestring,
        TaskGroupId = Type1ValueTypeint,
        StageIds = Type1ValueTypeint,
    },
    XTablePokerGuessing2Card = {
        Id = ValueTypeintPrimaryKey,
        PokerNum = ValueTypeint,
        FrontAssetPath = ValueTypestring,
        SmallCardPath = ValueTypestring,
        ChangedFrontAssetPath = ValueTypestring,
        Name = ValueTypestring,
        Note = ValueTypestring,
    },
    XTablePokerGuessing2CardGroup = {
        Id = ValueTypeintPrimaryKey,
        IsOrder = ValueTypebool,
        Card = Type1ValueTypeint,
    },
    XTablePokerGuessing2Character = {
        Id = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        CircularIcon = ValueTypestring,
        LineTips = ValueTypestring,
        LineRoundWin = Type1ValueTypestring,
        LineRoundLose = Type1ValueTypestring,
        LineRoundDraw = Type1ValueTypestring,
        LineGameWin = Type1ValueTypestring,
        LineGameLose = Type1ValueTypestring,
        LineChangeSelfCard = Type1ValueTypestring,
        LineChangeEnemyCard = Type1ValueTypestring,
        Order = ValueTypeint,
        EmojiRoundWin = Type1ValueTypestring,
        EmojiRoundLose = Type1ValueTypestring,
        EmojiRoundDraw = Type1ValueTypestring,
        EmojiGameWin = Type1ValueTypestring,
        EmojiGameLose = Type1ValueTypestring,
        EmojiChangeSelfCard = Type1ValueTypestring,
        EmojiChangeEnemyCard = Type1ValueTypestring,
        ChangeCardIcon = ValueTypestring,
    },
    XTablePokerGuessing2Config = {
        Id = ValueTypeintPrimaryKey,
        Param = ValueTypefloat,
    },
    XTablePokerGuessing2Effect = {
        Id = ValueTypeintPrimaryKey,
        HandCardId = ValueTypeint,
        OpponentCard = ValueTypeint,
        EffectType = ValueTypeint,
        EffectValue = ValueTypeint,
        Note = ValueTypestring,
    },
    XTablePokerGuessing2Stage = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        PreStage = ValueTypeint,
        TimeId = ValueTypeint,
        CardGroup = ValueTypeint,
        WinRate = ValueTypeint,
        WinType = ValueTypeint,
        RewardId = ValueTypeint,
        Effect = Type1ValueTypeint,
    },
    XTablePokerGuessing2StagePerform = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        NpcName = ValueTypestring,
        Icon = ValueTypestring,
        CardIcon = Type1ValueTypestring,
        EffectDesc = ValueTypestring,
        EffectStrikeBack = ValueTypestring,
        LineLevel = Type1ValueTypestring,
        LineLevelStart = Type1ValueTypestring,
        LineRoundWin = Type1ValueTypestring,
        LineRoundLose = Type1ValueTypestring,
        LineRoundDraw = Type1ValueTypestring,
        LineGameWin = Type1ValueTypestring,
        LineGameLose = Type1ValueTypestring,
        LineChangeSelfCard = Type1ValueTypestring,
        LineChangePlayerCard = Type1ValueTypestring,
        EmojiLevelStart = Type1ValueTypestring,
        EmojiRoundWin = Type1ValueTypestring,
        EmojiRoundLose = Type1ValueTypestring,
        EmojiRoundDraw = Type1ValueTypestring,
        EmojiGameWin = Type1ValueTypestring,
        EmojiGameLose = Type1ValueTypestring,
        EmojiChangeSelfCard = Type1ValueTypestring,
        EmojiChangePlayerCard = Type1ValueTypestring,
        EmojiStrikeBack = Type1ValueTypestring,
        EmojiBoom = Type1ValueTypestring,
        EmojiTrap = Type1ValueTypestring,
    },
    XTablePokerGuessing2Story = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        CharacterId = ValueTypeint,
        UnlockItemId = ValueTypeint,
        Cost = ValueTypeint,
        Icon = ValueTypestring,
        StoryId = ValueTypestring,
        Type = ValueTypeint,
    },
    XTablePokerGuessingActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BannerBg = ValueTypestring,
        TaskTimeLimitId = ValueTypeint,
        PokerGroupId = ValueTypeint,
        BackAssetPath = ValueTypestring,
        CostItemID = ValueTypeint,
        CostItemCount = ValueTypeint,
        TaskType = ValueTypeint,
        ShopSkipId = ValueTypeint,
        SingleProgress = ValueTypeint,
        MaxProgress = ValueTypeint,
        MaxTipsCount = ValueTypeint,
        StoryId = ValueTypestring,
    },
    XTablePokerGuessingRole = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Icon = ValueTypestring,
        RoundnessNotItemHeadIcon = ValueTypestring,
        BiggerDesc = ValueTypestring,
        SmallerDesc = ValueTypestring,
        EqualDesc = ValueTypestring,
    },
    XTablePokerGuessingStory = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Icon = ValueTypestring,
        StageId = ValueTypeint,
        UnlockItemId = ValueTypeint,
        Cost = ValueTypeint,
    },
    XTablePracticeActivity = {
        StageId = ValueTypeintPrimaryKey,
        ActivityTimeId = ValueTypeint,
        ActivityCondition = Type1ValueTypeint,
        OpenCondition = Type1ValueTypeint,
        CharacterId = ValueTypeint,
    },
    XTablePracticeChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ChallengeType = ValueTypeint,
        ConditionId = ValueTypeint,
        IsOpen = ValueTypeint,
        Groups = Type1ValueTypeint,
        StageId = Type1ValueTypeint,
    },
    XTablePracticeChapterDetail = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        BgPath = ValueTypestring,
        PracticeContentPrefab = ValueTypestring,
        PracticeGridPrefab = ValueTypestring,
        SubTag = ValueTypeint,
    },
    XTablePracticeChapterLocal = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ChallengeType = ValueTypeint,
        ConditionId = ValueTypeint,
        IsOpen = ValueTypeint,
        StageId = Type1ValueTypeint,
    },
    XTablePracticeGroup = {
        GroupId = ValueTypeintPrimaryKey,
        SkipId = ValueTypeint,
        StageIds = Type1ValueTypeint,
        LinkStageIds = Type1ValueTypeint,
    },
    XTablePracticeGroupDetail = {
        GroupId = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        GeneralSkillId = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        BackGroundImage = ValueTypestring,
        ActivityTimeId = ValueTypeint,
        ActivityCondition = Type1ValueTypeint,
        OpenCondition = Type1ValueTypeint,
        PrefabName = ValueTypestring,
    },
    XTablePracticeGroupDetailCharacterMap = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
    },
    XTablePracticeGroupDetailGeneralSkillMap = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
    },
    XTablePracticeSkillDetails = {
        StageId = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        PhaseDescription = ValueTypestring,
    },
    XTablePrequelChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Order = ValueTypeint,
        ChapterName = ValueTypestring,
        Bg = ValueTypestring,
        Priority = ValueTypeint,
        ActivityBegin = ValueTypestring,
        ActivityEnd = ValueTypestring,
        ActivityCondition = ValueTypeint,
        OpenCondition = Type1ValueTypeint,
        StageId = Type1ValueTypeint,
        PrefabName = ValueTypestring,
        ConditionPriority = ValueTypeint,
        TabRawImagePath = ValueTypestring,
        RImgChapterNamePath = ValueTypestring,
        UiBgPath = ValueTypestring,
        UiFxPath = ValueTypestring,
        FunctionOpenId = ValueTypeint,
        CharacterId = ValueTypeint,
    },
    XTablePrequelChapterInfo = {
        ChapterId = ValueTypeintPrimaryKey,
        ChapterDescription = ValueTypestring,
    },
    XTablePrequelCover = {
        CoverId = ValueTypeintPrimaryKey,
        CoverName = ValueTypestring,
        Priority = ValueTypeint,
        TimeId = ValueTypeint,
        ActivityCondition = ValueTypeint,
        OpenCondition = ValueTypeint,
        ChallengeStage = Type2KeyTypeintValueTypeint,
        ChallengePrefabName = ValueTypestring,
        ShopId = ValueTypeint,
        ChallengeFx = ValueTypestring,
        CharacterId = ValueTypeint,
    },
    XTablePrequelCoverInfo = {
        CoverId = ValueTypeintPrimaryKey,
        CoverBg = ValueTypestring,
        CoverName = ValueTypestring,
        CoverTitle = ValueTypestring,
        CoverDescription = ValueTypestring,
        ChallengeBg = ValueTypestring,
    },
    XTablePurchaseExchangeUiConfig = {
        Id = ValueTypeintPrimaryKey,
        NormalIcon = ValueTypestring,
        SelectIcon = ValueTypestring,
    },
    XTablePurchaseIconAssetPath = {
        Icon = ValueTypestringPrimaryKey,
        AssetPath = ValueTypestring,
        CoverImgPath = ValueTypestring,
    },
    XTablePurchaseItem = {
        Id = ValueTypeint,
        ConsumeId = ValueTypeint,
        ConsumeCount = ValueTypeint,
        ObtainId = ValueTypeint,
        ObtainCount = ValueTypeint,
        FirstObtainId = ValueTypeint,
        FirstObtainCount = ValueTypeint,
        ExtraObtainId = ValueTypeint,
        ExtraObtainCount = ValueTypeint,
        FirstObtainStartTimeStr = ValueTypestring,
        FirstObtainEndTimeStr = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        UiType = ValueTypeint,
        Priority = ValueTypeint,
        LogType = ValueTypeint,
    },
    XTablePurchaseLBByPass = {
        Id = ValueTypeintPrimaryKey,
        LBId = ValueTypeint,
    },
    XTablePurchasePackage = {
        Id = ValueTypeint,
        ConsumeId = ValueTypeint,
        ConsumeCount = ValueTypeint,
        RewardId = ValueTypeint,
        MailId = ValueTypeint,
        MailCount = ValueTypeint,
        DailyRewardId = ValueTypeint,
        DailyRewardCount = ValueTypeint,
        TimeToEffectStr = ValueTypestring,
        TimeToInvalidStr = ValueTypestring,
        ShelvesType = ValueTypeint,
        ShelvesDays = ValueTypestring,
        BuyLimitTimes = ValueTypeint,
        BuyLimitType = ValueTypeint,
        BuyLimitParam = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        IsSellOutShow = ValueTypebool,
        PrePurchaseId = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        Tag = ValueTypeint,
        UiType = ValueTypeint,
        Priority = ValueTypeint,
        LogType = ValueTypeint,
        NormalDiscountStr = ValueTypestring,
        DiscountShowStr = ValueTypestring,
        DiscountItemId = Type1ValueTypeint,
        DiscountItemCount = Type1ValueTypeint,
        DiscountValue = Type1ValueTypeint,
        DiscountBeginTimeStr = Type2KeyTypeintValueTypestring,
        DiscountEndTimeStr = Type2KeyTypeintValueTypestring,
        SignInId = ValueTypeint,
        MutexPurchaseIdStr = ValueTypestring,
        ConvertSwitch = ValueTypeint,
        CanMultiply = ValueTypebool,
        FashionLabel = ValueTypestring,
        PurchaseSignInId = ValueTypeint,
        SkipId = ValueTypeint,
        SelectId = ValueTypeint,
        RandomSelectId = ValueTypeint,
        IsSkipCondition = ValueTypebool,
        CompanyPackage = ValueTypeint,
        CompanyPackageCount = ValueTypeint,
        RemainDayMail = ValueTypeint,
        RemainDayMailId = ValueTypeint,
        TargetMonthlyCard = ValueTypeint,
        MonthlyCardAddDailyCount = ValueTypeint,
    },
    XTablePurchasePackageConvert = {
        Id = ValueTypeint,
        Note = ValueTypestring,
        PurchasePackageId = ValueTypeint,
        RewardGoodsIds = Type1ValueTypeint,
        Prices = Type1ValueTypeint,
    },
    XTablePurchasePackageYKUiConfig = {
        Id = ValueTypeintPrimaryKey,
        HelpKey = ValueTypestring,
        SortWeight = ValueTypeint,
        Tips = Type1ValueTypestring,
        Icon = ValueTypestring,
    },
    XTablePurchasePayUiConfig = {
        Key = ValueTypestringPrimaryKey,
        NormalIcon = ValueTypestring,
        SelectIcon = ValueTypestring,
    },
    XTablePurchaseRecommend = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        AssetPath = ValueTypestring,
        PurchasePackageIds = Type1ValueTypeint,
        ComboPackageIds = Type1ValueTypeint,
        StartTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
        Period = ValueTypeint,
        RareTagType = ValueTypeint,
        IsLockShow = ValueTypebool,
        UiType = ValueTypeint,
        SkipType = ValueTypeint,
        SkipId = ValueTypeint,
        ConditionId = ValueTypeint,
        PriorityConditions = Type1ValueTypeint,
    },
    XTablePurchaseSignIn = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ClientShowId = ValueTypeint,
        DailyRewardIds = Type1ValueTypeint,
        BetterIndexStr = ValueTypestring,
    },
    XTablePurchaseTabControl = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        GroupId = ValueTypeint,
        GroupName = ValueTypestring,
        GroupIcon = ValueTypestring,
        GroupOrder = ValueTypeint,
        UiType = ValueTypeint,
        IsOpen = ValueTypeint,
        ReqUiTypes = Type1ValueTypeint,
        Closecondition = ValueTypeint,
    },
    XTablePurchaseTagType = {
        Tag = ValueTypeintPrimaryKey,
        Des = ValueTypestring,
        Style = ValueTypestring,
        Effect = ValueTypestring,
        Type = ValueTypeint,
    },
    XTablePurchaseUiType = {
        UiType = ValueTypeintPrimaryKey,
        UiPrefabStyle = ValueTypestring,
        GroupType = ValueTypeint,
    },
    XTablePurchaseYKIcon = {
        Id = ValueTypeintPrimaryKey,
        Path = ValueTypestring,
    },
    XTablePuzzleActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        RewardId = ValueTypeint,
        BgImage = ValueTypestring,
    },
    XTablePuzzleActivityPiece = {
        Id = ValueTypeintPrimaryKey,
        ActId = ValueTypeint,
        ItemId = ValueTypeint,
        ItemCount = ValueTypeint,
        CoverImage = ValueTypestring,
    },
    XTableQuest = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Content = ValueTypestring,
        Quality = ValueTypeint,
        Announcer = ValueTypeint,
        MemberCount = ValueTypeint,
        NeedTime = ValueTypeint,
        RecommendAttrib = Type1ValueTypeint,
        PreQuestId = Type1ValueTypeint,
        FinishReward = ValueTypeint,
        ExtraReward = ValueTypeint,
        FilePoolId = ValueTypeint,
        IsRepeatedly = ValueTypeint,
        Condition = Type1ValueTypeint,
    },
    XTableQuestAnnouncerDetail = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableQuestAttribDetail = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableQuestFile = {
        Id = ValueTypeintPrimaryKey,
        FilePoolId = ValueTypeint,
        Condition = Type1ValueTypeint,
        PreFileId = Type1ValueTypeint,
        Weight = ValueTypeint,
        Announcer = ValueTypeint,
    },
    XTableQuestFileDetail = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Cover = ValueTypestring,
        GroupId = ValueTypeint,
        SubGroupId = ValueTypeint,
        Title = ValueTypestring,
        Editor = ValueTypestring,
        Approver = ValueTypestring,
        SubTitle = Type2KeyTypeintValueTypestring,
        SubContent = Type2KeyTypeintValueTypestring,
    },
    XTableQuestFileGroupDetail = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ParentGroup = ValueTypeint,
        UiType = ValueTypeint,
    },
    XTableQuestPool = {
        Id = ValueTypeintPrimaryKey,
        QuestId = Type1ValueTypeint,
        Weight = Type1ValueTypeint,
    },
    XTableQuestQualityDetail = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Color = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableQuestTerminal = {
        Lv = ValueTypeintPrimaryKey,
        NeedFinishQuest = ValueTypeint,
        NeedItem = Type1ValueTypeint,
        ItemCount = Type1ValueTypeint,
        NeedTime = ValueTypeint,
        TeamCount = ValueTypeint,
        QuestCount = ValueTypeint,
        SpecialQuest = ValueTypeint,
        NormalQuest = Type1ValueTypeint,
        NormalQuestMin = Type1ValueTypeint,
        NormalQuestWeight = Type1ValueTypeint,
    },
    XTableQuestTerminalDetail = {
        Lv = ValueTypeintPrimaryKey,
        Description = ValueTypestring,
    },
    XTableQuestTypeDetail = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableRaceActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        TaskTimeLimitId = ValueTypeint,
        ShopId = ValueTypeint,
        SecondShopId = ValueTypeint,
        ItemId = ValueTypeint,
        ShowItemId = Type1ValueTypeint,
        ShowItemCount = Type1ValueTypeint,
        NewsTime = ValueTypeint,
        MatchGuessTime = ValueTypeint,
        MatchGuess = Type1ValueTypeint,
        SkinRewardId = ValueTypeint,
    },
    XTableRaceBroadcast = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        BeforeTime = ValueTypeint,
        IsStill = ValueTypebool,
    },
    XTableRaceCamera = {
        Id = ValueTypeintPrimaryKey,
        AreaDistance = ValueTypeint,
        VcamPrefabPath = ValueTypestring,
        CamChangeTime = ValueTypefloat,
        FollowTarget = Type1ValueTypeint,
        LookAtTarget = Type1ValueTypeint,
        Postion = Type1ValueTypefloat,
        EulerAngles = Type1ValueTypefloat,
    },
    XTableRaceCar = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Quality = ValueTypestring,
        LinearMaxSpeed = ValueTypeint,
        CurveMaxSpeed = ValueTypeint,
        Accelerate = ValueTypeint,
        Luck = ValueTypeint,
        SkillId = Type1ValueTypeint,
    },
    XTableRaceCarSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Times = ValueTypeint,
        EffectId = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        PowerCost = Type1ValueTypeint,
    },
    XTableRaceCharacter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        NormalSkill = ValueTypeint,
        UltraSkill = ValueTypeint,
        LineSpeed = ValueTypeint,
        CurveSpeed = ValueTypeint,
        LineAcc = ValueTypeint,
        LineDec = ValueTypeint,
        CurveAcc = ValueTypeint,
        CurveDec = ValueTypeint,
        DriftGasRate = ValueTypeint,
        DriftGasMax = ValueTypeint,
        LuckWeight = ValueTypeint,
        ShowSpeed = ValueTypeint,
        ShowDrift = ValueTypeint,
        ShowAcc = ValueTypeint,
        ShowLuck = ValueTypeint,
        CharacterModel = ValueTypestring,
        AnimPath = ValueTypestring,
        Priority = ValueTypeint,
        CarModel = ValueTypestring,
        GroupId = ValueTypeint,
        ExtraIds = Type1ValueTypeint,
    },
    XTableRaceCharacterGrade = {
        Id = ValueTypeintPrimaryKey,
        MaxValue = ValueTypeint,
        MinValue = ValueTypeint,
        ShowText = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableRaceCharacterGroupAuto = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = Type1ValueTypeint,
    },
    XTableRaceCharacterSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        UltraShout = ValueTypestring,
        Desc = ValueTypestring,
        Condition = ValueTypeint,
        SignalBallCosts = Type2KeyTypeintValueTypeint,
        Times = ValueTypeint,
        Probability = ValueTypeint,
        Emoji = ValueTypestring,
        EmojiTime = ValueTypeint,
    },
    XTableRaceClientConfig = {
        Id = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableRaceDriftGas = {
        Id = ValueTypeintPrimaryKey,
        Cost = ValueTypeint,
        MagicId = ValueTypeint,
    },
    XTableRaceEffect = {
        Id = ValueTypeintPrimaryKey,
        EffectPath = ValueTypestring,
        Delay = ValueTypeint,
        Follow = ValueTypestring,
    },
    XTableRaceGuess = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Des = ValueTypestring,
        GuessType = ValueTypeint,
        RewardNum = ValueTypeint,
        Priority = ValueTypeint,
        SpecialType = ValueTypeint,
        GuessOptions = Type1ValueTypeint,
        GuessParams = Type1ValueTypeint,
        VoteCorrectVal = ValueTypeint,
    },
    XTableRaceGuessOption = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        MaxValue = ValueTypeint,
        MinValue = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableRaceGuessType = {
        Id = ValueTypeintPrimaryKey,
        PropertyType = ValueTypeint,
        NeedCharacter = ValueTypebool,
        IsHidePlayback = ValueTypebool,
        IsHideRank = ValueTypebool,
        PlaybackRoundId = ValueTypeint,
    },
    XTableRaceHomeNews = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
    },
    XTableRaceMagic = {
        Id = ValueTypeintPrimaryKey,
        Probability = ValueTypeint,
        SearchIds = Type1ValueTypeint,
        Buffs = Type2KeyTypeintValueTypeint,
        DelayTimes = Type2KeyTypeintValueTypeint,
        SelfEffects = Type2KeyTypeintValueTypeint,
        SelfEffectDelayTimes = Type2KeyTypeintValueTypeint,
        TargetEffects = Type2KeyTypeintValueTypeint,
        TargetEffectDelayTimes = Type2KeyTypeintValueTypeint,
    },
    XTableRaceMagicBuff = {
        Id = ValueTypeintPrimaryKey,
        Tags = Type1ValueTypeint,
        Time = ValueTypeint,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        EffectIds = Type1ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableRaceMagicBuffTag = {
        Id = ValueTypeintPrimaryKey,
        SkipTags = Type1ValueTypeint,
        RemoveTags = Type1ValueTypeint,
    },
    XTableRaceMagicSearch = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        SkipSelf = ValueTypeint,
    },
    XTableRaceMap = {
        Id = ValueTypeintPrimaryKey,
        EffectDistance = ValueTypeint,
        ScenePath = ValueTypestring,
        SceneRoadPath = ValueTypestring,
        CameraConfigPath = ValueTypestring,
        DataPath = Type1ValueTypestring,
        PointPath = Type1ValueTypestring,
    },
    XTableRacePath = {
        Id = ValueTypeintPrimaryKey,
        StartDistance = ValueTypeint,
        Distance = ValueTypeint,
        PathTag = ValueTypeint,
    },
    XTableRacePathPoint = {
        Id = ValueTypeintPrimaryKey,
        Distance = ValueTypeint,
        Group = ValueTypeint,
    },
    XTableRacePathRankSignal = {
        Rank = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        Weight = Type1ValueTypeint,
        EffectId = Type1ValueTypeint,
    },
    XTableRacePoint = {
        Id = ValueTypeintPrimaryKey,
        GetPoint = ValueTypeint,
    },
    XTableRaceRound = {
        Id = ValueTypeintPrimaryKey,
        TypeId = ValueTypeint,
        GuessEndTime = ValueTypestring,
        StartTime = ValueTypestring,
        CharacterGroupId = ValueTypeint,
        PromotionNum = ValueTypeint,
        FromRoundIds = Type1ValueTypeint,
        Guess = Type1ValueTypeint,
        PointGroupId = ValueTypeint,
    },
    XTableRaceRoundClient = {
        Id = ValueTypeintPrimaryKey,
        ActId = ValueTypeint,
        Name = ValueTypestring,
        SubTitle = ValueTypestring,
        MapId = ValueTypeint,
        EndShowType = ValueTypeint,
    },
    XTableRaceRoundPointGroupAuto = {
        Id = ValueTypeintPrimaryKey,
        RoundIds = Type1ValueTypeint,
    },
    XTableRaceSignalBall = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        Type = ValueTypeint,
        Emoji = ValueTypestring,
        EmojiTime = ValueTypeint,
        RollIcon = ValueTypestring,
    },
    XTableRaceSignalBallGroup = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        SignalBallId = ValueTypeint,
        Weight = ValueTypeint,
        SkillCostAddWeight = ValueTypeint,
    },
    XTableRaceSignalBallRankGroup = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        Rank = ValueTypeint,
        SignalBallGroup = ValueTypeint,
    },
    XTableRaceSkillBuff = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        Tag = ValueTypeint,
        Time = ValueTypeint,
        Param = Type1ValueTypeint,
    },
    XTableRaceSkillBuffTag = {
        Id = ValueTypeintPrimaryKey,
        SkipTag = Type1ValueTypeint,
        RemoveTag = Type1ValueTypeint,
    },
    XTableRaceSkillCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Formula = ValueTypestring,
        Desc = ValueTypestring,
        Params = Type1ValueTypeint,
    },
    XTableRaceSkillEffect = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SearchId = Type1ValueTypeint,
        BuffId = Type1ValueTypeint,
    },
    XTableRaceSkillSearch = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        SearchType = ValueTypeint,
        SearchParam = ValueTypeint,
        SkipSelf = ValueTypebool,
        CountSkipSelf = ValueTypebool,
    },
    XTableRaceStateEffect = {
        Id = ValueTypeintPrimaryKey,
        NomralEffectIds = Type1ValueTypeint,
        DriftEffectIds = Type1ValueTypeint,
    },
    XTableRadioSignActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
    },
    XTableRadioSignClientConfig = {
        Id = ValueTypeintPrimaryKey,
        FmGroupId = ValueTypeint,
        MinVagueFM = ValueTypefloat,
        MaxVagueFM = ValueTypefloat,
        MinPreciseFM = ValueTypefloat,
        MaxPreciseFM = ValueTypefloat,
        CV = ValueTypestring,
        Subtitles = Type1ValueTypestring,
        SubtitlesTime = Type1ValueTypeint,
        IsEnd = ValueTypebool,
        VideoConfigId = ValueTypeint,
        EndText = ValueTypestring,
        StandTime = ValueTypeint,
    },
    XTableRadioSignContent = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        RewardId = ValueTypeint,
        FmGroup = ValueTypeint,
        Tip = ValueTypestring,
        DefaultFM = ValueTypefloat,
        Duration = ValueTypefloat,
        Text = ValueTypestring,
        Tab = ValueTypestring,
    },
    XTableRankMatchRule = {
        Id = ValueTypeintPrimaryKey,
        ScoreRangeId = ValueTypeint,
        MatchTimeMin = ValueTypeint,
        ScoreDiffLower = ValueTypeint,
        ScoreDiffUpper = ValueTypeint,
    },
    XTableRankMatchScoreRange = {
        Id = ValueTypeintPrimaryKey,
        StageType = ValueTypeint,
        ScoreMin = ValueTypeint,
    },
    XTableRecommendLevel = {
        Id = ValueTypeint,
        LowerLevel = ValueTypeint,
        UpperLevel = ValueTypeint,
    },
    XTableRecommendSearch = {
        Level = ValueTypeint,
        RecommendList = Type1ValueTypeint,
    },
    XTableRedEnvelope = {
        Id = ValueTypeint,
        TimeId = ValueTypeint,
        StageList = Type1ValueTypeint,
        StageTypeList = Type1ValueTypeint,
        DropIds = Type1ValueTypeint,
    },
    XTableRedEnvelopeItemDrop = {
        Id = ValueTypeint,
        ItemId = ValueTypeint,
        ItemCountMax = ValueTypeint,
        ItemCountMin = ValueTypeint,
        Rate = ValueTypeint,
        BottomCount = ValueTypeint,
        DailyCount = ValueTypeint,
        ActivityCount = ValueTypeint,
    },
    XTableRedEnvelopeNpc = {
        Id = ValueTypeintPrimaryKey,
        NpcName = ValueTypestring,
        NpcHead = ValueTypestring,
    },
    XTableReformAffixSource = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        SimpleDes = ValueTypestring,
        Des = ValueTypestring,
        StarLevel = ValueTypeint,
        AddScore = ValueTypeint,
        Condition = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        MutexId = ValueTypeint,
        TeamLimit = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
    },
    XTableReformBuff = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Des = ValueTypestring,
        StarLevel = ValueTypeint,
        SubScore = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
    },
    XTableReformCfg = {
        Id = ValueTypeintPrimaryKey,
        ScoreItemId = ValueTypeint,
        OpenTimeId = ValueTypeint,
        BannerIcon = ValueTypestring,
        Name = ValueTypestring,
        HelpName = ValueTypestring,
        ScoreHelpName = ValueTypestring,
        PreviewCloseTime = ValueTypeint,
        UnlockChallengeScores = ValueTypeint,
    },
    XTableReformChapter = {
        Id = ValueTypeintPrimaryKey,
        ChapterDesc = ValueTypestring,
        OpenTime = ValueTypeint,
        Order = ValueTypeint,
        ChapterEventId = ValueTypeint,
        ChapterEventDesc = ValueTypestring,
        ChapterStageId = Type1ValueTypeint,
        Img = ValueTypestring,
        ImgRed = ValueTypestring,
    },
    XTableReformClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableReformEnemyBuffDetail = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Des = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableReformEnemySource = {
        Id = ValueTypeintPrimaryKey,
        DefaultTargetId = ValueTypeint,
        AddScore = ValueTypeint,
        TargetId = Type1ValueTypeint,
    },
    XTableReformEnemyTarget = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Level = ValueTypeint,
        AffixGroupId = ValueTypeint,
        AffixMaxCount = ValueTypeint,
        Name = ValueTypestring,
        ShowLevel = ValueTypestring,
        HeadIcon = ValueTypestring,
        AddScore = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        Condition = ValueTypeint,
        Label = Type1ValueTypestring,
    },
    XTableReformEnv = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Des = ValueTypestring,
        Icon = ValueTypestring,
        TextIcon = ValueTypestring,
        AddScore = ValueTypeint,
        PreviewIcon = ValueTypestring,
        PreviewText = ValueTypestring,
        FightEventIds = Type1ValueTypeint,
    },
    XTableReformEvolvableGroupBtnSort = {
        Id = ValueTypeintPrimaryKey,
        Weight = ValueTypeint,
    },
    XTableReformGroup = {
        Id = ValueTypeintPrimaryKey,
        SubId = Type1ValueTypeint,
        Des = ValueTypestring,
    },
    XTableReformMemberSource = {
        Id = ValueTypeintPrimaryKey,
        RobotId = ValueTypeint,
        StarLevel = ValueTypeint,
        AddScore = ValueTypeint,
        TargetId = Type1ValueTypeint,
        FightEventId = Type1ValueTypeint,
    },
    XTableReformMemberTarget = {
        Id = ValueTypeintPrimaryKey,
        RobotId = ValueTypeint,
        StarLevel = ValueTypeint,
        SubScore = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
    },
    XTableReformRecommend = {
        StageId = ValueTypeintPrimaryKey,
        Mob = Type1ValueTypeint,
        Affix = Type1ValueTypestring,
    },
    XTableReformStage = {
        Id = ValueTypeintPrimaryKey,
        StageType = ValueTypeint,
        Name = ValueTypestring,
        Difficulty = ValueTypeint,
        BaseStageId = ValueTypeint,
        ShowNpcId = ValueTypeint,
        OpenTimeId = ValueTypeint,
        ShowFightEventIds = Type1ValueTypeint,
        StageDiff = Type1ValueTypeint,
        RecommendScore = ValueTypeint,
        RecommendCharacterIds = Type1ValueTypeint,
        StarNeedScore = Type1ValueTypeint,
        UnlockStageId = ValueTypeint,
        FullPoint = ValueTypeint,
        StageGoalDesc = ValueTypestring,
        RecommendCharacterGroupId = ValueTypeint,
        PressureEasy = ValueTypeint,
        PressureHard = ValueTypeint,
        PlayerAmountLimitAffix = Type1ValueTypeint,
        PlayerAmountLimit = Type1ValueTypeint,
        PlayerAmountLimitDefault = ValueTypeint,
        UseCharaGroup = ValueTypeint,
    },
    XTableReformStageDifficulty = {
        Id = ValueTypeintPrimaryKey,
        Diff = ValueTypeint,
        UnlockScore = ValueTypeint,
        ReformEnv = ValueTypeint,
        ReformEnvMaxCount = ValueTypeint,
        ReformTimeEnv = ValueTypeint,
        ReformEnemys = Type1ValueTypeint,
        ExtraReformEnemys = Type1ValueTypeint,
        ReformBuff = ValueTypeint,
        ReformBuffMaxCount = ValueTypeint,
        ReformMember = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
    },
    XTableReformSubStage = {
        Id = ValueTypeintPrimaryKey,
        RootStage = ValueTypeint,
        Affix = ValueTypeint,
    },
    XTableReformTimeEnvSource = {
        Id = ValueTypeintPrimaryKey,
        StageTimeLimit = ValueTypeint,
        AddScore = ValueTypeint,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        TextIcon = ValueTypestring,
        PreviewIcon = ValueTypestring,
    },
    XTableReformUseCharaGroup = {
        Id = ValueTypeintPrimaryKey,
        CharacterIds = Type1ValueTypeint,
    },
    XTableRegression2Activity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ContinueDays = ValueTypeint,
        Level = ValueTypeint,
        FirstOfflineTime = ValueTypeint,
        SecondOfflineTime = ValueTypeint,
        StoryId = ValueTypestring,
        HelpId = ValueTypeint,
        InRegressionTaskId = ValueTypeint,
        NotInRegressionTaskId = ValueTypeint,
    },
    XTableRegression2ClienConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableRegression2Gacha = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Type = ValueTypeint,
        TimeId = ValueTypeint,
        InviteId = ValueTypeint,
        ContinueDays = ValueTypeint,
        ConsumeId = ValueTypeint,
        ConsumeCount = ValueTypeint,
    },
    XTableRegression2GachaGroup = {
        Id = ValueTypeintPrimaryKey,
        GachaId = ValueTypeint,
        PreGroupId = ValueTypeint,
        CoreRewardGroupId = ValueTypeint,
        RewardGroup = Type1ValueTypeint,
        Weight = Type1ValueTypeint,
    },
    XTableRegression2GachaReward = {
        Id = ValueTypeintPrimaryKey,
        RewardGroupId = ValueTypeint,
        UsableTimes = ValueTypeint,
        TemplateId = ValueTypeint,
        Count = ValueTypeint,
        Param = Type1ValueTypeint,
        Weight = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableRegression2Invite = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        TimeId = ValueTypeint,
        InviteCountMax = ValueTypeint,
        CodeLetter = ValueTypestring,
        RandomLetterCount = ValueTypeint,
        ConsumeItemId = ValueTypeint,
        CountToTransfer = ValueTypeint,
        CountTransferTo = ValueTypeint,
        DailyPointMax = ValueTypeint,
    },
    XTableRegression2InviteReward = {
        Id = ValueTypeintPrimaryKey,
        InviteId = ValueTypeint,
        Type = ValueTypeint,
        NeedPoint = ValueTypeint,
        RewardId = ValueTypeint,
        IsPrimeReward = ValueTypebool,
    },
    XTableRegression2ShareConfig = {
        Id = ValueTypeintPrimaryKey,
        PlatformType = ValueTypeint,
        ChannelId = ValueTypeint,
        KeepQRCode = ValueTypebool,
        ImagePlayerInfo = ValueTypestring,
        TextContent = ValueTypestring,
        KeepLink = ValueTypebool,
        TextPlayerInfo = ValueTypestring,
    },
    XTableRegression2SignIn = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Days = ValueTypeint,
        RewardId = ValueTypeint,
        AssetPath = ValueTypestring,
    },
    XTableRegression2Task = {
        Id = ValueTypeintPrimaryKey,
        TaskId = Type1ValueTypeint,
        DailyTaskId = Type1ValueTypeint,
        WeeklyTaskId = Type1ValueTypeint,
    },
    XTableRegression3Activity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Level = ValueTypeint,
        FirstOfflineTime = ValueTypeint,
        SecondOfflineTime = ValueTypeint,
        ContinueDays = ValueTypeint,
        StoryId = ValueTypestring,
        ShopId = ValueTypeint,
        PackageUiType = ValueTypeint,
        HelpId = ValueTypeint,
    },
    XTableRegression3ActivityOverview = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        ActivityType = ValueTypeint,
        PrefabPath = ValueTypestring,
        RedPointEvent = ValueTypestring,
    },
    XTableRegression3ClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableRegression3NewContent = {
        Id = ValueTypeintPrimaryKey,
        UpdateTime = ValueTypestring,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        SkipId = ValueTypeint,
        Tips = ValueTypestring,
        ImgPath = ValueTypestring,
        ItemId = Type1ValueTypeint,
    },
    XTableRegression3PassportActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ActivityId = ValueTypeint,
        TaskGroup = ValueTypeint,
        BuyPassPortEarlyEndTime = ValueTypeint,
        ComingToEndMailTime = ValueTypeint,
        ComingToEndMailId = ValueTypeint,
    },
    XTableRegression3PassportLevel = {
        Id = ValueTypeintPrimaryKey,
        PassportActivityId = ValueTypeint,
        Level = ValueTypeint,
        TotalExp = ValueTypeint,
    },
    XTableRegression3PassportReward = {
        Id = ValueTypeintPrimaryKey,
        PassportId = ValueTypeint,
        Level = ValueTypeint,
        RewardId = ValueTypeint,
        IsPrimeReward = ValueTypebool,
    },
    XTableRegression3PassportTaskGroup = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        TimeId = ValueTypeint,
        Group = ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTableRegression3PassportTypeInfo = {
        Id = ValueTypeintPrimaryKey,
        PassportActivityId = ValueTypeint,
        Name = ValueTypestring,
        CostItemId = ValueTypeint,
        CostItemCount = ValueTypeint,
        IsFree = ValueTypebool,
        RewardId = ValueTypeint,
        PreviewRewardId = ValueTypeint,
        BuyDesc = ValueTypestring,
    },
    XTableRegression3SignIn = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Days = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableRegression3Survey = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        OpenDay = ValueTypeint,
        TaskId = ValueTypeint,
        UrlId = ValueTypeint,
        LockTips = ValueTypestring,
    },
    XTableRegressionActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Type = ValueTypeint,
        Condition = ValueTypeint,
        Condition2 = ValueTypeint,
        ContinueDays = ValueTypeint,
        ScheduleItemId = ValueTypeint,
        StoryId = ValueTypestring,
        HelpId = ValueTypeint,
        Param = Type1ValueTypeint,
    },
    XTableRegressionCondition = {
        Id = ValueTypeint,
        Level = ValueTypeint,
        FirstOfflineTime = ValueTypeint,
        SecondOfflineTime = ValueTypeint,
    },
    XTableRegressionH5Activity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Level = ValueTypeint,
        OfflineDays = ValueTypeint,
    },
    XTableRegressionH5Reward = {
        Id = ValueTypeintPrimaryKey,
        Num = ValueTypeint,
        SendName = ValueTypestring,
        Title = ValueTypestring,
        Content = ValueTypestring,
        ValidTime = ValueTypeint,
        RewardIds = Type1ValueTypeint,
    },
    XTableRegressionInvite = {
        Id = ValueTypeintPrimaryKey,
        InvitePeopleMax = ValueTypeint,
        CodeLetter = ValueTypestring,
        InviteRewardId = Type1ValueTypeint,
        UseCodeReward = Type1ValueTypeint,
    },
    XTableRegressionInviteReward = {
        Id = ValueTypeintPrimaryKey,
        People = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableRegressionScheduleReward = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        Schedule = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableRegressionTask = {
        Id = ValueTypeintPrimaryKey,
        TaskId = Type1ValueTypeint,
        DailyTaskId = Type1ValueTypeint,
        WeeklyTaskId = Type1ValueTypeint,
    },
    XTableRepeatChallengeActivity = {
        Id = ValueTypeintPrimaryKey,
        ActivityTimeId = ValueTypeint,
        ChallengeTimeId = ValueTypeint,
        FightTimeId = ValueTypeint,
        ShopSkipId = ValueTypeint,
        Name = ValueTypestring,
        ActDescription = ValueTypestring,
        Cover = ValueTypestring,
        NpcRefreshClock = ValueTypeint,
        HideChapterConditionId = ValueTypeint,
        NormalChapter = Type1ValueTypeint,
        HiddenChapter = Type1ValueTypeint,
        SweepCondition = ValueTypeint,
        SpecialCharacters = Type1ValueTypeint,
        ExtraBuffLevel = ValueTypeint,
        ActcvityShopId = ValueTypeint,
        ShopRedPointSortId = ValueTypeint,
        ActivityRewardIds = Type1ValueTypeint,
        RewardShowTimeIds = Type1ValueTypeint,
    },
    XTableRepeatChallengeChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        TitlePath = ValueTypestring,
        Bg = ValueTypestring,
        Prefab = ValueTypestring,
        EffectPath = ValueTypestring,
        OrderId = ValueTypestring,
        Type = ValueTypeint,
        BuffId = ValueTypeint,
        StageId = Type1ValueTypeint,
    },
    XTableRepeatChallengeLevel = {
        Id = ValueTypeintPrimaryKey,
        UpExp = ValueTypeint,
        NeedShow = ValueTypebool,
        SimpleDesc = ValueTypestring,
        BuffId = Type1ValueTypeint,
    },
    XTableRepeatChallengeReward = {
        Id = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableRepeatChallengeStage = {
        Id = ValueTypeintPrimaryKey,
        ExpAdd = ValueTypeint,
    },
    XTableRepeatChatForbid = {
        Id = ValueTypeintPrimaryKey,
        CalculateTime = ValueTypefloat,
        RepeatCount = ValueTypeint,
        StringFilter = Type1ValueTypestring,
    },
    XTableReportEntry = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TagLevel = ValueTypeint,
        TagIds = Type1ValueTypeint,
        Title = ValueTypestring,
        IsShowReportChat = ValueTypeint,
        Remark = ValueTypestring,
    },
    XTableReportTag = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ParentId = ValueTypeint,
        SelectPriority = ValueTypeint,
        OrderPriority = ValueTypeint,
        ContentType = ValueTypeint,
    },
    XTableRestaurantActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ShopTimeId = ValueTypeint,
        Name = ValueTypestring,
        ShopId = ValueTypeint,
        TimeLimitTaskIds = Type1ValueTypeint,
        RecipeTaskId = ValueTypeint,
    },
    XTableRestaurantBuffEffect = {
        Id = ValueTypeintPrimaryKey,
        SectionType = ValueTypeint,
        ProductIds = Type1ValueTypeint,
    },
    XTableRestaurantCameraAuxiliary = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        CenterPos = ValueTypestring,
        MinPos = ValueTypestring,
        MaxPos = ValueTypestring,
        TitleIcon = ValueTypestring,
    },
    XTableRestaurantCharacter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        EmployNeedItemId = Type1ValueTypeint,
        EmployNeedItemCount = Type1ValueTypeint,
        Priority = ValueTypeint,
        Affiliated = ValueTypestring,
        DialogIds = Type1ValueTypeint,
    },
    XTableRestaurantCharacterLv = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Lv = ValueTypeint,
        SkillId = Type1ValueTypeint,
        UpgradeNeedItemId = Type1ValueTypeint,
        UpgradeNeedItemCount = Type1ValueTypeint,
    },
    XTableRestaurantCharacterModel = {
        CharacterId = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Anim = Type1ValueTypestring,
    },
    XTableRestaurantCharacterSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        SectionType = ValueTypeint,
        ProductId = Type1ValueTypeint,
        SkillAddition = Type1ValueTypeint,
    },
    XTableRestaurantClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Notes = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableRestaurantCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Desc = ValueTypestring,
        Params = Type1ValueTypeint,
    },
    XTableRestaurantConfig = {
        Id = ValueTypeintPrimaryKey,
        InitItemCount = ValueTypeint,
        InitIngredient = Type1ValueTypeint,
        InitIngredientCount = Type1ValueTypeint,
        InitFood = Type1ValueTypeint,
        InitFoodCount = Type1ValueTypeint,
        InitCharacter = Type1ValueTypeint,
        OfflineBillTime = ValueTypeint,
        OfflineBillLimit = ValueTypeint,
        AccelerateUseLimit = ValueTypeint,
        AccelerateTime = ValueTypeint,
        MaxSettleTime = ValueTypeint,
        UrgentTime = ValueTypeint,
    },
    XTableRestaurantCustomer = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        BehaviourId = ValueTypestring,
        DialogId = ValueTypeint,
    },
    XTableRestaurantDailyHotSale = {
        DayId = ValueTypeintPrimaryKey,
        FoodList = Type1ValueTypeint,
        SaleAddition = Type1ValueTypeint,
    },
    XTableRestaurantDialog = {
        Id = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        Text = Type1ValueTypestring,
    },
    XTableRestaurantEffect = {
        Id = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        PrefabUrl = ValueTypestring,
    },
    XTableRestaurantFood = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Quality = ValueTypeint,
        ProduceNeedTime = ValueTypeint,
        ConsumeIngredientIds = Type1ValueTypeint,
        ConsumeIngredientCounts = Type1ValueTypeint,
        Price = ValueTypeint,
        SaleNeedTime = ValueTypeint,
        Priority = ValueTypeint,
        IsDefault = ValueTypebool,
        UnlockItemIds = Type1ValueTypeint,
        UnlockItemCounts = Type1ValueTypeint,
        PerformId = ValueTypeint,
    },
    XTableRestaurantIllustrated = {
        Id = ValueTypeintPrimaryKey,
        TabName = ValueTypestring,
        TimeId = ValueTypeint,
    },
    XTableRestaurantIngredient = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        ProduceNeedTime = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableRestaurantLv = {
        Lv = ValueTypeintPrimaryKey,
        UpgradeNeedCharacterNum = ValueTypeint,
        UpgradeNeedSeniorCharacterLv = ValueTypeint,
        UpgradeNeedSeniorCharacterNum = ValueTypeint,
        RewardId = ValueTypeint,
        PerformIds = Type1ValueTypeint,
        UpgradeNeedItemId = Type1ValueTypeint,
        UpgradeNeedItemCount = Type1ValueTypeint,
        CharacterLimit = ValueTypeint,
        CashierLimit = ValueTypeint,
        HotSaleAddition = ValueTypeint,
        UnlockIngredient = Type1ValueTypeint,
        UnlockFood = Type1ValueTypeint,
        IngredientCounterNum = ValueTypeint,
        FoodCounterNum = ValueTypeint,
        SaleCounterNum = ValueTypeint,
        ScenePrefab = ValueTypestring,
        DecorationIcon = ValueTypestring,
        TitleIcon = ValueTypestring,
        CustomerLimit = ValueTypeint,
    },
    XTableRestaurantNpc = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ModelUrl = ValueTypestring,
        ControllerUrl = ValueTypestring,
    },
    XTableRestaurantOrder = {
        Id = ValueTypeintPrimaryKey,
        OrderActivityId = ValueTypeint,
        NpcId = ValueTypeint,
        RewardId = ValueTypeint,
        OrderDesc = ValueTypestring,
        FoodIds = Type1ValueTypeint,
        FoodNums = Type1ValueTypeint,
    },
    XTableRestaurantOrderModel = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Icon = ValueTypestring,
        RePlay = ValueTypestring,
        Anim = Type1ValueTypestring,
    },
    XTableRestaurantPerform = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        StoryId = ValueTypeint,
        RewardId = ValueTypeint,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        SmallIcon = ValueTypestring,
        DefaultPhoto = ValueTypestring,
        UnlockConditionIds = Type1ValueTypeint,
        TaskIds = Type1ValueTypeint,
        BehaviourIds = Type2KeyTypeintValueTypestring,
    },
    XTableRestaurantPerformer = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        PerformBehaviorIds = Type1ValueTypestring,
    },
    XTableRestaurantPerformTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Conditions = Type1ValueTypeint,
    },
    XTableRestaurantPhotoElement = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        RelativePath = ValueTypestring,
        Params = Type1ValueTypeint,
    },
    XTableRestaurantSectionBuff = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SectionType = ValueTypeint,
        UnlockLv = ValueTypeint,
        CharacterIds = Type1ValueTypeint,
        EffectIds = Type1ValueTypeint,
        EffectAdditions = Type1ValueTypeint,
        UnlockItemIds = Type1ValueTypeint,
        UnlockItemCounts = Type1ValueTypeint,
        IsDefault = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableRestaurantSignModel = {
        SignDay = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Anim = Type1ValueTypestring,
    },
    XTableRestaurantSkillType = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        LabelIcon = ValueTypestring,
    },
    XTableRestaurantStorage = {
        Id = ValueTypeintPrimaryKey,
        RestaurantLv = ValueTypeint,
        SectionType = ValueTypeint,
        ProductId = ValueTypeint,
        StorageLimit = ValueTypeint,
    },
    XTableRestaurantStory = {
        Id = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        TalkIds = Type1ValueTypeint,
        Duration = Type1ValueTypeint,
    },
    XTableRestaurantTalk = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Location = ValueTypeint,
        Nickname = ValueTypestring,
        Icon = ValueTypestring,
        Reply = ValueTypestring,
        Answers = Type1ValueTypestring,
    },
    XTableRestaurantWorkPos = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Index = ValueTypeint,
        Pos = ValueTypestring,
        IconOffset = ValueTypestring,
    },
    XTableReviewActivity = {
        Id = ValueTypeintPrimaryKey,
        StartTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
        RewardId = ValueTypeint,
        LimitLv = ValueTypeint,
        MailId = ValueTypeint,
        ShareMailId = ValueTypeint,
        EmojiStartCfgId = ValueTypeint,
        EmojiExceptCfgIds = Type1ValueTypeint,
        ScoreTitleExceptCfgIds = Type1ValueTypeint,
    },
    XTableReviewActivityInfo = {
        Id = ValueTypeintPrimaryKey,
        Key = ValueTypestring,
        ActivityId = ValueTypeint,
        Page = ValueTypeint,
        TextFormat = ValueTypestring,
        DataName = ValueTypestring,
        Note = ValueTypestring,
    },
    XTableReviewActivityPageInfo = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Page = ValueTypeint,
        Components = Type1ValueTypestring,
        ModelType = ValueTypeint,
    },
    XTableReward = {
        Id = ValueTypeintPrimaryKey,
        SubIds = Type1ValueTypeint,
    },
    XTableRewardConfirm = {
        Id = ValueTypeintPrimaryKey,
        Priority = ValueTypeint,
        Title = ValueTypestring,
        Content = ValueTypestring,
    },
    XTableRewardEquip = {
        Id = ValueTypeint,
        TemplateId = ValueTypeint,
        Level = ValueTypeint,
        Star = ValueTypeint,
        BreakThrough = ValueTypeint,
    },
    XTableRewardFashion = {
        Id = ValueTypeint,
        ItemId = ValueTypeint,
        Count = ValueTypeint,
    },
    XTableRewardGoods = {
        Id = ValueTypeintPrimaryKey,
        TemplateId = ValueTypeint,
        Count = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableRewardItem = {
        Id = ValueTypeint,
        ItemId = ValueTypeint,
        Count = ValueTypeint,
    },
    XTableRhythmGameControl = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        Condition = ValueTypeint,
        MapIds = Type1ValueTypeint,
        MapConditions = Type1ValueTypeint,
        HelpId = ValueTypeint,
    },
    XTableRhythmGameMap = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypestring,
    },
    XTableRhythmGameTaikoSkin = {
        Id = ValueTypeintPrimaryKey,
        SkinPrefabUiPath = ValueTypestring,
    },
    XTableRiftActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        ResetNoCdTimes = ValueTypeint,
        ResetCdIncrease = ValueTypeint,
        ResetCdMax = ValueTypeint,
        DailySweepTimes = ValueTypeint,
        PluginPeakloadInit = ValueTypeint,
        PluginPeakloadMax = ValueTypeint,
        AttrLevelSetCount = ValueTypeint,
        ShopId = Type1ValueTypeint,
        TaskGroupId = Type1ValueTypeint,
        PeriodTimeIds = Type1ValueTypeint,
        BackLayers = Type1ValueTypeint,
        RankLayerLimits = Type1ValueTypeint,
        PeriodDesc = Type1ValueTypestring,
        MaxLuckyValue = ValueTypeint,
        RankLayerLimit = ValueTypeint,
        PeriodName = Type1ValueTypestring,
        SeasonTaskGroupId = ValueTypeint,
        AttrSetNameLength = ValueTypeint,
        MopupCd = ValueTypeint,
        MaxWeight = ValueTypeint,
        AffixWeightVersion = ValueTypeint,
        TimeIntervalToLucky = ValueTypeint,
        TimeAddValueToLucky = ValueTypeint,
        GainRewardLuckyValue = ValueTypeint,
    },
    XTableRiftAttributeGroupMap = {
        GroupId = ValueTypeintPrimaryKey,
        SystemEffectType = ValueTypeint,
        SystemEffectParam = Type1ValueTypeint,
        MaxLevel = Type1ValueTypeint,
    },
    XTableRiftChapter = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        ActivityId = ValueTypeint,
        Name = ValueTypestring,
        Order = ValueTypeint,
        UnlockTime = ValueTypeint,
        UnlockLayerId = ValueTypeint,
        LuckyNodeCost = ValueTypeint,
        LayerPassLuckyValue = ValueTypeint,
        LuckyValueMax = ValueTypeint,
        DangerValue = ValueTypeint,
        BuffName = ValueTypestring,
        BuffIcon = ValueTypestring,
        BuffDesc = ValueTypestring,
        StartStoryId = ValueTypeint,
        EndStoryId = ValueTypeint,
        DropDesc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableRiftChapterPluginShow = {
        Id = ValueTypeintPrimaryKey,
        Chapter = ValueTypeint,
        PluginId = ValueTypeint,
    },
    XTableRiftCharacterAndRobot = {
        CharacterId = ValueTypeintPrimaryKey,
        RobotId = ValueTypeint,
        AttrType = ValueTypeint,
    },
    XTableRiftCharacterAndRobotAuto = {
        RobotId = ValueTypeintPrimaryKey,
        AttrType = ValueTypeint,
    },
    XTableRiftClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableRiftCollectAttributeEffect = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        FightEventId = ValueTypeint,
        FightEventLevel = ValueTypeint,
        Value = ValueTypeint,
        ConditionIds = Type1ValueTypeint,
        Attr = ValueTypeint,
    },
    XTableRiftFilterTag = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Params = Type1ValueTypestring,
    },
    XTableRiftFuncUnlock = {
        Id = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
        ItemId = ValueTypeint,
        Order = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableRiftLayer = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        Order = ValueTypeint,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        UnlockByPrevLayer = ValueTypebool,
        JumpLayerMaxCount = ValueTypeint,
        RewardId = ValueTypeint,
        CoinCount = ValueTypeint,
        AttributeCoinCount = ValueTypeint,
        PluginDropTypeGroupId = ValueTypeint,
        NodeRandomGroupId = ValueTypeint,
        NodeName = ValueTypestring,
        NodeDesc = ValueTypestring,
        PluginDropCountMin = ValueTypeint,
        PluginDropCountMax = ValueTypeint,
        LuckyNodeRandomGroupId = ValueTypeint,
        LuckyNodeRewardId = ValueTypeint,
        LuckyPluginDropTypeGroupId = ValueTypeint,
        LuckyPluginDropCountMin = ValueTypeint,
        LuckyPluginDropCountMax = ValueTypeint,
        FirstPassDropPluginIds = Type1ValueTypeint,
        SweepPluginDropTypeGroupId = ValueTypeint,
        SweepPluginDropCountMin = ValueTypeint,
        SweepPluginDropCountMax = ValueTypeint,
        PeriodFightEventIds = Type1ValueTypeint,
        StoryId = ValueTypeint,
        IsTreasure = ValueTypebool,
        MarkId = ValueTypeint,
        TreasureHpRate = Type1ValueTypeint,
        DropCount = Type1ValueTypeint,
    },
    XTableRiftLayerDetail = {
        Id = ValueTypeintPrimaryKey,
        PluginList = Type1ValueTypeint,
        LuckPluginList = Type1ValueTypeint,
        PluginDropList = Type1ValueTypeint,
        LuckPluginDropList = Type1ValueTypeint,
    },
    XTableRiftLayerFightEvent = {
        Id = ValueTypeintPrimaryKey,
        FightEvents = Type1ValueTypeint,
        FightEventLevels = Type1ValueTypeint,
    },
    XTableRiftMark = {
        Id = ValueTypeintPrimaryKey,
        EnemyHpPoint = ValueTypeint,
        NpcGroupPoint = ValueTypeint,
        MaxPoint = ValueTypeint,
    },
    XTableRiftMonster = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        IsShowMark = ValueTypeint,
        Level = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        BuffRandomGroupIds = Type1ValueTypeint,
        HeadIcon = ValueTypestring,
    },
    XTableRiftMonsterBuffRandomItem = {
        BuffId = ValueTypeint,
        Desc = ValueTypestring,
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableRiftMonsterWareRandomItem = {
        MonsterIds = Type1ValueTypeint,
        Desc = ValueTypestring,
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableRiftNodeRandomItem = {
        RiftStageIds = Type1ValueTypeint,
        Desc = ValueTypestring,
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableRiftNodeRandomItemAuto = {
        GroupId = ValueTypeintPrimaryKey,
        RiftStageId = ValueTypeint,
    },
    XTableRiftOneKeyEquip = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Sort = ValueTypeint,
        PluginType = ValueTypeint,
    },
    XTableRiftPlugin = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Star = ValueTypeint,
        Ability = ValueTypeint,
        CharacterId = ValueTypeint,
        FightEvent = ValueTypeint,
        FightEventLevel = ValueTypeint,
        FixAttrIds = Type1ValueTypeint,
        FixAttrLevels = Type1ValueTypeint,
        AttrFixGroupIds = Type1ValueTypeint,
        Load = ValueTypeint,
        DecomposeValue = ValueTypeint,
        Icon = ValueTypestring,
        Quality = ValueTypeint,
        DescId = ValueTypeint,
        DescParam = Type1ValueTypestring,
        DescTipsId = ValueTypeint,
        DescInitValue = ValueTypeint,
        DescFixAttrId = ValueTypeint,
        DescCoefficient = ValueTypeint,
        IsDisplay = ValueTypeint,
        SimpleDescId = ValueTypeint,
        Tags = Type1ValueTypeint,
        Element = ValueTypeint,
        Sort = ValueTypeint,
        GoldDesc = ValueTypestring,
        Chapter = ValueTypeint,
        SlotCount = ValueTypeint,
        AffixUnlockCost = ValueTypeint,
        AffixResetCost = ValueTypeint,
        AffixSameTypeResetCost = ValueTypeint,
        BuyCost = ValueTypeint,
        RandomInitialAffixCount = ValueTypeint,
    },
    XTableRiftPluginAttrFix = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        FixAttrId = ValueTypeint,
        FixAttrLevel = ValueTypeint,
        Ability = ValueTypeint,
        FightEvent = ValueTypeint,
        FightEventLevel = ValueTypeint,
        EffectType = ValueTypeint,
        EffectValue = ValueTypeint,
    },
    XTableRiftPluginDropRandomItem = {
        Id = ValueTypeintPrimaryKey,
        PluginDropTypeId = ValueTypeint,
        PluginId = ValueTypeint,
        Weight = ValueTypeint,
        InactiveWeightIncrease = ValueTypeint,
        ActiveWeightIncrease = ValueTypeint,
    },
    XTableRiftPluginDropTypeRandomItem = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        PluginId = ValueTypeint,
        PeriodWeights = Type1ValueTypeint,
        MissedWeightIncrease = ValueTypeint,
    },
    XTableRiftPluginGroupToFixAttr = {
        GroupId = ValueTypeintPrimaryKey,
        FixAttrId = ValueTypeint,
    },
    XTableRiftPluginQuality = {
        Id = ValueTypeintPrimaryKey,
        Image = ValueTypestring,
        ImageBg = ValueTypestring,
        ImageDropHead = ValueTypestring,
    },
    XTableRiftPluginShopGoods = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        PluginId = ValueTypeint,
        ConsumeCount = ValueTypeint,
        TimeId = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        GoodsType = ValueTypeint,
        PluginIds = Type1ValueTypeint,
        Weights = Type1ValueTypeint,
        ShowPluginId = ValueTypeint,
        InactiveWeightIncrease = ValueTypeint,
        ActiveWeightIncrease = ValueTypeint,
    },
    XTableRiftPluginWords = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        IsQualityColor = ValueTypeint,
    },
    XTableRiftRandomAffix = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Desc = Type1ValueTypestring,
        AffixWeight = ValueTypeint,
        AddAffixWeight = ValueTypeint,
        AddPower = ValueTypeint,
        Level = ValueTypeint,
        AffixPrice = ValueTypeint,
        LevelWeight = ValueTypeint,
        AddLevelWeight = ValueTypeint,
        AddObject = Type1ValueTypeint,
        Icon = ValueTypestring,
        IsInitial = ValueTypebool,
        LuckyCount = ValueTypeint,
        LuckyWeight = ValueTypeint,
    },
    XTableRiftRandomItemBase = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableRiftShop = {
        Id = ValueTypeintPrimaryKey,
        ShowItemId = Type1ValueTypeint,
    },
    XTableRiftStage = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        MonsterWaveRandomGroupIds = Type1ValueTypeint,
    },
    XTableRiftStory = {
        Id = ValueTypeintPrimaryKey,
        Chapter = ValueTypeint,
        Condition = ValueTypeint,
        Name = ValueTypestring,
        AvgId = ValueTypestring,
        Bg = ValueTypestring,
        Words = ValueTypestring,
    },
    XTableRiftSystemAttributeEffectType = {
        Id = ValueTypeintPrimaryKey,
        ShowType = ValueTypeint,
        Desc = ValueTypestring,
        Order = ValueTypeint,
    },
    XTableRiftSystemEffectTypeMap = {
        SystemEffectType = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
    },
    XTableRiftTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableRiftTeamAttribute = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        LimitInit = ValueTypeint,
        LimitMax = ValueTypeint,
        EffectGroupIds = Type1ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableRiftTeamAttributeCost = {
        Id = ValueTypeintPrimaryKey,
        Cost = ValueTypeint,
    },
    XTableRiftTeamAttributeEffect = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Level = ValueTypeint,
        Ability = ValueTypeint,
        FightEvent = ValueTypeint,
        EffectType = ValueTypeint,
        EffectValue = ValueTypeint,
        SystemEffectType = ValueTypeint,
        SystemEffectParam = ValueTypeint,
    },
    XTableRiftTeamAttributeEffectType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ShowType = ValueTypeint,
        Order = ValueTypeint,
    },
    XTableRobot = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        CharacterLevel = ValueTypeint,
        CharacterQuality = ValueTypeint,
        CharacterStar = ValueTypeint,
        CharacterGrade = ValueTypeint,
        SkillLevel = ValueTypeint,
        EnhanceSkillLevel = ValueTypeint,
        RemoveSkillId = Type1ValueTypeint,
        FashionId = ValueTypeint,
        UseFashionId = ValueTypeint,
        WeaponId = ValueTypeint,
        WeaponLevel = ValueTypeint,
        WeaponBeakThrough = ValueTypeint,
        WaferId = Type1ValueTypeint,
        WaferLevel = Type1ValueTypeint,
        WaferBreakThrough = Type1ValueTypeint,
        ShowAbility = ValueTypeint,
        LiberateLv = ValueTypeint,
        WeaponFashion = ValueTypeint,
        WeaponResonance = ValueTypestring,
        WeaponResonanceType = ValueTypestring,
        WaferResonance = Type2KeyTypeintValueTypestring,
        WaferResonanceType = Type2KeyTypeintValueTypestring,
        WaferAwakeCount = Type1ValueTypeint,
        RobotPartnerId = ValueTypeint,
        RebuildNpcId = ValueTypeint,
        SpSkillIds = Type2KeyTypeintValueTypeint,
        SpSkillLevels = Type2KeyTypeintValueTypeint,
        OverrunLevel = ValueTypeint,
        OverrunSuitId = ValueTypeint,
        SwitchSkillGroupId = ValueTypeint,
        SwitchEnhanceSkillGroupId = ValueTypeint,
    },
    XTableRobotPartner = {
        Id = ValueTypeintPrimaryKey,
        PartnerId = ValueTypeint,
        Level = ValueTypeint,
        BreakThrough = ValueTypeint,
        Quality = ValueTypeint,
        StarSchedule = ValueTypeint,
        MainSkillGroup = ValueTypeint,
        MainSkillLevel = ValueTypeint,
        PassiveSkillId = Type1ValueTypeint,
        PassiveSkillLevel = Type1ValueTypeint,
    },
    XTableRobotPlayer = {
        Id = ValueTypeint,
        Name = ValueTypestring,
        Level = ValueTypeint,
        HeadPortrait = ValueTypeint,
        Sign = ValueTypestring,
        CharRobot = Type1ValueTypeint,
    },
    XTableRobotRebuildNpc = {
        RebuildNpcId = ValueTypeintPrimaryKey,
        BigHeadIcon = ValueTypestring,
        BigImage = ValueTypestring,
    },
    XTableRogueLikeActivity = {
        Id = ValueTypeintPrimaryKey,
        ActivityTimeId = ValueTypeint,
        FightTimeId = ValueTypeint,
        TeamEffectId = Type1ValueTypeint,
        ActionPoint = ValueTypeint,
        TeamMemberCount = ValueTypeint,
        BlackShopId = ValueTypeint,
        FightNeedPoint = ValueTypeint,
        RobotMax = ValueTypeint,
        CharacterLimitType = ValueTypeint,
        LimitBuffId = ValueTypeint,
        InitActionPoint = ValueTypeint,
        InitBuffId = ValueTypeint,
    },
    XTableRogueLikeActivityDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        FunctionalOpenId = ValueTypeint,
        BeginStoryId = ValueTypestring,
    },
    XTableRogueLikeBox = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Param = Type1ValueTypeint,
    },
    XTableRogueLikeBuff = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        CustomType = ValueTypeint,
        FightEvent = ValueTypeint,
        Percent = ValueTypeint,
        ItemId = ValueTypeint,
        Discount = ValueTypeint,
        IntensifyId = ValueTypeint,
        CostItemId = ValueTypeint,
        CostItemCount = ValueTypeint,
    },
    XTableRogueLikeBuffDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        BuffType = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableRogueLikeEvent = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Group = ValueTypeint,
        Param = Type1ValueTypeint,
    },
    XTableRogueLikeNode = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Param = Type1ValueTypeint,
    },
    XTableRogueLikeNodeDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        Param = Type1ValueTypeint,
    },
    XTableRogueLikePoint = {
        Type = ValueTypeint,
        Point = ValueTypeint,
    },
    XTableRogueLikePurgatoryScoreDesDetail = {
        Type = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableRogueLikeRecover = {
        Id = ValueTypeintPrimaryKey,
        ActionPoint = ValueTypeint,
        HpPercent = ValueTypeint,
        CostSupportPoint = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableRogueLikeRobot = {
        Id = ValueTypeintPrimaryKey,
    },
    XTableRogueLikeShop = {
        Id = ValueTypeintPrimaryKey,
        LimitCount = ValueTypeint,
        ShopItemId = Type1ValueTypeint,
        BuyCount = Type1ValueTypeint,
    },
    XTableRogueLikeShopItem = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Param = Type1ValueTypeint,
        ConsumeId = Type1ValueTypeint,
        ConsumeNum = Type1ValueTypeint,
    },
    XTableRogueLikeSpecialEvent = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Param = Type1ValueTypeint,
    },
    XTableRogueLikeSpecialEventDetails = {
        Id = ValueTypeintPrimaryKey,
        Description = ValueTypestring,
        Title = ValueTypestring,
    },
    XTableRogueLikeSpecialEventGroup = {
        Id = ValueTypeintPrimaryKey,
        EventId = Type1ValueTypeint,
    },
    XTableRogueLikeSpecialEventGroupDetails = {
        Id = ValueTypeintPrimaryKey,
        GroupItemId = ValueTypeint,
        HasLeave = ValueTypeint,
        IsEnd = ValueTypeint,
        OptionDesc = Type1ValueTypestring,
    },
    XTableRogueLikeSpecialEventGroupItem = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Icon = ValueTypestring,
        Description = ValueTypestring,
        IsEnd = ValueTypeint,
        HasLeave = ValueTypeint,
        OptionId = Type1ValueTypeint,
        OptionDesc = Type1ValueTypestring,
    },
    XTableRogueLikeSupportStation = {
        Id = ValueTypeintPrimaryKey,
        Count = ValueTypeint,
        NeedPoint = ValueTypeint,
        SpecialEvent = ValueTypeint,
    },
    XTableRogueLikeSupportStationDetails = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableRogueLikeTeamEffect = {
        Id = ValueTypeintPrimaryKey,
        BuffId = Type1ValueTypeint,
        CharacterId = Type1ValueTypeint,
    },
    XTableRogueLikeTier = {
        Id = ValueTypeintPrimaryKey,
        Tier = ValueTypeint,
        Group = ValueTypeint,
        NodeId = Type1ValueTypeint,
        FatherNode = Type1ValueTypestring,
    },
    XTableRogueLikeTierSection = {
        Id = ValueTypeintPrimaryKey,
        TierType = ValueTypeint,
        MinTier = ValueTypeint,
        MaxTier = ValueTypeint,
        EventGroup = ValueTypeint,
        GroupId = Type1ValueTypeint,
    },
    XTableRogueLikeTierSectionDetails = {
        Id = ValueTypeintPrimaryKey,
        GroupId = Type1ValueTypeint,
        GroupPrefab = Type1ValueTypestring,
    },
    XTableRogueSimActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        GameTimeId = ValueTypeint,
        Name = ValueTypestring,
        StageIds = Type1ValueTypeint,
        SettlePointPerGold = ValueTypefloat,
        SettlePointPerCity = ValueTypeint,
        SettlePointPerMainLevel = ValueTypeint,
        SettlePointPerBuilding = ValueTypeint,
        SettlePointPerArea = ValueTypeint,
        SettlePointPerEvent = ValueTypeint,
        CommonPropRewardGroup = ValueTypeint,
        CommonBuildingRewardGroup = ValueTypeint,
        CommonEvenRewardGroup = ValueTypeint,
        CommonCityRewardGroup = ValueTypeint,
        CommonMixRewardGroup = ValueTypeint,
    },
    XTableRogueSimArea = {
        Id = ValueTypeintPrimaryKey,
        Level = ValueTypeint,
        UnlockType = ValueTypeint,
        LandformRandomGroupIds = Type1ValueTypeint,
        LandformRandomCounts = Type1ValueTypeint,
        FocusGridId = ValueTypeint,
        UnlockUiGridId = ValueTypeint,
        UnlockUiPos = ValueTypestring,
        UnlockCost = ValueTypeint,
        UnlockExpReward = ValueTypeint,
        Texts = Type1ValueTypestring,
        TextGridIds = Type1ValueTypeint,
    },
    XTableRogueSimAreaGrid = {
        Id = ValueTypeintPrimaryKey,
        AreaId = ValueTypeint,
        PosX = ValueTypeint,
        PosY = ValueTypeint,
        UnderWaterId = ValueTypeint,
        UnderWaterPosYWan = ValueTypeint,
        UnderWaterHeightWan = ValueTypeint,
        TerrainId = ValueTypeint,
        TerrainHeightWan = ValueTypeint,
        LandformId = ValueTypeint,
        ParentId = ValueTypeint,
        RandomGroupId = ValueTypeint,
        RewardDropId = ValueTypeint,
        AreaLevelGroupId = ValueTypeint,
    },
    XTableRogueSimAreaLevelGridGroup = {
        GroupId = ValueTypeintPrimaryKey,
        AreaLevels = Type1ValueTypeint,
        LandformRandomGroupIds = Type1ValueTypeint,
        LandformRandomCounts = Type1ValueTypeint,
    },
    XTableRogueSimAreaRandomGroup = {
        Id = ValueTypeintPrimaryKey,
        AreaIds = Type1ValueTypeint,
        Weights = Type1ValueTypeint,
    },
    XTableRogueSimBuff = {
        Id = ValueTypeintPrimaryKey,
        ConditionId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        Priority = ValueTypeint,
        Trigger = ValueTypeint,
        Duration = ValueTypeint,
        Overlay = ValueTypeint,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableRogueSimBuilding = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        DescParam = ValueTypeint,
        LandformId = ValueTypeint,
        Icon = ValueTypestring,
        Type = ValueTypeint,
        Quality = ValueTypeint,
        RefreshTurnCount = ValueTypeint,
        RefreshType = ValueTypeint,
        RefreshRewardGroupId = ValueTypeint,
        RefreshRewardDropId = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        EffectIds = Type1ValueTypeint,
        TipId = ValueTypeint,
        DescIcon = Type1ValueTypestring,
        ShowScores = Type2KeyTypeintValueTypeint,
        ActualScores = Type2KeyTypeintValueTypeint,
    },
    XTableRogueSimBuildingBluePrint = {
        Id = ValueTypeintPrimaryKey,
        BuildingId = ValueTypeint,
        MaxCount = ValueTypeint,
        CostGoldCount = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableRogueSimCityLevel = {
        Id = ValueTypeintPrimaryKey,
        LevelGroup = ValueTypeint,
        CityId = ValueTypeint,
        Level = ValueTypeint,
        Name = ValueTypestring,
        BriefDesc = ValueTypestring,
        Desc = ValueTypestring,
        LandformId = ValueTypeint,
        Icon = ValueTypestring,
        FlagIcon = ValueTypestring,
        BuffDesc = ValueTypestring,
        TaskIds = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
        EffectIds = Type1ValueTypeint,
        UnlockExpReward = ValueTypeint,
        ShowScores = Type2KeyTypeintValueTypeint,
        ActualScores = Type2KeyTypeintValueTypeint,
    },
    XTableRogueSimClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Note = ValueTypestring,
        Params = Type1ValueTypestring,
    },
    XTableRogueSimCommodity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        RewardName = ValueTypestring,
        Icon = ValueTypestring,
        MaxCount = ValueTypeint,
        CostResourceCount = ValueTypeint,
        Production = ValueTypeint,
        ProduceIncreaseRate = ValueTypeint,
        ProduceCriticalChanceRate = ValueTypeint,
        ProduceCriticalBonusRate = ValueTypeint,
        Price = ValueTypeint,
        PriceIncreaseRate = ValueTypeint,
        SellCriticalChanceRate = ValueTypeint,
        SellCriticalBonusRate = ValueTypeint,
        PriceRateGroupId = ValueTypeint,
        PriceRateRefreshInterval = ValueTypeint,
        WarningPercent = Type1ValueTypeint,
        WarningText = Type1ValueTypestring,
        WarningColor = Type1ValueTypestring,
        BubbleGroupId = ValueTypeint,
    },
    XTableRogueSimCommodityBubble = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        MethodName = ValueTypestring,
        ParamNames = Type1ValueTypestring,
    },
    XTableRogueSimCommodityBubbleGroup = {
        Id = ValueTypeintPrimaryKey,
        Price = Type1ValueTypeint,
        SpecialPrice = Type1ValueTypeint,
        Production = Type1ValueTypeint,
        SpecialProduction = Type1ValueTypeint,
    },
    XTableRogueSimCommodityPriceRate = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        MaxPriceRate = ValueTypeint,
        MinPriceRate = ValueTypeint,
        Weight = ValueTypeint,
        AddWeights = Type1ValueTypeint,
        AddWeightConditions = Type1ValueTypeint,
    },
    XTableRogueSimCommodityProduction = {
        Id = ValueTypeintPrimaryKey,
        CommodityId = ValueTypeint,
        Population = ValueTypeint,
        Production = ValueTypeint,
        Score = ValueTypeint,
    },
    XTableRogueSimCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Formula = ValueTypestring,
        Params = Type1ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableRogueSimEffect = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Note = ValueTypestring,
        Params = Type1ValueTypeint,
    },
    XTableRogueSimEvent = {
        Id = ValueTypeintPrimaryKey,
        EventType = ValueTypeint,
        RewardShow = ValueTypeint,
        RewardGroupId = ValueTypeint,
        Repeatable = ValueTypebool,
        Duration = ValueTypeint,
        Condition = ValueTypeint,
        SuspendDesc = ValueTypestring,
        Name = ValueTypestring,
        Text = ValueTypestring,
        OptionIds = Type1ValueTypeint,
        ExpireEffectIds = Type1ValueTypeint,
    },
    XTableRogueSimEventOption = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Condition = ValueTypeint,
        CostResourceIds = Type1ValueTypeint,
        CostResourceCounts = Type1ValueTypeint,
        CostResourceRates = Type1ValueTypeint,
        CostCommodityIds = Type1ValueTypeint,
        CostCommodityCounts = Type1ValueTypeint,
        CostCommodityRates = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
        EffectIds = Type1ValueTypeint,
        NextEventId = ValueTypeint,
        WinningRate = ValueTypeint,
        WinningNextEvents = Type1ValueTypeint,
        FailedNextEvents = Type1ValueTypeint,
        GambleRewardDelay = ValueTypeint,
        GambleRewardRates = Type1ValueTypeint,
        GambleRewardWeights = Type1ValueTypeint,
    },
    XTableRogueSimIllustrate = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Key = Type1ValueTypeint,
        StoryGroupId = ValueTypeint,
        StoryGroupName = ValueTypestring,
        StoryTitle = ValueTypestring,
        StoryDesc = ValueTypestring,
        UnlockTips = ValueTypestring,
    },
    XTableRogueSimLandform = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        GridCount = ValueTypeint,
        LandType = ValueTypeint,
        ScaleWan = ValueTypeint,
        RotationYWan = ValueTypeint,
        Model = ValueTypestring,
        ModelCenterIcon = ValueTypestring,
        ModelSideIcon = ValueTypestring,
        EventPool = ValueTypeint,
        FinishLandformId = ValueTypeint,
        IsPreview = ValueTypebool,
        IsExplored = ValueTypebool,
        Icon = ValueTypestring,
        BriefDesc = ValueTypestring,
        Description = ValueTypestring,
        TipId = ValueTypeint,
        TipTurnNumber = ValueTypeint,
    },
    XTableRogueSimLandformRandom = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        SourceLandformId = ValueTypeint,
        MinCount = ValueTypeint,
        MaxCount = ValueTypeint,
        TargetLandformId = ValueTypeint,
        TargetTerrainId = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableRogueSimLoadingTips = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        Weight = ValueTypeint,
    },
    XTableRogueSimMainLevel = {
        Id = ValueTypeintPrimaryKey,
        Level = ValueTypeint,
        LevelGroup = ValueTypeint,
        Name = ValueTypestring,
        BriefDesc = ValueTypestring,
        Desc = ValueTypestring,
        LandformId = ValueTypeint,
        TipId = ValueTypeint,
        Icon = ValueTypestring,
        SmallIcon = ValueTypestring,
        LevelUpResourceIds = Type1ValueTypeint,
        LevelUpResourceCounts = Type1ValueTypeint,
        UnlockAreaIdxs = Type1ValueTypeint,
        UnlockTechLevel = ValueTypeint,
        RewardResourceIds = Type1ValueTypeint,
        RewardResourceCounts = Type1ValueTypeint,
        UnlockBuildCount = ValueTypeint,
        RewardBluePrintIds = Type1ValueTypeint,
        RewardBluePrintCounts = Type1ValueTypeint,
    },
    XTableRogueSimProp = {
        Id = ValueTypeintPrimaryKey,
        Stacked = ValueTypeint,
        Tag = ValueTypeint,
        Duration = ValueTypeint,
        Rare = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        EffectIds = Type1ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        EffectDesc = ValueTypestring,
        ShowLabels = Type1ValueTypeint,
        ShowScores = Type2KeyTypeintValueTypeint,
        ActualScores = Type2KeyTypeintValueTypeint,
    },
    XTableRogueSimPropRare = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Path = ValueTypestring,
    },
    XTableRogueSimPropShowLabel = {
        Id = ValueTypeintPrimaryKey,
        BgColor = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableRogueSimResource = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        MaxCount = ValueTypeint,
    },
    XTableRogueSimReward = {
        Id = ValueTypeintPrimaryKey,
        Tag = ValueTypeint,
        Types = Type1ValueTypeint,
        ItemIds = Type1ValueTypeint,
        Nums = Type1ValueTypeint,
    },
    XTableRogueSimRewardDrop = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Num = ValueTypeint,
        GroupIds = Type1ValueTypeint,
    },
    XTableRogueSimRewardGroup = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        RandomType = ValueTypeint,
        RewardIds = Type1ValueTypeint,
        Weights = Type1ValueTypeint,
        Params = Type1ValueTypestring,
    },
    XTableRogueSimScoreTitle = {
        Id = ValueTypeintPrimaryKey,
        LowerLimit = ValueTypeint,
        UpperLimit = ValueTypeint,
        Content = ValueTypestring,
        BgIcon = ValueTypestring,
    },
    XTableRogueSimStage = {
        Id = ValueTypeintPrimaryKey,
        PreStageId = ValueTypeint,
        TimeId = ValueTypeint,
        GameTimeId = ValueTypeint,
        LevelGroup = ValueTypeint,
        CityLevelGroup = ValueTypeint,
        Name = ValueTypestring,
        NameIcon = ValueTypestring,
        FirstFinishReward = ValueTypeint,
        Type = ValueTypeint,
        Desc = ValueTypestring,
        AreaRandomGroupIds = Type1ValueTypeint,
        MaxTurnCount = ValueTypeint,
        TokenId = ValueTypeint,
        InitResourceIds = Type1ValueTypeint,
        InitResourceCounts = Type1ValueTypeint,
        InitCommodityIds = Type1ValueTypeint,
        InitCommodityCounts = Type1ValueTypeint,
        SettlePoinPerCoin = ValueTypeint,
        SettleCoinMin = ValueTypeint,
        SettleCoinMax = ValueTypeint,
        SettlePoinPerNut = ValueTypeint,
        SettleNutMin = ValueTypeint,
        SettleNutMax = ValueTypeint,
        StarConditions = Type1ValueTypeint,
        StarRewardIds = Type1ValueTypeint,
        StarDescs = Type1ValueTypestring,
    },
    XTableRogueSimTask = {
        Id = ValueTypeintPrimaryKey,
        TaskName = ValueTypestring,
        TaskDesc = ValueTypestring,
        Schedule = ValueTypeint,
        ConditionId = ValueTypeint,
        ConditionParams = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
    },
    XTableRogueSimTaskRandomGroup = {
        Id = ValueTypeintPrimaryKey,
        TaskIds = Type1ValueTypeint,
        Weights = Type1ValueTypeint,
    },
    XTableRogueSimTech = {
        Id = ValueTypeintPrimaryKey,
        TechType = ValueTypeint,
        Rare = ValueTypeint,
        Level = ValueTypeint,
        Cost = ValueTypeint,
        PreIds = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableRogueSimTechLevel = {
        Id = ValueTypeintPrimaryKey,
        Num = ValueTypeint,
        Techs = Type1ValueTypeint,
        NextUnlockLevel = ValueTypeint,
    },
    XTableRogueSimTerrain = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Model = ValueTypestring,
    },
    XTableRogueSimTip = {
        Id = ValueTypeintPrimaryKey,
        Content = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableRogueSimToken = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        EffectDesc = ValueTypestring,
        Icon = ValueTypestring,
        Rare = ValueTypeint,
        RogueSimVolatilityGroupId = ValueTypeint,
        IsShowCity = ValueTypebool,
        BuffIds = Type1ValueTypeint,
        Effect = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableRogueSimTokenRewardDrop = {
        Id = ValueTypeintPrimaryKey,
        TokenId = ValueTypeint,
        LandformId = ValueTypeint,
        RewardDropId = ValueTypeint,
    },
    XTableRogueSimVolatility = {
        Id = ValueTypeintPrimaryKey,
        Tag = ValueTypeint,
        StartTurn = ValueTypeint,
        EndTurn = ValueTypeint,
        Condition = ValueTypeint,
        Weight = ValueTypeint,
        BuffId = ValueTypeint,
        Delay = ValueTypeint,
        Duration = ValueTypeint,
        TipId = ValueTypeint,
    },
    XTableRogueSimVolatilityGroup = {
        Id = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
        VolatilityIds = Type1ValueTypeint,
    },
    XTableRogueSimWeight = {
        Id = ValueTypeintPrimaryKey,
        ConditionIds = Type1ValueTypeint,
        Weights = Type1ValueTypeint,
    },
    XTableRooot = {
        Id = ValueTypestring,
        RewardId = ValueTypeint,
        ExchangeTimes = ValueTypeint,
    },
    XTableRoootActivity = {
        Id = ValueTypeint,
        ActivityTimeId = ValueTypeint,
        RegisterTimeId = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableRpgBaseCharacter = {
        Id = ValueTypeintPrimaryKey,
        DisplayAttriName = Type1ValueTypestring,
        DisplayAttriType = Type1ValueTypeint,
    },
    XTableRpgCharacter = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Level = ValueTypeint,
        RobotId = ValueTypeint,
        SkillIds = Type1ValueTypeint,
    },
    XTableRpgConfig = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MaxChallengeCount = ValueTypeint,
        TalentItemId = ValueTypeint,
        ActivityName = ValueTypestring,
        EntryTexture = ValueTypestring,
        CharacterIds = Type1ValueTypeint,
        DailyRewards = Type1ValueTypeint,
    },
    XTableRpgItemConfig = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Quality = ValueTypeint,
        WorldDesc = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableRpgMakerGameActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TaskTimeLimitId = ValueTypeint,
        TimeId = ValueTypeint,
        BannerBg = ValueTypestring,
        CollectionIcon = ValueTypestring,
        GuideMoveDirection = ValueTypeint,
    },
    XTableRpgMakerGameAnimation = {
        ModelName = ValueTypestringPrimaryKey,
        StandAnimaName = ValueTypestring,
        RunAnimaNames = Type1ValueTypestring,
        FlyAnimNames = Type1ValueTypestring,
        AtkAnimaName = ValueTypestring,
        ElectricFenceAnimaName = ValueTypestring,
        AlarmAnimaName = ValueTypestring,
        DrownAnimaName = ValueTypestring,
        AdsorbAnimaName = ValueTypestring,
        TransferDisAnimaName = ValueTypestring,
        TransferAnimaName = ValueTypestring,
        BubblePushAnimaName = ValueTypestring,
        DropPickAnimaName = ValueTypestring,
        EffectRoot = ValueTypestring,
        SentrySignYOffset = ValueTypeint,
        XOffSet = ValueTypefloat,
        YOffSet = ValueTypefloat,
        ZOffSet = ValueTypefloat,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableRpgMakerGameBlock = {
        Id = ValueTypeintPrimaryKey,
        MapId = ValueTypeint,
        Row = ValueTypeint,
        Col = Type1ValueTypeint,
    },
    XTableRpgMakerGameChapter = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        PreChapterId = ValueTypeint,
        Name = ValueTypestring,
        OpenTimeId = ValueTypeint,
        TagBtnBG = ValueTypestring,
        Prefab = ValueTypestring,
    },
    XTableRpgMakerGameChapterGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        OpenTimeId = ValueTypeint,
        Bg = ValueTypestring,
        ActivityIcon = ValueTypestring,
        IsShowTask = ValueTypebool,
        IsFirstShow = ValueTypebool,
        TitlePrefab = ValueTypestring,
        GroundPrefab = Type1ValueTypestring,
        BlockPrefab = ValueTypestring,
        HelpKey = ValueTypestring,
    },
    XTableRpgMakerGameDeathTitle = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableRpgMakerGameElectricFence = {
        Id = ValueTypeintPrimaryKey,
        MapId = ValueTypeint,
        X = ValueTypeint,
        Y = ValueTypeint,
        Direction = ValueTypeint,
    },
    XTableRpgMakerGameEndPoint = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        X = ValueTypeint,
        Y = ValueTypeint,
        Type = ValueTypeint,
    },
    XTableRpgMakerGameEntity = {
        Id = ValueTypeintPrimaryKey,
        X = ValueTypeint,
        Y = ValueTypeint,
        MapId = ValueTypeint,
        Type = ValueTypeint,
        BrokenType = ValueTypeint,
    },
    XTableRpgMakerGameGap = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        X = ValueTypeint,
        Y = ValueTypeint,
        MapId = ValueTypeint,
        Direction = ValueTypeint,
    },
    XTableRpgMakerGameHintDialogBox = {
        StageId = ValueTypeintPrimaryKey,
        Text = ValueTypestring,
        BackCount = ValueTypeint,
        ResetCount = ValueTypeint,
        TotalLoseCount = ValueTypeint,
    },
    XTableRpgMakerGameHintIcon = {
        Key = ValueTypestringPrimaryKey,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Layer = ValueTypeint,
    },
    XTableRpgMakerGameHintLine = {
        MapId = ValueTypeintPrimaryKey,
        HintTitle = ValueTypestring,
        StartRowAndCol = ValueTypestring,
        StartGridPercent = ValueTypestring,
        NextRowAndCol = Type1ValueTypestring,
        NextGridPercent = Type1ValueTypestring,
    },
    XTableRpgMakerGameMap = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Row = ValueTypeint,
        Col = ValueTypeint,
        MaxRound = ValueTypeint,
        StartPointId = ValueTypeint,
        EndPointId = ValueTypeint,
        Prefab = ValueTypestring,
    },
    XTableRpgMakerGameMixBlock = {
        Id = ValueTypeintPrimaryKey,
        MapId = ValueTypeint,
        Row = ValueTypeint,
        Col = Type1ValueTypestring,
    },
    XTableRpgMakerGameModel = {
        Key = ValueTypestringPrimaryKey,
        ModelPath = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        Size = ValueTypestring,
        Scale = Type1ValueTypefloat,
    },
    XTableRpgMakerGameMonster = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        X = ValueTypeint,
        Y = ValueTypeint,
        MapId = ValueTypeint,
        Direction = ValueTypeint,
        ViewFront = ValueTypeint,
        ViewBack = ValueTypeint,
        ViewLeft = ValueTypeint,
        ViewRight = ValueTypeint,
        TriggerEnd = ValueTypeint,
        Type = ValueTypeint,
        SkillType = ValueTypeint,
        PatrolId = Type1ValueTypeint,
        Prefab = ValueTypestring,
        SentryFront = ValueTypeint,
        SentryBack = ValueTypeint,
        SentryLeft = ValueTypeint,
        SentryRight = ValueTypeint,
        SentryStopRound = ValueTypeint,
        ModelKey = ValueTypestring,
    },
    XTableRpgMakerGamePatrol = {
        Id = ValueTypeint,
        PatrolDirection = Type1ValueTypeint,
        PatrolStep = Type1ValueTypeint,
    },
    XTableRpgMakerGamePlayMainDownHint = {
        Id = ValueTypeintPrimaryKey,
        Text = ValueTypestring,
    },
    XTableRpgMakerGameRandomDialogBox = {
        Id = ValueTypeintPrimaryKey,
        PreStage = ValueTypeint,
        Text = ValueTypestring,
        Weight = ValueTypeint,
        Duration = ValueTypefloat,
    },
    XTableRpgMakerGameRole = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        UnlockChapterId = ValueTypeint,
        Style = ValueTypestring,
        SkillTypes = Type1ValueTypeint,
        RoleType = ValueTypeint,
        ModelAssetPath = ValueTypestring,
        RoleOrder = ValueTypeint,
        Info = ValueTypestring,
        InfoName = ValueTypestring,
        HeadPath = ValueTypestring,
        LockTipsDesc = ValueTypestring,
        SkillTypeDescs = Type1ValueTypestring,
        SkillTypeIconBefores = Type1ValueTypestring,
        SkillTypeIconAfters = Type1ValueTypestring,
    },
    XTableRpgMakerGameShadow = {
        Id = ValueTypeintPrimaryKey,
        MapId = ValueTypeint,
        X = ValueTypeint,
        Y = ValueTypeint,
        Direction = ValueTypeint,
    },
    XTableRpgMakerGameSkillType = {
        SkillType = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableRpgMakerGameStage = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        PreStage = ValueTypeint,
        MapId = ValueTypeint,
        Name = ValueTypestring,
        StageHint = ValueTypestring,
        BG = ValueTypestring,
        Prefab = ValueTypestring,
        LoseHint = Type1ValueTypestring,
        NumberName = ValueTypestring,
        HintCost = ValueTypeint,
        AnswerCost = ValueTypeint,
        UseRoleId = ValueTypeint,
        ShadowId = ValueTypeint,
    },
    XTableRpgMakerGameStarCondition = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Star = ValueTypeint,
        Reward = ValueTypeint,
        StepCount = ValueTypeint,
        MonsterCount = ValueTypeint,
        MonsterBossCount = ValueTypeint,
        ConditionDesc = ValueTypestring,
        DropType = Type2KeyTypeintValueTypeint,
        DropCount = Type2KeyTypeintValueTypeint,
    },
    XTableRpgMakerGameStartPoint = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        X = ValueTypeint,
        Y = ValueTypeint,
        Direction = ValueTypeint,
    },
    XTableRpgMakerGameTransferPoint = {
        Id = ValueTypeintPrimaryKey,
        X = ValueTypeint,
        Y = ValueTypeint,
        MapId = ValueTypeint,
        Color = ValueTypeint,
    },
    XTableRpgMakerGameTrap = {
        Id = ValueTypeintPrimaryKey,
        MapId = ValueTypeint,
        X = ValueTypeint,
        Y = ValueTypeint,
    },
    XTableRpgMakerGameTrigger = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        X = ValueTypeint,
        Y = ValueTypeint,
        MapId = ValueTypeint,
        Type = ValueTypeint,
        TargetId = Type1ValueTypeint,
        DefaultBlock = ValueTypeint,
    },
    XTableRpgMonsters = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SubName = ValueTypestring,
        MonsterNpcDataId = ValueTypeint,
        IsBoss = ValueTypeint,
        Scale = ValueTypefloat,
        PositionX = ValueTypefloat,
        PositionY = ValueTypefloat,
        PositionZ = ValueTypefloat,
        RotationX = ValueTypefloat,
        RotationY = ValueTypefloat,
        RotationZ = ValueTypefloat,
    },
    XTableRpgStage = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        StageId = ValueTypeint,
        TagId = ValueTypeint,
        OrderId = ValueTypeint,
        OrderName = ValueTypestring,
        Difficulty = ValueTypeint,
        StageBuffDesc = ValueTypestring,
        MonsterId = Type1ValueTypeint,
        RecommendLevel = ValueTypeint,
        NpcAffixId = Type1ValueTypeint,
        IsShowScore = ValueTypeint,
    },
    XTableRpgTag = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        SceneUrl = ValueTypestring,
        ModelUrl = ValueTypestring,
    },
    XTableRpgTalent = {
        TalentId = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        LayerId = ValueTypeint,
        TalentType = ValueTypeint,
        ConsumeCount = ValueTypeint,
        AttribPoolGroupId = ValueTypeint,
        SkillIds = Type1ValueTypeint,
        SkillLevels = Type1ValueTypeint,
        EventIds = Type1ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        SpecialAbility = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableRpgTalentLayer = {
        LayerId = ValueTypeintPrimaryKey,
        NeedTeamLevel = ValueTypeint,
    },
    XTableRpgTalentType = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        TalentType = ValueTypeint,
        Name = ValueTypestring,
        TalentDes = ValueTypestring,
        Icon = ValueTypestring,
        BattleRoomBg = ValueTypestring,
    },
    XTableRpgTeamLevel = {
        Level = ValueTypeintPrimaryKey,
        PreLevel = ValueTypeint,
        Exp = ValueTypeint,
        AddTalentPoint = ValueTypeint,
        AddRoleLevel = ValueTypeint,
        AddSkillLv = ValueTypeint,
    },
    XTableRunGameActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        GroupIds = Type1ValueTypeint,
        FinalStageModel = ValueTypestring,
        FinalStageId = ValueTypeint,
        ConsumeId = ValueTypeint,
        ConsumeCount = ValueTypeint,
    },
    XTableRunGameChallengeTarget = {
        Id = ValueTypeintPrimaryKey,
        Target = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableRunGameGroup = {
        GroupId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Prefab = ValueTypestring,
        RobotId = ValueTypeint,
        RoleHead = ValueTypestring,
        RoleName = ValueTypestring,
        StageIds = Type1ValueTypeint,
    },
    XTableRunGameStage = {
        StageId = ValueTypeintPrimaryKey,
        Prefab = ValueTypestring,
        Name = ValueTypestring,
        MonsterHead = ValueTypestring,
        NotOpenName = ValueTypestring,
    },
    XTableSailikaAnim = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ConditionId = ValueTypeint,
        ConditionParam = ValueTypeint,
        CvContent = ValueTypestring,
        CvId = ValueTypeint,
        ActionId = ValueTypestring,
        Priority = ValueTypeint,
        CoolTime = ValueTypeint,
        Duration = ValueTypefloat,
        EffectPath = ValueTypestring,
        Weight = ValueTypeint,
    },
    XTableSameColorBallBuffEffectShow = {
        BuffType = ValueTypeintPrimaryKey,
        EffectUrl = ValueTypestring,
    },
    XTableSameColorGameActivity = {
        Id = ValueTypeintPrimaryKey,
        TimerId = ValueTypeint,
        MaxSkillCount = ValueTypeint,
    },
    XTableSameColorGameAttributeFactor = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Factor = ValueTypefloat,
    },
    XTableSameColorGameAttributeType = {
        Type = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        BossDesc = ValueTypestring,
    },
    XTableSameColorGameBall = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Color = ValueTypeint,
        Score = ValueTypeint,
        Icon = ValueTypestring,
        WeakIcons = Type1ValueTypestring,
        Bg = ValueTypestring,
        WeakHitTimes = ValueTypeint,
        WeakMaxCount = ValueTypeint,
        Desc = ValueTypestring,
        PropType = ValueTypeint,
        SkillId = ValueTypeint,
        PropEffectTime = ValueTypeint,
        WeakBuffIds = Type1ValueTypeint,
    },
    XTableSameColorGameBoss = {
        Id = ValueTypeintPrimaryKey,
        TimerId = ValueTypeint,
        RoleId = ValueTypeint,
        ConditionId = ValueTypeint,
        PreBossId = ValueTypeint,
        PreBossUnlockTips = ValueTypestring,
        MaxRound = ValueTypeint,
        MaxTime = ValueTypeint,
        Name = ValueTypestring,
        ModelId = ValueTypestring,
        BattleModelId = ValueTypestring,
        FullBodyIcon = ValueTypestring,
        SuggestRoleIds = Type1ValueTypestring,
        ShowSkillIds = Type1ValueTypeint,
        NameIcon = ValueTypestring,
        NameEnIcon = ValueTypestring,
        AttributeType = ValueTypeint,
    },
    XTableSameColorGameBossGrade = {
        Id = ValueTypeintPrimaryKey,
        BossId = ValueTypeint,
        Damage = ValueTypeint,
        Grade = ValueTypeint,
        GradeName = ValueTypestring,
    },
    XTableSameColorGameBossSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        BossId = ValueTypeint,
        TriggerRound = ValueTypeint,
        SkipDamage = ValueTypeint,
        BuffId = Type1ValueTypeint,
        SubEnergyType = ValueTypeint,
        SubEnergyCount = ValueTypeint,
        WeakBallIds = Type1ValueTypeint,
    },
    XTableSameColorGameBuff = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        Step = ValueTypeint,
        Time = ValueTypeint,
        TargetColors = Type1ValueTypeint,
        TargetBallIds = Type1ValueTypeint,
        Duration = ValueTypeint,
        DurationTime = ValueTypeint,
        DamagePercent = ValueTypeint,
        AddEnergy = ValueTypeint,
        AddEnergyLimit = ValueTypeint,
        ChangeColorCount = ValueTypeint,
    },
    XTableSameColorGameCfg = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableSameColorGameCombo = {
        Id = ValueTypeintPrimaryKey,
        Percent = ValueTypeint,
    },
    XTableSameColorGamePassiveSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        TriggerRate = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableSameColorGameRole = {
        Id = ValueTypeintPrimaryKey,
        TimerId = ValueTypeint,
        ShopItemId = ValueTypeint,
        ConditionId = ValueTypeint,
        Row = ValueTypeint,
        Col = ValueTypeint,
        BallId = Type1ValueTypeint,
        SkillId = ValueTypeint,
        PassiveSkillId = ValueTypeint,
        CharacterId = ValueTypeint,
        ModelId = ValueTypestring,
        BattleModelId = ValueTypestring,
        ConsumeId = ValueTypeint,
        ConsumeCount = ValueTypeint,
        EnergyInit = ValueTypeint,
        EnergyLimit = ValueTypeint,
        ComboAddEnergy = ValueTypeint,
        AddEnergyStartRound = Type1ValueTypeint,
        RoundAddEnergyType = Type1ValueTypeint,
        RoundAddEnergyCount = Type1ValueTypeint,
        NameIcon = ValueTypestring,
        NameEnIcon = ValueTypestring,
        AttributeFactorId = ValueTypeint,
        PropBallIds = Type1ValueTypeint,
    },
    XTableSameColorGameScore = {
        Id = ValueTypeintPrimaryKey,
        Score = ValueTypeint,
    },
    XTableSameColorGameSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        BuffId = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        Desc = ValueTypestring,
        DescTimeType = ValueTypestring,
        Icon = ValueTypestring,
        ScreenMaskType = ValueTypeint,
        ControlType = ValueTypeint,
        ShowCountdown = ValueTypeint,
        HintText = ValueTypestring,
        HintTextTimeType = ValueTypestring,
        EnergyCost = ValueTypeint,
        AddEnergyType = ValueTypeint,
        AddEnergyCount = ValueTypeint,
        SkillParam = ValueTypeint,
        SkillParams = Type1ValueTypeint,
        ScoreFactor = ValueTypefloat,
        LowerLimit = ValueTypeint,
        UpperLimit = ValueTypeint,
        SkillComboType = ValueTypeint,
        SkillAttributeFactor = ValueTypefloat,
    },
    XTableSameColorGameSkillGroup = {
        Id = ValueTypeintPrimaryKey,
        ShopItemId = ValueTypeint,
        Cd = ValueTypeint,
        SkillId = ValueTypeint,
        OnSkillId = ValueTypeint,
        LimitTime = ValueTypeint,
    },
    XTableSameColorSkillEffectShow = {
        SkillId = ValueTypeintPrimaryKey,
        BeforeRemoveEffectType = ValueTypeint,
        BeforeRemoveEffect = Type1ValueTypestring,
        RemoveEffectType = ValueTypeint,
        RemoveEffect = Type1ValueTypestring,
        ChangeBallEffectType = ValueTypeint,
        ChangeBallEffect = Type1ValueTypestring,
        BallRemoveEffect = Type1ValueTypestring,
        PropEffect = Type1ValueTypestring,
        Shape = ValueTypeint,
    },
    XTableSameNpcGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        NpcId = Type1ValueTypeint,
    },
    XTableScene = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SceneType = ValueTypeint,
        SceneUrl = ValueTypestring,
        GlobalIllumination = ValueTypestring,
        CacheTime = ValueTypeint,
    },
    XTableSceneModel = {
        Id = ValueTypeintPrimaryKey,
        ScenePath = ValueTypestring,
        ModelPath = ValueTypestring,
    },
    XTableScoreScreenTag = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableScoreTitle = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        ScreenType = ValueTypeint,
        ActivityId = ValueTypeint,
        TimeId = ValueTypeint,
        ExtraParams = Type1ValueTypeint,
        InitQuality = ValueTypeint,
        QualityConditions = Type1ValueTypeint,
        Qualities = Type1ValueTypeint,
        Condition = ValueTypeint,
        Name = ValueTypestring,
        MainDesc = ValueTypestring,
        WorldDesc = ValueTypestring,
        Hint = Type1ValueTypestring,
        ExpandInfoId = Type1ValueTypeint,
        GetDesc = ValueTypestring,
        Priority = ValueTypeint,
        ShowType = ValueTypeint,
        ShowScore = ValueTypeint,
        ShowQualityUpTip = ValueTypeint,
        IsNotShowGetTip = ValueTypeint,
        Medal3D = ValueTypestring,
        MedalImg = ValueTypestring,
        MedalIcon = ValueTypestring,
        ScoreParams = Type1ValueTypestring,
        GroupId = ValueTypeint,
        GroupLv = ValueTypeint,
        ShowMaxLevel = ValueTypeint,
        PrefabPath = ValueTypestring,
    },
    XTableScoreTitleActivityExtra = {
        Id = ValueTypeint,
        ActivityId = Type1ValueTypeint,
    },
    XTableScoreTitleExpandInfo = {
        Id = ValueTypeintPrimaryKey,
        StrServerKey = ValueTypestring,
        Desc = ValueTypestring,
        EmptyDesc = ValueTypestring,
    },
    XTableScoreTitleItem = {
        Id = ValueTypeint,
        TitleId = ValueTypeint,
    },
    XTableScoreTowerActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        CountScoreTime = ValueTypeint,
        RankGroupId = ValueTypeint,
        RankOpenTimeId = ValueTypeint,
        RankOpenConditions = Type1ValueTypeint,
    },
    XTableScoreTowerChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        TowerIds = Type1ValueTypeint,
        ChapterIdCondition = ValueTypeint,
        ScoreCondition = ValueTypeint,
        ChapterName = ValueTypestring,
        RobotGroupId = ValueTypeint,
    },
    XTableScoreTowerCharGroup = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        CharacterIds = Type1ValueTypeint,
    },
    XTableScoreTowerCharTag = {
        Id = ValueTypeintPrimaryKey,
        TagIds = Type2KeyTypeintValueTypeint,
    },
    XTableScoreTowerClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Params = Type1ValueTypestring,
    },
    XTableScoreTowerFloor = {
        Id = ValueTypeintPrimaryKey,
        TowerId = ValueTypeint,
        FloorName = ValueTypestring,
        PreFloorId = ValueTypeint,
        SweepChapterIdCondition = ValueTypeint,
        SweepScoreCondition = ValueTypeint,
        RewardId = ValueTypeint,
        BgImgUrl = ValueTypestring,
    },
    XTableScoreTowerMonsterGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        MonsterIds = Type1ValueTypeint,
        Atk = ValueTypeint,
        Hp = ValueTypeint,
    },
    XTableScoreTowerPlug = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        NeedPoint = ValueTypeint,
        Desc = ValueTypestring,
        Name = ValueTypestring,
        PlugImg = ValueTypestring,
        PlugVideo = ValueTypestring,
    },
    XTableScoreTowerPlugPoint = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypestring,
        Point = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableScoreTowerRankGroup = {
        Id = ValueTypeintPrimaryKey,
        RankGroupId = ValueTypeint,
        SettlePointIndex = ValueTypeint,
        SettleTimeId = ValueTypeint,
        RewardGroupId = ValueTypeint,
    },
    XTableScoreTowerRankReward = {
        Id = ValueTypeintPrimaryKey,
        RewardGroupId = ValueTypeint,
        Rank = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableScoreTowerRobot = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        RobotId = ValueTypeint,
    },
    XTableScoreTowerStage = {
        Id = ValueTypeintPrimaryKey,
        FloorId = ValueTypeint,
        StageType = ValueTypeint,
        CharacterNum = ValueTypeint,
        StageId = ValueTypeint,
        SweepAverFaRequire = ValueTypeint,
        MonsterGroupIds = Type1ValueTypeint,
        Weakness = ValueTypeint,
        PlugPointIds = Type1ValueTypeint,
        IsFinalBoss = ValueTypebool,
        BossPlugIds = Type1ValueTypeint,
        BossAffixEvent = Type1ValueTypeint,
        BossFightTime = ValueTypeint,
        BossFightScore = Type1ValueTypeint,
        MaxPlugPoint = ValueTypeint,
        BossIcon = ValueTypestring,
        BossHeadIcon = ValueTypestring,
    },
    XTableScoreTowerStrengthen = {
        Id = ValueTypeintPrimaryKey,
        BelongChapter = ValueTypeint,
        Slot = ValueTypeint,
        BuffLv = Type1ValueTypeint,
        BuffLvRate = Type1ValueTypestring,
        BuffLvCost = Type1ValueTypeint,
        BuffPower = Type1ValueTypeint,
    },
    XTableScoreTowerTag = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableScoreTowerTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TaskIds = Type1ValueTypeint,
    },
    XTableScoreTowerTower = {
        Id = ValueTypeintPrimaryKey,
        TowerName = ValueTypestring,
        UnlockTowerId = ValueTypeint,
        CharacterNum = ValueTypeint,
        SweepCount = ValueTypeint,
        SuggestCharGroup = ValueTypeint,
        SuggestTagType = Type1ValueTypeint,
        SuggestTagCount = Type1ValueTypeint,
        IsRanking = ValueTypebool,
    },
    XTableScratchTicket = {
        Id = ValueTypeintPrimaryKey,
        WinRewardItemId = ValueTypeint,
        WinRewardItemNum = ValueTypeint,
        LoseRewardItemId = ValueTypeint,
        LoseRewardItemNum = ValueTypeint,
        WinRewardId = ValueTypeint,
        LoseRewardId = ValueTypeint,
        GridIds = Type1ValueTypeint,
    },
    XTableScratchTicketActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        IsCanReset = ValueTypebool,
        PreviewCount = ValueTypeint,
        SpendItemCount = ValueTypeint,
        SpendItemId = ValueTypeint,
        GoldRewardItemId = ValueTypeint,
        GoldRewardItemNum = ValueTypeint,
        ScratchTicket = Type1ValueTypeint,
        OpenTimeId = ValueTypeint,
    },
    XTableScratchTicketChose = {
        Id = ValueTypeintPrimaryKey,
        GridIndex = Type1ValueTypeint,
    },
    XTableScratchTicketGrid = {
        Id = ValueTypeintPrimaryKey,
        LuckNumber = ValueTypeint,
        Num = Type1ValueTypeint,
        CorrectChose = Type1ValueTypeint,
    },
    XTableScreenEffect = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        SortOrder = ValueTypeint,
        PlayAlone = ValueTypebool,
        SyncNpcTimescale = ValueTypebool,
        Hash = ValueTypeint,
    },
    XTableScreenFilter = {
        FilterId = ValueTypeintPrimaryKey,
        LutTexture = ValueTypestring,
        TileSize = ValueTypeint,
        ScreenEffectId = ValueTypeint,
        Comment = ValueTypestring,
    },
    XTableSecondaryFunctional = {
        Id = ValueTypeintPrimaryKey,
        Priority = ValueTypeint,
        Name = ValueTypestring,
        Activate = ValueTypeint,
        OpenId = ValueTypeint,
        Picture = ValueTypestring,
        Redirection = ValueTypestring,
        Cover = ValueTypestring,
        Click = ValueTypestring,
    },
    XTableSection = {
        SectionId = ValueTypeint,
        SectionName = ValueTypestring,
        Icon = ValueTypestring,
        OrderId = ValueTypeint,
        StageId = Type1ValueTypeint,
        TreasureId = Type1ValueTypeint,
        PosX = ValueTypefloat,
        PosY = ValueTypefloat,
    },
    XTableSentence = {
        SentenceId = ValueTypeint,
        OptionId = ValueTypeint,
        PlayTime = ValueTypefloat,
        BackgroundMusic = ValueTypestring,
        DialogSoundEffect = ValueTypestring,
        DialogSoundMusic = ValueTypestring,
        RoleId = ValueTypeint,
        RoleName = ValueTypestring,
        IsNewRole = ValueTypebool,
        PositionType = ValueTypeint,
        RoleIcon = Type2KeyTypeintValueTypestring,
        RoleEffect = Type2KeyTypeintValueTypestring,
        IsForce = ValueTypebool,
        BgAimation = ValueTypestring,
        InAnimation = Type2KeyTypeintValueTypestring,
        OutAnimation = Type2KeyTypeintValueTypestring,
        BackgroundEffect = ValueTypestring,
        DialogBgImg = ValueTypestring,
        BackgroundImg = ValueTypestring,
        BackgroundImg2 = ValueTypestring,
        Content = ValueTypestring,
    },
    XTableSettleLoseTip = {
        Id = ValueTypeintPrimaryKey,
        TipDesc = Type1ValueTypestring,
        SkipId = Type1ValueTypeint,
    },
    XTableSGCafeActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        StoryChapterId = ValueTypeint,
        ChallengeChapterId = ValueTypeint,
    },
    XTableSGCafeBuffList = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        EffectIds = Type1ValueTypeint,
    },
    XTableSGCafeChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        StageIds = Type1ValueTypeint,
    },
    XTableSGCafeCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        FuncType = ValueTypeint,
        Desc = ValueTypestring,
        Note = ValueTypestring,
        Params = Type1ValueTypeint,
    },
    XTableSGCafeConfig = {
        Id = ValueTypestringPrimaryKey,
        Value = ValueTypestring,
        Note = ValueTypestring,
    },
    XTableSGCafeCustomer = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Details = ValueTypestring,
        Desc = ValueTypestring,
        WorldDesc = ValueTypestring,
        Quality = ValueTypeint,
        Priority = ValueTypeint,
        Icon = ValueTypestring,
        SmallIcon = ValueTypestring,
        Coffee = ValueTypeint,
        Review = ValueTypeint,
        IsReDraw = ValueTypebool,
        DefaultNum = ValueTypeint,
        NpcId = ValueTypeint,
        IsShow = ValueTypebool,
        UseConditions = Type1ValueTypeint,
        Tags = Type1ValueTypeint,
        Effects = Type1ValueTypeint,
        UnlockDesc = ValueTypestring,
    },
    XTableSGCafeCustomerGenerate = {
        Id = ValueTypeintPrimaryKey,
        IsOrder = ValueTypebool,
        Note = ValueTypestring,
        CustomerIds = Type1ValueTypeint,
    },
    XTableSGCafeCustomerGroup = {
        Id = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        GenerateIds = Type1ValueTypeint,
    },
    XTableSGCafeCustomerPreset = {
        Id = ValueTypeintPrimaryKey,
        CustomerIds = Type1ValueTypeint,
    },
    XTableSGCafeEffect = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Trigger = ValueTypeint,
        Conditions = Type1ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableSGCafeNpcShow = {
        LevelNpcBaseId = ValueTypeintPrimaryKey,
        SettleEmoji = ValueTypestring,
        DefaultPosId = ValueTypeint,
        ClickText = Type1ValueTypestring,
    },
    XTableSGCafePosition = {
        Id = ValueTypeintPrimaryKey,
        SpotId = ValueTypeint,
        Area = ValueTypeint,
        CoffeeOffsetX = ValueTypefloat,
        CoffeeOffsetY = ValueTypefloat,
        ReviewOffsetX = ValueTypefloat,
        ReviewOffsetY = ValueTypefloat,
        EmojiOffsetX = ValueTypefloat,
        EmojiOffsetY = ValueTypefloat,
    },
    XTableSGCafeRoute = {
        Id = ValueTypeintPrimaryKey,
        RouteId = ValueTypeint,
    },
    XTableSGCafeStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        PreStage = ValueTypeint,
        Condition = ValueTypeint,
        IsKickOutCafe = ValueTypebool,
        Rounds = ValueTypeint,
        CustomerGroup = ValueTypeint,
        IsSingleGenerate = ValueTypebool,
        Review = ValueTypebool,
        InitReview = ValueTypeint,
        IsReDraw = ValueTypebool,
        ActPoint = ValueTypeint,
        MaxCustomer = ValueTypeint,
        BuffListId = ValueTypeint,
        Target = Type1ValueTypeint,
        Reward = Type1ValueTypeint,
        RewardCard = Type1ValueTypeint,
    },
    XTableSGCafeTag = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableSgDormArea = {
        AreaType = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        MaxFurnitureCount = ValueTypeint,
        DefaultLayoutId = ValueTypeint,
    },
    XTableSgDormConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableSgDormFashion = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ConvertItemId = ValueTypeint,
        ConvertItemCount = ValueTypeint,
        IsDefault = ValueTypebool,
        Icon = ValueTypestring,
        SmallIcon = ValueTypestring,
        Quality = ValueTypeint,
        Priority = ValueTypeint,
        SkinId = ValueTypeint,
        Desc = ValueTypestring,
        WorldDesc = ValueTypestring,
        LockDesc = ValueTypestring,
    },
    XTableSgDormFurniture = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TypeId = ValueTypeint,
        MaxCount = ValueTypeint,
        ConvertItemId = ValueTypeint,
        ConvertItemCount = ValueTypeint,
        PutMajorType = Type1ValueTypeint,
        PutCapacity = Type1ValueTypeint,
        Icon = ValueTypestring,
        SmallIcon = ValueTypestring,
        Quality = ValueTypeint,
        Priority = ValueTypeint,
        SceneObjId = ValueTypeint,
        Desc = ValueTypestring,
        WorldDesc = ValueTypestring,
        LockDesc = ValueTypestring,
        IsShow = ValueTypebool,
    },
    XTableSgDormFurnitureHandbook = {
        FurnitureId = ValueTypeintPrimaryKey,
        HandbookType = ValueTypeint,
        Priority = ValueTypeint,
        Scale = ValueTypeint,
        RotationX = ValueTypefloat,
        RotationY = ValueTypefloat,
        PositionY = ValueTypeint,
    },
    XTableSgDormFurnitureHandbookType = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Priority = ValueTypeint,
    },
    XTableSgDormFurnitureType = {
        Id = ValueTypeintPrimaryKey,
        AreaType = ValueTypeint,
        IsContainer = ValueTypebool,
        Icon = ValueTypestring,
        Priority = ValueTypeint,
        MajorType = ValueTypeint,
        MajorName = ValueTypestring,
        MinorType = ValueTypeint,
        MinorName = ValueTypestring,
    },
    XTableSgDormLayout = {
        Id = ValueTypeintPrimaryKey,
        AreaType = ValueTypeint,
        DefaultContainer = ValueTypeint,
        Name = ValueTypestring,
        DefaultIcon = ValueTypestring,
    },
    XTableSgDroneGameChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        TimeId = ValueTypeint,
        Condition = ValueTypeint,
        TeachDroneId = ValueTypeint,
        HardModeText = ValueTypestring,
        EasyDroneHp = ValueTypeint,
        IsEnableAssistance = ValueTypebool,
        IconUrl = ValueTypestring,
        StageIds = Type1ValueTypeint,
    },
    XTableSgDroneGameConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableSgDroneGameDialogue = {
        Id = ValueTypeintPrimaryKey,
        TriggerTag = ValueTypestring,
        Type = ValueTypeint,
        Delay = ValueTypefloat,
        Priority = ValueTypeint,
        HeadIcon = ValueTypestring,
        Duration = ValueTypefloat,
        AudioKey = ValueTypestring,
        Dialogue = Type1ValueTypestring,
    },
    XTableSgDroneGameDroneDisplay = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        TeachingVideoId = ValueTypeint,
    },
    XTableSgDroneGameStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        PreStageId = ValueTypeint,
        Condition = ValueTypeint,
        MapId = ValueTypeint,
        SkipId = ValueTypeint,
        IsFirst = ValueTypebool,
        ObjectiveId = ValueTypeint,
        IconUrl = ValueTypestring,
        StarTargets = Type1ValueTypeint,
        StarRewardIds = Type1ValueTypeint,
    },
    XTableSgDroneGameStarTarget = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        ProgressDesc = ValueTypestring,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableSgStreetArea = {
        Id = ValueTypeintPrimaryKey,
        PlaceId = ValueTypeint,
    },
    XTableSgStreetBgmSection = {
        Id = ValueTypeintPrimaryKey,
        Satisfaction = ValueTypeint,
        CustomerNum = ValueTypeint,
        BgmSection = ValueTypeint,
    },
    XTableSgStreetBillboard = {
        Id = ValueTypeintPrimaryKey,
        EffectId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Res = ValueTypestring,
        TaskId = ValueTypeint,
        TaskFinishNeedRemoveBuff = ValueTypebool,
        RestrictBuff = Type1ValueTypeint,
        RewardBuff = Type1ValueTypeint,
    },
    XTableSgStreetBillboardGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        BillboardId = ValueTypeint,
        Weigh = ValueTypeint,
        RepeatWeigh = ValueTypeint,
        AddWeighCondition = Type1ValueTypeint,
        AddWeigh = Type1ValueTypeint,
    },
    XTableSgStreetBuff = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        ShowType = ValueTypeint,
        GetShowType = ValueTypeint,
        ConditionId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        BgColor = ValueTypestring,
        Duration = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableSgStreetConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
        Note = ValueTypestring,
    },
    XTableSgStreetCustomer = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        HeadIcon = ValueTypestring,
    },
    XTableSgStreetCustomerEventEmergency = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        OptionDescs = Type1ValueTypestring,
        OptionBuffs = Type1ValueTypeint,
        SpOptionBuffs = Type1ValueTypeint,
    },
    XTableSgStreetCustomerEventEmergencyRandom = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        EventId = ValueTypeint,
        FirstWeight = ValueTypeint,
        SelectedWeight = ValueTypeint,
        AddWeightConditions = Type1ValueTypeint,
        AddWeights = Type1ValueTypeint,
    },
    XTableSgStreetCustomerEventNum = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        CustomerNum = ValueTypeint,
        DiscontentNum = ValueTypeint,
        EmergencyNum = ValueTypeint,
        FoodFeedbackNum = ValueTypeint,
        GroceryFeedbackNum = ValueTypeint,
        DessertFeedbackNum = ValueTypeint,
        FoodNegativeFeedbackNum = ValueTypeint,
        GroceryNegativeFeedbackNum = ValueTypeint,
        DessertNegativeFeedbackNum = ValueTypeint,
    },
    XTableSgStreetCustomerEventNumLimit = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Type = ValueTypeint,
        ShopNum = ValueTypeint,
        EventNumLimit = ValueTypeint,
    },
    XTableSgStreetCustomerParam = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        FoodGoodsLikeRandom = ValueTypeint,
        FoodGoldLikeRandom = ValueTypeint,
        GroceryGoldLikeRandom = ValueTypeint,
        DessertGoldLikeRandom = ValueTypeint,
        FoodFeedbackGroup = ValueTypeint,
        GroceryFeedbackGroup = ValueTypeint,
        DessertFeedbackGroup = ValueTypeint,
        CustomerHeadIconGroup = ValueTypeint,
        FoodFeedbackBadGroup = ValueTypeint,
        GroceryFeedbackBadGroup = ValueTypeint,
        DessertFeedbackBadGroup = ValueTypeint,
    },
    XTableSgStreetCustomerShopScore = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Value = ValueTypeint,
        Score = ValueTypeint,
        Note = ValueTypestring,
    },
    XTableSgStreetCustomerShopScoreFactor = {
        Id = ValueTypeintPrimaryKey,
        ShopScore = ValueTypeint,
        Factor = ValueTypeint,
    },
    XTableSgStreetEnvironmentSatisfaction = {
        Id = ValueTypeintPrimaryKey,
        Environment = ValueTypeint,
        Satisfaction = ValueTypeint,
    },
    XTableSgStreetFeedback = {
        Id = ValueTypeintPrimaryKey,
        FeedbackType = ValueTypeint,
        Desc = Type1ValueTypestring,
        Desc2 = ValueTypestring,
        IconGroupId = ValueTypeint,
        DiffScope = ValueTypeint,
        StarType = ValueTypeint,
        Star = ValueTypeint,
        IsFull = ValueTypebool,
        GoodsId = ValueTypeint,
    },
    XTableSgStreetFeedbackBadNum = {
        Id = ValueTypeintPrimaryKey,
        Score = ValueTypeint,
        FeedbackBadNum = ValueTypeint,
    },
    XTableSgStreetFeedbackGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        FeedbackType = ValueTypeint,
        Weigh = ValueTypeint,
        RepeatWeigh = ValueTypeint,
    },
    XTableSgStreetFeedbackIconGroup = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        HeadIcon = ValueTypestring,
    },
    XTableSgStreetFeedbackType = {
        FeedbackType = ValueTypeintPrimaryKey,
        FeedbackAttitude = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableSgStreetGrapevine = {
        Id = ValueTypeintPrimaryKey,
        GrapevineType = ValueTypeint,
        Weight = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableSgStreetGrapevineGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        TurnValue = ValueTypeint,
        Probability = ValueTypeint,
        FoodRandomGroup = ValueTypeint,
        GroceryRandomGroup = ValueTypeint,
        DessertRandomGroup = ValueTypeint,
    },
    XTableSgStreetGrapevineRandomGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        GrapevineType = ValueTypeint,
        Weight = ValueTypeint,
        RepeatWeight = ValueTypeint,
        AddWeightCondition = Type1ValueTypeint,
        AddWeight = Type1ValueTypeint,
    },
    XTableSgStreetInsideShopDessert = {
        Id = ValueTypeintPrimaryKey,
        InitGold = ValueTypeint,
        GoldMin = ValueTypeint,
        GoldMax = ValueTypeint,
        FeedbackImgGroup = ValueTypestring,
        Goods = Type1ValueTypeint,
    },
    XTableSgStreetInsideShopDessertGoods = {
        Id = ValueTypeintPrimaryKey,
        GoodsRes = ValueTypestring,
        GoodsName = ValueTypestring,
        GoodsIcon = ValueTypestring,
    },
    XTableSgStreetInsideShopFood = {
        Id = ValueTypeintPrimaryKey,
        InitGold = ValueTypeint,
        GoldMin = ValueTypeint,
        GoldMax = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        FeedbackImgGroup = ValueTypestring,
        Goods = Type1ValueTypeint,
        Chef = Type1ValueTypeint,
    },
    XTableSgStreetInsideShopFoodChef = {
        Id = ValueTypeintPrimaryKey,
        ChefName = ValueTypestring,
        ChefIcon = ValueTypestring,
        ImgPath = ValueTypestring,
    },
    XTableSgStreetInsideShopFoodGoods = {
        Id = ValueTypeintPrimaryKey,
        GoodsInit = ValueTypeint,
        GoodsMin = ValueTypeint,
        GoodsMax = ValueTypeint,
        GoodsRes = ValueTypestring,
        GoodsName = ValueTypestring,
        GoodsIcon = ValueTypestring,
        ImgPathGroup = Type1ValueTypestring,
    },
    XTableSgStreetInsideShopGrocery = {
        Id = ValueTypeintPrimaryKey,
        ShelfNum = ValueTypeint,
        InitGold = ValueTypeint,
        GoldMin = ValueTypeint,
        GoldMax = ValueTypeint,
        FeedbackImgGroup = ValueTypestring,
        Goods = Type1ValueTypeint,
    },
    XTableSgStreetInsideShopGroceryGoods = {
        Id = ValueTypeintPrimaryKey,
        GoldInit = ValueTypeint,
        GoldMin = ValueTypeint,
        GoldMax = ValueTypeint,
        GoodsRes = ValueTypestring,
        GoodsName = ValueTypestring,
        GoodsIcon = ValueTypestring,
    },
    XTableSgStreetMascot = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Condition = ValueTypeint,
        Weigh = ValueTypeint,
        IsRepeat = ValueTypeint,
        RepeatWeigh = ValueTypeint,
        MoodId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableSgStreetNews = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Buff = Type1ValueTypeint,
    },
    XTableSgStreetNewsGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        NewsId = ValueTypeint,
        Weigh = ValueTypeint,
        RepeatWeigh = ValueTypeint,
        AddWeighCondition = Type1ValueTypeint,
        AddWeigh = Type1ValueTypeint,
    },
    XTableSgStreetNewsTypeGroup = {
        Id = ValueTypeintPrimaryKey,
        TypeGroupId = ValueTypeint,
        NeedSatisfaction = ValueTypeint,
        GroupId = Type1ValueTypeint,
        Weigh = Type1ValueTypeint,
        NewsType = Type1ValueTypeint,
    },
    XTableSgStreetOutSideShopBuildCondition = {
        Id = ValueTypeintPrimaryKey,
        BuildNum = ValueTypeint,
        NeedSatisfaction = ValueTypeint,
    },
    XTableSgStreetPromotion = {
        Id = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        FashionDesc = ValueTypestring,
        Type = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        DescParam = Type1ValueTypeint,
        DescParamIndex = Type1ValueTypeint,
    },
    XTableSgStreetPromotionRandom = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        PromotionId = ValueTypeint,
        FirstWeight = ValueTypeint,
        RepeatWeight = ValueTypeint,
        SelectedWeight = ValueTypeint,
        AddWeightConditions = Type1ValueTypeint,
        AddWeights = Type1ValueTypeint,
    },
    XTableSgStreetResource = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        MaxCount = ValueTypeint,
    },
    XTableSgStreetResString = {
        Id = ValueTypeintPrimaryKey,
    },
    XTableSgStreetReview = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableSgStreetReviewDistribution = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        NeedSatisfaction = ValueTypeint,
        GoodReviewNum = ValueTypeint,
        BadReviewNum = ValueTypeint,
    },
    XTableSgStreetReviewGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        StreetReviewId = ValueTypeint,
        Condition = ValueTypeint,
        Weigh = ValueTypeint,
        RepeatWeigh = ValueTypeint,
    },
    XTableSgStreetSatisfactionFactor = {
        Id = ValueTypeintPrimaryKey,
        ShopNum = ValueTypeint,
        Factor = ValueTypeint,
    },
    XTableSgStreetShop = {
        Id = ValueTypeintPrimaryKey,
        Cost = ValueTypeint,
        MainType = ValueTypeint,
        SubType = ValueTypeint,
        SortType = ValueTypeint,
        FuncType = ValueTypeint,
        Condition = ValueTypeint,
        ShopResId = ValueTypeint,
        BuffShowId = ValueTypeint,
        Desc = ValueTypestring,
        AccountDesc = ValueTypestring,
        StrategyDesc = ValueTypestring,
        Name = ValueTypestring,
        Prefab = ValueTypestring,
        SignboardImg = ValueTypestring,
        BuildPromotionGroupId = ValueTypeint,
        TurnPromotionGroupId = ValueTypeint,
        EventEmergencyGroupId = ValueTypeint,
    },
    XTableSgStreetShopAttr = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Sort = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableSgStreetShopFactorStar = {
        Id = ValueTypeintPrimaryKey,
        CustomerFactor = Type1ValueTypeint,
        CustomerFactorStar = Type1ValueTypeint,
    },
    XTableSgStreetShopLv = {
        Id = ValueTypeintPrimaryKey,
        ShopId = ValueTypeint,
        Level = ValueTypeint,
        BuffId = ValueTypeint,
        ShowLevel = ValueTypeint,
        Cost = ValueTypeint,
        Condition = ValueTypeint,
        NeedCustomerNum = ValueTypeint,
        CustomerFactorStar = ValueTypeint,
        CustomerFactor = ValueTypeint,
        RecommendCustomerFactor = ValueTypeint,
        CustomerNumFixed = ValueTypeint,
        CustomerNumMultiple = ValueTypeint,
        EnvironmentFixed = ValueTypeint,
        EnvironmentMultiple = ValueTypeint,
        AwardGold = ValueTypeint,
        UpgradeBranch = Type1ValueTypeint,
        ActiveNode = Type1ValueTypeint,
        Prefab = ValueTypestring,
        Note = ValueTypestring,
    },
    XTableSgStreetShopLvBranchAdd = {
        Id = ValueTypeintPrimaryKey,
        AttrTypes = Type1ValueTypeint,
        AttrValues = Type1ValueTypeint,
        ShopAttrTypes = Type1ValueTypeint,
        ShopAttrValues = Type1ValueTypeint,
        Note = ValueTypestring,
    },
    XTableSgStreetShopScoreSatisfaction = {
        Id = ValueTypeintPrimaryKey,
        ShopScore = ValueTypeint,
        Satisfaction = ValueTypeint,
    },
    XTableSgStreetStage = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Condition = ValueTypeint,
        InitGold = ValueTypeint,
        InitCustomerNum = ValueTypeint,
        InitEnvironment = ValueTypeint,
        RewardId = ValueTypeint,
        PromotionInterval = ValueTypeint,
        MascotGroupId = ValueTypeint,
        MascotLikeGroupId = ValueTypeint,
        MaxTurn = ValueTypeint,
        BillboardGroup = ValueTypeint,
        NewsTypeGroup = ValueTypeint,
        GrapevineGroup = ValueTypeint,
        ReviewDistributionGroup = ValueTypeint,
        ReviewGoodGroup = ValueTypeint,
        ReviewBadGroup = ValueTypeint,
        CustomerParamId = ValueTypeint,
        DiscontentAwardGold = ValueTypeint,
        CustomerEventNumGroupId = ValueTypeint,
        IsFinishExit = ValueTypebool,
        Desc = ValueTypestring,
        Name = ValueTypestring,
        TargetTaskIds = Type1ValueTypeint,
        TargetTaskRewards = Type1ValueTypeint,
        CustomerEventNumLimitGroupId = Type1ValueTypeint,
    },
    XTableSgStreetStageDesc = {
        Id = ValueTypeintPrimaryKey,
        FeedbackParam = Type1ValueTypeint,
        GrapevineParam = Type1ValueTypeint,
        GrapevineIndexParam = Type1ValueTypeint,
    },
    XTableSgStreetStageRes = {
        Id = ValueTypeintPrimaryKey,
        ValueType = ValueTypeint,
        IsShopAttr = ValueTypeint,
        AttrId = ValueTypeint,
        BuffCalId = ValueTypeint,
        Div = ValueTypeint,
        IsSp = ValueTypebool,
        HasBubble = ValueTypebool,
        FormatStr = ValueTypestring,
        BubbleDesc = ValueTypestring,
        Desc = ValueTypestring,
        Name = ValueTypestring,
        InitKey = ValueTypestring,
        Icon = ValueTypestring,
        IconColor = ValueTypestring,
        Color = ValueTypestring,
        AttrKey = ValueTypestring,
    },
    XTableSgStreetStageShop = {
        Id = ValueTypeintPrimaryKey,
        InsideShopGroup = Type1ValueTypeint,
        OutsideShopGroup = Type1ValueTypeint,
        InitShop = Type1ValueTypeint,
        InitShopPos = Type1ValueTypeint,
        LockInsidePos = Type1ValueTypeint,
        LockOutsidePos = Type1ValueTypeint,
    },
    XTableSgStreetTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        AccountDesc = ValueTypestring,
        ConditionDesc = ValueTypestring,
        ConditionSampleDesc = ValueTypestring,
        ConditionType = ValueTypeint,
        Schedule = ValueTypeint,
        ScheduleDiv = ValueTypeint,
        ConditionParams = Type1ValueTypeint,
    },
    XTableSharePaltformConfig = {
        Id = ValueTypestring,
        SdkId = Type1ValueTypestring,
    },
    XTableShieldFunc = {
        Id = ValueTypeintPrimaryKey,
        UiName = Type1ValueTypestring,
    },
    XTableShop = {
        Id = ValueTypeint,
        Owner = ValueTypeint,
        Type = ValueTypeint,
        SecondType = ValueTypeint,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        ShowId = Type1ValueTypeint,
        StartTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
        Kind = ValueTypeint,
        GoodsBuyTimesLimit = ValueTypeint,
        ManualResetTimesLimit = ValueTypeint,
        ResetCostId = ValueTypeint,
        ResetCostCountStr = ValueTypestring,
        AutoResetClockId = ValueTypeint,
        TargetId = Type1ValueTypeint,
        IsResetManualTimes = ValueTypebool,
        IsAddSelloutGoods = ValueTypebool,
        IsUnShelve = ValueTypebool,
        ConditionId = Type1ValueTypeint,
        ScreenGroup = Type1ValueTypeint,
        RefreshTips = ValueTypestring,
        ActivityId = ValueTypeint,
    },
    XTableShopActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeLimitCtrlId = ValueTypeint,
        IsNeedHideCountdown = ValueTypebool,
    },
    XTableShopBuyLimitLabel = {
        ClockId = ValueTypeintPrimaryKey,
        TextLimitLabel = ValueTypestring,
    },
    XTableShopDetail = {
        Id = ValueTypeintPrimaryKey,
        IsNeedFirstBluePoint = ValueTypebool,
        ShopBtnRedPointConditions = Type1ValueTypestring,
    },
    XTableShopGroup = {
        Id = ValueTypeintPrimaryKey,
        TagName = ValueTypestring,
    },
    XTableShopScreenGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupName = ValueTypestring,
        GroupIcon = ValueTypestring,
        ScreenName = Type1ValueTypestring,
        ScreenID = Type1ValueTypeint,
    },
    XTableShopShowType = {
        Id = ValueTypeintPrimaryKey,
        ShowType = ValueTypeint,
    },
    XTableShopTypeName = {
        Id = ValueTypeintPrimaryKey,
        TypeName = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableShortStory = {
        Id = ValueTypeintPrimaryKey,
        ChapterName = ValueTypestring,
        ChapterEn = ValueTypestring,
        Icon = ValueTypestring,
        OrderId = ValueTypeint,
        ShowCondition = ValueTypeint,
        ChapterId = Type1ValueTypeint,
        ZhouMuId = ValueTypeint,
        ChapterTextColor = Type1ValueTypestring,
    },
    XTableShortStoryActivity = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = Type1ValueTypeint,
        ChapterTimeId = ValueTypeint,
        HideChapterTimeId = ValueTypeint,
    },
    XTableShortStoryDetails = {
        ChapterId = ValueTypeintPrimaryKey,
        ChapterName = ValueTypestring,
        ChapterEn = ValueTypestring,
        Difficult = ValueTypeint,
        StageTitle = ValueTypestring,
        OrderId = ValueTypeint,
        StageId = Type1ValueTypeint,
        TreasureId = Type1ValueTypeint,
        PrefabName = ValueTypestring,
        ActivityCondition = ValueTypeint,
        ExploreGroupId = ValueTypeint,
        OpenCondition = ValueTypeint,
        IsBtnMissionWhite = ValueTypeint,
    },
    XTableShortStoryExploreGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        StageIndex = ValueTypeint,
        PreShowIndex = Type1ValueTypeint,
    },
    XTableShortStoryNextChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        SkipCondition = ValueTypeint,
        StoryImgs = Type1ValueTypestring,
        StorySkipId = Type1ValueTypeint,
        StorySkipName = Type1ValueTypestring,
        StoryChpterType = Type1ValueTypeint,
        StoryChapterId = Type1ValueTypeint,
        StoryChapterName = Type1ValueTypestring,
    },
    XTableShortStoryStarTreasure = {
        TreasureId = ValueTypeintPrimaryKey,
        RequireStar = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableSignActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        RestaurantActivityId = ValueTypeint,
    },
    XTableSignAward = {
        Id = ValueTypeintPrimaryKey,
        SignActivityId = ValueTypeint,
        DayId = ValueTypeint,
        RewardId = ValueTypeint,
        NpcImgUrl = ValueTypestring,
        SignDesc = ValueTypestring,
        ReplyBtnDesc = ValueTypestring,
    },
    XTableSignBoardFeedback = {
        Id = ValueTypeintPrimaryKey,
        RoleId = ValueTypestring,
        StandType = ValueTypeint,
        ChangeToStandType = ValueTypeint,
        ShowType = ValueTypeint,
        UnlockCondition = Type1ValueTypeint,
        ConditionId = ValueTypeint,
        ConditionParam = ValueTypeint,
        Content = ValueTypestring,
        CvId = ValueTypeint,
        FaceId = ValueTypeint,
        ActionId = ValueTypestring,
        Duration = Type2KeyTypeintValueTypefloat,
        Weight = ValueTypeint,
        Validity = ValueTypefloat,
        CoolTime = ValueTypeint,
        ShowButton = ValueTypestring,
        ActivityId = ValueTypeint,
        ShowTime = ValueTypestring,
        IsShowHideUi = ValueTypebool,
        SceneCamAnimPrefab = ValueTypestring,
        IsUseSelfUiAnims = Type1ValueTypeint,
        IsUseCamPosAndRot = ValueTypeint,
        IsUseStoryCamera = ValueTypeint,
        IsControlTime = ValueTypeint,
        AnimPrefabRoleModelName = ValueTypestring,
        IsCloseRoleShadow = ValueTypeint,
        TurnOffBgm = ValueTypebool,
        IsUseLipSync = ValueTypebool,
        VideoId = ValueTypeint,
        VideoIdInAndriod = ValueTypeint,
    },
    XTableSignBoardFeedbackRoleMap = {
        Id = ValueTypeintPrimaryKey,
        SignBoardIds = Type1ValueTypeint,
    },
    XTableSignCard = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        PrefabPath = ValueTypestring,
        FullScreenBg = ValueTypestring,
        BtnBg = ValueTypestring,
        CanBuyDay = ValueTypeint,
        Description = ValueTypestring,
        Param = Type2KeyTypeintValueTypeint,
    },
    XTableSignDrawNewYear = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        PrefabPath = ValueTypestring,
        OpenLevel = ValueTypeint,
        StartTimeStr = ValueTypestring,
        CloseTimeStr = ValueTypestring,
        RuleTitle = Type1ValueTypestring,
        RuleContent = Type1ValueTypestring,
        GaChaId = ValueTypeint,
    },
    XTableSignFirstRecharge = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        PrefabPath = ValueTypestring,
        FullScreenBg = ValueTypestring,
        BtnBg = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableSignIn = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        FullScreenBg = ValueTypestring,
        PrefabPath = ValueTypestring,
        BtnBg = ValueTypestring,
        Type = ValueTypeint,
        RoundDays = Type1ValueTypeint,
        SubRoundId = Type1ValueTypeint,
        OpenLevel = ValueTypeint,
        OpenStage = ValueTypeint,
        PreSignId = ValueTypeint,
        CreateTimeId = ValueTypeint,
        IsShowWhenDayOver = ValueTypebool,
        IsShowWhenSignOver = ValueTypebool,
        ReissueRewardMailId = ValueTypeint,
    },
    XTableSignInReward = {
        Id = ValueTypeintPrimaryKey,
        SignId = ValueTypeint,
        Pre = ValueTypeint,
        Round = ValueTypeint,
        Day = ValueTypeint,
        IsGrandPrix = ValueTypebool,
        RewardType = ValueTypeint,
        RewardId = ValueTypeint,
        DropId = ValueTypeint,
        ShowRewardId = ValueTypeint,
        ReissueRewardId = ValueTypeint,
    },
    XTableSignInSubround = {
        Id = ValueTypeintPrimaryKey,
        SubRoundDays = Type1ValueTypeint,
        SubRoundName = Type1ValueTypestring,
        SubRoundIcon = Type1ValueTypestring,
        SubRoundDesc = ValueTypestring,
    },
    XTableSignTempleGacha = {
        Id = ValueTypeint,
        Name = ValueTypestring,
        PrefabPath = ValueTypestring,
        StartTimeStr = ValueTypestring,
        CloseTimeStr = ValueTypestring,
        RuleTitle = Type1ValueTypestring,
        RuleContent = Type1ValueTypestring,
        GaChaId = ValueTypeint,
    },
    XTableSimulatedCombatActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        HardConditionId = ValueTypeint,
        TimeId = ValueTypeint,
        ChapterPrefab = Type1ValueTypestring,
        ConsumeIds = Type1ValueTypeint,
        ConsumeCountLimit = Type1ValueTypeint,
        ConsumeInitCounts = Type1ValueTypeint,
        PointId = ValueTypeint,
        MaxDailyStageStarRewardCount = ValueTypeint,
        BannerBg = ValueTypestring,
    },
    XTableSimulatedCombatAddition = {
        Id = ValueTypeintPrimaryKey,
        FightEventId = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        Star = ValueTypeint,
        ConsumeCounts = Type1ValueTypeint,
    },
    XTableSimulatedCombatChallenge = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Num = ValueTypeint,
        Description = ValueTypestring,
    },
    XTableSimulatedCombatMember = {
        Id = ValueTypeintPrimaryKey,
        RobotId = ValueTypeint,
        Star = ValueTypeint,
        ConsumeCounts = Type1ValueTypeint,
        FightEventIds = Type1ValueTypeint,
    },
    XTableSimulatedCombatPointReward = {
        Id = ValueTypeintPrimaryKey,
        NeedPoint = ValueTypeint,
        RewardId = ValueTypeint,
        ShowItem = ValueTypeint,
        ShowItemNum = ValueTypeint,
    },
    XTableSimulatedCombatStage = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Type = ValueTypeint,
        PrefabPath = ValueTypestring,
        IconPath = ValueTypestring,
        MemberIds = Type1ValueTypeint,
        Additions = Type1ValueTypeint,
        StarRewardIds = Type2KeyTypeintValueTypeint,
        ChallengeIds = Type1ValueTypeint,
        ShowFightEventIds = Type1ValueTypeint,
    },
    XTableSimulatedCombatStarReward = {
        Id = ValueTypeintPrimaryKey,
        RequireStar = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableSimulateTrainActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        BossIds = Type1ValueTypeint,
    },
    XTableSimulateTrainActivityBoss = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MonsterId = ValueTypeint,
        ModelId = ValueTypestring,
        Icon = ValueTypestring,
        RobotIds = Type1ValueTypeint,
        TaskIds = Type1ValueTypeint,
        TaskTypes = Type1ValueTypeint,
        UiDetailBgs = Type1ValueTypestring,
    },
    XTableSimulateTrainAtk = {
        AtkLevel = ValueTypeintPrimaryKey,
        AtkBuffId = ValueTypeint,
        AtkAttributeCe = ValueTypeint,
        AtkAddPercent = ValueTypeint,
    },
    XTableSimulateTrainGroup = {
        GroupId = ValueTypeintPrimaryKey,
        GroupName = ValueTypestring,
    },
    XTableSimulateTrainHp = {
        HpLevel = ValueTypeintPrimaryKey,
        HpBuffId = ValueTypeint,
        HpAttributeCe = ValueTypeint,
        HpAddPercent = ValueTypeint,
    },
    XTableSimulateTrainMonster = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ImpasseTimeId = ValueTypeint,
        Type = ValueTypeint,
        HpAddPercent = ValueTypeint,
        StageId = ValueTypeint,
        NpcId = Type1ValueTypeint,
        NpcLevel = Type1ValueTypeint,
        StageName = Type1ValueTypestring,
        StageBuffId = Type1ValueTypeint,
        PeriodBuffId = Type2KeyTypeintValueTypeint,
        FirstRewardId = ValueTypeint,
        DefaultAtkLevel = ValueTypeint,
        DefaultHpLevel = ValueTypeint,
        SortId = ValueTypeint,
        GroupId = ValueTypeint,
        StageRatioCe = Type1ValueTypeint,
        StageBasicCe = Type1ValueTypeint,
        SkillIds = Type1ValueTypeint,
    },
    XTableSimulateTrainSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        VideoUrl = ValueTypestring,
    },
    XTableSingleStory = {
        Id = ValueTypeintPrimaryKey,
        PeriodChapterIds = Type2KeyTypeintValueTypeint,
        Name = ValueTypestring,
        Gender = ValueTypestring,
        HalfBodyImg = ValueTypestring,
        FullBodyImg = ValueTypestring,
        Text = ValueTypestring,
        MovieId = ValueTypestring,
        IsShow = Type2KeyTypeintValueTypeint,
        IsVoiceover = ValueTypeint,
        CharacterIds = Type1ValueTypeint,
    },
    XTableSkillRelease = {
        Id = ValueTypeintPrimaryKey,
        SkillId = ValueTypeint,
        SkillGroupId = ValueTypeint,
        BtnName = ValueTypeint,
        InputInfo = ValueTypeint,
        InputParam1 = ValueTypefix,
        InputParam2 = ValueTypefix,
        InputParam3 = ValueTypefix,
        Priority = ValueTypeint,
        SkillTiming = ValueTypeint,
        LastSkill = ValueTypestring,
        NeedBuff = ValueTypestring,
        ReleaseType = ValueTypeint,
        EnemyDistance = ValueTypefix,
    },
    XTableSkinVoteActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        VoteTimeId = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableSkinVoteActivityClient = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        VoteTips = ValueTypestring,
        PrefabPath = ValueTypestring,
        PreviewImgSmall = Type1ValueTypestring,
        PreviewImgFull = Type1ValueTypestring,
    },
    XTableSkinVoteNameGroup = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableSkipFunctional = {
        SkipId = ValueTypeintPrimaryKey,
        Origin = ValueTypeint,
        UiName = ValueTypestring,
        ParamId = ValueTypeint,
        Explain = ValueTypestring,
        IsRecord = ValueTypebool,
        ConditionId = ValueTypeint,
        FunctionalId = ValueTypeint,
        TimeId = ValueTypeint,
        StartTime = ValueTypestring,
        CloseTime = ValueTypestring,
        CustomParams = Type1ValueTypeint,
        IsHideFunc = ValueTypebool,
        IsShowExplain = ValueTypebool,
        NotShowUI = Type1ValueTypestring,
    },
    XTableSkyGardenHeavyArtilleryFireText = {
        Key = ValueTypestringPrimaryKey,
        Content = ValueTypestring,
    },
    XTableSlotMachines = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        DifferentAddScore = ValueTypeint,
        TwoSameAddScore = ValueTypeint,
        ConsumeItemId = ValueTypeint,
        ConsumeCount = ValueTypeint,
        UnlockNeedPreScore = ValueTypeint,
        ScoreLimit = ValueTypeint,
        BgImage = ValueTypestring,
        MachineImage = ValueTypestring,
        MachineLockImage = ValueTypestring,
        NextMachineBtnImage = ValueTypestring,
        ScoreIcon = ValueTypestring,
        NextMachineBtnText = ValueTypestring,
        LockTips = ValueTypestring,
        UnlockTips = ValueTypestring,
        RulesIds = Type1ValueTypeint,
        Icons = Type1ValueTypeint,
        Weights = Type1ValueTypeint,
        RewardIds = Type1ValueTypeint,
        RewardScores = Type1ValueTypeint,
        PrixBottomTimes = ValueTypeint,
        RockPrixTimesLimit = ValueTypeint,
        TaskDailyLimitId = ValueTypeint,
        TaskCumulativeLimitId = ValueTypeint,
        MailId = ValueTypeint,
        HighLight = ValueTypeint,
        RockTimes = ValueTypeint,
    },
    XTableSlotMachinesActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        SlotMachinesIds = Type1ValueTypeint,
    },
    XTableSlotMachinesIcon = {
        Id = ValueTypeintPrimaryKey,
        IconName = ValueTypestring,
        IconImage = ValueTypestring,
        IconTiltImage = ValueTypestring,
        Score = ValueTypeint,
        IsPrix = ValueTypebool,
    },
    XTableSlotMachinesRules = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableSmashEggsActivation = {
        Id = ValueTypeintPrimaryKey,
        Day = ValueTypeint,
        Index = ValueTypeint,
        TargetScore = ValueTypeint,
        RewardId = ValueTypeint,
        DropId = ValueTypeint,
    },
    XTableSmashEggsActivity = {
        Id = ValueTypeint,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        Background = ValueTypestring,
    },
    XTableSmashEggsBuffItem = {
        Id = ValueTypeintPrimaryKey,
        ItemId = ValueTypeint,
        Name = ValueTypestring,
        IsFree = ValueTypebool,
        InitCount = ValueTypeint,
        BuffType = ValueTypeint,
        BuffProb = ValueTypeint,
        SuccessRate = Type1ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableSmashEggsEggPlace = {
        Id = ValueTypeint,
        PlaceCount = ValueTypeint,
    },
    XTableSmashEggsScoreConfig = {
        Id = ValueTypeintPrimaryKey,
        InitScore = ValueTypeint,
        FirstScore = ValueTypeint,
        AddScoreType = ValueTypeint,
        AddScore = ValueTypeint,
        FailureReduceType = ValueTypeint,
        FailureScore = ValueTypeint,
        MaxScore = ValueTypeint,
        SucceedDropId = ValueTypeint,
        FailureDropId = ValueTypeint,
        ScoreConvertItemId = ValueTypeint,
        NeedTipCount = ValueTypeint,
    },
    XTableSoloReformCfg = {
        Id = ValueTypeintPrimaryKey,
        OpenTime = ValueTypeint,
        HelpName = ValueTypestring,
        TaskIds = Type1ValueTypeint,
        TaskGroupIds = Type1ValueTypeint,
        ShowRewardItemIds = Type1ValueTypeint,
    },
    XTableSoloReformChapter = {
        Id = ValueTypeintPrimaryKey,
        OpenTime = ValueTypeint,
        Type = ValueTypeint,
        ChapterStageIds = Type1ValueTypeint,
        UseChara = Type1ValueTypeint,
        RobotData = Type1ValueTypeint,
        Order = ValueTypeint,
        CharacterCount = ValueTypeint,
        Img = ValueTypestring,
        Title = ValueTypestring,
        StageLogo = ValueTypestring,
        HeadLogo = ValueTypestring,
    },
    XTableSoloReformLevel = {
        Id = ValueTypeintPrimaryKey,
        MinScores = Type1ValueTypeint,
        MaxScores = Type1ValueTypeint,
        LevelName = ValueTypestring,
        LevelIcon = ValueTypestring,
        BalanceIcon = ValueTypestring,
        EffectName = ValueTypestring,
        SettlementUIEffectName = ValueTypestring,
    },
    XTableSoloReformRankUp = {
        Id = ValueTypeintPrimaryKey,
        CastOnTime = Type1ValueTypeint,
        CastOnMission = Type1ValueTypeint,
        CastOffFightevent = Type1ValueTypeint,
        CastFail = Type1ValueTypeint,
        CastOnMissionFightTips = Type1ValueTypeint,
        CastOffFighteventTips = Type1ValueTypeint,
        LockIcon = ValueTypestring,
        TokeIcon = ValueTypestring,
        StageId = ValueTypeint,
    },
    XTableSoloReformScore = {
        Id = ValueTypeintPrimaryKey,
        Score = ValueTypeint,
        Type = ValueTypeint,
        Desc = ValueTypestring,
        Order = ValueTypeint,
        TipsDesc = ValueTypestring,
        TipsScore = ValueTypestring,
    },
    XTableSoloReformStage = {
        Id = ValueTypeintPrimaryKey,
        Difficulty = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        StarNum = ValueTypeint,
        Img = ValueTypestring,
        Icon = ValueTypestring,
        StarTalks = Type1ValueTypestring,
        StageType = ValueTypeint,
        TitleUnlock = ValueTypeint,
        TitleName = ValueTypestring,
        StageEnemyName = ValueTypestring,
    },
    XTableSoloReformUnlockFightEvent = {
        FightEventId = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        StageType = ValueTypeint,
        UnlockDiff = ValueTypeint,
        Desc = ValueTypestring,
        VideoId = ValueTypeint,
        Name = ValueTypestring,
        LockStage = ValueTypeint,
    },
    XTableSpecialActivity = {
        Id = ValueTypeintPrimaryKey,
        OnlyRedPoint = ValueTypeint,
        TimeId = ValueTypeint,
        Condition = ValueTypeint,
        SkipId = ValueTypeint,
        Bg = ValueTypestring,
        ActivityType = ValueTypeint,
        RedPointConditions = ValueTypestring,
        Param = ValueTypeint,
        ManagerName = ValueTypestring,
    },
    XTableSpecialCollectionLevel = {
        Index = ValueTypeintPrimaryKey,
        Id = ValueTypeint,
        Score = ValueTypeint,
        Level = ValueTypeint,
    },
    XTableSpecialRankScoreGoods = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Quality = ValueTypeint,
        Description = ValueTypestring,
    },
    XTableSpecialShop = {
        Id = ValueTypeintPrimaryKey,
        FashionShopId = ValueTypeint,
        WeaponFashionShopId = ValueTypeint,
        TimeId = ValueTypeint,
    },
    XTableSpecialTrainActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        ChapterIds = Type1ValueTypeint,
        EliminateGameId = ValueTypeint,
        PointItemId = ValueTypeint,
        PointRewardId = Type1ValueTypeint,
        TaskGroupId = Type1ValueTypeint,
        InitSkillId = ValueTypeint,
    },
    XTableSpecialTrainAlbumConfig = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Composer = ValueTypestring,
        Cover = ValueTypestring,
        Bg = ValueTypestring,
        CueId = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableSpecialTrainChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SecondName = ValueTypestring,
        SeasonName = ValueTypestring,
        PrefixName = ValueTypestring,
        BgIcon = ValueTypestring,
        TabImage = ValueTypestring,
        RewardType = ValueTypeint,
        HelpId = Type1ValueTypeint,
        RewardParams = Type1ValueTypeint,
        StageIds = Type1ValueTypeint,
        RandomStageId = ValueTypeint,
    },
    XTableSpecialTrainDailySwitchTask = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        DayId = ValueTypeint,
        DailyTaskGroupId = ValueTypeint,
    },
    XTableSpecialTrainPointReward = {
        Id = ValueTypeintPrimaryKey,
        NeedPoint = ValueTypeint,
        RewardId = ValueTypeint,
        ShowItem = ValueTypeint,
        ShowItemNum = ValueTypeint,
    },
    XTableSpecialTrainRandomStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        StoryIcon = ValueTypestring,
        IconEffect = ValueTypestring,
    },
    XTableSpecialTrainRankTier = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Tier = ValueTypeint,
        TierName = ValueTypestring,
        TierDescribe = ValueTypestring,
        Icon = ValueTypestring,
        Score = ValueTypeint,
        SettleScore = Type1ValueTypeint,
        NextRankId = ValueTypeint,
        LowestGrade = ValueTypeint,
    },
    XTableSpecialTrainRhythmRankSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        FightEvent = ValueTypeint,
    },
    XTableSpecialTrainStage = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        HellStageId = ValueTypeint,
        AlbumId = ValueTypeint,
        MatchTimeout = ValueTypeint,
        TimeId = ValueTypeint,
    },
    XTableSpecialTrainStageIconEffect = {
        StageId = ValueTypeintPrimaryKey,
        IconEffect = ValueTypestring,
    },
    XTableSpecialTrainStarReward = {
        Id = ValueTypeintPrimaryKey,
        RequireStar = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableSpecialUiModel = {
        Id = ValueTypeintPrimaryKey,
        ModelId = ValueTypestring,
        UiName = ValueTypestring,
        MainModelId = ValueTypestring,
        MinorModelId = ValueTypestring,
    },
    XTableSpringFestivalActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        Background = ValueTypestring,
        ChapterId = ValueTypeint,
        ActivitySkipId = ValueTypeint,
        ShopSkipId = ValueTypeint,
        CollectSkipId = ValueTypeint,
        TaskActivityId = ValueTypeint,
        CollectActivityId = ValueTypeint,
        CollectHelpId = ValueTypeint,
        SmashEggsHelpId = ValueTypeint,
        CollectWordBg = ValueTypestring,
    },
    XTableSpriteTextAsset = {
        Url = ValueTypestring,
    },
    XTableStage = {
        StageId = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        StoryIcon = ValueTypestring,
        BgmId = ValueTypeint,
        AmbientSound = ValueTypeint,
        LoadingType = ValueTypestring,
        RewardTipId = ValueTypeint,
        EventId = ValueTypeint,
        NormalEventIdOnPassed = ValueTypeint,
        UnlockEventId = Type1ValueTypeint,
        NormalEventId = Type1ValueTypeint,
        PreEventId = Type1ValueTypeint,
        ClearEventId = Type1ValueTypeint,
        DisappearCondition = ValueTypeint,
        OrderId = ValueTypeint,
        RecommandLevel = ValueTypeint,
        IsMultiplayer = ValueTypebool,
        HaveAssist = ValueTypeint,
        StandardUseTimeSec = ValueTypeint,
        RequireLevel = ValueTypeint,
        RequireActionPoint = ValueTypeint,
        FirstRequireActionPoint = ValueTypeint,
        FinishRequireActionPoint = ValueTypeint,
        CharacterLimitType = ValueTypeint,
        CareerSuggestType = ValueTypestring,
        AISuggestType = ValueTypeint,
        LimitBuffId = ValueTypeint,
        PassTimeLimit = ValueTypeint,
        PreStageId = Type1ValueTypeint,
        FlopRewardId = ValueTypeint,
        FinishRewardShow = ValueTypeint,
        FirstRewardShow = ValueTypeint,
        FinishDropId = ValueTypeint,
        FirstRewardId = ValueTypeint,
        StarRewardId = Type1ValueTypeint,
        TeamExp = ValueTypeint,
        FirstTeamExp = ValueTypeint,
        FinishTeamExp = ValueTypeint,
        CardExp = ValueTypeint,
        FirstCardExp = ValueTypeint,
        FinishCardExp = ValueTypeint,
        MaxChallengeNums = ValueTypeint,
        BuyChallengeCost = ValueTypeint,
        BuyChallengeCount = ValueTypeint,
        KeepPlayingStory = ValueTypeint,
        BeginStoryIds = Type1ValueTypestring,
        BeginConditions = Type2KeyTypeintValueTypeint,
        EndStoryIds = Type1ValueTypestring,
        EndConditions = Type2KeyTypeintValueTypeint,
        OnlinePlayerLeast = ValueTypeint,
        OnlinePlayerLimit = ValueTypeint,
        StarDesc = Type1ValueTypestring,
        DescEventId = Type1ValueTypeint,
        SettleLoseTipId = ValueTypeint,
        SuggestedConditionId = Type1ValueTypeint,
        ForceConditionId = Type1ValueTypeint,
        HaveFirstPass = ValueTypebool,
        FirstGotoSkipId = ValueTypeint,
        FunctionLeftBtn = ValueTypeint,
        FunctionRightBtn = ValueTypeint,
        RobotId = Type1ValueTypeint,
        UrgentEventId = Type1ValueTypeint,
        RebootId = ValueTypeint,
        AutoFightId = ValueTypeint,
        StageType = ValueTypeint,
        StageGridStyle = ValueTypestring,
        FightControlId = ValueTypeint,
        DisableJoystick = ValueTypebool,
        NeedJobType = Type1ValueTypeint,
        MultiChallengeId = ValueTypeint,
        Restartable = ValueTypebool,
        ResetHpCount = Type1ValueTypeint,
        StoryUiStyle = ValueTypeint,
        OnlineMsgId = ValueTypeint,
        ForceAllyEffect = ValueTypebool,
        DisableDeadEffect = ValueTypebool,
        HideAction = ValueTypeint,
        Ability = ValueTypeint,
        GeneralSkillIds = Type1ValueTypeint,
        IsBanGeneralSkill = ValueTypebool,
        NextStageId = Type1ValueTypeint,
    },
    XTableStageCharacterNpcId = {
        StageType = ValueTypeintPrimaryKey,
        CharacterId = Type1ValueTypeint,
        NpcId = Type1ValueTypeint,
    },
    XTableStageFightControl = {
        Id = ValueTypeintPrimaryKey,
        MaxRecommendFight = ValueTypeint,
        MaxShowFight = ValueTypeint,
        AvgRecommendFight = ValueTypeint,
        AvgShowFight = ValueTypeint,
        RecommendFight = ValueTypeint,
        ShowFight = ValueTypeint,
        CharacterFight = ValueTypeint,
        EquipFight = ValueTypeint,
    },
    XTableStageFightEvent = {
        StageId = ValueTypeintPrimaryKey,
        FightEventIds = Type1ValueTypeint,
    },
    XTableStageFightEventDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableStageGamePlayDesc = {
        StageType = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        BtnDefault = ValueTypeint,
        BtnRestart = ValueTypeint,
        BtnSave = ValueTypeint,
        BtnRestore = ValueTypeint,
        BtnRetreat = ValueTypeint,
    },
    XTableStageGamePlayDescSheet = {
        Id = ValueTypeintPrimaryKey,
        StageType = ValueTypeint,
        Title = ValueTypestring,
        Image = ValueTypestring,
        Desc1 = ValueTypestring,
        Desc2 = ValueTypestring,
    },
    XTableStageIdToResIdList = {
        StageId = ValueTypeintPrimaryKey,
        ResIdList = Type1ValueTypeint,
    },
    XTableStageLevelControl = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        MaxLevel = ValueTypeint,
        RecommendationLevel = ValueTypeint,
        FirstRewardShow = ValueTypeint,
        FinishRewardShow = ValueTypeint,
        FirstRewardId = ValueTypeint,
        FinishDropId = ValueTypeint,
        MonsterLevel = Type1ValueTypeint,
    },
    XTableStageLineupType = {
        StageId = ValueTypeintPrimaryKey,
        Type = Type1ValueTypeint,
        PlayerSexSwitch = ValueTypeint,
        PlayerReplaceOrders = ValueTypeint,
        PlayerSexRobotMan = ValueTypeint,
        PlayerSexRobotWoman = ValueTypeint,
    },
    XTableStageMemoryActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        StageIds = Type1ValueTypeint,
        StageTimeIds = Type1ValueTypeint,
        RequireStages = Type1ValueTypeint,
        RewardIds = Type1ValueTypeint,
    },
    XTableStageMemoryShow = {
        StageId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        DescDetail = ValueTypestring,
        NoInstructionOnUiFightPause = ValueTypebool,
    },
    XTableStageMixCharacterLimitBuff = {
        CharacterLimitType = ValueTypeintPrimaryKey,
        BuffInfos = Type1ValueTypestring,
    },
    XTableStageMultiplayerLevelControl = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Difficulty = ValueTypeint,
        DifficultyDesc = ValueTypestring,
        RecommendAbility = ValueTypeint,
        AdditionDest = ValueTypestring,
        FirstRewardId = ValueTypeint,
        FinishDropId = ValueTypeint,
        FlopRewardId = ValueTypeint,
        MonsterLevel = Type1ValueTypeint,
    },
    XTableStageRecommend = {
        StageId = ValueTypeintPrimaryKey,
        CharacterType = ValueTypeint,
        CharacterElement = ValueTypeint,
    },
    XTableStageRelatePoint = {
        StageId = ValueTypeintPrimaryKey,
        RelateStageId = Type1ValueTypeint,
    },
    XTableStageSettleSpecialSound = {
        StageId = ValueTypeintPrimaryKey,
        WinSoundId = Type1ValueTypeint,
        LoseSoundId = Type1ValueTypeint,
    },
    XTableStageSpeedrun = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        GroupId = ValueTypeint,
        RobotId = Type1ValueTypeint,
    },
    XTableStageStepSkip = {
        StageId = ValueTypeintPrimaryKey,
        SkipStep = Type1ValueTypeint,
    },
    XTableStageTag = {
        Type = ValueTypeintPrimaryKey,
        Tag = ValueTypestring,
    },
    XTableStageTeamBuff = {
        Id = ValueTypeintPrimaryKey,
        Quality = Type1ValueTypeint,
        BuffId = Type1ValueTypeint,
        OnIcon = ValueTypestring,
        OffIcon = ValueTypestring,
        Title = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableStageTeleport = {
        StageId = ValueTypeintPrimaryKey,
        SkipStageIds = Type1ValueTypeint,
        SkipLoadingTypes = Type1ValueTypestring,
        KeepPlayingStory = ValueTypeint,
    },
    XTableStageTransform = {
        Id = ValueTypeintPrimaryKey,
        PositionX = ValueTypefloat,
        PositionY = ValueTypefloat,
        PositionZ = ValueTypefloat,
        RotationX = ValueTypefloat,
        RotationY = ValueTypefloat,
        RotationZ = ValueTypefloat,
        Scale = ValueTypefloat,
        ChildPosX = ValueTypefloat,
        ChildPosY = ValueTypefloat,
        ChildRotaionX = ValueTypefloat,
        ChildRotaionY = ValueTypefloat,
        ChildRotaionZ = ValueTypefloat,
    },
    XTableStageType = {
        Id = ValueTypeintPrimaryKey,
        MatchCharIdRepeat = ValueTypebool,
        MatchByStageTypeTimeout = ValueTypeint,
        RobotId = Type1ValueTypeint,
    },
    XTableStageVoiceTip = {
        StageId = ValueTypeintPrimaryKey,
        Text = ValueTypestring,
    },
    XTableStatusSyncFightConfig = {
        ChangeMasterControllerByBadNetworkStateEnable = ValueTypebool,
        ChangeMasterControllerWaitTimeByBadNetworkState = ValueTypeint,
        ChangeMasterControllerMaxScoreDifference = ValueTypeint,
        ChangeMasterControllerMaxScoreBiggerDifference = ValueTypeint,
        ChangeMasterControllerLowestScore = ValueTypeint,
    },
    XTableStoryLayout = {
        CharacterId = ValueTypeintPrimaryKey,
        LayOutType = ValueTypestring,
        BgType = ValueTypeint,
        BgCustomParams = Type1ValueTypestring,
    },
    XTableStoryLayoutBgType = {
        Type = ValueTypeintPrimaryKey,
        PrefabAddress = ValueTypestring,
        CommonParams = Type1ValueTypestring,
    },
    XTableStoryRole = {
        RoleId = ValueTypeint,
        Name = ValueTypestring,
        RoleIcon = ValueTypestring,
        Race = ValueTypestring,
        BodyId = ValueTypeint,
        BodyFeature = ValueTypestring,
        Age = ValueTypeint,
        BirthData = ValueTypestring,
        Height = ValueTypeint,
        Weight = ValueTypeint,
        BWH = ValueTypestring,
        BodyFace = ValueTypestring,
        Awareness = ValueTypestring,
        ActionStandard = ValueTypestring,
        CarrayDevice = ValueTypestring,
        IQ = ValueTypeint,
        EQ = ValueTypeint,
        Physical = ValueTypeint,
        Tactics = ValueTypeint,
        LeaderShip = ValueTypeint,
    },
    XTableStrongholdActivity = {
        Id = ValueTypeintPrimaryKey,
        OpenTimeId = ValueTypeint,
        OneCycleSeconds = ValueTypeint,
        AutoBeginSeconds = ValueTypeint,
        FightContinueSeconds = ValueTypeint,
        IsNoPrize = ValueTypebool,
        IsClearTeam = ValueTypebool,
        DistributionId = Type1ValueTypeint,
    },
    XTableStrongholdBorrowCost = {
        Id = ValueTypeintPrimaryKey,
        ItemId = ValueTypeint,
        ItemCount = ValueTypeint,
    },
    XTableStrongholdBuff = {
        Id = ValueTypeintPrimaryKey,
        Condition = Type1ValueTypeint,
        FightEventId = Type1ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableStrongholdBuffGroup = {
        Id = ValueTypeint,
        BuffId = Type1ValueTypeint,
    },
    XTableStrongholdCfg = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypeint,
        Comment = ValueTypestring,
    },
    XTableStrongholdChapter = {
        Id = ValueTypeintPrimaryKey,
        GroupId = Type1ValueTypeint,
        Name = ValueTypestring,
        Banner = ValueTypestring,
        Bg = ValueTypestring,
        ChapterBg = ValueTypestring,
        Prefab = ValueTypestring,
        Type = ValueTypeint,
        UnlockCondition = ValueTypeint,
        MaxElectricUse = ValueTypeint,
        LendCharacterDisableUse = ValueTypebool,
        SuggestElectric = Type1ValueTypeint,
        SweepLevelId = Type1ValueTypeint,
        LimitElectric = ValueTypeint,
    },
    XTableStrongholdDistribution = {
        Id = ValueTypeint,
        RuneRuleId = ValueTypeint,
        Group = Type1ValueTypeint,
        ConstantStageGroupIndex = Type1ValueTypestring,
        RandomStageGroupIndex = Type1ValueTypestring,
        RandomStageGroupCount = Type1ValueTypeint,
        SupportGroup = Type1ValueTypestring,
        ExtendBuffId = Type1ValueTypeint,
    },
    XTableStrongholdElectric = {
        Id = ValueTypeintPrimaryKey,
        ElectricEnerge = Type2KeyTypeintValueTypeint,
    },
    XTableStrongholdEndurance = {
        Id = ValueTypeintPrimaryKey,
        Endurance = Type2KeyTypeintValueTypeint,
    },
    XTableStrongholdGroup = {
        Id = ValueTypeintPrimaryKey,
        PreId = ValueTypeint,
        Order = ValueTypestring,
        Name = ValueTypestring,
        DetailDesc = ValueTypestring,
        Prefab = ValueTypestring,
        IconBg = ValueTypestring,
        IconBoss = Type1ValueTypestring,
        DetailBg = ValueTypestring,
        FinishRelatedId = Type1ValueTypeint,
        Endurance = ValueTypeint,
        RewardId = Type2KeyTypeintValueTypeint,
        TeamMember = Type1ValueTypeint,
        DistributionGroup = ValueTypeint,
        BuffGroup = Type1ValueTypestring,
        RobotGroup = Type2KeyTypeintValueTypeint,
        StageIdGroup = Type1ValueTypestring,
        BaseBuffId = Type1ValueTypestring,
        StageBuffId = Type1ValueTypestring,
        SupportId = ValueTypestring,
        AddElectricEnergy = ValueTypeint,
        SweepCondition = Type1ValueTypeint,
        SweepLevelId = Type1ValueTypeint,
    },
    XTableStrongholdGroupElement = {
        StageIdGroupIndex = ValueTypeintPrimaryKey,
        GridTitleBg = ValueTypestring,
    },
    XTableStrongholdLevel = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        MinLevel = ValueTypeint,
        MaxLevel = ValueTypeint,
        InitElectricEnergy = ValueTypeint,
        InitEndurance = ValueTypeint,
        Chapter = Type1ValueTypeint,
    },
    XTableStrongholdPlugin = {
        Id = ValueTypeintPrimaryKey,
        BuffId = ValueTypeint,
        CountLimit = ValueTypeint,
        UseElectric = ValueTypeint,
        FightAbility = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableStrongholdReserve = {
        TeamId = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
    },
    XTableStrongholdReward = {
        Id = ValueTypeintPrimaryKey,
        LevelId = ValueTypeint,
        Condition = ValueTypeint,
        RewardId = ValueTypeint,
        SkipId = ValueTypeint,
        Desc = ValueTypestring,
        Offline = ValueTypeint,
        RewardType = ValueTypeint,
        ChapterId = ValueTypeint,
        IconNumber = ValueTypeint,
        Title = ValueTypestring,
    },
    XTableStrongholdRewardGroup = {
        RewardType = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableStrongholdRobotGroup = {
        Id = ValueTypeintPrimaryKey,
        RobotId = Type1ValueTypeint,
    },
    XTableStrongholdRune = {
        Id = ValueTypeintPrimaryKey,
        FightEventId = ValueTypeint,
        SubRuneId = Type1ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Brief = ValueTypestring,
        Color = ValueTypestring,
    },
    XTableStrongholdRuneRule = {
        Id = ValueTypeint,
        RuneCount = ValueTypeint,
        RuneId = Type1ValueTypeint,
    },
    XTableStrongholdStageLevelControl = {
        Id = ValueTypeint,
        StageId = ValueTypeint,
        LevelId = ValueTypeint,
        MonsterLevel = Type1ValueTypeint,
    },
    XTableStrongholdSubRune = {
        Id = ValueTypeintPrimaryKey,
        FightEventId = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableStrongholdSupport = {
        Id = ValueTypeintPrimaryKey,
        RequireAbility = ValueTypeint,
        Condition = Type1ValueTypeint,
        BuffId = Type1ValueTypeint,
    },
    XTableStrongholdTeamElectric = {
        Id = ValueTypeintPrimaryKey,
        ElectricEnerge = ValueTypeint,
    },
    XTableStudentChallengeReward = {
        TaskId = ValueTypeintPrimaryKey,
        RewardId = ValueTypeint,
    },
    XTableStudentWeeklyReward = {
        Id = ValueTypeintPrimaryKey,
        Level = ValueTypeint,
        Count = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableSubChapter = {
        ChapterId = ValueTypeintPrimaryKey,
        OrderId = ValueTypeint,
        Difficult = ValueTypeint,
        ChapterEn = ValueTypestring,
        PrefabName = ValueTypestring,
        StageId = Type1ValueTypeint,
        TreasureId = Type1ValueTypeint,
        ChapterName = ValueTypestring,
        Bg = ValueTypestring,
        Icon = ValueTypestring,
        ActivityCondition = ValueTypeint,
        ExploreGroupId = ValueTypeint,
        OpenCondition = ValueTypeint,
    },
    XTableSubGraphic = {
        Level = ValueTypeint,
        DisplayName = ValueTypestring,
    },
    XTableSubPackage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Index = ValueTypeint,
        Type = ValueTypeint,
        ResIds = Type1ValueTypeint,
        Desc = ValueTypestring,
        Banner = ValueTypestring,
        AllowDelete = ValueTypebool,
        CustomSkipId = ValueTypeint,
        PreIds = Type1ValueTypeint,
        DownloadTaskId = ValueTypeint,
    },
    XTableSubPackageGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        NameShort = ValueTypestring,
        NameEn = ValueTypestring,
        Desc = ValueTypestring,
        SubPackageId = Type1ValueTypeint,
    },
    XTableSubPackageIntercept = {
        Id = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        MainSubPackageId = ValueTypeint,
        ExtraSubPackageIds = Type1ValueTypeint,
        WeakSubPackageIds = Type1ValueTypeint,
        EntryType = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableSucceedBossActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        ChapterIds = Type1ValueTypeint,
        RobotIds = Type1ValueTypeint,
        TaskGroups = Type1ValueTypeint,
        CharacterResetHpPercent = ValueTypeint,
        ShowRewardId = ValueTypeint,
    },
    XTableSucceedBossChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Type = ValueTypeint,
        Name = ValueTypestring,
        PreChapter = ValueTypeint,
        TeamLimitCount = ValueTypeint,
        MonsterGroupIds = Type1ValueTypeint,
        CanSweep = Type1ValueTypebool,
    },
    XTableSucceedBossCharacterBuff = {
        Id = ValueTypeintPrimaryKey,
        CharacterElement = ValueTypeint,
        CharacterCareer = ValueTypeint,
        FightEventId = ValueTypeint,
    },
    XTableSucceedBossElement = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        FightEventId = ValueTypeint,
        ElementId = ValueTypeint,
    },
    XTableSucceedBossFightEventShow = {
        FightEventId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableSucceedBossFightGrid = {
        Id = ValueTypeintPrimaryKey,
        GridPos = ValueTypestring,
        Weight = ValueTypeint,
        Value = ValueTypeint,
    },
    XTableSucceedBossMonster = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Type = ValueTypeint,
        Name = ValueTypestring,
        StageId = ValueTypeint,
        SkillFightEventId = ValueTypeint,
        BuffFightEventId = ValueTypeint,
        DefaultUnlockLevel = ValueTypeint,
        HeadIcon = ValueTypestring,
        ShowIconMain = ValueTypestring,
        Model = ValueTypestring,
    },
    XTableSucceedBossMonsterGroup = {
        Id = ValueTypeintPrimaryKey,
        MonsterIds = Type1ValueTypeint,
        SelectMonster = ValueTypeint,
    },
    XTableSucceedBossMonsterLevel = {
        Id = ValueTypeintPrimaryKey,
        MonsterId = ValueTypeint,
        Level = ValueTypeint,
        FightEventId = ValueTypeint,
        MonsterScore = ValueTypeint,
        MonsterAtk = ValueTypeint,
        MonsterHp = ValueTypeint,
        MonsterEndure = ValueTypeint,
        SweepScore = ValueTypeint,
    },
    XTableSucceedBossSweepFightEvent = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableSummerEpisodeMapConfig = {
        Id = ValueTypeint,
        Bg = ValueTypestring,
        Picture = ValueTypestring,
    },
    XTableSummerMessage = {
        Id = ValueTypeintPrimaryKey,
        Message = ValueTypestring,
        CharacterHead = Type1ValueTypestring,
        CharacterName = ValueTypestring,
        TeamPic = ValueTypestring,
        UnlockTeamPic = ValueTypestring,
        UnlockHead = ValueTypestring,
        TeamName = ValueTypestring,
        RewardName = ValueTypestring,
        SinglePic = Type1ValueTypestring,
        SingleMessage = Type1ValueTypestring,
        SingleName = Type1ValueTypestring,
    },
    XTableSummerSignIn = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MessageId = Type1ValueTypeint,
        MessageRewardId = Type1ValueTypeint,
        ArchiveMailId = Type1ValueTypeint,
    },
    XTableSuperSmashBrosActivity = {
        Id = ValueTypeintPrimaryKey,
        OpenTimeId = ValueTypeint,
        Name = ValueTypestring,
        PointItemId = ValueTypeint,
        EnergyItemId = ValueTypeint,
        LevelItem = ValueTypeint,
        EnergyGainByDay = ValueTypeint,
        MaxEnergy = ValueTypeint,
        CoreStartLevel = ValueTypeint,
        EnergyCostOnUpgrade = ValueTypeint,
        AtkUpNumByLevel = ValueTypeint,
        AtkUpAbilityByLevel = ValueTypeint,
        LifeUpNumByLevel = ValueTypeint,
        LifeUpAbilityByLevel = ValueTypeint,
        EntryImage = ValueTypestring,
        DailyRewardId = ValueTypeint,
        AddTeamItem = ValueTypeint,
    },
    XTableSuperSmashBrosAssistance = {
        AssistId = ValueTypeintPrimaryKey,
        AssistType = ValueTypeint,
        PrivateFightEventId = ValueTypeint,
        OpenFightEventId = ValueTypeint,
        CoolingTime = ValueTypeint,
        SkillName = ValueTypestring,
        Desc = ValueTypestring,
        RoleCharacterBig = ValueTypestring,
        MonsterName = ValueTypestring,
        Ability = ValueTypeint,
        Icon = ValueTypestring,
        CareerIcon = ValueTypestring,
        HalfBodyImage = ValueTypestring,
    },
    XTableSuperSmashBrosBalanceTips = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        Icon = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableSuperSmashBrosCore = {
        Id = ValueTypeintPrimaryKey,
        ModeId = ValueTypeint,
        Name = ValueTypestring,
        UnlockTips = ValueTypestring,
        Icon = ValueTypestring,
        StarLimit = ValueTypeint,
        AttackFightEventId = ValueTypeint,
        HpFightEventId = ValueTypeint,
        StrongAttrLimit = ValueTypeint,
    },
    XTableSuperSmashBrosCoreLevel = {
        Id = ValueTypeintPrimaryKey,
        CoreId = ValueTypeint,
        Star = ValueTypeint,
        FightEventId = ValueTypeint,
        SpendMaterialId = ValueTypeint,
        SpendMaterialCount = ValueTypeint,
        Description = ValueTypestring,
        UpgradeDescription = ValueTypestring,
    },
    XTableSuperSmashBrosEnvLibrary = {
        Id = ValueTypeintPrimaryKey,
        LibraryId = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        FightEventId = ValueTypeint,
        PowerPercent = ValueTypeint,
    },
    XTableSuperSmashBrosMapLibrary = {
        Id = ValueTypeintPrimaryKey,
        LibraryId = ValueTypeint,
        ThumbnailPath = ValueTypestring,
        EnvName = ValueTypestring,
        Description = ValueTypestring,
        PowerPercent = ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        BtnIcon = ValueTypestring,
        SuperSmashBrosMonster = ValueTypeint,
        MonsterLibraryId = ValueTypeint,
        NeedWinCount = ValueTypeint,
    },
    XTableSuperSmashBrosMode = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Name = ValueTypestring,
        OpenTime = ValueTypeint,
        CoreId = ValueTypeint,
        MonsterLibraryId = ValueTypeint,
        MapLibraryId = ValueTypeint,
        EnvLibraryId = ValueTypeint,
        IsLinearStage = ValueTypebool,
        LinearStageNum = ValueTypeint,
        IsRanking = ValueTypebool,
        RoleMaxPosition = ValueTypeint,
        RoleMinPosition = ValueTypeint,
        RoleBattleNum = ValueTypeint,
        MonsterMinPosition = ValueTypeint,
        MonsterBattleNum = ValueTypeint,
        MonsterMaxPosition = ValueTypeint,
        MonsterRandomNum = ValueTypeint,
        BossLimit = ValueTypeint,
        Description = ValueTypestring,
        BgPath = ValueTypestring,
        Icon = ValueTypestring,
        OrderIcon = ValueTypestring,
        ShadowBgPath = ValueTypestring,
        NamePlateColorR = ValueTypeint,
        NamePlateColorG = ValueTypeint,
        NamePlateColorB = ValueTypeint,
        Priority = ValueTypeint,
        TeamMaxPosition = ValueTypeint,
        FightEvent = Type1ValueTypeint,
        EggRateRandom = ValueTypeint,
        EggRateNormal = ValueTypeint,
        EggStartIndex = ValueTypeint,
        EggEndIndex = ValueTypeint,
        EggRobots = Type1ValueTypestring,
        RoleForceRandomIndex = ValueTypeint,
        TaskGroupId = ValueTypeint,
        RoleForceAssistIndex = ValueTypeint,
        StageRollBack = ValueTypeint,
    },
    XTableSuperSmashBrosMonster = {
        Id = ValueTypeintPrimaryKey,
        MonsterId = ValueTypeint,
        MonsterType = ValueTypeint,
        Icon = ValueTypestring,
        Num = ValueTypeint,
        Level = ValueTypeint,
        LimitStageId = ValueTypeint,
        ModelScale = ValueTypefloat,
        FightEventList = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
        MonsterInfoId = ValueTypeint,
        Note = ValueTypestring,
    },
    XTableSuperSmashBrosMonsterInfo = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ModelName = ValueTypestring,
    },
    XTableSuperSmashBrosMonsterLibrary = {
        Id = ValueTypeintPrimaryKey,
        LibraryId = ValueTypeint,
        MonsterIdList = Type1ValueTypeint,
        Ability = ValueTypeint,
        MonsterGroupType = ValueTypeint,
        RewardId = ValueTypeint,
        FirstScore = ValueTypeint,
        LevelItem = ValueTypeint,
        Icon = ValueTypestring,
        HalfBodyIcon = ValueTypestring,
        OpenTime = ValueTypeint,
    },
    XTableSuperSmashBrosMonsterType = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableSuperSmashBrosReward = {
        Id = ValueTypeintPrimaryKey,
        ModeId = ValueTypeint,
        OrderId = ValueTypeint,
        NeedScore = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableSuperSmashBrosRewardShow = {
        Id = ValueTypeintPrimaryKey,
        TaskId = ValueTypeint,
        Order = ValueTypeint,
    },
    XTableSuperSmashBrosSystemCharacter = {
        Id = ValueTypeintPrimaryKey,
        RobotId = ValueTypeint,
    },
    XTableSuperSmashBrosTeamLevel = {
        TeamLevel = ValueTypeintPrimaryKey,
        NeedItem = ValueTypeint,
        AtkUp = ValueTypeint,
        HpUp = ValueTypeint,
        AbilityUp = ValueTypeint,
        FightEventId = ValueTypeint,
    },
    XTableSuperSmashEggRobot = {
        Id = ValueTypeintPrimaryKey,
        RoleHead = ValueTypestring,
        Desc = ValueTypestring,
        Name = ValueTypestring,
    },
    XTableSuperTowerActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        EntryImage = ValueTypestring,
        PrefaceStoryId = ValueTypestring,
        MapId = Type1ValueTypeint,
    },
    XTableSuperTowerCfg = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypeint,
        Comment = ValueTypestring,
    },
    XTableSuperTowerCharacterEnhancerDrop = {
        Id = ValueTypeint,
        EnhancerType = Type1ValueTypeint,
    },
    XTableSuperTowerCharacterExclusive = {
        Id = ValueTypeintPrimaryKey,
        ActivatePlugin = ValueTypeint,
        FightEventId = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableSuperTowerCharacterLevel = {
        Id = ValueTypeintPrimaryKey,
        Level = ValueTypeint,
        CharacterId = ValueTypeint,
        UpExp = ValueTypeint,
        FightEventId = ValueTypeint,
        Ability = ValueTypeint,
        AttributeId = Type1ValueTypeint,
        AttributeValue = Type1ValueTypeint,
    },
    XTableSuperTowerClientCfg = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypeint,
        Comment = ValueTypestring,
    },
    XTableSuperTowerCommonEnhancerDrop = {
        Id = ValueTypeint,
        EnhancerType = Type1ValueTypeint,
        Weight = Type1ValueTypeint,
    },
    XTableSuperTowerEnhanceDrop = {
        Id = ValueTypeintPrimaryKey,
        EnhancerDropGroupId = ValueTypeint,
        DropEnhanceId = ValueTypeint,
    },
    XTableSuperTowerEnhancer = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Level = ValueTypeint,
        Name = ValueTypestring,
        CharacterId = ValueTypeint,
        Quality = ValueTypeint,
        FightEventId = ValueTypeint,
        Icon = ValueTypestring,
        Description = ValueTypestring,
        Priority = ValueTypeint,
    },
    XTableSuperTowerFunction = {
        Key = ValueTypestringPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        UnLockDescription = ValueTypestring,
        Order = ValueTypeint,
        ThemeWeek = ValueTypeint,
        ItemId = ValueTypeint,
        LockTips = ValueTypestring,
    },
    XTableSuperTowerIndultCharacter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        CharacterId = Type1ValueTypeint,
        FightEventId = ValueTypeint,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableSuperTowerMall = {
        Id = ValueTypeintPrimaryKey,
        OpenTimeId = ValueTypeint,
        SpendItemId = ValueTypeint,
        FreeRefreshCount = ValueTypeint,
        RefreshCD = ValueTypeint,
        ManualRefreshSpendItemId = ValueTypeint,
        VisiblePluginCount = ValueTypeint,
        ManualRefreshSpendItemCount = Type1ValueTypeint,
    },
    XTableSuperTowerMallPlugin = {
        Id = ValueTypeintPrimaryKey,
        MallId = ValueTypeint,
        PluginId = ValueTypeint,
        Price = ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableSuperTowerMap = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        TierName = ValueTypestring,
    },
    XTableSuperTowerMapEffect = {
        ThemeId = ValueTypeintPrimaryKey,
        MapNormalEffect = ValueTypestring,
        MapLockEffect = ValueTypestring,
        MapCurrentEffect = ValueTypestring,
        MapTerrainEffect = ValueTypestring,
        NorStageLockEffect = ValueTypestring,
        NorStageUnLockEffect = ValueTypestring,
        NorStageCurrentEffect = ValueTypestring,
        NorStageSelectEffect = ValueTypestring,
        SpStageLockEffect = ValueTypestring,
        SpStageUnLockEffect = ValueTypestring,
        SpStageCurrentEffect = ValueTypestring,
        SpStageSelectEffect = ValueTypestring,
    },
    XTableSuperTowerPlugin = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        FightEventId = ValueTypeint,
        CharacterId = ValueTypeint,
        SynthesisId = ValueTypeint,
        SynthesisCount = ValueTypeint,
        Capacity = ValueTypeint,
        Quality = ValueTypeint,
        Icon = ValueTypestring,
        ResolveId = ValueTypeint,
        ResolveCount = ValueTypeint,
        Exp = ValueTypeint,
        Description = ValueTypestring,
        IsShowInLibrary = ValueTypeint,
        Priority = ValueTypeint,
    },
    XTableSuperTowerPluginDrop = {
        Id = ValueTypeintPrimaryKey,
        PluginsDropGroupId = ValueTypeint,
        DropPlugins = ValueTypeint,
    },
    XTableSuperTowerRobot = {
        Id = ValueTypeintPrimaryKey,
        OpenHour = ValueTypeint,
        RobotId = Type1ValueTypeint,
    },
    XTableSuperTowerStageElement = {
        Element = ValueTypeintPrimaryKey,
        StageElementIcon = ValueTypestring,
    },
    XTableSuperTowerStarIcon = {
        Quality = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        Bg = ValueTypestring,
    },
    XTableSuperTowerTargetStage = {
        Id = ValueTypeintPrimaryKey,
        SimpleName = ValueTypestring,
        OpenHour = ValueTypeint,
        MapId = ValueTypeint,
        PreId = ValueTypeint,
        PreProgress = ValueTypeint,
        Type = ValueTypeint,
        Progress = ValueTypeint,
        Bg = ValueTypestring,
        StageId = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
        StageAbility = Type1ValueTypeint,
        MemberCount = Type1ValueTypeint,
    },
    XTableSuperTowerTier = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Tier = ValueTypeint,
        MapId = ValueTypeint,
        PluginDropId = ValueTypeint,
        Score = Type1ValueTypeint,
    },
    XTableSuperTowerTierEnhancerAndDrop = {
        Id = ValueTypeintPrimaryKey,
        PluginsPreviewName = Type1ValueTypestring,
        PluginsPreviewId = Type1ValueTypeint,
        EnhancerDropGroupId = ValueTypeint,
        PluginsDropLevel = Type1ValueTypeint,
        PluginsDropGroupId = Type1ValueTypeint,
    },
    XTableSuperTowerTierEnhancerDrop = {
        Id = ValueTypeint,
        MapId = ValueTypeint,
        Tier = ValueTypeint,
        CommonDropId = ValueTypeint,
        Weight = Type1ValueTypeint,
    },
    XTableSuperTowerTierScoreRatio = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
    },
    XTableSwitchableSceneClientConfig = {
        Id = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableSwitchableSceneGyro = {
        SceneId = ValueTypeintPrimaryKey,
        Angle = Type1ValueTypeint,
        Distance = Type1ValueTypeint,
        Speed = Type1ValueTypeint,
    },
    XTableSwitchableSceneSettings = {
        Id = ValueTypeintPrimaryKey,
        SwitchType = ValueTypeint,
        TipsOpInPc = ValueTypestring,
        TipsOpInCloud = ValueTypestring,
        TipsOpInPhone = ValueTypestring,
    },
    XTableSystemReset = {
        ResetKey = ValueTypeintPrimaryKey,
        ResetType = ValueTypeint,
        ResetTime = ValueTypestring,
    },
    XTableTaikoMasterActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        MusicId = ValueTypeint,
        HelpId = ValueTypeint,
        SettingStageId = ValueTypeint,
        TeachStageId = ValueTypeint,
        TaskTimeLimitId = ValueTypeint,
        BannerBg = ValueTypestring,
        SongId = Type1ValueTypeint,
    },
    XTableTaikoMasterAssess = {
        Assess = ValueTypestringPrimaryKey,
        Image = ValueTypestring,
    },
    XTableTaikoMasterScore = {
        StageId = ValueTypeintPrimaryKey,
        JudgeName = Type1ValueTypestring,
        JudgeScore = Type1ValueTypeint,
        ProgressScore = ValueTypeint,
        Hit = ValueTypeint,
        Perfect = ValueTypeint,
        PositionNum = ValueTypeint,
    },
    XTableTaikoMasterSetting = {
        Type = ValueTypeintPrimaryKey,
        Offset = Type1ValueTypeint,
    },
    XTableTaikoMasterSong = {
        SongId = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Title = ValueTypestring,
        Description1 = ValueTypestring,
        Description2 = ValueTypestring,
        SettlementImage = ValueTypestring,
        CoverImage = ValueTypestring,
        CoverBgImage = ValueTypestring,
        MusicId = ValueTypeint,
        EasyStageId = ValueTypeint,
        HardStageId = ValueTypeint,
    },
    XTableTask = {
        Id = ValueTypeintPrimaryKey,
        SourceGroupId = ValueTypeint,
        Type = ValueTypeint,
        Priority = ValueTypeint,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        PreTaskId = ValueTypeint,
        ActivateCondition = Type1ValueTypeint,
        Condition = Type1ValueTypeint,
        Result = ValueTypeint,
        DropId = ValueTypeint,
        RewardId = ValueTypeint,
        SkipId = ValueTypeint,
        StartTime = ValueTypestring,
        EndTime = ValueTypestring,
        Suffix = ValueTypestring,
        ShowAfterTaskId = ValueTypeint,
        AchvType = ValueTypeint,
        GroupId = ValueTypeint,
        ShowAfterGroup = ValueTypeint,
        GroupTheme = ValueTypeint,
        ShowType = ValueTypeint,
        ShowCondition = ValueTypeint,
        Tag = ValueTypeint,
    },
    XTableTaskActiveness = {
        Type = ValueTypeintPrimaryKey,
        Activeness = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
        HonorRewardId = ValueTypeint,
        BigReward = ValueTypestring,
        ReissueRewardId = ValueTypeint,
        ReissueRewardMailId = ValueTypeint,
    },
    XTableTaskCondition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
    },
    XTableTaskForceConfig = {
        Id = ValueTypeintPrimaryKey,
        MaxTaskForceCount = ValueTypeint,
        ConditionId = ValueTypeint,
    },
    XTableTaskForceExpend = {
        RefreshCount = ValueTypeintPrimaryKey,
        ItemId = ValueTypeint,
        ItemCount = ValueTypeint,
    },
    XTableTaskForceSection = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ConditionId = ValueTypeint,
        TaskCount = ValueTypeint,
        TaskPoolId = ValueTypeint,
        SectionIcon = ValueTypestring,
        SectionChapterIcon = ValueTypestring,
        Desc = Type1ValueTypestring,
    },
    XTableTaskForceTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TaskPoolId = ValueTypeint,
        Quality = ValueTypeint,
        RandomWeight = ValueTypeint,
        ShowId = ValueTypeint,
        DropId = ValueTypeint,
        RewardId = ValueTypeint,
        Duration = ValueTypeint,
        Priority = ValueTypeint,
        ExtraRewardId = ValueTypeint,
        ExtraRewardConditionId = ValueTypeint,
        ConditionList = Type1ValueTypeint,
        MemberCount = ValueTypeint,
    },
    XTableTaskPool = {
        TaskPoolId = ValueTypeint,
        Desc = ValueTypestring,
        TaskId = Type1ValueTypeint,
    },
    XTableTaskReset = {
        ResetId = ValueTypeint,
        Type = ValueTypeint,
        LowerLevel = ValueTypeint,
        UpperLevel = ValueTypeint,
        TaskPool = Type1ValueTypeint,
    },
    XTableTaskTimeLimit = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        PlayerCondition = Type1ValueTypeint,
        Duration = ValueTypeint,
        TaskId = Type1ValueTypeint,
        DayTaskId = Type1ValueTypeint,
        WeekTaskId = Type1ValueTypeint,
        ReissueMailId = ValueTypeint,
    },
    XTableTeachingActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        ChallengeStage = Type1ValueTypeint,
        StageId = Type1ValueTypeint,
        LinkStageId = Type1ValueTypeint,
        ShowRewardId = ValueTypeint,
        TreasureId = Type1ValueTypeint,
        TotalStars = ValueTypeint,
        FubenPrefab = ValueTypestring,
        GridFubenPrefab = ValueTypestring,
        FubenChallengePrefab = ValueTypestring,
        GridFubenChallengePrefab = ValueTypestring,
        ConditionId = ValueTypeint,
        MainFullBgPrefab = ValueTypestring,
        MainPanelPrefab = ValueTypestring,
        BannerBg = ValueTypestring,
        CharacterId = ValueTypeint,
        SkipIdDraw = ValueTypeint,
        SkipIdChar = ValueTypeint,
        SkipIdSkin = ValueTypeint,
        NewCharType = ValueTypeint,
        MovieId = ValueTypeint,
        SkipGet = ValueTypeint,
        ChallengeCondition = ValueTypeint,
        CustomUiControlType = ValueTypeint,
        UiName = ValueTypestring,
        TeachingDetailUiName = ValueTypestring,
        ChallengeDetailUiName = ValueTypestring,
    },
    XTableTeachingActivityBGM = {
        ActivityId = ValueTypeintPrimaryKey,
        CueIds = Type1ValueTypeint,
        CueConditions = Type1ValueTypeint,
    },
    XTableTeachingClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableTeachingRobot = {
        StageId = ValueTypeintPrimaryKey,
        DescDetail = ValueTypestring,
        ShowFightEventIds = Type1ValueTypeint,
        RobotId = Type1ValueTypeint,
        CharacterType = ValueTypeint,
    },
    XTableTeachingTreasure = {
        TreasureId = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        RequireStage = ValueTypeint,
        RequireStar = ValueTypeint,
        RewardId = ValueTypeint,
        Description = ValueTypestring,
        Title = ValueTypestring,
    },
    XTableTeachingTrustStoryChapter = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        CharacterId = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableTeam = {
        Id = ValueTypeintPrimaryKey,
        IsCaptain = ValueTypebool,
        IsFirstFight = ValueTypebool,
        EffectPath = ValueTypestring,
        Color = ValueTypestring,
        SelectColor = ValueTypestring,
        DiagonalColor = ValueTypestring,
    },
    XTableTeamPrefabTag = {
        Id = ValueTypeintPrimaryKey,
        TagType = ValueTypeint,
        Text = ValueTypestring,
        Icon = ValueTypestring,
        Order = ValueTypeint,
    },
    XTableTeamRankReward = {
        Id = ValueTypeintPrimaryKey,
        ChallengeId = ValueTypeint,
        MinRank = ValueTypeint,
        MaxRank = ValueTypeint,
        MailId = ValueTypeint,
    },
    XTableTeamType = {
        TeamId = ValueTypeintPrimaryKey,
        TypeId = ValueTypeint,
        ChapterId = Type1ValueTypeint,
        SectionId = Type1ValueTypeint,
        StageId = Type1ValueTypeint,
    },
    XTableTemplateSetAttrib = {
        Id = ValueTypeintPrimaryKey,
        Comment = ValueTypestring,
        NpcId = ValueTypeint,
        Attrib = Type1ValueTypeint,
        Value = Type1ValueTypeint,
    },
    XTableTemple2Activity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        ChapterIds = Type1ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableTemple2Block = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TypeName = ValueTypestring,
        Grid1 = Type1ValueTypeint,
        Grid2 = Type1ValueTypeint,
        Grid3 = Type1ValueTypeint,
        EffectiveTimes = ValueTypeint,
        NoRotate = ValueTypeint,
    },
    XTableTemple2BlockOption = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        Desc = ValueTypestring,
        NameList = Type1ValueTypestring,
    },
    XTableTemple2Bubble = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        StoryId = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        CharacterIcon = ValueTypestring,
        StoryDescSimple = ValueTypestring,
        StoryDesc = ValueTypestring,
        StoryTitle = ValueTypestring,
    },
    XTableTemple2Chapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        StageIds = Type1ValueTypeint,
        BubbleId = ValueTypeint,
    },
    XTableTemple2Chat = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Duration = ValueTypeint,
        NpcId = ValueTypeint,
        Text = ValueTypestring,
        Params = Type1ValueTypestring,
    },
    XTableTemple2Grid = {
        Id = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        RotationIcon90 = ValueTypestring,
        RotationIcon180 = ValueTypestring,
        RotationIcon270 = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        ShowOnStageDetail = ValueTypeint,
        Type = ValueTypeint,
        RotateIcon = ValueTypeint,
        Color = ValueTypeint,
        Score = ValueTypeint,
        Rule = Type1ValueTypeint,
        Prefab = ValueTypestring,
    },
    XTableTemple2Map = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Bg = ValueTypestring,
        BgWidth = ValueTypeint,
        BgHeight = ValueTypeint,
        BgOffsetX = ValueTypeint,
        BgOffsetY = ValueTypeint,
        Rule = Type1ValueTypeint,
    },
    XTableTemple2Npc = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Text = ValueTypestring,
        Icon = ValueTypestring,
        Head = ValueTypestring,
        SettleDesc = ValueTypestring,
    },
    XTableTemple2NpcTime = {
        Id = ValueTypeintPrimaryKey,
        Duration = ValueTypeint,
        NpcIds = Type1ValueTypeint,
    },
    XTableTemple2RandomStage = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        TimeId = ValueTypeint,
        MapId = Type1ValueTypeint,
    },
    XTableTemple2Rule = {
        Id = ValueTypeintPrimaryKey,
        RuleType = ValueTypeint,
        Name = ValueTypestring,
        RuleDesc = ValueTypestring,
        Params = Type1ValueTypeint,
        Bubble = ValueTypeint,
        NpcId = ValueTypeint,
        EffectiveTimes = ValueTypeint,
        IconRule = ValueTypestring,
        IconGrid = ValueTypestring,
    },
    XTableTemple2Stage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        PreStageId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableTemple2StageGame = {
        Id = ValueTypeintPrimaryKey,
        Map = Type1ValueTypeint,
        BlockPool = Type1ValueTypeint,
        RandomBlockPool = Type1ValueTypeint,
        RandomPoolAmount = ValueTypeint,
    },
    XTableTemple2Task = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        Type = ValueTypeint,
        TaskIds = Type1ValueTypeint,
    },
    XTableTempleActionRecord = {
        Id = ValueTypeintPrimaryKey,
        BlockId = ValueTypeint,
        X = ValueTypeint,
        Y = ValueTypeint,
        Round = ValueTypeint,
        OptionId = ValueTypeint,
        Rotation = ValueTypeint,
    },
    XTableTempleBlock = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Grid1 = Type1ValueTypeint,
        Grid2 = Type1ValueTypeint,
        Grid3 = Type1ValueTypeint,
        Grid4 = Type1ValueTypeint,
        Grid5 = Type1ValueTypeint,
        Grid6 = Type1ValueTypeint,
    },
    XTableTempleConstConfig = {
        Key = ValueTypestringPrimaryKey,
        Value = ValueTypeint,
        ValueStr = ValueTypestring,
    },
    XTableTempleFairActivity = {
        Id = ValueTypeintPrimaryKey,
        ActivityName = ValueTypestring,
        TimeId = ValueTypeint,
    },
    XTableTempleFairChapter = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        TimeId = ValueTypeint,
        ChapterName = ValueTypestring,
    },
    XTableTempleFairStage = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        ChapterId = ValueTypeint,
        StageName = ValueTypestring,
        StageDesc = ValueTypestring,
        StageKind = ValueTypeint,
        TimeId = ValueTypeint,
        LastStage = ValueTypeint,
        StageNpc = ValueTypeint,
        StarNumberScore = Type1ValueTypeint,
        Bg = ValueTypestring,
        Message = ValueTypestring,
        DetailBg = ValueTypestring,
        ImageNumber = ValueTypestring,
    },
    XTableTempleGrid = {
        Id = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Type = ValueTypeint,
        RotateIcon = ValueTypeint,
        FusionType = ValueTypeint,
        Fusion = Type1ValueTypestring,
    },
    XTableTempleNpc = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Name = ValueTypestring,
        Body = ValueTypestring,
        TextStageEnter = Type1ValueTypestring,
        TextStageSettle = Type1ValueTypestring,
        TextRefreshBlock = Type1ValueTypestring,
        TextChooseBlock = Type1ValueTypestring,
        TextMoveBlock = Type1ValueTypestring,
        TextRotateBlock = Type1ValueTypestring,
        TextCancelBlock = Type1ValueTypestring,
        TextFail = Type1ValueTypestring,
        SmartPutDownBlock = ValueTypeint,
    },
    XTableTempleRule = {
        Id = ValueTypeintPrimaryKey,
        Text = ValueTypestring,
    },
    XTableTempleStageGame = {
        Id = ValueTypeintPrimaryKey,
        OptionRound = ValueTypeint,
        OptionId = ValueTypeint,
        OptionBlock = ValueTypeint,
        OptionReward = ValueTypeint,
        OptionSpend = ValueTypeint,
        RuleId = ValueTypeint,
        RuleName = ValueTypestring,
        RuleType = ValueTypeint,
        RuleParams = Type1ValueTypeint,
        RuleTime = Type1ValueTypeint,
        RuleScore = ValueTypeint,
        RuleIsHide = ValueTypeint,
        Rule4Grid = ValueTypeint,
        Map = Type1ValueTypeint,
        Time = ValueTypeint,
        TimeDuration = ValueTypeint,
    },
    XTableTempleTime = {
        Id = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        IconOn = ValueTypestring,
        IconOff = ValueTypestring,
    },
    XTableTheatre3Achievement = {
        Id = ValueTypeintPrimaryKey,
        TagName = ValueTypestring,
        TaskIds = Type1ValueTypeint,
    },
    XTableTheatre3Activity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        NeedCounts = Type2KeyTypeintValueTypeint,
        RewardIds = Type2KeyTypeintValueTypeint,
    },
    XTableTheatre3BaseGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
        KeyId = ValueTypeint,
        AddWeightCondition = ValueTypeint,
        AddWeight = ValueTypeint,
    },
    XTableTheatre3BattlePass = {
        Level = ValueTypeintPrimaryKey,
        NeedExp = ValueTypeint,
        RewardId = ValueTypeint,
        Display = ValueTypeint,
    },
    XTableTheatre3Chapter = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        ChapterName = ValueTypestring,
        NextChapterIds = Type1ValueTypeint,
        ConditionId = ValueTypeint,
        ConnectChapter = ValueTypeint,
        OpenSuitCount = ValueTypeint,
        BgmCueId = ValueTypeint,
        PlayMainBg = ValueTypestring,
        LoadingBgUrl = ValueTypestring,
        LoadingTitle = ValueTypestring,
        LoadingDesc = ValueTypestring,
        TitleEffect = ValueTypestring,
        ChapterType = ValueTypeint,
    },
    XTableTheatre3ChapterGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupName = ValueTypestring,
    },
    XTableTheatre3CharacterEnding = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        EndingId = ValueTypeint,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        ConditionId = ValueTypeint,
        EffectGroupId = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableTheatre3CharacterGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupName = ValueTypestring,
        EnergyCost = ValueTypeint,
        OrderId = ValueTypeint,
    },
    XTableTheatre3CharacterLevel = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Level = ValueTypeint,
        NeedExp = ValueTypeint,
        Desc = ValueTypestring,
        StrengthenPoint = ValueTypeint,
        EffectGroupId = ValueTypeint,
    },
    XTableTheatre3CharacterRecruit = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        CharacterId = ValueTypeint,
        RobotId = ValueTypeint,
        Property = ValueTypeint,
        Note = ValueTypestring,
        Weight = ValueTypeint,
        RepeatWeight = ValueTypeint,
    },
    XTableTheatre3ClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableTheatre3Config = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Value = ValueTypestring,
    },
    XTableTheatre3ContentLib = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Type = ValueTypeint,
        LibId = ValueTypeint,
        LowerLimit = ValueTypeint,
        UpperLimit = ValueTypeint,
        Weight = ValueTypeint,
        DropGroupId = ValueTypeint,
        AtkFactor = Type1ValueTypeint,
        HpFactor = Type1ValueTypeint,
        ConditionId = ValueTypeint,
        AddWeight = ValueTypeint,
        AddWeightCondition = ValueTypeint,
    },
    XTableTheatre3DestinyWeight = {
        Id = ValueTypeintPrimaryKey,
        Value = ValueTypeint,
        Weight = ValueTypeint,
        RepeatWeight = ValueTypeint,
    },
    XTableTheatre3Difficulty = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        StoryDesc = ValueTypestring,
        ConditionId = ValueTypeint,
        ChapterGroupId = ValueTypeint,
        FirstPassFlag = ValueTypeint,
        CharacterExpRate = ValueTypefloat,
        BPExpRate = ValueTypefloat,
        BgIcon = ValueTypestring,
        FightEvents = Type1ValueTypeint,
        RebootId = ValueTypeint,
        InitialItem = ValueTypeint,
    },
    XTableTheatre3DropGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Probability = ValueTypeint,
        IsShow = ValueTypeint,
        ItemBoxWeight = ValueTypeint,
        ItemBoxGroupId = ValueTypeint,
        ItemBoxUpperLimit = ValueTypeint,
        ItemBoxLowerLimit = ValueTypeint,
        GoldWeight = ValueTypeint,
        GoldGroupId = ValueTypeint,
        GoldUpperLimit = ValueTypeint,
        GoldLowerLimit = ValueTypeint,
        EquipWeight = ValueTypeint,
        EquipBoxGroupId = ValueTypeint,
        EquipBoxUpperLimit = ValueTypeint,
        EquipBoxLowerLimit = ValueTypeint,
        Tag = ValueTypeint,
    },
    XTableTheatre3EffectGroup = {
        Id = ValueTypeintPrimaryKey,
        FightEvents = Type1ValueTypeint,
        SystemEvents = Type1ValueTypeint,
        Note = ValueTypestring,
    },
    XTableTheatre3EffectGroupDesc = {
        EffectGroupId = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        DescList = Type1ValueTypestring,
        BaseValueList = Type1ValueTypestring,
    },
    XTableTheatre3Ending = {
        Id = ValueTypeintPrimaryKey,
        PassType = ValueTypeint,
        Priority = ValueTypeint,
        Factor = ValueTypefloat,
        Type = Type1ValueTypeint,
        Param = Type1ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        DescColor = ValueTypestring,
        StoryId = Type1ValueTypestring,
        StoryCondition = Type1ValueTypeint,
        RImgDesc = ValueTypestring,
        Bg = ValueTypestring,
        SpineBg = ValueTypestring,
        RImgTitle = ValueTypestring,
        Icon = ValueTypestring,
        IconBg = ValueTypestring,
        RecordIndex = ValueTypeint,
        BgmCueId = ValueTypeint,
    },
    XTableTheatre3EnergyUnused = {
        Id = ValueTypeintPrimaryKey,
        UnusedCount = ValueTypeint,
        FightEventId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableTheatre3Equip = {
        Id = ValueTypeintPrimaryKey,
        EquipName = ValueTypestring,
        Level = ValueTypeint,
        AttType = ValueTypeint,
        SuitId = ValueTypeint,
        BaseAttFightEventIds = Type1ValueTypeint,
        BaseAttDesc = Type1ValueTypestring,
        EffectDesc = ValueTypestring,
        EffectGroupId = ValueTypeint,
        Icon = ValueTypestring,
        TraitName = Type1ValueTypestring,
        TraitDesc = Type1ValueTypestring,
        StoryDesc = ValueTypestring,
        UseType = ValueTypeint,
        PosType = ValueTypeint,
        GlobalFightEventIds = Type1ValueTypeint,
        SimpleEffectDesc = ValueTypestring,
        RecordDamage = ValueTypebool,
        QubitEffectGroupId = ValueTypeint,
        QubitEffectDesc = ValueTypestring,
        QubitSampleEffectDesc = ValueTypestring,
        QubitTraitName = Type1ValueTypestring,
        QubitTraitDesc = Type1ValueTypestring,
        QubitGlobalFightEventIds = Type1ValueTypeint,
    },
    XTableTheatre3EquipBox = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        EquipGroupId = ValueTypeint,
        ExtractCount = ValueTypeint,
        MaxSelectCount = ValueTypeint,
        CharacterAddWeight = ValueTypeint,
        EquipBoxName = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Quality = ValueTypeint,
        Tag = ValueTypeint,
        FreeRefreshNum = ValueTypeint,
        RefreshCostNum = ValueTypeint,
        RefreshCost = Type1ValueTypeint,
    },
    XTableTheatre3EquipBoxGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        EquipBoxId = ValueTypeint,
        Weight = ValueTypeint,
        RepeatWeight = ValueTypeint,
        ConditionId = ValueTypeint,
    },
    XTableTheatre3EquipDamageSource = {
        EquipId = ValueTypeintPrimaryKey,
        BehaviorId = Type1ValueTypeint,
        MagicId = Type1ValueTypeint,
    },
    XTableTheatre3EquipGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        EquipId = ValueTypeint,
        Weight = ValueTypeint,
        SuitLevel = Type2KeyTypeintValueTypeint,
        SuitLevelAddWeight = Type2KeyTypeintValueTypeint,
    },
    XTableTheatre3EquipSuit = {
        Id = ValueTypeintPrimaryKey,
        AttType = ValueTypeint,
        SuitName = ValueTypestring,
        UseType = ValueTypeint,
        SuitEffectGroupId = ValueTypeint,
        Desc = ValueTypestring,
        TraitName = Type1ValueTypestring,
        TraitDesc = Type1ValueTypestring,
        StoryDesc = ValueTypestring,
        Icon = ValueTypestring,
        RecommendDesc = ValueTypestring,
        SimpleEffectDesc = ValueTypestring,
        QubitSuitEffectGroupId = ValueTypeint,
        QubitDesc = ValueTypestring,
        QubitSampleEffectDesc = ValueTypestring,
        QubitTraitName = Type1ValueTypestring,
        QubitTraitDesc = Type1ValueTypestring,
    },
    XTableTheatre3EquipSuitEffectGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        ActivateLevel = ValueTypeint,
        EffectGroupId = ValueTypeint,
        Desc = ValueTypestring,
        GlobalFightEventIds = Type1ValueTypeint,
    },
    XTableTheatre3EquipSuitOnStart = {
        Id = ValueTypeintPrimaryKey,
        SuitId = ValueTypeint,
        EnsureFlag = ValueTypeint,
        Weight = ValueTypeint,
        RepeatWeight = ValueTypeint,
        ExcludeSuitIds = Type1ValueTypeint,
        AddWeightSuitIds = Type1ValueTypeint,
        AddWeights = Type1ValueTypeint,
    },
    XTableTheatre3EquipSuitType = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableTheatre3Event = {
        Id = ValueTypeintPrimaryKey,
        EventId = ValueTypeint,
        StepId = ValueTypeint,
        NextStepId = ValueTypeint,
        Type = ValueTypeint,
        FightNodeId = ValueTypeint,
        WorkShopId = ValueTypeint,
        EffectGroupId = ValueTypeint,
        StoryId = ValueTypestring,
        StepRewardItemType = ValueTypeint,
        StepRewardItemId = Type2KeyTypeintValueTypeint,
        StepRewardItemCount = Type2KeyTypeintValueTypeint,
        OptionGroupId = ValueTypeint,
        Title = ValueTypestring,
        TitleContent = ValueTypestring,
        RoleIcon = ValueTypestring,
        RoleName = ValueTypestring,
        RoleContent = ValueTypestring,
        RoleEffect = ValueTypestring,
        EventDesc = ValueTypestring,
        ConfirmContent = ValueTypestring,
        BgAsset = ValueTypestring,
    },
    XTableTheatre3EventGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
        KeyId = ValueTypeint,
        EventId = ValueTypeint,
        LinkGroupId = ValueTypeint,
        AddWeight = Type1ValueTypeint,
        AddWeightCondition = Type1ValueTypeint,
    },
    XTableTheatre3EventNode = {
        EventId = ValueTypeintPrimaryKey,
        NodeName = ValueTypestring,
        NodeIcon = ValueTypestring,
        NodeBg = ValueTypestring,
        NodeDesc = ValueTypestring,
        NodeEffectUrl = ValueTypestring,
        UnDefeatNode = ValueTypeint,
    },
    XTableTheatre3EventOptionGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        OptionDesc = ValueTypestring,
        OptionDownDesc = ValueTypestring,
        OptionIcon = ValueTypestring,
        OptionType = ValueTypeint,
        OptionItemType = ValueTypeint,
        OptionItemId = Type2KeyTypeintValueTypeint,
        OptionItemCount = Type2KeyTypeintValueTypeint,
        OptionNextStepGroupId = ValueTypeint,
        OptionCondition = ValueTypeint,
        OptionShowCondition = ValueTypeint,
        QuantumEffectShowType = ValueTypeint,
    },
    XTableTheatre3EventStepGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        StepId = ValueTypeint,
        Weight = ValueTypeint,
        NodeEnterLimit = ValueTypeint,
    },
    XTableTheatre3FightExtraWave = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        MonsterGroupId = ValueTypeint,
        UpperLimit = ValueTypeint,
        Weight = ValueTypeint,
        ItemBoxId = ValueTypeint,
    },
    XTableTheatre3FightExtraWaveLimit = {
        Id = ValueTypeintPrimaryKey,
        UpperLimit = ValueTypeint,
    },
    XTableTheatre3FightLib = {
        FightNodeId = ValueTypeint,
        LinkGroupId = ValueTypeint,
        RepeatWeight = ValueTypeint,
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
        KeyId = ValueTypeint,
        AddWeightCondition = ValueTypeint,
        AddWeight = ValueTypeint,
    },
    XTableTheatre3FightNode = {
        Id = ValueTypeintPrimaryKey,
        TemplateId = ValueTypeint,
        Difficulty = ValueTypeint,
        IsBoss = ValueTypeint,
        EquipBoxIds = Type1ValueTypeint,
        GoldIds = Type1ValueTypeint,
        ItemBoxIds = Type1ValueTypeint,
        NodeName = ValueTypestring,
        NodeIcon = ValueTypestring,
        NodeBg = ValueTypestring,
        NodeDesc = ValueTypestring,
        NodeEffectUrl = ValueTypestring,
    },
    XTableTheatre3FightStageTemplate = {
        Id = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        TemplateId = ValueTypeint,
        StageId = ValueTypeint,
        Weight = ValueTypeint,
        Mode = ValueTypeint,
        ModeParams = Type1ValueTypeint,
        TimeLimit = ValueTypeint,
        MonsterGroupId = Type1ValueTypeint,
        GroupOrder = ValueTypeint,
        IsQubitStage = ValueTypeint,
        QubitMonsterGroup = Type1ValueTypeint,
        QubitValue = Type1ValueTypestring,
        QubitEquipBoxGroup = Type1ValueTypeint,
        QubitItemBoxGroup = Type1ValueTypeint,
        QubitGoldGroup = Type1ValueTypeint,
        FightEventIds = Type1ValueTypeint,
        SuggestAbility = ValueTypeint,
        ExtraWaveGroupId = ValueTypeint,
        ExtraWaveRate = ValueTypeint,
        ExtraWaveTime = ValueTypeint,
        BaseHp = ValueTypeint,
    },
    XTableTheatre3Gold = {
        Id = ValueTypeintPrimaryKey,
        Count = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        Tag = ValueTypeint,
    },
    XTableTheatre3GoldGroup = {
        GoldId = ValueTypeint,
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
        KeyId = ValueTypeint,
        AddWeightCondition = ValueTypeint,
        AddWeight = ValueTypeint,
    },
    XTableTheatre3Item = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ObtainMaxCount = ValueTypeint,
        Type = ValueTypeint,
        Quality = ValueTypeint,
        UnlockConditionId = ValueTypeint,
        EffectGroupId = ValueTypeint,
        Description = ValueTypestring,
        WorldDesc = ValueTypestring,
        Icon = ValueTypestring,
        ExpireTime = ValueTypeint,
        BgType = ValueTypeint,
        IsFireItem = ValueTypeint,
        FireNum = ValueTypeint,
        DiffcultId = ValueTypeint,
    },
    XTableTheatre3ItemBox = {
        Id = ValueTypeintPrimaryKey,
        BoxGroupId = ValueTypeint,
        Weight = ValueTypeint,
        ConditionId = ValueTypeint,
        ItemGroupId = Type1ValueTypeint,
        SafeGroupId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        Quality = ValueTypeint,
        Tag = ValueTypeint,
    },
    XTableTheatre3ItemGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        ItemId = ValueTypeint,
        Weight = ValueTypeint,
        InitialCondition = ValueTypeint,
    },
    XTableTheatre3ItemType = {
        Type = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ShowInArchive = ValueTypeint,
    },
    XTableTheatre3Monster = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Level = ValueTypeint,
        BuffLevel = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
        Note = ValueTypestring,
    },
    XTableTheatre3MonsterGroup = {
        Id = ValueTypeintPrimaryKey,
        MonsterIds = Type1ValueTypeint,
        Note = ValueTypestring,
    },
    XTableTheatre3Node = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        CountWeight = Type1ValueTypeint,
        ContentLibId = ValueTypeint,
        ConditionId = ValueTypeint,
        ConnectNode = ValueTypeint,
        UnDefeatNode = ValueTypeint,
    },
    XTableTheatre3NodeLink = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        LinkType = ValueTypeint,
        LinkTargetId = ValueTypeint,
        LinkAddWeight = ValueTypeint,
        DelNodeIds = Type1ValueTypeint,
    },
    XTableTheatre3NodeShop = {
        Id = ValueTypeintPrimaryKey,
        ShopType = ValueTypeint,
        DiscountNum = ValueTypeint,
        DiscountRate = ValueTypeint,
        RewardBoxType = ValueTypeint,
        RewardBoxId = ValueTypeint,
        GroupId = Type1ValueTypeint,
        ConditionId = Type1ValueTypeint,
        TitleContent = ValueTypestring,
        RoleIcon = ValueTypestring,
        RoleName = ValueTypestring,
        RoleContent = ValueTypestring,
        Desc = ValueTypestring,
        EndDesc = ValueTypestring,
        EndComfirmText = ValueTypestring,
        EndTitleDesc = ValueTypestring,
        EndRoleContent = ValueTypestring,
        BgAsset = ValueTypestring,
        NodeName = ValueTypestring,
        NodeIcon = ValueTypestring,
        NodeBg = ValueTypestring,
        NodeDesc = ValueTypestring,
        NodeEffectUrl = ValueTypestring,
    },
    XTableTheatre3NodeShopGroup = {
        ShopId = ValueTypeint,
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
        KeyId = ValueTypeint,
        AddWeightCondition = ValueTypeint,
        AddWeight = ValueTypeint,
    },
    XTableTheatre3NodeShopItem = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        ItemType = ValueTypeint,
        ItemId = ValueTypeint,
        EquipBoxId = ValueTypeint,
        ItemBoxId = ValueTypeint,
        Weight = ValueTypeint,
        Price = ValueTypeint,
    },
    XTableTheatre3QubitEffect = {
        Id = ValueTypeintPrimaryKey,
        QubitA = ValueTypeint,
        QubitB = ValueTypeint,
        EffectGroupId = ValueTypeint,
        CoverId = ValueTypeint,
        Desc = ValueTypestring,
        IsShake = ValueTypeint,
        ShowType = ValueTypeint,
    },
    XTableTheatre3QubitLevel = {
        Level = ValueTypeintPrimaryKey,
        Exp = ValueTypeint,
        FightDesc = ValueTypestring,
        Title = ValueTypestring,
        LevelUpTxt = ValueTypestring,
        ScreenEffectUrl = ValueTypestring,
        IsShake = ValueTypeint,
    },
    XTableTheatre3QubitShowLevel = {
        Id = ValueTypeintPrimaryKey,
        QubitType = ValueTypeint,
        Value = ValueTypeint,
    },
    XTableTheatre3QubitUpTxt = {
        Id = ValueTypeintPrimaryKey,
        QubitType = ValueTypeint,
        Value = ValueTypeint,
        ShowTxtList = Type1ValueTypestring,
    },
    XTableTheatre3Reboot = {
        Id = ValueTypeintPrimaryKey,
        RebootCost = ValueTypeint,
        MaxRebootCount = ValueTypeint,
        FubenRestartCost = ValueTypeint,
        FubenClashCost = ValueTypeint,
        HpRetain = ValueTypefix,
    },
    XTableTheatre3SettleFactor = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Factor = Type1ValueTypefloat,
    },
    XTableTheatre3StrengthenTree = {
        Id = ValueTypeintPrimaryKey,
        NeedStrengthenPoint = ValueTypeint,
        PointType = ValueTypeint,
        EffectGroupId = ValueTypeint,
        Condition = ValueTypeint,
        Page = ValueTypeint,
        PreId = Type1ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        Note = ValueTypestring,
    },
    XTableTheatre3SystemEffect = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        Params = Type1ValueTypefloat,
    },
    XTableTheatre3Task = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        MainShowOrder = ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTableTheatre3WorkShop = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Count = ValueTypeint,
    },
    XTableTheatre4ActionFactor = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        ActionTimes = ValueTypeint,
        Factor = ValueTypeint,
    },
    XTableTheatre4Activity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        Version = ValueTypeint,
        TalentRefreshLimitNum = ValueTypeint,
        TalentRefreshFreeNum = ValueTypeint,
        TalentRefreshCost = Type1ValueTypeint,
    },
    XTableTheatre4Affix = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        RecruitTicketId = Type1ValueTypeint,
        EffectGroupId = ValueTypeint,
        ConditionId = ValueTypeint,
        Desc = ValueTypestring,
        TeamLogo = Type1ValueTypestring,
        TeamLogoCondition = Type1ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableTheatre4Asset = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        WorldDesc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableTheatre4BattlePass = {
        Level = ValueTypeintPrimaryKey,
        NeedExp = ValueTypeint,
        RewardId = ValueTypeint,
        Display = ValueTypeint,
    },
    XTableTheatre4Block = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        SizeX = ValueTypeint,
        SizeY = ValueTypeint,
        BaseWeight = ValueTypeint,
        DefaultColorGroup = ValueTypeint,
        DefaultColorResourceGroup = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        ConditionWeight = Type1ValueTypeint,
    },
    XTableTheatre4BlockGrid = {
        Id = ValueTypeintPrimaryKey,
        PosX = ValueTypeint,
        PosY = ValueTypeint,
        SizeX = ValueTypeint,
        SizeY = ValueTypeint,
        DefaultVisible = ValueTypeint,
        ColorGroup = ValueTypeint,
        ColorResourceGroup = ValueTypeint,
        Type = ValueTypeint,
        ContentGroup = ValueTypeint,
        BlockFlag = ValueTypeint,
        DisableCountDown = ValueTypeint,
    },
    XTableTheatre4BlockGroup = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        BaseWeight = ValueTypeint,
        RelationGroup = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        ConditionWeight = Type1ValueTypeint,
        BlockId = Type1ValueTypeint,
    },
    XTableTheatre4BlockIcon = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        DefaultIcon = ValueTypestring,
        ColorIcon = Type1ValueTypestring,
    },
    XTableTheatre4BlockRelation = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        BlockGroupId = ValueTypeint,
        AddWeight = ValueTypeint,
    },
    XTableTheatre4BoxGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        DropId = ValueTypeint,
        Weight = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        BlockIcon = ValueTypeint,
        Title = ValueTypestring,
        TitleContent = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTheatre4Building = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        MaxCountInChapter = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Title = ValueTypestring,
        TitleContent = ValueTypestring,
        Desc = ValueTypestring,
        SkillPicture = ValueTypestring,
    },
    XTableTheatre4Character = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        RobotId = ValueTypeint,
        StarGroupId = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableTheatre4CharacterGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        CharacterId = ValueTypeint,
        Weight = ValueTypeint,
        Star = ValueTypeint,
        AddWeightCondition = Type1ValueTypeint,
        AddWeight = Type1ValueTypeint,
    },
    XTableTheatre4CharacterStar = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Star = ValueTypeint,
        ColorLevel = Type1ValueTypeint,
    },
    XTableTheatre4ClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Note = ValueTypestring,
        Params = Type1ValueTypestring,
    },
    XTableTheatre4ColorResource = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Desc = ValueTypestring,
        Color = ValueTypeint,
        Weight = ValueTypeint,
        Resource = Type1ValueTypeint,
    },
    XTableTheatre4ColorTalent = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        Type = ValueTypeint,
        ShowLevel = ValueTypeint,
        IsSkill = ValueTypeint,
        RelationGroup = ValueTypeint,
        EffectGroupId = ValueTypeint,
        JoinSettle = ValueTypeint,
        JoinAdventureSettle = ValueTypeint,
        ColorType = ValueTypeint,
        Condition = ValueTypeint,
        Param = Type1ValueTypefloat,
        Tags = Type1ValueTypestring,
        TagBgColors = Type1ValueTypestring,
        ParentNode = Type1ValueTypeint,
    },
    XTableTheatre4ColorTalentPool = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        TalentId = ValueTypeint,
        Repeatable = ValueTypeint,
        Weight = ValueTypeint,
        UnlockCondition = ValueTypeint,
        AddWeightCondition = Type1ValueTypeint,
        AddWeight = Type1ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableTheatre4ColorTalentRelation = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Group = ValueTypeint,
        Type = ValueTypeint,
        TalentId = ValueTypeint,
        AddWeight = ValueTypeint,
    },
    XTableTheatre4ColorTalentSlot = {
        Id = ValueTypeintPrimaryKey,
        Color = ValueTypeint,
        GeneratePoolGroup = ValueTypeint,
        GenerateType = ValueTypeint,
        GenerateNum = ValueTypeint,
        UnlockPoint = ValueTypeint,
        UnlockCondition = ValueTypeint,
        Level = ValueTypeint,
    },
    XTableTheatre4ColorTalentTree = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Type = ValueTypeint,
        GroupId = ValueTypeint,
        Level = ValueTypeint,
        Resource = ValueTypeint,
        ConditionId = ValueTypeint,
        Param = Type1ValueTypeint,
    },
    XTableTheatre4ColorWeight = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Color = ValueTypeint,
        Weight = ValueTypeint,
        AddWeightCondition = ValueTypeint,
        AddWeight = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableTheatre4Config = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableTheatre4DifficultDistance = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        Distance = ValueTypeint,
        AtkFactor = ValueTypeint,
        HpFactor = ValueTypeint,
    },
    XTableTheatre4Difficulty = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        StoryDesc = ValueTypestring,
        Temperature = ValueTypestring,
        Desc = Type1ValueTypestring,
        ConditionId = ValueTypeint,
        DifficultRate = ValueTypefloat,
        BPExpRate = ValueTypefloat,
        BPExpMax = ValueTypeint,
        TechPointRate = ValueTypefloat,
        TechPointMax = ValueTypeint,
        DistanceGroup = ValueTypeint,
        RebootId = ValueTypeint,
        ActionPoint = ValueTypeint,
        Hp = ValueTypeint,
        HpActionPoint = ValueTypeint,
        Energy = ValueTypeint,
        ReEnergy = ValueTypeint,
        ActionGroup = ValueTypeint,
        AtkFactor = Type1ValueTypeint,
        HpFactor = Type1ValueTypeint,
        EffectGroup = Type1ValueTypeint,
        RewardDrop = Type1ValueTypeint,
        StarGroupIds = Type1ValueTypeint,
        SnowEffect = ValueTypestring,
    },
    XTableTheatre4DifficultyStar = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        RewardBpExp = ValueTypeint,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        Condition = ValueTypeint,
        Title = ValueTypestring,
    },
    XTableTheatre4Effect = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Desc1 = ValueTypestring,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        SkillCostType = ValueTypeint,
        SkillCostId = ValueTypeint,
        SkillCostCount = ValueTypeint,
        SkillCostUp = Type1ValueTypeint,
        SkillCostResetType = ValueTypeint,
    },
    XTableTheatre4EffectGroup = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Desc1 = ValueTypestring,
        Effects = Type1ValueTypeint,
    },
    XTableTheatre4Ending = {
        Id = ValueTypeintPrimaryKey,
        PassType = ValueTypeint,
        Priority = ValueTypeint,
        Factor = ValueTypefloat,
        Condition = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        EndingDesc = ValueTypestring,
        DescColor = ValueTypestring,
        StoryId = Type1ValueTypestring,
        StoryCondition = Type1ValueTypeint,
        RImgDesc = ValueTypestring,
        Bg = ValueTypestring,
        BgEffect = ValueTypestring,
        SpineBg = ValueTypestring,
        RImgTitle = ValueTypestring,
        Icon = ValueTypestring,
        IconBg = ValueTypestring,
        RecordIndex = ValueTypeint,
        BgmCueId = ValueTypeint,
        MaxProsperity = ValueTypeint,
        MainBg = ValueTypestring,
        MainBgPriority = ValueTypeint,
    },
    XTableTheatre4Event = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        NextEvent = ValueTypeint,
        NextEventGroup = ValueTypeint,
        OptionGroupId = ValueTypeint,
        FightId = ValueTypeint,
        RewardId = Type1ValueTypeint,
        EffectGroupId = ValueTypeint,
        RoleIcon = ValueTypestring,
        RoleName = ValueTypestring,
        RoleContent = ValueTypestring,
        RoleEffect = ValueTypestring,
        ConfirmContent = ValueTypestring,
        IsEnd = ValueTypeint,
        IsForcePlay = ValueTypeint,
        BgAsset = ValueTypestring,
        StoryId = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        BlockIcon = ValueTypeint,
        Title = ValueTypestring,
        TitleContent = ValueTypestring,
        Desc = ValueTypestring,
        UnOpenDesc = ValueTypestring,
    },
    XTableTheatre4EventGroup = {
        Id = ValueTypeintPrimaryKey,
        Des = ValueTypestring,
        GroupId = ValueTypeint,
        EventId = ValueTypeint,
        Weight = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
        AddWeight = Type1ValueTypeint,
        AddWeightCondition = Type1ValueTypeint,
    },
    XTableTheatre4EventOption = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        OptionDesc = ValueTypestring,
        OptionDownDesc = ValueTypestring,
        OptionType = ValueTypeint,
        OptionItemType = ValueTypeint,
        OptionItemId = ValueTypeint,
        OptionItemCount = ValueTypeint,
        OptionStageScoreMin = ValueTypeint,
        OptionStageScoreMax = ValueTypeint,
        NextEvent = ValueTypeint,
        NextEventGroupId = ValueTypeint,
        OptionCondition = ValueTypeint,
        OptionShowCondition = ValueTypeint,
        OptionIcon = ValueTypestring,
        EffectGroupId = ValueTypeint,
    },
    XTableTheatre4Fate = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Difficulty = ValueTypeint,
        TriggerDay = Type1ValueTypeint,
        EventGroup = Type1ValueTypeint,
    },
    XTableTheatre4FateEvent = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Desc = ValueTypestring,
        Duration = ValueTypeint,
        SubHp = ValueTypeint,
        EventId = ValueTypeint,
        Weight = ValueTypeint,
        Condition = Type1ValueTypeint,
        ConditionWeight = Type1ValueTypeint,
    },
    XTableTheatre4Fight = {
        Id = ValueTypeintPrimaryKey,
        MoldId = ValueTypeint,
        FightType = ValueTypeint,
        ClearCost = ValueTypeint,
        RewardDropId = ValueTypeint,
        EventId = ValueTypeint,
        AfterEventId = ValueTypeint,
        PunishEffectGroup = ValueTypeint,
        Name = ValueTypestring,
        PanelName = ValueTypestring,
        Icon = ValueTypestring,
        BlockIcon = ValueTypeint,
        HeadIcon = ValueTypestring,
        Desc = ValueTypestring,
        NextFightId = Type1ValueTypeint,
        NextFightCondition = Type1ValueTypeint,
    },
    XTableTheatre4FightGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        FightId = ValueTypeint,
        Weight = ValueTypeint,
        Repeatable = ValueTypebool,
        RepeatWeight = ValueTypeint,
        Condition = ValueTypeint,
        Des = ValueTypestring,
        Difficult = Type1ValueTypeint,
        ClearCost = Type1ValueTypeint,
        ClearRedColorCost = Type1ValueTypeint,
        ProsperityLimit = Type1ValueTypeint,
        PunishTerm = Type1ValueTypeint,
    },
    XTableTheatre4FightMold = {
        Id = ValueTypeintPrimaryKey,
        StageId = Type1ValueTypeint,
        MonsterGroupIds = Type1ValueTypeint,
        BaseHp = ValueTypeint,
        Mode = ValueTypeint,
        TimeLimit = ValueTypeint,
        ModeParams = Type1ValueTypeint,
        FightEvents = Type1ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableTheatre4Item = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        CountLimit = ValueTypeint,
        Type = ValueTypeint,
        Quality = ValueTypeint,
        EffectGroupId = ValueTypeint,
        Duration = ValueTypeint,
        Desc = ValueTypestring,
        DescIcon = ValueTypestring,
        EffectDescId = ValueTypeint,
        Icon = ValueTypestring,
        IsProp = ValueTypeint,
        IsShow = ValueTypeint,
        IsPlay = ValueTypeint,
        BackPrice = ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableTheatre4ItemBox = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        ConditionId = ValueTypeint,
        Quality = ValueTypeint,
        ItemGroupId = Type1ValueTypeint,
        SafeItemGroupId = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Title = ValueTypestring,
        TitleContent = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTheatre4ItemEffectCount = {
        Id = ValueTypeintPrimaryKey,
        EffectType = ValueTypeint,
        Desc = ValueTypestring,
        BubbleDesc = ValueTypestring,
    },
    XTableTheatre4ItemGroup = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        GroupId = ValueTypeint,
        ItemId = ValueTypeint,
        Weight = ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableTheatre4Map = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        SizeX = ValueTypeint,
        SizeY = ValueTypeint,
        BaseBlockGroupId = ValueTypeint,
        EliteMonsterLimit = ValueTypeint,
        HiddenId = Type1ValueTypeint,
        TracebackGroupId = ValueTypeint,
    },
    XTableTheatre4MapBlueprint = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Order = ValueTypeint,
        MapGroup = Type1ValueTypeint,
        Index = Type1ValueTypeint,
    },
    XTableTheatre4MapClient = {
        Id = ValueTypeintPrimaryKey,
        SceneUrl = ValueTypestring,
        ModelUrl = ValueTypestring,
        LensX = ValueTypefloat,
        LensY = ValueTypefloat,
        LensDistance = ValueTypefloat,
        BigMapLensX = ValueTypefloat,
        BigMapLensY = ValueTypefloat,
        BigMapDistance = ValueTypefloat,
        MapOffsetX = ValueTypefloat,
        MapOffsetY = ValueTypefloat,
        CueTag = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTheatre4MapGrid = {
        Id = ValueTypeintPrimaryKey,
        AreaId = ValueTypeint,
        Desc = ValueTypestring,
        PosX = ValueTypeint,
        PosY = ValueTypeint,
        SizeX = ValueTypeint,
        SizeY = ValueTypeint,
        BlockGroupId = Type1ValueTypeint,
    },
    XTableTheatre4MapGroup = {
        Id = ValueTypeintPrimaryKey,
        MapGroup = ValueTypeint,
        MapId = ValueTypeint,
        BaseWeight = ValueTypeint,
        AddWeight = ValueTypeint,
        AddWeightCondition = ValueTypeint,
        Index = ValueTypeint,
        SpEffectGroup = ValueTypeint,
    },
    XTableTheatre4MapHiddenGrid = {
        Id = ValueTypeintPrimaryKey,
        ConditionId = ValueTypeint,
        Point = ValueTypestring,
        GridPos = ValueTypestring,
    },
    XTableTheatre4MapIndex = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableTheatre4Monster = {
        Id = ValueTypeintPrimaryKey,
        NpcId = ValueTypeint,
        Level = ValueTypeint,
        BuffLevel = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
        Note = ValueTypestring,
    },
    XTableTheatre4MonsterGroup = {
        Id = ValueTypeintPrimaryKey,
        MonsterIds = Type1ValueTypeint,
    },
    XTableTheatre4Reboot = {
        Id = ValueTypeintPrimaryKey,
        RebootCost = ValueTypeint,
        MaxRebootCount = ValueTypeint,
        FubenRestartCost = ValueTypeint,
        HpRetain = ValueTypefix,
    },
    XTableTheatre4RecruitTicket = {
        Id = ValueTypeintPrimaryKey,
        Quality = ValueTypeint,
        CharacterGroupA = ValueTypeint,
        CharacterNumA = ValueTypeint,
        CharacterGroupB = ValueTypeint,
        CharacterNumB = ValueTypeint,
        SelectNum = ValueTypeint,
        RefreshLimit = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTheatre4Reward = {
        Id = ValueTypeintPrimaryKey,
        Des = ValueTypestring,
        ElementType = ValueTypeint,
        ElementId = ValueTypeint,
        ElementCount = ValueTypeint,
        GroupId = ValueTypeint,
        Weight = ValueTypeint,
        Condition = ValueTypeint,
        ConditionWeight = ValueTypeint,
        IsShow = ValueTypeint,
        Color = ValueTypeint,
    },
    XTableTheatre4RewardDrop = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Des = ValueTypestring,
        GroupIds = Type1ValueTypeint,
        Probabilitys = Type1ValueTypefloat,
    },
    XTableTheatre4ScientificSpEffect = {
        Id = ValueTypeintPrimaryKey,
        SpEffectGroup = ValueTypeint,
        Difficulty = ValueTypeint,
        ColorPoint = ValueTypeint,
        Effect = ValueTypestring,
        MapImageFrom = Type1ValueTypestring,
        MapImageTo = Type1ValueTypestring,
    },
    XTableTheatre4Shop = {
        Id = ValueTypeintPrimaryKey,
        GoodsGroupId = Type1ValueTypeint,
        ConditionId = Type1ValueTypeint,
        RewardId = ValueTypeint,
        EndDesc = ValueTypestring,
        EndComfirmText = ValueTypestring,
        RoleIcon = ValueTypestring,
        RoleName = ValueTypestring,
        RoleContent = ValueTypestring,
        BgAsset = ValueTypestring,
        NodeBg = ValueTypestring,
        NodeIcon = ValueTypestring,
        NodeDesc = ValueTypestring,
        NodeEffectUrl = ValueTypestring,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        BlockIcon = ValueTypeint,
        Title = ValueTypestring,
        TitleContent = ValueTypestring,
        Desc = ValueTypestring,
        UnOpenDesc = ValueTypestring,
        RefreshLimit = ValueTypeint,
        RefreshFreeTimes = ValueTypeint,
        RefreshCost = Type1ValueTypeint,
    },
    XTableTheatre4ShopGoods = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        GoodsType = ValueTypeint,
        GoodsId = ValueTypeint,
        GoodsNum = ValueTypeint,
        Price = ValueTypeint,
        Weight = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        ConditionWeight = Type1ValueTypeint,
        ModelUrl = ValueTypestring,
        SceneUrl = ValueTypestring,
    },
    XTableTheatre4ShopGroup = {
        Id = ValueTypeintPrimaryKey,
        ShopGroupId = ValueTypeint,
        ShopId = ValueTypeint,
        Weight = ValueTypeint,
        NodeRepeatable = ValueTypeint,
        GameRepeatable = ValueTypeint,
        ConditionId = ValueTypeint,
        Des = ValueTypestring,
    },
    XTableTheatre4Task = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        MainShowOrder = ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTableTheatre4Tech = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Cost = ValueTypeint,
        EffectGroupId = ValueTypeint,
        Condition = ValueTypeint,
        PreIds = Type1ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableTheatre4Traceback = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Difficulty = ValueTypeint,
        EffectGroupId = ValueTypeint,
        ColorPointReduceRate = ValueTypeint,
        ColorPointReduceMax = ValueTypeint,
        ColorResourceReduceRate = ValueTypeint,
        ColorResourceReduceMax = ValueTypeint,
        ColorLevelReduceRate = ValueTypeint,
        ColorLevelReduceMax = ValueTypeint,
        GoldReturnRate = ValueTypeint,
        GoldReturnMax = ValueTypeint,
        BuildPointReturnRate = ValueTypeint,
        BuildPointReturnMax = ValueTypeint,
        IsReGenerateBoss = ValueTypebool,
        MaxDays = ValueTypeint,
    },
    XTableTheatre5Activity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        WorldId = ValueTypeint,
        ActivityCoin = ValueTypeint,
    },
    XTableTheatre5AttrShow = {
        Id = ValueTypeintPrimaryKey,
        AttrType = ValueTypestring,
        AttrName = ValueTypestring,
        ShowType = ValueTypeint,
        IconRes = ValueTypestring,
    },
    XTableTheatre5Character = {
        Id = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
        PvpCondition = ValueTypeint,
        Priority = ValueTypeint,
        Name = ValueTypestring,
        Info = ValueTypestring,
        CharacterId = ValueTypeint,
        Tags = Type1ValueTypestring,
        AttrId = ValueTypeint,
        TemplateId = ValueTypeint,
        NormalAttack = ValueTypeint,
        FashionIds = Type1ValueTypeint,
        Index = ValueTypeint,
        SkipId = ValueTypeint,
        PromotedAttrId = ValueTypeint,
    },
    XTableTheatre5CharacterFashion = {
        Id = ValueTypeintPrimaryKey,
        MainlineFashionId = ValueTypeint,
        DlcModelId = ValueTypestring,
        DlcWeaponId = Type1ValueTypestring,
        Portrait = ValueTypestring,
        MatchImg = ValueTypestring,
        AnimatorController = ValueTypestring,
        NormalIdleAnima = ValueTypestring,
        ChooseAnima = ValueTypestring,
        DetailIdleAnima = ValueTypestring,
        NoChooseSwitchAnima = ValueTypestring,
        NoChooseAnima = ValueTypestring,
        ChooseSwitchAnima = ValueTypestring,
    },
    XTableTheatre5CharacterLevel = {
        Id = ValueTypeintPrimaryKey,
        Level = ValueTypeint,
        GroupId = ValueTypeint,
        Exp = ValueTypeint,
        RelicGroup = Type1ValueTypeint,
    },
    XTableTheatre5ClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableTheatre5Config = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableTheatre5Currency = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IconRes = ValueTypestring,
        Info = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTheatre5GridUnlockCost = {
        UnlockNum = ValueTypeintPrimaryKey,
        GoldCost = ValueTypeint,
    },
    XTableTheatre5Item = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Price = ValueTypeint,
        DiscountPrice = ValueTypeint,
        SellPrice = ValueTypeint,
        Quality = ValueTypeint,
        BuffType = ValueTypeint,
        CharacterId = Type1ValueTypeint,
        Name = ValueTypestring,
        IconRes = ValueTypestring,
        Info = ValueTypestring,
        Desc = ValueTypestring,
        DescDigit = Type1ValueTypestring,
        EvolveDescDigit = Type1ValueTypestring,
        AddDesc = ValueTypestring,
        AddDigit = Type1ValueTypestring,
        Tags = Type1ValueTypeint,
        Keywords = Type1ValueTypeint,
        IsShow = ValueTypebool,
        Order = ValueTypeint,
    },
    XTableTheatre5ItemBox = {
        Id = ValueTypeintPrimaryKey,
        IsAutoOpen = ValueTypeint,
        BoxOpenType = ValueTypeint,
        ItemGroupIds = Type1ValueTypeint,
    },
    XTableTheatre5ItemKeyWord = {
        Id = ValueTypeintPrimaryKey,
        KeyWord = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTheatre5ItemRandomGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        GoodsId = ValueTypeint,
        GoodsWeight = ValueTypeint,
        ExpectedNum = ValueTypeint,
        Conditions = Type1ValueTypeint,
        ConditionWeights = Type1ValueTypeint,
    },
    XTableTheatre5ItemRelic = {
        Id = ValueTypeintPrimaryKey,
        Condition = Type1ValueTypeint,
        Effect = Type1ValueTypeint,
    },
    XTableTheatre5ItemRune = {
        Id = ValueTypeintPrimaryKey,
        MagicId = ValueTypeint,
        CoolDownSec = ValueTypeint,
        RuneAttrId = ValueTypeint,
        Type = ValueTypeint,
        EvolveAttrId = ValueTypeint,
        EvolveMagicId = ValueTypeint,
        AddMagicId = ValueTypeint,
    },
    XTableTheatre5ItemRuneAttr = {
        Id = ValueTypeintPrimaryKey,
        AttrTypes = Type1ValueTypestring,
        AttrValues = Type1ValueTypeint,
    },
    XTableTheatre5ItemSkill = {
        Id = ValueTypeintPrimaryKey,
        MagicId = ValueTypeint,
        CoolDownSec = ValueTypeint,
        Type = ValueTypeint,
        Range = ValueTypeint,
        ComboList = Type1ValueTypeint,
    },
    XTableTheatre5ItemTag = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IconRes = ValueTypestring,
        BgRes = ValueTypestring,
    },
    XTableTheatre5MatchConfig = {
        Id = ValueTypeintPrimaryKey,
        CupCount = ValueTypeint,
        DefeatCount = ValueTypeint,
        EnemyCupCount = ValueTypeint,
        EnemyDefeatCount = ValueTypeint,
    },
    XTableTheatre5MatchRobot = {
        Id = ValueTypeintPrimaryKey,
        GradeId = ValueTypeint,
        CupCount = ValueTypeint,
        DefeatCount = ValueTypeint,
        CharacterId = ValueTypeint,
        Score = ValueTypeint,
        SkillIds = Type1ValueTypeint,
        EquipIds = Type1ValueTypeint,
        Level = ValueTypeint,
        RelicIds = Type1ValueTypeint,
        RuneEvolves = Type1ValueTypeint,
    },
    XTableTheatre5Mission = {
        Id = ValueTypeintPrimaryKey,
        Bounty = ValueTypeint,
        Name = ValueTypestring,
        MissionConditionGroup = ValueTypeint,
        HideInHandBook = ValueTypebool,
    },
    XTableTheatre5MissionBounty = {
        Id = ValueTypeintPrimaryKey,
        Bounty = ValueTypeint,
        Level = ValueTypeint,
        Cost = ValueTypeint,
        BountyPackShow = ValueTypeint,
        BountyItem = Type1ValueTypeint,
    },
    XTableTheatre5MissionCondition = {
        Id = ValueTypeintPrimaryKey,
        MissionCondition = ValueTypeint,
        Desc = ValueTypestring,
        ConditionTarget = ValueTypeint,
        TriggerCondition = ValueTypeint,
        IsConditionAnd = ValueTypebool,
        ConditionParams = Type1ValueTypeint,
        ConditionCompares = Type1ValueTypeint,
        ConditionCompareValues = Type1ValueTypeint,
        DescShowParam = Type1ValueTypestring,
    },
    XTableTheatre5MissionTriggerCondition = {
        Id = ValueTypeintPrimaryKey,
        TriggerType = Type1ValueTypeint,
        SubTriggerType = Type1ValueTypeint,
        AddType = Type1ValueTypeint,
    },
    XTableTheatre5PveChapter = {
        Id = ValueTypeintPrimaryKey,
        LevelGroup = ValueTypeint,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        BgAsset = ValueTypestring,
        Hp = ValueTypeint,
        StartStory = ValueTypestring,
        EndStory = ValueTypestring,
        BaseRewardCoin = ValueTypeint,
        LevelRewardCoin = ValueTypeint,
        HpRewardCoin = ValueTypeint,
        LossRewardFactor = ValueTypeint,
        BagRuneGridInitCount = ValueTypeint,
        GridUnlockDiscount = ValueTypeint,
        CloseStoryTips = ValueTypeint,
        CharLevelGroup = ValueTypeint,
    },
    XTableTheatre5PveChapterLevel = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Level = ValueTypeint,
        EventGroup = ValueTypeint,
        FightGroup = ValueTypeint,
        EventLevel = ValueTypeint,
        MonsterLevel = ValueTypeint,
        EnemyBuff = Type1ValueTypeint,
        EnemyBuffLevel = Type1ValueTypeint,
        MonsterNerfBuff = Type1ValueTypeint,
    },
    XTableTheatre5PveDeduceClue = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        ShowType = ValueTypeint,
        Title = ValueTypestring,
        Img = ValueTypestring,
        OpenStoryLineContentId = ValueTypeint,
        ShowConditionId = ValueTypeint,
        ConnectClueIds = Type1ValueTypeint,
        LockDesc = ValueTypestring,
        UnlockDesc = ValueTypestring,
        CompleteDesc = ValueTypestring,
        ThinkDesc = ValueTypestring,
        ScriptId = ValueTypeint,
        StoryId = ValueTypestring,
        Index = ValueTypeint,
    },
    XTableTheatre5PveDeduceClueBoard = {
        Id = ValueTypeintPrimaryKey,
        Sort = ValueTypeint,
        IsOpen = ValueTypeint,
        CloseDesc = ValueTypestring,
        ConditionId = ValueTypeint,
        LockDesc = ValueTypestring,
        ClueGroupId = ValueTypeint,
        ImgConditionId = ValueTypeint,
        Img = ValueTypestring,
    },
    XTableTheatre5PveDeduceClueGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        ClueId = ValueTypeint,
    },
    XTableTheatre5PveDeduceQuestion = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Step = ValueTypeint,
        Desc = ValueTypestring,
        ShowClueGroupId = ValueTypeint,
        AnswerClue = ValueTypeint,
        AnswerTip = ValueTypestring,
        NormalWrongTip = ValueTypestring,
        SpWrongClues = Type1ValueTypeint,
        SpWrongTips = Type1ValueTypestring,
        Info = ValueTypestring,
    },
    XTableTheatre5PveDeduceScript = {
        Id = ValueTypeintPrimaryKey,
        PreClueGroupId = ValueTypeint,
        QuestionGroupId = ValueTypeint,
        StoryId = ValueTypestring,
    },
    XTableTheatre5PveEnding = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Bg = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableTheatre5PveEvent = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        NextEvent = ValueTypeint,
        NextEventGroup = ValueTypeint,
        OptionGroupId = ValueTypeint,
        EventLevelGroup = ValueTypeint,
        Clue = ValueTypeint,
        Exp = ValueTypeint,
        BgAsset = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        RoleIcons = Type1ValueTypestring,
        RoleNames = Type1ValueTypestring,
        RoleContents = Type1ValueTypestring,
        ConfirmContent = ValueTypestring,
        LocationName = ValueTypestring,
        LocationDesc = ValueTypestring,
        LocationDescUnselect = ValueTypestring,
        Icon = ValueTypestring,
        NextFightGroup = ValueTypeint,
    },
    XTableTheatre5PveEventGroup = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        EventId = ValueTypeint,
    },
    XTableTheatre5PveEventLevel = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        EventLevel = ValueTypeint,
        ItemType = Type1ValueTypeint,
        ItemId = Type1ValueTypeint,
        ItemCount = Type1ValueTypeint,
        BonusItemTypes = Type1ValueTypeint,
        BonusItemIds = Type1ValueTypeint,
        BonusItemCounts = Type1ValueTypeint,
    },
    XTableTheatre5PveEventOption = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        OptionDesc = ValueTypestring,
        OptionType = ValueTypeint,
        OptionCostType = ValueTypeint,
        OptionCostId = ValueTypeint,
        OptionCostCount = ValueTypeint,
        NextEvent = ValueTypeint,
        NextEventGroup = ValueTypeint,
        OptionCondition = ValueTypeint,
        OptionShowCondition = ValueTypeint,
    },
    XTableTheatre5PveFight = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Desc = ValueTypestring,
        Stage = ValueTypeint,
        EnemyName = ValueTypestring,
        EnemyType = ValueTypeint,
        EnemyId = ValueTypeint,
    },
    XTableTheatre5PveMonster = {
        Id = ValueTypeintPrimaryKey,
        MonsterGroup = ValueTypeint,
        MonsterLevel = ValueTypeint,
        MonsterNpcId = ValueTypeint,
        Skill = Type1ValueTypeint,
        EquipId = Type1ValueTypeint,
    },
    XTableTheatre5PveSceneChat = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        RoleName = ValueTypestring,
        ChatText = ValueTypestring,
    },
    XTableTheatre5PveSceneChatObjectPool = {
        Id = ValueTypeintPrimaryKey,
        SceneObject = ValueTypestring,
        SceneChatGroup = ValueTypeint,
        Characters = Type1ValueTypeint,
        Condition = ValueTypeint,
        FirstWeigh = ValueTypeint,
        Weigh = ValueTypeint,
    },
    XTableTheatre5PveSceneChatStoryPool = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Param = ValueTypestring,
        SceneChatGroup = ValueTypeint,
        Characters = Type1ValueTypeint,
    },
    XTableTheatre5PveStoryEntrance = {
        Id = ValueTypeintPrimaryKey,
        SceneObject = ValueTypestring,
        BtnOpenCondition = ValueTypeint,
        BtnCloseCondition = ValueTypeint,
        StoryIsOpen = ValueTypebool,
        StoryLine = ValueTypeint,
        RepeatChapterCondition = Type1ValueTypeint,
        RepeatChapter = Type1ValueTypeint,
    },
    XTableTheatre5PveStoryLine = {
        Id = ValueTypeintPrimaryKey,
        StoryLineType = ValueTypeint,
        StoryLineCondition = ValueTypeint,
        StoryLineCharacter = Type1ValueTypeint,
        StoryLineOpenTips = ValueTypestring,
    },
    XTableTheatre5PveStoryLineContent = {
        Id = ValueTypeintPrimaryKey,
        StoryLineId = ValueTypeint,
        ContentType = ValueTypeint,
        ContentId = ValueTypeint,
        AvgContent = ValueTypestring,
        NextScript = ValueTypeint,
        ChooseConditions = Type1ValueTypeint,
        ChooseContents = Type1ValueTypeint,
        ChooseLabels = Type1ValueTypestring,
        CharacterStoryDesc = ValueTypestring,
        DisabledCharacters = Type1ValueTypeint,
        DisabledCharactersTips = Type1ValueTypestring,
        IsContinue = ValueTypebool,
        IsTickOutToTitle = ValueTypebool,
    },
    XTableTheatre5PveStoryLineProgress = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypebool,
        ShowCondition = ValueTypeint,
        ShowConditionDesc = ValueTypestring,
        CloseCondition = ValueTypeint,
        Title = ValueTypestring,
        CountLine = ValueTypeint,
    },
    XTableTheatre5PvpRoundRefresh = {
        RoundNum = ValueTypeintPrimaryKey,
        ShopId = ValueTypeint,
        AddGoldNum = ValueTypeint,
        ShopDetailTips = ValueTypestring,
        SkillGroupIds = Type1ValueTypeint,
    },
    XTableTheatre5Rank = {
        Id = ValueTypeintPrimaryKey,
        RankName = ValueTypestring,
        Rank = ValueTypeint,
        RankStar = ValueTypeint,
        Rating = ValueTypeint,
        KWin = ValueTypeint,
        KLose = ValueTypeint,
        RankProtect = ValueTypeint,
        IconRes = ValueTypestring,
        PvpBonusRating = ValueTypeint,
        PvpPerfectRating = ValueTypeint,
        RewardId = ValueTypeint,
        KExWin = ValueTypeint,
        KExLose = ValueTypeint,
        PvpExBonusRating = ValueTypeint,
        PvpExLoseRating = ValueTypeint,
    },
    XTableTheatre5RankMajor = {
        Id = ValueTypeintPrimaryKey,
        StarCount = ValueTypeint,
        MinRank = ValueTypeint,
        MaxRank = ValueTypeint,
    },
    XTableTheatre5RecordSkillGroup = {
        MagicId = ValueTypeintPrimaryKey,
        RecordType = ValueTypeint,
        ItemSkillId = ValueTypeint,
    },
    XTableTheatre5RelicEffect = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Desc = ValueTypestring,
        Param = Type1ValueTypeint,
    },
    XTableTheatre5Shop = {
        Id = ValueTypeintPrimaryKey,
        UnlockNum = ValueTypeint,
        Name = ValueTypestring,
        RefreshCostGroupId = ValueTypeint,
        ProbShows = Type1ValueTypeint,
        Res = ValueTypestring,
        GroupIds = Type1ValueTypeint,
        ShopNpcId = ValueTypeint,
        ExpPrice = ValueTypeint,
    },
    XTableTheatre5ShopNpc = {
        Id = ValueTypeintPrimaryKey,
        TouchChatGroup = ValueTypeint,
        BuyChatGroup = ValueTypeint,
        SellChatGroup = ValueTypeint,
    },
    XTableTheatre5ShopNpcChat = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        Condition = ValueTypeint,
        Chat = ValueTypestring,
        Weigh = ValueTypeint,
    },
    XTableTheatre5ShopRefreshCost = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        RefreshCnt = ValueTypeint,
        GoldCost = ValueTypeint,
    },
    XTableTheatre5Story = {
        Id = ValueTypeintPrimaryKey,
        Group = ValueTypeint,
        Condition = ValueTypeint,
        StoryTitle = ValueTypestring,
        StoryDesc = ValueTypestring,
        StoryId = ValueTypestring,
        StoryIcon = ValueTypestring,
    },
    XTableTheatre5StoryGroup = {
        Id = ValueTypeintPrimaryKey,
        IsOpen = ValueTypebool,
        Title = ValueTypestring,
        Icon = ValueTypestring,
        Condition = ValueTypeint,
    },
    XTableTheatre5TaskShop = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Sort = ValueTypeint,
        ShopId = ValueTypeint,
        TaskTimeLimitId = ValueTypeint,
        TimeLimitId = ValueTypeint,
    },
    XTableTheatre5UiStyle = {
        Id = ValueTypeintPrimaryKey,
        UiType = ValueTypeint,
        ShowCondition = ValueTypeint,
        Priority = ValueTypeint,
        UiPrefabPath = ValueTypestring,
    },
    XTableTheatre6Activity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ShowItems = Type1ValueTypeint,
        ShowNum = Type1ValueTypeint,
        WorldId = ValueTypeint,
    },
    XTableTheatre6Attr = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Min = ValueTypeint,
        Max = ValueTypeint,
        SaveScore = ValueTypeint,
        AttrType = ValueTypeint,
        AttrKey = ValueTypestring,
        Priority = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableTheatre6AttrPack = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        ShortDesc = ValueTypestring,
        PlotDesc = ValueTypestring,
        DescParams = Type1ValueTypestring,
        Icon = ValueTypestring,
        AttrTypes = Type1ValueTypeint,
        AttrNums = Type1ValueTypeint,
        BuildTags = Type1ValueTypeint,
        BuffIds = Type1ValueTypeint,
        Quality = ValueTypeint,
        BuyPrice = ValueTypeint,
        SaveScore = ValueTypeint,
        IsHide = ValueTypebool,
        IsOutPool = ValueTypebool,
        LimitCount = ValueTypeint,
        Character = ValueTypeint,
        IsOutWiki = ValueTypebool,
        Priority = ValueTypeint,
        KeyWordIds = Type1ValueTypeint,
    },
    XTableTheatre6AttrPackPool = {
        Id = ValueTypeintPrimaryKey,
        NeedQualitys = Type1ValueTypeint,
        QualityWeights = Type1ValueTypeint,
        AppointAttrPackId = ValueTypeint,
        AppointAttrPackWeight = ValueTypeint,
        NeedTags = Type1ValueTypeint,
        TagWeights = Type1ValueTypeint,
        SameTagWeight = ValueTypeint,
        MaxSameTagWeight = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTheatre6BuildTag = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Pirority = ValueTypeint,
        IsHide = ValueTypestring,
        Desc = ValueTypestring,
        SaveWeight = ValueTypeint,
        Icon = ValueTypestring,
        FilterSort = ValueTypeint,
        GroupId = ValueTypeint,
    },
    XTableTheatre6Character = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        Name = ValueTypestring,
        Info = ValueTypestring,
        Priority = ValueTypeint,
        FashionIds = Type1ValueTypeint,
        TagBuffIds = Type1ValueTypeint,
        BuffConditionIds = Type2KeyTypeintValueTypeint,
        PlayDiffGroupIds = Type1ValueTypeint,
        BaseSkill = Type1ValueTypeint,
        AttrValue = Type2KeyTypeintValueTypeint,
        StoryItems = Type1ValueTypeint,
        BuildTags = Type1ValueTypeint,
        DlcAttrGroup = ValueTypeint,
        TemplateId = ValueTypeint,
        Bg = ValueTypestring,
        ConditionId = ValueTypeint,
        FilterSort = ValueTypeint,
    },
    XTableTheatre6CharacterFashion = {
        Id = ValueTypeintPrimaryKey,
        MainlineFashionId = ValueTypeint,
        DlcModelId = ValueTypestring,
        DlcWeaponIds = Type1ValueTypeint,
        Portrait = ValueTypestring,
        BigPortrait = ValueTypestring,
        PvpBigPortrait = ValueTypestring,
        AnimatorController = ValueTypestring,
        NormalIdleAnim = ValueTypestring,
        DetailIdleAnim = ValueTypestring,
        ChooseAnim = ValueTypestring,
        NoChooseAnim = ValueTypestring,
        SkipId = ValueTypeint,
    },
    XTableTheatre6ClientConfig = {
        Id = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableTheatre6Condition = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableTheatre6Config = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableTheatre6KeyWord = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Des = ValueTypestring,
    },
    XTableTheatre6Monster = {
        Id = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        SkillIds = Type1ValueTypeint,
        AttrTypes = Type2KeyTypeintValueTypeint,
        SaveTags = Type1ValueTypeint,
        SupportDesc = ValueTypestring,
        ShowSkills = Type1ValueTypeint,
        Score = ValueTypeint,
        BuildTags = Type1ValueTypeint,
        AttrPacks = Type1ValueTypeint,
        AttrPackNums = Type1ValueTypeint,
        DlcAttrGroup = ValueTypeint,
    },
    XTableTheatre6PvpActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Desc = ValueTypestring,
        InitPoint = ValueTypeint,
        CheckId = ValueTypeint,
    },
    XTableTheatre6PvpBuff = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        DescParams = Type1ValueTypestring,
        Icon = ValueTypestring,
        MagicId = ValueTypeint,
        ConditionId = ValueTypeint,
        Prompt = ValueTypestring,
    },
    XTableTheatre6PvpBuffGroup = {
        Id = ValueTypeintPrimaryKey,
        AttBuffs = Type1ValueTypeint,
        DefBuffs = Type1ValueTypeint,
    },
    XTableTheatre6PvpClientConfig = {
        Id = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableTheatre6PvpConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Values = Type1ValueTypestring,
    },
    XTableTheatre6PvpRank = {
        Id = ValueTypeintPrimaryKey,
        MinScore = ValueTypeint,
        MaxScore = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        RewardIds = Type1ValueTypeint,
        Desc = Type1ValueTypestring,
        SearchUp = ValueTypeint,
        SearchDown = ValueTypeint,
        SearchMid = ValueTypeint,
        RobotProp = ValueTypeint,
        SearchExpand = ValueTypeint,
        MistNum = ValueTypeint,
        TimeId = ValueTypeint,
        PvpBuffGroupId = ValueTypeint,
        KWin = ValueTypeint,
        KLose = ValueTypeint,
        AllWinScore = ValueTypeint,
        BaseWinScore = ValueTypeint,
        DefKWin = ValueTypeint,
        DefKLose = ValueTypeint,
    },
    XTableTheatre6PvpRankFight = {
        Id = ValueTypeintPrimaryKey,
        RobotIds = Type1ValueTypeint,
        PlayerDown = ValueTypeint,
        PlayerUp = ValueTypeint,
        MinScore = ValueTypeint,
        RobotProp = ValueTypeint,
        MaxPoolSize = ValueTypeint,
    },
    XTableTheatre6PvpRobot = {
        Id = ValueTypeintPrimaryKey,
        Score = ValueTypeint,
        UseMonsterIds = Type1ValueTypeint,
        Name = ValueTypestring,
        HeadIcon = ValueTypeint,
        HeadFrameId = ValueTypeint,
    },
    XTableTheatre6RandomPool = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        UseDesc = ValueTypestring,
    },
    XTableTheatre6RecordSkillGroup = {
        MagicId = ValueTypeintPrimaryKey,
        ItemSkillId = ValueTypeint,
    },
    XTableTheatre6Reward = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Priority = ValueTypeint,
        ShopId = ValueTypeint,
        TaskTimeLimitId = ValueTypeint,
    },
    XTableTheatre6Skill = {
        Id = ValueTypeintPrimaryKey,
        SkillKey = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        ShortDesc = ValueTypestring,
        DescParams = Type1ValueTypestring,
        Icon = ValueTypestring,
        ComboList = Type1ValueTypeint,
        BuildTags = Type1ValueTypeint,
        Level = ValueTypeint,
        Magics = Type1ValueTypeint,
        Type = ValueTypeint,
        IsOutPool = ValueTypebool,
        SaveScore = ValueTypeint,
        Character = ValueTypeint,
        BuyPrice = ValueTypeint,
        SellPrice = ValueTypeint,
        IsOutWiki = ValueTypebool,
        WikiPriority = ValueTypeint,
        CostTL = ValueTypeint,
        CSMag = ValueTypeint,
        TLDam = ValueTypeint,
        Quality = ValueTypeint,
        KeyWordIds = Type1ValueTypeint,
    },
    XTableTheatre6SkillExtend = {
        Id = ValueTypeintPrimaryKey,
        IsShowTags = Type1ValueTypebool,
    },
    XTableTheatre6SkillPool = {
        Id = ValueTypeintPrimaryKey,
        NeedLevels = Type1ValueTypeint,
        LevelWeights = Type1ValueTypeint,
        NeedQualitys = Type1ValueTypeint,
        QualityWeights = Type1ValueTypeint,
        AppointSkillId = Type1ValueTypeint,
        NeedTags = Type1ValueTypeint,
        TagWeights = Type1ValueTypeint,
        SameTagWeight = ValueTypeint,
        MaxSameTagWeight = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTheatre6Stage = {
        Id = ValueTypeintPrimaryKey,
        FloorIds = Type1ValueTypeint,
        IsShowFloorNum = ValueTypeint,
        OverflowGoodsGold = ValueTypeint,
        HpNum = ValueTypeint,
        BaseSan = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Image = ValueTypestring,
        BaseSkillSlot = ValueTypeint,
        SanGroupId = ValueTypeint,
        RewardIds = Type1ValueTypeint,
        ScoreProps = Type1ValueTypeint,
        MinScores = Type1ValueTypeint,
        MaxRewards = Type2KeyTypeintValueTypeint,
        AddRewards = Type2KeyTypeintValueTypeint,
    },
    XTableTheatre6StageAnno = {
        Id = ValueTypeintPrimaryKey,
        IsShowBoss = ValueTypebool,
        AnnoName = ValueTypestring,
        AnnoDesc = ValueTypestring,
    },
    XTableTheatre6StageBuff = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        DescParams = Type1ValueTypestring,
        Icon = ValueTypestring,
        BuffTriggerType = ValueTypeint,
        BuffTriggerParams = Type1ValueTypeint,
        BuffEffectType = ValueTypeint,
        BuffEffectParams = Type1ValueTypeint,
        MaxNum = ValueTypeint,
        Quailty = ValueTypeint,
        Priority = ValueTypeint,
        DurationType = ValueTypeint,
        DurationValues = Type1ValueTypeint,
        DeathType = ValueTypeint,
        IsCount = ValueTypeint,
        IsNotShow = ValueTypeint,
        DebuffType = ValueTypeint,
        Limit = ValueTypeint,
        CanStack = ValueTypebool,
    },
    XTableTheatre6StageBuffPool = {
        Id = ValueTypeintPrimaryKey,
        PoolId = ValueTypeint,
        BuffId = ValueTypeint,
        Weight = ValueTypeint,
        ConditionIds = Type1ValueTypeint,
        ConditionWeights = Type1ValueTypeint,
    },
    XTableTheatre6StageBuffPoolShow = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        UseDesc = ValueTypestring,
    },
    XTableTheatre6StageChoose = {
        Id = ValueTypeintPrimaryKey,
        Desc = ValueTypestring,
        Image = ValueTypestring,
        Quality = ValueTypeint,
        LeftDesc = ValueTypestring,
        LeftRewardTypes = Type1ValueTypeint,
        LeftRewardTypeIds = Type2KeyTypeintValueTypeint,
        LeftRewardMinNums = Type1ValueTypeint,
        LeftRewardMaxNums = Type2KeyTypeintValueTypeint,
        RightDesc = ValueTypestring,
        RightRewardTypes = Type1ValueTypeint,
        RightRewardTypeIds = Type2KeyTypeintValueTypeint,
        RightRewardMinNums = Type1ValueTypeint,
        RightRewardMaxNums = Type2KeyTypeintValueTypeint,
        ChooseLine = ValueTypeint,
        LineNum = ValueTypeint,
        NeedBuffs = Type1ValueTypeint,
        Bg = ValueTypestring,
        IsOutNormalPool = ValueTypebool,
    },
    XTableTheatre6StageChooseGroup = {
        Id = ValueTypeintPrimaryKey,
        ChoosePoolIds = Type1ValueTypeint,
        Bg = ValueTypestring,
        FirstTaskGroupId = ValueTypeint,
        LoopTaskGroupId = ValueTypeint,
        AppointFightGroupIds = Type1ValueTypeint,
    },
    XTableTheatre6StageChoosePool = {
        Id = ValueTypeintPrimaryKey,
        NeedQualitys = Type1ValueTypeint,
        QualityWeights = Type1ValueTypeint,
        NeedRewards = Type1ValueTypeint,
        RewardWeights = Type1ValueTypeint,
        AppointChooses = Type1ValueTypeint,
        ChooseWeights = Type1ValueTypeint,
        NeedRewardWeight = ValueTypeint,
    },
    XTableTheatre6StageDifficulty = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        NewStageIds = Type1ValueTypeint,
        Name = ValueTypestring,
        Des = ValueTypestring,
        ConditionId = ValueTypeint,
        HardNum = ValueTypeint,
    },
    XTableTheatre6StageDifficultyAuto = {
        StageId = ValueTypeintPrimaryKey,
        DifficultyIds = Type1ValueTypeint,
    },
    XTableTheatre6StageDifficultyGroup = {
        Id = ValueTypeintPrimaryKey,
        DifficultyIds = Type1ValueTypeint,
        Name = ValueTypestring,
        Des = ValueTypestring,
    },
    XTableTheatre6StageEffect = {
        Id = ValueTypeintPrimaryKey,
        EffectLut = ValueTypestring,
    },
    XTableTheatre6StageFight = {
        Id = ValueTypeintPrimaryKey,
        EasyMonsterId = ValueTypeint,
        EasyDescs = Type1ValueTypestring,
        EasyRewardTypes = Type1ValueTypeint,
        EasyRewardIds = Type2KeyTypeintValueTypeint,
        HardMonsterId = ValueTypeint,
        HardDescs = Type1ValueTypestring,
        HardRewardTypes = Type1ValueTypeint,
        HardRewardIds = Type2KeyTypeintValueTypeint,
        DefeatGetTypes = Type1ValueTypeint,
        DefeatGetValues = Type1ValueTypeint,
        LevelId = ValueTypeint,
    },
    XTableTheatre6StageFightGroup = {
        Id = ValueTypeintPrimaryKey,
        FightIds = Type1ValueTypeint,
        Weights = Type1ValueTypeint,
        BuildTagWeights = Type2KeyTypeintValueTypeint,
        MaxTagWeights = Type2KeyTypeintValueTypeint,
    },
    XTableTheatre6StageFloor = {
        Id = ValueTypeintPrimaryKey,
        RoomIds = Type1ValueTypeint,
        StartBuffPoolIds = Type1ValueTypeint,
        AnnoId = ValueTypeint,
        StartAVG = ValueTypeint,
        ExFloor = ValueTypeint,
    },
    XTableTheatre6StageGoods = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Type = ValueTypeint,
        UseDesc = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTheatre6StageRoom = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Values = Type1ValueTypeint,
    },
    XTableTheatre6StageSan = {
        Id = ValueTypeintPrimaryKey,
        SanGroupId = ValueTypeint,
        MinSan = ValueTypeint,
        MaxSan = ValueTypeint,
        BuffIds = Type1ValueTypeint,
        BuffTypes = Type1ValueTypeint,
        SanType = ValueTypeint,
        SanTitleDes = ValueTypestring,
        SanTitleBg = ValueTypestring,
        Color = ValueTypestring,
        CueId = ValueTypeint,
        LineColor = ValueTypestring,
        LineOffset = ValueTypeint,
    },
    XTableTheatre6StageSanAuto = {
        SanGroupId = ValueTypeintPrimaryKey,
        SanIds = Type1ValueTypeint,
    },
    XTableTheatre6StageShop = {
        Id = ValueTypeintPrimaryKey,
        RewardTypes = Type1ValueTypeint,
        RewardPools = Type1ValueTypeint,
        RefreshTime = ValueTypeint,
        BaseRereshPrice = ValueTypeint,
        RefreshAddPrice = ValueTypeint,
        BuySanNum = ValueTypeint,
        BuySanBasePrice = ValueTypeint,
        BuySanAddPrice = ValueTypeint,
        BuySanMaxTimes = ValueTypeint,
    },
    XTableTheatre6StageTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Quality = ValueTypeint,
        GoodsNums = Type1ValueTypeint,
        AppointGoodsTypes = Type1ValueTypeint,
        ConditionId = ValueTypeint,
        RewardTypes = Type1ValueTypeint,
        RewardIds = Type1ValueTypeint,
        CharacterId = ValueTypeint,
        IsOutPool = ValueTypeint,
    },
    XTableTheatre6StageTaskGroup = {
        Id = ValueTypeintPrimaryKey,
        QualityTypes = Type1ValueTypeint,
        QualityBaseWeights = Type1ValueTypeint,
        QualityExpectedNums = Type2KeyTypeintValueTypeint,
        QualityExpectedWeights = Type1ValueTypeint,
        RewardTypes = Type1ValueTypeint,
        RewardBaseWeights = Type1ValueTypeint,
        RewardExpectedNums = Type2KeyTypeintValueTypeint,
        RewardExpectedWeights = Type1ValueTypeint,
        AppointTasks = Type1ValueTypeint,
        FreeRefresh = ValueTypeint,
        RefreshStartGold = ValueTypeint,
        RefreshAddGold = ValueTypeint,
        MaxRefresh = ValueTypeint,
        ChooseNum = ValueTypeint,
        TaskNum = ValueTypeint,
        BaseWeight = ValueTypeint,
        SameGoodsReduceWeight = ValueTypeint,
    },
    XTableTheatre6StageTaskQuality = {
        Id = ValueTypeintPrimaryKey,
        Bg = ValueTypestring,
        FailCoin = ValueTypeint,
        Name = ValueTypestring,
    },
    XTableTheatre6StoryDetail = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        StoryId = ValueTypestring,
    },
    XTableTheatre6StoryLine = {
        Id = ValueTypeintPrimaryKey,
        CommonFx = ValueTypestring,
        CommonCamera = ValueTypeint,
        ConditionId = ValueTypeint,
        StoryGroupId = ValueTypeint,
        UseCharacter = ValueTypeint,
        StageCharacter = Type1ValueTypeint,
        StageIds = Type1ValueTypeint,
        CommonFirstGuides = Type2KeyTypeintValueTypeint,
        CommonGuides = Type2KeyTypeintValueTypeint,
        ConsumeCounts = Type2KeyTypeintValueTypeint,
    },
    XTableTheatre6StoryLineAuto = {
        CharacterId = ValueTypeintPrimaryKey,
        StoryLineId = Type1ValueTypeint,
    },
    XTableTheatre6TagToBuff = {
        Tag = ValueTypeintPrimaryKey,
        BuffId = ValueTypeint,
        BuildTagId = ValueTypeint,
    },
    XTableTheatre6Talent = {
        Id = ValueTypeintPrimaryKey,
        Level = ValueTypeint,
        AttrTypes = Type1ValueTypeint,
        AttrNums = Type1ValueTypeint,
        NextExp = ValueTypeint,
    },
    XTableTheatreAutoTeam = {
        StageId = ValueTypeintPrimaryKey,
        IsomerSortOrder = ValueTypeint,
        ElementSortOrder = Type1ValueTypeint,
        IsOnlyOneElement = Type1ValueTypeint,
        CareerSortOrder = Type1ValueTypeint,
    },
    XTableTheatreChapter = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        ConditionId = ValueTypeint,
        IsRecruit = ValueTypeint,
        RecruitCount = ValueTypeint,
        RecruitRefreshCount = ValueTypeint,
        DecorationPoint = ValueTypeint,
        FavorPoint = ValueTypeint,
        NeedDecoration = ValueTypeint,
        OpenIndexIcon = ValueTypestring,
        OpenTitleIcon = ValueTypestring,
        Title = ValueTypestring,
        SceneUrl = ValueTypestring,
        BgA = ValueTypestring,
        BgB = ValueTypestring,
        ModelUrl = ValueTypestring,
        RecruitGrid = ValueTypeint,
        MultiFightLoadingBg = ValueTypestring,
        BeginStory = ValueTypestring,
        EndStory = ValueTypestring,
    },
    XTableTheatreChapterGroup = {
        Id = ValueTypeintPrimaryKey,
        ChapterStartId = ValueTypeint,
        ConditionId = ValueTypeint,
        Mode = ValueTypeint,
    },
    XTableTheatreClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableTheatreConfig = {
        Key = ValueTypestringPrimaryKey,
        Comment = ValueTypestring,
        Value = ValueTypeint,
    },
    XTableTheatreDecoration = {
        Id = ValueTypeintPrimaryKey,
        DecorationId = ValueTypeint,
        Lv = ValueTypeint,
        ConditionId = ValueTypeint,
        UpgradeCostItemId = ValueTypeint,
        UpgradeCostCount = ValueTypeint,
        Type = Type1ValueTypeint,
        Param = Type1ValueTypestring,
        GroupIndex = ValueTypeint,
        GridIndex = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        ConditionDesc = ValueTypestring,
        IsWindow = ValueTypebool,
    },
    XTableTheatreDifficulty = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        ConditionId = ValueTypeint,
        RewardFactor = ValueTypefloat,
        ReopenCount = ValueTypeint,
        FightEventId = Type1ValueTypeint,
        EnemyBuff = Type1ValueTypeint,
        ShowItemIds = Type1ValueTypeint,
    },
    XTableTheatreEnding = {
        Id = ValueTypeintPrimaryKey,
        Priority = ValueTypeint,
        Type = Type1ValueTypeint,
        Param = Type1ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTheatreEvent = {
        Id = ValueTypeintPrimaryKey,
        EventId = ValueTypeint,
        NeedDecoration = ValueTypeint,
        StepId = ValueTypeint,
        NextStepId = ValueTypeint,
        Type = ValueTypeint,
        StageId = ValueTypeint,
        StepRewardItemId = ValueTypeint,
        StepRewardItemCount = ValueTypeint,
        StoryId = ValueTypestring,
        OptionDesc = Type1ValueTypestring,
        OptionDownDesc = Type1ValueTypestring,
        OptionIcon = Type1ValueTypestring,
        OptionType = Type1ValueTypeint,
        OptionItemId = Type1ValueTypeint,
        OptionItemCount = Type1ValueTypeint,
        OptionNextStepId = Type1ValueTypeint,
        OptionNeedDecoration = Type1ValueTypeint,
        Title = ValueTypestring,
        TitleContent = ValueTypestring,
        RoleIcon = ValueTypestring,
        RoleName = ValueTypestring,
        RoleContent = ValueTypestring,
        EventDesc = ValueTypestring,
        ConfirmContent = ValueTypestring,
        BgAsset = ValueTypestring,
    },
    XTableTheatreEventClientConfig = {
        Id = ValueTypeintPrimaryKey,
        NodeTypeName = ValueTypestring,
        NodeTypeIcon = ValueTypestring,
        NodeTypeDesc = ValueTypestring,
    },
    XTableTheatreFactor = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Factor = ValueTypefloat,
    },
    XTableTheatreFieldGuide = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Order = ValueTypeint,
    },
    XTableTheatreItem = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        KeepsakeId = ValueTypeint,
        FightCount = ValueTypeint,
        Lv = ValueTypeint,
        ItemId = ValueTypeint,
        PowerId = ValueTypeint,
        PowerFactor = ValueTypeint,
        Explain = ValueTypestring,
        Quality = ValueTypeint,
    },
    XTableTheatreKeepsake = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Description = ValueTypestring,
    },
    XTableTheatreLv = {
        Id = ValueTypeintPrimaryKey,
        Lv = ValueTypeint,
        Grade = ValueTypestring,
        EquipmentShowLevel = ValueTypeint,
    },
    XTableTheatreNode = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        NodeId = ValueTypeint,
        IsRandom = ValueTypeint,
        Type = Type1ValueTypeint,
        MaxRandom = ValueTypeint,
        LvExpect = ValueTypefloat,
        LvWeight = ValueTypeint,
        SkillExpect = ValueTypefloat,
        SkillWeight = ValueTypeint,
        DecorationExpect = ValueTypefloat,
        DecorationWeight = ValueTypeint,
        FavorExpect = ValueTypefloat,
        FavorWeight = ValueTypeint,
    },
    XTableTheatreNodeShop = {
        Id = ValueTypeintPrimaryKey,
        InitCount = ValueTypeint,
        MaxCount = ValueTypeint,
        LvWeight = ValueTypeint,
        LvPrice = ValueTypeint,
        SkillWeight = ValueTypeint,
        SkillPrice = ValueTypeint,
        DecorationWeight = ValueTypeint,
        DecorationPrice = ValueTypeint,
        DecorationCount = ValueTypeint,
        FavorWeight = ValueTypeint,
        FavorPrice = ValueTypeint,
        FavorCount = ValueTypeint,
        Title = ValueTypestring,
        TitleContent = ValueTypestring,
        RoleIcon = ValueTypestring,
        RoleName = ValueTypestring,
        RoleContent = ValueTypestring,
        Desc = ValueTypestring,
        EndDesc = ValueTypestring,
        EndComfirmText = ValueTypestring,
        BgAsset = ValueTypestring,
    },
    XTableTheatrePowerCondition = {
        Id = ValueTypeintPrimaryKey,
        ConditionId = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        SmallIcon = ValueTypestring,
    },
    XTableTheatrePowerFavor = {
        Id = ValueTypeintPrimaryKey,
        PowerId = ValueTypeint,
        Lv = ValueTypeint,
        UpgradeCost = ValueTypeint,
        RewardType = Type1ValueTypeint,
        RewardParam = Type1ValueTypestring,
        RewardDesc = ValueTypestring,
    },
    XTableTheatreRole = {
        Id = ValueTypeintPrimaryKey,
        PoolId = ValueTypeint,
    },
    XTableTheatreRoleAttr = {
        Id = ValueTypeintPrimaryKey,
        RoleId = ValueTypeint,
        Lv = ValueTypeint,
        RobotId = ValueTypeint,
        FightAbility = ValueTypeint,
    },
    XTableTheatreSettleFactor = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Factor = ValueTypefloat,
    },
    XTableTheatreSkill = {
        Id = ValueTypeintPrimaryKey,
        PowerId = ValueTypeint,
        Type = ValueTypeint,
        Pos = ValueTypeint,
        Quality = ValueTypeint,
        Lv = ValueTypeint,
        FightAbility = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
        NeedPowerFavor = ValueTypeint,
        FightEventId = Type1ValueTypeint,
        SkillWeight = ValueTypeint,
    },
    XTableTheatreSkillPosDefine = {
        Id = ValueTypeintPrimaryKey,
        SkillType = Type1ValueTypeint,
    },
    XTableTheatreSkillRule = {
        Id = ValueTypeintPrimaryKey,
        PowerExpect = Type1ValueTypeint,
        PowerBasicWeight = ValueTypeint,
        LvExpect = Type1ValueTypeint,
        SkillBasicWeight = ValueTypeint,
    },
    XTableTheatreStage = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = ValueTypeint,
        StageCount = ValueTypeint,
        StageId = Type1ValueTypeint,
        IsRandom = ValueTypeint,
        ConditionId = ValueTypeint,
        Weight = ValueTypeint,
        FightAbilityBegin = ValueTypeint,
        FightAbilityEnd = ValueTypeint,
        SelectSkillBegin = ValueTypeint,
        SelectSkillEnd = ValueTypeint,
        NeedDecoration = ValueTypeint,
        RewardId = ValueTypeint,
        IsBoss = ValueTypeint,
        SuggestAbility = ValueTypeint,
    },
    XTableTheatreTask = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        GroupId = ValueTypeint,
        MainShowOrder = ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTableTheatreTaskGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
    },
    XTableTimeLimitCtrlConfig = {
        Id = ValueTypeint,
        StartTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTopControlConfig = {
        Id = ValueTypeintPrimaryKey,
        FontSize = Type1ValueTypeint,
        HandleScale = Type1ValueTypefloat,
        Name = Type1ValueTypestring,
    },
    XTableTransfiniteAchievement = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        StageGroupId = Type1ValueTypeint,
    },
    XTableTransfiniteActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        CycleSeconds = ValueTypeint,
    },
    XTableTransfiniteConfig = {
        Id = ValueTypeintPrimaryKey,
        OpenMinLv = ValueTypeint,
        OpenMaxLv = ValueTypeint,
        StartMailId = ValueTypeint,
        StartMailInterval = ValueTypeint,
    },
    XTableTransfiniteIsland = {
        Id = ValueTypeintPrimaryKey,
        IslandImage = Type1ValueTypestring,
        StageGroupId = Type1ValueTypeint,
    },
    XTableTransfiniteMedal = {
        Id = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Time = Type1ValueTypeint,
        Desc = Type1ValueTypestring,
    },
    XTableTransfiniteRegion = {
        RegionId = ValueTypeintPrimaryKey,
        RegionName = ValueTypestring,
        TimeId = ValueTypeint,
        MinLv = ValueTypeint,
        MaxLv = ValueTypeint,
        RotateGroupId = ValueTypeint,
        TaskGroupId = Type1ValueTypeint,
        ScoreRewardGroupId = ValueTypeint,
        IslandId = ValueTypeint,
        IconLv = ValueTypestring,
        RewardId = Type1ValueTypeint,
    },
    XTableTransfiniteRotateGroup = {
        RotateGroupId = ValueTypeintPrimaryKey,
        StageGroupId = Type1ValueTypeint,
    },
    XTableTransfiniteScoreRewardGroup = {
        Id = ValueTypeintPrimaryKey,
        RegionId = ValueTypeint,
        ScoreRewardGroupId = ValueTypeint,
        Score = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
    },
    XTableTransfiniteSpecialTreatment = {
        StageGroupId = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        StageIds = Type1ValueTypeint,
        Scores = Type1ValueTypeint,
        ExtraScores = Type1ValueTypeint,
    },
    XTableTransfiniteStage = {
        StageId = ValueTypeintPrimaryKey,
        StageType = ValueTypeint,
        StageName = ValueTypestring,
        ConditionId = Type1ValueTypeint,
        StrengthenId = Type1ValueTypeint,
        Img = ValueTypestring,
        Score = ValueTypeint,
        ExtraTimeLimit = ValueTypeint,
        ExtraScore = ValueTypeint,
        ExtraDec = ValueTypestring,
        Model = ValueTypestring,
    },
    XTableTransfiniteStageGroup = {
        StageGroupId = ValueTypeintPrimaryKey,
        StageId = Type1ValueTypeint,
        StrengthenId = Type1ValueTypeint,
        Name = ValueTypestring,
        Img = Type1ValueTypestring,
        Type = ValueTypeint,
    },
    XTableTransfiniteStartStageProgress = {
        Id = ValueTypeintPrimaryKey,
        LastProgress = ValueTypeint,
        StartProgress = ValueTypeint,
    },
    XTableTransfiniteStrengthen = {
        StrengthenId = ValueTypeintPrimaryKey,
        EventId = ValueTypeint,
        Title = ValueTypestring,
        Des = ValueTypestring,
        Img = ValueTypestring,
    },
    XTableTransfiniteTaskGroup = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        TaskIds = Type1ValueTypeint,
    },
    XTableTransfiniteTaskGroupSpecialTreatment = {
        Id = ValueTypeintPrimaryKey,
        TaskGroup = ValueTypeint,
        TimeId = ValueTypeint,
        TaskIds = Type1ValueTypeint,
    },
    XTableTreasure = {
        TreasureId = ValueTypeintPrimaryKey,
        RequireStar = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableTrialChallenge = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        StageId = ValueTypeint,
        Picture = ValueTypestring,
        BigPicture = ValueTypestring,
        Explain = ValueTypestring,
        RewardId = ValueTypeint,
        PreId = ValueTypeint,
        AvgAbility = ValueTypeint,
        LimitTime = ValueTypeint,
        Unlocklevel = ValueTypeint,
        Name = ValueTypestring,
        Des = Type1ValueTypestring,
        ConditionExplain = Type1ValueTypestring,
    },
    XTableTrialTypeReward = {
        Type = ValueTypeintPrimaryKey,
        RewardId = ValueTypeint,
        MinIcon = ValueTypestring,
        BigIcon = ValueTypestring,
        Name = ValueTypestring,
    },
    XTableTRPGBoss = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        StageId = ValueTypeint,
        FinishMailId = ValueTypeint,
        ModelId = ValueTypestring,
        ChallengeCount = ValueTypeint,
        Desc = ValueTypestring,
        StartStoryId = ValueTypestring,
        HideEntranceTimeStr = ValueTypestring,
    },
    XTableTRPGBossHpConfig = {
        Id = ValueTypeint,
        ZoneName = ValueTypestring,
        BossId = ValueTypeint,
        TotalHp = ValueTypeint,
    },
    XTableTRPGBossHpControl = {
        Id = ValueTypeint,
        ZoneName = ValueTypestring,
        BossId = ValueTypeint,
        Day = ValueTypeint,
        MinHp = Type1ValueTypeint,
        MaxHp = Type1ValueTypeint,
    },
    XTableTRPGBossPhasesReward = {
        Id = ValueTypeintPrimaryKey,
        Percent = ValueTypeint,
        RewardId = ValueTypeint,
        Icon = ValueTypestring,
    },
    XTableTRPGBuff = {
        Id = ValueTypeintPrimaryKey,
        EffectType = ValueTypeint,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableTRPGButtonCondition = {
        Id = ValueTypeintPrimaryKey,
        Condition = ValueTypeint,
    },
    XTableTRPGExamine = {
        Id = ValueTypeintPrimaryKey,
        Endurance = ValueTypeint,
        Title = ValueTypestring,
        Description = ValueTypestring,
        ActionId = Type1ValueTypeint,
        PunishId = Type1ValueTypeint,
        PunishWeight = Type1ValueTypeint,
        SucDesc = ValueTypestring,
        FailDesc = ValueTypestring,
        StartMovieId = ValueTypestring,
    },
    XTableTRPGExamineAction = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Round = ValueTypeint,
        ItemId = ValueTypeint,
        NeedValue = ValueTypeint,
        ResetCostId = ValueTypeint,
        ResetCostCount = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableTRPGExamineActionDifficult = {
        Difficult = ValueTypeintPrimaryKey,
        Delta = ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableTRPGExamineActionType = {
        Type = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        DescEn = ValueTypestring,
        DefaultItemDesc = ValueTypestring,
        RangeDesc = ValueTypestring,
        AttrDesc = ValueTypestring,
    },
    XTableTRPGExaminePoint = {
        Id = ValueTypeint,
        RoleId = ValueTypeint,
        AttributeValue = ValueTypeint,
        Result = Type1ValueTypeint,
        Weight = Type1ValueTypeint,
    },
    XTableTRPGExaminePunish = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Params = Type1ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableTRPGFunction = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        NeedSave = ValueTypeint,
        Params = Type1ValueTypestring,
        RewardId = ValueTypeint,
        Desc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableTRPGFunctionGroup = {
        Id = ValueTypeintPrimaryKey,
        FunctionId = Type1ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableTRPGItem = {
        Id = ValueTypeintPrimaryKey,
        ItemType = ValueTypeint,
        Capacity = ValueTypeint,
        EffectType = ValueTypeint,
        Params = Type1ValueTypeint,
        TagIcon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableTRPGLevel = {
        Id = ValueTypeintPrimaryKey,
        UpExp = ValueTypeint,
        TalentPoint = ValueTypeint,
    },
    XTableTRPGMainArea = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SubAreaId = Type1ValueTypeint,
        TargetLinkId = Type1ValueTypeint,
        OpenTimeId = ValueTypeint,
        TRPGRewardId = Type1ValueTypeint,
        TruthRoadGroupId = Type1ValueTypeint,
        TruthRoadTabBg = ValueTypestring,
        SubAreaBg = ValueTypestring,
        TruthRoadBg = ValueTypestring,
        EnName = ValueTypestring,
        FirstOpenFunctionGroupId = ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableTRPGMaze = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        StartLayerId = ValueTypeint,
        LayerId = Type1ValueTypeint,
    },
    XTableTRPGMazeCard = {
        Id = ValueTypeintPrimaryKey,
        Disposeable = ValueTypeint,
        SingleDisposeable = ValueTypeint,
        RecordGroupId = ValueTypeint,
        Type = ValueTypeint,
        Param = Type1ValueTypestring,
        Order = ValueTypestring,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        IconR = ValueTypestring,
        MiniIcon = ValueTypestring,
        ConvertCardId = ValueTypeint,
        FightDes = ValueTypestring,
        QuickFightDes = ValueTypestring,
        ShowTag = ValueTypeint,
        MovieId = ValueTypestring,
    },
    XTableTRPGMazeCardRecordGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        MiniIcon = ValueTypestring,
    },
    XTableTRPGMazeCardType = {
        Type = ValueTypeintPrimaryKey,
        Icon = ValueTypestring,
        Prefab = ValueTypestring,
    },
    XTableTRPGMazeLayer = {
        Id = ValueTypeintPrimaryKey,
        StartNodeId = ValueTypeint,
        StartCardIndex = ValueTypeint,
        Name = ValueTypestring,
        MapId = ValueTypeint,
        BgImage = ValueTypestring,
    },
    XTableTRPGMazeMap = {
        Id = ValueTypeintPrimaryKey,
        CardId = Type1ValueTypeint,
    },
    XTableTRPGMemoirStory = {
        Id = ValueTypeintPrimaryKey,
        StoryId = ValueTypestring,
        UnlockItemId = ValueTypeint,
        UnlockItemCount = ValueTypeint,
        TabName = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        ImgCG = ValueTypestring,
    },
    XTableTRPGPanelPlotTab = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Bg = ValueTypestring,
        OpenUiName = ValueTypestring,
        Condition = ValueTypeint,
    },
    XTableTRPGReward = {
        Id = ValueTypeintPrimaryKey,
        Condition = Type1ValueTypeint,
        RewardId = ValueTypeint,
        ReceiveDesc = ValueTypestring,
        SecondMainReceiveDesc = ValueTypestring,
    },
    XTableTRPGRole = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        UnlockTarget = ValueTypeint,
        Image = ValueTypestring,
        HeadIcon = ValueTypestring,
        ModelId = ValueTypestring,
        InitAttribute = Type2KeyTypeintValueTypeint,
        TalentGroupId = ValueTypeint,
        IsShowTip = ValueTypeint,
    },
    XTableTRPGRoleAttribute = {
        AttrType = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        MaxValue = ValueTypeint,
    },
    XTableTRPGRoleTalent = {
        Id = ValueTypeintPrimaryKey,
        TalentPointIcon = ValueTypestring,
        ResetTalentItemId = ValueTypeint,
        ResetTalentItemCount = ValueTypeint,
    },
    XTableTRPGRoleTalentGroup = {
        Id = ValueTypeintPrimaryKey,
        PreId = ValueTypeint,
        IsCommonForShow = ValueTypeint,
        CostPoint = ValueTypeint,
        EventId = ValueTypeint,
        Icon = ValueTypestring,
        Intro = ValueTypestring,
        Description = ValueTypestring,
        Title = ValueTypestring,
    },
    XTableTRPGRoleTalentGroupClient = {
        Id = ValueTypeintPrimaryKey,
        Prefab = ValueTypestring,
    },
    XTableTRPGSecondArea = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        SubAreaBg = ValueTypestring,
        Type = ValueTypeint,
        MazeId = ValueTypeint,
        SubAreaId = Type1ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableTRPGSecondMain = {
        Id = ValueTypeintPrimaryKey,
        Condition = Type1ValueTypeint,
        Prefab = ValueTypestring,
        BG = ValueTypestring,
        SecondMainStageId = Type1ValueTypeint,
    },
    XTableTRPGSecondMainStage = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Condition = Type1ValueTypeint,
        StageType = ValueTypeint,
        StageId = ValueTypeint,
        TRPGRewardId = ValueTypeint,
        PrefabName = ValueTypestring,
        Icon = ValueTypestring,
        DialogIcon = ValueTypestring,
    },
    XTableTRPGShop = {
        Id = ValueTypeintPrimaryKey,
        OpenCondition = ValueTypeint,
        ShopItemId = Type1ValueTypeint,
        ShopItemCount = Type1ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableTRPGShopItem = {
        Id = ValueTypeintPrimaryKey,
        ResetType = ValueTypeint,
        Condition = ValueTypeint,
        RewardId = ValueTypeint,
        ConsumeId = ValueTypeint,
        ConsumeCount = ValueTypeint,
    },
    XTableTRPGSyncStage = {
        Id = ValueTypeintPrimaryKey,
        SyncTargetIds = Type1ValueTypeint,
    },
    XTableTRPGSyncTarget = {
        Id = ValueTypeintPrimaryKey,
        SyncStageIds = Type1ValueTypeint,
    },
    XTableTRPGTarget = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        StageType = ValueTypeint,
        Desc = ValueTypestring,
        Params = Type1ValueTypestring,
        Name = ValueTypestring,
        AreaIcon = ValueTypestring,
        CardIcon = ValueTypestring,
    },
    XTableTRPGTargetCheckConfig = {
        Id = ValueTypeint,
        TargetId = Type1ValueTypeint,
    },
    XTableTRPGTargetLink = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TargetId = Type1ValueTypeint,
        PreTarget = Type1ValueTypestring,
        TargetMissionType = ValueTypeint,
        PrefabAreaName = ValueTypestring,
    },
    XTableTRPGThirdArea = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        EnName = ValueTypestring,
        Icon = ValueTypestring,
        Bg = ValueTypestring,
        FuncGroup = Type1ValueTypeint,
        Condition = ValueTypeint,
    },
    XTableTRPGTruthRoad = {
        Id = ValueTypeintPrimaryKey,
        PrefabName = ValueTypestring,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        Condition = ValueTypeint,
        StageId = ValueTypeint,
        StoryId = ValueTypestring,
        TRPGRewardId = ValueTypeint,
        DialogIcon = ValueTypestring,
    },
    XTableTRPGTruthRoadGroup = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Condition = ValueTypeint,
        Prefab = ValueTypestring,
        TruthRoadId = Type1ValueTypeint,
        SmallName = ValueTypestring,
    },
    XTableTrustGameClickPool = {
        Id = ValueTypeintPrimaryKey,
        Question = ValueTypestring,
        Answer = ValueTypestring,
        Time = ValueTypeint,
        Weight = ValueTypeint,
        Difficult = ValueTypeint,
    },
    XTableTrustGameConfig = {
        Id = ValueTypeintPrimaryKey,
        GameRewardId = ValueTypeint,
        Type = ValueTypeint,
        Difficult = ValueTypeint,
        Count = ValueTypeint,
    },
    XTableTrustGameEliminatePool = {
        Id = ValueTypeintPrimaryKey,
        Question = ValueTypestring,
        Answer = ValueTypestring,
        Times = ValueTypeint,
        LimitTimes = ValueTypeint,
        Weight = ValueTypeint,
        Difficult = ValueTypeint,
    },
    XTableTrustGameGrid = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        SmallIcon = ValueTypestring,
        BigIcon = ValueTypestring,
    },
    XTableTrustGamePosition = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BgIcon = ValueTypestring,
    },
    XTableTrustGameReward = {
        Id = ValueTypeintPrimaryKey,
        FinishNum = Type1ValueTypeint,
        TrustExp = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
    },
    XTableTrustGameTypeConfig = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Title = ValueTypestring,
        Desc = ValueTypestring,
        ResultTitle = ValueTypestring,
        ResultDesc = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableTurntable = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        RewardId = ValueTypeint,
        RewardType = ValueTypeint,
        CanGainTimes = ValueTypeint,
        Weight = ValueTypeint,
        InitialAngle = ValueTypeint,
    },
    XTableTurntableActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        ConsumeItemId = ValueTypeint,
        ConsumeItemCount = ValueTypeint,
        MaxDrawNum = ValueTypeint,
        RecordNum = ValueTypeint,
        BaseRuleTitles = Type1ValueTypestring,
        BaseRules = Type1ValueTypestring,
        TaskGroup = Type1ValueTypeint,
    },
    XTableTurntableDrawReward = {
        Id = ValueTypeintPrimaryKey,
        ActivityId = ValueTypeint,
        AccumulateNum = ValueTypeint,
        AccumulateRewardId = ValueTypeint,
        IsTopShow = ValueTypebool,
    },
    XTableTurntableMilestone = {
        Id = ValueTypeintPrimaryKey,
        Percent = ValueTypefloat,
    },
    XTableTwoSideTowerActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        BannerBg = ValueTypestring,
        OutSideTimeId = ValueTypeint,
        InsideTimeId = ValueTypeint,
        OutSideBannerBg = ValueTypestring,
        InsideBannerBg = ValueTypestring,
        LimitTaskId = ValueTypeint,
        InsideLimitTaskId = ValueTypeint,
        ChapterIds = Type1ValueTypeint,
        InsideChapterIds = Type1ValueTypeint,
        RobotIds = Type1ValueTypeint,
    },
    XTableTwoSideTowerChapter = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        SecondName = ValueTypestring,
        FubenPrefab = ValueTypestring,
        Icon = ValueTypestring,
        MonsterBg = ValueTypestring,
        UnlockChapterIds = Type1ValueTypeint,
        PointIds = Type1ValueTypeint,
        ScoreLevel = Type1ValueTypeint,
        EndPointId = ValueTypeint,
        OverviewIcon = ValueTypestring,
        OverviewDesc = ValueTypestring,
    },
    XTableTwoSideTowerClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Desc = ValueTypestring,
        Params = Type1ValueTypestring,
    },
    XTableTwoSideTowerFeature = {
        Id = ValueTypeintPrimaryKey,
        FightEventId = ValueTypeint,
        Type = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Image = ValueTypestring,
        Desc = ValueTypestring,
        DescZonglan = ValueTypestring,
    },
    XTableTwoSideTowerPoint = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        NumberName = ValueTypestring,
        InitScore = ValueTypeint,
        ReduceScoreParam = ValueTypeint,
        StageIds = Type1ValueTypeint,
        IsEndPoint = ValueTypeint,
    },
    XTableTwoSideTowerStage = {
        Id = ValueTypeintPrimaryKey,
        FeatureId = ValueTypeint,
        ExtraFeatureId = ValueTypeint,
        SmallMonsterIcon = ValueTypestring,
        BigMonsterIcon = ValueTypestring,
        WeakIcon = ValueTypestring,
        StageTypeName = ValueTypestring,
        StageNumberName = ValueTypestring,
    },
    XTableUiBattleShowRole = {
        ModelId = ValueTypestringPrimaryKey,
        WeaponId = Type1ValueTypeint,
        StandbyAnime = ValueTypestring,
        HitAnime = ValueTypestring,
        Born = ValueTypeint,
        FrontDash = ValueTypeint,
        BackDash = ValueTypeint,
        SpecialAttack = Type1ValueTypeint,
        NormalAttack = Type1ValueTypeint,
        RedAttack = Type1ValueTypeint,
        BlueAttack = Type1ValueTypeint,
        YellowAttack = Type1ValueTypeint,
        SpecialAttackSound = Type1ValueTypeint,
        HideNodeName = Type1ValueTypestring,
        ReadyHideNodeName = Type1ValueTypestring,
        SkillAttack = Type1ValueTypeint,
        SpecialAttackEffectName = Type1ValueTypestring,
        SpecialAttackEffectJointName = Type1ValueTypestring,
    },
    XTableUiBuyAsset = {
        Id = ValueTypeintPrimaryKey,
        UiName = ValueTypestring,
    },
    XTableUiComponent = {
        Key = ValueTypestringPrimaryKey,
        PrefabUrl = ValueTypestring,
    },
    XTableUiControllerTipsGroupMap = {
        UiName = ValueTypestringPrimaryKey,
        Sort = ValueTypeint,
        IsShow = ValueTypebool,
        KeyCode = Type1ValueTypeint,
        KeyText = Type1ValueTypestring,
    },
    XTableUiDownloadPreviewControl = {
        Id = ValueTypeintPrimaryKey,
        OptionName = ValueTypestring,
        Desc = ValueTypestring,
        IgnoreInterput = ValueTypebool,
        Order = ValueTypeint,
        ResType = ValueTypeint,
    },
    XTableUiFightAchievement = {
        Id = ValueTypeintPrimaryKey,
        AssetPath = ValueTypestring,
        LayoutType = ValueTypeint,
        CueId = ValueTypeint,
        LoopTime = ValueTypefloat,
    },
    XTableUiFightButtonDefaultStyle = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Scheme = ValueTypeint,
    },
    XTableUiFightCerberusDialogBox = {
        Id = ValueTypeintPrimaryKey,
        UiPrefab = ValueTypestring,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        ShowTime = ValueTypeint,
        CvList = Type1ValueTypeint,
    },
    XTableUiFightCommonImage = {
        Id = ValueTypeintPrimaryKey,
        RawImagePath = ValueTypestring,
        PosX = ValueTypefloat,
        PosY = ValueTypefloat,
        Width = ValueTypefloat,
        Height = ValueTypefloat,
        IsShowBg = ValueTypebool,
        IsShowMask = ValueTypebool,
    },
    XTableUiFightLilithGacha = {
        Id = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        GachaIcon = ValueTypestring,
        GapuLeftIcon = ValueTypestring,
        GapuRightIcon = ValueTypestring,
        IntervalTime = ValueTypefloat,
    },
    XTableUiFightRedFog = {
        Id = ValueTypeintPrimaryKey,
        OpenFog = ValueTypebool,
        FogLevel = ValueTypeint,
        OpenProtector = ValueTypebool,
        SkillCD = ValueTypefloat,
        ProtectorTime = ValueTypefloat,
    },
    XTableUiFightTutorial = {
        Id = ValueTypeintPrimaryKey,
        Titles = Type1ValueTypestring,
        Contents = Type1ValueTypestring,
        AssetPaths = Type1ValueTypestring,
        AssetTypes = Type1ValueTypeint,
    },
    XTableUiGoodsLabel = {
        Id = ValueTypeintPrimaryKey,
        Note = ValueTypestring,
        PrefabUrl = ValueTypestring,
        Icon = ValueTypestring,
        Location = ValueTypeint,
        OffsetX = ValueTypefloat,
        OffsetY = ValueTypefloat,
        Description = ValueTypestring,
    },
    XTableUiMainSubMenu = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Title = ValueTypestring,
        SubTitle = ValueTypestring,
        Desc = ValueTypestring,
        StyleType = ValueTypeint,
        BtnIcon = ValueTypestring,
        SkipId = ValueTypeint,
        ConditionId = ValueTypeint,
        RedPointCondition = Type1ValueTypestring,
        RedPointParam = Type1ValueTypeint,
    },
    XTableUiMainSubMenuDynamic = {
        Key = ValueTypestringPrimaryKey,
        ImgPath = ValueTypestring,
    },
    XTableUiMainThemeMatching = {
        Id = ValueTypeintPrimaryKey,
        Color = Type1ValueTypestring,
        Background = Type1ValueTypestring,
        Effect = Type1ValueTypestring,
    },
    XTableUiModel = {
        Id = ValueTypestringPrimaryKey,
        ModelPath = ValueTypestring,
        HXModelPath = ValueTypestring,
        LowModelPath = ValueTypestring,
        LowHXModelPath = ValueTypestring,
        ControllerPath = ValueTypestring,
        DisplayControllerPath = ValueTypestring,
        UiDefaultAnimationPath = ValueTypestring,
        FashionControllerPath = ValueTypestring,
        HideNodeName = Type1ValueTypestring,
        ScriptPartId = ValueTypeint,
    },
    XTableUiModelBoneActive = {
        Id = ValueTypeintPrimaryKey,
        ActionId = ValueTypestring,
        ModelName = ValueTypestring,
        HideNodes = Type1ValueTypestring,
        ShowNodes = Type1ValueTypestring,
    },
    XTableUiModelBoneActiveNameAuto = {
        Id = ValueTypestringPrimaryKey,
        Value = ValueTypeint,
    },
    XTableUiModelCamera = {
        Id = ValueTypeintPrimaryKey,
        UiName = ValueTypestring,
        ModelName = ValueTypestring,
        CameraName = Type1ValueTypestring,
        PositionX = Type1ValueTypefloat,
        PositionY = Type1ValueTypefloat,
        PositionZ = Type1ValueTypefloat,
        RotationX = Type1ValueTypefloat,
        RotationY = Type1ValueTypefloat,
        RotationZ = Type1ValueTypefloat,
        FieldOfView = Type1ValueTypefloat,
    },
    XTableUiModelCameraNameAuto = {
        Id = ValueTypestringPrimaryKey,
        Value = ValueTypeint,
    },
    XTableUiModelOffWeaponBoneBind = {
        ModelId = ValueTypestringPrimaryKey,
        IsOffBindBone = ValueTypeint,
        ActionId = Type1ValueTypestring,
        WeaponCaseName = Type1ValueTypestring,
    },
    XTableUiModelTransform = {
        Id = ValueTypeintPrimaryKey,
        UiName = ValueTypestring,
        ModelName = ValueTypestring,
        PositionX = ValueTypefloat,
        PositionY = ValueTypefloat,
        PositionZ = ValueTypefloat,
        RotationX = ValueTypefloat,
        RotationY = ValueTypefloat,
        RotationZ = ValueTypefloat,
        ScaleX = ValueTypefloat,
        ScaleY = ValueTypefloat,
        ScaleZ = ValueTypefloat,
    },
    XTableUiModelTransformNameAuto = {
        Id = ValueTypestringPrimaryKey,
        Value = ValueTypeint,
    },
    XTableUiObjectPrefab = {
        UiName = ValueTypestringPrimaryKey,
        ParamKeys = Type1ValueTypestring,
        ParamValues = Type1ValueTypestring,
    },
    XTableUiPanelTip = {
        Id = ValueTypeintPrimaryKey,
        Priority = ValueTypeint,
        SkipId = ValueTypeint,
        Type = ValueTypeint,
        FunctionName = ValueTypestring,
        IgnoreOnTerminal = ValueTypeint,
        IsLockWithTerminalMobile = ValueTypebool,
    },
    XTableUiPcScreenResolution = {
        Id = ValueTypeintPrimaryKey,
        X = ValueTypeint,
        Y = ValueTypeint,
    },
    XTableUiSceneTransform = {
        Id = ValueTypeintPrimaryKey,
        UiName = ValueTypestring,
        SceneUrl = ValueTypestring,
        PositionX = ValueTypefloat,
        PositionY = ValueTypefloat,
        PositionZ = ValueTypefloat,
        RotationX = ValueTypefloat,
        RotationY = ValueTypefloat,
        RotationZ = ValueTypefloat,
        ScaleX = ValueTypefloat,
        ScaleY = ValueTypefloat,
        ScaleZ = ValueTypefloat,
    },
    XTableUiSpecialModelCamera = {
        Id = ValueTypeintPrimaryKey,
        UiName = ValueTypestring,
        CharacterId = ValueTypeint,
        CameraName = Type1ValueTypestring,
        PositionX = Type1ValueTypefloat,
        PositionY = Type1ValueTypefloat,
        PositionZ = Type1ValueTypefloat,
        RotationX = Type1ValueTypefloat,
        RotationY = Type1ValueTypefloat,
        RotationZ = Type1ValueTypefloat,
        FieldOfView = Type1ValueTypefloat,
    },
    XTableUiSpecialModelCameraNameAuto = {
        Id = ValueTypestringPrimaryKey,
        Value = ValueTypeint,
    },
    XTableUnionKillActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        RankTimeId = ValueTypeint,
        PraiseBaseRank = ValueTypeint,
        TaskLimitId = Type1ValueTypeint,
        SectionId = Type1ValueTypeint,
    },
    XTableUnionKillActivityDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableUnionKillEventDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
        Level = ValueTypeint,
    },
    XTableUnionKillEventStage = {
        Id = ValueTypeintPrimaryKey,
        EventId = Type1ValueTypeint,
    },
    XTableUnionKillRankLevel = {
        Id = ValueTypeintPrimaryKey,
        MinLevel = ValueTypeint,
        MaxLevel = ValueTypeint,
        Name = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableUnionKillRankReward = {
        Id = ValueTypeintPrimaryKey,
        LevelId = ValueTypeint,
        MinRank = ValueTypefloat,
        MaxRank = ValueTypefloat,
        MailId = ValueTypeint,
        RankIcon = ValueTypestring,
    },
    XTableUnionKillScoreRule = {
        Id = ValueTypeintPrimaryKey,
        DamageMaxScore = ValueTypeint,
        TimeMaxScore = ValueTypeint,
        HpMaxScore = ValueTypeint,
        BossLoseHp = ValueTypefloat,
        BossLoseHpScore = ValueTypeint,
        BossTotalHp = ValueTypeint,
        LeftTime = ValueTypeint,
        LeftTimeScore = ValueTypeint,
        CharLeftHp = ValueTypefloat,
        CharLeftHpScore = ValueTypeint,
    },
    XTableUnionKillSection = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        BoxRewardId = ValueTypeint,
        KillBossCount = ValueTypeint,
        UnlockBossStageLimit = ValueTypeint,
        EventStageLimit = ValueTypeint,
        SingleFightTime = ValueTypeint,
        BaseRankNum = ValueTypeint,
        BossStage = ValueTypeint,
        BossId = ValueTypeint,
        BossTotalHp = ValueTypeint,
        TrialStage = ValueTypeint,
        TrialUseShare = ValueTypeint,
        EventStageId = Type1ValueTypeint,
    },
    XTableUnionKillSectionDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        BossIcon = ValueTypestring,
        TrialIcon = ValueTypestring,
        BossBuffName = ValueTypestring,
        BossBuffText = ValueTypestring,
        MainPrefabName = ValueTypestring,
        ItemPrefabName = ValueTypestring,
        SectionIcon = Type1ValueTypestring,
    },
    XTableUnionKillWeather = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        EventId = Type1ValueTypeint,
        Weight = ValueTypeint,
    },
    XTableUnionKillWeatherChange = {
        Id = ValueTypeint,
        Hour = Type1ValueTypeint,
    },
    XTableUnionKillWeatherDetails = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        Icon = ValueTypestring,
    },
    XTableUnPatchConfig = {
        Id = ValueTypeintPrimaryKey,
        ResourceType = Type1ValueTypestring,
        ResourceParam = Type1ValueTypestring,
    },
    XTableUrgentEvent = {
        Id = ValueTypeintPrimaryKey,
        SimpleDesc = ValueTypestring,
        Icon = ValueTypestring,
        Effect = ValueTypestring,
        StageIcon = ValueTypestring,
        StageEffect = ValueTypestring,
        BgEffect = ValueTypestring,
        BgColor = ValueTypestring,
        SuccessRate = ValueTypeint,
        DayMaxLimit = ValueTypeint,
        Time = ValueTypeint,
        IsFailDestory = ValueTypebool,
        MinLevel = ValueTypeint,
        MaxLevel = ValueTypeint,
        ConditionId = Type1ValueTypeint,
        StageId = Type1ValueTypeint,
        Weight = Type1ValueTypeint,
        FightEvent = Type1ValueTypeint,
    },
    XTableUrlConfig = {
        Id = ValueTypeintPrimaryKey,
        Url = ValueTypestring,
        UrlIOS = ValueTypestring,
        UrlPC = ValueTypestring,
        Title = ValueTypestring,
        IsDisableAudio = ValueTypebool,
        IsTransparent = ValueTypebool,
        IsEmbed = ValueTypebool,
        IOSEmbedType = ValueTypeint,
        PcEmbedType = ValueTypeint,
        IsLandscape = ValueTypebool,
        IsPcLandscape = ValueTypebool,
        ParamEncryptionType = ValueTypeint,
        ExtendParams = Type1ValueTypestring,
        UrlParams = Type1ValueTypestring,
    },
    XTableVersionGiftActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        Name = ValueTypestring,
        DailyGiftReward = ValueTypeint,
        VersionGiftReward = ValueTypeint,
        MailId = ValueTypeint,
        ActivityTaskGroup = ValueTypeint,
        NormalTaskGroup = ValueTypeint,
        DailyTaskGroup = ValueTypeint,
    },
    XTableVersionGiftProcess = {
        ActivityId = ValueTypeintPrimaryKey,
        TaskCompleteCount = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
    },
    XTableVideoConfig = {
        Id = ValueTypeintPrimaryKey,
        BaseVideoId = ValueTypeint,
        ConditionId = ValueTypeint,
        Title = ValueTypestring,
        Height = ValueTypefloat,
        Width = ValueTypefloat,
        VideoUrl = ValueTypestring,
        VideoUrlPc = ValueTypestring,
    },
    XTableWaveRevise = {
        Id = ValueTypeint,
        ChallengeId = ValueTypeint,
        MinWave = ValueTypeint,
        MaxWave = ValueTypeint,
        AttribReviseId = ValueTypeint,
        ArenaAttribTypes = Type1ValueTypeint,
        ArenaAttribValues = Type1ValueTypeint,
    },
    XTableWeaponDeregulateUI = {
        Lv = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        LvUpTips = ValueTypestring,
        IconQuality = ValueTypestring,
        ItemsQuality = ValueTypestring,
        IconQualityEffect = ValueTypestring,
        ItemsQualityEffect = ValueTypestring,
        SceneStartEffectPath = ValueTypestring,
        SceneStartEffectTime = ValueTypeint,
        SceneLoopEffectPath = ValueTypestring,
    },
    XTableWeaponFashion = {
        Id = ValueTypeintPrimaryKey,
        EquipType = ValueTypeint,
        ItemId = ValueTypeint,
        ItemCount = ValueTypeint,
        ItemCountByHour = ValueTypeint,
        WeaponSkillId = ValueTypeint,
        EffectTimeStr = ValueTypestring,
        ExpireTimeStr = ValueTypestring,
    },
    XTableWeaponFashionRes = {
        Id = ValueTypeintPrimaryKey,
        Quality = ValueTypeint,
        Priority = ValueTypeint,
        Name = ValueTypestring,
        Description = ValueTypestring,
        WorldDescription = ValueTypestring,
        Icon = ValueTypestring,
        BigIcon = ValueTypestring,
        SkipIdParams = Type1ValueTypeint,
        ModelTransId = Type1ValueTypeint,
        ResonanceModelTransId1 = Type1ValueTypeint,
        ResonanceModelTransId2 = Type1ValueTypeint,
        ResonanceModelTransId3 = Type1ValueTypeint,
        ShopIcon = ValueTypestring,
    },
    XTableWeaponOverrun = {
        Id = ValueTypeintPrimaryKey,
        WeaponId = ValueTypeint,
        Level = ValueTypeint,
        LevelName = ValueTypestring,
        ConsumeItemIds = Type1ValueTypeint,
        ConsumeItemCounts = Type1ValueTypeint,
        OverrunType = ValueTypeint,
        ChipBindType = ValueTypeint,
        ActiveSuitItemId = ValueTypeint,
        ActiveSuitItemCount = ValueTypeint,
        MagicIds = Type1ValueTypeint,
        ShowOverrunSkillId = ValueTypeint,
        ShowOverrunEffect = ValueTypebool,
        CharacterId = ValueTypeint,
        Name = ValueTypestring,
        Desc = ValueTypestring,
        UpSkillGroupId = ValueTypeint,
        UpSkillGroupLevel = ValueTypeint,
        Ability = ValueTypeint,
        UiNodePosX = Type2KeyTypeintValueTypefloat,
        UiNodePosY = Type2KeyTypeintValueTypefloat,
        UiLinePointList = Type2KeyTypeintValueTypestring,
        SelectedCameraPosX = ValueTypefloat,
        SelectedCameraPosY = ValueTypefloat,
        SelectedCameraPosZ = ValueTypefloat,
        SelectedCameraRotX = ValueTypefloat,
        SelectedCameraRotY = ValueTypefloat,
        SelectedCameraRotZ = ValueTypefloat,
    },
    XTableWeaponOverrunSkill = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
    },
    XTableWeaponSetting = {
        Id = ValueTypeintPrimaryKey,
        EquipId = ValueTypeint,
        Order = ValueTypeint,
        Type = ValueTypeint,
        Title = ValueTypestring,
        Text = ValueTypestring,
        Condition = Type1ValueTypeint,
    },
    XTableWeaponSkill = {
        Id = ValueTypeintPrimaryKey,
        BornMagic = Type1ValueTypeint,
        SubSkillId = Type1ValueTypeint,
        Ability = ValueTypeint,
        Icon = ValueTypestring,
        Name = ValueTypestring,
        Description = ValueTypestring,
        DesLinkCharacterSkillId = ValueTypeint,
        Account = ValueTypestring,
    },
    XTableWeaponSkillPool = {
        Id = ValueTypeintPrimaryKey,
        PoolId = ValueTypeint,
        Weight = ValueTypeint,
        CharacterId = ValueTypeint,
        SkillId = Type1ValueTypeint,
    },
    XTableWeekChallengeActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MailId = ValueTypeint,
        Name = ValueTypestring,
        PrefabPath = ValueTypestring,
        FullScreenBg = ValueTypestring,
        BtnBg = ValueTypestring,
        TaskGroupId = Type1ValueTypeint,
    },
    XTableWeekChallengeReward = {
        ActivityId = ValueTypeintPrimaryKey,
        Id = ValueTypeintPrimaryKey,
        TaskCompleteCount = Type1ValueTypeint,
        RewardId = Type1ValueTypeint,
    },
    XTableWeekChallengeTask = {
        TaskGroupId = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTableWelfare = {
        Id = ValueTypeintPrimaryKey,
        FunctionType = ValueTypeint,
        SubConfigId = ValueTypeint,
        Sort = ValueTypeint,
    },
    XTableWheelchairManualActivity = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        CountDown = ValueTypeint,
        LottoId = ValueTypeint,
        PurchaseType = ValueTypeint,
        ShowPackageIds = Type1ValueTypeint,
        ActivityConfigId = ValueTypeint,
        PlanIds = Type1ValueTypeint,
        TeachConnectivityStageId = ValueTypeint,
        TeachCommonStageIds = Type1ValueTypeint,
        TeachTaskIds = Type1ValueTypeint,
        CommonBattlePassManualId = ValueTypeint,
        SeniorBattlePassManualId = ValueTypeint,
        BpLevelConfig = Type1ValueTypeint,
    },
    XTableWheelchairManualActivityShow = {
        ActivityId = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TeachingShowRewardId = ValueTypeint,
        TabIds = Type1ValueTypeint,
    },
    XTableWheelchairManualBattlePassLevel = {
        Id = ValueTypeintPrimaryKey,
        Level = ValueTypeint,
        NeedExp = ValueTypeint,
        IsSpecial = ValueTypebool,
    },
    XTableWheelchairManualBattlePassManual = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Name = ValueTypestring,
        IsFree = ValueTypebool,
        ConsumeItemId = ValueTypeint,
        ConsumeItemCount = ValueTypeint,
        RewardId = ValueTypeint,
        PreviewRewardId = ValueTypeint,
        BpRewardConfig = Type1ValueTypeint,
        Desc = ValueTypestring,
    },
    XTableWheelchairManualBattlePassPlan = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IsSpecial = ValueTypebool,
        RewardId = ValueTypeint,
        IsDisplays = Type1ValueTypeint,
        TaskIds = Type1ValueTypeint,
        TitleIcon = ValueTypestring,
    },
    XTableWheelchairManualBattlePassReward = {
        Id = ValueTypeintPrimaryKey,
        Level = ValueTypeint,
        RewardId = ValueTypeint,
        IsDisplays = Type1ValueTypeint,
    },
    XTableWheelchairManualCharacterPlan = {
        ActivityId = ValueTypeintPrimaryKey,
        CharacterId = ValueTypeint,
        CharacterPlanIndex = ValueTypeint,
        WeaponId = ValueTypeint,
        WeaponPlanIndex = ValueTypeint,
    },
    XTableWheelchairManualClientConfig = {
        Key = ValueTypestringPrimaryKey,
        Values = Type1ValueTypestring,
    },
    XTableWheelchairManualCoreRewardPreview = {
        Id = ValueTypeintPrimaryKey,
        RewardId = ValueTypeint,
        PlanId = ValueTypeint,
        ShowIcon = ValueTypestring,
    },
    XTableWheelchairManualGuideActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Sort = ValueTypeint,
        TimeId = ValueTypeint,
        ConditionId = ValueTypeint,
        IsHideTime = ValueTypebool,
        KindId = ValueTypeint,
        SkipId = ValueTypeint,
        TaskSourceGroupId = ValueTypeint,
        PeriodIds = Type1ValueTypeint,
        MainTemplateIds = Type1ValueTypeint,
        MainTemplateCounts = Type1ValueTypeint,
        ActivityIcon = ValueTypestring,
        ShopId = Type1ValueTypeint,
        EventCause = Type1ValueTypeint,
    },
    XTableWheelchairManualGuideActivityPeriod = {
        Id = ValueTypeintPrimaryKey,
        TimeId = ValueTypeint,
        MainTemplateIds = Type1ValueTypeint,
        MainTemplateCounts = Type1ValueTypeint,
    },
    XTableWheelchairManualGuideKind = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        BgColor = ValueTypestring,
    },
    XTableWheelchairManualGuideWeekActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Sort = ValueTypeint,
        KindId = ValueTypeint,
        SkipId = ValueTypeint,
        ActivityIcon = ValueTypestring,
        RefreshTime = ValueTypestring,
        ChapterType = ValueTypeint,
        ManagerName = ValueTypestring,
    },
    XTableWheelchairManualGuideWeekReward = {
        Id = ValueTypeintPrimaryKey,
        MainId = ValueTypeint,
        SubId = ValueTypeint,
        MainTemplateId = Type1ValueTypeint,
        MainTemplateCount = Type1ValueTypeint,
        TaskSourceGroupId = ValueTypeint,
        ShopId = Type1ValueTypeint,
        EventCause = Type1ValueTypeint,
        ExtraItem = Type1ValueTypeint,
    },
    XTableWheelchairManualPassportPrefab = {
        ActivityId = ValueTypeintPrimaryKey,
        CommonDesc = ValueTypestring,
        SeniorDesc = ValueTypestring,
        CommonSkipId = ValueTypeint,
        SeniorSkipId = ValueTypeint,
        PrefabAddress = ValueTypestring,
    },
    XTableWheelchairManualPassportScrollCards = {
        ActivityId = ValueTypeintPrimaryKey,
        SwitchInterval = ValueTypefloat,
        ScrollSpeed = ValueTypefloat,
        Images = Type1ValueTypestring,
        BannerLabels = Type1ValueTypestring,
        ImgSkips = Type1ValueTypeint,
    },
    XTableWheelchairManualTabs = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Condition = ValueTypeint,
        Image = ValueTypestring,
        MainTitle = ValueTypestring,
        SecondTitle = ValueTypestring,
        UIPrefabUrl = ValueTypestring,
        Params = Type1ValueTypestring,
    },
    XTableWhiteValentinesDayAttr = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IconPath = ValueTypestring,
    },
    XTableWhiteValentinesDayConfig = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        OpenConditionId = ValueTypeint,
        BgPicturePath = ValueTypestring,
        BgEffectPath = ValueTypestring,
        DefaultEnergy = ValueTypeint,
        MaxEnergy = ValueTypeint,
        EnergyRecoverySpeed = ValueTypeint,
        EnergyIconPath = ValueTypestring,
        ContributionItemId = ValueTypeint,
        CoinItemId = ValueTypeint,
        RandomMeetCostCoin = ValueTypeint,
        DefaultRoleId = Type1ValueTypeint,
    },
    XTableWhiteValentinesDayEvent = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        Description = ValueTypestring,
        AttrType = ValueTypeint,
        RankType = Type1ValueTypeint,
        RankWeight = Type1ValueTypeint,
    },
    XTableWhiteValentinesDayPlace = {
        Id = ValueTypeintPrimaryKey,
        OrderId = ValueTypeint,
        PrePlaceId = ValueTypeint,
        BgPath = ValueTypestring,
        InviteNum = ValueTypeint,
        DefaultEventId = ValueTypeint,
        RandomEventId = Type1ValueTypeint,
    },
    XTableWhiteValentinesDayRank = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IconPath = ValueTypestring,
        CostEnergy = ValueTypeint,
        CostTime = ValueTypeint,
        RewardContribution = ValueTypeint,
        RewardCoin = ValueTypeint,
    },
    XTableWhiteValentinesDayRole = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        IconPath = ValueTypestring,
        AttrType = ValueTypeint,
        AttrValue = ValueTypeint,
        EncounterStoryId = ValueTypeint,
        InviteStoryId = ValueTypeint,
        CommuId = ValueTypeint,
        CutDownTime = ValueTypeint,
        ContributionBuff = ValueTypeint,
    },
    XTableWhiteValentinesDayStory = {
        Id = ValueTypeintPrimaryKey,
        Title = ValueTypestring,
        StoryText = ValueTypestring,
    },
    XTableWorldBossActivity = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        TimeId = ValueTypeint,
        BeginTimeStr = ValueTypestring,
        EndTimeStr = ValueTypestring,
        AttributeAreaId = Type1ValueTypeint,
        BossAreaId = Type1ValueTypeint,
        SpecialSaleId = Type1ValueTypeint,
        ActionPointId = ValueTypeint,
        MaxActionPoint = ValueTypeint,
        ShopCurrencyId = ValueTypeint,
        TitleId = ValueTypeint,
        StartStoryId = ValueTypestring,
        Bg = ValueTypestring,
    },
    XTableWorldBossAttributeArea = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        EnglishName = ValueTypestring,
        MaxChallengeCount = ValueTypeint,
        FinishReward = ValueTypeint,
        BuffId = Type1ValueTypeint,
        StageId = Type1ValueTypeint,
        SystemReportId = Type1ValueTypeint,
        PlayerReportId = Type1ValueTypeint,
        StartStoryId = ValueTypestring,
        AreaImg = ValueTypestring,
        AreaDesc = ValueTypestring,
        PrefabName = ValueTypestring,
    },
    XTableWorldBossAttributeStage = {
        Id = ValueTypeintPrimaryKey,
        TotalFinishCount = ValueTypeint,
        PreStageId = Type1ValueTypeint,
        FinishReward = ValueTypeint,
        BuffId = Type1ValueTypeint,
        ConsumeId = ValueTypeint,
        ConsumeCount = ValueTypeint,
        StartStoryId = ValueTypestring,
        SystemReportId = Type1ValueTypeint,
    },
    XTableWorldBossBossArea = {
        Id = ValueTypeintPrimaryKey,
        Name = ValueTypestring,
        UnlockNeedStageCount = ValueTypeint,
        MaxChallengeCount = ValueTypeint,
        StageId = ValueTypeint,
        PhasesRewardId = Type1ValueTypeint,
        SystemReportId = Type1ValueTypeint,
        PlayerReportId = Type1ValueTypeint,
        StartStoryId = ValueTypestring,
        FinishStoryId = ValueTypestring,
        AreaImg = ValueTypestring,
        AreaLockImg = ValueTypestring,
        AreaDesc = ValueTypestring,
        ModelId = ValueTypestring,
        BossTaskId = Type1ValueTypeint,
    },
    XTableWorldBossBossShop = {
        Id = ValueTypeintPrimaryKey,
        RewardId = ValueTypeint,
        ConsumeId = ValueTypeint,
        ConsumeCount = ValueTypeint,
        DiscountId = Type1ValueTypeint,
        ShopImg = ValueTypestring,
    },
    XTableWorldBossBossShopDiscount = {
        Id = ValueTypeintPrimaryKey,
        HpPercent = ValueTypeint,
        Discount = ValueTypefloat,
        BossId = ValueTypeint,
        DiscountText = ValueTypestring,
    },
    XTableWorldBossBossStage = {
        Id = ValueTypeintPrimaryKey,
        StageId = ValueTypeint,
        Level = ValueTypeint,
        Icon = ValueTypestring,
        Desc = ValueTypestring,
        DescColor = ValueTypestring,
        HurtHp = ValueTypeint,
        RecommendAbility = ValueTypeint,
        RewardId = ValueTypeint,
        MonsterLevel = Type1ValueTypeint,
    },
    XTableWorldBossBuff = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        Priority = ValueTypeint,
        GroupId = ValueTypeint,
        Name = ValueTypestring,
        Level = ValueTypeint,
        CustomizeId = ValueTypeint,
        InfoTitle = ValueTypestring,
        InfoText = ValueTypestring,
        InfoConditionText = ValueTypestring,
        HintText = ValueTypestring,
        Icon = ValueTypestring,
        IsNotShow = ValueTypeint,
    },
    XTableWorldBossFightReport = {
        Id = ValueTypeintPrimaryKey,
        Type = ValueTypeint,
        HeadIcon = ValueTypestring,
        Phases = ValueTypeint,
        Score = ValueTypeint,
        Message = ValueTypestring,
    },
    XTableWorldBossHpConfig = {
        Id = ValueTypeint,
        ZoneName = ValueTypestring,
        BossId = ValueTypeint,
        TotalHp = ValueTypeint,
    },
    XTableWorldBossHpControl = {
        Id = ValueTypeint,
        ZoneName = ValueTypestring,
        Day = ValueTypeint,
        BossId = ValueTypeint,
        MaxLoseHp = ValueTypeint,
        MaxControlValue = ValueTypeint,
        MinPercent = Type1ValueTypeint,
        MaxPercent = Type1ValueTypeint,
        ControlValue = Type1ValueTypeint,
    },
    XTableWorldBossPhasesReward = {
        Id = ValueTypeintPrimaryKey,
        HpPercent = ValueTypeint,
        RewardId = ValueTypeint,
    },
    XTableWorldBossScoreRule = {
        Id = ValueTypeint,
        Damage = ValueTypeint,
        DamageScore = ValueTypeint,
        MaxDamageScore = ValueTypeint,
        CharLeftHp = ValueTypefloat,
        CharLeftHpScore = ValueTypeint,
        MaxCharacterScore = ValueTypeint,
    },
    XTableWorldBossStageScheduleControl = {
        Id = ValueTypeint,
        ZoneName = ValueTypestring,
        StageId = ValueTypeint,
        MinCount = Type1ValueTypeint,
        MaxCount = Type1ValueTypeint,
    },
    XTableZhouMu = {
        Id = ValueTypeintPrimaryKey,
        ChapterId = Type1ValueTypeint,
        TaskId = Type1ValueTypeint,
    },
    XTableZhouMuChapter = {
        Id = ValueTypeintPrimaryKey,
        ConditionId = Type1ValueTypeint,
        PrefabName = ValueTypestring,
        OrderId = ValueTypeint,
        StageId = Type1ValueTypeint,
    },
    XTableItemCombine = {
        ItemId = ValueTypeintPrimaryKey,
        GroupId = ValueTypeint,
        Priority = ValueTypeint,
    },
}
