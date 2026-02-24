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
    self.AnchorType = string.IsNilOrEmpty(params[6]) and XMVCA.XMovie.EnumConst.ANCHOR_ALIGNMENT_TYPE.FULL or paramToNumber(params[6]) -- 对齐方式
    self.PositionParams = XMVCA.XMovie:SplitParam(params[7], "|", true)
end

function XMovieActionBgSwitch:OnUiRootInit()
    self.RImgBg = self.UiRoot.UiMovieBg:GetBg(self.BgIndex)

    if self.RImgBg then
        self.CanvasGroup = self.RImgBg:GetCanvasGroup()
    end

    -- 支持动画时，RImgBg1为原图，RImgBg2为新图，RImgBg2的透明度从0缓变为1
    if self.NeedSupportAnim and self.BgIndex == DefaultBgIndex then
        self.RImgAnimBg = self.UiRoot.UiMovieBg:GetBg(2)
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
end

function XMovieActionBgSwitch:OnEnter()
    if self.IsHide then
        self.RImgBg:Hide()
        return
    end

    local bgPath = self.BgPath
    local rImgBg = self.RImgBg
    self.Record.BgPath = rImgBg:GetBgPath()
    rImgBg:Reset()
    if self.AspectRatioPercent > 0 then
        local ratio = rImgBg:GetAspectRatio() * self.AspectRatioPercent
        rImgBg:SetAspectRatio(ratio)
    end
    rImgBg:Show()

    if self.NeedSupportAnim and self.RImgAnimBg then
        local ratio = self.RImgBg:GetAspectRatio() * self.AspectRatioPercent
        self.RImgAnimBg:Reset()
        self.RImgAnimBg:SetBgPath(bgPath, self.AnchorType, self.PositionParams)
        self.RImgAnimBg:SetAspectRatio(ratio)
        self.RImgAnimBg:Show()
    else
        rImgBg:SetBgPath(bgPath, self.AnchorType, self.PositionParams)
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
    self.RImgBg:Reset()
    self.RImgBg:SetBgPath(self.BgPath, self.AnchorType, self.PositionParams)
    if self.AspectRatioPercent > 0 then
        local ratio = self.RImgBg:GetAspectRatio() * self.AspectRatioPercent
        self.RImgBg:SetAspectRatio(ratio)
    end
    self.RImgBg:Show()
    if self.BgAlpha then
        self.CanvasGroupBg.alpha = self.BgAlpha
    end
end

return XMovieActionBgSwitch