---@class XUiBountyChallengeChapterDetailTask : XUiNode
---@field _Control XBountyChallengeControl
local XUiBountyChallengeChapterDetailTask = XClass(XUiNode, "XUiBountyChallengeChapterDetailTask")

function XUiBountyChallengeChapterDetailTask:OnStart()
    self._GridRewards = {}
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
    self._Tweener = false
end

---@param data XUiBountyChallengeChapterDetailTaskData
function XUiBountyChallengeChapterDetailTask:UpdateContent(data)
    --self.Grid256New
    self._Data = data

    -- 无数据，显示空白格
    if not data then
        self.Detail.gameObject:SetActive(false)
        self.ImgBg1.gameObject:SetActive(false)
        self.ImgBg2.gameObject:SetActive(false)
        self.ImgBg3.gameObject:SetActive(true)
        return
    end

    self.Detail.gameObject:SetActive(true)
    if data.IsCanFinish or data.IsClear then
        self.ImgBg1.gameObject:SetActive(false)
        self.ImgBg2.gameObject:SetActive(true)
        self.ImgBg3.gameObject:SetActive(false)
    else
        self.ImgBg1.gameObject:SetActive(true)
        self.ImgBg2.gameObject:SetActive(false)
        self.ImgBg3.gameObject:SetActive(false)
    end

    self.TxtTitle.text = data.Name
    self.TxtDetail.text = data.Desc

    XTool.UpdateDynamicGridCommon(self._GridRewards, data.Rewards, self.Grid256New, self.Parent)

    if data.IsClear then
        for i = 1, #self._GridRewards do
            ---@type XUiGridCommon
            local grid = self._GridRewards[i]
            grid:SetReceived(true)
        end
    else
        for i = 1, #self._GridRewards do
            ---@type XUiGridCommon
            local grid = self._GridRewards[i]
            grid:SetReceived(false)
        end
    end

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
        self.Button.gameObject:SetActive(true)
    else
        for i = 1, #self._GridRewards do
            ---@type XUiGridCommon
            local grid = self._GridRewards[i]
            local imgCanReceive = grid.Transform:Find("ImgCanReceive")
            if imgCanReceive then
                imgCanReceive.gameObject:SetActive(false)
            end
        end
        self.Button.gameObject:SetActive(false)
    end
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
            XDataCenter.TaskManager.FinishTask(self._Data.Id, function(goodsList)
                XUiManager.OpenUiObtain(goodsList)
                self.Parent:Update()
            end)
            --else do nothing
        end
    end
end

return XUiBountyChallengeChapterDetailTask