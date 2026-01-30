---@class XItemRestrictAgency : XAgency
---@field private _Model XItemRestrictModel
local XItemRestrictAgency = XClass(XAgency, "XItemRestrictAgency")

-------------------------------------------------------
-- Init
-------------------------------------------------------

function XItemRestrictAgency:OnInit()
end

function XItemRestrictAgency:InitRpc()
    -- 全量数据
    XRpc.NotifyItemRestrictLoginData        = handler(self, self.OnNotifyItemRestrictLoginData)
    -- 新活动（单条完整数据）
    XRpc.NotifyItemRestrictActivityData     = handler(self, self.OnNotifyItemRestrictActivityData)
    -- 增量道具数量变更
    XRpc.NotifyItemRestrictChange           = handler(self, self.OnNotifyItemRestrictChange)
    -- 配置变更（List）
    XRpc.NotifyItemRestrictConfigUpdate     = handler(self, self.OnNotifyItemRestrictConfigUpdate)
end

function XItemRestrictAgency:InitEvent()
end

-------------------------------------------------------
-- RPC 回调
-------------------------------------------------------

-- 登录：List<ItemRestrictData>
function XItemRestrictAgency:OnNotifyItemRestrictLoginData(data)
    if not data or not data.Data then return end
    self._Model:InitData(data.Data)
end

-- 新活动：ItemRestrictData（单条）
function XItemRestrictAgency:OnNotifyItemRestrictActivityData(data)
    if not data or not data.Data then return end
    -- data.Data: ItemRestrictData
    self._Model:UpdateActivityData(data.Data)
end

-- 单条增量变更 NotifyItemRestrictChange
function XItemRestrictAgency:OnNotifyItemRestrictChange(data)
    if not data then return end
    -- data = { Type, Id, ItemId, GainItemCount }
    self._Model:UpdateChangeData(data)
end

-- 配置更新：List<ItemRestrictConfigUpdateData>
function XItemRestrictAgency:OnNotifyItemRestrictConfigUpdate(data)
    if not data or not data.Config then return end
    self._Model:UpdateConfigData(data.Config)
end

-------------------------------------------------------
-- Public API（全部按 Type）
-------------------------------------------------------

-- 获取所有数据（key = Type）
function XItemRestrictAgency:GetAllData()
    return self._Model:GetAllData()
end

-- 获取某个 Type 的数据
function XItemRestrictAgency:GetData(typeId)
    return self._Model:GetDataByType(typeId)
end

-- 获取任务组 ID 列表
function XItemRestrictAgency:GetTaskGroupIdList(typeId)
    local data = self._Model:GetDataByType(typeId)
    return data and data.TaskGroupId
end

-- 获取 ItemId 列表
function XItemRestrictAgency:GetItemIdList(typeId)
    local data = self._Model:GetDataByType(typeId)
    return data and data.ItemId
end

-- 获取 ItemMaxCount 列表
function XItemRestrictAgency:GetItemMaxCountList(typeId)
    local data = self._Model:GetDataByType(typeId)
    return data and data.ItemMaxCount
end

-- 获取 GainItemCount 列表
function XItemRestrictAgency:GetGainItemCountList(typeId)
    local data = self._Model:GetDataByType(typeId)
    return data and data.GainItemCount
end

-------------------------------------------------------
-- 判断（业务逻辑）
-------------------------------------------------------

-- 判断某 Type 下的某一索引是否达到上限
function XItemRestrictAgency:IsItemReachMaxByIndex(typeId, index)
    if not typeId or not index then
        return false
    end

    local data = self._Model:GetDataByType(typeId)
    if not data then
        return false
    end

    local maxList  = data.ItemMaxCount or {}
    local gainList = data.GainItemCount or {}

    local maxCount = maxList[index]
    if not maxCount then
        return false
    end

    local gainCount = gainList[index] or 0
    return gainCount >= maxCount
end

-- 判断该 Type 下所有 Item 是否全部达到最大上限
function XItemRestrictAgency:IsAllItemsReachMax(typeId)
    if not typeId then
        return false
    end

    local data = self._Model:GetDataByType(typeId)
    if not data then
        return false
    end

    local maxList  = data.ItemMaxCount or {}
    local gainList = data.GainItemCount or {}
    local itemIdList = data.ItemId or {}

    -- 如果没有 ItemId，按业务一般视为“未达成全部”
    if #itemIdList == 0 then
        return false
    end

    for index = 1, #itemIdList do
        local maxCount = maxList[index]
        local gainCount = gainList[index] or 0

        -- 没有 maxCount 或还未达到 maxCount => false
        if not maxCount or gainCount < maxCount then
            return false
        end
    end

    return true
end

-- 判断某 Type 下的指定 ItemId 是否达到上限
function XItemRestrictAgency:IsItemReachMaxByItemId(typeId, itemId)
    if not typeId or not itemId then
        return false
    end

    local data = self._Model:GetDataByType(typeId)
    if not data then
        return false
    end

    local itemIds = data.ItemId or {}
    for index, cfgItemId in ipairs(itemIds) do
        if cfgItemId == itemId then
            return self:IsItemReachMaxByIndex(typeId, index)
        end
    end

    return false
end

return XItemRestrictAgency
