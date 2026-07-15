local XUiGridFubenBossSingleModeBuffSmall =
    require("XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiGridFubenBossSingleModeBuffSmall")

local XUiGridFubenBossSingleModeBuffBig =
    require("XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiGridFubenBossSingleModeBuffBig")

local XUiFubenBossSinglePopupModeTips =
    require("XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiFubenBossSinglePopupModeTips")

---@class XUiPanelBossRightV4P5 : XUiNode
---@field Parent XUiFubenBossSingleModeDetail
---@field _SelectedFeatureIndex int
---@field _SmallBuffGrids XUiGridFubenBossSingleModeBuffSmall[]
---@field _BigBuffGrid XUiGridFubenBossSingleModeBuffBig
---@field _SmallBuffGridsShowing UnityEngine.UI.RectTransform[]
---@field _Control XFubenBossSingleControl


local XUiPanelBossRightV4P5 = XClass(XUiNode, "XUiPanelBossRightV4P5")

function XUiPanelBossRightV4P5:OnStart()
    -- 0的状态为未选择
    self._SelectedFeatureIndex = 0
    self._SmallBuffGrids = {}
    self._BigBuffGrid = XUiGridFubenBossSingleModeBuffBig.New(self.GirdBuffBig, self)

    self.BtnAttributeDetail.CallBack = self._OnBtnAttributeDetailClick
    self.BtnSelectModule.gameObject:SetActiveEx(false)
    self.BtnStart.CallBack = handler(self, self._OnBtnSelectModuleClick)

    self:RefreshWholeView()

    for _, grid in pairs(self._SmallBuffGrids) do
        grid:PlayExtendAnimation()
    end

    XLuaUiManager.SetMask(true)
    self._OpenAnimationMaskOffSchedule = XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.SetMask(false)
        XScheduleManager.UnSchedule(self._OpenAnimationMaskOffSchedule)
        self._OpenAnimationMaskOffSchedule = nil
    end, 2000)
end

function XUiPanelBossRightV4P5:OnEnable()
    XEventManager.AddEventListener(
        XEventId.EVENT_FUBEN_SINGLE_BOSS_RANK_SYNC,
        self.RefreshWholeView,
        self)

    XEventManager.AddEventListener(
        XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET,
        self.RefreshWholeView,
        self)
end

function XUiPanelBossRightV4P5:OnDisable()
    XEventManager.RemoveEventListener(
        XEventId.EVENT_FUBEN_SINGLE_BOSS_RANK_SYNC,
        self.RefreshWholeView,
        self)

    XEventManager.RemoveEventListener(
        XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET,
        self.RefreshWholeView,
        self)
end

function XUiPanelBossRightV4P5:OnDestroy()
    self:_StopRecordTimer()
end

function XUiPanelBossRightV4P5:Select(i)
    self._SelectedFeatureIndex = i

    if not i or i == 0 then
        self.SelectedFeature = nil
        self.SelectedBuffGroup = nil
        self.SelectedBuffGroupId = nil
    else
        local challengeData = self.Parent._ChallengeData
        local featureGroupId = challengeData:GetFeatureGroupId()
        self.SelectedBuffGroupId =
            XMVCA.XFubenBossSingle
                :GetBossSingleChallengeFeatureGroupBuffGroupIdsById(featureGroupId)[i]

        self.SelectedFeature = challengeData:GetFeatureByIndex(i)
        self.SelectedBuffGroup = XMVCA.XFubenBossSingle
            :GetBossSingleChallengeBuffGroupConfigByBuffGroupId(self.SelectedBuffGroupId)
    end

    self:_RefreshViewSelectState()

    self._BigBuffGrid:PlayExtendAnimation()
end

function XUiPanelBossRightV4P5:_RefreshViewSelectState()
    local sel = self._SelectedFeatureIndex
    local challengeData = self.Parent._ChallengeData

    if not sel or sel == 0 then
        self._BigBuffGrid:Close()
        self.PanelSmallTitle.gameObject:SetActiveEx(true)
        self.PanelBigUi.gameObject:SetActiveEx(false)

        self.Parent:ChangeCamera(false, nil, true)
        self.Parent._IsSelecting = false

        for _, grid in pairs(self._SmallBuffGrids) do
            grid:Open()
        end
    else
        self._BigBuffGrid.Transform:SetSiblingIndex(sel - 1)
        self._BigBuffGrid:SetData({ Feature = self.SelectedFeature, BuffGroup = self.SelectedBuffGroup })
        self._BigBuffGrid:Open()

        self.Parent:ChangeBuffGrid(sel)
        self.Parent._IsSelecting = true

        self.PanelSmallTitle.gameObject:SetActiveEx(false)
        self.PanelBigUi.gameObject:SetActiveEx(true)
        self.UiTxtAllScore.text = self.Parent.TxtValue.text

        for i, grid in pairs(self._SmallBuffGrids) do
            if i == sel then
                grid:Close()
            else
                grid:Open()
                self._SelectedFeature = grid.Feature
            end
        end

        local stageId = self._SelectedFeature:GetStageId()
        local stageConf = self._Control:GetBossStageConfig(stageId)
        self.UiTxtName.text = stageConf.BossName
    end

    self:_RefreshRecordTime(true)

    for i = challengeData:GetFeatureCount() + 1, #self._SmallBuffGrids do
        self._SmallBuffGrids[i]:Close()
    end
end

function XUiPanelBossRightV4P5:RefreshWholeView()
    local challengeData = self.Parent._ChallengeData
    local featureGroupId = challengeData:GetFeatureGroupId()
    local featureCount = challengeData:GetFeatureCount()

    local params = {}

    for i = 1, featureCount do
        params[i] = {
            Feature = challengeData:GetFeatureByIndex(i),
            GroupId = featureGroupId,
            Index = i
        }
    end

    XTool.SetDataForGenericGrid(
        self._SmallBuffGrids,
        params,
        self.GirdBuffSmall.gameObject,
        self.ListBuff.transform,
        self,
        XUiGridFubenBossSingleModeBuffSmall)

    self:_RefreshViewSelectState()
end


function XUiPanelBossRightV4P5:_RefreshRecordTime(isFirst)
    local bossSingle = self._Control:GetBossSingleData()
    local recordTime = bossSingle:GetBossSingleChallengeDeleteRecordTime()

    if XTool.IsNumberValid(recordTime) and isFirst then
        local endTime = recordTime + self._Control:GetChallengeRecordCD()
        local nowTime = XTime.GetServerNowTimestamp()
        local isShow = endTime > nowTime

        self.PanelTime.gameObject:SetActiveEx(isShow)
        if isShow then
            self.TxtTimeDesc.text = XUiHelper.GetText("BossSingleChallengeRecordCD")
            self._RecordEndTime = endTime - nowTime
            self:_RefreshTimerInner()
            if self._RecordEndTime >= 0 then
                self:_StartRecordTimer()
            end
        end
    else
        self.PanelTime.gameObject:SetActiveEx(false)
    end
end


function XUiPanelBossRightV4P5:_RefreshTimerInner()
    self.TxtTime.text = XUiHelper.GetTime(
        self._RecordEndTime,
        XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)

    self._RecordEndTime = self._RecordEndTime - 1
    if not XTool.IsNumberValid(self._RecordEndTime) or self._RecordEndTime <= 0 then
        self.PanelTime.gameObject:SetActiveEx(false)
        self._RecordEndTime = nil
        self:_StopRecordTimer()
    end
end

function XUiPanelBossRightV4P5:_StartRecordTimer()
    self:_StopRecordTimer()

    if XTool.IsNumberValid(self._RecordEndTime) then
        self._RecordTimer = XScheduleManager.ScheduleForever(Handler(self, self._RefreshTimerInner), XScheduleManager.SECOND)
    end
end

function XUiPanelBossRightV4P5:_StopRecordTimer()
    if self._RecordTimer then
        XScheduleManager.UnSchedule(self._RecordTimer)
        self._RecordTimer = nil
    end
end

function XUiPanelBossRightV4P5:_OnBtnAttributeDetailClick()
    XLuaUiManager.Open(
        "UiCharacterAttributeDetail",
        nil,
        XEnumConst.UiCharacterAttributeDetail.BtnTab.Damage)
end

function XUiPanelBossRightV4P5:_OnBtnSelectModuleClick()
    XLuaUiManager.Open(
        "UiFubenBossSinglePopupModeChoose",
        self.SelectedBuffGroupId,
        self.SelectedBuffGroup,
        self.SelectedFeature,
        handler(self, self.StartGame))
end

-- 传入 XBossSingleDefine @ class BossSingleChallengeBuffGroup
function XUiPanelBossRightV4P5:StartGame(bossSingleChallengeBuffGroup)
    local stageId = self.SelectedFeature:GetStageId()

    local featureId = self.SelectedFeature:GetFeatureId()
    local features = {}

    for buff, featureIndex in pairs(bossSingleChallengeBuffGroup.BuffChoices) do
        table.insert(features, self.SelectedBuffGroup[buff].Buff[featureIndex])
    end

    self._Control:SetSelectedSelectableFeatureIds({ [featureId] = features })

    self._Control:SetEnterBossInfo(
        self.Parent:GetBossId(),
        XEnumConst.BossSingle.LevelType.Challenge,
        featureId,
        bossSingleChallengeBuffGroup)

    self._Control:OnEnterChallengeFight()

    XLuaUiManager.Open(
        "UiBattleRoleRoom",
        stageId,
        nil,
        require(
            "XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiFubenBossSingleModeBattleRoleRoom"))

end

function XUiPanelBossRightV4P5:StartGameWithEmptyBuffSelection()
    self:StartGame({ BuffGroupId = self.SelectedBuffGroupId, BuffChoices = {} })
end

function XUiPanelBossRightV4P5:_OnBtnStartClick()
    if XUiFubenBossSinglePopupModeTips.IsNoMoreTipsToday() then
        self:StartGameWithEmptyBuffSelection()
    else
        XLuaUiManager.Open("UiFubenBossSinglePopupModeTips", self)
    end
end

return XUiPanelBossRightV4P5
