---@class XUiGridEquip : XUiNode
local XUiGridEquip = XClass(XUiNode, "XUiGridEquip")

function XUiGridEquip:OnStart(clickCb)
    self.ClickCb = clickCb

    self:InitAutoScript()
    self:SetSelected(false)
end

function XUiGridEquip:InitRootUi(rootUi)
    self.Parent = rootUi
end

-- 清除显示，会依据所传入的角色ID，还原装备图标、品质图标、共鸣信息等状态
function XUiGridEquip:ShowCharacterDefaultWeapon(characterId)
    if not characterId then
        return
    end
    
    -- 获取角色配置中的Equip字段
    local characterConfig = XMVCA.XCharacter:GetModelCharacterConfigById(characterId)
    if not characterConfig or not characterConfig.EquipId then
        return
    end
    
    -- 更新图标为配置中的Equip图标
    local equipIconPath = XMVCA.XEquip:GetEquipIconPath(characterConfig.EquipId)
    if self.RImgIcon and self.RImgIcon:Exist() then
        self.RImgIcon:SetRawImage(equipIconPath, nil, true)
    end

    -- 还原品质图标（ImgQuality）为默认状态
    if self.ImgQuality then
        -- 获取装备模板配置
        local equipTemplate = XMVCA.XEquip:GetConfigEquip(characterConfig.EquipId)
        if equipTemplate then
            -- 重置为装备对应品质的默认图标
            local qualityPath = XMVCA.XEquip:GetEquipQualityPath(characterConfig.EquipId)
            self.Parent:SetUiSprite(self.ImgQuality, qualityPath)
            -- 隐藏品质特效
            if self.ImgQualityEffect then
                self.ImgQualityEffect.gameObject:SetActiveEx(false)
            end
        end
    end
    
    -- 还原共鸣信息为无共鸣状态
    for i = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
        local obj = self["ImgResonance" .. i]
        if obj then
            obj.gameObject:SetActiveEx(false)
        end
    end
    
    -- 还原其他状态（如选中、锁定、回收、突破等状态）
    self:SetSelected(false)
    if self.ImgLock then
        self.ImgLock.gameObject:SetActiveEx(false)
    end
    if self.ImgLaJi then
        self.ImgLaJi.gameObject:SetActiveEx(false)
    end
    if self.ImgBreakthrough then
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
    end
    if self.PanelUsing then
        self.PanelUsing.gameObject:SetActiveEx(false)
    end
    if self.PanelDefault then
        self.PanelDefault.gameObject:SetActiveEx(false)
    end
    if self.PanelNowPreset then
        self.PanelNowPreset.gameObject:SetActiveEx(false)
    end
    if self.PanelOtherPreset then
        self.PanelOtherPreset.gameObject:SetActiveEx(false)
    end
end

function XUiGridEquip:Refresh(equipId, idList)
    self.EquipId = equipId
    local equip = XMVCA.XEquip:GetEquip(equipId)
    if not equip then
        return
    end

    local templateId = equip.TemplateId

    if self.RImgIcon and self.RImgIcon:Exist() then
        self.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipIconPath(templateId, equip.Breakthrough), nil, true)
    end

    --通用的横条品质色
    if self.ImgQuality then
        local qualityPath = equip:GetEquipQualityPath()
        self.Parent:SetUiSprite(self.ImgQuality, qualityPath)

        if self.ImgQualityEffect then
            local effectPath = equip:GetEquipQualityEffectPath()
            self.ImgQualityEffect.gameObject:SetActiveEx(effectPath ~= nil)
            if effectPath then
                self.ImgQualityEffect.gameObject:LoadUiEffect(effectPath)
            end
        end
    end

    --装备专用的竖条品质色
    if self.ImgEquipQuality then
        local bgPath = equip:GetEquipBgPath()
        self.Parent:SetUiSprite(self.ImgEquipQuality, bgPath)

        if self.ImgEquipQualityEffect then
            local effectPath = equip:GetEquipBgEffectPath()
            self.ImgEquipQualityEffect.gameObject:SetActiveEx(effectPath ~= nil)
            if effectPath then
                self.ImgEquipQualityEffect.gameObject:LoadUiEffect(effectPath)
            end
        end
    end

    if self.TxtName then
        self.TxtName.text = XMVCA.XEquip:GetEquipName(templateId)
    end

    if self.TxtLevel then
        self.TxtLevel.text = equip.Level
    end

    -- 公约驻守激活橙色边框
    local equipSite = XMVCA.XEquip:GetEquipSiteByEquipId(equipId)
    local isActiveAwarenessOcuupy = XTool.IsNumberValid(equipSite) and XDataCenter.FubenAwarenessManager.GetChapterDataBySiteNum(equipSite):IsOccupy()
    if self.ImgFrame then
        self.ImgFrame.gameObject:SetActiveEx(isActiveAwarenessOcuupy)
    end

    if self.PanelSite and self.TxtSite then
        local equipSite = XMVCA.XEquip:GetEquipSiteByEquipId(equipId)
        if equipSite and equipSite ~= XEnumConst.EQUIP.EQUIP_SITE.WEAPON then
            self.TxtSite.text = "0" .. equipSite
            self.PanelSite.gameObject:SetActiveEx(true)
        else
            self.PanelSite.gameObject:SetActiveEx(false)
        end
    end

    for i = 1, XEnumConst.EQUIP.MAX_STAR_COUNT do
        if self["ImgGirdStar" .. i] then
            if i <= XMVCA.XEquip:GetEquipStar(templateId) then
                self["ImgGirdStar" .. i].transform.parent.gameObject:SetActiveEx(true)
            else
                self["ImgGirdStar" .. i].transform.parent.gameObject:SetActiveEx(false)
            end
        end
    end

    for i = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
        local obj = self["ImgResonance" .. i]
        if obj then
            if XMVCA.XEquip:CheckEquipPosResonanced(equipId, i) then
                -- 公约驻守+超频激活橙色标签
                local awaken = XMVCA.XEquip:IsEquipPosAwaken(equipId, i)
                local icon = XMVCA.XEquip:GetResoanceIconPath(awaken)
                local bindCharId = XMVCA.XEquip:GetResonanceBindCharacterId(equipId, i)
                local characterId = XMVCA.XEquip:GetEquipWearingCharacterId(equipId)
                if isActiveAwarenessOcuupy and awaken and bindCharId == characterId then
                    icon = CS.XGame.ClientConfig:GetString("AwarenessOcuupyActiveResonanced")
                end
                self.Parent:SetUiSprite(obj, icon)
                obj.gameObject:SetActiveEx(true)
            else
                obj.gameObject:SetActiveEx(false)
            end
        end
    end

    self:UpdateIsLock(equipId)
    self:UpdateIsRecycle(equipId)
    self:UpdateUsing(equipId,idList)
    self:UpdateBreakthrough(equipId)
end

function XUiGridEquip:SetSelected(status)
    if XTool.UObjIsNil(self.ImgSelect) then
        return
    end
    self.ImgSelect.gameObject:SetActiveEx(status)
end

function XUiGridEquip:IsSelected()
    return not XTool.UObjIsNil(self.ImgSelect) and self.ImgSelect.gameObject.activeSelf
end

function XUiGridEquip:UpdateUsing(equipId,idList)
    if equipId ~= self.EquipId then return end
    if XTool.UObjIsNil(self.PanelUsing) then return end

    --v1.28 装备头像
    local wearingCharacterId = XMVCA.XEquip:GetEquipWearingCharacterId(equipId)
    if XMVCA.XEquip:IsWearing(equipId) then
        if not XTool.UObjIsNil(self.TxtUsingOrInSuitPrefab) then
            self.TxtUsingOrInSuitPrefab.text = CS.XTextManager.GetText("EquipGridUsingWords")
        end
        self.PanelUsing.gameObject:SetActiveEx(true)
        if not XTool.UObjIsNil(self.PanelDefault) then self.PanelDefault.gameObject:SetActiveEx(false) end
        if not XTool.UObjIsNil(self.RImgRole) then
            local icon = XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(wearingCharacterId)
            self.RImgRole:SetRawImage(icon)
        end
    elseif XMVCA.XEquip:IsInSuitPrefab(equipId)
    and not XTool.UObjIsNil(self.TxtUsingOrInSuitPrefab) then
        if not XTool.UObjIsNil(self.TextInPrefab) then 
            self.PanelUsing.gameObject:SetActiveEx(false)
            self.PanelDefault.gameObject:SetActiveEx(true)
            self.TextInPrefab.text = CS.XTextManager.GetText("EquipGridInPrefabWords")
        else
            self.PanelUsing.gameObject:SetActiveEx(true)
            self.TxtUsingOrInSuitPrefab.text = CS.XTextManager.GetText("EquipGridInPrefabWords")
        end
    else
        self.PanelUsing.gameObject:SetActiveEx(false)
        if not XTool.UObjIsNil(self.PanelDefault) then self.PanelDefault.gameObject:SetActiveEx(false) end
    end
    
    if idList then
        for _,id in pairs(idList) do
            if equipId == id then
                if not XTool.UObjIsNil(self.TxtUsingOrInSuitPrefab) then
                    self.TxtUsingOrInSuitPrefab.text = CS.XTextManager.GetText("MentorGiftIsSelectedText")
                end
                self.PanelUsing.gameObject:SetActiveEx(true) 
            end
        end
    end

    -- 如果没有实际穿戴则检测其是否在队伍预设里
    if self.PanelNowPreset then
        local characterId = self.Parent.CharacterId
        local isCharIn = characterId and XDataCenter.TeamManager.CheckEquipIdCharIdIsInTeamPrefab(self.EquipId, characterId)
        local isShow = not XTool.IsNumberValid(wearingCharacterId) and isCharIn -- 预设标签必须要没有角色在装备它
        self.PanelNowPreset.gameObject:SetActiveEx(isShow)
        if isShow then
            self.PanelNowPreset:GetObject("RImgRole"):SetRawImage(XMVCA.XCharacter:GetCharBigRoundnessNotItemHeadIcon(characterId))
        end 
    end

    if self.PanelOtherPreset then
        local characterId = self.Parent.CharacterId
        local isCharIn = characterId and XDataCenter.TeamManager.CheckEquipIdCharIdIsInTeamPrefab(self.EquipId, characterId)
        local isEquipIn = XDataCenter.TeamManager.CheckEquipIdIsInTeamPrefab(self.EquipId)
        local isShow = not XTool.IsNumberValid(wearingCharacterId) and not isCharIn and isEquipIn -- 其他预设标签必须要没有角色在装备或预设里
        self.PanelOtherPreset.gameObject:SetActiveEx(isShow)
    end
end

function XUiGridEquip:UpdateIsLock(equipId)
    if equipId ~= self.EquipId then
        return
    end
    if XTool.UObjIsNil(self.ImgLock) then
        return
    end
    self.ImgLock.gameObject:SetActiveEx(XMVCA.XEquip:IsLock(self.EquipId))
end

function XUiGridEquip:UpdateIsRecycle(equipId)
    if equipId ~= self.EquipId then
        return
    end
    if XTool.UObjIsNil(self.ImgLaJi) then
        return
    end
    self.ImgLaJi.gameObject:SetActiveEx(XMVCA.XEquip:IsRecycle(self.EquipId))
end

function XUiGridEquip:UpdateBreakthrough(equipId)
    if equipId ~= self.EquipId then
        return
    end
    if XTool.UObjIsNil(self.ImgBreakthrough) then
        return
    end

    local icon = XMVCA.XEquip:GetEquipBreakThroughSmallIconByEquipId(self.EquipId)
    if icon then
        self.Parent:SetUiSprite(self.ImgBreakthrough, icon)
        self.ImgBreakthrough.gameObject:SetActiveEx(true)
    else
        self.ImgBreakthrough.gameObject:SetActiveEx(false)
    end
end

function XUiGridEquip:InitAutoScript()
    XTool.InitUiObject(self)
    if not XTool.UObjIsNil(self.PanelUsing) then
        local textGo = self.PanelUsing:Find("TextUsing")
        self.TxtUsingOrInSuitPrefab = textGo and textGo:GetComponent(typeof(CS.UnityEngine.UI.Text))
        --v1.28 装备头像
        self.RImgRole = self.PanelUsing.transform:Find("RImgRole"):GetComponent(typeof(CS.UnityEngine.UI.RawImage))
        self.PanelDefault = self.GameObject.transform:Find("GridEquipRectangle/PanelDefault") or nil
        self.TextInPrefab = not XTool.UObjIsNil(self.PanelDefault) and self.PanelDefault.transform:Find("TextUsing"):GetComponent(typeof(CS.UnityEngine.UI.Text)) or nil
    end
    if self.BtnClick and self.ClickCb then
        CsXUiHelper.RegisterClickEvent(self.BtnClick, function() self:OnBtnClickClick() end)
    end

    --v2.5 品质特效
    if self.ImgQuality then
        self.ImgQualityEffect = XUiHelper.TryGetComponent(self.ImgQuality.transform, "ImgQualityEffect")
    end
    if self.ImgEquipQuality then
        self.ImgEquipQualityEffect = XUiHelper.TryGetComponent(self.ImgEquipQuality.transform, "ImgEquipQualityEffect")
    end
end

function XUiGridEquip:OnBtnClickClick()
    if self.ClickCb then
        self.ClickCb(self.EquipId, self)
    end
end

return XUiGridEquip