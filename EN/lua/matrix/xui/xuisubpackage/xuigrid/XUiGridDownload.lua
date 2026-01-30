

---@class XUiGridDownload : XUiNode
---@field _Control XSubPackageControl
local XUiGridDownload = XClass(XUiNode, "XUiGridDownload")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@param isPreview
function XUiGridDownload:OnStart(isPreview)
    self.IsPreview = isPreview
    self.GridDic = {}
    self:InitCb()
end

function XUiGridDownload:InitCb()
    self.BtnDownLoad.CallBack = function() 
        self:OnBtnDownLoadClick()
    end

    self.BtnPause.CallBack = function()
        self:OnBtnPauseClick()
    end

    self.BtnDownLoading.CallBack = function()
        self:OnBtnDownLoadingClick()
    end
    
    self.BtnPrepare.CallBack = function()
        self:OnBtnPrepareClick()
    end
end

function XUiGridDownload:Refresh(subpackageId)
    self.Id = subpackageId
    local index = self._Control:GetSubpackageIndex(subpackageId)
    if self.Parent.IsShortVersion then
        local subConfig = XMVCA.XSubPackage:GetSubpackageTemplate(subpackageId)
        local typeName = self._Control:GetGroupNameShort(subConfig.Type)
        self.TxtName.text = string.format("%s - %02d %s", typeName, index, self._Control:GetSubPackageName(subpackageId))
    else
        self.TxtName.text = string.format("%02d %s", index, self._Control:GetSubPackageName(subpackageId))
    end
    self.TxtDescribe.text = self._Control:GetSubPackageDesc(subpackageId)
    local item = self._Control:GetSubpackageItem(subpackageId)
    local size, unit = item:GetSubpackageSizeWithUnit(subpackageId)
    self.TxtSize.text = size .. unit
    
    local imgBanner = self._Control:GetSubPackageBanner(subpackageId)
    if not string.IsNilOrEmpty(imgBanner) then
        self.BgImage:SetRawImage(imgBanner)
    end

    local progress = item:GetProgress()
    local state = item:GetState()
    self:RefreshProgressOnly(progress)
    if self.IsPreview then
        self.BtnDownLoad.gameObject:SetActiveEx(false)
        self.BtnPause.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE 
                or state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.NOT_DOWNLOAD 
                or state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING)
        self.BtnDownLoading.gameObject:SetActiveEx(false)
        self.BtnComplete.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE)
        self.BtnPrepare.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD)
    else
        self.BtnDownLoad.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.NOT_DOWNLOAD)
        self.BtnPause.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE)
        self.BtnDownLoading.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING)
        self.BtnComplete.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE)
        self.BtnPrepare.gameObject:SetActiveEx(state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD)
    end

    -- 任务奖励
    if not self.GridCommon then return end
    self.GridCommon.gameObject:SetActiveEx(false)
    for i, grid in ipairs(self.GridDic) do
        grid.GameObject:SetActiveEx(false)
    end
    local downloadTaskId = self._Control:GetSubpackageDownloadTaskId(subpackageId)
    if not XTool.IsNumberValid(downloadTaskId) then 
        return 
    end

    local taskData = XDataCenter.TaskManager.GetTaskDataById(downloadTaskId)
    local taskConfig = XDataCenter.TaskManager.GetTaskTemplate(downloadTaskId)
    local rewards = XRewardManager.GetRewardList(taskConfig.RewardId)

    for i = 1, #rewards do
        local grid = self.GridDic[i]
        local reward = rewards[i]
        if not grid then
            local gridGo = XUiHelper.Instantiate(self.GridCommon, self.GridCommon.parent)
            grid = XUiGridCommon.New(self.Parent.Parent, gridGo)
            grid:SetProxyClickFunc(function ()
                return self:OnGridCommonClick(downloadTaskId)
            end)
            self.GridDic[i] = grid
        end
        grid:Refresh(reward)
        grid.GameObject:SetActiveEx(true)

        -- 奖励领取状态
        local PanelEffect = grid.Transform:FindTransform("PanelEffect")
        local isStateAchieved = taskData.State == XDataCenter.TaskManager.TaskState.Achieved
        local isStateFinish = taskData.State == XDataCenter.TaskManager.TaskState.Finish
        PanelEffect.gameObject:SetActiveEx(isStateAchieved)
        grid:SetReceived(isStateFinish)
    end
end

function XUiGridDownload:OnGridCommonClick(downloadTaskId)
    local taskData = XDataCenter.TaskManager.GetTaskDataById(downloadTaskId)
    if taskData.State ~= XDataCenter.TaskManager.TaskState.Achieved then
        return true
    end
    
    XDataCenter.TaskManager.FinishTask(downloadTaskId, function (rewardGoodsList)
        XUiManager.OpenUiObtain(rewardGoodsList)
        self.Parent:OnlyRefreshGridData()
    end)

    return false
end

function XUiGridDownload:RefreshProgressOnly(progress)
    local progressPercent = math.floor(progress * 100) .. "%"
    self.ImgProgress.fillAmount = progress

    local item = self._Control:GetSubpackageItem(self.Id)
    local isInCheck = item and item:IsProgressLess() or false
    self.BtnPause:SetNameByGroup(0, progressPercent)
    self.BtnDownLoading:SetNameByGroup(0, isInCheck and XUiHelper.GetText("FileChecking") or progressPercent)
end

function XUiGridDownload:OnBtnDownLoadClick()
    if self.IsPreview then
        return
    end
    XMVCA.XSubPackage:AddToDownload(self.Id)
end

function XUiGridDownload:OnBtnPauseClick()
    if self.IsPreview then
        return
    end
    XMVCA.XSubPackage:AddToDownload(self.Id)
end

function XUiGridDownload:OnBtnDownLoadingClick()
    if self.IsPreview then
        return
    end
    XMVCA.XSubPackage:PauseDownload(self.Id)
end

function XUiGridDownload:OnBtnPrepareClick()
    if self.IsPreview then
        return
    end
    XMVCA.XSubPackage:ProcessPrepare(self.Id)
end

function XUiGridDownload:GetSubpackageId()
    return self.Id
end


return XUiGridDownload