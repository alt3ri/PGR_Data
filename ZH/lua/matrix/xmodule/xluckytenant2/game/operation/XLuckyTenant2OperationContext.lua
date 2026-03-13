---操作执行上下文
---提供统一的执行环境和辅助方法
---@class XLuckyTenant2OperationContext
local XLuckyTenant2OperationContext = {}

---创建操作上下文
---@param game XLuckyTenant2Game 游戏实例
---@param model XLuckyTenant2Model 模型实例
---@param proxy XLuckyTenant2OperationProxy 操作代理
---@param animationGroup table|false 动画组（可选）
---@return XLuckyTenant2OperationContext
function XLuckyTenant2OperationContext.New(game, model, proxy)
    local ctx = {
        game = game,
        model = model,
        proxy = proxy,
    }
    
    ---查找棋子（统一方法，在棋盘和背包中查找）
    ---@param uid number 棋子UID
    ---@return XLuckyTenant2Piece|nil
    function ctx:FindPieceByUid(uid)
        if not uid or uid <= 0 then
            return nil
        end
        
        -- 先在棋盘查找
        local board = game:GetChessBoard()
        if board then
            local pieces = board:GetAllPieces()
            for _, piece in ipairs(pieces) do
                if piece and not piece:IsDeleted() and piece:GetUid() == uid then
                    return piece
                end
            end
        end
        
        -- 再在背包查找
        local bag = game:GetBag()
        if bag then
            return bag:GetPieceByUid(uid)
        end
        
        return nil
    end
    
    ---获取棋盘
    ---@return XLuckyTenant2ChessBoard|nil
    function ctx:GetChessBoard()
        return game:GetChessBoard()
    end
    
    ---获取背包
    ---@return XLuckyTenant2Bag|nil
    function ctx:GetBag()
        return game:GetBag()
    end
    
    ---获取当前回合分数
    ---@return number
    function ctx:GetScoreThisRound()
        return game:GetScoreThisRound()
    end
    
    ---设置当前回合分数
    ---@param score number
    function ctx:SetScoreThisRound(score)
        game:SetScoreThisRound(score)
    end
    
    ---增加当前回合分数
    ---@param delta number 增量
    ---@param sourcePiece XLuckyTenant2Piece|nil 分数来源棋子（可选）
    ---@param sourceBondIds number[]|nil 明确羁绊ID列表（可选）
    function ctx:AddScoreThisRound(delta, sourcePiece, sourceBondIds)
        game:AddScoreThisRound(delta, sourcePiece, sourceBondIds)
    end
    
    ---添加新棋子到背包
    ---@param pieceId number 棋子ID
    ---@return boolean, XLuckyTenant2Piece|nil 是否成功，棋子对象
    function ctx:AddNewPieceToBag(pieceId)
        return game:AddNewPieceToBag(model, pieceId)
    end
    
    ---获取棋盘上指定位置的棋子
    ---@param x number X坐标
    ---@param y number Y坐标
    ---@return XLuckyTenant2Piece|nil
    function ctx:GetPieceByPosition(x, y)
        local board = game:GetChessBoard()
        if board then
            return board:GetPieceByPosition(x, y)
        end
        return nil
    end
    
    ---在棋盘上设置棋子
    ---@param piece XLuckyTenant2Piece 棋子
    ---@param x number X坐标
    ---@param y number Y坐标
    ---@return boolean 是否成功
    function ctx:SetPieceByPosition(piece, x, y)
        local board = game:GetChessBoard()
        if board then
            return board:SetPieceByPosition(piece, x, y)
        end
        return false
    end
    
    ---从棋盘移除棋子
    ---@param x number X坐标
    ---@param y number Y坐标
    ---@return boolean 是否成功
    function ctx:RemovePieceByPosition(x, y)
        local board = game:GetChessBoard()
        if board then
            return board:RemovePieceByPosition(x, y)
        end
        return false
    end
    
    ---添加棋子到棋盘空位
    ---@param piece XLuckyTenant2Piece 棋子
    ---@return boolean 是否成功
    function ctx:AddPieceToChessBoard(piece)
        local board = game:GetChessBoard()
        if board then
            return board:AddPieceToChessBoard(piece)
        end
        return false
    end
    
    ---从背包删除棋子
    ---@param uid number 棋子UID
    ---@return boolean 是否成功
    function ctx:DeletePieceFromBag(uid)
        local bag = game:GetBag()
        if bag then
            return bag:DeletePieceByUid(uid)
        end
        return false
    end
    
    ---统一删除棋子：先标记、再移除棋盘、再移除背包，避免对象池回收后仍被引用
    ---@param uid number 棋子UID
    ---@param x number|nil 若棋子在棋盘上，可传X坐标以按位置移除
    ---@param y number|nil 若棋子在棋盘上，可传Y坐标
    ---@return boolean 是否执行了删除
    function ctx:DeletePiece(uid, x, y)
        if not uid or uid <= 0 then
            return false
        end
        local piece = ctx:FindPieceByUid(uid)
        if piece then
            if ctx.proxy then
                ctx.proxy:MarkPieceForDeletion(piece)
            end
            piece:MarkAsDeleted()
        end
        local board = game:GetChessBoard()
        if board then
            if x and y and type(x) == "number" and type(y) == "number" then
                local atPos = board:GetPieceByPosition(x, y)
                if atPos and atPos:GetUid() == uid then
                    board:RemovePieceByPosition(x, y)
                else
                    board:DeletePieceByUid(uid)
                end
            else
                board:DeletePieceByUid(uid)
            end
        end
        ctx:DeletePieceFromBag(uid)
        return true
    end
    
    ---获取游戏实例（用于访问BondManager等）
    ---@return XLuckyTenant2Game
    function ctx:GetGame()
        return game
    end
    
    ---统一添加或更新棋子状态（与 Game:ApplyStateToPiece 同一接口，供 Operation 调用）
    ---@param piece XLuckyTenant2Piece
    ---@param stateType number 状态类型（TriggerState）
    ---@param skillId number 技能ID
    ---@param rounds number 剩余回合数（-1 表示永久）
    ---@param options table|nil 可选 { conditionId = number }
    ---@return boolean 是否应用了状态
    function ctx:ApplyStateToPiece(piece, stateType, skillId, rounds, options)
        if not game then
            return false
        end
        local context = {
            piece = piece,
            board = game:GetChessBoard(),
            bag = game:GetBag(),
            game = game,
            model = model,
        }
        return game:ApplyStateToPiece(piece, stateType, skillId, rounds, model, context, options or {})
    end
    
    return ctx
end

return XLuckyTenant2OperationContext

