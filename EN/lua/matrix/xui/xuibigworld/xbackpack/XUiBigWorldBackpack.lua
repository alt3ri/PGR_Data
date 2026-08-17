local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiBigWorldBackpackDetail = require("XUi/XUiBigWorld/XBackpack/XUiBigWorldBackpackDetail")
local XUiBigWorldBackpackItem = require("XUi/XUiBigWorld/XBackpack/XUiBigWorldBackpackItem")

---@class XUiBigWorldBackpack : XBigWorldUi
---@field PanelItem UnityEngine.RectTransform
---@field PanelBagItem UnityEngine.RectTransform
---@field BtnClose XUiComponent.XUiButton
---@field BtnBgClose XUiComponent.XUiButton
---@field PanelItemDetail UnityEngine.RectTransform
---@field BagTags XUiButtonGroup
---@field BtnTog XUiComponent.XUiButton
---@field PaneNothing UnityEngine.RectTransform
---@field PanelBackpackList UnityEngine.RectTransform
---@field TxtTagTitle UnityEngine.UI.Text
---@field TxtTitle UnityEngine.UI.Text
---@field _Control XBigWorldBackpackControl
local XUiBigWorldBackpack = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldBackpack")

-- region 生命周期

function XUiBigWorldBackpack:OnAwake()
    -- local itemSize = self.PanelBagItem.rect
    -- local parentSize = self.PanelBagItem.parent.parent.rect
    -- self.ColCount = math.floor(parentSize.width / itemSize.width)
    -- self.RowCount = math.ceil(parentSize.height / itemSize.height)
    -- self.MaxCount = self.ColCount * self.RowCount

    ---@type XUiBigWorldBackpackDetail
    self._DetailUi = XUiBigWorldBackpackDetail.New(self.PanelItemDetail, self)
    ---@type XUiComponent.XUiButton[]
    self._TagList = {}
    self._IndexTypeMap = {}

    self._CurrentSelectItemIndex = false
    self._CurrentSelectIndex = 0
    self._DefaultIndex = 4

    self:_InitUi()
    self:_InitTabs()
    self:_RegisterButtonClicks()
end

function XUiBigWorldBackpack:OnStart()
    self._DynamicTable = XDynamicTableNormal.New(self.PanelItem)
    self._DynamicTable:SetProxy(XUiBigWorldBackpackItem, self)
    self._DynamicTable:SetDelegate(self)
    self._DetailUi:Close()
end

function XUiBigWorldBackpack:OnEnable()
    self:RefreshType()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldBackpack:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
end

function XUiBigWorldBackpack:OnDestroy()

end

-- endregion

-- region 按钮事件

function XUiBigWorldBackpack:OnBagTagsClick(index)
    local selectType = self._IndexTypeMap[index]

    if selectType and self._CurrentSelectIndex ~= index then
        if self._CurrentSelectIndex ~= 0 then
            self:PlayAnimation("QieHuan")
        end
        self._CurrentSelectIndex = index
        self._CurrentSelectItemIndex = false
        self._DetailUi:Close()
        self:_RefreshTitle()
        self:_RefreshDynamicTable()
    end
end

function XUiBigWorldBackpack:OnItemGridClick(index, itemParams, goodParams)
    if not itemParams or not goodParams then
        self._DetailUi:Close()
        return
    end

    if self._CurrentSelectItemIndex and self._CurrentSelectItemIndex ~= index then
        local grid = self._DynamicTable:GetGridByIndex(self._CurrentSelectItemIndex)

        if grid then
            grid:SetSelect(false)
        end
        self:PlayAnimation("LtemDetailQieHuan")
    end

    self._CurrentSelectItemIndex = index
    self:_RefreshTagReddot()
    self._DetailUi:Open()
    self._DetailUi:Refresh(itemParams, goodParams, XMVCA.XBigWorldQuest:IsQuestItem(itemParams.TemplateId))
end

---@param grid XUiBigWorldBackpackItem
function XUiBigWorldBackpack:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self._DynamicTable:GetData(index)
        grid:Refresh(data, index, self._CurrentSelectItemIndex == index)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        local allUseGird = self._DynamicTable:GetGrids()
        
        local grid = allUseGird[1]
        if not grid then return end

        if not self.ColCount then
            local tr = grid.Transform
            local itemSize = tr.rect
            local parentSize = tr.parent.parent.rect
            self.ColCount = math.floor(parentSize.width / itemSize.width)
            self.RowCount = math.ceil(parentSize.height / itemSize.height)
            self.MaxCount = self.ColCount * self.RowCount
        end

        for index, grid in pairs(allUseGird) do
            if index <= self.MaxCount then
                local col = math.ceil(index / self.ColCount)
                local row = (index - 1) % self.ColCount + 1
                grid:PlayEnableAnimation(col + row - 1 + self._DefaultIndex)
            else
                grid:PlayEnableAnimation(1)
            end
        end
        self._DefaultIndex = 0
    end
end

-- endregion

-- region 私有方法

function XUiBigWorldBackpack:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self:RegisterClickEvent(self.BtnBgClose, self.Close, true)
    self.BagTags:Init(self._TagList, Handler(self, self.OnBagTagsClick))
end

function XUiBigWorldBackpack:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldBackpack:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldBackpack:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldBackpack:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldBackpack:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldBackpack:RefreshType(isForce)
    if isForce then
        self._CurrentSelectIndex = 0
    end

    if XTool.IsNumberValid(self._CurrentSelectIndex) then
        self.BagTags:SelectIndex(self._CurrentSelectIndex)
    else
        self.BagTags:SelectIndex(1)
    end
end

function XUiBigWorldBackpack:_RefreshTitle()
    if self.TxtTagTitle then
        local type = self._IndexTypeMap[self._CurrentSelectIndex]
        self.TxtTagTitle.text = self._Control:GetTagTypeDescription(type)
    end
end

function XUiBigWorldBackpack:_RefreshDynamicTable()
    local items = self._Control:GetItemListByType(self._IndexTypeMap[self._CurrentSelectIndex])

    if not XTool.IsTableEmpty(items) then
        local gridSize = self._DynamicTable:GetGridSize()
        local viewSize = self.PanelItem.rect.size
        local spacing = self._DynamicTable:GetSpacing()
        local xCount = math.floor(viewSize.x / (gridSize.x + spacing.x))
        local maxFactor = 1
        local itemCount = #items

        if XTool.IsNumberValid(xCount) then
            while maxFactor * xCount < itemCount do
                maxFactor = maxFactor + 1
            end
        end
        for i = 1, maxFactor * xCount do
            if i > itemCount then
                table.insert(items, 0)
            end
        end

        self._CurrentSelectItemIndex = self._CurrentSelectItemIndex or 1
        self.PaneNothing.gameObject:SetActiveEx(false)
        self._DynamicTable:SetActive(true)
        self._DynamicTable:SetDataSource(items)
        self._DynamicTable:ReloadDataSync()
    else
        self._DynamicTable:SetActive(false)
        self.PaneNothing.gameObject:SetActiveEx(true)
    end
end

function XUiBigWorldBackpack:_RefreshTagReddot()
    for index, button in pairs(self._TagList) do
        local type = self._IndexTypeMap[index]

        if type then
            button:ShowReddot(self._Control:CheckTypeHasNotRecord(type))
        end
    end
end

function XUiBigWorldBackpack:_InitUi()
    self.PanelBagItem.gameObject:SetActiveEx(false)
end

function XUiBigWorldBackpack:_InitTabs()
    local types = self._Control:GetAllBackpackType(true, true)
    local index = 1

    for _, config in pairs(types) do
        local button = XUiHelper.Instantiate(self.BtnTog, self.BagTags.transform)

        if button then
            button:SetSprite(config.IconUrl)
            button:ShowReddot(self._Control:CheckTypeHasNotRecord(config.Type))
            self._TagList[index] = button
            self._IndexTypeMap[index] = config.Type
            index = index + 1
        end
    end
    self.BtnTog.gameObject:SetActiveEx(false)
end

-- endregion

return XUiBigWorldBackpack
