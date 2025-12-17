local LOCAL_SAVE_AGREE = "LOCAL_SAVE_AGREE"
local LOCAL_SAVE_PRIVE = "LOCAL_SAVE_PRIVE"
local XUiLoginAgreement = XLuaUiManager.Register(XLuaUi, "UiLoginAgreement")

function XUiLoginAgreement:OnAwake()
    self:InitUI()
end

--第一次登录默认不勾选用户协议
function XUiLoginAgreement:InitUI()
    self.AgreeToggle.isOn = false
    self.UserAgreeLicence = false
    self.AgreeTxt1.text = XAgreementManager.CurAgree
    self.AgreeTxt2.text = XAgreementManager.CurPriva
    self:AutoAddListeners()
    if XAgreementManager.GetUserAgreeLicence() ~= nil then
        self.AgreeToggle.isOn = XAgreementManager.GetUserAgreeLicence()
        self.SavedAgree = XAgreementManager.GetUserAgreeLicence()
    end
end

function XUiLoginAgreement:SaveToLocal()
    local saveAgree = XSaveTool.GetData(LOCAL_SAVE_AGREE)
    local savePrive = XSaveTool.GetData(LOCAL_SAVE_PRIVE)
    if saveAgree == nil or savePrive == nil then
        XSaveTool.SaveData(LOCAL_SAVE_AGREE, XAgreementManager.CurAgree)
        XSaveTool.SaveData(LOCAL_SAVE_PRIVE, XAgreementManager.CurPriva)
        return
    end

    if XAgreementManager.CurAgree == nil or XAgreementManager.CurPriva == nil then
        return
    end

    if XAgreementManager.CurAgree ~= saveAgree or XAgreementManager.CurPriva ~= savePrive then
        XSaveTool.SaveData(LOCAL_SAVE_AGREE, XAgreementManager.CurAgree)
        XSaveTool.SaveData(LOCAL_SAVE_PRIVE, XAgreementManager.CurPriva)
    end
end


function XUiLoginAgreement:AutoAddListeners()
    if self.Init then return end
    self.ConfirmAgree.onClick:AddListener(Handler(self, self.OnCancelAgree))
    self.CancelAgree.onClick:AddListener(Handler(self, self.OnConfirmAgree))
    self.AgreeToggle.onValueChanged:AddListener(Handler(self, self.OnAgreeValueChanged))
    self.Init = true
end

function XUiLoginAgreement:OnConfirmAgree()
    if self.UserAgreeLicence == false then
        --XUiManager.SystemDialogTip("TIPS", "利用規約及びプライバシーポリシーに同意いただけない場合、ゲーム登録できません。", XUiManager.DialogType.OnlySure, nil, nil)
        XUiManager.TipError(CS.XTextManager.GetLuaText("XUiLoginAgreement.lua_53"))
    else
        --CheckPoint: APPEVENT_GAME_PRIVACY
        XAppEventManager.AppLogEvent(XAppEventManager.CommonEventNameConfig.Game_Privacy)
        self.SaveToLocal()
        if self.Parent and self.Parent.CloseCallBack then
           self.Parent.CloseCallBack()
        end
        self:Close()
    end
end

function XUiLoginAgreement:OnAgreeValueChanged(isOn)
    self.UserAgreeLicence = isOn
    XAgreementManager.SetUserAgreeLicence(isOn)
end

function XUiLoginAgreement:OnCancelAgree()
    if self.SavedAgree ~= nil then
        XAgreementManager.SetUserAgreeLicence(self.SavedAgree);
    end
    self:Close()
end

return XUiLoginAgreement