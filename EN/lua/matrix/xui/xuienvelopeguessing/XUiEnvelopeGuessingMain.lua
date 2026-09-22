local XUiPanelEnvelopeGuessingInstrument = require("XUi/XUiEnvelopeGuessing/XUiPanelEnvelopeGuessingInstrument")
local XUiPanelEnvelopeGuessingMusicianChoose = require("XUi/XUiEnvelopeGuessing/XUiPanelEnvelopeGuessingMusicianChoose")

--region 埋点
-- 离开主界面时的交互按钮类型
local ReportExitType = {
    Other = 0, -- 其他
    Back = 1, -- 返回
    MainUi = 2, -- 主干界面
    Collection = 3, -- 图鉴
    Task = 4, -- 任务
    Invitation = 5, -- 邀请
}

-- 停留时长不足该秒数不上报
local REPORT_MIN_STAY_SECONDS = 3
-- 固定上报的乐器数量
local REPORT_INSTRUMENT_COUNT = 4
--endregion

-- 特殊角色模型对应的动画控制器
local SPECIAL_CONTROLLER = {
    ["QR4LuosaitaMd010011TX"] = "EnvelopeGuessingControllerLuosaita",
    ["QR3CibeizheMd010011TX"] = "EnvelopeGuessingControllerCibeizhe",
    ["QR3HelentineMd010011TX"] = "EnvelopeGuessingControllerHelentine",
}

---@class XUiEnvelopeGuessingMain : XLuaUi
---@field private _Control XEnvelopeGuessingControl
---@field private _Instruments table<number, XUiPanelEnvelopeGuessingInstrument>
local XUiEnvelopeGuessingMain = XLuaUiManager.Register(XLuaUi, "UiEnvelopeGuessingMain")

function XUiEnvelopeGuessingMain:OnStart(rewardGoodsList, taskRewardGoodsList)
    self:_RegisterButtons()
    local activityConf = XMVCA.XEnvelopeGuessing:GetActivityConfig()
    self:_InitInstruments()
    self:_InitShowRewards(activityConf)
    -- 资产面板
    XUiHelper.XUiPanelAsset(self, self.PanelAsset1, activityConf.TicketItemId, activityConf.SelectChoiceItemId)
    -- 设置自动关闭
    self.EndTime = XFunctionManager.GetEndTimeByTimeId(activityConf.TimeId)
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        else
            self:RefreshTime()
        end
    end)

    if not self._IsResume then
        self:_CheckEnterRewards(rewardGoodsList, taskRewardGoodsList)
    end
end

--region 初始化
function XUiEnvelopeGuessingMain:_InitShowRewards(activityConf)
    local rewardList = XRewardManager.GetRewardList(activityConf.ShowRewardId)
    if XTool.IsTableEmpty(rewardList) then
        self.Grid256New.gameObject:SetActiveEx(false)
        return
    end

    self._GridShowRewards = {}
    XUiHelper.RefreshCustomizedList(self.Grid256New.parent, self.Grid256New, #rewardList, function(index, go)
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

    self._BtnCloseInstrumentMusicianChoosePanel:AddEventListener(handler(self, self._CloseInstrumentMusicianChoosePanel))

    self._Instruments = {}

    local openInstrumentMusicianChoosePanel = handler(self, self._OnBtnInstrumentMusician)

    local threeDSceneUiObject = self.UiModel:GetComponent("UiObject")
    local threeDSceneUiObjects = {}
    XTool.InitUiObjectByInstance(threeDSceneUiObject, threeDSceneUiObjects)

    local loadAnimationController = handler(self, self._LoadCharacterAnimationController)

    for _, instrumentConf in pairs(self._Control:GetAllInstruments()) do
        local instName = "Instrument" .. instrumentConf.Id
        local panelGo = instruments[instName]
        panelGo.gameObject:SetActiveEx(true)
        self._Instruments[instrumentConf.Id] = XUiPanelEnvelopeGuessingInstrument.New(panelGo, self, instrumentConf, openInstrumentMusicianChoosePanel,
            threeDSceneUiObjects[instName], threeDSceneUiObjects.UiNearCamera, self.Name, loadAnimationController)
    end

    -- 播放场景镜头动画
    threeDSceneUiObjects.AnimStart.gameObject:PlayTimelineAnimation()
end

function XUiEnvelopeGuessingMain:_LoadCharacterAnimationController(isFemale, modelId)
    -- 优先根据modelId获取特殊角色的动画控制器，没有再按性别使用默认
    local pathKey = SPECIAL_CONTROLLER[modelId]
    if not pathKey then
        pathKey = isFemale and "EnvelopeGuessingCharacterAnimationControllerFemale" or "EnvelopeGuessingCharacterAnimationControllerMale"
    end
    return pathKey
end

function XUiEnvelopeGuessingMain:_CloseInstrumentMusicianChoosePanel()
    if XTool.UObjIsNil(self._MusicianChoosePanelContainer) then
        return
    end
    self._MusicianChoosePanel:Close()
    self._MusicianChoosePanelContainer.gameObject:SetActiveEx(false)
    self._BtnCloseInstrumentMusicianChoosePanel.gameObject:SetActiveEx(false)
    self._MusicianChoosePanelContainer = nil
end

function XUiEnvelopeGuessingMain:_OpenInstrumentMusicianChoosePanel(instrumentConfig, choosePanelContainer)
    if XTool.UObjIsNil(choosePanelContainer) then
        return
    end

    self._MusicianChoosePanelContainer = choosePanelContainer
    choosePanelContainer.gameObject:SetActiveEx(true)
    self._BtnCloseInstrumentMusicianChoosePanel.gameObject:SetActiveEx(true)
    self._UiEnvelopeGuessingPanelChoose.transform:SetParent(choosePanelContainer)
    self._UiEnvelopeGuessingPanelChoose.localPosition = Vector3.zero

    if not self._MusicianChoosePanel then
        ---@type XUiPanelEnvelopeGuessingMusicianChoose
        self._MusicianChoosePanel = XUiPanelEnvelopeGuessingMusicianChoose.New(self._UiEnvelopeGuessingPanelChoose, self, function(instId, ...)
            self._Instruments[instId]:Refresh(...)
        end, handler(self, self._CloseInstrumentMusicianChoosePanel))
    end

    self._MusicianChoosePanel:Open()
    self._MusicianChoosePanel:Reset(instrumentConfig)
end

function XUiEnvelopeGuessingMain:_OnBtnInstrumentMusician(instrumentConfig, choosePanelContainer)
    if choosePanelContainer == self._MusicianChoosePanelContainer then
        self:_CloseInstrumentMusicianChoosePanel()
    elseif self._MusicianChoosePanelContainer then
        self:_CloseInstrumentMusicianChoosePanel()
        self:_OpenInstrumentMusicianChoosePanel(instrumentConfig, choosePanelContainer)
    else
        self:_OpenInstrumentMusicianChoosePanel(instrumentConfig, choosePanelContainer)
    end
end
--endregion

function XUiEnvelopeGuessingMain:OnEnable()
    self:_Refresh()
    self._ReportStayStartTime = CS.UnityEngine.Time.realtimeSinceStartup
end

function XUiEnvelopeGuessingMain:OnDestroy()
    self:_ReportStay(ReportExitType.Other)
end

function XUiEnvelopeGuessingMain:OnGetLuaEvents()
    return {
        XEventId.EVENT_DAILY_RESET,
        XEventId.EVENT_ENVELOPE_UPDATE_DATA,
        XEventId.EVENT_FINISH_TASK,
        XEventId.EVENT_TASK_SYNC,
    }
end

function XUiEnvelopeGuessingMain:OnNotify(event, ...)
    if event == XEventId.EVENT_DAILY_RESET or event == XEventId.EVENT_ENVELOPE_UPDATE_DATA then
        self:_Refresh()
    elseif event == XEventId.EVENT_FINISH_TASK or event == XEventId.EVENT_TASK_SYNC then
        self.BtnTask:ShowReddot(XMVCA.XEnvelopeGuessing:HasAnyAchievedTask())
    end
end

function XUiEnvelopeGuessingMain:OnResume()
    self._IsResume = true
end

function XUiEnvelopeGuessingMain:_Refresh()
    self:RefreshTime()
    -- 刷新已解锁角色数量
    local allCharConf = self._Control:GetAllCharacterConfigs()
    local unlockedCharacters = self._Control:GetOpenedCharacterCount()
    self.BtnCollection:SetNameByGroup(0, string.format("%s/%s", unlockedCharacters, #allCharConf))
    -- 刷新邀请按钮状态
    if self._Control:IsAllCharactersOpened() then
        self.BtnInvitation:SetButtonState(CS.UiButtonState.Disable)
    else
        self.BtnInvitation:SetButtonState(CS.UiButtonState.Normal)
    end
    -- 刷新乐器状态
    local prev, cur = self._Control:UpdatePrevOpenedCharacterCount()
    for _, inst in pairs(self._Instruments) do
        -- 必须先刷新解锁状态：Refresh 内部依赖 _Unlocked 选择乐器模型
        inst:SetUnlockState(prev, cur)
        inst:Refresh()
    end
    -- 刷新任务红点
    self.BtnTask:ShowReddot(XMVCA.XEnvelopeGuessing:HasAnyAchievedTask())
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
    self.BtnBack:AddEventListener(handler(self, self._OnBtnBackClicked))
    self.BtnMainUi:AddEventListener(handler(self, self._OnBtnMainUiClicked))
    self.BtnTask:AddEventListener(handler(self, self._OnBtnTaskClicked))
    self.BtnCollection:AddEventListener(handler(self, self._OnBtnCollectionClicked))
    self.BtnInvitation:AddEventListener(handler(self, self._OnBtnInvitationClicked))
    self:BindHelpBtn(self.BtnHelp, "EnvelopeGuessingHelp")
end

function XUiEnvelopeGuessingMain:_OnBtnBackClicked()
    self:_ReportStay(ReportExitType.Back)
    self:Close()
end

function XUiEnvelopeGuessingMain:_OnBtnMainUiClicked()
    self:_ReportStay(ReportExitType.MainUi)
    XLuaUiManager.RunMain()
end

function XUiEnvelopeGuessingMain:_OnBtnCollectionClicked()
    self:_ReportStay(ReportExitType.Collection)
    XLuaUiManager.Open("UiEnvelopeGuessingCollection")
end

function XUiEnvelopeGuessingMain:_OnBtnInvitationClicked()
    if self._Control:IsAllCharactersOpened() then
        XUiManager.TipText("EnvelopeGuessingMainUiAllCharactersAlreadyOpened")
    else
        self:_ReportStay(ReportExitType.Invitation)
        XLuaUiManager.Open("UiEnvelopeGuessingInvitation")
    end
end

function XUiEnvelopeGuessingMain:_OnBtnTaskClicked()
    self:_ReportStay(ReportExitType.Task)
    XLuaUiManager.Open("UiEnvelopeGuessingTask")
end

function XUiEnvelopeGuessingMain:_CheckEnterRewards(rewardGoodsList, taskRewardGoodsList)
    if not XTool.IsTableEmpty(rewardGoodsList) or not XTool.IsTableEmpty(taskRewardGoodsList) then
        XLuaUiManager.Open("UiEnvelopeGuessingReward", rewardGoodsList, taskRewardGoodsList)
    end
end

--region 埋点
-- 上报本次停留的乐器状态、停留时长与离开方式
function XUiEnvelopeGuessingMain:_ReportStay(exitType)
    if not self._ReportStayStartTime then
        return
    end

    local duration = math.floor(CS.UnityEngine.Time.realtimeSinceStartup - self._ReportStayStartTime)
    self._ReportStayStartTime = nil

    -- 仅上报停留时长达到阈值的记录
    if duration < REPORT_MIN_STAY_SECONDS then
        return
    end

    local dict = {}
    dict["role_id"] = XPlayer.Id
    dict["i_stay_duration"] = duration
    dict["i_exit_type"] = exitType

    -- 按配表Id升序，保证「乐器N」与配表顺序稳定对应
    ---@type XTableEnvelopeInstrument[]
    local instrumentConfigs = {}
    for _, conf in pairs(self._Control:GetAllInstruments()) do
        table.insert(instrumentConfigs, conf)
    end
    table.sort(instrumentConfigs, function(a, b)
        return a.Id < b.Id
    end)

    local openedCount = self._Control:GetOpenedCharacterCount()
    for i = 1, REPORT_INSTRUMENT_COUNT do
        local conf = instrumentConfigs[i]
        local unlock = 0
        local characterId = 0
        if conf then
            unlock = openedCount >= conf.OpenTarget and 1 or 0
            characterId = self._Control:GetInstrumentBinding(conf.Id) or 0
        end
        dict["i_instrument" .. i .. "_unlock"] = unlock
        dict["i_instrument" .. i .. "_character"] = characterId
    end

    if XMain.IsWindowsEditor then
        CS.XRecord.RecordTest(dict, "1000048", "EnvelopeGuessingMain")
    else
        CS.XRecord.Record(dict, "1000048", "EnvelopeGuessingMain")
    end
end
--endregion

return XUiEnvelopeGuessingMain
