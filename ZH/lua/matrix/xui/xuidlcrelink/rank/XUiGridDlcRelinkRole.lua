---@class XUiGridDlcRelinkRole : XUiNode
---@field private _Control XDlcRelinkControl
local XUiGridDlcRelinkRole = XClass(XUiNode, "XUiGridDlcRelinkRole")

function XUiGridDlcRelinkRole:OnStart()
    if self.BtnDetail then
        self.BtnDetail:AddEventListener(handler(self, self.OnBtnDetailClick))
    end
end

---@param playerInfo XDlcRelinkRankPlayerInfo 玩家信息
function XUiGridDlcRelinkRole:Refresh(playerInfo)
    self.PlayerInfo = playerInfo
    if not self.PlayerInfo then
        return
    end

    self.TxtPlayerName.text = self.PlayerInfo.Name
    XUiPlayerHead.InitPortrait(self.PlayerInfo.HeadPortraitId, self.PlayerInfo.HeadFrameId, self.Head)
    if XTool.IsNumberValid(self.PlayerInfo.CharacterId) then
        self.StandIcon.gameObject:SetActiveEx(true)
        local fashionId = XMVCA.XCharacter:GetCharacterTemplate(self.PlayerInfo.CharacterId).DefaultNpcFashtionId
        self.StandIcon:SetRawImage(XDataCenter.FashionManager.GetFashionBigHeadIcon(fashionId))
    else
        self.StandIcon.gameObject:SetActiveEx(false)
    end
end

function XUiGridDlcRelinkRole:OnBtnDetailClick()
    if not self.PlayerInfo then
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerInfo.PlayerId)
end

return XUiGridDlcRelinkRole
