local SceneIds = require("XModule/XScene/XScene/XLuaSceneDefine").SceneIds

--- 肉鸽6玩法主界面
---@class XUiTheatre6Main : XLuaUi
---@field _Control XTheatre6Control
local XUiTheatre6Main = XLuaUiManager.Register(XLuaUi, "UiTheatre6Main")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

--region 生命周期
function XUiTheatre6Main:OnAwake()
    self:InitButtonEvents()
    self:Init3DPanel()
    self._RewardDuration = self._Control:GetIntClientConfigValue("RewardDuration")
end

function XUiTheatre6Main:OnStart()
    self.RewardRedPoint = self:AddRedPointEvent(self.BtnStory, self.NewStoryRedPoint, self, { XRedPointConditions.Types.CONDITION_THEATRE6_NEW_STORY }, nil, true)
    self.TaskRewardRedPoint = self:AddRedPointEvent(self.BtnReward, self.OnTaskRewardRedPoint, self, { XRedPointConditions.Types.CONDITION_THEATRE6_REWARD }, nil, true)
    self:TryPlayPv(function()
        self:Refresh()
        self:TryShowUpdatePopup()
    end)
end

function XUiTheatre6Main:OnEnable()
    self:Refresh()
    self:RefreshCommon()
    self:RefreshShowItems()
    XMVCA.XTheatre6:StopSanAudio()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_MODE_END, self.Refresh, self)
    XMVCA.XFunction:EnterFunction(XFunctionManager.FunctionName.Theatre6)
    self._Scene:UpdateRogueModel(true)
end

function XUiTheatre6Main:OnDisable()
    self._Scene:StopCommonCamAnim()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_MODE_END, self.Refresh, self)
end

function XUiTheatre6Main:OnDestroy()
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
    XMVCA.XScene:LoadScene(SceneIds.XTheatre6Scene, false, function()
        ---@type XTheatre6Scene
        self._Scene = XMVCA.XScene:GetScene(SceneIds.XTheatre6Scene)
    end)
end

--region 刷新
function XUiTheatre6Main:Refresh()
    self:RefreshFirstPlayState()
    self:RefreshBtnStory()
    self:RefreshBtnPlay()
    self:RefreshBtnPvp()
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
    local isVisible = self._Control:CheckOpenGamePlayModeCond()
    self.BtnPlay.gameObject:SetActiveEx(isVisible)
    self.BtnPvp.gameObject:SetActiveEx(isVisible)
end

function XUiTheatre6Main:RefreshBtnStory()
    local hasStoryProgress = self._Control:CheckHasStoryProgress()
    self.BtnStoryAbandon.gameObject:SetActiveEx(hasStoryProgress)
end

function XUiTheatre6Main:RefreshBtnPlay()
    local hasPlayProgress = self._Control:CheckHasPlayProgress()
    self.BtnPlayAbandon.gameObject:SetActiveEx(hasPlayProgress)
end

function XUiTheatre6Main:RefreshBtnPvp()
    local isLocked = false
    local state = isLocked and XUiButtonState.Disable or XUiButtonState.Normal
    self.BtnPvp:SetButtonState(state)
end

function XUiTheatre6Main:NewStoryRedPoint(result)
    self.BtnStory:ShowReddot(result >= 0)
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

function XUiTheatre6Main:OnBtnReplayClick()
    local videoId = self._Control:GetPvVideoId()
    XLuaVideoManager.PlayUiVideo(videoId,nil,true,true)
end

function XUiTheatre6Main:OnBtnRewardClick()
    XLuaUiManager.Open("UiTheatre6RewardShop")
end

function XUiTheatre6Main:OnBtnStoryClick()
    self._CurGuideId = nil
    self._CurCommonGuideId = nil

    if self:CheckReEnterSettlement(XEnumConst.Theatre6.PlayMode.Story) then
        return
    end

    if self._Control:CheckHasStoryProgress() then
        self:ContinueStoryGame()
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

    self._Control:SaveLastViewStoryTime()
    self.BtnStory:ShowReddot(false)
    self:EnterStoryMode()
end

function XUiTheatre6Main:RefreshCommon()
    self._CommonIdx = nil
    local storyLineIds = self._Control:GetCommonStoryLineIds()
    for _, storyLineId in ipairs(storyLineIds) do
        local storyLineConfig = self._Control:GetStoryLineConfig(storyLineId)
        local conditionId = storyLineConfig.ConditionId
        local isUnlock = not XTool.IsNumberValid(conditionId) or XConditionManager.CheckCondition(conditionId)
        local isPass = true
        for i = 1, #storyLineConfig.StageIds do
            if not self._Control:IsStagePass(storyLineId, i) then
                isPass = false
                if not self._CommonIdx and isUnlock then
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
    self:EnterChooseCharacter(XEnumConst.Theatre6.PlayMode.Story)
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
    self:EnterChooseCharacter(XEnumConst.Theatre6.PlayMode.GamePlay)
end

function XUiTheatre6Main:EnterChooseCharacter(mode)
    local index = self._Control:GetModeSelectRoleIndex(mode)
    self._Scene:SetModelSelect(index)
    
    local duration = self._Control:GetIntClientConfigValue("UiCameraDuration", index)
    local timerId = XScheduleManager.ScheduleOnce(function()
        XLuaUiManager.Open("UiTheatre6ChooseCharacter", mode)
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

function XUiTheatre6Main:OnBtnPvpClick()
    local title = XUiHelper.GetText("BtnPvpTipTitle")
    local content = XUiHelper.ReplaceTextNewLine(XUiHelper.GetText("BtnPvpTip"))
    self._Control:OpenPopupCommonWithoutButton(title, content)
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
        XDataCenter.MovieManager.PlayMovie(storyId)
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

return XUiTheatre6Main
