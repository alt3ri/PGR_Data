---@class XUiTeamRecommendRoleTargetDetail : XLuaUi
--- 详情页只展示已存目标：主数据每次 Refresh 按 CharacterId 现取 BuildRoleTargetDetailData——
--- 单人目标由 BaseCharacterId 走 FromCfgData 还原死配置；阵容目标由 TargetFormation（或 BaseFormationId 回表还原）走 FromServerData 归一化。
--- 穿戴/候选/共鸣/超频等运行态一律现查 XEquip/XPartner；排行榜快照（ServerFormation）与本界面无关。
local XUiTeamRecommendRoleTargetDetail = XLuaUiManager.Register(XLuaUi, "UiTeamRecommendRoleTargetDetail")

function XUiTeamRecommendRoleTargetDetail:OnAwake()
    self.IsHaveCallOnEnable = false
    self:InitUi()
    self:InitButton()
end

function XUiTeamRecommendRoleTargetDetail:OnStart(characterId)
    self.CharacterId = characterId
    self:Refresh()
end

--- 从上层界面（切换套装进Main等）返回时按最新目标缓存全量刷新
function XUiTeamRecommendRoleTargetDetail:OnEnable()
    if not self.IsHaveCallOnEnable then
        self.IsHaveCallOnEnable = true
        return
    end

    self:Refresh()
    if self.PanelLeftSwitch.gameObject.activeSelf then
        self:RefreshLeftSwitch()
    end
end

function XUiTeamRecommendRoleTargetDetail:InitUi()
    self.WeaponResonanceGridList = {}
    self.AwarenessEquipGridList = {}
    self.AwarenessResonanceGroupList = {}
    self.LeftSwitchRoleGridList = {}

    self.PanelLeftSwitchUiObj = XTool.InitUiObjectByUi({}, self.PanelLeftSwitch)
    self.LeftSwitchRoleTemplate = self.PanelLeftSwitchUiObj.GridRole
    self.PanelEquipmentUiObj = XTool.InitUiObjectByUi({}, self.PanelEquipment)
    self.PanelBubbleDetail:GetObject("UiTxtDesc").text = XUiHelper.GetText("TeamRecommendRoleTargetDetailDesc")

    self.PanelBubbleDetail.gameObject:SetActiveEx(false)
    self.PanelLeftSwitch.gameObject:SetActiveEx(false)
    self.LeftSwitchRoleTemplate.gameObject:SetActiveEx(false)
    if self.PanelEquipmentUiObj.WeaponRecommendLong then
        self.PanelEquipmentUiObj.WeaponRecommendLong.gameObject:SetActiveEx(false)
    end
    if self.PanelEquipmentUiObj.PanelWeaponPartner then
        self.PanelEquipmentUiObj.PanelWeaponPartner.gameObject:SetActiveEx(true)
    end

    self.WeaponUiObj = self.PanelEquipmentUiObj.WeaponRecommendShort and XTool.InitUiObjectByUi({}, self.PanelEquipmentUiObj.WeaponRecommendShort) or nil
    self.PartnerUiObj = self.PanelEquipmentUiObj.PartnerRecommend and XTool.InitUiObjectByUi({}, self.PanelEquipmentUiObj.PartnerRecommend) or nil
    self.AwarenessUiObj = self.PanelEquipmentUiObj.PanelAwareness and XTool.InitUiObjectByUi({}, self.PanelEquipmentUiObj.PanelAwareness) or nil

    self:InitWeaponUiObj()
    self:InitPartnerUiObj()
    self:InitAwarenessUiObj()
end

function XUiTeamRecommendRoleTargetDetail:InitButton()
    self.BtnBack.CallBack = function() self:Close() end
    self.BtnMainUi.CallBack = function() XLuaUiManager.RunMain() end
    self.BtnDetailClose.CallBack = function() self.PanelBubbleDetail.gameObject:SetActiveEx(false) end
    self.BtnNumDesc.CallBack = function() self.PanelBubbleDetail.gameObject:SetActiveEx(true) end
    self.BtnEvolution.CallBack = function() self:OnBtnEvolutionClick() end
    self.BtnLeftSwitch.CallBack = function() self:OnBtnLeftSwitchClick() end
    self.PanelLeftSwitchUiObj.BtnCloseLeftPanel.CallBack = function() self:OnBtnCloseLeftPanelClick() end
    self.PanelEquipmentUiObj.BtnSwitch.CallBack = function() self:OnBtnSwitchClick() end
    self.PanelEquipmentUiObj.BtnDelete.CallBack = function() self:OnBtnDeleteClick() end
end

function XUiTeamRecommendRoleTargetDetail:InitWeaponUiObj()
    local XUiGridTRTargetDetailWeaponEquip = require("XUi/XUiTeamRecommend/Grid/XUiGridTRTargetDetailWeaponEquip")
    self.WeaponUiObj.EquipGrid = XUiGridTRTargetDetailWeaponEquip.New(self.WeaponUiObj.GridEquip, self)
    self.WeaponOverrunLevelUiObj = XTool.InitUiObjectByUi({}, self.WeaponUiObj.BtnOverrunBlind)

    self.WeaponUiObj.BtnObtain.CallBack = function() self:OnBtnWeaponObtainClick() end
    self.WeaponUiObj.BtnWear.CallBack = function() self:OnBtnWeaponWearClick() end
    self.WeaponUiObj.BtnUpgrade.CallBack = function() self:OnBtnWeaponUpgradeClick() end
    self.WeaponUiObj.BtnOverrunBlind.CallBack = function() self:OnBtnWeaponOverrunClick() end

    self.WeaponUiObj.BtnEquipResonance1.gameObject:SetActiveEx(false)
    self.WeaponUiObj.BtnAchieve.gameObject:SetActiveEx(false)
end

-- 打开推荐武器谐振预览
function XUiTeamRecommendRoleTargetDetail:OnBtnWeaponOverrunClick()
    if XTool.IsNumberValid(self.RecommendCharData and self.RecommendCharData.WeaponOverrunChoseSuit) then
        local equip = XMVCA.XEquip:GetCharacterWeapon(self.RecommendCharData.CharacterId)
        if not equip then
            return
        end
        XLuaUiManager.Open("UiEquipOverrunSelect", equip.Id, nil, true, self.RecommendCharData.WeaponOverrunChoseSuit)
    end
end

function XUiTeamRecommendRoleTargetDetail:InitPartnerUiObj()
    self.PartnerUiObj.BtnObtain.CallBack = function() self:OnBtnPartnerObtainClick() end
    self.PartnerUiObj.BtnWear.CallBack = function() self:OnBtnPartnerWearClick() end
    self.PartnerUiObj.BtnUpgrade.CallBack = function() self:OnBtnPartnerUpgradeClick() end
    self.PartnerUiObj.BtnPanelPartner.CallBack = function() self:OnBtnPartnerClick() end
    self.PartnerUiObj.BtnAchieve.gameObject:SetActiveEx(false)
end

function XUiTeamRecommendRoleTargetDetail:InitAwarenessUiObj()
    if self.AwarenessUiObj.PanelListResonance then
        self.AwarenessUiObj.PanelListResonance.CallBack = function() self:OnBtnAwarenessResonanceClick() end
    end
    self.AwarenessUiObj.BtnWear.CallBack = function() self:OnBtnAwarenessWearClick() end
    self.AwarenessUiObj.BtnGet.CallBack = function() self:OnBtnAwarenessGetClick() end
    self.AwarenessUiObj.BtnCultivate.CallBack = function() self:OnBtnAwarenessCultivateClick() end

    self.AwarenessUiObj.GridPanelEquip.gameObject:SetActiveEx(false)
    self.AwarenessUiObj.GridPanelResonance.gameObject:SetActiveEx(false)
    self.AwarenessUiObj.GridResonanceSkill.gameObject:SetActiveEx(false)
end

function XUiTeamRecommendRoleTargetDetail:Refresh()
    -- 详情页只展示已存目标：每次刷新按角色现取最新目标缓存，取不到（目标已删）则关闭
    local roleTargetDetailData = XMVCA.XTeamRecommend:BuildRoleTargetDetailData(self.CharacterId)
    if not roleTargetDetailData then
        self:Close()
        return
    end

    self.RecommendCharData = roleTargetDetailData.RecommendCharData
    self.TargetName = roleTargetDetailData.TargetName

    -- 角色信息
    self:RefreshRole()

    -- 标题信息
    self:RefreshEquipment()

    -- 武器推荐
    self:RefreshWeapon()

    -- 辅助机推荐
    self:RefreshPartner()

    -- 意识推荐
    self:RefreshAwareness()

    -- 当前角色已经直接展示装备红点；切换入口只提示其他角色的可穿戴项
    self.BtnLeftSwitch:ShowReddot(XMVCA.XTeamRecommend:CheckHasTargetEquipCanWear(self.CharacterId))
end

function XUiTeamRecommendRoleTargetDetail:RefreshRole()
    local characterId = self.RecommendCharData.CharacterId

    -- 基础信息
    self.TxtName.text = XMVCA.XCharacter:GetCharacterFullNameStr(characterId)
    self.TxtPowerNum.text = tostring(XMVCA.XCharacter:GetCharacterHaveRobotAbilityById(characterId) or 0)

    -- 立绘品质
    if self.RImgRole then
        self.RImgRole:SetRawImage(XMVCA.XCharacter:GetCharHalfBodyImage(characterId))
    end
    local currentQuality = XMVCA.XCharacter:GetCharacterQuality(characterId) or self.RecommendCharData.Quality
    if self.RImgCharacterRank then
        self.RImgCharacterRank:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(currentQuality))
    end
    self.BtnEvolution:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(self.RecommendCharData.Quality))

    -- 目标进度
    local progress = XMVCA.XTeamRecommend:GetServerCharacterTargetProgressAndCheckFinish(self.RecommendCharData)
    self.TxtProgress.text = tostring(math.floor(progress * 100)) .. "%"
    if self.ImgProgress then
        self.ImgProgress.fillAmount = progress
    end
    -- TODO: 修改共鸣预期接入后，完成度需支持任意攻击/任意技能的通配匹配。
end

function XUiTeamRecommendRoleTargetDetail:RefreshEquipment()
    self.PanelEquipmentUiObj.TxtTeamName.text = self.TargetName or ""

    -- 详情页只展示已存目标，删除入口常显
    self.PanelEquipmentUiObj.BtnDelete.gameObject:SetActiveEx(true)

    -- 详情页只展示已存目标，不存在“展示方案≠已存方案”的比较场景，6星武器切换标签恒隐藏。
    self.PanelEquipmentUiObj.BtnSwitch:ShowTag(false)
end

--- 目标武器的可穿戴候选装备id；无候选返回nil
function XUiTeamRecommendRoleTargetDetail:GetWeaponCandidate()
    return XMVCA.XTeamRecommend:GetRecommendEquipCandidate(self.RecommendCharData.WeaponId, self.RecommendCharData.CharacterId)
end

--- 目标辅助机的可携带候选实体：当前角色已携带的同模板，或角色类型可携带且未被他人携带的最优实例
---@return table|nil candidatePartner 候选辅助机实体
---@return boolean isCarried 候选是否已由当前角色携带
function XUiTeamRecommendRoleTargetDetail:GetPartnerCandidate()
    return XMVCA.XTeamRecommend:GetRecommendPartnerCandidate(self.RecommendCharData.PartnerId, self.RecommendCharData.CharacterId)
end

--- 目标意识槽的目标配置（模板/套装/目标共鸣）；无目标返回nil
function XUiTeamRecommendRoleTargetDetail:GetAwarenessTargetSlotData(site)
    local awarenessTargetSlotList = self.RecommendCharData.AwarenessSlotList or {}
    local targetSlotData = awarenessTargetSlotList[site]
    if targetSlotData and XTool.IsNumberValid(targetSlotData.EquipTemplateId) then
        return targetSlotData
    end
end

--- 目标意识的可穿戴候选装备id；无目标或无候选返回nil
function XUiTeamRecommendRoleTargetDetail:GetAwarenessCandidate(site)
    local targetSlotData = self:GetAwarenessTargetSlotData(site)
    if not targetSlotData then
        return nil
    end
    return XMVCA.XTeamRecommend:GetRecommendEquipCandidate(targetSlotData.EquipTemplateId, self.RecommendCharData.CharacterId)
end

--- 当前角色在该意识位穿的就是目标模板时返回穿戴装备id（与完成度公式同源）；否则nil
function XUiTeamRecommendRoleTargetDetail:GetWearingAwarenessEquipId(site)
    local targetSlotData = self:GetAwarenessTargetSlotData(site)
    if not targetSlotData then
        return nil
    end

    local wearingEquipId = XMVCA.XEquip:GetCharacterEquipId(self.RecommendCharData.CharacterId, site)
    if not XTool.IsNumberValid(wearingEquipId) then
        return nil
    end

    local wearingEquip = XMVCA.XEquip:GetEquip(wearingEquipId)
    if wearingEquip and wearingEquip.TemplateId == targetSlotData.EquipTemplateId then
        return wearingEquipId
    end
end

function XUiTeamRecommendRoleTargetDetail:RefreshWeapon()
    local recommendCharData = self.RecommendCharData
    local weaponId = recommendCharData.WeaponId

    if not XTool.IsNumberValid(weaponId) then
        self.WeaponUiObj.GameObject:SetActiveEx(false)
        return
    end

    self.WeaponUiObj.GameObject:SetActiveEx(true)

    local resonanceList = recommendCharData.WeaponResonanceList or {}
    local candidateEquipId = self:GetWeaponCandidate()
    local hasCandidate = XTool.IsNumberValid(candidateEquipId)
    local isWearing = hasCandidate and XMVCA.XEquip:IsEquipWearingByCharacterId(candidateEquipId, recommendCharData.CharacterId)

    -- 基础信息
    self.WeaponUiObj.TxtWeaponName.text = XMVCA.XEquip:GetEquipName(weaponId)

    -- 武器格
    if self.WeaponUiObj.EquipGrid then
        local wearingResonanceCount = isWearing and (XMVCA.XEquip:GetEquipResonanceCount(candidateEquipId) or 0) or 0
        self.WeaponUiObj.EquipGrid:Refresh(weaponId, wearingResonanceCount, isWearing and candidateEquipId or nil)
    end

    -- 共鸣技能
    local targetSkillList = {}
    for index = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        local resonanceData = resonanceList[index]
        targetSkillList[index] = resonanceData and resonanceData.SkillId or 0
    end
    local resonanceStateList = XMVCA.XTeamRecommend:BuildWeaponResonanceTargetStateList(isWearing and candidateEquipId or nil, recommendCharData.CharacterId, targetSkillList)
    for index = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        local btn = self.WeaponResonanceGridList[index]
        if not btn then
            local go = XUiHelper.Instantiate(self.WeaponUiObj.BtnEquipResonance1.gameObject, self.WeaponUiObj.BtnEquipResonance1.transform.parent)
            btn = go:GetComponent("XUiButton")
            local slot = index
            btn.CallBack = function() self:OnBtnWeaponResonanceClick(slot) end
            self.WeaponResonanceGridList[index] = btn
        end

        btn.gameObject:SetActiveEx(true)

        local resonanceData = resonanceList[index]
        local skillInfo = resonanceData and XMVCA.XEquip:CreateResonanceSkillInfo(resonanceData.ResonanceType, resonanceData.SkillId) or nil
        if skillInfo and skillInfo.Icon then
            btn:SetRawImage(skillInfo.Icon)
            btn:SetButtonState(CS.UiButtonState.Normal)
        else
            btn:SetButtonState(CS.UiButtonState.Disable)
        end

        -- 压黑：目标技能未在当前穿戴武器的共鸣中达成（不要求与目标列表处于相同槽位）
        local imgMask = XTool.InitUiObjectByUi({}, btn.gameObject).ImgMask
        if imgMask then
            local resonanceState = resonanceStateList[index]
            local isAchieved = resonanceState and resonanceState.IsComplete
            imgMask.gameObject:SetActiveEx(skillInfo ~= nil and not isAchieved)
        end
    end
    if self.WeaponUiObj.BtnOverrunBlind then
        self.WeaponUiObj.BtnOverrunBlind.transform:SetAsLastSibling()
    end

    -- 谐振
    local suitId = recommendCharData.WeaponOverrunChoseSuit
    local isShowOverrunLevel = XTool.IsNumberValid(suitId)
    self.WeaponOverrunLevelUiObj.PanelLevelIcon.gameObject:SetActiveEx(isShowOverrunLevel)
    if isShowOverrunLevel then
        local suitIcon = XMVCA.XEquip:GetEquipSuitIconPath(suitId)
        local isLevel2 = XMVCA.XEquip:IsHasOverrunLevel2(weaponId, recommendCharData.CharacterId)
        self.WeaponOverrunLevelUiObj.UiTxtLevelImg1.gameObject:SetActiveEx(not isLevel2)
        self.WeaponOverrunLevelUiObj.UiTxtLevelImg2.gameObject:SetActiveEx(isLevel2)
        self.WeaponUiObj.BtnOverrunBlind:SetRawImage(suitIcon)
        self.WeaponUiObj.BtnOverrunBlind:SetButtonState(CS.UiButtonState.Normal)

        local wearingWeapon = XMVCA.XEquip:GetCharacterWeapon(recommendCharData.CharacterId)
        local isOverrunAchieved = wearingWeapon and wearingWeapon.TemplateId == weaponId
                and wearingWeapon:GetOverrunChoseSuit() == suitId
                and wearingWeapon:IsOverrunBlindMatch(recommendCharData.CharacterId)
        local noOverrunUiObj = self.WeaponOverrunLevelUiObj.NoOverrun
        if noOverrunUiObj then
            noOverrunUiObj.gameObject:SetActiveEx(not isOverrunAchieved)
        end
    else
        self.WeaponUiObj.BtnOverrunBlind:SetButtonState(CS.UiButtonState.Disable)
        if self.WeaponOverrunLevelUiObj.NoOverrun then
            self.WeaponOverrunLevelUiObj.NoOverrun.gameObject:SetActiveEx(false)
        end
    end

    -- 按钮状态
    local weaponProgressInfo = XMVCA.XTeamRecommend:GetCharacterTargetWeaponProgressInfo(recommendCharData)
    local isModuleAchieved = weaponProgressInfo.IsModuleAchieved
    self.WeaponUiObj.PanelUnOwn.gameObject:SetActiveEx(not isWearing)
    self.WeaponUiObj.BtnObtain.gameObject:SetActiveEx(not hasCandidate)
    self.WeaponUiObj.BtnWear.gameObject:SetActiveEx(hasCandidate and not isWearing)
    self.WeaponUiObj.BtnWear:ShowReddot(hasCandidate and not isWearing)
    self.WeaponUiObj.BtnUpgrade.gameObject:SetActiveEx(isWearing and not isModuleAchieved)
    self.WeaponUiObj.BtnAchieve.gameObject:SetActiveEx(isWearing and isModuleAchieved)
end

-- 打开推荐武器共鸣技能详情
function XUiTeamRecommendRoleTargetDetail:OnBtnWeaponResonanceClick(slot)
    local resonanceData = self.RecommendCharData and self.RecommendCharData.WeaponResonanceList[slot]
    if resonanceData then
        XLuaUiManager.Open("UiTeamRecommendWeaponResonanceDetailPopup", self.RecommendCharData, slot)
    end
end

function XUiTeamRecommendRoleTargetDetail:RefreshPartner()
    local recommendCharData = self.RecommendCharData
    local partnerId = recommendCharData.PartnerId
    local hasPartner = XTool.IsNumberValid(partnerId)

    self.PartnerUiObj.GameObject:SetActiveEx(true)
    self.PartnerUiObj.ImgNone.gameObject:SetActiveEx(not hasPartner)
    self.PartnerUiObj.RImgHeadIcon.gameObject:SetActiveEx(hasPartner)
    self.PartnerUiObj.RImgQuality.gameObject:SetActiveEx(hasPartner)
    self.PartnerUiObj.TxtWeaponName.gameObject:SetActiveEx(hasPartner)

    if not hasPartner then
        self.PartnerUiObj.ImgMedalIconlock.gameObject:SetActiveEx(false)
        self.PartnerUiObj.BtnObtain.gameObject:SetActiveEx(false)
        self.PartnerUiObj.BtnWear.gameObject:SetActiveEx(false)
        self.PartnerUiObj.BtnUpgrade.gameObject:SetActiveEx(false)
        self.PartnerUiObj.BtnAchieve.gameObject:SetActiveEx(false)
        return
    end

    local candidatePartner, isCarried = self:GetPartnerCandidate()
    local hasCandidate = candidatePartner ~= nil
    local quality = isCarried and candidatePartner:GetQuality() or XPartnerConfigs.GetQualityLimit(partnerId) or XPartnerConfigs.GetPartnerTemplateQuality(partnerId)

    -- 基础信息
    self.PartnerUiObj.TxtWeaponName.text = XPartnerConfigs.GetPartnerTemplateName(partnerId)
    self.PartnerUiObj.RImgHeadIcon:SetRawImage(XPartnerConfigs.GetPartnerTemplateIcon(partnerId))
    self.PartnerUiObj.RImgQuality:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(quality))

    -- 按钮状态
    local isAllCultureMax = isCarried and XMVCA.XPartner:GetOneKeyCultureAgency():IsPartnerAllCultureMax(candidatePartner:GetId())
    self.PartnerUiObj.ImgMedalIconlock.gameObject:SetActiveEx(not isCarried)
    self.PartnerUiObj.BtnObtain.gameObject:SetActiveEx(not hasCandidate)
    self.PartnerUiObj.BtnWear.gameObject:SetActiveEx(hasCandidate and not isCarried)
    self.PartnerUiObj.BtnWear:ShowReddot(hasCandidate and not isCarried)
    self.PartnerUiObj.BtnUpgrade.gameObject:SetActiveEx(isCarried and not isAllCultureMax)
    self.PartnerUiObj.BtnAchieve.gameObject:SetActiveEx(isCarried and isAllCultureMax)
end

function XUiTeamRecommendRoleTargetDetail:RefreshAwareness()
    local resonanceCount = 0
    local overclockingCount = 0
    local hasTargetAwareness = false -- 是否至少配置了一个有效目标意识；没有目标时不显示任何批量操作按钮
    local hasUnwornAwareness = false -- 是否存在已有可穿戴候选、但目标角色当前尚未穿戴的意识；无候选的情况由 hasNoCandidateAwareness 处理
    local hasNoCandidateAwareness = false
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local targetSlotData = self:GetAwarenessTargetSlotData(site)
        local candidateEquipId = self:GetAwarenessCandidate(site)
        local wearingEquipId = self:GetWearingAwarenessEquipId(site)

        if targetSlotData then
            hasTargetAwareness = true
            if not XTool.IsNumberValid(candidateEquipId) then
                hasNoCandidateAwareness = true
            elseif not XTool.IsNumberValid(wearingEquipId) then
                hasUnwornAwareness = true
            end
        end

        -- 共鸣/超频统计只算当前穿戴的目标意识
        local slotResonanceCount = 0
        if wearingEquipId then
            slotResonanceCount = XMVCA.XEquip:GetEquipResonanceCount(wearingEquipId) or 0
            for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
                if XMVCA.XEquip:IsEquipPosAwaken(wearingEquipId, pos) then
                    overclockingCount = overclockingCount + 1
                end
            end
        end
        resonanceCount = resonanceCount + slotResonanceCount

        -- 意识格
        self:GetAwarenessEquipGrid(site):Refresh(targetSlotData, candidateEquipId, slotResonanceCount)

        -- 共鸣组
        self:GetAwarenessResonanceGroup(site):Refresh(targetSlotData, wearingEquipId, self.RecommendCharData.CharacterId)
    end

    -- 统计
    if self.AwarenessUiObj.TxtResonanceCount then
        self.AwarenessUiObj.TxtResonanceCount.text = tostring(resonanceCount)
    end
    if self.AwarenessUiObj.TxtOverLockingCount then
        self.AwarenessUiObj.TxtOverLockingCount.text = tostring(overclockingCount)
    end

    -- 批量操作按钮优先级：一键穿戴 > 一键获取 > 批量培养 > 达成
    local showBtnWear = hasUnwornAwareness
    local showBtnGet = not showBtnWear and hasNoCandidateAwareness
    local awarenessProgressInfo = XMVCA.XTeamRecommend:GetCharacterTargetAwarenessProgressInfo(self.RecommendCharData)
    local showBtnCompleted = hasTargetAwareness and not showBtnWear and not showBtnGet and awarenessProgressInfo.IsModuleAchieved
    local showBtnCultivate = hasTargetAwareness and not showBtnWear and not showBtnGet and not showBtnCompleted
    self.AwarenessUiObj.BtnWear.gameObject:SetActiveEx(showBtnWear)
    self.AwarenessUiObj.BtnWear:ShowReddot(showBtnWear)
    self.AwarenessUiObj.BtnGet.gameObject:SetActiveEx(showBtnGet)
    self.AwarenessUiObj.BtnCultivate.gameObject:SetActiveEx(showBtnCultivate)
    self.AwarenessUiObj.BtnCompleted.gameObject:SetActiveEx(showBtnCompleted)
end

function XUiTeamRecommendRoleTargetDetail:GetAwarenessEquipGrid(site)
    local grid = self.AwarenessEquipGridList[site]
    if grid then
        return grid
    end

    local XUiGridTRTargetDetailAwarenessEquip = require("XUi/XUiTeamRecommend/Grid/XUiGridTRTargetDetailAwarenessEquip")
    local go = XUiHelper.Instantiate(self.AwarenessUiObj.GridPanelEquip.gameObject, self.AwarenessUiObj.GridPanelEquip.transform.parent)
    grid = XUiGridTRTargetDetailAwarenessEquip.New(go, self)
    self.AwarenessEquipGridList[site] = grid

    return grid
end

function XUiTeamRecommendRoleTargetDetail:GetAwarenessResonanceGroup(site)
    local group = self.AwarenessResonanceGroupList[site]
    if group then
        return group
    end

    local XUiGridTRTargetDetailAwarenessResonanceGroup = require("XUi/XUiTeamRecommend/Grid/XUiGridTRTargetDetailAwarenessResonanceGroup")
    local go = XUiHelper.Instantiate(self.AwarenessUiObj.GridPanelResonance.gameObject, self.AwarenessUiObj.GridPanelResonance.transform.parent)
    group = XUiGridTRTargetDetailAwarenessResonanceGroup.New(go, self)
    self.AwarenessResonanceGroupList[site] = group

    return group
end

function XUiTeamRecommendRoleTargetDetail:RefreshLeftSwitch()
    local roleTargetDetailDataList = self:BuildLeftSwitchRoleTargetDetailDataList()

    if self.PanelLeftSwitchUiObj.TxtNum then
        local targetLimit = XMVCA.XTeamRecommend:GetCharacterTargetLimit()
        self.PanelLeftSwitchUiObj.TxtNum.text = string.format("%d/%d", #roleTargetDetailDataList, targetLimit)
    end

    for index, roleTargetDetailData in ipairs(roleTargetDetailDataList) do
        self:GetLeftSwitchRoleGrid(index):Refresh(roleTargetDetailData, self.CharacterId)
    end

    for index = #roleTargetDetailDataList + 1, #self.LeftSwitchRoleGridList do
        self.LeftSwitchRoleGridList[index]:Close()
    end
end

function XUiTeamRecommendRoleTargetDetail:BuildLeftSwitchRoleTargetDetailDataList()
    local result = {}
    local targetList = XMVCA.XTeamRecommend:GetServerCharacterTargetList()

    for _, targetData in ipairs(targetList or {}) do
        local characterId = targetData.CharacterId
        local roleTargetDetailData = XMVCA.XTeamRecommend:BuildRoleTargetDetailData(characterId)
        if roleTargetDetailData then
            table.insert(result, roleTargetDetailData)
        end
    end

    return result
end

function XUiTeamRecommendRoleTargetDetail:GetLeftSwitchRoleGrid(index)
    local grid = self.LeftSwitchRoleGridList[index]
    if grid then
        return grid
    end

    local XUiGridTRTargetDetailRole = require("XUi/XUiTeamRecommend/Grid/XUiGridTRTargetDetailRole")
    local template = self.LeftSwitchRoleTemplate
    local go = XUiHelper.Instantiate(template.gameObject, template.transform.parent)
    grid = XUiGridTRTargetDetailRole.New(go, self)
    self.LeftSwitchRoleGridList[index] = grid

    return grid
end

function XUiTeamRecommendRoleTargetDetail:OpenWeaponDetail(childUiIndex)
    local candidateEquipId = self:GetWeaponCandidate()
    if XTool.IsNumberValid(candidateEquipId) then
        XMVCA.XEquip:OpenUiEquipDetail(candidateEquipId, false, self.RecommendCharData.CharacterId, nil, childUiIndex)
    else
        self:OnBtnWeaponObtainClick()
    end
end

-- 当前界面按钮回调
function XUiTeamRecommendRoleTargetDetail:OnBtnLeftSwitchClick()
    self.PanelLeftSwitch.gameObject:SetActiveEx(true)
    self:RefreshLeftSwitch()
end

function XUiTeamRecommendRoleTargetDetail:CloseLeftSwitch()
    for _, grid in ipairs(self.LeftSwitchRoleGridList) do
        grid:Close()
    end
    self.PanelLeftSwitch.gameObject:SetActiveEx(false)
end

function XUiTeamRecommendRoleTargetDetail:OnBtnCloseLeftPanelClick()
    self:CloseLeftSwitch()
end

function XUiTeamRecommendRoleTargetDetail:OnBtnSwitchClick()
    XMVCA.XTeamRecommend:RecordRoleTargetDetailOperation(XGlobalVar.BtnUiTeamRecommendRoleTargetDetail.BtnSwitchPlan, self.RecommendCharData.CharacterId)
    XLuaUiManager.Open("UiTeamRecommendMain", self.RecommendCharData.CharacterId)
end

function XUiTeamRecommendRoleTargetDetail:OnBtnEvolutionClick()
    if not XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.CharacterQuality) then
        return
    end

    local characterId = self.RecommendCharData.CharacterId
    XLuaUiManager.Open("UiCharacterSystemV2P6", characterId, XEnumConst.CHARACTER.SkipEnumV2P6.Quality)
end

function XUiTeamRecommendRoleTargetDetail:OnBtnDeleteClick()
    XUiManager.DialogTip(XUiHelper.GetText("TipTitle"), XUiHelper.GetText("IsSureDelete"), XUiManager.DialogType.Normal, nil, handler(self, self.DeleteTarget))
end

function XUiTeamRecommendRoleTargetDetail:DeleteTarget()
    local characterId = self.RecommendCharData.CharacterId
    local currentIndex = 1
    for index, targetData in ipairs(XMVCA.XTeamRecommend:GetServerCharacterTargetList()) do
        if targetData.CharacterId == characterId then
            currentIndex = index
            break
        end
    end
    XMVCA.XTeamRecommend:RecordRoleTargetDetailOperation(XGlobalVar.BtnUiTeamRecommendRoleTargetDetail.BtnDeleteTarget, characterId)
    XMVCA.XTeamRecommend:TeamRecommendDeleteTargetRequest(characterId, function(success)
        if not success then return end

        XUiManager.TipText("TeamRecommendDeleteTargetSuccess")
        local targetList = XMVCA.XTeamRecommend:GetServerCharacterTargetList()
        if #targetList > 0 then
            local nextTarget = targetList[currentIndex > #targetList and 1 or currentIndex]
            if nextTarget and XTool.IsNumberValid(nextTarget.CharacterId) then
                self.CharacterId = nextTarget.CharacterId
                self:CloseLeftSwitch()
                self:Refresh()
                return
            end
        end

        if XLuaUiManager.IsUiLoad("UiTeamRecommendMain") then
            self:Close()
            return
        end
        XLuaUiManager.PopThenOpen("UiTeamRecommendMain", characterId)
    end)
end

function XUiTeamRecommendRoleTargetDetail:OnBtnWeaponObtainClick()
    local skipData = XMVCA.XEquip:GenerateEquipSkipData(self.RecommendCharData.WeaponId)
    XLuaUiManager.Open("UiEquipStrengthenSkip", skipData)
end

function XUiTeamRecommendRoleTargetDetail:OnBtnWeaponWearClick()
    local characterId = self.RecommendCharData.CharacterId
    local candidateEquipId = self:GetWeaponCandidate()
    if XTool.IsNumberValid(characterId) and XTool.IsNumberValid(candidateEquipId) then
        XMVCA.XTeamRecommend:RecordRoleTargetDetailOperation(XGlobalVar.BtnUiTeamRecommendRoleTargetDetail.BtnWearWeapon, characterId)
        XMVCA.XEquip:PutOn(characterId, candidateEquipId, function()
            self:Refresh()
        end)
    end
end

local function CheckResonanceSkillConfig(equipTemplateId, characterId, resonanceList, resonanceCount)
    if not XMVCA.XEquip:CanResonanceByTemplateId(equipTemplateId) then
        return true
    end

    for pos = 1, resonanceCount do
        local resonanceData = resonanceList and resonanceList[pos]
        if not resonanceData or not XMVCA.XEquip:IsResonanceSkillValid(equipTemplateId, characterId, pos,
            resonanceData.ResonanceType, resonanceData.SkillId) then
            XUiManager.TipText("TeamRecommendResonanceSkillInvalid")
            return false
        end
    end
    return true
end

function XUiTeamRecommendRoleTargetDetail:OnBtnWeaponUpgradeClick()
    XMVCA.XTeamRecommend:RecordRoleTargetDetailOperation(XGlobalVar.BtnUiTeamRecommendRoleTargetDetail.BtnCultureWeapon, self.RecommendCharData.CharacterId)
    XMVCA.XEquip:OpenUiEquipOneClickCultureDetailMain(self.CharacterId)
end

function XUiTeamRecommendRoleTargetDetail:OnBtnPartnerObtainClick()
    local partnerId = self.RecommendCharData.PartnerId
    if XTool.IsNumberValid(partnerId) then
        local partnerData = { Id = 0, TemplateId = partnerId }
        local partner = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData, true)
        local useItemId = partner:GetChipItemId()
        XLuaUiManager.Open("UiSkip", useItemId)
    end
end

-- 打开推荐辅助机预览
function XUiTeamRecommendRoleTargetDetail:OnBtnPartnerClick()
    local partnerId = self.RecommendCharData.PartnerId
    if not XTool.IsNumberValid(partnerId) then
        return
    end

    local partnerData = { Id = 0, TemplateId = partnerId }
    local partner = XDataCenter.PartnerManager.CreatePartnerEntityByPartnerData(partnerData, true)
    XLuaUiManager.Open("UiPartnerPreview", partner)
end

function XUiTeamRecommendRoleTargetDetail:OnBtnPartnerWearClick()
    local candidatePartner = self:GetPartnerCandidate()
    if candidatePartner then
        XMVCA.XTeamRecommend:RecordRoleTargetDetailOperation(XGlobalVar.BtnUiTeamRecommendRoleTargetDetail.BtnWearPartner, self.RecommendCharData.CharacterId)
        XDataCenter.PartnerManager.PartnerCarryRequest(self.RecommendCharData.CharacterId, candidatePartner:GetId(), nil, function()
            XLuaUiManager.Open("UiPartnerPopupTip", XUiHelper.GetText("PartnerCarrySuccess"))
            self:RefreshRole()
            self:RefreshPartner()
        end)
    end
end

function XUiTeamRecommendRoleTargetDetail:OnBtnPartnerUpgradeClick()
    local candidatePartner, isCarried = self:GetPartnerCandidate()
    if isCarried then
        XMVCA.XTeamRecommend:RecordRoleTargetDetailOperation(XGlobalVar.BtnUiTeamRecommendRoleTargetDetail.BtnCulturePartner, self.RecommendCharData.CharacterId)
        XMVCA.XTeamRecommend:RecordRoleTargetDetailPartnerCulture(self.RecommendCharData.CharacterId, self.RecommendCharData.PartnerId)
        XMVCA.XPartner:OpenOneKeyCultureUI(candidatePartner:GetId())
    else
        self:OnBtnPartnerObtainClick()
    end
end

function XUiTeamRecommendRoleTargetDetail:OnBtnAwarenessGetClick()
    XMVCA.XTeamRecommend:RecordRoleTargetDetailOperation(XGlobalVar.BtnUiTeamRecommendRoleTargetDetail.BtnObtainAwareness, self.RecommendCharData.CharacterId)
    XLuaUiManager.Open("UiTeamRecommendExchangeCostPopup", self.RecommendCharData, function()
        self:RefreshRole()
        self:RefreshAwareness()
    end)
end

function XUiTeamRecommendRoleTargetDetail:OnBtnAwarenessWearClick()
    local characterId = self.RecommendCharData.CharacterId
    if not XTool.IsNumberValid(characterId) then
        return
    end

    local equipIds = {}
    local equipIdMap = {}
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local candidateEquipId = self:GetAwarenessCandidate(site)
        if XTool.IsNumberValid(candidateEquipId) and not XMVCA.XEquip:IsEquipWearingByCharacterId(candidateEquipId, characterId) and not equipIdMap[candidateEquipId] then
            equipIdMap[candidateEquipId] = true
            table.insert(equipIds, candidateEquipId)
        end
    end

    local function putOnNext(index)
        local equipId = equipIds[index]
        if not XTool.IsNumberValid(equipId) then
            self:Refresh()
            return
        end

        XMVCA.XEquip:PutOn(characterId, equipId, function()
            putOnNext(index + 1)
        end)
    end

    putOnNext(1)
end

function XUiTeamRecommendRoleTargetDetail:OnBtnAwarenessCultivateClick()
    XMVCA.XEquip:CheckCharacterTargetAwarenessResonanceSkill(self.RecommendCharData.CharacterId)

    for _, targetSlotData in pairs(self.RecommendCharData.AwarenessSlotList or {}) do
        if not CheckResonanceSkillConfig(targetSlotData.EquipTemplateId, self.RecommendCharData.CharacterId,
            targetSlotData.ResonanceList, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT) then return end
    end

    local characterId = self.RecommendCharData.CharacterId
    if XTool.IsNumberValid(characterId) then
        XMVCA.XTeamRecommend:RecordRoleTargetDetailOperation(XGlobalVar.BtnUiTeamRecommendRoleTargetDetail.BtnCultureAwareness, characterId)
        XMVCA.XEquip:OpenUiEquipAwarenessEnhanceMain(characterId)
    end
end

function XUiTeamRecommendRoleTargetDetail:OnBtnAwarenessResonanceClick()
    XLuaUiManager.Open("UiTeamRecommendResonanceSkillPopup", self.RecommendCharData)
end

-- 子Grid回调
function XUiTeamRecommendRoleTargetDetail:OnLeftSwitchRoleGridClick(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end

    if self.CharacterId ~= characterId then
        XMVCA.XTeamRecommend:RecordRoleTargetDetailOperation(XGlobalVar.BtnUiTeamRecommendRoleTargetDetail.BtnSwitchTarget, characterId)
        self.CharacterId = characterId
    end

    self:CloseLeftSwitch()
    self:Refresh()
end

function XUiTeamRecommendRoleTargetDetail:OnWeaponEquipGridClick(templateId)
    XLuaUiManager.Open("UiTeamRecommendEquipItemInfo", templateId, false)
end

function XUiTeamRecommendRoleTargetDetail:OnAwarenessObtainGridClick(site)
    local targetSlotData = self:GetAwarenessTargetSlotData(site)

    if targetSlotData then
        local skipData = XMVCA.XEquip:GenerateEquipSkipData(targetSlotData.EquipTemplateId)
        XLuaUiManager.Open("UiEquipStrengthenSkip", skipData)
    end
end

function XUiTeamRecommendRoleTargetDetail:OnAwarenessWearGridClick(site)
    local characterId = self.RecommendCharData.CharacterId
    local candidateEquipId = self:GetAwarenessCandidate(site)

    if XTool.IsNumberValid(characterId) and XTool.IsNumberValid(candidateEquipId) then
        XMVCA.XEquip:PutOn(characterId, candidateEquipId, function()
            self:Refresh()
        end)
    end
end

function XUiTeamRecommendRoleTargetDetail:OnAwarenessEquipGridClick(site, sourceTransform)
    local targetSlotData = self:GetAwarenessTargetSlotData(site)
    if targetSlotData then
        XLuaUiManager.Open("UiTeamRecommendAwarenessTipsPopup", self.RecommendCharData.CharacterId, targetSlotData, handler(self, self.Refresh), sourceTransform)
    end
end

-- 打开并定位指定意识共鸣槽
function XUiTeamRecommendRoleTargetDetail:OnAwarenessResonanceSkillClick(site, pos)
    XLuaUiManager.Open("UiTeamRecommendResonanceSkillPopup", self.RecommendCharData, site, pos)
end

return XUiTeamRecommendRoleTargetDetail
