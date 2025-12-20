---@class XUiDlcRelinkPopupRename : XLuaUi
---@field private _Control XDlcRelinkControl
---@field InFSigm UnityEngine.UI.InputField
local XUiDlcRelinkPopupRename = XLuaUiManager.Register(XLuaUi, "UiDlcRelinkPopupRename")

function XUiDlcRelinkPopupRename:OnAwake()
    self:RegisterUiEvents()
end

function XUiDlcRelinkPopupRename:OnStart(confirmCb)
    self.ConfirmCb = confirmCb
    self.MaxNameLength = self._Control:GetEquipPresetNameMaxLength()
    self.InFSigm.onValueChanged:AddListener(handler(self, self.OnInputValueChanged))
end

function XUiDlcRelinkPopupRename:OnEnable()
    self.InFSigm.text = ""
    self.TxtCount.text = string.format(self._Control:GetClientConfig("EquipPresetNameLengthFormat"), 0, self.MaxNameLength)
end

-- 去首尾空白
function XUiDlcRelinkPopupRename:Trim(str)
    return string.gsub(str or "", "^%s*(.-)%s*$", "%1")
end

-- 计算 UTF-8 字符长度
function XUiDlcRelinkPopupRename:GetInputLength()
    local s = self.InFSigm and self.InFSigm.text or ""
    local len = 0
    for _, _ in utf8.codes(s) do
        len = len + 1
    end
    return len
end

function XUiDlcRelinkPopupRename:OnInputValueChanged(text)
    local utf8Count = self:GetInputLength()
    self.TxtCount.text = string.format(self._Control:GetClientConfig("EquipPresetNameLengthFormat"), utf8Count, self.MaxNameLength)

    local editName = self:Trim(text)
    local disable = (editName == nil or editName == "") or (utf8Count > self.MaxNameLength)
    self.BtnNameSure:SetDisable(disable)
end

function XUiDlcRelinkPopupRename:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnTanchuangClose, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnNameCancel, self.OnBtnCancelClick)
    self:RegisterClickEvent(self.BtnNameSure, self.OnBtnNameSureClick)
end

function XUiDlcRelinkPopupRename:OnBtnCancelClick()
    self:Close()
end

function XUiDlcRelinkPopupRename:OnBtnNameSureClick()
    local editName = self:Trim(self.InFSigm.text)
    if string.len(editName) > 0 then
        local utf8Count = self:GetInputLength()
        if utf8Count > self.MaxNameLength then
            local msg = string.format(self._Control:GetClientConfig("EquipPresetNameTooLong"), self.MaxNameLength)
            self._Control:OpenCommonTipError(msg)
            return
        end
        self.ConfirmCb(editName, function()
            self._Control:OpenCommonTipSuccess(self._Control:GetClientConfig("EquipPresetRenameSuccess"))
            self:Close()
        end)
    else
        self._Control:OpenCommonTipError(self._Control:GetClientConfig("EquipPresetNameEmpty"))
    end
end

return XUiDlcRelinkPopupRename
