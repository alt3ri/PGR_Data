---@class XUiPanelDlcRelinkBoss : XUiNode
---@field private _Control XDlcRelinkControl
---@field BtnBoss XUiComponent.XUiButton
local XUiPanelDlcRelinkBoss = XClass(XUiNode, "XUiPanelDlcRelinkBoss")

function XUiPanelDlcRelinkBoss:OnStart()
    self.Icon.gameObject:SetActiveEx(false)
    self.BtnBoss:AddEventListener(handler(self, self.OnBtnBossClick))
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

    local isGlobalMatch = self._Control:IsGlobalMatchEnabled()
    if isHaveBoss then
        if self.LevelId == self._Control:GetTeachingLevelId() then
            self.BtnBoss:SetNameByGroup(0, self._Control:GetClientConfig("TutorialLevelName", 1))
        elseif self.LevelId == self._Control:GetTrainingLevelId() then
            self.BtnBoss:SetNameByGroup(0, self._Control:GetClientConfig("TutorialLevelName", 2))
        else
            self.BtnBoss:SetNameByGroup(0, self._Control:GetChapterName(self.ChapterId))
        end
        self.BtnBoss:SetRawImageEx(self._Control:GetChapterRoomIcon(self.ChapterId))
        self:RefreshDifficulty(self._Control:GetLevelDifficulty(self.LevelId))
        self:RefreshAbilityLimitTips()
        self:RefreshCareerMatchingTips()
    else
        self.BtnBoss:SetNameByGroup(1, self._Control:GetClientConfig("ChooseBossBtnName", isGlobalMatch and 2 or 1))
        self:RefreshDifficulty(0)
    end

    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    if isInRoom then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        local isSelfLeader = team and team:IsSelfLeader()
        self.NormalIconChange.gameObject:SetActiveEx(isSelfLeader)
        self.PressIconChange.gameObject:SetActiveEx(isSelfLeader)
    else
        self.NormalIconChange.gameObject:SetActiveEx(not isGlobalMatch)
        self.PressIconChange.gameObject:SetActiveEx(not isGlobalMatch)
    end
end

function XUiPanelDlcRelinkBoss:RefreshDifficulty(levelDifficulty)
    for i = 1, 5 do
        local typeObj = self[string.format("PanelDif0%s", i)]
        if typeObj then
            typeObj.gameObject:SetActiveEx(i == levelDifficulty)
        end
    end
end

function XUiPanelDlcRelinkBoss:RefreshAbilityLimitTips()
    local abilityLimit = self._Control:GetLevelAbilityLimit(self.LevelId)
    self.TxtLv.text = abilityLimit
    self.TxtLvNotEnough.text = abilityLimit

    local isEquipAbilityRational = self:IsEquipAbilityRational(abilityLimit)
    local isLimitValid = abilityLimit > 0

    self.TxtTitle.gameObject:SetActiveEx(isLimitValid and isEquipAbilityRational)
    self.TxtTitleNotEnough.gameObject:SetActiveEx(isLimitValid and not isEquipAbilityRational)
end

function XUiPanelDlcRelinkBoss:IsEquipAbilityRational(abilityLimit)
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    if isInRoom then
        local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
        return self._Control:CheckTeamEquipAbilityRational(team, abilityLimit)
    else
        local characterId = self._Control:GetFightCharacterId()
        local totalAbility = self._Control:GetEquipTotalAbilityByCharacterId(characterId)
        return totalAbility >= abilityLimit
    end
end

function XUiPanelDlcRelinkBoss:RefreshCareerMatchingTips()
    self.PanelCondition.gameObject:SetActiveEx(false)

    if not XMVCA.XDlcRoom:IsInRoom() then
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    if not team then
        return
    end

    self.PanelCondition.gameObject:SetActiveEx(true)
    local isSuccess, lackOccupationList = self._Control:CheckTeamOccupationRational(team, self.ChapterId)

    self.TxtRational.gameObject:SetActiveEx(isSuccess)
    self.PanelMiss.gameObject:SetActiveEx(not isSuccess)

    if isSuccess then
        return
    end

    for index, occupationType in ipairs(lackOccupationList) do
        local grid = self.OccupationGridList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.Icon, self.PanelMiss)
            self.OccupationGridList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local occupationIcon = self._Control:GetClientConfig("CharacterOccupationIconTwo", occupationType) or ""
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

-- 刷新红点
function XUiPanelDlcRelinkBoss:RefreshRedPoint()
    local isShowRedPoint = XMVCA.XDlcRelink:CheckAllLevelHasNewUnlock()
    self.BtnBoss:ShowReddot(isShowRedPoint)
end

function XUiPanelDlcRelinkBoss:OnBtnBossClick()
    if not self._Control:IsTeachingLevelPass() then
        self._Control:OpenCommonTipText("FirstPlayTeachingLevelTip")
        return
    end

    if not XMVCA.XDlcRoom:IsInRoom() then
        if self._Control:IsGlobalMatchEnabled() then
            self._Control:OpenCommonTipText("GlobalMatchDisableChooseBossTip")
            return
        end
        self:OpenChooseBoss()
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    if team and team:IsSelfLeader() then
        self:OpenChooseBoss()
    else
        self._Control:OpenCommonTipMsg(XUiHelper.GetText("MultiplayerRoomOnlyHomeownerTip"))
    end
end

function XUiPanelDlcRelinkBoss:OpenChooseBoss()
    if self._Control:IsTutorialChapter() then
        --教学关不在界面显示 所以重置下当前选择关卡的信息
        self._Control:SetCurrentSelectLevelData()
    end
    XLuaUiManager.Open("UiDlcRelinkChooseBoss")
end

return XUiPanelDlcRelinkBoss
