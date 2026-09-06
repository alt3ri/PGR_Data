-- 装备超频Awake子Control：意识超频相关接口
---@class XEquipAwakeCostItem
---@field Id number 道具 Id
---@field Count number 道具数量

---@class XEquipAwakeAutoExchangeInfo
---@field ItemId number 自动兑换补足的目标道具 Id
---@field ShopId number 兑换商店 Id
---@field GoodsId number 兑换商品 Id
---@field LackCount number 目标道具缺口数量
---@field ExchangeTimes number 补足缺口所需的计划兑换次数
---@field RewardCount number 按计划兑换次数可获得的目标道具数量
---@field AvailableExchangeTimes number 当前兑换材料可支持的兑换次数
---@field AvailableRewardCount number 当前兑换材料可支持获得的目标道具数量
---@field ConsumeList XEquipAwakeCostItem[] 按计划兑换次数需要消耗的道具列表

---@class XEquipAwakePreviewResult
---@field PreviewAwakeCount number 当前预览结果纳入消耗计算的超频槽位数；全量预览为全部可超频槽位，可用预览为当前资源内实际可执行槽位
---@field AvailableAwakeInfoList XEquipAwakePreviewSlotInfo[] 可用预览中本轮实际可执行的超频槽位列表；全量预览不依赖此字段
---@field CostMoney number 超频消耗螺母数量
---@field CostItemDic table<number, number> 超频材料 Id -> 需求数量
---@field CostItemList XEquipAwakeCostItem[] 按道具 Id 升序整理后的超频材料列表
---@field PreviewEquipAwakeCountDic table<number, number> 装备 Id -> 当前预览结果纳入消耗计算的槽位数量
---@field IsMoneyEnough boolean 螺母是否足够
---@field IsCostItemEnough boolean 超频材料是否足够
---@field IsEnough boolean 不计算自动兑换时资源是否足够
---@field IsEnoughWithAutoExchange boolean 纳入自动兑换预览后资源是否足够
---@field AutoExchangeInfo table<number, XEquipAwakeAutoExchangeInfo> 自动兑换信息，key 为补足目标道具 Id
---@field IsAutoExchangeConsumeEnough boolean 自动兑换消耗是否足够
---@field IsAutoExchangeNeeded boolean 是否需要执行自动兑换

---@class XEquipFullAwakePreviewOptions
---@field IsAutoExchangeEnabled boolean|nil 是否计算自动兑换补足

---@class XEquipAwakePreviewSlotInfo
---@field EquipId number 意识装备 Id
---@field Slots number[] 超频槽位列表

---@class XEquipAvailableAwakePreviewOptions
---@field IsAutoExchangeEnabled boolean|nil 是否计算自动兑换补足
---@field TargetAwakeInfoList XEquipAwakePreviewSlotInfo[]|nil 可用预览目标超频槽位列表
---@field PreviewRemainItemCountDic table<number, number>|nil 预览链路当前剩余资源数量，包含 Coin

---@class XEquipAwakePreviewResourceState
---@field PreviewRemainItemCountDic table<number, number>|nil 预览链路当前剩余资源数量，包含 Coin
---@field RemainItemCountDic table<number, number> 本轮超频预览变化后的剩余资源数量
---@field IsAutoExchangeEnabled boolean 是否允许自动兑换补足资源
---@field AutoExchangeInfo table<number, XEquipAwakeAutoExchangeInfo> 本轮预览预占的自动兑换信息

---@class XEquipAwarenessAwakeTaskInfo
---@field PreviewResult XEquipAwakePreviewResult 预览结果
---@field TaskList XEquipAwarenessAwakeTask[] 任务列表
---@field Index number 当前执行索引

---@class XEquipAwarenessAwakeTask
---@field Type number 任务类型
---@field Id number 任务 Id
---@field ExchangeTimes number|nil 本次自动兑换次数，仅自动兑换任务使用
---@field State number 任务状态

---@class XEquipAwakeControl: XControl
---@field private _Model XEquipModel
---@field private _MainControl XEquipControl
---@field private _AwarenessAwakeTaskInfo XEquipAwarenessAwakeTaskInfo|nil
---@field private _AwarenessAwakeCallback fun(isSuccess:boolean, errorCode:any)|nil
local XEquipAwakeControl = XClass(XControl, 'XEquipAwakeControl')

---@param countDic table<number, number> 道具数量字典
---@param itemId number|nil 道具 Id
---@param count number|nil 增量数量
local function AddItemCount(countDic, itemId, count)
    if not itemId or not count or count <= 0 then
        return
    end

    countDic[itemId] = (countDic[itemId] or 0) + count
end

---@param itemCountDic table<number, number> 道具 Id -> 数量
---@return XEquipAwakeCostItem[] costItemList 按道具 Id 升序整理后的消耗列表
local function BuildCostItemList(itemCountDic)
    local costItemList = {}
    for itemId, count in pairs(itemCountDic) do
        table.insert(costItemList, { Id = itemId, Count = count })
    end

    table.sort(costItemList, function(a, b) return a.Id < b.Id end)

    return costItemList
end

---@return XEquipAwakePreviewResult result 空的超频预览结果
local function BuildEmptyAwakePreview()
    return {
        PreviewAwakeCount = 0,
        AvailableAwakeInfoList = {},
        CostMoney = 0,
        CostItemDic = {},
        CostItemList = {},
        PreviewEquipAwakeCountDic = {},
        IsMoneyEnough = true,
        IsCostItemEnough = true,
        IsEnough = true,
        IsEnoughWithAutoExchange = true,
        AutoExchangeInfo = {},
        IsAutoExchangeConsumeEnough = true,
        IsAutoExchangeNeeded = false,
    }
end

-- 意识超频执行任务定义。
-- 意识超频执行任务类型，数值顺序即执行阶段顺序：先自动兑换，再批量超频。
local AwarenessAwakeTaskType = {
    -- 通过商店自动兑换补足预览所需资源。
    Exchange = 1,
    -- 对预览中实际可执行的槽位发起批量超频。
    QuickAwake = 2,
}

-- 意识超频任务状态，用于标记当前串行链路内每个 task 的执行进度。
local AwarenessAwakeTaskState = {
    -- 已构建但尚未开始。
    NotStarted = 0,
    -- 请求已发出，等待回调。
    Running = 1,
    -- 当前任务成功完成。
    Success = 2,
    -- 当前任务失败，链路中止。
    Failed = 3,
}

local MaxShopExchangeTimesPerRequest = CS.XGame.Config:GetInt("ShopBuyGoodsCountLimit")

----------------------------------------
-- 生命周期
----------------------------------------
-- 初始化装备超频Awake Control。
function XEquipAwakeControl:OnInit()
    self._AwarenessAwakeTaskInfo = nil
    self._AwarenessAwakeCallback = nil
end

-- 注册装备超频Awake相关事件。
function XEquipAwakeControl:AddAgencyEvent()
end

-- 移除装备超频Awake相关事件。
function XEquipAwakeControl:RemoveAgencyEvent()
end

-- 释放装备超频Awake Control。
function XEquipAwakeControl:OnRelease()
    self:CancelAwarenessAwake()
end

----------------------------------------
-- 意识超频执行
----------------------------------------

--- 根据预览结果启动意识超频串行链路。
--- 链路顺序：自动兑换任务逐个成功后，再对可执行槽位发起一次批量超频。
---@param previewResult XEquipAwakePreviewResult
---@param cb fun(isSuccess:boolean, errorCode:any)|nil
---@return boolean started
function XEquipAwakeControl:StartAwarenessAwake(previewResult, cb)
    self:CancelAwarenessAwake()

    local isValid, errorCode = self:_CheckAwarenessAwakePreview(previewResult)
    if not isValid then
        if cb then
            cb(false, errorCode)
        end
        return false
    end

    self._AwarenessAwakeCallback = cb
    self._AwarenessAwakeTaskInfo = {
        PreviewResult = previewResult,
        TaskList = self:_BuildAwarenessAwakeTaskList(previewResult),
        Index = 1,
    }

    self:_ExecuteNextAwarenessAwakeTask(self._AwarenessAwakeTaskInfo)
    return true
end

--- 打断当前意识超频链路；已发出的请求无法取消，但后续回调会因 taskInfo 失效而被忽略。
function XEquipAwakeControl:CancelAwarenessAwake()
    self._AwarenessAwakeTaskInfo = nil
    self._AwarenessAwakeCallback = nil
end

--- 当前是否正在执行意识超频链路。
---@return boolean
function XEquipAwakeControl:IsAwarenessAwakeRunning()
    return self._AwarenessAwakeTaskInfo ~= nil
end

--- 检查预览结果是否满足发起串行超频的基础条件。
---@param previewResult XEquipAwakePreviewResult|nil
---@return boolean
---@return string|nil
function XEquipAwakeControl:_CheckAwarenessAwakePreview(previewResult)
    if not previewResult or previewResult.PreviewAwakeCount <= 0 then
        return false, "InvalidPreview"
    end
    if XTool.IsTableEmpty(previewResult.AvailableAwakeInfoList) then
        return false, "AwakeMaterialNotEnough"
    end
    if previewResult.IsAutoExchangeNeeded then
        if XTool.IsTableEmpty(previewResult.AutoExchangeInfo) then
            return false, "InvalidAutoExchangeInfo"
        end
        if previewResult.IsAutoExchangeConsumeEnough == false then
            return false, "AutoExchangeConsumeNotEnough"
        end
        if previewResult.IsEnoughWithAutoExchange == false then
            return false, "AwakeMaterialNotEnough"
        end
        return true
    end
    if previewResult.IsEnoughWithAutoExchange == false then
        return false, "AwakeMaterialNotEnough"
    end
    return true
end

--- 根据预览结果构建串行任务列表：先按道具 Id 自动兑换，再发起一次批量超频。
---@param previewResult XEquipAwakePreviewResult
---@return XEquipAwarenessAwakeTask[] taskList
function XEquipAwakeControl:_BuildAwarenessAwakeTaskList(previewResult)
    local taskList = {}
    for itemId, exchangeInfo in pairs(previewResult.AutoExchangeInfo or {}) do
        local exchangeTimes = exchangeInfo.ExchangeTimes or 0
        while exchangeTimes > 0 do
            local taskExchangeTimes = math.min(exchangeTimes, MaxShopExchangeTimesPerRequest)
            table.insert(taskList, {
                Type = AwarenessAwakeTaskType.Exchange,
                Id = itemId,
                ExchangeTimes = taskExchangeTimes,
                State = AwarenessAwakeTaskState.NotStarted,
            })
            exchangeTimes = exchangeTimes - taskExchangeTimes
        end
    end

    table.insert(taskList, {
        Type = AwarenessAwakeTaskType.QuickAwake,
        Id = AwarenessAwakeTaskType.QuickAwake,
        State = AwarenessAwakeTaskState.NotStarted,
    })

    table.sort(taskList, function(taskA, taskB)
        if taskA.Type ~= taskB.Type then
            return taskA.Type < taskB.Type
        end
        return (tonumber(taskA.Id) or 0) < (tonumber(taskB.Id) or 0)
    end)
    return taskList
end

--- 启动下一个意识超频任务；所有任务完成后结束整条链路。
---@param taskInfo XEquipAwarenessAwakeTaskInfo
function XEquipAwakeControl:_ExecuteNextAwarenessAwakeTask(taskInfo)
    if not self:_IsAwarenessAwakeTaskValid(taskInfo) then
        return
    end

    local task = taskInfo.TaskList[taskInfo.Index]
    if not task then
        self:_FinishAwarenessAwake(taskInfo, true)
        return
    end

    task.State = AwarenessAwakeTaskState.Running
    local onTaskFinish = function()
        self:_CompleteCurrentAwarenessAwakeTask(taskInfo, task)
    end
    local onTaskFail = function(code)
        self:_FinishAwarenessAwake(taskInfo, false, code)
    end

    if task.Type == AwarenessAwakeTaskType.Exchange then
        local exchangeInfo = taskInfo.PreviewResult.AutoExchangeInfo[task.Id]
        XShopManager.BuyShop(exchangeInfo.ShopId, exchangeInfo.GoodsId, task.ExchangeTimes, onTaskFinish, onTaskFail)
    elseif task.Type == AwarenessAwakeTaskType.QuickAwake then
        self:_RequestAwarenessQuickAwake(taskInfo.PreviewResult.AvailableAwakeInfoList, onTaskFinish, onTaskFail)
    else
        self:_FinishAwarenessAwake(taskInfo, false, "InvalidTaskType")
    end
end

--- 进度链需要失败回调，因此这里直接包装批量超频协议并复用普通快速超频的数据刷新逻辑。
---@param awakeInfos XEquipAwakePreviewSlotInfo[]
---@param cb function|nil
---@param failCb fun(errorCode:any)|nil
function XEquipAwakeControl:_RequestAwarenessQuickAwake(awakeInfos, cb, failCb)
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.EquipAwake) then
        if failCb then
            failCb("EquipAwakeFunctionLocked")
        end
        return
    end

    local req = { EquipQuickAwakeInfos = awakeInfos }
    XNetwork.Call("EquipQuickAwakeRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if failCb then
                failCb(res.Code)
            end
            return
        end

        local charIdDic = {}
        for _, awakeInfo in ipairs(awakeInfos) do
            local equip = self._MainControl:GetEquip(awakeInfo.EquipId)
            for _, slot in ipairs(awakeInfo.Slots) do
                equip:SetAwake(slot)
            end
            if equip:IsWearing() then
                charIdDic[equip.CharacterId] = true
            end
        end

        XMVCA.XCharacter:OnSyncCharacterEquipChange(charIdDic)
        XMVCA.XEquip:TipEquipOperation(nil, XUiHelper.GetText("EquipMultiStrengthenSuc"))
        if cb then
            cb()
        end
    end, nil, nil, function()
        if failCb then
            failCb("ProtocolShielded")
        end
    end)
end

--- 标记当前任务完成并推进到下一个任务。
---@param taskInfo XEquipAwarenessAwakeTaskInfo
---@param task XEquipAwarenessAwakeTask
function XEquipAwakeControl:_CompleteCurrentAwarenessAwakeTask(taskInfo, task)
    if not self:_IsAwarenessAwakeTaskValid(taskInfo) then
        return
    end
    task.State = AwarenessAwakeTaskState.Success
    taskInfo.Index = taskInfo.Index + 1
    self:_ExecuteNextAwarenessAwakeTask(taskInfo)
end

--- 结束整条意识超频链路，清理运行态并回调结果。
---@param taskInfo XEquipAwarenessAwakeTaskInfo
---@param isSuccess boolean
---@param errorCode any
function XEquipAwakeControl:_FinishAwarenessAwake(taskInfo, isSuccess, errorCode)
    if not self:_IsAwarenessAwakeTaskValid(taskInfo) then
        return
    end
    local cb = self._AwarenessAwakeCallback
    local task = taskInfo.TaskList[taskInfo.Index]
    if task then
        task.State = isSuccess and AwarenessAwakeTaskState.Success or AwarenessAwakeTaskState.Failed
    end
    self._AwarenessAwakeTaskInfo = nil
    self._AwarenessAwakeCallback = nil
    if cb then
        cb(isSuccess, errorCode)
    end
end

--- 校验异步回调持有的 taskInfo 是否仍是当前运行中的链路。
---@param taskInfo XEquipAwarenessAwakeTaskInfo|nil
---@return boolean
function XEquipAwakeControl:_IsAwarenessAwakeTaskValid(taskInfo)
    return taskInfo and self._AwarenessAwakeTaskInfo == taskInfo
end

----------------------------------------
-- 意识超频预览
----------------------------------------
-- 可用超频预览：按目标槽位顺序逐槽扣减资源
-- 自动兑换开启时预占兑换消耗并补足目标资源；遇到第一个不可执行槽位时停止
---@param options XEquipAvailableAwakePreviewOptions 可用超频预览选项
---@return XEquipAwakePreviewResult result 超频资源预览结果
function XEquipAwakeControl:CalcAvailableAwakePreviewCost(options)
    local targetAwakeInfoList = options and options.TargetAwakeInfoList
    if XTool.IsTableEmpty(targetAwakeInfoList) then
        return BuildEmptyAwakePreview()
    end

    local isAutoExchangeEnabled = options and options.IsAutoExchangeEnabled == true
    local previewRemainItemCountDic = options and options.PreviewRemainItemCountDic

    return self:_BuildAvailableAwakePreviewResult(targetAwakeInfoList, previewRemainItemCountDic, isAutoExchangeEnabled)
end

-- 全量超频预览：忽略资源是否足够，统计当前装备状态下所有可超频到上限的槽位消耗
---@param equipIds table<number, number> 意识站位 -> 装备Id，未穿戴的站位不存在 key
---@param options XEquipFullAwakePreviewOptions|nil 全量超频预览选项
---@return XEquipAwakePreviewResult result 全量超频到上限的资源预览结果
function XEquipAwakeControl:CalcFullAwakePreviewCost(equipIds, options)
    local result = BuildEmptyAwakePreview()
    local isAutoExchangeEnabled = options and options.IsAutoExchangeEnabled == true

    if XTool.IsTableEmpty(equipIds) then
        return result
    end

    -- 普通超频入口只按当前装备状态计算到上限；可用预览目标槽位走 CalcAvailableAwakePreviewCost
    for _, equipId in pairs(equipIds) do
        local equip = self._MainControl:GetEquip(equipId)
        if equip and equip:IsAwareness() and self._Model:CheckEquipStarCanAwake(equipId) then
            local awakeCount = math.max(0, XEnumConst.EQUIP.MAX_AWAKE_COUNT - self._Model:GetEquipAwakeNum(equipId))

            if awakeCount > 0 then
                result.PreviewAwakeCount = result.PreviewAwakeCount + awakeCount
                result.PreviewEquipAwakeCountDic[equipId] = awakeCount
                result.CostMoney = result.CostMoney + self._Model:GetAwakeConsumeCrystalCoin(equipId, awakeCount)

                local costItemList = self._Model:GetAwakeConsumeItemCrystalList(equipId, awakeCount) or {}
                for _, item in ipairs(costItemList) do
                    AddItemCount(result.CostItemDic, item.ItemId, item.Count)
                end
            end
        end
    end

    self:_ApplyFullAwakePreviewResourceState(result, isAutoExchangeEnabled)

    return result
end

-- 构建可用超频预览结果：按目标槽位顺序逐槽扣减资源，遇到第一个不可执行槽位时停止
---@param targetAwakeInfoList XEquipAwakePreviewSlotInfo[] 可用预览目标超频槽位列表
---@param previewRemainItemCountDic table<number, number>|nil 预览链路当前剩余资源数量，包含 Coin
---@param isAutoExchangeEnabled boolean 是否允许自动兑换补足资源
---@return XEquipAwakePreviewResult result 超频资源预览结果
function XEquipAwakeControl:_BuildAvailableAwakePreviewResult(targetAwakeInfoList, previewRemainItemCountDic, isAutoExchangeEnabled)
    local result = BuildEmptyAwakePreview()

    -- 本轮可用预览的资源状态，会在逐槽预占和自动兑换补足过程中持续扣减
    ---@type XEquipAwakePreviewResourceState
    local resourceState = {
        PreviewRemainItemCountDic = previewRemainItemCountDic,
        RemainItemCountDic = {},
        IsAutoExchangeEnabled = isAutoExchangeEnabled == true,
        AutoExchangeInfo = {},
    }

    for _, targetAwakeInfo in ipairs(targetAwakeInfoList) do
        local awakeInfo
        local equipId = targetAwakeInfo.EquipId
        for _, pos in ipairs(targetAwakeInfo.Slots) do
            local isEnough, coinCost, itemCostList = self:_TryUseSingleAwakeCost(resourceState, equipId)
            if not isEnough then
                self:_ApplyAvailableAwakePreviewResourceState(result, resourceState)
                return result
            end

            if not awakeInfo then
                awakeInfo = { EquipId = equipId, Slots = {} }
                table.insert(result.AvailableAwakeInfoList, awakeInfo)
            end

            table.insert(awakeInfo.Slots, pos)
            result.PreviewAwakeCount = result.PreviewAwakeCount + 1
            result.PreviewEquipAwakeCountDic[equipId] = (result.PreviewEquipAwakeCountDic[equipId] or 0) + 1
            result.CostMoney = result.CostMoney + coinCost

            for _, item in ipairs(itemCostList) do
                AddItemCount(result.CostItemDic, item.ItemId, item.Count)
            end
        end
    end

    self:_ApplyAvailableAwakePreviewResourceState(result, resourceState)

    return result
end

----------------------------------------
-- 超频资源状态与自动兑换
----------------------------------------
-- 应用全量预览资源状态，并按需计算自动兑换信息
---@param result XEquipAwakePreviewResult 超频资源预览结果
---@param isAutoExchangeEnabled boolean 是否计算自动兑换补足
function XEquipAwakeControl:_ApplyFullAwakePreviewResourceState(result, isAutoExchangeEnabled)
    local coinId = XDataCenter.ItemManager.ItemId.Coin
    local coinBagCount = XDataCenter.ItemManager.GetCount(coinId)
    local lackCounts = isAutoExchangeEnabled and {}

    -- 全量预览只读取背包当前数量，不接入一键养成链路的预留资源
    result.CostItemList = BuildCostItemList(result.CostItemDic)
    result.IsMoneyEnough = coinBagCount >= result.CostMoney
    result.IsCostItemEnough = true
    for itemId, count in pairs(result.CostItemDic) do
        local bagCount = XDataCenter.ItemManager.GetCount(itemId)
        if bagCount < count then
            result.IsCostItemEnough = false
            if not isAutoExchangeEnabled then
                break
            end
        end

        if isAutoExchangeEnabled then
            AddItemCount(lackCounts, itemId, count - bagCount)
        end
    end
    result.IsEnough = result.IsMoneyEnough and result.IsCostItemEnough
    result.IsEnoughWithAutoExchange = result.IsEnough

    if not isAutoExchangeEnabled then
        return
    end

    -- 自动兑换缺口按总需求减背包数量计算
    AddItemCount(lackCounts, coinId, result.CostMoney - coinBagCount)
    local isAllLackCanExchange
    result.AutoExchangeInfo, result.IsAutoExchangeConsumeEnough, isAllLackCanExchange = self:_BuildAwakeAutoExchangeInfo(lackCounts)
    result.IsAutoExchangeNeeded = next(result.AutoExchangeInfo) ~= nil
    result.IsEnoughWithAutoExchange = result.IsEnough or (isAllLackCanExchange and result.IsAutoExchangeConsumeEnough)
end

-- 应用可用预览逐槽扣减后的资源状态
---@param result XEquipAwakePreviewResult 超频资源预览结果
---@param resourceState XEquipAwakePreviewResourceState 超频预览资源状态
function XEquipAwakeControl:_ApplyAvailableAwakePreviewResourceState(result, resourceState)
    local previewRemainItemCountDic = resourceState.PreviewRemainItemCountDic
    local coinId = XDataCenter.ItemManager.ItemId.Coin

    -- 可用预览使用预览链路剩余资源，未记录的道具回退到背包数量
    result.CostItemList = BuildCostItemList(result.CostItemDic)
    result.IsMoneyEnough = self:_GetPreviewRemainItemCount(coinId, previewRemainItemCountDic) >= result.CostMoney
    result.IsCostItemEnough = true
    for itemId, count in pairs(result.CostItemDic) do
        local remainCount = self:_GetPreviewRemainItemCount(itemId, previewRemainItemCountDic)
        if remainCount < count then
            result.IsCostItemEnough = false
            break
        end
    end
    result.IsEnough = result.IsMoneyEnough and result.IsCostItemEnough

    -- 逐槽试扣已完成本轮自动兑换预占，这里只汇总结果状态
    result.AutoExchangeInfo = resourceState.AutoExchangeInfo
    result.IsAutoExchangeNeeded = next(result.AutoExchangeInfo) ~= nil
    result.IsAutoExchangeConsumeEnough = true
    result.IsEnoughWithAutoExchange = result.IsEnough or result.IsAutoExchangeNeeded

    if not result.IsAutoExchangeNeeded then
        return
    end

    local requiredCounts = XTool.Clone(result.CostItemDic)
    AddItemCount(requiredCounts, coinId, result.CostMoney)

    -- 回填展示用缺口，缺口基于本轮总需求和预览链路剩余资源计算
    for itemId, exchangeInfo in pairs(result.AutoExchangeInfo) do
        local lackCount = (requiredCounts[itemId] or 0) - self:_GetPreviewRemainItemCount(itemId, previewRemainItemCountDic)
        exchangeInfo.LackCount = math.max(0, lackCount)
    end
end

-- 构建超频自动兑换信息
---@param lackCounts table<number, number> 需要自动兑换补足的资源缺口数量，仅包含螺母和两类超频材料
---@return table<number, XEquipAwakeAutoExchangeInfo> autoExchangeInfo 自动兑换信息，key 为补足目标道具 Id
---@return boolean isExchangeConsumeEnough 自动兑换消耗是否足够
---@return boolean isAllLackCanExchange 所有资源缺口是否都有自动兑换路线
function XEquipAwakeControl:_BuildAwakeAutoExchangeInfo(lackCounts)
    local autoExchangeInfo = {}
    local reservedExchangeConsumeCounts = {}
    local isAllLackCanExchange = true
    local isExchangeConsumeEnough = true
    -- 自动兑换目标仅包含螺母和两类超频材料，遍历顺序决定共享兑换材料的预占优先级。
    local priorityItemIds = {
        XDataCenter.ItemManager.ItemId.Coin,
        XDataCenter.ItemManager.ItemId.EquipAwakeCoin1,
        XDataCenter.ItemManager.ItemId.EquipAwakeCoin2,
    }
    local supportedItemIdDic = {}
    for _, itemId in ipairs(priorityItemIds) do
        supportedItemIdDic[itemId] = true
    end
    for itemId in pairs(lackCounts) do
        assert(supportedItemIdDic[itemId], string.format(
            "XEquipAwakeControl._BuildAwakeAutoExchangeInfo error: 不支持的超频自动兑换目标, itemId=%s",
            tostring(itemId)))
    end

    -- 只按目标资源单层兑换，不递归补齐兑换所需消耗
    for _, itemId in ipairs(priorityItemIds) do
        local lackCount = lackCounts[itemId]
        if lackCount and lackCount > 0 then
            local exchangeInfo = XDataCenter.ItemManager.GetItemAutoExchangeInfo(itemId)
            local rewardCount = exchangeInfo and exchangeInfo.RewardCountList and exchangeInfo.RewardCountList[1]
            if rewardCount and rewardCount > 0 then
                local exchangeTimes = math.ceil(lackCount / rewardCount)
                local availableExchangeTimes = exchangeTimes
                local consumeList = {}
                local consumeConfigList = exchangeInfo.ConsumeList and exchangeInfo.ConsumeList[1] or {}
                for _, consume in ipairs(consumeConfigList) do
                    local singleConsumeCount = consume.ConsumeCount or 0
                    local costCount = singleConsumeCount * exchangeTimes
                    if costCount > 0 then
                        table.insert(consumeList, { Id = consume.ConsumeId, Count = costCount })

                        local reservedCount = reservedExchangeConsumeCounts[consume.ConsumeId] or 0
                        local consumeOwnCount = XDataCenter.ItemManager.GetCount(consume.ConsumeId) or 0
                        local remainingConsumeCount = math.max(0, consumeOwnCount - reservedCount)
                        local exchangeTimesByConsume = math.floor(remainingConsumeCount / singleConsumeCount)
                        availableExchangeTimes = math.min(availableExchangeTimes, exchangeTimesByConsume)
                    end
                end
                table.sort(consumeList, function(a, b) return a.Id < b.Id end)

                -- 只预占当前可兑换次数对应的消耗，供后续目标计算剩余预算。
                for _, consume in ipairs(consumeConfigList) do
                    local reservedConsumeCount = (consume.ConsumeCount or 0) * availableExchangeTimes
                    AddItemCount(reservedExchangeConsumeCounts, consume.ConsumeId, reservedConsumeCount)
                end
                if availableExchangeTimes < exchangeTimes then
                    isExchangeConsumeEnough = false
                end

                autoExchangeInfo[itemId] = {
                    ItemId = itemId,
                    ShopId = exchangeInfo.ShopIdList[1],
                    GoodsId = exchangeInfo.GoodsIdList[1],
                    LackCount = lackCount,
                    ExchangeTimes = exchangeTimes,
                    RewardCount = rewardCount * exchangeTimes,
                    AvailableExchangeTimes = availableExchangeTimes,
                    AvailableRewardCount = rewardCount * availableExchangeTimes,
                    ConsumeList = consumeList,
                }
            else
                isAllLackCanExchange = false
            end
        end
    end

    return autoExchangeInfo, isExchangeConsumeEnough, isAllLackCanExchange
end

-- 获取预览链路当前剩余资源数量；未在预览中记录的道具回退到背包数量
---@param itemId number 道具 Id
---@param previewRemainItemCountDic table<number, number>|nil 预览链路当前剩余资源数量，包含 Coin
---@return number count 可用于本模块的资源数量
function XEquipAwakeControl:_GetPreviewRemainItemCount(itemId, previewRemainItemCountDic)
    if previewRemainItemCountDic and previewRemainItemCountDic[itemId] ~= nil then
        return previewRemainItemCountDic[itemId]
    end

    return XDataCenter.ItemManager.GetCount(itemId)
end

-- 获取当前超频预览中的资源数量；本轮未变化的道具回退到预览链路剩余数量
---@param resourceState XEquipAwakePreviewResourceState 超频预览资源状态
---@param itemId number 道具 Id
---@return number count 当前剩余数量
function XEquipAwakeControl:_GetCurrentAwakeItemCount(resourceState, itemId)
    local remainCount = resourceState.RemainItemCountDic[itemId]
    if remainCount ~= nil then
        return remainCount
    end

    return self:_GetPreviewRemainItemCount(itemId, resourceState.PreviewRemainItemCountDic)
end

-- 尝试使用超频预览资源中的指定道具，不足时按自动兑换配置补足
---@param resourceState XEquipAwakePreviewResourceState 超频预览资源状态
---@param itemId number 道具 Id
---@param count number 扣除数量
---@return boolean isEnough 是否扣除成功
function XEquipAwakeControl:_TryUseAwakeItem(resourceState, itemId, count)
    if count <= 0 then
        return true
    end

    local itemCount = self:_GetCurrentAwakeItemCount(resourceState, itemId)
    local lackCount = count - itemCount
    if lackCount > 0 then
        if not resourceState.IsAutoExchangeEnabled then
            return false
        end

        if not self:_TryAutoExchangeAwakeItem(resourceState, itemId, lackCount) then
            return false
        end

        itemCount = self:_GetCurrentAwakeItemCount(resourceState, itemId)
    end

    resourceState.RemainItemCountDic[itemId] = itemCount - count
    return true
end

-- 尝试自动兑换补足超频预览中的指定道具，调用方保证已开启自动兑换且缺口大于 0
---@param resourceState XEquipAwakePreviewResourceState 超频预览资源状态
---@param itemId number 道具 Id
---@param lackCount number 需要补足的数量
---@return boolean isEnough 是否补足成功
function XEquipAwakeControl:_TryAutoExchangeAwakeItem(resourceState, itemId, lackCount)
    -- 自动兑换只做单层补足：缺 itemId 时，只使用该道具自身的自动兑换配置
    local exchangeInfo = XDataCenter.ItemManager.GetItemAutoExchangeInfo(itemId)
    if not exchangeInfo then
        return false
    end

    local singleExchangeRewardCount = exchangeInfo.RewardCountList[1]
    local exchangeTimes = math.ceil(lackCount / singleExchangeRewardCount)
    local exchangeConsumeList = {}

    -- 先校验并整理兑换消耗，不立即写资源状态，避免中途失败时污染预览资源
    for _, consumeConfig in ipairs(exchangeInfo.ConsumeList[1]) do
        local costCount = consumeConfig.ConsumeCount * exchangeTimes
        if costCount > 0 then
            local consumeCount = self:_GetCurrentAwakeItemCount(resourceState, consumeConfig.ConsumeId)
            if consumeCount < costCount then
                return false
            end

            table.insert(exchangeConsumeList, { Id = consumeConfig.ConsumeId, Count = costCount })
        end
    end

    -- 所有兑换消耗都足够后，再统一扣除消耗并补入目标资源
    for _, consume in ipairs(exchangeConsumeList) do
        local consumeCount = self:_GetCurrentAwakeItemCount(resourceState, consume.Id)
        resourceState.RemainItemCountDic[consume.Id] = consumeCount - consume.Count
    end

    local totalRewardCount = singleExchangeRewardCount * exchangeTimes
    local itemCount = self:_GetCurrentAwakeItemCount(resourceState, itemId)
    resourceState.RemainItemCountDic[itemId] = itemCount + totalRewardCount
    self:_AddAwakeAutoExchangeInfo(resourceState, itemId, exchangeInfo, exchangeTimes, totalRewardCount, exchangeConsumeList)

    return true
end

-- 累加本轮预览预占的自动兑换信息
---@param resourceState XEquipAwakePreviewResourceState 超频预览资源状态
---@param itemId number 自动兑换补足的目标道具 Id
---@param exchangeConfig table 自动兑换配置
---@param exchangeTimes number 本次兑换次数
---@param rewardCount number 本次兑换获得数量
---@param consumeList XEquipAwakeCostItem[] 本次兑换消耗列表
function XEquipAwakeControl:_AddAwakeAutoExchangeInfo(resourceState, itemId, exchangeConfig, exchangeTimes, rewardCount, consumeList)
    local autoExchangeInfo = resourceState.AutoExchangeInfo[itemId]
    if not autoExchangeInfo then
        autoExchangeInfo = {
            ItemId = itemId,
            ShopId = exchangeConfig.ShopIdList[1],
            GoodsId = exchangeConfig.GoodsIdList[1],
            LackCount = 0,
            ExchangeTimes = 0,
            RewardCount = 0,
            AvailableExchangeTimes = 0,
            AvailableRewardCount = 0,
            ConsumeList = {},
        }
        resourceState.AutoExchangeInfo[itemId] = autoExchangeInfo
    end

    local consumeCountDic = {}
    for _, consume in ipairs(autoExchangeInfo.ConsumeList) do
        AddItemCount(consumeCountDic, consume.Id, consume.Count)
    end
    for _, consume in ipairs(consumeList) do
        AddItemCount(consumeCountDic, consume.Id, consume.Count)
    end

    autoExchangeInfo.ExchangeTimes = autoExchangeInfo.ExchangeTimes + exchangeTimes
    autoExchangeInfo.RewardCount = autoExchangeInfo.RewardCount + rewardCount
    autoExchangeInfo.AvailableExchangeTimes = autoExchangeInfo.AvailableExchangeTimes + exchangeTimes
    autoExchangeInfo.AvailableRewardCount = autoExchangeInfo.AvailableRewardCount + rewardCount
    autoExchangeInfo.ConsumeList = BuildCostItemList(consumeCountDic)
end

-- 尝试使用单个槽位的超频消耗，成功后扣减本地资源状态
---@param resourceState XEquipAwakePreviewResourceState 超频预览资源状态
---@param equipId number 意识装备 Id
---@return boolean isEnough 是否成功使用本次单槽位超频消耗
---@return number coinCost 单槽位螺母消耗
---@return XEquipAwakeCostItem[] itemCostList 单槽位材料消耗
function XEquipAwakeControl:_TryUseSingleAwakeCost(resourceState, equipId)
    -- 单槽位超频需要同时满足 Coin 和材料消耗；先在副本上试扣，失败时直接丢弃副本，避免污染外层资源状态
    local trialResourceState = XTool.Clone(resourceState)

    -- 先试扣 Coin，不足时本槽位不可执行
    local coinId = XDataCenter.ItemManager.ItemId.Coin
    local coinCost = self._Model:GetAwakeConsumeCrystalCoin(equipId, 1)
    if not self:_TryUseAwakeItem(trialResourceState, coinId, coinCost) then
        return false, 0, {}
    end

    -- 再逐个试扣材料，任意材料不足时本槽位不可执行
    local itemCostList = self._Model:GetAwakeConsumeItemCrystalList(equipId, 1) or {}
    for _, item in ipairs(itemCostList) do
        if not self:_TryUseAwakeItem(trialResourceState, item.ItemId, item.Count) then
            return false, 0, {}
        end
    end

    -- Coin 和材料都试扣成功后，才提交剩余资源与自动兑换预占信息
    resourceState.RemainItemCountDic = trialResourceState.RemainItemCountDic
    resourceState.AutoExchangeInfo = trialResourceState.AutoExchangeInfo

    return true, coinCost, itemCostList
end

return XEquipAwakeControl
