---@class XUiBountyChallengeMainGrid : XUiNode
---@field _Control XBountyChallengeControl
local XUiBountyChallengeMainGrid = XClass(XUiNode, "XUiBountyChallengeMainGrid")

function XUiBountyChallengeMainGrid:OnStart()
    XUiHelper.RegisterClickEvent(self, self.Button, self.OnClick)
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

    if data.IsLock4Time then
        if self.PanelLock then
            self.PanelLock.gameObject:SetActive(true)
        end
        -- 4.1 图片直接做在UI上
        --[[
        if self.ImgMask then
            self.ImgMask:SetRawImage(data.Icon)
        end
        --]]
        self:CountDown()
        self.RImgBgNormal.gameObject:SetActive(true)
        self.RImgBgComplete.gameObject:SetActive(false)
        -- 4.1 图片直接做在UI上
        --self.RImgBgNormal:SetRawImage(data.Icon)
        --self.RImgBgComplete:SetRawImage(data.Icon)
        self.TxtNum.gameObject:SetActive(false)
    else
        if self.PanelLock then
            self.PanelLock.gameObject:SetActive(false)
        end
        self.TxtNum.gameObject:SetActive(true)
        self.RImgBgNormal.gameObject:SetActiveEx(true)
        if self.TagComplete then
            if data.IsClear then
                self.TagComplete.gameObject:SetActiveEx(true)
                -- 4.1 图片直接做在UI上
                --self.RImgBgComplete:SetRawImage(data.Icon)
                --self.RImgBgComplete.color = XUiHelper.Hexcolor2Color("B2B2B2FF")
                --self.RImgBgNormal.gameObject:SetActiveEx(false)
            else
                self.TagComplete.gameObject:SetActiveEx(false)
            end
        end
        
        local format = self._Control:GetConfigStr('EntranceDifficultyLabel')
        
        local str = data.DifficultyName

        if not string.IsNilOrEmpty(format) then
            str = XUiHelper.FormatText(format, str)
        end
        
        self.Button:SetNameByGroup(0, str)
        -- 4.1 图片直接做在UI上
        --self.RImgBgNormal:SetRawImage(data.Icon)
    end

    for i = 1, 10 do
        local ui = self['RawImgDif0' .. i]

        if ui then
            local isCurLevel = i == data.DifficultyLevel

            if data.IsLock4Time then
                isCurLevel = false
            end
            
            ui.gameObject:SetActiveEx(isCurLevel)
        else
            break
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