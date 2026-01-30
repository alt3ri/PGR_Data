---@class XUiGridDlcRelinkPopupPlayerInvite : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkPopupPlayerInvite
---@field BtnInvite XUiComponent.XUiButton
local XUiGridDlcRelinkPopupPlayerInvite = XClass(XUiNode, "XUiGridDlcRelinkPopupPlayerInvite")

function XUiGridDlcRelinkPopupPlayerInvite:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnInvite, self.OnBtnInviteClick, true, true)
end

---@param friendInfo XDlcRelinkFriend
function XUiGridDlcRelinkPopupPlayerInvite:Refresh(friendInfo)
    self.FriendInfo = friendInfo
    self.TxtName.text = friendInfo:GetName()
    XUiPlayerHead.InitPortraitWithoutStandIcon(friendInfo:GetHeadIconId(), friendInfo:GetHeadFrameId(), self.HeadObject)
    self:RefreshState()
end

function XUiGridDlcRelinkPopupPlayerInvite:RefreshState()
    if self:CheckPlayerInRoom(self.FriendInfo:GetFriendId()) then
        self.BtnInvite.gameObject:SetActiveEx(false)
        self.TxtTips.gameObject:SetActiveEx(true)
        self.TxtTips.text = XUiHelper.GetText("DlcMultiplayerInvitedInRoomTips")
    else
        self:RefreshInvitedState()
    end
end

function XUiGridDlcRelinkPopupPlayerInvite:RefreshInvitedState()
    local isOnline = self.FriendInfo:GetIsOnline()
    self.TxtTips.gameObject:SetActiveEx(not isOnline)
    self.BtnInvite.gameObject:SetActiveEx(isOnline)
    -- 不在线显示最后登录时间
    if not isOnline then
        self.TxtTips.text = XUiHelper.GetText("FriendLatelyLogin") .. XUiHelper.CalcLatelyLoginTimeEx(self.FriendInfo:GetLastLoginTime())
        return
    end
    -- 等级未达标显示等级提示
    local unlockLevel = tonumber(self._Control:GetClientConfig("InvitedUnlockedLevel"))
    if self.FriendInfo:GetLevel() < unlockLevel then
        self.BtnInvite.gameObject:SetActiveEx(false)
        self.TxtTips.gameObject:SetActiveEx(true)
        self.TxtTips.text = string.format(self._Control:GetClientConfig("InvitedUnlockLevelTips"), unlockLevel)
        return
    end
    -- 刷新邀请按钮状态
    local canInvite, timeLeft = self:CheckInviteCd()
    self.BtnInvite:SetButtonState(canInvite and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    if canInvite then
        self.BtnInvite:SetNameByGroup(0, self._Control:GetClientConfig("InviteButtonText"))
    else
        local buttonText = string.format(self._Control:GetClientConfig("InviteButtonText", 2), timeLeft)
        self.BtnInvite:SetNameByGroup(1, buttonText)
    end
end

function XUiGridDlcRelinkPopupPlayerInvite:CheckPlayerInRoom(playerId)
    if not XTool.IsNumberValid(playerId) then
        return false
    end
    if XMVCA.XDlcRoom:IsInRoom() then
        local team = XMVCA.XDlcRoom:GetTeam()
        return team and team:IsPlayerInTeam(playerId) or false
    end
    return false
end

-- 检查邀请冷却时间
---@return boolean, number 是否可以邀请，剩余时间
function XUiGridDlcRelinkPopupPlayerInvite:CheckInviteCd()
    local invitedTime = self.FriendInfo:GetInvitedTime()
    if invitedTime <= 0 then
        return true, 0
    end
    local nowTime = XTime.GetServerNowTimestamp()
    local invitedCd = XMVCA.XDlcRoom:GetInviteShowTime()
    local timePassed = nowTime - invitedTime
    if timePassed >= invitedCd then
        return true, 0
    else
        return false, invitedCd - timePassed
    end
end

function XUiGridDlcRelinkPopupPlayerInvite:OnBtnInviteClick()
    if not self.FriendInfo:GetIsOnline() then
        return
    end

    local canInvite, timeLeft = self:CheckInviteCd()
    if not canInvite then
        local tipText = string.format(self._Control:GetClientConfig("InviteCdTips"), timeLeft)
        self._Control:OpenCommonTipMsg(tipText)
        return
    end

    if XMVCA.XDlcRoom:IsInRoom() then
        local team = XMVCA.XDlcRoom:GetTeam()
        if team and team:IsFull() then
            self._Control:OpenCommonTipMsg(XUiHelper.GetText("DlcMultiplayerFullInvitedTip"))
            return
        end
    end

    self.FriendInfo:SetInvitedTime(XTime.GetServerNowTimestamp())
    self.Parent:OnInviteClick(self.FriendInfo:GetFriendId())
    self:RefreshInvitedState()
end

return XUiGridDlcRelinkPopupPlayerInvite
