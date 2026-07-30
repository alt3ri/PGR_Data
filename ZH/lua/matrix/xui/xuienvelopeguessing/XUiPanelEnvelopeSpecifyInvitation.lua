local XUiEnvelopeGuessingOpenPackage =
    require("XUi/XUiEnvelopeGuessing/XUiEnvelopeGuessingOpenPackage")

local XDynamicTableNormal =
    require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiGridEnvelopeSpecifyInvitation =
    XClass(XUiNode,  "XUiGridEnvelopeSpecifyInvitation")

function XUiGridEnvelopeSpecifyInvitation:SetData(data, onClicked, selectedRole)
    self._Data = data
    self.BtnRole.CallBack = function() onClicked(data) end
    self:SetSelected(selectedRole)
    self.UnLockImgHeadImg:SetRawImage(data.HeadIcon)
end

function XUiGridEnvelopeSpecifyInvitation:SetSelected(selected)
    self.ImgRoleSelect.gameObject:SetActiveEx(selected.Id == self._Data.Id)
end

local XUiPanelEnvelopeSpecifyInvitation =
    XClass(XUiNode, "XUiPanelEnvelopeSpecifyInvitation")

function XUiPanelEnvelopeSpecifyInvitation:OnStart(
    setupConfirmButton,
    closeParent)

    self._RefreshConfirmButton = setupConfirmButton(
        self.PanelBtnConfirm,
        handler(self, self._OnConfirmClicked),
        {
            {
                CheckFunction = handler(self._Control, self._Control.CheckTicketItemEnough),
                CountTextGroupId = 2
            },
            {
                CheckFunction = handler(self._Control, self._Control.CheckChoiceTicketItemEnough),
                CountTextGroupId = 1                
            }
        })

    self._CloseParent = closeParent

    self._DynTable = XDynamicTableNormal.New(self.HeadScrollView)
    self._DynTable:SetProxy(XUiGridEnvelopeSpecifyInvitation, self)
    self._DynTable:SetDelegate(self)

    self._Card = {}
    XTool.InitUiObjectByInstance(
        self.UiEnvelopeGuessingSpecifyCard,
        self._Card)
end

function XUiPanelEnvelopeSpecifyInvitation:OnEnable()
    self._Characters = XTool.FilterList(
        self._Control:GetAllCharacterConfigs(),
        function(conf) return not self._Control:IsCharacterOpened(conf.Id) end)

    if XTool.IsTableEmpty(self._Characters) then
        self:_CloseParent()
        return
    end

    if self._SelectedRole then
        if self._Control:IsCharacterOpened(self._SelectedRole.Id) then
            self._SelectedRole = nil
        end
    end

    self._SelectedRole = self._SelectedRole or self._Characters[1]

    self._DynTable:SetDataSource(self._Characters)
    self._DynTable:ReloadDataASync()
    self:_RefreshCard()
    self._RefreshConfirmButton()
end

function XUiPanelEnvelopeSpecifyInvitation:_SelectRole(data)
    self._SelectedRole = data

    for _, grid in pairs(self._DynTable:GetGrids()) do
        grid:SetSelected(self._SelectedRole)
    end

    self:_RefreshCard()
end

function XUiPanelEnvelopeSpecifyInvitation:_RefreshCard()
    local data = self._SelectedRole

    self._Card.TxtSpecifyCardTip.text = CS.XTextManager.GetText(
        "EnvelopeGuessingCharacterCardSpecifyCardTip",
        data.CharacterName)

    self._Card.RImgPackagHead:SetRawImage(data.HeadIcon)
end

function XUiPanelEnvelopeSpecifyInvitation:OnDynamicTableEvent(evt, index, grid)
    if evt == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:SetData(
            self._Characters[index],
            handler(self, self._SelectRole),
            self._SelectedRole)
    end
end

function XUiPanelEnvelopeSpecifyInvitation:_OnConfirmClicked(fastOpen)
    if not self._Control:CheckChoiceTicketItemEnough() then
        XUiManager.TipText("UiEnvelopeGuessingInvitationChoiceTicketNotEnough")
        return
    end

    if not self._Control:CheckTicketItemEnough() then
        XUiManager.TipText("UiEnvelopeGuessingInvitationTicketNotEnough")
        return
    end

    self._Control:EnvelopeSelectOpenRequest(self._SelectedRole.Id, function(data)
        if data.Code ~= XCode.Success then
            XUiManager.TipCode(data.Code)
            return
        end

        XLuaUiManager.Open(
            "UiEnvelopeGuessingOpenPackage",
            XUiEnvelopeGuessingOpenPackage.OpenType.Specify,
            self._SelectedRole,
            fastOpen)
    end)
end

return XUiPanelEnvelopeSpecifyInvitation
