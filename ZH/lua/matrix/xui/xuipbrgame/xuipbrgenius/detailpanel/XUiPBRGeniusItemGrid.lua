---@class XUiPBRGeniusItemGrid: XUiNode
---@field protected _Control XPBRGameControl
---@field Parent
local XUiPBRGeniusItemGrid = XClass(XUiNode, "XUiPBRGeniusItemGrid")

function XUiPBRGeniusItemGrid:OnStart()
    self.BtnClick:AddEventListener(handler(self, self.OnBtnClickEvent))
end

function XUiPBRGeniusItemGrid:RefreshShow(itemId)
    self.ItemId = itemId

    local itemCfg = self._Control:GetPBRItemCfgById(itemId)
    
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
    
end

function XUiPBRGeniusItemGrid:OnBtnClickEvent()
    if XTool.IsNumberValidEx(self.ItemId) then
        self._Control:DispatchEvent(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_OPEN_ITEM_DETAIL, self.DetailPos, self.ItemId)
    end
end

return XUiPBRGeniusItemGrid