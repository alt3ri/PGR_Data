XPayManagerCreator = function()
    local Application = CS.UnityEngine.Application
    local Platform = Application.platform
    local RuntimePlatform = CS.UnityEngine.RuntimePlatform
    local PayAgent = nil

    ---@class XPayManager
    local XPayManager = {}
    local IsGetFirstRechargeReward  -- 是否领取首充奖励
    local FirstRewardReceivedList -- 领取首充奖励列表
    local IsFirstRecharge           -- 是否首充
    local TotalPayMoney = 0 --累计充值

    local METHOD_NAME = {
        Initiated = "PayInitiatedRequest",
        CheckResult = "PayCheckResultRequest",
        GetFirstPayReward = "GetFirstPayRewardRequest", -- 获取首充奖励
    }

    local function IsSupportPay()
        return Application.isMobilePlatform or
                (Platform == RuntimePlatform.WindowsPlayer or Platform == RuntimePlatform.WindowsEditor)
    end

    local function InitAgent()
        if Platform == RuntimePlatform.Android then
            PayAgent = XPayHeroAgent.New(XPlayer.Id)
        elseif Platform == RuntimePlatform.IPhonePlayer then
            PayAgent = XPayHeroAgent.New(XPlayer.Id)
        elseif Platform == RuntimePlatform.WindowsPlayer and not CS.XApplication.Debug then
            -- PC 正式充值
            PayAgent = XPayHeroAgent.New(XPlayer.Id)
        elseif Platform == RuntimePlatform.WindowsPlayer or Platform == RuntimePlatform.WindowsEditor then
            PayAgent = XPayAgent.New(XPlayer.Id)
        end
    end

    local function DoInit()
        XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, function()
            InitAgent()
        end)
    end

    local DoPay = function(productKey, cpOrderId, goodsId)
        PayAgent:Pay(productKey, cpOrderId, goodsId)
    end

    function XPayManager.Pay(productKey)
        if XUserManager.HasLoginError() then
            -- 临时兼容sdk会回调多次登陆成功的问题
            XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), "账号信息过期，请重新登陆", XUiManager.DialogType.OnlySure, nil, function()
                XUserManager.ClearLoginData()
            end)
            return
        end

        if not IsSupportPay() or not PayAgent then
            return
        end

        local template = XPayConfigs.GetPayTemplate(productKey)
        if not template then
            return
        end

        --CheckPoint: APPEVENT_REDEEMED_AND_MONTHCARD
        XAppEventManager.PurchasePayAppLogEvent(template.PayId)

        XDataCenter.KickOutManager.Lock(XEnumConst.KICK_OUT.LOCK.RECHARGE)
        XNetwork.Call(METHOD_NAME.Initiated, { Key = productKey }, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.RECHARGE, true)
                return
            end
            DoPay(productKey, res.GameOrder, template.GoodsId)
        end)
    end

    -- 领取首充奖励请求
    function XPayManager.GetFirstPayRewardReq(cb)
        XNetwork.Call(METHOD_NAME.GetFirstPayReward, nil, function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end

            IsGetFirstRechargeReward = true
            if cb then
                cb()
            end
            XUiManager.OpenUiObtain(res.RewardList)
            XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
        end)
    end

    function XPayManager.GetFirstRecharge()
        return IsFirstRecharge
    end

    function XPayManager.GetFirstRechargeReward()
        return IsGetFirstRechargeReward
    end

    -- 是否首充奖励领取
    function XPayManager.IsGotFirstReCharge()
        local isRecharge = XPayManager.GetFirstRecharge()
        if not isRecharge then
            return true
        end

        local isGot = XPayManager.GetFirstRechargeReward()
        return isGot
    end

    -- 是否月卡奖励领取
    function XPayManager.IsGotCard(monthlyCardId)
        if not XOverseaManager.IsENRegion() then
            local isBuy = XDataCenter.PurchaseManager.IsYkBuyed()
            if not isBuy then
                return true
            end

            local data = XDataCenter.PurchaseManager.GetYKInfoData()
            if not data then
                return false
            end
            return data.IsDailyRewardGet
        else
            if not monthlyCardId then
                return true
            end
            local data = XDataCenter.PurchaseManager.GetYKInfoDataById(monthlyCardId)
            if not data or data.DailyRewardRemainDay == 0 then
                return true
            end
            return data.IsDailyRewardGet
        end
    end

    -- 显示网页充值成功弹框
    function XPayManager.CheckShowWebTips()
        -- 战斗中不弹
        if CS.XFight.IsRunning then
            return false
        end
        if not PayAgent then
            return false
        end
        if not PayAgent:CheckWebTips() then
            return false
        end
        PayAgent:WebTipsPaySuccess()
        return true
    end

    function XPayManager.NotifyPayResult(data)
        if not data then
            return
        end

        TotalPayMoney = data.TotalPayMoney
        IsFirstRecharge = XPayConfigs.CheckFirstPay(data.TotalPayMoney)
        local orderList = data.DealGameOrderList
        -- 测试充值
        if not orderList or #orderList == 0 then
            return
        end
        if IsFirstRecharge then
            --CheckPoint: APPEVENT_FIRST_BUY
            XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.First_buy)
        end

        PayAgent:OnDealSuccess(orderList)
        XEventManager.DispatchEvent(XEventId.EVENT_CARD_REFRESH_WELFARE_BTN)
    end

    function XPayManager.NotifyPayInfo(data)
        if not data then
            return
        end

        -- v4.0 新增奖励，老玩家出现一半已领，一半未领取的情况
        if not data.FirstRewardReceivedList then
            IsGetFirstRechargeReward = data.IsGetFirstPayReward
        else
            FirstRewardReceivedList = data.FirstRewardReceivedList
            IsGetFirstRechargeReward = false
            local configs = XPayConfigs.GetFirstPayConfigs()
            local matchCount = 0
            for id, config in pairs(configs) do
                for i = 1, #data.FirstRewardReceivedList do
                    if data.FirstRewardReceivedList[i] == id then
                        matchCount = matchCount + 1
                        break
                    end
                end
            end
            if matchCount == #configs then
                IsGetFirstRechargeReward = true
            end
        end
        TotalPayMoney = data.TotalPayMoney
        IsFirstRecharge = XPayConfigs.CheckFirstPay(data.TotalPayMoney)
    end
    
    function XPayManager.IsFirstRechargeRewardReceived(id)
        if IsGetFirstRechargeReward then
            return true
        end
        if FirstRewardReceivedList then
            for i = 1, #FirstRewardReceivedList do
                if FirstRewardReceivedList[i] == id then
                    return true
                end
            end
        end
        return false
    end
    
    function XPayManager.GetSmallRewards()
        local configs = XPayConfigs.GetFirstPayConfigs()
        local rewards = {}
        for id, config in pairs(configs) do
            local rewardId = config.SmallRewardId
            local rewardList = XRewardManager.GetRewardList(rewardId)
            if rewardList then
                for i = 1, #rewardList do
                    local data = {
                        Item = rewardList[i],
                        IsReceived = XDataCenter.PayManager.IsFirstRechargeRewardReceived(id),
                        RewardId = rewardId,
                    }
                    table.insert(rewards, data)
                end
            end
        end
        return rewards
    end
    
    function XPayManager.GetBigRewards()
        local configs = XPayConfigs.GetFirstPayConfigs()
        local rewards = {}
        for id, config in pairs(configs) do
            local rewardId = config.BigRewardId
            local rewardList = XRewardManager.GetRewardList(rewardId)
            if rewardList then
                for i = 1, #rewardList do
                    local data = {
                        Item = rewardList[i],
                        IsReceived = XDataCenter.PayManager.IsFirstRechargeRewardReceived(id),
                        RewardId = rewardId
                    }
                    table.insert(rewards, data)
                end
            else
                XLog.Error("XPayManager.GetBigRewards rewardId not exist: " .. rewardId)
            end
        end
        return rewards
    end

    function XPayManager.GetTotalPayMoney()
        return TotalPayMoney
    end

    DoInit()

    return XPayManager
end

XRpc.NotifyPayResult = function(data)
    -- 测试充值
    XDataCenter.PayManager.NotifyPayResult(data)
end

XRpc.NotifyPayInfo = function(data)
    XDataCenter.PayManager.NotifyPayInfo(data)
end