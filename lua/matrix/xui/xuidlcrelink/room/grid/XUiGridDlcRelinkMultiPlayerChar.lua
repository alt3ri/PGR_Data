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
            local lockCharacterId = self._Control:GetCurLevelLockCharacter()
            if XTool.IsNumberValid(lockCharacterId) then
                return lockCharacterId
            end
            return self._Control:GetFightCharacterId()
        else
            return 0
        end
    end
end

--endregion

--region 刷新

local function SetActive(panel, active)
    if not XTool.UObjIsNil(panel) then
        panel.gameObject:SetActiveEx(active)
    end
end

function XUiGridDlcRelinkMultiPlayerChar:RefreshState()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    local name = ""
    local isSelf, isCharacterId, isSelfLeader, isLeader, isReady = false, false, false, false, false
    local isLock = self._Control:IsCurLevelLockCharacter()

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

    SetActive(self.PanelCharacterBg, isCharacterId or isSelf)
    SetActive(self.BtnExchange, isInRoom and not isSelf and isSelfLeader and isCharacterId)
    SetActive(self.BtnKick, isInRoom and not isSelf and isSelfLeader and isCharacterId)
    SetActive(self.BtnInfo, (isInRoom or isSelf) and isCharacterId)
    if self.BtnInfo then
        self.BtnInfo:SetNameByGroup(0, name)
    end
    SetActive(self.ImgLeader, isInRoom and isLeader)
    SetActive(self.PanelReady, isInRoom and not isLeader and isCharacterId)
    SetActive(self.ImgReadyOn, isInRoom and isReady)
    SetActive(self.ImgReadyOff, isInRoom and not isReady)
    SetActive(self.GridAdd, (isInRoom or isSelf) and not isCharacterId and not isLock)

    if isSelf and self._IsLeader == false and isLeader then
        self._Control:OpenCommonTipText('BecomeLeaderTips', 1)
    end
    
    self._IsLeader = isLeader
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
    local characterId, styleType, totalAbility = 0, 0, 0
    if isInRoom then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        local member = team and team:GetMember(self.Index)
        characterId = member and member:GetCharacterId()
        styleType = member and member:GetStyleType()
        totalAbility = member and member:GetRelinkEquipTotalAbility()
    else
        characterId = self._Control:GetFightCharacterId()
        styleType = self._Control:GetStyleTypeByCharacterId(characterId)
        totalAbility = self._Control:GetEquipTotalAbilityByCharacterId(characterId)
    end

    if not XTool.IsNumberValid(characterId) then
        return
    end
    -- 职业图标
    local occupationIcon = self._Control:GetCharacterOccupationIcon(characterId, styleType)
    if not string.IsNilOrEmpty(occupationIcon) then
        self.BtnInfo:SetRawImage(occupationIcon)
    end
    -- 装备战力
    self.BtnInfo:SetNameByGroup(1, totalAbility)
    -- 等级限制
    local levelId = self._Control:GetCurrentSelectLevelId()
    local isEnough = true
    if XTool.IsNumberValid(levelId) then
        local abilityLimit = self._Control:GetLevelAbilityLimit(levelId)
        isEnough = totalAbility >= abilityLimit
    end
    SetActive(self.LvNormal, isEnough)
    SetActive(self.LvNotEnough, not isEnough)
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

--- 任何一种方式离开房间时执行
function XUiGridDlcRelinkMultiPlayerChar:RefreshOnRoomLeave()
    self._IsLeader = nil
end

--- 任何一种方式进入房间时执行
function XUiGridDlcRelinkMultiPlayerChar:RefreshBeforeIntoRoom()
    self._IsLeader = nil
end
--endregion

--region UI事件注册

function XUiGridDlcRelinkMultiPlayerChar:RegisterUiEvents()
    self.BtnExchange:AddEventListener(handler(self, self.OnBtnExchangeClick))
    self.BtnKick:AddEventListener(handler(self, self.OnBtnKickClick))
    self.BtnInfo:AddEventListener(handler(self, self.OnBtnInfoClick))
    self.BtnAdd:AddEventListener(handler(self, self.OnBtnAddClick))
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
    --关卡锁定了角色 不允许更换
    if self._Control:IsCurLevelLockCharacter() then
        self._Control:OpenCommonTipText("ForbidSelectRoleTip")
        return
    end

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

    --local selfMember = team:GetSelfMember()
    --if selfMember and selfMember:IsReady() then
    --    self._Control:OpenCommonTipMsg(XUiHelper.GetText("DlcMultiplayerInReady"))
    --    return
    --end

    -- 查看他人角色
    self:OpenOtherRole(member)
end

function XUiGridDlcRelinkMultiPlayerChar:OnBtnAddClick()
    --关卡锁定了角色 不允许更换
    if self._Control:IsCurLevelLockCharacter() then
        self._Control:OpenCommonTipText("ForbidSelectRoleTip")
        return
    end

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
    --[[
    if selfMember and selfMember:IsReady() then
        if not isSelf then
            self._Control:OpenCommonTipMsg(XUiHelper.GetText("DlcMultiplayerInReady"))
            return
        end
    end
    --]]

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
