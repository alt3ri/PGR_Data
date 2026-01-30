
local XUiTeamPrefabPopupRename = XLuaUiManager.Register(XLuaUi, "UiTeamPrefabPopupRename")

function XUiTeamPrefabPopupRename:OnAwake()
    self:InitButton()
end

function XUiTeamPrefabPopupRename:InitButton()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnNameCancel.CallBack = function() self:Close() end
    self.BtnNameSure.CallBack = function() self:OnBtnNameSureClick() end
    self.BtnNameSure:SetDisable(true)
    self.InputField.onValueChanged:AddListener(function(v)
        self:OnInputValueChanged(v) 
    end)
    self.TxtNum.text = 0
end

function XUiTeamPrefabPopupRename:OnBtnNameSureClick()
    local str = self.InputField.text
    str = self:Trim(str)
    if string.IsNilOrEmpty(str) then
        XUiManager.TipText("TeamPrefabWithoutName")
        return
    end

    if self.ConfirmCb then
        self.ConfirmCb(str)
    end
    self:Close()
end

function XUiTeamPrefabPopupRename:OnInputValueChanged(v)
    local str = self.InputField.text
    local _, count = string.gsub(str, "[^\128-\193]", "")
    self.TxtNum.text = count
    if str ~= "" then
        self.BtnNameSure:SetDisable(false)
    else
        self.BtnNameSure:SetDisable(true)
    end
end

function XUiTeamPrefabPopupRename:OnStart(confirmCb)
    self.ConfirmCb = confirmCb
end

-- 修改 trim 函数，同时过滤所有换行符
function XUiTeamPrefabPopupRename:Trim(s)
    -- 先移除所有换行符（\n）和回车符（\r），再处理首尾空白
    s = string.gsub(s, "[\n\r]", "")  -- 过滤换行和回车
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))  -- 原有的首尾空白处理
end

