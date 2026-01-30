---@class XUiGridRelinkLoadingPlater : XUiNode
---@field private _Control XDlcRelinkControl
---@field Parent XUiRelinkLoading
local XUiGridRelinkLoadingPlater = XClass(XUiNode, "XUiGridRelinkLoadingPlater")

function XUiGridRelinkLoadingPlater:OnStart()
    self.TxtNum.gameObject:SetActiveEx(true)
    self.ImgBar.gameObject:SetActiveEx(true)
    self.IsFinish = false
end

---@param playerData XDlcPlayerData
function XUiGridRelinkLoadingPlater:Refresh(playerData)
    self.PlayerData = playerData
    local characterId = playerData:GetCharacterId()

    self.TxtName.text = playerData:GetNickname()
    self.TxtNum.text = "0%"
    self.ImgBar.fillAmount = 0
    self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))

    self:RefreshImgBg()
end

function XUiGridRelinkLoadingPlater:RefreshProgress(progress)
    if progress < 100 then
        self.TxtNum.text = progress .. "%"
        self.ImgBar.fillAmount = progress / 100.0
    else
        if not self.IsFinish then
            self.TxtNum.text = "100%"
            self.ImgBar.fillAmount = 1.0
            self.Parent:RefreshFinishCount()
            self.IsFinish = true
        end
    end
    self:RefreshImgBg()
end

function XUiGridRelinkLoadingPlater:RefreshImgBg()
    self.ImgBgOff.gameObject:SetActiveEx(not self.IsFinish)
    self.ImgBgOn.gameObject:SetActiveEx(self.IsFinish)
end

return XUiGridRelinkLoadingPlater
