---@class XUiGridSGStageListItem : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiPanelSGStageList
---@field _Control XSkyGardenCafeControl
local XUiGridSGStageListItem = XClass(XUiNode, "XUiGridSGStageListItem")

--local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")
local XUiGridSGStageReward = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGStageReward")

local MAX_STAR = 3

local StarKey = {
    On = "On",
    Off = "Off"
}

function XUiGridSGStageListItem:OnStart()
    self:InitCb()
    self:InitView()
end

function XUiGridSGStageListItem:InitCb()
end

function XUiGridSGStageListItem:InitView()
    self._GridStars = {}
    self._Rewards = {}
    self.GridReward.gameObject:SetActiveEx(false)
end

function XUiGridSGStageListItem:Refresh(stageId)
    self.TxtTitle.text = self._Control:GetStageName(stageId)
    local info = self._Control:GetStageInfo(stageId)
    local star = info:GetStar()
    for i = 1, MAX_STAR do
        local grid = self._GridStars[i]
        if not grid then
            grid = i == 1 and self.GridStar or XUiHelper.Instantiate(self.GridStar, self.ListStar.transform)
            grid:SetInitialState(StarKey.Off)
            self._GridStars[i] = grid
        end
        grid:ChangeState(i <= star and StarKey.On or StarKey.Off)
    end
    local isClear = star >= MAX_STAR
    self.ImgClear.gameObject:SetActiveEx(isClear)
    if self.RImgLock then
        local unlock = self._Control:IsStageUnlock(stageId)
        self.RImgLock.gameObject:SetActiveEx(not unlock)
        if not unlock then
            local preStageId = self._Control:GetPreStageId(stageId)
            local txt = self._Control:GetStageLockText(preStageId)
            self.TxtLock.text = txt
        end
    end
    self:RefreshReward(stageId)
    local showRed = self._Control:CheckStageNewMark(stageId)
    if self.RedPoint then
        self.RedPoint.gameObject:SetActiveEx(showRed)
    end
end

function XUiGridSGStageListItem:RefreshReward(stageId)
    local rewardIds = self._Control:GetStageReward(stageId)
    local rewards = {}
    local targets = self._Control:GetStageTarget(stageId)
    local star = self._Control:GetStageInfo(stageId):GetStar()
    if not XTool.IsTableEmpty(rewardIds) then
        for index, rewardId in pairs(rewardIds) do
            local list = XRewardManager.GetRewardList(rewardId)
            if list then
                --只显示第一个
                rewards[#rewards + 1] = {
                    Reward = list[1],
                    Target = targets and targets[index] or 0,
                    IsReceive = star >= index
                }
            end
        end
    end

    XTool.UpdateDynamicItem(self._Rewards, rewards, self.GridReward, XUiGridSGStageReward, self)
end

function XUiGridSGStageListItem:PlayClickAnimation(cb)
    self.GridStageClick:PlayTimelineAnimation(cb, nil, CS.UnityEngine.Playables.DirectorWrapMode.None)
end

return XUiGridSGStageListItem