---@class XPlotExhibitionAgency : XAgency
---@field private _Model XPlotExhibitionModel
local XPlotExhibitionAgency = XClass(XAgency, "XPlotExhibitionAgency")

function XPlotExhibitionAgency:OnInit()
    self._Speedrun = {}
    -- 添加协程相关的字段
    self._Coroutine = nil
    self._IsRunningCoroutine = false
end

function XPlotExhibitionAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
end

function XPlotExhibitionAgency:InitEvent()
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_ENABLE, self._SendRecordAsync, self)
end

function XPlotExhibitionAgency:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_ENABLE, self._SendRecordAsync, self)
    -- 停止协程
    self:_StopCoroutine()
end

-- 停止协程的函数
function XPlotExhibitionAgency:_StopCoroutine()
    self._IsRunningCoroutine = false
    self._Coroutine = nil
end

function XPlotExhibitionAgency:OpenRoleDetail(characterId)
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end

    local functionId = XFunctionManager.FunctionName.PlotExhibition
    if XFunctionManager.DetectionFunction(functionId) then
        XLuaUiManager.Open("UiPlotExhibitionDetail", characterId)
    end
end

--此记录仅在当次登录期间保存，重登游戏时，清除上一次登录的本地记录，所有勾选状态切换回【取消】状态
function XPlotExhibitionAgency:SetIsSpeedrun(stageId, value)
    local groupId = self._Model:GetStageGroupId(stageId)
    if groupId then
        self._Speedrun[groupId] = value
    else
        XLog.Error("[XPlotExhibitionAgency] 找不到stageId对应的groupId", stageId)
    end
end

function XPlotExhibitionAgency:GetIsSpeedrun(stageId)
    local groupId = self._Model:GetStageGroupId(stageId)
    if groupId then
        return self._Speedrun[groupId]
        --else
        --    XLog.Error("[XPlotExhibitionAgency] 找不到stageId对应的groupId", stageId)
    end
end

function XPlotExhibitionAgency:AddSpeedrunRobots(stageId, entities)
    if self:GetIsSpeedrun(stageId) then
        local config = self._Model:GetStageSpeedrunConfig(stageId)
        if config then
            for _, robotId in pairs(config.RobotId) do
                local robot = XRobotManager.GetRobotById(robotId)
                if robot then
                    table.insert(entities, robot)
                else
                    XLog.Error("XPlotExhibitionAgency:AddSpeedrunRobots robotId not exist:" .. tostring(robotId))
                end
            end
        end
    end
end

function XPlotExhibitionAgency:GetSpeedrunStageGroupId(stageId)
    local groupId = self._Model:GetStageGroupId(stageId)
    return groupId
end

function XPlotExhibitionAgency:GetSpeedrunStageId(stageId)
    local groupId = self._Model:GetStageGroupId(stageId)
    if groupId then
        if self._Speedrun[groupId] then
            local config = self._Model:GetStageSpeedrunConfig(stageId)
            if config then
                XLog.Debug("关卡:" .. tostring(stageId) .. "替换为速通关卡:" .. config.StageId)
                return config.StageId
            end
        end
    end
end

function XPlotExhibitionAgency:IsShowSpeedrunToggle(stageId)
    local config = self._Model:GetStageSpeedrunConfig(stageId)
    if config then
        return true
    end
    return false
end

---@return XTablePlotExhibitionStoryLine[]
function XPlotExhibitionAgency:GetStoryLineConfigs()
    return self._Model:GetStoryLineConfigs()
end

function XPlotExhibitionAgency:OpenMain()
    if not XMVCA.XSubPackage:CheckSubpackage() then
        return
    end

    local functionId = XFunctionManager.FunctionName.PlotExhibition
    if XFunctionManager.DetectionFunction(functionId) then
        XLuaUiManager.Open("UiPlotExhibitionMain")
    end
end

-- 分帧处理函数
function XPlotExhibitionAgency:_ProcessPlotData(plot, roleConfigs, storyDict)
    self._IsRunningCoroutine = true

    local i = 1
    local config
    local roleId
    local startTime = os.clock()

    while self._IsRunningCoroutine and i <= #roleConfigs do
        -- 检查是否超时（避免单帧处理时间过长）
        if os.clock() - startTime > 0.016 then
            -- 约1帧时间
            -- 让出控制权，下一帧继续执行
            coroutine.yield()
            startTime = os.clock()
        end

        config = roleConfigs[i]
        -- 因为解析问题, 所以要把number转为string
        roleId = tostring(config.Id)
        local currentProgressRole = 0
        local totalProgressRole = 0
        for j = 1, #config.CharacterId do
            local characterId = tostring(config.CharacterId[j])
            local storyProgress = {}
            local storyList = storyDict[characterId]
            if storyList then
                local currentProgressCharacter, totalProgressCharacter = 0, 0
                for k = 1, #storyList do
                    ---@type XTablePlotExhibitionStoryLine
                    local storyConfig = storyList[k]
                    local storyId = storyConfig.Id
                    local currentProgressStory, totalProgressStory = self:GetProgressByStoryConfig(storyConfig)
                    currentProgressCharacter = currentProgressCharacter + currentProgressStory
                    totalProgressCharacter = totalProgressCharacter + totalProgressStory

                    local progressChild = totalProgressStory > 0 and math.ceil(currentProgressStory / totalProgressStory * 100) or 0
                    storyProgress[storyId] = progressChild
                end

                local progress = totalProgressCharacter > 0 and math.ceil(currentProgressCharacter / totalProgressCharacter * 100) or 0
                plot[roleId] = plot[roleId] or {}
                plot[roleId][characterId] = {
                    totalProgress = progress,
                    storyProgress = storyProgress
                }

                currentProgressRole = currentProgressRole + currentProgressCharacter
                totalProgressRole = totalProgressRole + totalProgressCharacter
            else
                XLog.Error("[XPlotExhibitionAgency] 找不到characterId对应的角色", characterId)
            end
        end
        plot[roleId].totalProgress = totalProgressRole > 0 and math.ceil(currentProgressRole / totalProgressRole * 100) or 0

        i = i + 1
    end

    -- 处理完成后的操作
    if self._IsRunningCoroutine then
        --XLog.Error("埋点耗时:", os.clock() - startTime)
        CS.XRecord.Record({ plot = plot }, "200024", "Plot")
        --XLog.Error(plot)
    end

    self._IsRunningCoroutine = false
    self._Coroutine = nil
end

function XPlotExhibitionAgency:_SendRecordAsync()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_ENABLE, self._SendRecordAsync, self)

    local lastTime = self._Model._SaveUtil:GetData("SendRecord")
    local timestamp = XTime.GetServerNowTimestamp()
    local today = XTime.GetTimeDayFreshTime(timestamp)
    if lastTime == today then
        --XLog.Error("今天已发送")
        return
    end
    --XLog.Error("发送事件, 每天只发送一次")
    self._Model._SaveUtil:SaveData("SendRecord", today)

    local storyDict = {}
    local storyConfigs = self._Model:GetStoryLineConfigs()
    for _, storyConfig in pairs(storyConfigs) do
        local characterId = tostring(storyConfig.CharacterId)
        storyDict[characterId] = storyDict[characterId] or {}
        local storyList = storyDict[characterId]
        storyList[#storyList + 1] = storyConfig
    end

    -- 剧情进度埋点
    local plot = {}
    local roleConfigs = self._Model:GetRoleGroupConfigs()

    -- 检查是否已有协程在运行，避免重复发起
    if self._IsRunningCoroutine and self._Coroutine then
        XLog.Debug("协程已在运行中，跳过重复发起")
        return
    end

    -- 使用协程分帧处理
    self._IsRunningCoroutine = true
    self._Coroutine = coroutine.create(function()
        self:_ProcessPlotData(plot, roleConfigs, storyDict)
    end)

    -- 启动协程
    local function ResumeCoroutine()
        if self._Coroutine and coroutine.status(self._Coroutine) ~= "dead" then
            local success, err = coroutine.resume(self._Coroutine)
            if not success then
                XLog.Error("协程执行出错:", err)
                self:_StopCoroutine()
            else
                -- 如果协程还未结束，下一帧继续执行
                if self._Coroutine and coroutine.status(self._Coroutine) ~= "dead" then
                    XScheduleManager.ScheduleOnce(ResumeCoroutine, 1)
                end
            end
        end
    end

    ResumeCoroutine()
end

-- 因为埋点需要, 所以把下面这部分代码, 从control移到了agency中
---@param storyConfig XTablePlotExhibitionStoryLine
function XPlotExhibitionAgency:GetProgressByStoryConfig(storyConfig)
    if not storyConfig then
        return 0, 0
    end
    local chapterType, chapterId = storyConfig.StoryType, storyConfig.StoryChapter

    -- 好感度剧情
    if chapterType == XEnumConst.FuBen.ChapterType.FavorabilityStory then
        local characterId = storyConfig.CharacterId
        local plotDatas = XMVCA.XFavorability:GetCharacterStoryById(characterId)
        -- 刷新通关进度
        local totalCount = XTool.GetTableCount(plotDatas)
        
        -- 好感度剧情是需要有角色的，相约纪实不需要角色也可以打
        -- 但是目前他们混用了同一个类型，所以去掉限制
        --if not XMVCA.XCharacter:IsOwnCharacter(characterId) then
        --    return 0, totalCount
        --end

        local passCount = 0
        if not XTool.IsTableEmpty(plotDatas) then
            for i, v in ipairs(plotDatas) do
                if XTool.IsNumberValid(v.StoryId) then
                    if XMVCA.XFavorability:CheckStoryIsSatisfyUnlockCondition(characterId, v.Id) then
                        passCount = passCount + 1
                    end
                elseif XTool.IsNumberValid(v.StageId) then
                    if XMVCA.XFuben:CheckStageIsPass(v.StageId) then
                        passCount = passCount + 1
                    end
                end
            end
        end
        return passCount, totalCount
    end
    -- 主线等剧情
    local difficult = XDataCenter.FubenManager.DifficultNormal

    --主线
    if chapterType == XEnumConst.FuBen.ChapterType.MainLine then
        local viewModel = XDataCenter.FubenMainLineManager:ExGetChapterViewModelById(chapterId, difficult)
        return XMVCA.XMainLine2:GetViewModelCurrentAndMaxProgress(viewModel)
    end

    --外篇旧闻
    if chapterType == XEnumConst.FuBen.ChapterType.ExtralChapter then
        local viewModel = XDataCenter.ExtraChapterManager:ExGetChapterViewModelById(chapterId, difficult)
        return viewModel:GetCurrentAndMaxProgress()
    end

    --浮点纪实
    if chapterType == XEnumConst.FuBen.ChapterType.ShortStory then
        local viewModel = XDataCenter.ShortStoryChapterManager:ExGetChapterViewModelById(chapterId, difficult)
        return viewModel:GetCurrentAndMaxProgress()
    end

    --间章旧闻
    if chapterType == XEnumConst.FuBen.ChapterType.Prequel then
        local viewModel = XDataCenter.PrequelManager:ExGetChapterViewModelByChapterId(chapterId)
        if viewModel then
            return viewModel:GetCurrentAndMaxProgress()
        else
            XLog.Error("[XPlotExhibitionControl] 未找到间章旧闻:" .. tostring(chapterId))
        end
        return 0, 0
    end

    --本我回廊（角色塔）
    if chapterType == XEnumConst.FuBen.ChapterType.CharacterTower then
        local viewModel = XDataCenter.CharacterTowerManager:ExGetChapterViewModelBuyChapterId(chapterId)
        if viewModel then
            return viewModel:GetCurrentAndMaxProgress()
        else
            XLog.Error("[XPlotExhibitionControl] 未找到本我回廊:" .. tostring(chapterId))
        end
        return 0, 0
    end

    --主线2
    if chapterType == XEnumConst.FuBen.ChapterType.MainLine2 then
        -- 这个函数参数是mainId，但是实际含义是chapterId
        return XMVCA.XMainLine2:GetMainProgress(chapterId)
    end
    XLog.Error("[XPlotExhibitionControl] 未实现的剧情进度:" .. chapterType)
    return 0, 0
end

return XPlotExhibitionAgency