---@class XUiPanelTheatre6PvpLoadingDetail : XUiNode pvploading对局双方详情
---@field Parent XUiTheatre6PVPLoading
---@field _Control XTheatre6Control
local XUiPanelTheatre6PvpLoadingDetail = XClass(XUiNode, "XUiPanelTheatre6PvpLoadingDetail")

function XUiPanelTheatre6PvpLoadingDetail:OnStart()
    ---@type XUiGridTheatre6PvpRank
    self._Rank = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRank").New(self.GridRank, self)
    self.TxtEnvDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
end

---己方详情
function XUiPanelTheatre6PvpLoadingDetail:SetSelfData(lineupMode)
    self.TxtName.text = XPlayer.Name
    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    self._Rank:SetData(self._Control:GetPvpCurRankId())
    self.TxtRankScore.text = self._Control:GetPvpCurScore()

    local fileDataList = self._Control:GetPvpCurrentLineupFileDataList(lineupMode)
    for i = 1, 3 do
        local go = i == 1 and self.GridPVPRole or XUiHelper.Instantiate(self.GridPVPRole, self.GridPVPRole.parent)
        ---@type XUiGridTheatre6PvpRole
        local grid = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRole").New(go, self)
        grid:Refresh(fileDataList[i])
    end

    local buffId = self._Control:GetPvpCurrentLineupBuffId(lineupMode)
    if XTool.IsNumberValid(buffId) then
        local envConfig = self._Control:GetPvpBuffConfig(buffId)
        self.TxtEnvName.text = envConfig.Name
        self.TxtEnvDesc.text = self._Control:GetPvpBuffDesc(buffId)
        self.GridEnvironment:SetRawImage(envConfig.Icon)
        self.PanelEnvironment.gameObject:SetActiveEx(true)
    else
        self.PanelEnvironment.gameObject:SetActiveEx(false)
    end
end

---敌方详情
---@param data XTheatre6PvpPlayerBattleDb
function XUiPanelTheatre6PvpLoadingDetail:SetEnemyData(data)
    self.TxtName.text = data.Name
    XUiPlayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.Head)
    self._Rank:SetData(data.RankId)
    self.TxtRankScore.text = data.Score

    local fileDatas = self._Control:GetEnemySaveFiles(data)
    for i = 1, 3 do
        local go = i == 1 and self.GridPVPRole or XUiHelper.Instantiate(self.GridPVPRole, self.GridPVPRole.parent)
        ---@type XUiGridTheatre6PvpRole
        local grid = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRole").New(go, self)
        grid:Refresh(fileDatas[i])
    end

    local buffId = data.DefenseBuffId
    if XTool.IsNumberValid(buffId) then
        local envConfig = self._Control:GetPvpBuffConfig(buffId)
        self.TxtEnvName.text = envConfig.Name
        self.TxtEnvDesc.text = self._Control:GetPvpBuffDesc(buffId)
        self.GridEnvironment:SetRawImage(envConfig.Icon)
        self.PanelEnvironment.gameObject:SetActiveEx(true)
    else
        self.PanelEnvironment.gameObject:SetActiveEx(false)
    end
end

return XUiPanelTheatre6PvpLoadingDetail
