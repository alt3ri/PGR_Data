local XUiBigWorldProcessCoreActivity = require("XUi/XUiBigWorld/XProcess/Core/XUiBigWorldProcessCoreActivity")
local XUiBigWorldProcessCoreStory = require("XUi/XUiBigWorld/XProcess/Core/XUiBigWorldProcessCoreStory")

---@class XUiBigWorldProcessCore : XUiNode
---@field TabGroup XUiButtonGroup
---@field BtnTab XUiComponent.XUiButton
---@field BtnTabSmall XUiComponent.XUiButton
---@field ListActivity UnityEngine.RectTransform
---@field GridActivity UnityEngine.RectTransform
---@field PanelStory UnityEngine.RectTransform
---@field Parent XUiBigWorldProcess
---@field _Control XBigWorldCourseControl
local XUiBigWorldProcessCore = XClass(XUiNode, "XUiBigWorldProcessCore")

function XUiBigWorldProcessCore:OnStart()
    ---@type XBWCourseCoreEntity[]
    self._CoreEntitys = {}
    self._TabList = {}
    self._TabIndexGroup = {}

    self._CurrentIndex = 0

    ---@type XBWCourseContentEntity
    self._ContentEntity = nil

    ---@type XDynamicTableNormal
    self._ActivityDynamicTable = XUiHelper.DynamicTableNormal(self, self.ListActivity, XUiBigWorldProcessCoreActivity)
    ---@type XUiBigWorldProcessCoreStory
    self._StoryUi = XUiBigWorldProcessCoreStory.New(self.PanelStory, self)

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessCore:OnEnable()
    self:_RefreshCurrent()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessCore:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessCore:OnDestroy()
end

---@param grid XUiBigWorldProcessCoreActivity
function XUiBigWorldProcessCore:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local entity = self._ActivityDynamicTable:GetData(index)

        grid:Refresh(entity)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_RefreshCurrentElementRecord()
    end
end

function XUiBigWorldProcessCore:OnTabGroupClick(index)
    if self._CurrentIndex ~= index then
        local coreEntity = self._CoreEntitys[index]

        self._CurrentIndex = index
        if coreEntity then
            if coreEntity:IsActivity() then
                self._StoryUi:Close()
                self._ActivityDynamicTable:SetActive(true)
                self:_RefreshActivityDynamicTable(coreEntity)
            elseif coreEntity:IsQuest() then
                self._ActivityDynamicTable:SetActive(false)
                self._StoryUi:Open()
                self._StoryUi:Refresh(coreEntity)
            end

            self:_RefreshTabReddot()
            self:PlayAnimation("CoreQieHuan")
        end
    end
end

function XUiBigWorldProcessCore:OnRefreshRedPoint()
    self:_RefreshTabReddot()
end

---@param contentEntity XBWCourseContentEntity
function XUiBigWorldProcessCore:Refresh(contentEntity)
    self._ContentEntity = contentEntity
    self:_RefreshTab(contentEntity)
end

function XUiBigWorldProcessCore:_RefreshCurrent()
    if self._ContentEntity then
        local selectIndex = self._CurrentIndex

        self._CurrentIndex = 0
        self:_RefreshTab(self._ContentEntity, selectIndex)
    end
end

function XUiBigWorldProcessCore:_RegisterButtonClicks()
    -- 在此处注册按钮事件
end

function XUiBigWorldProcessCore:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH,
        self.OnRefreshRedPoint, self)
end

function XUiBigWorldProcessCore:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH,
        self.OnRefreshRedPoint, self)
end

function XUiBigWorldProcessCore:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessCore:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessCore:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessCore:_InitUi()
    self.GridActivity.gameObject:SetActiveEx(false)
    self.BtnTab.gameObject:SetActiveEx(false)
    self.BtnTabSmall.gameObject:SetActiveEx(false)
end

---@param contentEntity XBWCourseContentEntity
function XUiBigWorldProcessCore:_RefreshTab(contentEntity, selectIndex)
    local index = 1
    local tabGroup = {}
    local groupCoreList = contentEntity:GetCoreEntitysGroupList()

    self._CoreEntitys = {}
    self._TabIndexGroup = {}
    if not XTool.IsTableEmpty(groupCoreList) then
        for _, coreEntitys in pairs(groupCoreList) do
            if self._Control:CheckCoreEntitysUnlock(coreEntitys) then
                local groupId = coreEntitys[1]:GetGroupId()
                local tab = self._TabList[index]
                local groupName = self._Control:GetCoreGroupName(groupId)
                local label = self._Control:GetCoreGroupLabelImage(groupId)
                local mainIndex = index

                if not tab then
                    tab = XUiHelper.Instantiate(self.BtnTab, self.TabGroup.transform)
                    self._TabList[index] = tab
                end

                tab.gameObject:SetActiveEx(true)
                tab:SetNameByGroup(0, groupName)
                if not string.IsNilOrEmpty(label) then
                    tab:SetSprite(label)
                end

                table.insert(tabGroup, tab)
                self._TabIndexGroup[mainIndex] = {}
                if not XTool.IsTableEmpty(coreEntitys) then
                    if #coreEntitys > 1 or self._Control:CheckCoreQuestGroup(groupId) then
                        for _, coreEntity in pairs(coreEntitys) do
                            if coreEntity:IsUnlock() then
                                index = index + 1
                                tab = self._TabList[index]
                                label = coreEntity:GetLabelImage()

                                if not tab then
                                    tab = XUiHelper.Instantiate(self.BtnTabSmall, self.TabGroup.transform)
                                    self._TabList[index] = tab
                                end

                                self._CoreEntitys[index] = coreEntity
                                tab.gameObject:SetActiveEx(true)
                                tab:SetNameByGroup(0, coreEntity:GetName())
                                tab.SubGroupIndex = mainIndex
                                if not string.IsNilOrEmpty(label) then
                                    tab:SetSprite(label)
                                end

                                table.insert(self._TabIndexGroup[mainIndex], index)
                                table.insert(tabGroup, tab)
                            end
                        end
                    else
                        self._CoreEntitys[index] = coreEntitys[1]
                    end
                end

                index = index + 1
            end
        end
    end
    for i = index, #self._TabList do
        self._TabList[i].gameObject:SetActiveEx(false)
    end

    local currentSelect = selectIndex or 1

    if currentSelect > #tabGroup then
        currentSelect = 1
    end

    self.TabGroup:Init(tabGroup, Handler(self, self.OnTabGroupClick))
    self.TabGroup:SelectIndex(currentSelect)

end

---@param coreEntity XBWCourseCoreEntity
function XUiBigWorldProcessCore:_RefreshActivityDynamicTable(coreEntity)
    local elements = coreEntity:GetElementEntitysWithSort()

    if not XTool.IsTableEmpty(elements) then
        self._ActivityDynamicTable:SetActive(true)
        self._ActivityDynamicTable:SetDataSource(elements)
        self._ActivityDynamicTable:ReloadDataSync()
    else
        self._ActivityDynamicTable:SetActive(false)
    end
end

function XUiBigWorldProcessCore:_RefreshCurrentElementRecord()
    local coreEntity = self._CoreEntitys[self._CurrentIndex]

    if coreEntity then
        self._Control:RecordCoreElementsByCoreEntity(coreEntity)
    end
end

function XUiBigWorldProcessCore:_RefreshTabReddot()
    if not XTool.IsTableEmpty(self._TabIndexGroup) then
        for index, subIndexs in pairs(self._TabIndexGroup) do
            local mainTab = self._TabList[index]

            if XTool.IsTableEmpty(subIndexs) then
                local coreEntity = self._CoreEntitys[index]

                if mainTab and coreEntity then
                    mainTab:ShowReddot(coreEntity:IsNew())
                end
            else
                local isGroupNew = false

                for _, subIndex in pairs(subIndexs) do
                    local coreEntity = self._CoreEntitys[subIndex]
                    local tab = self._TabList[subIndex]

                    if coreEntity and tab then
                        local isNew = coreEntity:IsNew()

                        tab:ShowReddot(isNew)

                        if isNew then
                            isGroupNew = true
                        end
                    end
                end

                if mainTab then
                    mainTab:ShowReddot(isGroupNew)
                end
            end
        end
    end
end

return XUiBigWorldProcessCore
