
---@class XUiGridRaceFightCharacter : XUiNode
---@field Parent XUiRaceFightMain
local XUiGridRaceFightCharacter = XClass(XUiNode, "XUiGridRaceFightCharacter")


function XUiGridRaceFightCharacter:OnStart(...)
    self:_RegisterButtonClicks()
    self.GridSkillBall.gameObject:SetActive(false)
    self.PanelSkillTalkSmall.gameObject:SetActive(false)
    self.TagPredict.gameObject:SetActive(false)
    self.PanelBallShow.gameObject:SetActive(false)
    
    if self.PanelNumber then
        self.PanelNumber.gameObject:SetActive(false)
    end
    if self.PanelEmoji then
        self.PanelEmoji.gameObject:SetActive(false)
    end

    self._Balls = {}
end

function XUiGridRaceFightCharacter:OnGetLuaEvents()
    return {
        XEventId.EVENT_RACE_GAME_POWER_UPDATE, 
        XEventId.EVENT_RACE_GAME_POWER_UPDATE_START,
        XEventId.EVENT_RACE_GAME_SKILL_UPDATE,
        XEventId.EVENT_RACE_GAME_STATE_UPDATE,
    }
end

function XUiGridRaceFightCharacter:OnNotify(event, actorIndex, powerIndex, powerCnt, isShowSignalBall)
    if actorIndex ~= self._index then return end
    if event == XEventId.EVENT_RACE_GAME_POWER_UPDATE then
        self:UpdatePower()
    elseif event == XEventId.EVENT_RACE_GAME_POWER_UPDATE_START then
        self:ShowGetSignalBall(powerIndex)
    elseif event == XEventId.EVENT_RACE_GAME_SKILL_UPDATE then
        self:ShowSkill(powerIndex)
    elseif event == XEventId.EVENT_RACE_GAME_STATE_UPDATE then
        self:SetState(powerIndex)
    end
end

function XUiGridRaceFightCharacter:ShowTagPredict(isShow)
    self.TagPredict.gameObject:SetActive(isShow)
end

-- 显示表情
function XUiGridRaceFightCharacter:ShowEmoji(path, time)
    if not self.PanelEmoji then return end
    if string.IsNilOrEmpty(path) then
        return
    end

    self.PanelEmoji.gameObject:SetActive(true)
    self.ImgEmoji:SetSprite(path)
    self:RemoveEmojiTimer()
    self._EmojiTimerId = XScheduleManager.ScheduleOnce(function()
        self.PanelEmoji.gameObject:SetActive(false)
    end, time or 1000)
end

function XUiGridRaceFightCharacter:SetRank(rank)
    if not self.PanelNumber then return end
    self.PanelNumber.gameObject:SetActive(true)
    self.Number:SetSprite(self._Control:GetClientConfig("RankNumIcon" .. rank))
end

function XUiGridRaceFightCharacter:SetState(state)
    -- 3 受击
    if state ~= 3 then return end
    self:ShowEmoji(self._Control:GetClientConfig("HitEmoji"), tonumber(self._Control:GetClientConfig("HitEmojiTime")))
end

function XUiGridRaceFightCharacter:ShowSkill(skillId)
    if self._config.NormalSkill == skillId then
        self.PanelSkillTalkSmall.gameObject:SetActive(true)
        self:RemoveTalkTimer()
        self._TalkTimerId = XScheduleManager.ScheduleOnce(function()
            self.PanelSkillTalkSmall.gameObject:SetActive(false)
        end, tonumber(self._Control:GetClientConfig("NormalSkillShowTime")) or 2000)

        self:ShowEmoji(self._normalSkConfig.Emoji, self._normalSkConfig.EmojiTime)
    else
        self:ShowEmoji(self._ultraSkConfig.Emoji, self._ultraSkConfig.EmojiTime)
    end
end

function XUiGridRaceFightCharacter:ShowGetSignalBall(signalId)
    if signalId > 0 then
        self:RemoveTimer()
        self.PanelBallShow.gameObject:SetActive(true)
        self:PlayAnimation("SlotEnable")
        self.PanelBall.gameObject:SetActive(false)
        self._SignalId = signalId
    else
        if self._SignalId then
            self:ShowGetSignalBallInfo(self._SignalId)
        end
    end
end

function XUiGridRaceFightCharacter:ShowGetSignalBallInfo(powerIndex)
    if not powerIndex or not self._SignalId then
        return
    end

    self.PanelBall.gameObject:SetActive(true)
    self:PlayAnimation("SlotDisable")
    
    local ballConfig = self._Control:GetRaceSignalBallById(powerIndex)
    self.RImgBall:SetRawImage(ballConfig.RollIcon)
    self:ShowEmoji(ballConfig.Emoji, ballConfig.EmojiTime)
    
    self._SignalId = false
    self:RemoveTimer()
    self._CountDownTimerId = XScheduleManager.ScheduleOnce(function()
        self:HideGetSignalBall()
    end, tonumber(self._Control:GetClientConfig("SignalBallShowTime")) or 500)
end

function XUiGridRaceFightCharacter:HideGetSignalBall()
    self.PanelBallShow.gameObject:SetActive(false)
    self.PanelBall.gameObject:SetActive(false)
end

function XUiGridRaceFightCharacter:Update(id, index)
    self._config = self._Control:GetRaceCharacterById(id)
    self.RImgHead:SetRawImage(self._config.Icon)

    self._index = index
    self.TxtNum.text = self._Control:GetRoadNameByIndex(index)

    self:SetSelected(self.Parent._SelectIndex == index)
    self._ultraSkConfig = self._Control:GetRaceCharacterSkillById(self._config.UltraSkill)
    self._normalSkConfig = self._Control:GetRaceCharacterSkillById(self._config.NormalSkill)
    self.TxtTalk.text = self._normalSkConfig.Name

    self:UpdatePower()
end

function XUiGridRaceFightCharacter:UpdatePower()
    local hasShow = self._Control:GetSkillShowList(self._index, self._ultraSkConfig)
    local singalBallCosts = self._ultraSkConfig.SignalBallCosts
    local cellIndex = 1
    for i = 1, 5 do
        local signalBallIndex = i == 5 and 0 or i
        local needCnt = singalBallCosts[signalBallIndex] or 0
        if needCnt > 0 then
            for j = 1, needCnt do
                local cell = self._Balls[cellIndex]
                if not cell then
                    local go = CS.UnityEngine.Object.Instantiate(self.GridSkillBall, self.GridSkillBall.transform.parent)
                    cell = XUiNode.New(go, self)
                    cell:Open()
                    
                    local iconPath = self._Control:GetRaceSignalBallIconById(signalBallIndex)
                    cell.Off:SetRawImage(iconPath)
                    cell.On:SetRawImage(iconPath)
                    self._Balls[cellIndex] = cell
                end
                cell.On.gameObject:SetActive(j <= (hasShow[signalBallIndex] or 0))
                cellIndex = cellIndex + 1
            end
        end
    end

    self:ShowGetSignalBallInfo(self._SignalId)
end

function XUiGridRaceFightCharacter:SetSelected(isSelected)
    self.GridCharacter:SetButtonState(isSelected and CS.UiButtonState.Select or CS.UiButtonState.Normal)
    self:PlayAnimation(isSelected and "Expand" or "Storage")
end

function XUiGridRaceFightCharacter:OnBtnClick()
    self.Parent:OnBtnHeadClick(self._index)
end

function XUiGridRaceFightCharacter:_RegisterButtonClicks()
    self.GridCharacter.CallBack = Handler(self, self.OnBtnClick)
end

function XUiGridRaceFightCharacter:OnDestroy()
    self:RemoveTimer()
    self:RemoveTalkTimer()
    self:RemoveEmojiTimer()
end

function XUiGridRaceFightCharacter:RemoveTalkTimer()
    if not self._TalkTimerId then return end
    XScheduleManager.UnSchedule(self._TalkTimerId)
    self._TalkTimerId = nil
end

function XUiGridRaceFightCharacter:RemoveTimer()
    if not self._CountDownTimerId then return end
    XScheduleManager.UnSchedule(self._CountDownTimerId)
    self._CountDownTimerId = nil
end

function XUiGridRaceFightCharacter:RemoveEmojiTimer()
    if not self._EmojiTimerId then return end
    XScheduleManager.UnSchedule(self._EmojiTimerId)
    self._EmojiTimerId = nil
end

return XUiGridRaceFightCharacter
