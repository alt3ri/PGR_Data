local HotfixBase = require("Common/XObjHotfixBase")

--- 修复任务3005目标300501121线上卡交互问题
--- 该Id需要同步写进XDlcScriptManager的HotfixObjectiveIds中，hotfix才会生效
local scriptId = 251127181 -- 该脚本的ID，不能和其他脚本冲突

---@class QuestObjectiveHotfix251127181 : HotfixBase
local ObjectiveHotfixCls = XDlcScriptManager.RegQuestObjectiveHotfixScript(scriptId, "QuestObjectiveHotfix251127181", HotfixBase)


---@type QuestObjectiveHotfix251127181
local HotfixDefine = {
    ---@type number
    ScriptId = scriptId,


    ---@param obj QuestObjectiveHotfix251127181
    ---@param proxy XDlcCSharpFuncs
    OnStateEnterFunc = function(obj, proxy)
        --- 这里可以添加进入状态时的逻辑
    end,


    ---@param obj QuestObjectiveHotfix251127181
    ---@param proxy XDlcCSharpFuncs
    OnStateInProgressFunc = function(obj, proxy)
        if not proxy:IsActorInteractableComponentByPlaceId(ETargetActorType.Npc, 500026) then
            proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.Npc, 500026, true)
        end
        if proxy:IsActorInteractableComponentByPlaceId(ETargetActorType.Npc, 500028) then
            proxy:SetActorInteractableComponentEnableByPlaceId(ETargetActorType.Npc, 500028, false)
        end
    end,
}

HotfixBase.InitQuestObjectiveHotfix(ObjectiveHotfixCls, HotfixDefine) --固定的任务目标数据初始化调用（不要删除！）

return ObjectiveHotfixCls