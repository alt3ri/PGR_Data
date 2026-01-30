local XUiBigWorldMessageVisual = require("XUi/XUiBigWorld/XMessage/Common/XUiBigWorldMessageVisual")

---@class XUiBigWorldMessageGrid : XUiNode
---@field PanelCharacter UnityEngine.RectTransform
---@field PanelChat UnityEngine.RectTransform
---@field PanelHead UnityEngine.RectTransform
---@field StandIcon UnityEngine.UI.RawImage
---@field TxtName UnityEngine.UI.Text
---@field TxtChat UnityEngine.UI.Text
---@field RImgExpression UnityEngine.UI.RawImage
---@field Visual UnityEngine.RectTransform
---@field RImgPhoto UnityEngine.UI.RawImage
---@field BtnView XUiComponent.XUiButtonExt
---@field _Control XBigWorldMessageControl
---@field Parent XUiBigWorldMessageChat
local XUiBigWorldMessageGrid = XClass(XUiNode, "XUiBigWorldMessageGrid")

-- region 生命周期

function XUiBigWorldMessageGrid:OnStart()
    local animation = self.Transform:FindTransform("Animation")
    local panelChatEnable = animation:FindTransform("PanelChatEnable")
    local panelCharacter = animation:FindTransform("PanelCharacter")

    ---@type XUiBigWorldMessageVisual
    self._Video = XUiBigWorldMessageVisual.New(self.Visual, self)

    ---@type XBWMessageContentEntity
    self._Content = false

    self._IsWait = false
    self._AnimationName = "PanelCharacter"
    
    self._TextureCache = false
    self._OverrideTextureCache = false

    self.LoadingEffect = self.Transform:FindTransform("PanelMessageLoading")

    if panelChatEnable then
        self.ChatPlayable = panelChatEnable:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    end
    if panelCharacter then
        self.CharacterPlayable = panelCharacter:GetComponent(typeof(CS.UnityEngine.Playables.PlayableDirector))
    end

    self:_RegisterButtonClicks()
    self:_RegisterListeners()
end

function XUiBigWorldMessageGrid:OnEnable()
    self:_RegisterSchedules()
    self:_RegisterRedPointEvents()
end

function XUiBigWorldMessageGrid:OnDisable()
    self:_RemoveSchedules()
    self._AnimationName = "PanelCharacter"
    self._IsPlayed = false
end

function XUiBigWorldMessageGrid:OnDestroy()
    self:_RemoveListeners()
    self:_DestroyTextureCache()
    self:_DestroyOverrideTextureCache()
end

-- endregion

function XUiBigWorldMessageGrid:OnBtnViewClick()
    self:OpenPreview()
end

function XUiBigWorldMessageGrid:OnPreviewClose()
    if self._IsWait then
        self.Parent:RefreshPanelTips(false)
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_PLAY_NEXT_MESSAGE_NOTIFY)
    end
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageGrid:Refresh(content)
    if content:IsMultiple() then
        self.TxtName.gameObject:SetActiveEx(true)
        self.TxtName.text = content:GetSpeakerName()
    else
        self.TxtName.gameObject:SetActiveEx(false)
    end

    self.StandIcon:SetRawImage(content:GetSpeakerIcon())

    self._Content = content
    self._IsWait = content:IsWait()

    self:_DestroyTextureCache()

    if content:IsMemes() then
        self._Video:Close()
        self.TxtChat.gameObject:SetActiveEx(false)
        self.RImgPhoto.gameObject:SetActiveEx(false)
        self.RImgExpression.gameObject:SetActiveEx(true)
        self.RImgExpression:SetRawImage(content:GetMemes())
    elseif content:IsVideo() then
        self._Video:Open()
        self.TxtChat.gameObject:SetActiveEx(false)
        self.RImgPhoto.gameObject:SetActiveEx(false)
        self.RImgExpression.gameObject:SetActiveEx(false)
        self._Video:Refersh(content:GetVideoImage(), content:GetVideoId(), self._IsWait)
    elseif content:IsPhoto() then
        self._Video:Close()
        self.TxtChat.gameObject:SetActiveEx(false)
        self.RImgPhoto.gameObject:SetActiveEx(true)
        self.RImgExpression.gameObject:SetActiveEx(false)

        local photoImage = content:GetPhotoImage()

        if not photoImage then
            self.RImgPhoto:SetRawImage(content:GetImage(), function()
                self._Control:AdaptImageSize(self.RImgPhoto)
            end)
        else
            self.RImgPhoto.texture = photoImage
            self._Control:AdaptImageSize(self.RImgPhoto)
        end
    elseif content:IsImage() then
        self._Video:Close()
        self.TxtChat.gameObject:SetActiveEx(false)
        self.RImgPhoto.gameObject:SetActiveEx(true)
        self.RImgExpression.gameObject:SetActiveEx(false)
        self.RImgPhoto:SetRawImage(content:GetImage(), function()
            self._Control:AdaptImageSize(self.RImgPhoto)
        end)
    elseif content:IsImageToVideo() then
        self._Video:Close()
        self.TxtChat.gameObject:SetActiveEx(false)
        self.RImgPhoto.gameObject:SetActiveEx(true)
        self.RImgExpression.gameObject:SetActiveEx(false)
        self.RImgPhoto:SetRawImage(content:GetImage(), function()
            self._Control:AdaptImageSize(self.RImgPhoto)
        end)
    else
        self._Video:Close()
        self.TxtChat.gameObject:SetActiveEx(true)
        self.RImgPhoto.gameObject:SetActiveEx(false)
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
        self:_FinishAnimation()
        self:_PlayFinish(content, true)
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
        self:_PlayFinish(content, false)
    end)
end

function XUiBigWorldMessageGrid:OpenPreview()
    if not self._Content then
        return
    end

    ---@type XPreviewData
    local previewData = XMVCA.XBigWorldCommon:GetPreviewData()
    
    if self._Content:IsImageToVideo() then
        previewData:SetImageToVideoData(self._Content:GetImage(), self._Content:GetVideoId())
    elseif self._Content:IsImage() then
        previewData:SetImageData(self._Content:GetImage())
    elseif self._Content:IsPhoto() then
        self:_DestroyOverrideTextureCache()
        self._OverrideTextureCache = self._Content:GetPhotoImage()
        previewData:SetTextureData(self._OverrideTextureCache, self._Content:GetImage())
    elseif self._Content:IsVideo() then
        previewData:SetVideoData(self._Content:GetVideoId(), self._Content:GetImage())
        previewData:SetIsFullScreen(true)
    end

    XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_PLAY_PAUSE_NOTIFY)

    XMVCA.XBigWorldUI:Open("UiBigWorldVideoPreview", previewData)
end

-- region 私有方法

function XUiBigWorldMessageGrid:_RegisterButtonClicks()
    -- 在此处注册按钮事件
    self.BtnView:AddEventListener(Handler(self, self.OnBtnViewClick))
end

function XUiBigWorldMessageGrid:_RegisterSchedules()
    -- 在此处注册定时器
end

function XUiBigWorldMessageGrid:_RemoveSchedules()
    -- 在此处移除定时器
end

function XUiBigWorldMessageGrid:_RegisterListeners()
    -- 在此处注册事件监听
    XEventManager.AddEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_PREVIEW_CLOSE, self.OnPreviewClose, self)
end

function XUiBigWorldMessageGrid:_RemoveListeners()
    -- 在此处移除事件监听
    XEventManager.RemoveEventListener(XMVCA.XBigWorldService.DlcEventId.EVENT_BIG_WORLD_PREVIEW_CLOSE, self.OnPreviewClose, self)
end

function XUiBigWorldMessageGrid:_RegisterRedPointEvents()
    -- 在此处注册红点事件
    -- self:AddRedPointEvent(...)
end

-- endregion

function XUiBigWorldMessageGrid:_DestroyTextureCache()
    if self._TextureCache then
        CS.UnityEngine.Object.DestroyImmediate(self._TextureCache)
        self._TextureCache = false
    end
end

function XUiBigWorldMessageGrid:_DestroyOverrideTextureCache()
    if self._OverrideTextureCache then
        CS.UnityEngine.Object.DestroyImmediate(self._OverrideTextureCache)
        self._OverrideTextureCache = false
    end
end

---@param content XBWMessageContentEntity
function XUiBigWorldMessageGrid:_PlayFinish(content, isComplete)
    if self._IsWait then
        self.Parent:RefreshPanelTips(self._IsWait)
        return
    end

    if content:IsEnd() then
        XEventManager.DispatchEvent(XMVCA.XBigWorldService.DlcEventId.EVENT_MESSAGE_PLAY_FINISH_NOTIFY, content, isComplete)
    end
end

function XUiBigWorldMessageGrid:_FinishAnimation()
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
end

return XUiBigWorldMessageGrid
