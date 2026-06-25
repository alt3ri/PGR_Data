---@class XUiPanelTheatre6PvpEnergy : XUiNode
---@field _Control XTheatre6Control
---@field Parent XUiTheatre6PVPMain
local XUiPanelTheatre6PvpEnergy = XClass(XUiNode, "XUiPanelTheatre6PvpEnergy")

function XUiPanelTheatre6PvpEnergy:OnStart()
    self.BtnEnergy:AddEventListener(handler(self, self.OnBtnEnergyClick))
    self.BtnBubbleClose:AddEventListener(handler(self, self.OnBtnBubbleCloseClick))
    self.PanelBubbleEnergy.gameObject:SetActiveEx(false)
    self.IsClickBubble = false
end

function XUiPanelTheatre6PvpEnergy:OnGetLuaEvents()
    return {
        XEventId.EVENT_THEATRE6_PVP_ACTION_POINT_UPDATE
    }
end

function XUiPanelTheatre6PvpEnergy:OnNotify(event, ...)
    if event == XEventId.EVENT_THEATRE6_PVP_ACTION_POINT_UPDATE then
        self:Refresh()
        if self.IsClickBubble then
            self:RefreshBubble()
        end
    end
end

function XUiPanelTheatre6PvpEnergy:OnDisable()
    self:CloseBubble()
end

function XUiPanelTheatre6PvpEnergy:OnDestroy()
    self:StopTimer()
end

function XUiPanelTheatre6PvpEnergy:Refresh()
    local isExist = self._Control:GetPvpIsExistActionPoint()
    local curActionPoint = self._Control:GetPvpCurActionPoint()
    local maxActionPoint = self._Control:GetPvpMaxActionPoint()
    local index = curActionPoint <= 0 and 2 or 1
    local actionPointContent = self._Control:GetPvpClientConfigValue("ActionPointContent", index)

    if not isExist then
        curActionPoint = "-"
    end

    self.BtnEnergy:SetNameByGroup(0, string.format(actionPointContent, curActionPoint, maxActionPoint))
end

function XUiPanelTheatre6PvpEnergy:RefreshBubble()
    self:StopTimer()
    if self._Control:IsPvpActionPointFull() then
        self._NextRecoverTime = nil
        self.TxtDetail.text = self._Control:GetPvpClientConfigValue("ActionPointDetailContent", 1)
        return
    end
    local lastActionPointRecoverTime = self._Control:GetPvpLastActionPointRecoverTime()
    local actionPointRecoverInterval = self._Control:GetPvpActionPointRecoverInterval()
    self._NextRecoverTime = lastActionPointRecoverTime + actionPointRecoverInterval
    self:UpdateRecoverText()
    if self._NextRecoverTime > XTime.GetServerNowTimestamp() then
        self:StartTimer()
    end
end

function XUiPanelTheatre6PvpEnergy:UpdateRecoverText()
    local nextRecoverTime = self._NextRecoverTime or 0
    local left = math.max(0, nextRecoverTime - XTime.GetServerNowTimestamp())
    if left <= 0 then
        self:StopTimer()
        local detailContent = self._Control:GetPvpClientConfigValue("ActionPointDetailContent", 3)
        self.TxtDetail.text = detailContent
    else
        local timeStr = XUiHelper.GetTime(left, XUiHelper.TimeFormatType.GUILDCD)
        local detailContent = self._Control:GetPvpClientConfigValue("ActionPointDetailContent", 2)
        self.TxtDetail.text = string.format(detailContent, timeStr)
    end
end

function XUiPanelTheatre6PvpEnergy:ShowEnergyChange(changeValue)
    self.TxtNum.gameObject:SetActiveEx(true)
    self.TxtNum.text = changeValue >= 0 and string.format("+%s", changeValue) or changeValue
end

function XUiPanelTheatre6PvpEnergy:HideEnergyChange()
    self.TxtNum.gameObject:SetActiveEx(false)
end

function XUiPanelTheatre6PvpEnergy:StartTimer()
    self:StopTimer()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateRecoverText()
    end, XScheduleManager.SECOND)
end

function XUiPanelTheatre6PvpEnergy:StopTimer()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = nil
    end
end

function XUiPanelTheatre6PvpEnergy:OnBtnEnergyClick()
    self:RefreshBubble()
    self.PanelBubbleEnergy.gameObject:SetActiveEx(true)
    self.IsClickBubble = true
end

function XUiPanelTheatre6PvpEnergy:OnBtnBubbleCloseClick()
    self:CloseBubble()
end

function XUiPanelTheatre6PvpEnergy:CloseBubble()
    self:StopTimer()
    self.PanelBubbleEnergy.gameObject:SetActiveEx(false)
    self.IsClickBubble = false
end

return XUiPanelTheatre6PvpEnergy
