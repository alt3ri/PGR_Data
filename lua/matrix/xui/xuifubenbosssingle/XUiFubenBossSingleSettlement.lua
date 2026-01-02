local XUiFubenBossSingleSettlementGridSelectableFeature = require("XUi/XUiFubenBossSingle/XUiFubenBossSingleSettlementGridSelectableFeature")

---@class XUiFubenBossSingleSettlement : XLuaUi
---@field TxtTotalScoreRate UnityEngine.UI.Text  -- v4.2 新增：总讨伐值倍率显示
---@field PanelSelectableFeatures UnityEngine.RectTransform  -- v4.2 新增：可选词缀面板
---@field ListSelectableFeatures UnityEngine.RectTransform  -- v4.2 新增：可选词缀列表
---@field GridSelectableFeature UnityEngine.RectTransform  -- v4.2 新增：可选词缀Grid模板
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingleSettlement = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingleSettlement")

function XUiFubenBossSingleSettlement:OnAwake()
    self:AutoAddListener()
    -- v4.2 新增：初始化可选词缀列表
    ---@type XUiNode[]
    self._SelectableFeatureGridList = {}
    -- v4.2 新增：初始化挑战面板的可选feature列表
    ---@type XUiFubenBossSingleSettlementGridSelectableFeature[]
    self._ChallengeFeatureGridList = {}
end

function XUiFubenBossSingleSettlement:OnStart(data)
    self:ShowPanel(data)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiFubenBossSingleSettlement:OnEnable()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SAVE_NEW_RECORD, self.OnBtnCloseClick, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_HIDE_SETTLE, self.Hide, self)
    XDataCenter.FunctionEventManager.UnLockFunctionEvent()
    -- TODO: 确认新界面的动画名称
    -- self:PlayAnimation("PanelBossSingleinfo")
    self:OnActivityEnd()
end

function XUiFubenBossSingleSettlement:OnDisable()
    -- TODO: 界面隐藏时的逻辑
    XLog.Debug("OnDisable")
end

function XUiFubenBossSingleSettlement:OnDestroy()
    XLog.Debug("OnDestroy")
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_SAVE_NEW_RECORD, self.OnBtnCloseClick, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_HIDE_SETTLE, self.Hide, self)
    XDataCenter.AntiAddictionManager.EndFightAction()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiFubenBossSingleSettlement:OnActivityEnd()
    self._Control:OnActivityEnd()
end

function XUiFubenBossSingleSettlement:AutoAddListener()
    -- TODO: 确认新界面是否有 BtnLeft，如果没有则用 BtnCancel 代替
    -- self:RegisterClickEvent(self.BtnLeft, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSave, self.OnBtnSaveClick)
    self:RegisterClickEvent(self.BtnCancel, self.OnBtnCancelClick)
end

-- region 私有辅助方法

-- 安全设置文本
---@param textComponent UnityEngine.UI.Text
---@param text string|number
local function SafeSetText(textComponent, text)
    if textComponent and not XTool.UObjIsNil(textComponent) then
        textComponent.text = tostring(text)
    end
end

-- 安全设置GameObject激活状态
---@param gameObject any
---@param active boolean
local function SafeSetActive(gameObject, active)
    if gameObject and not XTool.UObjIsNil(gameObject) then
        if gameObject.SetActiveEx then
            gameObject:SetActiveEx(active)
        elseif gameObject.SetActive then
            gameObject:SetActive(active)
        end
    end
end

-- 获取按钮的文本组件
---@param button XUiComponent.XUiButton
---@return UnityEngine.UI.Text|nil
function XUiFubenBossSingleSettlement:GetButtonTextComponent(button)
    if not button or XTool.UObjIsNil(button.transform) then
        return nil
    end
    local textTransform = button.transform:Find("Text")
    if not textTransform then
        return nil
    end
    return textTransform:GetComponent("Text")
end

-- 设置按钮文本
---@param button XUiComponent.XUiButton
---@param text string
function XUiFubenBossSingleSettlement:SetButtonText(button, text)
    local textComponent = self:GetButtonTextComponent(button)
    if textComponent then
        textComponent.text = text
    end
end

-- 设置按钮文本显示状态
---@param button XUiComponent.XUiButton
---@param active boolean
function XUiFubenBossSingleSettlement:SetButtonTextActive(button, active)
    local textComponent = self:GetButtonTextComponent(button)
    if textComponent then
        SafeSetActive(textComponent.gameObject, active)
    end
end

-- 显示新纪录标签
function XUiFubenBossSingleSettlement:ShowNewRecordTag()
    if not self.TagNewRecord or XTool.UObjIsNil(self.TagNewRecord) then
        return
    end

    local myTotalHistory = self:GetMyTotalHistory()
    if self.CurAllScore > myTotalHistory then
        self.TagNewRecord.gameObject:SetActiveEx(true)
        self.TagNewRecord.gameObject.transform.localScale = CS.UnityEngine.Vector3.one
        self.TagNewRecord.gameObject:PlayTimelineAnimation()
    end
end

-- 初始化新纪录标签
function XUiFubenBossSingleSettlement:InitNewRecordTag()
    if self.TagNewRecord then
        self.TagNewRecord.gameObject.transform.localScale = CS.UnityEngine.Vector3.zero
    end
end

-- endregion

function XUiFubenBossSingleSettlement:ShowPanel(data)
    self.IsClash = false
    self:InitNewRecordTag()
    self.StageId = data.StageId
    self.IsSave = true

    local isChallenge = self._Control:IsBossSingleChallenge()
    local difficultName = self._Control:GetBossDifficultName(data.StageId)

    SafeSetText(self.TxtBossDifficulty, difficultName)

    -- Boss名称显示
    if self.TxtBossName then
        local bossId = self._Control:GetBossIdByStageId(data.StageId)
        self.TxtBossName.text = self._Control:GetBossName(bossId)
    end

    local settleData = data.SettleData
    local result = settleData.BossSingleFightResult

    -- TODO: 确认新界面是否有 PanelLeftTime 组件
    local showLeftTime = result.MaxTimeScore
    SafeSetActive(self.PanelLeftTime, showLeftTime > 0)

    local myTotalHistory = self:GetMyTotalHistory()
    local stageInfo = self._Control:GetBossStageInfo(data.StageId)
    local bossTotalScore = (stageInfo and stageInfo.Score or 0) + self._Control:GetBaseScoreByStageId(data.StageId)
    local curBossTotalScore = self._Control:GetBossCurSettleScore(data.StageId, result.TotalScore)
    local curBossMaxScore = self._Control:GetBossMaxScoreByStageId(data.StageId)

    self.CurAllScore = result.TotalScore

    -- TODO: 以下UI组件需要确认新界面是否存在，如果不存在则注释掉
    SafeSetText(self.TxtBossAllLoseHpScore, XUiHelper.GetText("BossSingleAutoFightDesc10", result.MaxBossDamageScore))
    SafeSetText(self.TxAlltLeftTimeScore, XUiHelper.GetText("BossSingleAutoFightDesc10", showLeftTime))
    SafeSetText(self.TxtAllCharLeftHpScore, XUiHelper.GetText("BossSingleAutoFightDesc10", result.MaxHpScore))
    -- SafeSetActive(self.TxtHistoryScore2, not isChallenge)
    -- SafeSetActive(self.TxtHistoryScoreDesc2, not isChallenge)

    if self.GameObject then
        self.GameObject:SetActiveEx(true)
    end

    -- 播放音效
    self.AudioInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX,
        XLuaAudioManager.UiBasicsMusic.UiSettle_Win_Number)

    -- 播放分数动画
    self:PlayScoreAnimation(result, myTotalHistory, bossTotalScore, curBossTotalScore, curBossMaxScore, isChallenge)

    self:RefreshButton(data)
    self:RefreshNewUI(data)
end

-- 播放分数动画
function XUiFubenBossSingleSettlement:PlayScoreAnimation(result, myTotalHistory, bossTotalScore, curBossTotalScore,
                                                         curBossMaxScore, isChallenge)
    local time = CS.XGame.ClientConfig:GetFloat("BossSingleAnimaTime")
    XUiHelper.Tween(time, function(f)
        if XTool.UObjIsNil(self.Transform) then
            return
        end

        local totalTimeText = XUiHelper.GetTime(math.floor(f * result.FightTime))
        local allScoreText = math.floor(f * result.TotalScore)
        local historyScoreText = math.floor(f * myTotalHistory) .. "/" .. bossTotalScore

        SafeSetText(self.TxtClearTime, totalTimeText)

        local bossLoseHpText = math.floor(f * result.BossDamagePer)
        local bossLoseHpScoreText = math.floor(f * result.BossDamageScore)
        local leftTimeText = XUiHelper.GetTime(math.floor(f * result.TimeLeft))
        local leftTimeScoreText = math.floor(f * result.TimeScore)
        local charLeftHpText = math.floor(f * result.HpLeftPer)
        local charLeftHpScoreText = math.floor(f * result.HpScore)
        SafeSetText(self.TxtBossLoseHp, bossLoseHpText)
        SafeSetText(self.TxtBossLoseHpScore, bossLoseHpScoreText)
        SafeSetText(self.TxtLeftTime, leftTimeText)
        SafeSetText(self.TxtLeftTimeScore, leftTimeScoreText)
        SafeSetText(self.TxtCharLeftHp, charLeftHpText)
        SafeSetText(self.TxtCharLeftHpScore, charLeftHpScoreText)
        SafeSetText(self.TxtScore, allScoreText)
        SafeSetText(self.TxtScoreTotal, curBossTotalScore)
    end, function()
        if XTool.UObjIsNil(self.Transform) then
            return
        end
        
        self:ShowNewRecordTag()
        self:StopAudio()
    end)
end

function XUiFubenBossSingleSettlement:RefreshNewUI(data)
    -- 1. 刷新特征信息显示（显示进入战斗的feature）
    if self.PanelFeature and self.TxtFeatureName and self.IconFeature then
        local challengeData = self._Control:GetBossSingleChallengeData()
        if challengeData then
            -- 获取进入战斗的feature ID
            local currentFeatureId = self._Control:GetCurrentFeatureId()
            if currentFeatureId and currentFeatureId > 0 then
                -- 通过feature ID获取feature对象
                local feature = challengeData:GetFeatureById(currentFeatureId)
                if feature then
                    -- 显示feature名称和图标
                    self.PanelFeature.gameObject:SetActiveEx(true)
                    SafeSetText(self.TxtFeatureName, feature:GetName())
                    if self.IconFeature and self.IconFeature.SetRawImage then
                        self.IconFeature:SetRawImage(feature:GetIcon())
                    end
                else
                    -- 找不到对应的feature，隐藏面板
                    self.PanelFeature.gameObject:SetActiveEx(false)
                end
            else
                -- 没有进入战斗的feature，隐藏面板
                self.PanelFeature.gameObject:SetActiveEx(false)
            end
        else
            self.PanelFeature.gameObject:SetActiveEx(false)
        end
    end

    -- 2. 刷新角色列表显示
    if self.ListCharacter and self.GridCharacter1 then
        -- 显示参与战斗的角色列表
        for _, v in ipairs(data.SettleData.NpcHpInfo) do
            local characterId = v.CharacterId
            if characterId and characterId > 0 then
                local grid = self.GridCharacter1
                local gridObj = XUiHelper.Instantiate(grid, self.ListCharacter)
                local imgHead = gridObj.transform:Find("RImgHead")
                if imgHead then
                    local rawImage = imgHead:GetComponent("RawImage")
                    if rawImage then
                        rawImage:SetRawImage(XMVCA.XCharacter:GetCharBigHeadIcon(characterId))
                    end
                end
            end
        end
        self.GridCharacter1.gameObject:SetActiveEx(false)
    end

    -- 3. 刷新挑战相关信息显示（显示选中的可选feature，type=2）
    if self.PanelChallenge and self.GridChallenge and self.ListChallenge then
        local currentBuffFeatureId = self._Control:GetCurrentFeatureId()
        local selectedFeatureIds = {}
        if currentBuffFeatureId and currentBuffFeatureId > 0 then
            selectedFeatureIds = self._Control:GetSelectedSelectableFeatureIds(currentBuffFeatureId) or {}
        end
        if XTool.IsTableEmpty(selectedFeatureIds) then
            -- 没有选中的可选feature，隐藏面板
            self.PanelChallenge.gameObject:SetActiveEx(false)
        else
            -- 显示面板
            self.PanelChallenge.gameObject:SetActiveEx(true)
            
            -- 隐藏模板
            self.GridChallenge.gameObject:SetActiveEx(false)
            
            local count = 0
            
            -- 遍历选中的feature IDs，显示对应的可选feature信息
            for _, featureId in ipairs(selectedFeatureIds) do
                -- 直接从配置获取可选feature的信息
                local featureConfig = XMVCA.XFubenBossSingle:GetFeatureConfigById(featureId)
                if featureConfig and featureConfig.Type == 2 then
                    count = count + 1
                    local grid = self._ChallengeFeatureGridList[count]
                    
                    if not grid then
                        local gridObj = XUiHelper.Instantiate(self.GridChallenge, self.ListChallenge)
                        -- 创建子UI节点
                        grid = XUiFubenBossSingleSettlementGridSelectableFeature.New(gridObj, self)
                        self._ChallengeFeatureGridList[count] = grid
                    end
                    
                    -- 刷新显示可选feature信息
                    grid:Refresh(featureConfig)
                    grid:Open()
                end
            end
            
            -- 隐藏多余的Grid
            for i = count + 1, #self._ChallengeFeatureGridList do
                if self._ChallengeFeatureGridList[i] then
                    self._ChallengeFeatureGridList[i]:Close()
                end
            end
        end
    end

    -- TODO: 5. 刷新分数加成百分比显示
    -- if self.TxtScoreAddPercent then
    --     -- 计算并显示分数加成百分比
    -- end
    
    -- v4.2 新增：刷新总倍率显示
    self:_RefreshTotalScoreRate()
    
    -- v4.2 新增：刷新选中的可选词缀显示
    self:_RefreshSelectableFeatures()
end

function XUiFubenBossSingleSettlement:SetDefaultText()
    -- TODO: 确认新界面的UI组件名称后，设置默认文本
    SafeSetText(self.TxtClearTime, XUiHelper.GetTime(0))
    SafeSetText(self.TxtScoreTotal, "0")
    -- TODO: 其他UI组件的默认值设置
end

function XUiFubenBossSingleSettlement:StopAudio()
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
end

function XUiFubenBossSingleSettlement:OnBtnCloseClick()
    self:StopAudio()
    -- 退出战斗（参考 XUiTransfiniteBattleSettlement）
    XMVCA.XFubenBossSingle:ExitFight()
    self:Close()
    XTipManager.Execute()
end

function XUiFubenBossSingleSettlement:OnBtnSaveClick()
    if self.IsClash then
        self._Control:OpenChallengeSaveDialog(self.CharacterIds, self.CurAllScore, self.StageId, self.ClashMap)
    elseif self.IsSave then
        XMVCA.XFubenBossSingle:RequestSaveScore(self.StageId, function(isTip)
            -- 退出战斗（参考 XUiTransfiniteBattleSettlement）
            XMVCA.XFubenBossSingle:ExitFight()
            self:OnBtnCloseClick()
            if isTip then
                XUiManager.TipText("BossSignleBufenTip", XUiManager.UiTipType.Tip)
            end
        end)
    else
        self:OnBtnCloseClick()
    end
end

function XUiFubenBossSingleSettlement:OnBtnCancelClick()
    local myTotalHistory = self:GetMyTotalHistory()

    if self.CurAllScore <= myTotalHistory then
        self._Control:SetIsUseSelectIndex(true)
        self:OnBtnCloseClick()
    else
        local titletext = XUiHelper.GetText("TipTitle")
        local contenttext = XUiHelper.GetText("BossSingleReslutDesc")
        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            self._Control:SetIsUseSelectIndex(true)
            -- 退出战斗（参考 XUiTransfiniteBattleSettlement）
            XMVCA.XFubenBossSingle:ExitFight()
            self:OnBtnCloseClick()
        end)
    end
end

function XUiFubenBossSingleSettlement:GetMyTotalHistory()
    local isTrial = self._Control:IsBossSingleTrial()

    if isTrial then
        local data = self._Control:GetBossSingleData()
        local stageData = data:GetBossSingleTrialStageInfoByStageId(self.StageId)
        return stageData and stageData:GetScore() or 0
    else
        local stageData = XMVCA.XFuben:GetStageData(self.StageId)
        return stageData and stageData.Score or 0
    end
end

function XUiFubenBossSingleSettlement:RefreshButton(data)
    local isNormal = self._Control:IsBossSingleNormal()
    self:SetButtonTextActive(self.BtnSave, isNormal)

    if isNormal then
        self:RefreshNormalButton(data)
    else
        self:RefreshChallengeButton(data)
    end
end

-- 刷新普通模式的按钮
function XUiFubenBossSingleSettlement:RefreshNormalButton(data)
    if not self._Control:IsResetOpen() then
        return
    end

    -- 这一关第一次进来，还没保存过分数 do nothing
    local stageId = data.StageId
    -- 重置功能开启时，检查当前期记录（RecordCurrent），而不是历史记录（HistoryList）
    local currentRecord = self._Control:GetRecordCurrentByStageId(stageId)
    if not currentRecord then
        return
    end

    local score = self._Control:GetStageCurrentScore(stageId)
    if score <= 0 then
        return
    end

    local bossId = self._Control:GetBossIdByStageId(stageId)
    local teamId = self._Control:GetTeamIdByBossId(bossId)
    ---@type XTeam
    local team = XDataCenter.TeamManager.GetXTeam(teamId)
    local isChange = XMVCA.XFubenBossSingle:CheckTeamDifferentWithRecord(stageId, team)
    
    -- 如果和挑战的记录角色不相同，则显示"扣除角色耐力"
    -- 如果和挑战的记录角色相同，则显示"不额外扣除角色耐力及挑战次数"
    if isChange then
        local text = XUiHelper.GetText("BossSingleSettleTips2")
        self:SetButtonText(self.BtnSave, text)
    else
        local text = XUiHelper.GetText("BossSingleSettleTips1")
        self:SetButtonText(self.BtnSave, text)
    end
end

-- 刷新挑战模式的按钮
function XUiFubenBossSingleSettlement:RefreshChallengeButton(data)
    local isChallenge = self._Control:IsBossSingleChallenge()
    if not isChallenge then
        return
    end

    local myTotalHistory = self:GetMyTotalHistory()
    local characterList = data.CharExp
    local challengeData = self._Control:GetBossSingleChallengeData()

    if self.CurAllScore <= myTotalHistory then
        self.IsSave = false
        SafeSetActive(self.BtnCancel, false)
        if self.BtnSave then
            self.BtnSave:SetNameByGroup(0, XUiHelper.GetText("BossSingleModeExit"))
        end
        return
    end

    -- 检查角色冲突
    local characterIds, isClash, clashFeatureMap = self:CheckCharacterClash(characterList, challengeData)

    if isClash then
        self.IsClash = true
        self.ClashMap = clashFeatureMap
        self.CharacterIds = characterIds
    else
        SafeSetActive(self.BtnCancel, false)
        if self.BtnSave then
            self.BtnSave:SetNameByGroup(0, XUiHelper.GetText("BossSingleModeSaveAndExit"))
        end
    end
end

-- 检查角色冲突
---@param characterList table
---@param challengeData XBossSingleChallenge
---@return table, boolean, table
function XUiFubenBossSingleSettlement:CheckCharacterClash(characterList, challengeData)
    local characterIds = {}
    local isClash = false
    local clashFeatureMap = {}

    if XMVCA.XFubenBossSingle:GetRelieveTeamAstrict() then
        -- 先锋服解除编队限制，不检查冲突
        return characterIds, isClash, clashFeatureMap
    end

    if XTool.IsTableEmpty(characterList) then
        return characterIds, isClash, clashFeatureMap
    end

    for _, exp in pairs(characterList) do
        table.insert(characterIds, exp.Id)
        if challengeData:CheckCharacterClash(exp.Id) then
            local feature = challengeData:GetClashFeature(exp.Id)
            if feature and feature:GetStageId() ~= self.StageId then
                isClash = true
                clashFeatureMap[feature:GetFeatureId()] = feature
            end
        end
    end

    return characterIds, isClash, clashFeatureMap
end

--- 隐藏结算界面（参考 XUiTransfiniteBattleSettlement.Hide）
function XUiFubenBossSingleSettlement:Hide()
    if self.GameObject and not XTool.UObjIsNil(self.GameObject) then
        self.GameObject:SetActiveEx(false)
    end
end

-- v4.2 新增：计算并刷新总讨伐值倍率
function XUiFubenBossSingleSettlement:_RefreshTotalScoreRate()
    if not self._Control then
        return
    end
    
    local challengeData = self._Control:GetBossSingleChallengeData()
    if not challengeData then
        return
    end
    
    local totalRate = 0
    
    -- 1. 计算所有原本feature（type=1）的倍率
    local featureCount = challengeData:GetFeatureCount()
    for i = 1, featureCount do
        local feature = challengeData:GetFeatureByIndex(i)
        if feature and not feature:IsSelectable() then
            totalRate = totalRate * feature:GetScoreRate()
        end
    end
    
    -- 2. 计算所有选中的可选feature（type=2）的倍率
    local currentBuffFeatureId = self._Control:GetCurrentFeatureId()
    local selectedFeatureIds = {}
    if currentBuffFeatureId and currentBuffFeatureId > 0 then
        selectedFeatureIds = self._Control:GetSelectedSelectableFeatureIds(currentBuffFeatureId) or {}
    end
    for _, featureId in ipairs(selectedFeatureIds) do
        -- 直接从配置获取可选feature的信息
        local featureConfig = XMVCA.XFubenBossSingle:GetFeatureConfigById(featureId)
        if featureConfig and featureConfig.ScoreRate then
            totalRate = totalRate + (featureConfig.ScoreRate or 0)
        end
    end
    
    -- 3. 显示总倍率
    if totalRate > 0 then
        if self.TxtScoreAddPercent then
            self.TxtScoreAddPercent.gameObject:SetActiveEx(true)
            self.TxtScoreAddPercent.text = string.format("+%.0f%%", totalRate / 100)
        end
    end
end

-- v4.2 新增：刷新选中的可选词缀显示
function XUiFubenBossSingleSettlement:_RefreshSelectableFeatures()
    if not self._Control then
        return
    end
    
    local challengeData = self._Control:GetBossSingleChallengeData()
    if not challengeData then
        return
    end
    
    local currentBuffFeatureId = self._Control:GetCurrentFeatureId()
    local selectedFeatureIds = {}
    if currentBuffFeatureId and currentBuffFeatureId > 0 then
        selectedFeatureIds = self._Control:GetSelectedSelectableFeatureIds(currentBuffFeatureId) or {}
    end
    if XTool.IsTableEmpty(selectedFeatureIds) then
        -- 没有选中的可选词缀，隐藏面板
        if self.PanelSelectableFeatures then
            self.PanelSelectableFeatures.gameObject:SetActiveEx(false)
        end
        return
    end
    
    -- 显示面板
    if self.PanelSelectableFeatures then
        self.PanelSelectableFeatures.gameObject:SetActiveEx(true)
    end
    
    if not self.ListSelectableFeatures or not self.GridSelectableFeature then
        return
    end
    
    local count = 0
    
    -- 遍历选中的feature IDs，显示对应的词缀信息
    for _, featureId in ipairs(selectedFeatureIds) do
        -- 直接从配置获取可选feature的信息
        local featureConfig = XMVCA.XFubenBossSingle:GetFeatureConfigById(featureId)
        if featureConfig and featureConfig.Type == 2 then
            count = count + 1
            local grid = self._SelectableFeatureGridList[count]
            
            if not grid then
                local gridObj = XUiHelper.Instantiate(self.GridSelectableFeature, self.ListSelectableFeatures)
                -- 创建一个简单的显示节点（不需要完整的XUiNode，只需要显示文本）
                grid = {
                    GameObject = gridObj.gameObject,
                    Transform = gridObj,
                    TxtName = gridObj:Find("TxtName"):GetComponent("Text"),
                    TxtDesc = gridObj:Find("TxtDesc"):GetComponent("Text"),
                    TxtScoreRate = gridObj:Find("TxtScoreRate"):GetComponent("Text"),
                }
                self._SelectableFeatureGridList[count] = grid
            end
            
            -- 显示词缀信息
            if grid.TxtName then
                grid.TxtName.text = featureConfig.Name or ""
            end
            if grid.TxtDesc then
                grid.TxtDesc.text = featureConfig.Desc or ""
            end
            if grid.TxtScoreRate then
                local scoreRate = featureConfig.ScoreRate or 0
                grid.TxtScoreRate.text = string.format("+%.0f%%", scoreRate / 100)
            end
            
            grid.GameObject:SetActiveEx(true)
        end
    end
    
    -- 隐藏多余的Grid
    for i = count + 1, #self._SelectableFeatureGridList do
        if self._SelectableFeatureGridList[i] then
            self._SelectableFeatureGridList[i].GameObject:SetActiveEx(false)
        end
    end
end

return XUiFubenBossSingleSettlement
