--- 战斗奖励-Buff卡片
---@class XUiPanelTheatre6RewardBuff : XUiNode
---@field private _Control XTheatre6Control
---@field Parent XUiTheatre6FightReward
local XUiPanelTheatre6RewardBuff = XClass(XUiNode, "XUiPanelTheatre6RewardBuff")

function XUiPanelTheatre6RewardBuff:OnStart()
    self.TxtDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
end

---@param data table {BuffId}
function XUiPanelTheatre6RewardBuff:Update(data)
    local buffId = data.BuffId
    local config = self._Control:GetBuffConfig(buffId)

    self.UiRImgIcon:SetRawImage(config.Icon)
    self.UiTxtName.text = config.Name
    self.TxtDesc.text = self._Control:GetBuffDesc(buffId)

    -- 品质底图
    local quality = config.Quality or 1
    local qualityIcon = self._Control:GetQualityIcon(quality)
    if qualityIcon and self.ImgQuality then
        self.ImgQuality:SetSprite(qualityIcon)
    end
end

return XUiPanelTheatre6RewardBuff
