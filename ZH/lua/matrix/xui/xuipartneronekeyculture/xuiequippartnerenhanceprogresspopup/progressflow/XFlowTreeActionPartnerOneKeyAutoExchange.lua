---@class XFlowTreeActionPartnerOneKeyAutoExchange : XFlowTreeAction 自动兑换行为节点：从 CommitControl 取兑换执行计划，逐条发商店购买协议补足材料
---@field private _Control XPartnerControl
---@field private _OneKeyCultureMainControl XPartnerOneKeyCultureControl
---@field private _PlanList table[] 兑换计划快照 { {ItemId, ShopId, GoodsId, Times, GainCount} }
---@field private _PreCountDic table<number, number> 兑换前各产物实际持有量快照 { [itemId] = count }
---@field private _CurIndex number 当前执行中的计划索引
---@field private _IsStopped boolean 节点是否已退出（BuyShop 走回调而非事件，需要标记拦截晚到回调）
local XFlowTreeActionPartnerOneKeyAutoExchange = XClass(require("XFlowTree/Base/XFlowTreeAction"), "XFlowTreeActionPartnerOneKeyAutoExchange")

---@param context XUiEquipPartnerEnhanceProgressPopup
function XFlowTreeActionPartnerOneKeyAutoExchange:OnEnter(context)
    local control = context._Control
    local mainControl = control:GetOneKeyCultureMainControl()
    self._Control = control
    self._OneKeyCultureMainControl = mainControl
    self._IsStopped = false

    -- 从 CommitControl 取兑换执行计划（CalcCommit 时按 升级升阶 → 升星 → 技能升级 顺序生成）
    local commitControl = mainControl:GetCommitControl()
    local planList = commitControl:GetExchangePlanList()

    -- 无兑换计划，直接完成
    if XTool.IsTableEmpty(planList) then
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
        return
    end

    -- 快照一份，避免执行期间 CommitControl 重算污染
    -- 同时快照兑换前各产物的实际持有量，供兑换完成后的对比校验 log 使用
    self._PlanList = {}
    self._PreCountDic = {}
    for _, plan in ipairs(planList) do
        table.insert(self._PlanList, {
            ItemId = plan.ItemId,
            ShopId = plan.ShopId,
            GoodsId = plan.GoodsId,
            Times = plan.Times,
            GainCount = plan.GainCount,
        })
        if not self._PreCountDic[plan.ItemId] then
            self._PreCountDic[plan.ItemId] = XDataCenter.ItemManager.GetCount(plan.ItemId)
        end
    end

    self._CurIndex = 0
    self:_SendNextBuy()
end

function XFlowTreeActionPartnerOneKeyAutoExchange:OnExit(isInterrupt)
    self._IsStopped = true
end

function XFlowTreeActionPartnerOneKeyAutoExchange:OnDestroy()
    self.Super.OnDestroy(self)
    self._IsStopped = true
    self._PlanList = nil
    self._PreCountDic = nil
    self._OneKeyCultureMainControl = nil
    self._Control = nil
end

--- 逐条发起商店购买，全部成功后节点完成
function XFlowTreeActionPartnerOneKeyAutoExchange:_SendNextBuy()
    self._CurIndex = self._CurIndex + 1
    local plan = self._PlanList[self._CurIndex]

    -- 全部兑换完成
    if not plan then
        self:_OnAllExchangeDoneLog()
        self:OnDone(self.XFlowTreeEnum.Result.Succeed)
        return
    end

    XShopManager.BuyShop(plan.ShopId, plan.GoodsId, plan.Times, function()
        self:_OnBuyFinish()
    end, function(errorCode)
        self:_OnBuyFail(errorCode)
    end)
end

function XFlowTreeActionPartnerOneKeyAutoExchange:_OnBuyFinish()
    if self._IsStopped then
        return
    end
    self:_SendNextBuy()
end

function XFlowTreeActionPartnerOneKeyAutoExchange:_OnBuyFail(errorCode)
    if self._IsStopped then
        return
    end
    self:_OnFailLog(errorCode)
    self:OnDone(self.XFlowTreeEnum.Result.Fail)
end

function XFlowTreeActionPartnerOneKeyAutoExchange:_OnFailLog(errorCode)
    local sb = {}
    table.insert(sb, string.format("[AutoExchange] 失败! planIndex=%d/%d errorCode=%s", self._CurIndex or 0, self._PlanList and #self._PlanList or 0, tostring(errorCode)))
    local plan = self._PlanList and self._PlanList[self._CurIndex]
    if plan then
        table.insert(sb, string.format("  itemId=%d shopId=%d goodsId=%d times=%d gain=%d", plan.ItemId, plan.ShopId, plan.GoodsId, plan.Times, plan.GainCount))
    end
    XLog.Error(table.concat(sb, "\n"))
end

--- 全部兑换完成后打印对比校验 log：计划兑换量 vs 实际持有量变化
function XFlowTreeActionPartnerOneKeyAutoExchange:_OnAllExchangeDoneLog()
    local sb = {}
    table.insert(sb, string.format("[AutoExchange] 全部兑换完成, plan count=%d", self._PlanList and #self._PlanList or 0))

    -- 按产物 Id 汇总计划兑换量
    local planGainDic = {}
    for _, plan in ipairs(self._PlanList or {}) do
        planGainDic[plan.ItemId] = (planGainDic[plan.ItemId] or 0) + plan.GainCount
    end

    for itemId, planGain in pairs(planGainDic) do
        local preCount = self._PreCountDic and self._PreCountDic[itemId] or 0
        local curCount = XDataCenter.ItemManager.GetCount(itemId)
        local realGain = curCount - preCount
        table.insert(sb, string.format("  itemId=%d 计划兑换=%d 实际增加=%d (兑换前=%d 兑换后=%d)%s",
            itemId, planGain, realGain, preCount, curCount, realGain == planGain and "" or " [不一致!]"))
    end

    XLog.Warning(table.concat(sb, "\n"))
end

return XFlowTreeActionPartnerOneKeyAutoExchange
