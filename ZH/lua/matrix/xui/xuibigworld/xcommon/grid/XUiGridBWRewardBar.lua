local XUiGridBWGoodsBase = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWGoodsBase")

---@class XUiGridBWRewardBar : XUiGridBWGoodsBase
---@field RImgIcon UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field TxtQuantity UnityEngine.UI.Text
---@field RewardLevel1 UiObject
---@field RewardLevel2 UiObject
---@field RewardLevel3 UiObject
---@field RewardLevel4 UiObject
---@field RewardLevel5 UiObject
---@field Parent XUiBigWorldRewardSidebar
local XUiGridBWRewardBar = XClass(XUiGridBWGoodsBase, "XUiGridBWRewardBar")

function XUiGridBWRewardBar:RefreshCount(count)
    if not count then
        self:_RefreshActive(self.TxtCount, false)
        return
    end

    self:_RefreshText(self.TxtCount, "x" .. tostring(count))
end

function XUiGridBWRewardBar:RefreshQuality(qualityIcon)
    local quality = self._GoodsParams.Quality

    for i = 1, 7 do
        local rewardLevel = self["RewardLevel".. i]

        if rewardLevel then
            rewardLevel.gameObject:SetActiveEx(i == quality)
        end
    end
end

return XUiGridBWRewardBar
