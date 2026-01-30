local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiPanelDlcRelinkChooseBossDetail : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiDlcRelinkChooseBoss
---@field VideoPlayer XVideoPlayerUGUI
local XUiPanelDlcRelinkChooseBossDetail = XClass(XUiNode, "XUiPanelDlcRelinkChooseBossDetail")

function XUiPanelDlcRelinkChooseBossDetail:OnStart()
    self.GridTag.gameObject:SetActiveEx(false)
    self.GridDot.gameObject:SetActiveEx(false)
    self.GridReform.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self.GridDrop.gameObject:SetActiveEx(false)
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.OnBtnCloseClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnChange, self.OnBtnChangeClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnSure, self.OnBtnSureClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnRight, self.OnBtnRightClick, true, true)
    XUiHelper.RegisterClickEvent(self, self.BtnLeft, self.OnBtnLeftClick, true, true)

    ---@type UiObject[]
    self.TagGridList = {}
    ---@type UiObject[]
    self.DotGridList = {}

    self.IsSkillAngerStatus = false
    self.SkillCount = 0
    self.CurSelectSkillIdIndex = 1
    self.CurSkillIds = {}
    self.IsVideoPlaying = false

    ---@type UiObject[]
    self.LevelGridList = {}
    self.LevelIds = {}
    self.LevelCount = 0

    ---@type XUiGridCommon[]
    self.RewardGridList = {}
    ---@type UiObject[]
    self.DropGridList = {}
end

function XUiPanelDlcRelinkChooseBossDetail:Refresh(chapterId, levelId)
    self.ChapterId = chapterId
    self.LevelId = levelId

    self.TxtTitle.text = self._Control:GetChapterName(self.ChapterId)
    self.IsSkillAngerStatus = false
    self.CurSelectSkillIdIndex = 1
    self:RefreshSkills()

    self.LevelIds = self._Control:GetChapterLevelIds(self.ChapterId)
    self.LevelCount = #self.LevelIds
    self:RefreshLevelIds()
end

function XUiPanelDlcRelinkChooseBossDetail:OnDisable()
    self:StopVideo()
end

function XUiPanelDlcRelinkChooseBossDetail:_SetSkillIndex(index)
    if self.SkillCount <= 0 then
        self.CurSelectSkillIdIndex = 0
        return
    end
    if index < 1 then
        index = self.SkillCount
    elseif index > self.SkillCount then
        index = 1
    end
    self.CurSelectSkillIdIndex = index
end

function XUiPanelDlcRelinkChooseBossDetail:_ApplySkillSelection()
    local skillId = self.CurSkillIds[self.CurSelectSkillIdIndex]
    if not skillId then
        self.TxtDesc.text = ""
        self.Txt.text = ""
        self:RefreshTags(nil)
        self:RefreshVideos(nil)
        return
    end

    self.TxtDesc.text = self._Control:GetBossSkillDescDesc(skillId)
    self:RefreshTags(skillId)
    self:RefreshVideos(skillId)
end

function XUiPanelDlcRelinkChooseBossDetail:_NavigateSkill(offset)
    if self.SkillCount <= 0 then
        return
    end
    self:_SetSkillIndex(self.CurSelectSkillIdIndex + offset)
    self:_ApplySkillSelection()
end

function XUiPanelDlcRelinkChooseBossDetail:GetSkillIds()
    if self.IsSkillAngerStatus then
        return self._Control:GetChapterOdSkills(self.ChapterId)
    else
        return self._Control:GetChapterSkills(self.ChapterId)
    end
end

function XUiPanelDlcRelinkChooseBossDetail:RefreshSkills()
    self.CurSkillIds = self:GetSkillIds()
    self.SkillCount = #self.CurSkillIds

    if self.SkillCount == 0 then
        self.CurSelectSkillIdIndex = 0
        self:_ApplySkillSelection()
        self:RefreshBtnChange()
        return
    end

    if self.CurSelectSkillIdIndex < 1 or self.CurSelectSkillIdIndex > self.SkillCount then
        self.CurSelectSkillIdIndex = 1
    end

    self:_ApplySkillSelection()
    self:RefreshBtnChange()
end

function XUiPanelDlcRelinkChooseBossDetail:RefreshTags(skillId)
    local tags = {}
    if skillId then
        tags = self._Control:GetBossSkillDescTags(skillId)
    end

    local tagCount = #tags
    self.ListTag.gameObject:SetActiveEx(tagCount > 0)
    if tagCount == 0 then
        return
    end

    for index = 1, tagCount do
        local grid = self.TagGridList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridTag, self.ListTag)
            self.TagGridList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("TxtTag").text = tags[index]
    end

    for index = tagCount + 1, #self.TagGridList do
        self.TagGridList[index].gameObject:SetActiveEx(false)
    end
end

function XUiPanelDlcRelinkChooseBossDetail:RefreshVideos(skillId)
    self.VideoPlayerGroup.gameObject:SetActiveEx(self.SkillCount > 0)
    if self.SkillCount == 0 then
        self:RefreshVideoBtn()
        return
    end

    self:RefreshDot()
    self:RefreshVideoBtn()
    self:PlaySelectedVideo(skillId)
end

function XUiPanelDlcRelinkChooseBossDetail:RefreshDot()
    self.PanelDot.gameObject:SetActiveEx(self.SkillCount > 0)
    if self.SkillCount == 0 then
        return
    end

    for index = 1, self.SkillCount do
        local grid = self.DotGridList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridDot, self.PanelDot)
            self.DotGridList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        grid:GetObject("ImgOff").gameObject:SetActiveEx(self.CurSelectSkillIdIndex ~= index)
        grid:GetObject("ImgOn").gameObject:SetActiveEx(self.CurSelectSkillIdIndex == index)
    end

    for index = self.SkillCount + 1, #self.DotGridList do
        self.DotGridList[index].gameObject:SetActiveEx(false)
    end
end

function XUiPanelDlcRelinkChooseBossDetail:RefreshVideoBtn()
    local hasMultipleVideos = self.SkillCount > 1
    self.BtnLeft.gameObject:SetActiveEx(hasMultipleVideos)
    self.BtnRight.gameObject:SetActiveEx(hasMultipleVideos)
end

function XUiPanelDlcRelinkChooseBossDetail:PlaySelectedVideo(skillId)
    if not skillId then
        self:StopVideo()
        return
    end
    self.Txt.text = self._Control:GetBossSkillDescName(skillId)
    self:PlayVideo(self._Control:GetBossSkillDescVideoUrl(skillId))
end

function XUiPanelDlcRelinkChooseBossDetail:PlayVideo(videoUrl)
    if not self.VideoPlayer then
        return
    end
    if string.IsNilOrEmpty(videoUrl) then
        self.VideoPlayer.gameObject:SetActiveEx(false)
        return
    end

    self.VideoPlayer.gameObject:SetActiveEx(true)
    self.VideoPlayer:SetVideoFromRelateUrl(videoUrl)
    if self.IsVideoPlaying then
        self.VideoPlayer:RePlay()
    else
        self.VideoPlayer:Play()
    end
    self.IsVideoPlaying = true
end

function XUiPanelDlcRelinkChooseBossDetail:StopVideo()
    if self.VideoPlayer and self.IsVideoPlaying then
        self.VideoPlayer:Pause()
        self.VideoPlayer.gameObject:SetActiveEx(false)
    end
end

function XUiPanelDlcRelinkChooseBossDetail:RefreshLevelIds()
    self.ListDifficulty.gameObject:SetActiveEx(self.LevelCount > 0)
    if self.LevelCount == 0 then
        return
    end

    for index = 1, self.LevelCount do
        local grid = self.LevelGridList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridReform, self.ListDifficulty)
            self.LevelGridList[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local levelId = self.LevelIds[index]
        grid:GetObject("BtnReform"):SetNameByGroup(0, self._Control:GetLevelName(levelId))
        local levelLimit = self._Control:GetLevelLevelLimit(levelId)
        local levelLimitDesc = levelLimit > 0 and string.format(self._Control:GetClientConfig("RoomBossLevelLimit"), levelLimit) or ""
        grid:GetObject("BtnReform"):SetNameByGroup(1, levelLimitDesc)
        grid:GetObject("BtnReform").CallBack = function()
            local isUnlockNow = self._Control:CheckLevelUnlock(levelId)
            if not isUnlockNow then
                self._Control:OpenCommonTipMsg(self._Control:GetLevelUnlockDesc(levelId))
                return
            end
            if self.LevelId ~= levelId then
                self.LevelId = levelId
                self:RefreshLevelGrid()
            end
        end
    end

    for index = self.LevelCount + 1, #self.LevelGridList do
        self.LevelGridList[index].gameObject:SetActiveEx(false)
    end

    self:RefreshLevelLockStates()
    self:RefreshLevelGrid()
end

function XUiPanelDlcRelinkChooseBossDetail:RefreshLevelLockStates()
    for index = 1, self.LevelCount do
        local grid = self.LevelGridList[index]
        if grid then
            local levelId = self.LevelIds[index]
            local unLock = self._Control:CheckLevelUnlock(levelId)
            grid:GetObject("PanelOn").gameObject:SetActiveEx(unLock)
            grid:GetObject("PanelOff").gameObject:SetActiveEx(not unLock)
        end
    end
end

function XUiPanelDlcRelinkChooseBossDetail:RefreshLevelGrid()
    -- 记录关卡点击
    self._Control:RecordLevelViewed(self.LevelId)
    -- 刷新章节红点
    self.Parent:RefreshRedPoint()
    -- 刷新关卡选中状态和红点
    for index = 1, self.LevelCount do
        local grid = self.LevelGridList[index]
        if grid then
            local levelId = self.LevelIds[index]
            local isSelected = self.LevelId == levelId
            grid:GetObject("SelectOn").gameObject:SetActiveEx(isSelected)
            grid:GetObject("NormalOn").gameObject:SetActiveEx(not isSelected)
            -- 红点
            local isShowRedPoint = self._Control:CheckLevelHasNewUnlock(levelId)
            grid:GetObject("BtnReform"):ShowReddot(isShowRedPoint)
        end
    end
    -- 作战场次
    self.TxtFight.text = self._Control:GetLevelPassTime(self.LevelId)
    -- 作战时间
    local isPass = self._Control:CheckLevelPassed(self.LevelId)
    if isPass then
        local finishTime = self._Control:GetLevelFinishTime(self.LevelId)
        self.TxtTime.text = XUiHelper.GetTime(finishTime, XUiHelper.TimeFormatType.DAY_HOUR)
    else
        self.TxtTime.text = "00:00:00"
    end
    -- 奖励
    self:RefreshReward()
end

function XUiPanelDlcRelinkChooseBossDetail:RefreshReward()
    local isPass = self._Control:CheckLevelPassed(self.LevelId)
    local rewardGoods, showRewardIds
    if isPass then
        rewardGoods, showRewardIds = self._Control:GetShowLevelRewardGoods(self.LevelId)
    else
        rewardGoods, showRewardIds = self._Control:GetShowLevelFirstRewardGoods(self.LevelId)
    end
    local rewardCount = #rewardGoods
    local showRewardCount = #showRewardIds
    self.ListReward.gameObject:SetActiveEx(rewardCount > 0 or showRewardCount > 0)
    if rewardCount == 0 and showRewardCount == 0 then
        return
    end
    -- 常规奖励
    for index = 1, rewardCount do
        local grid = self.RewardGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridReward, self.ListReward)
            grid = XUiGridCommon.New(self.Parent, go)
            self.RewardGridList[index] = grid
        end
        grid:Refresh(rewardGoods[index])
        grid:SetProxyClickFunc(function()
            XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", grid.TemplateId)
        end)
        grid.GameObject:SetActiveEx(true)
        grid.Transform:SetAsLastSibling()
    end
    for index = rewardCount + 1, #self.RewardGridList do
        local grid = self.RewardGridList[index]
        if grid then
            grid.GameObject:SetActiveEx(false)
        end
    end
    -- 展示奖励
    for index = 1, showRewardCount do
        local grid = self.DropGridList[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.GridDrop, self.ListReward)
            self.DropGridList[index] = grid
        end
        local showRewardId = showRewardIds[index]
        grid:GetObject("RImgIcon"):SetRawImageEx(self._Control:GetShowLevelDropIcon(showRewardId))
        grid:GetObject("BtnClick").CallBack = function()
            local icon = self._Control:GetShowLevelDropIcon(showRewardId)
            local name = self._Control:GetShowLevelDropName(showRewardId)
            local desc = self._Control:GetShowLevelDropDesc(showRewardId)
            XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", {
                IsTempItemData = true,
                Name = name,
                Icon = icon,
                Description = desc,
            })
        end
        grid.gameObject:SetActiveEx(true)
        grid.transform:SetAsLastSibling()
    end
    for index = showRewardCount + 1, #self.DropGridList do
        local grid = self.DropGridList[index]
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPanelDlcRelinkChooseBossDetail:RefreshBtnChange()
    self.BtnChange:SetButtonState(self.IsSkillAngerStatus and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiPanelDlcRelinkChooseBossDetail:OnBtnCloseClick()
    self.Parent:OnPanelDetailClose()
end

function XUiPanelDlcRelinkChooseBossDetail:OnBtnChangeClick()
    self.IsSkillAngerStatus = not self.IsSkillAngerStatus
    self.CurSelectSkillIdIndex = 1
    self:RefreshSkills()
end

function XUiPanelDlcRelinkChooseBossDetail:OnBtnSureClick()
    if XMVCA.XDlcRoom:IsMatching() then
        self._Control:OpenCommonTipCode(XCode.MatchPlayerIsMatching)
        return
    end

    self._Control:SetCurrentSelectLevelData(self.ChapterId, self.LevelId)
    if not XMVCA.XDlcRoom:IsInRoom() then
        self.Parent:Close()
        return
    end

    local team = XMVCA.XDlcRoom:GetRoomProxy():GetTeam()
    if team and team:IsSelfLeader() then
        local roomData = XMVCA.XDlcRoom:GetRoomData()
        if roomData and roomData:GetLevelId() ~= self.LevelId then
            XMVCA.XDlcRoom:SwitchWorld(self._Control:GetActivityWorldId(), self.LevelId, function()
                self.Parent:Close()
            end)
        else
            self.Parent:Close()
        end
    end
end

function XUiPanelDlcRelinkChooseBossDetail:OnBtnRightClick()
    self:_NavigateSkill(1)
end

function XUiPanelDlcRelinkChooseBossDetail:OnBtnLeftClick()
    self:_NavigateSkill(-1)
end

return XUiPanelDlcRelinkChooseBossDetail
