---@class XPunishaarNetworkAgency : XAgency
---@field private _Model XPunishaarModel
---@field private _MainAgency XPunishaarAgency
local XPunishaarNetworkAgency = XClass(XAgency, "XPunishaarNetworkAgency")

local NetworkLockFlagEnum = {
    GetStageData = 1,
    StartStage = 2,
    ContinueStage = 3,
    QuitStage = 4,
    SelectShop = 5,
    RefreshShop = 6,
    BuyGoods = 7,
    FreezeGoods = 8,
    SellCard = 9,
    ExitNode = 10,
    EnterFight = 11,
    SelectFight = 12,
    FinishFight = 13,
    SelectEvent = 14,
    FinishEvent = 15,
    SetCardPos = 16,
    HandlePendingReward = 17,
    DiscardCard = 18,
    AwayStage = 19,
}

local LockMaxTime = 60  -- 请求锁兜底超时（秒），正常流程由成功/异常回调提前解锁

function XPunishaarNetworkAgency:OnInit()
    self._NetworkRequestLock = nil
end

function XPunishaarNetworkAgency:InitRpc()
    XRpc.NotifyPunishaarLoginData = handler(self, self.OnNotifyPunishaarLoginData)
    XRpc.NotifyPunishaarGoldChange = handler(self, self.OnNotifyPunishaarGoldChange)
    XRpc.NotifyPunishaarMasterCardChange = handler(self, self.OnNotifyPunishaarMasterCardChange)
    XRpc.NotifyPunishaarSubCardChange = handler(self, self.OnNotifyPunishaarSubCardChange)
    XRpc.NotifyPunishaarRewardResult = handler(self, self.OnNotifyPunishaarRewardResult)
end

function XPunishaarNetworkAgency:InitEvent()
    XEventManager.AddEventListener(XEventId.EVENT_NETWORK_DISCONNECT, self.ClearNetLocks, self)
end

function XPunishaarNetworkAgency:RemoveEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_NETWORK_DISCONNECT, self.ClearNetLocks, self)
end

function XPunishaarNetworkAgency:ResetAll()
    self:ClearNetLocks()
end

function XPunishaarNetworkAgency:OnRelease()
end

local function GetCatalogTypeByCardId(cardId)
    if not cardId or cardId == 0 then
        return nil
    end

    local cfg = XMVCA.XPunishaar:GetTablePunishaarCard(cardId, true)

    if not cfg then
        return nil
    end

    local CardType = XMVCA.XPunishaar.EnumConst.CardType

    local CatalogType = XMVCA.XPunishaar.EnumConst.CatalogType

    if cfg.Type == CardType.Character then
        return CatalogType.Character

    elseif cfg.Type == CardType.Weapon then
        return CatalogType.Partner

    elseif cfg.Type == CardType.Awareness then
        return CatalogType.Equip

    elseif cfg.Type == CardType.Resonance then
        return CatalogType.Resonance
    end
end
--region Lock

--- 检查 flag 是否处于锁定状态。
--- 注意：含超时自动解锁的副作用（命名有意体现 "AndRefresh"），勿视为纯查询。
---@param flag number NetworkLockFlagEnum 值
---@return boolean
function XPunishaarNetworkAgency:IsLockedAndRefresh(flag)
    if not self._NetworkRequestLock or not self._NetworkRequestLock[flag] then
        return false
    end

    local passTime = XTime.GetServerNowTimestamp() - self._NetworkRequestLock[flag]
    if passTime > LockMaxTime then
        self:UnlockWithFlag(flag)
        return false
    end

    return true
end

function XPunishaarNetworkAgency:LockWithFlag(flag)
    if not self._NetworkRequestLock then
        self._NetworkRequestLock = {}
    end
    self._NetworkRequestLock[flag] = XTime.GetServerNowTimestamp()
end

--- 解锁：置 nil 使 key 真正从表中移除，保证 IsTableEmpty 等检查语义正确
function XPunishaarNetworkAgency:UnlockWithFlag(flag)
    if XTool.IsTableEmpty(self._NetworkRequestLock) then
        return
    end
    self._NetworkRequestLock[flag] = nil
end

function XPunishaarNetworkAgency:ClearNetLocks()
    self._NetworkRequestLock = nil
end

--endregion

--region Network Request

--- 选定事件（事件节点 WaitSelect 时，从 RandomEventIds 中选一个）。
---@param eventId number 选定的事件 Id（必须在 EventInfo.RandomEventIds 内）
---@param cb function(node: table|nil) 更新后的当前节点
function XPunishaarNetworkAgency:DoSelectEvent(eventId, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.SelectEvent) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.SelectEvent)

    XNetwork.Call("XPunishaarSelectEventRequest", { EventId = eventId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.SelectEvent)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then cb(nil) end
            return
        end
        if cb then cb(res.Node) end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.SelectEvent)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 完成当前事件（Processing → Finished 或 RewardReplace）。
--- 增强（#62）：读 res.Node + Model:SetCurrentNode + 回调传 node（原仅传 success 布尔、丢弃 Node），
--- 使调用方能按 node.Status==RewardReplace 分流到 _AutoHandlePendingReward（proto XPunishaarFinishEventResponse: XPunishaarNodeResponse 带 Node）。
---@param cb function(node: table|nil) 更新后的当前节点；nil=失败/异常
function XPunishaarNetworkAgency:DoFinishEvent(cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.FinishEvent) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.FinishEvent)

    XNetwork.Call("XPunishaarFinishEventRequest", nil, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.FinishEvent)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then cb(nil) end
            return
        end
        self._Model:SetCurrentNode(res.Node)
        if cb then cb(res.Node) end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.FinishEvent)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
        if cb then cb(nil) end
    end)
end

--- 处理暂存待发放的奖励卡牌（RewardReplace 状态：领取并指定落点 / 放弃）。
--- Response 继承 XPunishaarNodeResponse（含 .Node，处理后节点转 Finished）。奖励经 NotifyPunishaarRewardResult 下发，Response 不带奖励列表。
---@param isAccept boolean true=领取暂存卡牌，false=放弃
---@param cardDetail table XPunishaarRewardCardDetailInfo（{ AreaType, StartPos, SubCardId, MasterCardId }）；放弃时可为 nil
---@param cb function(node: table|nil) 更新后的当前节点
function XPunishaarNetworkAgency:DoHandlePendingReward(isAccept, cardDetail, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.HandlePendingReward) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.HandlePendingReward)

    XNetwork.Call("XPunishaarHandlePendingRewardRequest", { IsAccept = isAccept, CardDetail = cardDetail }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.HandlePendingReward)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then cb(nil) end
            return
        end
        if cb then cb(res.Node) end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.HandlePendingReward)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 退出当前节点，推进到下一节点（或触发本局结算）。
--- Response 含 Stage（进行中）或 SettleInfo（结算），二者互斥。奖励经 NotifyPunishaarRewardResult 下发，Response 不带奖励列表。
---@param cb function(stage: table|nil, settleInfo: table|nil)
function XPunishaarNetworkAgency:DoExitNode(cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.ExitNode) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.ExitNode)

    XNetwork.Call("XPunishaarExitNodeRequest", nil, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.ExitNode)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil, nil)
            end
            return
        end
        -- TODO: 若 res.Stage 不为 nil，更新 Model 的 CurrentStage 并刷新节点 UI
        -- TODO: 若 res.SettleInfo 不为 nil，打开结算界面
        if cb then
            cb(res.Stage, res.SettleInfo)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.ExitNode)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 战前准备阶段确认进入战斗（普通战斗节点）。
---@param cb function(node: table|nil)
function XPunishaarNetworkAgency:DoEnterFight(cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.EnterFight) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.EnterFight)

    XNetwork.Call("XPunishaarEnterFightRequest", nil, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.EnterFight)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil)
            end
            return
        end
        if cb then
            cb(res.Node)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.EnterFight)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 选定战斗（选择战斗节点 WaitSelect 时，从候选 RandomFightIds 中选一个）。
---@param fightId number 选定的战斗流水Id
---@param cb function(node: table|nil)
function XPunishaarNetworkAgency:DoSelectFight(fightId, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.SelectFight) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.SelectFight)

    XNetwork.Call("XPunishaarSelectFightRequest", { FightId = fightId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.SelectFight)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil)
            end
            return
        end
        if cb then
            cb(res.Node)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.SelectFight)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 上报战斗结果：胜利标记节点完成，失败扣耐久（归零则结算）。
--- Response 含 Stage（进行中）或 SettleInfo（结算），二者互斥。奖励经 NotifyPunishaarRewardResult 下发，Response 不带奖励列表。
---@param isWin boolean
---@param loseMaxColor number XPunishaarSignalBallColor，胜利时传 0
---@param stats table|nil 战斗埋点统计（FightControl:CollectBattleStats 产出，字段对齐 proto；nil 走默认零值）
---@param cb function(stage: table|nil, settleInfo: table|nil)
function XPunishaarNetworkAgency:DoFinishFight(isWin, loseMaxColor, stats, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.FinishFight) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.FinishFight)

    XNetwork.Call("XPunishaarFinishFightRequest", {
        IsWin = isWin,
        LoseMaxSignalBallColor = isWin and 0 or (loseMaxColor or 0),
        FightTime = stats and stats.FightTime or 0,
        FightSpeed = stats and stats.FightSpeed or false,
        IsAutoFight = stats and stats.IsAutoFight or false,
        UseSkillCount = stats and stats.UseSkillCount or 0,
        AutoUseSkillCount = stats and stats.AutoUseSkillCount or 0,
        BallProduction = stats and stats.BallProduction or 0,
        BallConsumption = stats and stats.BallConsumption or 0,
    }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.FinishFight)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil, nil)
            end
            return
        end
        if cb then
            cb(res.Stage, res.SettleInfo)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.FinishFight)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 选定商店（多候选时由玩家选择，单候选无需调用；选定后触发首次免费刷新）。
---@param shopId number 选定的商店 Id（必须在 ShopInfo.CandidateShopIds 内）
---@param cb function(node: table|nil) 更新后的当前节点
function XPunishaarNetworkAgency:DoSelectShop(shopId, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.SelectShop) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.SelectShop)

    XNetwork.Call("XPunishaarSelectShopRequest", { ShopId = shopId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.SelectShop)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil)
            end
            return
        end
        self._Model:SetCurrentNode(res.Node)
        if cb then
            cb(res.Node)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.SelectShop)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 刷新商店商品（扣除刷新费用，保留冻结槽，整批刷新非冻结槽）。
--- 客户端前置 0.6s CD 检查（基于服务端时间），CD 内拦截 + 飘窗提示（ShopRefreshCDTip）。
---@param cb function(node: table|nil) 更新后的当前节点
local SHOP_REFRESH_CD = 0.6  -- 秒

function XPunishaarNetworkAgency:DoRefreshShop(cb)
    -- 0.6s CD 检查（基于服务端时间，防快速连点；区别于请求锁——锁是请求中防重发，CD 是成功后冷却）
    local now = XTime.GetServerNowTimestamp()
    if self._LastRefreshShopTime and now - self._LastRefreshShopTime < SHOP_REFRESH_CD then
        XUiManager.TipMsg(XMVCA.XPunishaar:GetClientStringByKey("ShopRefreshCDTip") or "")
        return
    end
    self._LastRefreshShopTime = now

    if self:IsLockedAndRefresh(NetworkLockFlagEnum.RefreshShop) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.RefreshShop)

    XNetwork.Call("XPunishaarRefreshShopRequest", nil, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.RefreshShop)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil)
            end
            return
        end
        -- TODO: 将 res.Node 更新到 Model 的 CurrentStage.CurrentNode，刷新商店商品列表
        if cb then
            cb(res.Node)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.RefreshShop)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
        -- 网络异常也通知失败：补 cb(nil) 让 RefreshShop 走失败分支派发 RefreshShopFail（FightMain 播 ReShowFail）#商店刷新动效
        if cb then
            cb(nil)
        end
    end)
end

--- 购买指定槽位的商品。
---@param index number 槽位索引（1-based，底层已统一转换）
---@param cardDetail table XPunishaarRewardCardDetailInfo（购卡辅助参数）
---@param cb function(node: table|nil) 更新后的当前节点
function XPunishaarNetworkAgency:DoBuyGoods(index, cardDetail, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.BuyGoods) then
        -- 锁命中也调 cb，防调用方归位回调永不触发致拖拽卡牌视觉卡死 #M2
        if cb then cb(nil) end
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.BuyGoods)

    XNetwork.Call("XPunishaarBuyGoodsRequest", { Index = index, CardDetail = cardDetail }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.BuyGoods)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil)
            end
            return
        end
        -- Node 含更新后的商品列表（购入卡已标 IsBought=true）；TotalMasterCards 变化由 NotifyMasterCardChange 推送处理
        self._Model:SetCurrentNode(res.Node)
        if cb then
            cb(res.Node)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.BuyGoods)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 冻结或解冻指定槽位的商品（下次刷新时保留冻结槽）。
---@param index number 槽位索引（1-based，底层已统一转换）
---@param isFreeze boolean true=冻结，false=解冻
---@param cb function(node: table|nil) 更新后的当前节点
function XPunishaarNetworkAgency:DoFreezeGoods(index, isFreeze, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.FreezeGoods) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.FreezeGoods)

    XNetwork.Call("XPunishaarFreezeGoodsRequest", { Index = index, IsFreeze = isFreeze }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.FreezeGoods)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil)
            end
            return
        end
        -- TODO: 将 res.Node 更新到 Model 的 CurrentStage.CurrentNode，刷新商品冻结状态图标
        if cb then
            cb(res.Node)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.FreezeGoods)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 卖出主卡（仅限主卡，含镶嵌副卡一并卖出，按 Sell 总和加金币）。
---@param masterCardId number 主卡唯一 Id（非 CardId，是 MasterCard.Id）
---@param cb function(node: table|nil) 更新后的当前节点
function XPunishaarNetworkAgency:DoSellCard(masterCardId, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.SellCard) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.SellCard)

    XNetwork.Call("XPunishaarSellCardRequest", { MasterCardId = masterCardId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.SellCard)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil)
            end
            return
        end
        -- TODO: 将 res.Node 更新到 Model（含 TotalMasterCards 移除已卖卡），刷新装备栏
        if cb then
            cb(res.Node)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.SellCard)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 丢弃卡牌（主卡 or 副卡）。
--- IsMasterCard=true 丢弃主卡本身；false 丢弃该主卡携带的副卡。
--- 响应仅 XCode 无 Node，成功后客户端本地同步（Model 移除/清 SubCardId）。
---@param masterCardId number 目标主卡唯一 Id（丢弃副卡时亦用此定位其所在主卡）
---@param isMasterCard boolean true=丢弃主卡，false=丢弃副卡
---@param cb function(success: boolean)
function XPunishaarNetworkAgency:DoDiscardCard(masterCardId, isMasterCard, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.DiscardCard) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.DiscardCard)

    XNetwork.Call("XPunishaarDiscardCardRequest", { IsMasterCard = isMasterCard, MasterCardId = masterCardId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.DiscardCard)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then cb(false) end
            return
        end
        if cb then cb(true) end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.DiscardCard)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end
--- 提交全量卡牌位置（对战区+背包混放；须覆盖全部主卡）。
--- 响应无 Node，成功后客户端本地同步位置（Model:UpdateCardPositions）。
---@param cardPosList table XPunishaarCardPosInfo[]（{ Id, AreaType, StartPos }）
---@param cb function(success: boolean)
function XPunishaarNetworkAgency:DoSetCardPos(cardPosList, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.SetCardPos) then return end
    self:LockWithFlag(NetworkLockFlagEnum.SetCardPos)
    XNetwork.Call("XPunishaarSetCardPosRequest", { CardPosList = cardPosList }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.SetCardPos)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then cb(false) end
            return
        end
        self._Model:UpdateCardPositions(cardPosList)
        if cb then cb(true) end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.SetCardPos)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

---@param cb function(success: boolean)
function XPunishaarNetworkAgency:DoGetStageData(cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.GetStageData) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.GetStageData)

    XNetwork.Call("XPunishaarGetDataRequest", nil, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.GetStageData)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(false)
            end
            return
        end
        self._Model:InitDataDb(res.DataDb)
        if cb then
            cb(true)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.GetStageData)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 开始新的一局（从局外选关进入）
--- 成功后透传 Server.XPunishaarStage 给 cb，供 RunControl:EnterRun 使用
---@param stageId number
---@param cb function(stage: table) Server.XPunishaarStage
function XPunishaarNetworkAgency:DoStartStage(stageId, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.StartStage) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.StartStage)

    XNetwork.Call("XPunishaarStartStageRequest", { StageId = stageId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.StartStage)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        -- 服务端数据落 Model，RunControl / 表现层统一从 Model 读取
        self._Model:SetCurrentStage(res.Stage)
        if cb then
            cb(res.Stage)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.StartStage)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 继续已有的一局（存档重进）
--- 成功后透传 Server.XPunishaarStage 给 cb，供 RunControl:EnterRun 使用（与 DoStartStage 对称）
---@param stageId number
---@param cb function(stage: table) Server.XPunishaarStage
function XPunishaarNetworkAgency:DoContinueStage(stageId, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.ContinueStage) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.ContinueStage)

    XNetwork.Call("XPunishaarEnterStageRequest", { StageId = stageId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.ContinueStage)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil)
            end
            return
        end
        self._Model:SetCurrentStage(res.Stage)
        if cb then
            cb(res.Stage)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.ContinueStage)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 退出当前局（放弃或结算后退出）
---@param cb function(settleInfo: table|nil) 成功回调透传服务端整局结算信息；失败传 nil
function XPunishaarNetworkAgency:DoQuitStage(cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.QuitStage) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.QuitStage)

    XNetwork.Call("XPunishaarQuitStageRequest", nil, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.QuitStage)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then
                cb(nil)
            end
            return
        end
        if cb then
            cb(res.SettleInfo)
        end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.QuitStage)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--- 暂离当前局（保存存档，下次可经 ContinueStage 继续）。
--- 与 QuitStage 对称：AwayStage 保留存档可续局，QuitStage 放弃当局不保留。
--- Response 仅 XCode（无 Node/SettleInfo），成功后客户端本地执行暂离逻辑（ExitRun 关 FightMain）。
---@param stageId number 暂离的关卡存档 StageId
---@param cb function(success: boolean) 成功传 true，失败传 false
function XPunishaarNetworkAgency:DoAwayStage(stageId, cb)
    if self:IsLockedAndRefresh(NetworkLockFlagEnum.AwayStage) then
        return
    end
    self:LockWithFlag(NetworkLockFlagEnum.AwayStage)

    XNetwork.Call("XPunishaarAwayStageRequest", { StageId = stageId }, function(res)
        self:UnlockWithFlag(NetworkLockFlagEnum.AwayStage)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then cb(false) end
            return
        end
        if cb then cb(true) end
    end, nil, function(exception)
        self:UnlockWithFlag(NetworkLockFlagEnum.AwayStage)
        XUiManager.SystemDialogTip("", CS.XTextManager.GetRpcExceptionCodeText(exception.Code), XUiManager.DialogType.OnlySure)
    end)
end

--endregion

--region RPC

function XPunishaarNetworkAgency:OnNotifyPunishaarLoginData(data)
    self._Model:OnNotifyPunishaarLoginData(data)
end

function XPunishaarNetworkAgency:OnNotifyPunishaarGoldChange(data)
    self._Model:SetCurrentGold(data.Gold)
    XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_GOLD_CHANGE)
end

function XPunishaarNetworkAgency:OnNotifyPunishaarMasterCardChange(data)
    self._Model:UpdateMasterCardByNotify(data.AddedCard, data.RemovedCardIds)

    local addedCard = data.AddedCard

    if addedCard and addedCard.TemplateId then
        local catalogType = GetCatalogTypeByCardId(addedCard.TemplateId)

        if catalogType then 
            self._Model:AddCollectionUnlocked(catalogType, addedCard.TemplateId)
        end
    end

    XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_MASTER_CARD_CHANGE)
end

function XPunishaarNetworkAgency:OnNotifyPunishaarSubCardChange(data)
    self._Model:UpdateSubCardByNotify(data.MasterCardId, data.SubCardId)

    local catalogType = GetCatalogTypeByCardId(data.SubCardId)

    if catalogType then
        self._Model:AddCollectionUnlocked(catalogType, data.SubCardId)
    end

    XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_SUB_CARD_CHANGE)
end

--- 通用奖励下发：缓存整体到 Model + 更新局内槽位上限 + 派发事件（槽位解锁/整体奖励）。
--- 金币/卡牌的实际状态由专用 Notify（GoldChange/MasterCardChange/SubCardChange）单独推送+派发，
--- 此处仅缓存奖励列表（表现层弹窗集中展示）+ 槽位解锁更新 stage.GridLimit + 派发槽位解锁事件。
function XPunishaarNetworkAgency:OnNotifyPunishaarRewardResult(data)
    self._Model:OnNotifyPunishaarRewardResult(data.StageId, data.RewardGoodsList)

    -- 派发槽位解锁事件（表现层订阅刷新 slot）
    local rewardList = data.RewardGoodsList
    if rewardList then
        local RewardType = XMVCA.XPunishaar.EnumConst.RewardType
        for _, reward in ipairs(rewardList) do
            if reward.RewardType == RewardType.FightAreaGridLimit then
                XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_FIGHT_AREA_GRID_UNLOCK, reward.Amount)
            elseif reward.RewardType == RewardType.BagGridLimit then
                XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_BAG_GRID_UNLOCK, reward.Amount)
            end
        end
    end

    -- 派发整体奖励事件（表现层拉 Model:GetLastRewardGoodsList 弹窗集中展示，含金币增量等）
    XEventManager.DispatchEvent(XEventId.EVENT_PUNISHAAR_REWARD_RESULT, data.StageId)
end

--endregion

return XPunishaarNetworkAgency
