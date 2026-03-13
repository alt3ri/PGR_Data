local XUiCommonPopupGetCharacter = XLuaUiManager.Register(XLuaUi, "UiCommonPopupGetCharacter")

function XUiCommonPopupGetCharacter:OnStart(characterId)
    self.CharacterId = characterId
    self:InitUi()
    self:Refresh()
end

function XUiCommonPopupGetCharacter:InitUi()
    self.BtnCancelBg:AddEventListener(handler(self, self.OnBtnCancelBgClick))
    self.BtnTanchuangCloseBig:AddEventListener(handler(self, self.OnBtnCancelBgClick))
end

function XUiCommonPopupGetCharacter:Refresh()
    local characterId = self.CharacterId
    if not XTool.IsNumberValid(characterId) then return end

    -- 获取 CharacterPopupGetCharacterController 配置
    local popupConfig = XMVCA.XCharacter:GetPopupGetCharacterConfig(characterId)
    if not popupConfig then
        XLog.Error("XUiCommonPopupGetCharacter:Refresh error: config not found, characterId = " .. tostring(characterId))
        return
    end

    -- 获取角色基础配置
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    if not charConfig then return end

    -- TxtName: Character.tab 的 LogName
    self.TxtName.text = charConfig.LogName

    -- 获取元素配置
    local elementId = charConfig.Element
    local elementConfig = XMVCA.XCharacter:GetModelCharacterElementById(elementId)

    -- RImgElement: CharacterElement.tab 的 Icon2
    if elementConfig and elementConfig.Icon2 then
        self.RImgElement:SetRawImage(elementConfig.Icon2)
    end

    -- 获取职业配置
    local careerConfig = XMVCA.XCharacter:GetNpcTypeTemplate(charConfig.Career)

    -- TxtType: ElementName·CareerName（例如"雷·进攻型"）
    if elementConfig and careerConfig then
        self.TxtType.text = elementConfig.ElementName .. "·" .. careerConfig.Name
    end

    -- TxtType 颜色: CharacterPopupGetCharacterController.tab 的 TxtTypeColor
    if not string.IsNilOrEmpty(popupConfig.TxtTypeColor) then
        local colorStr = string.gsub(popupConfig.TxtTypeColor, "^#", "")
        self.TxtType.color = XUiHelper.Hexcolor2Color(colorStr)
    end

    -- ShowImg: CharacterPopupGetCharacterController.tab 的 ShowImgUrl
    if popupConfig.ShowImgUrl then
        self.ShowImg:SetRawImage(popupConfig.ShowImgUrl)
    end
end

function XUiCommonPopupGetCharacter:OnBtnCancelBgClick()
    self:Close()
end

return XUiCommonPopupGetCharacter
