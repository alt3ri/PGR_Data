--- 最终结算
---@class XUiTheatre5Settlement: XLuaUi
---@field private _Control XTheatre5Control
local XUiTheatre5Settlement = XLuaUiManager.Register(XLuaUi, 'UiTheatre5Settlement')
local XUiPanelTheatre5SettleTitle = require('XUi/XUiTheatre5/XUiTheatre5Settlement/XUiPanelTheatre5SettleTitle')
local XUiPanelTheatre5SettleGameDetail = require('XUi/XUiTheatre5/XUiTheatre5Settlement/XUiPanelTheatre5SettleGameDetail')
local XUiPanelTheatre5SettleReward = require('XUi/XUiTheatre5/XUiTheatre5Settlement/XUiPanelTheatre5SettleReward')

function XUiTheatre5Settlement:OnAwake()

end

---@param resultData XDlcFightSettleData
function XUiTheatre5Settlement:OnStart(resultData)
    self.ResultData = resultData

    self.PanelTitleMain.gameObject:SetActiveEx(true)
    self.PanelDetail.gameObject:SetActiveEx(true)
    self.PanelReward.gameObject:SetActiveEx(false)

    ---@type XUiPanelTheatre5SettleTitle
    self.PanelTitle = XUiPanelTheatre5SettleTitle.New(self.PanelTitleMain, self, self.ResultData)
    ---@type XUiPanelTheatre5SettleGameDetail
    self.PanelGameDetail = XUiPanelTheatre5SettleGameDetail.New(self.PanelDetail, self, self.ResultData)
    ---@type XUiPanelTheatre5SettleReward
    self.PanelReward = XUiPanelTheatre5SettleReward.New(self.PanelReward, self, self.ResultData)

    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        self._Control.PVPControl:StartPVPTimer()
    end
end

function XUiTheatre5Settlement:OnDestroy()
    if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        self._Control.PVPControl:ClearAdventureData()
        self._Control.PVPControl:StopPVPTimer()
    end
end

function XUiTheatre5Settlement:OnGameDetailNextEvent()
    self.PanelReward:Open()
    self:PlayAnimationWithMask('SecondToThird', function()
        self.PanelGameDetail:Close()
        -- 播放动画
        if self._Control:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
            self.PanelReward:ShowRankAnimation()
            -- 检查弹窗
            XEventManager.DispatchEvent(XEventId.EVENT_FIGHT_RESULT_WIN)
        end
        -- 检查引导
        XDataCenter.GuideManager.CheckGuideOpen()
    end)
end

function XUiTheatre5Settlement:OnRewardPreEvent()
    self.PanelGameDetail:Open()
    self:PlayAnimationWithMask('ThirdToSecond', function()
        self.PanelReward:Close()
    end)
end

return XUiTheatre5Settlement