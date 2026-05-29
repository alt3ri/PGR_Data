local XUiGridMovieBg = require("XUi/XUiMovie/XUiGridMovieBg")
local TIMER_INTERVAL = 0.1 -- 定时器间隔

---@class XUiGridMovieBgGroup : XUiNode
---@field Parent XUiMovie
---@field GridBgs table<number, XUiGridMovieBg>
local XUiGridMovieBgGroup = XClass(XUiNode, "XUiGridMovieBgGroup")

function XUiGridMovieBgGroup:OnStart(bgIndex)
    self.BgIndex = bgIndex
    self.GridBgs = {}

    -- 设置锚点、位置、缩放
    local anchorType = XMVCA.XMovie.EnumConst.ANCHOR_ALIGNMENT_TYPE.FULL
    local params = XMVCA.XMovie.EnumConst.ANCHOR_ALIGNMENT_TYPE_TO_PARAM[anchorType]
    local rect = self.GameObject:AddComponent(typeof(CS.UnityEngine.RectTransform))
    rect.localPosition = XLuaVector3.New(0, 0, 0)
    rect.localScale = XLuaVector3.New(1, 1, 1)
    rect.anchorMin = XLuaVector2.New(params[1], params[2])
    rect.anchorMax = XLuaVector2.New(params[3], params[4])
    rect.offsetMin = XLuaVector2.New(0, 0)   -- Left, Bottom
    rect.offsetMax = XLuaVector2.New(0, 0)   -- Right, Top

    local rImgBg = self.Parent["RImgBg" .. self.BgIndex]
    -- 添加XAspectRatioFitter组件
    if rImgBg:TryGetComponent(typeof(CS.XAspectRatioFitter)) then
        local aspectRatioFitter = rImgBg:GetComponent(typeof(CS.XAspectRatioFitter))
        local component = self.GameObject:AddComponent(typeof(CS.XAspectRatioFitter))
        component.aspectMode = aspectRatioFitter.aspectMode
        component.aspectRatio = aspectRatioFitter.aspectRatio
    end
    -- 添加Canvas组件
    if rImgBg:TryGetComponent(typeof(CS.UnityEngine.Canvas)) then
        local canvas = rImgBg:GetComponent(typeof(CS.UnityEngine.Canvas))
        local component = self.GameObject:AddComponent(typeof(CS.UnityEngine.Canvas))
        component.overrideSorting = canvas.overrideSorting
        component.sortingOrder  = canvas.sortingOrder
    end
    -- 设置缩放
    self.GameObject.transform.localScale = rImgBg.transform.localScale
end

function XUiGridMovieBgGroup:OnEnable()
    
end

function XUiGridMovieBgGroup:OnDisable()
    self:RemoveBgAnimTimer()
end

-- 播放背景组动画
function XUiGridMovieBgGroup:Play(bgPaths, loopCount, switchAnimTime, stayTime, isFadeOut)
    self.BgPaths = bgPaths
    self.LoopCount = loopCount
    self.SwitchAnimTime = switchAnimTime
    self.StayTime = stayTime
    self.IsFadeOut = isFadeOut
    self.MaxBgIndex = #self.BgPaths
    
    -- 刷新背景图
    for i, bgPath in ipairs(bgPaths) do
        local gridBg = self.GridBgs[i]
        if not gridBg then
            gridBg = XUiGridMovieBg.New(self.Parent, self.GameObject, self.BgIndex)
            self.GridBgs[i] = gridBg
        end
        
        gridBg:SetBgPath(bgPath)
    end
    
    self:PlayBgSwitchAnimation()
end

function XUiGridMovieBgGroup:Stop()
    self:RemoveBgAnimTimer()
end

-- 播放背景切换动画
function XUiGridMovieBgGroup:PlayBgSwitchAnimation()
    self.CurBgIndex = 1
    self.PassLoopCount = 0
    self.WaitTime = self.StayTime
    
    -- 显示第一张背景图
    for i, gridBg in ipairs(self.GridBgs) do
        local isShow = i == self.CurBgIndex
        gridBg:SetGameObjectShow(isShow)
        if isShow then
            gridBg:SetAlpha(1)
        end
    end
    
    self:RemoveBgAnimTimer()
    self.BgAnimTimer = XScheduleManager.ScheduleForever(function()  
        self:OnBgAnimUpdate()
    end, TIMER_INTERVAL * 1000)
end

-- 移除背景切换定时器
function XUiGridMovieBgGroup:RemoveBgAnimTimer()
    if self.BgAnimTimer then
        XScheduleManager.UnSchedule(self.BgAnimTimer)
        self.BgAnimTimer = nil
    end
end

-- 背景动画定时器更新函数
function XUiGridMovieBgGroup:OnBgAnimUpdate()
    self.WaitTime = self.WaitTime - TIMER_INTERVAL
    if self.WaitTime > 0 then return end

    local animTime = self.SwitchAnimTime
    local nextBgIndex = self.CurBgIndex + 1
    if nextBgIndex > self.MaxBgIndex then
        nextBgIndex = 1
        self.PassLoopCount = self.PassLoopCount + 1
    end

    -- 指定循环次数，并且超出循环次数时，结束动画
    if self.LoopCount ~= 0 and self.PassLoopCount >= self.LoopCount then
        self:RemoveBgAnimTimer()
        self:Close()
        return
    end

    -- 隐藏其他背景图
    for i, gridBg in ipairs(self.GridBgs) do
        local isShow = i == self.CurBgIndex or i == nextBgIndex
        gridBg:SetGameObjectShow(isShow)
    end

    -- 播放透明度动画
    local gridBg = self.GridBgs[self.CurBgIndex]
    local nextGridBg = self.GridBgs[nextBgIndex]
    gridBg:SetAlpha(1)
    if self.IsFadeOut then
        gridBg:SetAlpha(0, animTime)
    end
    nextGridBg:SetAsLastSibling()
    nextGridBg:SetAlpha(0)
    nextGridBg:SetAlpha(1, animTime)

    -- 更新背景图下标和等待时间
    self.CurBgIndex = nextBgIndex
    self.WaitTime = self.SwitchAnimTime + self.StayTime
end

return XUiGridMovieBgGroup