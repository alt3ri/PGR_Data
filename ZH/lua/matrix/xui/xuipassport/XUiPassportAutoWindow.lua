local CSXTextManagerGetText = CS.XTextManager.GetText

---@class XUiPassportAutoWindow:XLuaUi
---@field _Control XPassportControl
local XUiPassportAutoWindow = XLuaUiManager.Register(XLuaUi, "UiPassportAutoWindow")

local BPPhase = {
    Open    = 1, -- BP开启
    Sprint  = 2, -- BP冲刺
    NearEnd = 3, -- BP即将结束
}

function XUiPassportAutoWindow:OnAwake()
    self:RegisterButtonEvent()
end

function XUiPassportAutoWindow:OnStart(skipId)
    local cfg = XFunctionConfig.GetSkipFuncCfg(skipId)
    self._SprintTime  = cfg.CustomParams[1]
    self._NearEndTime = cfg.CustomParams[2]
    self:Refresh()
end

function XUiPassportAutoWindow:OnEnable()
end

function XUiPassportAutoWindow:OnDisable()
end

function XUiPassportAutoWindow:OnDestroy()
    XDataCenter.AutoWindowManager.NextAutoWindow()
end

function XUiPassportAutoWindow:RegisterButtonEvent()
    self.BtnBack:AddEventListener(handler(self, self.Close))
    self.BtnBigSkin:AddEventListener(handler(self, self.OnBtnBigSkinClick))
end

-----------------阶段判断 start--------------------------

function XUiPassportAutoWindow:IsBPSprint()
    local now = XTime.GetServerNowTimestamp()
    return now >= self._SprintTime and now <= self._NearEndTime
end

function XUiPassportAutoWindow:IsBPNearEnd()
    local now = XTime.GetServerNowTimestamp()
    return now > self._NearEndTime
end

function XUiPassportAutoWindow:GetBPPhase()
    if self:IsBPNearEnd() then
        return BPPhase.NearEnd
    elseif self:IsBPSprint() then
        return BPPhase.Sprint
    end
    return BPPhase.Open
end

-----------------阶段判断 end----------------------------

function XUiPassportAutoWindow:Refresh()
    local phase = self:GetBPPhase()
    self:UpdateTitle(phase)
    self:UpdateSubtitle(phase)
    self:UpdateIntro()
    self:UpdateCoating()
    self:UpdateEndTime()
end

function XUiPassportAutoWindow:UpdateTitle(phase)
    if phase == BPPhase.Sprint then
        self.TxtTitle.text = CSXTextManagerGetText("PassportAutoWindowTitleSprint")
    elseif phase == BPPhase.NearEnd then
        self.TxtTitle.text = CSXTextManagerGetText("PassportAutoWindowTitleNearEnd")
    else
        self.TxtTitle.text = CSXTextManagerGetText("PassportAutoWindowTitleOpen")
    end
end

function XUiPassportAutoWindow:UpdateSubtitle(phase)
    local isDoubleExp = phase == BPPhase.Sprint or phase == BPPhase.NearEnd
    self.RImgUp.gameObject:SetActiveEx(isDoubleExp)
    if isDoubleExp then
        self.TxtSubtitle.text = CSXTextManagerGetText("PassportAutoWindowSubtitleDoubleExp")
    else
        self.TxtSubtitle.text = CSXTextManagerGetText("PassportAutoWindowSubtitleOpen")
    end
end

function XUiPassportAutoWindow:UpdateIntro()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    local highPassportId = typeInfoIdList[3]
    local buyDesc = self._Control:GetPassportTypeInfoBuyDescBase(highPassportId)
    self.TxtIntro.text = string.gsub(buyDesc, "\\n", "\n")
end

function XUiPassportAutoWindow:UpdateCoating()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    local hasCoating = false
    for _, typeInfoId in ipairs(typeInfoIdList) do
        local name = self._Control:GetPassportBuyFashionName(typeInfoId)
        if name and name ~= "" then
            self.TxtCoatingName.text = name
            hasCoating = true
            break
        end
    end
    if not hasCoating then
        self.TxtCoatingName.text = ""
    end
    self.TxtCoatingBuy.text = CSXTextManagerGetText("PassportFashionBuyBtnText")
    self.PassportCoating.gameObject:SetActiveEx(hasCoating)
end

function XUiPassportAutoWindow:UpdateEndTime()
    local timeId = self._Control:GetPassportActivityTimeId()
    local startTime, endTime = XFunctionManager.GetTimeByTimeId(timeId)
    local startTimeStr = os.date("%m/%d", startTime)
    local endTimeStr = os.date("%m/%d", endTime)
    self.TxtTime.text = startTimeStr .. "~" .. endTimeStr
end

function XUiPassportAutoWindow:OnBtnBigSkinClick()
    if self.FullScreenBackground then
        self.FullScreenBackground.gameObject:SetActiveEx(false)
    end

    if self.SafeAreaContentPane then
        self.SafeAreaContentPane.gameObject:SetActiveEx(false)
    end

    XLuaUiManager.Open(
        "UiPassport",
        {
            OpenPassportCard = true,
            OnClose = function()
                XLuaUiManager.SetMask(true)
                self._CloseSchedule = XScheduleManager.ScheduleOnce(function()
                    XScheduleManager.UnSchedule(self._CloseSchedule)
                    XLuaUiManager.SetMask(false)
                    self:Close()
                end, 500)
            end
        })
end
