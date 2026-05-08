--- 资产显示面板（血量、金币）
---@class XUiPanelTheatre6Asset : XUiNode
---@field private _Control XTheatre6Control
local XUiPanelTheatre6Asset = XClass(XUiNode, "XUiPanelTheatre6Asset")

local WaitTime = 1000

function XUiPanelTheatre6Asset:OnStart()
    self._IsBubbleOpen = false

    self.BtnHP:AddEventListener(handler(self, self.OnBtnHPClick))
    self.BtnGlod:AddEventListener(handler(self, self.OnBtnGlodClick))
    --self.BtnReturn:AddEventListener(handler(self, self.OnBtnReturnClick))

    self.PanelBubble.gameObject:SetActiveEx(false)
    --self.BtnReturn.gameObject:SetActiveEx(false)
    self.UiTxtHpAdd.gameObject:SetActiveEx(false)
    self.UiTxtHpReduce.gameObject:SetActiveEx(false)
    self.UiTxtGoldAdd.gameObject:SetActiveEx(false)
    self.UiTxtGoldReduce.gameObject:SetActiveEx(false)

    self.BtnHP:SetRawImage(self._Control:GetHpIcon())
    self.BtnGlod:SetRawImage(self._Control:GetCoinIcon())
end

function XUiPanelTheatre6Asset:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_HEALTH_CHANGE, self.PlayAddHp, self)
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE6_GOLD_CHANGE, self.PlayAddGold, self)
end

function XUiPanelTheatre6Asset:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_HEALTH_CHANGE, self.PlayAddHp, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE6_GOLD_CHANGE, self.PlayAddGold, self)
end

function XUiPanelTheatre6Asset:OnDestroy()
    self:RemoveGoldTimer()
    self:RemoveHpTimer()
end

function XUiPanelTheatre6Asset:Refresh()
    self:RefreshHp()
    self:RefreshGold()
    --self:RefreshBubbleDetail()
end

function XUiPanelTheatre6Asset:RefreshHp()
    local hp = self._Control:GetCurrentHp()
    self.BtnHP:SetName(hp)
end

function XUiPanelTheatre6Asset:RefreshGold()
    local gold = self._Control:GetCurrentGold()
    self.BtnGlod:SetNameByGroup(0, gold)
end

--function XUiPanelTheatre6Asset:RefreshBubbleDetail()
--    local hpData = self._Control:GetHpDetail()
--    local goldData = self._Control:GetGoldDetail()
--    local detailText = "这是详情"
--    self.UiTxtDetail.text = detailText
--end

function XUiPanelTheatre6Asset:OnBtnHPClick()
    self._IsBubbleOpen = not self._IsBubbleOpen
    self.PanelBubble.gameObject:SetActiveEx(self._IsBubbleOpen)
    self.UiTxtDetail.text = self._Control:GetHpDetail()
end

function XUiPanelTheatre6Asset:OnBtnGlodClick()
    self._IsBubbleOpen = not self._IsBubbleOpen
    self.PanelBubble.gameObject:SetActiveEx(self._IsBubbleOpen)
    self.UiTxtDetail.text = self._Control:GetGoldDetail()
end

--function XUiPanelTheatre6Asset:OnBtnAssetClick()
--    self._IsBubbleOpen = not self._IsBubbleOpen
--    self.PanelBubble.gameObject:SetActiveEx(self._IsBubbleOpen)
--    self.BtnReturn.gameObject:SetActiveEx(self._IsBubbleOpen)
--end

--function XUiPanelTheatre6Asset:OnBtnReturnClick()
--    self._IsBubbleOpen = false
--    self.PanelBubble.gameObject:SetActiveEx(false)
--    self.BtnReturn.gameObject:SetActiveEx(false)
--end

function XUiPanelTheatre6Asset:PlayAddGold(value)
    self:RefreshGold()
    self:RemoveGoldTimer()
    if value > 0 then
        self.UiTxtGoldAdd.gameObject:SetActiveEx(true)
        self.UiTxtGoldAdd.text = string.format("+%s", value)
        self._GoldTimer = XScheduleManager.ScheduleOnce(function()
            self.UiTxtGoldAdd.gameObject:SetActiveEx(false)
        end, WaitTime)
    else
        self.UiTxtGoldReduce.gameObject:SetActiveEx(true)
        self.UiTxtGoldReduce.text = value
        self._GoldTimer = XScheduleManager.ScheduleOnce(function()
            self.UiTxtGoldReduce.gameObject:SetActiveEx(false)
        end, WaitTime)
    end
end

function XUiPanelTheatre6Asset:PlayAddHp(value)
    self:RefreshHp()
    self:RemoveHpTimer()
    if value > 0 then
        self.UiTxtHpAdd.gameObject:SetActiveEx(true)
        self.UiTxtHpAdd.text = string.format("+%s", value)
        self._HpTimer = XScheduleManager.ScheduleOnce(function()
            self.UiTxtHpAdd.gameObject:SetActiveEx(false)
        end, WaitTime)
    else
        self.UiTxtHpReduce.gameObject:SetActiveEx(true)
        self.UiTxtHpReduce.text = value
        self._HpTimer = XScheduleManager.ScheduleOnce(function()
            self.UiTxtHpReduce.gameObject:SetActiveEx(false)
        end, WaitTime)
    end
end

function XUiPanelTheatre6Asset:RemoveGoldTimer()
    if self._GoldTimer then
        XScheduleManager.UnSchedule(self._GoldTimer)
        self._GoldTimer = nil
    end
end

function XUiPanelTheatre6Asset:RemoveHpTimer()
    if self._HpTimer then
        XScheduleManager.UnSchedule(self._HpTimer)
        self._HpTimer = nil
    end
end

return XUiPanelTheatre6Asset
