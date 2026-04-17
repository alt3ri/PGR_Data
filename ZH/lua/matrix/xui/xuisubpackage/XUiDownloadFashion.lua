---@class XUiDownloadFashion : XLuaUi
local XUiDownloadFashion = XLuaUiManager.Register(XLuaUi, "UiDownloadFashion")

local FilterType = {
    All = 0,
    Own = 1,
    UnOwn = 2,
}

local DownloadMode = {
    Res = "Res",
    Sub = "Sub",
}

-- 下载状态筛选（与 FilterType 形成双维度交集）
local DownloadFilterType = {
    UnDownload = 1,  -- 未下载（含下载中）
    Download = 2,    -- 已下载
}

-- [F7] 会话缓存 key
local function GetSessionKey()
    return "DownloadFashion_Session_" .. (XPlayer.Id or 0)
end

function XUiDownloadFashion:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiDownloadFashion:OnStart()
    self._FilterType = FilterType.Own
    self._DownloadFilterType = DownloadFilterType.UnDownload
    self._SelectedResIds = {}
    -- [F4] 初始化双模式字段
    self._DownloadMode = nil  -- DownloadMode.Res|DownloadMode.Sub|nil
    self._DownloadSubId = nil
    self._IsDownloading = false
    self._IsPaused = false
    self._IsPausing = false -- Res级异步暂停过渡态，等待C#回调完成
    self._DownloadingResIds = {}
end

function XUiDownloadFashion:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_SUBPACKAGE_COMPLETE, self.RefreshView, self)
    XEventManager.AddEventListener(XEventId.EVENT_RES_UPDATE, self.OnResUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_RES_COMPLETE, self.OnResComplete, self)
    -- [F4] 新增事件监听
    XEventManager.AddEventListener(XEventId.EVENT_SUBPACKAGE_PREPARE, self.OnSubpackagePrepareOrStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_SUBPACKAGE_START, self.OnSubpackagePrepareOrStart, self)
    XEventManager.AddEventListener(XEventId.EVENT_SUBPACKAGE_PAUSE, self.OnSubpackagePause, self)
    XEventManager.AddEventListener(XEventId.EVENT_RES_PAUSE_COMPLETE, self.OnResPauseComplete, self)
    -- 每次界面可见时重新检查下载状态（确保事件监听先于状态刷新）
    self:CheckDownloadingState()
    self:RefreshView()
    self:UpdatePanelState()
end

function XUiDownloadFashion:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_SUBPACKAGE_COMPLETE, self.RefreshView, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_UPDATE, self.OnResUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_COMPLETE, self.OnResComplete, self)
    -- [F4] 新增
    XEventManager.RemoveEventListener(XEventId.EVENT_SUBPACKAGE_PREPARE, self.OnSubpackagePrepareOrStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SUBPACKAGE_START, self.OnSubpackagePrepareOrStart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SUBPACKAGE_PAUSE, self.OnSubpackagePause, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_PAUSE_COMPLETE, self.OnResPauseComplete, self)
end

function XUiDownloadFashion:InitButton()
    self.BtnTanchuangCloseBig:AddEventListener(handler(self, self.OnBtnTanchuangCloseBigClick))
    self.BtnFilterAll:AddEventListener(handler(self, self.OnBtnFilterAllClick))
    self.BtnFilterOwn:AddEventListener(handler(self, self.OnBtnFilterOwnClick))
    self.BtnFilterUnOwn:AddEventListener(handler(self, self.OnBtnFilterUnOwnClick))
    self.ToggleSelectAll:AddEventListener(handler(self, self.OnToggleSelectAllClick))
    self.BtnDownload:AddEventListener(handler(self, self.OnBtnDownloadClick))
    self.BtnUninstall:AddEventListener(handler(self, self.OnBtnUninstallClick))
    self.BtnContinue:AddEventListener(handler(self, self.OnBtnContinueClick))
    self.BtnPause:AddEventListener(handler(self, self.OnBtnPauseClick))
    self.BtnFilterUnDownload:AddEventListener(handler(self, self.OnBtnFilterUnDownloadClick))
    self.BtnFilterDownload:AddEventListener(handler(self, self.OnBtnFilterDownloadClick))
    self.BtnCancelDownload:AddEventListener(handler(self, self.OnBtnCancelDownloadClick))
    -- 缓存两个下载状态文本下的进度数字组件
    self._TxtProgressDownloading = self.TxtDownloading.transform:Find("TxtTotalProgressNum"):GetComponent("Text")
    self._TxtProgressWaiting = self.TxtWaiting.transform:Find("TxtTotalProgressNum"):GetComponent("Text")
end

function XUiDownloadFashion:InitDynamicTable()
    local XUiGridDownloadFashion = require("XUi/XUiSubPackage/XUiGrid/XUiGridDownloadFashion")
    self.ListFashion = XUiHelper.DynamicTableNormal(self, self.ListFashion, XUiGridDownloadFashion)
    self.ListFashion:SetDynamicEventDelegate(function(event, index, grid) self:OnListFashionDynamicTableEvent(event, index, grid) end)
end

function XUiDownloadFashion:OnBtnTanchuangCloseBigClick()
    self:Close()
end

function XUiDownloadFashion:OnBtnFilterAllClick()
    self._FilterType = FilterType.All
    self:ClearSelection()
    self:RefreshView()
    self:UpdateFilterBtnState()
end

function XUiDownloadFashion:OnBtnFilterOwnClick()
    self._FilterType = FilterType.Own
    self:ClearSelection()
    self:RefreshView()
    self:UpdateFilterBtnState()
end

function XUiDownloadFashion:OnBtnFilterUnOwnClick()
    self._FilterType = FilterType.UnOwn
    self:ClearSelection()
    self:RefreshView()
    self:UpdateFilterBtnState()
end

function XUiDownloadFashion:OnBtnFilterUnDownloadClick()
    self._DownloadFilterType = DownloadFilterType.UnDownload
    self:ClearSelection()
    self:RefreshView()
    self:UpdateFilterBtnState()
end

function XUiDownloadFashion:OnBtnFilterDownloadClick()
    self._DownloadFilterType = DownloadFilterType.Download
    self:ClearSelection()
    self:RefreshView()
    self:UpdateFilterBtnState()
end

function XUiDownloadFashion:OnToggleSelectAllClick()
    if self._IsDownloading then 
        XUiManager.TipText("DownloadingFashionTip")
        return 
    end
    local isSelectAll = self.ToggleSelectAll:GetToggleState()
    -- 取消全选时清空整个选中字典，避免不在当前视图的orphan条目残留
    if not isSelectAll then
        self._SelectedResIds = {}
    end
    for _, data in ipairs(self._DataList or {}) do
        data.IsSelected = isSelectAll
        self._SelectedResIds[data.ResId] = isSelectAll or nil
    end
    self:RefreshListFashionDynamicTable()
    self:UpdateBottomBtnState()
end

function XUiDownloadFashion:OnBtnDownloadClick()
    -- 只下载未下载完成的ResId
    local resIds = {}
    for resId, _ in pairs(self._SelectedResIds) do
        if not XMVCA.XSubPackage:CheckResDownloadComplete(resId) then
            table.insert(resIds, resId)
        end
    end
    if XTool.IsTableEmpty(resIds) then
        -- 区分"未选中"和"所选均已下载"两种情况
        if next(self._SelectedResIds) then
            XUiManager.TipText("FashionAlreadyDownloaded")
        else
            XUiManager.TipText("SelectFashionToDownload")
        end
        return
    end
    -- [F7] 保存为 Res 模式会话
    self._DownloadMode = DownloadMode.Res
    self._DownloadSubId = nil
    self:SaveDownloadSession(DownloadMode.Res, 0, resIds)
    -- 加入下载队列
    for _, resId in ipairs(resIds) do
        XMVCA.XSubPackage:AddResToDownload(resId)
    end
    self._IsDownloading = true
    self._DownloadingResIds = resIds
    self:ClearSelection()
    self:RefreshGridDataOnly()
    self:UpdatePanelState()
end

function XUiDownloadFashion:OnBtnUninstallClick()
    -- 本界面自身正在下载中，不允许卸载
    if self._IsDownloading then
        XUiManager.TipText("DownloadingFashionTip")
        return
    end
    
    -- 全局有下载任务时不允许卸载（如 UiDownLoadMain 正在下载 Sub）
    if XMVCA.XSubPackage:IsDownloading() then
        XUiManager.TipText("DownloadingFashionTip")
        return
    end

    -- 只卸载已下载完成的ResId
    local resIds = {}
    for resId, _ in pairs(self._SelectedResIds) do
        if XMVCA.XSubPackage:CheckResDownloadComplete(resId) then
            table.insert(resIds, resId)
        end
    end
    if XTool.IsTableEmpty(resIds) then
        XUiManager.TipText("SelectFashionToUninstall")
        return
    end
    local sureCb = function()
        self.DeleteMask.gameObject:SetActiveEx(true)
        XMVCA.XSubPackage:UninstallResourcesByIds(resIds, function()
            if XTool.UObjIsNil(self.GameObject) then return end
            self.DeleteMask.gameObject:SetActiveEx(false)
            self:ClearSelection()
            self:RefreshView()
        end)
    end
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("UninstallFashionConfirm"), nil, nil, sureCb)
end

function XUiDownloadFashion:OnBtnContinueClick()
    -- [F6] Sub 模式分流
    if self._DownloadMode == DownloadMode.Sub then
        self:ContinueSubMode()
        return
    end
    -- Res模式：维持原行为
    for _, resId in ipairs(self._DownloadingResIds or {}) do
        if not XMVCA.XSubPackage:CheckResDownloadComplete(resId) then
            XMVCA.XSubPackage:AddResToDownload(resId)
        end
    end
    self._IsPaused = false
    self._IsPausing = false
    self:UpdateDownloadBtnState()
    self:UpdateDownloadProgress()
end

function XUiDownloadFashion:OnBtnPauseClick()
    -- [F6] Sub 模式分流
    if self._DownloadMode == DownloadMode.Sub then
        self:PauseSubMode()
        return
    end
    -- Res模式：已在暂停中则忽略重复点击
    if self._IsPausing then
        return
    end
    -- 等待中：所有res都只在队列里，没有正在异步下载的，不处理暂停逻辑
    local hasActiveDownload = false
    for _, resId in ipairs(self._DownloadingResIds or {}) do
        local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
        if resItem and resItem:GetState() == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING then
            hasActiveDownload = true
            break
        end
    end
    if not hasActiveDownload then
        XUiManager.TipText("WaitingForDownloadFashionTip")
        return
    end
    -- 有异步下载中的res，走正常暂停流程 + 遮罩
    XMVCA.XSubPackage:PauseResListDownload(self._DownloadingResIds)
    self._IsPausing = true
    self:UpdateDownloadBtnState()
end

function XUiDownloadFashion:OnBtnCancelDownloadClick()
    -- Sub 模式：暂停整个 Sub
    if self._DownloadMode == DownloadMode.Sub and self._DownloadSubId then
        local flowState = XMVCA.XSubPackage:GetSubpackageFlowState(self._DownloadSubId)
        if flowState == XEnumConst.SUBPACKAGE.FLOW_STATE.QUEUED then
            XMVCA.XSubPackage:ProcessPrepare(self._DownloadSubId)
        elseif flowState ~= XEnumConst.SUBPACKAGE.FLOW_STATE.NONE then
            XMVCA.XSubPackage:PauseDownload(self._DownloadSubId)
        end
    end
    -- Res 模式 或 Sub 模式兜底：暂停所有管理中的 Res
    if not XTool.IsTableEmpty(self._DownloadingResIds) then
        XMVCA.XSubPackage:PauseResListDownload(self._DownloadingResIds)
    end

    -- 清除下载状态，回到选择模式
    self:ClearDownloadSession()
    self._IsDownloading = false
    self._IsPaused = false
    self._IsPausing = false
    self._DownloadingResIds = {}
    self._DownloadMode = nil
    self._DownloadSubId = nil
    self:ClearSelection()
    self:RefreshView()
    self:UpdatePanelState()
end

function XUiDownloadFashion:OnListFashionDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.ListFashion.DataSource[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnGridClick(grid)
    end
end

function XUiDownloadFashion:RefreshListFashionDynamicTable(index)
    self.ListFashion:ReloadDataSync(index or 1)
end

function XUiDownloadFashion:RefreshView()
    -- [F4] Sub 完成时清除接管状态
    if self._DownloadMode == DownloadMode.Sub and self._DownloadSubId then
        local subItem = XMVCA.XSubPackage:GetSubpackageItem(self._DownloadSubId)
        if subItem and subItem:IsComplete() then
            self:ClearDownloadSession()
            self._IsDownloading = false
            self._IsPaused = false
            self._IsPausing = false
            self._DownloadingResIds = {}
            self._DownloadMode = nil
            self._DownloadSubId = nil
        end
    end

    self._DataList = self:GetFashionDownloadList()
    self.ListFashion:SetDataSource(self._DataList)
    self:RefreshListFashionDynamicTable(1)
    self:UpdateFilterBtnState()
    self:UpdateBottomBtnState()
    self:UpdatePanelState()
end

function XUiDownloadFashion:GetFashionDownloadList()
    local result = {}
    local configs = XMVCA.XSubPackage:GetAllFashionDownloadConfigs()

    for k, config in pairs(configs) do
        if type(k) ~= "number" then goto continue end
        local fashionId = config.FashionId
        local resId = config.ResId

        if XDataCenter.FashionManager.IsFashionInTime(fashionId) then
            local isOwn = XDataCenter.FashionManager.CheckHasFashion(fashionId)
            local isDownloaded = XMVCA.XSubPackage:CheckResDownloadComplete(resId)
            local isDownloading = self:_CheckResDownloading(resId)

            -- 双筛选交集：拥有组 AND 下载状态组
            local passOwnership = false
            if self._FilterType == FilterType.All then
                passOwnership = true
            elseif self._FilterType == FilterType.Own and isOwn then
                passOwnership = true
            elseif self._FilterType == FilterType.UnOwn and not isOwn then
                passOwnership = true
            end

            local passDownload = false
            if self._DownloadFilterType == DownloadFilterType.UnDownload then
                passDownload = not isDownloaded  -- 未下载 + 下载中
            elseif self._DownloadFilterType == DownloadFilterType.Download then
                passDownload = isDownloaded
            end

            if passOwnership and passDownload then
                local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
                table.insert(result, {
                    FashionId = fashionId,
                    ResId = resId,
                    IsOwn = isOwn,
                    IsDownloaded = isDownloaded,
                    IsDownloading = isDownloading,
                    CharacterId = template and template.CharacterId or 0,
                    Name = template and template.Name or "",
                    IsSelected = self._SelectedResIds[resId] or false,
                })
            end
        end
        ::continue::
    end

    table.sort(result, function(a, b)
        if a.IsOwn ~= b.IsOwn then
            return a.IsOwn
        end
        return a.FashionId < b.FashionId
    end)

    return result
end

--- 判断 resId 是否处于下载中状态（正在下载 或 在当前下载批次中）
function XUiDownloadFashion:_CheckResDownloading(resId)
    -- 无活跃下载会话时，不判定为下载中（避免异步暂停期间读到C#脏状态）
    if not self._IsDownloading then
        return false
    end
    -- 实体状态为 DOWNLOADING 说明正在传输
    local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
    if resItem and resItem:GetState() == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING then
        return true
    end
    -- 在当前下载批次中（含等待队列里的）
    if self._IsDownloading then
        for _, downloadResId in ipairs(self._DownloadingResIds or {}) do
            if downloadResId == resId then
                return true
            end
        end
    end
    return false
end

function XUiDownloadFashion:UpdateFilterBtnState()
    -- 拥有组
    self.BtnFilterAll:SetButtonState(self._FilterType == FilterType.All and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.BtnFilterOwn:SetButtonState(self._FilterType == FilterType.Own and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.BtnFilterUnOwn:SetButtonState(self._FilterType == FilterType.UnOwn and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    -- 下载状态组
    self.BtnFilterUnDownload:SetButtonState(self._DownloadFilterType == DownloadFilterType.UnDownload and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self.BtnFilterDownload:SetButtonState(self._DownloadFilterType == DownloadFilterType.Download and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    -- 下载/卸载按钮跟随下载状态筛选
    self:UpdateActionBtnVisibility()
end

function XUiDownloadFashion:UpdateBottomBtnState()
    -- 分别收集未下载和已下载的resId，再用跨resId去重方式计算大小
    local downloadResIds = {}
    local uninstallResIds = {}
    for resId, _ in pairs(self._SelectedResIds) do
        if XMVCA.XSubPackage:CheckResDownloadComplete(resId) then
            uninstallResIds[resId] = true
        else
            downloadResIds[resId] = true
        end
    end

    local downloadSize = XMVCA.XSubPackage:GetResListTotalSize(downloadResIds)
    local uninstallSize = XMVCA.XSubPackage:GetResListTotalSize(uninstallResIds)

    local downloadMB = string.format("%.1fMB", downloadSize / 1024 / 1024)
    local uninstallMB = string.format("%.1fMB", uninstallSize / 1024 / 1024)

    self.BtnDownload:SetNameByGroup(1, downloadMB)
    self.BtnUninstall:SetNameByGroup(1, uninstallMB)

    -- 无有效选择时禁用按钮
    self.BtnDownload:SetDisable(next(downloadResIds) == nil)
    self.BtnUninstall:SetDisable(next(uninstallResIds) == nil)
end

-- 下载/卸载按钮跟随下载状态筛选显隐（BtnDownload 跟随 PanelSelecting 父节点）
function XUiDownloadFashion:UpdateActionBtnVisibility()
    local isDownloadFilter = self._DownloadFilterType == DownloadFilterType.Download
    self.BtnUninstall.gameObject:SetActiveEx(isDownloadFilter)
    if isDownloadFilter then
        local isDownloading = self._IsDownloading
        self.BtnUninstall:GetComponent("UiObject"):GetObject("Txt").gameObject:SetActiveEx(not isDownloading)
        if isDownloading then
            self.BtnUninstall:SetDisable(true)
        end
    end
end

function XUiDownloadFashion:OnResUpdate(resId, progress)
    -- 更新格子进度
    local grids = self.ListFashion:GetGrids()
    for _, grid in pairs(grids) do
        if grid.Data and grid.Data.ResId == resId then
            grid:RefreshProgress(progress)
            break
        end
    end

    -- 更新下载进度条
    if self._IsDownloading then
        self:UpdateDownloadProgress()
        self:CheckDownloadComplete()
    end
end

function XUiDownloadFashion:OnResComplete(resId)
    -- 只刷新已有 grid 数据，不重建列表，避免滚动位置置顶
    self:RefreshGridDataOnly()
    self:UpdateBottomBtnState()
    self:CheckDownloadComplete()
end

--- 刷新动态列表数据，不重置滚动位置
function XUiDownloadFashion:RefreshGridDataOnly()
    self._DataList = self:GetFashionDownloadList()
    self.ListFashion:SetDataSource(self._DataList)
    self.ListFashion:ReloadDataSync(-1)
end

--- [F4] Sub 开始准备/开始下载时检查是否需要接管
function XUiDownloadFashion:OnSubpackagePrepareOrStart(subpackageId)
    -- 已在 Sub 模式且是同一个 sub，不重复处理
    if self._DownloadMode == DownloadMode.Sub and self._DownloadSubId == subpackageId then
        -- 但如果从暂停恢复（Prepare→Active），更新暂停态
        local flowState = XMVCA.XSubPackage:GetSubpackageFlowState(subpackageId)
        if flowState == XEnumConst.SUBPACKAGE.FLOW_STATE.ACTIVE or flowState == XEnumConst.SUBPACKAGE.FLOW_STATE.QUEUED then
            self._IsPaused = false
            self._IsPausing = false
            self:UpdateDownloadBtnState()
            self:UpdateDownloadProgress()
        end
        return
    end

    -- Res 模式下检测是否需要接管
    if not self._IsDownloading then
        return
    end

    -- 检查该 sub 的 ResIds 是否与当前 Fashion 会话有交集
    local subTemplate = XMVCA.XSubPackage:GetSubpackageTemplate(subpackageId)
    if not subTemplate or not subTemplate.ResIds then return end
    local subResSet = {}
    for _, resId in ipairs(subTemplate.ResIds) do
        subResSet[resId] = true
    end
    local hasOverlap = false
    for _, resId in ipairs(self._DownloadingResIds or {}) do
        if subResSet[resId] then
            hasOverlap = true
            break
        end
    end

    if hasOverlap then
        -- 只有 Sub 真正被 AddToDownload 入队（ACTIVE/QUEUED）时才接管
        -- Res 级 PrepareDownload 触发的 EVENT_SUBPACKAGE_PREPARE 不应导致模式切换
        local flowState = XMVCA.XSubPackage:GetSubpackageFlowState(subpackageId)
        if flowState == XEnumConst.SUBPACKAGE.FLOW_STATE.ACTIVE
            or flowState == XEnumConst.SUBPACKAGE.FLOW_STATE.QUEUED then
            self:TryEnterSubMode(subpackageId)
        end
    end
end

--- [F4] Sub 暂停时更新 Fashion 状态
function XUiDownloadFashion:OnSubpackagePause(subpackageId)
    if self._DownloadMode == DownloadMode.Sub and self._DownloadSubId == subpackageId then
        self._IsPaused = true
        self:SaveDownloadSession(DownloadMode.Sub, subpackageId, self._DownloadingResIds)
        self:UpdateDownloadBtnState()
    end
end

--- Res级暂停完成回调：C#异步暂停完成后，从过渡态切换到真正的暂停态
function XUiDownloadFashion:OnResPauseComplete(resId)
    if not self._IsPausing then
        return
    end
    -- 检查回调的resId是否属于当前会话
    if not XTool.IsTableEmpty(self._DownloadingResIds) then
        local isRelevant = false
        for _, downloadResId in ipairs(self._DownloadingResIds) do
            if downloadResId == resId then
                isRelevant = true
                break
            end
        end
        if not isRelevant then
            return
        end
    end
    self._IsPausing = false
    self._IsPaused = true
    self:UpdateDownloadBtnState()
end

--- [F6] Sub 模式暂停
function XUiDownloadFashion:PauseSubMode()
    local subId = self._DownloadSubId
    local flowState = XMVCA.XSubPackage:GetSubpackageFlowState(subId)

    if flowState == XEnumConst.SUBPACKAGE.FLOW_STATE.QUEUED then
        XMVCA.XSubPackage:ProcessPrepare(subId)
        XMVCA.XSubPackage:PauseResListDownload(self._DownloadingResIds)
    elseif flowState == XEnumConst.SUBPACKAGE.FLOW_STATE.ACTIVE or flowState == XEnumConst.SUBPACKAGE.FLOW_STATE.PAUSING then
        XMVCA.XSubPackage:PauseDownload(subId)
    end

    self._IsPaused = true
    self:SaveDownloadSession(DownloadMode.Sub, subId, self._DownloadingResIds)
    self:UpdateDownloadBtnState()
end

--- [F6] Sub 模式继续
function XUiDownloadFashion:ContinueSubMode()
    local subId = self._DownloadSubId
    -- [F5] 显式 Sub 级继续，传 true 恢复 PAUSE Res
    XMVCA.XSubPackage:AddToDownload(subId, true)
    self._IsPaused = false
    self._IsPausing = false
    self:SaveDownloadSession(DownloadMode.Sub, subId, self._DownloadingResIds)
    self:UpdateDownloadBtnState()
    self:UpdateDownloadProgress()
end

-- 格子点击事件
function XUiDownloadFashion:OnGridClick(grid)
    if self._IsDownloading then return end
    if not grid or not grid.Data then return end
    local resId = grid.Data.ResId
    local isSelected = not grid.Data.IsSelected
    grid:UpdateSelectState(isSelected)
    self:OnGridSelectChanged(resId, isSelected)
end

function XUiDownloadFashion:OnGridSelectChanged(resId, isSelected)
    self._SelectedResIds[resId] = isSelected or nil
    self:UpdateBottomBtnState()
end

-- 清除选中状态
function XUiDownloadFashion:ClearSelection()
    self._SelectedResIds = {}
    if self.ToggleSelectAll then
        self.ToggleSelectAll:SetButtonState(CS.UiButtonState.Normal)
    end
end

-- 更新面板显示状态
function XUiDownloadFashion:UpdatePanelState()
    local isDownloading = self._IsDownloading
    local isDownloadFilter = self._DownloadFilterType == DownloadFilterType.Download

    -- BtnDownload 跟随 PanelSelecting，BtnCancelDownload 跟随 PanelDownloading
    self.PanelSelecting.gameObject:SetActiveEx(not isDownloading and not isDownloadFilter)
    self.PanelDownloading.gameObject:SetActiveEx(isDownloading and not isDownloadFilter)
    self.ToggleSelectAll:SetDisable(isDownloading)

    if isDownloading and not isDownloadFilter then
        self:UpdateDownloadProgress()
        self:UpdateDownloadBtnState()
    end

    self:UpdateActionBtnVisibility()
end

-- 更新暂停/继续按钮可见性
-- 暂停按钮在"下载中"和"正在暂停"时都显示（玩家可以疯狂点但只有第一次有效）
-- 继续按钮只在真正暂停成功后才显示
function XUiDownloadFashion:UpdateDownloadBtnState()
    self.BtnPause.gameObject:SetActiveEx(not self._IsPaused)
    self.BtnContinue.gameObject:SetActiveEx(self._IsPaused)
    self.PausingMask.gameObject:SetActiveEx(self._IsPausing or false)
end

-- 更新下载进度显示
function XUiDownloadFashion:UpdateDownloadProgress()
    local totalSize = 0
    local downloadedSize = 0
    local hasActiveDownload = false

    for _, resId in ipairs(self._DownloadingResIds or {}) do
        local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
        if resItem then
            totalSize = totalSize + resItem:GetTotalSize()
            downloadedSize = downloadedSize + resItem:GetDownloadSize()
            -- 用队列判断：在等待队列里的是真正的等待中，不算活跃下载
            if resItem:GetState() == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING
                    or (XMVCA.XSubPackage:IsResInDownloadQueue(resId)
                        and not XMVCA.XSubPackage:IsResWaitingInQueue(resId)) then
                hasActiveDownload = true
            end
        end
    end

    -- 区分下载中/等待中状态（暂停视为下载中）
    local isWaiting = not hasActiveDownload and not self._IsPaused
    self.TxtDownloading.gameObject:SetActiveEx(not isWaiting)
    self.TxtWaiting.gameObject:SetActiveEx(isWaiting)

    -- 进度条（进度仍用非去重的累加值，保证比例正确）
    local progress = totalSize > 0 and (downloadedSize / totalSize) or 0
    if self.ImgFillBar then
        self.ImgFillBar.fillAmount = progress
    end

    -- 进度文本：总大小用去重值，同时赋值到两个子节点
    local resIdTable = {}
    for _, resId in ipairs(self._DownloadingResIds or {}) do
        resIdTable[resId] = true
    end
    local dedupTotal = XMVCA.XSubPackage:GetResListTotalSize(resIdTable)
    local dedupDownloaded = totalSize > 0 and (downloadedSize / totalSize * dedupTotal) or 0
    local progressText = string.format("%.1fMB/%.1fMB", dedupDownloaded / 1024 / 1024, dedupTotal / 1024 / 1024)
    if self._TxtProgressDownloading then
        self._TxtProgressDownloading.text = progressText
    end
    if self._TxtProgressWaiting then
        self._TxtProgressWaiting.text = progressText
    end
end

--- [F7 重写] 检查下载状态（进入界面时调用）
function XUiDownloadFashion:CheckDownloadingState()
    local session = self:LoadDownloadSession()
    -- ========== 有 session 时，先尝试恢复 ==========
    if session and not XTool.IsTableEmpty(session.ResIds) then
        local restored = self:_TryRestoreFromSession(session)
        if restored then
            return
        end
        -- session 已过期/完成，清掉后 fall through 到无 session 检测
        self:ClearDownloadSession()
    end

    -- ========== 无 session（或旧 session 已清除），检测 Main 是否发起了涂装 Sub 下载 ==========
    if self:TryRestoreSubModeFromMainWithoutSession() then
        return
    end
    self._IsDownloading = false
    self._IsPaused = false
    self._IsPausing = false
    self._DownloadingResIds = {}
    self._DownloadMode = nil
    self._DownloadSubId = nil
end

--- 尝试从已有 session 恢复下载状态，成功返回 true，session 过期/无效返回 false
function XUiDownloadFashion:_TryRestoreFromSession(session)
    -- ========== Sub 模式恢复优先 ==========
    if session.Mode == DownloadMode.Sub and session.SubId and session.SubId > 0 then
        local subId = session.SubId
        local flowState = XMVCA.XSubPackage:GetSubpackageFlowState(subId)
        local isActivated = XMVCA.XSubPackage:IsSubpackageActivated(subId)

        -- 全量集合重算（不依赖缓存中的 ResIds）
        local fullResIds = self:GetFashionSubResIds(subId)
        local allComplete = true
        for _, resId in ipairs(fullResIds) do
            if not XMVCA.XSubPackage:CheckResDownloadComplete(resId) then
                allComplete = false
                break
            end
        end

        if allComplete then
            return false
        end

        -- 判断是否应恢复Sub下载模式：
        -- 1. flowState ~= NONE: Sub 正在运行时管线中（ACTIVE/QUEUED/PAUSING）
        -- 2. Sub 实体状态为 PAUSE/DOWNLOADING/PREPARE_DOWNLOAD 且未 finished: Sub 曾下载过但当前未在管线中（如暂停后）
        -- 不再仅凭 isActivated 持久化标记恢复，避免历史残留标记导致每次重启错误恢复
        local isFinished = XMVCA.XSubPackage:IsSubpackageFinished(subId)
        local subItem = XMVCA.XSubPackage:GetSubpackageItem(subId)
        local subState = subItem and subItem:GetState()
        local isSubInProgress = subState == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE
            or subState == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.DOWNLOADING
            or subState == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PREPARE_DOWNLOAD

        local shouldRestore = flowState ~= XEnumConst.SUBPACKAGE.FLOW_STATE.NONE
            or (isSubInProgress and not isFinished and not allComplete)

        if shouldRestore then
            self._DownloadMode = DownloadMode.Sub
            self._DownloadSubId = subId
            self._IsDownloading = true
            self._DownloadingResIds = fullResIds

            if flowState == XEnumConst.SUBPACKAGE.FLOW_STATE.ACTIVE then
                self._IsPaused = false
                self._IsPausing = false
            else
                self._IsPaused = true
                self._IsPausing = false
            end
            return true
        end

        return false
    end

    -- ========== Res 模式恢复 ==========
    local cachedResIds = session.ResIds

    -- [F7] 排除法过滤：保留 NOT_DOWNLOAD（重启后未落盘的选择）
    local needDownloadResIds = {}
    for _, resId in ipairs(cachedResIds) do
        local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
        if resItem then
            local state = resItem:GetState()
            if state ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE
                and state ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.UNINSTALLED then
                table.insert(needDownloadResIds, resId)
            end
        end
    end

    if XTool.IsTableEmpty(needDownloadResIds) then
        return false
    end

    local hasActiveDownload = false
    local hasPausedDownload = false
    local hasNotDownloaded = false
    for _, resId in ipairs(needDownloadResIds) do
        if XMVCA.XSubPackage:IsResInDownloadQueue(resId) then
            hasActiveDownload = true
        end
        local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
        if resItem then
            local state = resItem:GetState()
            if state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.PAUSE then
                hasPausedDownload = true
            elseif state == XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.NOT_DOWNLOAD then
                hasNotDownloaded = true
            end
        end
    end

    -- [F7] NOT_DOWNLOAD 不是脏缓存
    if not hasActiveDownload and not hasPausedDownload and not hasNotDownloaded then
        return false
    end

    -- 进入下载中模式（保留完整 session 列表，确保进度条反映用户原始意图）
    self._DownloadMode = DownloadMode.Res
    self._DownloadSubId = nil
    self._IsDownloading = true
    self._DownloadingResIds = cachedResIds

    if hasActiveDownload then
        self._IsPaused = false
        self._IsPausing = false
    else
        -- 恢复 session 时检查是否有 Res 正在异步暂停中
        local anyResPausing = false
        for _, resId in ipairs(cachedResIds) do
            if XMVCA.XSubPackage:IsResPausing(resId) then
                anyResPausing = true
                break
            end
        end
        self._IsPausing = anyResPausing
        self._IsPaused = not anyResPausing
    end

    -- [F4 前置] 检查是否应切换到 Sub 模式
    local takeoverSubId = self:GetTakeoverSubId()
    if takeoverSubId then
        self:TryEnterSubMode(takeoverSubId)
    end
    return true
end

--- [F7] 保存下载会话
---@param mode string "Res"|"Sub"
---@param subId number|nil Sub模式时的subId
---@param resIds table resId列表
function XUiDownloadFashion:SaveDownloadSession(mode, subId, resIds)
    local session = {
        Version = 2,
        Mode = mode or DownloadMode.Res,
        SubId = subId or 0,
        ResIds = resIds or {},
    }
    XSaveTool.SaveData(GetSessionKey(), session)
end

--- [F7] 加载下载会话
---@return table|nil {Version, Mode, SubId, ResIds}
function XUiDownloadFashion:LoadDownloadSession()
    local session = XSaveTool.GetData(GetSessionKey())
    if session and session.Version then
        return session
    end
    return nil
end

--- [F7] 清除下载会话缓存
function XUiDownloadFashion:ClearDownloadSession()
    XSaveTool.RemoveData(GetSessionKey())
end

-- 检查下载是否全部完成
function XUiDownloadFashion:CheckDownloadComplete()
    if XTool.IsTableEmpty(self._DownloadingResIds) then
        return
    end

    for _, resId in ipairs(self._DownloadingResIds) do
        if not XMVCA.XSubPackage:CheckResDownloadComplete(resId) then
            return
        end
    end

    -- 全部完成，清除缓存，返回选择模式
    self:ClearSelection()
    self:ClearDownloadSession()
    self._IsDownloading = false
    self._IsPaused = false
    self._IsPausing = false
    self._DownloadingResIds = {}
    self._DownloadMode = nil
    self._DownloadSubId = nil
    self:RefreshView()
    self:UpdatePanelState()
end

--- [F4] 获取全量 Fashion ResIds（属于该 sub 且在 FashionDownloadConfig 中）
function XUiDownloadFashion:GetFashionSubResIds(subpackageId)
    local subTemplate = XMVCA.XSubPackage:GetSubpackageTemplate(subpackageId)
    local subResSet = {}
    for _, resId in ipairs(subTemplate and subTemplate.ResIds or {}) do
        subResSet[resId] = true
    end
    local result = {}
    local configs = XMVCA.XSubPackage:GetAllFashionDownloadConfigs()
    for k, config in pairs(configs or {}) do
        if type(k) == "number" and subResSet[config.ResId] then
            table.insert(result, config.ResId)
        end
    end
    table.sort(result)
    return result
end

--- [F9] 获取 Fashion 所属的 SubId（所有涂装 Res 隶属同一个 Sub）
---@return number|nil subId
function XUiDownloadFashion:GetFashionSubId()
    local configs = XMVCA.XSubPackage:GetAllFashionDownloadConfigs()
    if XTool.IsTableEmpty(configs) then
        return nil
    end
    -- BinaryTable 原始表含 __tableNextFix 等 string key 内部标记，只取 number key（FashionId）
    local firstResId
    for k, config in pairs(configs) do
        if type(k) == "number" and config.ResId then
            firstResId = config.ResId
            break
        end
    end
    if not firstResId then return nil end
    local subIds = XMVCA.XSubPackage:GetSubpackageIdByResId(firstResId)
    if XTool.IsTableEmpty(subIds) then return nil end
    if #subIds > 1 then
        XLog.Error("[UiDownloadFashion] Fashion ResId 映射到多个 Sub，配置异常: resId=" .. firstResId)
    end
    return subIds[1]
end

--- [F9] 无本地 session 时，检测 Main 是否已发起涂装 Sub 下载，主动接管
function XUiDownloadFashion:TryRestoreSubModeFromMainWithoutSession()
    local subId = self:GetFashionSubId()
    if not subId then return false end

    local fullResIds = self:GetFashionSubResIds(subId)
    if XTool.IsTableEmpty(fullResIds) then return false end

    local allComplete = true
    for _, resId in ipairs(fullResIds) do
        if not XMVCA.XSubPackage:CheckResDownloadComplete(resId) then
            allComplete = false
            break
        end
    end
    if allComplete then return false end

    local FLOW = XEnumConst.SUBPACKAGE.FLOW_STATE
    local flowState = XMVCA.XSubPackage:GetSubpackageFlowState(subId)

    -- 仅当 Sub 当前在下载管线中（ACTIVE/QUEUED/PAUSING）才接管，不依赖持久化标记
    if flowState ~= FLOW.NONE then
        self._DownloadMode = DownloadMode.Sub
        self._DownloadSubId = subId
        self._IsDownloading = true
        self._DownloadingResIds = fullResIds

        if flowState == FLOW.ACTIVE or flowState == FLOW.QUEUED then
            self._IsPaused = false
            self._IsPausing = false
        else
            self._IsPaused = true
            self._IsPausing = false
        end

        self:SaveDownloadSession(DownloadMode.Sub, subId, fullResIds)
        return true
    end

    return false
end

--- [F4] 检查是否有 Sub 正在接管当前 Fashion 会话
--- 所有涂装 Res 隶属同一个 Sub，取第一个 resId 反查即可
---@return number|nil takeoverSubId
function XUiDownloadFashion:GetTakeoverSubId()
    if not self._IsDownloading or XTool.IsTableEmpty(self._DownloadingResIds) then
        return nil
    end
    local subIds = XMVCA.XSubPackage:GetSubpackageIdByResId(self._DownloadingResIds[1])
    if XTool.IsTableEmpty(subIds) then return nil end
    if #subIds > 1 then
        XLog.Error("[UiDownloadFashion] Fashion ResId 映射到多个 Sub，配置异常: resId=" .. self._DownloadingResIds[1])
    end
    local subId = subIds[1]

    -- 仅看运行时状态：Sub 在下载管线中才接管
    -- 持久化 Active 标记不触发接管，避免历史标记覆盖用户的 Res 部分选择意图
    -- （重启恢复由 _TryRestoreFromSession 的 Sub 模式分支处理，不依赖此处）
    local FLOW = XEnumConst.SUBPACKAGE.FLOW_STATE
    if XMVCA.XSubPackage:GetSubpackageFlowState(subId) ~= FLOW.NONE then
        return subId
    end
    return nil
end

--- [F4] 尝试切换到 Sub 接管模式
function XUiDownloadFashion:TryEnterSubMode(subpackageId)
    self._DownloadMode = DownloadMode.Sub
    self._DownloadSubId = subpackageId
    self._IsDownloading = true
    self._IsPaused = false
    self._IsPausing = false
    self._DownloadingResIds = self:GetFashionSubResIds(subpackageId)
    self:SaveDownloadSession(DownloadMode.Sub, subpackageId, self._DownloadingResIds)

    -- [F5] Sub 已在 Active 时，自动恢复 PAUSE 资源
    local flowState = XMVCA.XSubPackage:GetSubpackageFlowState(subpackageId)
    if flowState == XEnumConst.SUBPACKAGE.FLOW_STATE.ACTIVE then
        for _, resId in ipairs(self._DownloadingResIds) do
            local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
            if resItem and resItem:IsPause() then
                XMVCA.XSubPackage:AddResToDownload(resId)
            end
        end
    end

    self:UpdatePanelState()
end

function XUiDownloadFashion:OnDestroy()
    XEventManager.DispatchEvent(XEventId.EVENT_FUNCTION_EVENT_COMPLETE)
end