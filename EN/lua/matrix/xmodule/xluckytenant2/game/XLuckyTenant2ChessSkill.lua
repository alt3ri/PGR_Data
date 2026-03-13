local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local XLuckyTenant2Condition = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Condition")
local XLuckyTenant2SkillBase = require("XModule/XLuckyTenant2/Game/XLuckyTenant2SkillBase")

---@class XLuckyTenant2ChessSkill : XLuckyTenant2SkillBase
local XLuckyTenant2ChessSkill = XClass(XLuckyTenant2SkillBase, "XLuckyTenant2ChessSkill")

function XLuckyTenant2ChessSkill:Ctor()
    self._Id = 0
    self._Type = 0
    self._Name = ""
    self._Desc = ""
    self._Params = false
    self._Score = 0
    self._Priority = 0
    ---@type XLuckyTenant2Piece
    self._Piece = false
    self._IsPassive = false
    self._IsEffectUponJoining = false
    self._EffectJustOnFirstRound = false
    self._Condition = ""  -- 二期新增：condition字段
    self._SkillMode = 0  -- 新增：技能模式（用于区分相同SkillType但不同行为模式的技能）
end

---@param piece XLuckyTenant2Piece
---@param skillId number
---@param model XLuckyTenant2Model
function XLuckyTenant2ChessSkill:Set(piece, skillId, model)
    ---@type XTableLuckyTenant2ChessSkill
    local config = model:GetLuckyTenant2ChessSkillConfigById(skillId)
    if not config then
        XLog.Error("[XLuckyTenant2ChessSkill] 技能配置不存在:" .. tostring(skillId))
        return
    end
    self._Name = config.Name
    self._Desc = config.Desc
    self._Type = config.Type
    self._IsEffectUponJoining = config.IsEffectUponJoining == 1
    self._Params = config.Params
    self._Priority = config.Priority
    self._Score = config.Score
    self._IsPassive = config.IsPassive == 1
    self._Piece = piece
    self._Id = skillId
    self._EffectJustOnFirstRound = config.EffectJustOnFirstRound == 1
    self._Condition = config.Condition or ""  -- 二期新增
end

function XLuckyTenant2ChessSkill:ClearPiece()
    self._Piece = false
end

function XLuckyTenant2ChessSkill:SetPassiveSkill(skillId, model)
    self:Set(nil, skillId, model)
end

---检查技能是否满足执行条件
---@param model XLuckyTenant2Model
---@param context table 上下文（包含board、bag、game等）
---@return boolean 是否可以执行
function XLuckyTenant2ChessSkill:CanExecute(model, context)
    if not self._Condition or self._Condition == "" then
        return true  -- 无条件，直接执行
    end
    
    -- 确保piece在context中
    if not context.piece then
        context.piece = self._Piece
    end
    
    return XLuckyTenant2Condition.Evaluate(model, self._Condition, context)
end

function XLuckyTenant2ChessSkill:GetId()
    return self._Id
end

function XLuckyTenant2ChessSkill:GetType()
    return self._Type
end

function XLuckyTenant2ChessSkill:GetName()
    return self._Name
end

function XLuckyTenant2ChessSkill:GetDesc()
    return self._Desc
end

function XLuckyTenant2ChessSkill:GetParams()
    return self._Params
end

function XLuckyTenant2ChessSkill:GetScore()
    return self._Score
end

function XLuckyTenant2ChessSkill:GetPriority()
    return self._Priority
end

function XLuckyTenant2ChessSkill:GetPiece()
    return self._Piece
end

function XLuckyTenant2ChessSkill:IsPassive()
    return self._IsPassive
end

function XLuckyTenant2ChessSkill:IsEffectUponJoining()
    return self._IsEffectUponJoining
end

function XLuckyTenant2ChessSkill:GetCondition()
    return self._Condition
end

---设置技能模式
---@param skillMode number 技能模式（0=默认，1=升级等级模式，2=减少倒计时模式等）
function XLuckyTenant2ChessSkill:SetSkillMode(skillMode)
    self._SkillMode = skillMode or 0
end

---获取技能模式
---@return number 技能模式
function XLuckyTenant2ChessSkill:GetSkillMode()
    return self._SkillMode or 0
end

return XLuckyTenant2ChessSkill

