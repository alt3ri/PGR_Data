---@class XQuestActionContainer
---@field _Pool table<number, XQuestBaseAction[]>
---@field _RunningQueue XQuestBaseAction[]
---@field _RunningAction XQuestBaseAction
local XQuestActionContainer = XClass(nil, "XQuestActionContainer")

local State = {
    Ready = 1,
    Running = 2,
    Pause = 3,
}

function XQuestActionContainer:Ctor(finishCb)
    self._Pool = {}
    self._RunningQueue = {}
    self._ActionType2Cls = {
        [XMVCA.XBigWorldQuest.ActionType.PlayAnimation] = require("XUi/XUiBigWorld/XHud/Action/XQuestPlayAnimationAction"),
        [XMVCA.XBigWorldQuest.ActionType.Timer] = require("XUi/XUiBigWorld/XHud/Action/XQuestTimerAction"),
        [XMVCA.XBigWorldQuest.ActionType.Func] = require("XUi/XUiBigWorld/XHud/Action/XQuestFuncAction"),
    }
    self._FinishCb = finishCb
    self:UpdateState(State.Ready)
end

function XQuestActionContainer:Begin()
    self:UpdateState(State.Running)
    self._RunningAction = nil
    self:_DoAction()
end

function XQuestActionContainer:Finish()
    self:UpdateState(State.Ready)
    self._RunningAction = nil
    
    if self._FinishCb then
        self._FinishCb()
    end
end

function XQuestActionContainer:_DoAction()
    if XTool.IsTableEmpty(self._RunningQueue) then
        return self:Finish()
    end
    
    local action = table.remove(self._RunningQueue, 1)
    action:Execute()
    self._RunningAction = action
end

function XQuestActionContainer:Pause()
    if self._State == State.Pause then
        return
    end
    self:UpdateState(State.Pause)
    --暂停前，正在跑
    if self._LastState == State.Running then
        if self._RunningAction then
            if self._RunningAction:IsFinished() then
                self._RunningAction = nil
            else
                --如果正在执行的行为没有结束，则暂停它
                self._RunningAction:OnPause()
            end
        end
    end
end

function XQuestActionContainer:Resume()
    if self._State ~= State.Pause then
        return
    end
    
    self:UpdateState(self._LastState)
    --如果恢复之后仍然是Running,则直接执行下一个行为
    if self._State == State.Running then
        if self._RunningAction then
            self._RunningAction:OnResume()
        else
            self:RunNext()
        end
    end
end

function XQuestActionContainer:IsRunning()
    return self._State == State.Running
end

function XQuestActionContainer:RunNext()
    if self._State ~= State.Running then
        return
    end

    if XTool.IsTableEmpty(self._RunningQueue) then
        return self:Finish()
    end
    self:_DoAction()
end

function XQuestActionContainer:InsertAction(action)
    if self:IsRunning() then
        XLog.Error("运行过程中不允许添加新行为！！！")
        return self
    end
    self._RunningQueue[#self._RunningQueue + 1] = action
    return self
end

function XQuestActionContainer:InsertFirst(action)
    table.insert(self._RunningQueue, 1, action)
end

function XQuestActionContainer:Clear()
    for i = #self._RunningQueue, 1, -1 do
        local action = self._RunningQueue[i]
        action:OnDestroy()
        
        self:RecycleAction(action)
        table.remove(self._RunningQueue, i)
    end
    self:UpdateState(State.Ready)
    self._RunningAction = nil
end

--- 回收Action
---@param action XQuestBaseAction
function XQuestActionContainer:RecycleAction(action)
    local actionType = action:GetActionType()
    local pool = self._Pool[actionType]
    if not pool then
        pool = {}
        self._Pool[actionType] = pool
    end
    pool[#pool + 1] = action
end

function XQuestActionContainer:RetainAction(actionType, ...)
    local pool = self._Pool[actionType]
    ---@type XQuestBaseAction
    local action
    if XTool.IsTableEmpty(pool) then
        local cls = self._ActionType2Cls[actionType]
        action = cls.New()
    else
        action = table.remove(pool, 1)
    end
    action:Init(self, ...)

    return action
end

function XQuestActionContainer:UpdateState(state)
    self._LastState = self._State
    self._State = state
end

return XQuestActionContainer