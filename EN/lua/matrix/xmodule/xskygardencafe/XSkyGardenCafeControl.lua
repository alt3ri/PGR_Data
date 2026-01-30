---@class XSkyGardenCafeControl : XControl
---@field private _Model XSkyGardenCafeModel
---@field private _Battle XSkyGardenCafeBattle
---@field private _Condition XSkyGardenCafeCondition
---@field private _StateMachine XCafeStateMachine
local XSkyGardenCafeControl = XClass(XControl, "XSkyGardenCafeControl")

local EventId = XMVCA.XBigWorldService.DlcEventId
local XCafeStateMachine

function XSkyGardenCafeControl:OnInit()
    self._HudType2WorldPosition = {}
    self._NeedChangeCamera = true
    self._StageIdCache = 0
    self._Model:InitNewStage()
    XMVCA.XSkyGardenCafe:InitInnerEvent()
    
    self._Model:InitNewMark(self:GetAllShowCustomerIds())
    if not XCafeStateMachine then
        XCafeStateMachine = require("XModule/XSkyGardenCafe/StateMachine/XCafeStateMachine")
    end
end

function XSkyGardenCafeControl:AddAgencyEvent()

    local agency = XMVCA.XSkyGardenCafe
    agency:AddInnerEvent(EventId.EVENT_CAFE_ENTER_FIGHT, self.EnterFight, self)
    agency:AddInnerEvent(EventId.EVENT_CAFE_EXIT_FIGHT, self.ExitFight, self)
    agency:AddInnerEvent(EventId.EVENT_CAFE_SETTLEMENT, self.OnSettlement, self)
end

function XSkyGardenCafeControl:RemoveAgencyEvent()
    local agency = XMVCA.XSkyGardenCafe
    agency:RemoveInnerEvent(EventId.EVENT_CAFE_ENTER_FIGHT, self.EnterFight, self)
    agency:RemoveInnerEvent(EventId.EVENT_CAFE_EXIT_FIGHT, self.ExitFight, self)
    agency:RemoveInnerEvent(EventId.EVENT_CAFE_SETTLEMENT, self.OnSettlement, self)
end

function XSkyGardenCafeControl:OnRelease()
    self._CardUpdateHandler = nil
    self._HudType2WorldPosition = nil
    if self._StateMachine then
        self._StateMachine:Clear()
        self._StateMachine = nil
    end
    XMVCA.XSkyGardenCafe:ClearAllInnerEvent()
end

function XSkyGardenCafeControl:IsStageUnlock(stageId)
    local preStageId = self:GetPreStageId(stageId)
    if not preStageId or preStageId <= 0 then
        return true
    end
    local stageInfo = self:GetStageInfo(preStageId)
    return stageInfo:IsPassed()
end

--- 首个未通关剧情关
---@return number
--------------------------
function XSkyGardenCafeControl:GetFirstNotPassStoryStage()
    local stageIds = self:GetStoryStageIds()
    for _, stageId in pairs(stageIds) do
        local info = self:GetStageInfo(stageId)
        if not info:IsPassed() then
            return stageId
        end
    end
    return nil
end

--- 首个未通挑战关
---@return number
function XSkyGardenCafeControl:GetFirstNotPassChallengeStage()
    local stageIds = self:GetChallengeStageIds()
    for _, stageId in pairs(stageIds) do
        local info = self:GetStageInfo(stageId)
        if not self._Model:IsEndlessChallengeStage(stageId) and not info:IsPassed() then
            return stageId
        end
    end
    return nil
end

function XSkyGardenCafeControl:GetFirstNotPassStageId(stageId)
    if not stageId then
        stageId = self._Model:GetBattleInfo():GetStageId()
    end
    if not stageId or stageId <= 0 then
        return nil
    end
    local t = self._Model:GetStageTemplate(stageId)
    if t.Type == XMVCA.XSkyGardenCafe.StageType.Story then
        return self:GetFirstNotPassStoryStage()
    elseif t.Type == XMVCA.XSkyGardenCafe.StageType.Challenge then
        return self:GetFirstNotPassChallengeStage()
    end
    return nil
end

--- 挑战中的无尽关卡(可能为空)
---@return number
--------------------------
function XSkyGardenCafeControl:GetInChallengeStage()
    local battleInfo = self._Model:GetBattleInfo()
    local stageId = battleInfo:GetStageId()
    if not stageId or stageId < 0 then
        return nil
    end
    if not self._Model:IsEndlessChallengeStage(stageId) then
        return nil
    end
    return stageId
end

--- 挑战关最高分
---@return number
--------------------------
function XSkyGardenCafeControl:GetHighestChallengeScore()
    local stageId = self._Model:GetEndlessStageId()
    if not stageId or stageId < 0 then
        return 0
    end
    local info = self._Model:GetStageInfo(stageId)
    return info:GetScore()
end

function XSkyGardenCafeControl:GetStageReward(stageId)
    return self._Model:GetStageReward(stageId)
end

function XSkyGardenCafeControl:GetStageRounds(stageId)
    return self._Model:GetStageRounds(stageId)
end

function XSkyGardenCafeControl:GetStageRewardIdsByStar(stageId)
    local rewardIds = self:GetStageReward(stageId)
    if XTool.IsTableEmpty(rewardIds) then
        return
    end
    local stageInfo = self._Model:GetStageInfo(stageId)
    local star = stageInfo:GetStar()
    if star <= 0 then
        return
    end
    local list = {}
    for _, rewardId in pairs(rewardIds) do
        list[#list + 1] = rewardId
    end
    return list
end

function XSkyGardenCafeControl:GetStageTarget(stageId)
    return self._Model:GetStageTarget(stageId)
end

function XSkyGardenCafeControl:GetStageName(stageId)
    if not stageId or stageId <= 0 then
        return nil
    end
    local t = self._Model:GetStageTemplate(stageId)
    return t and t.Name or nil
end

function XSkyGardenCafeControl:GetPreStageId(stageId)
    return self._Model:GetPreStageId(stageId)
end

function XSkyGardenCafeControl:IsChallengeOpen()
    return true
end

function XSkyGardenCafeControl:IsHistoryOpen()
    local stageIds = self:GetStoryStageIds()
    for _, stageId in pairs(stageIds) do
        local info = self._Model:GetStageInfo(stageId)
        if info:IsPassed() then
            return true
        end
    end
    return false
end

function XSkyGardenCafeControl:GetChallengeProgress()
    local stageIds = self:GetChallengeStageIds()
    return self._Model:GetStageListProgress(stageIds)
end

function XSkyGardenCafeControl:GetHistoryProgress()
    local stageIds = self:GetHistoryStageIds()
    return self._Model:GetStageListProgress(stageIds)
end

function XSkyGardenCafeControl:GetStoryStageIds()
    return self._Model:GetStoryStageIds()
end

function XSkyGardenCafeControl:GetHistoryStageIds()
    local stageIds = self:GetStoryStageIds()
    local list = {}
    for _, stageId in pairs(stageIds) do
        local info = self._Model:GetStageInfo(stageId)
        if info:IsPassed() then
            list[#list + 1] = stageId
        end
    end
    return list
end

function XSkyGardenCafeControl:GetChallengeStageIds()
    return self._Model:GetChallengeStageIds()
end

---@return XSGCafeStage
function XSkyGardenCafeControl:GetStageInfo(stageId)
    return self._Model:GetStageInfo(stageId)
end

function XSkyGardenCafeControl:IsStoryStage(stageId)
    if stageId then
        return self._Model:IsStoryStage(stageId)
    end
    if self._Battle and self._Battle:IsInFight() then
        stageId = self._Battle:GetStageId()
        return self._Model:IsStoryStage(stageId)
    end
    return false
end

function XSkyGardenCafeControl:IsEndlessChallengeStage(stageId)
    if stageId then
        return self._Model:IsEndlessChallengeStage(stageId)
    end
    if self._Battle and self._Battle:IsInFight() then
        stageId = self._Battle:GetStageId()
        return self._Model:IsEndlessChallengeStage(stageId)
    end
    return false
end

function XSkyGardenCafeControl:IsReviewStage(stageId)
    if stageId then
        return self._Model:IsReviewStage(stageId)
    end
    if self._Battle and self._Battle:IsInFight() then
        stageId = self._Battle:GetStageId()
        return self._Model:IsReviewStage(stageId)
    end
    return false
end

function XSkyGardenCafeControl:GetStageBuffListId(stageId)
    return self._Model:GetStageBuffListId(stageId)
end

function XSkyGardenCafeControl:GetBuffListIcon(buffListId)
    local t = self._Model:GetBuffListTemplate(buffListId)
    return t.Icon
end

function XSkyGardenCafeControl:GetBuffListDesc(buffListId)
    local t = self._Model:GetBuffListTemplate(buffListId)
    return t.Desc
end

function XSkyGardenCafeControl:GetBuffListName(buffListId)
    local t = self._Model:GetBuffListTemplate(buffListId)
    return t.Name
end

function XSkyGardenCafeControl:OpenSettlement(stageId, isSettlement)
    XLuaUiManager.Open("UiSkyGardenCafePopupSettlement", stageId, isSettlement)
end

function XSkyGardenCafeControl:OnSettlement(stageId)
    self:OpenSettlement(stageId, true)
end

function XSkyGardenCafeControl:CheckStageCondition(stageId)
    if not stageId or stageId <= 0 then
        return true
    end
    local t = self._Model:GetStageTemplate(stageId)
    local conditionId = t.Condition
    if not conditionId or conditionId <= 0 then
        return true
    end
    return XMVCA.XBigWorldService:CheckCondition(conditionId)
end

function XSkyGardenCafeControl:IsKickOutCafeStage(stageId)
    if not stageId or stageId <= 0 then
        return false
    end
    local t = self._Model:GetStageTemplate(stageId)
    return t and t.IsKickOutCafe or false
end

--region 卡组&卡牌

--- 卡组信息
---@param deckId number 卡组Id  
---@return XSGCafeDeck
--------------------------
function XSkyGardenCafeControl:GetCardDeck(deckId)
    return self._Model:GetCardDeck(deckId)
end

function XSkyGardenCafeControl:RestoreDeck(deckId)
    if deckId and deckId > 0 then
        local deck = self:GetCardDeck(deckId)
        deck:Restore()
        return
    end

    for _, id in pairs(XMVCA.XSkyGardenCafe.DeckIds) do
        local deck = self:GetCardDeck(id)
        deck:Restore()
    end
end

function XSkyGardenCafeControl:GetSelectDeckId()
    return self._Model:GetSelectDeckId()
end

function XSkyGardenCafeControl:SetSelectDeckId(id)
    return self._Model:SetSelectDeckId(id)
end

function XSkyGardenCafeControl:GetOwnCardDeck()
    return self._Model:GetOwnCardDeck()
end

--- 卡牌信息
---@param cardId number 卡组Id  
---@return XSGCafeCard
--------------------------
function XSkyGardenCafeControl:GetOwnCard(cardId)
    return self:GetOwnCardDeck():GetOrAddCard(cardId)
end

function XSkyGardenCafeControl:CheckCardUnlock(cardId)
    return self._Model:CheckCardUnlock(cardId)
end

function XSkyGardenCafeControl:GetAllShowCustomerIds()
    return self._Model:GetAllShowCustomerIds()
end

function XSkyGardenCafeControl:GetCustomerName(id)
    local t = self._Model:GetCustomerTemplate(id)
    return t and t.Name
end

function XSkyGardenCafeControl:GetCustomerIcon(id)
    local t = self._Model:GetCustomerTemplate(id)
    return t and t.Icon
end

function XSkyGardenCafeControl:GetCustomerSmallIcon(id)
    local t = self._Model:GetCustomerTemplate(id)
    return t and t.SmallIcon
end

function XSkyGardenCafeControl:GetCustomerCoffee(id)
    return self._Model:GetCustomerCoffee(id)
end

function XSkyGardenCafeControl:GetCustomerPriority(id)
    return self._Model:GetCustomerPriority(id)
end

function XSkyGardenCafeControl:GetCustomerQuality(id)
    return self._Model:GetCustomerQuality(id)
end

function XSkyGardenCafeControl:GetCustomerQualityIcon(id)
    local quality = self:GetCustomerQuality(id)
    local key = "CardQuality" .. quality
    return XMVCA.XBigWorldResource:GetAssetUrl(key)
end

function XSkyGardenCafeControl:GetCustomerReview(id)
    return self._Model:GetCustomerReview(id)
end

function XSkyGardenCafeControl:GetCustomerTags(id)
    local t = self._Model:GetCustomerTemplate(id)
    return t and t.Tags
end

function XSkyGardenCafeControl:GetCustomerDetails(id)
    local details = self._Model:GetCustomerDetails(id)
    --该方法适合未进入战斗时使用，此时卡牌未使用，无法获取buff传出来的值，直接不显示
    return XUiHelper.ReplaceTextNewLine(details:gsub(XMVCA.XSkyGardenCafe.Pattern, "0"))
end

function XSkyGardenCafeControl:GetCustomerDesc(id)
    local desc = self._Model:GetCustomerDesc(id)
    return XUiHelper.ReplaceTextNewLine(desc)
end

function XSkyGardenCafeControl:GetCustomerWorldDesc(id)
    local desc = self._Model:GetCustomerWorldDesc(id)
    return XUiHelper.ReplaceTextNewLine(desc)
end

function XSkyGardenCafeControl:GetTagName(tagId)
    local t = self._Model:GetTagTemplate(tagId)
    return t and t.Name
end

function XSkyGardenCafeControl:GetTagDesc(tagId)
    local t = self._Model:GetTagTemplate(tagId)
    return t and t.Desc
end

function XSkyGardenCafeControl:GetCustomerUnlockDesc(id)
    return self._Model:GetCustomerUnlockDesc(id)
end

function XSkyGardenCafeControl:SaveDeckRequest(deckId, cb)
    local deck = self._Model:GetCardDeck(deckId)
    if deck:IsSynced() then
        XUiManager.TipMsg(self:GetSyncDeckSuccessText())
        return
    end
    local req = {
        GroupId = deckId,
        CardList = deck:GetCardsPool()
    }
    XNetwork.Call("BigWorldCafeCardGroupListSaveRequest", req, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        deck:Sync()
        XUiManager.TipMsg(self:GetSyncDeckSuccessText())

        if cb then
            cb()
        end
    end)
end

function XSkyGardenCafeControl:SyncKickOut(stageId)
    XNetwork.Call("BigWorldCafeGuideKickOutSceneRequest", { StageId = stageId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        local stageInfo = self:GetStageInfo(stageId)
        stageInfo:KickedOut()
        XLuaUiManager.SafeClose("UiSkyGardenCafeHandBook")
        if XMVCA.XSkyGardenCafe:IsEnterLevel() then
            XMVCA.XSkyGardenCafe:ExitGameLevel()
        else
            XMVCA.XSkyGardenCafe:DoLevelLevel()
        end
    end)
end

--endregion 卡组

--region 提示文本

function XSkyGardenCafeControl:GetTipTitle()
    return self._Model:GetConfig("Tips")
end

function XSkyGardenCafeControl:GetQuitText()
    return self._Model:GetConfig("ConfirmExit")
end

function XSkyGardenCafeControl:GetDeckNumNotEnoughText()
    return self._Model:GetConfig("CafeDeckNumNotEnough")
end

function XSkyGardenCafeControl:GetDeckNumIsFullText()
    return self._Model:GetConfig("CafeDeckNumIsFull")
end

function XSkyGardenCafeControl:GetCafeDealNumIsFull()
    return self._Model:GetConfig("CafeDealNumIsFull")
end

function XSkyGardenCafeControl:GetRoundText()
    return self._Model:GetConfig("CafeRoundText")
end

function XSkyGardenCafeControl:GetQuitGameText()
    return self._Model:GetConfig("QuitGameText")
end

function XSkyGardenCafeControl:GetResetRoundText()
    return self._Model:GetConfig("ResetRoundText")
end

function XSkyGardenCafeControl:GetDealCountFullText()
    return self._Model:GetConfig("DealCountFullText")
end

function XSkyGardenCafeControl:GetTargetText()
    return self._Model:GetConfig("CafeTargetText")
end

function XSkyGardenCafeControl:GetSyncDeckSuccessText()
    return self._Model:GetConfig("CafeSyncDeckSuccessText")
end

function XSkyGardenCafeControl:GetHistoryLockText()
    local desc = self._Model:GetConfig("PassUnlock")
    local storyStageIds = self:GetStoryStageIds()
    local stageId = storyStageIds and storyStageIds[1] or 0
    if not stageId or stageId <= 0 then
        return "???"
    end
    local name = self:GetStageName(stageId)
    return string.format(desc, name)
end

function XSkyGardenCafeControl:GetStageLockText(stageId)
    local name = self:GetStageName(stageId)
    local desc = self._Model:GetConfig("PassUnlock")
    return string.format(desc, name)
end

function XSkyGardenCafeControl:GetAllStoryStagePassedTip()
    return self._Model:GetConfig("AllStoryStagePassed")
end

function XSkyGardenCafeControl:GetQualityReachedLimitText()
    return self._Model:GetConfig("QualityReachedLimitText")
end

function XSkyGardenCafeControl:GetLeftCustomerTitle()
    return self._Model:GetConfig("LeftCustomerTitle")
end

function XSkyGardenCafeControl:GetSpecialStageTitle()
    return self._Model:GetConfig("SpecialStageTitle")
end

function XSkyGardenCafeControl:GetHistoryStageTitle()
    return self._Model:GetConfig("HistoryStageTitle")
end

function XSkyGardenCafeControl:GetQualityLimitDict()
    if self._QualityLimitDict then
        return self._QualityLimitDict
    end
    local maxQuality = self._Model:GetMaxQuality()
    local dict = {}
    for i = 1, maxQuality do
        local limit = tonumber(self._Model:GetConfig("MaxQuality"..i.."Limit"))
        if limit and limit > 0 then
            dict[i] = limit
        end
    end
    self._QualityLimitDict = dict
    
    return dict
end

function XSkyGardenCafeControl:GetCafeCameraScreenRatio()
    return tonumber(self._Model:GetConfig("CafeCameraScreenRatio"))
end

--endregion

--region 本地数据

function XSkyGardenCafeControl:IsShowCardDetail()
    local key = self._Model:GetCookies("SHOW_CARD_DETAIL")
    return XSaveTool.GetData(key) and true or false
end

function XSkyGardenCafeControl:MarkShowCardDetailValue(value)
    local key = self._Model:GetCookies("SHOW_CARD_DETAIL")
    XSaveTool.SaveData(key, value)
end

function XSkyGardenCafeControl:IsSkipAnimation()
    local key = self._Model:GetCookies("SKIP_ANIMATION")
    return XSaveTool.GetData(key) and true or false
end

function XSkyGardenCafeControl:MarkSkipAnimation(value)
    local key = self._Model:GetCookies("SKIP_ANIMATION")
    XSaveTool.SaveData(key, value)
end

function XSkyGardenCafeControl:HasNewCard()
    return self._Model:HasNewCard()
end

function XSkyGardenCafeControl:CheckCardNewMark(cardId)
    return self._Model:CheckCardNewMark(cardId)
end

function XSkyGardenCafeControl:MarkNewCard(cardId)
    self._Model:MarkNewCard(cardId)
end

function XSkyGardenCafeControl:SaveNewMark()
    self._Model:SaveNewMark()
end

function XSkyGardenCafeControl:CheckStageNewMark(stageId)
    return self._Model:CheckStageNewMark(stageId)
end

function XSkyGardenCafeControl:MarkNewStage(stageId)
    self._Model:MarkNewStage(stageId)
end

function XSkyGardenCafeControl:CheckStageNewMarkByType(stageType)
    local stageList
    if stageType == XMVCA.XSkyGardenCafe.StageType.Challenge then
        stageList = self:GetChallengeStageIds()
    elseif stageType == XMVCA.XSkyGardenCafe.StageType.Story then
        stageList = self:GetStoryStageIds()
    end
    if XTool.IsTableEmpty(stageList) then
        return false
    end
    for _, stageId in pairs(stageList) do
        if self:CheckStageNewMark(stageId) then
            return true
        end
    end
    
    return false
end

function XSkyGardenCafeControl:IsAscendingOrder()
    local key = self._Model:GetCookies("ASCENDING_ORDER")
    local v  = XSaveTool.GetData(key)
    if not v or v == 1 then
        return true
    end
    return false
end

function XSkyGardenCafeControl:SetAscendingOrder(isAscendingOrder)
    local v = isAscendingOrder and 1 or 0
    local key = self._Model:GetCookies("ASCENDING_ORDER")
    local localV = XSaveTool.GetData(key)
    if localV == v then
        return
    end
    XSaveTool.SaveData(key, v)
end

function XSkyGardenCafeControl:IsShowBuffDetail()
    local key = self._Model:GetCookies("SHOW_BUFF_DETAIL")
    local v = XSaveTool.GetData(key)
    if not v then
        return false
    end
    return v
end

function XSkyGardenCafeControl:MarkShowBuffDetailValue(value)
    local key = self._Model:GetCookies("SHOW_BUFF_DETAIL")
    local v = XSaveTool.GetData(key)
    if v == value then
        return
    end
    XSaveTool.SaveData(key, value)
end

--endregion

--region 战斗

function XSkyGardenCafeControl:CheckCondition(conditionId, ...)
    if not self._Condition then
        self._Condition = self:AddSubControl(require("XModule/XSkyGardenCafe/SubControl/XSkyGardenCafeCondition"))
    end
    return self._Condition:CheckCondition(conditionId, ...)
end

function XSkyGardenCafeControl:SetFightData(stageId, deckId)
    self._Model:SetFightData(stageId, deckId)
end

function XSkyGardenCafeControl:GetNextTargetAndMaxTargetByCoffee(stageId, coffee)
    local targets = self._Model:GetStageTarget(stageId)
    if XTool.IsTableEmpty(targets) then
        return 0, 0
    end
    local temp
    local max = targets[#targets]
    for _, target in pairs(targets) do
        if target > coffee then
            temp = target
            break
        end
    end
    if not temp then
        return max, max
    end
    return temp, max
end

--- 进入战斗
---@param stageId number 关卡Id
---@param deckId number 卡组Id, 只有挑战模式需要自定义卡组才需要传
--------------------------
function XSkyGardenCafeControl:EnterFight(stageId, deckId)
    if not self._Battle then
        self._Battle = self:AddSubControl(require("XModule/XSkyGardenCafe/SubControl/XSkyGardenCafeBattle"))
    end
    if XLuaUiManager.IsUiShow("UiSkyGardenCafeGame") then
        XLuaUiManager.Close("UiSkyGardenCafeGame")
    elseif XLuaUiManager.IsUiLoad("UiSkyGardenCafeGame") then
        XLuaUiManager.Remove("UiSkyGardenCafeGame")
    end
    self._Battle:DoEnterFight(stageId, deckId)
end

---@return XSkyGardenCafeBattle
function XSkyGardenCafeControl:GetBattle()
    if not self._Battle or not self._Battle:IsInFight() then
        return
    end
    return self._Battle
end

function XSkyGardenCafeControl:IsInFight()
    return self._Battle and self._Battle:IsInFight()
end

function XSkyGardenCafeControl:SetCardUpdateHandler(handler)
    self._CardUpdateHandler = handler
end

function XSkyGardenCafeControl:ExitFight()
    if self._Battle then
        self._Battle:DoExitFight()
    end
    self._CardUpdateHandler = nil
end

function XSkyGardenCafeControl:InvokeCardUpdate(evt, type, index, card)
    if not self._CardUpdateHandler or self:GetIsRelease() then
        return
    end
    self._CardUpdateHandler(evt, type, index, card)
end

function XSkyGardenCafeControl:GetBarTableClickCd()
    return self._Model:GetBarTableClickCd()
end

function XSkyGardenCafeControl:GetBtnReDrawText()
    if not self._Battle or not self._Battle:IsInFight() then
        return
    end
    local isSelect = self._Battle:GetRoundEntity():IsSelectReDrawCard()
    return self._Model:GetBtnReDrawText(isSelect)
end

function XSkyGardenCafeControl:GetBtnSettleContinueText(isQuit)
    local key = isQuit and "BtnSettleQuitText" or "BtnSettleContinueText"
    return self._Model:GetConfig(key)
end

function XSkyGardenCafeControl:GetCardLockedText()
    return self._Model:GetConfig("CardLocked")
end

function XSkyGardenCafeControl:GetCardUsedUpText()
    return self._Model:GetConfig("CardUsedUp")
end

function XSkyGardenCafeControl:OpenHandBook(uiType, stageId)
    uiType = uiType or XMVCA.XSkyGardenCafe.UIType.HandleBook
    local maxCustomer = self._Model:GetChallengeMaxCustomer()
    XLuaUiManager.Open("UiSkyGardenCafeHandBook", uiType, maxCustomer, stageId)
end

function XSkyGardenCafeControl:PopupBroadcast()
    local uiName = "UiSkyGardenCafePopupBroadcast"
    if XLuaUiManager.IsUiShow(uiName) then
        XMVCA.XSkyGardenCafe:DispatchInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_REFRESH_BROADCAST)
        return
    end
    XLuaUiManager.Open(uiName)
end

function XSkyGardenCafeControl:GetTrailEffectUrl(type)
    local name
    local HudType = XMVCA.XSkyGardenCafe.HudType
    if type == HudType.CoffeeHud then
        name = "FxUiSkyGardenUiTrail01"
    elseif type == HudType.ReviewHud then
        name = "FxUiSkyGardenUiTrail02"
    end
    if not name then
        return
    end
    
    return XMVCA.XBigWorldResource:GetAssetUrl(name)
end

function XSkyGardenCafeControl:GetTargetWorldPosition(type)
    return self._HudType2WorldPosition[type]
end

function XSkyGardenCafeControl:SetTargetWorldPosition(type, position)
    self._HudType2WorldPosition[type] = position
end

function XSkyGardenCafeControl:SetStageIdCache(value)
    self._StageIdCache = value
end

function XSkyGardenCafeControl:GetAndClearStageIdCache()
    if self._StageIdCache and self._StageIdCache > 0 then
        local id = self._StageIdCache
        self._StageIdCache = 0
        return id
    end
    return self._StageIdCache
end

function XSkyGardenCafeControl:NeedChangeCamera()
    return self._NeedChangeCamera
end

function XSkyGardenCafeControl:SetChangeCamera(value)
    self._NeedChangeCamera = value
end

function XSkyGardenCafeControl:CreateStateMachine(skeleton1, skeleton2)
    if not XCafeStateMachine then
        XCafeStateMachine = require("XModule/XSkyGardenCafe/StateMachine/XCafeStateMachine")
    end
    if not self._StateMachine then
        self._StateMachine = XCafeStateMachine.New(skeleton1, skeleton2)
    end
    self._StateMachine:_InitParams(skeleton1, skeleton2)
end

function XSkyGardenCafeControl:ClearStateMachineParam()
    if not self._StateMachine then
        return
    end
    self._StateMachine:ClearParams()
end

function XSkyGardenCafeControl:ChangeGamePetState(state)
    if not self._StateMachine then
        return false
    end
    return self._StateMachine:ChangeState(state)
end

--endregion 战斗


return XSkyGardenCafeControl