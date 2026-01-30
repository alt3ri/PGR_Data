local XPassportBaseInfo = require("XEntity/XPassport/XPassportBaseInfo")
local XPassportCombInfo = require("XCrossVersion/XEntity/XPassportCombInfo")

local tableInsert = table.insert
local tableSort = table.sort
local pairs = pairs

local TableKey = {
    CombPassportActivity = { CacheType = XConfigUtil.CacheType.Normal },
    CombPassportLevel = { CacheType = XConfigUtil.CacheType.Normal },
    CombPassportReward = { CacheType = XConfigUtil.CacheType.Normal },
    CombPassportTypeInfo = { CacheType = XConfigUtil.CacheType.Normal },
    CombPassportTaskGroup = { CacheType = XConfigUtil.CacheType.Normal },
    CombPassportBuyFashionShow = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "PassportId" },
    CombPassportBuyRewardShow = { DirPath = XConfigUtil.DirectoryType.Client },
}

---@class XPassportModel : XModel
local XPassportCombModel = XClass(XModel, "XPassportCombModel")

function XPassportCombModel:OnInit()
    self._ConfigUtil:InitConfigByTableKey("CombPassport", TableKey)

    self._PassportActivityIdToLevelIdList = nil
    self._PassportRewardIdDic = {}
    self._PassportActivityIdToTypeInfoIdList = nil
    self._PassportActivityAndLevelToLevelIdDic = nil
    self._PassportIdToPassportRewardIdList = nil
    self._PassportIdToBuyRewardShowIdList = nil
    self._LevelIdListSeparate = {}

    self._DefaultActivityId = 1
    self.PayCallBack = nil

    ---@type XPassportBaseInfo
    self._BaseInfo = XPassportBaseInfo.New()            --基础信息
    ---@type XPassportInfo[]
    self._PassportInfosDic = {}                         --已解锁通行证字典
    ---@type XPassportBaseInfo[]
    self._LastTimeBaseInfo = XPassportBaseInfo.New()    --上一期活动基础信息
    self.CurrMainViewSelectTagIndex = nil              --缓存主界面选择的页签
end

function XPassportCombModel:Init()
    self:_InitPassportActivityId()
    --self:_InitPassportActivityIdToLevelIdList()
    self:_InitPassportRewardIdDic()
    --self:_InitPassportActivityAndLevelToLevelIdDic()
    --self:_InitPassportIdToBuyRewardShowIdList()
end

function XPassportCombModel:ClearPrivate()
    self._PassportRewardIdDic = {}
    self._PassportActivityAndLevelToLevelIdDic = nil
    self._PassportIdToBuyRewardShowIdList = nil
    self._LevelIdListSeparate = {}
end

function XPassportCombModel:ResetAll()
    self._PassportActivityIdToTypeInfoIdList = nil
    self._PassportIdToPassportRewardIdList = nil
    -- temp
    self._DefaultActivityId = 1
    self._BaseInfo = XPassportBaseInfo.New()
    self._PassportInfosDic = {}
    self._LastTimeBaseInfo = XPassportBaseInfo.New()
    self.CurrMainViewSelectTagIndex = nil
end

----------public start----------


----------public end----------

----------private start----------


----------private end----------

--region config start
function XPassportCombModel:_InitPassportActivityId()
    if self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CombPassportActivity, self._DefaultActivityId) then
        return
    end
    local configs = self._ConfigUtil:GetByTableKey(TableKey.CombPassportActivity)
    for activityId, config in pairs(configs) do
        if XTool.IsNumberValid(config.TimeId) then
            self._DefaultActivityId = activityId
            break
        end
        self._DefaultActivityId = activityId
    end
end

function XPassportCombModel:_InitPassportActivityIdToLevelIdList()
    if not self._PassportActivityIdToLevelIdList then
        self._PassportActivityIdToLevelIdList = {}
        local configs = self._ConfigUtil:GetByTableKey(TableKey.CombPassportLevel)
        for _, v in pairs(configs) do
            if not self._PassportActivityIdToLevelIdList[v.ActivityId] then
                self._PassportActivityIdToLevelIdList[v.ActivityId] = {}
            end
            tableInsert(self._PassportActivityIdToLevelIdList[v.ActivityId], v.Id)
        end

        local sortFunc = function(a, b)
            return a < b
        end
        for _, idList in pairs(self._PassportActivityIdToLevelIdList) do
            tableSort(idList, sortFunc)
        end
    end
end

function XPassportCombModel:_InitPassportRewardIdDic()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.CombPassportReward)
    for _, v in pairs(configs) do
        if not self._PassportRewardIdDic[v.PassportId] then
            self._PassportRewardIdDic[v.PassportId] = {}
        end
        self._PassportRewardIdDic[v.PassportId][v.Level] = v.Id
    end
end

function XPassportCombModel:_InitPassportIdToPassportRewardIdList(passportId)
    self._PassportIdToPassportRewardIdList = self._PassportIdToPassportRewardIdList or {}
    local configs = self._ConfigUtil:GetByTableKey(TableKey.CombPassportReward)
    for _, v in pairs(configs) do
        if passportId == v.PassportId then
            if not self._PassportIdToPassportRewardIdList[v.PassportId] then
                self._PassportIdToPassportRewardIdList[v.PassportId] = {}
            end
            tableInsert(self._PassportIdToPassportRewardIdList[v.PassportId], v.Id)
        end
    end

    local sortFunc = function(a, b)
        local levelA = self:GetPassportRewardLevel(a)
        local levelB = self:GetPassportRewardLevel(b)
        if levelA ~= levelB then
            return levelA < levelB
        end
        return a < b
    end
    local idList = self._PassportIdToPassportRewardIdList[passportId]
    if idList then
        tableSort(idList, sortFunc)
    end
end

function XPassportCombModel:_InitPassportActivityIdToTypeInfoIdList()
    self._PassportActivityIdToTypeInfoIdList = {}
    local configs = self._ConfigUtil:GetByTableKey(TableKey.CombPassportTypeInfo)
    for _, v in pairs(configs) do
        if not self._PassportActivityIdToTypeInfoIdList[v.ActivityId] then
            self._PassportActivityIdToTypeInfoIdList[v.ActivityId] = {}
        end
        tableInsert(self._PassportActivityIdToTypeInfoIdList[v.ActivityId], v.Id)
    end

    local sortFunc = function(a, b)
        return a < b
    end
    for _, idList in pairs(self._PassportActivityIdToTypeInfoIdList) do
        tableSort(idList, sortFunc)
    end
end

function XPassportCombModel:_InitPassportActivityAndLevelToLevelIdDic()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.CombPassportLevel)
    self._PassportActivityAndLevelToLevelIdDic = {}
    for _, v in pairs(configs) do
        if not self._PassportActivityAndLevelToLevelIdDic[v.ActivityId] then
            self._PassportActivityAndLevelToLevelIdDic[v.ActivityId] = {}
        end
        self._PassportActivityAndLevelToLevelIdDic[v.ActivityId][v.Level] = v.Id
    end
end

function XPassportCombModel:_InitPassportIdToBuyRewardShowIdList()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.CombPassportBuyRewardShow)
    self._PassportIdToBuyRewardShowIdList = {}
    for _, v in pairs(configs) do
        if not self._PassportIdToBuyRewardShowIdList[v.PassportId] then
            self._PassportIdToBuyRewardShowIdList[v.PassportId] = {}
        end
        if XTool.IsNumberValid(v.Id) then
            tableInsert(self._PassportIdToBuyRewardShowIdList[v.PassportId], v.Id)
        end
    end

    local sortFunc = function(a, b)
        local levelA = self:GetPassportBuyRewardShowLevel(a)
        local levelB = self:GetPassportBuyRewardShowLevel(b)
        if levelA ~= levelB then
            return levelA > levelB
        end
        return a < b
    end
    for _, idList in pairs(self._PassportIdToBuyRewardShowIdList) do
        tableSort(idList, sortFunc)
    end
end

function XPassportCombModel:GetDefaultActivityId()
    return self._DefaultActivityId
end

function XPassportCombModel:SetDefaultActivityId(value)
    self._DefaultActivityId = value
end

function XPassportCombModel:SetPayCallBack(value)
    self.PayCallBack = value
end

function XPassportCombModel:GetPassportActivityConfig(id)
    if id == 0 then
        return nil
    end
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CombPassportActivity, id)
    return config
end
--endregion config

--region notify
function XPassportCombModel:NotifyPassportData(data)
    self:SetDefaultActivityId(data.ActivityId)
    self._BaseInfo:SetToLevel(data.Level or data.BaseInfo.Level)
    self._LastTimeBaseInfo:UpdateData(data.LastTimeBaseInfo)
    self:UpdatePassportInfosDic(data.CombPassportInfos)
    XEventManager.DispatchEvent(XEventId.EVENT_NOTIFY_PASSPORT_DATA)
end

function XPassportCombModel:NotifyPassportBaseInfo(data)
    self._BaseInfo:UpdateData(data.Level or data.BaseInfo.Level)
    XEventManager.DispatchEvent(XEventId.EVENT_NOTIFY_PASSPORT_BASE_INFO)
end

--endregion notify

---------------------本地接口 begin------------------
function XPassportCombModel:UpdatePassportInfosDic(passportInfos)
    if not passportInfos then
        return
    end
    ---@type XPassportCombInfo
    local passportInfo
    for _, data in pairs(passportInfos) do
        passportInfo = self._PassportInfosDic[data.Id]
        if not passportInfo then
            passportInfo = XPassportCombInfo.New()
            self._PassportInfosDic[data.Id] = passportInfo
        end
        passportInfo:UpdateData(data)
    end
end

function XPassportCombModel:SetPassportReceiveReward(passportId, passportRewardId)
    local passportInfo = self:GetPassportInfos(passportId)
    if passportInfo then
        passportInfo:SetReceiveReward(passportRewardId)
    end
end
---------------------本地接口 end------------------

function XPassportCombModel:GetPassportLevelConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CombPassportLevel, id)
    return config
end

function XPassportCombModel:GetPassportLevelIdList(activityId)
    self:_InitPassportActivityIdToLevelIdList()
    return self._PassportActivityIdToLevelIdList[activityId] or {}
end

function XPassportCombModel:GetPassportLevelId(level)
    local activityId = self:GetDefaultActivityId()
    if not self._PassportActivityAndLevelToLevelIdDic then
        self:_InitPassportActivityAndLevelToLevelIdDic()
    end
    return self._PassportActivityAndLevelToLevelIdDic[activityId] and self._PassportActivityAndLevelToLevelIdDic[activityId][level]
end

function XPassportCombModel:GetPassportRewardConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CombPassportReward, id)
    return config
end

function XPassportCombModel:GetPassportRewardIdList(passportId)
    if not self._PassportIdToPassportRewardIdList or not self._PassportIdToPassportRewardIdList[passportId] then
        self:_InitPassportIdToPassportRewardIdList(passportId)
    end
    if not self._PassportIdToPassportRewardIdList[passportId] then
        XLog.Error("[XPassportModel] GetPassportRewardIdList empty")
    end
    return self._PassportIdToPassportRewardIdList[passportId] or {}
end

--获得奖励表的id
function XPassportCombModel:GetRewardIdByPassportIdAndLevel(passportId, level)
    return self._PassportRewardIdDic[passportId] and self._PassportRewardIdDic[passportId][level]
end

function XPassportCombModel:GetPassportActivityIdToTypeInfoIdList()
    local activityId = self:GetDefaultActivityId()
    if not self._PassportActivityIdToTypeInfoIdList then
        self:_InitPassportActivityIdToTypeInfoIdList()
    end
    return self._PassportActivityIdToTypeInfoIdList[activityId]
end

function XPassportCombModel:GetPassportTypeInfoConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CombPassportTypeInfo, id)
    return config
end

function XPassportCombModel:GetPassportTaskGroupConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CombPassportTaskGroup, id)
    return config
end

function XPassportCombModel:GetPassportTaskGroupConfigs()
    local configs = self._ConfigUtil:GetByTableKey(TableKey.CombPassportTaskGroup)
    return configs
end

function XPassportCombModel:GetPassportBuyFashionShowConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CombPassportBuyFashionShow, id)
    return config
end

function XPassportCombModel:GetPassportBuyRewardShowConfig(id)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.CombPassportBuyRewardShow, id)
    return config
end

function XPassportCombModel:GetBuyRewardShowIdList(passportId)
    if not self._PassportIdToBuyRewardShowIdList then
        self:_InitPassportIdToBuyRewardShowIdList()
    end
    return self._PassportIdToBuyRewardShowIdList[passportId] or {}
end

function XPassportCombModel:GetLevelIdListSeparate()
    return self._LevelIdListSeparate
end

function XPassportCombModel:GetPassportInfos(passportId)
    return self._PassportInfosDic[passportId]
end

function XPassportCombModel:GetBaseInfo()
    return self._BaseInfo
end

function XPassportCombModel:GetLastTimeBaseInfo()
    return self._LastTimeBaseInfo
end

function XPassportCombModel:GetAutoGetTaskRewardListCookieKey()
    local activityId = self:GetDefaultActivityId()
    return XPlayer.Id .. "_XPassport_AutoGetTaskRewardList" .. activityId
end

function XPassportCombModel:InsertCookieAutoGetTaskRewardList(rewardList)
    local key = self:GetAutoGetTaskRewardListCookieKey()
    local cookieRewardList = self:GetCookieAutoGetTaskRewardList()
    if cookieRewardList then
        for _, rewardData in ipairs(rewardList) do
            table.insert(cookieRewardList, rewardData)
        end
    end
    XSaveTool.SaveData(key, cookieRewardList or rewardList)
end

function XPassportCombModel:GetCookieAutoGetTaskRewardList()
    local key = self:GetAutoGetTaskRewardListCookieKey()
    return XSaveTool.GetData(key)
end

--通知自动领取任务奖励列表
function XPassportCombModel:NotifyPassportAutoGetTaskReward(data)
    self:InsertCookieAutoGetTaskRewardList(data.RewardList or {})
    XEventManager.DispatchEvent(XEventId.EVENT_AUTO_GET_TASK_REWARD_LIST)
end

--检查活动没开回主界面
function XPassportCombModel:CheckActivityIsOpen(isNotRunMain)
    local timeId = self:GetPassportActivityTimeId()
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        if CS.XFight.IsRunning or XLuaUiManager.IsUiLoad("UiLoading") then
            return false
        end

        XUiManager.TipText("ActivityMainLineEnd")
        if not isNotRunMain then
            XLuaUiManager.RunMain()
        end
        return false
    end
    return true
end

function XPassportCombModel:GetPassportActivityTimeId()
    local activityId = self:GetDefaultActivityId()
    if activityId == 1 or activityId == 0 then
        return 0
    end
    local config = self:GetPassportActivityConfig(activityId)
    return config.TimeId
end

function XPassportCombModel:GetPassportMaxLevel()
    local activityId = self:GetDefaultActivityId()
    local levelIdList = self:GetPassportLevelIdList(activityId)
    local maxLevel = 0
    local levelCfg
    for _, levelId in ipairs(levelIdList) do
        levelCfg = self:GetPassportLevel(levelId)
        if levelCfg > maxLevel then
            maxLevel = levelCfg
        end
    end
    return maxLevel
end

function XPassportCombModel:GetPassportLevel(id)
    local config = self:GetPassportLevelConfig(id)
    return config.Level
end

--活动是否已结束
function XPassportCombModel:IsActivityClose()
    local nowServerTime = XTime.GetServerNowTimestamp()
    local timeId = self:GetPassportActivityTimeId()
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    return nowServerTime >= endTime
end

function XPassportCombModel:CheckPassportAchievedTaskRedPoint(taskType)
    local taskIdList = taskType == XEnumConst.PASSPORT.TASK_TYPE.ACTIVITY and self:GetPassportBPTask()
            or self:GetPassportTaskGroupCurrOpenTaskIdList(taskType)
    for _, taskId in pairs(taskIdList) do
        if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
            return true
        end
    end
    return false
end

function XPassportCombModel:GetPassportBPTask()
    local activityId = self:GetDefaultActivityId()
    local config = self:GetPassportActivityConfig(activityId)
    return config and config.BPTask or {}
end

function XPassportCombModel:GetPassportTaskGroupCurrOpenTaskIdList(type)
    for _, v in pairs(self:GetPassportTaskGroupConfigs()) do
        if v.Type == type and XFunctionManager.CheckInTimeByTimeId(v.TimeId) then
            return self:GetPassportTaskGroupTaskIdList(v.Id)
        end
    end
    return {}
end

function XPassportCombModel:GetPassportTaskGroupTaskIdList(id)
    local config = self:GetPassportTaskGroupConfig(id)
    return config.TaskId
end

--通行证检查是否可领取等级奖励
function XPassportCombModel:CheckPassportRewardRedPoint()
    local baseInfo = self._BaseInfo
    local currLevel = baseInfo:GetLevel()
    local typeInfoIdList = self:GetPassportActivityIdToTypeInfoIdList()
    local passportRewardIdList
    local levelCfg

    for _, passportId in ipairs(typeInfoIdList) do
        if self:GetPassportInfos(passportId) then
            passportRewardIdList = self:GetPassportRewardIdList(passportId)
            for _, passportRewardId in ipairs(passportRewardIdList) do
                levelCfg = self:GetPassportRewardLevel(passportRewardId)
                if currLevel < levelCfg then
                    break
                end
                if not self:IsReceiveReward(passportId, passportRewardId) then
                    return true
                end
            end
        end
    end
    return false
end

function XPassportCombModel:GetPassportRewardLevel(id)
    local config = self:GetPassportRewardConfig(id)
    return config.Level
end

--是否已领取奖励
function XPassportCombModel:IsReceiveReward(passportId, passportRewardId)
    local rewardId = self:GetPassportRewardId(passportRewardId)
    if not XTool.IsNumberValid(rewardId) then
        --没配置奖励作已领取处理
        return true
    end

    local passportInfo = self:GetPassportInfos(passportId)
    return passportInfo and passportInfo:IsReceiveReward(passportRewardId)
end

function XPassportCombModel:GetPassportRewardId(id)
    local config = self:GetPassportRewardConfig(id)
    return config.RewardId
end

function XPassportCombModel:GetPassportBuyRewardShowLevel(id)
    local config = self:GetPassportBuyRewardShowConfig(id)
    return config.Level
end

function XPassportCombModel:IsPassportTargetLevel(id)
    local config = self:GetPassportLevelConfig(id)
    return XTool.IsNumberValid(config.IsTargetLevel)
end

function XPassportCombModel:GetPassportBuyTimes(passportId)
    local passportInfo = self:GetPassportInfos(passportId)
    if not passportInfo then
        return 0
    end
    return passportInfo:GetBuyTimes()
end

return XPassportCombModel