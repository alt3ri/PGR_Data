local XUiTheatre6ShopPanel = require("XUi/XUiTheatre6/OutSider/Panel/XUiTheatre6ShopPanel")
local XUiTheatre6TaskPanel = require("XUi/XUiTheatre6/OutSider/Panel/XUiTheatre6TaskPanel")
local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")

---@field _Control XTheatre6Control
---@class XUiTheatre6RewardShop : XLuaUi
local XUiTheatre6RewardShop = XLuaUiManager.Register(XLuaUi, "UiTheatre6RewardShop")
local TaskShopType = XEnumConst.Theatre6.TaskShopType

---根据配置判断是商店还是任务
local function GetRewardCfgType(cfg)
    if XTool.IsNumberValid(cfg.ShopId) then
        return TaskShopType.Shop
    end
    return TaskShopType.Task
end

--region 生命周期
function XUiTheatre6RewardShop:OnAwake()
    self.TabIndexDic = {}
    self.FirstTab2IndexDict = {}
    self.TabBtns = {}
    self.SelectIndex = nil
    self._TimerId = nil
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnMainUi:AddEventListener(handler(self, self.OnBtnMainUiClick))
    local itemId = self._Control:GetRewardShopCoin()
    XUiHelper.NewPanelActivityAssetSafe({ itemId }, self.PanelSpecialTool, self, nil, function(_, index)
        XLuaUiManager.Open("UiTheatre6PopupRewardDetail", itemId)
    end)
end

function XUiTheatre6RewardShop:OnStart()
    ---@type XUiTheatre6ShopPanel
    self.UiTheatre6ShopPanel = XUiTheatre6ShopPanel.New(self.PanelItemList, self)
    ---@type XUiTheatre6TaskPanel
    self.UiTheatre6TaskPanel = XUiTheatre6TaskPanel.New(self.PanelTaskStory, self)

    local allShopIdList = self._Control:GetValidShopIdList()
    if XTool.IsTableEmpty(allShopIdList) then
        self:_OnShopValidInfoReady()
    else
        XShopManager.RequestShopValidInfo(allShopIdList, function()
            self:_OnShopValidInfoReady()
        end)
    end
end

function XUiTheatre6RewardShop:_OnShopValidInfoReady()
    self:InitTags()
    self:UpdateRedDot()
    if XTool.IsTableEmpty(self.TabBtns) then
        return
    end
    local shopIdList = self:_GetOpenShopIdList()
    if XTool.IsTableEmpty(shopIdList) then
        self.BtnTabGroup:SelectIndex(self.SelectIndex, true)
    else
        XShopManager.GetShopInfoList(shopIdList, function()
            self.BtnTabGroup:SelectIndex(self.SelectIndex, true)
        end, XShopManager.ActivityShopType.Theatre6Shop, true)
    end
end

---获取已开启的商店ID列表
function XUiTheatre6RewardShop:_GetOpenShopIdList()
    local allShopIdList = self._Control:GetValidShopIdList()
    local openShopIds = {}
    for _, shopId in ipairs(allShopIdList) do
        if XShopManager.IsShopOpen(shopId) then
            table.insert(openShopIds, shopId)
        end
    end
    return openShopIds
end

function XUiTheatre6RewardShop:OnEnable()
    --self:RefreshResourceBar()
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.UpdateRedDot, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateRedDot, self)
    self:StartTotalTimer()
end

function XUiTheatre6RewardShop:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.UpdateRedDot, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateRedDot, self)
    self:StopTotalTimer()
end

function XUiTheatre6RewardShop:OnDestroy()
    self:StopTimer()
    self.TabIndexDic = nil
    self.TabBtns = nil
    self.SelectIndex = nil
    self._TimerId = nil
end
--endregion

--region 页签管理
function XUiTheatre6RewardShop:InitTags()
    local firstTags = { TaskShopType.Shop, TaskShopType.Task }
    self.TabIndexDic = {}
    self.FirstTab2IndexDict = {}
    self.TabBtns = {}
    local btnIndex = 0

    self.TimelimitIds = {}

    for _, taskShopType in pairs(firstTags) do
        local secondTagCfgs = self._Control:GetValidShopOrTaskList(taskShopType)
        if not XTool.IsTableEmpty(secondTagCfgs) then
            --过滤掉未开启的限时商店
            local validCfgs = {}
            for _, rewardCfg in ipairs(secondTagCfgs) do
                if taskShopType == TaskShopType.Shop then
                    if XTool.IsNumberValid(rewardCfg.ShopId) and XShopManager.IsShopOpen(rewardCfg.ShopId) then
                        table.insert(validCfgs, rewardCfg)
                    end
                else
                    table.insert(validCfgs, rewardCfg)
                end
            end

            if not XTool.IsTableEmpty(validCfgs) then
                local btn = XUiHelper.Instantiate(self.BtnTab1, self.BtnTab1.transform.parent)
                btn.gameObject:SetActiveEx(true)
                btn:SetName(self._Control:GetTaskShopTagName(taskShopType))

                local uiButton = btn:GetComponent("XUiButton")
                table.insert(self.TabBtns, uiButton)
                btnIndex = btnIndex + 1
                self.FirstTab2IndexDict[taskShopType] = btnIndex

                local firstIndex = btnIndex
                for _, rewardCfg in ipairs(validCfgs) do
                    local tmpBtn = XUiHelper.Instantiate(self.BtnChild01, self.BtnChild01.transform.parent)
                    tmpBtn:SetName(rewardCfg.Name)
                    tmpBtn.gameObject:SetActiveEx(true)

                    local tmpUiButton = tmpBtn:GetComponent("XUiButton")
                    tmpUiButton.SubGroupIndex = firstIndex
                    table.insert(self.TabBtns, tmpUiButton)
                    btnIndex = btnIndex + 1

                    self.TabIndexDic[btnIndex] = rewardCfg

                    if XTool.IsNumberValid(rewardCfg.TaskTimeLimitId) then
                        self.TimelimitIds[rewardCfg.TaskTimeLimitId] = true
                    end
                end
            end
        end
    end
    self.BtnTab1.gameObject:SetActiveEx(false)
    self.BtnChild01.gameObject:SetActiveEx(false)
    self.BtnTabGroup:Init(self.TabBtns, function(index)
        self:OnSelectedTag(index)
    end)
    self.SelectIndex = 1
end

function XUiTheatre6RewardShop:RemoveTag(taskShopId)
    for btnIndex, taskShopCfg in pairs(self.TabIndexDic) do
        if taskShopCfg.Id == taskShopId then
            local uiButtonList = self.BtnTabGroup:RemoveButton(btnIndex)
            if uiButtonList then
                for _, uiButton in pairs(uiButtonList) do
                    uiButton.gameObject:SetActiveEx(false)
                    local isin, index = table.contains(self.TabBtns, uiButton)
                    table.remove(self.TabBtns, index)
                end
            end
        end
    end
end

function XUiTheatre6RewardShop:ClearTags()
    for i = 1, #self.TabBtns do
        self.TabBtns[i].gameObject:SetActiveEx(false)
        CS.UnityEngine.GameObject.Destroy(self.TabBtns[i].gameObject)
    end
    self.BtnTabGroup.TabBtnList:Clear()
end

function XUiTheatre6RewardShop:OnSelectedTag(index)
    self.SelectIndex = index
    local rewardCfg = self.TabIndexDic[index]
    if not rewardCfg then
        return
    end
    local cfgType = GetRewardCfgType(rewardCfg)
    self.UiTheatre6ShopPanel:SetVisible(cfgType == TaskShopType.Shop)
    self.UiTheatre6TaskPanel:SetVisible(cfgType == TaskShopType.Task)
    if cfgType == TaskShopType.Shop then
        self.UiTheatre6ShopPanel:UpdateShopShow(rewardCfg.ShopId, true)
        self._Control:RemoveShopNewReddot(rewardCfg)
        self.TxtTitle.text=XUiHelper.GetText("Theatre6Shop")
        self:UpdateRedDot()
    else
        local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(rewardCfg.TaskTimeLimitId)
        local taskIds = taskTimeLimitCfg and taskTimeLimitCfg.TaskId or {}
        self.UiTheatre6TaskPanel:UpdateTaskShow(taskIds)
        self._Control:RemoveTaskNewReddot(rewardCfg)
        self.TxtTitle.text=XUiHelper.GetText("Theatre6Task")
        self:UpdateRedDot()
    end
    self:StartTimer(rewardCfg)
end
--endregion

--region 单页签定时器
function XUiTheatre6RewardShop:StartTimer(rewardCfg)
    self:StopTimer()
    if not XTool.IsNumberValid(rewardCfg.TaskTimeLimitId) then
        self.TxtTime.gameObject:SetActiveEx(false)
        return
    end

    local timeLimitId = XTaskConfig.GetTimeLimitTaskCfg(rewardCfg.TaskTimeLimitId)
    if not timeLimitId or not XTool.IsNumberValid(timeLimitId.TimeId) then
        self.TxtTime.gameObject:SetActiveEx(false)
        return
    end

    local timeId = timeLimitId.TimeId
    if not XFunctionManager.CheckInTimeByTimeId(timeId) then
        self.TxtTime.gameObject:SetActiveEx(false)
        return
    end

    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    if endTime <= 0 then
        self.TxtTime.gameObject:SetActiveEx(false)
        return
    end

    self.TxtTime.gameObject:SetActiveEx(true)
    self:UpdateTime(timeId)
    self._TimerId = XScheduleManager.ScheduleForever(function()
        self:UpdateTime(timeId)
    end, XScheduleManager.SECOND)
end

function XUiTheatre6RewardShop:StopTimer()
    if self._TimerId then
        XScheduleManager.UnSchedule(self._TimerId)
        self._TimerId = nil
    end
end

function XUiTheatre6RewardShop:UpdateTime(timeId)
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    if endTime <= 0 then
        self:StopTimer()
        return
    end

    local now = XTime.GetServerNowTimestamp()
    local leftTime = math.max(endTime - now, 0)

    self.TxtTime.text = XUiHelper.GetText("Theatre6TaskShopTimeLabel", XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    if leftTime <= 0 then
        self:StopTimer()
        self:OnSelectedTag(self.SelectIndex)
    end
end
--endregion

--region 全局过期定时器
function XUiTheatre6RewardShop:StartTotalTimer()
    if XTool.IsTableEmpty(self.TimelimitIds) then
        return
    end
    self:StopTotalTimer()
    self:UpdateTotalTimer()
    self._TotalTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateTotalTimer), XScheduleManager.SECOND)
end

function XUiTheatre6RewardShop:StopTotalTimer()
    if self._TotalTimerId then
        XScheduleManager.UnSchedule(self._TotalTimerId)
        self._TotalTimerId = nil
    end
end

function XUiTheatre6RewardShop:UpdateTotalTimer()
    local endTimeId = nil

    for id, v in pairs(self.TimelimitIds) do
        if not XFunctionManager.CheckInTimeByTimeId(id, true) then
            if endTimeId == nil then
                endTimeId = {}
            end
            table.insert(endTimeId, id)
        end
    end

    if not XTool.IsTableEmpty(endTimeId) then
        for i = 1, #endTimeId do
            self.TimelimitIds[endTimeId[i]] = nil
        end

        local oldSelectIndex = self.SelectIndex
        self:ClearTags()
        self:InitTags()

        local newSelectIndex = math.min(oldSelectIndex, self.BtnTabGroup.TabBtnList.Count)
        self.BtnTabGroup:SelectIndex(newSelectIndex)

        XUiManager.TipMsg(self._Control:GetClientConfigTaskShopUpdateTips())
        --self:RefreshResourceBar()
    end
end
--endregion

--region 货币栏
--function XUiTheatre6RewardShop:RefreshResourceBar()
--    local latestCoinIds = self._Control:GetTheatre6CoinIds()
--
--    if not self.AssetActivityPanel then
--        self._ResourceBarCoins = latestCoinIds
--        ---@type XUiPanelActivityAsset
--        self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
--        for i = 1, #self._ResourceBarCoins do
--            self.AssetActivityPanel:SetButtonCb(i, function()
--                self:CustomCurrencyClick(i)
--            end)
--        end
--    else
--        if #self._ResourceBarCoins ~= #latestCoinIds then
--            for i = 1, #latestCoinIds do
--                self.AssetActivityPanel:SetButtonCb(i, function()
--                    self:CustomCurrencyClick(i)
--                end)
--            end
--        end
--        self._ResourceBarCoins = latestCoinIds
--    end
--
--    XDataCenter.ItemManager.RemoveCountUpdateListener(self.AssetActivityPanel)
--    self.AssetActivityPanel:Refresh(self._ResourceBarCoins)
--    XDataCenter.ItemManager.AddCountUpdateListener(self._ResourceBarCoins, handler(self, self.UpdateAssetPanel), self.AssetActivityPanel)
--end

--function XUiTheatre6RewardShop:CustomCurrencyClick(index)
--    local itemId = self._ResourceBarCoins[index]
--    if XTool.IsNumberValid(itemId) then
--        self._Control:UiTip(itemId)
--    end
--end

--function XUiTheatre6RewardShop:UpdateAssetPanel()
--    self.AssetActivityPanel:Refresh(self._ResourceBarCoins)
--end
--endregion

--region 购买 & 导航
function XUiTheatre6RewardShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, function()
        if cb then
            cb()
        end
        self:UpdateRedDot()
    end, "000000ff")
end

function XUiTheatre6RewardShop:GetCurShopId()
    local taskShopCfg = self.TabIndexDic[self.SelectIndex]
    return taskShopCfg.ShopId
end

function XUiTheatre6RewardShop:RefreshBuy()
    local shopId = self:GetCurShopId()
    self.UiTheatre6ShopPanel:UpdateShopShow(shopId)
end

function XUiTheatre6RewardShop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end
--endregion

--region 红点
function XUiTheatre6RewardShop:UpdateRedDot()
    local firstTagRedDict = {}
    for index, config in pairs(self.TabIndexDic) do
        local isRed = false
        local cfgType = GetRewardCfgType(config)
        if cfgType == TaskShopType.Task then
            local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(config.TaskTimeLimitId)
            if taskTimeLimitCfg and taskTimeLimitCfg.TaskId then
                for _, taskId in pairs(taskTimeLimitCfg.TaskId) do
                    if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                        isRed = true
                        break
                    end
                end
            end
            if not isRed then
                if self._Control:CheckNewTaskByTaskConfig(config) then
                    isRed = true
                end
            end
        elseif cfgType == TaskShopType.Shop then
            if self._Control:CheckShopNewGoodsByShopConfig(config) then
                isRed = true
            end
        end

        if isRed then
            firstTagRedDict[cfgType] = true
        end

        local button = self.TabBtns[index]
        if button then
            button:ShowReddot(isRed)
        end
    end

    for type, _ in pairs(self.FirstTab2IndexDict) do
        local btnIndex = self.FirstTab2IndexDict[type]
        local button = self.TabBtns[btnIndex]
        if button then
            button:ShowReddot(firstTagRedDict[type])
        end
    end
end
--endregion

return XUiTheatre6RewardShop
