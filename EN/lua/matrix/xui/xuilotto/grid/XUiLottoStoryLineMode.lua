---@class XUiLottoStoryLineMode : XUiNode
local XUiLottoStoryLineMode = XClass(XUiNode, "XUiLottoStoryLineMode")

function XUiLottoStoryLineMode:OnStart()
end

function XUiLottoStoryLineMode:InitStageList()
    local storyObj = self.PaneStageLine
    XTool.InitUiObjectByInstance(storyObj, self) -- 将line的UiObjet引用加进来

    local stageActivityId = XLottoConfigs.GetLottoStageActivity(self.Parent._LottoGroupData:GetId())
    local festivalActivity = XFestivalActivityConfig.GetFestivalById(stageActivityId)
    local XStageItem = require("XUi/XUiEpicFashionGacha/Grid/XStageItem")

    ---@type XStageItem[]
    self._StageGridList = {}
    self._StageIndexDir = {}

    for i, stageId in pairs(festivalActivity.StageId) do
        if self["Stage"..i] then
            self._StageGridList[i] = XStageItem.New(self, self["Stage"..i])
            self._StageIndexDir[stageId] = i
        end
    end
end

function XUiLottoStoryLineMode:RefreshStageList()
    self.PaneStageLine.gameObject:SetActiveEx(true)
    local newIndex = 0
    for stageId, index in pairs(self._StageIndexDir) do
        local activityId = XLottoConfigs.GetLottoStageActivity(self.Parent._LottoGroupData:GetId())
        local fStage = XDataCenter.FubenFestivalActivityManager.GetFestivalStageByFestivalIdAndStageId(activityId, stageId)
        local isOpen, _ = fStage:GetCanOpen()
        if isOpen then
            if self["Line"..(index - 1)] then
                self["Line"..(index - 1)].gameObject:SetActiveEx(true)
            end
            self._StageGridList[index].GameObject:SetActiveEx(true)
            self._StageGridList[index]:UpdateNode(activityId, stageId)
            newIndex = math.max(newIndex, index)
        else
            if self["Line"..(index - 1)] then
                self["Line"..(index - 1)].gameObject:SetActiveEx(false)
            end
            self._StageGridList[index].GameObject:SetActiveEx(false)
        end
    end
    self:MoveIntoStage(newIndex)
end

function XUiLottoStoryLineMode:UpdateNodesSelect(stageId)
    for gridStageId, index in pairs(self._StageIndexDir) do
        self._StageGridList[index]:SetNodeSelect(gridStageId == stageId)
        if gridStageId == stageId then
            self._LastOpenStage = index
        end
    end
end

function XUiLottoStoryLineMode:OpenStageDetails(stageId)
    XLuaUiManager.Open("UiEpicFashionGachaStageDetail", stageId)
end

function XUiLottoStoryLineMode:MoveIntoStage(stageIndex)
    if not self._StageGridList[stageIndex] then
        return
    end
    local gridRect = self._StageGridList[stageIndex].Transform
    local diffX = gridRect.localPosition.x + self.PanelStageContent.localPosition.x
    local left = 100

    if diffX > CS.XResolutionManager.OriginWidth / 2 - left then
        local tarPosX = (CS.XResolutionManager.OriginWidth / 4) - gridRect.localPosition.x - left
        local tarPos = self.PanelStageContent.localPosition
        tarPos.x = tarPosX
        XLuaUiManager.SetMask(true)
        if self.PanelStageList then
            self.PanelStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Unrestricted
        end
        XUiHelper.DoMove(self.PanelStageContent, tarPos, XDataCenter.FubenMainLineManager.UiGridChapterMoveDuration, XUiHelper.EaseType.Sin, function()
            XLuaUiManager.SetMask(false)

            if self.PanelStageList then
                self.PanelStageList.movementType = CS.UnityEngine.UI.ScrollRect.MovementType.Elastic
            end
        end)
    end
end

return XUiLottoStoryLineMode