--- 物品容器基类
---@class XUiGridTheatre5Container: XUiNode
---@field protected _Control XTheatre5Control
local XUiGridTheatre5Container = XClass(XUiNode, 'XUiGridTheatre5Container')

function XUiGridTheatre5Container:OnStart()
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre5Container:OnDisable()
    self:_ClearItemShow()
end

--- 设置容器索引
function XUiGridTheatre5Container:SetContainerIndex(index)
    self.ContainerIndex = index

    if self.UiGridSkill then
        self.UiGridSkill:SetBelongIndex(index)
    end

    if self.UiGridGem then
        self.UiGridGem:SetBelongIndex(index)
    end
end

--- 设置容器类型
function XUiGridTheatre5Container:SetContainerType(type)
    self.ContainerType = type

    if self.UiGridSkill then
        self.UiGridSkill:SetOwnerContainerType(type)
    end

    if self.UiGridGem then
        self.UiGridGem:SetOwnerContainerType(type)
    end
end

--- 初始化容器内的物品类，物品类始终作为子节点存在，不会在游戏过程中改变从属关系
function XUiGridTheatre5Container:InitBindItem(cls)
    if self._IsInitBindItems then
        return
    end

    local uiClass = cls and cls or require("XUi/XUiTheatre5/XUiTheatre5BattleShop/UiGridItems/XUiGridTheatre5Item")

    if uiClass then
        if self.GridSkill then
            self.UiGridSkill = uiClass.New(self.GridSkill, self)
        end

        if self.GridGem then
            self.UiGridGem = uiClass.New(self.GridGem, self)
        end

        self._IsInitBindItems = true

        self:_ClearItemShow()

    else
        XLog.Error('物品类不存在:', uiClass)
    end
end

function XUiGridTheatre5Container:GetIsInitBindItems()
    return self._IsInitBindItems
end

--- 设置显示的物品
---@param itemData XTheatre5Item
function XUiGridTheatre5Container:SetItemData(itemData)
    if not itemData then
        self:_ClearItemShow()
        return
    end

    self:_SetItemType(itemData.ItemType)

    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end

    if not self.CurUiGrid then
        return
    end

    self.CurUiGrid:Open()
    self.CurUiGrid:RefreshShow(itemData)
end

--- 设置显示的物品
function XUiGridTheatre5Container:SetItemShowById(itemId)
    if not XTool.IsNumberValid(itemId) then
        self:_ClearItemShow()
        return
    end

    ---@type XTableTheatre5Item
    local itemCfg = self._Control:GetTheatre5ItemCfgById(itemId)

    if itemCfg then
        self:_SetItemType(itemCfg.Type)

        if self.ImgSelect then
            self.ImgSelect.gameObject:SetActiveEx(false)
        end

        if not self.CurUiGrid then
            return
        end

        self.CurUiGrid:Open()
        self.CurUiGrid:RefreshShowById(itemId)
    end
end

function XUiGridTheatre5Container:_SetItemType(type)
    self.ItemType = type

    if self.UiGridSkill then
        self.UiGridSkill:Close()
    end

    if self.UiGridGem then
        self.UiGridGem:Close()
    end

    if self.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Skill then
        self.CurUiGrid = self.UiGridSkill
    elseif self.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Equip
            or self.ItemType == XMVCA.XTheatre5.EnumConst.ItemType.Hammer
    then
        self.CurUiGrid = self.UiGridGem
    end
end

function XUiGridTheatre5Container:_ClearItemShow()
    if self.UiGridSkill then
        self.UiGridSkill:Close()
    end

    if self.UiGridGem then
        self.UiGridGem:Close()
    end

    self.CurUiGrid = nil

    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end
end

-- 高级buff与低级buff不同时生效，需要显示不生效图标
---@param itemData XTheatre5Item
function XUiGridTheatre5Container:UpdateInvalid(itemData)
    local isShowInvalidIcon
    if itemData then
        local isValid = self._Control.ShopControl:CheckRuneValid(itemData)
        if isValid then
            isShowInvalidIcon = false
        else
            isShowInvalidIcon = true
            -- 显示不生效
            --XLog.Debug("物品不生效:" .. itemData.ItemId)
        end
    end
    -- 不一定是符文
    if self.UiGridGem and self.UiGridGem.UpdateInvalid then
        self.UiGridGem:UpdateInvalid(isShowInvalidIcon)
    end
end

return XUiGridTheatre5Container