---@type XPunishaarAgency 配置部分类
local XPunishaarAgency = XClassPartial("XPunishaarAgency")

local TableKey = {
    PunishaarActivity = { DirPath = XConfigUtil.DirectoryType.Share},
    PunishaarConfig = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    PunishaarClientConfig = { DirPath = XConfigUtil.DirectoryType.Client, Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    PunishaarStageGroup = { DirPath = XConfigUtil.DirectoryType.Share, Identifier = "StageId" },
    PunishaarStageContent = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'Id' },
    PunishaarStageContentGroup = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = 'StageId' },
    PunishaarCard = { DirPath = XConfigUtil.DirectoryType.Share, ReadFunc = XConfigUtil.ReadType.Int, Identifier = "Id", },
}


function XPunishaarAgency:InitConfig()
    --初始化配置表
    self:InitConfigByTabKey("Punishaar", TableKey)
end

---@return XTablePunishaarActivity
function XPunishaarAgency:GetTablePunishaarActivityById(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarActivity, id, notips)
end

---@return XTablePunishaarConfig
function XPunishaarAgency:GetTablePunishaarConfig(key, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarConfig, key, notips)
end

---@return XTablePunishaarClientConfig
function XPunishaarAgency:GetTablePunishaarClientConfig(key, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarClientConfig, key, notips)
end

---@return XTablePunishaarStageGroup
function XPunishaarAgency:GetTablePunishaarStageGroupById(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarStageGroup, id, notips)
end

function XPunishaarAgency:GetTablePunishaarCard(cardId, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarCard, cardId, notips)
end

function XPunishaarAgency:GetTablePunishaarCardCfgs()
    return self:GetAllConfigByTabKey(TableKey.PunishaarCard)
end
--region ClientConfig 

function XPunishaarAgency:GetClientStringByKey(key, index)
    index = index or 1
    
    local cfg = self:GetTablePunishaarClientConfig(key)

    if cfg then
        return cfg.Values[index] or ''
    end
    
    return ''
end

function XPunishaarAgency:GetClientNumberByKey(key, index)
    index = index or 1

    local cfg = self:GetTablePunishaarClientConfig(key)

    -- 容忍 Values[index] 为 nil（key 行存在但值未填）——nil 守卫在 string.IsFloatNumber 前，避免 match(nil) 报错 #80
    if cfg and not string.IsNilOrEmpty(cfg.Values[index]) and string.IsFloatNumber(cfg.Values[index]) then
        return tonumber(cfg.Values[index])
    end

    return 0
end

--endregion

--region ShareConfig（PunishaarConfig，Key + Param 键值表）

--- 读取 Share 端 PunishaarConfig 表的 Param 数值。
---@param key string 配置 Key
---@param index number|nil Param 下标（默认 1）
---@return number
function XPunishaarAgency:GetConfigNumberByKey(key, index)
    index = index or 1

    local cfg = self:GetTablePunishaarConfig(key)

    if cfg and cfg.Param then
        local paramStr = cfg.Param[index]

        if not string.IsNilOrEmpty(paramStr) and string.IsFloatNumber(cfg.Param[index]) then
            return tonumber(cfg.Param[index])
        end
    end

    return 0
end

--- 读取 Share 端 PunishaarConfig 表某 Key 的整行 Param 为数值列表（用于 MasterCardTypeList 这类多值配置）。
---@param key string 配置 Key
---@return number[] 数值列表（空配置返回空表）
function XPunishaarAgency:GetConfigNumberListByKey(key)
    local result = {}
    local cfg = self:GetTablePunishaarConfig(key)
    if cfg and cfg.Param then
        for i = 1, #cfg.Param do
            if string.IsFloatNumber(cfg.Param[i]) then
                result[#result + 1] = tonumber(cfg.Param[i])
            end
        end
    end
    return result
end

--endregion

--region 主副卡类型判据（数据源：PunishaarConfig 的 MasterCardTypeList / SubCardTypeList）

-- 主副卡类型列表配置 Key
local CardMainTypeConfigKey = {
    MasterCardTypeList = "MasterCardTypeList",  -- 属于主卡的 CardType 列表
    SubCardTypeList    = "SubCardTypeList",     -- 属于副卡的 CardType 列表
}

--- 属于主卡的 CardType 列表（配置 MasterCardTypeList，如 {1,2}=角色/武器）。
---@return number[]
function XPunishaarAgency:GetMasterCardTypeList()
    return self:GetConfigNumberListByKey(CardMainTypeConfigKey.MasterCardTypeList)
end

--- 属于副卡的 CardType 列表（配置 SubCardTypeList，如 {3,4}=意识/共鸣）。
---@return number[]
function XPunishaarAgency:GetSubCardTypeList()
    return self:GetConfigNumberListByKey(CardMainTypeConfigKey.SubCardTypeList)
end

--- 根据卡牌的配置类型（CardType）返回其主/副大类（CarMainType）。
--- 判据：CardType 命中 SubCardTypeList → Sub；否则 → Main（含命中 MasterCardTypeList 与异常兜底）。
--- 兜底为 Main 是为防止误判致卡牌完全不参战；异常配置打点由上层排查。
---@param cardType number CardType 枚举值（Character/Weapon/Awareness/Resonance）
---@return number CarMainType（Main/Sub）
function XPunishaarAgency:GetPunishaarCardMainType(cardType)
    local CarMainType = self.EnumConst.CarMainType
    for _, t in ipairs(self:GetSubCardTypeList()) do
        if t == cardType then
            return CarMainType.Sub
        end
    end
    return CarMainType.Main
end

--- 副卡小类 → 其能装配的宿主主卡小类（纯 CardType→CardType 映射）。
--- 意识(Awareness) 只能装 角色(Character)；共鸣(Resonance) 只能装 武器(Weapon)。
--- 映射表定义在枚举 `XPunishaarEnum.SubCardHostCardType`（静态表，避免每次调用重建）；
--- 【将来可配置】改为配置驱动时只需换掉本函数的取值来源，上层 IsSubCardTypeMatchMaster 不受影响。
--- 未命中返回 nil（未知副卡类型不允许装配任何主卡）。
---@param subCardType number 副卡 CardType（Awareness/Resonance）
---@return number|nil 允许装配的主卡 CardType；未知副卡类型返回 nil
function XPunishaarAgency:GetSubCardHostCardType(subCardType)
    return self.EnumConst.SubCardHostCardType[subCardType]
end

--- 判定某副卡小类能否装配到某主卡小类（供落点校验用）。
---@param subCardType number 副卡 CardType
---@param masterCardType number 主卡 CardType
---@return boolean
function XPunishaarAgency:IsSubCardTypeMatchMaster(subCardType, masterCardType)
    return self:GetSubCardHostCardType(subCardType) == masterCardType
end

--endregion

--region 关卡字段

function XPunishaarAgency:GetCfgStageNameByStageId(stageId, notips)
    local cfg = self:GetTablePunishaarStageGroupById(stageId, notips)

    if cfg then
        return cfg.Name
    end
end

function XPunishaarAgency:GetCfgStageDescByStageId(stageId, notips)
    local cfg = self:GetTablePunishaarStageGroupById(stageId, notips)

    if cfg then
        return cfg.Desc
    end
end

--endregion

--- 获取节点内容配置（每行 = 一个节点：ContentType/ShopGroupId/EventGroupId/FightGroupId/Gold）。
---@return XTablePunishaarStageContent
function XPunishaarAgency:GetTablePunishaarStageContent(id, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarStageContent, id, notips)
end

--- 获取关卡的有序节点序列（StageId → StageContentIds[1..N]）。
---@return XTablePunishaarStageContentGroup
function XPunishaarAgency:GetTablePunishaarStageContentGroup(stageId, notips)
    return self:GetConfigByTabKeyAndIdKey(TableKey.PunishaarStageContentGroup, stageId, notips)
end

---@param stageId number
---@return string|nil
function XPunishaarAgency:GetExploreDetailStoryId(stageId)
    local stageCfg = self:GetTablePunishaarStageGroupById(stageId, true)
    return stageCfg and stageCfg.BeginStoryId
end

--- 获取指定关卡的节点总数
---@param stageId number 关卡Id
---@return number 节点总数
function XPunishaarAgency:GetStageContentCount(stageId)
    local groupCfg = self:GetTablePunishaarStageContentGroup(stageId, true)
    if not groupCfg or not groupCfg.StageContentIds then
        return 0
    end

    return #groupCfg.StageContentIds
end

--- 根据关卡组Id和组内索引计算StageId（groupId * 100 + index）
---@param groupId number 关卡组Id（对应 PunishaarActivity.StageGroup）
---@param index number 组内序号（从1起）
---@return number
function XPunishaarAgency:GetStageIdByGroupAndIndex(groupId, index)
    return groupId * 100 + index
end

--- 当前活动的关卡组Id（从 Activity 配置取 StageGroup 字段）；活动无效时返回 nil
---@return number|nil
function XPunishaarAgency:GetCurrentStageGroupId()
    local activityId = self._Model:GetActivityId()
    local activityCfg = activityId and self:GetTablePunishaarActivityById(activityId)
    return activityCfg and activityCfg.StageGroup
end

return XPunishaarAgency
