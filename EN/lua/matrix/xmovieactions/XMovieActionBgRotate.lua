---@class XMovieActionBgRotate
---@field UiRoot XUiMovie
local XMovieActionBgRotate = XClass(XMovieActionBase, "XMovieActionBgRotate")
local INVALID_BG_INDEX =  1 -- 强制最底下的图层1无法旋转

---@param actionData XTableMovieNew
function XMovieActionBgRotate:OnInit(actionData)
    self.PivotParams = XMVCA.XMovie:SplitParam(actionData.Params[1], "|", true)
    self.AnimTime = XMVCA.XMovie:ParamToNumber(actionData.Params[2])
    self.RotationParams = XMVCA.XMovie:SplitParam(actionData.Params[3], "|", true)
    self.BgIndex = XMVCA.XMovie:ParamToNumber(actionData.Params[4])
    self.CurveType = XMVCA.XMovie:ParamToCurveType(actionData.Params[5])
end

function XMovieActionBgRotate:OnRunning()
    if self.BgIndex == 0 or self.BgIndex == INVALID_BG_INDEX then
        return
    end

    local bg = self.UiRoot.UiMovieBg:GetBg(self.BgIndex)

    -- 设置锚点
    if #self.PivotParams > 0 then
        local pivot = XLuaVector2.New(self.PivotParams[1], self.PivotParams[2])
        bg:SetPivot(pivot)
    end

    local targetRotation = XLuaVector3.New(self.RotationParams[1], self.RotationParams[2], self.RotationParams[3])
    local time = self.IsPassedRunning and 0 or self.AnimTime
    local ease = XMVCA.XMovie:GetDOTweenEase(self.CurveType)
    bg:DoRotate(targetRotation, time, ease)
end

function XMovieActionBgRotate:IsPassedActionRun(index)
    return true
end

function XMovieActionBgRotate:OnPassedActionRun()
    self.IsPassedRunning = true
    self:OnRunning(true)
    self.IsPassedRunning = false
end

return XMovieActionBgRotate