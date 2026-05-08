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

    self.VideoPlayerUgui1:SetInfoByVideoId(targetGotoConfig.VideoConfigId[1])
    self.VideoPlayerUgui2:SetInfoByVideoId(targetGotoConfig.VideoConfigId[2])
    self.VideoPlayerUgui3:SetInfoByVideoId(targetGotoConfig.VideoConfigId[3])
    self.VideoPlayerUgui1:Prepare()
    self.VideoPlayerUgui2:Prepare()
    self.VideoPlayerUgui3:Prepare()
    -- self.VideoPlayerUgui3:Prepare()

    self:InitTimes()

    XMVCA.XUiMain:SetUiLoginVideoV4P0OpenTriggerTrue()
    XSaveTool.SaveData(targetGotoConfig.Id.."LoginPromoFeatureConfig"..XPlayer.Id, 1)

    self.CurrentVideoIndex = 1
    self.VideoPlayTime = 0          -- 当前视频已播放时长
    self.AlphaFadeDuration = 0.1   -- alpha渐变持续时间
    self.VideoFadeTimer = 0        -- alpha渐变计时器
    self.IsFading = false          -- 是否正在做alpha渐变
    self.Video2Triggered = false   -- 视频2是否已触发播放
    self.Video3Triggered = false   -- 视频3是否已触发播放
    self.Video2PlayTime = 0        -- 视频2已播放时长

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

    -- 当前视频播放计时
    self.VideoPlayTime = self.VideoPlayTime + dt

    -- 视频2在12.13s开始播放
    if self.CurrentVideoIndex == 1 and self.VideoPlayTime >= 12.03 and not self.Video2Triggered then
        self.Video2Triggered = true
        self.CurrentVideoIndex = 2
        if not XTool.UObjIsNil(self.VideoPlayerUgui2) then
            self.VideoPlayerUgui2:Play()
        end
    end

    -- 透明度渐变从13.03s开始, 持续0.1s
    if self.Video2Triggered and self.VideoPlayTime >= 13.03 and not self.IsFading then
        if not XTool.UObjIsNil(self.VideoImg1) and self.VideoImg1.color.a > 0 then
            self.VideoFadeTimer = 0
            self.IsFading = true
        end
    end

    -- 视频1在13.13s时隐藏
    if self.Video2Triggered and self.VideoPlayTime >= 13.13 then
        if not XTool.UObjIsNil(self.VideoPlayerUgui1) and self.VideoPlayerUgui1.gameObject.activeSelf then
            self.VideoPlayerUgui1.gameObject:SetActiveEx(false)
        end
    end

    -- 视频2播放1.5s后触发视频3播放
    if self.Video2Triggered and not self.Video3Triggered then
        self.Video2PlayTime = self.Video2PlayTime + dt
        if self.Video2PlayTime >= 1.5 then
            self.Video3Triggered = true
            self.VideoPlayerUgui3:Play()
            self:PlayAnimation("BtnEnable")
        end
    end
end

function XUiLoginVideoV4P5:InitTimes()
    if XTool.IsNumberValid(self.ForceId) then
        return
    end
    
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
    XLoginManager.SetFirstOpenMainUi(true)
    XLuaUiManager.RunMain()
end

function XUiLoginVideoV4P5:OnBtnGoClick()
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

    self:Close()
    XFunctionManager.SkipInterface(self.LoginPromoFeatureConfig.GotoSkipId)
end

function XUiLoginVideoV4P5:OnDestroy()
    if self.TimerId then
        XScheduleManager.UnSchedule(self.TimerId)
    end
end