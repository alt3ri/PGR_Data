local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2Operation = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2Operation")

---@class XLuckyTenant2OperationAddPieceValue : XLuckyTenant2Operation
---增加棋子金币值操作
local XLuckyTenant2OperationAddPieceValue = XClass(XLuckyTenant2Operation, "XLuckyTenant2OperationAddPieceValue")

---构造函数
---@param data table Operation数据
---@param data.pieceUid number 棋子UID
---@param data.value number 金币值增量（可以为负数）
---@param data.skillId number 技能ID（可选）
function XLuckyTenant2OperationAddPieceValue:Ctor(data)
    data = data or {}
    XLuckyTenant2OperationAddPieceValue.Super.Ctor(self, data)
    self._Type = XLuckyTenant2Enum.Operation.AddPieceValue
    self._PieceUid = data.pieceUid or 0
    self._Value = data.value or 0
end

---验证操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否有效，错误信息
function XLuckyTenant2OperationAddPieceValue:Validate(ctx)
    if self._PieceUid <= 0 then
        return false, "棋子UID无效"
    end
    if self._Value == 0 then
        return false, "金币值增量不能为0"
    end
    -- 检查棋子是否存在
    local piece = ctx:FindPieceByUid(self._PieceUid)
    if not piece then
        return false, string.format("找不到棋子UID:%d", self._PieceUid)
    end
    return true, nil
end

---执行操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否执行成功，错误信息
function XLuckyTenant2OperationAddPieceValue:Do(ctx)
    -- 验证已在基类中完成，这里直接执行
    local piece = ctx:FindPieceByUid(self._PieceUid)
    if not piece then
        return false, string.format("执行时找不到棋子UID:%d", self._PieceUid)
    end
    
    -- 增加金币值（直接修改基础金币值）
    piece:AddValue(self._Value)
    return true, nil
end

---获取操作描述
---@return string
function XLuckyTenant2OperationAddPieceValue:GetDescription()
    return string.format("AddPieceValue[PieceUid:%d, Value:%d]", self._PieceUid, self._Value)
end

---获取动画数据
---@return table|nil 动画数据
function XLuckyTenant2OperationAddPieceValue:GetAnimationData()
    if self._PieceUid > 0 and self._Value ~= 0 then
        local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
        return {
            type = XLuckyTenant2Enum.AnimationType.UpdatePiece,
            pieceUid = self._PieceUid,
        }
    end
    return nil
end

return XLuckyTenant2OperationAddPieceValue

