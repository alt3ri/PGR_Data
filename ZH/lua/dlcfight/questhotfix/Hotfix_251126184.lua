local HotfixBase = require("Common/XObjHotfixBase")

--- 修复任务2003目标20030116线上罗斯卡交互看不了要挟信问题
--- 该Id需要同步写进XDlcScriptManager的HotfixObjectiveIds中，hotfix才会生效
local scriptId = 251126184 -- 该脚本的ID，不能和其他脚本冲突

---@class QuestObjectiveHotfix251126184 : HotfixBase
local ObjectiveHotfixCls = XDlcScriptManager.RegQuestObjectiveHotfixScript(scriptId, "QuestObjectiveHotfix251126184", HotfixBase)


---@type QuestObjectiveHotfix251126184
local HotfixDefine = {
    ---@type number
    ScriptId = scriptId,


    ---@param obj QuestObjectiveHotfix251126184
    ---@param proxy XDlcCSharpFuncs
    OnStateEnterFunc = function(obj, proxy)
        --- 这里可以添加进入状态时的逻辑
    end,


    ---@param obj QuestObjectiveHotfix251126184
    ---@param proxy XDlcCSharpFuncs
    OnStateInProgressFunc = function(obj, proxy)
        if not proxy:IsActorInteractableComponentByPlaceId(ETargetActorType.Npc, 500005) then
            proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.Npc, 500005, true)
        end
    end,
}

HotfixBase.InitQuestObjectiveHotfix(ObjectiveHotfixCls, HotfixDefine) --固定的任务目标数据初始化调用（不要删除！）

return ObjectiveHotfixCls