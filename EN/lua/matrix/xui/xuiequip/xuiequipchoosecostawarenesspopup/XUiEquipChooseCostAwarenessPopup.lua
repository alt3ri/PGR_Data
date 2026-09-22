local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")

-- 选择本次消耗意识的弹窗
---@class XUiEquipChooseCostAwarenessPopup : XLuaUi
---@field _Control XEquipControl 装备控制器
---@field AwarenessIdList number[] 可作为本次共鸣消耗的意识装备 Id 列表
---@field SelectedAwarenessIdMap table<number, boolean> 当前弹窗内已选意识字典
---@field ConfirmCb fun(selectedAwarenessIdMap:table<number, boolean>)|nil 确认选择回调
---@field DynamicTable XDynamicTableNormal 意识动态滑动列表
---@field BtnClose XUiComponent.XUiButton 关闭按钮
---@field PanelAwareness UnityEngine.GameObject|UnityEngine.RectTransform 意识动态滑动列表
---@field GridAwareness UiObject 意识列表项模板
---@field TxtChoosesNum UnityEngine.UI.Text 已选择数量文本
---@field BtnSelectAll XUiComponent.XUiButton 全选按钮
---@field BtnComfirm XUiComponent.XUiButton 确认选择按钮
local XUiEquipChooseCostAwarenessPopup = XLuaUiManager.Register(XLuaUi, "UiEquipChooseCostAwarenessPopup")

-- 初始化弹窗基础交互和模板显示状态
function XUiEquipChooseCostAwarenessPopup:OnAwake()
    self.AwarenessIdList = {}
    self.SelectedAwarenessIdMap = {}
    self:InitComponents()
end

-- 绑定关闭、全选和确认按钮的点击入口
function XUiEquipChooseCostAwarenessPopup:InitComponents()
    self.BtnClose:AddEventListener(function() self:OnBtnCloseClick() end)
    self.BtnSelectAll:AddEventListener(function() self:OnBtnSelectAllClick() end)
    self.BtnComfirm:AddEventListener(function() self:OnBtnComfirmClick() end)

    self.GridAwareness.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

-- 初始化可消耗意识动态列表，由 XDynamicTableNormal 负责滚动复用 GridAwareness
function XUiEquipChooseCostAwarenessPopup:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelAwareness)
    self.DynamicTable:SetProxy(XUiGridEquip, self)
    self.DynamicTable:SetDelegate(self)
end

-- 接收业务数据后刷新可消耗意识列表
---@param awarenessIdList number[] 可消耗意识装备 Id 列表
---@param selectedAwarenessIdMap table<number, boolean>|nil 已选意识字典
---@param confirmCb fun(selectedAwarenessIdMap:table<number, boolean>)|nil 确认回调
function XUiEquipChooseCostAwarenessPopup:OnStart(awarenessIdList, selectedAwarenessIdMap, confirmCb)
    self.AwarenessIdList = awarenessIdList or {}
    self.SelectedAwarenessIdMap = XTool.Clone(selectedAwarenessIdMap) or {}
    self.ConfirmCb = confirmCb
    self:Refresh()
end

-- 刷新意识列表、选中状态和数量显示
function XUiEquipChooseCostAwarenessPopup:Refresh()
    local awarenessIdList = self.AwarenessIdList
    self.DynamicTable:SetDataSource(awarenessIdList)
    self.DynamicTable:ReloadDataASync(#awarenessIdList > 0 and 1 or -1)
    self:RefreshChooseCount()
end

-- 动态列表回调：初始化、刷新和点击单个意识格子
---@param event number 动态列表事件
---@param index number 数据下标
---@param grid XUiGridEquip 意识装备格子
function XUiEquipChooseCostAwarenessPopup:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local equipId = self.AwarenessIdList[index]
        grid:Refresh(equipId)
        local isSelected = self:IsAwarenessSelected(equipId)
        grid:SetSelected(isSelected)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local equipId = self.AwarenessIdList[index]
        self:OnGridAwarenessClick(equipId)
    end
end

-- 判断指定意识是否被选为本次消耗
---@param equipId number 意识装备 Id
---@return boolean 是否选中
function XUiEquipChooseCostAwarenessPopup:IsAwarenessSelected(equipId)
    return self.SelectedAwarenessIdMap[equipId] == true
end

-- 点击意识格子时切换本弹窗内的选中状态
---@param equipId number 意识装备 Id
function XUiEquipChooseCostAwarenessPopup:OnGridAwarenessClick(equipId)
    local isSelected = self:IsAwarenessSelected(equipId)
    if isSelected then
        self.SelectedAwarenessIdMap[equipId] = nil
    else
        self.SelectedAwarenessIdMap[equipId] = true
    end

    self:RefreshGridSelectedState()
    self:RefreshChooseCount()
end

-- 刷新所有意识格子的选中表现
function XUiEquipChooseCostAwarenessPopup:RefreshGridSelectedState()
    local grids = self.DynamicTable:GetGrids()
    for index, grid in pairs(grids) do
        local equipId = self.AwarenessIdList[index]
        local isSelected = self:IsAwarenessSelected(equipId)
        grid:SetSelected(isSelected)
    end
end

-- 刷新已选择意识数量显示
function XUiEquipChooseCostAwarenessPopup:RefreshChooseCount()
    local selectedCount = self:GetSelectedAwarenessCount()
    local totalCount = #self.AwarenessIdList
    self.TxtChoosesNum.text = string.format("%d/%d", selectedCount, totalCount)

    local isAllSelected = totalCount > 0 and selectedCount >= totalCount
    self.BtnSelectAll:SetButtonState(isAllSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

-- 统计当前候选列表中的已选意识数量
---@return number 已选择数量
function XUiEquipChooseCostAwarenessPopup:GetSelectedAwarenessCount()
    local count = 0
    for _, equipId in ipairs(self.AwarenessIdList) do
        if self:IsAwarenessSelected(equipId) then
            count = count + 1
        end
    end

    return count
end

-- 点击全选按钮，根据当前选择数量执行全选或全部取消
function XUiEquipChooseCostAwarenessPopup:OnBtnSelectAllClick()
    local totalCount = #self.AwarenessIdList
    local isSelectAll = self:GetSelectedAwarenessCount() < totalCount
    self.SelectedAwarenessIdMap = {}
    if isSelectAll then
        for _, equipId in ipairs(self.AwarenessIdList) do
            self.SelectedAwarenessIdMap[equipId] = true
        end
    end

    self:RefreshGridSelectedState()
    self:RefreshChooseCount()
end

-- 点击确认按钮，回传只包含已选意识的字典并关闭弹窗
function XUiEquipChooseCostAwarenessPopup:OnBtnComfirmClick()
    if self.ConfirmCb then
        self.ConfirmCb(self:BuildConfirmSelectedAwarenessIdMap())
    end
    self:Close()
end

-- 构建回传给父面板的已选意识字典，未选意识不写入以便父面板判断空表
---@return table<number, boolean> 已选意识字典
function XUiEquipChooseCostAwarenessPopup:BuildConfirmSelectedAwarenessIdMap()
    local selectedAwarenessIdMap = {}
    for _, equipId in ipairs(self.AwarenessIdList) do
        if self:IsAwarenessSelected(equipId) then
            selectedAwarenessIdMap[equipId] = true
        end
    end

    return selectedAwarenessIdMap
end

-- 点击关闭按钮关闭弹窗
function XUiEquipChooseCostAwarenessPopup:OnBtnCloseClick()
    self:Close()
end

return XUiEquipChooseCostAwarenessPopup
