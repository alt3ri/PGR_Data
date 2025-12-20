---@class XUiFirstDownloadTips: XLuaUi
---@field _Control XSubPackageControl
local XUiFirstDownloadTips = XLuaUiManager.Register(XLuaUi, 'UiFirstDownloadTips')

function XUiFirstDownloadTips:OnAwake()
    self.BtnDownload:AddEventListener(handler(self, self.OnBtnDownloadClickEvent))
    self.BtnNoDownload:AddEventListener(handler(self, self.Close))
    self.BtnDownLoading:AddEventListener(handler(self, self.OnBtnDownloadingClickEvent))
    self.BtnBack:AddEventListener(handler(self, self.Close))

    if self.BtnGetAward then
        self.BtnGetAward:AddEventListener(handler(self, self.OnBtnGetRewardClickEvent))
    end
    
    self.BtnDownload.gameObject:SetActiveEx(false)
    self.BtnNoDownload.gameObject:SetActiveEx(false)
end

function XUiFirstDownloadTips:OnStart()
    self:InitBaseShow()
end

function XUiFirstDownloadTips:OnEnable()
    self:RefreshStateShow()
end

function XUiFirstDownloadTips:OnDestroy()
    self:StopProgressTimer()
end

function XUiFirstDownloadTips:OnGetLuaEvents()
    return {
        XEventId.EVENT_SUBPACKAGE_COMPLETE,
        XEventId.EVENT_SUBPACKAGE_START,
        XEventId.EVENT_SUBPACKAGE_PAUSE,
    }
end

function XUiFirstDownloadTips:OnNotify(evt, ...)
    if evt == XEventId.EVENT_SUBPACKAGE_COMPLETE then
        self:OnSubpackageComplete()
    elseif evt == XEventId.EVENT_SUBPACKAGE_START then
        self:StopProgressTimer()
        self:CheckAndStartProgressTimer()
    elseif evt == XEventId.EVENT_SUBPACKAGE_PAUSE then
        self:RefreshStateShow()
    end
end

---- 初始化基础显示，这部分显示无需动态刷新
function XUiFirstDownloadTips:InitBaseShow()
    -- 设置背景大图
    local bgPath = XMVCA.XMainLine2:GetClientConfigParams('DownloadBg', 1)

    if not string.IsNilOrEmpty(bgPath) then
        self.BgPic:SetRawImage(bgPath)
    end

    -- 设置中间多行的提示文本
    for i = 1, 10 do
        local ui = self['TxtTip' .. i]

        if ui then
            ui.text = XMVCA.XMainLine2:GetClientConfigParams('DownloadTipsGroup', i) or ''
        else
            break
        end
    end
    
    -- 设置包体大小显示
    self.TxtMb.text = XUiHelper.FormatText(XMVCA.XMainLine2:GetClientConfigParams('DownloadTotalSizeLabel', 1), self:GetDownloadTotalSize())
end

function XUiFirstDownloadTips:RefreshStateShow()
    self.BtnDownload.gameObject:SetActiveEx(false)
    self.BtnNoDownload.gameObject:SetActiveEx(false)
    self.BtnDownLoading.gameObject:SetActiveEx(false)
    self.SliderDownload.gameObject:SetActiveEx(false)
    if self.BtnGetAward then
        self.BtnGetAward.gameObject:SetActiveEx(false)
    end
    
    self:StopProgressTimer()
    
    if XMVCA.XSubPackage:CheckNecessaryIsReadyDownload() then
        self:CheckAndStartProgressTimer()
    elseif XMVCA.XSubPackage:CheckNecessaryComplete() then
        self.BtnDownLoading.gameObject:SetActiveEx(true)
        self.BtnDownLoading:SetButtonState(CS.UiButtonState.Disable)
        self._IsComplete = true

        local isShowRewardGet = XMVCA.XSubPackage:CheckNecessaryTaskState(XDataCenter.TaskManager.TaskState.Achieved)
        
        if self.BtnGetAward then
            self.BtnGetAward.gameObject:SetActiveEx(isShowRewardGet)
        end
    elseif XMVCA.XSubPackage:CheckNecessaryIsPaused() then
        self.BtnDownLoading.gameObject:SetActiveEx(true)
        self.SliderDownload.gameObject:SetActiveEx(true)
        self.BtnDownLoading:SetButtonState(CS.UiButtonState.Select)
        self._IsPause = true
        self:UpdateProgress()
    else
        self.BtnDownload.gameObject:SetActiveEx(true)
        self.BtnNoDownload.gameObject:SetActiveEx(true)
    end
end

function XUiFirstDownloadTips:OnBtnDownloadClickEvent()
    --开始下载必要资源
    XMVCA.XSubPackage:AddNecessaryToDownload()
    XMVCA.XSubPackage:StartDownload()
    self:Close()
end

function XUiFirstDownloadTips:OnBtnDownloadingClickEvent()
    if self._IsComplete then
        return
    end
    
    if self._IsPause then
        -- 继续
        XMVCA.XSubPackage:AddNecessaryToDownload()
        XMVCA.XSubPackage:StartDownload()
        self:RefreshStateShow()
    else
        -- 暂停
        XMVCA.XSubPackage:PauseNecessaryDownload()
        self:StopProgressTimer()
    end
    
    self._IsPause = not self._IsPause
end

function XUiFirstDownloadTips:OnBtnGetRewardClickEvent()
    local taskId = CS.XGame.ClientConfig:GetInt("SubpackageNecessaryTaskId")
    if not taskId then
        return
    end
    local taskData = XDataCenter.TaskManager.GetTaskDataById(taskId)
    if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
        XDataCenter.TaskManager.FinishTask(taskId, function(rewardGoodsList)
            if not XTool.IsTableEmpty(rewardGoodsList) then
                XUiManager.OpenUiObtain(rewardGoodsList)
            end
            self:RefreshStateShow()
        end)
    end
end

function XUiFirstDownloadTips:GetDownloadPercent()
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

function XUiFirstDownloadTips:GetDownloadPercentStr()
    local percent = self:GetDownloadPercent()

    return math.floor(percent * 100)
end

function XUiFirstDownloadTips:GetDownloadTotalSize()
    local subIds = XMVCA.XSubPackage:GetNecessarySubIds()
    local totalSize = 0

    if not XTool.IsTableEmpty(subIds) then
        for i, subId in pairs(subIds) do
            totalSize = totalSize + XMVCA.XSubPackage:GetSubPackageTotalSizeBySubId(subId)
        end
    end
    
    -- 单位转换
    totalSize = XMath.ToInt(totalSize / math.pow(2, 20))
    
    return totalSize
end

function XUiFirstDownloadTips:CheckAndStartProgressTimer()
    if not XMVCA.XSubPackage:IsOpen() then
        self:Close()
        return
    end

    -- 判断必要资源是否正在下载
    if XMVCA.XSubPackage:CheckNecessaryIsReadyDownload() then
        self.BtnDownLoading.gameObject:SetActiveEx(true)
        self.SliderDownload.gameObject:SetActiveEx(true)
        self.BtnDownLoading:SetButtonState(CS.UiButtonState.Normal)
        self._IsPause = false
        self:UpdateProgress()
        self._DownloadProgressTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateProgress), XScheduleManager.SECOND)
    end
end

function XUiFirstDownloadTips:StopProgressTimer()
    if self._DownloadProgressTimerId then
        XScheduleManager.UnSchedule(self._DownloadProgressTimerId)
        self._DownloadProgressTimerId = nil
    end
end

function XUiFirstDownloadTips:UpdateProgress()
    local percentStr = self:GetDownloadPercentStr()
    local percent = self:GetDownloadPercent()

    -- 显示百分比
    self.BtnDownLoading:SetNameByGroup(0, XUiHelper.FormatText(XMVCA.XMainLine2:GetClientConfigParams('DownloadProgressLabel', 1), percentStr))
    self.SliderDownload.value = percent

    if percent == 1 and XMVCA.XSubPackage:CheckNecessaryComplete() then
        self:StopProgressTimer()
    end
end

function XUiFirstDownloadTips:UpdateProgressOnPaused()
    local percentStr = self:GetDownloadPercentStr()
    local percent = self:GetDownloadPercent()
    
    -- 显示百分比
    self.BtnDownLoading:SetNameByGroup(0, XUiHelper.FormatText(XMVCA.XMainLine2:GetClientConfigParams('DownloadProgressLabel', 1), percentStr))
    self.SliderDownload.value = percent

    if percent == 1 and XMVCA.XSubPackage:CheckNecessaryComplete() then
        self:StopProgressTimer()
    end
end

function XUiFirstDownloadTips:OnSubpackageComplete()
    if XMVCA.XSubPackage:CheckNecessaryComplete() then
        local cb = function()
            self:RefreshStateShow()
        end
        
        XMVCA.XSubPackage:RequestNecessaryTask(cb, cb)
    end
end

return XUiFirstDownloadTips