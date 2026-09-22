--- 辅助接口，方便业务使用
---@class STEHelper
local STEHelper = {}

--region 类型接口 —— 用于继承

function STEHelper.GetClsPropertySingle()
    return require("STEVM/Data/Property/PropertySingle")
end

function STEHelper.GetClsPropertyModifiedNum()
    return require("STEVM/Data/Property/PropertyModifiedNum")
end

function STEHelper.GetClsPropertyConfig()
    return require("STEVM/Data/Property/PropertyConfig")
end

function STEHelper.GetClsEntity()
    return require("STEVM/Data/Entity")
end
--endregion

--region 实例化接口

function STEHelper.NewEnvironment(seed)
    local cls = require("STEVM/STEEnv")

    return cls.New(seed)
end

function STEHelper.NewEntity(cls, id, env, ...)
    return cls.New(id, env, ...)
end

function STEHelper.NewPropertySingle(ownScopeId, ownEnv, originVal)
    local cls = STEHelper.GetClsPropertySingle()
    
    return cls.New(ownScopeId, ownEnv, originVal)
end

function STEHelper.NewPropertyModifiedNum(ownScopeId, ownEnv, originVal, minVal, maxVal)
    local cls = STEHelper.GetClsPropertyModifiedNum()

    return cls.New(ownScopeId, ownEnv, originVal, minVal, maxVal)
end

function STEHelper.NewPropertyList(ownScopeId, ownEnv)
    local cls = require("STEVM/Data/Property/PropertyList")

    return cls.New(ownScopeId, ownEnv)
end

function STEHelper.NewPropertyDict(ownScopeId, ownEnv)
    local cls = require("STEVM/Data/Property/PropertyDict")

    return cls.New(ownScopeId, ownEnv)
end

--- 只读配置表行引用，不参与事务快照。configRef 须非 nil（构造期 bug 即暴露）。
---@param configRef table 配置表行
function STEHelper.NewPropertyConfig(ownScopeId, ownEnv, configRef)
    local cls = STEHelper.GetClsPropertyConfig()

    return cls.New(ownScopeId, ownEnv, configRef)
end
--endregion

--region 执行接口

--- 执行一次完整的单步处理
---@param atomic boolean 是否是原子事务，如果是，则执行pcall并对任何失败进行回滚
function STEHelper.RunStep(env, func, atomic, rootId, ...)
    local engine = require("STEVM/STEEngine")

    return engine.Run(env, func, atomic, rootId, ...)
end

--endregion


return STEHelper