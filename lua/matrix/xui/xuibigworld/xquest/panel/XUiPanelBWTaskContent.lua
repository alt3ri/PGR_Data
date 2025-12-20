---@class XUiGridBWObjective : XUiNode
---@field _Control XBigWorldQuestControl
local XUiGridBWObjective = XClass(XUiNode, "XUiGridBWObjective")

---@param data XBigWorldQuestObjective | XBigWorldQuestStep
function XUiGridBWObjective:Refresh(data, isStep)
    self:Open()
    local title, progress, isFinish
    if isStep then
        title = self._Control:GetStepText(data:GetId())
        progress = ""
        isFinish = data:IsFinish()
    else
        title = self._Control:GetObjectiveProgressDesc(data:GetId(), data:GetProgress(), data:GetMaxProgress())
        progress = ""
        isFinish = data:IsFinish()
    end
    if self.UiGroup then
        self.UiGroup:SetTextWithGroup(0, title)
        self.UiGroup:SetTextWithGroup(1, progress)
    end
    if self.PanelOff then
        self.PanelOff.gameObject:SetActiveEx(not isFinish)
        self.PanelOn.gameObject:SetActiveEx(isFinish)
    end
end


---@class XUiPanelBWTaskContent : XUiNode
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field Parent XUiBigWorldTaskMain
---@field _Control XBigWorldQuestControl
---@field _StepGrid XUiGridBWObjective
local XUiPanelBWTaskContent = XClass(XUiNode, "XUiPanelBWTaskContent")

local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

function XUiPanelBWTaskContent:OnStart()
    self:InitCb()
    self:InitView()
end

function XUiPanelBWTaskContent:OnDisable()
    if self._StepGrid then
        self._StepGrid:Close()
    end
end

function XUiPanelBWTaskContent:InitCb()
    self.BtnGo:AddEventListener(handler(self, self.OnBtnGoClick))

    self.BtnTrack:AddEventListener(handler(self, self.OnBtnTrackClick))

    self.BtnUntrack:AddEventListener(handler(self, self.OnBtnUntrackClick))
end

function XUiPanelBWTaskContent:InitView()
    if not self.PanelRewardRoot then
        self.PanelRewardRoot = self.Transform:FindTransform("PanelRewardRoot")
    end
    self.GridCommonTask.gameObject:SetActiveEx(false)
    self._RewardGrids = {}
    self._ObjectiveGrids = {}

    self.BtnGo:ShowReddot(false)
    self.BtnTrack:ShowReddot(false)
    self.BtnUntrack:ShowReddot(false)
end

function XUiPanelBWTaskContent:RefreshView(questId)
    self._QuestId = questId
    self.TxtTitle.text = self._Control:GetQuestName(questId)
    local stepData = self._Control:GetActiveStepData(questId)
    self:RefreshReward(questId)
    self:RefreshDetail(stepData)
    self:RefreshBtn()
    local isFavorableQuestType = XMVCA.XBigWorldQuest:IsFavorableQuestType(questId)
    self.ImgRoot.gameObject:SetActiveEx(isFavorableQuestType)
    self.PanelImg.gameObject:SetActiveEx(isFavorableQuestType)
    if isFavorableQuestType then
        self.RImgBanner:SetRawImage(XMVCA.XBigWorldQuest:GetQuestBanner(questId))
    end
end

function XUiPanelBWTaskContent:RefreshBtn()
    local questId = self._QuestId
    local isTrack = self._Control:IsTrackQuest(questId)
    self.BtnGo.gameObject:SetActiveEx(isTrack)
    self.BtnTrack.gameObject:SetActiveEx(not isTrack)
    self.BtnUntrack.gameObject:SetActiveEx(isTrack)
    self.BtnSubmit.gameObject:SetActiveEx(false)
end

---@param questId number
function XUiPanelBWTaskContent:RefreshReward(questId)
    local count = 0
    if questId and questId > 0 then
        local rewardId = self._Control:GetQuestRewardId(questId)
        if rewardId and rewardId > 0 then
            local rewardList = XRewardManager.GetRewardList(rewardId)
            self.PanelRewardRoot.gameObject:SetActiveEx(true)
            for _, reward in pairs(rewardList) do
                count = count + 1
                local grid = self._RewardGrids[count]
                if not grid then
                    local ui = count == 0 and self.GridCommonTask or XUiHelper.Instantiate(self.GridCommonTask, self.PanelReward.transform)
                    ui.name = count
                    
                    grid = XUiGridBWItem.New(ui, self)
                    self._RewardGrids[count] = grid
                end
                grid:Open()
                grid:Refresh(reward)
            end
        end
    end
    local hasReward = count > 0
    self.PanelRewardRoot.gameObject:SetActiveEx(hasReward)
    for index, grid in pairs(self._RewardGrids) do
        if index > count then
           grid:Close()
        end
    end
end

---@param step XBigWorldQuestStep
function XUiPanelBWTaskContent:RefreshDetail(step)
    if step then
        local objectiveList = XMVCA.XBigWorldQuest:GetObjectiveListWithStep(step)
        self:RefreshObjective(objectiveList)
    end
    self:RefreshStep(step)
end

---@param step XBigWorldQuestStep
function XUiPanelBWTaskContent:RefreshStep(step)
    local count = 0
    self.StepRoot.gameObject:SetActiveEx(true)
    if step then
        local stepDesc = self._Control:GetStepText(step:GetId())
        if not string.IsNilOrEmpty(stepDesc) then
            count = count + 1
            local grid = self._StepGrid
            if not grid then
                grid = XUiGridBWObjective.New(self.GridStep, self)
                self._StepGrid = grid
            end
            grid:Refresh(step, true)
        end
    end
    self.StepRoot.gameObject:SetActiveEx(count > 0)
end

function XUiPanelBWTaskContent:RefreshObjective(objectiveList)
    local count = 0
    local desc = ""
    self.ObjectiveRoot.gameObject:SetActiveEx(true)
    if not XTool.IsTableEmpty(objectiveList) then
        for i, objective in pairs(objectiveList) do
            local grid = self._ObjectiveGrids[i]
            if not grid then
                local ui = i == 1 and self.GridObjective or XUiHelper.Instantiate(self.GridObjective, self.ObjectiveRoot.transform)
                grid = XUiGridBWObjective.New(ui, self.Parent)
                self._ObjectiveGrids[i] = grid
            end
            grid:Refresh(objective, false)
            count = i
        end
        desc = self._Control:GetObjectiveDescription(objectiveList[1]:GetId())
    end
    for i = count + 1, #self._ObjectiveGrids do
        local grid = self._ObjectiveGrids[i]
        grid:Close()
    end
    self.ObjectiveRoot.gameObject:SetActiveEx(count > 0)
    self.TxtStep.text = desc
end

function XUiPanelBWTaskContent:OnBtnGoClick()
    local questId = self._QuestId
    local data = XMVCA.XBigWorldQuest:GetQuestSkipInfo(questId)
    XMVCA.XBigWorldQuest:TrySkipToByFightSkipInfo(data)
end

function XUiPanelBWTaskContent:OnBtnTrackClick()
    local questId = self._QuestId
    XMVCA.XBigWorldQuest:TrackQuest(questId, function()
        self:RefreshBtn()
        self.Parent:RefreshTabButton()
        local data = XMVCA.XBigWorldQuest:GetQuestSkipInfo(questId)
        local state = XMVCA.XBigWorldQuest:CheckSkipToByFightSkipInfo(data)
        if state  == XMVCA.XBigWorldQuest.EQuestSkipToByFightState.None then
            self.Parent:Close()
        elseif state == XMVCA.XBigWorldQuest.EQuestSkipToByFightState.NotExistMap
                or state == XMVCA.XBigWorldQuest.EQuestSkipToByFightState.NotExistMessage
                or state == XMVCA.XBigWorldQuest.EQuestSkipToByFightState.NotExistPin then
            self.Parent:Close()
        elseif state == XMVCA.XBigWorldQuest.EQuestSkipToByFightState.SameAreaGroup then
            self.Parent:Close()
        else
            XMVCA.XBigWorldQuest:TrySkipToByFightSkipInfo(data)
        end
    end)
end

function XUiPanelBWTaskContent:OnBtnUntrackClick()
    XMVCA.XBigWorldQuest:UnTrackQuest(self._QuestId, function()
        self:RefreshBtn()
        self.Parent:RefreshTabButton()
    end)
end

return XUiPanelBWTaskContent