local XUiBigWorldProcessCoreTipGrid = require("XUi/XUiBigWorld/XProcess/Core/Tip/XUiBigWorldProcessCoreTipGrid")

---@class XUiBigWorldProcessCoreTip : XUiNode
---@field GridProgress UnityEngine.RectTransform
---@field PanelLock UnityEngine.RectTransform
---@field TxtLock UnityEngine.UI.Text
---@field Parent XUiBigWorldProcessCoreActivity
local XUiBigWorldProcessCoreTip = XClass(XUiNode, "XUiBigWorldProcessCoreTip")

function XUiBigWorldProcessCoreTip:OnStart()
    ---@type XUiBigWorldProcessCoreTipGrid[]
    self._GridList = {}

    self:_InitUi()
    self:_RegisterButtonClicks()
end

function XUiBigWorldProcessCoreTip:OnEnable()
    self:_RegisterListeners()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldProcessCoreTip:OnDisable()
    self:_RemoveListeners()
    self:_RemoveSchedules()
end

function XUiBigWorldProcessCoreTip:OnDestroy()
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreTip:Refresh(elementEntity)
    self:_RefreshLocked(elementEntity)
    self:_RefreshProgress(elementEntity)
end

function XUiBigWorldProcessCoreTip:_RegisterButtonClicks()
    -- 在此处注册按钮事件
end

function XUiBigWorldProcessCoreTip:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldProcessCoreTip:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldProcessCoreTip:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldProcessCoreTip:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldProcessCoreTip:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldProcessCoreTip:_InitUi()
    self.GridProgress.gameObject:SetActiveEx(false)
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreTip:_RefreshLocked(elementEntity)
    local isLock, lockText = elementEntity:IsLocked()

    self.PanelLock.gameObject:SetActiveEx(isLock)
    if isLock then
        self.TxtLock.text = lockText
        for _, grid in pairs(self._GridList) do
            grid:Close()
        end
    end
    self._IsLock = isLock
end

---@param elementEntity XBWCourseCoreElementEntity
function XUiBigWorldProcessCoreTip:_RefreshProgress(elementEntity)
    if not self._IsLock and self.ListProgress then
        self.ListProgress.gameObject:SetActiveEx(true)
    end
    local index = 1
    if not self._IsLock then
        local progressData = elementEntity:GetProgressTipData()
        if not XTool.IsTableEmpty(progressData) then
            for _, progress in pairs(progressData) do
                local grid = self._GridList[index]

                if not grid then
                    local gridUi = XUiHelper.Instantiate(self.GridProgress, self.GridProgress.transform.parent)

                    grid = XUiBigWorldProcessCoreTipGrid.New(gridUi, self)
                    self._GridList[index] = grid
                end
                grid.GameObject.name = "Index" .. index
                grid:Open()
                grid:Refresh(progress.Title, progress.Progress, progress.IsComplete)
                index = index + 1
            end
        end
    end
    for i = index, #self._GridList do
        self._GridList[i]:Close()
    end
    if self._IsLock and self.ListProgress then
        self.ListProgress.gameObject:SetActiveEx(false)
    end
end

return XUiBigWorldProcessCoreTip
