--- 玩法内的Entity基类
--- 仅在Control生命周期内的，复杂的数据处理、配置表读取逻辑，封装到这里
---@class XTheatre5GameEntityBase: XEntity
local XTheatre5GameEntityBase = XClass(XEntity, 'XTheatre5GameEntityBase')

---@overload
function XTheatre5GameEntityBase:GetCurRoundGridUnlockCostReduce()
    
end

function XTheatre5GameEntityBase:GetRuneGridInitCount()
    
end

return XTheatre5GameEntityBase