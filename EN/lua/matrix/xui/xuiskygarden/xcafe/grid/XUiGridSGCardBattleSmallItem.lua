
---@class XUiGridSGCardBattleSmallItem
---@field _Control XSkyGardenCafeControl
---@field _Card XCafe.XCard
---@field Parent XUiSkyGardenCafeGame
local XUiGridSGCardBattleSmallItem = XClass(nil, "XUiGridSGCardBattleSmallItem")

local XUiPanelSGValueChange = require("XUi/XUiSkyGarden/XCafe/Panel/XUiPanelSGValueChange")

function XUiGridSGCardBattleSmallItem:Ctor(card, control, parent)
    XTool.InitUiObjectByUi(self, card.transform)
    self._Card = card
    self._Control = control
    self.Parent = parent
    if not self._Effect then
        self._Effect = self.Transform:Find("Effect")
    end
    
    self._PanelCoffee = XUiPanelSGValueChange.New(self.PanelSell)
    self._PanelReview = XUiPanelSGValueChange.New(self.PanelGood)
end

function XUiGridSGCardBattleSmallItem:Reclaim()
    self.PanelSell.gameObject:SetActiveEx(false)
    self.PanelGood.gameObject:SetActiveEx(false)
    self.RImgRole.gameObject:SetActiveEx(false)
    if self._Effect then
        self._Effect.gameObject:SetActiveEx(false)
    end
    self:StopTimer()
end

---@param card XSkyGardenCafeCardEntity
function XUiGridSGCardBattleSmallItem:Refresh(card)
    local index = self._Card:GetDealIndex() + 1
    self.TxtNum.text = index
    if not card or card:IsDisposed() then
        self.PanelSell.gameObject:SetActiveEx(false)
        self.PanelGood.gameObject:SetActiveEx(false)
        self.RImgRole.gameObject:SetActiveEx(false)
        if self._Effect then
            self._Effect.gameObject:SetActiveEx(false)
        end
        self:StopTimer()
        return
    end
    self.RImgRole.gameObject:SetActiveEx(true)
    self.PanelSell.gameObject:SetActiveEx(true)
    self.PanelGood.gameObject:SetActiveEx(true)
    
    if not self._RunAsync then
        local playTime = asynTask(self.Enable.PlayTimelineAnimation, self.Enable)
        RunAsyn(function()
            asynWaitSecond(0.3)

            playTime()

            if self.Parent.PlaySeatAudio then
                self.Parent:PlaySeatAudio(index)
            end
            if self._Effect then
                self._Effect.gameObject:SetActiveEx(true)
                asynWaitSecond(1)
                self._Effect.gameObject:SetActiveEx(false)
            end
        end)
        self._RunAsync = true
    end
    local configCoffee, totalCoffee, totalReview, configReview = 0, 0, 0, 0
    if not card:IsNotDisplayResourceType() then
        totalCoffee = card:GetTotalCoffee(false)
        configCoffee = self._Control:GetCustomerCoffee(card:GetCardId())

        totalReview = card:GetTotalReview(false)
        configReview = self._Control:GetCustomerReview(card:GetCardId())
    end
    

    self._PanelCoffee:RefreshViewWithTxtComponent(totalCoffee, configCoffee, self.TxtSellNum)
    self._PanelReview:RefreshViewWithTxtComponent(totalReview, configReview, self.TxtGoodNum)
   
    self.RImgRole:SetRawImage(self._Control:GetCustomerSmallIcon(card:GetCardId()))
end

function XUiGridSGCardBattleSmallItem:InitUi()
end

function XUiGridSGCardBattleSmallItem:InitCb()
end

function XUiGridSGCardBattleSmallItem:Open()
    if not self.GameObject then
        return
    end
    self.GameObject:SetActiveEx(true)
end

function XUiGridSGCardBattleSmallItem:Close()
    self:StopTimer()
    if not self.GameObject then
        return
    end
    self.GameObject:SetActiveEx(false)
end

function XUiGridSGCardBattleSmallItem:StopTimer()
    self._RunAsync = false
end

return XUiGridSGCardBattleSmallItem 