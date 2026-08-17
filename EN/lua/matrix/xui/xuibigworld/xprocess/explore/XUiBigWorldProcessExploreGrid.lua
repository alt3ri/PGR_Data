local XUiBWProcessAnimationBase = require("XUi/XUiBigWorld/XProcess/XUiBWProcessAnimationBase")
local XUiBigWorldProcessExploreRegion = require("XUi/XUiBigWorld/XProcess/Explore/XUiBigWorldProcessExploreRegion")

---@class XUiBigWorldProcessExploreGrid : XUiBWProcessAnimationBase
---@field ImgBackground UnityEngine.UI.RawImage
---@field TxtExploreName UnityEngine.UI.Text
---@field RImgIcon UnityEngine.UI.RawImage
---@field BtnHelp XUiComponent.XUiButton
---@field BtnReward XUiComponent.XUiButton
---@field PanelReceive UnityEngine.RectTransform
---@field RImgRewardIcon UnityEngine.UI.RawImage
---@field RImgTreasure UnityEngine.UI.RawImage
---@field TxtRewardNum UnityEngine.UI.Text
---@field ListRegion UnityEngine.RectTransform
---@field GridRegion UnityEngine.RectTransform
---@field CanvasGroup UnityEngine.CanvasGroup
---@field Parent XUiBigWorldProcessExplore
---@field _Control XBigWorldCourseControl
local XUiBigWorldProcessExploreGrid = XClass(XUiBWProcessAnimationBase, "XUiBigWorldProcessExploreGrid")

function XUiBigWorldProcessExploreGrid:OnStart()
    ---@type XBWCourseExploreEntity
    self._Entity = false
    ---@type XUiBigWorldProcessExploreRegion[]
    self._RegionGrids = {}

    self:_InitUi()
    self:_RegisterButtonClicks()
    self:SetEnableAnimationName("GridExploreEnable")
end

function XUiBigWorldProcessExploreGrid:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessExploreGrid:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessExploreGrid:OnDestroy()
end

function XUiBigWorldProcessExploreGrid:OnBtnHelpClick()
    if self._Entity then
        local teachId = self._Entity:GetTeachId()

        if XTool.IsNumberValid(teachId) then
            XMVCA.XBigWorldTeach:OpenTeachTipUi(teachId)
        end
    end
end

function XUiBigWorldProcessExploreGrid:OnBtnRewardClick()
    if not self._Entity then
        return
    end

    if self._Entity:IsAchieved() then
        self._Control:RequestBigWorldCourseExploreCntGetReward(self._Entity:GetVersionId(), self._Entity:GetExploreId())
    else
        self._Control:TryOpenRewardTips(self._Entity:GetRewardId())
    end
end

function XUiBigWorldProcessExploreGrid:OnRefreshRedPoint()
    self:_RefreshRedPoint()
end

---@param entity XBWCourseExploreEntity
function XUiBigWorldProcessExploreGrid:Refresh(entity)
    self._Entity = entity
    self:_Refresh(entity)
    self:_RefreshRedPoint()
    self:_RefreshReward(entity)
    self:_RefreshHelp(entity)
    self:_RefreshRegion(entity:GetPOIEntitys())
end

function XUiBigWorldProcessExploreGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnHelp:AddEventListener(handler(self, self.OnBtnHelpClick))
    self.BtnReward:AddEventListener(handler(self, self.OnBtnRewardClick))
end

function XUiBigWorldProcessExploreGrid:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH,
        self.OnRefreshRedPoint, self)
end

function XUiBigWorldProcessExploreGrid:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_COURSE_RED_POINT_REFRESH,
        self.OnRefreshRedPoint, self)
end

function XUiBigWorldProcessExploreGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessExploreGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessExploreGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessExploreGrid:_InitUi()
    self.GridRegion.gameObject:SetActiveEx(false)
end

---@param entity XBWCourseExploreEntity
function XUiBigWorldProcessExploreGrid:_Refresh(entity)
    self.ImgBackground:SetImage(entity:GetBanner())
    self.RImgIcon:SetImage(entity:GetIcon())
    self.TxtExploreName.text = entity:GetTitle()
    self.TxtRewardNum.text = entity:GetRewardProgressText()
    self.PanelReceive.gameObject:SetActiveEx(entity:IsComplete())
end

---@param entity XBWCourseExploreEntity
function XUiBigWorldProcessExploreGrid:_RefreshHelp(entity)
    local teachId = entity:GetTeachId()

    self.BtnHelp.gameObject:SetActiveEx(XTool.IsNumberValid(teachId))
end

---@param poiEntitys XBWCourseExplorePOIEntity[]
function XUiBigWorldProcessExploreGrid:_RefreshRegion(poiEntitys)
    local index = 1

    if not XTool.IsTableEmpty(poiEntitys) then
        for i, poiEntity in pairs(poiEntitys) do
            local regionGrid = self._RegionGrids[i]

            if not regionGrid then
                local grid = XUiHelper.Instantiate(self.GridRegion, self.ListRegion)

                regionGrid = XUiBigWorldProcessExploreRegion.New(grid, self)
                self._RegionGrids[i] = regionGrid
            end

            index = i
            regionGrid:Open()
            regionGrid:Refresh(poiEntity)
        end
    end

    for i = index + 1, #self._RegionGrids do
        self._RegionGrids[i]:Close()
    end
end

---@param entity XBWCourseExploreEntity
function XUiBigWorldProcessExploreGrid:_RefreshReward(entity)
    local rewardList = entity:GetRewardList()

    if not XTool.IsTableEmpty(rewardList) then
        local icon = entity:GetRewardIcon()

        if #rewardList == 1 and not string.IsNilOrEmpty(icon) then
            self.RImgRewardIcon:SetImage(icon)
            self.RImgTreasure.gameObject:SetActiveEx(false)
            self.RImgRewardIcon.gameObject:SetActiveEx(true)
        else
            self.RImgTreasure.gameObject:SetActiveEx(true)
            self.RImgRewardIcon.gameObject:SetActiveEx(false)
        end
    else
        self.RImgTreasure.gameObject:SetActiveEx(true)
        self.RImgRewardIcon.gameObject:SetActiveEx(false)
    end
end

function XUiBigWorldProcessExploreGrid:_RefreshRedPoint()
    if not self._Entity then
        self.BtnReward:ShowReddot(false)
        return
    end

    local versionId = self._Entity:GetVersionId()
    local exploreId = self._Entity:GetExploreId()

    if XTool.IsNumberValid(versionId) then
        self.BtnReward:ShowReddot(XMVCA.XBigWorldCourse:CheckExploreAchieved(versionId, exploreId))
    else
        self.BtnReward:ShowReddot(false)
    end
end

return XUiBigWorldProcessExploreGrid
