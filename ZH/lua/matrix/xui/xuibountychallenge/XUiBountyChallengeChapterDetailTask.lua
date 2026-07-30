---@class XUiBountyChallengeChapterDetailTask : XUiNode
---@field _Control XBountyChallengeControl
local XUiBountyChallengeChapterDetailTask = XClass(XUiNode, "XUiBountyChallengeChapterDetailTask")

function XUiBountyChallengeChapterDetailTask:OnStart()
    self._GridRewards = {}
    self._Tweener = false
    
    self.BtnReceive:AddEventListener(handler(self, self.OnClick))
    self.BtnTaskHelp:AddEventListener(handler(self, self.OnBtnTaskHelpClick))
    
    self.CanvasGroup = self.Transform:GetComponentInChildren(typeof(CS.UnityEngine.CanvasGroup), false)
end

---@param data XUiBountyChallengeChapterDetailTaskData
function XUiBountyChallengeChapterDetailTask:UpdateContent(data)
    --self.Grid256New
    self._Data = data
    
    self.TxtDesc.text = data.Desc

    XTool.UpdateDynamicGridCommon(self._GridRewards, data.Rewards, self.Grid256New, self.Parent)

    if data.IsClear then
        for i = 1, #self._GridRewards do
            ---@type XUiGridCommon
            local grid = self._GridRewards[i]
            grid:SetReceived(true)
        end
        
        self.ImgMask.gameObject:SetActive(true)
    else
        for i = 1, #self._GridRewards do
            ---@type XUiGridCommon
            local grid = self._GridRewards[i]
            grid:SetReceived(false)
        end
        
        self.ImgMask.gameObject:SetActive(false)
    end

    local isMaxDifficulty = data.IsMaxDifficulty
    self.ImgBgComplete.gameObject:SetActiveEx(data.IsCanFinish)
    self.ImgBgNormal.gameObject:SetActiveEx(not data.IsCanFinish and not isMaxDifficulty)
    if not self.ImgBgLianYu then
        self.ImgBgLianYu = self.Transform:Find("All/ImgBgLianYu")
    end
    self.ImgBgLianYu.gameObject:SetActiveEx(not data.IsCanFinish and isMaxDifficulty)

    -- 可领取特效
    if data.IsCanFinish then
        for i = 1, #self._GridRewards do
            ---@type XUiGridCommon
            local grid = self._GridRewards[i]
            local imgCanReceive = grid.Transform:Find("ImgCanReceive")
            if imgCanReceive then
                imgCanReceive.gameObject:SetActive(true)
            end
        end
        self.BtnReceive.gameObject:SetActive(true)
    else
        for i = 1, #self._GridRewards do
            ---@type XUiGridCommon
            local grid = self._GridRewards[i]
            local imgCanReceive = grid.Transform:Find("ImgCanReceive")
            if imgCanReceive then
                imgCanReceive.gameObject:SetActive(false)
            end
        end
        self.BtnReceive.gameObject:SetActive(false)
    end
    
    -- 视频入口
    local hasVideo = XTool.IsNumberValidEx(data.Config.StageDescId)
    
    self.BtnTaskHelp.gameObject:SetActiveEx(hasVideo)
end

---@param data XUiBountyChallengeChapterDetailTaskData
function XUiBountyChallengeChapterDetailTask:Update(data)
    if data and data.IsPlayAnimation then
        -- 延迟播放
        ---@type XUiBountyChallengeChapterDetailTaskData
        local unfinishedData = XTool.Clone(data)
        unfinishedData.IsCanFinish = false
        -- 不重复播放
        data.IsPlayAnimation = false
        if self._Control:IsPlayAnimationSync() then
            self:PlayAnimation("ImgBg2Enable")
            self:UpdateContent(data)
        else
            self:UpdateContent(unfinishedData)
            self:StopAnimation("ImgBg2Enable")
            self._Tweener = self:Tween(1.2, nil, function()
                self:PlayAnimation("ImgBg2Enable")
                self:UpdateContent(data)
            end)
        end
        return
    end
    if self._Tweener then
        self:_RemoveTimerIdAndDoCallback(self._Tweener)
        self._Tweener = false
    end
    self:StopAnimation("ImgBg2Enable")
    self:UpdateContent(data)
end

function XUiBountyChallengeChapterDetailTask:OnClick()
    if self._Data then
        if XDataCenter.TaskManager.CheckTaskAchieved(self._Data.Id) then
            self._Control:ReceiveAllTask(function(goodsList)
                XUiManager.OpenUiObtain(goodsList)
                self.Parent:Update()
            end)
        end
    end
end

function XUiBountyChallengeChapterDetailTask:OnBtnTaskHelpClick()
    local data = self._Control:GetUiBossDetailByDescId(self._Data.Config.StageDescId)

    if data then
        data.Index = self._Data.Config.StageDescIndex

        XLuaUiManager.Open('UiBountyChallengePopupBossDetail', data)
    end
    
end

function XUiBountyChallengeChapterDetailTask:PlayStartAnimation(index)
    local delayTime = self._Control:GetConfigNum('UiTaskAnimDelayTime', 1)
    local interval = self._Control:GetConfigNum('UiTaskAnimIntervalTime', 1)
    
    local fixDelayTime = math.floor((delayTime + index * interval) * XScheduleManager.SECOND)

    if self.CanvasGroup then
        self.CanvasGroup.alpha = 0
    end
    
    self:StopAnimation('TaskEnable')
    local animTimeId = XScheduleManager.ScheduleOnce(function()
        self:PlayAnimation('TaskEnable')
    end, fixDelayTime)
    
    self._TweenAnimationAgency:_AddTimerId(animTimeId)
end


return XUiBountyChallengeChapterDetailTask