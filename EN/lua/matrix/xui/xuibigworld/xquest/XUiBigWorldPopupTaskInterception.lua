---@class XUiBigWorldPopupTaskInterception : XLuaUi
---@field _Control XBigWorldQuestControl
---@field BtnConfirm XUiComponent.XUiButtonExt
---@field BtnClose XUiComponent.XUiButtonExt
---@field TxtInfoNormal UnityEngine.UI.Text
local XUiBigWorldPopupTaskInterception = XMVCA.XBigWorldUI:Register(nil, "UiBigWorldPopupTaskInterception")

function XUiBigWorldPopupTaskInterception:OnAwake()
    self:_RegisterButtonClicks()
end

function XUiBigWorldPopupTaskInterception:OnStart(tipId)
    self._TipId = tipId
    self:_RefreshView()
end

function XUiBigWorldPopupTaskInterception:_RefreshView()
    local desc = self._Control:GetMainLineTipDesc(self._TipId)
    self.TxtInfoNormal.text = desc
end

function XUiBigWorldPopupTaskInterception:_RegisterButtonClicks()
    self:RegisterClickEvent(self.BtnConfirm, self._OnBtnConfirmClick)
    self:RegisterClickEvent(self.BtnClose, self._OnBtnCloseClick)
end

function XUiBigWorldPopupTaskInterception:_OnBtnCloseClick()
    local template = self._Control:GetMainLineTipTemplate(self._TipId)
    local canSkip, tips = XMVCA.XBigWorldQuest:CheckMainlineSkipTip(template)
    if not canSkip then
        if not string.IsNilOrEmpty(tips) then
            XUiManager.TipError(tips)
        end
        return
    end
    self:CloseImmediately()
    XMVCA.XBigWorldQuest:SendMainlineSkipTipOpNotify(true)
    XMVCA.XBigWorldSkipFunction:SkipTo(template.SkipFunction, true)
end

function XUiBigWorldPopupTaskInterception:_OnBtnConfirmClick()
    self:Close()
    XMVCA.XBigWorldQuest:SendMainlineSkipTipOpNotify(false)
end
