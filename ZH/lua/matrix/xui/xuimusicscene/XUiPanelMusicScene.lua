---@class XUiPanelMusicScene 音乐场景
local XUiPanelMusicScene = XClass(nil, "XUiPanelMusicScene")

local Mode = XEnumConst.MusicScene.Mode
local PlayLogic = XEnumConst.MusicScene.PlayLogic
local NextMode = {
    [Mode.Music] = Mode.Normal,
    [Mode.Normal] = Mode.Music,
}
local KuroroEffectMode = {
    Normal = 1,
    ToNormal = 2,
    Music = 3,
    ToMusic = 4,
}

function XUiPanelMusicScene:Ctor(root)
    self._ModelHandler = {
        [Mode.Normal] = handler(self, self.PlayNormalStatus),
        [Mode.Music] = handler(self, self.PlayMusicStatus),
    }
    self._LogicHandler = {
        [PlayLogic.Simple] = handler(self, self.PlayMusicSimpleLogic),
        [PlayLogic.Full] = handler(self, self.PlayMusicFullLogic),
    }
    self._KuroroEffectHandler = {
        [Mode.Normal] = {
            [true] = handler(self, self.ShowKuroroToNormalEffect),
            [false] = handler(self, self.ShowKuroroNormalEffect)
        },
        [Mode.Music] = {
            [true] = handler(self, self.ShowKuroroToMusicEffect),
            [false] = handler(self, self.ShowKuroroMusicEffect)
        },
    }

    self._TrackKey = CS.XAudioManager.GetAudioClientConfig("MusicTrack_Volume_2")
    self._NormalTargetValue = XMVCA.XMusicScene:GetIntClientConfigValue("AisacTargetValue", Mode.Normal)
    self._MusicTargetValue = XMVCA.XMusicScene:GetIntClientConfigValue("AisacTargetValue", Mode.Music)
    self._CurveTime = XMVCA.XMusicScene:GetIntClientConfigValue("MusicCurveTime")
    self._Cd = XMVCA.XMusicScene:GetIntClientConfigValue("KuroroClickCd")
    ---@type XLuaUi
    self._Root = root

    XEventManager.AddEventListener(XEventId.EVENT_MUSIC_PLAYER_CHANGE, self.OnMusicPlayerChange, self)
    XEventManager.AddEventListener(XEventId.EVENT_MUSIC_SCENE_SETTING_CHANGE, self.OnSettingChange, self)
end

function XUiPanelMusicScene:OnDestroy()
    self:Stop()
    self:ClearKuroroEffectTimer()
    XEventManager.RemoveEventListener(XEventId.EVENT_MUSIC_PLAYER_CHANGE, self.OnMusicPlayerChange, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_MUSIC_SCENE_SETTING_CHANGE, self.OnSettingChange, self)
end

function XUiPanelMusicScene:Play(sceneId, sceneTran)
    if not XMVCA.XMusicScene:IsMusicScene(sceneId) then
        self:Stop()
        return
    end

    if sceneId == self._SceneId and self._IsPlaying then
        return
    end

    local bgmCO = XMVCA.XMusicPlayer:GetCurCommonBgnCO()
    self._IsPlaying = true
    self._Cfg = XMVCA.XMusicScene:GetMusicSceneConfig(sceneId)
    self._PlayMode = XMVCA.XMusicScene:GetCurPlayMode(sceneId)
    self._ExclusiveCueId = XMVCA.XMusicScene:GetSpecialCueId(sceneId)
    self._CurCueId = bgmCO and bgmCO.CueId or nil
    self._SceneId = sceneId
    self._SceneTran = sceneTran
    self._StateNameMap = {
        [Mode.Normal] = {
            [true] = self._Cfg.ToNormalAnim,
            [false] = self._Cfg.NormalAnim
        },
        [Mode.Music] = {
            [true] = self._Cfg.ToMusicAnim,
            [false] = self._Cfg.MusicAnim
        },
    }

    self._SceneUiObj = {}
    XUiHelper.InitUiClass(self._SceneUiObj, sceneTran)
    ---@type UnityEngine.Animator
    self._InputAnim = self._SceneUiObj.InputAnim

    self:LoadClickPrefab()
    self:PlayExclusiveMusic()
    self:ApplyModel()
    self:PlayKuroroAnimation(false)
end

---恢复播放
function XUiPanelMusicScene:Resume()
    if not self._IsPlaying and self._SceneId and self._SceneTran then
        self:Play(self._SceneId, self._SceneTran)
    end
end

function XUiPanelMusicScene:PlayExclusiveMusic()
    if not self._PlayExclusiveMusic or not XTool.IsNumberValid(self._Cfg.LoopCueId) then
        return
    end
    XMVCA.XMusicPlayer:StopCommonSystemBgmAndRecord() --返回其他界面自动恢复播放
    XMVCA.XMusicPlayer:SetLock(true)
    XLuaAudioManager.PlayMusicInOut2(self._Cfg.LoopCueId, -1, -1, -1, -1, 1, 1)
end

function XUiPanelMusicScene:Stop()
    self:DestroyClickPrefab()
    self._SceneUiObj = nil
    self._IsPlaying = false
    self._SceneId = nil
    XMVCA.XMusicPlayer:SetLock(false)
end

---禁止通过库洛洛切换状态
function XUiPanelMusicScene:SetForbidSwitch()
    self._ForbidSwitch = true
    self:DestroyClickPrefab()
end

---处于音乐状态时强制播放完整版，不改变玩家当前选择的常规/音乐状态
function XUiPanelMusicScene:SetForceFullMusic()
    self._ForceFullMusic = true
    self:DontSaveData()
    if self._IsPlaying then
        self:ApplyModel()
    end
end

---屏蔽cd机，单曲循环播放指定的音乐
function XUiPanelMusicScene:SetPlayExclusiveMusic()
    self._PlayExclusiveMusic = true
end

---设置数据不需要保存
function XUiPanelMusicScene:DontSaveData()
    self._DontSaveData = true
end

function XUiPanelMusicScene:LoadClickPrefab()
    if self._ForbidSwitch or string.IsNilOrEmpty(self._Cfg.ClickPrefab) then
        self:DestroyClickPrefab()
        return
    end
    local panelMusicScene = self._Root.PanelMusicScene
    if not panelMusicScene then
        XLog.Error("【音乐场景】加载预制体失败：请先在界面添加预制体挂载的节点")
        return
    end
    self._ClickPrefab = self._Cfg.ClickPrefab
    self._ClickGo = panelMusicScene:LoadPrefabEx(self._ClickPrefab)
    self._ClickUiObj = {}
    XUiHelper.InitUiClass(self._ClickUiObj, self._ClickGo)
    self:InitSwitchBtn()
    self:InitCanvas()
    self:SetClickEffectVisible(true)
end

function XUiPanelMusicScene:DestroyClickPrefab()
    if self._ClickGo then
        CS.UnityEngine.GameObject.Destroy(self._ClickGo)
        self._ClickGo = nil
    end
    if not string.IsNilOrEmpty(self._ClickPrefab) and self._Root and self._Root.PanelMusicScene then
        self._Root.PanelMusicScene:UnloadPrefabEx(self._ClickPrefab)
        self._ClickPrefab = nil
    end
    self:RemovePosTimer()
    self:SetClickEffectVisible(false)
end

---注册切换状态事件
function XUiPanelMusicScene:InitSwitchBtn()
    self:RemovePosTimer()
    if not self._ClickUiObj.BtnClick then
        return
    end
    self._ClickUiObj.BtnClick:AddEventListener(handler(self, self.SwitchMusicMode))
    self:StartPosTimer()
end

function XUiPanelMusicScene:InitCanvas()
    if not self._ClickUiObj.Canvas then
        return
    end
    self._ClickUiObj.Canvas.overrideSorting = false
end

---每秒更新按钮位置
function XUiPanelMusicScene:StartPosTimer()
    self._PosTimerId = XScheduleManager.ScheduleForever(function()
        if not self:IsClickPrefabExist() then
            self:RemovePosTimer()
            return
        end
        local localPos = XUiHelper.ObjPosToUguiPos(self._Root.Transform, self._InputAnim.transform.position, self._Root.UiModel.UiFarCamera)
        self._ClickUiObj.BtnClick.transform:SetLocalPosition(localPos.x, localPos.y, 0)
    end, 1000, 0)
end

function XUiPanelMusicScene:RemovePosTimer()
    if self._PosTimerId then
        XScheduleManager.UnSchedule(self._PosTimerId)
        self._PosTimerId = nil
    end
end

function XUiPanelMusicScene:IsClickPrefabExist()
    if XTool.UObjIsNil(self._ClickUiObj.BtnClick) then
        return false
    end
    if not self._Root or XTool.UObjIsNil(self._Root.Transform) then
        return false
    end
    if not self._Root.UiModel or XTool.UObjIsNil(self._Root.UiModel.UiFarCamera) then
        return false
    end
    if XTool.UObjIsNil(self._InputAnim) then
        return false
    end
    return true
end

---切换常规状态/音乐状态
function XUiPanelMusicScene:SwitchMusicMode()
    if not self._IsPlaying or self._ForbidSwitch then
        return
    end
    local nowTime = XTime.GetServerNowTimestamp()
    if self._ClickTime and nowTime - self._ClickTime < self._Cd then
        return
    end
    self._ClickTime = nowTime
    self._PlayMode = NextMode[self._PlayMode]
    self:PlayKuroroAnimation(true)
    self:ApplyModel()
end

function XUiPanelMusicScene:ApplyModel()
    local playMode = self:ResolvePlayMode()
    self._ModelHandler[playMode]()
    if not self._DontSaveData then
        XMVCA.XMusicScene:SavePlayMode(self._SceneId, playMode)
    end
end

function XUiPanelMusicScene:ResolvePlayMode()
    return self._PlayMode
end

function XUiPanelMusicScene:ResolveMusicLogic()
    if self._ForceFullMusic then
        return PlayLogic.Full
    end
    return self._ExclusiveCueId == self._CurCueId and PlayLogic.Full or PlayLogic.Simple
end

---播放切换动画
function XUiPanelMusicScene:PlayKuroroAnimation(isPressKuroro)
    local stateName = self._StateNameMap[self._PlayMode][isPressKuroro]
    if self._InputAnim and not string.IsNilOrEmpty(stateName) then
        self._InputAnim:CrossFade(stateName, 0.2, 0)
    end
    local effectHandler = self._KuroroEffectHandler[self._PlayMode][isPressKuroro]
    if effectHandler then
        effectHandler()
    end
end

---常规状态
function XUiPanelMusicScene:PlayNormalStatus()
    --器乐版
    self:ChangeMusicSourceAisac(self._NormalTargetValue)
    self:SetSceneEffectVisible(true, false)
end

---音乐状态
function XUiPanelMusicScene:PlayMusicStatus()
    --人声版
    self:ChangeMusicSourceAisac(self._MusicTargetValue)
    self:SetSceneEffectVisible(true, true)
    
    self._LogicMode = self:ResolveMusicLogic()
    self._LogicHandler[self._LogicMode]()
end

---简单版音乐状态
function XUiPanelMusicScene:PlayMusicSimpleLogic()

end

---完全版音乐状态
function XUiPanelMusicScene:PlayMusicFullLogic()

end

function XUiPanelMusicScene:SetSceneEffectVisible(isNormal, isMusic)
    if not self._SceneUiObj then
        return
    end
    self:SetSceneNodeVisible(self._SceneUiObj.NormalMod, isNormal) --常驻特效
    self:SetSceneNodeVisible(self._SceneUiObj.MusicMod, isMusic) --音乐模式增强特效
end

function XUiPanelMusicScene:SetClickEffectVisible(isVisible)
    if not self._SceneUiObj then
        return
    end
    self:SetSceneNodeVisible(self._SceneUiObj.CanClickEffect, isVisible)
end

function XUiPanelMusicScene:SetSceneNodeVisible(node, isVisible)
    if node then
        node.gameObject:SetActiveEx(isVisible)
    end
end

---切换器乐和人声
function XUiPanelMusicScene:ChangeMusicSourceAisac(targetValue)
    CS.XAudioManager.ChangeMusicSourceAisac(self._TrackKey, targetValue, self._CurveTime)
end

---cd机切换bgm（切换简单版和完全版音乐状态）
function XUiPanelMusicScene:OnMusicPlayerChange(cueId)
    self._CurCueId = cueId
    if not self._IsPlaying or self._CurCueId == cueId or self:ResolvePlayMode() == Mode.Normal then
        return
    end
    self:ApplyModel()
end

---通过设置改变播放模式
function XUiPanelMusicScene:OnSettingChange(sceneId, mode)
    if sceneId ~= self._SceneId or not self._IsPlaying then
        return
    end
    self._PlayMode = mode
    self:PlayKuroroAnimation(false)
    self:ApplyModel()
end

function XUiPanelMusicScene:ShowKuroroEffect(mode)
    self:ClearKuroroEffectTimer()
    if not self._SceneUiObj then
        return
    end
    self:SetSceneNodeVisible(self._SceneUiObj.NormalFace, mode == KuroroEffectMode.Normal)
    self:SetSceneNodeVisible(self._SceneUiObj.MusicFace, mode == KuroroEffectMode.Music)
    self:SetSceneNodeVisible(self._SceneUiObj.NormaltoMusic, mode == KuroroEffectMode.ToMusic)
    self:SetSceneNodeVisible(self._SceneUiObj.MusictoNormal, mode == KuroroEffectMode.ToNormal)
end

function XUiPanelMusicScene:ShowKuroroNormalEffect()
    self:ShowKuroroEffect(KuroroEffectMode.Normal)
end

function XUiPanelMusicScene:ShowKuroroToNormalEffect()
    self:ShowKuroroEffect(KuroroEffectMode.ToNormal)
    self._KuroroEffectTimerId = XScheduleManager.ScheduleOnce(function()
        self:ShowKuroroNormalEffect()
    end, self._Cfg.AnimSwitchTime)
end

function XUiPanelMusicScene:ShowKuroroMusicEffect()
    self:ShowKuroroEffect(KuroroEffectMode.Music)
end

function XUiPanelMusicScene:ShowKuroroToMusicEffect()
    self:ShowKuroroEffect(KuroroEffectMode.ToMusic)
    self._KuroroEffectTimerId = XScheduleManager.ScheduleOnce(function()
        self:ShowKuroroMusicEffect()
    end, self._Cfg.AnimSwitchTime)
end

function XUiPanelMusicScene:ClearKuroroEffectTimer()
    if self._KuroroEffectTimerId then
        XScheduleManager.UnSchedule(self._KuroroEffectTimerId)
        self._KuroroEffectTimerId = nil
    end
end

return XUiPanelMusicScene