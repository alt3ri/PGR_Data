local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")

---@class XLuckyTenant2Operation
---Operation基类，所有操作都继承此类
local XLuckyTenant2Operation = XClass(nil, "XLuckyTenant2Operation")

---构造函数
---@param data table Operation数据（可选）
---@param data.type number Operation类型（可选，子类会自动设置）
---@param data.sourcePosition number 源位置（可选）
function XLuckyTenant2Operation:Ctor(data)
    data = data or {}
    self._Type = data.type or XLuckyTenant2Enum.Operation.None
    self._SourcePosition = data.sourcePosition or 0
    self._SkillId = data.skillId or 0  -- 来源技能ID（用于日志和调试）
    self._Timestamp = data.timestamp or os.time()  -- 创建时间戳（用于调试）
end

---验证操作是否可以执行（子类可以重写）
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否有效，错误信息（如果有）
function XLuckyTenant2Operation:Validate(ctx)
    -- 默认实现：总是返回true
    return true, nil
end

---执行操作（统一接口，使用Context）
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否执行成功，错误信息（如果有）
function XLuckyTenant2Operation:Do(ctx)
    -- 先验证
    local valid, errMsg = self:Validate(ctx)
    if not valid then
        return false, errMsg or "验证失败"
    end
    
    -- 子类必须实现此方法
    XLog.Error("[XLuckyTenant2Operation] Do方法未实现，类型:", self._Type)
    return false, "Do方法未实现"
end

---获取操作描述（用于日志和调试）
---@return string
function XLuckyTenant2Operation:GetDescription()
    return string.format("Operation[Type:%d, SkillId:%d]", self._Type, self._SkillId)
end

---获取操作类型
---@return number
function XLuckyTenant2Operation:GetType()
    return self._Type
end

---获取源位置
---@return number
function XLuckyTenant2Operation:GetSourcePosition()
    return self._SourcePosition
end

---获取技能ID
---@return number
function XLuckyTenant2Operation:GetSkillId()
    return self._SkillId
end

---设置技能ID
---@param skillId number
function XLuckyTenant2Operation:SetSkillId(skillId)
    self._SkillId = skillId or 0
end

---获取动画数据（子类可以重写，如果没有动画则返回 nil）
---@return table|nil 动画数据，格式：{type = AnimationType, ...}，如果没有动画则返回 nil
function XLuckyTenant2Operation:GetAnimationData()
    -- 默认实现：返回 nil（表示没有动画）
    return nil
end

return XLuckyTenant2Operation

