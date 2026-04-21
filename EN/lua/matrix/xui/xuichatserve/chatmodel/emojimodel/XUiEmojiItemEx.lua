--===============
--新版表情控件
--===============
local XUiEmojiItemEx = XClass(nil, "XUiEmojiItemEx")
local STR_RESIDUE = CS.XTextManager.GetText("Residue")

function XUiEmojiItemEx:Ctor(uiPrefab, panel)
    XTool.InitUiObjectByUi(self, uiPrefab)
    self.OnClickEmojiCb = function(emoji) panel:OnClickEmojiItem(emoji) end
    XUiHelper.RegisterClickEvent(self, self.BtnEmoji, handler(self, self.OnClickBtnEmoji))
end

function XUiEmojiItemEx:Refresh(emoji)
    self:Reset()
    self.EmojiData = emoji

    local isDynamicEmoji = XDataCenter.ChatManager.IsDynamicEmoji(emoji.Id)
    self.RImgEmojiD.gameObject:SetActiveEx(not isDynamicEmoji)
    self.ImgEmojiSprite.gameObject:SetActiveEx(isDynamicEmoji)
    if isDynamicEmoji then
        -- 刷新动态表情
        self:RefreshDynamicFace()
    else
        -- 静态表情
        self.RImgEmojiD:SetRawImage(self.EmojiData:GetEmojiIcon())
    end
    
    local isTimeLimit = self.EmojiData:IsLimitEmoji()
    self.ObjTime.gameObject:SetActiveEx(isTimeLimit)
    self.IsOverTime = false
    if isTimeLimit then
        self:SetTimeText()
        self:SetCountDownTimer()
    end
    self:RefreshRedPoint()
    
    local connotationDesc = self.EmojiData:GetEmojiConnotationDesc()

    if self.TxtName then
        self.TxtName.gameObject:SetActiveEx(not string.IsNilOrEmpty(connotationDesc))
        self.TxtName.text = connotationDesc or ''
    end
end

function XUiEmojiItemEx:OnEnable()
    --如果是动态表情表， 由于在OnDisable释放了资源， 所以这里需要刷新一下
    local emojiType = self.EmojiData:GetEmojiType()
    if emojiType == XChatConfigs.EmojiType.Dynamic then
        self:RefreshDynamicFace()
    end
end

function XUiEmojiItemEx:RefreshDynamicFace()
    local emojiId = self.EmojiData:GetEmojiId()
    if not self.dynamicFaceId then
        self.dynamicFaceId = XDataCenter.ChatManager.CreateDynamicFace(self.ImgEmojiSprite, emojiId)
    else
        XDataCenter.ChatManager.SetDynamicFaceAtlas(self.dynamicFaceId, emojiId)
    end
end

function XUiEmojiItemEx:ReleaseDynamicFace()
    if self.dynamicFaceId then
        XDataCenter.ChatManager.ReleaseDynamicFace(self.dynamicFaceId)
        self.dynamicFaceId = nil
    end
end

function XUiEmojiItemEx:RefreshRedPoint()
    self.PanelNew.gameObject:SetActiveEx(self.EmojiData:GetIsNew())
end

function XUiEmojiItemEx:SetCountDownTimer()
    if self.TimeLimitId then return end
    self.TimeLimitId = XScheduleManager.ScheduleForever(function()
            if not self.Transform or XTool.UObjIsNil(self.Transform) then
                self:StopCountDownTimer()
                return
            end
 
            self:SetTimeText()
        end, 1)
end

function XUiEmojiItemEx:StopCountDownTimer()
    if not self.TimeLimitId then return end
    XScheduleManager.UnSchedule(self.TimeLimitId)
    self.TimeLimitId = nil
end

function XUiEmojiItemEx:SetTimeText()
    local timeNow = XTime.GetServerNowTimestamp()
    local deltaTime = self.EmojiData:GetEmojiEndTime() - timeNow
    if deltaTime > 0 then
        if self.TxtTime then
            self.TxtTime.text = STR_RESIDUE .. XUiHelper.GetTime(deltaTime, XUiHelper.TimeFormatType.CHATEMOJITIMER)
        end
    else
        self.IsOverTime = true
        self:StopCountDownTimer()
        self.GameObject:SetActiveEx(false)
    end
end

function XUiEmojiItemEx:OnClickBtnEmoji()
    if self.IsOverTime then
        XUiManager.TipText("EmojiOverTime")
        return
    end
    if self.OnClickEmojiCb then self.OnClickEmojiCb(self.EmojiData) end
    -- 点击后关闭新标签蓝点
    self.EmojiData:SetNotNew()
    self:RefreshRedPoint()
    XEventManager.DispatchEvent(XEventId.EVENT_CHAT_EMOJI_REFRESH_RED)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_CHAT_EMOJI_REFRESH_RED)
end

function XUiEmojiItemEx:Reset()
    self:StopCountDownTimer()
end

function XUiEmojiItemEx:OnDisable()
    self:StopCountDownTimer()
    self:ReleaseDynamicFace()
end

function XUiEmojiItemEx:Show()
    self.GameObject:SetActiveEx(true)
end

function XUiEmojiItemEx:Hide()
    self.GameObject:SetActiveEx(false)
end

return XUiEmojiItemEx