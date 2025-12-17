---@class XUiRacePopupResultDetail : XLuaUi 赛事预测结果弹框
---@field _Control XRaceControl
local XUiRacePopupResultDetail = XLuaUiManager.Register(XLuaUi, "UiRacePopupResultDetail")

function XUiRacePopupResultDetail:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.Close)
    self.BtnTanchuangClose.CallBack = handler(self, self.Close)
    self.BtnPlayback.CallBack = handler(self, self.OnBtnPlaybackClick)
end

function XUiRacePopupResultDetail:OnStart(guessId)
    self._GuessId = guessId
    self._MatchData = self._Control:GetMatchGuessData()
    self._Info = self._MatchData:GetInfo(guessId)
    self._IsHideRank = self._Control:IsGuessHideRank(guessId)

    self._IsSuccess = self._MatchData:IsPredictSuccess(guessId)
    self.ImgRight.gameObject:SetActiveEx(self._IsSuccess)
    self.ImgWrong.gameObject:SetActiveEx(not self._IsSuccess)
    self.TxtProject.text = self._Control:GetRaceGuessById(guessId).Name
    self.BtnPlayback.gameObject:SetActiveEx(not self._Control:IsGuessHidePlayback(guessId))

    self:InitPredict(self.PanelWinner, true)
    self:InitPredict(self.PanelMine, false)

    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
    end)
end

function XUiRacePopupResultDetail:InitPredict(go, isResultOrPredict)
    local isRole = self._Control:IsGuessNeedCharacter(self._GuessId)
    local mineOption = self._Control:GetGuessProjectOption(nil, self._GuessId)
    local resultOption = self._Control:GetGuessProjectResult(nil, self._GuessId)
    local option = isResultOrPredict and resultOption or mineOption
    if self._IsSuccess and isResultOrPredict and self._Control:IsGuessProjectMultiRole(nil, self._GuessId) then
        option = mineOption
    end

    local uiObject = {}
    XUiHelper.InitUiClass(uiObject, isResultOrPredict and self.PanelWinner or self.PanelMine)
    if isRole then
        local roleCfg = self._Control:GetRaceCharacterById(option)
        local property = isResultOrPredict and self._Info.ResultPropertyValue or self._Info.GuessPropertyValue
        uiObject.PanelRole.gameObject:SetActiveEx(true)
        uiObject.PanelOption.gameObject:SetActiveEx(false)
        uiObject.ImgHead:SetRawImage(roleCfg.Icon)
        uiObject.TxtRoleName.text = roleCfg.Name
        if self._IsHideRank then
            uiObject.TxtType.gameObject:SetActiveEx(false)
        else
            uiObject.TxtType.gameObject:SetActiveEx(true)
            uiObject.TxtType.text = string.format("%s：", self._Control:GetPropertyName(self._GuessId))
        end
        uiObject.TxtDetail.text = self._Control:GetPropertyDesc(self._GuessId, property)
    else
        uiObject.PanelRole.gameObject:SetActiveEx(false)
        uiObject.PanelOption.gameObject:SetActiveEx(true)
        uiObject.TxtOption.text = self._Control:GetGuessParamDesc(option)
    end
end

function XUiRacePopupResultDetail:OnBtnPlaybackClick()
    local roundId = self._Control:GetPlaybackRoundId(self._GuessId)
    if XTool.IsNumberValid(roundId) then
        self._Control:EnterGame(roundId, XEnumConst.Race.GameMode.Playback)
    else
        XLog.Error(string.format("赛事竞猜:GuessId=%s没有配置回放场次Id", self._GuessId))
    end
end

return XUiRacePopupResultDetail