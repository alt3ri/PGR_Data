
---@class XUiBigWorldPopupNews : XBigWorldUi
---@field _NewsTabList XUiComponent.XUiButton[]
---@field _NewsGroupList XUiComponent.XUiComponentGroup[]
---@field _PanelOverview XUiPanelBWNewsOverview
---@field _PanelQuest XUiPanelBWNewsQuest
local XUiBigWorldPopupNews = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupNews")

function XUiBigWorldPopupNews:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldPopupNews:OnStart(newsId)
    self._DefaultIndex = self:GetDefaultSelectIndex(newsId)
    self:InitView()
end

function XUiBigWorldPopupNews:OnEnable()
    self.BtnGroup:SelectIndex(self._DefaultIndex)
    self:RefreshFinish()
end

function XUiBigWorldPopupNews:OnDisable()
    self._DefaultIndex = self._TabIndex
    self._TabIndex = nil
end

function XUiBigWorldPopupNews:OnDestroy()
    XMVCA.XBigWorldNews:SaveAllLocalData()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_COMPLETE)
end

function XUiBigWorldPopupNews:InitUi()
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.PanelNewsType1.gameObject:SetActiveEx(false)
    self.PanelNewsType2.gameObject:SetActiveEx(false)
    
    self._NewsIds = self:FilterNewsIds(XMVCA.XBigWorldNews:GetNewsIds())

    local tabList = {}
    local groupList = {}
    self._NewsTabList = tabList
    self._NewsGroupList = groupList
    for i, id in pairs(self._NewsIds) do
        local btn = i == 1 and self.BtnFirst or XUiHelper.Instantiate(self.BtnFirst, self.BtnGroup.transform)
        btn:SetNameByGroup(0, XMVCA.XBigWorldNews:GetNewsName(id))
        btn.gameObject:SetActiveEx(true)
        tabList[#tabList + 1] = btn
        groupList[#groupList + 1] = btn.gameObject:GetComponent(typeof(CS.XUiComponent.XUiComponentGroup))
        self:RefreshTabRedOrTag(i)
    end
    
    self.BtnGroup:Init(tabList, function(tabIndex) self:OnSelectTab(tabIndex) end)
end

function XUiBigWorldPopupNews:InitCb()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    local newsType = XMVCA.XBigWorldNews.NewsType
    self._RefreshContentFunc = {
        [newsType.Overview] = handler(self, self.RefreshOverview),
        [newsType.Quest] = handler(self, self.RefreshQuest),
    }
    
    self._CheckFinishFunc = {
        [newsType.Overview] = handler(self, self.CheckOverViewFinish),
        [newsType.Quest] = handler(self, self.CheckQuestFinish),
    }
end

function XUiBigWorldPopupNews:InitView()
end

function XUiBigWorldPopupNews:OnSelectTab(tabIndex)
    if self._TabIndex == tabIndex then
        return
    end
    
    self:PlayAnimationWithMask("Qiehuan")
    self._TabIndex = tabIndex
    self._NewsId = self._NewsIds[tabIndex]
    local refreshFunc = self._RefreshContentFunc[XMVCA.XBigWorldNews:GetNewsType(self._NewsId)]
    if refreshFunc then
        refreshFunc()
    end
    XMVCA.XBigWorldNews:MarkNewsTagNew(self._NewsId)
    self:RefreshTeach()
    self:RefreshTabRedOrTag(tabIndex)
end

function XUiBigWorldPopupNews:RefreshOverview()
    if self._CurrentPanel then
        self._CurrentPanel:Close()
    end
    self._PanelOverview = self._PanelOverview or require("XUi/XUiBigWorld/XNews/Panel/XUiPanelBWNewsOverview").New(self.PanelNewsType1, self)
    self._PanelOverview:Refresh(self._NewsId)
    self._CurrentPanel = self._PanelOverview
end

function XUiBigWorldPopupNews:RefreshQuest()
    if self._CurrentPanel then
        self._CurrentPanel:Close()
    end
    self._PanelQuest = self._PanelQuest or require("XUi/XUiBigWorld/XNews/Panel/XUiPanelBWNewsQuest").New(self.PanelNewsType2, self)
    self._PanelQuest:Refresh(self._NewsId)
    self._CurrentPanel = self._PanelQuest
end

function XUiBigWorldPopupNews:RefreshTeach(btn)
    if XTool.UObjIsNil(btn) then
        return
    end
    
    local dialogId = XMVCA.XBigWorldNews:GetNewsDialogId(self._NewsId)
    btn.gameObject:SetActiveEx(dialogId and dialogId > 0)
end

function XUiBigWorldPopupNews:RefreshTabRedOrTag(tabIndex)
    local newsId = self._NewsIds[tabIndex]
    if not newsId then
        return
    end
    local btn = self._NewsTabList[tabIndex]
    if XMVCA.XBigWorldNews:CheckNewsRedPoint(newsId) then
        btn:ShowReddot(true)
        btn:ShowTag(false)
    elseif XMVCA.XBigWorldNews:CheckNewsTagNew(newsId) 
            or XMVCA.XBigWorldNews:CheckQuestNewsHasNew(newsId) then
        btn:ShowReddot(false)
        btn:ShowTag(true)
    else
        btn:ShowReddot(false)
        btn:ShowTag(false)
    end
end

function XUiBigWorldPopupNews:RefreshFinish()
    for index, newsId in pairs(self._NewsIds) do
        local finishFunc = self._CheckFinishFunc[XMVCA.XBigWorldNews:GetNewsType(newsId)]
        local isFinish = finishFunc and finishFunc(newsId) or false
        local componentGroup = self._NewsGroupList[index]
        if componentGroup then
            componentGroup:SetVisibleWithGroup(0, isFinish)
        end
    end
end

function XUiBigWorldPopupNews:OnBtnTeachClick()
    local dialogId = XMVCA.XBigWorldNews:GetNewsDialogId(self._NewsId)
    if not dialogId or dialogId < 0 then
        return
    end
    XMVCA.XBigWorldUI:OpenTextDialog(dialogId)
end

function XUiBigWorldPopupNews:GetDefaultSelectIndex(newsId)
    if not (newsId and newsId > 0) then
        return 1
    end
    for i, id in ipairs(self._NewsIds) do
        if id == newsId then
            return i
        end
    end
    return 1
end

function XUiBigWorldPopupNews:FilterNewsIds(newsIds)
    if XTool.IsTableEmpty(newsIds) then
        return newsIds
    end
    local list = {}
    local index = 0
    for _, newsId in pairs(newsIds) do
        local passed, _ = true, nil
        local conditionId = XMVCA.XBigWorldNews:GetNewsUnlockCondition(newsId)
        if conditionId and conditionId > 0 then
            passed, _ = XMVCA.XBigWorldService:CheckCondition(conditionId)
        end
        if passed then
            index = index + 1
            list[index] = newsId
        end
    end
    return list
end

function XUiBigWorldPopupNews:CheckOverViewFinish(newsId)
    local questIds = XMVCA.XBigWorldNews:GetNewsParams(newsId)
    if XTool.IsTableEmpty(questIds) then
        return true
    end
    for _, questId in ipairs(questIds) do
        if not XMVCA.XBigWorldQuest:CheckQuestFinish(questId) then
            return false
        end
    end
    return true
end

function XUiBigWorldPopupNews:CheckQuestFinish(newsId)
    if not newsId or newsId <= 0 then
        return false
    end
    local params = XMVCA.XBigWorldNews:GetNewsParams(newsId)
    local questId = params and params[1] or 0
    if not questId or questId <= 0 then
        return false
    end
    local isFinish = XMVCA.XBigWorldQuest:CheckQuestFinish(questId)
    return isFinish
end

function XUiBigWorldPopupNews:CheckFinish(newsId)
    if not newsId or newsId <= 0 then
        return false
    end
    local finishFunc = self._CheckFinishFunc[XMVCA.XBigWorldNews:GetNewsType(newsId)]
    local isFinish = finishFunc and finishFunc(newsId) or false
    return isFinish
end