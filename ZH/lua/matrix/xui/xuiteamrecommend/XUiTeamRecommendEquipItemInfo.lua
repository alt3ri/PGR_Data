local XUiTeamRecommendEquipItemInfo = XLuaUiManager.Register(XLuaUi, "UiTeamRecommendEquipItemInfo")

function XUiTeamRecommendEquipItemInfo:OnAwake()
    self:InitCb()
end

function XUiTeamRecommendEquipItemInfo:OnStart(templateId, isSuit)
    self.Id = templateId
    self.IsSuit = isSuit
    self:InitView()
end

function XUiTeamRecommendEquipItemInfo:InitCb()
    self:RegisterClickEvent(self.BtnClose, self.Close)
    self.BtnGet.CallBack = function()
        self:OnBtnGetClick()
    end
end

function XUiTeamRecommendEquipItemInfo:InitView()
    self.PanelAwarenessSkillDes.gameObject:SetActiveEx(self.IsSuit)
    self.PanelWeapon.gameObject:SetActiveEx(not self.IsSuit)

    if not self.IsSuit then
        self.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipBigIconPath(self.Id))
        self.TxtName.text = XMVCA.XEquip:GetEquipName(self.Id)
        local weaponTemplate = XMVCA.XEquip:GetConfigEquip(self.Id)
        local skillTemplate = XMVCA.XEquip:GetConfigWeaponSkill(weaponTemplate.WeaponSkillId)
        self.TemplateId = self.Id
        self:RefreshTemplateGrids({ self.GridWeaponDes }, { skillTemplate }, nil, nil, "GridWeaponDesc",
            function(grid, tmp)
                grid.TxtWeaponDes.text = tmp.Description
                grid.TxtDescription.text = tmp.Name
            end)
        self.TxtType.text = XMVCA.XArchive:GetWeaponGroupName(XMVCA.XEquip:GetEquipType(self.Id))
        self.ImgQuality:SetSprite(XMVCA.XEquip:GetEquipQualityPath(self.Id))
        return
    end

    local template = XMVCA.XEquip:GetConfigEquipSuit(self.Id)
    self.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipSuitClearIconPath(self.Id))
    self.TxtName.text = template.Name
    local skillData = XMVCA.XEquip:GetSuitActiveSkillDesList(self.Id, XEnumConst.EQUIP.MAX_SUIT_COUNT)
    self:RefreshTemplateGrids(self.GridSkillDes, skillData, self.SkillPaneContent, nil, "GridSkillDes",
        function(grid, tmp)
            grid.TxtSkillDes.text = tmp.SkillDes
            grid.TxtDescription.text = tmp.PosDes
        end)
    self.TxtType.text = template.Description
    self.TemplateId = XMVCA.XEquip:GetSuitEquipIds(self.Id)[1]
    self.ImgQuality:SetSprite(XMVCA.XEquip:GetEquipQualityPath(self.TemplateId))
end

function XUiTeamRecommendEquipItemInfo:OnBtnGetClick()
    if not XTool.IsNumberValid(self.TemplateId) then
        return
    end
    local data = XMVCA.XEquip:GenerateEquipSkipData(self.TemplateId)
    XLuaUiManager.Open("UiEquipStrengthenSkip", data)
end
