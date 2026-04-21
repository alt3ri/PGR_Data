local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2Piece = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Piece")

---@class XLuckyTenant2Bag
local XLuckyTenant2Bag = XClass(nil, "XLuckyTenant2Bag")

function XLuckyTenant2Bag:Ctor()
    ---@type table<number, XLuckyTenant2Piece> key为uid
    self._Pieces = {}

    ---@type table<number, XLuckyTenant2Piece> key为type
    self._Props = {}

    self._Uid = 0
    local createFunc = function()
        return XLuckyTenant2Piece.New()
    end
    ---@param piece XLuckyTenant2Piece
    local releaseFunc = function(piece)
        piece:Clear()
    end
    ---@type XPool
    self._Pool = XPool.New(createFunc, releaseFunc)

    self._PiecesAmount = 0
    local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
    self._MaxPiecesAmount = XLuckyTenant2Enum.GameConstants.MAX_PIECES_AMOUNT

    -- 被删掉的，需要纪录下来
    self._PieceDeleted = {}
    self._PieceDeletedDictionary = {}

    self._IsTagDirty = true
    self._Tag = {}
    ---@type XLuckyTenant2Piece[]|nil 缓存的可选棋子列表（排除道具），脏时重建
    self._AllPiecesCache = nil
    self._AllPiecesCacheDirty = true
end

---@param config XTableLuckyTenant2Stage
---@param game XLuckyTenant2Game
function XLuckyTenant2Bag:Init(model, config, isResumeGame, game)
    if not config then
        XLog.Error("[XLuckyTenant2Bag] config不存在")
        return
    end
    self._MaxPiecesAmount = config.BagCapacity

    if isResumeGame then
        return
    end
    
    local initialPiece = config.InitialPiece or {}
    local initialPieceAmount = config.InitialPieceNum or {}

    for i = 1, #initialPiece do
        local pieceId = initialPiece[i]
        local pieceAmount = initialPieceAmount[i] or 1
        if pieceId and pieceId > 0 then
            for j = 1, pieceAmount do
                game:AddNewPieceToBag(model, pieceId)
            end
        end
    end

    self:InitProps(game, model)
    self._IsTagDirty = true
end

---@param game XLuckyTenant2Game
---@param model XLuckyTenant2Model
function XLuckyTenant2Bag:InitProps(game, model)
    for name, id in pairs(XLuckyTenant2Enum.PropId) do
        local itemType = model:GetLuckyTenant2ChessTypeById(id)
        local prop = self:GetProp(itemType)
        if not prop then
            -- 先检查 InitialPiece 里是否已经加过该道具（99998/99999），避免重复添加并把数量清零
            local existingPieces = {}
            local totalAmount = 0
            for uid, piece in pairs(self._Pieces) do
                if piece and not piece:IsDeleted() and piece:GetId() == id then
                    existingPieces[#existingPieces + 1] = { uid = uid, piece = piece }
                    totalAmount = totalAmount + (piece:GetAmount() or 0)
                end
            end
            if #existingPieces > 0 then
                -- 保留第一个 piece 作为 _Props 引用，合并数量；其余从背包移除并回收
                local keep = existingPieces[1]
                keep.piece:SetAmount(totalAmount)
                self._Props[itemType] = keep.piece
                for i = 2, #existingPieces do
                    local u = existingPieces[i]
                    self:RemovePiece(u.uid)
                    self:ReturnPieceToPoolByPiece(u.piece)
                end
            else
                ---@type XLuckyTenant2Piece
                local isSuccess, piece = game:AddNewPieceToBag(model, id)
                if isSuccess and piece then
                    piece:SetAmount(0)
                    self._Props[itemType] = piece  -- 注册到 _Props，GetRefreshCoin/GetDeleteCoin 才能取到数量
                end
            end
        end
    end
end

function XLuckyTenant2Bag:GetNewUid()
    self._Uid = self._Uid + 1
    return self._Uid
end

---@return XLuckyTenant2Piece|false
function XLuckyTenant2Bag:NewPiece(model, pieceId, uid)
    if uid then
        self._Uid = math.max(self._Uid, uid)
    else
        uid = self:GetNewUid()
    end
    ---@type XTable.XTableLuckyTenant2Chess
    local config = model:GetLuckyTenant2ChessConfigById(pieceId)
    if not config then
        -- 配置不存在时返回false，不报Error（允许测试环境等场景）
        return false
    end
    ---@type XLuckyTenant2Piece
    local piece = self._Pool:GetItemFromPool()
    if not piece then
        XLog.Error("[XLuckyTenant2Bag] 从对象池获取棋子失败")
        return false
    end
    piece:Set(uid, config)
    return piece
end

---@return table<number, XLuckyTenant2Piece>
function XLuckyTenant2Bag:GetPieces()
    return self._Pieces
end

---@return XLuckyTenant2Piece[]
function XLuckyTenant2Bag:GetAllPieces()
    if not self._AllPiecesCacheDirty and self._AllPiecesCache then
        return self._AllPiecesCache
    end
    local result = {}
    local refreshProp = XLuckyTenant2Enum.PropId.RefreshProp
    local deleteProp = XLuckyTenant2Enum.PropId.DeleteProp
    for _, piece in pairs(self._Pieces) do
        local pieceId = piece:GetId()
        if pieceId ~= refreshProp and pieceId ~= deleteProp then
            table.insert(result, piece)
        end
    end
    self._AllPiecesCache = result
    self._AllPiecesCacheDirty = false
    return result
end

---@return XLuckyTenant2Piece[]
function XLuckyTenant2Bag:GetAllPiecesIncludingBoard()
    -- 返回所有棋子（包括在棋盘上的）
    local result = {}
    for _, piece in pairs(self._Pieces) do
        table.insert(result, piece)
    end
    return result
end

---@param piece XLuckyTenant2Piece
function XLuckyTenant2Bag:AddPiece(piece)
    if not piece then
        XLog.Error("[XLuckyTenant2Bag] AddPiece: piece为nil")
        return false
    end
    -- 检查是否已满
    if self:IsFull() then
        return false
    end
    local uid = piece:GetUid()
    if not uid or uid <= 0 then
        XLog.Error("[XLuckyTenant2Bag] AddPiece: 棋子uid无效:" .. tostring(uid))
        return false
    end
    if self._Pieces[uid] then
        XLog.Error("[XLuckyTenant2Bag] 棋子已存在:" .. tostring(uid))
        return false
    end
    self._Pieces[uid] = piece
    self._PiecesAmount = self._PiecesAmount + 1
    -- 棋子进入背包时，暂停状态倒计时
    piece:PauseStates()
    self._IsTagDirty = true
    self._AllPiecesCacheDirty = true
    return true
end

---@param uid number
function XLuckyTenant2Bag:RemovePiece(uid)
    local piece = self._Pieces[uid]
    if piece then
        self._Pieces[uid] = nil
        self._PiecesAmount = self._PiecesAmount - 1
        self._PieceDeleted[#self._PieceDeleted + 1] = piece:GetId()
        self._PieceDeletedDictionary[piece:GetId()] = (self._PieceDeletedDictionary[piece:GetId()] or 0) + 1
        -- 标记为删除，但不立即回收到对象池（延迟回收）
        piece:MarkAsDeleted()
        self._IsTagDirty = true
        self._AllPiecesCacheDirty = true
        return true
    end
    return false
end

---真正回收棋子到对象池（在所有技能执行完毕后调用）
---@param uid number
function XLuckyTenant2Bag:ReturnPieceToPool(uid)
    -- 注意：此时棋子可能已经从_Pieces中移除，需要从其他地方查找
    -- 或者通过传入的piece对象直接回收
    -- 这里我们假设调用者已经知道piece对象
    return false  -- 这个方法需要piece对象，应该使用下面的方法
end

---真正回收棋子到对象池（在所有技能执行完毕后调用）
---@param piece XLuckyTenant2Piece
function XLuckyTenant2Bag:ReturnPieceToPoolByPiece(piece)
    if piece and piece:IsDeleted() then
        -- 清除删除标记后回收到对象池
        piece:ClearDeletedFlag()
        self._Pool:ReturnItemToPool(piece)
        return true
    end
    return false
end

---@param pieceId number
---@param excludedList table
---@return XLuckyTenant2Piece
function XLuckyTenant2Bag:FindPiece(pieceId, excludedList)
    for i, piece in pairs(self._Pieces) do
        -- 过滤已标记为删除的棋子
        if not piece:IsDeleted() then
            if (not excludedList) or (not excludedList[piece:GetUid()]) then
                if piece:GetId() == pieceId then
                    return piece
                end
            end
        end
    end
end

---@param type number
---@return XLuckyTenant2Piece
function XLuckyTenant2Bag:GetProp(type)
    return self._Props[type]
end

---根据UID获取棋子（不包括已标记为删除的棋子）
---@param uid number
---@return XLuckyTenant2Piece|nil
function XLuckyTenant2Bag:GetPieceByUid(uid)
    local piece = self._Pieces[uid]
    if piece and not piece:IsDeleted() then
        return piece
    end
    return nil
end

---根据UID删除棋子（OperationContext使用）
---@param uid number
---@return boolean
function XLuckyTenant2Bag:DeletePieceByUid(uid)
    return self:RemovePiece(uid)
end

function XLuckyTenant2Bag:GetPiecesAmount()
    local amount = 0
    for i, v in pairs(self._Pieces) do
        -- 过滤掉道具（不计算在数量中）
        local pieceId = v:GetId()
        if pieceId ~= XLuckyTenant2Enum.PropId.RefreshProp and pieceId ~= XLuckyTenant2Enum.PropId.DeleteProp then
            amount = amount + 1
        end
    end
    return amount
end

function XLuckyTenant2Bag:GetMaxPiecesAmount()
    return self._MaxPiecesAmount
end

function XLuckyTenant2Bag:IsFull()
    return self:GetPiecesAmount() >= self._MaxPiecesAmount
end

---@param piece XLuckyTenant2Piece
function XLuckyTenant2Bag:OnPieceEnterBoard(piece)
    -- 棋子进入棋盘时，恢复状态倒计时
    piece:ResumeStates()
end

---@param piece XLuckyTenant2Piece
function XLuckyTenant2Bag:OnPieceLeaveBoard(piece)
    -- 棋子离开棋盘进入背包时，暂停状态倒计时
    piece:PauseStates()
end

function XLuckyTenant2Bag:GetDeletedPieceAmount()
    return #self._PieceDeleted
end

function XLuckyTenant2Bag:GetDeletedPieceAmountById(pieceId)
    return self._PieceDeletedDictionary[pieceId] or 0
end

function XLuckyTenant2Bag:ReducePropAmount(type)
    local prop = self:GetProp(type)
    if prop then
        local amount = math.max(prop:GetAmount() - 1, 0)
        prop:SetAmount(amount)
    end
end

function XLuckyTenant2Bag:GetPieceAmountById(pieceId)
    local pieceAmount = 0
    for uid, piece in pairs(self._Pieces) do
        if piece:GetId() == pieceId then
            pieceAmount = pieceAmount + 1
        end
    end
    return pieceAmount
end

---刷新标签数据
function XLuckyTenant2Bag:_RefreshTag()
    -- 清空现有标签数据
    for tag, _ in pairs(self._Tag) do
        self._Tag[tag] = nil
    end
    
    -- 遍历所有棋子，统计标签数量
    for uid, piece in pairs(self._Pieces) do
        local tag = piece._Tag  -- 第二期的Tag可能是字符串（用|分隔）、数组或false
        if tag and tag ~= false then
            local tagArray = {}
            -- 如果tag是字符串，转换为数组
            if type(tag) == "string" then
                for tagStr in string.gmatch(tag, "[^|]+") do
                    local tagValue = tonumber(tagStr)
                    if tagValue and tagValue > 0 then
                        table.insert(tagArray, tagValue)
                    end
                end
            elseif type(tag) == "table" then
                -- 如果tag是数组
                tagArray = tag
            else
                -- 如果tag是单个数字值
                local tagValue = tonumber(tag)
                if tagValue and tagValue > 0 then
                    table.insert(tagArray, tagValue)
                end
            end
            
            -- 统计标签数量
            for i = 1, #tagArray do
                local tagValue = tagArray[i]
                if tagValue and tagValue > 0 then
                    self._Tag[tagValue] = (self._Tag[tagValue] or 0) + 1
                end
            end
        end
    end
end

---获取指定Tag的棋子数量（用于随机池条件判断）
---@param tag string Tag名称
---@return number
function XLuckyTenant2Bag:GetTagAmount(tag)
    if self._IsTagDirty then
        self:_RefreshTag()
    end
    return self._Tag[tag] or 0
end

---获取所有Tag数据
---@return table 标签数据表 {tag = amount, ...}
---@return boolean 是否刚更新
function XLuckyTenant2Bag:GetTag()
    local isDirty = self._IsTagDirty
    if self._IsTagDirty then
        self:_RefreshTag()
        self._IsTagDirty = false
    end
    return self._Tag, isDirty
end

---获取序列化消息（用于网络传输）
---@return table
function XLuckyTenant2Bag:GetEncodeMessage()
    local grids = {}
    local pieces = self:GetPieces()

    -- 序列化背包中的棋子（道具也在 _Pieces 中，无需从 _Props 再次序列化，否则恢复时会重复添加）
    for uid, piece in pairs(pieces) do
        local pieceParams = piece:GetParamsEncodeMessage()
        local message = XMessagePack.Encode(pieceParams)
        if uid ~= piece:GetUid() then
            XLog.Error("[XLuckyTenant2Bag] encode有错误, pieceUId与背包key不相等")
        else
            grids[#grids + 1] = {
                ChessId = piece:GetId(),
                Uid = piece:GetUid(),
                ChessParams = message,
            }
        end
    end

    return grids
end

return XLuckyTenant2Bag

