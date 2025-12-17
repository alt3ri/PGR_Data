---@class XUiBigWorldObtain : XBigWorldUi 空花奖励界面
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
local XUiBigWorldObtain = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldObtain")

local XUiSGGridItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

local OpType = XMVCA.XBigWorldQuest.QuestOpType

function XUiBigWorldObtain:OnAwake()
    self._AutoCloseTimer = nil

    self:InitUi()
    self:InitCb()

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupBegin)
end

function XUiBigWorldObtain:OnStart(rewardData, title, closeCb, disableAutoClose)
    self.RewardList = XMVCA.XBigWorldService:GetRewardDataList(rewardData, true)
    if title and self.TxtTitle then
        self.TxtTitle.text = title
    end
    self.CloseCb = closeCb
    self._DisableAutoClose = disableAutoClose
    self:InitView()
end

function XUiBigWorldObtain:OnEnable()
    if not self._DisableAutoClose then
        self:RegisterAutoClose()
    end
end

function XUiBigWorldObtain:OnDisable()
    self:UnRegisterAutoClose()
end

function XUiBigWorldObtain:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_QUEST_OBJECTIVE_STATE_CHANGED, OpType.PopupEnd)
    self:RemoveCb()
end

function XUiBigWorldObtain:InitUi()
    self.GridCommon.gameObject:SetActiveEx(false)
    ---@type XUiGridBWItem[]
    self.GridRewards = {}
end

function XUiBigWorldObtain:InitCb()
    self.BtnBack:AddEventListener(handler(self, self.Close))
end

function XUiBigWorldObtain:RemoveCb()
end

function XUiBigWorldObtain:InitView()
    self:RefreshReward()
end

function XUiBigWorldObtain:RefreshReward()
    for _, grid in pairs(self.GridRewards) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid:Close()
        end
    end

    local isSetClickProxy = self:IsSetGridClickProxy()
    for i, reward in ipairs(self.RewardList) do
        local grid = self.GridRewards[i]
        if not grid then
            local ui = i == 1 and self.GridCommon or XUiHelper.Instantiate(self.GridCommon, self.PanelContent)
            local proxy = isSetClickProxy and handler(self, self.OnClickProxy) or false
            grid = XUiSGGridItem.New(ui, self, proxy)
            self.GridRewards[i] = grid
        end
        grid:Open()
        grid:Refresh(reward)
    end
end

function XUiBigWorldObtain:RegisterAutoClose()
    local time = self:GetShowTime()

    self:UnRegisterAutoClose()
    self._AutoCloseTimer = XScheduleManager.ScheduleOnce(function()
        self._AutoCloseTimer = nil
        self:Close()
    end, XScheduleManager.SECOND * time)
end

function XUiBigWorldObtain:IsSetGridClickProxy()
    return false
end

function XUiBigWorldObtain:OnClickProxy()
end

function XUiBigWorldObtain:GetShowTime()
    return XMVCA.XBigWorldGamePlay:GetCurrentAgency():GetFloat("BigWorldObtainShowTime")
end

function XUiBigWorldObtain:UnRegisterAutoClose()
    if XTool.IsNumberValid(self._AutoCloseTimer) then
        XScheduleManager.UnSchedule(self._AutoCloseTimer)
        self._AutoCloseTimer = nil
    end
end

return XUiBigWorldObtain
