---@class XTheatre5MissionControl : XControl
---@field private _Model XTheatre5Model
---@field private _MainControl XTheatre5Control
local XTheatre5MissionControl = XClass(XControl, "XTheatre5MissionControl")

function XTheatre5MissionControl:OnInit()

end

function XTheatre5MissionControl:AddAgencyEvent()

end

function XTheatre5MissionControl:RemoveAgencyEvent()

end

function XTheatre5MissionControl:OnRelease()
    
end

--region ActivityData

function XTheatre5MissionControl:GetChooseMissions()
    return self._Model.CurAdventureData:GetChooseMissions()
end

function XTheatre5MissionControl:GetChooseMissionByPos(pos)
    return self._Model.CurAdventureData:GetChooseMissionByPos(pos)
end

---@return Theatre5Mission
function XTheatre5MissionControl:GetCurMission()
    return self._Model.CurAdventureData:GetCurMission()
end

function XTheatre5MissionControl:CheckHasMission()
    local mission = self:GetCurMission()
    
    return not XTool.IsTableEmpty(mission)
end

function XTheatre5MissionControl:CheckMissionIsGotReward()
    local mission = self:GetCurMission()

    if mission then
        return mission.MissionState == XMVCA.XTheatre5.EnumConst.Theatre5MissionState.HasReward
    end
    
    return false
end

function XTheatre5MissionControl:GetCurMissionItemId()
    local mission = self:GetCurMission()

    if mission then
        return mission.MissionRelicId
    end
    
    return 0
end

function XTheatre5MissionControl:GetMatchEnemyMissionData()
    local enemeyData = self._Model.CurAdventureData:GetCurMatchedEnemy()

    if enemeyData then
        return enemeyData.MissionId, enemeyData.MissionBountyLevel, enemeyData.MissionRelicId
    end
end
--endregion

--region Configs

function XTheatre5MissionControl:GetTableMissionRewardNameById(id, notips)
    local cfg = self._Model:GetTableMissionCfgById(id, notips)

    if cfg then
        return cfg.Name or ''
    end

    return ''
end

function XTheatre5MissionControl:GetTheatre5MissionBountyId(missionId, notips)
    local cfg = self._Model:GetTableMissionCfgById(missionId, notips)

    if cfg then
        return cfg.Bounty or 0
    end

    return 0
end

--- 获取任务完成条件的文本描述
function XTheatre5MissionControl:GetTableMissionConditionDescById(id, notips)
    local cfg = self._Model:GetTableMissionConditionCfgById(id, notips)

    if cfg then
        -- 需要处理插值
        -- 后面需要看一下这块的性能
        if string.find(cfg.Desc, '{.+}') then
            local fixedDesc = cfg.Desc
            
            -- 插值规则是直接用表头
            for key, valType in pairs(XTable.XTableTheatre5MissionCondition) do
                -- 需要判断是值还是表
                if type(cfg[key]) == 'table' then
                    -- 表的话需要遍历
                    for i, v in pairs(cfg[key]) do
                        local format = '{' .. tostring(key) .. '%[' .. tostring(i) .. '%]}'
                        fixedDesc = string.gsub(fixedDesc, format, tostring(v))
                    end
                else
                    -- 值的话直接替换
                    fixedDesc = string.gsub(fixedDesc, '{' .. tostring(key) .. '}', tostring(cfg[key]))
                end
            end
            
            return fixedDesc
        else
            return cfg.Desc or ''
        end
        
    end

    return ''
end

--- 获取任务的升级描述
function XTheatre5MissionControl:GetMissionLevelUpCostDesc(bountyId, curLevel)
    local group = self._Model:GetTheatre5MissionBountyGroupByBountyId(bountyId)

    if XTool.IsTableEmpty(group) then
        XLog.Error('读取的奖励为空，bounty：' .. tostring(bountyId))
        return ''
    end

    -- 最后一级不显示
    local count = #group - 1
    local levelUpCostLinksTxt = self._Model:GetTheatre5ClientConfigText('MissionLevelUpCostLinks', count)

    if string.IsNilOrEmpty(levelUpCostLinksTxt) then
        XLog.Error('对应数量的插值配置不存在，等级数量：' .. tostring(count))
        return ''
    end

    local highlineLabel = self._Model:GetTheatre5ClientConfigText('MissionLevelUpCostHighLine', 1)

    local params = {}
    if XTool.IsNumberValidEx(curLevel) then
        -- 如果有指定当前等级，说明只针对当前等级进行高亮
        for i, v in ipairs(group) do
            if XTool.IsNumberValidEx(v.Cost) then
                local cost = v.Cost

                if v.Level == curLevel then
                    cost = XUiHelper.FormatText(highlineLabel, cost)
                end

                table.insert(params, cost)
            end
        end

        return XUiHelper.FormatText(levelUpCostLinksTxt, table.unpack(params))
    else
        for i, v in ipairs(group) do
            if XTool.IsNumberValidEx(v.Cost) then
                local cost = v.Cost
                table.insert(params, cost)
            end
        end

        local fullContent = XUiHelper.FormatText(levelUpCostLinksTxt, table.unpack(params))

        fullContent = XUiHelper.FormatText(highlineLabel, fullContent)

        return fullContent
    end
end

--- 获取任务对应等级的升级费用
function XTheatre5MissionControl:GetMissionLevelUpCost(bountyId, curLevel)
    local id = self._Model:GetMissionBountyComboId(bountyId, curLevel)
    local bountyCfg = self._Model:GetTheatre5MissionBountyCfgById(id)

    if bountyCfg then
        return bountyCfg.Cost
    end

    XLog.Error('没有找到有效的任务升级费用，bountyId: ' .. tostring(bountyId))

    return 0
end

--- 获取任务的奖励描述
function XTheatre5MissionControl:GetMissionRewardDesc(bountyId, curLevel, isSingle, targetItemId)
    local descFormat = self:GetMissionRewardDescFormat(bountyId)
    local highlineLabel = self._Model:GetTheatre5ClientConfigText('MissionRewardHighLine')
    
    local isAimLevel = XTool.IsNumberValidEx(curLevel)
    
    if isAimLevel and isSingle then
        -- 只获取当前等级的描述
        local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, curLevel)

        if itemCfg then
            local valueStrList = {}

            for i, v in ipairs(itemCfg.DescDigit) do
                local valueStr = XUiHelper.FormatText(highlineLabel, v)
                valueStrList[i] = valueStr
            end

            return XUiHelper.FormatText(descFormat, table.unpack(valueStrList))
        end
        
        return ''
    end

    local paramsGroup = {}
    local group = self._Model:GetTheatre5MissionBountyGroupByBountyId(bountyId)
    local levelCount = #group
    local rewardLinks = self._Model:GetTheatre5ClientConfigText('MissionRewardLinks', levelCount)

    if string.IsNilOrEmpty(rewardLinks) then
        XLog.Error('对应数量的插值配置不存在，等级数量：' .. tostring(levelCount))
        return ''
    end
    
    -- 需要根据参数来知道有多少个插值位, 因为每个等级的插值位是一致的，以1级为准即可
    local tmpItemCfg = self:GetItemCfgByMissionBountyId(bountyId, 1)
    local insertCount = 0

    if tmpItemCfg then
        insertCount = #tmpItemCfg.DescDigit
    end
    
    if isAimLevel then
        -- 指定了等级，那么仅该等级高亮
        for insertPos = 1, insertCount do
            local params = {}
            
            -- 需要判断当前插值位的各等级参数是否完全一致
            local isFullSameParam = true
            local compareStr = nil

            for i, v in ipairs(group) do
                local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, v.Level)

                local desc = itemCfg.DescDigit[insertPos]

                if compareStr == nil then
                    compareStr = desc
                elseif compareStr ~= desc then
                    isFullSameParam = false
                    break
                end
            end
            
            -- 如果存在参数差异，则按照原规则显示
            if not isFullSameParam then
                for i, v in ipairs(group) do
                    local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, v.Level)

                    local desc = itemCfg.DescDigit[insertPos]

                    if v.Level == curLevel then
                        desc = XUiHelper.FormatText(highlineLabel, desc)
                    end

                    table.insert(params, desc)
                end

                local tmpParam = ''

                if levelCount ~= #params then
                    XLog.Error('奖励描述的插值位和实际配置参数对不上，插值位数：' .. tostring(insertCount) .. '参数数量: ' .. tostring(#params))
                else
                    tmpParam = XUiHelper.FormatText(rewardLinks, table.unpack(params))
                end

                table.insert(paramsGroup, tmpParam)
            else
                -- 否则只显示其中一个等级的参数即可
                local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, 1)

                local desc = itemCfg.DescDigit[insertPos]

                desc = XUiHelper.FormatText(highlineLabel, desc)

                table.insert(paramsGroup, desc)
            end
        end
    else
        -- 未指定等级，整个参数高亮
        for insertPos = 1, insertCount do
            -- 需要判断当前插值位的各等级参数是否完全一致
            local isFullSameParam = true
            local compareStr = nil

            for i, v in ipairs(group) do
                local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, v.Level)

                local desc = itemCfg.DescDigit[insertPos]

                if compareStr == nil then
                    compareStr = desc
                elseif compareStr ~= desc then
                    isFullSameParam = false
                    break
                end
            end

            if not isFullSameParam then
                local params = {}

                for i, v in ipairs(group) do
                    local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, v.Level)
                    local desc = itemCfg.DescDigit[insertPos]

                    table.insert(params, desc)
                end

                local tmpParam = ''

                if levelCount ~= #params then
                    XLog.Error('奖励描述的插值位和实际配置参数对不上，插值位数：' .. tostring(insertCount) .. '参数数量: ' .. tostring(#params))
                else
                    tmpParam =  XUiHelper.FormatText(rewardLinks, table.unpack(params))
                    tmpParam =  XUiHelper.FormatText(highlineLabel, tmpParam)
                end

                table.insert(paramsGroup, tmpParam)
            else
                -- 否则只显示其中一个等级的参数即可
                local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, 1)

                local desc = itemCfg.DescDigit[insertPos]

                desc = XUiHelper.FormatText(highlineLabel, desc)

                table.insert(paramsGroup, desc)
            end
        end
    end
    
    return XUiHelper.FormatText(descFormat, table.unpack(paramsGroup))
end

--- 获取任务奖励的描述（固定只读等级1的文本）（没有完成才需要通过任务来找）
function XTheatre5MissionControl:GetMissionRewardDescFormat(bountyId)
    local id = self._Model:GetMissionBountyComboId(bountyId, 1)
    local bountyCfg = self._Model:GetTheatre5MissionBountyCfgById(id)

    if bountyCfg then
        local itemId = bountyCfg.BountyPackShow
        
        local itemCfg = self._Model:GetTheatre5ItemCfgById(itemId)

        if itemCfg then
            return itemCfg.Desc
        end
    end
    
    XLog.Error('没有找到有效的任务奖励描述文本，bountyId: ' .. tostring(bountyId))
    
    return ''
end

--- 获取任务奖励对应的道具配置（未完成时才需要通过任务来找）
function XTheatre5MissionControl:GetItemCfgByMissionBountyId(bountyId, level)
    local id = self._Model:GetMissionBountyComboId(bountyId, level)
    local bountyCfg = self._Model:GetTheatre5MissionBountyCfgById(id)

    if bountyCfg then
        local itemId = bountyCfg.BountyPackShow

        local itemCfg = self._Model:GetTheatre5ItemCfgById(itemId)

        return itemCfg
    end
end

--- 获取任务奖励道具Id列表
function XTheatre5MissionControl:GetItemIdsByMissionBountyId(bountyId, level)
    local id = self._Model:GetMissionBountyComboId(bountyId, level)
    local bountyCfg = self._Model:GetTheatre5MissionBountyCfgById(id)

    if bountyCfg then
        return bountyCfg.BountyItem
    end
end

--- 获取任务奖励图标(未完成时）
function XTheatre5MissionControl:GetMissionRewardIcon(bountyId, level)
    level = level or 1

    local id = self._Model:GetMissionBountyComboId(bountyId, level)
    local bountyCfg = self._Model:GetTheatre5MissionBountyCfgById(id)

    if bountyCfg then
        local itemId = bountyCfg.BountyPackShow

        local itemCfg = self._Model:GetTheatre5ItemCfgById(itemId)

        if itemCfg then
            return itemCfg.IconRes
        end
    end

    XLog.Error('没有找到有效的任务奖励图标，bountyId: ' .. tostring(bountyId))

    return ''
end

--- 任务图标的等级显示文本
function XTheatre5MissionControl:GetMissionGridLevelShow(bountyId, level)
    local isMaxLevel = self:CheckMissionIsMaxLevel(bountyId, level)

    if isMaxLevel then
        return self._Model:GetTheatre5ClientConfigText('MissionGridLevelLabel', 2)
    else
        return XMVCA.XTheatre5:GetClientConfig('MissionGridLevelLabel', 1, level)
    end
end

--- 获取任务刷新次数上限
function XTheatre5MissionControl:GetMissionFreshMaxCount()
    return self._Model:GetTheatre5ConfigValByKey('MissionFreshCnt')
end

--- 读取任务目标进度
function XTheatre5MissionControl:GetMissionTargetCount(conditionId)
    local cfg = self._Model:GetTableMissionConditionCfgById(conditionId)

    if cfg then
        return cfg.ConditionTarget
    end
    
    return 1
end

--- 获取任务图标标题文本
function XTheatre5MissionControl:GetMissionGridTitle(isFinishState)
    return self._Model:GetTheatre5ClientConfigText('MissionGridTitle', isFinishState and 2 or 1)
end

--- 获取图鉴中未解锁的描述文本
function XTheatre5MissionControl:GetClientConfigMissonIsLockInBook()
    return self._Model:GetTheatre5ClientConfigText('MissonIsLockInBook')
end

--- 获取每回合升级最大次数
function XTheatre5MissionControl:GetConfigMissionLevelUpForRound()
    return self._Model:GetTheatre5ConfigValByKey('MissionLevelUpForRound')
end

--- 技能三选一阶段点击任务升级时的提示
function XTheatre5MissionControl:GetClientConfigMissionLevelUpInSkillSelectionPart()
    return self._Model:GetTheatre5ClientConfigText('MissionLevelUpInSkillSelectionPart')
end

--- 技能三选一阶段点击已完成的任务Icon时的提示
function XTheatre5MissionControl:GetClientConfigMissionFinishTipsInSkillChoicePart()
    return self._Model:GetTheatre5ClientConfigText('MissionFinishTipsInSkillChoicePart')
end
--endregion

--region Condition

--- 判断任务是否升到顶级
function XTheatre5MissionControl:CheckMissionIsMaxLevel(bountyId, level)
    local group = self._Model:GetTheatre5MissionBountyGroupByBountyId(bountyId)

    if not XTool.IsTableEmpty(group) then
        local cfg = group[#group]
        
        return cfg.Level == level
    end
    
    XLog.Error('不存在奖励组配置，bountyId：' .. tostring(bountyId))
    return true
end

--- 判断指定位置的任务是否还可以刷新
function XTheatre5MissionControl:CheckMissionCanRefreshByPos(pos)
    local times = self._Model.CurAdventureData:GetFreshCountByPos(pos)
    local maxTimes= self:GetMissionFreshMaxCount()
    return times < maxTimes
end

--- 判断任务是否领取过
function XTheatre5MissionControl:CheckMissionBountyIsGot(bounty, distinguishPvpOrPve, isPvp)
    local isPvpHasGot = self._Model.PVPAdventureData:CheckHasBounty(bounty)
    local isPveHasGot = self._Model.PVEAdventureData:CheckHasBounty(bounty)

    if distinguishPvpOrPve then
        if isPvp then
            return isPvpHasGot
        else
            return isPveHasGot
        end
    end
    
    return isPvpHasGot or isPveHasGot
end

--- 判断是否有剩余升级次数
function XTheatre5MissionControl:CheckHasMissionLevelUpTimes()
    local limitTimes = self:GetConfigMissionLevelUpForRound()
    
    local curTimes = self._Model.CurAdventureData:GetMissionLevelUpForRound()
    
    return curTimes < limitTimes
end

--endregion

return XTheatre5MissionControl