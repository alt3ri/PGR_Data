local XUiCommonPopupGetCharacter = XLuaUiManager.Register(XLuaUi, "UiCommonPopupGetCharacter")

function XUiCommonPopupGetCharacter:OnStart(prefabUrl)
    self.PrefabUrl = prefabUrl
    self:InitUi()
end

function XUiCommonPopupGetCharacter:InitUi()
    if not self.PrefabUrl then return end
    
    self.PanelSpine:LoadPrefab(self.PrefabUrl)
    
    self:RegisterClickEvent(self.BtnCancelBg, self.OnBtnCancelBgClick)
end

function XUiCommonPopupGetCharacter:OnBtnCancelBgClick()
    self:Close()
end

return XUiCommonPopupGetCharacter
