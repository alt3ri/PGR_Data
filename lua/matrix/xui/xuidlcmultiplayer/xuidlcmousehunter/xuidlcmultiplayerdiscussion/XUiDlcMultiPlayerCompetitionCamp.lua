---@class XUiDlcMultiPlayerCompetitionCamp : XUiNode
---@field private _Control XDlcMultiMouseHunterControl
---@field CtrlDiscussion XUiComponent.XUiStateControl
local XUiDlcMultiPlayerCompetitionCamp = XClass(XUiNode, "XUiDlcMultiPlayerCompetitionCamp")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionCamp
local LeftColorGroup = {
    normalGroup = {
        "f0ebcf",
        "90dbaf",
        "fff9e8",
        "ebe4d6"
    },
    disableGroup = {
        "908e82",
        "5e7fbc",
        "9a9790",
        "8e8b85"
    },
    selectGroup = {
        "f0ebcf",
        "90dbaf",
        "a2f5c5",
        "ebe4d6"
    },
    failGroup = {
        "f0ebcf",
        "90dbaf",
        "fff9e8",
        "ebe4d6"
    }

}
local RightColorGroup = {
    normalGroup = {
        "f0ebcf",
        "fcd3a8",
        "fff9e8",
        "ebe4d6"
    },
    diableGroup = {
        "96907f",
        "9c8266",
        "9e9a90",
        "918d84"
    },
    selectGroup = {
        "f3eace",
        "fcd3a8",
        "ffe18f",
        "ebe4d6"
    },
    failGroup = {
        "f3eace",
        "fcd3a8",
        "fff9e9",
        "ebe4d6"
    }

}
function XUiDlcMultiPlayerCompetitionCamp:OnStart(camp)
    self._CurCamp = camp
    if camp == 1 then
        self.ColorGroup = LeftColorGroup
    else
        self.ColorGroup = RightColorGroup
    end
    self.TxtDiscussionSupport.text = XUiHelper.GetText("MultiMouseHunterChoice")

    self.TxtDiscussionRate.color = XUiHelper.Hexcolor2Color(self.ColorGroup.normalGroup[1])
    self.TxtDiscussionTitle2.color = XUiHelper.Hexcolor2Color(self.ColorGroup.normalGroup[2])
    self.TxtDiscussionTitle.color = XUiHelper.Hexcolor2Color(self.ColorGroup.normalGroup[3])
    self.SupportTxt.color = XUiHelper.Hexcolor2Color(self.ColorGroup.normalGroup[4])
end

-- 根据阵营设置标题和描述
---@param config XTableDlcMultiplayerDiscussion
function XUiDlcMultiPlayerCompetitionCamp:_SetTitleAndDescByCamp(config)
    if self._CurCamp == CampEnum.Camp1 then
        self.TxtDiscussionTitle.text = config.Camp1
        self.TxtDiscussionTitle2.text = config.Camp1Des
    elseif self._CurCamp == CampEnum.Camp2 then
        self.TxtDiscussionTitle.text = config.Camp2
        self.TxtDiscussionTitle2.text = config.Camp2Des
    else
        self.TxtDiscussionTitle.text = ""
        self.TxtDiscussionTitle2.text = ""
    end
end

-- 根据阵营和模式设置比率文本
---@param discussion XDlcMultiMouseHunterDiscussion
---@param mode string "vote" or "fail"
function XUiDlcMultiPlayerCompetitionCamp:_SetRateByCamp(discussion, mode)
    if self._CurCamp == CampEnum.Camp1 then
        if mode == "vote" then
            self.TxtDiscussionRate.text = discussion:IsStatistics() and XUiHelper.GetText("MultiMouseHunterStatistics") or
                discussion:GetCamp1RatioStr()
        else
            -- "fail"
            self.TxtDiscussionRate.text = discussion:GetPlayerCamp1RatioStr()
        end
    elseif self._CurCamp == CampEnum.Camp2 then
        if mode == "vote" then
            self.TxtDiscussionRate.text = discussion:IsStatistics() and XUiHelper.GetText("MultiMouseHunterStatistics") or
                discussion:GetCamp2RatioStr()
        else
            -- "fail"
            self.TxtDiscussionRate.text = discussion:GetPlayerCamp2RatioStr()
        end
    else
        self.TxtDiscussionRate.text = ""
    end
end

-- 设置标题样式（颜色、轮廓、引号）
function XUiDlcMultiPlayerCompetitionCamp:_ApplyTitleStyle(isSelected, addQuotes, mode)
    if not mode then
        if isSelected then
            self.TxtDiscussionRate.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[1])
            self.TxtDiscussionTitle2.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[2])
            self.TxtDiscussionTitle.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[3])
            self.SupportTxt.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[4])
        else
            self.TxtDiscussionRate.color = XUiHelper.Hexcolor2Color(self.ColorGroup.disableGroup[1])
            self.TxtDiscussionTitle2.color = XUiHelper.Hexcolor2Color(self.ColorGroup.disableGroup[2])
            self.TxtDiscussionTitle.color = XUiHelper.Hexcolor2Color(self.ColorGroup.disableGroup[3])
            self.SupportTxt.color = XUiHelper.Hexcolor2Color(self.ColorGroup.disableGroup[4])
        end
    end

    if mode == "fail" then
        self.TxtDiscussionRate.color = XUiHelper.Hexcolor2Color(self.ColorGroup.failGroup[1])
        self.TxtDiscussionTitle2.color = XUiHelper.Hexcolor2Color(self.ColorGroup.failGroup[2])
        self.TxtDiscussionTitle.color = XUiHelper.Hexcolor2Color(self.ColorGroup.failGroup[3])
        self.TxtDiscussionReward.color = XUiHelper.Hexcolor2Color(self.ColorGroup.failGroup[4])
        self.TxtDiscussionRewardCount.color = XUiHelper.Hexcolor2Color(self.ColorGroup.failGroup[4])
    elseif mode == "vote" then
        self.TxtDiscussionRate.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[1])
        self.TxtDiscussionTitle2.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[2])
        self.TxtDiscussionTitle.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[3])
        self.TxtDiscussionReward.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[4])
        self.TxtDiscussionRewardCount.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[4])
    end
    if addQuotes then
        self.TxtDiscussionTitle.text = string.format("“%s”", self.TxtDiscussionTitle.text)
    end
end

-- 设置奖励UI
function XUiDlcMultiPlayerCompetitionCamp:_SetRewardUi(isVictory)
    local activityConfig = self._Control:GetDlcMultiplayerActivityConfig()
    local bpExpIcon = XDataCenter.ItemManager.GetItemIcon(activityConfig.BpExpItem)
    self.ImgDiscussionRewardIcon:SetRawImage(bpExpIcon)

    if isVictory then
        self.TxtDiscussionReward.text = XUiHelper.GetText("MultiMouseHunterVoteVictoryGet")
        self.TxtDiscussionRewardCount.text = "*" .. tostring(activityConfig.DiscussionWinExp)
    else
        self.TxtDiscussionReward.text = XUiHelper.GetText("MultiMouseHunterVoteFailGet")
        self.TxtDiscussionRewardCount.text = "*" .. tostring(activityConfig.DiscussionFailExp)
    end
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:VoteUnSelect(discussion)
    self.CtrlDiscussion:ChangeState("VoteUnSelect")
    self:_SetTitleAndDescByCamp(discussion:GetTable())

    self:_ApplyTitleStyle(false)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:VoteUnSelect_Select(discussion)
    self.CtrlDiscussion:ChangeState("VoteUnSelect")
    self:_SetTitleAndDescByCamp(discussion:GetTable())

    self:_ApplyTitleStyle(true)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:VoteUnSelect_UnSelect(discussion)
    self.CtrlDiscussion:ChangeState("VoteUnSelect")
    self:_SetTitleAndDescByCamp(discussion:GetTable())
    self:_ApplyTitleStyle(false, true)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:VoteSelect(discussion)
    self.CtrlDiscussion:ChangeState("VoteSelect")

    self:_SetTitleAndDescByCamp(discussion:GetTable())
    self:_SetRateByCamp(discussion, "vote")

    local isSelected = self._CurCamp == discussion:GetPlayerCamp()
    self:_ApplyTitleStyle(isSelected, not isSelected, "vote")
    self.ImgSupport.gameObject:SetActiveEx(isSelected)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:DisplayVictory(discussion)
    self.CtrlDiscussion:ChangeState("DisplayVictory")

    self:_SetRewardUi(true)
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()

    if self._CurCamp == CampEnum.Camp1 then
        self.TxtDiscussionTitle.text = discussionConfig.Camp1
        self.TxtDiscussionRate.text = discussion:GetPlayerCamp1RatioStr()
        self.TxtDiscussionVictory.text = XUiHelper.GetText("MultiMouseHunterVoteVictory", discussionConfig.Camp1)
    elseif self._CurCamp == CampEnum.Camp2 then
        self.TxtDiscussionTitle.text = discussionConfig.Camp2
        self.TxtDiscussionRate.text = discussion:GetPlayerCamp2RatioStr()
        self.TxtDiscussionVictory.text = XUiHelper.GetText("MultiMouseHunterVoteVictory", discussionConfig.Camp2)
    else
        self.TxtDiscussionTitle.text = ""
        self.TxtDiscussionRate.text = ""
        self.TxtDiscussionVictory.text = ""
    end

    self:_ApplyTitleStyle(true, false)
    self.ImgSupport.gameObject:SetActiveEx(self._CurCamp == discussion:GetPlayerCamp())
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetitionCamp:DisplayFail(discussion)
    self.CtrlDiscussion:ChangeState("DisplayFail")

    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    self:_SetRewardUi(false)
    self:_SetTitleAndDescByCamp(discussionConfig)
    self:_SetRateByCamp(discussion, "fail")
    self:_ApplyTitleStyle(false, true, "fail")
    self.ImgSupport.gameObject:SetActiveEx(self._CurCamp == discussion:GetPlayerCamp())
end

return XUiDlcMultiPlayerCompetitionCamp
