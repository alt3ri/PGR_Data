local XUiGridDlcRelinkPopupPlayerInvite = require("XUi/XUiDlcRelink/Room/Grid/XUiGridDlcRelinkPopupPlayerInvite")
---@class XUiDlcRelinkPopupPlayerInvite : XLuaUi
---@field private _Control XDlcRelinkControl
local XUiDlcRelinkPopupPlayerInvite = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupPlayerInvite")

function XUiDlcRelinkPopupPlayerInvite:OnAwake()
    self.GridFriend.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self:InitDynamicTable()
end

---@param friendInfoList XDlcRelinkFriend[]
function XUiDlcRelinkPopupPlayerInvite:OnStart(friendInfoList)
    self.FriendInfoList = friendInfoList
end

function XUiDlcRelinkPopupPlayerInvite:OnEnable()
    self:SetupDynamicTable()
    self:RefreshInvitedTime()
    self:RegisterInviteTimer()
end

function XUiDlcRelinkPopupPlayerInvite:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_ROOM_PLAYER_ENTER,
        XEventId.EVENT_DLC_ROOM_PLAYER_LEAVE,
    }
end

function XUiDlcRelinkPopupPlayerInvite:OnNotify(event, ...)
    self:SetupDynamicTable()
end

function XUiDlcRelinkPopupPlayerInvite:OnDisable()
    self:RemoveInviteTimer()
end

--region 发送邀请

function XUiDlcRelinkPopupPlayerInvite:OnInviteClick(friendId)
    XDataCenter.ChatManager.SendChat(self:GetSendChat(friendId), function()
        XUiManager.TipText("OnlineSendWorldSuccess")
    end, true)
end

function XUiDlcRelinkPopupPlayerInvite:GetSendChat(friendId)
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

function XUiDlcRelinkPopupPlayerInvite:GetInviteContent()
    if not XMVCA.XDlcRoom:IsInRoom() then
        return nil
    end

    ---@type XDlcRoomData
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

--endregion

--region 动态列表

function XUiDlcRelinkPopupPlayerInvite:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelFriendList)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkPopupPlayerInvite, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkPopupPlayerInvite:SetupDynamicTable()
    if XTool.IsTableEmpty(self.FriendInfoList) then
        return
    end
    self.DynamicTable:SetDataSource(self.FriendInfoList)
    self.DynamicTable:ReloadDataASync()
end

---@param grid XUiGridDlcRelinkPopupPlayerInvite
function XUiDlcRelinkPopupPlayerInvite:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.FriendInfoList[index])
    end
end

--endregion

--region 邀请倒计时

function XUiDlcRelinkPopupPlayerInvite:RefreshInvitedTime()
    ---@type XUiGridDlcRelinkPopupPlayerInvite[]
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

function XUiDlcRelinkPopupPlayerInvite:RegisterInviteTimer()
    self:RemoveInviteTimer()
    self.InvitedTimer = XScheduleManager.ScheduleForever(function()
        if XTool.UObjIsNil(self.GameObject) then
            self:RemoveInviteTimer()
            return
        end
        self:RefreshInvitedTime()
    end, XScheduleManager.SECOND)
end

function XUiDlcRelinkPopupPlayerInvite:RemoveInviteTimer()
    if self.InvitedTimer then
        XScheduleManager.UnSchedule(self.InvitedTimer)
        self.InvitedTimer = nil
    end
end

--endregion

function XUiDlcRelinkPopupPlayerInvite:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiDlcRelinkPopupPlayerInvite:OnBtnCloseClick()
    self:Close()
end

return XUiDlcRelinkPopupPlayerInvite
