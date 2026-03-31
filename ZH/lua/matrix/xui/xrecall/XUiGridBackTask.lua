---@class XUiGridBackTask: XUiNode
---@field protected _Control XReCallActivityControl
---@field Parent
local XUiGridBackTask = XClass(XUiNode, "XUiGridBackTask")

function XUiGridBackTask:OnStart(typeIndex)
    self._SkipType = {
        ExTaskGroup = 1,
        DoubleReward = 2,
    }
    
    self.TypeIndex = typeIndex
    
    self:Init()
end

function XUiGridBackTask:Init()
    -- 显示固定的内容
    self.TxtDesc.text = XMVCA.XReCallActivity:GetClientConfigReCallText("BackOnlySkipDesc", self.TypeInex)
    self.BtnGo:AddEventListener(handler(self, self.OnBtnGoClickEvent))
end

function XUiGridBackTask:Refresh()
    -- 显示进度
    local progressDescFormat = XMVCA.XReCallActivity:GetClientConfigReCallText("BackOnlyProgressDesc", self.TypeIndex)

    if self.TypeIndex == self._SkipType.ExTaskGroup then
        self:_RefreshExTaskGroupProgress(progressDescFormat)
    elseif self.TypeIndex == self._SkipType.DoubleReward then
        self:_RefreshDoubleRewardTimes(progressDescFormat)
    end
end

function XUiGridBackTask:OnBtnGoClickEvent()
    local skipId = XMVCA.XReCallActivity:GetClientConfigReCallNumber("BackOnlySkipIds", self.TypeIndex)

    if XTool.IsNumberValidEx(skipId) then
        XFunctionManager.SkipInterface(skipId)
    end
end

function XUiGridBackTask:_RefreshExTaskGroupProgress(format)
    ---@type XTaskData[]
    local taskDataList = XMVCA.XReCallActivity:GetRegressionTaskDataList()

    if XTool.IsTableEmpty(taskDataList) then
        self.TxtNum.text = ''
        return
    end
    
    local totalCount = #taskDataList
    local finishedCount = 0

    for i, v in pairs(taskDataList) do
        if v.State == XDataCenter.TaskManager.TaskState.Finish then
            finishedCount = finishedCount + 1
        end
    end

    self.TxtNum.text = XUiHelper.FormatTextEx(format, finishedCount, totalCount)
end

function XUiGridBackTask:_RefreshDoubleRewardTimes(format)
    local stageId = XDataCenter.FubenRepeatChallengeManager.GetStageId()
    local curTimes = self._Control:GetCurRegressionPlayerMultiRewardCount(stageId)
    local maxTimes = self._Control:GetMaxRegressionPlayerMultiRewardCount()
    
    self.TxtNum.text = XUiHelper.FormatTextEx(format, curTimes, maxTimes)
end

return XUiGridBackTask