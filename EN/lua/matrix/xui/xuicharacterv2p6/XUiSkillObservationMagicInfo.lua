local XGridSkillObservationMagicInfo = require("XUi/XUiCharacterV2P6/Grid/XGridSkillObservationMagicInfo")
local XUiSkillObservationMagicInfo = XLuaUiManager.Register(XLuaUi, "UiSkillObservationMagicInfo")

function XUiSkillObservationMagicInfo:OnAwake()
    self:InitButton()
    self:InitDynamicTable()
end

function XUiSkillObservationMagicInfo:InitButton()
    XUiHelper.RegisterClickEvent(self, self.BtnClose, self.Close)
    XUiHelper.RegisterClickEvent(self, self.BtnTanchuangClose, self.Close)
end

function XUiSkillObservationMagicInfo:InitDynamicTable()
    self.DynamicTable = XUiHelper.DynamicTableNormal(self, self.PanelList, XGridSkillObservationMagicInfo)
    local grid = self.DynamicTable:GetGrid()
    if grid and grid.gameObject then
        grid.gameObject:SetActiveEx(false)
    end
end

function XUiSkillObservationMagicInfo:OnStart(skillId)
    self.SkillId = skillId
end

function XUiSkillObservationMagicInfo:OnEnable()
    if not XTool.IsNumberValid(self.SkillId) then
        return
    end

    self.ObsCfg = XMVCA.XCharacter:GetModelCharacterObsTriggerMagic()[self.SkillId]
    if XTool.IsTableEmpty(self.ObsCfg) then
        return
    end

    self.CurSkillLevel = XMVCA.XCharacter:GetSkillLevel(self.SkillId)
    self:RefreshTabData()
    self:RefreshTab()
end

function XUiSkillObservationMagicInfo:RefreshTabData()
    local tabDataById = {}
    local tabConfigByCareer = {}
    local tabConfigs = XMVCA.XCharacter:GetModelUiSkillObservationMagicInfoController()
    for _, tabConfig in pairs(tabConfigs) do
        for _, career in ipairs(tabConfig.Career) do
            tabConfigByCareer[career] = tabConfig
        end
    end

    self.TabData = {}
    for index, element in ipairs(self.ObsCfg.ObservationElement) do
        local tabConfig = tabConfigByCareer[self.ObsCfg.ObservationCareer[index]]
        if tabConfig then
            local tabData = tabDataById[tabConfig.TabId]
            if not tabData then
                tabData = {
                    TabId = tabConfig.TabId,
                    TabText = tabConfig.TabText,
                    ElementList = {},
                    ElementData = {},
                }
                tabDataById[tabConfig.TabId] = tabData
                table.insert(self.TabData, tabData)
            end

            if not tabData.ElementData[element] then
                tabData.ElementData[element] = {}
                table.insert(tabData.ElementList, element)
            end
            table.insert(tabData.ElementData[element], { IndexInCfg = index, Level = self.ObsCfg.Level[index] })
        end
    end

    table.sort(self.TabData, function(a, b)
        return a.TabId < b.TabId
    end)
end

function XUiSkillObservationMagicInfo:RefreshTab()
    self.TabButtons = self.TabButtons or { self.BtnTab }
    local activeTabButtons = {}
    for index, tabData in ipairs(self.TabData) do
        local btn = self.TabButtons[index]
        if not btn then
            btn = XUiHelper.Instantiate(self.BtnTab, self.BtnTab.transform.parent)
            self.TabButtons[index] = btn
        end
        btn.gameObject:SetActiveEx(true)
        btn:SetNameByGroup(0, tabData.TabText)
        table.insert(activeTabButtons, btn)
    end

    for index = #self.TabData + 1, #self.TabButtons do
        self.TabButtons[index].gameObject:SetActiveEx(false)
    end

    self.LayerSetting:Init(activeTabButtons, handler(self, self.OnSelectTab))
    self.LayerSetting:SelectIndex(1)
end

function XUiSkillObservationMagicInfo:OnSelectTab(index)
    self.CurTabData = self.TabData[index]
    if self.TxtPanelTitle then
        self.TxtPanelTitle.text = self.CurTabData.TabText
    end
    self.DynamicTable:SetDataSource(self.CurTabData.ElementList)
    self.DynamicTable:ReloadDataASync()
end

function XUiSkillObservationMagicInfo:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local element = self.CurTabData.ElementList[index]
        local dataList = self.CurTabData.ElementData[element]
        local targetLevelData = XTool.FindClosestNumber(dataList, self.CurSkillLevel, "Level")
        grid:Refresh(self.ObsCfg, targetLevelData.IndexInCfg)
    end
end

return XUiSkillObservationMagicInfo
