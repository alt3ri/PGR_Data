local tableInsert = table.insert
local tableSort = table.sort

---@class XMainLineLuosaitaControl : XControl
---@field private _Model XMainLineLuosaitaModel
local XMainLineLuosaitaControl = XClass(XControl, "XMainLineLuosaitaControl")

function XMainLineLuosaitaControl:OnInit()
    
end

function XMainLineLuosaitaControl:AddAgencyEvent()
    
end

function XMainLineLuosaitaControl:RemoveAgencyEvent()

end

function XMainLineLuosaitaControl:OnRelease()
    
end

--region Config

---@return XMainLineLuosaitaConfig
function XMainLineLuosaitaControl:GetConfig()
    return self._Model:GetConfig()
end

--endregion

--region RpcData

-- 获取阶段数据
---@return XMainLineLuosaitaSection
function XMainLineLuosaitaControl:GetSectionInfo(sectionId)
    return self._Model:GetSectionInfo(sectionId)
end

-- 获取阶段数据哈希表
---@return table<number, XMainLineLuosaitaSection>
function XMainLineLuosaitaControl:GetSectionInfoDic()
    return self._Model:GetSectionInfoDic()
end

--endregion

--region 空花入口

function XMainLineLuosaitaControl:GetSkyGardenEntryTaskId()
    if self._SkyGardenEntryTaskId and self._SkyGardenEntryTaskId > 0 then
        return self._SkyGardenEntryTaskId
    end
    local taskId = self:GetConfig():GetConfigNumber("SkyGardenEntry", 1)
    self._SkyGardenEntryTaskId = taskId
    return taskId
end

function XMainLineLuosaitaControl:GetSkyGardenEntryTitleAndDesc()
    local title, desc = self:GetConfig():GetConfigString("SkyGardenEntry", 2), self:GetConfig():GetConfigString("SkyGardenEntry", 3)
    return title, XUiHelper.ReplaceTextNewLine(desc)
end

function XMainLineLuosaitaControl:GetSkyGardenEntryConditionId()
    if self._SkyGardenEntryConditionId and self._SkyGardenEntryConditionId > 0 then
        return self._SkyGardenEntryConditionId
    end
    local conditionId = self:GetConfig():GetConfigNumber("SkyGardenEntryCondition", 1)
    self._SkyGardenEntryConditionId = conditionId
    return conditionId
end

function XMainLineLuosaitaControl:GetSkyGardenEntryRewardId()
    if self._SkyGardenEntryRewardId and self._SkyGardenEntryRewardId > 0 then
        return self._SkyGardenEntryRewardId
    end
    local rewardId = self:GetConfig():GetConfigNumber("SkyGardenEntryRewardId", 1)
    self._SkyGardenEntryRewardId = rewardId
    return rewardId
end

--endregion 空花入口

--region 阶段
-- 阶段是否完成
function XMainLineLuosaitaControl:IsSectionFinish(sectionId)
    local sectionInfo = self:GetSectionInfo(sectionId)
    if not sectionInfo then
        return false
    end
    
    return sectionInfo:IsFinish()
end

-- 阶段是否已解锁
function XMainLineLuosaitaControl:IsSectionUnlock(sectionId)
    if sectionId == XMVCA.XMainLineLuosaita.EnumConst.FIRST_SECTION_ID then
        return true
    end
    local lastSectionId = sectionId - 1
    return self:IsSectionFinish(lastSectionId)
end

-- 获取解锁的阶段Id列表
function XMainLineLuosaitaControl:GetUnlockSectionIds()
    local result = {}
    local sectionConfigs = self:GetConfig():GetConfigSections()
    for _, sectionConfig in pairs(sectionConfigs) do
        local sectionId = sectionConfig.Id
        if self:IsSectionUnlock(sectionId) then
            tableInsert(result, sectionId)
        end
    end
    return result
end

-- 获取进入玩法需要显示的章节Id
function XMainLineLuosaitaControl:GetEnterSectionId()
    local sectionConfigs = self:GetConfig():GetConfigSections()
    for _, sectionConfig in ipairs(sectionConfigs) do
        local sectionId = sectionConfig.Id
        local sectionInfo = self:GetSectionInfo(sectionId)
        if not sectionInfo then
            return sectionId
        elseif not sectionInfo:IsFinish() or not sectionInfo:IsAllDocUse() then
            return sectionId
        end
    end
    return sectionConfigs[#sectionConfigs].Id
end

-- 获取解锁的移动配置表
---@return XTableMainLineLuosaitaCharacterMove
function XMainLineLuosaitaControl:GetUnlockMoveConfig(sectionId)
    ---@type XTableMainLineLuosaitaCharacterMove[]
    local result = {}
    local sectionInfo = self:GetSectionInfo(sectionId)
    local charIdDic = sectionInfo:GetCharacterIdDic()
    local moveConfigs = self:GetConfig():GetConfigCharacterMoves()
    for _, config in pairs(moveConfigs) do
        if charIdDic[config.CharacterId] and not sectionInfo:IsMoveComplete(config.Id) then
            local isReach, desc = XConditionManager.CheckCondition(config.ConditionId)
            if isReach then
                tableInsert(result, config)
            end
        end
    end
    if #result > 0 then
        tableSort(result, function(a, b) 
            return a.Id < b.Id
        end)
        return result[1]
    end
end

-- 获取阶段的所有文件
function XMainLineLuosaitaControl:GetSectionDocIds(sectionId)
    local docIds = {}
    local positionConfigs = self:GetConfig():GetConfigPositionsBySectionId(sectionId)
    for _, config in pairs(positionConfigs) do
        local ids
        if config.Type == XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.ENEMY then
            ids = self:GetConfig():GetEnemyDocIds(config.MemberId)
        elseif config.Type == XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.STAGE then
            ids = self:GetConfig():GetStageDocIds(config.MemberId)
        end
        if ids and #ids > 0 then
            for _, id in pairs(ids) do
                tableInsert(docIds, id)
            end
        end
    end
    return docIds
end

-- 获取阶段的通讯Id
function XMainLineLuosaitaControl:GetSectionMessageId(sectionId)
    local messageIds = {}
    local sectionInfo = self:GetSectionInfo(sectionId)
    local armyPosInfos = sectionInfo:GetPositionInfosByType(XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.ARMY)
    local posInfoDic = sectionInfo:GetPositionInfoDic()
    for _, posInfo in pairs(posInfoDic) do
        local enemyId = posInfo:GetEnemyId()
        if posInfo:IsEnemy() then
            for _, armyPosInfo in ipairs(armyPosInfos) do
                local isCanMove, tips = self:IsCanMovePosition(armyPosInfo, posInfo)
                if isCanMove then
                    local messageId = self:GetConfig():GetEnemyMessageId(enemyId)
                    if XTool.IsNumberValidEx(messageId) then
                        tableInsert(messageIds, messageId)
                    end
                    break
                end
            end
        elseif posInfo:IsStage() then
            local stageId = posInfo:GetStageId()
            local isStagePass = XMVCA.XFuben:CheckStageIsPass(stageId)
            if not isStagePass and self:IsStageUnlock(stageId) and self:IsStageShow(stageId) then
                local messageId = self:GetConfig():GetStageMessageId(stageId)
                if XTool.IsNumberValidEx(messageId) then
                    tableInsert(messageIds, messageId)
                end
            end
        end
    end
    
    -- 排序
    if #messageIds > 0 then
        tableSort(messageIds, function(a, b)  
            local orderA = self:GetConfig():GetMessageOrder(a)
            local orderB = self:GetConfig():GetMessageOrder(b)
            return orderA < orderB
        end)
    end
    
    return messageIds[1]
end

-- 敌军是否可以被攻击
function XMainLineLuosaitaControl:IsEnemyCanAttack(sectionId, enemyInfo)
    local sectionInfo = self:GetSectionInfo(sectionId)
    local armyPosInfos = sectionInfo:GetPositionInfosByType(XMVCA.XMainLineLuosaita.EnumConst.POS_TYPE.ARMY)
    for _, armyPosInfo in pairs(armyPosInfos) do
        local isCanMove, tips = self:IsCanMovePosition(armyPosInfo, enemyInfo)
        if isCanMove then
            return true
        end
    end
    return false
end
--endregion

--region 块
-- 块是否全部通过
function XMainLineLuosaitaControl:IsBlockPassed(blockId)
    local posConfigs = self._Model:GetConfig():GetConfigPositionsByBlockId(blockId)
    for _, posConfig in pairs(posConfigs) do
        if not self:IsPositionPassed(posConfig.Id) then
            return false
        end
    end
    return true
end

-- 地块是否相邻
function XMainLineLuosaitaControl:IsEdgeBlock(curBlockId, targetBlockId)
    local edgeBlocks = self:GetConfig():GetBlockEdgeBlocks(curBlockId)
    for _, blockId in pairs(edgeBlocks)do
        if targetBlockId == blockId then
            return true
        end
    end
    return false
end
--endregion

--region 位置
-- 获取位置数据
---@param posId number 位置Id
---@return XMainLineLuosaitaPositionInfo
function XMainLineLuosaitaControl:GetPositionInfo(posId)
    return self._Model:GetPositionInfo(posId)
end

-- 获取位置的当前血量
---@param posId number 位置Id
function XMainLineLuosaitaControl:GetPositionCurHp(posId)
    local posInfo = self:GetPositionInfo(posId)
    if not posInfo then return 0 end
    
    return posInfo:GetCurHp()
end

-- 获取位置的攻击力
---@param posId number 位置Id
function XMainLineLuosaitaControl:GetPositionCurAttack(posId)
    local posInfo = self:GetPositionInfo(posId)
    if not posInfo then return 0 end
    
    local attack = posInfo:GetExtraAttack()
    if posInfo:IsArmy() then
        local armyId = posInfo:GetArmyId()
        attack = attack + self._Model:GetConfig():GetArmyAttack(armyId)
    elseif posInfo:IsEnemy() then
        local enemyId = posInfo:GetEnemyId()
        attack = attack + self._Model:GetConfig():GetEnemyAttack(enemyId)
    end
    return attack
end

-- 位置是否通过
function XMainLineLuosaitaControl:IsPositionPassed(posId)
    local posInfo = self:GetPositionInfo(posId)
    return self:IsPositionInfoPassed(posInfo)
end

-- 位置是否通过
---@param posInfo XMainLineLuosaitaPositionInfo
function XMainLineLuosaitaControl:IsPositionInfoPassed(posInfo)
    if not posInfo or posInfo:IsArmy() or posInfo:IsCharacter() then
        return true
    elseif posInfo:IsEnemy() then
        return false
    elseif posInfo:IsStage() then
        local stageId = posInfo:GetStageId()
        return XMVCA.XMainLine2:IsStagePass(stageId)
    end
    return false
end

-- 是否可移动位置
---@param startPosInfo XMainLineLuosaitaPositionInfo
---@param endPosInfo XMainLineLuosaitaPositionInfo
function XMainLineLuosaitaControl:IsCanMovePosition(startPosInfo, endPosInfo)
    local startBlockId = startPosInfo:GetBlockId()
    local endBlockId = endPosInfo:GetBlockId()
    
    -- 不同地块
    if startBlockId ~= endBlockId then
        -- 当前地块未通关不可移去其他地块
        if not self:IsBlockPassed(startBlockId) then
            return false, self:GetConfig():GetConfigString("DragTips2", 1)
        end

        -- 目标地块的所有相邻地块均未占领
        local isEdgPassed = false
        local edgBlockIds = self._Model:GetConfig():GetBlockEdgeBlocks(endBlockId)
        for _, edgBlockId in pairs(edgBlockIds) do
            if self:IsBlockPassed(edgBlockId) then
                isEdgPassed = true
                break
            end
        end
        if not isEdgPassed then
            return false, self:GetConfig():GetConfigString("DragTips6", 1)
        end
    end
    
    -- 指定友军才可攻击
    if endPosInfo:IsEnemy() and startPosInfo:IsArmy() then
        local enemyId = endPosInfo:GetEnemyId()
        local challengeArmyId = self:GetConfig():GetEnemyChallengeArmyId(enemyId)
        if challengeArmyId ~= 0 and challengeArmyId ~= startPosInfo:GetArmyId() then
            return false, self:GetConfig():GetEnemyChallengeArmyTips(enemyId)
        end
    end

    -- 友军攻击力 < 敌军血量
    local armyCurAttack = self:GetPositionCurAttack(startPosInfo:GetPosId())
    local enemyCurHp = self:GetPositionCurHp(endPosInfo:GetPosId())
    if armyCurAttack < enemyCurHp then
        return false, self:GetConfig():GetConfigString("DragTips5", 1)
    end
    
    return true
end
--endregion

--region 关卡
-- 关卡是否显示
function XMainLineLuosaitaControl:IsStageShow(stageId)
    local conditionId = self._Model:GetConfig():GetStageConditionId(stageId)
    if XTool.IsNumberValidEx(conditionId) then
        local isShow, _ = XConditionManager.CheckCondition(conditionId)
        return isShow
    end
    return true
end

-- 关卡是否解锁
function XMainLineLuosaitaControl:IsStageUnlock(stageId)
    return XMVCA.XMainLine2:IsStageUnlock(stageId)
end
--endregion

--region 敌军
function XMainLineLuosaitaControl:IsEnemyShow(enemyId)
    local showConditionId = self:GetConfig():GetEnemyShowConditionId(enemyId)
    if XTool.IsNumberValidEx(showConditionId) then
        local isShow, desc = XConditionManager.CheckCondition(showConditionId)
        return isShow
    end
    return true
end
--endregion

return XMainLineLuosaitaControl