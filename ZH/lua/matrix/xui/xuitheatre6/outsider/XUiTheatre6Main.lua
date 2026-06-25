local SceneIds = require("XModule/XScene/XScene/XLuaSceneDefine").SceneIds
local XUiPanelTheatre6PvpEnergy = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpEnergy")

--- 肉鸽6玩法主界面
---@class XUiTheatre6Main : XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6Main = XLuaUiManager.Register(XLuaUi, "UiTheatre6Main")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local MaskKey = "UiTheatre6MainMask"

--region 生命周期
function XUiTheatre6Main:OnAwake()
    self:InitButtonEvents()
    self:Init3DPanel()

    self._RewardDuration = self._Control:GetIntClientConfigValue("RewardDuration")
    self._FirstEnterGuideId = self._Control:GetIntClientConfigValue("FirstEnterGuideId")
end

function XUiTheatre6Main:OnStart()
    self.RewardRedPoint = self:AddRedPointEvent(self.BtnStory, self.NewStoryRedPoint, self, { XRedPointConditions.Types.CONDITION_THEATRE6_NEW_STORY }, nil, true)
    self.TaskRewardRedPoint = self:AddRedPointEvent(self.BtnReward, self.OnTaskRewardRedPoint, self, { XRedPointConditions.Types.CONDITION_THEATRE6_REWARD }, nil, true)
    self:CheckTaskLimitTimeEnd()
end

function XUiTheatre6Main:OnEnable()
    CS.XInputManager.SetCurInputMap(CS.XInputMapId.System)
    self:CheckSceneEnable()
    self:Refresh()
    self:RefreshCommon()
    self:RefreshShowItems()
    self:CheckPvpTimeChange()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_MODE_END, self.Refresh, self)
    XMVCA.XFunction:EnterFunction(XFunctionManager.FunctionName.Theatre6)
    self._Scene:UpdateRogueModel(true)
    -- 放到 OnEnable 末尾,让 InputMap 切换链条按 System -> Video -> System 顺序串起来,
    -- 避免 OnStart 阶段 Video 比 OnEnable 的 SetCurInputMap(System) 更晚,导致 BeforeInputMapID 被污染
    if not self._PvTried then
        self._PvTried = true
        self:TryPlayPv(function()
            self:PlayAnimation("AnimStart1", function()
                self:TryShowUpdatePopup()
            end, nil, nil, true)
            self:Refresh()
            self:CheckPlayGuide()
            self:CheckMainUiPvpGuide()
        end)
    else
        self:TryShowUpdatePopup()
        self:CheckMainUiPvpGuide()
    end
end

function XUiTheatre6Main:OnDisable()
    if XLuaUiManager.IsMaskShow(MaskKey) then
        XLuaUiManager.SetMask(false, MaskKey)
    end
    self:CheckSceneDisable()
    self:StopPvpTimeChangeTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_MODE_END, self.Refresh, self)
end

function XUiTheatre6Main:OnDestroy()
    self:StopTaskLimitTimer()
    XMVCA.XScene:ExitScene(SceneIds.XTheatre6Scene)
end

function XUiTheatre6Main:OnGetEvents()
    return {
        XEventId.EVENT_GUIDE_END,
    }
end

function XUiTheatre6Main:OnNotify(evt, ...)
    if evt == XEventId.EVENT_GUIDE_END then
        self:OnGuideEnd(...)
    end
end
--endregion

function XUiTheatre6Main:Init3DPanel()
    self._Scene = XMVCA.XScene:GetScene(SceneIds.XTheatre6Scene)
    if not self._Scene then
        XMVCA.XScene:LoadScene(SceneIds.XTheatre6Scene, false, function()
            ---@type XTheatre6Scene
            self._Scene = XMVCA.XScene:GetScene(SceneIds.XTheatre6Scene)
        end)
    end
    local timerId = self._Scene:PlayEnterCamAnim()
    self:_AddTimerId(timerId)
end

function XUiTheatre6Main:CheckSceneEnable()
    self._Scene:ShowScene()
    self._IsEnterChooseCharacter = false
end

function XUiTheatre6Main:CheckSceneDisable()
    self._Scene:StopCommonCamAnim()
    if not self._IsEnterChooseCharacter then
        self._Scene:HideScene()
    end
end

--region 刷新
function XUiTheatre6Main:Refresh()
    self:RefreshFirstPlayState()
    self:RefreshBtnStory()
    self:RefreshBtnPlay()
    self:RefreshBtnPvp()
    self:RefreshPvpEnergy()
end

function XUiTheatre6Main:RefreshShowItems()
    local items = self._Control:GetActivityShowItems(1)
    self._ShowItemGrids = self._ShowItemGrids or {}
    self.Grid256New.gameObject:SetActiveEx(false)
    XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New, #items, function(index, go)
        ---@type XUiGridCommon
        local grid = self._ShowItemGrids[go]
        if not grid then
            grid = XUiGridCommon.New(self, go)
            self._ShowItemGrids[go] = grid
        end
        grid:Refresh(items[index])
        grid:SetProxyClickFunc(function()
            XLuaUiManager.Open("UiTheatre6PopupRewardDetail", items[index])
        end)
    end)
    local timerId = XScheduleManager.ScheduleOnce(function()
        for _, grid in pairs(self._ShowItemGrids) do
            grid.GameObject:SetActiveEx(false)
        end
    end, self._RewardDuration)
    self:_AddTimerId(timerId)
end

---首轮共通线关卡完成前隐藏玩法模式和PVP按钮
function XUiTheatre6Main:RefreshFirstPlayState()
    local isOpen = self._Control:CheckOpenGamePlayModeCond()
    self.BtnPlay.gameObject:SetActiveEx(isOpen)
    self.BtnPvp.gameObject:SetActiveEx(isOpen)
    self.BtnNew.gameObject:SetActiveEx(isOpen and self._Control:CheckHasNewContent())
    --动效（只在从局内直接回到玩法主界面时播放）
    if self._IsPlayModeOpen == false and isOpen then
        local anim = self.BtnPlay.transform:FindTransform("UnLockEnable")
        if not XTool.UObjIsNil(anim) then
            self.BtnPlay:SetButtonState(XUiButtonState.Disable)
            anim:PlayTimelineAnimation(function()
                self.BtnPlay:SetButtonState(XUiButtonState.Normal)
            end)
        end
    end
    self._IsPlayModeOpen = isOpen
end

function XUiTheatre6Main:RefreshPvpEnergy()
    local isPvpOpen = self:IsPvpOpen()
    if not self._PvpEnergy then
        --- 要请求下模块开启 服务端才会推体力数据
        if isPvpOpen then
            self._PvpEnergy = XUiPanelTheatre6PvpEnergy.New(self.PanelPVPEnergy, self)
            self._Control:RequestGetPvpPreviewInfo()
        else
            self.PanelPVPEnergy.gameObject:SetActiveEx(false)
            return
        end
    end

    local isOpen = self._Control:CheckOpenGamePlayModeCond()
    if isOpen and isPvpOpen then
        self._PvpEnergy:Open()
        self._PvpEnergy:Refresh()
    else
        self._PvpEnergy:Close()
    end
end

function XUiTheatre6Main:RefreshBtnStory()
    local hasStoryProgress = self._Control:CheckHasStoryProgress()
    self.BtnStoryAbandon.gameObject:SetActiveEx(hasStoryProgress)
    self.BtnStory:ShowReddot(self._Control:CheckOpenGamePlayModeCond() and self._Control:CheckHasNewCharacter(XEnumConst.Theatre6.CharacterNewTagType.Story))
end

function XUiTheatre6Main:RefreshBtnPlay()
    local hasPlayProgress = self._Control:CheckHasPlayProgress()
    self.BtnPlayAbandon.gameObject:SetActiveEx(hasPlayProgress)
    self.BtnPlay:ShowReddot(self._Control:CheckHasNewCharacter(XEnumConst.Theatre6.CharacterNewTagType.Game))
end

function XUiTheatre6Main:RefreshBtnPvp()
    local isPvpOpen = self:IsPvpOpen()
    self.BtnPvp:SetDisable(not isPvpOpen)
end

function XUiTheatre6Main:NewStoryRedPoint(result)
    self.BtnStory:ShowReddot(result >= 0 or (self._Control:CheckOpenGamePlayModeCond() and self._Control:CheckHasNewCharacter(XEnumConst.Theatre6.CharacterNewTagType.Story)))
end

function XUiTheatre6Main:OnTaskRewardRedPoint(result)
    self.BtnReward:ShowReddot(result >= 0)
end
--endregion

--region 按钮事件
function XUiTheatre6Main:InitButtonEvents()
    self.BtnReplay:AddEventListener(handler(self, self.OnBtnReplayClick))
    self.BtnReward:AddEventListener(handler(self, self.OnBtnRewardClick))
    self.BtnStory:AddEventListener(handler(self, self.OnBtnStoryClick))
    self.BtnStoryAbandon:AddEventListener(handler(self, self.OnBtnStoryAbandonClick))
    self.BtnPlay:AddEventListener(handler(self, self.OnBtnPlayClick))
    self.BtnPlayAbandon:AddEventListener(handler(self, self.OnBtnPlayAbandonClick))
    self.BtnPvp:AddEventListener(handler(self, self.OnBtnPvpClick))
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainClick))
    self.BtnNew:AddEventListener(handler(self, self.OnBtnNewClick))
    self:BindHelpBtn(self.BtnHelp, "Theatre6MainHelp")
end

function XUiTheatre6Main:OnBtnBackClick()
    XMVCA.XFunction:ExitFunction(XFunctionManager.FunctionName.Theatre6)
    self:Close()
end

function XUiTheatre6Main:OnBtnMainClick()
    XMVCA.XFunction:ExitFunction(XFunctionManager.FunctionName.Theatre6)
    XLuaUiManager.RunMain()
end

function XUiTheatre6Main:OnBtnNewClick()
    self._Control:ShowUpdatePopup()
end

function XUiTheatre6Main:OnBtnReplayClick()
    local videoId = self._Control:GetPvVideoId()
    XLuaVideoManager.PlayUiVideo(videoId, nil, true, true)
end

function XUiTheatre6Main:OnBtnRewardClick()
    XLuaUiManager.Open("UiTheatre6RewardShop")
end

function XUiTheatre6Main:OnBtnStoryClick()
    self._CurGuideId = nil
    self._CurCommonGuideId = nil

    self._Control:SaveLastViewStoryTime()

    if self:CheckReEnterSettlement(XEnumConst.Theatre6.PlayMode.Story) then
        return
    end

    if self._Control:CheckHasStoryProgress() then
        self:ContinueStoryGame()
        return
    end

    if not self:CheckStoryClickCond() then
        return
    end

    local avgId = self._Control:GetStoryAvgId()
    local firstGuideId = self._Control:GetStoryFirstGuideId()
    local repeatGuideId = self._Control:GetStoryRepeatGuideId()

    if not XDataCenter.GuideManager.CheckIsGuide(firstGuideId) then
        self._CurGuideId = firstGuideId
    elseif not self._Control:IsStoryAvgAlreadyPlayed(avgId) then
        if XDataCenter.GuideManager.CheckIsGuide(repeatGuideId) then
            self:OnStoryGuideEnd()
            return
        else
            self._CurGuideId = repeatGuideId
        end
    end

    if XTool.IsNumberValid(self._CurGuideId) then
        XDataCenter.GuideManager.PlayGuide(self._CurGuideId)
        return
    end

    if self:EnterCommonStage() then
        return
    end

    self:EnterStoryMode()
end

function XUiTheatre6Main:CheckStoryClickCond()
    if not self._CurStoryLine then
        return true --全部通关
    end
    local conditionId = self._CurStoryLine.ConditionId
    if XTool.IsNumberValid(conditionId) then
        local isUnlock, desc = XConditionManager.CheckCondition(conditionId)
        if not isUnlock then
            self._Control:ShowTip(desc)
            return false
        end
    end
    return true
end

function XUiTheatre6Main:RefreshCommon()
    self._CommonIdx = nil
    self._CurStoryLine = nil
    local storyLineIds = self._Control:GetCommonStoryLineIds()
    for _, storyLineId in ipairs(storyLineIds) do
        local storyLineConfig = self._Control:GetStoryLineConfig(storyLineId)
        local conditionId = storyLineConfig.ConditionId
        local isUnlock = not XTool.IsNumberValid(conditionId) or XConditionManager.CheckCondition(conditionId)
        local isPass = true
        for i = 1, #storyLineConfig.StageIds do
            if not self._Control:IsStagePass(storyLineId, i) then
                isPass = false
                if not self._CommonIdx then
                    self._CommonIdx = i
                    self._CurStoryLine = storyLineConfig
                end
            end
        end
        self._Scene:SetCommonFxVisible(storyLineConfig.CommonFx, isUnlock and not isPass)
    end
end

---进入共通线
--1、播放首次引导/重复引导、播放特效
--2、播放镜头动画
--3、直接进入关卡
function XUiTheatre6Main:EnterCommonStage()
    if self._CommonIdx then
        self:PlayCommonGuide()
        return true
    end
    return false
end

---播放共通线引导
function XUiTheatre6Main:PlayCommonGuide()
    local firstGuideId = self._CurStoryLine.CommonFirstGuides[self._CommonIdx]
    local isFirstGuidePlayed = XDataCenter.GuideManager.CheckIsGuide(firstGuideId)

    local guideId = self._CurStoryLine.CommonGuides[self._CommonIdx]
    local isGuidePlayed = XDataCenter.GuideManager.CheckIsGuide(guideId)

    if not isFirstGuidePlayed then
        self._CurCommonGuideId = firstGuideId
    elseif not isGuidePlayed then
        self._CurCommonGuideId = guideId
    end

    if self._CurCommonGuideId then
        XDataCenter.GuideManager.PlayGuide(self._CurCommonGuideId)
    else
        self:OnCommonGuidePlayEnd()
    end
end

function XUiTheatre6Main:ContinueStoryGame()
    self._Control:RequestContinueGame(XEnumConst.Theatre6.PlayMode.Story)
end

function XUiTheatre6Main:EnterStoryMode()
    self:EnterChooseCharacter(XEnumConst.Theatre6.PlayMode.Story, XEnumConst.Theatre6.CharacterNewTagType.Story)
end

---检查是否有未结算的存档，有则直接进入结算界面
function XUiTheatre6Main:CheckReEnterSettlement(mode)
    local modelData = self._Control:GetPlayModeData(mode)
    if modelData and modelData.IsSettle then
        XLuaUiManager.Open("UiTheatre6Settlement", modelData.SettleData, mode, true)
        return true
    end
    return false
end

function XUiTheatre6Main:OnBtnStoryAbandonClick()
    if self:CheckReEnterSettlement(XEnumConst.Theatre6.PlayMode.Story) then
        return
    end
    self._Control:ShowAbandonConfirm(function()
        self:AbandonStoryProgress()
    end)
end

function XUiTheatre6Main:AbandonStoryProgress()
    self._Control:RequestEndGame(XEnumConst.Theatre6.PlayMode.Story, function(res)
        self:Refresh()
        XLuaUiManager.Open("UiTheatre6Settlement", res.SettleData, XEnumConst.Theatre6.PlayMode.Story)
    end)
end

function XUiTheatre6Main:OnBtnPlayClick()
    if self:CheckReEnterSettlement(XEnumConst.Theatre6.PlayMode.GamePlay) then
        return
    end
    if self._Control:CheckHasPlayProgress() then
        self:ContinuePlayGame()
    else
        self:EnterPlayMode()
    end
end

function XUiTheatre6Main:ContinuePlayGame()
    self._Control:RequestContinueGame(XEnumConst.Theatre6.PlayMode.GamePlay)
end

function XUiTheatre6Main:EnterPlayMode()
    self:EnterChooseCharacter(XEnumConst.Theatre6.PlayMode.GamePlay, XEnumConst.Theatre6.CharacterNewTagType.Game)
end

function XUiTheatre6Main:EnterChooseCharacter(mode, tagType)
    local index = self._Control:GetModeSelectRoleIndex(mode)
    self._Scene:SetModelSelect(index)

    XLuaUiManager.SetMask(true, MaskKey)
    local duration = self._Control:GetIntClientConfigValue("UiCameraDuration", index)
    local timerId = XScheduleManager.ScheduleOnce(function()
        self._IsEnterChooseCharacter = true
        XLuaUiManager.SetMask(false, MaskKey)
        XLuaUiManager.Open("UiTheatre6ChooseCharacter", mode, tagType)
    end, duration)
    self:_AddTimerId(timerId)
end

function XUiTheatre6Main:OnBtnPlayAbandonClick()
    if self:CheckReEnterSettlement(XEnumConst.Theatre6.PlayMode.GamePlay) then
        return
    end
    self._Control:ShowAbandonConfirm(function()
        self:AbandonPlayProgress()
    end)
end

function XUiTheatre6Main:AbandonPlayProgress()
    self._Control:RequestEndGame(XEnumConst.Theatre6.PlayMode.GamePlay, function(res)
        self:Refresh()
        XLuaUiManager.Open("UiTheatre6Settlement", res.SettleData, XEnumConst.Theatre6.PlayMode.GamePlay)
    end)
end

function XUiTheatre6Main:IsPvpOpen(isShowTip)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.Theatre6Pvp, true, not isShowTip) then
        return false
    end

    -- 判断是否在活动时间内
    if not self._Control:IsPvpInActivityTime() then
        if isShowTip then
            self._Control:ShowTip(self._Control:GetPvpClientConfigValue("NotInActivityTime"))
        end
        return false
    end

    local isUnlock, desc = self._Control:CheckPvpModeUnlock()

    if not isUnlock then
        if isShowTip then
            self._Control:ShowTip(desc)
        end

        return false
    end

    return true
end

function XUiTheatre6Main:OnBtnPvpClick()
    if not self:IsPvpOpen(true) then
        return
    end

    self._Control:RequestPvpStart(function()
        if self._Control:IsPvpInTinyBattle() then
            self._Control:RequestPvpRestartFight(function(fightResult)
                if fightResult then
                    XMVCA.XTheatre6.Battle:OpenPvpSettlement(fightResult)
                else
                    XLuaUiManager.Open("UiTheatre6PVPLoading", XEnumConst.Theatre6.Pvp.LineupMode.Attack, true)
                end
            end)
        else
            local remainCd = self._Control:GetPvpRefreshMatchRemainCd()
            if remainCd < 0 then
                self._Control:RequestPvpRefreshMatch(handler(self, self.OpenPvpMain))
            else
                self:OpenPvpMain()
            end
        end
    end)
end

function XUiTheatre6Main:OpenPvpMain()
    XLuaUiManager.Open("UiTheatre6PVPMain")
end
--endregion

--region PV & 弹窗
function XUiTheatre6Main:TryPlayPv(cb)
    if not self._Control:IsPvPlayed() then
        local videoId = self._Control:GetPvVideoId()
        XLuaVideoManager.PlayUiVideo(videoId, function()
            self._Control:SetPvPlayed()
            if cb then cb() end
        end, true, true)
    else
        if cb then cb() end
    end
end

---尝试弹出更新内容弹窗，首轮共通线未完成时不弹
function XUiTheatre6Main:TryShowUpdatePopup()
    if not self._Control:CheckOpenGamePlayModeCond() then
        return
    end
    if not self._Control:CheckShowUpdatePopup() then
        return
    end
    self._Control:ShowUpdatePopup()
end
--endregion

function XUiTheatre6Main:OnGuideEnd(guideId)
    if guideId == self._CurGuideId then
        self:OnStoryGuideEnd()
    elseif guideId == self._CurCommonGuideId then
        self:OnCommonGuidePlayEnd()
    end
end

---播放剧情，然后回到玩法主界面
function XUiTheatre6Main:OnStoryGuideEnd()
    self._CurGuideId = nil

    local avgId = self._Control:GetStoryAvgId()
    local storyId = self._Control:GetStoryDetailConfig(avgId).StoryId

    self._Control:RequestStoryModeGuideFinished(avgId, function()
        self._Scene:HideScene()
        XDataCenter.MovieManager.PlayMovie(storyId, function()
            self._Scene:ShowScene()
        end, nil, nil, false)
    end)
end

---播放镜头动画，直接进入共通线关卡
function XUiTheatre6Main:OnCommonGuidePlayEnd()
    local timerId = self._Scene:PlayCommonCamAnim(self._CommonIdx, function()
        self:ReqEnterCommon()
    end)

    if timerId then
        self:_AddTimerId(timerId)
    end

    self._CurCommonGuideId = nil
    self._CommonIdx = nil
end

function XUiTheatre6Main:ReqEnterCommon()
    self._Control:RequestEnterStoryLine(self._CurStoryLine.Id)
end

function XUiTheatre6Main:CheckPlayGuide()
    if not XTool.IsNumberValid(self._FirstEnterGuideId) then
        return
    end
    if XDataCenter.GuideManager.CheckIsGuide(self._FirstEnterGuideId) then
        return
    end
    XDataCenter.GuideManager.PlayGuide(self._FirstEnterGuideId)
end

function XUiTheatre6Main:CheckTaskLimitTimeEnd()
    if not self.TaskRewardRedPoint then
        return
    end

    local configs = XMVCA.XTheatre6:GetValidShopOrTaskList(XEnumConst.Theatre6.TaskShopType.Task)
    if XTool.IsTableEmpty(configs) then
        return
    end

    if not self._TaskLimitEndTimes then
        self._TaskLimitEndTimes = {}
        for _, config in ipairs(configs) do
            if not XTool.IsNumberValid(config.TaskTimeLimitId) then
                goto continue
            end
            local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(config.TaskTimeLimitId)
            local timeId = taskTimeLimitCfg.TimeId
            if not XTool.IsNumberValid(timeId) or not XFunctionManager.CheckInTimeByTimeId(timeId) then
                goto continue
            end
            local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
            if not table.contains(self._TaskLimitEndTimes, endTime) then
                table.insert(self._TaskLimitEndTimes, endTime)
            end
            :: continue ::
        end
        table.sort(self._TaskLimitEndTimes)
    end

    self:StopTaskLimitTimer()

    if XTool.IsTableEmpty(self._TaskLimitEndTimes) then
        return
    end

    local endTime = table.remove(self._TaskLimitEndTimes, 1)
    local leftTime = math.max(0, endTime - XTime.GetServerNowTimestamp()) * 1000
    self._TaskLimitTimerId = XScheduleManager.ScheduleOnce(function()
        XRedPointManager.Check(self.TaskRewardRedPoint)
        self:CheckTaskLimitTimeEnd()
    end, leftTime)
end

function XUiTheatre6Main:StopTaskLimitTimer()
    if self._TaskLimitTimerId then
        XScheduleManager.UnSchedule(self._TaskLimitTimerId)
        self._TaskLimitTimerId = nil
    end
end

function XUiTheatre6Main:CheckPvpTimeChange()
    self:StopPvpTimeChangeTimer()

    local timeId = self._Control:GetPvpActivityTimeId()
    if not XTool.IsNumberValid(timeId) then
        return
    end

    local now = XTime.GetServerNowTimestamp()
    local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)

    --找下一个未到达的时间
    local nextTime
    if XTool.IsNumberValid(startTime) and now < startTime then
        nextTime = startTime
    elseif XTool.IsNumberValid(endTime) and now < endTime then
        nextTime = endTime
    end

    if not nextTime then
        return
    end

    --延后1秒触发
    local leftTime = (math.max(0, nextTime - now) + 1) * XScheduleManager.SECOND
    self._PvpTimeChangeTimerId = XScheduleManager.ScheduleOnce(function()
        if XTool.UObjIsNil(self.GameObject) then
            return
        end
        self._PvpTimeChangeTimerId = nil
        self:RefreshBtnPvp()
        self:RefreshPvpEnergy()
        --继续监听下一个
        self:CheckPvpTimeChange()
    end, leftTime)
end

function XUiTheatre6Main:StopPvpTimeChangeTimer()
    if self._PvpTimeChangeTimerId then
        XScheduleManager.UnSchedule(self._PvpTimeChangeTimerId)
        self._PvpTimeChangeTimerId = nil
    end
end

---Pvp引导
function XUiTheatre6Main:CheckMainUiPvpGuide()
    local guideId = self._Control:GetIntClientConfigValue("MainUiPvpGuideId")
    if not XTool.IsNumberValid(guideId) then
        return
    end
    if not self:IsPvpOpen() then
        return
    end
    if XDataCenter.GuideManager.CheckIsGuide(guideId) then
        return
    end
    XDataCenter.GuideManager.PlayGuide(guideId)
end

return XUiTheatre6Main
