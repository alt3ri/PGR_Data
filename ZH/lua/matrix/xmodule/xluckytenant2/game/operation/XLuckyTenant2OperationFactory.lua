---Operation工厂
---统一创建和管理所有Operation类型
---@class XLuckyTenant2OperationFactory
local XLuckyTenant2OperationFactory = {}

local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")

local _Creators = {}
local _Initialized = false

---初始化工厂，注册所有Operation类型
local function _Initialize()
    if _Initialized then
        return
    end
    
    -- 注册所有Operation类型
    local XLuckyTenant2OperationAddScore = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationAddScore")
    local XLuckyTenant2OperationDeletePiece = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationDeletePiece")
    local XLuckyTenant2OperationAddNewPiece = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationAddNewPiece")
    local XLuckyTenant2OperationAddPieceValue = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationAddPieceValue")
    local XLuckyTenant2OperationAddPieceLevel = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationAddPieceLevel")
    local XLuckyTenant2OperationAddPieceState = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationAddPieceState")
    local XLuckyTenant2OperationAddPieceQuality = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationAddPieceQuality")
    local XLuckyTenant2OperationSetValueUponDeletion = require("XModule/XLuckyTenant2/Game/Operation/XLuckyTenant2OperationSetValueUponDeletion")

    _Creators[XLuckyTenant2Enum.Operation.Score] = function(data)
        return XLuckyTenant2OperationAddScore.New(data)
    end
    
    _Creators[XLuckyTenant2Enum.Operation.DeletePiece] = function(data)
        return XLuckyTenant2OperationDeletePiece.New(data)
    end
    
    _Creators[XLuckyTenant2Enum.Operation.AddNewPieceToBag] = function(data)
        return XLuckyTenant2OperationAddNewPiece.New(data)
    end
    
    _Creators[XLuckyTenant2Enum.Operation.AddPieceValue] = function(data)
        return XLuckyTenant2OperationAddPieceValue.New(data)
    end
    
    _Creators[XLuckyTenant2Enum.Operation.AddPieceLevel] = function(data)
        return XLuckyTenant2OperationAddPieceLevel.New(data)
    end
    
    _Creators[XLuckyTenant2Enum.Operation.AddPieceState] = function(data)
        return XLuckyTenant2OperationAddPieceState.New(data)
    end

    _Creators[XLuckyTenant2Enum.Operation.AddPieceQuality] = function(data)
        return XLuckyTenant2OperationAddPieceQuality.New(data)
    end

    _Creators[XLuckyTenant2Enum.Operation.SetValueUponDeletion] = function(data)
        return XLuckyTenant2OperationSetValueUponDeletion.New(data)
    end
    
    _Initialized = true
end

---注册Operation创建器（用于扩展）
---@param type number Operation类型
---@param creator function 创建函数 function(data) -> Operation
function XLuckyTenant2OperationFactory.Register(type, creator)
    _Initialize()
    _Creators[type] = creator
end

---创建Operation
---@param type number Operation类型
---@param data table Operation数据（可选）
---@return XLuckyTenant2Operation|nil
function XLuckyTenant2OperationFactory.Create(type, data)
    _Initialize()
    
    data = data or {}
    data.type = type  -- 确保类型正确
    
    local creator = _Creators[type]
    if not creator then
        XLog.Error("[XLuckyTenant2OperationFactory] 未注册的Operation类型:", type)
        return nil
    end
    
    local success, operation = pcall(creator, data)
    if not success then
        XLog.Error("[XLuckyTenant2OperationFactory] 创建Operation失败，类型:", type, "错误:", operation)
        return nil
    end
    
    return operation
end

---检查Operation类型是否已注册
---@param type number Operation类型
---@return boolean
function XLuckyTenant2OperationFactory.IsRegistered(type)
    _Initialize()
    return _Creators[type] ~= nil
end

---便捷方法：创建AddScore操作
---@param x number X坐标
---@param y number Y坐标
---@param value number 分数值
---@param skillId number 技能ID（可选）
---@return XLuckyTenant2Operation|nil
function XLuckyTenant2OperationFactory.CreateAddScore(x, y, value, skillId)
    return XLuckyTenant2OperationFactory.Create(XLuckyTenant2Enum.Operation.Score, {
        x = x,
        y = y,
        value = value,
        skillId = skillId or 0,
    })
end

---便捷方法：创建DeletePiece操作
---@param pieceUid number 棋子UID
---@param x number X坐标
---@param y number Y坐标
---@param fromPieceUid number 来源棋子UID（可选）
---@param skillId number 技能ID（可选）
---@return XLuckyTenant2Operation|nil
function XLuckyTenant2OperationFactory.CreateDeletePiece(pieceUid, x, y, fromPieceUid, skillId)
    return XLuckyTenant2OperationFactory.Create(XLuckyTenant2Enum.Operation.DeletePiece, {
        pieceUid = pieceUid,
        x = x,
        y = y,
        fromPieceUid = fromPieceUid or 0,
        skillId = skillId or 0,
    })
end

---便捷方法：创建AddNewPiece操作
---@param pieceId number 棋子ID
---@param x number|false X坐标（可选）
---@param y number|false Y坐标（可选）
---@param skillId number 技能ID（可选）
---@return XLuckyTenant2Operation|nil
function XLuckyTenant2OperationFactory.CreateAddNewPiece(pieceId, x, y, skillId, fromPieceUid)
    return XLuckyTenant2OperationFactory.Create(XLuckyTenant2Enum.Operation.AddNewPieceToBag, {
        pieceId = pieceId,
        x = x,
        y = y,
        skillId = skillId or 0,
        fromPieceUid = fromPieceUid or 0,
    })
end

---便捷方法：创建AddPieceValue操作
---@param pieceUid number 棋子UID
---@param value number 金币值增量
---@param skillId number 技能ID（可选）
---@return XLuckyTenant2Operation|nil
function XLuckyTenant2OperationFactory.CreateAddPieceValue(pieceUid, value, skillId)
    return XLuckyTenant2OperationFactory.Create(XLuckyTenant2Enum.Operation.AddPieceValue, {
        pieceUid = pieceUid,
        value = value,
        skillId = skillId or 0,
    })
end

---便捷方法：创建SetValueUponDeletion操作
---@param pieceUid number 棋子UID
---@param value number 消除得分
---@param skillId number 技能ID（可选）
---@return XLuckyTenant2Operation|nil
function XLuckyTenant2OperationFactory.CreateSetValueUponDeletion(pieceUid, value, skillId)
    return XLuckyTenant2OperationFactory.Create(XLuckyTenant2Enum.Operation.SetValueUponDeletion, {
        pieceUid = pieceUid,
        value = value,
        skillId = skillId or 0,
    })
end

---便捷方法：创建AddPieceLevel操作
---@param pieceUid number 棋子UID
---@param levelDelta number 等级增量
---@param skillId number 技能ID（可选）
---@return XLuckyTenant2Operation|nil
function XLuckyTenant2OperationFactory.CreateAddPieceLevel(pieceUid, levelDelta, skillId)
    return XLuckyTenant2OperationFactory.Create(XLuckyTenant2Enum.Operation.AddPieceLevel, {
        pieceUid = pieceUid,
        levelDelta = levelDelta,
        skillId = skillId or 0,
    })
end

---便捷方法：创建AddPieceState操作
---@param pieceUid number 棋子UID
---@param stateType number 状态类型
---@param skillId number 状态技能ID
---@param rounds number 持续回合数
---@return XLuckyTenant2Operation|nil
function XLuckyTenant2OperationFactory.CreateAddPieceState(pieceUid, stateType, skillId, rounds)
    return XLuckyTenant2OperationFactory.Create(XLuckyTenant2Enum.Operation.AddPieceState, {
        pieceUid = pieceUid,
        stateType = stateType,
        skillId = skillId,
        rounds = rounds,
    })
end

---便捷方法：创建AddPieceQuality操作
---@param pieceUid number 棋子UID
---@param qualityDelta number 品质增量（可以为负数）
---@param skillId number 技能ID（可选）
---@return XLuckyTenant2Operation|nil
function XLuckyTenant2OperationFactory.CreateAddPieceQuality(pieceUid, qualityDelta, skillId)
    return XLuckyTenant2OperationFactory.Create(XLuckyTenant2Enum.Operation.AddPieceQuality, {
        pieceUid = pieceUid,
        qualityDelta = qualityDelta,
        skillId = skillId or 0,
    })
end

return XLuckyTenant2OperationFactory

