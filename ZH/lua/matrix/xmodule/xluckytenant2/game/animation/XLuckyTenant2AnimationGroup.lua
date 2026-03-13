local XLuckyTenant2Enum = require("XModule/XLuckyTenant2/Game/XLuckyTenant2Enum")

---@class XLuckyTenant2AnimationGroup
---动画组：管理单个技能执行后的所有动画操作
local XLuckyTenant2AnimationGroup = XClass(nil, "XLuckyTenant2AnimationGroup")

---构造函数
---@param skillId number 技能ID
---@param pieceUid number 执行技能的棋子UID
---@param animationData table 该技能执行的所有动画数据列表（已提取好的动画数据）
---@param isFirst boolean 是否是第一个动画组（第一个立即开始，不需要等待间隔）
function XLuckyTenant2AnimationGroup:Ctor(skillId, pieceUid, animationData, isFirst)
    self._SkillId = skillId or 0
    self._PieceUid = pieceUid or 0
    
    -- 动画状态
    self._State = "waiting"  -- waiting: 等待开始, playing: 播放中, finished: 已完成
    self._WaitTime = 0  -- 等待时间（秒）
    self._ElapsedTime = 0  -- 已过去的时间
    self._MinDisplayTime = 0.3  -- 最小显示时间（秒），确保玩家能看到变化
    self._DisplayInterval = 0.5  -- 每个技能之间的间隔时间（秒）
    self._IsFirst = isFirst or false  -- 是否是第一个动画组
    
    -- 直接保存动画数据（不再从 Operations 中提取）
    self._AnimationData = animationData or {}
    -- 倒计时动画标记（用于 AnimationManager 排序，确保倒计时特效排在第一位）
    self._IsCountdown = false
end

---标记为倒计时动画组
function XLuckyTenant2AnimationGroup:SetIsCountdown(value)
    self._IsCountdown = value == true
end

---是否为倒计时动画组
---@return boolean
function XLuckyTenant2AnimationGroup:IsCountdown()
    return self._IsCountdown == true
end

---更新动画
---@param deltaTime number 时间增量（秒）
---@return boolean 是否已完成
function XLuckyTenant2AnimationGroup:Update(deltaTime)
    deltaTime = deltaTime or 0
    
    if self._State == "finished" then
        return true
    end
    
    if self._State == "waiting" then
        self._ElapsedTime = self._ElapsedTime + deltaTime
        
        -- 第一个动画组立即开始，后续动画组需要等待间隔时间
        local waitInterval = self._IsFirst and 0 or self._DisplayInterval
        
        if self._ElapsedTime >= waitInterval then
            -- 间隔时间已过，转为播放状态
            self._State = "playing"
            self._WaitTime = self._MinDisplayTime
            self._ElapsedTime = 0  -- 重置时间，开始计算显示时间
            return false
        end
        
        return false
    end
    
    if self._State == "playing" then
        self._ElapsedTime = self._ElapsedTime + deltaTime
        
        -- 如果达到了显示时间，标记为完成
        if self._ElapsedTime >= self._WaitTime then
            self._State = "finished"
            return true
        end
    end
    
    return false
end

---检查是否已完成
---@return boolean
function XLuckyTenant2AnimationGroup:IsFinish()
    return self._State == "finished"
end

---获取技能ID
---@return number
function XLuckyTenant2AnimationGroup:GetSkillId()
    return self._SkillId
end

---获取棋子UID
---@return number
function XLuckyTenant2AnimationGroup:GetPieceUid()
    return self._PieceUid
end

---设置最小显示时间
---@param time number 时间（秒）
function XLuckyTenant2AnimationGroup:SetMinDisplayTime(time)
    self._MinDisplayTime = time or 0.3
end

---设置显示间隔
---@param interval number 间隔时间（秒）
function XLuckyTenant2AnimationGroup:SetDisplayInterval(interval)
    self._DisplayInterval = interval or 0.5
end

---获取显示间隔（用于下一个动画组的延迟）
---@return number
function XLuckyTenant2AnimationGroup:GetDisplayInterval()
    return self._DisplayInterval
end

---获取动画数据列表
---@return table
function XLuckyTenant2AnimationGroup:GetAnimationData()
    return self._AnimationData
end

return XLuckyTenant2AnimationGroup
