---@class XUiCloudGamingPopupMain : XLuaUi
---@field _Control XCloudGameControl
local XUiCloudGamingPopupMain = XLuaUiManager.Register(XLuaUi, "UiCloudGamingPopupMain")

function XUiCloudGamingPopupMain:OnAwake()
    self._GridRewards = {}
    self:BindExitBtns(self.BtnTanchuangCloseBig)
    self.Grid256New.gameObject:SetActiveEx(false)
    XUiHelper.RegisterHelpButton(self.BtnHelp, "CloudGameHelp")
    XUiHelper.RegisterClickEvent(self, self.BtnBuy, self.OnClickBuy)
    self:Update()
end

function XUiCloudGamingPopupMain:OnStart()

end

function XUiCloudGamingPopupMain:OnEnable()
    self.ImgAndroidQRcode.gameObject:SetActiveEx(false)
    self.ImgIosQRcode.gameObject:SetActiveEx(false)
end

function XUiCloudGamingPopupMain:OnDisable()
end

function XUiCloudGamingPopupMain:Update()
    local uiData = self._Control:GetUiData()
    self.TxtTitle.text = uiData.Title1
    self.TxtDetail.text = uiData.Text1
    self.TxtTitle2.text = uiData.Text2
    self.TxtDetail2.text = XUiHelper.ReplaceTextNewLine(uiData.Text3)
    local rewards = uiData.Reward
    XTool.UpdateDynamicGridCommon(self._GridRewards, rewards, self.Grid256New)
    for i = 1, #self._GridRewards do
        ---@type XUiGridCommon
        local grid = self._GridRewards[i]
        grid:SetBtnNotClick(true)
    end

    if XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Default then
        -- 移动端
        if CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.IPhonePlayer then
            -- ios，显示ios的
            self.BtnAndroidDownload.gameObject:SetActiveEx(false)
            self.BtnIosDownload.gameObject:SetActiveEx(true)
            XUiHelper.RegisterClickEvent(self, self.BtnIosDownload, self.OnIosDownloadClick)

        elseif CS.UnityEngine.Application.platform == CS.UnityEngine.RuntimePlatform.Android then
            -- 安卓，显示安卓的
            self.BtnAndroidDownload.gameObject:SetActiveEx(true)
            self.BtnIosDownload.gameObject:SetActiveEx(false)
            XUiHelper.RegisterClickEvent(self, self.BtnAndroidDownload, self.OnAndroidDownloadClick)
            
            -- 内网测试环境，既不是ios，也不是安卓，当成安卓
        else
            self.BtnAndroidDownload.gameObject:SetActiveEx(true)
            self.BtnIosDownload.gameObject:SetActiveEx(false)
            XUiHelper.RegisterClickEvent(self, self.BtnAndroidDownload, self.OnAndroidDownloadClick)
        end

    elseif XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.CloudGame then
        -- 云游戏，不显示按钮
        self.BtnAndroidDownload.gameObject:SetActiveEx(false)
        self.BtnIosDownload.gameObject:SetActiveEx(false)

    elseif XDataCenter.UiPcManager.GetUiPcMode() == XDataCenter.UiPcManager.XUiPcMode.Pc then
        --pc，鼠标移动过去之后，出现二维码
        self.BtnAndroidDownload.gameObject:SetActiveEx(true)
        self.BtnIosDownload.gameObject:SetActiveEx(true)

        local eventListenerAndroid = self.BtnAndroidDownload.gameObject:GetComponent("XUguiEventListener")
        if eventListenerAndroid then
            eventListenerAndroid.OnEnter = function()
                self.ImgAndroidQRcode.gameObject:SetActiveEx(true)
            end
            eventListenerAndroid.OnExit = function()
                self.ImgAndroidQRcode.gameObject:SetActiveEx(false)
            end
        end

        local eventListenerIos = self.BtnIosDownload.gameObject:GetComponent("XUguiEventListener")
        if eventListenerIos then
            eventListenerIos.OnEnter = function()
                self.ImgIosQRcode.gameObject:SetActiveEx(true)
            end
            eventListenerIos.OnExit = function()
                self.ImgIosQRcode.gameObject:SetActiveEx(false)
            end
        end
    end
end

function XUiCloudGamingPopupMain:OnIosDownloadClick()
    XMVCA.XUrl:SkipByUrlId(XMVCA.XUrl.UrlId.CloudGameIos)
end

function XUiCloudGamingPopupMain:OnAndroidDownloadClick()
    XMVCA.XUrl:SkipByUrlId(XMVCA.XUrl.UrlId.CloudGameAndroid)
end

function XUiCloudGamingPopupMain:OnClickBuy()
    XLuaUiManager.Open("UiPassport", {
        OpenLastPassport = true
    })
end

return XUiCloudGamingPopupMain