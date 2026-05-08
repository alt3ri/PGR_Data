local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
local XUiPassportCardPanel = require("XUi/XUiPassport/Card/XUiPassportCardPanel")
local XUiPassport3D = require("XUi/XUiPassport/XUiPassport3D")

---@field _Control XPassportControl
---@class UiPassportCard:XLuaUi
local XUiPassportCard = XLuaUiManager.Register(XLuaUi, "UiPassportCard")

local CSXTextManagerGetText = CS.XTextManager.GetText

function XUiPassportCard:OnAwake()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.HongKa)
    self:RegisterButtonEvent()
    self:InitTextBuyCaption()
end

function XUiPassportCard:OnStart(closeCb, uiPassport)
    self.UiPassport = uiPassport
    self.CloseCb = closeCb

    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    local middlePassportId = typeInfoIdList[2]
    local highPassportId = typeInfoIdList[3]

    self.MiddlePanel = XUiPassportCardPanel.New(self.PanelCardMiddle, self, middlePassportId)
    self.HighPanel = XUiPassportCardPanel.New(self.PanelCardHigh, self, highPassportId)

    self:UpdateCoatingName()
end

function XUiPassportCard:OnEnable()
    CS.XGraphicManager.UseUiLightDir = true
    if self.UiPassport then self.UiPassport:OnShowCard() end
    self:RefreshAllPanels()
end

function XUiPassportCard:OnDisable()
    CS.XGraphicManager.UseUiLightDir = false
    if self.UiPassport then self.UiPassport:OnHideCard() end
end

function XUiPassportCard:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiPassportCard:InitTextBuyCaption()
    local time = self._Control:GetPassportBuyPassPortEarlyEndTime()
    local timeDesc = time > 0 and XUiHelper.GetTimeDesc(time, 2) or 0 .. CSXTextManagerGetText("Second")
    timeDesc = string.gsub(timeDesc, " ", "")
    local buyCaptionDesc = CSXTextManagerGetText("PassportBuyCaptionDesc", timeDesc)
    self.TextBuyTime.text = buyCaptionDesc
end

function XUiPassportCard:RefreshAllPanels()
    self.MiddlePanel:Refresh()
    self.HighPanel:Refresh()
end

function XUiPassportCard:UpdateCoatingName()
    if not self.TxtCoatingName then
        return
    end
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    for _, typeInfoId in ipairs(typeInfoIdList) do
        local name = self._Control:GetPassportBuyFashionName(typeInfoId)
        if name and name ~= "" then
            self.TxtCoatingName.text = name
            return
        end
    end
    self.TxtCoatingName.text = ""
end

function XUiPassportCard:OnBtnOpenClick()
    local typeInfoIdList = self._Control:GetPassportActivityIdToTypeInfoIdList()
    for _, typeInfoId in ipairs(typeInfoIdList) do
        local fashionId = self._Control:GetPassportBuyFashionShowFashionId(typeInfoId)
        if XTool.IsNumberValid(fashionId) then
            local fashionType = self._Control:GetPassportBuyFashionShowType(typeInfoId)
            local buyData = self._Control:GetPassportFashionBuyData(typeInfoId)
            XLuaUiManager.Open("UiPassportFashionDetail", fashionId, fashionType, buyData)
            return
        end
    end
end

function XUiPassportCard:RegisterButtonEvent()
    self.BtnClose:AddEventListener(handler(self, self.Close))
    self.BtnOpen:AddEventListener(handler(self, self.OnBtnOpenClick))
end
