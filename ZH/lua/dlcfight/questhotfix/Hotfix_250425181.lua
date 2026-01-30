local HotfixBase = require("Common/XObjHotfixBase")

--- 本次hotfix的脚本ID，需要保证不和之前的脚本ID冲突
--- 可以采取年份+月份+日期+小时++序号的方式来命名脚本ID
--- 例如：250425181代表25年年04月25日18时序号1的脚本ID
--- 该Id需要同步写进XDlcScriptManager的HotfixObjectiveIds中，hotfix才会生效
local scriptId = 250425181 -- 该脚本的ID，不能和其他脚本冲突

---@class QuestObjectiveHotfix250425181 : HotfixBase
local ObjectiveHotfixCls = XDlcScriptManager.RegQuestObjectiveHotfixScript(scriptId, "QuestObjectiveHotfix250425181", HotfixBase)


---@type QuestObjectiveHotfix250425181
local HotfixDefine = {
    ---@type number
    ScriptId = scriptId,


    ---@param obj QuestObjective20030143
    ---@param proxy XDlcCSharpFuncs
    OnStateEnterFunc = function(obj, proxy)
        --- 这里可以添加进入状态时的逻辑
    end,


    ---@param obj QuestObjective20030143
    ---@param proxy XDlcCSharpFuncs
    OnStateInProgressFunc = function(obj, proxy)
        --- 这里可以添加进行状态时的逻辑
        local placeId = 700005
        local npcUuid = proxy:GetNpcUUID(placeId)
        XLog.Debug(string.format("OnStateInProgressFunc: %d %d", placeId, npcUuid))
        if npcUuid == 0 then
            proxy:LoadLevelNpc(placeId)
        end
    end,
}

HotfixBase.InitQuestObjectiveHotfix(ObjectiveHotfixCls, HotfixDefine) --固定的任务目标数据初始化调用（不要删除！）

return ObjectiveHotfixCls