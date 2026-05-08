local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridDlcRelinkMultiPlayerChar = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkMultiPlayerChar")
local XUiPanelDlcRelinkBoss = require("XUi/XUiDlcRelink/Room/Panel/XUiPanelDlcRelinkBoss")
local XUiPanelDlcRelinkGlobal = require("XUi/XUiDlcRelink/Room/Panel/XUiPanelDlcRelinkGlobal")
---@class XUiDlcRelinkRoom : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkRoom = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkRoom")

local MAX_ROLE_COUNT = 3
local MAX_CHAT_WIDTH = 450
local CHAT_SUB_LENGTH = 18
local ButtonLeftState = {
    Leave = 1,
    Create = 2,
}
local ButtonRightState = {
    Fight = 1,
    Match = 2,
    Matching = 3,
    Ready = 4,
    CancelReady = 5,
}

function XUiDlcRelinkRoom:OnAwake()
    self.GridMulitiplayerRoomChar.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self.GridDot.gameObject:SetActiveEx(false)

    self.ButtonLeftState = {
        [ButtonLeftState.Leave] = self.BtnLeave,
        [ButtonLeftState.Create] = self.BtnCreate,
    }

    self.ButtonRightState = {
        [ButtonRightState.Fight] = self.BtnFight,
        [ButtonRightState.Match] = self.BtnMatch,
        [ButtonRightState.Matching] = self.BtnMatching,
        [ButtonRightState.Ready] = self.BtnReady,
        [ButtonRightState.CancelReady] = self.BtnCancelReady,
    }

    ---@type XUiGridDlcRelinkMultiPlayerChar[]
    self.GridMultiPlayerChar = {}

    self:RegisterUiEvents()

    local itemIds = { XDataCenter.ItemManager.ItemId.DlcRelinkStoreCoin, XDataCenter.ItemManager.ItemId.DlcRelinkGameplayCoin }
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self, nil, function(data, index)
        local itemId = itemIds[index]
        XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", itemId)
    end)
end

function XUiDlcRelinkRoom:OnStart()
    self.EndTime = self._Control:GetActivityEndTime()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self.EndTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        else
            self:RefreshTime()
        end
    end)

    self:InitSceneModel()
    self:InitMultiPlayerChar()
    self:InitRewardPreview()

    if XMVCA.XDlcRoom:IsInRoom() then
        XMVCA.XDlcRoom:CancelReconnectToWorld()
    end

    self._Control:CheckNeedPopWifiTips()
    self:GlobalMatchAutoSendHandle()

    self.Tips = self._Control:GetActivityTips()
    self.TipIcons = self._Control:GetActivityTipIcons()
    self.TipSwitchInterval = tonumber(self._Control:GetClientConfig("MainTipsSwitchInterval"))
    self.CurrentTipIndex = -1
    self:InitDot()
end

function XUiDlcRelinkRoom:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshTime()
    self:StartTipsTimer()
    self:ClearTeachingLevel()
    self:RefreshMultiPlayerChar()
    self:RefreshButtonState()
    self:RefreshPanelBoss()
    self:RefreshPanelExp()
    self:RefreshBtnTask()
    self:RefreshBtnBox()
    self:CheckShowMechanismTeach()
    self._Control:OnReceiveInvite()
    XEventManager.AddEventListener(XEventId.EVENT_DLC_RELINK_TEACHING_LEVEL_PASS, self.RefreshAfterTeachingLevelPass, self)
end

function XUiDlcRelinkRoom:OnGetLuaEvents()
    return {
        XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG, -- 收到房间聊天信息
        XEventId.EVENT_DLC_ROOM_ENTER_ROOM, -- 进入房间
        XEventId.EVENT_DLC_ROOM_KICKOUT, -- 被踢出房间
        XEventId.EVENT_DLC_ROOM_REFRESH, -- 房间信息刷新
        XEventId.EVENT_DLC_ROOM_PLAYER_ENTER, -- 玩家进入房间
        XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE, -- 玩家离开房间
        XEventId.EVENT_DLC_ROOM_PLAYER_REFRESH, -- 玩家信息刷新
        XEventId.EVENT_DLC_ROOM_INFO_CHANGE, -- 房间信息变更
        XEventId.EVENT_DLC_ROOM_MATCH, -- 开始匹配
        XEventId.EVENT_DLC_ROOM_CANCEL_MATCH, -- 取消匹配
        XEventId.EVENT_DLC_ROOM_AUTO_MATCH_CHANGE, -- 自动匹配状态改变
        XEventId.EVENT_DLC_RELINK_GLOBAL_MATCH_FLAG_CHANGE, -- 全局匹配开关状态改变
        XEventId.EVENT_DLC_RELINK_DAILY_RESET, -- 每日重置
    }
end

function XUiDlcRelinkRoom:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG then
        self:OnRefreshChatMessage(args[1], args[2])
    elseif event == XEventId.EVENT_DLC_ROOM_ENTER_ROOM then
        self:OnEnterRoom()
    elseif event == XEventId.EVENT_DLC_ROOM_KICKOUT then
        self:OnKickOutRoom()
    elseif event == XEventId.EVENT_DLC_ROOM_REFRESH then
        self:OnRefreshRoom()
    elseif event == XEventId.EVENT_DLC_ROOM_PLAYER_ENTER then
        self:OnPlayerEnterRoom(args[1])
    elseif event == XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE then
        self:OnPlayerLeaveRoom(args[1])
    elseif event == XEventId.EVENT_DLC_ROOM_PLAYER_REFRESH then
        self:OnPlayerRefresh(args[1])
    elseif event == XEventId.EVENT_DLC_ROOM_INFO_CHANGE then
        self:OnRoomInfoChange(args[1], args[2])
    elseif event == XEventId.EVENT_DLC_ROOM_MATCH then
        self:OnBeginMatching()
    elseif event == XEventId.EVENT_DLC_ROOM_CANCEL_MATCH then
        self:OnCancelMatching()
    elseif event == XEventId.EVENT_DLC_ROOM_AUTO_MATCH_CHANGE then
        self:RefreshAutoMatchButton()
    elseif event == XEventId.EVENT_DLC_RELINK_GLOBAL_MATCH_FLAG_CHANGE then
        self:RefreshButtonState()
        self:RefreshPanelBoss()
    elseif event == XEventId.EVENT_DLC_RELINK_DAILY_RESET then
        self:RefreshPanelGlobal()
        self:RefreshBtnBox()
    end
end

function XUiDlcRelinkRoom:OnDisable()
    self.Super.OnDisable(self)
    self:StopTipsTimer()
    self:MarkTeachingLevel()
    XEventManager.RemoveEventListener(XEventId.EVENT_DLC_RELINK_TEACHING_LEVEL_PASS, self.RefreshAfterTeachingLevelPass, self)
end

--region 初始化

function XUiDlcRelinkRoom:InitSceneModel()
    ---@type UnityEngine.Transform
    local root = self.UiModelGo.transform
    self.PanelRoleModel1 = XUiHelper.TryGetComponent(root, "UiNearRoot/PanelRoleModel1")
    self.PanelRoleModel2 = XUiHelper.TryGetComponent(root, "UiNearRoot/PanelRoleModel2")
    self.PanelRoleModel3 = XUiHelper.TryGetComponent(root, "UiNearRoot/PanelRoleModel3")
end

function XUiDlcRelinkRoom:InitMultiPlayerChar()
    for index = 1, MAX_ROLE_COUNT do
        local roomCase = self[string.format("RoomCharCase%d", index)]
        if roomCase then
            local grid = self.GridMultiPlayerChar[index]
            if not grid then
                local go = XUiHelper.Instantiate(self.GridMulitiplayerRoomChar, roomCase)
                grid = XUiGridDlcRelinkMultiPlayerChar.New(go, self, index)
                self.GridMultiPlayerChar[index] = grid
            end
            grid.Transform:Reset()
            grid:Open()
        end
    end
end

function XUiDlcRelinkRoom:InitRewardPreview()
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

--endregion

--region 刷新

function XUiDlcRelinkRoom:RefreshTime()
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

function XUiDlcRelinkRoom:RefreshMultiPlayerChar()
    for _, grid in pairs(self.GridMultiPlayerChar) do
        if grid then
            grid:Refresh()
        end
    end
end

function XUiDlcRelinkRoom:RefreshMultiPlayerCharOnLeave()
    for _, grid in pairs(self.GridMultiPlayerChar) do
        if grid then
            grid:RefreshOnRoomLeave()
        end
    end
end

function XUiDlcRelinkRoom:RefreshMultiPlayerCharBeforeIntoRoom()
    for _, grid in pairs(self.GridMultiPlayerChar) do
        if grid then
            grid:RefreshBeforeIntoRoom()
        end
    end
end

function XUiDlcRelinkRoom:RefreshButtonState()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    local isTutorial = self._Control:IsTutorialChapter()
    local isGlobalMatch = self._Control:IsGlobalMatchEnabled()
    self:SwitchButtonLeftState(isInRoom and ButtonLeftState.Leave or ButtonLeftState.Create)
    self.BtnCreate:SetButtonState((isTutorial or isGlobalMatch) and XUiButtonState.Disable or XUiButtonState.Normal)
    if isTutorial then
        self:SwitchButtonRightState(ButtonRightState.Fight)
        self:RefreshFightButton(true)
        self.BtnOpen.gameObject:SetActiveEx(false)
    elseif isInRoom then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        local member = team and team:GetSelfMember()
        local isLeader = member and member:IsLeader()
        local isReady = member and member:IsReady()
        if isLeader then
            self:SwitchButtonRightState(ButtonRightState.Fight)
            self:RefreshFightButton(team:IsAllReady())
        else
            self:SwitchButtonRightState(isReady and ButtonRightState.CancelReady or ButtonRightState.Ready)
        end
        self.BtnOpen.gameObject:SetActiveEx(isLeader)
        self:RefreshAutoMatchButton()
        if isLeader then
            -- 检查引导
            XDataCenter.GuideManager.CheckGuideOpen()
        end
    else
        local isMatching = XMVCA.XDlcRoom:IsMatching()
        self:SwitchButtonRightState(isMatching and ButtonRightState.Matching or ButtonRightState.Match)
        self.BtnOpen.gameObject:SetActiveEx(false)
    end
end

function XUiDlcRelinkRoom:RefreshFightButton(isAllReady)
    self.BtnFight:SetButtonState(isAllReady and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiDlcRelinkRoom:RefreshAutoMatchButton()
    self.BtnOpen:SetButtonState(XMVCA.XDlcRoom:IsRoomAutoMatch() and CS.UiButtonState.Normal or CS.UiButtonState.Select)
end

function XUiDlcRelinkRoom:SwitchButtonLeftState(state)
    for buttonState, button in pairs(self.ButtonLeftState) do
        button.gameObject:SetActiveEx(buttonState == state)
    end
end

function XUiDlcRelinkRoom:SwitchButtonRightState(state)
    for buttonState, button in pairs(self.ButtonRightState) do
        button.gameObject:SetActiveEx(buttonState == state)
    end
end

function XUiDlcRelinkRoom:RefreshPanelBoss()
    if not self.PanelBossNode then
        ---@type XUiPanelDlcRelinkBoss
        self.PanelBossNode = XUiPanelDlcRelinkBoss.New(self.PanelBoss, self)
        self.PanelBossNode:Open()
    end
    self.PanelBossNode:Refresh()
    self:RefreshPanelGlobal()
end

function XUiDlcRelinkRoom:RefreshPanelGlobal()
    if not self.PanelGlobalNode then
        ---@type XUiPanelDlcRelinkGlobal
        self.PanelGlobalNode = XUiPanelDlcRelinkGlobal.New(self.PanelGlobal, self)
    end
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    local isOpen = self._Control:CheckGlobalMatchEnableCondition()
    if not isInRoom and isOpen then
        self.PanelGlobalNode:Open()
        self.PanelGlobalNode:Refresh()
    else
        self.PanelGlobalNode:Close()
    end
end

function XUiDlcRelinkRoom:RefreshPanelExp()
    local curLevel = self._Control:GetCurrentPlayerLevel()
    local isMaxLevel = self._Control:GetPlayerLevelIsMax(curLevel)
    if isMaxLevel then
        self.ImgExp.fillAmount = 1
        self.TxtExpLevel.text = self._Control:GetClientConfig("RoomMaxPlayerLevelTips")
    else
        local curExp = self._Control:GetCurrentPlayerExp()
        local nextLevelExp = self._Control:GetNextPlayerLevelExp(curLevel)
        self.ImgExp.fillAmount = nextLevelExp > 0 and (curExp / nextLevelExp) or 0
        self.TxtExpLevel.text = curLevel
    end
    self.ExpRed.gameObject:SetActiveEx(false)
end

function XUiDlcRelinkRoom:RefreshBtnTask()
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

function XUiDlcRelinkRoom:RefreshBtnBox()
    local isSign = self._Control:CheckDailySign()
    self.BtnBox:ShowReddot(not isSign)
    self.IconBox.gameObject:SetActiveEx(not isSign)
end

-- 全局匹配自动发送处理
function XUiDlcRelinkRoom:GlobalMatchAutoSendHandle()
    if XMVCA.XDlcRoom:IsInRoom() or XMVCA.XDlcRoom:IsMatching() then
        return
    end
    if not self._Control:CheckGlobalMatchEnableCondition() then
        return
    end
    self._Control:RequestSwitchGlobalMatchFlag(self._Control:IsGlobalMatchEnabled())
end

--endregion

--region 获取

function XUiDlcRelinkRoom:GetMultiPlayerCharByPlayerId(playerId)
    if not XTool.IsNumberValid(playerId) then
        return nil
    end

    for _, grid in pairs(self.GridMultiPlayerChar) do
        if grid and grid:GetPlayerId() == playerId then
            return grid
        end
    end
    return nil
end

function XUiDlcRelinkRoom:GetEmptyGridByPlayerId(playerId)
    if not XTool.IsNumberValid(playerId) then
        return nil
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    if not team then
        return nil
    end

    local index = team:FindMemberByPlayerId(playerId)
    if not index then
        return nil
    end

    return self.GridMultiPlayerChar[index]
end

--endregion

--region 事件处理

function XUiDlcRelinkRoom:OnRefreshChatMessage(chatData, receiveTime)
    self:RefreshChatContent(chatData)
    self:RefreshChatGrid(chatData, receiveTime)
end

function XUiDlcRelinkRoom:RefreshChatContent(chatData)
    local senderName = XDataCenter.SocialManager.GetPlayerRemark(chatData.SenderId, chatData.NickName)
    if chatData.MsgType == ChatMsgType.Emoji then
        self.TxtMessageContent.text = string.format("%s:%s", senderName, XUiHelper.GetText("EmojiText"))
    else
        self.TxtMessageContent.text = string.format("%s:%s", senderName, chatData.Content)
    end

    if not string.IsNilOrEmpty(chatData.CustomContent) then
        self.TxtMessageContent.supportRichText = true
    else
        self.TxtMessageContent.supportRichText = false
    end

    if XUiHelper.CalcTextWidth(self.TxtMessageContent) > MAX_CHAT_WIDTH then
        self.TxtMessageContent.text = string.Utf8Sub(self.TxtMessageContent.text, 1, CHAT_SUB_LENGTH) .. [[......]]
    end
end

function XUiDlcRelinkRoom:RefreshChatGrid(chatData, receiveTime)
    local grid = self:GetMultiPlayerCharByPlayerId(chatData.SenderId)
    if not grid then
        return
    end

    if grid:IsNodeShow() then
        grid:RefreshChat(chatData, receiveTime)
    end
end

function XUiDlcRelinkRoom:OnEnterRoom()
    -- 进入房间前需要把之前的缓存清一下
    self:RefreshMultiPlayerCharBeforeIntoRoom()
    self:RefreshMultiPlayerChar()
    self:RefreshButtonState()
    self:RefreshPanelBoss()
    self:CheckShowMechanismTeach()
end

function XUiDlcRelinkRoom:OnKickOutRoom()
    self:RefreshMultiPlayerCharOnLeave()
    self:RefreshMultiPlayerChar()
    self:RefreshButtonState()
    self:RefreshPanelBoss()
end

function XUiDlcRelinkRoom:OnRefreshRoom()
    self:RefreshMultiPlayerChar()
end

function XUiDlcRelinkRoom:OnPlayerEnterRoom(playerId)
    local grid = self:GetEmptyGridByPlayerId(playerId)
    if not grid then
        return
    end

    grid:Refresh()
    self:RefreshButtonState()
    self:RefreshPanelBoss()
end

function XUiDlcRelinkRoom:OnPlayerLeaveRoom(playerIds)
    for _, grid in pairs(self.GridMultiPlayerChar) do
        if grid then
            local curPlayerId = grid:GetPlayerId()
            if not XTool.IsNumberValid(curPlayerId) or table.contains(playerIds, curPlayerId) then
                grid:RefreshOnRoomLeave()
                grid:Refresh()
            end
        end
    end
    self:RefreshButtonState()
    self:RefreshPanelBoss()
end

function XUiDlcRelinkRoom:OnPlayerRefresh(playerIds)
    self:RefreshMultiPlayerChar()
    self:RefreshButtonState()
    self:RefreshPanelBoss()
end

---@param roomData XDlcRoomData
---@param changeFlags { IsWorldIdChange : boolean, IsAutoMatchChange :boolean, IsAbilityChange : boolean }
function XUiDlcRelinkRoom:OnRoomInfoChange(roomData, changeFlags)
    self:RefreshMultiPlayerChar()
    self:RefreshPanelBoss()
    self:RefreshButtonState()
end

function XUiDlcRelinkRoom:OnBeginMatching()
    self:RefreshButtonState()
end

function XUiDlcRelinkRoom:OnCancelMatching()
    self:RefreshButtonState()
end

--endregion

--region 检查相关

-- 检查当前队伍职业是否合理
---@param team XDlcTeam
function XUiDlcRelinkRoom:CheckTeamOccupationRational(team)
    local chapterId = self._Control:GetCurrentSelectChapterId()
    return self._Control:CheckTeamOccupationRational(team, chapterId)
end

-- 检查当前队伍装备战力是否合理
---@param team XDlcTeam
function XUiDlcRelinkRoom:CheckTeamEquipAbilityRational(team)
    local levelId = self._Control:GetCurrentSelectLevelId()
    local abilityLimit = self._Control:GetLevelAbilityLimit(levelId)
    return self._Control:CheckTeamEquipAbilityRational(team, abilityLimit)
end

--endregion

--region UI事件

function XUiDlcRelinkRoom:RegisterUiEvents()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnTask:AddEventListener(handler(self, self.OnBtnTaskClick))
    self.BtnChat:AddEventListener(handler(self, self.OnBtnChatClick))
    self.BtnInvite:AddEventListener(handler(self, self.OnBtnInviteClick))
    self.BtnOpen:AddEventListener(handler(self, self.OnBtnOpenClick), true, true, 0.5)
    self.BtnFight:AddEventListener(handler(self, self.OnBtnFightClick), true, true, 0.5)
    self.BtnMatch:AddEventListener(handler(self, self.OnBtnMatchClick), true, true, 0.5)
    self.BtnMatching:AddEventListener(handler(self, self.OnBtnMatchingClick), true, true, 0.5)
    self.BtnReady:AddEventListener(handler(self, self.OnBtnReadyClick), true, true, 0.5)
    self.BtnCancelReady:AddEventListener(handler(self, self.OnBtnCancelReadyClick), true, true, 0.5)
    self.BtnLeave:AddEventListener(handler(self, self.OnBtnLeaveClick), true, true, 0.5)
    self.BtnCreate:AddEventListener(handler(self, self.OnBtnCreateClick), true, true, 0.5)
    self.BtnExp:AddEventListener(handler(self, self.OnBtnExpClick))
    self.BtnEncyclopedia:AddEventListener(handler(self, self.OnBtnEncyclopediaClick))
    self.BtnRank:AddEventListener(handler(self, self.OnBtnRankClick))
    self.BtnBox:AddEventListener(handler(self, self.OnBtnBoxClick))
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiDlcRelinkRoom:OnBtnBackClick()
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

function XUiDlcRelinkRoom:OnBtnTaskClick()
    XLuaUiManager.Open("UiDlcRelinkLvReward")
end

function XUiDlcRelinkRoom:OnBtnChatClick()
    if XMVCA.XDlcRoom:IsInRoom() then
        XUiHelper.OpenUiChatServeMain(false, ChatChannelType.Room, ChatChannelType.World)
    else
        XUiHelper.OpenUiChatServeMain(false, ChatChannelType.World)
    end
end

function XUiDlcRelinkRoom:OnBtnInviteClick()
    XLuaUiManager.Open("UiDlcRelinkPopupExchangeWheel")
end

function XUiDlcRelinkRoom:OnBtnOpenClick()
    if not XMVCA.XDlcRoom:IsInRoom() then
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    local member = team and team:GetSelfMember()
    if not member then
        return
    end

    -- 只有房主可以操作
    if not member:IsLeader() then
        self._Control:OpenCommonTipMsg(XUiHelper.GetText("MultiplayerRoomOnlyHomeownerTip"))
        return
    end

    -- 只有从非自动匹配切换到自动匹配时，才检查房主装备战力是否满足推荐
    if not XMVCA.XDlcRoom:IsRoomAutoMatch() then
        local levelId = self._Control:GetCurrentSelectLevelId()
        local abilityLimit = self._Control:GetLevelAbilityLimit(levelId)
        local totalAbility = member:GetRelinkEquipTotalAbility()
        if totalAbility < abilityLimit then
            self:RefreshAutoMatchButton()
            self._Control:OpenCommonTipText("RoomLeaderEquipAbilityNotRationalTips")
            return
        end
    end

    -- 切换自动匹配状态
    XMVCA.XDlcRoom:SetAutoMatch(not XMVCA.XDlcRoom:IsRoomAutoMatch())
end

function XUiDlcRelinkRoom:OnBtnFightClick()
    --教学/训练关无要求 直接进
    if self._Control:IsTutorialChapter() then
        local levelId = self._Control:GetCurrentSelectLevelId()
        local worldId = self._Control:GetActivityWorldId()
        XMVCA.XDlcRoom:RequestDlcSingleEnterFight(worldId, levelId)
        return
    end

    if not XMVCA.XDlcRoom:IsInRoom() then
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    if not team or not team:IsSelfLeader() then
        return
    end

    -- 队伍未全部准备
    if not team:IsAllReady() then
        self._Control:OpenCommonTipText("RoomWaitAllReadyTips")
        return
    end

    -- 检查当前选择的关卡是否解锁
    local levelId = self._Control:GetCurrentSelectLevelId()
    if not self._Control:CheckLevelUnlock(levelId) then
        self._Control:OpenCommonTipMsg(self._Control:GetLevelUnlockDesc(levelId))
        return
    end

    -- 仓库是否已满
    local curCount, maxCount = self._Control:GetEquipBagCurCountAndMaxCount()
    if curCount >= maxCount then
        self._Control:OpenCommonTipCode(XCode.RelinkEquipBagIsFull)
        return
    end

    -- 职业不合理 & 装备战力不满足推荐
    local isOccupationRational = self:CheckTeamOccupationRational(team)
    local isEquipAbilityRational = self:CheckTeamEquipAbilityRational(team)
    if not isOccupationRational then
        if not isEquipAbilityRational then
            self:OpenOccupationTipDialog(function()
                self:OpenEquipAbilityTipDialog(function()
                    XMVCA.XDlcRoom:Enter()
                end)
            end)
        else
            self:OpenOccupationTipDialog(function()
                XMVCA.XDlcRoom:Enter()
            end)
        end
        return
    end
    if not isEquipAbilityRational then
        self:OpenEquipAbilityTipDialog(function()
            XMVCA.XDlcRoom:Enter()
        end)
        return
    end
    -- 直接进入
    XMVCA.XDlcRoom:Enter()
end

-- 二次确认弹窗:队伍职业不合理
function XUiDlcRelinkRoom:OpenOccupationTipDialog(callback)
    local title = self._Control:GetClientConfig("TipTitle")
    local data = self._Control:GetClientConfigParams("RoomTeamOccupationNotRationalTipContent")
    local content = data[1] or ""
    local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "RoomTeamOccupationNotRationalTip", }
    self._Control:OpenCommonTipDialog(title, content, nil, callback, extraData)
end

-- 二次确认弹窗:队伍装备战力不满足推荐
function XUiDlcRelinkRoom:OpenEquipAbilityTipDialog(callback)
    local title = self._Control:GetClientConfig("TipTitle")
    local data = self._Control:GetClientConfigParams("RoomTeamEquipAbilityNotRationalTipContent")
    local content = data[1] or ""
    local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "RoomTeamEquipAbilityNotRationalTip", }
    self._Control:OpenCommonTipDialog(title, content, nil, callback, extraData)
end

function XUiDlcRelinkRoom:OnBtnMatchClick()
    -- 是否选择角色
    local characterId = self._Control:GetFightCharacterId()
    if not XTool.IsNumberValid(characterId) then
        self._Control:OpenCommonTipText("RoomNotSelectRoleTips")
        return
    end

    local isGlobalMatch = self._Control:IsGlobalMatchEnabled()
    -- 是否选择关卡
    local worldId = self._Control:GetActivityWorldId()
    local levelId = self._Control:GetCurrentSelectLevelId()
    if not isGlobalMatch and not XTool.IsNumberValid(levelId) then
        self._Control:OpenCommonTipText("RoomNotSelectLevelTips")
        return
    end

    -- 当前角色装备战力是否满足推荐
    if not isGlobalMatch then
        local totalAbility = self._Control:GetEquipTotalAbilityByCharacterId(characterId)
        local abilityLimit = self._Control:GetLevelAbilityLimit(levelId)
        if totalAbility < abilityLimit then
            self._Control:OpenCommonTipText("RoomEquipAbilityNotRationalTips")
            return
        end
    end

    -- 装备背包是否已满
    local curCount, maxCount = self._Control:GetEquipBagCurCountAndMaxCount()
    if curCount >= maxCount then
        local title = self._Control:GetClientConfig("TipTitle")
        local data = self._Control:GetClientConfigParams("EquipBagFullMatchTipContent")
        local content = data[1] or ""
        local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "EquipBagFullMatchTip", }
        self._Control:OpenCommonTipDialog(title, content, function()
            XLuaUiManager.Open("UiDlcRelinkEquipDecompose")
        end, function()
            self:OnReqMatchConfirm(worldId, levelId)
        end, extraData)
        return
    end

    -- 确认匹配
    self:OnReqMatchConfirm(worldId, levelId)
end

function XUiDlcRelinkRoom:OnReqMatchConfirm(worldId, levelId)
    if XTool.IsNumberValid(worldId) then
        XMVCA.XDlcRoom:ReqMatch(worldId, levelId, true)
    end
end

function XUiDlcRelinkRoom:OnBtnMatchingClick()
    XMVCA.XDlcRoom:ReqCancelMatch()
end

function XUiDlcRelinkRoom:OnBtnReadyClick()
    if not XMVCA.XDlcRoom:IsInRoom() then
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    local isSelfLeader = team and team:IsSelfLeader()
    if isSelfLeader then
        return
    end

    -- 检查当前选择的关卡是否解锁
    local levelId = self._Control:GetCurrentSelectLevelId()
    if not self._Control:CheckLevelUnlock(levelId) then
        self._Control:OpenCommonTipMsg(self._Control:GetLevelUnlockDesc(levelId))
        return
    end
    XMVCA.XDlcRoom:Ready()
end

function XUiDlcRelinkRoom:OnBtnCancelReadyClick()
    XMVCA.XDlcRoom:CancelReady()
end

function XUiDlcRelinkRoom:OnBtnLeaveClick()
    XMVCA.XDlcRoom:Quit(function()
        self:RefreshMultiPlayerCharOnLeave()
        self:RefreshMultiPlayerChar()
        self:RefreshButtonState()
        self:RefreshPanelBoss()
    end)
end

function XUiDlcRelinkRoom:OnBtnCreateClick()
    if not self._Control:IsTeachingLevelPass() then
        return
    end

    if self._Control:IsTutorialChapter() then
        return
    end

    if self._Control:IsGlobalMatchEnabled() then
        return
    end

    local characterId = self._Control:GetFightCharacterId()
    if not XTool.IsNumberValid(characterId) then
        self._Control:OpenCommonTipText("RoomNotSelectRoleTips")
        return
    end

    if XMVCA.XDlcRoom:IsMatching() then
        self._Control:OpenCommonTipCode(XCode.MatchPlayerIsMatching)
        return
    end

    local worldId = self._Control:GetActivityWorldId()
    local levelId = self._Control:GetCurrentSelectLevelId()
    if not XTool.IsNumberValid(levelId) then
        self._Control:OpenCommonTipText("RoomNotSelectLevelTips")
        return
    end

    if XTool.IsNumberValid(worldId) and XTool.IsNumberValid(levelId) then
        XMVCA.XDlcRoom:CreateRoom(worldId, levelId, 1, true)
    end
end

function XUiDlcRelinkRoom:OnBtnExpClick()
    XLuaUiManager.Open("UiDlcRelinkPopupResearch", function()
        self:RefreshPanelExp()
        self:RefreshBtnTask()
    end)
end

function XUiDlcRelinkRoom:OnBtnEncyclopediaClick()
    XLuaUiManager.Open("UiDlcRelinkEncyclopedia")
end

function XUiDlcRelinkRoom:OnBtnRankClick()
    XLuaUiManager.Open("UiDlcRelinkRank")
end

function XUiDlcRelinkRoom:OnBtnBoxClick()
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

--endregion

--region 机制教学

function XUiDlcRelinkRoom:CheckShowMechanismTeach()
    -- 引导中不弹
    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end
    local levelId = self.PanelBossNode.LevelId
    if not XTool.IsNumberValid(levelId) then
        return
    end
    local teachConfig = self._Control:GetMechanismTeachByLevelId(levelId)
    if not teachConfig then
        return
    end
    XLuaUiManager.Open("UiDlcRelinkPopupTutorial", teachConfig.Id)
end

--endregion

--region 教学关

function XUiDlcRelinkRoom:MarkTeachingLevel()
    if self._Control:IsTutorialChapter() and not self._Control:IsTeachingLevelPass() then
        self._CheckTeachingLevel = true
    end
end

---首通教学关后 需要恢复正常个人房间状态，且角色选择为空
function XUiDlcRelinkRoom:ClearTeachingLevel()
    if self._CheckTeachingLevel and self._Control:IsTeachingLevelPass() then
        self._Control:SetCurrentSelectLevelData()
    end
    self._CheckTeachingLevel = false
end

---通过事件更新（避免协议延迟没更新到）
function XUiDlcRelinkRoom:RefreshAfterTeachingLevelPass()
    self._Control:SetCurrentSelectLevelData()
    self:RefreshMultiPlayerChar()
    self:RefreshButtonState()
    self:RefreshPanelBoss()
end

--endregion

--region 提示信息相关

function XUiDlcRelinkRoom:InitDot()
    if XTool.IsTableEmpty(self.Tips) then
        self.PanelDot.gameObject:SetActiveEx(false)
        return
    end
    ---@type UiObject[]
    self.GridDotList = {}
    self.PanelDot.gameObject:SetActiveEx(true)
    local dotCount = #self.Tips
    for i = 1, dotCount do
        local go = XUiHelper.Instantiate(self.GridDot, self.PanelDot)
        go.gameObject:SetActiveEx(true)
        self.GridDotList[i] = go
    end
end

function XUiDlcRelinkRoom:StartTipsTimer()
    if XTool.IsTableEmpty(self.Tips) then
        self.PanelBanner.gameObject:SetActiveEx(false)
        return
    end
    self:StopTipsTimer()
    self.PanelBanner.gameObject:SetActiveEx(true)
    self.TipsTimer = XScheduleManager.ScheduleForeverEx(function()
        self:RefreshTip()
    end, self.TipSwitchInterval)
end

function XUiDlcRelinkRoom:RefreshTip()
    if XTool.UObjIsNil(self.TxtBannerTitle) then
        return
    end
    self.CurrentTipIndex = self:GetNextIndex()
    -- 刷新文本和图片
    self.TxtBannerTitle.text = self.Tips[self.CurrentTipIndex]
    local tipIcon = self.TipIcons[self.CurrentTipIndex]
    self.RImgBanner:SetRawImageEx(tipIcon)
    -- 刷新指示点
    for index, go in pairs(self.GridDotList) do
        local isActive = index == self.CurrentTipIndex
        go:GetObject("ImgOff").gameObject:SetActiveEx(not isActive)
        go:GetObject("ImgOn").gameObject:SetActiveEx(isActive)
    end
end

function XUiDlcRelinkRoom:StopTipsTimer()
    if self.TipsTimer then
        XScheduleManager.UnSchedule(self.TipsTimer)
        self.TipsTimer = nil
    end
    self.CurrentTipIndex = -1
end

function XUiDlcRelinkRoom:GetNextIndex()
    local totalTips = #self.Tips
    if totalTips <= 1 then
        return 1
    end
    local nextIndex = self.CurrentTipIndex + 1
    if nextIndex < 1 or nextIndex > totalTips then
        nextIndex = 1
    end
    return nextIndex
end

--endregion

return XUiDlcRelinkRoom
