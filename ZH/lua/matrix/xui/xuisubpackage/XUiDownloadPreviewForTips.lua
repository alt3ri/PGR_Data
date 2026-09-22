---@class XUiDownloadPreviewForTips : XLuaUi
local XUiDownloadPreviewForTips = XLuaUiManager.Register(XLuaUi, "UiDownloadPreviewForTips")

function XUiDownloadPreviewForTips:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiDownloadPreviewForTips:OnStart(characterId, fashionId)
    self._CharacterId = characterId
    self._FashionId = fashionId
    self._SelectedIndex = 1
    self:RefreshView()
end

function XUiDownloadPreviewForTips:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_RES_UPDATE, self.OnResUpdate, self)
    XEventManager.AddEventListener(XEventId.EVENT_RES_COMPLETE, self.OnResComplete, self)
end

function XUiDownloadPreviewForTips:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_UPDATE, self.OnResUpdate, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_RES_COMPLETE, self.OnResComplete, self)
end

function XUiDownloadPreviewForTips:InitButton()
    self.BtnDownloadB:AddEventListener(handler(self, self.OnBtnDownloadBClick))
    self.BtnTanchuangClose:AddEventListener(handler(self, self.OnBtnTanchuangCloseClick))
    self.BtnCloseBg:AddEventListener(handler(self, self.OnBtnCloseBgClick))
end

function XUiDownloadPreviewForTips:InitDynamicTable()
    local XUiGridPreviewTips = require("XUi/XUiSubPackage/XUiGrid/XUiGridPreviewTips")
    self.PanelAchvList = XUiHelper.DynamicTableNormal(self, self.PanelAchvList.gameObject, XUiGridPreviewTips)
    self.PanelAchvList:SetDynamicEventDelegate(function(event, index, grid) self:OnAchvListDynamicTableEvent(event, index, grid) end)
end

function XUiDownloadPreviewForTips:RefreshView()
    local dataList = self:BuildDataList()
    self._DataList = dataList
    self.PanelAchvList:SetDataSource(dataList)
    self:RefreshAchvListDynamicTable(1)
end

function XUiDownloadPreviewForTips:BuildDataList()
    local result = {}

    local fashionTemplate = XDataCenter.FashionManager.GetFashionTemplate(self._FashionId)
    local fashionName = fashionTemplate and fashionTemplate.Name or ""
    local characterName = XMVCA.XCharacter:GetCharacterFullNameStr(self._CharacterId)
    local resId = XMVCA.XSubPackage:GetFashionResId(self._FashionId)

    -- 格子1：当前涂装
    -- 描述key FashionDownloadIndividualDesc，策划配置格式：{0}涂装{1}
    table.insert(result, {
        Index = 1,
        OptionName = fashionName,
        Desc = XUiHelper.GetText("FashionDownloadIndividualDesc", characterName, fashionName),
        ResIds = XTool.IsNumberValid(resId) and {resId} or {},
        IsSelected = true,
    })

    -- 格子2：该角色所有未下载涂装
    -- 描述key FashionDownloadAllCharacterDesc，策划配置格式：{0}所有未下载的涂装资源
    local allResIds = self:GetCharacterDownloadableResIds()
    table.insert(result, {
        Index = 2,
        OptionName = XUiHelper.GetText("DownloadAllCharacterFashion"),
        Desc = XUiHelper.GetText("FashionDownloadAllCharacterDesc", characterName),
        ResIds = allResIds,
        IsSelected = false,
    })

    return result
end

function XUiDownloadPreviewForTips:GetCharacterDownloadableResIds()
    local resIds = {}
    -- 从分包配置表出发，只遍历有分包配置的涂装，避免对默认/基础涂装查表报错
    -- 包含已下载和未下载的，使总进度不变
    local allFashionConfigs = XMVCA.XSubPackage:GetAllFashionDownloadConfigs()
    if XTool.IsTableEmpty(allFashionConfigs) then
        return resIds
    end
    for _, config in pairs(allFashionConfigs) do
        local fashionId = config.FashionId
        local template = XDataCenter.FashionManager.GetFashionTemplate(fashionId)
        if template and template.CharacterId == self._CharacterId then
            local resId = config.ResId
            if XTool.IsNumberValid(resId) then
                table.insert(resIds, resId)
            end
        end
    end
    return resIds
end

function XUiDownloadPreviewForTips:OnBtnDownloadBClick()
    local selectedData = self._DataList[self._SelectedIndex]
    if selectedData and not XTool.IsTableEmpty(selectedData.ResIds) then
        -- 检查选中项的resId是否全部已下载完成
        local allComplete = true
        for _, resId in ipairs(selectedData.ResIds) do
            local resItem = XMVCA.XSubPackage:GetResourceItem(resId)
            if resItem and resItem:GetState() ~= XEnumConst.SUBPACKAGE.DOWNLOAD_STATE.COMPLETE then
                allComplete = false
                break
            end
        end
        if allComplete then
            XUiManager.PopupLeftTip(XUiHelper.GetText("DownloadFashionFinished"))
            self:Close()
            return
        end
        for _, resId in ipairs(selectedData.ResIds) do
            XMVCA.XSubPackage:AddResToDownload(resId)
        end
        XUiManager.TipText("DownloadFashionStarted")
    end
    self:Close()
end

function XUiDownloadPreviewForTips:OnBtnTanchuangCloseClick()
    self:Close()
end

function XUiDownloadPreviewForTips:OnBtnCloseBgClick()
    self:Close()
end

function XUiDownloadPreviewForTips:OnGridSelectChanged(index)
    self._SelectedIndex = index
    for i, data in ipairs(self._DataList) do
        data.IsSelected = (i == index)
    end
    self:RefreshAchvListDynamicTable()
end

function XUiDownloadPreviewForTips:OnAchvListDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Refresh(self.PanelAchvList.DataSource[index])
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
    end
end

function XUiDownloadPreviewForTips:RefreshAchvListDynamicTable(index)
    self.PanelAchvList:ReloadDataSync(index or 1)
end

-- 下载进度更新，刷新包含该resId的格子进度条
function XUiDownloadPreviewForTips:OnResUpdate(resId)
    self:RefreshGridProgressByResId(resId)
end

-- 单个Res下载完成，刷新格子进度条
function XUiDownloadPreviewForTips:OnResComplete(resId)
    self:RefreshGridProgressByResId(resId)
end

function XUiDownloadPreviewForTips:RefreshGridProgressByResId(resId)
    if XTool.IsTableEmpty(self._DataList) then
        return
    end
    local grids = self.PanelAchvList:GetGrids()
    for index, data in ipairs(self._DataList) do
        if not XTool.IsTableEmpty(data.ResIds) then
            for _, id in ipairs(data.ResIds) do
                if id == resId then
                    local grid = grids[index]
                    if grid then
                        grid:RefreshAggregatedProgress(data)
                    end
                    break
                end
            end
        end
    end
end