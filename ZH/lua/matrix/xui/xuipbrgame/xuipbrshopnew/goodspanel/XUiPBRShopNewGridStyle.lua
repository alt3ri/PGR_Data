--- 商品样式节点
---@class XUiPBRShopNewGridStyle: XUiNode
---@field protected _Control
---@field Parent
local XUiPBRShopNewGridStyle = XClass(XUiNode, "XUiPBRShopNewGridStyle")
local XUiPBRCommonItemDetailTag = require("XUi/XUiPBRGame/CommonUiTemplate/ItemDetailPopupPanel/XUiPBRCommonItemDetailTag")
local XUiPBRShopNewGridIcon = require('XUi/XUiPBRGame/XUiPBRShopNew/GoodsPanel/XUiPBRShopNewGridIcon')

---@param rootUi XLuaUi
function XUiPBRShopNewGridStyle:OnStart(rootUi)
    self.RootUi = rootUi

    self:InitComponents()
end

function XUiPBRShopNewGridStyle:OnEnable()
end

function XUiPBRShopNewGridStyle:OnDisable()
end

function XUiPBRShopNewGridStyle:OnDestroy()
end

function XUiPBRShopNewGridStyle:InitComponents()
    ---@type XUiPBRShopNewGridIcon
    self.GridIcon = XUiPBRShopNewGridIcon.New(self.GridItem, self, self.RootUi)
    self.GridIcon:Open()
end

---@param itemId number
function XUiPBRShopNewGridStyle:Refresh(itemId)
    if not itemId then
        return
    end

    self.ItemId = itemId
    
    local itemCfg = self._Control:GetPBRItemCfgById(itemId)

    self.GridIcon:RefreshIcon(self.ItemId)

    -- 判断类型
    if itemCfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Other then
        self.GridIcon:RefreshPropQualityColor(itemCfg.ItemTier)
    end

    -- 显示星级
    self:ShowStartByLevel(itemCfg.ItemTier)

    -- 刷新标签显示
    self:RefreshTagsShow(itemCfg.Tags)
end

function XUiPBRShopNewGridStyle:ShowStartByLevel(level)
    XUiHelper.RefreshCustomizedList(self.PanelStar, self.ImgStar, level, nil)
end

function XUiPBRShopNewGridStyle:RefreshTagsShow(tags)
    if self._TagGridDict == nil then
        self._TagGridDict = {}
    else
        for i, v in pairs(self._TagGridDict) do
            v:Close()
        end
    end

    XUiHelper.RefreshCustomizedList(self.PanelTag.transform, self.Tag, tags and #tags or 0, function(index, go)
        ---@type XUiPBRCommonItemDetailTag
        local tagGrid = self._TagGridDict[go]

        if not tagGrid then
            tagGrid = XUiPBRCommonItemDetailTag.New(go, self)
            self._TagGridDict[go] = tagGrid
        end

        tagGrid:Open()
        tagGrid:SetTagShow(tags[index])
    end)
end

return XUiPBRShopNewGridStyle