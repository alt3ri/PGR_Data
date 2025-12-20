---@class XUiGridDlcRelinkRole : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkRole = XClass(XUiNode, "XUiGridDlcRelinkRole")

function XUiGridDlcRelinkRole:OnStart()
    XUiHelper.RegisterClickEvent(self, self.BtnDetail, self.OnBtnDetailClick, true, true)
end

---@param playerInfo XDlcRelinkRankPlayerInfo 玩家信息
function XUiGridDlcRelinkRole:Refresh(playerInfo)
    self.PlayerInfo = playerInfo
    if not self.PlayerInfo then
        return
    end

    self.TxtPlayerName.text = self.PlayerInfo.Name
    XUiPlayerHead.InitPortrait(self.PlayerInfo.HeadPortraitId, self.PlayerInfo.HeadFrameId, self.Head)
    local fashionId = XMVCA.XCharacter:GetCharacterTemplate(self.PlayerInfo.CharacterId).DefaultNpcFashtionId
    self.StandIcon:SetRawImage(XDataCenter.FashionManager.GetFashionBigHeadIcon(fashionId))
end

function XUiGridDlcRelinkRole:OnBtnDetailClick()
    if not self.PlayerInfo then
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerInfo.PlayerId)
end

return XUiGridDlcRelinkRole
