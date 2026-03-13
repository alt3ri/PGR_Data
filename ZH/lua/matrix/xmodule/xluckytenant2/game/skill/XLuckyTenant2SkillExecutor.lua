local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")
local SkillType = XLuckyTenant2Enum.Skill

-- 子执行器（模块）
local SkillFinance = require("XModule/XLuckyTenant2/Game/Skill/Executors/XLuckyTenant2SkillFinance")
local SkillMonster = require("XModule/XLuckyTenant2/Game/Skill/Executors/XLuckyTenant2SkillMonster")
local SkillRole = require("XModule/XLuckyTenant2/Game/Skill/Executors/XLuckyTenant2SkillRole")
local SkillWeapon = require("XModule/XLuckyTenant2/Game/Skill/Executors/XLuckyTenant2SkillWeapon")
local SkillBox = require("XModule/XLuckyTenant2/Game/Skill/Executors/XLuckyTenant2SkillBox")
local SkillRedTide = require("XModule/XLuckyTenant2/Game/Skill/Executors/XLuckyTenant2SkillRedTide")

---技能执行上下文
---@class XLuckyTenant2SkillContext
---@field piece XLuckyTenant2Piece 技能所属棋子
---@field skill XLuckyTenant2ChessSkill 当前技能（由SkillExecutor填充）
---@field proxy XLuckyTenant2OperationProxy 操作代理
---@field model XLuckyTenant2Model 模型实例
---@field game XLuckyTenant2Game 游戏实例
---@field board XLuckyTenant2ChessBoard 棋盘
---@field bag XLuckyTenant2Bag 背包
---@field round number 当前回合数
---@field times number 执行次数（第几次计算）

---技能执行器（类）
---@class XLuckyTenant2SkillExecutor
local XLuckyTenant2SkillExecutor = XClass(nil, "XLuckyTenant2SkillExecutor")

function XLuckyTenant2SkillExecutor:Ctor()
    self._SkillExecutors = {}
    self._StateSkillIdCache = {}

    -- 注册各子执行器
    SkillFinance.Register(self)
    SkillMonster.Register(self)
    SkillRole.Register(self)
    SkillWeapon.Register(self)
    SkillBox.Register(self)
    SkillRedTide.Register(self)
end

---注册技能执行器
---@param skillType number 技能类型
---@param executorFunc function 执行函数
function XLuckyTenant2SkillExecutor:Register(skillType, executorFunc)
    self._SkillExecutors[skillType] = executorFunc
end

---初始化状态技能ID缓存
---@param model XLuckyTenant2Model 模型实例
function XLuckyTenant2SkillExecutor:InitStateSkillIds(model)
    if not model then
        return
    end

    self._StateSkillIdCache = {}

    local stateSkillTypes = {
        SkillType.Type210,
        SkillType.Type209,
        SkillType.Type508,
        SkillType.Type102,
        SkillType.Type506,
        SkillType.Type208,
        SkillType.Type301,
        SkillType.Type408,
    }

    local allSkillConfigs = model:GetLuckyTenant2ChessSkillConfigs()
    if allSkillConfigs then
        for skillId, skillConfig in pairs(allSkillConfigs) do
            if skillConfig then
                local skillType = skillConfig.Type
                for _, targetType in ipairs(stateSkillTypes) do
                    if skillType == targetType then
                        if not self._StateSkillIdCache[skillType] then
                            self._StateSkillIdCache[skillType] = {}
                        end
                        table.insert(self._StateSkillIdCache[skillType], skillId)
                        break
                    end
                end
            end
        end
    end
end

---获取指定类型的状态技能ID列表
---@param skillType number 技能类型
---@return number[]
function XLuckyTenant2SkillExecutor:GetStateSkillIds(skillType)
    return self._StateSkillIdCache[skillType] or {}
end

---获取指定类型的状态技能ID（返回第一个）
---@param skillType number 技能类型
---@return number|nil
function XLuckyTenant2SkillExecutor:GetStateSkillId(skillType)
    local skillIds = self._StateSkillIdCache[skillType]
    if skillIds and #skillIds > 0 then
        return skillIds[1]
    end
    return nil
end

---统一处理stateSkillId：先尝试作为技能类型查找，再尝试作为技能ID查找
---@param stateSkillId number 状态技能ID（可能是技能类型或技能ID）
---@param model XLuckyTenant2Model 模型实例
---@return number|nil, XTableLuckyTenant2ChessSkill|nil 实际技能ID, 技能配置
function XLuckyTenant2SkillExecutor:ResolveStateSkillId(stateSkillId, model)
    if not stateSkillId or stateSkillId <= 0 or not model then
        return nil, nil
    end

    local actualSkillId = self:GetStateSkillId(stateSkillId)
    local skillConfig = nil

    if actualSkillId then
        local config = model:GetLuckyTenant2ChessSkillConfigById(actualSkillId)
        if config then
            return actualSkillId, config
        end
    end

    local config = model:GetLuckyTenant2ChessSkillConfigById(stateSkillId)
    if config then
        return stateSkillId, config
    end

    return nil, nil
end

---执行技能
---@param skill XLuckyTenant2ChessSkill 技能对象
---@param context XLuckyTenant2SkillContext 执行上下文
---@return boolean 是否执行成功
function XLuckyTenant2SkillExecutor:Execute(skill, context)
    local skillType = skill:GetType()

    local piece = context.piece or skill:GetPiece()
    if not piece or type(piece) ~= "table" then
        return false
    end

    local deletedFlag = rawget(piece, "_IsDeleted")

    if deletedFlag == nil then
        return false
    end

    if deletedFlag then
        return false
    end

    local executor = self._SkillExecutors[skillType]
    if executor then
        context.skill = skill
        local result = executor(skill, context)

        return result
    else
        XLog.Warning("[SkillExecutor] 未实现的技能类型: " .. skillType)
        return false
    end
end

---获取技能执行函数（用于测试或调试）
---@param skillType number 技能类型
---@return function|nil
function XLuckyTenant2SkillExecutor:GetExecutor(skillType)
    return self._SkillExecutors[skillType]
end

return XLuckyTenant2SkillExecutor
