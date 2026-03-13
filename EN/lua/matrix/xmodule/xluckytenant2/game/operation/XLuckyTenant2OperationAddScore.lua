local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2Operation = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2Operation")

---@class XLuckyTenant2OperationAddScore : XLuckyTenant2Operation
---添加分数操作
local XLuckyTenant2OperationAddScore = XClass(XLuckyTenant2Operation, "XLuckyTenant2OperationAddScore")

---构造函数
---@param data table Operation数据
---@param data.x number X坐标
---@param data.y number Y坐标
---@param data.value number 分数值
---@param data.skillId number 技能ID（可选）
function XLuckyTenant2OperationAddScore:Ctor(data)
    data = data or {}
    XLuckyTenant2OperationAddScore.Super.Ctor(self, data)
    self._Type = XLuckyTenant2Enum.Operation.Score
    self._X = data.x or 0
    self._Y = data.y or 0
    self._Value = data.value or 0
end

---验证操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否有效，错误信息
function XLuckyTenant2OperationAddScore:Validate(ctx)
    if self._Value <= 0 then
        return false, "分数值必须大于0"
    end
    return true, nil
end

---执行操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否执行成功，错误信息
function XLuckyTenant2OperationAddScore:Do(ctx)
    -- 验证已在基类中完成，这里直接执行
    ctx:AddScoreThisRound(self._Value)
    
    if XMVCA.XLuckyTenant2 then
        XMVCA.XLuckyTenant2:Print("[XLuckyTenant2OperationAddScore] 位置(", self._X, ",", self._Y, 
            ") 增加分数:", self._Value, "技能ID:", self._SkillId)
    end
    
    return true, nil
end

---获取操作描述
---@return string
function XLuckyTenant2OperationAddScore:GetDescription()
    return string.format("AddScore[位置:(%d,%d), 分数:%d]", self._X, self._Y, self._Value)
end

---获取动画数据
---@return table|nil 动画数据
function XLuckyTenant2OperationAddScore:GetAnimationData()
    if self._Value > 0 then
        local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
        return {
            type = XLuckyTenant2Enum.AnimationType.GetScore,
            x = self._X,
            y = self._Y,
            value = self._Value,
        }
    end
    return nil
end

return XLuckyTenant2OperationAddScore

