

---@class XUiDownloadPreview : XLuaUi
---@field _Control XSubPackageControl
local XUiDownloadPreview = XLuaUiManager.Register(XLuaUi, "UiDownloadPreview")

function XUiDownloadPreview:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiDownloadPreview:OnStart(checkResult)
    self.CheckResult = checkResult
    self:InitView()
end

function XUiDownloadPreview:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_SUBPACKAGE_UPDATE, self.OnSubpackageUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_RES_UPDATE, self.OnResUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_SUBPACKAGE_COMPLETE, self.OnDownloadComplete, self)
    XEventManager.AddEventListener(XEventId.EVENT_RES_COMPLETE, self.OnDownloadComplete, self)
end

function XUiDownloadPreview:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_SUBPACKAGE_UPDATE, self.OnSubpackageUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_UPDATE, self.OnResUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_SUBPACKAGE_COMPLETE, self.OnDownloadComplete, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_COMPLETE, self.OnDownloadComplete, self)
end

function XUiDownloadPreview:OnDestroy()
    self:SaveIgnoreVersionState()
end

function XUiDownloadPreview:InitUi()
    self.GridTask.gameObject:SetActiveEx(false)
    local XUiGridDownloadPreview = require("XUi/XUiSubPackage/XUiGrid/XUiGridDownloadPreview")
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelAchvList, XUiGridDownloadPreview)
end

function XUiDownloadPreview:InitCb()
    local closeCb = handler(self, self.Close)

    self.BtnCloseBg.CallBack = closeCb
    self.BtnTanchuangClose.CallBack = closeCb

    self.BtnDownloadB.CallBack = function()
        self:OnBtnDownloadBClick()
    end
end

function XUiDownloadPreview:InitView()
    local dataList = self:BuildControlDataList()
    self.DataList = dataList
    self.DynamicTable:SetDataSource(dataList)
    self.DynamicTable:ReloadDataSync()
end

function XUiDownloadPreview:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DataList[index]
        grid:Refresh(data)
    end
    -- 点击逻辑统一由 Grid 的 OnToggleSelectClick 处理，避免与 DYNAMIC_GRID_TOUCHED 重复触发导致双重toggle
end

function XUiDownloadPreview:BuildControlDataList()
    local result = {}
    local checkResult = self.CheckResult
    if not checkResult then
        return result
    end

    local configs = XMVCA.XSubPackage:GetAllDownloadPreviewControlConfigs()
    if XTool.IsTableEmpty(configs) then
        return result
    end

    -- Sub模式配置行（按Order升序，第1个=强Sub，第2个=弱Sub）
    local subConfigs = XMVCA.XSubPackage:GetSortedSubModeConfigs()

    -- Res模式配置行（按ResType索引）
    local resTypeConfigs = {}
    for id, config in pairs(configs) do
        if XTool.IsNumberValid(config.ResType) and config.ResType ~= 0 then
            resTypeConfigs[config.ResType] = {Id = id, Config = config}
        end
    end

    -- 选项1：强Sub选项（Sub模式中Order最小的行）
    if #subConfigs >= 1 then
        local item = subConfigs[1]
        local resIds = self:CollectResIdsBySubPackageIds(checkResult.subIds)
        if not XTool.IsTableEmpty(resIds) then
            table.insert(result, {
                ControlId = item.Id,
                OptionName = item.Config.OptionName,
                Desc = item.Config.Desc,
                IgnoreInterput = item.Config.IgnoreInterput,
                ResIds = resIds,
                SubPackageIds = checkResult.subIds,
                IsSelected = true,
                IsWeak = false,
                EnterType = checkResult.enterType,
                Param = checkResult.param,
            })
        end
    end

    -- 选项2：弱Sub选项（Sub模式中Order第二小的行）
    if #subConfigs >= 2 then
        local item = subConfigs[2]
        local resIds = self:CollectResIdsBySubPackageIds(checkResult.weakSubIds)
        if not XTool.IsTableEmpty(resIds) then
            table.insert(result, {
                ControlId = item.Id,
                OptionName = item.Config.OptionName,
                Desc = item.Config.Desc,
                IgnoreInterput = item.Config.IgnoreInterput,
                ResIds = resIds,
                SubPackageIds = checkResult.weakSubIds,
                IsSelected = true,
                IsWeak = true,
                EnterType = checkResult.enterType,
                Param = checkResult.param,
            })
        end
    end

    -- 选项3+：散装Res选项（通过ResType匹配）
    for _, extraOpt in ipairs(checkResult.extraResOptions or {}) do
        local configItem = resTypeConfigs[extraOpt.resType]
        if configItem and not XTool.IsTableEmpty(extraOpt.resIds) then
            table.insert(result, {
                ControlId = configItem.Id,
                OptionName = configItem.Config.OptionName,
                Desc = configItem.Config.Desc,
                IgnoreInterput = configItem.Config.IgnoreInterput,
                ResIds = extraOpt.resIds,
                IsSelected = true,
                IsWeak = extraOpt.isWeak,
                EnterType = checkResult.enterType,
                Param = checkResult.param,
            })
        end
    end

    -- 判断是否全为弱选项（无强选项）
    local onlyWeak = true
    for _, data in ipairs(result) do
        if not data.IsWeak then
            onlyWeak = false
            break
        end
    end
    for _, data in ipairs(result) do
        data.OnlyWeakOptions = onlyWeak
    end

    return result
end

function XUiDownloadPreview:CollectResIdsBySubPackageIds(subPackageIds)
    local resIds = {}
    if XTool.IsTableEmpty(subPackageIds) then
        return resIds
    end
    for _, subId in ipairs(subPackageIds) do
        local template = XMVCA.XSubPackage:GetSubpackageTemplate(subId)
        if template and template.ResIds then
            for _, resId in ipairs(template.ResIds) do
                if not XMVCA.XSubPackage:CheckResDownloadComplete(resId) then
                    table.insert(resIds, resId)
                end
            end
        end
    end
    return resIds
end

function XUiDownloadPreview:OnBtnDownloadBClick()
    -- 分离Sub选项和Res选项
    local subDataList = {}
    local resIdsToDownload = {}

    for _, data in ipairs(self.DataList) do
        if data.IsSelected then
            if not XTool.IsTableEmpty(data.SubPackageIds) then
                table.insert(subDataList, data)
            elseif not XTool.IsTableEmpty(data.ResIds) then
                for _, resId in ipairs(data.ResIds) do
                    table.insert(resIdsToDownload, resId)
                end
            end
        end
    end

    local hasContent = not XTool.IsTableEmpty(subDataList) or not XTool.IsTableEmpty(resIdsToDownload)

    local downloadCb = function()
        -- Sub选项走Sub级下载流程（状态追踪、事件通知、UiDownloadMain同步）
        for _, data in ipairs(subDataList) do
            for _, subId in ipairs(data.SubPackageIds) do
                XMVCA.XSubPackage:AddToDownload(subId, true)
            end
        end
        -- 散装Res选项走Res级下载
        for _, resId in ipairs(resIdsToDownload) do
            XMVCA.XSubPackage:AddResToDownload(resId)
        end
        self:Close()
    end

    local jumpCb = function()
        self:Close()
        XMVCA.XSubPackage:OpenUiMain()
    end

    if hasContent then
        XUiManager.DialogDownload("", XUiHelper.GetText("DlcDownloadInBackgroundTip"), nil, downloadCb, jumpCb)
    else
        self:Close()
    end
end

-- Sub级进度更新：匹配含该subpackageId的选项刷新进度
function XUiDownloadPreview:OnSubpackageUpdate(subpackageId)
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        local data = grid.Data
        if data and not XTool.IsTableEmpty(data.SubPackageIds) then
            for _, subId in ipairs(data.SubPackageIds) do
                if subId == subpackageId then
                    grid:RefreshAggregatedProgress(data)
                    break
                end
            end
        end
    end
end

-- Res级进度更新：匹配含该resId的选项刷新进度
function XUiDownloadPreview:OnResUpdate(resId)
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        local data = grid.Data
        if data and not XTool.IsTableEmpty(data.ResIds) then
            for _, id in ipairs(data.ResIds) do
                if id == resId then
                    grid:RefreshAggregatedProgress(data)
                    break
                end
            end
        end
    end
end

-- 下载完成：全量刷新进度
function XUiDownloadPreview:OnDownloadComplete()
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        if grid.Data then
            grid:RefreshAggregatedProgress(grid.Data)
        end
    end
end

function XUiDownloadPreview:SaveIgnoreVersionState()
    local playerId = XPlayer.Id
    local grids = self.DynamicTable:GetGrids()
    for _, grid in pairs(grids) do
        if grid.GetIgnoreVersionState and grid.GetData then
            local data = grid:GetData()
            if data and data.IgnoreInterput and data.IsWeak then
                local cacheKey = "SubPackageIgnoreVersion_" .. playerId
                    .. "_" .. (data.EnterType or "")
                    .. "_" .. (data.Param or "")
                    .. "_" .. data.ControlId
                local isChecked = grid:GetIgnoreVersionState()
                XSaveTool.SaveData(cacheKey, isChecked)
            end
        end
    end
end
