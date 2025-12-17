local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
---@class XUiGridDlcRelinkMultiPlayerChar : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkRoom
local XUiGridDlcRelinkMultiPlayerChar = XClass(XUiNode, "XUiGridDlcRelinkMultiPlayerChar")

function XUiGridDlcRelinkMultiPlayerChar:OnStart(index)
    self.Index = index
    self.RoleModelUi = self.Parent.UiModelGo.transform:FindTransform(string.format("PanelRoleModel%s", self.Index))
    ---@type XUiPanelRoleModel
    self.RoleModel = XUiPanelRoleModel.New(self.RoleModelUi, self.Parent.Name, nil, true)
    self:RegisterUiEvents()
end

function XUiGridDlcRelinkMultiPlayerChar:Refresh()
    self:RefreshState()
    self:RefreshCharacterModel()
end

function XUiGridDlcRelinkMultiPlayerChar:OnDisable()
    self.RoleModel:HideRoleModel()
    self:StopChatTimer()
end

--region 获取数据

function XUiGridDlcRelinkMultiPlayerChar:GetPlayerId()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    if isInRoom then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        local member = team and team:GetMember(self.Index)
        return member and member:GetPlayerId() or 0
    else
        if self.Index == XEnumConst.DlcRelink.DefaultSelfIndex then
            return XPlayer.Id
        else
            return 0
        end
    end
end

function XUiGridDlcRelinkMultiPlayerChar:GetCharacterId()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    if isInRoom then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        local member = team and team:GetMember(self.Index)
        return member and member:GetCharacterId() or 0
    else
        if self.Index == XEnumConst.DlcRelink.DefaultSelfIndex then
            return self._Control:GetFightCharacterId()
        else
            return 0
        end
    end
end

--endregion

--region 刷新

local function SetActive(go, active)
    if go and go.SetActiveEx then
        go:SetActiveEx(active)
    end
end

function XUiGridDlcRelinkMultiPlayerChar:RefreshState()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    local name = ""
    local isSelf, isCharacterId, isSelfLeader, isLeader, isReady = false, false, false, false, false

    if isInRoom then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        local member = team and team:GetMember(self.Index)
        isSelfLeader = team and team:IsSelfLeader()
        isSelf = member and member:IsSelf()
        isLeader = member and member:IsLeader()
        isReady = member and member:IsReady()
        isCharacterId = member and member:GetCharacterId() > 0
        name = member and member:GetName() or ""
    else
        isSelf = self.Index == XEnumConst.DlcRelink.DefaultSelfIndex
        isCharacterId = isSelf and self._Control:GetFightCharacterId() > 0
        name = isSelf and XPlayer.Name or ""
    end

    SetActive(self.PanelCharacterBg.gameObject, isCharacterId or isSelf)
    SetActive(self.PanelCountDown.gameObject, false)
    SetActive(self.BtnExchange.gameObject, isInRoom and not isSelf and isSelfLeader and isCharacterId)
    SetActive(self.BtnKick.gameObject, isInRoom and not isSelf and isSelfLeader and isCharacterId)
    SetActive(self.BtnChat.gameObject, isSelf and isCharacterId)
    SetActive(self.BtnInfo.gameObject, (isInRoom or isSelf) and isCharacterId)
    if self.BtnInfo then
        self.BtnInfo:SetButtonState(isSelf and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
        self.BtnInfo:SetNameByGroup(0, name)
    end
    SetActive(self.ImgLeader.gameObject, isInRoom and isLeader)
    SetActive(self.PanelReady.gameObject, isInRoom and not isLeader and isCharacterId)
    SetActive(self.ImgReadyOn.gameObject, isInRoom and isReady)
    SetActive(self.ImgReadyOff.gameObject, isInRoom and not isReady)
    SetActive(self.GridAdd.gameObject, (isInRoom or isSelf) and not isCharacterId)
end

function XUiGridDlcRelinkMultiPlayerChar:RefreshCharacterModel()
    local characterId = self:GetCharacterId()
    if characterId > 0 then
        self:RefreshInfo(characterId)
        self.RoleModel:ShowRoleModel()
        self.RoleModel:UpdateCharacterModel(characterId, self.RoleModelUi, self.Parent.Name, nil, nil)
    else
        self.RoleModel:HideRoleModel()
    end
end

function XUiGridDlcRelinkMultiPlayerChar:RefreshInfo(characterId)
    -- 职业图标
    local occupationIcon = self._Control:GetOccupationIconByCharacterId(characterId)
    if not string.IsNilOrEmpty(occupationIcon) then
        self.Image:SetRawImage(occupationIcon)
    end
    -- 装备等级 TODO
end

function XUiGridDlcRelinkMultiPlayerChar:RefreshChat(chatData, receiveTime)
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
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
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

function XUiGridDlcRelinkMultiPlayerChar:StopChatTimer()
    if self.ChatTimer then
        XScheduleManager.UnSchedule(self.ChatTimer)
        self.ChatTimer = nil
    end
end

--endregion

--region UI事件注册

function XUiGridDlcRelinkMultiPlayerChar:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnExchange, self.OnBtnExchangeClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnKick, self.OnBtnKickClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnInfo, self.OnBtnInfoClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnChat, self.OnBtnChatClick, true)
end

function XUiGridDlcRelinkMultiPlayerChar:OnBtnExchangeClick()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    if not isInRoom then
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    local selfMember = team and team:GetSelfMember()
    if not selfMember or not selfMember:IsLeader() then
        return
    end

    local member = team and team:GetMember(self.Index)
    if not member or member:IsSelf() then
        return
    end

    --转移队长 TODO 需要二次确认弹框
    XMVCA.XDlcRoom:ChangeLeader(member:GetPlayerId())
end

function XUiGridDlcRelinkMultiPlayerChar:OnBtnKickClick()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    if not isInRoom then
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    local isSelfLeader = team and team:IsSelfLeader()
    if not isSelfLeader then
        return
    end

    local member = team and team:GetMember(self.Index)
    if not member or member:IsSelf() then
        return
    end

    local playerId = member:GetPlayerId()
    local title = XUiHelper.GetText("TipTitle")
    local kickOutMessage = XUiHelper.GetText("DlcRoomKickOutTip")
    XUiManager.DialogTip(title, kickOutMessage, XUiManager.DialogType.Normal, nil, function()
        XMVCA.XDlcRoom:KickOut(playerId, function()
            self:Refresh()
        end)
    end)
end

function XUiGridDlcRelinkMultiPlayerChar:OnBtnInfoClick()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    if not isInRoom then
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    local member = team and team:GetMember(self.Index)
    if not member or member:IsSelf() then
        return
    end

    local selfMember = team and team:GetSelfMember()
    if selfMember and selfMember:IsReady() then
        XUiManager.TipText("DlcMultiplayerInReady")
        return
    end

    -- TODO 临时处理 正式的需要打开角色详情界面
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(member:GetPlayerId())
end

function XUiGridDlcRelinkMultiPlayerChar:OnBtnAddClick()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    if isInRoom then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        local member = team and team:GetMember(self.Index)
        local selfMember = team and team:GetSelfMember()
        local isSelf = member and member:IsSelf()
        if selfMember and selfMember:IsReady() then
            if not isSelf then
                XUiManager.TipText("DlcMultiplayerInReady")
            end
            return
        end

        local characterId = member and member:GetCharacterId()
        if isSelf then
            XLuaUiManager.Open("UiDlcRelinkCharacter", characterId)
        else
            if not XTool.IsNumberValid(characterId) then
                self._Control:OpenFriendInviteUi("UiDlcRelinkPopupPlayerInvite")
            else
                -- TODO 打开角色详情界面
            end
        end
    elseif self.Index == XEnumConst.DlcRelink.DefaultSelfIndex then
        local characterId = self._Control:GetFightCharacterId()
        XLuaUiManager.Open("UiDlcRelinkCharacter", characterId)
    end
end

function XUiGridDlcRelinkMultiPlayerChar:OnBtnChatClick()
    -- TODO 打开交换轮盘
end

--endregion

return XUiGridDlcRelinkMultiPlayerChar
