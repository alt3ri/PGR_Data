local utf8 = require("utf8")

---@class XUiRaceMain : XLuaUi 赛马主界面
---@field _Control XRaceControl
---@field _MatchInfoPanel XUiPanelRaceMatchInfo
---@field _TaskReward XUiPanelRaceTaskBubble
---@field _3DCamera XUiPanelRace3DCamera
local XUiRaceMain = XLuaUiManager.Register(XLuaUi, "UiRaceMain")

function XUiRaceMain:OnAwake()
    self:BindHelpBtn(self.BtnHelp, "RaceMainHelp")
    self.BtnPredictAll.CallBack = handler(self, self.OnBtnPredictAllClick)
    self.BtnPredictOne.CallBack = handler(self, self.OnBtnPredictOneClick)
    self.BtnRank.CallBack = handler(self, self.OnBtnRankClick)
    self.BtnShop.CallBack = handler(self, self.OnBtnShopClick)
    self.BtnSkin.CallBack = handler(self, self.OnBtnSkinClick)
end

function XUiRaceMain:OnStart()
    self._ActivityConfig = self._Control:GetCurrentConfig()
    self._MatchInfoPanel = require("XUi/XUiRace/Panel/XUiPanelRaceMatchInfo").New(self.PanelMatchInfo, self)
    self._TaskReward = require("XUi/XUiRace/Panel/XUiPanelRaceTaskBubble").New(self.PanelTaskReward, self)
    self._3DCamera = require("XUi/XUiRace/Panel/XUiPanelRace3DCamera").New(self.UiModelGo.transform, self, XEnumConst.Race.SceneType.Main)
    
    self._TimeToMatchCountDown = self._Control:GetIntClientConfig("TimeToMatchCountDown") * 24 * 60 * 60

    self._Shown = {}
    self._EndTime = self._Control:GetTime()
    self._Broadcasts = self._Control:GetRaceHomeNewsConfigs()
    self._BroadcastCount = XTool.GetTableCount(self._Broadcasts)
    self._BroadcastDelay = self._Control:GetIntClientConfig("MainBroadcastWordShowTime")

    self:ShowSkinPopup()
    self:CountDown()
    self:InitUi()
    self:PlayBroadcast()
    
    self._3DCamera:RegisterRoleClick()

    local animStart = self.UiModelGo.transform:Find("Animation/AnimStart")
    if not XTool.UObjIsNil(animStart) then
        animStart:PlayTimelineAnimation()
    end
end

function XUiRaceMain:OnEnable()
    XMVCA.XFunction:EnterFunction(XFunctionManager.FunctionName.Race)

    self._3DCamera:ShowRoundRole()
    self:PlayPlatformDown()
    self:RefreshView()
    self:UpdateSkinBtn()
    self:CheckLastRound()
end

function XUiRaceMain:OnDestroy()
    self:RemoveBroadcastTimer()
    self._Control:SetRoleRandomSite(nil)
end

function XUiRaceMain:Close()
    XMVCA.XFunction:ExitFunction(XFunctionManager.FunctionName.Race)
    self.Super.Close(self)
end

function XUiRaceMain:InitUi()
    XUiHelper.NewPanelActivityAssetSafe({ self._ActivityConfig.ItemId }, self.PanelSpecialTool, self)
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
    self.BtnSkin:SetSprite(self._Control:GetClientConfig("SkinIcon"))
end

---请求上一把比赛预测结果
function XUiRaceMain:CheckLastRound()
    local lastId = self._Control:GetLastGuessRoundId()
    if not lastId then
        return
    end
    if self._Control:IsExistGuessResultData(lastId) then
        return
    end
    self._Control:RequestGuessSingleRoundResult(lastId, function()
        self:ShowRedPoint()
    end)
end

function XUiRaceMain:UpdateGuessBtn()
    local nowTime = XTime.GetServerNowTimestamp()
    local matchGuessEndTime = XFunctionManager.GetEndTimeByTimeId(self._ActivityConfig.MatchGuessTime)
    local leftTime = matchGuessEndTime - nowTime
    if leftTime >= self._TimeToMatchCountDown then
        self.BtnPredictAll:SetSpriteVisible(false)
    elseif leftTime > 0 and leftTime < self._TimeToMatchCountDown then
        -- 赛事预测剩余时间不足三天，显示倒计时
        local timeStr = XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.CHATEMOJITIMER)
        self.BtnPredictAll:SetNameByGroup(1, XUiHelper.GetText("RaceAllGuessTime", timeStr))
        self.BtnPredictAll:SetSpriteVisible(true)
    else
        self._IsMatchResultCheck = self._Control:IsMatchResultCheck()
        if self._Control:IsAllMatchFinish() and not self._IsMatchResultCheck then
            -- 比赛全部结束且存在赛事预测奖励没领取
            self.BtnPredictAll:SetNameByGroup(1, XUiHelper.GetText("RaceAllGuessReward"))
            self.BtnPredictAll:SetSpriteVisible(true)
        else
            self.BtnPredictAll:SetSpriteVisible(false)
        end
    end

    local state = self._RoundInfo.State
    if state == XEnumConst.Race.RoundState.InProgress then
        self.BtnPredictOne:SetNameByGroup(0, XUiHelper.GetText("RaceOneGuessState2"))
    else
        local unclaimedsRoundId = self._Control:GetDontViewedRoundId()
        if unclaimedsRoundId then
            -- 有预测奖励没领取
            self.BtnPredictOne:SetNameByGroup(0, XUiHelper.GetText("RaceOneGuessState3"))
        else
            if state == XEnumConst.Race.RoundState.Guess then
                local cur, total = self._Control:GetCurRoundGuessProgress()
                self.BtnPredictOne:SetNameByGroup(0, XUiHelper.GetText("RaceOneGuessState1"))
                self.BtnPredictOne:SetNameByGroup(1, string.format("%s/%s", cur, total))
            elseif state == XEnumConst.Race.RoundState.End then
                self.BtnPredictOne:SetNameByGroup(0, XUiHelper.GetText("RaceOneGuessState4"))
            end
        end
    end
    self.BtnPredictOne:SetSpriteVisible(state == XEnumConst.Race.RoundState.Guess)
end

function XUiRaceMain:UpdateSkinBtn()
    -- Disable状态表示已领取
    self.BtnSkin:SetButtonState(self._Control:IsSkinRewardGain() and XUiButtonState.Disable or XUiButtonState.Normal)
end

function XUiRaceMain:PlayBroadcast()
    self:RemoveBroadcastTimer()

    local words = self:GetRandomBroadcast()
    local len = self:GetUTF8Len(words)
    local now = XTime.GetServerNowTimestamp()
    local wordIndex = 1

    self._BroadcastTimer = XScheduleManager.Schedule(function()
        self.TxtBroadcast.text = self:GetUTF8Sub(words, wordIndex)
        if wordIndex >= len then
            -- 文字打印结束
            self:RemoveBroadcastTimer()
            -- 下一条播报
            self._BroadcastTimer = XScheduleManager.ScheduleOnce(handler(self, self.PlayBroadcast), self._ActivityConfig.NewsTime * 1000)
        else
            wordIndex = wordIndex + 1
        end
    end, self._BroadcastDelay, len, 0)
end

function XUiRaceMain:GetRandomBroadcast()
    if #self._Shown >= self._BroadcastCount then
        self._Shown = {}
    end
    -- 找到未显示过的索引
    local candidates = {}
    local used = {}
    for _, i in ipairs(self._Shown) do
        used[i] = true
    end
    for i = 1, self._BroadcastCount do
        if not used[i] then
            table.insert(candidates, i)
        end
    end
    -- 从候选里随机一个
    local index = candidates[math.random(#candidates)]
    table.insert(self._Shown, index)
    return self._Broadcasts[index].Desc
end

function XUiRaceMain:RemoveBroadcastTimer()
    if self._BroadcastTimer then
        XScheduleManager.UnSchedule(self._BroadcastTimer)
        self._BroadcastTimer = nil
    end
end

function XUiRaceMain:GetUTF8Len(str)
    local count = 0
    for _ in utf8.codes(str) do
        count = count + 1
    end
    return count
end

---取前N个字符
function XUiRaceMain:GetUTF8Sub(str, index)
    local start_byte = utf8.offset(str, 1)
    local end_byte = utf8.offset(str, index + 1)

    if start_byte == nil then
        return "" -- 起始超出长度
    end
    if end_byte == nil then
        end_byte = #str -- 取到末尾
    else
        end_byte = end_byte - 1
    end

    return string.sub(str, start_byte, end_byte)
end

function XUiRaceMain:CountDown()
    self:SetAutoCloseInfo(self._EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
        self:RefreshView()
    end)
    self:RefreshView()
end

function XUiRaceMain:RefreshView()
    local time = self._EndTime - XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetText("RaceMainCountDown", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER))

    self._RoundInfo = self._Control:GetCurRoundInfo()

    local isOpenUiRacePopupGameStart = false
    -- 进入活动主界面时比赛已经开始了，则弹比赛开始弹框
    if self._Control:CheckShowGameStart() then
        if not self._CheckOpenStartGamePopup then
            if self._RoundInfo.State == XEnumConst.Race.RoundState.InProgress then
                XLuaUiManager.Open("UiRacePopupGameStart")
                isOpenUiRacePopupGameStart = false
            end
            self._CheckOpenStartGamePopup = true
        end
    end
    if isOpenUiRacePopupGameStart and self._RoundInfo.State == XEnumConst.Race.RoundState.InProgress then
        if not XMVCA.XRace:IsRunninghMatch() then
            self._Control:OpenSettlePanel()
        end
    end

    self:UpdateGuessBtn()
    self._MatchInfoPanel:Update()
    self._TaskReward:Update()
    self:ShowRedPoint()
end

function XUiRaceMain:OnBtnPredictAllClick()
    if self._Control:IsAllMatchFinish() then
        self._Control:RequestGuessGlobalResult(function()
            local isCanGain = self._Control:HasJoinGuess() and not self._Control:IsAllGuessRewardGain()
            if isCanGain or not self._IsMatchResultCheck then
                --比赛全部结束+有赛事预测奖励没领取=打开结算界面
                self._Control:SetSettleParam(false)
                XLuaUiManager.Open("UiRaceFightPredictSettlement", nil)
            else
                XLuaUiManager.Open("UiRaceProjectChose")
            end
        end)
    else
        XLuaUiManager.Open("UiRaceProjectChose")
    end
end

function XUiRaceMain:OnBtnPredictOneClick()
    local dontGainRoundId = self._Control:GetDontViewedRoundId()
    if dontGainRoundId then
        -- 领取预测奖励
        self._Control:SetSettleParam(false)
        XLuaUiManager.Open("UiRaceFightPredictSettlement", dontGainRoundId)
        return
    end
    if self._RoundInfo.State == XEnumConst.Race.RoundState.End then
        -- 全部比赛都结束
        return
    end
    if self._RoundInfo.State == XEnumConst.Race.RoundState.InProgress then
        -- 比赛进行中
        local roundId = self._Control:GetCurRound()
        self._Control:EnterGame(roundId, XEnumConst.Race.GameMode.LiveStream)
        return
    end
    self._Control:RequestCurRoundSupportRate(function()
        XLuaUiManager.Open("UiRacePredict")
    end)
end

function XUiRaceMain:OnBtnRankClick()
    XLuaUiManager.Open("UiRaceRank")
end

function XUiRaceMain:OnBtnShopClick()
    XLuaUiManager.Open("UiRaceMissionShop")
end

function XUiRaceMain:OnBtnSkinClick()
    XLuaUiManager.OpenWithCloseCallback("UiRacePopupSkin", function()
        self:UpdateSkinBtn()
    end)
end

function XUiRaceMain:ShowRedPoint()
    local isMatchRed = XMVCA.XRace:CheckMatchGuessRedpoint()
    self.BtnPredictAll:ShowReddot(isMatchRed)

    local isTaskRed = XMVCA.XRace:CheckTaskRedPoint()
    self.BtnShop:ShowReddot(isTaskRed)

    local isRoundRed = XMVCA.XRace:CheckRoundGuessRedPoint()
    self.BtnPredictOne:ShowReddot(isRoundRed)
end

function XUiRaceMain:ShowSkinPopup()
    if self._Control:IsGainSkinReward() or not self._Control:CheckShowSkinPopup() then
        return
    end
    self:OnBtnSkinClick()
end

function XUiRaceMain:PlayPlatformDown()
    local platform = self.UiSceneInfo.Transform:FindTransform("Racing_BanjiangtaiAni")
    if XTool.UObjIsNil(platform) then
        return
    end
    ---@type UnityEngine.Animator
    local animator = platform:GetComponent(typeof(CS.UnityEngine.Animator))
    if XTool.UObjIsNil(animator) then
        return
    end
    animator:Play("FloorDownLoop")
end

return XUiRaceMain