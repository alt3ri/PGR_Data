

---@class XUiPanelDownloadTips
---@field LaunchDlcManager XLaunchDlcManager
local XUiPanelDownloadTips = {}

function XUiPanelDownloadTips.New(gameObj, parentProxy)
    local class = {}
    setmetatable(class, { __index = XUiPanelDownloadTips })
    class:Init(gameObj, parentProxy)
    return class
end

function XUiPanelDownloadTips:Init(gameObj, parentProxy)
    self.GameObject = gameObj
    self.Parent = parentProxy
    self.LaunchDlcManager = require("XLaunchDlcManager")
    self:InitDynamicTable()
    self:RefreshDynamicTable()
end

function XUiPanelDownloadTips:InitDynamicTable()
    local XGridDownloadTipSubpackage = require("XLaunchUi/XGridDownloadTipSubpackage")
    local XDynamicTableNormal = require("XLaunchUi/XDynamicTableNormalLaunch")
    self.DynamicTable = XDynamicTableNormal.New(self.Parent.SubpackageList)
    self.DynamicTable:SetProxy(XGridDownloadTipSubpackage, self)
    self.DynamicTable:SetDelegate(self)
end

function XUiPanelDownloadTips:IsAllGridDownloadFlag()
    for k, grid in pairs(self.DynamicTable:GetGrids()) do
        if not grid:GetDownFlag() then
            return false
        end
    end
    return true
end

function XUiPanelDownloadTips:SetAllGridDownloadFlag(flag)
    for k, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetDownFlag(flag)
        grid:RefreshWithCb()
    end
end

function XUiPanelDownloadTips:SetAllGridClickLock(flag)
    for k, grid in pairs(self.DynamicTable:GetGrids()) do
        grid:SetClickLock(flag)
    end
end

function XUiPanelDownloadTips:GetRemoveResIdList()
    local res = {}
    --todo hyx self.DynamicTable:GetGrids() 只能获取到已经刷新的格子，如果是动态列表，可能存在未创建的格子，这里的收集可能会有问题（所有这个接口都可能存在问题）
    for k, grid in pairs(self.DynamicTable:GetGrids()) do
        -- print("SP/DN GetRemoveResIdList ", k, grid, grid:GetDownFlag())
        if not grid:GetDownFlag() then
            local resIdlist = grid.ResIdList
            for i = 1, #resIdlist do
                local resId = resIdlist[i]
                table.insert(res, resId)
            end
        end
    end
    return res
end

function XUiPanelDownloadTips:GetRemoveSize()
    local resSize = 0
    for k, grid in pairs(self.DynamicTable:GetGrids()) do
        if not grid:GetDownFlag() then
            resSize = resSize + grid:GetTotalSize()
        end
    end
    return resSize
end

function XUiPanelDownloadTips:RegisterGridClickCb(cb)
    self.GridClickCb = cb
end

function XUiPanelDownloadTips:RefreshDynamicTable()
    local t = {}

    local subPackageMap = {}
    local subPackageStorage = CS.XLaunchManager.SubPackageTab
    if subPackageStorage == nil then
        error("SubPackageTab is nil")
        return
    end
    local spPairs = subPackageStorage.keyValuePairs
    for i = 0, spPairs.Length - 1 do
        local kv = spPairs[i]
        subPackageMap[kv.Key] = kv.Value
    end

    -- 遍历 LaunchRemoveSelectSubPackageIds 的所有键值对
    local storage = CS.XLaunchManager.LaunchRemoveSelectSubPackageIds
    if storage == nil then
        error("LaunchRemoveSelectSubPackageIds is nil")
        return
    end

    -- keyValuePairs 是 List<KeyValueData>
    local kPairs = storage.keyValuePairs
    for i = 0, kPairs.Length - 1 do
        local kv = kPairs[i]
        local k = kv.Key
        local subpackageIdStr = kv.Value

        -- 通过 XBuiltinText 解析真实key
        local realKey = CS.XApplication.GetText(k)
        if not realKey or realKey == "" then
            error("无效 realKey, key = " .. tostring(k))
        end

        local name, desc = string.match(realKey, "([^|]+)|([^|]+)")
        if not name or not desc then
            error("realKey 格式错误: " .. tostring(realKey))
        end

        local combinedResIds = {}
        local foundAny = false
        for subId in string.gmatch(tostring(subpackageIdStr), "[^|]+") do
            local resIdsStr = subPackageMap[subId]
            if resIdsStr then
                self.LaunchDlcManager.SplitResIds(resIdsStr, false, combinedResIds, ",")
                foundAny = true
            else
                print("XUiPanelDownloadTips:RefreshDynamicTable subpackageId not found: " .. tostring(subId))
            end
        end

        if foundAny then
            table.insert(t, {
                Name = name,
                Desc = desc,
                ResIdList = combinedResIds
            })
        end
    end

    self.DynamicTable:SetDataSource(t)
    self.DynamicTable:ReloadDataSync()
end

function XUiPanelDownloadTips:OnDynamicTableEvent(event, index, grid)
    if event == self.DynamicTable.DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        local data = self.DynamicTable.DataSource[index]
        grid:Init(data)
        grid:RegisterClickCb(function ()
            if self.GridClickCb then
                self.GridClickCb(self:GetRemoveSize())
            end
        end)
    elseif event == self.DynamicTable.DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh()
    end
end

function XUiPanelDownloadTips:SetActiveEx(flag)
    self.GameObject:SetActiveEx(flag)
end

function XUiPanelDownloadTips:OnDestroy()
    if self.DynamicTable then
        self.DynamicTable:Clear()
        self.DynamicTable = nil
    end
    self.GridClickCb = nil
    self.Parent = nil
end

return XUiPanelDownloadTips