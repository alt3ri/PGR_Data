local XUiDlcMultiPlayerCompetitionCamp = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerDiscussion/XUiDlcMultiPlayerCompetitionCamp")
local XUiDlcMultiPlayerCompetitionBulletChat = require("XUi/XUiDlcMultiPlayer/XUiDlcMouseHunter/XUiDlcMultiPlayerDiscussion/XUiDlcMultiPlayerCompetitionBulletChat")
---@class XUiDlcMultiPlayerCompetition : XLuaUi
---@field private _Control XDlcMultiMouseHunterControl
local XUiDlcMultiPlayerCompetition = XLuaUiManager.Register(XLuaUi, "UiDlcMultiPlayerCompetition")

local CampEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionCamp
local StatusEnum = XMVCA.XDlcMultiMouseHunter.DlcMultiplayerDiscussionStatus

-- 点击上传延迟时间（秒）
local CLICK_UPLOAD_DELAY = 10

function XUiDlcMultiPlayerCompetition:OnAwake()
    self:RegisterUiEvents()
end

function XUiDlcMultiPlayerCompetition:OnStart()
    self._CurSelectCamp = nil
    self._DiscussionTimer = nil
    self._CurDiscussionStatus = StatusEnum.None
    self._MonsterClickCount = 0
    self._MonsterClickUploadTimer = nil

    ---@type XUiDlcMultiPlayerCompetitionCamp
    self._BlueCamp = XUiDlcMultiPlayerCompetitionCamp.New(self.BlueCampPanel, self, CampEnum.Camp1)
    ---@type XUiDlcMultiPlayerCompetitionCamp
    self._RedCamp = XUiDlcMultiPlayerCompetitionCamp.New(self.RedCampPanel, self, CampEnum.Camp2)
    self._ClickCount = 0
end

function XUiDlcMultiPlayerCompetition:OnEnable()
    self._MonsterClickCount = self._Control:GetMonsterClickCount()
    self:_RefreshDiscussion()
end

function XUiDlcMultiPlayerCompetition:OnGetLuaEvents()
    return {
        XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA
    }
end

function XUiDlcMultiPlayerCompetition:OnNotify(event, ...)
    if event == XEventId.EVENT_DLC_MOUSE_HUNTER_REFRESH_DISCUSSION_DATA then
        self:_RefreshDiscussion()
    end
end

function XUiDlcMultiPlayerCompetition:OnDisable()
    self._CurSelectCamp = nil
    self._CurDiscussionStatus = StatusEnum.None
    self:_RemoveDiscussionTimer()
    self:_RemoveMonsterClickUploadTimer()
end

function XUiDlcMultiPlayerCompetition:_RefreshDiscussion()
    self:_RemoveDiscussionTimer()

    local discussion = self._Control:GetDiscussion()
    if not discussion:HasDiscussionData() and not discussion:HasPlayerData() then
        self:Close()
        return
    end

    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    if not discussionConfig then
        self:Close()
        return
    end

    local discussionStatus = discussion:IsSameDiscussion() and discussion:GetStatus() or StatusEnum.Show
    if discussionStatus == StatusEnum.None then
        self:Close()
        return
    end

    if self._CurDiscussionStatus ~= discussionStatus then
        self._CurDiscussionStatus = discussionStatus
        self._CurSelectCamp = nil
    end

    self.TxtTitle.text = discussionConfig.Discussion
    self.TxtTime.text = ""

    local discussionPlayerCamp = discussion:GetPlayerCamp()
    if discussionStatus == StatusEnum.Vote then
        --投票期
        if discussionPlayerCamp == CampEnum.None then
            --未选择阵营
            self:_RefreshVoteUnSelect(discussion)
        else
            --已经选择阵营
            self:_RefreshVoteSelect(discussion)
        end
    elseif discussionStatus == StatusEnum.Show then
        --展示期
        self:_RefreshDisplay(discussion)
    end

    -- 弹幕
    self:_RefreshBulletChat(discussion)
end

function XUiDlcMultiPlayerCompetition:_RefreshSelectCamp(selectCamp, enableClick, voteTxt, btnTxt)
    local discussion = self._Control:GetDiscussion()

    self._CurSelectCamp = selectCamp
    if selectCamp == CampEnum.Camp1 then
        self.BtnVote:SetButtonState(CS.UiButtonState.Normal)
        self.BtnVote.enabled = enableClick
        self.BlueSelect.gameObject:SetActiveEx(true)
        self.BtnBlue.enabled = false
        self.RedSelect.gameObject:SetActiveEx(false)
        self.BtnRed.enabled = enableClick
        if btnTxt then
            self.BtnBlue:SetName(btnTxt)
            self.BtnRed:SetName(XUiHelper.GetText("MultiMouseHunterSubUnVote"))
            self.BtnBlue:SetButtonState(CS.UiButtonState.Select)
            self.BtnRed:SetButtonState(CS.UiButtonState.Normal)
        end
    elseif selectCamp == CampEnum.Camp2 then
        self.BtnVote:SetButtonState(CS.UiButtonState.Normal)
        self.BtnVote.enabled = enableClick
        self.BlueSelect.gameObject:SetActiveEx(false)
        self.BtnBlue.enabled = enableClick
        self.RedSelect.gameObject:SetActiveEx(true)
        self.BtnRed.enabled = false
        if btnTxt then
            self.BtnBlue:SetName(XUiHelper.GetText("MultiMouseHunterSubUnVote"))
            self.BtnRed:SetName(btnTxt)
            self.BtnBlue:SetButtonState(CS.UiButtonState.Normal)
            self.BtnRed:SetButtonState(CS.UiButtonState.Select)
        end
    else
        self.BtnVote:SetButtonState(CS.UiButtonState.Disable)
        self.BtnVote.enabled = false
        self.BlueSelect.gameObject:SetActiveEx(false)
        self.BtnBlue.enabled = enableClick
        self.RedSelect.gameObject:SetActiveEx(false)
        self.BtnRed.enabled = enableClick
        if btnTxt then
            self.BtnBlue:SetName(XUiHelper.GetText("MultiMouseHunterSubUnVote"))
            self.BtnRed:SetName(XUiHelper.GetText("MultiMouseHunterSubUnVote"))
            self.BtnBlue:SetButtonState(CS.UiButtonState.Normal)
            self.BtnRed:SetButtonState(CS.UiButtonState.Normal)
        end
    end

    local camp = discussion:GetPlayerCamp()
    if camp ~= CampEnum.None then
        self.BtnVote:SetButtonState(CS.UiButtonState.Disable)
        self.BtnVote.enabled = false
    end

    if voteTxt then
        self.BtnVote:SetName(voteTxt)
        self.BtnVote.gameObject:SetActiveEx(true)
    else
        self.BtnVote.gameObject:SetActiveEx(false)
    end

    if not btnTxt then
        self.BtnBlue.enabled = false
        self.BtnRed.enabled = false
        if discussion:IsPlayerCamp1Vectory() then
            self.BtnRed:SetButtonState(CS.UiButtonState.Disable)
            self.LeftPanelChoose.gameObject:SetActiveEx(false)
        else
            self.RightPanelChoose.gameObject:SetActiveEx(false)
            self.BtnBlue:SetButtonState(CS.UiButtonState.Disable)
        end
    end
end

function XUiDlcMultiPlayerCompetition:_RefreshTxtDiscussionTime(endTimestamp)
    if XTool.UObjIsNil(self.TxtTime) then
        return
    end

    local timestamp = endTimestamp - XTime.GetServerNowTimestamp()
    timestamp = timestamp >= 0 and timestamp or 0
    self.TxtTime.text = XUiHelper.GetText("MultiMouseHunterVoteRemainTime", XUiHelper.GetTime(timestamp, XUiHelper.TimeFormatType.ACTIVITY))
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetition:_RefreshVoteUnSelect(discussion)
    self.TxtTime.gameObject:SetActiveEx(true)
    self.TxtBpTips.gameObject:SetActiveEx(true)
    self.TxtBpTips.text = XUiHelper.GetText("MultiMouseHunterVoteBP", self._Control:GetBpLevel())
    self._BlueCamp:VoteUnSelect(discussion)
    self._RedCamp:VoteUnSelect(discussion)
    self:_RefreshSelectCamp(self._CurSelectCamp, true, XUiHelper.GetText("MultiMouseHunterUnVote"), XUiHelper.GetText("MultiMouseHunterSubUnVote"))
    self:_RefreshDiscussionTimer(function()
        self:_RefreshTxtDiscussionTime(discussion:GetVoteEndTimestamp())
    end)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetition:_RefreshVoteSelect(discussion)
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    self.TxtTime.gameObject:SetActiveEx(true)
    self.TxtBpTips.gameObject:SetActiveEx(true)
    self.TxtBpTips.text = XUiHelper.GetText("MultiMouseHunterVoteCount", self._Control:GetBpLevel())
    self._BlueCamp:VoteSelect(discussion)
    self._RedCamp:VoteSelect(discussion)
    local camp = discussion:GetPlayerCamp()
    local campStr = camp == CampEnum.Camp1 and discussionConfig.Camp1 or discussionConfig.Camp2
    self:_RefreshSelectCamp(camp, false, XUiHelper.GetText("MultiMouseHunterVoted", campStr), XUiHelper.GetText("MultiMouseHunterSubVoted"))
    self:_RefreshDiscussionTimer(function()
        self:_RefreshTxtDiscussionTime(discussion:GetVoteEndTimestamp())
    end)
end

---@param discussion XDlcMultiMouseHunterDiscussion
function XUiDlcMultiPlayerCompetition:_RefreshDisplay(discussion)
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    self.TxtTime.gameObject:SetActiveEx(true)
    self.TxtTime.text = XUiHelper.GetText("MultiMouseHunterVoteEnd")

    if discussion:IsPlayerCamp1Vectory() then
        self._BlueCamp:DisplayVictory(discussion)
        self._RedCamp:DisplayFail(discussion)
    elseif discussion:IsPlayerCamp2Vectory() then
        self._BlueCamp:DisplayFail(discussion)
        self._RedCamp:DisplayVictory(discussion)
    else
        self._BlueCamp:DisplayFail(discussion)
        self._RedCamp:DisplayFail(discussion)
    end

    local camp = discussion:GetPlayerCamp()
    if camp ~= CampEnum.None then
        self.TxtBpTips.gameObject:SetActiveEx(true)
        self.TxtBpTips.text = XUiHelper.GetText("MultiMouseHunterVoteCount", self._Control:GetBpLevel())
        local campStr = camp == CampEnum.Camp1 and discussionConfig.Camp1 or discussionConfig.Camp2
        self:_RefreshSelectCamp(camp, false, XUiHelper.GetText("MultiMouseHunterVoted", campStr), nil)
    else
        self.TxtBpTips.gameObject:SetActiveEx(false)
        self:_RefreshSelectCamp(camp, false, nil, nil)
    end

    self:_CheckGetReward()
end

function XUiDlcMultiPlayerCompetition:_CheckGetReward()
    local discussion = self._Control:GetDiscussion()
    if not discussion:CanGetReward() then
        return
    end

    XMVCA.XDlcMultiMouseHunter:RequestGetDiscussionVoteReward(function()
        local activityConfig = self._Control:GetDlcMultiplayerActivityConfig()
        local rewardCount = discussion:IsPlayerVectory() and activityConfig.DiscussionWinExp or activityConfig.DiscussionFailExp

        local rewardList = {}
        table.insert(rewardList, XRewardManager.CreateRewardGoods(activityConfig.BpExpItem, rewardCount))
        XUiManager.OpenUiObtain(rewardList)
    end)
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
    self.BtnClose:AddEventListener(handler(self, self.OnBtnCloseClick))
    self.BtnBlue:AddEventListener(handler(self, self.OnBtnBlueClick))
    self.BtnRed:AddEventListener(handler(self, self.OnBtnRedClick))
    self.BtnVote:AddEventListener(handler(self, self.OnBtnVoteClick))
    self.BtnMonster:AddEventListener(handler(self, self.OnBtnMonsterClick))
end

function XUiDlcMultiPlayerCompetition:OnBtnCloseClick()
    self:_RemoveMonsterClickUploadTimer()
    self:_UploadMonsterClickCount(function()
        self:Close()
    end)
end

function XUiDlcMultiPlayerCompetition:OnBtnBlueClick()
    if not self:_IsCanSelectCamp() then
        return
    end
    local discussion = self._Control:GetDiscussion()
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    self:_RefreshSelectCamp(CampEnum.Camp1, true, XUiHelper.GetText("MultiMouseHunterVote", discussionConfig.Camp1), XUiHelper.GetText("MultiMouseHunterSubVote", discussionConfig.Camp1))
    self._BlueCamp:VoteUnSelect_Select(discussion)
    self._RedCamp:VoteUnSelect_UnSelect(discussion)
end

function XUiDlcMultiPlayerCompetition:OnBtnRedClick()
    if not self:_IsCanSelectCamp() then
        return
    end
    local discussion = self._Control:GetDiscussion()
    local discussionConfig = discussion:GetPlayerTable() or discussion:GetTable()
    self:_RefreshSelectCamp(CampEnum.Camp2, true, XUiHelper.GetText("MultiMouseHunterVote", discussionConfig.Camp2), XUiHelper.GetText("MultiMouseHunterSubVote", discussionConfig.Camp2))
    self._BlueCamp:VoteUnSelect_UnSelect(discussion)
    self._RedCamp:VoteUnSelect_Select(discussion)
end

function XUiDlcMultiPlayerCompetition:_IsCanSelectCamp()
    local discussion = self._Control:GetDiscussion()
    return discussion:GetPlayerCamp() == CampEnum.None and discussion:GetStatus() == StatusEnum.Vote
end

function XUiDlcMultiPlayerCompetition:OnBtnVoteClick()
    if not self:_IsCanSelectCamp() then
        return
    end

    if not self._CurSelectCamp or self._CurSelectCamp == CampEnum.None then
        return
    end
    XMVCA.XDlcMultiMouseHunter:RequestPlayerDiscussionVote(self._CurSelectCamp)
    self._BulletChat:AddOwnDanmakuData(self._CurSelectCamp)
end

function XUiDlcMultiPlayerCompetition:OnBtnMonsterClick()
    self._MonsterClickCount = self._MonsterClickCount + 1
    self._ClickCount = self._ClickCount + 1
    -- TODO 播放击打动画，可连续点击
    -- 重置上传计时器，停止点击10秒后上传
    self:_ResetMonsterClickUploadTimer()
end

function XUiDlcMultiPlayerCompetition:_RemoveDiscussionTimer()
    if self._DiscussionTimer then
        XScheduleManager.UnSchedule(self._DiscussionTimer)
        self._DiscussionTimer = nil
    end
end

function XUiDlcMultiPlayerCompetition:_RefreshDiscussionTimer(func)
    self:_RemoveDiscussionTimer()
    if func then
        self._DiscussionTimer = XScheduleManager.ScheduleForever(func, XScheduleManager.SECOND)
    end
end

function XUiDlcMultiPlayerCompetition:_RemoveMonsterClickUploadTimer()
    if self._MonsterClickUploadTimer then
        XScheduleManager.UnSchedule(self._MonsterClickUploadTimer)
        self._MonsterClickUploadTimer = nil
    end
end

function XUiDlcMultiPlayerCompetition:_ResetMonsterClickUploadTimer()
    self:_RemoveMonsterClickUploadTimer()
    self._MonsterClickUploadTimer = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self:_UploadMonsterClickCount()
    end, CLICK_UPLOAD_DELAY * XScheduleManager.SECOND)
end

function XUiDlcMultiPlayerCompetition:_UploadMonsterClickCount(callback)
    if self._MonsterClickCount > self._Control:GetMonsterClickCount() then
        XMVCA.XDlcMultiMouseHunter:RequestDlcMultiplayerMonsterClick(self._MonsterClickCount, callback)
    else
        if callback then
            callback()
        end
    end
end

function XUiDlcMultiPlayerCompetition:OnDestroy()
    if XLoginManager.IsLogin() and self._ClickCount > 0 then
        XMVCA.XDlcRoom:ClickCount(self._ClickCount)
    end
end

return XUiDlcMultiPlayerCompetition
