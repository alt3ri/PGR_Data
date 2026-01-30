---@class XUiGridMovieBg
---@field UiMovie XUiMovie
local XUiGridMovieBg = XClass(nil, "XUiGridMovieBg")

function XUiGridMovieBg:Ctor(uiMovie, link)
    self.UiMovie = uiMovie
    self.Link = link -- 挂点
    self.GameObject = XUiHelper.Instantiate(self.UiMovie.UiMovieRImgBg, self.Link.transform)
    self.Transform = self.GameObject.transform
    self.GameObject.gameObject:SetActiveEx(true)
    XTool.InitUiObject(self)
end

function XUiGridMovieBg:OnDestroy()
    
end

function XUiGridMovieBg:Show()
    self.Link.gameObject:SetActiveEx(true)
end

function XUiGridMovieBg:Hide()
    self.Link.gameObject:SetActiveEx(false)
end

function XUiGridMovieBg:SetLocalPosition(pos)
    self.BgRoot.transform.localPosition = pos
end

function XUiGridMovieBg:SetAnchoredPosition3D(pos)
    self.BgRoot.transform.anchoredPosition3D = pos
end

function XUiGridMovieBg:SetLocalScale(scale)
    self.BgRoot.transform.localScale = scale
end

function XUiGridMovieBg:DOLocalMove(pos, duration)
    self.RImgBg.transform:DOLocalMove(pos, duration)
end

function XUiGridMovieBg:DOComplete()
    self.RImgBg.transform:DOComplete()
end

function XUiGridMovieBg:ResetScale()
    local scale = XLuaVector3.New(1, 1, 1)
    self.BgRoot.transform.localScale = scale
    self.RImgBg.transform.localScale = scale
end

function XUiGridMovieBg:ResetPosition()
    local pos = XLuaVector3.New(0, 0, 0)
    self.BgRoot.transform.anchoredPosition3D = pos
    self.RImgBg.transform.anchoredPosition3D = pos
end

function XUiGridMovieBg:GetRImgBg()
    return self.RImgBg
end

function XUiGridMovieBg:SetBgPath(bgPath)
    self.BgPath = bgPath
    self.RImgBg:SetRawImage(bgPath)
end

function XUiGridMovieBg:GetBgPath()
    return self.BgPath
end

function XUiGridMovieBg:GetColor()
    return self.RImgBg.color
end

function XUiGridMovieBg:SetColor(color)
    self.RImgBg.color = color
end

-- 重置BgRoot的透明度，这个透明度是由动画控制的，代码控制的是RImgBg的透明度
function XUiGridMovieBg:ResetBgRootAlpha()
    self:StopAnimtion("RImgBgDisableSlow")
    self.BgRoot:GetComponent("CanvasGroup").alpha = 1
end

function XUiGridMovieBg:SetAlpha(alpha, duration)
    self.RImgBg:DOFade(alpha, duration)
end

-- 设置灰度值
function XUiGridMovieBg:SetGrayScale(value, time)
    local component = self.RImgBg:GetComponent(typeof(CS.XUiMaterialController))
    if not component then
        component = self.RImgBg.gameObject:AddComponent(typeof(CS.XUiMaterialController))
    end
    component:SetGrayScale(value, time)
end

function XUiGridMovieBg:GetXAspectRatioFitter()
    return self.Link.transform:GetComponent(typeof(CS.XAspectRatioFitter))
end

function XUiGridMovieBg:GetCanvasGroup()
    return self.RImgBg.transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
end

function XUiGridMovieBg:GetAnim(animName)
    return self[animName]
end

function XUiGridMovieBg:PlayAnimtion(animName, cb)
    local anim = self:GetAnim(animName)
    anim:PlayTimelineAnimation(function()
        if cb then cb() end
    end)
end

function XUiGridMovieBg:StopAnimtion(animName)
    local anim = self:GetAnim(animName)
    local timelineAnimation = anim.transform:GetComponent(typeof(CS.XUiPlayTimelineAnimation))
    if timelineAnimation then
        timelineAnimation:Stop(false)
    end
end

return XUiGridMovieBg