local XUiGridBWItem = require("XUi/XUiBigWorld/XCommon/Grid/XUiGridBWItem")

---@class XUiBigWorldBackpackItem : XUiNode
---@field Lock UnityEngine.RectTransform
---@field Red UnityEngine.RectTransform
---@field PanelEmpty UnityEngine.RectTransform
---@field ItemGrid UnityEngine.RectTransform
---@field Parent XUiBigWorldBackpack
---@field _Control XBigWorldBackpackControl
local XUiBigWorldBackpackItem = XClass(XUiNode, "XUiBigWorldBackpackItem")

-- region 生命周期

function XUiBigWorldBackpackItem:OnStart()
    self.CanvasGroup = self.Grid.transform:GetComponent(typeof(CS.UnityEngine.CanvasGroup))
    self.Grid:AddEventListener(function()
        if self._Grid then
            if self._Grid:IsNodeShow() then self._Grid:OnClick() end
        end
    end)
    ---@type XUiGridBWItem
    self._Grid = false
    self._Index = 0
    self:_RegisterButtonClicks()
end

function XUiBigWorldBackpackItem:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldBackpackItem:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
    self:StopAnimationTimer()
end

function XUiBigWorldBackpackItem:OnDestroy()

end

-- endregion

-- region 按钮事件

function XUiBigWorldBackpackItem:OnGridClick(itemParams, goodParams)
    self:SetSelect(true)
    self._Control:AddRecordItemId(itemParams)
    self:ShowReddot(false)
    self.Parent:OnItemGridClick(self._Index, itemParams, goodParams)
end

-- endregion

function XUiBigWorldBackpackItem:Refresh(itemId, index, isSelect)
    self:_InitItemGrid()
    self._Index = index
    if XTool.IsNumberValid(itemId) then
        self._Grid:Open()
        self._Grid:Refresh(itemId)
        if isSelect then
            self._Grid:OnClick()
        end
        self.PanelEmpty.gameObject:SetActiveEx(false)
        self:ShowReddot(not self._Control:CheckItemIsRecord(itemId))
    else
        self._Grid:Close()
        self.PanelEmpty.gameObject:SetActiveEx(true)
        self:ShowReddot(false)
    end
    self:SetSelect(isSelect)
end

function XUiBigWorldBackpackItem:SetLock(isLock)
    self.Lock.gameObject:SetActiveEx(isLock)
end

function XUiBigWorldBackpackItem:SetSelect(isSelect)
    self.Grid:SetButtonState(isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal)
end

function XUiBigWorldBackpackItem:ShowReddot(isShow)
    self.Grid:ShowReddot(isShow)
end

-- region 私有方法

function XUiBigWorldBackpackItem:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    -- XUiHelper.RegisterClickEvent(self, self.BtnGo, self.OnBtnGoClick, true)
end

function XUiBigWorldBackpackItem:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldBackpackItem:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldBackpackItem:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldBackpackItem:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldBackpackItem:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiBigWorldBackpackItem:_RefreshConsume()
    
end

function XUiBigWorldBackpackItem:_InitItemGrid()
    if not self._Grid then
        self._Grid = XUiGridBWItem.New(self.ItemGrid, self, Handler(self, self.OnGridClick))
    end
end

function XUiBigWorldBackpackItem:StopAnimationTimer()
    if not self._AnimationTimer then
        return
    end
    XScheduleManager.UnSchedule(self._AnimationTimer)
    self._AnimationTimer = false
end

function XUiBigWorldBackpackItem:PlayEnableAnimation(index)
    self:StopAnimationTimer()
    self.CanvasGroup.alpha = 0
    self._AnimationTimer = XScheduleManager.ScheduleOnce(function()
        self.GridEnable:PlayTimelineAnimation()
        self:StopAnimationTimer()
    end, 80 * index)
end

-- endregion

return XUiBigWorldBackpackItem
