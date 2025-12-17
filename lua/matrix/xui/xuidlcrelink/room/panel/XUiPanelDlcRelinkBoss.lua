---@class XUiPanelDlcRelinkBoss : XUiNode
---@field private _Control XDlcRelinkControl
---@field BtnBoss XUiComponent.XUiButton
local XUiPanelDlcRelinkBoss = XClass(XUiNode, "XUiPanelDlcRelinkBoss")

function XUiPanelDlcRelinkBoss:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnBoss, self.OnBtnBossClick, true)
end

function XUiPanelDlcRelinkBoss:Refresh()
    self.ChapterId = self._Control:GetCurrentSelectChapterId()
    self.LevelId = self._Control:GetCurrentSelectLevelId()
    self:RefreshInfo()
    self:RefreshCareerMatchingTips()
end

function XUiPanelDlcRelinkBoss:RefreshInfo()
    local isHaveBoss = XTool.IsNumberValid(self.ChapterId) and XTool.IsNumberValid(self.LevelId)
    self.PanelLv.gameObject:SetActiveEx(isHaveBoss)
    if isHaveBoss then
        local chapterName = self._Control:GetChapterName(self.ChapterId)
        local levelName = self._Control:GetLevelName(self.LevelId)
        self.BtnBoss:SetNameByGroup(0, string.format("%s-%s", levelName, chapterName))
        local chapterIcon = self._Control:GetChapterIcon(self.ChapterId)
        if not string.IsNilOrEmpty(chapterIcon) then
            self.BtnBoss:SetSprite(chapterIcon)
        end
        local levelLimit = self._Control:GetLevelLevelLimit(self.LevelId)
        self.TxtTitle.gameObject:SetActiveEx(levelLimit > 0)
        self.TxtLv.text = string.format(self._Control:GetClientConfig("RoomBossLevelLimit"), levelLimit)
    else
        self.BtnBoss:SetNameByGroup(0, self._Control:GetClientConfig("RoomBossDefaultName"))
        self.BtnBoss:SetSprite(self._Control:GetClientConfig("RoomBossDefaultBgIcon"))
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

function XUiPanelDlcRelinkBoss:RefreshCareerMatchingTips()
    local isInRoom = XMVCA.XDlcRoom:IsInRoom()
    self.PanelCondition.gameObject:SetActiveEx(false)
    if not isInRoom then
        return
    end
    -- TODO 职业搭配提示
    --1、当队伍职业不满足配置时,需要显示缺少(文本)+缺少的的职业icon(最多2个)
    --2、当队伍职业满足配置,显示【阵容合理】
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
        XUiManager.TipText("MultiplayerRoomOnlyHomeownerTip")
    end
end

return XUiPanelDlcRelinkBoss
