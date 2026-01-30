local XUiGridDlcRelinkMultiPlayerChar = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkMultiPlayerChar")
local XUiPanelDlcRelinkBoss = require("XUi/XUiDlcRelink/Room/Panel/XUiPanelDlcRelinkBoss")
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

    local itemIds = { XDataCenter.ItemManager.ItemId.DlcRelinkExpCoin, XDataCenter.ItemManager.ItemId.DlcRelinkGameplayCoin }
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self, nil, function(data, index)
        local itemId = itemIds[index]
        XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", itemId)
    end)
end

function XUiDlcRelinkRoom:OnStart()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self:InitSceneModel()
    self:InitMultiPlayerChar()

    if XMVCA.XDlcRoom:IsInRoom() then
        XMVCA.XDlcRoom:CancelReconnectToWorld()
    end
end

function XUiDlcRelinkRoom:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshMultiPlayerChar()
    self:RefreshButtonState()
    self:RefreshPanelBoss()
    self:RefreshPanelExp()
    self:RefreshBtnTask()
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
    end
end

function XUiDlcRelinkRoom:OnDisable()
    self.Super.OnDisable(self)
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

--endregion

--region 刷新

function XUiDlcRelinkRoom:RefreshMultiPlayerChar()
    for _, grid in pairs(self.GridMultiPlayerChar) do
        if grid then
            grid:Refresh()
        end
    end
end

function XUiDlcRelinkRoom:RefreshButtonState()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    self:SwitchButtonLeftState(isInRoom and ButtonLeftState.Leave or ButtonLeftState.Create)
    if isInRoom then
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
        self.BtnOpen:SetButtonState(XMVCA.XDlcRoom:IsRoomAutoMatch() and CS.UiButtonState.Normal or CS.UiButtonState.Select)
    else
        local isMatching = XMVCA.XDlcRoom:IsMatching()
        self:SwitchButtonRightState(isMatching and ButtonRightState.Matching or ButtonRightState.Match)
        self.BtnOpen.gameObject:SetActiveEx(false)
    end
end

function XUiDlcRelinkRoom:RefreshFightButton(isAllReady)
    self.BtnFight:SetButtonState(isAllReady and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
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
    self:RefreshMultiPlayerChar()
    self:RefreshButtonState()
    self:RefreshPanelBoss()
end

function XUiDlcRelinkRoom:OnKickOutRoom()
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
                grid:Refresh()
            end
        end
    end
    self:RefreshButtonState()
    self:RefreshPanelBoss()
end

function XUiDlcRelinkRoom:OnPlayerRefresh(playerIds)
    for _, playerId in pairs(playerIds) do
        local grid = self:GetMultiPlayerCharByPlayerId(playerId)
        if grid then
            grid:Refresh()
        end
    end
    self:RefreshButtonState()
    self:RefreshPanelBoss()
end

---@param roomData XDlcRoomData
---@param changeFlags { IsWorldIdChange : boolean, IsAutoMatchChange :boolean, IsAbilityChange : boolean }
function XUiDlcRelinkRoom:OnRoomInfoChange(roomData, changeFlags)
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

-- 检查当队伍职业配置是否合理
---@param team XDlcTeam
function XUiDlcRelinkRoom:CheckTeamOccupationRational(team)
    local chapterId = self._Control:GetCurrentSelectChapterId()
    local occupationMap = {}
    local amount = team:GetMemberNumber()
    for pos = 1, amount do
        local member = team:GetMember(pos)
        if member then
            occupationMap[member:GetOccupationType()] = true
        end
    end

    local trueOccupationList = self._Control:GetChapterTrueOccupations(chapterId)
    for _, occupation in ipairs(trueOccupationList) do
        if not occupationMap[occupation] then
            return false
        end
    end
    return true
end

-- 检查当队伍装备战力是否满足推荐
---@param team XDlcTeam
function XUiDlcRelinkRoom:CheckTeamEquipAbilityRational(team)
    local levelId = self._Control:GetCurrentSelectLevelId()
    local levelLimit = self._Control:GetLevelLevelLimit(levelId)
    local amount = team:GetMemberNumber()
    for pos = 1, amount do
        local member = team:GetMember(pos)
        if member then
            local totalAbility = member:GetRelinkEquipTotalAbility()
            if totalAbility < levelLimit then
                return false
            end
        end
    end
    return true
end

--endregion

--region UI事件

function XUiDlcRelinkRoom:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnTask, self.OnBtnTaskClick)
    self:RegisterClickEvent(self.BtnChat, self.OnBtnChatClick)
    self:RegisterClickEvent(self.BtnInvite, self.OnBtnInviteClick)
    self:RegisterClickEvent(self.BtnOpen, self.OnBtnOpenClick)
    self:RegisterClickEvent(self.BtnFight, self.OnBtnFightClick)
    self:RegisterClickEvent(self.BtnMatch, self.OnBtnMatchClick)
    self:RegisterClickEvent(self.BtnMatching, self.OnBtnMatchingClick)
    self:RegisterClickEvent(self.BtnReady, self.OnBtnReadyClick)
    self:RegisterClickEvent(self.BtnCancelReady, self.OnBtnCancelReadyClick)
    self:RegisterClickEvent(self.BtnLeave, self.OnBtnLeaveClick)
    self:RegisterClickEvent(self.BtnCreate, self.OnBtnCreateClick)
    self:RegisterClickEvent(self.BtnExp, self.OnBtnExpClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiDlcRelinkRoom:OnBtnBackClick()
    XLuaUiManager.CloseAllUpperUi("UiDlcRelinkMain")
end

function XUiDlcRelinkRoom:OnBtnTaskClick()
    XLuaUiManager.Open("UiDlcRelinkLvReward")
end

function XUiDlcRelinkRoom:OnBtnChatClick()
    XUiHelper.OpenUiChatServeMain(false, ChatChannelType.Room, ChatChannelType.World)
end

function XUiDlcRelinkRoom:OnBtnInviteClick()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    local characterId
    if isInRoom then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        local member = team and team:GetSelfMember()
        if not member or member:IsReady() then
            return
        end
        characterId = member:GetCharacterId()
    else
        characterId = self._Control:GetFightCharacterId()
    end
    XLuaUiManager.Open("UiDlcRelinkCharacter", characterId)
end

function XUiDlcRelinkRoom:OnBtnOpenClick()
    if not XMVCA.XDlcRoom:IsInRoom() then
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    local isSelfLeader = team and team:IsSelfLeader()
    if not isSelfLeader then
        self._Control:OpenCommonTipMsg(XUiHelper.GetText("MultiplayerRoomOnlyHomeownerTip"))
        return
    end
    XMVCA.XDlcRoom:SetAutoMatch(not XMVCA.XDlcRoom:IsRoomAutoMatch())
end

function XUiDlcRelinkRoom:OnBtnFightClick()
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
    local characterId = self._Control:GetFightCharacterId()
    if not XTool.IsNumberValid(characterId) then
        self._Control:OpenCommonTipText("RoomNotSelectRoleTips")
        return
    end

    local worldId = self._Control:GetActivityWorldId()
    local levelId = self._Control:GetCurrentSelectLevelId()
    if not XTool.IsNumberValid(levelId) then
        self._Control:OpenCommonTipText("RoomNotSelectLevelTips")
        return
    end

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

    self:OnReqMatchConfirm(worldId, levelId)
end

function XUiDlcRelinkRoom:OnReqMatchConfirm(worldId, levelId)
    if XTool.IsNumberValid(worldId) and XTool.IsNumberValid(levelId) then
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
    XMVCA.XDlcRoom:Ready()
end

function XUiDlcRelinkRoom:OnBtnCancelReadyClick()
    XMVCA.XDlcRoom:CancelReady()
end

function XUiDlcRelinkRoom:OnBtnLeaveClick()
    XMVCA.XDlcRoom:Quit(function()
        self:RefreshMultiPlayerChar()
        self:RefreshButtonState()
        self:RefreshPanelBoss()
    end)
end

function XUiDlcRelinkRoom:OnBtnCreateClick()
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
    end)
end

--endregion

return XUiDlcRelinkRoom
