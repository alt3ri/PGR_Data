local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiSkyGardenDroneStageDetailGrid : XUiNode
---@field TxtTitle UnityEngine.UI.Text
---@field GridStar XUiComponent.XUiStateControl
---@field GridReward UnityEngine.RectTransform
---@field Parent XUiSkyGardenSGDroneStageDetail
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenDroneStageDetailGrid = XClass(XUiNode, "XUiSkyGardenDroneStageDetailGrid")

function XUiSkyGardenDroneStageDetailGrid:OnStart()
    ---@type XUiGridBWItem
    self._Grid = XUiGridBWItem.New(self.GridReward, self)

    self:_RegisterButtonClicks()
end

function XUiSkyGardenDroneStageDetailGrid:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenDroneStageDetailGrid:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenDroneStageDetailGrid:OnDestroy()
end

function XUiSkyGardenDroneStageDetailGrid:Refresh(targetId, reward, isComplete)
    self.TxtTitle.text = self._Control:GetTargetDescription(targetId)
    self.GridStar:ChangeState(isComplete and "On" or "Off")
    self._Grid:Open()
    self._Grid:Refresh(reward)
    self._Grid.PanelReceive.gameObject:SetActiveEx(isComplete)
end

function XUiSkyGardenDroneStageDetailGrid:_RegisterButtonClicks()
    --在此处注册按钮事件
end

function XUiSkyGardenDroneStageDetailGrid:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenDroneStageDetailGrid:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenDroneStageDetailGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenDroneStageDetailGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenDroneStageDetailGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiSkyGardenDroneStageDetailGrid
