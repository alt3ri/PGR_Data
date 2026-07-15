---@class XUiTheatre6RoomTaskSettlement : XLuaUi 任务结算
---@field _Control XTheatre6Control
local XUiTheatre6RoomTaskSettlement = XLuaUiManager.Register(XLuaUi, "UiTheatre6RoomTaskSettlement")

function XUiTheatre6RoomTaskSettlement:OnAwake()
    self.BtnYes:AddEventListener(handler(self, self.OnBtnYesClick))
    self.BtnCharacter:AddEventListener(handler(self, self.OnBtnCharacterClick))
    ---@type XUiPanelTheatre6TopSan
    self._PanelSan = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6TopSan").New(self.PanelSan, self)
    ---@type XUiPanelTheatre6Asset
    self._PanelAsset = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6Asset").New(self.PanelAsset, self)
    ---@type XUiPanelTheatre6BottomBuffList
    self._PanelBuff = require("XUi/XUiTheatre6/Stage/Panel/XUiPanelTheatre6BottomBuffList").New(self.ListBuff, self)
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

    -- self:TryOpenSellSkillPanel()
end

function XUiTheatre6RoomTaskSettlement:OnEnable()
    self._PanelAsset:Refresh()
    self._PanelBuff:UpdateView()
    self:ShowRoleInfo()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_SCORE_CHANGE, self.ShowRoleInfo, self)
end

function XUiTheatre6RoomTaskSettlement:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_SCORE_CHANGE, self.ShowRoleInfo, self)
end

function XUiTheatre6RoomTaskSettlement:ShowRoleInfo()
    self.BtnCharacter:SetRawImage(self._Control:GetHeadIcon())
    self.BtnCharacter:SetName(self._ModelData.ScoreTotal)
end

function XUiTheatre6RoomTaskSettlement:OnBtnYesClick()
    if self:TryOpenSellSkillPanel() then
        return
    end
    local control = self._Control
    self._Control:RequestRecvTaskRoomReward(function()
        control:OpenChooseRoom(true)
    end)
end

function XUiTheatre6RoomTaskSettlement:TryOpenSellSkillPanel()
    return self._Control:CheckForceSellSkillBlock()
end

function XUiTheatre6RoomTaskSettlement:OnBtnCharacterClick()
    XLuaUiManager.Open("UiTheatre6PopupRoleDetail", self.BtnCharacter.transform)
end

return XUiTheatre6RoomTaskSettlement
