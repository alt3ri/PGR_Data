local XPanelCharacterUnOwnedInfoV2P6 = XClass(XUiNode, "XPanelCharacterUnOwnedInfoV2P6")
local XUiCharacterPanelRoleSkillV2P6 = require("XUi/XUiCharacterV2P6/Grid/XUiCharacterPanelRoleSkillV2P6")

function XPanelCharacterUnOwnedInfoV2P6:OnStart()
    self.IsFoldState = false
    self.RoleSkillPanel = XUiCharacterPanelRoleSkillV2P6.New(self.PanelRoleSkill, self)

    self:InitButton()
end

function XPanelCharacterUnOwnedInfoV2P6:RefreshUiShow()
    local characterId = self.Parent.CurCharacter.Id
    self.CharacterId = characterId
    
    -- 生命树
    local isShowTreeControl = XTool.IsNumberValid(CS.XGame.ClientConfig:GetInt("CharacterPowerIconVisible"))
    local powerConfig = XMVCA.XCharacter:GetCharacterPowerConfig(characterId)
    self.BtnTree.gameObject:SetActiveEx(powerConfig and isShowTreeControl)
    if powerConfig then
        self.TxtTreeDesc.text = powerConfig.Description
        self.BtnTree:SetSprite(powerConfig.Icon)
    end

    -- 机体名
    local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
    self.TxtName.text = charConfig.Name
    self.TxtNameOther.text = charConfig.TradeName
    if XOverseaManager.IsJP_KRRegion() then
        --是否显示为黑岩适配的换行文本，海外原先的Text放不下
        local detailConfig = XMVCA.XCharacter:GetCharDetailTemplate(characterId)
        local isShowSpcialText = detailConfig.LiberationShowType
        self.PanelName.gameObject:SetActiveEx(not isShowSpcialText)
        self.BlackRockShooter.gameObject:SetActiveEx(isShowSpcialText)
    end

    -- 职业
    local career = XMVCA.XCharacter:GetCharacterCareer(characterId)
    local careerIcon = XMVCA.XCharacter:GetNpcTypeIcon(career)
    self.BtnType:SetRawImage(careerIcon)

    local showUniframe = XMVCA.XCharacter:GetIsIsomer(characterId)
    self.BtnUniframeTip.gameObject:SetActiveEx(showUniframe)

    -- 品质
    self.ImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(XMVCA.XCharacter:GetCharacterQuality(characterId)))

    -- 元素
    local elementList = XMVCA.XCharacter:GetCharacterAllElement(characterId)
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if elementList and elementList[i] then
            rImg.gameObject:SetActiveEx(true)
            local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
            rImg:SetRawImage(elementConfig.Icon)
        else
            rImg.gameObject:SetActiveEx(false)
        end
    end

    -- 机制
    local generalSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(characterId)
    for i = 1, self.ListGeneralSkillDetail.childCount, 1 do
        local id = generalSkillIds[i]
        self["BtnGeneralSkill"..i].gameObject:SetActiveEx(id)
        if id then
            local generalSkillConfig = XMVCA.XCharacter:GetModelCharacterGeneralSkill()[id]
            self["BtnGeneralSkill"..i]:SetRawImage(generalSkillConfig.Icon)
        end
    end

    -- 碎片   
    local bornQuality = XMVCA.XCharacter:GetCharMinQuality(characterId)
    local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
    local curFragment = XMVCA.XCharacter:GetCharUnlockFragment(characterId)
    local needFragment = XMVCA.XCharacter:GetComposeCount(characterType, bornQuality)
    self.TxtOwnFragmentNumber.text = curFragment
    self.TxtNeedFragmentNumber.text = "/"..needFragment
    self.ImgFill.fillAmount = curFragment/needFragment
    local isEnoughtFrament = curFragment >= needFragment
    self.BtnUnlock.gameObject:SetActiveEx(isEnoughtFrament)
    self.BtnGet.gameObject:SetActiveEx(not isEnoughtFrament)

    local fragmentItemId = XMVCA.XCharacter:GetCharacterTemplate(characterId).ItemId
    local fragmentIcon = XDataCenter.ItemManager.GetItemIcon(fragmentItemId)
    self.Icon:SetRawImage(fragmentIcon)
    -- 描述
    self.TxtFiles.text = XMVCA.XCharacter:GetCharacterIntro(characterId)

    -- 技能预览
    self.RoleSkillPanel:Refresh(characterId)
end

function XPanelCharacterUnOwnedInfoV2P6:InitButton()
    self.BtnUniframeTip.CallBack = function()
        self:OnBtnUniframeTipClick()
    end
    
    self.BtnType.CallBack = function()
        self:OnBtnCareerTipsClick()
    end
    
    self.BtnElementDetail.CallBack = function()
        self:OnBtnElementDetailClick()
    end
    
    self.BtnSkillFold.CallBack = function()
        self:OnBtnSkillFoldClick()
    end
    
    self.BtnSkillUnFold.CallBack = function()
        self:OnBtnSkillUnFoldClick()
    end
    
    self.BtnGet.CallBack = function()
        self:OnBtnGetClick()
    end
    
    self.BtnUnlock.CallBack = function()
        self:OnBtnUnlockClick()
    end
    
    self.BtnGeneralSkill1.CallBack = function()
        self:OnBtnGeneralSkillClick(1)
    end
    
    self.BtnGeneralSkill2.CallBack = function()
        self:OnBtnGeneralSkillClick(2)
    end

    self.BtnTree.CallBack = function ()
        self:OnBtnTreeClick()
    end

    self.XGoInputHandler:AddDragUpListener(function ()
        self:OnDragUp()
    end)
    self.XGoInputHandler:AddDragDownListener(function ()
        self:OnDragDown()
    end)
    self.XGoInputHandler:AddMidButtonScrollUpListener(function ()
        self:OnDragUp()
    end)
    self.XGoInputHandler:AddMidButtonScrollDownListener(function ()
        self:OnDragDown()
    end)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnUniframeTipClick()
    XLuaUiManager.Open("UiCharacterUniframeBubbleV2P6")
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnCareerTipsClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnElementDetailClick()
    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnTreeClick()
    local isBubbleTreeActive = self.BubbleTreeDetail.gameObject.activeSelf
    self.Parent.BtnClose.gameObject:SetActiveEx(not isBubbleTreeActive)
    self.BubbleTreeDetail.gameObject:SetActiveEx(not isBubbleTreeActive)
end

function XPanelCharacterUnOwnedInfoV2P6:CloseTreeBubble()
    self.BubbleTreeDetail.gameObject:SetActiveEx(false)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnGeneralSkillClick(index)
    local generalSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(self.CharacterId)
    local curId = generalSkillIds[index]
    if not curId then
        return
    end

    XLuaUiManager.Open("UiCharacterAttributeDetail", self.CharacterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill, index)
end

-- 描述折叠
function XPanelCharacterUnOwnedInfoV2P6:OnBtnSkillFoldClick()
    if self.RoleSkillPanel:IsNodeShow() then
        return
    end
    
    self.Parent:PlayAnimation("PanelRoleSkillEnable")
    self.BtnSkillFold.gameObject:SetActiveEx(false)
    self.PanelUnownedInfo.gameObject:SetActiveEx(false)
    self.RoleSkillPanel:Open()
    local characterId = self.Parent.CurCharacter.Id
    self.RoleSkillPanel:Refresh(characterId)
end

-- 描述展开
function XPanelCharacterUnOwnedInfoV2P6:OnBtnSkillUnFoldClick()
    if not self.RoleSkillPanel:IsNodeShow() then
        return
    end

    self.Parent:PlayAnimation("PanelUnOwnedEnable")
    self.BtnSkillFold.gameObject:SetActiveEx(true)
    self.PanelUnownedInfo.gameObject:SetActiveEx(true)
    self.RoleSkillPanel:Close()
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnUnlockClick()
    local characterId = self.CharacterId
    if not XMVCA.XCharacter:CheckIsFragment(characterId) then
        return
    end

    XLuaUiManager.Open("UiUnlockShow", characterId, function()
        if not XMVCA.XCharacter:CheckIsFragment(characterId) then
            return
        end
        
        XMVCA.XCharacter:ExchangeCharacter(characterId, function()
            local title = CSXTextManagerGetText("CharacterUnlockNewCharacter")
            local content = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
            XUiManager.PopupLeftTip(title, content)
            XLuaAudioManager.PlayAudioByType(XLuaAudioManager.SoundType.SFX, XLuaAudioManager.UiBasicsMusic.UiCharacter_UnlockEnd)
        end)
    end)
end

function XPanelCharacterUnOwnedInfoV2P6:OnBtnGetClick()
    --local unionFightData = XDataCenter.FubenUnionKillRoomManager.GetUnionRoomData()
    --if unionFightData and unionFightData.Id then
    --    return
    --end

    local useItemId = XMVCA.XCharacter:GetCharacterTemplate(self.CharacterId).ItemId
    XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(useItemId))
end

function XPanelCharacterUnOwnedInfoV2P6:OnDragUp()
    self:OnBtnSkillFoldClick()
end

function XPanelCharacterUnOwnedInfoV2P6:OnDragDown()
    self:OnBtnSkillUnFoldClick()
end

return XPanelCharacterUnOwnedInfoV2P6
