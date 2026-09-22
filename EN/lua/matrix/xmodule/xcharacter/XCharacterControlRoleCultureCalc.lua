---@type XCharacterControl
local XCharacterControl = XClassPartial("XCharacterControl")

-- 兑换处理的模块顺序标记：等级最先、晋升次之、技能最后（共享代币如螺母时前置模块优先占用）
local MODULE_LEVEL = 1
local MODULE_GRADE = 2
local MODULE_SKILL = 3

-- GetCharacterSkills 结果缓存：该调用会新建大表+读大量配置,开销大。技能结构由 (角色, 晋升等级) 决定
-- (升阶会解锁新技能),故用 characterId+Grade 作 key。预览态不改真实 Grade,同一会话内命中;真实升阶后 key 变自动重建。
-- 技能当前等级(CurLv)不缓存、每次实时读 GetSkillLevel,故养成后等级变化不会取到过期值。
local _CachedSkillsCharId
local _CachedSkillsGrade
local _CachedSkills

local function ClearTable(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

local function ClearArray(t)
    for i = #t, 1, -1 do
        t[i] = nil
    end
end

local function AddCost(costMap, itemId, count)
    if XTool.IsNumberValid(itemId) and count and count > 0 then
        costMap[itemId] = (costMap[itemId] or 0) + count
    end
end

--region 预览计算

---@class XRoleCultureCalcArgs 计算入参（由 UI 收集自身字段填入）
---@field CharacterId number
---@field TargetLevel number
---@field TargetGrade number
---@field SkillTargetLevel number 技能目标等级（0~最高上限，各技能只升不降、各自封顶）
---@field IncludeEnhance boolean
---@field AutoExchange boolean

---@class XRoleCultureResult : XRoleCultureCalcArgs 计算结果（含入参快照，供执行链直接使用）
---@field DirectCostMap table<number, number> 原始材料需求(合并三模块,供兑换计算用)
---@field LevelCostMap table<number, number> 等级模块消耗
---@field GradeCostMap table<number, number> 晋升模块消耗
---@field SkillCostMap table<number, number> 技能模块消耗
---@field ExpItemPlan table<number, number> 升级经验道具选用
---@field ExchangePlan table[] 兑换计划 {ShopId, GoodsId, ItemId, Count}
---@field FinalCostMap table<number, number> 含兑换消耗的最终资源需求
---@field ExchangeTokenCostMap table<number, number> 自动兑换付出的代币消耗(如跃升晶元/复刷关代币)
---@field LackMap table<number, number> 兑换后仍缺
---@field IsGradeMaterialLack boolean 晋升模块材料是否不足（兑换补足后仍缺）
---@field SkillPreviewList table[] 技能预览，每个子技能一条 {IsEnhance, Pos, SubSkillId, GroupId, SkillId, PreviewLv, GridIndex}
---@field PanelCostList table[] 资源条 {Id, Count}
---@field MaxFullSkillCur number 技能标题 n
---@field MaxFullSkillAdd number 技能标题 +x
---@field MaxFullSkillTotal number 技能标题 N
---@field MaxSkillLevel number 技能步进器上限（所有技能中的最高等级上限）
---@field MaxReachableLevel number
---@field MaxReachableGrade number
---@field MaxReachableSkillLevel number 当前资源可达的技能目标等级
---@field FreeSkillLevel number 技能免费上限

function XCharacterControl:_NewRoleCultureWork(args)
    return {
        CharacterId = args.CharacterId,
        TargetLevel = args.TargetLevel,
        TargetGrade = args.TargetGrade,
        SkillTargetLevel = args.SkillTargetLevel,
        IncludeEnhance = args.IncludeEnhance,
        AutoExchange = args.AutoExchange,
        DirectCostMap = {},
        LevelCostMap = {},
        GradeCostMap = {},
        SkillCostMap = {},
        -- 各模块"实际消耗量"(自有+兑换到手,已扣除补不齐部分)：供 CostPreviewPopup 展示实际会消耗什么
        LevelActualMap = {},
        GradeActualMap = {},
        SkillActualMap = {},
        ExpItemPlan = {},
        ExchangePlan = {},
        FinalCostMap = {},
        ExchangeTokenCostMap = {},
        LackMap = {},
        SkillPreviewList = {},
        PanelCostList = {},
        _SkillCache = {},
        _EnhanceCache = {},
        _ExpItems = nil,
    }
end
--region 对象池：pd 复用

--- 清空 pd 所有子表/数组并更新入参
local function ResetPd(pd, args)
    ClearTable(pd.DirectCostMap)
    ClearTable(pd.LevelCostMap)
    ClearTable(pd.GradeCostMap)
    ClearTable(pd.SkillCostMap)
    ClearTable(pd.LevelActualMap)
    ClearTable(pd.GradeActualMap)
    ClearTable(pd.SkillActualMap)
    ClearTable(pd.ExpItemPlan)
    ClearTable(pd.ExchangePlan)
    ClearTable(pd.FinalCostMap)
    ClearTable(pd.ExchangeTokenCostMap)
    ClearTable(pd.LackMap)
    ClearArray(pd.SkillPreviewList)
    ClearArray(pd.PanelCostList)
    ClearArray(pd._SkillCache)
    ClearArray(pd._EnhanceCache)
    pd._ExpItems = nil
    if args then
        pd.CharacterId = args.CharacterId
        pd.TargetLevel = args.TargetLevel
        pd.TargetGrade = args.TargetGrade
        pd.SkillTargetLevel = args.SkillTargetLevel
        pd.IncludeEnhance = args.IncludeEnhance
        pd.AutoExchange = args.AutoExchange
    end
end

--- 创建 pd 池：首次新建，后续 ResetPd 复用
local function MakePdPool()
    local pd = nil
    return function(control, args)
        if not pd then
            pd = control:_NewRoleCultureWork(args)
        else
            ResetPd(pd, args)
        end
        return pd
    end
end

-- CalcRoleCulturePreview 专用
local AcquirePreviewPd = MakePdPool()
-- 临时计算专用（IsSkillMaxNoCost / CheckRoleCultureHasAnyUpgradable / CalcRoleCultureAutoAllocate）
local AcquireTempPd = MakePdPool()

--endregion

--- 计算一键培养预览
---@param args XRoleCultureCalcArgs
---@return XRoleCultureResult
function XCharacterControl:CalcRoleCulturePreview(args)
    local pd = AcquirePreviewPd(self, args)
    self:_BuildRoleCultureSkillCache(pd)

    self:_CalcRoleCultureLevelCost(pd, pd.TargetLevel, pd.LevelCostMap, pd.ExpItemPlan)
    self:_CalcRoleCultureGradeCost(pd, pd.TargetGrade, pd.GradeCostMap)
    self:_CalcRoleCultureSkillCost(pd, pd.SkillTargetLevel, pd.IncludeEnhance, pd.SkillCostMap)

    -- 按 等级→晋升→技能 顺序分配：自有库存+代币预算(如螺母)前置模块优先占用。
    -- 勾选兑换时允许兑换补足;不勾选时只按顺序分配自有。
    -- 只影响 ExchangePlan/LackMap/各模块 ActualMap(实际消耗),不改需求量(CostMap)
    self:_ComputeRoleCultureExchangePlan({
        { ModuleKey = MODULE_LEVEL, CostMap = pd.LevelCostMap, ActualMap = pd.LevelActualMap },
        { ModuleKey = MODULE_GRADE, CostMap = pd.GradeCostMap, ActualMap = pd.GradeActualMap },
        { ModuleKey = MODULE_SKILL, CostMap = pd.SkillCostMap, ActualMap = pd.SkillActualMap },
    }, pd.ExchangePlan, pd.LackMap, pd.AutoExchange, pd.ExchangeTokenCostMap)

    -- 合并三模块到 DirectCostMap / FinalCostMap(真实需求量,供主界面消耗栏与判空)
    self:_MergeRoleCultureModuleCost(pd)
    for itemId, count in pairs(pd.DirectCostMap) do
        pd.FinalCostMap[itemId] = count
    end

    self:_BuildRoleCultureSkillPreview(pd)
    self:_BuildRoleCulturePanelCostList(pd)

    -- 各步进器可达上限
    pd.MaxSkillLevel = self:_GetRoleCultureMaxSkillLevel(pd)
    pd.MaxReachableLevel = self:_CalcRoleCultureMaxLevel(pd)
    pd.MaxReachableGrade = self:_CalcRoleCultureMaxGrade(pd)
    pd.MaxReachableSkillLevel = self:_CalcRoleCultureMaxSkillLevel(pd)
    pd.FreeSkillLevel = self:_GetRoleCultureFreeSkillLevel(pd)
    pd.IsGradeMaterialLack = self:_IsRoleCultureModuleMaterialLack(pd.GradeCostMap, pd.GradeActualMap)

    return pd
end

--- 模块材料是否不足
---@param costMap table<number, number> 模块需求
---@param actualMap table<number, number> 模块实际可用量
---@return boolean
function XCharacterControl:_IsRoleCultureModuleMaterialLack(costMap, actualMap)
    for itemId, count in pairs(costMap) do
        if (actualMap[itemId] or 0) < count then
            return true
        end
    end
    return false
end

--- 技能步进器上限：当前选定条件下所有技能中最高可达等级
--- 每个技能受条件上限（如角色等级类条件 type=13103）约束，取 min(MaxLv, condCap) 后再取最大
function XCharacterControl:_GetRoleCultureMaxSkillLevel(pd)
    local maxLevel = 0
    local characterId = pd.CharacterId
    for i = 1, #pd._SkillCache do
        local s = pd._SkillCache[i]
        if not s.IsLiberation then
            local condCap = self:_GetNormalSkillConditionCap(s.SubSkillId, characterId, s.CurLv, s.MaxLv, pd.TargetLevel)
            maxLevel = math.max(maxLevel, math.min(s.MaxLv, condCap))
        end
    end
    if pd.IncludeEnhance then
        for i = 1, #pd._EnhanceCache do
            local e = pd._EnhanceCache[i]
            local condCap = self:_GetEnhanceSkillConditionCap(e, characterId, e.CurLv, e.MaxLv, pd.TargetLevel)
            maxLevel = math.max(maxLevel, math.min(e.MaxLv, condCap))
        end
    end
    return maxLevel
end

--- 技能免费上限：目标设到该等级不产生任何消耗
function XCharacterControl:_GetRoleCultureFreeSkillLevel(pd)
    local maxLevel = pd.MaxSkillLevel or 0
    local tempCost = {}
    for level = 0, maxLevel do
        ClearTable(tempCost)
        self:_CalcRoleCultureSkillCost(pd, level, pd.IncludeEnhance, tempCost)
        if next(tempCost) ~= nil then
            return level - 1
        end
    end
    return maxLevel
end

function XCharacterControl:_BuildRoleCultureSkillCache(pd)
    ClearArray(pd._SkillCache)
    ClearArray(pd._EnhanceCache)

    local agency = self:GetAgency()
    local characterId = pd.CharacterId
    local character = agency:GetCharacter(characterId)
    -- GetCharacterSkills高消耗，故做缓存
    local skills
    if _CachedSkillsCharId == characterId and _CachedSkillsGrade == character.Grade and _CachedSkills then
        skills = _CachedSkills
    else
        skills = agency:GetCharacterSkills(characterId)
        _CachedSkillsCharId = characterId
        _CachedSkillsGrade = character.Grade
        _CachedSkills = skills
    end
    -- 终阶解放技能是切换类技能（非升级类），不纳入培养消耗/上限，但仍展示当前真实状态
    local maxLiberationGroupId = agency:GetCharMaxLiberationSkillGroupId(characterId)
    for pos = 1, XEnumConst.CHARACTER.MAX_SHOW_SKILL_POS do
        local skill = skills[pos]
        if skill and skill.subSkills then
            for i, subSkill in ipairs(skill.subSkills) do
                local groupId = agency:GetSkillGroupIdAndIndex(subSkill.SubSkillId)
                local minMax = agency:GetSubSkillMinMaxLevel(subSkill.SubSkillId)
                if minMax then
                    -- 当前等级实时读（不用缓存快照,避免养成后过期）
                    local curLv = character:GetSkillLevel(groupId)
                    table.insert(pd._SkillCache, {
                        Pos = pos,
                        SubSkillId = subSkill.SubSkillId,
                        CurLv = curLv,
                        MaxLv = minMax.Max,
                        IsLocked = curLv <= 0,
                        GridIndex = i,
                        IsLiberation = groupId == maxLiberationGroupId,
                    })
                end
            end
        end
    end

    if agency:CheckIsShowEnhanceSkill(characterId) then
        local groupIdList = character:GetEnhanceSkillGroupIdList() or {}
        for i, groupId in ipairs(groupIdList) do
            local group = character:GetEnhanceSkillGroupData(groupId)
            if group then
                table.insert(pd._EnhanceCache, {
                    GroupId = groupId,
                    SkillId = group:GetActiveSkillId(),
                    CurLv = group:GetLevel(),
                    MaxLv = group:GetMaxLevel() or 0,
                    IsUnlock = group:GetIsUnLock(),
                    Group = group,
                    GridIndex = i,
                })
            end
        end
    end
end

function XCharacterControl:_BuildRoleCultureSkillPreview(pd)
    ClearArray(pd.SkillPreviewList)
    local targetLevel = pd.SkillTargetLevel
    local characterId = pd.CharacterId
    local curFull, previewFull, total = 0, 0, 0

    -- 普通技能
    for i = 1, #pd._SkillCache do
        local s = pd._SkillCache[i]
        local preview
        if s.IsLiberation then
            -- 终阶解放技能不可升级：计入展示总数，已解锁即视为已满，不参与升级预览统计
            preview = s.CurLv
            total = total + 1
            if not s.IsLocked then
                curFull = curFull + 1
            end
        else
            total = total + 1
            local condCap = self:_GetNormalSkillConditionCap(s.SubSkillId, characterId, s.CurLv, s.MaxLv, pd.TargetLevel)
            preview = math.max(s.CurLv, math.min(targetLevel, condCap))
            if s.CurLv >= s.MaxLv then
                curFull = curFull + 1
            elseif preview >= s.MaxLv then
                previewFull = previewFull + 1
            end
        end
        table.insert(pd.SkillPreviewList, {
            IsEnhance = false,
            Pos = s.Pos,
            SubSkillId = s.SubSkillId,
            PreviewLv = preview,
            GridIndex = s.GridIndex,
        })
    end

    -- 跃升/独域（未勾选包含时目标视为不变；条件不满足的等级不可达）
    local enhanceTarget = pd.IncludeEnhance and targetLevel or 0
    for i = 1, #pd._EnhanceCache do
        local e = pd._EnhanceCache[i]
        total = total + 1
        local condCap = self:_GetEnhanceSkillConditionCap(e, characterId, e.CurLv, e.MaxLv, pd.TargetLevel)
        local preview = math.max(e.CurLv, math.min(enhanceTarget, condCap))
        if e.CurLv >= e.MaxLv then
            curFull = curFull + 1
        elseif preview >= e.MaxLv then
            previewFull = previewFull + 1
        end
        table.insert(pd.SkillPreviewList, {
            IsEnhance = true,
            GroupId = e.GroupId,
            SkillId = e.SkillId,
            PreviewLv = preview,
            GridIndex = e.GridIndex,
        })
    end

    pd.MaxFullSkillCur = curFull
    pd.MaxFullSkillAdd = previewFull
    pd.MaxFullSkillTotal = total
end

--- 强化按钮上方资源条
function XCharacterControl:_BuildRoleCulturePanelCostList(pd)
    ClearArray(pd.PanelCostList)

    local added = {}
    local function add(itemId)
        if not itemId or added[itemId] then
            return
        end
        local count = (pd.FinalCostMap[itemId] or 0) + (pd.ExchangeTokenCostMap[itemId] or 0)
        if count > 0 then
            added[itemId] = true
            local isEnough = (pd.LackMap[itemId] or 0) <= 0
            table.insert(pd.PanelCostList, { Id = itemId, Count = count, IsEnough = isEnough })
        end
    end

    add(XDataCenter.ItemManager.ItemId.Coin)
    add(XDataCenter.ItemManager.ItemId.SkillPoint)
    add(XDataCenter.ItemManager.ItemId.LeapWaferChip)
    add(XDataCenter.ItemManager.ItemId.SoloDomainCrystal)
    add(XDataCenter.ItemManager.ItemId.RepeatChallengeCoin)
end

--endregion

--region 三类消耗计算

--- 升级消耗：大经验优先
function XCharacterControl:_CalcRoleCultureLevelCost(pd, targetLevel, costMap, planOut)
    local agency = self:GetAgency()
    local character = agency:GetCharacter(pd.CharacterId)
    if targetLevel <= character.Level then
        return true
    end

    local characterId = pd.CharacterId
    local needExp = -character.Exp
    for level = character.Level, targetLevel - 1 do
        needExp = needExp + agency:GetNextLevelExp(characterId, level)
    end
    if needExp <= 0 then
        return true
    end

    local expItems = self:_GetRoleCultureExpItemList(pd)
    for i = 1, #expItems do
        local item = expItems[i]
        local own = XDataCenter.ItemManager.GetCount(item.Id)
        local use = math.min(own, math.floor(needExp / item.Exp))
        if use > 0 then
            planOut[item.Id] = (planOut[item.Id] or 0) + use
            AddCost(costMap, item.Id, use)
            needExp = needExp - use * item.Exp
        end
    end
    
    if needExp > 0 then
        for i = #expItems, 1, -1 do
            local item = expItems[i]
            local used = planOut[item.Id] or 0
            if XDataCenter.ItemManager.GetCount(item.Id) - used > 0 then
                planOut[item.Id] = used + 1
                AddCost(costMap, item.Id, 1)
                needExp = needExp - item.Exp
                if needExp <= 0 then
                    break
                end
            end
        end
    end

    -- 自有道具不足：剩余缺口折算成需补充的经验道具
    if needExp > 0 and expItems[1] then
        -- 筛出配了兑换的道具子集（expItems 按经验降序）
        local exchangeable = {}
        for i = 1, #expItems do
            if XItemConfigs.GetItemAutoExchangeById(expItems[i].Id) then
                table.insert(exchangeable, expItems[i])
            end
        end
        -- 有配了兑换的道具 → 只在子集里选基准；否则用全量（会进 LackMap 表示缺料）
        local basis = #exchangeable > 0 and exchangeable or expItems

        -- 从最小往前找第一个单个经验 >= 缺口的道具
        local pick = nil
        for i = #basis, 1, -1 do
            if basis[i].Exp >= needExp then
                pick = basis[i]
                break
            end
        end
        if pick then
            planOut[pick.Id] = (planOut[pick.Id] or 0) + 1
            AddCost(costMap, pick.Id, 1)
        else
            -- 缺口比子集最大道具还大，用子集最大道具按个数折算
            local biggest = basis[1]
            local lackCount = math.ceil(needExp / biggest.Exp)
            planOut[biggest.Id] = (planOut[biggest.Id] or 0) + lackCount
            AddCost(costMap, biggest.Id, lackCount)
        end
        return false
    end

    return needExp <= 0
end

--- 经验道具列表（本角色类型适用，按单个经验降序）
--- 取自配置全列表（不依赖持有）：没持有任何经验道具时仍能作为缺口折算基准
function XCharacterControl:_GetRoleCultureExpItemList(pd)
    if pd._ExpItems then
        return pd._ExpItems
    end
    local character = self:GetAgency():GetCharacter(pd.CharacterId)
    local items = {}
    local templates = XItemConfigs.GetItemTemplates()
    local cardExpType = XItemConfigs.ItemType.CardExp
    for itemId, tpl in pairs(templates) do
        if tpl.ItemType == cardExpType then
            local exp = XDataCenter.ItemManager.GetCharExp(itemId, character.Type)
            if exp and exp > 0 then
                table.insert(items, { Id = itemId, Exp = exp })
            end
        end
    end
    table.sort(items, function(a, b)
        return a.Exp > b.Exp
    end)
    pd._ExpItems = items
    return items
end

function XCharacterControl:_CalcRoleCultureGradeCost(pd, targetGrade, costMap)
    local agency = self:GetAgency()
    local character = agency:GetCharacter(pd.CharacterId)
    for grade = character.Grade, targetGrade - 1 do
        local gradeConfig = agency:GetGradeTemplates(pd.CharacterId, grade)
        if gradeConfig then
            local itemKey, itemCount = gradeConfig.UseItemKey, gradeConfig.UseItemCount
            if type(itemKey) == "table" then
                for i = 1, #itemKey do
                    AddCost(costMap, itemKey[i], itemCount[i])
                end
            else
                AddCost(costMap, itemKey, itemCount)
            end
        end
    end
end

--- 普通技能最大等级
function XCharacterControl:_GetNormalSkillConditionCap(subSkillId, characterId, curLv, maxLv, targetCharLv)
    local CHAR_LEVEL_CONDITION_TYPE = 13103
    local agency = self:GetAgency()
    for level = curLv, maxLv - 1 do
        local gradeConfig = agency:GetSkillGradeConfig(subSkillId, level)
        if not gradeConfig then
            return level
        end
        if not XTool.IsTableEmpty(gradeConfig.ConditionId) then
            for _, conditionId in pairs(gradeConfig.ConditionId) do
                if XTool.IsNumberValid(conditionId) then
                    local template = XConditionManager.GetConditionTemplate(conditionId)
                    if template and template.Type == CHAR_LEVEL_CONDITION_TYPE then
                        if targetCharLv < (template.Params[1] or 0) then
                            return level
                        end
                    elseif not XConditionManager.CheckCondition(conditionId, characterId) then
                        return level
                    end
                end
            end
        end
    end
    return maxLv
end

--- 跃升/独域技能最大等级
function XCharacterControl:_GetEnhanceSkillConditionCap(e, characterId, curLv, maxLv, targetCharLv)
    local CHAR_LEVEL_CONDITION_TYPE = 13103
    for level = curLv, maxLv - 1 do
        local conditions = e.Group:GetConditionList(e.SkillId, level)
        if not XTool.IsTableEmpty(conditions) then
            for _, conditionId in pairs(conditions) do
                if XTool.IsNumberValid(conditionId) then
                    local template = XConditionManager.GetConditionTemplate(conditionId)
                    if template and template.Type == CHAR_LEVEL_CONDITION_TYPE then
                        if targetCharLv < (template.Params[1] or 0) then
                            return level
                        end
                    elseif not XConditionManager.CheckCondition(conditionId, characterId) then
                        return level
                    end
                end
            end
        end
    end
    return maxLv
end

--- 技能消耗
function XCharacterControl:_CalcRoleCultureSkillCost(pd, targetLevel, includeEnhance, costMap)
    if targetLevel <= 0 then
        return
    end

    local agency = self:GetAgency()
    local characterId = pd.CharacterId
    local coinId = XDataCenter.ItemManager.ItemId.Coin
    local skillPointId = XDataCenter.ItemManager.ItemId.SkillPoint

    for i = 1, #pd._SkillCache do
        local s = pd._SkillCache[i]
        if not s.IsLiberation then
            local condCap = self:_GetNormalSkillConditionCap(s.SubSkillId, characterId, s.CurLv, s.MaxLv, pd.TargetLevel)
            local target = math.max(s.CurLv, math.min(targetLevel, condCap))
            for level = s.CurLv, target - 1 do
                local cfg = agency:GetSkillGradeConfig(s.SubSkillId, level)
                if cfg then
                    AddCost(costMap, coinId, cfg.UseCoin)
                    AddCost(costMap, skillPointId, cfg.UseSkillPoint)
                end
            end
        end
    end

    if includeEnhance then
        for i = 1, #pd._EnhanceCache do
            local e = pd._EnhanceCache[i]
            local condCap = self:_GetEnhanceSkillConditionCap(e, characterId, e.CurLv, e.MaxLv, pd.TargetLevel)
            local target = math.max(e.CurLv, math.min(targetLevel, condCap))
            for level = e.CurLv, target - 1 do
                local costList = e.Group:GetCostItemList(e.SkillId, level)
                for _, cost in pairs(costList or {}) do
                    AddCost(costMap, cost.Id, cost.Count)
                end
            end
        end
    end
end

--endregion

--region 自动兑换计算

--- 合并三模块 CostMap 到 DirectCostMap（兑换砍量后调用，得到最终总需求）
function XCharacterControl:_MergeRoleCultureModuleCost(pd)
    ClearTable(pd.DirectCostMap)
    for itemId, count in pairs(pd.LevelCostMap) do
        pd.DirectCostMap[itemId] = (pd.DirectCostMap[itemId] or 0) + count
    end
    for itemId, count in pairs(pd.GradeCostMap) do
        pd.DirectCostMap[itemId] = (pd.DirectCostMap[itemId] or 0) + count
    end
    for itemId, count in pairs(pd.SkillCostMap) do
        pd.DirectCostMap[itemId] = (pd.DirectCostMap[itemId] or 0) + count
    end
end

--- 兑换计划（按模块顺序处理 + 代币预算制）
--- @param orderedModules table[] 有序模块列表 { {ModuleKey=number, CostMap=table<itemId,count>}, ... }
---        按顺序处理：先到先占代币预算(如螺母),前置模块优先满足,后置模块只兑预算够的部分(砍到刚好够)
--- @param planOut table 兑换计划输出(每项带 Module 标记,受代币预算限制的实际兑换量)
--- @param lackOut table 兑换后仍缺(自有+实际兑换到手仍补不齐的量)
--- @param allowExchange boolean 是否允许兑换补足(勾选自动兑换为 true;false 时只按模块顺序分配自有库存)
--- @param tokenCostOut table 可选,兑换实际付出的代币消耗(itemId->count)
function XCharacterControl:_ComputeRoleCultureExchangePlan(orderedModules, planOut, lackOut, allowExchange, tokenCostOut)
    -- 跨模块共享：used(真实库存占用)、virtualOwn(兑换)、tokenBudget(代币预算,惰性初始化为真实持有)
    local virtualOwn, used, tokenBudget = {}, {}, {}

    for _, moduleData in ipairs(orderedModules) do
        local moduleKey = moduleData.ModuleKey
        local costMap = moduleData.CostMap
        local actualMap = moduleData.ActualMap
        for itemId, count in pairs(costMap) do
            local lack = self:_CalcRoleCultureRealLack(used, virtualOwn, itemId, count)
            if lack > 0 and allowExchange then
                lack = self:_TryRoleCultureAutoExchange(itemId, lack, planOut, virtualOwn, tokenBudget, moduleKey, tokenCostOut)
            end
            if lack > 0 then
                lackOut[itemId] = (lackOut[itemId] or 0) + lack
            end
            if actualMap then
                local actual = count - lack
                if actual > 0 then
                    actualMap[itemId] = (actualMap[itemId] or 0) + actual
                end
            end
        end
    end
end

--- 扣除库存占用与已计划兑换量后的真实缺口
function XCharacterControl:_CalcRoleCultureRealLack(used, virtualOwn, itemId, count)
    local own = XDataCenter.ItemManager.GetCount(itemId) - (used[itemId] or 0)
    if own < 0 then
        own = 0
    end
    local fromOwn = math.min(own, count)
    used[itemId] = (used[itemId] or 0) + fromOwn
    local remain = count - fromOwn
    local virtual = virtualOwn[itemId] or 0
    local fromVirtual = math.min(virtual, remain)
    virtualOwn[itemId] = virtual - fromVirtual
    return remain - fromVirtual
end

--- 自动兑换来源：ItemAutoExchange.tab
--- 预拉取后 ShopDict 有数据就能查到；查不到返回 nil 静默跳过
--- @param tokenBudget table 代币预算(itemId->剩余可用量)
--- @param moduleKey number 该兑换归属模块(1等级/2晋升/3技能),写入 planOut 便于按模块顺序展示
--- @param tokenCostOut table 可选,累计本次兑换实际付出的代币(itemId->count)
function XCharacterControl:_TryRoleCultureAutoExchange(itemId, lack, planOut, virtualOwn, tokenBudget, moduleKey, tokenCostOut)
    local cfg = XItemConfigs.GetItemAutoExchangeById(itemId)
    if not cfg then
        return lack
    end
    local info = XShopManager.GetGoodsExchangeInfo(itemId, cfg.ShopId, cfg.GoodsId)
    if not info or not info.RewardCount or info.RewardCount <= 0 then
        return lack
    end

    local leftTimes = math.huge
    local goods = XShopManager.GetShopGoodsInfo(info.ShopId, info.GoodsId)
    if goods and XTool.IsNumberValid(goods.BuyTimesLimit) then
        leftTimes = goods.BuyTimesLimit - (goods.TotalBuyTimes or 0)
    end

    local buyCount = math.min(math.ceil(lack / info.RewardCount), leftTimes)

    -- 代币预算限制：每种消耗代币按剩余预算算最多能买几次,取最小(砍到刚好够)
    for _, consume in ipairs(info.ConsumeList or table.empty) do
        local budget = tokenBudget[consume.ConsumeId]
        if budget == nil then
            budget = XDataCenter.ItemManager.GetCount(consume.ConsumeId)
            tokenBudget[consume.ConsumeId] = budget
        end
        if consume.ConsumeCount > 0 then
            buyCount = math.min(buyCount, math.floor(budget / consume.ConsumeCount))
        end
    end

    if buyCount <= 0 then
        return lack
    end

    for _, consume in ipairs(info.ConsumeList or table.empty) do
        local cost = consume.ConsumeCount * buyCount
        tokenBudget[consume.ConsumeId] = tokenBudget[consume.ConsumeId] - cost
        if tokenCostOut then
            tokenCostOut[consume.ConsumeId] = (tokenCostOut[consume.ConsumeId] or 0) + cost
        end
    end

    table.insert(planOut, {
        ShopId = info.ShopId,
        GoodsId = info.GoodsId,
        ItemId = itemId,
        Count = buyCount,
        Module = moduleKey,
    })

    local gained = buyCount * info.RewardCount
    local usedNow = math.min(gained, lack)
    virtualOwn[itemId] = (virtualOwn[itemId] or 0) + gained - usedNow
    return lack - usedNow
end

--endregion

--region 可达上限与一键分配

--- 校验一组消耗是否可负担
function XCharacterControl:_CheckRoleCultureAffordable(pd, costMap)
    if not pd.AutoExchange then
        for itemId, count in pairs(costMap) do
            if XDataCenter.ItemManager.GetCount(itemId) < count then
                return false
            end
        end
        return true
    end

    local lack = {}
    self:_ComputeRoleCultureExchangePlan({ { ModuleKey = MODULE_LEVEL, CostMap = costMap } }, {}, lack, true)
    return not next(lack)
end

--- 可否负担消耗
function XCharacterControl:CheckRoleCultureTotalAffordable(pd, targetLevel, targetGrade, skillTarget)
    local cost, plan = {}, {}
    self:_CalcRoleCultureLevelCost(pd, targetLevel, cost, plan)
    self:_CalcRoleCultureGradeCost(pd, targetGrade, cost)
    self:_CalcRoleCultureSkillCost(pd, skillTarget, pd.IncludeEnhance, cost)
    return self:_CheckRoleCultureAffordable(pd, cost)
end

--- 等级可达上限
function XCharacterControl:_CalcRoleCultureMaxLevel(pd)
    local agency = self:GetAgency()
    local character = agency:GetCharacter(pd.CharacterId)
    local low, high = character.Level, agency:GetMaxAvailableLevel(pd.CharacterId)
    while low < high do
        local mid = math.ceil((low + high + 1) / 2)
        if self:CheckRoleCultureTotalAffordable(pd, mid, character.Grade, 0) then
            low = mid
        else
            high = mid - 1
        end
    end
    return low
end

--- 晋升可达上限（仅受角色等级等非材料条件约束，材料不足不再阻断上限）
function XCharacterControl:_CalcRoleCultureMaxGrade(pd)
    local agency = self:GetAgency()
    local character = agency:GetCharacter(pd.CharacterId)
    local reachable = character.Grade
    for grade = character.Grade + 1, agency:GetCharMaxGrade(pd.CharacterId) do
        local gradeConfig = agency:GetGradeTemplates(pd.CharacterId, grade - 1)
        if not gradeConfig or not self:_CheckRoleCultureGradeCondition(pd, gradeConfig) then
            break
        end
        reachable = grade
    end
    return reachable
end

--- 晋升条件检查
function XCharacterControl:_CheckRoleCultureGradeCondition(pd, gradeConfig)
    local conditions = gradeConfig.ConditionId
    if XTool.IsTableEmpty(conditions) then
        return true
    end
    -- 角色等级条件（type=13103）
    local CHAR_LEVEL_CONDITION_TYPE = 13103
    for _, conditionId in pairs(conditions) do
        if XTool.IsNumberValid(conditionId) then
            local template = XConditionManager.GetConditionTemplate(conditionId)
            if template and template.Type == CHAR_LEVEL_CONDITION_TYPE then
                if pd.TargetLevel < (template.Params[1] or 0) then
                    return false
                end
            elseif not XConditionManager.CheckCondition(conditionId, pd.CharacterId) then
                return false
            end
        end
    end
    return true
end

--- 技能可达目标等级
function XCharacterControl:_CalcRoleCultureMaxSkillLevel(pd)
    local maxLevel = self:_GetRoleCultureMaxSkillLevel(pd)
    local reachable = 0
    for target = 1, maxLevel do
        if not self:CheckRoleCultureTotalAffordable(pd, pd.TargetLevel, pd.TargetGrade, target) then
            break
        end
        reachable = target
    end
    return reachable
end

--- 一键分配：等级 → 晋升 → 技能
---@param args XRoleCultureCalcArgs
function XCharacterControl:CalcRoleCultureAutoAllocate(args)
    local agency = self:GetAgency()
    local pd = AcquireTempPd(self, args)
    pd.IncludeEnhance = args.IncludeEnhance ~= false
    self:_BuildRoleCultureSkillCache(pd)
    local character = agency:GetCharacter(pd.CharacterId)

    -- 等级拉满
    local low, high = character.Level, agency:GetMaxAvailableLevel(pd.CharacterId)
    while low < high do
        local mid = math.ceil((low + high + 1) / 2)
        if self:CheckRoleCultureTotalAffordable(pd, mid, character.Grade, 0) then
            low = mid
        else
            high = mid - 1
        end
    end
    pd.TargetLevel = low

    -- 晋升逐级
    local grade = character.Grade
    for g = character.Grade + 1, agency:GetCharMaxGrade(pd.CharacterId) do
        local gradeConfig = agency:GetGradeTemplates(pd.CharacterId, g - 1)
        if not gradeConfig or not self:_CheckRoleCultureGradeCondition(pd, gradeConfig) then
            break
        end
        if not self:CheckRoleCultureTotalAffordable(pd, pd.TargetLevel, g, 0) then
            break
        end
        grade = g
    end
    pd.TargetGrade = grade

    -- 技能目标等级
    local skillTarget = 0
    for target = 1, self:_GetRoleCultureMaxSkillLevel(pd) do
        if not self:CheckRoleCultureTotalAffordable(pd, pd.TargetLevel, pd.TargetGrade, target) then
            break
        end
        skillTarget = target
    end

    return pd.TargetLevel, pd.TargetGrade, skillTarget
end

--- 是否还有任何可提升点（等级/晋升未封顶，或任一技能 CurLv<条件上限）
---@param args XRoleCultureCalcArgs
---@param includeEnhance boolean 是否把跃升/独域技能算进来（特训不提升它们，传 false）
function XCharacterControl:CheckRoleCultureHasAnyUpgradable(args, includeEnhance)
    local agency = self:GetAgency()
    local characterId = args.CharacterId
    local character = agency:GetCharacter(characterId)

    if character.Level < agency:GetMaxAvailableLevel(characterId) then
        return true
    end
    if character.Grade < agency:GetCharMaxGrade(characterId) then
        return true
    end

    local pd = AcquireTempPd(self, args)
    self:_BuildRoleCultureSkillCache(pd)

    for i = 1, #pd._SkillCache do
        local s = pd._SkillCache[i]
        if not s.IsLiberation then
            local condCap = self:_GetNormalSkillConditionCap(s.SubSkillId, characterId, s.CurLv, s.MaxLv, pd.TargetLevel)
            if s.CurLv < condCap then
                return true
            end
        end
    end
    if includeEnhance then
        for i = 1, #pd._EnhanceCache do
            local e = pd._EnhanceCache[i]
            local condCap = self:_GetEnhanceSkillConditionCap(e, characterId, e.CurLv, e.MaxLv, pd.TargetLevel)
            if e.CurLv < condCap then
                return true
            end
        end
    end
    return false
end

local _CurStateArgs = {}

function XCharacterControl:CheckRoleCultureHasAnyUpgradableByCurState(characterId)
    local character = self:GetAgency():GetCharacter(characterId)
    if not character then
        return false
    end

    _CurStateArgs.CharacterId = characterId
    _CurStateArgs.TargetLevel = character.Level
    _CurStateArgs.TargetGrade = character.Grade
    _CurStateArgs.SkillTargetLevel = 0
    _CurStateArgs.IncludeEnhance = true
    _CurStateArgs.AutoExchange = false
    return self:CheckRoleCultureHasAnyUpgradable(_CurStateArgs, true)
end



--region 步进器辅助

--- 判断当前角色等级下，技能可达最高等级是否不产生材料消耗（用于步进器加号禁用）
---@param args XRoleCultureCalcArgs
---@param cultureResult XRoleCultureResult
function XCharacterControl:IsSkillMaxNoCost(args, cultureResult)
    if not args then
        return true
    end
    local maxSkill = cultureResult and cultureResult.MaxSkillLevel or 0
    if maxSkill <= 0 then
        return true
    end

    local pd = AcquireTempPd(self, args)
    pd.SkillTargetLevel = maxSkill
    self:_BuildRoleCultureSkillCache(pd)
    ClearTable(pd.SkillCostMap)
    self:_CalcRoleCultureSkillCost(pd, maxSkill, args.IncludeEnhance, pd.SkillCostMap)
    return XTool.IsTableEmpty(pd.SkillCostMap)
end

local _LightArgs = {}

--- 轻量计算：只算当前角色等级下的技能等级上限（不算材料/消耗）
---@param characterId number
---@param targetLevel number
---@return number maxSkillLevel
function XCharacterControl:CalcMaxSkillLevel(characterId, targetLevel)
    _LightArgs.CharacterId = characterId
    _LightArgs.TargetLevel = targetLevel
    local pd = AcquireTempPd(self, _LightArgs)
    self:_BuildRoleCultureSkillCache(pd)
    return self:_GetRoleCultureMaxSkillLevel(pd)
end

--- 轻量计算：只构建技能预览（不计材料/消耗），供特训态"技能显示到满级"
---@param args XRoleCultureCalcArgs { CharacterId, TargetLevel, SkillTargetLevel, IncludeEnhance }
---@return table skillPreviewList, number curFull, number addFull, number total
function XCharacterControl:CalcRoleCultureSkillPreviewOnly(args)
    local pd = AcquireTempPd(self, args)
    self:_BuildRoleCultureSkillCache(pd)
    self:_BuildRoleCultureSkillPreview(pd)

    local src = pd.SkillPreviewList
    local list = {}
    for i = 1, #src do
        list[i] = src[i]
    end
    return list, pd.MaxFullSkillCur, pd.MaxFullSkillAdd, pd.MaxFullSkillTotal
end

--- 轻量计算：只算当前角色等级下的晋升条件上限（不算材料/消耗）
---@param characterId number
---@param targetLevel number
---@return number maxReachableGrade
function XCharacterControl:CalcMaxReachableGrade(characterId, targetLevel)
    _LightArgs.CharacterId = characterId
    _LightArgs.TargetLevel = targetLevel
    local pd = AcquireTempPd(self, _LightArgs)
    return self:_CalcRoleCultureMaxGrade(pd)
end

--endregion
return XCharacterControl
