---@class XUiGridBossInshotRank : XUiNode
---@field private _Control XBossInshotControl
local XUiGridBossInshotRank = XClass(XUiNode, "XUiGridBossInshotRank")

function XUiGridBossInshotRank:OnStart()
    self:SetButtonCallBack()
end

function XUiGridBossInshotRank:SetButtonCallBack()
    XUiHelper.RegisterClickEvent(self, self.Transform, self.OnBtnDetailClicked)
end

function XUiGridBossInshotRank:OnBtnDetailClicked()
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.RankInfo.Id)
end

local TowerScoreBits = 20
local TowerBits = 8
local TowerScoreMask = (1 << TowerScoreBits) - 1
local TowerMask = (1 << TowerBits) - 1

local function GetTower(encoded)
    return (encoded >> TowerScoreBits) & TowerMask
end

local function GetScore(encoded)
    return encoded & TowerScoreMask
end

function XUiGridBossInshotRank:Refresh(rankInfo)
    self.RankInfo = rankInfo
    -- 排行
    local icon = self._Control:GetRankingSpecialIcon(rankInfo.Rank)
    if icon then 
        self.ImgRankSpecial:SetSprite(icon)
    end
    self.TxtRankNormal.gameObject:SetActive(icon == nil)
    self.ImgRankSpecial.gameObject:SetActive(icon ~= nil)
    self.TxtRankNormal.text = rankInfo.Rank
    -- 指挥官
    self.TxtPlayerName.text = rankInfo.Name
    XUiPlayerHead.InitPortrait(rankInfo.HeadPortraitId, rankInfo.HeadFrameId, self.Head)
    -- 分数
    if rankInfo.TowerId then
        self.TxtRankScore.text = tostring(rankInfo.Score)
        self.TxtRankFloor.text = CS.XTextManager.GetText("BossInshotTowerFloor", rankInfo.TowerId)
    else
        self.TxtRankScore.text = tostring(GetScore(rankInfo.Score))
        self.TxtRankFloor.text = CS.XTextManager.GetText("BossInshotTowerFloor", GetTower(rankInfo.Score))
    end
    -- 角色
    local roleId = rankInfo.CharacterId or rankInfo.CharacterIds[1]
    local roleIcon = XMVCA.XCharacter:GetCharSmallHeadIcon(roleId, rankInfo.Id ~= XPlayer.Id)
    self.RImgRole:SetRawImage(roleIcon)
end

function XUiGridBossInshotRank:PlayFlyInAnimation()
    self:PlayAnimation("PlayerRankEnable")
end

return XUiGridBossInshotRank