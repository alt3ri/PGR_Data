---@class XUiSkyGardenShoppingStreetGamePet : XUiNode
local XUiSkyGardenShoppingStreetGamePet = XClass(XUiNode, "XUiSkyGardenShoppingStreetGamePet")

--region 生命周期

function XUiSkyGardenShoppingStreetGamePet:OnStart()
    self:_RegisterButtonClicks()
    self._TalkStatus = true

    self._MoodId2Name = {
        [1] = "idle",
        [2] = "miyan",
        [3] = "shengqi",
        [4] = "wuyu",
        [5] = "xiao",
        [6] = "yansu",
        [7] = "zhayan",
    }

    self.PanelTalk.gameObject:SetActive(false)
    self._MascotData = self._Control:GetMascotData()
    self._DelayTime = tonumber(self._Control:GetGlobalConfigByKey("MascotMessageDelayTime")) * 1000
    self._DelayFunc = handler(self, self._DelayHideFunc)
    self._RunningAnimCallback = handler(self, self.RunningAnimCallback)

    self.WWX2.gameObject:SetActive(true)
    self.WWX2.AnimationState:Complete('+', self._RunningAnimCallback)
    self.WWX2.gameObject:SetActive(false)
end

function XUiSkyGardenShoppingStreetGamePet:OnGetLuaEvents()
    return { XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_LIKE_TALK_REFRESH, }
end

function XUiSkyGardenShoppingStreetGamePet:OnNotify(event)
    if event == XMVCA.XBigWorldService.DlcEventId.EVENT_BUSINESS_STREET_LIKE_TALK_REFRESH then
        self:CheckTips()
    end
end

function XUiSkyGardenShoppingStreetGamePet:OnDisable()
    self.WWX2.AnimationState:Complete('-', self._RunningAnimCallback)
    self:_RemoveTimer()
    self:_DelayHideFunc()
end

--endregion

function XUiSkyGardenShoppingStreetGamePet:RunningAnimCallback()
    self.WWX2.AnimationState:SetAnimation(0, "idle", true)
end

function XUiSkyGardenShoppingStreetGamePet:CheckTips()
    if self._MascotData:HasLikeMessageTag() then
        self.HasLikeMessage = true
        self:_AddMessage(self._MascotData:GetLikeRandomMessage())
    end
end

function XUiSkyGardenShoppingStreetGamePet:StageStartTips()
    if self.HasLikeMessage then return end
    self:_AddMessage(self._MascotData:GetStartRandomMessage())
end

function XUiSkyGardenShoppingStreetGamePet:ShowTalkStatus(isShow)
    if not isShow then
        self.PanelTalk.gameObject:SetActive(false)
    end
    self._TalkStatus = isShow
end

--region 按钮事件
function XUiSkyGardenShoppingStreetGamePet:OnPanelTalkClick()
    if self._isPlayingAnim then return end
    self:_RemoveTimer()
    self._isPlayingAnim = true
    self.Parent:PlayTalkAnim(false, nil, function() self:_TalkFinish() end)
end

function XUiSkyGardenShoppingStreetGamePet:OnImgPetClick()
    if self.HasLikeMessage then return end
    if self._IsRunningStatus then return end
    self:_AddMessage(self._MascotData:GetRandomMessage())
end

function XUiSkyGardenShoppingStreetGamePet:SetRunningStatus(isRunning)
    self._IsRunningStatus = isRunning
    self:_TalkFinish()
    self.WWX1.gameObject:SetActive(not isRunning)
    self.WWX2.gameObject:SetActive(isRunning)
end

function XUiSkyGardenShoppingStreetGamePet:PlayTipsAnim(moodId)
    if not moodId then return end

    local animStr = self._MoodId2Name[moodId]
    if not animStr then return end

    self.WWX1.AnimationState:SetAnimation(0, animStr, true)
end

function XUiSkyGardenShoppingStreetGamePet:PlayRunningAnim(showType)
    if showType == 1 then
        self.WWX2.AnimationState:SetAnimation(0, "caimi", true)
        if self.ForceFieldEnable then
            self.ForceFieldEnable:PlayTimelineAnimation()
        end
    else
        self.WWX2.AnimationState:SetAnimation(0, "record", true)
    end
end

--endregion

--region 私有方法

function XUiSkyGardenShoppingStreetGamePet:_RegisterButtonClicks()
    --在此处注册按钮事件
    self.PanelTalk:AddEventListener(handler(self, self.OnPanelTalkClick))
    self.ImgPet:AddEventListener(handler(self, self.OnImgPetClick))
end

function XUiSkyGardenShoppingStreetGamePet:_AddMessage(msg, moodId)
    if not self._TalkStatus then return end

    self.TxtTalk.text = msg
    self:_RemoveTimer()
    self._TimerId = XScheduleManager.ScheduleOnce(self._DelayFunc, self._DelayTime)
    
    self._isPlayingAnim = true
    self.Parent:PlayTalkAnim(true, function()
        self.PanelTalk.gameObject:SetActive(true)
        self:PlayTipsAnim(moodId)
    end, function()
        self._isPlayingAnim = false
    end)
end

function XUiSkyGardenShoppingStreetGamePet:_TalkFinish()
    self:PlayTipsAnim(1)
    self.PanelTalk.gameObject:SetActive(false)
    self._isPlayingAnim = false
end

function XUiSkyGardenShoppingStreetGamePet:_DelayHideFunc()
    self._isPlayingAnim = true
    self.Parent:PlayTalkAnim(false, nil, function() self:_TalkFinish() end)
    self.HasLikeMessage = false
end

function XUiSkyGardenShoppingStreetGamePet:_RemoveTimer()
    if not self._TimerId then return end
    XScheduleManager.UnSchedule(self._TimerId)
    self._TimerId = nil
end
--endregion

return XUiSkyGardenShoppingStreetGamePet
