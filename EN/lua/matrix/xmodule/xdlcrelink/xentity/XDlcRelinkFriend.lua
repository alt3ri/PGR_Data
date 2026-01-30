---@class XDlcRelinkFriend
local XDlcRelinkFriend = XClass(nil, "XDlcRelinkFriend")

function XDlcRelinkFriend:Ctor()
    self.Level = 0
    self.Name = ""
    self.HeadIconId = 0
    self.HeadFrameId = 0
    self.FriendId = 0
    self.IsOnline = false
    self.TitleId = 0
    self.LastLoginTime = 0
    self.InvitedTime = 0
end

function XDlcRelinkFriend:UpdateFriendData(data)
    self.Level = data.Level or 0
    self.Name = data.Name or ""
    self.HeadIconId = data.CurrHeadPortraitId or 0
    self.HeadFrameId = data.CurrHeadFrameId or 0
    self.FriendId = data.Id or 0
    self.IsOnline = data.IsOnline or false
    self.TitleId = data.DlcMultiplayerTitle or 0
    self.LastLoginTime = data.LastLoginTime or 0
    self.InvitedTime = self.InvitedTime or 0
end

function XDlcRelinkFriend:GetLevel()
    return self.Level
end

function XDlcRelinkFriend:GetName()
    return self.Name
end
function XDlcRelinkFriend:GetHeadIconId()
    return self.HeadIconId
end

function XDlcRelinkFriend:GetHeadFrameId()
    return self.HeadFrameId
end

function XDlcRelinkFriend:GetFriendId()
    return self.FriendId
end

function XDlcRelinkFriend:GetIsOnline()
    return self.IsOnline
end

function XDlcRelinkFriend:GetTitleId()
    return self.TitleId
end

function XDlcRelinkFriend:GetLastLoginTime()
    return self.LastLoginTime
end

function XDlcRelinkFriend:SetInvitedTime(value)
    self.InvitedTime = value
end

function XDlcRelinkFriend:GetInvitedTime()
    return self.InvitedTime
end

return XDlcRelinkFriend
