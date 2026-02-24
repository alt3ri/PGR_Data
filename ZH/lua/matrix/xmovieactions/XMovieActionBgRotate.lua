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
end

---@param ignoreAnim boolean 是否忽略动画
function XMovieActionBgRotate:OnRunning(ignoreAnim)
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
    local time = ignoreAnim and 0 or self.AnimTime
    bg:DoRotate(targetRotation, time)
end

function XMovieActionBgRotate:IsPassedActionRun(index)
    return true
end

function XMovieActionBgRotate:OnPassedActionRun()
    self:OnRunning(true)
end

return XMovieActionBgRotate