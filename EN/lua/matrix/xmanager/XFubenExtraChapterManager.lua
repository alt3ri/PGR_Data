local XExFubenExtralChapterManager = require("XEntity/XFuben/XExFubenExtralChapterManager")

XFubenExtraChapterCreator = function()
    local ExtraChapterManager = XExFubenExtralChapterManager.New(XEnumConst.FuBen.ChapterType.ExtralChapter)
    local ChapterInfos = {} -- info {FirstStage, ActiveStage, Stars, Unlock, Passed}
    local LastPassStage = {} -- index:章节数chapterId 内容:通关关卡passStageId
    ---@type XTableChapterExtra[]
    local ChapterExtraCfgs = {}
    local ChapterExtraDetailsCfgs = {}
    local StarTreasureCfgs = {}
    local ActivityChapters = {} --活动抢先体验ChapterId列表
    local ActivityEndTime = 0 --活动抢先体验结束时间
    local ActivityChallengeBeginTime = 0 --活动抢先体验结束时间(隐藏模式)
    local ActivityTimer
    local ExploreEventStateList = {}
    local ExploreGroupInfos = nil
    local ExploreItemInfos = nil
    local PlayerTreasureData = {}
    local CurrentClearData = {}
    --排序
    local orderIdSortFunc = function(a, b)
        return a.OrderId < b.OrderId
    end

    local SortById = function(a, b)
        return a.Id < b.Id
    end
    local ExItemRedPointState = {
        Off = 0,
        On = 1,
    }

    local DifficultType = {
        Normal = CS.XGame.Config:GetInt("FubenDifficultNormal"),
        Hard = CS.XGame.Config:GetInt("FubenDifficultHard")
    }

    function ExtraChapterManager.Init()
        ChapterExtraCfgs = XFubenExtraChapterConfigs.GetExtraChapterCfgs()
        ChapterExtraDetailsCfgs = XFubenExtraChapterConfigs.GetExtraChapterDetailsCfgs()
        StarTreasureCfgs = XFubenExtraChapterConfigs.GetExtraChapterStarTreasuresCfgs()
        ExtraChapterManager.UiGridChapterMoveMinX = CS.XGame.ClientConfig:GetInt("UiGridChapterMoveMinX")
        ExtraChapterManager.UiGridChapterMoveMaxX = CS.XGame.ClientConfig:GetInt("UiGridChapterMoveMaxX")
        ExtraChapterManager.UiGridChapterMoveTargetX = CS.XGame.ClientConfig:GetInt("UiGridChapterMoveTargetX")
        ExtraChapterManager.UiGridChapterMoveDuration = CS.XGame.ClientConfig:GetFloat("UiGridChapterMoveDuration")
    end

    function ExtraChapterManager.InitExtraInfos(infoDatas)
        if not infoDatas then return end
        if infoDatas.TreasureData then
            for i = 1, #infoDatas.TreasureData do
                PlayerTreasureData[infoDatas.TreasureData[i]] = true
            end
        end
        if infoDatas.LastPassStage then
            for k, v in pairs(infoDatas.LastPassStage) do
                LastPassStage[k] = v
            end
        end
        if infoDatas.ChapterEventInfos then
            ExtraChapterManager.SetChapterEventState(infoDatas.ChapterEventInfos)
        end
        XEventManager.AddEventListener(XEventId.EVENT_FUBEN_STAGE_SYNC, ExtraChapterManager.OnSyncStageData)
        XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_LEVEL_UP, ExtraChapterManager.InitStageInfoEx)
    end

    function ExtraChapterManager.InitStageInfoEx()
        ExtraChapterManager.InitStageInfo(false)
    end

    function ExtraChapterManager.InitStageInfo(checkNewUnlock)
        ExtraChapterManager.InitChapterData(checkNewUnlock)
        ExtraChapterManager.ExtraActivityStart()
    end

    local function InitChapterInfo(chapterMain, chapter)
        local info = {}
        if #chapter.StageId > 0 then
            info.ChapterMainId = chapterMain.Id
            info.FirstStage = chapter.StageId[1]
            local treasureCfg = XDataCenter.ExtraChapterManager.GetTreasureCfg(chapter.TreasureId[#chapter.TreasureId])
            info.TotalStars = treasureCfg and treasureCfg.RequireStar or 0
            -- Unlock/IsOpen/Stars/Passed 等字段在 GetChapterInfo 首次访问时按需计算
        end
        return info
    end

    -- 按需计算章节完整信息（Unlock/IsOpen/Stars/Passed 等），由 GetChapterInfo 懒调用
    local function RefreshChapterInfo(info, chapterMain, chapter)
        if not chapter or #chapter.StageId == 0 then
            info.Unlock = false  -- 清除 nil 哨兵，防止重入
            return
        end
        local firstStageInfo = XDataCenter.FubenManager.GetStageInfo(info.FirstStage)
        -- 如果章节处于活动时间内，根据时间判断是否可以解锁
        local firstUnlock = firstStageInfo.Unlock
        local firstPassed = firstStageInfo.Passed
        info.Unlock = firstUnlock
        info.IsOpen = firstStageInfo.IsOpen
        if not firstPassed and firstUnlock and ExtraChapterManager.CheckDiffHasAcitivity(chapter) then
            if not ExtraChapterManager.CheckActivityCondition(chapter.ChapterId) then
                info.Unlock = false
                info.IsOpen = false
            end
        elseif not (ExtraChapterManager.IsExtraActivityOpen() and ExtraChapterManager.CheckDiffHasAcitivity(chapter)) then
            local isOpen, desc = ExtraChapterManager.CheckOpenCondition(chapter.ChapterId)
            if not isOpen then
                info.Unlock = false
                info.IsOpen = false
            end
        end
        local passStageNum = 0
        local stars = 0
        local allPassed = true
        for _, v in ipairs(chapter.StageId) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(v)
            if stageInfo.Unlock then
                info.ActiveStage = v
                info.LastStageOrder = XDataCenter.FubenManager.GetStageOrderId(v)
            end
            if not stageInfo.Passed then
                allPassed = false
            else
                passStageNum = passStageNum + 1
            end
            stars = stars + stageInfo.Stars
        end
        info.Stars = stars > info.TotalStars and info.TotalStars or stars
        info.Passed = allPassed
        info.PassStageNum = passStageNum
    end
    
    function ExtraChapterManager.GetChapterUnlock(chapterId)
        local chapterConfigs = XFubenExtraChapterConfigs.GetExtraChapterDetailsCfgs()
        local chapter = chapterConfigs[chapterId]
        local firstStageInfo = XDataCenter.FubenManager.GetStageInfo(chapter.StageId[1])
        if not firstStageInfo.Passed and firstStageInfo.Unlock and ExtraChapterManager.CheckDiffHasAcitivity(chapter) then
            if not ExtraChapterManager.CheckActivityCondition(chapter.ChapterId) then
                return false
            end
        elseif (not ExtraChapterManager.IsExtraActivityOpen() and ExtraChapterManager.CheckDiffHasAcitivity(chapter)) or not ExtraChapterManager.CheckDiffHasAcitivity(chapter) then
            local isOpen, desc = ExtraChapterManager.CheckOpenCondition(chapter.ChapterId)
            if not isOpen then
                return false
            end
        end
        return true
    end

    function ExtraChapterManager.GetDifficult(stageId)
        local orderId, chapterId, difficult = ExtraChapterManager.GetInfo(stageId)
        return difficult
    end

    function ExtraChapterManager.GetChapterId(stageId)
        local orderId, chapterId, difficult = ExtraChapterManager.GetInfo(stageId)
        return chapterId
    end

    function ExtraChapterManager.GetOrderId(stageId)
        local orderId, chapterId, difficult = ExtraChapterManager.GetInfo(stageId)
        return orderId
    end
    
    function ExtraChapterManager.GetInfo(stageId)
        for _, chapterMain in pairs(ChapterExtraCfgs) do
            for difficult, chapterId in pairs(chapterMain.ChapterId) do
                local chapter = ChapterExtraDetailsCfgs[chapterId]
                for k, v in ipairs(chapter.StageId) do
                    if v == stageId then
                        return k, chapter.ChapterId, difficult
                    end
                end
            end
        end
    end

    function ExtraChapterManager.InitChapterData(checkNewUnlock)
        local oldChapterInfos = ChapterInfos
        ChapterInfos = {}
        CurrentClearData = {}  -- 重置，下次调用 GetChapterClearData 时按需重建
        local SortChapterExtraCfgs = {}
        for _, chapterMain in pairs(ChapterExtraCfgs) do
            table.insert(SortChapterExtraCfgs, chapterMain)
        end
        table.sort(SortChapterExtraCfgs, SortById)
        for _, chapterMain in pairs(SortChapterExtraCfgs) do
            for difficult, chapterId in pairs(chapterMain.ChapterId) do
                local chapter = ChapterExtraDetailsCfgs[chapterId]
                ChapterInfos[chapterId] = InitChapterInfo(chapterMain, chapter)
            end
        end
        if checkNewUnlock then
            for k, v in pairs(ChapterInfos) do
                local info = ExtraChapterManager.GetChapterInfo(k)
                if info and info.Unlock and oldChapterInfos[k] and oldChapterInfos[k].Unlock == false then
                    XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_NEW_EXTRA_CHAPTER, k)
                end
            end
        end
    end

    function ExtraChapterManager.OnSyncStageData(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if stageInfo.Type ~= XDataCenter.FubenManager.StageType.ExtraChapter then return end
        LastPassStage[stageInfo.ChapterId] = stageId
    end

    function ExtraChapterManager.IsTreasureGet(treasureId)
        return PlayerTreasureData[treasureId]
    end

    function ExtraChapterManager.SyncTreasureStage(treasureId)
        PlayerTreasureData[treasureId] = true
    end

    function ExtraChapterManager.GetChapterExtraCfgs(difficult)
        local list = {} -- v1.30新入口，顺序只和order有关了，和限时标签无关

        for _, v in pairs(ChapterExtraCfgs) do
            local chapterId
            local chapterInfo

            chapterId = v.ChapterId[difficult]
            chapterInfo = ExtraChapterManager.GetChapterInfo(chapterId)

            if chapterInfo then
                table.insert(list, v)
            end
        end

        if next(list) then
            table.sort(list, orderIdSortFunc)
        end

        return list
    end
    -- 获取篇章星数
    function ExtraChapterManager.GetChapterStars(chapterId)
        local info = ExtraChapterManager.GetChapterInfo(chapterId)
        return info and info.Stars or 0, info and info.TotalStars or 0
    end

    function ExtraChapterManager.GetChapterList(difficult)
        local list = {}
        for _, v in pairs(ChapterExtraCfgs) do
            list[v.OrderId] = v.ChapterId[difficult]
        end
        return list
    end

    function ExtraChapterManager.GetChapterCfg(chapterId)
        return ChapterExtraCfgs[chapterId]
    end

    function ExtraChapterManager.GetChapterInfo(chapterId)
        local info = ChapterInfos[chapterId]
        if info and info.Unlock == nil then
            local chapter = ChapterExtraDetailsCfgs[chapterId]
            local chapterMainCfg = ChapterExtraCfgs[info.ChapterMainId]
            RefreshChapterInfo(info, chapterMainCfg, chapter)
        end
        return info
    end
    
    function ExtraChapterManager.GetChapterInfoPassed(chapterId)
        local chapterInfo = ExtraChapterManager.GetChapterInfo(chapterId)

        if chapterInfo then
            return chapterInfo.Passed
        end

        return true
    end

    function ExtraChapterManager.GetChapterByChapterDetailsId(chapterId)
        return ChapterInfos[chapterId].ChapterMainId
    end

    function ExtraChapterManager.GetChapterDetailsCfg(chapterId)
        return ChapterExtraDetailsCfgs[chapterId]
    end

    function ExtraChapterManager.GetChapterDetailsCfgByChapterIdAndDifficult(chapterId, difficult)
        local cfg = ExtraChapterManager.GetChapterCfg(chapterId)
        if not cfg then return nil end
        return ExtraChapterManager.GetChapterDetailsCfg(cfg.ChapterId[difficult])
    end

    function ExtraChapterManager.GetChapterDetailsStageTitle(chapterId)
        if chapterId == nil then return end
        local cfg = ExtraChapterManager.GetChapterDetailsCfg(chapterId)
        return cfg.StageTitle
    end

    function ExtraChapterManager.CheckChapterNew(chapterId)
        local chapterInfo = ExtraChapterManager.GetChapterInfo(chapterId)
        return chapterInfo.Unlock and not chapterInfo.Passed
    end

    function ExtraChapterManager.GetLastPassStage(chapterId)
        return LastPassStage[chapterId]
    end

    function ExtraChapterManager.GetStageList(chapterId)
        return ChapterExtraDetailsCfgs[chapterId].StageId
    end

    function ExtraChapterManager.GetAutoChangeBgDatumLinePrecent(chapterId)
        return ChapterExtraDetailsCfgs[chapterId].DatumLinePrecent or 0
    end

    function ExtraChapterManager.GetAutoChangeBgStageIndex(chapterId)
        return ChapterExtraDetailsCfgs[chapterId].MoveStageIndex
    end

    function ExtraChapterManager.GetTreasureCfg(treasureId)
        if StarTreasureCfgs[treasureId] then
            return StarTreasureCfgs[treasureId]
        end
    end

    ---检测章节内是否有收集进度奖励
    function ExtraChapterManager.CheckTreasureReward(chapterId)
        local chapterInfo = ExtraChapterManager.GetChapterInfo(chapterId)
        if chapterInfo and not chapterInfo.Unlock then
            return false
        end

        local chapter = ExtraChapterManager.GetChapterDetailsCfg(chapterId)
        if not chapter then return false end

        local hasReward = false
        local targetList = chapter.TreasureId
        if not targetList then return false end
        for _, var in ipairs(targetList) do
            local treasureCfg = ExtraChapterManager.GetTreasureCfg(var)
            if treasureCfg then
                local requireStars = treasureCfg.RequireStar
                local starCount = 0
                local stageList = ExtraChapterManager.GetStageList(chapterId)

                for i = 1, #stageList do
                    local stage = XDataCenter.FubenManager.GetStageCfg(stageList[i])
                    local stageInfo = XDataCenter.FubenManager.GetStageInfo(stage.StageId)
                    starCount = starCount + stageInfo.Stars
                end

                if requireStars > 0 and requireStars <= starCount then
                    local isGet = ExtraChapterManager.IsTreasureGet(treasureCfg.TreasureId)
                    if not isGet then
                        hasReward = true
                        break
                    end
                end
            end
        end

        return hasReward
    end

    function ExtraChapterManager.GetProgressByChapterId(chapterId)
        local chapterCfg = ExtraChapterManager.GetChapterDetailsCfg(chapterId)
        local totalStageNum = 0
        local passStageNum = 0
        if chapterCfg and chapterCfg.StageId then
            totalStageNum = totalStageNum + #chapterCfg.StageId
            for _, stageId in pairs(chapterCfg.StageId) do
                local isPass = XDataCenter.FubenManager.CheckStageIsPass(stageId)
                if isPass then
                    passStageNum = passStageNum + 1
                end
            end
        end
        
        if totalStageNum == 0 then
            return 0
        end
        return math.ceil(100 * passStageNum / totalStageNum)
    end

    function ExtraChapterManager.GetCurrentAndMaxProgressByChapterId(chapterId)
        local chapterCfg = ExtraChapterManager.GetChapterDetailsCfg(chapterId)
        local totalStageNum = 0
        local passStageNum = 0
        if chapterCfg and chapterCfg.StageId then
            totalStageNum = totalStageNum + #chapterCfg.StageId
            for _, stageId in pairs(chapterCfg.StageId) do
                local isPass = XDataCenter.FubenManager.CheckStageIsPass(stageId)
                if isPass then
                    passStageNum = passStageNum + 1
                end
            end
        end
        if totalStageNum == 0 then
            return 0, 0
        end
        return passStageNum, totalStageNum
    end

    function ExtraChapterManager.GetChapterInfoForOrderId(difficult, orderId)
        for _, v in pairs(ChapterExtraCfgs) do
            if v.OrderId == orderId then
                local chapterId = v.ChapterId[difficult]
                return ExtraChapterManager.GetChapterInfo(chapterId)
            end
        end
    end

    function ExtraChapterManager.GetChapterIdByChapterExtraId(chapterExtraId, difficult)
        if difficult == DifficultType.Normal then
            return ChapterExtraCfgs[chapterExtraId].ChapterId[1]
        elseif difficult == DifficultType.Hard then
            return ChapterExtraCfgs[chapterExtraId].ChapterId[2]
        end
        local tempStr = "ExtraChapterManager.GetChapterIdByChapterExtraId函数参数difficult应该是，"
        XLog.Error(tempStr .. "config表：Share/Config/Config.tab, 中字段FubenDifficultNormal、FubenDifficultHard对应的值中的一个")
    end
    
    --- 获取外篇旧闻主章节通关数目
    function ExtraChapterManager.GetMainChapterPassedCount()
        local count = 0

        for i, v in pairs(ChapterExtraCfgs) do
            if ExtraChapterManager.CheckMainChapterDifficutIsAllPass(v.Id, DifficultType.Normal) then
                count = count + 1
            end
        end
        
        return count
    end
    
    --- 判断主章节指定难度关卡是否通关
    function ExtraChapterManager.CheckMainChapterDifficutIsAllPass(mainId, difficult)
        local mainChapterCfg = ChapterExtraCfgs[mainId]

        if mainChapterCfg then
            if difficult then
                local chapterId = mainChapterCfg.ChapterId[difficult]

                if XTool.IsNumberValidEx(chapterId) then
                    return ExtraChapterManager.GetChapterInfoPassed(chapterId)
                else
                    XLog.Error('ExtraChapterManager.CheckMainChapterDifficutIsPass 指定难度关卡不存在, mainId:' .. tostring(mainId) .. 'difficult: ' .. tostring(difficult))
                end
            else
                for i, v in ipairs(mainChapterCfg.ChapterId) do
                    if not ExtraChapterManager.GetChapterInfoPassed(v) then
                        return false
                    end
                end
                
                return true
            end
        end
        
        XLog.Error('外篇旧闻指定主章节不存在, mainId: ' .. tostring(mainId))
        return false
    end

    function ExtraChapterManager.GetCurDiffcult()
        return ExtraChapterManager.CurDifficult or DifficultType.Normal
    end

    function ExtraChapterManager.SetCurDifficult(difficult)
        ExtraChapterManager.CurDifficult = difficult
        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_CHANGE_EXTRA_CHAPTER_DIFFICULT, difficult)
    end

    --检测所有章节进度是否有奖励
    function ExtraChapterManager.CheckAllChapterReward()
        for _, v in pairs(ChapterExtraCfgs) do
            for _, chapterId in pairs(v.ChapterId) do
                if ExtraChapterManager.CheckTreasureReward(chapterId) then
                    return true
                end
            end
        end
        return false
    end
    --获取通关进度
    function ExtraChapterManager.GetChapterClearData()
        if not CurrentClearData.ChapterTotalNum then
            local SortChapterExtraCfgs = {}
            for _, chapterMain in pairs(ChapterExtraCfgs) do
                table.insert(SortChapterExtraCfgs, chapterMain)
            end
            table.sort(SortChapterExtraCfgs, SortById)
            CurrentClearData.ChapterTotalNum = 0
            CurrentClearData.AllChapterClear = true
            for _, chapterMain in pairs(SortChapterExtraCfgs) do
                for difficult, chapterId in pairs(chapterMain.ChapterId) do
                    local chapter = ChapterExtraDetailsCfgs[chapterId]
                    -- 直接查服务器阶段数据，避免触发 GetChapterInfo 懒加载
                    if chapter and #chapter.StageId > 0 and difficult == DifficultType.Normal then
                        CurrentClearData.ChapterTotalNum = CurrentClearData.ChapterTotalNum + 1
                        -- 第一关有服务器数据即视为章节已解锁
                        local unlock = XMVCA.XFuben:GetStageData(chapter.StageId[1]) ~= nil
                        if CurrentClearData.AllChapterClear and unlock then
                            local allPassed = true
                            local activeStage = nil
                            local lastStageOrder = nil
                            local passStageNum = 0
                            for _, stageId in ipairs(chapter.StageId) do
                                local stageData = XMVCA.XFuben:GetStageData(stageId)
                                if stageData then
                                    -- 有服务器数据视为已解锁，取最后一个已解锁关卡
                                    activeStage = stageId
                                    lastStageOrder = XDataCenter.FubenManager.GetStageOrderId(stageId)
                                    if stageData.Passed then
                                        passStageNum = passStageNum + 1
                                    else
                                        allPassed = false
                                    end
                                else
                                    allPassed = false
                                end
                            end
                            CurrentClearData.ChapterId = chapterMain.Id
                            CurrentClearData.StageTitle = chapter.StageTitle
                            CurrentClearData.StageId = activeStage
                            CurrentClearData.LastStageOrder = lastStageOrder
                            CurrentClearData.IsClear = allPassed
                            CurrentClearData.PassStageNum = passStageNum
                            if not allPassed then CurrentClearData.AllChapterClear = false end
                        elseif not unlock then
                            -- 未解锁章节视为未通关
                            CurrentClearData.AllChapterClear = false
                        end
                    end
                end
            end
        end
        return CurrentClearData
    end
    --跳转到外章Banner页面
    function ExtraChapterManager.JumpToExtraBanner()
        -- XLuaUiManager.Open("UiFuben", XDataCenter.FubenManager.StageType.Mainline, nil, 4)
        XLuaUiManager.Open("UiNewFuben", XEnumConst.FuBen.ChapterType.ExtralChapter)
    end
    --跳转到外章章节关卡
    function ExtraChapterManager.JumpToExtraStage(chapterId, stageId)
        local chapter = ExtraChapterManager.GetChapterDetailsCfg(chapterId)
        if chapter then
            local checkResult, checkDesription = ExtraChapterManager.CheckCanGoTo(chapterId, stageId)
            if not checkResult then
                XUiManager.TipMsg(checkDesription)
                return
            end
            if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.ExtralChapter, chapterId) then
                return
            end
            XLuaUiManager.Open("UiFubenMainLineChapterFw", chapter, stageId, false)
        else
            ExtraChapterManager.JumpToExtraBanner()
            XLog.Error("跳转到特定外章章节关卡失败，没有在chapterDetails表中找到章节信息。 chpaterId : " .. tostring(chapterId))
        end
    end
    -- 检查番外章节是否可以跳转
    function ExtraChapterManager.CheckCanGoTo(chapterId, stageId, specialTip)
        specialTip = specialTip or XUiHelper.GetText("ExtraChapterGetChapterDataFail")

        if not chapterId then return false, specialTip end
        local chapterInfo = ExtraChapterManager.GetChapterInfo(chapterId)
        if not chapterInfo then return false, specialTip end
        if chapterInfo.IsActivity then
            if not ExtraChapterManager.IsExtraActivityOpen() then
                return false, CS.XTextManager.GetText("FubenExtraNotOpen")
            end
            local checkResult, checkDesription = ExtraChapterManager.CheckActivityCondition(chapterId)
            if not checkResult then
                return false, checkDesription
            end
        end
        if not chapterInfo.Unlock then return false, XDataCenter.FubenManager.GetFubenOpenTips(chapterInfo.FirstStage) end
        if stageId then
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            if not stageInfo then return false, XUiHelper.GetText("ExtraChapterGetStageDataFail") end
            if not stageInfo.Unlock then return false, XDataCenter.FubenManager.GetFubenOpenTips(stageId) end
        end
        return true
    end
    ------------------------------------------------------------------抢先体验部分
    function ExtraChapterManager.NotifyExtraActivity(data)
        local activityId = data.ActivityId or 0
        if not XTool.IsNumberValid(activityId) then
            ActivityEndTime = 0
            ActivityChallengeBeginTime = 0
            ExtraChapterManager.ExtraActivityEnd()
            return
        end
        
        local extraChapterActivityCfg = XFubenExtraChapterConfigs.GetExtraChapterActivityCfg(activityId)
        local chapterIds = extraChapterActivityCfg.ChapterId
        local chapterTimeId = extraChapterActivityCfg.ChapterTimeId
        local hideChapterTimeId = extraChapterActivityCfg.HideChapterTimeId
        
        local now = XTime.GetServerNowTimestamp()
        ActivityEndTime = XFunctionManager.GetEndTimeByTimeId(chapterTimeId) or 0
        ActivityChallengeBeginTime = XFunctionManager.GetStartTimeByTimeId(hideChapterTimeId) or 0
        if now < ActivityEndTime then
            --清理上次活动状态
            if next(ActivityChapters) then
                ExtraChapterManager.ExtraActivityEnd()
            end

            ActivityChapters = {
                MainLineIds = chapterIds,
            }

            ExtraChapterManager.ExtraActivityStart()
        else
            --活动关闭
            ExtraChapterManager.ExtraActivityEnd()
        end
    end

    function ExtraChapterManager.IsExtraActivityOpen()
        return ActivityEndTime and ActivityEndTime > XTime.GetServerNowTimestamp()
    end

    function ExtraChapterManager.IsExtraActivityChallengeBegin()
        return ActivityChallengeBeginTime and XTime.GetServerNowTimestamp() >= ActivityChallengeBeginTime
    end

    function ExtraChapterManager.ExtraActivityStart()
        if not ExtraChapterManager.IsExtraActivityOpen() then return end
        --定时器
        if ActivityTimer then
            XScheduleManager.UnSchedule(ActivityTimer)
            ActivityTimer = nil
        end
        local time = XTime.GetServerNowTimestamp()
        local challengeWaitUnlock = true
        ActivityTimer = XScheduleManager.ScheduleForever(function()
            time = time + 1
            if time >= ActivityChallengeBeginTime then
                if challengeWaitUnlock then
                    ExtraChapterManager.UnlockActivityChapters()
                    challengeWaitUnlock = nil
                end
            end
            if time >= ActivityEndTime then
                ExtraChapterManager.ExtraActivityEnd()
            end
        end, XScheduleManager.SECOND, 0)
        ExtraChapterManager.UnlockActivityChapters()
    end

    function ExtraChapterManager.UnlockActivityChapters()
        if not next(ActivityChapters) then return end
        for _, chapterId in pairs(ActivityChapters.MainLineIds) do
            if chapterId ~= 0 then
                ExtraChapterManager.UnlockChapterViaActivity(chapterId)
            end
        end
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_EXTRACHAPTER_STATE_CHANGE)
    end

    function ExtraChapterManager.ExtraActivityEnd()
        if ActivityTimer then
            XScheduleManager.UnSchedule(ActivityTimer)
            ActivityTimer = nil
        end
        --活动结束处理
        local chapterIds = ActivityChapters.MainLineIds
        if chapterIds then
            for _, chapterId in pairs(chapterIds) do
                if chapterId ~= 0 then
                    local chapterInfo = ExtraChapterManager.GetChapterInfo(chapterId)
                    chapterInfo.IsActivity = false
                    ExtraChapterManager.CheckStageStatus(chapterId, false)
                end
            end
        end

        --XDataCenter.FubenManager.InitData(true)
        ExtraChapterManager.InitStageInfo(true)

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_ACTIVITY_EXTRACHAPTER_STATE_CHANGE)

        XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA)
    end

    function ExtraChapterManager.GetActivityEndTime()
        return ActivityEndTime
    end

    function ExtraChapterManager.CheckDiffHasAcitivity(chapter)
        if not next(ActivityChapters) then return false end
        for _, chapterId in pairs(ActivityChapters.MainLineIds) do
            if chapterId == chapter.ChapterId then
                return true
            end
        end
        return false
    end

    function ExtraChapterManager.UnlockChapterViaActivity(chapterId)
        --开启章节，标识活动状态
        local chapterInfo = ExtraChapterManager.GetChapterInfo(chapterId)
        if not chapterInfo then return end
        chapterInfo.IsActivity = true

        if not ExtraChapterManager.CheckActivityCondition(chapterId) then
            chapterInfo.Unlock = false
            chapterInfo.IsOpen = false
            return
        end

        chapterInfo.Unlock = true
        chapterInfo.IsOpen = true

        ExtraChapterManager.CheckStageStatus(chapterId, true)
    end
    
    function ExtraChapterManager.CheckStageStatus(chapterId, isFirstSpecial)
        local chapterCfg = ExtraChapterManager.GetChapterDetailsCfg(chapterId)
        
        for index, stageId in ipairs(chapterCfg.StageId) do
            local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
            stageInfo.Unlock = true
            stageInfo.IsOpen = true

            local isSpecial = true
            if isFirstSpecial then
                isSpecial = index ~= 1 -- 章节第一关无视前置条件
            end

            if isSpecial then
                local stageCfg = XDataCenter.FubenManager.GetStageCfg(stageId)
                for _, preStageId in pairs(stageCfg.PreStageId or {}) do
                    if preStageId > 0 then
                        local stageData = XDataCenter.FubenManager.GetStageData(preStageId)
                        if not stageData or not stageData.Passed then
                            stageInfo.Unlock = false
                            stageInfo.IsOpen = false
                            break
                        end
                    end
                end
            end
        end
    end

    function ExtraChapterManager.CheckActivityCondition(chapterId)
        local chapterCfg = ExtraChapterManager.GetChapterDetailsCfg(chapterId)
        if not chapterCfg then return false, CS.XTextManager.GetText("ExtraChapterFindNoChapterData") end
        if chapterCfg.Difficult == DifficultType.Hard and
        not ExtraChapterManager.IsExtraActivityChallengeBegin() then
            local time = XTime.GetServerNowTimestamp()
            local timeStr = XUiHelper.GetTime(ActivityChallengeBeginTime - time, XUiHelper.TimeFormatType.ACTIVITY)
            local msg = CS.XTextManager.GetText("FuBenExtraChapterActivityNotReachChallengeTime", timeStr)
            return false, msg
        elseif chapterCfg.Difficult == DifficultType.Hard and
        not XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.FubenDifficulty) then
            return false, XFunctionManager.GetFunctionOpenCondition(XFunctionManager.FunctionName.FubenDifficulty)
        end

        local conditionId = chapterCfg.ActivityCondition
        if conditionId and conditionId ~= 0 then
            return XConditionManager.CheckCondition(conditionId)
        end

        return true, ""
    end

    function ExtraChapterManager.OnActivityEnd()
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return
        end
        XUiManager.TipText("ActivityExtraChapterEnd")
        XLuaUiManager.RunMain()
    end

    function ExtraChapterManager.IfChapterIsExtraChapter(chapterId)
        return ChapterExtraDetailsCfgs[chapterId] ~= nil
    end
    ------------------------------------------------------------------ 活动番外副本抢先体验 end -------------------------------------------------------
    ------------------------------------------------------------------ 活动番外副本探索玩法 begin -------------------------------------------------------
    function ExtraChapterManager.InitExploreGroup()
        if ExploreGroupInfos then
            return
        end

        ExploreGroupInfos = {}
        local exploreGroupList = XFubenExtraChapterConfigs.GetExploreGroupCfg()
        for _, exploreGroup in pairs(exploreGroupList) do
            if not ExploreGroupInfos[exploreGroup.GroupId] then
                ExploreGroupInfos[exploreGroup.GroupId] = {}
            end
            ExploreGroupInfos[exploreGroup.GroupId][exploreGroup.StageIndex] = exploreGroup
        end
    end

    function ExtraChapterManager.InitExploreItem()
        if ExploreItemInfos then
            return
        end

        ExploreItemInfos = {}
        local exploreItemList = XFubenExtraChapterConfigs.GetExploreItemCfg()
        for _, exploreItem in pairs(exploreItemList) do
            if not ExploreItemInfos[exploreItem.MainChapterId] then
                ExploreItemInfos[exploreItem.MainChapterId] = {}
            end
            table.insert(ExploreItemInfos[exploreItem.MainChapterId], exploreItem)
        end
    end

    function ExtraChapterManager.GetExploreGroupInfoByGroupId(id)
        ExtraChapterManager.InitExploreGroup()
        if not ExploreGroupInfos[id] then
            XLog.ErrorTableDataNotFound("ExtraChapterManager.GetExploreGroupInfoByGroupId",
            "ExploreGroupInfos", " Client/Fuben/ExtraChapter/ExtraExploreGroup.tab", "id", tostring(id))
            return {}
        end
        return ExploreGroupInfos[id]
    end

    function ExtraChapterManager.GetChapterOrderIdByStageId(stageId)
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        local chapter = ChapterExtraDetailsCfgs[stageInfo.ChapterId]
        return chapter.OrderId
    end

    function ExtraChapterManager.CheckChapterTypeIsExplore(chapter)
        return chapter.ExploreGroupId and chapter.ExploreGroupId > 0
    end

    function ExtraChapterManager.CheckHaveNewExploreItemByChapterId(chapterId)
        ExtraChapterManager.InitExploreItem()
        if not ExploreItemInfos[chapterId] then
            return false
        end
        for _, info in pairs(ExploreItemInfos[chapterId]) do
            if ExtraChapterManager.CheckHaveNewExploreItemByItemId(info.Id) then
                return true
            end
        end
        return false
    end

    function ExtraChapterManager.CheckHaveNewExploreItemByItemId(itemId)
        local data = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ExtraChapterExploreItem", itemId))
        return data == ExItemRedPointState.On
    end

    function ExtraChapterManager.SetChapterEventState(chapterEventDatas)
        for _, data in pairs(chapterEventDatas) do
            local eventIds = data.EventIds or {}
            for _, id in pairs(eventIds) do
                ExploreEventStateList[id] = true
            end
        end
    end

    function ExtraChapterManager.AddChapterEventState(chapterEventData)
        local eventIds = chapterEventData and chapterEventData.EventIds or {}
        for _, id in pairs(eventIds) do
            ExploreEventStateList[id] = true
        end
    end

    function ExtraChapterManager.GetChapterExploreItemList(chapterId)
        ExtraChapterManager.InitExploreItem()
        local list = {}
        if ExploreItemInfos[chapterId] then
            for _, info in pairs(ExploreItemInfos[chapterId]) do
                if ExploreEventStateList[info.Id] then
                    table.insert(list, info)
                end
            end
        end
        return list
    end

    function ExtraChapterManager.GetChapterExploreItemMaxCount(chapterId)
        ExtraChapterManager.InitExploreItem()
        return ExploreItemInfos[chapterId] and #ExploreItemInfos[chapterId] or 0
    end

    function ExtraChapterManager.SaveNewExploreItemRedPoint(chapterEventData)
        local eventIds = chapterEventData and chapterEventData.EventIds or {}
        local exploreItemList = XFubenMainLineConfigs.GetExploreItemCfg()
        for _, id in pairs(eventIds) do
            if exploreItemList[id] then
                if not XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ExtraChapterExploreItem", id)) then
                    XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ExtraChapterExploreItem", id), ExItemRedPointState.On)
                end
            else
                XLog.ErrorTableDataNotFound("ExtraChapterManager.SaveNewExploreItemRedPoint",
                "exploreItem", "Client/Fuben/ExtraChapter/ExtraExploreItem.tab", "id", tostring(id))
            end
        end
    end

    function ExtraChapterManager.MarkNewExploreItemRedPointByItemId(itemId)
        local data = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ExtraChapterExploreItem", itemId))
        if data and data == ExItemRedPointState.On then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ExtraChapterExploreItem", itemId), ExItemRedPointState.Off)
            XEventManager.DispatchEvent(XEventId.EVENT_MAINLINE_EXPLORE_ITEMBOX_CLOSE)
        end
    end

    function ExtraChapterManager.CheckHaveNewJumpStageButtonByStageId(stageId)
        local data = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ExtraChapterJumpStageButton", stageId))
        if data then
            return data == ExItemRedPointState.On
        end
        return false
    end

    function ExtraChapterManager.SaveNewJumpStageButtonEffect(stageId)
        if not XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ExtraChapterJumpStageButton", stageId)) then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ExtraChapterJumpStageButton", stageId), ExItemRedPointState.On)
        end
    end

    function ExtraChapterManager.MarkNewJumpStageButtonEffectByStageId(stageId)
        local data = XSaveTool.GetData(string.format("%d%s%d", XPlayer.Id, "ExtraChapterJumpStageButton", stageId))
        if data and data == ExItemRedPointState.On then
            XSaveTool.SaveData(string.format("%d%s%d", XPlayer.Id, "ExtraChapterJumpStageButton", stageId), ExItemRedPointState.Off)
        end
    end
    -- 胜利 & 奖励界面
    function ExtraChapterManager.ShowReward(winData)
        XLuaUiManager.Open("UiSettleWinMainLine", winData)
    end
    ------------------------------------------------------------------ 活动主线副本探索玩法 end -------------------------------------------------------
    --新增章节开启条件
    function ExtraChapterManager.CheckOpenCondition(chapterId)
        local chapterCfg = ExtraChapterManager.GetChapterDetailsCfg(chapterId)
        if not chapterCfg then return false, CS.XTextManager.GetText("ExtraChapterFindNoChapterData") end
        local conditionId = chapterCfg.OpenCondition
        if conditionId and conditionId ~= 0 then
            return XConditionManager.CheckCondition(conditionId)
        end

        return true, ""
    end

    -- 领取宝箱奖励
    function ExtraChapterManager.ReceiveTreasureReward(cb, treasureId)
        local req = { TreasureId = treasureId }
        XNetwork.Call("ChapterExtraTreasureRewardRequest", req, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            ExtraChapterManager.SyncTreasureStage(treasureId)
            if cb then
                cb(res.RewardGoods)
            end
            XEventManager.DispatchEvent(XEventId.EVENT_FUBEN_EXTRACHAPTER_REWARD)
        end)
    end
    ExtraChapterManager.Init()
    return ExtraChapterManager
end

XRpc.NotifyChapterExtraActivity = function(data)
    XDataCenter.ExtraChapterManager.NotifyExtraActivity(data)
end

XRpc.NotifyChapterExtraEventData = function(data)
    XDataCenter.ExtraChapterManager.AddChapterEventState(data.ChapterEventData)
    XEventManager.DispatchEvent(XEventId.EVENT_EXTRACHAPTER_EXPLORE_ITEM_GET)
end