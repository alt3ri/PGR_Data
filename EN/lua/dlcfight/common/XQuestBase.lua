---@class XQuestBase
local XQuestBase = XClass(nil,"QuestBase")

---@param proxy XDlcCSharpFuncs
function XQuestBase:Ctor(proxy)
    self._proxy = proxy
end

---@param eventType number
---@param eventArgs userdata
function XQuestBase:HandleEvent(eventType, eventArgs)
end

XQuestBase.StepExtraCheckFuncs = {}
XQuestBase.StepEnterFuncs = {}
XQuestBase.StepExitFuncs = {}
XQuestBase.StepHandleEventFuncs = {}

--==========新架构==================================
local emptyFunc = function() end

local function InitQuestObjective(objectiveBaseClass, define)
    local id = define.Id
    --构建任务目标的classTable
    local objectiveClass = XDlcScriptManager.RegQuestObjectiveScript(
        id, "QuestObjective"..tostring(id), objectiveBaseClass)
    objectiveClass.Init = define.InitFunc or emptyFunc --这个函数不能为空，会报错
    objectiveClass.Enter = define.EnterFunc
    objectiveClass.HandleEvent = define.HandleEventFunc
    objectiveClass.Exit = define.ExitFunc
    objectiveClass.HasEnterFunc = define.EnterFunc ~= nil
    objectiveClass.HasExitFunc = define.ExitFunc ~= nil

    --XLog.Debug("[Script] XQuestBase.InitQuestObjective: " .. tostring(id))
end

function XQuestBase.InitQuestObjectives(objectiveBaseClass, objectivesDefines)
    for _, define in pairs(objectivesDefines) do
        InitQuestObjective(objectiveBaseClass, define)
    end
end

function XQuestBase.InitSteps(stepDefines)
    -- 待删除
end

return XQuestBase
