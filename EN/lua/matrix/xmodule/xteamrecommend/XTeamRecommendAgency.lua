---@class XTeamRecommendAgency : XAgency
---@field private _Model XTeamRecommendModel
local XTeamRecommendAgency = XClass(XAgency, "XTeamRecommendAgency", false)

local RequestName = {
    TeamRecommendFormationRequest = "TeamRecommendFormationRequest",
    TeamRecommendSetTargetRequest = "TeamRecommendSetTargetRequest",
    TeamRecommendSetFormationTargetRequest = "TeamRecommendSetFormationTargetRequest",
    TeamRecommendGetAllTargetsRequest = "TeamRecommendGetAllTargetsRequest",
    TeamRecommendDeleteTargetRequest = "TeamRecommendDeleteTargetRequest",
    TeamRecommendFinishTargetRequest = "TeamRecommendFinishTargetRequest",
    TeamRecommendFinishTargetEventRequest = "TeamRecommendFinishTargetEventRequest",
}

function XTeamRecommendAgency:OnInit()
    --初始化一些变量
    self:InitConfig()
    self._FinishTargetRequesting = {}
end

function XTeamRecommendAgency:InitRpc()
    --实现服务器事件注册
    --XRpc.XXX
    XRpc.NotifyTeamRecommendTargetData = handler(self, self.NotifyTeamRecommendTargetData)
end

function XTeamRecommendAgency:InitEvent()
    --实现跨Agency事件注册
    --self:AddAgencyEvent()
end

function XTeamRecommendAgency:InitConfig()
    --初始化配置表
end


--region ----------public start----------

--============================================================== #region 配置表查询 ==============================================================

---------------------------------------- #region TeamRecommendBaseCharacter ----------------------------------------
--- 获取角色推荐方案配置（单条/全部）
function XTeamRecommendAgency:GetTeamRecommendBaseCharacter(id)
    return self._Model:GetTeamRecommendBaseCharacter(id)
end

--- Tab1: 根据CharacterId获取该角色的所有推荐方案
function XTeamRecommendAgency:GetBaseCharacterListByCharacterId(characterId)
    return self._Model:GetBaseCharacterListByCharacterId(characterId)
end

---------------------------------------- #region TeamRecommendBaseFormation ----------------------------------------
--- 获取阵容基础信息配置（单条/全部）
function XTeamRecommendAgency:GetTeamRecommendBaseFormation(id)
    return self._Model:GetTeamRecommendBaseFormation(id)
end

--- 根据FormationId+CharacterId锁定BaseFormation配置行
function XTeamRecommendAgency:GetTeamRecommendBaseFormationByFormationIdAndCharacterId(formationId, characterId)
    return self._Model:GetTeamRecommendBaseFormationByFormationIdAndCharacterId(formationId, characterId)
end

---------------------------------------- #region TeamRecommendCharacterTarget ----------------------------------------
--- 获取角色目标设定配置
function XTeamRecommendAgency:GetTeamRecommendCharacterTarget(characterId)
    return self._Model:GetTeamRecommendCharacterTarget(characterId)
end

--- 获取角色的目标方案ID列表
function XTeamRecommendAgency:GetCharacterTargetBaseCharacterIds(characterId)
    return self._Model:GetCharacterTargetBaseCharacterIds(characterId)
end

--- 获取角色目标名称列表
function XTeamRecommendAgency:GetCharacterTargetNames(characterId)
    return self._Model:GetCharacterTargetNames(characterId)
end

---------------------------------------- #region TeamRecommendConfig ----------------------------------------
--- 获取通用配置
function XTeamRecommendAgency:GetTeamRecommendConfig(key)
    return self._Model:GetTeamRecommendConfig(key)
end

--- 角色目标设定上限
function XTeamRecommendAgency:GetCharacterTargetLimit()
    return self._Model:GetCharacterTargetLimit()
end

--- 任务要求的目标完成度上报阈值（百分比）
function XTeamRecommendAgency:GetTargetFinishPercentage()
    return self._Model:GetTargetFinishPercentage()
end

---------------------------------------- #region TeamRecommendFormation ----------------------------------------
--- 获取阵容筛选/展示配置（单条/全部）
function XTeamRecommendAgency:GetTeamRecommendFormation(id)
    return self._Model:GetTeamRecommendFormation(id)
end

--- 根据StageType+FormationType筛选Formation配置列表
function XTeamRecommendAgency:GetFormationListByFilter(stageType, formationType)
    return self._Model:GetFormationListByFilter(stageType, formationType)
end

--- Tab2核心查询：根据筛选条件+角色ID构造完整阵容展示数据
--- 返回 { Formation=cfg, BaseFormation=cfg, ServerFormation=serverData } 列表
function XTeamRecommendAgency:BuildFormationGridList(stageType, formationType, characterId)
    local formations = self:GetFormationListByFilter(stageType, formationType)
    local result = {}
    for _, formationCfg in ipairs(formations) do
        local gridData = self:BuildFormationGridData(formationCfg.Id, characterId, formationCfg)
        if gridData then
            table.insert(result, gridData)
        end
    end

    table.sort(result, function(a, b)
        return a.BaseFormation.Order > b.BaseFormation.Order
    end)

    return result
end

--- 构造单个阵容展示数据
function XTeamRecommendAgency:BuildFormationGridData(teamCfgId, characterId, formationCfg)
    if not XTool.IsNumberValid(teamCfgId) or not XTool.IsNumberValid(characterId) then
        return nil
    end

    formationCfg = formationCfg or self:GetTeamRecommendFormation(teamCfgId)
    local baseFormationCfg = self:GetTeamRecommendBaseFormationByFormationIdAndCharacterId(teamCfgId, characterId)
    if not formationCfg or not baseFormationCfg then
        return nil
    end

    return {
        Formation = formationCfg,
        BaseFormation = baseFormationCfg,
        ServerFormation = self:GetServerFormationData(characterId, teamCfgId),
    }
end

--- 记录装备目标详情页操作
function XTeamRecommendAgency:RecordRoleTargetDetailOperation(actionType, characterId)
    local dict = {}
    dict["action_type"] = actionType
    dict["character_id"] = characterId
    dict["role_id"] = XPlayer.Id
    CS.XRecord.Record(dict, "1000002", "UiTeamRecommendRoleTargetDetail")
end

--- 记录从装备目标详情页进入辅助机一键培养
function XTeamRecommendAgency:RecordRoleTargetDetailPartnerCulture(characterId, partnerId)
    local dict = {}
    dict["character_id"] = characterId
    dict["partner_id"] = partnerId
    dict["role_id"] = XPlayer.Id
    CS.XRecord.Record(dict, "1000004", "UiEquipOneClickCulturePartnerMain")
end

--============================================================== #endregion 配置表查询 ==============================================================

--============================================================== #region 服务端目标数据 ==============================================================

--- 获取角色当前服务端目标
function XTeamRecommendAgency:GetServerCharacterTarget(characterId)
    return self._Model:GetServerCharacterTarget(characterId)
end

--- 获取所有已设角色目标（单人+阵容）
function XTeamRecommendAgency:GetServerCharacterTargetList()
    return self._Model:GetServerCharacterTargetList()
end

--- 获取按角色Id排序后的第一个有效目标角色
function XTeamRecommendAgency:GetFirstServerCharacterTargetId()
    for _, targetData in ipairs(self:GetServerCharacterTargetList()) do
        local characterId = targetData.CharacterId
        if self:BuildRoleTargetDetailData(characterId) then
            return characterId
        end
    end
    return nil
end

--- 打开指定角色的推荐或当前目标详情
function XTeamRecommendAgency:OpenCharacterRecommend(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end

    if self:GetServerCharacterTarget(characterId) then
        XLuaUiManager.Open("UiTeamRecommendRoleTargetDetail", characterId)
    else
        XLuaUiManager.Open("UiTeamRecommendMain", characterId)
    end
end

--- 从主界面打开第一个有效目标详情
function XTeamRecommendAgency:OpenFirstServerCharacterTarget()
    local characterId = self:GetFirstTargetEquipCanWearCharacterId() or self:GetFirstServerCharacterTargetId()
    if not characterId then
        return
    end

    XUiHelper.RecordBuriedSpotTypeLevelOne(XGlobalVar.BtnBuriedSpotTypeLevelOne.BtnUiMainBtnTeamRecommend)
    XLuaUiManager.Open("UiTeamRecommendRoleTargetDetail", characterId)
end

--- 获取角色当前阵容目标详情；死配置目标用BaseFormationId回配表构造
function XTeamRecommendAgency:GetCharacterTargetFormationData(characterId)
    local target = self:GetServerCharacterTarget(characterId)
    if not target then
        return nil
    end

    if target.TargetFormation then
        return target.TargetFormation
    end

    local baseFormationId = target.BaseFormationId
    if XTool.IsNumberValid(baseFormationId) then
        return self:BuildTargetFormationFromCfg(self:GetTeamRecommendBaseFormation(baseFormationId))
    end

    return nil
end

--- 从角色已存阵容目标取本人归一化数据（前往培养/左侧目标切换的参照物）
function XTeamRecommendAgency:GetCharacterTargetCharData(characterId)
    local target = self:GetServerCharacterTarget(characterId)
    local formationData = self:GetCharacterTargetFormationData(characterId)
    local characterDatas = formationData and formationData.CharacterDatas
    for _, characterData in ipairs(characterDatas or {}) do
        if characterData.CharacterId == characterId then
            local recommendCharData = self:FromServerData(characterData)
            if recommendCharData then
                recommendCharData.TargetTeamCfgId = target.TeamCfgId or 0
            end
            return recommendCharData
        end
    end
    return nil
end

local function IsSameTargetResonance(recommendResonance, targetResonance)
    if recommendResonance == targetResonance then return true end
    if not recommendResonance or not targetResonance then return false end
    return recommendResonance.SkillId == targetResonance.SkillId and recommendResonance.ResonanceType == targetResonance.ResonanceType
end

--- 当前阵容卡片与角色已存目标的培养数据一致时，才视为正在使用
function XTeamRecommendAgency:IsCharacterFormationTargetUsing(recommendCharData, teamCfgId)
    local characterId = recommendCharData and recommendCharData.CharacterId
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(teamCfgId) then return false end

    local target = self:GetServerCharacterTarget(characterId)
    if not target or target.TeamCfgId ~= teamCfgId then return false end

    local targetCharData = self:GetCharacterTargetCharData(characterId)
    if not targetCharData then return false end

    local isSameRoleTarget = recommendCharData.Quality == targetCharData.Quality and recommendCharData.Star == targetCharData.Star
    if not isSameRoleTarget then return false end

    local isSameEquipmentTarget = recommendCharData.WeaponId == targetCharData.WeaponId and recommendCharData.WeaponOverrunChoseSuit == targetCharData.WeaponOverrunChoseSuit and recommendCharData.PartnerId == targetCharData.PartnerId
    if not isSameEquipmentTarget then return false end

    local recommendWeaponResonanceList = recommendCharData.WeaponResonanceList
    local targetWeaponResonanceList = targetCharData.WeaponResonanceList
    for slot = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        if not IsSameTargetResonance(recommendWeaponResonanceList[slot], targetWeaponResonanceList[slot]) then return false end
    end

    local recommendAwarenessSlotList = recommendCharData.AwarenessSlotList
    local targetAwarenessSlotList = targetCharData.AwarenessSlotList
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local recommendSlotData = recommendAwarenessSlotList[site]
        local targetSlotData = targetAwarenessSlotList[site]
        if recommendSlotData.EquipTemplateId ~= targetSlotData.EquipTemplateId then return false end

        local recommendResonanceList = recommendSlotData.ResonanceList
        local targetResonanceList = targetSlotData.ResonanceList
        for slot = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            if not IsSameTargetResonance(recommendResonanceList[slot], targetResonanceList[slot]) then return false end
        end
    end

    return true
end

--- 获取角色当前设置的目标意识列表，包含目标意识与目标共鸣信息
---@param characterId number
---@return table|nil AwarenessSlotList
function XTeamRecommendAgency:GetCharacterTargetAwarenessSlotList(characterId)
    local roleTargetDetailData = self:BuildRoleTargetDetailData(characterId)
    local recommendCharData = roleTargetDetailData and roleTargetDetailData.RecommendCharData
    local result = recommendCharData and recommendCharData.AwarenessSlotList or nil
    return result
end

--- 获取指定角色目标方案的标题
function XTeamRecommendAgency:GetCharacterTargetNameByBaseCfgId(characterId, baseCfgId)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(baseCfgId) then
        return nil
    end

    local baseCharacterIds = self:GetCharacterTargetBaseCharacterIds(characterId)
    local targetNames = self:GetCharacterTargetNames(characterId)
    for index, targetBaseCfgId in ipairs(baseCharacterIds or {}) do
        if tonumber(targetBaseCfgId) == baseCfgId then
            return targetNames and targetNames[index] or nil
        end
    end
    return nil
end

--- 按角色现拼已存目标的详情页条目（RecommendCharData+TargetName）；未设目标返回nil
function XTeamRecommendAgency:BuildRoleTargetDetailData(characterId)
    local target = self:GetServerCharacterTarget(characterId)
    if not target then
        return nil
    end

    local recommendCharData
    local targetName
    if XTool.IsNumberValid(target.BaseCharacterId) then
        -- 单人目标：按方案配置行展示，标题用方案名
        local cfg = self:GetTeamRecommendBaseCharacter(target.BaseCharacterId)
        recommendCharData = self:FromCfgData(cfg)
        targetName = recommendCharData and self:GetCharacterTargetNameByBaseCfgId(characterId, recommendCharData.BaseCfgId)
    else
        -- 阵容目标：从目标快照取本人数据，标题优先读死配置来源BaseFormation行的Desc
        recommendCharData = self:GetCharacterTargetCharData(characterId)
        if recommendCharData then
            local baseFormationCfg = XTool.IsNumberValid(target.BaseFormationId) and self:GetTeamRecommendBaseFormation(target.BaseFormationId) or nil
            if not baseFormationCfg then
                baseFormationCfg = self:GetTeamRecommendBaseFormationByFormationIdAndCharacterId(target.TeamCfgId, characterId)
            end
            targetName = baseFormationCfg and baseFormationCfg.Desc
        end
    end

    if not recommendCharData then
        return nil
    end

    return {
        RecommendCharData = recommendCharData,
        TargetName = targetName,
    }
end

--- 当前角色目标是否使用指定推荐角色方案
function XTeamRecommendAgency:IsCharacterTargetUsing(recommendCharData)
    if not recommendCharData then
        return false
    end

    local characterId = recommendCharData.CharacterId
    if not XTool.IsNumberValid(characterId) then
        return false
    end

    local target = self:GetServerCharacterTarget(characterId)
    if not target then
        return false
    end

    local baseCfgId = recommendCharData.BaseCfgId
    if XTool.IsNumberValid(baseCfgId) then
        return target.BaseCharacterId == baseCfgId
    end

    return false
end

--- 角色目标已选5星武器时，非当前推荐方案的6星武器方案显示标签
function XTeamRecommendAgency:IsShowCharacterTargetSixStarWeaponTag(recommendCharData)
    if not recommendCharData then
        return false
    end

    local characterId = recommendCharData.CharacterId
    local baseCfgId = recommendCharData.BaseCfgId
    local weaponId = recommendCharData.WeaponId
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(baseCfgId) or not XTool.IsNumberValid(weaponId) then
        return false
    end

    local target = self:GetServerCharacterTarget(characterId)
    local targetBaseCfgId = target and target.BaseCharacterId
    if not XTool.IsNumberValid(targetBaseCfgId) or targetBaseCfgId == baseCfgId then
        return false
    end

    local targetCfg = self:GetTeamRecommendBaseCharacter(targetBaseCfgId)
    local targetWeaponId = targetCfg and targetCfg.WeaponId
    if not XTool.IsNumberValid(targetWeaponId) then
        return false
    end

    local targetWeaponStar = XMVCA.XEquip:GetEquipStar(targetWeaponId)
    local curWeaponStar = XMVCA.XEquip:GetEquipStar(weaponId)
    return targetWeaponStar == XEnumConst.EQUIP.FIVE_STAR and curWeaponStar == XEnumConst.EQUIP.SIX_STAR
end

--- 构造角色当前阵容目标对应的展示数据
function XTeamRecommendAgency:BuildFormationTargetGridData(characterId)
    local target = self:GetServerCharacterTarget(characterId)
    local teamCfgId = target and target.TeamCfgId
    if not XTool.IsNumberValid(teamCfgId) then
        return nil
    end

    local gridData = self:BuildFormationGridData(teamCfgId, characterId)
    if gridData then
        if XTool.IsNumberValid(target.BaseFormationId) then
            local baseFormationCfg = self:GetTeamRecommendBaseFormation(target.BaseFormationId)
            if baseFormationCfg then
                gridData.BaseFormation = baseFormationCfg
            end
        end
        gridData.TargetFormation = self:GetCharacterTargetFormationData(characterId)
    end
    return gridData
end

--- 获取服务端阵容详情
function XTeamRecommendAgency:GetServerFormationData(characterId, teamCfgId)
    return self._Model:GetServerFormationData(characterId, teamCfgId)
end

--- 判断指定阵容详情是否已向服务端请求过
function XTeamRecommendAgency:AreServerFormationDatasRequested(characterId, teamCfgIds)
    return self._Model:AreServerFormationDatasRequested(characterId, teamCfgIds)
end

--- 将当前角色移到展示列表首位，其余角色保持原顺序
function XTeamRecommendAgency:MoveCurrentCharacterToFirst(characterDataList, currentCharacterId)
    for index, characterData in ipairs(characterDataList) do
        if characterData.CharacterId == currentCharacterId then
            if index > 1 then table.insert(characterDataList, 1, table.remove(characterDataList, index)) end
            return
        end
    end
end

--- 从阵容格子数据提取角色头像展示数据，优先使用服务端数据
function XTeamRecommendAgency:GetFormationRoleDisplayList(formationGridData, currentCharacterId)
    local result = {}
    local formationData = formationGridData and (formationGridData.TargetFormation or formationGridData.ServerFormation)
    local characterDatas = formationData and formationData.CharacterDatas
    if characterDatas and #characterDatas > 0 then
        for _, characterData in ipairs(characterDatas) do
            local characterId = characterData.CharacterId
            if XTool.IsNumberValid(characterId) then
                local grade = characterData.CharacterQualityStar or 0
                local quality = math.floor(grade / 1000)
                if not XTool.IsNumberValid(quality) then
                    quality = XMVCA.XCharacter:GetCharacterQuality(characterId)
                end
                table.insert(result, {
                    CharacterId = characterId,
                    Quality = quality,
                })
            end
        end
        self:MoveCurrentCharacterToFirst(result, currentCharacterId)
        return result
    end

    local baseFormationCfg = formationGridData and formationGridData.BaseFormation
    local baseCharacterIds = baseFormationCfg and baseFormationCfg.BaseCharacterIds or {}
    for _, baseCharacterId in ipairs(baseCharacterIds) do
        local baseCharacterCfg = self:GetTeamRecommendBaseCharacter(baseCharacterId)
        if baseCharacterCfg then
            local characterId = baseCharacterCfg.CharacterId
            local quality = math.floor((baseCharacterCfg.CharacterQualityStar or 0) / 1000)
            table.insert(result, {
                CharacterId = characterId,
                Quality = quality,
            })
        end
    end
    self:MoveCurrentCharacterToFirst(result, currentCharacterId)
    return result
end

--- 获取推荐装备模板的可穿戴候选装备id：同模板在背包中或当前角色已穿戴的最优实例（穿戴优先），
--- 排除其他角色已穿戴；无候选返回nil（UI引导用；完成度公式只看当前穿戴）
function XTeamRecommendAgency:GetRecommendEquipCandidate(templateId, characterId)
    if not XTool.IsNumberValid(templateId) then
        return nil
    end

    local equipIds = XMVCA.XEquip:GetEnableEquipIdsByTemplateId(templateId, characterId)
    if XTool.IsTableEmpty(equipIds) then
        return nil
    end

    local function CountEquipResonance(equip, charId)
        local curChar, total = 0, 0
        for _, list in ipairs({equip.ResonanceInfo, equip.UnconfirmedResonanceInfo}) do
            for _, info in pairs(list or {}) do
                total = total + 1
                if info.CharacterId == charId then
                    curChar = curChar + 1
                end
            end
        end
        return curChar, total
    end

    table.sort(equipIds, function(equipIdA, equipIdB)
        local equipA = XMVCA.XEquip:GetEquip(equipIdA)
        local equipB = XMVCA.XEquip:GetEquip(equipIdB)
        if equipA.Breakthrough ~= equipB.Breakthrough then
            return equipA.Breakthrough > equipB.Breakthrough
        end
        if equipA.Level ~= equipB.Level then
            return equipA.Level > equipB.Level
        end

        local curCharResA, totalResA = CountEquipResonance(equipA, characterId)
        local curCharResB, totalResB = CountEquipResonance(equipB, characterId)
        if curCharResA ~= curCharResB then
            return curCharResA > curCharResB
        end
        if totalResA ~= totalResB then
            return totalResA > totalResB
        end

        return equipIdA < equipIdB
    end)

    for _, equipId in ipairs(equipIds) do
        if XMVCA.XEquip:IsEquipWearingByCharacterId(equipId, characterId) then
            return equipId
        end
    end
    return equipIds[1]
end

--- 目标辅助机的可携带候选实体：当前角色已携带的同模板，或角色类型可携带且未被他人携带的最优实例
---@return table|nil candidatePartner 候选辅助机实体
---@return boolean isCarried 候选是否已由当前角色携带
function XTeamRecommendAgency:GetRecommendPartnerCandidate(partnerId, characterId)
    if not XTool.IsNumberValid(partnerId) then
        return nil, false
    end

    local carryPartner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(characterId)
    if carryPartner and carryPartner:GetTemplateId() == partnerId then
        return carryPartner, true
    end

    local characterType = XMVCA.XCharacter:GetCharacterType(characterId)
    local partnerList = XDataCenter.PartnerManager.GetPartnerOverviewDataList(nil, characterType, false)
    local targetPartnerList = {}
    for _, partner in ipairs(partnerList or {}) do
        local isCanWear = not partner:GetIsCarry() or partner:GetCharacterId() == characterId
        if partner:GetTemplateId() == partnerId and isCanWear then
            table.insert(targetPartnerList, partner)
        end
    end

    local XPartnerSort = require("XUi/XUiPartner/PartnerCommon/XPartnerSort")
    XPartnerSort.CarrySortFunction(targetPartnerList, characterId)
    return targetPartnerList[1], false
end

--- 指定目标角色是否有装备可穿戴但尚未穿戴
function XTeamRecommendAgency:CheckTargetEquipCanWear(characterId, recommendCharData)
    if not recommendCharData then
        local detailData = self:BuildRoleTargetDetailData(characterId)
        recommendCharData = detailData and detailData.RecommendCharData
    end
    if not recommendCharData then
        return false
    end

    local weaponCandidateId = self:GetRecommendEquipCandidate(recommendCharData.WeaponId, characterId)
    if XTool.IsNumberValid(weaponCandidateId) and not XMVCA.XEquip:IsEquipWearingByCharacterId(weaponCandidateId, characterId) then
        return true
    end

    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local targetSlotData = recommendCharData.AwarenessSlotList and recommendCharData.AwarenessSlotList[site]
        local templateId = targetSlotData and targetSlotData.EquipTemplateId
        local candidateId = self:GetRecommendEquipCandidate(templateId, characterId)
        if XTool.IsNumberValid(candidateId) and not XMVCA.XEquip:IsEquipWearingByCharacterId(candidateId, characterId) then
            return true
        end
    end

    local partner, isCarried = self:GetRecommendPartnerCandidate(recommendCharData.PartnerId, characterId)
    return partner ~= nil and not isCarried
end

--- 按目标排序获取第一个有装备可穿戴但尚未穿戴的角色
---@param excludeCharacterId number|nil 不参与检查的角色Id
function XTeamRecommendAgency:GetFirstTargetEquipCanWearCharacterId(excludeCharacterId)
    for _, targetData in ipairs(self:GetServerCharacterTargetList()) do
        if targetData.CharacterId ~= excludeCharacterId and self:CheckTargetEquipCanWear(targetData.CharacterId) then
            return targetData.CharacterId
        end
    end
    return nil
end

--- 是否有目标装备已可穿戴但尚未穿戴
---@param excludeCharacterId number|nil 不参与检查的角色Id
function XTeamRecommendAgency:CheckHasTargetEquipCanWear(excludeCharacterId)
    return self:GetFirstTargetEquipCanWearCharacterId(excludeCharacterId) ~= nil
end

local TargetProgressWeightKey = {
    CharacterOwn = "CharacterOwn",
    CharacterLevel = "CharacterLevel",
    CharacterSkill = "CharacterSkill",
    WeaponWear = "WeaponWear",
    WeaponLevel = "WeaponLevel",
    WeaponResonance = "WeaponResonance",
    WeaponOverrun = "WeaponOverrun",
    AwarenessWear = "AwarenessWear",
    AwarenessLevel = "AwarenessLevel",
    AwarenessResonance = "AwarenessResonance",
    AwarenessOverclock = "AwarenessOverclock",
    PartnerWear = "PartnerWear",
    PartnerLevel = "PartnerLevel",
}
local function GetTargetProgressWeight(weightCfgMap, key)
    local cfg = weightCfgMap and weightCfgMap[key]
    if not cfg then
        XLog.Error("请检查配置表Client/TeamRecommend/TeamRecommendProgressWeight.tab，未配置行Key = " .. tostring(key))
        return 0
    end
    return cfg.Weight
end

-- 统一包装模块进度，供总进度和局部达成按钮复用。
local function BuildTargetProgressInfo(finishWeight, totalWeight)
    local progress = totalWeight > 0 and math.min(finishWeight / totalWeight, 1) or 0
    return {
        FinishWeight = finishWeight,
        TotalWeight = totalWeight,
        Progress = progress,
        IsModuleAchieved = totalWeight > 0 and progress >= 1,
    }
end

-- 把目标共鸣转成可重复匹配的类型+技能 key 列表。
local function BuildResonanceKeyList(resonanceList)
    local result = {}
    for _, resonanceData in pairs(resonanceList or {}) do
        if resonanceData and XTool.IsNumberValid(resonanceData.SkillId) then
            local key = tostring(resonanceData.ResonanceType or 0) .. "_" .. tostring(resonanceData.SkillId)
            table.insert(result, key)
        end
    end
    return result
end

-- 计算当前穿戴装备命中的目标共鸣数量。
local function GetEquipResonanceMatchCount(equip, characterId, targetResonanceKeyList)
    local actualCountMap = {}
    for _, resonanceInfo in pairs(equip:GetResonanceInfoDic() or {}) do
        local bindCharacterId = resonanceInfo and resonanceInfo.CharacterId or 0
        local skillId = resonanceInfo and resonanceInfo.TemplateId or 0
        local isBindSelf = not XTool.IsNumberValid(bindCharacterId) or bindCharacterId == characterId
        if XTool.IsNumberValid(skillId) and isBindSelf then
            local key = tostring((resonanceInfo and resonanceInfo.Type) or 0) .. "_" .. tostring(skillId)
            actualCountMap[key] = (actualCountMap[key] or 0) + 1
        end
    end

    local matchCount = 0
    for _, key in ipairs(targetResonanceKeyList or {}) do
        if actualCountMap[key] and actualCountMap[key] > 0 then
            matchCount = matchCount + 1
            actualCountMap[key] = actualCountMap[key] - 1
        end
    end
    return matchCount
end

--- 构建武器共鸣目标状态列表：五星武器只要求对应槽位已共鸣，其他武器要求目标技能已共鸣且绑定指定角色
---@param equipId number 武器实例Id
---@param characterId number 绑定角色Id
---@param targetSkillList number[] 目标共鸣技能Id列表
---@return table[] resonanceList { { Pos, SkillId, IsComplete }, ... }
---@return number completeCount
function XTeamRecommendAgency:BuildWeaponResonanceTargetStateList(equipId, characterId, targetSkillList)
    local actualSkillCount = {}
    local equip = XTool.IsNumberValid(equipId) and XMVCA.XEquip:GetEquip(equipId) or nil
    local isFiveStar = equip and XMVCA.XEquip:GetEquipStar(equip.TemplateId) == XEnumConst.EQUIP.FIVE_STAR
    -- 五星武器不比较目标技能，只按对应槽位是否已共鸣预填命中计数。
    if isFiveStar then
        for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
            local targetSkillId = targetSkillList and targetSkillList[pos] or 0
            if XTool.IsNumberValid(targetSkillId) and equip:GetResonanceInfo(pos) then
                actualSkillCount[targetSkillId] = (actualSkillCount[targetSkillId] or 0) + 1
            end
        end
    end
    if equip and not isFiveStar then
        for _, resonanceInfo in pairs(equip:GetResonanceInfoDic()) do
            local skillId = resonanceInfo and resonanceInfo.TemplateId or 0
            if XTool.IsNumberValid(skillId) and resonanceInfo.CharacterId == characterId then
                actualSkillCount[skillId] = (actualSkillCount[skillId] or 0) + 1
            end
        end
    end

    local resonanceList = {}
    local completeCount = 0
    for pos = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
        local targetSkillId = targetSkillList and targetSkillList[pos] or 0
        local skillCount = actualSkillCount[targetSkillId] or 0
        local isComplete = XTool.IsNumberValid(targetSkillId) and skillCount > 0
        if isComplete then
            actualSkillCount[targetSkillId] = skillCount - 1
            completeCount = completeCount + 1
        end
        resonanceList[pos] = {
            Pos = pos,
            SkillId = targetSkillId,
            IsComplete = isComplete == true,
        }
    end
    return resonanceList, completeCount
end

--- 获取角色本体模块进度（拥有角色、满级、技能满级）
function XTeamRecommendAgency:GetCharacterTargetRoleProgressInfo(recommendCharData)
    local characterId = recommendCharData and recommendCharData.CharacterId
    if not XTool.IsNumberValid(characterId) then
        return BuildTargetProgressInfo(0, 0)
    end

    local finishWeight = 0
    local totalWeight = 0
    local isOwnCharacter = XMVCA.XCharacter:IsOwnCharacter(characterId)
    local weightCfgMap = self._Model:GetTeamRecommendProgressWeight()
    local ownWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.CharacterOwn)
    local levelWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.CharacterLevel)
    local skillWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.CharacterSkill)

    -- 1. 角色ID：玩家拥有该角色。
    totalWeight = totalWeight + ownWeight
    if isOwnCharacter then
        finishWeight = finishWeight + ownWeight
    end

    -- 2. 角色等级：角色满级。
    totalWeight = totalWeight + levelWeight
    if isOwnCharacter and XMVCA.XCharacter:IsMaxLevel(characterId) then
        finishWeight = finishWeight + levelWeight
    end

    -- 3. 角色技能等级：角色全部技能满级。
    totalWeight = totalWeight + skillWeight
    if isOwnCharacter and XMVCA.XCharacter:CheckCharacterAllSkillMax(characterId) then
        finishWeight = finishWeight + skillWeight
    end

    return BuildTargetProgressInfo(finishWeight, totalWeight)
end

--- 获取武器模块进度（穿戴目标武器、满级、目标共鸣、目标谐振）
function XTeamRecommendAgency:GetCharacterTargetWeaponProgressInfo(recommendCharData)
    local characterId = recommendCharData and recommendCharData.CharacterId
    local weaponId = recommendCharData and recommendCharData.WeaponId
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(weaponId) then
        return BuildTargetProgressInfo(0, 0)
    end

    local finishWeight = 0
    local totalWeight = 0
    local wearingWeaponId = XMVCA.XEquip:GetCharacterWeaponId(characterId)
    local wearingWeapon = XTool.IsNumberValid(wearingWeaponId) and XMVCA.XEquip:GetEquip(wearingWeaponId) or nil
    local isWearingTargetWeapon = wearingWeapon and wearingWeapon.TemplateId == weaponId
    local weightCfgMap = self._Model:GetTeamRecommendProgressWeight()
    local wearWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.WeaponWear)
    local levelWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.WeaponLevel)
    local resonanceWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.WeaponResonance)
    local overrunWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.WeaponOverrun)

    -- 4. 武器ID：目标角色穿戴该武器。
    totalWeight = totalWeight + wearWeight
    if isWearingTargetWeapon then
        finishWeight = finishWeight + wearWeight
    end

    -- 5. 武器等级：当前穿戴的目标武器满级满突破。
    totalWeight = totalWeight + levelWeight
    if isWearingTargetWeapon and XMVCA.XEquip:IsMaxLevelAndBreakthrough(wearingWeaponId) then
        finishWeight = finishWeight + levelWeight
    end

    local targetResonanceKeyList = BuildResonanceKeyList(recommendCharData.WeaponResonanceList)
    local targetResonanceCount = #targetResonanceKeyList
    if targetResonanceCount > 0 then
        -- 6. 武器共鸣：当前穿戴的目标武器命中目标共鸣，按命中数折算。
        local matchCount = 0
        if isWearingTargetWeapon then
            local isFiveStar = XMVCA.XEquip:GetEquipStar(wearingWeapon.TemplateId) == XEnumConst.EQUIP.FIVE_STAR
            if isFiveStar then
                for slot = 1, XEnumConst.EQUIP.WEAPON_RESONANCE_COUNT do
                    local targetResonance = recommendCharData.WeaponResonanceList[slot]
                    if targetResonance and XTool.IsNumberValid(targetResonance.SkillId) and wearingWeapon:GetResonanceInfo(slot) then
                        matchCount = matchCount + 1
                    end
                end
            else
                matchCount = GetEquipResonanceMatchCount(wearingWeapon, characterId, targetResonanceKeyList)
            end
        end
        local resonanceProgress = math.min(matchCount, targetResonanceCount) / targetResonanceCount
        totalWeight = totalWeight + resonanceWeight
        finishWeight = finishWeight + resonanceWeight * resonanceProgress
    end

    local weaponOverrunSuitId = recommendCharData.WeaponOverrunChoseSuit
    if XTool.IsNumberValid(weaponOverrunSuitId) then
        -- 7. 武器谐振：当前穿戴的目标武器达到目标谐振。
        totalWeight = totalWeight + overrunWeight
        if isWearingTargetWeapon then
            local isSuitMatch = wearingWeapon:GetOverrunChoseSuit() == weaponOverrunSuitId
            if isSuitMatch and wearingWeapon:IsOverrunBlindMatch(characterId) then
                finishWeight = finishWeight + overrunWeight
            end
        end
    end

    return BuildTargetProgressInfo(finishWeight, totalWeight)
end

--- 获取意识模块进度（各槽位穿戴目标意识、满级、目标共鸣、超频）
function XTeamRecommendAgency:GetCharacterTargetAwarenessProgressInfo(recommendCharData)
    local characterId = recommendCharData and recommendCharData.CharacterId
    if not XTool.IsNumberValid(characterId) then
        return BuildTargetProgressInfo(0, 0)
    end

    local awarenessCount = XEnumConst.EQUIP.WEAR_AWARENESS_COUNT
    local resonanceSlotCount = XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT
    local overclockSlotCount = XEnumConst.EQUIP.MAX_AWAKE_COUNT
    local totalResonanceSlotCount = awarenessCount * resonanceSlotCount
    local totalOverclockSlotCount = awarenessCount * overclockSlotCount
    local awarenessWearCount = 0
    local awarenessLevelCount = 0
    local awarenessResonanceFinishCount = 0
    local awarenessOverclockFinishCount = 0
    local awarenessTargetSlotList = recommendCharData.AwarenessSlotList or {}
    local weightCfgMap = self._Model:GetTeamRecommendProgressWeight()
    local wearWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.AwarenessWear)
    local levelWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.AwarenessLevel)
    local resonanceWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.AwarenessResonance)
    local overclockWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.AwarenessOverclock)

    for site = 1, awarenessCount do
        local targetSlotData = awarenessTargetSlotList[site]
        local templateId = targetSlotData and targetSlotData.EquipTemplateId
        if not XTool.IsNumberValid(templateId) then
            XLog.Error(string.format("目标意识配置异常: CharacterId=%s, Site=%s", characterId, site))
        else
            local wearingAwareness = XMVCA.XEquip:GetCharacterEquip(characterId, site)
            local isWearingTargetAwareness = wearingAwareness and wearingAwareness.TemplateId == templateId

            -- 8. 意识ID：目标槽位穿戴该意识，6 个槽位按完成数折算。
            if isWearingTargetAwareness then
                awarenessWearCount = awarenessWearCount + 1
            end
            -- 9. 意识等级：当前槽位穿戴的目标意识满级满突破。
            if isWearingTargetAwareness and XMVCA.XEquip:IsMaxLevelAndBreakthrough(wearingAwareness.Id) then
                awarenessLevelCount = awarenessLevelCount + 1
            end

            local canResonance = XMVCA.XEquip:CanResonanceByTemplateId(templateId)
            if not canResonance then
                awarenessResonanceFinishCount = awarenessResonanceFinishCount + resonanceSlotCount
            else
                local targetResonanceKeyList = BuildResonanceKeyList(targetSlotData.ResonanceList)
                if #targetResonanceKeyList ~= resonanceSlotCount then
                    XLog.Error(string.format("目标意识共鸣配置异常: CharacterId=%s, Site=%s", characterId, site))
                end
                local matchCount = isWearingTargetAwareness and GetEquipResonanceMatchCount(wearingAwareness, characterId, targetResonanceKeyList) or 0
                awarenessResonanceFinishCount = awarenessResonanceFinishCount + math.min(matchCount, resonanceSlotCount)
            end

            local canOverclock = XMVCA.XEquip:GetEquipStar(templateId) >= XMVCA.XEquip:GetMinAwakeStar()
            if not canOverclock then
                awarenessOverclockFinishCount = awarenessOverclockFinishCount + overclockSlotCount
            elseif isWearingTargetAwareness then
                for pos = 1, overclockSlotCount do
                    if XMVCA.XEquip:IsEquipPosAwaken(wearingAwareness.Id, pos) then
                        awarenessOverclockFinishCount = awarenessOverclockFinishCount + 1
                    end
                end
            end
        end
    end

    local finishWeight = wearWeight * awarenessWearCount / awarenessCount
            + levelWeight * awarenessLevelCount / awarenessCount
            + resonanceWeight * awarenessResonanceFinishCount / totalResonanceSlotCount
            + overclockWeight * awarenessOverclockFinishCount / totalOverclockSlotCount
    local totalWeight = wearWeight + levelWeight + resonanceWeight + overclockWeight

    return BuildTargetProgressInfo(finishWeight, totalWeight)
end
--- 获取辅助机模块进度（携带目标辅助机、辅助机满级）
function XTeamRecommendAgency:GetCharacterTargetPartnerProgressInfo(recommendCharData)
    local characterId = recommendCharData and recommendCharData.CharacterId
    local partnerId = recommendCharData and recommendCharData.PartnerId
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(partnerId) then
        return BuildTargetProgressInfo(0, 0)
    end

    local finishWeight = 0
    local totalWeight = 0
    local carryPartner = XDataCenter.PartnerManager.GetCarryPartnerEntityByCarrierId(characterId)
    local isCarryTargetPartner = carryPartner and carryPartner:GetTemplateId() == partnerId
    local weightCfgMap = self._Model:GetTeamRecommendProgressWeight()
    local wearWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.PartnerWear)
    local levelWeight = GetTargetProgressWeight(weightCfgMap, TargetProgressWeightKey.PartnerLevel)

    -- 11. 辅助机ID：目标角色携带该辅助机。
    totalWeight = totalWeight + wearWeight
    if isCarryTargetPartner then
        finishWeight = finishWeight + wearWeight
    end

    -- 12. 辅助机等级：当前携带的目标辅助机满级。
    totalWeight = totalWeight + levelWeight
    if isCarryTargetPartner and XMVCA.XPartner:GetOneKeyCultureAgency():IsCultureTypeMax(carryPartner:GetId(), XMVCA.XPartner.Enum.CultureType.LevelUp) then
        finishWeight = finishWeight + levelWeight
    end

    return BuildTargetProgressInfo(finishWeight, totalWeight)
end

--- 获取角色当前服务端目标完成度；达到100%时自动上报完成
function XTeamRecommendAgency:GetServerCharacterTargetProgressAndCheckFinish(recommendCharData)
    if not recommendCharData then
        return 0
    end

    local characterId = recommendCharData.CharacterId
    if not XTool.IsNumberValid(characterId) then
        return 0
    end

    local target = self:GetServerCharacterTarget(characterId)
    if not target then
        return 0
    end

    local baseCfgId = target.BaseCharacterId
    local teamCfgId = target.TeamCfgId
    if XTool.IsNumberValid(baseCfgId) then
        if recommendCharData.BaseCfgId ~= baseCfgId then
            return 0
        end
    elseif XTool.IsNumberValid(teamCfgId) then
        if recommendCharData.TargetTeamCfgId ~= teamCfgId then
            return 0
        end
    else
        return 0
    end

    local finishWeight = 0
    local totalWeight = 0

    -- 角色、武器、意识、辅助机：各模块独立计算，便于详情页局部达成复用。
    local progressInfoList = {
        self:GetCharacterTargetRoleProgressInfo(recommendCharData),
        self:GetCharacterTargetWeaponProgressInfo(recommendCharData),
        self:GetCharacterTargetAwarenessProgressInfo(recommendCharData),
        self:GetCharacterTargetPartnerProgressInfo(recommendCharData),
    }
    for _, progressInfo in ipairs(progressInfoList) do
        finishWeight = finishWeight + progressInfo.FinishWeight
        totalWeight = totalWeight + progressInfo.TotalWeight
    end

    if totalWeight <= 0 then
        return 0
    end
    local progress = math.min(finishWeight / totalWeight, 1)

    if progress >= 1 then
        self:TeamRecommendFinishTargetRequest(characterId)
    elseif progress * 100 >= self:GetTargetFinishPercentage() then
        self:TeamRecommendFinishTargetEventRequest(characterId)
    end

    return progress
end

--- 按角色检查当前服务端目标完成度；给一键养成等外部养成流程调用
function XTeamRecommendAgency:GetServerCharacterTargetProgressAndCheckFinishByCharacterId(characterId)
    local target = self:GetServerCharacterTarget(characterId)
    if not target then
        return 0
    end

    local baseCfgId = target.BaseCharacterId
    if XTool.IsNumberValid(baseCfgId) then
        return self:GetServerCharacterTargetProgressAndCheckFinish(self:FromCfgData(self:GetTeamRecommendBaseCharacter(baseCfgId)))
    end

    return self:GetServerCharacterTargetProgressAndCheckFinish(self:GetCharacterTargetCharData(characterId))
end

--- 按角色字典检查当前服务端目标完成度
function XTeamRecommendAgency:CheckServerCharacterTargetsProgressAndFinish(characterIdDic)
    for characterId in pairs(characterIdDic or {}) do
        self:GetServerCharacterTargetProgressAndCheckFinishByCharacterId(characterId)
    end
end

--- 遍历检查所有当前服务端目标完成度
function XTeamRecommendAgency:CheckAllServerCharacterTargetProgressAndFinish()
    local targetDataList = self:GetServerCharacterTargetList()
    for _, targetData in ipairs(targetDataList) do
        self:GetServerCharacterTargetProgressAndCheckFinishByCharacterId(targetData.CharacterId)
    end
end

--============================================================== #endregion 服务端目标数据 ==============================================================

--endregion ----------public end----------

--region ----------数据转换----------

-- 将角色技能池配置换算成实际技能ID。
local function NormalizeSkillId(resonanceType, skillId)
    if resonanceType == XEnumConst.EQUIP.RESONANCE_TYPE.CHARACTER_SKILL then
        local row = XMVCA.XCharacter:GetCharacterSkillPoolRowById(skillId)
        if row then
            return row.SkillId
        end
    end
    return skillId
end

-- 构造单个意识槽位的目标配置，只保留模板、套装和目标共鸣。
local function BuildAwarenessTargetSlotData(site, templateId)
    local resonanceList = {}
    for pos = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
        resonanceList[pos] = {
            Pos = pos,
            SkillId = 0,
            ResonanceType = 0,
        }
    end

    local targetSlotData = {
        Site = site,
        EquipTemplateId = templateId or 0,
        SuitId = XTool.IsNumberValid(templateId) and XMVCA.XEquip:GetEquipSuitId(templateId) or 0,
        ResonanceList = resonanceList,
        IsOverrun = false,
    }
    return targetSlotData
end

-- 预留共鸣预期本地缓存覆写入口。
local function ApplyAwarenessResonanceExpectCache(targetSlotData, characterId, baseCfgId)
    if not characterId or not baseCfgId then
        return targetSlotData
    end

    -- TODO: 修改共鸣预期接入后，在这里读取每个角色/方案的本地缓存，
    -- 覆写目标共鸣为方案指定、任意攻击或任意技能。
    return targetSlotData
end

-- 写入单个意识槽的目标共鸣数据。
local function SetAwarenessResonance(targetSlotData, skillId, resonanceType, pos)
    if not targetSlotData or not XTool.IsNumberValid(skillId) then
        return
    end

    pos = tonumber(pos) or pos
    skillId = tonumber(skillId) or skillId
    resonanceType = tonumber(resonanceType) or resonanceType
    if not XTool.IsNumberValid(pos) or pos > XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT then
        local emptyPos
        for index = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            local data = targetSlotData.ResonanceList[index]
            if not data or not XTool.IsNumberValid(data.SkillId) then
                emptyPos = index
                break
            end
        end
        pos = emptyPos
    end
    if not pos then
        return
    end

    targetSlotData.ResonanceList[pos] = {
        Pos = pos,
        SkillId = skillId,
        ResonanceType = resonanceType or 0,
    }
end

-- 按意识位和共鸣槽读取配置表目标共鸣。
local function GetCfgAwarenessResonance(baseCharacterCfg, site, slot)
    local cfgIndex = (site - 1) * XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT + slot
    local skillId = baseCharacterCfg.EquipSkillIds and baseCharacterCfg.EquipSkillIds[cfgIndex]
    local resonanceType = baseCharacterCfg.EquipResonanceTypes and baseCharacterCfg.EquipResonanceTypes[cfgIndex]

    if XTool.IsNumberValid(skillId) and XTool.IsNumberValid(resonanceType) then
        skillId = NormalizeSkillId(resonanceType, skillId)
    end

    return skillId or 0, resonanceType or 0
end

--- 将服务端下发的 XTeamRecommendCharacter 转换为归一化数据
function XTeamRecommendAgency:FromServerData(characterData)
    if not characterData then return nil end

    local characterId = characterData.CharacterId
    local grade = characterData.CharacterQualityStar or 0
    local quality = math.floor(grade / 1000)
    if not XTool.IsNumberValid(quality) then
        quality = XMVCA.XCharacter:GetCharacterQuality(characterId)
    end
    local star = grade % 1000

    -- 意识按套装分组
    local suitDataMap = {}
    local suitDataList = {}
    local equipIds = characterData.EquipIds
    local awarenessTargetSlotList = {}
    local awarenessEquipIds = equipIds or {}
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        awarenessTargetSlotList[site] = BuildAwarenessTargetSlotData(site, awarenessEquipIds[site] or 0)
    end

    -- EquipResonanceDatas 固定12条平铺（第1件第1/2条、第2件第1/2条…），空槽占位。
    -- 件序=ceil(下标/每件共鸣数)，条目里的 Slot 是该意识上的共鸣槽位。
    for index, resonanceData in ipairs(characterData.EquipResonanceDatas or {}) do
        local site = math.ceil(index / XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT)
        local targetSlotData = awarenessTargetSlotList[site]
        SetAwarenessResonance(targetSlotData, resonanceData.TemplateId, resonanceData.Type, resonanceData.Slot)
    end
    for site, targetSlotData in pairs(awarenessTargetSlotList) do
        awarenessTargetSlotList[site] = ApplyAwarenessResonanceExpectCache(targetSlotData, characterId, characterData.BaseCfgId)
    end

    if equipIds then
        for _, templateId in ipairs(equipIds) do
            if XTool.IsNumberValid(templateId) then
                local suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
                local data = suitDataMap[suitId]
                if not data then
                    data = { SuitId = suitId, Count = 0, SkillIds = {} }
                    suitDataMap[suitId] = data
                    table.insert(suitDataList, data)
                end
                data.Count = data.Count + 1
            end
        end
    end

    -- 从 EquipResonanceDatas 提取共鸣技能，按 suitId 归组（固定12条平铺，件序=ceil(下标/每件共鸣数)）
    if equipIds then
        for index, resonanceData in ipairs(characterData.EquipResonanceDatas or {}) do
            local skillId = resonanceData.TemplateId
            if XTool.IsNumberValid(skillId) then
                local site = math.ceil(index / XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT)
                local templateId = equipIds[site]
                if XTool.IsNumberValid(templateId) then
                    local suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
                    local data = suitDataMap[suitId]
                    if data then
                        table.insert(data.SkillIds, {
                            SkillId = skillId,
                            ResonanceType = resonanceData.Type or 0,
                            EquipTemplateId = templateId,
                        })
                    end
                end
            end
        end
    end

    -- 武器共鸣类型只有属性/武器技能两种。
    local weaponResonanceList = {}
    for _, resonanceData in ipairs(characterData.WeaponResonanceDatas or {}) do
        local slot = resonanceData.Slot
        if XTool.IsNumberValid(slot) and slot <= 3 and XTool.IsNumberValid(resonanceData.TemplateId) then
            weaponResonanceList[slot] = {
                SkillId = resonanceData.TemplateId,
                ResonanceType = resonanceData.Type or 0,
            }
        end
    end

    -- 排序
    self:SortSuitDataList(suitDataList)

    return {
        BaseCfgId = characterData.BaseCfgId or 0,
        CharacterId = characterId,
        Quality = quality,
        Star = star,
        WeaponId = characterData.WeaponId or 0,
        WeaponOverrunChoseSuit = characterData.WeaponOverrunChoseSuit or 0,
        PartnerId = characterData.PartnerId or 0,
        WeaponResonanceList = weaponResonanceList,
        SuitDataList = suitDataList,
        AwarenessSlotList = awarenessTargetSlotList,
    }
end

--- 将死数据 baseCharacterCfg 转换为归一化数据
function XTeamRecommendAgency:FromCfgData(baseCharacterCfg)
    if not baseCharacterCfg then return nil end

    local characterId = baseCharacterCfg.CharacterId
    local grade = baseCharacterCfg.CharacterQualityStar or 0
    local quality = math.floor(grade / 1000)
    local star = grade % 1000

    -- 武器共鸣：直接用配表的 WeaponResonanceTypes + WeaponResonanceSkillIds。
    local weaponResonanceList = {}
    local cfgTypeList = baseCharacterCfg.WeaponResonanceTypes or {}
    local cfgSkillList = baseCharacterCfg.WeaponResonanceSkillIds or {}
    for i = 1, 3 do
        local rType = cfgTypeList[i]
        local skillId = cfgSkillList[i]
        if XTool.IsNumberValid(skillId) and XTool.IsNumberValid(rType) then
            weaponResonanceList[i] = {
                SkillId = skillId,
                ResonanceType = rType,
            }
        end
    end

    -- 意识按套装分组
    local suitDataMap = {}
    local suitDataList = {}
    local equipIds = baseCharacterCfg.EquipIds
    local awarenessTargetSlotList = {}
    local awarenessEquipIds = equipIds or {}
    for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
        local templateId = awarenessEquipIds[site] or 0
        local targetSlotData = BuildAwarenessTargetSlotData(site, templateId)
        for slot = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
            local skillId, resonanceType = GetCfgAwarenessResonance(baseCharacterCfg, site, slot)
            SetAwarenessResonance(targetSlotData, skillId, resonanceType, slot)
        end
        awarenessTargetSlotList[site] = ApplyAwarenessResonanceExpectCache(targetSlotData, characterId, baseCharacterCfg.Id)
    end

    if equipIds then
        for site, templateId in ipairs(equipIds) do
            if XTool.IsNumberValid(templateId) then
                local suitId = XMVCA.XEquip:GetEquipSuitId(templateId)
                local data = suitDataMap[suitId]
                if not data then
                    data = { SuitId = suitId, Count = 0, SkillIds = {} }
                    suitDataMap[suitId] = data
                    table.insert(suitDataList, data)
                end
                data.Count = data.Count + 1
                for slot = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
                    local skillId, rType = GetCfgAwarenessResonance(baseCharacterCfg, site, slot)
                    if XTool.IsNumberValid(skillId) then
                        table.insert(data.SkillIds, {
                            SkillId = skillId,
                            ResonanceType = rType or 0,
                            EquipTemplateId = templateId,
                        })
                    end
                end
            end
        end
    end

    -- 排序
    self:SortSuitDataList(suitDataList)

    return {
        BaseCfgId = baseCharacterCfg.Id,
        CharacterId = characterId,
        Quality = quality,
        Star = star,
        WeaponId = baseCharacterCfg.WeaponId or 0,
        WeaponOverrunChoseSuit = baseCharacterCfg.WeaponOverrunChoseSuit or 0,
        PartnerId = baseCharacterCfg.PartnerId or 0,
        WeaponResonanceList = weaponResonanceList,
        SuitDataList = suitDataList,
        AwarenessSlotList = awarenessTargetSlotList,
    }
end

--- 配置表来源拼阵容快照（XTeamRecommendFormationData 协议结构）。
--- 已弃用用途：死配置设目标不再用它拼快照上传服务端，只发SourceId=BaseFormation.Id；
--- 保留用于本地展示/完成度，以及回包Target只有BaseFormationId时还原。
function XTeamRecommendAgency:BuildTargetFormationFromCfg(baseFormationCfg)
    if not baseFormationCfg then
        return nil
    end

    local characterDatas = {}
    for _, baseCharacterId in ipairs(baseFormationCfg.BaseCharacterIds or {}) do
        local baseCharacterCfg = self:GetTeamRecommendBaseCharacter(baseCharacterId)
        if baseCharacterCfg then
            -- 意识共鸣固定12条平铺、空槽占位；协议内快照统一为最终技能id。
            local equipResonanceDatas = {}
            for site = 1, XEnumConst.EQUIP.WEAR_AWARENESS_COUNT do
                for slot = 1, XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT do
                    local skillId, resonanceType = GetCfgAwarenessResonance(baseCharacterCfg, site, slot)
                    local flatIndex = (site - 1) * XEnumConst.EQUIP.AWARENESS_RESONANCE_COUNT + slot
                    equipResonanceDatas[flatIndex] = { Slot = slot, Type = resonanceType, TemplateId = skillId }
                end
            end

            -- 武器共鸣类型只有属性/武器技能，配表原值直传，无需换算。
            local weaponResonanceDatas = {}
            local cfgTypeList = baseCharacterCfg.WeaponResonanceTypes or {}
            local cfgSkillList = baseCharacterCfg.WeaponResonanceSkillIds or {}
            for i = 1, 3 do
                local skillId = cfgSkillList[i]
                local resonanceType = cfgTypeList[i]
                if XTool.IsNumberValid(skillId) and XTool.IsNumberValid(resonanceType) then
                    table.insert(weaponResonanceDatas, {
                        Slot = i,
                        Type = resonanceType,
                        TemplateId = skillId,
                    })
                end
            end

            table.insert(characterDatas, {
                CharacterId = baseCharacterCfg.CharacterId,
                CharacterQualityStar = baseCharacterCfg.CharacterQualityStar or 0,
                WeaponId = baseCharacterCfg.WeaponId or 0,
                WeaponOverrunChoseSuit = baseCharacterCfg.WeaponOverrunChoseSuit or 0,
                WeaponResonanceDatas = weaponResonanceDatas,
                EquipIds = baseCharacterCfg.EquipIds or {},
                EquipResonanceDatas = equipResonanceDatas,
                PartnerId = baseCharacterCfg.PartnerId or 0,
            })
        end
    end

    -- 服务端校验阵容3人，配表残缺直接拦截不发
    if #characterDatas ~= 3 then
        XLog.Error("[XTeamRecommendAgency] 阵容配置人数异常，BaseFormationId = " .. tostring(baseFormationCfg.Id) .. "，人数 = " .. #characterDatas)
        return nil
    end

    return { CharacterDatas = characterDatas }
end

--- 排序套装和共鸣技能（内部复用）
function XTeamRecommendAgency:SortSuitDataList(suitDataList)
    -- 排序套装：数量多靠前，数量相同时suitId大的靠前
    table.sort(suitDataList, function(a, b)
        if a.Count ~= b.Count then
            return a.Count > b.Count
        end
        return a.SuitId > b.SuitId
    end)
    -- 排序每个套装内的共鸣技能：数量大靠前，数量相同时skillId大的靠前
    for _, data in ipairs(suitDataList) do
        local skillCntMap = {}
        local skillExtraMap = {}
        for _, item in ipairs(data.SkillIds) do
            local sid = item.SkillId
            skillCntMap[sid] = (skillCntMap[sid] or 0) + 1
            if not skillExtraMap[sid] then
                skillExtraMap[sid] = { EquipTemplateId = item.EquipTemplateId, ResonanceType = item.ResonanceType }
            end
        end
        local sorted = {}
        for sid, cnt in pairs(skillCntMap) do
            local extra = skillExtraMap[sid]
            table.insert(sorted, {
                SkillId = sid,
                Count = cnt,
                ResonanceType = extra.ResonanceType,
                EquipTemplateId = extra.EquipTemplateId,
            })
        end
        table.sort(sorted, function(a, b)
            if a.Count ~= b.Count then
                return a.Count > b.Count
            end
            return a.SkillId > b.SkillId
        end)
        data.SortedSkillList = sorted
    end
end

--endregion ----------数据转换----------

--============================================================== #region 协议请求 ==============================================================

--- 查询指定阵容推荐详情
function XTeamRecommendAgency:TeamRecommendFormationRequest(characterId, teamCfgIds, cb)
    if not XTool.IsNumberValid(characterId) or not teamCfgIds then
        if cb then cb(false, nil, nil) end
        return
    end

    XNetwork.Call(RequestName.TeamRecommendFormationRequest, { CharacterId = characterId,TeamCfgIds = teamCfgIds }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then cb(false, nil, res) end
            return
        end

        self._Model:UpdateServerFormationDatas(characterId, res.TeamRecommendFormations, teamCfgIds)
        if cb then
            cb(true, res.TeamRecommendFormations or {}, res)
        end
    end)
end

--- 设定角色单个目标
function XTeamRecommendAgency:TeamRecommendSetTargetRequest(characterId, baseCfgId, cb)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(baseCfgId) then
        return
    end

    XNetwork.Call(RequestName.TeamRecommendSetTargetRequest, { CharacterId = characterId, BaseCfgId = baseCfgId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateServerCharacterTarget(characterId, res.Target)
        XEventManager.DispatchEvent(XEventId.EVENT_TEAM_RECOMMEND_TARGET_STATE_CHANGE)
        XUiManager.TipText("TeamRecommendSetTargetSuccess")
        if cb then cb(res) end
    end)
end

--- 设定角色阵容目标：BaseFormationId属于回包Target结构；请求只传来源，只有TopDetail来源带TargetFormation快照。
function XTeamRecommendAgency:TeamRecommendSetFormationTargetRequest(characterId, teamCfgId, targetFormation, sourceType, sourceId, cb)
    if not XTool.IsNumberValid(characterId) or not XTool.IsNumberValid(teamCfgId) then
        return
    end

    local srcType = XEnumConst.TeamRecommend.TargetSrcType
    if sourceType == srcType.FromTopDetail and not targetFormation then
        XLog.Error("[XTeamRecommendAgency] TargetFormation is nil, SourceType = " .. tostring(sourceType) .. ", TeamCfgId = " .. tostring(teamCfgId))
        return
    end

    local request = {CharacterId = characterId, TeamCfgId = teamCfgId, SourceType = sourceType, SourceId = sourceId}
    if sourceType == srcType.FromTopDetail then
        request.TargetFormation = targetFormation
    end

    XNetwork.Call(RequestName.TeamRecommendSetFormationTargetRequest, request, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            return
        end

        self._Model:UpdateServerCharacterTarget(characterId, res.Target)
        XEventManager.DispatchEvent(XEventId.EVENT_TEAM_RECOMMEND_TARGET_STATE_CHANGE)
        XUiManager.TipText("TeamRecommendSetTargetSuccess")
        if cb then cb(res) end
    end)
end

--- Debug纯查看：打印所有设定目标，不接业务、不刷新本地缓存
function XTeamRecommendAgency:TeamRecommendGetAllTargetsRequest(cb)
    XNetwork.Call(RequestName.TeamRecommendGetAllTargetsRequest, {}, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then cb(false, res) end
            return
        end

        XLog.Debug("[XTeamRecommendAgency] GetAllTargets：", res.CharacterTargets)
        if cb then cb(true, res) end
    end)
end

--- 删除角色目标
function XTeamRecommendAgency:TeamRecommendDeleteTargetRequest(characterId, cb)
    if not XTool.IsNumberValid(characterId) then
        if cb then cb(false, nil) end
        return
    end

    XNetwork.Call(RequestName.TeamRecommendDeleteTargetRequest, { CharacterId = characterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then cb(false, res) end
            return
        end

        self._Model:DeleteServerCharacterTarget(characterId)
        XEventManager.DispatchEvent(XEventId.EVENT_TEAM_RECOMMEND_TARGET_STATE_CHANGE)
        if cb then cb(true, res) end
    end)
end

--- 完成角色目标
function XTeamRecommendAgency:TeamRecommendFinishTargetRequest(characterId, cb)
    if not XTool.IsNumberValid(characterId) then
        if cb then cb(false, nil) end
        return
    end

    if self._FinishTargetRequesting[characterId] then
        return
    end

    self._FinishTargetRequesting[characterId] = true
    XNetwork.Call(RequestName.TeamRecommendFinishTargetRequest, { CharacterId = characterId }, function(res)
        self._FinishTargetRequesting[characterId] = nil
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
            if cb then cb(false, res) end
            return
        end

        -- 回包只有Code；成功后按约定移除本地当前目标缓存。
        self._Model:DeleteServerCharacterTarget(characterId)
        XEventManager.DispatchEvent(XEventId.EVENT_TEAM_RECOMMEND_TARGET_STATE_CHANGE)
        if cb then cb(true, res) end
    end)
end

--- 上报角色目标完成度达到任务阈值
function XTeamRecommendAgency:TeamRecommendFinishTargetEventRequest(characterId)
    if not XTool.IsNumberValid(characterId) then
        return
    end

    XNetwork.Call(RequestName.TeamRecommendFinishTargetEventRequest, { CharacterId = characterId }, function(res)
        if res.Code ~= XCode.Success then
            XUiManager.TipCode(res.Code)
        end
    end)
end

--============================================================== #endregion 协议请求 ==============================================================

-- Notify协议相关
--- 全量当前目标数据推送（data.CharacterTargets 是整个Db，内层 CharacterTargets 是当前目标字典）
function XTeamRecommendAgency:NotifyTeamRecommendTargetData(data)
    self._Model:UpdateServerCharacterTargets(data and data.CharacterTargets)
    XEventManager.DispatchEvent(XEventId.EVENT_TEAM_RECOMMEND_TARGET_STATE_CHANGE)
    self:CheckAllServerCharacterTargetProgressAndFinish()
end

return XTeamRecommendAgency
