---@class XUiRaceMissionShop : XLuaUi 商店&任务
---@field _Control XRaceControl
local XUiRaceMissionShop = XLuaUiManager.Register(XLuaUi, "UiRaceMissionShop")

function XUiRaceMissionShop:OnStart()
    self._ActivityConfig = self._Control:GetCurrentConfig()
    ---@type XUiPanelRaceTask
    self._Task = require("XUi/XUiRace/Panel/XUiPanelRaceTask").New(self.PanelTask, self)
    ---@type XUiPanelRaceShop
    self._Shop = require("XUi/XUiRace/Panel/XUiPanelRaceShop").New(self.PanelShop, self)

    self:InitTab()
    self:InitComponent()
    self:UpdateRedDot()
    XShopManager.GetShopInfoList(self._TabData[2], nil, XShopManager.ActivityShopType.RaceShop)
end

function XUiRaceMissionShop:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.UpdateRedDot, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateRedDot, self)
end

function XUiRaceMissionShop:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.UpdateRedDot, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateRedDot, self)
end

function XUiRaceMissionShop:InitTab()
    self._TabBtns = {}
    self._TabBtnIndexDict = {}
    self._TabData = {}
    self._TabData[1] = { self._ActivityConfig.TaskTimeLimitId }
    if XTool.IsNumberValid(self._ActivityConfig.SecondShopId) then
        self._TabData[2] = { self._ActivityConfig.ShopId, self._ActivityConfig.SecondShopId }
    else
        self._TabData[2] = { self._ActivityConfig.ShopId }
    end
    local btnIndex = 0
    local titles = self._Control:GetClientConfigs("TagTitle")
    for i, tabs in ipairs(self._TabData) do
        local btnGo = XUiHelper.Instantiate(self.BtnTab, self.BtnTab.parent)
        local btn = btnGo:GetComponent("XUiButton")
        btn:SetNameByGroup(0, titles[i])
        table.insert(self._TabBtns, btn)
        btnIndex = btnIndex + 1

        local firstIndex = btnIndex
        local childTitles = self._Control:GetClientConfigs(string.format("TagTitle_%s", i))
        for j, id in ipairs(tabs) do
            local childBtnGo = XUiHelper.Instantiate(self.BtnChild, self.BtnChild.parent)
            local childBtn = childBtnGo:GetComponent("XUiButton")
            childBtn.SubGroupIndex = firstIndex
            childBtn:SetNameByGroup(0, childTitles[j])
            table.insert(self._TabBtns, childBtn)
            btnIndex = btnIndex + 1
            self._TabBtnIndexDict[btnIndex] = { i, j }
        end
    end

    self.BtnTab.gameObject:SetActiveEx(false)
    self.BtnChild.gameObject:SetActiveEx(false)
    self.BtnTabGroup:Init(self._TabBtns, function(index)
        self:OnSelectedTag(index)
    end)
    self.BtnTabGroup:SelectIndex(1)
end

function XUiRaceMissionShop:InitComponent()
    local endTime = self._Control:GetTime()
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
            return
        end
        local time = endTime - XTime.GetServerNowTimestamp()
        self.TxtTime.text = XUiHelper.GetText("RaceCountDown", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER))
    end)
    XUiHelper.NewPanelActivityAssetSafe({ self._ActivityConfig.ItemId }, self.PanelSpecialTool, self)
    XUiHelper.NewPanelTopControl(self, self.TopControlWhite)
end

function XUiRaceMissionShop:OnSelectedTag(index)
    local btn = self._TabBtns[index]
    local firstIndex = self._TabBtnIndexDict[index][1]
    local secondIndex = self._TabBtnIndexDict[index][2]
    local id = self._TabData[firstIndex][secondIndex]
    if firstIndex == 1 then
        -- 任务
        self._Task:Open()
        self._Task:UpdateTaskShow(id)
        self._Shop:Close()
    elseif firstIndex == 2 then
        -- 商店
        self._CurShopId = id
        self._Task:Close()
        self._Shop:Open()
        self._Shop:UpdateShopShow(id, true)
    end
end

--region 商店调用

function XUiRaceMissionShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, function()
        if cb then
            cb()
        end
        self:UpdateRedDot()
    end, "000000ff")
end

function XUiRaceMissionShop:CheckGoodsBuyPriority(data)
    local priority = data.BuyPriority
    local allGoods = self._Shop.ShopItemList
    for _, goods in pairs(allGoods) do
        local goodsPriority = goods.BuyPriority
        if goodsPriority and goodsPriority < priority then
            local buyTimesLimit, totalBuyTimes = goods.BuyTimesLimit, goods.TotalBuyTimes
            if buyTimesLimit <= 0 and totalBuyTimes <= 0 then
                return false
            end
            if buyTimesLimit > 0 and buyTimesLimit > totalBuyTimes then
                return false
            end
        end
    end
    return true
end

function XUiRaceMissionShop:GetCurShopId()
    return self._CurShopId
end

function XUiRaceMissionShop:RefreshBuy()
    local shopId = self:GetCurShopId()
    self._Shop:UpdateShopShow(shopId)
end

--endregion

function XUiRaceMissionShop:UpdateRedDot()

end

return XUiRaceMissionShop