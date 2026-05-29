local XUiFubenBossSinglePopupModeChooseIndex = XClass(
    XUiNode,
    "XUiFubenBossSinglePopupModeChooseIndex")

function XUiFubenBossSinglePopupModeChooseIndex:Ctor(
    _0,
    _1,
    buffGroup,
    currentChoice,
    onChangeCallback)

    self:_InitView(buffGroup, currentChoice)
    self._OnChangeCallback = onChangeCallback
end

function XUiFubenBossSinglePopupModeChooseIndex:_InitView(buffGroup, currentChoice)
    self._SelectedIndex = currentChoice
    self._BuffGroup = buffGroup
    self.TxtName.text = buffGroup.IndexName
    self.GridMode.gameObject:SetActiveEx(false)
    self._Buttons = {}

    for i, buffId in pairs(buffGroup.Buff) do
        local buff = XMVCA.XFubenBossSingle:GetFeatureConfigById(buffId)
        local go = XUiHelper.Instantiate(self.GridMode.gameObject, self.ListMode)
        go:SetActiveEx(true)

        local btn = go:GetComponent("XUiButton")
        btn:SetRawImageEx(buff.Icon)
        btn:SetNameByGroup(0, buff.Desc)

        if buff.ScoreRate > 0 then
            btn:ActiveTextByGroup(1, true)

            btn:SetNameByGroup(
                1,
                string.format("+%.1f%%", buff.ScoreRate / 100))
        else
            btn:ActiveTextByGroup(1, false)
        end

        self._Buttons[i] = btn
        btn.CallBack = function() self:Select(i) end
    end

    self:_RefreshButtons()
end

function XUiFubenBossSinglePopupModeChooseIndex:Select(index)
    if index == self._SelectedIndex then
        self._SelectedIndex = 0
    else
        self._SelectedIndex = index
    end

    self:_RefreshButtons()
    self._OnChangeCallback()
end

function XUiFubenBossSinglePopupModeChooseIndex:_RefreshButtons()
    if not self._SelectedIndex then
        self._SelectedIndex = 0
    end

    for i = 1, #self._Buttons do
        if i == self._SelectedIndex then
            self._Buttons[i]:SetButtonState(CS.UiButtonState.Select)
        else
            self._Buttons[i]:SetButtonState(CS.UiButtonState.Normal)
        end
    end
end

function XUiFubenBossSinglePopupModeChooseIndex:GetSelectedBuffIndexAndBuffId()
    if self._SelectedIndex == 0 then
        return nil, nil
    end

    return self._SelectedIndex, self._BuffGroup.Buff[self._SelectedIndex]
end

return XUiFubenBossSinglePopupModeChooseIndex
