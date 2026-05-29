---@class XUiLoginVideoV4P0: XLuaUi
local XUiLoginVideoV4P0 = XLuaUiManager.Register(XLuaUi, "UiLoginVideoV4P0")

function XUiLoginVideoV4P0:OnAwake()
    self.BtnTanchuangClose.CallBack = function() self:OnBtnCloseClick() end
    self.BtnGo.CallBack = function() self:OnBtnGoClick() end

    self.VideoPlayerUgui1.ActionPlayed = function ()
        self.TimerId = XScheduleManager.ScheduleOnce(function()
            self.Effect.gameObject:SetActiveEx(true)
            self.Step2.gameObject:SetActiveEx(true)
            self:PlayAnimation("BtnEnable")
        end, XScheduleManager.SECOND * 7.85)
        
        self.TimerId2 = XScheduleManager.ScheduleOnce(function()
            self.VideoPlayerUgui2:Play()
            self.VideoPlayerUgui1:Stop()
            self.VideoPlayerUgui1.gameObject:SetActiveEx(false)
        end, XScheduleManager.SECOND * 8.2)
    end
end

function XUiLoginVideoV4P0:OnStart(forceId)
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

    self.VideoPlayerUgui1:SetInfoByVideoId(targetGotoConfig.VideoConfigId[1])
    self.VideoPlayerUgui2:SetInfoByVideoId(targetGotoConfig.VideoConfigId[2])
    self.VideoPlayerUgui1:Prepare()
    self.VideoPlayerUgui2:Prepare()

    self:InitTimes()

    if self.IsOpenFromLogin then
        XMVCA.XUiMain:SetUiLoginVideoV4P0OpenTriggerTrue()
    end
    XSaveTool.SaveData(targetGotoConfig.Id.."LoginPromoFeatureConfig"..XPlayer.Id, 1)
end

function XUiLoginVideoV4P0:InitTimes()
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

function XUiLoginVideoV4P0:RefreshTitleByTimeId()
    local timeSecond = self.EndTime - XTime.GetServerNowTimestamp()
    self.TxtTime.text = XUiHelper.GetText("Residue")..XUiHelper.GetTime(timeSecond, XUiHelper.TimeFormatType.CHATEMOJITIMER)
end

function XUiLoginVideoV4P0:OnBtnCloseClick()
    if not self.IsOpenFromLogin then
        self:Close()
        return
    end

    XLoginManager.SetFirstOpenMainUi(true)
    XLuaUiManager.RunMain()
end

function XUiLoginVideoV4P0:TryGoShownDrawMain()
    if not XLuaUiManager.IsUiLoad("UiNewDrawMain") then
        return false
    end

    self:CloseVideo()
    self:Close()
    
    return true
end

function XUiLoginVideoV4P0:OnBtnGoClick()
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

function XUiLoginVideoV4P0:OnDisable()
    self:CloseVideo()
end

function XUiLoginVideoV4P0:OnDestroy()
    self:CloseVideo()
end

function XUiLoginVideoV4P0:CloseVideo()
    if self.TimerId then
        XScheduleManager.UnSchedule(self.TimerId)
        self.TimerId = nil
    end

    if self.TimerId2 then
        XScheduleManager.UnSchedule(self.TimerId2)
        self.TimerId2 = nil
    end

    if not XTool.UObjIsNil(self.VideoPlayerUgui1) then self.VideoPlayerUgui1:Stop() end
    if not XTool.UObjIsNil(self.VideoPlayerUgui2) then self.VideoPlayerUgui2:Stop() end
end