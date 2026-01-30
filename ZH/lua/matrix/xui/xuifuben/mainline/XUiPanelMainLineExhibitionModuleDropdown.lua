---@class XUiPanelMainLineExhibitionModuleDropdown
---@field UiPanelExhibition XUiPanelMainLineExhibition
---@field IsOpenDropdown boolean 是否打开下拉列表
---@field CurrentModuleId number 当前的模块Id
local XUiPanelMainLineExhibitionModuleDropdown = XClass(nil, "XUiPanelMainLineExhibitionModuleDropdown")

function XUiPanelMainLineExhibitionModuleDropdown:Ctor(uiPanelExhibition, ui)
    self.UiPanelExhibition = uiPanelExhibition
    XUiHelper.InitUiClass(self, ui)
    
    self.IsOpenDropdown = false
    self.CurrentModuleId = nil
    self.BtnSwitchPanelBg.gameObject:SetActiveEx(false)
    self.ModuleList.gameObject:SetActiveEx(false)
    self.ModuleItem.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
end

function XUiPanelMainLineExhibitionModuleDropdown:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnCurModule, self.OnBtnCurModuleClick, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnSwitchPanelBg, self.OnBgClick, nil, true)
end

function XUiPanelMainLineExhibitionModuleDropdown:OnBtnCurModuleClick()
    if self.IsOpenDropdown then
        self:CloseDropdown()
    else
        self:OpenDropdown()
    end
end

function XUiPanelMainLineExhibitionModuleDropdown:OnBgClick()
    if self.IsOpenDropdown then
        self:CloseDropdown()
    end
end

-- 打开下拉列表
function XUiPanelMainLineExhibitionModuleDropdown:OpenDropdown()
    self.UiPanelExhibition:SetAreaScaleDragEnable(false)
    self.IsOpenDropdown = true
    self.BtnSwitchPanelBg.gameObject:SetActiveEx(true)
    self.ModuleList.gameObject:SetActiveEx(true)
    self.ImgArrowDownNormal.gameObject:SetActiveEx(false)
    self.ImgArrowUpNormal.gameObject:SetActiveEx(true)
    self.ImgArrowDownPress.gameObject:SetActiveEx(false)
    self.ImgArrowUpPress.gameObject:SetActiveEx(true)
    
    self:UpdateDynamicTable()
end

-- 关闭下拉列表
function XUiPanelMainLineExhibitionModuleDropdown:CloseDropdown()
    self.UiPanelExhibition:SetAreaScaleDragEnable(true)
    self.IsOpenDropdown = false
    self.BtnSwitchPanelBg.gameObject:SetActiveEx(false)
    self.ModuleList.gameObject:SetActiveEx(false)
    self.ImgArrowDownNormal.gameObject:SetActiveEx(true)
    self.ImgArrowUpNormal.gameObject:SetActiveEx(false)
    self.ImgArrowDownPress.gameObject:SetActiveEx(true)
    self.ImgArrowUpPress.gameObject:SetActiveEx(false)
end

-- 初始化动态滑动列表
function XUiPanelMainLineExhibitionModuleDropdown:InitDynamicTable()
    local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
    local XUiGridMainLineExhibitionModuleDropdown = require("XUi/XUiFuben/MainLine/XUiGridMainLineExhibitionModuleDropdown")
    self.DynamicTable = XDynamicTableNormal.New(self.ModuleList)
    self.DynamicTable:SetDelegate(self)
    self.DynamicTable:SetProxy(XUiGridMainLineExhibitionModuleDropdown, self)
end

-- 刷新动态滑动类表
function XUiPanelMainLineExhibitionModuleDropdown:UpdateDynamicTable()
    if not self.DynamicTable then
        self:InitDynamicTable()
    end

    self.ModuleConfigs = XMVCA.XMainLine2:GetConfigExhibitionModule()
    self.DynamicTable:SetDataSource(self.ModuleConfigs)
    self.DynamicTable:ReloadDataASync(#self.ModuleConfigs > 0 and #self.ModuleConfigs or -1)
end

function XUiPanelMainLineExhibitionModuleDropdown:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local moduleConfig = self.ModuleConfigs[index]
        local isSelect = moduleConfig.Id == self.CurrentModuleId
        grid:Refresh(moduleConfig, isSelect)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self.UiPanelExhibition:LocateByIndex(index)
        self:CloseDropdown()
    end
end

-- 设置当前模块Id
function XUiPanelMainLineExhibitionModuleDropdown:SetCurrentModuleId(moduleId)
    self.CurrentModuleId = moduleId
    local moduleConfig = XMVCA.XMainLine2:GetConfigExhibitionModule(moduleId)
    self.TxtName.text = moduleConfig.Name
    local currentProgress, maxProgress = XMVCA.XMainLine2:GetExhibitionModuleProgress(moduleId)
    self.TxtProgress.text = math.floor(currentProgress / maxProgress * 100) .. "%"
    
    -- 蓝点
    local module = self.UiPanelExhibition:GetModuleByModuleId(moduleId)
    local isRed = module:IsShowRed()
    self.BtnCurModule:ShowReddot(isRed)
end

function XUiPanelMainLineExhibitionModuleDropdown:Open()
    self.GameObject:SetActiveEx(true)
end

function XUiPanelMainLineExhibitionModuleDropdown:Close()
    self.GameObject:SetActiveEx(false)
end

return XUiPanelMainLineExhibitionModuleDropdown
