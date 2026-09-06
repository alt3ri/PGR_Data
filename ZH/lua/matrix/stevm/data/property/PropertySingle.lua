local PropertyBase = require('STEVM/Data/Property/PropertyBase')

--- 基础数值属性
---@class PropertySingle : PropertyBase
---@field _OriginVal number 原始值
local PropertySingle = XClass(PropertyBase, 'PropertySingle')

---@param originVal number|nil 原始值,缺省 0
function PropertySingle:Ctor(ownScopeId, ownEnv, originVal)
    -- 注:父类 Ctor 已由 XClass.New 自动调用(父先子后),此处只补本层字段。
    -- 防御判空(规范#20):缺省值 0;非 number 也兜底 0。
    if type(originVal) == 'number' then
        self._OriginVal = originVal
    else
        self._OriginVal = 0
    end
end

--- 取原始值。
---@return number
function PropertySingle:GetOriginVal()
    return self._OriginVal
end

--- 设置原始值(写接口,允许;读接口才需纯净)。
---@param v number
function PropertySingle:SetOriginVal(v)
    self:_BeforeWrite()
    if type(v) == 'number' then
        self._OriginVal = v
    else
        self._OriginVal = 0
    end
end

--- 取最终值。纯值:final == origin(纯读,不修改状态)。
---@return number
function PropertySingle:GetFinalVal()
    return self._OriginVal
end

--- 快照:导出可还原的纯数据(事务工具)。只存原始值。
---@return table snap { origin = number }
function PropertySingle:Snapshot()
    return { origin = self._OriginVal }
end

--- 还原:从快照写回原始值(事务回滚)。
---@param snap table Snapshot 产出的结构
function PropertySingle:Restore(snap)
    self._OriginVal = snap.origin
end

return PropertySingle
