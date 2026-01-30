--- 任务结算界面
---@class XUiTheatre5PopupTaskSettlement: XLuaUi
---@field _Control XTheatre5Control
local XUiTheatre5PopupTaskSettlement = XLuaUiManager.Register(XLuaUi, 'UiTheatre5PopupTaskSettlement')
local XUiTheatre5GridTaskDetail = require('XUi/XUiTheatre5/XUiTheatre5ChooseTask/XUiTheatre5GridTaskDetail')

function XUiTheatre5PopupTaskSettlement:OnAwake()
    if self.BtnSure then
        self.BtnSure:AddEventListener(handler(self, self.Close))
    end
end

function XUiTheatre5PopupTaskSettlement:OnStart(showItemId)
    ---@type XUiTheatre5GridTaskDetail
    self.PanelTaskDetail = XUiTheatre5GridTaskDetail.New(self.UiTheatre5GridTaskDetail, self)
    self.ShowItemId = showItemId
end

function XUiTheatre5PopupTaskSettlement:OnEnable()
    self.PanelTaskDetail:Refresh(XMVCA.XTheatre5.EnumConst.UITaskDetailShowType.InComplete, self._Control.MissionControl:GetCurMission(), self.ShowItemId)
    self.PanelTaskDetail:ShowTaskDetail()
end


return XUiTheatre5PopupTaskSettlement