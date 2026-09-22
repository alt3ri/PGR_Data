local XUiGridPunishaarStage = XClass(XUiNode, "XUiGridPunishaarStage")
--关卡子组件
function XUiGridPunishaarStage:OnStart()
    self.BtnStage:AddEventListener(function ()
            self:OnClick()
    end)
    self._ButtonStateViewList = {
        {
            NowBg = self.NowBgNormal,
            TagClear = self.TagClearNormal,
        },
        {
            NowBg = self.NowBgPress,
            TagClear = self.TagClearPress,
        },
    }
end

function XUiGridPunishaarStage:InitStage(stageId)
    self.StageId = stageId

    local stageCfg = XMVCA.XPunishaar:GetTablePunishaarStageGroupById(stageId)
    self._IsEndless = self._Control:IsEndlessStage(stageId)

    -- 序号和名称
    self.BtnStage:SetNameByGroup(0, string.format("%02d", stageId % 100))
    self.BtnStage:SetNameByGroup(1, stageCfg and stageCfg.Name or "")
end

function XUiGridPunishaarStage:Refresh()
    local stageStatus = XMVCA.XPunishaar:GetStageStatus(self.StageId)
    self:RefreshStatus(stageStatus)
end

function XUiGridPunishaarStage:OnClick()
    local status = XMVCA.XPunishaar:GetStageStatus(self.StageId)

    if status == XMVCA.XPunishaar.EnumConst.StageStatus.NotOpen then
        local stageCfg = XMVCA.XPunishaar:GetTablePunishaarStageGroupById(self.StageId, true)
        local tipText

        if stageCfg and XTool.IsNumberValidEx(stageCfg.TimeId) then
            local startTime = XFunctionManager.GetStartTimeByTimeId(stageCfg.TimeId)
            local now = XTime.GetServerNowTimestamp()

            if XTool.IsNumberValidEx(startTime) and now < startTime then
                local timeText = XTime.TimestampToGameDateTimeString(startTime, "yyyy/MM/dd HH:mm")

                local format = self._Control:GetStageUnlockTimeTipText()
                if not string.IsNilOrEmpty(format) then
                    tipText = XUiHelper.FormatTextEx(format, timeText)
                end
            end
        end

        -- 已到时间但前置关卡未通关
        if string.IsNilOrEmpty(tipText) then
            tipText = self._Control:GetStageNotOpenTipText()
        end
        if not string.IsNilOrEmpty(tipText) then
            XUiManager.TipMsg(tipText)
        end

        return
    end

    self._Control:MarkStageRead(self.StageId)
    self.BtnStage:ShowReddot(false)
    XLuaUiManager.Open("UiPunishaarExploreDetail", self.StageId)
end

function XUiGridPunishaarStage:RefreshIfStatusChanged()
    local stageStatus = XMVCA.XPunishaar:GetStageStatus(self.StageId)

    if self._StageStatus == stageStatus then
        return
    end

    self:RefreshStatus(stageStatus)
end

function XUiGridPunishaarStage:RefreshStatus(stageStatus)
    self._StageStatus = stageStatus

    local isLocked = stageStatus == XMVCA.XPunishaar.EnumConst.StageStatus.NotOpen
    local isHasSave = stageStatus == XMVCA.XPunishaar.EnumConst.StageStatus.HasSave
    local isPassed = stageStatus == XMVCA.XPunishaar.EnumConst.StageStatus.Passed

    -- 未解锁 / 正常状态
    self.BtnStage:SetButtonState(isLocked and CS.UiButtonState.Disable or CS.UiButtonState.Normal)

    -- 通关标记
    local isShowClear = isPassed and not self._IsEndless

    for _, view in ipairs(self._ButtonStateViewList) do
        view.TagClear.gameObject:SetActiveEx(isShowClear)
        view.NowBg.gameObject:SetActiveEx(not isShowClear)
    end

    -- 存档状态
    self.TagInProgress.gameObject:SetActiveEx(isHasSave)

    -- 当前节点进度
    if isHasSave then
        local cur, total = XMVCA.XPunishaar:GetStageProgress(self.StageId)
        self.TxtProgress.text = XUiHelper.FormatTextEx(self._Control:GetStageProgressText(), cur, total)

        if self._IsEndless then
            self.TxtInProgress.text = XUiHelper.FormatTextEx(
                self._Control:GetStageEndlessRoundText(),
                self._Control:GetStageSaveRound(self.StageId)
            )
        else
            self.TxtInProgress.text = self._Control:GetStageInProgressText()
        end
    end

    XRedPointManager.CheckOnceByButton(
        self.BtnStage,
        {
            XRedPointConditions.Types.CONDITION_PUNISHAAR_STAGE
        },
        self.StageId
    )
end

return XUiGridPunishaarStage
