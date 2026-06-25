---@class XUiTheatre6PopupChooseEnvironment : XLuaUi pvp环境选择弹窗
---@field _Control XTheatre6Control
local XUiTheatre6PopupChooseEnvironment = XLuaUiManager.Register(XLuaUi, "UiTheatre6PopupChooseEnvironment")

local LineupMode = XEnumConst.Theatre6.Pvp.LineupMode

function XUiTheatre6PopupChooseEnvironment:OnAwake()
    self.BtnYes:AddEventListener(handler(self, self.OnBtnYesClick))
    self.BtnTanchuangCloseWhite:AddEventListener(handler(self, self.Close))
end

---@param pvpCamp number 攻击方/防御方
function XUiTheatre6PopupChooseEnvironment:OnStart(pvpCamp)
    self._PvpCamp = pvpCamp
    ---@type XUiPanelTheatre6PvpEnvironmentDetail
    self._EnvDetail = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpEnvironmentDetail").New(self.PanelDetail, self)
end

function XUiTheatre6PopupChooseEnvironment:OnEnable()
    local rankIndex = self._Control:GetPvpCurRankId()
    local rankConfig = self._Control:GetPvpRankConfig(rankIndex)
    local groupId = rankConfig.PvpBuffGroupId

    if not XTool.IsNumberValid(groupId) then
        XLog.Error(string.format("段位%s不存在环境效果", rankIndex))
        return
    end

    local tabs = {}
    local groupConfig = self._Control:GetPvpBuffGroupConfig(groupId)
    local buffIds = self._PvpCamp == LineupMode.Attack and groupConfig.AttBuffs or groupConfig.DefBuffs
    XUiHelper.RefreshCustomizedList(self.GridEnvironment.parent, self.GridEnvironment, #buffIds, function(i, go)
        ---@type XUiGridTheatre6PvpEnvironment
        local grid = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpEnvironment").New(go, self)
        grid:SetData(buffIds[i])
        table.insert(tabs, grid.GridEnvironment)
    end)

    local historyEnvId = self._Control:GetPvpCurrentLineupBuffId(self._PvpCamp)
    local selectIndex = historyEnvId and table.indexof(buffIds, historyEnvId) or 1
    self.ListEnvironment:Init(tabs, function(index)
        self._SelectEnvId = buffIds[index]
        self._EnvDetail:SetData(self._SelectEnvId)
    end)
    self.ListEnvironment:SelectIndex(selectIndex)
end

function XUiTheatre6PopupChooseEnvironment:OnBtnYesClick()
    local config = self._Control:GetPvpBuffConfig(self._SelectEnvId)
    if XTool.IsNumberValid(config.ConditionId) then
        local result, _ = XConditionManager.CheckCondition(config.ConditionId)
        if not result then
            self._Control:ShowTipWithKey("Theatre6PvpEnvReplaceFail")
            return
        end
    end
    self._Control:TryPvpUpCurrentLineupBuffId(self._PvpCamp, self._SelectEnvId)
    self._Control:ShowTipWithKey("Theatre6PvpEnvReplaceSuccess")
    self:Close()
end

return XUiTheatre6PopupChooseEnvironment
