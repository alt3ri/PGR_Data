---@class XUiPanelTheatre6PvpPlayerInfo : XUiNode
---@field _Control XTheatre6Control
---@field Parent XUiTheatre6PVPMain
local XUiPanelTheatre6PvpPlayerInfo = XClass(XUiNode, "XUiPanelTheatre6PvpPlayerInfo")

local XUiGridTheatre6PvpMember = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpMember")
local XUiGridTheatre6PvpRank = require("XUi/XUiTheatre6/PVP/Grid/XUiGridTheatre6PvpRank")

function XUiPanelTheatre6PvpPlayerInfo:OnStart()
    self.BtnDetail:AddEventListener(handler(self, self.OnBtnDetailClick))
    self.BtnRank:AddEventListener(handler(self, self.OnBtnRankClick))
    self.BtnRecord:AddEventListener(handler(self, self.OnBtnRecordClick))
    self.BtnDefend:AddEventListener(handler(self, self.OnBtnDefendClick))
    self.TxtTips.gameObject:SetActiveEx(false)

    ---@type XUiGridTheatre6PvpMember
    self._MemberGrid = nil
    ---@type XUiGridTheatre6PvpRank
    self._RankGrid = nil
end

function XUiPanelTheatre6PvpPlayerInfo:Refresh()
    self:RefreshMember()
    self:RefreshRank()
    self:RefreshTips()
end

function XUiPanelTheatre6PvpPlayerInfo:RefreshMember()
    if not self._MemberGrid then
        self._MemberGrid = XUiGridTheatre6PvpMember.New(self.GridMember, self)
    end
    self._MemberGrid:Open()
    self._MemberGrid:Refresh(XPlayer.Name, XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, XPlayer.Id)
    self._MemberGrid:SetNameplate()
end

function XUiPanelTheatre6PvpPlayerInfo:RefreshRank()
    if not self._RankGrid then
        self._RankGrid = XUiGridTheatre6PvpRank.New(self.GridRank, self)
    end
    self._RankGrid:Open()
    local rankId = self._Control:GetPvpCurRankId()
    self._RankGrid:SetData(rankId)
    -- 段位分数
    local rankConfig = self._Control:GetPvpRankConfig(rankId)
    local score = self._Control:GetPvpCurScore()
    local maxScore = rankConfig and rankConfig.MaxScore or 0
    local index = score >= maxScore and 2 or 1
    local rankScoreContent = self._Control:GetPvpClientConfigValue("RankScoreContent", index)
    self.TxtRankScore.text = string.format(rankScoreContent, score, maxScore)
end

-- 刷新段位时间提示 当前分数已满且下一段位未开启时，才显示提示
function XUiPanelTheatre6PvpPlayerInfo:RefreshTips()
    local showTips = false
    local curRankConfig = self._Control:GetCurrentRankConfig()
    local score = self._Control:GetPvpCurScore()
    local maxScore = curRankConfig and curRankConfig.MaxScore or 0
    local isScoreFull = XTool.IsNumberValid(maxScore) and score >= maxScore
    local rankConfig = self._Control:GetNextRankConfig()
    if isScoreFull and rankConfig then
        local timeId = rankConfig.TimeId
        if XTool.IsNumberValid(timeId) then
            local nowTime = XTime.GetServerNowTimestamp()
            local startTime = XFunctionManager.GetStartTimeByTimeId(timeId)
            if nowTime < startTime then
                local rankTimeTips = self._Control:GetPvpClientConfigValue("RankTimeTips")
                local rankTime = XUiHelper.GetTime(startTime - nowTime, XUiHelper.TimeFormatType.MOE_WAR)
                self.TxtTips.text = string.format(rankTimeTips, rankTime, rankConfig.Name)
                showTips = true
            end
        end
    end
    self.TxtTips.gameObject:SetActiveEx(showTips)
end

function XUiPanelTheatre6PvpPlayerInfo:OnBtnDetailClick()
    self._Control:OpenPvpRankDetail()
end

function XUiPanelTheatre6PvpPlayerInfo:OnBtnRankClick()
    self._Control:OpenPvpRank()
end

function XUiPanelTheatre6PvpPlayerInfo:OnBtnRecordClick()
    XLuaUiManager.Open("UiTheatre6PopupPVPRecord")
end

function XUiPanelTheatre6PvpPlayerInfo:OnBtnDefendClick()
    XLuaUiManager.Open("UiTheatre6PVPAttackDefend", XEnumConst.Theatre6.Pvp.LineupMode.Defend)
end

return XUiPanelTheatre6PvpPlayerInfo
