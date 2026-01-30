---@class XUiSkyGardenDroneStageStar : XUiNode
---@field IconStarOn UnityEngine.RectTransform
---@field IconStarOff UnityEngine.RectTransform
---@field Parent XUiSkyGardenDroneStageGrid
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenDroneStageStar = XClass(XUiNode, "XUiSkyGardenDroneStageStar")

function XUiSkyGardenDroneStageStar:OnStart()
    self:_RegisterButtonClicks()
end

function XUiSkyGardenDroneStageStar:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenDroneStageStar:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenDroneStageStar:OnDestroy()
end

function XUiSkyGardenDroneStageStar:Refresh(isOn)
    self.IconStarOn.gameObject:SetActiveEx(isOn)
    self.IconStarOff.gameObject:SetActiveEx(not isOn)
end

function XUiSkyGardenDroneStageStar:_RegisterButtonClicks()
    --在此处注册按钮事件
end

function XUiSkyGardenDroneStageStar:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenDroneStageStar:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenDroneStageStar:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenDroneStageStar:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenDroneStageStar:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiSkyGardenDroneStageStar
