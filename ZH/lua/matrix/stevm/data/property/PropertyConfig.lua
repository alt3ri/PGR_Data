local PropertyBase = require('STEVM/Data/Property/PropertyBase')

--- 只读配置表行引用。
--- 持有一个不可变的配置 table，不参与事务 journal（Snapshot/Restore 均为 no-op）。
--- 使用方式：vm:ReadProperty(entityId, fieldName) 拿到本对象后调用 :GetConfig()，
--- 再按约定的配置表类型访问具体字段（框架不做类型检查，约定由 FieldNameType 注释保证）。
---@class PropertyConfig : PropertyBase
---@field private _ConfigRef table 配置表行（构造后不可变）
local PropertyConfig = XClass(PropertyBase, 'PropertyConfig')

---@param configRef table 配置表行，不得为 nil
function PropertyConfig:Ctor(ownScopeId, ownEnv, configRef)
    self._ConfigRef = configRef
end

--- 取配置表行。
---@return table
function PropertyConfig:GetConfig()
    return self._ConfigRef
end

--- 统一 Property 接口：GetFinalVal 返回配置表行。
---@return table
function PropertyConfig:GetFinalVal()
    return self._ConfigRef
end

--- 常量不进 journal，Snapshot 返回 nil。
function PropertyConfig:Snapshot()
    return nil
end

--- 常量不需要还原。
function PropertyConfig:Restore(snap)
end

return PropertyConfig
