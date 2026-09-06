-- 引用LuaUi：UiTeamRecommendMain、UiTeamRecommendDetail
---@class XUiGridTRCharTargetCard : XUiNode 角色目标卡片
local XUiGridTRCharTargetCard = XClass(XUiNode, "XUiGridTRCharTargetCard")
local XUiGridTRTargetAwarenessSuit = require("XUi/XUiTeamRecommend/Grid/XUiGridTRTargetAwarenessSuit")

function XUiGridTRCharTargetCard:OnStart()
    self.PartnerUiObj = XTool.InitUiObjectByUi({}, self.PanelPartner)
    self.OverrunLevelUiObj = XTool.InitUiObjectByUi({}, self.BtnOverrunBlind)
    self.AwarenessGridList = {}
    self.GridAwarenessItem.gameObject:SetActiveEx(false)

    XUiHelper.RegisterClickEvent(self, self.RImgHead, self.OnBtnHeadClick)
    self.BtnSet.CallBack = function() self:OnBtnSetClick() end
    self.BtnGo.CallBack = function() self:OnBtnGoClick() end
    self.BtnGetRole.CallBack = function() self:OnBtnGetRoleClick() end
    self.PartnerUiObj.BtnClick.CallBack = function() self:OnBtnPartnerClick() end
    self.BtnElementDetail.CallBack = handler(self, self.OnBtnElementDetailClick)
    self.BtnGeneralSkill1.CallBack = function() self:OnBtnGeneralSkillClick(1) end
    self.BtnGeneralSkill2.CallBack = function() self:OnBtnGeneralSkillClick(2) end
    self.BtnOverrunBlind.CallBack = function() self:OnBtnWeaponOverrunClick() end
    for slot = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        local resonanceSlot = slot
        self["BtnWeaponResonance" .. slot].CallBack = function() self:OnBtnWeaponResonanceClick(resonanceSlot) end
    end
end

---@param recommendCharData XTeamRecommendCharData 归一化推荐角色数据（由 XTeamRecommendAgency:FromCfgData/FromServerData 生成）
---@param targetName string|nil 卡片标题
---@param isShowSixStarWeaponTag boolean|nil 是否显示6星武器标签
---@param formationGridData table|nil 阵容目标数据；为空表示单人目标
function XUiGridTRCharTargetCard:Refresh(recommendCharData, targetName, isShowSixStarWeaponTag, formationGridData)
    self.RecommendCharData = recommendCharData
    self.TargetName = targetName
    self.FormationGridData = formationGridData

    local characterId = recommendCharData.CharacterId

    -- 卡片标题
    if self.TxtCardTitle then
        self.TxtCardTitle.text = targetName
    end

    -- 头像
    self.RImgHead:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyImage(characterId))

    -- 品质
    self.RImgCharacterRank:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(recommendCharData.Quality))

    -- 机体名
    self.TxtName.text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)

    -- 元素
    local elementList = XMVCA.XCharacter:GetCharacterAllElement(characterId, true)
    for i = 1, 3 do
        local rImg = self["RImgCharElement" .. i]
        if rImg then
            if elementList and elementList[i] then
                rImg.gameObject:SetActiveEx(true)
                local elementConfig = XMVCA.XCharacter:GetCharElement(elementList[i])
                rImg:SetRawImage(elementConfig.Icon)
            else
                rImg.gameObject:SetActiveEx(false)
            end
        end
    end

    -- 机制
    local charSkillIds = XMVCA.XCharacter:GetCharacterGeneralSkillIds(characterId)
    self.GeneralSkillIds = charSkillIds
    local generalSkillConfigs = XMVCA.XCharacter:GetModelCharacterGeneralSkill()
    for i = 1, 2 do
        local btnGeneralSkill = self["BtnGeneralSkill" .. i]
        if btnGeneralSkill then
            local id = charSkillIds and charSkillIds[i]
            if id then
                local generalSkillConfig = generalSkillConfigs[id]
                btnGeneralSkill:SetRawImage(generalSkillConfig.Icon)
            end
            btnGeneralSkill.gameObject:SetActiveEx(id ~= nil)
        end
    end

    -- 武器（用XUiGridCommon按TemplateId展示）
    local XUiGridCommon = require("XUi/XUiObtain/XUiGridCommon")
    ---@type XUiGridCommon
    self.WeaponGrid = self.WeaponGrid or XUiGridCommon.New(self.Parent, self.GridWeapon)
    local weaponId = recommendCharData.WeaponId
    if XTool.IsNumberValid(weaponId) then
        self.WeaponGrid:Refresh(weaponId)
        local candidateEquipId = XMVCA.XTeamRecommend:GetRecommendEquipCandidate(weaponId, characterId)
        self.WeaponGrid.ImgMask.gameObject:SetActiveEx(not XTool.IsNumberValid(candidateEquipId))
    end

    -- 辅助机
    local partnerId = recommendCharData.PartnerId
    local hasPartner = XTool.IsNumberValid(partnerId)
    self.PartnerUiObj.ImgNone.gameObject:SetActiveEx(not hasPartner)
    self.PartnerUiObj.RImgHeadIcon.gameObject:SetActiveEx(hasPartner)
    self.PartnerUiObj.RImgQuality.gameObject:SetActiveEx(hasPartner)
    self.PartnerUiObj.ImgMask.gameObject:SetActiveEx(hasPartner and not XDataCenter.PartnerManager.CheckIsOwnPartnerByTemplateId(partnerId))
    if hasPartner then
        local quality = XPartnerConfigs.GetQualityLimit(partnerId) or XPartnerConfigs.GetPartnerTemplateQuality(partnerId)
        self.PartnerUiObj.RImgHeadIcon:SetRawImage(XPartnerConfigs.GetPartnerTemplateIcon(partnerId))
        self.PartnerUiObj.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(quality))
    end

    -- 武器共鸣
    local weaponResonanceList = recommendCharData.WeaponResonanceList or {}
    for i = 1, 3 do
        local btn = self["BtnWeaponResonance" .. i]
        if btn then
            local entry = weaponResonanceList[i]
            if entry and XTool.IsNumberValid(entry.SkillId) then
                local skillInfo = XMVCA.XEquip:CreateResonanceSkillInfo(entry.ResonanceType, entry.SkillId)
                if skillInfo and skillInfo.Icon then
                    btn:SetRawImage(skillInfo.Icon)
                end
                btn:SetButtonState(CS.UiButtonState.Normal)
            else
                btn:SetButtonState(CS.UiButtonState.Disable)
            end
        end
    end

    -- 武器谐振
    local btnOverrun = self.BtnOverrunBlind
    if btnOverrun then
        local overrunSuitId = recommendCharData.WeaponOverrunChoseSuit
        local isShowOverrunLevel = XTool.IsNumberValid(overrunSuitId)
        self.OverrunLevelUiObj.PanelLevelIcon.gameObject:SetActiveEx(isShowOverrunLevel)
        if isShowOverrunLevel then
            local isLevel2 = XMVCA.XEquip:IsHasOverrunLevel2(weaponId, characterId)
            self.OverrunLevelUiObj.UiTxtLevelImg1.gameObject:SetActiveEx(not isLevel2)
            self.OverrunLevelUiObj.UiTxtLevelImg2.gameObject:SetActiveEx(isLevel2)
            local icon = XMVCA.XEquip:GetEquipSuitIconPath(overrunSuitId)
            if icon then
                btnOverrun:SetRawImage(icon)
                btnOverrun:SetButtonState(CS.UiButtonState.Normal)
            else
                btnOverrun:SetButtonState(CS.UiButtonState.Disable)
            end
        else
            btnOverrun:SetButtonState(CS.UiButtonState.Disable)
        end
    end

    -- 意识格子（直接使用归一化后的SuitDataList）
    local suitDataList = recommendCharData.SuitDataList or {}
    for i, grid in ipairs(self.AwarenessGridList) do
        grid.GameObject:SetActiveEx(false)
    end
    for i, data in ipairs(suitDataList) do
        local grid = self.AwarenessGridList[i]
        if not grid then
            -- 原节点仅作为干净模板，避免前一个套装运行期生成的共鸣技能节点被后续套装一并克隆。
            local go = XUiHelper.Instantiate(self.GridAwarenessItem, self.GridAwarenessItem.transform.parent)
            grid = XUiGridTRTargetAwarenessSuit.New(go, self)
            self.AwarenessGridList[i] = grid
        end
        grid.GameObject:SetActiveEx(true)
        grid:Refresh(data.SuitId, data.Count, data.SortedSkillList)
    end

    self:RefreshTargetState(recommendCharData, isShowSixStarWeaponTag)
end

function XUiGridTRCharTargetCard:RefreshTargetState(recommendCharData, isShowSixStarWeaponTag)
    local isUsing = self:GetIsUsingTarget(recommendCharData)
    local characterId = recommendCharData and recommendCharData.CharacterId
    local isOwnCharacter = XMVCA.XCharacter:IsOwnCharacter(characterId)
    local isShowWeaponTag = false

    if isShowSixStarWeaponTag then
        isShowWeaponTag = XMVCA.XTeamRecommend:IsShowCharacterTargetSixStarWeaponTag(recommendCharData)
    end

    self.IsUsingTarget = isUsing
    self.IsOwnCharacter = isOwnCharacter

    self:RefreshTargetButtons(isUsing, isOwnCharacter, isShowWeaponTag)

    if self.TagUsing then
        self.TagUsing.gameObject:SetActiveEx(isUsing)
    end
end

function XUiGridTRCharTargetCard:GetIsUsingTarget(recommendCharData)
    if self.Parent and self.Parent.IsTeamRecommendCharUsingTarget then
        return self.Parent:IsTeamRecommendCharUsingTarget(recommendCharData)
    end

    return XMVCA.XTeamRecommend:IsCharacterTargetUsing(recommendCharData)
end

function XUiGridTRCharTargetCard:RefreshTargetButtons(isUsing, isOwnCharacter, isShowWeaponTag)
    local showBtnSet = isOwnCharacter and not isUsing
    local showBtnGo = isOwnCharacter and isUsing
    local showBtnGetRole = not isOwnCharacter

    if self.BtnSet then
        self.BtnSet.gameObject:SetActiveEx(showBtnSet)
        self.BtnSet:SetButtonState(CS.UiButtonState.Normal)
        self.BtnSet:ShowTag(showBtnSet and isShowWeaponTag or false)
    end

    if self.BtnGo then
        self.BtnGo.gameObject:SetActiveEx(showBtnGo)
    end

    if self.BtnGetRole then
        self.BtnGetRole.gameObject:SetActiveEx(showBtnGetRole)
    end
end

function XUiGridTRCharTargetCard:OnBtnHeadClick()
    -- 详情页只展示已设目标的培养详情，未设目标的角色不进
    local characterId = self.RecommendCharData and self.RecommendCharData.CharacterId
    if not XMVCA.XTeamRecommend:GetServerCharacterTarget(characterId) then
        return
    end

    self:OpenRoleTargetDetail()
end

local function GetFormationTargetDesc(formationGridData)
    local descList = {}
    local formationCfg = formationGridData.Formation
    if formationCfg.StageType == XEnumConst.FuBen.StageType.BossSingle then
        table.insert(descList, XUiHelper.GetText("TeamRecommendStageTypeBossSingle"))
    elseif formationCfg.StageType == XEnumConst.FuBen.StageType.Arena then
        table.insert(descList, XUiHelper.GetText("TeamRecommendStageTypeArena"))
    end
    if not string.IsNilOrEmpty(formationGridData.BaseFormation.Desc) then
        table.insert(descList, formationGridData.BaseFormation.Desc)
    end
    for _, tag in ipairs(formationCfg.Tags) do
        if not string.IsNilOrEmpty(tag) then
            table.insert(descList, tag)
        end
    end
    return table.concat(descList, "-")
end

function XUiGridTRCharTargetCard:OnBtnSetClick()
    if not self.RecommendCharData then
        return
    end

    if not self.IsOwnCharacter then
        self:OnBtnGetRoleClick()
        return
    end

    if self.IsUsingTarget then
        self:OnBtnGoClick()
        return
    end

    -- 已达目标设定上限且本次为新增目标（切换已有目标不拦截）：不发设目标请求，二次确认后打开共鸣目标列表首位角色目标详情
    local characterId = self.RecommendCharData.CharacterId
    local oldTarget = XMVCA.XTeamRecommend:GetServerCharacterTarget(characterId)
    local isLimitReached = #XMVCA.XTeamRecommend:GetServerCharacterTargetList() >= XMVCA.XTeamRecommend:GetCharacterTargetLimit()
    if isLimitReached and not oldTarget then
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("TeamRecommendTargetLimitReached"), XUiManager.DialogType.Normal, nil, handler(self, self.OpenFirstRoleTargetDetail))
        return
    end

    -- 已有旧目标时，弹窗确认从旧目标切换到当前卡片目标。
    if oldTarget then
        local oldTargetDesc
        if XTool.IsNumberValid(oldTarget.BaseCharacterId) then
            local oldTargetData = XMVCA.XTeamRecommend:BuildRoleTargetDetailData(characterId)
            oldTargetDesc = XUiHelper.GetText("TeamRecommendCharacterTargetDesc", oldTargetData.TargetName)
        else
            oldTargetDesc = GetFormationTargetDesc(XMVCA.XTeamRecommend:BuildFormationTargetGridData(characterId))
        end
        local newTargetDesc
        if self.FormationGridData then
            newTargetDesc = GetFormationTargetDesc(self.FormationGridData)
        else
            newTargetDesc = XUiHelper.GetText("TeamRecommendCharacterTargetDesc", self.TargetName)
        end
        if string.IsNilOrEmpty(oldTargetDesc) or string.IsNilOrEmpty(newTargetDesc) then
            XLog.Error("[XUiGridTRCharTargetCard] Target description is empty, CharacterId = " .. tostring(characterId))
            return
        end
        local content = XUiHelper.GetText("EquipGuideChangeTargetIdenticalRoleTips", oldTargetDesc, newTargetDesc)
        XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), content, XUiManager.DialogType.Normal, nil, handler(self, self.SetTarget))
        return
    end

    self:SetTarget()
end

function XUiGridTRCharTargetCard:SetTarget()
    if self.Parent and self.Parent.OnTeamRecommendCharSetTarget then
        self.Parent:OnTeamRecommendCharSetTarget(self.RecommendCharData)
    end
end

--- 达上限二次确认：打开共鸣目标列表首位角色的目标详情
function XUiGridTRCharTargetCard:OpenFirstRoleTargetDetail()
    local firstTarget = XMVCA.XTeamRecommend:GetServerCharacterTargetList()[1]
    local firstCharacterId = firstTarget and firstTarget.CharacterId
    if XTool.IsNumberValid(firstCharacterId) then
        XLuaUiManager.Open("UiTeamRecommendRoleTargetDetail", firstCharacterId)
    end
end

function XUiGridTRCharTargetCard:OnBtnGoClick()
    self:OpenRoleTargetDetail()
end

function XUiGridTRCharTargetCard:OnBtnGetRoleClick()
    local characterId = self.RecommendCharData and self.RecommendCharData.CharacterId
    if not XTool.IsNumberValid(characterId) then
        return
    end

    local fragmentItemId = XMVCA.XCharacter:GetCharacterItemId(characterId)
    if XTool.IsNumberValid(fragmentItemId) then
        XLuaUiManager.Open("UiTip", XDataCenter.ItemManager.GetItem(fragmentItemId))
    end
end

function XUiGridTRCharTargetCard:OnBtnElementDetailClick()
    local characterId = self.RecommendCharData and self.RecommendCharData.CharacterId
    if not XTool.IsNumberValid(characterId) then
        return
    end

    XLuaUiManager.Open("UiCharacterAttributeDetail", characterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.Element)
end

function XUiGridTRCharTargetCard:OnBtnGeneralSkillClick(index)
    local characterId = self.RecommendCharData and self.RecommendCharData.CharacterId
    if not XTool.IsNumberValid(characterId) then
        return
    end

    local generalSkillId = self.GeneralSkillIds and self.GeneralSkillIds[index]
    if not XTool.IsNumberValid(generalSkillId) then
        return
    end

    XLuaUiManager.Open("UiCharacterAttributeDetail", characterId, XEnumConst.UiCharacterAttributeDetail.BtnTab.GeneralSkill, index)
end

-- 查找聚合共鸣技能首个对应意识槽
function XUiGridTRCharTargetCard:GetFirstAwarenessResonancePosition(suitId, skillData)
    local awarenessSlotList = self.RecommendCharData and self.RecommendCharData.AwarenessSlotList or {}
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local targetSlotData = awarenessSlotList[site]
        if targetSlotData and targetSlotData.SuitId == suitId then
            for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
                local resonanceData = targetSlotData.ResonanceList and targetSlotData.ResonanceList[pos]
                if resonanceData and resonanceData.SkillId == skillData.SkillId and resonanceData.ResonanceType == skillData.ResonanceType then
                    return site, pos
                end
            end
        end
    end
end

-- 打开共用角色卡的意识共鸣技能详情
function XUiGridTRCharTargetCard:OnAwarenessResonanceSkillClick(suitId, skillData)
    local site, pos = self:GetFirstAwarenessResonancePosition(suitId, skillData)
    if site then
        XLuaUiManager.Open("UiTeamRecommendResonanceSkillPopup", self.RecommendCharData, site, pos)
    end
end

-- 打开推荐武器共鸣技能详情
function XUiGridTRCharTargetCard:OnBtnWeaponResonanceClick(slot)
    local resonanceData = self.RecommendCharData and self.RecommendCharData.WeaponResonanceList[slot]
    if resonanceData then
        XLuaUiManager.Open("UiTeamRecommendWeaponResonanceDetailPopup", self.RecommendCharData, slot)
    end
end

-- 打开推荐武器谐振预览
function XUiGridTRCharTargetCard:OnBtnWeaponOverrunClick()
    if XTool.IsNumberValid(self.RecommendCharData and self.RecommendCharData.WeaponOverrunChoseSuit) then
        XLuaUiManager.Open("UiTeamRecommendEquipOverrunSelect", self.RecommendCharData)
    end
end

-- 打开推荐辅助机预览
function XUiGridTRCharTargetCard:OnBtnPartnerClick()
    local partnerId = self.RecommendCharData and self.RecommendCharData.PartnerId
    if not XTool.IsNumberValid(partnerId) then
        return
    end

    local partnerData = { Id = 0, TemplateId = partnerId }
    local partner = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData, true)
    XLuaUiManager.Open("UiPartnerPreview", partner)
end

-- 详情页只按 characterId 展示该角色的已存目标，展示数据由详情页自己从目标缓存还原
function XUiGridTRCharTargetCard:OpenRoleTargetDetail()
    local characterId = self.RecommendCharData and self.RecommendCharData.CharacterId
    if XTool.IsNumberValid(characterId) then
        XLuaUiManager.Open("UiTeamRecommendRoleTargetDetail", characterId)
    end
end

return XUiGridTRCharTargetCard
