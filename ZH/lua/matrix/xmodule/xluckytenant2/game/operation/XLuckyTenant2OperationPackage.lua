---@class XLuckyTenant2OperationPackage
local XLuckyTenant2OperationPackage = XClass(nil, "XLuckyTenant2OperationPackage")

function XLuckyTenant2OperationPackage:Ctor()
    ---@type XLuckyTenant2Operation[]
    self._Operations = {}
end

---添加操作到包中
---@param operation XLuckyTenant2Operation
function XLuckyTenant2OperationPackage:Push(operation)
    if operation then
        self._Operations[#self._Operations + 1] = operation
    end
end

---获取所有操作
---@return XLuckyTenant2Operation[]
function XLuckyTenant2OperationPackage:GetOperations()
    return self._Operations
end

---检查包是否为空
---@return boolean
function XLuckyTenant2OperationPackage:IsNotEmpty()
    return #self._Operations > 0
end

---执行包中的所有操作（统一接口，使用Context）
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return table|nil 动画数据列表（如果有动画数据），格式：{type = AnimationType, ...}[]
function XLuckyTenant2OperationPackage:Do(ctx)
    local operations = self._Operations
    local animationDataList = {}
    
    for i = 1, #operations do
        ---@type XLuckyTenant2Operation
        local operation = operations[i]
        if operation then
            local success, errMsg = operation:Do(ctx)
            if not success and errMsg then
                XLog.Warning("[XLuckyTenant2OperationPackage] Operation执行失败:", errMsg, "操作:", operation:GetDescription())
            else
                -- 执行成功后，获取动画数据
                local animData = operation:GetAnimationData()
                if animData then
                    animationDataList[#animationDataList + 1] = animData
                end
            end
        end
    end
    
    -- 如果有动画数据，返回；否则返回 nil
    if #animationDataList > 0 then
        return animationDataList
    end
    return nil
end

---验证包中的所有操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否全部有效，错误信息（如果有）
function XLuckyTenant2OperationPackage:ValidateAll(ctx)
    local operations = self._Operations
    for i = 1, #operations do
        ---@type XLuckyTenant2Operation
        local operation = operations[i]
        if operation then
            local valid, errMsg = operation:Validate(ctx)
            if not valid then
                return false, string.format("Operation[%d]验证失败: %s", i, errMsg or "未知错误")
            end
        end
    end
    return true, nil
end

---保存操作记录（用于回放或日志）
---@param record table 记录表
function XLuckyTenant2OperationPackage:SaveRecord(record)
    for i = 1, #self._Operations do
        record[#record + 1] = self._Operations[i]
    end
end

---清空操作包
function XLuckyTenant2OperationPackage:Clear()
    self._Operations = {}
end

return XLuckyTenant2OperationPackage

