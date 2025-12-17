--- 意识图鉴数据实体
---@class XArchiveAwarenessData
---@field private _Owner XArchiveModel
---
---@field AwarenessSuitRedPointCountDic table @对应意识类型的套装红点数之和字典 <key: ArchiveAwarenessGroup.tab-Type, value: number(suit reddot) >
---@field AwarenessSuitTotalRedPointCount number @意识图鉴红点总数
---@field AwarenessSettingCanUnlockDic table @可解锁的意识设定字典 <key: AwarenessSetting.tab-Id, value: bool>
---@field NewAwarenessSettingIdsDic table @新解锁的意识套装-设定映射字典 <key: suitId, value: table<settingId> >
---@field AwarenessSettingRedPointCountDic table @对应意识类型的设定红点数之和字典 <key: ArchiveAwarenessGroup.tab-Type, value: number(setting reddot) >
---@field AwarenessSettingTotalRedPointCount number @意识设定红点总数
---
---@field AwarenessServerData table @意识图鉴服务端数据 <key: templateId, value: XArchiveEquipClient>
---@field AwarenessSuitUnlockServerData table @意识套装解锁的服务端数据 <key: id, value: bool>
---@field AwarenessSettingUnlockServerData table @意识设定解锁的服务端数据 <key: settingId, value: bool>
---@field AwarenessSuitToAwarenessCountDic table @意识套装-套装内意识数映射字典 <key: suitId, value: number(awareness) >
local XArchiveAwarenessData = XClass(nil, 'XArchiveAwarenessData')

function XArchiveAwarenessData:Ctor(owner)
    self._Owner = owner
    
    self:InitData()
end

function XArchiveAwarenessData:Release()
    self._Owner = nil
end

function XArchiveAwarenessData:ResetData()
    self:InitData()
end

function XArchiveAwarenessData:InitData()
    self.AwarenessSuitRedPointCountDic = {}
    self.AwarenessSuitTotalRedPointCount = 0
    self.AwarenessSettingCanUnlockDic = {}
    self.NewAwarenessSettingIdsDic = {}
    self.AwarenessSettingRedPointCountDic = {}
    self.AwarenessSettingTotalRedPointCount = 0

    self.AwarenessServerData = {}
    self.AwarenessSuitUnlockServerData = {}
    self.AwarenessSettingUnlockServerData = {}
    self.AwarenessSuitToAwarenessCountDic = {}
    
    self._IsInitByPairAwarenessGroupConfig = false -- 是否执行了_InitByPairAwarenessGroupConfig初始化方法

    self._AwarenessTypeToGroupDatasDic = {}
    self._AwarenessTypeToTimeLimitGroupDatasDic = {}
    self._AwarenessSuitIdToSettingListDic = {}

    self._AwarenessShowedStatusDic = {}
end

function XArchiveAwarenessData:_InitByPairAwarenessGroupConfig()
    if self._IsInitByPairAwarenessGroupConfig then
        return
    end
    
    local awarenessGroupConfig = self._Owner:GetArchiveAwarenessGroup()

    if XTool.IsTableEmpty(awarenessGroupConfig) then
        return
    end
    
    -- 常显意识总数
    self._AwarenessResidentSumCollectNum = 0
    -- 时间控制的意识字典
    self._AwarenessTimeLimitSumCollectDict = {}
    
    local now = XTime.GetServerNowTimestamp()

    ---@param config XTableArchiveAwarenessGroup
    for suitId, config in pairs(awarenessGroupConfig) do
        -- 统计常显意识总数、带时间控制的意识
        local showTimeStr = config.ShowTimeStr
        local templateIdList = XMVCA.XEquip:GetSuitEquipIds(suitId)
        -- 如果没有配置时间限制，或配置的时间已经到达了，则归入常显部分，不参与后续的检测
        if string.IsNilOrEmpty(showTimeStr) or now >= XTime.ParseToTimestamp(showTimeStr) then
            self._AwarenessResidentSumCollectNum = self._AwarenessResidentSumCollectNum + XTool.GetTableCount(templateIdList)
        else
            self._AwarenessTimeLimitSumCollectDict[suitId] = showTimeStr
        end
    end
    
    self._IsInitByPairAwarenessGroupConfig = true
end

--- 检查指定的意识套装，是否显示(未配置showTimeStr，或已到达显示的时间）
function XArchiveAwarenessData:CheckAwarenessSuitInShowTime(suitId)
    ---@type XTableArchiveAwarenessGroup
    local cfg = self._Owner:GetArchiveAwarenessGroupCfgById(suitId)

    if cfg then
        if string.IsNilOrEmpty(cfg.ShowTimeStr) then
            return true
        else
            local now = XTime.GetServerNowTimestamp()

            return now >= XTime.ParseToTimestamp(cfg.ShowTimeStr)
        end
    end

    return false
end

--region ---------- 服务端数据 ---------->>>

--- AwarenessServerData

function XArchiveAwarenessData:GetAwarenessServerData()
    return self.AwarenessServerData
end

function XArchiveAwarenessData:GetAwarenessServerDataById(templateId)
    return self.AwarenessServerData[templateId]
end

function XArchiveAwarenessData:SetAwarenessServerDataById(templateId,data)
    self.AwarenessServerData[templateId] = data
end

--- AwarenessSuitToAwarenessCountDic

function XArchiveAwarenessData:GetAwarenessSuitToAwarenessCountDic()
    return self.AwarenessSuitToAwarenessCountDic
end

function XArchiveAwarenessData:GetAwarenessSuitToAwarenessCountById(suitId)
    return self.AwarenessSuitToAwarenessCountDic[suitId]
end

function XArchiveAwarenessData:ClearAwarenessSuitToAwarenessCountDic()
    self.AwarenessSuitToAwarenessCountDic = {}
end

function XArchiveAwarenessData:AddAwarenessSuitToAwarenessCountById(suitId,adds)
    if type(self.AwarenessSuitToAwarenessCountDic[suitId]) ~= 'number' then
        self.AwarenessSuitToAwarenessCountDic[suitId] = 0
    end
    self.AwarenessSuitToAwarenessCountDic[suitId] = self.AwarenessSuitToAwarenessCountDic[suitId] + adds
end

--- AwarenessSuitUnlockServerData

function XArchiveAwarenessData:GetAwarenessSuitUnlockServerDataById(suitId)
    return self.AwarenessSuitUnlockServerData[suitId]
end


function XArchiveAwarenessData:SetAwarenessSuitUnlockServerDataById(id,data)
    self.AwarenessSuitUnlockServerData[id] = data
end

function XArchiveAwarenessData:UpdateAwarenessSuitUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self.AwarenessSuitUnlockServerData[id] = true
    end
end

--- AwarenessSettingUnlockServerData

function XArchiveAwarenessData:GetAwarenessSettingUnlockServerDataById(settingId)
    return self.AwarenessSettingUnlockServerData[settingId] or false
end

function XArchiveAwarenessData:_SetAwarenessSettingUnlockServerData(id,unLock)
    self.AwarenessSettingUnlockServerData[id] = unLock
end

function XArchiveAwarenessData:UpdateAwarenessSettingUnlockServerData(idList)
    for _, id in ipairs(idList) do
        self.AwarenessSettingUnlockServerData[id] = true
    end
end

--endregion <<<---------------------------

--region ---------- 配置相关 --------->>>

--- 获取显示的意识收集上限数
function XArchiveAwarenessData:GetAwarenessSumCollectNum()
    self:_InitByPairAwarenessGroupConfig()
    
    local totalCount = self._AwarenessResidentSumCollectNum
    
    if not XTool.IsTableEmpty(self._AwarenessTimeLimitSumCollectDict) then
        -- 如果存在意识有时间控制显示的，那么只有在到达时间后才能纳入统计
        local now = XTime.GetServerNowTimestamp()
        
        local removeList = nil
        
        for id, timeShowStr in pairs(self._AwarenessTimeLimitSumCollectDict) do
            if now >= XTime.ParseToTimestamp(timeShowStr) then
                local templateIdList = XMVCA.XEquip:GetSuitEquipIds(id)
                local newShowCount = XTool.GetTableCount(templateIdList)
                totalCount = totalCount + newShowCount
                
                -- 如果意识已经到达显示的时间了，那么直接归入常显列表即可，后续不再重复检测
                self._AwarenessResidentSumCollectNum = self._AwarenessResidentSumCollectNum + newShowCount

                if removeList == nil then
                    removeList = {}
                end
                
                table.insert(removeList, id)
            end
        end

        if removeList then
            for i, v in pairs(removeList) do
                self:_RemoveAwarenessGroupFromTimelimitChecker(v)
                
                -- 新显示的套装需要检查所属设定是否显示蓝点
                -- 新显示的套装需要检查是否需要显示蓝点
                local suitNewReddot = self:TryToSetAwarenessSuitNewGetReddot(v, true)
                local settingNewReddot = self:TrySetAllAwarenessSettingNewGetReddotBySuitId(v)
                
                if suitNewReddot or settingNewReddot then
                    XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_AWARENESS_SUIT, v)
                end
            end
        end
    end

    return totalCount
end

--- 获取类型-意识套装配置的映射字典(忽略时间限制隐藏的意识套装）
function XArchiveAwarenessData:GetAwarenessTypeToGroupDatas(groupType)
    --- 遍历分组，并且提取出受时间控制的意识套装
    if XTool.IsTableEmpty(self._AwarenessTypeToGroupDatasDic) then
        local now = XTime.GetServerNowTimestamp()
        
        for _, typeCfg in pairs(self._Owner:GetArchiveAwarenessGroupType()) do
            self._AwarenessTypeToGroupDatasDic[typeCfg.GroupId] = {}
        end

        for _, groupCfg in pairs(self._Owner:GetArchiveAwarenessGroup()) do
            local curGroupType = groupCfg.Type
            
            if not string.IsNilOrEmpty(groupCfg.ShowTimeStr) then
                if self._AwarenessTypeToTimeLimitGroupDatasDic[curGroupType] == nil then
                    self._AwarenessTypeToTimeLimitGroupDatasDic[curGroupType] = {}
                end

                -- 只有时间没到才要加入列表进行检测，如果已经到时间了则不必重复检测，这里本身重登后也会重新执行
                if now < XTime.ParseToTimestamp(groupCfg.ShowTimeStr) then
                    table.insert(self._AwarenessTypeToTimeLimitGroupDatasDic[curGroupType], groupCfg)
                else
                    if self._AwarenessTypeToGroupDatasDic[curGroupType] then
                        table.insert(self._AwarenessTypeToGroupDatasDic[curGroupType], groupCfg)
                    end
                end
            else
                if self._AwarenessTypeToGroupDatasDic[curGroupType] then
                    table.insert(self._AwarenessTypeToGroupDatasDic[curGroupType], groupCfg)
                end
            end
        end
    end

    --- 获取对应组当前可以显示的套装列表
    if not XTool.IsTableEmpty(self._AwarenessTypeToTimeLimitGroupDatasDic[groupType]) then
        local now = XTime.GetServerNowTimestamp()
        --- 检查
        for i = #self._AwarenessTypeToTimeLimitGroupDatasDic[groupType], 1, -1 do
            local cfg = self._AwarenessTypeToTimeLimitGroupDatasDic[groupType][i]

            if now >= XTime.ParseToTimestamp(cfg.ShowTimeStr) then
                -- 如果这个意识套装满足显示条件了，加入到常显列表，同时移出时限检测列表
                self:_RemoveAwarenessGroupFromTimelimitChecker(cfg.Id, i)

                -- 新显示的套装需要检查所属设定是否显示蓝点
                local suitNewReddot = self:TryToSetAwarenessSuitNewGetReddot(cfg.Id, true)
                local settingNewReddot = self:TrySetAllAwarenessSettingNewGetReddotBySuitId(cfg.Id)
                
                if suitNewReddot or settingNewReddot then
                    XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_NEW_AWARENESS_SUIT, cfg.Id)
                end
            end
        end
    end

    return self._AwarenessTypeToGroupDatasDic[groupType]
end 

--- 获取意识套装-设定配置列表的映射字典
--- 登录时就因初始化红点数据而遍历了，后续可看看是否有合适的优化方法
function XArchiveAwarenessData:GetAwarenessSuitIdToSettingListDic()
    if XTool.IsTableEmpty(self._AwarenessSuitIdToSettingListDic) then
        local suitId
        for _, settingData in pairs(self._Owner:GetAwarenessSetting()) do
            suitId = settingData.SuitId
            self._AwarenessSuitIdToSettingListDic[suitId] = self._AwarenessSuitIdToSettingListDic[suitId] or {}
            table.insert(self._AwarenessSuitIdToSettingListDic[suitId], settingData)
        end
    end

    return self._AwarenessSuitIdToSettingListDic
end

--- 获取意识Id字典，方便更新服务端数据时校验数据是否在配置中存在 时的访问效率
--- 不确定是否有历史意识数据变动，该逻辑的必要性暂时不明，且该逻辑遍历初始化的性能消耗不是特别大，暂时仅作接口位置迁移
function XArchiveAwarenessData:GetAwarenessShowedStatusDic()
    if XTool.IsTableEmpty(self._AwarenessShowedStatusDic) then
        local templateIdList
        for suitId, _ in pairs(self._Owner:GetArchiveAwarenessGroup()) do
            templateIdList = XMVCA.XEquip:GetSuitEquipIds(suitId)
            for _, templateId in pairs(templateIdList) do
                self._AwarenessShowedStatusDic[templateId] = true
            end
        end
    end

    return self._AwarenessShowedStatusDic
end

--- 将指定意识套装从限时检查的缓存中移除(当指定套装的showTimeStr满足时）
function XArchiveAwarenessData:_RemoveAwarenessGroupFromTimelimitChecker(suitId, timelimeGroupDictIndex)
    -- 从意识套装统计进度的限时检查字典中移除
    self._AwarenessTimeLimitSumCollectDict[suitId] = nil
    
    ---@type XTableArchiveAwarenessGroup
    local cfg = self._Owner:GetArchiveAwarenessGroupCfgById(suitId)
    if cfg then
        -- 从意识套装组限时配置列表中移除
        local isin, index

        if XTool.IsNumberValid(timelimeGroupDictIndex) then
            isin = true
            index = timelimeGroupDictIndex
        else
            isin, index = table.contains(self._AwarenessTypeToTimeLimitGroupDatasDic[cfg.Type], cfg)
        end

        if isin then
            table.remove(self._AwarenessTypeToTimeLimitGroupDatasDic[cfg.Type], index)
        end
        
        -- 加入到意识套装组配置列表中
        table.insert(self._AwarenessTypeToGroupDatasDic[cfg.Type], cfg)
    end
end

--endregion <<<------------------------

--region --------- 意识套装红点相关 ---------->>>

--- 清除对应意识套装的红点数据
function XArchiveAwarenessData:ClearAwarenessSuitReddotBySuitIds(suitIds)
    if not XTool.IsTableEmpty(suitIds) then
        for _, id in ipairs(suitIds) do
            -- 将对应意识套装标记为已解锁
            self:SetAwarenessSuitUnlockServerDataById(id, true)
            
            local cfg = self._Owner:GetArchiveAwarenessGroupCfgById(id)

            if cfg then
                -- 将该意识套装所属的意识类型红点计数 - 1
                self:_SetAwarenessSuitRedPointCountByType(cfg.Type, self:GetNewAwarenessSuitByGetType(cfg.Type) - 1)
            end
        end
        
        -- 意识图鉴套装总红点计数 - 已解锁套装数
        self:_AddAwarenessSuitTotalRedPointCount(- #suitIds)

        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SUIT)
    end
end

--- 添加指定意识套装的红点数据（新获得，未标记为解锁时）
function XArchiveAwarenessData:SetAwarenessSuitNewGetReddot(suitId)
    local cfg = self._Owner:GetArchiveAwarenessGroupCfgById(suitId)

    if cfg then
        local awarenessGetType = cfg.Type
        --- 套装所属类型的红点计数 + 1
        self:_AddAwarenessSuitRedPointCountByType(awarenessGetType, 1)
        --- 意识套装总红点计数 + 1
        self:_AddAwarenessSuitTotalRedPointCount(1)
    end
end

--- 尝试添加指定意识套装的红点数据，若满足条件则添加成功
function XArchiveAwarenessData:TryToSetAwarenessSuitNewGetReddot(suitId, ignoreShowTime)
    if not self:GetAwarenessSuitUnlockServerDataById(suitId) then
        if ignoreShowTime or self:CheckAwarenessSuitInShowTime(suitId) then
            self:SetAwarenessSuitNewGetReddot(suitId)
            return true
        end
    end
    return false
end

--- 获取意识套装总红点数
function XArchiveAwarenessData:GetAwarenessSuitTotalRedPointCount()
    return self.AwarenessSuitTotalRedPointCount
end

--- 获取指定意识类型的红点数（新获得意识数）
function XArchiveAwarenessData:GetNewAwarenessSuitByGetType(type)
    return self.AwarenessSuitRedPointCountDic[type] or 0
end

--- 设置对应意识类型拥有的红点数
function XArchiveAwarenessData:_SetAwarenessSuitRedPointCountByType(awarenessGetType, count)
    self.AwarenessSuitRedPointCountDic[awarenessGetType] = count
end

--- 按照意识类型添加红点数量
function XArchiveAwarenessData:_AddAwarenessSuitRedPointCountByType(awarenessGetType, adds)
    if type(self.AwarenessSuitRedPointCountDic[awarenessGetType]) ~= 'number' then
        self.AwarenessSuitRedPointCountDic[awarenessGetType] = 0
    end
    
    self.AwarenessSuitRedPointCountDic[awarenessGetType] = self.AwarenessSuitRedPointCountDic[awarenessGetType] + adds
end

--- 为当前意识套装红点总数添加增量
function XArchiveAwarenessData:_AddAwarenessSuitTotalRedPointCount(adds)
    self.AwarenessSuitTotalRedPointCount = self.AwarenessSuitTotalRedPointCount + adds
end

--endregion <<<----------------------------

--region ---------- 意识设定红点相关 ---------->>>

--- 清除对应意识设定的红点
function XArchiveAwarenessData:ClearAwarenessSettingReddotBySettingIds(settingIds)
    if not XTool.IsTableEmpty(settingIds) then
        for _, id in ipairs(settingIds) do
            -- 将对应意识设定标记为已解锁
            self:_SetAwarenessSettingUnlockServerData(id, true)
            -- 清除意识设定红点
            self:_SetAwarenessSettingCanUnlockDicById(id, nil)
            local suitId = self._Owner:GetAwarenessSetting()[id].SuitId
            local getType = self._Owner:GetArchiveAwarenessGroup()[suitId].Type
            -- 意识设定所属的意识套装，关联类型的红点计数 - 1
            self:_SetAwarenessSettingRedPointCountDicByType(getType,self:GetNewAwarenessSettingByGetType(getType) - 1)
            local newAwarenessSettingIdList = self:GetNewAwarenessSettingIdListById(suitId)

            if newAwarenessSettingIdList then
                for index, settingId in ipairs(newAwarenessSettingIdList) do
                    if id == settingId then
                        table.remove(newAwarenessSettingIdList, index)
                        break
                    end
                end
                if #newAwarenessSettingIdList == 0 then
                    self:_SetNewAwarenessSettingIdsDicBySuitId(suitId, nil)
                end
            end
        end
        
        -- 意识设定总红点计数 - 已解锁设定数
        self:_SetAwarenessSettingTotalRedPointCount(self:GetAwarenessSettingTotalRedPointCount() - #settingIds)
        XEventManager.DispatchEvent(XEventId.EVENET_ARCHIVE_UNLOCK_AWARENESS_SETTING)
    end
end

--- 添加指定意识设定的红点数据（新获得，未标记为解锁时）
function XArchiveAwarenessData:SetAwarenessSettingNewGetReddot(settingId)
    -- 将该意识设定标记为可解锁
    self:_SetAwarenessSettingCanUnlockDicById(settingId, true)
    
    local suitId = self._Owner:GetAwarenessSetting()[settingId].SuitId
    local getType = self._Owner:GetArchiveAwarenessGroup()[suitId].Type
    -- 根据所属意识套装，添加到新获得列表中，同时所属套装类型、意识设定总红点计数 + 1
    self:_InsertNewAwarenessSettingIdById(suitId,settingId)
    self:_AddAwarenessSettingRedPointCountDicByType(getType,1)
    self:_AddAwarenessSettingTotalRedPointCount(1)
end

--- 根据指定的意识套装，尝试初始化它的所有设定的红点
function XArchiveAwarenessData:TrySetAllAwarenessSettingNewGetReddotBySuitId(suitId)
    local settingDataList = XMVCA.XArchive.AwarenessArchiveCom:GetAwarenessSettingList(suitId, nil, true)
    local hasAnyReddot = false
    for _, settingData in ipairs(settingDataList) do
        local settingId = settingData.Id
        if not self:GetAwarenessSettingUnlockServerDataById(settingId) and XConditionManager.CheckCondition(settingData.Condition, suitId) then
            self:SetAwarenessSettingNewGetReddot(settingId)
            hasAnyReddot = true
        end
    end
    
    return hasAnyReddot
end

--- 判断指定意识设定Id是否可解锁
function XArchiveAwarenessData:GetAwarenessSettingCanUnlockById(settingId)
    return self.AwarenessSettingCanUnlockDic[settingId] or false
end

--- 获取意识设定解锁状态字典
function XArchiveAwarenessData:GetAwarenessSettingCanUnlockDic()
    return self.AwarenessSettingCanUnlockDic
end

--- 获取意识设定总红点数（新解锁意识设定数量）
function XArchiveAwarenessData:GetAwarenessSettingTotalRedPointCount()
    return self.AwarenessSettingTotalRedPointCount
end

--- 根据指定的意识类型，获取对应的设定红点数
function XArchiveAwarenessData:GetNewAwarenessSettingByGetType(type)
    return self.AwarenessSettingRedPointCountDic[type] or 0
end

--- 意识套装->意识设定映射的字典，存储的数据表示新解锁的设定
function XArchiveAwarenessData:GetNewAwarenessSettingIdListById(suitId)
    return self.NewAwarenessSettingIdsDic[suitId]
end

--- 设置指定意识设定Id的解锁状态
function XArchiveAwarenessData:_SetAwarenessSettingCanUnlockDicById(id, canUnLock)
    self.AwarenessSettingCanUnlockDic[id] = canUnLock
end

function XArchiveAwarenessData:_InsertNewAwarenessSettingIdById(tmpSuitId,settingId)
    if not self.NewAwarenessSettingIdsDic[tmpSuitId] then
        self.NewAwarenessSettingIdsDic[tmpSuitId] = {}
    end
    table.insert(self.NewAwarenessSettingIdsDic[tmpSuitId], settingId)
end

function XArchiveAwarenessData:_SetNewAwarenessSettingIdsDicBySuitId(suitId,data)
    self.NewAwarenessSettingIdsDic[suitId] = data
end

function XArchiveAwarenessData:_SetAwarenessSettingRedPointCountDicByType(type,count)
    self.AwarenessSettingRedPointCountDic[type] = count
end

function XArchiveAwarenessData:_AddAwarenessSettingRedPointCountDicByType(_type,adds)
    if type(self.AwarenessSettingRedPointCountDic[_type]) ~= 'number' then
        self.AwarenessSettingRedPointCountDic[_type] = 0
    end
    self.AwarenessSettingRedPointCountDic[_type] = self.AwarenessSettingRedPointCountDic[_type] + adds
end

function XArchiveAwarenessData:_SetAwarenessSettingTotalRedPointCount(count)
    self.AwarenessSettingTotalRedPointCount = count
end

function XArchiveAwarenessData:_AddAwarenessSettingTotalRedPointCount(adds)
    self.AwarenessSettingTotalRedPointCount = self.AwarenessSettingTotalRedPointCount+adds
end
--endregion <<<----------------------------

return XArchiveAwarenessData