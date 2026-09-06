local XUiGridTransfiniteTowerStage = require("XUi/XUiTransfiniteTower/Grid/XUiGridTransfiniteTowerStage")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@class XUiTransfiniteTowerMain : XLuaUi
---@field _Control XTransfiniteTowerControl
---@field TxtTime UnityEngine.UI.Text
---@field GridStage_3 UnityEngine.GameObject
---@field GridStage_8Top UnityEngine.GameObject
---@field GridStage_8Bottom UnityEngine.GameObject
---@field GridStage_15 UnityEngine.GameObject
---@field BtnTask XUiComponent.XUiButton
---@field BtnRank XUiComponent.XUiButton
---@field BtnHelp XUiComponent.XUiButton
---@field TopControl UnityEngine.RectTransform
---@field CommonTaskRewardLeft UnityEngine.GameObject
---@field Grid256New UnityEngine.RectTransform
---@field Grid256NewRight UnityEngine.RectTransform
local XUiTransfiniteTowerMain = XLuaUiManager.Register(XLuaUi, "UiTransfiniteTowerMain")

-- 四座塔入口节点。顺序即展示顺序，每个节点对应一座塔。
local StageGridNodeNames = {
    "GridStage_3",        -- 初级塔
    "GridStage_8Top",     -- 8层塔（上）
    "GridStage_8Bottom",  -- 8层塔（下）
    "GridStage_15",       -- 15层塔
}

function XUiTransfiniteTowerMain:OnAwake()
    self:InitTopControl()
    self:InitStageGrids()
    self:InitRewardBubble()
    self:RegisterButtonEvent()
end

function XUiTransfiniteTowerMain:OnStart()
    self._Control:RefreshRankCache()
    local endTime = XMVCA.XTransfiniteTower:GetActivityEndTime()
    if endTime > 0 then
        self:SetAutoCloseInfo(endTime, handler(self, self.OnActivityClosed))
    end
end

function XUiTransfiniteTowerMain:OnActivityClosed(isClose)
    if not isClose then
        return
    end
    XUiManager.TipMsg(XUiHelper.GetText("TransfiniteTowerTowerClosed"))
    self:Close()
end

function XUiTransfiniteTowerMain:OnEnable()
    self:Refresh()
    XMVCA.XFunction:EnterFunction(XFunctionManager.FunctionName.TransfiniteTower)
end

function XUiTransfiniteTowerMain:OnDisable()
    XMVCA.XFunction:ExitFunction(XFunctionManager.FunctionName.TransfiniteTower)
    self:StopTimeTimer()
end

function XUiTransfiniteTowerMain:OnDestroy()
    self:StopTimeTimer()
end

--region 初始化

function XUiTransfiniteTowerMain:InitTopControl()
    -- 通用顶部栏组件（BtnBack 默认 Close，BtnMainUi 默认返回主界面）
    self._TopControl = XUiHelper.NewPanelTopControl(self, self.TopControl)
end

function XUiTransfiniteTowerMain:InitStageGrids()
    ---@type XUiGridTransfiniteTowerStage[]
    self.StageGrids = {}
    for i = 1, #StageGridNodeNames do
        local node = self[StageGridNodeNames[i]]
        self.StageGrids[i] = XUiGridTransfiniteTowerStage.New(node, self)
    end
end

function XUiTransfiniteTowerMain:InitRewardBubble()
    self._TaskRewardGrids = {}
    self._TaskRewardData = {}
    self._RankRewardGrid = XUiGridCommon.New(self, self.Grid256NewRight)
end

function XUiTransfiniteTowerMain:RegisterButtonEvent()
    self.BtnTask:AddEventListener(handler(self, self.OnBtnTaskClick))
    self.BtnRank:AddEventListener(handler(self, self.OnBtnRankClick))
    self.BtnTeach:AddEventListener(handler(self, self.OnBtnTeachClick))
    self:BindHelpBtn(self.BtnHelp, "TransfiniteTowerHelp")
end

--endregion

--region 刷新

function XUiTransfiniteTowerMain:Refresh()
    self:RefreshStageGrids()
    self:RefreshTask()
    self:RefreshRewardBubble()
    self:RefreshTime()
end

function XUiTransfiniteTowerMain:RefreshStageGrids()
    local towerCfgIds = self._Control:GetMainTowerCfgIds()
    for i = 1, #self.StageGrids do
        self.StageGrids[i]:Refresh(towerCfgIds[i])
    end
end

function XUiTransfiniteTowerMain:RefreshTask()
    local finished, total = XMVCA.XTransfiniteTower:GetTaskProgress()
    self.BtnTask:SetNameByGroup(1, XUiHelper.GetText("TransfiniteTowerTaskProgress", finished, total))
end

function XUiTransfiniteTowerMain:RefreshRewardBubble()
    local rewards = XMVCA.XTransfiniteTower:GetTaskRewardPreview()
    local isShowBubble = rewards ~= nil
    self.CommonTaskRewardLeft.gameObject:SetActiveEx(isShowBubble)
    if isShowBubble then
        self._TaskRewards = rewards
        XUiHelper.RefreshCustomizedList(self.Grid256New.transform.parent, self.Grid256New,
            #rewards, handler(self, self.RefreshTaskRewardGrid))
    end
    local rankReward = self._Control:GetRankRewardPreview(self._Control:GetRankChapterId())
    self.Grid256NewRight.gameObject:SetActiveEx(rankReward ~= nil)
    if rankReward then
        self._RankRewardGrid:Refresh(rankReward)
    end
end

---任务奖励格填数据
function XUiTransfiniteTowerMain:RefreshTaskRewardGrid(index, go)
    local grid = self._TaskRewardGrids[index]
    if not grid then
        grid = XUiGridCommon.New(self, go)
        self._TaskRewardGrids[index] = grid
    end
    local data = self._TaskRewardData[index]
    if not data then
        data = {}
        self._TaskRewardData[index] = data
    end
    local reward = self._TaskRewards[index]
    data.TemplateId = reward.TemplateId
    data.Count = reward.Count
    grid:Refresh(data)
end

function XUiTransfiniteTowerMain:RefreshTime()
    self:UpdateTime()
    self:StopTimeTimer()
    self._TimeTimer = XScheduleManager.ScheduleForever(handler(self, self.UpdateTime), XScheduleManager.SECOND)
end

function XUiTransfiniteTowerMain:UpdateTime()
    local remainTime = XMVCA.XTransfiniteTower:GetActivityRemainTime()
    if remainTime <= 0 then
        self.TxtTime.text = ""
        self:StopTimeTimer()
        return
    end
    self.TxtTime.text = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
end

function XUiTransfiniteTowerMain:StopTimeTimer()
    if self._TimeTimer then
        XScheduleManager.UnSchedule(self._TimeTimer)
        self._TimeTimer = nil
    end
end

--endregion

--region 按钮回调

function XUiTransfiniteTowerMain:OnBtnTaskClick()
    self._Control:OpenTaskUi()
end

function XUiTransfiniteTowerMain:OnBtnRankClick()
    local isUnlock, unlockDaysDesc = self._Control:IsRankUnlock()
    if not isUnlock then
        XUiManager.TipMsg(unlockDaysDesc)
        return
    end
    self._Control:OpenRankUi()
end

function XUiTransfiniteTowerMain:OnBtnTeachClick()
    XLuaUiManager.Open("UiTransfiniteTowerTeach")
end

--endregion

return XUiTransfiniteTowerMain
