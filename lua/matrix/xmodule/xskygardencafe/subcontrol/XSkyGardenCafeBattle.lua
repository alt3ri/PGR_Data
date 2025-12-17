local XSkyGardenCafeChallengeRound = require("XModule/XSkyGardenCafe/Entity/XSkyGardenCafeChallengeRound")
local XSkyGardenCafeStoryRound = require("XModule/XSkyGardenCafe/Entity/XSkyGardenCafeStoryRound")

local XSkyGardenCafeCardFactory = require("XModule/XSkyGardenCafe/Entity/XSkyGardenCafeCardFactory")
local XSGCafeBuffFactory = require("XModule/XSkyGardenCafe/Entity/Effect/XSGCafeBuffFactory")
local XSkyGardenCafeNpcFactory = require("XModule/XSkyGardenCafe/Entity/XSkyGardenCafeNpcFactory")

local CardUpdateEvent = XMVCA.XSkyGardenCafe.CardUpdateEvent
local CardContainer = XMVCA.XSkyGardenCafe.CardContainer
local DlcEventId = XMVCA.XBigWorldService.DlcEventId

---@class XSkyGardenCafeBattle : XEntityControl 战斗控制器
---@field _Model XSkyGardenCafeModel
---@field _MainControl XSkyGardenCafeControl
---@field _RoundEntity XSkyGardenCafeRound
---@field _Game XCafe.XCafeGame
---@field _CardFactory XSkyGardenCafeCardFactory
---@field _BuffFactory XSGCafeBuffFactory
---@field _NextRoundBuff XSGCafeBuff[]
---@field _NextRoundAddBuff XSGCafeBuff[]
---@field _StageBuffEntities XSGCafeBuff[]
---@field _NpcFactory XSkyGardenCafeNpcFactory
local XSkyGardenCafeBattle = XClass(XEntityControl, "XSkyGardenCafeBattle")

---@type XCafe.XCafeParam
local CsCafeParam = CS.XCafe.XCafeParam

function XSkyGardenCafeBattle:OnInit()
    self._Game = false
    self._StageId = 0
    --每个回合重置次数
    self._ResetTimes = 0
    --回合结算中
    self._IsSettling = false
end

function XSkyGardenCafeBattle:OnRelease()
    self._Game = false
    self._StageId = 0
    --每个回合重置次数
    self._ResetTimes = 0
    if self._RoundEntity then
        self:RemoveEntity(self._RoundEntity)
    end
    self._RoundEntity = nil
end

function XSkyGardenCafeBattle:DoEnterFight(stageId, deckId)
    self._StageId = stageId
    local isStory = self:IsStoryStage(stageId)
    local cls = isStory and XSkyGardenCafeStoryRound or XSkyGardenCafeChallengeRound
    local entities = self:GetEntitiesWithType(cls)
    if not XTool.IsTableEmpty(entities) then
        for _, entity in pairs(entities) do
            self._RoundEntity = entity
            self._RoundEntity:ResetData()
            break
        end
    end
    if not self._RoundEntity then
        self._RoundEntity = self:AddEntity(cls)
    end
    self._RoundEntity:DoEnter(stageId, deckId)
end

function XSkyGardenCafeBattle:DoExitFight()
    local stageId = self._StageId
    if self._RoundEntity then
        self._RoundEntity:DoExit(stageId)
    end
    self._RoundEntity = nil
    if self._Game then
        self._Game:ExitGame()
    end
    self._Model:GetBattleInfo():Reset()
    self._Game = false

    self:BeforeExit()

    self._StageId = 0
end

function XSkyGardenCafeBattle:BeforeFight()
    self._CardFactory = self:AddSubControl(XSkyGardenCafeCardFactory)
    self._BuffFactory = self:AddSubControl(XSGCafeBuffFactory)
    self._NpcFactory = self:AddSubControl(XSkyGardenCafeNpcFactory)
    
    self:InitStageBuff()
end

function XSkyGardenCafeBattle:BeforeExit()
    self:ReleaseBuff()

    if self._CardFactory then
        self:RemoveSubControl(self._CardFactory)
    end

    if self._BuffFactory then
        self:RemoveSubControl(self._BuffFactory)
    end

    if self._NpcFactory then
        self:RemoveSubControl(self._NpcFactory)
    end
    self._CardFactory = nil
    self._BuffFactory = nil
    self._NpcFactory = nil
end

function XSkyGardenCafeBattle:InitStageBuff()
    self._NextRoundBuff = {}
    self._NextRoundAddBuff = {}
    local buffListId = self._Model:GetStageBuffListId(self._StageId)
    if not buffListId or buffListId <= 0 then
        return
    end
    local effectIds = self._Model:GetBuffListEffectIds(buffListId)
    if XTool.IsTableEmpty(effectIds) then
        return
    end
    local factory = self:GetBuffFactory()
    self._StageBuffEntities = {}
    for _, effectId in pairs(effectIds) do
        local buff = factory:CreateBuff(effectId, nil)
        self._StageBuffEntities[#self._StageBuffEntities + 1] = buff
    end
end

function XSkyGardenCafeBattle:ApplyStageBuff(triggerDict, triggerArgDict)
    if XTool.IsTableEmpty(self._StageBuffEntities) then
        return
    end

    for _, buff in pairs(self._StageBuffEntities) do
        buff:DoApply(triggerDict, triggerArgDict)
    end
end

function XSkyGardenCafeBattle:ReleaseBuff()
    local factory = self:GetBuffFactory()
    if not XTool.IsTableEmpty(self._StageBuffEntities) then
        for _, buff in pairs(self._StageBuffEntities) do
            factory:RemoveEntity(buff)
        end
    end
    self:ReleaseNextBuff()
    self:ReleaseNextAddBuff()
    self._StageBuffEntities = nil
    self._NextRoundAddBuff = nil
    self._NextRoundBuff = nil
    self._NextRoundBuffServerData = nil
end

function XSkyGardenCafeBattle:ReleaseNextBuff()
    local list = self._NextRoundBuff
    if XTool.IsTableEmpty(list) then
        return
    end
    local factory = self:GetBuffFactory()
    for i = #list, 1, -1 do
        local buff = list[i]
        factory:RemoveEntity(buff)
        table.remove(list, i)
    end
end

function XSkyGardenCafeBattle:ReleaseNextAddBuff()
    local list = self._NextRoundAddBuff
    if XTool.IsTableEmpty(list) then
        return
    end
    local factory = self:GetBuffFactory()
    for i = #list, 1, -1 do
        local buff = list[i]
        factory:RemoveEntity(buff)
        table.remove(list, i)
    end
end

function XSkyGardenCafeBattle:AttachStageBuff(buff)
    if not buff then
        return
    end
    self._StageBuffEntities[#self._StageBuffEntities + 1] = buff
end

function XSkyGardenCafeBattle:Play()
    if not self._RoundEntity then
        return
    end
    local cardEntities = self._RoundEntity:GetDealCardEntities()
    if #cardEntities <= 0 then
        XUiManager.TipMsg(self._Model:GetConfig("DealEmptyTip"))
        return
    end
    local deckCardIds = self._RoundEntity:GetDeckCardIds()
    local dealCardIds = self._RoundEntity:GetDealCardIds()
    local reviewChangeNums = self._RoundEntity:GetReviewChangeNums()
    XLuaUiManager.SetMask(true)
    self._IsSettling = true
    --local isSkip = self._MainControl:IsSkipAnimation()
    RunAsyn(function()
        --回合结束
        self._RoundEntity:DoRoundEnd()
        asynWaitSecond(0.5)
        XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_ROUND_NPC_SHOW, true)
        --if not isSkip then
        --    --回合演出结束
        --    local waitTime = self._NpcFactory:PlayRoundEnd()
        --    asynWaitSecond(waitTime / 1000)
        --end
        self._NpcFactory:RemoveNpcWhenRoundEnd(self._RoundEntity:GetDeckCardEntities())
        local round = self:GetBattleInfo():GetRound()
        local targetRound = self._Model:GetStageRounds(self._StageId)
        if round <= targetRound then
            XMVCA.XSkyGardenCafe:DispatchInnerEvent(DlcEventId.EVENT_CAFE_ROUND_NPC_SHOW, false)
            self._RoundEntity:DoRoundBegin()
        end
        self._RoundEntity:DoRequestRoundChange(dealCardIds, deckCardIds, reviewChangeNums)
        XLuaUiManager.SetMask(false)
    end)
end

function XSkyGardenCafeBattle:GiveUp(cb)
    XNetwork.Call("BigWorldCafeGiveUpRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self:DoExitFight()
        if cb then
            cb()
        end
    end)
end

function XSkyGardenCafeBattle:ToServerData()
    local data = self._ServerData
    if not data then
        data = {}
        self._ServerData = data
    end
    local battleInfo = self:GetBattleInfo()
    local roundEntity = self._RoundEntity
    
    data.StageId = self._StageId
    data.Round = battleInfo:GetRound()
    data.SumSales = battleInfo:GetTotalScore()
    data.ActPoint = battleInfo:GetDealLimit()
    data.HandCardPosNum = battleInfo:GetDeckLimit(self._Model:GetMaxDeckCount())
    data.ReviewNum = battleInfo:GetTotalReview()
    data.HandCards = roundEntity:GetDeckCardIds()
    data.CardsWarehouse = roundEntity:GetPoolCardIds()
    data.AbandonCards = battleInfo:GetAbandonCards()
    data.BanCards = battleInfo:GetBanCards()
    data.PriorityCard = battleInfo:GetPrecedeCards()
    data.RetainHandCard = battleInfo:GetStayInHandCards()
    data.UseCardTimes = battleInfo:GetCardUseCountDict()
    data.BuffAdditionDict = battleInfo:GetCardForeverDict()
    data.CardGroupId = roundEntity:GetDeckId()
    data.NextRoundBuffs = self:GetNextRoundBuffsWithServer()
    
    return data
end

function XSkyGardenCafeBattle:GetResetTimes()
    return self._ResetTimes
end

function XSkyGardenCafeBattle:AddResetTimes()
    self._ResetTimes = self._ResetTimes + 1
end

function XSkyGardenCafeBattle:ResetResetTimes()
    self._ResetTimes = 0
end

--- 主控制器
---@return XSkyGardenCafeControl
--------------------------
function XSkyGardenCafeBattle:GetMainControl()
    return self._MainControl
end

function XSkyGardenCafeBattle:GetBarCounterNpcUUID()
    return self._NpcFactory:GetBarCounterNpcUUID()
end

function XSkyGardenCafeBattle:ChangeRoundSettle(value)
    self._IsSettling = value
end

function XSkyGardenCafeBattle:IsNeedReDraw()
    local battleInfo = self:GetBattleInfo()
    if battleInfo:GetRound() > 1 then
        return false
    end
    return self._Model:IsReDrawStage(self._StageId)
end

--- 打开战斗界面
--------------------------
function XSkyGardenCafeBattle:OpenBattleView(deckId)
    local stageId = self._StageId
    local battleInfo = self:GetBattleInfo()
    local isContinue
    ----重新进入关卡
    --if battleInfo:GetStageId() == stageId then
    --    self._RoundEntity:InitBattleInfoWithServer()
    --    isContinue = true
    --else --进入新关卡
        self._RoundEntity:InitBattleInfoWithClint()
        isContinue = false
    --end
    --初始化参数
    CsCafeParam.InitLayoutData(0.1, 150, 0, 0.1, 268, 0, 0.1, 10500, 1.2, 180)
    CsCafeParam.InitDuration(0.5, 1.0, 0.2, 0.5)
    CsCafeParam.InitCardUrl(XMVCA.XBigWorldResource:GetAssetUrl("SkyGardenCafeCardSmall"), 
            XMVCA.XBigWorldResource:GetAssetUrl("SkyGardenCafeCard"))
    --打开战斗界面
    XLuaUiManager.OpenWithCallback("UiSkyGardenCafeGame", function()
        XMVCA.XBigWorldUI:SafeClose("UiBigWorldBlackMaskNormal")
        self._Game = CS.XCafe.XCafeGame.Instance
        --c#回调
        local update = handler(self, self.OnCardUpdate)
        local checker = handler(self, self.CanPlayCard)
        --初始化表现
        self._Game:EnterGame(self._Model:GetMaxDeckCount(), self:GetBattleInfo():GetDealLimit(), 100, update, checker)
        
        self._Model:MarkNewStage(stageId)
        
        XLuaUiManager.SetMask(true)
        XScheduleManager.ScheduleOnce(function()
            self._RoundEntity:StartTimer()
            --回合开始
            self._RoundEntity:DoRoundBegin(isContinue)

            --只有新进入游戏 并且 不是重抽才同步服务器，重抽会在重抽后同步服务器
            if not isContinue and not self:IsNeedReDraw() then
                --同步服务器
                self:RequestEnterGame(deckId)
            end
            XLuaUiManager.SetMask(false)
        end, 1000)
    end, stageId)
end

function XSkyGardenCafeBattle:RequestEnterGame(deckId, func)
    local cardList
    if deckId and deckId > 0 then
        local deck = self._Model:GetCardDeck(deckId)
        cardList = deck:GetCardsPool()
    end
    
    local req = {
        CafeGambling = self:ToServerData(),
        CardGroupId = deckId,
        CardList = cardList,
        --埋点：首回合放弃的牌
        AbandonedCardList = self._RoundEntity:GetReDrawSelectIds(true),
    }
    local handleError = function() self:HandleError() end
    XNetwork.Call("BigWorldCafeNewRoundRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            handleError()
            return
        end
        if deckId and deckId > 0 then
            local deck = self._Model:GetCardDeck(deckId)
            deck:Sync()
        end
        local battleInfo = self:GetBattleInfo()
        battleInfo:SetDeckCount(self._Model:GetMaxCustomer(self._StageId))
        battleInfo:NewBattle(req.CafeGambling)
        self:ResetResetTimes()
        if func then
            func()
        end
    end, nil, handleError)
end

function XSkyGardenCafeBattle:HandleError()
    if self._StageId <= 0 then
        return
    end
    self:DoExitFight()
    XMVCA.XBigWorldUI:SafeClose("UiSkyGardenCafeGame")
end

function XSkyGardenCafeBattle:OnCardUpdate(evt, type, index, card)
    if evt == CardUpdateEvent.Deck2Deal then
        self._RoundEntity:DeckToDeal(type + 1, index + 1)
    end
    self._MainControl:InvokeCardUpdate(evt, type, index, card)
end

function XSkyGardenCafeBattle:CanPlayCard(type, index)
    local tip
    local pass = true
    local restCount = self._RoundEntity:GetRestDealCount()
    if restCount <= 0 then
        XUiManager.TipMsg(self._MainControl:GetDealCountFullText())
        return false
    end
    if type == CardContainer.Deck then
        local battleInfo = self:GetBattleInfo()
        local card = self:GetRoundEntity():GetDeckCardEntities()[index + 1]
        if not card then
            XLog.Error("手牌为空！")
            return false
        end
        local totalScore, totalReview = battleInfo:GetTotalScore(), battleInfo:GetTotalReview()
        local basicScore, basicReview = card:GetTotalCoffee(true), card:GetTotalReview(true)
        if totalScore + basicScore < 0 then
            tip = self._Model:GetResourceNotEnough(true)
            pass = false
        elseif totalReview + basicReview < 0 then
            tip = self._Model:GetResourceNotEnough(false)
            pass = false
        end
        if not pass then
            XUiManager.TipMsg(tip)
            return pass
        end


        local conditions = self._Model:GetCustomerUseCondition(card:GetCardId())
        if not XTool.IsTableEmpty(conditions) then
            local tempTip
            for _, conditionId in pairs(conditions) do
                pass, tempTip = self._MainControl:CheckCondition(conditionId)
                if not pass then
                    tip = tempTip
                    break
                end
            end
        end
    end

    if tip then
        XUiManager.TipMsg(tip)
    end

    return pass
end

function XSkyGardenCafeBattle:Pool2DeckWithCount(count)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    if not count or count <= 0 then
        return
    end
    self._Game:PoolToDeck(count)
end

function XSkyGardenCafeBattle:Pool2DeckWithList(list)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    if XTool.IsTableEmpty(list) then
        return
    end
    self._Game:PoolToDeck(list)
end

function XSkyGardenCafeBattle:Deal2Pool()
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    self._Game:DealToPool()
end

function XSkyGardenCafeBattle:Deck2Pool(list)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    if XTool.IsTableEmpty(list) then
        return
    end
    self._Game:DeckToPool(list)
end

function XSkyGardenCafeBattle:DeckToDealByIndex(deckIndex)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    if deckIndex <= 0 then
        return
    end
    self._Game:DeckToDealByIndex(deckIndex - 1)
end

function XSkyGardenCafeBattle:Resize(state, size)
    if not self._Game then
        return
    end
    if size == 0 then
        return
    end
    
    self._Game:Resize(state, size)
end

function XSkyGardenCafeBattle:PoolToReDraw(count)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    if count <= 0 then
        return
    end
    self._Game:PoolToReDraw(count)
end

function XSkyGardenCafeBattle:ReDrawToDeck(indexList)
    if not self._Game then
        XLog.Error("对局还未初始化!")
        return
    end
    if XTool.IsTableEmpty(indexList) then
        return
    end
    
    self._Game:ReDrawToDeck(indexList)
end

function XSkyGardenCafeBattle:Collapse(containerType)
    if not self._Game then
        return
    end
    self._Game:Collapse(containerType)
end

function XSkyGardenCafeBattle:Expand(containerType)
    if not self._Game then
        return
    end
    self._Game:Expand(containerType)
end

function XSkyGardenCafeBattle:RefreshContainer(containerType)
    if not self._Game then
        return
    end
    self._Game:RefreshContainer(containerType)
end

---@return XSkyGardenCafeRound
function XSkyGardenCafeBattle:GetRoundEntity()
    return self._RoundEntity
end

function XSkyGardenCafeBattle:GetStageId()
    return self._StageId
end

function XSkyGardenCafeBattle:IsInFight()
    return self._StageId ~= 0
end

function XSkyGardenCafeBattle:IsStoryStage()
    return self._Model:IsStoryStage(self._StageId)
end

---@return XSGCafeBattle
function XSkyGardenCafeBattle:GetBattleInfo()
    return self._Model:GetBattleInfo()
end

---@return XSkyGardenCafeCardFactory
function XSkyGardenCafeBattle:GetCardFactory()
    return self._CardFactory
end

---@return XSGCafeBuffFactory
function XSkyGardenCafeBattle:GetBuffFactory()
    return self._BuffFactory
end

---@return XSkyGardenCafeNpcFactory
function XSkyGardenCafeBattle:GetNpcFactory()
    return self._NpcFactory
end

function XSkyGardenCafeBattle:PlayResourceChange(card, coffee, review)
    self._RoundEntity:UpdateDealCardInfo()
    self._NpcFactory:PlayResourceChange(card, coffee, review)
end

function XSkyGardenCafeBattle:AddNextRoundBuff(buffId, card)
    if not buffId or buffId <= 0 then
        return
    end
    local buff = self:GetBuffFactory():CreateBuff(buffId, card)
    buff:SubLeftRound()
    if not self._NextRoundAddBuff then
        self._NextRoundAddBuff = {}
    end
    self._NextRoundAddBuff[#self._NextRoundAddBuff + 1] = buff
end

function XSkyGardenCafeBattle:ApplyNextRoundBuff()
    if XTool.IsTableEmpty(self._NextRoundBuff) then
        return
    end
    for _, buff in pairs(self._NextRoundBuff) do
        buff:DoApplyNoCheck()
    end
end

function XSkyGardenCafeBattle:SyncNextRoundBuff()
    if not XTool.IsTableEmpty(self._NextRoundBuff) then
        local factory = self:GetBuffFactory()
        for _, buff in pairs(self._NextRoundBuff) do
            factory:RemoveEntity(buff)
        end
    end
    
    self._NextRoundBuff = self._NextRoundAddBuff
    self._NextRoundAddBuff = {}
end

function XSkyGardenCafeBattle:SyncNextRoundBuffWithServer()
    local list = self:GetBattleInfo():GetNextRoundBuffs()
    if XTool.IsTableEmpty(list) then
        return
    end
    local factory = self._BuffFactory
    local buffList = self._NextRoundBuff
    for _, data in pairs(list) do
        local buffId = data.BuffId
        local cardId = data.CardId
        if buffId and buffId > 0 then
            local card
            if cardId and cardId > 0 then
                --如果卡不存在，则卡已经被销毁
                card = self._RoundEntity:GetDeckCardEntityWithId(cardId)
                if not card then
                    card = self._CardFactory:CreateCard(cardId)
                end
            end
            local buff = factory:CreateBuff(buffId, card)
            buffList[#buffList + 1] = buff
        end
    end
end

function XSkyGardenCafeBattle:GetNextRoundBuffsWithServer()
    if not self._NextRoundBuffServerData then
        self._NextRoundBuffServerData = {}
    end
    local data = self._NextRoundBuffServerData
    if XTool.IsTableEmpty(self._NextRoundAddBuff) then
        return data
    end
    for _, buff in pairs(self._NextRoundAddBuff) do
        data[#data + 1] = {
            BUffId = buff:GetBuffId(),
            CardId = buff:GetCardId()
        }
    end
    return data
end

function XSkyGardenCafeBattle:AddDeckCount(count)
    if not self._Game then
        return
    end
    local info = self._Model:GetBattleInfo()
    local maxCount = self._Model:GetMaxDeckCount()
    local limit = info:GetDeckLimit(maxCount)
    if limit + count > maxCount then
        XUiManager.TipMsg(self._MainControl:GetDeckNumIsFullText())
    end
    count = math.min(count, maxCount - limit)
    if count == 0 then
        return
    end
    --1.修改手牌上限（数据）
    info:AddDeckCount(count)
    --2.修改手牌上限（表现）
    local free = self._RoundEntity:GetRestDeckCount()
    if free > 0 and not self._IsSettling and not self._RoundEntity:IsRoundReStart() then
        --3.补充空余卡
        local cards = self._RoundEntity:SequenceCards(free)
        self._RoundEntity:DoPoolToDeck(cards)
    end
end

function XSkyGardenCafeBattle:AddDealCount(count)
    if not self._Game then
        return
    end
    local maxCount = self._Model:GetMaxDealCount()
    local battleInfo = self._Model:GetBattleInfo()
    local limit = battleInfo:GetDealLimit()
    if limit + count > maxCount then
        XUiManager.TipMsg(self._MainControl:GetCafeDealNumIsFull())
    end
    local max = math.min(maxCount, limit + count)
    local realCount = max - limit
    if realCount == 0 then
        return
    end
    --1.修改出牌上限（数据）
    battleInfo:AddDealCount(realCount)
    --2.修改手牌上限（表现）
    self:Resize(CardContainer.Deal, realCount)
    
    return realCount
end

function XSkyGardenCafeBattle:DoNpcClicked(uuid)
    if not self._NpcFactory then
        return false
    end
    local npc = self._NpcFactory:GetNpc(uuid)
    if not npc then
        return false
    end
    
    return npc:ShowDialog()
end

return XSkyGardenCafeBattle