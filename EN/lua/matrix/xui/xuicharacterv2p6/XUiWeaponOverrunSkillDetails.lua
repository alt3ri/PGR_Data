local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")

---@class XUiWeaponOverrunSkillDetails : XLuaUi
local XUiWeaponOverrunSkillDetails = XLuaUiManager.Register(XLuaUi, "UiWeaponOverrunSkillDetails")

local BtnSpecialStateNames = { "Normal", "Press", "Select" }

function XUiWeaponOverrunSkillDetails:OnAwake()
    self:InitPanel()
    self:InitButton()
end

function XUiWeaponOverrunSkillDetails:OnStart(characterId)
    self.CharacterId = characterId
end

function XUiWeaponOverrunSkillDetails:OnEnable()
    self:Refresh()
end

function XUiWeaponOverrunSkillDetails:InitButton()
    self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.SkillPoint, XDataCenter.ItemManager.ItemId.Coin)

    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnNext, self.OnBtnNext)
    self:RegisterClickEvent(self.BtnLast, self.OnBtnLast)
    self:RegisterClickEvent(self.PanelSkillInfoUiObject:GetObject("BtnUnlock"), self.OnBtnUnlockClick)

    self.PanelTagGroup:Init({ self.BtnSpecial }, function(tabIndex)
        self:OnClickTabCallBack(tabIndex)
    end)
end

function XUiWeaponOverrunSkillDetails:InitPanel()
    self.Toggle.gameObject:SetActiveEx(false)
    self.BtnTog.gameObject:SetActiveEx(false)

    self.PanelSkillInfoUiObject = self.PanelSkillInfo:GetComponent("UiObject")
    self.PanelSkillInfoUiObject:GetObject("PanelMask").gameObject:SetActiveEx(false)
    self.PanelSkillInfoUiObject:GetObject("BtnObservation").gameObject:SetActiveEx(false)
    self.PanelSkillInfoUiObject:GetObject("PanelConsume").gameObject:SetActiveEx(false)
    self.PanelSkillInfoUiObject:GetObject("BtnNounParsing").gameObject:SetActiveEx(false)
    self.PanelSkillInfoUiObject:GetObject("BtnSwitch").gameObject:SetActiveEx(false)
    self.PanelSkillInfoUiObject:GetObject("BtnDetails").gameObject:SetActiveEx(false)
    self.PanelSkillInfoUiObject:GetObject("BtnUpgrade").gameObject:SetActiveEx(false)
    self.PanelSkillInfoUiObject:GetObject("TxtSkillTitle").gameObject:SetActiveEx(false)
    self.PanelSkillInfoUiObject:GetObject("ImgBlueBall").gameObject:SetActiveEx(false)
end

function XUiWeaponOverrunSkillDetails:OnBtnBackClick()
    self.ParentUi:Close()
end

function XUiWeaponOverrunSkillDetails:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiWeaponOverrunSkillDetails:OnBtnNext()
    self.ParentUi:SwitchToNextSkillDetails()
end

function XUiWeaponOverrunSkillDetails:OnBtnLast()
    self.ParentUi:SwitchToLastSkillDetails()
end

function XUiWeaponOverrunSkillDetails:OnClickTabCallBack(tabIndex)
end

function XUiWeaponOverrunSkillDetails:OnBtnUnlockClick()
    local exclusiveEquipId = self:GetExclusiveEquipId()
    local equip = self:GetEquippedExclusiveWeapon(exclusiveEquipId)
    if not equip then
        return
    end

    XLuaUiManager.Open("UiEquipDetailV2P6", equip.Id, nil, self.CharacterId, nil, XEnumConst.EQUIP.UI_EQUIP_DETAIL_BTN_INDEX.OVERRUN)
end

function XUiWeaponOverrunSkillDetails:Refresh()
    local exclusiveEquipId = self:GetExclusiveEquipId()
    local attrConfig = XMVCA.XEquip:GetWeaponOverrunAttrCfgByTemplateId(exclusiveEquipId, self.CharacterId)
    local equip = self:GetEquippedExclusiveWeapon(exclusiveEquipId)
    local isUnlock = equip and equip:IsOverrunAttrUnlock(self.CharacterId) or false
    local isWearingExclusiveWeapon = equip ~= nil
    -- Overrun attr config displays level 1 after unlock, otherwise level 0.
    local level = isUnlock and 1 or 0
    local showSkillId = attrConfig and attrConfig.ShowOverrunSkillId
    local skillCfg = XMVCA.XEquip:GetWeaponOverrunSkillConfigById(showSkillId)

    self:RefreshBtnSpecial(skillCfg, level)
    self:RefreshSkillInfo(skillCfg, level, isUnlock, isWearingExclusiveWeapon, exclusiveEquipId)
end

function XUiWeaponOverrunSkillDetails:GetExclusiveEquipId()
    local characterConfig = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId, true)
    return characterConfig and characterConfig.ExclusiveEquipId
end

function XUiWeaponOverrunSkillDetails:GetEquippedExclusiveWeapon(exclusiveEquipId)
    if not XTool.IsNumberValid(exclusiveEquipId) then
        return nil
    end

    local weaponId = XMVCA.XEquip:GetCharacterWeaponId(self.CharacterId)
    if not XTool.IsNumberValid(weaponId) then
        return nil
    end

    local equip = XMVCA.XEquip:GetEquip(weaponId)
    if equip and equip.TemplateId == exclusiveEquipId then
        return equip
    end

    return nil
end

function XUiWeaponOverrunSkillDetails:GetWearConditionDesc(exclusiveEquipId)
    local equipName = XMVCA.XEquip:GetEquipName(exclusiveEquipId)
    return string.format(CSXTextManagerGetText("EquipOverrunCharacterWearTips"), equipName)
end

function XUiWeaponOverrunSkillDetails:RefreshSkillInfo(skillCfg, level, isUnlock, isWearingExclusiveWeapon, exclusiveEquipId)
    local panelSkillInfoUiObject = self.PanelSkillInfoUiObject
    local typeDes = CSXTextManagerGetText("EquipOverrunCharacterSkillTagName")
    local skillIcon = CSXTextManagerGetText("EquipOverrunCharacterSkillTagIcon")

    panelSkillInfoUiObject:GetObject("TxtSkillLevel").text = tostring(level)
    panelSkillInfoUiObject:GetObject("TxtSkillType").text = CSXTextManagerGetText("CharacterSkillTypeText", typeDes)
    panelSkillInfoUiObject:GetObject("BtnUnlock").gameObject:SetActiveEx(not isUnlock)
    panelSkillInfoUiObject:GetObject("BtnUnlock"):SetDisable(not isWearingExclusiveWeapon)
    panelSkillInfoUiObject:GetObject("PanelMax").gameObject:SetActiveEx(isUnlock)
    panelSkillInfoUiObject:GetObject("PanelCondition").gameObject:SetActiveEx(not isWearingExclusiveWeapon)
    panelSkillInfoUiObject:GetObject("TxtConditionBad").gameObject:SetActiveEx(not isWearingExclusiveWeapon)
    if not isWearingExclusiveWeapon then
        panelSkillInfoUiObject:GetObject("TxtConditionBad").text = self:GetWearConditionDesc(exclusiveEquipId)
    end
    self.TxtName.text = typeDes
    self.SkillIcon:SetRawImage(skillIcon)

    panelSkillInfoUiObject:GetObject("ImgSkillPointIcon").gameObject:SetActiveEx(true)
    panelSkillInfoUiObject:GetObject("ImgSkillPointIcon"):SetRawImage(skillCfg.Icon)
    panelSkillInfoUiObject:GetObject("TxtSkillName").text = skillCfg.Name or ""
    panelSkillInfoUiObject:GetObject("TxtSkillSpecific").text = XUiHelper.ReplaceTextNewLine(skillCfg.Desc or "")
end

function XUiWeaponOverrunSkillDetails:RefreshBtnSpecial(skillCfg, level)
    local levelText = level == 0 and "" or CS.XTextManager.GetText("HostelDeviceLevel") .. ":" .. level
    self.BtnSpecial:SetNameByGroup(0, levelText)

    local isLock = level <= 0
    -- Keep icon and lock state consistent across all button states.
    for _, stateName in ipairs(BtnSpecialStateNames) do
        local iconTrans = self.BtnSpecial.transform:Find(stateName .. "/Icon")
        if iconTrans then
            iconTrans:GetComponent("Image"):SetSprite(skillCfg.Icon)
        end

        local imgLock = self.BtnSpecial.transform:Find(stateName .. "/ImgLcok")
        if imgLock then
            imgLock.gameObject:SetActiveEx(isLock)
        end
    end

    self.PanelTagGroup:SelectIndex(1)
end

return XUiWeaponOverrunSkillDetails
