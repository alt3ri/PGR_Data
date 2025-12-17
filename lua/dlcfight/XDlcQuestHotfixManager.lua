XDlcQuestHotfixManager = {}

--- 线上在跑逻辑的hotfix的脚本ID集合，脚本ID需要保证不和之前的脚本ID冲突
--- 集合维护脚本ID和ObjectiveId的映射
--- 可以采取年份+月份+日期+小时++序号的方式来命名脚本ID
--- 例如：250425181代表25年年04月25日18时序号1的脚本ID
local HotfixObjectiveIds = {
    ---[250425181] = 2002032,
}

function XDlcQuestHotfixManager.GetQuestObjectiveHotfixIds()
    return HotfixObjectiveIds
end
