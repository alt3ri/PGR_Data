---@class XMovieActionBgScale
---@field UiRoot XUiMovie
local XMovieActionBgScale = XClass(XMovieActionBase, "XMovieActionBgScale")
local DefaultBgIndex = 1

function XMovieActionBgScale:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.Scale = paramToNumber(params[1])
    local strPos = params[2]
    if strPos then
        self.Pos = XTool.ConvertStringToVector3(strPos)
    else
        self.Pos = CS.UnityEngine.Vector3.zero
    end

    local bgIndex = params[3]
    self.BgIndex = bgIndex and paramToNumber(bgIndex) or DefaultBgIndex
end

function XMovieActionBgScale:OnUiRootInit()
    self.RImgBg = self.UiRoot.UiMovieBg:GetBg(self.BgIndex)
    self.RImgAnimBg = self.BgIndex == DefaultBgIndex and self.UiRoot.UiMovieBg:GetBg(2) or nil
end

function XMovieActionBgScale:OnRunning()
    if self.RImgBg then
        self.RImgBg:SetLocalScale(CS.UnityEngine.Vector3.one * self.Scale)
        self.RImgBg:SetLocalPosition(self.Pos)
    end

    if self.RImgAnimBg then
        self.RImgAnimBg:SetLocalScale(CS.UnityEngine.Vector3.one * self.Scale)
        self.RImgAnimBg:SetLocalPosition(self.Pos)
    end
end

function XMovieActionBgScale:IsPassedActionRun(index)
    return true
end

function XMovieActionBgScale:OnPassedActionRun()
    self:OnRunning()
end

return XMovieActionBgScale