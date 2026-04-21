---@class XMovieActionTextAnim
---@field UiRoot XUiMovie
local XMovieActionTextAnim = XClass(XMovieActionBase, "XMovieActionTextAnim")

function XMovieActionTextAnim:OnInit(actionData)
    local params = actionData.Params

    self.TextId = params[1]
    self.Time = XMVCA.XMovie:ParamToNumber(params[2])
    self.Pos = params[3] and XMVCA.XMovie:SplitParam(params[3], "|",true) or nil
    self.Rotation = params[4] and XMVCA.XMovie:ParamToNumber(params[4]) or nil
    self.Scale = params[5] and XMVCA.XMovie:ParamToNumber(params[5]) or nil
end

function XMovieActionTextAnim:OnRunning()
    self.UiRoot:TextPlayAnim(self.TextId, self.Time, self.Pos, self.Rotation, self.Scale)
end

function XMovieActionTextAnim:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

---@param action XMovieActionBase
function XMovieActionTextAnim:IsPassedActionCovered(action)
    if action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.TEXT_APPEAR then
        local params = action:GetParams()
        local textId = params[1]
        return textId == self.TextId

    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.TEXT_DISAPPEAR then
        return action:IsDisAppear(self.TextId)
    end
    return false
end

function XMovieActionTextAnim:OnPassedActionRun()
    local text = self.UiRoot:GetText(self.TextId)
    if not text then return end
    
    if self.Pos then
        local aimPos = XLuaVector3.New(self.Pos[1], self.Pos[2], self.Pos[3] or 0)
        text.transform.localPosition = aimPos
    end

    if self.Rotation then
        local eulerAngles = text.transform.eulerAngles
        eulerAngles = XLuaVector3.New(eulerAngles.x, eulerAngles.y, eulerAngles.z + self.Rotation)
        text.transform.eulerAngles = eulerAngles
    end

    if self.Scale then
        text.transform.localScale = XLuaVector3.New(self.Scale, self.Scale, self.Scale)
    end
end

return XMovieActionTextAnim