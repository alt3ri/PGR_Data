local Base = require("Skill/Common/XSkillBase")

---@class XSkill_1055001 : XSkillBase
local XSkill_1055001 = XDlcScriptManager.RegSkillScript(1055001, "XSkill_1055001", Base)

function XSkill_1055001:ScriptInit(isGainControl)
    Base.ScriptInit(self, isGainControl)
    -- 条件1：只能在地面释放，2 表示地面
    self._groundOnlyState = 2
    -- 条件2/3：前闪或后闪
    self._frontDodgeId = 1055011
    self._backDodgeId = 1055012
    self._currentActionIds = {
        self._frontDodgeId,
        self._backDodgeId,
    }
    -- 条件4：前闪/后闪动作里的技能时间类型 = 12
    self._dodgeActionTimingType = 12
end

function XSkill_1055001:IsGroundStateMatched()
    -- 地面条件：当前不在空中时通过
    if self._groundOnlyState == 2 then
        return not self._proxy:CheckNpcOnAir(self._uuid)
    end

    return false
end

function XSkill_1055001:GetDodgeActionInProgress()
    -- 检查当前动作是否为前闪或后闪，返回正在播放的闪避动作 ID
    for _, actionId in ipairs(self._currentActionIds) do
        if self._proxy:CheckNpcCurrentAction(self._uuid, actionId) then
            return actionId
        end
    end

    return nil
end

function XSkill_1055001:CheckCastCondition(actionId)
    -- 第一步：先继承 Base 的通用释放检查，失败时不再继续判断表条件
    if not Base.CheckCastCondition(self, actionId, 0) then
        -- print("Skill_1055001 CheckCastCondition: Base.CheckCastCondition(actionId, 0) 未通过")
        return false
    end

    -- 第二步：必须满足地面条件
    if not self:IsGroundStateMatched() then
        -- print("Skill_1055001 CheckCastCondition: 地面条件未通过")
        return false
    end

    -- 第三步：如果当前正在前闪或后闪，检查当前闪避动作的技能时间类型 = 12
    local dodgeActionId = self:GetDodgeActionInProgress()
    if dodgeActionId then
        -- print("Skill_1055001 CheckCastCondition: 当前动作是 " .. tostring(dodgeActionId) ..
            -- " 前闪/后闪，检查技能时间类型 = " .. tostring(self._dodgeActionTimingType))
        return self._proxy:CheckActionTiming(self._uuid, self._dodgeActionTimingType)
    end

    -- 第四步：不在前闪/后闪期间时，Base 与地面条件通过即可释放
    -- print("Skill_1055001 CheckCastCondition: 当前动作不是 " .. tostring(self._frontDodgeId) ..
        -- " 前闪或 " .. tostring(self._backDodgeId) .. " 后闪，Base 与地面条件已通过")
    return true
end

return XSkill_1055001
