---@class XUiSkyGardenSGDroneFailureSettlementGrid : XUiNode
---@field ImgUAV UnityEngine.RectTransform
---@field ImgPointOff UnityEngine.RectTransform
---@field ImgPointOn UnityEngine.RectTransform
---@field _Control XSkyGardenDroneGameControl
---@field Parent XUiSkyGardenSGDroneFailureSettlement
local XUiSkyGardenSGDroneFailureSettlementGrid = XClass(XUiNode, "XUiSkyGardenSGDroneFailureSettlementGrid")

function XUiSkyGardenSGDroneFailureSettlementGrid:OnStart()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneFailureSettlementGrid:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneFailureSettlementGrid:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneFailureSettlementGrid:OnDestroy()
end

function XUiSkyGardenSGDroneFailureSettlementGrid:Refresh(isPass, isCurrent)
    self.ImgPointOff.gameObject:SetActiveEx(not isPass)
    self.ImgPointOn.gameObject:SetActiveEx(isPass)
    self.ImgUAV.gameObject:SetActiveEx(isCurrent)
end

function XUiSkyGardenSGDroneFailureSettlementGrid:_RegisterButtonClicks()
    --在此处注册按钮事件
end

function XUiSkyGardenSGDroneFailureSettlementGrid:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDroneFailureSettlementGrid:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDroneFailureSettlementGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneFailureSettlementGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneFailureSettlementGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiSkyGardenSGDroneFailureSettlementGrid
