--- 通用的技能格子展示，使用该类至少大体上结构是一致的
---@class XUiPBRCommonPropGrid : XUiNode
---@field _Control XPBRGameControl
local XUiPBRCommonPropGrid = XClass(XUiNode, "XUiPBRCommonPropGrid")

function XUiPBRCommonPropGrid:OnStart()
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClickEvent))
end

---@param itemData PbrItem
function XUiPBRCommonPropGrid:RefreshShow(itemData)
    self.ItemId = itemData.ItemId

    local itemCfg = self._Control:GetPBRItemCfgById(self.ItemId)

    self.RImgIcon:SetRawImage(itemCfg.Icon)

    if itemCfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Other then
        self.ImgQuality.gameObject:SetActiveEx(true)

        local qualityIcon = XArrangeConfigs.GeQualityPath(itemCfg.ItemTier)

        if not string.IsNilOrEmpty(qualityIcon) then
            self.ImgQuality:SetImage(qualityIcon)
        end
    else
        self.ImgQuality.gameObject:SetActiveEx(false)
    end

    if self.PropNumText then
        if XTool.IsNumberValidEx(itemData.GainNum) then
            self.PropNumText.gameObject:SetActiveEx(true)
            self.PropNumText.text = XUiHelper.FormatTextEx(self._Control:GetClientPBRText('ItemCountFormat'), itemData.GainNum)
        else
            self.PropNumText.gameObject:SetActiveEx(false)
        end
    end
end

function XUiPBRCommonPropGrid:OnBtnClickEvent()
    if XTool.IsNumberValidEx(self.ItemId) then
        self._Control:DispatchEvent(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_OPEN_ITEM_DETAIL, self.DetailPos, self.ItemId)
    end
end

return XUiPBRCommonPropGrid
