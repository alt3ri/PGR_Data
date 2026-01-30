local XUiGridBWRewardBar = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWRewardBar")

---@class XUiBigWorldRewardSidebar : XBigWorldUi
---@field RewardBar UnityEngine.RectTransform
---@field PanelRewardTips UnityEngine.RectTransform
local XUiBigWorldRewardSidebar = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldRewardSidebar")

function XUiBigWorldRewardSidebar:OnAwake()
    self._RewardList = {}
    self._RewardData = {}
    self._CloseCallback = false

    self._MaxCount = 8
    self._IsShowing = true

    ---@type XUiGridBWRewardBar[]
    self._RewardBarList = {}

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED,
        XMVCA.XBigWorldQuest.QuestOpType.PopupBegin)
end

function XUiBigWorldRewardSidebar:OnStart(rewardData, closeCallback)
    self._RewardList = XMVCA.XBigWorldService:GetRewardDataList(rewardData, true)
    self._CloseCallback = closeCallback

    self:_InitUi()
    self:_InitRewardData()
end

function XUiBigWorldRewardSidebar:OnEnable()
    self._IsShowing = true
    self:_Refresh()
end

function XUiBigWorldRewardSidebar:OnDisable()
    self._IsShowing = false
end

function XUiBigWorldRewardSidebar:OnDestroy()
    if self._CloseCallback then
        self._CloseCallback()
    end

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED,
        XMVCA.XBigWorldQuest.QuestOpType.PopupEnd)
end

function XUiBigWorldRewardSidebar:_InitUi()
    self.RewardBar.gameObject:SetActiveEx(false)
end

function XUiBigWorldRewardSidebar:_InitRewardData()
    if not XTool.IsTableEmpty(self._RewardList) then
        local rewardBarData = {}
        local count = 0
        local index = 1

        for _, reward in pairs(self._RewardList) do
            count = count + 1

            if count > self._MaxCount then
                index = index + 1
                count = 0
            end

            rewardBarData[index] = rewardBarData[index] or {}
            table.insert(rewardBarData[index], reward)
        end

        self._RewardData = rewardBarData
    end
end

function XUiBigWorldRewardSidebar:_Refresh()
    RunAsyn(Handler(self, self._RefreshAsync))
end

function XUiBigWorldRewardSidebar:_RefreshAsync()
    if XTool.IsTableEmpty(self._RewardData) then
        return
    end

    for i, rewardList in pairs(self._RewardData) do
        if not self:_AwaitSecond(0.3) then
            return
        end

        local showRewardBar = self:_RefreshRewardBar(rewardList)

        for _, bar in pairs(showRewardBar) do
            bar:Open()
            bar:PlayAnimation("RewardLevelEnable")

            if not self:_AwaitSecond(0.2) then
                return
            end
        end

        if not self:_AwaitSecond(1) then
            return
        end

        local showCount = table.nums(showRewardBar)

        for index, bar in pairs(showRewardBar) do
            if i == table.nums(self._RewardData) then
                bar:PlayAnimation("RewardLevelDisable", function()
                    if index == showCount then
                        self:Close()
                    end
                end)
            else
                bar:PlayAnimation("RewardLevelDisable")
            end
        end
    end
end

---@return XUiGridBWRewardBar[]
function XUiBigWorldRewardSidebar:_RefreshRewardBar(rewardList)
    local showRewardBar = {}

    if not XTool.IsTableEmpty(rewardList) then
        for i, reward in pairs(rewardList) do
            local gridBar = self._RewardBarList[i]

            if not gridBar then
                local grid = i == 1 and self.RewardBar or XUiHelper.Instantiate(self.RewardBar, self.PanelRewardTips)

                gridBar = XUiGridBWRewardBar.New(grid, self)
                self._RewardBarList[i] = gridBar
            end

            gridBar:Close()
            gridBar:Refresh(reward)
            table.insert(showRewardBar, gridBar)
        end
    end
    for i = table.nums(rewardList) + 1, table.nums(self._RewardBarList) do
        self._RewardBarList[i]:Close()
    end

    return showRewardBar
end

function XUiBigWorldRewardSidebar:_AwaitSecond(second)
    if self._IsShowing then
        asynWaitSecond(second)

        return self._IsShowing
    end

    return false
end

return XUiBigWorldRewardSidebar
