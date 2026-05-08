local XFubenActivityAgency = require('XModule/XBase/XFubenActivityAgency')

---@class XGameCollectionAgency : XFubenActivityAgency
---@field private _Model XGameCollectionModel
local XGameCollectionAgency = XClass(XFubenActivityAgency, "XGameCollectionAgency")


function XGameCollectionAgency:OnInit()
end

function XGameCollectionAgency:InitRpc()
    XRpc.NotifyGameCollectionData = handler(self, self.NotifyGameCollectionData)
end

function XGameCollectionAgency:InitEvent()
end

function XGameCollectionAgency:OpenMainUi()
    self:_ShowCollectionMainUi(false)
end

function XGameCollectionAgency:NotifyGameCollectionData(data)
    self._Model:SetActivityId(data.GameCollectionData.ActivityId)
    self._Model:UpdateGameData(data.GameCollectionData.GameData)
end

function XGameCollectionAgency:IsLaunchedFromCollection(gameType)
    if not XTool.IsNumberValid(gameType) then
        return true
    end

    return self:GetLaunchContext().GameType == gameType
end

function XGameCollectionAgency:OnGameExitToCollection(gameType, exitInfo)
    if not XTool.IsNumberValid(gameType) or not self:IsLaunchedFromCollection(gameType) then
        return false
    end

    local function NormalizeExitInfo(exitInfo)
        if type(exitInfo) == "number" then
            return {
                Score = exitInfo,
            }
        end

        return exitInfo or {}
    end
    local gameCfg = self._Model:GetGameCollectionCfgById(gameType)
    local record = self:_BuildExitRecord(gameType, gameCfg, NormalizeExitInfo(exitInfo))

    self._Model:SetSelectedGameType(gameType)
    self._Model:SetPendingExitRecord(record)
    self:ClearLaunchContext()

    return true
end

function XGameCollectionAgency:_BuildExitRecord(gameType, gameCfg, exitInfo)
    if XTool.IsTableEmpty(gameCfg) then
        return nil
    end

    if gameType == XEnumConst.GameCollection.GameType.Game2048 then
        local snapshot = self._Model:GetGameSnapshot(gameType)
        local enterMaxScore = snapshot and snapshot.EnterMaxScore or 0
        local score = exitInfo.Score or 0
        if score > enterMaxScore then
            return {
                GameName = gameCfg.Name,
                NewScore = score,
            }
        end
        return nil
    end

    if gameType == XEnumConst.GameCollection.GameType.FangKong and exitInfo.IsNewScoreRecord then
        return {
            GameName = gameCfg.Name,
            NewScore = exitInfo.Score or 0,
        }
    end
end

function XGameCollectionAgency:SetLaunchContext(gameType, stageId)
    self._LaunchContext = {
        GameType = gameType,
        StageId = stageId or 0,
    }
end

function XGameCollectionAgency:GetLaunchContext()
    return self._LaunchContext
end

function XGameCollectionAgency:ClearLaunchContext()
    self._LaunchContext = nil
end

function XGameCollectionAgency:BackToMainUiIfNeeded()
    self:_ShowCollectionMainUi(true)
end

function XGameCollectionAgency:_ShowCollectionMainUi(usePopThenOpen)
    if usePopThenOpen then
        XLuaUiManager.PopThenOpen("UiMiniGamesCollectionMain")
    else
        XLuaUiManager.Open("UiMiniGamesCollectionMain")
    end
end

function XGameCollectionAgency:CheckActivityTips()
    if self._HasEnteredRewardShopThisLaunch then
        return false
    end
    local remainDays = tonumber(self:GetGameCollectionConfig("RedPointRemainDays")) or 0
    if remainDays <= 0 then
        return false
    end
    local activityId = self._Model:GetActivityId()
    if not activityId then
        return false
    end
    local activityCfg = self._Model:GetGameCollectionActivityCfgById(activityId)
    local endTime = activityCfg and XFunctionManager.GetEndTimeByTimeId(activityCfg.TimeId) or 0
    if endTime <= 0 then
        return false
    end
    if (endTime - XTime.GetServerNowTimestamp()) > remainDays * CS.XDateUtil.ONE_DAY_SECOND then
        return false
    end
    return true
end

function XGameCollectionAgency:HasRewardCanGet()
    -- 1. 检查任务是否有可领取奖励
    local taskTimeLimitIds = self._Model:GetGameCollectionTaskCfgs()
    if not XTool.IsTableEmpty(taskTimeLimitIds) then
        for _, taskTimeLimitId in pairs(taskTimeLimitIds) do
            local timeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(taskTimeLimitId)
            if timeLimitCfg and XFunctionManager.CheckInTimeByTimeId(timeLimitCfg.TimeId) then
                local taskList = XDataCenter.TaskManager.GetTimeLimitTaskListByGroupId(taskTimeLimitId)
                for _, taskData in pairs(taskList) do
                    if taskData.State == XDataCenter.TaskManager.TaskState.Achieved then
                        return true
                    end
                end
            end
        end
    end
    return false
end

function XGameCollectionAgency:GetGameCollectionConfig(key, index)
    local config = self._Model:GetGameCollectionConfig(key)
    if config then
        if not XTool.IsNumberValid(index) then
            return config.Values[1]
        end
        return config.Values[index]
    end
    return nil
end

function XGameCollectionAgency:MarkRewardShopEntered()
    self._HasEnteredRewardShopThisLaunch = true
end

function XGameCollectionAgency:HasGoodCanBuy()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, false) then
        return false
    end
    local config = self._Model:GetGameCollectionConfig("shopId")
    local shopId = tonumber(config.Values[1])
    if not self.IsCheckShopInfo then
        self.IsCheckShopInfo = true
        XShopManager.RequestShopValidInfo({shopId}, nil)
        return false
    end
    if XTool.IsNumberValid(shopId) and XShopManager.IsShopOpen(shopId) then
        local goods = XShopManager.GetShopGoodsList(shopId, true)
        if #goods == 0 then
            -- XLog.Warning("本次请求暂时未加载到商品数据，无法判断是否有可购买的商品，默认返回没有可购买的商品")
              XShopManager.GetShopInfo(shopId)
            return false
        end
        for _, v in ipairs(goods) do
            local goodsUnLock = true
            if not XTool.IsTableEmpty(v.ConditionIds) then
                for _, id in pairs(v.ConditionIds) do
                    if not XConditionManager.CheckCondition(id) then
                        goodsUnLock = false
                        break
                    end
                end
            end

            if goodsUnLock and v.TotalBuyTimes < v.BuyTimesLimit then
                for _, consume in ipairs(v.ConsumeList) do
                    if XDataCenter.ItemManager.GetCount(consume.Id) >= consume.Count then
                        return true
                    end
                end
            end
        end
    end

    return false
end

return XGameCollectionAgency
