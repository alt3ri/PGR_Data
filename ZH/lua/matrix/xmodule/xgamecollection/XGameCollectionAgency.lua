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
    local newRecords = self._Model:UpdateGameData(data.GameCollectionData.GameData)
    if XTool.IsTableEmpty(newRecords) then
        return
    end
    for _, record in ipairs(newRecords) do
        self._Model:SetPendingExitRecord(record)
    end
    -- Notify 到达,立刻处理(若有等待中的延时定时器,_PumpBreakRecord 内会取消)
    self:_PumpBreakRecord(false)
end

function XGameCollectionAgency:IsLaunchedFromCollection(gameType)
    if not XTool.IsNumberValid(gameType) then
        return true
    end

    local launchContext = self:GetLaunchContext()
    return launchContext and launchContext.GameType == gameType or false
end

function XGameCollectionAgency:OnGameExitToCollection(gameType, exitInfo)
    if not XTool.IsNumberValid(gameType) or not self:IsLaunchedFromCollection(gameType) then
        return false
    end

    self._Model:SetSelectedGameType(gameType)
    self:ClearLaunchContext()

    return true
end

-- 破纪录弹窗统一入口:在主界面已显示且当前没有破纪录弹窗时,从队列依次消费;否则只缓存
-- onClose:全部破纪录弹窗依次关闭后才触发,确保"下一步"被弹窗拦住
-- 携带 onClose 时会延时一小段等 Notify,避免 RPC 回调早于 Notify 到达时漏拦
function XGameCollectionAgency:TryOpenBreakRecord(onClose)
    if onClose then
        self._PendingBreakRecordCb = onClose
    end
    self:_PumpBreakRecord(onClose ~= nil)
end

function XGameCollectionAgency:_PumpBreakRecord(allowDeferForLateNotify)
    if self._BreakRecordPumpTimer then
        XScheduleManager.UnSchedule(self._BreakRecordPumpTimer)
        self._BreakRecordPumpTimer = nil
    end

    if XLuaUiManager.IsUiShow("UiMiniGamesCollectionBreakTheRecord") then
        -- 弹窗已显示,暂存的 onClose 会在弹窗链结束后触发
        return
    end

    local function FlushPendingCb()
        local cb = self._PendingBreakRecordCb
        self._PendingBreakRecordCb = nil
        if cb then cb() end
    end

    if not XLuaUiManager.IsUiShow("UiMiniGamesCollectionMain") then
        FlushPendingCb()
        return
    end

    local record = self._Model:PopPendingExitRecord()
    if XTool.IsTableEmpty(record) then
        if allowDeferForLateNotify and self._PendingBreakRecordCb then
            -- 给 Notify 一小段时间到达,期间若 Notify 写入记录会再次触发并取消本定时器
            self._BreakRecordPumpTimer = XScheduleManager.ScheduleOnce(function()
                self._BreakRecordPumpTimer = nil
                self:_PumpBreakRecord(false)
            end, 200)
            return
        end
        FlushPendingCb()
        return
    end

    XLuaUiManager.Open("UiMiniGamesCollectionBreakTheRecord", record.GameName, record.NewScore, function()
        self:_PumpBreakRecord(false)
    end)
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

function XGameCollectionAgency:GetFirstEnterMainKey()
    local activityId = self._Model:GetActivityId() or 0
    return string.format("GameCollection_FirstEnterMain_%s_%s", tostring(activityId), tostring(XPlayer.Id))
end

function XGameCollectionAgency:HasFirstEnterMainBluePoint()
    if not XTool.IsNumberValid(self._Model:GetActivityId()) then
        return false
    end
    return not XSaveTool.GetData(self:GetFirstEnterMainKey())
end

function XGameCollectionAgency:MarkFirstEnterMain()
    if not XTool.IsNumberValid(self._Model:GetActivityId()) then
        return
    end
    XSaveTool.SaveData(self:GetFirstEnterMainKey(), true)
end

function XGameCollectionAgency:HasGoodCanBuy()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon, nil, true) then
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
