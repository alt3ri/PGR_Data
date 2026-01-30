local XBWCourseEntityBase = require("XModule/XBigWorldCourse/XEntity/XBWCourseEntityBase")
local XBWCourseExplorePOIEntity = require("XModule/XBigWorldCourse/XEntity/Explore/XBWCourseExplorePOIEntity")

---@field private _ParentEntity XBWCourseContentEntity
---@class XBWCourseExploreEntity : XBWCourseEntityBase
local XBWCourseExploreEntity = XClass(XBWCourseEntityBase, "XBWCourseExploreEntity")

function XBWCourseExploreEntity:OnInit(exploreId)
    ---@type XBWCourseExplorePOIEntity[]
    self._POIEntitys = false

    self:SetExploreId(exploreId)
end

function XBWCourseExploreEntity:IsNil()
    return not XTool.IsNumberValid(self:GetExploreId())
end

function XBWCourseExploreEntity:IsAchieved()
    if not self:IsNil() then
        local poiEntitys = self:GetPOIEntitys()
        local isPOIComplete = true

        if not XTool.IsTableEmpty(poiEntitys) then
            for _, poiEntity in pairs(self._POIEntitys) do
                if not poiEntity:IsComplete() then
                    isPOIComplete = false
                    break
                end
            end
        end

        return isPOIComplete and not self:IsComplete()
    end

    return false
end

function XBWCourseExploreEntity:IsComplete()
    if not self:IsNil() then
        return self._Model:CheckExploreRewardAcquired(self:GetVersionId(), self:GetExploreId())
    end

    return false
end

function XBWCourseExploreEntity:SetExploreId(exploreId)
    self._ExploreId = exploreId or 0
    self:_Init()
end

function XBWCourseExploreEntity:GetExploreId()
    return self._ExploreId
end

function XBWCourseExploreEntity:GetContentId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExploreContentIdByExploreId(self:GetExploreId())
    end

    return 0
end

function XBWCourseExploreEntity:GetVersionId()
    if not self:IsNil() then
        return self._ParentEntity:GetVersionId()
    end

    return 0
end

function XBWCourseExploreEntity:GetTeachId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExploreTeachIdByExploreId(self:GetExploreId())
    end

    return ""
end

function XBWCourseExploreEntity:GetTitle()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExploreTitleByExploreId(self:GetExploreId())
    end

    return ""
end

function XBWCourseExploreEntity:GetBanner()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExploreBannerByExploreId(self:GetExploreId())
    end

    return ""
end

function XBWCourseExploreEntity:GetIcon()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExploreIconByExploreId(self:GetExploreId())
    end

    return ""
end

function XBWCourseExploreEntity:GetPriority()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExplorePriorityByExploreId(self:GetExploreId())
    end

    return 0
end

function XBWCourseExploreEntity:GetGuideId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExploreGuideIdByExploreId(self:GetExploreId())
    end

    return 0
end

function XBWCourseExploreEntity:GetType()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExploreTypeByExploreId(self:GetExploreId())
    end

    return XEnumConst.BWCourse.ExploreType.None
end

function XBWCourseExploreEntity:GetRewardId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExploreRewardIdByExploreId(self:GetExploreId())
    end

    return 0
end

function XBWCourseExploreEntity:GetRewardList()
    local rewardId = self:GetRewardId()

    if XTool.IsNumberValid(rewardId) then
        return XMVCA.XBigWorldService:GetRewardDataList(rewardId)
    end

    return nil
end

function XBWCourseExploreEntity:GetFirstReward()
    local rewardList = self:GetRewardList()

    if not XTool.IsTableEmpty(rewardList) then
        return rewardList[1]
    end

    return nil
end

function XBWCourseExploreEntity:GetRewardIcon()
    local reward = self:GetFirstReward()

    if reward then
        return XMVCA.XBigWorldService:GetGoodsIconByTemplateId(reward.TemplateId)
    end

    return ""
end

function XBWCourseExploreEntity:GetRewardProgressText()
    local entitys = self:GetPOIEntitys()

    if not XTool.IsTableEmpty(entitys) then
        local totalProgress = 0
        local currentProgress = 0

        for _, poiEntity in pairs(self._POIEntitys) do
            totalProgress = totalProgress + poiEntity:GetTotalProgress()
            currentProgress = currentProgress + poiEntity:GetCurrentProgress()
        end

        if not XTool.IsNumberValid(totalProgress) then
            return ""
        end

        return string.format("%d/%d", currentProgress, totalProgress)
    end

    return ""
end

function XBWCourseExploreEntity:GetTimeId()
    if not self:IsNil() then
        return self._Model:GetBigWorldCourseExploreTimeIdByExploreId(self:GetExploreId())
    end

    return 0
end

---@return XBWCourseExplorePOIEntity[]
function XBWCourseExploreEntity:GetPOIEntitys()
    return self._POIEntitys or {}
end

function XBWCourseExploreEntity:_Init()
    if not self:IsNil() then
        local poiIds = self._Model:GetBigWorldCourseExplorePOIIdsByExploreId(self:GetExploreId())

        self._POIEntitys = {}
        if not XTool.IsTableEmpty(poiIds) then
            for _, poiId in pairs(poiIds) do
                self:_AddPOIEntity(poiId)
            end
            table.sort(self._POIEntitys, function(poiA, poiB)
                return poiA:GetPriority() > poiB:GetPriority()
            end)
        end
    end
end

function XBWCourseExploreEntity:_AddPOIEntity(poiId)
    table.insert(self._POIEntitys, self:AddChildEntity(XBWCourseExplorePOIEntity, poiId))
end

return XBWCourseExploreEntity
