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
    -- pvp和pve的匹配敌人数据结构不一样
    if self._Model:GetCurPlayingMode() == XMVCA.XTheatre5.EnumConst.GameMode.PVP then
        local enemeyData = self._Model.CurAdventureData:GetCurMatchedEnemy()

        if enemeyData then
            return enemeyData.MissionId, enemeyData.MissionBountyLevel, enemeyData.MissionRelicId
        end
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
            
            -- 获取配置到配置表里的表头定义
            local fieldNames = self._Model:GetTheatre5ClientConfigTextArray('Theatre5MissionConditionTableDefine')

            if not XTool.IsTableEmpty(fieldNames) then
                -- 插值规则是直接用表头
                for _, key in pairs(fieldNames) do
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
function XTheatre5MissionControl:GetMissionRewardDesc(bountyId, curLevel, isSingle, itemIndex, descTargetLevel)
    local descFormat = self:GetMissionRewardDescFormat(bountyId, itemIndex, descTargetLevel)
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
    local tmpItemCfg = self:GetItemCfgByMissionBountyId(bountyId, 1, itemIndex)
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
                local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, v.Level, itemIndex)

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
                    local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, v.Level, itemIndex)

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
                local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, 1, itemIndex)

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
                local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, v.Level, itemIndex)

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
                    local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, v.Level, itemIndex)
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
                local itemCfg = self:GetItemCfgByMissionBountyId(bountyId, 1, itemIndex)

                local desc = itemCfg.DescDigit[insertPos]

                desc = XUiHelper.FormatText(highlineLabel, desc)

                table.insert(paramsGroup, desc)
            end
        end
    end
    
    -- 开发模式下检查
    if XMain.IsEditorDebug then
        local finalContent = ''

        xpcall(function()
            finalContent = XUiHelper.FormatText(descFormat, table.unpack(paramsGroup))
        end, function(msg)
            XLog.Error(msg, descFormat, paramsGroup)
        end)
        
        return finalContent
    else
        return XUiHelper.FormatText(descFormat, table.unpack(paramsGroup))
    end
    
end

--- 获取任务奖励的描述（固定只读等级1的文本）（没有完成才需要通过任务来找）
function XTheatre5MissionControl:GetMissionRewardDescFormat(bountyId, index, targetLevel)
    -- 默认只读等级1的文本，但图鉴等地方可能用的其他等级的文本
    targetLevel = targetLevel or 1
    local id = self._Model:GetMissionBountyComboId(bountyId, targetLevel)
    local bountyCfg = self._Model:GetTheatre5MissionBountyCfgById(id)

    if bountyCfg then
        local itemId = nil

        if XTool.IsNumberValidEx(index) then
            itemId = bountyCfg.BountyItem and bountyCfg.BountyItem[index] or nil
        else
            itemId = bountyCfg.BountyPackShow
        end

        if XTool.IsNumberValidEx(itemId) then

            local itemCfg = self._Model:GetTheatre5ItemCfgById(itemId)

            if itemCfg then
                return itemCfg.Desc
            end
        end
    end
    
    XLog.Error('没有找到有效的任务奖励描述文本，bountyId: ' .. tostring(bountyId))
    
    return ''
end

--- 获取任务奖励对应的道具配置（未完成时才需要通过任务来找）
function XTheatre5MissionControl:GetItemCfgByMissionBountyId(bountyId, level, index)
    local id = self._Model:GetMissionBountyComboId(bountyId, level)
    local bountyCfg = self._Model:GetTheatre5MissionBountyCfgById(id)

    if bountyCfg then
        if XTool.IsNumberValidEx(index) and XTool.IsNumberValidEx(bountyCfg.BountyItem[index]) then
            -- 指定了获取的是实际奖励中对应索引的奖励
            local itemId = bountyCfg.BountyItem[index]

            local itemCfg = self._Model:GetTheatre5ItemCfgById(itemId)

            return itemCfg
        else
            local itemId = bountyCfg.BountyPackShow

            local itemCfg = self._Model:GetTheatre5ItemCfgById(itemId)

            return itemCfg
        end
        
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

--- 回合结算无任务奖励状态描述，1是未接取，2是未完成
function XTheatre5MissionControl:GetClientConfigMissionStateLabelInRoundSettle(isGetMission)
    return self._Model:GetTheatre5ClientConfigText('MissionStateLabelInRoundSettle', isGetMission and 2 or 1)
end

--- 最终结算无任务奖励状态描述，1是未接取，2是未完成
function XTheatre5MissionControl:GetClientConfigMissionStateLabelInFinalSettle(isGetMission)
    return self._Model:GetTheatre5ClientConfigText('MissionStateLabelInFinalSettle', isGetMission and 2 or 1)
end

function XTheatre5MissionControl:GetClientConfigMissionLvFormat(level, isMax)
    local desc = self._Model:GetTheatre5ClientConfigText('MissionLvFormat', isMax and 2 or 1)

    if isMax then
        -- 顶级描述无插值
        return desc
    else
        return XUiHelper.FormatText(desc, level)
    end
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

--region 图鉴

--- 根据服务端记录的已解锁的bounty，构建临时的已解锁item缓存
--- 因为有些bounty是不显示的，但是它们使用的item与其他bounty存在重复，而图鉴显示是以道具为单位，因此这样做可以简单地兼容
function XTheatre5MissionControl:InitUnlockMissionItemCache()
    self._UnlockMissionItemIds = {}
    
    local pvpUnlockBountyList = self._Model.PVPAdventureData:GetUnlockBountyList()
    local pveUnlockBountyList = self._Model.PVEAdventureData:GetUnlockBountyList()

    self:_MarkBountyItemUnlockByBountyList(pvpUnlockBountyList)
    self:_MarkBountyItemUnlockByBountyList(pveUnlockBountyList)
end

function XTheatre5MissionControl:ReleaseUnlockMissionItemCache()
    self._UnlockMissionItemIds = nil
end

function XTheatre5MissionControl:_MarkBountyItemUnlockByBountyList(unlockBountyList)
    if not XTool.IsTableEmpty(unlockBountyList) then
        for i, bounty in pairs(unlockBountyList) do
            -- 这里需要遍历bounty表，进入图鉴显示本来就会全加载的，因此这里遍历没关系
            local bountyCfgs = self._Model:GetTheatre5MissionBountyGroupByBountyId(bounty)
            -- 读出来的是按等级顺序的配置
            local maxLevelBountyCfg = bountyCfgs[#bountyCfgs]

            -- 将最高级bounty对应的所有道具id标记为已解锁
            self._UnlockMissionItemIds[maxLevelBountyCfg.BountyPackShow] = true

            if not XTool.IsTableEmpty(maxLevelBountyCfg.BountyItem) then
                for _, itemId in pairs(maxLevelBountyCfg.BountyItem) do
                    self._UnlockMissionItemIds[itemId] = true
                end
            end
        end
    end
end

function XTheatre5MissionControl:_CheckBountyItemIsUnlock(itemId)
    if self._UnlockMissionItemIds then
        return self._UnlockMissionItemIds[itemId] or false
    end
    
    return false
end

--- 获取任务委托奖励的图鉴数据
function XTheatre5MissionControl:GetDataHandBook()
    if not self._UnlockMissionItemIds then
        self:InitUnlockMissionItemCache()
    end

    ---@type XUiTheatre5SkillHandbookTabGridData
    local tabOnlyOne = {
        TagName = "",
        Id = 0,
        Items = {},
        Order = 0,
        HideTagName = true,
    }
    
    -- 用于去重
    local itemIdMap = {}

    local missionCfgs = self._Model:GetTheatre5MissionCfgs()

    if missionCfgs then
        for id, missionCfg in pairs(missionCfgs) do
            if not missionCfg.HideInHandBook then
                local bounty = missionCfg.Bounty
                -- 获取任务最高等级
                local bountyMaxLevel = self._Model:GetTheatre5MissionBountyMaxLevel(bounty)
                
                -- 展示的道具
                local showItemCfg = self:GetItemCfgByMissionBountyId(bounty, bountyMaxLevel)

                if not itemIdMap[showItemCfg.Id] then
                    local showItemData = self:_GetItemDataHandBook(showItemCfg, bounty)

                    table.insert(tabOnlyOne.Items, showItemData)

                    itemIdMap[showItemCfg.Id] = true
                end
                
                -- 显示多选奖励中的实际奖励部分
                local itemIds = self:GetItemIdsByMissionBountyId(missionCfg.Bounty, bountyMaxLevel)

                if XTool.GetTableCount(itemIds) > 1 then
                    for index, itemId in pairs(itemIds) do
                        local itemCfg = self._Model:GetTheatre5ItemCfgById(itemId)

                        if not itemIdMap[itemCfg.Id] then
                            local data = self:_GetItemDataHandBook(itemCfg, bounty, index)

                            table.insert(tabOnlyOne.Items, data)

                            itemIdMap[itemCfg.Id] = true
                        end
                    end
                end
            end
        end
    end


    -- 排序
    table.sort(tabOnlyOne.Items, function(a, b)
        return a.Order < b.Order
    end)

    return { tabOnlyOne }
end

---@param itemCfg XTableTheatre5Item
---@return XUiTheatre5SkillHandbookItemGridData
function XTheatre5MissionControl:_GetItemDataHandBook(itemCfg, bounty, itemIndex)
    local maxLevel = self._Model:GetTheatre5MissionBountyMaxLevel(bounty)
    
    ---@type XUiTheatre5SkillHandbookItemGridData
    local data = {
        Id = itemCfg.Id,
        ItemId = itemCfg.Id,
        Order = itemCfg.Order,
        Name = itemCfg.Name,
        Quality = 0,
        Icon = itemCfg.IconRes,
        Desc = self:GetMissionRewardDesc(bounty, nil, nil, itemIndex, maxLevel),
        Tags = itemCfg.Tags,
        Bounty = bounty,
        IsUnlock = self:_CheckBountyItemIsUnlock(itemCfg.Id),
        Index = itemIndex,
    }
    
    return data
end

--endregion

return XTheatre5MissionControl