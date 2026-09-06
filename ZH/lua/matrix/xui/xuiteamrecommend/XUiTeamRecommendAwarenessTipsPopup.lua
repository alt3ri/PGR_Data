local AwarenessState = {
    Obtain = 1,
    Wear = 2,
    Cultivate = 3,
    Complete = 4,
}

local Color = {
    Blue = XUiHelper.Hexcolor2Color("0E70BDFF"),
    Black = XUiHelper.Hexcolor2Color("00000099"),
    Green = XUiHelper.Hexcolor2Color("188649FF"),
}

local CSMathf = CS.UnityEngine.Mathf
local PopupMargin = 20
local RectTransformCornerCount = 4

---@class XUiTeamRecommendAwarenessTipsPopup : XLuaUi
local XUiTeamRecommendAwarenessTipsPopup = XLuaUiManager.Register(XLuaUi, "UiTeamRecommendAwarenessTipsPopup")

-- 初始化组件默认状态，避免刷新中断时保留 Prefab 激活状态
function XUiTeamRecommendAwarenessTipsPopup:OnAwake()
    self.EquipUiObj = XTool.InitUiObjectByUi({}, self.GridEquipUsing)
    self.PanelStateDesc.gameObject:SetActiveEx(false)
    self.PanelBtn.gameObject:SetActiveEx(true)
    self.BtnGet.gameObject:SetActiveEx(false)
    self.BtnWear.gameObject:SetActiveEx(false)
    self.BtnCultivate.gameObject:SetActiveEx(false)
    self.TxtWearTips.gameObject:SetActiveEx(false)
    self:InitButton()
end

function XUiTeamRecommendAwarenessTipsPopup:OnStart(characterId, targetSlotData, refreshCb, sourceTransform)
    self.CharacterId = characterId
    self.TargetSlotData = targetSlotData
    self.Site = targetSlotData.Site
    self.TemplateId = targetSlotData.EquipTemplateId
    self.RefreshCb = refreshCb
    self:Refresh()
    self:FixPosition(sourceTransform)
end

function XUiTeamRecommendAwarenessTipsPopup:InitButton()
    self.BtnClose.CallBack = function() self:Close() end
    self.BtnGet.CallBack = function() self:OnBtnGetClick() end
    self.BtnWear.CallBack = function() self:OnBtnWearClick() end
    self.BtnCultivate.CallBack = function() self:OnBtnCultivateClick() end
end

function XUiTeamRecommendAwarenessTipsPopup:Refresh()
    local wearingEquip = XMVCA.XEquip:GetCharacterEquip(self.CharacterId, self.Site)
    self.WearingEquip = wearingEquip and wearingEquip.TemplateId == self.TemplateId and wearingEquip or nil
    local candidateEquipId = XMVCA.XTeamRecommend:GetRecommendEquipCandidate(self.TemplateId, self.CharacterId)
    self.CandidateEquip = candidateEquipId and XMVCA.XEquip:GetEquip(candidateEquipId) or nil

    self:RefreshEquip()
    self:RefreshAttr()
    self:RefreshSkill()
    self:RefreshState()
end

function XUiTeamRecommendAwarenessTipsPopup:GetState()
    if not self.CandidateEquip then return AwarenessState.Obtain end
    if not self.WearingEquip then return AwarenessState.Wear end
    return self:IsTargetAchieved() and AwarenessState.Complete or AwarenessState.Cultivate
end

-- 当前穿戴意识达到满级、目标共鸣和超频条件时视为完成
function XUiTeamRecommendAwarenessTipsPopup:IsTargetAchieved()
    if not self.WearingEquip:IsMaxLevelAndBreakthrough() then return false end

    if XMVCA.XEquip:CanResonanceByTemplateId(self.TemplateId) then
        local resonanceList = self.TargetSlotData.ResonanceList
        for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            local resonanceData = resonanceList and resonanceList[pos]
            local targetState = XMVCA.XEquip:GetAwarenessResonanceTargetState(
                self.WearingEquip.Id, pos, resonanceData, self.CharacterId)
            if not targetState.IsAchieved then
                return false
            end
        end
    end

    local isAwakeSupported = XMVCA.XEquip:CheckEquipStarCanAwake(self.WearingEquip.Id)
    if isAwakeSupported then
        for pos = 1, XEnumConst.EQUIP.MAX_AWAKE_COUNT do
            if not XMVCA.XEquip:IsEquipPosAwaken(self.WearingEquip.Id, pos) then
                return false
            end
        end
    end
    return true
end

function XUiTeamRecommendAwarenessTipsPopup:RefreshEquip()
    local equip = self.WearingEquip or self.CandidateEquip
    local equipUiObj = self.EquipUiObj
    equipUiObj.TxtName.text = XMVCA.XEquip:GetEquipName(self.TemplateId)
    equipUiObj.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipIconPath(self.TemplateId))
    equipUiObj.ImgQuality:SetSprite(XMVCA.XEquip:GetEquipQualityPath(self.TemplateId))
    equipUiObj.TxtSite.text = string.format("%02d", self.Site)
    equipUiObj.TxtLevel.text = equip and tostring(equip.Level) or ""

    local breakthrough = equip and equip.Breakthrough or 0
    equipUiObj.ImgBreakthrough.gameObject:SetActiveEx(breakthrough > 0)
    if breakthrough > 0 then
        equipUiObj.ImgBreakthrough:SetSprite(XMVCA.XEquip:GetEquipBreakThroughSmallIcon(breakthrough))
    end

    local resonanceCount = equip and equip:GetResonanceCount() or 0
    equipUiObj.PanelResonance.gameObject:SetActiveEx(resonanceCount > 0)
    for pos = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
        local imgResonance = equipUiObj["ImgResonance" .. pos]
        imgResonance.gameObject:SetActiveEx(pos <= resonanceCount)
        if pos <= resonanceCount then
            imgResonance:SetSprite(XMVCA.XEquip:GetResoanceIconPath(equip:IsEquipPosAwaken(pos)))
        end
    end
end

function XUiTeamRecommendAwarenessTipsPopup:RefreshAttr()
    local equip = self.WearingEquip or self.CandidateEquip
    local attrList = equip and XMVCA.XEquip:GetEquipAttrMap(equip.Id, equip.Breakthrough, equip.Level) or XMVCA.XEquip:ConstructTemplateEquipAttrMap(self.TemplateId, 0, 0)
    for index = 1, 2 do
        local attr = attrList[index]
        self["TxtUsingAttrName" .. index].text = attr and attr.Name or ""
        self["TxtUsingAttrValue" .. index].text = attr and attr.Value or ""
    end
end

function XUiTeamRecommendAwarenessTipsPopup:RefreshSkill()
    local suitId = XMVCA.XEquip:GetEquipSuitId(self.TemplateId)
    local activeCount = XMVCA.XEquip:GetActiveSuitEquipsCount(self.CharacterId, suitId)
    local skillDescList = XMVCA.XEquip:GetSuitActiveSkillDesList(suitId, activeCount)
    self:RefreshTemplateGrids(self.TxtSkillDesc, skillDescList, self.PanelContent, nil, "GridChipsDesc", function(grid, data)
        local color = data.IsActive and Color.Green or Color.Black
        grid.TxtTitle.text = data.PosDes
        grid.TxtSkillDesc.text = data.SkillDes
        grid.TxtTitle.color = color
        grid.TxtSkillDesc.color = color
    end)
end

function XUiTeamRecommendAwarenessTipsPopup:RefreshState()
    local state = self:GetState()
    local isObtain = state == AwarenessState.Obtain
    local isWear = state == AwarenessState.Wear
    local isCultivate = state == AwarenessState.Cultivate
    local isComplete = state == AwarenessState.Complete
    self.BtnGet.gameObject:SetActiveEx(isObtain)
    self.BtnWear.gameObject:SetActiveEx(isWear)
    self.BtnCultivate.gameObject:SetActiveEx(isCultivate or isComplete)
    self.BtnCultivate:SetDisable(isComplete, isCultivate)
    self.TxtWearTips.gameObject:SetActiveEx(isWear)

    local textKey = isObtain and "EquipGuideEquipNotExist" or isWear and "EquipGuideEquipCanEquips" or isComplete and "EquipGuideEquipFullLevel" or "EquipGuideEquipGrowing"
    self.TxtStateDesc.text = XUiHelper.GetText(textKey)
    self.TxtStateDesc.color = isComplete and Color.Blue or Color.Black
end

-- 将弹窗放在点击项侧边并限制在屏幕内
function XUiTeamRecommendAwarenessTipsPopup:FixPosition(sourceTransform)
    local panelTransform = self.PanelDynamicPosParent.transform
    local parentTransform = panelTransform.parent
    local corners = CS.System.Array.CreateInstance(typeof(CS.UnityEngine.Vector3), RectTransformCornerCount)
    sourceTransform:GetWorldCorners(corners)

    local sourceBottomLeft = parentTransform:InverseTransformPoint(corners[0])
    local sourceTopRight = parentTransform:InverseTransformPoint(corners[2])
    local panelRect = panelTransform.rect
    local parentRect = parentTransform.rect
    local pivot = panelTransform.pivot
    local panelLeft = pivot.x * panelRect.width
    local panelRight = (1 - pivot.x) * panelRect.width
    local panelBottom = pivot.y * panelRect.height
    local panelTop = (1 - pivot.y) * panelRect.height
    local minX = parentRect.xMin + panelLeft
    local maxX = parentRect.xMax - panelRight
    local minY = parentRect.yMin + panelBottom
    local maxY = parentRect.yMax - panelTop
    local rightX = sourceTopRight.x + PopupMargin + panelLeft
    local leftX = sourceBottomLeft.x - PopupMargin - panelRight
    local x = leftX
    if rightX <= maxX or leftX < minX then
        x = rightX
    end
    local y = (sourceBottomLeft.y + sourceTopRight.y) / 2
    local position = panelTransform.localPosition

    panelTransform.localPosition = CS.UnityEngine.Vector3(CSMathf.Clamp(x, minX, maxX), CSMathf.Clamp(y, minY, maxY), position.z)
end

function XUiTeamRecommendAwarenessTipsPopup:OnBtnGetClick()
    XLuaUiManager.Open("UiEquipStrengthenSkip", XMVCA.XEquip:GenerateEquipSkipData(self.TemplateId))
end

function XUiTeamRecommendAwarenessTipsPopup:OnBtnWearClick()
    XMVCA.XEquip:PutOn(self.CharacterId, self.CandidateEquip.Id, function()
        if self.RefreshCb then self.RefreshCb() end
        self:Refresh()
    end)
end

function XUiTeamRecommendAwarenessTipsPopup:OnBtnCultivateClick()
    self:Close()
    XMVCA.XEquip:OpenUiEquipDetail(self.WearingEquip.Id, false, self.CharacterId)
end
