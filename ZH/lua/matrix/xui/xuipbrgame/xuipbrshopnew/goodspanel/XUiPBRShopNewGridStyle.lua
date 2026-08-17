--- 商品样式节点
---@class XUiPBRShopNewGridStyle: XUiNode
---@field protected _Control
---@field Parent
--- 以下为 prefab 自动注入的 UI 节点
---@field GridItem UnityEngine.RectTransform 图标节点（在 InitComponents 中包装为 XUiPBRShopNewGridIcon）
---@field PanelStar UnityEngine.RectTransform 星级列表容器
---@field ImgStar UnityEngine.RectTransform 单颗星级图标模板（按商品品阶数量动态生成）
---@field PanelTag UnityEngine.RectTransform 标签列表容器
---@field Tag1 UnityEngine.RectTransform 第1个标签固定节点（包装为 XUiPBRCommonItemDetailTag）
---@field Tag2 UnityEngine.RectTransform 第2个标签固定节点（包装为 XUiPBRCommonItemDetailTag）
---@field Tag3 UnityEngine.RectTransform 第3个标签固定节点（包装为 XUiPBRCommonItemDetailTag）
---@field TxtName UnityEngine.UI.Text 商品名称
---@field TxtDetail XUiComponent.XUiRichTextCustomRender 商品效果描述（富文本，支持图文）
---@field PanelDesc UnityEngine.UI.ScrollRect 描述文本滚动区（刷新时可重置到顶部）
---@field ImgUpBg UnityEngine.RectTransform 升阶效果描述背景（仅同阶合成显示）
---@field TxtUpDesc UnityEngine.UI.Text 升阶后效果描述文本
---@field BtnChoose XUiComponent.XUiButton 购买/选择该商品按钮（已选时置灰）
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
    if self.TxtDetail and self.TxtDetail:GetType() == typeof(CS.XUiComponent.XUiRichTextCustomRender) then
        self.TxtDetail.requestImage = self._Control:GetRichTextImageRequestHandler()
        self._IsTxtDetailRichText = true
    end

    if self.BtnChoose then
        self.BtnChoose:AddEventListener(function() self:OnBtnChooseClick() end)
    end

    ---@type XUiPBRShopNewGridIcon
    self.GridIcon = XUiPBRShopNewGridIcon.New(self.GridItem, self, self.RootUi)
    self.GridIcon:Open()

    local ConstTagCount = 3
    self._TagGridList = {}
    for i = 1, ConstTagCount do
        local go = self["Tag" .. i]
        if go then
            local tagGrid = XUiPBRCommonItemDetailTag.New(go, self)
            tagGrid:Open()
            self._TagGridList[i] = tagGrid
        end
    end
end

function XUiPBRShopNewGridStyle:OnBtnChooseClick()
    self.RootUi:OnSelectItemSignal(self.ItemId)
end

---@param itemId number
---@param resetScroll boolean 是否将描述滚动区复位到顶部
function XUiPBRShopNewGridStyle:Refresh(itemId, resetScroll)
    self:_RefreshBefore()

    if not itemId then
        return
    end

    if resetScroll and self.PanelDesc then
        self.PanelDesc.verticalNormalizedPosition = 1
    end

    self.ItemId = itemId

    local itemCfg = self._Control:GetPBRItemCfgById(itemId)

    -- 基础信息
    self.TxtName.text = itemCfg.ItemName
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(itemCfg.ItemDesc)

    -- 富文本图标在 GridStyle Close→Open(换色切回曾显示过的色) 或 OnDisable→OnEnable 循环后，
    -- 若 text 与该样式上次显示时相同(同商品)，ParseText 不重置标志，叠加 text setter 的 RecycleAllIconRender
    -- 与 OnPopulateMesh 填充时序冲突，usingIcons 被清空后图标永久 active=false。
    -- 设完 text 后主动 ForcePopulateIcons 强制重填 usingIcons 并置 iconShowed=true，绕过时序竞态。
    if self._IsTxtDetailRichText then
        self.TxtDetail:ForcePopulateIcons()
    end

    self.GridIcon:RefreshIcon(self.ItemId)

    -- 判断类型
    if itemCfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Other then
        self.GridIcon:RefreshPropQualityColor(itemCfg.ItemTier)
    end

    -- 显示星级
    self:ShowStartByLevel(itemCfg.ItemTier)

    -- 刷新标签显示
    self:RefreshTagsShow(itemCfg.Tags)

    -- 技能类需要额外展示升阶提示
    if itemCfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Skill then
        self:_RefreshSkillShowAddition()
    end

    -- 刷新购买按钮状态：已选择则置灰
    if self.BtnChoose then
        self.BtnChoose:SetButtonState(self._Control.InGameControl:GetIsItemChoseByItemId(self.ItemId) and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    end
end

--- 刷新前默认隐藏升阶提示（ImgUp 已上浮至 GridItem 管理）
function XUiPBRShopNewGridStyle:_RefreshBefore()
    if self.TxtUpDesc then
        self.TxtUpDesc.gameObject:SetActiveEx(false)
    end

    if self.ImgUpBg then
        self.ImgUpBg.gameObject:SetActiveEx(false)
    end
end

--- 技能升阶提示：判断当前技能是否可合并升阶，是则展示升阶描述（ImgUp 箭头已上浮至 GridItem）
function XUiPBRShopNewGridStyle:_RefreshSkillShowAddition()
    -- 对于技能而言，存在合并升阶，需要判断当前技能是否已拥有
    local isHigherOrCanBeHigher = false
    local isOwned, nextLevelItemId = self._Control.InGameControl:CheckIsHasItemAndGetNextItemId(self.ItemId)

    if isOwned and nextLevelItemId then
        isHigherOrCanBeHigher = true
    else
        local isHigher, oldItemId = self._Control.InGameControl:CheckItemIsHigherThanOwnedSkill(self.ItemId)

        if isHigher and oldItemId then
            isHigherOrCanBeHigher = true
        end
    end

    local notSold = not self._Control.InGameControl:GetIsItemChoseByItemId(self.ItemId)

    if isHigherOrCanBeHigher and notSold then
        if XTool.IsNumberValidEx(nextLevelItemId) then
            -- 只有同阶合成时才需要显示下一阶的效果描述
            if self.ImgUpBg then
                self.ImgUpBg.gameObject:SetActiveEx(true)
            end

            if self.TxtUpDesc then
                self.TxtUpDesc.gameObject:SetActiveEx(true)
            end

            local nextItemCfg = self._Control:GetPBRItemCfgById(nextLevelItemId)

            if nextItemCfg and self.TxtUpDesc then
                self.TxtUpDesc.text = XUiHelper.ReplaceTextNewLine(nextItemCfg.ItemDesc)
            end
        end
    end
end

function XUiPBRShopNewGridStyle:ShowStartByLevel(level)
    XUiHelper.RefreshCustomizedList(self.PanelStar, self.ImgStar, level, nil)
end

function XUiPBRShopNewGridStyle:RefreshTagsShow(tags)
    for i = 1, #self._TagGridList do
        self._TagGridList[i]:SetTagShow(tags and tags[i])
    end
end

return XUiPBRShopNewGridStyle