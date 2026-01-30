local XUiBigWorldProcessCourseRewardGrid = require("XUi/XUiBigWorld/XProcess/Course/XUiBigWorldProcessCourseRewardGrid")

---@class XUiBigWorldProcessCourseReward : XUiNode
---@field TxtNum UnityEngine.UI.Text
---@field ListReward UnityEngine.RectTransform
---@field RewardGrid UnityEngine.RectTransform
---@field SpecialRewardGrid UnityEngine.RectTransform
---@field ImgPointOn UnityEngine.UI.Image
---@field ImgPointOff UnityEngine.UI.Image
---@field Parent XUiBigWorldProcessCourse
---@field RImgOnIcon UnityEngine.UI.RawImage
---@field RImgOnIconBig UnityEngine.UI.RawImage
---@field RImgOffIcon UnityEngine.UI.RawImage
---@field RImgOffIconBig UnityEngine.UI.RawImage
---@field _Control XBigWorldCourseControl
local XUiBigWorldProcessCourseReward = XClass(XUiNode, "XUiBigWorldProcessCourseReward")

function XUiBigWorldProcessCourseReward:OnStart()
    ---@type XBWCourseTaskProgressEntity
    self._Entity = false
    ---@type XUiBigWorldProcessCourseRewardGrid[]
    self._RewardGrids = {}

    self.SpecialRewardGrid = self.SpecialRewardGrid or self.RewardGrid

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessCourseReward:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessCourseReward:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessCourseReward:OnDestroy()
end

---@param progressEntity XBWCourseTaskProgressEntity
function XUiBigWorldProcessCourseReward:Refresh(progressEntity)
    self._Entity = progressEntity
    self.ImgPointOff.gameObject:SetActiveEx(not progressEntity:IsComplete())
    self.ImgPointOn.gameObject:SetActiveEx(progressEntity:IsComplete())
    self.TxtNum.text = tostring(progressEntity:GetProgress())
    self:_RefreshRewards(progressEntity:GetRewardList(true), progressEntity:IsSpecial())
    self:_RefreshIcon(progressEntity:GetProgressIconNoneColor())
    self:_PlayProcessCue(progressEntity)
end

function XUiBigWorldProcessCourseReward:PlayDisableAnimation()
    if self:IsNodeShow() then
        self:PlayAnimation("GridRewardDisable")
        for _, grid in pairs(self._RewardGrids) do
            grid:PlayDisableAnimation()
        end
    end
end

function XUiBigWorldProcessCourseReward:_RegisterButtonClicks()
    -- 在此处注册按钮事件
end

function XUiBigWorldProcessCourseReward:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldProcessCourseReward:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldProcessCourseReward:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessCourseReward:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessCourseReward:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessCourseReward:_InitUi()
    self.RewardGrid.gameObject:SetActiveEx(false)
    self.SpecialRewardGrid.gameObject:SetActiveEx(false)
end

function XUiBigWorldProcessCourseReward:_RefreshRewards(rewardList, isSpecial)
    local count = 0

    if not XTool.IsTableEmpty(rewardList) then
        local gridObject = isSpecial and self.SpecialRewardGrid or self.RewardGrid

        for i, reward in pairs(rewardList) do
            local grid = self._RewardGrids[i]

            if not grid then
                local gridUi = XUiHelper.Instantiate(gridObject, self.ListReward)

                grid = XUiBigWorldProcessCourseRewardGrid.New(gridUi, self)
                self._RewardGrids[i] = grid
            end

            grid:Open()
            grid:Refresh(self._Entity, reward)
            count = count + 1
        end
    end
    for i = count + 1, #self._RewardGrids do
        self._RewardGrids[i]:Close()
    end
end

function XUiBigWorldProcessCourseReward:_RefreshIcon(icon)
    if not string.IsNilOrEmpty(icon) then
        self.RImgOnIcon.gameObject:SetActiveEx(true)
        self.RImgOnIconBig.gameObject:SetActiveEx(true)
        self.RImgOffIcon.gameObject:SetActiveEx(true)
        self.RImgOffIconBig.gameObject:SetActiveEx(true)
        self.RImgOnIcon:SetImage(icon)
        self.RImgOnIconBig:SetImage(icon)
        self.RImgOffIcon:SetImage(icon)
        self.RImgOffIconBig:SetImage(icon)
    else
        self.RImgOnIcon.gameObject:SetActiveEx(false)
        self.RImgOnIconBig.gameObject:SetActiveEx(false)
        self.RImgOffIcon.gameObject:SetActiveEx(false)
        self.RImgOffIconBig.gameObject:SetActiveEx(false)
    end
end

---@param progressEntity XBWCourseTaskProgressEntity
function XUiBigWorldProcessCourseReward:_PlayProcessCue(progressEntity)
    if progressEntity:IsComplete() and progressEntity:IsCompleteStateChange() then
        self.Parent:PlayTaskProcessAudio()
        self._Control:SyncCurrentRecordTaskProgress(progressEntity:GetVersionId())
    end
end

return XUiBigWorldProcessCourseReward
