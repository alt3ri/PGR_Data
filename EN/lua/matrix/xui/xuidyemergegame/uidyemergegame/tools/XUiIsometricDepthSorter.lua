--- 等距投影视图的 SiblingIndex 排序工具类
--- 与游戏逻辑零耦合，depthKey 的含义由调用方决定。
--- depthKey 越大 = 视觉越靠后（越远离观察者）= SiblingIndex 越低（先渲染，显示在后）
--- subKey 用于同 depthKey 时的二级排序：subKey 越大 SiblingIndex 越高（渲染越靠前）
---@class XUiIsometricDepthSorter
local XUiIsometricDepthSorter = XClass(nil, "XUiIsometricDepthSorter")

function XUiIsometricDepthSorter:Ctor()
    --- 有序条目列表，每项为 { transform=transform, key=key, subKey=subKey }
    ---@type table[]
    self._Items = {}
    --- transform -> item 快速查找，支持 O(1) SetKey / Remove
    ---@type table
    self._TransformToItem = {}
    --- 预创建排序比较器，避免每次 Sort 产生闭包 GC
    self._Comparator = function(a, b)
        if a.key ~= b.key then
            return a.key > b.key
        end
        return a.subKey < b.subKey
    end
end

--- 注册一个 transform，给定初始 depthKey 和 subKey（不立即排序）
---@param transform userdata
---@param key number
---@param subKey number|nil 同 depthKey 时的二级排序键，默认 0（地板=0，方块=1）
function XUiIsometricDepthSorter:Add(transform, key, subKey)
    local item = { transform = transform, key = key, subKey = subKey or 0 }
    table.insert(self._Items, item)
    self._TransformToItem[transform] = item
end

--- 注销 transform（不立即排序）
---@param transform userdata
function XUiIsometricDepthSorter:Remove(transform)
    local item = self._TransformToItem[transform]
    if not item then return end
    self._TransformToItem[transform] = nil
    for i, v in ipairs(self._Items) do
        if v == item then
            table.remove(self._Items, i)
            break
        end
    end
end

--- 更新已注册 transform 的 depthKey（不立即排序）
---@param transform userdata
---@param key number
function XUiIsometricDepthSorter:SetKey(transform, key)
    local item = self._TransformToItem[transform]
    if item then
        item.key = key
    end
end

--- 已注册则更新 depthKey，未注册则新增（不立即排序）
---@param transform userdata
---@param key number
---@param subKey number|nil
function XUiIsometricDepthSorter:AddOrUpdate(transform, key, subKey)
    local item = self._TransformToItem[transform]
    if item then
        item.key = key
        if subKey ~= nil then item.subKey = subKey end
    else
        self:Add(transform, key, subKey)
    end
end

--- 返回当前已注册的条目数量
---@return number
function XUiIsometricDepthSorter:GetCount()
    return #self._Items
end

--- 按 depthKey 降序、subKey 升序排序，并逐个写入 SetSiblingIndex
--- depthKey 越大 SiblingIndex 越低（先渲染，显示在后）
--- 同 depthKey 时 subKey 越大 SiblingIndex 越高（渲染越靠前，方块 subKey=1 覆盖地板 subKey=0）
function XUiIsometricDepthSorter:Sort()
    table.sort(self._Items, self._Comparator)
    for i, item in ipairs(self._Items) do
        item.transform:SetSiblingIndex(i - 1)
    end
end

--- 清空所有已注册条目（重新布局时使用）
function XUiIsometricDepthSorter:Clear()
    self._Items = {}
    self._TransformToItem = {}
end

--- 注册并立即排序（便捷接口）
---@param transform userdata
---@param key number
---@param subKey number|nil 同 depthKey 时的二级排序键，默认 0
function XUiIsometricDepthSorter:AddAndSort(transform, key, subKey)
    self:Add(transform, key, subKey)
    self:Sort()
end

--- 注销并立即排序（便捷接口）
---@param transform userdata
function XUiIsometricDepthSorter:RemoveAndSort(transform)
    self:Remove(transform)
    self:Sort()
end

return XUiIsometricDepthSorter
