local HotfixBase = require("Common/XObjHotfixBase")

--- 修复任务2001目标20010126线上露西亚无法交互问题
--- 该Id需要同步写进XDlcScriptManager的HotfixObjectiveIds中，hotfix才会生效
local scriptId = 251126182 -- 该脚本的ID，不能和其他脚本冲突

---@class QuestObjectiveHotfix251126182 : HotfixBase
local ObjectiveHotfixCls = XDlcScriptManager.RegQuestObjectiveHotfixScript(scriptId, "QuestObjectiveHotfix251126182", HotfixBase)


---@type QuestObjectiveHotfix251126182
local HotfixDefine = {
    ---@type number
    ScriptId = scriptId,


    ---@param obj QuestObjectiveHotfix251126182
    ---@param proxy XDlcCSharpFuncs
    OnStateEnterFunc = function(obj, proxy)
        --- 这里可以添加进入状态时的逻辑
    end,


    ---@param obj QuestObjectiveHotfix251126182
    ---@param proxy XDlcCSharpFuncs
    OnStateInProgressFunc = function(obj, proxy)
        if not proxy:IsActorInteractableComponentByPlaceId(ETargetActorType.Npc, 600010) then
            proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.Npc, 600010, true)
        end
    end,
}

HotfixBase.InitQuestObjectiveHotfix(ObjectiveHotfixCls, HotfixDefine) --固定的任务目标数据初始化调用（不要删除！）

return ObjectiveHotfixCls