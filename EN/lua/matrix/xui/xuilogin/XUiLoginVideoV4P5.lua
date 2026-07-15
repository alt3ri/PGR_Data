---@class XUiLoginVideoV4P5: XLuaUi
local XUiLoginVideoV4P5 = XLuaUiManager.Register(XLuaUi, "UiLoginVideoV4P5")

function XUiLoginVideoV4P5:OnAwake()
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnGo.CallBack = function() self:OnBtnGoClick() end

    -- 视频2、3初始透明度为0
    local color2 = self.VideoImg2.color
    color2.a = 0
    self.VideoImg2.color = color2

    local color3 = self.VideoImg3.color
    color3.a = 0
    self.VideoImg3.color = color3
end

function XUiLoginVideoV4P5:OnStart(forceId)
    self.IsOpenFromLogin = not XTool.IsNumberValid(forceId)

    ---@type XTableLoginPromoFeature
    local targetGotoConfig
    -- 优先使用外部传入的指定Id
    if forceId then
        self.ForceId = forceId
        local allConfigs = XLoginManager.GetLoginPromoFeatureTemplate()
        targetGotoConfig = allConfigs[forceId]
    end
    if not targetGotoConfig then
        targetGotoConfig = XLoginManager.GetCurrentLoginPromoFeature()
    end
    self.LoginPromoFeatureConfig = targetGotoConfig

    self.VideoPlayerUgui1.ActionPrepared = function()
        local vlength1 = self.VideoPlayerUgui1:GetCurMovieLength()
        self.Video2StartTime = vlength1 + self.Video2StartOffset
        self.FadeStartTime = vlength1 + self.FadeStartOffset
        self.Video1HideTime = vlength1 + self.Video1HideOffset
    end
    self.VideoPlayerUgui2.ActionPrepared = function()
        self.Video2Length = self.VideoPlayerUgui2:GetCurMovieLength()
    end

    self.VideoPlayerUgui1:SetInfoByVideoId(targetGotoConfig.VideoConfigId[1])
    self.VideoPlayerUgui2:SetInfoByVideoId(targetGotoConfig.VideoConfigId[2])
    self.VideoPlayerUgui3:SetInfoByVideoId(targetGotoConfig.VideoConfigId[3])
    self.VideoPlayerUgui1:Prepare()
    self.VideoPlayerUgui2:Prepare()
    self.VideoPlayerUgui3:Prepare()
    -- self.VideoPlayerUgui3:Prepare()

    self:InitTimes()

    if self.IsOpenFromLogin then
        XMVCA.XUiMain:SetUiLoginVideoV4P0OpenTriggerTrue()
    end
    XSaveTool.SaveData(targetGotoConfig.Id.."LoginPromoFeatureConfig"..XPlayer.Id, 1)

    -- 可调时间参数（初始值，ActionPrepared回调后由实际视频长度覆盖）
    self.Video1HideOffset = 0                -- 视频1隐藏：vlength1 + offset
    self.Video2StartOffset = -0.8             -- 视频2开始播放：vlength1 + offset
    self.FadeStartOffset = -1                 -- 视频1淡出/视频2淡入：vlength1 + offset
    self.Video2TriggerVideo3Time = 2          -- 视频2播放到多少秒时触发视频3
    self.AlphaFadeDuration = 0                -- alpha渐变持续时间

    self.CurrentVideoIndex = 1
    self.VideoPlayTime = 0          -- 全局计时（程序累加）
    self.VideoFadeTimer = 0         -- alpha渐变计时器
    self.IsFading = false           -- 是否正在做alpha渐变
    self.Video2Triggered = false    -- 视频2是否已触发播放
    self.Video3Triggered = false    -- 视频3是否已触发播放
    self.FadeTriggered = false      -- 透明度渐变是否已触发
    self.IsFading3 = false          -- 是否正在做视频3淡入/视频2淡出
    self.Video2StartTime = math.huge-- ActionPrepared后覆盖
    self.FadeStartTime = math.huge
    self.Video1HideTime = math.huge

    self.TimerId = XScheduleManager.ScheduleForever(function()
        self:Update()
    end, 0)
end

function XUiLoginVideoV4P5:Update()
    local dt = CS.UnityEngine.Time.deltaTime

    -- alpha渐变处理 (视频2淡入 + 视频1淡出)
    if self.IsFading then
        self.VideoFadeTimer = self.VideoFadeTimer + dt
        local progress = self.VideoFadeTimer / self.AlphaFadeDuration
        if progress >= 1 then
            progress = 1
            self.IsFading = false
        end
        -- 视频2: 0→1
        if not XTool.UObjIsNil(self.VideoImg2) then
            local color2 = self.VideoImg2.color
            color2.a = progress
            self.VideoImg2.color = color2
        end
        -- 视频1: 1→0
        if not XTool.UObjIsNil(self.VideoImg1) then
            local color1 = self.VideoImg1.color
            color1.a = 1 - progress
            self.VideoImg1.color = color1
        end
    end

    -- alpha渐变处理 (视频3淡入 + 视频2淡出)
    if self.IsFading3 then
        self.VideoFade3Timer = self.VideoFade3Timer + dt
        local progress = self.VideoFade3Timer / self.AlphaFadeDuration
        if progress >= 1 then
            progress = 1
            self.IsFading3 = false
        end
        -- 视频3: 0→1
        if not XTool.UObjIsNil(self.VideoImg3) then
            local color3 = self.VideoImg3.color
            color3.a = progress
            self.VideoImg3.color = color3
        end
        -- 视频2: 1→0
        if not XTool.UObjIsNil(self.VideoImg2) then
            local color2 = self.VideoImg2.color
            color2.a = 1 - progress
            self.VideoImg2.color = color2
        end
    end

    local video1Time = self.VideoPlayTime
    self.VideoPlayTime = self.VideoPlayTime + dt

    -- 视频2在 vlength1-1.5s 开始播放
    if self.CurrentVideoIndex == 1 and video1Time >= self.Video2StartTime and not self.Video2Triggered then
        self.Video2Triggered = true
        self.CurrentVideoIndex = 2
        if not XTool.UObjIsNil(self.VideoPlayerUgui2) then
            self.VideoPlayerUgui2:Play()
            self:PlayAnimation("BtnEnable")
        end
    end

    if self.Video2Triggered and video1Time >= self.FadeStartTime and not self.FadeTriggered then
        self.FadeTriggered = true
        self.VideoFadeTimer = 0
        self.IsFading = true
    end

    -- 视频1在 vlength1 时隐藏
    if self.Video2Triggered and video1Time >= self.Video1HideTime then
        if not XTool.UObjIsNil(self.VideoPlayerUgui1) and self.VideoPlayerUgui1.gameObject.activeSelf then
            self.VideoPlayerUgui1:Stop(false)
            self.VideoPlayerUgui1.gameObject:SetActiveEx(false)
        end
    end

    -- BtnGo已点击 且 视频2播放到 Video2TriggerVideo3Time 秒时触发视频3
    if self.Video2Triggered and not self.Video3Triggered and self.BtnGoClicked and self.Video2Length then
        local video2Time = self.VideoPlayerUgui2:GetCurrentTime() % self.Video2Length
        local prevVideo2Time = self.PrevVideo2Time or 0
        self.PrevVideo2Time = video2Time
        local crossed = prevVideo2Time < self.Video2TriggerVideo3Time and video2Time >= self.Video2TriggerVideo3Time
        local looped = video2Time < prevVideo2Time and prevVideo2Time < self.Video2TriggerVideo3Time
        if crossed or looped then
            self.Video3Triggered = true
            self.VideoPlayerUgui3:Play()
            self.VideoFade3Timer = 0
            self.IsFading3 = true
            self.VideoPlayerUgui3.ActionEnded = function()
                XScheduleManager.ScheduleOnce(function() self:DoGo() end, 0)
            end
        end
    end
end

function XUiLoginVideoV4P5:InitTimes()
    local endTime = XFunctionManager.GetEndTimeByTimeId(self.LoginPromoFeatureConfig.ShowTimeId) or 0
    self.EndTime = endTime
    self:RefreshTitleByTimeId() -- 计时器启动比较慢 先提前刷新一次
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self:OnBtnCloseClick()
        else
            self:RefreshTitleByTimeId()
        end
    end)
end

function XUiLoginVideoV4P5:RefreshTitleByTimeId()
    local timeSecond = self.EndTime - XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetText("Residue")..XUiHelper.GetTime(timeSecond, XUiHelper.TimeFormatType.CHATEMOJITIMER)
end

function XUiLoginVideoV4P5:OnBtnCloseClick()
    if not self.IsOpenFromLogin then
        self:Close()
        return
    end

    XLoginManager.SetFirstOpenMainUi(true)
    XLuaUiManager.RunMain()
end

function XUiLoginVideoV4P5:OnBtnGoClick()
    self.BtnGoClicked = true
    self:PlayAnimation("BtnDisable")
end

function XUiLoginVideoV4P5:TryGoShownDrawMain()
    if not XLuaUiManager.IsUiLoad("UiNewDrawMain") then
        return false
    end

    self:CloseVideo()
    self:Close()

    return true
end

function XUiLoginVideoV4P5:DoGo()
    local list = XFunctionConfig.GetSkipFuncCfg(self.LoginPromoFeatureConfig.GotoSkipId)
    if list.FunctionalId ~= nil and list.FunctionalId ~= 0 then
        -- 屏蔽功能
        if XFunctionManager.CheckFunctionFitter(list.FunctionalId) then
            XUiManager.TipMsg(CS.XTextManager.GetText("FunctionalMaintain"))
            return false
        end

        if not XFunctionManager.DetectionFunction(list.FunctionalId) then
            return false
        end
    end

    if self:TryGoShownDrawMain() then
        return true
    end

    self:CloseVideo()
    self:Close()
    XFunctionManager.SkipInterface(self.LoginPromoFeatureConfig.GotoSkipId)
end

function XUiLoginVideoV4P5:OnDisable()
    self:CloseVideo()
end

function XUiLoginVideoV4P5:OnDestroy()
    self:CloseVideo()
end

function XUiLoginVideoV4P5:CloseVideo()
    if self.TimerId then
        XScheduleManager.UnSchedule(self.TimerId)
    end
    if not XTool.UObjIsNil(self.VideoPlayerUgui1) then self.VideoPlayerUgui1:Stop() end
    if not XTool.UObjIsNil(self.VideoPlayerUgui2) then self.VideoPlayerUgui2:Stop() end
    if not XTool.UObjIsNil(self.VideoPlayerUgui3) then self.VideoPlayerUgui3:Stop() end
end
