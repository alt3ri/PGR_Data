local DefaultAspectRatio = 1
local DefaultBgIndex = 1

---@field UiRoot XUiMovie
---@class XMovieActionBgSwitch
local XMovieActionBgSwitch = XClass(XMovieActionBase, "XMovieActionBgSwitch")

function XMovieActionBgSwitch:OnInit(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.Record = {}
    self.BgPath = params[1]
    self.AspectRatioPercent = paramToNumber(params[2])
    self.NeedSupportAnim = self.BeginAnim == "RImgBg2Enable"

    local bgAlpha = params[3]
    self.BgAlpha = bgAlpha and bgAlpha ~= "" and tonumber(bgAlpha) or nil
    local bgIndex = params[4]
    self.BgIndex = bgIndex and paramToNumber(bgIndex) or DefaultBgIndex
    self.IsHide = params[5] == "1"
end

function XMovieActionBgSwitch:OnUiRootInit()
    self.RImgBg = self.UiRoot.UiMovieBg:GetBg(self.BgIndex)

    if self.RImgBg then
        self.AspectRatioFitter = self.RImgBg:GetXAspectRatioFitter()
        self.CanvasGroup = self.RImgBg:GetCanvasGroup()
        DefaultAspectRatio = self.AspectRatioFitter.aspectRatio
    end

    -- 支持动画时，RImgBg1为原图，RImgBg2为新图，RImgBg2的透明度从0缓变为1
    if self.NeedSupportAnim and self.BgIndex == DefaultBgIndex then
        self.RImgAnimBg = self.UiRoot.UiMovieBg:GetBg(2)
        self.AspectRatioFitter2 = self.RImgAnimBg:GetXAspectRatioFitter()
    end

    -- FullScreenBackground下的背景图，仍按照旧逻辑改动FullScreenBackground的透明度
    local isInFullScreenBackground = self.RImgBg.Link.transform.parent == self.UiRoot.FullScreenBackground.transform
    if isInFullScreenBackground then
        self.CanvasGroupBg = self.UiRoot.FullScreenBackground:GetComponent("CanvasGroup")
    else
        self.CanvasGroupBg = self.RImgBg:GetCanvasGroup()
    end
end

function XMovieActionBgSwitch:OnUiRootDestroy()
    self.CanvasGroup = nil
    self.AspectRatioFitter = nil
    self.AspectRatioFitter2 = nil
    DefaultAspectRatio = 1
end

function XMovieActionBgSwitch:OnEnter()
    if self.IsHide then
        self.RImgBg:Hide()
        return
    end

    local bgPath = self.BgPath
    local aspectRatioPercent = self.AspectRatioPercent
    local ratio = aspectRatioPercent > 0 and DefaultAspectRatio * aspectRatioPercent or DefaultAspectRatio
    local rImgBg = self.RImgBg
    self.Record.BgPath = rImgBg:GetBgPath()
    rImgBg:ResetPosition()
    rImgBg:ResetScale()
    self.AspectRatioFitter.aspectRatio = ratio
    rImgBg:Show()

    if self.NeedSupportAnim and self.RImgAnimBg then
        rImgBg = self.RImgAnimBg
        rImgBg:SetBgPath(bgPath)
        rImgBg:ResetScale()
        rImgBg:ResetPosition()
        self.AspectRatioFitter2.aspectRatio = ratio
        rImgBg:Show()
    else
        rImgBg:SetBgPath(bgPath)
    end

    local bgAlpha = self.BgAlpha
    if bgAlpha then
        self.CanvasGroupBg.alpha = bgAlpha
    end
end

function XMovieActionBgSwitch:OnExit()
    if self.NeedSupportAnim then
        self.CanvasGroup.alpha = 1
        if not self.IsHide then
            self.RImgBg:SetBgPath(self.BgPath)
            self.RImgBg:ResetBgRootAlpha()
        end
        if self.RImgAnimBg then
            self.RImgAnimBg:Hide()
        end
    end
end

function XMovieActionBgSwitch:OnUndo()
    if self.Record.BgPath then
        self.RImgBg:SetBgPath(self.Record.BgPath)
    end
end

function XMovieActionBgSwitch:IsPassedActionRun(index)
    -- 隐藏action跳过
    if self.IsHide then return false end

    -- 有下一个刷新背景，不论是显示/隐藏，都是跳过
    local isCover = XDataCenter.MovieManager.IsBehindPassedActionCover(index, function(action)
        return self:IsActionCover(action)
    end)
    return not isCover
end

-- 传入Action是否可覆盖当前Action的UI显示，可覆盖则OnPassedActionRun不用再刷新UI界面
---@param action XMovieActionBase
function XMovieActionBgSwitch:IsActionCover(action)
    if action:GetType() ~= self:GetType() then
        return false
    end

    local params = action:GetParams()
    local bgIndex = params[4]
    bgIndex = bgIndex and XDataCenter.MovieManager.ParamToNumber(bgIndex) or DefaultBgIndex
    return bgIndex == self.BgIndex
end

function XMovieActionBgSwitch:OnPassedActionRun()
    -- 刷新背景图
    self.Record.BgPath = self.RImgBg:GetBgPath()
    self.RImgBg:SetBgPath(self.BgPath)
    self.RImgBg:ResetPosition()
    self.RImgBg:ResetScale()
    local ratio = self.AspectRatioPercent > 0 and DefaultAspectRatio * self.AspectRatioPercent or DefaultAspectRatio
    self.AspectRatioFitter.aspectRatio = ratio
    self.RImgBg:Show()
    if self.BgAlpha then
        self.CanvasGroupBg.alpha = self.BgAlpha
    end
end

return XMovieActionBgSwitch