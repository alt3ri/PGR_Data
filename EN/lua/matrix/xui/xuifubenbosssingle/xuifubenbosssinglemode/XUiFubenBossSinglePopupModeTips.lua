local XUiFubenBossSinglePopupModeTips = XLuaUiManager.Register(
    XLuaUi,
    "UiFubenBossSinglePopupModeTips")

function XUiFubenBossSinglePopupModeTips:OnStart(bossRightPanel)

    self._BossRightPanel = bossRightPanel

    self.BtnTanchuangClose.CallBack = function() self:Close() end

    self.BtnSelectModule.CallBack = function()
        self:Close()
        bossRightPanel:_OnBtnSelectModuleClick()
    end

    self.BtnGoFight.CallBack = handler(self, self.OnGoFightBtnClick)
end

local NoMoreTipsTodayHint = "XUiFubenBossSinglePopupModeTips_NoMoreTipsTodayHint"

function XUiFubenBossSinglePopupModeTips:OnGoFightBtnClick()
    local noMoreTipToday =
        self.BtnIgnoreToday.ButtonState == CS.UiButtonState.Select

    self:Close()

    if noMoreTipToday then
        local tomorrow = XTime.GetSeverTomorrowFreshTime()
        XSaveTool.SaveData(NoMoreTipsTodayHint, tostring(tomorrow))
    end

    self._BossRightPanel:StartGameWithEmptyBuffSelection()
end

function XUiFubenBossSinglePopupModeTips.IsNoMoreTipsToday()
    local tomorrowStr = XSaveTool.GetData(NoMoreTipsTodayHint)

    if not tomorrowStr or tomorrowStr == "" then
        return false
    end

    local tomorrow = tonumber(tomorrowStr)
    return tomorrow > XTime.GetServerNowTimestamp()
end

return XUiFubenBossSinglePopupModeTips
