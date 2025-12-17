---@class XUiRaceFightPredictSettlement : XLuaUi 结算-预测结果
---@field _Control XRaceControl
local XUiRaceFightPredictSettlement = XLuaUiManager.Register(XLuaUi, "UiRaceFightPredictSettlement")

function XUiRaceFightPredictSettlement:OnAwake()
    self.BtnPlayback.CallBack = handler(self, self.OnBtnPlaybackClick)
    self.BtnRaceDetail.CallBack = handler(self, self.OnBtnRaceDetailClick)
    self.BtnNext.CallBack = handler(self, self.OnClose)
    self.BtnGetReward.CallBack = handler(self, self.OnBtnGetRewardClick)
end

function XUiRaceFightPredictSettlement:OnStart(roundId)
    self._CanGainReward = false
    self._ResultRoundId = roundId
    self._ItemId = self._Control:GetCurrentConfig().ItemId
    local infoDict = {}

    local param = self._Control:GetSettleParam()
    self._IsFromRound = param and param.IsFromRound
    
    if roundId then
        --单场竞猜
        local cfg = self._Control:GetRaceRoundById(roundId)
        local data = self._Control:GetRoundGuessData(roundId)
        infoDict = data:GetInfoDict()

        if string.IsNilOrEmpty(cfg.SubTitle) then
            self.TxtRace.text = cfg.Name
        else
            self.TxtRace.text = string.format("%s-%s", cfg.Name, cfg.SubTitle)
        end
        self.BtnPlayback.gameObject:SetActiveEx(not self._IsFromRound)
        self.BtnRaceDetail.gameObject:SetActiveEx(not self._IsFromRound)
        self._Control:SetRoundResultCheck(roundId)
    else
        --赛事竞猜
        local data = self._Control:GetMatchGuessData()
        infoDict = data:GetInfoDict()

        self.TxtRace.text = ""
        self.BtnPlayback.gameObject:SetActiveEx(false)
        self.BtnRaceDetail.gameObject:SetActiveEx(false)
    end
    
    ---@type GuessInfo[]
    local infos = {}
    for _, v in pairs(infoDict) do
        local guessId = v.GuessId
        local isCorrect = self._Control:IsPredictSuccess(self._ResultRoundId, guessId)
        if isCorrect then
            self._CanGainReward = true
        end
        table.insert(infos, v)
    end
    table.sort(infos, function(a, b)
        return a.GuessId < b.GuessId
    end)

    self.GridPredict.gameObject:SetActiveEx(false)
    local timerId = XScheduleManager.ScheduleOnce(function()
        self:ShowPredictResult(infos)
    end, 500)
    self:_AddTimerId(timerId)

    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
    end)

    self.BtnGetReward.gameObject:SetActiveEx(self._CanGainReward)
    self.BtnNext.gameObject:SetActiveEx(not self._CanGainReward)
end

function XUiRaceFightPredictSettlement:OnDestroy()
    if not XLuaUiManager.IsUiShow("UiRaceFightSettlement") then
        self._Control:ClearSettleParam()
    end
end

function XUiRaceFightPredictSettlement:ShowPredictResult(infos)
    local itemIcon = XDataCenter.ItemManager.GetItemIcon(self._ItemId)
    XUiHelper.RefreshCustomizedList(self.GridPredict.parent, self.GridPredict, #infos, function(i, go)
        local info = infos[i]
        local guessId = info.GuessId
        local guessCfg = self._Control:GetRaceGuessById(guessId)
        local property = self._Control:GetGuessProperty(guessId)
        local isPredict = self._Control:IsPredict(self._ResultRoundId, guessId)
        local isRole = self._Control:IsGuessNeedCharacter(guessId)
        local isCorrect = self._Control:IsPredictSuccess(self._ResultRoundId, guessId)
        local isPropertyRank = property == XEnumConst.Race.PropertyType.Rank
        local uiObject = {}
        local roleCfg

        XUiHelper.InitUiClass(uiObject, go)
        uiObject.Transform.name = guessId
        uiObject.TxtTitle.text = guessCfg.Name
        uiObject.RImgRole.gameObject:SetActiveEx(isRole)
        uiObject.PanelOption.gameObject:SetActiveEx(not isRole)
        uiObject.PanelMyPredict.gameObject:SetActiveEx(isPredict)
        uiObject.PanelNone.gameObject:SetActiveEx(not isPredict)
        uiObject.PanelActualData.gameObject:SetActiveEx(isRole and not isPropertyRank) --预测属性是排名时 不需要显示
        uiObject.PanelTopRole.gameObject:SetActiveEx(isRole and isPropertyRank)
        uiObject.Win.gameObject:SetActiveEx(isCorrect) --预测结果是否正确
        uiObject.Lost.gameObject:SetActiveEx(not isCorrect)
        uiObject.TagParallel.gameObject:SetActiveEx(self._Control:IsGuessProjectMultiRole(self._ResultRoundId, guessId))

        local resultId = self._Control:GetGuessProjectResult(self._ResultRoundId, guessId)
        if isRole then
            --实际结果
            local resultRoleId = isCorrect and info.GuessRoleId or resultId
            roleCfg = resultRoleId and self._Control:GetRaceCharacterById(resultRoleId)
            if roleCfg then
                uiObject.RImgRole.gameObject:SetActiveEx(true)
                uiObject.RImgRole:SetRawImage(roleCfg.Icon)
            else
                uiObject.RImgRole.gameObject:SetActiveEx(false)
            end
            uiObject.TxtValue.text = self._Control:GetPropertyDesc(guessId, info.ResultPropertyValue)
            --预测结果
            if isCorrect then
                uiObject.PanelHeadWin.gameObject:SetActiveEx(isPredict)
                uiObject.TxtPredictWin.gameObject:SetActiveEx(false)
                if isPredict then
                    roleCfg = self._Control:GetRaceCharacterById(info.GuessRoleId)
                    uiObject.RImgHeadWin:SetRawImage(roleCfg.Icon)
                    uiObject.TxtRankWin.text = self._Control:GetPropertyDesc(guessId, info.GuessPropertyValue)
                end
            else
                uiObject.PanelHeadLost.gameObject:SetActiveEx(isPredict)
                uiObject.TxtPredictLost.gameObject:SetActiveEx(false)
                if isPredict then
                    roleCfg = self._Control:GetRaceCharacterById(info.GuessRoleId)
                    uiObject.RImgHeadLost:SetRawImage(roleCfg.Icon)
                    uiObject.TxtRankLost.text = self._Control:GetPropertyDesc(guessId, info.GuessPropertyValue)
                end
            end
        else
            --实际结果
            uiObject.TxtOption.text = self._Control:GetPropertyDesc(guessId, info.ResultPropertyValue)
            --预测结果
            local guessOptionId = self._Control:GetGuessProjectOption(self._ResultRoundId, guessId)
            if isCorrect then
                uiObject.PanelHeadWin.gameObject:SetActiveEx(false)
                uiObject.TxtPredictWin.gameObject:SetActiveEx(true)
                uiObject.TxtPredictWin.text = isPredict and self._Control:GetGuessParamDesc(guessOptionId) or ""
            else
                uiObject.PanelHeadLost.gameObject:SetActiveEx(false)
                uiObject.TxtPredictLost.gameObject:SetActiveEx(true)
                uiObject.TxtPredictLost.text = isPredict and self._Control:GetGuessParamDesc(guessOptionId) or ""
            end
        end

        --预测正确奖励
        if isCorrect then
            uiObject.RImgIcon:SetRawImage(itemIcon)
            uiObject.TxtNum.text = string.format("+%s", guessCfg.RewardNum)
        end

        uiObject.GameObject:SetActiveEx(false)
        local timerId = XScheduleManager.ScheduleOnce(function()
            uiObject.GameObject:SetActiveEx(true)
        end, i * 50)
        self:_AddTimerId(timerId)
    end)
end

function XUiRaceFightPredictSettlement:OnBtnPlaybackClick()
    self._Control:OpenPopup("TipTitle", "RaceReviewPopupTitle", nil, function()
        self._Control:EnterGame(self._ResultRoundId, XEnumConst.Race.GameMode.Playback)
    end)
end

function XUiRaceFightPredictSettlement:OnBtnRaceDetailClick()
    XLuaUiManager.Open("UiRaceFightSettlement", self._ResultRoundId)
    self:Close()
end

function XUiRaceFightPredictSettlement:OnBtnGetRewardClick()
    if self._ResultRoundId then
        self._Control:RequestSingleRoundGainReward(self._ResultRoundId, function(itemCount)
            self:ShowRewardAndClose(itemCount)
        end, handler(self, self.Close))
    else
        self._Control:RequestGuessGlobalGainReward(function(itemCount)
            self:ShowRewardAndClose(itemCount)
        end, handler(self, self.Close))
    end
end

function XUiRaceFightPredictSettlement:ShowRewardAndClose(itemCount)
    local reward = {}
    reward.RewardType = XRewardManager.XRewardType.Item
    reward.TemplateId = self._ItemId
    reward.Count = itemCount
    self._Control:OpenUiObtain({ reward }, nil, function()
        self:OnClose()
    end)
end

function XUiRaceFightPredictSettlement:OnClose()
    if self._Control:IsAllMatchFinish() or self._IsFromRound then
        self:Close()
    else
        self._Control:RequestCurRoundSupportRate(function()
            XLuaUiManager.OpenWithCallback("UiRacePredict", function()
                XLuaUiManager.Remove("UiRaceFightPredictSettlement")
            end)
        end)
    end
end

return XUiRaceFightPredictSettlement