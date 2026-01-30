local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")


---@class XUiSkyGardenCafeHandBook : XLuaUi
---@field GameObject UnityEngine.GameObject
---@field Transform UnityEngine.Transform
---@field _Control XSkyGardenCafeControl
---@field _GridCardSmall XUiGridSGCardItem[]
local XUiSkyGardenCafeHandBook = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenCafeHandBook")

local XUiGridSGCardItem = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGCardItem")
local XUiSGGridQualityLimit = require("XUi/XUiSkyGarden/XCafe/Grid/XUiSGGridQualityLimit")

local UiType = XMVCA.XSkyGardenCafe.UIType
local CsSelect = CS.UiButtonState.Select
local CsNormal = CS.UiButtonState.Normal

local ClickSmallCd = 0.1
local DlcEventId = XMVCA.XBigWorldService.DlcEventId

function XUiSkyGardenCafeHandBook:OnAwake()
    self:InitUi()
    self:InitCb()
end

function XUiSkyGardenCafeHandBook:OnStart(uiType, maxCustomer, stageId)
    self._UiType = uiType
    self._MaxCustomer = maxCustomer
    self._StageId = stageId
    self:InitView()
    XMVCA.XSkyGardenCafe:AddInnerEvent(DlcEventId.EVENT_CAFE_NEW_CARD_UNLOCK, self.RefreshNewPanel, self)
end

function XUiSkyGardenCafeHandBook:OnEnable()
    local id = self._Control:GetAndClearStageIdCache()
    if id and id > 0 and id ~= self._StageId then
        self._StageId = id
        self:InitView()
    end
    if self._GridBuff then
        self._GridBuff:RefreshView()
    end
end

function XUiSkyGardenCafeHandBook:OnDisable()
    if self.TweenTimer then
        XScheduleManager.UnSchedule(self.TweenTimer)
        self.TweenTimer = nil
    end
end

function XUiSkyGardenCafeHandBook:OnDestroy()
    self._Control:RestoreDeck()
    XMVCA.XSkyGardenCafe:RemoveInnerEvent(DlcEventId.EVENT_CAFE_NEW_CARD_UNLOCK, self.RefreshNewPanel, self)
end

function XUiSkyGardenCafeHandBook:InitUi()
    self._IsAscendingOrder = self._Control:IsAscendingOrder()
    self._ClickSmallTime = os.clock()
    local qualityDict = self._Control:GetQualityLimitDict()
    local list = {}
    for quality, limit in pairs(qualityDict) do
        list[#list + 1] = {
            Quality = quality,
            Limit = limit
        }
    end
    table.sort(list, function(a, b) 
        return a.Quality < b.Quality
    end)
    self._QualityList = list
    self._GridQualities = {}
    local tab = {
        self.BtnTab1,
        self.BtnTab2,
        self.BtnTab3,
    }
    self.PanelTab:Init(tab, function(index) self:OnSelectTab(index) end)
    
    self._GridCardSmall = {}
    self.GridCard.gameObject:SetActiveEx(false)
    
    
    self._GDynamicTable = XDynamicTableNormal.New(self.GListCard)
    self._GDynamicTable:SetProxy(XUiGridSGCardItem, self)
    self._GDynamicTable:SetDelegate(self)
    self._GDynamicTable:SetDynamicEventDelegate(handler(self, self.OnGDynamicTableEvent))
    self.UiSkyGardenCafeCard.gameObject:SetActiveEx(false)

    self.PanelNewCardTips.gameObject:SetActiveEx(false)

    local isShowDetail = self._Control:IsShowCardDetail()
    local state = isShowDetail and CsSelect or CsNormal
    self.BtnToggle:SetButtonState(state)
end

function XUiSkyGardenCafeHandBook:InitCb()
    self.BtnBack:AddEventListener(handler(self, self.OnBtnBackClick))
    
    self.BtnDelete:AddEventListener(handler(self, self.OnBtnDeleteClick))
    
    self.BtnStart:AddEventListener(handler(self, self.OnBtnStartClick))
    
    self.BtnSave:AddEventListener(handler(self, self.OnBtnSaveClick))
    
    self.BtnToggle:AddEventListener(handler(self, self.OnBtnToggleClick))
    
    self.BtnArriveNew:AddEventListener(handler(self, self.OnBtnArriveNewClick))
    
    self.BtnToggleScreen:AddEventListener(handler(self, self.OnBtnToggleScreenClick))
    
    self.BtnHelp:AddEventListener(handler(self, self.OnBtnHelpClick))
    
    self._SortCardIdAscendingCb = function(idA, idB)
        local pA = self._Control:GetCustomerQuality(idA)
        local pB = self._Control:GetCustomerQuality(idB)
        if pA ~= pB then
            return pA > pB
        end
        local qA = self._Control:GetCustomerPriority(idA)
        local qB = self._Control:GetCustomerPriority(idB)
        if qA ~= qB then
            return qA > qB
        end
        return idA < idB
    end

    self._SortCardIdDescendingCb = function(idA, idB)
        local pA = self._Control:GetCustomerQuality(idA)
        local pB = self._Control:GetCustomerQuality(idB)
        if pA ~= pB then
            return pA < pB
        end
        local qA = self._Control:GetCustomerPriority(idA)
        local qB = self._Control:GetCustomerPriority(idB)
        if qA ~= qB then
            return qA < qB
        end
        return idA > idB
    end
    
    self._SortCardCb = function(a, b) 
        return self._SortCardIdAscendingCb(a:GetId(), b:GetId())
    end
end

function XUiSkyGardenCafeHandBook:InitView()
    self.BtnDelete.gameObject:SetActiveEx(true)
    local isDeckEditor = self._UiType == UiType.DeckEditor
    self.BtnStart.gameObject:SetActiveEx(isDeckEditor)
    self.BtnSave.gameObject:SetActiveEx(self._UiType == UiType.HandleBook)
    --self.PanelScore.gameObject:SetActiveEx(isDeckEditor)
    --if isDeckEditor then
    --    self.TxtCoffeeNum.text = self._Control:GetHighestChallengeScore()
    --end

    local isAscendingOrder = self._IsAscendingOrder
    local state = isAscendingOrder and CsNormal or CsSelect
    self.BtnToggleScreen:SetButtonState(state)
    self.UiSkyGardenCafeGridBuff.gameObject:SetActiveEx(false)
    if isDeckEditor then
        local buffListId = self._Control:GetStageBuffListId(self._StageId)
        if buffListId and buffListId > 0 then
            self._GridBuff = require("XUi/XUiSkyGarden/XCafe/Grid/XUiGridSGBuffItem").New(self.UiSkyGardenCafeGridBuff, self, buffListId)
            self._GridBuff:Open()
        end
    end
    
    local selectId = self._Control:GetSelectDeckId()
    self.PanelTab:SelectIndex(selectId)
    
    self:RefreshQualityLimit()
end

function XUiSkyGardenCafeHandBook:OnBtnBackClick()
    if self._Control:IsInFight() then
        self._Control:ExitFight()
    end
    self:Close()
end

function XUiSkyGardenCafeHandBook:OnBtnDeleteClick()
    self._Deck:Clear()
    
    self:RefreshSmallCardList()
    self:SetupOwnDynamicTable(true)
    
    self:RefreshQualityLimit()
end

function XUiSkyGardenCafeHandBook:OnBtnStartClick()
    if self._Deck:Total() < self._MaxCustomer then
        XUiManager.TipMsg(self._Control:GetDeckNumNotEnoughText())
        return
    end
    if not XTool.IsTableEmpty(self._Quality2Count) then
        for q, data in pairs(self._Quality2Count) do
            local limit = data.Limit
            if limit > 0 and limit < data.Count then
                XUiManager.TipMsg(self._Control:GetQualityReachedLimitText())
                return
            end
        end
    end
    self._Control:SetFightData(self._StageId, self._Deck:GetId())
    XMVCA.XSkyGardenCafe:EnterGameLevel()
end

function XUiSkyGardenCafeHandBook:OnBtnSaveClick()
    if self._Deck:Total() < self._MaxCustomer then
        XUiManager.TipMsg(self._Control:GetDeckNumNotEnoughText())
        return
    end
    if not XTool.IsTableEmpty(self._Quality2Count) then
        for q, data in pairs(self._Quality2Count) do
            local limit = data.Limit
            if limit > 0 and limit < data.Count then
                XUiManager.TipMsg(self._Control:GetQualityReachedLimitText())
                return
            end
        end
    end
    local deckId = self._Deck:GetId()
    self._Control:SaveDeckRequest(deckId)
end

function XUiSkyGardenCafeHandBook:OnBtnToggleClick()
    local isShowDetail = self._Control:IsShowCardDetail()
    isShowDetail = not isShowDetail
    local state = isShowDetail and CsSelect or CsNormal
    self.BtnToggle:SetButtonState(state)
    
    self._Control:MarkShowCardDetailValue(isShowDetail)
    
    self:SetupOwnDynamicTable(true)
end

function XUiSkyGardenCafeHandBook:OnBtnArriveNewClick()
    local index
    for i, cardId in pairs(self._AllList) do
        if self._Control:CheckCardNewMark(cardId) then
            index = i
            break
        end
    end

    if index then
        self:SetupOwnDynamicTable(false, index)
    end
end

function XUiSkyGardenCafeHandBook:OnBtnToggleScreenClick()
    self._IsAscendingOrder = not self._IsAscendingOrder
    self:SetupOwnDynamicTable(true)
    self._Control:SetAscendingOrder(self._IsAscendingOrder)
end

function XUiSkyGardenCafeHandBook:OnBtnHelpClick()
    XMVCA.XBigWorldTeach:OpenTeachTipUi(XMVCA.XSkyGardenCafe:GetTeachId())
end

function XUiSkyGardenCafeHandBook:OnSelectTab(index)
    if self._TabIndex == index then
        return
    end
    
    local deckId = XMVCA.XSkyGardenCafe.DeckIds[index]
    if not deckId then
        index = 1
        deckId = XMVCA.XSkyGardenCafe.DeckIds[index]
        XLog.Error("不存在卡组Id")
        self.PanelTab:SelectIndex(index, false)
        return
    end
    self:PlayAnimationWithMask("PageSwitch")
    self._Deck = self._Control:GetCardDeck(deckId)
    self._TabIndex = index
    self:RefreshSmallCardList()
    self:SetupOwnDynamicTable()
    self:RefreshQualityLimit()
end

function XUiSkyGardenCafeHandBook:RefreshDeckInfo()
    local total = self._Deck:Total()
    self.TxtNum.text = string.format("%d/%d", total, self._MaxCustomer)
    if self._UiType == UiType.DeckEditor then
        local disable = total < self._MaxCustomer
        self.BtnStart:SetDisable(disable)
    end
end

function XUiSkyGardenCafeHandBook:RefreshSmallCardList()
    local dataList = self._Deck:GetCardList()
    table.sort(dataList, self._SortCardCb)
    self._CardList = dataList

    XTool.UpdateDynamicItem(self._GridCardSmall, dataList, self.GridCard, XUiGridSGCardItem, self)
    self:RefreshDeckInfo()
end

function XUiSkyGardenCafeHandBook:AddSmallCard(cardId, isAdd)
    local dataList = self._Deck:GetCardList()
    table.sort(dataList, self._SortCardCb)
    self._CardList = dataList
    local anim = isAdd and "GridCardEnable" or "GridCardRefresh"
    local index
    for i, data in pairs(dataList) do
        if data:GetId() == cardId then
            index = i
            break
        end
    end
    if not index then
        return
    end
    local cardItem = self._GridCardSmall[index]
    if not cardItem then
        return
    end
    XTool.UpdateDynamicItem(self._GridCardSmall, dataList, self.GridCard, XUiGridSGCardItem, self)
    if index then
        local current = self.VListCard.verticalNormalizedPosition
        local target = 1 - (index - 1) / (#dataList - 1)
        self.TweenTimer = self:Tween(0.1, function(dt)
            self.VListCard.verticalNormalizedPosition = (target - current) * dt + current
        end, function()
            local grid = self._GridCardSmall[index]
            if grid then
                --grid:PlayEnableEffect()
                grid:PlayAnimationWithMask(anim)
            end
        end)
    end
    self:RefreshDeckInfo()
end

function XUiSkyGardenCafeHandBook:RemoveSmallCard(index, isRemove)
    local dataList = self._Deck:GetCardList()
    table.sort(dataList, self._SortCardCb)
    self._CardList = dataList
    local anim = isRemove and "GridCardDisable" or "GridCardRefresh"
    
    local cardItem = self._GridCardSmall[index]
    if not cardItem then
        return
    end
    
    cardItem:PlayAnimationWithMask(anim, function()
        --if isRemove then
        --    cardItem:Close()
        --else
        --    XTool.UpdateDynamicItem(self._GridCardSmall, dataList, self.GridCard, XUiGridSGCardItem, self)
        --end
        XTool.UpdateDynamicItem(self._GridCardSmall, dataList, self.GridCard, XUiGridSGCardItem, self)
    end)
    self:RefreshDeckInfo()
end

function XUiSkyGardenCafeHandBook:SetupOwnDynamicTable(isRefreshOnly, startIndex)
    local dataList = self._Control:GetAllShowCustomerIds()
    if self._IsAscendingOrder then
        table.sort(dataList, self._SortCardIdAscendingCb)
    else
        table.sort(dataList, self._SortCardIdDescendingCb)
    end
    self._AllList = dataList
    
    self._GDynamicTable:SetDataSource(dataList)
    if isRefreshOnly then
        for i, cardId in pairs(dataList) do
            local grid = self._GDynamicTable:GetGridByIndex(i)
            if grid then
                self:DoRefreshBigItem(grid, cardId)
            end
        end
    else
        self._GDynamicTable:ReloadDataSync(startIndex)
    end
    
end

---@param grid XUiGridSGCardItem
function XUiSkyGardenCafeHandBook:DoRefreshBigItem(grid, cardId)
    if not grid then
        return
    end
    local card = self._Control:GetOwnCardDeck():GetOrAddCard(cardId)
    local deckCard = self._Deck:GetOrAddCard(cardId)
    local userCount = deckCard:Count()
    grid:RefreshBig(card, userCount)
end

function XUiSkyGardenCafeHandBook:OnGDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local cardId = self._AllList[index]
        self:DoRefreshBigItem(grid, cardId)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:OnClickBigItem(index, grid)
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:Recycle()
    elseif evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RELOAD_COMPLETED then
        self:RefreshNewPanel()
    end
end

function XUiSkyGardenCafeHandBook:OnClickSmallItem(index, grid)
    local now = os.clock()
    if now - self._ClickSmallTime < ClickSmallCd then
        return
    end
    self._ClickSmallTime = now
    local card = self._CardList[index]
    local cardId = card:GetId()
    self._Deck:RemoveAt(cardId)
    local isRemove
    if card:Count() <= 0 then
        isRemove = true
    else
        isRemove = false
    end
    
    self:RemoveSmallCard(index, isRemove)
    self:SetupOwnDynamicTable(true)
    self:RefreshQualityLimit()
end

function XUiSkyGardenCafeHandBook:OnClickBigItem(index, grid)
    local id = self._AllList[index]
    local card = self._Control:GetOwnCardDeck():GetOrAddCard(id)
    if not card then
        return
    end
    if not card:IsUnlock() then
        XUiManager.TipMsg(self._Control:GetCardLockedText())
        return
    end
    local userCount = self._Deck:GetOrAddCard(id):Count()
    if card:PreviewCount(userCount) <= 0 then
        XUiManager.TipMsg(self._Control:GetCardUsedUpText())
        return
    end
    if self._Deck:Total() >= self._MaxCustomer then
        XUiManager.TipMsg(self._Control:GetQualityReachedLimitText())
        return
    end
    local quality = self._Control:GetCustomerQuality(id)
    local data = self._Quality2Count[quality]
    if data and data.Limit <= data.Count then
        XUiManager.TipMsg(self._Control:GetQualityReachedLimitText())
        return
    end
    self._Deck:Insert(id)
    userCount = userCount + 1
    grid:RefreshBig(card, userCount)
    self:AddSmallCard(card:GetId(), card:Count() == 1)
    self:RefreshQualityLimit()
end

function XUiSkyGardenCafeHandBook:RefreshQualityLimit()
    local cardList = self._Deck:GetCardList()
    local quality2Count = {}
    for _, card in pairs(cardList) do
        local id = card:GetId()
        local quality = self._Control:GetCustomerQuality(id)
        local count = 0
        if not quality2Count[quality] then
            quality2Count[quality] = {
                Count = 0,
                Limit = 0
            }
        else
            count = quality2Count[quality].Count
        end
        count = count + card:Count()
        quality2Count[quality].Count = count
    end
    for i, data in pairs(self._QualityList) do
        local grid = self._GridQualities[i]
        if not grid then
            local ui = i == 1 and self.GridConfine or XUiHelper.Instantiate(self.GridConfine, self.PanelConfine)
            grid = XUiSGGridQualityLimit.New(ui, self)
            self._GridQualities[i] = grid
        end
        local quality = data.Quality
        local limit = data.Limit
        local count = quality2Count[quality] and quality2Count[quality].Count or 0
        grid:Refresh(quality, limit, count)
        if quality2Count[quality] then
            quality2Count[quality].Limit = data.Limit
        end
    end
    self._Quality2Count = quality2Count
end

function XUiSkyGardenCafeHandBook:RefreshNewPanel()
    local v = self._Control:HasNewCard()
    self.PanelNewCardTips.gameObject:SetActiveEx(v)
    if v then
        self:SetupOwnDynamicTable(true)
    end
end

function XUiSkyGardenCafeHandBook:IsShowBuffDetail()
    return true
end