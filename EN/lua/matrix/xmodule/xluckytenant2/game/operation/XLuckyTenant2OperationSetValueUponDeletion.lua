local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2Operation = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2Operation")

---@class XLuckyTenant2OperationSetValueUponDeletion : XLuckyTenant2Operation
---设置棋子消除得分操作
local XLuckyTenant2OperationSetValueUponDeletion = XClass(XLuckyTenant2Operation, "XLuckyTenant2OperationSetValueUponDeletion")

---构造函数
---@param data table Operation数据
---@param data.pieceUid number 棋子UID
---@param data.value number 消除得分
---@param data.skillId number 技能ID（可选）
function XLuckyTenant2OperationSetValueUponDeletion:Ctor(data)
    data = data or {}
    XLuckyTenant2OperationSetValueUponDeletion.Super.Ctor(self, data)
    self._Type = XLuckyTenant2Enum.Operation.SetValueUponDeletion
    self._PieceUid = data.pieceUid or 0
    self._Value = data.value or 0
end

---验证操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否有效，错误信息
function XLuckyTenant2OperationSetValueUponDeletion:Validate(ctx)
    if self._PieceUid <= 0 then
        return false, "棋子UID无效"
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
function XLuckyTenant2OperationSetValueUponDeletion:Do(ctx)
    local piece = ctx:FindPieceByUid(self._PieceUid)
    if not piece then
        return false, string.format("执行时找不到棋子UID:%d", self._PieceUid)
    end
    
    piece:SetValueUponDeletion(self._Value)
    
    if XMVCA.XLuckyTenant2 then
        XMVCA.XLuckyTenant2:Print("[XLuckyTenant2OperationSetValueUponDeletion] 棋子UID:", self._PieceUid, 
            "设置消除得分:", self._Value, "技能ID:", self._SkillId)
    end
    
    return true, nil
end

---获取操作描述
---@return string
function XLuckyTenant2OperationSetValueUponDeletion:GetDescription()
    return string.format("SetValueUponDeletion[PieceUid:%d, Value:%d]", self._PieceUid, self._Value)
end

---获取动画数据
---@return table|nil 动画数据
function XLuckyTenant2OperationSetValueUponDeletion:GetAnimationData()
    if self._PieceUid > 0 then
        local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
        return {
            type = XLuckyTenant2Enum.AnimationType.UpdatePiece,
            pieceUid = self._PieceUid,
        }
    end
    return nil
end

return XLuckyTenant2OperationSetValueUponDeletion
