local XUiPokerGuessing2Character = require("XUi/XUiPokerGuessing2/Game/XUiPokerGuessing2Character")
local XUiPokerGuessing2Card = require("XUi/XUiPokerGuessing2/Game/XUiPokerGuessing2Card")
local XPokerGuessing2Enum = require("XModule/XPokerGuessing2/XPokerGuessing2Enum")
local XUiPanelPokerGuessing2ChangeCard = require('XUi/XUiPokerGuessing2/Game/XUiPanelPokerGuessing2ChangeCard')

---@class XUiPokerGuessing2Game : XLuaUi
---@field _Control XPokerGuessing2Control
local XUiPokerGuessing2Game = XLuaUiManager.Register(XLuaUi, "UiPokerGuessing2Game")

function XUiPokerGuessing2Game:OnAwake()
    ---@type XUiPokerGuessing2Card[]
    self._EnemyPreviewCards = {}

    --self.AssetActivityPanel = XUiHelper.NewPanelActivityAssetSafe({
    --}, self.PanelSpecialTool, self)
    ---@type XUiPokerGuessing2Character
    self._Player = XUiPokerGuessing2Character.New(self.PanelRight, self, true)
    ---@type XUiPokerGuessing2Character
    self._Enemy = XUiPokerGuessing2Character.New(self.PanelLeft, self)
    ---@type XUiPanelPokerGuessing2ChangeCard
    self.PanelChangeCard = XUiPanelPokerGuessing2ChangeCard.New(self.PanelChangeCard, self, self.BtnClose)
    self.PanelChangeCard:Close()
    
    XUiHelper.RegisterClickEvent(self, self.BtnPlay, self.OnClickPlay, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnClickBack, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnClickMain, nil, true)
    XUiHelper.RegisterClickEvent(self, self.BtnShowRule, self.OnBtnShowRuleClick, nil, true)
    
    self.BtnSkillChangeSelf:AddEventListener(handler(self, self.OnBtnSkillChangeSelfClick))
    self.BtnSkillChangeEnemy:AddEventListener(handler(self, self.OnBtnSkillChangeEnemyClick))

    self.PanelDraw = self.PanelDraw or self.TxtDraw
    if self.PanelDraw then
        self.PanelDraw.gameObject:SetActiveEx(false)
    end
    self.TxtPlayerNum.text = 0
    self.TxtPlayerNextNum.text = 0
    self.TxtOpponentNum.text = 0
    self.TxtOpponentNextNum.text = 0

    self._IsPlayingAnimation = false
end

function XUiPokerGuessing2Game:OnStart()
    self:HideSpeak()
    self:UpdateScore()
    self:UpdateStageDesc()
    self:UpdatePlayer()
    self:UpdateEnemy()
    self:UpdateSkillShow()
    self:PlayAnimationStartRound()
    
    -- 默认显示PanelBuff
    if self.PanelBuff then
        self.PanelBuff.gameObject:SetActiveEx(true)
        -- 3秒后自动关闭
        self._PanelBuffAutoCloseTimer = XScheduleManager.ScheduleOnce(function()
            if self.PanelBuff and not XTool.UObjIsNil(self.PanelBuff.gameObject) then
                self.PanelBuff.gameObject:SetActiveEx(false)
            end
            self._PanelBuffAutoCloseTimer = nil
        end, 3000)
    end
end

function XUiPokerGuessing2Game:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_SKILL_SHOW, self.UpdateSkillShow, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_SPEAK, self.UpdateSpeak, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_CONFIRM_RESULT, self.PlayAnimationConfirmResult, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_START_ROUND, self.PlayAnimationStartRound, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_RESTART, self.Restart, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_SELECT_PLAYER_CARD, self.PlayAnimationPlayerPutCard, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_OPEN_CHANGE_SKILL, self.OnOpenChangeCardSkillPanel, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_STAGE_DESC, self.UpdateStageDesc, self)
    XEventManager.AddEventListener(XEventId.EVENT_POKER_GUESSING2_CHANGE_CARD_SUCCESS, self.OnChangeCardSuccess, self)
    -- 任务会导致卡顿, 因此延迟到游戏界面关闭时进行更新
    XDataCenter.TaskManager.CloseSyncTasksEvent()
end

function XUiPokerGuessing2Game:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_SKILL_SHOW, self.UpdateSkillShow, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_SPEAK, self.UpdateSpeak, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_CONFIRM_RESULT, self.PlayAnimationConfirmResult, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_START_ROUND, self.PlayAnimationStartRound, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_RESTART, self.Restart, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_SELECT_PLAYER_CARD, self.PlayAnimationPlayerPutCard, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_OPEN_CHANGE_SKILL, self.OnOpenChangeCardSkillPanel, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_CHANGE_CARD_SUCCESS, self.OnChangeCardSuccess, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_POKER_GUESSING2_UPDATE_STAGE_DESC, self.UpdateStageDesc, self)

    XDataCenter.TaskManager.OpenSyncTasksEvent()
end

function XUiPokerGuessing2Game:OnDestroy()
    -- 清理PanelBuff自动关闭定时器
    if self._PanelBuffAutoCloseTimer then
        XScheduleManager.UnSchedule(self._PanelBuffAutoCloseTimer)
        self._PanelBuffAutoCloseTimer = nil
    end
    
    -- 防止遮罩层多次打开
    for i = 1, 99 do
        if XLuaUiManager.IsMaskShow("PokerGuessing2") then
            XLuaUiManager.SetMask(false, "PokerGuessing2")
        else
            break
        end
    end
    self._Control:SetCurrentStageId(nil, nil)
end

function XUiPokerGuessing2Game:PlayAnimationStartRound()
    local duration1 = 1.5
    local duration2 = 2
    local duration3 = 0.5

    self._IsPlayingAnimation = true
    -- 为什么延迟一帧，因为如果在第一回合startGame的网络协议回调时，连续open两个ui，会导致第二个ui打开失败，但是它的data一直存在，致使control无法回收
    -- 虽然已经过滤掉第一回合，但是还是保留延迟一帧吧
    if self._Control:GetRound() ~= 1 then
        self:TimerQuick(function()
            XLuaUiManager.Open("UiPokerGuessing2ToastRound")
        end, 0)
    end
    self:TimerQuick(function()
        XLuaUiManager.Close("UiPokerGuessing2ToastRound")

        self:TimerQuick(function()
            self:UpdateSpeak(XPokerGuessing2Enum.Speak.RoundStart)
        end, 0.5)

        self:TimerQuick(function()
            self._Enemy:PlayAnimationCardToPutDownRandom(duration3)
            self._IsPlayingAnimation = false
        end, duration2)
    end, duration1)
end

function XUiPokerGuessing2Game:TimerQuick(callback, duration)
    local time = CS.UnityEngine.Time.time + duration
    local timer
    timer = XScheduleManager.ScheduleForever(function()
        if CS.UnityEngine.Time.time >= time then
            XScheduleManager.UnSchedule(timer)
            self:_RemoveTimerIdAndDoCallback(timer)
            if callback then
                callback()
            end
        end
    end, 0)
    self:_AddTimerId(timer)
end

---@param state number 游戏状态
---@param roundState number 回合状态
---@param roundPlayerEffect number 玩家回合效果
---@param roundRobotEffect number 敌人回合效果
function XUiPokerGuessing2Game:PlayAnimationConfirmResult(state, roundState, roundPlayerEffect, roundRobotEffect)
    XLuaUiManager.SetMask(true, "PokerGuessing2")
    -- 掀开敌人的卡（敌人卡牌会在动画结束后自动克隆）
    self:RevealEnemyCard()
    -- 玩家卡牌直接克隆（因为玩家卡牌不需要翻牌动画）
    self._Player:CloneCardOnCurrentNode()

    -- 判断输赢
    self:TimerQuick(function()
        if roundState == XPokerGuessing2Enum.RoundState.RoundWin then
            self._Player:SetTheRevealCardWin()
            self._Player:ShowEffectSuccess()
        elseif roundState == XPokerGuessing2Enum.RoundState.RoundLose then
            self._Enemy:SetTheRevealCardWin()
            self._Enemy:ShowEffectSuccess()
        elseif roundState == XPokerGuessing2Enum.RoundState.RoundDrawn then
            self.PanelDraw.gameObject:SetActiveEx(true)
        end
    end, 0.3)

    -- 更新分数
    self:TimerQuick(function()
        self:UpdateScore()
    end, 1.3)

    -- 显示对话
    -- 优先处理回合效果（roundPlayerEffect 和 roundRobotEffect）
    if roundPlayerEffect and roundPlayerEffect ~= 0 then
        -- 将 PokerRoundEffect 映射到 Speak 枚举
        local playerSpeakType = self:_MapRoundEffectToSpeak(roundPlayerEffect)
        if playerSpeakType then
            local playerSpeak = self._Control:GetDialogue(playerSpeakType)
            self:TimerQuick(function()
                if playerSpeak.Player then
                    self:_ShowCharacterSpeak(self._Player, playerSpeak.Player)
                end
            end, 0.7)
        end
    end
    
    if roundRobotEffect and roundRobotEffect ~= 0 then
        -- 将 PokerRoundEffect 映射到 Speak 枚举
        local enemySpeakType = self:_MapRoundEffectToSpeak(roundRobotEffect)
        if enemySpeakType then
            local enemySpeak = self._Control:GetDialogue(enemySpeakType)
            self:TimerQuick(function()
                if enemySpeak.Enemy then
                    self:_ShowCharacterSpeak(self._Enemy, enemySpeak.Enemy)
                end
            end, 0.7)
        end
    end
    
    -- 获取原 state 的对话（用于玩家对话，以及没有效果时的敌人对话）
    local originalSpeak = self._Control:GetDialogue(state)
    
    -- 如果没有回合效果，使用原来的 state 逻辑
    if (not roundPlayerEffect or roundPlayerEffect == 0) and (not roundRobotEffect or roundRobotEffect == 0) then
        self:TimerQuick(function()
            if originalSpeak.Player then
                self:_ShowCharacterSpeak(self._Player, originalSpeak.Player)
            end
        end, 0.7)
        self:TimerQuick(function()
            if originalSpeak.Enemy then
                self:_ShowCharacterSpeak(self._Enemy, originalSpeak.Enemy)
            end
        end, 0.7)
    else
        -- 如果有回合效果，玩家对话使用原 state 逻辑
        if roundRobotEffect and roundRobotEffect ~= 0 then
            -- 反杀效果只改变敌人对话，玩家对话保留原逻辑
            self:TimerQuick(function()
                if originalSpeak.Player then
                    self:_ShowCharacterSpeak(self._Player, originalSpeak.Player)
                end
            end, 0.7)
        end
    end

    -- 判断是否结束
    if self._Control:IsGameOver() then
        -- 结算界面
        self:TimerQuick(function()
            XLuaUiManager.SetMask(false, "PokerGuessing2")
            XLuaUiManager.Open("UiPokerGuessing2PopupSettlement")
        end, 2.5)
    else
        -- 开始下一轮
        self:TimerQuick(function()
            XLuaUiManager.SetMask(false, "PokerGuessing2")

            self.PanelDraw.gameObject:SetActiveEx(false)
            -- 移除掀开的牌
            self:UpdatePlayer()
            self:UpdateEnemy()
            self._Player:HideCardWin()
            self._Enemy:HideCardWin()
            self._Player:SetAllCardPutOnGroup(false)
            self._Enemy:SetAllCardPutOnGroup(false)
            self:PlayAnimationStartRound()
        end, 2.5)
    end
end

function XUiPokerGuessing2Game:UpdateScore()
    local playerScore, enemyScore = self._Control:GetScore()
    if tostring(playerScore) ~= self.TxtPlayerNum.text then
        self.TxtPlayerNextNum.text = self.TxtPlayerNum.text
        self.TxtPlayerNum.text = playerScore
        self:PlayAnimation("PlayerScoreJump")
    end
    if tostring(enemyScore) ~= self.TxtOpponentNum.text then
        self.TxtOpponentNextNum.text = self.TxtOpponentNum.text
        self.TxtOpponentNum.text = enemyScore
        self:PlayAnimation("OpponentScoreJump")
    end
end

function XUiPokerGuessing2Game:UpdateStageDesc()
    local uiMain = self._Control:GetUiMain()
    local desc = uiMain.StageDesc or ""
    local strikeBack = uiMain.StageStrikeBack or ""
    
    -- 显示 EffectDesc
    self.TxtDetail1.text = desc
    
    -- 显示 EffectStrikeBack
    if self.TextStrikeBack then
        self.TextStrikeBack.text = strikeBack
    end
    
    -- 控制 PanelStrikeBack 的显示/隐藏
    if self.PanelStrikeBack then
        self.PanelStrikeBack.gameObject:SetActiveEx(strikeBack ~= "")
    end
end

function XUiPokerGuessing2Game:OnClickPlay()
    if self._IsPlayingAnimation then
        return
    end
    self._Control:Confirm()
end

function XUiPokerGuessing2Game:OnBtnSkillChangeSelfClick()
    self._Control:UseSkillChangeSelfCard()
end

function XUiPokerGuessing2Game:OnBtnSkillChangeEnemyClick()
    self._Control:UseSkillChangeEnemyCard()
end

function XUiPokerGuessing2Game:OnBtnShowRuleClick()
    if not self.PanelBuff then
        return
    end
    -- 切换PanelBuff的显示状态
    local isActive = self.PanelBuff.gameObject.activeSelf
    self.PanelBuff.gameObject:SetActiveEx(not isActive)
    
    -- 如果手动关闭了PanelBuff，取消自动关闭定时器
    if not isActive and self._PanelBuffAutoCloseTimer then
        XScheduleManager.UnSchedule(self._PanelBuffAutoCloseTimer)
        self._PanelBuffAutoCloseTimer = nil
    end
end

function XUiPokerGuessing2Game:OnOpenChangeCardSkillPanel(isPlayer, originId)
    self.PanelChangeCard:Open()
    self.PanelChangeCard:RefreshShowWithSide(isPlayer, originId)
end

function XUiPokerGuessing2Game:OnChangeCardSuccess(isChangedPlayerSide)
    if isChangedPlayerSide then
        -- 改牌后目前只有玩家的牌需要立刻刷新
        self._Player:UpdateAfterChangedCard(self._Control:GetPlayerSelectCardData())
    else
        self._Enemy:ShowChangeCardAnimOnly(self._Control:GetEnemySelectCardData())
    end
    
    -- 己方角色显示对应的对话
    local content, isEmoji = self._Control:GetPlayerDialogAfterChangedCard(isChangedPlayerSide)
    
    self._Player:Speak(content, isEmoji)
end

function XUiPokerGuessing2Game:UpdateSkillShow()
    self.BtnSkillChangeSelf:SetButtonState(self._Control:CheckHasChangeSelfSkillCount() and CS.UiButtonState.Normal or CS.UiButtonState.Disable)
    self.BtnSkillChangeEnemy:SetButtonState(self._Control:CheckHasChangeEnemySkillCount() and CS.UiButtonState.Normal or CS.UiButtonState.Disable)

    local tipsCardSpeak = self._Control:GetTipsCardSpeak()
    if tipsCardSpeak then
        self._Player:Speak(tipsCardSpeak)
    end
end

function XUiPokerGuessing2Game:UpdateEnemy()
    local enemy = self._Control:GetEnemy()
    self._Enemy:Update(enemy)
    XTool.UpdateDynamicItem(self._EnemyPreviewCards, enemy.PreviewCards, self.GridSmallCard, XUiPokerGuessing2Card, self)
    self._Enemy:CoverAllTheCards()
end

function XUiPokerGuessing2Game:RevealEnemyCard()
    local enemy = self._Control:GetEnemy()
    self._Enemy:RevealCoveredCard(enemy.Card)
    -- 移除掀开的牌
    self._Control:RemoveEnemyCard()
end

function XUiPokerGuessing2Game:UpdatePlayer()
    self._Player:Update(self._Control:GetPlayer())
end

function XUiPokerGuessing2Game:HideSpeak()
    self._Enemy:Speak()
    self._Player:Speak()
end

--- 显示角色对话
---@param character XUiPokerGuessing2Character 角色UI组件
---@param speakData table 对话数据 {Type, Text, Emoji}
--- 将 PokerRoundEffect 映射到 Speak 枚举
---@param roundEffect number PokerRoundEffect 枚举值
---@return number|nil Speak 枚举值
function XUiPokerGuessing2Game:_MapRoundEffectToSpeak(roundEffect)
    if roundEffect == XPokerGuessing2Enum.PokerRoundEffect.RoundReverse then
        return XPokerGuessing2Enum.Speak.StrikeBack
    elseif roundEffect == XPokerGuessing2Enum.PokerRoundEffect.RoundBoom then
        return XPokerGuessing2Enum.Speak.Boom
    elseif roundEffect == XPokerGuessing2Enum.PokerRoundEffect.RoundTrap then
        return XPokerGuessing2Enum.Speak.Trap
    end
    return nil
end

function XUiPokerGuessing2Game:_ShowCharacterSpeak(character, speakData)
    if not character or not speakData then
        return
    end
    
    if speakData.Type == XPokerGuessing2Enum.SpeakShowType.Text then
        -- 显示文本
        character:Speak(speakData.Text, false)
    elseif speakData.Type == XPokerGuessing2Enum.SpeakShowType.Emoji then
        -- 显示表情
        character:Speak(speakData.Emoji, true)
    end
end

function XUiPokerGuessing2Game:UpdateSpeak(state)
    local speak = self._Control:GetDialogue(state)
    if speak.Enemy then
        self:_ShowCharacterSpeak(self._Enemy, speak.Enemy)
    end
    if speak.Player then
        self:_ShowCharacterSpeak(self._Player, speak.Player)
    else
        self._Player:Speak()
    end
end

function XUiPokerGuessing2Game:Restart()
    self._Control:Restart(function()
        -- 清理克隆的卡牌
        self._Player:ClearClonedCards()
        self._Enemy:ClearClonedCards()
        
        self:UpdateScore()
        self:UpdateStageDesc()
        self:UpdatePlayer()
        self:UpdateEnemy()
        self:UpdateSkillShow()
        self._Player:Reset()
        self._Enemy:Reset()
        self.PanelDraw.gameObject:SetActiveEx(false)
    end)
end

function XUiPokerGuessing2Game:OnClickBack()
    XUiManager.DialogTip(nil, XUiHelper.GetText("PokerGuessing2GiveUp"), nil, nil, function()
        self:Close()
    end)
end

function XUiPokerGuessing2Game:OnClickMain()
    XUiManager.DialogTip(nil, XUiHelper.GetText("PokerGuessing2GiveUp"), nil, nil, function()
        XLuaUiManager.RunMain()
    end)
end

-- 打出玩家指定位置的手牌
function XUiPokerGuessing2Game:PlayAnimationPlayerPutCard(cardIndex)
    cardIndex = tonumber(cardIndex)
    if cardIndex == nil then
        XLog.Warning("[XUiPokerGuessing2Game] PlayAnimationPlayerPutCard cardIndex is nil")
        return
    end
    local card = self._Player:PlayAnimationCardToPutDown(cardIndex, 0.5)
    if card then
        card:SetPlayerSelected()
        self._Player:RevertCardParentAndPosition(card)
    end
end

return XUiPokerGuessing2Game

