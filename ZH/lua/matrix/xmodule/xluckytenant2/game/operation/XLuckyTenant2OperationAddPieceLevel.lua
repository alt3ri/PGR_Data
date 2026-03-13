local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2Operation = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2Operation")

---@class XLuckyTenant2OperationAddPieceLevel : XLuckyTenant2Operation
---增加棋子等级操作
local XLuckyTenant2OperationAddPieceLevel = XClass(XLuckyTenant2Operation, "XLuckyTenant2OperationAddPieceLevel")

---构造函数
---@param data table Operation数据
---@param data.pieceUid number 棋子UID
---@param data.levelDelta number 等级增量（可以为负数）
---@param data.skillId number 技能ID（可选）
function XLuckyTenant2OperationAddPieceLevel:Ctor(data)
    data = data or {}
    XLuckyTenant2OperationAddPieceLevel.Super.Ctor(self, data)
    self._Type = XLuckyTenant2Enum.Operation.AddPieceLevel
    self._PieceUid = data.pieceUid or 0
    self._LevelDelta = data.levelDelta or 0
end

---验证操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否有效，错误信息
function XLuckyTenant2OperationAddPieceLevel:Validate(ctx)
    if self._PieceUid <= 0 then
        return false, "棋子UID无效"
    end
    if self._LevelDelta == 0 then
        return false, "等级增量不能为0"
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
function XLuckyTenant2OperationAddPieceLevel:Do(ctx)
    -- 验证已在基类中完成，这里直接执行
    local piece = ctx:FindPieceByUid(self._PieceUid)
    if not piece then
        return false, string.format("执行时找不到棋子UID:%d", self._PieceUid)
    end
    
    -- 增加等级
    local currentLevel = piece:GetLevel() or 0
    piece:AddLevel(self._LevelDelta)
    
    -- 如果等级增加了（升级），标记"刚升级"，供Type504等技能检测
    -- 注意：不能修改Upgrade状态的RemainRounds，否则会破坏Type301的升级倒计时
    if self._LevelDelta > 0 then
        piece:MarkJustLeveledUp()
    end
    return true, nil
end

---获取操作描述
---@return string
function XLuckyTenant2OperationAddPieceLevel:GetDescription()
    return string.format("AddPieceLevel[PieceUid:%d, LevelDelta:%d]", self._PieceUid, self._LevelDelta)
end

---获取动画数据
---@return table|nil 动画数据
function XLuckyTenant2OperationAddPieceLevel:GetAnimationData()
    if self._PieceUid > 0 then
        local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
        return {
            type = XLuckyTenant2Enum.AnimationType.UpdatePiece,
            pieceUid = self._PieceUid,
        }
    end
    return nil
end

return XLuckyTenant2OperationAddPieceLevel

