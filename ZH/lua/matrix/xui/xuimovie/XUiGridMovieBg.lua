local DEFAULT_PIVOT = XLuaVector2.New(0.5, 0.5)
local DEFAULT_SCALE = XLuaVector3.New(1, 1, 1)
local Quaternion = CS.UnityEngine.Quaternion
local tableInsert = table.insert

---@class XUiGridMovieBg
---@field UiMovie XUiMovie
local XUiGridMovieBg = XClass(nil, "XUiGridMovieBg")

function XUiGridMovieBg:Ctor(uiMovie, link, bgIndex)
    self.UiMovie = uiMovie
    self.Link = link -- 挂点
    self.BgIndex = bgIndex
    self.GameObject = XUiHelper.Instantiate(self.UiMovie.UiMovieRImgBg, self.Link.transform)
    self.Transform = self.GameObject.transform
    self.GameObject.gameObject:SetActiveEx(true)
    XTool.InitUiObject(self)

    self.XAspectRatioFitter = self.Link.transform:GetComponent(typeof(CS.XAspectRatioFitter))
    self.InitAspectRatio = self.XAspectRatioFitter and self.XAspectRatioFitter.aspectRatio or 1
    self.LinkScale = self.Link.transform.localScale
    self.CanvasGroup = self.RImgBg.transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    self.RImgBgRect = self.RImgBg.transform:GetComponent(typeof(CS.UnityEngine.RectTransform))
    self.InitSizeDelta = self.RImgBgRect.sizeDelta
    self.AnchorType = XMVCA.XMovie.EnumConst.ANCHOR_ALIGNMENT_TYPE.FULL
end

function XUiGridMovieBg:OnDestroy()
    
end

-- 显示背景图
function XUiGridMovieBg:Show()
    self.Link.gameObject:SetActiveEx(true)
end

-- 隐藏背景图
function XUiGridMovieBg:Hide()
    self.Link.gameObject:SetActiveEx(false)

    -- 隐藏时重置旋转
    self.RImgBg.transform.localRotation = Quaternion.identity
end

-- 动画主要控制BgRoot，程序主要控制RImgBg
function XUiGridMovieBg:SetLocalPosition(pos)
    self.RImgBg.transform.localPosition = pos
end

---@param isForceUpdate boolean 是否强制刷新， RectTransform 在设置 anchor 时会自动调整位置以保持相对位置，需要下一帧设置位置/先强制刷新才会生效
function XUiGridMovieBg:SetAnchoredPosition3D(pos, isForceUpdate)
    --[[
    if isForceUpdate then
        CS.UnityEngine.Canvas.ForceUpdateCanvases()
    end
    ]]
    self.RImgBg.transform.anchoredPosition3D = pos
end

function XUiGridMovieBg:SetLocalScale(scale)
    self.RImgBg.transform.localScale = scale
end

function XUiGridMovieBg:SetPivot(pivot)
    self.RImgBg.transform.pivot = pivot
end

function XUiGridMovieBg:SetNativeSize()
    self.RImgBg:SetNativeSize()
end

-- 修改对齐方式和位置
function XUiGridMovieBg:SetAnchorType(anchorType, positionParams)
    -- 未配置对齐方式
    if not anchorType then return end

    -- 对齐方式相同，检查位置修改
    if self.AnchorType == anchorType then
        -- 修改位置
        if positionParams and #positionParams > 0 then
            local pos = XLuaVector3.New(positionParams[1], positionParams[2], positionParams[3])
            self:SetAnchoredPosition3D(pos)
        end
        return    
    end
    
    local isAnchorFull = anchorType == XMVCA.XMovie.EnumConst.ANCHOR_ALIGNMENT_TYPE.FULL
    local isAnchorFullDisableAdapter = anchorType == XMVCA.XMovie.EnumConst.ANCHOR_ALIGNMENT_TYPE.FULL_DISABLE_ADAPTER
    local isFull = isAnchorFull or isAnchorFullDisableAdapter

    -- 只有FULL类型需要启用XAspectRatioFitter，并使用预制体预设的1.1倍缩放
    if isAnchorFull then
        if self.XAspectRatioFitter then
            self.XAspectRatioFitter.enabled = true
        end
        self.Link.localScale = self.LinkScale
    else
        if self.XAspectRatioFitter then
            self.XAspectRatioFitter.enabled = false
        end
        self.Link.localScale = DEFAULT_SCALE
        self.Link.offsetMin = XLuaVector2.New(0, 0)   -- Left, Bottom
        self.Link.offsetMax = XLuaVector2.New(0, 0)   -- Right, Top
    end

    -- 修改锚点
    local params = XMVCA.XMovie.EnumConst.ANCHOR_ALIGNMENT_TYPE_TO_PARAM[anchorType]
    self.RImgBgRect.anchorMin = XLuaVector2.New(params[1], params[2])
    self.RImgBgRect.anchorMax = XLuaVector2.New(params[3], params[4])
    -- 修改大小
    if isFull then
        self.RImgBgRect.offsetMin = XLuaVector2.New(0, 0)   -- Left, Bottom
        self.RImgBgRect.offsetMax = XLuaVector2.New(0, 0)   -- Right, Top
    else
        self:SetNativeSize()
    end
    self.AnchorType = anchorType

    -- 修改位置
    if positionParams and #positionParams > 0 then
        local pos = XLuaVector3.New(positionParams[1], positionParams[2], positionParams[3])
        self:SetAnchoredPosition3D(pos, true)
    end
end

function XUiGridMovieBg:DOAnchorPos3D(pos, duration)
    -- 正在加载图片，需要等图片加载完成，设置完对齐和位置之后才开始移动
    if self.IsLoadingRawImage then
        self._CacheMovePosList = self._CacheMovePosList or {}
        self._CacheMoveDurationList = self._CacheMoveDurationList or {}
        tableInsert(self._CacheMovePosList, pos)
        tableInsert(self._CacheMoveDurationList, duration)
        return
    end

    -- 完成上一个位移动画
    if self.DOAnchorPos3DTween then
        self.DOAnchorPos3DTween:Complete()
        self.DOAnchorPos3DTween = nil
    end
    
    -- 0秒也要跑Tween动画
    -- 原因：旧剧情是先配0秒动画设置位置，再配101切换背景图(会重置位置)，而动画最少跑一帧，最终以动画的位置显示
    self.DOAnchorPos3DTween = self.RImgBg.transform:DOAnchorPos3D(pos, duration)
end

-- 检测是否有动画未播放
function XUiGridMovieBg:_CheckPlayMoveAnimation()
    if self._CacheMovePosList and #self._CacheMovePosList > 0 then
        for i, pos in ipairs(self._CacheMovePosList) do
            local duration = self._CacheMoveDurationList[i]
            self:DOAnchorPos3D(pos, duration)
        end
        self._CacheMovePosList = {}
        self._CacheMoveDurationList = {}
    end
end

function XUiGridMovieBg:DoRotate(targetRotation, duration)
    -- 完成上一个旋转动画
    if self.DORotateTween then
        self.DORotateTween:Complete()
        self.DORotateTween = nil
    end
    
    local transform = self.RImgBg.transform
    if not duration or duration == 0 then
        transform.eulerAngles = targetRotation
    else
        self.DORotateTween = transform:DORotate(targetRotation, duration):OnComplete(function()
            transform.eulerAngles = targetRotation
        end)
    end
end

function XUiGridMovieBg:DOComplete()
    self.RImgBg.transform:DOComplete()
end

-- 动画修改的位置和缩放也要重置
function XUiGridMovieBg:Reset()
    -- self:DOComplete() 这里不能重置动画，存在先配置背景动画，再刷新背景图的情况
    self:SetPivot(DEFAULT_PIVOT)
    
    local scale = XLuaVector3.New(1, 1, 1)
    self.BgRoot.transform.localScale = scale
    self.RImgBg.transform.localScale = scale

    local pos = XLuaVector3.New(0, 0, 0)
    self.BgRoot.transform.anchoredPosition3D = pos
    self.RImgBg.transform.anchoredPosition3D = pos

    -- 调用了SetNativeSize的图片改回默认大小
    self.RImgBgRect.sizeDelta = self.InitSizeDelta
end

function XUiGridMovieBg:GetRImgBg()
    return self.RImgBg
end

function XUiGridMovieBg:SetBgPath(bgPath, anchorType, positionParams)
    -- 和之前图片相同不需要重新加载
    if self.BgPath == bgPath then
        self:SetAnchorType(anchorType, positionParams) -- 更新对齐模式
        return
    end
    
    self.BgPath = bgPath
    self.IsLoadingRawImage = true -- 是否正在加载图片
    self.RImgBg:SetRawImage(bgPath, function()
        self.IsLoadingRawImage = false
        self:SetAnchorType(anchorType, positionParams) -- 更新对齐模式
        self:_CheckPlayMoveAnimation()
    end)
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
    -- 完成上一个透明度变化动画
    if self.DOFadeTween then
        self.DOFadeTween:Complete()
        self.DOFadeTween = nil
    end

    self.DOFadeTween = self.RImgBg:DOFade(alpha, duration)
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
    return self.XAspectRatioFitter
end

function XUiGridMovieBg:GetAspectRatio()
    return self.XAspectRatioFitter and self.XAspectRatioFitter.aspectRatio or 1
end

function XUiGridMovieBg:SetAspectRatio(aspectRatio)
    if aspectRatio <= 0 then
        XLog.Error("aspectRatio 不能设置<=0！会导致localPosition.y 变成NaN！")
        return
    end
    
    if self.XAspectRatioFitter then
        self.XAspectRatioFitter.aspectRatio = aspectRatio
    end
end

function XUiGridMovieBg:GetCanvasGroup()
    return self.CanvasGroup
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