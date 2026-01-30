local XUiPokerGuessing2Card = require("XUi/XUiPokerGuessing2/Game/XUiPokerGuessing2Card")
---@type UnityEngine.Vector3
local Vector3 = CS.UnityEngine.Vector3

---@class XUiPokerGuessing2Character : XUiNode
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2Character = XClass(XUiNode, "XUiPokerGuessing2Character")

function XUiPokerGuessing2Character:OnStart(isPlayer)
    ---@type XUiPokerGuessing2Card[]
    self._Cards = {
        self.GridCard1 and XUiPokerGuessing2Card.New(self.GridCard1, self, isPlayer),
        self.GridCard2 and XUiPokerGuessing2Card.New(self.GridCard2, self, isPlayer),
        self.GridCard3 and XUiPokerGuessing2Card.New(self.GridCard3, self, isPlayer),
        self.GridCard4 and XUiPokerGuessing2Card.New(self.GridCard4, self, isPlayer),
        self.GridCard5 and XUiPokerGuessing2Card.New(self.GridCard5, self, isPlayer),
    }
    if self._Data then
        XLog.Warning("[XUiPokerGuessing2Character] data已经赋值了")
    else
        self._Data = false
    end
    self._IsPlayer = isPlayer

    -- 初始化5个放置节点
    self._NodesToPutDown = {
        self.NodeToPutDown1,
        self.NodeToPutDown2,
        self.NodeToPutDown3,
        self.NodeToPutDown4,
        self.NodeToPutDown5,
    }
    -- 禁用每个节点下挂的RawImage脚本
    for i = 1, #self._NodesToPutDown do
        local node = self._NodesToPutDown[i]
        if node then
            -- 禁用节点本身的RawImage组件
            local rawImage = node:GetComponent(typeof(CS.UnityEngine.UI.RawImage))
            if rawImage then
                rawImage.enabled = false
            end
            -- 禁用节点下所有子对象的RawImage组件
            local childCount = node.transform.childCount
            for j = 0, childCount - 1 do
                local child = node.transform:GetChild(j)
                if child then
                    local childRawImage = child:GetComponent(typeof(CS.UnityEngine.UI.RawImage))
                    if childRawImage then
                        childRawImage.enabled = false
                    end
                end
            end
        end
    end

    if self.PanelWin then
        self.PanelWin.gameObject:SetActiveEx(false)
    end
end

function XUiPokerGuessing2Character:SetAllCardPutOnGroup(value)
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        card:SetPutOnGround(value)
    end
end

--对手牌重新排序
function XUiPokerGuessing2Character:ResortCards()
    ---@type XUiPokerGuessing2Card[]
    local cards = {}
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        if not card:IsPutOnGround() then
            table.insert(cards, card)
        end
    end
    table.sort(cards, function(a, b)
        return a:GetOriginalSiblingIndex() < b:GetOriginalSiblingIndex()
    end)
    for i = 1, #cards do
        local card = cards[i]
        card.Transform:SetSiblingIndex(i - 1)
    end
end

function XUiPokerGuessing2Character:RevertCardParentAndPosition(except)
    if except then
        for i = 1, #self._Cards do
            local card = self._Cards[i]
            if card ~= except then
                card:ReverParent()
            end
        end
        for i = 1, #self._Cards do
            local card = self._Cards[i]
            if card ~= except then
                card:ReverSiblingIndex()
            end
        end
    else
        for i = 1, #self._Cards do
            local card = self._Cards[i]
            if not card:IsOnOriginalParent() then
                card:ReverParent()
            end
        end
        local cards = {}
        for i = 1, #self._Cards do
            local card = self._Cards[i]
            table.insert(cards, card)
        end
        table.sort(cards, function(a, b)
            return a:GetOriginalSiblingIndex() < b:GetOriginalSiblingIndex()
        end)
        for i = 1, #cards do
            local card = cards[i]
            card:ReverSiblingIndex()
        end
    end
end

---@param data XUiPokerGuessing2CharacterData
function XUiPokerGuessing2Character:Update(data)
    self._Data = data
    self:RevertCardParentAndPosition()
    if self.GridCard or self.GridCard1 then
        XTool.UpdateDynamicItem(self._Cards, data.Cards, self.GridCard or self.GridCard1, XUiPokerGuessing2Card, self)
    end
    if not data.IsLock then
        if self.PanelNone then
            self.PanelNone.gameObject:SetActiveEx(false)
        end
        self.RImgCharacter.gameObject:SetActiveEx(true)
        self.RImgCharacter:SetRawImage(data.Icon)
        self.TxtName.text = data.Name

        -- 根据回合数获取对应的节点
        local nodeToPutDown = self:GetNodeToPutDownByRound()
        for i = 1, #self._Cards do
            self._Cards[i]:SetParentOnDrag(nodeToPutDown)
        end
        if self._IsPlayer then
            for i = 1, #self._Cards do
                self._Cards[i]:SetIsCanDrag(true)
            end
        else
            for i = 1, #self._Cards do
                self._Cards[i]:SetVisibleCardFace(false)
                self._Cards[i]:SetIsCanDrag(false)
            end
        end
    else
        if self.PanelNone then
            self.PanelNone.gameObject:SetActiveEx(true)
            self.RImgCharacter.gameObject:SetActiveEx(false)
            self.PanelTalk.gameObject:SetActiveEx(false)
            -- 如果是因为前置关卡未通关, 改成 "神秘对手"
            self.TxtName.text = XUiHelper.GetText("PokerGuessing2UnknownName")
        end
    end
end

---@param data XUiPokerGuessing2CardData
function XUiPokerGuessing2Character:UpdateAfterChangedCard(data)
    if not XTool.IsTableEmpty(data) then
        for i, v in pairs(self._Cards) do
            if v:GetCardId() == data.Id then
                v:Update(data, nil, true)
                v:TryShowChangedCard(true)
            end
        end
    end 
end

function XUiPokerGuessing2Character:ShowChangeCardAnimOnly(data)
    if not XTool.IsTableEmpty(data) then
        for i, v in pairs(self._Cards) do
            if v:GetCardId() == data.Id then
                v:ShowChangeCardAnimOnly()
            end
        end
    end
end

function XUiPokerGuessing2Character:UpdateTimeForLockedStage()
    -- 如果是因为时间导致的,改成倒计时
    if self._Data.IsLock4Time then
        local timerId = self._Data.TimeId
        if timerId and timerId > 0 then
            if XFunctionManager.CheckInTimeByTimeId(timerId) then
                XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_MAIN_ENEMY)
            else
                local endTime = XFunctionManager.GetStartTimeByTimeId(timerId)
                local current = XTime.GetServerNowTimestamp()
                local remainTime = endTime - current
                if remainTime > 0 then
                    local timeStr = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.ACTIVITY)
                    self.TxtName.text = XUiHelper.GetText("PokerGuessing2CountDown", timeStr)
                end
            end
        end
    end
end

function XUiPokerGuessing2Character:Speak(text, isEmoji)
    self.TxtTalk.gameObject:SetActiveEx(not isEmoji)

    if self.RImgEmoji then
        self.RImgEmoji.gameObject:SetActiveEx(isEmoji)
    end
    
    if isEmoji then
        local url = text

        if not string.IsNilOrEmpty(url) then
            self.PanelTalk.gameObject:SetActiveEx(true)

            if self.RImgEmoji then
                self.RImgEmoji:SetRawImage(url)
            end
        else
            self.PanelTalk.gameObject:SetActiveEx(false)
        end
    else
        if text and text ~= "" then
            self.PanelTalk.gameObject:SetActiveEx(true)
            self.TxtTalk.text = text
        else
            self.PanelTalk.gameObject:SetActiveEx(false)
        end
    end
    
end

function XUiPokerGuessing2Character:PlayAnimationCardToPutDownRandom(duration)
    if not self._Data then
        return
    end
    local cardIndex = math.random(1, #self._Data.Cards)
    if not self._Cards[cardIndex] then
        cardIndex = 1
    end
    self:PlayAnimationCardToPutDown(cardIndex, duration)
end

function XUiPokerGuessing2Character:PlayAnimationCardToPutDown(cardIndex, duration)
    local card = self._Cards[cardIndex]
    if not card then
        XLog.Warning("[XUiPokerGuessing2Character] card is nil")
        return
    end
    if card then
        card:PlayAnimationCardToPutDown(duration)
        return card
    end
end

-- 揭开盖上的卡
function XUiPokerGuessing2Character:RevealCoveredCard(cardData)
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        if card:IsPutOnGround() then
            card:Update(cardData)
            -- 播放先开牌动画，动画结束后克隆卡牌
            card:PlayAnimationRevealTheCard(function()
                self:CloneCardOnCurrentNode()
            end)
            return
        end
    end
end

function XUiPokerGuessing2Character:SetTheRevealCardWin()
    if self.PanelWin then
        self.PanelWin.gameObject:SetActiveEx(true)
    end
end

function XUiPokerGuessing2Character:HideCardWin()
    if self.PanelWin then
        self.PanelWin.gameObject:SetActiveEx(false)
    end
end

function XUiPokerGuessing2Character:Reset()
    -- 停止所有卡牌的 ShowCard 动画
    self:StopAllCardsShowCardAnimation()
    
    self:SetAllCardPutOnGroup(false)
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        card:Reset()
    end
    self:HideCardWin()
end

-- 重置克隆卡牌的特效值
function XUiPokerGuessing2Character:ResetClonedCardDissolutionEffect(clonedGameObject)
    if not clonedGameObject then
        return
    end
    
    -- 查找并让 animation/ChangeCard 的 PlayableDirector 跳到最后一帧并停止
    local animRoot = clonedGameObject.transform:Find("Animation")
    if animRoot then
        local changeCardAnim = animRoot:Find("ChangeCard")
        if changeCardAnim then
            local playableDirector = changeCardAnim:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
            if playableDirector then
                -- 跳到最后一帧并停止
                playableDirector.time = playableDirector.duration
                playableDirector:Evaluate()
                playableDirector:Stop()
            end
        end
    end
end

-- 使所有牌背面向上
function XUiPokerGuessing2Character:CoverAllTheCards()
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        card:SetVisibleCardFace(false)
        card:SetVisibleCardBack(true)
    end
end

-- 根据回合数获取对应的放置节点
function XUiPokerGuessing2Character:GetNodeToPutDownByRound()
    local round = self._Control:GetRound() or 1
    
    -- 回合数从1开始，超过5就使用最后一个
    local index = math.min(round, 5)
    local node = self._NodesToPutDown[index]
    
    -- 如果节点不存在，使用第一个或最后一个可用的节点
    if not node then
        for i = 1, #self._NodesToPutDown do
            if self._NodesToPutDown[i] then
                node = self._NodesToPutDown[i]
                break
            end
        end
    end
    
    return node or self.NodeToPutDown
end

-- 获取已放在地上的卡牌
function XUiPokerGuessing2Character:GetCardOnGround()
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        if card:IsPutOnGround() then
            return card
        end
    end
    return nil
end

-- 克隆当前放在地上的卡牌到当前节点
function XUiPokerGuessing2Character:CloneCardOnCurrentNode()
    -- 找到已经放在地上的卡牌
    local cardOnGround = self:GetCardOnGround()
    
    if not cardOnGround then
        return nil
    end
    
    -- 使用卡牌的父节点
    local parentNode = cardOnGround.Transform.parent
    if not parentNode then
        return nil
    end

    -- 克隆卡牌的GameObject
    local clonedGameObject = CS.UnityEngine.Object.Instantiate(cardOnGround.GameObject, parentNode)
    if clonedGameObject then
        -- 设置克隆对象的位置和旋转
        local clonedTransform = clonedGameObject.transform
        clonedTransform.localPosition = Vector3.zero
        clonedTransform.localRotation = CS.UnityEngine.Quaternion.identity
        
        -- 重置克隆体的特效值
        self:ResetClonedCardDissolutionEffect(clonedGameObject)
    end
    
    return clonedGameObject
end

-- 停止所有卡牌的 ShowCard 动画
function XUiPokerGuessing2Character:StopAllCardsShowCardAnimation()
    -- 停止所有原始卡牌的 ShowCard 动画并隐藏 SuccessEffect 和 PutDownEffect
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        if card then
            card:StopAnimation("ShowCard")
            -- 隐藏 SuccessEffect 和 PutDownEffect
            card:HideEffectSuccess()
            card:HideEffectPutDown()
        end
    end
    
    -- 停止所有克隆卡牌的 ShowCard 动画并隐藏 SuccessEffect 和 PutDownEffect
    for i = 1, #self._NodesToPutDown do
        local node = self._NodesToPutDown[i]
        if node then
            local childCount = node.transform.childCount
            for j = 0, childCount - 1 do
                local child = node.transform:GetChild(j)
                if child then
                    -- 停止 ShowCard 动画
                    local animRoot = child:Find("Animation")
                    if not XTool.UObjIsNil(animRoot) then
                        local animTrans = animRoot:Find("ShowCard")
                        if not XTool.UObjIsNil(animTrans) then
                            animTrans:StopTimelineAnimation()
                        end
                    end
                    
                    -- 隐藏 SuccessEffect
                    local successEffect = XUiHelper.TryGetComponent(child, "SuccessEffect", "RectTransform")
                    if successEffect then
                        successEffect.gameObject:SetActiveEx(false)
                    end
                    
                    -- 隐藏 PutDownEffect
                    local putDownEffect = XUiHelper.TryGetComponent(child, "PutDownEffect", "RectTransform")
                    if putDownEffect then
                        putDownEffect.gameObject:SetActiveEx(false)
                    end
                end
            end
        end
    end
end

-- 清理所有节点下的克隆卡牌
function XUiPokerGuessing2Character:ClearClonedCards()
    -- 收集所有原始卡牌的GameObject，用于判断是否是克隆对象
    local originalCardGameObjects = {}
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        if card and card.GameObject then
            originalCardGameObjects[card.GameObject] = true
        end
    end
    
    -- 遍历所有节点，清理克隆的卡牌
    for i = 1, #self._NodesToPutDown do
        local node = self._NodesToPutDown[i]
        if node then
            local childCount = node.transform.childCount
            -- 从后往前遍历，避免删除时索引变化的问题
            for j = childCount - 1, 0, -1 do
                local child = node.transform:GetChild(j)
                if child then
                    local childGameObject = child.gameObject
                    -- 如果不是原始卡牌的GameObject，则是克隆对象，需要销毁
                    if not originalCardGameObjects[childGameObject] then
                        CS.UnityEngine.Object.Destroy(childGameObject)
                    end
                end
            end
        end
    end
end

function XUiPokerGuessing2Character:HideAllCardsEffect()
    for i = 1, #self._Cards do
        local card = self._Cards[i]
        card:HideEffectSuccess()
        card:HideEffectPutDown()
    end
end

return XUiPokerGuessing2Character