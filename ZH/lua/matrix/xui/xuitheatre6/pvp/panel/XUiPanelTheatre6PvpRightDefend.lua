local XUiPanelTheatre6PvpRightBase = require("XUi/XUiTheatre6/PVP/Panel/XUiPanelTheatre6PvpRightBase")

---@class XUiPanelTheatre6PvpRightDefend : XUiPanelTheatre6PvpRightBase
---@field private _Control XTheatre6Control
local XUiPanelTheatre6PvpRightDefend = XClass(XUiPanelTheatre6PvpRightBase, "XUiPanelTheatre6PvpRightDefend")

function XUiPanelTheatre6PvpRightDefend:OnStart()
    XUiPanelTheatre6PvpRightDefend.Super.OnStart(self)

    self.BtnDetail:AddEventListener(handler(self, self.OnBtnDetailClick))
    self.BtnEnvironment:AddEventListener(handler(self, self.OnBtnEnvironmentClick))
end

function XUiPanelTheatre6PvpRightDefend:GetLineupMode()
    return XEnumConst.Theatre6.Pvp.LineupMode.Defend
end

function XUiPanelTheatre6PvpRightDefend:Refresh()
    self:RefreshTips()
    self:RefreshBtn()
    self:RefreshRoleMe()
    self:SelectDefaultSlot()
end

function XUiPanelTheatre6PvpRightDefend:RefreshTips()
    local mistNum = self._Control:GetPvpRankMistNum()
    local isShow = mistNum > 0
    self.TxtTips.gameObject:SetActiveEx(isShow)
    if not isShow then
        return
    end
    local count = math.min(mistNum, 3)
    local indexList = {}
    for index = 3 - count + 1, 3 do
        table.insert(indexList, index)
    end
    local tips = self._Control:GetPvpClientConfigValue("DefendMistTips")
    self.TxtTips.text = string.format(tips, table.concat(indexList, ","))
end

function XUiPanelTheatre6PvpRightDefend:RefreshBtn()
    self.BtnEnvironment.gameObject:SetActiveEx(self._Control:IsPvpBuffGroupIdValid())
    local buffId = self._Control:GetPvpCurrentLineupBuffId(self:GetLineupMode())
    if not XTool.IsNumberValid(buffId) then
        return
    end
    local buffConfig = self._Control:GetPvpBuffConfig(buffId)
    if buffConfig then
        self.BtnEnvironment:SetRawImageEx(buffConfig.Icon)
        self.BtnEnvironment:SetNameByGroup(0, buffConfig.Name)
        self.BtnEnvironment:ShowReddot(self._Control:IsChooseEnvRedPoint())
    end
end

function XUiPanelTheatre6PvpRightDefend:OnBtnDetailClick()
    local playerData = {}
    playerData.Name = XPlayer.Name
    playerData.HeadPortraitId = XPlayer.CurrHeadPortraitId
    playerData.HeadFrameId = XPlayer.CurrHeadFrameId
    playerData.PlayerId = XPlayer.Id
    playerData.RankId = self._Control:GetPvpCurRankId()
    playerData.Score = self._Control:GetPvpCurScore()
    playerData.FileDataList = self._MyFileDataList
    playerData.BuffId = self._Control:GetPvpCurrentLineupBuffId(self:GetLineupMode())
    XLuaUiManager.Open("UiTheatre6PopupPVPInfo", playerData)
end

function XUiPanelTheatre6PvpRightDefend:OnBtnEnvironmentClick()
    self._Control:CloseChooseEnvRedPoint()
    XLuaUiManager.OpenWithCloseCallback("UiTheatre6PopupChooseEnvironment", function()
        self:RefreshBtn()
    end, self.Parent:GetLineupMode())
end

return XUiPanelTheatre6PvpRightDefend
