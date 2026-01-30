---https://kurogame.feishu.cn/sheets/Ma88su1BThVPawtGEEPc0oolnec


local GAMEPLAY_TAG_PATH = "Share/StatusSyncFight/GameplayTag/GameplayTag.tab";
local ROOT_ID = 0;
local GameplayTagConfig = CS.StatusSyncFight.XGameplayTag.GetTagArr()
local GameplayTag = {}


---@desc 获取Tag配置 测试是否能在容器中发现查询中的至少拥有一个需要匹配的标签。
---@param id int
---@return XTable.XTableGameplayTag
function GameplayTag.GetTags(id)
    if id == 0 then
        return nil
    end
    return GameplayTagConfig[id]
end

---@desc 匹配标签是否是 目标标签或目标标签的子标签
---@param targetTag int
---@param matchTag int
---@return bool 是否匹配成功
function GameplayTag.MatchTagInTree(targetTag, matchTag)
    if matchTag == ROOT_ID or targetTag == ROOT_ID then
        XLog.Error("Lua MatchTagInTree Error, targetTag and matchTag cannot be 0");
        return false;
    end
    
    if targetTag == matchTag then
        return true;
    end 
    
    local queryParentTag = GameplayTagConfig[targetTag];
    while not (queryParentTag.Parent == ROOT_ID) do
        if (queryParentTag.Parent == matchTag) then
            return true;
        end
        queryParentTag = GameplayTagConfig[queryParentTag.Parent];
    end

    return false;
end

--region LuaTagsTable匹配用
---@desc 匹配任意标签 测试查询中的所有标签是否都在容器中。如果查询为空，这会返回true。
---@param targetTags int[]
---@param matchTags int[]
---@return bool 是否匹配成功
function GameplayTag.MatchAnyTag(targetTags, matchTags)
    if targetTags == nil then
        return false;
    end
    for i = 1, #targetTags do
        local targetTag = targetTags[i]
        for j = 1, #matchTags do
            local matchTag = matchTags[j]
            if GameplayTag.MatchTagInTree(targetTag, matchTag) then
                return true;
            end
        end
    end
    return false;
end

---@desc 匹配所有标签
---@param targetTags int[]
---@param matchTags int[]
---@return bool 是否匹配成功
function GameplayTag.MatchAllTag(targetTags, matchTags)
    if targetTags == nil then
        return false;
    end
    for i = 1, #targetTags do
        local targetTag = targetTags[i]
        for j = 1, #matchTags do
            local matchTag = matchTags[j]
            if not GameplayTag.MatchTagInTree(targetTag, matchTag) then
                return false;
            end
        end
    end
    return true;
end

---@desc 匹配无标签 测试查询中的所有标签是否都不在容器中。如果查询为空，这会返回true。
---@param targetTags int[]
---@param matchTags int[]
---@return bool 是否匹配成功
function GameplayTag.MatchNoTag(targetTags, matchTags)
    if targetTags == nil then
        return true;
    end
    for i = 1, #targetTags do
        local targetTag = targetTags[i]
        for j = 1, #matchTags do
            local matchTag = matchTags[j]
            if GameplayTag.MatchTagInTree(targetTag, matchTag) then
                return false;
            end
        end
    end
    return true;
end
--endregion


--region C#TagsList匹配用

---@desc C#Tags匹配任意标签 测试查询中的所有标签是否都在容器中。如果查询为空，这会返回true。
---@param CSTargetTags CS.List<int>
---@param matchTags int[]
---@return bool 是否匹配成功
function GameplayTag.CSMatchAnyTag(CSTargetTags, matchTags)
    if CSTargetTags == nil then
        return false;
    end
    for i = 0, CSTargetTags.Count - 1, 1 do
        local targetTag = CSTargetTags[i]
        for j = 1, #matchTags do
            local matchTag = matchTags[j]
            if GameplayTag.MatchTagInTree(targetTag, matchTag) then
                return true;
            end
        end
    end
    return false;
end

---@desc C#Tags匹配所有标签
---@param CSTargetTags CS.List<int>
---@param matchTags int[]
---@return bool 是否匹配成功
function GameplayTag.CSMatchAllTag(CSTargetTags, matchTags)
    if CSTargetTags == nil then
        return false;
    end
    for i = 0, CSTargetTags.Count - 1, 1 do
        local targetTag = CSTargetTags[i]
        for j = 1, #matchTags do
            local matchTag = matchTags[j]
            if not GameplayTag.MatchTagInTree(targetTag, matchTag) then
                return false;
            end
        end
    end
    return true;
end

---@desc 匹C#Tags配无标签 测试查询中的所有标签是否都不在容器中。如果查询为空，这会返回true。
---@param CSTargetTags CS.List<int>
---@param matchTags int[]
---@return bool 是否匹配成功
function GameplayTag.CSMatchNoTag(CSTargetTags, matchTags)
    if CSTargetTags == nil then
        return true;
    end
    for i = 0, CSTargetTags.Count - 1, 1 do
        local targetTag = CSTargetTags[i]
        for j = 1, #matchTags do
            local matchTag = matchTags[j]
            if GameplayTag.MatchTagInTree(targetTag, matchTag) then
                return false;
            end
        end
    end
    return true;
end

--endregion

return GameplayTag