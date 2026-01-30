---@class XMovieActionAddReview
local XMovieActionAddReview = XClass(XMovieActionBase, "XMovieActionAddReview")

function XMovieActionAddReview:OnInit(actionData)
    local params = actionData.Params
    self.RoleName = XMVCA.XMovie:FormatContent(params[1])
    self.DialogContent = XMVCA.XMovie:FormatContent(params[2])
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