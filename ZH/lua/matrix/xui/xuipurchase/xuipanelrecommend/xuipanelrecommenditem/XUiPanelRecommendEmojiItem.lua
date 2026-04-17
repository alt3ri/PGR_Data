local XUiPanelRecommendItem = require("XUi/XUiPurchase/XUiPanelRecommend/XUiPanelRecommendItem/XUiPanelRecommendItem")

---@class XUiPanelRecommendEmojiItem : XUiPanelRecommendItem 动态表情包专属Item
local XUiPanelRecommendEmojiItem = XClass(XUiPanelRecommendItem, "XUiPanelRecommendEmojiItem")

function XUiPanelRecommendEmojiItem:Update(package)
    self.Super.Update(self, package)

    --武器包，不显示预览按钮
    local firstDynamicEmojiId = package:GetFirstDynamicEmojiId()
    local hasDynamicEmoji = firstDynamicEmojiId and firstDynamicEmojiId > 0 or false

    self.ButtonTip.gameObject:SetActiveEx(hasDynamicEmoji)

    --预览动态表情
    if hasDynamicEmoji and self.ButtonTip then
        XUiHelper.RegisterClickEvent(self, self.ButtonTip, function()
            XLuaUiManager.Open("UiDynamicFacePreview", package)
        end)
    end

    --礼包icon
    if package.Data and hasDynamicEmoji then
        local iconPath = XPurchaseConfigs.GetIconPathByIconName(package.Data.Icon)
        if iconPath and iconPath.AssetPath then
            self.ImgIconLb:SetRawImage(iconPath.AssetPath, function() self.ImgIconLb:SetNativeSize() end)
        end
    end
end

return XUiPanelRecommendEmojiItem
