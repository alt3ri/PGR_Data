local tonumber = tonumber
local tostring = tostring
local mathFloor = math.floor
local tableInsert = table.insert
local tableRemove = table.remove
local next = next
local tableRemove = table.remove
local CSMovieXMovieManagerInstance = CS.Movie.XMovieManager.Instance

local UI_MOVIE = "UiMovie"
local UI_MOVIE_2D = "UiMovie2D"   --不带3D场景的UI
local RESOLUTION_RATIO = CS.XResolutionManager.OriginWidth / CS.XResolutionManager.OriginHeight / CS.XUiManager.DefaultScreenRatio
local TIMELINE_SECONDS_TRANS = 1 / 60
local DisableFunction = false     --功能屏蔽标记（调试模式时使用）
local CurrentAction = nil

--可以通过上一页返回到的节点
local MovieBackFilter = {
    [301] = true, --普通对话
}

XMovieManagerCreator = function()
    local AllMovieActions = {}
    local ActionIdToIndexDics = {}

    local CurPlayingMovieId
    local CurPlayingActionIndex
    local IsAutoPlay
    local IsLongPressAutoPlay
    local WaitToPlayList = {}
    
    ---@type XMovieActionBase[]
    local PassedActions = {}        -- 从剧情中间开始播时，前面播过的Action
    local PassedOptionDic = {}      -- 从剧情中间开始播时，前面选项的选择
    local DelaySelectionDic = {}
    local ReviewDialogList = {}
    local EndCallBack
    local IsPlaying
    local IsYield
    local IsPause = false
    local YieldCallBack
    local MovieBackStack = XStack.New()
    local Speed                     -- 自动播放的倍速
    local StageId                   -- 剧情对应的关卡Id
    local SelectionDataDic = {}     -- 当前剧情选项记录

    local function InitMovieActions(movieId)
        local movieActions = {}
        local actionIdToIndexDic = {}

        local findEnd = false
        local movieCfg = XMovieConfigs.GetMovieCfg(movieId)
        for index, actionData in ipairs(movieCfg) do
            local actionClass = XMVCA.XMovie.EnumConst:GetActionClass(actionData.Type)
            if not actionClass then
                XLog.Error("XMovieManager.InitMovieActions 配置节点类型错误，找不到对应的节点，Type: " .. actionData.Type)
                return
            end

            tableInsert(movieActions, actionClass.New(actionData))
            actionIdToIndexDic[actionData.ActionId] = index

            if actionData.IsEnd ~= 0 then
                findEnd = true
            end
        end

        if not findEnd then
            XLog.Error("XMovieManager.InitMovieActions error:没有配置结束标记IsEnd, movieId: ", movieId)
            return
        end

        AllMovieActions[movieId] = movieActions
        ActionIdToIndexDics[movieId] = actionIdToIndexDic

        return movieActions
    end

    local function GetMovieActions(movieId)
        if not AllMovieActions[movieId] then
            InitMovieActions(movieId)
        end

        if not AllMovieActions[movieId] then
            XLog.Error("XMovieManager GetMovieActions error:actions not exsit, movieId is: ", movieId)
            return
        end

        return AllMovieActions[movieId]
    end

    local function GetActionIndexById(movieId, actionId)
        local dic = ActionIdToIndexDics[movieId]
        if not dic then
            XLog.Error("XMovieManager GetActionIndexById error:dic not exsit, movieId is: " .. movieId .. ", actionId is: " .. actionId)
            return
        end

        local index = dic[actionId]
        if not index then
            XLog.Error("XMovieManager GetActionIndexById error:index not exsit, actionId is: " .. actionId)
        end
        return index
    end
    
    local function ClearAllMovieActions()
        for movieId, movieActions in pairs(AllMovieActions) do
            for _, action in pairs(movieActions) do
                action:Release()
            end
        end
        AllMovieActions = {}
        ActionIdToIndexDics = {}
    end

    -- 当前ActionId是否可以到达目标ActionId
    ---@param curActionId number 当前ActionId
    ---@param targetActionId number 目标ActionId
    ---@param searchActionIdDic table 记录查找中的ActionId，避免跳转ActionId导致死循环
    local function IsCanReachAction(curActionId, targetActionId, searchActionIdDic)
        if curActionId == targetActionId then
            return true
        end
        
        searchActionIdDic = searchActionIdDic or {}
        if searchActionIdDic[curActionId] then
            -- 当前选项已查找过，跳过
            return false
        end
        searchActionIdDic[curActionId] = true

        local curIndex = GetActionIndexById(CurPlayingMovieId, curActionId)
        ---@type XMovieActionBase
        local curAction = WaitToPlayList[curIndex]
        if curAction:IsEnding() then return false end
        
        -- 选项能否到达
        if curAction:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SELECTION then
            local delaySelectKey = curAction:GetDelaySelectKey()
            if XTool.IsNumberValidEx(delaySelectKey) then
                local nextIndex = GetActionIndexById(CurPlayingMovieId, curActionId) + 1
                local nextActionId = WaitToPlayList[nextIndex]:GetActionId()
                if IsCanReachAction(nextActionId, targetActionId, searchActionIdDic) then
                    return true
                end
            else
                local selectCnt = curAction:GetSelectionCnt()
                for i = 1, selectCnt do
                    local selectionActionId = curAction:GetSelectionActionId(i)
                    if IsCanReachAction(selectionActionId, targetActionId, searchActionIdDic) then
                        return true
                    end
                end
            end
            return false
        end
        
        local nextActionId = curAction:GetNextActionId()
        if XTool.IsNumberValidEx(nextActionId) then
            -- 有配置NextActionId
            return IsCanReachAction(nextActionId, targetActionId, searchActionIdDic)
        else
            -- 默认index+1
            ---@type XMovieActionBase
            local nextAction = WaitToPlayList[curIndex + 1]
            if nextAction then
                return IsCanReachAction(nextAction:GetActionId(), targetActionId, searchActionIdDic)
            else
                return false
            end
        end
    end

    -- 获取选择分支对话的下一个NextId
    ---@param action XMovieActionSelection 当前action
    ---@param animActionId number 需要往下跑能到目标ActionId
    ---@param optionDic table 分支对话 选择了哪个选项的数据 actionId:index
    local function GetSelectionNextActionId(action, animActionId, optionDic)
        local actionId = action:GetActionId()
        local selIndex = optionDic[actionId]
        local nextActionId = 0
        -- 有选项数据，使用选项数据
        if XTool.IsNumberValidEx(selIndex) then
            nextActionId = action:GetSelectionActionId(selIndex)
        end

        -- 没有选项数据/选项数据有问题
        if not XTool.IsNumberValidEx(nextActionId) then
            local selectCnt = action:GetSelectionCnt()
            for i = 1, selectCnt do
                nextActionId = action:GetSelectionActionId(i)
                if IsCanReachAction(nextActionId, animActionId) then
                    optionDic[action:GetActionId()] = i
                    break
                end
            end
        end
        return nextActionId
    end

    -- 从startActionId开始播剧情，获取前面播放过的Action列表
    local function GetPassedActions(startActionId, optionDic)
        local delaySelectionDic = {} -- 延迟做出选择的选项
        local result = {}
        local isSuccess = false
        local index = 1
        local allActionCnt = #WaitToPlayList
        while index <= allActionCnt do
            ---@type XMovieActionBase
            local action = WaitToPlayList[index]
            local actionId = action:GetActionId()
            if actionId == startActionId then
                isSuccess = true
                break
            else
                table.insert(result, action)
            end
            
            -- 跳转ActionId处理
            local nextActionId = 0
            if action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SELECTION then
                local delaySelectKey = action:GetDelaySelectKey()
                if XTool.IsNumberValidEx(delaySelectKey) then
                    delaySelectionDic[delaySelectKey] = action:GetActionId()
                else
                    nextActionId = GetSelectionNextActionId(action, startActionId, optionDic)
                end
            elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.SELECTION_DELAY_SKIP then
                local delaySelectKey = action:GetDelaySelectKey()
                local selectionActionId = delaySelectionDic[delaySelectKey]
                local selectionActionIndex = GetActionIndexById(CurPlayingMovieId, selectionActionId)
                local selectionAction = WaitToPlayList[selectionActionIndex]
                nextActionId = GetSelectionNextActionId(selectionAction, startActionId, optionDic)
            elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.AUTO_SKIP then
                nextActionId = action:GetSelectedActionId()
            end
            
            if not XTool.IsNumberValidEx(nextActionId) then
                nextActionId = action:GetNextActionId()
            end
            if XTool.IsNumberValidEx(nextActionId) then
                index = GetActionIndexById(CurPlayingMovieId, nextActionId)
            else
                index = index + 1
            end
        end

        -- 当配置了DelaySelectKey，又未跑到Action303时，即选择哪个选项都能到达，返回默认值1
        for _, actionId in pairs(delaySelectionDic) do
            if not optionDic[actionId] then
                optionDic[actionId] = 1
            end
        end
        
        if isSuccess then
            return result, isSuccess
        else
            return {}, isSuccess
        end
    end

    local function ReleaseAll(isRelease)
        if (not CS.XFight.IsRunning) and isRelease then
            CsXUiManager.Instance:ReleaseAll(CsXUiType.Normal)
        end
    end

    local function IsUiShow()
        return XLuaUiManager.IsUiShow(UI_MOVIE) or XLuaUiManager.IsUiShow(UI_MOVIE_2D)
    end

    local function OnPlayBegin(movieId, hideSkipBtn, isRelease, startActionId, optionDic, stageId, is2D)
        CurPlayingMovieId = movieId
        CurPlayingActionIndex = 1
        WaitToPlayList = GetMovieActions(movieId)
        PassedActions = {}
        PassedOptionDic = {}
        ReviewDialogList = {}
        MovieBackStack:Clear()
        IsPlaying = true
        IsPause = false
        XDataCenter.MovieManager.SetStageId(stageId)
        SelectionDataDic = {} -- 选项的
        optionDic = optionDic or {}

        -- 从startActionId开始播
        if XTool.IsNumberValid(startActionId) then
            local isSuccess = false
            PassedActions, isSuccess = GetPassedActions(startActionId, optionDic)
            if isSuccess then
                PassedOptionDic = optionDic
                CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, startActionId)
            else
                XLog.Error(string.format("剧情%s无法定位到ActionId:%s，从头开始播放", movieId, startActionId))
            end
            
            -- 检查是否提前
            local isAdvance = false
            local advanceIndex, advanceActionId
            for i, action in ipairs(PassedActions) do
                if action:IsPassedActionRun(i) and action:IsAdvanceStartAction() then
                    isAdvance = true
                    advanceIndex = i
                    advanceActionId = action:GetActionId()
                    break
                end
            end
            if isAdvance then
                for i = #PassedActions, advanceIndex, -1 do
                    table.remove(PassedActions, i)
                end
                CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, advanceActionId)
                XLog.Debug(string.format("剧情提前到ActionIndex = %s开始播放", CurPlayingActionIndex))
            end
        end
        
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOVIE_BEGIN, movieId)
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BEGIN, movieId)

        if IsUiShow() then return end

        ReleaseAll(isRelease)

        local uiMovie = is2D and UI_MOVIE_2D or UI_MOVIE
        XLuaUiManager.Open(uiMovie, hideSkipBtn)
    end
    
    local function CheckClose()
        if XLuaUiManager.IsUiShow(UI_MOVIE) then
            XLuaUiManager.Close(UI_MOVIE)
        end

        if XLuaUiManager.IsUiShow(UI_MOVIE_2D) then
            XLuaUiManager.Close(UI_MOVIE_2D)
        end
    end

    local function OnPlayEnd(isLoginOut)
        if not CurPlayingMovieId then return end
        
        XDataCenter.MovieManager.RecordStorylineEnd(CurPlayingMovieId)
        
        if not CS.XFight.IsRunning and not isLoginOut then
            CsXUiManager.Instance:RevertAll()
        end

        CurPlayingMovieId = nil
        CurPlayingActionIndex = nil
        IsAutoPlay = nil
        ReviewDialogList = {}
        DelaySelectionDic = {}
        WaitToPlayList = {}
        IsPlaying = nil
        IsYield = nil
        IsPause = false
        YieldCallBack = nil
        MovieBackStack:Clear()

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOVIE_END)
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_END)

        --[[
        if CurrentAction then
            CurrentAction:OnDestroy()
        end
        ]]

        CheckClose()

        ClearAllMovieActions()
        XMovieConfigs.DeleteMovieCfgs()
    end

    --剧情UI完全关闭，所有节点清理行为结束
    local function AfterUiClosed()
        if EndCallBack then
            local endCb = EndCallBack --可能会嵌套播放，避免新剧情打开时回调被错误清掉
            EndCallBack = nil

            -- 剧情过程中强制下线
            if not XLoginManager.IsLogin() then
                return
            end

            endCb()
        end
    end

    local function DoAction(ignoreLock)
        if not CurPlayingActionIndex or not next(WaitToPlayList) then
            OnPlayEnd()
            return
        end

        if IsYield then
            return
        end

        if IsPause then
            return
        end
        ---@type XMovieActionBase
        local action = WaitToPlayList[CurPlayingActionIndex]

        if not ignoreLock and action:IsWaiting() then
            return
        end

        if action:Destroy() then
            if action:IsEnding() then
                OnPlayEnd()
                return
            end
            MovieBackStack:Push(CurPlayingActionIndex)
            local indexChanged

            local selectedActionId = action:GetSelectedActionId()
            if selectedActionId ~= 0 then
                CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, selectedActionId)
                indexChanged = true
            end

            local delaySelectedActionId = action:GetDelaySelectActionId()
            if delaySelectedActionId ~= 0 then
                CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, delaySelectedActionId)
                indexChanged = true
            end

            local resumeActionId = action:GetResumeActionId()
            if resumeActionId ~= 0 then
                CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, resumeActionId)
                indexChanged = true
            end

            if not indexChanged then
                local nextActionId = action:GetNextActionId()
                if nextActionId ~= 0 then
                    CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, nextActionId)
                    indexChanged = true
                end
            end

            if not indexChanged then
                CurPlayingActionIndex = CurPlayingActionIndex + 1
            end

            action = WaitToPlayList[CurPlayingActionIndex]
            CurrentAction = action
            action:OnReset()
            if not action then
                OnPlayEnd()
                return
            end
        end

        action:ChangeStatus()
    end

    ---@class XMovieManager
    local XMovieManager = {}

    function XMovieManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_MOVIE_BREAK_BLOCK, DoAction)
        XEventManager.AddEventListener(XEventId.EVENT_MOVIE_UI_CLOSED, AfterUiClosed)

        DisableFunction = XMovieManager.CheckFuncDisable()
    end

    local function PlayOldMovie(movieId, cb)
        if not CSMovieXMovieManagerInstance:CheckMovieExist(movieId) then return end
        CSMovieXMovieManagerInstance:PlayById(movieId, function()
            if cb then cb() end
        end)
    end

    local function PlayNewMovie(movieId, cb, yieldCb, hideSkipBtn, isRelease, startActionId, optionDic, stageId, is2D)
        EndCallBack = cb
        YieldCallBack = yieldCb
        OnPlayBegin(movieId, hideSkipBtn, isRelease, startActionId, optionDic, stageId, is2D)
    end
    
    --检查剧情存在
    function XMovieManager.CheckMovieExist(movieId)
        if XMovieConfigs.CheckMovieConfigExist(movieId) then
            return true
        end
        if CSMovieXMovieManagerInstance:CheckMovieExist(movieId) then
            return true
        end
        return false
    end

    -- 是否跳过剧情播放
    function XMovieManager.IsSkipMovie()
        return DisableFunction or XUiManager.IsHideFunc
    end

    ---@param startActionId number 开始播放的ActionId
    ---@param is2D bool 是否仅使用不带3D场景的UI界面
    function XMovieManager.PlayMovie(movieId, cb, yieldCb, hideSkipBtn, isRelease, startActionId, optionDic, stageId, is2D)
        if XMain.IsEditorDebug then
            XLog.Debug("开始播放剧情 MovieId = " .. tostring(movieId))
        end
        
        local fun = function ()
            if isRelease == nil then
                isRelease = true
            end
            if XMovieManager.IsSkipMovie() then
                XLog.Warning(string.format("已跳过剧情%s", movieId))
                if cb then cb() end
                return
            end
            XMovieManager.RecordStorylineStart(movieId)
            movieId = tostring(movieId)
            XMVCA.XMovie:RequestMovieOptions(movieId)
            if XMovieConfigs.CheckMovieConfigExist(movieId) then
                PlayNewMovie(movieId, cb, yieldCb, hideSkipBtn, isRelease, startActionId, optionDic, stageId, is2D)
            else
                PlayOldMovie(movieId, cb)
            end
        end

        -- 由于设计 目前这里只有纯剧情关才会走了，若战斗自带剧情关也只会在FubenAgency做检测
        if not stageId then
            stageId = XMVCA.XFuben:GetStageIdByBeginStoryId(movieId)
        end
        local isHasCheckStory = XMVCA.XSubPackage:GetHasResIdCheckStoryId(movieId)
        if XTool.IsNumberValid(stageId) and not isHasCheckStory then
            XMVCA.XSubPackage:CheckStageIdListResIdListDownloadComplete({stageId}, fun)
        else
            fun()
        end
    end

    function XMovieManager.StopMovie(isLoginOut)
        if not XMovieManager.IsPlayingMovie() then return end
        if not IsUiShow() then return end
        OnPlayEnd(isLoginOut)
    end
    
    function XMovieManager.IsExitPassedActions()
        return #PassedActions > 0
    end

    -- 开始执行PassedActions列表
    function XMovieManager.StartPassedActions()
        if #PassedActions > 0 then
            for index, passedAction in ipairs(PassedActions) do
                passedAction:OnPassedActionExecute(index)
            end
        end
    end
    
    -- 是否在Loading结束后开始
    function XMovieManager.IsStartActionAfterLoading()
        local action = WaitToPlayList[CurPlayingActionIndex]
        if action then
            return action:IsStartAfterLoading()
        end
        return false
    end
    
    -- 开始执行Actions列表
    function XMovieManager.StartActions()
        DoAction()
    end
    
    -- 后面是否存在PassedAction会覆盖当前Action的UI显示
    ---@param curIndex number 当前Action位于PassedActions下标
    function XMovieManager.IsBehindPassedActionCover(curIndex)
        local allActionCnt = #PassedActions
        local action = PassedActions[curIndex]
        for actionIndex = curIndex + 1, allActionCnt do
            local behindAction = PassedActions[actionIndex]
            if action:IsPassedActionCovered(behindAction) then
                return true
            end
        end
        return false
    end
    
    -- 获取Selection类型Action，选择的下标
    function XMovieManager.GetPassedSelectionIndex(actionId)
        return PassedOptionDic[actionId]
    end

    function XMovieManager.BackToLastAction()
        local curAction = WaitToPlayList[CurPlayingActionIndex]
        local lastId = MovieBackStack:Peek()
        if lastId ~= CurPlayingActionIndex then
            curAction:OnUndo()
            curAction:OnReset()
        end
        if MovieBackStack:Count() == 0 then
            CurPlayingActionIndex = 1
        end
        while (MovieBackStack:Count() ~= 0) do
            local currIndex = MovieBackStack:Pop()
            local action = WaitToPlayList[currIndex]
            action:OnUndo()
            action:OnReset()
            if MovieBackFilter[action:GetType()] then
                CurPlayingActionIndex = currIndex
                break
            end
            if MovieBackStack:Count() == 0 then
                CurPlayingActionIndex = 1
                break
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
    end
    
    -- 获取当前播放的Action下标
    function XMovieManager.GetCurPlayingActionIndex()
        return CurPlayingActionIndex
    end

    -- 获取当前播放的Action类型
    function XMovieManager.GetCurPlayingActionType()
        local curAction = WaitToPlayList[CurPlayingActionIndex]
        if curAction then
            return curAction:GetType()
        end
    end
    
    function XMovieManager.GetNextActionId(actionId)
        local nextIndex = GetActionIndexById(CurPlayingMovieId, actionId) + 1
        local nextActionId = WaitToPlayList[nextIndex]:GetActionId()
        return nextActionId
    end

    local function IsPlayingNewMovie()
        return IsPlaying
    end

    local function IsPlayingOldMovie()
        return CSMovieXMovieManagerInstance:IsPlayingMovie()
    end

    function XMovieManager.IsPlayingMovie()
        return IsPlayingNewMovie() or IsPlayingOldMovie()
    end

    function XMovieManager.IsMovieYield()
        if not XMovieManager.IsPlayingMovie() then return false end
        return IsYield or false
    end

    function XMovieManager.YiledMovie()
        if not YieldCallBack then return end --没有恢复回调时不允许挂起

        IsYield = true

        YieldCallBack()
        YieldCallBack = nil
    end

    function XMovieManager.IsMoviePause()
        if not XMovieManager.IsPlayingMovie() then return false end
        return IsPause or false
    end

    function XMovieManager.SetMoviePause(isPause)
        IsPause = isPause
    end

    function XMovieManager.SwitchMovieState()
        IsPause = not IsPause
        local action = WaitToPlayList[CurPlayingActionIndex]
        if (not IsPause) and action:CanContinue() then
            DoAction()
        end
    end

    function XMovieManager.ResumeMovie(index)
        if not IsPlayingNewMovie() then
            if IsPlayingOldMovie() then
                XLog.Error("XMovieManager.ResumeMovie Error: 老版剧情不支持挂起恢复操作")
                return
            end

            XLog.Error("XMovieManager.ResumeMovie Error: 当前没有播放中的剧情")
            return
        end

        local action = WaitToPlayList[CurPlayingActionIndex]
        if not IsYield or not action.ResumeAtIndex then
            XLog.Error("XMovieManager.ResumeMovie Error: 当前没有挂起中的剧情, action: ", action)
            return
        end

        IsYield = nil
        action:ResumeAtIndex(index)
        DoAction()
    end

    function XMovieManager.PushInReviewDialogList(roleName, dialogContent, cueId, actionType)
        roleName = roleName and roleName ~= "" and roleName .. ":  " or ""
        if not string.IsNilOrEmpty(roleName) then
            dialogContent = dialogContent and dialogContent ~= "" and dialogContent or ""
        end
        
        local data = {
            RoleName = roleName,
            Content = dialogContent,
            CueId = cueId,
            ActionType = actionType
        }
        tableInsert(ReviewDialogList, data)
    end
    
    -- 移除并返回最后一个回顾
    function XMovieManager.PopLastReviewDialog(actionType)
        local reviewDialogCnt = #ReviewDialogList
        if reviewDialogCnt == 0 then return end
        
        if actionType then
            for i = reviewDialogCnt, 1, -1 do
                if ReviewDialogList[i].ActionType == actionType then
                    local dialog = tableRemove(ReviewDialogList, i)
                    return dialog
                end
            end
        else
            return tableRemove(ReviewDialogList)
        end
    end

    function XMovieManager.RemoveFromReviewDialogList()
        if ReviewDialogList and #ReviewDialogList > 0 then
            tableRemove(ReviewDialogList)
        end
    end

    function XMovieManager.DelaySelectAction(key, actionId)
        DelaySelectionDic[key] = actionId
    end

    function XMovieManager.GetDelaySelectActionId(key)
        local actionId = DelaySelectionDic[key]
        if actionId then
            DelaySelectionDic[key] = nil
        else
            actionId = 0
        end
        return actionId
    end
    
    -- 设置剧情对应的关卡Id
    function XMovieManager.SetStageId(stageId)
        StageId = stageId
    end
    
    -- 获取剧情对应的关卡Id
    function XMovieManager.GetStageId()
        return StageId
    end
    
    -- 是否显示书签
    function XMovieManager.IsShowBookmark()
        if not StageId then return false end
        
        local stageType = XMVCA.XFuben:GetStageType(StageId)
        return stageType == XEnumConst.FuBen.StageType.Mainline or stageType == XEnumConst.FuBen.StageType.Mainline2 
                or stageType == XEnumConst.FuBen.StageType.ShortStory or stageType == XEnumConst.FuBen.StageType.ExtraChapter
    end
    
    -- 缓存选项数据
    function XMovieManager.CacheSelectionData(actionId, index)
        SelectionDataDic[actionId] = index
    end
    
    -- 获取当前剧情的选项选择数据
    function XMovieManager.GetSelectionDataDic()
        return XTool.Clone(SelectionDataDic)
    end

    function XMovieManager.GetReviewDialogList()
        return ReviewDialogList
    end

    function XMovieManager.ReplacePlayerName(str)
        return XUiHelper.ReplaceWithPlayerName(str, XMovieConfigs.PLAYER_NAME_REPLACEMENT)
    end

    function XMovieManager.Fit(width)
        return width * RESOLUTION_RATIO
    end

    function XMovieManager.ParamToNumber(param)
        return param and param ~= "" and tonumber(param) or 0
    end

    function XMovieManager.TransTimeLineSeconds(time)
        time = time or 0
        local interger = mathFloor(time)
        local decimal = time - interger
        return interger + TIMELINE_SECONDS_TRANS * decimal
    end

    function XMovieManager.ReloadMovies()
        if not XMain.IsDebug then return end

        ClearAllMovieActions()
        XMovieConfigs.DeleteMovieCfgs()
    end

    function XMovieManager.TryGetMovieSkipSummaryCfg()
        return XMovieConfigs.TryGetMovieSkipSummaryCfg(CurPlayingMovieId)
    end
    
    --[[ 改成XMVCA.XMovie:FormatContent
    --- 针对传入的文本，根据玩家当前的性别类型进行处理，返回处理过后的文本
    function XMovieManager.GetSummaryContentByGenderCheck(content)
        local OpenMovieThirdGender = XMVCA.XMovie:GetOpenMovieSkipThirdGender()

        -- 这里写死了标签与性别ID的映射，若后期需要走配置，则需要调整这里的逻辑
        if XPlayer.Gender == 0 or XPlayer.Gender == XEnumConst.PLAYER.GENDER_TYPE.MAN or (not OpenMovieThirdGender and XPlayer.Gender == XEnumConst.PLAYER.GENDER_TYPE.SECRECY) then
            -- 未配置、男、保密，均按男的文本
            -- 将由女性标签包围的连续字符串，或男性标签字符串替换为空
            local result = string.gsub(content, '<W>.-</W>', '')
            result = string.gsub(result, '<T>.-</T>', '')
            result = string.gsub(result, '<M>', '')
            result = string.gsub(result, '</M>', '')
            return result
        elseif OpenMovieThirdGender and XPlayer.Gender == XEnumConst.PLAYER.GENDER_TYPE.SECRECY then
            local isManOrWoman = string.gmatch(content, "<T>.-</T>")
            if not isManOrWoman() then
                local result = string.gsub(content, '<W>.-</W>', '')
                result = string.gsub(result, '<M>', '')
                result = string.gsub(result, '</M>', '')
                return result
            end
            local result = string.gsub(content, '<M>.-</M>', '')
            result = string.gsub(result, '<W>.-</W>', '')
            result = string.gsub(result, '<T>', '')
            result = string.gsub(result, '</T>', '')
            return result
        else
            -- 将由男性标签包围的连续字符串，或女性标签字符串替换为空
            local result = string.gsub(content, '<M>.-</M>', '')
            result = string.gsub(result, '<T>.-</T>', '')
            result = string.gsub(result, '<W>', '')
            result = string.gsub(result, '</W>', '')
            return result
        end
    end
    ]]

    function XMovieManager.GetCurPlayingMovieId()
        return CurPlayingMovieId
    end
    
    function XMovieManager:GetCurPlayingActionId()
        if CurrentAction then
            return CurrentAction:GetActionId()
        end

        local action = WaitToPlayList[CurPlayingActionIndex]
        if action then
            return action:GetActionId()
        end
        return 0
    end

    --检测功能开关
    function XMovieManager.CheckFuncDisable()
        return XMain.IsDebug and XSaveTool.GetData(XPrefs.StoryTrigger)
    end

    function XMovieManager.ChangeFuncDisable(state)
        DisableFunction = state
        XSaveTool.SaveData(XPrefs.StoryTrigger, DisableFunction)
    end

    --region 自动播放
    
    -- 切换自动播放
    function XMovieManager.SwitchAutoPlay(speed)
        if not IsAutoPlay then
            if speed then
                XMovieManager.SetSpeed(speed)
            end
            
            local ui = XLuaUiManager.FindTopUi("UiMovie")
            if ui then
                ---@type XUiMovie
                local uiMovie = ui.UiProxy.UiLuaTable
                uiMovie:OnClickBtnAuto()
            end
        end
    end
    
    -- 设置自动播放
    function XMovieManager.SetAutoPlay(isAutoPlay)
        IsAutoPlay = isAutoPlay

        -- 打点
        local dict = {}
        dict["story_id"] = CurPlayingMovieId
        dict["role_level"] = XPlayer.GetLevel()
        dict["speed"] = XMovieManager.GetSpeed()
        dict["sex"] = XPlayer.Gender or 0
        if IsAutoPlay then
            CS.XRecord.Record(dict, "200011", "StoryAutoplayStart")
        else
            CS.XRecord.Record(dict, "200012", "StoryAutoplayEnd")
        end
    end
    
    -- 发送自动播放事件
    function XMovieManager.DispatchAutoPlayEvent()
        local action = WaitToPlayList[CurPlayingActionIndex]
        if action then
            XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_AUTO_PLAY, IsAutoPlay)
        end
    end

    -- 
    function XMovieManager.GetIsAutoPlay()
        return IsAutoPlay
    end
    
    -- 设置长按自动播放
    function XMovieManager.SetLongPressAutoPlay(isLongPressAutoPlay)
        IsLongPressAutoPlay = isLongPressAutoPlay
    end
    
    -- 设置倍速
    function XMovieManager.SetSpeed(speed)
        -- 长按加速设置的倍速不进行缓存，GetSpeed()直接返回LONG_PRESS_SPEED
        if IsLongPressAutoPlay then return end

        Speed = speed
        XSaveTool.SaveData("MovieAutoPlaySpeed", speed)

        -- 打点
        local dict = {}
        dict["story_id"] = CurPlayingMovieId
        dict["role_level"] = XPlayer.GetLevel()
        dict["speed"] = Speed
        dict["sex"] = XPlayer.Gender or 0
        CS.XRecord.Record(dict, "200013", "StoryAutoplayChangeSpeed")
    end

    -- 获取倍速
    function XMovieManager.GetSpeed()
        if IsAutoPlay then
            if IsLongPressAutoPlay then
                return XMVCA.XMovie.EnumConst.LONG_PRESS_SPEED
            else
                if not Speed then
                    Speed = XSaveTool.GetData("MovieAutoPlaySpeed") or XMVCA.XMovie.EnumConst.DEFAULT_SPEED
                end
                return Speed
            end
        else
            return XMVCA.XMovie.EnumConst.DEFAULT_SPEED
        end
    end

    -- 当前是否加速
    function XMovieManager.IsSpeedUp()
        return XMovieManager.GetSpeed() ~= XMVCA.XMovie.EnumConst.DEFAULT_SPEED and IsAutoPlay
    end
    --endregion
    
    --region 埋点相关
    
    --- 记录开始剧情
    function XMovieManager.RecordStorylineStart(id, level, sex)
        sex = sex or XPlayer.Gender
        
        local dict = {}
        dict["story_id"] = id
        dict["role_level"] = level or XPlayer.GetLevel()
        dict["sex"] = sex or 0
        CS.XRecord.Record(dict, "200001", "StorylineStart")
    end

    --- 记录剧情结束
    function XMovieManager.RecordStorylineEnd(id, level, sex)
        sex = sex or XPlayer.Gender
        
        local dict = {}
        dict["story_id"] = id
        dict["role_level"] = level or XPlayer.GetLevel()
        dict["sex"] = sex or 0
        CS.XRecord.Record(dict, "200002", "StorylineEnd")
    end 
    
    --- 记录剧情跳过
    function XMovieManager.RecordStorylineSkip(id, level, sex, stayTime, action_id)
        sex = sex or XPlayer.Gender
        
        local dict = {}
        dict["story_id"] = id
        dict["role_level"] = level or XPlayer.GetLevel()
        dict["sex"] = sex or 0
        dict["stay_time"] = stayTime
        dict["action_id"] = action_id
        CS.XRecord.Record(dict, "200003", "StorylineSkip")
    end
    
    --endregion

    XMovieManager.Init()
    return XMovieManager
end