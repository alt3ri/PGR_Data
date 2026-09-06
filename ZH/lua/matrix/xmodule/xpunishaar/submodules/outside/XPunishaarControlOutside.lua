--- Control部分类，此处处理关卡入口与局外数据（任务/图鉴/关卡协议）。
--- 局内商店操作见 XPunishaarGameControlShop，局内节点流程见 XPunishaarGameControlNodeFlow。
local XPunishaarControl = XClassPartial('XPunishaarControl')

local function GetCatalogTypeByMainCardType(cardType)
    local CardType = XMVCA.XPunishaar.EnumConst.CardType
    local CatalogType = XMVCA.XPunishaar.EnumConst.CatalogType

    if cardType == CardType.Character then
        return CatalogType.Character
    elseif cardType == CardType.Weapon then
        return CatalogType.Partner
    end
end

local function GetCatalogTypeBySubCardType(cardType)
    local CardType = XMVCA.XPunishaar.EnumConst.CardType
    local CatalogType = XMVCA.XPunishaar.EnumConst.CatalogType

    if cardType == CardType.Awareness then
        return CatalogType.Equip
    elseif cardType == CardType.Resonance then
        return CatalogType.Resonance
    end
end

---@param cardType number CardType.Character/CardType.Weapon
---@return table groups
---@return number unlockedCount
---@return number totalCount
---@return number percent
function XPunishaarControl:GetMainCollectionGroups(cardType)
    local groups = {
        { Size = 1, Cards = {} },
        { Size = 2, Cards = {} },
        { Size = 3, Cards = {} },
    }

    local groupMap = {
        [1] = groups[1],
        [2] = groups[2],
        [3] = groups[3],
    }

    local catalogType = GetCatalogTypeByMainCardType(cardType)
    local outsideModel = self._Model:GetOutSideModel()

    local unlockedCount = 0
    local totalCount = 0

    for _, cfg in pairs(self:GetTablePunishaarCardCfgs()) do
        local group = groupMap[cfg.Size]

        if cfg.Type == cardType and cfg.IsShow and group then
            local isUnlocked = outsideModel:IsCollectionUnlocked(
                catalogType,
                cfg.Id
            )

            group.Cards[#group.Cards + 1] = {
                Id = cfg.Id,
                Type = cfg.Type,
                Size = cfg.Size,
                Level = 1,
                IsUnlocked = isUnlocked,
                Config = cfg,
            }

            totalCount = totalCount + 1
            if isUnlocked then
                unlockedCount = unlockedCount + 1
            end
        end
    end

    for _, group in ipairs(groups) do
        table.sort(group.Cards, function(a, b)
            local orderA = a.Config.Order or 0
            local orderB = b.Config.Order or 0

            if orderA ~= orderB then
                return orderA < orderB
            end

            return a.Id < b.Id
        end)
    end

    local percent = 0
    if totalCount > 0 then
        percent = math.ceil(unlockedCount * 100 / totalCount)
    end

    return groups, unlockedCount, totalCount, percent
end

---@param cardType number Awareness/Resonance
---@return table cards
---@return number unlockedCount
---@return number totalCount
---@return number percent
function XPunishaarControl:GetSubCollectionDatas(cardType)
    local catalogType = GetCatalogTypeBySubCardType(cardType)

    if not catalogType then
        return table.empty, 0, 0, 0
    end

    local outsideModel = self._Model:GetOutSideModel()
    local cards = {}
    local unlockedCount = 0

    for _, cfg in pairs(self:GetTablePunishaarCardCfgs()) do
        if cfg.Type == cardType and cfg.IsShow then
            local isUnlocked = outsideModel:IsCollectionUnlocked(catalogType, cfg.Id)

            cards[#cards + 1] = {
                Id = cfg.Id,
                Type = cfg.Type,
                Size = cfg.Size,
                IsUnlocked = isUnlocked,
                Config = cfg,
            }

            if isUnlocked then
                unlockedCount = unlockedCount + 1
            end
        end
    end

    table.sort(cards, function(a, b)
        local orderA = a.Config.Order or 0
        local orderB = b.Config.Order or 0

        if orderA ~= orderB then
            return orderA < orderB
        end

        return a.Id < b.Id
    end)

    local totalCount = #cards
    local percent = 0

    if totalCount > 0 then
        percent = math.ceil(unlockedCount * 100 / totalCount)
    end

    return cards, unlockedCount, totalCount, percent
end

function XPunishaarControl:GetTaskDatas(index)
    local activityCfg = self:GetActivityCfg()
    if not activityCfg or XTool.IsTableEmpty(activityCfg.TaskGroupIds) then
        return table.empty
    end

    local groupId = activityCfg.TaskGroupIds[index]
    if not XTool.IsNumberValid(groupId) then
        return table.empty
    end

    local result = {}
    local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(groupId, true) or {}

    for _, data in ipairs(taskList) do
        local taskCfg = XDataCenter.TaskManager.GetTaskTemplate(data.Id)

        local totalProcess = 1
        if taskCfg and taskCfg.Result > 0 then
            totalProcess = taskCfg.Result
        end

        local taskData = {
            Id = data.Id,
            State = data.State,
            CurProcess = 0,
            TotalProcess = totalProcess,
        }

        if not XTool.IsTableEmpty(data.Schedule) then
            taskData.CurProcess = math.min(data.Schedule[1].Value or 0, totalProcess)
        end

        taskData.RewardsList = XRewardManager.GetRewardList(taskCfg.RewardId) or {}

        table.insert(result, taskData)
    end

    return result
end


function XPunishaarControl:MarkStageRead(stageId)
    if not self._Model:GetIsStageRead(stageId) then
        self._Model:SetStageRead(stageId)
    end
end

function XPunishaarControl:MarkCollectionRead(catalogType)
    XMVCA.XPunishaar:MarkCollectionRead(catalogType)
end

--- 获取关卡轮次
---@param stageId number
---@return number
function XPunishaarControl:GetStageSaveRound(stageId)
    local stage = self._Model:GetOutSideModel():GetSaveStage(stageId)
    return stage and stage.CurrentRound or 0
end

--- region ----------=协议（委托 NetworkAgency 执行，控制层不直接调 XNetwork）----------

function XPunishaarControl:GetStageData(cb)
    XMVCA.XPunishaar.NetworkAgency:DoGetStageData(cb)
end

function XPunishaarControl:StartStage(stageId, cb)
    local outSideModel = self._Model:GetOutSideModel()

    -- 尝试建新存档时，检测一下是否超过存档上限
    if not outSideModel:IsHasSaveStage(stageId) then
        local saveCount = outSideModel:GetSaveStageCount()
        local maxSaveCount = self:GetMaxSaveCount()

        if maxSaveCount > 0 and saveCount >= maxSaveCount then
            local tipCode = self:GetSaveCountLimitTipCode()

            if XTool.IsNumberValid(tipCode) then
                XUiManager.TipCode(tipCode)
                return
            end
        end
    end

    XMVCA.XPunishaar.NetworkAgency:DoStartStage(stageId, cb)
end

function XPunishaarControl:ContinueStage(stageId, cb)
    XMVCA.XPunishaar.NetworkAgency:DoContinueStage(stageId, cb)
end

--- 暂离当前局（保存存档，可继续）。与 QuitStage 对称：保留存档不放弃。
---@param stageId number
---@param cb function(success: boolean) 成功传 true，失败传 false
function XPunishaarControl:AwayStage(stageId, cb)
    XMVCA.XPunishaar.NetworkAgency:DoAwayStage(stageId, cb)
end

--- 提前结束当前局（放弃当局）。成功回调透传服务端整局结算信息 settleInfo。
---@param cb function(settleInfo: table|nil) 成功传 settleInfo，失败传 nil
function XPunishaarControl:QuitStage(cb)
    XMVCA.XPunishaar.NetworkAgency:DoQuitStage(cb)
end

--- 获取最近一次奖励列表（表现层弹窗集中展示用，奖励经 NotifyPunishaarRewardResult 缓存到 Model）
---@return table|nil XPunishaarRewardGoods[]
function XPunishaarControl:GetLastRewardGoodsList()
    return self._Model:GetLastRewardGoodsList()
end

return XPunishaarControl
