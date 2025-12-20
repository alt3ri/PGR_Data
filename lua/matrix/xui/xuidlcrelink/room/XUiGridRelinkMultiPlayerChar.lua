local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
---@class XUiGridRelinkMultiPlayerChar : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiRelinkPlayerRoom
local XUiGridRelinkMultiPlayerChar = XClass(XUiNode, "XUiGridRelinkMultiPlayerChar")

---@param team XDlcTeam
function XUiGridRelinkMultiPlayerChar:OnStart(team, index, case)
    self.Team = team
    self.Index = index

    ---@type XUiPanelRoleModel
    self.RoleModel = XUiPanelRoleModel.New(case, self.Parent.Name, nil, true)
    self:RegisterUiEvents()
end

function XUiGridRelinkMultiPlayerChar:Refresh()
    if self:IsEmpty() then
        return
    end

    local member = self:GetMember()
    local characterId = member:GetCharacterId()
    local isSelf = member:IsSelf()
    local isLeader = member:IsLeader()

    self.BtnInfo.gameObject:SetActiveEx(true)
    self.BtnInfo:SetButtonState(isSelf and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    self.BtnInfo:SetNameByGroup(0, member:GetName())
    self.BtnKick.gameObject:SetActiveEx(not isSelf and self.Team:IsSelfLeader())
    self.BtnExchange.gameObject:SetActiveEx(isSelf)
    self.ImgView.gameObject:SetActiveEx(not isSelf)
    self.ImgMedalIcon.gameObject:SetActiveEx(isLeader)
    if member:IsSelecting() then
        self.ImgReady.gameObject:SetActiveEx(false)
        self.ImgModifying.gameObject:SetActiveEx(true)
    elseif member:IsReady() or isLeader then
        self.ImgReady.gameObject:SetActiveEx(true)
        self.ImgModifying.gameObject:SetActiveEx(false)
    else
        self.ImgReady.gameObject:SetActiveEx(false)
        self.ImgModifying.gameObject:SetActiveEx(true)
    end

    self:RefreshModel(characterId)
end

function XUiGridRelinkMultiPlayerChar:OnDisable()
    self.RoleModel:HideRoleModel()
    self:StopChatTimer()
end

function XUiGridRelinkMultiPlayerChar:IsEmpty()
    local member = self:GetMember()
    return not member or member:IsEmpty() or not self:IsNodeShow()
end

function XUiGridRelinkMultiPlayerChar:GetMember()
    if self.Team and self.Index then
        return self.Team:GetMember(self.Index)
    end
    return nil
end

function XUiGridRelinkMultiPlayerChar:RefreshModel(characterId)
    self.RoleModel:ShowRoleModel()
    self.RoleModel:UpdateCharacterModel(characterId, nil, self.Parent.Name, nil, nil)
end

function XUiGridRelinkMultiPlayerChar:RefreshChat(chatData, receiveTime)
    local isEmoji = chatData.MsgType == ChatMsgType.Emoji
    local nowTime = XTime.GetServerNowTimestamp()
    local leftTime = (receiveTime or nowTime) + XFubenConfigs.ROOM_WORLD_TIME - nowTime

    self:StopChatTimer()
    if leftTime > 0 then
        if isEmoji then
            local icon = XDataCenter.ChatManager.GetEmojiIcon(chatData.Content)
            self.RImgEmoji:SetRawImage(icon)
        else
            self.TxtDesc.text = chatData.Content or ""
        end

        self.ChatTimer = XScheduleManager.ScheduleOnce(function()
            self.ChatTimer = nil
            self.PanelChat.gameObject:SetActiveEx(false)
        end, XScheduleManager.SECOND * leftTime)

        self.PanelChat.gameObject:SetActiveEx(true)
        self.PanelDailog.gameObject:SetActiveEx(not isEmoji)
        self.PanelEmoji.gameObject:SetActiveEx(isEmoji)
        self.PanelChatEnable:PlayTimelineAnimation()
    else
        self.PanelChat.gameObject:SetActiveEx(false)
    end
end

function XUiGridRelinkMultiPlayerChar:StopChatTimer()
    if self.ChatTimer then
        XScheduleManager.UnSchedule(self.ChatTimer)
        self.ChatTimer = nil
    end
end

--region 按钮相关

function XUiGridRelinkMultiPlayerChar:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnExchange, self.OnBtnExchangeClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnKick, self.OnBtnKickClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnInfo, self.OnBtnInfoClick, true, true)
end

function XUiGridRelinkMultiPlayerChar:OnBtnExchangeClick()
    local member = self:GetMember()
    if not member or member:IsEmpty() then
        return
    end
    XLuaUiManager.Open("UiRelinkPopupChooseCharacter", member:GetCharacterId())
end

function XUiGridRelinkMultiPlayerChar:OnBtnKickClick()
    local selfMember = self.Team and self.Team:GetSelfMember()
    if not (selfMember and selfMember:IsLeader()) then
        return
    end

    local member = self:GetMember()
    if not member then
        return
    end

    local playerId = member:GetPlayerId()
    local title = XUiHelper.GetText("TipTitle")
    local kickOutMessage = XUiHelper.GetText("DlcRoomKickOutTip")
    XUiManager.DialogTip(title, kickOutMessage, XUiManager.DialogType.Normal, nil, function()
        XMVCA.XDlcRoom:KickOut(playerId, Handler(self, self.Close))
    end)
end

function XUiGridRelinkMultiPlayerChar:OnBtnInfoClick()
    local member = self:GetMember()
    if not member or member:IsSelf() then
        return
    end

    local selfMember = self.Team and self.Team:GetSelfMember()
    if selfMember and selfMember:IsReady() then
        XUiManager.TipText("DlcMultiplayerInReady")
        return
    end

    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(member:GetPlayerId())
end

--endregion

return XUiGridRelinkMultiPlayerChar
