local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local PieceId = XLuckyTenant2Enum.PieceId or { Subworm = 2 }
local XLuckyTenant2State = require("XModule/XLuckyTenant2/Game/XLuckyTenant2State")
local XLuckyTenant2ChessSkill = require("XModule/XLuckyTenant2/Game/XLuckyTenant2ChessSkill")

---@class XLuckyTenant2Piece
local XLuckyTenant2Piece = XClass(nil, "XLuckyTenant2Piece")

-- 类变量：缓存角色等级上限（从Type301技能配置读取）
local _CachedRoleMaxLevel = XLuckyTenant2Enum.GameConstants.MAX_ROLE_LEVEL

---设置角色等级上限（从Type301技能配置读取）
---@param maxLevel number 角色最大等级
function XLuckyTenant2Piece.SetRoleMaxLevel(maxLevel)
    _CachedRoleMaxLevel = maxLevel
end

---获取角色等级上限
---@return number 角色最大等级
function XLuckyTenant2Piece.GetRoleMaxLevel()
    return _CachedRoleMaxLevel or XLuckyTenant2Enum.GameConstants.MAX_ROLE_LEVEL
end

-- 类变量：缓存武器等级上限（从Type401技能配置读取）
local _CachedWeaponMaxLevel = XLuckyTenant2Enum.GameConstants.MAX_PIECE_LEVEL

---设置武器等级上限（从Type401技能配置读取）
---@param maxLevel number 武器最大等级
function XLuckyTenant2Piece.SetWeaponMaxLevel(maxLevel)
    _CachedWeaponMaxLevel = maxLevel
end

---获取武器等级上限
---@return number 武器最大等级
function XLuckyTenant2Piece.GetWeaponMaxLevel()
    return _CachedWeaponMaxLevel or XLuckyTenant2Enum.GameConstants.MAX_PIECE_LEVEL
end

function XLuckyTenant2Piece:Ctor(uid, config)
    self._Id = 0
    self._Uid = 0
    self._PieceType = 0
    self._Quality = 0
    self._Name = ""
    self._Desc = false
    self._InitialValue = 0
    self._ScoreValidThisRound = 0
    self._Icon = false
    self._IsCanDelete = false
    self._IsCanDie = false
    self._SkillId = false
    self._Tag = false

    self._Amount = 0
    self._Value = 0
    self._ValueUponDeletion = 0
    self._InitialValueUponDeletion = 0
    self._BondBaseValueDeltas = {}
    self._BondDeletionValueDeltas = {}

    self._IsPiece = false
    self._IsProp = false
    ---@type XLuckyTenant2ChessSkill[]
    self._Skills = false

    self._X = 0
    self._Y = 0
    self._IsOnBoard = false -- 是否在棋盘上

    -- 二期新增字段
    self._BondId = ""             -- 羁绊id（支持多个，用|隔开）
    self._CanUseForBond = false   -- 是否可应用到凑羁绊中
    self._Level = 0               -- 等级
    self._DefaultLevel = 0        -- 默认等级
    self._CanUpgrade = false      -- 是否可升级
    self._CanBeEliminated = false -- 是否可被消除
    ---@type table<number, XLuckyTenant2State> 状态字典，key为状态类型
    self._States = {}

    -- 非鸦技能需要动态显示概率
    self._IsDescDynamic = true
    self._DynamicDesc = false
    self._IsHideRound = false

    -- 删除标记：标记棋子是否已被删除（延迟回收）
    self._IsDeleted = false

    -- 如果提供了config，则设置配置
    if config then
        self:Set(uid or 0, config)
    elseif uid then
        self:SetUid(uid)
    end
end

function XLuckyTenant2Piece:ResetPosition()
    self._X = 0
    self._Y = 0
    self._IsOnBoard = false
end

function XLuckyTenant2Piece:SetConfigAndClear(config)
    self:Clear()
    self:__SetConfig(config)
end

function XLuckyTenant2Piece:SetConfigButRetainPositionAndUid(config)
    self:ClearButRetainPositionAndUid()
    self:__SetConfig(config)
end

---@param config XTable.XTableLuckyTenant2Chess
function XLuckyTenant2Piece:__SetConfig(config)
    if config then
        self._Id = config.Id
        self._Amount = 1
        self._PieceType = config.Type
        self._Quality = config.Quality
        self._Name = config.Name
        self._Desc = config.Desc
        self._InitialValue = config.Value
        self._Value = config.Value
        self._Icon = config.Icon
        self._IsCanDelete = config.CanDelete
        self._IsCanDie = config.CanDie
        self._SkillId = config.SkillId
        self._Tag = config.Tag
        self._ValueUponDeletion = config.ValueUponDeletion
        self._InitialValueUponDeletion = self._ValueUponDeletion

        -- 二期新增字段
        self._BondId = config.BondId or ""
        self._CanUseForBond = config.CanUseForBond == 1
        self._DefaultLevel = config.DefaultLevel or 0
        self._Level = self._DefaultLevel
        self._CanUpgrade = config.CanUpgrade == 1
        self._CanBeEliminated = config.CanBeEliminated == 1

        local isProp = config.Type == XLuckyTenant2Enum.Item.DeleteProp
            or config.Type == XLuckyTenant2Enum.Item.RefreshProp
        self._IsProp = isProp
        self._IsPiece = not isProp
    else
        XLog.Error("[XLuckyTenant2Piece] 设置棋子config失败")
    end
end

function XLuckyTenant2Piece:SetUid(uid)
    self._Uid = uid
end

function XLuckyTenant2Piece:Set(uid, config)
    self:SetConfigAndClear(config)
    self:SetUid(uid)
end

function XLuckyTenant2Piece:SetPosition(x, y)
    self._X = x
    self._Y = y
    self._IsOnBoard = (x > 0 and y > 0)
end

function XLuckyTenant2Piece:IsOnBoard()
    return self._IsOnBoard
end

function XLuckyTenant2Piece:GetName()
    if XMain.IsZlbDebug then
        return self._Name .. "\nid:" .. self._Id .. " Uid:" .. self._Uid
    end
    return self._Name
end

function XLuckyTenant2Piece:GetId()
    return self._Id
end

function XLuckyTenant2Piece:GetUid()
    return self._Uid
end

function XLuckyTenant2Piece:GetQuality()
    return self._Quality
end

function XLuckyTenant2Piece:SetQuality(quality)
    local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
    local maxQuality = XLuckyTenant2Enum.GameConstants and XLuckyTenant2Enum.GameConstants.MAX_QUALITY or 5
    self._Quality = math.min(maxQuality, math.max(0, quality or 0))
end

function XLuckyTenant2Piece:AddQuality(amount)
    self:SetQuality((self._Quality or 0) + amount)
end

function XLuckyTenant2Piece:GetPieceType()
    return self._PieceType
end

---获取基础金币值
---@return number
function XLuckyTenant2Piece:GetBaseValue()
    return self._Value
end

function XLuckyTenant2Piece:GetBaseValueWithoutBond()
    return self._Value - self:_GetBondBaseValueDeltaSum()
end

function XLuckyTenant2Piece:GetLevel()
    return self._Level
end

function XLuckyTenant2Piece:SetLevel(level)
    local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
    local constants = XLuckyTenant2Enum.GameConstants

    -- 根据羁绊类型确定等级上限（角色羁绊棋子使用缓存的上限，其他棋子最大等级99）
    local maxLevel = constants.MAX_PIECE_LEVEL
    local bondId = tonumber(self:GetBondId())
    if bondId then
        if bondId == XLuckyTenant2Enum.Bond.Role then
            maxLevel = XLuckyTenant2Piece.GetRoleMaxLevel()
        elseif bondId == XLuckyTenant2Enum.Bond.Weapon then
            maxLevel = XLuckyTenant2Piece.GetWeaponMaxLevel()
        else
            maxLevel = constants.MAX_PIECE_LEVEL
        end
    end

    self._Level = math.min(maxLevel, math.max(constants.MIN_PIECE_LEVEL, level))
end

function XLuckyTenant2Piece:AddLevel(amount)
    self:SetLevel(self._Level + amount)
end

function XLuckyTenant2Piece:GetBondId()
    return self._BondId
end

function XLuckyTenant2Piece:CanUseForBond()
    return self._CanUseForBond
end

function XLuckyTenant2Piece:CanUpgrade()
    return self._CanUpgrade
end

function XLuckyTenant2Piece:CanBeEliminated()
    return self._CanBeEliminated
end

-- ==================== 状态相关方法 ====================

---@param stateType number 状态类型
---@return boolean
function XLuckyTenant2Piece:HasState(stateType)
    return self._States[stateType] ~= nil
end

---@param stateType number 状态类型
---@return XLuckyTenant2State
function XLuckyTenant2Piece:GetState(stateType)
    return self._States[stateType]
end

---@return XLuckyTenant2State[]
function XLuckyTenant2Piece:GetAllStates()
    local result = {}
    for _, state in pairs(self._States) do
        table.insert(result, state)
    end
    return result
end

---@param state XLuckyTenant2State
function XLuckyTenant2Piece:AddState(state)
    local stateType = state:GetStateType()
    -- 如果已存在相同状态，不重复添加（根据需求文档3.1.7）
    if not self._States[stateType] then
        self._States[stateType] = state
    end
end

---@param stateType number 状态类型
function XLuckyTenant2Piece:RemoveState(stateType)
    self._States[stateType] = nil
end

---@param stateType number 状态类型
---@param skillId number 技能id
---@param remainRounds number 剩余回合数
function XLuckyTenant2Piece:AddStateByType(stateType, skillId, remainRounds)
    local state = XLuckyTenant2State.New(stateType, skillId, remainRounds)
    self:AddState(state)
end

-- 暂停所有状态的倒计时（在背包中时）
function XLuckyTenant2Piece:PauseStates()
    for _, state in pairs(self._States) do
        state:Pause()
    end
end

-- 恢复所有状态的倒计时（回到棋盘时）
function XLuckyTenant2Piece:ResumeStates()
    for _, state in pairs(self._States) do
        state:Resume()
    end
end

-- 减少所有状态的倒计时
-- @return table 返回过期的状态列表 {stateType, state, stateSkillId}
function XLuckyTenant2Piece:ReduceStateRounds(amount)
    local expiredStates = {}
    local statesToRemove = {}
    local TriggerState = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum").TriggerState

    for stateType, state in pairs(self._States) do
        local remainRoundsBefore = state:GetRemainRounds()
        state:ReduceRounds(amount)
        local remainRoundsAfter = state:GetRemainRounds()
        local isExpired = state:IsExpired()
        local stateSkillId = state:GetSkillId()

        -- 添加调试日志（仅对子虫和死亡状态）
        if self:GetId() == PieceId.Subworm and stateType == TriggerState.Death then
            XMVCA.XLuckyTenant2:Print(string.format("[ReduceStateRounds] 子虫[ID:%d] 死亡状态: 减少前=%d, 减少后=%d, 是否过期=%s, 状态技能ID=%d",
                self:GetId(), remainRoundsBefore, remainRoundsAfter, tostring(isExpired), stateSkillId))
        end

        if isExpired then
            table.insert(expiredStates, {
                stateType = stateType,
                state = state,
                stateSkillId = stateSkillId
            })
            table.insert(statesToRemove, stateType)
        end
    end

    -- 移除过期的状态（在收集完过期状态信息后）
    for _, stateType in ipairs(statesToRemove) do
        self:RemoveState(stateType)
    end

    return expiredStates
end

-- ==================== 技能相关方法 ====================

---@param model XLuckyTenant2Model
---@return XLuckyTenant2ChessSkill[]
function XLuckyTenant2Piece:GetSkills(model)
    if not self._Skills then
        if not model then
            XMVCA.XLuckyTenant2:Print("[XLuckyTenant2Piece] 删除技能未初始化的棋子")
            return {}
        end
        self._Skills = {}
        local skillId = self._SkillId
        if skillId then
            for i = 1, #skillId do
                local id = skillId[i]
                if id and id > 0 then
                    ---@type XLuckyTenant2ChessSkill
                    local skill = XLuckyTenant2ChessSkill.New()
                    skill:Set(self, id, model)
                    self._Skills[#self._Skills + 1] = skill
                end
            end
        end
    end
    return self._Skills
end

-- 清除技能（重置棋盘时重新赋值）
function XLuckyTenant2Piece:ClearSkills()
    self._Skills = false
end

-- ==================== 其他方法 ====================

function XLuckyTenant2Piece:Clear()
    self._Id = 0
    self._Uid = 0
    self._PieceType = 0
    self._Quality = 0
    self._Name = ""
    self._Desc = false
    self._InitialValue = 0
    self._ScoreValidThisRound = 0
    self._Icon = false
    self._IsCanDelete = false
    self._IsCanDie = false
    self._SkillId = false
    self._Tag = false
    self._Amount = 0
    self._Value = 0
    self._ValueUponDeletion = 0
    self._InitialValueUponDeletion = 0
    self._BondBaseValueDeltas = {}
    self._BondDeletionValueDeltas = {}
    self._IsPiece = false
    self._IsProp = false
    self._Skills = false
    self._IsDeleted = false -- 清除删除标记
    self:ResetPosition()
    self._BondId = ""
    self._CanUseForBond = false
    self._Level = 0
    self._DefaultLevel = 0
    self._CanUpgrade = false
    self._CanBeEliminated = false
    self._States = {}
    self._IsDescDynamic = true
    self._DynamicDesc = false
    self._IsHideRound = false
end

function XLuckyTenant2Piece:ClearButRetainPositionAndUid()
    local x, y = self._X, self._Y
    local uid = self._Uid
    self:Clear()
    self._X = x
    self._Y = y
    self._Uid = uid
    self._IsOnBoard = (x > 0 and y > 0)
end

function XLuckyTenant2Piece:ClearEveryTurn()
    self._ScoreValidThisRound = 0
    -- 状态倒计时在回合结束时统一处理
end

function XLuckyTenant2Piece:GetPosition()
    return self._X, self._Y
end

function XLuckyTenant2Piece:IsPiece()
    return self._IsPiece
end

function XLuckyTenant2Piece:IsCanDelete()
    return self._IsCanDelete
end

function XLuckyTenant2Piece:IsProp()
    return self._IsProp
end

---检查棋子是否已被标记为删除
---@return boolean
function XLuckyTenant2Piece:IsDeleted()
    return self._IsDeleted == true
end

---标记棋子为已删除（延迟回收）
function XLuckyTenant2Piece:MarkAsDeleted()
    self._IsDeleted = true
end

---清除删除标记（用于对象池复用）
function XLuckyTenant2Piece:ClearDeletedFlag()
    self._IsDeleted = false
end

function XLuckyTenant2Piece:GetAmount()
    return self._Amount
end

function XLuckyTenant2Piece:SetAmount(value)
    if self._IsPiece and value ~= 1 then
        XLog.Error("[XLuckyTenant2Piece] 棋子数量只能为1")
        return
    end
    self._Amount = value
end

function XLuckyTenant2Piece:GetInitialValue()
    return self._InitialValue
end

---获取本回合额外金币值（临时值）
---@return number
function XLuckyTenant2Piece:GetRoundBonusValue()
    return self._ScoreValidThisRound
end

---获取总金币值（基础值 + 回合加成）
---@return number
function XLuckyTenant2Piece:GetTotalValue()
    return self._Value + self._ScoreValidThisRound
end

---获取消除时的得分
---@return number
function XLuckyTenant2Piece:GetValueUponDeletion()
    return self._ValueUponDeletion
end

function XLuckyTenant2Piece:GetInitialValueUponDeletion()
    return self._InitialValueUponDeletion
end

function XLuckyTenant2Piece:GetValueUponDeletionWithoutBond()
    return self._ValueUponDeletion - self:_GetBondDeletionValueDeltaSum()
end

function XLuckyTenant2Piece:GetBondDeletionValueDelta(key)
    return self._BondDeletionValueDeltas[key] or 0
end

---获取羁绊技能对基础金币的增益总和
---@return number 增益总和
function XLuckyTenant2Piece:GetBondValueDelta()
    return self:_GetBondBaseValueDeltaSum()
end

function XLuckyTenant2Piece:SetValueUponDeletion(value)
    self._ValueUponDeletion = value or 0
end

function XLuckyTenant2Piece:AddValueUponDeletion(value)
    if value and value ~= 0 then
        self._ValueUponDeletion = self._ValueUponDeletion + value
    end
end

function XLuckyTenant2Piece:_GetBondBaseValueDeltaSum()
    local sum = 0
    for _, delta in pairs(self._BondBaseValueDeltas) do
        sum = sum + (delta or 0)
    end
    return sum
end

function XLuckyTenant2Piece:_GetBondDeletionValueDeltaSum()
    local sum = 0
    for _, delta in pairs(self._BondDeletionValueDeltas) do
        sum = sum + (delta or 0)
    end
    return sum
end

function XLuckyTenant2Piece:ApplyBondBaseValueDelta(key, value)
    local newDelta = value or 0
    local oldSum = self:_GetBondBaseValueDeltaSum()
    self._BondBaseValueDeltas[key] = newDelta
    local newSum = self:_GetBondBaseValueDeltaSum()
    if newSum ~= oldSum then
        self._Value = self._Value + (newSum - oldSum)
        -- XLog.Error(string.format("[ApplyBondBaseValueDelta] 棋子[ID:%d] 基础金币增益变化: 旧=%d, 新=%d, 新值=%d", self:GetId(), oldSum, newSum, self._Value))
    end
end

---设置羁绊技能对基础金币的增益（别名，便于理解）
---@param key string 技能key
---@param value number 增益值
function XLuckyTenant2Piece:SetBondValueDelta(key, value)
    self:ApplyBondBaseValueDelta(key, value)
end

function XLuckyTenant2Piece:ApplyBondDeletionValueDelta(key, value)
    local newDelta = value or 0
    local oldSum = self:_GetBondDeletionValueDeltaSum()
    self._BondDeletionValueDeltas[key] = newDelta
    local newSum = self:_GetBondDeletionValueDeltaSum()
    if newSum ~= oldSum then
        self._ValueUponDeletion = self._ValueUponDeletion + (newSum - oldSum)
    end
end

---设置羁绊技能对消除金币的增益（别名，便于理解）
---@param key string 技能key
---@param value number 增益值
function XLuckyTenant2Piece:SetBondDeletionValueDelta(key, value)
    self:ApplyBondDeletionValueDelta(key, value)
end

function XLuckyTenant2Piece:ResetBondValueDeltas()
    local baseSum = self:_GetBondBaseValueDeltaSum()
    if baseSum ~= 0 then
        self._Value = self._Value - baseSum
    end
    local deleteSum = self:_GetBondDeletionValueDeltaSum()
    if deleteSum ~= 0 then
        self._ValueUponDeletion = self._ValueUponDeletion - deleteSum
    end
    self._BondBaseValueDeltas = {}
    self._BondDeletionValueDeltas = {}
end

function XLuckyTenant2Piece:SetScoreValidThisRound(value)
    self._ScoreValidThisRound = math.min(999, value)
end

function XLuckyTenant2Piece:AddScoreValidThisRound(value)
    self._ScoreValidThisRound = math.min(999, self._ScoreValidThisRound + value)
end

function XLuckyTenant2Piece:SetValue(value)
    self._Value = value
end

function XLuckyTenant2Piece:AddValue(value)
    self._Value = self._Value + value
end

function XLuckyTenant2Piece:Equals(piece)
    return self._Uid == piece:GetUid()
end

---获取序列化参数消息（用于网络传输）
---@return table
function XLuckyTenant2Piece:GetParamsEncodeMessage()
    local amount = self._Amount
    local value = self._Value
    -- 如果值与初始值相同，不序列化以节省空间
    if value == self._InitialValue then
        value = nil
    end

    local valueUponDeletion = self._ValueUponDeletion
    if valueUponDeletion == self._InitialValueUponDeletion then
        valueUponDeletion = nil
    end

    local level = self._Level
    -- 如果等级为默认等级，不序列化
    if level == self._DefaultLevel then
        level = nil
    end

    local scoreValidThisRound = self._ScoreValidThisRound
    -- 如果本回合临时分数为0，不序列化
    if scoreValidThisRound == 0 then
        scoreValidThisRound = nil
    end

    -- 序列化状态信息（二期新增）
    local states = nil
    local stateList = self:GetAllStates()
    if #stateList > 0 then
        states = {}
        for i = 1, #stateList do
            local state = stateList[i]
            states[i] = {
                StateType = state:GetStateType(),
                SkillId = state:GetSkillId(),
                RemainRounds = state:GetRemainRounds(),
            }
        end
    end

    ---@class XLuckyTenant2PieceMessage
    local message = {
        Amount = amount,
        Value = value,
        ValueUponDeletion = valueUponDeletion,
        Level = level,
        ScoreValidThisRound = scoreValidThisRound,
        States = states,
    }

    return message
end

---获取序列化消息（用于网络传输）
---@return table
function XLuckyTenant2Piece:GetEncodeMessage()
    local params = XMessagePack.Encode(self:GetParamsEncodeMessage())
    local message = {
        ChessId = self:GetId(),
        Uid = self:GetUid(),
        ChessParams = params,
    }
    return message
end

----解码消息（用于从网络数据恢复棋子状态）
----@param message XLuckyTenant2PieceMessage
function XLuckyTenant2Piece:DecodeMessage(message)
    if not message then
        return
    end
    
    -- 恢复数量
    if message.Amount then
        self:SetAmount(message.Amount)
    end
    
    -- 恢复分数
    if message.Value then
        self:SetValue(message.Value)
    end
    
    -- 恢复删除分数
    if message.ValueUponDeletion then
        self:SetValueUponDeletion(message.ValueUponDeletion)
    end
    
    -- 恢复等级
    if message.Level then
        self:SetLevel(message.Level)
    end
    
    -- 恢复本回合临时分数
    if message.ScoreValidThisRound then
        self:SetScoreValidThisRound(message.ScoreValidThisRound)
    end
    
    -- 恢复状态信息（二期新增）
    if message.States and #message.States > 0 then
        for i = 1, #message.States do
            local stateData = message.States[i]
            -- 应用状态（TriggerState）
            if stateData.StateType and stateData.SkillId then
                self:AddStateByType(stateData.StateType, stateData.SkillId, stateData.RemainRounds or 0)
            end
        end
    end
end

return XLuckyTenant2Piece
