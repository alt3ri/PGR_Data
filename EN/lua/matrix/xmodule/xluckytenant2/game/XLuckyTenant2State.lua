local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")

---@class XLuckyTenant2State
local XLuckyTenant2State = XClass(nil, "XLuckyTenant2State")

---@param stateType number 状态类型（TriggerState枚举）
---@param skillId number 状态绑定的技能id
---@param remainRounds number 剩余回合数（可选）
function XLuckyTenant2State:Ctor(stateType, skillId, remainRounds)
    self._StateType = stateType
    self._SkillId = skillId
    self._RemainRounds = remainRounds or 0
    self._IsPaused = false -- 是否暂停（在背包中时暂停）
end

function XLuckyTenant2State:GetStateType()
    return self._StateType
end

function XLuckyTenant2State:GetSkillId()
    return self._SkillId
end

function XLuckyTenant2State:SetSkillId(skillId)
    self._SkillId = skillId
end

function XLuckyTenant2State:GetRemainRounds()
    return self._RemainRounds
end

function XLuckyTenant2State:SetRemainRounds(rounds)
    self._RemainRounds = rounds
end

function XLuckyTenant2State:ReduceRounds(amount)
    if not self._IsPaused then
        -- 永久状态（RemainRounds < 0）不会被减少
        if self._RemainRounds < 0 then
            return
        end
        self._RemainRounds = math.max(0, self._RemainRounds - amount)
    end
end

function XLuckyTenant2State:IsExpired()
    -- 永久状态：RemainRounds < 0 表示永久状态，不会过期
    -- RemainRounds = 0 表示已过期
    -- RemainRounds > 0 表示还有剩余回合数
    return self._RemainRounds == 0
end

function XLuckyTenant2State:Pause()
    self._IsPaused = true
end

function XLuckyTenant2State:Resume()
    self._IsPaused = false
end

function XLuckyTenant2State:IsPaused()
    return self._IsPaused
end

return XLuckyTenant2State
