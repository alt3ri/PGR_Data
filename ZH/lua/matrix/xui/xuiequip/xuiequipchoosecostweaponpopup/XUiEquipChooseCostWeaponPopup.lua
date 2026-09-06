local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")

-- 选择本次消耗武器的弹窗
---@class XUiEquipChooseCostWeaponPopup : XLuaUi
---@field _Control XEquipControl 装备控制器
---@field EquipIdList number[] 可作为本次共鸣消耗的武器装备 Id 列表
---@field SelectedEquipIdMap table<number, boolean> 当前弹窗内已选武器字典
---@field ConfirmCb fun(selectedEquipIdMap:table<number, boolean>)|nil 确认选择回调
---@field DynamicTable XDynamicTableNormal 武器动态滑动列表
---@field BtnClose XUiComponent.XUiButton 关闭按钮
---@field PanelWeapon UnityEngine.GameObject|UnityEngine.RectTransform 武器动态滑动列表
---@field GridWeapon UiObject 武器列表项模板
---@field TxtChoosesNum UnityEngine.UI.Text 已选择数量文本
---@field BtnSelectAll XUiComponent.XUiButton 全选按钮
---@field BtnComfirm XUiComponent.XUiButton 确认选择按钮
local XUiEquipChooseCostWeaponPopup = XLuaUiManager.Register(XLuaUi, "UiEquipChooseCostWeaponPopup")

-- 初始化弹窗基础交互和模板显示状态
function XUiEquipChooseCostWeaponPopup:OnAwake()
    self.EquipIdList = {}
    self.SelectedEquipIdMap = {}
    self:InitComponents()
end

-- 绑定关闭、全选和确认按钮的点击入口
function XUiEquipChooseCostWeaponPopup:InitComponents()
    self.BtnClose:AddEventListener(function() self:OnBtnCloseClick() end)
    self.BtnSelectAll:AddEventListener(function() self:OnBtnSelectAllClick() end)
    self.BtnComfirm:AddEventListener(function() self:OnBtnComfirmClick() end)

    self.GridWeapon.gameObject:SetActiveEx(false)
    self:InitDynamicTable()
end

-- 初始化可消耗武器动态列表，由 XDynamicTableNormal 负责滚动复用 GridWeapon
function XUiEquipChooseCostWeaponPopup:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelWeapon)
    self.DynamicTable:SetProxy(XUiGridEquip, self)
    self.DynamicTable:SetDelegate(self)
end

-- 接收业务数据后刷新可消耗武器列表
---@param equipIdList number[] 可消耗武器装备 Id 列表
---@param selectedEquipIdMap table<number, boolean>|nil 已选武器字典
---@param maxSelectCount number 最大可选数量（=共鸣技能数量）
---@param confirmCb fun(selectedEquipIdMap:table<number, boolean>)|nil 确认回调
function XUiEquipChooseCostWeaponPopup:OnStart(equipIdList, selectedEquipIdMap, maxSelectCount, confirmCb)
    self.EquipIdList = equipIdList or {}
    self.SelectedEquipIdMap = XTool.Clone(selectedEquipIdMap) or {}
    self.MaxSelectCount = maxSelectCount or 0
    self.ConfirmCb = confirmCb
    self:Refresh()
end

-- 刷新武器列表、选中状态和数量显示
function XUiEquipChooseCostWeaponPopup:Refresh()
    self:SortEquipIdList()
    local equipIdList = self.EquipIdList
    self.DynamicTable:SetDataSource(equipIdList)
    self.DynamicTable:ReloadDataASync(#equipIdList > 0 and 1 or -1)
    self:RefreshChooseCount()
end

function XUiEquipChooseCostWeaponPopup:SortEquipIdList()
    local selected, unselected = {}, {}
    for _, equipId in ipairs(self.EquipIdList) do
        if self:IsEquipSelected(equipId) then
            selected[#selected + 1] = equipId
        else
            unselected[#unselected + 1] = equipId
        end
    end
    for i = 1, #unselected do
        selected[#selected + 1] = unselected[i]
    end
    self.EquipIdList = selected
end

-- 动态列表回调：初始化、刷新和点击单个武器格子
---@param event number 动态列表事件
---@param index number 数据下标
---@param grid XUiGridEquip 武器装备格子
function XUiEquipChooseCostWeaponPopup:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:InitRootUi(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local equipId = self.EquipIdList[index]
        grid:Refresh(equipId)
        local isSelected = self:IsEquipSelected(equipId)
        grid:SetSelected(isSelected)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local equipId = self.EquipIdList[index]
        self:OnGridWeaponClick(equipId)
    end
end

-- 判断指定武器是否被选为本次消耗
---@param equipId number 武器装备 Id
---@return boolean 是否选中
function XUiEquipChooseCostWeaponPopup:IsEquipSelected(equipId)
    return self.SelectedEquipIdMap[equipId] == true
end

-- 点击武器格子时切换本弹窗内的选中状态（受 MaxSelectCount 限制）
---@param equipId number 武器装备 Id
function XUiEquipChooseCostWeaponPopup:OnGridWeaponClick(equipId)
    local isSelected = self:IsEquipSelected(equipId)
    if isSelected then
        self.SelectedEquipIdMap[equipId] = nil
    else
        -- 超过最大可选数量（共鸣技能数）时不允许再选
        if self.MaxSelectCount > 0 and self:GetSelectedEquipCount() >= self.MaxSelectCount then
            --XUiManager.TipMsg(CS.XTextManager.GetText("EquipWeaponOneClickMaterialNotEnough"))
            return
        end
        self.SelectedEquipIdMap[equipId] = true
    end

    self:RefreshGridSelectedState()
    self:RefreshChooseCount()
end

-- 刷新所有武器格子的选中表现
function XUiEquipChooseCostWeaponPopup:RefreshGridSelectedState()
    local grids = self.DynamicTable:GetGrids()
    for index, grid in pairs(grids) do
        local equipId = self.EquipIdList[index]
        local isSelected = self:IsEquipSelected(equipId)
        grid:SetSelected(isSelected)
    end
end

-- 刷新已选择武器数量显示（x/y，y = 最大可选数量 = 共鸣技能数）
function XUiEquipChooseCostWeaponPopup:RefreshChooseCount()
    local selectedCount = self:GetSelectedEquipCount()
    local maxCount = self.MaxSelectCount
    self.TxtChoosesNum.text = string.format("%d/%d", selectedCount, maxCount)

    local isAllSelected = maxCount > 0 and selectedCount >= maxCount
    self.BtnSelectAll:SetButtonState(isAllSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

-- 统计当前候选列表中的已选武器数量
---@return number 已选择数量
function XUiEquipChooseCostWeaponPopup:GetSelectedEquipCount()
    local count = 0
    for _, equipId in ipairs(self.EquipIdList) do
        if self:IsEquipSelected(equipId) then
            count = count + 1
        end
    end

    return count
end

-- 点击全选按钮：选满 MaxSelectCount 个（共鸣技能数），或全部取消
function XUiEquipChooseCostWeaponPopup:OnBtnSelectAllClick()
    local maxCount = self.MaxSelectCount
    local isSelectAll = maxCount > 0 and self:GetSelectedEquipCount() < maxCount
    self.SelectedEquipIdMap = {}
    if isSelectAll then
        local selected = 0
        for _, equipId in ipairs(self.EquipIdList) do
            if selected >= maxCount then
                break
            end
            self.SelectedEquipIdMap[equipId] = true
            selected = selected + 1
        end
    end

    self:RefreshGridSelectedState()
    self:RefreshChooseCount()
end

-- 点击确认按钮，回传只包含已选武器的字典并关闭弹窗
function XUiEquipChooseCostWeaponPopup:OnBtnComfirmClick()
    if self.ConfirmCb then
        self.ConfirmCb(self:BuildConfirmSelectedEquipIdMap())
    end
    self:Close()
end

-- 构建回传给父面板的已选武器字典，未选武器不写入以便父面板判断空表
---@return table<number, boolean> 已选武器字典
function XUiEquipChooseCostWeaponPopup:BuildConfirmSelectedEquipIdMap()
    local selectedEquipIdMap = {}
    for _, equipId in ipairs(self.EquipIdList) do
        if self:IsEquipSelected(equipId) then
            selectedEquipIdMap[equipId] = true
        end
    end

    return selectedEquipIdMap
end

-- 点击关闭按钮关闭弹窗
function XUiEquipChooseCostWeaponPopup:OnBtnCloseClick()
    self:Close()
end

return XUiEquipChooseCostWeaponPopup
