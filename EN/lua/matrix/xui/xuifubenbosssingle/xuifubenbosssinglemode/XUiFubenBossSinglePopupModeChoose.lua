local XUiPanelFubenBossSingleChallengeModePreview = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiPanelFubenBossSingleChallengeModePreview")

local XUiFubenBossSinglePopupModeChooseIndex = require(
    "XUi/XUiFubenBossSingle/XUiFubenBossSingleMode/XUiFubenBossSinglePopupModeChooseIndex")

local UiFubenBossSinglePopupModeChoose = XLuaUiManager.Register(
    XLuaUi,
    "UiFubenBossSinglePopupModeChoose")

function UiFubenBossSinglePopupModeChoose:OnStart(
    buffGroupId,
    buffGroups,
    feature,
    onStartCallback)

    self.BtnTanchuangClose.CallBack = handler(self, self._OnBtnTanchuangCloseClick)
    self.BtnGo.CallBack = handler(self, self._OnBtnGoClick)
    self._BuffGroupId = buffGroupId
    self._OnStartCallback = onStartCallback
    self:_InitView(feature, buffGroups)
end

function UiFubenBossSinglePopupModeChoose:_InitView(feature, buffGroups)
    self._Preview = XUiPanelFubenBossSingleChallengeModePreview.New(
        self.PanelSelectedMode, self)

    self.TxtTitle.text = feature:GetName()
    self.TxtDesc.text = feature:GetDesc()
    self.PanelMode.gameObject:SetActiveEx(false)
    self._IndexSelectors = {}

    local historyBuffGroup = feature:GetHistoryBuffGroup()

    for _, buffGroup in pairs(buffGroups) do
        local go = XUiHelper.Instantiate(
            self.PanelMode.gameObject,
            self.PanelModeContent)

        local choice = 0
        if historyBuffGroup and historyBuffGroup.BuffChoices then
            choice = historyBuffGroup.BuffChoices[buffGroup.Index] or 0
        end

        self._IndexSelectors[buffGroup.Index] =
            XUiFubenBossSinglePopupModeChooseIndex.New(
                go,
                self,
                buffGroup,
                choice,
                function() self:_RefreshPreview() end)

        go:SetActiveEx(true)
    end

    self:_RefreshPreview()
end

function UiFubenBossSinglePopupModeChoose:_RefreshPreview()
    self._Preview:SetData(self:GetBossSingleChallengeBuffGroup())
end

-- 返回 XBossSingleDefine @ class BossSingleChallengeBuffGroup
function UiFubenBossSinglePopupModeChoose:GetBossSingleChallengeBuffGroup()
    local buffChoices = {}

    for index, selector in pairs(self._IndexSelectors) do
        local buffChoice, _ = selector:GetSelectedBuffIndexAndBuffId()
        buffChoices[index] = buffChoice
    end

    XMessagePack.MarkAsTable(buffChoices)

    return { BuffGroupId = self._BuffGroupId, BuffChoices = buffChoices }
end

function UiFubenBossSinglePopupModeChoose:_OnBtnTanchuangCloseClick()
    self:Close()
end

function UiFubenBossSinglePopupModeChoose:_OnBtnGoClick()
    local buffSelection = self:GetBossSingleChallengeBuffGroup()
    self:Close()
    self._OnStartCallback(buffSelection)
end

return UiFubenBossSinglePopupModeChoose
