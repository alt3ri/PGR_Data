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

---播放动画（由 UI 层调用）
---@param ui XUiLuckyTenant2Game UI 实例
function XLuckyTenant2AnimationGroup:PlayAnimations(ui)
    if not ui then
        return
    end
    
    local animationData = self._AnimationData
    if not animationData or #animationData == 0 then
        return
    end
    
    -- 遍历所有动画数据，播放对应的动画
    for idx, animData in ipairs(animationData) do
        local animType = animData.type
        if animType == XLuckyTenant2Enum.AnimationType.GetScore then
            -- 播放分数动画
            self:_PlayGetScoreAnimation(ui, animData)
        elseif animType == XLuckyTenant2Enum.AnimationType.AddPiece then
            -- 播放添加棋子动画
            self:_PlayAddPieceAnimation(ui, animData)
        elseif animType == XLuckyTenant2Enum.AnimationType.DeletePiece then
            -- 播放删除棋子动画
            self:_PlayDeletePieceAnimation(ui, animData)
        elseif animType == XLuckyTenant2Enum.AnimationType.UpdatePiece then
            -- 播放更新棋子动画
            self:_PlayUpdatePieceAnimation(ui, animData)
        elseif animType == XLuckyTenant2Enum.AnimationType.ActivateSkillEnable then
            -- 主动发动技能的棋子播放
            self:_PlayActivateSkillEnableAnimation(ui, animData)
        elseif animType == XLuckyTenant2Enum.AnimationType.AffectedBySkillEnable then
            -- 受技能影响的棋子播放
            self:_PlayAffectedBySkillEnableAnimation(ui, animData)
        end
    end
end

---播放分数动画
---@param ui XUiLuckyTenant2Game UI 实例
---@param animData table 动画数据
function XLuckyTenant2AnimationGroup:_PlayGetScoreAnimation(ui, animData)
    if not ui or not animData then
        return
    end
    
    local x = animData.x or 0
    local y = animData.y or 0
    local value = animData.value or 0
    
    if value > 0 and ui.PlayAnimationGetScore then
        local duration = 0.7  -- 动画持续时间（秒）
        ui:PlayAnimationGetScore(x, y, value, duration, function()
            -- 动画完成回调（已在 UI 层处理分数更新）
        end)
    end
end

---播放添加棋子动画
---@param ui XUiLuckyTenant2Game UI 实例
---@param animData table 动画数据
function XLuckyTenant2AnimationGroup:_PlayAddPieceAnimation(ui, animData)
    if not ui or not animData then
        return
    end
    
    local pieceId = animData.pieceId or 0
    local x = animData.x
    local y = animData.y
    
    if pieceId > 0 and ui.PlayAnimationAddPiece then
        ui:PlayAnimationAddPiece(pieceId, x, y)
    end
end

---播放删除棋子动画
---@param ui XUiLuckyTenant2Game UI 实例
---@param animData table 动画数据（含 pieceId 用于区分宝盒/非宝盒消除特效）
function XLuckyTenant2AnimationGroup:_PlayDeletePieceAnimation(ui, animData)
    if not ui or not animData then
        return
    end
    
    local pieceUid = animData.pieceUid or 0
    local x = animData.x or 0
    local y = animData.y or 0
    local fromPieceUid = animData.fromPieceUid or 0
    local pieceId = animData.pieceId or 0
    
    if pieceUid > 0 and ui.PlayAnimationDeletePiece then
        ui:PlayAnimationDeletePiece(pieceUid, x, y, fromPieceUid, pieceId, self._SkillId)
    end
end

---播放更新棋子动画
---@param ui XUiLuckyTenant2Game UI 实例
---@param animData table 动画数据
function XLuckyTenant2AnimationGroup:_PlayUpdatePieceAnimation(ui, animData)
    if not ui or not animData then
        return
    end
    
    local pieceUid = animData.pieceUid or 0
    
    if pieceUid > 0 and ui.PlayAnimationUpdatePiece then
        ui:PlayAnimationUpdatePiece(pieceUid, self._SkillId)
    end
end

---播放主动发动技能动画（发动技能的棋子）
---@param ui XUiLuckyTenant2Game UI 实例
---@param animData table 动画数据 { pieceUid, x, y }
function XLuckyTenant2AnimationGroup:_PlayActivateSkillEnableAnimation(ui, animData)
    if not ui or not animData then
        return
    end
    local pieceUid = animData.pieceUid or 0
    local x = animData.x or 0
    local y = animData.y or 0
    local skillId = self._SkillId or 0
    if (pieceUid > 0 or (x > 0 and y > 0)) and ui.PlayAnimationActivateSkillEnable then
        ui:PlayAnimationActivateSkillEnable(pieceUid, x, y, skillId)
    end
end

---播放受技能影响动画（被技能影响的棋子）
---@param ui XUiLuckyTenant2Game UI 实例
---@param animData table 动画数据 { pieceUid, x, y }
function XLuckyTenant2AnimationGroup:_PlayAffectedBySkillEnableAnimation(ui, animData)
    if not ui or not animData then
        return
    end
    local pieceUid = animData.pieceUid or 0
    local x = animData.x or 0
    local y = animData.y or 0
    local skillId = self._SkillId or 0
    if (pieceUid > 0 or (x > 0 and y > 0)) and ui.PlayAnimationAffectedBySkillEnable then
        ui:PlayAnimationAffectedBySkillEnable(pieceUid, x, y, skillId)
    end
end

return XLuckyTenant2AnimationGroup
