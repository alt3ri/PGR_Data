--- 商品通用图标
---@class XUiPBRShopNewGridIcon: XUiNode
---@field protected _Control
---@field Parent
local XUiPBRShopNewGridIcon = XClass(XUiNode, "XUiPBRShopNewGridIcon")

function XUiPBRShopNewGridIcon:OnStart(rootUi)
    self.RootUi = rootUi
end

function XUiPBRShopNewGridIcon:RefreshIcon(itemId)
    -- 显示道具图标
    local itemCfg = self._Control:GetPBRItemCfgById(itemId)

    if itemCfg then
        if not string.IsNilOrEmpty(itemCfg.Icon) then
            self.RImgIcon:SetRawImage(itemCfg.Icon)
        end
    else
        self.RImgIcon:SetRawImage("")
    end
end

function XUiPBRShopNewGridIcon:RefreshPropQualityColor(quality)
    -- 品质底图
    if self.ImgQuality then
        XUiHelper.SetQualityIcon(self.RootUi, self.ImgQuality, quality)
        self.ImgQuality.gameObject:SetActiveEx(true)
    end

    -- 品质底图（大）
    if self.ImgIconQuality then
        XUiHelper.SetQualityIcon(self.RootUi, self.ImgIconQuality, quality)
        self.ImgIconQuality.gameObject:SetActiveEx(true)
    end
end

return XUiPBRShopNewGridIcon