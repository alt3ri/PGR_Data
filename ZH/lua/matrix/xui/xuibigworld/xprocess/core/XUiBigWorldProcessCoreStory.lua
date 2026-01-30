local XUiBigWorldProcessCoreStoryGrid = require("XUi/XUiBigWorld/XProcess/Core/XUiBigWorldProcessCoreStoryGrid")

---@class XUiBigWorldProcessCoreStory : XUiNode
---@field TxtName UnityEngine.UI.Text
---@field RImgBanner UnityEngine.UI.RawImage
---@field ListStory UnityEngine.RectTransform
---@field GridStory UnityEngine.RectTransform
---@field SingleGridStory UnityEngine.RectTransform
---@field SpineBanner UnityEngine.RectTransform
---@field Parent XUiBigWorldProcessCore
---@field _Control XBigWorldCourseControl
local XUiBigWorldProcessCoreStory = XClass(XUiNode, "XUiBigWorldProcessCoreStory")

function XUiBigWorldProcessCoreStory:OnStart()
    ---@type XBWCourseCoreEntity
    self._Entity = false
    ---@type XDynamicTableNormal
    self._DynamicTable = XUiHelper.DynamicTableNormal(self, self.ListStory, XUiBigWorldProcessCoreStoryGrid)
    ---@type XUiBigWorldProcessCoreStoryGrid
    self._StoryGrid = XUiBigWorldProcessCoreStoryGrid.New(self.SingleGridStory, self)
    self._StoryGrid:Close()

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessCoreStory:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessCoreStory:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessCoreStory:OnDestroy()
end

---@param grid XUiBigWorldProcessCoreStoryGrid
function XUiBigWorldProcessCoreStory:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local entity = self._DynamicTable:GetData(index)

        grid:Refresh(entity)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:_RefreshCurrentElementRecord()
    end
end

---@param coreEntity XBWCourseCoreEntity
function XUiBigWorldProcessCoreStory:Refresh(coreEntity)
    self._Entity = coreEntity
    self.TxtName.text = coreEntity:GetName()
    self:_RefreshBanner(coreEntity)
    self:_RefreshElements(coreEntity)
end

function XUiBigWorldProcessCoreStory:_RegisterButtonClicks()
    --在此处注册按钮事件
end

function XUiBigWorldProcessCoreStory:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldProcessCoreStory:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldProcessCoreStory:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessCoreStory:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessCoreStory:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessCoreStory:_InitUi()
    self.GridStory.gameObject:SetActiveEx(false)
end

---@param coreEntity XBWCourseCoreEntity
function XUiBigWorldProcessCoreStory:_RefreshElements(coreEntity)
    local elements = coreEntity:GetElementEntitysWithSort()

    if not XTool.IsTableEmpty(elements) and #elements == 1 then
        self._StoryGrid:Open()
        self._StoryGrid:Refresh(elements[1])
        self:_RefreshCurrentElementRecord()
    else
        self._StoryGrid:Close()
        self:_RefreshDynamicTable(elements)
    end
end

---@param elements XBWCourseCoreElementEntity[]
function XUiBigWorldProcessCoreStory:_RefreshDynamicTable(elements)
    if not XTool.IsTableEmpty(elements) then
        self._DynamicTable:SetActive(true)
        self._DynamicTable:SetDataSource(elements)
        self._DynamicTable:ReloadDataSync()
    else
        self._DynamicTable:SetActive(false)
    end
end

function XUiBigWorldProcessCoreStory:_RefreshCurrentElementRecord()
    if self._Entity then
        self._Control:RecordCoreElementsByCoreEntity(self._Entity)
    end
end

---@param coreEntity XBWCourseCoreEntity
function XUiBigWorldProcessCoreStory:_RefreshBanner(coreEntity)
    local spineBanner = coreEntity:GetSpineBanner()
    local banner = coreEntity:GetBanner()

    if string.IsNilOrEmpty(banner) and string.IsNilOrEmpty(coreEntity) then
        self.RImgBanner.gameObject:SetActiveEx(false)
        self.SpineBanner.gameObject:SetActiveEx(false)
    elseif not string.IsNilOrEmpty(spineBanner) then
        self.RImgBanner.gameObject:SetActiveEx(false)
        self.SpineBanner.gameObject:SetActiveEx(true)
        self.SpineBanner:LoadPrefab(spineBanner)
    else
        self.RImgBanner.gameObject:SetActiveEx(true)
        self.SpineBanner.gameObject:SetActiveEx(false)
        self.RImgBanner:SetImage(spineBanner)
    end
end

return XUiBigWorldProcessCoreStory
