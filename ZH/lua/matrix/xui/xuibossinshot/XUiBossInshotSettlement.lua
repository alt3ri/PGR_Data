---@class XUiBossInshotSettlement:XLuaUi
---@field private _Control XBossInshotControl
local XUiBossInshotSettlement = XLuaUiManager.Register(XLuaUi, "UiBossInshotSettlement")

function XUiBossInshotSettlement:OnAwake()
    self.GridScore.gameObject:SetActiveEx(false)
    self.TxtScoreNum.text = "0"
    self.BtnExit.gameObject:SetActiveEx(true)
    self.BtnAgain.gameObject:SetActiveEx(true)
    self:RegisterUiEvents()

    if CS.XRLManager.RLScene then
        CS.XRLManager.RLScene:SetUiEffectRootActive(false)
    end
    
    -- self:CheckMaskActive()

    -- local uiObj = self.UiSceneInfo.Transform:GetComponent("UiObject")
    -- if not uiObj then
    --     return
    -- end
    -- local screenShotEffect = uiObj:GetObject("CTVergil03pingfenwin")
    -- if screenShotEffect then
    --     screenShotEffect.gameObject:SetActiveEx(false)
    -- end
end

function XUiBossInshotSettlement:OnStart(settleData, isCheckActivityEnd)
    self.PanelPop.gameObject:SetActiveEx(true)
    self.StageId = settleData.StageId
    self.SettleData = settleData
    self.IsCheckActivityEnd = isCheckActivityEnd == true

    -- 提前缓存IntToIntRecord数据，弹结算界面未退出战斗场景，仍在跑行为树逻辑，IntToIntRecord会产生变化
    self.FightIntToIntRecord = {}
    local result = XMVCA.XFuben:GetCurFightResult()
    local e = result.IntToIntRecord:GetEnumerator()
    while e:MoveNext() do
        self.FightIntToIntRecord[e.Current.Key] = e.Current.Value
    end
    e:Dispose()
end

function XUiBossInshotSettlement:OnEnable()
    self:Refresh()
end

function XUiBossInshotSettlement:OnDestroy()
    XMVCA:GetAgency(ModuleId.XBossInshot):ExitFight()
end

-- 检查黑边是否需要显示
-- function XUiBossInshotSettlement:CheckMaskActive()
--     local currentWidth = CS.UnityEngine.Screen.width
--     local currentHeight = CS.UnityEngine.Screen.height
--     local scale = 1920 / 1010
--     self.Mask.gameObject:SetActiveEx(currentWidth / currentHeight > scale)
-- end

-- 刷新场景特效
function XUiBossInshotSettlement:RefreshMarkEffectActive()
    local uiObj = self.UiSceneInfo.Transform:GetComponent("UiObject")
    if not uiObj then
        return
    end
    
    local screenShotEffect = uiObj:GetObject("FxUiDMCPingfenJieping")
    if screenShotEffect then
        screenShotEffect.gameObject:SetActiveEx(true)
    end

    -- 带截屏脚本的节点显示需要一帧，截屏也需要一帧，故延迟2帧等截屏完再开启其他节点
    local loop = 2
    XScheduleManager.Schedule(function()
        loop = loop - 1
        if loop > 0 or XTool.UObjIsNil(self.GameObject) then
            return
        end

        --因为播完之后会直接退出, 这里先提前结束特殊特效, 避免影响光照
        CS.XRenderFeatureManager.ExitFight()
        
        local team = self._Control:GetTeam()
        local id = team:GetCaptainPosEntityId()
        local effectName = self._Control:GetMarkEffectName(id)
        local markEffectObj = uiObj:GetObject(effectName)
        if markEffectObj then
            markEffectObj.gameObject:SetActiveEx(true)
        end
        
        local timelineObj = uiObj:GetObject("CTVergil03pingfenwin")
        if timelineObj then
            timelineObj.gameObject:SetActiveEx(true)
        end

        self.LevelEffectSchedule = XScheduleManager.ScheduleOnce(function()
            XScheduleManager.UnSchedule(self.LevelEffectSchedule)
            self.LevelEffectSchedule = nil

            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            
            local levelEffectName
            if self._Control:IsFestivalActivityStage(self.StageId) then
                levelEffectName = "FxUiDMCPingfenS"
            elseif self.Difficulty then
                levelEffectName = self._Control:GetScoreLevelEffectName(self.Difficulty, self.Score)
            else
                levelEffectName = self.ScoreLevelConf.EffectName
            end
            
            local levelEffectObjet = uiObj:GetObject(levelEffectName)
            if levelEffectObjet then
                levelEffectObjet.gameObject:SetActiveEx(true)
            end
        end, 6200)
    end, 0, loop)
end

function XUiBossInshotSettlement:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnAgain, self.OnBtnAgainClick)
    self:RegisterClickEvent(self.BtnExit, self.OnBtnExitClick)
    self:RegisterClickEvent(self.BtnReplay, self.OnBtnReplayClick)
    self:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClick)
    self:RegisterClickEvent(self.BtnPopBg, self.OnBtnPopBgClick)
end

function XUiBossInshotSettlement:OnBtnAgainClick()
    -- 玩法结束
    local isOpen = self._Control:IsActivityOpen()
    if not isOpen then
        self._Control:HandleActivityEnd()
        return
    end
    
    local stageId = self.StageId
    local team = self._Control:GetTeam()
    self._Control:SetAgainFight(true)

    -- 重新挑战，无须还原UI栈
    CsXUiManager.Instance:SetRevertAllLock(true)
    
    self:Close()
    local fubenAgency = XMVCA:GetAgency(ModuleId.XFuben)
    fubenAgency:EnterFightByStageId(stageId, team:GetId())
end

function XUiBossInshotSettlement:OnBtnExitClick()
    if self.IsCheckActivityEnd then
        -- 玩法结束
        local isOpen = self._Control:IsActivityOpen()
        if not isOpen then
            self._Control:HandleActivityEnd()
            return
        end
    end
    
    self._Control:SetAgainFight(false)
    self:Close()
end

function XUiBossInshotSettlement:OnBtnReplayClick()
    if not CS.XFight.Instance then
        XUiManager.TipText("BossInshotSettlementTowerCheatCannotSaveReplay")
        return
    end

    if not self.PlaybackData then
        local scoreLevelIcon

        if self.Difficulty then
            scoreLevelIcon = self._Control:GetScoreLevelIcon(self.Difficulty, self.Score)
        else
            scoreLevelIcon = self.ScoreLevelConf.LevelIcon
        end

        local towerId = nil

        if self.TowerLevelConf then
            towerId = self.TowerLevelConf.Id
        end

        self.PlaybackData = self._Control:GenLastPlaybackData(
            self.BossId,
            self.Score,
            scoreLevelIcon,
            self.Difficulty,
            towerId)
    end
    XLuaUiManager.Open("UiBossInshotPlayback", self.BossId, self.PlaybackData)
end

function XUiBossInshotSettlement:OnBtnPopBgClick()
    self:PlayScoreAnimation()
    self:PlayAnimation("SecondScreenEnable")
end

function XUiBossInshotSettlement:OnBtnHelpClick()
    XLuaUiManager.Open("UiBossInshotTip", self.FightIntToIntRecord)
end

-- 特殊关卡显示内容
function XUiBossInshotSettlement:RefreshByFestivalActivity()
    self.BtnReplay.gameObject:SetActiveEx(false)
    self.BtnHelp.gameObject:SetActiveEx(false)
    self.PanelNew.gameObject:SetActiveEx(false)
    self.BtnAgain.gameObject:SetActiveEx(false)
    
    self.TxtNext.text = XUiHelper.GetText("MissionComplete")
    local stageName = XMVCA.XFuben:GetStageName(self.StageId)
    self.TxtName.text = stageName
    self.TxtName2.text = stageName
    self.BtnExit:SetName(XUiHelper.GetText("Continue"))
    self.TxtScore:SetSprite(CS.XGame.ClientConfig:GetString("UiBossInshotSettlementFestivalActivityTitle"))

    -- 得分列表固定显示文本内容
    self.PanelPop.gameObject:SetActiveEx(true)
    self.ScoreInfos = {{Desc = XUiHelper.GetText("StageClear")}}
    self.DynamicTable:SetDataSource(self.ScoreInfos)
    self.DynamicTable:ReloadDataSync()

    -- self:RefreshMarkEffectActive()
end

function XUiBossInshotSettlement:Refresh()
    if self._Control:IsFestivalActivityStage(self.StageId) then
        self:RefreshByFestivalActivity()
        return
    end
    
    -- 回放按钮
    local isShowPlayback = self._Control:GetIsShowPlayback(self.StageId)
    self.BtnReplay.gameObject:SetActiveEx(isShowPlayback)
    
    -- 总分
    local isNewRecord = self.SettleData.BossInshotSettleResult.IsNewRecord
    local inshotStageId = self._Control:GetInshotStageIdByStageId(self.StageId)
    self.Score = self.SettleData.BossInshotSettleResult.Score

    if inshotStageId then   -- 如果是普通关卡
        self.BossId = self._Control:GetStageBossId(inshotStageId)
        self.Difficulty = self._Control:GetStageDifficulty(inshotStageId)
        self.ScoreLevelIcon = self._Control:GetScoreLevelBigIcon(self.Difficulty, self.Score)

        self.TxtNext.text = self._Control:GetNextScoreLevelTips(
            self.Difficulty, self.Score)

        self.RImgWin.gameObject:SetActiveEx(true)
        self.RImgLose.gameObject:SetActiveEx(false)
        self.BtnAgain.gameObject:SetActiveEx(true)
    else                    -- 如果是爬塔关卡
        self.BossId = self._Control:GetTowerBossIdByStageId(self.StageId)
        local prevLevelId, prevUnlockedLevelId = XMVCA.XBossInshot:GetPrevTowerLevelIdAndPrevUnlockedLevel()
        assert(prevLevelId and prevUnlockedLevelId)
        self.TowerLevelConf = self._Control:GetConfigBossInshotTowerAllLevels()[prevLevelId]
        assert(self.TowerLevelConf)
        self.ScoreLevelConf = self._Control:GetTowerScoreLevelConf(self.TowerLevelConf.Id, self.Score)
        self.ScoreLevelIcon = self.ScoreLevelConf.BalanceIcon

        local towerLevelPass = self._Control:HasPassedTowerLevel(self.TowerLevelConf.Id)
        if self.TowerLevelConf.PassScore and self.Score < self.TowerLevelConf.PassScore then
            towerLevelPass = false
        end

        self.RImgWin.gameObject:SetActiveEx(towerLevelPass)
        self.RImgLose.gameObject:SetActiveEx(not towerLevelPass)

        local alreadyAllCleared = self._Control:IsTowerAllClear()
        self.BtnAgain.gameObject:SetActiveEx(not towerLevelPass or alreadyAllCleared)

        local nextLevelPass = self._Control:HasPassedTowerLevel(self.TowerLevelConf.Id + 1)

        local tip
        local getText = CS.XTextManager.GetText

        self.BtnAgain.gameObject:SetActiveEx(false)

        if alreadyAllCleared then
            tip = getText("BossInshotSettlementTowerTipAllCleared")
            self.BtnAgain.gameObject:SetActiveEx(true)
        elseif towerLevelPass and nextLevelPass then
            tip = getText("BossInshotSettlementTowerTipRetryWin")
        elseif towerLevelPass then
            tip = getText("BossInshotSettlementTowerTipNextLevelUnlocked")
        elseif self.TowerLevelConf.FailReBackToId == -1 or self.TowerLevelConf.FailReBackToId == self.TowerLevelConf.Id then
            tip = getText("BossInshotSettlementTowerTipNextLevelNotUnlocked", self.TowerLevelConf.PassScore)
            self.BtnAgain.gameObject:SetActiveEx(true)
        else
            if self._Control:GetBossTowerCurrentLevel() < prevUnlockedLevelId then
                tip = getText("BossInshotSettlementTowerTipFall", self.TowerLevelConf.PassScore)
            else
                tip = getText("BossInshotSettlementTowerTipFallProtected", self.TowerLevelConf.PassScore)
            end
        end

        self.TxtNext.text = tip
    end

    self.RImgScore:SetRawImage(self.ScoreLevelIcon)
    self.PanelNew.gameObject:SetActiveEx(isNewRecord)
    -- 关卡名
    local stageName = XMVCA.XFuben:GetStageName(self.StageId)
    self.TxtName.text = stageName
    self.TxtName2.text = stageName

    -- 得分列表
    self.PanelPop.gameObject:SetActiveEx(true)
    self.ScoreInfos = self:GetScoreInfos()
    self:RefreshScoreTipsList()

    -- self:RefreshMarkEffectActive()
end

-- 获取得分列表
function XUiBossInshotSettlement:GetScoreInfos()
    local result = XMVCA.XFuben:GetCurFightResult()
    if not result or not result.IsWin or not result.IntToIntRecord then
        return {}
    end

    local scoreInfos = {}
    local scoreCfgs = self._Control:GetConfigBossInshotScore()
    local e = result.IntToIntRecord:GetEnumerator()
    while e:MoveNext() do
        local scoreCfg = scoreCfgs[e.Current.Key]
        if scoreCfg then
            local isShow = e.Current.Value ~= 0 and (scoreCfg.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.Add or scoreCfg.Type == XEnumConst.BOSSINSHOT.SCORE_TYPE.MULTIPLY)
            if isShow then
                local scoreInfo = { Id = e.Current.Key, Value = e.Current.Value, Score = scoreCfg.Score, Type = scoreCfg.Type, Desc = scoreCfg.Desc, Order = scoreCfg.Order }
                table.insert(scoreInfos, scoreInfo)
            end
        end
    end
    e:Dispose()

    -- 按照Order排序
    table.sort(scoreInfos, function(a, b)
        return a.Order < b.Order
    end)

    return scoreInfos
end

function XUiBossInshotSettlement:RefreshScoreTipsList()
    local XUiGridBossInshotScore = require("XUi/XUiBossInshot/XUiGridBossInshotScore")

    if not self.ScoreTipGridContainerGameObjects
        or not self.ScoreTipGridContainerGameObjectsTemplate then

        self.ScoreTipGridContainerGameObjects = {}

        XTool.InitUiObjectByInstance(
            self.ScoreList,
            self.ScoreTipGridContainerGameObjects)

        self.ScoreTipGridContainerGameObjectsTemplate =
            self.ScoreTipGridContainerGameObjects.GridScorePanelTemplate

        self.ScoreTipGridContainerGameObjects.GridScorePanelTemplate = nil
    end

    if not self.ScoreTipGridContainers then
        self.ScoreTipGridContainers = {}
    end

    for _, c in pairs(self.ScoreTipGridContainers) do
        c:Close()
    end

    for _, c in pairs(self.ScoreTipGridContainerGameObjects) do
        c.gameObject:SetActiveEx(false)
    end

    XLuaUiManager.SetMask(true)

    local interval = CS
        .XGame
        .ClientConfig
        :GetInt("BossInshotSettlementScoreListItemShowInterval")

    local delay = CS
        .XGame
        .ClientConfig
        :GetInt("BossInshotSettlementScoreListItemShowDelay")

    self.ScoreListShowIntervalCounter = 1

    local function unschedule()
        XScheduleManager.UnSchedule(self.ScoreListShowIntervalSchedule)
        self.ScoreListShowIntervalCounter = nil
        self.ScoreListShowIntervalSchedule = nil
        XLuaUiManager.SetMask(false)
    end

    self.ScoreListShowIntervalSchedule = XScheduleManager.ScheduleForever(
        function()
            local i = self.ScoreListShowIntervalCounter
            local scoreInfo = self.ScoreInfos[i]
            local containerGameObject = self.ScoreTipGridContainerGameObjects["GridScore" .. i]

            if not containerGameObject or not scoreInfo then
                unschedule()
                return
            end

            containerGameObject.gameObject:SetActiveEx(true)

            local container = self.ScoreTipGridContainers[i]
            if not container then
                local panel = XUiHelper.Instantiate(
                    self.ScoreTipGridContainerGameObjectsTemplate,
                    containerGameObject)

                container = XUiGridBossInshotScore.New(panel, self)
            end

            container:Open()
            container:Refresh(scoreInfo)
            self.ScoreListBoundSizeFitter:SetLayoutVertical()

            XUiHelper.ScrollTo(
                self.ScoreListScrollRect,
                containerGameObject.transform)

            self.ScoreListShowIntervalCounter = self.ScoreListShowIntervalCounter + 1
            container:PlayAnimation("Enable")
        end,
        interval,
        delay)
end

function XUiBossInshotSettlement:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local info = self.ScoreInfos[index]
        grid:Refresh(info)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local grids = self.DynamicTable:GetGrids()
        for _, g in pairs(grids) do
            g.GameObject:SetActive(false)
        end
        self.GridIndex = 1
        self.GridsTimer = XScheduleManager.Schedule(function()
            local item = grids[self.GridIndex]
            if item then
                item.GameObject:SetActive(true)
            end
            self.GridIndex = self.GridIndex + 1
        end, 100, #grids)
    end
end

-- 播放滚动效果
function XUiBossInshotSettlement:PlayScoreAnimation()
    local time = CS.XGame.ClientConfig:GetInt("BossInshotSettlementScoreAnimationDuration") / 1000.0
    if self._Control:IsFestivalActivityStage(self.StageId) then
        -- 播放通关时间滚动效果
        local result = XMVCA.XFuben:GetCurFightResult()
        local costTime = math.abs(result.LeftTime)
        self:Tween(time, function(f)
            self.TxtScoreNum.text = XUiHelper.GetTime(costTime * f, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
        end, function()
            self.TxtScoreNum.text = XUiHelper.GetTime(costTime, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
        end)
        return
    end
    
    -- 播放分数滚动效果
    self:Tween(time, function(f)
        self.TxtScoreNum.text = tostring(XMath.ToMinInt(self.Score * f))
    end, function()
        self.TxtScoreNum.text = tostring(self.Score)
    end)
end

return XUiBossInshotSettlement
