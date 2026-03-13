---简易技能基类：仅持有技能配置数据（Id/Type/Params/SkillMode/Name），不绑定棋子
---用于羁绊/棋子配置解析出的「散装」技能，与 XLuckyTenant2ChessSkill（绑定棋子、条件等）区分
---@class XLuckyTenant2SkillBase
local XLuckyTenant2SkillBase = XClass(nil, "XLuckyTenant2SkillBase")

---@param skillId number 技能ID
---@param skillType number 技能类型
---@param params table 技能参数
---@param skillMode number 技能模式（可选，默认0）
---@param name string 技能名称（可选）
function XLuckyTenant2SkillBase:Ctor(skillId, skillType, params, skillMode, name)
    self._Id = skillId or 0
    self._Type = skillType or 0
    self._Params = params or {}
    self._SkillMode = skillMode or 0
    self._Name = name or ""
end

function XLuckyTenant2SkillBase:GetId()
    return self._Id
end

function XLuckyTenant2SkillBase:GetType()
    return self._Type
end

function XLuckyTenant2SkillBase:GetParams()
    return self._Params
end

function XLuckyTenant2SkillBase:GetSkillMode()
    return self._SkillMode or 0
end

---散装技能不绑定棋子，执行时由 context.piece 提供
---@return nil
function XLuckyTenant2SkillBase:GetPiece()
    return nil
end

function XLuckyTenant2SkillBase:GetName()
    return self._Name or ""
end

return XLuckyTenant2SkillBase
