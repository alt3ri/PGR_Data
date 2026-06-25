---@class XUiGridTheatre6PvpMember : XUiNode
---@field private _Control XTheatre6Control
local XUiGridTheatre6PvpMember = XClass(XUiNode, "XUiGridTheatre6PvpMember")

function XUiGridTheatre6PvpMember:OnStart()
    if self.BtnHead then
        self.BtnHead:AddEventListener(handler(self, self.OnBtnHeadClick))
    end
    if self.RImgNameplate then
        self.RImgNameplate.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre6PvpMember:Refresh(name, headPortraitId, headFrameId, playerId)
    self.PlayerId = playerId
    if self.TxtName then
        self.TxtName.text = name
    end
    if self.Head then
        XUiPlayerHead.InitPortrait(headPortraitId, headFrameId, self.Head)
    end
end

function XUiGridTheatre6PvpMember:SetNameplate()
    -- TODO
end

function XUiGridTheatre6PvpMember:OnBtnHeadClick()
    if not XTool.IsNumberValid(self.PlayerId) then
        return
    end
    XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.PlayerId)
end

return XUiGridTheatre6PvpMember
