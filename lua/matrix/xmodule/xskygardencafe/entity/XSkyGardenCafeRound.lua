---@class XSkyGardenCafeRound : XEntity 回合控制
---@field _Model XSkyGardenCafeModel
---@field _OwnControl XSkyGardenCafeBattle
---@field _PoolEntities XSkyGardenCafeCardEntity[]
---@field _DeckEntities XSkyGardenCafeCardEntity[]
---@field _DealEntities XSkyGardenCafeCardEntity[]
---@field _ReDrawEntities XSkyGardenCafeCardEntity[]
---@field _RoundBeforeCardEntities XSkyGardenCafeCardEntity[]
local XSkyGardenCafeRound = XClass(XEntity, "XSkyGardenCafeRound")

local tableInsert = table.insert
local tableRemove = table.remove
local tableRange = table.range
local tableSort = table.sort
local pairs = pairs
local mathMin = math.min
local mathMax = math.max
local mathRandomSeed = math.randomseed
local mathRandom = math.random

local DlcEventId = XMVCA.XBigWorldService.DlcEventId
local EffectTriggerId = XMVCA.XSkyGardenCafe.EffectTriggerId
local DrawCardType = XMVCA.XSkyGardenCafe.DrawCardType

local IsDebugBuild = CS.XApplication.Debug

local RoundState = {
    None = 0,
    RoundBeginBefore = 1,
    RoundBeginAfter = 2,
    RoundEndBefore = 3,
    RoundEndAfter = 4,
    RoundReStart = 5,
    RoundContinue = 6,
}

function XSkyGardenCafeRound:OnInit()
end

function XSkyGardenCafeRound:OnRelease()
end

--region 流程控制

function XSkyGardenCafeRound:DoEnter(stageId, deckId)
    self._StageId = stageId
    self:OnEnter(stageId, deckId)
    self:AddEvent()
end

function XSkyGardenCafeRound:OnEnter()
end

function XSkyGardenCafeRound:DoExit(stageId)
    self:OnExit(stageId)
    self:ResetData()
    self:SubEvent()
    self:DebugExitGame()
    self:StopTimer()
end

function XSkyGardenCafeRound:OnExit()
end

function XSkyGardenCafeRound:InitData()
    --卡池
    self._PoolEntities = {}
    --手牌组
    self._DeckEntities = {}
    --出牌组
    self._DealEntities = {}
    --重抽组
    self._ReDrawEntities = {}
    --重抽时选中需要替换的卡牌
    self._ReDrawSelectIds = nil
    --回合开始前的抽卡
    self._RoundBeforeCardEntities = {}
    --选中的需要重抽卡牌的位置
    self._ReDrawSelectIndex = {}
    --状态
    self._RoundState = RoundState.None
    --下个席位下标
    self._NextDealIndex = 1
    --最大席位下标
    self._MaxDealIndex = self._Model:GetMaxDeckCount()

    --触发条件
    self._TriggerDictWhenDiscard = {
        [EffectTriggerId.Discard] = true
    }

    self._TriggerDictWhenDrawCard = {
        [EffectTriggerId.DrawCard] = true
    }
    
    self._TriggerCardResourceChanged = {
        [EffectTriggerId.CardResourceChanged] = true,
    }

    self._TriggerRoundResourceChanged = {
        [XMVCA.XSkyGardenCafe.EffectTriggerId.RoundResourceChanged] = true
    }

    self._TriggerDictWhenInDeck = {
        [EffectTriggerId.RoundBegin] = true,
        [EffectTriggerId.Deck2Deal] = true,
        [EffectTriggerId.KeepInDeck] = true,
        [EffectTriggerId.CardResourceChanged] = true,
        [EffectTriggerId.DealCountChanged] = true,
    }

    self._TriggerDictWhenDeckToDeal = {
        [EffectTriggerId.Deck2Deal] = true,
    }
    self._TriggerDictWhenDealCountChanged = {
        [EffectTriggerId.DealCountChanged] = true,
    }
    
    self._TriggerDictWhenRoundEnd = {
        [EffectTriggerId.RoundEnd] = true
    }
    
    self._TriggerDictWhenDeckRoundEnd = {
        [EffectTriggerId.KeepInDeck] = true,
        [EffectTriggerId.RoundEnd] = true,
    }
    
    self._TriggerDictWhenShuffleCard = {
        [EffectTriggerId.Shuffle] = true,
    }
end

function XSkyGardenCafeRound:ResetData()
    --卡池
    self._PoolEntities = nil
    --手牌组
    self._DeckEntities = nil
    --出牌组
    self._DealEntities = nil
    --重抽组
    self._ReDrawEntities = nil
    --回合开始前的抽卡
    self._RoundBeforeCardEntities = nil
    --选中的需要重抽卡牌的位置
    self._ReDrawSelectIndex = nil

    self._TriggerDictWhenDiscard = nil
    self._TriggerDictWhenDrawCard = nil
    self._TriggerDictWhenInDeck = nil
    self._TriggerDictWhenDeckToDeal = nil
    self._TriggerDictWhenRoundEnd = nil
    self._TriggerDictWhenDeckRoundEnd = nil
    self._TriggerDictWhenDealCountChanged = nil
    self._TriggerCardResourceChanged = nil
    self._TriggerRoundResourceChanged = nil
    self._DebugAddDeckCards = nil
    self._TriggerDictWhenShuffleCard = nil
    --清除掉NPC随机点位数据
    self._Model:ClearNpcRandomPoint()
end

function XSkyGardenCafeRound:AddEvent()
    ---@param cardA XSkyGardenCafeCardEntity
    ---@param cardB XSkyGardenCafeCardEntity
    self._SortCardFunc = function(cardA, cardB)
        local idA = cardA and cardA:GetCardId() or 0
        local idB = cardB and cardB:GetCardId() or 0
        local isZeroA = idA <= 0
        local isZeroB = idB <= 0
        if isZeroA ~= isZeroB then
            return isZeroB
        end
        local qA = self._Model:GetCustomerQuality(idA)
        local qB = self._Model:GetCustomerQuality(idB)
        if qA ~= qB then
            return qA > qB
        end
        local pA = self._Model:GetCustomerPriority(idA)
        local pB = self._Model:GetCustomerPriority(idB)
        if pA ~= pB then
            return pA > pB
        end
        return idA > idB
    end

    XMVCA.XSkyGardenCafe:AddInnerEvent(DlcEventId.EVENT_CAFE_APPLY_BUFF, self.OnEventApplyBuff, self)

    if IsDebugBuild then
        XEventManager.AddEventListener("EVENT_SG_DEBUG_POOL_TO_DECK", self.DebugPoolToDeck, self)
    end
end

function XSkyGardenCafeRound:SubEvent()
    self._SortCardFunc = nil

    XMVCA.XSkyGardenCafe:RemoveInnerEvent(DlcEventId.EVENT_CAFE_APPLY_BUFF, self.OnEventApplyBuff, self)

    if IsDebugBuild then
        XEventManager.RemoveEventListener("EVENT_SG_DEBUG_POOL_TO_DECK", self.DebugPoolToDeck, self)
    end
end

function XSkyGardenCafeRound:ContinueGame()
    --继续本回合
    tableSort(self._DeckEntities, self._SortCardFunc)
    --牌库到手牌(表现)
    self._OwnControl:Pool2DeckWithCount(#self._DeckEntities)
    --加载npc
    self._OwnControl:GetNpcFactory():LoadNpcWhenDrawCard(self._DeckEntities)

    if not XTool.IsTableEmpty(self._DeckEntities) then
        local argDict = { [EffectTriggerId.DrawCard] = { DrawCardType.Round, self._DeckEntities } }
        --触发关卡buff
        self._OwnControl:ApplyStageBuff(self._TriggerDictWhenDrawCard, argDict)
        --触发抽卡buff
        self:DoApplyBuff(true, true, true, self._TriggerDictWhenDrawCard, argDict)
    end
    --预览在手上的buff
    self:DoPreviewBuff(true, true, false, self._TriggerDictWhenInDeck, nil)
end

function XSkyGardenCafeRound:DoRoundBegin(isContinue)
    self._RoundState = isContinue and RoundState.RoundContinue or RoundState.RoundBeginBefore
    self._ReviewChangeNums = {}
    self._Model:GetBattleInfo():SyncBill()
    self:OnRoundBegin()
    self:DoApplyBuffWhenRoundBefore()
    if isContinue then
        self:ContinueGame()
    else --开始新游戏
        if self._Model:IsReDrawStage(self._StageId) 
                and self._Model:GetBattleInfo():GetRound() == 1 then --重抽
            self:PoolToReDraw()
        else
            if self._Model:GetBattleInfo():GetRound() == 1 then
                self:OpenBroadcastFirst()
            end
            self:PoolToDeck()
        end
    end
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_ROUND_BEGIN)
end

function XSkyGardenCafeRound:OnRoundBegin()
end

function XSkyGardenCafeRound:DoRoundEnd()
    self._RoundState = RoundState.RoundEndBefore
    --触发回合结束
    self._OwnControl:ApplyStageBuff(self._TriggerDictWhenRoundEnd)
    ---@type XSkyGardenCafeCardEntity[] 本回合所有弃掉的牌
    local abandon = {}
    --触发出牌区回合结束
    self:DoApplyBuff(false, true, false, self._TriggerDictWhenRoundEnd)
    --先弃掉出牌区里的牌
    self:DiscardDealCards(abandon)
    --触发手牌区回合结束
    self:DoApplyBuff(true, false, false, self._TriggerDictWhenDeckRoundEnd)
    --弃掉手牌
    local removeIndexList = self:DiscardDeckCards(abandon)
    --表现
    self._OwnControl:Deal2Pool()
    self._OwnControl:Deck2Pool(removeIndexList)
    --放入弃牌堆
    local info = self._Model:GetBattleInfo()
    info:SyncAbandonCards(abandon, true)
    --同步下个回合
    info:NextRound()
    self._OwnControl:SyncNextRoundBuff()
    self:OnRoundEnd()
    --清除掉NPC随机点位数据
    self._Model:ClearNpcRandomPoint()
    self._RoundState = RoundState.RoundEndAfter
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_RESET_BUFF_PREVIEW)
end

function XSkyGardenCafeRound:OnRoundEnd()
end

function XSkyGardenCafeRound:DoRoundReStart()
    self._RoundState = RoundState.RoundReStart
    --表现
    self._OwnControl:Deal2Pool()
    local removeIndexList = {}
    for i = 0, #self._DeckEntities - 1 do
        removeIndexList[#removeIndexList + 1] = i 
    end
    --清除本回合打印信息
    self:DebugRoundReStart()
    self._OwnControl:Deck2Pool(removeIndexList)
    --移除下回合Buff
    self._OwnControl:ReleaseNextAddBuff()
    self._Model:ClearNpcRandomPoint()
    --移除掉牌库
    self:ClearPoolCards()
    --清掉手牌
    self:ClearDeckCards()
    --清掉出牌
    self:ClearDealCards()
    --清除掉回合初抽卡
    self:ClearRoundBeforeCards()
    --移除掉NPC
    self._OwnControl:GetNpcFactory():RemoveNpcWhenRoundEnd(self._DeckEntities, true)
    --清除下标
    self:UpdateDealIndex()
    local info = self._Model:GetBattleInfo()
    --重置回合修改数据
    info:ResetWhenDataSync(false)
    --同步数据
    self:InitBattleInfoWithServer()
    self:DoRoundBegin(true)
    --刷新手牌显示
    self._OwnControl:RefreshContainer(XMVCA.XSkyGardenCafe.CardContainer.Deck)
    --增加重置次数
    self._OwnControl:AddResetTimes()
    XMVCA.XSkyGardenCafe:SetLastWaitTime(XTime.GetServerNowTimestamp())
end

function XSkyGardenCafeRound:DoRequestRoundChange(dealCardIds, deckCardIds, reviewChangedNums, requestCb)
    local serverData = self._OwnControl:ToServerData()
    local req = {
        CafeGambling = serverData,
        --埋点：本回合重置使用次数
        ResetTimes = self._OwnControl:GetResetTimes(),
        --埋点：出的牌的id
        PlayedCardList = dealCardIds,
        --埋点：本回合玩家出牌前的手牌
        HandCardsBeforePlay = deckCardIds,
        --埋点：每回合好评变化列表
        ReviewNumChangeList = reviewChangedNums
    }
    local maxRound = self._Model:GetStageRounds(self._StageId)
    local info = self._Model:GetBattleInfo()
    local handleError = function() 
        self._OwnControl:GiveUp(function() 
            XMVCA.XBigWorldUI:SafeClose("UiSkyGardenCafeGame")
        end) 
    end
    XNetwork.Call("BigWorldCafeNextRoundRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            handleError()
            return
        end
        info:UpdateData(serverData)
        local curRound = info:GetRound()
        
        local isGameFinish = curRound > maxRound
        if requestCb then
            requestCb()
        end
        if not isGameFinish then
            self._OwnControl:GetMainControl():PopupBroadcast()
            XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_ROUND_BEGIN)
        end
        self._OwnControl:ResetResetTimes()
        self._OwnControl:ChangeRoundSettle(false)
    end, nil, handleError)
end

function XSkyGardenCafeRound:InitBattleInfoWithClint()
end

function XSkyGardenCafeRound:InitBattleInfoWithServer()
    local info = self._Model:GetBattleInfo()
    self:InitPoolCards(info:GetLibCards())
    self:InitDeckCards(info:GetDeckCards())

    --同步回合Buff
    self._OwnControl:SyncNextRoundBuffWithServer()
end

--endregion


--region 卡牌操作

function XSkyGardenCafeRound:InitPoolCards(cardIdList)
    if XTool.IsTableEmpty(cardIdList) then
        return
    end
    local factory = self._OwnControl:GetCardFactory()
    for _, cardId in pairs(cardIdList) do
        local card = factory:CreateCard(cardId)
        self:InsertPool(card)
    end
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
end

function XSkyGardenCafeRound:ClearPoolCards()
    if XTool.IsTableEmpty(self._PoolEntities) then
        return
    end
    local factory = self._OwnControl:GetCardFactory()
    for i = #self._PoolEntities, 1, -1 do
        local card = self._PoolEntities[i]
        factory:RemoveEntity(card)
        self:RemovePool(i)
    end
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
end

function XSkyGardenCafeRound:InsertPool(card, index)
    if not card then
        return
    end
    if index then
        tableInsert(self._PoolEntities, index, card)
    else
        self._PoolEntities[#self._PoolEntities + 1] = card
    end
end

function XSkyGardenCafeRound:RemovePool(index)
    tableRemove(self._PoolEntities, index)
end

--- 往牌库里创建几张新的卡牌
---@param targetIds number[]
---@param count number
---@param isRandom boolean
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:InsertPoolNewCards(targetIds, count, isRandom)
    local needCount = targetIds and #targetIds or 0
    local createIds
    if needCount > count then
        if isRandom then
            targetIds = XTool.RandomArray(targetIds, os.time(), false)
        end
        createIds = tableRange(targetIds, 1, count)
    else
        createIds = targetIds
    end
    local cards = {}
    local factory = self._OwnControl:GetCardFactory()
    local isRoundStart = self._RoundState == RoundState.RoundBeginBefore
    for _, cardId in pairs(createIds) do
        local card = factory:CreateCard(cardId)
        if not isRoundStart then
            self:InsertPool(card)
        end
        cards[#cards + 1] = card
    end
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
    return cards
end

--- 根据位置往牌库里创建几张新的卡牌
---@param targetIds number[]
---@param edge number
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:InsertPoolNewCardsWithEdge(targetIds, edge)
    if XTool.IsTableEmpty(targetIds) then
        return
    end
    local poolCards = self._PoolEntities
    local factory = self._OwnControl:GetCardFactory()
    if edge == 1 then --随机位置
        mathRandomSeed(os.time())
        for _, cardId in pairs(targetIds) do
            local card = factory:CreateCard(cardId)
            local index = mathRandom(1, #poolCards)
            self:InsertPool(card, index)
        end
    elseif edge == 2 then --牌堆顶
        for index, cardId in pairs(targetIds) do
            local card = factory:CreateCard(cardId)
            self:InsertPool(card, index)
        end
    elseif edge == 3 then --牌堆尾
        for _, cardId in pairs(targetIds) do
            local card = factory:CreateCard(cardId)
            self:InsertPool(card)
        end
    end
    
end

--- 移除卡组里的卡
---@param dict table<XSkyGardenCafeCardEntity, number>
---@return number[]
function XSkyGardenCafeRound:RemovePoolCards(dict)
    if XTool.IsTableEmpty(dict) then
        return
    end
    local cards = self._PoolEntities
    for i = #cards, 1, -1 do
        if XTool.IsTableEmpty(dict) then
            break
        end
        local card = cards[i]
        local cnt = dict[card]
        if cnt and cnt > 0 then
            cnt = cnt - 1
            dict[card] = cnt
            self:RemovePool(i)
        end
    end
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
end

function XSkyGardenCafeRound:InitDeckCards(cardIdList)
    if XTool.IsTableEmpty(cardIdList) then
        return
    end
    local factory = self._OwnControl:GetCardFactory()
    for _, cardId in pairs(cardIdList) do
        local card = factory:CreateCard(cardId)
        self:InsertDeck(card)
    end
end

function XSkyGardenCafeRound:DiscardDeckCards(record)
    local deckCards = self._DeckEntities
    if XTool.IsTableEmpty(deckCards) then
        return
    end
    local csRemoveIndex = {}
    local info, factory = self._Model:GetBattleInfo(), self._OwnControl:GetCardFactory()
    for i = #deckCards, 1, -1 do
        local card = deckCards[i]
        local cardId = card:GetCardId()
        local isBan = info:IsBanCard(cardId)
        local isStay = info:IsStayInHand(cardId)
        local isDebugAdd = self:IsDebugAddCard(card)
        --不保留在手上
        if not isStay or isBan then
            card:DoApplyBuff(self._TriggerDictWhenDiscard)

            if not isBan and not isDebugAdd then
                record[#record + 1] = cardId
            end
            csRemoveIndex[#csRemoveIndex + 1] = i - 1
            self:RemoveDebugAddCard(card)
            factory:RemoveEntity(card)
            self:RemoveDeck(i)
        else
            card:ClearBuffArgs()
        end
    end

    return csRemoveIndex
end

function XSkyGardenCafeRound:InsertDeck(card, index)
    if not card then
        return
    end
    if index then
        tableInsert(self._DeckEntities, card)
    else
        self._DeckEntities[#self._DeckEntities + 1] = card
    end
end

function XSkyGardenCafeRound:ClearDeckCards()
    if XTool.IsTableEmpty(self._DeckEntities) then
        return
    end
    local factory = self._OwnControl:GetCardFactory()
    for i = #self._DeckEntities, 1, -1 do
        local card = self._DeckEntities[i]
        self:RemoveDebugAddCard(card)
        factory:RemoveEntity(card)
        self:RemoveDeck(i)
    end
end

function XSkyGardenCafeRound:RemoveDeck(index)
    tableRemove(self._DeckEntities, index)
end

function XSkyGardenCafeRound:DiscardDealCards(record)
    local dealCards = self._DealEntities
    if XTool.IsTableEmpty(dealCards) then
        return
    end
    local info, factory = self._Model:GetBattleInfo(), self._OwnControl:GetCardFactory()
    for i = #dealCards, 1, -1 do
        local card = dealCards[i]
        local cardId = card:GetCardId()
        if not info:IsBanCard(cardId) and not self:IsDebugAddCard(card) then
            record[#record + 1] = cardId
        end
        self:RemoveDebugAddCard(card)
        factory:RemoveEntity(card)
        self:RemoveDeal(i)
    end
    self:UpdateDealIndex()
end

function XSkyGardenCafeRound:InsertDeal(card, index)
    if not card then
        return
    end
    if index then
        tableInsert(self._DealEntities, card)
    else
        self._DealEntities[#self._DealEntities + 1] = card
    end
end

function XSkyGardenCafeRound:ClearDealCards()
    if XTool.IsTableEmpty(self._DealEntities) then
        return
    end
    local factory = self._OwnControl:GetCardFactory()
    for i = #self._DealEntities, 1, -1 do
        local card = self._DealEntities[i]
        self:RemoveDebugAddCard(card)
        factory:RemoveEntity(card)
        self:RemoveDeal(i)
    end
end

function XSkyGardenCafeRound:RemoveDeal(index)
    tableRemove(self._DealEntities, index)
end

function XSkyGardenCafeRound:InsertRoundBefore(card, index)
    if not card then
        return
    end
    if index then
        tableInsert(self._RoundBeforeCardEntities, card)
    else
        self._RoundBeforeCardEntities[#self._RoundBeforeCardEntities + 1] = card
    end
end

function XSkyGardenCafeRound:RemoveRoundBegin(index)
    tableRemove(self._RoundBeforeCardEntities, index)
end

function XSkyGardenCafeRound:ClearRoundBeforeCards()
    if XTool.IsTableEmpty(self._RoundBeforeCardEntities) then
        return
    end
    local factory = self._OwnControl:GetCardFactory()
    for i = #self._RoundBeforeCardEntities, 1, -1 do
        local card = self._RoundBeforeCardEntities[i]
        factory:RemoveEntity(card)
        self:RemoveRoundBegin(i)
    end
end

function XSkyGardenCafeRound:InsertReDraw(card, index)
    if not card then
        return
    end
    if index then
        tableInsert(self._ReDrawEntities, card)
    else
        self._ReDrawEntities[#self._ReDrawEntities + 1] = card
    end
end

function XSkyGardenCafeRound:RemoveReDraw(index)
    tableRemove(self._ReDrawEntities, index)
end

--- 抽牌组里抽牌
function XSkyGardenCafeRound:PoolToDeck()
    --顺序抽卡
    local cards = self:SequenceCards(self:GetRestDeckCount())
    --抽卡表现
    self:DoPoolToDeck(cards)
    
    if not XTool.IsTableEmpty(cards) then
        local argDict = { [EffectTriggerId.DrawCard] = { DrawCardType.Round, cards } }
        --触发关卡buff
        self._OwnControl:ApplyStageBuff(self._TriggerDictWhenDrawCard, argDict)
        --触发抽卡buff
        self:DoApplyBuff(true, true, true, self._TriggerDictWhenDrawCard, argDict)
    end
    --预览在手上的buff
    self:DoPreviewBuff(true, true, false, self._TriggerDictWhenInDeck, nil)
end

--- 抽卡表现
---@param cards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:DoPoolToDeck(cards)
    --从牌组里抽到的
    local count = cards and #cards or 0
    --回合开始给的
    local roundBeforeCount = #self._RoundBeforeCardEntities
    local total = count + roundBeforeCount
    if total <= 0 then
        return
    end
    local dict = {}
    if roundBeforeCount > 0 then
        local targetCards = self._RoundBeforeCardEntities
        for i = roundBeforeCount, 1, -1 do
            local card = targetCards[i]
            --放进手牌
            self:InsertDeck(card)
            --移除卡牌
            self:RemoveRoundBegin(i)
            self:RecordCount(dict, card)
        end
    end
    if not XTool.IsTableEmpty(cards) then
        for _, card in pairs(cards) do
            --放进手牌
            self:InsertDeck(card)
            self:RecordCount(dict, card)
        end
    end
    --移除掉卡组
    self:RemovePoolCards(self:CloneRecord(dict))
    --插入卡下标
    local indexList = self:CalcDeckInsertIndexList(dict)
    self._OwnControl:Pool2DeckWithList(indexList)
    --加载Npc模型
    self._OwnControl:GetNpcFactory():LoadNpcWhenDrawCard(self._DeckEntities)
    --抽卡完成后
    self._RoundState = RoundState.RoundBeginAfter
end

--- 手牌到出牌区
---@param deckIndex number 手牌区下标
---@param dealIndex number 出牌区下标
function XSkyGardenCafeRound:DeckToDeal(deckIndex, dealIndex)
    local deckCards = self._DeckEntities
    local card = deckCards[deckIndex]
    if not card then
        XLog.Error(string.format("出牌异常，卡牌为空，手牌下标: %s", deckIndex))
        return
    end
    self:InsertDeal(card, dealIndex)
    self:RemoveDeck(deckIndex)
    --增加使用次数
    local battleInfo = self._Model:GetBattleInfo()
    battleInfo:AddCardUseCount(card:GetCardId())
    --更新出牌区下标
    self:UpdateDealIndex()
    --更新出牌区卡牌信息
    self:UpdateDealCardInfo()
    --触发当前出牌的Buff
    card:DoApplyBuff(self._TriggerDictWhenDeckToDeal, nil)
    if card:IsResourceChanged() then
        card:DoApplyBuff(self._TriggerCardResourceChanged, nil)
    end
    --插入出牌信息
    self:DebugDeckToDeal(card:GetCardId())
    --触发整个出牌区Buff
    self:DoApplyBuff(false, true, false, self._TriggerDictWhenDeckToDeal, nil)
    local rest = self:GetRestDeckCount()
    --还有空位置时，打一抽一
    if rest > 0 then
        local cards = self:SequenceCards(1)
        self:DoPoolToDeck(cards)
        self:DoApplyBuffWhenDrawCards(card, cards)
    end
    --触发出牌区数量改变
    self:DoApplyBuff(true, true, false, self._TriggerDictWhenDealCountChanged, nil)
    --更新出牌区卡牌信息
    self:UpdateDealCardInfo()
    --触发回合资源改变
    self:DoApplyBuff(true, true, false, self._TriggerRoundResourceChanged)
    --预览手牌在手中
    self:DoPreviewBuff(true, true, false, self._TriggerDictWhenInDeck, nil)
    --事件通知界面刷新
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_UPDATE_PLAY_CARD)
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_DECK_TO_DEAL, deckIndex, dealIndex)
    --打牌时加载模型
    self._OwnControl:GetNpcFactory():LoadNpc(card)
    
    self._ReviewChangeNums[#self._ReviewChangeNums + 1] = card:GetTotalReview(true)
    
    XMVCA.XSkyGardenCafe:SetLastWaitTime(XTime.GetServerNowTimestamp())
end

--- 游戏开始，重抽逻辑
function XSkyGardenCafeRound:PoolToReDraw()
    local cards = self:SequenceCards(self:GetRestDeckCount())
    if XTool.IsTableEmpty(cards) then
        XLog.Error("重抽失败，抽到0张卡牌！")
        return
    end
    local toDeckCards, toReDrawCards = {}, {}
    for _, card in pairs(cards) do
        if card:IsReDrawCard() then
            toReDrawCards[#toReDrawCards + 1] = card
        else
            toDeckCards[#toDeckCards + 1] = card
        end
    end
    
    --先将不能重抽的卡放进手牌，从牌库内移除掉
    if not XTool.IsTableEmpty(toDeckCards) or not XTool.IsTableEmpty(self._RoundBeforeCardEntities) then
        self:DoPoolToDeck(toDeckCards)
        self:DoApplyBuff(true, true, false, self._TriggerDictWhenDrawCard, {
            [EffectTriggerId.DrawCard] = { DrawCardType.Round, toDeckCards }
        })
    end
    --跟新重抽&牌库
    if not XTool.IsTableEmpty(toReDrawCards) then
        local dict = {}
        tableSort(toReDrawCards, self._SortCardFunc)
        for _, card in pairs(toReDrawCards) do
            self:InsertReDraw(card)
            self:RecordCount(dict, card)
        end
        self:RemovePoolCards(dict)
        --重抽表现
        self._OwnControl:PoolToReDraw(#toReDrawCards)
        XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_RE_DRAW_CARD, true)
    end
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
end

--- 重抽完成，卡牌进入手牌
function XSkyGardenCafeRound:ReDrawToDeck()
    local toReDrawCards = self._ReDrawEntities
    if XTool.IsTableEmpty(toReDrawCards) then
        return
    end
    
    --选中了一些需要重抽的牌
    if self:IsSelectReDrawCard() then
        local selectIndex = {}
        for index, value in pairs(self._ReDrawSelectIndex) do
            if value then
                selectIndex[#selectIndex + 1] = index
            end
        end
        --重新抽几张
        local cards = self:SequenceCards(#selectIndex)
        mathRandomSeed(os.time())
        local poolCards = self._PoolEntities
        --需要移除掉的卡牌
        local drawDict = {}
        local redrawReplaceCardIds = {}
        --更新数据
        for index, select in pairs(selectIndex) do
            --抽取的卡牌
            local drawCard = cards[index]
            --原来的卡牌
            local originCard = toReDrawCards[select]
            --替换为新的卡牌
            toReDrawCards[select] = drawCard
            --将卡牌随机放入到牌组中
            local randomIndex = mathRandom(1, #poolCards)
            self:InsertPool(originCard, randomIndex)
            
            self:RecordCount(drawDict, drawCard)
            redrawReplaceCardIds[#redrawReplaceCardIds + 1] = originCard:GetCardId()
        end
        self:RemovePoolCards(drawDict)
        self._ReDrawSelectIds = redrawReplaceCardIds
    end
    
    local dict = {}
    for i = #toReDrawCards, 1, -1 do
        local card = toReDrawCards[i]
        self:InsertDeck(card)
        self:RecordCount(dict, card)
    end
    --获取下标
    local indexList = self:CalcDeckInsertIndexList(dict)
    self._OwnControl:ReDrawToDeck(indexList)
    
    --触发Buff之前同步给服务器
    self._OwnControl:RequestEnterGame(self:GetDeckId(), function()
        local triggerDict = {
            [EffectTriggerId.DrawCard] = true,
            [EffectTriggerId.RoundBegin] = true,
        }
        --触发抽卡Buff
        self:DoApplyBuff(true, true, false, triggerDict, {
            [EffectTriggerId.DrawCard] = { DrawCardType.Round, toReDrawCards }
        })
        --预览在手上的buff
        self:DoPreviewBuff(true, true, false, self._TriggerDictWhenInDeck, nil)
        for i = #toReDrawCards, 1, -1 do
            self:RemoveReDraw(i)
        end
        --加载npc
        self._OwnControl:GetNpcFactory():LoadNpcWhenDrawCard(self._DeckEntities)
        XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_RE_DRAW_CARD, false)
        XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
        --弹关卡目标
        self:OpenBroadcastFirst()
    end)
end

--- 牌组替换手牌
---@param deckCards XSkyGardenCafeCardEntity[] 手牌
---@param poolCards XSkyGardenCafeCardEntity[] 牌组
---@param card XSkyGardenCafeCardEntity 调用的那张卡
function XSkyGardenCafeRound:ReplacePoolInDeck(deckCards, poolCards, card)
    local addDeckCount = 0
    if self._RoundState == RoundState.RoundBeginBefore then
        if not XTool.IsTableEmpty(poolCards) then
            addDeckCount = #poolCards
            for _, poolCard in pairs(poolCards) do
                self:InsertRoundBefore(poolCard)
            end
            self._Model:GetBattleInfo():AddDeckCount(addDeckCount)
        end
        return addDeckCount
    end
    --先将卡牌从手牌中移动到牌组中
    local toPoolCount = self:DeckToPool(deckCards)
    --再将牌组里的牌移动到手牌中
    if not XTool.IsTableEmpty(poolCards) then
        local info = self._Model:GetBattleInfo()
        --最大手牌数
        local maxCount = self._Model:GetMaxDeckCount()
        --手牌当前上限
        local limit = info:GetDeckLimit(maxCount)
        --当前手牌数
        local curCount = #self._DeckEntities + #self._RoundBeforeCardEntities
        --预计放入
        local count = #poolCards
        --能放入的数量
        local insertCount = mathMin(maxCount - curCount, count)
        --需要增加的上限
        local addLimit = mathMin(maxCount - limit, insertCount)
        addDeckCount = mathMax(addLimit - toPoolCount, 0)
        local realCards
        --需要增加上限，但是已经达到上限
        if count > 0 and (addDeckCount == 0 or addDeckCount + limit >= maxCount) then
            --没有换牌换牌 || 换牌数不等于增加上限数，则提示
            if toPoolCount <= 0 or toPoolCount > insertCount then
                XUiManager.TipMsg(self._OwnControl:GetMainControl():GetDeckNumIsFullText())
            end
        end
        --实际需要插入的卡
        realCards = tableRange(poolCards, 1, insertCount)
        --实际增加增加上限
        self._Model:GetBattleInfo():AddDeckCount(addDeckCount)
        self:DoPoolToDeck(realCards)
        --触发抽卡Buff
        if card then
            self:DoApplyBuffWhenDrawCards(card, realCards)
        end
    end
    return addDeckCount
end

--- 牌组替换手牌
---@param cards XSkyGardenCafeCardEntity[] 手牌
function XSkyGardenCafeRound:DeckToPool(cards)
    if XTool.IsTableEmpty(cards) then
        return 0
    end
    local dict = {}
    --放进牌库中
    for _, card in pairs(cards) do
        self:RecordCount(dict, card)
        self:InsertPool(card)
    end
    --移除手牌（数据）
    local removeIndex = {}
    local deckCards = self._DeckEntities
    for i = #deckCards, 1, -1 do
        local card = deckCards[i]
        local cnt = dict[card]
        if cnt and cnt > 0 then
            removeIndex[#removeIndex + 1] = i - 1
            cnt = cnt - 1
            dict[card] = cnt
            self:RemoveDeck(i)
        end
    end
    --移除手牌（表现）
    self._OwnControl:Deck2Pool(removeIndex)
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_POOL_CARD_COUNT_UPDATE)
    
    return #removeIndex
end

--endregion


--region 数据更新

function XSkyGardenCafeRound:UpdateDealIndex()
    local index = #self._DealEntities + 1
    self._NextDealIndex = mathMin(index, self._MaxDealIndex)

    XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_DEAL_INDEX_UPDATE)
end

function XSkyGardenCafeRound:UpdateDealCardInfo()
    local info = self._Model:GetBattleInfo()
    info:ResetAddCardScore()
    info:ResetAddCardReview()
    local addScore = 0
    local addReview = 0
    for _, card in pairs(self._DealEntities) do
        addScore = addScore + card:GetTotalCoffee(false)
        addReview = addReview + card:GetTotalReview(false)
    end
    info:AddCardScore(addScore)
    info:AddCardReview(addReview)
end

function XSkyGardenCafeRound:SetReDrawSelectIndex(index, value)
    self._ReDrawSelectIndex[index] = value
end

--endregion


--region 洗牌&抽牌

--- 顺序抽卡
---@param count number
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:SequenceCards(count)
    if count <= 0 then
        return
    end
    local poolEntities = self._PoolEntities
    --剩余卡数量
    local rest = #poolEntities
    --牌不够抽了
    if rest < count then
        self:Shuffle()
        rest = #poolEntities
    end
    --牌仍然不够
    if rest < count then
        XLog.Error(string.format("牌库数量不足，剩余卡牌数量：%s, 需要抽卡数量：%s", rest, count))
        count = rest
    end
    local precede, normal = self:GetDifferentPriorityCards(poolEntities)
    --跟优先抽卡的数量差距
    local subCount = count - #precede
    --优先抽卡 == 需要抽卡数
    if subCount == 0 then
        return precede
    end
    --优先抽卡数量不足, 从普通池里抽subCount个
    if subCount > 0 then
        for index = 1, subCount do
            precede[#precede + 1] = normal[index]
        end
        return precede
    end
    return tableRange(precede, 1, count)
end

--- 随机打乱目标卡组，并抽取count个
---@param sources XSkyGardenCafeCardEntity[]
---@param count number
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:RandomCards(sources, count)
    if XTool.IsTableEmpty(sources) then
        return sources
    end
    local rest = #sources
    --无需随机D
    if rest <= count then
        return tableRange(sources, 1, count)
    end
    local precede, normal = self:GetDifferentPriorityCards(sources)
    --跟优先抽卡的数量差距
    local subCount = count - #precede
    --优先抽卡 == 需要抽卡数
    if subCount == 0 then
        return precede
    end
    mathRandomSeed(os.time())
    --优先抽卡数量不足, 从普通池里随机subCount个
    if subCount > 0 then
        local subList = {}
        local normalCnt = #normal
        for _ = 1, subCount do
            local index = mathRandom(1, normalCnt)
            local temp = normal[index]
            subList[#subList + 1] = temp
            --交换当前跟最后一个
            normal[index], normal[normalCnt] = normal[normalCnt], normal[index]
            normalCnt = normalCnt - 1
        end
        return XTool.MergeArray(precede, subList)
    end

    --优先抽卡数量已经足够
    local subList = {}
    local precedeCnt = #precede
    for _ = 1, count do
        local index = mathRandom(1, precedeCnt)
        local temp = precede[index]
        subList[#subList + 1] = temp
        --交换当前跟最后一个
        precede[index], precede[precedeCnt] = precede[precedeCnt], precede[index]
        precedeCnt = precedeCnt - 1
    end
    return subList
end

--- 洗牌
---@param
---@return
function XSkyGardenCafeRound:Shuffle()
    local info = self._Model:GetBattleInfo()
    local cardIds = info:GetAbandonCards()
    --再次随机打乱
    cardIds = XTool.RandomArray(cardIds, os.time(), true)
    self:InitPoolCards(cardIds)
    self:DoApplyBuff(false, false, true, self._TriggerDictWhenShuffleCard)
    info:SyncAbandonCards({}, false)
end

--- 获取优先级不同的卡组
---@param sources XSkyGardenCafeCardEntity[]
---@return XSkyGardenCafeCardEntity[], XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetDifferentPriorityCards(sources)
    local precede, normal = {}, {}
    
    if XTool.IsTableEmpty(sources) then
        return precede, normal
    end
    local info = self._Model:GetBattleInfo()
    for _, card in pairs(sources) do
        local cardId = card:GetCardId()
        if info:IsPrecede(cardId) then
            precede[#precede + 1] = card
        else
            normal[#normal + 1] = card
        end
    end
    if #precede > 1 then
        ---@param a XSkyGardenCafeCardEntity
        ---@param b XSkyGardenCafeCardEntity
        tableSort(precede, function(a, b) 
            local pA = self._Model:GetCustomerPriority(a:GetCardId())
            local pB = self._Model:GetCustomerPriority(b:GetCardId())
            if pA ~= pB then
                return pA > pB
            end
            return a:GetCardId() > b:GetCardId()
        end)
    end
    return precede, normal
end

--endregion


--region Buff操作

--- 触发buff
---@param isDeck boolean 是否触发手牌区
---@param isDeal boolean 是否触发出牌区
---@param isPool boolean 是否触发卡组
---@param triggerDict table 需要触发的条件组
---@param triggerArgsDict table 条件组对应的参数
function XSkyGardenCafeRound:DoApplyBuff(isDeck, isDeal, isPool, triggerDict, triggerArgsDict)
    if isDeck then
        for _, card in pairs(self._DeckEntities) do
            card:DoApplyBuff(triggerDict, triggerArgsDict)
        end
    end

    if isDeal then
        for _, card in pairs(self._DealEntities) do
            card:DoApplyBuff(triggerDict, triggerArgsDict)
        end
    end

    if isPool then
        for _, card in pairs(self._PoolEntities) do
            card:DoApplyBuff(triggerDict, triggerArgsDict)
        end
    end
end

--- 预览buff
---@param isDeck boolean 是否触发手牌区
---@param isDeal boolean 是否触发出牌区
---@param isPool boolean 是否触发卡组
---@param triggerDict table 需要触发的条件组
---@param triggerArgsDict table 条件组对应的参数
function XSkyGardenCafeRound:DoPreviewBuff(isDeck, isDeal, isPool, triggerDict, triggerArgsDict)
    if isDeck then
        for _, card in pairs(self._DeckEntities) do
            card:DoPreviewBuff(triggerDict, triggerArgsDict)
        end
    end

    if isDeal then
        for _, card in pairs(self._DealEntities) do
            card:DoPreviewBuff(triggerDict, triggerArgsDict)
        end
    end

    if isPool then
        for _, card in pairs(self._PoolEntities) do
            card:DoPreviewBuff(triggerDict, triggerArgsDict)
        end
    end
end

--- 触发抽卡buff
---@param playCard XSkyGardenCafeCardEntity 打出去的牌
---@param drawCards XSkyGardenCafeCardEntity[] 抽到的牌
function XSkyGardenCafeRound:DoApplyBuffWhenDrawCards(playCard, drawCards)
    local argDict = {
        [EffectTriggerId.DrawCard] = { DrawCardType.PlayCard, drawCards }
    }
    if playCard then
        playCard:DoApplyBuff(self._TriggerDictWhenDrawCard, argDict)
    end
    for _, drawCard in pairs(drawCards) do
        drawCard:DoApplyBuff(self._TriggerDictWhenDrawCard, argDict)
    end
    self:DoApplyBuff(true, false, false, self._TriggerDictWhenDrawCard, argDict)
end

--- 触发回合开始前的Buff
function XSkyGardenCafeRound:DoApplyBuffWhenRoundBefore()
    local triggerDict = {
        [EffectTriggerId.RoundBegin] = true
    }
    --先预览在手上的buff
    self:DoPreviewBuff(true, true, false, self._TriggerDictWhenInDeck)
    --再生效
    self:DoApplyBuff(true, false, true, triggerDict, nil)
    self._OwnControl:ApplyNextRoundBuff()
    self._OwnControl:ApplyStageBuff(triggerDict, nil)
end

--- 通过事件触发Buff
function XSkyGardenCafeRound:OnEventApplyBuff(isDeck, isDeal, isPool, triggerDict, triggerArgsDict)
    self:DoApplyBuff(isDeck, isDeal, isPool, triggerDict, triggerArgsDict)
end

--endregion


--region Getter & Setter

function XSkyGardenCafeRound:GetDeckCardIds()
    local list = {}
    for _, card in pairs(self._DeckEntities) do
        list[#list + 1] = card:GetCardId()
    end
    return list
end

--- readonly
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetDeckCardEntities()
    return self._DeckEntities
end

function XSkyGardenCafeRound:GetDeckCardEntityWithId(cardId)
    if XTool.IsTableEmpty(self._DeckEntities) then
        return
    end
    for _, card in pairs(self._DeckEntities) do
        if card:GetCardId() == cardId then
            return card
        end
    end
end

--- 根据类型获取手牌中的牌
---@param typeDict table<number>
---@param isTarget boolean
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetDeckCardsWithType(typeDict, isTarget)
    if XTool.IsTableEmpty(typeDict) then
        return
    end
    local list = {}
    for _, card in pairs(self._DeckEntities) do
        local t = card:GetCardType()
        if isTarget then
            if typeDict[t] then
                list[#list + 1] = card
            end
        else
            if not typeDict[t] then
                list[#list + 1] = card
            end
        end
    end

    return list
end

--- 根据品质获取手牌中的牌
---@param qualityDict table<number>
---@param isTarget boolean
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetDeckCardsWithQuality(qualityDict, isTarget)
    if XTool.IsTableEmpty(qualityDict) then
        return
    end
    local list = {}
    for _, card in pairs(self._DeckEntities) do
        local q = card:GetCardQuality()
        if isTarget then
            if qualityDict[q] then
                list[#list + 1] = card
            end
        else
            if not qualityDict[q] then
                list[#list + 1] = card
            end
        end
    end

    return list
end

--- 获取需要抽取卡的数量
---@return number
function XSkyGardenCafeRound:GetRestDeckCount()
    local limit = self._Model:GetBattleInfo():GetDeckLimit(self._Model:GetMaxDeckCount())
    return limit - #self._DeckEntities - #self._RoundBeforeCardEntities
end

function XSkyGardenCafeRound:GetDealCardIds()
    local list = {}
    for _, card in pairs(self._DealEntities) do
        list[#list + 1] = card:GetCardId()
    end
    return list
end

--- readonly
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetDealCardEntities()
    return self._DealEntities
end

--- 根据卡牌Id获取卡牌下标，如果有相同卡牌，只能取到第一个
---@param cardId number
---@return number
function XSkyGardenCafeRound:GetDealCardIndexWithCardId(cardId)
    if not cardId or cardId < 0 then
        return -1
    end
    local cards = self._DealEntities
    if XTool.IsTableEmpty(cards) then
        return -1
    end
    for index, entity in pairs(cards) do
        if entity:GetCardId() == cardId then
            return index
        end
    end
    return -1
end

--- 根据卡牌获取卡牌下标
---@param card XSkyGardenCafeCardEntity
---@return number
function XSkyGardenCafeRound:GetDealCardIndexWithCard(card)
    if not card then
        return -1
    end
    local cards = self._DealEntities
    if XTool.IsTableEmpty(cards) then
        return -1
    end
    for index, entity in pairs(cards) do
        if entity == card then
            return index
        end
    end
    return -1
end

--- 获取出牌区剩余空位
---@return number
function XSkyGardenCafeRound:GetRestDealCount()
    local limit = self._Model:GetBattleInfo():GetDealLimit()
    return limit - #self._DealEntities
end

function XSkyGardenCafeRound:GetPoolCardIds()
    local list = {}
    for _, card in pairs(self._PoolEntities) do
        list[#list + 1] = card:GetCardId()
    end
    return list
end

--- readonly
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetPoolCardEntities()
    return self._PoolEntities
end

--- readonly
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetReDrawCardEntities()
    return self._ReDrawEntities
end

function XSkyGardenCafeRound:GetReDrawSelectIds(bIsReset)
    local list = self._ReDrawSelectIds
    if XTool.IsTableEmpty(list) then
        return
    end

    if bIsReset then
        self._ReDrawSelectIds = nil
    end
    
    return list
end

--- 根据类型从牌库里抽卡
---@param type number
---@param count number
---@param isRandom boolean
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetPoolCardsWithType(type, count, isRandom)
    local poolCards = self._PoolEntities
    local rest = #poolCards
    if rest < count then
        self:Shuffle()
        rest = #poolCards
        count = mathMin(rest, count)
    end

    local list = {}
    for _, card in pairs(poolCards) do
        if card:GetCardType() == type then
            list[#list + 1] = card
        end
        if not isRandom and #list == count then
            return list
        end
    end
    return self:RandomCards(list, count)
end

--- 根据品质从牌库里抽卡
---@param quality number
---@param count number
---@param isRandom boolean
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetPoolCardsWithQuality(quality, count, isRandom)
    local poolCards = self._PoolEntities
    local rest = #poolCards
    if rest < count then
        self:Shuffle()
        rest = #poolCards
        count = mathMin(rest, count)
    end

    local list = {}
    for _, card in pairs(poolCards) do
        if card:GetCardQuality() == quality then
            list[#list + 1] = card
        end
        if not isRandom and #list == count then
            return list
        end
    end
    return self:RandomCards(list, count)
end

--- 根据卡牌Id从牌库里抽卡
---@param targetIds number[]
---@param count number
---@param isRandom boolean
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetPoolCardsWithTargets(targetIds, count, isRandom)
    if XTool.IsTableEmpty(targetIds) then
        return
    end
    local dict = {}
    for _, cardId in pairs(targetIds) do
        self:RecordCount(dict, cardId)
    end
    local poolCards = self._PoolEntities
    local list = {}
    for _, card in pairs(poolCards) do
        local cardId = card:GetCardId()
        local need = dict[cardId]
        if need and need > 0 then
            list[#list + 1] = card
            need = need - 1
            dict[cardId] = need
        end
    end
    
    if #list <= count then
        return list
    end
    return isRandom and self:RandomCards(list, count) or tableRange(list, 1, count)
end

--- 按顺序冲牌库里抽
---@param count number
---@param isRandom boolean
---@return XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:GetPoolCardsWithOrder(count, isRandom)
    local poolCards = self._PoolEntities
    local rest = #poolCards
    if rest < count then
        self:Shuffle()
        rest = #poolCards
        count = mathMin(rest, count)
    end
    if isRandom then
        return self:RandomCards(poolCards, count)
    end

    return tableRange(poolCards, 1, count)
end

function XSkyGardenCafeRound:IsSelectReDrawCard()
    for _, value in pairs(self._ReDrawSelectIndex) do
        if value then
            return true
        end
    end
    return false
end

function XSkyGardenCafeRound:GetRoundState()
    return self._RoundState
end

function XSkyGardenCafeRound:IsRoundReStart()
    return self._RoundState == RoundState.RoundReStart
end

function XSkyGardenCafeRound:GetNextDealIndex()
    return self._NextDealIndex
end

function XSkyGardenCafeRound:GetDeckId()
    return 0
end

--- 是否为剧情的回合控制器
---@return boolean
--------------------------
function XSkyGardenCafeRound:IsStory()
    return false
end

--endregion


--region Other

function XSkyGardenCafeRound:RecordCount(dict, key)
    local cnt = dict[key] or 0
    cnt = cnt + 1
    dict[key] = cnt
end

function XSkyGardenCafeRound:CloneRecord(dict)
    local temp = {}
    for card, cnt in pairs(dict) do
        temp[card] = cnt
    end
    return temp
end

function XSkyGardenCafeRound:GetReviewChangeNums()
    return self._ReviewChangeNums
end

--- 计算插入手牌的下标
---@param dict table<XSkyGardenCafeCardEntity,number>
---@return number[]
function XSkyGardenCafeRound:CalcDeckInsertIndexList(dict)
    if XTool.IsTableEmpty(dict) then
        return {}
    end
    local list = {}
    local cards = self._DeckEntities
    tableSort(cards, self._SortCardFunc)
    for i, card in pairs(cards) do
        local cnt = dict[card] or 0
        if cnt > 0 then
            list[#list + 1] = i - 1
            cnt = cnt - 1
            dict[card] = cnt
        end
    end
    return list
end

function XSkyGardenCafeRound:OpenBroadcastFirst()
    XLuaUiManager.SetMask(true)
    XScheduleManager.ScheduleOnce(function()
        XMVCA.XBigWorldUI:Open("UiSkyGardenCafePopupBroadcastFirst", self._StageId)
        XLuaUiManager.SetMask(false)
    end, 900)
end

function XSkyGardenCafeRound:StartTimer()
    self:StopTimer()
    if not self._TipTime then
        self._TipTime = tonumber(self._Model:GetConfig("LongTermInactivity"))
    end
    XMVCA.XSkyGardenCafe:SetLastWaitTime(XTime.GetServerNowTimestamp())
    self._ForeverTimer = XScheduleManager.ScheduleForever(function()
        local time = XTime.GetServerNowTimestamp()
        if time - XMVCA.XSkyGardenCafe:GetLastWaitTime() >= self._TipTime then
            self._OwnControl:GetMainControl():ChangeGamePetState(XMVCA.XSkyGardenCafe.GamePetState.LongTimeWait)
        end
    end, 500)
end

function XSkyGardenCafeRound:StopTimer()
    if not self._ForeverTimer then
        return
    end
    XScheduleManager.UnSchedule(self._ForeverTimer)
    self._ForeverTimer = nil
end

function XSkyGardenCafeRound:DebugDeckToDeal(cardId)
    if not IsDebugBuild then
        return
    end
    if not self._DebugDict then
        self._DebugDict = {}
    end
    local round = self._Model:GetBattleInfo():GetRound()
    local info = self._DebugDict[round]
    if not info then
        info = {}
        self._DebugDict[round] = info
    end
    info[#info + 1] = cardId
end

function XSkyGardenCafeRound:DebugExitGame()
    if not IsDebugBuild then
        return
    end
    self._DebugDict = nil
end

function XSkyGardenCafeRound:DebugRoundReStart()
    if not IsDebugBuild then
        return
    end
    if not self._DebugDict then
        return
    end
    local round = self._Model:GetBattleInfo():GetRound()
    self._DebugDict[round] = {}
end

function XSkyGardenCafeRound:DebugPrintInfo()
    if not IsDebugBuild then
        return
    end
    if not self._DebugDict then
        return
    end
    local battleInfo = self._Model:GetBattleInfo()
    local log = {
        "【Debug】回合数据:", 
        string.format("手牌上限(%s), 座位上限(%s)", 
                battleInfo:GetDeckLimit(self._Model:GetMaxDeckCount()), battleInfo:GetDealLimit()), 
        "操作流程:" }
    for round, info in pairs(self._DebugDict) do
        log[#log + 1] = string.format("第%s回合出牌：[%s]", round, table.concat(info, ", "))
    end
    XLog.Warning(table.concat(log, "\n"))
end

function XSkyGardenCafeRound:DebugPoolToDeck(cardId, count)
    if not IsDebugBuild then
        return
    end
    if self:IsStory() then
        XLog.Error("剧情模式无法添加！")
        return
    end
    if not self._DebugAddDeckCards then
        self._DebugAddDeckCards = {}
    end
    local limit = self._Model:GetMaxDeckCount()
    local current = #self._DeckEntities
    count = mathMin(count, limit - current)
    if count <= 0 then
        XLog.Error("手牌已满，无法再添加！")
        return
    end
    local cards = {}
    local factory = self._OwnControl:GetCardFactory()
    for _ = 1, count do
        local card = factory:CreateCard(cardId)
        cards[#cards + 1] = card
        self._DebugAddDeckCards[card] = true
    end
    self:DoDebugPoolToDeck(cards)
    if not XTool.IsTableEmpty(cards) then
        local argDict = { [EffectTriggerId.DrawCard] = { DrawCardType.Round, cards } }
        --触发关卡buff
        self._OwnControl:ApplyStageBuff(self._TriggerDictWhenDrawCard, argDict)
        --触发抽卡buff
        self:DoApplyBuff(true, true, true, self._TriggerDictWhenDrawCard, argDict)
    end
    --预览在手上的buff
    self:DoPreviewBuff(true, true, false, self._TriggerDictWhenInDeck, nil)
end

---@param cards XSkyGardenCafeCardEntity[]
function XSkyGardenCafeRound:DoDebugPoolToDeck(cards)
    if not IsDebugBuild then
        return
    end
    local count = cards and #cards or 0
    if count <= 0 then
        return
    end
    local dict = {}
    for _, card in pairs(cards) do
        --放进手牌
        self:InsertDeck(card)
        self:RecordCount(dict, card)
    end
    --插入卡下标
    local indexList = self:CalcDeckInsertIndexList(dict)
    self._OwnControl:Pool2DeckWithList(indexList)
end

function XSkyGardenCafeRound:IsDebugAddCard(card)
    if not IsDebugBuild or XTool.IsTableEmpty(self._DebugAddDeckCards) then
        return false
    end
    return self._DebugAddDeckCards[card]
end

---@param card XSkyGardenCafeCardEntity
function XSkyGardenCafeRound:RemoveDebugAddCard(card)
    if not IsDebugBuild then
        return
    end
    if not self:IsDebugAddCard(card) then
        return
    end
    self._DebugAddDeckCards[card] = nil
end

--endregion



return XSkyGardenCafeRound