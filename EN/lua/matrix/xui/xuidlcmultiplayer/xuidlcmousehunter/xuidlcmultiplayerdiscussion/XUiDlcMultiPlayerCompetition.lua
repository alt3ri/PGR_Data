local XUiDlcMultiPlayerCompetitionCamp = require(
    "XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerDiscussion/XUiDlcMultiPlayerCompetitionCamp")
local XUiDlcMultiPlayerCompetitionBulletChat = require(
    "XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerDiscussion/XUiDlcMultiPlayerCompetitionBulletChat")
---@class XUiDlcMultiPlayerCompetition : XLuaUi
---@field private _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerCompetition = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerCompetition")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionCamp
local StatusEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionStatus


function XUiDlcMultiPlayerCompetition:OnAwake()
    self:RegisterUiEvents()
end

function XUiDlcMultiPlayerCompetition:OnStart()
    ---@type XUiDlcMultiPlayerCompetitionCamp
    self._BlueCamp = XUiDlcMultiPlayerCompetitionCamp.New(self.BlueCampPanel, self, CampEnum.Camp1)
    ---@type XUiDlcMultiPlayerCompetitionCamp
    self._RedCamp = XUiDlcMultiPlayerCompetitionCamp.New(self.RedCampPanel, self, CampEnum.Camp2)
    self._ClickCount = 0
    self._CurShowDiscussionStatus = nil -- 当前界面显示的状态
    self:_SpecialkGetReward(function ()
        self:Refresh()
    end)
    
end

function XUiDlcMultiPlayerCompetition:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA
    }
end

function XUiDlcMultiPlayerCompetition:OnNotify(event, ...)
    if event == XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA then
        -- 展示期时不刷新界面（无论是否跨期）
        if self._CurShowDiscussionStatus == StatusEnum.Show then
            return
        end
        self:Refresh()
    end
end

function XUiDlcMultiPlayerCompetition:Refresh()
    if self._Control == nil then
        return
    end
    local discussion = self._Control:GetDiscussion()
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    local discussionStatus = discussion:IsSameDiscussion() and discussion:GetStatus() or StatusEnum.Show
    self:_RemoveDiscussionTimer()

    -- 记录当前界面显示的状态
    self._CurShowDiscussionStatus = discussionStatus

    self.TxtTitle.text = discussionConfig.Discussion
    self.TxtTime.text = ""
    local discussionPlayerCamp = discussion:GetPlayerCamp()
    if discussionStatus == StatusEnum.Vote then
        --投票期
        if discussionPlayerCamp == CampEnum.None then
            --未选择阵营
            self:RefreshUnSelect(discussion)
        else
            --已经选择阵营
            self:RefreshSelected(discussion)
        end
    elseif discussionStatus == StatusEnum.Show then
        --展示期
        self:RefreshShow(discussion)
        self:_CheckGetReward()
    else
        self:Close()
    end

    -- 弹幕
    self:_RefreshBulletChat(discussion)
end

function XUiDlcMultiPlayerCompetition:RefreshUnSelect(discussion)
    self.TxtDiscussionVictory.transform.parent.gameObject:SetActiveEx(false)
    self.TxtBpTips.text = XUiHelper.GetText("MultiMouseHunterVoteBP", self._Control:GetBpLevel())
    self._BlueCamp:RefreshUnSelect(discussion)
    self._RedCamp:RefreshUnSelect(discussion)
    self.BtnVote:SetName(XUiHelper.GetText("MultiMouseHunterVoteUnSelect"))
    self.BtnVote:SetDisable(true)
    self.BtnVote.enabled = false
    -- self:_RefreshSelectCamp(self._CurSelectCamp, true, XUiHelper.GetText("MultiMouseHunterUnVote"),
    --     )
    self:_RemoveDiscussionTimer()
    self:_RefreshTxtDiscussionTime(discussion:GetVoteEndTimestamp())
    self._DiscussionTimer = XScheduleManager.ScheduleForever(function()
        self:_RefreshTxtDiscussionTime(discussion:GetVoteEndTimestamp())
    end, XScheduleManager.SECOND)
end

function XUiDlcMultiPlayerCompetition:RefreshSelected(discussion)
    self.TxtDiscussionVictory.transform.parent.gameObject:SetActiveEx(false)
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    self.TxtBpTips.text = XUiHelper.GetText("MultiMouseHunterVoteCount", self._Control:GetBpLevel())
    self._BlueCamp:RefreshSelected(discussion)
    self._RedCamp:RefreshSelected(discussion)
    local camp = discussion:GetPlayerCamp()
    local campStr = camp == CampEnum.Camp1 and discussionConfig.Camp1 or discussionConfig.Camp2
    self.BtnVote:SetName(XUiHelper.GetText("MultiMouseHunterVoted", campStr))
    self.BtnVote:SetDisable(true)
    self.BtnVote.enabled = false
    -- self:_RefreshSelectCamp(camp, false, XUiHelper.GetText("MultiMouseHunterVoted", campStr), XUiHelper.GetText("MultiMouseHunterSubVoted"))
    self:_RemoveDiscussionTimer()
    self:_RefreshTxtDiscussionTime(discussion:GetVoteEndTimestamp())
    self._DiscussionTimer = XScheduleManager.ScheduleForever(function()
        self:_RefreshTxtDiscussionTime(discussion:GetVoteEndTimestamp())
    end, XScheduleManager.SECOND)
end

function XUiDlcMultiPlayerCompetition:RefreshShow(discussion)
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    self.TxtBpTips.text = XUiHelper.GetText("MultiMouseHunterVoteCount", self._Control:GetBpLevel())
    if discussion:IsPlayerCamp1Vectory() then
        self.TxtDiscussionVictory.text = XUiHelper.GetText("MultiMouseHunterVoteVictory", discussionConfig.Camp1)
    else
        self.TxtDiscussionVictory.text = XUiHelper.GetText("MultiMouseHunterVoteVictory", discussionConfig.Camp2)
    end
    self.TxtDiscussionVictory.transform.parent.gameObject:SetActiveEx(true)
    self._BlueCamp:RefreshShow(discussion)
    self._RedCamp:RefreshShow(discussion)
    local camp = discussion:GetPlayerCamp()
    if camp ~= CampEnum.None then
        local campStr = camp == CampEnum.Camp1 and discussionConfig.Camp1 or discussionConfig.Camp2
        self.BtnVote:SetName(XUiHelper.GetText("MultiMouseHunterVoted", campStr))
    else
        self.BtnVote:SetName(XUiHelper.GetText("MultiMouseHunterVoteUnSelect"))
    end
    self.BtnVote:SetDisable(true)
    self.BtnVote.enabled = false
    -- self:_RefreshSelectCamp(camp, false, XUiHelper.GetText("MultiMouseHunterVoted", campStr), XUiHelper.GetText("MultiMouseHunterSubVoted"))
    self:_RemoveDiscussionTimer()
    self:_RefreshTxtDiscussionTime(discussion:GetDiscussionEndTimestamp())
    self._DiscussionTimer = XScheduleManager.ScheduleForever(function()
        self:_RefreshTxtDiscussionTime(discussion:GetDiscussionEndTimestamp())
    end, XScheduleManager.SECOND)
end

function XUiDlcMultiPlayerCompetition:_RefreshTxtDiscussionTime(endTimestamp)
    local timestamp = endTimestamp - XTime.GetServerNowTimestamp()
    timestamp = timestamp >= 0 and timestamp or 0
    self.TxtTime.text = XUiHelper.GetText("MultiMouseHunterVoteRemainTime",
        XUiHelper.GetTime(timestamp, XUiHelper.TimeFormatType.ACTIVITY))
end

function XUiDlcMultiPlayerCompetition:_RemoveDiscussionTimer()
    if self._DiscussionTimer then
        XScheduleManager.UnSchedule(self._DiscussionTimer)
        self._DiscussionTimer = nil
    end
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetition:_RefreshBulletChat(discussion)
    if not self._BulletChat then
        ---@type XUiDlcMultiPlayerCompetitionBulletChat
        self._BulletChat = XUiDlcMultiPlayerCompetitionBulletChat.New(self.PanelBulletChat, self)
    end
    self._BulletChat:Open()
    self._BulletChat:Refresh(discussion)
end

function XUiDlcMultiPlayerCompetition:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnVote:AddEventListener(handler(self, self.OnBtnVoteClick))
    self.BtnMonster:AddEventListener(handler(self, self.OnBtnMonsterClick))
end

function XUiDlcMultiPlayerCompetition:OnBtnVoteClick()
    XMVCA.XDlcMultiMouseHunter:RequestPlayerDiscussionVote(self._CurSelectCamp, function()
        self._BulletChat:AddOwnDanmakuData(self._CurSelectCamp)
    end)
end

function XUiDlcMultiPlayerCompetition:SetSelectCamp(camp)
    self._CurSelectCamp = camp
end

function XUiDlcMultiPlayerCompetition:GetBlueCamp()
    return self._BlueCamp
end

function XUiDlcMultiPlayerCompetition:GetRedCamp()
    return self._RedCamp
end

function XUiDlcMultiPlayerCompetition:OnBtnMonsterClick()
    self._ClickCount = self._ClickCount + 1
    self.MonsterState:SetInitialState("hit")
    if self.MonsetResetTimer then
        XScheduleManager.UnSchedule(self.MonsetResetTimer)
        self.MonsetResetTimer = nil
    end
    self.MonsetResetTimer = XScheduleManager.ScheduleOnce(function()
        self.MonsterState:SetInitialState("normal")
    end, 500)
end

function XUiDlcMultiPlayerCompetition:OnDestroy()
    if XLoginManager.IsLogin() and self._ClickCount > 0 then
        XMVCA.XDlcRoom:ClickCount(self._ClickCount)
    end
    self:_RemoveDiscussionTimer()
    if self.MonsetResetTimer then
        XScheduleManager.UnSchedule(self.MonsetResetTimer)
        self.MonsetResetTimer = nil
    end
end

function XUiDlcMultiPlayerCompetition:_CheckGetReward()
    local discussion = self._Control:GetDiscussion()
    if not discussion:CanGetReward() then
        return
    end

    XMVCA.XDlcMultiMouseHunter:RequestGetDiscussionVoteReward(function()
        local activityConfig = self._Control:GetDlcMultiplayerActivityConfig()
        local rewardCount = discussion:IsPlayerVectory() and activityConfig.DiscussionWinExp or
            activityConfig.DiscussionFailExp

        local rewardList = {}
        table.insert(rewardList, XRewardManager.CreateRewardGoods(activityConfig.BpExpItem, rewardCount))
        XUiManager.OpenUiObtain(rewardList)
    end)
end

function XUiDlcMultiPlayerCompetition:_SpecialkGetReward(callback)
    local discussion = self._Control:GetDiscussion()
    if not discussion:CanGetReward() then
        if callback then
            callback()
        end
        return
    end
    if discussion:GetPlayerCamp() == CampEnum.None then
        if callback then
            callback()
        end
        return
    end
    if discussion:IsSameDiscussion() == true and discussion:GetStatus() ~= nil then
        if callback then
            callback()
        end
        return
    end

    local activityConfig = self._Control:GetDlcMultiplayerActivityConfig()
    local rewardCount = discussion:IsPlayerVectory() and activityConfig.DiscussionWinExp or
        activityConfig.DiscussionFailExp

    local rewardList = {}
    table.insert(rewardList, XRewardManager.CreateRewardGoods(activityConfig.BpExpItem, rewardCount))
    XMVCA.XDlcMultiMouseHunter:RequestGetDiscussionVoteReward(function()
        XUiManager.OpenUiObtain(rewardList)
        if callback then
            callback()
        end
    end)
end

return XUiDlcMultiPlayerCompetition
