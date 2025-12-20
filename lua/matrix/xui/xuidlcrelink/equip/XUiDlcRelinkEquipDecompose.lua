local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XUiGridDlcRelinkEquipment = require("XUi/XUiDlcRelink/Equip/Grid/XUiGridDlcRelinkEquipment")
local XUiPanelDlcRelinkEquipFilter = require("XUi/XUiDlcRelink/Equip/Panel/XUiPanelDlcRelinkEquipFilter")
---@class XUiDlcRelinkEquipDecompose : XLuaUi
---@field private _Control XDlcRelinkControl
---@field PanelTab XUiButtonGroup
local XUiDlcRelinkEquipDecompose = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkEquipDecompose")

function XUiDlcRelinkEquipDecompose:OnAwake()
    self.GridEquipment.gameObject:SetActiveEx(false)
    self.BtnTab.gameObject:SetActiveEx(false)
    self.GridReward.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()

    ---@type XUiComponent.XUiButton[]
    self.EquipBtnTabList = {}
    --- 装备筛选数据缓存
    ---@type XDlcRelinkEquipFilterCache
    self.EquipFilterCache = {}
    ---@type XUiGridCommon[]
    self.RewardGridList = {}

    local itemIds = { XDataCenter.ItemManager.ItemId.DlcRelinkGameplayCoin }
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe(itemIds, self.PanelSpecialTool, self, nil, function(data, index)
        local itemId = itemIds[index]
        XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", itemId)
    end)
end

function XUiDlcRelinkEquipDecompose:OnStart()
    -- 设置自动关闭
    self:SetAutoCloseInfo(self._Control:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)

    self.EquipOccupationDefaultIndex = 1 -- 进入时默认选择的职业Tab
    self.CurSelectEquipOccupationIndex = 0

    ---@type table<number, boolean>
    self.SelectedEquipUidSet = {} -- 当前选中的装备uid集合

    self:InitPanelTab()
    self:InitDynamicTable()
end

function XUiDlcRelinkEquipDecompose:OnEnable()
    self.Super.OnEnable(self)
    self:RefreshEquipCapacity()
    self.PanelTab:SelectIndex(self.EquipOccupationDefaultIndex)
end

function XUiDlcRelinkEquipDecompose:OnDisable()
    self.Super.OnDisable(self)
    self.EquipFilterCache = {}
    self:ClearSelected()
end

--region 装备背包

function XUiDlcRelinkEquipDecompose:InitPanelTab()
    self.EquipBtnTabList = {}
    local tabDescList = self._Control:GetClientConfigParams("EquipTabsDesc")
    for _, tabDesc in ipairs(tabDescList) do
        ---@type XUiComponent.XUiButton
        local btnTab = XUiHelper.Instantiate(self.BtnTab, self.PanelTab.transform)
        btnTab.gameObject:SetActiveEx(true)
        btnTab:SetNameByGroup(0, tabDesc)
        table.insert(self.EquipBtnTabList, btnTab)
    end
    self.PanelTab:Init(self.EquipBtnTabList, handler(self, self.OnEquipBtnTabClick))
end

function XUiDlcRelinkEquipDecompose:OnEquipBtnTabClick(index)
    if self.CurSelectEquipOccupationIndex == index then
        return
    end
    self.CurSelectEquipOccupationIndex = index
    -- 重置装备筛选缓存
    self.EquipFilterCache = {}
    self:SetupDynamicTable()
    self:RefreshSelectedCount()
    self:RefreshPanelFilter()
    self:RefreshReward()
end

function XUiDlcRelinkEquipDecompose:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    self.DynamicTable = XDynamicTableNormal.New(self.PanelEquipScroll)
    self.DynamicTable:SetProxy(XUiGridDlcRelinkEquipment, self, handler(self, self.OnEquipItemCallBack), handler(self, self.OnEquipItemRemoveCallBack))
    self.DynamicTable:SetDelegate(self)
end

function XUiDlcRelinkEquipDecompose:SetupDynamicTable()
    self:ClearSelected()
    -- 获取当前页签下的装备列表
    self.EquipUidList = self._Control:GetEquipUidListByOccupationType(self.CurSelectEquipOccupationIndex, { Context = "Decompose" })
    local isEmpty = XTool.IsTableEmpty(self.EquipUidList)
    self.None.gameObject:SetActiveEx(isEmpty)
    if isEmpty then
        self.DynamicTable:Clear()
        return
    end

    self:SelectFilterEquip()
    self.DynamicTable:SetDataSource(self.EquipUidList)
    self.DynamicTable:ReloadDataSync()
end

-- 选择符合筛选条件的装备
function XUiDlcRelinkEquipDecompose:SelectFilterEquip()
    if not self:CheckFilterCache() then
        return
    end

    local filterEquipUidList = self._Control:GetEquipUidListByOccupationType(self.CurSelectEquipOccupationIndex, { Context = "Decompose", Filter = self.EquipFilterCache })
    for _, equipUid in ipairs(filterEquipUidList) do
        if self:CanSelect(equipUid) then
            self:SetSelected(equipUid, true)
        end
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipDecompose:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local equipUid = self.EquipUidList[index]
        grid:Refresh(equipUid)
        grid:SetHead(self._Control:GetEquipWearCharacterId(equipUid))
        -- 按当前选择集刷新选中态（显示减号）
        grid:SetSelect(self:IsSelected(equipUid), true)
    end
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipDecompose:OnEquipItemCallBack(grid)
    local equipUid = grid:GetEquipUid()
    if not XTool.IsNumberValid(equipUid) then
        return
    end

    -- 始终先展示右侧气泡
    self:ShowEquipBubble(equipUid, grid.Transform)
    -- 已选中：仅展示气泡，不取消选择
    if self:IsSelected(equipUid) then
        return
    end
    -- 未选中：检查选择条件，满足后选中
    self:CheckSelectCondition(equipUid, function()
        -- 可选：设置为选中并刷新显示
        self:SetSelected(equipUid, true)
        grid:SetSelect(true, true)
        self:RefreshSelectedCount()
        self:RefreshReward()
    end)
end

---@param grid XUiGridDlcRelinkEquipment
function XUiDlcRelinkEquipDecompose:OnEquipItemRemoveCallBack(grid)
    local equipUid = grid:GetEquipUid()
    if not XTool.IsNumberValid(equipUid) then
        return
    end

    if not self:IsSelected(equipUid) then
        return
    end
    self:SetSelected(equipUid, false)
    grid:SetSelect(false)
    self:RefreshSelectedCount()
    self:RefreshReward()
end

-- 右侧装备气泡展示
---@param targetTransform UnityEngine.RectTransform
function XUiDlcRelinkEquipDecompose:ShowEquipBubble(equipUid, targetTransform)
    XLuaUiManager.Open("UiDlcRelinkBubbleEquipDetail", equipUid, targetTransform)
end

-- 刷新装备容量
function XUiDlcRelinkEquipDecompose:RefreshEquipCapacity()
    local curCount, maxCount = self._Control:GetEquipBagCurCountAndMaxCount()
    local isFull = curCount >= maxCount
    local desc = self._Control:GetClientConfig("EquipCapacityDesc", isFull and 2 or 1)
    self.TxtTips.text = XUiHelper.FormatText(desc, curCount, maxCount)
end

-- 刷新已选择数量
function XUiDlcRelinkEquipDecompose:RefreshSelectedCount()
    local count = table.nums(self.SelectedEquipUidSet)
    local desc = self._Control:GetClientConfig("EquipDecomposeSelectedCountDesc", count > 0 and 2 or 1)
    self.Txt.text = string.format(desc, count)
    self.BtnBreak:SetDisable(count <= 0)
end

--endregion

--region 多选工具方法

-- 检查选择装备条件
function XUiDlcRelinkEquipDecompose:CheckSelectCondition(equipUid, callback)
    -- 锁定
    local isLocked = self._Control:GetEquipIsLockedByEquipUid(equipUid)
    if isLocked then
        self._Control:OpenCommonTipText("EquipDecomposeLockTips")
        return
    end

    local wearCharacterId = self._Control:GetEquipWearCharacterId(equipUid)
    local isPreset = self._Control:CheckEquipIsPresetByEquipUid(equipUid)
    local hasWearer = XTool.IsNumberValid(wearCharacterId)

    -- 有佩戴者时处理（同时在预设中或仅佩戴中）
    if hasWearer then
        if isPreset then
            self:OpenWearTipDialog(wearCharacterId, function()
                self:OpenPresetTipDialog(callback)
            end)
        else
            self:OpenWearTipDialog(wearCharacterId, callback)
        end
        return
    end

    -- 仅预设中
    if isPreset then
        self:OpenPresetTipDialog(callback)
        return
    end

    if callback then
        callback()
    end
end

-- 打开佩戴中提示弹窗
---@param wearCharacterId number 佩戴角色Id
---@param callback function 确认后的回调
function XUiDlcRelinkEquipDecompose:OpenWearTipDialog(wearCharacterId, callback)
    local characterName = XMVCA.XCharacter:GetCharacterName(wearCharacterId)
    local title = self._Control:GetClientConfig("TipTitle")
    local data = self._Control:GetClientConfigParams("WearEquipDecomposeTipContent")
    local content = string.format(data[1] or "", characterName)
    local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "WearEquipDecomposeTip" }
    self._Control:OpenCommonTipDialog(title, content, nil, callback, extraData)
end

-- 打开预设中提示弹窗
---@param callback function 确认后的回调
function XUiDlcRelinkEquipDecompose:OpenPresetTipDialog(callback)
    local title = self._Control:GetClientConfig("TipTitle")
    local data = self._Control:GetClientConfigParams("PresetEquipDecomposeTipContent")
    local content = data[1] or ""
    local extraData = { ConfirmText = data[2] or "", CancelText = data[3] or "", TipsKey = "PresetEquipDecomposeTip" }
    self._Control:OpenCommonTipDialog(title, content, nil, callback, extraData)
end

-- 检查装备是否可选择
---@field equipUid number 装备uid
---@return boolean, string 是否可选 及不可选原因
function XUiDlcRelinkEquipDecompose:CanSelect(equipUid)
    -- 锁定
    local isLocked = self._Control:GetEquipIsLockedByEquipUid(equipUid)
    if isLocked then
        return false, self._Control:GetClientConfig("EquipDecomposeLockTips")
    end
    -- 佩戴中
    local wearerId = self._Control:GetEquipWearCharacterId(equipUid)
    if XTool.IsNumberValid(wearerId) then
        return false, self._Control:GetClientConfig("EquipDecomposeWearTips")
    end
    -- 预设中
    local isPreset = self._Control:CheckEquipIsPresetByEquipUid(equipUid)
    if isPreset then
        return false, self._Control:GetClientConfig("EquipDecomposePresetTips")
    end
    return true
end

-- 是否选中
function XUiDlcRelinkEquipDecompose:IsSelected(equipUid)
    return self.SelectedEquipUidSet and self.SelectedEquipUidSet[equipUid] == true
end

-- 设置选中/取消
function XUiDlcRelinkEquipDecompose:SetSelected(equipUid, isSelect)
    if not self.SelectedEquipUidSet then
        self.SelectedEquipUidSet = {}
    end

    if isSelect then
        self.SelectedEquipUidSet[equipUid] = true
    else
        self.SelectedEquipUidSet[equipUid] = nil
    end
end

-- 切换选中状态，返回是否选中
function XUiDlcRelinkEquipDecompose:ToggleSelected(equipUid)
    local newState = not self:IsSelected(equipUid)
    self:SetSelected(equipUid, newState)
    return newState
end

-- 清空选择
function XUiDlcRelinkEquipDecompose:ClearSelected()
    self.SelectedEquipUidSet = {}
end

--endregion

--region 装备筛选

function XUiDlcRelinkEquipDecompose:RefreshPanelFilter()
    if not self.EquipFilterNode then
        ---@type XUiPanelDlcRelinkEquipFilter
        self.EquipFilterNode = XUiPanelDlcRelinkEquipFilter.New(self.PanelFilter, self, handler(self, self.OnEquipFilterChange))
        self.EquipFilterNode:Open()
    end
    local equipMainFactorIds = self._Control:GetEquipMainFactorIds(self.EquipUidList)
    self.EquipFilterNode:Refresh(equipMainFactorIds, self.EquipFilterCache)
end

function XUiDlcRelinkEquipDecompose:OnEquipFilterChange()
    self:SetupDynamicTable()
    self:RefreshSelectedCount()
    self:RefreshReward()
end

-- 检查当前筛选条件是否有生效
function XUiDlcRelinkEquipDecompose:CheckFilterCache()
    if XTool.IsTableEmpty(self.EquipFilterCache) then
        return false
    end

    if XTool.IsNumberValid(self.EquipFilterCache.ReformedType)
        or XTool.IsNumberValid(self.EquipFilterCache.FactorRemovedType)
        or XTool.IsNumberValid(self.EquipFilterCache.EquipType)
        or not XTool.IsTableEmpty(self.EquipFilterCache.FactorIds) then
        return true
    end

    return false
end

--endregion

--region 分解获得

function XUiDlcRelinkEquipDecompose:RefreshReward()
    local equipUidList = {}
    for equipUid, _ in pairs(self.SelectedEquipUidSet) do
        table.insert(equipUidList, equipUid)
    end
    local rewardGoodsList = self._Control:GetBreakRewardGoods(equipUidList)
    local isEmpty = XTool.IsTableEmpty(rewardGoodsList)
    self.PanelReward.gameObject:SetActiveEx(not isEmpty)
    if isEmpty then
        return
    end

    for index, rewardGood in ipairs(rewardGoodsList) do
        local grid = self.RewardGridList[index]
        if not grid then
            local go = XUiHelper.Instantiate(self.GridReward, self.PanelReward)
            grid = XUiGridCommon.New(self, go)
            self.RewardGridList[index] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(rewardGood)
        grid:SetProxyClickFunc(function()
            XLuaUiManager.Open("UiDlcRelinkPopupItemDetail", grid.TemplateId)
        end)
    end

    -- 隐藏多余的奖励格子
    for i = #rewardGoodsList + 1, #self.RewardGridList do
        self.RewardGridList[i].GameObject:SetActiveEx(false)
    end
end

--endregion

function XUiDlcRelinkEquipDecompose:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnBreak, self.OnBtnBreakClick)
end

function XUiDlcRelinkEquipDecompose:OnBtnBackClick()
    self:Close()
end

function XUiDlcRelinkEquipDecompose:OnBtnBreakClick()
    local selectedCount = table.nums(self.SelectedEquipUidSet)
    if selectedCount <= 0 then
        self._Control:OpenCommonTipText("EquipDecomposeNoSelectTips")
        return
    end

    if not self._Control:AbleSyncDataToMatchServer() then
        return
    end

    local equipUidList = {}
    for equipUid, _ in pairs(self.SelectedEquipUidSet) do
        table.insert(equipUidList, equipUid)
    end
    self._Control:RequestEquipBreak(equipUidList, function(rewardList)
        self:SetupDynamicTable()
        self:RefreshSelectedCount()
        self:RefreshReward()

        if XTool.IsTableEmpty(rewardList) then
            return
        end
        local rewardGoodsList = {}
        for _, reward in ipairs(rewardList) do
            if not XTool.IsTableEmpty(reward.RewardGoods) then
                table.insert(rewardGoodsList, reward.RewardGoods)
            end
        end
        XLuaUiManager.Open("UiDlcRelinkPopupEquipDecomposeResult", rewardGoodsList)
    end)
end

return XUiDlcRelinkEquipDecompose
