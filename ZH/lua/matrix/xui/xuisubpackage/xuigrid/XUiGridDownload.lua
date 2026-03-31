---@class XUiGridDownload : XUiNode
---@field _Control XSubPackageControl
local XUiGridDownload = XClass(XUiNode, "XUiGridDownload")
local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")

function XUiGridDownload:OnStart()
    self.GridDic = {}
    self:InitCb()

    -- 缓存 BtnCustom 内部节点引用
    local btnCustomObj = self.BtnCustom:GetComponent("UiObject")
    self._CustomNormalTxtDownloading = btnCustomObj:GetObject("NormalTxtDownloading")
    self._CustomNormalTxtDesc = btnCustomObj:GetObject("NormalTxtDesc")
    self._CustomPressTxtDownloading = btnCustomObj:GetObject("PressTxtDownloading")
    self._CustomPressTxtDesc = btnCustomObj:GetObject("PressTxtDesc")
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

    self.BtnDelete.CallBack = function()
        self:OnBtnDeleteClick()
    end

    self.BtnCustom.CallBack = function()
        self:OnBtnCustomClick()
    end

    local DOWNLOAD_STATE = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE
    -- 按钮状态配置
    self.ButtonStateConfig = {
        [DOWNLOAD_STATE.PAUSE]            = { BtnPause = true, BtnDelete = function(id) return XMVCA.XSubPackage:CheckSubpackageCanUninstall(id) and XMVCA.XSubPackage:GetSubpackageTemplate(id).AllowDelete and not XMVCA.XSubPackage:IsSubOrResDownloading(id) end },
        [DOWNLOAD_STATE.NOT_DOWNLOAD]     = { BtnDownLoad = true },
        [DOWNLOAD_STATE.DOWNLOADING]      = { BtnDownLoading = true },
        [DOWNLOAD_STATE.COMPLETE]         = { BtnComplete = true, BtnDelete = function(id) return XMVCA.XSubPackage:CheckSubpackageCanUninstall(id) and XMVCA.XSubPackage:GetSubpackageTemplate(id).AllowDelete and not XMVCA.XSubPackage:IsSubOrResDownloading(id) end },
        [DOWNLOAD_STATE.PREPARE_DOWNLOAD] = { BtnPrepare = true },
        [DOWNLOAD_STATE.UNINSTALLED]      = { BtnDownLoad = true },
    }
end

-- 根据状态刷新按钮显示
function XUiGridDownload:RefreshButtons(state, subpackageId)
    local config = self.ButtonStateConfig[state] or {}

    self.BtnDownLoad.gameObject:SetActiveEx(config.BtnDownLoad or false)
    self.BtnPause.gameObject:SetActiveEx(config.BtnPause or false)
    self.BtnDownLoading.gameObject:SetActiveEx(config.BtnDownLoading or false)
    self.BtnComplete.gameObject:SetActiveEx(config.BtnComplete or false)
    self.BtnPrepare.gameObject:SetActiveEx(config.BtnPrepare or false)

    self:_RefreshDeleteButton(state, subpackageId)
end

function XUiGridDownload:_RefreshDeleteButton(state, subpackageId)
    local config = self.ButtonStateConfig[state] or {}
    local deleteVisible = config.BtnDelete
    if type(deleteVisible) == "function" then
        self.BtnDelete.gameObject:SetActiveEx(deleteVisible(subpackageId))
    elseif type(deleteVisible) == "boolean" then
        self.BtnDelete.gameObject:SetActiveEx(deleteVisible)
    else
        self.BtnDelete.gameObject:SetActiveEx(false)
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
    -- 按钮显隐：CustomSkipId 格子与普通格子互斥
    local subConfig = XMVCA.XSubPackage:GetSubpackageTemplate(subpackageId)
    local customSkipId = subConfig and subConfig.CustomSkipId or 0
    local hasCustomSkip = XTool.IsNumberValid(customSkipId)
    self.BtnCustom.gameObject:SetActiveEx(hasCustomSkip)
    if hasCustomSkip then
        self.BtnDownLoad.gameObject:SetActiveEx(false)
        self.BtnDownLoading.gameObject:SetActiveEx(false)
        self.BtnPause.gameObject:SetActiveEx(false)
        self.BtnPrepare.gameObject:SetActiveEx(false)
        self.BtnComplete.gameObject:SetActiveEx(false)
        self:_RefreshDeleteButton(state, subpackageId)
        self:_RefreshCustomButton(subpackageId)
    else
        self:RefreshButtons(state, subpackageId)
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
    local item = self._Control:GetSubpackageItem(self.Id)
    if item and item:IsUninstalled() then
        -- [F3] UNINSTALLED 时检查是否有活跃下载的 Res（防御性兜底）
        local hasActiveRes = false
        local template = XMVCA.XSubPackage:GetSubpackageTemplate(self.Id)
        local resIds = template and template.ResIds
        if resIds then
            for _, resId in ipairs(resIds) do
                local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
                if resItem then
                    local resState = resItem:GetState()
                    if resState == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING
                        or resState == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD
                        or resState == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE then
                        hasActiveRes = true
                        break
                    end
                end
            end
        end
        if not hasActiveRes then
            progress = 0
        end
    end

    local progressPercent = math.floor(progress * 100) .. "%"
    self.ImgProgress.fillAmount = progress

    local isInCheck = item and item:IsProgressLess() or false
    self.BtnPause:SetNameByGroup(0, progressPercent)
    self.BtnDownLoading:SetNameByGroup(0, isInCheck and XUiHelper.GetText("FileChecking") or progressPercent)
end

function XUiGridDownload:OnBtnDownLoadClick()
    XMVCA.XSubPackage:AddToDownload(self.Id, true)
end

function XUiGridDownload:OnBtnPauseClick()
    XMVCA.XSubPackage:AddToDownload(self.Id, true)
end

function XUiGridDownload:OnBtnDownLoadingClick()
    XMVCA.XSubPackage:PauseDownload(self.Id)
end

function XUiGridDownload:OnBtnPrepareClick()
    XMVCA.XSubPackage:ProcessPrepare(self.Id)
end

--- 刷新 BtnCustom 内部节点显隐（Desc 对与 Downloading 对互斥切换）
function XUiGridDownload:_RefreshCustomButton(subpackageId)
    local isDownloading = self:_IsCustomDownloading(subpackageId)
    -- 下载中：显示 Downloading 对
    self._CustomNormalTxtDownloading.gameObject:SetActiveEx(isDownloading)
    self._CustomPressTxtDownloading.gameObject:SetActiveEx(isDownloading)
    -- 非下载中：显示 Desc 对
    self._CustomNormalTxtDesc.gameObject:SetActiveEx(not isDownloading)
    self._CustomPressTxtDesc.gameObject:SetActiveEx(not isDownloading)
end

--- 判断 sub 或其包含的 res 是否处于下载中或等待队列中
function XUiGridDownload:_IsCustomDownloading(subpackageId)
    local DOWNLOAD_STATE = XEnumConst.SUBPACKAGE.DOWNLOAD_STATE
    -- Sub 级状态
    local item = self._Control:GetSubpackageItem(subpackageId)
    local subState = item:GetState()
    if subState == DOWNLOAD_STATE.DOWNLOADING or subState == DOWNLOAD_STATE.PREPARE_DOWNLOAD then
        return true
    end
    -- Res 级状态：遍历子资源，任一处于下载中/等待队列即判定为下载中
    local template = XMVCA.XSubPackage:GetSubpackageTemplate(subpackageId)
    if template and template.ResIds then
        for _, resId in ipairs(template.ResIds) do
            local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
            if resItem then
                local resState = resItem:GetState()
                if resState == DOWNLOAD_STATE.DOWNLOADING
                    or resState == DOWNLOAD_STATE.PREPARE_DOWNLOAD then
                    return true
                end
            end
        end
    end
    return false
end

function XUiGridDownload:OnBtnCustomClick()
    local subConfig = XMVCA.XSubPackage:GetSubpackageTemplate(self.Id)
    local customSkipId = subConfig and subConfig.CustomSkipId or 0
    if not XTool.IsNumberValid(customSkipId) then
        return
    end
    XFunctionManager.SkipInterface(customSkipId)
end

function XUiGridDownload:OnBtnDeleteClick()
    -- [F8] 从全局 IsDownloading() 改为按 Sub 粒度检查
    if XMVCA.XSubPackage:IsSubOrResDownloading(self.Id) then
        XUiManager.TipText("SubpackageUninstallRejectDownloading")
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