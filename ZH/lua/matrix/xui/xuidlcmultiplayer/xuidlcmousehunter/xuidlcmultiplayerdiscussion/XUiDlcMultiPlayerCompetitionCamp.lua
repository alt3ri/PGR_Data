---@class XUiDlcMultiPlayerCompetitionCamp : XUiNode
---@field private _Control XDlcMultiMouseHunterControl

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
        "5e7f6c",
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
    disableGroup = {
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
    if camp == CampEnum.Camp1 then
        self.ColorGroup = LeftColorGroup
    else
        self.ColorGroup = RightColorGroup
    end
    self.TxtDiscussionSupport.text = XUiHelper.GetText("MultiMouseHunterChoice")
    self.BtnSupport:AddEventListener(handler(self, self.OnClickBtnSupport))
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

function XUiDlcMultiPlayerCompetitionCamp:FailStateStyle()
    self.TxtDiscussionRate.color = XUiHelper.Hexcolor2Color(self.ColorGroup.failGroup[1])
    self.TxtDiscussionTitle2.color = XUiHelper.Hexcolor2Color(self.ColorGroup.failGroup[2])
    self.TxtDiscussionTitle.color = XUiHelper.Hexcolor2Color(self.ColorGroup.failGroup[3])
    self.TxtDiscussionReward.color = XUiHelper.Hexcolor2Color(self.ColorGroup.failGroup[4])
    self.TxtDiscussionRewardCount.color = XUiHelper.Hexcolor2Color(self.ColorGroup.failGroup[4])
    
end

function XUiDlcMultiPlayerCompetitionCamp:VoteStateStyle()
    self.TxtDiscussionRate.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[1])
    self.TxtDiscussionTitle2.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[2])
    self.TxtDiscussionTitle.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[3])
    self.TxtDiscussionReward.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[4])
    self.TxtDiscussionRewardCount.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[4])
end

function XUiDlcMultiPlayerCompetitionCamp:SelectStateStyle()
    self.TxtDiscussionRate.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[1])
    self.TxtDiscussionTitle2.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[2])
    self.TxtDiscussionTitle.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[3])
    self.SupportTxt.color = XUiHelper.Hexcolor2Color(self.ColorGroup.selectGroup[4])
    
end

function XUiDlcMultiPlayerCompetitionCamp:NormalStateStyle()
    self.TxtDiscussionRate.color = XUiHelper.Hexcolor2Color(self.ColorGroup.normalGroup[1])
    self.TxtDiscussionTitle2.color = XUiHelper.Hexcolor2Color(self.ColorGroup.normalGroup[2])
    self.TxtDiscussionTitle.color = XUiHelper.Hexcolor2Color(self.ColorGroup.normalGroup[3])
    self.SupportTxt.color = XUiHelper.Hexcolor2Color(self.ColorGroup.normalGroup[4])
end

function XUiDlcMultiPlayerCompetitionCamp:UnSelectStyle()
    self.TxtDiscussionRate.color = XUiHelper.Hexcolor2Color(self.ColorGroup.disableGroup[1])
    self.TxtDiscussionTitle2.color = XUiHelper.Hexcolor2Color(self.ColorGroup.disableGroup[2])
    self.TxtDiscussionTitle.color = XUiHelper.Hexcolor2Color(self.ColorGroup.disableGroup[3])
    self.SupportTxt.color = XUiHelper.Hexcolor2Color(self.ColorGroup.disableGroup[4])

end

function XUiDlcMultiPlayerCompetitionCamp:OnClickBtnSupport()
    if self == self.Parent:GetBlueCamp() then
        self.Parent:GetBlueCamp():PreviewSelected()
        self.Parent:GetRedCamp():PreviewUnSelected()
    else
        self.Parent:GetRedCamp():PreviewSelected()
        self.Parent:GetBlueCamp():PreviewUnSelected()
    end


    --todo刷新样式
end

function XUiDlcMultiPlayerCompetitionCamp:IsPlayerSelectCamp()
    return self._CurCamp == self.Discussion:GetPlayerCamp()
end
function XUiDlcMultiPlayerCompetitionCamp:IsCurCampVictory()
    return (self._CurCamp == CampEnum.Camp1 and self.Discussion:IsPlayerCamp1Vectory()) or
    (self._CurCamp == CampEnum.Camp2 and self.Discussion:IsPlayerCamp2Vectory())
end
function XUiDlcMultiPlayerCompetitionCamp:RefreshUnSelect(discussion)
    self.Discussion = discussion
    local discussionConfig = self.Discussion:GetPlayerTable() or self.Discussion:GetTable()
    self:_SetTitleAndDescByCamp(discussionConfig)
    self:NormalStateStyle()
    self.CtrlDiscussion:ChangeState("VoteNormal")
    -- self.BtnSupport:SetButtonState(CS.UiButtonState.Select)
end

function XUiDlcMultiPlayerCompetitionCamp:RefreshSelected(discussion)
    self.Discussion = discussion
    local discussionConfig = self.Discussion:GetPlayerTable() or self.Discussion:GetTable()
    self:_SetTitleAndDescByCamp(discussionConfig)
    self.BtnSupport.enabled = false
    -- self.BtnSupport:SetDisable(true)
    if self._CurCamp == discussion:GetPlayerCamp() then
        self.CtrlDiscussion:ChangeState("VoteSelected")
        self:SelectStateStyle()
        local str = discussionConfig.Camp1
        if self._CurCamp == CampEnum.Camp2 then
            str = discussionConfig.Camp2
        end
        self.BtnSupport:SetName(XUiHelper.GetText("MultiMouseHunterSubVote",str))
    else
        self.CtrlDiscussion:ChangeState("VoteUnSelected")
        self.BtnSupport:SetDisable(true)
        self:UnSelectStyle()
        self.BtnSupport:SetName(XUiHelper.GetText("MultiMouseHunterSubVoted"))
        self.PanelChoose.gameObject:SetActiveEx(false)
    end
    self:_SetRateByCamp(discussion)
    -- 
end

function XUiDlcMultiPlayerCompetitionCamp:RefreshShow(discussion)
    self.Discussion = discussion
    self.BtnSupport.enabled = false
    self.ImgSupport.gameObject:SetActiveEx(self:IsPlayerSelectCamp())
    self:_SetRewardUi(self:IsCurCampVictory())
    local discussionConfig = self.Discussion:GetPlayerTable() or self.Discussion:GetTable()
    self:_SetTitleAndDescByCamp(discussionConfig)
    if self:IsCurCampVictory() then
        self.CtrlDiscussion:ChangeState("DisplayVictory")
        if discussion:GetPlayerCamp() ~= CampEnum.None then
            self:VoteStateStyle()
        else
            self:NormalStateStyle()
        end
        self:_SetRateByCamp(discussion, "vote")
    else
        self.CtrlDiscussion:ChangeState("DisplayFail")
        if discussion:GetPlayerCamp() ~= CampEnum.None then
            self:FailStateStyle()
        else
            self:NormalStateStyle()
        end
        self:_SetRateByCamp(discussion, "fail")
    end
end

function XUiDlcMultiPlayerCompetitionCamp:PreviewSelected()
    self.CtrlDiscussion:ChangeState("VoteSelect")
    local discussionConfig = self.Discussion:GetPlayerTable() or self.Discussion:GetTable()
    self:_SetTitleAndDescByCamp(discussionConfig)
    self:SelectStateStyle()
    self.BtnSupport:SetDisable(false)
    self.Parent:SetSelectCamp(self._CurCamp)
    local str = discussionConfig.Camp1
    if self._CurCamp == CampEnum.Camp2 then
        str = discussionConfig.Camp2
    end
    self.BtnSupport:SetName(XUiHelper.GetText("MultiMouseHunterSubVote", str))
    self.Parent.BtnVote:SetName(XUiHelper.GetText("MultiMouseHunterVote",str))
    self.Parent.BtnVote:SetDisable(false)
    self.Parent.BtnVote.enabled = true
end
function XUiDlcMultiPlayerCompetitionCamp:PreviewUnSelected()
    self.CtrlDiscussion:ChangeState("VoteUnSelect")
    local discussionConfig = self.Discussion:GetPlayerTable() or self.Discussion:GetTable()
    self:_SetTitleAndDescByCamp(discussionConfig)
    self:UnSelectStyle()
    self.BtnSupport:SetDisable(true)
    self.BtnSupport:SetName(XUiHelper.GetText("MultiMouseHunterSubVoted"))
end


return XUiDlcMultiPlayerCompetitionCamp
