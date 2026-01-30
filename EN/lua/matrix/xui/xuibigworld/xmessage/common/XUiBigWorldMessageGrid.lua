---@class XUiBigWorldMessageGrid : XUiNode
---@field PanelCharacter UnityEngine.RectTransform
---@field PanelChat UnityEngine.RectTransform
---@field PanelHead UnityEngine.RectTransform
---@field StandIcon UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field TxtChat UnityEngine.UI.Text
---@field RImgExpression UnityEngine.UI.RawImage
---@field _Control XBigWorldMessageControl
local XUiBigWorldMessageGrid = XClass(XUiNode, "XUiBigWorldMessageGrid")

-- region 生命周期

function XUiBigWorldMessageGrid:OnStart()
    local animation = self.Transform:FindTransform("Animation")
    local panelChatEnable = animation:FindTransform("PanelChatEnable")
    local panelCharacter = animation:FindTransform("PanelCharacter")

    self.LoadingEffect = self.Transform:FindTransform("PanelMessageLoading")
    self._AnimationName = "PanelCharacter"

    if panelChatEnable then
        self.ChatPlayable = panelChatEnable:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    end
    if panelCharacter then
        self.CharacterPlayable = panelCharacter:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    end

    self:_RegisterButtonClicks()
end

function XUiBigWorldMessageGrid:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterListeners()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMessageGrid:OnDisable()
    self:_RemoveSchedules()
    self:_RemoveListeners()
    self._AnimationName = "PanelCharacter"
    self._IsPlayed = false
end

function XUiBigWorldMessageGrid:OnDestroy()

end

-- endregion

---@param content XBWMessageContentEntity
function XUiBigWorldMessageGrid:Refresh(content)
    if content:IsMultiple() then
        self.TxtName.gameObject:SetActiveEx(true)
        self.TxtName.text = content:GetSpeakerName()
    else
        self.TxtName.gameObject:SetActiveEx(false)
    end
    self.StandIcon:SetRawImage(content:GetSpeakerIcon())

    if content:IsMemes() then
        self.TxtChat.gameObject:SetActiveEx(false)
        self.RImgExpression.gameObject:SetActiveEx(true)
        self.RImgExpression:SetRawImage(content:GetMemes())
    else
        self.TxtChat.gameObject:SetActiveEx(true)
        self.RImgExpression.gameObject:SetActiveEx(false)
        self.TxtChat.text = content:GetText()
    end
end

function XUiBigWorldMessageGrid:SetLoadingEffectActive(isActive)
    if not XTool.UObjIsNil(self.LoadingEffect) then
        self.LoadingEffect.gameObject:SetActiveEx(isActive)
        self.PanelChat.gameObject:SetActiveEx(not isActive)
    end
    if isActive then
        self._AnimationName = "PanelChatEnable"
    end
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageGrid:PlayEnableAnimation(content, audioPlayer)
    if content:IsComplete() then
        if self._AnimationName == "PanelChatEnable" then
            if self.ChatPlayable then
                self.ChatPlayable.time = self.ChatPlayable.duration
                self.ChatPlayable:Evaluate()
            end
        end
        if self._AnimationName == "PanelCharacter" then
            if self.CharacterPlayable then
                self.CharacterPlayable.time = self.CharacterPlayable.duration
                self.CharacterPlayable:Evaluate()
            end
        end

        self:_PlayFinish(content)
        return
    end
    if self._IsPlayed then
        return
    end

    if audioPlayer then
        if content:IsReceive() then
            audioPlayer:PlayByKeyName("getmessage")
        elseif content:IsSend() then
            audioPlayer:PlayByKeyName("sendmessage")
        end
    end

    self._IsPlayed = true

    self:PlayAnimation(self._AnimationName, function(isFinish)
        self:_PlayFinish(content)
    end)
end

-- region 私有方法

function XUiBigWorldMessageGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
end

function XUiBigWorldMessageGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMessageGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMessageGrid:_RegisterListeners()
    -- 在此处注册事件监听
end

function XUiBigWorldMessageGrid:_RemoveListeners()
    -- 在此处移除事件监听
end

function XUiBigWorldMessageGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

-- endregion

---@param content XBWMessageContentEntity
function XUiBigWorldMessageGrid:_PlayFinish(content)
    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAY_NEXT_MESSAGE_NOTIFY)

    if content:IsEnd() then
        CS.XLog.Debug("[BigWorldMessage]: Play Message Content Play Finish. StepId: " .. tostring(content:GetStepId()) .. "\n" .. debug.traceback())
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_PLAY_FINISH_NOTIFY, content)
    end
end

return XUiBigWorldMessageGrid
