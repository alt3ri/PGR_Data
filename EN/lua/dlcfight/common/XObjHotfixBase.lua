---@class QuestObjectiveHotfixBase
local ObjectiveHotfixBase = XClass(nil, "QuestObjectiveHotfixBase")

---@param proxy XDlcCSharpFuncs
function ObjectiveHotfixBase:Ctor(proxy)
    self.proxy = proxy
end

local emptyFunc = function() end

local function InitQuestObjectiveHotfix(ObjectiveHotfixCls, define)
    if ObjectiveHotfixCls == nil then
        XLog.Error("QuestObjectiveHotfixBase InitQuestObjectiveHotfix ObjectiveHotfixCls is nil")
        return
    end
    local scriptId = define.ScriptId

    ObjectiveHotfixCls.ScriptId = scriptId

    ObjectiveHotfixCls.Init = define.InitFunc or emptyFunc --这个函数不能为空，会报错
    ObjectiveHotfixCls.Update = nil
    ObjectiveHotfixCls.Enter = nil
    ObjectiveHotfixCls.HandleEvent = nil
    ObjectiveHotfixCls.HandleLuaEvent = nil
    ObjectiveHotfixCls.Terminate = nil
    ObjectiveHotfixCls.OnStateEnter = define.OnStateEnterFunc
    ObjectiveHotfixCls.OnStateScriptEnter = define.OnStateScriptEnterFunc
    ObjectiveHotfixCls.OnStateInProgress = define.OnStateInProgressFunc
    ObjectiveHotfixCls.OnStateExit = define.OnStateExitFunc
    ObjectiveHotfixCls.OnStateScriptExit = define.OnStateScriptExitFunc

    ObjectiveHotfixCls.HasOnStateEnterFunc = define.OnStateEnterFunc ~= nil
    ObjectiveHotfixCls.HasOnStateScriptEnterFunc = define.OnStateScriptEnterFunc ~= nil
    ObjectiveHotfixCls.HasOnStateInProgressFunc = define.OnStateInProgressFunc ~= nil
    ObjectiveHotfixCls.HasOnStateExitFunc = define.OnStateExitFunc ~= nil
    ObjectiveHotfixCls.HasOnStateScriptExitFunc = define.OnStateScriptExitFunc ~= nil
end

function ObjectiveHotfixBase.InitQuestObjectiveHotfix(ObjectiveHotfixCls, define)
    if ObjectiveHotfixCls == nil then
        XLog.Error("QuestObjectiveHotfixBase InitQuestObjectiveHotfix ObjectiveHotfixCls is nil")
        return
    end
    InitQuestObjectiveHotfix(ObjectiveHotfixCls, define)
end

return ObjectiveHotfixBase