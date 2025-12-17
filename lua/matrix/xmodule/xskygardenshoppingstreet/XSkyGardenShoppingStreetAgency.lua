local XBigWorldActivityAgency = require("XModule/XBase/XBigWorldActivityAgency")

---@class XSkyGardenShoppingStreetAgency : XBigWorldActivityAgency
---@field private _Model XSkyGardenShoppingStreetModel
local XSkyGardenShoppingStreetAgency = XClass(XBigWorldActivityAgency, "XSkyGardenShoppingStreetAgency")

function XSkyGardenShoppingStreetAgency:OnInit()
    --初始化一些变量
    self._FinishStageKey = XPlayer.Id.. "_SS_FinishStageKey"
    -- 客户端资源类型显示
    self.StageResType = {
        InitGold = 20101,
        InitFriendly = 20102,
        InitCustomerNum = 20103,
        InitEnvironment = 20104,
        ShopCustomerFactorStar = 20011,
        ShopAwardGold = 20013,

        EnvironmentSatisfaction = 20021,
        ShopScoreSatisfaction = 20022,
        OtherSatisfaction = 20023,

        AddCustomerFix = 101,
        AddCustomerRatio = 102,
        AddEnvironmentFix = 103,
        AddEnvironmentRatio = 104,
        AddSatisfactionFixed = 105,
        AddSatisfactionRatio = 106,
    }

    self._ResBaseToResType = {
        [1] = self.StageResType.InitGold,
    }

    self._AttrBaseToResType = {
        [1] = self.StageResType.InitCustomerNum,
        [2] = self.StageResType.InitEnvironment,
        [3] = self.StageResType.InitFriendly,
        [4] = self.StageResType.EnvironmentSatisfaction,
        [5] = self.StageResType.ShopScoreSatisfaction,
        [6] = self.StageResType.OtherSatisfaction,
    }

    -- 客户端建造分类 1 消费 2 游客 3 环境
    self.InsideBuildingParentType = {
        Consumpt = 1,
        Passenger = 2,
        Environment = 3,
    }

    -- 客户端关卡状态 0 正常，1 编辑，2 进行中
    self.X3CStageStatus = {
        Normal = 0,
        Edit = 1,
        Running = 2,
    }
    -- 摄像机位置索引 1 中间，2 左边
    self.X3CCameraPosIndex = {
        Middle = 1,
        Left = 2,
    }
    -- 升级摄像机位置添加类型
    self.X3CShopVCamIndexType = {
        Focus = 1,
        Upgrade = 2,
    }
    -- 客户端特效类型 0 无，1 预览，2 创建，3 更新，4 删除
    self.X3CEShopEffectType = {
        None = 0,
        ShopPreview = 1,
        ShopCreate = 2,
        ShopUpdate = 3,
        ShopDestroy = 4,
        ShopSale = 5,
    }
    -- 客户端buff类型 1 资源 2 属性 3 商店
    self.ParseBuffType = {
        Res = 1,
        Attr = 2,
        Shop = 3,
    }
    --------------------------------------------------------------------------------
    -- 服务器通用定义
    -- 资源类型 1 金币，2 好感度，3 顾客数量，4 环境
    self.XSgStreetResourceId = {
        Gold = 1,
    }
    -- 商业街属性加成 1 客流量，2 环境
    self.XSgStreetAttrType = {
        -- /// 客流量, 开发用, 配置不生效
        CustomerNum = 1,
        -- /// 环境, 开发用, 配置不生效
        Environment = 2,
        -- ///满意度
        Satisfaction = 3,
        -- /// 客流量固定加成
        CustomerNumAddFixed = 101,
        -- /// 客流量万分比加成
        CustomerNumAddRatio = 102,
        -- /// 环境固定加成
        EnvironmentAddFixed = 103,
        -- /// 环境万分比加成
        EnvironmentAddRatio = 104,
        -- /// 满意度固定加成
        SatisfactionAddFixed = 105,
        -- /// 满意度万分比加成
        SatisfactionAddRatio = 106,
        -- /// 不满事件数量万分比加成
        DiscontentCountAddRatio = 201,
        -- /// 突发事件数量万分比加成
        EmergencyCountAddRatio = 202,
        -- /// 推荐店铺利润加成
        RecommendShopAwardAddFixed = 203,
        -- /// 推荐店铺到店系数加成
        RecommendShopCustomerFactorAddFixed = 204,
        -- /// 自动处理不满, 仅客户端使用
        DiscontentAutoHandle = 301,
        -- /// 自动处理反馈, 仅客户端使用
        FeedbackAutoHandle = 302,
        -- /// 商店移除返回资金万分比加成
        ShopRemoveReturnAddRatio = 303,
        -- /// 新闻负面新闻权重降低
        NewsNegativeWeightSubFixed = 304,
        -- /// 突发事件启用特殊奖励
        EmergencyRewardSpOptionBuff = 305,
    }
    self.XSgStreetShopAttrType = {
        -- /// 到店系数固定加成
        CustomerFactorAddFixed = 1,
        -- /// 到店系数万分比加成
        CustomerFactorAddRatio = 2,
        -- /// 利润固定加成
        AwardAddFixed = 3,
        -- /// 利润万分比加成
        AwardAddRatio = 4,
        -- /// 建造消耗加成
        BuildCostAddRatio = 5,
        -- /// 升级消耗加成
        UpgradeCostAddRatio = 6,
    }
    -- 建筑类型 1 内部，2 外部
    self.XSgStreetShopMainType = {
        Inside = 1,
        Outside = 2,
    }
    -- 商店功能类型 101 美食，102 商品，103 甜品
    self.XSgStreetShopFuncType = {
        Food = 101,
        Grocery = 102,
        Dessert = 103,
    }
    -- 商业街顾客指令类型
    self.XSgStreetCustomerCommandType = {
        ShopInside = 1,
        ShopOutside = 2,
        Fake = 3,
    }
    -- 商店促销类型 1 回合制 节日，2 商店建筑 开业
    self.XSgStreetPromotionType = {
        TurnBase = 1,
        ShopBuild = 2,
    }
    -- 商店顾客事件类型 1 不满，2 突发
    self.XSgStreetCustomerEventType = {
        Discontent = 1,
        Emergency = 2,
        FeedBack = 3,
    }
    -- Buff效果类型 1 全局属性加成，2 增加资金，3 改变指定店铺的全部内容喜好，4 改变指定范围内随机X个店铺的全部喜好，5 改变食品店中指定内容的顾客喜好，6 改变商品店中指定内容的顾客喜好，7 改变甜品店中指定内容的顾客喜好，8 按回合间隔增加指定Buff，9 清除所有指定类型的Buff
    self.XSgStreetBuffEffectType = {
        -- ///全局属性加成
        GlobalAddAttrType1 = 1,
        -- ///增加资金, 支持负数
        AddGoldType2 = 2,
        -- ///改变指定店铺的全部内容喜
        ChangeAllShopLikeType3 = 3,
        -- /// 改定指定范围内随机X个店铺的全部喜好
        ChangeRandomShopLikeType4 = 4,
        -- ///改变食品店中指定内容的顾客喜好
        ChangeFoodShopLikeType5 = 5,
        -- ///改变商品店中指定内容的顾客喜好
        ChangeGroceryShopLikeType6 = 6,
        -- ///改变甜品店中指定内容的顾客喜好
        ChangeDessertShopLikeType7 = 7,
        -- ///按回合间隔增加指定Buff
        AddBuffAtIntervalsType8 = 8,
        -- ///清除所有指定类型的Buff
        CleanBuffType9 = 9,
    }
    -- 关卡任务状态 1 激活，2 达成，3 完成
    self.XSgStreetTaskState = {
        Activated = 1,
        Achieved = 2,
        Finished = 3,
    }
    self.XSgStreetTaskSource = {
        -- /// 关卡目标
        StageTarget = 1,
        -- /// 灯带
        Billboard = 2,
    }
    self.XShopBuildShowTypeBase = 20000
    self.XShopAttrTypesBase = 30000

    self:InitConditionCheck()
end

function XSkyGardenShoppingStreetAgency:OnRelease()
    self:ReleaseConditionCheck()
end

-- 初始化事件
function XSkyGardenShoppingStreetAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

----------private start----------
--region 协议
-- 初始化RPC协议
function XSkyGardenShoppingStreetAgency:InitRpc()
    --实现服务器事件注册
    -- 通知玩法数据
    self:AddRpc("NotifySgStreetData", handler(self, self._NotifySgStreetData))
    -- 通知当前关卡数据
    self:AddRpc("NotifySgStreetCurStageData", handler(self, self._NotifySgStreetCurStageData))
    -- 通知运营结算后的关卡数据
    self:AddRpc("NotifySgStreetAfterOperatingSettleStageData", handler(self, self._NotifySgStreetAfterOperatingSettleStageData))
    -- 通知关卡结算数据
    self:AddRpc("NotifySgStreetStageSettle", handler(self, self._NotifySgStreetStageSettle))
    -- 通知资源变化
    self:AddRpc("NotifySgStreetResourceChange", handler(self, self._NotifySgStreetResourceChange))
    -- 通知商店变化
    self:AddRpc("NotifySgStreetShopChange", handler(self, self._NotifySgStreetShopChange))
    -- 通知促销选择分组
    self:AddRpc("NotifySgStreetPromotionSelectGroupAdd", handler(self, self._NotifySgStreetPromotionSelectGroupAdd))
    -- 通知属性增加
    self:AddRpc("NotifySgStreetAttrAdds", handler(self, self._NotifySgStreetAttrAdds))
    -- 通知Buff增加
    -- self:AddRpc("NotifySgStreetBuffAdd", handler(self, self._NotifySgStreetBuffAdd))
    -- 通知Buff移除
    -- self:AddRpc("NotifySgStreetBuffRemove", handler(self, self._NotifySgStreetBuffRemove))
    -- 通知Buff数据
    self:AddRpc("NotifySgStreetBuffsData", handler(self, self._NotifySgStreetBuffsData))
    -- //通知商店街统计数据
    self:AddRpc("NotifySgStreetStatisticsData", handler(self, self._NotifySgStreetStatisticsData))
    -- //通知更新任务更新
    self:AddRpc("NotifySgStreetTaskData", handler(self, self._NotifySgStreetTaskData))
    -- //通知更新任务移除
    self:AddRpc("NotifySgStreetTaskDataRemove", handler(self, self._NotifySgStreetTaskDataRemove))
    -- //通知更新商店喜好
    self:AddRpc("NotifySgStreetLikeChange", handler(self, self._NotifySgStreetLikeChange))
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetData(data)
    local serverData = data.Data or data
    self._Model:SetStageData(serverData.CurStageData)
    self._Model:SetSceneStageData(serverData.SceneData)
    self._Model:SetPassedStageIds(serverData.PassedStageRecords)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetCurStageData(data)
    local serverData = data.Data or data
    self._Model:SetStageData(serverData)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetAfterOperatingSettleStageData(data)
    local serverData = data.Data or data
    self._Model:SetStageDataCache(serverData)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetStageSettle(data)
    self._Model:SetStageData(data.StageData)
    self._Model:SetSceneStageData(data.SceneData)
    self._Model:SetPassedStageIds(data.PassedStageRecords)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetResourceChange(data)
    self._Model:SetResourceDatas(data.Datas)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetShopChange(data)
    self._Model:UpdateShopAreaData(data.Datas, false)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetPromotionSelectGroupAdd(data)
    self._Model:UpdatePromotionData(data.Data)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetAttrAdds(data)
    self._Model:SetAttrsData(data.AttrAdds)
    self._Model:SetShopAttrAdds(data.ShopAttrAdds)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetBuffsData(data)
    self._Model:SetBuffsData(data.BuffDatas, true)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetStatisticsData(data)
    self._Model:SetStatisticsData(data.StatisticsData)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetTaskData(data)
    self._Model:SetTaskDatas(data.TaskDatas, true)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetTaskDataRemove(data)
    self._Model:RemoveTaskDatas(data.TaskIds)
end

function XSkyGardenShoppingStreetAgency:_NotifySgStreetLikeChange(data)
    self._Model:ShowLikeMessage()
end

-- 领取结算
function XSkyGardenShoppingStreetAgency:SgStreetStageWinSettleRequest(cb)
    if self._SendingSgStreetStageWinSettleRequest then return end
    self._SendingSgStreetStageWinSettleRequest = true
    XNetwork.Call(
        "SgStreetStageWinSettleRequest",
        { StageId = self._Model:GetCurrentStageId(), },
        function(res)
            self._SendingSgStreetStageWinSettleRequest = false
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据()
            self._Model:ResetBase(true)
            if cb then cb(res.RewardGoodsList, res.IsNewStagePassed) end
        end
    )
end

-- 任务完成
function XSkyGardenShoppingStreetAgency:SgStreetFinishTasksRequest(cb)
    local achievedTaskIds = self._Model:GetAchievedTaskIds()
    if not achievedTaskIds or self._SendingSgStreetFinishTasksRequest then return end
    self._SendingSgStreetFinishTasksRequest = true
    XNetwork.Call(
        "SgStreetFinishTasksRequest",
        { TaskIds = achievedTaskIds, },
        function(res)
            self._SendingSgStreetFinishTasksRequest = false
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            -- 刷新数据()
            for _, taskId in ipairs(achievedTaskIds) do
                self._Model:TaskFinishCheckBillborad(taskId)
            end
            self._Model:ClearAchievedTaskIds()
            self._Model:RemoveTaskDatas(res.FinishedTaskIds, true)
            self:TryTaskFinish()
            if cb then cb() end
        end
    )
end
--endregion
----------private end----------

----------public start----------
--region 游戏相关
function XSkyGardenShoppingStreetAgency:IsInGameUi()
    return XMVCA.XBigWorldUI:IsUiLoad("UiSkyGardenShoppingStreetGame")
end

function XSkyGardenShoppingStreetAgency:GetFinishStageConfirmId()
    return XSaveTool.GetData(self._FinishStageKey) or 0
end

function XSkyGardenShoppingStreetAgency:SetFinishStageConfirmId(stageId)
    XSaveTool.SaveData(self._FinishStageKey, stageId)
end

function XSkyGardenShoppingStreetAgency:CheckFinishTaskWithCallback(cb)
    if self._Model:IsFinishComfirm() then return end
    if self._Model:IsFinishAllStageTask() then
        local stageId = self._Model:GetCurrentStageId()
        if self:GetFinishStageConfirmId() ~= stageId then
            self:ConfirmPanel({
                ["Title"] = XMVCA.XBigWorldService:GetText("CommmonTipsTitle"),
                ["Tips"] = XMVCA.XBigWorldService:GetText("SG_SS_FinishLeaveGame"),
                ["SureCallback"] = function()
                    self._Model:SetFinishComfirm(true)
                    self:TryFinishStage()
                end,
                ["CancelCallback"] = function()
                    self:SetFinishStageConfirmId(stageId)
                    if cb then cb() end
                end,
            })
            return
        end
    end
    
    if cb then cb() end
end

-- 尝试完成关卡
function XSkyGardenShoppingStreetAgency:TryTaskFinish()
    local inGameUi = self:IsInGameUi()
    if inGameUi and not self._Model:IsRunningGame() then
        -- 完成任务检测是否结束关卡
        if self._Model:IsMaxTurn() then
            self:TryFinishStage()
        else
            if self._Model:IsFinishLimitTask() then
                XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetToastTaskSettlement", function ()
                    self:CheckFinishTaskWithCallback(function() self:SgStreetFinishTasksRequest() end)
                end)
            else
                self:CheckFinishTaskWithCallback(function() self:SgStreetFinishTasksRequest() end)
            end
            self:ShowFinishInfo()
        end
    end
end

-- 主界面进入
function XSkyGardenShoppingStreetAgency:StartStage(stageId)
    self._CurrentSelectStageId = stageId
    -- 进入关卡场景
    self:EnterStreetShopLevel()
end

-- 打开主界面
function XSkyGardenShoppingStreetAgency:OpenMainUi(id, args)
    if not self._Model:IsOpen() then
        self:Toast(XMVCA.XBigWorldService:GetText("CommmonTipsLock"))
        return
    end

    if XMVCA.XBigWorldGamePlay:IsInGame() then
        XMVCA.XBigWorldGamePlay:SetCurNpcActive(false)
    end
    self._Args = args
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetMain")
end

function XSkyGardenShoppingStreetAgency:GetProgressTipData()
    return {
        [1] = {
            Title = XMVCA.XBigWorldService:GetText("SG_SS_Progress"),
            Progress = self._Model:GetCurrentStarNum() .. "/" .. self._Model:GetTotalStarNum(),
            IsComplete = self._Model:IsComplete(),
        }
    }
end

function XSkyGardenShoppingStreetAgency:CheckFunctionOpen()
    return XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.SgStreet)
end

function XSkyGardenShoppingStreetAgency:CheckInTime()
    return self._Model:IsOpen()
end

-- 完成场景加载回调
function XSkyGardenShoppingStreetAgency:OnLevelBeginUpdate()
    -- 兼容服务器直接进入关卡
    if not self._CurrentSelectStageId then
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetMain")
        return
    end
    if self._CurrentSelectStageId == self._Model:GetCurrentStageId() and self._Model:IsStageRunning() then
        -- 完成任务检测是否结束关卡
        if self._Model:IsMaxTurn() then
            self:TryFinishStage()
        else
            self:AddOpenBlackMaskLoading(nil, function()
                -- 进入关卡场景
                XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetGame")
                self:SgStreetFinishTasksRequest()
            end)
        end
    else
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetTarget", self._CurrentSelectStageId, true)
    end
end

function XSkyGardenShoppingStreetAgency:IsEnterLevel()
    if not XMVCA.XBigWorldGamePlay:IsInGame() then return false end
    return XMVCA.XBigWorldGamePlay:GetCurrentLevelId() == self:GetLevelId()
end

-- 进入关卡副本回调
function XSkyGardenShoppingStreetAgency:OnEnterLevel()
end

-- 离开关卡副本回调
function XSkyGardenShoppingStreetAgency:OnLeaveLevel()
    self:DoLeaveLevel()
end

-- 离开level触发逻辑
function XSkyGardenShoppingStreetAgency:DoLeaveLevel()
    XMVCA.XBigWorldUI:SafeClose("UiSkyGardenShoppingStreetMain")

    -- 调试判断
    if not XMVCA.XBigWorldGamePlay:IsInGame() then return end

    local config = self:GetConfig()
    XMVCA.XBigWorldGamePlay:DeactivateVCamera(config.VirtureCamera)
    XMVCA.XBigWorldGamePlay:SetCurNpcActive(true)
end

function XSkyGardenShoppingStreetAgency:ExitGameLevel()
    if not self:IsEnterLevel() then
        self:DoLeaveLevel()
        return
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_TELEPORT_PLAYER_TO_LAST_LEVEL)
end

function XSkyGardenShoppingStreetAgency:EnterStreetShopLevel()
    -- 调试
    local isInGame = XMVCA.XBigWorldGamePlay:IsInGame()
    if not isInGame then
        self:OnLevelBeginUpdate()
        return
    end

    -- 正式
    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    local config = self:GetConfig()
    if not config or levelId == config.LevelId then
        self:OnLevelBeginUpdate()
    else
        if self._Args then
            XMVCA.XBigWorldMap:SendTeleportCommand(config.LevelId, self._Args[0] or 0, self._Args[1] or 0, self._Args[2] or 0)
        else
            XMVCA.XBigWorldMap:SendTeleportCommand(config.LevelId, 0, 0, 0)
        end
    end
end

-- 获取活动名称
function XSkyGardenShoppingStreetAgency:GetName()
    return self._Model:GetActivityName()
end

-- params = { Title, Tips, IsNew, CancelCallback, SureCallback, }
function XSkyGardenShoppingStreetAgency:ConfirmPanel(params)
    if params.IsTask then
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetPopupTaskConfirmation", params)
        return
    end
    XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetPopupConfirmation", params)
end

-- params = { Title, Tips, IsNew, }
function XSkyGardenShoppingStreetAgency:Toast(params)
    XMVCA.XBigWorldUI:OpenSingleUi("UiSkyGardenShoppingStreetToastNormal", params)
end

function XSkyGardenShoppingStreetAgency:ShowGetBuff()
    if not XMVCA.XBigWorldUI:IsShow("UiSkyGardenShoppingStreetToastEventReward") then
        XMVCA.XBigWorldUI:OpenSingleUi("UiSkyGardenShoppingStreetToastEventReward")
    end
end

function XSkyGardenShoppingStreetAgency:GetShopCustomerNumInTurnByShopId(shopId)
    return self._Model:GetShopCustomerNumInTurnByShopId(shopId)
end

function XSkyGardenShoppingStreetAgency:GetShopCustomerNumInLastTurnByShopId(shopId)
    return self._Model:GetShopCustomerNumInLastTurnByShopId(shopId)
end

function XSkyGardenShoppingStreetAgency:GetShopScoreInLastTurnByShopId(shopId)
    return self._Model:GetShopScoreInLastTurnByShopId(shopId)
end

function XSkyGardenShoppingStreetAgency:TryFinishStage()
    self:SgStreetStageWinSettleRequest(function(rewardGoodsList, isNewSagePassed)
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetSettlement", rewardGoodsList, isNewSagePassed)
    end)
end

function XSkyGardenShoppingStreetAgency:ShowFinishInfo()
    local showList = self._Model:GetFinishShowTargets()
    if showList and #showList > 0 then
        self:_ShowFinishInfo(showList)
    end
end

function XSkyGardenShoppingStreetAgency:_ShowFinishInfo(list)
    if not list or #list <= 0 then return end
    if not XMVCA.XBigWorldUI:IsShow("UiSkyGardenShoppingStreetGameTargetPopup") then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_FINISH_TASK_REFRESH, list)
        XMVCA.XBigWorldUI:Open("UiSkyGardenShoppingStreetGameTargetPopup", list)
    else
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_FINISH_TASK_REFRESH, list)
    end
end

function XSkyGardenShoppingStreetAgency:ShowBubbleTips(text, pos)
    XMVCA.XBigWorldUI:OpenSingleUi("UiSkyGardenShoppingStreetGameTips", text, pos)
end

function XSkyGardenShoppingStreetAgency:ShowBuffTips(buffId, pos)
    XMVCA.XBigWorldUI:OpenSingleUi("UiSkyGardenShoppingStreetGameBuffTips", buffId, pos)
end

-- remove Mask timer
function XSkyGardenShoppingStreetAgency:RemoveBlackMaskLoadingTimer()
    if not self._MaskTimer then return end

    XScheduleManager.UnSchedule(self._MaskTimer)
    self._MaskTimer = nil
    XMVCA.XBigWorldLoading:CloseBlackMaskLoading()
end

-- 黑幕打开
function XSkyGardenShoppingStreetAgency:AddOpenBlackMaskLoading(time, cb)
    if self._maskCallbackCb then return end
    local waitTime = time or 0.3
    -- 移除定时器
    self:RemoveBlackMaskLoadingTimer()

    -- 遮罩等待
    XMVCA.XBigWorldLoading:OpenBlackMaskLoading()
    if waitTime <= 0 then
        XMVCA.XBigWorldLoading:CloseBlackMaskLoading()
        if cb then cb() end
        return
    end

    self._maskCallbackCb = cb
    if not self._maskCallbackCache then
        self._maskCallbackCache = handler(self, self.MaskCallbackCache)
    end

    -- 移除遮罩定时器
    self._MaskTimer = XScheduleManager.ScheduleOnce(self._maskCallbackCache, waitTime * 1000)
end


-- remove Mask timer
function XSkyGardenShoppingStreetAgency:MaskCallbackCache()
    if self._maskCallbackCb then self._maskCallbackCb() end
    self._maskCallbackCb = nil
    self:RemoveBlackMaskLoadingTimer()
end

--endregion

--------------------------------------------------------------------------------

--region 配置相关

--- 获取所有属性显示的配置
---@return XTableSgStreetShopAttr 属性配置
function XSkyGardenShoppingStreetAgency:GetShopAttrConfigs()
    return self._Model:GetShopAttrConfigs()
end

--- 获取阶段内商品配置
---@param bid 商店id
---@param isInside 是否内部商店
---@return XTableSgStreetInsideShop 商店配置
function XSkyGardenShoppingStreetAgency:GetShopConfigById(shopId, isInside)
    return self._Model:GetShopConfigById(shopId, isInside)
end

--- 获取商店内商品配置
---@param shopId 商店id
---@param lv 等级
---@param isInside 是否内部商店
---@return XTableSgStreetInsideShopLv 商店内商品配置
function XSkyGardenShoppingStreetAgency:GetShopLevelConfigById(shopId, lv, isInside)
    return self._Model:GetShopLevelConfigById(shopId, lv, isInside)
end

--- 获取商店升级分支配置
---@param branchId 分支id
---@return XTableSgStreetShopLvBranchAdd 商店升级分支配置
function XSkyGardenShoppingStreetAgency:GetShopLvBranchConfigsByBranchId(branchId)
    return self._Model:GetShopLvBranchConfigsByBranchId(branchId)
end

-- 阶段配置
---@return XTableSgStreetStageRes 资源显示配置
function XSkyGardenShoppingStreetAgency:GetStageResConfigs()
    return self._Model:GetStageResConfigs()
end

--- 获取商店最大等级
--- @param shopId 商店id
--- @return 最大等级
function XSkyGardenShoppingStreetAgency:GetShopMaxLevel(shopId)
    return self._Model:GetShopMaxLevel(shopId)
end

--- 获取灯带配置
---@param id 灯带Id
---@return XTableSgStreetBillboard 灯带配置
function XSkyGardenShoppingStreetAgency:GetBillboardConfigById(id)
    return self._Model:GetBillboardConfigById(id)
end

function XSkyGardenShoppingStreetAgency:GetFuncTypeByShopId(shopId, isInside)
    local config = XMVCA.XSkyGardenShoppingStreet:GetShopConfigById(shopId, isInside)
    return config.FuncType
end

function XSkyGardenShoppingStreetAgency:GetFuncDataByShopData(shopData)
    if not shopData then return end
    local funcType = self:GetFuncTypeByShopId(shopData.ShopId, true)
    if funcType == self.XSgStreetShopFuncType.Food then
        return shopData.FoodData
    elseif funcType == self.XSgStreetShopFuncType.Grocery then
        return shopData.GroceryData
    elseif funcType == self.XSgStreetShopFuncType.Dessert then
        return shopData.DessertData
    end
end

function XSkyGardenShoppingStreetAgency:CanShowUpgradeTips(shopId, level, isInside)
    local shopConfig = self._Model:GetShopLevelConfigById(shopId, level + 1, isInside)
    local shopCfg = self._Model:GetShopConfigById(shopId, isInside)
    local reduceCost = self._Model:ShopUpgradeCostReduceBySubType(shopCfg.SubType, shopConfig.Cost)
    return self._Model:EnoughStageResById(reduceCost)
end

--endregion

--------------------------------------------------------------------------------
--region X3C 需要的数据
function XSkyGardenShoppingStreetAgency:X3CSgRequestData(data)
    return self._Model:GetX3CSceneData(data)
end

-- X3C 顾客完成任务回调
function XSkyGardenShoppingStreetAgency:X3CSgCustomerFinishTask(data)
    if self._CustomerFinishTaskCallback then
        self._CustomerFinishTaskCallback(data)
    end
end

-- X3C设置回调
function XSkyGardenShoppingStreetAgency:X3CSetCustomerFinishTaskCallback(finishCb)
    self._CustomerFinishTaskCallback = finishCb
end

--- 改变灯带
---@param TapeLightId number 灯带Id
function XSkyGardenShoppingStreetAgency:X3CLightChange(TapeLightId)
    -- 调试判断
    if not XMVCA.XBigWorldGamePlay:IsInGame() then return end

    local levelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    local config = self:GetConfig()
    if not config or levelId ~= config.LevelId then return end

    return XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_SHOPSTREET_CHANGE_TAPE_LIGHT, {
        TapeLightId = TapeLightId,
    })
end
--endregion

-- 引导Trigger触发
function XSkyGardenShoppingStreetAgency:CheckGuideOpen(isBubble)
    -- 气泡子任务都完成了就去掉气泡trigger
    if isBubble then
        if not self._CheckGuidIds then
            self._CheckGuidIds = {}
            
            local isFinishAllGuide = true
            local ids = self._Model:GetGlobalConfigByKey("BubbleGuideIdsFinishToSkipTrigger", true)
            for _, value in ipairs(ids) do
                local guideId = tonumber(value)
                if guideId then
                    local isFinish = XDataCenter.GuideManager.CheckIsGuide(guideId)
                    self._CheckGuidIds[guideId] = isFinish
                    isFinishAllGuide = isFinish and isFinishAllGuide
                end
            end
            self._IsFinishAllGuide = isFinishAllGuide
        else
            if not self._IsFinishAllGuide then
                local isFinishAllGuide = true
                for guideId, isFinishCache in pairs(self._CheckGuidIds) do
                    if not isFinishCache then
                        local isFinish = XDataCenter.GuideManager.CheckIsGuide(guideId)
                        isFinishAllGuide = isFinish and isFinishAllGuide
                        if not isFinishAllGuide then break end
                    end
                end
                self._IsFinishAllGuide = isFinishAllGuide
            end
        end

        if self._IsFinishAllGuide then return end
    end
    -- 判断是否引导
    XDataCenter.GuideManager.CheckGuideOpen()
end

function XSkyGardenShoppingStreetAgency:CleanBubbleCount()
    self._BubbleCountList = nil
end

-- 气泡统计
function XSkyGardenShoppingStreetAgency:ChangeBubbleCount(addType, num)
    if not self._BubbleCountList then
        self._BubbleCountList = {}
    end
    self._BubbleCountList[addType] = (self._BubbleCountList[addType] or 0) + num
end

function XSkyGardenShoppingStreetAgency:GetBubbleCount(addType)
    if not self._BubbleCountList then
        return 0
    end
    return self._BubbleCountList[addType] or 0
end

function XSkyGardenShoppingStreetAgency:SetPromotionSelectType(index)
    self._PromotionType = index
end

function XSkyGardenShoppingStreetAgency:GetPromotionSelectType()
    return self._PromotionType or 0
end

--region 条件判断

-- 条件判断初始化
function XSkyGardenShoppingStreetAgency:InitConditionCheck()
    XMVCA.XBigWorldService:RegisterConditionFunc(10202001, handler(self, self.CheckStageProperty))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202002, handler(self, self.CheckStageGold))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202003, handler(self, self.CheckStageShop))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202004, handler(self, self.HasBuff))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202005, handler(self, self.CheckPerfectShopCount))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202006, handler(self, self.CheckShopLevelCount))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202007, handler(self, self.CheckSelectedPromotionCount))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202008, handler(self, self.CheckDiscontentEventCount))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202009, handler(self, self.CheckEmergencyEventCount))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202010, handler(self, self.CheckFinishTaskCount))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202011, handler(self, self.CheckDayMaxEarnCount))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202012, handler(self, self.CheckRoundValue))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202013, handler(self, self.CheckGotGrapevineId))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202014, handler(self, self.CheckFoodShopChef))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202015, handler(self, self.CheckFoodShopGoodsPerfectCount))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202016, handler(self, self.CheckFoodShopGain))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202017, handler(self, self.CheckGoodShopPerfectCount))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202018, handler(self, self.CheckGoodShopGainCount))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202019, handler(self, self.CheckDessertShopGain))
    XMVCA.XBigWorldService:RegisterConditionFunc(10202020, handler(self, self.CheckDessertShopPerfectCount))

    -- 当前处于商业街第X关第X轮
    XMVCA.XBigWorldService:RegisterConditionFunc(10202021, handler(self, self.CheckStageAndRound))
    -- 当前处于商业街的游玩状态还是准备状态
    XMVCA.XBigWorldService:RegisterConditionFunc(10202022, handler(self, self.CheckRunStageState))
    -- 判断当前是否有对应类型的气泡
    XMVCA.XBigWorldService:RegisterConditionFunc(10202023, handler(self, self.CheckGameBubble))
    -- 判断当前玩家金币数量是否大于某个数值
    XMVCA.XBigWorldService:RegisterConditionFunc(10202024, handler(self, self.CheckGameGoldNum))
    -- 判断当前玩家满意度是否大于某个数值
    XMVCA.XBigWorldService:RegisterConditionFunc(10202025, handler(self, self.CheckGameFriendlyNum))
    -- 判断当前是否存在突发事件
    XMVCA.XBigWorldService:RegisterConditionFunc(10202026, handler(self, self.CheckGameConflictEvent))
    -- 判断当前处于开业促销还是常规促销
    XMVCA.XBigWorldService:RegisterConditionFunc(10202027, handler(self, self.CheckGamePromotion))
end

function XSkyGardenShoppingStreetAgency:ReleaseConditionCheck()
    if not XMVCA:IsRegisterAgency(ModuleId.XBigWorldService) then
        return
    end
    for i = 10202001, 10202027 do
        XMVCA.XBigWorldService:UnRegisterConditionFunc(i)
    end
end

--region 条件判断实现A

-- 1 检查关卡属性
function XSkyGardenShoppingStreetAgency:CheckStageProperty(template)
    local params = template.Params
    local propertyId = params[2]
    local resId = self._AttrBaseToResType[propertyId]
    local ownValue
    if resId then
        ownValue = self._Model:GetStageResById(resId)
    else
        ownValue = self._Model:GetAttrsDataByType(propertyId)
    end
    return XTool.CommonVariableCompare(params[1], ownValue, params, 3), template.Desc
end

-- 2 检查金币
function XSkyGardenShoppingStreetAgency:CheckStageGold(template)
    local params = template.Params
    local resId = self._ResBaseToResType[params[2]] or 0
    local ownValue = self._Model:GetStageResById(resId)
    return XTool.CommonVariableCompare(params[1], ownValue, params, 3), template.Desc
end

-- 3 检查商铺建造情况
function XSkyGardenShoppingStreetAgency:CheckStageShop(template)
    local stageId = self._Model:GetCurrentStageId()
    local stageShopConfig = self._Model:GetStageShopConfigsByStageId(stageId)
    local shopIds = {}
    for _, shopId in pairs(stageShopConfig.InsideShopGroup) do
        shopIds[shopId] = true
    end
    for _, shopId in pairs(stageShopConfig.OutsideShopGroup) do
        shopIds[shopId] = true
    end
    local params = template.Params
    local subTypeList = {}
    for i = 2, #params do
        subTypeList[params[i]] = true
    end

    local checkType = params[1]
    local isCheckBuild = checkType == 1

    if isCheckBuild then
        for shopId, _ in pairs(shopIds) do
            local shopCfg = self._Model:GetShopConfigById(shopId)
            if subTypeList[shopCfg.SubType] then
                if not self._Model:GetAreaIdByShopId(shopId) then
                    return false, template.Desc
                end
            end
        end
        return true, template.Desc
    else
        for shopId, _ in pairs(shopIds) do
            local shopCfg = self._Model:GetShopConfigById(shopId)
            if subTypeList[shopCfg.SubType] then
                if self._Model:GetAreaIdByShopId(shopId) then
                    return false, template.Desc
                end
            end
        end
        return true, template.Desc
    end
end

-- 4 检查是否有buff
function XSkyGardenShoppingStreetAgency:HasBuff(template)
    local checkType = template.Params[1]
    if checkType == 1 then
        for i = 2, #template.Params do
            local buffId = template.Params[i]
            local buffData = self._Model:GetStageGameBuff(buffId)
            if not buffData then return false, template.Desc end
        end
        return true, template.Desc
    else
        for i = 2, #template.Params do
            local buffId = template.Params[i]
            local buffData = self._Model:GetStageGameBuff(buffId)
            if buffData then return true, template.Desc end
        end
        return false, template.Desc
    end
end

-- 5 检查完美店铺数量
function XSkyGardenShoppingStreetAgency:CheckPerfectShopCount(template)
    local perectNum = template.Params[1]
    local shopCount = template.Params[2]
    local count = 0
    local areas = self._Model:GetAllShopAreas()
    for _, area in pairs(areas) do
        local score = area:GetShopScore()
        if score >= perectNum then
            count = count + 1
        end
    end
    return count >= shopCount, template.Desc
end

-- 6 检查商铺等级
function XSkyGardenShoppingStreetAgency:CheckShopLevelCount(template)
    local level = template.Params[1]
    local shopCount = template.Params[2]
    local inoutType = template.Params[3]
    local count = 0
    local areas = self._Model:GetAllShopAreas()
    for _, area in pairs(areas) do
        local mainType = area:GetShopMainType()
        if mainType == inoutType or inoutType == 3 then
            local lv = area:GetShopLevel()
            if lv >= level then
                count = count + 1
            end
        end
    end
    return count >= shopCount, template.Desc
end

-- 7 检查已选择促销数量
function XSkyGardenShoppingStreetAgency:CheckSelectedPromotionCount(template)
    local saleCount = template.Params[1]
    return self._Model:GetSelectedPromotionCount() >= saleCount, template.Desc
end

-- 8 检查不满度事件数量
function XSkyGardenShoppingStreetAgency:CheckDiscontentEventCount(template)
    local eventCount = template.Params[1]
    return self._Model:GetDiscontentEventCount() >= eventCount, template.Desc
end

-- 9 检查紧急事件数量
function XSkyGardenShoppingStreetAgency:CheckEmergencyEventCount(template)
    local eventCount = template.Params[1]
    return self._Model:GetEmergencyEventCount() >= eventCount, template.Desc
end

-- 10 检查完成任务数量
function XSkyGardenShoppingStreetAgency:CheckFinishTaskCount(template)
    local taskCount = template.Params[1]
    local sourceType = template.Params[2]
    if sourceType == 0 then
        return self._Model:GetFinishTaskTimesBySourceType(1) + self._Model:GetFinishTaskTimesBySourceType(2) >= taskCount, template.Desc
    end
    return self._Model:GetFinishTaskTimesBySourceType(sourceType) >= taskCount, template.Desc
end

-- 11 检查最高收益
function XSkyGardenShoppingStreetAgency:CheckDayMaxEarnCount(template)
    local value = template.Params[1]
    return self._Model:GetMaxDailyGold() >= value, template.Desc
end

-- 12 检查当前回合
function XSkyGardenShoppingStreetAgency:CheckRoundValue(template)
    local ownValue = self._Model:GetRunRound()
    local params = template.Params
    return XTool.CommonVariableCompare(params[1], ownValue, params, 2), template.Desc
end

-- 13 检查做过的小道
function XSkyGardenShoppingStreetAgency:CheckGotGrapevineId(template)
    local grapevineIds = self._Model:GetAllGrapevineIds()
    local params = template.Params
    local checkType = params[1]
    if checkType == 1 then
        for i = 2, #params do
            local gId = params[i]
            if table.contains(grapevineIds, gId) then
                return true, template.Desc
            end
        end
        return false, template.Desc
    else
        for i = 2, #params do
            local gId = params[i]
            if not table.contains(grapevineIds, gId) then
                return false, template.Desc
            end
        end
        return true, template.Desc
    end
end

-- 14 检查美食店厨师
function XSkyGardenShoppingStreetAgency:CheckFoodShopChef(template)
    local areas = self._Model:GetAllShopAreas()
    for _, area in pairs(areas) do
        local settingData = area:GetFoodData()
        local likeSettingData = area:GetFoodLikeData()
        if settingData and likeSettingData and settingData.ChefId == likeSettingData.ChefId then
            return true, template.Desc
        end
    end
    return false, template.Desc
end

-- 15 检查美食店商品数量
function XSkyGardenShoppingStreetAgency:CheckFoodShopGoodsPerfectCount(template)
    local areas = self._Model:GetAllShopAreas()
    local params = template.Params
    for _, area in pairs(areas) do
        local settingData = area:GetFoodData()
        local likeSettingData = area:GetFoodLikeData()
        if settingData and likeSettingData then
            local count = 0
            for key, value in pairs(settingData.GoodsCountList) do
                if value == likeSettingData.GoodsCountList[key] then
                    count = count + 1
                end
            end
            local isGood = XTool.CommonVariableCompare(params[1], count, params, 2)
            if isGood then
                return true, template.Desc
            end
        end
    end
    return false, template.Desc
end

-- 16 检查美食店收益
function XSkyGardenShoppingStreetAgency:CheckFoodShopGain(template)
    local areas = self._Model:GetAllShopAreas()
    local params = template.Params
    for _, area in pairs(areas) do
        local settingData = area:GetFoodData()
        local likeSettingData = area:GetFoodLikeData()
        if settingData and likeSettingData then
            local count = settingData.Gold - likeSettingData.Gold
            local isGood = XTool.CommonVariableCompare(params[1], count, params, 2)
            if isGood then
                return true, template.Desc
            end
        end
    end
    return false, template.Desc
end

-- 17 检查商品店铺数量
function XSkyGardenShoppingStreetAgency:CheckGoodShopPerfectCount(template)
    local areas = self._Model:GetAllShopAreas()
    local params = template.Params
    for _, area in pairs(areas) do
        local settingData = area:GetGroceryData()
        local likeSettingData = area:GetGroceryLikeData()
        if settingData and likeSettingData then
            local count = 0
            local map = {}
            for _, ShopGroceryShelfData in pairs(settingData.ShelfDatas) do
                map[ShopGroceryShelfData.GoodsId] = true
            end
            for _, ShopGroceryShelfData in pairs(likeSettingData.ShelfDatas) do
                if map[ShopGroceryShelfData.GoodsId] then
                    count = count + 1
                end
            end
            local isGood = XTool.CommonVariableCompare(params[1], count, params, 2)
            if isGood then
                return true, template.Desc
            end
        end
    end
    return false, template.Desc
end

-- 18 检查商品店铺收益数量
function XSkyGardenShoppingStreetAgency:CheckGoodShopGainCount(template)
    local areas = self._Model:GetAllShopAreas()
    local params = template.Params
    for _, area in pairs(areas) do
        local settingData = area:GetGroceryData()
        local likeSettingData = area:GetGroceryLikeData()
        if settingData and likeSettingData then
            local count = 0
            local map = {}
            for _, ShopGroceryShelfData in pairs(settingData.ShelfDatas) do
                map[ShopGroceryShelfData.GoodsId] = ShopGroceryShelfData
            end
            for _, ShopGroceryShelfData in pairs(likeSettingData.ShelfDatas) do
                local data = map[ShopGroceryShelfData.GoodsId]
                if data and data.GoldCount ~= ShopGroceryShelfData.GoldCount then
                    count = count + 1
                end
            end
            local isGood = XTool.CommonVariableCompare(params[1], count, params, 2)
            if isGood then
                return true, template.Desc
            end
        end
    end
    return false, template.Desc
end

-- 19 检查甜品店收益
function XSkyGardenShoppingStreetAgency:CheckDessertShopGain(template)
    local areas = self._Model:GetAllShopAreas()
    local params = template.Params
    for _, area in pairs(areas) do
        local settingData = area:GetDessertData()
        local likeSettingData = area:GetDessertLikeData()
        if settingData and likeSettingData then
            local count = settingData.Gold - likeSettingData.Gold
            local isGood = XTool.CommonVariableCompare(params[1], count, params, 2)
            if isGood then
                return true, template.Desc
            end
        end
    end
    return false, template.Desc
end

-- 20 检查甜品店逆序数
function XSkyGardenShoppingStreetAgency:CheckDessertShopPerfectCount(template)
    local areas = self._Model:GetAllShopAreas()
    local params = template.Params
    for _, area in pairs(areas) do
        local settingData = area:GetDessertData()
        if settingData then
            local count = 0
            for i = 1, #settingData.GoodsIdList do
                for j = i + 1, #settingData.GoodsIdList do
                    if settingData.GoodsIdList[i] > settingData.GoodsIdList[j] then
                        count = count + 1
                    end
                end
            end
            local isGood = XTool.CommonVariableCompare(params[1], count, params, 2)
            if isGood then
                return true, template.Desc
            end
        end
    end
    return false, template.Desc
end

--endregion

--region 条件判断实现B 指引

-- 21 检查当前关卡和当前轮次
function XSkyGardenShoppingStreetAgency:CheckStageAndRound(template)
    local params = template.Params
    local checkStageId = params[1]
    local checkRound = params[2]
    local stageId = self._Model:GetCurrentStageId()
    local round = self._Model:GetRunRound()
    return checkStageId == stageId and (checkRound == round or checkRound == 0), template.Desc
end

-- 22 检查当前关卡是否处于游玩状态
function XSkyGardenShoppingStreetAgency:CheckRunStageState(template)
    local params = template.Params
    local checkState = params[1]
    local isRunning = self._Model:IsRunningGame()
    local status = isRunning and 1 or 0
    return status == checkState, template.Desc
end

-- 23 检查当前是否有对应类型的气泡
function XSkyGardenShoppingStreetAgency:CheckGameBubble(template)
    local params = template.Params
    local checkType = params[1]
    return self:GetBubbleCount(checkType) > 0, template.Desc
end

-- 24 检查当前玩家金币数量是否大于某个数值
function XSkyGardenShoppingStreetAgency:CheckGameGoldNum(template)
    local params = template.Params
    local checkType = params[1]
    return XTool.CommonVariableCompare(checkType, self._Model:GetStageResById(XMVCA.XSkyGardenShoppingStreet.StageResType.InitGold), params, 2), template.Desc
end

-- 25 检查当前玩家金币数量是否小于某个数值
function XSkyGardenShoppingStreetAgency:CheckGameFriendlyNum(template)
    local params = template.Params
    local checkType = params[1]
    return XTool.CommonVariableCompare(checkType, self._Model:GetStageResById(XMVCA.XSkyGardenShoppingStreet.StageResType.InitFriendly), params, 2), template.Desc
end

-- 26 判断当前是否存在突发事件
function XSkyGardenShoppingStreetAgency:CheckGameConflictEvent(template)
    local params = template.Params
    if params[1] == 0 then
        return self:GetBubbleCount(3) <= 0, template.Desc
    end
    return self:GetBubbleCount(3) > 0, template.Desc
end

-- 27 判断当前处于开业促销还是常规促销
function XSkyGardenShoppingStreetAgency:CheckGamePromotion(template)
    local params = template.Params
    local checkType = params[1]
    return self:GetPromotionSelectType() == checkType, template.Desc
end

--endregion

--endregion

--------------------------------------------------------------------------------
--region 解析数据

function XSkyGardenShoppingStreetAgency:ParseFuncByConfig(attrType, shopId, config)
    local resCfgs = self._Model:GetStageResConfigs()
    local resCfg = resCfgs[attrType]
    local key = resCfg.InitKey
    if string.IsNilOrEmpty(key) then return 0 end
    return config[key] or 0
end

function XSkyGardenShoppingStreetAgency:ParseAttributeByConfig(attrType, shopId, config)
    return self:ParseFuncByConfig(attrType, shopId, config)
end

--endregion
----------public end----------


return XSkyGardenShoppingStreetAgency