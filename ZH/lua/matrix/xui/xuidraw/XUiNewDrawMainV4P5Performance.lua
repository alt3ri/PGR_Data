local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
local XDrawPerformanceBinder = require("XUi/XUiDraw/XDrawPerformanceBinder")

---@class XUiNewDrawMainV4P5Performance : XLuaUi
---@field VideoPlayer XVideoPlayerUGUI
local XUiNewDrawMainV4P5Performance = XLuaUiManager.Register(XLuaUi, "UiNewDrawMainV4P5Performance")

function XUiNewDrawMainV4P5Performance:OnAwake()
    self:RegisterUiEvents()
    self:InitScene()
    -- 进入表演场景，设置场景类型为战斗类型
    CS.XGlobalIllumination.SetSceneType(CS.XSceneType.Fight)
end

--- @param rewardInfo table 当前展示的奖励信息
--- @param closeCb function|nil 关闭时的回调（通知外部继续流程）
function XUiNewDrawMainV4P5Performance:OnStart(rewardInfo, closeCb)
    self.CloseCb = closeCb
    self.IsClosed = false
    self.IsInfoShown = false
    self.ImgBg.gameObject:SetActiveEx(false)
    self.PanelInfo.gameObject:SetActiveEx(false)
    self.PanelPerformance.gameObject:SetActiveEx(false)
    self.RImgIcon.gameObject:SetActiveEx(false)
    self.GridGeneralSkills = {}
    self.EnterPerformanceVideoId = tonumber(XDrawConfigs.GetDrawClientConfig("EnterPerformanceVideoId"))
    self:Refresh(rewardInfo)
end

function XUiNewDrawMainV4P5Performance:OnDestroy()
    self:CleanupPerformance()
    -- 离开表演场景，重置场景类型为Ui类型
    CS.XGlobalIllumination.SetSceneType(CS.XSceneType.Ui)
end

function XUiNewDrawMainV4P5Performance:InitScene()
    self.PerformanceRoot = self.UiModelGo.transform:Find("PerformanceRoot")
    self.NpcRoot = self.PerformanceRoot:Find("NpcRoot")
    self.CameraRoot = self.PerformanceRoot:Find("CameraRoot")
    self.EffectRoot = self.PerformanceRoot:Find("EffectRoot")
    self.PerformancePlayable = self.PerformanceRoot:Find("PerformancePlayable")
    self.AnimEventSender = self.PerformancePlayable:GetComponent(typeof(CS.XTimeLine.XTimeLineAnimEventSender))
    self.PerformanceEventReceiver = self.PerformancePlayable:GetComponent(typeof(CS.XUiPerformanceEventReceiver))
    self.Loader = self.PerformanceRoot:GetLoader()

    self.UiModel.UiFarCamera.gameObject:SetActiveEx(false)
    self.UiModel.UiNearCamera.gameObject:SetActiveEx(false)

    -- XRLTerrainRendering 由 C# 构建，Lua 只传 UiSceneInfo.Transform
    if self.UiSceneInfo and self.UiSceneInfo.Transform then
        self.PerformanceEventReceiver:InitScene(self.UiSceneInfo.Transform)
    end
    -- 通用帧事件钩子
    --self.PerformanceEventReceiver:RegisterCustomCallback(function(param)
    --    self:OnPerformanceCustomEvent(param)
    --end)
end

function XUiNewDrawMainV4P5Performance:Refresh(rewardInfo)
    self.RewardInfo = rewardInfo
    self.IsInfoShown = false
    self.CharacterId = XDataCenter.DrawManager.GetRewardGoodsId(rewardInfo)
    if not self.CharacterId or XTypeManager.GetTypeById(self.CharacterId) ~= XArrangeConfigs.Types.Character then
        XLog.Error("XUiNewDrawMainV4P5Performance:Refresh error: rewardType is not Character")
        self:DoClose()
        return
    end
    self.RolePerformanceConfig = XDrawConfigs.GetDrawRolePerformance(self.CharacterId)
    if not self.RolePerformanceConfig then
        XLog.Error("XUiNewDrawMainV4P5Performance:Refresh error: RolePerformanceConfig is nil, CharacterId = " .. tostring(self.CharacterId))
        self:DoClose()
        return
    end
    self:RefreshInfo()
    self:LoadAsset()
    self:PlayEnterPerformance(function()
        self.PanelPerformance.gameObject:SetActiveEx(false)
        self:PlayCharacterPerformance()
    end)
end

function XUiNewDrawMainV4P5Performance:RefreshInfo()
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId)
    self.TxtCharacterName.text = charConfig.LogName

    local elementConfig = XMVCA.XCharacter:GetCharElement(charConfig.Element)
    local careerConfig = XMVCA.XCharacter:GetNpcTypeTemplate(charConfig.Career)
    self.TxtCharacterType.text = XUiHelper.GetText("DrawBannerRoleTypeText", elementConfig.ElementName, careerConfig.Name)

    -- 元素
    self.RImgTypeIcon:SetRawImage(elementConfig.Icon2)

    -- 机制
    local generalSkillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(self.CharacterId)
    for index, id in ipairs(generalSkillIds) do
        local grid = self.GridGeneralSkills[index]
        if not grid then
            grid = XUiHelper.Instantiate(self.RImgIcon, self.PanelType)
            self.GridGeneralSkills[index] = grid
        end
        grid.gameObject:SetActiveEx(true)
        local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
        grid:SetRawImageEx(generalSkillConfig.IconTranspose)
    end

    for index = #generalSkillIds + 1, #self.GridGeneralSkills do
        local grid = self.GridGeneralSkills[index]
        if grid then
            grid.gameObject:SetActiveEx(false)
        end
    end

    local isConvertFrom = self.RewardInfo.ConvertFrom and self.RewardInfo.ConvertFrom > 0
    self.NewBg.gameObject:SetActiveEx(not isConvertFrom)
    self.Icon01.gameObject:SetActiveEx(not isConvertFrom)
    self.Icon02.gameObject:SetActiveEx(isConvertFrom)
    if not isConvertFrom then
        if not self.GridChallengeUi1 then
            ---@type XUiGridCommon
            self.GridChallengeUi1 = XUiGridCommon.New(nil, self.GridChallenge1)
        end
        self.GridChallengeUi1:Refresh(self.RewardInfo)
    else
        if not self.GridChallengeUi2 then
            ---@type XUiGridCommon
            self.GridChallengeUi2 = XUiGridCommon.New(nil, self.GridChallenge2)
        end
        self.GridChallengeUi2:Refresh(self.RewardInfo)
    end
end

function XUiNewDrawMainV4P5Performance:LoadAsset()
    ---@type XDrawPerformanceBinder
    self.Binder = XDrawPerformanceBinder.New(self)
    self.Binder:Bind()
end

function XUiNewDrawMainV4P5Performance:PlayEnterPerformance(callback)
    self.ImgBg.gameObject:SetActiveEx(false)
    self.PanelInfo.gameObject:SetActiveEx(false)
    self.PanelPerformance.gameObject:SetActiveEx(true)
    self.BtnSkip.gameObject:SetActiveEx(true)
    if XTool.IsNumberValid(self.EnterPerformanceVideoId) then
        self.VideoPlayer.ActionEnded = callback
        self.VideoPlayer.ActionError = callback
        self.VideoPlayer:SetInfoByVideoId(self.EnterPerformanceVideoId)
        self.VideoPlayer:Prepare()
    else
        if callback then
            callback()
        end
    end
end

function XUiNewDrawMainV4P5Performance:PlayCharacterPerformance()
    if not self.Binder:HasDirector() then
        self:ShowCharacterInfo()
        return
    end
    -- 播放表演
    self.Binder:Play()
    -- 播放音频
    local voiceId = self.RolePerformanceConfig.VoiceId or 0
    if voiceId > 0 then
        self.VoiceInfo = XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.Voice, voiceId)
    end
    -- 根据 UiShowTime 延迟显示角色信息；与 Timeline 时长取最小值，避免 UiShowTime > Timeline 时长导致空白等待
    local showTime = self.RolePerformanceConfig.UiShowTime or 0
    local duration = self.Binder:GetDuration()
    if duration > 0 and showTime > duration then
        showTime = duration
    end
    if showTime > 0 then
        local delay = math.floor(showTime * XScheduleManager.SECOND)
        self.ShowInfoTimerId = XScheduleManager.ScheduleOnce(function()
            if XTool.UObjIsNil(self.GameObject) then
                return
            end
            self.ShowInfoTimerId = nil
            self:ShowCharacterInfo()
        end, delay)
    else
        self:ShowCharacterInfo()
    end
end

function XUiNewDrawMainV4P5Performance:ShowCharacterInfo()
    if self.IsInfoShown then
        return
    end
    self.IsInfoShown = true
    self.BtnSkip.gameObject:SetActiveEx(false)
    self.ImgBg.gameObject:SetActiveEx(true)
    self.PanelInfo.gameObject:SetActiveEx(true)
end

-- 通用帧事件回调占位（由 PerformanceEvent 轨道的 CustomEvent 帧事件触发）
--function XUiNewDrawMainV4P5Performance:OnPerformanceCustomEvent(param)
--end

function XUiNewDrawMainV4P5Performance:CleanupPerformance()
    if self.ShowInfoTimerId then
        XScheduleManager.UnSchedule(self.ShowInfoTimerId)
        self.ShowInfoTimerId = nil
    end
    -- 还原被隐藏的 UI 场景渲染
    if not XTool.UObjIsNil(self.PerformanceEventReceiver) then
        self.PerformanceEventReceiver:RestoreScene()
    end
    if self.Binder then
        self.Binder:Stop()
        self.Binder = nil
    end
    if not XTool.UObjIsNil(self.AnimEventSender) then
        self.AnimEventSender:StopAllFramePlayedAudio()
    end
    if self.VoiceInfo then
        self.VoiceInfo:Stop()
        self.VoiceInfo = nil
    end
    if self.VideoPlayer then
        self.VideoPlayer:Stop()
    end
end

function XUiNewDrawMainV4P5Performance:RegisterUiEvents()
    self.BtnClose:AddEventListener(handler(self, self.DoClose))
    self.BtnSkip:AddEventListener(handler(self, self.DoClose))
end

function XUiNewDrawMainV4P5Performance:DoClose()
    if self.IsClosed then
        return
    end
    self.IsClosed = true
    self:Close()
    if self.CloseCb then
        self.CloseCb()
    end
end

return XUiNewDrawMainV4P5Performance
