local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiTheatre5StoryGrid = require("XUi/XUiTheatre5/XUiTheatre5Story/XUiTheatre5StoryGrid")
local XUiTheatre5StoryTab = require("XUi/XUiTheatre5/XUiTheatre5Story/XUiTheatre5StoryTab")

---@field _Control XTheatre5Control
---@class XUiTheatre5Story:XLuaUi
local XUiTheatre5Story = XLuaUiManager.Register(XLuaUi, "UiTheatre5Story")

function XUiTheatre5Story:OnStart()
    self:BindExitBtns()
    self:InitDynamicTable()
    self:InitTabs()
end

function XUiTheatre5Story:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiTheatre5StoryGrid, self)
    self.DynamicTable:SetDelegate(self)
    self.GridStoryItem.gameObject:SetActiveEx(false)
end

function XUiTheatre5Story:SetupDynamicTable(type)
    local dataSource = self._Control:GetStoryData(type)
    self.DynamicTable:SetDataSource(dataSource)
    self.DynamicTable:ReloadDataSync(1)
    
    local total = #dataSource
    local complete = 0
    for _, config in pairs(dataSource) do
        local storyId = config.StoryId
        if config.Condition == 0 or XConditionManager.CheckCondition(config.Condition) then
            complete = complete + 1
        end
    end
    self.TxtHaveCollectNum.text  = complete
    self.TxtMaxCollectNum.text = total
end

function XUiTheatre5Story:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:Update(self.DynamicTable:GetData(index), self, index)
    end
end

function XUiTheatre5Story:InitTabs(selectPage)
    self._TabDatas = self._Control:GetStoryTab()
    self._TabIndex = selectPage and selectPage or 1
    self._TabBtnObjects = {}
    self._TabBtns = {}
    for _, v in pairs(self._TabDatas) do
        local btn = CS.UnityEngine.Object.Instantiate(self.BtnTab)
        btn.gameObject:SetActive(true)
        btn.transform:SetParent(self.TabBtnContent.transform, false)
        local instance = btn:GetComponent("XUiButton")
        instance:SetName(v.Name)
        table.insert(self._TabBtnObjects, instance)
    end
    for index, btn in pairs(self._TabBtnObjects) do
        ---@type XUiTheatre5StoryTab
        local tabBtn = XUiTheatre5StoryTab.New(btn, self)
        tabBtn:Update(self._TabDatas[index])
        if not tabBtn:IsOpen() then
            btn:SetDisable(true, true)
        end
        self._TabBtns[index] = tabBtn
    end
    self.TabBtnContent:Init(self._TabBtnObjects, function(index)
        local btn = self._TabBtns[index]
        if not btn:IsOpen() then
            btn:TipLockMsg()
            return
        end
        self:SelectTab(index)
    end)
    self.BtnTab.gameObject:SetActiveEx(false)
    self.TabBtnContent:SelectIndex(self._TabIndex)
end

function XUiTheatre5Story:SelectTab(index)
    self._TabIndex = index
    local data = self._TabDatas[index]
    self:SetupDynamicTable(data.Id)
    self:PlayAnimation("QieHuan")
end

return XUiTheatre5Story