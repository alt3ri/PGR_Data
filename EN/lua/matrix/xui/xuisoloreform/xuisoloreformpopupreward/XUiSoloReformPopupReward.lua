---@class XUiSoloReformPopupReward: XLuaUi
---@field private _Control XSoloReformControl
local XUiSoloReformPopupReward = XLuaUiManager.Register(XLuaUi, 'UiSoloReformPopupReward')
local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
local XUiSoloReformPopupRewardItem = require("XUi/XUiSoloReform/XUiSoloReformPopupReward/XUiSoloReformPopupRewardItem")

function XUiSoloReformPopupReward:OnAwake()
    self._TaskDatas = nil

end

function XUiSoloReformPopupReward:OnStart()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnMainUi:AddEventListener(handler(self, XLuaUiManager.RunMain))
    self:InitDynamicTable()
    self.BtnGroup:Init({self.BtnTabTask1, self.BtnTabTask2},function (index)
        self:OnClickTaskTypeCallBack(index)
    end)
    self.BtnGroup:SelectIndex(1)
    self:InitReddot()
    self:RefreshReddot()
end

function XUiSoloReformPopupReward:OnEnable()
    self._Control:AddEventListener(XMVCA.XSoloReform.EventId.EVENT_GAIN_TASK_REWARD, self.OnGainTaskReward, self)
    self:Refresh()
end

function XUiSoloReformPopupReward:OnDisable()
    self._Control:RemoveEventListener(XMVCA.XSoloReform.EventId.EVENT_GAIN_TASK_REWARD, self.OnGainTaskReward, self)
end

function XUiSoloReformPopupReward:InitReddot()
    self._TaskReddotId1 = self:AddRedPointEvent(self.BtnTabTask1, self.OnTaskReddotEvent1, self, 
        { XRedPointConditions.Types.CONDITION_SOLO_REFORM_TASK }, nil, false)
    self._TaskReddotId2 = self:AddRedPointEvent(self.BtnTabTask2, self.OnTaskReddotEvent2, self, 
        { XRedPointConditions.Types.CONDITION_SOLO_REFORM_CHALLENGE_TASK }, nil, false)
end
function XUiSoloReformPopupReward:RefreshReddot()
    XRedPointManager.Check(self._TaskReddotId1)
    XRedPointManager.Check(self._TaskReddotId2)
end

function XUiSoloReformPopupReward:OnTaskReddotEvent1(count)
    self.BtnTabTask1:ShowReddot(count >= 0)
end

function XUiSoloReformPopupReward:OnTaskReddotEvent2(count)
    self.BtnTabTask2:ShowReddot(count >= 0)
end

function XUiSoloReformPopupReward:OnClickTaskTypeCallBack(index)
    if index == 1 then
        self._TaskDatas = self._Control:GetTaskDatas()
    else
        self._TaskDatas = self._Control:GetChallengeTaskDatas()
    end
    self.TaskType = index
    self:Refresh()
end
function XUiSoloReformPopupReward:Refresh()
    self.DynamicTable:SetDataSource(self._TaskDatas)
    self.DynamicTable:ReloadDataSync(1)
end

function XUiSoloReformPopupReward:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.TaskList)
    self.DynamicTable:SetProxy(XUiSoloReformPopupRewardItem, self)
    self.DynamicTable:SetDelegate(self)
    self.GridTask.gameObject:SetActiveEx(false)
end

function XUiSoloReformPopupReward:OnGainTaskReward()
    self:OnClickTaskTypeCallBack(self.TaskType)
    self:RefreshReddot()
end

function XUiSoloReformPopupReward:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local data = self.DynamicTable:GetData(index)
        grid:Update(data,self.TaskType)
    end
end

function XUiSoloReformPopupReward:ChildInvokeClose()
    self:Close()
end

function XUiSoloReformPopupReward:OnDestroy()
    self._TaskDatas = nil
    self._TaskReddotId1 = nil
    self._TaskReddotId2 = nil
end

return XUiSoloReformPopupReward