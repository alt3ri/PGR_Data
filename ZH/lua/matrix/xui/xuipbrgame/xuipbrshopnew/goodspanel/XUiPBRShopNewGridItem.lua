---@class XUiPBRShopNewGridItem : XUiNode
---@field _Control XPBRGameControl
--- 以下为按商品颜色互斥显示的样式节点；均包装为 XUiPBRShopNewGridStyle，商品名称/描述/升阶提示/购买按钮等已下沉其中
---@field GridNull UnityEngine.RectTransform 空位样式（无商品时显示）
---@field GridPropStyle UnityEngine.RectTransform 道具样式节点
---@field GridSkillStyleRed UnityEngine.RectTransform 红色技能样式节点
---@field GridSkillStyleBlue UnityEngine.RectTransform 蓝色技能样式节点
---@field GridSkillStyleYellow UnityEngine.RectTransform 黄色技能样式节点
---@field ImgUp UnityEngine.RectTransform 可升阶提示箭头（拥有可合成技能时显示，由 GridItem 统一管理）
local XUiPBRShopNewGridItem = XClass(XUiNode, "XUiPBRShopNewGridItem")
local XUiPBRShopNewGridStyle = require('XUi/XUiPBRGame/XUiPBRShopNew/GoodsPanel/XUiPBRShopNewGridStyle')

local GridStyleType = {
    Null = 1,
    Prop = 2,
    SkillRed = 3,
    SkillBlue = 4,
    SkillYellow = 5,
}

--- 与配置定义对应
local ItemColor2GridStyle = {
    [0] = GridStyleType.Prop,
    [1] = GridStyleType.SkillRed,
    [2] = GridStyleType.SkillBlue,
    [3] = GridStyleType.SkillYellow,
}

---@param rootUi XLuaUi
function XUiPBRShopNewGridItem:OnStart(rootUi)
    self.RootUi = rootUi

    self:InitComponents()
end

function XUiPBRShopNewGridItem:OnEnable()
end

function XUiPBRShopNewGridItem:OnDisable()
end

function XUiPBRShopNewGridItem:OnDestroy()
end

---@overload
function XUiPBRShopNewGridItem:InitComponents()
    -- 与配置枚举对应
    self.GridStyleUiDict = {
        [GridStyleType.Null] = self.GridNull,
        [GridStyleType.Prop] = self.GridPropStyle,
        [GridStyleType.SkillRed] = self.GridSkillStyleRed,
        [GridStyleType.SkillBlue] = self.GridSkillStyleBlue,
        [GridStyleType.SkillYellow] = self.GridSkillStyleYellow,
    }

    -- 各个UI节点对应的控制对象
    self.GridStyleDict = {}
end

---@param itemId number
function XUiPBRShopNewGridItem:Refresh(itemId, resetScroll)
    self:HideAllGridStyles()

    if not itemId then
        -- 显示空
        self:ShowEmpty()
        if self.ImgUp then
            self.ImgUp.gameObject:SetActiveEx(false)
        end
        return
    end

    self.ItemId = itemId

    local itemCfg = self._Control:GetPBRItemCfgById(itemId)

    -- 根据颜色获取对应的样式，商品名称/描述/升阶提示/购买按钮等展示均由样式节点自行处理
    local gridStyle = self:_GetGridStyleByColor(itemCfg.OrbColor)

    if gridStyle then
        gridStyle:Open()

        gridStyle:Refresh(self.ItemId, resetScroll)
    end

    self:_RefreshImgUp(itemId, itemCfg)
end

function XUiPBRShopNewGridItem:_RefreshImgUp(itemId, itemCfg)
    if not self.ImgUp then
        return
    end

    local show = false

    if itemCfg and itemCfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Skill then
        local isHigherOrCanBeHigher = false
        local isOwned, nextLevelItemId = self._Control.InGameControl:CheckIsHasItemAndGetNextItemId(itemId)

        if isOwned and nextLevelItemId then
            isHigherOrCanBeHigher = true
        else
            local isHigher, oldItemId = self._Control.InGameControl:CheckItemIsHigherThanOwnedSkill(itemId)

            if isHigher and oldItemId then
                isHigherOrCanBeHigher = true
            end
        end

        local notSold = not self._Control.InGameControl:GetIsItemChoseByItemId(itemId)
        show = isHigherOrCanBeHigher and notSold
    end

    self.ImgUp.gameObject:SetActiveEx(show)
end

function XUiPBRShopNewGridItem:HideAllGridStyles()
    for i, v in pairs(GridStyleType) do
        local grid = self.GridStyleDict[v]

        if grid then
            grid:Close()
        else
            local go = self.GridStyleUiDict[v]

            if go then
                go.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiPBRShopNewGridItem:ShowEmpty()
    if self.GridNull then
        self.GridNull.gameObject:SetActiveEx(true)
    end
end

---@return XUiPBRShopNewGridStyle
function XUiPBRShopNewGridItem:_GetGridStyleByColor(color)
    local styleType = ItemColor2GridStyle[color]

    if styleType then
        local grid = self.GridStyleDict[styleType]

        if not grid then
            local go = self.GridStyleUiDict[styleType]

            if go then
                grid = self:GetGridStyleCls().New(go, self, self.RootUi)

                self.GridStyleDict[styleType] = grid
            end
        end
        
        return grid
    end
end

--- 子类可重写：返回样式节点使用的类（详情弹窗复用商品结构时替换为详情样式类）
---@return XUiPBRShopNewGridStyle
function XUiPBRShopNewGridItem:GetGridStyleCls()
    return XUiPBRShopNewGridStyle
end

return XUiPBRShopNewGridItem
