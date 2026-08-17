--- 详情模式的商品格子（技能替换弹窗复用商品结构）
--- 复用 GridItem 的按色选样式调度，仅替换为详情样式类并隐藏升阶箭头
---@class XUiPBRShopNewDetailGridItem: XUiPBRShopNewGridItem
local XUiPBRShopNewGridItem = require('XUi/XUiPBRGame/XUiPBRShopNew/GoodsPanel/XUiPBRShopNewGridItem')
local XUiPBRShopNewDetailGridStyle = require('XUi/XUiPBRGame/XUiPBRShopNew/GoodsPanel/XUiPBRShopNewDetailGridStyle')
local XUiPBRShopNewDetailGridItem = XClass(XUiPBRShopNewGridItem, "XUiPBRShopNewDetailGridItem")

function XUiPBRShopNewDetailGridItem:GetGridStyleCls()
    return XUiPBRShopNewDetailGridStyle
end

--- 详情模式不展示可升阶箭头
function XUiPBRShopNewDetailGridItem:_RefreshImgUp(itemId, itemCfg)
    if self.ImgUp then
        self.ImgUp.gameObject:SetActiveEx(false)
    end
end

return XUiPBRShopNewDetailGridItem
