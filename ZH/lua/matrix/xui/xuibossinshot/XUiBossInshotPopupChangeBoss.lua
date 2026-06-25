
---@class XUiBossInshotPopupChangeBoss:XLuaUi

local XUiBossInshotPopupChangeBoss =
    XLuaUiManager.Register(XLuaUi, "UiBossInshotPopupChangeBoss")

function XUiBossInshotPopupChangeBoss:OnStart(
    control,
    towerData,
    stageSelections,
    onSelectConfirmCb)

    self._OnSelectConfirmCb = onSelectConfirmCb
    self._TowerData = towerData
    self._Ctrl = control
    self.BtnConfirm.CallBack = handler(self, self._OnConfirm)
    self.BtnClose.CallBack = handler(self, self.Close)

    local currentSelected = towerData.SelectStageId
    if towerData.SelectStageIdAfterAllPass
        and towerData.SelectStageIdAfterAllPass ~= 0 then
        currentSelected = towerData.SelectStageIdAfterAllPass
    end

    self._BossGrids = {}

    XTool.SetDataForGenericGrid(
        self._BossGrids,
        stageSelections,
        self.GirdBoss.gameObject,
        self.ListBossContent,
        self,
        require("XUi/XUiBossInshot/XUiGridBossInshotPopupChangeBoss"),
        {
            SelectCallback = handler(self, self._OnSelectBoss),
            CurrentSelected = currentSelected,
            Control = control
        })

    self:_OnSelectBoss(currentSelected)

    for _, g in pairs(self._BossGrids) do
        g:Close()
    end

    self._FlyInIndex = 1

    XLuaUiManager.SetMask(true)
    self._FlyInSchedule = XScheduleManager.ScheduleForever(
        function()
            local grid = self._BossGrids[self._FlyInIndex]
            if grid then
                grid:Open()
                grid:PlayFlyInAnimation()
                self._FlyInIndex = self._FlyInIndex + 1
            else
                XScheduleManager.UnSchedule(self._FlyInSchedule)
                self._FlyInSchedule = nil
                XLuaUiManager.SetMask(false)
            end
        end,
        CS.XGame.ClientConfig:GetInt("BossInshotTowerChangeBossGridShowInterval"),
        CS.XGame.ClientConfig:GetInt("BossInshotTowerChangeBossGridShowDelay"))
end

function XUiBossInshotPopupChangeBoss:_OnSelectBoss(stageId)

    self._SelectedStageId = stageId

    for _, bossGrid in pairs(self._BossGrids) do
        bossGrid:SetSelected(bossGrid:GetStageId() == stageId)
    end
end

function XUiBossInshotPopupChangeBoss:_OnConfirm()
    assert(self._SelectedStageId)
    self._OnSelectConfirmCb(self._SelectedStageId)
    self:Close()
end

return XUiBossInshotPopupChangeBoss
