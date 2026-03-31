
---@field _Control XPBRGameControl
---@class XUiPBRCollection : XLuaUi
local XUiPBRCollection = XLuaUiManager.Register(XLuaUi, "UiPBRCollection")
local XUiPBRMonsterPopupPanel = require('XUi/XUiPBRGame/XUiPBRCollection/PanelDetail/XUiPBRMonsterPopupPanel')

function XUiPBRCollection:OnAwake()
    self:InitComponents()
end

function XUiPBRCollection:InitComponents()
    -- Back Mainui Help
    self:BindExitBtns()
    self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe(self._Control:GetClientPBRNumberArray('PanelAssetItems'), self.PanelSpecialTool, self)
    
    -- 初始化怪物弹窗
    self.PanelTips.gameObject:SetActiveEx(false)
    ---@type XUiPBRMonsterPopupPanel
    self.MonsterTipsPanel = XUiPBRMonsterPopupPanel.New(self.PanelTips, self)
    
    -- 初始化详情面板
    ---@type XUiPBRCollectionPanelDesc
    self.PanelDesc = require('XUi/XUiPBRGame/XUiPBRCollection/PanelDetail/XUiPBRCollectionPanelDesc').New(self.PanelDesc, self)

    self.GridCollection.gameObject:SetActiveEx(false)
    ---@type XDynamicTableNormal
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelList, require('XUi/XUiPBRGame/XUiPBRCollection/XUiPBRCollectionGridCollection'))
    
    --- 初始化页签
    local buttonList = {}
    
    local tabType = XMVCA.XPBRGame.EnumConst.Collections.TabType
    
    XUiHelper.RefreshCustomizedList(self.PanelTabGroup.transform, self.GridTab, tabType and XTool.GetTableCount(tabType) or 0, function(index, go)
        local xuiButton = go.transform:GetComponent(typeof(CS.XUiComponent.XUiButton))

        if xuiButton then
            table.insert(buttonList, xuiButton)
            
            xuiButton:SetNameByGroup(0, self._Control:GetClientPBRText('CollectionTabName', index))
        end
    end)
    
    self.PanelTabGroup:Init(buttonList, handler(self, self.OnTabSelect), 1)

    --- 初始化排序下拉框
    ---@type XUiPBRCommonDropdownPanel
    self.DropdownPanel = require('XUi/XUiPBRGame/CommonUiTemplate/DropdownPanel/XUiPBRCommonDropdownPanel').New(self.PanelDropdown, self)
    
    -- 各页签索引缓存
    self._Tab2IndexCache = {}
    
    -- 各页签排序类型缓存
    self._Tab2SortTypeCache = {}
    
    self._OnSortValueChangeHandler = handler(self, self.OnSortTypeChange)
end

function XUiPBRCollection:OnStart(...)
    self._Control.CollectionControl:InitOnEnterCollections()
    self.PanelTabGroup:SelectIndex(1)
end

function XUiPBRCollection:OnEnable()
    self._Control:AddEventListener(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_OPEN_MONSTER_ARCHIVE_POPUPPANEL, self.RefreshShow, self)
end

function XUiPBRCollection:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XPBRGame.EventId.EVENT_PBR_INNER_OPEN_MONSTER_ARCHIVE_POPUPPANEL, self.RefreshShow, self)
end

function XUiPBRCollection:OnDestroy()
    self._Control.CollectionControl:ReleaseOnExitCollections()
end

function XUiPBRCollection:OnTabSelect(index)
    if self.CurIndex == index then
        return
    end    
    self.CurIndex = index
    
    self:RefreshCollectionShowByType(self.CurIndex)
    -- 刷新排序下拉框
    -- 获取当前页签拥有的排序类型
    local sortName = {}
    local type2SortTypeList = XMVCA.XPBRGame.EnumConst.Collections.Tab2SortTypeList[self.CurIndex]

    if type2SortTypeList then
        for _, sortType in pairs(type2SortTypeList) do
            table.insert(sortName, self._Control:GetClientPBRText('CollectionSortTypeName', sortType))
        end
    end
    
    self.DropdownPanel:InitDropdownList(sortName, self._OnSortValueChangeHandler, self._Tab2SortTypeCache[self.CurIndex] or XMVCA.XPBRGame.EnumConst.Collections.SortType.Default)
end

function XUiPBRCollection:RefreshCollectionShowByType(tabType)
    self.TxtProgressNum.text = self._Control.CollectionControl:GetCollectionRadio(tabType)
    
    local datas = self._Control.CollectionControl:GetCollectionItemList(tabType, true, self._Tab2SortTypeCache[tabType] or XMVCA.XPBRGame.EnumConst.Collections.SortType.Default)

    self.CurTabType = tabType
    
    if XTool.IsTableEmpty(datas) then
        self.DynamicTable:SetDataSource(nil)
        self.DynamicTable:RecycleAllTableGrid()
    else    
        self.DynamicTable:SetDataSource(datas)
        self.DynamicTable:ReloadDataSync(1)
        self:PlayAnimationWithMask("Qiehuan")
    end
end

function XUiPBRCollection:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Open()
        grid:RefreshShow(self.DynamicTable.DataSource[index])
        
        if index == self.CurSelectIndex then
            self:SelectGrid(grid, index)
        else
            grid:SetSelectState(false)
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Close()
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:SelectGrid(grid, index)
        self._Tab2IndexCache[self.CurTabType] = self.CurSelectIndex
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        -- 默认选中
        local defaultIndex = self._Tab2IndexCache[self.CurTabType] or 1
        
        local tmpGrid = self.DynamicTable:GetGridByIndex(defaultIndex)
        
        if tmpGrid then
            self:SelectGrid(tmpGrid, defaultIndex)
        end
        
        self.CurSelectIndex = defaultIndex
    end
end

function XUiPBRCollection:SelectGrid(grid, index)
    if self.CurSelectIndex then
        local tmpGrid = self.DynamicTable:GetGridByIndex(self.CurSelectIndex)

        if tmpGrid then
            tmpGrid:SetSelectState(false)
        end
    end
    
    grid:SetSelectState(true)
    self.CurSelectIndex = index

    self.PanelDesc:RefreshShow(self.DynamicTable.DataSource[index])
end

function XUiPBRCollection:RefreshShow(worldPos, pivot, desc)
    self.MonsterTipsPanel:Open()
    self.MonsterTipsPanel:RefreshShow(worldPos, pivot, desc)
end

function XUiPBRCollection:OnSortTypeChange(sortIndex)
    local tabType = self.CurTabType
    local type2SortTypeList = XMVCA.XPBRGame.EnumConst.Collections.Tab2SortTypeList[tabType]

    if type2SortTypeList and type2SortTypeList[sortIndex] then
        self._Tab2SortTypeCache[tabType] = type2SortTypeList[sortIndex]
    else
        self._Tab2SortTypeCache[tabType] = nil
    end

    self:RefreshCollectionShowByType(tabType)
end

return XUiPBRCollection
