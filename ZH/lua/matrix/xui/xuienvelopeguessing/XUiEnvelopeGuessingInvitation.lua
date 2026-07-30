local XUiPanelEnvelopeGuessingClueInvitation =
    require("XUi/XUiEnvelopeGuessing/XUiPanelEnvelopeGuessingClueInvitation")

local XUiPanelEnvelopeSpecifyInvitation =
    require("XUi/XUiEnvelopeGuessing/XUiPanelEnvelopeSpecifyInvitation")

local XUiEnvelopeGuessingSubUi =
    require("XUi/XUiEnvelopeGuessing/XUiEnvelopeGuessingSubUi")

local XUiEnvelopeGuessingInvitation =
    XLuaUiManager.Register(XUiEnvelopeGuessingSubUi, "UiEnvelopeGuessingInvitation")

function XUiEnvelopeGuessingInvitation:OnStart()
    self._Agency = XMVCA.XEnvelopeGuessing

    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "EnvelopeGuessingHelp")

    function self.BtnRandomSelect.CallBack()
        self._CurrentPage:RandomSelect()
    end

    local activityConf = self._Agency:GetCurrentActivity()

    self._FastOpenRadioMemoryKey = "XUiEnvelopeGuessingInvitation.FastOpenRadioMemoryKey_" .. XPlayer.Id
    self._FastOpenRadioSelected = XSaveTool.GetData(self._FastOpenRadioMemoryKey) == "1"
    self._FastOpenRadios = {}

    local setupConfirmButton = handler(self, self._SetupConfirmButton)
    local close = handler(self, self.Close)

    self._Pages = {
        XUiPanelEnvelopeGuessingClueInvitation.New(
            self.PanelClueInvitation,
            self,
            setupConfirmButton,
            close),

        XUiPanelEnvelopeSpecifyInvitation.New(
            self.PanelSpecifyInvitation,
            self,
            setupConfirmButton,
            close)
    }

    self.BtnTabGroup:Init(
        {
            self.BtnClueInvitation,
            self.BtnSpecifyInvitation
        },
        handler(self, self._SwitchPages))

    self.BtnTabGroup:SelectIndex(self._CurrentPageIndex or 1)

    XUiHelper.XUiPanelAsset(
        self,
        self.PanelAsset1,
        activityConf.TicketItemId,
        activityConf.SelectChoiceItemId)
end

function XUiEnvelopeGuessingInvitation:_SwitchPages(index)
    for i, page in ipairs(self._Pages) do
        if i == index then
            page:Open()
            self._CurrentPage = page
            self._CurrentPageIndex = i
        else
            page:Close()
        end
    end

    self.BtnRandomSelect.gameObject:SetActive(
        not not self._CurrentPage.RandomSelect)
end

function XUiEnvelopeGuessingInvitation:OnReleaseInst()
    return self._CurrentPageIndex or 1
end

function XUiEnvelopeGuessingInvitation:OnResume(pageIndex)
    self._CurrentPageIndex = pageIndex
end

-- 返回一个Refresh函数，在OnEnable时需要调用它以刷新按钮状态
function XUiEnvelopeGuessingInvitation:_SetupConfirmButton(
    confirmPanel,
    clickHandler,
    buttonItemCheckList)

    local ui = {}
    XTool.InitUiObjectByInstance(confirmPanel, ui)
    table.insert(self._FastOpenRadios, ui.UiEnvelopeGuessingBtnRadio)

    local function refreshRadio()
        local state = CS.UiButtonState.Normal
        if self._FastOpenRadioSelected then
            state = CS.UiButtonState.Select
        end

        for _, radio in ipairs(self._FastOpenRadios) do
            radio:SetButtonState(state)
        end

        ui.UiEnvelopeGuessingBtnRadio.gameObject:SetActive(
            self._Control:CheckFastOpenUnlocked())

        local enable = true

        for _, itemCheck in pairs(buttonItemCheckList) do
            local check = itemCheck.CheckFunction()

            local textKey
            if check then
                textKey = "UiEnvelopeGuessingInvitationInviteButtonWhiteOne"
            else
                textKey = "UiEnvelopeGuessingInvitationInviteButtonRedOne"
                enable = false
            end

            ui.BtnConfirm:SetNameByGroup(
                itemCheck.CountTextGroupId,
                CS.XTextManager.GetText(textKey))
        end

        -- todo: 这个按钮尚未准备Disable状态的版本
        -- if enable then
        --     ui.BtnConfirm:SetButtonState(CS.UiButtonState.Normal)
        -- else
        --     ui.BtnConfirm:SetButtonState(CS.UiButtonState.Disable)
        -- end
    end
        
    function ui.UiEnvelopeGuessingBtnRadio.CallBack()
        self._FastOpenRadioSelected = not self._FastOpenRadioSelected
        local data = "0"
        if self._FastOpenRadioSelected then
            data = "1"
        end
        XSaveTool.SaveData(self._FastOpenRadioMemoryKey, data)
        refreshRadio()
    end

    function ui.BtnConfirm.CallBack()
        clickHandler(
            self._FastOpenRadioSelected
            and self._Control:CheckFastOpenUnlocked())
    end

    refreshRadio()
    return refreshRadio
end

return XUiEnvelopeGuessingInvitation
