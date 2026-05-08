XPgsAchievementManager = XPgsAchievementManager or {}

local Json = require("XCommon/Json")

-------------------------------
-- PGS成就ID枚举（按区服管理）
-------------------------------
local PgsAchievementEnum = {
    MainLine1_12 = "MainLine1_12",                -- 首次通關主線劇情1-12
    RoleDevelopI = "RoleDevelopI",                -- 角色研發I（角色池抽卡累計達到60次數）
    ThreeMembersLv15 = "ThreeMembersLv15",        -- 3個成員升級至15級
    TrustLevel3 = "TrustLevel3",                  -- 1個成員信賴度達到3級
    SixAwarenessLv20 = "SixAwarenessLv20",        -- 擁有6件20級意識
    BossSingleWin20 = "BossSingleWin20",          -- 通關幻痛囚籠20次
    SixStarWeapon = "SixStarWeapon",              -- 擁有1件6星武器
    RoleDevelopII = "RoleDevelopII",              -- 角色研發II（角色池抽卡累計達到120次數）
    SkillUpgrade60 = "SkillUpgrade60",            -- 升級成員技能60次
    RoleDevelopIII = "RoleDevelopIII",            -- 角色研發III（角色池抽卡累計達到180次數）
}

-- 各服成就ID配置
local PgsAchievementIdConfig = {
    TW = {
        [PgsAchievementEnum.MainLine1_12] = "CgkIwYODm5cQEAIQAQ",
        [PgsAchievementEnum.RoleDevelopI] = "CgkIwYODm5cQEAIQCA",
        [PgsAchievementEnum.ThreeMembersLv15] = "CgkIwYODm5cQEAIQBA",
        [PgsAchievementEnum.TrustLevel3] = "CgkIwYODm5cQEAIQAg",
        [PgsAchievementEnum.SixAwarenessLv20] = "CgkIwYODm5cQEAIQBQ",
        [PgsAchievementEnum.BossSingleWin20] = "CgkIwYODm5cQEAIQBg",
        [PgsAchievementEnum.SixStarWeapon] = "CgkIwYODm5cQEAIQAw",
        [PgsAchievementEnum.RoleDevelopII] = "CgkIwYODm5cQEAIQCQ",
        [PgsAchievementEnum.SkillUpgrade60] = "CgkIwYODm5cQEAIQBw",
        [PgsAchievementEnum.RoleDevelopIII] = "CgkIwYODm5cQEAIQCg",
    },
    -- 后续其他服在此扩展
    -- JP = {},
    -- KR = {},
    -- EN = {},
}

-------------------------------
-- 内部状态
-------------------------------
local UnlockedCache = {} -- 已解锁成就缓存（仅当前会话），避免重复调用SDK
local IncrementReportedCache = {} -- 增量成就已上报项缓存，key=achievementEnum，value=已上报id集合

-- 增量成就缓存清理阈值（防止本地存档无限增长）
local IncrementReportedCacheLimit = {
    ThreeMembersLv15 = 6,
    SixAwarenessLv20 = 12,
}

-- 统计哈希表元素数量（reported 以 id 为 key，不能用 #）
local function GetTableCount(t)
    if not t then
        return 0
    end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function GetReportedSaveKey(achievementEnum)
    return "PgsReported_" .. achievementEnum .. "_" .. XPlayer.Id
end

local function LoadReportedCache(achievementEnum)
    local saveKey = GetReportedSaveKey(achievementEnum)
    local data = XSaveTool.GetData(saveKey)
    if data then
        IncrementReportedCache[achievementEnum] = data
    end
end

local function SaveReportedCache(achievementEnum)
    XSaveTool.SaveData(GetReportedSaveKey(achievementEnum), IncrementReportedCache[achievementEnum])
end

-------------------------------
-- 辅助函数
-------------------------------
local function IsPGSEnable()
    local ok, value = pcall(function()
        return CS.XHeroSdkAgent.IsPGSEnable
    end)
    return ok and value == true
end
local function GetRegionKey()
    if XOverseaManager.IsTWRegion() then
        return "TW"
    -- elseif XOverseaManager.IsJPRegion() then
    --     return "JP"
    -- elseif XOverseaManager.IsKRRegion() then
    --     return "KR"
    -- elseif XOverseaManager.IsENRegion() then
    --     return "EN"
    end
    return nil
end

local function GetAchievementId(achievementEnum)
    local regionKey = GetRegionKey()
    if not regionKey then
        return nil
    end
    local regionConfig = PgsAchievementIdConfig[regionKey]
    if not regionConfig then
        return nil
    end
    return regionConfig[achievementEnum]
end

local function IsSDKResultSuccessful(result)
    if not result then
        return false
    end
    local ok, data = pcall(Json.decode, result)
    return ok and data and data.isSuccessful == true
end

local function TryUnlock(achievementEnum)
    if not IsPGSEnable() then
        return
    end
    local achievementId = GetAchievementId(achievementEnum)
    if not achievementId then
        return
    end
    if UnlockedCache[achievementId] then
        return
    end
    XLog.Debug("[PGS] UnlockAchievement: " .. achievementEnum .. " id=" .. achievementId)
    local result = CS.XHeroSdkAgent.PGSUnlockAchievement(achievementId)
    if IsSDKResultSuccessful(result) then
        UnlockedCache[achievementId] = true
    end
end

local function TryIncrement(achievementEnum, step)
    if not IsPGSEnable() then
        return
    end
    local achievementId = GetAchievementId(achievementEnum)
    if not achievementId then
        return
    end
    XLog.Debug("[PGS] IncrementAchievement: " .. achievementEnum .. " step=" .. tostring(step) .. " id=" .. achievementId)
    local result = CS.XHeroSdkAgent.PGSIncrementAchievement(achievementId, step)
end

-------------------------------
-- 成就条件检查
-------------------------------

-- 主线1-12通关（第一章第12关，关卡ID：10010304）
local function CheckMainLine1_12()
    local isPass = XDataCenter.FubenManager.CheckStageIsPass(10010304)
    if isPass then
        TryUnlock(PgsAchievementEnum.MainLine1_12)
    end
end

-- 角色研发（角色池抽卡，单抽+1，十连+10）
local function CheckRoleDevelop(drawId, count)
    if not drawId or not count then
        return
    end
    local drawSceneCfg = XDrawConfigs.GetDrawSceneCfg(drawId)
    if not drawSceneCfg or drawSceneCfg.Type ~= XDrawConfigs.ModelType.Role then
        return
    end
    TryIncrement(PgsAchievementEnum.RoleDevelopI, count)
    TryIncrement(PgsAchievementEnum.RoleDevelopII, count)
    TryIncrement(PgsAchievementEnum.RoleDevelopIII, count)
end

-- 3个成员15级（增量类型，角色达到15级时increment+1，PGS累计达到3自动解锁）
local function CheckThreeMembersLv15(characterId)
    if not characterId then
        return
    end
    local reported = IncrementReportedCache[PgsAchievementEnum.ThreeMembersLv15] or {}
    -- 超过上限时清空缓存并保存，防止本地存档无限增长
    if GetTableCount(reported) > IncrementReportedCacheLimit.ThreeMembersLv15 then
        reported = {}
        IncrementReportedCache[PgsAchievementEnum.ThreeMembersLv15] = reported
        SaveReportedCache(PgsAchievementEnum.ThreeMembersLv15)
    end
    if reported[characterId] then
        return
    end
    local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
    local level = characterAgency:GetCharacterLevel(characterId)
    if level >= 15 then
        reported[characterId] = true
        IncrementReportedCache[PgsAchievementEnum.ThreeMembersLv15] = reported
        SaveReportedCache(PgsAchievementEnum.ThreeMembersLv15)
        TryIncrement(PgsAchievementEnum.ThreeMembersLv15, 1)
    end
end

-- 信赖度3级（只检查当前变化的角色）
local function CheckTrustLevel3(characterId, trustLv)
    if not characterId then
        return
    end
    if trustLv and trustLv >= 3 then
        TryUnlock(PgsAchievementEnum.TrustLevel3)
    end
end

-- 6件20级意识（增量类型，意识达到20级时increment+1，PGS累计达到6自动解锁）
local function CheckSixAwarenessLv20(equipId)
    if not equipId then
        return
    end
    local reported = IncrementReportedCache[PgsAchievementEnum.SixAwarenessLv20] or {}
    -- 超过上限时清空缓存并保存，防止本地存档无限增长
    if GetTableCount(reported) > IncrementReportedCacheLimit.SixAwarenessLv20 then
        reported = {}
        IncrementReportedCache[PgsAchievementEnum.SixAwarenessLv20] = reported
        SaveReportedCache(PgsAchievementEnum.SixAwarenessLv20)
    end
    if reported[equipId] then
        return
    end
    local equipAgency = XMVCA:GetAgency(ModuleId.XEquip)
    local equipDic = equipAgency:GetEquipDic()
    local equip = equipDic[equipId]
    if equip and equip:IsAwareness() and equip.Level >= 20 then
        reported[equipId] = true
        IncrementReportedCache[PgsAchievementEnum.SixAwarenessLv20] = reported
        SaveReportedCache(PgsAchievementEnum.SixAwarenessLv20)
        TryIncrement(PgsAchievementEnum.SixAwarenessLv20, 1)
    end
end

-- 通关幻痛囚笼20次（增量类型，每次通关increment+1，PGS累计达到20自动解锁）
local function CheckBossSingleWin(stageId)
    if not XMVCA.XFubenBossSingle:IsBossSingleStage(stageId) then
        return
    end
    TryIncrement(PgsAchievementEnum.BossSingleWin20, 1)
end

-- 6星武器（从武器池抽卡结果中检查是否获得6星武器）
local function CheckSixStarWeaponFromDrawResult(drawId, rewardList)
    if not drawId or not rewardList then
        return
    end
    local combination = XDataCenter.DrawManager.GetDrawCombination(drawId)
    if not combination or combination.Type ~= XDrawConfigs.ModelType.Weapon then
        return
    end
    for _, reward in ipairs(rewardList) do
        local templateId = reward.Id and reward.Id > 0 and reward.Id or reward.TemplateId
        if templateId and templateId > 0 then
            local itemType = XTypeManager.GetTypeById(templateId)
            if itemType == XArrangeConfigs.Types.Weapon then
                local goodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(templateId)
                if goodsShowParams and goodsShowParams.Star and goodsShowParams.Star >= 6 then
                    TryUnlock(PgsAchievementEnum.SixStarWeapon)
                    return
                end
            end
        end
    end
end

-- 技能升级（增量类型，每次+1）
local function OnSkillUpgrade()
    TryIncrement(PgsAchievementEnum.SkillUpgrade60, 1)
end

-------------------------------
-- 事件回调
-------------------------------

local function OnFightResultWin()
    CheckMainLine1_12()
end

local function OnCharacterLevelUp(characterId)
    CheckThreeMembersLv15(characterId)
end

local function OnEquipStrengthen(equipId)
    CheckSixAwarenessLv20(equipId)
end

local function OnFubenSettleReward(settleData)
    if settleData and settleData.IsWin and settleData.StageId then
        CheckBossSingleWin(settleData.StageId)
    end
end

local function OnDrawResult(drawId, count, rewardList)
    CheckRoleDevelop(drawId, count)
    CheckSixStarWeaponFromDrawResult(drawId, rewardList)
end

local function OnFavorabilityLevelChanged(characterId, trustLv)
    CheckTrustLevel3(characterId, trustLv)
end

local function OnSkillUp()
    OnSkillUpgrade()
end

-------------------------------
-- 公开接口
-------------------------------

-- 注册业务事件（在服务器登录成功后调用）
local function RegisterEventListeners()
    -- 重置状态
    UnlockedCache = {}
    IncrementReportedCache = {}
    -- PGS开关未开启不注册
    if not IsPGSEnable() then
        return
    end
    -- 非海外服不注册
    if not XOverseaManager.IsOverSeaRegion() then
        return
    end
    -- 当前区服无PGS配置不注册
    if not GetRegionKey() then
        return
    end

    -- 从本地恢复增量成就已上报记录
    LoadReportedCache(PgsAchievementEnum.ThreeMembersLv15)
    LoadReportedCache(PgsAchievementEnum.SixAwarenessLv20)

    XLog.Debug("[PGS] RegisterEventListeners")

    XEventManager.AddEventListener(XEventId.EVENT_FIGHT_RESULT_WIN, OnFightResultWin)
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_LEVEL_UP, OnCharacterLevelUp)
    XEventManager.AddEventListener(XEventId.EVENT_EQUIP_STRENGTHEN_NOTYFY, OnEquipStrengthen)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SETTLE_REWARD, OnFubenSettleReward)
    XEventManager.AddEventListener(XEventId.EVENT_PGS_FAVORABILITY_LEVELCHANGED, OnFavorabilityLevelChanged)
    XEventManager.AddEventListener(XEventId.EVENT_CHARACTER_SKILL_UP, OnSkillUp)
    XEventManager.AddEventListener(XEventId.EVENT_PGS_DRAW_RESULT, OnDrawResult)
end

function XPgsAchievementManager.InitEventListeners()
    RegisterEventListeners()
end

function XPgsAchievementManager.ShowAchievements()
    if not IsPGSEnable() then
        return
    end
    if not XOverseaManager.IsOverSeaRegion() then
        return
    end
    --CS.XHeroSdkAgent.PGSShowAchievements(9003)
end

function XPgsAchievementManager.OnKRPluginCallback(responseData)
    XLog.Error("[PGS] OnKRPluginCallback: " .. tostring(responseData))
end

function XPgsAchievementManager.GetAchievementEnum()
    return PgsAchievementEnum
end

function XPgsAchievementManager.GetAchievementIdConfig()
    return PgsAchievementIdConfig
end
