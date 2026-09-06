local XUiPanelPunishaarCollection = XClass(XUiNode, "XUiPanelPunishaarCollection")
local XUiPanelPunishaarCollectionCard = require("XUi/XUiPunishaar/Panel/XUiPanelPunishaarCollectionCard")

function XUiPanelPunishaarCollection:OnStart()
    local cardRoot = self.UiPunishaarGridCard.transform.parent

    self._GridLayout = cardRoot:GetComponent(
        typeof(CS.UnityEngine.UI.GridLayoutGroup)
    )

    if not XTool.UObjIsNil(self._GridLayout) then
        self._BaseCellWidth = self._GridLayout.cellSize.x
        self._BaseCellHeight = self._GridLayout.cellSize.y
    end
end

---@param size number 卡牌占位尺寸：1/2/3
function XUiPanelPunishaarCollection:Refresh(size)
    self._Size = size
    self:RefreshGridSize(size)

    -- 需求中的分组标题是1x、2x、3x
    self.TxtTitleSlot.text = string.format("%dx", size)

    local allCollectionDatas = self.Parent:GetCurrentCollectionDatas()

    self._CollectionDatas = allCollectionDatas[size] or {}


    self.UiCardList = self.UiCardList or {}

    XTool.UpdateDynamicItem(
        self.UiCardList,
        self._CollectionDatas,
        self.UiPunishaarGridCard,
        XUiPanelPunishaarCollectionCard,
        self
    )

    for index = 1, #self._CollectionDatas do
        local cardData = self._CollectionDatas[index]
        local grid = self.UiCardList[index]

        grid:SetSelected(
            self.Parent:IsCardSelected(cardData.Id)
        )
    end

    CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.Transform)
end

---@param data table 卡牌图鉴数据
---@param grid XUiPanelPunishaarCollectionCard
function XUiPanelPunishaarCollection:OnCardClick(data, grid)
    if self.Parent.OnMainCardClick then
        self.Parent:OnMainCardClick(data, grid)
    end
end

---@param allowLocked boolean 是否允许选择未解锁卡
---@return boolean 是否成功选中
function XUiPanelPunishaarCollection:SelectFirstCard(allowLocked)
    for index, data in ipairs(self._CollectionDatas or {}) do
        if data.IsUnlocked then
            local grid = self.UiCardList and self.UiCardList[index]

            if grid then
                self:OnCardClick(data, grid)
                return true
            end
        end
    end

    if allowLocked then
        local data = self._CollectionDatas
            and self._CollectionDatas[1]
        local grid = self.UiCardList
            and self.UiCardList[1]

        if data and grid then
            self:OnCardClick(data, grid)
            return true
        end
    end

    return false
end

function XUiPanelPunishaarCollection:RefreshGridSize(size)
    if XTool.UObjIsNil(self._GridLayout) then
        XLog.Error("Punishaar collection GridLayoutGroup is nil")
        return
    end

    local width = self._BaseCellWidth * (size or 1)
    self._GridLayout.cellSize = CS.UnityEngine.Vector2(width, self._BaseCellHeight)
end

return XUiPanelPunishaarCollection
