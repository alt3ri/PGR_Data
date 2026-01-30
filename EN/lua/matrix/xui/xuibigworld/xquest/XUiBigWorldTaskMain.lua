
---@class XUiBigWorldTaskMain : XBigWorldUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XBigWorldQuestControl
---@field _PanelTaskGroup table<number, XUiPanelBWTaskGroup>
local XUiBigWorldTaskMain = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldTaskMain")

local XUiPanelBWTaskGroup = require("XUi/XUiBigWorld/XQuest/Panel/XUiPanelBWTaskGroup")

local DlcEventId = XMVCA.XBigWorldService.DlcEventId

local TASK_TYPE_ALL = XMVCA.XBigWorldQuest.QuestType.All
--策划需要缓存
--local Type2TabIndex = {}

local LastSelectQuest = nil

function XUiBigWorldTaskMain:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiBigWorldTaskMain:OnStart(index, questId)
    self._DefaultIndex = index or 1
    self._DefaultQuestId = questId
    self:InitView()
    
    XEventManager.AddEventListener(DlcEventId.EVENT_QUEST_RED_POINT_REFRESH, self.RefreshRedPoint, self)
end

function XUiBigWorldTaskMain:OnEnable()
    self.PanelTabBtnGroup:SelectIndex(self._DefaultIndex)
end

function XUiBigWorldTaskMain:OnDisable()
end

function XUiBigWorldTaskMain:OnDestroy()
    XEventManager.RemoveEventListener(DlcEventId.EVENT_QUEST_RED_POINT_REFRESH, self.RefreshRedPoint, self)
    
    XMVCA.XBigWorldQuest:SaveQuestRed()
end

function XUiBigWorldTaskMain:InitUi()
    -- 任务类型页签
    self._TypeIds = {TASK_TYPE_ALL, }
    self._TypeIds = XTool.MergeArray(self._TypeIds, self._Control:GetQuestTypeIds())

    local tabList = {}
    for index, typeId in ipairs(self._TypeIds) do
        local btn = index == 1 and self.BtnTab or XUiHelper.Instantiate(self.BtnTab, self.PanelTabBtnGroup.transform)
        local icon = self._Control:GetQuestTypeIcon(typeId)
        if not string.IsNilOrEmpty(icon) then
            btn:SetSprite(icon)
        end
        btn:ShowReddot(self:CheckRedPoint(typeId))
        table.insert(tabList, btn)
    end
    self.PanelTabBtnGroup:Init(tabList, function(index) self:OnSelectTab(index) end)

    self._TabList = tabList
    -- 任务组页签
    ---@type table<number, XUiPanelBWTaskGroup>
    self._PanelTaskGroup = {}
    self.PanelTitleBtnGroup.gameObject:SetActiveEx(false)
end

function XUiBigWorldTaskMain:InitCb()
    self.BtnBack:AddEventListener(handler(self, self.Close))

    self.BtnStory:AddEventListener(handler(self, self.OnBtnStoryClick))
end

function XUiBigWorldTaskMain:InitView()
end

function XUiBigWorldTaskMain:OnSelectTab(tabIndex)
    if self._TabIndex == tabIndex then
        return
    end

    if self._TabIndex then
        self:PlayAnimation("QieHuan")
    end
    self._TabIndex = tabIndex
    self:RefreshRedPoint()
    self:RefreshTaskGroup()
end

function XUiBigWorldTaskMain:RefreshTaskGroup()
    local typeId = self._TypeIds[self._TabIndex]
    if self._LastTypeId then
        local lastPanel = self:GetPanelTaskGroup(self._LastTypeId)
        lastPanel:Close()
    end
    local panel = self:GetPanelTaskGroup(typeId)
    panel:Open()
    self._LastTypeId = typeId
end

function XUiBigWorldTaskMain:GetSelectData(typeId)
    --默认选中外部传值
    if self._DefaultQuestId then
        local questId = self._DefaultQuestId
        self._DefaultQuestId = nil
        --Type2TabIndex[typeId] = questId
        LastSelectQuest = questId
        return questId
    end
    return LastSelectQuest
end

function XUiBigWorldTaskMain:SetSelectData(typeId, questId)
    LastSelectQuest = questId
end

function XUiBigWorldTaskMain:RefreshTaskContent(typeId, groupId, questId)
    if not self._PanelTaskContent then
        self._PanelTaskContent = require("XUi/XUiBigWorld/XQuest/Panel/XUiPanelBWTaskContent").New(self.PanelTask, self)
    end
    if typeId > 0 and groupId > 0 and questId > 0 then
        self._PanelTaskContent:Open()
        self._PanelTaskContent:RefreshView(questId)
        self.PaneNothing.gameObject:SetActiveEx(false)
    else
        self.PaneNothing.gameObject:SetActiveEx(true)
        self._PanelTaskContent:Close()
    end
end

function XUiBigWorldTaskMain:GetPanelTaskGroup(typeId)
    local panel = self._PanelTaskGroup[typeId]
    if panel then
        return panel
    end
    local ui = XUiHelper.Instantiate(self.PanelTitleBtnGroup, self.ContentGroup.transform)
    ui.gameObject:SetActiveEx(true)
    panel = XUiPanelBWTaskGroup.New(ui, self, typeId)
    self._PanelTaskGroup[typeId] = panel

    return panel
end

function XUiBigWorldTaskMain:OnBtnStoryClick()
    XLuaUiManager.Open("UiBigWorldLineChapter")
end

function XUiBigWorldTaskMain:CheckRedPoint(type)
    return XMVCA.XBigWorldQuest:CheckQuestRedWithQuestType(type)
end

function XUiBigWorldTaskMain:RefreshRedPoint()
    for i, typeId in pairs(self._TypeIds) do
        local btn = self._TabList[i]
        btn:ShowReddot(self:CheckRedPoint(typeId))
    end 
end

function XUiBigWorldTaskMain:RefreshTabButton()
    local typeId = self._TypeIds[self._TabIndex]
    local panel = self:GetPanelTaskGroup(typeId)
    if not panel then
        return
    end
    panel:RefreshButton()
end