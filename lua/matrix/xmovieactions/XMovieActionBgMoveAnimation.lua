---@class XMovieActionBgMoveAnimation
---@field UiRoot XUiMovie
local XMovieActionBgMoveAnimation = XClass(XMovieActionBase,"XMovieActionBgMoveAnimation")
local DefaultBgIndex = 1

function XMovieActionBgMoveAnimation:OnInit(actionData)
    local params = actionData.Params
    local strPos = params[1]
    if strPos then
        self.Pos = XTool.ConvertStringToVector3(strPos)
    else
        self.Pos = CS.UnityEngine.Vector3.zero
    end
    self.Duration = tonumber(params[2])
    self.IsPanelSpine = tonumber(params[3]) == 1

    local bgIndex = params[4]
    self.BgIndex = bgIndex and tonumber(bgIndex) or DefaultBgIndex
end

function XMovieActionBgMoveAnimation:OnUiRootInit()
    self.RImgBg = self.UiRoot.UiMovieBg:GetBg(self.BgIndex)
    self.RImgAnimBg = self.BgIndex == DefaultBgIndex and self.UiRoot.UiMovieBg:GetBg(2) or nil
end

function XMovieActionBgMoveAnimation:OnRunning()
    if self.IsPanelSpine then
        self.UiRoot.PanelSpine.transform:DOComplete()
        self.UiRoot.PanelSpine.transform:DOLocalMove(self.Pos, self.Duration)
        return
    end

    if self.RImgBg then
        self.RImgBg:DOComplete()
        self.RImgBg:DOLocalMove(self.Pos, self.Duration)
    end
    if self.RImgAnimBg then
        self.RImgAnimBg:DOComplete()
        self.RImgAnimBg:DOLocalMove(self.Pos, self.Duration)
    end
end

function XMovieActionBgMoveAnimation:GetBgIndex()
    return self.BgIndex
end

function XMovieActionBgMoveAnimation:IsPassedActionRun(index)
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index, function(action)
        return self:IsActionCover(action)
    end)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionBgMoveAnimation:IsActionCover(action)
    if action:GetType() == self:GetType() then
        return self.BgIndex == action:GetBgIndex()
    end
    return false
end

function XMovieActionBgMoveAnimation:OnPassedActionRun()
    if self.IsPanelSpine then
        self.UiRoot.PanelSpine.transform.localPosition = self.Pos
        return
    end

    if self.RImgBg then
        self.RImgBg:SetLocalPosition(self.Pos)
    end
    if self.RImgAnimBg then
        self.RImgAnimBg:SetLocalScale(self.Pos)
    end
end

return XMovieActionBgMoveAnimation