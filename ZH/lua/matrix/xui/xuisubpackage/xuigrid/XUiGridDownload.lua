---@class XUiGridDownload : XUiNode
---@field _Control XSubPackageControl
local XUiGridDownload = XClass(XUiNode, "XUiGridDownload")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

---@param isPreview bool
function XUiGridDownload:OnStart(isPreview)
    self.IsPreview = isPreview
    self.GridDic = {}
    self:InitCb()
end

function XUiGridDownload:InitCb()
    if self.BtnDownLoad then
        self.BtnDownLoad.CallBack = function() 
            self:OnBtnDownLoadClick()
        end
    end

    if self.BtnPause then
        self.BtnPause.CallBack = function()
            self:OnBtnPauseClick()
        end
    end

    if self.BtnDownLoading then
        self.BtnDownLoading.CallBack = function()
            self:OnBtnDownLoadingClick()
        end
    end
    
    if self.BtnPrepare then
        self.BtnPrepare.CallBack = function()
            self:OnBtnPrepareClick()
        end
    end

    if self.BtnDelete then
        self.BtnDelete.CallBack = function()
            self:OnBtnDeleteClick()
        end
    end

    local DOWNLOAD_STATE = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE
    -- 按钮状态配置
    self.ButtonStateConfig = {
        [true] = { -- IsPreview = true
            [DOWNLOAD_STATE.PAUSE]            = { BtnPause = true },
            [DOWNLOAD_STATE.NOT_DOWNLOAD]     = { BtnPause = true },
            [DOWNLOAD_STATE.DOWNLOADING]      = { BtnPause = true },
            [DOWNLOAD_STATE.COMPLETE]         = { BtnComplete = true },
            [DOWNLOAD_STATE.PREPARE_DOWNLOAD] = { BtnPrepare = true },
            [DOWNLOAD_STATE.UNINSTALLED]      = { BtnPause = true },
        },
        [false] = { -- IsPreview = false
            [DOWNLOAD_STATE.PAUSE]            = { BtnPause = true, BtnDelete = function(id) return XMVCA.XSubPackage:CheckSubpackageCanUninstall(id) and XMVCA.XSubPackage:GetSubpackageTemplate(id).AllowDelete end },
            [DOWNLOAD_STATE.NOT_DOWNLOAD]     = { BtnDownLoad = true },
            [DOWNLOAD_STATE.DOWNLOADING]      = { BtnDownLoading = true },
            [DOWNLOAD_STATE.COMPLETE]         = { BtnComplete = true, BtnDelete = function(id) return XMVCA.XSubPackage:CheckSubpackageCanUninstall(id) and XMVCA.XSubPackage:GetSubpackageTemplate(id).AllowDelete end },
            [DOWNLOAD_STATE.PREPARE_DOWNLOAD] = { BtnPrepare = true },
            [DOWNLOAD_STATE.UNINSTALLED]        = { BtnDownLoad = true },
        }
    }
end

-- 根据状态刷新按钮显示
function XUiGridDownload:RefreshButtons(state, subpackageId)
    local config = self.ButtonStateConfig[self.IsPreview or false][state] or {}

    self.BtnDownLoad.gameObject:SetActiveEx(config.BtnDownLoad or false)
    self.BtnPause.gameObject:SetActiveEx(config.BtnPause or false)
    self.BtnDownLoading.gameObject:SetActiveEx(config.BtnDownLoading or false)
    self.BtnComplete.gameObject:SetActiveEx(config.BtnComplete or false)
    self.BtnPrepare.gameObject:SetActiveEx(config.BtnPrepare or false)

    local deleteVisible = config.BtnDelete
    if self.BtnDelete then
        if type(deleteVisible) == "function" then
            self.BtnDelete.gameObject:SetActiveEx(deleteVisible(subpackageId))
        elseif type(deleteVisible) == "boolean" then
            self.BtnDelete.gameObject:SetActiveEx(deleteVisible)
        else
            self.BtnDelete.gameObject:SetActiveEx(false)
        end
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
    local state = item:GetState()

    local size, unit = item:GetSubpackageSizeWithUnit(subpackageId)
    self.TxtSize.text = size .. unit
    
    local imgBanner = self._Control:GetSubPackageBanner(subpackageId)
    if not string.IsNilOrEmpty(imgBanner) then
        self.BgImage:SetRawImage(imgBanner)
    end

    local progress = item:GetProgress()
    self:RefreshProgressOnly(progress)
    self:RefreshButtons(state, subpackageId)

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
    local item = self._Control:GetSubpackageItem(self.Id)
    if item and item:IsUninstalled() then -- 业务层强行设置卸载状态显示进度条为0
        progress = 0
    end

    local progressPercent = math.floor(progress * 100) .. "%"
    self.ImgProgress.fillAmount = progress

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

function XUiGridDownload:OnBtnDeleteClick()
    if self.IsPreview then
        return
    end

    local sureCb = function()
        self.Parent.Parent.DeleteMask.gameObject:SetActiveEx(true)
        XMVCA.XSubPackage:UninstallSubpackageById(self.Id, function ()
            self.Parent.Parent.DeleteMask.gameObject:SetActiveEx(false)
        end)
    end
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("SubPackageDeleteConfirm", self._Control:GetSubPackageName(self.Id)), nil, nil, sureCb)
end

function XUiGridDownload:GetSubpackageId()
    return self.Id
end

return XUiGridDownload