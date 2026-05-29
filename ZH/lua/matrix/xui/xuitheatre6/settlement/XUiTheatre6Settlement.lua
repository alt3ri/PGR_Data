--- 肉鸽6结算界面
---@class XUiTheatre6Settlement : XLuaUi
---@field _PanelDetail XUiPanelTheatre6SettlementDetail 养成展示面板
---@field _PanelSave XUiPanelTheatre6SettlementSave 保存存档界面
---@field private _Control XTheatre6Control
local XUiTheatre6Settlement = XLuaUiManager.Register(XLuaUi, "UiTheatre6Settlement")
local SETTLEMENT_RESULT_SHOW_TIME = 3000 

function XUiTheatre6Settlement:OnAwake()
    self.PanelResult.gameObject:SetActiveEx(false)
    self.PanelDetail.gameObject:SetActiveEx(false)
    self.PanelSave.gameObject:SetActiveEx(false)
end

function XUiTheatre6Settlement:OnStart(settleData, mode, isContinue)
    self.SettleData = settleData
    self.IsWin = self.SettleData.IsWin
    self._Mode = mode or self._Control:GetCurPlayMode()
    self._IsContinue = isContinue

    self._PanelDetail = require("XUi/XUiTheatre6/Settlement/Panel/XUiPanelTheatre6SettlementDetail").New(self.PanelDetail, self, self._Mode)
    self._PanelSave = require("XUi/XUiTheatre6/Settlement/Panel/XUiPanelTheatre6SettlementSave").New(self.PanelSave, self, self._Mode)
end

function XUiTheatre6Settlement:OnEnable()

    self:ShowPanelResult()
    XLuaUiManager.SafeClose("UiTheatre6RoomEitheror")
    XLuaUiManager.SafeClose("UiBiancaTheatreBlack")
end

function XUiTheatre6Settlement:OnDisable()
    
end

function XUiTheatre6Settlement:OnDestroy()
    
end

--region PanelResult（战斗结果）
function XUiTheatre6Settlement:ShowPanelResult()
    self:RefreshPanelResult()
    if self._IsContinue then
        self:ShowPanelDetail()
    else
        self.PanelResult.gameObject:SetActiveEx(true)
        self:PlayAnimationWithMask("PanelResultAnimEnable", function()
            self:PlayAnimationWithMask("PanelDetailTab")
            self:ShowPanelDetail()
        end)
    end
end

function XUiTheatre6Settlement:RefreshPanelResult()
    self.PanelWin.gameObject:SetActiveEx(self.IsWin)
    self.PanelLose.gameObject:SetActiveEx(not self.IsWin)
end
--endregion

--region PanelDetail（详情界面）
function XUiTheatre6Settlement:ShowPanelDetail()
    self.PanelResult.gameObject:SetActiveEx(false)
    self._PanelDetail:Open()
    self._PanelDetail:Refresh()
end
--endregion

--region PanelSave（保存存档界面）
function XUiTheatre6Settlement:ShowPanelSave()
    self.PanelDetail.gameObject:SetActiveEx(false)
    self._PanelSave:Open()
    self._PanelSave:Refresh(self._Mode)
end
--endregion

return XUiTheatre6Settlement
