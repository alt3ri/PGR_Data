local XLuckyTenant2Bond = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Bond")

---@class XLuckyTenant2BondManager
local XLuckyTenant2BondManager = XClass(nil, "XLuckyTenant2BondManager")

---@param bondConfigs XTableLuckyTenant2Bond[] 羁绊配置列表
function XLuckyTenant2BondManager:Ctor(bondConfigs)
    ---@type table<number, XLuckyTenant2Bond>
    self._Bonds = {}
    self._IsDirty = true
    ---@type function|nil 等级变化回调函数 (bondId, oldLevel, newLevel)
    self._OnLevelChangedCallback = nil

    -- 初始化所有羁绊
    if bondConfigs then
        for _, config in pairs(bondConfigs) do
            local bond = XLuckyTenant2Bond.New(config.BondId, config)
            self._Bonds[config.BondId] = bond
        end
    end
end

---@param bondId number
---@return XLuckyTenant2Bond
function XLuckyTenant2BondManager:GetBond(bondId)
    return self._Bonds[bondId]
end

---@return XLuckyTenant2Bond[]
function XLuckyTenant2BondManager:GetAllBonds()
    local result = {}
    for _, bond in pairs(self._Bonds) do
        table.insert(result, bond)
    end
    return result
end

---设置等级变化回调
---@param callback function 回调函数 (bondId, oldLevel, newLevel)
function XLuckyTenant2BondManager:SetOnLevelChangedCallback(callback)
    self._OnLevelChangedCallback = callback
end

---@param bag XLuckyTenant2Bag
---@param model XLuckyTenant2Model|nil 配置模型（可选，用于获取SkillRequire数据）
function XLuckyTenant2BondManager:RefreshBondLevels(bag, model)
    -- 刷新所有羁绊的等级
    local bondCount = 0
    for _ in pairs(self._Bonds) do
        bondCount = bondCount + 1
    end

    local hasChange = false
    for _, bond in pairs(self._Bonds) do
        local oldLevel = bond:GetLevel()
        local newLevel = bond:CalculateLevel(bag, model)

        if oldLevel ~= newLevel then
            bond:SetLevel(newLevel)
            hasChange = true

            -- 调用回调通知等级变化
            if self._OnLevelChangedCallback then
                self._OnLevelChangedCallback(bond:GetBondId(), oldLevel, newLevel)
            end
        end
    end
    if hasChange then
        self._IsDirty = true
    end

    return hasChange
end

---@return XLuckyTenant2Bond[] 按品质降序排序
function XLuckyTenant2BondManager:GetBondsSortedByQuality()
    local bonds = self:GetAllBonds()
    -- 按生效的最高羁绊品质降序排序
    table.sort(bonds, function(a, b)
        return a:GetLevel() > b:GetLevel()
    end)
    return bonds
end

---@param bondId number
---@return number[] 该羁绊关联的棋子ID列表
function XLuckyTenant2BondManager:GetBondRelatedChessIds(bondId)
    local bond = self:GetBond(bondId)
    if bond then
        return bond:GetRelatedChessIds()
    end
    return {}
end

function XLuckyTenant2BondManager:IsDirty()
    return self._IsDirty
end

function XLuckyTenant2BondManager:SetDirty(dirty)
    self._IsDirty = dirty
end

return XLuckyTenant2BondManager
