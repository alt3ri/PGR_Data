---@class XUiGridRiftStage : XUiNode
---@field Parent XUiRiftFightLayerSelect
---@field _Control XRiftControl
local XUiGridRiftStage = XClass(XUiNode, "XUiGridRiftStage")

local MathLerp = CS.UnityEngine.Mathf.Lerp

function XUiGridRiftStage:OnStart()
    self._Speed = self._Control:GetProgressSpeed()

    XUiHelper.RegisterClickEvent(self, self.GridStage, self.TryEnterStage)
end

function XUiGridRiftStage:Init(fightLayer,index)
    ---@type XRiftFightLayer
    self._FightLayer = fightLayer
    self.GridStage:SetNameByGroup(2, string.format("0%s", index))
end

function XUiGridRiftStage:Update()
    local isPassed = self._Control:CheckLayerFirstPassed(self._FightLayer:GetFightLayerId())
    local isChallenge = self._FightLayer:IsChallenge()
    local isEndless = self._FightLayer:GetParent():IsEndless()
    local hasStory = self._FightLayer:HasStory()
    self.GridStage:SetSpriteVisible(isPassed)
    self.ImgStory.gameObject:SetActiveEx(hasStory)
    if self.ImgStory2 then
        self.ImgStory2.gameObject:SetActiveEx(hasStory)
    end
    if self._FightLayer:CheckHasLock() then
        self.GridStage:SetButtonState(CS.UiButtonState.Disable)
        self.PanelBar.gameObject:SetActiveEx(true)
        self.GridStage:SetNameByGroup(0, "")
    else
        self.GridStage:SetButtonState(CS.UiButtonState.Normal)
        self.PanelBar.gameObject:SetActiveEx(not isChallenge and not isEndless)
        if isChallenge or isEndless then -- 挑战关和无尽关没有关卡进度
            self.ImgBar.fillAmount = 1
            self.GridStage:SetNameByGroup(0, self._FightLayer:GetConfig().Name)
        elseif isPassed then -- 通关
            self.ImgBar.fillAmount = 1
            self.GridStage:SetNameByGroup(0, 100)
        else
            local progress = self._FightLayer:GetFightProgress()
            self.ImgBar.fillAmount = progress
            self.GridStage:SetNameByGroup(0, math.floor(progress * 100))
        end
    end
    if self.PanelTime then
        local str = ""
        if isPassed then
            if isEndless then
                str = self._FightLayer:GetParent():GetScore()
            else
                str = XUiHelper.GetTime(self._FightLayer:GetParent():GetPassTime(), XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
            end
        end
        self.GridStage:SetNameByGroup(2, str)
    end
    if self.ImgIcon1 then
        self.ImgIcon1.gameObject:SetActiveEx(not isPassed)
    end
    if self.ImgIcon2 then
        self.ImgIcon2.gameObject:SetActiveEx(not isPassed)
    end
    if not isChallenge and not isEndless then
        self.GridStage:SetNameByGroup(1, self._FightLayer:GetConfig().Name)
    else
        self.GridStage:SetNameByGroup(1, "")
    end
    if isChallenge then
        self.GridStage:SetNameByGroup(3, XUiHelper.GetText("RiftBestTime"))
    elseif isEndless then
        self.GridStage:SetNameByGroup(3, XUiHelper.GetText("RiftBestScore"))
    end
    self:RefreshReddot()
end

function XUiGridRiftStage:RefreshReddot()
    self.GridStage:ShowReddot(self._FightLayer:CheckRedPoint())
end

function XUiGridRiftStage:TryEnterStage()
    if self._FightLayer:CheckHasLock() then
        XUiManager.TipError(XUiHelper.GetText("RiftLayerLimit2"))
        return
    end

    self:EnterStage()
end

function XUiGridRiftStage:EnterStage()
    local stageGroup = self._FightLayer:GetStageGroup()
    if not stageGroup then
        return
    end

    self._Control:SetCurrSelectRiftStage(stageGroup)
    self._FightLayer:SaveFirstEnter()

    self:RefreshReddot()
    self.Parent:OnGridFightLayerSelected(self._FightLayer)

    local storyId = self._FightLayer:GetConfig().StoryId
    if not self._FightLayer:CheckFirstPassed() and self._FightLayer:HasStory() and not XSaveTool.GetData(string.format("RiftStory_%s_%s", storyId, XPlayer.Id)) then
        XDataCenter.UiQueueManager.Open("UiRiftPopupStory", storyId)
    end
    if self._FightLayer:IsChallenge() then
        XDataCenter.UiQueueManager.Open("UiRiftPopupChallengeStageDetail", self._FightLayer, false)
    else
        XDataCenter.UiQueueManager.Open("UiRiftPopupStageDetail", self._FightLayer, false)
    end
end

function XUiGridRiftStage:PlayProgressTween()
    local isPassed = self._Control:CheckLayerFirstPassed(self._FightLayer:GetFightLayerId())
    local isChallenge = self._FightLayer:IsChallenge()
    if isPassed or isChallenge then
        return
    end

    local progress = self._FightLayer:GetFightProgress()
    self._Timer = XUiHelper.Tween(progress * self._Speed, function(t)
        local value = MathLerp(0, progress, t)
        self.ImgBar.fillAmount = value
        self.GridStage:SetNameByGroup(0, math.floor(value * 100))
    end)
end

function XUiGridRiftStage:StopProgressTween()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

return XUiGridRiftStage