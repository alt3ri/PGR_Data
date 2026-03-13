local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2Operation = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2Operation")

---@class XLuckyTenant2OperationAddPieceQuality : XLuckyTenant2Operation
---增加棋子品质操作
local XLuckyTenant2OperationAddPieceQuality = XClass(XLuckyTenant2Operation, "XLuckyTenant2OperationAddPieceQuality")

---构造函数
---@param data table Operation数据
---@param data.pieceUid number 棋子UID
---@param data.qualityDelta number 品质增量（可以为负数）
---@param data.skillId number 技能ID（可选）
function XLuckyTenant2OperationAddPieceQuality:Ctor(data)
    data = data or {}
    XLuckyTenant2OperationAddPieceQuality.Super.Ctor(self, data)
    self._Type = XLuckyTenant2Enum.Operation.AddPieceQuality
    self._PieceUid = data.pieceUid or 0
    self._QualityDelta = data.qualityDelta or 0
end

---验证操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否有效，错误信息
function XLuckyTenant2OperationAddPieceQuality:Validate(ctx)
    if self._PieceUid <= 0 then
        return false, "棋子UID无效"
    end
    if self._QualityDelta == 0 then
        return false, "品质增量不能为0"
    end
    local piece = ctx:FindPieceByUid(self._PieceUid)
    if not piece then
        return false, string.format("找不到棋子UID:%d", self._PieceUid)
    end
    return true, nil
end

---执行操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否执行成功，错误信息
function XLuckyTenant2OperationAddPieceQuality:Do(ctx)
    local piece = ctx:FindPieceByUid(self._PieceUid)
    if not piece then
        return false, string.format("执行时找不到棋子UID:%d", self._PieceUid)
    end

    piece:AddQuality(self._QualityDelta)
    return true, nil
end

---获取操作描述
---@return string
function XLuckyTenant2OperationAddPieceQuality:GetDescription()
    return string.format("AddPieceQuality[PieceUid:%d, QualityDelta:%d]", self._PieceUid, self._QualityDelta)
end

---获取动画数据
---@return table|nil 动画数据
function XLuckyTenant2OperationAddPieceQuality:GetAnimationData()
    if self._PieceUid > 0 then
        return {
            type = XLuckyTenant2Enum.AnimationType.UpdatePiece,
            pieceUid = self._PieceUid,
        }
    end
    return nil
end

return XLuckyTenant2OperationAddPieceQuality
