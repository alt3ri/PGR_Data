---@class XUiSkyGardenShoppingStreetTargetGridTarget : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field TxtDetail UnityEngine.UI.Text
---@field ImgComplete UnityEngine.UI.Image
---@field TxtNum UnityEngine.UI.Text
local XUiSkyGardenShoppingStreetTargetGridTarget = XClass(XUiNode, "XUiSkyGardenShoppingStreetTargetGridTarget")

--region 刷新逻辑
function XUiSkyGardenShoppingStreetTargetGridTarget:Update(taskConfigId, index)
    if not self._GridCommon and self.UiBigWorldItemGrid then
        local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
        self._GridCommon = XUiGridBWItem.New(self.UiBigWorldItemGrid, self)
    end

    if type(taskConfigId) == "table" then
        if taskConfigId.TaskId then
            self:Update(taskConfigId.TaskId, index)
            return
        end

        self.TxtTitle.text = taskConfigId.ConditionDesc
        self.TxtDetail.text = taskConfigId.ConditionDetailDesc
        self.TxtNum.text = ""
        self.TxtDetailDesc.text = ""

        if self._GridCommon then
            local rewards = XRewardManager.GetRewardList(taskConfigId.RewardId)
            self._GridCommon:Refresh(rewards[1])
            -- 奖励是否显示已获取
            local PanelReceive = self._GridCommon.PanelReceive
            if PanelReceive then
                PanelReceive.gameObject:SetActive(taskConfigId.IsGet)
            end
            self.ImgComplete.gameObject:SetActive(taskConfigId.IsGet)
        end
        return
    end

    self._index = index
    local config = self._Control:GetStageTaskConfigsById(taskConfigId)
    self._Config = config
    if self.TxtDetailDesc then
        self.TxtDetailDesc.text = config.AccountDesc
    end
    local scheduleDiv = config.ScheduleDiv
    if not scheduleDiv or scheduleDiv == 0 then
        scheduleDiv = 1
    end
    self.TxtTitle.text = config.Name
    self.TxtDetail.text = config.ConditionDesc

    local taskData = self._Control:GetTaskDataByConfigId(taskConfigId)
    if taskData then
        self.TxtNum.text = XTool.MathGetRoundingValueStandard(taskData.Schedule / scheduleDiv, 1) .. "/" .. XTool.MathGetRoundingValueStandard(config.Schedule / scheduleDiv, 1)
        self.ImgComplete.gameObject:SetActive(taskData.Schedule >= config.Schedule)
    else
        self.TxtNum.text = 0 .. "/" .. XTool.MathGetRoundingValueStandard(config.Schedule / scheduleDiv, 1)
        self.ImgComplete.gameObject:SetActive(false)
    end

    if self.Parent.GetStageId then
        if self._GridCommon then
            local stageId = self.Parent:GetStageId()
            local stageCfg = self._Control:GetStageConfigsByStageId(stageId)
            local rewardId = stageCfg.TargetTaskRewards[index]
            local rewards = XRewardManager.GetRewardList(rewardId)
            self._GridCommon:Refresh(rewards[1])
    
            local isShowFinish = self._Control:GetRewardIndexRecordAndIndex(stageId, self._index)
            -- 奖励是否显示已获取
            self._GridCommon.PanelReceive.gameObject:SetActive(isShowFinish)
        end
    else
        if self.UiBigWorldItemGrid then
            self.UiBigWorldItemGrid.gameObject:SetActive(false)
        end
    end
end

function XUiSkyGardenShoppingStreetTargetGridTarget:SetFinish(cb)
    local scheduleDiv = self._Config.ScheduleDiv
    if not scheduleDiv or scheduleDiv == 0 then
        scheduleDiv = 1
    end
    local num = XTool.MathGetRoundingValueStandard(self._Config.Schedule / scheduleDiv, 1)
    self.TxtNum.text = num .. "/" .. num
    self.ImgComplete.gameObject:SetActive(true)

    if cb then
        self.UiSkyGardenShoppingStreetGridTarget:AddEventListener(function () cb(self._index) end)
    end
end

function XUiSkyGardenShoppingStreetTargetGridTarget:PlayAnim(isEnable, startCb, endCb)
    if isEnable and self.GridTargetEnable then
        if self.GridTargetEnable.gameObject.activeInHierarchy then
            self.GridTargetEnable.gameObject:PlayTimelineAnimation(endCb, startCb, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
        end
    end
    if not isEnable and self.GridTargetDisable then
        if self.GridTargetDisable.gameObject.activeInHierarchy then
            self.GridTargetDisable.gameObject:PlayTimelineAnimation(endCb, startCb, CS.UnityEngine.Playables.DirectorWrapMode.Hold)
        end
    end
end
--endregion

return XUiSkyGardenShoppingStreetTargetGridTarget
