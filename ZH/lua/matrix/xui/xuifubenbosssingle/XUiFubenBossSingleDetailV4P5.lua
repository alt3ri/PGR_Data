local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
local XUiModelUtility = require("XUi/XUiCharacter/XUiModelUtility")
local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiFubenBossSingleDetailPanelReset = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleDetailPanelReset")

local XUiGridFubenBossSingleDetailBuffOrSkillV4P5 = require(
    "XUi/XUiFubenBossSingle/XUiGridFubenBossSingleDetailBuffOrSkillV4P5")

local XUiFubenBossSingleDetailDifficultySelectCardV4P5 = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleDetailDifficultySelectCardV4P5")

local XUiFubenBossSingleDetailAutoFight = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleDetailAutoFight")


---@class XUiFubenBossSingleDetailV4P5 : XLuaUi
---@field _Control XFubenBossSingleControl

local XUiFubenBossSingleDetailV4P5 =
    XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleDetailV4P5")

function XUiFubenBossSingleDetailV4P5:OnAwake()
    self._TimerResetCooldown = false

    XUiPanelAsset.New(
        self,
        self.PanelAsset,
        XDataCenter.ItemManager.ItemId.FreeGem,
        XDataCenter.ItemManager.ItemId.ActionPoint,
        XDataCenter.ItemManager.ItemId.Coin)

    self._RoleModelPanelUi = XUiPanelRoleModel.New(
        self.UiModelGo.transform:FindTransform("PanelRoleModel"),
        self.Name,
        nil,
        true)

    self._ResetPanelUi = XUiFubenBossSingleDetailPanelReset.New(
        self.PanelReset,
        self)

    self._AutoFightPanelUi = XUiFubenBossSingleDetailAutoFight.New(
        self.PanelAutoFight,
        self)

    self._AutoFightPanelUi:SetBtnAutoFightAdditionalOperation(function()
        self._AutoFightPanelUi:Close()
        self:_RefreshView(true)
        self:ScheduleResetCooldown()
    end)

    self._AutoFightPanelUi:SetAutoFightPreCheck(function()
        return self:_AutoFightPreCheck()
    end)
end

function XUiFubenBossSingleDetailV4P5:OnStart(bossId)
    self:_RegisterButtonClicks()

    self._BossId = bossId
    self._SectionConf = self._Control:GetBossSectionConfigByBossId(bossId)
    self._SectionInfo = self._Control:GetBossSectionInfoByBossId(bossId)
    self:_SelectLevel(self:_GetCurBossIndex(bossId), true)
end

function XUiFubenBossSingleDetailV4P5:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self._RefreshViewNoDifficultySelectCardAnimation, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self._RefreshViewNoDifficultySelectCardAnimation, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_AUTO_FIGHT, self._RefreshViewNoDifficultySelectCardAnimation, self)

    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self.ScheduleResetCooldown, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.ScheduleResetCooldown, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_AUTO_FIGHT, self.ScheduleResetCooldown, self)

    self:_RefreshView()
    self:ScheduleResetCooldown()
end

function XUiFubenBossSingleDetailV4P5:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self._RefreshViewNoDifficultySelectCardAnimation, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self._RefreshViewNoDifficultySelectCardAnimation, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_AUTO_FIGHT, self._RefreshViewNoDifficultySelectCardAnimation, self)

    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self.ScheduleResetCooldown, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.ScheduleResetCooldown, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_AUTO_FIGHT, self.ScheduleResetCooldown, self)

    XScheduleManager.UnSchedule(self._TimerResetCooldown)
    self._TimerResetCooldown = false
end

function XUiFubenBossSingleDetailV4P5:_RegisterButtonClicks()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "BossSingle")

    XUiHelper.RegisterClickEvent(self, self.BtnAttributeDetail, function()
        XLuaUiManager.Open(
            "UiCharacterAttributeDetail",
            nil,
            XEnumConst.UiCharacterAttributeDetail.BtnTab.Damage)
    end)

    XUiHelper.RegisterClickEvent(self, self.BtnBossDetail, function()
        XLuaUiManager.Open(
            "UiFubenBossSingleHide",
            self._SectionConf,
            self._SelectedBossStageConf,
            true)
    end)

    XUiHelper.RegisterClickEvent(self, self.BtnBuffInfo, function()
        XLuaUiManager.Open(
            "UiFubenBossSingleHide",
            self._SectionConf,
            self._SelectedBossStageConf,
            false)
    end)

    XUiHelper.RegisterClickEvent(self, self.BtnStart, self.StartManuallyFight)
    XUiHelper.RegisterClickEvent(self, self.BtnAuto, self._OnBtnAutoClick)
end

function XUiFubenBossSingleDetailV4P5:_SelectLevel(index, skipRefreshView)
    self._SelectedBossStageIndex = index
    self._SelectedBossStageConf = self._SectionInfo[index]
    self:_RefreshModel(self._SelectedBossStageConf)
    if not skipRefreshView then self:_RefreshView() end
end

function XUiFubenBossSingleDetailV4P5:_RefreshViewNoDifficultySelectCardAnimation()
    self:_RefreshView(true)
end

function XUiFubenBossSingleDetailV4P5:_RefreshView(noDifficultySelectCardAnimation)
    local bossConf = self._SelectedBossStageConf
    local stageId = self._SelectedBossStageConf.StageId
    local stageConf = XMVCA.XFuben:GetStageCfg(stageId)

    self.TxtAllScore.text = XUiHelper.GetText(
        "BossSingleDetailAllScore",
        self:_GetBossCurScore(self._BossId))

    self.TxtBossName.text = bossConf.BossName

    self.TxtTimeLimit.text = XUiHelper.GetText(
        "BossSingleTimeLimit",
        math.floor(stageConf.PassTimeLimit / 60))


    self:_RefreshBuffDetails(bossConf)
    self:_ResetDifficultySelectCards(noDifficultySelectCardAnimation)
    self:_RefreshButtons()
    self:ScheduleResetCooldown()
end

function XUiFubenBossSingleDetailV4P5:_RefreshModel(bossConf)
    XUiModelUtility.UpdateMonsterBossModel(
        self._RoleModelPanelUi,
        bossConf.ModelId,
        XModelManager.MODEL_UINAME.XUiBossSingleV4P5)
end


function XUiFubenBossSingleDetailV4P5:_RefreshBuffDetails(bossConf)
    if self._BuffOrSkillGrids then
        for _, v in pairs(self._BuffOrSkillGrids) do
            v:Close()
            CS.UnityEngine.GameObject.Destroy(v.GameObject)
        end
    end

    self.GridBuffDetail.gameObject:SetActiveEx(false)
    self._BuffOrSkillGrids = {}

    if bossConf.FeaturesId then
        for _, featureId in pairs(bossConf.FeaturesId) do
            local feature = XMVCA.XFuben:GetFeaturesById(featureId)

            local go = XUiHelper.Instantiate(
                self.GridBuffDetail.gameObject,
                self.PanelBuffContent)

            go:SetActiveEx(true)

            local ui = XUiGridFubenBossSingleDetailBuffOrSkillV4P5.New(
                go,
                self,
                feature.Name,
                feature.Icon,
                feature.TriangleBg)

            table.insert(self._BuffOrSkillGrids, ui)
        end
    end

    if bossConf.BuffDetailsId then
        for _, buffId in pairs(bossConf.BuffDetailsId) do
            local go = XUiHelper.Instantiate(
                self.GridBuffDetail.gameObject,
                self.PanelBuffContent)

            go:SetActiveEx(true)

            local buff = XFubenBabelTowerConfigs.GetBabelBuffConfigs(buffId)

            local ui = XUiGridFubenBossSingleDetailBuffOrSkillV4P5.New(
                go,
                self,
                buff.Name,
                buff.BuffBg,
                buff.BuffTriangleBg)

            table.insert(self._BuffOrSkillGrids, ui)
        end
    end

    self.BtnBuffInfo.gameObject:SetActiveEx(
        not XTool.IsTableEmpty(self._BuffOrSkillGrids))
end

function XUiFubenBossSingleDetailV4P5:_ResetDifficultySelectCards(noDifficultySelectCardAnimation)
    if self._DifficultySelectCard then
        for _, v in pairs(self._DifficultySelectCard) do
            v:Close()
            CS.UnityEngine.GameObject.Destroy(v.GameObject)
        end
    end

    local playSmallAnimation = not self._DifficultySelectCard
    self._DifficultySelectCard = {}
    self.BtnGridDifficultyBig.gameObject:SetActiveEx(false)
    self.BtnGridDifficultySmall.gameObject:SetActiveEx(false)

    for difficultyIndex, difficulty in pairs(self._SectionInfo) do
        local prefab
        local callback
        local isSmall = nil

        if difficultyIndex == self._SelectedBossStageIndex then
            prefab = self.BtnGridDifficultyBig.gameObject
            callback = function() end
        else
            prefab = self.BtnGridDifficultySmall.gameObject
            callback = function() self:_SelectLevel(difficultyIndex) end
            isSmall = true
        end

        local go = XUiHelper.Instantiate(prefab, self.PanelDifficultyContent)
        go:SetActiveEx(true)

        local ui = XUiFubenBossSingleDetailDifficultySelectCardV4P5.New(
            go,
            self,
            difficulty,
            self._SelectedBossStageConf,
            callback,
            isSmall and playSmallAnimation and not noDifficultySelectCardAnimation,
            not isSmall and not noDifficultySelectCardAnimation)

        table.insert(self._DifficultySelectCard, ui)
    end
end

function XUiFubenBossSingleDetailV4P5:RefreshToggleGroup(noDifficultyCardAnimation)
    self:_RefreshView(noDifficultyCardAnimation)
    self:ScheduleResetCooldown()
end

function XUiFubenBossSingleDetailV4P5:_RefreshBtnReset()
    local stageId = self._SelectedBossStageConf.StageId

    if self._Control:IsResetCoolDown() then
        self.BtnReset:SetButtonState(CS.UiButtonState.Disable)
        local time = self._Control:GetResetCoolDownRemainTime()
        if time < 0 then time = 0 end
        self.TxtCoolDown.text = XUiHelper.GetTime(
            time,
            XUiHelper.TimeFormatType.HOUR_MINUTE_SECOND)
        self.TxtCoolDown.gameObject:SetActiveEx(true)
        self.BtnReset.CallBack = function()
            XUiManager.TipText("BossSingleResetCooldown")
        end
    elseif not self._Control:IsResetBtnVisible(stageId) then
        self.TxtCoolDown.gameObject:SetActiveEx(false)
        self.BtnReset:SetButtonState(CS.UiButtonState.Disable)
        self.BtnReset.CallBack = function()
            XUiManager.TipText("FuBenBossSingleResetNotUsable")
        end
    elseif self._Control:IsResetBtnEnable(stageId) then
        self.TxtCoolDown.gameObject:SetActiveEx(false)
        self.BtnReset:SetButtonState(CS.UiButtonState.Normal)
        self.BtnReset.CallBack = function()
            self._ResetPanelUi:Open()
            self._ResetPanelUi:Update(self._SelectedBossStageConf)
        end
    else
        self.TxtCoolDown.gameObject:SetActiveEx(false)
        self.BtnReset:SetButtonState(CS.UiButtonState.Disable)
        self.BtnReset.CallBack = function()
            XUiManager.TipText("FuBenBossSingleResetNotUsable")
        end
    end
end

function XUiFubenBossSingleDetailV4P5:_RefreshBtnStartAndAuto()
    local maxCount = self._Control:GetAutoFightCount()

    if self._SelectedBossStageConf.AutoFight
        and maxCount > 0
        and self._Control:CheckAutoFight(self._SelectedBossStageConf.StageId)
    then
        local curCount =
            maxCount
            - self:GetBossSingleData():GetBossSingleAutoFightCount()

        self.BtnAuto:SetName(
            XUiHelper.GetText("BossSingleAutoFightCount2", curCount, maxCount))

        self.BtnAuto.gameObject:SetActiveEx(true)
    else
        self.BtnAuto.gameObject:SetActiveEx(false)
    end
end

function XUiFubenBossSingleDetailV4P5:_RefreshButtons()
    self:_RefreshBtnReset()
    self:_RefreshBtnStartAndAuto()
end

function XUiFubenBossSingleDetailV4P5:ScheduleResetCooldown()
    self:_RefreshButtons()
    if not self._Control:IsResetCoolDown() then
        return
    end

    if self._TimerResetCooldown then
        XScheduleManager.UnSchedule(self._TimerResetCooldown)
    end

    self._TimerResetCooldown = XScheduleManager.ScheduleForever(function()
        self:_RefreshButtons()
        if not self._Control:IsResetCoolDown() then
            XScheduleManager.UnSchedule(self._TimerResetCooldown)
        end
    end, XScheduleManager.SECOND)
end


function XUiFubenBossSingleDetailV4P5:_OnBtnAutoClick()
    self._AutoFightPanelUi:Open()

    self._AutoFightPanelUi:Refresh(
        self._Control:CheckAutoFight(self._SelectedBossStageConf.StageId),
        self:GetBossSingleData():GetBossSingleAutoFightCount(),
        self._SelectedBossStageConf)
end

function XUiFubenBossSingleDetailV4P5:StartManuallyFight()
    local stageId = self._SelectedBossStageConf.StageId

    local stageCfg = XMVCA.XFuben:GetStageCfg(stageId)

    if not XMVCA.XFuben:CheckPreFight(stageCfg) then
        return
    end

    self._Control:SetEnterBossInfo(
        self._BossId,
        self._SelectedBossStageConf.DifficultyType)

    self._Control:OnEnterNormalFight()

    XLuaUiManager.Open(
        "UiBattleRoleRoom",
        stageId,
        self._Control:GetTeamByBossId(self._BossId),
        require("XUi/XUiFubenBossSingle/XUiBossSingleBattleRoleRoom"),
        nil,
        nil,
        { EnableTeamDifferentCheck = true })
end

function XUiFubenBossSingleDetailV4P5:GetBossSingleData()
    return self._Control:GetBossSingleData()
end

function XUiFubenBossSingleDetailV4P5:_GetBossCurScore(bossId)
    return self._Control:GetBossCurScore(bossId)
end

function XUiFubenBossSingleDetailV4P5:_GetCurBossIndex(bossId)
    return self._Control:GetCurBossIndex(bossId)
end

function XUiFubenBossSingleDetailV4P5:_GetStageCurrentScore(stageId)
    return self._Control:GetStageCurrentScore(stageId)
end

function XUiFubenBossSingleDetailV4P5:_ShowHistoryTeam()
    return true
end

function XUiFubenBossSingleDetailV4P5:_GetHistoryTeam(stageId)
    local characterIds

    local currentRoundRecord = self._Control:GetRecordCurrentByStageId(stageId)

    if currentRoundRecord then
        characterIds = currentRoundRecord.Characters
    end

    if XTool.IsTableEmpty(characterIds) then
        characterIds = self._Control:GetCharacterListInRecord(stageId)
    end

    return characterIds
end

function XUiFubenBossSingleDetailV4P5:_AutoFightPreCheck()
    local bossStageConf = self._SelectedBossStageConf
    if not bossStageConf.AutoFight then
        local text = XUiHelper.GetText("BossSingleAutoFightDesc2", bossStageConf.DifficultyDesc)
        XUiManager.TipMsg(text)
        return false
    end

    local autoFightData = self._Control:CheckAutoFight(bossStageConf.StageId)

    if not autoFightData then
        XUiManager.TipText("BossSingleAutoFightDesc1")
        return false
    end

    local curScore = self._Control:GetStageCurrentScore(bossStageConf.StageId)

    local autoScore = math.floor(self._Control:GetAutoFightRebate() * autoFightData:GetScore() / 100)

    if curScore >= autoScore then
        XUiManager.TipText("BossSingleAutoFightDesc12")
        return false
    end

    local autoFightCount = self._Control:GetAutoFightCount()
    local maxCount = autoFightCount
    local curCount = autoFightCount - self:GetBossSingleData():GetBossSingleAutoFightCount()

    if maxCount > 0 and curCount <= 0 then
        XUiManager.TipText("BossSingleAutoFightCount3")
        return false
    end

    return true
end


return XUiFubenBossSingleDetailV4P5
