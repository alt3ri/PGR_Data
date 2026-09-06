---@class XUiPanelCultureSkillList : XUiNode
local XUiPanelCultureSkillList = XClass(XUiNode, "XUiPanelCultureSkillList")
local XUiGridCultureSkill = require("XUi/XUiRole/XUiRoleCulture/XUiGridCultureSkill")

-- 普通技能 Pos -> 分类配置（列表父节点 transform + grid 缓存表 key）
local POS_CATEGORY_MAP = {
    { Parent = "PanelBaseSkillList",      Grids = "BaseGrids" },
    { Parent = "PanelSpecialSkillList",   Grids = "SpecialGrids" },
    { Parent = "PanelComSkillList",       Grids = "ComGrids" },
    { Parent = "PanelEvolutionSkillList", Grids = "EvolutionGrids" },
}

-- 模块级比较函数，避免热路径每次刷新重建闭包
local function _CompareByGridIndex(a, b)
    return (a.GridIndex or 0) < (b.GridIndex or 0)
end

local function _CompareSortItem(a, b)
    if a.SortKey ~= b.SortKey then
        return a.SortKey < b.SortKey
    end
    -- 同档按原列表索引保序，等价于稳定排序
    return a.OrigIndex < b.OrigIndex
end

function XUiPanelCultureSkillList:OnStart()
    self.BaseGrids = {}
    self.SpecialGrids = {}
    self.ComGrids = {}
    self.EvolutionGrids = {}
    self.AscensionGrids = {}
    self.GridClickCb = handler(self, self.OnGridClick)
end

function XUiPanelCultureSkillList:Refresh(result)
    self.CharacterId = self.Parent.CharacterId
    self.TxtSkillLevel.color = CS.UnityEngine.Color.black
    local addText = result.MaxFullSkillAdd > 0
        and string.format("<color=#3270BB>+%d</color>", result.MaxFullSkillAdd) or ""
    self.TxtSkillLevel.text = result.MaxFullSkillCur .. addText
    self.TxtLevel2.text = result.MaxFullSkillTotal

    -- 普通技能按 Pos 分桶，组内按 GridIndex 升序，固定节点按位展示（不再排序/实例化）
    local buckets = {}
    for i = 1, #POS_CATEGORY_MAP do
        buckets[i] = {}
    end
    local enhanceList = {}
    for _, info in ipairs(result.SkillPreviewList or table.empty) do
        if info.IsEnhance then
            table.insert(enhanceList, info)
        else
            local bucket = buckets[info.Pos]
            if bucket then
                table.insert(bucket, info)
            end
        end
    end
    for i = 1, #POS_CATEGORY_MAP do
        self:_RefreshCategory(i, buckets[i])
    end

    -- 跃升/独域技能
    self:_RefreshAscension(enhanceList)
end

--- 刷新单个普通技能分类
function XUiPanelCultureSkillList:_RefreshCategory(posIndex, list)
    local cfg = POS_CATEGORY_MAP[posIndex]
    local grids = self[cfg.Grids]
    table.sort(list, _CompareByGridIndex)
    XTool.UpdateDynamicItemByUiCache(grids, list, self[cfg.Parent].transform, XUiGridCultureSkill, self)
    for i = 1, #list do
        grids[i]:SetClickCb(self.GridClickCb)
    end
end

--- 刷新跃升/独域技能分类；无则隐藏整块不刷新子节点
function XUiPanelCultureSkillList:_RefreshAscension(list)
    local hasEnhance = #list > 0
    self.PanelAscensionSkill.gameObject:SetActiveEx(hasEnhance)
    if not hasEnhance then
        return
    end

    -- 跃升(泛用机)显 Title1，独域(异构)显 Title2
    local isNormalType = XMVCA.XCharacter:GetCharacterType(self.CharacterId) == XEnumConst.CHARACTER.CharacterType.Normal
    self.TxtAscensionSkillTitle1.gameObject:SetActiveEx(isNormalType)
    self.TxtAscensionSkillTitle2.gameObject:SetActiveEx(not isNormalType)

    table.sort(list, _CompareByGridIndex)
    XTool.UpdateDynamicItemByUiCache(self.AscensionGrids, list, self.Content.transform, XUiGridCultureSkill, self)
    for i = 1, #list do
        self.AscensionGrids[i]:SetClickCb(self.GridClickCb)
    end
end

function XUiPanelCultureSkillList:GetSkillCurLv(info)
    local agency = XMVCA.XCharacter
    local characterId = self.Parent.CharacterId
    if info.IsEnhance then
        local group = agency:GetCharacter(characterId):GetEnhanceSkillGroupData(info.GroupId)
        return group:GetLevel()
    end
    local groupId = agency:GetSkillGroupIdAndIndex(info.SubSkillId)
    return agency:GetCharacter(characterId):GetSkillLevel(groupId)
end

--- 稳定排序技能列表：预览提示>普通>锁定
function XUiPanelCultureSkillList:_SortSkills(skills)
    local list = {}
    for i, info in ipairs(skills or table.empty) do
        local curLv = self:GetSkillCurLv(info)
        local previewLv = info.PreviewLv or 0
        local sortKey = 1 -- 普通
        if curLv <= 0 and previewLv <= 0 then
            sortKey = 2 -- 锁定
        elseif previewLv > curLv then
            sortKey = 0 -- 有预览提示
        end
        table.insert(list, { Info = info, SortKey = sortKey, OrigIndex = i })
    end
    table.sort(list, _CompareSortItem)
    local sorted = {}
    for _, item in ipairs(list) do
        table.insert(sorted, item.Info)
    end
    return sorted
end

--- 主页面用：返回排序后的前 n 个技能
function XUiPanelCultureSkillList:GetTopSkills(skills, n)
    local sorted = self:_SortSkills(skills)
    local top = {}
    for i = 1, math.min(n, #sorted) do
        table.insert(top, sorted[i])
    end
    return top, #sorted
end

function XUiPanelCultureSkillList:OnGridClick(info)
    local characterId = self.Parent.CharacterId
    if info.IsEnhance then
        XLuaUiManager.Open("UiSkillDetailsParentV2P6", characterId,
            XEnumConst.CHARACTER.SkillDetailsType.Enhance, info.Pos, info.GridIndex)
    else
        XLuaUiManager.Open("UiSkillDetailsParentV2P6", characterId,
            XEnumConst.CHARACTER.SkillDetailsType.Normal, info.Pos, info.GridIndex)
    end
end

return XUiPanelCultureSkillList
