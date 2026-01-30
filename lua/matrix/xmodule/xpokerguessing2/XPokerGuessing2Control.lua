local XPokerGuessing2Game = require("XModule/XPokerGuessing2/Game/XPokerGuessing2Game")
local XPokerGuessing2Enum = require("XModule/XPokerGuessing2/XPokerGuessing2Enum")
local XPokerGuessing2RandomSpeak = require('XModule/XPokerGuessing2/Game/XPokerGuessing2RandomSpeak')

---@class XPokerGuessing2Control : XControl
---@field private _Model XPokerGuessing2Model
local XPokerGuessing2Control = XClass(XControl, "XPokerGuessing2Control")

function XPokerGuessing2Control:OnInit()
    self._Main = {
        Time = 0,
        ---@type XUiPokerGuessing2CharacterData
        Enemy = {
            Name = "",
            Icon = "",
            Card = nil,
            Cards = {},
        },
        EnemyCardIndex = 1,
        ---@type XUiPokerGuessing2CharacterData
        Player = {
            Name = "",
            Icon = "",
            Card = nil,
            Cards = {},
        },
        StageDesc = "",
        StageStrikeBack = "",
        StageIndex = 0,
        StageMaxIndex = 0,
        IsOpen = false,
        StageId = 0,
        EnemyDialogue = "",
        IsPassed = false,
    }
    self._SelectCharacter = {
        ---@type XPokerGuessing2UiCharacter[]
        Characters = {},
        ---@type XPokerGuessing2UiCharacter
        Selected = nil,
    }
    self._Settlement = {
        IsWin = false,
        Round = 0,
        Rewards = {},
    }
    self._SelectedCharacterId = XSaveTool.GetData("PokerGuessing2CharacterId" .. XPlayer.Id) or 0
    self._SelectedCardId = 0

    self._StageConfigList = false

    --为了可以重开，游戏结束后，也不清除
    self._GameStageId = 0
    
    -- 缓存玩家反杀分数，初始为 0
    self._PlayerReverseScore = 0

    ---@type XPokerGuessing2Game
    self._Game = XPokerGuessing2Game.New()
    ---@type XPokerGuessing2RandomSpeak
    self._PlayerRandomSpeak = XPokerGuessing2RandomSpeak.New()
    ---@type XPokerGuessing2RandomSpeak
    self._EnemyRandomSpeak = XPokerGuessing2RandomSpeak.New()
end

function XPokerGuessing2Control:AddAgencyEvent()
    self._Timer = XScheduleManager.ScheduleForever(function()
        self:UpdateTime()
    end, XScheduleManager.SECOND)
end

function XPokerGuessing2Control:RemoveAgencyEvent()
    XScheduleManager.UnSchedule(self._Timer)
end

function XPokerGuessing2Control:OnRelease()
    self:SetCurrentStageId(nil, nil)
end

function XPokerGuessing2Control:RemoveEnemyCard()
    self._Game:RemoveEnemyCard()
end

function XPokerGuessing2Control:Restart(callback)
    local stageId = self._GameStageId
    if not stageId or stageId == 0 then
        XLog.Error("[XPokerGuessing2Control] 重开失败, stageId:", tostring(stageId))
        return
    end
    XMVCA.XPokerGuessing2:StartNewPokerGuessing2Request(stageId, function(res)
        if not res then
            XLuaUiManager.Close("UiPokerGuessing2Game")
            return
        end
        self:SetCurrentStageId(stageId, 1)
        self:_InitGameData(res)
        if callback then
            callback()
        end
        XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_SPEAK, XPokerGuessing2Enum.Speak.RoundStart)
        XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_START_ROUND)
    end)
end

function XPokerGuessing2Control:StartGame()
    local stageId = self._Main.StageId
    XMVCA.XPokerGuessing2:StartNewPokerGuessing2Request(stageId, function(res)
        if res then
            self:SetCurrentStageId(stageId, 1)
            self._GameStageId = stageId
            self:_InitGameData(res)
            XLuaUiManager.Open("UiPokerGuessing2Game")
        end
    end)
end

function XPokerGuessing2Control:_InitGameData(res)
    -- 重置玩家反杀分数缓存
    self._PlayerReverseScore = 0
    self._Game:Reset()
    local cards = res.PlayerCards
    self._Game:SetPlayerCards(cards)
    self._Game:SetEnemyCards(cards)

    local activityId = self._Model:GetActivityId()
    self._Game:InitMaxChangePlayerCardCount(self._Model:GetPokerGuessing2ActivityMaxChangeSelfCardCountById(activityId))
    self._Game:InitMaxChangeRobotCardCount(self._Model:GetPokerGuessing2ActivityMaxChangeEnemyCardCountById(activityId))
    self:_InitSpeaks()
end

function XPokerGuessing2Control:_InitSpeaks()
    local stageConfig = self:GetStagePerformConfig()
    local characterConfig = self:GetCharacterConfig()

    self._PlayerRandomSpeak:AddRandomGroup(#characterConfig.LineGameWin, #characterConfig.EmojiGameWin,
        XPokerGuessing2Enum.Speak.GameWin)
    self._PlayerRandomSpeak:AddRandomGroup(#characterConfig.LineGameLose, #characterConfig.EmojiGameLose,
        XPokerGuessing2Enum.Speak.GameLose)
    self._PlayerRandomSpeak:AddRandomGroup(#characterConfig.LineRoundWin, #characterConfig.EmojiRoundWin,
        XPokerGuessing2Enum.Speak.RoundWin)
    self._PlayerRandomSpeak:AddRandomGroup(#characterConfig.LineRoundLose, #characterConfig.EmojiRoundLose,
        XPokerGuessing2Enum.Speak.RoundLose)
    self._PlayerRandomSpeak:AddRandomGroup(#characterConfig.LineRoundDraw, #characterConfig.EmojiRoundDraw,
        XPokerGuessing2Enum.Speak.RoundDraw)
    self._PlayerRandomSpeak:AddRandomGroup(#characterConfig.LineChangeSelfCard, #characterConfig.EmojiChangeSelfCard,
        XPokerGuessing2Enum.Speak.PlayerCardChanged)
    self._PlayerRandomSpeak:AddRandomGroup(#characterConfig.LineChangeEnemyCard, #characterConfig.EmojiChangeEnemyCard,
        XPokerGuessing2Enum.Speak.EnemyCardChanged)
    -- self._PlayerRandomSpeak:AddRandomGroup(#characterConfig.LineStrikeBack, #characterConfig.EmojiStrikeBack, XPokerGuessing2Enum.Speak.StrikeBack)
    -- self._PlayerRandomSpeak:AddRandomGroup(#characterConfig.LineBoom, #characterConfig.EmojiBoom, XPokerGuessing2Enum.Speak.Boom)
    -- self._PlayerRandomSpeak:AddRandomGroup(#characterConfig.LineTrap, #characterConfig.EmojiTrap, XPokerGuessing2Enum.Speak.Trap)

    self._EnemyRandomSpeak:AddRandomGroup(#stageConfig.LineGameWin, #stageConfig.EmojiGameWin,
        XPokerGuessing2Enum.Speak.GameWin)
    self._EnemyRandomSpeak:AddRandomGroup(#stageConfig.LineGameLose, #stageConfig.EmojiGameLose,
        XPokerGuessing2Enum.Speak.GameLose)
    self._EnemyRandomSpeak:AddRandomGroup(#stageConfig.LineRoundWin, #stageConfig.EmojiRoundWin,
        XPokerGuessing2Enum.Speak.RoundWin)
    self._EnemyRandomSpeak:AddRandomGroup(#stageConfig.LineRoundLose, #stageConfig.EmojiRoundLose,
        XPokerGuessing2Enum.Speak.RoundLose)
    self._EnemyRandomSpeak:AddRandomGroup(#stageConfig.LineRoundDraw, #stageConfig.EmojiRoundDraw,
        XPokerGuessing2Enum.Speak.RoundDraw)
    self._EnemyRandomSpeak:AddRandomGroup(#stageConfig.LineChangePlayerCard, #stageConfig.EmojiChangePlayerCard,
        XPokerGuessing2Enum.Speak.PlayerCardChanged)
    self._EnemyRandomSpeak:AddRandomGroup(#stageConfig.LineChangeSelfCard, #stageConfig.EmojiChangeSelfCard,
        XPokerGuessing2Enum.Speak.EnemyCardChanged)
    self._EnemyRandomSpeak:AddRandomGroup(0, #stageConfig.EmojiStrikeBack, XPokerGuessing2Enum.Speak.StrikeBack)
    self._EnemyRandomSpeak:AddRandomGroup(0, #stageConfig.EmojiBoom, XPokerGuessing2Enum.Speak.Boom)
    self._EnemyRandomSpeak:AddRandomGroup(0, #stageConfig.EmojiTrap, XPokerGuessing2Enum.Speak.Trap)
end

function XPokerGuessing2Control:GetScore()
    return self._Game:GetScore()
end

function XPokerGuessing2Control:GetStageList()
    if self._StageConfigList then
        return self._StageConfigList
    end
    local stageList = {}
    local activityId = self._Model:GetActivityId()
    local activityCfg = self._Model:GetPokerGuessing2ActivityConfigById(activityId)

    if activityCfg and not XTool.IsTableEmpty(activityCfg.StageIds) then
        for i, stageId in pairs(activityCfg.StageIds) do
            local stageCfg = self._Model:GetPokerGuessing2StageConfigById(stageId)

            if stageCfg then
                stageList[#stageList + 1] = stageCfg
            end
        end
        table.sort(stageList, function(a, b)
            return a.Id < b.Id
        end)
        self._StageConfigList = stageList
    end

    return stageList
end

function XPokerGuessing2Control:GetEnemyCardIndex()
    return self._Main.EnemyCardIndex
end

function XPokerGuessing2Control:PlayFirstTimeStory()
    --[[if XSaveTool.GetData("XPokerGuessing2FirstTimeStory" .. XPlayer.Id) == true then
        return
    end--]]

    if self._Model:CheckIsFirstTimeStory() then
        return
    end

    local config = self:GetActivityConfig()
    if config then
        local storyId = config.StoryId
        if storyId and storyId ~= "" then
            XDataCenter.MovieManager.PlayMovie(storyId, function()
                self._Model:SetIsFirstTimeStory(true)
                --XSaveTool.SaveData("XPokerGuessing2FirstTimeStory" .. XPlayer.Id, true)
            end)
        end
    end
end

function XPokerGuessing2Control:SelectDefaultStage()
    local stageList = self:GetStageList()
    local selectStageId = self._Main.StageId
    if selectStageId == 0 then
        -- 找到第一个未通关且可挑战的关卡
        for i = 1, #stageList do
            local stageData = stageList[i]
            local stageId = stageData.Id
            if self._Model:IsStageCanChallenge(stageId) and not self._Model:IsStagePassed(stageId) then
                selectStageId = stageId
                break
            end
        end
        -- 否则选中最后一个可挑战的
        if selectStageId == 0 then
            for i = 1, #stageList do
                local stageData = stageList[i]
                local stageId = stageData.Id
                if self._Model:IsStageCanChallenge(stageId) then
                    selectStageId = stageId
                end
            end
        end
        if selectStageId == 0 then
            if #stageList == 0 then
                XLog.Error("[XPokerGuessing2Control] 关卡列表为空")
            else
                XLog.Error("[XPokerGuessing2Control] 没有一关可挑战?")
                selectStageId = stageList[1].Id
            end
        end
    end
    self._Main.StageId = selectStageId
end

function XPokerGuessing2Control:GetUiMain()
    local data = self._Main

    local stageList = self:GetStageList()
    local selectStageId = self._Main.StageId
    if selectStageId ~= 0 then
        local stageConfig = self._Model:GetPokerGuessing2StagePerformCfgById(selectStageId)
        self._Main.StageId = selectStageId
        self._Main.IsOpen = self._Model:IsStageCanChallenge(selectStageId)
        self._Main.IsPassed = self._Model:IsStagePassed(selectStageId)
        -- 分开设置 EffectDesc 和 EffectStrikeBack
        if stageConfig.EffectDesc and stageConfig.EffectDesc ~= "" then
            self._Main.StageDesc = XUiHelper.ReplaceTextNewLine(stageConfig.EffectDesc)
        else
            self._Main.StageDesc = ""
        end
        
        if stageConfig.EffectStrikeBack and stageConfig.EffectStrikeBack ~= "" then
            -- 使用缓存的分数（初始为 0）
            self._Main.StageStrikeBack = XUiHelper.FormatText(XUiHelper.ReplaceTextNewLine(stageConfig.EffectStrikeBack), self._PlayerReverseScore or 0)
        else
            self._Main.StageStrikeBack = ""
        end
        for i = 1, #stageList do
            if stageList[i].Id == selectStageId then
                self._Main.StageIndex = i
            end
        end

        self._Main.EnemyDialogue = self:RandomSpeak(stageConfig.LineLevel)
    else
        self._Main.StageIndex = 0
        XLog.Error("[XPokerGuessing2Control] 无法找到关卡")
    end
    self._Main.StageMaxIndex = #stageList

    local selectedCharacterId = self._SelectedCharacterId
    if selectedCharacterId == 0 then
        local characters = self._Model:GetAllCharacters()
        if #characters == 0 then
            XLog.Error("[XPokerGuessing2Control] 已解锁角色数量为0")
        else
            self:SetSelectedCharacter(characters[1].Id)
        end
    end
    if selectedCharacterId ~= 0 then
        if XMVCA.XCharacter:GetModelCharacterConfigById(selectedCharacterId) then
            self._Main.Player.Name = XMVCA.XCharacter:GetCharacterName(selectedCharacterId)
            local storyConfig = self._Model:GetStoryConfig(selectedCharacterId)
            self._Main.Player.Icon = storyConfig.Icon
        else
            XLog.Error("[XPokerGuessing2Control] 不存在这个角色:", selectedCharacterId)
        end
    end
    return data
end

--- 构建对话数据结构
---@param content string 内容（文本或URL）
---@param isEmoji boolean 是否为表情
---@return table 对话数据 {Type, Text, Emoji}
function XPokerGuessing2Control:_BuildSpeakData(content, isEmoji)
    if isEmoji then
        return {
            Type = XPokerGuessing2Enum.SpeakShowType.Emoji,
            Text = "",
            Emoji = content or "",
        }
    else
        return {
            Type = XPokerGuessing2Enum.SpeakShowType.Text,
            Text = content or "",
            Emoji = "",
        }
    end
end

function XPokerGuessing2Control:GetDialogue(speak)
    local stageConfig = self:GetStagePerformConfig()
    local characterConfig = self:GetCharacterConfig()
    local enemyContent, enemyIsEmoji
    local playerContent, playerIsEmoji

    if speak == XPokerGuessing2Enum.Speak.GameWin then
        enemyContent, enemyIsEmoji = self:GetRandomSpeak(stageConfig.LineGameLose, stageConfig.EmojiGameLose,
            self._EnemyRandomSpeak, XPokerGuessing2Enum.Speak.GameLose)
        playerContent, playerIsEmoji = self:GetRandomSpeak(characterConfig.LineGameWin, characterConfig.EmojiGameWin,
            self._PlayerRandomSpeak, XPokerGuessing2Enum.Speak.GameWin)
    elseif speak == XPokerGuessing2Enum.Speak.GameLose then
        enemyContent, enemyIsEmoji = self:GetRandomSpeak(stageConfig.LineGameWin, stageConfig.EmojiGameWin,
            self._EnemyRandomSpeak, XPokerGuessing2Enum.Speak.GameWin)
        playerContent, playerIsEmoji = self:GetRandomSpeak(characterConfig.LineGameLose, characterConfig.EmojiGameLose,
            self._PlayerRandomSpeak, XPokerGuessing2Enum.Speak.GameLose)
    elseif speak == XPokerGuessing2Enum.Speak.RoundWin then
        enemyContent, enemyIsEmoji = self:GetRandomSpeak(stageConfig.LineRoundLose, stageConfig.EmojiRoundLose,
            self._EnemyRandomSpeak, XPokerGuessing2Enum.Speak.RoundLose)
        playerContent, playerIsEmoji = self:GetRandomSpeak(characterConfig.LineRoundWin, characterConfig.EmojiRoundWin,
            self._PlayerRandomSpeak, XPokerGuessing2Enum.Speak.RoundWin)
    elseif speak == XPokerGuessing2Enum.Speak.RoundLose then
        enemyContent, enemyIsEmoji = self:GetRandomSpeak(stageConfig.LineRoundWin, stageConfig.EmojiRoundWin,
            self._EnemyRandomSpeak, XPokerGuessing2Enum.Speak.RoundWin)
        playerContent, playerIsEmoji = self:GetRandomSpeak(characterConfig.LineRoundLose, characterConfig.EmojiRoundLose,
            self._PlayerRandomSpeak, XPokerGuessing2Enum.Speak.RoundLose)
    elseif speak == XPokerGuessing2Enum.Speak.RoundDraw then
        enemyContent, enemyIsEmoji = self:GetRandomSpeak(stageConfig.LineRoundDraw, stageConfig.EmojiRoundDraw,
            self._EnemyRandomSpeak, XPokerGuessing2Enum.Speak.RoundDraw)
        playerContent, playerIsEmoji = self:GetRandomSpeak(characterConfig.LineRoundDraw, characterConfig.EmojiRoundDraw,
            self._PlayerRandomSpeak, XPokerGuessing2Enum.Speak.RoundDraw)
    elseif speak == XPokerGuessing2Enum.Speak.RoundStart then
        local round = self._Game:GetRound()
        if string.IsNilOrEmpty(stageConfig.EmojiLevelStart[round]) then
            enemyContent = stageConfig.LineLevelStart[round]
            enemyIsEmoji = false
        else
            enemyContent = stageConfig.EmojiLevelStart[round]
            enemyIsEmoji = true
        end
        playerContent = nil -- 回合开始不显示玩家对话

        --if isTipsAlways then
        --    playerContent = characterConfig.LineLevelStart[round]
        --end
    elseif speak == XPokerGuessing2Enum.Speak.StrikeBack then
        -- 反杀效果：只改变敌人的表情（EmojiStrikeBack），玩家对话保留原逻辑（不在这里设置）
        enemyContent, enemyIsEmoji = self:GetRandomSpeak(nil, stageConfig.EmojiStrikeBack,
            self._EnemyRandomSpeak, XPokerGuessing2Enum.Speak.StrikeBack)
        -- playerContent 不设置，保留原逻辑
    elseif speak == XPokerGuessing2Enum.Speak.Boom then
        -- 炸弹效果：只显示敌人的表情（EmojiBoom）
        enemyContent, enemyIsEmoji = self:GetRandomSpeak(nil, stageConfig.EmojiBoom,
            self._EnemyRandomSpeak, XPokerGuessing2Enum.Speak.Boom)
        playerContent = nil -- 炸弹效果不显示玩家对话
    elseif speak == XPokerGuessing2Enum.Speak.Trap then
        -- 陷阱效果：只显示敌人的表情（EmojiTrap）
        enemyContent, enemyIsEmoji = self:GetRandomSpeak(nil, stageConfig.EmojiTrap,
            self._EnemyRandomSpeak, XPokerGuessing2Enum.Speak.Trap)
        playerContent = nil -- 陷阱效果不显示玩家对话
    end

    -- 除了回合开始外如果有改牌记录，则替换对方的对话内容
    if speak ~= XPokerGuessing2Enum.Speak.RoundStart then
        -- 先判断双方出的牌是不是被改过的
        local enemyLastCardId = self._Game:GetLastEnemyCardOriginId()
        local playerLastCardId = self._Game:GetLastPlayerCardOriginId()

        local isEnemyLastCardChanged = self._Game:CheckEnemyCardIsChanged(enemyLastCardId)
        local isPlayerLastCardChanged = self._Game:CheckPlayerCardIsChanged(playerLastCardId)

        -- 只有任意一方当局出的牌存在被修改的情况，才处理
        if isEnemyLastCardChanged or isPlayerLastCardChanged then
            -- 当不是双方的牌都修改的前提下，以改了牌的一方为准显示文本
            local showSideWithNotBothChanged = not isEnemyLastCardChanged and isPlayerLastCardChanged

            if isEnemyLastCardChanged and isPlayerLastCardChanged then
                -- 如果双方出的牌都是被改过的，那么以最后一次更改为准
                local isPlayerSide = self._Game:GetLatestChangeCardSide() == XPokerGuessing2Enum.PokerPlaySide.Player
                enemyContent, enemyIsEmoji = self:GetEnemyDialogAfterChangedCard(isPlayerSide)

                self._Game:SetLatestChangeCardSide(nil)
            else
                enemyContent, enemyIsEmoji = self:GetEnemyDialogAfterChangedCard(showSideWithNotBothChanged)
            end
        end
    end

    self._Game:SetLastEnemyCardOriginId(nil)
    self._Game:SetLastPlayerCardOriginId(nil)

    -- 构建规范的对话数据结构
    local result = {}

    -- 构建敌人对话数据
    if enemyContent then
        result.Enemy = self:_BuildSpeakData(enemyContent, enemyIsEmoji or false)
    end

    -- 构建玩家对话数据
    if playerContent then
        result.Player = self:_BuildSpeakData(playerContent, playerIsEmoji or false)
    end

    return result
end

function XPokerGuessing2Control:GetPlayerDialogAfterChangedCard(isChangedPlayerSide)
    local characterConfig = self:GetCharacterConfig()

    if isChangedPlayerSide then
        return self:GetRandomSpeak(characterConfig.LineChangeSelfCard, characterConfig.EmojiChangeSelfCard,
            self._PlayerRandomSpeak, XPokerGuessing2Enum.Speak.PlayerCardChanged)
    else
        return self:GetRandomSpeak(characterConfig.LineChangeEnemyCard, characterConfig.EmojiChangeEnemyCard,
            self._PlayerRandomSpeak, XPokerGuessing2Enum.Speak.EnemyCardChanged)
    end
end

function XPokerGuessing2Control:GetEnemyDialogAfterChangedCard(isChangedPlayerSide)
    local stageConfig = self:GetStagePerformConfig()

    if isChangedPlayerSide then
        return self:GetRandomSpeak(stageConfig.LineChangePlayerCard, stageConfig.EmojiChangePlayerCard,
            self._EnemyRandomSpeak, XPokerGuessing2Enum.Speak.PlayerCardChanged)
    else
        return self:GetRandomSpeak(stageConfig.LineChangeSelfCard, stageConfig.EmojiChangeSelfCard,
            self._EnemyRandomSpeak, XPokerGuessing2Enum.Speak.EnemyCardChanged)
    end
end

function XPokerGuessing2Control:RandomSpeak(array)
    if #array > 0 then
        local i = math.random(1, #array)
        return array[i]
    end
    return ""
end

---@param randomSpeaker XPokerGuessing2RandomSpeak
function XPokerGuessing2Control:GetRandomSpeak(dialogArray, emojiArray, randomSpeaker, speakPeriod)
    local val = randomSpeaker:GetRandomValBySpeakPeriod(speakPeriod)

    if XTool.IsNumberValid(val) then
        local showType = math.floor(val / 100)
        local index = math.floor(val % 100)

        if showType == XPokerGuessing2Enum.SpeakShowType.Text then
            return dialogArray[index]
        else
            return emojiArray[index], true
        end
    end

    --[[
    if not XTool.IsTableEmpty(emojiArray) then
        return self:RandomSpeak(emojiArray), true
    end

    return self:RandomSpeak(dialogArray)
    --]]
end

function XPokerGuessing2Control:GetActivityConfig()
    local activityId = self._Model:GetActivityId()
    local activityConfig = self._Model:GetPokerGuessing2ActivityConfigById(activityId)
    return activityConfig
end

function XPokerGuessing2Control:UpdateTime()
    local activityConfig = self:GetActivityConfig()
    if activityConfig then
        local timeId = activityConfig.TimeId
        local currentTime = XTime.GetServerNowTimestamp()
        self._Main.Time = math.max(0, XFunctionManager.GetEndTimeByTimeId(timeId) - currentTime)
    end
    if self._Main.Time <= 0 then
        XUiManager.RunMain()
        XUiManager.TipText("ActivityAlreadyClose")
    end
    XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_TIME)
end

function XPokerGuessing2Control:GetUiSelectRole()
    local data = self._SelectCharacter
    ---@class XPokerGuessing2UiCharacter
    local role = {
        Name = "",
        CharacterId = 0,
        Icon = nil,
        Id = 0,
    }
    return data
end

function XPokerGuessing2Control:Confirm()
    if self._Game:IsOver() then
        XLog.Warning("[XPokerGuessing2Control] 游戏已结束")
        return
    end

    local card = self._Game:GetPlayerCard()
    if not card then
        XUiManager.TipText("PokerGuessing2PleaseSelectCard")
        return
    end
    if not card:IsSelected() then
        XUiManager.TipText("PokerGuessing2PleaseSelectCard")
        return
    end

    local playerOriginalCardId = card:GetId()

    ---@param res ActionPokerGuessing2Response
    XMVCA.XPokerGuessing2:ActionPokerGuessing2Request(card, function(res)
        self._Game:RemoveCardFromPlayer(card:GetUid())
        self._Main.EnemyCardIndex = self._Game:SetEnemyCardAndRemoveFromList(res.RobotCard)

        if res.GoodList then
            self._Settlement.Rewards = res.GoodList
        else
            if not XTool.IsTableEmpty(self._Settlement.Rewards) then
                self._Settlement.Rewards = {}
            end
        end

        self._Game:SetEnemyScore(res.RobotScore)
        self._Game:SetPlayerScore(res.PlayerScore)
        self._Game:SetLastPlayerCardOriginId(playerOriginalCardId)
        self._Game:SetLastEnemyCardOriginId(res.RobotCard)

        local state = res.State
        local roundState = res.RoundState
        -- 获取回合效果字段
        -- 但是要交换这两个值，因为我出牌，敌人显示表情
        local roundPlayerEffect = res.RoundRobotEffect
        local roundRobotEffect = res.RoundPlayerEffect
        -- 获取玩家反杀分数并缓存
        local playerReverseScore = res.PlayerReverseScore
        if playerReverseScore then
            self._PlayerReverseScore = playerReverseScore
        end

        -- 如果配置了 EffectStrikeBack 字段，更新 StageStrikeBack
        if self._PlayerReverseScore then
            local stageConfig = self:GetStagePerformConfig()
            if stageConfig and stageConfig.EffectStrikeBack and stageConfig.EffectStrikeBack ~= "" then
                self._Main.StageStrikeBack = XUiHelper.FormatText(XUiHelper.ReplaceTextNewLine(stageConfig.EffectStrikeBack), self._PlayerReverseScore)
                -- 触发 UI 更新
                XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_STAGE_DESC)
            end
        end

        if state == XPokerGuessing2Enum.State.GameWin
            or state == XPokerGuessing2Enum.State.GameLose
        then
            local isWin = state == XPokerGuessing2Enum.State.GameWin
            self._Settlement.IsWin = isWin
            self._Game:SetIsOver(true)
            if isWin then
                self._Model:SetStagePassed(self._GameStageId)
            end
            self:SetCurrentStageId(nil, nil)
        else
            self._Game:SetRound(self._Game:GetRound() + 1)
            XMVCA.XPokerGuessing2:SetCurrentRound(self._Game:GetRound())
        end
        XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_PLAY_GAME_ANIMATION_CONFIRM_RESULT, state, roundState,
            roundPlayerEffect, roundRobotEffect)
        if state == XPokerGuessing2Enum.State.GameWin then
            self:MoveToRightStage()
        end
    end)
end

function XPokerGuessing2Control:UseTips()
    if self._Game:IsOver() then
        XLog.Warning("[XPokerGuessing2Control] 游戏已结束")
        return
    end
    if self._Game:GetTipsAmount() > 0 then
        XMVCA.XPokerGuessing2:UseTips2Request(function(res)
            self._Game:SetTipsAmount(self._Game:GetTipsAmount() - 1)
            self._Game:SetTipsCard(res.RobotCard)
            XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_SKILL_SHOW)
        end)
    else
        XUiManager.TipText("PokerGuessing2HelpOver")
    end
end

--- 使用技能修改自己出的牌
function XPokerGuessing2Control:UseSkillChangeSelfCard()
    if self._Game:IsOver() then
        XLog.Warning("[XPokerGuessing2Control] 游戏已结束")
        return
    end

    -- 检查是否有次数
    if self:CheckHasChangeSelfSkillCount() then
        -- 检查是否有打出牌
        local card = self._Game:GetPlayerCard()
        if not card then
            XUiManager.TipText("PokerGuessing2UseSkillInNoCardTips")
            return
        end
        if not XTool.IsNumberValid(card:GetId()) or not card:IsSelected() then
            XUiManager.TipText("PokerGuessing2UseSkillInNoCardTips")
            return
        end

        XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_OPEN_CHANGE_SKILL, true, card:GetId())
    else
        XUiManager.TipText("PokerGuessing2ChangeSelfCardSkillOver")
    end
end

--- 使用技能修改敌人出的牌
function XPokerGuessing2Control:UseSkillChangeEnemyCard()
    if self._Game:IsOver() then
        XLog.Warning("[XPokerGuessing2Control] 游戏已结束")
        return
    end

    -- 检查是否有次数
    if self:CheckHasChangeEnemySkillCount() then
        -- 检查是否有打出牌
        local card = self._Game:GetEnemyCard()
        if not card or not card:IsSelected() or not XTool.IsNumberValid(card:GetId()) then
            return
        end

        XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_OPEN_CHANGE_SKILL, false, 0)
    else
        XUiManager.TipText("PokerGuessing2ChangeEnemyCardSkillOver")
    end
end

--- 尝试生效修改牌的技能
function XPokerGuessing2Control:TrySummitSkillChange(playSide, originId, changedId, cb)
    if self._Game:IsOver() then
        XLog.Warning("[XPokerGuessing2Control] 游戏已结束")
        return
    end

    playSide = playSide and XPokerGuessing2Enum.PokerPlaySide.Player or XPokerGuessing2Enum.PokerPlaySide.Robot

    self:RequestChangeCardPokerGuessing2(playSide, originId, changedId, cb)
end

--- 判断是否还能使用改自己手牌的技能
function XPokerGuessing2Control:CheckHasChangeSelfSkillCount()
    return self._Game:GetChangePlayerCardCount() > 0
end

--- 判断是否还能使用改敌人手牌的技能
function XPokerGuessing2Control:CheckHasChangeEnemySkillCount()
    return self._Game:GetChangeRobotCardCount() > 0
end

function XPokerGuessing2Control:GetTipsAmount()
    local tipsAmount = self._Game:GetTipsAmount()
    local maxTipsAmount = self._Game:GetMaxTipsAmount()
    return tipsAmount, maxTipsAmount
end

function XPokerGuessing2Control:GetTipsCardSpeak()
    local tipsCard = self._Game:GetTipsCard()
    if tipsCard and not tipsCard:IsEmpty() then
        local characterConfig = self._Model:GetPokerGuessing2CharacterConfig(self._SelectedCharacterId)
        if characterConfig then
            local text = string.format(characterConfig.LineTips, tipsCard:GetName(self._Model))
            return text
        end
    end
end

function XPokerGuessing2Control:GetEnemy()
    local cardData
    local enemyCard = self._Game:GetEnemyCard()
    if enemyCard and not enemyCard:IsEmpty() then
        cardData = enemyCard:GetUiData(self._Model)
    end

    local enemyCards = self._Game:GetEnemyCards()
    local cards = {}
    for i = 1, #enemyCards do
        cards[i] = enemyCards[i]:GetUiData(self._Model)
    end

    local previewCards = {}
    for i = 1, #enemyCards do
        previewCards[i] = enemyCards[i]:GetUiData(self._Model, true)
    end

    local stageConfig = self:GetStageConfig()
    local stagePerformConfig = self:GetStagePerformConfig()

    ---@class XUiPokerGuessing2CharacterData
    local enemy = {
        Name = stagePerformConfig.NpcName,
        Icon = stagePerformConfig.Icon,
        Card = cardData,
        Cards = cards,
        PreviewCards = previewCards,
        TimeId = stageConfig.TimeId,
        IsLock = not self._Model:IsStageCanChallenge(self._Main.StageId),
        IsLock4Time = not self._Model:IsStageOnTime(self._Main.StageId),
    }
    self._Main.Enemy = enemy
    return enemy
end

function XPokerGuessing2Control:GetPlayer()
    local cardData
    local playerCard = self._Game:GetPlayerCard()
    if not playerCard:IsEmpty() then
        cardData = playerCard:GetUiData(self._Model)
    end
    local playerCards = self._Game:GetPlayerCards()
    local cards = {}
    for i = 1, #playerCards do
        cards[i] = playerCards[i]:GetUiData(self._Model)
    end
    if XMVCA.XCharacter:GetModelCharacterConfigById(self._SelectedCharacterId) then
        local character = self:GetCharacterConfig()
        local player = {
            Name = XMVCA.XCharacter:GetCharacterName(self._SelectedCharacterId),
            Icon = character.Icon,
            Card = cardData,
            Cards = cards
        }
        self._Main.Player = player
    end
    return self._Main.Player
end

function XPokerGuessing2Control:GetPlayerSelectCardData()
    local cardData
    local playerCard = self._Game:GetPlayerCard()
    if not playerCard:IsEmpty() then
        cardData = playerCard:GetUiData(self._Model)
    end

    return cardData
end

function XPokerGuessing2Control:GetEnemySelectCardData()
    local cardData
    local enemyCard = self._Game:GetEnemyCard()
    if not enemyCard:IsEmpty() then
        cardData = enemyCard:GetUiData(self._Model)
    end

    return cardData
end

--- 获取服务端下发的牌组Id列表
function XPokerGuessing2Control:GetCardGroup()
    return self._Game:GetCardGroup()
end

function XPokerGuessing2Control:GetStageConfig()
    return self._Model:GetPokerGuessing2StageConfigById(self._Main.StageId)
end

function XPokerGuessing2Control:GetStagePerformConfig()
    return self._Model:GetPokerGuessing2StagePerformCfgById(self._Main.StageId)
end

function XPokerGuessing2Control:GetCharacterConfig()
    return self._Model:GetPokerGuessing2CharacterConfig(self._SelectedCharacterId)
end

--- 获取当前选择角色的改牌图案
function XPokerGuessing2Control:GetCharacterChangeCardIcon()
    local cfg = self:GetCharacterConfig()

    if cfg then
        return cfg.ChangeCardIcon
    end
end

---@param data XUiPokerGuessing2CardData
function XPokerGuessing2Control:SetSelectedCard(data)
    if not data then
        self._Game:SetPlayerCard(nil)
        return
    end
    self._Game:SetPlayerCard(data.Uid)
end

---@param data XUiPokerGuessing2CardData
function XPokerGuessing2Control:SetEnemySelectedCard(data)
    if not data then
        self._Game:SetEnemyCard(nil)
        return
    end
    self._Game:SetEnemyCard(data.Uid)
end

---@param data XUiPokerGuessing2CardData
function XPokerGuessing2Control:IsSelectedCard(data)
    if data then
        ---@type XPokerGuessing2Card
        local playerCard = self._Game:GetPlayerCard()
        if playerCard and not playerCard:IsEmpty() then
            return playerCard:GetUid() == data.Uid
        end
    end
    return false
end

function XPokerGuessing2Control:SetSelectedCharacter(id)
    local characterConfig = self._Model:GetPokerGuessing2CharacterConfig(id)
    if characterConfig then
        self._SelectedCharacterId = id
        XSaveTool.SaveData("PokerGuessing2CharacterId" .. XPlayer.Id, id)
    end
end

function XPokerGuessing2Control:GetTime()
    return self._Main.Time
end

function XPokerGuessing2Control:GetRewards()
    local stageConfig = self:GetStageConfig()
    local rewards = XRewardManager.GetRewardList(stageConfig.RewardId)
    return rewards
end

function XPokerGuessing2Control:GetStageCards()
    local stageConfig = self:GetStagePerformConfig()
    local icons = stageConfig.CardIcon
    local cards = {}
    for i = 1, #icons do
        local data = {
            Icon = icons[i],
        }
        table.insert(cards, data)
    end
    return cards
end

function XPokerGuessing2Control:MoveToLeftStage()
    local stageIndex = self._Main.StageIndex
    local stageList = self:GetStageList()
    if stageIndex > 1 then
        local stageConfig = stageList[stageIndex - 1]
        self._Main.StageId = stageConfig.Id
        self._Main.StageIndex = stageIndex - 1
    end
end

function XPokerGuessing2Control:MoveToRightStage()
    local stageIndex = self._Main.StageIndex
    local stageList = self:GetStageList()
    if stageIndex < #stageList then
        local stageConfig = stageList[stageIndex + 1]
        self._Main.StageId = stageConfig.Id
        self._Main.StageIndex = stageIndex + 1
    end
end

function XPokerGuessing2Control:GetSelectedCharacterId()
    return self._SelectedCharacterId
end

function XPokerGuessing2Control:GetCharacterList()
    local characters = self._Model:GetAllCharacters()
    local list = {}
    for i = 1, #characters do
        local character = characters[i]
        if XMVCA.XCharacter:GetModelCharacterConfigById(character.Id) then
            local isUse = self._SelectedCharacterId == character.Id
            ---@class XUiPokerGuessing2PopupSelectRoleGridData
            local data = {
                Id = character.Id,
                Icon = character.CircularIcon,
                Name = XMVCA.XCharacter:GetCharacterName(character.Id),
                IsUse = isUse,
                IsSelected = isUse
            }
            table.insert(list, data)
        end
    end
    return list
end

function XPokerGuessing2Control:GetTaskGroupIds()
    local activityConfig = self:GetActivityConfig()
    return activityConfig.TaskGroupId
end

function XPokerGuessing2Control:GetActivityEndTime()
    local activityConfig = self:GetActivityConfig()
    return XFunctionManager.GetEndTimeByTimeId(activityConfig.TimeId)
end

function XPokerGuessing2Control:GetActivityTimerId()
    local activityConfig = self:GetActivityConfig()
    return activityConfig.TimeId
end

function XPokerGuessing2Control:GetActivityId()
    return self._Model:GetActivityId() or 0
end

--- 获取是否显示未播放剧情优先（按activityId区分）
---@return boolean 是否显示未播放剧情优先，默认true
function XPokerGuessing2Control:GetShowUnplayedStoriesFirst()
    local activityId = self:GetActivityId()
    return self._Model:GetShowUnplayedStoriesFirst(activityId)
end

--- 设置是否显示未播放剧情优先（按activityId区分）
---@param isOn boolean 是否显示未播放剧情优先
function XPokerGuessing2Control:SetShowUnplayedStoriesFirst(isOn)
    local activityId = self:GetActivityId()
    self._Model:SetShowUnplayedStoriesFirst(activityId, isOn)
end

function XPokerGuessing2Control:GetRound()
    return self._Game:GetRound()
end

function XPokerGuessing2Control:IsGameOver()
    return self._Game:IsOver()
end

function XPokerGuessing2Control:GetSettlement()
    local settlement = self._Settlement
    settlement.Round = self._Game:GetRound()
    return settlement
end

---@param data XUiPokerGuessing2StoryGridData
function XPokerGuessing2Control:PlayStory(data)
    if data.StoryId == "" or data.StoryId == nil then
        XLog.Error("[XPokerGuessing2Control] 剧情Id为空", data.Id)
        return
    end
    XSaveTool.SaveData("PokerGuessing2StoryPlayed" .. XPlayer.Id .. data.StoryId, true)
    XDataCenter.MovieManager.PlayMovie(data.StoryId)
end

---@param data XUiPokerGuessing2StoryGridData
function XPokerGuessing2Control:UnlockStory(data)
    -- Type=Previous 代表往期角色剧情，不消耗道具，直接播放
    local storyType = data.Type or self._Model:GetPokerGuessing2StoryTypeById(data.Id)
    if storyType == XPokerGuessing2Enum.StoryType.Previous then
        self:PlayStory(data)
        return
    end

    local itemAmount = XDataCenter.ItemManager.GetCount(data.TicketId)
    if itemAmount < data.TicketCost then
        XUiManager.TipText("PokerGuessing2StoryInviteNoEnoughTicket")
        return
    end
    local sureCallback = function()
        XMVCA.XPokerGuessing2:UnlockStoryPokerGuessing2Request(data.Id, function()
            self._Model:SetStoryUnlock(data.Id)
            XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_STORY)
            self:PlayStory(data)
        end)
    end

    local key = "XPokerGuessing2Invite" .. XPlayer.Id
    local updateTime = XSaveTool.GetData(key)
    local isShowToday = false
    if updateTime then
        isShowToday = XTime.GetServerNowTimestamp() < updateTime
    end
    if isShowToday then
        sureCallback()
        return
    end
    local title = XUiHelper.GetText("PokerGuessing2StoryInviteTitle")
    local content = XUiHelper.GetText("PokerGuessing2StoryInviteContent")
    local content2 = ""
    local closeCallback = nil
    local hintInfo = {
        SetHintCb = function(isSelect)
            if not isSelect then
                XSaveTool.RemoveData(key)
            else
                XSaveTool.SaveData(key, XTime.GetSeverTomorrowFreshTime())
            end
        end,
        Status = isShowToday
    }
    XUiManager.DialogHintTip(title, content, content2, closeCallback, sureCallback, hintInfo)
end

function XPokerGuessing2Control:GetStoryList()
    local configs = self._Model:GetPokerGuessing2StoryConfigs()
    local list = {}
    local curActivityId = self._Model:GetActivityId()

    for id, config in pairs(configs) do
        if config.ActivityId == curActivityId then
            local storyId = config.StoryId
            local characterId = config.CharacterId
            local name = XMVCA.XCharacter:GetCharacterName(characterId)
            local storyType = self._Model:GetPokerGuessing2StoryTypeById(config.Id)
            -- Type=Previous 代表往期角色剧情，默认解锁且已观看
            local isUnlock = self._Model:IsStoryUnlock(config.Id)
            local isPlayed = false
            if storyType == XPokerGuessing2Enum.StoryType.Previous then
                isUnlock = true
                isPlayed = true
            else
                isPlayed = XSaveTool.GetData("PokerGuessing2StoryPlayed" .. XPlayer.Id .. tostring(storyId)) or false
            end
            ---@class XUiPokerGuessing2StoryGridData
            local data = {
                Id = config.Id,
                Name = name,
                Icon = config.Icon,
                IsUnlock = isUnlock,
                StoryId = storyId,
                TicketId = config.UnlockItemId,
                TicketCost = config.Cost,
                IsPlayed = isPlayed,
                Type = storyType
            }
            table.insert(list, data)
        end
    end
    table.sort(list, function(a, b)
        return a.Id < b.Id
    end)
    return list
end

function XPokerGuessing2Control:IsStageOnTime()
    local stageId = self._Main.StageId
    return self._Model:IsStageOnTime(stageId)
end

function XPokerGuessing2Control:IsPreStagePassed()
    local stageId = self._Main.StageId
    return self._Model:IsPreStagePassed(stageId)
end

function XPokerGuessing2Control:SetCurrentStageId(stageId, round)
    XMVCA.XPokerGuessing2:SetCurrentStageId(stageId)
    XMVCA.XPokerGuessing2:SetCurrentRound(round)
end

function XPokerGuessing2Control:GetPokerGuessing2CardSmallAssetPathById(id)
    return self._Model:GetPokerGuessing2CardSmallAssetPathById(id)
end

function XPokerGuessing2Control:GetPokerGuessing2CardChangedFrontAssetPathById(id)
    return self._Model:GetPokerGuessing2CardChangedFrontAssetPathById(id)
end

--region 局内协议

function XPokerGuessing2Control:RequestChangeCardPokerGuessing2(playSide, originalCard, changedCard, cb)
    local content = {
        PlaySide = playSide,
        OriginalCard = originalCard,
        ChangedCard = changedCard,
    }


    XNetwork.Call("ChangeCardPokerGuessing2Request", content, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)

            if cb then
                cb(false)
            end

            return
        end

        local isChangedPlayerSide = res.PlaySide == XPokerGuessing2Enum.PokerPlaySide.Player

        if isChangedPlayerSide then
            -- 扣除本地缓存的使用次数
            self._Game:ModifyChangePlayerCardCount(-1)

            self._Game:SetPlayerCardsChangedMap(res.ChangedCards)
        else
            -- 扣除本地缓存的使用次数
            self._Game:ModifyChangeRobotCardCount(-1)

            self._Game:SetEnemyCardsChangedMap(res.ChangedCards)
        end

        self._Game:SetLatestChangeCardSide(res.PlaySide)

        if cb then
            cb(true, res)
        end

        XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_UPDATE_SKILL_SHOW)
        XEventManager.DispatchEvent(XEventId.EVENT_POKER_GUESSING2_CHANGE_CARD_SUCCESS, isChangedPlayerSide)
    end)
end

--endregion

--region Config

function XPokerGuessing2Control:GetConfigItemId()
    return self._Model:GetPokerGuessing2ConfigParamById(XPokerGuessing2Enum.ConfigId.ItemId)
end

--endregion

return XPokerGuessing2Control
