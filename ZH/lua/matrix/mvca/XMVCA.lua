---
--- MVCA管理容器
--- Created by Jaylin.
--- DateTime: 2023-03-06-006 11:32
---
---


---@class XMVCACls
---@field _AgencyDict table<string, XAgency>
---@field _ControlDict table<string, XControl>
---@field _ModelDict table<string, XModel|XModelBase>
---@field _ControlReleaseDict table<string, XControl>
---@field private _TabConfigDict table<string, XTabConfig>
---@field XCharacter XCharacterAgency
---@field XCommonCharacterFilter XCommonCharacterFilterAgency
---@field XEquip XEquipAgency
---@field XTheatre3 XTheatre3Agency
---@field XBlackRockChess XBlackRockChessAgency
---@field XFuben XFubenAgency
---@field XPassport XPassportAgency
---@field XUiMain XUiMainAgency
---@field XConnectingLine XConnectingLineAgency
---@field XSubPackage XSubPackageAgency
---@field XPreload XPreloadAgency
---@field XTaikoMaster XTaikoMasterAgency
---@field XSameColor XSameColorAgency
---@field XRogueSim XRogueSimAgency
---@field XBirthdayPlot XBirthdayPlotAgency
---@field XFavorability XFavorabilityAgency
---@field XBigWorldService XBigWorldServiceAgency
---@field XBigWorldCharacter XBigWorldCharacterAgency
---@field XDlcRoom XDlcRoomAgency
---@field XDlcWorld XDlcWorldAgency
---@field XDlcCasual XDlcCasualAgency
---@field XBigWorld XBigWorldAgency
---@field XBigWorldQuest XBigWorldQuestAgency
---@field XBigWorldAlbum XBigWorldAlbumAgency
---@field XSkyGardenCafe XSkyGardenCafeAgency
---@field XSkyGardenShoppingStreet XSkyGardenShoppingStreetAgency
---@field XFubenEx XFubenExAgency
---@field XCerberusGame XCerberusGameAgency
---@field XFangKuai XFangKuaiAgency
---@field XGoldenMiner XGoldenMinerAgency
---@field XReform XReformAgency
---@field XKotodamaActivity XKotodamaActivityAgency
---@field XMail XMailAgency
---@field XAccumulateExpend XAccumulateExpendAgency
---@field XFubenBossSingle XFubenBossSingleAgency
---@field XRift XRiftAgency
---@field XTemple XTempleAgency
---@field XTemple2 XTemple2Agency
---@field XFSM XFSMAgency
---@field XLinkCraftActivity XLinkCraftActivityAgency
---@field XArchive XArchiveAgency
---@field XLeftTime XLeftTimeAgency
---@field XAprilFoolDay XAprilFoolDayAgency
---@field XAudio XAudioAgency
---@field XRestaurant XRestaurantAgency
---@field XDlcMultiplayer XDlcMultiplayerAgency
---@field XDlcMultiMouseHunter XDlcMultiMouseHunterAgency
---@field XDunhuang XDunhuangAgency
---@field XArena XArenaAgency
---@field XFightLevelMusicGame XFightLevelMusicGameAgency
---@field XLineArithmetic XLineArithmeticAgency
---@field XMechanismActivity XMechanismActivityAgency
---@field XBossInshot XBossInshotAgency
---@field XDailyReset XDailyResetAgency
---@field XMainLine2 XMainLine2Agency
---@field XMovie XMovieAgency
---@field XTheatre4 XTheatre4Agency
---@field XLogUpload XLogUploadAgency
---@field XSkyGarden XSkyGardenAgency
---@field X3CProxy X3CProxyAgency
---@field XScene XSceneAgency
---@field XUrl XUrlAgency
---@field XSimulateTrain XSimulateTrainAgency
---@field XBagOrganizeActivity XBagOrganizeActivityAgency
---@field XSucceedBoss XSucceedBossAgency
---@field XBigWorldCommanderDIY XBigWorldCommanderDIYAgency
---@field XGame2048 XGame2048Agency
---@field XBigWorldResource XBigWorldResourceAgency
---@field XNonogram XNonogramAgency
---@field XBigWorldBackpack XBigWorldBackpackAgency
---@field XFpsGame XFpsGameAgency
---@field XBigWorldMessage XBigWorldMessageAgency
---@field XPacMan XPacManAgency
---@field XPacMan2 XPacMan2Agency
---@field XWheelchairManual XWheelchairManualAgency
---@field XBigWorldMap XBigWorldMapAgency
---@field XBigWorldGamePlay XBigWorldGamePlayAgency
---@field XStageMemory XStageMemoryAgency
---@field XReCallActivity XReCallActivityAgency
---@field XBigWorldCommon XBigWorldCommonAgency
---@field XBigWorldUI XBigWorldUIAgency
---@field XAnniversary XAnniversaryAgency
---@field XMaverick3 XMaverick3Agency
---@field XGachaCanLiver XGachaCanLiverAgency
---@field XRhythmGame XRhythmGameAgency
---@field XMusicGameActivity XMusicGameActivityAgency
---@field XArrangementGame XArrangementGameAgency
---@field XConcertPreHeating XConcertPreHeatingAgency
---@field XLuckyTenant XLuckyTenantAgency
---@field XLuckyTenant2 XLuckyTenant2Agency
---@field XSkyGardenDorm XSkyGardenDormAgency
---@field XBigWorldTeach XBigWorldTeachAgency
---@field XPcg XPcgAgency
---@field XBigWorldSet XBigWorldSetAgency
---@field XGuildWar XGuildWarAgency
---@field XBigWorldLoading XBigWorldLoadingAgency
---@field XVersionGift XVersionGiftAgency
---@field XInstrumentSimulator XInstrumentSimulatorAgency
---@field XPokerGuessing2 XPokerGuessing2Agency
---@field XScoreTower XScoreTowerAgency
---@field XBigWorldFunction XBigWorldFunctionAgency
---@field XBigWorldInstance XBigWorldInstanceAgency 大世界副本
---@field XBigWorldCourse XBigWorldCourseAgency
---@field XBigWorldNews XBigWorldNewsAgency
---@field XBigWorldSkipFunction XBigWorldSkipFunctionAgency
---@field XTheatre5 XTheatre5Agency
---@field XBountyChallenge XBountyChallengeAgency
---@field XFubenSkyGarden XFubenSkyGardenAgency
---@field XDlcHelper XDlcHelperAgency
---@field XDlcRelink XDlcRelinkAgency
---@field XLineArithmetic2 XLineArithmetic2Agency
---@field XLineArithmetic3 XLineArithmetic3Agency
---@field XFashionStory XFashionStoryAgency
---@field XHelpCourse XHelpCourseAgency
---@field XSoloReform XSoloReformAgency
---@field XRpgMakerGame XRpgMakerGameAgency
---@field XRace XRaceAgency
---@field XPlotExhibition XPlotExhibitionAgency
---@field XFunction XFunctionAgency
---@field XFashionSuit XFashionSuitAgency
---@field XAreaWar XAreaWarAgency
---@field XMainLineLuosaita XMainLineLuosaitaAgency
---@field XSwitchableScene XSwitchableSceneAgency
---@field XRadioSign XRadioSignAgency
---@field XSkyGardenDroneGame XSkyGardenDroneGameAgency
---@field XItemRestrict XItemRestrictAgency
---@field XShop XShopAgency
---@field XItem XItemAgency
---@field XPBRGame XPBRGameAgency
---@field XLifeTree XLifeTreeAgency
---@field XTheatre6 XTheatre6Agency
---@field XFashion XFashionAgency
---@field XGameCollection XGameCollectionAgency
---@field XBigWorldMemory XBigWorldMemoryAgency
---@field XLowMemory XLowMemoryAgency
---@field XDyeMergeGame XDyeMergeGameAgency
local XMVCACls = require("MVCA/XMVCACls")

---常用的一些模块放在这里初始化
function XMVCACls:InitModule()
    --region
    self:RegisterAgency(ModuleId.XScene)
    self:RegisterAgency(ModuleId.XMail)
    self:RegisterAgency(ModuleId.XCharacter)
    self:RegisterAgency(ModuleId.XCommonCharacterFilter)
    self:RegisterAgency(ModuleId.XEquip)
    self:RegisterAgency(ModuleId.XMovie)

    self:RegisterAgency(ModuleId.XFSM)
    self:RegisterAgency(ModuleId.XFuben)
    self:RegisterAgency(ModuleId.XFubenEx)
    self:RegisterAgency(ModuleId.XTheatre3)
    self:RegisterAgency(ModuleId.XBlackRockChess)
    self:RegisterAgency(ModuleId.XTurntable)
    self:RegisterAgency(ModuleId.XBlackRockStage)
    self:RegisterAgency(ModuleId.XPassport)
    self:RegisterAgency(ModuleId.XTaikoMaster)
    self:RegisterAgency(ModuleId.XUiMain)
    self:RegisterAgency(ModuleId.XNewActivityCalendar)
    self:RegisterAgency(ModuleId.XTwoSideTower)
    self:RegisterAgency(ModuleId.XFavorability)
    self:RegisterAgency(ModuleId.XSameColor)
    self:RegisterAgency(ModuleId.XGoldenMiner)
    self:RegisterAgency(ModuleId.XFightLevelMusicGame)

    --endregion

--region 大世界

    self:RegisterAgency(ModuleId.XBigWorldService)
    self:RegisterAgency(ModuleId.XBigWorldUI)
    self:RegisterAgency(ModuleId.XBigWorldCharacter)
    self:RegisterAgency(ModuleId.XBigWorldGamePlay)
    self:RegisterAgency(ModuleId.XBigWorldMemory)
    self:RegisterAgency(ModuleId.XFubenSkyGarden)
    self:RegisterAgency(ModuleId.XBigWorldCourse)
    self:RegisterAgency(ModuleId.XBigWorldCommanderDIY)
--endregion 大世界
    self:RegisterAgency(ModuleId.XDlcHelper)
    self:RegisterAgency(ModuleId.XDlcRoom)
    self:RegisterAgency(ModuleId.XDlcWorld)
    self:RegisterAgency(ModuleId.XDlcCasual)
    self:RegisterAgency(ModuleId.XConnectingLine)
    self:RegisterAgency(ModuleId.XSubPackage)
    self:RegisterAgency(ModuleId.XPreload)
    self:RegisterAgency(ModuleId.XRogueSim)
    self:RegisterAgency(ModuleId.XBirthdayPlot)
    self:RegisterAgency(ModuleId.XCerberusGame)
    self:RegisterAgency(ModuleId.XArchive)
    self:RegisterAgency(ModuleId.XAnniversary)
    self:RegisterAgency(ModuleId.XReform)
    self:RegisterAgency(ModuleId.XKotodamaActivity)
    self:RegisterAgency(ModuleId.XFangKuai)
    self:RegisterAgency(ModuleId.XAccumulateExpend)
    self:RegisterAgency(ModuleId.XMainLine2)
    self:RegisterAgency(ModuleId.XFubenBossSingle)
    self:RegisterAgency(ModuleId.XTemple)
    self:RegisterAgency(ModuleId.XRift)
    self:RegisterAgency(ModuleId.XLinkCraftActivity)
    self:RegisterAgency(ModuleId.XLeftTime)
    self:RegisterAgency(ModuleId.XAprilFoolDay)
    self:RegisterAgency(ModuleId.XAudio)
    self:RegisterAgency(ModuleId.XRestaurant)
    self:RegisterAgency(ModuleId.XDlcMultiplayer)
    self:RegisterAgency(ModuleId.XDlcMultiMouseHunter)
    self:RegisterAgency(ModuleId.XBossInshot)
    self:RegisterAgency(ModuleId.XDunhuang)
    self:RegisterAgency(ModuleId.XArena)

    self:RegisterAgency(ModuleId.XUiFightTutorial)
    self:RegisterAgency(ModuleId.XLineArithmetic)
    self:RegisterAgency(ModuleId.XMechanismActivity)

    self:RegisterAgency(ModuleId.XUiFightAchievement)
    self:RegisterAgency(ModuleId.XDailyReset)
    self:RegisterAgency(ModuleId.XTheatre4)

    self:RegisterAgency(ModuleId.XLogUpload)
    self:RegisterAgency(ModuleId.X3CProxy)

    self:RegisterAgency(ModuleId.XUrl)
    self:RegisterAgency(ModuleId.XSimulateTrain)
    self:RegisterAgency(ModuleId.XBagOrganizeActivity)
    self:RegisterAgency(ModuleId.XSucceedBoss)
    self:RegisterAgency(ModuleId.XTemple2)
    self:RegisterAgency(ModuleId.XGame2048)

    self:RegisterAgency(ModuleId.XNonogram)

    self:RegisterAgency(ModuleId.XPacMan)
    self:RegisterAgency(ModuleId.XPacMan2)
    self:RegisterAgency(ModuleId.XWheelchairManual)
    self:RegisterAgency(ModuleId.XFpsGame)
    self:RegisterAgency(ModuleId.XStageMemory)
    self:RegisterAgency(ModuleId.XReCallActivity)
    self:RegisterAgency(ModuleId.XMaverick3)
    self:RegisterAgency(ModuleId.XGachaCanLiver)
    self:RegisterAgency(ModuleId.XRhythmGame)
    self:RegisterAgency(ModuleId.XMusicGameActivity)
    self:RegisterAgency(ModuleId.XArrangementGame)
    self:RegisterAgency(ModuleId.XConcertPreHeating)
    self:RegisterAgency(ModuleId.XLuckyTenant)
    self:RegisterAgency(ModuleId.XLuckyTenant2)
    self:RegisterAgency(ModuleId.XPcg)
    self:RegisterAgency(ModuleId.XVersionGift)
    self:RegisterAgency(ModuleId.XGuildWar)
    self:RegisterAgency(ModuleId.XInstrumentSimulator)
    self:RegisterAgency(ModuleId.XPokerGuessing2)
    self:RegisterAgency(ModuleId.XScoreTower)
    self:RegisterAgency(ModuleId.XTheatre5)
    self:RegisterAgency(ModuleId.XBountyChallenge)
    self:RegisterAgency(ModuleId.XDlcRelink)
    self:RegisterAgency(ModuleId.XLineArithmetic2)
    self:RegisterAgency(ModuleId.XLineArithmetic3)
    self:RegisterAgency(ModuleId.XFashionStory)
    self:RegisterAgency(ModuleId.XSoloReform)
    self:RegisterAgency(ModuleId.XHelpCourse)
    self:RegisterAgency(ModuleId.XRpgMakerGame)
    self:RegisterAgency(ModuleId.XFunction)

    self:RegisterAgency(ModuleId.XRace)
    self:RegisterAgency(ModuleId.XFashionSuit)
    self:RegisterAgency(ModuleId.XAreaWar)
    self:RegisterAgency(ModuleId.XMainLineLuosaita)

    self:RegisterAgency(ModuleId.XPlotExhibition)
    self:RegisterAgency(ModuleId.XSwitchableScene)
    self:RegisterAgency(ModuleId.XRadioSign)
    self:RegisterAgency(ModuleId.XItemRestrict)
    self:RegisterAgency(ModuleId.XShop)
    self:RegisterAgency(ModuleId.XItem)

    self:RegisterAgency(ModuleId.XPBRGame)
    self:RegisterAgency(ModuleId.XLifeTree)
    self:RegisterAgency(ModuleId.XTheatre6)
    self:RegisterAgency(ModuleId.XGameCollection)
    self:RegisterAgency(ModuleId.XFashion)
    self:RegisterAgency(ModuleId.XDyeMergeGame)
end

---@type XMVCACls
XMVCA = XMVCACls.New()



---新框架开发规则---
---1. 事件注册事件需要传入self, 不使用匿名函数
---2. 不要在类里定义基于文件的local变量, 不好做回收
---3. 内部使用的变量和函数前面加下划线
---4. model不对外, 避免又出现到处访问的情况

---现存问题
---XLuaUi:OnGetEvents()注册的事件, 是针对基于XGameEventManager (C#)层派发的事件, lua层需要自己在XEventManager注册, 目前这块用的比较混乱了















