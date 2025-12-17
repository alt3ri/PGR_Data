---@class XUiDlcRelinkMain : XLuaUi
---@field private _Control XDlcRelinkControl
---@field VideoPlayer XVideoPlayerUGUI
---@field BtnEnter XUiComponent.XUiButton
local XUiDlcRelinkMain = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkMain")

function XUiDlcRelinkMain:OnAwake()
    self:RegisterUiEvents()
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ XDataCenter.ItemManager.ItemId.DlcRelinkCoin }, self.PanelSpecialTool, self)
end

function XUiDlcRelinkMain:OnStart()
    self.EndTime = self._Control:GetActivityEndTime()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        else
            self:RefreshTime()
        end
    end)
    self.IsPaused = false
    self.Tips = self._Control:GetActivityTips()
    self.TipSwitchInterval = tonumber(self._Control:GetClientConfig("MainTipsSwitchInterval"))
    self.CurrentTipIndex = -1
    self:InitVideo()
    -- TODO 战斗初始化，先临时放在这里，后续等战斗那边优化后在调整。
    XMVCA.XDlcRelink:DlcInitFight()
end

function XUiDlcRelinkMain:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshTime()
    self:RefreshName()
    self:StartTipsTimer()
    self:PlayVideo()
    self:RefreshBtnEnter()
end

function XUiDlcRelinkMain:OnDisable()
    self.Super.OnDisable(self)
    self:StopTipsTimer()
    self:StopVideo()
end

function XUiDlcRelinkMain:InitVideo()
    local videoUrl = self._Control:GetActivityVideoUrl()
    if string.IsNilOrEmpty(videoUrl) then
        self.VideoPlayer.gameObject:SetActiveEx(false)
        return
    end
    self.VideoPlayer.gameObject:SetActiveEx(true)
    self.VideoPlayer:SetVideoFromRelateUrl(videoUrl)
end

function XUiDlcRelinkMain:RefreshName()
    self.TxtTitle.text = self._Control:GetActivityName()
end

function XUiDlcRelinkMain:RefreshTime()
    if XTool.UObjIsNil(self.TxtTime) then
        return
    end
    local timeLeft = self.EndTime - XTime.GetServerNowTimestamp()
    if timeLeft < 0 then
        timeLeft = 0
    end
    local timeStr = XUiHelper.GetTime(timeLeft, XUiHelper.TimeFormatType.ESCAPE_REMAIN_TIME)
    self.TxtTime.text = string.format(self._Control:GetClientConfig("MainCountDownDesc"), timeStr)
end

function XUiDlcRelinkMain:StartTipsTimer()
    if XTool.IsTableEmpty(self.Tips) then
        self.PanelTips.gameObject:SetActiveEx(false)
        return
    end
    self:StopTipsTimer()
    self.PanelTips.gameObject:SetActiveEx(true)
    self.TipsTimer = XScheduleManager.ScheduleForeverEx(function()
        self:RefreshTip()
    end, self.TipSwitchInterval)
end

function XUiDlcRelinkMain:RefreshTip()
    if XTool.UObjIsNil(self.TxtTips) then
        return
    end
    self.CurrentTipIndex = self:GetRandomIndex()
    self.TxtTips.text = self.Tips[self.CurrentTipIndex]
end

function XUiDlcRelinkMain:StopTipsTimer()
    if self.TipsTimer then
        XScheduleManager.UnSchedule(self.TipsTimer)
        self.TipsTimer = nil
    end
    self.CurrentTipIndex = -1
end

function XUiDlcRelinkMain:GetRandomIndex()
    local totalTips = #self.Tips
    if totalTips <= 1 then
        return 1
    end
    local idx = math.random(1, totalTips)
    if idx == self.CurrentTipIndex then
        idx = idx % totalTips + 1
    end
    return idx
end

function XUiDlcRelinkMain:PlayVideo()
    if self.IsPaused then
        self.VideoPlayer:RePlay()
        self.IsPaused = false
    else
        self.VideoPlayer:Play()
    end
end

function XUiDlcRelinkMain:StopVideo()
    self.VideoPlayer:Pause()
    self.IsPaused = true
end

function XUiDlcRelinkMain:RefreshBtnEnter()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    self.BtnEnter:SetNameByGroup(0, self._Control:GetClientConfig("MainBtnEnterDesc", isInRoom and 2 or 1))
end

function XUiDlcRelinkMain:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:RegisterClickEvent(self.BtnRank, self.OnBtnRankClick)
    self:RegisterClickEvent(self.BtnEnter, self.OnBtnEnterClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiDlcRelinkMain:OnBtnBackClick()
    if XMVCA.XDlcRoom:IsInRoom() then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        if not team then
            self:Close()
            return
        end
        if team:GetMemberAmount() == 1 then
            XMVCA.XDlcRoom:Quit(function() self:Close() end)
        else
            XMVCA.XDlcRoom:DialogTipQuit(function() self:Close() end)
        end
        return
    end

    if XMVCA.XDlcRoom:IsMatching() then
        XMVCA.XDlcRoom:DialogTipCancelMatch(function() self:Close() end)
    else
        self:Close()
    end
end

function XUiDlcRelinkMain:OnBtnMainUiClick()
    local isNotDialogTip = true
    if XMVCA.XDlcRoom:IsInRoom() then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        if team then
            isNotDialogTip = team:GetMemberAmount() == 1
        end
    else
        if XMVCA.XDlcRoom:IsMatching() then
            isNotDialogTip = false
        end
    end
    XLuaUiManager.RunMain(isNotDialogTip)
end

function XUiDlcRelinkMain:OnBtnTaskClick()
end

function XUiDlcRelinkMain:OnBtnRankClick()
end

function XUiDlcRelinkMain:OnBtnEnterClick()
    XLuaUiManager.Open("UiDlcRelinkRoom")
end

return XUiDlcRelinkMain
