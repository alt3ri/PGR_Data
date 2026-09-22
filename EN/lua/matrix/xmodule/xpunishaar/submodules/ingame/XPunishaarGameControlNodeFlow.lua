--- Control部分类，此处处理局内节点流程（节点选定/透传/战斗上报/暂存奖励/局流程切换）。
--- 下游接口：委托 NetworkAgency:Do* + Model 同步 + RunControl:TransitionTo/AdvanceNode。
--- 上游调用方：RunControl（流程状态机路由时调）+ UI（战前按钮/补强离开/结算退出）。
local XPunishaarGameControl = XClassPartial('XPunishaarGameControl')

--- 选定商店并更新 Model 节点（WaitSelectShop → Processing）
---@param shopId number
---@param cb function(success: boolean)
function XPunishaarGameControl:SelectShop(shopId, cb)
    XMVCA.XPunishaar.NetworkAgency:DoSelectShop(shopId, function(node)
        if not node then
            if cb then cb(false) end
            return
        end
        self._Model:SetCurrentNode(node)
        if cb then cb(true) end
    end)
end

--- 选定事件（事件节点 WaitSelect 时，从 RandomEventIds 取第一个候选 Id 调用）。
---@param eventId number
---@param cb function(success: boolean)
function XPunishaarGameControl:SelectEvent(eventId, cb)
    XMVCA.XPunishaar.NetworkAgency:DoSelectEvent(eventId, function(node)
        if not node then if cb then cb(false) end return end
        self._Model:SetCurrentNode(node)
        if cb then cb(true) end
    end)
end

--- 完成当前事件（Processing → Finished 或 RewardReplace）。
--- 增强（#62）：回调传更新后的 node（原仅 success 布尔，DoFinishEvent 已读 res.Node+SetCurrentNode），使调用方能按 node.Status 分流。
---@param cb function(node: table|nil) 更新后的当前节点；nil=失败
function XPunishaarGameControl:FinishEvent(cb)
    XMVCA.XPunishaar.NetworkAgency:DoFinishEvent(function(node)
        if cb then cb(node) end
    end)
end

--- 【#62】FinishEvent 回调分流：node.Status==RewardReplace→_AutoHandlePendingReward（内部链路至 ExitNode）；Finished/其他→ExitNode。
---@param node table 更新后的节点（DoFinishEvent 回传）
function XPunishaarGameControl:_FinishEventThenExit(node)
    if not node then return end
    if node.Status == XMVCA.XPunishaar.EnumConst.NodeStatus.RewardReplace then
        self:_AutoHandlePendingReward(node)
    else
        self:ExitNode()
    end
end

--- 事件节点无 UI 时的自动透传：按当前状态选择最短路径完成事件并退出节点。
--- WaitSelect     → SelectEvent(首个候选) → FinishEvent → _FinishEventThenExit（RewardReplace/Finished 分流）
--- Processing     → FinishEvent → _FinishEventThenExit
--- RewardReplace  → 自动处理暂存奖励卡(默认领取+找位) → ExitNode
--- 其余状态       → ExitNode（Finished 等直接过）
---@param node table Server.XPunishaarNode
function XPunishaarGameControl:AutoPassthroughEvent(node)
    local status = node.Status

    if status == XMVCA.XPunishaar.EnumConst.NodeStatus.WaitSelect then
        local candidateIds = node.EventInfo and node.EventInfo.RandomEventIds
        local firstId = candidateIds and candidateIds[1]
        if not firstId then
            XLog.Error("[Punishaar] AutoPassthroughEvent: WaitSelect 但无候选事件 Id")
            return
        end
        self:SelectEvent(firstId, function(ok)
            if not ok then return end
            self:FinishEvent(handler(self, self._FinishEventThenExit))
        end)
    elseif status == XMVCA.XPunishaar.EnumConst.NodeStatus.Processing then
        self:FinishEvent(handler(self, self._FinishEventThenExit))
    elseif status == XMVCA.XPunishaar.EnumConst.NodeStatus.RewardReplace then
        -- 升级预判：同 TemplateId 同 Level → 合并升级（不占槽，不开 SellCardTip）
        if self:_TryUpgradePendingReward(node) then
            return
        end
        -- 非升级（放置）：重连/重进重开卡牌保留界面让玩家决断（放弃/卖弃腾位后自动放入）
        -- 不走 _AutoHandlePendingReward 的分支A静默自动放置（致"默认 ExitNode"、玩家无感丢决断权）
        -- _EnterManualPlacement 开 SellCardTip(RewardFull)；双区满则留玩家卖/弃腾位后自动放入，或点放弃。
        local pendingCardId = node and node.PendingRewardCardId
        if not pendingCardId or pendingCardId == 0 then
            XLog.Warning("[Punishaar] AutoPassthroughEvent: RewardReplace 但 PendingRewardCardId 缺失（服务端未下发？），无法重开承载界面，fallback ExitNode")
            self:ExitNode()
        else
            self:_EnterManualPlacement(node, pendingCardId)
        end
    else
        self:ExitNode()
    end
end

--- 剧情节点(AvgNode)无 UI 时的自动透传：剧情进入即 Processing、不经 Finished（服务端语义），
--- 无候选选择、无完成上报，直接 ExitNode 推进下一节点。
--- TODO: 临时透传逃生，正式方案需接 AVG 剧情播放面板，播放结束后再 ExitNode。
---@param node table Server.XPunishaarNode
function XPunishaarGameControl:AutoPassthroughStory(node)
    local status = node and node.Status
    -- 剧情节点常规进入即 Processing；其余状态（含 None）也统一直接推进，避免静默卡死
    if status ~= XMVCA.XPunishaar.EnumConst.NodeStatus.Processing then
        XLog.Warning("[Punishaar] AutoPassthroughStory: 非预期的剧情节点状态，status=" .. tostring(status)
            .. "，仍直接透传推进")
    end
    self:ExitNode()
end

--- 退出当前节点，推进到下一节点或触发本局结算。
--- res.Stage 不为 nil → 更新 Model 并由 RunControl 推进节点 UI；
--- res.SettleInfo 不为 nil → 本局结束，打开整局结算界面。
function XPunishaarGameControl:ExitNode()
    XMVCA.XPunishaar.NetworkAgency:DoExitNode(function(stage, settleInfo)
        if settleInfo then
            self:_OnStageSettled(settleInfo)
            -- 不 ExitRun：FightMain 作 #66 持久基底贯穿结算期，ExitRun 移至 ChallengeSettlement:_OnBtnExit
            XLuaUiManager.Open("UiPunishaarChallengeSettlement", settleInfo)
            return
        end
        if stage then
            self._Model:SetCurrentStage(stage)
            self.RunControl:AdvanceNode()
        end
    end)
end

--- 清除当局运行缓存（整局结算界面完成 Refresh 后跳转前调用）。
function XPunishaarGameControl:ClearCurrentRun()
    self._Model:ClearCurrentRun()
end

--- 离开补强商店：请求 EnterFight（服务端切 Remedy→Processing + 清理补强商店 ShopInfo），回战前准备 PreFight。
--- 不启动战斗（OnPlayerStartFight 留给玩家点"开始战斗"时 ConfirmEnterFight 触发）。
--- 与普通商店的"离开商店"(ExitNode 推进下一节点)语义完全不同。
function XPunishaarGameControl:LeaveRemedyShop()
    XMVCA.XPunishaar.NetworkAgency:DoEnterFight(function(node)
        if not node then return end
        self._Model:SetCurrentNode(node)
        self.RunControl:TransitionTo(XMVCA.XPunishaar.EnumConst.FightState.PreFight)
    end)
end

--- 战前准备确认进入战斗（由 XUiPanelPunishaarPreFight 的"开始战斗"按钮触发）。
--- 成功后 RunControl 负责切换到 Fighting 状态并启动战斗引擎。
--- 注意：不要重命名回 EnterFight，主 Control 中同名方法是本地引擎启动，两者用途不同。
function XPunishaarGameControl:ConfirmEnterFight()
    XMVCA.XPunishaar.NetworkAgency:DoEnterFight(function(node)
        if not node then return end
        self._Model:SetCurrentNode(node)
        self.RunControl:OnPlayerStartFight()
    end)
end

--- 选定战斗（选择战斗节点专用；WaitSelect → Processing，SelectedFightId 由此确定）。
--- 选定后方可激活"开始战斗"按钮调用 EnterFight。
---@param fightId number 候选列表中选定的战斗流水Id
---@param cb function(success: boolean)
function XPunishaarGameControl:SelectFight(fightId, cb)
    XMVCA.XPunishaar.NetworkAgency:DoSelectFight(fightId, function(node)
        if not node then if cb then cb(false) end return end
        self._Model:SetCurrentNode(node)
        if cb then cb(true) end
    end)
end

--- 处理暂存待发放的奖励卡牌（RewardReplace 状态专用：默认领取并指定落点，或放弃）。
--- 成功后节点转 Finished，更新 Model 当前节点。奖励经 NotifyPunishaarRewardResult 下发，回调不带 rewardList。
---@param isAccept boolean true=领取暂存卡牌，false=放弃
---@param cardDetail table|nil XPunishaarRewardCardDetailInfo；放弃时可为 nil
---@param cb function(success: boolean)
function XPunishaarGameControl:HandlePendingReward(isAccept, cardDetail, cb)
    XMVCA.XPunishaar.NetworkAgency:DoHandlePendingReward(isAccept, cardDetail, function(node)
        if not node then
            if cb then cb(false) end
            return
        end
        self._Model:SetCurrentNode(node)
        if cb then cb(true) end
    end)
end

--- 上报战斗结果（由 RunControl.OnBattleEnded 转发；外部勿直接调用）。
--- 无论输赢，先弹战斗结算界面；玩家点击确认后再推进后续流程（补强商店 / 推进节点 / 整局结算）。
---@param isWin boolean
---@param loseMaxColor number XPunishaarSignalBallColor（胜利传 0）
---@param stats table|nil 战斗埋点统计（FightControl:CollectBattleStats 产出；nil=测试路径无 FightControl）
function XPunishaarGameControl:FinishFight(isWin, loseMaxColor, stats)
    -- 战前耐久：发 DoFinishFight 前取，闭包捕获进回调（不读 Model，时序无关）。
    -- 服务端失败扣耐久后回包 stage.Durability 为扣减后值；delta = beforeDur - afterDur。
    local beforeDur = self:GetControl():GetCurrentDurability() or 0
    XMVCA.XPunishaar.NetworkAgency:DoFinishFight(isWin, loseMaxColor, stats, function(stage, settleInfo)
        -- 立即缓存战后 stage：BattleSettlement 显示期间各链路读 Model(GetCurrentDurability 等)需战后值，
        -- 否则 Model 停留战前值致耐久等显示错（耐久无 Notify 通道只走 stage.Durability）。
        -- 对齐 DoStartStage/DoContinueStage 回包立即 SetCurrentStage 范式。onConfirm:190 幂等覆写无害。
        if stage then
            self._Model:SetCurrentStage(stage)
        end
        -- 后续跳转决策延迟到战斗结算界面确认后执行
        local onConfirm = function()
            if settleInfo then
                self:_OnStageSettled(settleInfo)
                -- 不 ExitRun：FightMain 作 #66 持久基底贯穿结算期，ExitRun 移至 ChallengeSettlement:_OnBtnExit
                -- SafeClose BattleSettlement（关前守卫：BattleSettlement 经 CloseWithCallback 自关，onConfirm 在关后回调跑，
                --   已关则 SafeClose no-op 兜底；未关则安全关。FightMain 基底盖住，再 Open ChallengeSettlement Pop 叠）
                XLuaUiManager.SafeClose("UiPunishaarBattleSettlement")
                XLuaUiManager.Open("UiPunishaarChallengeSettlement", settleInfo)
                return
            end
            if not stage then return end
            self._Model:SetCurrentStage(stage)
            local nodeStatus = stage.CurrentNode and stage.CurrentNode.Status
            if nodeStatus == XMVCA.XPunishaar.EnumConst.NodeStatus.Finished then
                self:ExitNode()
            elseif nodeStatus == XMVCA.XPunishaar.EnumConst.NodeStatus.RewardReplace then
                -- 协议兼容保留：服务端 OnFightWin 当前不进 RewardReplace（战斗结算不出卡，只发格子数+血上限，
                -- 详见 FightMain持久基底方案·二期服务端事实核实），此分支不可达。保留作协议兼容：若未来服务端
                -- 改为战斗胜利出卡，走 _AutoHandlePendingReward 正式链路（分支A自动找位 / 分支B手动编排）。
                self:_AutoHandlePendingReward(stage.CurrentNode)
            elseif nodeStatus == XMVCA.XPunishaar.EnumConst.NodeStatus.Remedy then
                -- 失败且该战斗节点配了补强商店：进补强商店，买完卡离开回战前准备重战
                self.RunControl:TransitionTo(XMVCA.XPunishaar.EnumConst.FightState.Shopping)
            elseif nodeStatus == XMVCA.XPunishaar.EnumConst.NodeStatus.Processing then
                -- 失败但该战斗节点无补强商店配置：节点留在进行中（战斗节点可反复挑战至胜利），
                -- 直接回战前准备，由玩家再点"开始战斗"重新迎战（连战）
                self.RunControl:TransitionTo(XMVCA.XPunishaar.EnumConst.FightState.PreFight)
            else
                XLog.Warning("[Punishaar] FinishFight: 未预期的 nodeStatus=" .. tostring(nodeStatus)
                    .. "，isWin=" .. tostring(isWin))
            end
        end
        -- rewardList Proto 不带（传 nil 占位）；BattleSettlement 奖励显示拉 Model 缓存 GetLastRewardGoodsList（NotifyPunishaarRewardResult 下发，已接 _RefreshRewardList）
        -- 补强判定：失败 + nodeStatus==Remedy（逻辑层有，传 BattleSettlement 显 tips）#69
        local hasRemedy = (not isWin) and stage and stage.CurrentNode
            and stage.CurrentNode.Status == XMVCA.XPunishaar.EnumConst.NodeStatus.Remedy
        -- 耐久扣减量：失败 + delta>0 才显（胜利 delta=0 不显）。
        -- 战后值：stage 在场取 stage.Durability；stage 缺失（与 SettleInfo 互斥）则按 SettleType 推——
        -- DurabilityEnd=耐久归零→0，其余（Finished/Quit）不扣→beforeDur。
        local durabilityDelta = 0
        if not isWin then
            local afterDur = beforeDur
            if stage then
                afterDur = stage.Durability or beforeDur
            elseif settleInfo and settleInfo.SettleType == XMVCA.XPunishaar.EnumConst.SettleType.DurabilityEnd then
                afterDur = 0
            end
            local delta = beforeDur - afterDur
            if delta > 0 then
                durabilityDelta = delta
            end
        end
        XLuaUiManager.Open("UiPunishaarBattleSettlement", isWin, nil, onConfirm, hasRemedy, durabilityDelta)
    end)
end

--- 整局结算统一处理：通关时本地写入 PassedStageIds（修复通关后下一关需重登录才解锁 #通关缓存修复）。
--- 两条结算路径（ExitNode / FinishFight）均调此，避免重复。
---@param settleInfo table Server.XPunishaarSettleInfo（含 SettleType + StageId）
function XPunishaarGameControl:_OnStageSettled(settleInfo)
    if not settleInfo then return end
    local SettleType = XMVCA.XPunishaar.EnumConst.SettleType
    if settleInfo.SettleType == SettleType.Finished then
        -- 通关：本地写入通关记录（服务端已标，客户端镜像；GetData/NotifyLogin 仍兜底同步）
        self._Model:GetOutSideModel():AddPassedStage(settleInfo.StageId)
    end
end

--- 暂存奖励卡升级预判：同 TemplateId 同 Level 持有卡 + 有下一级 → 合并升级（cardDetail.MasterCardId=持有卡 Id，不占新槽）。
--- 对齐商店 BuyGoods 的 BuyUpgradeChain 策略（MasterCardId≠0=升级，=0=放置）。事件领取阶段不开背包 UI，无升级动画。
---@param node table Server.XPunishaarNode（RewardReplace）
---@return boolean true=已走升级路径（HandlePendingReward→ExitNode）；false=非升级（调用方走放置/重开界面）
function XPunishaarGameControl:_TryUpgradePendingReward(node)
    local pendingCardId = node and node.PendingRewardCardId
    if not pendingCardId or pendingCardId == 0 then
        return false
    end
    local pendingLevel = node.PendingRewardCardLevel or 1
    local owned = self:_FindOwnedCardByLevel(pendingCardId, pendingLevel)
    if not owned or not self:HasNextCardLevel(pendingCardId, pendingLevel) then
        return false  -- 非升级（无同级持有 / 到顶共存 / 无下一级）
    end
    XLog.Debug(string.format("[主卡Discard诊断] 升级预判命中: pendingCardId=%s L%s → 合并进 owned.Id=%s", tostring(pendingCardId), tostring(pendingLevel), tostring(owned.Id)))
    self:HandlePendingReward(true, { MasterCardId = owned.Id, SubCardId = 0 }, function(success)
        if not success then
            XLog.Error("[Punishaar] _TryUpgradePendingReward: 升级 HandlePendingReward 失败, pendingCardId=" .. tostring(pendingCardId))
            return
        end
        self:ExitNode()
    end)
    return true
end

--- RewardReplace 状态处理暂存奖励卡：分支A自动找位（正式主路径，玩家无感）；分支B放不下→_EnterManualPlacement。
--- 分支A：复用 _FindPlacementForDirectBuy（优先对战区→背包，不挤压）；有位→HandlePendingReward(true)→ExitNode。
--- 分支B（无位）：_EnterManualPlacement 预留正式入口（打开承载界面让玩家手动编排/放弃，prefab 待补）；当前按放弃推进（二期承载界面就位后替换为正式手动编排）。
---@param node table Server.XPunishaarNode（RewardReplace 状态的当前节点）
function XPunishaarGameControl:_AutoHandlePendingReward(node)
    local pendingCardId = node and node.PendingRewardCardId
    -- 无暂存卡：无需处理，直接推进
    if not pendingCardId or pendingCardId == 0 then
        self:ExitNode()
        return
    end

    -- 升级预判：同 TemplateId 同 Level → 合并升级（不占槽，不开 SellCardTip）
    if self:_TryUpgradePendingReward(node) then
        return
    end

    -- 分支A：为待发放卡自动找位（优先对战区，其次背包，不挤压）
    local cardDetail = self:_FindPlacementForDirectBuy(pendingCardId)
    if not cardDetail then
        -- 分支B：放不下→进手动编排入口（正式：打开承载界面；当前临时：按放弃推进）
        self:_EnterManualPlacement(node, pendingCardId)
        return
    end

    self:HandlePendingReward(true, cardDetail, function(success)
        if not success then
            XLog.Error("[Punishaar] _AutoHandlePendingReward: HandlePendingReward 失败，pendingCardId="
                .. tostring(pendingCardId))
            return
        end
        -- 节点已转 Finished，推进下一节点
        self:ExitNode()
    end)
end

--- 【分支B·正式】暂存卡放不下（双区均满）时的承载界面入口。
--- 切 Base 态→开承载界面 SellCardTip(RewardFull)（EventSettlement 由调用方 _DoExit:302 自关，本入口不重复关）。玩家卖/弃腾位后，MasterCardChange
---   触发 SellCardTip 刷背包 + 调 gc:TryAutoPlacePendingReward（复用 _FindPlacementForDirectBuy，有位即
---   HandlePendingReward(true)→_FinishRewardPlacement 关弹窗+ExitNode）；或点放弃→gc:AbandonPendingReward
---   （HandlePendingReward(false)→_FinishRewardPlacement）。
--- 时序保障：OnNotifyPunishaarMasterCardChange 在 DispatchEvent 前已 UpdateMasterCardByNotify 更新 Model，
---   故重检读到的是腾位后最新值（无 stale）。UI 不拖拽（对齐主/副卡装配 click-only 范式），空槽充足自动入背包。
---@param node table Server.XPunishaarNode
---@param pendingCardId number 暂存卡 Id（node.PendingRewardCardId）
function XPunishaarGameControl:_EnterManualPlacement(node, pendingCardId)
    -- 不在此关 EventSettlement：本入口由 EventSettlement._DoExit:300 _FinishEventThenExit 同步调起，
    -- _DoExit:302 紧接 self:Close() 自关事件界面（先盖 SellCardTip 后关，对齐 _DoExit "先盖后关" 注释）。
    -- 此处再 SafeClose 会与 _DoExit:302 双重关闭报"重复Close"。AutoPassthrough 路径无 EventSettlement 开着，亦无需关。
    -- 切 Base 态作 FightMain 基底（承载界面叠其上）
    self.RunControl:TransitionTo(XMVCA.XPunishaar.EnumConst.FightState.Base)
    -- 置奖励放置流程态（TryAutoPlacePendingReward/AbandonPendingReward 守卫 + _FinishRewardPlacement 清理）
    self._RewardPlacementActive = true
    self._RewardCardId = pendingCardId
    self._RewardHandling = false
    self._RewardDone = false
    local level = (node and node.PendingRewardCardLevel) or 1
    XLuaUiManager.Open("UiPunishaarSellCardTip", { mode = "RewardFull", cardId = pendingCardId, level = level })
end

--- RewardFull 流程：卖/弃腾位后自动找位放置（SellCardTip 订阅 MasterCardChange 后调本入口）。
--- 复用 _FindPlacementForDirectBuy（优先对战区→背包，不挤压）；有位→HandlePendingReward(true)→_FinishRewardPlacement。
function XPunishaarGameControl:TryAutoPlacePendingReward()
    if not self._RewardPlacementActive or self._RewardHandling or self._RewardDone then
        return
    end
    local detail = self:_FindPlacementForDirectBuy(self._RewardCardId)
    XLog.Debug(string.format("[主卡Discard诊断] TryAutoPlace: _RewardCardId=%s detail=%s",
            tostring(self._RewardCardId),
            detail and string.format("{AreaType=%s,StartPos=%s,SubCardId=%s,MasterCardId=%s}",
                    tostring(detail.AreaType), tostring(detail.StartPos), tostring(detail.SubCardId), tostring(detail.MasterCardId)) or "nil"))
    if not detail then
        return  -- 仍无空位，等玩家继续腾位或点放弃
    end
    self._RewardHandling = true
    XLog.Debug(string.format("[主卡Discard诊断] 发 HandlePendingReward(true) AreaType=%s StartPos=%s",
            tostring(detail.AreaType), tostring(detail.StartPos)))
    self:HandlePendingReward(true, detail, function(success)
        self._RewardHandling = false
        local stage = self._Model and self._Model:GetCurrentStage()
        local cards = stage and stage.TotalMasterCards
        local count = 0
        local foundReward = false
        if cards then
            for _, c in pairs(cards) do
                count = count + 1
                if c.TemplateId == self._RewardCardId then
                    foundReward = true
                end
            end
        end
        XLog.Debug(string.format("[主卡Discard诊断] HandlePendingReward 响应 success=%s; 放置后(本地)stage.TotalMasterCards count=%s 含奖励卡(TemplateId=%s)=%s",
                tostring(success), tostring(count), tostring(self._RewardCardId), tostring(foundReward)))
        if success then
            self:_FinishRewardPlacement()
        end
    end)
end

--- RewardFull 流程：放弃暂存卡（SellCardTip 的 BtnSkipReward 调）。
function XPunishaarGameControl:AbandonPendingReward()
    if not self._RewardPlacementActive or self._RewardHandling or self._RewardDone then
        return
    end
    self._RewardHandling = true
    self:HandlePendingReward(false, nil, function(success)
        self._RewardHandling = false
        if success then
            self:_FinishRewardPlacement()
        end
    end)
end

--- RewardFull 流程收尾：置完成态（防 HandlePendingReward 自身触发的 MasterCardChange 重入）+ 关承载界面 + ExitNode 推进。
function XPunishaarGameControl:_FinishRewardPlacement()
    self._RewardDone = true
    self._RewardPlacementActive = false
    XLuaUiManager.Close("UiPunishaarSellCardTip")
    self:ExitNode()
end

--- 是否在主卡保留环节（reward-placement 流程态，_EnterManualPlacement 置 true，_FinishRewardPlacement 清）。
--- 供 MainCardTips 区分主卡详情应显售出（商店/他处）还是丢弃（主卡保留环节腾位路径）#主卡Discard
---@return boolean
function XPunishaarGameControl:IsRewardPlacementActive()
    return self._RewardPlacementActive == true
end

return XPunishaarGameControl
