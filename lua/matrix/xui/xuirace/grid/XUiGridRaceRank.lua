---@class XUiGridRaceRank : XUiNode
---@field Parent XUiRaceRank
---@field _Control XRaceControl
local XUiGridRaceRank = XClass(XUiNode, "XUiGridRaceRank")

function XUiGridRaceRank:Init()
    ---@type UnityEngine.UI.Image[]
    self._RankImgs = { self.ImgRank1, self.ImgRank2, self.ImgRank3 }
    XUiHelper.RegisterClickEvent(self, self.BtnHead, self.OnBtnDetailClicked)
end

function XUiGridRaceRank:Refresh(rankInfo)
    self.PlayerId = rankInfo.Id
    self:ShowRank(rankInfo.Rank)
    self.TxtName.text = rankInfo.Name
    self.TxtGuildName.text = string.IsNilOrEmpty(rankInfo.GuildName) and XUiHelper.GetText("RaceNotGuild") or rankInfo.GuildName
    self.TxtPoint.text = rankInfo.Score
    XUiPlayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
end

function XUiGridRaceRank:RefreshMine(rankInfo, totalCount)
    if rankInfo then
        self.TxtPoint.text = rankInfo.Score
        -- 101名及以上显示百分比
        if rankInfo.Rank > 100 then
            self.TxtRank.text = math.max(1, math.floor(rankInfo.Rank * 100 / totalCount)) .. "%" -- 最小显示1%
        elseif rankInfo.Rank > 0 and rankInfo.Rank <= 100 then
            self.TxtRank.text = rankInfo.Rank
        else
            self.TxtRank.text = XUiHelper.GetText("RaceNotListed")
        end
    else
        self.TxtPoint.text = "0"
        self.TxtRank.text = XUiHelper.GetText("RaceNotListed")
    end
    self.PlayerId = XPlayer.Id
    self.TxtName.text = XPlayer.Name
    XUiPlayerHead.InitPortrait(XPlayer.CurrHeadPortraitId, XPlayer.CurrHeadFrameId, self.Head)
    if XDataCenter.GuildManager.IsJoinGuild() then
        self.TxtGuildName.text = XDataCenter.GuildManager.GetGuildName()
    else
        self.TxtGuildName.text = XUiHelper.GetText("RaceNotGuild")
    end
end

function XUiGridRaceRank:OnBtnDetailClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerId)
end

function XUiGridRaceRank:ShowRank(rank)
    local spList = self._Control:GetRankSprites(rank)
    for i = 1, 3 do
        local sp = spList[i]
        if sp then
            self._RankImgs[i].gameObject:SetActiveEx(true)
            self._RankImgs[i]:SetSprite(sp)
        else
            self._RankImgs[i].gameObject:SetActiveEx(false)
        end
    end
end

return XUiGridRaceRank
