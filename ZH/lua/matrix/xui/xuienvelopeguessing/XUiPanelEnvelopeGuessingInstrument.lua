local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

local XUiPanelEnvelopeGuessingInstrument =
    XClass(XUiNode, "XUiPanelEnvelopeGuessingInstrument")

function XUiPanelEnvelopeGuessingInstrument:OnStart(
    instrumentConf,
    clickInstrumentMusicianChoosePanel,
    threeDInstrument,
    threeDNearCamera,
    uiName,
    loadCharacterAnimationController)

    self._LoadCharacterAnimationController = loadCharacterAnimationController
    threeDInstrument.gameObject:SetActiveEx(true)
    XTool.InitUiObjectByInstance(threeDInstrument, self)

    self._NearCamera = threeDNearCamera
    self._InstrumentConf = instrumentConf
    self._Unlocked = false

    function self.BtnMusician.CallBack()
        if not self._Unlocked then
            XUiManager.TipMsg(CS.XTextManager.GetText(
                "EnvelopeGuessingChoosePanelLocked",
                self._InstrumentConf.OpenTarget))
            return
        end

        clickInstrumentMusicianChoosePanel(
            instrumentConf,
            self.ChoosePanel)
    end

    self._ModelInst = XUiPanelRoleModel.New(self.InstrumentModel, uiName, nil, true, false)
    self._ModelChar = XUiPanelRoleModel.New(self.CharacterModel, uiName, nil, true, false)
    self._ParentUiName = uiName
end

XUiPanelEnvelopeGuessingInstrument.RefreshType = {
    Normal = 0,     -- 默认
    Enter = 1,      -- 进入时
    Exit = 2        -- 退出时
}

function XUiPanelEnvelopeGuessingInstrument:Refresh(refreshType)
    --self:_UpdatePosition()

    local playerCharacterId = self._Control:GetInstrumentBinding(
        self._InstrumentConf.Id)

    local modelInstId
    local instrumentPos
    if playerCharacterId then
        modelInstId = self._InstrumentConf.ModelPlayingId
        instrumentPos = self.InstrumentPos2
    else
        modelInstId = self._InstrumentConf.ModelId
        instrumentPos = self.InstrumentPos1
    end

    -- 递增刷新序号，供延迟回调判断自身是否已被更晚的刷新覆盖
    self._RefreshSeq = (self._RefreshSeq or 0) + 1
    local refreshSeq = self._RefreshSeq

    local function applyInstModel()
        if self.CurrentInstModel ~= modelInstId then
            self._ModelInst:UpdateRoleModel(modelInstId, nil, self._ParentUiName, function(roleModel)
                roleModel.transform.localPosition = instrumentPos.localPosition
                roleModel.transform.localRotation = instrumentPos.localRotation
                roleModel.transform.localScale = instrumentPos.localScale
            end)
            self.CurrentInstModel = modelInstId
        end
    end

    -- Exit 时若有小人正在演奏，需等其停止演奏动画（03）播完再切换乐器模型；
    -- 其余情况（Enter/Normal 等）立即切换
    local waitStopAnimBeforeSwitch = refreshType == self.RefreshType.Exit
        and not playerCharacterId
        and self._LoadedCharModel
        and self._PrevCharAnimationPrefix

    if not waitStopAnimBeforeSwitch then
        applyInstModel()
    end

    self.ImgAdd.gameObject:SetActiveEx(not playerCharacterId)
    self.BtnMusician:SetRawImageVisible(XTool.IsNumberValid(playerCharacterId))

    local bgmTrackTargetValue = 0
    if playerCharacterId then
        bgmTrackTargetValue = 1
    end

    local bgmTrackFadeDuration = 0.0
    if refreshType == self.RefreshType.Enter or refreshType == self.RefreshType.Exit then
        bgmTrackFadeDuration = CS.XGame.ClientConfig:GetInt(
            "EnvelopeGuessingEnvelopeBGMFadeDuration") / 1000.0
    end

    CS.XAudioManager.ChangeMusicSourceAisac(
        self._InstrumentConf.BGMTrackControlName,
        bgmTrackTargetValue,
        bgmTrackFadeDuration,
        XTool.Nop)

    if playerCharacterId then
        self._SomeCharacterIsPlaying = true
        self._ModelChar:ShowRoleModel()

        local charConf = self._Control:GetCharacterConfig(playerCharacterId)
        local charModelId = charConf.ModelId

        self._ModelChar:UpdateRoleModel(
            charModelId,
            nil,
            self._ParentUiName,
            function(model)
                self._LoadedCharModel = model
                local ctrl = self._LoadCharacterAnimationController(charConf.IsFemale)
                model:GetComponent(typeof(CS.UnityEngine.Animator)).runtimeAnimatorController = ctrl

                local charAnima = self._InstrumentConf.CharacterAnimationId
                self._PrevCharAnimationPrefix = charAnima

                if refreshType == self.RefreshType.Enter then
                    charAnima = charAnima .. "01"
                else
                    charAnima = charAnima .. "02"
                end

                self._ModelChar:PlayAnima(charAnima, true)
            end,
            false)
    else
        self._SomeCharacterIsPlaying = false

        if waitStopAnimBeforeSwitch then
            local function cb()
                -- 若已被更晚的刷新覆盖，则不再执行本次的收尾逻辑
                if self._RefreshSeq ~= refreshSeq then
                    return
                end
                -- 停止演奏动画播完后，再切换乐器模型
                applyInstModel()

                if not self._SomeCharacterIsPlaying then
                    self._ModelChar:HideRoleModel()
                end
            end

            self._ModelChar:PlayAnima(self._PrevCharAnimationPrefix .. "03", true, cb, cb)

            self._PrevCharAnimationPrefix = nil
            self._LoadedCharModel = nil
        else
            self._ModelChar:HideRoleModel()
        end
    end
end

function XUiPanelEnvelopeGuessingInstrument:_UpdatePosition()
    CS.UnityEngine.Canvas.ForceUpdateCanvases()

    XUiHelper.SetUiObjectPositionTo3D(
        self._UiCamera,
        self.Transform,
        self._NearCamera,
        self.ButtonPosition)
end

function XUiPanelEnvelopeGuessingInstrument:SetUnlockState(
    prevOpenedCharacters, currentOpenedCharacters)

    prevOpenedCharacters = prevOpenedCharacters or currentOpenedCharacters
    local prevUnlocked = prevOpenedCharacters >= self._InstrumentConf.OpenTarget
    self._Unlocked = currentOpenedCharacters >= self._InstrumentConf.OpenTarget

    if self._Unlocked then
        if prevUnlocked then
            -- todo: 这里插入解锁动画
            self:_SetAsLocked(currentOpenedCharacters)
            self:_SetAsUnlocked()
        else
            self:_SetAsUnlocked()
        end
    else
        self:_SetAsLocked(currentOpenedCharacters)
    end
end

function XUiPanelEnvelopeGuessingInstrument:_SetAsLocked(curOpenedChars)
    self.BtnMusician:SetButtonState(CS.UiButtonState.Disable)
    self.BtnMusician:SetNameByGroup(0,
        curOpenedChars .. "/" .. self._InstrumentConf.OpenTarget)

    self.PanelUnlock.gameObject:SetActiveEx(false)
end

function XUiPanelEnvelopeGuessingInstrument:_SetAsUnlocked()
    self.BtnMusician:SetButtonState(CS.UiButtonState.Normal)
    self.PanelUnlock.gameObject:SetActiveEx(true)
end

return XUiPanelEnvelopeGuessingInstrument
