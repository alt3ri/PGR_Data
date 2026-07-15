---@class XMovieActionBgScaleAnim
---@field UiRoot XUiMovie
local XMovieActionBgScaleAnim = XClass(XMovieActionBase, "XMovieActionBgScaleAnim")

---@param actionData XTableMovieNew
function XMovieActionBgScaleAnim:OnInit(actionData)
    self.PivotParams = XMVCA.XMovie:SplitParam(actionData.Params[1], "|", true)
    self.AnimTime = XMVCA.XMovie:ParamToNumber(actionData.Params[2])
    self.Scale = XMVCA.XMovie:ParamToNumber(actionData.Params[3])
    -- 参数4不配置时默认作用背景1（策划期望）
    local bgIndex = XMVCA.XMovie:ParamToNumber(actionData.Params[4])
    self.BgIndex = bgIndex == 0 and 1 or bgIndex
    self.CurveType = XMVCA.XMovie:ParamToCurveType(actionData.Params[5])
end

function XMovieActionBgScaleAnim:OnRunning()
    -- 背景1 可缩放（与旋转 113 不同，113 禁止图层1）
    local bg = self.UiRoot.UiMovieBg:GetBg(self.BgIndex)
    if not bg then
        return
    end

    -- 设置缩放中心点
    if #self.PivotParams > 0 then
		bg:SetPivotWithoutGC(self.PivotParams[1], self.PivotParams[2])
    end

    local targetScale = XLuaVector3.New(self.Scale, self.Scale, self.Scale)
    local time = self.IsPassedRunning and 0 or self.AnimTime
    local ease = XMVCA.XMovie:GetDOTweenEase(self.CurveType)
    bg:DoScale(targetScale, time, ease)
end

function XMovieActionBgScaleAnim:IsPassedActionRun(index)
    return true
end

---@param action XMovieActionBase
function XMovieActionBgScaleAnim:IsPassedActionCovered(action)
    if action:GetType() == self:GetType() then
        return self.BgIndex == action.BgIndex
    end
    return false
end

function XMovieActionBgScaleAnim:OnPassedActionRun()
    self.IsPassedRunning = true
    self:OnRunning()
    self.IsPassedRunning = false
end

return XMovieActionBgScaleAnim
