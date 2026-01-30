local XUiGridRelinkPopupPlayerInvite = require("XUi/XUiDlcRelink/Room/XUiGridRelinkPopupPlayerInvite")
---@class XUiRelinkPopupPlayerInvite : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiRelinkPopupPlayerInvite = XLuaUiManager.Register(XLuaUi, "UiRelinkPopupPlayerInvite")

function XUiRelinkPopupPlayerInvite:OnAwake()
    self.GridFriend.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self:InitDynamicTable()
end

---@param friendInfoList XDlcRelinkFriend[]
function XUiRelinkPopupPlayerInvite:OnStart(friendInfoList)
    self.FriendInfoList = friendInfoList
end

function XUiRelinkPopupPlayerInvite:OnEnable()
    self:SetupDynamicTable()
    self:RefreshInvitedTime()
    self:RegisterInviteTimer()
end

function XUiRelinkPopupPlayerInvite:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_ROOM_PLAYER_ENTER,
        XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE,
    }
end

function XUiRelinkPopupPlayerInvite:OnNotify(event, ...)
    self:SetupDynamicTable()
end

function XUiRelinkPopupPlayerInvite:OnDisable()
    self:RemoveInviteTimer()
end

function XUiRelinkPopupPlayerInvite:OnInviteClick(friendId)
    XDataCenter.ChatManager.SendChat(self:GetSendChat(friendId), function()
        XUiManager.TipText("OnlineSendWorldSuccess")
    end, true)
end

function XUiRelinkPopupPlayerInvite:GetSendChat(friendId)
    local content = self:GetInviteContent()
    if not content then
        return nil
    end

    return {
        ChannelType = ChatChannelType.Private,
        MsgType = ChatMsgType.DlcRoomMsg,
        Content = content,
        TargetIds = { friendId },
    }
end

function XUiRelinkPopupPlayerInvite:GetInviteContent()
    if not XMVCA.XDlcRoom:IsInRoom() then
        return nil
    end

    local roomData = XMVCA.XDlcRoom:GetRoomData()
    if not roomData then
        return nil
    end

    local contentId = RoomMsgContentId.FrinedInvite
    local worldId = roomData:GetWorldId()
    local levelId = roomData:GetLevelId()
    local roomId = roomData:GetId()
    local nodeId = roomData:GetNodeId()
    local roomType = MultipleRoomType.DlcWorld

    return XChatData.EncodeRoomMsg(contentId, XPlayer.Id, worldId, roomId, roomType, 0, nodeId, levelId)
end

function XUiRelinkPopupPlayerInvite:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelFriendList)
    self.DynamicTable:SetProxy(XUiGridRelinkPopupPlayerInvite, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiRelinkPopupPlayerInvite:SetupDynamicTable()
    if XTool.IsTableEmpty(self.FriendInfoList) then
        return
    end
    self.DynamicTable:SetDataSource(self.FriendInfoList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridRelinkPopupPlayerInvite
function XUiRelinkPopupPlayerInvite:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.FriendInfoList[index])
    end
end

function XUiRelinkPopupPlayerInvite:RefreshInvitedTime()
    ---@type XUiGridRelinkPopupPlayerInvite[]
    local gridList = self.DynamicTable:GetGrids()
    if XTool.IsTableEmpty(gridList) then
        return
    end
    for _, grid in pairs(gridList) do
        if grid and grid:IsNodeShow() then
            grid:RefreshState()
        end
    end
end

function XUiRelinkPopupPlayerInvite:RegisterInviteTimer()
    self:RemoveInviteTimer()
    self.InvitedTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:RemoveInviteTimer()
            return
        end
        self:RefreshInvitedTime()
    end, XScheduleManager.SECOND)
end

function XUiRelinkPopupPlayerInvite:RemoveInviteTimer()
    if self.InvitedTimer then
        XScheduleManager.UnSchedule(self.InvitedTimer)
        self.InvitedTimer = nil
    end
end

function XUiRelinkPopupPlayerInvite:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiRelinkPopupPlayerInvite:OnBtnCloseClick()
    self:Close()
end

return XUiRelinkPopupPlayerInvite
