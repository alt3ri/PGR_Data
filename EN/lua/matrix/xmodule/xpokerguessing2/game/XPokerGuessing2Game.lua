local XPokerGuessing2Card = require("XModule/XPokerGuessing2/Game/XPokerGuessing2Card")

---@class XPokerGuessing2Game
local XPokerGuessing2Game = XClass(nil, "XPokerGuessing2Game")

function XPokerGuessing2Game:Ctor()
    self._ScorePlayer = 0
    self._ScoreEnemy = 0
    ---@type XPokerGuessing2Card
    self._PlayerCard = XPokerGuessing2Card.New()

    ---@type XPokerGuessing2Card
    self._EnemyCard = XPokerGuessing2Card.New()

    ---@type XPokerGuessing2Card[]
    self._EnemyCards = {}

    ---@type XPokerGuessing2Card[]
    self._PlayerCards = {}

    ---@type XPokerGuessing2Card
    self._TipsCard = XPokerGuessing2Card.New()

    self._TipsAmount = 0
    self._MaxTipsAmount = 0

    self._Uid = 0

    self._IsOver = false

    self._Round = 1
end

function XPokerGuessing2Game:GetScore()
    return self._ScorePlayer, self._ScoreEnemy
end

function XPokerGuessing2Game:GetPlayerCard()
    return self._PlayerCard
end

function XPokerGuessing2Game:GetPlayerCards()
    return self._PlayerCards
end

function XPokerGuessing2Game:GetEnemyCard()
    return self._EnemyCard
end

function XPokerGuessing2Game:GetEnemyCards()
    return self._EnemyCards
end

function XPokerGuessing2Game:SetEnemyCardAndRemoveFromList(id)
    if self._EnemyCard then
        self._EnemyCard:SetSelected(false)
    end
    for i = 1, #self._EnemyCards do
        if self._EnemyCards[i]:GetId() == id then
            self._EnemyCard = self._EnemyCards[i]
            self._EnemyCard:SetSelected(true)
            table.remove(self._EnemyCards, i)
            return i
        end
    end
end

function XPokerGuessing2Game:SetEnemyCard(uid)
    if self._EnemyCard then
        self._EnemyCard:SetSelected(false)
    end
    for i = 1, #self._EnemyCards do
        if self._EnemyCards[i]:GetUid() == uid then
            self._EnemyCard = self._EnemyCards[i]
            self._EnemyCard:SetSelected(true)
            return
        end
    end
end

function XPokerGuessing2Game:GetTipsAmount()
    return self._TipsAmount
end

function XPokerGuessing2Game:GetTipsCard()
    return self._TipsCard
end

function XPokerGuessing2Game:GetMaxTipsAmount()
    return self._MaxTipsAmount
end

--- 获取局内修改自己手牌的最大次数
function XPokerGuessing2Game:GetMaxChangePlayerCardCount()
    return self._MaxChangePlayerCardCount
end

--- 获取局内修改敌人手牌的最大次数
function XPokerGuessing2Game:GetMaxChangeRobotCardCount()
    return self._MaxChangeRobotCardCount
end

--- 获取局内修改自己手牌的剩余次数
function XPokerGuessing2Game:GetChangePlayerCardCount()
    return self._ChangePlayerCardCount
end

--- 获取局内修改敌人手牌的剩余次数
function XPokerGuessing2Game:GetChangeRobotCardCount()
    return self._ChangeRobotCardCount
end

--- 初始化局内修改自己手牌的次数
function XPokerGuessing2Game:InitMaxChangePlayerCardCount(value)
    value = math.max(value, 0)
    self._ChangePlayerCardCount = value
    self._MaxChangePlayerCardCount = value
end

--- 初始化局内修改敌人手牌的次数
function XPokerGuessing2Game:InitMaxChangeRobotCardCount(value)
    value = math.max(value, 0)
    self._ChangeRobotCardCount = value
    self._MaxChangeRobotCardCount = value
end

--- 修正技能改己方牌的次数
function XPokerGuessing2Game:ModifyChangePlayerCardCount(adds)
    self._ChangePlayerCardCount = math.max(self._ChangePlayerCardCount + adds, 0)
end

--- 修正技能改对方牌的次数
function XPokerGuessing2Game:ModifyChangeRobotCardCount(adds)
    self._ChangeRobotCardCount = math.max(self._ChangeRobotCardCount + adds, 0)
end

function XPokerGuessing2Game:SetTipsAmount(value)
    self._TipsAmount = math.max(value, 0)
end

function XPokerGuessing2Game:SetTipsCard(cardId)
    self._TipsCard:Set(cardId)
end

function XPokerGuessing2Game:Reset()
    self._ScorePlayer = 0
    self._ScoreEnemy = 0
    self._PlayerCard:Reset()
    self._EnemyCard:Reset()
    self._EnemyCards = {}
    self._PlayerCards = {}
    self._TipsCard:Reset()
    self._TipsAmount = 0
    self._MaxTipsAmount = 0
    self._IsOver = false
    self._Round = 1
    self._CardGroup = nil -- 缓存服务端下发的牌组数据
    self._PlayerCardsChangedMap = nil -- 玩家改牌的缓存记录 key = 旧Id，value=新Id
    self._EnemyCardsChangedMap = nil -- 对手改牌的缓存记录 key = 旧Id，value=新Id
    self._LatestChangeCardSideCache = nil -- 最新的牌面改动缓存，用于指导对方的对话显示
    self._LastPlayerCardOriginId = nil -- 上回合玩家出牌的原Id，用于指导回合结算后的对话
    self._LastEnemyCardOriginId = nil -- 上回合对方出牌的原Id，用于指导回合结算后的对话
end

function XPokerGuessing2Game:SetPlayerCards(list)
    for i = 1, #list do
        self._PlayerCards[i] = self:NewCard(list[i])
    end
    self:SortCards(self._PlayerCards)

    self._CardGroup = list
    
    table.sort(self._CardGroup, function(a, b) 
        return a < b
    end)
end

function XPokerGuessing2Game:SetPlayerCard(uid)
    if self._PlayerCard then
        self._PlayerCard:SetSelected(false)
    end
    for i = 1, #self._PlayerCards do
        if self._PlayerCards[i]:GetUid() == uid then
            self._PlayerCard = self._PlayerCards[i]
            self._PlayerCard:SetSelected(true)
            return
        end
    end
end

function XPokerGuessing2Game:SetEnemyCards(list)
    for i = 1, #list do
        self._EnemyCards[i] = self:NewCard(list[i])
    end
    self:SortCards(self._EnemyCards)
end

--- 获取服务端下发的牌组Id列表
function XPokerGuessing2Game:GetCardGroup()
    return self._CardGroup
end

-- 服务端发的牌有排序，为了不暴露，需要改成按牌值从小到大排序
function XPokerGuessing2Game:SortCards(cards)
    table.sort(cards, function(a, b)
        return a:GetId() < b:GetId()
    end)
end

function XPokerGuessing2Game:RemoveEnemyCard()
    self._EnemyCard:Reset()
end

function XPokerGuessing2Game:SetEnemyScore(value)
    self._ScoreEnemy = value
end

function XPokerGuessing2Game:SetPlayerScore(value)
    self._ScorePlayer = value
end

function XPokerGuessing2Game:NewCard(id)
    self._Uid = self._Uid + 1
    return XPokerGuessing2Card.New(self._Uid, id)
end

function XPokerGuessing2Game:SetIsOver(value)
    self._IsOver = value
end

function XPokerGuessing2Game:IsOver()
    return self._IsOver
end

function XPokerGuessing2Game:SetRound(value)
    self._Round = value
end

function XPokerGuessing2Game:GetRound()
    return self._Round
end

function XPokerGuessing2Game:RemoveCardFromPlayer(uid)
    if self._PlayerCard:GetUid() == uid then
        self._PlayerCard:Reset()
    end
    for i = 1, #self._PlayerCards do
        if self._PlayerCards[i]:GetUid() == uid then
            table.remove(self._PlayerCards, i)
            return
        end
    end
end

function XPokerGuessing2Game:SetPlayerCardsChangedMap(map)
    self._PlayerCardsChangedMap = map

    if not XTool.IsTableEmpty(map) and not XTool.IsTableEmpty(self._PlayerCards) then
        for originId, changedId in pairs(map) do
            for i, v in pairs(self._PlayerCards) do
                if v:GetId() == originId then
                    v:SetChangedId(changedId)
                end
            end
        end
    end
end

function XPokerGuessing2Game:CheckPlayerCardIsChanged(originCardId)
    if XTool.IsTableEmpty(self._PlayerCardsChangedMap) then
        return false
    end
    
    return XTool.IsNumberValid(self._PlayerCardsChangedMap[originCardId])
end

function XPokerGuessing2Game:SetEnemyCardsChangedMap(map)
    self._EnemyCardsChangedMap = map

    if not XTool.IsTableEmpty(map) and not XTool.IsTableEmpty(self._EnemyCards) then
        for originId, changedId in pairs(map) do
            for i, v in pairs(self._EnemyCards) do
                if v:GetId() == originId then
                    v:SetChangedId(changedId)
                end
            end
        end
    end
end

function XPokerGuessing2Game:CheckEnemyCardIsChanged(originCardId)
    if XTool.IsTableEmpty(self._EnemyCardsChangedMap) then
        return false
    end

    return XTool.IsNumberValid(self._EnemyCardsChangedMap[originCardId])
end

function XPokerGuessing2Game:SetLatestChangeCardSide(PlaySide)
    self._LatestChangeCardSideCache = PlaySide
end

function XPokerGuessing2Game:GetLatestChangeCardSide()
    return self._LatestChangeCardSideCache
end

function XPokerGuessing2Game:SetLastPlayerCardOriginId(originCardId)
    self._LastPlayerCardOriginId = originCardId
end

function XPokerGuessing2Game:GetLastPlayerCardOriginId()
    return self._LastPlayerCardOriginId or 0
end

function XPokerGuessing2Game:SetLastEnemyCardOriginId(originCardId)
    self._LastEnemyCardOriginId = originCardId
end

function XPokerGuessing2Game:GetLastEnemyCardOriginId()
    return self._LastEnemyCardOriginId or 0
end

return XPokerGuessing2Game