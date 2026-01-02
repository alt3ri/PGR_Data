---@class XUiTheatre5PopupNewSeason : XLuaUi
---@field _Control XTheatre5Control
local XUiTheatre5PopupNewSeason = XLuaUiManager.Register(XLuaUi, "UiTheatre5PopupNewSeason")
local Day = 3600 * 24
local TipsType = {
    WillStart = 1,
    InTime = 2,
    End = 3,
}


function XUiTheatre5PopupNewSeason:OnAwake()
    self:BindExitBtns(self.BtnBack)
end

function XUiTheatre5PopupNewSeason:OnEnable()
    self:Update()
end

function XUiTheatre5PopupNewSeason:Update()
    self.TxtSeasonTime.text = self._Control:GetActivityTime()
    self.TxtName.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpTitle", 1)
    self.TxtSeasonNum.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpTitle", 2)
    self.TxtName1.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent1", 1)
    self.TxtTips1.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent1", 2)
    self.TxtName2.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent2", 1)
    self.TxtTips2.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent2", 2)
    self.TxtName3.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent3", 1)
    self.TxtTips3.text = XMVCA.XTheatre5:GetClientConfig("PvpPopUpContent3", 2)
    
    local nameplateIcon = XMVCA.XTheatre5:GetClientConfig("PvpPopUpImgNameplate", 1)

    if not string.IsNilOrEmpty(nameplateIcon) then
        self.ImgNameplate:SetSprite(nameplateIcon)
    end
    self.RImgRune:SetRawImage(XMVCA.XTheatre5:GetClientConfig("PvpPopUpImgRune", 1))

    if self.TxtTimeDesc then
        self.TxtTimeDesc.gameObject:SetActiveEx(true)
        
        local pvpTimeId = XMVCA.XTheatre5:GetPVPActivityTimeId()
        local startTime = XFunctionManager.GetStartTimeByTimeId(pvpTimeId)
        local endTime = XFunctionManager.GetEndTimeByTimeId(pvpTimeId)
        local now = XTime.GetServerNowTimestamp()
        
        local leftTimeStr = ''

        if now < startTime then
            local startLeftTime = startTime - now
            leftTimeStr = math.ceil(startLeftTime / Day)
            leftTimeStr = XUiHelper.FormatText(self._Control:GetClientConfigPVPReasonTips(TipsType.WillStart), leftTimeStr)
        elseif now < endTime then
            leftTimeStr = self._Control:GetClientConfigPVPReasonTips(TipsType.InTime)
        else
            leftTimeStr = self._Control:GetClientConfigPVPReasonTips(TipsType.End) or ''
        end

        self.TxtTimeDesc.text = leftTimeStr
    end
end

return XUiTheatre5PopupNewSeason