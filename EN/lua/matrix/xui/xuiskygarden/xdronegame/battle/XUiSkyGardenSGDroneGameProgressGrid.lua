---@class XUiSkyGardenSGDroneGameProgressGrid : XUiNode
---@field ImgPointOff UnityEngine.RectTransform
---@field ImgPointOn UnityEngine.RectTransform
---@field ImgPointFinishLine UnityEngine.RectTransform
---@field ImgUAV UnityEngine.RectTransform
---@field LayoutElement UnityEngine.UI.LayoutElement
---@field _Control XSkyGardenDroneGameControl
---@field Parent XUiSkyGardenSGDroneGame
local XUiSkyGardenSGDroneGameProgressGrid = XClass(XUiNode, "XUiSkyGardenSGDroneGameProgressGrid")

function XUiSkyGardenSGDroneGameProgressGrid:OnStart(isEndPoint)
    self._IsEndPoint = isEndPoint
    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneGameProgressGrid:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneGameProgressGrid:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneGameProgressGrid:OnDestroy()
end

function XUiSkyGardenSGDroneGameProgressGrid:Refresh(isFinish, isCurrent, flexibleWidth)
    self.ImgPointOff.gameObject:SetActiveEx(not isFinish and not self._IsEndPoint)
    self.ImgPointOn.gameObject:SetActiveEx(isFinish and not self._IsEndPoint)
    self.ImgPointFinishLine.gameObject:SetActiveEx(self._IsEndPoint)
    self.ImgUAV.gameObject:SetActiveEx(isCurrent)
    self.LayoutElement.flexibleWidth = flexibleWidth * 10
end

function XUiSkyGardenSGDroneGameProgressGrid:_RegisterButtonClicks()
    --在此处注册按钮事件
end

function XUiSkyGardenSGDroneGameProgressGrid:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDroneGameProgressGrid:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDroneGameProgressGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneGameProgressGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneGameProgressGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiSkyGardenSGDroneGameProgressGrid
