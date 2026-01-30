local XUiTheatre5ShopPanel = require("XUi/XUiTheatre5/XUiTheatre5RewardShop/XUiTheatre5ShopPanel")
local XUiTheatre5TaskPanel = require("XUi/XUiTheatre5/XUiTheatre5RewardShop/XUiTheatre5TaskPanel")
local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")

---@field _Control XTheatre5Control
---@class XUiTheatre5RewardShop : XLuaUi
local XUiTheatre5RewardShop = XLuaUiManager.Register(XLuaUi, "UiTheatre5RewardShop")

function XUiTheatre5RewardShop:OnAwake()
    self.TabIndexDic = {}
    self.FirstTab2IndexDict = {}
    self.TabBtns = {}
    self.SelectIndex = nil
    self._TimerId = nil
    self:RegisterClickEvent(self.BtnBack, self.Close, true)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick, true)

end

function XUiTheatre5RewardShop:OnStart()
    self:InitTags()
    self:UpdateRedDot()
    ---@type XUiTheatre5ShopPanel
    self.UiTheatre5ShopPanel = XUiTheatre5ShopPanel.New(self.PanelItemList, self)
    ---@type XUiTheatre5TaskPanel
    self.UiTheatre5TaskPanel = XUiTheatre5TaskPanel.New(self.PanelTaskStory, self)
    local shopIdList = self._Control:GetValidShopIdlist()
    if XTool.IsTableEmpty(shopIdList) then
        self.BtnTabGroup:SelectIndex(self.SelectIndex, true)
    else
        XShopManager.GetShopInfoList(shopIdList, function()
            self.BtnTabGroup:SelectIndex(self.SelectIndex, true)
        end, XShopManager.ActivityShopType.Theatre5Shop, true)
    end
end

function XUiTheatre5RewardShop:OnEnable()
    self:RefreshResourceBar()

    XEventManager.AddEventListener(XEventId.EVENT_FINISH_TASK, self.UpdateRedDot, self)
    XEventManager.AddEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateRedDot, self)
    
    self:StartTotalTimer()
end

function XUiTheatre5RewardShop:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_TASK, self.UpdateRedDot, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FINISH_MULTI, self.UpdateRedDot, self)
    
    self:StopTotalTimer()
end

function XUiTheatre5RewardShop:RefreshResourceBar()
    local latestCoinIds = self._Control:GetTheatre5CoinIds()

    if not self.AssetActivityPanel then
        self._ResourceBarCoins = latestCoinIds

        ---@type XUiPanelActivityAsset
        self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
        for i = 1, #self._ResourceBarCoins do
            self.AssetActivityPanel:SetButtonCb(i, function()
                self:CustomCurrencyClick(i)
            end)
        end
    else
        -- 如果货币数量发生了变化，需要重新设置点击回调
        if #self._ResourceBarCoins ~= #latestCoinIds then
            for i = 1, #latestCoinIds do
                self.AssetActivityPanel:SetButtonCb(i, function()
                    self:CustomCurrencyClick(i)
                end)
            end
        end

        self._ResourceBarCoins = latestCoinIds
    end

    XDataCenter.ItemManager.RemoveCountUpdateListener(self.AssetActivityPanel)
    self.AssetActivityPanel:Refresh(self._ResourceBarCoins)
    XDataCenter.ItemManager.AddCountUpdateListener(self._ResourceBarCoins, handler(self, self.UpdateAssetPanel), self.AssetActivityPanel)
end

function XUiTheatre5RewardShop:CustomCurrencyClick(index)
    local itemId = self._ResourceBarCoins[index]
    if XTool.IsNumberValid(itemId) then
        XLuaUiManager.Open("UiTheatre5PopupRewardDetail", itemId, XMVCA.XTheatre5.EnumConst.ItemType.Common)
    end
end

function XUiTheatre5RewardShop:InitTags()
    local firstTags = { XMVCA.XTheatre5.EnumConst.TaskShopType.Shop, XMVCA.XTheatre5.EnumConst.TaskShopType.Task }
    self.TabIndexDic = {}
    self.FirstTab2IndexDict = {}
    self.TabBtns = {}
    local btnIndex = 0
    
    self.TimelimitIds = {}

    --一级标题
    for _, taskShopType in pairs(firstTags) do
        local secondTagCfgs = self._Control:GetValidShopOrTaskList(taskShopType)
        if not XTool.IsTableEmpty(secondTagCfgs) then
            local btn = XUiHelper.Instantiate(self.BtnTab1, self.BtnTab1.transform.parent)
            btn.gameObject:SetActiveEx(true)
            btn:SetName(self._Control:GetTaskShopTagName(taskShopType))

            local uiButton = btn:GetComponent("XUiButton")
            table.insert(self.TabBtns, uiButton)
            btnIndex = btnIndex + 1
            self.FirstTab2IndexDict[taskShopType] = btnIndex

            --二级标题
            local firstIndex = btnIndex
            for _, taskShopCfg in ipairs(secondTagCfgs) do
                local tmpBtn = XUiHelper.Instantiate(self.BtnChild01, self.BtnChild01.transform.parent)
                tmpBtn:SetName(taskShopCfg.Name)
                tmpBtn.gameObject:SetActiveEx(true)

                local tmpUiButton = tmpBtn:GetComponent("XUiButton")
                tmpUiButton.SubGroupIndex = firstIndex
                table.insert(self.TabBtns, tmpUiButton)
                btnIndex = btnIndex + 1

                self.TabIndexDic[btnIndex] = taskShopCfg

                -- 收集所有时间用于界面过时检测
                if XTool.IsNumberValidEx(taskShopCfg.TimeLimitId) then
                    self.TimelimitIds[taskShopCfg.TimeLimitId] = true
                elseif XTool.IsNumberValidEx(taskShopCfg.TaskTimeLimitId) then
                    self.TimelimitIds[taskShopCfg.TaskTimeLimitId] = true
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

function XUiTheatre5RewardShop:RemoveTag(taskShopId)
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

--- 清除所有页签，用于重新初始化
function XUiTheatre5RewardShop:ClearTags()
    for i = 1, #self.TabBtns do
        self.TabBtns[i].gameObject:SetActiveEx(false)
        CS.UnityEngine.GameObject.Destroy(self.TabBtns[i].gameObject)
    end
    
    self.BtnTabGroup.TabBtnList:Clear()
end

function XUiTheatre5RewardShop:OnSelectedTag(index)
    self.SelectIndex = index
    local taskShopCfg = self.TabIndexDic[index]
    if not taskShopCfg then
        return
    end
    self.UiTheatre5ShopPanel:SetVisible(taskShopCfg.Type == XMVCA.XTheatre5.EnumConst.TaskShopType.Shop)
    self.UiTheatre5TaskPanel:SetVisible(taskShopCfg.Type == XMVCA.XTheatre5.EnumConst.TaskShopType.Task)
    if taskShopCfg.Type == XMVCA.XTheatre5.EnumConst.TaskShopType.Shop then
        local shopId
        if XFunctionManager.CheckInTimeByTimeId(taskShopCfg.TimeLimitId, true) then
            shopId = taskShopCfg.ShopId
        end
        self.UiTheatre5ShopPanel:UpdateShopShow(shopId, true)
        self._Control:RemoveShopNewReddot(taskShopCfg)
        self:UpdateRedDot()
    else
        local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(taskShopCfg.TaskTimeLimitId)
        if taskTimeLimitCfg then
            local taskIds = XFunctionManager.CheckInTimeByTimeId(taskShopCfg.TimeLimitId, true) and taskTimeLimitCfg.TaskId or {}
            self.UiTheatre5TaskPanel:UpdateTaskShow(taskIds)
        end
        self._Control:RemoveTaskNewReddot(taskShopCfg)
        self:UpdateRedDot()
    end
    self:StartTimer(taskShopCfg)
end

--region 单个页签的定时器

function XUiTheatre5RewardShop:StartTimer(taskShopCfg)
    self:StopTimer()
    if not XTool.IsNumberValid(taskShopCfg.TimeLimitId) then
        self.TxtTime.gameObject:SetActiveEx(false)
        return
    end

    if not XFunctionManager.CheckInTimeByTimeId(taskShopCfg.TimeLimitId) then
        self.TxtTime.gameObject:SetActiveEx(false)
        return
    end

    --常驻的不显示
    local endTime = XFunctionManager.GetEndTimeByTimeId(taskShopCfg.TimeLimitId)
    if endTime <= 0 then
        self.TxtTime.gameObject:SetActiveEx(false)
        return
    end

    self.TxtTime.gameObject:SetActiveEx(true)
    self:UpdateTime(taskShopCfg)
    self._TimerId = XScheduleManager.ScheduleForever(function()
        self:UpdateTime(taskShopCfg)
    end, XScheduleManager.SECOND)
end

function XUiTheatre5RewardShop:StopTimer()
    if self._TimerId then
        XScheduleManager.UnSchedule(self._TimerId)
        self._TimerId = nil
    end
end

function XUiTheatre5RewardShop:UpdateTime(taskShopCfg)
    local endTime = XFunctionManager.GetEndTimeByTimeId(taskShopCfg.TimeLimitId)

    if endTime <= 0 then
        self:StopTimer()
        return
    end

    local now = XTime.GetServerNowTimestamp()
    local leftTime = math.max(endTime - now, 0)

    if self.TxtTime then
        self.TxtTime.text = XUiHelper.FormatText(self._Control:GetClientConfigTaskShopTimeLabel(),
                XUiHelper.GetTime(leftTime, XUiHelper.TimeFormatType.ACTIVITY))
    end
    if leftTime <= 0 then
        self:StopTimer()
        --刷新下
        self:OnSelectedTag(self.SelectIndex)
    end
end

--endregion

--region 整个界面的定时器

function XUiTheatre5RewardShop:StartTotalTimer()
    if XTool.IsTableEmpty(self.TimelimitIds) then
        return
    end
    
    self:StopTotalTimer()
    
    self:UpdateTotalTimer()
    self._TotalTimerId = XScheduleManager.ScheduleForever(handler(self, self.UpdateTotalTimer), XScheduleManager.SECOND)
end

function XUiTheatre5RewardShop:StopTotalTimer()
    if self._TotalTimerId then 
        XScheduleManager.UnSchedule(self._TotalTimerId)
        self._TotalTimerId = nil
    end
end

function XUiTheatre5RewardShop:UpdateTotalTimer()
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
        -- 存在某个页签的timeId过期了
        for i = 1, #endTimeId do
            self.TimelimitIds[endTimeId[i]] = nil
        end
        
        local oldSelectIndex = self.SelectIndex
        
        -- 因为触发频率不高，直接重新初始化页签
        self:ClearTags()
        self:InitTags()
        
        -- 重新选择
        local newSelectIndex = math.min(oldSelectIndex, self.BtnTabGroup.TabBtnList.Count)
        
        self.BtnTabGroup:SelectIndex(newSelectIndex)
        
        XUiManager.TipMsg(self._Control:GetClientConfigTaskShopUpdateTips())
        
        -- 刷新货币
        self:RefreshResourceBar()
    end
end

--endregion

function XUiTheatre5RewardShop:UpdateAssetPanel()
    self.AssetActivityPanel:Refresh(self._ResourceBarCoins)
end

function XUiTheatre5RewardShop:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiTheatre5RewardShop:UpdateBuy(data, cb)
    XLuaUiManager.Open("UiShopItem", self, data, function()
        if cb then
            cb()
        end
        self:UpdateRedDot()
    end, "000000ff")
end

function XUiTheatre5RewardShop:GetCurShopId()
    local taskShopCfg = self.TabIndexDic[self.SelectIndex]
    return taskShopCfg.ShopId
end

function XUiTheatre5RewardShop:RefreshBuy()
    local shopId = self:GetCurShopId()
    self.UiTheatre5ShopPanel:UpdateShopShow(shopId)
end

function XUiTheatre5RewardShop:OnDestroy()
    self:StopTimer()
    self.TabIndexDic = nil
    self.TabBtns = nil
    self.SelectIndex = nil
    self._TimerId = nil
end

function XUiTheatre5RewardShop:UpdateRedDot()
    local firstTagRedDict = {}
    for index, config in pairs(self.TabIndexDic) do
        local isRed = false
        if config.Type == XMVCA.XTheatre5.EnumConst.TaskShopType.Task then
            -- 有任务处于可领取状态
            local taskTimeLimitCfg = XTaskConfig.GetTimeLimitTaskCfg(config.TaskTimeLimitId)
            if taskTimeLimitCfg and taskTimeLimitCfg.TaskId then
                for _, taskId in pairs(taskTimeLimitCfg.TaskId) do
                    if XDataCenter.TaskManager.CheckTaskAchieved(taskId) then
                        isRed = true
                        break
                    end
                end
            end
            -- 新增任务
            if not isRed then
                if XMVCA.XTheatre5:CheckNewTaskByTaskConfig(config) then
                    isRed = true
                end
            end
        elseif config.Type == XMVCA.XTheatre5.EnumConst.TaskShopType.Shop then
            -- 新增商店
            if XMVCA.XTheatre5:CheckShopNewGoodsByShopConfig(config) then
                isRed = true
            end
        end

        if isRed then
            firstTagRedDict[config.Type] = true 
        end

        local button = self.TabBtns[index]
        if button then
            button:ShowReddot(isRed)
        else
            XLog.Error("[XUiTheatre5RewardShop] UpdateRedDot: button not exist:" .. index)
        end
    end

    for type, _ in pairs(self.FirstTab2IndexDict) do
        local btnIndex = self.FirstTab2IndexDict[type]
        local button = self.TabBtns[btnIndex]
        if button then
            button:ShowReddot(firstTagRedDict[type])
        else
            XLog.Error("[XUiTheatre5RewardShop] UpdateRedDot: button not exist:" .. btnIndex)
        end
    end
end

return XUiTheatre5RewardShop