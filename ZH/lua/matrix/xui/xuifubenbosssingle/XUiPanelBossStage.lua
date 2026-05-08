---@class XUiPanelBossStage : XUiNode
---@field _Control XFubenBossSingleControl
local XUiPanelBossStage = XClass(XUiNode, "XUiPanelBossStage")
local BOSS_MAX_COUNT = 3

function XUiPanelBossStage:OnStart(bossList)
    self._BossList = bossList
    self._GroupId = {}
    
    -- 拖尾特效节点
    self.FxTuowei = self.FxTuowei or self.Transform:FindTransform("FxTuowei")
    if self.FxTuowei then
        self.FxTuowei.gameObject:SetActiveEx(false)
    end
    
    self:_RegisterButtonListeners()
end

function XUiPanelBossStage:OnEnable()
    self:_Refresh()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self._Refresh, self)
end

function XUiPanelBossStage:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SYNC, self._Refresh, self)
    
    -- 清理延迟隐藏的定时器
    if self._HidePanelTimer then
        XScheduleManager.UnSchedule(self._HidePanelTimer)
        self._HidePanelTimer = nil
    end
    
    -- 清理回调
    self._ChallengeUnlockPanelCallback = nil

    if self._TrailTimer then
        XScheduleManager.UnSchedule(self._TrailTimer)
        self._TrailTimer = nil
    end
    if self._TrailDelayTimer then
        XScheduleManager.UnSchedule(self._TrailDelayTimer)
        self._TrailDelayTimer = nil
    end
end

function XUiPanelBossStage:_RegisterButtonListeners()
    XUiHelper.RegisterClickEvent(self, self.BtnEnter1, self.OnBtnEnter1Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter2, self.OnBtnEnter2Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnEnter3, self.OnBtnEnter3Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnName1, self.OnBtnName1Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnName2, self.OnBtnName2Click, true)
    XUiHelper.RegisterClickEvent(self, self.BtnName3, self.OnBtnName3Click, true)
    -- XUiHelper.RegisterClickEvent(self, self.BtnMode, self.OnBtnModeClick, true)
    XUiHelper.RegisterClickEvent(self, self.BtnModeV4P5, self.OnBtnModeClick, true)
end

function XUiPanelBossStage:_RefreshBossInfo()
    self._GroupId = {}
    for i = 1, BOSS_MAX_COUNT do
        if not self._BossList[i] then
            self["PanelStageLock" .. i].gameObject:SetActiveEx(true)
            self["PanelStageOpen" .. i].gameObject:SetActiveEx(false)
            -- self["PanelBossNameInfo" .. i].gameObject:SetActiveEx(false)
            self["TxtBoosName" .. i].gameObject:SetActiveEx(false)
            self["PanelLevel" .. i].gameObject:SetActiveEx(false)
            return
        end

        local bossId = self._BossList[i]
        self["PanelStageLock" .. i].gameObject:SetActiveEx(false)
        self["PanelStageOpen" .. i].gameObject:SetActiveEx(true)
        -- self["PanelBossNameInfo" .. i].gameObject:SetActiveEx(true)
        self["TxtBoosName" .. i].gameObject:SetActiveEx(true)
        self["PanelLevel" .. i].gameObject:SetActiveEx(true)

        local bossInfo = self._Control:GetBossCurDifficultyInfo(bossId, i)
        local curScore = self._Control:GetBossCurScore(bossId)
        if bossInfo:GetIsHideBoss() then
            self["TxtBossScore" .. i].text = CS.XTextManager.GetText("BossSingleLevelHideBoss", curScore)
            self["TxtBoosLevel" .. i].text = CS.XTextManager.GetText("BossSingleNameHideDesc", bossInfo:GetBossDifficultyName())
        else
            self["TxtBossScore" .. i].text = CS.XTextManager.GetText("BossSingleLevel", curScore)
            self["TxtBoosLevel" .. i].text = CS.XTextManager.GetText("BossSingleNameNotHideDesc", bossInfo:GetBossDifficultyName())
        end

        self["TxtBoosName" .. i].text = bossInfo:GetBossName()
        self["RImgBossIcon" .. i]:SetRawImage(bossInfo:GetBossIcon())

        if bossInfo:GetGroupName() then
            self["BtnName" .. i]:SetName(bossInfo:GetGroupName())
        end

        if bossInfo:GetGroupIcon() then
            self["BtnName" .. i]:SetSprite(bossInfo:GetGroupIcon())
        end

        self._GroupId[i] = bossInfo:GetGroupId()
    end
end

function XUiPanelBossStage:_EnterDetail(index)
    if not self._BossList[index] then
        XUiManager.TipText("BossSingleBossNotEnough")
        return
    end

    self.Parent:ShowBossDetail(self._BossList[index])
end

function XUiPanelBossStage:_RefreshPanelMode()
    local bossSingle = self._Control:GetBossSingleData()
    local isOpen = self._Control:CheckChallengeOpen()
    local score = bossSingle:GetBossSingleTotalScore()

    -- 由于未解锁状态下无法从服务器直接获得当前鏖战点的进度，这里直接读取表中唯一的9号挑战即鏖战点的需求分数
    local scoreNeed = self._Control._Model:GetBossSingleChallengeGradeNeedScoreByLevelType(9)

    if bossSingle:IsNewVersion() and self._Control:IsInLevelTypeExtreme() then
        self.PanelModeV4P5.gameObject:SetActiveEx(true)

        self.BtnModeV4P5:ShowReddot(isOpen and self._Control:CheckChallengeRedPoint())
        self.BtnModeV4P5ImgProgress.fillAmount = score / scoreNeed
        self.BtnModeV4P5UiTxtNum.text = CS.XTextManager.GetText(
            "BossSingleChallengeButtonScoreDisplay",
            score,
            scoreNeed)

        if isOpen then
            local isFirst = bossSingle:GetIsFirstUnlockChallenge()
            if isFirst then
                self.BtnModeV4P5:SetButtonState(CS.UiButtonState.Disable)
                self.BtnModeV4P5Effect.gameObject:SetActiveEx(false)
                self:_ShowChallengeUnlockPanel(function()
                    self.BtnModeV4P5Effect.gameObject:SetActiveEx(true)
                    self.BtnModeV4P5:SetButtonState(CS.UiButtonState.Normal)
                    bossSingle:UnlockChallenge()
                end)
            else
                self.BtnModeV4P5:SetButtonState(CS.UiButtonState.Normal)
            end
        else
            self.BtnModeV4P5:SetButtonState(CS.UiButtonState.Disable)
        end
    else
        self.PanelModeV4P5.gameObject:SetActiveEx(false)
    end

--[[ 旧版代码，用于参考
    local effect = self.BtnMode.transform:FindTransform("Effect")
    self.BtnMode:SetDisable(not isOpen)
    self.TxtTips.text = XUiHelper.GetText("BossSingleModeTips")
    self.BtnMode:ShowReddot(isOpen and self._Control:CheckChallengeRedPoint())
    if effect then
        local isFirst = bossSingle:GetIsFirstUnlockChallenge()

        -- 如果是第一次解锁且开放，先弹出PanelDetail，关闭后再播放特效
        if isOpen and isFirst then
            -- 先确保按钮特效关闭，等待拖尾结束后再开启
            effect.gameObject:SetActiveEx(false)
            self:_ShowChallengeUnlockPanel(function()
                -- PanelDetail关闭后的回调，播放特效
                if effect then
                    effect.gameObject:SetActiveEx(true)
                end
                bossSingle:UnlockChallenge()
            end)
        else
            effect.gameObject:SetActiveEx(false)
        end
    end
]]

end

--- 显示鏖战点解锁面板
---@param callback function 面板关闭后的回调
function XUiPanelBossStage:_ShowChallengeUnlockPanel(callback)
    -- 获取鏖战点的bossId
    local challengeData = self._Control:GetBossSingleChallengeData()
    if not challengeData then
        XLog.Warning("[XUiPanelBossStage] challengeData为空，无法显示解锁面板")
        if callback then
            callback()
        end
        return
    end

    local bossId = challengeData:GetBossId()
    if not bossId or bossId <= 0 then
        XLog.Warning("[XUiPanelBossStage] bossId无效，无法显示解锁面板")
        if callback then
            callback()
        end
        return
    end

    -- 清理之前的定时器
    if self._HidePanelTimer then
        XScheduleManager.UnSchedule(self._HidePanelTimer)
        self._HidePanelTimer = nil
    end
    if self._TrailTimer then
        XScheduleManager.UnSchedule(self._TrailTimer)
        self._TrailTimer = nil
    end
    if self._TrailDelayTimer then
        XScheduleManager.UnSchedule(self._TrailDelayTimer)
        self._TrailDelayTimer = nil
    end

    -- 获取boss图片和名字
    local bossBannerImg = self._Control:GetBossUnlockChallengeBannerImage(bossId)
    local bossName = self._Control:GetBossName(bossId)

    -- 本期铭牌图标：从能获得的奖励最高的里面查找铭牌
    local nameplateIcon = self:_GetHighestAvailableNameplateIcon()

    -- 显示UiFubenBossSingleChallengeUnlockBanner
    XLuaUiManager.Open(
        "UiFubenBossSingleChallengeUnlockBanner",
        bossBannerImg,
        nameplateIcon)

    -- 保存回调
    self._ChallengeUnlockPanelCallback = callback

    -- 先显示detail 0.6秒，再播放拖尾飞到BtnMode
    local delay = 1
    self._TrailDelayTimer = XScheduleManager.ScheduleOnce(function()
        self._TrailDelayTimer = nil
        self:_PlayTrailToBtnMode(function()
            XLuaUiManager.Close("UiFubenBossSingleChallengeUnlockBanner")

            if self._ChallengeUnlockPanelCallback then
                self._ChallengeUnlockPanelCallback()
                self._ChallengeUnlockPanelCallback = nil
            end
        end)
    end, delay * XScheduleManager.SECOND)

    XLog.Debug("[XUiPanelBossStage] 显示鏖战点解锁面板，bossId: " .. bossId .. ", bossName: " .. (bossName or ""))
end

--- 获取能获得的奖励最高的铭牌图标
---@return string|nil 铭牌图标路径
function XUiPanelBossStage:_GetHighestAvailableNameplateIcon()
    local bossSingleData = self._Control:GetBossSingleData()
    if not bossSingleData then
        return nil
    end

    local levelType = bossSingleData:GetBossSingleLevelType()
    local configs = self._Control:GetScoreRewardConfig(levelType)
    if not configs or #configs == 0 then
        return nil
    end

    local totalScore = bossSingleData:GetBossSingleTotalScoreBestRecord()
    local highestScoreConfig = nil
    local highestScore = 0

    -- 找到能获得的最高分数奖励配置
    for i = 1, #configs do
        local config = configs[i]
        if config and config.Score and totalScore >= config.Score then
            if config.Score > highestScore then
                highestScore = config.Score
                highestScoreConfig = config
            end
        end
    end

    if not highestScoreConfig or not highestScoreConfig.RewardId then
        return nil
    end

    -- 从奖励列表中找到铭牌类型的奖励
    local rewardList = XRewardManager.GetRewardList(highestScoreConfig.RewardId)
    if not rewardList then
        return nil
    end

    for _, reward in ipairs(rewardList) do
        if reward and reward.RewardType == XRewardManager.XRewardType.Nameplate then
            -- 找到铭牌奖励，获取铭牌图标
            local nameplateId = reward.TemplateId
            if nameplateId and nameplateId > 0 then
                -- GetNameplateIcon 可能返回两个值（icon, title）或一个值（icon）
                local icon, title = XMedalConfigs.GetNameplateIcon(nameplateId)
                if icon and icon ~= "" then
                    return icon
                end
            end
        end
    end

    return nil
end

--- 拖尾飞向 BtnMode
---@param callback function
function XUiPanelBossStage:_PlayTrailToBtnMode(callback)
    if not self.FxTuowei or not self.BtnMode then
        if callback then
            callback()
        end
        return
    end

    local startPos = self.FxTuowei.position
    local duration = 1
    local elapsed = 0

    self.FxTuowei.gameObject:SetActiveEx(true)
    self.FxTuowei.position = startPos

    self._TrailTimer = XScheduleManager.ScheduleForever(function()
        elapsed = elapsed + CS.UnityEngine.Time.deltaTime
        local t = math.min(elapsed / duration, 1)
        -- 实时获取目标位置
        local targetPos = self.BtnMode.transform.position
        local pos = CS.UnityEngine.Vector3.Lerp(startPos, targetPos, t)
        self.FxTuowei.position = pos

        if t >= 1 then
            XScheduleManager.UnSchedule(self._TrailTimer)
            self._TrailTimer = nil
            self.FxTuowei.gameObject:SetActiveEx(false)
            if callback then
                callback()
            end
        end
    end, 0)
end

function XUiPanelBossStage:_Refresh()
    self:_RefreshBossInfo()
    self:_RefreshPanelMode()
end

function XUiPanelBossStage:OnBtnEnter1Click()
    self:_EnterDetail(1)
end

function XUiPanelBossStage:OnBtnEnter2Click()
    self:_EnterDetail(2)
end

function XUiPanelBossStage:OnBtnEnter3Click()
    self:_EnterDetail(3)
end

function XUiPanelBossStage:OnBtnName1Click()
    local groupId = self._GroupId[1]
    self.Parent:ShowBossGroupInfo(groupId)
end

function XUiPanelBossStage:OnBtnName2Click()
    local groupId = self._GroupId[2]
    self.Parent:ShowBossGroupInfo(groupId)
end

function XUiPanelBossStage:OnBtnName3Click()
    local groupId = self._GroupId[3]
    self.Parent:ShowBossGroupInfo(groupId)
end

function XUiPanelBossStage:OnBtnModeClick()
    local isOpen = self._Control:CheckChallengeOpen()

    if isOpen then
        self._Control:OpenChallengeUi()
    else
        XUiManager.TipText("BossSingleModeTips")
    end
end

return XUiPanelBossStage