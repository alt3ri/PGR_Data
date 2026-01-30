---@class XItemRestrictModel : XModel
local XItemRestrictModel = XClass(XModel, "XItemRestrictModel")

-------------------------------------------------------
-- Local Helper
-------------------------------------------------------

local function NormalizeData(data)
    if not data then return end

    data.ItemId        = data.ItemId        or {}
    data.ItemMaxCount  = data.ItemMaxCount  or {}
    data.TaskGroupId   = data.TaskGroupId   or {}
    data.GainItemCount = data.GainItemCount or {}

    return data
end

-- 覆盖或创建某个 Type 的整条数据
function XItemRestrictModel:ApplyFullData(data)
    NormalizeData(data)
    self.ServerPrams.ItemsByType[data.Type] = data
end

-------------------------------------------------------
-- Init
-------------------------------------------------------

function XItemRestrictModel:OnInit()
    self.ServerPrams = {
        ItemsByType = {},   -- key: Type → ItemRestrictData
    }
end

function XItemRestrictModel:ClearPrivate()
    self.ServerPrams.ItemsByType = {}
end

function XItemRestrictModel:ResetAll()
    self.ServerPrams.ItemsByType = {}
end

-------------------------------------------------------
-- RPC Update APIs (Agency 调用)
-------------------------------------------------------

-- 全量数据：List<ItemRestrictData>
function XItemRestrictModel:InitData(dataList)
    self.ServerPrams.ItemsByType = {}

    for _, data in ipairs(dataList or {}) do
        self:ApplyFullData(data)
    end
end

-- 新活动开启：单条 ItemRestrictData，覆盖某个 type
function XItemRestrictModel:UpdateActivityData(data)
    -- data: ItemRestrictData
    if not data then return end
    self:ApplyFullData(data)
end

-- 增量变更：NotifyItemRestrictChange
-- {
--     Type,
--     Id,
--     ItemId,
--     GainItemCount
-- }
function XItemRestrictModel:UpdateChangeData(change)
    if not change or not change.Type or not change.ItemId then return end

    local typeId = change.Type
    local entry = self.ServerPrams.ItemsByType[typeId]

    -- 若第一次接收到 change，该 type 没有 full data，必须创建骨架
    if not entry then
        entry = {
            Type = typeId,
            Id = change.Id,         -- 服务器仍会发 Id，保留不使用
            ItemId = {},
            ItemMaxCount = {},
            TaskGroupId = {},
            GainItemCount = {},
        }
        NormalizeData(entry)
        self.ServerPrams.ItemsByType[typeId] = entry
    end

    NormalizeData(entry)

    -- 找到 itemId 在 entry.ItemId 中的 index
    local index
    for i, itemId in ipairs(entry.ItemId) do
        if itemId == change.ItemId then
            index = i
            break
        end
    end

    if not index then
        -- 新的 ItemId，Push 一个 slot
        table.insert(entry.ItemId, change.ItemId)
        table.insert(entry.ItemMaxCount, 0)
        table.insert(entry.GainItemCount, change.GainItemCount or 0)
    else
        -- 更新获得数量
        entry.GainItemCount[index] = change.GainItemCount or 0
    end
end

-- 配置热更：List<ItemRestrictConfigUpdateData>
-- 覆盖 Type 相关的 TaskGroupId / ItemId / ItemMaxCount
function XItemRestrictModel:UpdateConfigData(configList)
    for _, cfg in ipairs(configList or {}) do
        local typeId = cfg.Type
        if typeId then
            local entry = self.ServerPrams.ItemsByType[typeId]
            if not entry then
                -- 创建最初的骨架
                entry = {
                    Type = typeId,
                    Id = cfg.Id,
                    ItemId = cfg.ItemId or {},
                    ItemMaxCount = cfg.ItemMaxCount or {},
                    TaskGroupId = cfg.TaskGroupId or {},
                    GainItemCount = {},
                }
                NormalizeData(entry)
                self.ServerPrams.ItemsByType[typeId] = entry
            else
                -- 覆盖配置相关字段（但不动 Gain 数据）
                entry.Id = cfg.Id
                entry.ItemId = cfg.ItemId or entry.ItemId
                entry.ItemMaxCount = cfg.ItemMaxCount or entry.ItemMaxCount
                entry.TaskGroupId = cfg.TaskGroupId or entry.TaskGroupId

                NormalizeData(entry)
            end
        end
    end
end

-------------------------------------------------------
-- Query APIs
-------------------------------------------------------

-- 获取所有数据（按 Type）
function XItemRestrictModel:GetAllData()
    return self.ServerPrams.ItemsByType
end

-- 获取单个 Type
function XItemRestrictModel:GetDataByType(typeId)
    local data = self.ServerPrams.ItemsByType[typeId]
    NormalizeData(data)
    return data
end

return XItemRestrictModel
