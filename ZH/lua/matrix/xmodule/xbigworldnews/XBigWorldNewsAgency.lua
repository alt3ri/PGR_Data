---@class XBigWorldNewsAgency : XAgency
---@field private _Model XBigWorldNewsModel
local XBigWorldNewsAgency = XClass(XAgency, "XBigWorldNewsAgency")
function XBigWorldNewsAgency:OnInit()
    self.NewsType = {
        Overview = 1, --版本概况
        Quest = 2,    --版本任务
    }

    self._PanelUiType = {}
end

function XBigWorldNewsAgency:InitRpc()
end

function XBigWorldNewsAgency:InitEvent()
    self:AddAgencyEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_FINISH, self.CheckAutoPopup, self)
    XMVCA.XBigWorldFunction:AddEnterOperateHandler(XMVCA.XBigWorldFunction.EnterOperateType.OpenNews,
        self.TryOpenNewsUiAndMarkPopped, self)
end

function XBigWorldNewsAgency:RemoveEvent()
    self:RemoveAgencyEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_FINISH, self.CheckAutoPopup, self)
end

function XBigWorldNewsAgency:InitPopupNews(data)
    self._Model:InitPopupNews(data)
end

---@return XUiPanelBWNewsBase
function XBigWorldNewsAgency:CreatePanelUiClass(newsId, ui, parent)
    local type = self:GetNewsType(newsId)
    local uiClass = self._PanelUiType[type]

    if not uiClass then
        uiClass = self:GetPanelUiClass(type)

        self._PanelUiType[type] = uiClass
    end

    return uiClass.New(ui, parent)
end

function XBigWorldNewsAgency:GetPanelUiClass(type)
    if type == self.NewsType.Overview then
        return require("XUi/XUiBigWorld/XNews/Panel/XUiPanelBWNewsOverview")
    elseif type == self.NewsType.Quest then
        return require("XUi/XUiBigWorld/XNews/Panel/XUiPanelBWNewsQuest")
    else
        XLog.Error("[新闻] : 找不到对应的类型 Type = " .. tostring(type))
        return require("XUi/XUiBigWorld/XNews/Panel/XUiPanelBWNewsBase")
    end
end

function XBigWorldNewsAgency:CheckAutoPopup(targetNewsId)
    if XMVCA.XBigWorldGamePlay:IsInstLevel() then
        return false
    end
    if not XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.BigWorldNews, true, true) then
        return false
    end

    local newsIds = self:GetNewsIds()
    local popupIds = { targetNewsId }

    for _, newsId in pairs(newsIds) do
        if self:CheckNewsPopup(newsId) then
            table.insert(popupIds, newsId)
        end
    end

    if not XTool.IsTableEmpty(popupIds) then
        self:RequestMarkNewsPopped(popupIds)
        self._Model:SetMultipleNewsPopup(popupIds)
        self:OpenNewsUi(popupIds[1])
        return true
    end

    return false
end

function XBigWorldNewsAgency:OpenNewsUi(newsId, isActiveClick)
    if not XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.BigWorldNews, true) then
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldPopupNews", newsId)
end

function XBigWorldNewsAgency:CheckNewsPopup(newsId)
    if self._Model:CheckNewsPopup(newsId) then
        return false
    end
    if not self:CheckPopupCondition(newsId) then
        return false
    end
    local conditionId = self:GetNewsUnlockCondition(newsId)
    if conditionId and conditionId > 0 and not XMVCA.XBigWorldService:CheckCondition(conditionId) then
        return false
    end
    if not self:CheckNewsInTime(newsId) then
        return false
    end

    return true
end

function XBigWorldNewsAgency:TryOpenNewsUiAndMarkPopped(newsId)
    self:CheckAutoPopup(newsId)
end

function XBigWorldNewsAgency:RequestMarkNewsPopped(newsIds, func)
    if not XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.BigWorldNews, true, true) then
        return
    end

    if XTool.IsTableEmpty(newsIds) then
        return
    end

    XNetwork.Call("BigWorldNewsMarkPopupRequest", { NewsIds = newsIds }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetMultipleNewsPopup(res.MarkedNewsIds)

        if func then func() end
    end)
end

--region 读取配置

function XBigWorldNewsAgency:GetNewsIds()
    return self._Model:GetNewsIds()
end

function XBigWorldNewsAgency:FilterNewsIds(newsIds)
    if XTool.IsTableEmpty(newsIds) then
        return newsIds
    end

    local list = {}
    local index = 0

    for _, newsId in pairs(newsIds) do
        local passed = true
        local conditionId = XMVCA.XBigWorldNews:GetNewsUnlockCondition(newsId)

        if conditionId and conditionId > 0 then
            passed = XMVCA.XBigWorldService:CheckCondition(conditionId)
        end
        if passed then
            index = index + 1
            list[index] = newsId
        end
    end

    return list
end

function XBigWorldNewsAgency:GetFilteredNewsIds()
    return self:FilterNewsIds(self:GetNewsIds())
end

function XBigWorldNewsAgency:GetNewsType(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.Type
end

function XBigWorldNewsAgency:GetNewsName(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.Name
end

function XBigWorldNewsAgency:GetNewsTitle(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.Title
end

function XBigWorldNewsAgency:GetNewsContent(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.Content
end

function XBigWorldNewsAgency:GetNewsPriority(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.Priority
end

function XBigWorldNewsAgency:GetNewsShowReward(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.ShowReward
end

function XBigWorldNewsAgency:GetNewsUnlockCondition(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.UnlockCondition
end

function XBigWorldNewsAgency:GetNewsEarlyAccessCondition(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.EarlyAccessCondition
end

function XBigWorldNewsAgency:CheckEarlyAccessCondition(id)
    local conditionId = self:GetNewsEarlyAccessCondition(id)

    if XTool.IsNumberValid(conditionId) then
        return XMVCA.XBigWorldService:CheckCondition(conditionId)
    end

    return true
end

function XBigWorldNewsAgency:GetPopupCondition(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.PopupCondition
end

function XBigWorldNewsAgency:CheckPopupCondition(id)
    local conditionId = self:GetPopupCondition(id)
    if not conditionId or conditionId <= 0 then
        return false
    end
    local passed, _ = XMVCA.XBigWorldService:CheckCondition(conditionId)
    return passed
end

function XBigWorldNewsAgency:GetNewsBgPic(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.BgPic
end

function XBigWorldNewsAgency:GetNewsSpineBanner(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.SpineBanner
end

function XBigWorldNewsAgency:GetNewsSkipId(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.SkipId
end

function XBigWorldNewsAgency:GetNewsTaskGroupId(id)
    local t = self._Model:GetNewsTemplate(id)

    return t.TaskGroupId or 0
end

function XBigWorldNewsAgency:GetNewsShowTimeId(id)
    local t = self._Model:GetNewsTemplate(id)

    return t.ShowTimeId or 0
end

function XBigWorldNewsAgency:GetNewsShowCountDown(id)
    local t = self._Model:GetNewsTemplate(id)

    return t.ShowCountDown or 0
end

function XBigWorldNewsAgency:GetNewsShowTimeRewardTitle(id)
    local t = self._Model:GetNewsTemplate(id)

    return t.ShowTimeRewardTitle or 0
end

function XBigWorldNewsAgency:GetNewsShowTimeRewardContent(id)
    local t = self._Model:GetNewsTemplate(id)

    return t.ShowTimeRewardContent or 0
end

function XBigWorldNewsAgency:GetNewsTagHideCondition(id)
    local t = self._Model:GetNewsTemplate(id)

    return t.TagHideCondition or 0
end

function XBigWorldNewsAgency:GetNewsRewardShowSkipId(id)
    local t = self._Model:GetNewsTemplate(id)

    return t.RewardShowSkipId or 0
end

function XBigWorldNewsAgency:GetNewsIsSpecial(id)
    local t = self._Model:GetNewsTemplate(id)

    return t.IsSpecial or 0
end

function XBigWorldNewsAgency:GetNewsCustomParamId(id)
    local t = self._Model:GetNewsTemplate(id)

    return t.CustomParamId or 0
end

function XBigWorldNewsAgency:GetNewsEarlyAccessTextDialogId(id)
    local t = self._Model:GetNewsTemplate(id)

    return t.EarlyAccessTextDialogId or 0
end

function XBigWorldNewsAgency:GetNewsEarlyAccessSkipIds(id)
    local t = self._Model:GetNewsTemplate(id)

    return t.EarlyAccessSkipIds or 0
end

function XBigWorldNewsAgency:GetNewsDialogId(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.TextDialogId
end

function XBigWorldNewsAgency:GetNewsParams(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.Params
end

function XBigWorldNewsAgency:GetNewsPreSkipIds(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.PreSkipIds
end

function XBigWorldNewsAgency:GetNewsPreConditions(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.PreConditions
end

--endregion 读取配置

function XBigWorldNewsAgency:CheckNewsRedPoint(newsId)
    if not XTool.IsNumberValid(newsId) then
        return false
    end

    local taskGroupId = self:GetNewsTaskGroupId(newsId)

    if XTool.IsNumberValid(taskGroupId) then
        local taskDatas = XMVCA.XBigWorldService:GetTimeLimitTaskListByGroupId(taskGroupId)

        for _, taskData in pairs(taskDatas) do
            if XMVCA.XBigWorldService:CheckTaskAchieved(taskData.Id) then
                return true
            end
        end
    end

    return false
end

function XBigWorldNewsAgency:CheckNewsIsTime(newsId)
    if not XTool.IsNumberValid(newsId) then
        return false
    end

    local timeId = self:GetNewsShowTimeId(newsId)
    local countDownTime = self:GetNewsShowCountDown(newsId)

    if XTool.IsNumberValid(timeId) and XTool.IsNumberValid(countDownTime) then
        local endTime = XMVCA.XBigWorldService:GetEndTimeByTimeId(timeId)
        local currentTime = XTime.GetServerNowTimestamp()
        local offsetTime = endTime - currentTime

        return offsetTime > 0 and offsetTime < countDownTime
    end

    return false
end

function XBigWorldNewsAgency:CheckNewsNew(newsId)
    if not XTool.IsNumberValid(newsId) then
        return false
    end

    return self:CheckNewsTagNew(newsId) or self:CheckQuestNewsHasNew(newsId)
end

function XBigWorldNewsAgency:CheckNewsShowTag(newsId)
    if not XTool.IsNumberValid(newsId) then
        return false
    end

    local tagHideCondition = self:GetNewsTagHideCondition(newsId)

    if XTool.IsNumberValid(tagHideCondition) then
        return not XMVCA.XBigWorldService:CheckCondition(tagHideCondition)
    end

    return true
end

function XBigWorldNewsAgency:CheckNewsInTime(newsId)
    if not XTool.IsNumberValid(newsId) then
        return false
    end

    local timeId = self:GetNewsShowTimeId(newsId)

    return XMVCA.XBigWorldService:CheckInTimeByTimeId(timeId, true)
end

function XBigWorldNewsAgency:CheckNewsTagNew(newsId)
    return self._Model:CheckNewsTagNew(newsId)
end

function XBigWorldNewsAgency:MarkNewsTagNew(newsId)
    self._Model:MarkNewsTagNew(newsId)
end

function XBigWorldNewsAgency:GetNewsFirstLockCondition(newsId)
    if not newsId or newsId <= 0 then
        return -1
    end
    local conditions = self:GetNewsPreConditions(newsId)
    if XTool.IsTableEmpty(conditions) then
        return -1
    end
    for index, conditionId in ipairs(conditions) do
        local res, _ = XMVCA.XBigWorldService:CheckCondition(conditionId)
        if not res then
            return index
        end
    end
    return -1
end

function XBigWorldNewsAgency:GetNewsRemainingTime(newsId)
    if not XTool.IsNumberValid(newsId) then
        return 0
    end

    local timeId = self:GetNewsShowTimeId(newsId)
    local countDownTime = self:GetNewsShowCountDown(newsId)

    if XTool.IsNumberValid(timeId) and XTool.IsNumberValid(countDownTime) then
        local startTime = XMVCA.XBigWorldService:GetStartTimeByTimeId(timeId)
        local currentTime = XTime.GetServerNowTimestamp()

        return countDownTime - currentTime + startTime
    end

    return 0
end

function XBigWorldNewsAgency:CheckQuestNewsHasNew(newsId)
    local lockIndex = self:GetNewsFirstLockCondition(newsId)
    --已经解锁了
    if lockIndex <= 0 then
        return false
    end
    return self._Model:CheckQuestNewsPreConditionTag(newsId, lockIndex)
end

function XBigWorldNewsAgency:MarkQuestNewsPreConditionTag(newsId, lockIndex)
    self._Model:MarkQuestNewsPreConditionTag(newsId, lockIndex)
end

function XBigWorldNewsAgency:SaveAllLocalData()
    self._Model:SaveAllLocalData()
end

function XBigWorldNewsAgency:HasNewNews()
    local newsIds = self:GetNewsIds()
    if XTool.IsTableEmpty(newsIds) then
        return false
    end
    for _, newsId in pairs(newsIds) do
        if self:CheckNewsTagNew(newsId)
            or self:CheckQuestNewsHasNew(newsId) then
            return true
        end
    end
    return false
end

function XBigWorldNewsAgency:HasTimeNews()
    local newsIds = self:GetFilteredNewsIds()
    if XTool.IsTableEmpty(newsIds) then
        return false
    end
    for _, newsId in pairs(newsIds) do
        if self:CheckNewsIsTime(newsId) and self:CheckNewsInTime(newsId) and self:CheckNewsShowTag(newsId) then
            return true
        end
    end
    return false
end

function XBigWorldNewsAgency:HasReddotNews()
    local newsIds = self:GetNewsIds()
    if XTool.IsTableEmpty(newsIds) then
        return false
    end
    for _, newsId in pairs(newsIds) do
        if self:CheckNewsRedPoint(newsId) then
            return true
        end
    end
    return false
end

function XBigWorldNewsAgency:IsNewsEmpty()
    local newsIds = self:GetNewsIds()
    if XTool.IsTableEmpty(newsIds) then
        return true
    end
    for _, newsId in pairs(newsIds) do
        local conditionId = self:GetNewsUnlockCondition(newsId)
        if not conditionId or conditionId <= 0 then
            return false
        end
        local passed, _ = XMVCA.XBigWorldService:CheckCondition(conditionId)
        if passed then
            return false
        end
    end
    return true
end

return XBigWorldNewsAgency
