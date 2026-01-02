
---@class XUiSkyGardenSGDroneGameScore : XUiNode
---@field TxtScore UnityEngine.UI.Text
---@field TxtTimeReward UnityEngine.UI.Text
---@field _Control XSkyGardenDroneGameControl
---@field Parent XUiSkyGardenSGDroneGame
local XUiSkyGardenSGDroneGameScore = XClass(XUiNode, "XUiSkyGardenSGDroneGameScore")

function XUiSkyGardenSGDroneGameScore:OnStart()
    self._Timer = false

    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneGameScore:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiSkyGardenSGDroneGameScore:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiSkyGardenSGDroneGameScore:OnDestroy()
end

function XUiSkyGardenSGDroneGameScore:Refresh(desc, score)
    self.TxtTimeReward.text = desc
    self.TxtScore.text = string.format("+%s", score)
    self:_RegisterTimer()
end

function XUiSkyGardenSGDroneGameScore:_RegisterButtonClicks()
    --在此处注册按钮事件
end

function XUiSkyGardenSGDroneGameScore:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiSkyGardenSGDroneGameScore:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiSkyGardenSGDroneGameScore:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiSkyGardenSGDroneGameScore:_RemoveSchedules()
    -- 在此处移除定时器
    self:_RemoveTimer()
end

function XUiSkyGardenSGDroneGameScore:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDroneGameScore:_RegisterTimer()
    self:_RemoveTimer()
    self._Timer = XScheduleManager.ScheduleOnce(function()
        self.Parent:RestoreScoreGrid(self)
        self:Close()
    end, XScheduleManager.SECOND * 3)
end

function XUiSkyGardenSGDroneGameScore:_RemoveTimer()
    if self._Timer then
        self.Parent:RestoreScoreGrid(self)
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

return XUiSkyGardenSGDroneGameScore
