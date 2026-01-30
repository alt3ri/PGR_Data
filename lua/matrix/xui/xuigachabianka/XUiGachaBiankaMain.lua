local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
---@class XUiGachaBiankaMain : XLuaUi 比安卡卡池
---@field SafeAreaContentPane UnityEngine.CanvasGroup
---@field _Scene XUiPanelGachaBiankaScene
local XUiGachaBiankaMain = XLuaUiManager.Register(XLuaUi, "UiGachaBianka402Main")

function XUiGachaBiankaMain:OnAwake()
    self._CanPlayEnableAnim = false -- 只有进入卡池时会检测播放1次
    self._IsGachaReturnMain = false -- 是否抽卡后返回卡池主界面
    self._ShowCourseRewardTrigger = nil
    self._DoGachaTrigger = nil -- 抽卡触发器，1/10回抽按钮设置，拨动时钟触发
    self._FinishCbTrigger = nil -- 抽卡结束触发器，抽卡请求回调设置，播放完抽卡演出后触发
    self._GachaAllFinishTrigger = nil -- 抽卡全结束触发器，1/10回抽按钮设置，抽卡结果界面关闭后刷新触发
    self._TipCbTrigger = nil -- 奖励弹框
    self._HasBeenKey = "BiankaHasBeenKey"
    self._SkipBtnKey = "UiGachaBianka"
    self._GachaStoryRedPoint = "GachaStoryRedPoint"
    self._IsCanGacha = true
    self._IsCanGachaClick = true
    ---@type XUiGridCommon[]
    self._GridCourseRewardsDic = {}
    ---@type XUiGridCommon[]
    self._GridBoardRewardsDic = {}
    self._PanelShowDic = {}
    self:InitButton()
end

---@param isPlayEnterAnim boolean 是否播放入场动画
---@param isPlayStoryAnim boolean 是否播放剧情动画
function XUiGachaBiankaMain:OnStart(gachaId, isPlayEnterAnim, isPlayStoryAnim)
    if isPlayEnterAnim == nil then
        isPlayEnterAnim = true
    end
    self._GachaId = gachaId
    ---@type XTableGacha
    self._GachaCfg = XGachaConfigs.GetGachaCfgById(self._GachaId)
    ---@type XUiPanelGachaBiankaVolume
    self._Volume = require("XUi/XUiGachaBianka/Grid/XUiPanelGachaBiankaVolume").New(self.PanelVolume, self)
    self._Volume:HideAll()
    self._Scene = require("XUi/XUiGachaBianka/Grid/XUiPanelGachaBiankaScene").New(self.Transform, self)
    ---@type XUiPanelSwitchableSceneAnim
    self._SwitchableScene = require("XUi/XUiSwitchableScene/Panel/XUiPanelSwitchableSceneAnim").New()
    
    -- 跳过按钮,只有在进入ui时自动刷新1次
    local isSelect = XSaveTool.GetData(self._SkipBtnKey)
    local state = isSelect and CS.UiButtonState.Select or CS.UiButtonState.Normal
    self.BtnSkip:SetButtonState(state)

    if not self._IsGoFight then
        self._CanPlayEnableAnim = isPlayEnterAnim
        self._CanPlayStoryAnim = isPlayStoryAnim
    end

    local timeId = self._GachaCfg.TimeId
    local endTime = XFunctionManager.GetEndTimeByTimeId(timeId)
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose then
            XLuaUiManager.RunMain()
            XUiManager.TipMsg(XUiHelper.GetText("ActivityAlreadyOver"))
        else
            local time = XFunctionManager.GetEndTimeByTimeId(timeId) - XTime.GetServerNowTimestamp()
            self.TxtTime.text = XUiHelper.GetText("GachaBiankaTime", XUiHelper.GetTime(time, XUiHelper.TimeFormatType.CHATEMOJITIMER))
        end
    end, nil, 0)

    self._AnimDisableLong = self:FindTransform("AnimDisableLong")

    -- 资源栏
    local managerItems = XDataCenter.ItemManager.ItemId
    self.AssetPanel = XUiHelper.NewPanelActivityAssetSafe({ managerItems.PaidGem, managerItems.HongKa, self._GachaCfg.ConsumeId }, self.PanelSpecialTool, self)
    self.AssetPanel:SetButtonCb(3, function()
        self:OpenGachaItemShop()
    end)
end

function XUiGachaBiankaMain:OnEnable()
    -- 顺序不能改表
    -- 1.先检测是否需要打开子界面 -- 【需要的话】就不进行enable动画播放 且直接刷新红点
    -- 2.【不需要的话】就开始播放enable动画，且必须在动画播完后再刷新红点
    local isAutoPlayGyro = true
    self._Scene:Init3DSceneInfo()
    self:RefreshUiShow()
    if self._IsGachaReturnMain then
        self.AssetPanel:Open()
        self.GachaButtonsEnable:PlayTimelineAnimation()
        self._Scene:PlayStart1()
    elseif self._CanPlayEnableAnim then
        local isSkip = self:PlayEnableAnim()
        if not isSkip then
            isAutoPlayGyro = false
        end
    else
        if self._CanPlayStoryAnim then
            self._Scene:PlayExitStageLine()
            self:PlayAnimationWithMask("AnimStart2")
        else
            self:PlayAnimationWithMask("AnimStart1")
        end
        self:RefreshReddot()
        self._Scene:SetXPostFaicalControllerActive(true)
    end
    -- 显示获得道具弹框
    if self._TipCbTrigger then
        self._TipCbTrigger()
        self._TipCbTrigger = nil
    end
    self._IsGachaReturnMain = false
    self._CanPlayStoryAnim = false
    if isAutoPlayGyro then
        self._SwitchableScene:AutoPlay(self.UiSceneInfo.Transform)
    end
end

function XUiGachaBiankaMain:OnDisable()
    -- 本地缓存skip按钮状态
    local isSelect = self.BtnSkip:GetToggleState()
    XSaveTool.SaveData(self._SkipBtnKey, isSelect)

    -- 离开界面时关闭视线跟随
    self._Scene:SetXPostFaicalControllerActive(false)
    self._SwitchableScene:Stop()
end

function XUiGachaBiankaMain:OnDestroy()
    self._SwitchableScene:OnDestory()
    self._ShowCourseRewardTrigger = nil
    self._DoGachaTrigger = nil
    if self._UiObtainTimer then
        XScheduleManager.UnSchedule(self._UiObtainTimer)
        self._UiObtainTimer = nil
    end
end

function XUiGachaBiankaMain:Close()
    if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc and self._FinishCbTrigger ~= nil then
        --pc端抽卡时不能通过点击Esc关闭界面
        return
    end
    self.Super.Close(self)
end

-- 记录战斗前后数据
function XUiGachaBiankaMain:OnReleaseInst()
    return {
        IsGoFight = true,
        CanPlayEnableAnim = self._CanPlayEnableAnim,
    }
end

function XUiGachaBiankaMain:OnResume(data)
    data = data or {}
    self._IsGoFight = data.IsGoFight
    self._CanPlayEnableAnim = data.CanPlayEnableAnim
end

function XUiGachaBiankaMain:InitButton()
    self:RegisterClickEvent(self.BtnBack, self.Close)
    self:RegisterClickEvent(self.BtnMainUi, function()
        if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc and self._FinishCbTrigger ~= nil then
            --pc端抽卡时不能通过点击Home回到主界面
            return
        end
        XLuaUiManager.RunMain()
    end)
    self:RegisterClickEvent(self.BtnGacha, function()
        self:OnBtnGachaClick(self._GachaCfg.BtnGachaCount[1])
    end)
    self:RegisterClickEvent(self.BtnGacha2, function()
        self:OnBtnGachaClick(self._GachaCfg.BtnGachaCount[2])
    end)
    self:RegisterClickEvent(self.BtnSkipGacha, self.OnBtnSkipGachaClick)
    self:RegisterClickEvent(self.BtnStoryLine, function()
        self:OnBtnStoryLineClick()
    end)
    self:RegisterClickEvent(self.BtnAward, function()
        XLuaUiManager.Open("UiGachaBianka402Log", self._GachaCfg, 1)
    end)
    self:RegisterClickEvent(self.BtnHelp, function()
        XLuaUiManager.Open("UiGachaBianka402Log", self._GachaCfg)
    end)
    self:RegisterClickEvent(self.BtnSet, function()
        XLuaUiManager.Open("UiSet")
    end)
end

function XUiGachaBiankaMain:OnChildClose()
    self:RefreshUiShow()
    self:PlayAnimationWithMask("AnimStart1")
    self:RefreshReddot()
    self._Scene:SetXPostFaicalControllerActive(true)
end

function XUiGachaBiankaMain:PlayEnableAnim()
    self._CanPlayEnableAnim = false
    self._Scene:SetXPostFaicalControllerActive(false)

    local isSkip = XSaveTool.GetData(self._SkipBtnKey)
    self._SwitchableScene:IsContinuePlay(isSkip)
    ---- 如果勾了跳过演出 就播放短动画 否则播放长动画
    if isSkip then
        self:RefreshReddot()
        self:PlayShortEnableAnim()
    else
        self:PlayLongEnableAnim()
        local hasBeen = XSaveTool.GetData(self._HasBeenKey)
        if not hasBeen then
            -- 如果第一次进来播长动画，自动勾上跳过
            self.BtnSkip:SetButtonState(CS.UiButtonState.Select)
            XSaveTool.SaveData(self._HasBeenKey, 1)
        end
    end
    return isSkip
end

function XUiGachaBiankaMain:PlayLongEnableAnim()
    self._Volume:PlayStart()
    self:PlayAnimation("AnimEnableLong")
    self.SafeAreaContentPane.blocksRaycasts = false
    self._Scene:PlayEnableLong(function()
        self._Volume:PlayEnd()
        self.SafeAreaContentPane.blocksRaycasts = true
    end, function()
        self._SwitchableScene:AutoPlay(self.UiSceneInfo.Transform)
    end)
end

function XUiGachaBiankaMain:PlayShortEnableAnim()
    self:PlayAnimationWithMask("AnimEnableShort")
    self._Scene:PlayEnableShort()
end

function XUiGachaBiankaMain:RefreshUiShow()
    -- 奖励展示滚动
    local PanelAwardShow = {}
    XTool.InitUiObjectByUi(PanelAwardShow, self.PanelAwardShow)
    local rewardRareLevelList = XDataCenter.GachaManager.GetGachaRewardSplitByRareLevel(self._GachaId)
    for i, group in ipairs(rewardRareLevelList) do
        local Panel = self._PanelShowDic[i]
        if XTool.IsTableEmpty(Panel) then
            Panel = {}
            self._PanelShowDic[i] = Panel
            local panelShowUiTrans = PanelAwardShow["PanelShow" .. i]
            if not panelShowUiTrans then
                break
            end
            XTool.InitUiObjectByUi(Panel, panelShowUiTrans)
        end

        for k, v in pairs(group) do
            local searchIndex = i * 10 + k
            local item = self._GridBoardRewardsDic[searchIndex]
            if not item then
                local uiTrans = k == 1 and Panel.GridRewards or Panel["GridRewards" .. k]
                local fashionId = tonumber(XGachaConfigs.GetClientConfig("WeaponFashionId", self._GachaCfg.CourseRewardId))
                item = XUiGridCommon.New(self, uiTrans)
                item:SetCustomWeaopnFashionId(fashionId, XUiHelper.GetText("GachaBiankaFashionDesc"))
                item:SetCustomItemTip(function(data, hideSkipBtn, rootUiName, lackNum)
                    XLuaUiManager.Open("UiGachaBianka402Tip", data, hideSkipBtn, rootUiName, lackNum)
                end)
                self._GridBoardRewardsDic[searchIndex] = item
            end

            local tmpData = {}
            tmpData.TemplateId = v.Cfg.TemplateId
            tmpData.Count = v.Cfg.Count
            local curCount
            if v.Cfg.RewardType == XGachaConfigs.RewardType.Count then
                curCount = v.CurCount
            end
            item:Refresh(tmpData, nil, nil, nil, curCount)
        end
    end

    -- 历程
    local curTotalGachaTimes = XDataCenter.GachaManager.GetTotalGachaTimes(self._GachaId)
    local courseReward = XGachaConfigs.GetGachaCourseRewardById(self._GachaCfg.CourseRewardId)
    local gachaBuyTicketRuleConfig = XGachaConfigs.GetGachaItemExchangeCfgById(self._GachaCfg.ExchangeId)
    local totaMaxTimes = gachaBuyTicketRuleConfig.TotalBuyCountMax
    curTotalGachaTimes = curTotalGachaTimes >= totaMaxTimes and totaMaxTimes or curTotalGachaTimes -- 分子不能超过分母
    self.TextProgress.text = curTotalGachaTimes .. "/" .. totaMaxTimes
    local Notes = {}
    for i = 1, #courseReward.LimitDrawTimes, 1 do
        Notes[i] = {}
        XTool.InitUiObjectByUi(Notes[i], self["Note" .. i])
    end

    for i, rewardId in ipairs(courseReward.RewardIds) do
        -- 节点进度条
        local curNoteGachaTime = courseReward.LimitDrawTimes[i] -- 该节点对应的gacha抽次数
        local progresssImg = self["ProgressImgYellow" .. i]
        progresssImg.fillAmount = (curTotalGachaTimes - (courseReward.LimitDrawTimes[i - 1] or 0)) / (curNoteGachaTime - (courseReward.LimitDrawTimes[i - 1] or 0))

        -- 节点奖励
        local rewards = XRewardManager.GetRewardList(rewardId)
        local note = Notes[i]
        note.Txt.text = curNoteGachaTime
        local isReceived = curTotalGachaTimes >= curNoteGachaTime
        if isReceived then
            if self._ShowCourseRewardTrigger and curTotalGachaTimes - 10 < curNoteGachaTime then
                -- 只有刚刚抽到的时候才闪一下
                XUiHelper.PlayAllChildParticleSystem(note.PanelEffect)
            end
            note.PanelEffect.gameObject:SetActiveEx(true)
            note.Select.gameObject:SetActiveEx(true)
        else
            note.PanelEffect.gameObject:SetActiveEx(false)
            note.Select.gameObject:SetActiveEx(false)
        end
        for j, item in pairs(rewards) do
            local searchIndex = curNoteGachaTime + j
            local gridReward = self._GridCourseRewardsDic[searchIndex]
            if not gridReward then
                local ui = CS.UnityEngine.Object.Instantiate(note.GridRewards, note.GridRewards.parent)
                gridReward = XUiGridCommon.New(self, ui)
                gridReward:SetCustomItemTip(function(data, hideSkipBtn, rootUiName, lackNum)
                    XLuaUiManager.Open("UiGachaBianka402Tip", data, hideSkipBtn, rootUiName, lackNum)
                end)
                self._GridCourseRewardsDic[searchIndex] = gridReward
            end
            gridReward.GameObject:SetActiveEx(true)
            gridReward:Refresh(item)
            gridReward:SetReceived(isReceived)
            gridReward:ShowCount(not isReceived)
        end
    end
    -- 如果抽完卡达到历程奖励 弹奖励提示
    self._ShowCourseRewardTrigger = nil

    -- 抽奖按钮
    local GridBtnGachas = {}
    GridBtnGachas[1] = {}
    GridBtnGachas[2] = {}
    XTool.InitUiObjectByUi(GridBtnGachas[1], self.BtnGacha)
    XTool.InitUiObjectByUi(GridBtnGachas[2], self.BtnGacha2)
    local icon = XDataCenter.ItemManager.GetItemTemplate(self._GachaCfg.ConsumeId).Icon
    GridBtnGachas[1].ImgUseItemIcon:SetRawImage(icon)
    GridBtnGachas[1].TxtUseItemCount.text = self._GachaCfg.ConsumeCount
    GridBtnGachas[2].ImgUseItemIcon:SetRawImage(icon)
    GridBtnGachas[2].TxtUseItemCount.text = self._GachaCfg.ConsumeCount * 10
    -- 按钮显示
    local leftCanGachaCount = totaMaxTimes - curTotalGachaTimes
    self.IsCanGacha1 = leftCanGachaCount > 0
    self.IsCanGacha10 = leftCanGachaCount >= 10
    self.IsGachaTimesEnd = leftCanGachaCount == 0

    self.BtnGacha:SetDisable(not self.IsCanGacha1)
    self.BtnGacha2:SetDisable(not self.IsCanGacha10)
    self.BtnGacha.transform:GetComponent("RawImage").enabled = self.IsCanGacha1
    GridBtnGachas[2].BtnGacha2.enabled = self.IsCanGacha10
    --GridBtnGachas[2].RImg1.gameObject:SetActiveEx(leftCanGachaCount >= 1 and leftCanGachaCount < 10)
    --GridBtnGachas[2].RImg2.gameObject:SetActiveEx(self.IsGachaTimesEnd)

    if not self.IsCanGacha1 then
        GridBtnGachas[1].ImgUseItemIcon.gameObject:SetActiveEx(false)
        GridBtnGachas[1].TxtUseItemCount.gameObject:SetActiveEx(false)
    end
    if not self.IsCanGacha10 then
        GridBtnGachas[2].ImgUseItemIcon.gameObject:SetActiveEx(false)
        GridBtnGachas[2].TxtUseItemCount.gameObject:SetActiveEx(false)
    end

    if self._GachaAllFinishTrigger then
        self._GachaAllFinishTrigger = nil
        self:ShowWeaponFashion()
    end
end

function XUiGachaBiankaMain:RefreshReddot()
    -- 红点
    local allStageIds = XFestivalActivityConfig.GetFestivalById(self._GachaCfg.FestivalActivityId).StageId
    local isAllPass = true
    for k, stageId in pairs(allStageIds) do
        local stageInfo = XDataCenter.FubenManager.GetStageInfo(stageId)
        if not stageInfo.Passed then
            isAllPass = false
            break
        end
    end

    local isNewDay = nil
    local updateTime = XSaveTool.GetData(self._GachaStoryRedPoint)
    if updateTime then
        isNewDay = XTime.GetServerNowTimestamp() > updateTime
    else
        isNewDay = true
    end

    local isRed = not isAllPass and isNewDay
    self.BtnStoryLine:ShowReddot(isRed)
end

-- 打开gacha道具购买界面
function XUiGachaBiankaMain:OpenGachaItemShop(openCb, gachaCount)
    -- 购买上限检测
    local gachaBuyTicketRuleConfig = XGachaConfigs.GetGachaItemExchangeCfgById(self._GachaCfg.ExchangeId)
    if XDataCenter.GachaManager.GetCurExchangeItemCount(self._GachaId) >= gachaBuyTicketRuleConfig.TotalBuyCountMax then
        XUiManager.TipError(CS.XTextManager.GetText("BuyItemCountLimit", XDataCenter.ItemManager.GetItemName(self._GachaCfg.ConsumeId)))
        return
    end

    local createItemData = function(config, index)
        return
        {
            ItemId = config.UseItemIds[index],
            Sale = config.Sales[index], -- 折扣
            CostNum = config.UseItemCounts[index], -- 价格
            ItemImg = config.UseItemImgs[index],
        }
    end
    local itemData1 = createItemData(gachaBuyTicketRuleConfig, 1)
    local itemData2 = createItemData(gachaBuyTicketRuleConfig, 2)
    local targetData = { ItemId = self._GachaCfg.ConsumeId, ItemImg = gachaBuyTicketRuleConfig.TargetItemImg }
    XLuaUiManager.Open("UiGachaBianka402BuyTicket", self._GachaCfg, itemData1, itemData2, targetData, gachaCount, function()
        self:RefreshUiShow()
    end)

    if openCb then
        openCb()
    end
end

function XUiGachaBiankaMain:CheckIsCanGacha(gachaCount)
    if not XDataCenter.GachaManager.CheckGachaIsOpenById(self._GachaCfg.Id, true) then
        return false
    end

    -- 剩余抽卡次数检测
    if not self["IsCanGacha" .. gachaCount] then
        if gachaCount == 10 and not self.IsGachaTimesEnd then
            XUiManager.TipText("GachaBiankaItemNoEnough")
        end
        return
    end

    -- 抽卡前检测物品是否满了
    if XMVCA.XEquip:CheckBoxOverLimitOfDraw() then
        return false
    end
    -- 检查货币是否足够
    local ownItemCount = XDataCenter.ItemManager.GetItem(self._GachaCfg.ConsumeId).Count
    local lackItemCount = self._GachaCfg.ConsumeCount * gachaCount - ownItemCount
    if lackItemCount > 0 then
        -- 打开购买界面
        self:OpenGachaItemShop(function()
            XUiManager.TipError(CS.XTextManager.GetText("DrawNotEnoughError"))
        end, gachaCount)
        return false
    end

    return true
end

-- 抽卡流程
function XUiGachaBiankaMain:DoGacha(gachaCount, isSkipToShow)
    local totalGachaCountBefore = XDataCenter.GachaManager.GetTotalGachaTimes(self._GachaId)
    if self._IsCanGacha then
        self._IsCanGacha = false

        -- 根据是否已拥有奖励判断能否弹窗历程奖励
        local isShowCourseRewardList = {}
        local courseReward = XGachaConfigs.GetGachaCourseRewardById(self._GachaCfg.CourseRewardId)
        for i = 1, #courseReward.LimitDrawTimes, 1 do
            local rewardList = XRewardManager.GetRewardList(courseReward.RewardIds[i])
            local isShow = true
            -- 检测是否已经拥有奖励的内容了，已拥有就不弹了。这个检测必须放在trigger外面作为upvalue，因为trigeer的调用时机很晚，背包可能已经被塞入东西看
            for k, data in pairs(rewardList) do
                if i == 1 then
                    if XRewardManager.CheckRewardOwn(data.RewardType, data.TemplateId) then
                        isShow = false
                    end
                end
                isShowCourseRewardList[i] = isShow
            end
        end

        local successCb = function(rewardList, newUnlockGachaId, res)
            -- 弹框相关
            local fashionItem
            local backgroundItem
            local rewardName
            local templateId
            local isConvertFrom
            local rewardListCourseFromServer

            self.RewardList = rewardList
            -- 检测是否抽到时装
            for _, v in pairs(rewardList) do
                if v.TemplateId == self._GachaCfg.TargetTemplateId then
                    fashionItem = v
                end
                if v.RewardType == XRewardManager.XRewardType.Background then
                    backgroundItem = v
                end
            end

            -- 检测是否达到历程奖励
            local totalGachaCountAfter = XDataCenter.GachaManager.GetTotalGachaTimes(self._GachaId)
            for i = 1, #courseReward.LimitDrawTimes, 1 do
                local times = courseReward.LimitDrawTimes[i]
                rewardName = courseReward.RewardNames[i]
                if totalGachaCountBefore < times and totalGachaCountAfter >= times then
                    self._ShowCourseRewardTrigger = true
                    local rewardListCourse = XRewardManager.GetRewardList(courseReward.RewardIds[i])
                    local isShow = isShowCourseRewardList[i]
                    if isShow then
                        -- 历程奖励已获得，先显示使用弹框，再显示（转化后）奖励展示弹框
                        rewardListCourseFromServer = res.GachaCourseResult.RewardList
                        if rewardListCourseFromServer and #rewardListCourseFromServer > 0 then
                            -- 固定【头像、头像框和武器涂装】
                            templateId = rewardListCourseFromServer[1].TemplateId
                            isConvertFrom = XTool.IsNumberValid(rewardListCourseFromServer[1].ConvertFrom)
                        else
                            templateId = rewardListCourse[1].TemplateId
                            isConvertFrom = false
                        end
                    end
                    break
                end
            end

            -- 播放完动画 展示奖励界面的触发器
            self._FinishCbTrigger = function(isSkipToShow2)
                -- 抽卡成功关闭场景镜头、特效
                self._IsCanGacha = true
                self._IsCanGachaClick = true
                local isSkipToShow = isSkipToShow2 or isSkipToShow -- 闭包在其他函数调用的时候不能获取当前函数里的的upvalue isSkipToShow，所以要在其他地方调用时要额外再传一次isSkipToShow2

                self:StopAnime()
                XLuaUiManager.Open("UiGachaBianka402Show", self._GachaId, self.RewardList, nil, isSkipToShow and gachaCount > 1) -- 单抽不能跳过奖励展示
                self._TipCbTrigger = function()
                    local isOpenQuickWear = XTool.IsNumberValid(templateId) and not isConvertFrom
                    local isOpenUiObtain = isConvertFrom and rewardListCourseFromServer

                    if isOpenUiObtain and not isOpenQuickWear and not fashionItem and not backgroundItem then
                        -- 防止UiObtain截背景图截到黑幕
                        self._UiObtainTimer = XScheduleManager.ScheduleOnce(function()
                            XLuaUiManager.Open("UiObtain", rewardListCourseFromServer)
                        end, 500)
                    else
                        local asynOpen = asynTask(XLuaUiManager.Open)
                        RunAsyn(function()
                            if isOpenQuickWear then
                                asynOpen("UiGachaBianka402QuickWear", templateId, self._GachaCfg.CourseRewardId, isConvertFrom, rewardName)
                            end
                            if fashionItem then
                                asynOpen("UiGachaBianka402Passport", fashionItem)
                            end
                            if backgroundItem then
                                asynOpen("UiGachaBianka402Passport", backgroundItem)
                            end
                            if isOpenUiObtain then
                                asynOpen("UiObtain", rewardListCourseFromServer)
                            end
                        end)
                    end
                end
            end

            if isSkipToShow then
                if self._FinishCbTrigger then
                    self._FinishCbTrigger(isSkipToShow)
                    self._FinishCbTrigger = nil
                end
            else
                local maxQuality = 0
                for k, rewardInfo in pairs(rewardList) do
                    --获取奖励品质
                    local id = rewardInfo.Id and rewardInfo.Id > 0 and rewardInfo.Id or rewardInfo.TemplateId
                    local Type = XTypeManager.GetTypeById(id)
                    if rewardInfo.ConvertFrom > 0 then
                        Type = XTypeManager.GetTypeById(rewardInfo.ConvertFrom)
                        id = rewardInfo.ConvertFrom
                    end
                    local quality
                    local templateIdData = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(id)
                    if Type == XArrangeConfigs.Types.Wafer then
                        quality = templateIdData.Star
                    elseif Type == XArrangeConfigs.Types.Weapon then
                        quality = templateIdData.Star
                    elseif Type == XArrangeConfigs.Types.Character then
                        quality = XMVCA.XCharacter:GetCharMinQuality(id)
                    elseif Type == XArrangeConfigs.Types.Partner then
                        quality = templateIdData.Quality
                    else
                        quality = XTypeManager.GetQualityById(id)
                    end
                    if XDataCenter.ItemManager.IsWeaponFashion(id) then
                        quality = XTypeManager.GetQualityById(id)
                    end
                    -- 强制检测特效
                    local foreceQuality = XGachaConfigs.GetGachaShowRewardConfigById(id)
                    if foreceQuality then
                        quality = foreceQuality.EffectQualityType
                    end

                    if quality > maxQuality then
                        maxQuality = quality
                    end
                end

                self:PlayGachaAnime(maxQuality)
            end
        end
        XDataCenter.GachaManager.DoGacha(self._GachaCfg.Id, gachaCount, successCb)
    end
end

function XUiGachaBiankaMain:PlayGachaAnime(quality)
    self.PlayAnime = true
    if not self._FinishCbTrigger then
        return
    end

    quality = quality or 4
    local timeline = self._Scene:GetGachaAnime(quality)
    if timeline then
        timeline:PlayTimelineAnimation(function()
            if self._FinishCbTrigger then
                self._FinishCbTrigger()
                self._FinishCbTrigger = nil
            end
        end)
    end

    self.GachaButtonsDisable:PlayTimelineAnimation(function()
        self.AssetPanel:Close()
    end)

    self.PlayAnime = false
end

-- 关闭所有特效
function XUiGachaBiankaMain:StopAnime()
    self.BtnSkipGacha.gameObject:SetActiveEx(false)
end

-- 传入要抽多少抽
function XUiGachaBiankaMain:OnBtnGachaClick(gachaCount)
    if not self:CheckIsCanGacha(gachaCount) then
        return
    end
    XDataCenter.KickOutManager.Lock(XEnumConst.KICK_OUT.LOCK.GACHA)

    self.BtnStoryLine:ShowReddot(false) -- 因为红点是用粒子特效做的，动画无法隐藏，必须程序控制抽卡时隐藏红点
    self._Scene:SetXPostFaicalControllerActive(false)
    self._GachaAllFinishTrigger = true
    self._DoGachaTrigger = function(isSkipToshow)
        self:DoGacha(gachaCount, isSkipToshow)
    end
    self._IsGachaReturnMain = true
    self._DoGachaTrigger()
end

-- 跳过抽卡演出,直接展示所有奖励
function XUiGachaBiankaMain:OnBtnSkipGachaClick()
    self._Scene:PlayChoukaAudioDisable(function() -- 特殊处理 为了关闭音效
        self.PlayAnime = false
        if self._FinishCbTrigger then
            -- timeline的PlayTimelineAnimation会在Disable执行回调
            -- 上面的抽卡动画的回调里就有个self._FinishCbTrigger()，所以这里得先置空，否则self._FinishCbTrigger会被调两次
            local cb = self._FinishCbTrigger
            self._FinishCbTrigger = nil
            cb(true)
        end
    end)
end

function XUiGachaBiankaMain:OnBtnStoryLineClick()
    if XLuaUiManager.IsUiLoad("UiGachaBianka402StageLine") then
        self:Close()
    else
        self._CanPlayStoryAnim = true
        XLuaUiManager.Open("UiGachaBianka402StageLine", self._GachaId)
    end
end

function XUiGachaBiankaMain:ShowWeaponFashion()
    local cacheReward = XDataCenter.LottoManager.GetWeaponFashionCacheReward()
    if cacheReward then
        XDataCenter.LottoManager.ClearWeaponFashionCacheReward()
        local data = cacheReward
        local rewards = { { TemplateId = data.ItemId, Count = data.ItemCount } }
        XUiManager.OpenUiObtain(rewards)
    end
end

return XUiGachaBiankaMain