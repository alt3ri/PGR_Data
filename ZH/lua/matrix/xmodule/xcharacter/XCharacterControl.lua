---@class XCharacterControl : XControl
---@field _Model XCharacterModel
local XCharacterControl = XClass(XControl, "XCharacterControl", true)

-- 一键培养计算区（预览/消耗/兑换/可达上限/一键分配）拆分为分部类，见下方 require 文件
XClassPartialRequire("XModule/XCharacter/XCharacterControlRoleCultureCalc", "XCharacterControl")

function XCharacterControl:OnInit()
    --初始化内部变量
end

-------- 优化拆分到Control的表 begin
function XCharacterControl:GetCharGraphTemplate(graphId)
    local template = self._Model:GetCharacterGraph()[graphId]
    if not template then
        XLog.Error("CharacterGraph.tab not found id ", graphId)
        return
    end
    return template
end

-- 获得当前品质的各个star的进化表演阶段
---@return table
function XCharacterControl:GetCharacterSkillQualityBigEffectBallPerformArea(quality)
    local config = self:GetModelCharacterSkillQualityBigEffectBall()[quality]
    if XTool.IsTableEmpty(config) then
        XLog.Error("CharacterSkillQualityBigEffectBall.tab not found quality ", quality)
        return
    end

    local res = {}
    for k, areaStr in pairs(config.PerformArea) do
        local areaTable = string.Split(areaStr, '|')
        -- 把area做成table 且转换为number
        for j, v in pairs(areaTable) do
            areaTable[j] = tonumber(v)
        end
        res[k] = areaTable
    end

    return res
end

-- 根据角色获得当前其处在哪个表演阶段
function XCharacterControl:GetCharQualityPerformArea(charId, quality)
    local char = self:GetAgency():GetCharacter(charId)
    if not char then
        return
    end

    local allAreas = self:GetCharacterSkillQualityBigEffectBallPerformArea(quality)
    local curQualityState = self:GetAgency():GetQualityState(charId, quality)
    if curQualityState == XEnumConst.CHARACTER.QualityState.ActiveFinish then
        return #allAreas -- 最大阶段
    end

    if curQualityState == XEnumConst.CHARACTER.QualityState.Lock then
        return XEnumConst.CHARACTER.PerformState.One
    end

    local star = char.Star
    for k, area in pairs(allAreas) do
        local areaMin = area[1]
        local areaMax = area[2]
        if star >= areaMin and star <= areaMax then
            return k
        end 
    end
end

-- 获取核心切换技能的描述
function XCharacterControl:GetCharacterSkillExchangeDesBySkillIdAndLevel(skillId, skillLevel)
    local levelString = (skillLevel >= 10) and skillLevel or ("0"..skillLevel)
    local targetId = tonumber((skillId *100)..levelString)
    return self:GetModelCharacterSkillExchangeDes()[targetId]
end

-- 部分拆分的直接get的表
function XCharacterControl:GetModelCharacterSkillQualityBigEffectBall()
    return self._Model:GetCharacterSkillQualityBigEffectBall()
end

function XCharacterControl:GetModelCharacterSkillExchangeDes()
    return self._Model:GetCharacterSkillExchangeDes()
end
--

-------- 优化拆分到Control的表 end

-- 协议 begin
function XCharacterControl:CharacterResetNewFlagRequest(characterIdList, cb)
    XNetwork.Call("CharacterResetNewFlagRequest", { CharacterIds = characterIdList }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb()
        end
    end)
end

function XCharacterControl:CharacterSetCollectStateRequest(characterId, collectState, cb)
    local char = XMVCA.XCharacter:GetCharacter(characterId)
    if not char then
        return
    end

    if collectState == char.CollectState then
        return
    end

    XNetwork.Call("CharacterSetCollectStateRequest", { CharacterId = characterId, CollectState = collectState }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb()
        end
    end)
end

function XCharacterControl:CharacterEnhanceSkillNoticeRequest(characterId, cb)
    local char = XMVCA.XCharacter:GetCharacter(characterId)
    if not char then
        return
    end

    XNetwork.Call("CharacterEnhanceSkillNoticeRequest", { CharacterId = characterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        if cb then
            cb()
        end
    end)
end
-- 协议 end

-------- 一键养成

local CULTURE_STEP_TIMEOUT = 15000 -- 超时时间
local SPECIAL_TRAINING_ITEM_ID = 30000

--region 一键养成本地设置

--- 取角色一键养成自动兑换开关（本地存档，无则默认开）
---@return boolean
function XCharacterControl:GetRoleCultureAutoExchange()
    return self._Model:GetRoleCultureAutoExchange()
end

--- 存角色一键养成自动兑换开关
---@param value boolean
function XCharacterControl:SetRoleCultureAutoExchange(value)
    self._Model:SetRoleCultureAutoExchange(value)
end

--endregion

--region 强化执行串行链

---一键强化唯一入口（除了一键养成道具以外的）
---@param pd XRoleCultureResult
function XCharacterControl:RunRoleCultureExecute(pd, callbacks)
    if self._CultureRunning then
        return
    end
    if next(pd.LackMap) then
        XUiManager.TipText("RoleCultureItemNotEnough")
        return
    end

    self._CultureCallbacks = callbacks or {}
    self._CultureRunning = true
    self._CulturePd = pd
    self._CultureQueue = self:_BuildRoleCultureQueue(pd)
    self._CultureStepIndex = 0
    -- 多步串行执行会收到大量任务推送，压住逐条派发，链结束时统一派发一次
    XDataCenter.TaskManager.CloseSyncTasksEvent()
    self:_NextRoleCultureStep()
end

---@param pd XRoleCultureResult
function XCharacterControl:_BuildRoleCultureQueue(pd)
    local queue = {}

    -- 兑换/开箱前置
    local exchangeSteps = {}
    self:_BuildRoleCultureExchangeSteps(pd, exchangeSteps)
    for i = 1, #exchangeSteps do
        table.insert(queue, { Fn = exchangeSteps[i] })
    end

    -- 三阶段强化
    local function appendPhase(phaseKey, buildFunc)
        local steps = {}
        buildFunc(self, pd, steps)
        if #steps == 0 then
            return
        end
        table.insert(queue, { Phase = phaseKey })
        for i = 1, #steps do
            table.insert(queue, { Fn = steps[i] })
        end
    end

    appendPhase("Level", self._BuildRoleCultureLevelSteps)
    appendPhase("Grade", self._BuildRoleCultureGradeSteps)
    appendPhase("Skill", self._BuildRoleCultureSkillSteps)

    return queue
end

--- 本次参与的养成模块列表。兑换/开箱不算独立模块，不在列表中
---@param pd XRoleCultureResult
function XCharacterControl:GetRoleCultureUnits(pd)
    local agency = self:GetAgency()
    local nameTextKey = { Level = "RoleCultureUnitLevel", Grade = "RoleCultureUnitGrade", Skill = "RoleCultureUnitSkill" }
    local targetTextGetter = {
        Level = function() return CS.XTextManager.GetText("RoleCultureUnitLevelTarget", pd.TargetLevel) end,
        Grade = function() return agency:GetCharGradeName(pd.CharacterId, pd.TargetGrade) end,
        Skill = function() return CS.XTextManager.GetText("RoleCultureUnitSkillTarget", pd.SkillTargetLevel) end,
    }

    local units = {}
    local queue = self:_BuildRoleCultureQueue(pd)
    for i = 1, #queue do
        local phase = queue[i].Phase
        if phase then
            local unit = {
                Key = phase,
                Name = CS.XTextManager.GetText(nameTextKey[phase]),
                Target = targetTextGetter[phase](),
            }
            if phase == "Grade" then
                -- 晋升模块用星级展示（PanelUpGrade），额外提供渲染所需数据
                unit.CharacterId = pd.CharacterId
                unit.GradeValue = pd.TargetGrade
            end
            table.insert(units, unit)
        end
    end
    return units
end

--- 构造消耗预览弹窗所需的数据(按等级/晋升/技能分三块)
function XCharacterControl:BuildCultureCostPreviewData(result)
    -- 1) 汇总每个产出道具的兑换项（ExchangePlan 可能多次兑换同一道具，合并购买次数 Times）
    local exchangePlanMap = {} -- itemId -> {Plan, Info, Times}
    for _, plan in ipairs(result.ExchangePlan or table.empty) do
        local info = XShopManager.GetGoodsExchangeInfo(plan.ItemId, plan.ShopId, plan.GoodsId)
        if info and info.RewardCount then
            if not exchangePlanMap[plan.ItemId] then
                exchangePlanMap[plan.ItemId] = { Plan = plan, Info = info, Times = 0 }
            end
            exchangePlanMap[plan.ItemId].Times = exchangePlanMap[plan.ItemId].Times + plan.Count
        end
    end

    -- 2) 按模块拆 CostList：用"实际消耗量"(自有+兑换到手,已扣除补不齐部分)拆自有/兑换两行
    --    补不齐的量不在 actualMap 里,天然不显示
    --    ownUsed 跨模块累减真实持有：同一材料(如螺母)被多模块消耗时,自有优先给前面模块(等级>晋升>技能),不重叠
    local ownUsed = {}
    local function BuildSectionCostList(moduleActualMap)
        local costList = {}
        for itemId, actualCount in pairs(moduleActualMap or table.empty) do
            local ownLeft = XDataCenter.ItemManager.GetCount(itemId) - (ownUsed[itemId] or 0)
            if ownLeft < 0 then
                ownLeft = 0
            end
            local ownCount = math.min(actualCount, ownLeft)
            ownUsed[itemId] = (ownUsed[itemId] or 0) + ownCount
            if ownCount > 0 then
                table.insert(costList, { Id = itemId, Count = ownCount, IsExchange = false })
            end
            local exchangeCount = actualCount - ownCount
            if exchangeCount > 0 then
                table.insert(costList, { Id = itemId, Count = exchangeCount, IsExchange = true })
            end
        end
        return costList
    end

    local sections = {}
    if not XTool.IsTableEmpty(result.LevelActualMap) then
        table.insert(sections, { Title = CS.XTextManager.GetText("RoleCultureUnitLevel"), CostList = BuildSectionCostList(result.LevelActualMap) })
    end
    if not XTool.IsTableEmpty(result.GradeActualMap) then
        table.insert(sections, { Title = CS.XTextManager.GetText("RoleCultureUnitGrade"), CostList = BuildSectionCostList(result.GradeActualMap) })
    end
    if not XTool.IsTableEmpty(result.SkillActualMap) then
        table.insert(sections, { Title = CS.XTextManager.GetText("RoleCultureUnitSkill"), CostList = BuildSectionCostList(result.SkillActualMap) })
    end

    -- 3) ExchangeList：每项 {ItemId, RewardCount(总产出), ConsumeList(总消耗)}
    local exchangeList = {}
    for itemId, entry in pairs(exchangePlanMap) do
        local info = entry.Info
        local times = entry.Times
        local consumeList = {}
        for _, consume in ipairs(info.ConsumeList or table.empty) do
            table.insert(consumeList, {
                Id = consume.ConsumeId,
                Count = consume.ConsumeCount * times,
            })
        end
        table.insert(exchangeList, {
            ItemId = itemId,
            RewardCount = info.RewardCount * times,
            ConsumeList = consumeList,
        })
    end

    return { Sections = sections, ExchangeList = exchangeList }
end

--- 创建特训道具用过程弹窗数据结构
function XCharacterControl:GetRoleCultureSpecialTrainingUnits(characterId)
    local agency = self:GetAgency()
    local character = agency:GetCharacter(characterId)
    local maxLevel = agency:GetMaxAvailableLevel(characterId)
    local maxGrade = agency:GetCharMaxGrade(characterId)

    local units = {}
    if character.Level < maxLevel then
        table.insert(units, {
            Key = "Level",
            Name = CS.XTextManager.GetText("RoleCultureUnitLevel"),
            Target = CS.XTextManager.GetText("RoleCultureUnitLevelTarget", maxLevel),
        })
    end
    if character.Grade < maxGrade then
        table.insert(units, {
            Key = "Grade",
            Name = CS.XTextManager.GetText("RoleCultureUnitGrade"),
            Target = agency:GetCharGradeName(characterId, maxGrade),
            CharacterId = characterId,
            GradeValue = maxGrade,
        })
    end

    -- 技能：任一技能未封顶即参与（特训拉满，技能条件上限按满级算）
    local pd = self:_NewRoleCultureWork({ CharacterId = characterId, TargetLevel = maxLevel })
    self:_BuildRoleCultureSkillCache(pd)
    local skillMax = self:_GetRoleCultureMaxSkillLevel(pd)
    local hasSkillRoom = false
    for i = 1, #pd._SkillCache do
        local s = pd._SkillCache[i]
        if not s.IsLiberation and s.CurLv < s.MaxLv then
            hasSkillRoom = true
            break
        end
    end
    if not hasSkillRoom then
        for i = 1, #pd._EnhanceCache do
            if pd._EnhanceCache[i].CurLv < pd._EnhanceCache[i].MaxLv then
                hasSkillRoom = true
                break
            end
        end
    end
    if hasSkillRoom then
        table.insert(units, {
            Key = "Skill",
            Name = CS.XTextManager.GetText("RoleCultureUnitSkill"),
            Target = CS.XTextManager.GetText("RoleCultureUnitSkillTarget", skillMax),
        })
    end

    return units
end

function XCharacterControl:_BuildRoleCultureExchangeSteps(pd, steps)
    -- 兑换：ExchangePlan 逆序执行——后置轮次条目是前置轮次的货币/材料来源，必须先到账
    for i = #pd.ExchangePlan, 1, -1 do
        local plan = pd.ExchangePlan[i]
        table.insert(steps, function(onDone, onFail)
            XShopManager.BuyShop(plan.ShopId, plan.GoodsId, plan.Count, onDone, onFail)
        end)
    end
end

function XCharacterControl:_BuildRoleCultureLevelSteps(pd, steps)
    local agency = self:GetAgency()
    local characterId = pd.CharacterId
    local character = agency:GetCharacter(characterId)
    if pd.TargetLevel <= character.Level or not next(pd.ExpItemPlan) then
        return
    end
    local useItems = {}
    for itemId, count in pairs(pd.ExpItemPlan) do
        useItems[itemId] = count
    end
    table.insert(steps, function(onDone, onFail)
        if not self:_CheckRoleCultureItemsEnough(useItems) then
            onFail()
            return
        end
        agency:AddExp(characterId, useItems, onDone)
    end)
end

function XCharacterControl:_BuildRoleCultureGradeSteps(pd, steps)
    local agency = self:GetAgency()
    local characterId = pd.CharacterId
    local character = agency:GetCharacter(characterId)
    for _ = character.Grade + 1, pd.TargetGrade do
        table.insert(steps, function(onDone, onFail)
            local char = agency:GetCharacter(characterId)
            if not agency:IsPromoteGradeUseItemEnough(characterId, char.Grade) then
                onFail()
                return
            end
            agency:PromoteGrade(characterId, onDone)
        end)
    end
end

function XCharacterControl:_BuildRoleCultureSkillSteps(pd, steps)
    local agency = self:GetAgency()
    local characterId = pd.CharacterId
    if pd.SkillTargetLevel <= 0 then
        return
    end

    -- 普通技能（按技能 id 升序；0 级需先 Unlock 再 Upgrade）
    local skillList = {}
    for i = 1, #pd._SkillCache do
        local s = pd._SkillCache[i]
        if not s.IsLiberation and s.CurLv < s.MaxLv then
            table.insert(skillList, s)
        end
    end
    table.sort(skillList, function(a, b)
        return a.SubSkillId < b.SubSkillId
    end)
    for _, s in ipairs(skillList) do
        local condCap = self:_GetNormalSkillConditionCap(s.SubSkillId, characterId, s.CurLv, s.MaxLv, pd.TargetLevel)
        local target = math.max(s.CurLv, math.min(pd.SkillTargetLevel, condCap))
        if target > s.CurLv then
            local startLv = s.CurLv
            if s.IsLocked then
                table.insert(steps, function(onDone)
                    agency:UnlockSubSkill(s.SubSkillId, characterId, onDone)
                end)
                startLv = 1
            end
            local addCount = target - startLv
            if addCount > 0 then
                table.insert(steps, function(onDone)
                    agency:UpgradeSubSkillLevel(characterId, s.SubSkillId, onDone, addCount)
                end)
            end
        end
    end

    -- 跃升/独域技能（含未解锁，未解锁先 Unlock 再 Upgrade）
    if pd.IncludeEnhance then
        for i = 1, #pd._EnhanceCache do
            local e = pd._EnhanceCache[i]
            if e.CurLv < e.MaxLv then
                local condCap = self:_GetEnhanceSkillConditionCap(e, characterId, e.CurLv, e.MaxLv, pd.TargetLevel)
                local target = math.max(e.CurLv, math.min(pd.SkillTargetLevel, condCap))
                if target > e.CurLv then
                    local startLv = e.CurLv
                    if not e.IsUnlock then
                        table.insert(steps, function(onDone)
                            agency:UnlockEnhanceSkillRequest(e.GroupId, characterId, onDone)
                        end)
                        startLv = 1
                    end
                    local addCount = target - startLv
                    if addCount > 0 then
                        table.insert(steps, function(onDone)
                            agency:UpgradeEnhanceSkillRequest(e.GroupId, addCount, characterId, onDone)
                        end)
                    end
                end
            end
        end
    end
end

function XCharacterControl:_CheckRoleCultureItemsEnough(itemDict)
    for itemId, count in pairs(itemDict) do
        if XDataCenter.ItemManager.GetCount(itemId) < count then
            return false
        end
    end
    return true
end

--- 推进执行器
function XCharacterControl:_NextRoleCultureStep()
    if not self._CultureRunning then
        return
    end
    self._CultureStepIndex = self._CultureStepIndex + 1
    local item = self._CultureQueue[self._CultureStepIndex]
    if not item then
        -- 队列走完，全部完成
        self:_FinishRoleCultureExecute(true)
        return
    end

    if item.Phase then
        -- 交给弹窗塞假动画
        local onStart = self._CultureCallbacks["on" .. item.Phase .. "Start"]
        if onStart then
            onStart(handler(self, self._NextRoleCultureStep))
        else
            self:_NextRoleCultureStep()
        end
        return
    end

    -- 超时直接寄
    self:_CancelRoleCultureTimeout()
    self._CultureTimer = XScheduleManager.ScheduleOnce(function()
        self._CultureTimer = nil
        self:_FinishRoleCultureExecute(false)
    end, CULTURE_STEP_TIMEOUT)

    item.Fn(handler(self, self._NextRoleCultureStep), handler(self, self._AbortRoleCultureExecute))
end

function XCharacterControl:_AbortRoleCultureExecute()
    self:_FinishRoleCultureExecute(false) --失败也直接寄
end

function XCharacterControl:_CancelRoleCultureTimeout()
    if self._CultureTimer then
        XScheduleManager.UnSchedule(self._CultureTimer)
        self._CultureTimer = nil
    end
end

function XCharacterControl:_FinishRoleCultureExecute(isSuccess)
    if not self._CultureRunning then
        return
    end
    self._CultureRunning = false
    self._CultureQueue = nil
    self._CulturePd = nil
    self:_CancelRoleCultureTimeout()
    XDataCenter.TaskManager.OpenSyncTasksEvent()

    local callbacks = self._CultureCallbacks or table.empty
    self._CultureCallbacks = nil
    local cb = isSuccess and callbacks.onAllDone or callbacks.onAbort
    if cb then
        cb()
    end
end

--- 玩家手动中止养成
function XCharacterControl:ReleaseRoleCultureExecute()
    self:_CancelRoleCultureTimeout()
    self._CultureRunning = false
    self._CultureQueue = nil
    self._CulturePd = nil
    self._CultureCallbacks = nil
    XDataCenter.TaskManager.OpenSyncTasksEvent()
end

--region 特训道具
function XCharacterControl:GetRoleCultureSpecialItemId()
    return SPECIAL_TRAINING_ITEM_ID
end

function XCharacterControl:GetRoleCultureSpecialItemCount()
    return XDataCenter.ItemManager.GetCount(SPECIAL_TRAINING_ITEM_ID)
end

--- 特训道具单独入口
function XCharacterControl:RunRoleCultureSpecialTraining(characterId, callbacks)
    if self._CultureRunning then
        return
    end
    self._CultureCallbacks = callbacks or {}
    self._CultureRunning = true
    self._CulturePd = nil
    self._CultureQueue = {
        { Fn = function(onDone, onFail)
            self:RequestRoleCultureSpecialTraining(characterId, onDone, onFail)
        end },
    }
    self._CultureStepIndex = 0
    self:_NextRoleCultureStep()
end

--- 特训服务端请求
function XCharacterControl:RequestRoleCultureSpecialTraining(characterId, onDone, onFail)
    -- 防止拉满触发过多事件卡顿
    XDataCenter.TaskManager.CloseSyncTasksEvent()
    XNetwork.Call("CharacterUseOneClickItemRequest", { CharacterId = characterId }, function(res)
        XDataCenter.TaskManager.OpenSyncTasksEvent()
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            onFail()
            return
        end
        onDone()
    end)
end

--endregion

--endregion

-------- 一键培养（UiRoleCultureDetailMain）end

function XCharacterControl:AddAgencyEvent()
    --control在生命周期启动的时候需要对Agency及对外的Agency进行注册
end

function XCharacterControl:RemoveAgencyEvent()

end

function XCharacterControl:OnRelease()
    self:ReleaseRoleCultureExecute()
end

return XCharacterControl