--- 战斗奖励-遗物卡片
---@class XUiPanelTheatre6RewardRelic : XUiNode
---@field private _Control XTheatre6Control
---@field Parent XUiTheatre6FightReward
local XUiPanelTheatre6RewardRelic = XClass(XUiNode, "XUiPanelTheatre6RewardRelic")

function XUiPanelTheatre6RewardRelic:OnStart()
    self._TagGrids = {}
    self._ClickTagCb = nil
    self.UiTxtDescEffect.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
    self.UiTxtDescAttribute.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
    self.UiTxtDesc.requestImage = XMVCA.XTheatre6.RichTextImageCallBack
end

---@param data table {AttrPackId}
function XUiPanelTheatre6RewardRelic:Update(data)
    self._RelicId = data.AttrPackId
    self._Config = self._Control:GetAttrPackCfgById(self._RelicId)

    self:RefreshIcon()
    self:RefreshName()
    self:RefreshQuality()
    self:RefreshDesc()
    self:RefreshTags()
end

function XUiPanelTheatre6RewardRelic:RefreshIcon()
    self.UiRImgIcon:SetRawImage(self._Config.Icon)
end

function XUiPanelTheatre6RewardRelic:RefreshName()
    self.UiTxtName.text = self._Config.Name
end

function XUiPanelTheatre6RewardRelic:RefreshQuality()
    local quality = self._Config.Quality or 1
    local qualityIcon = self._Control:GetQualityIcon(quality)
    if qualityIcon and self.ImgQuality then
        self.ImgQuality:SetRawImage(qualityIcon)
    end
end

function XUiPanelTheatre6RewardRelic:RefreshDesc()
    -- 属性加成
    local attrConfigs, attrValues = self._Control:GetShowAttribute(self._Config.AttrTypes, self._Config.AttrNums)
    local attrText = ""
    for i, attrCfg in ipairs(attrConfigs) do
        local value = attrValues[i]
        attrText = attrText .. string.format("%s +%s\n", attrCfg.Name, value)
    end
    self.UiTxtDescAttribute.text = attrText

    -- 额外效果
    local effectText = ""
    if self._Config.BuffIds and #self._Config.BuffIds > 0 then
        for _, buffId in ipairs(self._Config.BuffIds) do
            local buffCfg = self._Control:GetBuffConfig(buffId)
            effectText = effectText .. self._Control:GetBuffDesc(buffId) .. "\n"
        end
    end
    self.UiTxtDescEffect.text = effectText
    self.UiTxtDescEffect.gameObject:SetActiveEx(effectText ~= "")

    -- 包装文案
    self.UiTxtDesc.text = self._Control:GetAttrPackDesc(self._RelicId, false)
end

function XUiPanelTheatre6RewardRelic:RefreshTags()
    local showTags = self._Control:GetShowBuildTagWithSort(self._Config.BuildTags)
    local keyWordIds = self._Config.KeyWordIds

    if #showTags == 0 then
        self.PanelType.gameObject:SetActiveEx(false)
        return
    end

    self.PanelType.gameObject:SetActiveEx(true)
    self.GridTag.gameObject:SetActiveEx(false)

    self._TagGrids = XUiHelper.RefreshUiObjectList(self._TagGrids, self.GridTag.parent, self.GridTag, #showTags, function(i, grid)
        local tag = showTags[i]
        grid.ImgIcon:SetSprite(tag.Icon)
        grid.TxtName.text = tag.Name

        grid:AddEventListener(function()
            self._Control:OpenTagTip(self._Config.BuildTags, self.Transform, keyWordIds)
        end)
    end)
end

return XUiPanelTheatre6RewardRelic
