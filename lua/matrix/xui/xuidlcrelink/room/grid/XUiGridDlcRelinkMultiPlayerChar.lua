local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")
---@class XUiGridDlcRelinkMultiPlayerChar : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkRoom
---@field BtnInfo XUiComponent.XUiButton
local XUiGridDlcRelinkMultiPlayerChar = XClass(XUiNode, "XUiGridDlcRelinkMultiPlayerChar")

function XUiGridDlcRelinkMultiPlayerChar:OnStart(index)
    self.Index = index
    self.RoleModelUi = self.Parent[string.format("PanelRoleModel%s", self.Index)]
    ---@type XUiPanelRoleModel
    self.RoleModel = XUiPanelRoleModel.New(self.RoleModelUi, self.Parent.Name, nil, true)
    self:RegisterUiEvents()
    -- 当前角色Id
    self.CurrentCharacterId = 0
end

function XUiGridDlcRelinkMultiPlayerChar:Refresh()
    self:RefreshState()
    self:RefreshInfo()
    self:RefreshCharacterModel()
end

function XUiGridDlcRelinkMultiPlayerChar:OnDisable()
    self.CurrentCharacterId = 0
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
    if self.CurrentCharacterId == characterId then
        return
    end
    self.CurrentCharacterId = characterId

    if characterId > 0 then
        self.RoleModel:ShowRoleModel()
        local fashionId = XMVCA.XCharacter:GetCharacterTemplate(characterId).DefaultNpcFashtionId
        self.RoleModel:UpdateCharacterModel(characterId, self.RoleModelUi, self.Parent.Name, nil, nil, fashionId, nil, nil, true)
    else
        self.RoleModel:HideRoleModel()
    end
end

function XUiGridDlcRelinkMultiPlayerChar:RefreshInfo()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    local occupationType, totalAbility = 0, 0
    if isInRoom then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        local member = team and team:GetMember(self.Index)
        occupationType = member and member:GetOccupationType()
        totalAbility = member and member:GetRelinkEquipTotalAbility()
    else
        local characterId = self._Control:GetFightCharacterId()
        occupationType = self._Control:GetOccupationTypeByCharacterId(characterId)
        totalAbility = self._Control:GetEquipTotalAbilityByCharacterId(characterId)
    end
    -- 职业图标
    local occupationIcon = self._Control:GetClientConfig("CharacterOccupationIcon", occupationType)
    if not string.IsNilOrEmpty(occupationIcon) then
        self.BtnInfo:SetRawImage(occupationIcon)
    end
    -- 装备战力
    local ability = string.format(self._Control:GetClientConfig("EquipLevelDesc"), totalAbility)
    self.BtnInfo:SetNameByGroup(1, ability)
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
    XUiHelper.RegisterClickEvent(self, self.BtnExchange, self.OnBtnExchangeClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnKick, self.OnBtnKickClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnInfo, self.OnBtnInfoClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnAdd, self.OnBtnAddClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnChat, self.OnBtnChatClick, true, true)
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

    local title = self._Control:GetClientConfig("TipTitle")
    local data = self._Control:GetClientConfigParams("ChangeLeaderConfirmTipContent")
    local content = data[1] or ""
    local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "ChangeLeaderConfirm", }
    self._Control:OpenCommonTipDialog(title, content, nil, function()
        XMVCA.XDlcRoom:ChangeLeader(member:GetPlayerId())
    end, extraData)
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
    self._Control:OpenCommonTipDialog(title, kickOutMessage, nil, function()
        XMVCA.XDlcRoom:KickOut(playerId, function()
            self:Refresh()
        end)
    end, { TipsKey = "DlcRoomKickOut" })
end

function XUiGridDlcRelinkMultiPlayerChar:OnBtnInfoClick()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    if not isInRoom then
        if self.Index == XEnumConst.DlcRelink.DefaultSelfIndex then
            XLuaUiManager.Open("UiDlcRelinkCharacter", self._Control:GetFightCharacterId())
        end
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    if not team then
        return
    end

    local member = team:GetMember(self.Index)
    if member and member:IsSelf() then
        XLuaUiManager.Open("UiDlcRelinkCharacter", member:GetCharacterId())
        return
    end

    local selfMember = team:GetSelfMember()
    if selfMember and selfMember:IsReady() then
        self._Control:OpenCommonTipMsg(XUiHelper.GetText("DlcMultiplayerInReady"))
        return
    end

    -- 查看他人角色
    self:OpenOtherRole(member)
end

function XUiGridDlcRelinkMultiPlayerChar:OnBtnAddClick()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    -- 不在房间: 仅自己可选角色
    if not isInRoom then
        if self.Index == XEnumConst.DlcRelink.DefaultSelfIndex then
            XLuaUiManager.Open("UiDlcRelinkCharacter", self._Control:GetFightCharacterId())
        end
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    if not team then
        return
    end

    local member = team:GetMember(self.Index)
    local selfMember = team:GetSelfMember()
    local isSelf = member and member:IsSelf()

    -- 准备中禁止操作(除自身外)
    if selfMember and selfMember:IsReady() then
        if not isSelf then
            self._Control:OpenCommonTipMsg(XUiHelper.GetText("DlcMultiplayerInReady"))
            return
        end
    end

    local characterId = member and member:GetCharacterId()
    if isSelf then
        XLuaUiManager.Open("UiDlcRelinkCharacter", characterId)
        return
    end

    -- 没有人或没有角色 -> 邀请好友
    if not XTool.IsNumberValid(characterId) then
        self._Control:OpenFriendInviteUi("UiDlcRelinkPopupPlayerInvite")
        return
    end

    -- 查看他人角色
    self:OpenOtherRole(member)
end

function XUiGridDlcRelinkMultiPlayerChar:OnBtnChatClick()
    XLuaUiManager.Open("UiDlcRelinkPopupExchangeWheel")
end

-- 查看他人角色
function XUiGridDlcRelinkMultiPlayerChar:OpenOtherRole(member)
    if member then
        local XDlcMember = require("XModule/XDlcRoom/XEntity/XDlcMember")
        ---@type XDlcMember
        local cloneMember = XDlcMember.New()
        cloneMember:Clone(member)
        XLuaUiManager.Open("UiDlcRelinkCharacterOther", cloneMember)
    end
end

--endregion

return XUiGridDlcRelinkMultiPlayerChar
