local XSkyGardenCafeConfig = require("XModule/XSkyGardenCafe/XSkyGardenCafeConfig")

local XSGCafeStage
local XSGCafeDeck
local XSGCafeBattle

local pairs = pairs

---@class XSkyGardenCafeModel : XSkyGardenCafeConfig
---@field _StageInfo table<number, XSGCafeStage>
---@field _CardDecks table<number, XSGCafeDeck>
---@field _OwnCards XSGCafeDeck
---@field _BattleInfo XSGCafeBattle
local XSkyGardenCafeModel = XClass(XSkyGardenCafeConfig, "XSkyGardenCafeModel")
function XSkyGardenCafeModel:OnInit()
    XSkyGardenCafeConfig.OnInit(self)
    -- 活动数据
    self._ActivityId = 0
    self._NewCardMark = false
    self:Reset()
end

function XSkyGardenCafeModel:ClearPrivate()
    XSkyGardenCafeConfig.ClearPrivate(self)
    self._Cookies = false
end

function XSkyGardenCafeModel:ResetAll()
    XSkyGardenCafeConfig.ResetAll(self)
    self:Reset()
end

function XSkyGardenCafeModel:Reset()
    --关卡数据
    self._StageInfo = {}
    self._TotalChallengeStar = false
    self._EndlessStageId = false

    --卡组&卡牌
    self._CardDecks = {}
    self._SelectDeckId = 1
    self._OwnCards = false

    --对局信息
    self._BattleInfo = false
    
    self._LeftPatrol = nil
    self._LeftPosition = nil
    
    --缓存Key
    self._Cookies = false
    
    self._FightData = nil
end

function XSkyGardenCafeModel:SetActivityId(activityId)
    self._ActivityId = activityId
end

function XSkyGardenCafeModel:IsOpen()
    if not self._ActivityId or self._ActivityId <= 0 then
        return false
    end
    local timeId = self:GetActivityTimeId(self._ActivityId)
    if timeId and timeId > 0 then
        if not XFunctionManager.CheckInTimeByTimeId(timeId, false) then
            return false
        end
    end
    
    return true
end

function XSkyGardenCafeModel:GetActivityId()
    return self._ActivityId
end

function XSkyGardenCafeModel:GetActivityName()
    local t = self:GetActivityTemplate(self._ActivityId)
    return t and t.Name or ""
end

function XSkyGardenCafeModel:GetStoryStageIds()
    local storyChapterId = self:GetStoryChapterId(self._ActivityId)
    return self:GetChapterStageIds(storyChapterId)
end

function XSkyGardenCafeModel:GetChallengeStageIds()
    local challengeChapterId = self:GetChallengeChapterId(self._ActivityId)
    return self:GetChapterStageIds(challengeChapterId)
end

function XSkyGardenCafeModel:GetTotalChallengeStar()
    if self._TotalChallengeStar then
        return self._TotalChallengeStar
    end
    local stageIds = self:GetChallengeStageIds()
    local star = 0
    for _, stageId in pairs(stageIds) do
        local target = self:GetStageTarget(stageId)
        local count = target and #target or 0
        star = star + count
    end
    self._TotalChallengeStar = star
    
    return star
end

---@return XSGCafeStage
function XSkyGardenCafeModel:GetStageInfo(stageId)
    local info = self._StageInfo[stageId]
    if not info then
        if not XSGCafeStage then
            XSGCafeStage = require("XModule/XSkyGardenCafe/Data/XSGCafeStage")
        end
        info = XSGCafeStage.New(stageId)
        self._StageInfo[stageId] = info
    end
    return info
end

function XSkyGardenCafeModel:InitStageInfo(stageList)
    if not stageList then
        return
    end
    for _, stageInfo in pairs(stageList) do
        self:UpdateStageInfo(stageInfo)
    end
end

function XSkyGardenCafeModel:UpdateStageInfo(stageInfo)
    if not stageInfo then
        return
    end
    local stageId = stageInfo.StageId
    if not stageId or stageId <= 0 then
        return
    end
    local info = self:GetStageInfo(stageId)
    info:UpdateData(stageInfo)
end

function XSkyGardenCafeModel:GetEndlessStageId()
    if self._EndlessStageId then
        return self._EndlessStageId
    end
    local stageIds = self:GetChallengeStageIds()
    for _, stageId in pairs(stageIds) do
        if self:IsEndlessChallengeStage(stageId) then
            self._EndlessStageId = stageId
            break
        end
    end
    self._EndlessStageId = -1
    
    return self._EndlessStageId
end

function XSkyGardenCafeModel:GetStageListProgress(stageIds)
    if XTool.IsTableEmpty(stageIds) then
        return 0, 0
    end
    local count, total = 0, 0
    for _, stageId in pairs(stageIds) do
        local target = self:GetStageTarget(stageId)
        total = total + (target and #target or 0)
        local info = self:GetStageInfo(stageId)
        count = count + info:GetStar()
    end
    return count, total
end

--- 获取卡组信息
---@param deckId number 卡组Id  
---@return XSGCafeDeck
--------------------------
function XSkyGardenCafeModel:GetCardDeck(deckId)
    local deck = self._CardDecks[deckId]
    if deck then
        return deck
    end

    if not XSGCafeDeck then
        XSGCafeDeck = require("XModule/XSkyGardenCafe/Data/XSGCafeDeck")
    end
    deck = XSGCafeDeck.New(deckId, true)
    self._CardDecks[deckId] = deck
    
    return deck
end

function XSkyGardenCafeModel:InitCardDeckGroup(cardGroupDict)
    local list = XMVCA.XSkyGardenCafe.DeckIds
    for _, deckId in pairs(list) do
        local deck = self:GetCardDeck(deckId)
        deck:Clear()
    end
    --是否采用策划配置的编组
    local initDict = {}
    
    if not XTool.IsTableEmpty(cardGroupDict) then
        for deckId, cardList in pairs(cardGroupDict) do
            local deck = self:GetCardDeck(deckId)
            --当前编组不需要采用策划配置
            initDict[deckId] = true
            
            for _, cardId in pairs(cardList) do
                deck:Insert(cardId)
            end
            deck:Sync()
        end
    end
    self:InitCardDeckByPreset(initDict)
end

function XSkyGardenCafeModel:InitCardDeckByPreset(initDict)
    local list = XMVCA.XSkyGardenCafe.DeckIds
    for _, deckId in pairs(list) do
        if initDict and not initDict[deckId] then
            local deck = self:GetCardDeck(deckId)
            local ids = self:GetPresetCustomerIds(deckId)
            for _, cardId in pairs(ids) do
                deck:Insert(cardId)
            end
            deck:Sync()
        end
    end
end

--- 获取已有牌组
---@return XSGCafeDeck
--------------------------
function XSkyGardenCafeModel:GetOwnCardDeck()
    if self._OwnCards then
        return self._OwnCards
    end
    if not XSGCafeDeck then
        XSGCafeDeck = require("XModule/XSkyGardenCafe/Data/XSGCafeDeck")
    end
    self._OwnCards = XSGCafeDeck.New(-1, false)
    
    return self._OwnCards
end

function XSkyGardenCafeModel:UpdateOwnCardDeck(cardDict)
    if not cardDict then
        return
    end
    local deck = self:GetOwnCardDeck()
    deck:UpdateCards(cardDict)
end

function XSkyGardenCafeModel:CheckCardUnlock(cardId)
    local deck = self:GetOwnCardDeck()
    local card = deck:GetOrAddCard(cardId)
    return card:IsUnlock()
end

function XSkyGardenCafeModel:GetSelectDeckId()
    return self._SelectDeckId
end

function XSkyGardenCafeModel:SetSelectDeckId(id)
    self._SelectDeckId = id
end

function XSkyGardenCafeModel:SetFightData(stageId, deckId)
    if not self._FightData then
        self._FightData = {
            StageId = 0,
            DeckId = 0
        }
    end
    self._FightData.StageId = stageId
    self._FightData.DeckId = deckId or 0
end

function XSkyGardenCafeModel:GetFightData()
    return self._FightData
end

function XSkyGardenCafeModel:UpdateBattle(battleInfo)
    if not battleInfo then
        return
    end
    local stageId = battleInfo.StageId
    if not stageId or stageId <= 0 then
        return
    end
    local info = self:GetBattleInfo()
    info:SetDeckCount(self:GetMaxCustomer(stageId))
    info:UpdateData(battleInfo)
end

---@return XSGCafeBattle
function XSkyGardenCafeModel:GetBattleInfo()
    if not self._BattleInfo then
        if not XSGCafeBattle then
            XSGCafeBattle = require("XModule/XSkyGardenCafe/Data/XSGCafeBattle")
        end
        self._BattleInfo = XSGCafeBattle.New()
    end
    return self._BattleInfo 
end

function XSkyGardenCafeModel:RandomPosId()
    local allIds = self:GetAllPositionIds()
    local total = #allIds
    local left = self._LeftPosition or total
    if left <= 0 then
        XLog.Error("点位不够随机，将会导致NPC重叠")
        return allIds[1]
    end
    math.randomseed(os.time())
    local index = math.random(1, left)
    local id = allIds[index]
    --随机之后，跟当前最后一个进行交换
    allIds[index], allIds[left] = allIds[left], allIds[index]
    left = left - 1
    self._LeftPosition = left
    
    return id
end

function XSkyGardenCafeModel:RandomRouteId()
    local allIds = self:GetAllPatrolIds()
    local total = #allIds
    local left = self._LeftPatrol or total
    if left <= 0 then
        XLog.Error("点位不够随机，将会导致NPC重叠")
        return allIds[1]
    end
    math.randomseed(os.time())
    local index = math.random(1, left)
    local id = allIds[index]
    --随机之后，跟当前最后一个进行交换
    allIds[index], allIds[left] = allIds[left], allIds[index]
    left = left - 1
    self._LeftPatrol = left

    return id
end

function XSkyGardenCafeModel:ClearNpcRandomPoint()
    self._LeftPosition = nil
    self._LeftPatrol = nil
end

function XSkyGardenCafeModel:GetCookies(key)
    if self._Cookies and self._Cookies[key] then
        return self._Cookies[key]
    end
    local finalKey = string.format("SKY_GARDEN_CAFE_%s_%s_%s", self._ActivityId, XPlayer.Id, key)
    if not self._Cookies then
        self._Cookies = {}
    end
    self._Cookies[key] = finalKey
    
    return finalKey
end

function XSkyGardenCafeModel:HasNewCard()
    for cardId, _ in pairs(self._NewCardMark) do
        if self:CheckCardNewMark(cardId) then
            return true
        end
    end
    return false
end

function XSkyGardenCafeModel:IsNewCard(cardId)
    return self._NewCardMark[cardId]
end

function XSkyGardenCafeModel:CheckCardNewMark(cardId)
    local deck = self:GetOwnCardDeck()
    local count = deck:GetCardCount(cardId)
    local recordCount = self._NewCardMark[cardId]
    return recordCount ~= count
end

function XSkyGardenCafeModel:MarkNewCard(cardId)
    local deck = self:GetOwnCardDeck()
    local count = deck:GetCardCount(cardId)
    self._NewCardMark[cardId] = count
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_NEW_CARD_UNLOCK)
end

function XSkyGardenCafeModel:InitNewMark(cardIdList)
    if XTool.IsTableEmpty(cardIdList) then
        return
    end
    --已经初始化过
    if self._NewCardMark then
        return
    end
    local key = self:GetCookies("NEW_CARD_MARK")
    local localData = XSaveTool.GetData(key)
    local dict
    if localData then
        dict = localData
    else
        dict = {}
        for _, cardId in pairs(cardIdList) do
            dict[cardId] = self:GetCustomerDefaultNum(cardId)
        end
    end
    self._NewCardMark = dict
end

function XSkyGardenCafeModel:SaveNewMark()
    local key = self:GetCookies("NEW_CARD_MARK")
    XSaveTool.SaveData(key, self._NewCardMark)
end

function XSkyGardenCafeModel:InitNewStage()
    if self._NewStageMark then
        return
    end
    local key = self:GetCookies("NEW_STAGE_UNLOCK_MARK")
    local data = XSaveTool.GetData(key)
    local dict
    if data then
        dict = data
    else
        dict = {}
    end
    self._NewStageMark = dict
end

function XSkyGardenCafeModel:SaveStageMark()
    local key = self:GetCookies("NEW_STAGE_UNLOCK_MARK")
    XSaveTool.SaveData(key, self._NewStageMark)
end

function XSkyGardenCafeModel:CheckStageNewMark(stageId)
    --已经记录了， 就不判断下面的了
    if self._NewStageMark[stageId] then
        return false
    end
    
    local t = self:GetStageTemplate(stageId)
    local preId = t.PreStage
    --前置未通关
    if preId and preId > 0 then
        local preStageInfo = self:GetStageInfo(preId)
        if not preStageInfo:IsPassed() then
            return false
        end
    end
    --条件未过
    local condition = t.Condition
    if condition and condition > 0 then
        if not XMVCA.XBigWorldService:CheckCondition(condition) then
            return false
        end
    end
    return true
end

function XSkyGardenCafeModel:MarkNewStage(stageId)
    if not self._NewStageMark then
        self._NewStageMark = {}
    end
    local v = self._NewStageMark[stageId]
    if v then
        return
    end
    self._NewStageMark[stageId] = true
    self:SaveStageMark()
end

return XSkyGardenCafeModel