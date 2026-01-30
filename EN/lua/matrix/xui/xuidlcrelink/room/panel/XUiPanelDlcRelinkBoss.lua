---@class XUiPanelDlcRelinkBoss : XUiNode
---@field private _Control XDlcRelinkControl
---@field BtnBoss XUiComponent.XUiButton
local XUiPanelDlcRelinkBoss = XClass(XUiNode, "XUiPanelDlcRelinkBoss")

function XUiPanelDlcRelinkBoss:OnStart()
    self.Icon.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnBoss, self.OnBtnBossClick, true, true)
    ---@type UiObject[]
    self.OccupationGridList = {}
end

function XUiPanelDlcRelinkBoss:Refresh()
    self.ChapterId = self._Control:GetCurrentSelectChapterId()
    self.LevelId = self._Control:GetCurrentSelectLevelId()
    self:RefreshInfo()
    self:RefreshRedPoint()
end

function XUiPanelDlcRelinkBoss:RefreshInfo()
    local isHaveBoss = XTool.IsNumberValid(self.ChapterId) and XTool.IsNumberValid(self.LevelId)
    self.PanelLv.gameObject:SetActiveEx(isHaveBoss)
    self.PanelChooseNormal.gameObject:SetActiveEx(isHaveBoss)
    self.PanelNotChooseNormal.gameObject:SetActiveEx(not isHaveBoss)
    self.PanelChoosePress.gameObject:SetActiveEx(isHaveBoss)
    self.PanelNotChoosePress.gameObject:SetActiveEx(not isHaveBoss)

    if isHaveBoss then
        self.BtnBoss:SetNameByGroup(0, self._Control:GetChapterName(self.ChapterId))
        self.BtnBoss:SetRawImageEx(self._Control:GetChapterRoomIcon(self.ChapterId))
        self:RefreshType(self._Control:GetLevelType(self.LevelId))

        local levelLimit = self._Control:GetLevelLevelLimit(self.LevelId)
        self.TxtTitle.gameObject:SetActiveEx(levelLimit > 0)
        self.TxtLv.text = string.format(self._Control:GetClientConfig("RoomBossLevelLimit"), levelLimit)

        self:RefreshCareerMatchingTips()
    else
        self:RefreshType(0)
    end

    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    local isSelfLeader = false
    if isInRoom then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        isSelfLeader = team and team:IsSelfLeader()
    end
    self.NormalIconChange.gameObject:SetActiveEx(not isInRoom or isSelfLeader)
    self.PressIconChange.gameObject:SetActiveEx(not isInRoom or isSelfLeader)
end

function XUiPanelDlcRelinkBoss:RefreshType(levelType)
    for i = 1, 4 do
        local typeObj = self[string.format("PanelDif0%s", i)]
        if typeObj then
            typeObj.gameObject:SetActiveEx(i == levelType)
        end
    end
end

function XUiPanelDlcRelinkBoss:RefreshCareerMatchingTips()
    self.PanelCondition.gameObject:SetActiveEx(false)
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    if not isInRoom then
        return
    end
    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    if not team then
        return
    end

    self.PanelCondition.gameObject:SetActiveEx(true)
    local occupationMap = {}
    local amount = team:GetMemberNumber()
    for pos = 1, amount do
        local member = team:GetMember(pos)
        if member then
            occupationMap[member:GetOccupationType()] = true
        end
    end

    local trueOccupationList = self._Control:GetChapterTrueOccupations(self.ChapterId)
    local isSuccess = true
    local lackOccupationList = {}
    for _, occupation in ipairs(trueOccupationList) do
        if not occupationMap[occupation] then
            isSuccess = false
            table.insert(lackOccupationList, occupation)
        end
    end

    self.TxtRational.gameObject:SetActiveEx(isSuccess)
    self.PanelMiss.gameObject:SetActiveEx(not isSuccess)
    if not isSuccess then
        for index, occupation in ipairs(lackOccupationList) do
            local grid = self.OccupationGridList[index]
            if not grid then
                grid = XUiHelper.Instantiate(self.Icon, self.PanelMiss)
                self.OccupationGridList[index] = grid
            end

            grid.gameObject:SetActiveEx(true)
            local occupationIcon = self._Control:GetClientConfig("CharacterOccupationIcon", occupation) or ""
            grid:GetObject("RawImage"):SetRawImageEx(occupationIcon)
            grid.transform:SetAsLastSibling()
        end

        for i = #lackOccupationList + 1, #self.OccupationGridList do
            local grid = self.OccupationGridList[i]
            if grid then
                grid.gameObject:SetActiveEx(false)
            end
        end
    end
end

-- 刷新红点
function XUiPanelDlcRelinkBoss:RefreshRedPoint()
    local isShowRedPoint = XMVCA.XDlcRelink:CheckAllLevelHasNewUnlock()
    self.BtnBoss:ShowReddot(isShowRedPoint)
end

function XUiPanelDlcRelinkBoss:OnBtnBossClick()
    if not XMVCA.XDlcRoom:IsInRoom() then
        XLuaUiManager.Open("UiDlcRelinkChooseBoss")
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    if team and team:IsSelfLeader() then
        XLuaUiManager.Open("UiDlcRelinkChooseBoss")
    else
        self._Control:OpenCommonTipMsg(XUiHelper.GetText("MultiplayerRoomOnlyHomeownerTip"))
    end
end

return XUiPanelDlcRelinkBoss
