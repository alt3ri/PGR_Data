local XUiGridRelinkMultiPlayerChar = require("XUi/XUiDlcRelink/Room/XUiGridRelinkMultiPlayerChar")
---@class XUiRelinkPlayerRoom : XLuaUi
---@field private _Control XDlcRelinkControl
---@field BtnAutoMatch XUiComponent.XUiButton
local XUiRelinkPlayerRoom = XLuaUiManager.Register(XLuaUi, "UiRelinkPlayerRoom")

local MAX_CHAT_WIDTH = 450
local CHAT_SUB_LENGTH = 18
local ButtonState = {
    Fight = 1,
    Ready = 2,
    CancelReady = 3,
}

function XUiRelinkPlayerRoom:OnAwake()
    if not XMVCA.XDlcRoom:IsInRoom() then
        self:Close()
        return
    end

    self.GridMulitiplayerRoomChar.gameObject:SetActiveEx(false)
    self.PanelAsset.gameObject:SetActiveEx(false)
    self.BtnMatching.gameObject:SetActiveEx(false)
    self.MatchingSuccess.gameObject:SetActiveEx(false)

    self.ButtonMap = {
        [ButtonState.Fight] = self.BtnFight,
        [ButtonState.Ready] = self.BtnReady,
        [ButtonState.CancelReady] = self.BtnCancelReady,
    }

    self.MainModelRoot = nil
    ---@type XUiGridRelinkMultiPlayerChar[]
    self.GridMultiPlayerChar = {}
    ---@type table<number, XUiGridRelinkMultiPlayerChar>
    self.GridMultiPlayerCharMap = {}
    ---@type XDlcTeam
    self.Team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    self:RegisterUiEvents()
end

function XUiRelinkPlayerRoom:OnStart()
    if not XMVCA.XDlcRoom:IsInRoom() then
        self:Close()
        return
    end

    self:InitScene()
    XMVCA.XDlcRoom:CancelReconnectToWorld()
end

function XUiRelinkPlayerRoom:OnEnable()
    if not XMVCA.XDlcRoom:IsInRoom() then
        self:Close()
        return
    end

    self:RefreshCharacter()
    self:RefreshButtonState()
end

function XUiRelinkPlayerRoom:OnGetLuaEvents()
    return {
        XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG,
        XEventId.EVENT_DLC_ROOM_REFRESH,
        XEventId.EVENT_DLC_ROOM_PLAYER_ENTER,
        XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE,
        XEventId.EVENT_DLC_ROOM_PLAYER_REFRESH,
        XEventId.EVENT_DLC_ROOM_INFO_CHANGE,
    }
end

function XUiRelinkPlayerRoom:OnNotify(event, ...)
    local args = { ... }
    if event == XEventId.EVENT_CHAT_RECEIVE_ROOM_MSG then
        self:OnRefreshChatMessage(args[1], args[2])
    elseif event == XEventId.EVENT_DLC_ROOM_REFRESH then
        self:OnRoomRefresh()
    elseif event == XEventId.EVENT_DLC_ROOM_PLAYER_ENTER then
        self:OnPlayerEnter(args[1])
    elseif event == XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE then
        self:OnPlayerLeave(args[1])
    elseif event == XEventId.EVENT_DLC_ROOM_PLAYER_REFRESH then
        self:OnPlayerRefresh(args[1])
    elseif event == XEventId.EVENT_DLC_ROOM_INFO_CHANGE then
        self:OnRoomInfoChange(args[1], args[2])
    end
end

--region 初始化

function XUiRelinkPlayerRoom:InitScene()
    local sceneUrl = self._Control:GetCurrentWorldScene()
    local modelUrl = self._Control:GetCurrentWorldSceneModel()
    local loadingType = self._Control:GetCurrentMaskLoadingType()

    XLuaUiManager.Open("UiLoading", loadingType)
    self:LoadUiSceneAsync(sceneUrl, modelUrl, function()
        if not self._Control then
            XLuaUiManager.SafeClose("UiLoading")
            return
        end
        self.Team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        self:InitModelRoot()
        self:InitCharacterGrid()
        self:RefreshCharacter()
        XMVCA.XDlcRelink:DlcInitFight()
        XLuaUiManager.Close("UiLoading")
    end)
end

function XUiRelinkPlayerRoom:InitModelRoot()
    local root = self.UiModelGo.transform
    self.MainModelRoot = root:FindTransform("PanelRoleModel")
    self.MainModelRoot.gameObject:SetActiveEx(true)
end

function XUiRelinkPlayerRoom:InitCharacterGrid()
    local memberCount = self.Team:GetMaxMemeberNumber()
    local root = self.MainModelRoot or self.UiModelGo.transform

    for index = 1, memberCount do
        local case = root:FindTransform(string.format("Role%d", index))
        local grid = self.GridMultiPlayerChar[index]
        if not grid then
            local roomCase = self[string.format("RoomCharCase%d", index)]
            local go = XUiHelper.Instantiate(self.GridMulitiplayerRoomChar, roomCase)
            grid = XUiGridRelinkMultiPlayerChar.New(go, self, self.Team, index, case)
            self.GridMultiPlayerChar[index] = grid
        end
        grid.Transform:Reset()
    end
end

--endregion

--region 刷新

function XUiRelinkPlayerRoom:RefreshCharacter()
    self.GridMultiPlayerCharMap = {}
    for index, grid in ipairs(self.GridMultiPlayerChar) do
        local member = self.Team:GetMember(index)
        if member and not member:IsEmpty() then
            self.GridMultiPlayerCharMap[member:GetPlayerId()] = grid
            self:RefreshCharacterGrid(grid)
        else
            grid:Close()
        end
    end
end

---@param grid XUiGridRelinkMultiPlayerChar
function XUiRelinkPlayerRoom:RefreshCharacterGrid(grid)
    if not grid then
        return
    end
    grid:Open()
    grid:Refresh()
end

function XUiRelinkPlayerRoom:RefreshButtonState()
    local member = self.Team:GetSelfMember()
    if not member or member:IsEmpty() then
        return
    end

    if member:IsLeader() then
        self:SwitchButtonState(ButtonState.Fight)
        self:RefreshFightButton()
    elseif member:IsReady() then
        self:SwitchButtonState(ButtonState.CancelReady)
    else
        self:SwitchButtonState(ButtonState.Ready)
    end

    self:RefreshBtnAutoMatch()
end

function XUiRelinkPlayerRoom:RefreshChatContent(chatData)
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

function XUiRelinkPlayerRoom:RefreshChatGrid(chatData, receiveTime)
    local grid = self.GridMultiPlayerCharMap[chatData.SenderId]
    if not grid then
        return
    end
    if grid:IsNodeShow() then
        grid:RefreshChat(chatData, receiveTime)
    end
end

function XUiRelinkPlayerRoom:RefreshFightButton()
    self.BtnFight:SetButtonState(self.Team:IsAllReady() and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
end

function XUiRelinkPlayerRoom:RefreshBtnAutoMatch()
    self.BtnAutoMatch.gameObject:SetActiveEx(self.Team:IsSelfLeader())
    self.BtnAutoMatch:SetButtonState(XMVCA.XDlcRoom:IsRoomAutoMatch() and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

--endregion

--region Set

function XUiRelinkPlayerRoom:SetPlayerToGrid(playerId, grid)
    if not playerId or not grid then
        return
    end
    self.GridMultiPlayerCharMap[playerId] = grid
end

--endregion

--region Get

function XUiRelinkPlayerRoom:GetEmptyGridByPlayerId(playerId)
    local index = self.Team:FindMemberByPlayerId(playerId)
    local grid = self.GridMultiPlayerChar[index]
    if grid and grid:IsEmpty() then
        return grid
    end
    return nil
end

--endregion

--region 事件相关

function XUiRelinkPlayerRoom:OnRefreshChatMessage(chatData, receiveTime)
    self:RefreshChatContent(chatData)
    self:RefreshChatGrid(chatData, receiveTime)
end

function XUiRelinkPlayerRoom:OnRoomRefresh()
    self:RefreshCharacter()
end

function XUiRelinkPlayerRoom:OnPlayerEnter(playerId)
    local grid = self:GetEmptyGridByPlayerId(playerId)
    self:SetPlayerToGrid(playerId, grid)
    self:RefreshCharacterGrid(grid)
    self:RefreshButtonState()
end

function XUiRelinkPlayerRoom:OnPlayerLeave(leaveIds)
    for _, playerId in pairs(leaveIds) do
        local grid = self.GridMultiPlayerCharMap[playerId]
        if grid then
            grid:Close()
            self.GridMultiPlayerCharMap[playerId] = nil
        end
    end
    self:RefreshButtonState()
end

function XUiRelinkPlayerRoom:OnPlayerRefresh(playerIds)
    if self.Team:IsSelfLeader() then
        for _, grid in pairs(self.GridMultiPlayerCharMap) do
            self:RefreshCharacterGrid(grid)
        end
    else
        for _, playerId in ipairs(playerIds) do
            local grid = self.GridMultiPlayerCharMap[playerId]
            if grid then
                self:RefreshCharacterGrid(grid)
            end
        end
    end
    self:RefreshButtonState()
end

---@param roomData XDlcRoomData
---@param changeFlags { IsWorldIdChange : boolean, IsAutoMatchChange :boolean, IsAbilityChange : boolean }
function XUiRelinkPlayerRoom:OnRoomInfoChange(roomData, changeFlags)
    self:RefreshButtonState()
end

function XUiRelinkPlayerRoom:OnRefreshModel(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end
    local grid = self.GridMultiPlayerCharMap[XPlayer.Id]
    if grid and grid:IsNodeShow() then
        grid:RefreshModel(characterId)
    end
end

--endregion

--region 按钮相关

function XUiRelinkPlayerRoom:SwitchButtonState(state)
    for buttonState, button in pairs(self.ButtonMap) do
        button.gameObject:SetActiveEx(buttonState == state)
    end
end

function XUiRelinkPlayerRoom:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnChat, self.OnBtnChatClick)
    self:RegisterClickEvent(self.BtnInvite, self.OnBtnInviteClick)
    self:RegisterClickEvent(self.BtnCancelReady, self.OnBtnCancelReadyClick)
    self:RegisterClickEvent(self.BtnFight, self.OnBtnFightClick)
    self:RegisterClickEvent(self.BtnReady, self.OnBtnReadyClick)
    self:RegisterClickEvent(self.BtnAutoMatch, self.OnBtnAutoMatchClick)

    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
end

function XUiRelinkPlayerRoom:OnBtnBackClick()
    if self.Team and self.Team:GetMemberAmount() == 1 then
        XMVCA.XDlcRoom:Quit(function()
            self:Close()
        end)
    else
        XMVCA.XDlcRoom:DialogTipQuit(function()
            self:Close()
        end)
    end
end

function XUiRelinkPlayerRoom:OnBtnMainUiClick()
    XLuaUiManager.RunMain(self.Team and self.Team:GetMemberAmount() == 1)
end

function XUiRelinkPlayerRoom:OnBtnChatClick()
    XUiHelper.OpenUiChatServeMain(false, ChatChannelType.Room, ChatChannelType.World)
end

function XUiRelinkPlayerRoom:OnBtnInviteClick()
    self._Control:OpenFriendInviteUi("UiRelinkPopupPlayerInvite")
end

function XUiRelinkPlayerRoom:OnBtnCancelReadyClick()
    XMVCA.XDlcRoom:CancelReady()
end

function XUiRelinkPlayerRoom:OnBtnFightClick()
    if not self.Team:IsAllReady() or not self.Team:IsSelfLeader() then
        return
    end
    XMVCA.XDlcRoom:Enter()
end

function XUiRelinkPlayerRoom:OnBtnReadyClick()
    if not self.Team:IsSelfLeader() then
        XMVCA.XDlcRoom:Ready()
    end
end

function XUiRelinkPlayerRoom:OnBtnAutoMatchClick()
    if not self.Team:IsSelfLeader() then
        XUiManager.TipText("MultiplayerRoomCanNotChangeAutoMatch")
        return
    end

    XMVCA.XDlcRoom:SetAutoMatch(not XMVCA.XDlcRoom:IsRoomAutoMatch())
end

--endregion

return XUiRelinkPlayerRoom
