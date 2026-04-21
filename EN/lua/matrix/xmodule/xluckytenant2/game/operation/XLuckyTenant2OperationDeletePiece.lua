local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2Operation = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2Operation")
local XLuckyTenant2OnDeleteEffects = require("XModule/XLuckyTenant2/Game/XLuckyTenant2OnDeleteEffects")

---@class XLuckyTenant2OperationDeletePiece : XLuckyTenant2Operation
---删除棋子操作
local XLuckyTenant2OperationDeletePiece = XClass(XLuckyTenant2Operation, "XLuckyTenant2OperationDeletePiece")

---构造函数
---@param data table Operation数据
---@param data.pieceUid number 棋子UID
---@param data.x number X坐标
---@param data.y number Y坐标
---@param data.fromPieceUid number 来源棋子UID（可选）
---@param data.skillId number 技能ID（可选）
---@param data.roleWhipCount number 305鞭尸特效次数（可选）
---@param data.roleWhipSkillId number 305技能ID（可选）
function XLuckyTenant2OperationDeletePiece:Ctor(data)
    data = data or {}
    XLuckyTenant2OperationDeletePiece.Super.Ctor(self, data)
    self._Type = XLuckyTenant2Enum.Operation.DeletePiece
    self._PieceUid = data.pieceUid or 0
    self._X = data.x or 0
    self._Y = data.y or 0
    self._FromPieceUid = data.fromPieceUid or 0
    self._RoleWhipCount = data.roleWhipCount or 0
    self._RoleWhipSkillId = data.roleWhipSkillId or 0
end

---验证操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否有效，错误信息
function XLuckyTenant2OperationDeletePiece:Validate(ctx)
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
function XLuckyTenant2OperationDeletePiece:Do(ctx)
    -- 验证已在基类中完成，这里直接执行
    -- 在删除前获取棋子信息并执行「删除时效果」（Type204/208/507/502 统一在 XLuckyTenant2OnDeleteEffects）
    local piece = ctx:FindPieceByUid(self._PieceUid)
    self._PieceId = piece and piece:GetId() or 0  -- 供 GetAnimationData 使用（区分宝盒/非宝盒特效）
    local baseValue = piece and piece:GetBaseValue() or 0
    XLuckyTenant2OnDeleteEffects.ApplyOnDeleteEffects(ctx, piece, baseValue, {
        x = self._X,
        y = self._Y,
        fromPieceUid = self._FromPieceUid,
        skillId = self._SkillId,
    })

    -- 统一删除：先标记、再移除棋盘、再移除背包，避免对象池回收后仍被引用
    ctx:DeletePiece(self._PieceUid, self._X, self._Y)

    return true, nil
end

---获取操作描述
---@return string
function XLuckyTenant2OperationDeletePiece:GetDescription()
    return string.format("DeletePiece[PieceUid:%d, 位置:(%d,%d)]", self._PieceUid, self._X, self._Y)
end

---获取动画数据
---@return table|nil 动画数据
function XLuckyTenant2OperationDeletePiece:GetAnimationData()
    if self._PieceUid <= 0 then
        return nil
    end

    local AnimationType = XLuckyTenant2Enum.AnimationType
    local animList = {}

    -- Type304 + Type305：在删除前先播放多次被技能影响特效（鞭尸表现）
    if self._RoleWhipCount > 0 and self._RoleWhipSkillId > 0 then
        for _ = 1, self._RoleWhipCount do
            animList[#animList + 1] = {
                type = AnimationType.AffectedBySkillEnable,
                pieceUid = self._PieceUid,
                x = self._X,
                y = self._Y,
                skillId = self._RoleWhipSkillId,
            }
        end
    end

    -- 删除动画放在最后
    animList[#animList + 1] = {
        type = AnimationType.DeletePiece,
        pieceUid = self._PieceUid,
        x = self._X,
        y = self._Y,
        fromPieceUid = self._FromPieceUid,  -- 来源棋子UID（用于晃动动画）
        pieceId = self._PieceId or 0,       -- 被删棋子ID（用于区分宝盒/非宝盒消除特效）
    }

    return animList
end

return XLuckyTenant2OperationDeletePiece

