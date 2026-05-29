local XUiBigWorldProcessCourse = require("XUi/XUiBigWorld/XProcess/Course/XUiBigWorldProcessCourse")
local XUiBigWorldProcessExplore = require("XUi/XUiBigWorld/XProcess/Explore/XUiBigWorldProcessExplore")
local XUiBigWorldProcessCore = require("XUi/XUiBigWorld/XProcess/Core/XUiBigWorldProcessCore")

---@class XUiBigWorldProcess : XBigWorldUi
---@field TopTabGroup XUiButtonGroup
---@field BtnTab XUiComponent.XUiButton
---@field BtnSwitch XUiComponent.XUiButton
---@field PanelProcess UnityEngine.RectTransform
---@field PanelExplore UnityEngine.RectTransform
---@field PanelCore UnityEngine.RectTransform
---@field ImgTitle UnityEngine.UI.Image
---@field TxtTitle UnityEngine.UI.Text
---@field TxtProgress UnityEngine.UI.Text
---@field BtnClose XUiComponent.XUiButton
---@field _Control XBigWorldCourseControl
local XUiBigWorldProcess = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldProcess")

function XUiBigWorldProcess:OnAwake()
    self._CurrentIndex = 0

    ---@type XBWCourseVersionEntity
    self._CurrentVersionEntity = false

    self._Timer = false
    self._SequentialId = 0
    self._TargetContentId = 0

    self._TabMap = {}
    self._TabCache = {}

    ---@type XUiBigWorldProcessCourse
    self._CourseUi = XUiBigWorldProcessCourse.New(self.PanelProcess, self)
    ---@type XUiBigWorldProcessExplore
    self._ExploreUi = XUiBigWorldProcessExplore.New(self.PanelExplore, self)
    ---@type XUiBigWorldProcessCore
    self._CoreUi = XUiBigWorldProcessCore.New(self.PanelCore, self)

    self:_RegisterButtonClicks()
end

function XUiBigWorldProcess:OnStart(id, contentId, versionId)
    self._SequentialId = id or 0
    self._TargetContentId = contentId or 0
    self._CurrentVersionEntity = self._Control:GetSelectVersionEntity(versionId)

    self:_InitUi()
end

function XUiBigWorldProcess:OnEnable()
    if not self._CurrentVersionEntity then
        self:Close()
        return
    end

    self:_RefreshTargetTab()
    self:_RefreshVersion()
    self:_RefreshRedPoint()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcess:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcess:OnDestroy()
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_HUD_RED_POINT_REFRESH)

    if XTool.IsNumberValid(self._SequentialId) then
        XMVCA.XBigWorldCommon:FinishSequentialJob(self._SequentialId)
    end
end

function XUiBigWorldProcess:OnTopTabGroupClick(index)
    if self._CurrentIndex ~= index then
        local version = self:_GetCurrentVersion()

        if version then
            local contentEntity = version:GetContentEntityByIndex(index)

            self._CurrentIndex = index
            self:_RefreshPage(contentEntity)
            self:PlayAnimation("QieHuan")
        end
    end
end

function XUiBigWorldProcess:OnBtnSwitchClick()
    XMVCA.XBigWorldUI:Open("UiBigWorldProcessSwitch")
end

function XUiBigWorldProcess:OnBtnCloseClick()
    self._CourseUi:PlayRewardDisableAnimation()
    self:Close()
end

function XUiBigWorldProcess:OnRefreshRedPoint()
    self:_RefreshRedPoint()
end

function XUiBigWorldProcess:OnChangePage(contentId)
    local versionEntity = self:_GetCurrentVersion()

    if versionEntity then
        local index = 1
        local contentEntitys = versionEntity:GetContentEntitys()

        for i, contentEntity in pairs(contentEntitys) do
            if contentEntity:GetContentId() == contentId then
                index = i
            end
        end

        if XTool.IsNumberValid(index) then
            self.TopTabGroup:SelectIndex(index)
        end
    end
end

---@param versionEntity XBWCourseVersionEntity
function XUiBigWorldProcess:OnChangeVersion(versionEntity)
    local currentIndex = self._CurrentIndex

    self._CurrentIndex = 0
    self._CurrentVersionEntity = versionEntity
    self:_VersionChanged(currentIndex)
    self:_RefreshTab(currentIndex)
    self:_RefreshVersion()
    self:_RefreshRedPoint()
    self._Control:SetSelectVersion(self._CurrentVersionEntity:GetVersionId())
end

function XUiBigWorldProcess:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnSwitch:AddEventListener(handler(self, self.OnBtnSwitchClick))
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
end

function XUiBigWorldProcess:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH,
        self.OnRefreshRedPoint, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_CHANGE_PAGE, self.OnChangePage, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_CHANGE_VERSION, self.OnChangeVersion,
        self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefreshRedPoint, self)
end

function XUiBigWorldProcess:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH,
        self.OnRefreshRedPoint, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_CHANGE_PAGE, self.OnChangePage,
        self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_CHANGE_VERSION, self
    .OnChangeVersion, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnRefreshRedPoint, self)
end

function XUiBigWorldProcess:_RegisterSchedules()
    -- 在此处注册定时器
    self:_RemoveSchedules()

    self._Timer = XScheduleManager.ScheduleForever(function()
        if not self._CurrentVersionEntity or not self._CurrentVersionEntity:IsValid() then
            self:_RemoveSchedules()
            XMVCA.XBigWorldUI:SafeClose("UiBigWorldProcessSwitch")
            self:Close()
        end
    end, XScheduleManager.SECOND)
end

function XUiBigWorldProcess:_RemoveSchedules()
    -- 在此处移除定时器
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiBigWorldProcess:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcess:_InitUi()
    self.BtnTab.gameObject:SetActive(false)
end

function XUiBigWorldProcess:_RefreshTargetTab()
    if not XTool.IsNumberValid(self._TargetContentId) then
        local versionEntity = self:_GetCurrentVersion()

        if versionEntity then
            local index = 1
            local contentEntitys = versionEntity:GetContentEntitys()

            for i, contentEntity in pairs(contentEntitys) do
                if contentEntity:GetContentId() == self._TargetContentId then
                    index = i
                    break
                end
            end

            self:_RefreshTab(index)
        end

        return
    end

    self:_RefreshTab()
end

function XUiBigWorldProcess:_RefreshTab(currentSelectIndex)
    local versionEntity = self:_GetCurrentVersion()
    self._TabMap = {}
    if versionEntity then
        local tabList = {}
        local contentEntitys = versionEntity:GetContentEntitys()
        local selectIndex = self._CurrentIndex

        if not XTool.IsTableEmpty(contentEntitys) then
            local count = 1

            for index, contentEntity in pairs(contentEntitys) do
                if contentEntity:IsUnlock() then
                    local tab = self._TabCache[index]

                    if not tab then
                        tab = XUiHelper.Instantiate(self.BtnTab, self.TopTabGroup.transform)
                        self._TabCache[index] = tab
                    end

                    count = count + 1
                    self._TabMap[contentEntity:GetContentType()] = tab
                    tab.gameObject:SetActiveEx(true)
                    tab:SetNameByGroup(0, contentEntity:GetName())
                    tab:ShowReddot(false)
                    table.insert(tabList, tab)
                end
            end
            for i = count, #self._TabCache do
                self._TabCache[i].gameObject:SetActiveEx(false)
            end
        end

        if not XTool.IsNumberValid(selectIndex) then
            if XTool.IsNumberValid(currentSelectIndex) then
                selectIndex = currentSelectIndex
            else
                selectIndex = 1
            end

            if selectIndex > #tabList then
                selectIndex = 1
            end
        end

        self.TopTabGroup:Init(tabList, Handler(self, self.OnTopTabGroupClick))
        self.TopTabGroup:SelectIndex(selectIndex)
    end
end

---@return XBWCourseVersionEntity
function XUiBigWorldProcess:_GetCurrentVersion()
    return self._CurrentVersionEntity
end

---@param contentEntity XBWCourseContentEntity
function XUiBigWorldProcess:_RefreshPage(contentEntity)
    if not contentEntity or contentEntity:IsNil() then
        return
    end

    if contentEntity:IsTask() then
        self._CourseUi:Open()
        self._CourseUi:Refresh(contentEntity)
        self._CoreUi:Close()
        self._ExploreUi:Close()
    elseif contentEntity:IsExplore() then
        self._ExploreUi:Open()
        self._ExploreUi:Refresh(contentEntity)
        self._CourseUi:Close()
        self._CoreUi:Close()
    elseif contentEntity:IsCore() then
        self._CoreUi:Open()
        self._CoreUi:Refresh(contentEntity)
        self._CourseUi:Close()
        self._ExploreUi:Close()
    end

    self:_RefreshRedPoint()
end

---@param index number
function XUiBigWorldProcess:_VersionChanged(index)
    local version = self:_GetCurrentVersion()
    if not version then
        return
    end
    local contentEntity = version:GetContentEntityByIndex(index)
    if not contentEntity or contentEntity:IsNil() then
        return
    end
    if self._CourseUi then
        self._CourseUi:OnVersionChanged()
    end
    if self._ExploreUi then
        self._ExploreUi:OnVersionChanged()
    end
    if self._CoreUi then
        self._CoreUi:OnVersionChanged()
    end
end

function XUiBigWorldProcess:_RefreshVersion()
    local version = self:_GetCurrentVersion()

    if version then
        self.TxtTitle.text = version:GetName()
        self.TxtProgress.text = version:GetProgressStr()
        self.BtnSwitch:ShowReddot(XMVCA.XBigWorldCourse:CheckVersionsAchievedWithoutVersion(version:GetVersionId()))
    end
end

function XUiBigWorldProcess:_RefreshRedPoint()
    local version = self:_GetCurrentVersion()

    if version and not version:IsNil() then
        local versionId = version:GetVersionId()

        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Task,
            XMVCA.XBigWorldCourse:CheckVersionTaskAchieved(versionId))
        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Explore,
            XMVCA.XBigWorldCourse:CheckVersionExploreAchieved(versionId))
        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Core,
            XMVCA.XBigWorldCourse:CheckVersionNewCore(versionId))
    else
        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Task, false)
        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Explore, false)
        self:_RefreshTabRedPoint(XEnumConst.BWCourse.ContentType.Core, false)
    end
end

function XUiBigWorldProcess:_RefreshTabRedPoint(contentType, isShow)
    local contentTab = self._TabMap[contentType]

    if contentTab then
        contentTab:ShowReddot(isShow)
    end
end

return XUiBigWorldProcess
