--=============
--配置表枚举
--ReadFunc : 读取表格的方法，默认为XConfigUtil.ReadType.Int
--DirPath : 读取的文件夹类型XConfigUtil.DirectoryType，默认是Share
--Identifier : 读取表格的主键名，默认为Id
--TableDefinedName : 表定于名，默认同表名
--CacheType : 配置表缓存方式，默认XConfigUtil.CacheType.Private
--=============
local DlcRelinkTableKey = {
    DlcRelinkActivity = { CacheType = XConfigUtil.CacheType.Normal },
    DlcRelinkChapter = { Identifier = "ChapterId", },
    DlcRelinkCharacter = {},
    DlcRelinkLevel = { Identifier = "LevelId", },
    DlcRelinkDropGroup = {},
    DlcRelinkRewardGroup = {},
    DlcRelinkPlayerLevel = { Identifier = "Level", },
    DlcRelinkEquip = {},
    DlcRelinkEquipQuality = { Identifier = "Quality", },
    DlcRelinkFactor = {},
    DlcRelinkFactorDesc = {},
    DlcRelinkCompose = {},
    DlcRelinkComposePool = {},
    DlcRelinkBreak = { Identifier = "BreakEquipId", },
    DlcRelinkConfig = {
        ReadFunc = XConfigUtil.ReadType.String,
        Identifier = "Key",
    },
    DlcRelinkBossSkillDesc = { DirPath = XConfigUtil.DirectoryType.Client, },
    DlcRelinkEquipSkillFactor = { DirPath = XConfigUtil.DirectoryType.Client, },
    DlcRelinkWorld = {
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
    },
    DlcRelinkClientConfig = {
        CacheType = XConfigUtil.CacheType.Normal,
        ReadFunc = XConfigUtil.ReadType.String,
        DirPath = XConfigUtil.DirectoryType.Client,
        Identifier = "Key",
    }
}

---@class XDlcRelinkModel : XModel
---@field ActivityData XDlcRelinkActivity
local XDlcRelinkModel = XClass(XModel, "XDlcRelinkModel")
function XDlcRelinkModel:OnInit()
    --初始化内部变量
    --这里只定义一些基础数据, 请不要一股脑把所有表格在这里进行解析
    self._ConfigUtil:InitConfigByTableKey("DlcWorld/DlcRelink", DlcRelinkTableKey)
end

function XDlcRelinkModel:ClearPrivate()
    --这里执行内部数据清理
end

function XDlcRelinkModel:ResetAll()
    --这里执行重登数据清理
    self.ActivityData = nil
end

--region 服务端信息更新和获取

function XDlcRelinkModel:NotifyActivityData(data)
    if not self.ActivityData then
        self.ActivityData = require("XModule/XDlcRelink/XEntity/XDlcRelinkActivity").New()
    end
    self.ActivityData:NotifyActivityData(data)
end

--endregion

--region 活动表相关

---@return XTableDlcRelinkActivity
function XDlcRelinkModel:GetActivityConfig()
    if not self.ActivityData then
        return nil
    end
    local curActivityId = self.ActivityData:GetActivityId()
    if not XTool.IsNumberValid(curActivityId) then
        return nil
    end
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkActivity, curActivityId)
end

-- 获取活动时间Id
function XDlcRelinkModel:GetActivityTimeId()
    local config = self:GetActivityConfig()
    return config and config.TimeId or 0
end

--endregion

--region 章节表相关
---@return XTableDlcRelinkChapter[]
function XDlcRelinkModel:GetChapterConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkChapter)
end

---@return XTableDlcRelinkChapter
function XDlcRelinkModel:GetChapterConfig(chapterId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkChapter, chapterId)
end

--endregion

--region 角色表相关

---@return XTableDlcRelinkCharacter[]
function XDlcRelinkModel:GetCharacterConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkCharacter)
end

---@return XTableDlcRelinkCharacter
function XDlcRelinkModel:GetCharacterConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkCharacter, id)
end

--endregion

--region 等级表相关

---@return XTableDlcRelinkLevel[]
function XDlcRelinkModel:GetLevelConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkLevel)
end

---@return XTableDlcRelinkLevel
function XDlcRelinkModel:GetLevelConfig(levelId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkLevel, levelId)
end

--endregion

--region 掉落组表相关

---@return XTableDlcRelinkDropGroup[]
function XDlcRelinkModel:GetDropGroupConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkDropGroup)
end

---@return XTableDlcRelinkDropGroup
function XDlcRelinkModel:GetDropGroupConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkDropGroup, id)
end

--endregion

--region 奖励组表相关

---@return XTableDlcRelinkRewardGroup[]
function XDlcRelinkModel:GetRewardGroupConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkRewardGroup)
end

---@return XTableDlcRelinkRewardGroup
function XDlcRelinkModel:GetRewardGroupConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkRewardGroup, id)
end

--endregion

--region 玩家等级表相关

---@return XTableDlcRelinkPlayerLevel[]
function XDlcRelinkModel:GetPlayerLevelConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkPlayerLevel)
end

---@return XTableDlcRelinkPlayerLevel
function XDlcRelinkModel:GetPlayerLevelConfig(level)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkPlayerLevel, level)
end

--endregion

--region 装备表相关

---@return XTableDlcRelinkEquip[]
function XDlcRelinkModel:GetEquipConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkEquip)
end

---@return XTableDlcRelinkEquip
function XDlcRelinkModel:GetEquipConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkEquip, id)
end

--endregion

--region 装备品质表相关

---@return XTableDlcRelinkEquipQuality[]
function XDlcRelinkModel:GetEquipQualityConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkEquipQuality)
end

---@return XTableDlcRelinkEquipQuality
function XDlcRelinkModel:GetEquipQualityConfig(quality)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkEquipQuality, quality)
end

--endregion

--region 词条表相关

---@return XTableDlcRelinkFactor[]
function XDlcRelinkModel:GetFactorConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkFactor)
end

---@return XTableDlcRelinkFactor
function XDlcRelinkModel:GetFactorConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkFactor, id)
end

--endregion

--region 词条描述表相关

---@return XTableDlcRelinkFactorDesc[]
function XDlcRelinkModel:GetFactorDescConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkFactorDesc)
end

---@return XTableDlcRelinkFactorDesc
function XDlcRelinkModel:GetFactorDescConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkFactorDesc, id)
end

--endregion

--region 合成表相关

---@return XTableDlcRelinkCompose[]
function XDlcRelinkModel:GetComposeConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkCompose)
end

---@return XTableDlcRelinkCompose
function XDlcRelinkModel:GetComposeConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkCompose, id)
end

--endregion

--region 合成池表相关

---@return XTableDlcRelinkComposePool[]
function XDlcRelinkModel:GetComposePoolConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkComposePool)
end

---@return XTableDlcRelinkComposePool
function XDlcRelinkModel:GetComposePoolConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkComposePool, id)
end

--endregion

--region 分解表相关

---@return XTableDlcRelinkBreak[]
function XDlcRelinkModel:GetBreakConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkBreak)
end

---@return XTableDlcRelinkBreak
function XDlcRelinkModel:GetBreakConfig(breakEquipId)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkBreak, breakEquipId)
end

--endregion

--region 配置表相关

---@return XTableDlcRelinkConfig[]
function XDlcRelinkModel:GetConfigConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkConfig)
end

---@return XTableDlcRelinkConfig
function XDlcRelinkModel:GetConfigConfig(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkConfig, key)
end

--endregion

--region Boss技能描述表相关

---@return XTableDlcRelinkBossSkillDesc[]
function XDlcRelinkModel:GetBossSkillDescConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkBossSkillDesc)
end

---@return XTableDlcRelinkBossSkillDesc
function XDlcRelinkModel:GetBossSkillDescConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkBossSkillDesc, id)
end

--endregion

--region 装备技能词条表相关

---@return XTableDlcRelinkEquipSkillFactor[]
function XDlcRelinkModel:GetEquipSkillFactorConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkEquipSkillFactor)
end

---@return XTableDlcRelinkEquipSkillFactor
function XDlcRelinkModel:GetEquipSkillFactorConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkEquipSkillFactor, id)
end

--endregion

--region World表相关

---@return XTableDlcRelinkWorld[]
function XDlcRelinkModel:GetWorldConfigs()
    return self._ConfigUtil:GetByTableKey(DlcRelinkTableKey.DlcRelinkWorld)
end

---@return XTableDlcRelinkWorld
function XDlcRelinkModel:GetWorldConfig(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkWorld, id)
end

function XDlcRelinkModel:GetWorldIcon(id)
    local config = self:GetWorldConfig(id)
    return config and config.Icon or ""
end

function XDlcRelinkModel:GetWorldSceneUrl(id)
    local config = self:GetWorldConfig(id)
    return config and config.SceneUrl or ""
end

function XDlcRelinkModel:GetWorldSceneModelUrl(id)
    local config = self:GetWorldConfig(id)
    return config and config.SceneModelUrl or ""
end

function XDlcRelinkModel:GetWorldLoadingBackground(id)
    local config = self:GetWorldConfig(id)
    return config and config.LoadingBackground or ""
end

function XDlcRelinkModel:GetWorldArtName(id)
    local config = self:GetWorldConfig(id)
    return config and config.ArtName or ""
end

function XDlcRelinkModel:GetWorldMaskLoadingType(id)
    local config = self:GetWorldConfig(id)
    return config and config.MaskLoadingType or ""
end

function XDlcRelinkModel:GetWorldSettlementUiName(id)
    local config = self:GetWorldConfig(id)
    return config and config.SettlementUiName or ""
end

--endregion

--region 客户端配置表相关

function XDlcRelinkModel:GetClientConfig(key, index)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkClientConfig, key)
    if not config then
        return nil
    end
    return config.Params and config.Params[index] or ""
end

function XDlcRelinkModel:GetClientConfigParams(key)
    local config = self._ConfigUtil:GetCfgByTableKeyAndIdKey(DlcRelinkTableKey.DlcRelinkClientConfig, key)
    if not config then
        return nil
    end
    return config.Params
end

--endregion

return XDlcRelinkModel
