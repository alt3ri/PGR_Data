local XFubenActivityAgency = require("XModule/XBase/XFubenActivityAgency")
---@class XMainLine2Agency : XFubenActivityAgency
---@field _Model XMainLine2Model
local XMainLine2Agency = XClass(XFubenActivityAgency, "XMainLineAgency")

function XMainLine2Agency:OnInit()
    --初始化一些变量
    self:RegisterFuben(XEnumConst.FuBen.StageType.Mainline2)

    -- 添加协程相关的字段
    self._Coroutine = nil
    self._IsRunningCoroutine = false
end

function XMainLine2Agency:AfterInitManager()
    XDataCenter.FubenManagerEx.RegisterManager(self)
end

function XMainLine2Agency:InitRpc()
    -- 注册服务器事件
end

function XMainLine2Agency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
    XEventManager.AddEventListener(XEventId.EVENT_SCENE_UIMAIN_ENABLE, self._SendRecordAsync, self)
end

function XMainLine2Agency:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_ENABLE, self._SendRecordAsync, self)
    -- 停止协程
    self:_StopCoroutine()
end

--- 获取章节类型
function XMainLine2Agency:ExGetChapterType()
    return XEnumConst.FuBen.ChapterType.MainLine2
end

function XMainLine2Agency:ExGetFunctionNameType()
    return XFunctionManager.FunctionName.MainLine
end

--- 通过章节Id，获取主章节实例
function XMainLine2Agency:ExGetChapterViewModelBySubChapterId(chapterId)
    local mainCfgs = self._Model:GetConfigMain()
    for _, mainCfg in pairs(mainCfgs) do
        for _, cId in ipairs(mainCfg.ChapterIds) do
            if cId == chapterId then
                return self:GetMain(mainCfg.Id)
            end
        end
    end

    return nil
end

--region 埋点
-- 停止协程的函数
function XMainLine2Agency:_StopCoroutine()
    self._IsRunningCoroutine = false
    self._Coroutine = nil
end


function XMainLine2Agency:_SendRecordAsync()
    XEventManager.RemoveEventListener(XEventId.EVENT_SCENE_UIMAIN_ENABLE, self._SendRecordAsync, self)

    -- 检查是否已有协程在运行，避免重复发起
    if self._IsRunningCoroutine and self._Coroutine then
        XLog.Debug("协程已在运行中，跳过重复发起")
        return
    end
    
    -- 使用协程分帧处理
    self._IsRunningCoroutine = true
    self._Coroutine = coroutine.create(function()  -- TODO 优化全局变量
        self:_ProcessMainLineData()
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

-- 分帧处理函数
function XMainLine2Agency:_ProcessMainLineData()
    self._IsRunningCoroutine = true

    local dict = {}
    local mainline = {}
    dict["mainline"] = mainline
    local moduleCfgs = XMVCA.XMainLine2:GetConfigExhibitionModule()
    local i = 1
    local moduleCnt = #moduleCfgs
    local startTime = os.clock()

    while self._IsRunningCoroutine and i <= moduleCnt do
        -- 检查是否超时（避免单帧处理时间过长）
        if os.clock() - startTime > 0.016 then
            -- 约1帧时间
            -- 让出控制权，下一帧继续执行
            coroutine.yield()
            startTime = os.clock()
        end

        local moduleCfg = moduleCfgs[i]
        local module = {}
        mainline[tostring(moduleCfg.Id)] = module
        local currentProgress, maxProgress = XMVCA.XMainLine2:GetExhibitionModuleProgress(moduleCfg.Id)
        local chapters = {}
        module["progress"] = string.format("%.2f", currentProgress / maxProgress)
        module["chapters"] = chapters
        for _, exhibitionChapterId in ipairs(moduleCfg.ChapterIds) do
            local currentChapterProgress, maxChapterProgress = self:GetExhibitionChapterProgress(exhibitionChapterId)
            if maxChapterProgress ~= 0 then
                chapters[tostring(exhibitionChapterId)] = string.format("%.2f", currentChapterProgress / maxChapterProgress)
            end
        end
        i = i + 1
    end

    -- 处理完成后的操作
    if self._IsRunningCoroutine then
        --XLog.Error("埋点耗时:", os.clock() - startTime)
        CS.XRecord.Record(dict, "200022", "MainlineProgress")
        --XLog.Error(dict)
    end

    self._IsRunningCoroutine = false
    self._Coroutine = nil
end

--endregion

--region rpc
function XMainLine2Agency:OnLoginNotify(fubenMainLine2Data)
    self._Model:OnLoginNotify(fubenMainLine2Data)
end

--- 请求领取成就
---@param id number 主章节Id
function XMainLine2Agency:RequestReceiveAchievement(mainId, cb)
    local req = { ChapterId = mainId }
    XNetwork.CallWithAutoHandleErrorCode("MainLine2ReceiveAchievementRequest", req, function(res)
        self._Model:OnReceiveAchievement(mainId)
        if res.RewardGoodsList then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end
        if cb then cb() end
    end)
end

--- 请求领取通关奖励
function XMainLine2Agency:RequestReceiveTreasure(chapterId, cb)
    local req = { ChapterId = chapterId }
    XNetwork.CallWithAutoHandleErrorCode("MainLine2ReceiveTreasureRequest", req, function(res)
        self._Model:OnReceiveTreasure(chapterId, res.RewardIdxs)
        if res.RewardGoodsList then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end
        if cb then cb() end
    end)
end

--- 请求领取主章节的通关奖励
function XMainLine2Agency:ReceiveMainTreasureRequest(mainId, cb)
    local req = { MainId = mainId }
    XNetwork.CallWithAutoHandleErrorCode("MainLine2ReceiveMainTreasureRequest", req, function(res)
        self._Model:OnReceiveMainTreasure(mainId, res.RewardIdxs)
        if res.RewardGoodsList then
            XUiManager.OpenUiObtain(res.RewardGoodsList)
        end
        if cb then cb() end
    end)
end

--- 请求领取彩蛋奖励
function XMainLine2Agency:RequestMainLine2ReceiveEggsTreasure(chapterId, eggId, cb)
    local req = { ChapterId = chapterId, EggId = eggId }
    XNetwork.CallWithAutoHandleErrorCode("MainLine2ReceiveEggsTreasureRequest", req, function(res)
        self._Model:AddEggData(eggId)
        if cb then cb(res.RewardGoodsList) end
    end)
end
--endregion


--- 主章节是否存在
---@param id number 主章节Id
function XMainLine2Agency:IsMainExit(id)
    return self._Model:IsMainExit(id)
end

--- 获取主章节实例
---@param mainId number 主章节Id
function XMainLine2Agency:GetMain(mainId)
    return self._Model:GetMain(mainId)
end

--- 获取所有主章节实例
function XMainLine2Agency:GetAllMains()
    return self._Model:GetAllMains()
end

--- 获取主章节配置表列表
---@param storyType number 章节类型
---@param groupId number 组Id
function XMainLine2Agency:GetMainCfgsByStoryTypeGroupId(storyType, groupId)
    return self._Model:GetMainCfgsByStoryTypeGroupId(storyType, groupId)
end

--- 获取主章节进度
---@param mainId number 主章节Id
function XMainLine2Agency:GetMainProgress(mainId)
    return self._Model:GetMainProgress(mainId)
end

-- 获取主章节标题
function XMainLine2Agency:GetMainTitle(mainId)
    return self._Model:GetMainTitle(mainId)
end

-- 获取主章节任务组Id
function XMainLine2Agency:GetMainTaskGroupId(mainId)
    return self._Model:GetMainTaskGroupId(mainId)
end

--- 主章节是否显示新章节标签：存在 已解锁 + 未通关 的关卡
---@param mainId number 主章节Id
function XMainLine2Agency:IsMainHasNewTag(mainId)
    local chapterIds = self._Model:GetMainChapterIds(mainId)
    for _, chapterId in ipairs(chapterIds) do
        if self:IsChapterUnlock(chapterId) and not self:IsChapterPassed(chapterId) then
            return true
        end
    end
    return false
end

--- 主章节是否显示限时标签：配置TimeId，可选配置ConditionId
---@param mainId number 主章节Id
function XMainLine2Agency:IsMainShowTimeLimitTag(mainId)
    local chapterIds = self._Model:GetMainChapterIds(mainId)
    for _, chapterId in ipairs(chapterIds) do
        local timeId = self._Model:GetChapterActivityTimeId(chapterId)
        if XFunctionManager.CheckInTimeByTimeId(timeId) then
            return true
        end
    end
    return false
end

--- 主章节是否特殊标签
---@param mainId number 主章节Id
function XMainLine2Agency:IsMainShowSpecialTag(mainId)
    local condition = self._Model:GetMainSpecialCondition(mainId)
    if condition ~= 0 then
        return XConditionManager.CheckCondition(condition)
    end
    return false
end

--- 获取主章节特殊页签名称
---@param mainId number 主章节Id
function XMainLine2Agency:GetMainSpecialTagName(mainId)
    return self._Model:GetMainSpecialTagName(mainId)
end

--- 获取主章节特殊特效
---@param mainId number 主章节Id
function XMainLine2Agency:GetSpecialEffect(mainId)
    return self._Model:GetSpecialEffect(mainId)
end

--- 主章节是否全通关
---@param mainId number 主章节Id
function XMainLine2Agency:IsMainPassed(mainId)
    return self._Model:IsMainPassed(mainId)
end

--- 获取主线主章节通关数量
function XMainLine2Agency:GetMainChapterPassedCount(storyType, difficult)
    ---@type XTableMainLine2Main[]
    local cfgs = self._Model:GetConfigMain()

    local count = 0

    for i, v in pairs(cfgs) do
        if not storyType or v.StoryType == storyType then
            -- 检查普通章节是否全通关
            if self._Model:IsMainPassed(v.Id, difficult) then
                count = count + 1
            end
        end
    end
    
    return count
end

--- 主章节是否解锁
---@param mainId number 主章节Id
function XMainLine2Agency:IsMainUnlock(mainId)
    return self._Model:IsMainUnlock(mainId)
end

-- 获取主章节是否已领取成就
function XMainLine2Agency:IsAchievementGet(mainId)
    return self._Model:IsAchievementGet(mainId)
end

--- 获取主章节成就进度
---@param mainId number 主章节Id
function XMainLine2Agency:GetMainAchievementProgress(mainId)
    local curCnt = 0
    local mainCfg = self._Model:GetConfigMain(mainId)
    if not mainCfg then
        XLog.Error("[XMainLine2Agency] 找不到对应的主线配置:" .. tostring(mainId))
        return 0, 0
    end
    for _, chapterId in ipairs(mainCfg.ChapterIds) do
        local groupIds = self._Model:GetChapterStageGroupIds(chapterId)
        for _, groupId in ipairs(groupIds) do
            local stageIds = self._Model:GetGroupStageIds(groupId)
            for _, stageId in ipairs(stageIds) do
                local cnt, map = self:GetStageAchievementMap(stageId)
                curCnt = curCnt + cnt
            end
        end
    end

    local maxCnt = self._Model:GetAchievementCount(mainCfg.AchievementId)
    return curCnt, maxCnt
end

function XMainLine2Agency:GetMainAchievementIconWithLockState(mainId)
    local curCnt, maxCnt = self:GetMainAchievementProgress(mainId)
    local isUnlock = curCnt >= maxCnt
    if isUnlock then
        return self:GetMainAchievementIcon(mainId), true
    else
        return self:GetAchievementChapterIconLock(mainId), false
    end
end

--- 获取主章节成就图标
---@param mainId number 主章节Id
function XMainLine2Agency:GetMainAchievementIcon(mainId)
    local mainCfg = self._Model:GetConfigMain(mainId)
    if not mainCfg then
        XLog.Error("[XMainLine2Agency] 找不到对应的主线配置:" .. tostring(mainId))
        return nil
    end
    if mainCfg.AchievementId ~= 0 then
        return self._Model:GetAchievementChapterIcon(mainCfg.AchievementId)
    end

    return nil
end

--- 获取主章节成就未解锁图标
---@param mainId number 主章节Id
function XMainLine2Agency:GetAchievementChapterIconLock(mainId)
    local mainCfg = self._Model:GetConfigMain(mainId)
    if not mainCfg then
        XLog.Error("[XMainLine2Agency] 找不到对应的主线配置:" .. tostring(mainId))
        return nil
    end
    if mainCfg.AchievementId ~= 0 then
        return self._Model:GetAchievementChapterIconLock(mainCfg.AchievementId)
    end

    return nil
end

-- 获取主章节的第一个子章节Id
function XMainLine2Agency:GetMainFirstChapterId(mainId)
    local chapterIds = self._Model:GetMainChapterIds(mainId)
    return chapterIds[1]
end

-- 获取子章节的第一个StageGroupId
function XMainLine2Agency:GetChapterFirstStageGroupId(chapterId)
    local stageGroupIds = self._Model:GetChapterStageGroupIds(chapterId)
    return stageGroupIds[1]
end

--- 主章节是否显示蓝点
---@param mainId number 主章节Id
function XMainLine2Agency:IsMainRed(mainId)
    -- 成就奖励未领取
    local isGet = self._Model:IsAchievementGet(mainId)
    if not isGet then
        local curCnt, maxCnt = self:GetMainAchievementProgress(mainId)
        if curCnt >= maxCnt then
            return true
        end
    end

    -- 总进度奖励未领取
    local mainCfg = self._Model:GetConfigMain(mainId)
    if mainCfg.TreasureId ~= 0 then
        local treasureCfg = self._Model:GetConfigTreasure(mainCfg.TreasureId)
        local passCnt, maxCnt = self._Model:GetMainProgress(mainId)
        local count = #treasureCfg.StageCounts
        for i, stageCount in ipairs(treasureCfg.StageCounts) do
            local isGet = self._Model:IsMainTreasureGet(mainId, i - 1)
            local isReach = passCnt >= stageCount
            if not isGet and isReach then
                return true
            end
        end
    end

    -- 章节进度奖励未领取
    local chapterIds = self._Model:GetMainChapterIds(mainId)
    for _, chapterId in ipairs(chapterIds) do
        if self:IsChapterRed(chapterId) then
            return true
        end
    end

    -- 时间蓝点
    if self:IsMainRedTimeIdShow(mainId) then
        return true
    end
    
    -- 任务蓝点
    if self:IsMainRedTaskReward(mainId) then
        return true
    end

    return false
end

-- 是否显示主章节时间红点
function XMainLine2Agency:IsMainRedTimeIdShow(mainId)
    local isPass = self:IsMainPassed(mainId)
    if isPass then
        return false
    end

    local timeId = self._Model:GetMainRedTimeId(mainId)
    if timeId == 0 then
        return false
    end

    -- 已移除红点
    local key = self:GetMainMainRedKey(mainId, timeId)
    local isRemove = XSaveTool.GetData(key) == true
    if isRemove then
        return false
    end

    -- 时间内
    local isInTime = XFunctionManager.CheckInTimeByTimeId(timeId)
    return isInTime
end

-- 移除主章节时间红点
function XMainLine2Agency:RemoveMainRedTimeIdShow(mainId)
    if self:IsMainRedTimeIdShow(mainId) then
        local timeId = self._Model:GetMainRedTimeId(mainId)
        local key = self:GetMainMainRedKey(mainId, timeId)
        XSaveTool.SaveData(key, true)
    end
end

function XMainLine2Agency:GetMainMainRedKey(mainId, timeId)
    return string.format("XMainLine2Main.tab_RedTimeId_%s_%s_%s", mainId, XPlayer.Id, timeId)
end

-- 蓝点：任务可领取奖励
function XMainLine2Agency:IsMainRedTaskReward(mainId)
    local taskGroupId = self:GetMainTaskGroupId(mainId)
    if XTool.IsNumberValidEx(taskGroupId) then
        return XDataCenter.TaskManager.CheckStoryTaskCanGet(taskGroupId)
    end
    return false
end

--- 章节是否存在
---@param chapterId number 章节Id
function XMainLine2Agency:IsChapterExit(chapterId)
    return self._Model:IsChapterExit(chapterId)
end

--- 章节是否通关
---@param chapterId number 章节Id
function XMainLine2Agency:IsChapterPassed(chapterId)
    return self._Model:IsChapterPassed(chapterId)
end

--- 章节是否解锁
---@param chapterId number 章节Id
function XMainLine2Agency:IsChapterUnlock(chapterId)
    return self._Model:IsChapterUnlock(chapterId)
end

--- 章节是否显示蓝点
---@param chapterId number 章节Id
function XMainLine2Agency:IsChapterRed(chapterId)
    return self._Model:IsChapterRed(chapterId)
end

--- 获取章节打的下一关入口
---@param chapterId number 章节Id
function XMainLine2Agency:GetChapterNextEntrance(chapterId)
    return self._Model:GetChapterNextEntrance(chapterId)
end

--- 获取章节Id
---@param mainId number 主章节Id
---@param difficultyId number 难度Id
function XMainLine2Agency:GetChapterId(mainId, difficultyId)
    return self._Model:GetChapterId(mainId, difficultyId)
end

--- 获取章节的主章节Id
---@param chapterId number 章节Id
function XMainLine2Agency:GetChapterMainId(chapterId, ignoreError)
    return self._Model:GetChapterMainId(chapterId, ignoreError)
end

-- 获取关卡的主章节Id
function XMainLine2Agency:GetStageMainId(stageId)
    local chapterId = self._Model:GetStageChapterId(stageId)
    return self:GetChapterMainId(chapterId, true)
end

-- 获取关卡的特殊字符
function XMainLine2Agency:GetStageSpecialorder(stageId)
    return self._Model:GetStageSpecialorder(stageId)
end

--- 获取关卡首通时间
---@param stageId number 关卡Id
function XMainLine2Agency:GetFirstPassTime(stageId)
    return self._Model:GetFirstPassTime(stageId)
end

--- 关卡是否存在
---@param stageId number 关卡Id
function XMainLine2Agency:IsStageExit(stageId)
    return self._Model:IsStageExit(stageId)
end

--- 获取关卡配置表
---@param stageId number 关卡Id
function XMainLine2Agency:GetConfigStage(stageId)
    return self._Model:GetConfigStage(stageId)
end

-- 获取关卡类型
function XMainLine2Agency:GetStageDetailType(stageId)
    return self._Model:GetStageDetailType(stageId)
end

--- 获取关卡对应章节成就图标
---@param stageId number 关卡Id
function XMainLine2Agency:GetStageChapterAchievementIcon(stageId)
    if not self:IsStageExit(stageId) then
        return
    end

    local chapterId = self._Model:GetStageChapterId(stageId)
    local mainId = self:GetChapterMainId(chapterId)
    local achievementId = self._Model:GetMainAchievementId(mainId)
    return self._Model:GetAchievementIcon(achievementId)
end

--- 获取关卡成就名称
---@param stageId number 关卡Id
---@param index number 成就下标，从1开始
function XMainLine2Agency:GetStageAchievementName(stageId, index)
    return self._Model:GetStageAchievementName(stageId, index)
end

--- 获取关卡成就完成情况
---@param stageId number 关卡Id
function XMainLine2Agency:GetStageAchievementMap(stageId)
    return self._Model:GetStageAchievementMap(stageId)
end

--- 获取关卡成就信息
---@param stageId number 关卡Id
---@param isFighting boolean 是否在战斗中
function XMainLine2Agency:GetStagesAchievementInfos(stageId, isFighting, isCombineStageGroup)
    return self._Model:GetStagesAchievementInfos(stageId, isFighting, isCombineStageGroup)
end

-- 获取关卡成就简短描述
---@param stageId number 关卡Id
---@param index number 成就下标，从1开始
function XMainLine2Agency:GetStageAchievementBriefDesc(stageId, index)
    return self._Model:GetStageAchievementBriefDesc(stageId, index)
end

--- 获取关卡是否通关
---@param stageId number 关卡Id
function XMainLine2Agency:IsStagePass(stageId)
    return self._Model:IsStagePass(stageId)
end

--- 关卡是否解锁
---@param stageId number 关卡Id
function XMainLine2Agency:IsStageUnlock(stageId)
    return self._Model:IsStageUnlock(stageId)
end

--- 关卡是否配置怪物上场
---@param stageId number 关卡Id
function XMainLine2Agency:IsStageMonster(stageId)
    local stageCfg = self:GetConfigStage(stageId)
    if #stageCfg.MonsterHeads > 0 then
        return true
    end

    return false
end

--- 关卡是否配置成就
---@param stageId number 关卡Id
function XMainLine2Agency:IsStageAchievement(stageId)
    local isCombine = self._Model:GetStageAchievementIsCombine(stageId)
    if isCombine then
        local stageIds = self._Model:GetStageStageIds(stageId)
        for _, tempStageId in ipairs(stageIds) do
            local stageCfg = self._Model:GetConfigStage(tempStageId)
            if #stageCfg.AchievementTpyes > 0 then
                return true
            end
        end
    else
        local stageCfg = self._Model:GetConfigStage(stageId)
        if #stageCfg.AchievementTpyes > 0 then
            return true
        end
    end

    return false
end

--- 获取关卡的通关进度
---@param stageId number 关卡Id
function XMainLine2Agency:GetStageProgress(stageId)
    return self._Model:GetStageProgress(stageId)
end

--- 获取关卡所在的关卡列表
---@param stageId number 关卡Id
---@return number[] 关卡Id列表
function XMainLine2Agency:GetStageStageIds(stageId)
    return self._Model:GetStageStageIds(stageId)
end

--- 关卡是否显示战中提示面板
---@param stageId number 关卡Id
function XMainLine2Agency:IsShowFightInstruction(stageId)
    if not self:IsStageMonster(stageId) then
        return true
    end
    if self:IsStageAchievement(stageId) then
        return true
    end

    return false
end

--- 获取成就完成情况
---@param achievement number 已完成成就 位字段
function XMainLine2Agency:GetAchievementMap(achievement)
    return self._Model:GetAchievementMap(achievement)
end

--- 获取客户端配置表参数
---@param key string 参数key
---@param index number 参数下标
function XMainLine2Agency:GetClientConfigParams(key, index)
    return self._Model:GetClientConfigParams(key, index)
end

function XMainLine2Agency:GetClientConfigNumberArray(key)
    return self._Model:GetClientConfigNumberArray(key)
end

-- 缓存主章节释放的数据
function XMainLine2Agency:CacheMainReleaseData(mainId, data)
    self._Model:CacheMainReleaseData(mainId, data)
end

-- 获取主章节上次释放时的数据
function XMainLine2Agency:GetMainReleaseData(mainId, isRemove)
    return self._Model:GetMainReleaseData(mainId, isRemove)
end

-- 获取主线界面新手主线锁定文本显示的condition
function XMainLine2Agency:GetClientNewbieMainLineLockCondition()
    return self._Model:GetClientConfigNumber('NewbieMainLineLockCondition')
end

--- 缓存关卡Id对应的章节Id
---@param stageId number 关卡Id
---@param chapterId number 章节Id
function XMainLine2Agency:CacheStageChapterId(stageId, chapterId)
    self._Model:CacheStageChapterId(stageId, chapterId)
end

--- 缓存关卡Id所在的组Id
---@param stageId number 关卡Id
---@param groupId number 关卡组Id
function XMainLine2Agency:CacheStageGroupId(stageId, groupId)
    self._Model:CacheStageGroupId(stageId, groupId)
end

--region Fuben
--- 开始战斗前获取数据
---@param stage XTableStage
function XMainLine2Agency:PreFight(stage, teamId, isAssist, challengeCount)
    local preFight = {}
    preFight.CardIds = { 0, 0, 0 }
    preFight.RobotIds = { 0, 0, 0 }
    preFight.StageId = stage.StageId
    preFight.IsHasAssist = isAssist and true or false
    preFight.ChallengeCount = challengeCount or 1

    local isRobotBlendStage = XMVCA.XFuben:GetConfigStageLineupType(stage.StageId)

    if not stage.RobotId or #stage.RobotId <= 0 or isRobotBlendStage then
        local teamData = nil
        ---@type XTeam
        local xteamData = isRobotBlendStage and XDataCenter.TeamManager.GetTempTeam(teamId) or XDataCenter.TeamManager.GetXTeam(teamId)

        if isRobotBlendStage then
            if xteamData then
                teamData = xteamData:GetEntityIds()
                preFight.CaptainPos = xteamData:GetCaptainPos()
                preFight.FirstFightPos = xteamData:GetFirstFightPos()
            end
        else
            teamData = XDataCenter.TeamManager.GetTeamData(teamId)
            preFight.CaptainPos = XDataCenter.TeamManager.GetTeamCaptainPos(teamId)
            preFight.FirstFightPos = XDataCenter.TeamManager.GetTeamFirstFightPos(teamId)
        end

        if not XTool.IsTableEmpty(teamData) then
            for i, v in pairs(teamData) do
                local isRobot = XEntityHelper.GetIsRobot(v)
                preFight.RobotIds[i] = isRobot and v or 0
                preFight.CardIds[i] = isRobot and 0 or v
            end
        end

    else
        for i, v in pairs(stage.RobotId) do
            preFight.RobotIds[i] = v
        end
        -- 设置默认值
        preFight.CaptainPos = 1
        preFight.FirstFightPos = 1
    end
    return preFight
end

-- 战斗胜利，弹结算界面
function XMainLine2Agency:ShowReward(winData)
    -- 记录章节最后打的关卡
    self._Model:SetLastPassStage(winData.StageId)
    -- 记录关卡首通时间
    self._Model:SetFirstPassTime(winData.StageId)

    ---@type XFubenAgency
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    local teleportInfo = fubenAgency:GetStageTeleportInfo()
    if teleportInfo then
        -- 跳转下一关战斗
        -- 打开黑幕避免进入战斗前打开关卡界面
        XLuaUiManager.Open("UiBiancaTheatreBlack")
        local team = XDataCenter.TeamManager.GetXTeamByStageId(teleportInfo.SkipStageId)
        local stageConfig = XMVCA.XFuben:GetStageCfg(teleportInfo.SkipStageId)
        team:UpdateEntityIds(XTool.Clone(stageConfig.RobotId))
        fubenAgency:EnterFightByStageId(teleportInfo.SkipStageId, team:GetId(), nil, nil, nil, function()
            XLuaUiManager.Remove("UiBiancaTheatreBlack")
        end)
    else
        -- 结算界面
        XLuaUiManager.Open("UiMainLine2Settlement", winData)
    end
end
--endregion


--region open ui

-- 打开章节UI界面
---@param mainId number 主章节Id
---@param chapterId number 章节Id
---@param stageId number 关卡Id
---@param isOpenStageDetail boolean 是否打开关卡详情
function XMainLine2Agency:OpenChapterUi(mainId, chapterId, stageId, isOpenStageDetail)
    if not XMVCA.XSubPackage:CheckSubpackage(XFunctionManager.FunctionName.MainLine, chapterId) then
        return
    end

    -- 章节未解锁
    if chapterId then
        local isUnlock, tips = self:IsChapterUnlock(chapterId)
        if not isUnlock then
            XUiManager.TipError(tips)
            return
        end
    end

    -- 主章节未解锁
    local isMainUnlock, mainTips = self:IsMainUnlock(mainId)
    if not isMainUnlock then
        XUiManager.TipError(mainTips)
        return
    end
    
    if self:OpenSpecialChapterUi(mainId) then
        return
    end

    XLuaUiManager.Open("UiMainLine2Chapter", mainId, chapterId, stageId, isOpenStageDetail)
    self:RemoveMainRedTimeIdShow(mainId)
end

function XMainLine2Agency:OpenSpecialChapterUi(mainId)
    if mainId == XEnumConst.MAINLINE2.SPECIAL_MAINID.LUOSAITA then
        XMVCA.XMainLineLuosaita:ExOpenMainUi()
        return true
    end
    return false
end

-- 通过关卡Id打开章节界面
---@param stageId number 关卡Id
function XMainLine2Agency:OpenChapterUiByStageId(stageId)
    local chapterId = self._Model:GetStageChapterId(stageId, true)
    if not chapterId then return end
    
    local mainId = self._Model:GetChapterMainId(chapterId, true)
    if not mainId then return end
    
    self:OpenChapterUi(mainId, chapterId, stageId)
end

--- 跳转接口
---@param chapterId number 章节Id
---@param stageId number 关卡Id
---@param isOpenStageDetail boolean 是否打开关卡详情
function XMainLine2Agency:SkipToMainLine2(chapterId, stageId, isOpenStageDetail)
    local mainId = self:GetChapterMainId(chapterId, true)
    self:OpenChapterUi(mainId, chapterId, stageId, isOpenStageDetail)
end

-- 获取主界面的进度展示
--- @return string progress 关卡进度
--- @return string difficult 难度
function XMainLine2Agency:GetUiMainProgress(mainId)
    local chapterIds = self._Model:GetMainChapterIds(mainId)
    local chapterCnt = #chapterIds

    -- 默认显示第一关进度
    local lastChapterId = chapterIds[1]
    local firstGroupId = self._Model:GetConfigChapter(lastChapterId).StageGroupIds[1]
    local lastStageId = self._Model:GetConfigStageGroup(firstGroupId).StageIds[1]

    for i, chapterId in ipairs(chapterIds) do
        -- 章节未全通/全通时取最后一章
        if not self:IsChapterPassed(chapterId) or i == chapterCnt then
            local chapterCfg = self._Model:GetConfigChapter(chapterId)
            for _, groupId in ipairs(chapterCfg.StageGroupIds) do
                local groupCfg = self._Model:GetConfigStageGroup(groupId)
                for _, stageId in ipairs(groupCfg.StageIds) do
                    local isIgnore = self._Model:IsStageIgnore(stageId)
                    if not isIgnore then
                        if self:IsStagePass(stageId) then
                            lastChapterId = chapterId
                            lastStageId = stageId
                        elseif self._Model:IsStageUnlock(stageId) and self._Model:IsStageShow(stageId) then
                            lastChapterId = chapterId
                            lastStageId = stageId
                            goto CONTINUE
                        end
                    end
                end
            end
        end
    end

    :: CONTINUE ::
    if lastStageId then
        local mainTitle = self._Model:GetMainTitle(mainId)
        local stageCfg = XMVCA.XFuben:GetStageCfg(lastStageId)
        local name = self._Model:GetChapterDifficultName(lastChapterId)
        local enName = self._Model:GetChapterDifficultEnName(lastChapterId)
        local progress = tostring(mainTitle) .. "-" .. tostring(stageCfg.OrderId)
        local difficult = tostring(enName) .. "：" .. tostring(name)
        return progress, difficult
    end
end

-- 点击成就按钮回调
function XMainLine2Agency:OnBtnAchievementClick(mainId, cb)
    local isGet = self._Model:IsAchievementGet(mainId)
    local curCnt, maxCnt = self:GetMainAchievementProgress(mainId)
    if not isGet and curCnt >= maxCnt then
        self:RequestReceiveAchievement(mainId, function()
            if cb then cb() end
        end)
    else
        local achievementId = self._Model:GetMainAchievementId(mainId)
        local rewardId = self._Model:GetAchievementClearRewardId(achievementId)
        local rewardList = XRewardManager.GetRewardList(rewardId)
        local itemTemplateId = rewardList[1].TemplateId
        local data = XDataCenter.MedalManager.GetScoreTitleById(itemTemplateId)
        XLuaUiManager.Open("UiCollectionTip", data, XDataCenter.MedalManager.InType.Normal)
    end
end
--endregion

--region 时间轴
-- 是否打开主线时间轴
function XMainLine2Agency:GetIsOpenExhibition()
    return self._Model:GetIsOpenExhibition()
end

-- 设置是否打开主线时间轴
function XMainLine2Agency:SetOpenExhibition(isOpen)
    self._Model:SetOpenExhibition(isOpen)
end

-- 获取时间轴模块配置
function XMainLine2Agency:GetConfigExhibitionModule(id)
    return self._Model:GetConfigExhibitionModule(id)
end

-- 获取时间轴章节配置
function XMainLine2Agency:GetConfigExhibitionChapter(id)
    return self._Model:GetConfigExhibitionChapter(id)
end

-- 获取时间轴的ViewModel
function XMainLine2Agency:GetExhibitionViewModel(mainId)
    local difficult = XDataCenter.FubenManager.DifficultNormal
    -- 旧主线
    local mainConfigs = XFubenMainLineConfigs.GetChapterMainTemplates()
    if mainConfigs[mainId] then
        return XDataCenter.FubenMainLineManager:ExGetChapterViewModelById(mainId, difficult)
    end
    -- 旧浮点纪实
    local storyConfigs = XFubenShortStoryChapterConfigs.GetShortStoryChapterCfg()
    if storyConfigs[mainId] then
        return XDataCenter.ShortStoryChapterManager:ExGetChapterViewModelById(mainId, difficult)
    end
    -- 新主线/新浮点纪实
    if XMVCA.XMainLine2:IsMainExit(mainId) then
        return XMVCA.XMainLine2:GetMain(mainId)
    end
end

-- 获取模块进度
function XMainLine2Agency:GetExhibitionModuleProgress(moduleId)
    local allCurrentProgress = 0
    local allMaxProgress = 0
    local moduleConfig = XMVCA.XMainLine2:GetConfigExhibitionModule(moduleId)
    for _, chapterId in ipairs(moduleConfig.ChapterIds) do
        local currentProgress, maxProgress = self:GetExhibitionChapterProgress(chapterId)
        allCurrentProgress = allCurrentProgress + currentProgress
        allMaxProgress = allMaxProgress + maxProgress
    end
    return allCurrentProgress, allMaxProgress
end

-- 获取章节进度
function XMainLine2Agency:GetExhibitionChapterProgress(exhibitionChapterId)
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(exhibitionChapterId)
    if chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE then
        local viewModel = self:GetExhibitionViewModel(chapterCfg.ExhibitionFubenConfigId)
        return self:GetViewModelCurrentAndMaxProgress(viewModel)
    end
    return 0, 0
end

-- 获取时间轴当前的模块下标和章节下标
function XMainLine2Agency:GetExhibitionCurrentModuleIndexAndChapterIndex()
    local moduleConfigs = self:GetConfigExhibitionModule()

    -- 最后战斗的时间轴章节Id
    local lastExhibitionChapterId = self:GetLastExhibitionChapterId()
    
    -- 第一个未通关主线
    local firstUnPassedModuleIndex
    local firstUnPassedChapterIndex
    
    for i, moduleConfig in ipairs(moduleConfigs) do
        for j, chapterId in ipairs(moduleConfig.ChapterIds) do
            if chapterId == lastExhibitionChapterId then
                return i, j
            end
            
            local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(chapterId)
            if chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE then
                ---@type XChapterViewModel
                local viewModel = self:GetExhibitionViewModel(chapterCfg.ExhibitionFubenConfigId)
                
                -- 限时开放关卡
                if viewModel:CheckHasTimeLimitTag() and not self:IsViewModelPassed(viewModel) then
                    return i, j
                end
                -- 获取第一个未通关主线
                if not firstUnPassedModuleIndex and not firstUnPassedChapterIndex and not self:IsViewModelPassed(viewModel) then
                    firstUnPassedModuleIndex = i
                    firstUnPassedChapterIndex = j
                end
            end
        end
    end

    -- 返回第一个未通关章节
    if firstUnPassedModuleIndex and firstUnPassedChapterIndex then
        return firstUnPassedModuleIndex, firstUnPassedChapterIndex

    -- 返回最后一个模块最后一个章节
    else
        local lastModuleIndex = #moduleConfigs
        local lastChapterIndex = #moduleConfigs[lastModuleIndex].ChapterIds
        return lastModuleIndex, lastChapterIndex
    end
end

-- viewModel是否已经通关
function XMainLine2Agency:IsViewModelPassed(viewModel)
    local currentProgress, maxProgress
    if viewModel:GetId() == XDataCenter.FubenMainLineManager.TRPGChapterId then
        currentProgress, maxProgress = XDataCenter.TRPGManager.GetCurrentAndMaxProgress()
    else
        currentProgress, maxProgress = viewModel:GetCurrentAndMaxProgress()
    end
    return currentProgress >= maxProgress
end

-- 获取viewModel当前和最大进度
function XMainLine2Agency:GetViewModelCurrentAndMaxProgress(viewModel)
    if viewModel:GetId() == XDataCenter.FubenMainLineManager.TRPGChapterId then
        return XDataCenter.TRPGManager.GetCurrentAndMaxProgress()
    else
        return viewModel:GetCurrentAndMaxProgress()
    end
end

-- 获取时间轴当前的章节下标
function XMainLine2Agency:GetExhibitionCurrentChapterIndex(moduleId)
    local moduleConfig = self:GetConfigExhibitionModule(moduleId)
    for j, chapterId in ipairs(moduleConfig.ChapterIds) do
        local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(chapterId)
        if chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE then
            local viewModel = self:GetExhibitionViewModel(chapterCfg.ExhibitionFubenConfigId)
            local currentProgress, maxProgress = viewModel:GetCurrentAndMaxProgress()
            if currentProgress < maxProgress then
                return j -- 返回第一个进度未达到100%的章节
            end
        end
    end
    -- 全通关返回第一个章节
    return 1
end

-- 打开时间轴内章节
function XMainLine2Agency:OpenExhibitionChapter(exhibitionChapterId)
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(exhibitionChapterId)
    local fubenConfigId = chapterCfg.ExhibitionFubenConfigId
    local difficult = XDataCenter.FubenManager.DifficultNormal
    if chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE then
        -- 旧主线
        local mainConfigs = XFubenMainLineConfigs.GetChapterMainTemplates()
        if mainConfigs[fubenConfigId] then
            local viewModel = XDataCenter.FubenMainLineManager:ExGetChapterViewModelById(fubenConfigId, difficult)
            XDataCenter.FubenMainLineManager:ExOpenChapterUi(viewModel, difficult)
            return
        end
        -- 旧浮点纪实
        local storyConfigs = XFubenShortStoryChapterConfigs.GetShortStoryChapterCfg()
        if storyConfigs[fubenConfigId] then
            local viewModel = XDataCenter.ShortStoryChapterManager:ExGetChapterViewModelById(fubenConfigId, difficult)
            XDataCenter.ShortStoryChapterManager:ExOpenChapterUi(viewModel)
            return
        end
        -- 新主线/新浮点纪实
        if XMVCA.XMainLine2:IsMainExit(fubenConfigId) then
            XMVCA.XMainLine2:OpenChapterUi(fubenConfigId)
            return
        end

    elseif chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.EXTRA then
        -- 外篇旧闻
        local viewModel = XDataCenter.ExtraChapterManager:ExGetChapterViewModelById(fubenConfigId, difficult)
        XDataCenter.ExtraChapterManager:ExOpenChapterUi(viewModel, difficult)

    elseif chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.CHALLENGE then
        -- 多维演绎
        local challengeBannerConfig = XMVCA.XFuben:GetNewChallengeConfigById(fubenConfigId)
        local manager = XDataCenter.FubenManagerEx.GetManagers(challengeBannerConfig.Type)
        manager[1]:ExOpenMainUi()
    end
end

-- 时间轴章节是否完成
function XMainLine2Agency:IsExhibitionChapterCompleted(exhibitionChapterId)
    local chapterCfg = XMVCA.XMainLine2:GetConfigExhibitionChapter(exhibitionChapterId)
    local mainId = chapterCfg.ExhibitionFubenConfigId
    local difficult = XDataCenter.FubenManager.DifficultNormal
    
    local viewModel
    if chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE then
        -- 主线/浮点纪实
        viewModel = XMVCA.XMainLine2:GetExhibitionViewModel(mainId)
    elseif chapterCfg.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.EXTRA then
        -- 外篇旧闻
        viewModel = XDataCenter.ExtraChapterManager:ExGetChapterViewModelById(mainId, difficult)
    end

    if viewModel then
        local currentProgress, maxProgress = viewModel:GetCurrentAndMaxProgress()
        local isCompleted = currentProgress >= maxProgress
        return isCompleted
    end
    
    return true
end

-- 时间轴章节的前置章节是否完成
function XMainLine2Agency:IsExhibitionChapterPreCompleted(chapterId)
    local config = self:GetConfigExhibitionChapter(chapterId)
    if #config.PreIds == 0 then return true end

    for _, preId in pairs(config.PreIds) do
        local isCompleted = self:IsExhibitionChapterCompleted(preId)
        if not isCompleted then
            return false
        end
    end
    return true
end

-- 设置UiMainLineExhibitionPopupChapter本次登陆不再弹出
function XMainLine2Agency:SetIgnoreUiExhibitionPopupChapter(isIgnore)
    self._Model:SetIgnoreUiExhibitionPopupChapter(isIgnore)
end

-- 获取UiMainLineExhibitionPopupChapter本次登陆能否再弹出
function XMainLine2Agency:GetIsIgnoreUiExhibitionPopupChapter()
    return self._Model:GetIsIgnoreUiExhibitionPopupChapter()
end

-- 设置最后进入的时间轴章节(多维演绎)
function XMainLine2Agency:SetLastExhibitionChapterByChapterType(chapterType)
    local configs = self:GetConfigExhibitionChapter()
    for _, config in pairs(configs) do
        -- 多维演绎
        if config.ExhibitionFubenType == XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.CHALLENGE then
            local challengeBannerConfig = XMVCA.XFuben:GetNewChallengeConfigById(config.ExhibitionFubenConfigId)
            if challengeBannerConfig.Type == chapterType then
                self:SetLastExhibitionChapter(config.Id)
                return
            end
        end
    end
end

-- 设置最后进入的时间轴章节(主线+浮点纪实+外篇旧闻)
function XMainLine2Agency:SetLastExhibitionChapterByStageId(stageId)
    local stageConfig = XMVCA.XFuben:GetStageCfg(stageId)
    if stageConfig.Type == XEnumConst.FuBen.StageType.Mainline then
        local mainId = XFubenMainLineConfigs.GetStageMainId(stageId)
        local exhibitionChapterId = self:GetExhibitionChapterIdByFubenData(XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE, mainId)
        if exhibitionChapterId then -- 部分旧主线不配置在时间轴
            self:SetLastExhibitionChapter(exhibitionChapterId)
        end
    elseif stageConfig.Type == XEnumConst.FuBen.StageType.ShortStory then
        local mainId, chapterId = XFubenShortStoryChapterConfigs.GetStageMainId(stageId)
        local exhibitionChapterId = self:GetExhibitionChapterIdByFubenData(XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE, mainId)
        self:SetLastExhibitionChapter(exhibitionChapterId)
    elseif stageConfig.Type == XEnumConst.FuBen.StageType.Mainline2 then
        local mainId = self:GetStageMainId(stageId)
        local exhibitionChapterId = self:GetExhibitionChapterIdByFubenData(XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE, mainId)
        self:SetLastExhibitionChapter(exhibitionChapterId)
    elseif stageConfig.Type == XEnumConst.FuBen.StageType.ExtraChapter then
        local mainId, chapterId = XFubenExtraChapterConfigs.GetStageMainId(stageId)
        local exhibitionChapterId = self:GetExhibitionChapterIdByFubenData(XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.EXTRA, mainId)
        self:SetLastExhibitionChapter(exhibitionChapterId)
    else
        return -- 时间轴未包括
    end
end

-- 设置最后进入的时间轴章节(主线+浮点纪实+外篇旧闻)
function XMainLine2Agency:SetEnterExhibitionChapterTRPG()
    local exhibitionChapterId = self:GetExhibitionChapterIdByFubenData(XEnumConst.MAINLINE2.EXHIBITION_FUBEN_TYPE.MAINLINE, XEnumConst.MAINLINE2.SPECIAL_MAINID.THIRTEENTH)
    self:SetLastExhibitionChapter(exhibitionChapterId)
end

-- 设置最后进入的时间轴章节
function XMainLine2Agency:SetLastExhibitionChapter(exhibitionChapterId)
    local lastId = self._Model:GetLastExhibitionChapterId()
    if lastId ~= exhibitionChapterId and exhibitionChapterId then
        local req = { ChapterId = exhibitionChapterId }
        XNetwork.CallWithAutoHandleErrorCode("MainLine2UpdateExhibitionChapterRequest", req, function(res)
            self._Model:SetLastExhibitionChapterId(exhibitionChapterId)
        end)
    end
end

function XMainLine2Agency:GetExhibitionChapterIdByFubenData(exhibitionFubenType, exhibitionFubenConfigId)
    local configs = self:GetConfigExhibitionChapter()
    for _, config in pairs(configs) do
        if config.ExhibitionFubenType == exhibitionFubenType and config.ExhibitionFubenConfigId == exhibitionFubenConfigId then
            return config.Id
        end
    end
end

-- 获取最后进入的时间轴章节Id
function XMainLine2Agency:GetLastExhibitionChapterId()
    return self._Model:GetLastExhibitionChapterId()
end

--endregion

--region 旧主线
-- UiFubenMainLineChapter界面，进战斗前缓存数据
function XMainLine2Agency:OnReleaseInstUiFubenMainLineChapter(data)
    self._Model:OnReleaseInstUiFubenMainLineChapter(data)
end

-- UiFubenMainLineChapter界面，战斗结束后获取缓存数据
function XMainLine2Agency:OnResumeUiFubenMainLineChapter()
    return self._Model:OnResumeUiFubenMainLineChapter()
end

function XMainLine2Agency:ClearCacheDatasUiFubenMainLineChapter()
    self._Model:ClearCacheDatasUiFubenMainLineChapter()
end
--endregion

-- 埋点进入章节的方式
function XMainLine2Agency:RecordEnterChapterWay(way)
    local dict = {}
    dict["way"] = way
    CS.XRecord.Record(dict, "200023", "EnterChapterWay")
end

--region 彩蛋功能
-- 检测是否打开彩蛋弹窗功能
function XMainLine2Agency:CheckOpenUiEggsTreasureTips(chapterId)
    if XLuaUiManager.IsUiLoad("UiMainLine2EggsTreasureTips") or XLuaUiManager.IsUiLoad("UiMainLine2EggsTreasureMail") then
        return
    end
    
    local eggIds = self._Model:GetChapterEggIds(chapterId)
    for _, eggId in pairs(eggIds) do
        if not self._Model:IsEggGet(eggId) then
            local conditionId = self._Model:GetEggConditionId(eggId)
            local isReach, desc = XConditionManager.CheckCondition(conditionId)
            if isReach then
                XLuaUiManager.Open("UiMainLine2EggsTreasureTips", chapterId, eggId)
                return
            end
        end
    end
end
--endregion

return XMainLine2Agency