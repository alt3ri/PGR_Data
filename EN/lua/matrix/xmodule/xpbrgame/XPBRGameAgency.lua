local XFubenActivityAgency = require('XModule/XBase/XFubenActivityAgency')

---@class XPBRGameAgency : XFubenActivityAgency
---@field private _Model XPBRGameModel
local XPBRGameAgency = XClass(XFubenActivityAgency, "XPBRGameAgency", true)

XClassPartialRequire("XModule/XPBRGame/XPBRGameAgencyFight", "XPBRGameAgency")

function XPBRGameAgency:OnInit()
    self:RegisterActivityAgency()
    self:RegisterFuben(XEnumConst.FuBen.StageType.PBRGame)
    
    self.EnumConst = require('XModule/XPBRGame/XPBRGameEnumConst')
    self.EventId = require('XModule/XPBRGame/XPBRGameEventId')
    ---@type XPBRNetworkAgency
    self.NetworkAgency = self:AddSubAgency(require('XModule/XPBRGame/SubModules/Network/XPBRNetworkAgency'))
    
    self:FightPartialInit()
end

function XPBRGameAgency:InitRpc()

end

function XPBRGameAgency:InitEvent()
    self:FightPartialInitEvent()
end

function XPBRGameAgency:OnRelease()
    self:FightPartialRelease()
end

function XPBRGameAgency:ResetAll()
    self:FightPartialReset()
end

function XPBRGameAgency:ExOnSkip()
    if self:GetIsActivityOpen(true) then
        XLuaUiManager.Open('UiPBRMain')
        return true
    else
        return false
    end
end

function XPBRGameAgency:GetIsActivityOpen(needTips)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.PBRGame, true, needTips) then
        return false
    end

    if not self:ExCheckInTime() then
        if needTips then
            XUiManager.TipText('CommonActivityNotInTime')
        end
        return false
    end

    if not XTool.IsNumberValidEx(self._Model:GetActivityId()) then
        if needTips then
            XUiManager.TipText('CommonActivityNotInTime')
        end
        return false
    end
    
    return true
end

function XPBRGameAgency:GetIsStageUnlockById(stageId)
    local stageCfg = self._Model:GetTablePBRStageCfgById(stageId)

    if not stageCfg then
        return false
    end
    -- 先判断时间
    if not XFunctionManager.CheckInTimeByTimeId(stageCfg.TimeId, false) then
        local now = XTime.GetServerNowTimestamp()
        local startTime = XFunctionManager.GetStartTimeByTimeId(stageCfg.TimeId)

        if now < startTime then
            -- 返回具体开放的日期
            return false, XUiHelper.FormatTextEx(self._Model:GetClientPBRText('StageUnlockTimeFormat'), XUiHelper.GetTimeMonthDay(startTime))
        else
            -- 返回关卡已结束
            return false, self._Model:GetClientPBRText('StageLockOutDateDesc')
        end
    end
    
    -- 判断前置条件
    if XTool.IsNumberValidEx(stageCfg.PreStageId) then
        if not self:CheckPassedByStageId(stageCfg.PreStageId) then
            -- 返回需通关前置关卡
            local preStageCfg = self._Model:GetTablePBRStageCfgById(stageCfg.PreStageId)

            if preStageCfg then
                return false, XUiHelper.FormatTextEx(self._Model:GetClientPBRText('StageUnlockPreStageFormat'), preStageCfg.StageName)
            end
            
            return false
        end
    end
    
    return true
end

--- 判断关卡是否通关：完成所有目标
function XPBRGameAgency:CheckPassedByStageId(stageId)
    local stageRecord = self._Model:GetStageRecordById(stageId)

    if stageRecord then
        return stageRecord.IsPass
    end
    
    return false
end

function XPBRGameAgency:GetIsAnyStageIsPassed()
    local activityCfg = self._Model:GetCurActivityCfg()
    
    -- 按顺序找到第一个未通关的关卡id
    if activityCfg and not XTool.IsTableEmpty(activityCfg.StageIds) then
        for i, stageId in ipairs(activityCfg.StageIds) do
            if XMVCA.XPBRGame:GetIsStageUnlockById(stageId) then
                if XMVCA.XFuben:CheckStageIsPass(stageId) then
                    return true
                end
            end
        end
    end
    
    return false
end

--- 判断指定天赋节点是否可解锁
function XPBRGameAgency:GetIsNodeCanUnlock(nodeId)
    local nodeCfg = self._Model:GetTablePBRMetaProgressionCfgById(nodeId)

    if not nodeCfg then
        return false
    end

    -- 已解锁
    if self._Model.GeniusModel:GetIsNodeUnlock(nodeId) then
        return false
    end

    -- 前置节点未解锁
    if XTool.IsNumberValidEx(nodeCfg.PreNode) and not self._Model.GeniusModel:GetIsNodeUnlock(nodeCfg.PreNode) then
        return false, self._Model:GetClientPBRText('GeniusPreNodeUnlockTips')
    end

    -- 判断条件
    if XTool.IsNumberValidEx(nodeCfg.NodeCondition) then
        if not XConditionManager.CheckCondition(nodeCfg.NodeCondition) then
            return false, XConditionManager.GetConditionDescById(nodeCfg.NodeCondition)
        end
    end

    -- 判断是否有足够的货币进行解锁
    local curItemCount = self._Model:GetGeniusCoinCount()

    if curItemCount < nodeCfg.NodeCost then
        return false, self._Model:GetClientPBRText('GeniusNodeUnlockCostLimitTips')
    end

    return true
end

--- 获取某个天赋组的已解锁节点数量
function XPBRGameAgency:GetMetaNodeGroupUnlockCount(groupId)
    local groupCfg = self._Model:GetTablePBRMetaProgressionNodeGroupCfgById(groupId)

    if groupCfg and not XTool.IsTableEmpty(groupCfg.NodeIds) then
        local unlockCount = 0
        
        for i, nodeId in pairs(groupCfg.NodeIds) do
            if self._Model.GeniusModel:GetIsNodeUnlock(nodeId) then
                unlockCount = unlockCount + 1
            end
        end
        
        return unlockCount
    end
    
    
    return 0
end

--- 检查局内商店是否有可升阶的技能
--- 1. 合成升阶：商品中存在与已拥有技能相同且存在下一阶的技能
--- 2. 替换升阶：商品中的技能是已拥有技能的同组高阶
--- - **专门为引导开放的接口，涉及到局内配置表，约定只能在局内强化界面中判断**
---@param stageId number|nil @关卡Id，若指定则先判断当前关卡是否是目标关卡
---@return boolean
function XPBRGameAgency:CheckInGameShopAnyGoodsHigher(stageId)
    -- 先检查活动是否开启
    if not self:GetIsActivityOpen(false) then
        return false
    end

    -- 再判断是不是在局内
    if not self._Model:GetIsHasSegmentSettleData() then
        return false
    end
    
    -- 最后确定是在局内强化界面
    if not XLuaUiManager.IsUiShow("UiPBRShopNew") then
        return false
    end

    -- 如果指定了关卡Id，检查当前关卡是否匹配
    if XTool.IsNumberValidEx(stageId) then
        local curStageId = self._Model:GetStageIdInSegmentSettleData()
        if curStageId ~= stageId then
            return false
        end
    end

    -- 获取商店商品列表
    local sellItemIds = self._Model:GetShopSellItemIds()

    if XTool.IsTableEmpty(sellItemIds) then
        return false
    end

    -- 遍历商店商品，检查是否有可升阶的技能
    for _, shopItemId in pairs(sellItemIds) do
        local shopItemCfg = self._Model:GetTablePBRItemCfgById(shopItemId)

        -- 只检查技能类型
        if shopItemCfg and shopItemCfg.ItemType == XMVCA.XPBRGame.EnumConst.ItemType.Skill then
            -- 跳过已选择的商品
            if not self._Model:GetIsItemChoseByItemId(shopItemId) then
                -- 1. 合成升阶：玩家已拥有该技能，且存在下一阶
                if self:_CheckSkillCanMergeUpgrade(shopItemId, shopItemCfg) then
                    return true
                end

                -- 2. 替换升阶：玩家拥有同组低阶技能
                if self:_CheckSkillCanReplaceUpgrade(shopItemId, shopItemCfg) then
                    return true
                end
            end
        end
    end

    return false
end

--- 检查技能是否可以合成升阶（玩家已拥有该技能，且存在下一阶）
---@param shopItemId number 商店道具Id
---@param shopItemCfg table 商店道具配置
---@return boolean
function XPBRGameAgency:_CheckSkillCanMergeUpgrade(shopItemId, shopItemCfg)
    -- 检查玩家是否已拥有该道具
    if not self._Model:CheckIsHasItemInSegmentSettleData(shopItemId) then
        return false
    end

    -- 检查是否存在下一阶
    if not XTool.IsNumberValidEx(shopItemCfg.OrbGroup) then
        return false
    end

    local itemGroupCfg = self._Model:GetTablePBRItemGroupCfgById(shopItemCfg.OrbGroup)

    if not itemGroupCfg or XTool.IsTableEmpty(itemGroupCfg.ItemIds) then
        return false
    end

    -- 查找是否存在比当前高一阶的道具
    for _, id in pairs(itemGroupCfg.ItemIds) do
        if id ~= shopItemId then
            local otherItemCfg = self._Model:GetTablePBRItemCfgById(id)
            if otherItemCfg and (otherItemCfg.ItemTier - shopItemCfg.ItemTier) == 1 then
                return true
            end
        end
    end

    return false
end

--- 检查技能是否可以替换升阶（玩家拥有同组低阶技能）
---@param shopItemId number 商店道具Id
---@param shopItemCfg table 商店道具配置
---@return boolean
function XPBRGameAgency:_CheckSkillCanReplaceUpgrade(shopItemId, shopItemCfg)
    if not XTool.IsNumberValidEx(shopItemCfg.OrbGroup) then
        return false
    end

    local itemGroupCfg = self._Model:GetTablePBRItemGroupCfgById(shopItemCfg.OrbGroup)

    if not itemGroupCfg or XTool.IsTableEmpty(itemGroupCfg.ItemIds) then
        return false
    end

    -- 遍历同组所有道具，检查玩家是否拥有比商店道具低阶的技能
    for _, id in pairs(itemGroupCfg.ItemIds) do
        if id ~= shopItemId then
            local ownedItemCfg = self._Model:GetTablePBRItemCfgById(id)
            if ownedItemCfg and (shopItemCfg.ItemTier - ownedItemCfg.ItemTier) >= 1 then
                -- 检查玩家是否拥有这个低阶技能
                if self._Model:CheckIsHasItemInSegmentSettleData(id) then
                    return true
                end
            end
        end
    end

    return false
end

--region 红点相关

--- 是否有任意关卡新开放
function XPBRGameAgency:ReddotIsAnyStageNewUnlock()
    local curActCfg = self._Model:GetCurActivityCfg()

    if curActCfg then
        if not XTool.IsTableEmpty(curActCfg.StageIds) then
            for _, stageId in ipairs(curActCfg.StageIds) do
                if self:ReddotIsStageNewUnlockById(stageId) then
                    return true
                end
            end
        end
    end
    
    return false
end

--- 指定关卡是否新开放
function XPBRGameAgency:ReddotIsStageNewUnlockById(stageId)
    -- 首先需要已解锁
    if not self:GetIsStageUnlockById(stageId) then
        return false
    end
    
    -- 其次忽略已通关
    if self:CheckPassedByStageId(stageId) then
        return false
    end
    
    -- 接着查本地缓存
    return not self._Model:ReddotGetIsMarkStage(stageId)
end

--- 是否有任意天赋可解锁
function XPBRGameAgency:ReddotIsAnyGeniusNodeCanUnlock()
    local nodeCfgs = self._Model:GetTablePBRMetaProgressionCfgs()

    if nodeCfgs then
        --todo 考虑做一个安全的缓存，避免每次遍历进行复杂判断
        for _, nodeCfg in pairs(nodeCfgs) do
            local canUnlock, _ = self:GetIsNodeCanUnlock(nodeCfg.NodeId)

            if canUnlock then
                return true
            end
        end
    end
end

--- 是否有任意任务可领取奖励
function XPBRGameAgency:ReddotIsAnyTaskAchieved()
    local curActCfg = self._Model:GetCurActivityCfg()

    if curActCfg then
        if not XTool.IsTableEmpty(curActCfg.TaskGroupIds) then
            for _, taskGroupId in ipairs(curActCfg.TaskGroupIds) do
                if self:ReddotIsTaskGroupAchieved(taskGroupId) then
                    return true
                end
            end
        end
    end
    
    return false
end

--- 指定任务组中是否有任务可领取奖励
function XPBRGameAgency:ReddotIsTaskGroupAchieved(taskGroupId)
    local groupCfg = self._Model:GetTablePBRTaskGroupCfgById(taskGroupId)

    if not groupCfg then
        return false
    end

    if groupCfg.GroupType == XMVCA.XPBRGame.EnumConst.TaskGroupType.TaskId then
        for _, taskId in ipairs(groupCfg.TaskIds) do
            if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                return true
            end
        end
    elseif groupCfg.GroupType == XMVCA.XPBRGame.EnumConst.TaskGroupType.TaskTimeLimitId then
        -- 约定是任务组时，只取数组顺位第一个Id
        local timelimitTaskId = groupCfg.TaskIds[1]
        return XDataCenter.TaskManager.CheckTimeLimitTaskAnyCanFinishByGroupId(timelimitTaskId)
    else
        XLog.Error('PBRTaskGroup错误的GroupType配置，groupId:' .. taskGroupId .. ', GroupType:' .. tostring(groupCfg.GroupType))
    end
    
    return false
end
--endregion

return XPBRGameAgency