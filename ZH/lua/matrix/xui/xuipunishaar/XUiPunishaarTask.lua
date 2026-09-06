---@class XUiPunishaarTask: XLuaUi
---@field private _Control XPunishaarControl
local XUiPunishaarTask = XLuaUiManager.Register(XLuaUi, 'UiPunishaarTask')
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiPunishaarTaskItem = require("XUi/XUiPunishaar/Grid/XUiGridPunishaarTask")

function XUiPunishaarTask:OnGetEvents()
    return {
        XEventId.EVENT_TASK_SYNC,
    }
end
function XUiPunishaarTask:OnAwake()
    self._TaskDatas = nil

end

function XUiPunishaarTask:OnStart()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnMainUi:AddEventListener(handler(self, XLuaUiManager.RunMain))
    self:InitDynamicTable()
    self.BtnGroup:Init({ self.BtnTabTask1, self.BtnTabTask2 }, function(index)
        self:OnClickTaskTypeCallBack(index)
    end)
    self:InitReddot()
    self.BtnGroup:SelectIndex(1)
end

function XUiPunishaarTask:OnEnable()
    self:RefreshTask()
end

function XUiPunishaarTask:OnDisable()
end

function XUiPunishaarTask:InitReddot()
    self._TaskReddotId1 = self:AddRedPointEvent(
        self.BtnTabTask1,
        self.OnTaskReddotEvent1,
        self,
        { XRedPointConditions.Types.CONDITION_PUNISHAAR_TASK },
        1,
        false
    )

    self._TaskReddotId2 = self:AddRedPointEvent(
        self.BtnTabTask2,
        self.OnTaskReddotEvent2,
        self,
        { XRedPointConditions.Types.CONDITION_PUNISHAAR_TASK },
        2,
        false
    )
end

function XUiPunishaarTask:OnNotify(evt, ...)
    if evt == XEventId.EVENT_TASK_SYNC then
        self:RefreshTask()
    end
end

function XUiPunishaarTask:RefreshTask()
    local taskType = self.TaskType or 1
    self._TaskDatas = self._Control:GetTaskDatas(taskType)
    self:Refresh()
    self:RefreshReddot()
end

function XUiPunishaarTask:RefreshReddot()
    XRedPointManager.Check(self._TaskReddotId1)
    XRedPointManager.Check(self._TaskReddotId2)
end

function XUiPunishaarTask:OnTaskReddotEvent1(count)
    self.BtnTabTask1:ShowReddot(count >= 0)
end

function XUiPunishaarTask:OnTaskReddotEvent2(count)
    self.BtnTabTask2:ShowReddot(count >= 0)
end

function XUiPunishaarTask:OnClickTaskTypeCallBack(index)
    self.TaskType = index
    self:RefreshTask()
end

function XUiPunishaarTask:Refresh()
    self.DynamicTable:SetDataSource(self._TaskDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiPunishaarTask:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XUiPunishaarTaskItem, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end


function XUiPunishaarTask:OnGainTaskReward()
    self:RefreshTask()
end

function XUiPunishaarTask:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        grid:Update(data)
    end
end

function XUiPunishaarTask:OnDestroy()
    self._TaskDatas = nil
    self._TaskReddotId1 = nil
    self._TaskReddotId2 = nil
end

return XUiPunishaarTask