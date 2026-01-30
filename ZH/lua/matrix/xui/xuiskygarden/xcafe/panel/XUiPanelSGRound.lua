---@class XUiPanelSGRound : XUiNode
---@field _Control XSkyGardenCafeControl
---@field Parent XUiSkyGardenCafeGame
---@field ImgBgBarInner UnityEngine.RectTransform
local XUiPanelSGRound = XClass(XUiNode, "XUiPanelSGRound")

local IsDebugBuild = CS.XApplication.Debug

function XUiPanelSGRound:OnStart(total)
    self._TotalRound = total
    self._CurRound = self._Control:GetBattle():GetBattleInfo():GetRound() - 1
    self:InitUi()
    self:InitCb()
end

function XUiPanelSGRound:OnDestroy()
    self:StopTimer()
    self:StopRoundActiveTimer()
end

function XUiPanelSGRound:Refresh(curRound)
    if self._CurRound == curRound then
        self.ImgBgBar.fillAmount = curRound / self._TotalRound
        self:StopTimer()
        return
    end
    self:StopTimer()
    
    self:PlayRunningEffect(curRound / self._TotalRound)
    local cur = self._CurRound
    self.Timer = self:Tween(0.5, function(dt)
        self.ImgBgBar.fillAmount = ((curRound - cur) * dt + cur) / self._TotalRound
    end, function() 
        self._CurRound = curRound
        self:PlayActiveEffect(curRound)
    end)
end

function XUiPanelSGRound:StopTimer()
    if not self.Timer then
        return
    end
    XScheduleManager.UnSchedule(self.Timer)
    self.Timer = false
end

function XUiPanelSGRound:StopRoundActiveTimer()
    if not self.RoundActiveTimer then
        return
    end
    XScheduleManager.UnSchedule(self.RoundActiveTimer)
    self.RoundActiveTimer = false
end

function XUiPanelSGRound:InitUi()
    local total = self._TotalRound
    self._GridRounds = {}
    for i = 1, total do
        local ui = i == 1 and self.GridRound or XUiHelper.Instantiate(self.GridRound, self.ListTimeRound)
        ---@type UiObject
        local uiObject = ui.transform:GetComponent("UiObject")
        uiObject:GetObject("TxtTime1").text = string.format(self._Control:GetRoundText(), i)
        uiObject:GetObject("ImgZs01").gameObject:SetActiveEx(i ~= total)
        uiObject:GetObject("EffectActive").gameObject:SetActiveEx(false)
        self._GridRounds[i] = uiObject
    end
    self.ImgBgBar.fillAmount = self._CurRound / self._TotalRound
    self.ImgBgBarInner.gameObject:SetActiveEx(false)
end

function XUiPanelSGRound:InitCb()
    if IsDebugBuild then
        self.Parent:RegisterClickEvent(self.Transform, self.DebugPrint) 
    end
end

function XUiPanelSGRound:PlayActiveEffect(round)
    local uiObject = self._GridRounds[round]
    if not uiObject then
        return
    end
    local effectActive = uiObject:GetObject("EffectActive")
    if not effectActive then
        return
    end
    effectActive.gameObject:SetActiveEx(false)
    effectActive.gameObject:SetActiveEx(true)
    self:StopRoundActiveTimer()
    self.RoundActiveTimer = XScheduleManager.ScheduleOnce(function()
        if effectActive then
            effectActive.gameObject:SetActiveEx(false)
        end
    end, 500)
end

function XUiPanelSGRound:PlayRunningEffect(progress)
    if self._IsRunning then
        return
    end
    self.ImgBgBarInner.gameObject:SetActiveEx(true)
    self.ImgBgBarInner.localScale = Vector3(progress, 1, 1)
    self._IsRunning = true
    self.Enable:PlayTimelineAnimation(function()
        self._IsRunning = false
        if self.ImgBgBarInner then
            self.ImgBgBarInner.gameObject:SetActiveEx(false)
        end
    end)
end

function XUiPanelSGRound:DebugPrint()
    if not IsDebugBuild then
        return
    end
    self._Control:GetBattle():GetRoundEntity():DebugPrintInfo()
end

return XUiPanelSGRound