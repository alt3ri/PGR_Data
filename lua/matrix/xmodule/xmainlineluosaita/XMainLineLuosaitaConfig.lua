local tableInsert = table.insert
local pairs = pairs

local TableKey = {
    MainLineLuosaitaConfig = { Identifier = "Key", ReadFunc = XConfigUtil.ReadType.String },
    MainLineLuosaitaSection = {},
    MainLineLuosaitaBlock = {},
    MainLineLuosaitaPosition = {},
    MainLineLuosaitaArmy = {},
    MainLineLuosaitaEnemy = {},
    MainLineLuosaitaStage = {},
    MainLineLuosaitaCharacter = {},
    MainLineLuosaitaCharacterMove = {},
    MainLineLuosaitaDocument = {},
    MainLineLuosaitaMessage = { DirPath = XConfigUtil.DirectoryType.Client },
}

---@class XMainLineLuosaitaConfig 纯配置模块
local XMainLineLuosaitaConfig = XClass(nil, "XMainLineLuosaitaConfig")

function XMainLineLuosaitaConfig:Ctor(configUtil)
    self._ConfigUtil = configUtil
    self._ConfigUtil:InitConfigByTableKey("Fuben/MainLineLuosaita", TableKey)
end

-- 退出玩法清理内部数据
function XMainLineLuosaitaConfig:ClearPrivate()
end

-- 重登清理数据
function XMainLineLuosaitaConfig:ResetAll()
end

--region MainLineLuosaitaConfig
---@return XTableMainLineLuosaitaConfig
function XMainLineLuosaitaConfig:GetConfigTemplate(key)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLineLuosaitaConfig, key)
end

---@return number
function XMainLineLuosaitaConfig:GetConfigNumber(key, index)
    local t = self:GetConfigTemplate(key)
    if not t then
        return 0
    end
    local value = t.Values[index]
    if not value then
        return 0
    end
    if XMain.IsWindowsEditor then
        if not string.IsFloatNumber(value) then
            XLog.Error("XMainLineLuosaitaConfig:GetConfigNumberValue: value is not a number: " .. value .. "Key = " .. key .. " index = " .. index)
            return 0
        end
    end
    return tonumber(value)
end

---@return string
function XMainLineLuosaitaConfig:GetConfigString(key, index)
    local t = self:GetConfigTemplate(key)
    if not t then
        return 0
    end
    local value = t.Values[index]
    return value
end
--endregion

--region MainLineLuosaitaSection 阶段表
---@return XTableMainLineLuosaitaSection
function XMainLineLuosaitaConfig:GetConfigSection(id)
        return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLineLuosaitaSection, id)
end

---@return XTableMainLineLuosaitaSection[]
function XMainLineLuosaitaConfig:GetConfigSections()
    return self._ConfigUtil:GetByTableKey(TableKey.MainLineLuosaitaSection)
end

---@return string 阶段预制体路径
function XMainLineLuosaitaConfig:GetSectionMapPrefabPath(id)
    local config = self:GetConfigSection(id)
    return config and config.MapPrefabPath or ""
end

---@return string 阶段名称
function XMainLineLuosaitaConfig:GetSectionName(id)
    local config = self:GetConfigSection(id)
    return config and config.Name or ""
end
--endregion

--region MainLineLuosaitaBlock 地块表
---@return XTableMainLineLuosaitaBlock
function XMainLineLuosaitaConfig:GetConfigBlock(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLineLuosaitaBlock, id)
end

---@return XTableMainLineLuosaitaBlock[]
function XMainLineLuosaitaConfig:GetConfigBlocks()
    return self._ConfigUtil:GetByTableKey(TableKey.MainLineLuosaitaBlock)
end

---@return XTableMainLineLuosaitaBlock[]
function XMainLineLuosaitaConfig:GetConfigBlocksBySectionId(sectionId)
    local result = {}
    local configs = self:GetConfigBlocks()
    for _, config in pairs(configs) do
        if config.SectionId == sectionId then
            tableInsert(result, config)
        end
    end
    return result
end

---@return string 地块名
function XMainLineLuosaitaConfig:GetBlockName(id)
    local config = self:GetConfigBlock(id)
    return config and config.Name or ""
end

---@return number 阶段Id
function XMainLineLuosaitaConfig:GetBlockSectionId(id)
    local config = self:GetConfigBlock(id)
    return config and config.SectionId or 0
end

---@return number[] 相邻地块Id列表
function XMainLineLuosaitaConfig:GetBlockEdgeBlocks(id)
    local config = self:GetConfigBlock(id)
    return config and config.EdgeBlocks or {}
end

---@return string ui节点名称
function XMainLineLuosaitaConfig:GetBlockUiNodeName(id)
    local config = self:GetConfigBlock(id)
    return config and config.UiNodeName or ""
end
--endregion

--region MainLineLuosaitaPosition 位置表
---@return XTableMainLineLuosaitaPosition
function XMainLineLuosaitaConfig:GetConfigPosition(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLineLuosaitaPosition, id)
end

---@return XTableMainLineLuosaitaPosition[]
function XMainLineLuosaitaConfig:GetConfigPositions()
    return self._ConfigUtil:GetByTableKey(TableKey.MainLineLuosaitaPosition)
end

---@return XTableMainLineLuosaitaPosition[]
function XMainLineLuosaitaConfig:GetConfigPositionsBySectionId(sectionId)
    local result = {}
    local configs = self:GetConfigPositions()
    for i, config in pairs(configs) do
        local posSectionId = self:GetBlockSectionId(config.BlockId) 
        if posSectionId == sectionId then
            tableInsert(result, config)
        end
    end
    return result
end

---@return XTableMainLineLuosaitaPosition[]
function XMainLineLuosaitaConfig:GetConfigPositionsByBlockId(blockId)
    local result = {}
    local configs = self:GetConfigPositions()
    for i, config in pairs(configs) do
        if config.BlockId == blockId then
            tableInsert(result, config)
        end
    end
    return result
end

---@return number 块Id
function XMainLineLuosaitaConfig:GetPositionBlockId(id)
    local config = self:GetConfigPosition(id)
    return config and config.BlockId or 0
end

---@return number 位置类型
function XMainLineLuosaitaConfig:GetPositionType(id)
    local config = self:GetConfigPosition(id)
    return config and config.Type or 0
end

---@return string ui节点名称
function XMainLineLuosaitaConfig:GetPositionUiNodeName(id)
    local config = self:GetConfigPosition(id)
    return config and config.UiNodeName or ""
end
--endregion

--region MainLineLuosaitaArmy 友军表
---@return XTableMainLineLuosaitaArmy
function XMainLineLuosaitaConfig:GetConfigArmy(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLineLuosaitaArmy, id)
end

---@return XTableMainLineLuosaitaArmy[]
function XMainLineLuosaitaConfig:GetConfigArmys()
    return self._ConfigUtil:GetByTableKey(TableKey.MainLineLuosaitaArmy)
end

---@return string 友军名称
function XMainLineLuosaitaConfig:GetArmyName(id)
    local config = self:GetConfigArmy(id)
    return config and config.Name or ""
end

---@return string 友军详情
function XMainLineLuosaitaConfig:GetArmyDesc(id)
    local config = self:GetConfigArmy(id)
    return config and config.Desc or ""
end

---@return string 友军头像
function XMainLineLuosaitaConfig:GetArmyHead(id)
    local config = self:GetConfigArmy(id)
    return config and config.Head or ""
end

---@return number 友军攻击力
function XMainLineLuosaitaConfig:GetArmyAttack(id)
    local config = self:GetConfigArmy(id)
    return config and config.Attack or 0
end
--endregion

--region MainLineLuosaitaEnemy 敌军表
---@return XTableMainLineLuosaitaEnemy
function XMainLineLuosaitaConfig:GetConfigEnemy(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLineLuosaitaEnemy, id)
end

---@return XTableMainLineLuosaitaEnemy[]
function XMainLineLuosaitaConfig:GetConfigEnemys()
    return self._ConfigUtil:GetByTableKey(TableKey.MainLineLuosaitaEnemy)
end

---@return string 敌军名称
function XMainLineLuosaitaConfig:GetEnemyName(id)
    local config = self:GetConfigEnemy(id)
    return config and config.Name or ""
end

---@return number 指定友军Id
function XMainLineLuosaitaConfig:GetEnemyChallengeArmyId(id)
    local config = self:GetConfigEnemy(id)
    return config and config.ChallengeArmyId or 0
end

---@return string 指定友军提示
function XMainLineLuosaitaConfig:GetEnemyChallengeArmyTips(id)
    local config = self:GetConfigEnemy(id)
    return config and config.ChallengeArmyTips or ""
end

---@return string 敌军详情
function XMainLineLuosaitaConfig:GetEnemyDesc(id)
    local config = self:GetConfigEnemy(id)
    return config and config.Desc or ""
end

---@return string 敌军头像
function XMainLineLuosaitaConfig:GetEnemyHead(id)
    local config = self:GetConfigEnemy(id)
    return config and config.Head or ""
end

---@return number 敌军攻击力
function XMainLineLuosaitaConfig:GetEnemyAttack(id)
    local config = self:GetConfigEnemy(id)
    return config and config.Attack or 0
end

---@return number[] 敌军文件Id列表
function XMainLineLuosaitaConfig:GetEnemyDocIds(id)
    local config = self:GetConfigEnemy(id)
    return config and config.DocIds or {}
end

---@return number 通讯Id
function XMainLineLuosaitaConfig:GetEnemyMessageId(id)
    local config = self:GetConfigEnemy(id)
    return config and config.MessageId or 0
end

---@return number 显示条件
function XMainLineLuosaitaConfig:GetEnemyShowConditionId(id)
    local config = self:GetConfigEnemy(id)
    return config and config.ShowConditionId or 0
end
--endregion

--region MainLineLuosaitaStage 关卡表
---@return XTableMainLineLuosaitaStage
function XMainLineLuosaitaConfig:GetConfigStage(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLineLuosaitaStage, id)
end

---@return XTableMainLineLuosaitaStage[]
function XMainLineLuosaitaConfig:GetConfigStages()
    return self._ConfigUtil:GetByTableKey(TableKey.MainLineLuosaitaStage)
end

---@return number 关卡显示条件
function XMainLineLuosaitaConfig:GetStageConditionId(id)
    local config = self:GetConfigStage(id)
    return config and config.ConditionId or 0
end

---@return number[] 关卡文件Id列表
function XMainLineLuosaitaConfig:GetStageDocIds(id)
    local config = self:GetConfigStage(id)
    return config and config.DocIds or {}
end

---@return number 通讯Id
function XMainLineLuosaitaConfig:GetStageMessageId(id)
    local config = self:GetConfigStage(id)
    return config and config.MessageId or 0
end
--endregion

--region MainLineLuosaitaCharacter 角色表
---@return XTableMainLineLuosaitaCharacter
function XMainLineLuosaitaConfig:GetConfigCharacter(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLineLuosaitaCharacter, id)
end

---@return XTableMainLineLuosaitaCharacter[]
function XMainLineLuosaitaConfig:GetConfigCharacters()
    return self._ConfigUtil:GetByTableKey(TableKey.MainLineLuosaitaCharacter)
end

---@return number 角色名称
function XMainLineLuosaitaConfig:GetCharacterName(id)
    local config = self:GetConfigCharacter(id)
    return config and config.Name or ""
end

---@return number 角色详情
function XMainLineLuosaitaConfig:GetCharacterDesc(id)
    local config = self:GetConfigCharacter(id)
    return config and config.Desc or ""
end

---@return number 角色头像
function XMainLineLuosaitaConfig:GetCharacterHead(id)
    local config = self:GetConfigCharacter(id)
    return config and config.Head or ""
end
--endregion

--region MainLineLuosaitaCharacterMove 角色移动表
---@return XTableMainLineLuosaitaCharacterMove
function XMainLineLuosaitaConfig:GetConfigCharacterMove(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLineLuosaitaCharacterMove, id)
end

---@return XTableMainLineLuosaitaCharacterMove[]
function XMainLineLuosaitaConfig:GetConfigCharacterMoves()
    return self._ConfigUtil:GetByTableKey(TableKey.MainLineLuosaitaCharacterMove)
end

---@return number 角色移动Id
function XMainLineLuosaitaConfig:GetCharacterMoveConditionId(id)
    local config = self:GetConfigCharacterMove(id)
    return config and config.ConditionId or 0
end
--endregion

--region MainLineLuosaitaDocument 文件表
---@return XTableMainLineLuosaitaDocument
function XMainLineLuosaitaConfig:GetConfigDocument(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLineLuosaitaDocument, id)
end

---@return XTableMainLineLuosaitaDocument[]
function XMainLineLuosaitaConfig:GetConfigDocuments()
    return self._ConfigUtil:GetByTableKey(TableKey.MainLineLuosaitaDocument)
end

---@return number 文件类型
function XMainLineLuosaitaConfig:GetDocumentType(id)
    local config = self:GetConfigDocument(id)
    return config and config.Type or 0
end
--endregion

--region MainLineLuosaitaMessage 通讯表
---@return XTableMainLineLuosaitaMessage
function XMainLineLuosaitaConfig:GetConfigMessage(id)
    return self._ConfigUtil:GetCfgByTableKeyAndIdKey(TableKey.MainLineLuosaitaMessage, id)
end

---@return XTableMainLineLuosaitaMessage[]
function XMainLineLuosaitaConfig:GetConfigMessages()
    return self._ConfigUtil:GetByTableKey(TableKey.MainLineLuosaitaMessage)
end

---@return number 通讯优先级
function XMainLineLuosaitaConfig:GetMessageOrder(id)
    local config = self:GetConfigMessage(id)
    return config and config.Order or 0
end

---@return number 通讯文本
function XMainLineLuosaitaConfig:GetMessageText(id)
    local config = self:GetConfigMessage(id)
    return config and config.Text or 0
end
--endregion

return XMainLineLuosaitaConfig