---@class XUiTheatre6RoomTaskSettlement : XLuaUi 任务结算
---@field _Control XTheatre6Control
local XUiTheatre6RoomTaskSettlement = XLuaUiManager.Register(XLuaUi, "UiTheatre6RoomTaskSettlement")

function XUiTheatre6RoomTaskSettlement:OnAwake()
    self.BtnYes:AddEventListener(handler(self, self.OnBtnYesClick))
    ---@type XUiPanelTheatre6TopSan
    self._PanelSan = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopSan").New(self.PanelSan, self)
    ---@type XUiPanelTheatre6Asset
    self._PanelAsset = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6Asset").New(self.PanelAsset, self)
    require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6MessyCodeFx").New(self.MessyCodeFx, self)
end

function XUiTheatre6RoomTaskSettlement:OnStart()
    self._ModelData = self._Control:GetCurPlayModeData()

    local datas = self._Control:GetStageActivatedTaskSort()
    XUiHelper.RefreshCustomizedList(self.GridTask.parent, self.GridTask, #datas, function(i, go)
        ---@type XUiGridTheatre6TaskDetail
        local grid = require("XUi/XUiTheatre6/Task/Grid/XUiGridTheatre6TaskDetail").New(go, self)
        grid:SetData(datas[i], true)
    end)

    self:TryOpenSellSkillPanel()
end

function XUiTheatre6RoomTaskSettlement:OnEnable()
    self._PanelAsset:Refresh()
end

function XUiTheatre6RoomTaskSettlement:OnBtnYesClick()
    if self:TryOpenSellSkillPanel() then
        return
    end
    self._Control:RequestRecvTaskRoomReward(function()
        local control = self._Control
        self:Close()
        control:OpenChooseRoom()
    end)
end

function XUiTheatre6RoomTaskSettlement:TryOpenSellSkillPanel()
    return self._Control:CheckForceSellSkillBlock()
end

return XUiTheatre6RoomTaskSettlement
