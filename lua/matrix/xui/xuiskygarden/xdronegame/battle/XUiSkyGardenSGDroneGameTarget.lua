
---@class XUiSkyGardenSGDroneGameTarget : XUiNode
---@field TargetScoreOn UnityEngine.UI.Text
---@field TargetScoreOff UnityEngine.UI.Text
---@field GridStar XUiComponent.XUiStateControl
---@field _Control XSkyGardenDroneGameControl
---@field Parent XUiSkyGardenSGDroneGame
local XUiSkyGardenSGDroneGameTarget = XClass(XUiNode, "XUiSkyGardenSGDroneGameTarget")

function XUiSkyGardenSGDroneGameTarget:OnStart()
    self._Text = false
    self._IsFinish = false

    self:SetFinish(false)
    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneGameTarget:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneGameTarget:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneGameTarget:OnDestroy()
end

function XUiSkyGardenSGDroneGameTarget:SetText(text)
    self._Text = text
end

function XUiSkyGardenSGDroneGameTarget:SetFinish(isFinish)
    self._IsFinish = isFinish
    self.GridStar:ChangeState(isFinish and "On" or "Off")
    self.TargetScoreOn.gameObject:SetActiveEx(isFinish)
    self.TargetScoreOff.gameObject:SetActiveEx(not isFinish)
end

function XUiSkyGardenSGDroneGameTarget:SetProgress(progress, totalProgress)
    if self._Text then
        local text = string.gsub(self._Text, "%[0%]", tostring(progress))

        text = string.gsub(text, "%[1%]", tostring(totalProgress))

        self.TargetScoreOn.text = text
        self.TargetScoreOff.text = text
    end
end

function XUiSkyGardenSGDroneGameTarget:GetIsFinish()
    return self._IsFinish
end

function XUiSkyGardenSGDroneGameTarget:_RegisterButtonClicks()
    --在此处注册按钮事件
end

function XUiSkyGardenSGDroneGameTarget:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDroneGameTarget:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDroneGameTarget:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneGameTarget:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiSkyGardenSGDroneGameTarget:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

return XUiSkyGardenSGDroneGameTarget
