local XSGDroneCooldown = require("XModule/XSkyGardenDroneGame/XCommon/XSGDroneCooldown")
local XUiSkyGardenSGDroneGameTarget = require("XUi/XUiSkyGarden/XDroneGame/Battle/XUiSkyGardenSGDroneGameTarget")
local XUiSkyGardenSGDroneGameScore = require("XUi/XUiSkyGarden/XDroneGame/Battle/XUiSkyGardenSGDroneGameScore")
local XUiSkyGardenSGDroneGameProgressGrid = require(
    "XUi/XUiSkyGarden/XDroneGame/Battle/XUiSkyGardenSGDroneGameProgressGrid")

---@class XUiSkyGardenSGDroneGame : XBigWorldUi
---@field BtnStop XUiComponent.XUiButtonExt
---@field BtnSpeedUp XUiComponent.XUiButtonExt
---@field BtnChange XUiComponent.XUiButtonExt
---@field BtnSpecialLock XUiComponent.XUiButtonExt
---@field BtnSpecialLaunch XUiComponent.XUiButtonExt
---@field BtnSpecialSuper XUiComponent.XUiButtonExt
---@field BtnSpecialJump XUiComponent.XUiButtonExt
---@field TargetScore UnityEngine.UI.Text
---@field PanelExtraTarget UnityEngine.RectTransform
---@field ExtraTarget UnityEngine.RectTransform
---@field RoleHead UnityEngine.UI.RawImage
---@field TxtRoleTips UnityEngine.UI.Text
---@field PanelBtnSpecial UnityEngine.RectTransform
---@field TxtTime UnityEngine.UI.Text
---@field TxtTimeChange UnityEngine.UI.Text
---@field ProgressContent UnityEngine.RectTransform
---@field ImgRewardBar UnityEngine.UI.Image
---@field GridProgress UnityEngine.RectTransform
---@field PanelRole UnityEngine.RectTransform
---@field PanelTop UnityEngine.RectTransform
---@field PanelTime UnityEngine.RectTransform
---@field PanelScore UnityEngine.RectTransform
---@field Mask UnityEngine.RectTransform
---@field TxtTips UnityEngine.UI.Text
---@field ImgLockOnCount UnityEngine.UI.Image
---@field TxtLockOnCount UnityEngine.UI.Text
---@field ImgLaunchCount UnityEngine.UI.Image
---@field TxtLaunchCount UnityEngine.UI.Text
---@field ImgSuperCount UnityEngine.UI.Image
---@field TxtSuperCount UnityEngine.UI.Text
---@field ImgJumpCount UnityEngine.UI.Image
---@field TxtJumpCount UnityEngine.UI.Text
---@field ImgAccelerationCount UnityEngine.UI.Image
---@field TxtAccelerationCount UnityEngine.UI.Text
---@field NoiseEffect UnityEngine.RectTransform
---@field AudioPlayer XAudioObjectPlayer
---@field _Control XSkyGardenDroneGameControl
local XUiSkyGardenSGDroneGame = XMVCA.XBigWorldUI:Register(nil, "UiSkyGardenSGDroneGame")

local XSGDGInstance = CS.XBigWorldGame.XSkyGarden.XDroneGame.XSGDGInstance

local CooldownType = {
    Acceleration = 1,
    Jump = 2,
    Super = 3,
    Launch = 4,
}

local OperatorType = {
    Acceleration = 1,
    Jump = 2,
    Super = 3,
    LockOn = 4,
    Launch = 5,
    UTurn = 6,
}

function XUiSkyGardenSGDroneGame:OnAwake()
    self._StageId = 0
    self._MapId = 0
    self._IsHardMode = false
    self._Timer = false
    self._ScoreChangeTimer = false

    self._TimeDetail = 0
    self._CurrentProgress = 0

    ---@type table<int, XUiSkyGardenSGDroneGameTarget>
    self._TargetGrids = {}
    ---@type XUiSkyGardenSGDroneGameProgressGrid[]
    self._ProgressGrids = {}
    ---@type XUiSkyGardenSGDroneGameScore[]
    self._ScoreCache = {}
    ---@type XUiSkyGardenSGDroneGameScore[]
    self._CurrentScore = {}

    self._CurrentKeyPromptedType = false

    ---@type table<number, XSGDroneCooldown>
    self._Cooldowns = {
        [CooldownType.Acceleration] = XSGDroneCooldown.New(),
        [CooldownType.Jump] = XSGDroneCooldown.New(),
        [CooldownType.Super] = XSGDroneCooldown.New(),
        [CooldownType.Launch] = XSGDroneCooldown.New(),
    }

    self._DialogueTimer = false
    self._IsPlayingDialogue = false

    self._IsGuidePauseGame = false
    self._IsGuideFocusObject = false

    self._IsMaskActive = false

    self._NoiseTimer = false

    self._CacheGuideOperator = false

    ---@type XTableSgDroneGameDialogue[]
    self._DialogueWaitQueue = {}

    self._RandomDialogueCounts = {}

    self._CurrentDialogueAudioKey = ""

    self._HiddenUTurnStages = self._Control:GetHiddenUTurnStages()
    self._TriggeredDialogues = self._Control:GetTriggeredDialogues()
    self._TimerDialogues = self._Control:GetTimerDialogues()
    self._RandomDialogues = self._Control:GetRandomDialogues()

    self:_RegisterButtonClicks()
end

function XUiSkyGardenSGDroneGame:OnStart(stageId, mapId, stageData, isHardMode, easyDroneHp, isEnableAssistance)
    self._StageId = stageId
    self._IsHardMode = isHardMode
    self._MapId = mapId

    self:_InitUi()
    self:_InitGame(stageData.Seed)
    self:_InitMode(isHardMode, easyDroneHp, isEnableAssistance)
    self:_InitTarget()
    self:_InitStage(stageData.SaveData)
    self:_RegisterListeners()
end

function XUiSkyGardenSGDroneGame:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()

    XEventManager.AddEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_SPEED_UP", self.OnSpeedUp, self)
    XEventManager.AddEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_REVERSE", self.OnReverse, self)
    XEventManager.AddEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_LOCK_ON_ATTACK", self.OnLockOnAttack, self)
    XEventManager.AddEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_ATTACK", self.OnAttack, self)
    XEventManager.AddEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_JUMP", self.OnJump, self)
    XEventManager.AddEventListener("EVENT_SKYGARDEN_GUIDE_FOCUS_OBJECT", self.OnFocusObject, self)
    XEventManager.AddEventListener("EVENT_SKYGARDEN_GUIDE_FOLLOW_DRONE", self.OnFollowDrone, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUNCTION_EVENT_COMPLETE, self.OnGuideComplete, self)
end

function XUiSkyGardenSGDroneGame:OnDisable()
    self:_RemoveSchedules()

    XEventManager.RemoveEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_SPEED_UP", self.OnSpeedUp, self)
    XEventManager.RemoveEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_REVERSE", self.OnReverse, self)
    XEventManager.RemoveEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_LOCK_ON_ATTACK", self.OnLockOnAttack, self)
    XEventManager.RemoveEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_ATTACK", self.OnAttack, self)
    XEventManager.RemoveEventListener("EVENT_SKYGARDEN_GUIDE_DRONEGAME_JUMP", self.OnJump, self)
    XEventManager.RemoveEventListener("EVENT_SKYGARDEN_GUIDE_FOCUS_OBJECT", self.OnFocusObject, self)
    XEventManager.RemoveEventListener("EVENT_SKYGARDEN_GUIDE_FOLLOW_DRONE", self.OnFollowDrone, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUNCTION_EVENT_COMPLETE, self.OnGuideComplete, self)
end

function XUiSkyGardenSGDroneGame:OnDestroy()
    self:_RemoveListeners()
    self.AudioPlayer:StopByKeyName("BGM_DroneGame")

    if not string.IsNilOrEmpty(self._CurrentDialogueAudioKey) then
        self.AudioPlayer:StopByKeyName(self._CurrentDialogueAudioKey)
    end

    CS.XAudioManager.ResumeBgmAreaTrigger("SkyGardenDrone")
end

function XUiSkyGardenSGDroneGame:OnBtnSpeedUpClick()
    if self._IsMaskActive then
        return
    end

    if not self._Cooldowns[CooldownType.Acceleration]:IsCoolingdown() then
        self:_RestoreKeyPrompted(self._Control.KeyPromptedType.Accelerate)
        XSGDGInstance.Instance.DroneManager:SpeedUp()
    end
end

function XUiSkyGardenSGDroneGame:OnBtnChangeClick()
    if self._IsMaskActive then
        return
    end

    self:_RestoreKeyPrompted(self._Control.KeyPromptedType.UTurn)
    XSGDGInstance.Instance.DroneManager:Reverse()
end

function XUiSkyGardenSGDroneGame:OnBtnSpecialLockClick()
    if self._IsMaskActive then
        return
    end

    if not self._Cooldowns[CooldownType.Launch]:IsCoolingdown() then
        self:_RestoreKeyPrompted(self._Control.KeyPromptedType.LockOn)
        XSGDGInstance.Instance.DroneManager:LockOnAttack()
    end
end

function XUiSkyGardenSGDroneGame:OnBtnSpecialLaunchClick()
    if self._IsMaskActive then
        return
    end

    if not self._Cooldowns[CooldownType.Launch]:IsCoolingdown() then
        self:_RestoreKeyPrompted(self._Control.KeyPromptedType.Launch)
        XSGDGInstance.Instance.DroneManager:Attack()
    end
end

function XUiSkyGardenSGDroneGame:OnBtnSpecialSuperClick()
    if self._IsMaskActive then
        return
    end

    if not self._Cooldowns[CooldownType.Super]:IsCoolingdown() then
        self:_RestoreKeyPrompted(self._Control.KeyPromptedType.Supercomputing)
        XSGDGInstance.Instance.DroneManager:Supercomputing()
    end
end

function XUiSkyGardenSGDroneGame:OnBtnSpecialJumpClick()
    if self._IsMaskActive then
        return
    end

    if not self._Cooldowns[CooldownType.Jump]:IsCoolingdown() then
        self:_RestoreKeyPrompted(self._Control.KeyPromptedType.Jump)
        XSGDGInstance.Instance.DroneManager:Jump()
    end
end

function XUiSkyGardenSGDroneGame:OnBtnStopClick()
    if self._IsMaskActive then
        return
    end

    if XSGDGInstance.Instance.Engine.CurrentState ~= CS.XBigWorldGame.XSkyGarden.XDroneGame.ESGDGEngineState.Save then
        XSGDGInstance.PauseGame()
    end

    XMVCA.XBigWorldUI:Open("UiSkyGardenSGDronePopupStop", self._StageId, XSGDGInstance.Instance.DroneManager.DroneId)
end

function XUiSkyGardenSGDroneGame:OnSpeedUp()
    if XSGDGInstance.Instance and XSGDGInstance.Instance.DroneManager then
        if self._IsGuidePauseGame then
            self._CacheGuideOperator = OperatorType.Acceleration
        else
            XSGDGInstance.Instance.DroneManager:SpeedUp()
        end
    end
end

function XUiSkyGardenSGDroneGame:OnReverse()
    if XSGDGInstance.Instance and XSGDGInstance.Instance.DroneManager then
        if self._IsGuidePauseGame then
            self._CacheGuideOperator = OperatorType.UTurn
        else
            XSGDGInstance.Instance.DroneManager:Reverse()
        end
    end
end

function XUiSkyGardenSGDroneGame:OnLockOnAttack()
    if XSGDGInstance.Instance and XSGDGInstance.Instance.DroneManager then
        if self._IsGuidePauseGame then
            self._CacheGuideOperator = OperatorType.LockOn
        else
            XSGDGInstance.Instance.DroneManager:LockOnAttack()
        end
    end
end

function XUiSkyGardenSGDroneGame:OnAttack()
    if XSGDGInstance.Instance and XSGDGInstance.Instance.DroneManager then
        if self._IsGuidePauseGame then
            self._CacheGuideOperator = OperatorType.Launch
        else
            XSGDGInstance.Instance.DroneManager:Attack()
        end
    end
end

function XUiSkyGardenSGDroneGame:OnJump()
    if XSGDGInstance.Instance and XSGDGInstance.Instance.DroneManager then
        if self._IsGuidePauseGame then
            self._CacheGuideOperator = OperatorType.Jump
        else
            XSGDGInstance.Instance.DroneManager:Jump()
        end
    end
end

function XUiSkyGardenSGDroneGame:OnFocusObject(paramStr)
    if string.IsNilOrEmpty(paramStr) or not XSGDGInstance.Instance then
        return
    end

    local params = string.Split(paramStr)

    if not XTool.IsTableEmpty(params) then
        local targetId = tonumber(params[1])

        if targetId then
            local time = tonumber(params[2]) or 1

            self._IsGuideFocusObject = true
            XSGDGInstance.Instance:MoveCameraToTarget(targetId, time)
        end
    end
end

function XUiSkyGardenSGDroneGame:OnFollowDrone()
    if not XSGDGInstance.Instance then
        return
    end

    XSGDGInstance.Instance:CameraFollowDrone()
    self._IsGuideFocusObject = false
end

function XUiSkyGardenSGDroneGame:OnGuideComplete()
    if self._IsGuidePauseGame then
        XSGDGInstance.ResumeGame()
        self._IsGuidePauseGame = false

        if self._CacheGuideOperator then
            self:_DoGuideOperator()
        end
        if self._IsGuideFocusObject then
            self:OnFollowDrone()
        end
    end
end

function XUiSkyGardenSGDroneGame:OnLoadComplete()
    self:_RefreshScore()
    self:_RefreshTarget()
    self:_RefreshProgress()
    self:_RefreshOperator(XSGDGInstance.Instance.DroneManager.DroneIntType)
    self.AudioPlayer:PlayByKeyName("BGM_DroneGame")
    XMVCA.XBigWorldUI:Close("UiSkyGardenSGDroneLoading")
end

function XUiSkyGardenSGDroneGame:OnGamePrepareComplete()
    self:_InitProgress()
end

function XUiSkyGardenSGDroneGame:OnGameContinueComplete()
    self:_InitProgress()
    self:_RefreshScore()
    self:_RefreshTarget()
    self:_RefreshProgress()
    self:_PlayNoiseEffect()
end

function XUiSkyGardenSGDroneGame:OnGameRestoreComplete()
    self._CurrentProgress = 0

    self:_RefreshScore()
    self:_RefreshTarget()
    self:_RefreshProgress()
    self:_PlayNoiseEffect()
    self:_SetMaskActive(false)
end

function XUiSkyGardenSGDroneGame:OnGameRestartComplete()
    self._CurrentProgress = 0

    self:_RefreshScore()
    self:_RefreshTarget()
    self:_RefreshProgress()
    self:_PlayNoiseEffect()
    self:_SetMaskActive(false)
end

function XUiSkyGardenSGDroneGame:OnGameRelease()
    self:_RemoveListeners()
    self:_RemoveSchedules()
    XMVCA.XBigWorldUI:SafeClose("UiSkyGardenSGDroneGame")
end

function XUiSkyGardenSGDroneGame:OnBeginSaveGame()
    self:_SetMaskActive(true)
end

function XUiSkyGardenSGDroneGame:OnEndSaveGame()
    self:_SetMaskActive(false)
    self:_RefreshProgressPoint()
end

function XUiSkyGardenSGDroneGame:OnBehaviorTriggered(text, score)
    local scoreGrid = nil

    if XTool.IsTableEmpty(self._ScoreCache) then
        local scoreUi = XUiHelper.Instantiate(self.PanelScore, self.PanelTime)

        scoreGrid = XUiSkyGardenSGDroneGameScore.New(scoreUi, self)
    else
        scoreGrid = table.remove(self._ScoreCache, 1)
    end

    if scoreGrid then
        if #self._CurrentScore >= 1 then
            local currentScore = table.remove(self._CurrentScore, 1)

            if currentScore then
                currentScore:Close()
            end
        end

        scoreGrid:Open()
        scoreGrid:Refresh(text, score)
        table.insert(self._CurrentScore, scoreGrid)
    end
end

function XUiSkyGardenSGDroneGame:OnTargetProgressChanged(targetId, progress, totalProgress, isFinish)
    local targetGrid = self._TargetGrids[targetId]

    if targetGrid then
        if isFinish and not targetGrid:GetIsFinish() then
            self.AudioPlayer:PlayByKeyName("SFX_Achieve")
        end

        targetGrid:SetFinish(isFinish)
        targetGrid:SetProgress(progress, totalProgress)
    end
end

function XUiSkyGardenSGDroneGame:OnScoreChanged(score, changedScore)
    if XTool.IsNumberValid(changedScore) then
        self.TxtTime.text = tostring(score)
        self.TxtTimeChange.gameObject:SetActiveEx(true)
        self.TxtTimeChange.text = string.format("+%d", changedScore)

        self:_RegisterScoreChangeTimer()
    end
end

function XUiSkyGardenSGDroneGame:OnTagTriggered(triggerTag)
    local dialogues = self._TriggeredDialogues[triggerTag]

    if not XTool.IsTableEmpty(dialogues) then
        local playDialogues = {}

        for _, dialogue in pairs(dialogues) do
            table.insert(playDialogues, dialogue)
        end

        self:_PlayDialogues(playDialogues)
    end

    self:_TryTriggerGuide(triggerTag)
end

function XUiSkyGardenSGDroneGame:OnKeyPrompted(key, isActive)
    if key == self._Control.KeyPromptedType.Accelerate then
        self.BtnSpeedUp:ShowTag(isActive)
    elseif key == self._Control.KeyPromptedType.UTurn then
        self.BtnChange:ShowTag(isActive)
    elseif key == self._Control.KeyPromptedType.Jump then
        self.BtnSpecialJump:ShowTag(isActive)
    elseif key == self._Control.KeyPromptedType.Supercomputing then
        self.BtnSpecialSuper:ShowTag(isActive)
    elseif key == self._Control.KeyPromptedType.Launch then
        self.BtnSpecialLaunch:ShowTag(isActive)
    elseif key == self._Control.KeyPromptedType.LockOn then
        self.BtnSpecialLock:ShowTag(isActive)
    end

    if isActive then
        self._CurrentKeyPromptedType = key
    else
        self._CurrentKeyPromptedType = false
    end
end

function XUiSkyGardenSGDroneGame:OnAccelerationCDChanged(count, cd)
    self.TxtAccelerationCount.text = count
    self.ImgAccelerationCount.fillAmount = cd
    self._Cooldowns[CooldownType.Acceleration]:Use(count, cd)
end

function XUiSkyGardenSGDroneGame:OnLaunchCDChanged(count, cd)
    self.TxtLaunchCount.text = count
    self.TxtLockOnCount.text = count
    self.ImgLaunchCount.fillAmount = cd
    self.ImgLockOnCount.fillAmount = cd
    self._Cooldowns[CooldownType.Launch]:Use(count, cd)
end

function XUiSkyGardenSGDroneGame:OnBulletCDChanged(count, cd)
    self.TxtLaunchCount.text = count
    self.TxtLockOnCount.text = count
    self._Cooldowns[CooldownType.Launch].Count = count
end

function XUiSkyGardenSGDroneGame:OnSuperCDChanged(count, cd)
    self.TxtSuperCount.text = count
    self.ImgSuperCount.fillAmount = cd
    self._Cooldowns[CooldownType.Super]:Use(count, cd)
end

function XUiSkyGardenSGDroneGame:OnJumpCDChanged(count, cd)
    self.TxtJumpCount.text = count
    self.ImgJumpCount.fillAmount = cd
    self._Cooldowns[CooldownType.Jump]:Use(count, cd)
end

---@type XUiSkyGardenSGDroneGameScore
function XUiSkyGardenSGDroneGame:RestoreScoreGrid(grid)
    table.insert(self._ScoreCache, grid)

    for i, scoreGrid in pairs(self._CurrentScore) do
        if scoreGrid == grid then
            table.remove(self._CurrentScore, i)
            break
        end
    end
end

function XUiSkyGardenSGDroneGame:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnSpeedUp:AddEventListener(Handler(self, self.OnBtnSpeedUpClick))
    self.BtnChange:AddEventListener(Handler(self, self.OnBtnChangeClick), true, true, 0.1)
    self.BtnStop:AddEventListener(Handler(self, self.OnBtnStopClick))
    self.BtnSpecialLock:AddEventListener(Handler(self, self.OnBtnSpecialLockClick))
    self.BtnSpecialLaunch:AddEventListener(Handler(self, self.OnBtnSpecialLaunchClick))
    self.BtnSpecialSuper:AddEventListener(Handler(self, self.OnBtnSpecialSuperClick))
    self.BtnSpecialJump:AddEventListener(Handler(self, self.OnBtnSpecialJumpClick))
end

function XUiSkyGardenSGDroneGame:_RegisterListeners()
    -- 在此处注册事件监听
    XSGDGInstance.Instance.Bridge.OnGameLoadComplete = Handler(self, self.OnLoadComplete)
    XSGDGInstance.Instance.Bridge.OnGamePrepareComplete = Handler(self, self.OnGamePrepareComplete)
    XSGDGInstance.Instance.Bridge.OnGameContinueComplete = Handler(self, self.OnGameContinueComplete)
    XSGDGInstance.Instance.Bridge.OnGameRestoreComplete = Handler(self, self.OnGameRestoreComplete)
    XSGDGInstance.Instance.Bridge.OnGameRestartComplete = Handler(self, self.OnGameRestartComplete)
    XSGDGInstance.Instance.Bridge.OnGameRelease = Handler(self, self.OnGameRelease)
    XSGDGInstance.Instance.Bridge.OnBeginSaveGame = Handler(self, self.OnBeginSaveGame)
    XSGDGInstance.Instance.Bridge.OnEndSaveGame = Handler(self, self.OnEndSaveGame)

    XSGDGInstance.Instance.Bridge.OnBehaviorTriggered = Handler(self, self.OnBehaviorTriggered)
    XSGDGInstance.Instance.Bridge.OnTargetProgressChanged = Handler(self, self.OnTargetProgressChanged)
    XSGDGInstance.Instance.Bridge.OnScoreChanged = Handler(self, self.OnScoreChanged)
    XSGDGInstance.Instance.Bridge.OnTagTriggered = Handler(self, self.OnTagTriggered)
    XSGDGInstance.Instance.Bridge.OnKeyPrompted = Handler(self, self.OnKeyPrompted)

    XSGDGInstance.Instance.Bridge.OnAccelerationCDChanged = Handler(self, self.OnAccelerationCDChanged)
    XSGDGInstance.Instance.Bridge.OnLaunchCDChanged = Handler(self, self.OnLaunchCDChanged)
    XSGDGInstance.Instance.Bridge.OnBulletCDChanged = Handler(self, self.OnBulletCDChanged)
    XSGDGInstance.Instance.Bridge.OnSupercomputingCDChanged = Handler(self, self.OnSuperCDChanged)
    XSGDGInstance.Instance.Bridge.OnJumpCDChanged = Handler(self, self.OnJumpCDChanged)

    XSGDGInstance.Instance.Bridge.RequestSuspendStage = Handler(self, self.RequestSuspendStage)
    XSGDGInstance.Instance.Bridge.RequestStageSettle = Handler(self, self.RequestStageSettle)
    XSGDGInstance.Instance.Bridge.RequestRestartStage = Handler(self, self.RequestRestartStage)
end

function XUiSkyGardenSGDroneGame:_RemoveListeners()
    if not XSGDGInstance.Instance then
        return
    end

    -- 在此处移除事件监听
    XSGDGInstance.Instance.Bridge.OnGameLoadComplete = nil
    XSGDGInstance.Instance.Bridge.OnGamePrepareComplete = nil
    XSGDGInstance.Instance.Bridge.OnGameRelease = nil
    XSGDGInstance.Instance.Bridge.OnBeginSaveGame = nil
    XSGDGInstance.Instance.Bridge.OnEndSaveGame = nil

    XSGDGInstance.Instance.Bridge.OnBehaviorTriggered = nil
    XSGDGInstance.Instance.Bridge.OnTargetProgressChanged = nil
    XSGDGInstance.Instance.Bridge.OnScoreChanged = nil
    XSGDGInstance.Instance.Bridge.OnTagTriggered = nil
    XSGDGInstance.Instance.Bridge.OnKeyPrompted = nil

    XSGDGInstance.Instance.Bridge.OnAccelerationCDChanged = nil
    XSGDGInstance.Instance.Bridge.OnLaunchCDChanged = nil
    XSGDGInstance.Instance.Bridge.OnBulletCDChanged = nil
    XSGDGInstance.Instance.Bridge.OnSupercomputingCDChanged = nil
    XSGDGInstance.Instance.Bridge.OnJumpCDChanged = nil

    XSGDGInstance.Instance.Bridge.RequestSuspendStage = nil
    XSGDGInstance.Instance.Bridge.RequestStageSettle = nil
    XSGDGInstance.Instance.Bridge.RequestRestartStage = nil
end

function XUiSkyGardenSGDroneGame:_RegisterSchedules()
    -- 在此处注册定时器
    self._Timer = XScheduleManager.ScheduleForeverEx(Handler(self, self._Update), XScheduleManager.SECOND * 0.5)
end

function XUiSkyGardenSGDroneGame:_RemoveSchedules()
    -- 在此处移除定时器
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end

    self:_RemoveScoreChangeTimer()
    self:_RemoveDialogueTimer()
    self:_RemoveNoiseTimer()
end

function XUiSkyGardenSGDroneGame:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

function XUiSkyGardenSGDroneGame:_Update()
    if not XSGDGInstance.Instance then
        return
    end

    self:_RefreshProgress()
    self:_RefreshProgressPoint()

    local playDialogues = {}

    self._TimeDetail = XSGDGInstance.Instance.Engine.RunningTime

    if not XTool.IsTableEmpty(self._TimerDialogues) then
        for _, dialogue in pairs(self._TimerDialogues) do
            if dialogue.Delay <= self._TimeDetail then
                table.insert(playDialogues, dialogue)
            end
        end
    end
    if not XTool.IsTableEmpty(self._RandomDialogues) then
        for _, dialogue in pairs(self._RandomDialogues) do
            local count = self._RandomDialogueCounts[dialogue.Id] or 0
            local delay = dialogue.Delay * (count + 1)

            if self._TimeDetail > 0 and delay < self._TimeDetail then
                table.insert(playDialogues, dialogue)
                self._RandomDialogueCounts[dialogue.Id] = count + 1
            end
        end
    end

    self:_PlayDialogues(playDialogues)
end

function XUiSkyGardenSGDroneGame:_InitUi()
    self.Mask.gameObject:SetActiveEx(false)
    self.PanelRole.gameObject:SetActiveEx(false)
    self.ExtraTarget.gameObject:SetActiveEx(false)
    self.TxtTimeChange.gameObject:SetActiveEx(false)
    self.GridProgress.gameObject:SetActiveEx(false)
    self.PanelScore.gameObject:SetActiveEx(false)
    self.ImgAccelerationCount.gameObject:SetActiveEx(true)
    self.ImgJumpCount.gameObject:SetActiveEx(true)
    self.ImgSuperCount.gameObject:SetActiveEx(true)
    self.ImgLaunchCount.gameObject:SetActiveEx(true)
    self.ImgLockOnCount.gameObject:SetActiveEx(true)

    self.BtnChange.gameObject:SetActiveEx(not (self._HiddenUTurnStages[self._StageId] or false))
end

function XUiSkyGardenSGDroneGame:_InitGame(seed)
    local stageObject = self.UiModelGo.transform:FindTransform("StageRoot")
    local camera = self.UiModelGo.transform:FindTransform("Camera")
    local stageObjectUrl = self._Control:GetStageObjectUrl()
    local cameraFollowConfig = self._Control:GetCameraFollowConfig()

    XSGDGInstance.InitGame(stageObject.gameObject, camera, seed or 0)
    XSGDGInstance.InitStageObjectUrl(stageObjectUrl)
    XSGDGInstance.InitCameraFollow(cameraFollowConfig.Width, cameraFollowConfig.Height, cameraFollowConfig.OffsetX,
        cameraFollowConfig.OffsetY, cameraFollowConfig.IsUseSmoothFollow, cameraFollowConfig.SmoothFollowSpeed)
    XSGDGInstance.StartGame(self._MapId)
end

function XUiSkyGardenSGDroneGame:_InitMode(isHardMode, easyDroneHp, isEnableAssistance)
    XSGDGInstance.InitMode(isHardMode, easyDroneHp, isEnableAssistance)
end

function XUiSkyGardenSGDroneGame:_InitStage(stageData)
    if stageData then
        local storageStageData = XSGDGInstance.CreateStorageStageData()

        if not XTool.IsTableEmpty(stageData.StageObjectDataDict) then
            for objectId, objectData in pairs(stageData.StageObjectDataDict) do
                storageStageData:AddObjectData(objectId, objectData.Durability, objectData.ActivateTime,
                    objectData.IsTriggered, objectData.GenerateExecutionsCount)
            end
        end
        if not XTool.IsTableEmpty(stageData.CollectStageObjects) then
            for _, objectId in pairs(stageData.CollectStageObjects) do
                storageStageData:AddCollectObject(objectId)
            end
        end
        if not XTool.IsTableEmpty(stageData.TriggeredBehaviorIds) then
            for _, behaviorId in pairs(stageData.TriggeredBehaviorIds) do
                storageStageData:AddTriggeredBehavior(behaviorId)
            end
        end
        if not XTool.IsTableEmpty(stageData.TargetProgress) then
            for targetId, progress in pairs(stageData.TargetProgress) do
                storageStageData:RestoreTargetProgress(targetId, progress)
            end
        end

        storageStageData.RelayObjectId = stageData.RelayObjectId
        storageStageData.RunningTime = stageData.RunningTime
        storageStageData.Score = stageData.Score

        XSGDGInstance.Instance:SetStorageStageData(storageStageData)
    end
end

function XUiSkyGardenSGDroneGame:_InitTarget()
    local targetIds = self._Control:GetStageTargetIds(self._StageId)

    if not XTool.IsTableEmpty(targetIds) then
        for i, targetId in pairs(targetIds) do
            local targetType = self._Control:GetTargetType(targetId)
            local targetParams = self._Control:GetTargetParams(targetId)
            local targetDesc = self._Control:GetTargetProgressDescription(targetId)

            if i == 1 then
                self.TargetScore.text = targetDesc
            else
                local grid = XUiHelper.Instantiate(self.ExtraTarget, self.PanelExtraTarget)
                ---@type XUiSkyGardenSGDroneGameTarget
                local gridUi = XUiSkyGardenSGDroneGameTarget.New(grid, self)

                gridUi:Open()
                gridUi:SetText(targetDesc)
                self._TargetGrids[targetId] = gridUi
            end

            XSGDGInstance.Instance.BehaviorManager:AddTarget(targetId, targetType, targetParams)
        end
    end
end

function XUiSkyGardenSGDroneGame:_InitProgress()
    local count = XSGDGInstance.Instance.Engine.RelayPointCount + 1
    local currentIndex = XSGDGInstance.Instance.Engine.CurrentRelayPointIndex + 1
    local flexibleWidths = XSGDGInstance.Instance.Engine.RelayPointFlexibleWidths

    for i = 1, count do
        local grid = XUiHelper.Instantiate(self.GridProgress, self.ProgressContent)
        ---@type XUiSkyGardenSGDroneGameProgressGrid
        local gridUi = XUiSkyGardenSGDroneGameProgressGrid.New(grid, self, i == count)
        local flexibleWidth = 0

        if i <= flexibleWidths.Length then
            flexibleWidth = flexibleWidths[i - 1]
        end

        gridUi:Open()
        gridUi:Refresh(i <= currentIndex, i == currentIndex, flexibleWidth)
        self._ProgressGrids[i] = gridUi
    end
end

function XUiSkyGardenSGDroneGame:_RestoreKeyPrompted(keyPromptType)
    if not self._CurrentKeyPromptedType then
        return
    end

    local isSuccess = self._CurrentKeyPromptedType == keyPromptType

    XSGDGInstance.Instance.Engine:UnKeyPrompt()
    XSGDGInstance.Instance.DroneManager:KeyPrompt(isSuccess)

    if self._CurrentKeyPromptedType == self._Control.KeyPromptedType.Accelerate then
        self.BtnSpeedUp:ShowTag(false)
    elseif self._CurrentKeyPromptedType == self._Control.KeyPromptedType.UTurn then
        self.BtnChange:ShowTag(false)
    elseif self._CurrentKeyPromptedType == self._Control.KeyPromptedType.Jump then
        self.BtnSpecialJump:ShowTag(false)
    elseif self._CurrentKeyPromptedType == self._Control.KeyPromptedType.Supercomputing then
        self.BtnSpecialSuper:ShowTag(false)
    elseif self._CurrentKeyPromptedType == self._Control.KeyPromptedType.Launch then
        self.BtnSpecialLaunch:ShowTag(false)
    elseif self._CurrentKeyPromptedType == self._Control.KeyPromptedType.LockOn then
        self.BtnSpecialLock:ShowTag(false)
    end

    self._CurrentKeyPromptedType = false
end

function XUiSkyGardenSGDroneGame:_RefreshOperator(droneType)
    self.PanelBtnSpecial.gameObject:SetActiveEx(droneType ~= self._Control.DroneType.Normal)
    self.BtnSpecialLock.gameObject:SetActiveEx(droneType == self._Control.DroneType.LaunchDrone)
    self.BtnSpecialLaunch.gameObject:SetActiveEx(false)
    self.BtnSpecialSuper.gameObject:SetActiveEx(droneType == self._Control.DroneType.Supercomputing)
    self.BtnSpecialJump.gameObject:SetActiveEx(droneType == self._Control.DroneType.Magnetic)
end

function XUiSkyGardenSGDroneGame:_RefreshTarget()
    if not XTool.IsTableEmpty(self._TargetGrids) then
        for targetId, gridUi in pairs(self._TargetGrids) do
            local progress = XSGDGInstance.Instance.BehaviorManager:GetTargetProgressByTargetId(targetId)
            local totalProgress = XSGDGInstance.Instance.BehaviorManager:GetTargetThresholdByTargetId(targetId)
            local isFinish = XSGDGInstance.Instance.BehaviorManager:CheckTargetProgress(targetId)

            gridUi:SetFinish(isFinish)
            gridUi:SetProgress(progress, totalProgress)
        end
    end
end

function XUiSkyGardenSGDroneGame:_RefreshScore()
    self.TxtTime.text = XSGDGInstance.Instance.Engine.Score
end

function XUiSkyGardenSGDroneGame:_RefreshProgress()
    self._CurrentProgress = math.max(self._CurrentProgress, XSGDGInstance.Instance.Engine.Progress)
    self.ImgRewardBar.fillAmount = self._CurrentProgress
end

function XUiSkyGardenSGDroneGame:_RefreshProgressPoint()
    local count = XSGDGInstance.Instance.Engine.RelayPointCount + 1
    local currentIndex = XSGDGInstance.Instance.Engine.CurrentRelayPointIndex + 1
    local flexibleWidths = XSGDGInstance.Instance.Engine.RelayPointFlexibleWidths

    for i = 1, count do
        local gridUi = self._ProgressGrids[i]
        local flexibleWidth = 0

        if i <= flexibleWidths.Length then
            flexibleWidth = flexibleWidths[i - 1]
        end

        if gridUi then
            gridUi:Refresh(i <= currentIndex, i == currentIndex, flexibleWidth)
        end
    end
end

---@param dialogue XTableSgDroneGameDialogue
function XUiSkyGardenSGDroneGame:_RefreshDialogue(dialogue)
    local dialogues = dialogue.Dialogue
    local dialogueText = ""

    if not XTool.IsTableEmpty(dialogues) then
        local index = math.random(1, #dialogues)

        dialogueText = dialogues[index]
    end

    self.RoleHead:SetImage(dialogue.HeadIcon)
    self.TxtRoleTips.text = dialogueText
end

function XUiSkyGardenSGDroneGame:_RegisterScoreChangeTimer()
    self:_RemoveScoreChangeTimer()
    self._ScoreChangeTimer = XScheduleManager.ScheduleOnce(function()
        self.TxtTimeChange.gameObject:SetActiveEx(false)
    end, XScheduleManager.SECOND * 2)
end

function XUiSkyGardenSGDroneGame:_RemoveScoreChangeTimer()
    if self._ScoreChangeTimer then
        XScheduleManager.UnSchedule(self._ScoreChangeTimer)
        self._ScoreChangeTimer = false
    end
end

function XUiSkyGardenSGDroneGame:_RemoveDialogueTimer()
    if self._DialogueTimer then
        XScheduleManager.UnSchedule(self._DialogueTimer)
        self._DialogueTimer = false
    end
end

function XUiSkyGardenSGDroneGame:_RemoveNoiseTimer()
    if self._NoiseTimer then
        XScheduleManager.UnSchedule(self._NoiseTimer)
        if XMVCA.XBigWorldUI:IsMaskShow(self.Name) then
            XMVCA.XBigWorldUI:SetMaskActive(false, self.Name)
        end
        self._NoiseTimer = false
    end
end

function XUiSkyGardenSGDroneGame:_TryTriggerGuide(tag)
    if string.IsNilOrEmpty(tag) then
        return
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    if string.find(tag, "EVENT_TRIGGER_GUIDE") then
        local values = string.Split(tag)

        if not XTool.IsTableEmpty(values) and #values >= 2 then
            local guideId = tonumber(values[2])

            if guideId and not XDataCenter.GuideManager.CheckIsGuide(guideId) then
                local template = XDataCenter.GuideManager.GetGuideGroupTemplatesById(guideId)

                if XDataCenter.GuideManager.TryActiveGuide(template) then
                    self._IsGuidePauseGame = true
                    XSGDGInstance.PauseGame()
                end
            end
        end
    end
end

function XUiSkyGardenSGDroneGame:_DoGuideOperator()
    local operatorType = self._CacheGuideOperator

    if operatorType == OperatorType.LockOn then
        self:OnLockOnAttack()
    elseif operatorType == OperatorType.Launch then
        self:OnAttack()
    elseif operatorType == OperatorType.Jump then
        self:OnJump()
    elseif operatorType == OperatorType.Acceleration then
        self:OnSpeedUp()
    elseif operatorType == OperatorType.UTurn then
        self:OnReverse()
    end

    self._CacheGuideOperator = false
end

function XUiSkyGardenSGDroneGame:_SetMaskActive(isActive)
    if self._IsMaskActive ~= isActive then
        self._IsMaskActive = isActive
        self.Mask.gameObject:SetActiveEx(isActive)
        XMVCA.XBigWorldUI:SetMaskActive(isActive, self.Name)

        if isActive then
            self.AudioPlayer:PlayByKeyName("SFX_Save")
        end
    end
end

function XUiSkyGardenSGDroneGame:_PlayNoiseEffect()
    if not self.NoiseEffect then
        return
    end

    self:_RemoveNoiseTimer()

    self.AudioPlayer:PlayByKeyName("SFX_Load")
    self.NoiseEffect.gameObject:SetActiveEx(false)
    self.NoiseEffect.gameObject:SetActiveEx(true)
    XMVCA.XBigWorldUI:SetMaskActive(true, self.Name)
    self._NoiseTimer = XScheduleManager.ScheduleOnce(function()
        XMVCA.XBigWorldUI:SetMaskActive(false, self.Name)
        self.AudioPlayer:StopByKeyName("SFX_Load")
        self._NoiseTimer = false
    end, XScheduleManager.SECOND * 1)
end

function XUiSkyGardenSGDroneGame:_PlayDialogues(dialogues)
    if not XTool.IsTableEmpty(dialogues) then
        for _, dialogue in pairs(dialogues) do
            self:_PlayDialogue(dialogue)
        end
        for _, dialogue in pairs(dialogues) do
            self:_RemoveDialogue(dialogue)
        end
    end
end

---@param dialogue XTableSgDroneGameDialogue
function XUiSkyGardenSGDroneGame:_PlayDialogue(dialogue)
    if self._IsPlayingDialogue then
        for index, waitingDialogue in pairs(self._DialogueWaitQueue) do
            if waitingDialogue.Priority < dialogue.Priority then
                table.insert(self._DialogueWaitQueue, index, dialogue)
                return
            end
        end

        table.insert(self._DialogueWaitQueue, dialogue)
        return
    end

    self.PanelRole.gameObject:SetActiveEx(true)
    self.AudioPlayer:PlayByKeyName("SFX_Message")
    self._IsPlayingDialogue = true

    self:_RefreshDialogue(dialogue)
    self:_RemoveDialogueTimer()
    self._DialogueTimer = XScheduleManager.ScheduleOnce(function()
        self._IsPlayingDialogue = false
        self._DialogueTimer = false

        if not XTool.IsTableEmpty(self._DialogueWaitQueue) then
            local nextDialogue = table.remove(self._DialogueWaitQueue, 1)

            self:_PlayDialogue(nextDialogue)
        else
            self.PanelRole.gameObject:SetActiveEx(false)

            if not string.IsNilOrEmpty(self._CurrentDialogueAudioKey) then
                self.AudioPlayer:StopByKeyName(self._CurrentDialogueAudioKey)
                self.AudioPlayer:PlayByKeyName("BGM_DroneGame")
                self._CurrentDialogueAudioKey = ""
            end
        end
    end, XScheduleManager.SECOND * dialogue.Duration)

    if not string.IsNilOrEmpty(dialogue.AudioKey) then
        self._CurrentDialogueAudioKey = dialogue.AudioKey

        if not string.IsNilOrEmpty(self._CurrentDialogueAudioKey) then
            self.AudioPlayer:StopByKeyName(self._CurrentDialogueAudioKey)
        else
            self.AudioPlayer:StopByKeyName("BGM_DroneGame")
        end

        self.AudioPlayer:PlayByKeyName(dialogue.AudioKey)
    else
        if not string.IsNilOrEmpty(self._CurrentDialogueAudioKey) then
            self.AudioPlayer:StopByKeyName(self._CurrentDialogueAudioKey)
            self.AudioPlayer:PlayByKeyName("BGM_DroneGame")
            self._CurrentDialogueAudioKey = ""
        end
    end
end

---@param dialogue XTableSgDroneGameDialogue
function XUiSkyGardenSGDroneGame:_RemoveDialogue(dialogue)
    if dialogue then
        if dialogue.Type == XMVCA.XSkyGardenDroneGame.DialogueType.Trigger then
            if not XTool.IsTableEmpty(self._TriggeredDialogues) then
                for _, triggerDialogues in pairs(self._TriggeredDialogues) do
                    if not XTool.IsTableEmpty(triggerDialogues) then
                        for i, triggerDialogue in pairs(triggerDialogues) do
                            if triggerDialogue.Id == dialogue.Id then
                                table.remove(triggerDialogues, i)
                                break
                            end
                        end
                    end
                end
            end
        elseif dialogue.Type == XMVCA.XSkyGardenDroneGame.DialogueType.Timer then
            if not XTool.IsTableEmpty(self._TimerDialogues) then
                for i, timerDialogue in pairs(self._TimerDialogues) do
                    if timerDialogue.Id == dialogue.Id then
                        table.remove(self._TimerDialogues, i)
                        break
                    end
                end
            end
        end
    end
end

function XUiSkyGardenSGDroneGame:RequestSuspendStage(stageData)
    self._Control:RequestStageSuspend(self._StageId, stageData)
end

function XUiSkyGardenSGDroneGame:RequestStageSettle(isWin, stageData)
    local settleData = {
        StageId = self._StageId,
        DroneId = XSGDGInstance.Instance.DroneManager.DroneId,
        IsWin = isWin,
        RelayPointCount = XSGDGInstance.Instance.Engine.RelayPointCount + 1,
        CurrentRelayPointIndex = XSGDGInstance.Instance.Engine.CurrentRelayPointIndex + 1,
        Score = XSGDGInstance.Instance.Engine.Score,
        HasArchive = XSGDGInstance.Instance.Engine.HasArchive,
        TargetMap = {},
        AchieveTargetMap = self._Control:GetAchieveTargetMap(self._StageId),
    }

    local targetIds = self._Control:GetStageTargetIds(self._StageId)
    local settleType = isWin and self._Control.SettleType.Win or self._Control.SettleType.Lose
    local collectCount = stageData.CollectCount
    local recordData = XSGDGInstance.Instance.Engine.RecordData

    if not XTool.IsTableEmpty(targetIds) then
        for i, targetId in pairs(targetIds) do
            settleData.TargetMap[targetId] = XSGDGInstance.Instance.BehaviorManager:CheckTargetProgress(targetId)
        end
    end

    self._Control:RecordStage(self._StageId, recordData, collectCount, settleType)

    if isWin then
        self._Control:RequestStageSettle(self._StageId, stageData, function()
            XMVCA.XBigWorldUI:Open("UiSkyGardenSGDronePopupSettlement", settleData)
        end)
    else
        XMVCA.XBigWorldUI:Open("UiSkyGardenSGDronePopupSettlement", settleData)
    end
end

function XUiSkyGardenSGDroneGame:RequestGiveUpStage()
    self._Control:RequestStageGiveUp()
end

function XUiSkyGardenSGDroneGame:RequestRestartStage()
    if not XTool.IsNumberValid(self._StageId) then
        return
    end

    self._Control:RequestStageGiveUp(function()
        self._Control:RequestStageStart(self._StageId, self._IsHardMode, function()
            XSGDGInstance.Instance:Restart()
        end)
    end)
end

return XUiSkyGardenSGDroneGame
