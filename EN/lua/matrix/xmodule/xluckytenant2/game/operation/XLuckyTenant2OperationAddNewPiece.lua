local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2Operation = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2Operation")
local XLuckyTenant2StateApplier = require("XModule/XLuckyTenant2/Game/XLuckyTenant2StateApplier")

---@class XLuckyTenant2OperationAddNewPiece : XLuckyTenant2Operation
---添加新棋子操作
local XLuckyTenant2OperationAddNewPiece = XClass(XLuckyTenant2Operation, "XLuckyTenant2OperationAddNewPiece")

---构造函数
---@param data table Operation数据
---@param data.pieceId number 棋子ID
---@param data.x number|false X坐标（可选）
---@param data.y number|false Y坐标（可选）
---@param data.skillId number 技能ID（可选）
---@param data.fromPieceUid number 来源棋子UID（可选，用于Type203、Type205、Type207）
function XLuckyTenant2OperationAddNewPiece:Ctor(data)
    data = data or {}
    XLuckyTenant2OperationAddNewPiece.Super.Ctor(self, data)
    self._Type = XLuckyTenant2Enum.Operation.AddNewPieceToBag
    self._PieceId = data.pieceId or 0
    self._X = data.x
    self._Y = data.y
    self._FromPieceUid = data.fromPieceUid or 0

    -- 克隆棋子数据, 以防止在动画播放的过程中, 被删掉, 导致不显示
    self._ClonePieceData = nil
end

---验证操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否有效，错误信息
function XLuckyTenant2OperationAddNewPiece:Validate(ctx)
    if not self._PieceId or self._PieceId <= 0 then
        return false, "棋子ID无效"
    end
    -- 检查配置是否存在
    local config = ctx.model:GetLuckyTenant2ChessConfigById(self._PieceId)
    if not config then
        return false, string.format("棋子配置不存在，ID:%d", self._PieceId)
    end
    -- 如果指定了位置，检查位置是否有效
    if self._X and self._Y then
        local existingPiece = ctx:GetPieceByPosition(self._X, self._Y)
        if existingPiece then
            -- 位置已被占用，但这是允许的（会添加到空位）
        end
    end
    return true, nil
end

---执行操作
---@param ctx XLuckyTenant2OperationContext 操作上下文
---@return boolean, string|nil 是否执行成功，错误信息
function XLuckyTenant2OperationAddNewPiece:Do(ctx)
    -- 验证已在基类中完成，这里直接执行
    -- 添加到背包
    local isSuccess, piece = ctx:AddNewPieceToBag(self._PieceId)
    if not isSuccess or not piece then
        return false, string.format("添加棋子到背包失败，ID:%d", self._PieceId)
    end
    
    -- 如果指定了位置，且位置为空（或被标记删除的棋子占用），则放置到棋盘上
    if self._X and self._Y then
        local existingPiece = ctx:GetPieceByPosition(self._X, self._Y)
        local canPlace = false
        if not existingPiece then
            canPlace = true
        elseif existingPiece:IsDeleted() then
            -- 位置上的棋子已被标记删除，可以放置
            canPlace = true
        end

        if canPlace then
            ctx:SetPieceByPosition(piece, self._X, self._Y)
        else
            -- 位置已被占用且未被标记删除，添加到空位
            ctx:AddPieceToChessBoard(piece)
        end
    else
        -- 未指定位置，添加到棋盘空位
        ctx:AddPieceToChessBoard(piece)
    end

    self._ClonePieceData = piece:Clone()
    
    -- 用棋子最终位置更新，供 GetAnimationData 使用（添加到空位或占位时位置由棋盘决定）
    local px, py = piece:GetPosition()
    if px and py then
        self._X, self._Y = px, py
    end
    
    -- 根据来源怪物羁绊应用状态与数值（Type203/205/207 + 死亡/感染状态，逻辑统一在 XLuckyTenant2StateApplier）
    XLuckyTenant2StateApplier.ApplyStateSkillsFromSourceBond(ctx, piece, self._PieceId, self._FromPieceUid, self._DeathSkillId, self._DeathRounds)

    return true, nil
end

---获取操作描述
---@return string
function XLuckyTenant2OperationAddNewPiece:GetDescription()
    if self._X and self._Y then
        return string.format("AddNewPiece[PieceId:%d, 位置:(%d,%d)]", self._PieceId, self._X, self._Y)
    else
        return string.format("AddNewPiece[PieceId:%d, 位置:自动]", self._PieceId)
    end
end

---获取动画数据（需要在执行后调用，因为位置在执行时确定）
---@return table|nil 动画数据
function XLuckyTenant2OperationAddNewPiece:GetAnimationData()
    -- 位置在执行时已经确定并保存到 self._X 和 self._Y
    if self._X and self._Y and self._PieceId > 0 then
        local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
        return {
            type = XLuckyTenant2Enum.AnimationType.AddPiece,
            pieceId = self._PieceId,
            x = self._X,
            y = self._Y,
            clonePieceData = self._ClonePieceData,
        }
    end
    return nil
end

return XLuckyTenant2OperationAddNewPiece
