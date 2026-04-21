--- 图鉴控制器
---@class XPBRCollectionControl : XControl
---@field private _Model XPBRGameModel
---@field _MainControl XPBRGameControl
local XPBRCollectionControl = XClass(XControl, "XPBRCollectionControl")

function XPBRCollectionControl:OnInit()

end

function XPBRCollectionControl:AddAgencyEvent()

end

function XPBRCollectionControl:RemoveAgencyEvent()

end

function XPBRCollectionControl:OnRelease()
    self._Type2ItemParams = nil
end

--region Configs

function XPBRCollectionControl:GetTablePBRarchiveMonsterCfgById(id)
    return self._Model:GetTablePBRArchiveMonsterById(id)
end

function XPBRCollectionControl:GetTableStatusNameById(statusId)
    local statusCfg = self._Model:GetTablePBRStatsDescCfgById(statusId)

    if statusCfg then
        return statusCfg.StatsName
    end

    return ''
end

--endregion

function XPBRCollectionControl:InitOnEnterCollections()
    self._Type2ItemParams = {}
    self._Type2CollectionRadito = {} -- 收集率

    -- 初始化道具
    local itemCfgs = self._Model:GetTablePBRItemCfgs()

    if not XTool.IsTableEmpty(itemCfgs) then
        for i, cfg in pairs(itemCfgs) do

            if cfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Other then
                local itemParams = self._Type2ItemParams[cfg.ItemType] or {}
                
                ---@type XPBRCollectionItemParam
                local itemParamData = {
                    Id = cfg.ItemId,
                    TabType = cfg.ItemType,
                    Icon = cfg.Icon,
                    IsUnlock = self._Model.CollectionModel:GetIsItemUnlockInCollection(cfg.ItemId),
                    UnlockTime = self._Model.CollectionModel:GetItemUnlockTime(cfg.ItemId),
                    IconQuality = XArrangeConfigs.GeQualityPath(cfg.ItemTier)
                }

                table.insert(itemParams, itemParamData)
                self._Type2ItemParams[cfg.ItemType] = itemParams
            end
        end
    end

    -- 初始化技能组
    local skillGroupCfgs = self._Model:GetTablePBRSkillGroupDescCfgs()

    if not XTool.IsTableEmpty(skillGroupCfgs) then
        for i, cfg in pairs(skillGroupCfgs) do
            local itemParams = self._Type2ItemParams[XMVCA.XPBRGame.EnumConst.Collections.TabType.Skill] or {}
            
            ---@type XPBRCollectionItemParam
            local itemParamData = {
                Id = cfg.Id,
                TabType = XMVCA.XPBRGame.EnumConst.Collections.TabType.Skill,
                Icon = cfg.Icon,
                IsUnlock = self:_GetIsSkillGroupUnlock(cfg.Id),
                IsGroupId = true,
                UnlockTime = self:_GetSkillGroupUnlockTime(cfg.Id),
            }

            table.insert(itemParams, itemParamData)
            self._Type2ItemParams[XMVCA.XPBRGame.EnumConst.Collections.TabType.Skill] = itemParams
        end
    end
    
    -- 初始化敌人
    local monsterCfgs = self._Model:GetTablePBRArchiveMonsterCfgs()

    if not XTool.IsTableEmpty(monsterCfgs) then
        for i, cfg in pairs(monsterCfgs) do
            local itemParams = self._Type2ItemParams[XMVCA.XPBRGame.EnumConst.Collections.TabType.Monster] or {}
            
            ---@type XPBRCollectionItemParam
            local itemParamData = {
                Id = cfg.Id,
                TabType = XMVCA.XPBRGame.EnumConst.Collections.TabType.Monster,
                Icon = cfg.Icon,
                IsUnlock = self._Model.CollectionModel:GetIsMonsterUnlockInCollection(cfg.Id),
                UnlockTime = self._Model.CollectionModel:GetMonsterUnlockTime(cfg.Id),
            }

            table.insert(itemParams, itemParamData)
            self._Type2ItemParams[XMVCA.XPBRGame.EnumConst.Collections.TabType.Monster] = itemParams
        end
    end
    
    
    -- 初始化收集率
    if not XTool.IsTableEmpty(self._Type2ItemParams) then
        for i, itemParams in pairs(self._Type2ItemParams) do
            if not XTool.IsTableEmpty(itemParams) then
                local count = 0
                local unlockCount = 0

                for _, data in pairs(itemParams) do
                    count = count + 1

                    if data.IsUnlock then
                        unlockCount = unlockCount + 1
                    end
                end

                if count > 0 then
                    self._Type2CollectionRadito[i] = unlockCount / count
                else
                    self._Type2CollectionRadito[i] = 0
                end
            end
        end
    end
end

function XPBRCollectionControl:ReleaseOnExitCollections()
    self._Type2ItemParams = nil
end

--- 根据类型获取对应数据
function XPBRCollectionControl:GetCollectionItemList(tabType, isSort, sortType)
    local itemParams = self._Type2ItemParams[tabType]

    if not XTool.IsTableEmpty(itemParams) then
        if isSort then
           if sortType == XMVCA.XPBRGame.EnumConst.Collections.SortType.Default then
               ---@param a XPBRCollectionItemParam
               ---@param b XPBRCollectionItemParam
                table.sort(itemParams, function(a, b)
                    -- 默认排序按Id升序
                    return a.Id < b.Id
                end)
            elseif sortType == XMVCA.XPBRGame.EnumConst.Collections.SortType.UnlockTime then
               ---@param a XPBRCollectionItemParam
               ---@param b XPBRCollectionItemParam
                table.sort(itemParams, function(a, b)
                    return a.UnlockTime < b.UnlockTime
                end)
            elseif sortType == XMVCA.XPBRGame.EnumConst.Collections.SortType.Quality then
                -- 目前只限定道具类型
               if tabType == XMVCA.XPBRGame.EnumConst.Collections.TabType.Other then
                   ---@param a XPBRCollectionItemParam
                   ---@param b XPBRCollectionItemParam
                    table.sort(itemParams, function(a, b)
                        local aCfg = self._Model:GetTablePBRItemCfgById(a.Id)
                        local bCfg = self._Model:GetTablePBRItemCfgById(b.Id)

                        local aQuality = aCfg and aCfg.ItemTier or 0
                        local bQuality = bCfg and bCfg.ItemTier or 0

                        if aQuality ~= bQuality then
                            return aQuality > bQuality
                        end

                        return a.Id < b.Id
                    end)
               end
            end
        end
    end
    
    return itemParams
end

--- 获取指定类型的收集率
function XPBRCollectionControl:GetCollectionRadio(tabType)
    local percent = self._Type2CollectionRadito[tabType] or 0
    local percentStr = string.format('%.1f', percent * 100)
    return XUiHelper.FormatTextEx(self._Model:GetClientPBRText('CollectionPercentShowFormat'), percentStr)
end

--- 获得指定图鉴内容的详情信息
---@param params XPBRCollectionItemParam
function XPBRCollectionControl:GetCollectionDetail(params, type)
    self:_ResetCollectionDetailData()
    
    if type == XMVCA.XPBRGame.EnumConst.Collections.TabType.Monster then
        local monsterCfg = self._Model:GetTablePBRArchiveMonsterById(params.Id)

        if monsterCfg then
            ---@type XPBRCollectionMonsterDetailParam
            local collectionDetailData = self._CollectionDetailData

            collectionDetailData.Name = monsterCfg.Name
            collectionDetailData.BaseDesc = XUiHelper.ReplaceTextNewLine(monsterCfg.BaseDesc)
            collectionDetailData.StatusDict = monsterCfg.StatusDict
            collectionDetailData.UpgradeDesc = XUiHelper.ReplaceTextNewLine(monsterCfg.UpgradeDesc)
        end
    else
        if params.IsGroupId then
            if params.TabType == XMVCA.XPBRGame.EnumConst.Collections.TabType.Skill then
                local skillGroupCfg = self._Model:GetTablePBRSkillGroupDescCfgById(params.Id)

                if skillGroupCfg then
                    ---@type XPBRCollectionSkillDetailParam
                    local collectionDetailData = self._CollectionDetailData

                    collectionDetailData.Name = skillGroupCfg.Name
                    collectionDetailData.BaseDesc = XUiHelper.ReplaceTextNewLine(skillGroupCfg.BaseDesc)
                    collectionDetailData.LevelStrList = skillGroupCfg.LevelDescList
                end
            end
        else
            local itemCfg = self._Model:GetTablePBRItemCfgById(params.Id)

            if itemCfg then
                self._CollectionDetailData.Name = itemCfg.ItemName
                self._CollectionDetailData.BaseDesc = XUiHelper.ReplaceTextNewLine(itemCfg.ItemDesc)
            end
        end
    end
    
    return self._CollectionDetailData
end

function XPBRCollectionControl:_ResetCollectionDetailData()
    if self._CollectionDetailData == nil then
        ---@type XPBRCollectionItemDetailParamBase
        self._CollectionDetailData = {}
        self._CollectionDetailData.SummaryDatas = {}
    else
        -- 清空统计信息
        if not XTool.IsTableEmpty(self._CollectionDetailData.SummaryDatas) then
            for i, v in pairs(XMVCA.XPBRGame.EnumConst.Collections.SummaryDataType) do
                self._CollectionDetailData.SummaryDatas[v] = nil
            end
        end
    end
end

function XPBRCollectionControl:_GetIsSkillGroupUnlock(groupId)
    local isUnLock = false

    -- 检查组内是否有任意技能解锁
    local groupCfg = self._Model:GetTablePBRItemGroupCfgById(groupId)

    if groupCfg then
        for i, v in pairs(groupCfg.ItemIds) do
            if self._Model.CollectionModel:GetIsItemUnlockInCollection(v) then
                isUnLock = true
                break
            end
        end
    end
    
    return isUnLock
end

function XPBRCollectionControl:_GetSkillGroupUnlockTime(groupId)
    local unlockTime = math.maxinteger

    -- 检查组内是否有任意技能解锁
    local groupCfg = self._Model:GetTablePBRItemGroupCfgById(groupId)

    if groupCfg then
        for i, v in pairs(groupCfg.ItemIds) do
            if self._Model.CollectionModel:GetIsItemUnlockInCollection(v) then
                local tmpUnlockTime = self._Model.CollectionModel:GetItemUnlockTime(v)

                if tmpUnlockTime < unlockTime then
                    unlockTime = tmpUnlockTime
                end
            end
        end
    end

    return unlockTime
end

function XPBRCollectionControl:_GetSkillTotalTriggerTimesByGroup(groupId)
    local totalTimes = 0

    -- 检查组内是否有任意技能解锁
    local groupCfg = self._Model:GetTablePBRItemGroupCfgById(groupId)

    if groupCfg then
        for i, v in pairs(groupCfg.ItemIds) do
            local times = self._Model.CollectionModel:GetItemTriggerNum(v)
            
            totalTimes = totalTimes + times
        end
    end
    
    return totalTimes
end

return XPBRCollectionControl

--- 图鉴中的道具项信息
---@class XPBRCollectionItemParam
---@field Id
---@field TabType
---@field Icon string @图片路径
---@field IsUnlock boolean @该道具是否解锁图鉴
---@field IconQuality string @品质图片路径
---@field IsGroupId boolean @Id是不是组Id
---@field UnlockTime number @解锁时间戳

--- 图鉴中的道具详细信息基类
---@class XPBRCollectionItemDetailParamBase
---@field Name string
---@field SummaryDatas table<number, number> @统计信息，key是统计类型，value是统计值
---@field BaseDesc string @基本描述

--- 图鉴中的技能详细信息
---@class XPBRCollectionSkillDetailParam: XPBRCollectionItemDetailParamBase
---@field LevelStrList string[] @各阶级效果描述文本列表

--- 图鉴中的怪物详细信息
---@class XPBRCollectionMonsterDetailParam: XPBRCollectionItemDetailParamBase
---@field StatusDict table<number, number> @状态信息，key是状态类型，value是状态值
---@field UpgradeDesc string @进化描述