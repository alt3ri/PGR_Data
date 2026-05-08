local XUiBigWorldProcessSwitchGrid = require("XUi/XUiBigWorld/XProcess/Switch/XUiBigWorldProcessSwitchGrid")

---@class XUiBigWorldProcessSwitch : XBigWorldUi
---@field BtnTanchuangClose XUiComponent.XUiButtonExt
---@field ListProcess UnityEngine.RectTransform
---@field GridProcess UnityEngine.RectTransform
---@field _Control XBigWorldCourseControl
local XUiBigWorldProcessSwitch = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldProcessSwitch")

function XUiBigWorldProcessSwitch:OnAwake()
    ---@type XUiBigWorldProcessSwitchGrid[]
    self._PorcessGrids = {}
    ---@type XBWCourseVersionEntity[]
    self._VersionEntities = false
    self._VersionEntitiesState = false

    self._Timer = false

    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessSwitch:OnStart()
    self:_InitUi()
end

function XUiBigWorldProcessSwitch:OnEnable()
    self:_Refresh()
    self:_RegisterSchedules()
end

function XUiBigWorldProcessSwitch:OnDisable()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessSwitch:OnDestroy()
end

function XUiBigWorldProcessSwitch:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnTanchuangClose:AddEventListener(Handler(self, self.Close))
end

function XUiBigWorldProcessSwitch:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldProcessSwitch:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldProcessSwitch:_RegisterSchedules()
    -- 在此处注册定时器
    self:_RemoveSchedules()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:_RefreshState()
    end, XScheduleManager.SECOND)
end

function XUiBigWorldProcessSwitch:_RemoveSchedules()
    -- 在此处移除定时器
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiBigWorldProcessSwitch:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessSwitch:_InitUi()
    self.GridProcess.gameObject:SetActiveEx(false)
end

function XUiBigWorldProcessSwitch:_Refresh()
    local index = 1
    local versionEntities = self._Control:GetVersionEntitys()

    self._VersionEntitiesState = {}
    self._VersionEntities = versionEntities
    if not XTool.IsTableEmpty(versionEntities) then
        for _, versionEntity in pairs(versionEntities) do
            local grid = self._PorcessGrids[index]

            if not grid then
                local gridUi = XUiHelper.Instantiate(self.GridProcess, self.ListProcess)

                grid = XUiBigWorldProcessSwitchGrid.New(gridUi, self)
                self._PorcessGrids[index] = grid
            end

            --- 方便策划引导查询节点
            grid.GameObject.name = string.format("GridProcess%d", versionEntity:GetVersionId())
            grid:Open()
            grid:Refresh(versionEntity)
            self._VersionEntitiesState[index] = versionEntity:IsValid()
            index = index + 1
        end
    end

    for i = index, #self._PorcessGrids do
        self._PorcessGrids[i]:Close()
    end
end

function XUiBigWorldProcessSwitch:_RefreshState()
    for i, grid in pairs(self._PorcessGrids) do
        local isValid = self._VersionEntitiesState[i] or false

        self._VersionEntitiesState[i] = grid:TryRefreshValid(isValid)
    end
end

return XUiBigWorldProcessSwitch
