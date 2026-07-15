---@class XUiGridTheatre6PvpRecord : XUiNode
---@field Parent XUiTheatre6PopupPVPRecord
---@field _Control XTheatre6Control
local XUiGridTheatre6PvpRecord = XClass(XUiNode, "XUiGridTheatre6PvpRecord")

local BattleRecordStatus = XEnumConst.Theatre6.Pvp.BattleRecordStatus

function XUiGridTheatre6PvpRecord:OnStart()
    self.BtnGrid:AddEventListener(handler(self, self.OnBtnGridClick))
    self.BtnHead:AddEventListener(handler(self, self.OnBtnHeadClick))
    ---@type XUiGridTheatre6PvpRank
    self._Rank = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRank").New(self.UiTheatre6GridRank, self)
    ---@type XUiGridTheatre6PvpEnvironment
    self._Env = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpEnvironment").New(self.UiTheatre6GridEnvironment, self)
    ---@type XUiGridTheatre6PvpRole[]
    self._SaveFileGrids = {}

    self:InitRecordStatusHandler()
end

function XUiGridTheatre6PvpRecord:InitRecordStatusHandler()
    self._RecordStatusHandler = {
        --进攻
        [true] = {
            [true] = handler(self, self.OnAtkSuc),
            [false] = handler(self, self.OnAtkFail),
        },
        --防守
        [false] = {
            [true] = handler(self, self.OnDefSuc),
            [false] = handler(self, self.OnDefFail),
        },
    }
end

---@param data XTheatre6PvpBattleRecord
function XUiGridTheatre6PvpRecord:SetData(data)
    self.TxtName.text = data.EnemyInfo.Name
    self._EnemyPlayerId = data.EnemyInfo.PlayerId
    self._Rank:SetData(data.EnemyInfo.RankId)
    self._Rank:SetRankScore(data.EnemyInfo.Score)
    XUiPlayerHead.InitPortrait(data.EnemyInfo.HeadPortraitId, data.EnemyInfo.HeadFrameId, self.Head)

    local saveFiles = self._Control:GetEnemySaveFiles(data.EnemyInfo)
    for i = 1, #saveFiles do
        local grid = self._SaveFileGrids[i]
        if not grid then
            local go = i == 1 and self.UiTheatre6GridPVPRole or XUiHelper.Instantiate(self.UiTheatre6GridPVPRole, self.UiTheatre6GridPVPRole.parent)
            grid = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRole").New(go, self)
            self._SaveFileGrids[i] = grid
        end
        grid:Open()
        grid:Refresh(saveFiles[i])
    end
    for i = #saveFiles + 1, #self._SaveFileGrids do
        self._SaveFileGrids[i]:Close()
    end

    if XTool.IsNumberValid(data.EnemyInfo.DefenseBuffId) then
        self._Env:Open()
        self._Env:SetData(data.EnemyInfo.DefenseBuffId)
        self._Env.Transform:SetAsLastSibling()
    else
        self._Env:Close()
    end

    if data.RecordStatus == BattleRecordStatus.Abnormal then
        self:ShowFailText("BattleRecordAbnormal")
    else
        local handler = self._RecordStatusHandler[data.IsAttacker][data.IsWin]
        handler(data)
    end

    self:UpdatePlayerData(data, saveFiles)
end

function XUiGridTheatre6PvpRecord:UpdatePlayerData(data, saveFiles)
    if not self._PlayerData then
        self._PlayerData = {}
    end
    self._PlayerData.Name = data.EnemyInfo.Name
    self._PlayerData.HeadPortraitId = data.EnemyInfo.HeadPortraitId
    self._PlayerData.HeadFrameId = data.EnemyInfo.HeadFrameId
    self._PlayerData.PlayerId = data.EnemyInfo.PlayerId
    self._PlayerData.RankId = data.EnemyInfo.RankId
    self._PlayerData.Score = data.EnemyInfo.Score
    self._PlayerData.FileDataList = saveFiles
    self._PlayerData.BuffId = data.EnemyInfo.DefenseBuffId
end

--region 状态管理

function XUiGridTheatre6PvpRecord:OnAtkSuc(data)
    if data.IsAllWin then
        self:ShowWinText("BattleRecordTotalAtkSuc", data.ScoreChange)
    else
        self:ShowWinText("BattleRecordAtkSuc", data.ScoreChange)
    end
end

function XUiGridTheatre6PvpRecord:OnAtkFail(data)
    self:ShowFailText("BattleRecordAtkFail", math.abs(data.ScoreChange))
end

function XUiGridTheatre6PvpRecord:OnDefSuc(data)
    self:ShowWinText("BattleRecordDefSuc", data.ScoreChange)
end

function XUiGridTheatre6PvpRecord:OnDefFail(data)
    self:ShowFailText("BattleRecordDefFailLoseScore", math.abs(data.ScoreChange))
end

function XUiGridTheatre6PvpRecord:ShowWinText(key, param)
    self.ImgBgWin.gameObject:SetActiveEx(true)
    self.ImgBgLose.gameObject:SetActiveEx(false)
    self.TxtWin.text = string.format(self._Control:GetPvpClientConfigValue(key), param)
end

function XUiGridTheatre6PvpRecord:ShowFailText(key, param)
    self.ImgBgWin.gameObject:SetActiveEx(false)
    self.ImgBgLose.gameObject:SetActiveEx(true)
    self.TxtLose.text = string.format(self._Control:GetPvpClientConfigValue(key), param)
end

--endregion

function XUiGridTheatre6PvpRecord:OnBtnHeadClick()
    if not XTool.IsNumberValid(self._EnemyPlayerId) then
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self._EnemyPlayerId)
end

function XUiGridTheatre6PvpRecord:OnBtnGridClick()
    XLuaUiManager.Open("UiTheatre6PopupPVPInfo", self._PlayerData)
end

return XUiGridTheatre6PvpRecord
