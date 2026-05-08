---@class XUiPanelCharacterCard
local XUiPanelCharacterCard = XClass(XUiNode, "XUiPanelCharacterCard")

function XUiPanelCharacterCard:OnStart(pos)
    self.BtnHead.CallBack = function() self:OnBtnHeadClick() end
    self.PanelNoneFullBtn.CallBack = function() self:OnBtnHeadClick() end
    self.PanelAwarenessBtn.CallBack = function() self:OnPanelAwarenessBtnClick() end
    self.BtnEquipResonance1.CallBack = function() self:OnBtnEquipResonanceClick(1) end
    self.BtnEquipResonance2.CallBack = function() self:OnBtnEquipResonanceClick(2) end
    self.BtnEquipResonance3.CallBack = function() self:OnBtnEquipResonanceClick(3) end
    self.BtnOverrunBlind.CallBack = function() self:OnBtnOverrunBlindClick() end
    self.GridPartnerBtn.CallBack = function() self:OnGridPartnerBtnClick() end
    self.PanelNonePartnerBtn.CallBack = function() self:OnGridPartnerBtnClick() end
    self.BtnPartnerSkill1.CallBack = function() self:OnBtnPartnerMainSkillClick() end
    self.BtnPartnerSkill2.CallBack = function() self:OnBtnPartnerPassiveSkillClick(2) end
    self.BtnPartnerSkill3.CallBack = function() self:OnBtnPartnerPassiveSkillClick(3) end
    self.BtnPartnerSkill4.CallBack = function() self:OnBtnPartnerPassiveSkillClick(4) end
    self.BtnPartnerSkill5.CallBack = function() self:OnBtnPartnerPassiveSkillClick(5) end
    self.BtnPartnerSkill6.CallBack = function() self:OnBtnPartnerPassiveSkillClick(6) end
    self.BtnFirst.CallBack = function() self:OnBtnFirstClick() end
    self.BtnMode.CallBack = function() self:OnBtnModeClick() end
    self.SA_ImgSelect2.color = XDataCenter.TeamManager.GetTeamMemberSelectColor(pos)

    self.ProxyTable = {
        AOPOnBtnJoinTeamClickedBefore = function(curProxy, uiBattleRoomRoleDetail, currentNeedAddEntityId)
            if not XTool.IsNumberValid(currentNeedAddEntityId) then
                return false
            end
            local weaponEquipId = XMVCA.XEquip:GetCharacterWeaponId(currentNeedAddEntityId)
            local res = self.TeamPrefab:CheckEquipIdInTeam(weaponEquipId)
            if res then
                XUiManager.TipText("TeamPrefabWeaponEquippedByOtherInPreset")
            end
            return res
        end,
        AOPOnBtnJoinTeamClickedAfter = function(curProxy, uiBattleRoomRoleDetail)
            local newCharId = self.TeamPrefab:GetEntityIdByTeamPos(self.Pos)
            self.TeamPrefab:CopyRealCharacterToPos(newCharId, self.Pos)
            XScheduleManager.ScheduleNextFrame(function ()
                self:PlayAnimation("QieHuanRole")
            end)
        end,
        AOPOnBtnQuitTeamClickedAfter = function(curProxy, uiBattleRoomRoleDetail, operatedPos)
            -- 进去后删除的不一定是当前点击进去的POS位置的角色
            self.TeamPrefab:CopyRealCharacterToPos(nil, operatedPos)
            XScheduleManager.ScheduleNextFrame(function ()
                self:PlayAnimation("QieHuanRole")
            end)
        end,
        AOPOnStartAfter = function(curProxy, uiBattleRoomRoleDetail)
            uiBattleRoomRoleDetail.BtnPartner.gameObject:SetActiveEx(false)
            uiBattleRoomRoleDetail.BtnConsciousness.gameObject:SetActiveEx(false)
            uiBattleRoomRoleDetail.BtnWeapon.gameObject:SetActiveEx(false)
        end,
    }
end

function XUiPanelCharacterCard:OnEnable()
    self:ForceSkipToEndAnimation("BtnFirstDisable")
end

function XUiPanelCharacterCard:OnBtnHeadClick()
    self.BattleRoomDetailProxy = self.BattleRoomDetailProxy or XTool.CreateBattleRoomDetailProxy(self.ProxyTable)
    XLuaUiManager.Open("UiTeamPrefabCharacterSelect", nil, self.TeamPrefab, self.Pos, self.BattleRoomDetailProxy)
end

function XUiPanelCharacterCard:OnPanelAwarenessBtnClick()
    XLuaUiManager.Open("UiTeamPrefabEquipAwareness", self.TeamPrefab, self.Pos)
end

function XUiPanelCharacterCard:OnBtnEquipResonanceClick(slot)
    local characterId = self.TeamPrefab:GetEntityIdByTeamPos(self.Pos)
    local weaponData = self.TeamPrefab:GetWeaponData(self.Pos)
    local weaponEquipId = weaponData.EquipId
    local equip = XMVCA.XEquip:GetEquip(weaponEquipId)

    if not (equip:IsWeapon() and equip:GetResonanceBindCharacterId(slot) == characterId) then
        XUiManager.TipText("TeamPrefabResonanceNeedUnlock")
        return
    end

    XLuaUiManager.Open("UiTeamPrefabEquipResonanceSkillChange", self.TeamPrefab, characterId, weaponEquipId, self.Pos, function ()
        self.Parent:RefreshRightInfo()
    end)
end


function XUiPanelCharacterCard:OnBtnOverrunBlindClick()
    local weaponData = self.TeamPrefab:GetWeaponData(self.Pos)
    local weaponEquipId = weaponData.EquipId
    local equip = XMVCA.XEquip:GetEquip(weaponEquipId)
    if not equip:CanOverrun() or not equip:IsOverrunCanBlindSuit() then
        XUiManager.TipText("TeamPrefabOverrunNeedUnlock")
        return
    end

    XLuaUiManager.Open("UiTeamPrefabEquipOverrunSelect", self.TeamPrefab, weaponEquipId, self.Pos, function()
        self.Parent:RefreshRightInfo()
    end)
end

function XUiPanelCharacterCard:OnGridPartnerBtnClick()
    if XDataCenter.PartnerManager.IsPartnerListEmpty() then
        XUiManager.TipText("PartnerListIsEmpty")
        return
    end

    XLuaUiManager.Open("UiTeamPrefabPartner", self.TeamPrefab, self.Pos)
end

function XUiPanelCharacterCard:OnBtnPartnerMainSkillClick()
    local partnerPrefab = self.TeamPrefab:GetPartnerData()
    if not partnerPrefab then
        return
    end
    local partner = XDataCenter.PartnerManager.GetPartnerEntityById(partnerPrefab:GetPartnerIdByPos(self.Pos))
    local closeCb = function ()
        self.Parent:RefreshRightInfo()
    end
    XLuaUiManager.OpenWithCloseCallback("UiPartnerPresetMainSkill", closeCb, partner, partnerPrefab)
end

function XUiPanelCharacterCard:OnBtnPartnerPassiveSkillClick(slot)
    local partnerPrefab = self.TeamPrefab:GetPartnerData()
    if not partnerPrefab then
        return
    end
    local partner = XDataCenter.PartnerManager.GetPartnerEntityById(partnerPrefab:GetPartnerIdByPos(self.Pos))
    local closeCb = function ()
        self.Parent:RefreshRightInfo()
    end
    XLuaUiManager.OpenWithCloseCallback("UiPartnerPresetPassiveSkill", closeCb, partner, partnerPrefab)
end

function XUiPanelCharacterCard:OnBtnFirstClick()
    if self.TeamPrefab:GetFirstFightPos() == self.Pos then
        return
    end

    self:PlayAnimation("BtnFirstDisable")

    self.TeamPrefab:UpdateFirstFightPos(self.Pos, nil, function ()
        XUiManager.PopupLeftTip(XUiHelper.GetText("TeamPrefabFirstFightAdjusted"))
    end)
    self.Parent:RefreshRightInfo()
end

function XUiPanelCharacterCard:OnBtnModeClick()
    XLuaUiManager.Open("UiTeamPrefabSkillSwitch", self.TeamPrefab, self.Pos, function()
        self.Parent:RefreshRightInfo()
    end)
end

--- func desc
---@param xTeamPrefab XTeamPrefab
function XUiPanelCharacterCard:Refresh(xTeamPrefab, pos)
    local characterId = xTeamPrefab:GetEntityIdByTeamPos(pos)
    local hasCharacter = XTool.IsNumberValid(characterId)
    self.IsYellowConflict = false
    self.IsWeaponResonanceBindCharConflict = false
    self.IsWeaponResonanceBindSkillIdConflict = false
    self.IsWeaponResonanceCountConflict = false
    self.IsWeaponOverrunConflict = false
    self.IsEquipAwarenessConflict = false
    self.IsPartnerSkillReddot = false
    self.IsWeaponExsitConflict = false

    self.TeamPrefab = xTeamPrefab
    self.Pos = pos
    self.CharacterId = characterId
    self.PanelDetailFull.gameObject:SetActiveEx(hasCharacter)
    self.PanelNoneFullBtn.gameObject:SetActiveEx(not hasCharacter)

    if hasCharacter then
        self.BtnHead:SetRawImage(XMVCA.XCharacter:GetCharSmallHeadIcon(characterId))
        self.IconLeader.gameObject:SetActiveEx(xTeamPrefab:GetCaptainPos() == pos)
        
        -- 机体名
        local charConfig = XMVCA.XCharacter:GetCharacterTemplate(characterId)
        self.TxtName.text = charConfig.Name
        self.TxtNameOther.text = charConfig.TradeName

        -- 品质
        self.RImgCharacterRank:SetRawImage(XMVCA.XCharacter:GetCharacterQualityIcon(XMVCA.XCharacter:GetCharacterQuality(characterId)))

        -- 元素
        local elementList = XMVCA.XCharacter:GetCharacterAllElement(characterId, true)
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
        local activeGenralSkillIds = XMVCA.XCharacter:GetCharactersActiveGeneralSkillIdList(characterId)
        local curTeamPrefabActiveSelectedGeneralSkill = xTeamPrefab:GetCurGeneralSkill()
        local generalSkillConfigs = XMVCA.XCharacter:GetModelCharacterGeneralSkill()

        for i = 1, 2 do
            local id = activeGenralSkillIds[i]
            local btnGeneralSkill = self["GeneralSkill"..i]
            if id then
                local generalSkillConfig = generalSkillConfigs[id]
                local isSelect = id == curTeamPrefabActiveSelectedGeneralSkill
                -- 根据是否选中切换图标
                if isSelect then
                    btnGeneralSkill:SetRawImage(generalSkillConfig.IconBlue)
                else
                    btnGeneralSkill:SetRawImage(generalSkillConfig.Icon)
                end
                btnGeneralSkill:ShowTag(isSelect)
            end
            btnGeneralSkill.gameObject:SetActiveEx(id)
        end

        -- 意识
        if not self.SuitItemList then
            self.SuitItemList = {self.SuitItem}
        end
        -- 隐藏所有
        for _, suitItem in ipairs(self.SuitItemList) do
            suitItem.gameObject:SetActiveEx(false)
        end
        self.SuitOverrunItem.gameObject:SetActiveEx(false)
        -- 套装列表
        local suitInfoList = xTeamPrefab:GetWearingSuitInfoListByPos(pos)
        local itemIndex = 1
        local haveSuit = false
        for i, suitInfo in ipairs(suitInfoList) do
            if suitInfo.Count ~= 1 then
                haveSuit = true
                local itemGo
                if suitInfo.IsOverrun then
                    itemGo = self.SuitOverrunItem
                else
                    itemGo = self.SuitItemList[itemIndex]
                    if not itemGo then
                        itemGo = XUiHelper.Instantiate(self.SuitItem.gameObject, self.SuitItem.transform.parent)
                        table.insert(self.SuitItemList, itemGo)
                    end
                    itemIndex = itemIndex + 1
                end
    
                itemGo.gameObject:SetActiveEx(true)
                itemGo.transform:SetAsLastSibling()
                local uiObj = itemGo:GetComponent("UiObject")
                uiObj:GetObject("TxtSuitName").text = suitInfo.Name
                uiObj:GetObject("TxtSuitCount").text = suitInfo.Count
            end
        end
        self.PanelNoneAwareness.gameObject:SetActiveEx(not haveSuit)
        -- 意识黄标:equip实际共鸣的角色与当前预设里的角色不一致则显示
        local allAwarenessData = xTeamPrefab:GetAllAwarenessData(pos)
        local isYellowConflict = false
        if not XTool.IsTableEmpty(allAwarenessData) then
            for k, v in pairs(allAwarenessData) do
                local equipId = v.EquipId
                local xEquip = XMVCA.XEquip:GetEquip(equipId)
                for resonanceSlot = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT, 1 do
                    local resonanceCharId = xEquip:GetResonanceBindCharacterId(resonanceSlot)
                    if XTool.IsNumberValid(resonanceCharId) and resonanceCharId ~= characterId then
                        isYellowConflict = true
                        break
                    end
                end
            end
        end
        self.TagConflictYellowAwareness.gameObject:SetActiveEx(isYellowConflict)
        if isYellowConflict then
            self.IsYellowConflict = true
            self.IsEquipAwarenessConflict = true
        end

        -- 武器
        local XUiGridEquip = require("XUi/XUiEquip/XUiGridEquip")
        local weaponData = xTeamPrefab:GetWeaponData(pos)
        ---@type XUiGridEquip
        self.WeaponGrid = self.WeaponGrid or XUiGridEquip.New(self.GridWeapon, self.Parent, function ()
            XLuaUiManager.Open("UiTeamPrefabWeapon", self.TeamPrefab, self.Pos)
        end)
        local realWeaponId = XMVCA.XEquip:GetCharacterWeaponId(characterId)
        local usingWeaponId = realWeaponId
        if weaponData then
            usingWeaponId = weaponData.EquipId
        end
        -- 预设武器与实穿武器是否一致，①②③④冲突检测的前置条件
        local isWeaponSameAsReal = (usingWeaponId == realWeaponId)
        local xWeaponEquip = XMVCA.XEquip:GetEquip(usingWeaponId)
        if xWeaponEquip then
            self.WeaponGrid:Refresh(usingWeaponId)
            -- 武器共鸣
            -- 先全部隐藏
            self.BtnEquipResonance1:SetButtonState(CS.UiButtonState.Disable)
            self.BtnEquipResonance2:SetButtonState(CS.UiButtonState.Disable)
            self.BtnEquipResonance3:SetButtonState(CS.UiButtonState.Disable)
			local resonanceDict = nil
            if weaponData then
                resonanceDict = weaponData.ResonanceDict
            end
            local isHasResonance = not XTool.IsTableEmpty(resonanceDict)
            if isHasResonance then
                local XSkillInfoObj = require("XEntity/XEquip/XSkillInfoObj")
                -- 获取当前预设角色ID（用于区分角色专属共鸣技能）
                local characterId = self.TeamPrefab:GetEntityIdByTeamPos(pos)
                for i, skillId in pairs(resonanceDict) do
                    -- 尝试自动识别共鸣类型（武器/属性/角色技能）
                    -- 若预设数据中包含类型信息，可直接传入，否则需通过配置反向判断
                    local skillType = XMVCA.XEquip:GuessResonanceType(skillId, xWeaponEquip.TemplateId)
                    local skillInfo = XSkillInfoObj.New(skillType, skillId, characterId)
                    self["BtnEquipResonance"..i]:SetRawImage(skillInfo.Icon)
                    self["BtnEquipResonance"..i]:SetButtonState(CS.UiButtonState.Normal)
                end
            end
			-- 武器谐振
            self.BtnOverrunBlind:SetButtonState(CS.UiButtonState.Disable)
            local hasOverrunSuitId = false
            if weaponData then
                hasOverrunSuitId = XTool.IsNumberValid(weaponData.WeaponOverrunSuitId)
            end
            if xWeaponEquip:CanOverrun() and hasOverrunSuitId then
                local icon = XMVCA.XEquip:GetEquipSuitIconPath(weaponData.WeaponOverrunSuitId)
                self.BtnOverrunBlind:SetRawImage(icon)
                self.BtnOverrunBlind:SetButtonState(CS.UiButtonState.Normal)
            end
            -- 武器共鸣黄标:
            -- 1.共鸣绑定角色冲突：equip实际共鸣绑定的角色与当前预设里的角色不一致则显示
            -- 4.共鸣绑定技能冲突：预设里绑定的技能Id不在实际装备当前可选技能列表中则显示
            -- ①④任意触发则对应槽位显示不共鸣标签
            local isWeaponResonanceBindCharConflict = false
            local isWeaponResonanceBindSkillIdConflict = false
            local validSkillIdSet = {}
            local previewList = XMVCA.XEquip:GetResonancePreviewSkillInfoList(usingWeaponId, characterId, 1)
            for _, info in ipairs(previewList) do
                validSkillIdSet[info.Id] = true
            end
            for slot = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT, 1 do
                -- ① 绑定角色冲突（需预设武器与实穿一致）
                local charId = xWeaponEquip:GetResonanceBindCharacterId(slot)
                local isCurSlotCharIdConflict = XTool.IsNumberValid(charId) and charId ~= characterId
                if isCurSlotCharIdConflict then
                    isWeaponResonanceBindCharConflict = true
                    self.IsWeaponResonanceBindCharConflict = true
                end
                -- ④ 绑定技能冲突（需预设武器与实穿一致）
                local prefabSkillId = resonanceDict and resonanceDict[slot]
                local isCurSlotSkillIdConflict = isWeaponSameAsReal and XTool.IsNumberValid(prefabSkillId) and not validSkillIdSet[prefabSkillId]
                if isCurSlotSkillIdConflict then
                    isWeaponResonanceBindSkillIdConflict = true
                    self.IsWeaponResonanceBindSkillIdConflict = true
                end
                self["BtnEquipResonance"..slot]:ShowReddot(isCurSlotCharIdConflict or isCurSlotSkillIdConflict)
            end
            
            -- 2.预设里的共鸣数量与实际装备共鸣数量不一致则显示
            local resounanceCountInPrefab = 0
            if resonanceDict then
                for slot, v in pairs(resonanceDict) do
                    resounanceCountInPrefab = resounanceCountInPrefab + 1
                end
            end
            local resounanceCountInEquip = xWeaponEquip:GetResonanceCount()
            local isWeaponResonanceCountConflict = (resounanceCountInPrefab ~= resounanceCountInEquip)
            if isWeaponResonanceCountConflict then
                self.IsWeaponResonanceCountConflict = true
            end
    
            local isWeaponResonanceConflict = isWeaponResonanceCountConflict or isWeaponResonanceBindCharConflict
            self.BtnEquipResonance1:ShowTag(isWeaponResonanceConflict)
            if isWeaponResonanceConflict then
                self.IsYellowConflict = true
            end
    
			-- 武器谐振冲突:预设里没有配置谐振套装（WeaponOverrunSuitId 无效），但实际装备已选择了谐振套装
            local isWeaponOverrunConfilict = false
            if weaponData then
                isWeaponOverrunConfilict = (not XTool.IsNumberValid(weaponData.WeaponOverrunSuitId)) and (XTool.IsNumberValid(xWeaponEquip:GetOverrunChoseSuit()))
            end
            self.BtnOverrunBlind:ShowTag(isWeaponOverrunConfilict)
            if isWeaponOverrunConfilict then
                self.IsYellowConflict = true
                self.IsWeaponOverrunConflict = true
            end
        else
            -- 没有武器装备时，重置所有显示状态
            self.WeaponGrid:ShowCharacterDefaultWeapon(characterId)

            self.BtnEquipResonance1:SetButtonState(CS.UiButtonState.Disable)
            self.BtnEquipResonance2:SetButtonState(CS.UiButtonState.Disable)
            self.BtnEquipResonance3:SetButtonState(CS.UiButtonState.Disable)
            self.BtnOverrunBlind:SetButtonState(CS.UiButtonState.Disable)

            self.BtnEquipResonance1:ShowReddot(false)
            self.BtnEquipResonance2:ShowReddot(false)
            self.BtnEquipResonance3:ShowReddot(false)
            self.BtnEquipResonance1:ShowTag(false)
            self.BtnEquipResonance2:ShowTag(false)
            self.BtnEquipResonance3:ShowTag(false)
            self.BtnOverrunBlind:ShowTag(false)

            self.IsWeaponExsitConflict = true
        end
        self.TagConflictRedWeapon.gameObject:SetActiveEx(not xWeaponEquip)

        -- 辅助机
        local partnerPrefabData = xTeamPrefab:GetPartnerData()
        local partnerId = partnerPrefabData and partnerPrefabData:GetPartnerIdByPos(pos)
        local partner = partnerId and XDataCenter.PartnerManager.GetPartnerEntityById(partnerId)
        self.PanelNonePartnerBtn.gameObject:SetActiveEx(not partner)
        self.GridPartnerBtn.gameObject:SetActiveEx(partner)
        self.ListSkillPartner.gameObject:SetActiveEx(partner)
        if partner then
            self.RImgPartner:SetRawImage(partner:GetIcon())
            self.ImgPartnerBreakthrough:SetSprite(partner:GetBreakthroughIcon())
            self.PartnerRImgRank:SetRawImage(partner:GetCharacterQualityIcon())

            -- 辅助机技能
            partnerPrefabData:InitSkillCache({TeamData = xTeamPrefab:GetEntityIds()})
            -- 携带的主动技能
            local activeSkills = XDataCenter.PartnerManager.GetPresetSkillList(partnerId, XPartnerConfigs.SkillType.MainSkill)
            -- 携带的被动技能
            local passiveSkills = XDataCenter.PartnerManager.GetPresetSkillList(partnerId, XPartnerConfigs.SkillType.PassiveSkill)

            local skillGroup = activeSkills[1]
            local activeId = XDataCenter.PartnerManager.SwitchMainActiveSkillId(skillGroup, characterId)
            self.BtnPartnerSkill1:SetRawImage(skillGroup:GetSkillIcon(activeId))

            local passiveBtnStartIndex = 2
            for i = passiveBtnStartIndex, 6, 1 do
                self["BtnPartnerSkill"..i]:SetButtonState(CS.UiButtonState.Disable)
            end

            for i = passiveBtnStartIndex, 6, 1 do
                local btnSkill = self["BtnPartnerSkill"..i]
                local skillObj = btnSkill.gameObject:GetComponent("UiObject")
                skillGroup = passiveSkills[i-1]
                local qCount = partner:GetQualitySkillColumnCount()
                local isLock = qCount < i - 1
                local hasData = not XTool.IsTableEmpty(skillGroup)
                if hasData then
                    activeId = XDataCenter.PartnerManager.SwitchMainActiveSkillId(skillGroup, characterId)
                    btnSkill:SetRawImage(skillGroup:GetSkillIcon(activeId))
                    btnSkill:SetButtonState(CS.UiButtonState.Normal)
                end

                skillObj:GetObject("PanelLock").gameObject:SetActiveEx(isLock)

                -- 辅助机技能没装满黄标提醒：
                if not isLock and not hasData then
                    self.IsYellowConflict = true
                    self.IsPartnerSkillReddot = true
                end
            end
        end
        -- 辅助机技能红点提示：解锁了但是没有带满技能槽
        self.SkillPartnerReddot.gameObject:SetActiveEx(partner and self.IsPartnerSkillReddot)

        --首发按钮
        local isFirst = xTeamPrefab:GetFirstFightPos() == pos
        self.BtnFirst:SetButtonState(isFirst and CS.UiButtonState.Disable or CS.UiButtonState.Normal)

        -- 形态切换按钮（仅支持 CharacterSkillExchangeDes 配置的角色，如比安卡）
        local switchSkillId, skillExchangeConfig = XMVCA.XCharacter:GetSkillExchangeDesSkillIdAndConfigByCharacterId(characterId)
        self.BtnMode.gameObject:SetActiveEx(switchSkillId ~= nil)
        if switchSkillId then
            -- 确定当前选中的变体：读预设存储，nil 时 fallback 到 group 第一个（不读全局态，保持数据独立）
            local currentSkillId = xTeamPrefab:GetSwitchSkillByPos(pos)
            local groupSkillIds = XMVCA.XCharacter:GetGroupSkillIds(switchSkillId)
            if not currentSkillId then
                currentSkillId = groupSkillIds[1]
            end
            -- 填充图标与形态名
            local skillLevel = XMVCA.XCharacter:GetSkillLevel(currentSkillId)
            local skillDetail = XMVCA.XCharacter:GetSkillGradeDesWithDetailConfig(currentSkillId, skillLevel)
            self.BtnMode:SetRawImage(skillDetail.Icon)
            -- Title 按 group 内顺序索引，需要找到 currentSkillId 的位置
            local titleIndex = 1
            for i, skillId in ipairs(groupSkillIds) do
                if skillId == currentSkillId then titleIndex = i break end
            end
            self.BtnMode:SetNameByGroup(0, skillExchangeConfig.Title[titleIndex])
        end
    end
    if self.WeaponGrid then
        if hasCharacter then
            self.WeaponGrid:Open()
        else
            self.WeaponGrid:Close()
        end
    end
end

function XUiPanelCharacterCard:GetIsYellowConflict()
    return self.IsYellowConflict
end

function XUiPanelCharacterCard:GetIsEquipAwarenessConflict()
    return self.IsEquipAwarenessConflict
end

function XUiPanelCharacterCard:GetIsWeaponResonanceBindCharConflict()
    return self.IsWeaponResonanceBindCharConflict
end

function XUiPanelCharacterCard:GetIsWeaponResonanceBindSkillIdConflict()
    return self.IsWeaponResonanceBindSkillIdConflict
end

function XUiPanelCharacterCard:GetIsWeaponResonanceCountConflict()
    return self.IsWeaponResonanceCountConflict
end

function XUiPanelCharacterCard:GetIsWeaponOverrunConflict()
    return self.IsWeaponOverrunConflict
end

function XUiPanelCharacterCard:GetIsWeaponExsitConflict()
    return self.IsWeaponExsitConflict
end

return XUiPanelCharacterCard