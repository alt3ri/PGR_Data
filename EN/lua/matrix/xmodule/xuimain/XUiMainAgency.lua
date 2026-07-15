-- 主界面模块管理器
---@class XUiMainAgency : XAgency
---@field private _Model XUiMainModel
local XUiMainAgency = XClass(XAgency, "XUiMainAgency")

local ActivityToastHallCheckIntervalSecond = 30

function XUiMainAgency:OnInit()
    --初始化一些变量
    self._UiLoginVideoV4P0OpenTrigger = false
    -- 活动跑马灯：记录当前场景、待播队列和轮询计时器
    self._ActivityToastHallSceneKey = nil
    self._ActivityToastHallQueue = nil
    self._ActivityToastHallPendingIdMap = nil
    self._ActivityToastHallTimer = nil
    self:CheckClearAllPanelTipClicked()
end

function XUiMainAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyBoardEffectData = handler(self, self.NotifyBoardEffectData)
end

function XUiMainAgency:InitEvent()
    --实现跨Agency事件注册
    self:AddAgencyEvent(XEventId.EVENT_SIGN_IN_FIVE_OCLOCK_REFRESH, self.ClearAllPanelTipClicked, self) -- 每天五点 恢复蓝点检测
    self:AddAgencyEvent(
        XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE,
        self.OnLoginDataLoadCompleteStartActivityToastHall,
        self
    )
    self:AddAgencyEvent(XEventId.EVENT_USER_LOGOUT, self.OnUserLogoutStopActivityToastHall, self)
end

function XUiMainAgency:RemoveEvent()
    self:RemoveAgencyEvent(XEventId.EVENT_SIGN_IN_FIVE_OCLOCK_REFRESH, self.ClearAllPanelTipClicked, self)
    self:RemoveAgencyEvent(
        XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE,
        self.OnLoginDataLoadCompleteStartActivityToastHall,
        self
    )
    self:RemoveAgencyEvent(XEventId.EVENT_USER_LOGOUT, self.OnUserLogoutStopActivityToastHall, self)
end

function XUiMainAgency:ResetAll()
    self:StopActivityToastHallTimer()
end

function XUiMainAgency:NotifyBoardEffectData(data)
    if not data then
        return
    end
    self._Model:UpdateBoardEffectData(data.BoardEffectData)
end

----------public start----------

function XUiMainAgency:SetUiLoginVideoV4P0OpenTriggerTrue()
    self._UiLoginVideoV4P0OpenTrigger = true
end

function XUiMainAgency:GetUiLoginVideoV4P0OpenTrigger()
    local flag = self._UiLoginVideoV4P0OpenTrigger
    self._UiLoginVideoV4P0OpenTrigger = false
    return flag
end

-- 强制打开指定Id的登录推广功能，跳过Condition和EnterTime等检查
function XUiMainAgency:ForceOpenLoginPromoFeature(id)
    local allConfigs = XLoginManager.GetLoginPromoFeatureTemplate()
    local config = allConfigs[id]
    if not config then
        XLog.Error("ForceOpenLoginPromoFeature: config not found, id = " .. tostring(id))
        return
    end
    local skipCfg = XFunctionConfig.GetSkipFuncCfg(config.EnterSkipId)
    if not skipCfg then
        XLog.Error("ForceOpenLoginPromoFeature: skip config not found, EnterSkipId = " .. tostring(config.EnterSkipId))
        return
    end
    XLuaUiManager.Open(skipCfg.UiName, id)
end

function XUiMainAgency:SetLastPlaySignBoardCfgId(id)
    self._Model.LastPlaySignBoardCfgId = id
end

function XUiMainAgency:GetLastPlaySignBoardCfgId()
    return self._Model.LastPlaySignBoardCfgId
end

function XUiMainAgency:GetModelUiPanelTipById(id, notTipError)
    local config = self:GetModelUiPanelTip()[id]
    if XTool.IsTableEmpty(config) and not notTipError then
        XLog.Error("表Client/UiMain/UiPanelTip.tab Id:" .. id .. "未配置")
    end

    return config
end

-- 珍惜道具获取接口
function XUiMainAgency:GetAllExpensiveiItems()
    if self._Model.ConfigExpensiveiItem then
        return self._Model.ConfigExpensiveiItem
    end
    local path = "Share/Item/ExpensiveiItem.tab"
    local allConfig = XTableManager.ReadByIntKey(path, XTable.XTableExpensiveiItem, "ItemId")
    self._Model.ConfigExpensiveiItem = allConfig
    return allConfig
end

-- 获取激活提示的珍惜道具
function XUiMainAgency:GetAllActiveTipExpensiveiItems()
    local allConfig = self:GetAllExpensiveiItems()
    local res = {}
    for itemId, v in pairs(allConfig) do
        local leftTime = XDataCenter.ItemManager.GetRecycleLeftTime(itemId)
        -- 检测开启提示的倒计时时间
        local hasCount = XDataCenter.ItemManager.GetCount(itemId)
        if XTool.IsNumberValid(leftTime) and leftTime < v.LeftTime and XTool.IsNumberValid(hasCount) then
            table.insert(res, v)
        end
    end
    return res
end

-- 记录当前点击的终端缓存
function XUiMainAgency:RecordPanelTipClicked(panelTipId)
    local key = "RecordPanelTipClicked" .. panelTipId
    local nextRefreshTs = XTime.GetSeverNextRefreshTime()
    XSaveTool.SaveData(key, nextRefreshTs)
end

-- 每次登录时检测是否清除当天的点击缓存，如果超过5点就清除
function XUiMainAgency:CheckClearAllPanelTipClicked()
    local allPanleTip = self:GetModelUiPanelTip()
    for id, v in pairs(allPanleTip) do
        local recordTs = self:CheckPanelTipClicked(id)
        local nextTs = XTime.GetSeverNextRefreshTime()
        if recordTs and recordTs ~= nextTs then
            self:ClearPanelTipClicked(id)
        end
    end
end

-- 清除所有终端点击缓存
function XUiMainAgency:ClearAllPanelTipClicked()
    local allPanleTip = self:GetModelUiPanelTip()
    for id, v in pairs(allPanleTip) do
        self:ClearPanelTipClicked(id)
    end
end

function XUiMainAgency:ClearPanelTipClicked(panelTipId)
    local key = "RecordPanelTipClicked" .. panelTipId
    XSaveTool.SaveData(key, false)
end

function XUiMainAgency:CheckPanelTipClicked(panelTipId)
    local key = "RecordPanelTipClicked" .. panelTipId
    return XSaveTool.GetData(key)
end

function XUiMainAgency:GetScrollTipList(ignoreOnTerminal)
    local list = {}
    local templates = self:GetModelUiPanelTip() or {}
    
    local isInsideUnlock = self:CheckUiMainTerminalMobileListUnlock()
    
    for _, template in pairs(templates) do
        if not ignoreOnTerminal or (ignoreOnTerminal and template.IgnoreOnTerminal ~= 1) then
            if not template.IsLockWithTerminalMobile or isInsideUnlock then
                local func = self[template.FunctionName]
                local tip = func and func(self, ignoreOnTerminal) or nil
                if not string.IsNilOrEmpty(tip) then
                    table.insert(list, {
                        Tips = tip,
                        Type = template.Type,
                        Config = template
                    })
                end
            end
        end
    end

    if not XTool.IsTableEmpty(list) then
        table.sort(list, function(a, b)
            return a.Config.Priority < b.Config.Priority
        end)
    end

    return list
end

function XUiMainAgency:GetYkScrollTip()
    if not XDataCenter.PurchaseManager.CheckYKContinueBuy() then
        return
    end

    return XUiHelper.GetText("PurchaseYKExpireDes")
end

function XUiMainAgency:GetPurchaseScrollTip()
    local giftCount = XDataCenter.PurchaseManager.ExpireCount or 0
    if giftCount <= 0 then
        return
    end

    if giftCount == 1 then
        return XUiHelper.GetText("PurchaseGiftValitimeTips1")
    end

    return XUiHelper.GetText("PurchaseGiftValitimeTips2")
end

function XUiMainAgency:GetDormQuestScrollTip()
    -- 宿舍终端提示 可领取 > 可派遣
    local dispatchedCount, unDispatchCount = XDataCenter.DormQuestManager.GetEntranceShowData()
    if dispatchedCount > 0 then
        return XUiHelper.GetText("DormQuestTerminalMainTeamRegress", dispatchedCount)
    elseif unDispatchCount > 0 then
        return XUiHelper.GetText("DormQuestTerminalMainTeamFree", unDispatchCount)
    end
end

function XUiMainAgency:CheckCanPlayActionByMainUi()
    local targetUiName = "UiMain"
    local isMainUiLoad = XLuaUiManager.IsUiLoad(targetUiName)
    local isMainUiShow = XLuaUiManager.IsUiShow(targetUiName)
    local isTopUiMain = XLuaUiManager.GetTopUiName() == targetUiName
    if isMainUiLoad and not isMainUiShow then
        return false
    end

    if isMainUiShow and not isTopUiMain then
        return false
    end

    return true
end

function XUiMainAgency:GetExpensiveScrollTip(isIgnoreDayCheck)
    local allItem = self:GetAllActiveTipExpensiveiItems()
    if XTool.IsTableEmpty(allItem) or (self:CheckPanelTipClicked(XEnumConst.Ui_MAIN.TerminalTipType.ExpensiveItem) and not isIgnoreDayCheck) then
        return
    end

    return XUiHelper.GetText("ExpensiveItemExpiration")
end

function XUiMainAgency:GetSubpackageScrollTip()
    return XMVCA.XSubPackage:GetDownloadingTip()
end

function XUiMainAgency:GetPreloadScrollTip()
    return XMVCA.XPreload:GetDownloadingTip()
end

function XUiMainAgency:GetWeekCardScrollTip()
    local isCanContinueBuy, weekCardData = XDataCenter.PurchaseManager.CheckWeekCardContinueBuy()
    if isCanContinueBuy and weekCardData then
        return XUiHelper.GetText("PurchaseWeekCardExpireDes", weekCardData:GetName())
    end
end

--region左上角活动按钮相关

-- 检查活动按钮是否显示
function XUiMainAgency:CheckActivityBtnShow(activityBtnConfig, isIgnoreNewPlayerTask)
    if not activityBtnConfig then
        return false
    end

    -- 新玩家任务通过合集按钮显示了
    if not isIgnoreNewPlayerTask and self:CheckIsNewPlayerTaskActivityBtnId(activityBtnConfig.Id) then
        return false
    end

    local timeId = activityBtnConfig.TimeId
    local isTimePass = XFunctionManager.CheckInTimeByTimeId(timeId)
    if not isTimePass then
        return false
    end

    local isCondPass = self:CheckActivityBtnConditionPass(activityBtnConfig)

    if not isCondPass then
        return false
    end
    
    return true
end

-- 检查活动按钮条件是否通过
function XUiMainAgency:CheckActivityBtnConditionPass(activityBtnConfig)
    local isOrConditions = activityBtnConfig.IsOrConditions
    local conditions = activityBtnConfig.Conditions

    local isPass = true
    for _, conId in pairs(conditions) do
        if isOrConditions then
            if XConditionManager.CheckCondition(conId) then
                return true
            else
                isPass = false
            end
        else
            if not XConditionManager.CheckCondition(conId) then
                return false
            else
                isPass = true
            end
        end
    end

    return isPass
end

--region 新手任务合集

-- 获取新手任务合集
---@return table {{ ActivityBtnId = xxx, BestRewardId = xxx }, ...}
function XUiMainAgency:GetNewPlayerTaskCollection()
    return self._Model:GetNewPlayerTaskCollection()
end

-- 获取第一个可以跳转的新手任务合集的跳转Id
function XUiMainAgency:GetFirstCanSkipNewPlayerTaskCollectionSKipId()
    local newPlayerTaskCollection = self._Model:GetNewPlayerTaskCollection()
    if XTool.IsTableEmpty(newPlayerTaskCollection) then
        return
    end

    for _, data in ipairs(newPlayerTaskCollection) do
        local activityBtnConfig = self:GetActivityBtnConfigById(data.ActivityBtnId)
        if not XTool.IsTableEmpty(activityBtnConfig) then
            if self:CheckActivityBtnConditionPass(activityBtnConfig) then
                return activityBtnConfig.SkipId
            end
        end
    end
end

-- 检查是否是新手任务合集的按钮
function XUiMainAgency:CheckIsNewPlayerTaskActivityBtnId(activityBtnId)
    local newPlayerTaskCollection = self._Model:GetNewPlayerTaskCollection()
    for _, data in ipairs(newPlayerTaskCollection) do
        if data.ActivityBtnId == activityBtnId then
            return true
        end
    end

    return false
end
--endregion

--endregion

--region 获取表数据
function XUiMainAgency:GetModelUiPanelTip()
    return self._Model:GetUiPanelTip()
end

function XUiMainAgency:GetModelActivityBtn()
    return self._Model:GetActivityBtn()
end

function XUiMainAgency:GetActivityBtnConfigById(id)
    return self._Model:GetActivityBtnConfigById(id)
end

function XUiMainAgency:GetActivityToastHallCfgs()
    return self._Model:GetActivityToastHallCfgs()
end

function XUiMainAgency:GetActivityToastHallCfgById(id)
    return self._Model:GetActivityToastHallCfgById(id)
end

function XUiMainAgency:GetActivityToastHallSkinCfgById(id)
    return self._Model:GetActivityToastHallSkinCfgById(id)
end

function XUiMainAgency:GetActivityToastHallSceneRuleCfg(sceneKey)
    return self._Model:GetActivityToastHallSceneRuleCfg(sceneKey)
end

function XUiMainAgency:ResolveActivityToastHallSceneKey(sceneKey)
    if string.IsNilOrEmpty(sceneKey) then
        return self._Model:GetActivityToastHallDefaultSceneKey()
    end

    return sceneKey
end

--endregion

--region 活动跑马灯

-- 自动调度：同一轮满足条件的多条配置按优先级串播
function XUiMainAgency:StartActivityToastHallTimer(sceneKey)
    self:StopActivityToastHallTimer()

    if not CS.XGame.ClientConfig:GetBool("ActivityToastHallAutoCheckEnable") then
        XLuaUiManager.Remove("UiMainActivityToastHall")
        return
    end

    self._ActivityToastHallSceneKey = self:ResolveActivityToastHallSceneKey(sceneKey)
    self._ActivityToastHallQueue = XQueue.New()
    self._ActivityToastHallPendingIdMap = {}

    self:UpdateActivityToastHallQueue()
    self:TryPopActivityToastHall()

    self._ActivityToastHallTimer = XScheduleManager.ScheduleForever(function()
        self:UpdateActivityToastHallQueue()
        self:TryPopActivityToastHall()
    end, ActivityToastHallCheckIntervalSecond * XScheduleManager.SECOND)
end

function XUiMainAgency:StopActivityToastHallTimer()
    if self._ActivityToastHallTimer then
        XScheduleManager.UnSchedule(self._ActivityToastHallTimer)
        self._ActivityToastHallTimer = nil
    end

    if self._ActivityToastHallQueue then
        self._ActivityToastHallQueue:Clear()
    end

    self._ActivityToastHallPendingIdMap = nil
end

function XUiMainAgency:OnLoginDataLoadCompleteStartActivityToastHall()
    self:StartActivityToastHallTimer()
end

function XUiMainAgency:OnUserLogoutStopActivityToastHall()
    self:StopActivityToastHallTimer()
    XLuaUiManager.Remove("UiMainActivityToastHall")
end

function XUiMainAgency:UpdateActivityToastHallQueue(sceneKey)
    sceneKey = self:ResolveActivityToastHallSceneKey(sceneKey or self._ActivityToastHallSceneKey)

    if not self._ActivityToastHallQueue then
        self._ActivityToastHallQueue = XQueue.New()
    end

    if not self._ActivityToastHallPendingIdMap then
        self._ActivityToastHallPendingIdMap = {}
    end

    local cfgs = self:GetActivityToastHallCfgs()
    if XTool.IsTableEmpty(cfgs) then
        return
    end

    local list = {}
    for _, cfg in pairs(cfgs) do
        if self:CheckActivityToastHallCanEnqueue(cfg, sceneKey) then
            table.insert(list, cfg)
        end
    end

    if XTool.IsTableEmpty(list) then
        return
    end

    table.sort(list, function(a, b)
        if a.Priority ~= b.Priority then
            return (a.Priority or 0) < (b.Priority or 0)
        end
        return (a.Id or 0) < (b.Id or 0)
    end)

    for _, cfg in ipairs(list) do
        self._ActivityToastHallQueue:Enqueue(cfg.Id)
        self._ActivityToastHallPendingIdMap[cfg.Id] = true
    end
end

---@param cfg XTableActivityToastHall
function XUiMainAgency:CheckActivityToastHallCanEnqueue(cfg, sceneKey)
    if not cfg or self._ActivityToastHallPendingIdMap and self._ActivityToastHallPendingIdMap[cfg.Id] then
        return false
    end

    local cfgSceneKey = string.IsNilOrEmpty(cfg.SceneKey) and sceneKey or cfg.SceneKey
    if cfgSceneKey ~= sceneKey then
        return false
    end

    if XTool.IsNumberValidEx(cfg.TimeId) and not XFunctionManager.CheckInTimeByTimeId(cfg.TimeId, false) then
        return false
    end

    if XTool.IsNumberValidEx(cfg.ConditionId) and not XConditionManager.CheckCondition(cfg.ConditionId) then
        return false
    end

    local now = XTime.GetServerNowTimestamp()
    local lastShowTime = self._Model:GetActivityToastHallLastShowTime(cfg.Id)
    if XTool.IsNumberValidEx(cfg.IntervalTime) then
        if XTool.IsNumberValidEx(lastShowTime) and now - lastShowTime < cfg.IntervalTime then
            return false
        end
    elseif XTool.IsNumberValidEx(lastShowTime) then
        return false
    end

    return true
end

function XUiMainAgency:CanPopActivityToastHall(sceneKey)
    sceneKey = self:ResolveActivityToastHallSceneKey(sceneKey or self._ActivityToastHallSceneKey)
    if XLuaUiManager.IsUiShow("UiMainActivityToastHall") or XLuaUiManager.IsUiPushing("UiMainActivityToastHall") then
        return false
    end

    local rule = self:GetActivityToastHallSceneRuleCfg(sceneKey)
    if not rule then
        return true
    end

    if self:CheckActivityToastHallHasBlockUi(rule.BlockUiNames) then
        return false
    end

    return self:CheckActivityToastHallTopUiValid(rule.AllowTopUiNames)
end

function XUiMainAgency:TryPopActivityToastHall(sceneKey)
    sceneKey = self:ResolveActivityToastHallSceneKey(sceneKey or self._ActivityToastHallSceneKey)
    if not self:CanPopActivityToastHall(sceneKey) then
        return false
    end

    if not self._ActivityToastHallQueue or self._ActivityToastHallQueue:Count() <= 0 then
        return false
    end

    local id = self._ActivityToastHallQueue:Dequeue()
    if self._ActivityToastHallPendingIdMap then
        self._ActivityToastHallPendingIdMap[id] = nil
    end

    if not XTool.IsNumberValidEx(id) then
        return false
    end

    if XLuaUiManager.IsUiLoad("UiMainActivityToastHall") then
        XLuaUiManager.Remove("UiMainActivityToastHall")
    end

    XLuaUiManager.OpenWithCallback("UiMainActivityToastHall", function()
        self._Model:SetActivityToastHallLastShowTime(id, XTime.GetServerNowTimestamp())
    end, id)
    return true
end

function XUiMainAgency:CheckActivityToastHallHasBlockUi(blockUiNames)
    if XTool.IsTableEmpty(blockUiNames) then
        return false
    end

    for _, uiName in ipairs(blockUiNames) do
        if not string.IsNilOrEmpty(uiName) then
            if XLuaUiManager.IsUiLoad(uiName) or XLuaUiManager.IsUiShow(uiName) then
                return true
            end
        end
    end

    return false
end

function XUiMainAgency:CheckActivityToastHallTopUiValid(allowTopUiNames)
    if XTool.IsTableEmpty(allowTopUiNames) then
        return true
    end

    local topUiName = XLuaUiManager.GetTopUiName()
    for _, uiName in ipairs(allowTopUiNames) do
        if not string.IsNilOrEmpty(uiName) and topUiName == uiName then
            return true
        end
    end

    return false
end

--endregion

--region 活动按钮数据

--ios审核模式特殊屏蔽的id
local HideFuncBtnIds = {
    [3] = true
}

-- 获取数据处理
function XUiMainAgency:GetActivityBtnListByOrder()
    local allConfig = self:GetModelActivityBtn()
    local res = {}
    for k, v in pairs(allConfig) do
        if not XUiManager.IsHideFunc or not HideFuncBtnIds[k] then
            --审核模式
            table.insert(res, v)
        end
    end

    table.sort(res, function(a, b)
        return (a.Priority or 0) > (b.Priority or 0)
    end)

    return res
end

--endregion

--region BoardEffect

-- 触发特效请求
function XUiMainAgency:BoardEffectTriggerRequest(cb)
    XNetwork.Call("BoardEffectTriggerRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:UpdateLastTriggerTime(res.LastTriggerTime)
        if cb then
            cb()
        end
    end)
end

-- 获取特效根节点名和特效路径
---@return table<number, { RootName:string, Path:string, Time:number }>
function XUiMainAgency:GetBoardEffectPaths()
    local rootNames = self._Model:GetBoardEffectEffectRootNames()
    local paths = self._Model:GetBoardEffectEffectPaths()
    local times = self._Model:GetBoardEffectEffectTimes()
    local res = {}
    for i, path in ipairs(paths) do
        res[i] = {
            RootName = rootNames[i],
            Path = path,
            Time = times[i] or 0
        }
    end
    return res
end

-- 检查活动是否开启
function XUiMainAgency:IsBoardEffectActivityOpen()
    return self._Model:GetBoardEffectActivityId() > 0
end

-- 检查是否冷却 未冷却返回false
function XUiMainAgency:IsBoardEffectCoolDown()
    if not self:IsBoardEffectActivityOpen() then
        return false
    end
    local lastTriggerTime = self._Model:GetBoardEffectLastTriggerTime()
    if lastTriggerTime <= 0 then
        return true
    end
    -- 触发冷却时间
    local coolDown = self._Model:GetBoardEffectTriggerCd() + 1
    local now = XTime.GetServerNowTimestamp()
    return now - lastTriggerTime >= coolDown
end

-- 检查是否触发特效
function XUiMainAgency:CheckIsTriggerBoardEffect()
    if not self:IsBoardEffectCoolDown() then
        return false
    end
    -- 触发概率 千分数
    local triggerProbability = self._Model:GetBoardEffectTriggerProbability()
    if triggerProbability <= 0 then
        return false
    end
    -- 随机触发
    local random = math.random(1, 1000)
    return random <= triggerProbability
end

-- 触发特效
---@param cb function 触发回调
function XUiMainAgency:TriggerBoardEffect(cb)
    if not self:CheckIsTriggerBoardEffect() then
        return
    end
    self:BoardEffectTriggerRequest(cb)
end

--endregion

--- 特殊处理，判断终端内中间面板相关内容是否解锁，用于控制红点穿透、信息穿透等
function XUiMainAgency:CheckUiMainTerminalMobileListUnlock()
    -- 整体屏蔽判断
    local unlockCondition = CS.XGame.ClientConfig:GetInt('UiMainTerminalMobileListUnlockCondition')

    if XTool.IsNumberValidEx(unlockCondition) and not XConditionManager.CheckCondition(unlockCondition) then
        return false
    end
    
    return true
end

----------public end----------

----------private start----------


----------private end----------

return XUiMainAgency
