local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2Operation = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2Operation")

---@class XLuckyTenant2OperationAddPieceState : XLuckyTenant2Operation
---添加棋子状态操作
local XLuckyTenant2OperationAddPieceState = XClass(XLuckyTenant2Operation, "XLuckyTenant2OperationAddPieceState")

---构造函数
---@param data table Operation数据
---@param data.pieceUid number 棋子UID
---@param data.stateType number 状态类型（TriggerState枚举）
---@param data.skillId number 状态技能ID
---@param data.rounds number 持续回合数
---@param data.fromPieceUid number 来源棋子UID（可选，用于受影响动画定位施法者）
function XLuckyTenant2OperationAddPieceState:Ctor(data)
    data = data or {}
    XLuckyTenant2OperationAddPieceState.Super.Ctor(self, data)
    self._Type = XLuckyTenant2Enum.Operation.AddPieceState
    self._PieceUid = data.pieceUid or 0
    self._StateType = data.stateType or 0
    self._StateSkillId = data.skillId or 0  -- 状态技能ID（与Operation的skillId不同）
    self._Rounds = data.rounds or 0
    self._FromPieceUid = data.fromPieceUid or 0
end

---验证操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否有效，错误信息
function XLuckyTenant2OperationAddPieceState:Validate(ctx)
    if self._PieceUid <= 0 then
        return false, "棋子UID无效"
    end
    if self._StateType <= 0 then
        return false, "状态类型无效"
    end
    if self._Rounds < 0 then
        return false, "回合数不能为负数"
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
function XLuckyTenant2OperationAddPieceState:Do(ctx)
    -- 验证已在基类中完成，这里直接执行
    local piece = ctx:FindPieceByUid(self._PieceUid)
    if not piece then
        return false, string.format("执行时找不到棋子UID:%d", self._PieceUid)
    end
    
    -- 添加状态
    local XLuckyTenant2State = require("XModule/XLuckyTenant2/Game/XLuckyTenant2State")
    -- 技能类型转为技能ID
    local skillId = XLuckyTenant2Enum.SkillTypeToInfectionSkillMap[self._StateSkillId] or self._StateSkillId
    local state = XLuckyTenant2State.New(self._StateType, skillId, self._Rounds)
    piece:AddState(state)
    
    return true, nil
end

---获取操作描述
---@return string
function XLuckyTenant2OperationAddPieceState:GetDescription()
    return string.format("AddPieceState[PieceUid:%d, StateType:%d, Rounds:%d]", 
        self._PieceUid, self._StateType, self._Rounds)
end

---获取动画数据
---@return table|nil 动画数据
function XLuckyTenant2OperationAddPieceState:GetAnimationData()
    if self._PieceUid > 0 then
        local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
        return {
            type = XLuckyTenant2Enum.AnimationType.UpdatePiece,
            pieceUid = self._PieceUid,
            fromPieceUid = self._FromPieceUid,
        }
    end
    return nil
end

return XLuckyTenant2OperationAddPieceState

