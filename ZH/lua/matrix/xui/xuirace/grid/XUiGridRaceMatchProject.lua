---@class XUiGridRaceMatchProject : XUiNode 赛事预测项目
---@field Parent XUiRaceProjectChose
---@field _Control XRaceControl
local XUiGridRaceMatchProject = XClass(XUiNode, "XUiGridRaceMatchProject")

local MatchState = XEnumConst.Race.MatchState

function XUiGridRaceMatchProject:OnStart(guessId)
    self._GuessId = guessId
    self._GuessCfg = self._Control:GetRaceGuessById(guessId)
    self._MatchData = self._Control:GetMatchGuessData()
    
    self.TxtName.text = self._GuessCfg.Name
    self.ImgIcon:SetRawImage(XDataCenter.ItemManager.GetItemIcon(self.Parent._ActivityConfig.ItemId))
    self.TxtNum.text = self._GuessCfg.RewardNum
    self.ImgTag.gameObject:SetActiveEx(self._GuessCfg.SpecialType == 1)
    self.GridProject.CallBack = handler(self, self.OnBtnClick)
    self.Transform.name = guessId
end

function XUiGridRaceMatchProject:UpdateView()
    local state = self.Parent._MatchState
    local mineGuessId = self._Control:GetGuessProjectOption(nil, self._GuessId)
    local isRoleType = self._Control:IsGuessNeedCharacter(self._GuessId)
    local isResult = false
    self.TagBg01.gameObject:SetActiveEx(false)
    
    if state == MatchState.Guess then
        self:NormalPredict()
    elseif self._MatchData:IsWaitOpen(self._GuessId) then --等待开奖
        if mineGuessId then
            self:NormalPredict()
        else
            self:NotPredict()
        end
    else
        if self._MatchData:IsPredictSuccess(self._GuessId) then
            self:PredictSuccess()
        else
            self:PredictFail()
        end
        isResult = true
        local isMultiRole = self._Control:IsGuessProjectMultiRole(nil, self._GuessId)
        self.TagBg01.gameObject:SetActiveEx(isMultiRole)
    end

    if isRoleType then
        self:ShowRole(mineGuessId, isResult)
    else
        self:ShowOption(mineGuessId)
    end
end

---预测中/已预测
function XUiGridRaceMatchProject:NormalPredict()
    self.PanelMoney.gameObject:SetActiveEx(true)
    self.PanelResult.gameObject:SetActiveEx(false)
    self.PanelDetail.gameObject:SetActiveEx(false)
    self.ImgMask.gameObject:SetActiveEx(false)
    self.GridProject:ShowReddot(not self._MatchData:IsPredict(self._GuessId))
end

---预测已结束+未预测
function XUiGridRaceMatchProject:NotPredict()
    self.PanelMoney.gameObject:SetActiveEx(true)
    self.PanelResult.gameObject:SetActiveEx(false)
    self.PanelDetail.gameObject:SetActiveEx(false)
    self.ImgMask.gameObject:SetActiveEx(true)
    self.GridProject:ShowReddot(false)
end

---预测成功
function XUiGridRaceMatchProject:PredictSuccess()
    self.PanelMoney.gameObject:SetActiveEx(false)
    self.PanelResult.gameObject:SetActiveEx(true)
    self.RImgRight.gameObject:SetActiveEx(true)
    self.RImgWrong.gameObject:SetActiveEx(false)
    self.PanelDetail.gameObject:SetActiveEx(true)
    self.ImgMask.gameObject:SetActiveEx(false)
    self.GridProject:ShowReddot(false)
end

---预测失败
function XUiGridRaceMatchProject:PredictFail()
    self.PanelMoney.gameObject:SetActiveEx(false)
    self.PanelResult.gameObject:SetActiveEx(true)
    self.RImgRight.gameObject:SetActiveEx(false)
    self.RImgWrong.gameObject:SetActiveEx(true)
    self.PanelDetail.gameObject:SetActiveEx(true)
    self.ImgMask.gameObject:SetActiveEx(false)
    self.GridProject:ShowReddot(false)
end

function XUiGridRaceMatchProject:ShowRole(roleId, isResult)
    self.PanelRole.gameObject:SetActiveEx(true)
    self.PanleOption.gameObject:SetActiveEx(false)
    if roleId then
        local isObsolete = self._Control:IsCharacterObsoleteNow(roleId)
        local roleIcon = self._Control:GetRaceCharacterById(roleId).Icon
        self.RImgHead1:SetRawImage(roleIcon)
        self.RImgHead2:SetRawImage(roleIcon)
        self.ImgRoleEmpty.gameObject:SetActiveEx(false)
        self.RImgHead1.gameObject:SetActiveEx(true)
        self.ImgFail.gameObject:SetActiveEx(isObsolete and not isResult)
    else
        self.ImgRoleEmpty.gameObject:SetActiveEx(true)
        self.RImgHead1.gameObject:SetActiveEx(false)
        self.ImgFail.gameObject:SetActiveEx(false)
    end
end

function XUiGridRaceMatchProject:ShowOption(optionId)
    self.PanelRole.gameObject:SetActiveEx(false)
    self.PanleOption.gameObject:SetActiveEx(true)
    if optionId then
        self.TxtOption.text = self._Control:GetGuessParamDesc(optionId)
        self.TxtOption.gameObject:SetActiveEx(true)
        self.ImgOptionEmpty.gameObject:SetActiveEx(false)
    else
        self.TxtOption.gameObject:SetActiveEx(false)
        self.ImgOptionEmpty.gameObject:SetActiveEx(true)
    end
end

function XUiGridRaceMatchProject:OnBtnClick()
    local state = self.Parent._MatchState
    local isPredict = self._MatchData:IsPredict(self._GuessId)

    if state == MatchState.Guess then
        self._Control:RequestGlobalRoundSupportRate(function()
            XLuaUiManager.Open("UiRacePredict", nil, true, self._GuessId)
        end)
    elseif self._MatchData:IsWaitOpen(self._GuessId) then
        if isPredict then
            self._Control:OpenTip("RaceMatchGuessTip2") --请等待开奖
        else
            self._Control:OpenTip("RaceMatchGuessTip1") --预测时间已过，无法进行预测
        end
    else
        if isPredict then
            XLuaUiManager.Open("UiRacePopupResultDetail", self._GuessId)
        else
            self._Control:OpenTip("RaceMatchGuessTip3") --未预测该项目，无可查看结果
        end
    end
end

return XUiGridRaceMatchProject
