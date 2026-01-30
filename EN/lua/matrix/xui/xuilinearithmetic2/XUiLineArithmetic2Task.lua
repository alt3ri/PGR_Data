local XUiLineArithmetic2TaskGrid = require("XUi/XUiLineArithmetic2/XUiLineArithmetic2TaskGrid")
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
---@class XUiLineArithmetic2Task : XLuaUi
---@field _Control XLineArithmetic2Control
local XUiLineArithmetic2Task = XLuaUiManager.Register(XLuaUi, "UiLineArithmetic2Task")

function XUiLineArithmetic2Task:OnAwake()
    self.GridTask.gameObject:SetActiveEx(false)
    self:AddBtnListener()
end

function XUiLineArithmetic2Task:OnStart()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewTask)
    self.DynamicTable:SetProxy(XUiLineArithmetic2TaskGrid, self)
    self.DynamicTable:SetDelegate(self)

    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.AddEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
end

function XUiLineArithmetic2Task:OnEnable()
    self:OnTaskChangeSync()
end

function XUiLineArithmetic2Task:OnDisable()

end

function XUiLineArithmetic2Task:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_SYNC, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.OnTaskChangeSync, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_TASK_FINISH_FAIL, self.OnTaskChangeSync, self)
end

--region Ui - BtnListener
function XUiLineArithmetic2Task:AddBtnListener()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
end

function XUiLineArithmetic2Task:OnBtnBackClick()
    self:Close()
end

function XUiLineArithmetic2Task:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--endregion

function XUiLineArithmetic2Task:OnTaskChangeSync()
    local taskDatas = self._Control:GetTaskList()
    if not XTool.IsTableEmpty(taskDatas) then
        self.DynamicTable:SetDataSource(taskDatas)
        self.DynamicTable:ReloadDataSync(1)
    end
end

function XUiLineArithmetic2Task:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:ResetData(self.DynamicTable.DataSource[index])
    end
end

return XUiLineArithmetic2Task