local XUiGridRaceFightCharacter = require("XUi/XUiRace/Grid/XUiGridRaceFightCharacter")
local XUiGridRaceFightMapCharacter = require("XUi/XUiRace/Grid/XUiGridRaceFightMapCharacter")

---@class XUiRaceFightMain : XUiRaceFightMainPartial
local XUiRaceFightMain = XLuaUiManager.Register(XLuaUi, "UiRaceFightMain")
local SceneIds = require("XModule/XScene/XScene/XLuaSceneDefine").SceneIds

local MatchStatus = {
    Wait = 0,
    CountDown = 1,
    Matching = 2,
    End = 3,
}

function XUiRaceFightMain:OnStart(roundId, ids, sceneType)
    self:_RegisterButtonClicks()
    -- 后续开启
    self.GridSkillTalk.gameObject:SetActive(false)
    self.BtnDirector.gameObject:SetActive(true)
    self.PanelCountdown.gameObject:SetActive(false)
    self.BtnRaceExit.gameObject:SetActive(false)
    self:ShowFinish(false)

    self._SkillUltraCache = {}
    self._SprintIndexList = {}
    self._FinishIndexList = {}
    self._RaceIds = ids
    self._SelectIndex = math.ceil(#self._RaceIds / 2)
    self._RoundId = roundId
    self._EnterCount = self._Control:GetEnterRaceCount()
    self._Control:SetEnterRaceCount(self._EnterCount + 1)
    local roundCfg = self._Control:GetEtcdRoundConfig(roundId)

    if not XLoginManager.IsLogin() then
        self:Close()
        return
    end

    if roundCfg then
        local guessList = roundCfg.Guess
        for i = 1, #guessList do
            local guessId = guessList[i]
            local guessCfg = self._Control:GetRaceGuessById(guessId)
            if guessCfg and guessCfg.SpecialType == 1 then
                local needCharacter = self._Control:IsGuessNeedCharacter(guessId)
                if needCharacter then
                    self._GuessId = guessCfg.Id
                    break
                end
            end
        end
        if self._GuessId then
            local mineOptionCId = self._Control:GetGuessProjectOption(self._RoundId, self._GuessId)
            if mineOptionCId then
                for key, value in pairs(self._RaceIds) do
                    if value == mineOptionCId then
                        self._SelectIndex = key
                        self._TagIndex = key
                        break
                    end
                end
            end
        end
    end

    self._ExtraChangeWaitTime = 2
    self._SceneType = sceneType
    self._WaitingTime = 0
    self._StartCountTime = 3
    self._CurrentTime = XTime.GetServerNowTimestamp()
    if sceneType == XEnumConst.Race.GameMode.LiveStream then
        if not XMVCA.XRace:IsRunninghMatch() then
            XMVCA.XRace:CloseLoading()
            XUiManager.DialogTip(nil, XUiHelper.GetText("RaceErrorDesc"), XUiManager.DialogType.OnlySure, nil, function()
                self:OnBtnRaceExitClick()
            end)
            return
        end

        -- 开始时间
        local delayTime = tonumber(self._Control:GetClientConfig("RaceStartTime")) or 0
        local activeTime = XMVCA.XRace:GetRaceStartTime()
        self._StartTime = activeTime + delayTime / 1000
        self._GapTime = self._CurrentTime - self._StartTime
        if self._GapTime < 0 then
            local leftTime = -self._GapTime
            self._StartCountTime = math.min(leftTime, self._StartCountTime)
            leftTime = math.max(leftTime - self._StartCountTime, 0)
            self._ExtraChangeWaitTime = math.min(leftTime, self._ExtraChangeWaitTime)
            leftTime = math.max(leftTime - self._StartCountTime, 0)
            self._WaitingTime = leftTime
        else
            self._StartCountTime = 0
        end
        -- XLog.Warning("[XUiRaceFightMain] OnStart: activeTime ", activeTime)
        -- XLog.Warning("[XUiRaceFightMain] OnStart: _CurrentTime ", self._CurrentTime)
        -- XLog.Warning("[XUiRaceFightMain] OnStart: _GapTime ", self._GapTime)
        -- XLog.Warning("[XUiRaceFightMain] OnStart: _WaitingTime ", self._WaitingTime)
        -- XLog.Warning("[XUiRaceFightMain] OnStart: delayTime ", delayTime)
        self._IsHide = self._WaitingTime > 0 or self._ExtraChangeWaitTime > 0 or self._StartCountTime > 0
    else
        self._WaitingTime = 0
        self._ExtraChangeWaitTime = 1
        -- self._GapTime = -20
        -- if self._GapTime < 0 then
        --     local leftTime = -self._GapTime
        --     self._StartCountTime = math.min(leftTime, self._StartCountTime)
        --     leftTime = math.max(leftTime - self._StartCountTime, 0)
        --     self._ExtraChangeWaitTime = math.min(leftTime, self._ExtraChangeWaitTime)
        --     leftTime = math.max(leftTime - self._StartCountTime, 0)
        --     self._WaitingTime = leftTime
        -- else
        --     self._StartCountTime = 0
        -- end
        self._GapTime = 0
    end

    self._CheckTimerUpdateCb = handler(self, self.CheckTimerUpdate)
    self._DefaultPos = self.PanelSkillDetail.transform.anchoredPosition
    self._UltraSkill = {}
    self._Heads = {}
    self._MapHeads = {}
    self._MapAreas = {}
    self._UltraSkillShowList = {}

    local XUiPanelRaceFightRankDetail = require("XUi/XUiRace/Panel/XUiPanelRaceFightRankDetail")
    self._PanelRaceDataUi = XUiPanelRaceFightRankDetail.New(self.PanelRaceData, self)
    self._PanelRaceDataUi:Open()
    self._PanelRaceDataUi:InitRace(#self._RaceIds)
    self._PanelRaceDataUi:UpdateRank(self._SelectIndex)

    self._Scene = XMVCA.XScene:GetScene(SceneIds.XRaceScene)
    self._UpdatePowerCallback = handler(self, self.UpdatePowerCallback)
    self._UpdateSkillCallback = handler(self, self.UpdateSkillCallback)
    self._UiCallback = handler(self, self.UiCallback)
    self._Control:InitRacePowerData(#self._RaceIds)
    self:InitRace()
    self:Record(1)
end

-- live初始化结束
function XUiRaceFightMain:OnGetLuaEvents()
    return { XEventId.EVENT_RACE_GAME_END_IN_SCENE, }
end

function XUiRaceFightMain:OnNotify(evt, ...)
    if evt == XEventId.EVENT_RACE_GAME_END_IN_SCENE then
        self._IsFinish = true
        self.BtnRaceExit.gameObject:SetActive(true)

        if self._ClientFinish then return end
        self:RemoveDelayTimer()
        self._DelayTimerId = XScheduleManager.ScheduleOnce(function()
            if self._NotTips or self._IsDestroyUi or self._OpenTips or self._ClientFinish then return end
            XUiManager.DialogTip(nil, XUiHelper.GetText("RaceEndDesc"), XUiManager.DialogType.OnlySure, nil, function()
                self:OnBtnRaceExitClick()
            end)
        end, tonumber(self._Control:GetClientConfig("RaceFinishWaitTime")) or 3000)
    end
end

-- live初始化结束
function XUiRaceFightMain:InitServerDataFinish()
    if self._GapTime < 0 then
        return
    end
    self._IsPlaying = true
    self:SetMatchStatus(MatchStatus.Matching)
    self._Scene:PlayMatch()
    self:AddCheckTimer()
    -- finish
    XMVCA.XRace:CloseLoading()
    if self.XAudioObjectPlayer then
        self.XAudioObjectPlayer:PlayByKeyName("BGMStart")
    end
end

function XUiRaceFightMain:SetPanelUiShow(isShow)
    if self.PanelUiShow.gameObject.activeSelf == isShow then
        return
    end
    
    if isShow then
        self.PanelUiShow.gameObject:SetActive(isShow)
        self:PlayAnimation("PanelUiShowEnable")
    else
        self:PlayAnimation("PanelUiShowDisable", function()
            self.PanelUiShow.gameObject:SetActive(isShow)
        end)
    end
end

-- 没数据暂停
function XUiRaceFightMain:OnC2LPause()
    -- self:SetPanelUiShow(true)
    self:ShowLoadingMask(true)
    XMVCA.XRace:CloseLoading()
    self:AddWaitExitTimer()
end

-- 数据恢复
function XUiRaceFightMain:OnC2LResume()
    -- self:SetPanelUiShow(false)
    self:RemoveWaitExitTimer()
    self:ShowLoadingMask(false)
end

-- 更新排行榜
function XUiRaceFightMain:OnC2LUpdateRank()
    if self._ShowingFinishIndex ~= self._SelectIndex or self._SelectIndex == -1 then
        self._PanelRaceDataUi:UpdateRank(self._SelectIndex, nil, self._SelectIndex == -1)
    end
end

-- 进入中段路程
function XUiRaceFightMain:OnC2LFinishHalf()
    self._IsMiddle = true
    if self.XAudioObjectPlayer then
        self.XAudioObjectPlayer:PlayByKeyName("BGMMiddle")
    end
end

function XUiRaceFightMain:OnC2LError()
    self:Close()
    XMVCA.XRace:CloseLoading()
    self:Record(7)
end

function XUiRaceFightMain:ShowFinish(isFinish)
    if not isFinish and isFinish == self.PanelFinish.gameObject.activeSelf then
        return
    end
    if isFinish and self.PanelFinish.gameObject.activeSelf then
        self.PanelFinish.gameObject:SetActive(false)
    end
    self.PanelFinish.gameObject:SetActive(isFinish)
    if isFinish then
        self._ShowingFinishIndex = self._SelectIndex
        self:PlayAnimation("Finish", function()
            self._PanelRaceDataUi:UpdateRank(self._SelectIndex, true)
            self:OnEnterSprintMode(false)
            self._ShowingFinishIndex = nil
        end)
    end
end

function XUiRaceFightMain:PlayRaceDataEnable()
    self:PlayAnimation("RaceDataEnable")
end

function XUiRaceFightMain:OnEnterSprintMode(isSprintMode)
    if self._IsShowSprintMode == isSprintMode then return end
    if isSprintMode then
        self:PlayAnimation("Disable", function()
            self.PanelMap.gameObject:SetActive(not isSprintMode and not self._ClientFinish)
            self.HeadBg.gameObject:SetActive(not isSprintMode and not self._ClientFinish)
            self.BtnDirector.gameObject:SetActive(not isSprintMode and not self._ClientFinish)
            self.PanelSkillDetail.gameObject:SetActive(not isSprintMode and not self._ClientFinish)
            self.BtnHide.gameObject:SetActive(not isSprintMode and not self._ClientFinish)
        end)
    else
        self.PanelMap.gameObject:SetActive(not isSprintMode and not self._ClientFinish)
        self.HeadBg.gameObject:SetActive(not isSprintMode and not self._ClientFinish)
        self.BtnDirector.gameObject:SetActive(not isSprintMode and not self._ClientFinish)
        self.PanelSkillDetail.gameObject:SetActive(not isSprintMode and not self._ClientFinish)
        self.BtnHide.gameObject:SetActive(not isSprintMode and not self._ClientFinish)
        self:PlayAnimation("Enable")
    end
    self._IsShowSprintMode = isSprintMode
    -- self:ShowFinish(false)
    -- if not isSprintMode then
    --     self._PanelRaceDataUi:UpdateRank(self._SelectIndex)
    -- end
end

function XUiRaceFightMain:OnC2LSprint(csActorIndex)
    local actorIndex = csActorIndex + 1
    self._SprintIndexList[actorIndex] = true
    -- if actorIndex == self._SelectIndex then
    --     self:OnEnterSprintMode(true)
    -- end
    if not self._FirstFinish then
        self._FirstFinish = true
        if self.XAudioObjectPlayer then
            self.XAudioObjectPlayer:PlayByKeyName("BGMEnd")
        end
    end
end

function XUiRaceFightMain:OnC2LSprintFinish(csActorIndex)
    local actorIndex = csActorIndex + 1
    self._SprintIndexList[actorIndex] = false
    self._FinishIndexList[actorIndex] = true
    if actorIndex == self._SelectIndex then
        self:OnEnterSprintMode(true)
        self:ShowFinish(self._FinishIndexList[self._SelectIndex])
    end
    self._Heads[actorIndex]:SetRank(table.nums(self._FinishIndexList))
end

function XUiRaceFightMain:OnC2LFinish()
    self:RemoveCheckTimer()
    -- 结束比赛
    -- self.PanelRaceData.gameObject:SetActive(true)
    self._PanelRaceDataUi:UpdateRank(self._SelectIndex, true)
    self:SetPanelUiShow(false)
    self.HeadBg.gameObject:SetActive(false)
    self.PanelSkillDetail.gameObject:SetActive(false)
    self.PanelMap.gameObject:SetActive(false)
    self.BtnDirector.gameObject:SetActive(false)
    self._ClientFinish = true
    self._NotTips = true
    self:Record(6)
    if self._SceneType ~= XEnumConst.Race.GameMode.LiveStream then
        self.BtnRaceExit.gameObject:SetActive(true)
    end
end

function XUiRaceFightMain:UiCallback(name, ...)
    -- XLog.Warning("UiCallback", name, ...)
    local func = self[name]
    if func then
        func(self, ...)
    end
end

function XUiRaceFightMain:_GetUltraSkillCell()
    if #self._SkillUltraCache > 0 then
        return table.remove(self._SkillUltraCache, 1)
    end

    local XUiGridRaceFightUltraSkill = require("XUi/XUiRace/Grid/XUiGridRaceFightUltraSkill")
    local go = CS.UnityEngine.Object.Instantiate(self.GridSkillTalk, self.GridSkillTalk.transform.parent)
    return XUiGridRaceFightUltraSkill.New(go, self)
end

function XUiRaceFightMain:_RemoveUltraSkillCell(cell)
    table.insert(self._SkillUltraCache, cell)
end

function XUiRaceFightMain:HideTips(cfg, cell)
    for i = 1, #self._UltraSkillShowList do
        local data = self._UltraSkillShowList[i]
        if data.CharCfg == cfg then
            table.remove(self._UltraSkillShowList, i)
            break
        end
    end
    for i = 1, #self._UltraSkill do
        if self._UltraSkill[i] == cell then
            self._UltraSkill[i]:Close()
            table.remove(self._UltraSkill, i)
            self:_RemoveUltraSkillCell(cell)
            break
        end
    end
    if #self._UltraSkillShowList <= 0 then
        self.ListSkillTalkBig.gameObject:SetActive(false)
    end
end

function XUiRaceFightMain:ShowRaceUltraSkill(actorIndex, charCfg)
    if self._IsHide then return end
    self.ListSkillTalkBig.gameObject:SetActive(true)

    local data = {
        ActorIndex = actorIndex,
        CharCfg = charCfg,
    }
    table.insert(self._UltraSkillShowList, data)
    if #self._UltraSkillShowList > 2 then
        local data = self._UltraSkillShowList[1]
        self:HideTips(data.CharCfg, self._UltraSkill[1])
    end
    local cell = self:_GetUltraSkillCell()
    cell:Open()
    cell:Update(data.CharCfg, data.ActorIndex)
    self._UltraSkill[#self._UltraSkill + 1] = cell
end

function XUiRaceFightMain:UpdateSkillCallback(actorIndex, skillId)
    local luaActorIndex = actorIndex + 1
    XEventManager.DispatchEvent(XEventId.EVENT_RACE_GAME_SKILL_UPDATE, luaActorIndex, skillId)

    local charId = self._RaceIds[luaActorIndex]
    local charCfg = self._Control:GetRaceCharacterById(charId)
    if charCfg.UltraSkill == skillId then
        self:ShowRaceUltraSkill(luaActorIndex, charCfg)
    end
end

function XUiRaceFightMain:UpdatePowerCallback(actorIndex, powerIndex, powerCnt)
    local luaActorIndex = actorIndex + 1
    if powerIndex >= 0 then
        local luaPowerIndex = powerIndex + 1
        local lastPowerCnt = self._Control:GetRacePowerCount(luaActorIndex, luaPowerIndex)
        self._Control:UpdateRacePowerData(luaActorIndex, luaPowerIndex, powerCnt, self._IsPlaying)
        XEventManager.DispatchEvent(XEventId.EVENT_RACE_GAME_POWER_UPDATE, luaActorIndex, luaPowerIndex, powerCnt, lastPowerCnt < powerCnt)
    else
        if powerIndex == -1 then
            XEventManager.DispatchEvent(XEventId.EVENT_RACE_GAME_POWER_UPDATE_START, luaActorIndex, powerCnt)
        else
            XEventManager.DispatchEvent(XEventId.EVENT_RACE_GAME_STATE_UPDATE, luaActorIndex, powerCnt)
        end
    end
end

function XUiRaceFightMain:InitRace()
    -- ui初始化
    self:InitHeadsUI()
    -- 场景数据初始化
    self._Scene:InitActor(self._RaceIds, self._UpdatePowerCallback, self._UpdateSkillCallback)
    -- 场景数据初始化
    self._Scene:InitMatch(self._UiCallback)

    -- 切换默认目标
    self:OnBtnHeadClick(self._SelectIndex, true)

    -- 显示等待界面
    if self._WaitingTime > 0 then
        self:ShowWaiting()
    elseif self._ExtraChangeWaitTime > 0 then
        self:ShowExtraWaiting()
    elseif self._StartCountTime > 0 then
        self:ShowCountDown(self._StartCountTime)
    end

    if self._GapTime <= 0 then
        -- finish
        XMVCA.XRace:CloseLoading()
    end
end

-- set loadingMask
function XUiRaceFightMain:ShowLoadingMask(isTrue)
    if self._setLoadingMask == isTrue or (not isTrue and self._setLoadingMask == nil) then return end
    XLuaUiManager.SetAnimationMask("XUiRaceFightMain", isTrue)
    self._setLoadingMask = isTrue
end

function XUiRaceFightMain:OnDestroy()
    XMVCA.XRace:LeaveMatchScene()
    self:ShowLoadingMask(false)
    self._IsDestroyUi = true
    self:RemoveTimer()
    self:RemoveDelayTimer()
    self:RemoveCheckTimer()
    self:RemoveWaitExitTimer()
end

function XUiRaceFightMain:RemoveTimer()
    if not self._CountDownTimerId then return end
    XScheduleManager.UnSchedule(self._CountDownTimerId)
    self._CountDownTimerId = nil
end

function XUiRaceFightMain:RemoveDelayTimer()
    if not self._DelayTimerId then return end
    XScheduleManager.UnSchedule(self._DelayTimerId)
    self._DelayTimerId = nil
end

function XUiRaceFightMain:CheckTimerUpdate()
    self._Scene:CheckMapEffect()
end

function XUiRaceFightMain:AddCheckTimer()
    if self._CheckTimerId then return end
    self._CheckTimerId = XScheduleManager.ScheduleForever(self._CheckTimerUpdateCb, 1000)
end

function XUiRaceFightMain:RemoveCheckTimer()
    if not self._CheckTimerId then return end
    XScheduleManager.UnSchedule(self._CheckTimerId)
    self._CheckTimerId = nil
end

function XUiRaceFightMain:AddWaitExitTimer()
    self:RemoveWaitExitTimer()
    local contentStr = self._IsFinish and XUiHelper.GetText("RaceEndDesc") or XUiHelper.GetText("RaceErrorDesc")
    self._WaitExitTimerId = XScheduleManager.ScheduleOnce(function()
        if self._IsDestroyUi then return end
        self._OpenTips = true
        self._Scene:Stop()
        self:ShowLoadingMask(false)
        XUiManager.DialogTip(nil, contentStr, XUiManager.DialogType.OnlySure, nil, function()
            self:OnBtnRaceExitClick()
        end)
    end, tonumber(self._Control:GetClientConfig("ErrorTime")) or 5000)
end

function XUiRaceFightMain:RemoveWaitExitTimer()
    if not self._WaitExitTimerId then return end
    XScheduleManager.UnSchedule(self._WaitExitTimerId)
    self._WaitExitTimerId = nil
end

function XUiRaceFightMain:ShowWaiting()
    self:SetMatchStatus(MatchStatus.Wait)
    
    self:SetPanelUiShow(true)
    self._Scene:PlayTrackAnim(true)

    self:RemoveTimer()
    self._CountDownTimerId = XScheduleManager.ScheduleOnce(function()
        self:ShowExtraWaiting()
    end, self._WaitingTime * 1000)
end


function XUiRaceFightMain:ShowExtraWaiting()
    self:SetMatchStatus(MatchStatus.Wait)
    self:SetPanelUiShow(false)
    self._Scene:PlayTrackAnim(false)

    self:RemoveTimer()
    self._CountDownTimerId = XScheduleManager.ScheduleOnce(function()
        self:ShowCountDown(self._StartCountTime)
    end, self._ExtraChangeWaitTime * 1000)
end

function XUiRaceFightMain:UpdateSkillInfo(isInit)
    if not self._ShowSkill then
        if not isInit then
            self:Record(4, self._SelectIndex)
        end
    else
        if not self._SkillDetailPanel then
            local XUiPanelRaceFightSkillDetail = require("XUi/XUiRace/Panel/XUiPanelRaceFightSkillDetail")
            self._SkillDetailPanel = XUiPanelRaceFightSkillDetail.New(self.SkillLayout, self)
            self._SkillDetailPanel:Open()
        end
        self._SkillDetailPanel:SetRaceId(self._RaceIds[self._SelectIndex], self._SelectIndex)
        if not isInit then
            self:Record(5, self._SelectIndex)
        end
    end
end

function XUiRaceFightMain:OnBtnHeadClick(index, isInit)
    if self._ShowingFinishIndex then return end
    if self._SelectIndex and self._SelectIndex > 0 then
        self._Heads[self._SelectIndex]:SetSelected(false)
    end
    self._SelectIndex = index
    local head = self._Heads[self._SelectIndex]
    if not head then return end
    head:SetSelected(true)
    self._Scene:MoveCamera2Index(index)

    self:UpdateSkillInfo(isInit)
    
    self.PanelSkillDetail.gameObject:SetActive(true)
    self._PanelRaceDataUi:SelectIndex(index, self._RaceIds[self._SelectIndex])

    if self._FinishIndexList[self._SelectIndex] then
        self:OnEnterSprintMode(false)
    end
end

function XUiRaceFightMain:InitHeadsUI()
    self.PanelMap.gameObject:SetActive(true)
    self.PanelRaceMatch.gameObject:SetActive(true)

    XTool.UpdateDynamicItem(self._Heads, self._RaceIds, self.GridCharacter, XUiGridRaceFightCharacter, self)
    XTool.UpdateDynamicItem(self._MapHeads, self._RaceIds, self.GridMapCharacter, XUiGridRaceFightMapCharacter, self)
    self._Scene:InitMapHead(self._MapHeads, self.GridAreas.gameObject)
    if self._TagIndex then
        self._Heads[self._TagIndex]:ShowTagPredict(true)
    end
end

function XUiRaceFightMain:ShowTextInfo(index)
    local path = self._Control:GetClientConfig("CountdownUI", index)
    self.CountNumber:SetRawImage(path)
    self:PlayAnimation("Countdown")
    if self.XAudioObjectPlayer then
        self.XAudioObjectPlayer:PlayByKeyName("AudioStart321")
    end
end

function XUiRaceFightMain:DelayStartRace()
    self:RemoveDelayTimer()
    self._DelayTimerId = XScheduleManager.ScheduleOnce(function()
        self._Scene:PlayMatch()
        self:AddCheckTimer()
    end, 150)
    self._IsHide = false
end

function XUiRaceFightMain:ShowCountDown(count)
    if self._IsPlaying then return end

    self:SetMatchStatus(MatchStatus.CountDown)

    self.PanelCountdown.gameObject:SetActive(true)
    self.PanleGo.gameObject:SetActive(false)

    self._TimeCount = count
    self:ShowTextInfo(self._TimeCount)

    self:RemoveTimer()
    local timeGap = 1
    self._CountDownTimerId = XScheduleManager.ScheduleForever(function()
        self._TimeCount = self._TimeCount - timeGap
        if self._TimeCount >= 0 then
            if self._TimeCount == 0 then
                self:DelayStartRace()
                self:SetMatchStatus(MatchStatus.Matching)
                self.PanleGo.gameObject:SetActive(true)
                self:PlayAnimation("Go")
                self.PanelCountdown.gameObject:SetActive(false)
                if self.XAudioObjectPlayer then
                    self.XAudioObjectPlayer:PlayByKeyName("AudioStartGo")
                    self.XAudioObjectPlayer:PlayByKeyName("BGMStart")
                end
        else
                if self._TimeCount - math.floor(self._TimeCount) < 0.2 then
                    self:ShowTextInfo(self._TimeCount)
                end
            end
        else
            self.PanleGo.gameObject:SetActive(false)
            XScheduleManager.UnSchedule(self._CountDownTimerId)
            self._CountDownTimerId = nil
        end
    end, timeGap * 1000)
end

function XUiRaceFightMain:SetMatchStatus(status)
    self.PanelWait.gameObject:SetActive(status == MatchStatus.Wait)
    self.PanelMap.gameObject:SetActive(status == MatchStatus.Matching and not self._ClientFinish)
    self.PanelRaceMatch.gameObject:SetActive(status == MatchStatus.Matching)
    if status == MatchStatus.Matching then
        for i = 1, #self._Heads do
            self._Heads[i]:SetSelected(i == self._SelectIndex)
        end
    end

    self._CurrentStatus = status
end

function XUiRaceFightMain:OnBtnDirectorClick()
    if self._SelectIndex == -1 then
        return
    end
    if self._SelectIndex and self._SelectIndex > 0 then
        self._Heads[self._SelectIndex]:SetSelected(false)
    end
    self._SelectIndex = -1
    self._Scene:SetAutoCamera()
    self.PanelSkillDetail.gameObject:SetActive(false)
    self:Record(3)
end

function XUiRaceFightMain:NormalClose()
    if self._IsCloseUiRaceFightMain then return end
    self._IsCloseUiRaceFightMain = true
    self:Close()
    self:Record(2)
end

function XUiRaceFightMain:OnBtnExitClick()
    if self._SceneType == XEnumConst.Race.GameMode.LiveStream and self._IsFinish then
        self._Control:OpenSettlePanel(self._RoundId, function()
            self:NormalClose()
        end)
        return
    end
    XUiManager.DialogTip(nil, XUiHelper.GetText("RaceFightQuitContent"), XUiManager.DialogType.Normal, nil, function()
        self:NormalClose()
    end)
end

function XUiRaceFightMain:OnBtnHideClick()
    self:PlayAnimation("Disable", function()
        self.PanelWait.gameObject:SetActive(false)
        self.PanelMap.gameObject:SetActive(false)
        self.PanelRaceMatch.gameObject:SetActive(false)
        self.BtnExit.gameObject:SetActive(false)
        self.BtnMask.gameObject:SetActive(true)
        self._PanelRaceDataUi:Close()
        self._IsHide = true
    end)
end

function XUiRaceFightMain:OnBtnMaskClick()
    self.BtnMask.gameObject:SetActive(false)
    self.BtnExit.gameObject:SetActive(true)

    self._PanelRaceDataUi:Open()
    self._PanelRaceDataUi:UpdateRank(self._SelectIndex)
    self:SetMatchStatus(self._CurrentStatus)
    self._IsHide = false
    self:PlayAnimation("Enable")
end

function XUiRaceFightMain:OnBtnCloseClick()
    self._ShowSkill = not self._ShowSkill
    if self.BtnClose02 then
        self.BtnClose02.gameObject:SetActive(self._ShowSkill)
        self.BtnClose.gameObject:SetActive(not self._ShowSkill)
    end
    if self._ShowSkill then
        self:PlayAnimation("PanelSkillDetailExpand")
    else
        self:PlayAnimation("PanelSkillDetailStorage")
    end
    -- self.PanelSkillDetail.transform.anchoredPosition = self._ShowSkill and CS.UnityEngine.Vector2(0, self._DefaultPos.y) or self._DefaultPos
    self:UpdateSkillInfo()
end

function XUiRaceFightMain:OnBtnRaceExitClick()
    if self._IsFinish and self._SceneType == XEnumConst.Race.GameMode.LiveStream then
        self._Control:OpenSettlePanel(self._RoundId, function()
            self:NormalClose()
        end)
        return
    end
    self:NormalClose()
end

function XUiRaceFightMain:Record(optId, selectId)
    if self._SceneType ~= XEnumConst.Race.GameMode.LiveStream and self._SceneType ~= XEnumConst.Race.GameMode.Playback then
        return
    end
    local dict = {}
    dict.opt_int = optId
    dict.play_type_int = self._SceneType == XEnumConst.Race.GameMode.LiveStream and 0 or 1
    dict.id_str = tostring(selectId and self._RaceIds[selectId] or 0)
    dict.round_id_str = tostring(self._RoundId)
    dict.guess_int = self._GuessId or 0
    dict.enter_count_int = self._EnterCount
    dict.enter_time_int = self._CurrentTime
    CS.XRecord.Record(dict, "900013", "RaceClientRecord")
end

function XUiRaceFightMain:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.BtnDirector.CallBack = Handler(self, self.OnBtnDirectorClick)
    self.BtnExit.CallBack = Handler(self, self.OnBtnExitClick)
    self.BtnHide.CallBack = Handler(self, self.OnBtnHideClick)
    self.BtnMask.CallBack = Handler(self, self.OnBtnMaskClick)
    self.BtnClose.CallBack = Handler(self, self.OnBtnCloseClick)
    -- self.BtnRaceExit.CallBack = Handler(self, self.OnBtnRaceExitClick)
    self.BtnRaceExit:AddEventListener(handler(self, self.OnBtnRaceExitClick))
    if self.BtnClose02 then
        self.BtnClose02.CallBack = Handler(self, self.OnBtnCloseClick)
    end
end

return XUiRaceFightMain
