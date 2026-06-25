---@class XUiConcertPreHeatingTuningStageCorrectTips : XLuaUi
local XUiConcertPreHeatingTuningStageCorrectTips = XLuaUiManager.Register(
    XLuaUi,
    "UiConcertPreHeatingTuningStageCorrectTips"
)

function XUiConcertPreHeatingTuningStageCorrectTips:OnAwake()
    self:InitButton()
end

function XUiConcertPreHeatingTuningStageCorrectTips:OnStart(closeCb)
    self._CloseCb = closeCb
    self:InitTime()
end

function XUiConcertPreHeatingTuningStageCorrectTips:InitButton()
    self.BtnClose.CallBack = handler(self, self.OnBtnCloseClick)
end

function XUiConcertPreHeatingTuningStageCorrectTips:InitTime()
    local endTime = XMVCA.XConcertPreHeating:GetActivityEndTime()
    if not XTool.IsNumberValid(endTime) then
        return
    end

    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XMVCA.XConcertPreHeating:HandleActivityEnd()
        end
    end)
end

function XUiConcertPreHeatingTuningStageCorrectTips:OnBtnCloseClick()
    local closeCb = self._CloseCb
    self:Close()

    if closeCb then
        closeCb()
    end
end

return XUiConcertPreHeatingTuningStageCorrectTips
