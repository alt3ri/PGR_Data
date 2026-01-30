local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiDlcRelinkMain : XLuaUi
---@field private _Control XDlcRelinkControl
---@field VideoPlayer XVideoPlayerUGUI
---@field BtnEnter XUiComponent.XUiButton
local XUiDlcRelinkMain = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkMain")

function XUiDlcRelinkMain:OnAwake()
    self:RegisterUiEvents()
    self.GridReward.gameObject:SetActiveEx(false)

    local itemIds = { XDataCenter.ItemManager.ItemId.DlcRelinkStoreCoin }
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self, nil, function(data, index)
        local itemId = itemIds[index]
        XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", itemId)
    end)
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
    self.Tips = self._Control:GetActivityTips()
    self.TipSwitchInterval = tonumber(self._Control:GetClientConfig("MainTipsSwitchInterval"))
    self.CurrentTipIndex = -1
    self:InitRewardPreview()
    self:GlobalMatchAutoSendHandle()
    -- TODO 战斗初始化，先临时放在这里，后续等战斗那边优化后在调整。
    XMVCA.XDlcRelink:DlcInitFight()
end

function XUiDlcRelinkMain:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshTime()
    self:StartTipsTimer()
    self:PlayVideo()
    self:RefreshBtnEnter()
    self:RefreshBtnTask()
    self:RefreshBtnBox()
    self._Control:OnReceiveInvite()
end

function XUiDlcRelinkMain:OnDisable()
    self.Super.OnDisable(self)
    self:StopTipsTimer()
    self:StopVideo()
end

function XUiDlcRelinkMain:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_ROOM_KICKOUT,
        XEventId.EVENT_DLC_RELINK_DAILY_RESET,
    }
end

function XUiDlcRelinkMain:OnNotify(event, ...)
    if event == XEventId.EVENT_DLC_ROOM_KICKOUT then
        self:RefreshBtnEnter()
    elseif event == XEventId.EVENT_DLC_RELINK_DAILY_RESET then
        self:RefreshBtnBox()
    end
end

function XUiDlcRelinkMain:InitRewardPreview()
    local rewardId = tonumber(self._Control:GetClientConfig("MainPreviewRewardId"))
    if not XTool.IsNumberValid(rewardId) then
        self.PanelReward.gameObject:SetActiveEx(false)
        return
    end

    self.PanelReward.gameObject:SetActiveEx(true)
    local rewardList = XRewardManager.GetRewardList(rewardId)
    local rewardCount = #rewardList
    for i = 1, rewardCount do
        local go = XUiHelper.Instantiate(self.GridReward, self.PanelReward)
        ---@type XUiGridCommon
        local grid = XUiGridCommon.New(self, go)
        grid:Refresh(rewardList[i])
        grid:SetProxyClickFunc(function()
            XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", grid.TemplateId)
        end)
        grid.GameObject:SetActiveEx(true)
    end
end

function XUiDlcRelinkMain:RefreshTime()
    if XTool.UObjIsNil(self.TxtTime) then
        return
    end
    local timeLeft = self.EndTime - XTime.GetServerNowTimestamp()
    if timeLeft < 0 then
        timeLeft = 0
    end
    local timeStr = XUiHelper.GetTime(timeLeft, XUiHelper.TimeFormatType.DEFAULT)
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
    local videoConfigId = self._Control:GetActivityVideoConfigId()
    if not XTool.IsNumberValid(videoConfigId) then
        self.VideoPlayer.gameObject:SetActiveEx(false)
        return
    end
    self.VideoPlayer.gameObject:SetActiveEx(true)
    self.VideoPlayer:SetInfoByVideoId(videoConfigId)
    self.VideoPlayer:RePlay()
end

function XUiDlcRelinkMain:StopVideo()
    if self.VideoPlayer then
        self.VideoPlayer:Stop()
        self.VideoPlayer.gameObject:SetActiveEx(false)
    end
end

function XUiDlcRelinkMain:RefreshBtnEnter()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    self.BtnEnter:SetNameByGroup(0, self._Control:GetClientConfig("MainBtnEnterDesc", isInRoom and 2 or 1))
end

function XUiDlcRelinkMain:RefreshBtnTask()
    local taskId = self._Control:GetFirstUnCompleteTaskId()
    local isValid = XTool.IsNumberValid(taskId)
    self.BtnTask:SetDisable(not isValid)
    if isValid then
        local taskConfig = XDataCenter.TaskManager.GetTaskTemplate(taskId)
        self.BtnTask:SetNameByGroup(0, taskConfig and taskConfig.Desc or "")
    end
    -- 红点
    local isShowRedPoint = XMVCA.XDlcRelink:CheckAllTaskRedPoint()
    self.BtnTask:ShowReddot(isShowRedPoint)
end

function XUiDlcRelinkMain:RefreshBtnBox()
    local isSign = self._Control:CheckDailySign()
    self.BtnBox:ShowReddot(not isSign)
    self.IconBox.gameObject:SetActiveEx(not isSign)
end

-- 全局匹配自动发送处理
function XUiDlcRelinkMain:GlobalMatchAutoSendHandle()
    if XMVCA.XDlcRoom:IsInRoom() or XMVCA.XDlcRoom:IsMatching() then
        return
    end
    if not self._Control:CheckGlobalMatchEnableCondition() then
        return
    end
    self._Control:RequestSwitchGlobalMatchFlag(self._Control:IsGlobalMatchEnabled())
end

function XUiDlcRelinkMain:RegisterUiEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))
    self.BtnTask:AddEventListener(handler(self, self.OnBtnTaskClick))
    self.BtnRank:AddEventListener(handler(self, self.OnBtnRankClick))
    self.BtnEnter:AddEventListener(handler(self, self.OnBtnEnterClick))
    self.BtnBox:AddEventListener(handler(self, self.OnBtnBoxClick))
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
    self._Control:CommonRunMainUiHandle()
end

function XUiDlcRelinkMain:OnBtnTaskClick()
    XLuaUiManager.Open("UiDlcRelinkLvReward")
end

function XUiDlcRelinkMain:OnBtnRankClick()
    XLuaUiManager.Open("UiDlcRelinkRank")
end

function XUiDlcRelinkMain:OnBtnEnterClick()
    XLuaUiManager.Open("UiDlcRelinkRoom")
end

function XUiDlcRelinkMain:OnBtnBoxClick()
    if self._Control:CheckDailySign() then
        return
    end
    self._Control:RequestSign(function(rewardList)
        self:RefreshBtnBox()
        if XTool.IsTableEmpty(rewardList) then
            return
        end
        local rewardGoodsList = {}
        local equipUidList = {}
        for _, reward in ipairs(rewardList) do
            if not XTool.IsTableEmpty(reward.RewardGoods) then
                table.insert(rewardGoodsList, reward.RewardGoods)
            end
            if XTool.IsNumberValid(reward.EquipUid) then
                table.insert(equipUidList, reward.EquipUid)
            end
        end
        XLuaUiManager.Open("UiDlcRelinkPopupGetReward", rewardGoodsList, equipUidList)
    end)
end

return XUiDlcRelinkMain
