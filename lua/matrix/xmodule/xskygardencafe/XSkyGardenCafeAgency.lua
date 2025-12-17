local XBigWorldActivityAgency = require("XModule/XBase/XBigWorldActivityAgency")

---@class   XSkyGardenCafeAgency : XBigWorldActivityAgency
---@field private _Model XSkyGardenCafeModel
local XSkyGardenCafeAgency = XClass(XBigWorldActivityAgency, "XSkyGardenCafeAgency")
function XSkyGardenCafeAgency:OnInit()
    self.StageType = {
        Story = 1, --剧情
        Challenge = 2, --挑战
        EndlessChallenge = 3, --无限挑战
    }

    self.UIType = {
        HandleBook = 1, --图鉴
        DeckEditor = 2, --卡组编辑
    }

    self.HudType = {
        CoffeeHud = 1,
        ReviewHud = 2,
        EmojiHud = 3,
        DialogHud = 4,
    }

    --卡组Id
    self.DeckIds = { 1, 2, 3 }

    self.CardUpdateEvent = {
        Create = 1,
        LongPress = 2,
        LongPressUp = 3,
        Reclaim = 4,
        Deck2Deal = 5,
        Deal2Deck = 6,
        DealSwitch = 7,
        CardClick = 8,
        RefreshContainer = 9,
        Drag = 10,
    }

    self.CardContainer = {
        Deck = 2,
        Deal = 3,
        ReDraw = 4,
    }

    -- 抽卡类型
    self.DrawCardType = {
        --回合抽卡
        Round = 1,
        --出牌抽卡
        PlayCard = 2
    }

    self.EffectTriggerId = {
        --出牌时
        Deck2Deal = 1,
        --保留时
        KeepInDeck = 2,
        --弃牌时
        Discard = 3,
        --抽卡时
        DrawCard = 4,
        --卡牌资源发生改变时
        CardResourceChanged = 5,
        --回合资源发生改变
        RoundResourceChanged = 6,
        --回合开始时
        RoundBegin = 7,
        --回合结束
        RoundEnd = 8,
        --出牌区数量发生变化时
        DealCountChanged = 9,
        --洗牌
        Shuffle = 10,
    }

    self.EffectType = {
        --优先抽牌
        PriorityLottery = 1,
        --保留手牌
        StayInHand = 2,
        --移除
        Remove = 3,
        --替换
        Replace = 4,
        --非定向抽取
        NonDirectedLottery = 5,
        --定向抽取
        TargetedLottery = 6,
        --插入
        Insert = 7,
        --发牌调整
        Pool2Deck = 8,
        --出牌区数量修改
        DealCountChange = 9,
        --改变卡的基础资源
        ResourceChange = 10,
        --卡的资源转化
        ResourceTransform = 11,
        --复制
        Copy = 12,
        --出牌区下标判断
        DealIndex = 13,
        --卡牌数量
        CardCount = 14,
        --出牌时携带符合条件的卡牌一起使用，且不占用槽位
        CarryWhenUse = 15,
        --卡牌使用次数
        CardUseCount = 16,
        --游戏回合
        GameRound = 17,
        --触发其他Buff
        ApplyOther = 18,
        --游戏回合持续Buff
        GameRoundSustain = 19,
        --卡牌资源永久改变
        ResourceChangeForever = 20,
        --创建新的卡牌
        CreateNew = 21,
    }

    self.ResourceType = {
        --咖啡销量
        Coffee = 1,
        --好评
        Review = 2,
    }

    --临时效果，在Buff销毁时复原
    self.NotPermanentEffectType = {
        [self.EffectType.DealCountChange] = true,
        [self.EffectType.Pool2Deck] = true,
        [self.EffectType.Remove] = true,
        [self.EffectType.CreateNew] = true,
    }

    self.CafeCueKey = {
        --销量增加
        AddCoffeeCueKey = "CoffeeAscend",
        --销量减少
        SubCoffeeCueKey = "CoffeeDescend",
        --好评增加
        AddReviewCueKey = "ReviewAscend",
        --好评减少
        SubReviewCueKey = "ReviewDecend",
    }

    self.GamePetState = {
        Idle = 1, --闲置
        LongTimeWait = 2, --长时间等待
        AddReview = 3, --增加好评
        AddCoffee = 4, --增加销量
        Settle = 5, --结算
    }

    self.Pattern = "{(%d+)}"

    self.RichTextImageCallBackCb = handler(self, self.RichTextImageCallBack)

    self._IsNotify = false

    self._LastEnterGameTime = os.clock()
    
    self._LastWaitTime = 0

    self:InitConditionCheck()
end

function XSkyGardenCafeAgency:OnRelease()
    self:ReleaseConditionCheck()
end

function XSkyGardenCafeAgency:InitRpc()
    self:AddRpc("NotifyBigWorldCafeData", handler(self, self.NotifyBigWorldCafeData))
    self:AddRpc("NotifyBigWorldCafeSettle", handler(self, self.NotifyBigWorldCafeSettle))
    self:AddRpc("NotifyBigWorldNewCafeCard", handler(self, self.NotifyBigWorldNewCafeCard))
end

function XSkyGardenCafeAgency:InitEvent()
end

function XSkyGardenCafeAgency:Reset()
    self._Model:Reset()
end

function XSkyGardenCafeAgency:CheckFunctionOpen()
    return XMVCA.XBigWorldFunction:DetectionFunction(XMVCA.XBigWorldFunction.FunctionId.SgCafe)
end

function XSkyGardenCafeAgency:OpenMainUi(id, args)
    if not self._Model:IsOpen() then
        XLog.Error("活动未开启")
        return
    end
    if args then
        self._X = tonumber(args[0])
        self._Y = tonumber(args[1])
        self._Z = tonumber(args[2])
    end
    --打开活动主界面
    XMVCA.XBigWorldUI:Open("UiSkyGardenCafeMain")

    XMVCA.XBigWorldGamePlay:SetCurNpcActive(false)
end

function XSkyGardenCafeAgency:EnterGameLevel()
    if not XMVCA.XBigWorldGamePlay:IsInGame() then
        return
    end
    local now = os.clock()
    if now <= self._LastEnterGameTime + 0.5 then
        return
    end
    self._LastEnterGameTime = now

    local curLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    if curLevelId == self:GetLevelId() then
        local data = self._Model:GetFightData()
        XMVCA.XSkyGardenCafe:DispatchInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ENTER_FIGHT, data.StageId, data.DeckId)
        return
    end
    XMVCA.XBigWorldMap:SendTeleportCommand(self:GetLevelId(), self._X, self._Y, self._Z, 0)
end

function XSkyGardenCafeAgency:ExitGameLevel()
    --判断是否返回到上个Level
    if not XMVCA.XSkyGardenCafe:IsEnterLevel() then
        return
    end
    XMVCA.X3CProxy:Send(CS.X3CCommand.CMD_TELEPORT_PLAYER_TO_LAST_LEVEL)
end

function XSkyGardenCafeAgency:GetName()
    return self._Model:GetActivityName()
end

function XSkyGardenCafeAgency:GetProgressTipData()
    local activityId = self._Model:GetActivityId()
    if not activityId or activityId <= 0 then
        return
    end
    local storyIdChapterId = self._Model:GetStoryChapterId(activityId)
    local challengeChapterId = self._Model:GetChallengeChapterId(activityId)
    local cur1, total1 = self._Model:GetStageListProgress(self._Model:GetStoryStageIds())
    local cur2, total2 = self._Model:GetStageListProgress(self._Model:GetChallengeStageIds())
    return {
        [1] = {
            Title = self._Model:GetChapterName(storyIdChapterId),
            Progress = string.format("%s/%s", cur1, total1),
            IsComplete = cur1 >= total1,
        },
        [2] = {
            Title = self._Model:GetChapterName(challengeChapterId),
            Progress = string.format("%s/%s", cur2, total2),
            IsComplete = cur2 >= total2,
        }
    }
end

function XSkyGardenCafeAgency:CheckInTime()
    return self._Model:IsOpen()
end

function XSkyGardenCafeAgency:OnEnterLevel()
    local curLevelId = XMVCA.XBigWorldGamePlay:GetCurrentLevelId()
    if curLevelId == self:GetLevelId() then
        return
    end
    XMVCA.XBigWorldUI:Open("UiBigWorldBlackMaskNormal")
end

function XSkyGardenCafeAgency:OnLevelBeginUpdate()
    local data = self._Model:GetFightData()
    if not data then
        return
    end
    XMVCA.XSkyGardenCafe:DispatchInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_ENTER_FIGHT, data.StageId, data.DeckId)
end

function XSkyGardenCafeAgency:OnLeaveLevel()
    self:DoLevelLevel()
end

function XSkyGardenCafeAgency:DoLevelLevel()
    --切换相机
    XMVCA.XBigWorldGamePlay:DeactivateVCamera("UiSkyGardenCoffeeCameraMain")
    --显示指挥官
    XMVCA.XBigWorldGamePlay:SetCurNpcActive(true)
    if XLoginManager.IsLogin() then
        XMVCA.XBigWorldUI:SafeClose("UiSkyGardenCafeMain")
    end
end

--region Util

function XSkyGardenCafeAgency:GetChangeValueByPercent(oldValue, percent)
    local newValue = oldValue * (1 + percent)
    return math.floor(newValue - oldValue)
end

function XSkyGardenCafeAgency:GetTeachId()
    return 2020
end

--endregion

--- 活动下发
function XSkyGardenCafeAgency:NotifyBigWorldCafeData(data)
    if not data then
        return
    end
    local gameData = data.Data
    --更新对局数据
    self._Model:UpdateBattle(gameData.CafeGambling)
    --更新牌组数据
    self._Model:InitCardDeckGroup(gameData.CardGroupList, true)
    --更新关卡信息
    self._Model:InitStageInfo(gameData.CafeStageList)
    --更新玩家数据
    self._Model:UpdateOwnCardDeck(gameData.CardDict)
    --目前只有1期，先设置成默认值
    self._Model:SetActivityId(1)
end

--- 结算通知
--------------------------
function XSkyGardenCafeAgency:NotifyBigWorldCafeSettle(data)
    if not data then
        return
    end

    local stageId = data.StageId
    local info = self._Model:GetStageInfo(stageId)
    info:DoSettle(data.Star, data.SumSales)
    local battle = self._Model:GetBattleInfo()
    battle:DoSettle(data.SumSales, data.AwardList)

    XMVCA.XSkyGardenCafe:DispatchInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_SETTLEMENT, stageId)

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_SETTLEMENT)
end

function XSkyGardenCafeAgency:NotifyBigWorldNewCafeCard(data)
    if not data then
        return
    end
    local deck = self._Model:GetOwnCardDeck()
    deck:UpdateCards({
        [data.CardId] = data.Num,
    })
    self:DispatchInnerEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_CAFE_NEW_CARD_UNLOCK)
end

function XSkyGardenCafeAgency:FightRequestData()
    local battleInfo = self._Model:GetBattleInfo()
    local stageId = battleInfo:GetStageId()
    --1:没有正在进行的游戏数据 2:有正在进行的游戏数据
    local state = 1
    if stageId > 0 then
        state = 2
    end

    return {
        GameplayState = state
    }
end

function XSkyGardenCafeAgency:FightRequestGiveUp()
    XNetwork.Call("BigWorldCafeGiveUpRequest", nil, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end
        self._Model:GetBattleInfo():Reset()
    end)
end

--- 富文本图文并排回调
---@param key string BigWorldAssetUrl.tab的Key值
---@param image UnityEngine.UI.Image
function XSkyGardenCafeAgency:RichTextImageCallBack(key, image)
    if XTool.UObjIsNil(image) then
        XLog.Error("创建图片失败! Image组件为空")
        return
    end
    local url = XMVCA.XBigWorldResource:GetAssetUrl(key)
    if string.IsNilOrEmpty(url) then
        XLog.Error("创建图片失败! BigWorldAssetUrl.tab 不存在主键 = " .. key)
        return
    end
    image:SetSprite(url)
end

function XSkyGardenCafeAgency:DispatchInnerEvent(eventId, ...)
    if not self._InnerEventDict then
        return
    end
    local eventDict = self._InnerEventDict[eventId]
    if not eventDict then
        return
    end
    for caller, funcDict in pairs(eventDict) do
        for _, func in pairs(funcDict) do
            func(caller, ...)
        end
    end
end

function XSkyGardenCafeAgency:AddInnerEvent(eventId, func, caller)
    if not self._InnerEventDict then
        return
    end
    local eventDict = self._InnerEventDict[eventId]
    if not eventDict then
        eventDict = {}
        self._InnerEventDict[eventId] = eventDict
    end
    local dict = eventDict[caller]
    if not dict then
        dict = {}
        eventDict[caller] = dict
    end
    dict[func] = func
end

function XSkyGardenCafeAgency:RemoveInnerEvent(eventId, func, caller)
    if not self._InnerEventDict then
        return
    end
    local eventDict = self._InnerEventDict[eventId]
    if not eventDict then
        return
    end
    local dict = eventDict[caller]
    if not dict then
        return
    end
    dict[func] = nil
end

function XSkyGardenCafeAgency:ClearAllInnerEvent()
    self._InnerEventDict = nil
end

function XSkyGardenCafeAgency:InitInnerEvent()
    self._InnerEventDict = {}
end

function XSkyGardenCafeAgency:GetLastWaitTime()
    return self._LastWaitTime
end

function XSkyGardenCafeAgency:SetLastWaitTime(value)
    self._LastWaitTime = value
end

--region Condition

function XSkyGardenCafeAgency:InitConditionCheck()
    XMVCA.XBigWorldService:RegisterConditionFunc(10203001, handler(self, self.CheckStageStar))
    XMVCA.XBigWorldService:RegisterConditionFunc(10203002, handler(self, self.CheckStageRound))
end

function XSkyGardenCafeAgency:ReleaseConditionCheck()
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10203001)
    XMVCA.XBigWorldService:UnRegisterConditionFunc(10203002)
end

--- 检测关卡星级是否满足
---@param template XTableCondition
---@return boolean, string
function XSkyGardenCafeAgency:CheckStageStar(template, ...)
    local stageId, star = template.Params[1], template.Params[2]
    if not stageId or stageId <= 0 then
        XLog.Error("Condition配置异常,关卡Id无效, ConditionId = " .. template.Id)
        return false, template.Desc
    end
    local stageInfo = self._Model:GetStageInfo(stageId)
    return stageInfo:GetStar() >= star, template.Desc
end

--- 当前是否位于指定关卡的指定时段
---@param template XTableCondition
---@return boolean, string
function XSkyGardenCafeAgency:CheckStageRound(template, ...)
    local stageId, round = template.Params[1], template.Params[2]
    if not stageId or stageId <= 0 then
        XLog.Error("Condition配置异常,关卡Id无效, ConditionId = " .. template.Id)
        return false, template.Desc
    end
    local battle = self._Model:GetBattleInfo()
    return battle:GetStageId() == stageId and battle:GetRound() == round, template.Desc
end

--endregion

return XSkyGardenCafeAgency