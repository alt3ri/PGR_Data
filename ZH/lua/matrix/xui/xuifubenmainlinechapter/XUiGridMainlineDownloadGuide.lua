--- 主线第一章全包下载引导入口
---@class XUiGridMainlineDownloadGuide: XUiNode
local XUiGridMainlineDownloadGuide = XClass(XUiNode, 'XUiGridMainlineDownloadGuide')

function XUiGridMainlineDownloadGuide:OnStart()
    self.BtnDownload:AddEventListener(handler(self, self.OnBtnDownloadClick))
end

function XUiGridMainlineDownloadGuide:OnEnable()
    self:CheckState()
end

function XUiGridMainlineDownloadGuide:OnDestroy()
    self:StopProgressTimer()
end

function XUiGridMainlineDownloadGuide:OnGetLuaEvents()
    return {
        XEventId.EVENT_SUBPACKAGE_COMPLETE,
        XEventId.EVENT_SUBPACKAGE_START,
        XEventId.EVENT_SUBPACKAGE_PAUSE,
    }
end

function XUiGridMainlineDownloadGuide:OnNotify(evt, ...)
    if evt == XEventId.EVENT_SUBPACKAGE_COMPLETE then
        self:OnSubpackageComplete()
    elseif evt == XEventId.EVENT_SUBPACKAGE_START then
        self:StopProgressTimer()
        self:CheckAndStartProgressTimer()
    elseif evt == XEventId.EVENT_SUBPACKAGE_PAUSE then
        self:CheckState()
    end
end

function XUiGridMainlineDownloadGuide:OnBtnDownloadClick()
    XLuaUiManager.Open('UiFirstDownloadTips')
end

function XUiGridMainlineDownloadGuide:CheckShow()
    -- 分包未开启不显示
    if not XMVCA.XSubPackage:IsOpen() then
        self:Close()
        return
    end
    
    local isShow = false
    
    local condition = XMVCA.XMainLine2:GetClientConfigParams('DownloadEntranceShowCondition', 1)
    
    local isConditionSuccess = not XTool.IsNumberValidEx(condition) or XConditionManager.CheckCondition(condition)
    
    -- 奖励没有领取完才考虑是否显示
    if not XMVCA.XSubPackage:CheckNecessaryTaskState(XDataCenter.TaskManager.TaskState.Finish) then
        -- 需满足未下载完成且满足条件
        if not XMVCA.XSubPackage:CheckNecessaryComplete() and isConditionSuccess then
            isShow = true
        end
    end

    if not isShow then
        -- 必要下载奖励可领取时也显示
        if XMVCA.XSubPackage:CheckNecessaryTaskState(XDataCenter.TaskManager.TaskState.Achieved) then
            isShow = true
        end
    end

    if isShow then
        self:Open()
    else
        self:Close()
    end
end

function XUiGridMainlineDownloadGuide:CheckState()
    self.BtnDownload:SetNameByGroup(1, '')
    self:StopProgressTimer()
    
    -- 隐藏完成的图标
    if self.ImgIcon3 then
        self.ImgIcon3.gameObject:SetActiveEx(false)
    end

    if self.ImgIcon2Root then
        self.ImgIcon2Root.gameObject:SetActiveEx(true)
    end

    if XMVCA.XSubPackage:CheckNecessaryComplete() then
        self.BtnDownload:SetNameByGroup(1, XMVCA.XMainLine2:GetClientConfigParams('DownloadEntranceRewardTips', 1))

        if self.ImgIcon3 then
            self.ImgIcon3.gameObject:SetActiveEx(true)
        end

        if self.ImgIcon2Root then
            self.ImgIcon2Root.gameObject:SetActiveEx(false)
        end
    elseif XMVCA.XSubPackage:CheckNecessaryIsPaused() then
        self:UpdateProgressOnPaused()
    else
        self:CheckAndStartProgressTimer()
    end
end

function XUiGridMainlineDownloadGuide:GetDownloadPercent()
    local subIds = XMVCA.XSubPackage:GetNecessarySubIds()
    local totalSize = 0
    local downloadSize = 0

    if not XTool.IsTableEmpty(subIds) then
        for i, subId in pairs(subIds) do
            totalSize = totalSize + XMVCA.XSubPackage:GetSubPackageTotalSizeBySubId(subId)
            downloadSize = downloadSize + XMVCA.XSubPackage:GetSubPackageDownloadSizeBySubId(subId)
        end
    end

    local percent = 1

    if XTool.IsNumberValidEx(totalSize) then
        percent = math.min(downloadSize / totalSize, 1)
    end
    
    return percent
end

function XUiGridMainlineDownloadGuide:GetDownloadPercentStr()
    return math.floor(self:GetDownloadPercent() * 100)
end

function XUiGridMainlineDownloadGuide:CheckAndStartProgressTimer()
    if not XMVCA.XSubPackage:IsOpen() then
        self:Close()
        return
    end
    
    -- 判断必要资源是否正在下载
    if XMVCA.XSubPackage:CheckNecessaryIsReadyDownload() then
        self:UpdateProgress()
        self._DownloadProgressTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateProgress), XScheduleManager.SECOND)
        self:StopAnimation('ImgIcon2Loop')
        self:PlayAnimation('DownloadLoop', nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
    end
end

function XUiGridMainlineDownloadGuide:StopProgressTimer()
    if self._DownloadProgressTimerId then
        XScheduleManager.UnSchedule(self._DownloadProgressTimerId)
        self._DownloadProgressTimerId = nil
    end
    
    self:StopAnimation('DownloadLoop')
    self:PlayAnimation('ImgIcon2Loop', nil, nil, CS.UnityEngine.Playables.DirectorWrapMode.Loop)
end

function XUiGridMainlineDownloadGuide:UpdateProgress()
    local percent = self:GetDownloadPercentStr()

    -- 显示百分比
    self.BtnDownload:SetNameByGroup(1, XUiHelper.FormatText(XMVCA.XMainLine2:GetClientConfigParams('DownloadingEntranceTips', 1), percent))


    if percent == 1 and XMVCA.XSubPackage:CheckNecessaryComplete() then
        self:StopProgressTimer()
    end
end

function XUiGridMainlineDownloadGuide:UpdateProgressOnPaused()
    local percent = self:GetDownloadPercentStr()

    -- 显示百分比
    self.BtnDownload:SetNameByGroup(1, XUiHelper.FormatText(XMVCA.XMainLine2:GetClientConfigParams('DownloadEntrancePauseTips', 1), percent))
end

function XUiGridMainlineDownloadGuide:OnSubpackageComplete()
    if XMVCA.XSubPackage:CheckNecessaryComplete() then
        local cb = function()
            self:StopProgressTimer()
            self:CheckState()
        end
        
        XMVCA.XSubPackage:RequestNecessaryTask(cb, cb)
    end
end

return XUiGridMainlineDownloadGuide