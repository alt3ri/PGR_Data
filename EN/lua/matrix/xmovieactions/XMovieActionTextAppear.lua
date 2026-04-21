---@class XMovieActionTextAppear
---@field UiRoot XUiMovie
local XMovieActionTextAppear = XClass(XMovieActionBase, "XMovieActionTextAppear")

function XMovieActionTextAppear:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    
    self.TextId = params[1]
    self.TextContent = XMVCA.XMovie:FormatContent(params[2])
    self.PosX = paramToNumber(params[3])
    self.PosY = paramToNumber(params[4])
    self.Rotation = paramToNumber(params[5])
    self.IsPlayTypeWriter = paramToNumber(params[6]) == 1 -- 是否播放打字机
    self.CanJumpTypeWriter = paramToNumber(params[7]) == 1
    self.TypeWriterTime = paramToNumber(params[8])
    self.Layer = params[9] and paramToNumber(params[9]) or 1  -- 1:背景之上，演员之下 2：演员之上 3：最上层
    
    -- 参数10决定对齐方式
    if params[10] == "1" then
        self.Alignment = CS.UnityEngine.TextAnchor.MiddleLeft
    elseif params[10] == "2" then
        self.Alignment = CS.UnityEngine.TextAnchor.MiddleRight
    else
        self.Alignment = CS.UnityEngine.TextAnchor.MiddleCenter
    end
    
    self.IsAnim = paramToNumber(params[11]) == 1
    self.Scale = params[12] and paramToNumber(params[12]) or 1
    self.AnchorType = string.IsNilOrEmpty(params[13]) and XMVCA.XMovie.EnumConst.ANCHOR_ALIGNMENT_TYPE.MIDDLE or paramToNumber(params[13]) -- 对齐方式
end

function XMovieActionTextAppear:OnEnter()
    self.IsTyping = false
    local content = XMVCA.XMovie:ExtractGenderContent(self.TextContent)
    local uiObj = self.UiRoot:AppearText(self.Layer, self.TextId, content, self.PosX, self.PosY, self.Scale, self.Rotation, self.IsAnim, self.AnchorType)
    if self.IsPlayTypeWriter then
        self.IsTyping = true
        self.TypeWriter = uiObj:GetObject("TypeWriter")
        self.TypeWriter.Duration = self.TypeWriterTime
        self.TypeWriter.CompletedHandle = function() self:OnTypeWriterComplete() end
        self.TypeWriter:Play()
    end
    self.UiRoot:SetBtnNextCallback(function() self:OnClickBtnNext() end)
    uiObj:GetObject("GridText").alignment = self.Alignment
end

function XMovieActionTextAppear:OnDestroy()
    self.UiRoot:RemoveBtnNextCallback()
end

function XMovieActionTextAppear:OnClickBtnNext()
    if self.IsTyping then
        self.TypeWriter:Stop()
        self.TypeWriter:ShowAllText()
        self:OnTypeWriterComplete()
    else
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
    end
end

function XMovieActionTextAppear:OnTypeWriterComplete()
    self.IsTyping = false
end

function XMovieActionTextAppear:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index)
    return not isCover
end

---@param action XMovieActionBase
function XMovieActionTextAppear:IsPassedActionCovered(action)
    if action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.TEXT_APPEAR then
        local params = action:GetParams()
        local textId = params[1]
        return textId == self.TextId

    elseif action:GetType() == XMVCA.XMovie.EnumConst.ACTION_TYPE.TEXT_DISAPPEAR then
        return action:IsDisAppear(self.TextId)
    end
    return false
end

function XMovieActionTextAppear:OnPassedActionRun()
    self:OnEnter()
end

return XMovieActionTextAppear