---@class XUiPBRShopNewGridItem : XUiNode
---@field _Control XPBRGameControl
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
    if self.TxtDetail:GetType() == typeof(CS.XUiComponent.XUiRichTextCustomRender) then
        self.TxtDetail.requestImage = self._Control:GetRichTextImageRequestHandler()
    end
    
    if self.BtnChoose then
        self.BtnChoose:AddEventListener(function() self:OnBtnChooseClick() end)
    end
    
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

function XUiPBRShopNewGridItem:OnBtnChooseClick()
    self.RootUi:OnSelectItemSignal(self.ItemId)
end

---@param itemId number
function XUiPBRShopNewGridItem:Refresh(itemId, resetScroll)
    self:AOPRefreshBefore()

    if not itemId then
        -- 显示空
        self:ShowEmpty()
        return
    end

    if resetScroll then
        self.PanelDesc.verticalNormalizedPosition = 1
    end

    self.ItemId = itemId


    local itemCfg = self._Control:GetPBRItemCfgById(itemId)

    -- 基础信息
    self.TxtName.text = itemCfg.ItemName
    self.TxtDetail.text = XUiHelper.ReplaceTextNewLine(itemCfg.ItemDesc)

    -- 根据颜色获取对应的样式
    local gridStyle = self:_GetGridStyleByColor(itemCfg.OrbColor)

    if gridStyle then
        gridStyle:Open()
        
        gridStyle:Refresh(self.ItemId)

        if itemCfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Skill then
            self:AOPRefreshSkillShowAddition()
        end
    end

    self:AOPRefreshAfter()
end

---@overload
function XUiPBRShopNewGridItem:AOPRefreshBefore()
    self:HideAllGridStyles()

    -- 默认隐藏
    if self.ImgUp then
        self.ImgUp.gameObject:SetActiveEx(false)
    end

    if self.TxtUpDesc then
        self.TxtUpDesc.gameObject:SetActiveEx(false)
    end

    if self.ImgUpBg then
        self.ImgUpBg.gameObject:SetActiveEx(false)
    end
end

---@overload
function XUiPBRShopNewGridItem:AOPRefreshSkillShowAddition()
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
        -- 显示升级箭头和描述
        if self.ImgUp then
            self.ImgUp.gameObject:SetActiveEx(true)
        end
        
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

---@overload
function XUiPBRShopNewGridItem:AOPRefreshAfter()
    if self.BtnChoose then
        -- 判断当前是否已选择该物品，如果是则置灰按钮
        self.BtnChoose:SetButtonState(self._Control.InGameControl:GetIsItemChoseByItemId(self.ItemId) and CS.UiButtonState.Disable or CS.UiButtonState.Normal)
    end
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
    self.TxtName.text = ''
    self.TxtDetail.text = ''

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
                grid = XUiPBRShopNewGridStyle.New(go, self, self.RootUi)

                self.GridStyleDict[styleType] = grid
            end
        end
        
        return grid
    end
end

return XUiPBRShopNewGridItem
