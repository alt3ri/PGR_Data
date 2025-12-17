---@class XUiBountyChallengeMainGrid : XUiNode
---@field _Control XBountyChallengeControl
local XUiBountyChallengeMainGrid = XClass(XUiNode, "XUiBountyChallengeMainGrid")

function XUiBountyChallengeMainGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
    self._DifficultyImage = { self.Image }
    self._Timer = false
end

function XUiBountyChallengeMainGrid:OnEnable()
    self:CountDown()
end

function XUiBountyChallengeMainGrid:OnDisable()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
        self._Timer = false
    end
end

function XUiBountyChallengeMainGrid:CountDown()
    if not self._Data then
        return
    end
    if not self._Data.IsLock4Time then
        return
    end
    local timerId = self._Data.TimeId
    if XFunctionManager.CheckInTimeByTimeId(timerId) then
        return
    end

    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            if XFunctionManager.CheckInTimeByTimeId(timerId) then
                self._Data.IsLock4Time = false
                self:Update(self._Data)
            else
                self:UpdateTxtLock()
            end

        end, XScheduleManager.SECOND)
    end
    self:UpdateTxtLock()
end

function XUiBountyChallengeMainGrid:UpdateTxtLock()
    local timerId = self._Data.TimeId
    local startTime = XFunctionManager.GetStartTimeByTimeId(timerId)
    local remainTime = startTime - XTime.GetServerNowTimestamp()
    if remainTime <= 0 then
        remainTime = 0
    end
    local str = XUiHelper.GetTime(remainTime, XUiHelper.TimeFormatType.DAY_HOUR_MINUTE)
    if self.TxtLock then
        self.TxtLock.text = XUiHelper.GetText("ReformBaseStageUnlockText", str)
    end
end

---@param data XUiBountyChallengeMainGridData
function XUiBountyChallengeMainGrid:Update(data)
    self._Data = data
    self.TxtName.text = data.Name
    self.Red.gameObject:SetActive(data.Red)
    self.TxtNum.text = XUiHelper.GetText("BountyChallengeProgress", data.Progress, data.ProgressMax)

    -- 难度条
    local difficulty = data.DifficultyLevel
    for i = 1, difficulty do
        local image = self._DifficultyImage[i]
        if not image then
            image = XUiHelper.Instantiate(self.Image, self.Image.transform.parent)
            self._DifficultyImage[i] = image
        end
        image.gameObject:SetActive(true)
    end
    for i = difficulty + 1, #self._DifficultyImage do
        local image = self._DifficultyImage[i]
        if image then
            image.gameObject:SetActive(false)
        end
    end

    if data.IsLock4Time then
        if self.PanelLock then
            self.PanelLock.gameObject:SetActive(true)
        end
        if self.ImgMask then
            self.ImgMask:SetRawImage(data.Icon)
        end
        self:CountDown()
        self.RImgBgNormal.gameObject:SetActive(true)
        self.RImgBgComplete.gameObject:SetActive(false)
        self.PanelNdNormal.gameObject:SetActive(false)
        self.PanelNdComplete.gameObject:SetActive(false)
        self.RImgBgNormal:SetRawImage(data.Icon)
        self.RImgBgComplete:SetRawImage(data.Icon)
        self.TxtNum.gameObject:SetActive(false)
    else
        if self.PanelLock then
            self.PanelLock.gameObject:SetActive(false)
        end
        self.TxtNum.gameObject:SetActive(true)
        if self.TagComplete then
            if data.IsClear then
                self.TagComplete.gameObject:SetActive(true)
                self.RImgBgComplete.color = XUiHelper.Hexcolor2Color("B2B2B2FF")
            else
                self.TagComplete.gameObject:SetActive(false)
            end
        end

        if data.IsMaxLevel then
            self.Difficulty2.text = data.DifficultyName
            self.RImgBgNormal.gameObject:SetActive(false)
            self.RImgBgComplete.gameObject:SetActive(true)
            self.PanelNdNormal.gameObject:SetActive(false)
            self.PanelNdComplete.gameObject:SetActive(true)
            self.RImgBgComplete:SetRawImage(data.Icon)
        else
            self.Difficulty.text = data.DifficultyName
            self.RImgBgNormal.gameObject:SetActive(true)
            self.RImgBgComplete.gameObject:SetActive(false)
            self.PanelNdNormal.gameObject:SetActive(true)
            self.PanelNdComplete.gameObject:SetActive(false)
            self.RImgBgNormal:SetRawImage(data.Icon)
        end
    end
end

function XUiBountyChallengeMainGrid:OnClick()
    if self._Data.IsLock4Time then
        return
    end
    XSaveTool.SaveData("BountyChallengeNewBoss" .. XPlayer.Id .. self._Data.BossId, true)
    XLuaUiManager.Open("UiBountyChallengeChapterDetail", self._Data)
end

return XUiBountyChallengeMainGrid