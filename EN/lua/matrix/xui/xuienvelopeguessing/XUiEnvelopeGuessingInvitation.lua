local XUiPanelEnvelopeGuessingClueInvitation = require("XUi/XUiEnvelopeGuessing/XUiPanelEnvelopeGuessingClueInvitation")
local XUiPanelEnvelopeSpecifyInvitation = require("XUi/XUiEnvelopeGuessing/XUiPanelEnvelopeSpecifyInvitation")
---@class XUiEnvelopeGuessingInvitation : XLuaUi
---@field private _Control XEnvelopeGuessingControl
local XUiEnvelopeGuessingInvitation = XLuaUiManager.Register(XLuaUi, "UiEnvelopeGuessingInvitation")

--region 埋点
-- 拆包类型
XUiEnvelopeGuessingInvitation.ReportOpenType = {
    Specify = 1, -- 定向
    Clue = 2, -- 普通
}
--endregion

function XUiEnvelopeGuessingInvitation:OnStart()
    self:BindExitBtns(self.BtnBack, self.BtnMainUi)
    self:BindHelpBtn(self.BtnHelp, "EnvelopeGuessingHelp")
    self.BtnRandomSelect:AddEventListener(handler(self, self.OnBtnRandomSelectClick))

    self._FastOpenRadioMemoryKey = "XUiEnvelopeGuessingInvitation.FastOpenRadioMemoryKey_" .. XPlayer.Id
    self._FastOpenRadioSelected = XSaveTool.GetData(self._FastOpenRadioMemoryKey) == "1"
    self._FastOpenRadios = {}

    local setupConfirmButton = handler(self, self._SetupConfirmButton)
    local close = handler(self, self.Close)

    self._Pages = {
        XUiPanelEnvelopeGuessingClueInvitation.New(self.PanelClueInvitation, self, setupConfirmButton, close),
        XUiPanelEnvelopeSpecifyInvitation.New(self.PanelSpecifyInvitation, self, setupConfirmButton, close)
    }

    self.BtnTabGroup:Init({ self.BtnClueInvitation, self.BtnSpecifyInvitation }, handler(self, self._SwitchPages))
    self.BtnTabGroup:SelectIndex(self._CurrentPageIndex or 1)

    local activityConf = XMVCA.XEnvelopeGuessing:GetActivityConfig()
    XUiHelper.XUiPanelAsset(self, self.PanelAsset1, activityConf.TicketItemId, activityConf.SelectChoiceItemId)

    -- 设置自动关闭
    self:SetAutoCloseInfo(XMVCA.XEnvelopeGuessing:GetActivityEndTime(), function(isClose)
        if isClose then
            self._Control:HandleActivityEnd()
        end
    end)
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

    -- 切页重置随机标记
    self._RandomSelectTriggered = false
    self.BtnRandomSelect.gameObject:SetActive(not not self._CurrentPage.RandomSelect)
end

function XUiEnvelopeGuessingInvitation:OnReleaseInst()
    return self._CurrentPageIndex or 1
end

function XUiEnvelopeGuessingInvitation:OnResume(pageIndex)
    self._CurrentPageIndex = pageIndex
end

-- 返回一个Refresh函数，在OnEnable时需要调用它以刷新按钮状态
function XUiEnvelopeGuessingInvitation:_SetupConfirmButton(confirmPanel, clickHandler, buttonItemCheckList)
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

        ui.UiEnvelopeGuessingBtnRadio.gameObject:SetActive(self._Control:CheckFastOpenUnlocked())

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

            ui.BtnConfirm:SetNameByGroup(itemCheck.CountTextGroupId, CS.XTextManager.GetText(textKey))
        end

        -- todo: 这个按钮尚未准备Disable状态的版本
        -- if enable then
        --     ui.BtnConfirm:SetButtonState(CS.UiButtonState.Normal)
        -- else
        --     ui.BtnConfirm:SetButtonState(CS.UiButtonState.Disable)
        -- end
    end

    ui.UiEnvelopeGuessingBtnRadio:AddEventListener(function()
        self._FastOpenRadioSelected = not self._FastOpenRadioSelected
        local data = "0"
        if self._FastOpenRadioSelected then
            data = "1"
        end
        XSaveTool.SaveData(self._FastOpenRadioMemoryKey, data)
        refreshRadio()
    end)

    ui.BtnConfirm:AddEventListener(function()
        clickHandler(self._FastOpenRadioSelected and self._Control:CheckFastOpenUnlocked())
    end)

    refreshRadio()
    return refreshRadio
end

function XUiEnvelopeGuessingInvitation:OnBtnRandomSelectClick()
    self._RandomSelectTriggered = true
    self._CurrentPage:RandomSelect()
end

--region 埋点
-- 手动改选后随机结果已被干涉，清除标记
function XUiEnvelopeGuessingInvitation:ClearRandomSelectFlag()
    self._RandomSelectTriggered = false
end

---@param openType number 拆包类型：1定向 2普通
---@param maxTiltAngle number 陀螺仪最大倾斜角度（度），定向恒为0
function XUiEnvelopeGuessingInvitation:ReportOpenCard(openType, characterId, fastOpen, maxTiltAngle)
    local dict = {}
    dict["role_id"] = XPlayer.Id
    dict["i_character_id"] = characterId or 0
    dict["i_open_type"] = openType
    -- 仅普通拆包有随机选择入口
    dict["i_is_random_select"] = (openType == self.ReportOpenType.Clue and self._RandomSelectTriggered) and 1 or 0
    dict["i_is_auto_play"] = fastOpen and 1 or 0
    dict["i_max_tilt_angle"] = math.floor((maxTiltAngle or 0) * 100) -- 乘100保留两位小数精度

    if XMain.IsWindowsEditor then
        CS.XRecord.RecordTest(dict, "1000049", "EnvelopeGuessingOpenCard")
    else
        CS.XRecord.Record(dict, "1000049", "EnvelopeGuessingOpenCard")
    end
end
--endregion

return XUiEnvelopeGuessingInvitation
