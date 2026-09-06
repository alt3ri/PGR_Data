---@class XUiEquipPartnerOneKeyCultureSelectPreview : XUiNode
---@field _Control XPartnerControl
---@field TxtEvolutionBefore UnityEngine.UI.Text
---@field TxtEvolutionValue UnityEngine.UI.Text
---@field TxtEvolutionAfter UnityEngine.UI.Text
---@field TxtAttackBefore UnityEngine.UI.Text
---@field TxtAttackAfter UnityEngine.UI.Text
---@field TxtSkillEquipNum UnityEngine.UI.Text
---@field RImgRecommendQuality UnityEngine.UI.RawImage  
local XUiEquipPartnerOneKeyCultureSelectPreview = XClass(XUiNode, "XUiEquipPartnerOneKeyCultureSelectPreview")

function XUiEquipPartnerOneKeyCultureSelectPreview:OnStart()
    self:_Refresh()
end

function XUiEquipPartnerOneKeyCultureSelectPreview:OnEnable()
    self:_SetEvent(true)
    self:_Refresh()
end

function XUiEquipPartnerOneKeyCultureSelectPreview:OnDisable()
    self:_SetEvent(false)
end

function XUiEquipPartnerOneKeyCultureSelectPreview:OnDestroy()
end

---region event

function XUiEquipPartnerOneKeyCultureSelectPreview:_SetEvent(flag)
    local XPartnerEventId = XMVCA.XPartner.EventIds
    if flag then
        self._Control:AddEventListener(XPartnerEventId.EVENT_FOOD_SELECT_PREVIEW_CHANGE, self._OnFoodSelectChange, self)
    else
        self._Control:RemoveEventListener(XPartnerEventId.EVENT_FOOD_SELECT_PREVIEW_CHANGE, self._OnFoodSelectChange, self)
    end
end

function XUiEquipPartnerOneKeyCultureSelectPreview:_OnFoodSelectChange()
    self:_Refresh()
end

---endregion

function XUiEquipPartnerOneKeyCultureSelectPreview:_Refresh()
    local mainControl = self._Control:GetOneKeyCultureMainControl()
    local partner = mainControl:GetCurPartnerEntity()
    if not partner then
        return
    end

    local foodSelectControl = mainControl:GetFoodSelectControl()
    local curQuality = partner:GetQuality()

    local curStarSchedule = partner:GetStarSchedule()
    local maxClipCount = partner:GetClipMaxCount(curQuality)
    local previousQuality = curQuality - 1
    previousQuality = previousQuality >= partner:GetInitQuality() and previousQuality or 0
    local previousMaxClipCount = previousQuality > 0 and partner:GetClipMaxCount(previousQuality) or 0
    local foodExpCount = foodSelectControl:GetFoodSelectExpCount()

    self.TxtEvolutionBefore.text = curStarSchedule - previousMaxClipCount
    self.TxtEvolutionAfter.text = "/" .. maxClipCount - previousMaxClipCount
    self.TxtEvolutionValue.text = string.format("+%d", foodExpCount)

    self.TxtAttackBefore.text = foodSelectControl:GetPartnerAttrValue(partner, XNpcAttribType.AttackNormal)
    self.TxtAttackAfter.text = foodSelectControl:GetPreviewAttack()

    local canUpCount = foodSelectControl:GetFoodSelectCanUpCount()
    local targetQuality = math.min(curQuality + canUpCount, partner:GetQualityLimit())
    self.TxtSkillEquipNum.text = partner:GetQualitySkillColumnCount(targetQuality)

    self.RImgRecommendQuality:SetRawImage(XMVCA.XCharacter:GetCharQualityIcon(mainControl:GetRecommendQuality()))
end

return XUiEquipPartnerOneKeyCultureSelectPreview
