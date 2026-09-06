-- 引用LuaUi：UiTeamRecommendRoleTargetDetail
---@class XUiGridTRTargetDetailAwarenessEquip : XUiNode
local XUiGridTRTargetDetailAwarenessEquip = XClass(XUiNode, "XUiGridTRTargetDetailAwarenessEquip")

function XUiGridTRTargetDetailAwarenessEquip:OnStart()
    self.GridEquipUiObj = XTool.InitUiObjectByUi({}, self.GridEquip)

    self.GridEquipUiObj.BtnClick.CallBack = function() self:OnBtnClick() end
    self.GridEquipUiObj.BtnObtain.CallBack = function() self:OnBtnObtainClick() end
    self.GridEquipUiObj.BtnWear.CallBack = function() self:OnBtnWearClick() end
end

---@param targetSlotData table|nil 意识槽目标配置（EquipTemplateId/Site等），无目标传nil
---@param candidateEquipId number|nil 可穿戴候选装备id，无候选传nil
function XUiGridTRTargetDetailAwarenessEquip:Refresh(targetSlotData, candidateEquipId, resonanceCount)
    self.TemplateId = targetSlotData and targetSlotData.EquipTemplateId or 0
    self.Site = targetSlotData and targetSlotData.Site or 0
    self.CandidateEquipId = candidateEquipId

    if not XTool.IsNumberValid(self.TemplateId) then
        self:Close()
        return
    end

    self:Open()
    self:RefreshEquipInfo()
    self:RefreshResonanceIcon(resonanceCount)
    self:RefreshButton()
end

function XUiGridTRTargetDetailAwarenessEquip:RefreshEquipInfo()
    self.GridEquipUiObj.RImgIcon:SetRawImage(XMVCA.XEquip:GetEquipIconPath(self.TemplateId))
    self.Parent:SetUiSprite(self.GridEquipUiObj.ImgQuality, XMVCA.XEquip:GetEquipQualityPath(self.TemplateId))
    self.GridEquipUiObj.TxtSite.text = "0" .. tostring(self.Site or XMVCA.XEquip:GetEquipSite(self.TemplateId) or "")
    self.GridEquipUiObj.PanelSite.gameObject:SetActiveEx(true)
    self.GridEquipUiObj.ImgSelect.gameObject:SetActiveEx(false)
end

function XUiGridTRTargetDetailAwarenessEquip:RefreshResonanceIcon(resonanceCount)
    resonanceCount = resonanceCount or 0
    self.GridEquipUiObj.PanelResonance.gameObject:SetActiveEx(resonanceCount > 0)

    local iconPath = XMVCA.XEquip:GetResoanceIconPath(false)
    for index = 1, XEnumConst.EQUIP.MAX_RESONANCE_SKILL_COUNT do
        local img = self.GridEquipUiObj["ImgResonance" .. index]
        self.Parent:SetUiSprite(img, iconPath)
        img.gameObject:SetActiveEx(index <= resonanceCount)
    end
end

function XUiGridTRTargetDetailAwarenessEquip:RefreshButton()
    local candidateEquipId = self.CandidateEquipId
    local hasCandidate = XTool.IsNumberValid(candidateEquipId)
    local isWearing = hasCandidate and XMVCA.XEquip:IsEquipWearingByCharacterId(candidateEquipId, self.Parent.RecommendCharData.CharacterId)
    local isLocked = isWearing and XMVCA.XEquip:IsLock(candidateEquipId)

    self.GridEquipUiObj.ImgMedalIconlock.gameObject:SetActiveEx(not isWearing)
    self.GridEquipUiObj.ImgLock.gameObject:SetActiveEx(isLocked)
    self.GridEquipUiObj.TagLevel.gameObject:SetActiveEx(isWearing)
    self.GridEquipUiObj.BtnObtain.gameObject:SetActiveEx(not hasCandidate)
    self.GridEquipUiObj.BtnWear.gameObject:SetActiveEx(hasCandidate and not isWearing)
    self.GridEquipUiObj.TagWearRed.gameObject:SetActiveEx(hasCandidate and not isWearing)

    local breakthrough = 0
    if isWearing then
        local equip = XMVCA.XEquip:GetEquip(candidateEquipId)
        self.GridEquipUiObj.TxtLevel.text = tostring(equip.Level)
        breakthrough = equip.Breakthrough
    end

    local showBreakthrough = breakthrough > 0
    self.GridEquipUiObj.ImgBreakthrough.gameObject:SetActiveEx(showBreakthrough)
    if showBreakthrough then
        local icon = XMVCA.XEquip:GetEquipBreakThroughSmallIcon(breakthrough)
        self.Parent:SetUiSprite(self.GridEquipUiObj.ImgBreakthrough, icon)
    end
end

function XUiGridTRTargetDetailAwarenessEquip:OnBtnClick()
    self.Parent:OnAwarenessEquipGridClick(self.Site, self.GridEquipUiObj.BtnClick.transform)
end

function XUiGridTRTargetDetailAwarenessEquip:OnBtnObtainClick()
    self.Parent:OnAwarenessObtainGridClick(self.Site)
end

function XUiGridTRTargetDetailAwarenessEquip:OnBtnWearClick()
    self.Parent:OnAwarenessWearGridClick(self.Site)
end

return XUiGridTRTargetDetailAwarenessEquip
