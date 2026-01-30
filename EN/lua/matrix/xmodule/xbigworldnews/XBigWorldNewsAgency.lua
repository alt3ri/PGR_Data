---@class XBigWorldNewsAgency : XAgency
---@field private _Model XBigWorldNewsModel
local XBigWorldNewsAgency = XClass(XAgency, "XBigWorldNewsAgency")
function XBigWorldNewsAgency:OnInit()
    self.NewsType = {
        Overview = 1, --版本概况
        Quest = 2, --版本任务
    }
end

function XBigWorldNewsAgency:InitRpc()
end

function XBigWorldNewsAgency:InitEvent()
    self:AddAgencyEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_FINISH, self.CheckAutoPopup, self)
    XMVCA.XBigWorldFunction:AddEnterOperateHandler(XMVCA.XBigWorldFunction.EnterOperateType.OpenNews, self.TryOpenNewsUiAndMarkPopped, self)
end

function XBigWorldNewsAgency:RemoveEvent()
    self:RemoveAgencyEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_FINISH, self.CheckAutoPopup, self)
end

function XBigWorldNewsAgency:InitPopupNews(data)
    self._Model:InitPopupNews(data)
end

function XBigWorldNewsAgency:CheckAutoPopup()
    if XMVCA.XBigWorldGamePlay:IsInstLevel() then
        return false
    end
    if not XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.BigWorldNews, true, true) then
        return false
    end
    
    local newsIds = self:GetNewsIds()
    for _, newsId in pairs(newsIds) do
        if self:CheckNewsPopup(newsId) then
            self:RequestMarkNewsPopped(newsId)
            self:OpenNewsUi(newsId)
            self._Model:SetNewsPopup(newsId)
            return true
        end
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
    return true
end

function XBigWorldNewsAgency:TryOpenNewsUiAndMarkPopped(newsId)
    if XMVCA.XBigWorldGamePlay:IsInstLevel() then
        return
    end
    if not XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.BigWorldNews, true, true) then
        return
    end
    if self:CheckNewsPopup(newsId) then
        self:RequestMarkNewsPopped(newsId)
        self._Model:SetNewsPopup(newsId)
    end
    self:OpenNewsUi(newsId)
end

function XBigWorldNewsAgency:RequestMarkNewsPopped(newsId, func)
    if self._Model:CheckNewsPopup(newsId) then
        return
    end

    if not XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.BigWorldNews, true, true) then
        return
    end
    
    if not self:CheckPopupCondition(newsId) then
        return
    end
    XNetwork.Call("BigWorldNewsMarkPopupRequest", { Id = newsId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:SetNewsPopup(newsId)

        if func then func() end
    end)
end

--region 读取配置

function XBigWorldNewsAgency:GetNewsIds()
    return self._Model:GetNewsIds()
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

function XBigWorldNewsAgency:GetNewsShowReward(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.ShowReward
end

function XBigWorldNewsAgency:GetNewsUnlockCondition(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.UnlockCondition
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

function XBigWorldNewsAgency:GetNewsSkipId(id)
    local t = self._Model:GetNewsTemplate(id)
    return t.SkipId
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
    return false
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