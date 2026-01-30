local XUiBWProcessPlayerBase = require("XUi/XUiBigWorld/XProcess/XUiBWProcessPlayerBase")
local XUiBigWorldProcessExploreGrid = require("XUi/XUiBigWorld/XProcess/Explore/XUiBigWorldProcessExploreGrid")

---@class XUiBigWorldProcessExplore : XUiBWProcessPlayerBase
---@field TxtExploreProgress UnityEngine.UI.Text
---@field BtnReward XUiComponent.XUiButton
---@field ListExplore UnityEngine.RectTransform
---@field GridExplore UnityEngine.RectTransform
---@field Parent XUiBigWorldProcess
---@field _Control XBigWorldCourseControl
---@field TxtTips UnityEngine.UI.Text
local XUiBigWorldProcessExplore = XClass(XUiBWProcessPlayerBase, "XUiBigWorldProcessExplore")

function XUiBigWorldProcessExplore:OnStart()
    ---@type XBWCourseContentEntity
    self._Entity = false
    ---@type XDynamicTableNormal
    self._DynamicTable = XUiHelper.DynamicTableNormal(self, self.ListExplore, XUiBigWorldProcessExploreGrid)

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessExplore:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessExplore:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessExplore:OnDestroy()
end

function XUiBigWorldProcessExplore:OnBtnRewardClick()
    if not self._Entity then
        return
    end

    if self._Entity:IsAchieved() then
        self._Control:RequestBigWorldCourseExploreCntGetCompleteReward(self._Entity:GetVersionId())
    else
        self._Control:TryOpenRewardTips(self._Entity:GetExploreRewardId())
    end
end

---@param grid XUiBigWorldProcessExploreGrid
function XUiBigWorldProcessExplore:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local entity = self._DynamicTable:GetData(index)

        grid:Refresh(entity)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:PlayDynamicAnimation()
    end
end

function XUiBigWorldProcessExplore:OnRefreshRedPoint()
    self:_RefreshRedPoint()
end

function XUiBigWorldProcessExplore:OnRefresh()
    if self._Entity then
        self:Refresh(self._Entity)
    end
end

---@param contentEntity XBWCourseContentEntity
function XUiBigWorldProcessExplore:Refresh(contentEntity)
    self._Entity = contentEntity

    self:_RefreshRedPoint()
    self:_RefreshProgress(contentEntity)
    self:_RefreshDynamicTable(contentEntity:GetExploreEntitysWithSorting())
    self:_RefreshBannerBg(contentEntity)
    self:_RefreshTips(contentEntity)
end

---@return XDynamicTableNormal
function XUiBigWorldProcessExplore:GetDynamicTable()
    return self._DynamicTable
end

function XUiBigWorldProcessExplore:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnReward:AddEventListener(handler(self, self.OnBtnRewardClick))
end

function XUiBigWorldProcessExplore:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH,
        self.OnRefreshRedPoint, self)
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_REWARD_RECEIVE, self.OnRefresh, self)
end

function XUiBigWorldProcessExplore:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH,
        self.OnRefreshRedPoint, self)
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_REWARD_RECEIVE, self.OnRefresh,
        self)
end

function XUiBigWorldProcessExplore:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessExplore:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessExplore:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessExplore:_InitUi()
    self.GridExplore.gameObject:SetActiveEx(false)
    self.ImgBg = self.ImgBg or self.Transform:Find("PanelAccumulate/ImgBg"):GetComponent("RawImage")
end

---@param contentEntity XBWCourseContentEntity
function XUiBigWorldProcessExplore:_RefreshProgress(contentEntity)
    local rewardList = contentEntity:GetExploreRewardList()

    self.TxtExploreProgress.text = contentEntity:GetExploreProgressText()
    if table.nums(rewardList) == 1 then
        self.BtnReward:ShowTag(false)
        self.BtnReward:SetRawImageVisible(true)
        self.BtnReward:SetRawImage(contentEntity:GetExploreRewardIcon())
    else
        self.BtnReward:SetRawImageVisible(false)
        self.BtnReward:ShowTag(true)
    end
    if self.PanelReceive then
        self.PanelReceive.gameObject:SetActiveEx(contentEntity:IsComplete())
    end
end

---@param exploreEntitys XBWCourseExploreEntity[]
function XUiBigWorldProcessExplore:_RefreshDynamicTable(exploreEntitys)
    if not XTool.IsTableEmpty(exploreEntitys) then
        self._DynamicTable:SetDataSource(exploreEntitys)
        self._DynamicTable:ReloadDataSync()
    end
end

function XUiBigWorldProcessExplore:_RefreshRedPoint()
    if not self._Entity then
        self.BtnReward:ShowReddot(false)
        return
    end

    self.BtnReward:ShowReddot(self._Entity:IsAchieved())
end

---@param exploreEntity XBWCourseContentEntity
function XUiBigWorldProcessExplore:_RefreshBannerBg(exploreEntity)
    if not self.ImgBg then
        return
    end
    self.ImgBg:SetRawImage(exploreEntity:GetBigWorldCourseContentBannerBg())
end

---@param exploreEntity XBWCourseContentEntity
function XUiBigWorldProcessExplore:_RefreshTips(exploreEntity)
    local tip = exploreEntity:GetBigWorldCourseContentTip()
    if string.IsNilOrEmpty(tip) then
        self.TxtTips.gameObject:SetActiveEx(false)
    else
        self.TxtTips.gameObject:SetActiveEx(true)
        self.TxtTips.text = tip
    end
end

function XUiBigWorldProcessExplore:OnVersionChanged()
end

return XUiBigWorldProcessExplore
