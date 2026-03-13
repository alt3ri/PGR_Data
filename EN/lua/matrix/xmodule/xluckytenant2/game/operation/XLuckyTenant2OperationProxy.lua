local XLuckyTenant2OperationPackage = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationPackage")
local XLuckyTenant2OperationFactory = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationFactory")
local XLuckyTenant2Piece = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Piece")

---@class XLuckyTenant2OperationProxy
local XLuckyTenant2OperationProxy = XClass(nil, "XLuckyTenant2OperationProxy")

---构造函数
---@param game XLuckyTenant2Game 游戏实例
---@param model XLuckyTenant2Model 模型实例
function XLuckyTenant2OperationProxy:Ctor(game, model)
    self.Game = game  -- 保存游戏实例
    self.Model = model  -- 保存模型实例（用于配置访问）
    self.Chessboard = game:GetChessBoard()  -- 获取棋盘
    self.Bag = game:GetBag()  -- 获取背包
    
    ---@type XLuckyTenant2Piece[] 复用table，用来接收相邻棋子
    self.Neighbours = {}
    
    self.PiecesOnBoard = self.Chessboard and self.Chessboard:GetAllPieces() or {}
    
    ---@type XLuckyTenant2OperationPackage 操作包
    self.OperationPackage = XLuckyTenant2OperationPackage.New()
    
    ---@type XLuckyTenant2OperationPackage[] 多个操作包
    self.ManyOperationPackages = {}
    
    self.UniqueSkillExecuted = {}  -- 存储已执行的独特技能
    self._ExecutedSkills = {}  -- 存储已执行的技能（每个循环后清空）
    self._RoundExecutedSkills = {}  -- 存储回合级别的已执行技能（整个回合内有效，不被ClearExecutionState清空）
    self._DeletedPieces = {}  -- 已删除的棋子UID集合
    
    ---@type XLuckyTenant2Piece|nil
    self.Piece = nil  -- 当前操作的棋子
    
    ---@type XLuckyTenant2ChessSkill|nil
    self.Skill = nil  -- 当前操作的技能
    
    ---@type number[] 技能参数
    self.Params = {}
    
    ---@type table[] 本技能仅需播放的动画（如 Type508 原地生成新宝盒，不经过 Operation 但需播生成动画）
    self._ExtraAnimations = {}
    
    ---@type XLuckyTenant2Piece[] 这部分棋子已经从棋盘和背包上移除，但要等到本轮次结束后才真正移除
    self._ToDelete = {}
    
    -- 一轮次计算中，产生的操作
    self._OperationsLastCalculate = {}
    
    self.Times = 0  -- 执行次数
end

---设置当前操作的棋子和技能
---@param piece XLuckyTenant2Piece 棋子
---@param skill XLuckyTenant2ChessSkill 技能
function XLuckyTenant2OperationProxy:SetPieceAndSkill(piece, skill)
    self.Piece = piece
    self.Skill = skill
    if skill then
        self.Params = skill:GetParams() or {}
    end
end

---保存当前操作包到操作包列表
function XLuckyTenant2OperationProxy:SaveOperationPackage()
    -- 如果操作包不为空，则保存它
    if self.OperationPackage:IsNotEmpty() then
        self.ManyOperationPackages[#self.ManyOperationPackages + 1] = self.OperationPackage
        self.OperationPackage = XLuckyTenant2OperationPackage.New()  -- 重置操作包
    end
end

---添加仅播放动画的数据（不经过 Operation，如 Type508 原地生成新宝盒）
---@param animData table 格式同 GetAnimationData，如 { type = AnimationType.AddPiece, pieceId = x, x = x, y = y }
function XLuckyTenant2OperationProxy:AddExtraAnimation(animData)
    if animData and animData.type then
        self._ExtraAnimations[#self._ExtraAnimations + 1] = animData
    end
end

---取出并清空本技能累积的额外动画（由 Game 在创建动画组时合并）
---@return table[]
function XLuckyTenant2OperationProxy:GetAndClearExtraAnimations()
    local list = self._ExtraAnimations
    self._ExtraAnimations = {}
    return list
end

---执行所有操作包中的操作
---@param model XLuckyTenant2Model
---@param animationGroups table|false 动画组（可选）
function XLuckyTenant2OperationProxy:ExecuteAllOperations(model, animationGroups)
    -- 先保存当前操作包
    self:SaveOperationPackage()
    
    -- 创建操作上下文
    local XLuckyTenant2OperationContext = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationContext")
    
    -- 执行所有操作包
    for i = 1, #self.ManyOperationPackages do
        local package = self.ManyOperationPackages[i]
        local ctx = XLuckyTenant2OperationContext.New(self.Game, model, self, animationGroups)
        package:Do(ctx)
    end
    
    -- 执行延迟删除
    self:ExecuteDeferredDeletions()
    
    -- 清空操作包列表（已执行完毕）
    self.ManyOperationPackages = {}
end

---清空所有操作包
function XLuckyTenant2OperationProxy:ClearAllOperations()
    self.OperationPackage:Clear()
    self.ManyOperationPackages = {}
end

---标记执行（按棋子+技能+参数）
---@param params1 any 参数1（可选）
---@param params2 any 参数2（可选）
---@param params3 any 参数3（可选）
---@param params4 any 参数4（可选）
---@return boolean 是否已执行过（true=已执行过，false=未执行过并已标记）
function XLuckyTenant2OperationProxy:MarkExecuted(params1, params2, params3, params4)
    local key = self:_BuildExecutedKey(params1, params2, params3, params4)
    
    if self._ExecutedSkills[key] then
        return true  -- 已执行过
    end
    self._ExecutedSkills[key] = true
    return false  -- 未执行过，已标记
end

---检查是否已执行（不标记）
---@param params1 any 参数1（可选）
---@param params2 any 参数2（可选）
---@param params3 any 参数3（可选）
---@param params4 any 参数4（可选）
---@return boolean 是否已执行过
function XLuckyTenant2OperationProxy:IsExecuted(params1, params2, params3, params4)
    local key = self:_BuildExecutedKey(params1, params2, params3, params4)
    return self._ExecutedSkills[key] == true
end

---标记执行（技能级别，不依赖棋子UID）
---@param params1 any 参数1（可选）
---@return boolean 是否已执行过
function XLuckyTenant2OperationProxy:MarkSkillExecuted(params1)
    local skillId = self.Skill and self.Skill:GetId() or 0
    local key
    if params1 then
        key = "Skill_" .. skillId .. "_" .. tostring(params1)
    else
        key = "Skill_" .. skillId
    end
    
    if self._ExecutedSkills[key] then
        return true  -- 已执行过
    end
    self._ExecutedSkills[key] = true
    return false  -- 未执行过，已标记
end

---检查技能级别是否已执行
---@param params1 any 参数1（可选）
---@return boolean
function XLuckyTenant2OperationProxy:IsSkillExecuted(params1)
    local skillId = self.Skill and self.Skill:GetId() or 0
    local key
    if params1 then
        key = "Skill_" .. skillId .. "_" .. tostring(params1)
    else
        key = "Skill_" .. skillId
    end
    return self._ExecutedSkills[key] == true
end

---构建执行标记的key（私有方法）
---@param params1 any 参数1（可选）
---@param params2 any 参数2（可选）
---@param params3 any 参数3（可选）
---@param params4 any 参数4（可选）
---@return string
function XLuckyTenant2OperationProxy:_BuildExecutedKey(params1, params2, params3, params4)
    local pieceUid = self.Piece and self.Piece:GetUid() or 0
    local skillId = self.Skill and self.Skill:GetId() or 0
    
    if params4 then
        return pieceUid .. "_" .. skillId .. "_" .. tostring(params1) .. "_" .. tostring(params2) .. "_" .. tostring(params3) .. "_" .. tostring(params4)
    elseif params3 then
        return pieceUid .. "_" .. skillId .. "_" .. tostring(params1) .. "_" .. tostring(params2) .. "_" .. tostring(params3)
    elseif params2 then
        return pieceUid .. "_" .. skillId .. "_" .. tostring(params1) .. "_" .. tostring(params2)
    elseif params1 then
        return pieceUid .. "_" .. skillId .. "_" .. tostring(params1)
    else
        return pieceUid .. "_" .. skillId
    end
end

---检查棋子是否已执行过
---@param piece XLuckyTenant2Piece
---@return boolean
function XLuckyTenant2OperationProxy:CheckPieceExecuted(piece)
    if not piece then
        return false
    end
    return self:IsExecuted(piece:GetUid())
end

---设置已执行的独特技能
---@param skillId number 技能ID
function XLuckyTenant2OperationProxy:SetUniqueSkillExecuted(skillId)
    self.UniqueSkillExecuted[skillId] = true
end

---检查独特技能是否已执行
---@param skillId number 技能ID
---@return boolean
function XLuckyTenant2OperationProxy:IsUniqueSkillExecuted(skillId)
    return self.UniqueSkillExecuted[skillId] == true
end

---标记回合级别的技能执行（基于棋子UID，在整个回合内有效，不会被ClearExecutionState清空）
---@param pieceUid number 棋子UID
---@return boolean 是否已执行过（true=已执行过，false=未执行过并已标记）
function XLuckyTenant2OperationProxy:MarkRoundSkillExecuted(pieceUid)
    local key = "Piece_" .. tostring(pieceUid)
    if self._RoundExecutedSkills[key] then
        return true  -- 已执行过
    end
    self._RoundExecutedSkills[key] = true
    return false  -- 未执行过，已标记
end

---清空执行记录和待删除列表
function XLuckyTenant2OperationProxy:ClearExecutionState()
    self._ExecutedSkills = {}
    self.UniqueSkillExecuted = {}
    -- 注意：_RoundExecutedSkills 不清空，因为它需要在整个回合内有效
    self._DeletedPieces = {}
    self._ToDelete = {}
    self.Times = 0
end

---获取相邻棋子
---@param piece XLuckyTenant2Piece 可选，要获取相邻棋子的棋子，不传则使用self.Piece
---@return XLuckyTenant2Piece[]
function XLuckyTenant2OperationProxy:GetAdjacentPieces(piece)
    piece = piece or self.Piece
    if not piece or not self.Chessboard then
        return {}
    end
    
    return self.Chessboard:GetAdjacentPieces(piece)
end

---获取相邻空位坐标
---@return table[] 相邻空位坐标数组 {x, y}
function XLuckyTenant2OperationProxy:GetAdjacentEmptyPositions()
    local result = {}
    if not self.Piece or not self.Chessboard then
        return result
    end
    
    local x, y = self.Piece:GetPosition()
    if x == 0 or y == 0 then
        return result
    end
    
    -- 获取棋盘边界（Row和Column）
    local row = self.Chessboard:GetRow() or 0
    local column = self.Chessboard:GetColumn() or 0
    if row <= 0 or column <= 0 then
        return result
    end
    
    local adjacentPositions = {
        {x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1},
        {x - 1, y},                 {x + 1, y},
        {x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1},
    }
    
    for _, pos in ipairs(adjacentPositions) do
        local posX, posY = pos[1], pos[2]
        -- 验证坐标是否在棋盘边界内（坐标从1开始）
        if posX >= 1 and posX <= column and posY >= 1 and posY <= row then
            local adjPiece = self.Chessboard:GetPieceByPosition(posX, posY)
            if not adjPiece then
                -- 空位且在边界内
                table.insert(result, pos)
            end
        end
    end
    
    return result
end

---获取棋盘上所有棋子
---@return XLuckyTenant2Piece[]
function XLuckyTenant2OperationProxy:GetAllPiecesOnBoard()
    return self.Chessboard and self.Chessboard:GetAllPieces() or {}
end

---查找棋子（统一方法，在棋盘和背包中查找）
---@param uid number 棋子UID
---@return XLuckyTenant2Piece|nil
function XLuckyTenant2OperationProxy:FindPieceByUid(uid)
    if not uid or uid <= 0 then
        return nil
    end
    
    -- 先在棋盘查找
    if self.Chessboard then
        local pieces = self.Chessboard:GetAllPieces()
        for _, piece in ipairs(pieces) do
            if piece:GetUid() == uid then
                return piece
            end
        end
    end
    
    -- 再在背包查找
    if self.Bag then
        return self.Bag:GetPieceByUid(uid)
    end
    
    return nil
end

---随机判断（1-100）
---@param percent number 百分比（1-100）
---@return boolean 是否命中
function XLuckyTenant2OperationProxy:RandomCheck(percent)
    if percent <= 0 then
        return false
    end
    if percent >= 100 then
        return true
    end
    return math.random(1, 100) <= percent
end

---标记棋子为待删除（延迟删除）
---@param piece XLuckyTenant2Piece
function XLuckyTenant2OperationProxy:MarkPieceForDeletion(piece)
    if piece then
        self._ToDelete[piece:GetUid()] = piece
    end
end

---执行所有标记为待删除的棋子（从背包中移除并回收到对象池）
function XLuckyTenant2OperationProxy:ExecuteDeferredDeletions()
    if not self.Bag then
        return
    end
    
    -- 先处理_ToDelete中的棋子（这些棋子已经从棋盘和背包上移除，现在真正回收）
    for uid, piece in pairs(self._ToDelete) do
        if piece and piece:IsDeleted() then
            self.Bag:ReturnPieceToPoolByPiece(piece)
        end
        self._ToDelete[uid] = nil
    end
    
    -- 然后处理所有被标记为删除的棋子（从背包中查找并回收）
    local bagPieces = self.Bag:GetAllPieces()
    if bagPieces then
        for _, piece in ipairs(bagPieces) do
            if piece and piece:IsDeleted() then
                self.Bag:ReturnPieceToPoolByPiece(piece)
            end
        end
    end
    
    -- 处理棋盘上的被标记为删除的棋子
    if self.Chessboard then
        local boardPieces = self.Chessboard:GetAllPieces()
        if boardPieces then
            for _, piece in ipairs(boardPieces) do
                if piece and piece:IsDeleted() then
                    self.Bag:ReturnPieceToPoolByPiece(piece)
                end
            end
        end
    end
end


---检查棋子是否标记为待删除
---@param piece XLuckyTenant2Piece
---@return boolean
function XLuckyTenant2OperationProxy:IsMarkedForDeletion(piece)
    if piece and self._ToDelete[piece:GetUid()] then
        return true
    end
    return false
end

---获取上一轮计算的操作记录（用于技能查询）
---@return table
function XLuckyTenant2OperationProxy:GetLastRoundOperations()
    return self._OperationsLastCalculate
end

---添加新棋子（通过Operation）
---@param pieceId number 棋子ID
---@param x number|false X坐标（可选，默认使用当前棋子位置）
---@param y number|false Y坐标（可选，默认使用当前棋子位置）
function XLuckyTenant2OperationProxy:AddNewPiece(pieceId, x, y)
    if not pieceId or pieceId <= 0 then
        XLog.Error("[XLuckyTenant2OperationProxy] 添加棋子失败，棋子ID无效:" .. tostring(pieceId))
        return
    end
    
    -- 如果未指定位置，使用当前棋子位置
    if not x and not y and self.Piece then
        x, y = self.Piece:GetPosition()
    end
    
    local skillId = self.Skill and self.Skill:GetId() or 0
    local skillName = self.Skill and self.Skill:GetName() or ""
    XMVCA.XLuckyTenant2:Print(string.format("[AddNewPiece] 添加新棋子: pieceId=%d, 位置=(%s,%s), 技能ID=%d, 技能名=%s", 
        pieceId, tostring(x), tostring(y), skillId, skillName))
    
    local operation = XLuckyTenant2OperationFactory.CreateAddNewPiece(pieceId, x, y, skillId)
    if operation then
        self.OperationPackage:Push(operation)
        XMVCA.XLuckyTenant2:Print(string.format("[AddNewPiece] 操作已添加到队列，pieceId=%d", pieceId))
    else
        XMVCA.XLuckyTenant2:Print(string.format("[AddNewPiece] 创建操作失败，pieceId=%d", pieceId))
    end
end

---添加新棋子并给其添加死亡技能（用于技能201创建子虫）
---@param pieceId number 棋子ID
---@param x number|false X坐标（可选）
---@param y number|false Y坐标（可选）
---@param deathSkillId number|nil 死亡技能ID（技能202）
---@param deathRounds number|nil 死亡倒计回合数
function XLuckyTenant2OperationProxy:AddNewPieceWithDeathSkill(pieceId, x, y, deathSkillId, deathRounds)
    if not pieceId or pieceId <= 0 then
        XLog.Error("[XLuckyTenant2OperationProxy] 添加棋子失败，棋子ID无效:" .. tostring(pieceId))
        return
    end
    
    -- 如果未指定位置，使用当前棋子位置
    if not x and not y and self.Piece then
        x, y = self.Piece:GetPosition()
    end
    
    local skillId = self.Skill and self.Skill:GetId() or 0
    local fromPieceUid = self.Piece and self.Piece:GetUid() or 0
    local operation = XLuckyTenant2OperationFactory.CreateAddNewPiece(pieceId, x, y, skillId, fromPieceUid)
    if operation then
        -- 保存死亡技能信息，在Operation执行后给子虫添加死亡状态
        if deathSkillId and deathRounds and deathRounds > 0 then
            operation._DeathSkillId = deathSkillId
            operation._DeathRounds = deathRounds
        end
        self.OperationPackage:Push(operation)
    end
end

---添加多个新棋子（通过Operation）
---@param amount number 数量
---@param pieceId number 棋子ID
---@param x number|false X坐标（可选）
---@param y number|false Y坐标（可选）
function XLuckyTenant2OperationProxy:AddMultipleNewPieces(amount, pieceId, x, y)
    if not pieceId or pieceId <= 0 then
        XLog.Error("[XLuckyTenant2OperationProxy] 添加棋子失败，棋子ID无效:" .. tostring(pieceId))
        return
    end
    if amount <= 0 then
        return
    end
    
    -- 如果未指定位置，使用当前棋子位置
    if (not x and not y) and self.Piece then
        x, y = self.Piece:GetPosition()
    end
    
    for i = 1, amount do
        self:AddNewPiece(pieceId, x, y)
    end
end

---修改棋子金币值（通过Operation）
---@param piece XLuckyTenant2Piece 棋子
---@param valueDelta number 金币值增量（可以为负数）
function XLuckyTenant2OperationProxy:ModifyPieceValue(piece, valueDelta)
    if not piece then
        XLog.Error("[XLuckyTenant2OperationProxy] ModifyPieceValue失败，棋子不存在")
        return
    end
    
    local skillId = self.Skill and self.Skill:GetId() or 0
    local operation = XLuckyTenant2OperationFactory.CreateAddPieceValue(piece:GetUid(), valueDelta, skillId)
    if operation then
        self.OperationPackage:Push(operation)
    end
end

---设置棋子消除得分（通过Operation）
---@param piece XLuckyTenant2Piece 棋子
---@param value number 消除得分
function XLuckyTenant2OperationProxy:SetPieceValueUponDeletion(piece, value)
    if not piece then
        XLog.Error("[XLuckyTenant2OperationProxy] SetPieceValueUponDeletion失败，棋子不存在")
        return
    end
    
    local skillId = self.Skill and self.Skill:GetId() or 0
    local operation = XLuckyTenant2OperationFactory.CreateSetValueUponDeletion(piece:GetUid(), value, skillId)
    if operation then
        self.OperationPackage:Push(operation)
    end
end

---添加分数
---@param value number 分数值
---@param piece XLuckyTenant2Piece 棋子（可选，默认使用当前棋子）
function XLuckyTenant2OperationProxy:AddScore(value, piece)
    piece = piece or self.Piece
    if not piece then
        XLog.Error("[XLuckyTenant2OperationProxy] AddScore失败，棋子不存在")
        return
    end
    
    local x, y = piece:GetPosition()
    local skillId = self.Skill and self.Skill:GetId() or 0
    local operation = XLuckyTenant2OperationFactory.CreateAddScore(x, y, value, skillId)
    if operation then
        self.OperationPackage:Push(operation)
    end
end

---删除棋子（通过Operation）
---@param piece XLuckyTenant2Piece 要删除的棋子
---@param from XLuckyTenant2Piece 来源棋子（可选）
---@return boolean 是否成功
function XLuckyTenant2OperationProxy:DeletePiece(piece, from)
    if not piece then
        XLog.Error("[XLuckyTenant2OperationProxy] 删除棋子失败，棋子不存在")
        return false
    end
    
    local uid = piece:GetUid()
    local pieceName = piece:GetName() or "未知"
    local pieceId = piece:GetId()
    local x, y = piece:GetPosition()
    local posStr = (x > 0 and y > 0) and string.format("位置(%d,%d)", x, y) or "背包"
    
    if self._DeletedPieces[uid] then
        if XMVCA.XLuckyTenant2 then
            XMVCA.XLuckyTenant2:Print(string.format("[DeletePiece] 棋子已被标记删除: %s[ID:%d,UID:%d], %s", 
                pieceName, pieceId, uid, posStr))
        end
        return false
    end
    self._DeletedPieces[uid] = true
    
    local fromPieceUid = (from or self.Piece) and (from or self.Piece):GetUid() or 0
    local skillId = self.Skill and self.Skill:GetId() or 0
    local operation = XLuckyTenant2OperationFactory.CreateDeletePiece(uid, x, y, fromPieceUid, skillId)
    if operation then
        self.OperationPackage:Push(operation)
        if XMVCA.XLuckyTenant2 then
            XMVCA.XLuckyTenant2:Print(string.format("[DeletePiece] 删除棋子操作已加入队列: %s[ID:%d,UID:%d], %s, 技能ID=%d", 
                pieceName, pieceId, uid, posStr, skillId))
        end
        return true
    end
    
    return false
end

---删除当前棋子（通过Operation）
---@param from XLuckyTenant2Piece 来源棋子（可选）
---@return boolean 是否成功
function XLuckyTenant2OperationProxy:DeleteCurrentPiece(from)
    return self:DeletePiece(self.Piece, from)
end

---修改棋子等级（通过Operation）
---@param piece XLuckyTenant2Piece 棋子
---@param levelDelta number 等级增量（可以为负数）
function XLuckyTenant2OperationProxy:ModifyPieceLevel(piece, levelDelta)
    if not piece then
        XLog.Error("[XLuckyTenant2OperationProxy] ModifyPieceLevel失败，棋子不存在")
        return
    end
    
    local skillId = self.Skill and self.Skill:GetId() or 0
    local operation = XLuckyTenant2OperationFactory.CreateAddPieceLevel(piece:GetUid(), levelDelta, skillId)
    if operation then
        self.OperationPackage:Push(operation)
    end
end

---应用状态到棋子（通过Operation）
---@param piece XLuckyTenant2Piece 棋子
---@param stateType number 状态类型
---@param skillId number 状态技能ID（可以是技能类型ID或技能配置ID）
---@param rounds number 持续回合数
function XLuckyTenant2OperationProxy:ApplyState(piece, stateType, skillId, rounds)
    if not piece then
        XLog.Error("[XLuckyTenant2OperationProxy] ApplyState失败，棋子不存在")
        return
    end
    
    -- 解析技能ID：如果传入的是技能类型ID（例如102），则解析为实际的技能配置ID
    local actualSkillId = skillId
    if self.Model then
        local SkillExecutor = require("XModule/XLuckyTenant2/Game/Skill/XLuckyTenant2SkillExecutor")
        local resolvedId, _ = SkillExecutor.ResolveStateSkillId(skillId, self.Model)
        if resolvedId then
            actualSkillId = resolvedId
        end
    end
    
    local operation = XLuckyTenant2OperationFactory.CreateAddPieceState(piece:GetUid(), stateType, actualSkillId, rounds)
    if operation then
        -- 设置Operation的技能ID为当前技能ID（用于日志）
        local currentSkillId = self.Skill and self.Skill:GetId() or 0
        operation:SetSkillId(currentSkillId)
        self.OperationPackage:Push(operation)
    end
end


---修改棋子品质（通过Operation）
---@param piece XLuckyTenant2Piece 棋子
---@param qualityDelta number 品质增量（可以为负数）
function XLuckyTenant2OperationProxy:ModifyPieceQuality(piece, qualityDelta)
    if not piece then
        XLog.Error("[XLuckyTenant2OperationProxy] ModifyPieceQuality失败，棋子不存在")
        return
    end
    
    local skillId = self.Skill and self.Skill:GetId() or 0
    local operation = XLuckyTenant2OperationFactory.CreateAddPieceQuality(piece:GetUid(), qualityDelta, skillId)
    if operation then
        self.OperationPackage:Push(operation)
    end
end
return XLuckyTenant2OperationProxy

