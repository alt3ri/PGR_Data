---@class XUiBigWorldPopupNews : XBigWorldUi
---@field _NewsTabList XUiComponent.XUiButton[]
---@field _NewsGroupList XUiComponent.XUiComponentGroup[]
---@field _PanelOverview XUiPanelBWNewsOverview
---@field _PanelQuest XUiPanelBWNewsQuest
local XUiBigWorldPopupNews = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupNews")

function XUiBigWorldPopupNews:OnAwake()
    self._NewsIds = XMVCA.XBigWorldNews:GetFilteredNewsIds()
    ---@type XUiComponent.XUiButton[]
    self._NewsTabList = {}
    ---@type XUiComponent.XUiComponentGroup[]
    self._NewsGroupList = {}
    ---@type table<number, XUiPanelBWNewsBase>
    self._Panels = {}

    ---@type XUiPanelBWNewsBase
    self._CurrentPanel = false

    self._CurrentNewsShowMap = {}

    self._Timer = false

    self._DefaultIndex = -1
    self._TabIndex = 0

    self:InitUi()
    self:InitPanels()
    self:InitTabs()
    self:InitTabsTag()
    self:InitCb()
end

function XUiBigWorldPopupNews:OnStart(newsId)
    self._DefaultIndex = self:GetDefaultSelectIndex(newsId, self._DefaultIndex)
    self:InitView()
end

function XUiBigWorldPopupNews:OnEnable()
    self.BtnGroup:SelectIndex(self._DefaultIndex)
    self:RefreshFinish()
    self:RegisterTimer()

    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_ADVANCE_UPDATE, self.OnRefresh, self)
end

function XUiBigWorldPopupNews:OnDisable()
    self._DefaultIndex = self._TabIndex
    self._TabIndex = 0

    self:RemoveTimer()
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_ADVANCE_UPDATE, self.OnRefresh,
        self)
end

function XUiBigWorldPopupNews:OnDestroy()
    XMVCA.XBigWorldNews:SaveAllLocalData()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_FUNCTION_EVENT_COMPLETE)
end

function XUiBigWorldPopupNews:OnRefresh(isSure)
    if isSure then
        self:Close()
    else
        self:RefreshCurrentPanel()
    end
end

function XUiBigWorldPopupNews:InitUi()
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.PanelNewsType1.gameObject:SetActiveEx(false)
    self.PanelNewsType2.gameObject:SetActiveEx(false)
end

function XUiBigWorldPopupNews:InitTabs()
    table.sort(self._NewsIds, function(newsIdA, newsIdB)
        local panelA = self._Panels[newsIdA]
        local panelB = self._Panels[newsIdB]
        local isNewsAFinish = panelA and panelA:IsShowFinishTag() or false
        local isNewsBFinish = panelB and panelB:IsShowFinishTag() or false

        if isNewsAFinish ~= isNewsBFinish then
            return not isNewsAFinish
        end

        local priorityA = XMVCA.XBigWorldNews:GetNewsPriority(newsIdA)
        local priorityB = XMVCA.XBigWorldNews:GetNewsPriority(newsIdB)

        if priorityA ~= priorityB then
            return priorityA > priorityB
        end

        return newsIdA < newsIdB
    end)

    self._NewsGroupList = {}
    self._CurrentNewsShowMap = {}
    for i, id in pairs(self._NewsIds) do
        local panel = self._Panels[id]
        local btn = self._NewsTabList[i]
        local isInTime = panel and panel:IsInTime() or false

        if not btn then
            btn = i == 1 and self.BtnFirst or XUiHelper.Instantiate(self.BtnFirst, self.BtnGroup.transform)

            self._NewsTabList[i] = btn
        end

        self._CurrentNewsShowMap[id] = isInTime
        if isInTime and self._DefaultIndex == -1 then
            self._DefaultIndex = i
        end

        btn:SetNameByGroup(0, XMVCA.XBigWorldNews:GetNewsName(id))
        btn.gameObject.name = string.format("BtnFirst%d", id)
        btn.gameObject:SetActiveEx(isInTime)
        table.insert(self._NewsGroupList, btn.gameObject:GetComponent(typeof(CS.XUiComponent.XUiComponentGroup)))
    end

    self.BtnGroup:Init(self._NewsTabList, function(tabIndex) self:OnSelectTab(tabIndex) end)
end

function XUiBigWorldPopupNews:InitPanels()
    for _, type in pairs(XMVCA.XBigWorldNews.NewsType) do
        local ui = self["PanelNewsType" .. tostring(type)]

        if ui then
            ui.gameObject:SetActiveEx(false)
        end
    end
    for i, id in pairs(self._NewsIds) do
        local type = XMVCA.XBigWorldNews:GetNewsType(id)
        local ui = self["PanelNewsType" .. tostring(type)]

        if ui then
            local uiClone = XUiHelper.Instantiate(ui, self.PanelTeachContent)
            local uiObject = XMVCA.XBigWorldNews:CreatePanelUiClass(id, uiClone, self)

            uiObject:SetNewsId(id)
            self._Panels[id] = uiObject
        end
    end
end

function XUiBigWorldPopupNews:InitTabsTag()
    for i, id in pairs(self._NewsIds) do
        local uiObject = self._Panels[id]

        if uiObject then
            self:RefreshTabRedOrTag(uiObject, i)
        end
    end
end

function XUiBigWorldPopupNews:InitCb()
    self.BtnBack:AddEventListener(handler(self, self.Close))
end

function XUiBigWorldPopupNews:InitView()
end

function XUiBigWorldPopupNews:OnSelectTab(tabIndex)
    if self._TabIndex == tabIndex then
        return
    end

    local newsId = self._NewsIds[tabIndex]

    if self._CurrentPanel then
        self._CurrentPanel:Close()
    end

    self._TabIndex = tabIndex
    self._CurrentPanel = self._Panels[newsId]
    self:PlayAnimationWithMask("Qiehuan")
    self:RefreshCurrentPanel(newsId, tabIndex)
end

function XUiBigWorldPopupNews:RefreshCurrentPanel(newsId, tabIndex)
    if self._CurrentPanel then
        newsId = newsId or self._CurrentPanel:GetNewsId()

        if not tabIndex then
            for i, id in pairs(self._NewsIds) do
                if id == newsId then
                    tabIndex = i
                    break
                end
            end
        end

        self._CurrentPanel:Open()
        self._CurrentPanel:Refresh()
        XMVCA.XBigWorldNews:MarkNewsTagNew(newsId)
        self:RefreshTabRedOrTag(self._CurrentPanel, tabIndex)
    end
end

function XUiBigWorldPopupNews:RefreshCurrentTabSelect()
    if not self._CurrentPanel then
        return
    end

    self:InitTabs()

    for i, id in pairs(self._NewsIds) do
        if id == self._CurrentPanel:GetNewsId() then
            self._TabIndex = i
        else
            local panel = self._Panels[id]

            if panel then
                self:RefreshTabRedOrTag(panel, i)
            end
        end
    end

    self.BtnGroup:SelectIndex(self._TabIndex)
end

---@param panel XUiPanelBWNewsBase
---@param tabIndex number
function XUiBigWorldPopupNews:RefreshTabRedOrTag(panel, tabIndex)
    local btn = self._NewsTabList[tabIndex]
    local componentGroup = self._NewsGroupList[tabIndex]

    btn:ShowReddot(panel:IsShowReddot())
    btn:ShowTag(panel:IsShowNewTag())

    if componentGroup then
        componentGroup:SetVisibleWithGroup(1, panel:IsShowTimeTag())
    end
end

function XUiBigWorldPopupNews:RefreshTab(newsId, panel, tabIndex)
    local btn = self._NewsTabList[tabIndex]
    local componentGroup = self._NewsGroupList[tabIndex]

    btn:ShowReddot(panel:IsShowReddot())
    btn:ShowTag(panel:IsShowNewTag())

    if componentGroup then
        componentGroup:SetVisibleWithGroup(0, self:CheckFinish(newsId))
        componentGroup:SetVisibleWithGroup(1, panel:IsShowTimeTag())
    end
end

function XUiBigWorldPopupNews:RefreshFinish()
    for index, newsId in pairs(self._NewsIds) do
        local isFinish = self:CheckFinish(newsId)
        local componentGroup = self._NewsGroupList[index]

        if componentGroup then
            componentGroup:SetVisibleWithGroup(0, isFinish)
        end
    end
end

function XUiBigWorldPopupNews:GetDefaultSelectIndex(newsId, defaultValue)
    if not (newsId and newsId > 0) then
        return defaultValue or 1
    end
    for i, id in ipairs(self._NewsIds) do
        if id == newsId then
            return i
        end
    end
    return defaultValue or 1
end

function XUiBigWorldPopupNews:CheckFinish(newsId)
    if not newsId or newsId <= 0 then
        return false
    end

    local panel = self._Panels[newsId]

    return panel and panel:IsShowFinishTag() or false
end

function XUiBigWorldPopupNews:RegisterTimer()
    self:RemoveTimer()

    self._Timer = XScheduleManager.ScheduleForeverEx(Handler(self, self.UpdateTime), XScheduleManager.SECOND)
end

function XUiBigWorldPopupNews:RemoveTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)

        self._Timer = false
    end
end

function XUiBigWorldPopupNews:UpdateTime()
    local count = 0
    local hideCount = 0
    local selectIndex = -1
    local isChangeSelect = false

    for i, id in pairs(self._NewsIds) do
        local panel = self._Panels[id]

        if panel then
            local isInTime = panel:IsInTime()

            count = count + 1
            if isInTime ~= self._CurrentNewsShowMap[id] then
                self._CurrentNewsShowMap[id] = isInTime
                self:SetPanelActive(i, isInTime)

                if isInTime then
                    self:RefreshTab(id, panel, i)
                end

                XMVCA.XBigWorldUI:TipText("NewsChangeTip")
            elseif isInTime then
                panel:SecondUpdate()
            end

            if isChangeSelect then
                selectIndex = i
                isChangeSelect = false
            end

            if self._CurrentPanel and self._CurrentPanel == panel and not isInTime then
                isChangeSelect = true
            end

            if not isInTime then
                hideCount = hideCount + 1
            end
        end
    end

    if hideCount >= count then
        self:Close()
        return
    end

    if selectIndex ~= -1 then
        self.BtnGroup:SelectIndex(selectIndex)
    end
end

---@param panel XUiPanelBWNewsBase
function XUiBigWorldPopupNews:SetPanelActive(index, isActive)
    local tab = self._NewsTabList[index]

    if tab then
        tab.gameObject:SetActiveEx(isActive)

    end
end

return XUiBigWorldPopupNews
