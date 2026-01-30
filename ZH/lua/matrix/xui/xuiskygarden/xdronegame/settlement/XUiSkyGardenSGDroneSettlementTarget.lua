
---@class XUiSkyGardenSGDroneSettlementTarget : XUiNode
---@field TargetScore UnityEngine.UI.Text
---@field GridStar XUiComponent.XUiStateControl
---@field _Control XSkyGardenDroneGameControl
---@field Parent XUiSkyGardenSGDroneCheckpointSettlement
local XUiSkyGardenSGDroneSettlementTarget = XClass(XUiNode, "XUiSkyGardenSGDroneSettlementTarget")

function XUiSkyGardenSGDroneSettlementTarget:OnStart()
    self.GridStar:ChangeState("On")

    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneSettlementTarget:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneSettlementTarget:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneSettlementTarget:OnDestroy()
end

function XUiSkyGardenSGDroneSettlementTarget:Refresh(text, isSuccess)
    self.TargetScore.text = text
    self.GridStar:ChangeState(isSuccess and "On" or "Off")
end

function XUiSkyGardenSGDroneSettlementTarget:_RegisterButtonClicks()
    --在此处注册按钮事件
end

function XUiSkyGardenSGDroneSettlementTarget:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDroneSettlementTarget:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDroneSettlementTarget:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneSettlementTarget:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneSettlementTarget:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiSkyGardenSGDroneSettlementTarget
