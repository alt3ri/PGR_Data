---@class XMovieActionAddReview
local XMovieActionAddReview = XClass(XMovieActionBase, "XMovieActionAddReview")

function XMovieActionAddReview:OnInit(actionData)
    local params = actionData.Params
    self.RoleName = XMVCA.XMovie:FormatContent(params[1])
    self.DialogContent = XMVCA.XMovie:FormatContent(params[2])
    if XMain.IsDebug and params[3] and params[3] ~= "" and not tonumber(params[3]) then
        XLog.Error(string.format("XMovieActionAddReview:OnInit error: 参数3(CvId)必须为数字，当前填写为 %s，请检查节点: %s", tostring(params[3]), self.ActionId))
    end
    self.CvId = XMVCA.XMovie:ParamToNumber(params[3])
end

function XMovieActionAddReview:OnEnter()
    XDataCenter.MovieManager.PushInReviewDialogList(self.RoleName, self.DialogContent, self.CvId)
end

function XMovieActionAddReview:IsPassedActionRun(index)
    return true
end

function XMovieActionAddReview:OnPassedActionRun()
    XDataCenter.MovieManager.PushInReviewDialogList(self.RoleName, self.DialogContent, self.CvId)
end

function XMovieActionAddReview:OnPassedActionSkip()
    XDataCenter.MovieManager.PushInReviewDialogList(self.RoleName, self.DialogContent, self.CvId)
end

return XMovieActionAddReview