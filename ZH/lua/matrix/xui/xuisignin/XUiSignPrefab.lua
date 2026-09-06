local XUiSignGridDay = require("XUi/XUiSignIn/XUiSignGridDay")

---@class XUiSignPrefab
local XUiSignPrefab = XClass(nil, "XUiSignPrefab")

function XUiSignPrefab:Ctor(ui, rootUi, parent, setTomorrow)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    ---@type XLuaUi
    self.RootUi = rootUi
    self.Parent = parent
    self.SetTomorrow = setTomorrow

    self.OnBtnHelpClickCb = function() self:OnBtnHelpClick() end
    XTool.InitUiObject(self)
    self:InitAddListen()

    ---@type XUiSignGridDay[]
    self.DaySmallGrids = {}
    table.insert(self.DaySmallGrids, XUiSignGridDay.New(self.GridDaySmall, self.RootUi))
    ---@type XUiSignGridDay[]
    self.DayBigGrids = {}
    table.insert(self.DayBigGrids, XUiSignGridDay.New(self.GridDayBig, self.RootUi))
    ---@type XUiSignGridDay[]
    self.DaySpecialGrids = {}
    if self.GridDaySpecialBig then
        table.insert(self.DaySpecialGrids, XUiSignGridDay.New(self.GridDaySpecialBig, self.RootUi))
    end
    self.BtnList = {}
    table.insert(self.BtnList, self.BtnTab)
end

function XUiSignPrefab:InitAddListen()
    self.RootUi:RegisterClickEvent(self.BtnHelp, self.OnBtnHelpClickCb)
    if self.BtnSkip then
        self.BtnSkip:AddEventListener(handler(self, self.OnBtnSkipClick))
    end
end

function XUiSignPrefab:OnBtnHelpClick()
    XUiManager.UiFubenDialogTip("", self.SignInInfos[1].Description or "")
end

---
--- 福利界面打开时'isShow'为false，打脸打开时为true
function XUiSignPrefab:Refresh(signId, round, isShow)
    self.IsShow = isShow
    self.SignId = signId
    self.Round = round

    local signType = XSignInConfigs.GetSignInType(signId)
    if signType == XSignInConfigs.SignType.PurchasePackage then
        if self.PanelPrice then
            self.PanelPrice.gameObject:SetActiveEx(false)
        end
        if self.BtnPurchase then
            self.BtnPurchase.gameObject:SetActiveEx(false)
        end
        if self.OffShelf then
            self.OffShelf.gameObject:SetActiveEx(false)
        end
        if self.PanelPurchaseLimit then
            self.PanelPurchaseLimit.gameObject:SetActiveEx(false)
        end
        if self.PanelPurchaseRemain then
            self.PanelPurchaseRemain.gameObject:SetActiveEx(false)
        end
        if not isShow then
            self:SetBtnReceiveDisable()
        end
    end

    local timeId = XSignInConfigs.GetSignTimeId(signId)
    local beginTimeStamp, endTimeStamp = XFunctionManager.GetTimeByTimeId(timeId)
    self:SetSignTime(self.BeginTime, beginTimeStamp,"MM/dd")
    self:SetSignTime(self.EndTime1, endTimeStamp,"MM/dd")
    self:SetSignTime(self.EndTime2, endTimeStamp,"HH:mm")

    self:InitTabGroup()
    self:ShowSkip()
    self:RefreshSkipRedPoint()
end

---
--- 设置签到时间
---@param textComponent userdata 字符串控件
---@param timeStamp number 时间戳
---@param format string 显示的格式
function XUiSignPrefab:SetSignTime(textComponent, timeStamp, format)
    if not textComponent then
        return
    end

    local timeStr = XTime.TimestampToGameDateTimeString(timeStamp, format)
    if timeStr then
        textComponent.text = timeStr
    else
        XLog.Error("XUiSignPrefab:SetSignTime函数错误，formatTimeStr为空")
    end
end

function XUiSignPrefab:InitTabGroup()
    for _, v in ipairs(self.BtnList) do
        v.gameObject:SetActiveEx(false)
    end

    self.SignInInfos = XSignInConfigs.GetSignInInfos(self.SignId)
    self:SetRewardInfos(self.Round)
    if #self.SignInInfos <= 1 then
        return
    end

    local btnGroupList = {}
    for i = 1, #self.SignInInfos do
        local grid = self.BtnList[i]
        if not grid then
            grid = CS.UnityEngine.Object.Instantiate(self.BtnTab.gameObject)
            grid.transform:SetParent(self.PanelTabContent.gameObject.transform, false)
            table.insert(self.BtnList, grid)
        end
        local xBtn = grid.transform:GetComponent("XUiButton")
        local rowImg = XUiHelper.TryGetComponent(grid.transform, "RImgIcon", "RawImage")

        table.insert(btnGroupList, xBtn)
        xBtn:SetName(self.SignInInfos[i].RoundName)
        rowImg:SetRawImage(self.SignInInfos[i].Icon)
        xBtn.gameObject:SetActiveEx(true)
    end

    self.PanelTabContent:Init(btnGroupList, function(index)
        self:SelectPanelRound(index)
    end)

    local curRound = XDataCenter.SignInManager.GetSignRound(self.SignId, true)
    if curRound then
        self.PanelTabContent:SelectIndex(curRound, false)
    end
end

function XUiSignPrefab:SelectPanelRound(index)
    self.Parent:RefreshPanel(index)
end

function XUiSignPrefab:SetRewardInfos(index)
    local signInInfo = self.SignInInfos[index]
    local rewardConfigs = XSignInConfigs.GetSignInRewardConfigs(self.SignId, signInInfo.Round, false)

    for _, v in ipairs(self.DaySmallGrids) do
        v.GameObject:SetActiveEx(false)
    end

    for _, v in ipairs(self.DayBigGrids) do
        v.GameObject:SetActiveEx(false)
    end

    for _, v in ipairs(self.DaySpecialGrids) do
        v.GameObject:SetActiveEx(false)
    end

    local smallIndex = 1
    local bigIndex = 1
    local specialIndex = 1

    for _, config in ipairs(rewardConfigs) do
        if config.IsGrandPrix then                          -- 设置大奖励
            local dayGrid = self.DayBigGrids[bigIndex]
            if not dayGrid then
                local grid = CS.UnityEngine.GameObject.Instantiate(self.GridDayBig)
                grid.transform:SetParent(self.PanelDayContent, false)
                dayGrid = XUiSignGridDay.New(grid, self.RootUi)
                table.insert(self.DayBigGrids, dayGrid)
            end

            dayGrid:Refresh(config, self.IsShow, self.SetTomorrow)
            dayGrid.Transform:SetAsLastSibling()
            bigIndex = bigIndex + 1
        elseif config.IsSpecialPrix then                     -- 设置特殊奖励（第三种奖励样式）
            if not self.GridDaySpecialBig then
                XLog.Error(string.format("XUiSignPrefab:SetRewardInfos 配置了IsSpecialPrix特殊奖励，但当前预制无GridDaySpecialBig槽位，signId=%s", tostring(self.SignId)))
            else
                local dayGrid = self.DaySpecialGrids[specialIndex]
                if not dayGrid then
                    local grid = CS.UnityEngine.GameObject.Instantiate(self.GridDaySpecialBig)
                    grid.transform:SetParent(self.PanelDayContent, false)
                    dayGrid = XUiSignGridDay.New(grid, self.RootUi)
                    table.insert(self.DaySpecialGrids, dayGrid)
                end

                dayGrid:Refresh(config, self.IsShow, self.SetTomorrow)
                dayGrid.Transform:SetAsLastSibling()
                specialIndex = specialIndex + 1
            end
        else                                                -- 设置小奖励
            local dayGrid = self.DaySmallGrids[smallIndex]
            if not dayGrid then
                local grid = CS.UnityEngine.GameObject.Instantiate(self.GridDaySmall)
                grid.transform:SetParent(self.PanelDayContent, false)
                dayGrid = XUiSignGridDay.New(grid, self.RootUi)
                table.insert(self.DaySmallGrids, dayGrid)
            end

            dayGrid:Refresh(config, self.IsShow, self.SetTomorrow)
            dayGrid.Transform:SetAsLastSibling()
            smallIndex = smallIndex + 1
        end
    end
end

function XUiSignPrefab:SetTomorrowOpen(dayRewardConfig, isRoundLastDay)
    local t = XSignInConfigs.GetSignInConfig(dayRewardConfig.SignId)
    local isActive = t.Type == XSignInConfigs.SignType.Activity

    if isRoundLastDay and isActive then
        for _, v in ipairs(self.DaySmallGrids) do
            if v.GameObject.activeSelf and v.Config and
               v.Config.SignId == dayRewardConfig.SignId and
               v.Config.Round == dayRewardConfig.Round + 1 and
               v.Config.Day == 1 then
                v:SetTomorrow()
                return
            end
        end

        for _, v in ipairs(self.DayBigGrids) do
            if v.GameObject.activeSelf and v.Config and
                v.Config.SignId == dayRewardConfig.SignId and
                v.Config.Round == dayRewardConfig.Round + 1 and
                v.Config.Day == 1 then
                v:SetTomorrow()
                return
            end
        end

        for _, v in ipairs(self.DaySpecialGrids) do
            if v.GameObject.activeSelf and v.Config and
                    v.Config.SignId == dayRewardConfig.SignId and
                    v.Config.Round == dayRewardConfig.Round + 1 and
                    v.Config.Day == 1 then
                v:SetTomorrow()
                return
            end
        end

        return
    end

    for _, v in ipairs(self.DaySmallGrids) do
       if v.GameObject.activeSelf and v.Config and
          v.Config.SignId == dayRewardConfig.SignId and
          v.Config.Round == dayRewardConfig.Round and
          v.Config.Day - 1 == dayRewardConfig.Day then
            v:SetTomorrow()
            return
        end
    end

    for _, v in ipairs(self.DayBigGrids) do
        if v.GameObject.activeSelf and v.Config and
           v.Config.SignId == dayRewardConfig.SignId and
           v.Config.Round == dayRewardConfig.Round and
           v.Config.Day - 1 == dayRewardConfig.Day then
            v:SetTomorrow()
            return
        end
    end
end

function XUiSignPrefab:SetBtnReceiveDisable()
    if self.BtnReceive then
        self.BtnReceive:SetButtonState(XUiButtonState.Disable)
    end
end


function XUiSignPrefab:SetSignActive(active, round)
    if active and self.GameObject.activeSelf then
        return
    end

    if not active and not self.GameObject.activeSelf then
        return
    end

    if #self.SignInInfos > 1 then
        self.PanelTabContent:SelectIndex(round, false)
    end

    self.GameObject:SetActiveEx(active)
end

function XUiSignPrefab:SetTomorrowForce(isForce)
    self.SetTomorrow = isForce
end

function XUiSignPrefab:ShowSkip()
    self:RemoveSkipTimer()
    self.IsSkipOpen = false

    if XTool.UObjIsNil(self.BtnSkip) or XTool.UObjIsNil(self.TxtSkip) then
        self:RefreshSkipRedPointDisplay()
        return
    end

    local signInCfg = XSignInConfigs.GetSignInConfig(self.SignId)
    self.SkipTimeId = signInCfg.SkipTimeId
    self.SkipId = signInCfg.SkipId

    local endTime = XFunctionManager.GetEndTimeByTimeId(self.SkipTimeId)
    if XTime.GetServerNowTimestamp() > endTime then
        --跳转入口已关闭
        self.BtnSkip:SetDisable(true, false)
        self.TxtSkip.gameObject:SetActiveEx(false)
        self:RefreshSkipRedPointDisplay()
        return
    end

    local startTime = XFunctionManager.GetStartTimeByTimeId(self.SkipTimeId)
    local nowTime = XTime.GetServerNowTimestamp()
    if nowTime >= startTime then
        --跳转入口已开启
        self.IsSkipOpen = true
        self.TxtSkip.text = XUiHelper.GetText("DrawLinkageSkipOpen", XUiHelper.GetTime(endTime - nowTime, XUiHelper.TimeFormatType.DAY_HOUR_MINUTE))
    else
        --跳转入口未开启
        self.TxtSkip.text = XUiHelper.GetText("DrawLinkageSkipClose", XUiHelper.GetTime(startTime - nowTime, XUiHelper.TimeFormatType.DAY_HOUR_MINUTE))
    end
    self:RefreshSkipRedPointDisplay()

    self.SkipTimer = XScheduleManager.ScheduleOnce(handler(self, self.ShowSkip), 1000)
end

function XUiSignPrefab:RefreshSkipRedPoint()
    if self.SkipRedPointId then
        self.RootUi:RemoveRedPointEvent(self.SkipRedPointId)
        self.SkipRedPointId = nil
    end

    self.IsSkipRedPoint = false
    self:RefreshSkipRedPointDisplay()
    if XTool.UObjIsNil(self.BtnSkip) then
        return
    end

    local signInCfg = XSignInConfigs.GetSignInConfig(self.SignId)
    local conditions = {}
    for _, conditionName in ipairs(signInCfg.SkipRedPointConditions) do
        local condition = XRedPointConditions.Types[conditionName]
        if condition then
            table.insert(conditions, condition)
        end
    end
    if XTool.IsTableEmpty(conditions) then
        return
    end

    self.SkipRedPointId = self.RootUi:AddRedPointEvent(self.BtnSkip, self.OnSkipRedPoint, self, conditions)
end

function XUiSignPrefab:OnSkipRedPoint(count)
    self.IsSkipRedPoint = count >= 0
    self:RefreshSkipRedPointDisplay()
end

function XUiSignPrefab:RefreshSkipRedPointDisplay()
    if XTool.UObjIsNil(self.BtnSkip) then
        return
    end
    self.BtnSkip:ShowReddot(self.IsSkipOpen and self.IsSkipRedPoint or false)
end

function XUiSignPrefab:RemoveSkipTimer()
    if self.SkipTimer then
        XScheduleManager.UnSchedule(self.SkipTimer)
        self.SkipTimer = nil
    end
end

function XUiSignPrefab:OnBtnSkipClick()
    if not self.IsSkipOpen then
        local startTime = XFunctionManager.GetStartTimeByTimeId(self.SkipTimeId)
        local timeStr = XTime.TimestampToGameDateTimeString(startTime, "yyyy/MM/dd")
        XUiManager.TipErrorWithKey("DrawLinkageSkipUnlockTip", timeStr)
        return
    end
    XFunctionManager.SkipInterface(self.SkipId)
end

return XUiSignPrefab