--- 物品基类
---@class XUiGridTheatre5Item: XUiNode
---@field protected _Control XTheatre5Control
local XUiGridTheatre5Item = XClass(XUiNode, 'XUiGridTheatre5Item')
local XUiGridTheatre5ItemTag = require('XUi/XUiTheatre5/XUiTheatre5BubbleItemDetail/XUiGridTheatre5ItemTag')

function XUiGridTheatre5Item:OnStart()
    self._IsHideTag = false
    if self.GridBtn then
        self.GridBtn:AddEventListener(handler(self, self.OnGridBtnClickEvent))
    end

    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(false)
    end

    if self.PanelSellPrice then
        self.PanelSellPrice.gameObject:SetActiveEx(false)
    end
    if self.Noneffective then
        self.Noneffective.gameObject:SetActiveEx(false)
    end
end

function XUiGridTheatre5Item:SetOwnerContainerType(containerType)
    self.OwnerContainerType = containerType
end

function XUiGridTheatre5Item:SetBelongIndex(index)
    self.BelongIndex = index
end

---@param itemData XTheatre5Item
function XUiGridTheatre5Item:RefreshShow(itemData)
    if not itemData then
        return
    end

    self.ItemData = itemData

    ---@type XTableTheatre5Item
    local cfg = self._Control:GetTheatre5ItemCfgById(itemData.ItemId)

    if cfg then
        if self.RImgIcon then
            self.RImgIcon:SetRawImage(cfg.IconRes)
        end

        if self.RawImgBgQuality then
            local color = self._Control:GetClientConfigGemQualityColor(cfg.Quality)

            if color then
                self.RawImgBgQuality.color = color
            end
        end

        self:_RefreshTagsShow(cfg)
        self:_RefreshStrengthen(itemData)
    end
end

function XUiGridTheatre5Item:RefreshShowById(itemId)
    if not XTool.IsNumberValid(itemId) then
        return
    end

    self.ItemId = itemId

    ---@type XTableTheatre5Item
    local cfg = self._Control:GetTheatre5ItemCfgById(self.ItemId)

    if cfg then
        if self.RImgIcon then
            self.RImgIcon:SetRawImage(cfg.IconRes)
        end

        if self.RawImgBgQuality then
            local color = self._Control:GetClientConfigGemQualityColor(cfg.Quality)

            if color then
                self.RawImgBgQuality.color = color
            end
        end

        self:_RefreshTagsShow(cfg)
    end
end

function XUiGridTheatre5Item:_RefreshTagsShow(cfg)
    -- 刷新标签
    if not self.ListTag or not self.Tag then
        return
    end

    -- 部份ui不显示
    if self._IsHideTag then
        return
    end

    self.ListTag.gameObject:SetActiveEx(true)

    if self.TagGrids == nil then
        self.TagGrids = {}
    end

    if not XTool.IsTableEmpty(self.TagGrids) then
        for i, v in pairs(self.TagGrids) do
            v:Close()
        end
    end

    XUiHelper.RefreshCustomizedList(self.ListTag.transform, self.Tag, #cfg.Tags, function(index, go)
        local grid = self.TagGrids[go]

        if not grid then
            grid = XUiGridTheatre5ItemTag.New(go, self)
            self.TagGrids[go] = grid
        end

        grid:Open()
        grid:Refresh(self._Control:GetTheatre5ItemTagCfgById(cfg.Tags[index]))
    end)
end

--region 选择
function XUiGridTheatre5Item:OnGridBtnClickEvent()
    self.IsSelected = not self.IsSelected

    self:RefreshSelectState()

    if self.IsSelected then
        self._Control:SetItemSelected(self)
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_OPEN_ITEM_DETAIL, self.ItemData, self.OwnerContainerType, self.Parent.DetailPos)
    else
        self._Control:SetItemSelected(nil)
        self._Control:DispatchEvent(XMVCA.XTheatre5.EventId.EVENT_THEATRE5_HIDE_ITEM_DETAIL)
    end
end

function XUiGridTheatre5Item:UnSelect()
    self.IsSelected = false
    self:RefreshSelectState()
end

function XUiGridTheatre5Item:RefreshSelectState()
    if self.ImgSelect then
        self.ImgSelect.gameObject:SetActiveEx(self.IsSelected)

        if self.IsSelected then
            self:PlayAnimation('GridRefresh')
        end
    end
end
--endregion

---@param itemData XTheatre5Item
function XUiGridTheatre5Item:_RefreshStrengthen(itemData)
    if self.PanelStar then
        if itemData.IsStrengthen then
            self.PanelStar.gameObject:SetActiveEx(true)
        else
            self.PanelStar.gameObject:SetActiveEx(false)
        end
    end
end

function XUiGridTheatre5Item:UpdateInvalid(value)
    if self.Noneffective then
        self.Noneffective.gameObject:SetActiveEx(value)
    end
end

function XUiGridTheatre5Item:SetHideTag(value)
    self._IsHideTag = value
end

return XUiGridTheatre5Item