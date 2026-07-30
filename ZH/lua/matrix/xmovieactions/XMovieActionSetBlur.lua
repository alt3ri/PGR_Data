local pairs = pairs
local tableInsert = table.insert
local SPINE_INDEX_OFFSET = 100
local ALL_BG_INDEX = 999
local TARGET_START_INDEX = 4
local TARGET_END_INDEX = 9
local GRAYSCALE_PARAM_INDEX = 11
local GRAYSCALE_DURATION_PARAM_INDEX = 12

-- BlurType: 0=关闭, 1=Directional, 2=Radial, 3=Gaussian
local BLUR_TYPE = {
    NONE = 0,
    DIRECTIONAL = 1,
    RADIAL = 2,
    GAUSSIAN = 3,
}

---@class XMovieActionSetBlur
---@field UiRoot XUiMovie
local XMovieActionSetBlur = XClass(XMovieActionBase, "XMovieActionSetBlur")

-- 把 "a|b|c|..." 串按 BlurType 解析为 extra 表
local function ParseExtra(blurType, str)
    if string.IsNilOrEmpty(str) then
        return nil
    end
    local parts = string.Split(str, "|")
    if blurType == BLUR_TYPE.DIRECTIONAL then
        return { angle = tonumber(parts[1]) or 0 }
    elseif blurType == BLUR_TYPE.RADIAL then
        return {
            focusX = tonumber(parts[1]) or 0.5,
            focusY = tonumber(parts[2]) or 0.5,
            radius = tonumber(parts[3]) or 0.2,
            gradient = tonumber(parts[4]) or 0.5,
            noiseScale = tonumber(parts[5]) or 0.7,
        }
    end
    return nil
end

function XMovieActionSetBlur:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber

    self.BlurType = paramToNumber(params[1])
    self.Strength = XMath.Clamp(paramToNumber(params[2]), 0, 1)
    self.Duration = paramToNumber(params[3])
    self.HasGrayScale = not string.IsNilOrEmpty(params[GRAYSCALE_PARAM_INDEX])
    self.GrayScale = self.HasGrayScale and XMath.Clamp(paramToNumber(params[GRAYSCALE_PARAM_INDEX]), 0, 1) or nil
    self.GrayDuration = self.HasGrayScale and paramToNumber(params[GRAYSCALE_DURATION_PARAM_INDEX]) or 0

    self.IndexList = {}
    for i = TARGET_START_INDEX, TARGET_END_INDEX do
        local id = paramToNumber(params[i])
        if id ~= 0 then
            tableInsert(self.IndexList, id)
        end
    end

    self.Extra = ParseExtra(self.BlurType, params[10])
end

function XMovieActionSetBlur:_GetRunDuration()
    -- 快进重放时瞬时到终态，不播渐变
    return self.IsPassedRunning and 0 or self.Duration
end

function XMovieActionSetBlur:_GetGrayRunDuration()
    return self.IsPassedRunning and 0 or self.GrayDuration
end

function XMovieActionSetBlur:_ApplyToAllBg()
    local duration = self:_GetRunDuration()
    local grayDuration = self:_GetGrayRunDuration()
    local bgDic = self.UiRoot.UiMovieBg:GetBgDic()
    for _, bg in pairs(bgDic) do
        bg:SetBlur(self.BlurType, self.Strength, duration, self.Extra, self.GrayScale, grayDuration)
    end
end

function XMovieActionSetBlur:_ApplyToBg(index)
    if index == ALL_BG_INDEX then
        self:_ApplyToAllBg()
        return
    end
    local bgIndex = index % 1000
    local bg = self.UiRoot.UiMovieBg:GetBg(bgIndex)
    if bg then
        bg:SetBlur(self.BlurType, self.Strength, self:_GetRunDuration(), self.Extra, self.GrayScale, self:_GetGrayRunDuration())
    end
end

function XMovieActionSetBlur:OnRunning()
    local maxActorNum = XMovieConfigs.MAX_ACTOR_NUM
    local indexList = self.IndexList
    local hasTarget = false
    local duration = self:_GetRunDuration()
    local grayDuration = self:_GetGrayRunDuration()

    for _, index in pairs(indexList) do
        if index > 0 and index <= maxActorNum then
            ---@type XUiGridMovieActor
            local actor = self.UiRoot:GetActor(index)
            actor:SetBlur(self.BlurType, self.Strength, duration, self.Extra, self.GrayScale, grayDuration)
            hasTarget = true
        elseif index > SPINE_INDEX_OFFSET and index <= SPINE_INDEX_OFFSET + maxActorNum then
            -- Spine 走的是非 UGUI 渲染（XUiMaterialController 一类），
            -- XUiBlurController 依赖 Graphic，本期不支持
            XLog.Warning(string.format("[SetBlur] Spine 演员 index=%s 暂不支持模糊，跳过", tostring(index)))
            hasTarget = true
        else
            self:_ApplyToBg(index)
            hasTarget = true
        end
    end

    -- 没传目标：默认作用到所有立绘 + 所有背景（与 SetGray 行为对齐）
    if not hasTarget then
        self:_ApplyToAllBg()
        for index = 1, maxActorNum do
            ---@type XUiGridMovieActor
            local actor = self.UiRoot:GetActor(index)
            actor:SetBlur(self.BlurType, self.Strength, duration, self.Extra, self.GrayScale, grayDuration)
        end
    end
end

function XMovieActionSetBlur:GetBlurType()
    return self.BlurType
end

function XMovieActionSetBlur:IsPassedActionRun(index)
    -- 关闭模糊（strength=0 / blurType=0）的节点不需要重放
    if (self.Strength == 0 or self.BlurType == BLUR_TYPE.NONE) and (not self.HasGrayScale or self.GrayScale == 0) then
        return false
    end
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

---@param action XMovieActionBase
function XMovieActionSetBlur:IsPassedActionCovered(action)
    return action:GetType() == self:GetType()
end

function XMovieActionSetBlur:OnPassedActionRun()
    self.IsPassedRunning = true
    self:OnRunning()
    self.IsPassedRunning = false
end

return XMovieActionSetBlur
