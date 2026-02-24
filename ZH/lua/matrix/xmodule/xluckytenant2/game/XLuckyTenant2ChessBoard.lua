local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")

---@class XLuckyTenant2ChessBoard
local XLuckyTenant2ChessBoard = XClass(nil, "XLuckyTenant2ChessBoard")

function XLuckyTenant2ChessBoard:Ctor()
    ---@type XLuckyTenant2Piece[]
    self._Pieces = {}
    --- 正在计算的分数
    self._Score4Position = {}
    --- 已经执行的分数
    self._Score4PositionImplemented = {}
    self._Column = 0
    self._Row = 0
    self._PiecesAmount = 0
end

---@param config XTable.XTableLuckyTenant2Stage
function XLuckyTenant2ChessBoard:Init(config)
    local column = config.Column
    local row = config.Row
    self._Column = column
    self._Row = row
    self._PiecesAmount = column * row
    for y = 1, row do
        for x = 1, column do
            local index = self:GetIndex(x, y)
            self._Pieces[index] = false
            self._Score4Position[index] = 0
            self._Score4PositionImplemented[index] = 0
        end
    end
end

function XLuckyTenant2ChessBoard:GetIndex(x, y)
    return (y - 1) * self._Column + x
end

function XLuckyTenant2ChessBoard:GetXY(index)
    local x = (index - 1) % self._Column + 1
    local y = math.ceil(index / self._Column)
    return x, y
end

function XLuckyTenant2ChessBoard:ClearEveryTurn()
    for i = 1, #self._Pieces do
        local piece = self._Pieces[i]
        if piece then
            piece:ClearEveryTurn()
            self._Pieces[i] = false
        end
    end
    for i = 1, #self._Score4Position do
        self._Score4Position[i] = 0
    end
    for i = 1, #self._Score4PositionImplemented do
        self._Score4PositionImplemented[i] = 0
    end
end

function XLuckyTenant2ChessBoard:SetPieceByIndex(piece, index, x, y)
    local pieceOnPos = self._Pieces[index]
    if pieceOnPos then
        if pieceOnPos ~= piece then
            pieceOnPos:ResetPosition()
            XMVCA.XLuckyTenant2:Print("用", piece:GetName(), "替换了棋盘上的棋子", pieceOnPos:GetName(), ",他的位置是(" .. tostring(x) .. "," .. tostring(y) .. ")")
        end
    end
    self._Pieces[index] = piece
    if not x or not y then
        x, y = self:GetXY(index)
    end
    piece:SetPosition(x, y)
    return true
end

---@param piece XLuckyTenant2Piece
function XLuckyTenant2ChessBoard:SetPieceByPosition(piece, x, y)
    if x > self._Column or y > self._Row then
        XLog.Error("[XLuckyTenant2ChessBoard] 设置棋子位置超出棋盘大小")
        return false
    end
    local index = self:GetIndex(x, y)
    return self:SetPieceByIndex(piece, index, x, y)
end

---@param game XLuckyTenant2Game
---@param model XLuckyTenant2Model
---@param bag XLuckyTenant2Bag
function XLuckyTenant2ChessBoard:SetTestCase(game, model, bag, testCase)
    self:ClearEveryTurn()

    local usedPiece = {}
    for i = 1, #testCase do
        local pieceId = testCase[i]
        if pieceId ~= 0 then
            local piece = bag:FindPiece(pieceId, usedPiece)
            if not piece or usedPiece[piece:GetUid()] then
                local isSuccess
                isSuccess, piece = game:AddNewPieceToBag(model, pieceId)
                if isSuccess and piece then
                    XMVCA.XLuckyTenant2:Print("[XLuckyTenant2ChessBoard] 作弊获得棋子:" .. piece:GetName())
                end
            end
            if not piece then
                XLog.Warning("[XLuckyTenant2ChessBoard] SetTestCase创建棋子失败，pieceId=" .. tostring(pieceId))
                goto continue_test_case
            end
            usedPiece[piece:GetUid()] = true
            local x, y = self:GetXY(i)
            self:SetPieceByPosition(piece, x, y)
        end
        ::continue_test_case::
    end
end

---@param bag XLuckyTenant2Bag
function XLuckyTenant2ChessBoard:SetPieces(bag)
    -- 调试日志
    local XLuckyTenant2DebugLog = require("XModule/XLuckyTenant2/XLuckyTenant2DebugLog")
    XLuckyTenant2DebugLog.Log("========== SetPieces 开始 ==========")
    XLuckyTenant2DebugLog.LogFormat("棋盘容量: %d", self._PiecesAmount)
    
    self:ClearEveryTurn()

    local pieces = bag:GetPieces()
    local piecesToEnter1 = {}
    for i, piece in pairs(pieces) do
        -- 过滤掉道具（不放到棋盘上）
        local pieceId = piece:GetId()
        if pieceId == XLuckyTenant2Enum.PropId.RefreshProp or pieceId == XLuckyTenant2Enum.PropId.DeleteProp then
            goto continue
        end
        piecesToEnter1[#piecesToEnter1 + 1] = piece
        ::continue::
    end
    
    XLuckyTenant2DebugLog.LogFormat("背包中棋子总数: %d", #piecesToEnter1)
    
    -- 如果棋子数量>20，只取前20个
    local piecesToEnter2 = {}
    local maxPieces = math.min(#piecesToEnter1, self._PiecesAmount)
    XLuckyTenant2DebugLog.LogFormat("将选择 %d 个棋子放置到棋盘", maxPieces)
    
    for i = 1, maxPieces do
        local remaining = #piecesToEnter1
        if remaining > 0 then
            local index = math.random(1, remaining)
            local piece = piecesToEnter1[index]
            table.remove(piecesToEnter1, index)
            piecesToEnter2[#piecesToEnter2 + 1] = piece
        end
    end
    
    XLuckyTenant2DebugLog.LogFormat("选择了 %d 个棋子放置到棋盘", #piecesToEnter2)
    
    -- 随机位置
    local posToEnter = {}
    for i = 1, self._PiecesAmount do
        posToEnter[#posToEnter + 1] = i
    end
    for i = 1, #piecesToEnter2 do
        ---@type XLuckyTenant2Piece
        local piece = piecesToEnter2[i]
        local index = math.random(1, #posToEnter)
        local pos = posToEnter[index]
        table.remove(posToEnter, index)
        self._Pieces[pos] = piece
        local x, y = self:GetXY(pos)
        piece:SetPosition(x, y)
        
        -- 调试日志：记录放置的棋子信息
        XLuckyTenant2DebugLog.LogFormat("  放置棋子: PieceId=%d, Uid=%d, 位置=(%d,%d), 位置索引=%d", 
            piece:GetId(), piece:GetUid(), x, y, pos)
        
        -- 棋子进入棋盘，恢复状态倒计时
        bag:OnPieceEnterBoard(piece)
    end
    
    -- 剩余的棋子留在背包中，状态保持冻结
    XLuckyTenant2DebugLog.LogFormat("剩余 %d 个棋子留在背包中", #piecesToEnter1)
    for i = 1, #piecesToEnter1 do
        local piece = piecesToEnter1[i]
        bag:OnPieceLeaveBoard(piece)
        XLuckyTenant2DebugLog.LogFormat("  保留在背包: PieceId=%d, Uid=%d", 
            piece:GetId(), piece:GetUid())
    end
    
    XLuckyTenant2DebugLog.Log("========== SetPieces 结束 ==========")
    XMVCA.XLuckyTenant2:Print("设置棋盘结束")
end

---@return XLuckyTenant2Piece|false
function XLuckyTenant2ChessBoard:GetPieceByPosition(x, y)
    if x > self._Column or x < 1 or y > self._Row or y < 1 then
        return false
    end
    local index = self:GetIndex(x, y)
    local piece = self._Pieces[index]
    if piece and piece:IsDeleted() then
        return false
    end
    return piece
end

---@return XLuckyTenant2Piece
function XLuckyTenant2ChessBoard:GetPieceByIndex(index)
    return self._Pieces[index]
end

---@param piece XLuckyTenant2Piece
---@return XLuckyTenant2Piece[] 相邻棋子列表（九宫格）
function XLuckyTenant2ChessBoard:GetAdjacentPieces(piece)
    local result = {}
    local x, y = piece:GetPosition()
    if x == 0 or y == 0 then
        return result
    end
    
    local adjacentPositions = {
        {x - 1, y + 1}, {x, y + 1}, {x + 1, y + 1},
        {x - 1, y},                 {x + 1, y},
        {x - 1, y - 1}, {x, y - 1}, {x + 1, y - 1},
    }
    
    for _, pos in ipairs(adjacentPositions) do
        local adjPiece = self:GetPieceByPosition(pos[1], pos[2])
        if adjPiece then
            table.insert(result, adjPiece)
        end
    end
    
    return result
end

---@param piece XLuckyTenant2Piece
---@return boolean 是否成功添加到棋盘空位
function XLuckyTenant2ChessBoard:AddPieceToChessBoard(piece)
    if not piece then
        return false
    end
    
    -- 查找第一个空位
    for i = 1, #self._Pieces do
        if not self._Pieces[i] then
            -- 找到空位，放置棋子
            local x, y = self:GetXY(i)
            return self:SetPieceByPosition(piece, x, y)
        end
    end
    
    -- 没有空位
    return false
end

---@param piece XLuckyTenant2Piece
---@return XLuckyTenant2Piece[] 同行同列的棋子列表
function XLuckyTenant2ChessBoard:GetSameRowColPieces(piece)
    local result = {}
    local x, y = piece:GetPosition()
    if x == 0 or y == 0 then
        return result
    end
    
    -- 同行
    for col = 1, self._Column do
        if col ~= x then
            local adjPiece = self:GetPieceByPosition(col, y)
            if adjPiece then
                table.insert(result, adjPiece)
            end
        end
    end
    
    -- 同列
    for row = 1, self._Row do
        if row ~= y then
            local adjPiece = self:GetPieceByPosition(x, row)
            if adjPiece then
                table.insert(result, adjPiece)
            end
        end
    end
    
    return result
end

---@return XLuckyTenant2Piece[] 所有棋盘上的棋子
function XLuckyTenant2ChessBoard:GetAllPieces()
    local result = {}
    for i = 1, #self._Pieces do
        local piece = self._Pieces[i]
        if piece and not piece:IsDeleted() then
            table.insert(result, piece)
        end
    end
    return result
end

---@return number 空位数量
function XLuckyTenant2ChessBoard:GetEmptySlotCount()
    local count = 0
    for i = 1, #self._Pieces do
        if not self._Pieces[i] then
            count = count + 1
        end
    end
    return count
end

---@return boolean 是否有空位
function XLuckyTenant2ChessBoard:HasEmptySlot()
    return self:GetEmptySlotCount() > 0
end

function XLuckyTenant2ChessBoard:DeletePieceByUid(uid)
    for i = 1, #self._Pieces do
        local piece = self._Pieces[i]
        if piece and piece:GetUid() == uid then
            self._Pieces[i] = false
            piece:ResetPosition()
            break
        end
    end
end

---从指定位置移除棋子
---@param x number X坐标
---@param y number Y坐标
---@return XLuckyTenant2Piece|false 被移除的棋子，如果没有棋子则返回false
function XLuckyTenant2ChessBoard:RemovePieceByPosition(x, y)
    if x > self._Column or x < 1 or y > self._Row or y < 1 then
        return false
    end
    local index = self:GetIndex(x, y)
    local piece = self._Pieces[index]
    if piece then
        self._Pieces[index] = false
        piece:ResetPosition()
        return piece
    end
    return false
end

function XLuckyTenant2ChessBoard:GetColumn()
    return self._Column
end

function XLuckyTenant2ChessBoard:GetRow()
    return self._Row
end

function XLuckyTenant2ChessBoard:GetPiecesAmount()
    return self._PiecesAmount
end

---获取序列化消息（用于网络传输）
---@return table 数组，每个元素为棋子UID或0
function XLuckyTenant2ChessBoard:GetEncodeMessage()
    local pieces = self._Pieces
    local message = {}
    for i = 1, #pieces do
        local piece = pieces[i]
        if piece then
            message[i] = piece:GetUid()
        else
            message[i] = 0
        end
    end
    return message
end

return XLuckyTenant2ChessBoard

