local XUiPanelEnvelopeGuessingInstrument =
    require("XUi/XUiEnvelopeGuessing/XUiPanelEnvelopeGuessingInstrument")

local XUiPanelEnvelopeGuessingMusicianChoose =
    require("XUi/XUiEnvelopeGuessing/XUiPanelEnvelopeGuessingMusicianChoose")

local UiName = "UiEnvelopeGuessingMain"

---@class XUiEnvelopeGuessingMain : XLuaUi
---@field _Control XEnvelopeGuessingControl

local XUiEnvelopeGuessingMain = XLuaUiManager.Register(
    XLuaUi, UiName)

function XUiEnvelopeGuessingMain:OnStart()
    self._Agency = XMVCA.XEnvelopeGuessing
    self:_RegisterButtons()

    local activityConf = self._Agency:GetCurrentActivity()

    if activityConf then
        self._ActivityId = activityConf.Id
    end

    if self:_CloseUiIfActivityOver(activityConf) then
        return
    end

    self:_InitInstruments()
    self:_InitShowRewards(activityConf)

    XUiHelper.XUiPanelAsset(
        self,
        self.PanelAsset1,
        activityConf.TicketItemId,
        activityConf.SelectChoiceItemId)

    self:_InitAutoRefreshTime(activityConf)
end

function XUiEnvelopeGuessingMain:_InitAutoRefreshTime(activityConf)
    self.EndTime = XFunctionManager.GetEndTimeByTimeId(activityConf.TimeId)
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if not isClose then
            self:RefreshTime()
        end
    end)
end

function XUiEnvelopeGuessingMain:_InitShowRewards(activityConf)
    local rewardList = XRewardManager.GetRewardList(activityConf.ShowRewardId)
    if XTool.IsTableEmpty(rewardList) then
        self.Grid256New.gameObject:SetActiveEx(false)
        return
    end

    self._GridShowRewards = {}

    XUiHelper.RefreshCustomizedList(
        self.Grid256New.parent,
        self.Grid256New,
        #rewardList,
        function(index, go)
            local grid = self._GridShowRewards[go]
            if not grid then
                grid = XUiHelper.XUiGridCommon(self, go)
                self._GridShowRewards[go] = grid
            end
            grid:Refresh(rewardList[index])
        end)
end

function XUiEnvelopeGuessingMain:_InitInstruments()
    local instruments = {}
    XTool.InitUiObjectByInstance(self.Instruments, instruments)

    self._BtnCloseInstrumentMusicianChoosePanel = instruments.BtnClose
    self._UiEnvelopeGuessingPanelChoose = instruments.UiEnvelopeGuessingPanelChoose

    self._BtnCloseInstrumentMusicianChoosePanel.CallBack = handler(
        self, self._CloseInstrumentMusicianChoosePanel)

    self._Instruments = {}

    local openInstrumentMusicianChoosePanel = handler(
        self, self._OnBtnInstrumentMusician)

    local threeDSceneUiObject = self.UiModel:GetComponent("UiObject")
    local threeDSceneUiObjects = {}

    XTool.InitUiObjectByInstance(
        threeDSceneUiObject,
        threeDSceneUiObjects)

    local loadAnimationController = handler(
        self, self._LoadCharacterAnimationController)

    for _, instrumentConf in pairs(self._Control:GetAllInstruments()) do
        local instName = "Instrument" .. instrumentConf.Id
        local panelGo = instruments[instName]
        panelGo.gameObject:SetActiveEx(true)
        self._Instruments[instrumentConf.Id] =
            XUiPanelEnvelopeGuessingInstrument.New(
                panelGo,
                self,
                instrumentConf,
                openInstrumentMusicianChoosePanel,
                threeDSceneUiObjects[instName],
                threeDSceneUiObjects.UiNearCamera,
                UiName,
                loadAnimationController)
    end
end

function XUiEnvelopeGuessingMain:_LoadCharacterAnimationController(isFemale)
    if not self._AnimationControllerCache then
        self._AnimationControllerCache = {}
    end

    local cached = self._AnimationControllerCache[isFemale]

    if not cached then
        local pathKey
        local lifeTimeBoundGameObject   -- Controller绑定生命周期的GameObject
        if isFemale then
            pathKey = "EnvelopeGuessingCharacterAnimationControllerFemale"
            lifeTimeBoundGameObject = self.GameObject
        else
            pathKey = "EnvelopeGuessingCharacterAnimationControllerMale"
            lifeTimeBoundGameObject = self.PanelAsset1.gameObject   -- 没有必要专门建个GameObject来存生命周期，直接随便找个已有的
        end

        cached = CS.LoadHelper.LoadUiController(
            CS.XGame.ClientConfig:GetString(pathKey),
            lifeTimeBoundGameObject)

        self._AnimationControllerCache[isFemale] = cached
    end

    return cached
end

function XUiEnvelopeGuessingMain:_CloseInstrumentMusicianChoosePanel()
    assert(self._MusicianChoosePanelContainer)
    self._MusicianChoosePanel:Close()
    self._MusicianChoosePanelContainer.gameObject:SetActiveEx(false)
    self._BtnCloseInstrumentMusicianChoosePanel.gameObject:SetActiveEx(false)
    self._MusicianChoosePanelContainer = nil
end

function XUiEnvelopeGuessingMain:_OpenInstrumentMusicianChoosePanel(
    instrumentConfig,
    choosePanelContainer)

    assert(not self._MusicianChoosePanelContainer)

    self._MusicianChoosePanelContainer = choosePanelContainer
    choosePanelContainer.gameObject:SetActiveEx(true)
    self._BtnCloseInstrumentMusicianChoosePanel.gameObject:SetActiveEx(true)
    self._UiEnvelopeGuessingPanelChoose.transform:SetParent(choosePanelContainer)
    self._UiEnvelopeGuessingPanelChoose.localPosition = Vector3.zero

    if not self._MusicianChoosePanel then
        self._MusicianChoosePanel = XUiPanelEnvelopeGuessingMusicianChoose.New(
            self._UiEnvelopeGuessingPanelChoose,
            self,
            function(instId, ...) self._Instruments[instId]:Refresh(...) end,
            handler(self, self._CloseInstrumentMusicianChoosePanel))
    end

    self._MusicianChoosePanel:Open()
    self._MusicianChoosePanel:Reset(instrumentConfig)
end

function XUiEnvelopeGuessingMain:_OnBtnInstrumentMusician(
    instrumentConfig,
    choosePanelContainer)

    if choosePanelContainer == self._MusicianChoosePanelContainer then
        self:_CloseInstrumentMusicianChoosePanel()
    elseif self._MusicianChoosePanelContainer then
        self:_CloseInstrumentMusicianChoosePanel()
        self:_OpenInstrumentMusicianChoosePanel(
            instrumentConfig,
            choosePanelContainer)
    else
        self:_OpenInstrumentMusicianChoosePanel(
            instrumentConfig,
            choosePanelContainer)
    end
end

function XUiEnvelopeGuessingMain:OnEnable()
    self:_Refresh(function()
        assert(not self._ListenersSetup)
        self._ListenersSetup = true

        XMVCA.XEnvelopeGuessing:AddEventListener(
            XMVCA.XEnvelopeGuessing.EventIds.EVENT_ON_NOTIFY_ENVELOPE,
            self._Refresh, self)

        XEventManager.AddEventListener(
            XEventId.EVENT_DAILY_RESET,
            self._Refresh, self)
    end)
end

function XUiEnvelopeGuessingMain:OnDisable()
    if self._ListenersSetup then
        XMVCA.XEnvelopeGuessing:RemoveEventListener(
            XMVCA.XEnvelopeGuessing.EventIds.EVENT_ON_NOTIFY_ENVELOPE,
            self._Refresh, self)

        XEventManager.RemoveEventListener(
            XEventId.EVENT_DAILY_RESET,
            self._Refresh, self)

        self._ListenersSetup = false
    end
end

function XUiEnvelopeGuessingMain:_CloseUiIfActivityOver(activityConf)
    if not activityConf or activityConf.Id ~= self._ActivityId then
        self:Close()
        XUiManager.TipText("ActivityAlreadyOver")
        return true
    end

    return false
end

function XUiEnvelopeGuessingMain:_Refresh(continuation)
    local activityConf = self._Agency:GetCurrentActivity()

    if not self:_CloseUiIfActivityOver(activityConf) then
        self.BtnTask:ShowReddot(
            XMVCA.XEnvelopeGuessing:HasAnyAchievedTask())

        self:RefreshTime()

        XLuaUiManager.SetMask(true)

        self:_RequestEnterRewards(
            function()
                if continuation then continuation() end
                XLuaUiManager.SetMask(false)

                local allCharConf = self._Control:GetAllCharacterConfigs()
                local unlockedCharacters = self._Control:GetOpenedCharacterCount()
                self.BtnCollection:SetNameByGroup(0, string.format("%s/%s", unlockedCharacters, #allCharConf))

                if self._Control:IsAllCharactersOpened() then
                    self.BtnInvitation:SetButtonState(CS.UiButtonState.Disable)
                else
                    self.BtnInvitation:SetButtonState(CS.UiButtonState.Normal)
                end

                for _, inst in pairs(self._Instruments) do
                    inst:Refresh()
                end

                self.BtnTask:ShowReddot(
                    XMVCA.XEnvelopeGuessing:HasAnyAchievedTask())
            end,
            function()
                local prev, cur =
                    self._Control:UpdatePrevOpenedCharacterCount()

                for _, inst in pairs(self._Instruments) do
                    inst:SetUnlockState(prev, cur)
                end
            end)
    end
end

function XUiEnvelopeGuessingMain:RefreshTime()
    if XTool.UObjIsNil(self.TxtTime) then
        return
    end
    local timeLeft = self.EndTime - XTime.GetServerNowTimestamp()
    if timeLeft < 0 then
        timeLeft = 0
    end
    self.TxtTime.text = XUiHelper.GetTime(timeLeft, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiEnvelopeGuessingMain:_RegisterButtons()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self.BtnTask.CallBack = handler(self, self._OnBtnTaskClicked)
    self.BtnCollection.CallBack = handler(self, self._OnBtnCollectionClicked)
    self.BtnInvitation.CallBack = handler(self, self._OnBtnInvitationClicked)
    self:BindHelpBtn(self.BtnHelp, "EnvelopeGuessingHelp")
end

function XUiEnvelopeGuessingMain:_OnBtnCollectionClicked()
    XLuaUiManager.Open("UiEnvelopeGuessingCollection")
end

function XUiEnvelopeGuessingMain:_OnBtnInvitationClicked()
    if self._Control:IsAllCharactersOpened() then
        XUiManager.TipText("EnvelopeGuessingMainUiAllCharactersAlreadyOpened")
    else
        XLuaUiManager.Open("UiEnvelopeGuessingInvitation")
    end
end

function XUiEnvelopeGuessingMain:_OnBtnTaskClicked()
    XLuaUiManager.Open("UiEnvelopeGuessingTask")
end

function XUiEnvelopeGuessingMain:_RequestEnterRewards(
    cbAlways,
    cbAfterClosePopups)

    self._Control:EnvelopeEnterRequest(function(data)
        if cbAlways then cbAlways() end

        if data.Code ~= XCode.Success then
            XUiManager.TipCode(data.Code)
            self:Close()
            return
        end

        if not XTool.IsTableEmpty(data.RewardGoodsList)
            or not XTool.IsTableEmpty(data.TaskRewardGoodsList) then

            XLuaUiManager.Open(
                "UiEnvelopeGuessingReward",
                data,
                self._Agency:GetCurrentActivity(),
                cbAfterClosePopups)
        else
            if cbAfterClosePopups then cbAfterClosePopups() end
        end
    end)
end

return XUiEnvelopeGuessingMain
